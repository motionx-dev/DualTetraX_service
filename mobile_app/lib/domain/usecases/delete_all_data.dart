import 'package:dartz/dartz.dart';
import '../repositories/usage_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class DeleteAllData extends UseCase<void, NoParams> {
  final UsageRepository repository;

  DeleteAllData(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.deleteAllSessions();
  }
}
