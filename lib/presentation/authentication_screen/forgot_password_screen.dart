import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toastification/toastification.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api_constant.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_outlined_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;
  
  Key _rebuildKey = UniqueKey();

  void _forceRebuild() {
    print('🔄 Force rebuilding forgot password screen...');
    if (mounted) {
      setState(() {
        _rebuildKey = UniqueKey();
      });
    }
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
    });

    try {
      print('Sending reset link to email: $email');
      
      final response = await http.post(
        Uri.parse(ApiConstants.emailForgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Reset link response status: ${response.statusCode}');
      print('Reset link response body: ${response.body}');

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
              responseData['message'] ?? 'Reset link sent to your email',
              style: const TextStyle(color: Colors.white),
            ),
            autoCloseDuration: const Duration(seconds: 3),
            backgroundColor: appTheme.lightGreen.withAlpha((0.8 * 255).toInt()),
            style: ToastificationStyle.flat,
            borderSide: BorderSide(color: appTheme.whiteA700, width: 2),
            icon: Icon(Icons.check_circle, color: appTheme.whiteA700),
          );

          // ✅ Navigate directly to reset password screen with email
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.resetPasswordScreen,
              arguments: {
                'email': email,
                'from_forgot': true, // Flag to indicate coming from forgot password
              },
            );
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Failed to send reset link';
        
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
          errorMessage = errorData['message'] ?? 'Failed to send reset link';
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

      print('Reset link error: $e');
      
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
                            buildForgotPasswordForm(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: _buildBackButton(),
              ),
            ),
            // Language Selector with SafeArea
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: LanguageSelector(
                  showAsButton: true,
                  onLanguageChanged: () {
                    print('🔄 Language changed callback triggered in forgot password');
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

  Widget buildForgotPasswordForm() {
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
              buildHeader(),
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
              
              const SizedBox(height: 24),
              
              // Send Reset Link Button
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : buildSendResetLinkButton(),
              
              const SizedBox(height: 16),
              
              // Back to Login
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "lbl_back_to_login".tr,
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
          'assets/images/forgot_pass_illustration.svg',
          height: 120,
          width: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
        Text(
          "lbl_forgot_password".tr,
          style: CustomTextStyles.headlineSmallMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "msg_enter_your_email_to_receive_link".tr,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
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

  Widget buildSendResetLinkButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomOutlinedButton(
        text: "btn_send_reset_link".tr,
        onPressed: isLoading ? null : _sendResetLink,
        backgroundColor: appTheme.orange200,
        textColor: Colors.white,
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: 40.h,
      height: 40.h,
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: appTheme.black900,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: appTheme.whiteA700.withOpacity(1),
        ),
        child: Icon(
          Icons.arrow_back,
          size: 20,
          color: appTheme.black900,
        ),
      ),
    );
  }
}