import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Message types for BLE communication (TX: Device -> App)
enum TxMsgType {
  statusUpdate(0x01),
  sessionStart(0x02),
  sessionEnd(0x03),
  batterySample(0x04),
  // Response types start at 0x80+
  timeSyncResponse(0x90),
  getSessionsResponse(0x91),
  getSessionDetailResponse(0x92),
  confirmSyncResponse(0x93),
  deleteSessionResponse(0x94);

  const TxMsgType(this.value);
  final int value;

  static TxMsgType? fromValue(int value) {
    for (final type in TxMsgType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// Message types for BLE communication (RX: App -> Device)
enum RxMsgType {
  timeSync(0x10),
  getSessions(0x11),
  getSessionDetail(0x12),
  confirmSync(0x13),
  deleteSession(0x14);

  const RxMsgType(this.value);
  final int value;
}

/// Response status codes
enum ResponseStatus {
  success(0x00),
  invalidType(0x01),
  invalidLength(0x02),
  invalidParam(0x03),
  notFound(0x04),
  busy(0x05),
  error(0xFF);

  const ResponseStatus(this.value);
  final int value;

  static ResponseStatus fromValue(int value) {
    for (final status in ResponseStatus.values) {
      if (status.value == value) return status;
    }
    return ResponseStatus.error;
  }
}

/// Status update payload from device (12 bytes)
/// Matches firmware StatusUpdatePayload structure
class StatusUpdate {
  final int shotType;       // 0=Unknown, 1=U-Shot, 2=E-Shot, 3=LED
  final int mode;           // Current mode (1-8)
  final int level;          // Current level (1-3)
  final int workingState;   // 0=OFF, 1=WORKING, 2=PAUSE, 3=STANDBY
  final int batteryMv;      // Battery voltage in mV
  final int batteryState;   // 0=SUFFICIENT, 1=LOW, 2=CRITICAL
  final int warning;        // Warning flags
  final int elapsedTime;    // Elapsed time in seconds
  final bool isCharging;
  final bool isSessionActive;

  StatusUpdate({
    required this.shotType,
    required this.mode,
    required this.level,
    required this.workingState,
    required this.batteryMv,
    required this.batteryState,
    required this.warning,
    required this.elapsedTime,
    required this.isCharging,
    required this.isSessionActive,
  });

  factory StatusUpdate.fromBytes(Uint8List data) {
    if (data.length < 12) {
      throw FormatException('StatusUpdate requires at least 12 bytes, got ${data.length}');
    }
    return StatusUpdate(
      shotType: data[0],
      mode: data[1],
      level: data[2],
      workingState: data[3],
      batteryMv: data[4] | (data[5] << 8),
      batteryState: data[6],
      warning: data[7],
      elapsedTime: data[8] | (data[9] << 8),
      isCharging: (data[10] & 0x01) != 0,
      isSessionActive: (data[10] & 0x02) != 0,
    );
  }
}

/// Session summary for list display
class SessionSummary {
  final Uint8List uuid;
  final int startTimeMs;
  final int durationS;
  final int featureType;
  final int mode;
  final int level;
  final int syncStatus;

  SessionSummary({
    required this.uuid,
    required this.startTimeMs,
    required this.durationS,
    required this.featureType,
    required this.mode,
    required this.level,
    required this.syncStatus,
  });

  factory SessionSummary.fromBytes(Uint8List data) {
    if (data.length < 32) {
      throw FormatException('SessionSummary requires 32 bytes');
    }
    final byteData = ByteData.sublistView(data);
    return SessionSummary(
      uuid: data.sublist(0, 16),
      startTimeMs: byteData.getUint64(16, Endian.little),
      durationS: byteData.getUint16(24, Endian.little),
      featureType: data[26],
      mode: data[27],
      level: data[28],
      syncStatus: data[29],
    );
  }
}

/// Session start notification from device
class SessionStartNotification {
  final String uuid;
  final int featureType;    // 1=U-Shot, 2=E-Shot, 3=LED
  final int mode;           // U-Shot: 0x01-0x04, E-Shot: 0x11-0x14, LED: 0x21
  final int level;          // 1-3
  final int ledPattern;
  final int startBatteryMV;
  final DateTime timestamp;

  SessionStartNotification({
    required this.uuid,
    required this.featureType,
    required this.mode,
    required this.level,
    required this.ledPattern,
    required this.startBatteryMV,
    required this.timestamp,
  });

  factory SessionStartNotification.fromBytes(Uint8List data) {
    if (data.length < 24) {
      throw FormatException('SessionStartNotification requires at least 24 bytes');
    }
    return SessionStartNotification(
      uuid: _bytesToUuidString(data.sublist(0, 16)),
      featureType: data[16],
      mode: data[17],
      level: data[18],
      ledPattern: data[19],
      startBatteryMV: data[20] | (data[21] << 8),
      timestamp: DateTime.now(),
    );
  }
}

/// Session end notification from device
class SessionEndNotification {
  final String uuid;
  final int endTimeMs;
  final int workingDurationSeconds;
  final int pauseDurationSeconds;
  final int pauseCount;
  final int terminationReason;
  final int completionPercent;
  final int endBatteryMV;
  final int batterySampleCount;
  final DateTime timestamp;

  SessionEndNotification({
    required this.uuid,
    required this.endTimeMs,
    required this.workingDurationSeconds,
    required this.pauseDurationSeconds,
    required this.pauseCount,
    required this.terminationReason,
    required this.completionPercent,
    required this.endBatteryMV,
    required this.batterySampleCount,
    required this.timestamp,
  });

  factory SessionEndNotification.fromBytes(Uint8List data) {
    if (data.length < 40) {
      throw FormatException('SessionEndNotification requires at least 40 bytes');
    }
    final byteData = ByteData.sublistView(data);
    return SessionEndNotification(
      uuid: _bytesToUuidString(data.sublist(0, 16)),
      endTimeMs: byteData.getUint64(16, Endian.little),
      workingDurationSeconds: byteData.getUint16(24, Endian.little),
      pauseDurationSeconds: byteData.getUint16(26, Endian.little),
      pauseCount: data[28],
      terminationReason: data[29],
      completionPercent: data[30],
      endBatteryMV: byteData.getUint16(31, Endian.little),
      batterySampleCount: data[33],
      timestamp: DateTime.now(),
    );
  }
}

/// Battery sample notification from device
class BatterySampleNotification {
  final String sessionUuid;
  final int elapsedSeconds;
  final int voltageMV;
  final int batteryState;
  final int sampleIndex;

  BatterySampleNotification({
    required this.sessionUuid,
    required this.elapsedSeconds,
    required this.voltageMV,
    required this.batteryState,
    required this.sampleIndex,
  });

  factory BatterySampleNotification.fromBytes(Uint8List data) {
    if (data.length < 22) {
      throw FormatException('BatterySampleNotification requires at least 22 bytes');
    }
    return BatterySampleNotification(
      sessionUuid: _bytesToUuidString(data.sublist(0, 16)),
      elapsedSeconds: data[16] | (data[17] << 8),
      voltageMV: data[18] | (data[19] << 8),
      batteryState: data[20],
      sampleIndex: data[21],
    );
  }
}

/// Convert UUID bytes to string format
String _bytesToUuidString(Uint8List bytes) {
  if (bytes.length != 16) return '';
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// BLE Communication Service UUIDs
class BleCommUuids {
  static const String service = '12340001-1234-1234-1234-123456789abc';
  static const String txChar = '12340002-1234-1234-1234-123456789abc';
  static const String rxChar = '12340003-1234-1234-1234-123456789abc';
}

/// Abstract interface for BLE communication data source
abstract class BleCommDataSource {
  /// Initialize with a connected device
  Future<void> initialize(BluetoothDevice device);

  /// Disconnect from device
  Future<void> disconnect();

  /// Dispose resources (call when no longer needed)
  Future<void> dispose();

  /// Check if connected
  bool get isConnected;

  /// Stream of status updates
  Stream<StatusUpdate> get statusUpdates;

  /// Stream of session start notifications
  Stream<SessionStartNotification> get sessionStartStream;

  /// Stream of session end notifications
  Stream<SessionEndNotification> get sessionEndStream;

  /// Stream of battery sample notifications
  Stream<BatterySampleNotification> get batterySampleStream;

  /// Send time sync to device
  Future<ResponseStatus> sendTimeSync(int timestampMs);

  /// Get session list from device
  Future<List<SessionSummary>> getSessions({int maxCount = 10, int filter = 0});

  /// Get session detail by UUID
  Future<Uint8List?> getSessionDetail(Uint8List uuid);

  /// Confirm session synced
  Future<ResponseStatus> confirmSync(Uint8List uuid);

  /// Delete session from device
  Future<ResponseStatus> deleteSession(Uint8List uuid);
}

/// Implementation of BLE communication data source
class BleCommDataSourceImpl implements BleCommDataSource {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _txChar;
  BluetoothCharacteristic? _rxChar;
  StreamSubscription? _notifySubscription;

  final _statusController = StreamController<StatusUpdate>.broadcast();
  final _responseController = StreamController<Uint8List>.broadcast();
  final _sessionStartController = StreamController<SessionStartNotification>.broadcast();
  final _sessionEndController = StreamController<SessionEndNotification>.broadcast();
  final _batterySampleController = StreamController<BatterySampleNotification>.broadcast();

  static const _responseTimeout = Duration(seconds: 5);

  @override
  bool get isConnected => _device != null && _txChar != null && _rxChar != null;

  @override
  Stream<StatusUpdate> get statusUpdates => _statusController.stream;

  @override
  Stream<SessionStartNotification> get sessionStartStream => _sessionStartController.stream;

  @override
  Stream<SessionEndNotification> get sessionEndStream => _sessionEndController.stream;

  @override
  Stream<BatterySampleNotification> get batterySampleStream => _batterySampleController.stream;

  @override
  Future<void> initialize(BluetoothDevice device) async {
    _device = device;

    // Discover services
    final services = await device.discoverServices();

    // Find our communication service
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == BleCommUuids.service.toLowerCase()) {
        for (final char in service.characteristics) {
          final uuid = char.uuid.toString().toLowerCase();
          if (uuid == BleCommUuids.txChar.toLowerCase()) {
            _txChar = char;
          } else if (uuid == BleCommUuids.rxChar.toLowerCase()) {
            _rxChar = char;
          }
        }
      }
    }

    if (_txChar == null || _rxChar == null) {
      throw Exception('BLE Communication service not found on device');
    }

    // Subscribe to TX characteristic notifications
    await _txChar!.setNotifyValue(true);
    _notifySubscription = _txChar!.onValueReceived.listen(_handleNotification);
  }

  @override
  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;

    if (_txChar != null) {
      try {
        await _txChar!.setNotifyValue(false);
      } catch (_) {}
    }

    _txChar = null;
    _rxChar = null;
    _device = null;
  }

  /// Dispose resources (call when no longer needed)
  @override
  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
    await _responseController.close();
    await _sessionStartController.close();
    await _sessionEndController.close();
    await _batterySampleController.close();
  }

