import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AutoLoginRequested extends AuthEvent {
  const AutoLoginRequested();
}

class LoginWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginWithEmailRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignupWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const SignupWithEmailRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

class LoginWithAppleRequested extends AuthEvent {
  const LoginWithAppleRequested();
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ResetPasswordRequested extends AuthEvent {
  final String email;
  const ResetPasswordRequested({required this.email});
  @override
  List<Object?> get props => [email];
}
