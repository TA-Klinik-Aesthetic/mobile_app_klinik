import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toastification/toastification.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_outlined_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  final String email;
  final bool fromForgot;

  const ResetPasswordScreen({
    super.key,
    this.token,
    required this.email,
    this.fromForgot = false,
  });

  @override
  ResetPasswordScreenState createState() => ResetPasswordScreenState();
}

class ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  
  Key _rebuildKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // If token is provided (from deep link), fill it automatically
    if (widget.token != null) {
      _tokenController.text = widget.token!;
    }
  }

  void _forceRebuild() {
    print('🔄 Force rebuilding reset password screen...');
    if (mounted) {
      setState(() {
        _rebuildKey = UniqueKey();
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final token = _tokenController.text.trim();

    if (password != confirmPassword) {
      toastification.show(
        context: context,
        title: Text('Error', style: const TextStyle(color: Colors.white)),
        description: Text('Passwords do not match', style: const TextStyle(color: Colors.white)),
        autoCloseDuration: const Duration(seconds: 3),
        backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
        style: ToastificationStyle.flat,
        borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
        icon: Icon(Icons.error, color: appTheme.whiteA700),
      );
      return;
    }

    if (token.isEmpty) {
      toastification.show(
        context: context,
        title: Text('Error', style: const TextStyle(color: Colors.white)),
        description: Text('Please click the reset link in your email first', style: const TextStyle(color: Colors.white)),
        autoCloseDuration: const Duration(seconds: 5),
        backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
        style: ToastificationStyle.flat,
        borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
        icon: Icon(Icons.error, color: appTheme.whiteA700),
      );
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });

    try {
      print('Resetting password for email: ${widget.email}');
      
      final response = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'email': widget.email,
          'password': password,
          'password_confirmation': confirmPassword,
        }),
      );

      print('Reset password response status: ${response.statusCode}');
      print('Reset password response body: ${response.body}');

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (mounted) {
          toastification.show(
            context: context,
            title: Text('lbl_success'.tr, style: const TextStyle(color: Colors.white)),
            description: Text(
              responseData['message'] ?? 'Password reset successfully',
              style: const TextStyle(color: Colors.white),
            ),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: Icon(Icons.check_circle, color: appTheme.whiteA700),
          );

          // Navigate to login screen
          Future.delayed(const Duration(seconds: 1), () {
            NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginUserScreen);
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to reset password';
        
        if (response.statusCode == 422) {
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
          errorMessage = errorData['message'] ?? 'Failed to reset password';
        }

        if (mounted) {
          toastification.show(
            context: context,
            title: Text('Error', style: const TextStyle(color: Colors.white)),
            description: Text(errorMessage, style: const TextStyle(color: Colors.white)),
            autoCloseDuration: const Duration(seconds: 5),
            backgroundColor: appTheme.darkCherry.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: Icon(Icons.error, color: appTheme.whiteA700),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      print('Reset password error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _rebuildKey,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Background image with full screen coverage
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_auth.jpg',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // SafeArea only for content, not background
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            buildResetPasswordForm(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Language Selector with SafeArea
            SafeArea(
              child: Positioned(
                top: 16,
                right: 16,
                child: LanguageSelector(
                  showAsButton: true,
                  onLanguageChanged: () {
                    print('🔄 Language changed callback triggered in reset password');
                    _forceRebuild();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildResetPasswordForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
          decoration: BoxDecoration(
            color: appTheme.whiteA700.withAlpha((0.6 * 255).toInt()),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo and title
              buildHeader(),
              
              const SizedBox(height: 40),
              
              // Email Display (read-only)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Email", style: theme.textTheme.bodySmall),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Token Input (only show if coming from forgot password)
              if (widget.fromForgot) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text("Reset Token", style: theme.textTheme.bodySmall),
                  ),
                ),
                CustomTextFormField(
                  controller: _tokenController,
                  hintText: "Enter reset token from email",
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please click the reset link in your email first";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  "Please check your email and click the reset link to get the token",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              
              // New Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("New Password", style: theme.textTheme.bodySmall),
                ),
              ),
              buildPasswordInput(),
              
              const SizedBox(height: 16),
              
              // Confirm Password Input
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text("Confirm Password", style: theme.textTheme.bodySmall),
                ),
              ),
              buildConfirmPasswordInput(),
              
              const SizedBox(height: 24),
              
              // Reset Password Button
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildResetPasswordButton(),
              
              const SizedBox(height: 16),
              
              // Back to Login
              GestureDetector(
                onTap: () {
                  NavigatorService.pushNamedAndRemoveUntil(AppRoutes.loginUserScreen);
                },
                child: Text(
                  "Back to Login",
                  style: TextStyle(
                    color: appTheme.orange400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/login_illustration_app.svg',
          height: 120,
          width: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
        Text(
          "Reset Password",
          style: CustomTextStyles.headlineSmallMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.fromForgot 
              ? "Check your email for reset link"
              : "Enter your new password",
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget buildPasswordInput() {
    return CustomTextFormField(
      controller: _passwordController,
      hintText: "Enter new password",
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
          return "Password must be at least 8 characters";
        }
        return null;
      },
    );
  }

  Widget buildConfirmPasswordInput() {
    return CustomTextFormField(
      controller: _confirmPasswordController,
      hintText: "Confirm new password",
      obscureText: _obscureConfirmPassword,
      suffix: GestureDetector(
        onTap: () {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            }
          });
        },
        child: Icon(
          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().length < 8) {
          return "Password must be at least 8 characters";
        }
        return null;
      },
    );
  }

  Widget buildResetPasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomOutlinedButton(
        text: "Reset Password",
        onPressed: isLoading ? null : _resetPassword,
        backgroundColor: appTheme.orange200,
        textColor: Colors.white,
      ),
    );
  }
}