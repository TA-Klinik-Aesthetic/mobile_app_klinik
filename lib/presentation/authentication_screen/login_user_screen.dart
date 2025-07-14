import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_klinik/core/services/fcm_service.dart';
import 'package:mobile_app_klinik/core/widgets/language_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_outlined_button.dart';
import '../home_screen/home_screen.dart';

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  LoginUserScreenState createState() => LoginUserScreenState();
}

class LoginUserScreenState extends State<LoginUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoading = false;
  String appVersion = "Loading...";
  
  // Add this key to force rebuild
  Key _rebuildKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  // Method to force rebuild the entire widget
  void _forceRebuild() {
    print('🔄 Force rebuilding login screen...');
    if (mounted) {
      setState(() {
        _rebuildKey = UniqueKey();
      });
    }
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appVersion = "${packageInfo.version}${packageInfo.buildNumber.isNotEmpty ? '+${packageInfo.buildNumber}' : ''}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          appVersion = "0.0.0";
        });
      }
    }
  }

  Future<void> _loginUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });

    try {
      print('Attempting login with email: $email');
      
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['user']['role'] != "pelanggan") {
          if (mounted) {
            toastification.show(
              context: context,
              title: Text('msg_access_denied'.tr, style: const TextStyle(color: Colors.white)),
              description: Text('msg_customer_only'.tr, style: const TextStyle(color: Colors.white)),
              autoCloseDuration: const Duration(seconds: 3),
              backgroundColor: appTheme.lightYellow.withAlpha((0.8 * 255).toInt()),
              style: ToastificationStyle.flat,
              borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
            );
          }
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_user', responseData['user']['id_user']);
        await prefs.setString('nama_user', responseData['user']['nama_user']);
        await prefs.setString('no_telp', responseData['user']['no_telp']);
        await prefs.setString('email', responseData['user']['email']);
        await prefs.setString('role', responseData['user']['role']);
        await prefs.setString('token', responseData['token']);

        _registerFCMInBackground();

        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_success'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(
              'msg_login_success'.tr.replaceFirst('{name}', responseData['user']['nama_user']),
              style: const TextStyle(color: Colors.white),
            ),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: Icon(Icons.check_circle, color: appTheme.whiteA700),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'msg_login_failed'.tr;
        
        if (response.statusCode == 403) {
          errorMessage = errorData['message'] ?? 'msg_account_not_verified'.tr;
        } else if (response.statusCode == 401) {
          errorMessage = errorData['message'] ?? 'msg_invalid_credentials'.tr;
        } else if (response.statusCode == 422) {
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
          }
        } else {
          errorMessage = errorData['message'] ?? 'msg_login_failed'.tr;
        }

        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_login_failed'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            autoCloseDuration: const Duration(seconds: 5),
            backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: Icon(Icons.block, color: appTheme.whiteA700),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      print('Login error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${'msg_something_wrong'.tr}: $e")),
        );
      }
    }
  }

  void _registerFCMInBackground() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await FCMService.registerTokenAfterLogin();
        print('FCM token registered successfully after login');
      } catch (fcmError) {
        print('Failed to register FCM token: $fcmError');
      }
    });
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
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 120),
                      buildLoginForm(),
                      const SizedBox(height: 120),
                      Text(
                        "v$appVersion © 2024",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        "Copyright By NESH Navya",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                  print('🔄 Language changed callback triggered in login');
                  _forceRebuild(); // Force complete rebuild
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoginForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
          decoration: BoxDecoration(
            color: appTheme.whiteA700.withAlpha((0.6 * 255).toInt()),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Column(
            children: [
              // Logo centered (no language selector here)
              buildLogo(),
              
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_email".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              buildEmailInput(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_password".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              buildPasswordInput(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("msg_forgot_password".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildLoginButton(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("msg_don_t_have_an_account".tr, style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.registerUserScreen);
                    },
                    child: Text(
                      "lbl_register".tr,
                      style: TextStyle(
                        color: appTheme.orange400,
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

  Widget buildLogo() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/login_illustration_app.svg',
          height: 150,
          width: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
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

  Widget buildLoginButton() {
    return CustomOutlinedButton(
      text: "lbl_login".tr,
      onPressed: isLoading ? null : _loginUser,
    );
  }

  Widget buildEmailInput() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "msg_enter_your_email".tr,
      textInputType: TextInputType.emailAddress,
      validator: (value) {
        final trimmedValue = value?.trim();
        if (trimmedValue == null || trimmedValue.isEmpty) {
          return "msg_email_required".tr;
        }
        if (!isValidEmail(trimmedValue)) {
          return "msg_email_invalid".tr;
        }
        return null;
      },
    );
  }

  Widget buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "lbl_enter_your_password".tr,
      obscureText: _obscurePassword,
      suffix: GestureDetector(
        onTap: () {
          SchedulerBinding.instance.addPostFrameCallback((_) {
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
        if (value == null || value.trim().length < 8) {
          return "msg_password_must_be_8_characters".tr;
        }
        return null;
      },
    );
  }
}