import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user_goal.dart';
import '../../repositories/goal_repository.dart';

class UpdateGoal extends UseCase<UserGoal, UpdateGoalParams> {
  final GoalRepository repository;
  UpdateGoal(this.repository);

  @override
  Future<Either<Failure, UserGoal>> call(UpdateGoalParams params) {
    return repository.updateGoal(
      params.id,
      targetMinutes: params.targetMinutes,
      isActive: params.isActive,
    );
  }
}

class UpdateGoalParams {
  final String id;
  final int? targetMinutes;
  final bool? isActive;

  const UpdateGoalParams({required this.id, this.targetMinutes, this.isActive});
}
