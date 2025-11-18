# DualTetraX Mobile App - 프로젝트 구조

## 전체 파일 목록

### 루트 파일
```
mobile_app/
├── pubspec.yaml                 # Flutter 프로젝트 설정 및 의존성
├── analysis_options.yaml        # Dart 분석 옵션
├── .gitignore                   # Git 제외 파일
├── README.md                    # 프로젝트 문서
└── PROJECT_STRUCTURE.md         # 이 파일
```

### 핵심 코드 (lib/)

#### 1. Domain Layer (domain/)
비즈니스 로직과 엔티티를 정의합니다. 외부 의존성이 없는 순수 Dart 코드입니다.

**Entities (entities/)**
```
domain/entities/
├── shot_type.dart               # Shot 타입 enum (U/E/LED)
├── device_mode.dart             # 디바이스 모드 enum
├── device_level.dart            # 레벨 enum (1/2/3)
├── working_state.dart           # 동작 상태 enum
├── battery_status.dart          # 배터리 상태 클래스
├── warning_status.dart          # Warning 상태 클래스
├── device_status.dart           # 디바이스 전체 상태
├── device_info.dart             # 디바이스 정보
├── usage_session.dart           # 사용 세션
├── usage_statistics.dart        # 사용 통계
└── connection_state.dart        # BLE 연결 상태 enum
```

**Repositories (repositories/)**
```
domain/repositories/
├── device_repository.dart       # 디바이스 Repository 인터페이스
└── usage_repository.dart        # 사용 이력 Repository 인터페이스
```

**Use Cases (usecases/)**
```
domain/usecases/
├── connect_to_device.dart       # 디바이스 연결
├── get_device_status.dart       # 디바이스 상태 조회
├── get_daily_statistics.dart    # 일별 통계
├── get_weekly_statistics.dart   # 주별 통계
├── get_monthly_statistics.dart  # 월별 통계
└── delete_all_data.dart         # 전체 데이터 삭제
```

#### 2. Data Layer (data/)
데이터 소스와 Repository 구현체를 포함합니다.

**Data Sources (datasources/)**
```
data/datasources/
├── ble_remote_data_source.dart      # BLE 통신 (flutter_blue_plus)
├── device_local_data_source.dart    # 디바이스 정보 저장 (SharedPreferences)
├── usage_local_data_source.dart     # 사용 이력 저장 (SQLite)
└── database_helper.dart             # SQLite DB 초기화 및 관리
```

**Models (models/)**
```
data/models/
├── device_info_model.dart       # DeviceInfo 모델 (JSON 직렬화)
└── usage_session_model.dart     # UsageSession 모델 (SQLite 매핑)
```

**Repositories (repositories/)**
```
data/repositories/
├── device_repository_impl.dart  # DeviceRepository 구현
└── usage_repository_impl.dart   # UsageRepository 구현
```

#### 3. Presentation Layer (presentation/)
UI 및 상태 관리를 담당합니다.

**BLoC (bloc/)**
```
presentation/bloc/
├── device_connection/
│   ├── device_connection_bloc.dart
│   ├── device_connection_event.dart
│   └── device_connection_state.dart
├── device_status/
│   └── device_status_bloc.dart
└── usage_statistics/
    └── usage_statistics_bloc.dart
```

**Pages (pages/)**
```
presentation/pages/
├── home_page.dart               # 홈 화면 (연결 상태, 오늘 사용)
├── statistics_page.dart         # 통계 화면 (일/주/월)
├── guide_page.dart              # 사용 가이드 화면
└── settings_page.dart           # 설정 화면
```

**Widgets (widgets/)**
```
presentation/widgets/
├── connection_status_widget.dart    # 연결 상태 위젯
└── today_usage_widget.dart          # 오늘 사용 위젯
```

#### 4. Core (core/)
공통 기능 및 유틸리티를 포함합니다.

```
core/
├── constants/                   # 상수 정의
├── di/
│   └── injection_container.dart # GetIt 의존성 주입 설정
├── errors/
│   └── failures.dart            # 에러 정의 (Failure 클래스)
├── usecases/
│   └── usecase.dart             # Base UseCase 인터페이스
└── utils/                       # 유틸리티 함수
```

#### 5. Main
```
lib/
└── main.dart                    # 앱 진입점
```

## 의존성 흐름

```
main.dart
  ↓
MultiBlocProvider (BLoC들 제공)
  ↓
HomePage/StatisticsPage/GuidePage/SettingsPage
  ↓
BLoC (DeviceConnectionBloc, DeviceStatusBloc, UsageStatisticsBloc)
  ↓
Use Cases (ConnectToDevice, GetDeviceStatus, GetDailyStatistics, ...)
  ↓
Repositories (DeviceRepository, UsageRepository)
  ↓
Data Sources (BleRemoteDataSource, DeviceLocalDataSource, UsageLocalDataSource)
  ↓
External (flutter_blue_plus, SharedPreferences, SQLite)
```

