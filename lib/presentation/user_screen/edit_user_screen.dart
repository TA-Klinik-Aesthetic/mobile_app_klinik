import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_constant.dart';
import '../../theme/theme_helper.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _profileImageUrl;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      // For debugging purposes
      if (kDebugMode) {
        print('Fetching profile with token: ${token.substring(0, min(10, token.length))}...');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Debug response
      if (kDebugMode) {
        print('Profile API Response Status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Profile API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Debug data after decoding
        if (kDebugMode) {
          print('Decoded data: $data');
        }

        // Check if data is inside a nested structure
        final userData = data is Map && data.containsKey('data') ? data['data'] : data;

        setState(() {
          _nameController.text = userData['nama_user'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['no_telp'] ?? '';
          _profileImageUrl = userData['foto_profil'];

          // Handle date format conversion if needed
          if (userData['tanggal_lahir'] != null && userData['tanggal_lahir'].toString().isNotEmpty) {
            try {
              // Try parsing with different formats if the date is not in the expected format
              final DateTime date = DateTime.parse(userData['tanggal_lahir']);
              _birthDateController.text = DateFormat('dd/MM/yyyy').format(date);
            } catch (e) {
              if (kDebugMode) {
                print('Error formatting date: $e');
              }
              _birthDateController.text = userData['tanggal_lahir'] ?? '';
            }
          }

          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token might be expired or invalid
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Sesi Anda telah berakhir. Silakan login kembali.');

          // Clear token and navigate to login
          await prefs.remove('token');
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Gagal memuat data profil: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isSaving = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama_user': _nameController.text,
          'email': _emailController.text,
          'no_telp': _phoneController.text,
          'tanggal_lahir': _birthDateController.text,
        }),
      );
      
      setState(() => _isSaving = false);
      
      if (response.statusCode == 200) {
        jsonDecode(response.body);
        
        // Update stored user data
        await prefs.setString('nama_user', _nameController.text);
        await prefs.setString('email', _emailController.text);
        await prefs.setString('no_telp', _phoneController.text);
        
        if (mounted) {
          _showSuccessSnackbar('Profil berhasil diperbarui');
          Navigator.pop(context);
        }
      } else {
        _showErrorSnackbar('Gagal memperbarui profil');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appTheme.darkCherry,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appTheme.lightGreen,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDateController.text.isNotEmpty
          ? DateFormat('dd/MM/yyyy').parse(_birthDateController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Enter Image URL'),
              onTap: () {
                Navigator.pop(context);
                _enterImageUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() => _isLoading = true);

        // Create multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/upload-profile-image'),
        );

        // Get token for authorization
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        // Add authorization header
        request.headers['Authorization'] = 'Bearer $token';

        // Add file to request
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          pickedFile.path,
        ));

        // Send request
        final response = await request.send();

        // Process response
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final data = jsonDecode(responseData);

          setState(() {
            _profileImageUrl = data['url'];
            _isLoading = false;
          });

          _showSuccessSnackbar('Profile image updated successfully');
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Failed to upload image');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error picking image: $e');
    }
  }

  void _enterImageUrl() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'https://...'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (urlController.text.isNotEmpty) {
                Navigator.pop(context);

                setState(() => _isLoading = true);

                try {
                  // Validate URL by attempting to load it
                  final response = await http.head(Uri.parse(urlController.text));

                  if (response.statusCode == 200) {
                    setState(() {
                      _profileImageUrl = urlController.text;
                      _isLoading = false;
                    });

                    // Save profile image URL to backend
                    _updateProfileImageUrl();
                  } else {
                    setState(() => _isLoading = false);
                    _showErrorSnackbar('Invalid image URL');
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  _showErrorSnackbar('Error loading image: $e');
                }
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfileImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/update-profile-image'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image_url': _profileImageUrl,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Profile image updated successfully');
      } else {
        _showErrorSnackbar('Failed to update profile image');
      }
    } catch (e) {
      _showErrorSnackbar('Error updating profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Profile',
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Photo
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                  ? DecorationImage(
                                image: NetworkImage(_profileImageUrl!),
                                fit: BoxFit.cover,
                                onError: (_, __) => const AssetImage('assets/images/profile_placeholder.png'),
                              )
                                  : const DecorationImage(
                                image: AssetImage('assets/images/profile_placeholder.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _selectImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: appTheme.orange200,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: appTheme.whiteA700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Name Input
                      _buildInputLabel('Name'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          hintText: 'Enter your name',
                          suffixIcon: Icons.edit,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Email Input
                      _buildInputLabel('Email'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hintText: 'Enter your email',
                          suffixIcon: Icons.email_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone Number Input
                      _buildInputLabel('Phone Number'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hintText: 'Enter your phone number',
                          prefixText: '+62 ',
                          suffixIcon: Icons.phone_callback,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth Input
                      _buildInputLabel('Date of Birth'),
                      InkWell(
                        onTap: _selectDate,
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _birthDateController,
                            decoration: _inputDecoration(
                              hintText: 'DD/MM/YYYY',
                              suffixIcon: Icons.calendar_month,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.lightGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appTheme.lightGreenOld,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? prefixText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF8A44C), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
