import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> loginWithEmail(String email, String password);
  Future<Either<Failure, AuthUser>> signupWithEmail(String email, String password);
  Future<Either<Failure, AuthUser>> loginWithGoogle();
  Future<Either<Failure, AuthUser>> loginWithApple();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthUser>> autoLogin();
  Future<Either<Failure, AuthUser?>> getCurrentUser();
  Future<Either<Failure, void>> resetPassword(String email);
  Stream<AuthUser?> get authStateChanges;
}
