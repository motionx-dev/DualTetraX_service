import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/server_statistics.dart';
import '../../domain/repositories/server_stats_repository.dart';
import '../datasources/stats_remote_data_source.dart';

class ServerStatsRepositoryImpl implements ServerStatsRepository {
  final StatsRemoteDataSource remoteDataSource;

  ServerStatsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ServerDailyStats>> getDailyStats({String? date, String? deviceId}) async {
    try {
      final stats = await remoteDataSource.getDailyStats(date: date, deviceId: deviceId);
      return Right(stats);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get daily stats', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerRangeStats>> getRangeStats({required String startDate, required String endDate, String? deviceId, String groupBy = 'day'}) async {
    try {
      final stats = await remoteDataSource.getRangeStats(startDate: startDate, endDate: endDate, deviceId: deviceId, groupBy: groupBy);
      return Right(stats);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get range stats', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
