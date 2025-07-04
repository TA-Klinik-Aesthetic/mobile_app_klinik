import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_booking_treatment_screen.dart';

class BookingTreatmentScreen extends StatefulWidget {
  const BookingTreatmentScreen({super.key});

  @override
  State<BookingTreatmentScreen> createState() => _BookingTreatmentScreenState();
}

class _BookingTreatmentScreenState extends State<BookingTreatmentScreen> {
  List<dynamic> jenisTreatments = [];
  Map<int, List<dynamic>> treatmentsByCategory = {};
  bool _isLoading = true;
  String? error;
  // Store selected treatments at parent level to persist across category changes
  List<Map<String, dynamic>> _selectedTreatments = [];
  final int maxSelections = 10;

  @override
  void initState() {
    super.initState();
    fetchJenisTreatment();
  }

  // Method to update selected treatments
  void updateSelectedTreatments(Map<String, dynamic> treatment) {
    setState(() {
      final isAlreadySelected = _selectedTreatments.any(
              (item) => item['id_treatment'] == treatment['id_treatment']);

      if (isAlreadySelected) {
        _selectedTreatments.removeWhere(
                (item) => item['id_treatment'] == treatment['id_treatment']);
      } else {
        if (_selectedTreatments.length < maxSelections) {
          _selectedTreatments.add(treatment);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maksimal $maxSelections treatment dapat dipilih.')),
          );
        }
      }
    });
  }

  Future<void> fetchJenisTreatment() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse(ApiConstants.jenisTreatment),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          jenisTreatments = data['data'];

          // Extract treatments from each category and store them in the map
          treatmentsByCategory.clear(); // Clear existing data first
          for (var category in jenisTreatments) {
            int categoryId = category['id_jenis_treatment'];
            if (category['treatment'] != null && category['treatment'] is List) {
              treatmentsByCategory[categoryId] = List.from(category['treatment']);
              print('Category $categoryId has ${treatmentsByCategory[categoryId]?.length} treatments');
            } else {
              treatmentsByCategory[categoryId] = [];
              print('Category $categoryId has no treatments');
            }
          }

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
      print('Error in fetchJenisTreatment: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      error = null;
    });
    await fetchJenisTreatment();
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
    return _formatPrice(total);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : jenisTreatments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada treatment dalam kategori ini',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                foregroundColor: Colors.white,
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: appTheme.orange200,
        child: Padding(
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
                    final categoryId = treatment['id_jenis_treatment'];
                    // Get treatments for this category
                    final categoryTreatments = treatmentsByCategory[categoryId] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TreatmentCategoryCard(
                        name: treatment['nama_jenis_treatment'],
                        id: categoryId,
                        description: treatment['deskripsi_treatment'] ?? 'Treatment spesial untuk kebutuhan Anda',
                        selectedTreatments: _selectedTreatments,
                        updateSelectedTreatments: updateSelectedTreatments,
                        maxSelections: maxSelections,
                        treatments: categoryTreatments, // Pass treatments directly
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Show bottom navigation with selected treatments if any
      bottomNavigationBar: _selectedTreatments.isNotEmpty
          ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 4,
              blurRadius: 6,
              offset: const Offset(4, -6),
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
              onPressed: () {
                if (_selectedTreatments.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih setidaknya satu treatment')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBookingTreatmentScreen(
                      selectedTreatments: _selectedTreatments,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Lanjutkan Reservasi',
                style: TextStyle(
                  color: appTheme.whiteA700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      )
          : null,
    );
  }
}

class TreatmentCategoryCard extends StatelessWidget {
  final String name;
  final int id;
  final String description;
  final List<Map<String, dynamic>> selectedTreatments;
  final Function(Map<String, dynamic>) updateSelectedTreatments;
  final int maxSelections;
  final List<dynamic> treatments; // Add this parameter

  const TreatmentCategoryCard({
    super.key,
    required this.name,
    required this.id,
    required this.description,
    required this.selectedTreatments,
    required this.updateSelectedTreatments,
    required this.maxSelections,
    required this.treatments,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to treatment list with the selected treatments
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TreatmentListScreen(
              categoryId: id,
              categoryName: name,
              selectedTreatments: selectedTreatments,
              updateSelectedTreatments: updateSelectedTreatments,
              maxSelections: maxSelections,
              preloadedTreatments: treatments, // Pass treatments directly
            ),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: appTheme.lightGrey.withAlpha((0.6 * 255).toInt()),
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

class TreatmentListScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final List<Map<String, dynamic>> selectedTreatments;
  final Function(Map<String, dynamic>) updateSelectedTreatments;
  final int maxSelections;
  final List<dynamic> preloadedTreatments;

  const TreatmentListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.selectedTreatments,
    required this.updateSelectedTreatments,
    required this.maxSelections,
    required this.preloadedTreatments,
  });

  @override
  State<TreatmentListScreen> createState() => _TreatmentListScreenState();
}

class _TreatmentListScreenState extends State<TreatmentListScreen> {

  Map<int, bool> treatmentFavoriteStatus = {};

  List<dynamic> treatments = [];
  bool _isLoading = true;
  String? error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    treatments = widget.preloadedTreatments;
    print('TreatmentListScreen initialized with ${treatments.length} treatments');
    print('Category ID: ${widget.categoryId}, Category Name: ${widget.categoryName}');
    _isLoading = false;
    checkFavoriteTreatments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      error = null;
      // Just use the preloaded data again for refresh
      treatments = widget.preloadedTreatments;
      _isLoading = false;
    });

    await checkFavoriteTreatments();

    // Scroll to top after refresh
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Check favorite status for all treatments
  Future<void> checkFavoriteTreatments() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.viewTreatmentFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> favoriteTreatments = jsonData['data'] ?? [];

        setState(() {
          treatmentFavoriteStatus.clear();
          for (var treatment in favoriteTreatments) {
            treatmentFavoriteStatus[treatment['id_treatment']] = true;
          }
        });
      }
    } catch (e) {
      print('Error checking favorite treatments: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleTreatmentFavorite(int treatmentId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk menambahkan favorit')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.addTreatmentFavorite),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': userId,
          'id_treatment': treatmentId,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          treatmentFavoriteStatus[treatmentId] = jsonData['is_favorited'] ??
              !(treatmentFavoriteStatus[treatmentId] ?? false);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? 'Status favorit diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status favorit')),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> fetchTreatmentsByCategory() async {
    try {
      setState(() => _isLoading = true);

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
      setState(() {
        error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  bool _isTreatmentSelected(Map<String, dynamic> treatment) {
    return widget.selectedTreatments.any((item) => item['id_treatment'] == treatment['id_treatment']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Makes bottom area transparent
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0.0,
        centerTitle: true,
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
              onPressed: _refreshData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : treatments.isEmpty
          ? RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const Center(
                child: Text('Belum ada treatment dalam kategori ini'),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: treatments.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final treatment = treatments[index];
              final isSelected = _isTreatmentSelected(treatment);
              final int treatmentId = treatment['id_treatment'];
              final bool isFavorite = treatmentFavoriteStatus[treatmentId] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: InkWell(
                  onTap: () {
                    widget.updateSelectedTreatments(treatment);
                    setState(() {}); // Refresh UI to show selection
                  },
                  child: TreatmentCard(
                    treatment: treatment,
                    isSelected: isSelected,
                    isFavorite: isFavorite,
                    onFavoriteToggle: toggleTreatmentFavorite,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: widget.selectedTreatments.isNotEmpty
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
                  '${widget.selectedTreatments.length} Treatment Dipilih',
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.black900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: Rp ${_formatTotalPrice(widget.selectedTreatments)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: appTheme.orange200,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.selectedTreatments.isEmpty) {
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailBookingTreatmentScreen(
                      selectedTreatments: widget.selectedTreatments,
                    ),
                  ),
                );
              },
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
          : null,
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
    return _formatPrice(total);
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

class TreatmentCard extends StatelessWidget {
  final Map<String, dynamic> treatment;
  final bool isSelected;
  final bool isFavorite;
  final Function(int) onFavoriteToggle;

  const TreatmentCard({
    super.key,
    required this.treatment,
    this.isSelected = false,
    this.isFavorite = false,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide(color: appTheme.orange200, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? Colors.grey.shade200 : appTheme.whiteA700,
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
                  "https://klinikneshnavya.com/${treatment['gambar_treatment']}",
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
                    print('Error loading image: $error');
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
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? appTheme.darkCherry : appTheme.black900,
                      size: 24,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => onFavoriteToggle(treatment['id_treatment']),
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
              if (isSelected)
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: appTheme.orange200,
                    radius: 16,
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ),
              // Add selection label when selected
              if (isSelected)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: appTheme.orange200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      "Dipilih",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appTheme.black900,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                            Icons.star_rounded,
                            color: appTheme.orange200,
                            size: 28),
                        const SizedBox(width: 4),
                        Text(
                          '4,8',
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
                const SizedBox(height: 6),
                Text(
                  'Rp ${treatment['biaya_treatment'] != null ? _formatPrice(treatment['biaya_treatment']) : '0'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appTheme.orange200,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  treatment['deskripsi_treatment'] ?? 'Facial untuk kulit sensitif',
                  style: TextStyle(
                    fontSize: 16,
                    color: appTheme.black900,
                  ),
                ),
                const SizedBox(height: 16)
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