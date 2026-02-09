import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_goal.dart';

abstract class GoalRepository {
  Future<Either<Failure, List<UserGoal>>> getGoals();
  Future<Either<Failure, UserGoal>> createGoal({
    required String goalType,
    required int targetMinutes,
    required String startDate,
    required String endDate,
  });
  Future<Either<Failure, UserGoal>> updateGoal(String id, {int? targetMinutes, bool? isActive});
  Future<Either<Failure, void>> deleteGoal(String id);
}
