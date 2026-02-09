import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/goal_remote_data_source.dart';

class GoalRepositoryImpl implements GoalRepository {
  final GoalRemoteDataSource remoteDataSource;

  GoalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UserGoal>>> getGoals() async {
    try {
      final goals = await remoteDataSource.getGoals();
      return Right(goals);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to get goals', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserGoal>> createGoal({required String goalType, required int targetMinutes, required String startDate, required String endDate}) async {
    try {
      final goal = await remoteDataSource.createGoal(goalType: goalType, targetMinutes: targetMinutes, startDate: startDate, endDate: endDate);
      return Right(goal);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to create goal', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserGoal>> updateGoal(String id, {int? targetMinutes, bool? isActive}) async {
    try {
      final goal = await remoteDataSource.updateGoal(id, targetMinutes: targetMinutes, isActive: isActive);
      return Right(goal);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to update goal', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    try {
      await remoteDataSource.deleteGoal(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to delete goal', statusCode: e.response?.statusCode));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
