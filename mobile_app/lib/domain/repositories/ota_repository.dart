import 'dart:typed_data';
import '../entities/ota_status.dart';
import '../entities/firmware_info.dart';

/// OTA Repository interface for firmware update operations
abstract class OtaRepository {
  /// Stream of OTA status updates
  Stream<OtaStatus> get otaStatusStream;

  /// Pick local firmware file
  Future<FirmwareInfo?> pickLocalFirmware();

  /// Initialize OTA service
  Future<void> initializeOtaService();

  /// Check if OTA service is available
  Future<bool> isOtaAvailable();

  /// Start OTA update with firmware info
  Future<void> startOtaUpdate(FirmwareInfo firmware);

  /// Send next firmware chunk
  /// Returns true if more chunks remain, false if all sent
  Future<bool> sendNextChunk();

  /// Finish OTA (trigger validation and apply)
  Future<void> finishOtaUpdate();

  /// Cancel ongoing OTA
  Future<void> cancelOtaUpdate();

  /// Get current progress percentage (0-100)
  int get currentProgress;

  /// Dispose resources
  void dispose();
}
