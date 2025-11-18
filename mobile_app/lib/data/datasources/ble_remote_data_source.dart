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

abstract class BleRemoteDataSource {
  Stream<BleConnectionState> get connectionStateStream;
  Stream<DeviceStatus> get deviceStatusStream;

  Future<void> scanAndConnect();
  Future<void> connectToDevice(String deviceId);
  Future<void> disconnect();
  Future<DeviceInfo> getDeviceInfo();
  Future<DeviceStatus> getCurrentStatus();
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

  BluetoothDevice? _connectedDevice;
  final StreamController<BleConnectionState> _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<DeviceStatus> _deviceStatusController =
      StreamController<DeviceStatus>.broadcast();

  DeviceStatus? _currentStatus;
  List<StreamSubscription> _characteristicSubscriptions = [];

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

    // Listen to connection state
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _connectionStateController.add(BleConnectionState.connected);
      } else if (state == BluetoothConnectionState.disconnected) {
        _connectionStateController.add(BleConnectionState.disconnected);
        _cleanup();
      }
    });

    // Connect to device
    await device.connect(timeout: const Duration(seconds: 10));

    // Discover services
    final services = await device.discoverServices();

    // Subscribe to characteristics
    await _subscribeToCharacteristics(services);
  }

  Future<void> _subscribeToCharacteristics(
      List<BluetoothService> services) async {
    for (final service in services) {
      if (service.uuid == realtimeStatusServiceUuid) {
        for (final characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            // Subscribe to notifications
            await characteristic.setNotifyValue(true);
            final subscription =
                characteristic.lastValueStream.listen((value) {
              _handleCharacteristicUpdate(characteristic.uuid, value);
            });
            _characteristicSubscriptions.add(subscription);
          }
        }
      }
    }

    // Read initial values
    await _readInitialValues(services);
  }

  Future<void> _readInitialValues(List<BluetoothService> services) async {
    // Read current status values
    // TODO: Implement reading initial characteristic values
  }

  void _handleCharacteristicUpdate(Guid characteristicUuid, List<int> value) {
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
    }

    _deviceStatusController.add(_currentStatus!);
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
