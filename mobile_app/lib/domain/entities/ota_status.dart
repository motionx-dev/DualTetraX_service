import 'package:equatable/equatable.dart';
import 'ota_state.dart';
import 'ota_error.dart';

/// OTA status entity matching firmware BleOtaService::Status
class OtaStatus extends Equatable {
  final OtaState state;
  final OtaError error;
  final int progress; // 0-100%
  final int batteryLevel; // 0-100%
  final DateTime timestamp;

  const OtaStatus({
    required this.state,
    required this.error,
    required this.progress,
    required this.batteryLevel,
    required this.timestamp,
  });

  /// Create from BLE notification data (4 bytes)
  factory OtaStatus.fromBytes(List<int> bytes) {
    if (bytes.length < 4) {
      return OtaStatus.initial();
    }
    return OtaStatus(
      state: OtaState.fromValue(bytes[0]),
      error: OtaError.fromValue(bytes[1]),
      progress: bytes[2],
      batteryLevel: bytes[3],
      timestamp: DateTime.now(),
    );
  }

  /// Initial/default status
  factory OtaStatus.initial() {
    return OtaStatus(
      state: OtaState.idle,
      error: OtaError.none,
      progress: 0,
      batteryLevel: 100,
      timestamp: DateTime.now(),
    );
  }

  OtaStatus copyWith({
    OtaState? state,
    OtaError? error,
    int? progress,
    int? batteryLevel,
    DateTime? timestamp,
  }) {
    return OtaStatus(
      state: state ?? this.state,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isActive => state.isActive;
  bool get isSuccess => state == OtaState.success;
  bool get isError => state == OtaState.error;
  bool get isIdle => state == OtaState.idle;

  @override
  List<Object?> get props => [state, error, progress, batteryLevel, timestamp];
}
