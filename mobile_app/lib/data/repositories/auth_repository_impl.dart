import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> loginWithEmail(String email, String password) async {
    try {
      final user = await remoteDataSource.loginWithEmail(email, password);
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Login failed', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signupWithEmail(String email, String password) async {
    try {
      final user = await remoteDataSource.signupWithEmail(email, password);
      return Right(user);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Signup failed', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> loginWithGoogle() async {
    try {
      final user = await remoteDataSource.loginWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> loginWithApple() async {
    try {
      final user = await remoteDataSource.loginWithApple();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> autoLogin() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      if (user == null) {
        return const Left(AuthFailure('No active session'));
      }
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Stream<AuthUser?> get authStateChanges => remoteDataSource.authStateChanges;
}
