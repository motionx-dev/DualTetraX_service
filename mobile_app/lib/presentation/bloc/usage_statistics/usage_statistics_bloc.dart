import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/usage_statistics.dart';
import '../../../domain/usecases/get_daily_statistics.dart';
import '../../../domain/usecases/get_weekly_statistics.dart';
import '../../../domain/usecases/get_monthly_statistics.dart';
import '../../../domain/usecases/get_daily_usage_for_week.dart';
import '../../../domain/usecases/get_daily_usage_for_month.dart';
import '../../../domain/usecases/delete_all_data.dart';
import '../../../core/usecases/usecase.dart';

// Events
abstract class UsageStatisticsEvent extends Equatable {
  const UsageStatisticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailyStatistics extends UsageStatisticsEvent {
  final DateTime date;

  const LoadDailyStatistics(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadWeeklyStatistics extends UsageStatisticsEvent {
  final DateTime weekStart;

  const LoadWeeklyStatistics(this.weekStart);

  @override
  List<Object?> get props => [weekStart];
}

class LoadMonthlyStatistics extends UsageStatisticsEvent {
  final int year;
  final int month;

  const LoadMonthlyStatistics(this.year, this.month);

  @override
  List<Object?> get props => [year, month];
}

class DeleteAllDataRequested extends UsageStatisticsEvent {}

// States
abstract class UsageStatisticsState extends Equatable {
  const UsageStatisticsState();

  @override
  List<Object?> get props => [];
}

class UsageStatisticsInitial extends UsageStatisticsState {}

class UsageStatisticsLoading extends UsageStatisticsState {}

class UsageStatisticsLoaded extends UsageStatisticsState {
  final UsageStatistics statistics;
  final List<DailyUsage>? dailyUsages;

  const UsageStatisticsLoaded(this.statistics, {this.dailyUsages});

  @override
  List<Object?> get props => [statistics, dailyUsages];
}

class UsageStatisticsError extends UsageStatisticsState {
  final String message;

  const UsageStatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DataDeleted extends UsageStatisticsState {}

// Bloc
class UsageStatisticsBloc
    extends Bloc<UsageStatisticsEvent, UsageStatisticsState> {
  final GetDailyStatistics getDailyStatistics;
  final GetWeeklyStatistics getWeeklyStatistics;
  final GetMonthlyStatistics getMonthlyStatistics;
  final GetDailyUsageForWeek getDailyUsageForWeek;
  final GetDailyUsageForMonth getDailyUsageForMonth;
  final DeleteAllData deleteAllData;

  UsageStatisticsBloc({
    required this.getDailyStatistics,
    required this.getWeeklyStatistics,
    required this.getMonthlyStatistics,
    required this.getDailyUsageForWeek,
    required this.getDailyUsageForMonth,
    required this.deleteAllData,
  }) : super(UsageStatisticsInitial()) {
    on<LoadDailyStatistics>(_onLoadDaily);
    on<LoadWeeklyStatistics>(_onLoadWeekly);
    on<LoadMonthlyStatistics>(_onLoadMonthly);
    on<DeleteAllDataRequested>(_onDeleteAllData);
  }

  Future<void> _onLoadDaily(
    LoadDailyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());

    final result = await getDailyStatistics(DateParams(event.date));

    result.fold(
      (failure) => emit(UsageStatisticsError(failure.message)),
      (statistics) => emit(UsageStatisticsLoaded(statistics)),
    );
  }

  Future<void> _onLoadWeekly(
    LoadWeeklyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());

    final result = await getWeeklyStatistics(WeekParams(event.weekStart));
    final dailyResult = await getDailyUsageForWeek(WeekUsageParams(event.weekStart));

    result.fold(
      (failure) => emit(UsageStatisticsError(failure.message)),
      (statistics) {
        dailyResult.fold(
          (failure) => emit(UsageStatisticsLoaded(statistics)),
          (dailyUsages) => emit(UsageStatisticsLoaded(statistics, dailyUsages: dailyUsages)),
        );
      },
    );
  }

  Future<void> _onLoadMonthly(
    LoadMonthlyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());

    final result = await getMonthlyStatistics(MonthParams(event.year, event.month));
    final dailyResult = await getDailyUsageForMonth(MonthUsageParams(event.year, event.month));

    result.fold(
      (failure) => emit(UsageStatisticsError(failure.message)),
      (statistics) {
        dailyResult.fold(
          (failure) => emit(UsageStatisticsLoaded(statistics)),
          (dailyUsages) => emit(UsageStatisticsLoaded(statistics, dailyUsages: dailyUsages)),
        );
      },
    );
  }

  Future<void> _onDeleteAllData(
    DeleteAllDataRequested event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(UsageStatisticsLoading());

    final result = await deleteAllData(NoParams());

    result.fold(
      (failure) => emit(UsageStatisticsError(failure.message)),
      (_) => emit(DataDeleted()),
    );
  }
}
