import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/payment_screen/payment_success_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'dart:typed_data';
import 'dart:io';
import '../../core/app_export.dart';
import '../../api/api_constant.dart';

class PaymentQrisScreen extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final Map<String, dynamic> paymentInfo;
  final String paymentMethod;
  final String orderId;

  const PaymentQrisScreen({
    Key? key,
    required this.paymentData,
    required this.paymentInfo,
    required this.paymentMethod,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentQrisScreen> createState() => _PaymentQrisScreenState();
}

class _PaymentQrisScreenState extends State<PaymentQrisScreen> {
  bool isLoading = false;
  String? errorMessage;
  late Timer _statusCheckTimer;
  final int _statusCheckInterval = 5;
  bool _isMounted = false;
  final GlobalKey qrKey = GlobalKey();

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

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/midtrans/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': widget.orderId}),
      );

      if (!_isMounted) return;

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
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _saveQrToGallery() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get the RenderRepaintBoundary object
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes != null) {
        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/QRIS_Payment_${widget.orderId}.png');
        await file.writeAsBytes(imageBytes);

        // Share the image
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QRIS Payment untuk ${_getWalletName()}',
          subject: 'Pembayaran via ${_getWalletName()}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR Code berhasil dibagikan'),
              backgroundColor: appTheme.orange200,
              behavior: SnackBarBehavior.floating,
            )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getWalletName() {
    switch (widget.paymentMethod) {
      case 'gopay': return 'GoPay';
      case 'shopeepay': return 'ShopeePay';
      default: return 'QRIS';
    }
  }

  String _getWalletLogo() {
    switch (widget.paymentMethod) {
      case 'gopay': return 'assets/images/gopay_logo.png';
      case 'shopeepay': return 'assets/images/shopeepay_logo.png';
      default: return 'assets/images/qris_logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String qrCodeUrl = widget.paymentData['qr_code_url'] ??
        widget.paymentData['actions']?.firstWhere(
                (action) => action['name'] == 'qr-code',
            orElse: () => {'url': ''})['url'] ?? '';
    final String walletName = _getWalletName();
    final String expiryTime = widget.paymentData['expiry_time'] ?? 'Unknown';
    final double amount = double.tryParse(widget.paymentInfo['nominal_pembayaran']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Pembayaran $walletName',
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

            // QR Code
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        _getWalletLogo(),
                        height: 40,
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Scan QR Code di bawah ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RepaintBoundary(
                    key: qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          if (qrCodeUrl.isNotEmpty)
                            Image.network(
                              qrCodeUrl,
                              height: 200,
                              width: 200,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: Text(
                                      'Gagal memuat QR Code',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            SizedBox(
                              height: 200,
                              width: 200,
                              child: Center(
                                child: Text(
                                  'QR Code tidak tersedia',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
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
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _saveQrToGallery(),
                        icon: Icon(Icons.download, color: Colors.white),
                        label: Text(
                          'Simpan QR Code',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appTheme.orange200,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                  _buildInstructions(walletName),
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
                Share.share('Silahkan scan QR Code untuk melakukan pembayaran via $walletName sebesar Rp ${_formatPrice(amount)}');
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

  Widget _buildInstructions(String walletName) {
    List<String> instructions;

    switch (widget.paymentMethod) {
      case 'gopay':
        instructions = [
          '1. Buka aplikasi Gojek di smartphone Anda',
          '2. Tap "Bayar" pada halaman utama',
          '3. Tap "Scan QR" atau ikon kamera',
          '4. Scan QR code yang ditampilkan di atas',
          '5. Periksa jumlah yang akan dibayar',
          '6. Tap "Bayar" dan konfirmasi pembayaran',
          '7. Pembayaran selesai'
        ];
        break;

      case 'shopeepay':
        instructions = [
          '1. Buka aplikasi Shopee di smartphone Anda',
          '2. Tap "ShopeePay" pada halaman utama',
          '3. Tap "Scan" untuk memindai kode QR',
          '4. Scan QR code yang ditampilkan di atas',
          '5. Periksa detail pembayaran',
          '6. Masukkan PIN ShopeePay Anda',
          '7. Pembayaran selesai'
        ];
        break;

      default:
        instructions = [
          '1. Buka aplikasi mobile banking atau e-wallet Anda',
          '2. Pilih opsi scan QR atau QRIS',
          '3. Scan QR code yang ditampilkan di atas',
          '4. Periksa jumlah yang akan dibayar',
          '5. Konfirmasi pembayaran',
          '6. Pembayaran selesai'
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: instructions.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            step,
            style: TextStyle(fontSize: 14),
          ),
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