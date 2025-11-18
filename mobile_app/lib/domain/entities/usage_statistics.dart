import 'package:equatable/equatable.dart';
import 'shot_type.dart';
import 'device_mode.dart';
import 'device_level.dart';

class UsageStatistics extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final int totalUsageMinutes;
  final Map<ShotType, int> usageByShot; // minutes
  final Map<DeviceMode, int> usageByMode; // minutes
  final Map<DeviceLevel, int> usageByLevel; // minutes
  final int warningCount;

  const UsageStatistics({
    required this.startDate,
    required this.endDate,
    required this.totalUsageMinutes,
    required this.usageByShot,
    required this.usageByMode,
    required this.usageByLevel,
    required this.warningCount,
  });

  @override
  List<Object?> get props => [
        startDate,
        endDate,
        totalUsageMinutes,
        usageByShot,
        usageByMode,
        usageByLevel,
        warningCount,
      ];
}

class DailyUsage extends Equatable {
  final DateTime date;
  final int usageMinutes;
  final Map<ShotType, int> usageByShot;

  const DailyUsage({
    required this.date,
    required this.usageMinutes,
    required this.usageByShot,
  });

  @override
  List<Object?> get props => [date, usageMinutes, usageByShot];
}
