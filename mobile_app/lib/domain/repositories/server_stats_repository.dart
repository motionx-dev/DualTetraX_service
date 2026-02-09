import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/server_statistics.dart';

abstract class ServerStatsRepository {
  Future<Either<Failure, ServerDailyStats>> getDailyStats({String? date, String? deviceId});
  Future<Either<Failure, ServerRangeStats>> getRangeStats({
    required String startDate,
    required String endDate,
    String? deviceId,
    String groupBy = 'day',
  });
}
