import 'dart:async';
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
import 'ble_comm_data_source.dart';

abstract class BleRemoteDataSource {
  Stream<BleConnectionState> get connectionStateStream;
  Stream<DeviceStatus> get deviceStatusStream;

  Future<void> scanAndConnect();
  Future<void> connectToDevice(String deviceId);
  Future<void> disconnect();
  Future<DeviceInfo> getDeviceInfo();
  Future<DeviceStatus> getCurrentStatus();
  Future<void> refreshStatus();
}

class BleRemoteDataSourceImpl implements BleRemoteDataSource {
  static const String deviceNamePrefix = 'DualTetraX-';

  // Standard BLE Device Info Service
  static final Guid deviceInfoServiceUuid = Guid('0000180a-0000-1000-8000-00805f9b34fb');
  static final Guid firmwareVersionUuid = Guid('00002a26-0000-1000-8000-00805f9b34fb');

  // NEW Communication Service (12340001) - Binary protocol
  static final Guid commServiceUuid = Guid('12340001-1234-1234-1234-123456789abc');
  static final Guid commTxCharUuid = Guid('12340002-1234-1234-1234-123456789abc');  // Notify
  static final Guid commRxCharUuid = Guid('12340003-1234-1234-1234-123456789abc');  // Write

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _txChar;
  StreamSubscription? _notifySubscription;

  final StreamController<BleConnectionState> _connectionStateController =
      StreamController<BleConnectionState>.broadcast();
  final StreamController<DeviceStatus> _deviceStatusController =
      StreamController<DeviceStatus>.broadcast();

  DeviceStatus? _currentStatus;

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

    // Find and subscribe to Communication Service (NEW service)
    await _subscribeToCommService(services);
  }

  /// Subscribe to NEW Communication Service (12340001) for status updates
  Future<void> _subscribeToCommService(List<BluetoothService> services) async {
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == commServiceUuid.toString().toLowerCase()) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == commTxCharUuid.toString().toLowerCase()) {
            _txChar = char;
          }
        }
      }
    }

    if (_txChar == null) {
      print('[BLE] Warning: Communication service TX characteristic not found');
      return;
    }

    // Subscribe to TX notifications (status updates from device)
    await _txChar!.setNotifyValue(true);
    _notifySubscription = _txChar!.onValueReceived.listen(_handleNotification);

    print('[BLE] Subscribed to Communication Service (12340001)');
  }

  /// Handle notifications from NEW Communication Service
  void _handleNotification(List<int> data) {
    if (data.length < 4) return;

    final bytes = Uint8List.fromList(data);
    final msgType = bytes[0];
    final payloadLen = bytes[1] | (bytes[2] << 8);

    // Verify frame length
    if (bytes.length < 3 + payloadLen + 1) return;

    // Verify CRC (XOR of all bytes except last)
    int crc = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      crc ^= bytes[i];
    }
    if (crc != bytes[bytes.length - 1]) {
      print('[BLE] CRC mismatch, ignoring packet');
      return;
    }

    final payload = bytes.sublist(3, 3 + payloadLen);

    // Handle STATUS_UPDATE (0x01)
    if (msgType == 0x01 && payload.length >= 12) {
      try {
        final status = StatusUpdate.fromBytes(Uint8List.fromList(payload));
        _updateStatusFromPayload(status);
      } catch (e) {
        print('[BLE] Error parsing status update: $e');
      }
    }
  }

  /// Convert StatusUpdate from binary protocol to DeviceStatus
  void _updateStatusFromPayload(StatusUpdate status) {
    // Convert battery mV to percentage (simple linear mapping)
    int batteryPercent;
    if (status.batteryMv >= 4200) {
      batteryPercent = 100;
    } else if (status.batteryMv <= 3200) {
      batteryPercent = 0;
    } else {
      batteryPercent = ((status.batteryMv - 3200) * 100 ~/ 1000);
    }

    _currentStatus = DeviceStatus(
      shotType: ShotType.fromValue(status.shotType),
      mode: DeviceMode.fromValue(status.mode),
      level: DeviceLevel.fromValue(status.level),
      workingState: WorkingState.fromValue(status.workingState),
      batteryStatus: BatteryStatus(
        level: batteryPercent,
        state: BatteryState.fromValue(status.batteryState),
      ),
      warningStatus: WarningStatus.fromByte(status.warning),
      isCharging: status.isCharging,
      currentWorkingTime: status.elapsedTime,
      timestamp: DateTime.now(),
    );

    _deviceStatusController.add(_currentStatus!);
  }

  @override
  Future<void> refreshStatus() async {
    // Status updates are pushed automatically via notifications
    // No action needed - just wait for next status update
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
    _notifySubscription?.cancel();
    _notifySubscription = null;
    _txChar = null;
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
