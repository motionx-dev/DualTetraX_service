# BLE OTA Design Specification

## Document Info
- **Version**: 1.0
- **Date**: 2026-01-13
- **Project**: DualTetraX Mobile App - BLE OTA Feature

---

## 1. System Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Mobile App (Flutter)                         │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │   OTA UI    │  │  OTA BLoC   │  │ File Picker │                 │
│  │   (Page)    │──│  (State)    │──│  (Plugin)   │                 │
│  └─────────────┘  └──────┬──────┘  └─────────────┘                 │
│                          │                                          │
│                  ┌───────┴───────┐                                  │
│                  │ OTA Use Cases │                                  │
│                  └───────┬───────┘                                  │
│                          │                                          │
│                  ┌───────┴───────┐                                  │
│                  │OTA Repository │                                  │
│                  └───────┬───────┘                                  │
│                          │                                          │
│                  ┌───────┴───────┐                                  │
│                  │BLE Data Source│                                  │
│                  └───────┬───────┘                                  │
└──────────────────────────┼──────────────────────────────────────────┘
                           │ BLE (GATT)
┌──────────────────────────┼──────────────────────────────────────────┐
│                          │        Firmware (ESP32-S3)               │
├──────────────────────────┼──────────────────────────────────────────┤
│                  ┌───────┴───────┐                                  │
│                  │BLE OTA Service│  ← New GATT Service              │
│                  └───────┬───────┘                                  │
│                          │                                          │
│                  ┌───────┴───────┐                                  │
│                  │ DTOtaManager  │  ← Existing OTA Core             │
│                  └───────┬───────┘                                  │
│                          │                                          │
│                  ┌───────┴───────┐                                  │
│                  │  OTA Partition │                                 │
│                  │  (ota_0/ota_1) │                                 │
│                  └───────────────┘                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Component Overview

| Component | Location | Responsibility |
|-----------|----------|----------------|
| OTA UI | `lib/presentation/pages/ota_page.dart` | 사용자 인터페이스 |
| OTA BLoC | `lib/presentation/bloc/ota/` | 상태 관리 |
| OTA Use Cases | `lib/domain/usecases/ota/` | 비즈니스 로직 |
| OTA Repository | `lib/data/repositories/ota_repository.dart` | 데이터 추상화 |
| BLE OTA DataSource | `lib/data/datasources/ble_ota_data_source.dart` | BLE 통신 |
| BLE OTA Service (FW) | `modules/ota_manager/dt_ble_ota_service.cpp` | GATT 서비스 |

---

## 2. BLE GATT Service Design

### 2.1 Service & Characteristics

**OTA Service UUID**: `12341111-1234-1234-1234-123456789abc`

| Characteristic | UUID | Properties | Size | Description |
|----------------|------|------------|------|-------------|
| OTA Control | `12341101-...-abc` | Write | 1-9 bytes | OTA 명령 전송 |
| OTA Status | `12341102-...-abc` | Read, Notify | 4 bytes | OTA 상태 알림 |
| OTA Data | `12341103-...-abc` | Write No Response | 244 bytes | 펌웨어 청크 전송 |
| OTA Info | `12341104-...-abc` | Read | 16 bytes | 펌웨어 정보 |

### 2.2 OTA Control Commands

```
┌─────────────────────────────────────────────────────────┐
│                  OTA Control Command                     │
├──────────┬──────────────────────────────────────────────┤
│ Byte 0   │ Command ID                                   │
├──────────┼──────────────────────────────────────────────┤
│ Byte 1-N │ Command Data (optional)                      │
└──────────┴──────────────────────────────────────────────┘

Command IDs:
  0x01 = OTA_CMD_START      - Start OTA session
  0x02 = OTA_CMD_FINISH     - All chunks sent, start validation
  0x03 = OTA_CMD_CANCEL     - Cancel OTA
  0x04 = OTA_CMD_GET_INFO   - Request device OTA info
```

#### OTA_CMD_START Payload (9 bytes)
```
┌────────┬────────┬────────────────────────────────────┐
│ Offset │ Size   │ Description                        │
├────────┼────────┼────────────────────────────────────┤
│ 0      │ 1      │ Command ID (0x01)                  │
│ 1-4    │ 4      │ Firmware size (uint32, LE)         │
│ 5-8    │ 4      │ Chunk count (uint32, LE)           │
└────────┴────────┴────────────────────────────────────┘
```

### 2.3 OTA Status Notification (4 bytes)

