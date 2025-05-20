import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import '../../api/api_constant.dart';

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

  @override
  void initState() {
    super.initState();
    fetchDoctorDetails();
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
            size: 35, // Membesarkan ukuran ikon back
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          padding: const EdgeInsets.all(16), // Menambahkan padding untuk area tap yang lebih besar
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? appTheme.darkCherry : appTheme.black900,
              size: 35, // Membesarkan ukuran ikon favorite
            ),
            onPressed: () {
              setState(() {
                isFavorite = !isFavorite;
              });
            },
            padding: const EdgeInsets.all(16), // Menambahkan padding untuk area tap yang lebih besar
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
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[300],
                          // Uncomment when you have the image
                          // image: DecorationImage(
                          //   image: AssetImage('assets/images/doctor_placeholder.png'),
                          //   fit: BoxFit.cover,
                          // ),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
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
                        color: appTheme.lightBadge100,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Tahun",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "/ 10",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "/ sesi konsultasi",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
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
                              color: appTheme.lightBadge100,
                              borderRadius: BorderRadius.circular(16),
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
                                  color: appTheme.lightBadge100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white, width: 0.5),
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
                                              ? Colors.orange 
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
                        color: appTheme.lightBadge100,
                        borderRadius: BorderRadius.circular(16),
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
                              // Warna untuk hari yang dipilih
                              selectedDecoration: BoxDecoration(
                                color: appTheme.darkCherry,
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: const TextStyle(color: Colors.white),
                              
                              // Warna untuk hari ini
                              todayDecoration: BoxDecoration(
                                color: appTheme.darkCherry.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: TextStyle(color: appTheme.black900, fontWeight: FontWeight.bold),
                              
                              // Warna default untuk tanggal
                              defaultTextStyle: TextStyle(color: appTheme.black900),
                              
                              // Warna untuk hari di luar bulan
                              outsideTextStyle: const TextStyle(color: Colors.grey),
                              outsideDaysVisible: false,
                              
                              // Warna untuk hari weekend
                              weekendTextStyle: TextStyle(color: appTheme.darkCherry),

                              // Marker yang mungkin menunjukkan jadwal
                              markerDecoration: BoxDecoration(
                                color: appTheme.darkCherry,
                                shape: BoxShape.circle,
                              ),
                            ),
                            
                            // Style untuk hari dalam seminggu (Mon, Tue, Wed, dll)
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: appTheme.black900,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              weekendStyle: TextStyle(
                                color: appTheme.darkCherry,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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
                        color: appTheme.lightBadge100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: TextField(
                        maxLines: 5,
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
                        onPressed: _selectedDay == null
                            ? null
                            : () {
                                // Handle booking
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "ATUR JADWAL",
                          style: TextStyle(
                            color: _selectedDay == null ? Colors.grey : Colors.black,
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