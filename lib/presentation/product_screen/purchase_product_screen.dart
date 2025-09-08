import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/core/services/pdf_generator.dart';
import 'package:mobile_app_klinik/presentation/payment_screen/payment_screen.dart';
import 'package:mobile_app_klinik/widgets/ereceipt_screen.dart';
import 'package:printing/printing.dart';
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
  bool isRefreshingPayment = false;
  Map<String, dynamic> purchaseData = {};
  Map<int, Map<String, dynamic>> productsData = {}; // To store product details

  @override
  void initState() {
    super.initState();
    fetchPurchaseDetails();
  }

  Future<void> _refreshPaymentStatus() async {
    // Get payment ID from purchase data
    final String? paymentId = purchaseData['pembayaran_produk']?['id_pembayaran']?.toString();
    
    if (paymentId == null) {
      _showMessage('ID pembayaran tidak ditemukan');
      return;
    }

    setState(() {
      isRefreshingPayment = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() {
          isRefreshingPayment = false;
        });
        return;
      }

      // Call refresh payment API
      final String refreshUrl = ApiConstants.refreshPembayaranMidtrans
          .replaceAll('{id_pembayaran}', paymentId);

      print('=== REFRESHING PAYMENT STATUS ===');
      print('Payment ID: $paymentId');
      print('URL: $refreshUrl');

      final response = await http.get(
        Uri.parse(refreshUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Refresh response status: ${response.statusCode}');
      print('Refresh response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Payment status refreshed successfully');
        
        // Show success message
        _showMessage('Status pembayaran berhasil diperbarui');
        
        // Refresh the entire purchase data to get updated payment status
        await fetchPurchaseDetails();
        
      } else {
        print('Failed to refresh payment status: ${response.statusCode}');
        
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Gagal memperbarui status pembayaran';
          _showMessage(errorMessage);
        } catch (e) {
          _showMessage('Gagal memperbarui status pembayaran');
        }
      }
    } catch (e) {
      print('Error refreshing payment status: $e');
      _showMessage('Error: $e');
    } finally {
      setState(() {
        isRefreshingPayment = false;
      });
    }
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

        // ✅ Fetch product details for each item using correct field names
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
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ✅ Build Product Details Section - Updated to match API structure
  Widget _buildProductDetails() {
    final List<dynamic> detailPembelian = purchaseData['detail_pembelian'] ?? [];
    
    if (detailPembelian.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          // ✅ Product items list - Updated field names
          ...detailPembelian.map<Widget>((item) {
            final dynamic rawProductId = item['id_produk'];
            int? productId;

            if (rawProductId is int) {
              productId = rawProductId;
            } else if (rawProductId is String) {
              productId = int.tryParse(rawProductId);
            }

            final Map<String, dynamic>? productData = productId != null ? productsData[productId] : null;
            final String productName = productData?['nama_produk'] ?? 'Produk Tidak Diketahui';
            final String productImage = productData?['gambar_produk'] ?? '';
            
            // ✅ Use correct field names from API
            final int quantity = int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
            final double itemPrice = double.tryParse(item['harga_penjualan_produk']?.toString() ?? '0') ?? 0.0;
            final double totalItemPrice = itemPrice * quantity;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Product Image
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: productImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ApiConstants.getImageUrl(productImage),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey.shade500,
                                  size: 30,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag,
                            color: Colors.grey.shade500,
                            size: 30,
                          ),
                  ),
                  const SizedBox(width: 16),
                  // ✅ Product Details - Layout like in the image
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Price per item x quantity
                        Text(
                          'Rp ${_formatPrice(itemPrice)} x $quantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✅ Total Price on the right - Orange color like in image
                  Text(
                    'Rp ${_formatPrice(totalItemPrice)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: appTheme.orange200,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
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
                // ✅ Status and refresh button row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (purchaseData['pembayaran_produk'] != null &&
                            (purchaseData['pembayaran_produk']['status_pembayaran'] == 'Sudah Dibayar' ||
                            purchaseData['pembayaran_produk']['status_pembayaran'] == 'Berhasil'))
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        purchaseData['pembayaran_produk']?['status_pembayaran'] ?? 'Belum Dibayar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (purchaseData['pembayaran_produk']?['status_pembayaran'] == 'Sudah Dibayar' ||
                                purchaseData['pembayaran_produk']?['status_pembayaran'] == 'Berhasil')
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ✅ Refresh button - only show if payment exists
                    if (purchaseData['pembayaran_produk'] != null &&
                        purchaseData['pembayaran_produk']['id_pembayaran'] != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isRefreshingPayment ? null : _refreshPaymentStatus,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: appTheme.orange200.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: appTheme.orange200.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: isRefreshingPayment
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: appTheme.orange200,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // ID Pembelian
            _buildInfoRow(
                'ID Pembelian',
                '#PURC${purchaseData['id_penjualan_produk']}'
            ),
            const SizedBox(height: 12),
            // Waktu Pembelian
            _buildInfoRow(
                'Waktu Pembelian',
                _formatDate(purchaseData['tanggal_pembelian'])
            ),
            const SizedBox(height: 12),
            // ✅ Status pengambilan produk
            _buildInfoRow(
              'Status Pengambilan',
              purchaseData['status_pengambilan_produk'] ?? 'Belum diambil'
            ),
            if (purchaseData['waktu_pengambilan'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Waktu Pengambilan',
                _formatDate(purchaseData['waktu_pengambilan'])
              ),
            ],
            const SizedBox(height: 12),
            // ✅ REMOVED ID Pembayaran and Order ID - only show basic payment info
            if (purchaseData['pembayaran_produk'] != null) ...[
              _buildInfoRow(
                'Metode Pembayaran',
                purchaseData['pembayaran_produk']['metode_pembayaran'] ?? 'Tunai'
              ),
              if (purchaseData['pembayaran_produk']['waktu_pembayaran'] != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Waktu Pembayaran',
                  _formatDate(purchaseData['pembayaran_produk']['waktu_pembayaran'])
                ),
              ],
            ],
          ],
        ),
      ),

        // ✅ Show refresh helper text if payment is pending
        if (purchaseData['pembayaran_produk'] != null &&
            (purchaseData['pembayaran_produk']['status_pembayaran'] == 'Pending' ||
             purchaseData['pembayaran_produk']['status_pembayaran'] == 'Belum Dibayar'))
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gunakan tombol refresh untuk memperbarui status pembayaran secara manual',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ✅ Add Product Details Section
        _buildProductDetails(),

        const SizedBox(height: 16),

        // ✅ Price summary - Updated to match API structure
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

              // ✅ Show discount if promo was applied
              if (purchaseData['id_promo'] != null && 
                  purchaseData['potongan_harga'] != null &&
                  double.tryParse(purchaseData['potongan_harga'].toString()) != 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Potongan',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.black900,
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
              ],

              // ✅ Show tax if applied
              if (purchaseData['besaran_pajak'] != null &&
                  double.tryParse(purchaseData['besaran_pajak'].toString()) != 0) ...[
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchPurchaseDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
              ),
              child: const Text('Refresh', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchPurchaseDetails,
        color: appTheme.orange200,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildPurchaseDetails(),
        ),
      ),
      bottomNavigationBar: () {
        final String? paymentStatus = purchaseData['pembayaran_produk']?['status_pembayaran'];
        final bool needsPayment = paymentStatus == null || 
                                paymentStatus == 'Belum Dibayar' || 
                                paymentStatus == 'Pending';
        
        final bool isSuccessful = paymentStatus == 'Sudah Dibayar' || 
                                 paymentStatus == 'Berhasil' ||
                                 paymentStatus == 'settlement';

        return purchaseData.isNotEmpty
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
                child: isSuccessful
                    ? // ✅ E-Receipt buttons for successful payment
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EReceiptScreen.product(
                                      purchaseData: purchaseData,
                                      productsData: productsData,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.receipt_long, color: Colors.white),
                              label: const Text(
                                'E-Receipt',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appTheme.orange200,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : needsPayment
                        ? // ✅ Payment button for pending/unpaid
                          ElevatedButton(
                            onPressed: () {
                              // Existing payment logic
                              final dynamic rawSaleId = purchaseData['id_penjualan_produk'];
                              int? saleId;

                              if (rawSaleId is int) {
                                saleId = rawSaleId;
                              } else if (rawSaleId is String) {
                                saleId = int.tryParse(rawSaleId);
                              }

                              String productName = 'Pembelian Produk';
                              if (purchaseData['detail_pembelian'] != null &&
                                  purchaseData['detail_pembelian'].isNotEmpty) {
                                final int? productId = int.tryParse(
                                    purchaseData['detail_pembelian'][0]['id_produk'].toString()
                                );
                                if (productId != null && productsData.containsKey(productId)) {
                                  productName = productsData[productId]?['nama_produk'] ?? 'Pembelian Produk';
                                }
                              }

                              final double amount = double.tryParse(
                                  purchaseData['harga_akhir']?.toString() ?? '0'
                              ) ?? 0.0;

                              if (saleId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentScreen.product(
                                      productSaleId: saleId!,
                                      name: productName,
                                      price: amount,
                                    ),
                                  ),
                                ).then((result) {
                                  if (mounted) {
                                    fetchPurchaseDetails();
                                  }
                                });
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
                            child: Text(
                              paymentStatus == 'Pending' ? 'Lanjutkan Pembayaran' : 'Bayar Sekarang',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              )
            : null;
      }(),
    );
  }
}