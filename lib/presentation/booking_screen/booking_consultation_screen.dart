import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/booking_screen/detail_booking_consultation_screen.dart';
import 'package:mobile_app_klinik/presentation/booking_screen/model/doctor_card_model.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class BookingConsultationScreen extends StatefulWidget {
  const BookingConsultationScreen({super.key});

  @override
  _BookingConsultationScreenState createState() => _BookingConsultationScreenState();
}

class _BookingConsultationScreenState extends State<BookingConsultationScreen> {
  List<dynamic> doctorList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDoctor();
  }

  Future<void> fetchDoctor() async {
    setState(() {
      isLoading = true;
    });

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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await fetchDoctor();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: appTheme.orange200,
        backgroundColor: Colors.white,
        child: doctorList.isEmpty && isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}