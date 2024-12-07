import 'package:flutter/material.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_pickers.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_outlined_button.dart';
import '../../widgets/custom_phone_number.dart';
import '../../widgets/custom_text_form_field.dart';
import 'notifier/register_user_notifier.dart';

class RegisterUserScreen extends ConsumerStatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  RegisterUserScreenState createState() => RegisterUserScreenState();
}

// ignore_for_file: must_be_immutable
class RegisterUserScreenState extends ConsumerState<RegisterUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.only(
                  left: 24.h,
                  top: 24.h,
                  right: 24.h,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 72.h),
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.only(
                        left: 14.h,
                        top: 32.h,
                        right: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: appTheme.lightGreen100,
                        borderRadius: BorderRadiusStyle.roundedBorder40,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 1.h,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.h),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: 80.h,
                              width: 82.h,
                              decoration: BoxDecoration(
                                color: appTheme.blueGray100,
                                borderRadius: BorderRadiusStyle.roundedBorder40,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: 6.h),
                                  Text(
                                    "lbl_logo".tr,
                                    style: theme.textTheme.titleLarge,
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Align(
                            alignment: Alignment.center,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "lbl_welcome_to".tr,
                                    style: CustomTextStyles.headlineSmallMedium,
                                  ),
                                  TextSpan(
                                    text: "lbl_navya_hub".tr,
                                    style: CustomTextStyles.signature,
                                  )
                                ],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 34.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.h),
                            child: Text(
                              "lbl_email".tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          _buildEmailInput(context),
                          SizedBox(height: 30.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.h),
                            child: Text(
                              "lbl_phone_number".tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          SizedBox(
                            width: double.maxFinite,
                            child: _buildPhoneNumber(context),
                          ),
                          SizedBox(height: 24.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.h),
                            child: Text(
                              "lbl_password".tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          _buildPasswordInput(context),
                          SizedBox(height: 24.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.h),
                            child: Text(
                              "msg_re_type_password".tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          _buildRetypePasswordInput(context),
                          SizedBox(height: 48.h),
                          _buildRegisterButton(context),
                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "msg_already_have_an".tr,
                                  style: CustomTextStyles.bodySmallBlack900,
                                ),
                                GestureDetector(
                                onTap: () {
                                  onTapTxtLogin(context);
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(left: 4.h),
                                  child: Text(
                                    "lbl_login".tr,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              )
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                    SizedBox(height: 42.h),
                    Text(
                      "msg_v0_0_0_beta_copyright".tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildEmailInput(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return CustomTextFormField(
          controller: ref.watch(registerUserNotifier).emailInputController,
          hintText: "lbl_enter_the_email".tr,
          textInputType: TextInputType.emailAddress,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 10.h,
          ),
          validator: (value) {
            if (value == null || (!isValidEmail(value, isRequired: true))) {
              return "err_msg_please_enter_valid_email".tr;
            }
            return null;
          },
        );
      },
    );
  }

  /// Section Widget
  Widget _buildPhoneNumber(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Consumer(
        builder: (context, ref, _) {
          return CustomPhoneNumber(
            country: ref.watch(registerUserNotifier).selectedCountry ??
                CountryPickerUtils.getCountryByPhoneCode('1'),
            controller: ref.watch(registerUserNotifier).phoneNumberController,
            onTap: (Country value) {
              ref.watch(registerUserNotifier).selectedCountry = value;
            },
          );
        },
      ),
    );
  }

  /// Section Widget
  Widget _buildPasswordInput(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return CustomTextFormField(
          controller: ref.watch(registerUserNotifier).passwordInputController,
          hintText: "msg_enter_the_password".tr,
          textInputType: TextInputType.visiblePassword,
          obscureText: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 10.h,
          ),
          validator: (value) {
            if (value == null || (!isValidPassword(value, isRequired: true))) {
              return "err_msg_please_enter_valid_password".tr;
            }
            return null;
          },
        );
      },
    );
  }

  /// Section Widget
  Widget _buildRetypePasswordInput(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return CustomTextFormField(
          controller:
              ref.watch(registerUserNotifier).retypePasswordInputController,
          hintText: "msg_re_type_the_password".tr,
          textInputAction: TextInputAction.done,
          textInputType: TextInputType.visiblePassword,
          obscureText: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 10.h,
          ),
          validator: (value) {
            if (value == null || (!isValidPassword(value, isRequired: true))) {
              return "err_msg_please_enter_valid_password".tr;
            }
            return null;
          },
        );
      },
    );
  }

  /// Section Widget
  Widget _buildRegisterButton(BuildContext context) {
    return CustomOutlinedButton(
      text: "lbl_register".tr,
    );
  }

  onTapTxtLogin(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.loginUserScreen,
    );
  }
}
