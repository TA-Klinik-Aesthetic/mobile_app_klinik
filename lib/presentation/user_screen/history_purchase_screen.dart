import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';
import '../product_screen/purchase_product_screen.dart';

class HistoryPurchaseScreen extends StatefulWidget {
  const HistoryPurchaseScreen({super.key});

  @override
  State<HistoryPurchaseScreen> createState() => _HistoryPurchaseScreenState();
}

class _HistoryPurchaseScreenState extends State<HistoryPurchaseScreen> {
  bool _isLoading = true;
  List<dynamic> _purchases = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchPurchaseHistory();
  }

  Future<void> fetchPurchaseHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Silakan login terlebih dahulu';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.penjualanProdukUser.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _purchases = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _error = errorData['message'] ?? 'Gagal memuat riwayat pembelian';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
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

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return '${dateTime.day} ${_getIndonesianMonth(dateTime.month)} ${dateTime.year}';
  }

  String _getIndonesianMonth(int month) {
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    if (status == 'Sudah Dibayar') {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Riwayat Pembelian',
          style: TextStyle(
            color: appTheme.orange200,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: appTheme.black900),
      ),
      body: RefreshIndicator(
        onRefresh: fetchPurchaseHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : _purchases.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada riwayat pembelian',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _purchases.length,
          itemBuilder: (context, index) {
            final purchase = _purchases[index];
            final String purchaseId = purchase['id_penjualan_produk'].toString();
            final String date = _formatDate(purchase['tanggal_pembelian']);
            final String total = _formatPrice(purchase['harga_akhir']);
            final String status = purchase['status_pembayaran'];

            // Get first product image for thumbnail
            String thumbnailUrl = '';
            if (purchase['detail_pembelian'] != null &&
                purchase['detail_pembelian'].isNotEmpty &&
                purchase['detail_pembelian'][0]['produk'] != null) {
              thumbnailUrl = purchase['detail_pembelian'][0]['produk']['gambar_produk'] ?? '';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PurchaseProductScreen(
                        purchaseId: purchase['id_penjualan_produk'],
                      ),
                    ),
                  ).then((_) => fetchPurchaseHistory()); // Refresh on return
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: appTheme.lightBadge100,
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
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: thumbnailUrl.isNotEmpty
                            ? Image.network(
                          thumbnailUrl,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                            : Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.shopping_bag),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Purchase details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#PURCH$purchaseId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total: Rp $total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: appTheme.orange200,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow indicator
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: appTheme.black900,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}