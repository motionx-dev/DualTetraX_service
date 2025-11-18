# DualTetraX Mobile App

DualTetraX 디바이스와 연동되는 Flutter 기반 모바일 애플리케이션입니다.

## 프로젝트 개요

이 앱은 DualTetraX 디바이스(ESP32 기반 FW)와 BLE(Bluetooth Low Energy)로 연동하여 다음 기능을 제공합니다:

- **BLE 자동 연결**: DualTetraX 디바이스 자동 검색 및 연결
- **실시간 상태 모니터링**: Shot 타입, 모드, 레벨, 배터리 상태 확인
- **사용 이력 수집**: 사용 세션 자동 추적 및 저장
- **사용 패턴 분석**: 일/주/월 단위 사용 통계 및 그래프
- **사용 가이드**: 단계별 DualTetraX 사용 방법 안내
- **데이터 관리**: 사용 이력 초기화 기능

## 기술 스택

- **프레임워크**: Flutter 3.0+
- **아키텍처**: Clean Architecture
- **상태 관리**: BLoC Pattern (flutter_bloc)
- **BLE 통신**: flutter_blue_plus
- **로컬 데이터베이스**: SQLite (sqflite)
- **로컬 저장소**: SharedPreferences
- **차트**: fl_chart
- **의존성 주입**: GetIt
- **함수형 프로그래밍**: Dartz

## 프로젝트 구조

```
lib/
├── core/                      # 핵심 기능
│   ├── constants/             # 상수 정의
│   ├── di/                    # 의존성 주입 (GetIt)
│   ├── errors/                # 에러 및 실패 정의
│   ├── usecases/              # Base UseCase
│   └── utils/                 # 유틸리티 함수
├── data/                      # Data Layer
│   ├── datasources/           # 데이터 소스
│   │   ├── ble_remote_data_source.dart       # BLE 통신
│   │   ├── device_local_data_source.dart     # 디바이스 정보 저장
│   │   ├── usage_local_data_source.dart      # 사용 이력 저장
│   │   └── database_helper.dart              # SQLite DB 헬퍼
│   ├── models/                # 데이터 모델 (JSON 직렬화)
│   │   ├── device_info_model.dart
│   │   └── usage_session_model.dart
│   └── repositories/          # Repository 구현체
│       ├── device_repository_impl.dart
│       └── usage_repository_impl.dart
├── domain/                    # Domain Layer (비즈니스 로직)
│   ├── entities/              # 엔티티 (순수 비즈니스 객체)
│   │   ├── shot_type.dart
│   │   ├── device_mode.dart
│   │   ├── device_level.dart
│   │   ├── working_state.dart
│   │   ├── battery_status.dart
│   │   ├── warning_status.dart
│   │   ├── device_status.dart
│   │   ├── device_info.dart
│   │   ├── usage_session.dart
│   │   ├── usage_statistics.dart
│   │   └── connection_state.dart
│   ├── repositories/          # Repository 인터페이스
│   │   ├── device_repository.dart
│   │   └── usage_repository.dart
│   └── usecases/              # Use Cases
│       ├── connect_to_device.dart
│       ├── get_device_status.dart
│       ├── get_daily_statistics.dart
│       ├── get_weekly_statistics.dart
│       ├── get_monthly_statistics.dart
│       └── delete_all_data.dart
└── presentation/              # Presentation Layer (UI)
    ├── bloc/                  # BLoC (상태 관리)
    │   ├── device_connection/
    │   │   ├── device_connection_bloc.dart
    │   │   ├── device_connection_event.dart
    │   │   └── device_connection_state.dart
    │   ├── device_status/
    │   │   └── device_status_bloc.dart
    │   └── usage_statistics/
    │       └── usage_statistics_bloc.dart
    ├── pages/                 # 화면
    │   ├── home_page.dart             # 홈 화면
    │   ├── statistics_page.dart       # 통계 화면
    │   ├── guide_page.dart            # 가이드 화면
    │   └── settings_page.dart         # 설정 화면
    └── widgets/               # 재사용 위젯
        ├── connection_status_widget.dart
        └── today_usage_widget.dart
```

