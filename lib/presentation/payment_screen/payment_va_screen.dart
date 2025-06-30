import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/payment_screen/payment_success_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:share_plus/share_plus.dart';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';

class PaymentVAScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final Map<String, dynamic> paymentInfo;
  final String paymentMethod;
  final String orderId;

  const PaymentVAScreen({
    super.key,
    required this.paymentData,
    required this.paymentInfo,
    required this.paymentMethod,
    required this.orderId,
  });

  @override
  State<PaymentVAScreen> createState() => _PaymentVAScreenState();
}

class _PaymentVAScreenState extends State<PaymentVAScreen> {
  bool isLoading = false;
  String? errorMessage;
  late Timer _statusCheckTimer;
  final int _statusCheckInterval = 5;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    // Start periodic status checking
    _statusCheckTimer = Timer.periodic(
        Duration(seconds: _statusCheckInterval),
            (_) => _checkPaymentStatus()
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _statusCheckTimer.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    if (!_isMounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/midtrans/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': widget.orderId}),
      );

      if (!_isMounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final statusData = json.decode(response.body);

        if (statusData['status_pembayaran'] == 'Berhasil') {
          _statusCheckTimer.cancel();
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    paymentData: statusData,
                  )
              )
          );
        }
      }
    } catch (e) {
      if (!_isMounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disalin ke clipboard'),
          backgroundColor: appTheme.orange200,
          behavior: SnackBarBehavior.floating,
        )
    );
  }

  String _getBankName() {
    switch (widget.paymentMethod) {
      case 'bca_va': return 'BCA';
      case 'bni_va': return 'BNI';
      case 'bri_va': return 'BRI';
      case 'mandiri_va': return 'Mandiri';
      default: return 'Bank';
    }
  }

  String _getBankLogo() {
    switch (widget.paymentMethod) {
      case 'bca_va': return 'assets/images/bca_logo.png';
      case 'bni_va': return 'assets/images/bni_logo.png';
      case 'bri_va': return 'assets/images/bri_logo.png';
      case 'mandiri_va': return 'assets/images/mandiri_logo.png';
      default: return 'assets/images/bank_logo.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String vaNumber = widget.paymentData['va_numbers']?[0]?['va_number'] ??
        widget.paymentData['bill_key'] ?? ''; // Fallback for Mandiri
    final String bankName = _getBankName();
    final String expiryTime = widget.paymentData['expiry_time'] ?? 'Unknown';
    final double amount = double.tryParse(widget.paymentInfo['nominal_pembayaran']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Pembayaran Virtual Account',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment status and timer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appTheme.black900, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Menunggu Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selesaikan pembayaran sebelum:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiryTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appTheme.orange200,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatPrice(amount)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appTheme.orange200,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Virtual Account Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appTheme.black900, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        _getBankLogo(),
                        height: 40,
                        width: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Virtual Account $bankName',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'No. Pesanan: ${widget.orderId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Nomor Virtual Account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          vaNumber,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(vaNumber),
                        icon: Icon(
                          Icons.copy,
                          color: appTheme.orange200,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Payment Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: appTheme.whiteA700,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: appTheme.black900, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInstructions(bankName),
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _checkPaymentStatus(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: appTheme.orange200),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200),
                  ),
                )
                    : Text(
                  'Cek Status Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appTheme.orange200,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final String shareText = 'Pembayaran via $bankName\n'
                    'Nomor VA: $vaNumber\n'
                    'Jumlah: Rp ${_formatPrice(amount)}\n'
                    'Bayar sebelum: $expiryTime';
                Share.share(shareText);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(
                Icons.share,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(String bankName) {
    List<Map<String, String>> instructions;

    switch (widget.paymentMethod) {
      case 'bca_va':
        instructions = [
          {'title': 'ATM BCA', 'content': '1. Masukkan kartu ATM dan PIN\n2. Pilih "Transaksi Lainnya" > "Transfer" > "Ke Rek BCA Virtual Account"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Pembayaran selesai'},
          {'title': 'Mobile Banking BCA', 'content': '1. Login ke aplikasi BCA Mobile\n2. Pilih "m-BCA" > "m-Transfer" > "BCA Virtual Account"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Masukkan PIN m-BCA\n6. Pembayaran selesai'},
        ];
        break;

      case 'bni_va':
        instructions = [
          {'title': 'ATM BNI', 'content': '1. Masukkan kartu ATM dan PIN\n2. Pilih "Menu Lain" > "Transfer" > "Dari rekening tabungan" > "Ke rekening BNI"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Pembayaran selesai'},
          {'title': 'Mobile Banking BNI', 'content': '1. Login ke aplikasi BNI Mobile\n2. Pilih "Transfer" > "Virtual Account Billing"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Masukkan password transaksi\n6. Pembayaran selesai'},
        ];
        break;

      case 'bri_va':
        instructions = [
          {'title': 'ATM BRI', 'content': '1. Masukkan kartu ATM dan PIN\n2. Pilih "Transaksi Lain" > "Pembayaran" > "Lainnya" > "BRIVA"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Pembayaran selesai'},
          {'title': 'Mobile Banking BRI', 'content': '1. Login ke aplikasi BRI Mobile\n2. Pilih "Pembayaran" > "BRIVA"\n3. Masukkan nomor Virtual Account\n4. Konfirmasi detail pembayaran\n5. Masukkan PIN\n6. Pembayaran selesai'},
        ];
        break;

      case 'mandiri_va':
        instructions = [
          {'title': 'ATM Mandiri', 'content': '1. Masukkan kartu ATM dan PIN\n2. Pilih "Bayar/Beli" > "Multi Payment"\n3. Masukkan kode perusahaan 70012\n4. Masukkan nomor Virtual Account\n5. Konfirmasi detail pembayaran\n6. Pembayaran selesai'},
          {'title': 'Mobile Banking Mandiri', 'content': '1. Login ke aplikasi Livin by Mandiri\n2. Pilih "Pembayaran" > "Multi Payment"\n3. Cari "Midtrans"\n4. Masukkan nomor Virtual Account\n5. Konfirmasi detail pembayaran\n6. Masukkan MPIN\n7. Pembayaran selesai'},
        ];
        break;

      default:
        instructions = [
          {'title': 'ATM', 'content': 'Silahkan hubungi bank Anda untuk petunjuk pembayaran.'},
          {'title': 'Mobile Banking', 'content': 'Silahkan hubungi bank Anda untuk petunjuk pembayaran.'},
        ];
    }

    return Column(
      children: instructions.map((instruction) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: appTheme.orange200.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                instruction['title']!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              instruction['content']!,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';

    double priceDouble;
    if (price is int) {
      priceDouble = price.toDouble();
    } else if (price is String) {
      priceDouble = double.tryParse(price) ?? 0.0;
    } else if (price is double) {
      priceDouble = price;
    } else {
      return '0';
    }

    final String priceString = priceDouble.toStringAsFixed(0);
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
}