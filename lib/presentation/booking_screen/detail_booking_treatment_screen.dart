import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'model/promo_model.dart';

class DetailBookingTreatmentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedTreatments;

  const DetailBookingTreatmentScreen({super.key, required this.selectedTreatments});

  @override
  State<DetailBookingTreatmentScreen> createState() => _DetailBookingTreatmentScreenState();
}

class _DetailBookingTreatmentScreenState extends State<DetailBookingTreatmentScreen> {
  late List<Map<String, dynamic>> _treatments;
  List<Promo> _promos = [];
  Promo? _selectedPromo;
  bool _isLoadingPromos = false;
  final PromoService _promoService = PromoService();

  @override
  void initState() {
    super.initState();
    // Create a copy of the list to avoid modifying the original
    _treatments = List.from(widget.selectedTreatments);
    _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    setState(() {
      _isLoadingPromos = true;
    });

    try {
      final promos = await _promoService.fetchPromos();
      setState(() {
        _promos = promos;
        _isLoadingPromos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPromos = false;
      });
      print('Error fetching promos: $e');
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin ingin menghapusnya dari cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Tidak jadi',
                style: TextStyle(color: appTheme.lightGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Remove the item
                setState(() {
                  _treatments.removeAt(index);
                  // If all treatments removed, clear promo too
                  if (_treatments.isEmpty) {
                    _selectedPromo = null;
                  }
                });
                Navigator.of(context).pop(); // Close dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ya, saya ingin',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
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

  double _calculateTotalPrice() {
    double total = 0.0;
    for (var t in _treatments) {
      if (t['biaya_treatment'] != null) {
        if (t['biaya_treatment'] is int) {
          total += (t['biaya_treatment'] as int).toDouble();
        } else if (t['biaya_treatment'] is String) {
          total += double.tryParse(t['biaya_treatment']) ?? 0.0;
        } else if (t['biaya_treatment'] is double) {
          total += (t['biaya_treatment'] as double);
        }
      }
    }
    return total;
  }

  double _calculateFinalPrice() {
    double totalPrice = _calculateTotalPrice();
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    return totalPrice - discount;
  }

  String _formatEstimasi(String estimasi) {
    try {
      final parts = estimasi.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);

        String formattedTime = '';
        if (hours > 0) {
          formattedTime += '$hours jam';
        }
        if (minutes > 0) {
          if (hours > 0) formattedTime += ' ';
          formattedTime += '$minutes menit';
        }
        return formattedTime.isEmpty ? '0 menit' : formattedTime;
      }
      return estimasi;
    } catch (e) {
      return estimasi;
    }
  }

  void _showPromoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPromoBottomSheet(),
    );
  }

  Widget _buildPromoBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Promo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appTheme.black900,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedPromo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPromo = null;
                  });
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text('Hapus Promo', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoadingPromos
                ? const Center(child: CircularProgressIndicator())
                : _promos.isEmpty
                ? _buildEmptyPromoState()
                : _buildPromoList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromoState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.discount_outlined,
            size: 60,
            color: appTheme.lightGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada promo yang tersedia saat ini',
            style: TextStyle(
              fontSize: 16,
              color: appTheme.black900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoList() {
    return ListView.builder(
      itemCount: _promos.length,
      itemBuilder: (context, index) {
        final promo = _promos[index];
        bool isSelected = _selectedPromo != null &&
            _selectedPromo!.idPromo == promo.idPromo;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? appTheme.orange200 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPromo = promo;
              });
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          promo.namaPromo ?? 'Promo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appTheme.orange200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promo.formatPromoValue(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo.deskripsiPromo ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.black900.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Periode: ${promo.formatDate(promo.tanggalMulai)} - ${promo.formatDate(promo.tanggalBerakhir)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: appTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoButton() {
    return InkWell(
      onTap: _showPromoBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.discount_outlined,
              color: appTheme.orange200,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedPromo != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Promo diterapkan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _selectedPromo!.namaPromo ?? 'Promo',
                    style: TextStyle(
                      fontSize: 14,
                      color: appTheme.black900.withOpacity(0.7),
                    ),
                  ),
                ],
              )
                  : const Text(
                'Gunakan Promo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: appTheme.lightGrey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ringkasan Booking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
      ),
      body: _treatments.isEmpty
          ? Center(
        child: Text(
          'Tidak ada treatment yang dipilih.',
          style: TextStyle(fontSize: 16, color: appTheme.lightGrey),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Show treatments
                ...List.generate(_treatments.length, (index) {
                  final treatment = _treatments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: treatment['gambar_treatment'] != null &&
                                treatment['gambar_treatment'].toString().isNotEmpty
                                ? Image.network(
                              treatment['gambar_treatment'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  treatment['nama_treatment'] ?? 'Unnamed Treatment',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rp ${_formatPrice(treatment['biaya_treatment'])}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: appTheme.orange200,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Durasi: ${_formatEstimasi(treatment['estimasi_treatment'] ?? '00:00:00')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: appTheme.lightGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: appTheme.lightGrey),
                            onPressed: () => _showDeleteConfirmation(context, index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Add promo button
                const SizedBox(height: 16),
                _buildPromoButton(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appTheme.whiteA700,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add discount row if promo is selected
                if (_selectedPromo != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Rp ${_formatPrice(_calculateTotalPrice())}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Diskon:',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: appTheme.orange200.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedPromo!.namaPromo ?? 'Promo',
                              style: TextStyle(
                                fontSize: 12,
                                color: appTheme.orange200,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '- Rp ${_formatPrice(_selectedPromo!.calculateDiscount(_calculateTotalPrice()))}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: appTheme.orange200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                      ),
                    ),
                    Text(
                      'Rp ${_formatPrice(_calculateFinalPrice())}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _treatments.isEmpty ? null : () {
                      // Implement final booking process here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Melanjutkan ke proses pembayaran...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.orange200,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Konfirmasi dan Bayar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}