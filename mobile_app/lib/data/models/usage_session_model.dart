import '../../domain/entities/usage_session.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';
import '../../domain/entities/battery_sample.dart';
import '../../domain/entities/termination_reason.dart';
import '../../domain/entities/sync_status.dart';

class UsageSessionModel extends UsageSession {
  const UsageSessionModel({
    required super.uuid,
    required super.startTime,
    super.endTime,
    required super.shotType,
    required super.mode,
    required super.level,
    super.ledPattern,
    super.workingDurationSeconds,
    super.pauseDurationSeconds,
    super.pauseCount,
    super.terminationReason,
    super.completionPercent,
    super.hadTemperatureWarning,
    super.hadBatteryWarning,
    required super.startBatteryLevel,
    super.endBatteryLevel,
    super.batterySamples,
    super.syncStatus,
    super.deviceId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UsageSessionModel.fromMap(Map<String, dynamic> map) {
    return UsageSessionModel(
      uuid: map['uuid'] as String,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      shotType: ShotType.fromValue(map['shot_type'] as int),
      mode: DeviceMode.fromValue(map['mode'] as int),
      level: DeviceLevel.fromValue(map['level'] as int),
      ledPattern: map['led_pattern'] as int?,
      workingDurationSeconds: map['working_duration_seconds'] as int? ?? 0,
      pauseDurationSeconds: map['pause_duration_seconds'] as int? ?? 0,
      pauseCount: map['pause_count'] as int? ?? 0,
      terminationReason: map['termination_reason'] != null
          ? TerminationReason.fromValue(map['termination_reason'] as int)
          : null,
      completionPercent: map['completion_percent'] as int? ?? 0,
      hadTemperatureWarning: (map['had_temperature_warning'] as int? ?? 0) == 1,
      hadBatteryWarning: (map['had_battery_warning'] as int? ?? 0) == 1,
      startBatteryLevel: map['start_battery_level'] as int,
      endBatteryLevel: map['end_battery_level'] as int?,
      syncStatus: SyncStatus.fromValue(map['sync_status'] as int? ?? 0),
      deviceId: map['device_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'shot_type': shotType.value,
      'mode': mode.value,
      'level': level.value,
      'led_pattern': ledPattern,
      'working_duration_seconds': workingDurationSeconds,
      'pause_duration_seconds': pauseDurationSeconds,
      'pause_count': pauseCount,
      'termination_reason': terminationReason?.value,
      'completion_percent': completionPercent,
      'had_temperature_warning': hadTemperatureWarning ? 1 : 0,
      'had_battery_warning': hadBatteryWarning ? 1 : 0,
      'start_battery_level': startBatteryLevel,
      'end_battery_level': endBatteryLevel,
      'sync_status': syncStatus.value,
      'device_id': deviceId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UsageSessionModel.fromEntity(UsageSession entity) {
    return UsageSessionModel(
      uuid: entity.uuid,
      startTime: entity.startTime,
      endTime: entity.endTime,
      shotType: entity.shotType,
      mode: entity.mode,
      level: entity.level,
      ledPattern: entity.ledPattern,
      workingDurationSeconds: entity.workingDurationSeconds,
      pauseDurationSeconds: entity.pauseDurationSeconds,
      pauseCount: entity.pauseCount,
      terminationReason: entity.terminationReason,
      completionPercent: entity.completionPercent,
      hadTemperatureWarning: entity.hadTemperatureWarning,
      hadBatteryWarning: entity.hadBatteryWarning,
      startBatteryLevel: entity.startBatteryLevel,
      endBatteryLevel: entity.endBatteryLevel,
      batterySamples: entity.batterySamples,
      syncStatus: entity.syncStatus,
      deviceId: entity.deviceId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

class BatterySampleModel extends BatterySample {
  const BatterySampleModel({
    required super.elapsedSeconds,
    required super.voltageMV,
  });

  factory BatterySampleModel.fromMap(Map<String, dynamic> map) {
    return BatterySampleModel(
      elapsedSeconds: map['elapsed_seconds'] as int,
      voltageMV: map['voltage_mv'] as int,
    );
  }

  Map<String, dynamic> toMap(String sessionUuid) {
    return {
      'session_uuid': sessionUuid,
      'elapsed_seconds': elapsedSeconds,
      'voltage_mv': voltageMV,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory BatterySampleModel.fromEntity(BatterySample entity) {
    return BatterySampleModel(
      elapsedSeconds: entity.elapsedSeconds,
      voltageMV: entity.voltageMV,
    );
  }
}
