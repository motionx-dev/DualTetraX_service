import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/usage_statistics.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetMonthlyStatistics extends UseCase<UsageStatistics, MonthParams> {
  final UsageRepository repository;

  GetMonthlyStatistics(this.repository);

  @override
  Future<Either<Failure, UsageStatistics>> call(MonthParams params) {
    return repository.getMonthlyStatistics(params.year, params.month);
  }
}

class MonthParams extends Equatable {
  final int year;
  final int month;

  const MonthParams(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}
