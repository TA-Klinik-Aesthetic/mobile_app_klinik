part of 'register_user_notifier.dart';

/// Represents the state of RegisterUser in the application.

// ignore_for_file: must_be_immutable
class RegisterUserState extends Equatable {
  RegisterUserState(
      {this.emailInputController,
      this.phoneNumberController,
      this.passwordInputController,
      this.retypePasswordInputController,
      this.selectedCountry,
      this.registerUserModelObj});

  TextEditingController? emailInputController;

  TextEditingController? phoneNumberController;

  TextEditingController? passwordInputController;

  TextEditingController? retypePasswordInputController;

  RegisterUserModel? registerUserModelObj;

  Country? selectedCountry;

  @override
  List<Object?> get props => [
        emailInputController,
        phoneNumberController,
        passwordInputController,
        retypePasswordInputController,
        selectedCountry,
        registerUserModelObj
      ];
  RegisterUserState copyWith({
    TextEditingController? emailInputController,
    TextEditingController? phoneNumberController,
    TextEditingController? passwordInputController,
    TextEditingController? retypePasswordInputController,
    Country? selectedCountry,
    RegisterUserModel? registerUserModelObj,
  }) {
    return RegisterUserState(
      emailInputController: emailInputController ?? this.emailInputController,
      phoneNumberController:
          phoneNumberController ?? this.phoneNumberController,
      passwordInputController:
          passwordInputController ?? this.passwordInputController,
      retypePasswordInputController:
          retypePasswordInputController ?? this.retypePasswordInputController,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      registerUserModelObj: registerUserModelObj ?? this.registerUserModelObj,
    );
  }
}
