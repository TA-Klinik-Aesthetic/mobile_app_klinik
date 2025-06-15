import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../booking_screen/detail_history_consultation_screen.dart';

class HistoryVisitScreen extends StatefulWidget {
  const HistoryVisitScreen({Key? key}) : super(key: key);

  @override
  State<HistoryVisitScreen> createState() => _HistoryVisitScreenState();
}

class _HistoryVisitScreenState extends State<HistoryVisitScreen> {
  bool _isLoading = true;
  List<dynamic> _consultations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchConsultationHistory();
  }

  Future<void> fetchConsultationHistory() async {
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

      final response = await http.get(
        Uri.parse(ApiConstants.bookingKonsultasi),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _consultations = data['data'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load consultation history. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  Widget _buildStatusBadge(String status) {
    Color badgeColor;

    switch (status) {
      case 'Verifikasi':
        badgeColor = appTheme.lightBlue;
        break;
      case 'Selesai':
        badgeColor = appTheme.lightGreen;
        break;
      case 'Batal':
        badgeColor = appTheme.darkCherry;
        break;
      case 'Konfirmasi':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Konsultasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
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
              onPressed: fetchConsultationHistory,
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
          : _consultations.isEmpty
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
              'Belum ada riwayat konsultasi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchConsultationHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _consultations.length,
          itemBuilder: (context, index) {
            final consultation = _consultations[index];
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
                    // Konsultasi title and date with status
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
                      _formatDate(consultation['waktu_konsultasi'] ?? ''),
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
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 60,
                                height: 60,
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
                                fontWeight: FontWeight.bold,
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
                            final consultationId = consultation['id_konsultasi'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailHistoryConsultationScreen(
                                  consultationId: consultationId,
                                ),
                              ),
                            ).then((_) {
                              // Refresh the list when returning from detail screen
                              fetchConsultationHistory();
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
          },
        ),
      ),
    );
  }
}