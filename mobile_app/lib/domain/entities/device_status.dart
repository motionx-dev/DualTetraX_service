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

  // 동작 시간 관련 (초 단위)
  final int? currentWorkingTime; // 현재 진행된 시간 (초)
  final int? totalWorkingTime;   // 전체 동작 시간 (초)

  // 모션 인식 상태 (U-Shot에서 사용)
  final bool isMotionDetected;

  const DeviceStatus({
    required this.shotType,
    required this.mode,
    required this.level,
    required this.workingState,
    required this.batteryStatus,
    required this.warningStatus,
    required this.isCharging,
    required this.timestamp,
    this.currentWorkingTime,
    this.totalWorkingTime,
    this.isMotionDetected = true, // 기본값: 모션 감지됨
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
    int? currentWorkingTime,
    int? totalWorkingTime,
    bool? isMotionDetected,
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
      currentWorkingTime: currentWorkingTime ?? this.currentWorkingTime,
      totalWorkingTime: totalWorkingTime ?? this.totalWorkingTime,
      isMotionDetected: isMotionDetected ?? this.isMotionDetected,
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
        currentWorkingTime,
        totalWorkingTime,
        isMotionDetected,
      ];
}