```
┌────────┬────────┬────────────────────────────────────┐
│ Offset │ Size   │ Description                        │
├────────┼────────┼────────────────────────────────────┤
│ 0      │ 1      │ State (enum OtaState)              │
│ 1      │ 1      │ Error code (0 = no error)          │
│ 2      │ 1      │ Progress (0-100%)                  │
│ 3      │ 1      │ Battery level (0-100%)             │
└────────┴────────┴────────────────────────────────────┘

OtaState enum:
  0x00 = IDLE
  0x01 = READY           (waiting for firmware data)
  0x02 = RECEIVING       (receiving chunks)
  0x03 = VALIDATING      (verifying firmware)
  0x04 = APPLYING        (writing to flash)
  0x05 = SUCCESS
  0x06 = ERROR

Error codes:
  0x00 = NO_ERROR
  0x01 = ERR_LOW_BATTERY
  0x02 = ERR_INVALID_STATE
  0x03 = ERR_INVALID_SIZE
  0x04 = ERR_CHECKSUM_FAIL
  0x05 = ERR_FLASH_WRITE
  0x06 = ERR_TIMEOUT
  0x07 = ERR_CANCELLED
```

### 2.4 OTA Data Chunk Format

```
┌────────┬────────┬────────────────────────────────────┐
│ Offset │ Size   │ Description                        │
├────────┼────────┼────────────────────────────────────┤
│ 0-3    │ 4      │ Chunk index (uint32, LE)           │
│ 4-N    │ ≤240   │ Firmware data                      │
└────────┴────────┴────────────────────────────────────┘

Max chunk payload: 240 bytes (244 total with header)
```

---

## 3. Firmware Implementation

### 3.1 New Files

```
modules/ota_manager/
├── include/ota_manager/
│   └── dt_ble_ota_service.hpp    ← NEW
└── src/
    └── dt_ble_ota_service.cpp    ← NEW
```

### 3.2 BLE OTA Service Class

```cpp
// dt_ble_ota_service.hpp

#pragma once

#include <cstdint>
#include <functional>
#include "ota_manager/dt_ota_manager.hpp"

namespace dt {

class BleOtaService {
public:
    // Singleton
    static BleOtaService& instance();

    // Initialization
    void init(DTOtaManager* ota_manager);

    // GATT Service registration
    int register_gatt_service();

    // Command handlers (called from BLE callbacks)
    void handle_control_command(const uint8_t* data, uint16_t len);
    void handle_data_chunk(const uint8_t* data, uint16_t len);

    // Status notification
    void notify_status();

    // State
    bool is_ota_active() const { return ota_active_; }

private:
    BleOtaService() = default;

    // OTA session management
    void start_ota(uint32_t firmware_size, uint32_t chunk_count);
    void finish_ota();
    void cancel_ota();

    // Progress tracking
    void update_progress(uint8_t progress);

    // Members
    DTOtaManager* ota_manager_ = nullptr;
    bool ota_active_ = false;
    uint32_t firmware_size_ = 0;
    uint32_t expected_chunks_ = 0;
    uint32_t received_chunks_ = 0;
    uint8_t current_progress_ = 0;
    uint16_t conn_handle_ = 0;
};

} // namespace dt
```

### 3.3 GATT Service Definition

```cpp
// In dt_ble_ota_service.cpp

static const ble_uuid128_t ota_svc_uuid = BLE_UUID128_INIT(
    0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12, 0x34, 0x12,
    0x34, 0x12, 0x34, 0x12, 0x11, 0x11, 0x34, 0x12
);

static const ble_uuid128_t ota_ctrl_chr_uuid = BLE_UUID128_INIT(
    0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12, 0x34, 0x12,
    0x34, 0x12, 0x34, 0x12, 0x01, 0x11, 0x34, 0x12
);

static const ble_uuid128_t ota_status_chr_uuid = BLE_UUID128_INIT(
    0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12, 0x34, 0x12,
    0x34, 0x12, 0x34, 0x12, 0x02, 0x11, 0x34, 0x12
);

static const ble_uuid128_t ota_data_chr_uuid = BLE_UUID128_INIT(
    0xbc, 0x9a, 0x78, 0x56, 0x34, 0x12, 0x34, 0x12,
    0x34, 0x12, 0x34, 0x12, 0x03, 0x11, 0x34, 0x12
);

static const struct ble_gatt_svc_def ota_gatt_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = &ota_svc_uuid.u,
        .characteristics = (struct ble_gatt_chr_def[]) {
            {
                // OTA Control
                .uuid = &ota_ctrl_chr_uuid.u,
                .access_cb = ota_control_access_cb,
                .flags = BLE_GATT_CHR_F_WRITE,
            },
            {
                // OTA Status
                .uuid = &ota_status_chr_uuid.u,
                .access_cb = ota_status_access_cb,
                .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY,
            },
            {
                // OTA Data
                .uuid = &ota_data_chr_uuid.u,
                .access_cb = ota_data_access_cb,
                .flags = BLE_GATT_CHR_F_WRITE_NO_RSP,
            },
            { 0 }, // Terminator
        },
    },
    { 0 }, // Terminator
};
```

