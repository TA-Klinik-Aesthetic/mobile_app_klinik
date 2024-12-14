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
  bool isLoading = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      return;
    }

    final email = _emailController.text;
    final namaUser = _usernameController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nama_user': namaUser,
          'no_telp': phone,
          'email': email,
          'password': password,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 201) { 
        final responseData = jsonDecode(response.body);
        toastification.show(
          context: context,
          title: const Text('Registration Successful'),
          description: Text("${responseData['message']}"),
          autoCloseDuration: const Duration(seconds: 3), // Toast otomatis tertutup
          backgroundColor: appTheme.lightGreen, // Warna hijau untuk sukses
          icon: const Icon(Icons.check_circle, color: Colors.white), // Ikon sukses
        );
        Navigator.pushNamed(context, AppRoutes.loginUserScreen);
      } else {
        final errorData = jsonDecode(response.body);
        toastification.show(
          context: context,
          title: const Text('Registration Failed'),
          description: Text("${errorData['errors'] ?? 'Unknown error'}"),
          autoCloseDuration: const Duration(seconds: 3), // Toast otomatis tertutup
          backgroundColor: appTheme.darkCherry, // Warna merah untuk error
          icon: const Icon(Icons.error, color: Colors.white), // Ikon error
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
                "lbl_username".tr,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          CustomTextFormField(
            controller: _usernameController,
            hintText: "User Name",
            textInputType: TextInputType.name,
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "lbl_phone_number".tr,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          CustomTextFormField(
            controller: _phoneController,
            hintText: "08** **** ****",
            textInputType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),
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
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                "msg_re_type_password".tr,
                style: theme.textTheme.bodySmall,
              ),
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
              const Text("Already have an account? "),
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
                SizedBox(height: 24.h),
                _buildRegisterForm(),
                SizedBox(height: 36.h),
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

  Widget _buildRetypePasswordInput() {
    return CustomTextFormField(
      controller: _retypePasswordController,
      hintText: "Re-type your password",
      obscureText: true,
      validator: (value) {
        if (value != _passwordController.text) {
          return "Passwords do not match.";
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return CustomOutlinedButton(
      text: "Register",
      onPressed: _registerUser,
    );
  }
}
