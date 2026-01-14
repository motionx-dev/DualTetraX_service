import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/usage_statistics.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetDailyUsageForMonth extends UseCase<List<DailyUsage>, MonthUsageParams> {
  final UsageRepository repository;

  GetDailyUsageForMonth(this.repository);

  @override
  Future<Either<Failure, List<DailyUsage>>> call(MonthUsageParams params) {
    return repository.getDailyUsageForMonth(params.year, params.month);
  }
}

class MonthUsageParams extends Equatable {
  final int year;
  final int month;

  const MonthUsageParams(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}
