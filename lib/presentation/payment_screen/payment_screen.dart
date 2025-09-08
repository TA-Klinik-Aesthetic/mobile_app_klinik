import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/core/services/midtrans_config.dart';
import 'package:mobile_app_klinik/presentation/payment_screen/payment_midtrans.dart';
import 'package:mobile_app_klinik/presentation/payment_screen/payment_on_store.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../theme/theme_helper.dart';

class PaymentScreen extends StatefulWidget {
  final int? treatmentBookingId;
  final int? productSaleId;
  final String name;
  final double price;

  const PaymentScreen.treatment({
    super.key,
    required this.treatmentBookingId,
    required this.name,
    required this.price,
  }) : productSaleId = null;

  const PaymentScreen.product({
    super.key,
    required this.productSaleId,
    required this.name,
    required this.price,
  }) : treatmentBookingId = null;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkMidtransConfig();
  }

  void _checkMidtransConfig() {
    if (!MidtransConfig.isConfigured) {
      print('Warning: Midtrans not properly configured');
      print('Client Key: ${MidtransConfig.clientKey}');
      print('Server Key: ${MidtransConfig.serverKey}');
      print('Merchant ID: ${MidtransConfig.merchantId}');
    } else {
      print('Midtrans configured successfully');
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    super.dispose();
  }

  String _formatPrice(double price) {
    final String priceString = price.toStringAsFixed(0);
    final StringBuffer formattedPrice = StringBuffer();
    int count = 0;
    for (int i = priceString.length - 1; i >= 0; i--) {
      formattedPrice.write(priceString[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        formattedPrice.write('.');
      }
    }
    return formattedPrice.toString().split('').reversed.join('');
  }

  Future<void> _processCashPayment() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran Tunai'),
        content: Text(
          'Anda akan membayar ${widget.name} senilai Rp ${_formatPrice(widget.price)} di klinik. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.orange200,
            ),
            child: const Text('Konfirmasi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Generate payment ID untuk PaymentOnStoreScreen
      String paymentId = widget.productSaleId?.toString() ?? 
                        widget.treatmentBookingId?.toString() ?? 
                        DateTime.now().millisecondsSinceEpoch.toString();

      // Navigate directly to PaymentOnStoreScreen
      final result = await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentOnStoreScreen(
            paymentId: paymentId,
            amount: widget.price,
            productSaleId: widget.productSaleId,
          ),
        ),
      );

      // Return result to previous screen if needed
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod.isEmpty) {
      _showMessage('Pilih metode pembayaran terlebih dahulu');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPaymentMethod == 'cash') {
        await _processCashPayment();
      } else if (_selectedPaymentMethod == 'online') {
        await _processOnlinePayment();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processOnlinePayment() async {
    if (!MidtransConfig.isConfigured) {
      _showMessage('Konfigurasi Midtrans belum lengkap');
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        return;
      }

      // Tentukan jenis pembayaran dan endpoint
      final bool isTreatment = widget.treatmentBookingId != null;
      final String endpoint = isTreatment
          ? ApiConstants.pembayaranMidtransTreatment
          : ApiConstants.pembayaranMidtransProduk;

      // Siapkan body sesuai jenis
      final Map<String, dynamic> requestBody = isTreatment
          ? {
              'id_booking_treatment': widget.treatmentBookingId,
            }
          : {
              'id_penjualan_produk': widget.productSaleId,
            };

      print('=== DEBUGGING PAYMENT REQUEST ===');
      print('Type: ${isTreatment ? 'Treatment' : 'Produk'}');
      print('Endpoint: $endpoint');
      print('Token: ${token.substring(0, 20)}...');
      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('=== RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body (first 500): ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      // Cek HTML error
      if (response.body.trim().startsWith('<!DOCTYPE') || response.body.trim().startsWith('<html')) {
        _showMessage('Server mengembalikan HTML (Status ${response.statusCode}). Periksa URL API.');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Ambil snap/redirect url
        final String? snapUrl = data['snap_url'] ??
            data['redirect_url'] ??
            data['payment_url'] ??
            data['url'] ??
            data['data']?['snap_url'] ??
            data['data']?['redirect_url'];

        // Ambil id_pembayaran jika ada untuk fitur refresh
        final String? paymentId = (data['id_pembayaran'] ??
                data['payment_id'] ??
                data['data']?['id_pembayaran'] ??
                data['pembayaran']?['id_pembayaran'])
            ?.toString();

        if (snapUrl == null || snapUrl.isEmpty) {
          _showMessage('URL pembayaran tidak ditemukan');
          return;
        }

        await _openMidtransWebViewWithId(snapUrl, paymentId);
      } else {
        // Tampilkan pesan error dari server
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = errorData['message'] ??
              errorData['error'] ??
              (isTreatment
                  ? 'Gagal memproses pembayaran treatment'
                  : 'Gagal memproses pembayaran produk');
          _showMessage(errorMessage);
        } catch (_) {
          _showMessage('Error ${response.statusCode}: Gagal memproses pembayaran');
        }
      }
    } catch (e) {
      _showMessage('Network error: $e');
    }
  }

  Future<void> _openMidtransWebView(String snapUrl) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMidtrans(
            snapUrl: snapUrl,
            title: 'Pembayaran ${widget.name}',
          ),
        ),
      );

      // Handle the result from WebView
      if (result != null) {
        _handlePaymentResult(result);
      }
    } catch (e) {
      _showMessage('Error membuka halaman pembayaran: $e');
    }
  }

  Future<void> _openMidtransWebViewWithId(String snapUrl, String? paymentId) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMidtrans(
            snapUrl: snapUrl,
            title: 'Pembayaran ${widget.name}',
            paymentId: paymentId,
          ),
        ),
      );

      if (result != null) {
        _handlePaymentResult(result);
      }
    } catch (e) {
      _showMessage('Error membuka halaman pembayaran: $e');
    }
  }

  void _handlePaymentResult(String status) {
    String message;
    bool shouldPop = false;

    switch (status) {
      case 'success':
        message = 'Pembayaran berhasil!';
        shouldPop = true;
        break;
      case 'pending':
        message = 'Pembayaran sedang diproses. Silakan cek status pembayaran Anda.';
        shouldPop = true;
        break;
      case 'failed':
        message = 'Pembayaran gagal. Silakan coba lagi.';
        break;
      case 'cancelled':
        message = 'Pembayaran dibatalkan.';
        break;
      default:
        message = 'Status pembayaran tidak diketahui.';
    }

    _showMessage(message);

    if (shouldPop) {
      // Pop back to previous screen after successful or pending payment
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, status);
        }
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _selectedPaymentMethod == value ? appTheme.orange200 : Colors.grey.shade300,
          width: _selectedPaymentMethod == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (String? newValue) {
          setState(() {
            _selectedPaymentMethod = newValue ?? '';
          });
        },
        activeColor: appTheme.orange200,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.orange200.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appTheme.orange200.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appTheme.black900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(widget.price)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appTheme.orange200,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 16),

            // Payment options
            Expanded(
              child: Column(
                children: [
                  _buildPaymentOption(
                    value: 'cash',
                    title: 'Bayar di Klinik',
                    subtitle: 'Pembayaran tunai langsung di klinik',
                    icon: Icons.store,
                    iconColor: Colors.green,
                  ),
                  _buildPaymentOption(
                    value: 'online',
                    title: 'Pembayaran Online',
                    subtitle: 'Transfer bank, e-wallet, atau kartu kredit',
                    icon: Icons.payment,
                    iconColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.orange200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Proses Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}