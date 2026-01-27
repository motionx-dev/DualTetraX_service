import 'dart:async';
import 'dart:math';
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

/// BLE Mock Data Source for testing without real device
class BleMockDataSource implements BleRemoteDataSource {
  final StreamController<BleConnectionState> _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<DeviceStatus> _deviceStatusController =
      StreamController<DeviceStatus>.broadcast();

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
  final Random _random = Random();
  bool _isConnected = false;

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<DeviceStatus> get deviceStatusStream => _deviceStatusController.stream;

  @override
  Future<void> scanAndConnect() async {
    _connectionStateController.add(BleConnectionState.connecting);

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    _isConnected = true;
    _connectionStateController.add(BleConnectionState.connected);

    // Start simulating device status changes
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
    _statusUpdateTimer?.cancel();
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
    // In mock mode, just re-send the current status
    if (_isConnected) {
      _deviceStatusController.add(_currentStatus);
    }
  }

  void _startStatusSimulation() {
    // Update status every 5 seconds to simulate device state changes
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      // Randomly change device state
      _simulateStatusChange();
      _deviceStatusController.add(_currentStatus);
    });

    // Send initial status
    _deviceStatusController.add(_currentStatus);
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

  void dispose() {
    _statusUpdateTimer?.cancel();
    _connectionStateController.close();
    _deviceStatusController.close();
  }
}
