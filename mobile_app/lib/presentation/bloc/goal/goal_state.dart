import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_goal.dart';

abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

class GoalsLoaded extends GoalState {
  final List<UserGoal> goals;
  const GoalsLoaded(this.goals);
  @override
  List<Object?> get props => [goals];
}

class GoalError extends GoalState {
  final String message;
  const GoalError(this.message);
  @override
  List<Object?> get props => [message];
}
