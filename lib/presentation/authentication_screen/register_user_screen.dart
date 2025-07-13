import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toastification/toastification.dart';
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_outlined_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  RegisterUserScreenState createState() => RegisterUserScreenState();
}

class RegisterUserScreenState extends State<RegisterUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _retypePasswordController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  
  String? _selectedJenisKelamin;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRetypePassword = true;

  Future<void> _registerUser() async {
    // Fix: Logic validation yang benar
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Stop jika form tidak valid
    }

    final email = _emailController.text.trim();
    final namaUser = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final tanggalLahir = _tanggalLahirController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      // Sesuaikan dengan API Controller yang baru
      final requestBody = {
        'nama_user': namaUser,
        'no_telp': phone,
        'email': email,
        'password': password,
        'password_confirmation': _retypePasswordController.text.trim(), // Tambahkan confirmed
      };

      // Tambahkan field opsional jika diisi
      if (tanggalLahir.isNotEmpty) {
        requestBody['tanggal_lahir'] = tanggalLahir;
      }
      
      if (_selectedJenisKelamin != null) {
        requestBody['jenis_kelamin'] = _selectedJenisKelamin!;
      }

      print('Register request body: $requestBody');

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) { 
        final responseData = jsonDecode(response.body);
        
        toastification.show(
          context: context,
          title: const Text('Registration Successful', style: TextStyle(color: Colors.white)),
          description: Text(
            responseData['message'] ?? "Registrasi berhasil. Silakan cek email Anda untuk verifikasi akun.",
            style: const TextStyle(color: Colors.white),
          ),
          autoCloseDuration: const Duration(seconds: 5),
          backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
        
        Navigator.pushNamed(context, AppRoutes.loginUserScreen);
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Registration failed';
        
        // Handle validation errors dari controller
        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          
          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessages.addAll(messages.cast<String>());
            } else {
              errorMessages.add(messages.toString());
            }
          });
          
          errorMessage = errorMessages.join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        toastification.show(
          context: context,
          title: const Text('Registration Failed', style: TextStyle(color: Colors.white)),
          description: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          autoCloseDuration: const Duration(seconds: 5),
          backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      print('Register error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          height: 100.h,
          width: 100.h,
          child: SvgPicture.asset(
            'assets/images/logo_navya_hub.svg',
            height: 80.h,
            width: 80.h,
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 14.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Welcome to ",
                style: CustomTextStyles.headlineSmallMedium,
              ),
              TextSpan(
                text: "Navya Hub",
                style: CustomTextStyles.signature,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 34.h),
          decoration: BoxDecoration(
            color: appTheme.whiteA700.withOpacity(0.6),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: theme.colorScheme.primary, width: 1.h),
          ),
          child: Column(
            children: [
              _buildLogo(),
              SizedBox(height: 24.h),
              
              // Username Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Username", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildUsernameInput(),
              SizedBox(height: 16.h),
              
              // Phone Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Phone Number", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildPhoneInput(),
              SizedBox(height: 16.h),
              
              // Email Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Email", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildEmailInput(),
              SizedBox(height: 16.h),
              
              // Tanggal Lahir (Opsional)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Tanggal Lahir (Opsional)", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildTanggalLahirInput(),
              SizedBox(height: 16.h),
              
              // Jenis Kelamin (Opsional)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Jenis Kelamin (Opsional)", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildJenisKelaminDropdown(),
              SizedBox(height: 16.h),
              
              // Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Password", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildPasswordInput(),
              SizedBox(height: 16.h),
              
              // Retype Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Confirm Password", style: theme.textTheme.bodySmall),
                ),
              ),
              _buildRetypePasswordInput(),
              SizedBox(height: 48.h),
              
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildRegisterButton(),
              SizedBox(height: 16.h),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: theme.textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.loginUserScreen);
                    },
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: appTheme.orange200,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameInput() {
    return CustomTextFormField(
      controller: _usernameController,
      hintText: "Enter your username",
      textInputType: TextInputType.name,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Username is required";
        }
        if (value.trim().length > 255) {
          return "Username must be less than 255 characters";
        }
        return null;
      },
    );
  }

  Widget _buildPhoneInput() {
    return CustomTextFormField(
      controller: _phoneController,
      hintText: "08** **** ****",
      textInputType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Phone number is required";
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "Enter your email",
      textInputType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Email is required";
        }
        if (!isValidEmail(value.trim())) {
          return "Please enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _buildTanggalLahirInput() {
    return CustomTextFormField(
      controller: _tanggalLahirController,
      hintText: "YYYY-MM-DD (optional)",
      textInputType: TextInputType.datetime,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          // Basic date format validation
          final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
          if (!dateRegex.hasMatch(value.trim())) {
            return "Please enter date in YYYY-MM-DD format";
          }
        }
        return null;
      },
    );
  }

  Widget _buildJenisKelaminDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJenisKelamin,
          hint: const Text("Select gender (optional)"),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedJenisKelamin = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "Enter your password",
      textInputType: TextInputType.visiblePassword,
      obscureText: _obscurePassword,
      suffix: GestureDetector(
        onTap: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        child: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 8) {
          return "Password must be at least 8 characters";
        }
        return null;
      },
    );
  }

  Widget _buildRetypePasswordInput() {
    return CustomTextFormField(
      controller: _retypePasswordController,
      hintText: "Confirm your password",
      obscureText: _obscureRetypePassword,
      suffix: GestureDetector(
        onTap: () {
          setState(() {
            _obscureRetypePassword = !_obscureRetypePassword;
          });
        },
        child: Icon(
          _obscureRetypePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
      ),
      validator: (value) {
        if (value != _passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_auth.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 24.h),
                      _buildRegisterForm(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return CustomOutlinedButton(
      text: "Register",
      onPressed: _registerUser,
    );
  }
}
