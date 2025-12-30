import 'package:equatable/equatable.dart';

class LoginRequest extends Equatable {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class RegisterRequest extends Equatable {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final String? firstName;
  final String? lastName;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object?> get props => [
    username,
    email,
    password,
    confirmPassword,
    firstName,
    lastName,
  ];
}
