import 'package:flutter/material.dart';
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

  void _registerUser(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final nama_user = _usernameController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;

    setState(() {
      isLoading = true;
    });

    final response = await http.post(
      Uri.parse('https://127.0.0.1:8000/api/register'), // Sesuaikan endpoint backend
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nama_user': nama_user,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Successful: ${responseData['message']}")),
      );
      Navigator.pushNamed(context, AppRoutes.loginUserScreen);
    } else {
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed: ${errorData['errors']}")),
      );
    }
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
        if (value == null || value.length < 6) {
          return "Password must be at least 6 characters.";
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
      onPressed: () => _registerUser(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmailInput(),
                  const SizedBox(height: 16),
                  _buildPasswordInput(),
                  const SizedBox(height: 16),
                  _buildRetypePasswordInput(),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildRegisterButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
