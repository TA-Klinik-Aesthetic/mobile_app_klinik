import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';

class PurchaseProductScreen extends StatefulWidget {
  final int purchaseId;

  const PurchaseProductScreen({Key? key, required this.purchaseId}) : super(key: key);

  @override
  State<PurchaseProductScreen> createState() => _PurchaseProductScreenState();
}

class _PurchaseProductScreenState extends State<PurchaseProductScreen> {
  bool isLoading = true;
  Map<String, dynamic> purchaseData = {};
  Map<int, Map<String, dynamic>> productsData = {}; // To store product details

  @override
  void initState() {
    super.initState();
    fetchPurchaseDetails();
  }

  Future<void> fetchPurchaseDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.penjualanProduk}/${widget.purchaseId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          purchaseData = data;
        });

        // Fetch product details for each item
        List<dynamic> detailPembelian = data['detail_pembelian'] ?? [];
        for (var item in detailPembelian) {
          int productId = item['id_produk'];
          await fetchProductDetails(productId);
        }

        setState(() {
          isLoading = false;
        });
      } else {
        _showMessage('Gagal memuat detail pembelian');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchProductDetails(int productId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.product}/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          setState(() {
            productsData[productId] = responseData['data'];
          });
        }
      }
    } catch (e) {
      print('Error fetching product $productId: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    final String monthName = _getIndonesianMonth(dateTime.month);
    return '${dateTime.day} $monthName ${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getIndonesianMonth(int month) {
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1]; // Arrays are 0-indexed but months are 1-indexed
  }

  Widget _buildPurchaseDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Purchase header with status
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pembelian',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purchaseData['status_pembayaran'] == 'Sudah Dibayar'
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      purchaseData['status_pembayaran'] ?? 'Belum Dibayar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: purchaseData['status_pembayaran'] == 'Sudah Dibayar'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'ID Pembelian: #PURCH${purchaseData['id_penjualan_produk']}',
                style: TextStyle(
                  fontSize: 14,
                  color: appTheme.black900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tanggal: ${_formatDate(purchaseData['tanggal_pembelian'])}',
                style: TextStyle(
                  fontSize: 14,
                  color: appTheme.black900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Order items
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
                'Detail Produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 6),

              // List of purchased items
              ...((purchaseData['detail_pembelian'] as List<dynamic>?) ?? []).map((item) {
                final price = double.tryParse(item['harga_penjualan_produk'].toString()) ?? 0;
                final quantity = item['jumlah_produk'] ?? 0;
                final subtotal = price * quantity;
                final discount = double.tryParse(purchaseData['potongan_harga']?.toString() ?? '0') ?? 0.0;
                final afterDiscount = subtotal - discount;
                final tax = (afterDiscount * 0.10).clamp(0, double.infinity);
                final productId = item['id_produk'];
                final productData = productsData[productId];
                final imageUrl = productData?['gambar_produk'] ?? '';
                final productName = productData?['nama_produk'] ?? 'Produk #$productId';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Product details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_formatPrice(price)} x ${item['jumlah_produk']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Subtotal
                      Text(
                        'Rp ${_formatPrice(subtotal)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: appTheme.orange200,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Price summary
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
                'Ringkasan Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.black900,
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice(purchaseData['harga_total'])}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (purchaseData['id_promo'] != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Potongan',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.orange200,
                      ),
                    ),
                    Text(
                      '- Rp ${_formatPrice(purchaseData['potongan_harga'])}',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // In the payment summary section, add a row for tax:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pajak 10%', style: TextStyle(fontSize: 14)),
                    Text(
                      '+ Rp ${_formatPrice(purchaseData['besaran_pajak'])}',
                      style: TextStyle(fontSize: 14, color: appTheme.darkCherry),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              const Divider(),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice(purchaseData['harga_akhir'])}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: appTheme.orange200,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          'Detail Pembelian',
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : purchaseData.isEmpty
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
              'Data pembelian tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildPurchaseDetails(),
      ),
      bottomNavigationBar: purchaseData.isNotEmpty && purchaseData['status_pembayaran'] == 'Belum Dibayar'
          ? Container(
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
          onPressed: () {
            _showMessage('Fitur pembayaran belum tersedia');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.orange200,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Bayar Sekarang',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      )
          : null,
    );
  }
}