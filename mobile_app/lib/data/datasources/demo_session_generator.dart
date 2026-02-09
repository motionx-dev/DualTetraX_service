import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';
import '../../domain/entities/termination_reason.dart';
import '../../domain/entities/sync_status.dart';
import '../models/usage_session_model.dart';
import 'usage_local_data_source.dart';

class DemoSessionGenerator {
  final UsageLocalDataSource _usageLocalDataSource;
  final _random = Random();
  final _uuid = const Uuid();

  static const _uShotModes = [
    DeviceMode.glow,
    DeviceMode.toneup,
    DeviceMode.renew,
    DeviceMode.volume,
  ];

  static const _eShotModes = [
    DeviceMode.clean,
    DeviceMode.firm,
    DeviceMode.line,
    DeviceMode.lift,
  ];

  static const _levels = [
    DeviceLevel.level1,
    DeviceLevel.level2,
    DeviceLevel.level3,
  ];

  static const _terminationReasons = [
    TerminationReason.timeout8Min,
    TerminationReason.manualPowerOff,
    TerminationReason.timeout8Min,
    TerminationReason.manualPowerOff,
    TerminationReason.pauseTimeout,
  ];

  DemoSessionGenerator(this._usageLocalDataSource);

  /// Generate demo data for the last [days] days with [sessionsPerDay] sessions each.
  /// Returns the total number of sessions created.
  Future<int> generateDemoData({int days = 7, int minPerDay = 3, int maxPerDay = 5}) async {
    int totalCreated = 0;
    final now = DateTime.now();

    for (int d = 0; d < days; d++) {
      final date = now.subtract(Duration(days: d));
      final sessionsCount = minPerDay + _random.nextInt(maxPerDay - minPerDay + 1);

      for (int s = 0; s < sessionsCount; s++) {
        final session = _generateSession(date, s);
        await _usageLocalDataSource.insertSession(session);
        totalCreated++;
      }
    }

    return totalCreated;
  }

  /// Generate a single realistic mock session.
  UsageSessionModel generateSingleSession() {
    return _generateSession(DateTime.now(), 0);
  }

  UsageSessionModel _generateSession(DateTime date, int index) {
    // Spread sessions across the day (8am - 10pm)
    final hour = 8 + _random.nextInt(14);
    final minute = _random.nextInt(60);
    final startTime = DateTime(date.year, date.month, date.day, hour, minute);

    // Random shot type (U-Shot 60%, E-Shot 35%, LED 5%)
    final shotRoll = _random.nextDouble();
    late ShotType shotType;
    late DeviceMode mode;

    if (shotRoll < 0.60) {
      shotType = ShotType.uShot;
      mode = _uShotModes[_random.nextInt(_uShotModes.length)];
    } else if (shotRoll < 0.95) {
      shotType = ShotType.eShot;
      mode = _eShotModes[_random.nextInt(_eShotModes.length)];
    } else {
      shotType = ShotType.ledCare;
      mode = DeviceMode.ledMode;
    }

    final level = _levels[_random.nextInt(_levels.length)];

    // Duration: 60-480 seconds (1-8 minutes)
    final workingDuration = 60 + _random.nextInt(421);
    final pauseDuration = _random.nextDouble() > 0.7 ? _random.nextInt(30) : 0;
    final pauseCount = pauseDuration > 0 ? 1 + _random.nextInt(3) : 0;
    final totalDuration = workingDuration + pauseDuration;
    final endTime = startTime.add(Duration(seconds: totalDuration));

    // Battery: start 60-95%, drain 2-8%
    final startBattery = 60 + _random.nextInt(36);
    final batteryDrain = 2 + _random.nextInt(7);
    final endBattery = (startBattery - batteryDrain).clamp(5, 100);

    // Completion: mostly 80-100%
    final completion = workingDuration >= 480
        ? 100
        : ((workingDuration / 480) * 100).round().clamp(10, 100);

    final termination = _terminationReasons[_random.nextInt(_terminationReasons.length)];

    final sessionUuid = _uuid.v4();
    final createdAt = startTime;

    return UsageSessionModel(
      uuid: sessionUuid,
      startTime: startTime,
      endTime: endTime,
      shotType: shotType,
      mode: mode,
      level: level,
      ledPattern: shotType == ShotType.ledCare ? 1 : null,
      workingDurationSeconds: workingDuration,
      pauseDurationSeconds: pauseDuration,
      pauseCount: pauseCount,
      terminationReason: termination,
      completionPercent: completion,
      hadTemperatureWarning: _random.nextDouble() > 0.95,
      hadBatteryWarning: startBattery < 30,
      startBatteryLevel: startBattery,
      endBatteryLevel: endBattery,
      syncStatus: SyncStatus.syncedToApp,
      timeSynced: true,
      deviceId: 'mock-device-001',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }
}
