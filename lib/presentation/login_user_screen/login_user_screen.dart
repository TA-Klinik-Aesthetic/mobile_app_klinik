import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/utils/validation_functions.dart';
import '../../widgets/custom_outlined_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'notifier/login_user_notifier.dart';

class LoginUserScreen extends ConsumerStatefulWidget {
  const LoginUserScreen({super.key});

  @override
  LoginUserScreenState createState() => LoginUserScreenState();
}

// ignore_for_file: must_be_immutable
class LoginUserScreenState extends ConsumerState<LoginUserScreen> {
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
                  top: 96.h,
                  right: 24.h,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 78.h),
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.h,
                        vertical: 34.h,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
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
                          SizedBox(height: 14.h),
                          RichText(
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
                          SizedBox(height: 40.h),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4.h),
                              child: Text(
                                "lbl_email".tr,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Consumer(
                            builder: (context, ref, _) {
                              return CustomTextFormField(
                                controller: ref
                                    .watch(loginUserNotifier)
                                    .emailtwoController,
                                hintText: "msg_enter_your_email".tr,
                                textInputType: TextInputType.emailAddress,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.h,
                                  vertical: 10.h,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      (!isValidEmail(value,
                                          isRequired: true))) {
                                    return "err_msg_please_enter_valid_email"
                                        .tr;
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          SizedBox(height: 24.h),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4.h),
                              child: Text(
                                "lbl_password".tr,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Consumer(
                            builder: (context, ref, _) {
                              return CustomTextFormField(
                                controller: ref
                                    .watch(loginUserNotifier)
                                    .passwordtwoController,
                                hintText: "lbl_enter_password".tr,
                                textInputAction: TextInputAction.done,
                                textInputType: TextInputType.visiblePassword,
                                obscureText: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.h,
                                  vertical: 10.h,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      (!isValidPassword(value,
                                          isRequired: true))) {
                                    return "err_msg_please_enter_valid_password"
                                      .tr;
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "msg_forgot_password".tr,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          CustomOutlinedButton(
                            text: "lbl_login".tr,
                            style: theme.textTheme.labelLarge,
                          ),
                          SizedBox(height: 18.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "msg_don_t_have_an_account".tr,
                                style: CustomTextStyles.bodySmallBlack900,
                              ),
                              GestureDetector(
                                onTap: () {
                                  onTapTxtRegisterone(context);
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(left: 4.h),
                                  child: Text(
                                    "lbl_register".tr,
                                    style: 
                                      CustomTextStyles.bodyBoldOrange,
                                      selectionColor: Colors.orange,
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 120.h),
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

  /// Navigates to the registerUserScreen when the action is triggered.
  onTapTxtRegisterone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.registerUserScreen,
    );
  }
}
