import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_goal_model.dart';

abstract class GoalRemoteDataSource {
  Future<List<UserGoalModel>> getGoals();
  Future<UserGoalModel> createGoal({required String goalType, required int targetMinutes, required String startDate, required String endDate});
  Future<UserGoalModel> updateGoal(String id, {int? targetMinutes, bool? isActive});
  Future<void> deleteGoal(String id);
}

class GoalRemoteDataSourceImpl implements GoalRemoteDataSource {
  final ApiClient _apiClient;

  GoalRemoteDataSourceImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<UserGoalModel>> getGoals() async {
    final response = await _apiClient.get(ApiEndpoints.goals);
    final data = response.data as Map<String, dynamic>;
    final goals = data['goals'] as List;
    return goals.map((g) => UserGoalModel.fromJson(g as Map<String, dynamic>)).toList();
  }

  @override
  Future<UserGoalModel> createGoal({required String goalType, required int targetMinutes, required String startDate, required String endDate}) async {
    final response = await _apiClient.post(
      ApiEndpoints.goals,
      data: {
        'goal_type': goalType,
        'target_minutes': targetMinutes,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return UserGoalModel.fromJson(data['goal'] as Map<String, dynamic>);
  }

  @override
  Future<UserGoalModel> updateGoal(String id, {int? targetMinutes, bool? isActive}) async {
    final response = await _apiClient.put(
      ApiEndpoints.goal(id),
      data: {
        if (targetMinutes != null) 'target_minutes': targetMinutes,
        if (isActive != null) 'is_active': isActive,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return UserGoalModel.fromJson(data['goal'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _apiClient.delete(ApiEndpoints.goal(id));
  }
}
