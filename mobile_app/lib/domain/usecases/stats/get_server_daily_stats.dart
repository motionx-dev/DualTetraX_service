import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/server_statistics.dart';
import '../../repositories/server_stats_repository.dart';

class GetServerDailyStats extends UseCase<ServerDailyStats, DailyStatsParams> {
  final ServerStatsRepository repository;
  GetServerDailyStats(this.repository);

  @override
  Future<Either<Failure, ServerDailyStats>> call(DailyStatsParams params) {
    return repository.getDailyStats(date: params.date, deviceId: params.deviceId);
  }
}

class DailyStatsParams {
  final String? date;
  final String? deviceId;
  const DailyStatsParams({this.date, this.deviceId});
}
