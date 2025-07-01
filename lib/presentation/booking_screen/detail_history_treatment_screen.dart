import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api/api_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailHistoryTreatmentScreen extends StatefulWidget {
  final int bookingId;

  const DetailHistoryTreatmentScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<DetailHistoryTreatmentScreen> createState() => _DetailHistoryTreatmentScreenState();
}

class _DetailHistoryTreatmentScreenState extends State<DetailHistoryTreatmentScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBookingDetails();
  }

  Future<void> fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if bookingId is null
      if (widget.bookingId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'ID booking tidak valid';
        });
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Silakan login terlebih dahulu';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.detailBookingTreatment}/${widget.bookingId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookingData = data['booking_treatment'];
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
          _errorMessage = errorData['message'] ?? 'Gagal memuat data booking';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
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

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    final String monthName = _getIndonesianMonth(dateTime.month);
    return '${dateTime.day} $monthName ${dateTime.year}';
  }

  String _getIndonesianMonth(int month) {
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  String _formatTime(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verifikasi':
        return Colors.deepOrange;
      case 'Berhasil Dibooking':
        return Colors.blueAccent;
      case 'Selesai':
        return Colors.lightGreen;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return appTheme.lightGrey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80), // Add minimum width
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center, // Center the text
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color color;
    if (status == 'Sudah Dibayar') {
      color = Colors.green;
    } else if (status == 'Belum Dibayar') {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Treatment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: appTheme.orange200, // Orange color
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
        actions: [
          // Support icon only shown if status is "Selesai"
          if (_bookingData?['status_booking_treatment'] == 'Selesai')
            IconButton(
              icon: Icon(
                Icons.support_agent_rounded,
                size: 24,
                color: appTheme.darkCherry, // Dark cherry color
              ),
              onPressed: () {
                // Handle support action
              },
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
              onPressed: fetchBookingDetails,
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
                side: BorderSide(
                  color: appTheme.lightGrey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
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
                        _buildStatusBadge(_bookingData?['status_booking_treatment'] ?? 'Unknown'),
                      ],
                    ),
                    const Divider(height: 24),

                    // Waktu Booking
                    _buildInfoRow(
                        'Waktu Booking',
                        '${_formatDate(_bookingData?['created_at'] ?? '')} ${_formatTime(_bookingData?['created_at'] ?? '')}'
                    ),
                    const SizedBox(height: 12),

                    // Jadwal Treatment
                    _buildInfoRow(
                        'Jadwal Treatment',
                        '${_formatDate(_bookingData?['waktu_treatment'] ?? '')} ${_formatTime(_bookingData?['waktu_treatment'] ?? '')}'
                    ),
                    const SizedBox(height: 12),

                    // Nama Dokter
                    _buildInfoRow(
                        'Nama Dokter',
                        _bookingData?['dokter']?['nama_dokter'] ?? '-'
                    ),
                    const SizedBox(height: 12),

                    // Nama Beautician
                    _buildInfoRow(
                        'Nama Beautician',
                        _bookingData?['beautician']?['nama_beautician'] ?? '-'
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CONTAINER 2: Treatment List
            Text(
              'Rincian Treatment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 12),

            // Treatment list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_bookingData?['detail_booking'] as List?)?.length ?? 0,
              itemBuilder: (context, index) {
                final item = (_bookingData?['detail_booking'] as List)[index];
                final treatment = item['treatment'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: appTheme.whiteA700,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: appTheme.lightGrey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Treatment image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: treatment['gambar_treatment'] != null &&
                              treatment['gambar_treatment'].toString().isNotEmpty
                              ? Image.network(
                            "https://klinikneshnavya.com/${treatment['gambar_treatment']}",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                              );
                            },
                          )
                              : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Treatment details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                treatment['nama_treatment'] ?? 'Unnamed Treatment',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                treatment['deskripsi_treatment'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appTheme.black900.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: appTheme.lightGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatEstimasi(treatment['estimasi_treatment'] ?? '00:00:00'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appTheme.lightGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Price
                        Text(
                          'Rp ${_formatPrice(item['biaya_treatment'])}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: appTheme.orange200,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // CONTAINER 3: Payment Information
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
                    // Payment info header and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Informasi Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                        _buildPaymentStatusBadge(_bookingData?['pembayaran_treatment']?['status_pembayaran'] ?? 'Belum Dibayar'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                        Text('Rp ${_formatPrice(_bookingData?['harga_total'])}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),

                    // Discount if applicable
                    if (_bookingData?['id_promo'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Potongan Harga',
                                style: TextStyle(fontSize: 14, color: appTheme.black900),
                              ),
                            ],
                          ),
                          Text(
                            '- Rp ${_formatPrice(_bookingData?['potongan_harga'])}',
                            style: TextStyle(fontSize: 14, color: appTheme.black900),
                          ),
                        ],
                      ),
                    ],

                    // Tax row
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (10%):', style: TextStyle(fontSize: 14)),
                        Text('Rp ${_formatPrice(_bookingData?['besaran_pajak'])}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Pembayaran:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                        Text(
                          'Rp ${_formatPrice(_bookingData?['harga_akhir_treatment'])}',
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build info rows
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
}