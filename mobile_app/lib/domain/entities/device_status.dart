import 'package:equatable/equatable.dart';
import 'shot_type.dart';
import 'device_mode.dart';
import 'device_level.dart';
import 'working_state.dart';
import 'battery_status.dart';
import 'warning_status.dart';

class DeviceStatus extends Equatable {
  final ShotType shotType;
  final DeviceMode mode;
  final DeviceLevel level;
  final WorkingState workingState;
  final BatteryStatus batteryStatus;
  final WarningStatus warningStatus;
  final bool isCharging;
  final DateTime timestamp;

  const DeviceStatus({
    required this.shotType,
    required this.mode,
    required this.level,
    required this.workingState,
    required this.batteryStatus,
    required this.warningStatus,
    required this.isCharging,
    required this.timestamp,
  });

  DeviceStatus copyWith({
    ShotType? shotType,
    DeviceMode? mode,
    DeviceLevel? level,
    WorkingState? workingState,
    BatteryStatus? batteryStatus,
    WarningStatus? warningStatus,
    bool? isCharging,
    DateTime? timestamp,
  }) {
    return DeviceStatus(
      shotType: shotType ?? this.shotType,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      workingState: workingState ?? this.workingState,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      warningStatus: warningStatus ?? this.warningStatus,
      isCharging: isCharging ?? this.isCharging,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        shotType,
        mode,
        level,
        workingState,
        batteryStatus,
        warningStatus,
        isCharging,
        timestamp,
      ];
}
