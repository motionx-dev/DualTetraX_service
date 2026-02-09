import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/device_info.dart';
import '../../domain/entities/connection_state.dart';
import '../../domain/entities/shot_type.dart';
import '../../domain/entities/device_mode.dart';
import '../../domain/entities/device_level.dart';
import '../../domain/entities/working_state.dart';
import '../../domain/entities/battery_status.dart';
import '../../domain/entities/warning_status.dart';
import '../models/device_info_model.dart';
import 'ble_remote_data_source.dart';
import 'ble_comm_data_source.dart';
import 'usage_local_data_source.dart';
import 'demo_session_generator.dart';

/// BLE Mock Data Source for testing without real device.
/// Implements both BleRemoteDataSource and BleCommDataSource.
class BleMockDataSource implements BleRemoteDataSource, BleCommDataSource {
  final UsageLocalDataSource? _usageLocalDataSource;
  late final DemoSessionGenerator? _sessionGenerator;

  final StreamController<BleConnectionState> _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<DeviceStatus> _deviceStatusController =
      StreamController<DeviceStatus>.broadcast();
  final StreamController<StatusUpdate> _statusUpdateController =
      StreamController<StatusUpdate>.broadcast();
  final StreamController<SessionStartNotification> _sessionStartController =
      StreamController<SessionStartNotification>.broadcast();
  final StreamController<SessionEndNotification> _sessionEndController =
      StreamController<SessionEndNotification>.broadcast();
  final StreamController<BatterySampleNotification> _batterySampleController =
      StreamController<BatterySampleNotification>.broadcast();

  DeviceStatus _currentStatus = DeviceStatus(
    shotType: ShotType.uShot,
    mode: DeviceMode.glow,
    level: DeviceLevel.level1,
    workingState: WorkingState.standby,
    batteryStatus: const BatteryStatus(
      level: 85,
      state: BatteryState.sufficient,
    ),
    warningStatus: const WarningStatus(),
    isCharging: false,
    timestamp: DateTime.now(),
  );

  Timer? _statusUpdateTimer;
  Timer? _sessionGeneratorTimer;
  final Random _random = Random();
  bool _isConnected = false;
  bool _isCommInitialized = false;

  BleMockDataSource({UsageLocalDataSource? usageLocalDataSource})
      : _usageLocalDataSource = usageLocalDataSource {
    _sessionGenerator = usageLocalDataSource != null
        ? DemoSessionGenerator(usageLocalDataSource)
        : null;
  }

  // ── BleRemoteDataSource ────────────────────────────────

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<DeviceStatus> get deviceStatusStream => _deviceStatusController.stream;

  @override
  Future<void> scanAndConnect() async {
    _connectionStateController.add(BleConnectionState.connecting);
    await Future.delayed(const Duration(seconds: 2));

    _isConnected = true;
    _connectionStateController.add(BleConnectionState.connected);
    _startStatusSimulation();
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    await scanAndConnect();
  }

  @override
  Future<void> disconnect() async {
    _connectionStateController.add(BleConnectionState.disconnecting);
    _isConnected = false;
    _isCommInitialized = false;
    _statusUpdateTimer?.cancel();
    _sessionGeneratorTimer?.cancel();
    _connectionStateController.add(BleConnectionState.disconnected);
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    return const DeviceInfoModel(
      deviceId: 'mock-device-001',
      deviceName: 'DualTetraX-MOCK',
      firmwareVersion: '1.0.0',
      modelName: 'DualTetraX',
      serialNumber: 'SN20240001',
      bleAddress: '00:11:22:33:44:55',
    );
  }

  @override
  Future<DeviceStatus> getCurrentStatus() async {
    return _currentStatus;
  }

  @override
  Future<void> refreshStatus() async {
    if (_isConnected) {
      _deviceStatusController.add(_currentStatus);
    }
  }

  // ── BleCommDataSource ──────────────────────────────────

  @override
  Future<void> initialize(BluetoothDevice device) async {
    _isCommInitialized = true;
    _startAutoSessionGeneration();
  }

  @override
  bool get isConnected => _isConnected && _isCommInitialized;

  @override
  Stream<StatusUpdate> get statusUpdates => _statusUpdateController.stream;

  @override
  Stream<SessionStartNotification> get sessionStartStream =>
      _sessionStartController.stream;

  @override
  Stream<SessionEndNotification> get sessionEndStream =>
      _sessionEndController.stream;

