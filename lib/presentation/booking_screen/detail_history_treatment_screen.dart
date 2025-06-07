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
        return Colors.blue;
      case 'Dikonfirmasi':
        return Colors.green;
      case 'Selesai':
        return appTheme.orange200;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Text(
        status,
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
        title: const Text(
          'Detail Treatment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
            // Header with booking number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${_bookingData?['id_booking_treatment'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(_bookingData?['status_booking_treatment'] ?? 'Unknown'),
              ],
            ),
            const SizedBox(height: 8),

            // Date and time
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
                      'Jadwal Treatment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.black900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tanggal: ${_formatDate(_bookingData?['waktu_treatment'] ?? '')}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: appTheme.orange200,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Jam: ${_formatTime(_bookingData?['waktu_treatment'] ?? '')}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Treatment list header
            Text(
              'Rincian Treatment',
              style: TextStyle(
                fontSize: 16,
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
                  color: appTheme.lightBadge100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Treatment image (left side)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: treatment['gambar_treatment'] != null
                              ? Image.network(
                            treatment['gambar_treatment'],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
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

                        // Treatment details (middle)
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

            // Payment details
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
                        _buildPaymentStatusBadge(_bookingData?['status_pembayaran'] ?? 'Unknown'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Rp ${_formatPrice(_bookingData?['harga_total'])}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    // Show discount if applicable
                    if (_bookingData?['id_promo'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Diskon',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: appTheme.orange200,
                                ),
                              ),
                              if (_bookingData?['promo'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: appTheme.orange200.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _bookingData?['promo']['nama_promo'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appTheme.orange200,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '- Rp ${_formatPrice(_bookingData?['potongan_harga'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: appTheme.orange200,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
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

            // User information
            if (_bookingData?['user'] != null) ...[
              const SizedBox(height: 16),
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
                        'Informasi Pelanggan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appTheme.black900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Image.network(
                              _bookingData?['user']['foto_profil'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white, size: 30),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _bookingData?['user']['nama_user'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 14, color: appTheme.lightGrey),
                                    const SizedBox(width: 4),
                                    Text(
                                      _bookingData?['user']['no_telp'] ?? '-',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: appTheme.lightGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}