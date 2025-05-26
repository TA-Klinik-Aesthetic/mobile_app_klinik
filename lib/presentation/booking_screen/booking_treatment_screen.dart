import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'detail_booking_treatment_screen.dart';

class BookingTreatmentScreen extends StatefulWidget {
  const BookingTreatmentScreen({super.key});

  @override
  State<BookingTreatmentScreen> createState() => _BookingTreatmentScreenState();
}

class _BookingTreatmentScreenState extends State<BookingTreatmentScreen> {
  List<dynamic> jenisTreatments = [];
  bool _isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchJenisTreatment();
  }

  Future<void> fetchJenisTreatment() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.jenisTreatment),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jenisTreatments = data['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          error = 'Gagal memuat data jenis treatment';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  error = null;
                });
                fetchJenisTreatment();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: jenisTreatments.length,
                itemBuilder: (context, index) {
                  final treatment = jenisTreatments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TreatmentCategoryCard(
                      name: treatment['nama_jenis_treatment'],
                      id: treatment['id_jenis_treatment'],
                      description: treatment['deskripsi_treatment'] ?? 'Treatment spesial untuk kebutuhan Anda',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TreatmentCategoryCard extends StatelessWidget {
  final String name;
  final int id;
  final String description;

  const TreatmentCategoryCard({
    super.key,
    required this.name,
    required this.id,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to treatment list by category
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentListScreen(
              categoryId: id,
              categoryName: name,
            ),
          ),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: appTheme.lightBadge100,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: appTheme.black900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: appTheme.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================================
// MODIFIED TreatmentListScreen
// ====================================================================
class TreatmentListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const TreatmentListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TreatmentListScreen> createState() => _TreatmentListScreenState();
}

class _TreatmentListScreenState extends State<TreatmentListScreen> {
  List<dynamic> treatments = [];
  bool _isLoading = true;
  String? error;
  List<Map<String, dynamic>> _selectedTreatments = []; // List to store selected treatments
  final int maxSelections = 3; // Maximum number of treatments allowed

  @override
  void initState() {
    super.initState();
    fetchTreatmentsByCategory();
  }

  Future<void> fetchTreatmentsByCategory() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.treatment}?id_jenis_treatment=${widget.categoryId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final allTreatments = data['data'];
          treatments = allTreatments is List
              ? allTreatments.where((item) =>
          item['id_jenis_treatment'] == widget.categoryId).toList()
              : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          error = 'Gagal memuat data treatment: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching treatments: $e');
      setState(() {
        error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleTreatmentSelection(Map<String, dynamic> treatment) {
    setState(() {
      final isAlreadySelected = _selectedTreatments.any((item) => item['id_treatment'] == treatment['id_treatment']);

      if (isAlreadySelected) {
        _selectedTreatments.removeWhere((item) => item['id_treatment'] == treatment['id_treatment']);
      } else {
        if (_selectedTreatments.length < maxSelections) {
          _selectedTreatments.add(treatment);
        } else {
          // Optionally, show a message to the user that max selection is reached
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maksimal ${maxSelections} treatment dapat dipilih.')),
          );
        }
      }
    });
  }

  bool _isTreatmentSelected(Map<String, dynamic> treatment) {
    return _selectedTreatments.any((item) => item['id_treatment'] == treatment['id_treatment']);
  }

  void _proceedToBooking() {
    if (_selectedTreatments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setidaknya satu treatment untuk melanjutkan.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailBookingTreatmentScreen(selectedTreatments: _selectedTreatments),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: appTheme.whiteA700,
        foregroundColor: appTheme.black900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  error = null;
                });
                fetchTreatmentsByCategory();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : treatments.isEmpty
          ? const Center(
        child: Text('Belum ada treatment dalam kategori ini'),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: treatments.length,
          itemBuilder: (context, index) {
            final treatment = treatments[index];
            final isSelected = _isTreatmentSelected(treatment);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector( // Wrap with GestureDetector to handle selection
                onTap: () => _toggleTreatmentSelection(treatment),
                child: TreatmentCard(
                  treatment: treatment,
                  isSelected: isSelected, // Pass selection status
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _selectedTreatments.isNotEmpty
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedTreatments.length} Treatment Dipilih',
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.black900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: Rp ${_formatTotalPrice(_selectedTreatments)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appTheme.orange200,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _proceedToBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Lanjutkan Reservasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )
          : null, // Hide bottom bar if no treatments are selected
    );
  }

  String _formatTotalPrice(List<Map<String, dynamic>> treatments) {
    double total = 0.0;
    for (var t in treatments) {
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
    return _formatPrice(total); // Reusing the existing price formatter
  }

  // Helper for formatting price (re-used from TreatmentCard)
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

// ====================================================================
// MODIFIED TreatmentCard (No longer navigates, just displays selection)
// ====================================================================
class TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final bool isSelected; // New parameter to indicate selection status

  const TreatmentCard({
    super.key,
    required this.treatment,
    this.isSelected = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2, // Higher elevation if selected
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide(color: appTheme.orange200, width: 3) // Orange border if selected
            : BorderSide.none,
      ),
      color: isSelected ? appTheme.orange200.withOpacity(0.1) : appTheme.whiteA700, // Light orange background if selected
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: treatment['gambar_treatment'] != null && treatment['gambar_treatment'].toString().isNotEmpty
                    ? Image.network(
                  treatment['gambar_treatment'],
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                )
                    : Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: appTheme.lightGrey.withAlpha((0.6 * 255).toInt()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.watch_later_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatEstimasi(treatment['estimasi_treatment'] ?? '00:00:00'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected) // Show a checkmark if selected
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: appTheme.orange200,
                    radius: 16,
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        treatment['nama_treatment'] ?? 'Unnamed Treatment',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                            Icons.star_outline,
                            color: appTheme.orange200,
                            size: 28),
                        const SizedBox(width: 4),
                        Text(
                          '4,8', // Static review score
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: appTheme.black900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${treatment['biaya_treatment'] != null ? _formatPrice(treatment['biaya_treatment']) : '0'}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appTheme.orange200,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Facial untuk kulit sensitif', // Static description as seen in the image
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.lightGrey,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
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