import 'package:equatable/equatable.dart';

class ServerDailyStats extends Equatable {
  final String date;
  final int totalSessions;
  final int totalDuration;
  final int ushotSessions;
  final int ushotDuration;
  final int eshotSessions;
  final int eshotDuration;
  final int ledSessions;
  final int ledDuration;
  final Map<String, int> modeBreakdown;
  final Map<String, int> levelBreakdown;
  final int warningCount;

  const ServerDailyStats({
    required this.date,
    this.totalSessions = 0,
    this.totalDuration = 0,
    this.ushotSessions = 0,
    this.ushotDuration = 0,
    this.eshotSessions = 0,
    this.eshotDuration = 0,
    this.ledSessions = 0,
    this.ledDuration = 0,
    this.modeBreakdown = const {},
    this.levelBreakdown = const {},
    this.warningCount = 0,
  });

  @override
  List<Object?> get props => [
        date,
        totalSessions,
        totalDuration,
        ushotSessions,
        eshotSessions,
        ledSessions,
        warningCount,
      ];
}

class ServerRangeStats extends Equatable {
  final String startDate;
  final String endDate;
  final List<ServerPeriodStats> data;
  final int summaryTotalSessions;
  final int summaryTotalDuration;
  final double avgSessionsPerDay;

  const ServerRangeStats({
    required this.startDate,
    required this.endDate,
    this.data = const [],
    this.summaryTotalSessions = 0,
    this.summaryTotalDuration = 0,
    this.avgSessionsPerDay = 0,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        data,
        summaryTotalSessions,
        summaryTotalDuration,
      ];
}

class ServerPeriodStats extends Equatable {
  final String period;
  final int totalSessions;
  final int totalDuration;
  final int ushotSessions;
  final int eshotSessions;
  final int ledSessions;

  const ServerPeriodStats({
    required this.period,
    this.totalSessions = 0,
    this.totalDuration = 0,
    this.ushotSessions = 0,
    this.eshotSessions = 0,
    this.ledSessions = 0,
  });

  @override
  List<Object?> get props => [
        period,
        totalSessions,
        totalDuration,
        ushotSessions,
        eshotSessions,
        ledSessions,
      ];
}