## Clean Architecture 설명

이 프로젝트는 Clean Architecture 원칙을 따릅니다:

### 1. Domain Layer (핵심 비즈니스 로직)
- **Entities**: 비즈니스 객체 (ShotType, DeviceMode, UsageSession 등)
- **Repositories (Interface)**: 데이터 접근 인터페이스
- **Use Cases**: 단일 책임을 가진 비즈니스 로직

### 2. Data Layer (데이터 처리)
- **Models**: JSON 직렬화/역직렬화를 포함한 데이터 모델
- **Data Sources**:
  - **Remote**: BLE 통신
  - **Local**: SQLite, SharedPreferences
- **Repositories (Implementation)**: Domain의 Repository 인터페이스 구현

### 3. Presentation Layer (UI)
- **BLoC**: 상태 관리 및 비즈니스 로직 호출
- **Pages**: 화면
- **Widgets**: 재사용 가능한 UI 컴포넌트

### 의존성 흐름
```
Presentation → Domain ← Data
     ↓           ↑
   BLoC    Use Cases
```

- Presentation Layer는 Domain Layer의 Use Cases만 알고 있음
- Data Layer는 Domain Layer의 인터페이스를 구현
- Domain Layer는 외부 의존성이 없음 (순수 Dart 코드)

## 주요 기능

### 1. BLE 연결
- DualTetraX 디바이스 자동 검색 (`DualTetraX-` Prefix)
- 자동 연결 및 재연결
- BLE Bonding을 통한 페어링 정보 저장
- 연결 상태 실시간 모니터링

### 2. 실시간 상태 모니터링
- 현재 Shot 타입 (U-Shot, E-Shot, LED Care)
- 현재 모드 (Glow, Tuning, Renewal, Volume, Cleansing, Firming, Lifting, LF)
- 현재 레벨 (1, 2, 3)
- 동작 상태 (Working, Pause, Standby, Off)
- 배터리 상태 (레벨 0-100%, 상태)
- Warning 상태 (온도, 배터리 경고)

### 3. 사용 이력 수집
- Working 상태 시작/종료 자동 추적
- 세션별 상세 정보 저장:
  - 시작/종료 시각
  - Shot 타입, 모드, 레벨
  - 사용 시간, Pause 시간
  - Warning 발생 여부
  - 배터리 상태

### 4. 사용 패턴 분석
- 일별 사용 통계
- 주별 사용 통계 (요일별 분포)
- 월별 사용 통계
- Shot/모드/레벨별 사용 시간 분석
- 그래프 시각화 (fl_chart)

### 5. 데이터 관리
- 모든 사용 이력 초기화
- 기간별 데이터 삭제
- 디바이스 정보 저장/삭제

## 설치 및 실행

### 사전 요구사항
- Flutter SDK 3.0 이상
- Dart SDK 2.17 이상
- iOS: Xcode 13 이상
- Android: Android Studio, JDK 11 이상

### 의존성 설치
```bash
cd services/mobile_app
flutter pub get
```

### 실행
```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# 실제 기기
flutter run
```

### 빌드
```bash
# Android APK
flutter build apk

# iOS (macOS 필요)
flutter build ios
```

## BLE 프로토콜 (DualTetraX 펌웨어와의 통신)

이 앱은 DualTetraX 펌웨어가 제공하는 BLE 서비스를 통해 통신합니다.

### 필요한 BLE 서비스

#### 1. Device Info Service
- **Firmware Version**: 펌웨어 버전 정보
- **Model Name**: 디바이스 모델명
- **Serial Number**: 시리얼 번호

