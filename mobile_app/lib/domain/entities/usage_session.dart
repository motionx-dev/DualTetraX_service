import 'package:equatable/equatable.dart';
import 'shot_type.dart';
import 'device_mode.dart';
import 'device_level.dart';

class UsageSession extends Equatable {
  final String? id;
  final DateTime startTime;
  final DateTime? endTime;
  final ShotType shotType;
  final DeviceMode mode;
  final DeviceLevel level;
  final int workingDurationSeconds;
  final int pauseDurationSeconds;
  final bool hadTemperatureWarning;
  final bool hadBatteryWarning;
  final int startBatteryLevel;
  final int? endBatteryLevel;

  const UsageSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.shotType,
    required this.mode,
    required this.level,
    this.workingDurationSeconds = 0,
    this.pauseDurationSeconds = 0,
    this.hadTemperatureWarning = false,
    this.hadBatteryWarning = false,
    required this.startBatteryLevel,
    this.endBatteryLevel,
  });

  Duration get workingDuration => Duration(seconds: workingDurationSeconds);
  Duration get pauseDuration => Duration(seconds: pauseDurationSeconds);
  Duration get totalDuration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  UsageSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    ShotType? shotType,
    DeviceMode? mode,
    DeviceLevel? level,
    int? workingDurationSeconds,
    int? pauseDurationSeconds,
    bool? hadTemperatureWarning,
    bool? hadBatteryWarning,
    int? startBatteryLevel,
    int? endBatteryLevel,
  }) {
    return UsageSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shotType: shotType ?? this.shotType,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      workingDurationSeconds:
          workingDurationSeconds ?? this.workingDurationSeconds,
      pauseDurationSeconds: pauseDurationSeconds ?? this.pauseDurationSeconds,
      hadTemperatureWarning:
          hadTemperatureWarning ?? this.hadTemperatureWarning,
      hadBatteryWarning: hadBatteryWarning ?? this.hadBatteryWarning,
      startBatteryLevel: startBatteryLevel ?? this.startBatteryLevel,
      endBatteryLevel: endBatteryLevel ?? this.endBatteryLevel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        shotType,
        mode,
        level,
        workingDurationSeconds,
        pauseDurationSeconds,
        hadTemperatureWarning,
        hadBatteryWarning,
        startBatteryLevel,
        endBatteryLevel,
      ];
}
