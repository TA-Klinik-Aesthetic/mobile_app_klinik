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
      final response = await http.get(
        Uri.parse('${ApiConstants.feedbackKonsultasi}?id_dokter=${widget.doctor['id_dokter']}'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final feedbackList = jsonData['data'] as List;
        
        if (feedbackList.isNotEmpty) {
          double totalRating = 0;
          for (var feedback in feedbackList) {
            totalRating += feedback['rating'];
          }
          
          setState(() {
            averageRating = totalRating / feedbackList.length;
            reviewCount = feedbackList.length;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
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
          color: appTheme.lightBadge100, 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appTheme.black900, width: 1),
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
                        fontSize: 16, 
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
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Rating
                    Row(
                      children: [
                        Icon(Icons.stars_rounded, color: appTheme.orange200, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          isLoading 
                              ? '...' 
                              : '${averageRating.toStringAsFixed(1)} Reviews ($reviewCount)',
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