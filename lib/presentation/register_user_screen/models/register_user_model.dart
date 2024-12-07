import 'package:equatable/equatable.dart';

/// This class defines the variables used in the [register_user_screen],
/// and is typically used to hold data that is passed between different parts of the application.
class RegisterUserModel extends Equatable {
  const RegisterUserModel();

  RegisterUserModel copyWith() {
    return const RegisterUserModel();
  }

  @override
  List<Object?> get props => [];
}
