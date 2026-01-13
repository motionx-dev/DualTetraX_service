import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../domain/entities/ota_status.dart';
import '../../domain/entities/firmware_info.dart';
import '../../domain/repositories/ota_repository.dart';
import '../datasources/ble_ota_data_source.dart';
import '../datasources/local_firmware_data_source.dart';

/// Implementation of OTA Repository
class OtaRepositoryImpl implements OtaRepository {
  final BleOtaDataSource _bleOtaDataSource;
  final LocalFirmwareDataSource _localFirmwareDataSource;
  final BluetoothDevice? Function() _getConnectedDevice;

  static const int chunkSize = 240; // Match firmware MAX_CHUNK_SIZE

  FirmwareInfo? _currentFirmware;
  int _currentChunkIndex = 0;
  int _totalChunks = 0;

  OtaRepositoryImpl({
    required BleOtaDataSource bleOtaDataSource,
    required LocalFirmwareDataSource localFirmwareDataSource,
    required BluetoothDevice? Function() getConnectedDevice,
  })  : _bleOtaDataSource = bleOtaDataSource,
        _localFirmwareDataSource = localFirmwareDataSource,
        _getConnectedDevice = getConnectedDevice;

  @override
  Stream<OtaStatus> get otaStatusStream => _bleOtaDataSource.otaStatusStream;

  @override
  Future<FirmwareInfo?> pickLocalFirmware() async {
    return await _localFirmwareDataSource.pickFirmwareFile();
  }

  @override
  Future<void> initializeOtaService() async {
    final device = _getConnectedDevice();
    print('[OTA Repo] getConnectedDevice returned: $device');
    if (device == null) {
      throw Exception('No device connected');
    }
    await _bleOtaDataSource.initialize(device);
  }

  @override
  Future<bool> isOtaAvailable() async {
    return await _bleOtaDataSource.isOtaServiceAvailable();
  }

  @override
  Future<void> startOtaUpdate(FirmwareInfo firmware) async {
    _currentFirmware = firmware;
    _currentChunkIndex = 0;
    _totalChunks = firmware.chunkCount;

    await _bleOtaDataSource.startOta(firmware);
  }

  @override
  Future<bool> sendNextChunk() async {
    if (_currentFirmware == null || _currentFirmware!.path == null) {
      throw Exception('No firmware loaded');
    }

    if (_currentChunkIndex >= _totalChunks) {
      return false; // All chunks sent
    }

    // Read chunk from file
    final chunkData = await _localFirmwareDataSource.getChunk(
      _currentFirmware!.path!,
      _currentChunkIndex,
      chunkSize,
    );

    // Send chunk via BLE
    await _bleOtaDataSource.sendChunk(_currentChunkIndex, chunkData);

    _currentChunkIndex++;

    // Small delay to prevent overwhelming the BLE stack
    await Future.delayed(const Duration(milliseconds: 10));

    return _currentChunkIndex < _totalChunks;
  }

  @override
  Future<void> finishOtaUpdate() async {
    await _bleOtaDataSource.finishOta();
  }

  @override
  Future<void> cancelOtaUpdate() async {
    await _bleOtaDataSource.cancelOta();
    _reset();
  }

  @override
  int get currentProgress {
    if (_totalChunks == 0) return 0;
    return (_currentChunkIndex * 100) ~/ _totalChunks;
  }

  @override
  void dispose() {
    _bleOtaDataSource.dispose();
    _reset();
  }

  void _reset() {
    _currentFirmware = null;
    _currentChunkIndex = 0;
    _totalChunks = 0;
  }
}
