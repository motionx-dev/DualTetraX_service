import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/usage_statistics.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetDailyStatistics extends UseCase<UsageStatistics, DateParams> {
  final UsageRepository repository;

  GetDailyStatistics(this.repository);

  @override
  Future<Either<Failure, UsageStatistics>> call(DateParams params) {
    return repository.getDailyStatistics(params.date);
  }
}

class DateParams extends Equatable {
  final DateTime date;

  const DateParams(this.date);

  @override
  List<Object?> get props => [date];
}
