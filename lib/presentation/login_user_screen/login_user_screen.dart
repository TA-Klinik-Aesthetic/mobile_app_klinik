import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            title: const Text('Akses Ditolak'),
            description: const Text("Login hanya dengan akun pelanggan"),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.darkCherry,
            icon: const Icon(Icons.block, color: Colors.white),
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

        toastification.show(
          context: context,
          title: const Text('Success!'),
          description: Text("Login successful! Welcome, ${responseData['user']['nama_user']}"),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.lightGreen,
          icon: const Icon(Icons.check_circle, color: Colors.white),
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
          title: const Text('Login Failed'),
          description: Text(errorMessage),
          autoCloseDuration: const Duration(seconds: 3),
          backgroundColor: appTheme.darkCherry,
          icon: const Icon(Icons.error, color: Colors.white),
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

  Widget buildLoginButton() {
    return CustomOutlinedButton(
      text: "btn_login".tr,
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
      hintText: "lbl_enter_your_email".tr,
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
          return "msg_password_must_be_8".tr;
        }
        return null;
      },
    );
  }
}
