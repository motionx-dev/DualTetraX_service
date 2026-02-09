import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_goal.dart';
import '../../repositories/goal_repository.dart';

class GetGoals extends UseCase<List<UserGoal>, NoParams> {
  final GoalRepository repository;
  GetGoals(this.repository);

  @override
  Future<Either<Failure, List<UserGoal>>> call(NoParams params) {
    return repository.getGoals();
  }
}