#### 2. Realtime Status Service
- **Shot Type**: 현재 Shot 타입 (Notify)
- **Mode**: 현재 모드 (Notify)
- **Level**: 현재 레벨 (Notify)
- **Working State**: 동작 상태 (Notify)
- **Battery Status**: 배터리 상태 (Notify)
- **Warning Status**: Warning 상태 (Notify)

#### 3. Usage Session Service (선택)
- **Session Event**: 세션 이벤트 (Notify)
  - SESSION_START
  - SESSION_END
  - MODE_CHANGED
  - LEVEL_CHANGED
  - WARNING_OCCURRED

### UUID 설정
현재 코드에는 임시 UUID가 사용되고 있습니다. 실제 DualTetraX 펌웨어의 UUID로 교체해야 합니다.

`lib/data/datasources/ble_remote_data_source.dart` 파일의 UUID를 수정하세요:
```dart
// TODO: Replace with actual UUIDs from DualTetraX firmware
static final Guid deviceInfoServiceUuid = Guid('...');
static final Guid realtimeStatusServiceUuid = Guid('...');
```

## 권한 설정

### iOS (Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>DualTetraX 디바이스와 연결하기 위해 Bluetooth 권한이 필요합니다.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>DualTetraX 디바이스와 연결하기 위해 Bluetooth 권한이 필요합니다.</string>
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

## 개발 가이드

### 새로운 UseCase 추가
1. `lib/domain/usecases/` 에 UseCase 클래스 생성
2. `lib/core/di/injection_container.dart`에 등록
3. BLoC에서 UseCase 사용

### 새로운 화면 추가
1. `lib/presentation/pages/`에 페이지 생성
2. 필요시 BLoC 생성
3. 라우팅 설정

### 데이터베이스 스키마 변경
1. `lib/data/datasources/database_helper.dart`에서 버전 증가
2. `_onUpgrade` 메서드 구현

## 주의사항

### BLE 통신
- BLE 연결은 OS 제약으로 인해 100% 보장되지 않습니다
- 앱이 백그라운드에 있을 때는 연결이 제한될 수 있습니다
- 디바이스의 전원이 꺼지면 자동으로 연결이 해제됩니다

### 데이터 저장
- 모든 데이터는 로컬에만 저장됩니다 (서버 연동 없음)
- 앱을 삭제하면 모든 데이터가 삭제됩니다
- 백업 기능은 추후 추가 예정입니다

### 배터리 최적화
- BLE 연결은 배터리를 소모합니다
- 불필요할 때는 연결을 해제하는 것이 좋습니다
- 이벤트 기반 통신으로 폴링을 최소화했습니다

## 향후 개발 계획

- [ ] 실제 DualTetraX 펌웨어 BLE UUID 적용
- [ ] 주간/월간 통계 그래프 구현
- [ ] 사용 목표 설정 및 알림 기능
- [ ] 데이터 백업/복원 기능
- [ ] 다국어 지원 (영어, 한국어)
- [ ] 다크 모드 지원
- [ ] 사용자 프로필 기능
- [ ] 펌웨어 OTA 업데이트 기능

## 트러블슈팅

### BLE 연결 실패
1. 디바이스 전원이 켜져 있는지 확인
2. Bluetooth 권한이 허용되었는지 확인
3. 위치 권한이 허용되었는지 확인 (Android)
4. 앱을 재시작하고 다시 시도

### 데이터베이스 오류
1. 앱 데이터 삭제 후 재설치
2. 데이터베이스 버전 확인

### 빌드 오류
1. `flutter clean` 실행
2. `flutter pub get` 실행
3. 의존성 버전 확인

## 라이선스

Copyright (c) 2024 MotionX

## 참조 문서

- [DualTetraX Mobile App Requirements](doc/DualTetraX_Mobile_App_Requirements_v1.md)
- [DualTetraX Firmware Requirements for Mobile App](doc/DualTetraX_Requirements_for_Mobile_App_v1.md)
