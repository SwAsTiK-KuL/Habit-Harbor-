import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_request.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final LoginRequest request;

  const LoginRequested(this.request);

  @override
  List<Object> get props => [request];
}

class RegisterRequested extends AuthEvent {
  final RegisterRequest request;

  const RegisterRequested(this.request);

  @override
  List<Object> get props => [request];
}

class LogoutRequested extends AuthEvent {}

class GetProfileRequested extends AuthEvent {}

class AuthErrorCleared extends AuthEvent {}
