import 'package:flutter/material.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/register_user_model.dart';
part 'register_user_state.dart';

final registerUserNotifier =
    StateNotifierProvider.autoDispose<RegisterUserNotifier, RegisterUserState>(
  (ref) => RegisterUserNotifier(RegisterUserState(
    emailInputController: TextEditingController(),
    phoneNumberController: TextEditingController(),
    passwordInputController: TextEditingController(),
    retypePasswordInputController: TextEditingController(),
    selectedCountry: CountryPickerUtils.getCountryByPhoneCode('1'),
  )),
);

/// A notifier that manages the state of a RegisterUser according to the event that is dispatched to it.
class RegisterUserNotifier extends StateNotifier<RegisterUserState> {
  RegisterUserNotifier(RegisterUserState state) : super(state);
}
