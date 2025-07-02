import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/api/api_constant.dart';
import 'package:mobile_app_klinik/theme/theme_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintScreen extends StatefulWidget {
  final int bookingId;
  final List<dynamic> treatments;

  const ComplaintScreen({
    Key? key,
    required this.bookingId,
    required this.treatments,
  }) : super(key: key);

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final TextEditingController _complaintController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _selectedTreatment;
  List<File> _images = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedTreatment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih treatment terlebih dahulu')),
      );
      return;
    }

    if (_complaintController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi komplain terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');
      final int? userId = prefs.getInt('id_user');

      if (token == null || userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/komplain'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields['id_user'] = userId.toString();
      request.fields['id_booking_treatment'] = widget.bookingId.toString();
      request.fields['id_detail_booking_treatment'] = _selectedTreatment!['id_detail_booking_treatment'].toString();
      request.fields['teks_komplain'] = _complaintController.text;

      // Add image files
      for (var i = 0; i < _images.length; i++) {
        final file = await http.MultipartFile.fromPath(
          'gambar_komplain[]',
          _images[i].path,
        );
        request.files.add(file);
      }

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komplain berhasil dikirim')),
        );
        Navigator.pop(context);
      } else {
        var errorData = json.decode(responseString);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Gagal mengirim komplain')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layanan Komplain',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treatment selection section
            Text(
              'Pilih Treatment yang ingin dikomplain:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 12),

            // Treatment list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.treatments.length,
              itemBuilder: (context, index) {
                final treatment = widget.treatments[index];
                final isSelected = _selectedTreatment == treatment;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isSelected ? appTheme.orange200 : appTheme.lightGrey,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTreatment = treatment;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Radio<Map<String, dynamic>>(
                            value: treatment,
                            groupValue: _selectedTreatment,
                            activeColor: appTheme.orange200,
                            onChanged: (value) {
                              setState(() {
                                _selectedTreatment = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              treatment['treatment']['nama_treatment'] ?? 'Unknown Treatment',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Complaint text input
            Text(
              'Apa ada kesalahan selama atau setelah melakukan Treatment?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _complaintController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ceritakan masalah yang Anda alami...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appTheme.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appTheme.orange200),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Photo upload section
            Text(
              'Kirimkan foto pendukung',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: appTheme.black900,
              ),
            ),
            const SizedBox(height: 12),

            // Photo grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length + 1, // +1 for the add button
              itemBuilder: (context, index) {
                if (index == _images.length) {
                  // Add image button
                  return InkWell(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: appTheme.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: appTheme.orange200,
                      ),
                    ),
                  );
                } else {
                  // Image preview
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: appTheme.whiteA700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme.orange200,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Kirim Komplain',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}