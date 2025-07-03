import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/payment_screen/payment_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../api/api_constant.dart';

class PurchaseProductScreen extends StatefulWidget {
  final int purchaseId;

  const PurchaseProductScreen({super.key, required this.purchaseId});

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

      // Fetch purchase details
      final response = await http.get(
        Uri.parse('${ApiConstants.penjualanProduk}/${widget.purchaseId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Purchase data: $data');

        setState(() {
          purchaseData = data;
        });

        // Fetch payment details for this purchase
        final paymentResponse = await http.get(
          Uri.parse(ApiConstants.pembayaranProduk),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (paymentResponse.statusCode == 200) {
          final List<dynamic> paymentsList = jsonDecode(paymentResponse.body);
          print('All payment data: $paymentsList');

          // Find payment for current purchase ID
          final paymentData = paymentsList.firstWhere(
                (payment) => payment['id_penjualan_produk'].toString() == widget.purchaseId.toString(),
            orElse: () => {},
          );

          print('Payment data for ID ${widget.purchaseId}: $paymentData');
          if (paymentData.isNotEmpty) {
            setState(() {
              // Store payment data
              purchaseData['payment_info'] = paymentData;
            });
          }
        } else {
          print('Failed to fetch payment data: ${paymentResponse.statusCode}');
        }

        // Fetch product details for each item
        List<dynamic> detailPembelian = data['detail_pembelian'] ?? [];
        for (var item in detailPembelian) {
          final dynamic rawId = item['id_produk'];
          int? productId;

          if (rawId is int) {
            productId = rawId;
          } else if (rawId is String) {
            productId = int.tryParse(rawId);
          }

          if (productId != null) {
            await fetchProductDetails(productId);
          } else {
            print('Invalid product ID format: $rawId');
          }
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

  /// Fetch product details by product ID
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
        print('Product data for $productId: ${responseData['data']}'); // Debug line
        if (responseData['data'] != null) {
          setState(() {
            productsData[productId] = responseData['data'];
          });
        }
      } else {
        print('Failed to fetch product $productId: ${response.statusCode}');
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: appTheme.black900.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
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
                      color: (purchaseData['pembayaran_produk'] != null &&
                          purchaseData['pembayaran_produk']['status_pembayaran'] == 'Sudah Dibayar')
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      purchaseData['pembayaran_produk']?['status_pembayaran'] ?? 'Belum Dibayar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: purchaseData['pembayaran_produk']?['status_pembayaran'] == 'Sudah Dibayar'
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
              // ID Booking
              _buildInfoRow(
                  'ID Pembelian',
                  '#PURCH${purchaseData['id_penjualan_produk']}'
              ),
              const SizedBox(height: 12),
              // Waktu Booking
              _buildInfoRow(
                  'Waktu Pembelian',
                  _formatDate(purchaseData['tanggal_pembelian'])
              ),
              const SizedBox(height: 12),
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
                final quantity = int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
                final subtotal = price * quantity;
                final discount = double.tryParse(purchaseData['potongan_harga']?.toString() ?? '0') ?? 0.0;
                final afterDiscount = subtotal - discount;
                final tax = (afterDiscount * 0.10).clamp(0, double.infinity);

                // Convert product ID to integer
                final productId = int.tryParse(item['id_produk'].toString()) ?? 0;
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
                      const SizedBox(height: 8),
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
                        color: appTheme.lightGreen,
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
      bottomNavigationBar: () {
        // Debug prints to check data structure
        print('Payment info available: ${purchaseData['payment_info'] != null}');
        if (purchaseData['payment_info'] != null) {
          print('Payment status: ${purchaseData['payment_info']['status_pembayaran']}');
        }

        // Fix: Check status directly from both possible locations
        final bool needsPayment =
        !(purchaseData['pembayaran_produk'] != null &&
            purchaseData['pembayaran_produk']['status_pembayaran'] == 'Sudah Dibayar');

        return purchaseData.isNotEmpty && needsPayment
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
              // Safely convert the ID to int
              final dynamic rawSaleId = purchaseData['id_penjualan_produk'];
              int? saleId;

              if (rawSaleId is int) {
                saleId = rawSaleId;
              } else if (rawSaleId is String) {
                saleId = int.tryParse(rawSaleId);
              }

              // Product name and price logic
              String productName = 'Produk';
              if (purchaseData['detail_pembelian'] != null &&
                  purchaseData['detail_pembelian'].isNotEmpty) {
                final int? productId = int.tryParse(purchaseData['detail_pembelian'][0]['id_produk'].toString());
                if (productId != null && productsData.containsKey(productId)) {
                  productName = productsData[productId]?['nama_produk'] ?? 'Produk';
                }
              }

              final double amount = double.tryParse(purchaseData['harga_akhir']?.toString() ?? '0') ?? 0.0;

              if (saleId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen.product(
                      productSaleId: saleId!, // Non-null assertion is safe here
                      name: productName,
                      price: amount,
                    ),
                  ),
                ).then((_) => fetchPurchaseDetails());
              } else {
                _showMessage('Data penjualan tidak ditemukan');
              }
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        )
            : null;
      }(),
    );
  }
}