import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/booking_screen/detail_booking_consultation_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/model/doctor_card_model.dart';

import '../../api/api_constant.dart';

class BookingConsultationScreen extends StatefulWidget {
  const BookingConsultationScreen({super.key});

  @override
  _BookingConsultationScreenState createState() => _BookingConsultationScreenState();
}

class _BookingConsultationScreenState extends State<BookingConsultationScreen> {
  List<dynamic> doctorList = [];

  @override
  void initState() {
    super.initState();
    fetchDoctor();
  }

  Future<void> fetchDoctor() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.dokter));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          doctorList = data['data'];
        });
      } else {
        debugPrint('Failed to load doctor data');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: doctorList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "Terdapat ${doctorList.length} Dokter Terdaftar",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: doctorList.length,
                    itemBuilder: (context, index) {
                      final doctor = doctorList[index];
                      return DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailBookingKonsultasi(dokter: doctor),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
