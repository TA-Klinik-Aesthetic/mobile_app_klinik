import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_klinik/core/services/auth_service.dart';
import 'package:mobile_app_klinik/core/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_outlined_button.dart';

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
      
      // ✅ Get FCM token before login
      String? fcmToken;
      try {
        fcmToken = await FCMService.getToken();
        print('🔔 FCM Token for login: ${fcmToken?.substring(0, 50)}...');
      } catch (e) {
        print('⚠️ Failed to get FCM token for login: $e');
      }
      
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'password': password,
          'fcm_token': fcmToken, // ✅ Send FCM token to backend
        }),
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

        // ✅ Save all user data including FCM token from response
        await AuthService.saveUserData(
          token: responseData['token'],
          userId: responseData['user']['id_user'].toString(),
          userName: responseData['user']['nama_user'],
          userEmail: responseData['user']['email'],
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_user', responseData['user']['id_user']);
        await prefs.setString('nama_user', responseData['user']['nama_user']);
        await prefs.setString('no_telp', responseData['user']['no_telp'] ?? '');
        await prefs.setString('email', responseData['user']['email']);
        await prefs.setString('role', responseData['user']['role']);
        await prefs.setString('token', responseData['token']);
        
        // ✅ Save FCM token from response (if provided by backend)
        if (responseData['fcm_token'] != null) {
          await prefs.setString('fcm_token', responseData['fcm_token']);
          print('🔔 FCM token from server saved: ${responseData['fcm_token']}');
        }

        await prefs.setBool('onboarding_completed', true);
        await prefs.setBool('first_time_user', false);

        // ✅ Initialize FCM listener after login
        try {
          await FCMService.initializeNotificationListener();
          await FCMService.debugStatus();
          print('✅ FCM listeners initialized after login');
          
        } catch (e) {
          print('⚠️ Error initializing FCM after login: $e');
        }

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

          // UBAH: pakai navigator dari context, bukan NavigatorService
          Future.delayed(const Duration(milliseconds: 150), () {
            if (!mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.homeScreen,
              (route) => false,
            );
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_login_failed'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(errorData['message'] ?? 'Login failed', style: const TextStyle(color: Colors.white)),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: const Icon(Icons.error, color: Colors.white),
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        toastification.show(
          context: context,
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          description: Text('Connection error: $e', style: const TextStyle(color: Colors.white)),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            // ✅ NEW: Back to Info Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: _buildBackToInfoButton(),
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
              // Logo centered
              buildLogo(),
              
              const SizedBox(height: 40),
              
              // Email Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_email".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              buildEmailInput(),
              
              const SizedBox(height: 16),
              
              // Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_password".tr, style: theme.textTheme.bodySmall),
                ),
              ),
              buildPasswordInput(),
              
              const SizedBox(height: 8),
              
              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPasswordScreen);
                    },
                    child: Text(
                      "msg_forgot_password".tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: appTheme.orange400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Login Button
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildLoginButton(),
              
              const SizedBox(height: 16),
              
              // Register Section
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Add this method to login_user_screen.dart
  Widget _buildBackToInfoButton() {
    return SizedBox(
      width: 135.h,
      height: 35.h,
      child: OutlinedButton.icon(
        onPressed: () {
          _goToOnboarding();
        },
        icon: Icon(
          Icons.info_outline,
          size: 24,
          color: appTheme.black900,
        ),
        label: Text(
          "Back to Info",
          style: TextStyle(
            color: appTheme.black900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          side: BorderSide(
            color: appTheme.black900,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: appTheme.whiteA700.withOpacity(1),
        ),
      ),
    );
  }

  // ✅ NEW: Add this method to login_user_screen.dart
  void _goToOnboarding() {
    print('🔄 Navigating back to onboarding from login');
    // UBAH: pakai navigator dari context
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.onboardingScreen,
      (route) => false,
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
      backgroundColor: appTheme.orange200, // Add this parameter
      textColor: Colors.white, // Add this for contrast
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