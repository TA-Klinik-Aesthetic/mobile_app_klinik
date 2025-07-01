import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/core/app_export.dart';
import 'dart:convert';
import '../../../api/api_constant.dart';

class DoctorCard extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final VoidCallback onTap;

  const DoctorCard({super.key, required this.doctor, required this.onTap});

  @override
  State<DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<DoctorCard> {
  double averageRating = 0.0;
  int reviewCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctorRating();
  }

  Future<void> fetchDoctorRating() async {
    try {
      final doctorId = widget.doctor['id_dokter'].toString();
      print('Fetching ratings for doctor ID: $doctorId');

      // Get all feedbacks and filter by doctor ID manually
      final response = await http.get(
        Uri.parse(ApiConstants.feedbackKonsultasi),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final allFeedbackList = jsonData['data'] as List;

        // Filter feedbacks for this specific doctor
        final feedbackList = allFeedbackList.where((feedback) {
          // Check if konsultasi exists and its id_dokter matches our doctor ID
          return feedback['konsultasi'] != null &&
              feedback['konsultasi']['id_dokter'].toString() == doctorId;
        }).toList();

        print('Number of feedbacks found for this doctor: ${feedbackList.length}');

        if (feedbackList.isNotEmpty) {
          double totalRating = 0;
          for (var feedback in feedbackList) {
            totalRating += double.parse(feedback['rating'].toString());
          }

          setState(() {
            averageRating = totalRating / feedbackList.length;
            reviewCount = feedbackList.length;
            isLoading = false;
            print('Set average rating to: $averageRating, reviews: $reviewCount');
          });
        } else {
          setState(() {
            averageRating = 0;
            reviewCount = 0;
            isLoading = false;
          });
        }
      } else {
        print('API error: ${response.statusCode}, ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching doctor rating: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: appTheme.whiteA700,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTheme.lightGrey, width: 1),
          boxShadow: [
            BoxShadow(
              color: appTheme.lightGrey.withAlpha((0.6 * 255).toInt()),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto dokter
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: appTheme.lightGrey,
                  image: widget.doctor['foto_dokter'] != null
                      ? DecorationImage(
                          image: NetworkImage('${widget.doctor['foto_dokter']}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.doctor['foto_dokter'] == null
                    ? Center(
                        child: Icon(Icons.person, size: 50, color: appTheme.black900),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Informasi dokter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama dokter
                    Text(
                      '${widget.doctor['nama_dokter']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Pengalaman
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: appTheme.whiteA700,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '± 5 Tahun Pengalaman',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.star_rate_rounded, color: appTheme.orange200, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          isLoading
                              ? 'Loading...'
                              : reviewCount > 0
                              ? '${averageRating.toStringAsFixed(1)} Review ($reviewCount)'
                              : 'No reviews yet',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}