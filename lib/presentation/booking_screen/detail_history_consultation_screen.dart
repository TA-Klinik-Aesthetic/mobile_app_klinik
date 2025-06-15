import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../api/api_constant.dart';
import '../../core/app_export.dart';

class DetailHistoryConsultationScreen extends StatefulWidget {
  final int consultationId;

  const DetailHistoryConsultationScreen({
    Key? key,
    required this.consultationId,
  }) : super(key: key);

  @override
  State<DetailHistoryConsultationScreen> createState() => _DetailHistoryConsultationScreenState();
}

class _DetailHistoryConsultationScreenState extends State<DetailHistoryConsultationScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _consultationData;
  String? _errorMessage;
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0;
  bool _isSendingFeedback = false;
  Map<String, dynamic>? _treatmentData;
  Map<String, dynamic>? _doctorRatingData;

  @override
  void initState() {
    super.initState();
    fetchConsultationDetails();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> fetchConsultationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }

      // Debug print
      print('Fetching consultation with ID: ${widget.consultationId}');

      // Fetch consultation details
      final response = await http.get(
        Uri.parse('${ApiConstants.bookingKonsultasi}/${widget.consultationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Check if the data is nested inside a data field
        final consultationData = responseData['data'] ?? responseData;

        setState(() {
          _consultationData = consultationData;
        });

        // Fetch treatments data for recommendations
        if (_consultationData?['detail_konsultasi'] != null &&
            _consultationData!['detail_konsultasi'] is List &&
            _consultationData!['detail_konsultasi'].isNotEmpty) {
          for (var detail in _consultationData!['detail_konsultasi']) {
            if (detail['id_treatment'] != null) {
              await fetchTreatmentData(detail['id_treatment']);
            }
          }
        }

        // Fetch doctor ratings if doctor exists
        if (_consultationData?['dokter'] != null &&
            _consultationData!['dokter']['id_dokter'] != null) {
          await fetchDoctorRatings(_consultationData!['dokter']['id_dokter']);
        }

      } else {
        setState(() {
          _errorMessage = 'Failed to load consultation data. Please try again. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error in fetchConsultationDetails: $e');
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchTreatmentData(int treatmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.treatment}/$treatmentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _treatmentData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching treatment data: $e');
    }
  }

  Future<void> fetchDoctorRatings(int doctorId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.feedbackKonsultasi}/dokter/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _doctorRatingData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching doctor ratings: $e');
    }
  }

  Future<void> submitFeedback() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }

    setState(() {
      _isSendingFeedback = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(ApiConstants.feedbackKonsultasi),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'id_konsultasi': widget.consultationId,
          'rating': _rating.toInt(),
          'teks_feedback': _feedbackController.text.trim(),
          'balasan_feedback': null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully')),
        );
        _feedbackController.clear();
        setState(() {
          _rating = 0;
        });
        // Refresh consultation details to show the feedback
        fetchConsultationDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isSendingFeedback = false;
      });
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;

    switch (status) {
      case 'Verifikasi':
        badgeColor = Colors.blue;
        break;
      case 'Selesai':
        badgeColor = Colors.green;
        break;
      case 'Batal':
        badgeColor = Colors.red;
        break;
      case 'Konfirmasi':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: appTheme.whiteA700, width: 1),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final bool isConsultationComplete =
        _consultationData?['status_booking_konsultasi'] == 'Selesai';
    final double doctorRating = _doctorRatingData != null ?
    (_doctorRatingData?['average_rating'] ?? 0.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Konsultasi',
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
              onPressed: fetchConsultationDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONTAINER 1: Booking Details
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detail Booking and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                        _buildStatusBadge(_consultationData?['status_booking_konsultasi'] ?? 'Unknown'),
                      ],
                    ),
                    const Divider(height: 24),

                    // ID Booking
                    _buildInfoRow(
                        'ID Booking',
                        '#CONS${_consultationData?['id_konsultasi'] ?? '-'}'
                    ),
                    const SizedBox(height: 12),

                    // Waktu Booking
                    _buildInfoRow(
                        'Waktu Booking',
                        '${_formatDate(_consultationData?['created_at'] ?? '')} ${_formatTime(_consultationData?['created_at'] ?? '')}'
                    ),
                    const SizedBox(height: 12),

                    // Waktu Konsultasi
                    _buildInfoRow(
                        'Waktu Konsultasi',
                        '${_formatDate(_consultationData?['waktu_konsultasi'] ?? '')} ${_formatTime(_consultationData?['waktu_konsultasi'] ?? '')}'
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CONTAINER 2: Doctor Information
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Dokter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                      ),
                    ),
                    const Divider(height: 24),

                    if (_consultationData?['dokter'] != null)
                      Row(
                        children: [
                          // Doctor image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _consultationData?['dokter']['foto_dokter'] != null
                                ? Image.network(
                              _consultationData!['dokter']['foto_dokter'],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 32, color: Colors.grey),
                                );
                              },
                            )
                                : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 32, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Doctor name and rating
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _consultationData!['dokter']['nama_dokter'] ?? 'Unknown Doctor',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 20,
                                      color: appTheme.orange200,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctorRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: appTheme.black900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const Text('No doctor information available'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CONTAINER 3: Doctor's Prescription
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resep Dokter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                      ),
                    ),
                    const Divider(height: 24),

                    // Keluhan Pelanggan
                    Text(
                      'Keluhan Pelanggan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: appTheme.black900.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _consultationData?['keluhan_pelanggan'] ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Saran Tindakan
                    Text(
                      'Saran Tindakan',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.black900.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Detail Consultations
                    if (_consultationData?['detail_konsultasi'] != null &&
                        (_consultationData!['detail_konsultasi'] as List).isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_consultationData!['detail_konsultasi'] as List).length,
                        itemBuilder: (context, index) {
                          final detail = _consultationData!['detail_konsultasi'][index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: appTheme.lightGrey,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Diagnosis
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        const TextSpan(
                                          text: 'Diagnosis: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: detail['diagnosis'] ?? '-',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Saran Tindakan
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        const TextSpan(
                                          text: 'Saran Tindakan: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: detail['saran_tindakan'] ?? '-',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Recommended Treatment
                                  if (detail['id_treatment'] != null)
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          const TextSpan(
                                            text: 'Rekomendasi Treatment: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: _treatmentData?['nama_treatment'] ?? 'Loading...',
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      const Text('No prescription details available'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CONTAINER 4: Rating Section (only when status is "Selesai")
            if (isConsultationComplete)
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beri Penilaian',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appTheme.black900,
                        ),
                      ),
                      const Divider(height: 24),

                      // Rating Bar
                      Center(
                        child: RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 36,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: appTheme.orange200,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Feedback Text Area
                      Text(
                        'Tambahkan Komentar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: appTheme.black900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Jelaskan Pengalaman Anda',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: appTheme.lightGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: appTheme.orange200),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Submit Button (only when status is "Selesai")
            if (isConsultationComplete)
              Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _isSendingFeedback ? null : submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.orange200,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSendingFeedback
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Kirim',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}