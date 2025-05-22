import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';

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

// Screen yang akan dibuat untuk menampilkan daftar treatment berdasarkan kategori
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
          // Pastikan hanya treatment dengan id_jenis_treatment yang sesuai yang ditampilkan
          final allTreatments = data['data'];
          treatments = allTreatments is List
              ? allTreatments.where((item) =>
                  item['id_jenis_treatment'] == widget.categoryId).toList()
              : [];

          print('Fetched ${treatments.length} treatments for category ID: ${widget.categoryId}');
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: TreatmentCard(
                              treatment: treatment,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> treatment;

  const TreatmentCard({
    super.key,
    required this.treatment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: appTheme.lightBadge100,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar treatment dari URL API
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: treatment['gambar_treatment'] != null && treatment['gambar_treatment'].toString().isNotEmpty
                ? Image.network(
                    treatment['gambar_treatment'],
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 150,
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
                        height: 150,
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
                    height: 150,
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
            const SizedBox(height: 12),
            Text(
              treatment['nama_treatment'] ?? 'Unnamed Treatment',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${treatment['biaya_treatment'] ?? 0}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: appTheme.orange200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              treatment['deskripsi_treatment'] ?? 'Tidak ada deskripsi',
              style: TextStyle(
                fontSize: 14,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimasi: ${_formatEstimasi(treatment['estimasi_treatment'] ?? '00:00:00')}',
              style: TextStyle(
                fontSize: 14,
                color: appTheme.lightGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEstimasi(String estimasi) {
    try {
      final parts = estimasi.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);

        if (hours > 0) {
          return '$hours jam ${minutes > 0 ? '$minutes menit' : ''}';
        } else {
          return '$minutes menit';
        }
      }
      return estimasi;
    } catch (e) {
      return estimasi;
    }
  }
}
