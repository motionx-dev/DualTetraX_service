import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/goals/get_goals.dart';
import '../../../domain/usecases/goals/create_goal.dart' as create_usecase;
import '../../../domain/usecases/goals/update_goal.dart' as update_usecase;
import '../../../domain/usecases/goals/delete_goal.dart' as delete_usecase;
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GetGoals getGoals;
  final create_usecase.CreateGoal createGoalUseCase;
  final update_usecase.UpdateGoal updateGoalUseCase;
  final delete_usecase.DeleteGoal deleteGoalUseCase;

  GoalBloc({
    required this.getGoals,
    required this.createGoalUseCase,
    required this.updateGoalUseCase,
    required this.deleteGoalUseCase,
  }) : super(const GoalInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<CreateGoal>(_onCreateGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
  }

  Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    final result = await getGoals(NoParams());
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goals) => emit(GoalsLoaded(goals)),
    );
  }

  Future<void> _onCreateGoal(CreateGoal event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    final result = await createGoalUseCase(create_usecase.CreateGoalParams(
      goalType: event.goalType,
      targetMinutes: event.targetMinutes,
      startDate: event.startDate,
      endDate: event.endDate,
    ));
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (_) => add(const LoadGoals()),
    );
  }

  Future<void> _onUpdateGoal(UpdateGoalEvent event, Emitter<GoalState> emit) async {
    final result = await updateGoalUseCase(update_usecase.UpdateGoalParams(
      id: event.id,
      targetMinutes: event.targetMinutes,
      isActive: event.isActive,
    ));
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (_) => add(const LoadGoals()),
    );
  }

  Future<void> _onDeleteGoal(DeleteGoalEvent event, Emitter<GoalState> emit) async {
    final result = await deleteGoalUseCase(event.id);
    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (_) => add(const LoadGoals()),
    );
  }
}
