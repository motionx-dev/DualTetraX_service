import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/ota_status.dart';
import '../../domain/entities/firmware_info.dart';

/// OTA control commands matching firmware BleOtaService::Command
class OtaCommand {
  static const int start = 0x01;
  static const int finish = 0x02;
  static const int cancel = 0x03;
  static const int getInfo = 0x04;
}

/// Abstract interface for BLE OTA operations
abstract class BleOtaDataSource {
  /// Stream of OTA status updates from device
  Stream<OtaStatus> get otaStatusStream;

  /// Initialize OTA service with connected device
  Future<void> initialize(BluetoothDevice device);

  /// Dispose resources
  void dispose();

  /// Check if OTA service is available on device
  Future<bool> isOtaServiceAvailable();

  /// Start OTA update with firmware info
  Future<void> startOta(FirmwareInfo firmware);

  /// Send firmware data chunk
  Future<void> sendChunk(int index, Uint8List data);

  /// Finish OTA (trigger validation and apply)
  Future<void> finishOta();

  /// Cancel ongoing OTA
  Future<void> cancelOta();

  /// Request current OTA info/status
  Future<void> requestInfo();
}

/// Implementation of BLE OTA DataSource
class BleOtaDataSourceImpl implements BleOtaDataSource {
  // OTA Service UUID: 12341111-1234-1234-1234-123456789abc
  static final Guid otaServiceUuid =
      Guid('12341111-1234-1234-1234-123456789abc');

  // Characteristic UUIDs
  static final Guid otaControlUuid =
      Guid('12341101-1234-1234-1234-123456789abc'); // Write
  static final Guid otaStatusUuid =
      Guid('12341102-1234-1234-1234-123456789abc'); // Read/Notify
  static final Guid otaDataUuid =
      Guid('12341103-1234-1234-1234-123456789abc'); // Write No Response

  BluetoothDevice? _device;
  BluetoothService? _otaService;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _dataChar;

  StreamSubscription<List<int>>? _statusSubscription;
  final StreamController<OtaStatus> _statusController =
      StreamController<OtaStatus>.broadcast();

  @override
  Stream<OtaStatus> get otaStatusStream => _statusController.stream;

  @override
  Future<void> initialize(BluetoothDevice device) async {
    _device = device;

    // Discover services if not already done
    List<BluetoothService> services = await device.discoverServices();

    // Debug: log all discovered services
    print('[OTA] Discovered ${services.length} services:');
    for (final service in services) {
      print('[OTA]   Service: ${service.uuid}');
    }
    print('[OTA] Looking for OTA service: $otaServiceUuid');

    // Find OTA service
    for (final service in services) {
      if (service.uuid == otaServiceUuid) {
        _otaService = service;
        break;
      }
    }

    if (_otaService == null) {
      throw Exception('OTA service not found on device. Available: ${services.map((s) => s.uuid).toList()}');
    }

    // Find characteristics
    for (final char in _otaService!.characteristics) {
      if (char.uuid == otaControlUuid) {
        _controlChar = char;
      } else if (char.uuid == otaStatusUuid) {
        _statusChar = char;
      } else if (char.uuid == otaDataUuid) {
        _dataChar = char;
      }
    }

    if (_controlChar == null || _statusChar == null || _dataChar == null) {
      throw Exception('OTA characteristics not found');
    }

    // Subscribe to status notifications
    await _statusChar!.setNotifyValue(true);
    _statusSubscription = _statusChar!.onValueReceived.listen((value) {
      if (value.isNotEmpty) {
        final status = OtaStatus.fromBytes(value);
        _statusController.add(status);
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _statusController.close();
    _device = null;
    _otaService = null;
    _controlChar = null;
    _statusChar = null;
    _dataChar = null;
  }

  @override
  Future<bool> isOtaServiceAvailable() async {
    return _otaService != null;
  }

  @override
  Future<void> startOta(FirmwareInfo firmware) async {
    if (_controlChar == null) {
      throw Exception('OTA control characteristic not available');
    }

    // Build START command: [cmd(1), size(4), chunk_count(4)]
    final data = ByteData(9);
    data.setUint8(0, OtaCommand.start);
    data.setUint32(1, firmware.size, Endian.little);
    data.setUint32(5, firmware.chunkCount, Endian.little);

    await _controlChar!.write(data.buffer.asUint8List(), withoutResponse: false);
  }

  @override
  Future<void> sendChunk(int index, Uint8List chunkData) async {
    if (_dataChar == null) {
      throw Exception('OTA data characteristic not available');
    }

    // Build chunk packet: [index(4), data(...)]
    final packet = ByteData(4 + chunkData.length);
    packet.setUint32(0, index, Endian.little);
    for (int i = 0; i < chunkData.length; i++) {
      packet.setUint8(4 + i, chunkData[i]);
    }

    // Write without response for faster throughput
    await _dataChar!.write(packet.buffer.asUint8List(), withoutResponse: true);
  }

  @override
  Future<void> finishOta() async {
    if (_controlChar == null) {
      throw Exception('OTA control characteristic not available');
    }

    await _controlChar!.write([OtaCommand.finish], withoutResponse: false);
  }

  @override
  Future<void> cancelOta() async {
    if (_controlChar == null) {
      throw Exception('OTA control characteristic not available');
    }

    await _controlChar!.write([OtaCommand.cancel], withoutResponse: false);
  }

  @override
  Future<void> requestInfo() async {
    if (_controlChar == null) {
      throw Exception('OTA control characteristic not available');
    }

    await _controlChar!.write([OtaCommand.getInfo], withoutResponse: false);
  }
}
