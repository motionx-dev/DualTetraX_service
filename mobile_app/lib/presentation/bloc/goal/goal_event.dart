import 'package:equatable/equatable.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

class LoadGoals extends GoalEvent {
  const LoadGoals();
}

class CreateGoal extends GoalEvent {
  final String goalType;
  final int targetMinutes;
  final String startDate;
  final String endDate;

  const CreateGoal({
    required this.goalType,
    required this.targetMinutes,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [goalType, targetMinutes, startDate, endDate];
}

class UpdateGoalEvent extends GoalEvent {
  final String id;
  final int? targetMinutes;
  final bool? isActive;

  const UpdateGoalEvent({required this.id, this.targetMinutes, this.isActive});

  @override
  List<Object?> get props => [id, targetMinutes, isActive];
}

class DeleteGoalEvent extends GoalEvent {
  final String id;
  const DeleteGoalEvent(this.id);
  @override
  List<Object?> get props => [id];
}
