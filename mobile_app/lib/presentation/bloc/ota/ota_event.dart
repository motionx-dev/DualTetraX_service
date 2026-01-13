import 'package:equatable/equatable.dart';
import '../../../domain/entities/firmware_info.dart';
import '../../../domain/entities/ota_status.dart';

abstract class OtaEvent extends Equatable {
  const OtaEvent();

  @override
  List<Object?> get props => [];
}

/// Pick firmware file from local storage
class PickFirmwareRequested extends OtaEvent {
  const PickFirmwareRequested();
}

/// Clear selected firmware
class ClearFirmwareRequested extends OtaEvent {
  const ClearFirmwareRequested();
}

/// Initialize OTA service
class InitializeOtaRequested extends OtaEvent {
  const InitializeOtaRequested();
}

/// Start OTA update with selected firmware
class StartOtaRequested extends OtaEvent {
  final FirmwareInfo firmware;

  const StartOtaRequested(this.firmware);

  @override
  List<Object?> get props => [firmware];
}

/// Cancel ongoing OTA
class CancelOtaRequested extends OtaEvent {
  const CancelOtaRequested();
}

/// Internal event: OTA status changed (from BLE notification)
class OtaStatusChanged extends OtaEvent {
  final OtaStatus status;

  const OtaStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Internal event: Chunk send progress update
class ChunkProgressUpdated extends OtaEvent {
  final int progress;
  final int sentChunks;
  final int totalChunks;

  const ChunkProgressUpdated({
    required this.progress,
    required this.sentChunks,
    required this.totalChunks,
  });

  @override
  List<Object?> get props => [progress, sentChunks, totalChunks];
}

/// Internal event: All chunks sent, finishing OTA
class OtaFinishRequested extends OtaEvent {
  const OtaFinishRequested();
}
