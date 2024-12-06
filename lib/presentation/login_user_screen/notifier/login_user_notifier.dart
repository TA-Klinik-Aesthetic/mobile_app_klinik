import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../../core/app_export.dart';
import '../models/login_user_model.dart';
part 'login_user_state.dart';

final loginUserNotifier =
    StateNotifierProvider.autoDispose<LoginUserNotifier, LoginUserState>(
  (ref) => LoginUserNotifier(LoginUserState(
    emailtwoController: TextEditingController(),
    passwordtwoController: TextEditingController(),
  )),
);

/// A notifier that manages the state of a LoginUser according to the event that is dispatched to it.
class LoginUserNotifier extends StateNotifier<LoginUserState> {
  LoginUserNotifier(LoginUserState state) : super(state);
}