  void _handleNotification(List<int> data) {
    if (data.length < 4) return;

    final bytes = Uint8List.fromList(data);
    final msgType = bytes[0];
    final payloadLen = bytes[1] | (bytes[2] << 8);

    // Verify frame length
    if (bytes.length < 3 + payloadLen + 1) return;

    // Verify CRC
    int crc = 0;
    for (int i = 0; i < bytes.length - 1; i++) {
      crc ^= bytes[i];
    }
    if (crc != bytes[bytes.length - 1]) {
      return; // CRC mismatch
    }

    final payload = bytes.sublist(3, 3 + payloadLen);

    // Route message
    final type = TxMsgType.fromValue(msgType);
    if (type == null) return;

    switch (type) {
      case TxMsgType.statusUpdate:
        try {
          final status = StatusUpdate.fromBytes(payload);
          _statusController.add(status);
        } catch (_) {}
        break;

      case TxMsgType.sessionStart:
        try {
          final notification = SessionStartNotification.fromBytes(payload);
          _sessionStartController.add(notification);
          print('[BLE] Session started: ${notification.uuid}');
        } catch (e) {
          print('[BLE] Error parsing session start: $e');
        }
        break;

      case TxMsgType.sessionEnd:
        try {
          final notification = SessionEndNotification.fromBytes(payload);
          _sessionEndController.add(notification);
          print('[BLE] Session ended: ${notification.uuid}, duration=${notification.workingDurationSeconds}s');
        } catch (e) {
          print('[BLE] Error parsing session end: $e');
        }
        break;

      case TxMsgType.batterySample:
        try {
          final notification = BatterySampleNotification.fromBytes(payload);
          _batterySampleController.add(notification);
          print('[BLE] Battery sample: index=${notification.sampleIndex}, ${notification.voltageMV}mV');
        } catch (e) {
          print('[BLE] Error parsing battery sample: $e');
        }
        break;

      // Response messages (0x90-0x94)
      case TxMsgType.timeSyncResponse:
      case TxMsgType.getSessionsResponse:
      case TxMsgType.getSessionDetailResponse:
      case TxMsgType.confirmSyncResponse:
      case TxMsgType.deleteSessionResponse:
        _responseController.add(payload);
        break;
    }
  }

