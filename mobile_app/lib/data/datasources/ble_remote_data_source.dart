import 'dart:async';
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

// Helper class to buffer notifications during initialization
class _BufferedNotification {
  final Guid characteristicUuid;
  final List<int> value;

  _BufferedNotification(this.characteristicUuid, this.value);
}

abstract class BleRemoteDataSource {
  Stream<BleConnectionState> get connectionStateStream;
  Stream<DeviceStatus> get deviceStatusStream;

  Future<void> scanAndConnect();
  Future<void> connectToDevice(String deviceId);
  Future<void> disconnect();
  Future<DeviceInfo> getDeviceInfo();
  Future<DeviceStatus> getCurrentStatus();
  Future<void> refreshStatus();  // Re-read all characteristic values
}

class BleRemoteDataSourceImpl implements BleRemoteDataSource {
  static const String deviceNamePrefix = 'DualTetraX-';

  // Service UUIDs (these should match DualTetraX firmware)
  // TODO: Replace with actual UUIDs from DualTetraX firmware
  static final Guid deviceInfoServiceUuid = Guid('0000180a-0000-1000-8000-00805f9b34fb');
  static final Guid realtimeStatusServiceUuid = Guid('12340000-1234-1234-1234-123456789abc');

  // Characteristic UUIDs (examples - should match firmware)
  static final Guid firmwareVersionUuid = Guid('00002a26-0000-1000-8000-00805f9b34fb');
  static final Guid shotTypeUuid = Guid('12340001-1234-1234-1234-123456789abc');
  static final Guid modeUuid = Guid('12340002-1234-1234-1234-123456789abc');
  static final Guid levelUuid = Guid('12340003-1234-1234-1234-123456789abc');
  static final Guid workingStateUuid = Guid('12340004-1234-1234-1234-123456789abc');
  static final Guid batteryStatusUuid = Guid('12340005-1234-1234-1234-123456789abc');
  static final Guid warningStatusUuid = Guid('12340006-1234-1234-1234-123456789abc');
  static final Guid elapsedTimeUuid = Guid('12340007-1234-1234-1234-123456789abc');

  BluetoothDevice? _connectedDevice;
  final StreamController<BleConnectionState> _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<DeviceStatus> _deviceStatusController =
      StreamController<DeviceStatus>.broadcast();

  DeviceStatus? _currentStatus;
  List<StreamSubscription> _characteristicSubscriptions = [];

  // Flag to prevent emission during initial value reading
  bool _isInitializing = false;

  // Buffer for notifications received during initialization
  final List<_BufferedNotification> _notificationBuffer = [];

  // Public getter for connected device (used by OTA service)
  BluetoothDevice? get connectedDevice => _connectedDevice;

  @override
  Stream<BleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<DeviceStatus> get deviceStatusStream => _deviceStatusController.stream;

  @override
  Future<void> scanAndConnect() async {
    _connectionStateController.add(BleConnectionState.connecting);

    try {
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      // Listen for scan results
      final completer = Completer<void>();
      late StreamSubscription subscription;

      subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (final result in results) {
          if (result.device.platformName.startsWith(deviceNamePrefix)) {
            // Found DualTetraX device
            await FlutterBluePlus.stopScan();
            subscription.cancel();

            try {
              await _connect(result.device);
              completer.complete();
            } catch (e) {
              completer.completeError(e);
            }
            return;
          }
        }
      });