### 3.4 Integration with Existing OTA Manager

```cpp
void BleOtaService::start_ota(uint32_t firmware_size, uint32_t chunk_count) {
    // Battery check
    if (SystemConfig::instance().get_battery_level() < 70) {
        notify_error(ERR_LOW_BATTERY);
        return;
    }

    // Initialize OTA via existing manager
    if (!ota_manager_->begin_ota(firmware_size)) {
        notify_error(ERR_INVALID_SIZE);
        return;
    }

    ota_active_ = true;
    firmware_size_ = firmware_size;
    expected_chunks_ = chunk_count;
    received_chunks_ = 0;

    notify_status();  // READY state
}

void BleOtaService::handle_data_chunk(const uint8_t* data, uint16_t len) {
    if (!ota_active_ || len < 5) return;

    uint32_t chunk_idx = *(uint32_t*)data;
    const uint8_t* chunk_data = data + 4;
    uint16_t chunk_len = len - 4;

    // Write to OTA manager
    if (!ota_manager_->write_chunk(chunk_data, chunk_len)) {
        notify_error(ERR_FLASH_WRITE);
        cancel_ota();
        return;
    }

    received_chunks_++;
    update_progress((received_chunks_ * 100) / expected_chunks_);
}
```

---

## 4. Mobile App Implementation

### 4.1 Directory Structure

```
lib/
├── domain/
│   ├── entities/
│   │   └── ota_status.dart           ← NEW
│   ├── repositories/
│   │   └── ota_repository.dart       ← NEW (interface)
│   └── usecases/
│       └── ota/
│           ├── start_ota.dart        ← NEW
│           ├── cancel_ota.dart       ← NEW
│           └── get_ota_status.dart   ← NEW
├── data/
│   ├── datasources/
│   │   └── ble_ota_data_source.dart  ← NEW
│   └── repositories/
│       └── ota_repository_impl.dart  ← NEW
└── presentation/
    ├── bloc/
    │   └── ota/
    │       ├── ota_bloc.dart         ← NEW
    │       ├── ota_event.dart        ← NEW
    │       └── ota_state.dart        ← NEW
    ├── pages/
    │   └── ota_page.dart             ← NEW
    └── widgets/
        └── ota_progress_widget.dart  ← NEW
```

### 4.2 OTA Status Entity

```dart
// lib/domain/entities/ota_status.dart

import 'package:equatable/equatable.dart';

enum OtaState {
  idle,
  ready,
  receiving,
  validating,
  applying,
  success,
  error,
}

enum OtaError {
  none,
  lowBattery,
  invalidState,
  invalidSize,
  checksumFail,
  flashWrite,
  timeout,
  cancelled,
  connectionLost,
}

class OtaStatus extends Equatable {
  final OtaState state;
  final OtaError error;
  final int progress;
  final int batteryLevel;

  const OtaStatus({
    required this.state,
    this.error = OtaError.none,
    this.progress = 0,
    this.batteryLevel = 0,
  });

  factory OtaStatus.fromBytes(List<int> bytes) {
    return OtaStatus(
      state: OtaState.values[bytes[0]],
      error: OtaError.values[bytes[1]],
      progress: bytes[2],
      batteryLevel: bytes[3],
    );
  }

  @override
  List<Object?> get props => [state, error, progress, batteryLevel];
}
```

### 4.3 BLE OTA Data Source

