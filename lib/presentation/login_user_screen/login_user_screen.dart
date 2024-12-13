import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  bool isLoading = false;

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

        // Simpan data pengguna ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_user', responseData['user']['id_user']);
        await prefs.setString('nama_user', responseData['user']['nama_user']);
        await prefs.setString('no_telp', responseData['user']['no_telp']);
        await prefs.setString('email', responseData['user']['email']);
        await prefs.setString('role', responseData['user']['role']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful! Welcome, ${responseData['user']['nama_user']}")),
        );

        // Navigasi ke halaman Home
        Navigator.pushReplacementNamed(context, '/homeScreen');
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: $errorMessage")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 120),
                  _buildLoginForm(),
                  const SizedBox(height: 150),
                  Text(
                    "v0.0.0 Beta © 2024",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 34),
      decoration: BoxDecoration(
        color: appTheme.lightBadge100,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "Enter your email",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          _buildEmailInput(),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "Enter your password",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          _buildPasswordInput(),
          const SizedBox(height: 48),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildLoginButton(),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ Text(
                "msg_don_t_have_an_account".tr,
                style: theme.textTheme.bodyMedium,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.registerUserScreen);
                },
                child: Text(
                  "lbl_register".tr,
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
    );
  }

  Widget _buildLoginButton() {
    return CustomOutlinedButton(
      text: "Login",
      onPressed: _loginUser,
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/logo_navya_hub.svg',
          height: 80,
          width: 80,
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

  Widget _buildEmailInput() {
    return CustomTextFormField(
      controller: _emailController,
      hintText: "Enter your email",
      textInputType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || !isValidEmail(value, isRequired: true)) {
          return "Please enter a valid email.";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "Enter your password",
      obscureText: true,
      validator: (value) {
        if (value == null || value.length < 8) {
          return "Password must be at least 8 characters.";
        }
        return null;
      },
    );
  }
}
