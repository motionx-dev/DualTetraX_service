import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/usage_statistics.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetWeeklyStatistics extends UseCase<UsageStatistics, WeekParams> {
  final UsageRepository repository;

  GetWeeklyStatistics(this.repository);

  @override
  Future<Either<Failure, UsageStatistics>> call(WeekParams params) {
    return repository.getWeeklyStatistics(params.weekStart);
  }
}

class WeekParams extends Equatable {
  final DateTime weekStart;

  const WeekParams(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}
