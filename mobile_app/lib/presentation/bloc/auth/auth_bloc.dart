import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/auth_user.dart';
import '../../../domain/usecases/auth/login_with_email.dart';
import '../../../domain/usecases/auth/signup_with_email.dart';
import '../../../domain/usecases/auth/logout.dart';
import '../../../domain/usecases/auth/auto_login.dart';
import '../../../domain/usecases/auth/login_with_google.dart';
import '../../../domain/usecases/auth/login_with_apple.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithEmail loginWithEmail;
  final SignupWithEmail signupWithEmail;
  final Logout logout;
  final AutoLogin autoLogin;
  final LoginWithGoogle loginWithGoogle;
  final LoginWithApple loginWithApple;
  final AuthRepository authRepository;

  StreamSubscription<AuthUser?>? _authStateSubscription;

  AuthBloc({
    required this.loginWithEmail,
    required this.signupWithEmail,
    required this.logout,
    required this.autoLogin,
    required this.loginWithGoogle,
    required this.loginWithApple,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AutoLoginRequested>(_onAutoLogin);
    on<LoginWithEmailRequested>(_onLoginWithEmail);
    on<SignupWithEmailRequested>(_onSignupWithEmail);
    on<LoginWithGoogleRequested>(_onLoginWithGoogle);
    on<LoginWithAppleRequested>(_onLoginWithApple);
    on<LogoutRequested>(_onLogout);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  Future<void> _onAutoLogin(AutoLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await autoLogin(NoParams());
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLoginWithEmail(LoginWithEmailRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginWithEmail(LoginParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignupWithEmail(SignupWithEmailRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signupWithEmail(SignupParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLoginWithGoogle(LoginWithGoogleRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginWithGoogle(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLoginWithApple(LoginWithAppleRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginWithApple(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await logout(NoParams());
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  Future<void> _onResetPassword(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await authRepository.resetPassword(event.email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const PasswordResetSent()),
    );
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
