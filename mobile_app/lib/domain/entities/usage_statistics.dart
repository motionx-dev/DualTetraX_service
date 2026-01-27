import 'package:equatable/equatable.dart';
import 'shot_type.dart';
import 'device_mode.dart';
import 'device_level.dart';

class UsageStatistics extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int totalUsageSeconds;
  final Map<ShotType, int> usageByShot; // seconds
  final Map<DeviceMode, int> usageByMode; // seconds
  final Map<DeviceLevel, int> usageByLevel; // seconds
  final int warningCount;

  const UsageStatistics({
    required this.startDate,
    required this.endDate,
    required this.totalUsageSeconds,
    required this.usageByShot,
    required this.usageByMode,
    required this.usageByLevel,
    required this.warningCount,
  });

  /// Helper to get total usage in minutes (for backward compatibility)
  int get totalUsageMinutes => (totalUsageSeconds / 60).ceil();

  /// Format seconds as "Xm Ys" or "Ys" for short durations
  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalUsageSeconds,
        usageByShot,
        usageByMode,
        usageByLevel,
        warningCount,
      ];
}

class DailyUsage extends Equatable {
  final DateTime date;
  final int usageSeconds;
  final Map<ShotType, int> usageByShot; // seconds
  /// Seconds from sessions with real time sync (timeSynced=true)
  final int syncedSeconds;
  /// Seconds from sessions without time sync (timeSynced=false, estimated time)
  final int unsyncedSeconds;

  const DailyUsage({
    required this.date,
    required this.usageSeconds,
    required this.usageByShot,
    this.syncedSeconds = 0,
    this.unsyncedSeconds = 0,
  });

  /// Helper for backward compatibility
  int get usageMinutes => (usageSeconds / 60).ceil();
  int get syncedMinutes => (syncedSeconds / 60).ceil();
  int get unsyncedMinutes => (unsyncedSeconds / 60).ceil();

  @override
  List<Object?> get props => [date, usageSeconds, usageByShot, syncedSeconds, unsyncedSeconds];
}