  Future<Uint8List> _sendRequest(RxMsgType type, Uint8List payload) async {
    if (!isConnected) {
      throw Exception('Not connected to device');
    }

    // Build frame: Type(1) + Len(2) + Payload + CRC(1)
    final frameLen = 3 + payload.length + 1;
    final frame = Uint8List(frameLen);

    frame[0] = type.value;
    frame[1] = payload.length & 0xFF;
    frame[2] = (payload.length >> 8) & 0xFF;
    frame.setRange(3, 3 + payload.length, payload);

    // Calculate CRC
    int crc = 0;
    for (int i = 0; i < frameLen - 1; i++) {
      crc ^= frame[i];
    }
    frame[frameLen - 1] = crc;

    // Send request
    await _rxChar!.write(frame, withoutResponse: false);

    // Wait for response
    final response = await _responseController.stream.first.timeout(
      _responseTimeout,
      onTimeout: () => throw TimeoutException('No response from device'),
    );

    return response;
  }

  @override
  Future<ResponseStatus> sendTimeSync(int timestampMs) async {
    final payload = Uint8List(8);
    final byteData = ByteData.sublistView(payload);
    byteData.setUint64(0, timestampMs, Endian.little);

    final response = await _sendRequest(RxMsgType.timeSync, payload);
    if (response.isEmpty) return ResponseStatus.error;
    return ResponseStatus.fromValue(response[0]);
  }

