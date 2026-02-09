import '../../domain/entities/usage_session.dart';
import '../../domain/entities/battery_sample.dart';

class SessionUploadModel {
  final String deviceId;
  final List<SessionItemModel> sessions;

  const SessionUploadModel({
    required this.deviceId,
    required this.sessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }
}

class SessionItemModel {
  final String id;
  final int shotType;
  final int deviceMode;
  final int level;
  final int? ledPattern;
  final String startTime;
  final String? endTime;
  final int workingDuration;
  final int pauseDuration;
  final int pauseCount;
  final int? terminationReason;
  final int completionPercent;
  final bool hadTemperatureWarning;
  final bool hadBatteryWarning;
  final int? batteryStart;
  final int? batteryEnd;
  final bool timeSynced;
  final List<BatterySampleJson> batterySamples;

  const SessionItemModel({
    required this.id,
    required this.shotType,
    required this.deviceMode,
    required this.level,
    this.ledPattern,
    required this.startTime,
    this.endTime,
    this.workingDuration = 0,
    this.pauseDuration = 0,
    this.pauseCount = 0,
    this.terminationReason,
    this.completionPercent = 0,
    this.hadTemperatureWarning = false,
    this.hadBatteryWarning = false,
    this.batteryStart,
    this.batteryEnd,
    this.timeSynced = true,
    this.batterySamples = const [],
  });

  factory SessionItemModel.fromEntity(UsageSession session) {
    return SessionItemModel(
      id: session.uuid,
      shotType: session.shotType.value,
      deviceMode: session.mode.value,
      level: session.level.value,
      ledPattern: session.ledPattern,
      startTime: session.startTime.toUtc().toIso8601String(),
      endTime: session.endTime?.toUtc().toIso8601String(),
      workingDuration: session.workingDurationSeconds,
      pauseDuration: session.pauseDurationSeconds,
      pauseCount: session.pauseCount,
      terminationReason: session.terminationReason?.value,
      completionPercent: session.completionPercent,
      hadTemperatureWarning: session.hadTemperatureWarning,
      hadBatteryWarning: session.hadBatteryWarning,
      batteryStart: session.startBatteryLevel,
      batteryEnd: session.endBatteryLevel,
      timeSynced: session.timeSynced,
      batterySamples: session.batterySamples
          .map((s) => BatterySampleJson(
                elapsedSeconds: s.elapsedSeconds,
                voltageMv: s.voltageMV,
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shot_type': shotType,
      'device_mode': deviceMode,
      'level': level,
      if (ledPattern != null) 'led_pattern': ledPattern,
      'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      'working_duration': workingDuration,
      'pause_duration': pauseDuration,
      'pause_count': pauseCount,
      if (terminationReason != null) 'termination_reason': terminationReason,
      'completion_percent': completionPercent,
      'had_temperature_warning': hadTemperatureWarning,
      'had_battery_warning': hadBatteryWarning,
      if (batteryStart != null) 'battery_start': batteryStart,
      if (batteryEnd != null) 'battery_end': batteryEnd,
      'time_synced': timeSynced,
      if (batterySamples.isNotEmpty)
        'battery_samples': batterySamples.map((s) => s.toJson()).toList(),
    };
  }
}

class BatterySampleJson {
  final int elapsedSeconds;
  final int voltageMv;

  const BatterySampleJson({
    required this.elapsedSeconds,
    required this.voltageMv,
  });

  Map<String, dynamic> toJson() => {
        'elapsed_seconds': elapsedSeconds,
        'voltage_mv': voltageMv,
      };
}
