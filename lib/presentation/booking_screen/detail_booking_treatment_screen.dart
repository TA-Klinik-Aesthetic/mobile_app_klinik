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
  List<Map<String, dynamic>> _availableTimeSlots = [];
  bool _isLoadingTimeSlots = false;
  Map<String, dynamic>? _selectedTimeSlot;
  Promo? _selectedPromo;
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

  Future<void> _fetchTimeSlots(DateTime date) async {
    setState(() {
      _isLoadingTimeSlots = true;
      _availableTimeSlots = [];
      _selectedTimeSlot = null;
    });

    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final response = await http.get(
        Uri.parse("${ApiConstants.jadwalTreatment}/$formattedDate"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            if (data['data']['details'] != null) {
              _availableTimeSlots = List<Map<String, dynamic>>.from(data['data']['details']);
            } else {
              _availableTimeSlots = [];
            }
          });

          if (_availableTimeSlots.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak ada jadwal tersedia untuk tanggal ini')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat jadwal: ${data['message'] ?? "Unknown error"}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching time slots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoadingTimeSlots = false;
      });
    }
  }

  // Replace time picker with time slot selector
  void _showTimeSlotSelector() {
    if (_availableTimeSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada jadwal tersedia untuk tanggal ini')),
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
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: _availableTimeSlots.length,
                itemBuilder: (context, index) {
                  final timeSlot = _availableTimeSlots[index];
                  final isAvailable = timeSlot['status_jadwal'] == 'tersedia';
                  final timeString = timeSlot['waktu_tersedia'].toString().substring(0, 5); // Format HH:MM

                  return GestureDetector(
                    onTap: isAvailable ? () {
                      setState(() {
                        _selectedTimeSlot = timeSlot;
                      });
                      Navigator.pop(context);
                    } : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? (_selectedTimeSlot != null && _selectedTimeSlot!['id_detail'] == timeSlot['id_detail'])
                            ? appTheme.orange200
                            : Colors.white
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable
                              ? (_selectedTimeSlot != null && _selectedTimeSlot!['id_detail'] == timeSlot['id_detail'])
                              ? appTheme.orange200
                              : appTheme.lightGrey
                              : Colors.grey[300]!,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        timeString,
                        style: TextStyle(
                          color: isAvailable
                              ? (_selectedTimeSlot != null && _selectedTimeSlot!['id_detail'] == timeSlot['id_detail'])
                              ? Colors.white
                              : appTheme.black900
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
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

  // Add day selection handler to fetch time slots
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedTimeSlot = null;
    });

    _fetchTimeSlots(selectedDay);
  }

// Update booking treatment function to use time slot ID
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

      // Format date
      final String formattedDate = "${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}";

      // Create treatment detail list for request
      final List<Map<String, dynamic>> treatmentDetails = _treatments.map((treatment) {
        return {
          "id_treatment": treatment['id_treatment'],
          "id_kompensasi_diberikan": null
        };
      }).toList();

      // Create request body according to updated API format
      Map<String, dynamic> requestBody = {
        'id_user': userId,
        'waktu_treatment': formattedDate,
        'id_detail_jadwal_treatment': _selectedTimeSlot!['id_detail'],
        'id_dokter': 1, // This could be dynamic in the future
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

        // Safely access the booking ID
        int? bookingId = responseData['data']?['id_booking_treatment'] ??
            responseData['booking_treatment']?['id_booking_treatment'] ??
            responseData['id_booking_treatment'] ??
            responseData['id'];

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
          title: const Text('Konfirmasi Penghapusan'),
          content: const Text('Yakin anda ingin menghapusnya dari cart?'),
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
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,),
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
          border: Border.all(color: appTheme.lightGrey, width: 1),
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
                                      color: appTheme.darkCherry.withAlpha((0.6 * 255).toInt()),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close, size: 16, color: appTheme.whiteA700),
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
                  "Pilih Tanggal & Waktu Treatment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Calendar widget
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appTheme.lightGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 60)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            color: appTheme.black900,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          selectedDecoration: BoxDecoration(
                            color: appTheme.orange200,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: appTheme.orange200.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: Colors.white),
                        ),
                        onDaySelected: _onDaySelected,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectedDay != null ? _showTimeSlotSelector : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: appTheme.lightGrey),
                            borderRadius: BorderRadius.circular(8),
                            color: _selectedDay == null ? Colors.grey[200] : Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTimeSlot != null
                                    ? "Waktu: ${_selectedTimeSlot!['waktu_tersedia'].toString().substring(0, 5)}"
                                    : "Pilih Waktu",
                                style: TextStyle(
                                  color: _selectedTimeSlot != null ? appTheme.black900 : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                color: _selectedDay == null ? Colors.grey : appTheme.orange200,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoadingTimeSlots)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator(color: appTheme.orange200)),
                        ),
                    ],
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
                      const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                      Text('Rp ${_formatPrice(_calculateTotalPrice())}', style: const TextStyle(fontSize: 14)),
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
                  // Tax row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pajak (10%):', style: TextStyle(fontSize: 14)),
                      Text('Rp ${_formatPrice(_calculateTax())}', style: const TextStyle(fontSize: 14)),
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.black900),
                    ),
                    Text(
                      'Rp ${_formatPrice(_calculateFinalPrice())}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: appTheme.orange200),
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