## 데이터 흐름 예시

### 1. BLE 연결 흐름
```
1. User taps "연결" button (home_page.dart)
   ↓
2. DeviceConnectionBloc receives ConnectRequested event
   ↓
3. DeviceConnectionBloc calls ConnectToDevice use case
   ↓
4. ConnectToDevice calls DeviceRepository.scanAndConnect()
   ↓
5. DeviceRepositoryImpl calls BleRemoteDataSource.scanAndConnect()
   ↓
6. BleRemoteDataSource uses flutter_blue_plus to scan and connect
   ↓
7. Connection state streams back through the layers
   ↓
8. DeviceConnectionBloc emits DeviceConnected state
   ↓
9. UI updates to show "연결됨"
```

### 2. 통계 조회 흐름
```
1. User opens StatisticsPage
   ↓
2. UsageStatisticsBloc receives LoadDailyStatistics event
   ↓
3. UsageStatisticsBloc calls GetDailyStatistics use case
   ↓
4. GetDailyStatistics calls UsageRepository.getDailyStatistics()
   ↓
5. UsageRepositoryImpl calls UsageLocalDataSource.getSessionsByDate()
   ↓
6. UsageLocalDataSource queries SQLite database
   ↓
7. Data flows back through repository (with calculation)
   ↓
8. UsageStatisticsBloc emits UsageStatisticsLoaded state
   ↓
9. UI displays chart and statistics
```

## Clean Architecture 레이어 설명

### Domain Layer (가장 안쪽)
- **목적**: 비즈니스 로직과 규칙을 정의
- **특징**: 외부 의존성이 전혀 없음 (Flutter, BLE, DB에 대한 참조 없음)
- **구성**: Entities, Repository Interfaces, Use Cases

### Data Layer (중간)
- **목적**: 데이터 접근 및 저장 로직
- **특징**: Domain의 Repository 인터페이스를 구현
- **구성**: Repository Implementations, Data Sources, Models

### Presentation Layer (가장 바깥쪽)
- **목적**: UI 및 사용자 상호작용
- **특징**: Domain의 Use Cases만 호출 (Data Layer를 직접 호출하지 않음)
- **구성**: BLoC, Pages, Widgets

## 주요 디자인 패턴

### 1. Repository Pattern
- Domain Layer는 Repository 인터페이스만 정의
- Data Layer에서 실제 구현 제공
- 데이터 소스 변경 시 Domain Layer는 영향받지 않음

### 2. BLoC Pattern
- UI와 비즈니스 로직 분리
- Event → BLoC → State 흐름
- Stream 기반 상태 관리

### 3. Dependency Injection (GetIt)
- 싱글톤 패턴으로 의존성 관리
- `injection_container.dart`에서 모든 의존성 등록
- 테스트 시 Mock 객체로 쉽게 교체 가능

### 4. Either Pattern (Dartz)
- 성공/실패를 명시적으로 처리
- `Either<Failure, SuccessType>` 반환
- 함수형 프로그래밍 스타일

## 구현된 기능

✅ BLE 디바이스 스캔 및 연결
✅ 실시간 디바이스 상태 모니터링
✅ 사용 세션 추적 및 저장
✅ 일별 통계 조회
✅ 주별/월별 통계 조회 (기본 구조)
✅ 데이터 초기화
✅ 사용 가이드
✅ 설정 화면

## 미구현/추가 필요 기능

⚠️ 실제 DualTetraX BLE UUID 적용 필요
⚠️ BLE 세션 이벤트 수신 로직 완성 필요
⚠️ 주간/월간 그래프 시각화 구현 필요
⚠️ iOS/Android 네이티브 권한 처리 추가 필요
⚠️ 에러 처리 강화 필요

## 다음 단계

1. **DualTetraX 펌웨어 연동**
   - 실제 BLE UUID 적용
   - Characteristic 데이터 포맷 매핑
   - 세션 이벤트 수신 로직 구현

2. **UI 개선**
   - 주간/월간 그래프 차트 구현
   - 로딩 상태 개선
   - 에러 메시지 다국어화

3. **테스트 추가**
   - Unit Test (Use Cases, Repositories)
   - Widget Test (UI)
   - Integration Test (전체 흐름)

4. **권한 처리**
   - iOS Info.plist 설정
   - Android Manifest 설정
   - 런타임 권한 요청 UI

5. **최적화**
   - BLE 연결 안정성 개선
   - 배터리 소모 최적화
   - 데이터베이스 쿼리 최적화
