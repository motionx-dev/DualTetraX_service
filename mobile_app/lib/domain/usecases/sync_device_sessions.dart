import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/usage_repository.dart';
import '../entities/usage_session.dart';
import '../entities/shot_type.dart';
import '../entities/device_mode.dart';
import '../entities/device_level.dart';
import '../entities/termination_reason.dart';
import '../entities/sync_status.dart';
import '../entities/battery_sample.dart';
import '../../data/datasources/ble_comm_data_source.dart';

class SyncDeviceSessionsUseCase {
  final UsageRepository usageRepository;
  final BleCommDataSource bleCommDataSource;

  /// Minimum working duration (in seconds) required to save a session
  static const int minWorkingDurationSeconds = 30;

  SyncDeviceSessionsUseCase({
    required this.usageRepository,
    required this.bleCommDataSource,
  });

  Future<Either<Failure, bool>> sendTimeSync() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = await bleCommDataSource.sendTimeSync(now);
      if (result != ResponseStatus.success) {
        return Left(DeviceFailure('Time sync failed: ${result.name}'));
      }
      return const Right(true);
    } catch (e) {
      return Left(DeviceFailure(e.toString()));
    }
  }

  Future<Either<Failure, int>> syncAllSessions() async {
    try {
      // Get unsynced sessions (filter=1)
      final summaries = await bleCommDataSource.getSessions(filter: 1);

      int syncedCount = 0;

      for (final summary in summaries) {
        // Get full session data
        final sessionData = await bleCommDataSource.getSessionDetail(summary.uuid);
        if (sessionData == null) continue;

        // Parse session data and save to local database
        final parsed = _parseSessionDetail(sessionData);
        if (parsed != null) {
          final (session, samples) = parsed;
          // Only save sessions with working duration >= 30 seconds
          if (session.workingDurationSeconds >= minWorkingDurationSeconds) {
            await usageRepository.saveSessionFromDevice(session, samples);
          }
        }

        // Confirm sync to device
        final confirmed = await bleCommDataSource.confirmSync(summary.uuid);
        if (confirmed == ResponseStatus.success) {
          syncedCount++;
        }
      }

      return Right(syncedCount);
    } catch (e) {
      return Left(DeviceFailure(e.toString()));
    }
  }

  /// Parse session detail data from device
  /// Format: UserActivityLogEntryV3 (56 bytes) + BatterySample[] (4 bytes each)
  (UsageSession, List<BatterySample>)? _parseSessionDetail(Uint8List data) {
    // Minimum size: 56 bytes (UserActivityLogEntryV3)
    if (data.length < 56) return null;

    final byteData = ByteData.sublistView(data);
    int offset = 0;

    // Header (4 bytes)
    final version = data[offset]; // version
    offset += 4; // skip version + reserved

    if (version != 3) return null; // Only support V3

    // UUID (16 bytes)
    final uuid = data.sublist(offset, offset + 16);
    final uuidString = _uuidToString(uuid);
    offset += 16;

    // Timestamps (16 bytes)
    final startTimeMs = byteData.getUint64(offset, Endian.little);
    offset += 8;
    final endTimeMs = byteData.getUint64(offset, Endian.little);
    offset += 8;

    // Session Info (8 bytes)
    final featureType = data[offset++];
    final mode = data[offset++];
    final level = data[offset++];
    final ledPattern = data[offset++];
    final workingDurationS = byteData.getUint16(offset, Endian.little);
    offset += 2;
    final pauseDurationS = byteData.getUint16(offset, Endian.little);
    offset += 2;

    // Termination Info (4 bytes)
    final terminationReason = data[offset++];
    final pauseCount = data[offset++];
    final completionPercent = data[offset++];
    offset++; // skip syncStatus (we set it to syncedToApp)

    // Battery Sample Reference (4 bytes)
    final batterySampleCount = data[offset++];
    offset += 3; // skip battery_storage_index and reserved

    // Quick Battery Access (4 bytes)
    final startBatteryMV = byteData.getUint16(offset, Endian.little);
    offset += 2;
    final endBatteryMV = byteData.getUint16(offset, Endian.little);
    offset += 2;

    // Parse battery samples
    final samples = <BatterySample>[];
    for (int i = 0; i < batterySampleCount && offset + 4 <= data.length; i++) {
      final elapsedSeconds = byteData.getUint16(offset, Endian.little);
      offset += 2;
      final voltageMV = byteData.getUint16(offset, Endian.little);
      offset += 2;
      samples.add(BatterySample(
        elapsedSeconds: elapsedSeconds,
        voltageMV: voltageMV,
      ));
    }

    // Convert to domain entities
    final shotType = ShotType.fromValue(featureType);
    final deviceMode = _convertMode(featureType, mode);
    final deviceLevel = DeviceLevel.fromValue(level + 1); // firmware uses 0-2, app uses 1-3
    final termReason = TerminationReason.fromValue(terminationReason);

    final now = DateTime.now();
    final session = UsageSession(
      uuid: uuidString,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
      endTime: endTimeMs > 0 ? DateTime.fromMillisecondsSinceEpoch(endTimeMs) : null,
      shotType: shotType,
      mode: deviceMode,
      level: deviceLevel,
      ledPattern: ledPattern,
      workingDurationSeconds: workingDurationS,
      pauseDurationSeconds: pauseDurationS,
      pauseCount: pauseCount,
      terminationReason: termReason,
      completionPercent: completionPercent,
      startBatteryLevel: _voltageToPercent(startBatteryMV),
      endBatteryLevel: endBatteryMV > 0 ? _voltageToPercent(endBatteryMV) : null,
      batterySamples: samples,
      syncStatus: SyncStatus.syncedToApp,
      createdAt: now,
      updatedAt: now,
    );

    return (session, samples);
  }

  /// Convert firmware mode (0-3) to DeviceMode based on feature type
  DeviceMode _convertMode(int featureType, int mode) {
    if (featureType == 1) {
      // U-Shot: mode 0-3 → glow(0x01), tuning(0x02), renewal(0x03), volume(0x04)
      return DeviceMode.fromValue(mode + 1);
    } else if (featureType == 2) {
      // E-Shot: mode 0-3 → cleansing(0x11), firming(0x12), lifting(0x13), lf(0x14)
      return DeviceMode.fromValue(mode + 0x11);
    } else if (featureType == 3) {
      // LED Care
      return DeviceMode.ledMode;
    }
    return DeviceMode.unknown;
  }

  /// Convert UUID bytes to string format
  String _uuidToString(Uint8List bytes) {
    if (bytes.length != 16) return '';
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Convert battery voltage to percentage
  int _voltageToPercent(int voltageMV) {
    if (voltageMV >= 4200) return 100;
    if (voltageMV <= 3000) return 0;
    if (voltageMV >= 4000) return 80 + ((voltageMV - 4000) * 20 ~/ 200);
    if (voltageMV >= 3700) return 20 + ((voltageMV - 3700) * 60 ~/ 300);
    return ((voltageMV - 3000) * 20 ~/ 700);
  }
}