  @override
  Future<List<SessionSummary>> getSessions({int maxCount = 10, int filter = 0}) async {
    final payload = Uint8List(2);
    payload[0] = maxCount;
    payload[1] = filter;

    final response = await _sendRequest(RxMsgType.getSessions, payload);
    if (response.length < 3) return [];

    final status = ResponseStatus.fromValue(response[0]);
    if (status != ResponseStatus.success) return [];

    final totalCount = response[1] | (response[2] << 8);
    final sessions = <SessionSummary>[];

    // Parse session summaries (32 bytes each, starting at offset 3)
    int offset = 3;
    while (offset + 32 <= response.length) {
      try {
        final summary = SessionSummary.fromBytes(response.sublist(offset, offset + 32));
        sessions.add(summary);
      } catch (_) {}
      offset += 32;
    }

    return sessions;
  }

  @override
  Future<Uint8List?> getSessionDetail(Uint8List uuid) async {
    if (uuid.length != 16) return null;

    final response = await _sendRequest(RxMsgType.getSessionDetail, uuid);
    if (response.isEmpty) return null;

    final status = ResponseStatus.fromValue(response[0]);
    if (status != ResponseStatus.success) return null;

    return response.sublist(1); // Return session data without status byte
  }

  @override
  Future<ResponseStatus> confirmSync(Uint8List uuid) async {
    if (uuid.length != 16) return ResponseStatus.invalidParam;

    final response = await _sendRequest(RxMsgType.confirmSync, uuid);
    if (response.isEmpty) return ResponseStatus.error;
    return ResponseStatus.fromValue(response[0]);
  }

  @override
  Future<ResponseStatus> deleteSession(Uint8List uuid) async {
    if (uuid.length != 16) return ResponseStatus.invalidParam;

    final response = await _sendRequest(RxMsgType.deleteSession, uuid);
    if (response.isEmpty) return ResponseStatus.error;
    return ResponseStatus.fromValue(response[0]);
  }
}
