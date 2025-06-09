import 'package:flutter/material.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/detail_history_treatment_screen.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api/api_constant.dart';
import 'model/promo_model.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app_klinik/routes/app_routes.dart';

class DetailBookingTreatmentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedTreatments;

  const DetailBookingTreatmentScreen({super.key, required this.selectedTreatments});

  @override
  State<DetailBookingTreatmentScreen> createState() => _DetailBookingTreatmentScreenState();
}

class _DetailBookingTreatmentScreenState extends State<DetailBookingTreatmentScreen> {
  late List<Map<String, dynamic>> _treatments;
  List<Promo> _promos = [];
  Promo? _selectedPromo;
  bool _isLoadingPromos = false;
  final PromoService _promoService = PromoService();

  // New variables for date and time selection
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  bool _isBookingLoading = false;
  Map<String, dynamic>? _userData;

  // Getter for form validation
  bool get _isFormValid =>
      _selectedDay != null &&
          _selectedTime != null;

  @override
  void initState() {
    super.initState();
    // Create a copy of the list to avoid modifying the original
    _treatments = List.from(widget.selectedTreatments);
    _fetchPromos();
    _getUserData();
  }

  // Get user data from shared preferences
  Future<void> _getUserData() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token != null) {
        final response = await http.get(
          Uri.parse(ApiConstants.profile),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _userData = jsonDecode(response.body);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat data pengguna')),
          );
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchPromos() async {
    setState(() {
      _isLoadingPromos = true;
    });

    try {
      final promos = await _promoService.fetchPromos();
      setState(() {
        // Filter promos to only include "Treatment" type
        _promos = promos.where((promo) => promo.jenisPromo == "Treatment").toList();
        _isLoadingPromos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPromos = false;
      });
      print('Error fetching promos: $e');
    }
  }

  void _showTimePicker() {
    // Round the current time to the nearest 15 minutes
    final DateTime now = DateTime.now();
    const int minuteInterval = 15;
    final int minutes = ((now.minute + minuteInterval ~/ 2) ~/ minuteInterval) * minuteInterval;
    final DateTime initialDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        minutes
    );

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: const Text('Selesai'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    minuteInterval: minuteInterval,
                    onDateTimeChanged: (DateTime newTime) {
                      setState(() {
                        _selectedTime = TimeOfDay(
                            hour: newTime.hour,
                            minute: newTime.minute
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Booking treatment function
  Future<void> _bookTreatment() async {
    if (!_isFormValid) return;

    setState(() {
      _isBookingLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk melakukan booking')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan, silakan login ulang')),
        );
        setState(() {
          _isBookingLoading = false;
        });
        return;
      }

      // Format waktu treatment: YYYY-MM-DD HH:MM:SS
      final DateTime treatmentDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final String formattedDate =
          '${treatmentDate.year}-'
          '${treatmentDate.month.toString().padLeft(2, '0')}-'
          '${treatmentDate.day.toString().padLeft(2, '0')} '
          '${treatmentDate.hour.toString().padLeft(2, '0')}:'
          '${treatmentDate.minute.toString().padLeft(2, '0')}:00';

      // Create treatment detail list for request
      final List<Map<String, dynamic>> treatmentDetails = _treatments.map((treatment) {
        return {
          'id_treatment': treatment['id_treatment'],
        };
      }).toList();

      // Create request body according to API format
      Map<String, dynamic> requestBody = {
        'id_user': userId,
        'waktu_treatment': formattedDate,
        'id_dokter': null,
        'id_beautician': null,
        'status_booking_treatment': 'Verifikasi',
        'id_promo': _selectedPromo?.idPromo,
        'details': treatmentDetails
      };

      // Send the booking request
      final response = await http.post(
        Uri.parse(ApiConstants.bookingTreatment),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Safely access the booking ID
        int bookingId = responseData['data']['id_booking_treatment'] ?? responseData['id_booking_treatment'];

        if (responseData != null && responseData['booking_treatment'] != null) {
          bookingId = responseData['booking_treatment']['id_booking_treatment'];
        } else if (responseData != null && responseData.containsKey('id_booking_treatment')) {
          // Alternative location if the structure is different
          bookingId = responseData['id_booking_treatment'];
        } else if (responseData != null && responseData.containsKey('id')) {
          // Check if ID is directly in the response
          bookingId = responseData['id'];
        }

        if (bookingId != null) {
          // Navigate to history treatment screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailHistoryTreatmentScreen(bookingId: bookingId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking berhasil, tapi ID tidak ditemukan')),
          );
          // Navigate back
          Navigator.pop(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Gagal membuat jadwal')),
        );
      }

      setState(() {
        _isBookingLoading = false;
      });
    } catch (e) {
      setState(() {
        _isBookingLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Yakin ingin menghapusnya dari cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _treatments.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
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

  double _calculateTotalPrice() {
    double total = 0.0;
    for (var t in _treatments) {
      if (t['biaya_treatment'] != null) {
        if (t['biaya_treatment'] is int) {
          total += (t['biaya_treatment'] as int).toDouble();
        } else if (t['biaya_treatment'] is String) {
          total += double.tryParse(t['biaya_treatment']) ?? 0.0;
        } else if (t['biaya_treatment'] is double) {
          total += t['biaya_treatment'];
        }
      }
    }
    return total;
  }

  double _calculateFinalPrice() {
    double totalPrice = _calculateTotalPrice();
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    return totalPrice - discount;
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

  void _showPromoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildPromoBottomSheet(),
    );
  }

  Widget _buildPromoBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pilih Promo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedPromo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedPromo!.namaPromo} berhasil diterapkan',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoadingPromos
                ? const Center(child: CircularProgressIndicator())
                : _promos.isEmpty
                ? _buildEmptyPromoState()
                : _buildPromoList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPromoState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada promo tersedia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoList() {
    return ListView.builder(
      itemCount: _promos.length,
      itemBuilder: (context, index) {
        final promo = _promos[index];
        bool isSelected = _selectedPromo != null &&
            _selectedPromo!.idPromo == promo.idPromo;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? appTheme.orange200 : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPromo = promo;
              });
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        promo.namaPromo ?? 'Promo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        promo.formatPromoValue(),
                        style: TextStyle(
                          fontSize: 16,
                          color: appTheme.orange200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo.deskripsiPromo ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Periode: ${promo.formatDate(promo.tanggalMulai)} - ${promo.formatDate(promo.tanggalBerakhir)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: appTheme.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromoButton() {
    return InkWell(
      onTap: _showPromoBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          border: Border.all(color: appTheme.black900, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.discount_outlined, color: appTheme.orange200),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedPromo != null
                    ? '${_selectedPromo!.namaPromo} diterapkan'
                    : 'Gunakan Promo',
                style: TextStyle(
                  color: _selectedPromo != null ? appTheme.black900 : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.grey.shade600,
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
        title: const Text(
          'Ringkasan Booking',
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
      body: _treatments.isEmpty
          ? Center(
        child: Text(
          'Tidak ada treatment yang dipilih.',
          style: TextStyle(fontSize: 16, color: appTheme.lightGrey),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Selected treatments list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _treatments.length,
                  itemBuilder: (context, index) {
                    final treatment = _treatments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: appTheme.whiteA700,
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
                                width: 80,
                                height: 80,
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
                                      fontWeight: FontWeight.bold,
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
                                        color: appTheme.black900,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatEstimasi(treatment['estimasi_treatment'] ?? '00:00:00'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: appTheme.black900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Price and delete (right side)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () => _showDeleteConfirmation(context, index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Rp ${_formatPrice(treatment['biaya_treatment'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: appTheme.orange200,
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

                const SizedBox(height: 24),

                // Calendar section
                const Text(
                  "Pilih Tanggal Treatment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar widget
                Container(
                  decoration: BoxDecoration(
                    color: appTheme.whiteA700,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: appTheme.black900, width: 1),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Month selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_focusedDay.month}/${_focusedDay.year}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(2030),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        headerVisible: false,
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: appTheme.orange200,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: Colors.white),
                          todayDecoration: BoxDecoration(
                            color: appTheme.orange200.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(color: appTheme.black900, fontWeight: FontWeight.bold),
                          defaultTextStyle: TextStyle(color: appTheme.black900),
                          outsideTextStyle: const TextStyle(color: Colors.grey),
                          outsideDaysVisible: false,
                          weekendTextStyle: TextStyle(color: appTheme.orange200),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: appTheme.black900,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          weekendStyle: TextStyle(
                            color: appTheme.orange200,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Time picker section
                const Text(
                  "Pilih Jam Treatment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showTimePicker,
                  child: Container(
                    decoration: BoxDecoration(
                      color: appTheme.whiteA700,
                      border: Border.all(color: appTheme.black900, width: 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTime == null
                              ? "Pilih jam treatment"
                              : "Jam ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            color: _selectedTime == null
                                ? appTheme.black900.withOpacity(0.5)
                                : appTheme.black900,
                            fontSize: 14,
                          ),
                        ),
                        Icon(Icons.access_time, color: appTheme.black900),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Promo section
                const Text(
                  "Promo",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPromoButton(),
              ],
            ),
          ),
          // Payment summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appTheme.whiteA700,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha((0.2 * 255).toInt()),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add discount row if promo is selected
                if (_selectedPromo != null) ...[
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
                        'Rp ${_formatPrice(_calculateTotalPrice())}',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: appTheme.orange200.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedPromo!.namaPromo ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: appTheme.orange200,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '- Rp ${_formatPrice(_selectedPromo!.calculateDiscount(_calculateTotalPrice()))}',
                        style: TextStyle(
                          fontSize: 14,
                          color: appTheme.orange200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
                const SizedBox(height: 8),
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
                      'Rp ${_formatPrice(_calculateFinalPrice())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.orange200,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isFormValid
                        ? _isBookingLoading
                        ? null
                        : _bookTreatment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? appTheme.orange200
                          : Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isBookingLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Konfirmasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}