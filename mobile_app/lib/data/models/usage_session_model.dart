import '../../domain/entities/usage_session.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';

class UsageSessionModel extends UsageSession {
  const UsageSessionModel({
    super.id,
    required super.startTime,
    super.endTime,
    required super.shotType,
    required super.mode,
    required super.level,
    super.workingDurationSeconds,
    super.pauseDurationSeconds,
    super.hadTemperatureWarning,
    super.hadBatteryWarning,
    required super.startBatteryLevel,
    super.endBatteryLevel,
  });

  factory UsageSessionModel.fromMap(Map<String, dynamic> map) {
    return UsageSessionModel(
      id: map['id'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      shotType: ShotType.fromValue(map['shot_type'] as int),
      mode: DeviceMode.fromValue(map['mode'] as int),
      level: DeviceLevel.fromValue(map['level'] as int),
      workingDurationSeconds: map['working_duration_seconds'] as int? ?? 0,
      pauseDurationSeconds: map['pause_duration_seconds'] as int? ?? 0,
      hadTemperatureWarning: (map['had_temperature_warning'] as int? ?? 0) == 1,
      hadBatteryWarning: (map['had_battery_warning'] as int? ?? 0) == 1,
      startBatteryLevel: map['start_battery_level'] as int,
      endBatteryLevel: map['end_battery_level'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'shot_type': shotType.value,
      'mode': mode.value,
      'level': level.value,
      'working_duration_seconds': workingDurationSeconds,
      'pause_duration_seconds': pauseDurationSeconds,
      'had_temperature_warning': hadTemperatureWarning ? 1 : 0,
      'had_battery_warning': hadBatteryWarning ? 1 : 0,
      'start_battery_level': startBatteryLevel,
      'end_battery_level': endBatteryLevel,
    };
  }

  factory UsageSessionModel.fromEntity(UsageSession entity) {
    return UsageSessionModel(
      id: entity.id,
      startTime: entity.startTime,
      endTime: entity.endTime,
      shotType: entity.shotType,
      mode: entity.mode,
      level: entity.level,
      workingDurationSeconds: entity.workingDurationSeconds,
      pauseDurationSeconds: entity.pauseDurationSeconds,
      hadTemperatureWarning: entity.hadTemperatureWarning,
      hadBatteryWarning: entity.hadBatteryWarning,
      startBatteryLevel: entity.startBatteryLevel,
      endBatteryLevel: entity.endBatteryLevel,
    );
  }
}
