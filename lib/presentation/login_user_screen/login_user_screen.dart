import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  void _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://backend-klinik-aesthetic-production.up.railway.app/api/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Successful: ${responseData['message']}")),
        );
        Navigator.pushNamed(context, AppRoutes.homeScreen); // Replace with your dashboard route.
      } else {
        try {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Failed: ${errorData['errors'] ?? 'Invalid credentials'}")),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Failed: Unexpected response format")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
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
      textInputType: TextInputType.visiblePassword,
      obscureText: true,
      validator: (value) {
        if (value == null || value.length < 8) {
          return "Password must be at least 8 characters.";
        }
        return null;
      },
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14.h,
        vertical: 34.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.lightBadge100,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 1.h,
        ),
      ),
      child: Column(
        children: [
          _buildLogo(),
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "lbl_enter_the_email".tr,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          _buildEmailInput(),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "msg_enter_the_password".tr,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          _buildPasswordInput(),
          SizedBox(height: 48.h),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 120.h),
                _buildLoginForm(),
                SizedBox(height: 150.h),
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
    );
  }

  Widget _buildLoginButton() {
    return CustomOutlinedButton(
      text: "Login",
      onPressed: _loginUser,
    );
  }
}
