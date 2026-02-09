import '../../domain/entities/user_goal.dart';

class UserGoalModel extends UserGoal {
  const UserGoalModel({
    required super.id,
    required super.userId,
    required super.goalType,
    required super.targetMinutes,
    required super.startDate,
    required super.endDate,
    super.isActive,
    required super.createdAt,
  });

  factory UserGoalModel.fromJson(Map<String, dynamic> json) {
    return UserGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      targetMinutes: json['target_minutes'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
