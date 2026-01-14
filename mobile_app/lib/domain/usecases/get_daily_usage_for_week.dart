import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/usage_statistics.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetDailyUsageForWeek extends UseCase<List<DailyUsage>, WeekUsageParams> {
  final UsageRepository repository;

  GetDailyUsageForWeek(this.repository);

  @override
  Future<Either<Failure, List<DailyUsage>>> call(WeekUsageParams params) {
    return repository.getDailyUsageForWeek(params.weekStart);
  }
}

class WeekUsageParams extends Equatable {
  final DateTime weekStart;

  const WeekUsageParams(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}
