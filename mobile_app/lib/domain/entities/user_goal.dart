import 'package:equatable/equatable.dart';

class UserGoal extends Equatable {
  final String id;
  final String userId;
  final String goalType;
  final int targetMinutes;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  const UserGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetMinutes,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        goalType,
        targetMinutes,
        startDate,
        endDate,
        isActive,
        createdAt,
      ];
}
