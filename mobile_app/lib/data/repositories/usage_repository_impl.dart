import 'package:dartz/dartz.dart';
import '../../domain/entities/usage_session.dart';
import '../../domain/entities/usage_statistics.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';
import '../../domain/repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/usage_local_data_source.dart';
import '../models/usage_session_model.dart';

class UsageRepositoryImpl implements UsageRepository {
  final UsageLocalDataSource localDataSource;

  UsageRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, void>> startSession(UsageSession session) async {
    try {
      final model = UsageSessionModel.fromEntity(session);
      await localDataSource.insertSession(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSession(UsageSession session) async {
    try {
      final model = UsageSessionModel.fromEntity(session);
      await localDataSource.updateSession(model);
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endSession(
      String sessionId, DateTime endTime) async {
    try {
      // TODO: Implement end session logic
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UsageSession?>> getActiveSession() async {
    try {
      final session = await localDataSource.getActiveSession();
      return Right(session);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UsageSession>>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final sessions =
          await localDataSource.getSessionsByDateRange(startDate, endDate);
      return Right(sessions);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UsageSession>>> getSessionsByDate(
      DateTime date) async {
    try {
      final sessions = await localDataSource.getSessionsByDate(date);
      return Right(sessions);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UsageStatistics>> getDailyStatistics(
      DateTime date) async {
    try {
      final sessions = await localDataSource.getSessionsByDate(date);
      final statistics = _calculateStatistics(
        sessions,
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day, 23, 59, 59),
      );
      return Right(statistics);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UsageStatistics>> getWeeklyStatistics(
      DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final sessions =
          await localDataSource.getSessionsByDateRange(weekStart, weekEnd);
      final statistics = _calculateStatistics(sessions, weekStart, weekEnd);
      return Right(statistics);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UsageStatistics>> getMonthlyStatistics(
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
      final sessions =
          await localDataSource.getSessionsByDateRange(startDate, endDate);
      final statistics = _calculateStatistics(sessions, startDate, endDate);
      return Right(statistics);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyUsage>>> getDailyUsageForWeek(
      DateTime weekStart) async {
    try {
      final dailyUsages = <DailyUsage>[];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final sessions = await localDataSource.getSessionsByDate(date);
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, session) => sum + (session.workingDurationSeconds ~/ 60),
        );

        final usageByShot = <ShotType, int>{};
        for (final session in sessions) {
          final minutes = session.workingDurationSeconds ~/ 60;
          usageByShot[session.shotType] =
              (usageByShot[session.shotType] ?? 0) + minutes;
        }

        dailyUsages.add(DailyUsage(
          date: date,
          usageMinutes: totalMinutes,
          usageByShot: usageByShot,
        ));
      }
      return Right(dailyUsages);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyUsage>>> getDailyUsageForMonth(
    int year,
    int month,
  ) async {
    try {
      final dailyUsages = <DailyUsage>[];
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final sessions = await localDataSource.getSessionsByDate(date);
        final totalMinutes = sessions.fold<int>(
          0,
          (sum, session) => sum + (session.workingDurationSeconds ~/ 60),
        );

        final usageByShot = <ShotType, int>{};
        for (final session in sessions) {
          final minutes = session.workingDurationSeconds ~/ 60;
          usageByShot[session.shotType] =
              (usageByShot[session.shotType] ?? 0) + minutes;
        }

        dailyUsages.add(DailyUsage(
          date: date,
          usageMinutes: totalMinutes,
          usageByShot: usageByShot,
        ));
      }
      return Right(dailyUsages);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllSessions() async {
    try {
      await localDataSource.deleteAllSessions();
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      await localDataSource.deleteSessionsByDateRange(startDate, endDate);
      return const Right(null);
    } on Exception catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  UsageStatistics _calculateStatistics(
    List<UsageSession> sessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    int totalMinutes = 0;
    final usageByShot = <ShotType, int>{};
    final usageByMode = <DeviceMode, int>{};
    final usageByLevel = <DeviceLevel, int>{};
    int warningCount = 0;

    for (final session in sessions) {
      final minutes = session.workingDurationSeconds ~/ 60;
      totalMinutes += minutes;

      usageByShot[session.shotType] =
          (usageByShot[session.shotType] ?? 0) + minutes;
      usageByMode[session.mode] = (usageByMode[session.mode] ?? 0) + minutes;
      usageByLevel[session.level] =
          (usageByLevel[session.level] ?? 0) + minutes;

      if (session.hadTemperatureWarning || session.hadBatteryWarning) {
        warningCount++;
      }
    }

    return UsageStatistics(
      startDate: startDate,
      endDate: endDate,
      totalUsageMinutes: totalMinutes,
      usageByShot: usageByShot,
      usageByMode: usageByMode,
      usageByLevel: usageByLevel,
      warningCount: warningCount,
    );
  }
}
