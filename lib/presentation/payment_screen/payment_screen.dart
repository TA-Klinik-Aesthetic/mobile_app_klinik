import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';

class PaymentScreen extends StatefulWidget {
  final int? productSaleId;
  final int? appointmentId;
  final String name;
  final double price;
  final bool isProduct; // To differentiate between product and appointment payments

  // Constructor for product payments
  PaymentScreen.product({
    Key? key,
    required this.productSaleId,
    required this.name,
    required this.price,
  }) :
        appointmentId = null,
        isProduct = true,
        super(key: key);

  // Constructor for appointment payments (for future use)
  PaymentScreen.appointment({
    Key? key,
    required this.appointmentId,
    required this.name,
    required this.price,
  }) :
        productSaleId = null,
        isProduct = false,
        super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;
  String paymentMethod = 'cash'; // Default payment method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Pembayaran',
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
            // Payment header
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
                  // Total payment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rp ${_formatPrice(widget.price)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: appTheme.orange200,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment method selection
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
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cash payment option
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('Tunai (Bayar di Klinik)'),
                      ],
                    ),
                    value: 'cash',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),

                  // Transfer payment option
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('Mandiri (Virtual Account)'),
                      ],
                    ),
                    value: 'mandiri_va',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('BNI (Virtual Account)'),
                      ],
                    ),
                    value: 'bni_va',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('BRI (Virtual Account)'),
                      ],
                    ),
                    value: 'bri_va',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('BCA (Virtual Account)'),
                      ],
                    ),
                    value: 'bca_va',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.wallet,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('Go-Pay'),
                      ],
                    ),
                    value: 'gopay',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
                  ),
                  RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(
                          Icons.wallet,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 12),
                        const Text('ShopeePay'),
                      ],
                    ),
                    value: 'shopeepay',
                    groupValue: paymentMethod,
                    onChanged: (String? value) {
                      setState(() {
                        paymentMethod = value!;
                      });
                    },
                    activeColor: appTheme.orange200,
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
          onPressed: isLoading ? null : () => _processPayment(),
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.orange200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Text(
            'Konfirmasi Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {
        'id_user': userId,
        'metode_pembayaran': paymentMethod,
        'nominal_pembayaran': widget.price,
      };

      // Add the specific ID based on payment type
      if (widget.isProduct && widget.productSaleId != null) {
        requestBody['id_penjualan_produk'] = widget.productSaleId;
      } else if (!widget.isProduct && widget.appointmentId != null) {
        requestBody['id_booking'] = widget.appointmentId;
      }

      // Make API call
      final response = await http.post(
        Uri.parse(ApiConstants.pembayaranProduk),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage('Pembayaran berhasil dikonfirmasi');
        Navigator.pop(context, true); // Return success
      } else {
        _showMessage('Gagal memproses pembayaran. Silakan coba lagi.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: appTheme.orange200,
      ),
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