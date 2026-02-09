import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_goal.dart';
import '../../repositories/goal_repository.dart';

class CreateGoal extends UseCase<UserGoal, CreateGoalParams> {
  final GoalRepository repository;
  CreateGoal(this.repository);

  @override
  Future<Either<Failure, UserGoal>> call(CreateGoalParams params) {
    return repository.createGoal(
      goalType: params.goalType,
      targetMinutes: params.targetMinutes,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class CreateGoalParams {
  final String goalType;
  final int targetMinutes;
  final String startDate;
  final String endDate;

  const CreateGoalParams({
    required this.goalType,
    required this.targetMinutes,
    required this.startDate,
    required this.endDate,
  });
}
