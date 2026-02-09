import '../../domain/entities/server_statistics.dart';

class ServerDailyStatsModel extends ServerDailyStats {
  const ServerDailyStatsModel({
    required super.date,
    super.totalSessions,
    super.totalDuration,
    super.ushotSessions,
    super.ushotDuration,
    super.eshotSessions,
    super.eshotDuration,
    super.ledSessions,
    super.ledDuration,
    super.modeBreakdown,
    super.levelBreakdown,
    super.warningCount,
  });

  factory ServerDailyStatsModel.fromJson(Map<String, dynamic> json) {
    return ServerDailyStatsModel(
      date: json['date'] as String,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalDuration: json['total_duration'] as int? ?? 0,
      ushotSessions: json['ushot_sessions'] as int? ?? 0,
      ushotDuration: json['ushot_duration'] as int? ?? 0,
      eshotSessions: json['eshot_sessions'] as int? ?? 0,
      eshotDuration: json['eshot_duration'] as int? ?? 0,
      ledSessions: json['led_sessions'] as int? ?? 0,
      ledDuration: json['led_duration'] as int? ?? 0,
      modeBreakdown: json['mode_breakdown'] != null
          ? Map<String, int>.from(
              (json['mode_breakdown'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      levelBreakdown: json['level_breakdown'] != null
          ? Map<String, int>.from(
              (json['level_breakdown'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              ),
            )
          : const {},
      warningCount: json['warning_count'] as int? ?? 0,
    );
  }
}

class ServerRangeStatsModel extends ServerRangeStats {
  const ServerRangeStatsModel({
    required super.startDate,
    required super.endDate,
    super.data,
    super.summaryTotalSessions,
    super.summaryTotalDuration,
    super.avgSessionsPerDay,
  });

  factory ServerRangeStatsModel.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final dataList = json['data'] as List? ?? [];

    return ServerRangeStatsModel(
      startDate: range['start'] as String,
      endDate: range['end'] as String,
      data: dataList
          .map((d) => ServerPeriodStatsModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      summaryTotalSessions: summary['total_sessions'] as int? ?? 0,
      summaryTotalDuration: summary['total_duration'] as int? ?? 0,
      avgSessionsPerDay: (summary['avg_sessions_per_day'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ServerPeriodStatsModel extends ServerPeriodStats {
  const ServerPeriodStatsModel({
    required super.period,
    super.totalSessions,
    super.totalDuration,
    super.ushotSessions,
    super.eshotSessions,
    super.ledSessions,
  });

  factory ServerPeriodStatsModel.fromJson(Map<String, dynamic> json) {
    return ServerPeriodStatsModel(
      period: json['period'] as String,
      totalSessions: json['total_sessions'] as int? ?? 0,
      totalDuration: json['total_duration'] as int? ?? 0,
      ushotSessions: json['ushot_sessions'] as int? ?? 0,
      eshotSessions: json['eshot_sessions'] as int? ?? 0,
      ledSessions: json['led_sessions'] as int? ?? 0,
    );
  }
}
