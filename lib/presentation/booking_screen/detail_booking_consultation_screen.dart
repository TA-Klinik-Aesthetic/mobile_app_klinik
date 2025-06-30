import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:mobile_app_klinik/core/app_export.dart';
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class DetailBookingKonsultasi extends StatefulWidget {
  final Map<String, dynamic> dokter;

  const DetailBookingKonsultasi({super.key, required this.dokter});

  @override
  State<DetailBookingKonsultasi> createState() => _DetailBookingKonsultasiState();
}

class _DetailBookingKonsultasiState extends State<DetailBookingKonsultasi> {
  bool _isLoading = true;
  double averageRating = 0.0;
  int reviewCount = 0;
  List<Map<String, dynamic>> topFeedbacks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool isFavorite = false;
  
  // Tambahkan variabel baru untuk fitur booking
  TimeOfDay? _selectedTime;
  final TextEditingController _keluhanController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isBookingLoading = false;

  // Getter untuk validasi form
  bool get _isFormValid => 
      _selectedDay != null && 
      _selectedTime != null && 
      _keluhanController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    fetchDoctorDetails();
    _getUserData();
    checkFavoriteStatus();
  }
  
  // Fungsi untuk mendapatkan data user dari session token
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

  // Time picker untuk memilih jam konsultasi
  void _showTimePicker() {
    // Round the current time to the nearest 15 minutes to avoid the interval error
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

// Fungsi untuk melakukan booking konsultasi
  Future<void> _bookingKonsultasi() async {
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

      // Format waktu konsultasi: YYYY-MM-DD HH:MM:SS
      final DateTime konsultasiDate = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final String formattedDate =
          '${konsultasiDate.year}-'
          '${konsultasiDate.month.toString().padLeft(2, '0')}-'
          '${konsultasiDate.day.toString().padLeft(2, '0')} '
          '${konsultasiDate.hour.toString().padLeft(2, '0')}:'
          '${konsultasiDate.minute.toString().padLeft(2, '0')}:00';

      // Create the consultation with keluhan_pelanggan included directly
      final response = await http.post(
        Uri.parse(ApiConstants.bookingKonsultasi),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_dokter': widget.dokter['id_dokter'],
          'id_user': userId,
          'waktu_konsultasi': formattedDate,
          'keluhan_pelanggan': _keluhanController.text.trim(), // Include complaint directly
        }),
      );

      print('Consultation response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Booking Berhasil'),
              content: const Text('Jadwal konsultasi Anda telah berhasil dibuat.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            AppRoutes.routes[AppRoutes.homeScreen]!(context),
                      ),
                          (route) => false, // This removes all previous routes
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        final jsonData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? 'Gagal membuat jadwal')),
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

  Future<void> fetchDoctorDetails() async {
    try {
      // Fetch doctor's feedback
      final response = await http.get(
        Uri.parse('${ApiConstants.feedbackKonsultasi}?id_dokter=${widget.dokter['id_dokter']}'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final feedbackList = jsonData['data'] as List;

        if (feedbackList.isNotEmpty) {
          double totalRating = 0;
          for (var feedback in feedbackList) {
            totalRating += feedback['rating'];

            // Fetch user info for each feedback
            try {
              final int userId = feedback['konsultasi']['id_user'];
              final userResponse = await http.get(
                Uri.parse('${ApiConstants.profile}/$userId'),
              );

              if (userResponse.statusCode == 200) {
                final userData = jsonDecode(userResponse.body);
                feedback['user_name'] = userData['nama_user'] ?? 'Unknown User';
              } else {
                feedback['user_name'] = 'Unknown User';
              }
            } catch (e) {
              feedback['user_name'] = 'Unknown User';
              print('Error fetching user info: $e');
            }
          }

          // Sort by created_at to get the latest feedbacks
          feedbackList.sort((a, b) {
            return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
          });

          // Take the top 3 or less if there are fewer feedbacks
          final topFeedbacksCount = feedbackList.length > 3 ? 3 : feedbackList.length;
          final List<Map<String, dynamic>> topFeedbacksList = [];

          for (var i = 0; i < topFeedbacksCount; i++) {
            topFeedbacksList.add(Map<String, dynamic>.from(feedbackList[i]));
          }

          setState(() {
            averageRating = totalRating / feedbackList.length;
            reviewCount = feedbackList.length;
            topFeedbacks = topFeedbacksList;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctor details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if doctor is already favorited
  Future<void> checkFavoriteStatus() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) return;

      // Fetch favorite doctors
      final response = await http.get(
        Uri.parse(ApiConstants.viewDoctorFavorite.replaceAll('{id_user}', userId.toString())),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> favoriteDoctors = jsonData['data'] ?? [];

        // Check if current doctor is in favorites
        setState(() {
          isFavorite = favoriteDoctors.any(
                  (doctor) => doctor['id_dokter'].toString() == widget.dokter['id_dokter'].toString()
          );
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login untuk menambahkan favorit')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.addDoctorFavorite),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'id_user': userId,
          'id_dokter': widget.dokter['id_dokter'],
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          isFavorite = jsonData['is_favorited'] ?? !isFavorite;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonData['message'] ?? 'Status favorit diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status favorit')),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appTheme.whiteA700,
        elevation: 0,
        iconTheme: IconThemeData(color: appTheme.black900, size: 30), // Membesarkan ikon back
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: appTheme.black900,
            size: 35,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          padding: const EdgeInsets.all(16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? appTheme.darkCherry : appTheme.black900,
              size: 35,
            ),
            onPressed: toggleFavorite, // Update this line
            padding: const EdgeInsets.all(16),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor's photo
                    Center(
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: appTheme.lightGrey,
                          image: widget.dokter['foto_dokter'] != null
                              ? DecorationImage(
                                  image: NetworkImage('${widget.dokter['foto_dokter']}'),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.dokter['foto_dokter'] == null
                            ? Center(
                                child: Icon(Icons.person, size: 50, color: appTheme.black900),
                              )
                            : null,
                      ),
                    ),  
                    const SizedBox(height: 16),
                    
                    // Doctor's name
                    Center(
                      child: Text(
                        "${widget.dokter['nama_dokter']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Information box (Experience, Rating, Price)
                    Container(
                      decoration: BoxDecoration(
                        color: appTheme.whiteA700,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appTheme.black900, width: 1),
                      ),
                      child: Row(
                        children: [
                          // Experience
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.white, width: 1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "±5",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Tahun",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Rating
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.white, width: 1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "/ 10",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Price
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  Text(
                                    "FREE",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "/ sesi konsultasi",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: appTheme.black900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      "Komentar Teratas",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Comments grid
                    topFeedbacks.isEmpty
                      ? const Center(
                          child: Text(
                            "Belum ada komentar untuk dokter ini.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : topFeedbacks.length == 1 
                        // Single feedback layout (wide card)
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: appTheme.whiteA700,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: appTheme.black900, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // User info and date
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.person, size: 20, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  topFeedbacks[0]['user_name'] ?? "Pasien",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatDate(topFeedbacks[0]['created_at']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Rating stars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      color: index < (topFeedbacks[0]['rating']) 
                                          ? Colors.orange 
                                          : Colors.grey,
                                      size: 24,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                
                                // Comment text
                                Text(
                                  topFeedbacks[0]['teks_feedback'] ?? "Tidak ada komentar",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        // Multiple feedback layout (grid)
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.55,
                            ),
                            itemCount: topFeedbacks.length > 3 ? 3 : topFeedbacks.length,
                            itemBuilder: (context, index) {
                              final feedback = topFeedbacks[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: appTheme.whiteA700,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: appTheme.black900, width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // User info
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black,
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.person, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: Text(
                                        feedback['user_name'] ?? "Pasien",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        _formatDate(feedback['created_at']),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Rating stars
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          Icons.star,
                                          color: starIndex < (feedback['rating']) 
                                              ? appTheme.orange400 
                                              : Colors.grey,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Comment text
                                    Expanded(
                                      child: Text(
                                        feedback['teks_feedback'] ?? "Tidak ada komentar",
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 24),
                    
                    // Calendar section
                    const Text(
                      "Pilih waktu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Calendar
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
                                "${_getMonthName(_focusedDay.month)} ${_focusedDay.year}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  // Previous month button
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);

                                        // If selected day is in a different month, clear selection
                                        if (_selectedDay != null &&
                                            (_selectedDay!.month != _focusedDay.month || _selectedDay!.year != _focusedDay.year)) {
                                          _selectedDay = null;
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: appTheme.whiteA700,
                                      elevation: 0,
                                      padding: const EdgeInsets.all(8),
                                      shape: const CircleBorder(),
                                      side: BorderSide(color: appTheme.black900.withOpacity(0.2)),
                                    ),
                                    child: Icon(Icons.chevron_left, color: appTheme.black900),
                                  ),

                                  // Next month button
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

                                        // If selected day is in a different month, clear selection
                                        if (_selectedDay != null &&
                                            (_selectedDay!.month != _focusedDay.month || _selectedDay!.year != _focusedDay.year)) {
                                          _selectedDay = null;
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: appTheme.whiteA700,
                                      elevation: 0,
                                      padding: const EdgeInsets.all(8),
                                      shape: const CircleBorder(),
                                      side: BorderSide(color: appTheme.black900.withOpacity(0.2)),
                                    ),
                                    child: Icon(Icons.chevron_right, color: appTheme.black900),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Calendar
                          TableCalendar(
                            firstDay: DateTime(DateTime.now().year - 1, 1), // Allow viewing from January of last year
                            lastDay: DateTime(DateTime.now().year + 5, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            enabledDayPredicate: (day) {
                              // Only enable dates today or in the future
                              return !day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                            },
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
                      "Pilih jam konsultasi",
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appTheme.black900, width: 1),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime == null
                                  ? "Pilih jam konsultasi"
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
                    
                    // Text field untuk keluhan
                    const Text(
                      "Keluhan Anda",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: appTheme.whiteA700,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appTheme.black900, width: 1),
                      ),
                      child: TextField(
                        controller: _keluhanController,
                        maxLines: 3,
                        onChanged: (text) {
                          setState(() {}); // Refresh UI untuk validasi tombol
                        },
                        decoration: InputDecoration(
                          hintText: 'Tuliskan keluhan Anda di sini...',
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: appTheme.black900.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                        style: TextStyle(
                          color: appTheme.black900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Book button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isFormValid 
                            ? _isBookingLoading 
                                ? null 
                                : _bookingKonsultasi 
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid 
                              ? appTheme.orange200
                              : appTheme.lightGrey, // Abu-abu jika tidak valid
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                            : Text(
                                "ATUR JADWAL",
                                style: TextStyle(
                                  color: _isFormValid ? appTheme.whiteA700 : appTheme.lightGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

String _getMonthName(int month) {
  final List<String> months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return months[month - 1];
}

String _formatDate(String dateString) {
  try {
    final DateTime date = DateTime.parse(dateString);
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final String day = date.day.toString();
    final String month = months[date.month - 1];
    final String year = date.year.toString();
    
    return "$day $month $year";
  } catch (e) {
    return "Unknown Date";
  }
}