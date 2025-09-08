import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _sortOption = 'Terbaru';           // 'Terbaru' | 'Pertama'
  String _paymentFilter = 'Semua';          // 'Semua' | 'Belum Dibayar' | 'Sudah Dibayar'
  String _pickupFilter = 'Semua';           // 'Semua' | 'Sudah diambil' | 'Belum diambil'
  List<dynamic> _filteredPurchases = [];

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
        // Terapkan filter setiap selesai fetch
        _applyFilters();
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

  String _normalizedStatus(Map<String, dynamic> purchase) {
    final nested = purchase['pembayaran_produk'];
    final raw = (nested is Map
            ? nested['status_pembayaran']
            : purchase['status_pembayaran'])
        ?.toString()
        .trim()
        .toLowerCase();

    if (raw == null) return 'Pending';

    const successList = ['sudah dibayar', 'berhasil', 'settlement', 'success', 'paid'];
    if (successList.contains(raw)) return 'Berhasil';

    // Selain success dianggap pending
    const pendingList = ['pending', 'belum dibayar', 'unpaid', 'menunggu pembayaran'];
    if (pendingList.contains(raw)) return 'Pending';

    // Default
    return 'Pending';
  }

  Color _badgeBgColor(String normalized) {
    if (normalized == 'Berhasil') {
      return Colors.green.withOpacity(0.15);
    }
    return Colors.amber.withOpacity(0.25); // kuning untuk Pending
  }

  Color _badgeFgColor(String normalized) {
    if (normalized == 'Berhasil') {
      return Colors.green.shade700;
    }
    return Colors.amber.shade800;
  }

  Widget _buildStatusBadge(String normalized) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _badgeBgColor(normalized),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _badgeFgColor(normalized),
        ),
      ),
    );
  }

  void _applyFilters() {
    List<dynamic> list = List<dynamic>.from(_purchases);

    // Filter Pembayaran
    if (_paymentFilter == 'Belum Dibayar') {
      list = list.where((p) => _normalizedStatus(p) == 'Pending').toList();
    } else if (_paymentFilter == 'Sudah Dibayar') {
      list = list.where((p) => _normalizedStatus(p) == 'Berhasil').toList();
    }

    // Filter Pengambilan
    if (_pickupFilter != 'Semua') {
      final target = _pickupFilter.toLowerCase();
      list = list.where((p) {
        final raw = p['status_pengambilan_produk']?.toString().toLowerCase();
        return raw == target;
      }).toList();
    }

    // Urutkan
    int cmpDate(dynamic a, dynamic b) {
      DateTime pa;
      DateTime pb;
      try {
        pa = DateTime.parse(a['tanggal_pembelian'].toString());
      } catch (_) {
        pa = DateTime.fromMillisecondsSinceEpoch(0);
      }
      try {
        pb = DateTime.parse(b['tanggal_pembelian'].toString());
      } catch (_) {
        pb = DateTime.fromMillisecondsSinceEpoch(0);
      }
      return pa.compareTo(pb);
    }

    if (_sortOption == 'Terbaru') {
      list.sort((a, b) => -cmpDate(a, b)); // desc
    } else {
      list.sort(cmpDate); // asc
    }

    setState(() {
      _filteredPurchases = list;
    });
  }

  // ================== NEW: UI helper Filter Chip ==================
  Widget _buildFilterChip({
    required String label,
    required String selected,
    required String defaultValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
    required VoidCallback onReset,
  }) {
    final bool isDefault = selected == defaultValue;

    Future<void> openOptions() async {
      final result = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appTheme.black900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...options.map((o) {
                  final bool sel = o == selected;
                  return ListTile(
                    title: Text(o),
                    trailing: sel ? Icon(Icons.check, color: appTheme.orange200) : null,
                    onTap: () => Navigator.pop(context, o),
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (result != null) onSelected(result);
    }

    final Color bg = isDefault ? Colors.white : appTheme.orange200.withAlpha(50);
    final Color fg = isDefault ? appTheme.black900 : appTheme.orange200;
    final Color border = isDefault ? Colors.grey.shade300 : appTheme.orange200;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDefault)
            InkWell(
              onTap: onReset,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(Icons.close, size: 16, color: fg),
              ),
            ),
          InkWell(
            onTap: openOptions,
            borderRadius: isDefault
                ? BorderRadius.circular(20)
                : const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label: ',
                    style: TextStyle(fontSize: 14, color: isDefault ? Colors.grey.shade600 : appTheme.black900),
                  ),
                  Text(
                    selected,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 18, color: fg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        color: appTheme.orange200,
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
                        // Index 0 = header filter, sisanya item list.
                        itemCount: (_filteredPurchases.isEmpty ? 2 : _filteredPurchases.length + 1),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Bar Filter Horizontal
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                      label: 'Urutkan',
                                      selected: _sortOption,
                                      defaultValue: 'Terbaru',
                                      options: const ['Terbaru', 'Pertama'],
                                      onSelected: (val) {
                                        setState(() => _sortOption = val);
                                        _applyFilters();
                                      },
                                    onReset: () {
                                        setState(() => _sortOption = 'Terbaru');
                                        _applyFilters();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Pembayaran',
                                      selected: _paymentFilter,
                                      defaultValue: 'Semua',
                                      options: const ['Semua', 'Belum Dibayar', 'Sudah Dibayar'],
                                      onSelected: (val) {
                                        setState(() => _paymentFilter = val);
                                        _applyFilters();
                                      },
                                      onReset: () {
                                        setState(() => _paymentFilter = 'Semua');
                                        _applyFilters();
                                      },
                                    ),
                                    _buildFilterChip(
                                      label: 'Pengambilan',
                                      selected: _pickupFilter,
                                      defaultValue: 'Semua',
                                      options: const ['Semua', 'Sudah diambil', 'Belum diambil'],
                                      onSelected: (val) {
                                        setState(() => _pickupFilter = val);
                                        _applyFilters();
                                      },
                                      onReset: () {
                                        setState(() => _pickupFilter = 'Semua');
                                        _applyFilters();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // Jika hasil filter kosong, tampilkan pesan
                          if (_filteredPurchases.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text(
                                  'Tidak ada data sesuai filter',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              ),
                            );
                          }

                          final purchase = _filteredPurchases[index - 1];
                          final String purchaseId = purchase['id_penjualan_produk'].toString();
                          final String date = purchase['tanggal_pembelian']?.toString() ?? '';
                          final String total = _formatPrice(purchase['harga_akhir']);
                          final String normalizedStatus = _normalizedStatus(purchase);

                          // Get first product details
                          String thumbnailUrl = '';
                          String productName = '';
                          int firstProductQuantity = 0;
                          int totalProducts = 0;
                          int totalItems = 0;

                          if (purchase['detail_pembelian'] != null &&
                              purchase['detail_pembelian'] is List &&
                              purchase['detail_pembelian'].isNotEmpty) {
                            final detailPembelian = purchase['detail_pembelian'] as List;
                            totalProducts = detailPembelian.length;

                            if (detailPembelian[0]['produk'] != null) {
                              thumbnailUrl = detailPembelian[0]['produk']['gambar_produk'] ?? '';
                              productName = detailPembelian[0]['produk']['nama_produk'] ?? '';
                              firstProductQuantity = int.tryParse(
                                    detailPembelian[0]['jumlah_produk']?.toString() ?? '0',
                                  ) ??
                                  0;
                            }

                            for (var item in detailPembelian) {
                              totalItems += int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: appTheme.whiteA700,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: appTheme.black900, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row with Pembelian title and status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Pembelian',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      _buildStatusBadge(normalizedStatus),
                                    ],
                                  ),

                                  // Date
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const Divider(height: 24),

                                  // Product details row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: thumbnailUrl.isNotEmpty
                                            ? Image.network(
                                                ApiConstants.getImageUrl(thumbnailUrl),
                                                width: 75,
                                                height: 75,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 75,
                                                    height: 75,
                                                    color: Colors.grey[300],
                                                    child: const Icon(Icons.image_not_supported),
                                                  );
                                                },
                                              )
                                            : Container(
                                                width: 75,
                                                height: 75,
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.shopping_bag),
                                              ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Product info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productName,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$firstProductQuantity item',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                            ),
                                            if (totalProducts > 1)
                                              Text(
                                                '+ ${totalProducts - 1} produk lainnya',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Divider(height: 24),

                                  // Footer with total and button
                                  Row(
                                    children: [
                                      // Total info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total $totalItems Produk',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rp $total',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: appTheme.orange200,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Detail button
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PurchaseProductScreen(
                                                purchaseId: purchase['id_penjualan_produk'],
                                              ),
                                            ),
                                          ).then((_) => fetchPurchaseHistory());
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: appTheme.lightGreen,
                                          foregroundColor: appTheme.black900,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: appTheme.lightGreenOld, width: 1),
                                          ),
                                        ),
                                        child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}