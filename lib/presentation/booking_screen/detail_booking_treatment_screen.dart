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
  List<String> _availableTimeSlots = [];
  List<String> _bookedTimeSlots = [];
  String? _selectedTimeSlot;
  bool _isLoadingTimeSlots = false;
  Promo? _selectedPromo;

  //Promo Related
  List<Promo> _promos = [];
  bool _isLoadingPromos = false;
  final PromoService _promoService = PromoService();

  // Date and time selection
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isBookingLoading = false;
  Map<String, dynamic>? _userData;

  // Getter for form validation
  bool get _isFormValid =>
      _selectedDay != null &&
          _selectedTimeSlot != null;

  @override
  void initState() {
    super.initState();
    _treatments = List.from(widget.selectedTreatments);
    _fetchPromos();
    _getUserData();
  }

  List<String> _generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 10; hour <= 20; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00:00');
      if (hour < 20) {
        slots.add('${hour.toString().padLeft(2, '0')}:30:00');
      }
    }
    return slots;
  }

  Future<void> _fetchBookedTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingTimeSlots = true;
      _bookedTimeSlots = [];
      _selectedTimeSlot = null;
    });

    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      // Get all booking treatments first
      final response = await http.get(
        Uri.parse(ApiConstants.bookingTreatment),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> bookedSlotsForDate = [];

        // Handle different response structures
        List<dynamic> bookings = [];
        if (data['data'] != null) {
          bookings = data['data'] is List ? data['data'] : [data['data']];
        } else if (data['booking_treatments'] != null) {
          bookings = data['booking_treatments'];
        } else if (data['booking_treatment'] != null) {
          bookings = [data['booking_treatment']];
        }

        print('Total bookings found: ${bookings.length}');

        for (var booking in bookings) {
          if (booking['waktu_treatment'] != null) {
            String waktuTreatment = booking['waktu_treatment'];
            print('Processing booking time: $waktuTreatment');

            try {
              DateTime bookingDateTime = DateTime.parse(waktuTreatment);

              // Only add to booked slots if it's the same date
              String bookingDateOnly = "${bookingDateTime.year}-${bookingDateTime.month.toString().padLeft(2, '0')}-${bookingDateTime.day.toString().padLeft(2, '0')}";

              print('Booking date: $bookingDateOnly, Selected date: $formattedDate');

              if (bookingDateOnly == formattedDate) {
                String roundedTime = _roundToNearestSlot(bookingDateTime);
                print('Adding booked slot for selected date: $roundedTime');
                bookedSlotsForDate.add(roundedTime);
              } else {
                print('Skipping booking - different date');
              }
            } catch (e) {
              print('Error parsing time: $waktuTreatment - $e');
            }
          }
        }

        print('Booked slots for $formattedDate: $bookedSlotsForDate');

        setState(() {
          _bookedTimeSlots = bookedSlotsForDate;
          _availableTimeSlots = _generateTimeSlots()
              .where((slot) => !_bookedTimeSlots.contains(slot))
              .toList();
          _isLoadingTimeSlots = false;
        });

        print('Available slots: $_availableTimeSlots');
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _availableTimeSlots = _generateTimeSlots();
          _isLoadingTimeSlots = false;
        });
      }
    } catch (e) {
      print('Error fetching booked time slots: $e');
      setState(() {
        _availableTimeSlots = _generateTimeSlots();
        _isLoadingTimeSlots = false;
      });
    }
  }

  String _roundToNearestSlot(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;

    if (minute <= 15) {
      minute = 0;
    } else if (minute <= 45) {
      minute = 30;
    } else {
      minute = 0;
      hour += 1;
    }

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  String _formatTimeForDisplay(String timeSlot) {
    return timeSlot.substring(0, 5);
  }

  void _showTimeSlotSelector() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal terlebih dahulu')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Waktu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appTheme.black900,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: appTheme.black900),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingTimeSlots)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _generateTimeSlots().length,
                  itemBuilder: (context, index) {
                    final timeSlot = _generateTimeSlots()[index];
                    final isBooked = _bookedTimeSlots.contains(timeSlot);
                    final isSelected = _selectedTimeSlot == timeSlot;
                    final isAvailable = !isBooked;

                    return GestureDetector(
                      onTap: isAvailable ? () {
                        setState(() {
                          _selectedTimeSlot = timeSlot;
                        });
                        Navigator.pop(context);
                      } : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked
                              ? Colors.grey[300]
                              : isSelected
                              ? appTheme.orange200
                              : Colors.white,
                          border: Border.all(
                            color: isBooked
                                ? Colors.grey[400]!
                                : isSelected
                                ? appTheme.orange200
                                : appTheme.lightGrey,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTimeForDisplay(timeSlot),
                                style: TextStyle(
                                  color: isBooked
                                      ? Colors.grey[600]
                                      : isSelected
                                      ? Colors.white
                                      : appTheme.black900,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (isBooked)
                                Text(
                                  'Terisi',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                        ),
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTimeSlot = null;
    });

    _fetchBookedTimeSlots(selectedDay);
  }

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
        // Filter promos to only include "Produk" type
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

  Future<void> _bookTreatment() async {
    if (!_isFormValid) return;

    setState(() {
      _isBookingLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        setState(() => _isBookingLoading = false);
        return;
      }

      final String formattedDate = "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";
      final String waktuTreatment = "$formattedDate $_selectedTimeSlot";

      final List<Map<String, dynamic>> treatmentDetails = _treatments.map((treatment) {
        return {
          "id_treatment": treatment['id_treatment'],
          "id_kompensasi_diberikan": null
        };
      }).toList();

      Map<String, dynamic> requestBody = {
        'id_user': userId,
        'waktu_treatment': waktuTreatment,
        'id_dokter': null,
        'id_beautician': null,
        'id_promo': _selectedPromo?.idPromo,
        'details': treatmentDetails,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.bookingTreatment),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        int? bookingId = responseData['booking_treatment']?['id_booking_treatment'];

        if (bookingId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailHistoryTreatmentScreen(bookingId: bookingId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking berhasil tapi ID tidak ditemukan')),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.treatmentHistoryScreen);
        }
      } else {
        final errorMsg = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ?? 'Gagal melakukan booking'
            : 'Gagal melakukan booking';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      setState(() => _isBookingLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isBookingLoading = false);
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Treatment'),
          content: const Text('Apakah Anda yakin ingin menghapus treatment ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () {
                setState(() {
                  _treatments.removeAt(index);
                });
                Navigator.of(context).pop();
              },
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

  double _calculateTax() {
    double totalPrice = _calculateTotalPrice();
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    double afterDiscount = totalPrice - discount;
    return (afterDiscount * 0.10).clamp(0, double.infinity);
  }

  double _calculateFinalPrice() {
    double totalPrice = _calculateTotalPrice();
    double discount = _selectedPromo?.calculateDiscount(totalPrice) ?? 0.0;
    double afterDiscount = totalPrice - discount;
    double tax = _calculateTax();
    return (afterDiscount + tax).clamp(0, double.infinity);
  }

  String _formatEstimasi(String estimasi) {
    try {
      final parts = estimasi.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
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
                border: Border.all(color: appTheme.lightGreen, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedPromo!.namaPromo} berhasil diterapkan',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
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
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada promo tersedia',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
        bool isSelected = _selectedPromo != null && _selectedPromo!.idPromo == promo.idPromo;

        // Check if cart total meets minimum spending requirement
        double minBelanja = double.tryParse(promo.minimalBelanja ?? '0') ?? 0;
        bool isEligible = _calculateTotalPrice() >= minBelanja;
        double amountNeeded = minBelanja - _calculateTotalPrice();

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
            onTap: isEligible ? () {
              setState(() {
                _selectedPromo = promo;
              });
              Navigator.pop(context);
            } : null,
            child: Opacity(
              opacity: isEligible ? 1.0 : 0.7,
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEligible ? appTheme.black900 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          promo.formatPromoValue(),
                          style: TextStyle(
                            fontSize: 16,
                            color: isEligible ? appTheme.orange200 : Colors.grey.shade500,
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
                        color: isEligible ? Colors.grey.shade600 : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Minimal belanja: Rp ${_formatPrice(minBelanja)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isEligible ? appTheme.orange200 : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Periode: ${promo.formatDate(promo.tanggalMulai)} - ${promo.formatDate(promo.tanggalBerakhir)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: appTheme.lightGrey,
                          ),
                        ),
                      ],
                    ),

                    // Show missing amount if not eligible
                    if (!isEligible) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          "Belanja Rp ${_formatPrice(amountNeeded)} lagi untuk menggunakan promo ini",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
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
          border: Border.all(color: appTheme.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.discount_outlined, color: appTheme.orange200),
            const SizedBox(width: 16),
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
        title: Text(
          'Booking Treatment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: appTheme.orange200,
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
                // Treatment Cards
                ...List.generate(_treatments.length, (index) {
                  final treatment = _treatments[index];
                  final imageUrl = treatment['gambar_treatment'] ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: appTheme.lightGrey, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Treatment Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                              "https://klinikneshnavya.com/${treatment['gambar_treatment']}",
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                                );
                              },
                            )
                                : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Treatment Details
                          Expanded(
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Treatment Name - with padding to avoid delete button
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: _treatments.length > 1 ? 40 : 0,
                                      ),
                                      child: Text(
                                        treatment['nama_treatment'] ?? 'Nama tidak tersedia',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Description - limited to 2 lines and aligned with price width
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Calculate available width considering the price text width
                                        const priceWidth = 80.0; // Approximate width for price text
                                        final availableWidth = constraints.maxWidth - priceWidth - 16; // 16 for spacing

                                        return Container(
                                          width: availableWidth,
                                          child: Text(
                                            treatment['deskripsi_treatment'] ?? 'Deskripsi tidak tersedia',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Estimasi and Price row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Estimasi
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatEstimasi(treatment['estimasi_treatment'] ?? '0:00:00'),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Price
                                        Text(
                                          'Rp ${_formatPrice(treatment['biaya_treatment'])}',
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
                                // Floating Delete Button
                                if (_treatments.length > 1)
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: appTheme.darkCherry,
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      constraints: const BoxConstraints(
                                        minWidth: 12,
                                        minHeight: 12,
                                      ),
                                      onPressed: () => _showDeleteConfirmation(context, index),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // Date & Time Selection
                Card(
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
                        Text(
                          'Pilih Tanggal & Waktu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TableCalendar<DateTime>(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 30)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: _onDaySelected,
                          calendarFormat: CalendarFormat.month,
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          calendarStyle: CalendarStyle(
                            selectedDecoration: BoxDecoration(
                              color: appTheme.orange200,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(color: Colors.white),
                            todayDecoration: BoxDecoration(
                              color: appTheme.orange200.withAlpha(150),
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
                          availableGestures: AvailableGestures.all,
                        ),
                        const SizedBox(height: 8),
                        // Debug information
                        if (_selectedDay != null) ...[
                          Text(
                            'Tanggal dipilih: ${_selectedDay!.day}-${_selectedDay!.month}-${_selectedDay!.year}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            'Waktu terisi: ${_bookedTimeSlots.length} slot',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Time selection button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedDay != null ? _showTimeSlotSelector : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedDay != null
                                  ? appTheme.orange200
                                  : Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _selectedTimeSlot != null
                                  ? 'Waktu: ${_formatTimeForDisplay(_selectedTimeSlot!)}'
                                  : 'Pilih Waktu',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Promo Section
                Card(
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
                        Text(
                          'Promo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appTheme.black900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPromoButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Payment Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: appTheme.whiteA700,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                    Text('Rp ${_formatPrice(_calculateTotalPrice())}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
                if (_selectedPromo != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon:', style: TextStyle(fontSize: 16)),
                      Text('- Rp ${_formatPrice(_selectedPromo!.calculateDiscount(_calculateTotalPrice()))}',
                          style: TextStyle(fontSize: 16, color: appTheme.lightGreen)),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pajak (10%):', style: TextStyle(fontSize: 16)),
                    Text('+ Rp ${_formatPrice(_calculateTax())}', style: TextStyle(fontSize: 16, color: appTheme.darkCherry)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rp ${_formatPrice(_calculateFinalPrice())}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: appTheme.orange200)),
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
                        fontSize: 18,
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