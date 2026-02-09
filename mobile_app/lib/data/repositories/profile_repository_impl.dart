import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/skin_profile.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    try {
      final profile = await remoteDataSource.getProfile();
      return Right(profile);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get profile', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({String? name, String? gender, String? dateOfBirth, String? timezone}) async {
    try {
      final profile = await remoteDataSource.updateProfile(name: name, gender: gender, dateOfBirth: dateOfBirth, timezone: timezone);
      return Right(profile);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to update profile', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SkinProfile>> getSkinProfile() async {
    try {
      final profile = await remoteDataSource.getSkinProfile();
      return Right(profile);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get skin profile', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SkinProfile>> updateSkinProfile({String? skinType, List<String>? concerns, String? memo}) async {
    try {
      final profile = await remoteDataSource.updateSkinProfile(skinType: skinType, concerns: concerns, memo: memo);
      return Right(profile);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to update skin profile', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings() async {
    try {
      final settings = await remoteDataSource.getNotificationSettings();
      return Right(settings);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get notification settings', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    bool? pushEnabled, bool? emailEnabled, bool? usageReminder, String? reminderTime, bool? marketingEnabled,
  }) async {
    try {
      final settings = await remoteDataSource.updateNotificationSettings(
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        usageReminder: usageReminder,
        reminderTime: reminderTime,
        marketingEnabled: marketingEnabled,
      );
      return Right(settings);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to update notification settings', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
