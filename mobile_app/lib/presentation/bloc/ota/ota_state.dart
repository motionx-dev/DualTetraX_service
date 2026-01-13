import 'package:equatable/equatable.dart';
import '../../../domain/entities/firmware_info.dart';
import '../../../domain/entities/ota_status.dart';
import '../../../domain/entities/ota_state.dart' as domain;
import '../../../domain/entities/ota_error.dart';

class OtaBlocState extends Equatable {
  final FirmwareInfo? selectedFirmware;
  final bool isOtaServiceReady;
  final bool isTransferring;
  final OtaStatus? deviceStatus;
  final int sendProgress; // Local send progress (0-100)
  final int sentChunks;
  final int totalChunks;
  final String? errorMessage;

  const OtaBlocState({
    this.selectedFirmware,
    this.isOtaServiceReady = false,
    this.isTransferring = false,
    this.deviceStatus,
    this.sendProgress = 0,
    this.sentChunks = 0,
    this.totalChunks = 0,
    this.errorMessage,
  });

  OtaBlocState copyWith({
    FirmwareInfo? selectedFirmware,
    bool? clearFirmware,
    bool? isOtaServiceReady,
    bool? isTransferring,
    OtaStatus? deviceStatus,
    int? sendProgress,
    int? sentChunks,
    int? totalChunks,
    String? errorMessage,
    bool? clearError,
  }) {
    return OtaBlocState(
      selectedFirmware: clearFirmware == true ? null : (selectedFirmware ?? this.selectedFirmware),
      isOtaServiceReady: isOtaServiceReady ?? this.isOtaServiceReady,
      isTransferring: isTransferring ?? this.isTransferring,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      sendProgress: sendProgress ?? this.sendProgress,
      sentChunks: sentChunks ?? this.sentChunks,
      totalChunks: totalChunks ?? this.totalChunks,
      errorMessage: clearError == true ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasError => errorMessage != null;
  bool get canStartOta =>
      selectedFirmware != null &&
      isOtaServiceReady &&
      !isTransferring &&
      (deviceStatus?.isIdle ?? true);

  bool get isOtaActive => isTransferring || (deviceStatus?.isActive ?? false);
  bool get isSuccess => deviceStatus?.isSuccess ?? false;
  bool get isDeviceError => deviceStatus?.isError ?? false;

  domain.OtaState get otaState => deviceStatus?.state ?? domain.OtaState.idle;

  @override
  List<Object?> get props => [
        selectedFirmware,
        isOtaServiceReady,
        isTransferring,
        deviceStatus,
        sendProgress,
        sentChunks,
        totalChunks,
        errorMessage,
      ];
}

/// Initial state
class OtaInitial extends OtaBlocState {
  const OtaInitial() : super();
}
