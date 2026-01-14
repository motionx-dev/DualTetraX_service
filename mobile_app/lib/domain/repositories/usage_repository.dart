import 'package:dartz/dartz.dart';
import '../entities/usage_session.dart';
import '../entities/usage_statistics.dart';
import '../entities/sync_status.dart';
import '../entities/battery_sample.dart';
import '../../core/errors/failures.dart';

abstract class UsageRepository {
  // Session Management
  Future<Either<Failure, void>> startSession(UsageSession session);
  Future<Either<Failure, void>> updateSession(UsageSession session);
  Future<Either<Failure, void>> endSession(String sessionUuid, DateTime endTime);
  Future<Either<Failure, UsageSession?>> getActiveSession();
  Future<Either<Failure, UsageSession?>> getSessionByUuid(String uuid);

  // Session Queries
  Future<Either<Failure, List<UsageSession>>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<UsageSession>>> getSessionsByDate(DateTime date);

  // Sync Management
  Future<Either<Failure, List<UsageSession>>> getUnsyncedSessions();
  Future<Either<Failure, void>> updateSyncStatus(String uuid, SyncStatus status);
  Future<Either<Failure, void>> saveSessionFromDevice(
    UsageSession session,
    List<BatterySample> samples,
  );

  // Statistics
  Future<Either<Failure, UsageStatistics>> getDailyStatistics(DateTime date);
  Future<Either<Failure, UsageStatistics>> getWeeklyStatistics(DateTime weekStart);
  Future<Either<Failure, UsageStatistics>> getMonthlyStatistics(
    int year,
    int month,
  );
  Future<Either<Failure, List<DailyUsage>>> getDailyUsageForWeek(
    DateTime weekStart,
  );
  Future<Either<Failure, List<DailyUsage>>> getDailyUsageForMonth(
    int year,
    int month,
  );

  // Data Management
  Future<Either<Failure, void>> deleteAllSessions();
  Future<Either<Failure, void>> deleteSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
