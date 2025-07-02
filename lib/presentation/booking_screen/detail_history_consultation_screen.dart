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
    super.key,
    required this.consultationId,
  });

  @override
  State<DetailHistoryConsultationScreen> createState() => _DetailHistoryConsultationScreenState();
}

class _DetailHistoryConsultationScreenState extends State<DetailHistoryConsultationScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _keluhanEditController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _feedbackExists = false;
  bool _isSendingFeedback = false;
  Map<String, dynamic>? _consultationData;
  String? _errorMessage;
  double _rating = 0;
  Map<String, dynamic>? _existingFeedback;
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
    _keluhanEditController.dispose();
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


        if (_consultationData?['status_booking_konsultasi'] == 'Selesai') {
          await checkExistingFeedback();
        }

        // Fetch treatments data for recommendations
        if (_consultationData?['detail_konsultasi'] != null &&
            _consultationData!['detail_konsultasi'] is List &&
            _consultationData!['detail_konsultasi'].isNotEmpty) {
          for (var detail in _consultationData!['detail_konsultasi']) {
            // Similarly for treatment data:
            if (detail['id_treatment'] != null) {
              try {
                int treatmentId;
                if (detail['id_treatment'] is int) {
                  treatmentId = detail['id_treatment'];
                } else {
                  treatmentId = int.parse(detail['id_treatment'].toString());
                }
                await fetchTreatmentData(treatmentId);
              } catch (e) {
                print('Error parsing treatment ID: $e');
              }
            }
          }
        }

        // Fetch doctor ratings if doctor exists
        if (_consultationData?['dokter'] != null &&
            _consultationData!['dokter']['id_dokter'] != null) {
          // Convert string ID to integer
          int doctorId;
          try {
            if (_consultationData!['dokter']['id_dokter'] is int) {
              doctorId = _consultationData!['dokter']['id_dokter'];
            } else {
              doctorId = int.parse(_consultationData!['dokter']['id_dokter'].toString());
            }
            await fetchDoctorRatings(doctorId);
          } catch (e) {
            print('Error parsing doctor ID: $e');
          }
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

  Future<void> updateKeluhan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.bookingKonsultasi}/${widget.consultationId}/keluhan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'keluhan_pelanggan': _keluhanEditController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keluhan berhasil diperbarui')),
        );
        // Refresh consultation details
        fetchConsultationDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui keluhan: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> checkExistingFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiConstants.feedbackKonsultasi}/konsultasi/${widget.consultationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final feedbackData = responseData['data'];

        setState(() {
          if (feedbackData != null &&
              (feedbackData is List ? feedbackData.isNotEmpty : true)) {
            _feedbackExists = true;
            _existingFeedback = feedbackData is List ? feedbackData[0] : feedbackData;

            // Set rating to match existing feedback
            if (_existingFeedback != null && _existingFeedback!.containsKey('rating')) {
              if (_existingFeedback!['rating'] is int) {
                _rating = _existingFeedback!['rating'].toDouble();
              } else {
                _rating = double.tryParse(_existingFeedback!['rating'].toString()) ?? 0.0;
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error checking existing feedback: $e');
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

  Future<void> cancelConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found. Please login again.';
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.bookingKonsultasi}/${widget.consultationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status_booking_konsultasi': 'Dibatalkan',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konsultasi berhasil dibatalkan')),
        );
        // Refresh consultation details
        fetchConsultationDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan konsultasi: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to show confirmation dialog
  Future<void> _showCancellationConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Pembatalan'),
          content: const Text('Apakah Anda yakin ingin membatalkan konsultasi ini?'),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak', style: TextStyle(color: appTheme.lightGrey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ya', style: TextStyle(color: appTheme.darkCherry)),
              onPressed: () {
                Navigator.of(context).pop();
                cancelConsultation();
              },
            ),
          ],
        );
      },
    );
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
    double.tryParse(_doctorRatingData?['average_rating']?.toString() ?? '0') ?? 0.0 : 0.0;

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

            if (_consultationData?['status_booking_konsultasi'] == 'Berhasil dibooking')
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showCancellationConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.darkCherry,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Keluhan Pelanggan',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: appTheme.black900.withOpacity(0.7),
                              ),
                            ),
                            // Edit button - only visible for "Verifikasi" status and when not editing
                            if (_consultationData?['status_booking_konsultasi'] == 'Verifikasi')
                              IconButton(
                                icon: Icon(
                                  _isEditing ? Icons.save : Icons.edit,
                                  color: appTheme.orange200,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (_isEditing) {
                                    // Save changes
                                    updateKeluhan();
                                  } else {
                                    // Enter edit mode
                                    _keluhanEditController.text = _consultationData?['keluhan_pelanggan'] ?? '';
                                    setState(() {
                                      _isEditing = true;
                                    });
                                  }
                                },
                              )
                            else if (_consultationData?['status_booking_konsultasi'] == 'Berhasil dibooking' ||
                                _consultationData?['status_booking_konsultasi'] == 'Dibatalkan' ||
                                _consultationData?['status_booking_konsultasi'] == 'Selesai')
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: appTheme.lightGrey,
                                  size: 20,
                                ),
                                onPressed: null, // Disabled
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Editable text field when in editing mode, otherwise just display text
                        _isEditing
                            ? TextField(
                          controller: _keluhanEditController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: appTheme.lightGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: appTheme.orange200),
                            ),
                          ),
                        )
                            : Text(
                          _consultationData?['keluhan_pelanggan'] ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        TextSpan(
                                          text: detail['diagnosis'] ?? '-',
                                          style: const TextStyle(fontSize: 14),
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
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        TextSpan(
                                          text: detail['saran_tindakan'] ?? '-',
                                          style: const TextStyle(fontSize: 14),
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
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          TextSpan(
                                            text: _treatmentData?['nama_treatment'] ?? 'Loading...',
                                            style: const TextStyle(fontSize: 14),
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
            // and feedback does not already exist
            if (isConsultationComplete)
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
                        'Ulasan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appTheme.black900,
                        ),
                      ),
                      const Divider(height: 24),

                      if (_feedbackExists && _existingFeedback != null)
                      // Display existing feedback
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating stars (read-only)
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    color: index < _rating.toInt()
                                        ? appTheme.orange200
                                        : Colors.grey,
                                    size: 36,
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Feedback text
                            if (_existingFeedback!.containsKey('teks_feedback') &&
                                _existingFeedback!['teks_feedback'] != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: appTheme.lightGrey),
                                ),
                                child: Text(
                                  _existingFeedback!['teks_feedback'].toString(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: appTheme.black900,
                                  ),
                                ),
                              ),
                          ],
                        )
                      else
                      // Show feedback form (existing implementation)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating Bar
                            Center(
                              child: RatingBar.builder(
                                initialRating: _rating,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 5,
                                itemSize: 48,
                                itemPadding: const EdgeInsets.symmetric(horizontal: 8),
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
                    ],
                  ),
                ),
              ),

// Only show submit button if feedback doesn't exist
            if (isConsultationComplete && !_feedbackExists)
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