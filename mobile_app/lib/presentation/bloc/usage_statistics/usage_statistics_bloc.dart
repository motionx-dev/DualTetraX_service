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

// Period type to distinguish which tab's data is loaded
enum StatisticsPeriod { daily, weekly, monthly }

// Data holder for each period
class PeriodData extends Equatable {
  final bool isLoading;
  final UsageStatistics? statistics;
  final List<DailyUsage>? dailyUsages;
  final String? error;

  const PeriodData({
    this.isLoading = false,
    this.statistics,
    this.dailyUsages,
    this.error,
  });

  PeriodData copyWith({
    bool? isLoading,
    UsageStatistics? statistics,
    List<DailyUsage>? dailyUsages,
    String? error,
    bool clearError = false,
  }) {
    return PeriodData(
      isLoading: isLoading ?? this.isLoading,
      statistics: statistics ?? this.statistics,
      dailyUsages: dailyUsages ?? this.dailyUsages,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [isLoading, statistics, dailyUsages, error];
}

// State that caches data for all periods
class UsageStatisticsState extends Equatable {
  final PeriodData daily;
  final PeriodData weekly;
  final PeriodData monthly;
  final bool dataDeleted;

  const UsageStatisticsState({
    this.daily = const PeriodData(),
    this.weekly = const PeriodData(),
    this.monthly = const PeriodData(),
    this.dataDeleted = false,
  });

  UsageStatisticsState copyWith({
    PeriodData? daily,
    PeriodData? weekly,
    PeriodData? monthly,
    bool? dataDeleted,
  }) {
    return UsageStatisticsState(
      daily: daily ?? this.daily,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      dataDeleted: dataDeleted ?? this.dataDeleted,
    );
  }

  @override
  List<Object?> get props => [daily, weekly, monthly, dataDeleted];
}

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
  }) : super(const UsageStatisticsState()) {
    on<LoadDailyStatistics>(_onLoadDaily);
    on<LoadWeeklyStatistics>(_onLoadWeekly);
    on<LoadMonthlyStatistics>(_onLoadMonthly);
    on<DeleteAllDataRequested>(_onDeleteAllData);
  }

  Future<void> _onLoadDaily(
    LoadDailyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(state.copyWith(
      daily: state.daily.copyWith(isLoading: true, clearError: true),
    ));

    final result = await getDailyStatistics(DateParams(event.date));

    result.fold(
      (failure) => emit(state.copyWith(
        daily: state.daily.copyWith(isLoading: false, error: failure.message),
      )),
      (statistics) => emit(state.copyWith(
        daily: PeriodData(isLoading: false, statistics: statistics),
      )),
    );
  }

  Future<void> _onLoadWeekly(
    LoadWeeklyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(state.copyWith(
      weekly: state.weekly.copyWith(isLoading: true, clearError: true),
    ));

    final result = await getWeeklyStatistics(WeekParams(event.weekStart));
    final dailyResult = await getDailyUsageForWeek(WeekUsageParams(event.weekStart));

    result.fold(
      (failure) => emit(state.copyWith(
        weekly: state.weekly.copyWith(isLoading: false, error: failure.message),
      )),
      (statistics) {
        dailyResult.fold(
          (failure) => emit(state.copyWith(
            weekly: PeriodData(isLoading: false, statistics: statistics),
          )),
          (dailyUsages) => emit(state.copyWith(
            weekly: PeriodData(isLoading: false, statistics: statistics, dailyUsages: dailyUsages),
          )),
        );
      },
    );
  }

  Future<void> _onLoadMonthly(
    LoadMonthlyStatistics event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(state.copyWith(
      monthly: state.monthly.copyWith(isLoading: true, clearError: true),
    ));

    final result = await getMonthlyStatistics(MonthParams(event.year, event.month));
    final dailyResult = await getDailyUsageForMonth(MonthUsageParams(event.year, event.month));

    result.fold(
      (failure) => emit(state.copyWith(
        monthly: state.monthly.copyWith(isLoading: false, error: failure.message),
      )),
      (statistics) {
        dailyResult.fold(
          (failure) => emit(state.copyWith(
            monthly: PeriodData(isLoading: false, statistics: statistics),
          )),
          (dailyUsages) => emit(state.copyWith(
            monthly: PeriodData(isLoading: false, statistics: statistics, dailyUsages: dailyUsages),
          )),
        );
      },
    );
  }

  Future<void> _onDeleteAllData(
    DeleteAllDataRequested event,
    Emitter<UsageStatisticsState> emit,
  ) async {
    emit(state.copyWith(
      daily: state.daily.copyWith(isLoading: true),
    ));

    final result = await deleteAllData(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        daily: state.daily.copyWith(isLoading: false, error: failure.message),
      )),
      (_) => emit(const UsageStatisticsState(dataDeleted: true)),
    );
  }
}