```dart
// lib/data/datasources/ble_ota_data_source.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleOtaDataSource {
  static const String otaServiceUuid = '12341111-1234-1234-1234-123456789abc';
  static const String otaControlUuid = '12341101-1234-1234-1234-123456789abc';
  static const String otaStatusUuid = '12341102-1234-1234-1234-123456789abc';
  static const String otaDataUuid = '12341103-1234-1234-1234-123456789abc';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _dataChar;

  final _statusController = StreamController<OtaStatus>.broadcast();
  Stream<OtaStatus> get statusStream => _statusController.stream;

  static const int chunkSize = 240;
  static const int chunkHeaderSize = 4;

  Future<void> initialize(BluetoothDevice device) async {
    _device = device;

    final services = await device.discoverServices();
    final otaService = services.firstWhere(
      (s) => s.uuid.toString() == otaServiceUuid,
      orElse: () => throw Exception('OTA service not found'),
    );

    for (final char in otaService.characteristics) {
      final uuid = char.uuid.toString();
      if (uuid == otaControlUuid) _controlChar = char;
      if (uuid == otaStatusUuid) _statusChar = char;
      if (uuid == otaDataUuid) _dataChar = char;
    }

    // Subscribe to status notifications
    await _statusChar?.setNotifyValue(true);
    _statusChar?.onValueReceived.listen((value) {
      _statusController.add(OtaStatus.fromBytes(value));
    });
  }

  Future<void> startOta(Uint8List firmware) async {
    final firmwareSize = firmware.length;
    final chunkCount = (firmwareSize / chunkSize).ceil();

    // Send START command
    final startCmd = ByteData(9);
    startCmd.setUint8(0, 0x01); // OTA_CMD_START
    startCmd.setUint32(1, firmwareSize, Endian.little);
    startCmd.setUint32(5, chunkCount, Endian.little);

    await _controlChar?.write(startCmd.buffer.asUint8List());
  }

  Future<void> sendFirmwareChunks(
    Uint8List firmware,
    void Function(int sent, int total) onProgress,
  ) async {
    final totalChunks = (firmware.length / chunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize).clamp(0, firmware.length);
      final chunkData = firmware.sublist(start, end);

      // Build chunk packet: [index(4)] + [data(≤240)]
      final packet = ByteData(chunkHeaderSize + chunkData.length);
      packet.setUint32(0, i, Endian.little);
      for (int j = 0; j < chunkData.length; j++) {
        packet.setUint8(chunkHeaderSize + j, chunkData[j]);
      }

      await _dataChar?.write(
        packet.buffer.asUint8List(),
        withoutResponse: true,
      );

      onProgress(i + 1, totalChunks);

      // Throttle to prevent buffer overflow
      if (i % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }

    // Send FINISH command
    await _controlChar?.write([0x02]); // OTA_CMD_FINISH
  }

  Future<void> cancelOta() async {
    await _controlChar?.write([0x03]); // OTA_CMD_CANCEL
  }

  void dispose() {
    _statusController.close();
  }
}
```

### 4.4 OTA BLoC

```dart
// lib/presentation/bloc/ota/ota_bloc.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtaBloc extends Bloc<OtaEvent, OtaState> {
  final BleOtaDataSource _dataSource;
  StreamSubscription? _statusSubscription;

  OtaBloc(this._dataSource) : super(OtaInitial()) {
    on<OtaStartRequested>(_onStartRequested);
    on<OtaCancelRequested>(_onCancelRequested);
    on<OtaStatusChanged>(_onStatusChanged);

    _statusSubscription = _dataSource.statusStream.listen((status) {
      add(OtaStatusChanged(status));
    });
  }

  Future<void> _onStartRequested(
    OtaStartRequested event,
    Emitter<OtaState> emit,
  ) async {
    try {
      emit(OtaInProgress(progress: 0, status: 'Initializing...'));

      await _dataSource.startOta(event.firmware);

      await _dataSource.sendFirmwareChunks(
        event.firmware,
        (sent, total) {
          final progress = (sent * 100 / total).round();
          emit(OtaInProgress(
            progress: progress,
            status: 'Uploading... $sent/$total chunks',
          ));
        },
      );
    } catch (e) {
      emit(OtaFailure(error: e.toString()));
    }
  }

  Future<void> _onCancelRequested(
    OtaCancelRequested event,
    Emitter<OtaState> emit,
  ) async {
    await _dataSource.cancelOta();
    emit(OtaCancelled());
  }

  void _onStatusChanged(OtaStatusChanged event, Emitter<OtaState> emit) {
    final status = event.status;

    switch (status.state) {
      case OtaState.success:
        emit(OtaSuccess());
        break;
      case OtaState.error:
        emit(OtaFailure(error: _errorToString(status.error)));
        break;
      case OtaState.validating:
        emit(OtaInProgress(progress: 95, status: 'Validating firmware...'));
        break;
      case OtaState.applying:
        emit(OtaInProgress(progress: 98, status: 'Applying update...'));
        break;
      default:
        break;
    }
  }

  String _errorToString(OtaError error) {
    switch (error) {
      case OtaError.lowBattery:
        return 'Battery too low. Please charge to at least 70%.';
      case OtaError.checksumFail:
        return 'Firmware verification failed.';
      case OtaError.timeout:
        return 'Update timed out. Please try again.';
      default:
        return 'Update failed. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
```

