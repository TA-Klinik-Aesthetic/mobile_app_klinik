import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';

class HistoryComplaintScreen extends StatefulWidget {
  const HistoryComplaintScreen({super.key});

  @override
  State<HistoryComplaintScreen> createState() => _HistoryComplaintScreenState();
}

class _HistoryComplaintScreenState extends State<HistoryComplaintScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _complaints = [];

  @override
  void initState() {
    super.initState();
    fetchUserComplaints();
  }

  Future<void> fetchUserComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        setState(() {
          _errorMessage = 'Session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/komplain/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _complaints = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load complaints. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final formatter = DateFormat('MMM yyyy');
      return formatter.format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengajuan Komplain',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: appTheme.black900,
      ),
      body: RefreshIndicator(
        color: appTheme.orange200,
        backgroundColor: Colors.white,
        onRefresh: fetchUserComplaints,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: appTheme.orange200))
            : _errorMessage != null
            ? Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: fetchUserComplaints,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appTheme.orange200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  ),
                  // Add space to ensure it's scrollable
                  SizedBox(height: MediaQuery.of(context).size.height * 0.6),
                ],
              ),
            ),
          ),
        )
            : _complaints.isEmpty
            ? Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada komplain',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda belum pernah mengajukan komplain',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  // Add space to ensure it's scrollable
                  SizedBox(height: MediaQuery.of(context).size.height * 0.6),
                ],
              ),
            ),
          ),
        )
            : ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _complaints.length,
          separatorBuilder: (context, index) => Divider(
            height: 2,
            thickness: 2,
            color: appTheme.lightGrey,
          ),
          itemBuilder: (context, index) {
            final complaint = _complaints[index];
            final treatment = complaint['detail_booking_treatment']?['treatment'];
            final imageUrl = treatment?['gambar_treatment'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Treatment Image (circular)
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: appTheme.lightGrey.withOpacity(0.3),
                      border: Border.all(color: appTheme.lightGrey),
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        '${ApiConstants.baseUrl}/storage/$imageUrl',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.spa, size: 28, color: appTheme.lightGrey),
                      )
                          : Icon(Icons.spa, size: 28, color: appTheme.lightGrey),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Complaint details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Complaint ID, Status and Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // ID and Status in a row
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    'COMP${complaint['id_komplain']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: complaint['balasan_komplain'] != null
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: complaint['balasan_komplain'] != null
                                            ? Colors.green
                                            : Colors.orange,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      complaint['balasan_komplain'] != null ? 'Dijawab' : 'Menunggu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: complaint['balasan_komplain'] != null
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Date on the right
                            Text(
                              formatDate(complaint['created_at'] ?? ''),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Complaint text (max 2 lines)
                        Text(
                          complaint['teks_komplain'] ?? 'No description',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: appTheme.black900,
                          ),
                        ),

                        // Treatment name
                        const SizedBox(height: 8),
                        Text(
                          treatment?['nama_treatment'] ?? 'Unknown Treatment',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}