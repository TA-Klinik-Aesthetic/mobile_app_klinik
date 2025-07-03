import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import '../../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../booking_screen/detail_history_consultation_screen.dart';
import '../booking_screen/detail_history_treatment_screen.dart';

class HistoryVisitScreen extends StatefulWidget {
  const HistoryVisitScreen({Key? key}) : super(key: key);

  @override
  State<HistoryVisitScreen> createState() => _HistoryVisitScreenState();
}

class _HistoryVisitScreenState extends State<HistoryVisitScreen> {
  bool _isLoading = true;
  List<dynamic> _consultations = [];
  List<dynamic> _treatments = [];
  List<Map<String, dynamic>> _combinedHistory = [];
  String? _errorMessage;
  bool _isNewestFirst = true;

  @override
  void initState() {
    super.initState();
    fetchAllHistory();
  }

  Future<void> fetchAllHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }

      // Fetch consultations
      final consultationResponse = await http.get(
        Uri.parse(ApiConstants.bookingKonsultasi),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Fetch treatments
      final treatmentResponse = await http.get(
        Uri.parse(ApiConstants.bookingTreatment),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (consultationResponse.statusCode == 200) {
        final consultationData = json.decode(consultationResponse.body);
        _consultations = consultationData['data'] ?? [];
      }

      if (treatmentResponse.statusCode == 200) {
        final treatmentData = json.decode(treatmentResponse.body);
        _treatments = treatmentData['booking_treatments'] ?? [];
      }

      // Combine both types into a single list with a type indicator
      _combinedHistory = [];

      for (var consultation in _consultations) {
        _combinedHistory.add({
          'type': 'consultation',
          'data': consultation,
          'date': DateTime.parse(consultation['created_at'] ?? DateTime.now().toString()),
        });
      }

      for (var treatment in _treatments) {
        _combinedHistory.add({
          'type': 'treatment',
          'data': treatment,
          'date': DateTime.parse(treatment['created_at'] ?? DateTime.now().toString()),
        });
      }

      // Sort based on current sort order
      _sortHistory();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  // Add method to handle sorting
  void _sortHistory() {
    if (_isNewestFirst) {
      // Sort by date, newest first
      _combinedHistory.sort((a, b) => b['date'].compareTo(a['date']));
    } else {
      // Sort by date, oldest first
      _combinedHistory.sort((a, b) => a['date'].compareTo(b['date']));
    }
  }

  // Add method to toggle sort order
  // Add method to toggle sort order with toast notification
  void _toggleSortOrder() {
    setState(() {
      _isNewestFirst = !_isNewestFirst;
      _sortHistory();
    });

    // Show toast notification
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flatColored,
      title: Text(_isNewestFirst ? 'Menampilkan dari yang terbaru' : 'Menampilkan dari yang terlama'),
      description: Text(_isNewestFirst
          ? 'Data diurutkan dari tanggal terbaru ke terlama'
          : 'Data diurutkan dari tanggal terlama ke terbaru'),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      icon: Icon(_isNewestFirst ? Icons.trending_down : Icons.trending_up),
      primaryColor: appTheme.lightGreenOld,
      backgroundColor: appTheme.lightGreen.withAlpha((0.6 * 255).toInt()),
      foregroundColor: appTheme.black900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 16,
          offset: Offset(0, 16),
          spreadRadius: 0,
        )
      ],
      showProgressBar: false,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
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

    return priceDouble.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.');
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;

    switch (status) {
      case 'Verifikasi':
        badgeColor = Colors.orangeAccent;
        break;
      case 'Selesai':
        badgeColor = Colors.green;
        break;
      case 'Dibatalkan':
        badgeColor = appTheme.darkCherry;
        break;
      case 'Berhasil dibooking':
        badgeColor = Colors.blueAccent;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildConsultationCard(Map<String, dynamic> item) {
    final consultation = item['data'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: appTheme.lightGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Konsultasi title and status badge in one row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Konsultasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(consultation['status_booking_konsultasi'] ?? 'Unknown'),
              ],
            ),

            // Date below Konsultasi title
            Text(
              _formatDate(consultation['created_at'] ?? ''),
              style: TextStyle(
                fontSize: 14,
                color: appTheme.black900.withOpacity(0.7),
              ),
            ),
            const Divider(height: 24),

            // Doctor info and detail button
            Row(
              children: [
                // Doctor image
                if (consultation['dokter'] != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      consultation['dokter']['foto_dokter'] ?? '',
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 75,
                        height: 75,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Doctor name
                  Expanded(
                    child: Text(
                      consultation['dokter']['nama_dokter'] ?? 'Unknown Doctor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dokter belum ditentukan',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],

                // Detail button
                TextButton(
                  onPressed: () {
                    try {
                      var rawId = consultation['id_konsultasi'];
                      print('Raw consultation ID type: ${rawId.runtimeType}, value: $rawId');

                      int consultationId;

                      if (rawId is int) {
                        consultationId = rawId;
                      } else if (rawId is String) {
                        // Remove any non-numeric characters if present
                        String cleanIdString = rawId.replaceAll(RegExp(r'[^0-9]'), '');
                        consultationId = int.parse(cleanIdString);
                      } else if (rawId == null) {
                        throw Exception('Consultation ID is null');
                      } else {
                        // For other types, convert to string first then parse
                        consultationId = int.parse(rawId.toString());
                      }

                      print('Parsed consultation ID: $consultationId');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailHistoryConsultationScreen(
                            consultationId: consultationId,
                          ),
                        ),
                      ).then((_) {
                        // Refresh data when returning from detail screen
                        fetchAllHistory();
                      });
                    } catch (e) {
                      // Show error message to user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error accessing consultation details: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      print('Error processing consultation ID: $e');
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: appTheme.lightGreen,
                    foregroundColor: appTheme.black900,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: appTheme.lightGreenOld,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Lihat Detail',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> item) {
    final treatment = item['data'];
    final treatmentDetails = treatment['detail_booking'] ?? [];
    final int treatmentCount = treatmentDetails.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: appTheme.lightGrey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treatment title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Treatment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(treatment['status_booking_treatment'] ?? 'Unknown'),
              ],
            ),

            // Date below Treatment title
            Text(
              _formatDate(treatment['created_at'] ?? ''),
              style: TextStyle(
                fontSize: 14,
                color: appTheme.black900.withOpacity(0.7),
              ),
            ),
            const Divider(height: 24),

            // Treatment info with image
            if (treatmentCount > 0 && treatmentDetails[0]['treatment'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Treatment image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      treatmentDetails[0]['treatment']['gambar_treatment'] != null &&
                      treatmentDetails[0]['treatment']['gambar_treatment'].toString().isNotEmpty
                        ? "https://klinikneshnavya.com/${treatmentDetails[0]['treatment']['gambar_treatment']}"
                        : '',
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 75,
                        height: 75,
                        color: Colors.grey[200],
                        child: const Icon(Icons.spa, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Treatment name and additional treatments info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          treatmentDetails[0]['treatment']['nama_treatment'] ?? 'Unknown Treatment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (treatmentCount > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            '+${treatmentCount - 1} treatment lainnya',
                            style: TextStyle(
                              fontSize: 12,
                              color: appTheme.black900.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24),

            // Total price and detail button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Total: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: appTheme.black900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: 'Rp ${_formatPrice(treatment['harga_akhir_treatment'])}',
                        style: TextStyle(
                          fontSize: 16,
                          color: appTheme.orange200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailHistoryTreatmentScreen(
                          bookingId: treatment['id_booking_treatment'],
                        ),
                      ),
                    ).then((_) {
                      // Refresh data when returning from detail screen
                      fetchAllHistory();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: appTheme.lightGreen,
                    foregroundColor: appTheme.black900,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: appTheme.lightGreenOld,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    'Lihat Detail',
                    style: TextStyle(
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
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
        title: Text(
          'Riwayat Kunjungan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: appTheme.orange200,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
        actions: [
          // Add toggle button for sort order
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _toggleSortOrder,
              icon: Icon(
                _isNewestFirst ? FontAwesomeIcons.sortAmountAsc : FontAwesomeIcons.sortAmountUpAlt,
                color: appTheme.black900,
              ),
              tooltip: _isNewestFirst ? 'Urutkan dari yang terlama' : 'Urutkan dari yang terbaru',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchAllHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : _combinedHistory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat konsultasi atau treatment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Add sort indicator below app bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: appTheme.whiteA700,
              border: Border(
                bottom: BorderSide(
                  color: appTheme.lightGrey,
                  width: 0.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchAllHistory,
              color: appTheme.orange200,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _combinedHistory.length,
                itemBuilder: (context, index) {
                  final item = _combinedHistory[index];
                  if (item['type'] == 'consultation') {
                    return _buildConsultationCard(item);
                  } else {
                    return _buildTreatmentCard(item);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}