---

## 5. Sequence Diagrams

### 5.1 Successful OTA Flow

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│  User    │          │Mobile App│          │ Device   │
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                     │
     │ Select firmware     │                     │
     │────────────────────>│                     │
     │                     │                     │
     │                     │ OTA_CMD_START       │
     │                     │────────────────────>│
     │                     │                     │
     │                     │ Status: READY       │
     │                     │<────────────────────│
     │                     │                     │
     │                     │ Chunk 0             │
     │                     │────────────────────>│
     │                     │                     │
     │                     │ Status: RECEIVING   │
     │                     │<────────────────────│
     │                     │                     │
     │ Progress: 5%        │ Chunk 1             │
     │<────────────────────│────────────────────>│
     │                     │                     │
     │      ...            │      ...            │
     │                     │                     │
     │ Progress: 100%      │ OTA_CMD_FINISH      │
     │<────────────────────│────────────────────>│
     │                     │                     │
     │                     │ Status: VALIDATING  │
     │                     │<────────────────────│
     │                     │                     │
     │                     │ Status: APPLYING    │
     │                     │<────────────────────│
     │                     │                     │
     │                     │ Status: SUCCESS     │
     │                     │<────────────────────│
     │                     │                     │
     │ "Update Complete!"  │                     │
     │<────────────────────│    [Device Reboots] │
     │                     │                     │
```

### 5.2 Error Recovery Flow

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│  User    │          │Mobile App│          │ Device   │
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                     │
     │                     │ Chunk N             │
     │                     │────────────────────>│
     │                     │                     │
     │                     │ [Write Error]       │
     │                     │                     │
     │                     │ Status: ERROR       │
     │                     │ Error: FLASH_WRITE  │
     │                     │<────────────────────│
     │                     │                     │
     │ "Update Failed"     │                     │
     │<────────────────────│                     │
     │                     │                     │
     │                     │ [Auto Rollback]     │
     │                     │                     │
     │                     │ Status: IDLE        │
     │                     │<────────────────────│
     │                     │                     │
```

---

## 6. Error Handling

### 6.1 Error Categories

| Category | Errors | Recovery Action |
|----------|--------|-----------------|
| Pre-flight | Low battery, Invalid state | Block OTA start, show message |
| Transfer | Chunk write fail, Timeout | Cancel OTA, notify user |
| Validation | Checksum fail, Invalid header | Cancel OTA, rollback |
| Connection | BLE disconnect | Auto-cancel, prompt retry |

### 6.2 Timeout Values

| Timeout | Value | Action |
|---------|-------|--------|
| Chunk ACK | 5s | Retry (3x), then fail |
| OTA Session | 5 min | Auto-cancel |
| Status notification | 10s | Show warning |

---

## 7. Testing Strategy

### 7.1 Unit Tests
- Chunk splitting logic
- Status parsing
- Error code mapping

### 7.2 Integration Tests
- BLE service discovery
- Characteristic read/write
- Notification subscription

### 7.3 E2E Tests
- Full OTA cycle with test firmware
- Cancel during transfer
- Connection loss simulation
- Low battery rejection

---

## 8. Security Considerations

### 8.1 Current Measures
- Firmware header validation (ESP32 magic byte)
- MD5 checksum verification
- Battery safety checks

### 8.2 Future Enhancements (Phase 2)
- Firmware signature verification (RSA/ECDSA)
- Encrypted transfer
- Version downgrade protection

---

## 9. Implementation Phases

### Phase 1: Core Implementation (2 weeks)
- [ ] Firmware: BLE OTA GATT service
- [ ] Firmware: Integration with DTOtaManager
- [ ] App: BLE OTA data source
- [ ] App: OTA BLoC and basic UI

### Phase 2: Polish & Testing (1 week)
- [ ] Error handling refinement
- [ ] Progress UI improvements
- [ ] Localization
- [ ] Testing

### Phase 3: Security & Optimization (Future)
- [ ] Firmware signing
- [ ] Transfer speed optimization
- [ ] Background transfer support

---

## 10. References

- [ESP-IDF OTA API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/ota.html)
- [NimBLE GATT Server](https://mynewt.apache.org/latest/network/ble_hs/ble_gatts.html)
- [flutter_blue_plus](https://pub.dev/packages/flutter_blue_plus)
- Existing code: `/modules/ota_manager/dt_ota_manager.hpp`
