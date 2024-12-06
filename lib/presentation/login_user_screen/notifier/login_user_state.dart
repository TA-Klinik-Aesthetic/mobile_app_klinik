part of 'login_user_notifier.dart';

/// Represents the state of LoginUser in the application.

// ignore_for_file: must_be_immutable
class LoginUserState extends Equatable {
  LoginUserState(
      {this.emailtwoController,
      this.passwordtwoController,
      this.loginUserModelObj});

  TextEditingController? emailtwoController;

  TextEditingController? passwordtwoController;

  LoginUserModel? loginUserModelObj;

  @override
  List<Object?> get props =>
      [emailtwoController, passwordtwoController, loginUserModelObj];
  LoginUserState copyWith({
    TextEditingController? emailtwoController,
    TextEditingController? passwordtwoController,
    LoginUserModel? loginUserModelObj,
  }) {
    return LoginUserState(
      emailtwoController: emailtwoController ?? this.emailtwoController,
      passwordtwoController:
          passwordtwoController ?? this.passwordtwoController,
      loginUserModelObj: loginUserModelObj ?? this.loginUserModelObj,
    );
  }
}