  @override
  Stream<BatterySampleNotification> get batterySampleStream =>
      _batterySampleController.stream;

  @override
  Future<ResponseStatus> sendTimeSync(int timestampMs) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return ResponseStatus.success;
  }

  @override
  Future<List<SessionSummary>> getSessions({int maxCount = 10, int filter = 0}) async {
    return [];
  }

  @override
  Future<Uint8List?> getSessionDetail(Uint8List uuid) async {
    return null;
  }

  @override
  Future<ResponseStatus> confirmSync(Uint8List uuid) async {
    return ResponseStatus.success;
  }

  @override
  Future<ResponseStatus> deleteSession(Uint8List uuid) async {
    return ResponseStatus.success;
  }

  @override
  Future<void> dispose() async {
    _statusUpdateTimer?.cancel();
    _sessionGeneratorTimer?.cancel();
    _connectionStateController.close();
    _deviceStatusController.close();
    _statusUpdateController.close();
    _sessionStartController.close();
    _sessionEndController.close();
    _batterySampleController.close();
  }

  // ── Simulation Logic ───────────────────────────────────

  void _startStatusSimulation() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      _simulateStatusChange();
      _deviceStatusController.add(_currentStatus);

      // Also emit StatusUpdate for BleCommDataSource consumers
      _statusUpdateController.add(StatusUpdate(
        shotType: _currentStatus.shotType.value,
        mode: _currentStatus.mode.value,
        level: _currentStatus.level.value,
        workingState: _currentStatus.workingState == WorkingState.working ? 1 : 3,
        batteryMv: _currentStatus.batteryStatus.level * 42, // ~4200mV at 100%
        batteryState: _currentStatus.batteryStatus.state.index,
        warning: 0,
        elapsedTime: 0,
        isCharging: _currentStatus.isCharging,
        isSessionActive: _currentStatus.workingState == WorkingState.working,
      ));
    });

    _deviceStatusController.add(_currentStatus);
  }

  void _startAutoSessionGeneration() {
    if (_sessionGenerator == null) return;

    _sessionGeneratorTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      final session = _sessionGenerator!.generateSingleSession();
      await _usageLocalDataSource!.insertSession(session);
    });
  }

  void _simulateStatusChange() {
    // Randomly toggle between working and standby
    if (_random.nextDouble() > 0.7) {
      _currentStatus = _currentStatus.copyWith(
        workingState: _currentStatus.workingState == WorkingState.working
            ? WorkingState.standby
            : WorkingState.working,
        timestamp: DateTime.now(),
      );
    }

    // Randomly change mode
    if (_random.nextDouble() > 0.8) {
      final modes = [
        DeviceMode.glow,
        DeviceMode.toneup,
        DeviceMode.renew,
        DeviceMode.volume,
      ];
      _currentStatus = _currentStatus.copyWith(
        mode: modes[_random.nextInt(modes.length)],
        timestamp: DateTime.now(),
      );
    }

    // Randomly change level
    if (_random.nextDouble() > 0.85) {
      final levels = [DeviceLevel.level1, DeviceLevel.level2, DeviceLevel.level3];
      _currentStatus = _currentStatus.copyWith(
        level: levels[_random.nextInt(levels.length)],
        timestamp: DateTime.now(),
      );
    }

    // Simulate battery drain
    if (_random.nextDouble() > 0.9) {
      final currentLevel = _currentStatus.batteryStatus.level;
      if (currentLevel > 20) {
        _currentStatus = _currentStatus.copyWith(
          batteryStatus: BatteryStatus(
            level: (currentLevel - _random.nextInt(5)).clamp(0, 100),
            state: _getBatteryState(currentLevel - 5),
          ),
          timestamp: DateTime.now(),
        );
      }
    }

    // Randomly trigger warnings
    if (_random.nextDouble() > 0.95) {
      _currentStatus = _currentStatus.copyWith(
        warningStatus: WarningStatus(
          temperatureWarning: _random.nextBool(),
          batteryLowWarning: _currentStatus.batteryStatus.level < 30,
          batteryCriticalWarning: _currentStatus.batteryStatus.level < 10,
        ),
        timestamp: DateTime.now(),
      );
    }
  }

  BatteryState _getBatteryState(int level) {
    if (level >= 50) return BatteryState.sufficient;
    if (level >= 20) return BatteryState.low;
    return BatteryState.critical;
  }
}
