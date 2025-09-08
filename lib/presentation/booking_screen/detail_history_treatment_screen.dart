import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/user_screen/complaint_screen.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/widgets/ereceipt_screen.dart';
import 'dart:convert';
import '../../api/api_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app_klinik/presentation/payment_screen/payment_screen.dart';

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
  bool _isRefreshingPayment = false;

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
      if (widget.bookingId <= 0) {
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
          _bookingData = data['booking_treatment'] ?? data['data'];
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Refresh status pembayaran Midtrans berdasarkan id_pembayaran
  Future<void> _refreshPaymentStatus() async {
    final String? paymentId =
        _bookingData?['pembayaran_treatment']?['id_pembayaran']?.toString();

    if (paymentId == null) {
      _showMessage('ID pembayaran tidak ditemukan');
      return;
    }

    setState(() => _isRefreshingPayment = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        _showMessage('Silakan login terlebih dahulu');
        setState(() => _isRefreshingPayment = false);
        return;
      }

      final String refreshUrl =
          ApiConstants.refreshPembayaranMidtrans.replaceAll('{id_pembayaran}', paymentId);

      final response = await http.get(
        Uri.parse(refreshUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showMessage('Status pembayaran berhasil diperbarui');
        await fetchBookingDetails(); // ambil ulang detail
      } else {
        try {
          final err = jsonDecode(response.body);
          _showMessage(err['message'] ?? 'Gagal memperbarui status pembayaran');
        } catch (_) {
          _showMessage('Gagal memperbarui status pembayaran');
        }
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _isRefreshingPayment = false);
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
    final dateTime = DateTime.tryParse(dateString);
    if (dateTime == null) return '-';
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
    final dateTime = DateTime.tryParse(dateTimeString);
    if (dateTime == null) return '-';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Verifikasi':
        return appTheme.orange200;
      case 'Berhasil dibooking':
        return Colors.blueAccent;
      case 'Selesai':
        return Colors.green;
      case 'Dibatalkan':
        return Colors.red;
      default:
        return appTheme.lightGrey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _getStatusColor(status), width: 1),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    final s = (status.isEmpty ? 'Belum Dibayar' : status).toLowerCase();
    Color color;
    if (s == 'sudah dibayar' || s == 'berhasil' || s == 'settlement') {
      color = Colors.green;
    } else if (s == 'pending' || s == 'belum dibayar') {
      color = Colors.orange;
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
        status.isEmpty ? 'Belum Dibayar' : status,
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
            color: appTheme.orange200,
          ),
        ),
        backgroundColor: appTheme.whiteA700,
        elevation: 0.0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
        actions: [
          if (_bookingData?['status_booking_treatment'] == 'Selesai')
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 6, bottom: 4),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplaintScreen(
                        bookingId: widget.bookingId,
                        treatments: _bookingData?['detail_booking'] ?? [],
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_alert,
                        size: 20,
                        color: appTheme.darkCherry,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Komplain',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: appTheme.darkCherry,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? RefreshIndicator(
                  onRefresh: fetchBookingDetails,
                  color: appTheme.orange200,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
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
                              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchBookingDetails,
                  color: appTheme.orange200,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                  '${_formatDate(_bookingData?['created_at'] ?? '')} ${_formatTime(_bookingData?['created_at'] ?? '')}',
                                ),
                                const SizedBox(height: 12),

                                // Jadwal Treatment
                                _buildInfoRow(
                                  'Jadwal Treatment',
                                  '${_formatDate(_bookingData?['waktu_treatment'] ?? '')} ${_formatTime(_bookingData?['waktu_treatment'] ?? '')}',
                                ),
                                const SizedBox(height: 12),

                                // Nama Dokter
                                _buildInfoRow('Nama Dokter', _bookingData?['dokter']?['nama_dokter'] ?? '-'),
                                const SizedBox(height: 12),

                                // Nama Beautician
                                _buildInfoRow('Nama Beautician', _bookingData?['beautician']?['nama_beautician'] ?? '-'),
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
                                // Header + status + refresh
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
                                    Row(
                                      children: [
                                        _buildPaymentStatusBadge(
                                          _bookingData?['pembayaran_treatment']?['status_pembayaran'] ?? 'Belum Dibayar',
                                        ),
                                        const SizedBox(width: 8),
                                        if (_bookingData?['pembayaran_treatment'] != null &&
                                            _bookingData?['pembayaran_treatment']?['id_pembayaran'] != null)
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isRefreshingPayment ? null : _refreshPaymentStatus,
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: appTheme.orange200.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: appTheme.orange200.withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: _isRefreshingPayment
                                                    ? SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(appTheme.orange200),
                                                        ),
                                                      )
                                                    : Icon(Icons.refresh, size: 14, color: appTheme.orange200),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
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

                                // Potongan
                                if (_bookingData?['id_promo'] != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text('Potongan Harga', style: TextStyle(fontSize: 14, color: appTheme.black900)),
                                        ],
                                      ),
                                      Text('- Rp ${_formatPrice(_bookingData?['potongan_harga'])}',
                                          style: TextStyle(fontSize: 14, color: appTheme.black900)),
                                    ],
                                  ),
                                ],

                                // Pajak
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

                                // Detail Pembayaran (tampil jika sukses)
                                const SizedBox(height: 16),
                                Builder(builder: (_) {
                                  final pay = _bookingData?['pembayaran_treatment'] as Map<String, dynamic>?;
                                  final status = (pay?['status_pembayaran']?.toString() ?? '').toLowerCase();
                                  final isSuccess = status == 'sudah dibayar' || status == 'berhasil' || status == 'settlement';
                                  if (!isSuccess || pay == null) return const SizedBox.shrink();

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(height: 1, color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Detail Pembayaran',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: appTheme.black900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Metode Pembayaran', pay['metode_pembayaran']?.toString() ?? '-'),
                                      if (pay['waktu_pembayaran'] != null) ...[
                                        const SizedBox(height: 8),
                                        _buildInfoRow('Waktu Pembayaran', '${_formatDate(pay['waktu_pembayaran'])} ${_formatTime(pay['waktu_pembayaran'])}'),
                                      ],
                                      const SizedBox(height: 8),
                                      if (pay['transaction_status'] != null ||
                                          pay['payment_type'] != null ||
                                          pay['bank'] != null ||
                                          pay['va_number'] != null) ...[
                                        Container(height: 1, color: Colors.grey.shade300),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Detail Teknis',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: appTheme.black900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (pay['transaction_status'] != null) _buildInfoRow('Status Transaksi', pay['transaction_status'].toString()),
                                        if (pay['payment_type'] != null) ...[
                                          const SizedBox(height: 8),
                                          _buildInfoRow('Tipe Pembayaran', pay['payment_type'].toString()),
                                        ],
                                        if (pay['bank'] != null) ...[
                                          const SizedBox(height: 8),
                                          _buildInfoRow('Bank', pay['bank'].toString().toUpperCase()),
                                        ],
                                        if (pay['va_number'] != null) ...[
                                          const SizedBox(height: 8),
                                          _buildInfoRow('VA Number', pay['va_number'].toString()),
                                        ],
                                      ],
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

      // ============== Bottom Navigation Bar (Bayar / E-Receipt) ==============
      bottomNavigationBar: () {
        final String? payStatus = _bookingData?['pembayaran_treatment']?['status_pembayaran'];
        final String s = (payStatus ?? '').toLowerCase();
        final bool isSuccess = s == 'sudah dibayar' || s == 'berhasil' || s == 'settlement';
        final bool needsPayment = payStatus == null || s == 'belum dibayar' || s == 'pending';

        if (_bookingData == null) return null;

        if (isSuccess) {
          // Tombol E-Receipt Treatment
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EReceiptScreen.treatment(
                              bookingData: _bookingData!,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, color: Colors.white),
                      label: const Text(
                        'E-Receipt',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.orange200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!needsPayment) return null;

        // Tombol Bayar Sekarang (Midtrans)
        final double totalPrice =
            double.tryParse((_bookingData?['harga_akhir_treatment'] ?? '0').toString()) ?? 0.0;

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen.treatment(
                      treatmentBookingId: widget.bookingId,
                      name: 'Pembayaran Treatment',
                      price: totalPrice,
                    ),
                  ),
                );
                if (!mounted) return;
                // Apapun hasilnya, refresh data setelah kembali dari layar Midtrans
                await fetchBookingDetails();
                // Opsional tampilkan pesan
                if (result is String && result.isNotEmpty) {
                  _showMessage('Status pembayaran: $result');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.orange200,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: const Text(
                'Bayar Sekarang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      }(),
      // =======================================================================
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