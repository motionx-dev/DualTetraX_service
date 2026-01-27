import 'package:equatable/equatable.dart';
import 'shot_type.dart';
import 'device_mode.dart';
import 'device_level.dart';
import 'battery_sample.dart';
import 'termination_reason.dart';
import 'sync_status.dart';

class UsageSession extends Equatable {
  final String uuid;
  final DateTime startTime;
  final DateTime? endTime;
  final ShotType shotType;
  final DeviceMode mode;
  final DeviceLevel level;
  final int? ledPattern;
  final int workingDurationSeconds;
  final int pauseDurationSeconds;
  final int pauseCount;
  final TerminationReason? terminationReason;
  final int completionPercent;
  final bool hadTemperatureWarning;
  final bool hadBatteryWarning;
  final int startBatteryLevel;
  final int? endBatteryLevel;
  final List<BatterySample> batterySamples;
  final SyncStatus syncStatus;
  final bool timeSynced; // true if timestamps are real time, false if device uptime
  final String? deviceId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UsageSession({
    required this.uuid,
    required this.startTime,
    this.endTime,
    required this.shotType,
    required this.mode,
    required this.level,
    this.ledPattern,
    this.workingDurationSeconds = 0,
    this.pauseDurationSeconds = 0,
    this.pauseCount = 0,
    this.terminationReason,
    this.completionPercent = 0,
    this.hadTemperatureWarning = false,
    this.hadBatteryWarning = false,
    required this.startBatteryLevel,
    this.endBatteryLevel,
    this.batterySamples = const [],
    this.syncStatus = SyncStatus.notSynced,
    this.timeSynced = true,
    this.deviceId,
    required this.createdAt,
    required this.updatedAt,
  });

  @Deprecated('Use uuid instead')
  String? get id => uuid;

  Duration get workingDuration => Duration(seconds: workingDurationSeconds);
  Duration get pauseDuration => Duration(seconds: pauseDurationSeconds);
  Duration get totalDuration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  bool get isActive => endTime == null;

  int? get startBatteryPercent =>
      batterySamples.isNotEmpty ? batterySamples.first.batteryPercent : null;

  int? get endBatteryPercent =>
      batterySamples.length > 1 ? batterySamples.last.batteryPercent : null;

  int? get batteryConsumed {
    if (startBatteryPercent != null && endBatteryPercent != null) {
      return startBatteryPercent! - endBatteryPercent!;
    }
    return null;
  }

  UsageSession copyWith({
    String? uuid,
    DateTime? startTime,
    DateTime? endTime,
    ShotType? shotType,
    DeviceMode? mode,
    DeviceLevel? level,
    int? ledPattern,
    int? workingDurationSeconds,
    int? pauseDurationSeconds,
    int? pauseCount,
    TerminationReason? terminationReason,
    int? completionPercent,
    bool? hadTemperatureWarning,
    bool? hadBatteryWarning,
    int? startBatteryLevel,
    int? endBatteryLevel,
    List<BatterySample>? batterySamples,
    SyncStatus? syncStatus,
    bool? timeSynced,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsageSession(
      uuid: uuid ?? this.uuid,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      shotType: shotType ?? this.shotType,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      ledPattern: ledPattern ?? this.ledPattern,
      workingDurationSeconds:
          workingDurationSeconds ?? this.workingDurationSeconds,
      pauseDurationSeconds: pauseDurationSeconds ?? this.pauseDurationSeconds,
      pauseCount: pauseCount ?? this.pauseCount,
      terminationReason: terminationReason ?? this.terminationReason,
      completionPercent: completionPercent ?? this.completionPercent,
      hadTemperatureWarning:
          hadTemperatureWarning ?? this.hadTemperatureWarning,
      hadBatteryWarning: hadBatteryWarning ?? this.hadBatteryWarning,
      startBatteryLevel: startBatteryLevel ?? this.startBatteryLevel,
      endBatteryLevel: endBatteryLevel ?? this.endBatteryLevel,
      batterySamples: batterySamples ?? this.batterySamples,
      syncStatus: syncStatus ?? this.syncStatus,
      timeSynced: timeSynced ?? this.timeSynced,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uuid,
        startTime,
        endTime,
        shotType,
        mode,
        level,
        ledPattern,
        workingDurationSeconds,
        pauseDurationSeconds,
        pauseCount,
        terminationReason,
        completionPercent,
        hadTemperatureWarning,
        hadBatteryWarning,
        startBatteryLevel,
        endBatteryLevel,
        batterySamples,
        syncStatus,
        timeSynced,
        deviceId,
        createdAt,
        updatedAt,
      ];
}
