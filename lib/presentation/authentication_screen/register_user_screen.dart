import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_klinik/core/widgets/language_selector.dart';
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
  
  // Add this key to force rebuild
  Key _rebuildKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    print('Register screen initialized');
  }

  // Method to force rebuild the entire widget
  void _forceRebuild() {
    print('🔄 Force rebuilding register screen...');
    if (mounted) {
      setState(() {
        _rebuildKey = UniqueKey();
      });
    }
  }

  // Keep all existing methods (_registerUser, _clearForm, _getFieldDisplayName) unchanged
  Future<void> _registerUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      print('Form validation failed');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });

    final email = _emailController.text.trim();
    final namaUser = _usernameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final tanggalLahir = _tanggalLahirController.text.trim();

    try {
      final requestBody = {
        'nama_user': namaUser,
        'no_telp': phone,
        'email': email,
        'password': password,
        'password_confirmation': _retypePasswordController.text.trim(),
      };

      if (tanggalLahir.isNotEmpty) {
        requestBody['tanggal_lahir'] = tanggalLahir;
      }
      
      if (_selectedJenisKelamin != null && _selectedJenisKelamin!.isNotEmpty) {
        requestBody['jenis_kelamin'] = _selectedJenisKelamin!;
      }

      print('Register request body: $requestBody');
      print('Register URL: ${ApiConstants.register}');

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (response.statusCode == 201) { 
        final responseData = jsonDecode(response.body);
        final user = responseData['user'];
        final status = responseData['status'];
        
        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_registration_successful'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(
              "${'msg_welcome_user'.tr.replaceFirst('{name}', user['nama_user'])}!\n${responseData['message']}\n${'lbl_status'.tr}: $status",
              style: const TextStyle(color: Colors.white),
            ),
            autoCloseDuration: const Duration(seconds: 6),
            backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: const Icon(Icons.check_circle, color: Colors.white),
          );
          
          _clearForm();
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.loginUserScreen);
            }
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'msg_registration_failed'.tr;
        
        if (response.statusCode == 422) {
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];
            
            errors.forEach((field, messages) {
              String fieldName = _getFieldDisplayName(field);
              if (messages is List) {
                for (String message in messages.cast<String>()) {
                  errorMessages.add('$fieldName: $message');
                }
              } else {
                errorMessages.add('$fieldName: ${messages.toString()}');
              }
            });
            
            errorMessage = errorMessages.join('\n');
          }
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }

        print('Registration error: $errorMessage');

        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_registration_failed'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            autoCloseDuration: const Duration(seconds: 7),
            backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      
      print('Register error: $e');
      
      if (mounted) {
        String errorMessage = "msg_registration_failed".tr;
        
        if (e.toString().contains('timeout')) {
          errorMessage = "msg_request_timeout".tr;
        } else if (e.toString().contains('SocketException')) {
          errorMessage = "msg_network_error".tr;
        } else if (e.toString().contains('FormatException')) {
          errorMessage = "msg_invalid_response".tr;
        } else {
          errorMessage = "${'msg_unexpected_error'.tr}: ${e.toString()}";
        }
        
        toastification.show(
          context: context,
          title: Text('lbl_error'.tr, style: const TextStyle(color: Colors.white)),
          description: Text(errorMessage, style: const TextStyle(color: Colors.white)),
          autoCloseDuration: const Duration(seconds: 5),
          backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    }
  }

  void _clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _retypePasswordController.clear();
    _tanggalLahirController.clear();
    if (mounted) {
      setState(() {
        _selectedJenisKelamin = null;
      });
    }
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'nama_user':
        return 'lbl_username'.tr;
      case 'no_telp':
        return 'lbl_phone_number'.tr;
      case 'email':
        return 'lbl_email'.tr;
      case 'password':
        return 'lbl_password'.tr;
      case 'password_confirmation':
        return 'lbl_confirm_password'.tr;
      case 'tanggal_lahir':
        return 'lbl_tanggal_lahir'.tr;
      case 'jenis_kelamin':
        return 'lbl_jenis_kelamin'.tr;
      default:
        return field;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: _rebuildKey, // Force rebuild key
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
            // Language Selector positioned manually
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: LanguageSelector(
                showAsButton: true,
                onLanguageChanged: () {
                  print('🔄 Language changed callback triggered in register');
                  _forceRebuild(); // Force complete rebuild
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                text: "msg_welcome_to".tr,
                style: CustomTextStyles.headlineSmallMedium,
              ),
              TextSpan(
                text: " Navya Hub",
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
              // Logo centered (no language selector here)
              _buildLogo(),
              SizedBox(height: 24.h),
              
              // Username Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_username".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildUsernameInput(),
              SizedBox(height: 16.h),
              
              // Phone Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_phone_number".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildPhoneInput(),
              SizedBox(height: 16.h),
              
              // Email Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_email".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildEmailInput(),
              SizedBox(height: 16.h),
              
              // Tanggal Lahir
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_tanggal_lahir".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildTanggalLahirInput(),
              SizedBox(height: 16.h),
              
              // Jenis Kelamin
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_jenis_kelamin".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildJenisKelaminDropdown(),
              SizedBox(height: 16.h),
              
              // Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_password".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              _buildPasswordInput(),
              SizedBox(height: 16.h),
              
              // Confirm Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_confirm_password".tr, style: theme.textTheme.bodySmall),
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
                  Text("msg_already_have_an".tr, style: theme.textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.loginUserScreen);
                    },
                    child: Text(
                      "lbl_login".tr,
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

  // Keep all existing input building methods unchanged but with translations
  Widget _buildUsernameInput() {
    return CustomTextFormField(
      controller: _usernameController,
      hintText: "lbl_enter_your_username".tr,
      textInputType: TextInputType.name,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "msg_username_required".tr;
        }
        if (value.trim().length > 255) {
          return "msg_username_max_255".tr;
        }
        return null;
      },
    );
  }

  Widget _buildPhoneInput() {
    return CustomTextFormField(
      controller: _phoneController,
      hintText: "lbl_hint_phonum".tr,
      textInputType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "msg_phone_required".tr;
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "lbl_enter_the_email".tr,
      textInputType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "msg_email_required_register".tr;
        }
        if (!isValidEmail(value.trim())) {
          return "msg_email_valid".tr;
        }
        return null;
      },
    );
  }

  Widget _buildTanggalLahirInput() {
    return CustomTextFormField(
      controller: _tanggalLahirController,
      hintText: "YYYY-MM-DD",
      textInputType: TextInputType.datetime,
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
          if (!dateRegex.hasMatch(value.trim())) {
            return "msg_date_format".tr;
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
        color: appTheme.whiteA700.withOpacity(0.6),
        border: Border.all(color: appTheme.black900, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJenisKelamin,
          hint: Text("lbl_pilih_jenis_kelamin".tr),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          onChanged: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedJenisKelamin = value;
                });
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "msg_enter_the_password".tr,
      textInputType: TextInputType.visiblePassword,
      obscureText: _obscurePassword,
      suffix: GestureDetector(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            }
          });
        },
        child: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 8) {
          return "msg_password_min_8".tr;
        }
        return null;
      },
    );
  }

  Widget _buildRetypePasswordInput() {
    return CustomTextFormField(
      controller: _retypePasswordController,
      hintText: "lbl_enter_confirm_password".tr,
      obscureText: _obscureRetypePassword,
      suffix: GestureDetector(
        onTap: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _obscureRetypePassword = !_obscureRetypePassword;
              });
            }
          });
        },
        child: Icon(
          _obscureRetypePassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
      ),
      validator: (value) {
        if (value != _passwordController.text) {
          return "msg_passwords_not_match".tr;
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomOutlinedButton(
        text: isLoading ? "lbl_creating_account".tr : "lbl_register".tr,
        onPressed: isLoading ? null : _registerUser,
      ),
    );
  }
}