import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_klinik/core/services/fcm_service.dart';
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

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = "${packageInfo.version}${packageInfo.buildNumber.isNotEmpty ? '+${packageInfo.buildNumber}' : ''}";
      });
    } catch (e) {
      setState(() {
        appVersion = "0.0.0";
      });
    }
  }

  Future<void> _loginUser() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Check if user role is "pelanggan"
        if (responseData['user']['role'] != "pelanggan") {
          toastification.show(
            context: context,
            title: const Text(
              'Akses Ditolak',
              style: TextStyle(color: Colors.white),),
            description: const Text(
              "Login hanya dengan akun pelanggan",
              style: TextStyle(color: Colors.white),),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.lightYellow.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
          );
          return;
        }

        final prefs = await SharedPreferences.getInstance();

        await prefs.setInt('id_user', responseData['user']['id_user']);
        await prefs.setString('nama_user', responseData['user']['nama_user']);
        await prefs.setString('no_telp', responseData['user']['no_telp']);
        await prefs.setString('email', responseData['user']['email']);
        await prefs.setString('role', responseData['user']['role']);
        await prefs.setString('token', responseData['token']);

        // Register FCM token after successful login
        try {
          await FCMService.registerTokenAfterLogin();
          print('FCM token registered successfully after login');
        } catch (fcmError) {
          print('Failed to register FCM token: $fcmError');
          // Don't fail the login process if FCM registration fails
        }

        toastification.show(
          context: context,
          title: const Text(
            'Success!',
            style: TextStyle(color: Colors.white),),
          description: Text(
            "Login successful! Welcome, ${responseData['user']['nama_user']}",
            style: const TextStyle(color: Colors.white),),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: Icon(Icons.check_circle, color: appTheme.whiteA700),
        );

        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Login failed.';

        toastification.show(
          context: context,
          title: const Text('Login Failed',
            style: TextStyle(color: Colors.white),),
          description: Text(errorMessage,
            style: const TextStyle(color: Colors.white),),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
          style: ToastificationStyle.flat,
          borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
          icon: Icon(Icons.block, color: appTheme.whiteA700),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
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
              buildLogo(),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Email", style: theme.textTheme.bodySmall),
                ),
              ),
              buildEmailInput(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("lbl_password".tr(context), style: theme.textTheme.bodySmall),
                ),
              ),
              buildPasswordInput(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("msg_forgot_password".tr(context), style: theme.textTheme.bodySmall),
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
                  Text("msg_don_t_have_an_account".tr(context), style: theme.textTheme.bodyMedium),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.registerUserScreen);
                    },
                    child: Text(
                      "lbl_register".tr(context),
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

  Widget buildLoginButton() {
    return CustomOutlinedButton(
      text: "btn_login".tr(context),
      onPressed: _loginUser,
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

  Widget buildEmailInput() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "lbl_enter_your_email".tr(context),
      textInputType: TextInputType.emailAddress,
      validator: (value) {
        final trimmedValue = value?.trim();
        if (trimmedValue == null || trimmedValue.isEmpty) {
          return "msg_email_required".tr(context);
        }
        if (!isValidEmail(trimmedValue)) {
          return "msg_email_invalid".tr(context);
        }
        return null;
      },
    );
  }

  Widget buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "lbl_enter_your_password".tr(context),
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
        if (value == null || value.trim().length < 8) {
          return "msg_password_must_be_8".tr(context);
        }
        return null;
      },
    );
  }
}
