import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/goal_repository.dart';

class DeleteGoal extends UseCase<void, String> {
  final GoalRepository repository;
  DeleteGoal(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteGoal(params);
  }
}