      // Wait for connection or timeout
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          subscription.cancel();
          FlutterBluePlus.stopScan();
          throw Exception('Device not found');
        },
      );
    } catch (e) {
      _connectionStateController.add(BleConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    // TODO: Implement connecting to specific device by ID
    throw UnimplementedError();
  }

  Future<void> _connect(BluetoothDevice device) async {
    _connectedDevice = device;
    print('[BLE] _connect: hash=$hashCode, device=$_connectedDevice');

    // Connect to device
    await device.connect(timeout: const Duration(seconds: 10));

    // Emit connected state immediately after successful connection
    _connectionStateController.add(BleConnectionState.connected);

    // Listen for future disconnection events
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectionStateController.add(BleConnectionState.disconnected);
        _cleanup();
      }
    });

    // Discover services
    final services = await device.discoverServices();

    // Subscribe to characteristics
    await _subscribeToCharacteristics(services);
  }

  Future<void> _subscribeToCharacteristics(
      List<BluetoothService> services) async {
    // Prevent notifications from emitting during initialization
    _isInitializing = true;
    _notificationBuffer.clear();

    for (final service in services) {
      if (service.uuid == realtimeStatusServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            // Subscribe to notifications
            await characteristic.setNotifyValue(true);
            final subscription =
                characteristic.lastValueStream.listen((value) {
              if (_isInitializing) {
                // Buffer notifications during initialization
                _notificationBuffer.add(_BufferedNotification(characteristic.uuid, value));
              } else {
                // Normal operation - emit immediately
                _handleCharacteristicUpdate(characteristic.uuid, value, emit: true);
              }
            });
            _characteristicSubscriptions.add(subscription);
          }
        }
      }
    }

    // Read initial values - emit once after all values are read
    await _readInitialValues(services, emitAfterAll: true);

    // Process any buffered notifications (update state but don't emit - we already emitted)
    for (final notification in _notificationBuffer) {
      _handleCharacteristicUpdate(notification.characteristicUuid, notification.value, emit: false);
    }
    _notificationBuffer.clear();

    // Allow notifications to emit after initialization is complete
    _isInitializing = false;
  }

  Future<void> _readInitialValues(List<BluetoothService> services, {bool emitAfterAll = false}) async {
    for (final service in services) {
      if (service.uuid == realtimeStatusServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.read) {
            try {
              final value = await characteristic.read();
              if (value.isNotEmpty) {
                _handleCharacteristicUpdate(characteristic.uuid, value, emit: !emitAfterAll);
              }
            } catch (e) {
              // Ignore read errors
            }
          }
        }
      }
    }

    // Emit once after all values are read
    if (emitAfterAll && _currentStatus != null) {
      _deviceStatusController.add(_currentStatus!);
    }
  }

  @override
  Future<void> refreshStatus() async {
    if (_connectedDevice == null) {
      return;
    }

    try {
      // Prevent notifications from emitting during refresh
      _isInitializing = true;
      _notificationBuffer.clear();

      final services = await _connectedDevice!.discoverServices();
      // Read all values then emit once at the end
      await _readInitialValues(services, emitAfterAll: true);

      // Process any buffered notifications (update state but don't emit)
      for (final notification in _notificationBuffer) {
        _handleCharacteristicUpdate(notification.characteristicUuid, notification.value, emit: false);
      }
      _notificationBuffer.clear();

      _isInitializing = false;
    } catch (e) {
      _notificationBuffer.clear();
      _isInitializing = false;
      // Ignore refresh errors
    }
  }

  void _handleCharacteristicUpdate(Guid characteristicUuid, List<int> value, {bool emit = true}) {
    if (_currentStatus == null) {
      _currentStatus = DeviceStatus(
        shotType: ShotType.unknown,
        mode: DeviceMode.unknown,
        level: DeviceLevel.unknown,
        workingState: WorkingState.off,
        batteryStatus: const BatteryStatus(
          level: 0,
          state: BatteryState.sufficient,
        ),
        warningStatus: const WarningStatus(),
        isCharging: false,
        timestamp: DateTime.now(),
      );
    }

    if (characteristicUuid == shotTypeUuid && value.isNotEmpty) {
      _currentStatus = _currentStatus!.copyWith(
        shotType: ShotType.fromValue(value[0]),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == modeUuid && value.isNotEmpty) {
      _currentStatus = _currentStatus!.copyWith(
        mode: DeviceMode.fromValue(value[0]),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == levelUuid && value.isNotEmpty) {
      _currentStatus = _currentStatus!.copyWith(
        level: DeviceLevel.fromValue(value[0]),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == workingStateUuid && value.isNotEmpty) {
      _currentStatus = _currentStatus!.copyWith(
        workingState: WorkingState.fromValue(value[0]),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == batteryStatusUuid && value.length >= 2) {
      _currentStatus = _currentStatus!.copyWith(
        batteryStatus: BatteryStatus(
          level: value[0],
          state: BatteryState.fromValue(value[1]),
        ),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == warningStatusUuid && value.isNotEmpty) {
      _currentStatus = _currentStatus!.copyWith(
        warningStatus: WarningStatus.fromByte(value[0]),
        timestamp: DateTime.now(),
      );
    } else if (characteristicUuid == elapsedTimeUuid && value.length >= 2) {
      // Elapsed time is sent as 2 bytes (little-endian uint16_t in seconds)
      final elapsedSeconds = value[0] | (value[1] << 8);
      _currentStatus = _currentStatus!.copyWith(
        currentWorkingTime: elapsedSeconds,
        timestamp: DateTime.now(),
      );
    }

    if (emit) {
      _deviceStatusController.add(_currentStatus!);
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      _connectionStateController.add(BleConnectionState.disconnecting);
      await _connectedDevice!.disconnect();
      _cleanup();
    }
  }

  void _cleanup() {
    for (final subscription in _characteristicSubscriptions) {
      subscription.cancel();
    }
    _characteristicSubscriptions.clear();
    _connectedDevice = null;
    _currentStatus = null;
    _isInitializing = false;
    _notificationBuffer.clear();
  }

  @override
  Future<DeviceInfo> getDeviceInfo() async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to device');
    }

    final services = await _connectedDevice!.discoverServices();
    String firmwareVersion = 'Unknown';
    String modelName = 'DualTetraX';
    String serialNumber = 'Unknown';

    for (final service in services) {
      if (service.uuid == deviceInfoServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == firmwareVersionUuid) {
            final value = await characteristic.read();
            firmwareVersion = String.fromCharCodes(value);
          }
        }
      }
    }

    return DeviceInfoModel(
      deviceId: _connectedDevice!.remoteId.toString(),
      deviceName: _connectedDevice!.platformName,
      firmwareVersion: firmwareVersion,
      modelName: modelName,
      serialNumber: serialNumber,
      bleAddress: _connectedDevice!.remoteId.toString(),
    );
  }

  @override
  Future<DeviceStatus> getCurrentStatus() async {
    if (_currentStatus == null) {
      throw Exception('Status not available');
    }
    return _currentStatus!;
  }

  void dispose() {
    _cleanup();
    _connectionStateController.close();
    _deviceStatusController.close();
  }
}
