import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app_klinik/presentation/user_screen/edit_password_screen.dart';
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
  
  // ✅ Add gender dropdown
  String? _selectedGender;
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  
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
      
      if (token == null || token.isEmpty) {
        if (mounted) {
          _showErrorSnackbar('Token tidak ditemukan. Silakan login kembali.');
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
      
      if (kDebugMode) {
        print('Fetching profile with token: ${token.substring(0, min(10, token.length))}...');
        print('Using endpoint: ${ApiConstants.profile}');
      }

      // ✅ Use correct API endpoint with proper headers
      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (kDebugMode) {
        print('Profile API Response Status: ${response.statusCode}');
        print('Profile API Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (kDebugMode) {
          print('Decoded data: $data');
        }

        // ✅ Safer null checking for user data
        Map<String, dynamic>? userData;
        
        if (data is Map<String, dynamic>) {
          if (data.containsKey('user') && data['user'] != null) {
            userData = data['user'] as Map<String, dynamic>;
          } else if (data.containsKey('data') && data['data'] != null) {
            userData = data['data'] as Map<String, dynamic>;
          } else {
            // If response structure is different, treat the whole response as user data
            userData = data;
          }
        }

        if (userData != null) {
          setState(() {
            // ✅ Safe access with null checking and default values
            _nameController.text = userData!['nama_user']?.toString() ?? '';
            _emailController.text = userData['email']?.toString() ?? '';
            _phoneController.text = userData['no_telp']?.toString() ?? '';
            _selectedGender = userData['jenis_kelamin']?.toString() ?? 'Laki-laki';

            // ✅ Handle date format properly from API response
            final birthDate = userData['tanggal_lahir'];
            if (birthDate != null && birthDate.toString().isNotEmpty && birthDate.toString() != 'null') {
              try {
                // Parse the ISO date from API (e.g., "1990-05-14T16:00:00.000000Z")
                final DateTime date = DateTime.parse(birthDate.toString());
                _birthDateController.text = DateFormat('dd/MM/yyyy').format(date);
              } catch (e) {
                if (kDebugMode) {
                  print('Error formatting date: $e');
                }
                _birthDateController.text = '';
              }
            } else {
              _birthDateController.text = '';
            }

            _isLoading = false;
          });

          // ✅ Update SharedPreferences with fresh data
          await prefs.setString('nama_user', userData['nama_user']?.toString() ?? '');
          await prefs.setString('email', userData['email']?.toString() ?? '');
          await prefs.setString('no_telp', userData['no_telp']?.toString() ?? '');
          await prefs.setString('jenis_kelamin', userData['jenis_kelamin']?.toString() ?? 'Laki-laki');
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Format respons API tidak valid');
        }

      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorSnackbar('Sesi Anda telah berakhir. Silakan login kembali.');

          await prefs.remove('token');
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        setState(() => _isLoading = false);
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message'] ?? 'Gagal memuat data profil';
        _showErrorSnackbar('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      setState(() => _isLoading = false);
      _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isSaving = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        if (mounted) {
          _showErrorSnackbar('Token tidak ditemukan. Silakan login kembali.');
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      // ✅ Prepare date in correct format for API
      String? formattedDate;
      if (_birthDateController.text.isNotEmpty) {
        try {
          // Convert from DD/MM/YYYY to YYYY-MM-DD format for API
          final DateTime date = DateFormat('dd/MM/yyyy').parse(_birthDateController.text);
          formattedDate = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing date: $e');
          }
          formattedDate = null;
        }
      }
      
      // ✅ Prepare request body
      final requestBody = {
        'nama_user': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'no_telp': _phoneController.text.trim(),
        'jenis_kelamin': _selectedGender,
      };
      
      // Only add birth date if it's properly formatted
      if (formattedDate != null) {
        requestBody['tanggal_lahir'] = formattedDate;
      }

      if (kDebugMode) {
        print('Sending PUT request to: ${ApiConstants.profile}');
        print('Request body: ${jsonEncode(requestBody)}');
        print('Authorization: Bearer ${token.substring(0, min(10, token.length))}...');
      }
      
      // ✅ Use correct API endpoint and proper authorization
      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Update Profile Response Status: ${response.statusCode}');
        print('Update Profile Response Body: ${response.body}');
      }
      
      setState(() => _isSaving = false);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // ✅ Update stored user data in SharedPreferences
        await prefs.setString('nama_user', _nameController.text.trim());
        await prefs.setString('email', _emailController.text.trim());
        await prefs.setString('no_telp', _phoneController.text.trim());
        await prefs.setString('jenis_kelamin', _selectedGender ?? 'Laki-laki');
        
        if (mounted) {
          final message = responseData['message']?.toString() ?? 'Profil berhasil diperbarui';
          _showSuccessSnackbar(message);
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else if (response.statusCode == 401) {
        await prefs.remove('token');
        if (mounted) {
          _showErrorSnackbar('Sesi Anda telah berakhir. Silakan login kembali.');
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        final errorBody = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        final errorMessage = errorBody['message']?.toString() ?? 'Gagal memperbarui profil';
        _showErrorSnackbar('$errorMessage (${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving profile: $e');
      }
      setState(() => _isSaving = false);
      _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: appTheme.darkCherry,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: appTheme.lightGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    DateTime? initialDate;
    
    // ✅ Better date parsing
    if (_birthDateController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('dd/MM/yyyy').parse(_birthDateController.text);
      } catch (e) {
        initialDate = DateTime.now().subtract(const Duration(days: 365 * 25)); // Default to 25 years ago
      }
    } else {
      initialDate = DateTime.now().subtract(const Duration(days: 365 * 25));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      // ✅ Custom styling for date picker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appTheme.orange200, // Selection color
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // ✅ Custom Gender Selection Widget
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Jenis Kelamin'),
        const SizedBox(height: 8),
        Row(
          children: [
            // Laki-laki Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Laki-laki';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ✅ Reduced vertical padding
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Laki-laki' 
                        ? Colors.blue.shade500 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Laki-laki' 
                          ? Colors.blue.shade500 
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: _selectedGender == 'Laki-laki'
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row( // ✅ Changed from Column to Row
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        size: 20, // ✅ Slightly larger icon for better visibility
                        color: _selectedGender == 'Laki-laki' 
                            ? Colors.white 
                            : Colors.blue.shade400,
                      ),
                      const SizedBox(width: 8), // ✅ Horizontal spacing
                      Text(
                        'Laki-laki',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedGender == 'Laki-laki' 
                              ? Colors.white 
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Perempuan Option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Perempuan';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ✅ Reduced vertical padding
                  decoration: BoxDecoration(
                    color: _selectedGender == 'Perempuan' 
                        ? Colors.pink.shade500 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedGender == 'Perempuan' 
                          ? Colors.pink.shade500 
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: _selectedGender == 'Perempuan'
                        ? [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row( // ✅ Changed from Column to Row
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        size: 20, // ✅ Consistent icon size
                        color: _selectedGender == 'Perempuan' 
                            ? Colors.white 
                            : Colors.pink.shade400,
                      ),
                      const SizedBox(width: 8), // ✅ Horizontal spacing
                      Text(
                        'Perempuan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedGender == 'Perempuan' 
                              ? Colors.white 
                              : Colors.pink.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // ✅ Validation error display
        if (_selectedGender == null) ...[
          const SizedBox(height: 8),
          Text(
            'Pilih jenis kelamin',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: appTheme.orange200),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data profil...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Header with user avatar
                      Center(
                        child: Column(
                          children: [
                            // ✅ Avatar with gender indication
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _selectedGender == 'Perempuan'
                                      ? [Colors.pink.shade200, Colors.pink.shade400]
                                      : [Colors.blue.shade200, Colors.blue.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background circle
                                  Container(
                                    width: 85,
                                    height: 85,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  // Main icon
                                  Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  // Gender badge
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 25,
                                      height: 25,
                                      decoration: BoxDecoration(
                                        color: _selectedGender == 'Perempuan' 
                                            ? Colors.pink.shade600 
                                            : Colors.blue.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        _selectedGender == 'Perempuan' ? Icons.female : Icons.male,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // ✅ Name Input
                      _buildInputLabel('Nama Lengkap'),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          hintText: 'Masukkan nama lengkap',
                          suffixIcon: Icons.person_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama lengkap tidak boleh kosong';
                          }
                          if (value.trim().length < 2) {
                            return 'Nama minimal 2 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ Email Input
                      _buildInputLabel('Email'),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hintText: 'Masukkan alamat email',
                          suffixIcon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // ✅ Phone Number Input
                      _buildInputLabel('Nomor Telepon'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hintText: 'Masukkan nomor telepon',
                          prefixText: '+62 ',
                          suffixIcon: Icons.phone_outlined,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor telepon tidak boleh kosong';
                          }
                          if (value.trim().length < 8) {
                            return 'Nomor telepon minimal 8 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // ✅ Custom Gender Selection (Replace dropdown with custom boxes)
                      _buildGenderSelection(),
                      const SizedBox(height: 16),

                      // ✅ Date of Birth Input
                      _buildInputLabel('Tanggal Lahir'),
                      InkWell(
                        onTap: _selectDate,
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: _birthDateController,
                            decoration: _inputDecoration(
                              hintText: 'DD/MM/YYYY',
                              suffixIcon: Icons.calendar_today_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Tanggal lahir tidak boleh kosong';
                              }
                              try {
                                DateFormat('dd/MM/yyyy').parse(value.trim());
                                return null;
                              } catch (e) {
                                return 'Format tanggal tidak valid';
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // ✅ Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () {
                            // ✅ Add gender validation before saving
                            if (_selectedGender == null) {
                              setState(() {}); // Trigger rebuild to show error
                              _showErrorSnackbar('Pilih jenis kelamin terlebih dahulu');
                              return;
                            }
                            _saveProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appTheme.orange200,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Menyimpan...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'SIMPAN PERUBAHAN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: appTheme.whiteA700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ✅ Tambah link "Atau ingin Ubah Kata Sandi?"
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Atau ingin ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: _isSaving ? null : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditPasswordScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: const [
                                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Expanded(child: Text('Password berhasil diubah')),
                                        ],
                                      ),
                                      backgroundColor: appTheme.lightGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Ubah Kata Sandi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appTheme.orange200,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: appTheme.black900,
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
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: appTheme.black900,
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon != null 
          ? Icon(suffixIcon, color: Colors.grey.shade400, size: 20) 
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: appTheme.orange200, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}