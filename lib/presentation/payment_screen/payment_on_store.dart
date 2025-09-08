import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/presentation/product_screen/purchase_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';

class PaymentOnStoreScreen extends StatefulWidget {
  final String paymentId;
  final double amount;
  final int? productSaleId; // Add this parameter

  const PaymentOnStoreScreen({
    super.key,
    required this.paymentId,
    required this.amount,
    this.productSaleId, // Add this parameter
  });

  @override
  State<PaymentOnStoreScreen> createState() => _PaymentOnStoreScreenState();
}

class _PaymentOnStoreScreenState extends State<PaymentOnStoreScreen> {
  bool isLoading = false;
  Map<String, dynamic> paymentData = {};

  @override
  void initState() {
    super.initState();
    _fetchPaymentDetails();
  }

  Future<void> _fetchPaymentDetails() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.pembayaranProduk}/${widget.paymentId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return; // Check mounted before setState

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          paymentData = data;
        });
      } else {
        _showMessage('Gagal memuat data pembayaran');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: appTheme.orange200,
      ),
    );
  }

  void _navigateBack() {
    if (!mounted) return;

    // Extract id_penjualan_produk from API response
    int? purchaseId;
    
    if (paymentData['data'] != null) {
      final data = paymentData['data'];
      
      // Try to get from direct field first
      final rawPurchaseId = data['id_penjualan_produk'];
      if (rawPurchaseId != null) {
        if (rawPurchaseId is int) {
          purchaseId = rawPurchaseId;
        } else if (rawPurchaseId is String) {
          purchaseId = int.tryParse(rawPurchaseId);
        }
      }
      
      // If not found, try to get from nested penjualan_produk
      if (purchaseId == null && data['penjualan_produk'] != null) {
        final nestedPurchaseId = data['penjualan_produk']['id_penjualan_produk'];
        if (nestedPurchaseId is int) {
          purchaseId = nestedPurchaseId;
        } else if (nestedPurchaseId is String) {
          purchaseId = int.tryParse(nestedPurchaseId);
        }
      }
    }

    // Use purchaseId from API response, fallback to widget.productSaleId
    final finalPurchaseId = purchaseId ?? widget.productSaleId;

    if (finalPurchaseId != null) {
      // Navigate back to PurchaseProductScreen with correct ID
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PurchaseProductScreen(
            purchaseId: finalPurchaseId,
          ),
        ),
      );
    } else {
      // Default navigation to home if no ID available
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Pembayaran Tunai',
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appTheme.black900),
          onPressed: _navigateBack,
        ),
      ),
      body: RefreshIndicator(
        color: appTheme.orange200,
        onRefresh: _fetchPaymentDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),

              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: appTheme.orange200,
              ),

              const SizedBox(height: 24),

              Text(
                'Tunjukan ke Kasir',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: appTheme.black900,
                ),
              ),

              const SizedBox(height: 32),

              // Price display with orange border
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: appTheme.orange200, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp ${_formatPrice(widget.amount)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Payment ID
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'ID Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PAY${widget.paymentId}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: appTheme.black900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Status pembayaran
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Text(
                  'Menunggu Pembayaran',
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
          onPressed: _navigateBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.orange200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            widget.productSaleId != null ? 'Kembali ke Detail Pembelian' : 'Kembali ke Beranda',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
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