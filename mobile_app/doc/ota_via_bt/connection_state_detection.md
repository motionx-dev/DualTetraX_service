# OTA Connection State Detection Design

## Overview

OTA 페이지에서 디바이스 연결 상태를 인지하고, 연결 해제 시 적절히 대응하기 위한 설계 문서입니다.

## Problem Statement

현재 OtaBloc은 DeviceConnectionBloc과 독립적으로 동작하여:
1. OTA 페이지 진입 시 연결 상태를 확인하지 않음
2. OTA 진행 중 연결 해제를 감지하지 못함

## Solution: Stream Injection Pattern

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      SettingsPage                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ OTA 메뉴 클릭                                          │  │
│  │   ↓                                                    │  │
│  │ DeviceConnectionBloc.state 확인                        │  │
│  │   ↓                                                    │  │
│  │ 연결됨? → OtaPage로 이동 (di.sl<OtaBloc>())            │  │
│  │ 연결안됨? → SnackBar 경고 표시                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                        OtaBloc                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 생성자 파라미터:                                        │  │
│  │   - otaRepository: OtaRepository                       │  │
│  │   - connectionStateStream: Stream<BleConnectionState>  │  │
│  │                                                        │  │
│  │ 연결 상태 구독:                                         │  │
│  │   connectionStateStream.listen((state) {               │  │
│  │     if (state == BleConnectionState.disconnected) {    │  │
│  │       add(ConnectionLostDuringOta());                  │  │
│  │     }                                                  │  │
│  │   });                                                  │  │
│  │                                                        │  │
│  │ 연결 해제 처리:                                         │  │
│  │   - OTA 전송 중단 (_isSendingChunks = false)           │  │
│  │   - 에러 상태 emit (isOtaServiceReady = false)         │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Details

### 1. File Changes

| File | Changes |
|------|---------|
| `ota_event.dart` | `ConnectionLostDuringOta` 이벤트 추가 |
| `ota_bloc.dart` | connectionStateStream 파라미터 및 구독 로직 추가 |
| `injection_container.dart` | OtaBloc 생성 시 connectionStateStream 주입 |
| `settings_page.dart` | OTA 메뉴 진입 전 연결 상태 확인 |
| `app_localizations*.dart` | `deviceNotConnected` 번역 키 추가 (8개 언어) |

### 2. New Event: ConnectionLostDuringOta

```dart
// ota_event.dart
class ConnectionLostDuringOta extends OtaEvent {
  const ConnectionLostDuringOta();
}
```

### 3. OtaBloc Changes

```dart
// ota_bloc.dart
class OtaBloc extends Bloc<OtaEvent, OtaBlocState> {
  final OtaRepository otaRepository;
  final Stream<BleConnectionState> connectionStateStream;

  StreamSubscription? _connectionSubscription;
  StreamSubscription? _otaStatusSubscription;
  bool _isSendingChunks = false;

  OtaBloc({
    required this.otaRepository,
    required this.connectionStateStream,
  }) : super(const OtaInitial()) {
    // ... existing handlers ...
    on<ConnectionLostDuringOta>(_onConnectionLost);

    _listenToConnectionState();
  }

  void _listenToConnectionState() {
    _connectionSubscription = connectionStateStream.listen((state) {
      if (state == BleConnectionState.disconnected) {
        add(const ConnectionLostDuringOta());
      }
    });
  }

  Future<void> _onConnectionLost(
    ConnectionLostDuringOta event,
    Emitter<OtaBlocState> emit,
  ) async {
    // Skip if OTA already completed successfully
    if (state.isSuccess) return;

    _isSendingChunks = false;

    // Cancel OTA if in progress
    if (state.isTransferring) {
      try {
        await otaRepository.cancelOtaUpdate();
      } catch (_) {}
    }

    emit(state.copyWith(
      isOtaServiceReady: false,
      isTransferring: false,
      errorMessage: 'Device disconnected',
    ));
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    _isSendingChunks = false;
    _otaStatusSubscription?.cancel();
    otaRepository.dispose();
    return super.close();
  }
}
```

### 4. DI Container Changes

```dart
// injection_container.dart
sl.registerFactory(
  () => OtaBloc(
    otaRepository: sl(),
    connectionStateStream: sl<DeviceRepository>().connectionStateStream,
  ),
);
```

### 5. SettingsPage Changes

```dart
// settings_page.dart - OTA ListTile onTap
onTap: () {
  final connectionState = context.read<DeviceConnectionBloc>().state;
  final l10n = AppLocalizations.of(context)!;

  if (connectionState is! DeviceConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.deviceNotConnected)),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => di.sl<OtaBloc>(),
        child: const OtaPage(),
      ),
    ),
  );
},
```

### 6. Localization Keys

| Language | Key | Value |
|----------|-----|-------|
| Korean | deviceNotConnected | 디바이스가 연결되어 있지 않습니다 |
| English | deviceNotConnected | Device is not connected |
| Chinese | deviceNotConnected | 设备未连接 |
| Japanese | deviceNotConnected | デバイスが接続されていません |
| Portuguese | deviceNotConnected | Dispositivo não conectado |
| Spanish | deviceNotConnected | Dispositivo no conectado |
| Vietnamese | deviceNotConnected | Thiết bị chưa được kết nối |
| Thai | deviceNotConnected | อุปกรณ์ไม่ได้เชื่อมต่อ |

## Edge Cases

### 1. OTA Success + Device Reboot
OTA 성공 후 디바이스가 재부팅되면서 연결이 끊어지는 것은 정상 동작입니다.
- `state.isSuccess`인 경우 `ConnectionLostDuringOta` 이벤트 무시

### 2. Connection Lost During Transfer
OTA 전송 중 연결이 끊어지면:
- `_isSendingChunks = false`로 전송 루프 중단
- `otaRepository.cancelOtaUpdate()` 호출
- 에러 상태로 전환

### 3. Already Disconnected Before OTA Page Entry
SettingsPage에서 OTA 메뉴 진입 전 연결 상태 확인하여 차단

## Test Scenarios

1. **연결된 상태에서 OTA 페이지 진입** → 정상 진입
2. **연결 안된 상태에서 OTA 페이지 진입** → SnackBar 경고, 진입 차단
3. **OTA 전송 중 연결 해제** → 전송 중단, 에러 표시
4. **OTA 성공 후 재부팅으로 인한 연결 해제** → 정상 (에러 아님)
5. **OTA 시작 전 연결 해제** → 에러 표시

## Verification Checklist

- [x] `ota_event.dart`에 `ConnectionLostDuringOta` 이벤트 추가됨
- [x] `ota_bloc.dart`에 `connectionStateStream` 파라미터 추가됨
- [x] `ota_bloc.dart`에 `_listenToConnectionState()` 메서드 추가됨
- [x] `ota_bloc.dart`에 `_onConnectionLost()` 핸들러 추가됨
- [x] `ota_bloc.dart`의 `close()`에서 `_connectionSubscription` 해제됨
- [x] `injection_container.dart`에서 `connectionStateStream` 주입됨
- [x] `settings_page.dart`에서 연결 상태 확인 후 OTA 진입
- [x] 8개 언어 파일에 `deviceNotConnected` 번역 추가됨
