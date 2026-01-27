# User History Management - Mobile App Specification

**Version**: 3.0
**Date**: 2026-01-14
**Status**: Draft
**Related Document**: [docs/service/user_history_management_spec.md](../../../docs/service/user_history_management_spec.md)

---

## 1. Overview

### 1.1 Purpose
DualTetraX 모바일 앱의 사용 이력 관리 기능에 대한 요구사항 분석 및 설계 문서.
일/주/월별 데이터 조회, 시각화, 클라우드 동기화를 포함한 확장성 있는 아키텍처 설계.

### 1.2 Architecture Change (v3.0) - RAM-Only Storage

**배경**: 디바이스에 RTC(Real-Time Clock)가 없어 NVS 저장이 무의미하므로, RAM 버퍼에만 세션을 저장하고 모바일 앱 연동 시 실시간 동기화하는 방식으로 변경.

```
[Device]                              [Mobile App]
  RAM Buffer (max 20 sessions)  <-BLE->  Persistent Storage (SQLite)

1. Session Start -> Store in RAM (uptime-based timestamp)
2. Session End -> Add to RAM buffer, send via BLE if connected
3. BLE Connect -> App sends current time (Time Sync 0x002B)
4. Device corrects timestamps and sends session data
5. Power Off -> RAM data lost (OK, already sent to app or acceptable loss)
```

**모바일 앱의 역할 변경**:
- 앱이 **영구 저장소 역할**을 담당 (디바이스는 RAM만 사용)
- BLE 연결 시 **즉시 Time Sync 전송** 필수
- 미동기화 세션을 적극적으로 Pull하여 저장

### 1.3 Scope
- 사용 이력 조회 (일별, 주별, 월별)
- 통계 시각화 (차트, 그래프)
- BLE를 통한 기기 데이터 동기화 (Time Sync 포함)
- 클라우드 서버 연동 및 데이터 백업
- 멀티 디바이스 지원

---

## 2. Current Implementation Analysis (현재 구현 분석)

### 2.1 Architecture Overview

```
+------------------------------------------------------------------+
|                    PRESENTATION LAYER                              |
|  +------------------+  +------------------+  +-----------------+   |
|  | StatisticsPage   |  |TodayUsageWidget  |  | UsageStatistics |   |
|  | - Daily (v)      |  | (Home Page)      |  |     BLoC        |   |
|  | - Weekly (!)     |  +------------------+  +-----------------+   |
|  | - Monthly (!)    |                                              |
|  +------------------+                                              |
+------------------------------------------------------------------+
                              |
+------------------------------------------------------------------+
|                      DOMAIN LAYER                                  |
|  +-----------------+  +-----------------+  +-------------------+   |
|  | UsageSession    |  |UsageStatistics  |  |   UseCases        |   |
|  | Entity          |  | Entity          |  | - GetDaily (v)    |   |
|  |                 |  |                 |  | - GetWeekly (v)   |   |
|  | DailyUsage      |  |                 |  | - GetMonthly (v)  |   |
|  | Entity          |  |                 |  | - DeleteAll (v)   |   |
|  +-----------------+  +-----------------+  +-------------------+   |
+------------------------------------------------------------------+
                              |
+------------------------------------------------------------------+
|                       DATA LAYER                                   |
|  +-----------------+  +-----------------+  +-------------------+   |
|  |UsageRepository  |  |UsageLocalData   |  | DatabaseHelper    |   |
|  | Impl (v)        |  | Source (v)      |  | SQLite (v)        |   |
|  +-----------------+  +-----------------+  +-------------------+   |
|                                                                    |
|  +-----------------+  +-----------------+                          |
|  |UsageRemoteData  |  | SyncManager     |  <- NOT IMPLEMENTED      |
|  | Source (x)      |  | (x)             |                          |
|  +-----------------+  +-----------------+                          |
+------------------------------------------------------------------+

Legend: (v) Implemented  (!) Stub/Partial  (x) Not Implemented
```

### 2.2 Implementation Status Matrix

| Component | Status | Description |
|-----------|--------|-------------|
| **Domain Layer** | | |
| UsageSession Entity | v | 세션 데이터 모델 정의 |
| UsageStatistics Entity | v | 통계 집계 모델 정의 |
| DailyUsage Entity | v | 일별 사용량 모델 정의 |
| UsageRepository Interface | v | 데이터 접근 추상화 |
| GetDailyStatistics UseCase | v | 일별 통계 조회 |
| GetWeeklyStatistics UseCase | v | 주별 통계 조회 |
| GetMonthlyStatistics UseCase | v | 월별 통계 조회 |
| DeleteAllData UseCase | v | 전체 데이터 삭제 |
| **Data Layer** | | |
| DatabaseHelper (SQLite) | v | 로컬 DB 관리 |
| UsageLocalDataSource | v | 로컬 데이터 접근 |
| UsageRepositoryImpl | v | 리포지토리 구현 |
| UsageRemoteDataSource | x | 클라우드 API 연동 |
| SyncManager | x | 동기화 관리자 |
| **Presentation Layer** | | |
| UsageStatisticsBloc | v | 상태 관리 |
| Daily Statistics View | v | 일별 통계 UI |
| Weekly Statistics View | ! | "Coming Soon" 표시 |
| Monthly Statistics View | ! | "Coming Soon" 표시 |
| TodayUsageWidget | v | 홈 화면 위젯 |
| Charts/Visualization | ! | fl_chart 임포트만 됨 |

### 2.3 Current Data Model

```dart
// 현재 UsageSession 구조
class UsageSession {
  final String? id;
  final DateTime startTime;
  final DateTime? endTime;
  final ShotType shotType;           // uShot, eShot, ledCare
  final DeviceMode mode;             // glow, tuning, cleansing, etc.
  final DeviceLevel level;           // level1, level2, level3
  final int workingDurationSeconds;
  final int pauseDurationSeconds;
  final bool hadTemperatureWarning;
  final bool hadBatteryWarning;
  final int startBatteryLevel;
  final int? endBatteryLevel;
}
```

### 2.4 Current SQLite Schema

```sql
-- 현재 usage_sessions 테이블
CREATE TABLE usage_sessions (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  end_time INTEGER,
  shot_type INTEGER NOT NULL,
  mode INTEGER NOT NULL,
  level INTEGER NOT NULL,
  working_duration_seconds INTEGER DEFAULT 0,
  pause_duration_seconds INTEGER DEFAULT 0,
  had_temperature_warning INTEGER DEFAULT 0,
  had_battery_warning INTEGER DEFAULT 0,
  start_battery_level INTEGER NOT NULL,
  end_battery_level INTEGER
);

-- 인덱스
CREATE INDEX idx_sessions_start_time ON usage_sessions(start_time);
CREATE INDEX idx_sessions_end_time ON usage_sessions(end_time);
CREATE INDEX idx_sessions_shot_type ON usage_sessions(shot_type);
```

---

## 3. Requirements (요구사항)

### 3.1 Functional Requirements

#### FR-M001: Daily Statistics View (일별 통계)
- **현재 상태**: v 구현됨
- **요구사항**:
  - 선택한 날짜의 총 사용 시간 표시
  - 샷 타입별 사용 시간 분류
  - 모드별, 레벨별 사용 시간 분류
  - 날짜 선택 기능 (캘린더 UI)
  - 경고 발생 횟수 표시

#### FR-M002: Weekly Statistics View (주별 통계)
- **현재 상태**: ! 스텁 구현
- **요구사항**:
  - 주간 총 사용 시간 요약
  - 일별 사용 시간 막대 차트 (7일)
  - 샷 타입별 주간 분포 파이 차트
  - 주간 목표 달성률 표시
  - 이전/다음 주 네비게이션

#### FR-M003: Monthly Statistics View (월별 통계)
- **현재 상태**: ! 스텁 구현
- **요구사항**:
  - 월간 총 사용 시간 요약
  - 일별 사용량 히트맵 캘린더
  - 월간 트렌드 라인 차트
  - 샷 타입별 월간 분포
  - 이전/다음 월 네비게이션
  - 월간 평균 사용 시간

#### FR-M004: Usage Charts & Visualization
- **현재 상태**: x 미구현 (fl_chart 라이브러리만 추가됨)
- **요구사항**:
  - 일별 사용량 막대 차트 (Bar Chart)
  - 샷 타입 분포 파이 차트 (Pie Chart)
  - 월간 트렌드 라인 차트 (Line Chart)
  - 히트맵 캘린더 뷰 (Calendar Heatmap)
  - 차트 터치 인터랙션 (상세 정보 툴팁)

#### FR-M005: Time Sync Protocol (v3.0 신규)
- **현재 상태**: x 미구현
- **요구사항**:
  - BLE 연결 즉시 Time Sync (0x002B) 전송
  - 현재 Unix timestamp (milliseconds) 전송
  - 디바이스 응답 확인 후 세션 동기화 시작
  - 앱 시작/재연결 시 자동 실행

```dart
// Time Sync 프로토콜 구현 예시
Future<void> sendTimeSync() async {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final data = ByteData(8)..setUint64(0, timestamp, Endian.little);
  await _bleService.sendCommand(0x002B, data.buffer.asUint8List());
}
```

#### FR-M006: BLE Session Sync (기기 연동)
- **현재 상태**: ! 실시간 상태만 구현
- **요구사항**:
  - 기기 연결 시 **Time Sync 먼저 전송** (0x002B)
  - 미동기화 세션 목록 조회 (CMD 0x0029)
  - 세션 상세 정보 조회 (CMD 0x002A)
  - 동기화 확인 전송 (CMD 0x0028)
  - 실시간 세션 진행 추적
  - 1분 간격 배터리 샘플 수신 (CMD 0x0026)

#### FR-M007: UUID-based Data Management
- **현재 상태**: x 미구현
- **요구사항**:
  - 기기에서 생성된 UUID를 Primary Key로 사용
  - UUID 기반 중복 방지
  - UUID를 통한 서버 동기화 식별

#### FR-M008: Battery Sample Tracking
- **현재 상태**: x 미구현
- **요구사항**:
  - 세션별 배터리 샘플 저장 (1분 간격)
  - 배터리 소모 그래프 표시
  - 세션 상세 보기에서 배터리 변화 시각화

#### FR-M009: Cloud Synchronization
- **현재 상태**: x 미구현
- **요구사항**:
  - REST API를 통한 서버 업로드
  - 서버에서 데이터 복원 (Pull)
  - 멀티 디바이스 동기화
  - 오프라인 모드 지원 (큐잉)
  - 동기화 상태 추적

#### FR-M010: Data Export
- **현재 상태**: x 미구현
- **요구사항**:
  - CSV/Excel 형식 내보내기
  - PDF 리포트 생성
  - 날짜 범위 선택 내보내기
  - 공유 기능 (이메일, 클라우드)

### 3.2 Non-Functional Requirements

#### NFR-M001: Performance
- 통계 조회 응답 시간: 500ms 이내
- 차트 렌더링: 60fps 유지
- 대용량 데이터 (1000+ 세션) 처리 가능

#### NFR-M002: Offline Support
- 네트워크 미연결 시 로컬 데이터 완전 지원
- 네트워크 복구 시 자동 동기화

#### NFR-M003: Data Integrity
- 앱 강제 종료 시 데이터 보존
- 트랜잭션 기반 DB 작업
- 동기화 실패 시 재시도 메커니즘

---

## 4. Extended Data Model Design

### 4.1 Updated UsageSession Entity

```dart
/// 확장된 사용 세션 엔티티
class UsageSession extends Equatable {
  /// UUID v4 (기기에서 생성, 동기화 식별자)
  final String uuid;

  /// 세션 시간 정보
  final DateTime startTime;
  final DateTime? endTime;

  /// 샷 정보
  final ShotType shotType;
  final DeviceMode mode;
  final DeviceLevel level;
  final int? ledPattern;  // E-Shot RGB 패턴

  /// 시간 추적
  final int workingDurationSeconds;
  final int pauseDurationSeconds;
  final int pauseCount;

  /// 종료 정보
  final TerminationReason? terminationReason;
  final int completionPercent;  // 0-100%

  /// 경고 플래그
  final bool hadTemperatureWarning;
  final bool hadBatteryWarning;

  /// 배터리 정보
  final List<BatterySample> batterySamples;

  /// 동기화 상태
  final SyncStatus syncStatus;

  /// 시간 동기화 여부 (v3.1)
  /// true: 앱 연동 상태에서 기록 (정확한 시간)
  /// false: 앱 미연동 상태에서 기록 (재할당된 추정 시간)
  final bool timeSynced;

  /// 기기 식별자 (멀티 디바이스 지원)
  final String? deviceId;

  /// 메타데이터
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  Duration get totalDuration =>
      endTime?.difference(startTime) ?? Duration.zero;

  bool get isActive => endTime == null;

  int? get startBatteryPercent =>
      batterySamples.isNotEmpty ? batterySamples.first.batteryPercent : null;

  int? get endBatteryPercent =>
      batterySamples.length > 1 ? batterySamples.last.batteryPercent : null;

  int? get batteryConsumed =>
      (startBatteryPercent != null && endBatteryPercent != null)
          ? startBatteryPercent! - endBatteryPercent!
          : null;

  @override
  List<Object?> get props => [uuid, startTime, endTime, shotType, mode, level];
}
```

### 4.2 New BatterySample Entity

```dart
/// 배터리 샘플 데이터 (1분 간격)
class BatterySample extends Equatable {
  final int elapsedSeconds;  // 세션 시작부터 경과 시간
  final int voltageMV;       // 배터리 전압 (mV)

  const BatterySample({
    required this.elapsedSeconds,
    required this.voltageMV,
  });

  /// mV를 퍼센트로 변환 (Li-ion 방전 곡선 기반)
  int get batteryPercent {
    if (voltageMV >= 4200) return 100;
    if (voltageMV <= 3000) return 0;

    // Non-linear approximation
    if (voltageMV >= 4000) return 80 + ((voltageMV - 4000) * 20 ~/ 200);
    if (voltageMV >= 3700) return 20 + ((voltageMV - 3700) * 60 ~/ 300);
    return ((voltageMV - 3000) * 20 ~/ 700);
  }

  @override
  List<Object> get props => [elapsedSeconds, voltageMV];
}
```

### 4.3 New Enumerations

```dart
/// 세션 종료 사유
enum TerminationReason {
  timeout8Min(0),         // 8분 타임아웃
  manualPowerOff(1),      // 수동 종료
  batteryDrain(2),        // 배터리 방전
  overheat(3),            // Legacy (use specific types)
  chargingStarted(4),     // 충전 시작
  pauseTimeout(5),        // 일시정지 타임아웃
  modeSwitch(6),          // 모드 전환
  powerOn(7),             // 전원 켜짐 이벤트
  overheatUltrasonic(8),  // 초음파 과열
  overheatBody(9),        // 본체 과열
  ;

  final int value;
  const TerminationReason(this.value);

  static TerminationReason fromValue(int value) {
    return TerminationReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TerminationReason.manualPowerOff,
    );
  }
}

/// 동기화 상태
enum SyncStatus {
  notSynced(0),       // 미동기화
  syncedToApp(1),     // 앱에 동기화됨
  syncedToServer(2),  // 서버에 업로드됨
  fullySynced(3),     // 앱 + 서버 모두 완료
  ;

  final int value;
  const SyncStatus(this.value);

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.notSynced,
    );
  }
}
```

### 4.4 Extended UsageStatistics

```dart
/// 확장된 사용 통계 엔티티
class UsageStatistics extends Equatable {
  final DateTime startDate;
  final DateTime endDate;

  // 기본 통계
  final int totalUsageMinutes;
  final int totalSessionCount;
  final int averageSessionMinutes;

  // 분류별 통계
  final Map<ShotType, int> usageByShot;      // 샷 타입별 분 단위
  final Map<DeviceMode, int> usageByMode;    // 모드별 분 단위
  final Map<DeviceLevel, int> usageByLevel;  // 레벨별 분 단위

  // 종료 사유별 통계
  final Map<TerminationReason, int> sessionsByTermination;

  // 경고 통계
  final int temperatureWarningCount;
  final int batteryWarningCount;

  // 배터리 통계
  final int? averageBatteryConsumed;  // 평균 배터리 소모량

  // 목표 달성
  final int? goalMinutes;             // 설정된 목표 (분)
  final double goalAchievementRate;   // 목표 달성률 (0.0 - 1.0)

  // 트렌드 (일별 데이터)
  final List<DailyUsage> dailyBreakdown;

  @override
  List<Object?> get props => [startDate, endDate, totalUsageMinutes];
}

/// 일별 사용량 (차트용)
class DailyUsage extends Equatable {
  final DateTime date;
  final int usageMinutes;
  final int sessionCount;
  final Map<ShotType, int> usageByShot;

  /// v3.1: 시간 동기화 상태별 사용 시간 분리
  final int syncedMinutes;    // 동기화된 세션의 사용 시간
  final int unsyncedMinutes;  // 미동기화 세션의 추정 사용 시간

  // 차트 표시용 computed properties
  double get usageHours => usageMinutes / 60.0;

  bool get hasUsage => usageMinutes > 0;

  bool get hasUnsyncedData => unsyncedMinutes > 0;

  @override
  List<Object?> get props => [date, usageMinutes, syncedMinutes, unsyncedMinutes];
}
```

---

## 5. Updated Database Schema

### 5.1 Schema Migration (Version 2)

```sql
-- =====================================================
-- DATABASE VERSION 2 - User History Management v3.0
-- =====================================================

-- 1. Usage Sessions Table (Updated)
CREATE TABLE usage_sessions (
  -- Primary key: UUID from device
  uuid TEXT PRIMARY KEY,

  -- Timestamps (milliseconds since epoch)
  start_time INTEGER NOT NULL,
  end_time INTEGER,

  -- Shot information
  shot_type INTEGER NOT NULL,      -- 0: unknown, 1: uShot, 2: eShot, 3: ledCare
  mode INTEGER NOT NULL,           -- Device mode enum value
  level INTEGER NOT NULL,          -- 1, 2, 3
  led_pattern INTEGER,             -- RGB pattern for E-Shot

  -- Duration tracking
  working_duration_seconds INTEGER DEFAULT 0,
  pause_duration_seconds INTEGER DEFAULT 0,
  pause_count INTEGER DEFAULT 0,

  -- Termination info
  termination_reason INTEGER,      -- TerminationReason enum
  completion_percent INTEGER DEFAULT 0,

  -- Warning flags
  had_temperature_warning INTEGER DEFAULT 0,
  had_battery_warning INTEGER DEFAULT 0,

  -- Sync management
  sync_status INTEGER DEFAULT 0,   -- 0: not synced, 1: app, 2: server, 3: both
  time_synced INTEGER DEFAULT 1,   -- 1: real time (synced), 0: estimated time (v3.1)
  device_id TEXT,                  -- For multi-device support

  -- Metadata
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 2. Battery Samples Table (New)
CREATE TABLE battery_samples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_uuid TEXT NOT NULL,
  elapsed_seconds INTEGER NOT NULL,
  voltage_mv INTEGER NOT NULL,
  created_at INTEGER NOT NULL,

  FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
    ON DELETE CASCADE
);

-- 3. Sync Queue Table (New - for offline support)
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_uuid TEXT NOT NULL,
  action TEXT NOT NULL,           -- 'upload', 'update', 'delete'
  payload TEXT,                   -- JSON serialized data
  retry_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_attempt_at INTEGER,

  FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
    ON DELETE CASCADE
);

-- 4. Sync Metadata Table (New)
CREATE TABLE sync_metadata (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Initial sync metadata
INSERT INTO sync_metadata (key, value, updated_at)
VALUES
  ('last_device_sync_timestamp', '0', strftime('%s', 'now') * 1000),
  ('last_server_sync_timestamp', '0', strftime('%s', 'now') * 1000),
  ('server_user_id', '', strftime('%s', 'now') * 1000);

-- =====================================================
-- INDEXES
-- =====================================================

-- Usage sessions indexes
CREATE INDEX idx_sessions_start_time ON usage_sessions(start_time);
CREATE INDEX idx_sessions_end_time ON usage_sessions(end_time);
CREATE INDEX idx_sessions_shot_type ON usage_sessions(shot_type);
CREATE INDEX idx_sessions_sync_status ON usage_sessions(sync_status);
CREATE INDEX idx_sessions_device_id ON usage_sessions(device_id);

-- Battery samples indexes
CREATE INDEX idx_battery_session ON battery_samples(session_uuid);
CREATE INDEX idx_battery_elapsed ON battery_samples(elapsed_seconds);

-- Sync queue indexes
CREATE INDEX idx_sync_queue_action ON sync_queue(action);
CREATE INDEX idx_sync_queue_created ON sync_queue(created_at);
```

### 5.2 Migration Script

```dart
// In database_helper.dart
class DatabaseHelper {
  static const int _databaseVersion = 2;

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to usage_sessions
      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN uuid TEXT
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN pause_count INTEGER DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN termination_reason INTEGER
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN completion_percent INTEGER DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN sync_status INTEGER DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN device_id TEXT
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN led_pattern INTEGER
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN created_at INTEGER
      ''');

      await db.execute('''
        ALTER TABLE usage_sessions
        ADD COLUMN updated_at INTEGER
      ''');

      // Generate UUIDs for existing records
      await _generateUuidsForExistingRecords(db);

      // Create new tables
      await db.execute('''
        CREATE TABLE battery_samples (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_uuid TEXT NOT NULL,
          elapsed_seconds INTEGER NOT NULL,
          voltage_mv INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_uuid TEXT NOT NULL,
          action TEXT NOT NULL,
          payload TEXT,
          retry_count INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          last_attempt_at INTEGER,
          FOREIGN KEY (session_uuid) REFERENCES usage_sessions(uuid)
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE sync_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create new indexes
      await db.execute(
        'CREATE INDEX idx_sessions_sync_status ON usage_sessions(sync_status)'
      );
      await db.execute(
        'CREATE INDEX idx_sessions_device_id ON usage_sessions(device_id)'
      );
      await db.execute(
        'CREATE INDEX idx_battery_session ON battery_samples(session_uuid)'
      );
    }
  }

  Future<void> _generateUuidsForExistingRecords(Database db) async {
    final sessions = await db.query('usage_sessions');
    for (final session in sessions) {
      final uuid = const Uuid().v4();
      await db.update(
        'usage_sessions',
        {'uuid': uuid},
        where: 'id = ?',
        whereArgs: [session['id']],
      );
    }
  }
}
```

---

## 6. BLE Protocol Integration (v3.0)

### 6.1 Protocol Commands Summary

| CMD | Name | Direction | Description |
|-----|------|-----------|-------------|
| 0x0025 | SessionStartNotify | Device -> App | 세션 시작 알림 |
| 0x0026 | BatterySampleNotify | Device -> App | 배터리 샘플 알림 (1분 간격) |
| 0x0027 | SessionEndNotify | Device -> App | 세션 종료 알림 |
| 0x0028 | SyncConfirmReq/Rsp | App -> Device | 동기화 확인 |
| 0x0029 | BulkSessionReq/Rsp | App -> Device | 세션 목록 요청 |
| 0x002A | SessionDetailReq/Rsp | App -> Device | 세션 상세 요청 |
| **0x002B** | **TimeSyncReq/Rsp** | **App -> Device** | **시간 동기화 (신규)** |

### 6.2 Time Sync Protocol (0x002B)

**중요**: 디바이스에 RTC가 없으므로 앱이 BLE 연결 즉시 현재 시간을 전송해야 합니다.

```
Direction: App -> Device (Request)
Payload (8 bytes):
  - timestamp_ms[8]: Current Unix timestamp in milliseconds (Little Endian)

Response (1 byte):
  - status[1]: 0=success

Device Logic:
  time_offset = app_timestamp - device_uptime
  real_time = uptime + time_offset
```

**구현 예시**:
```dart
class BleSessionSyncService {
  Future<bool> sendTimeSync() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = ByteData(8)..setUint64(0, timestamp, Endian.little);

    final response = await _bleService.sendCommand(
      0x002B,
      data.buffer.asUint8List(),
    );

    return response.status == 0;
  }
}
```

### 6.3 Updated BLE Sync Flow (v3.0)

```
+-------------+                              +-------------+
|   Device    |                              |  Mobile App |
+------+------+                              +------+------+
       |                                            |
       |  === BLE Connected ===                     |
       |                                            |
       |<---------[0x002B] Time Sync----------------+
       |          (Unix timestamp ms)               |
       |                                            |
       +--------[0x002B RSP] Success--------------->|
       |                                            |
       |<---------[0x0029] Bulk Session Request-----+
       |          (max_count=10, sync_filter=0)     |
       |                                            |
       +--------[0x0029 RSP] Session List---------->|
       |  (unsynced sessions with real timestamps)  |
       |                                            |
       |  For each unsynced session:                |
       |                                            |
       |<---------[0x002A] Session Detail-----------+
       |                                            |
       +--------[0x002A RSP] Full Data + Samples--->|
       |                                            |
       |                         +-- Save to SQLite |
       |                                            |
       |<---------[0x0028] Sync Confirm-------------+
       |                                            |
       +--------[0x0028 RSP]----------------------->|
       |                                            |
```

### 6.4 Real-time Session Tracking Flow

```
+-------------+                +---------------+
|   Device    |                |  Mobile App   |
+------+------+                +-------+-------+
       |                               |
       |  === Session Start ===        |
       |                               |
       +--[0x0025] Session Start------>|
       |  (uuid, type, mode, level,    |
       |   battery, uptime timestamp)  |
       |                               |
       |                         +-- Create UsageSession
       |                         |   (convert uptime to real time
       |                         |    using time_offset)
       |                               |
       |  === During Session ===       |
       |                               |
       +--[0x0026] Battery Sample----->|
       |  (1min interval)              |
       |                         +-- Append BatterySample
       |                               |
       |  === Session End ===          |
       |                               |
       +--[0x0027] Session End-------->|
       |  (duration, pauses, reason,   |
       |   real timestamps after sync) |
       |                               |
       |                         +-- Update UsageSession
       |                         |   (status: completed)
       |                               |
       |<---------[0x0028] Sync Confirm+
       |                               |
```

### 6.5 Time Sync Status (v3.1 신규)

디바이스는 앱과 연동 없이도 독립적으로 세션을 기록할 수 있습니다. 이 경우 타임스탬프가 실제 시간이 아닌 기기 업타임 기반이므로, 앱에서 특별하게 처리합니다.

#### 6.5.1 `time_synced` 필드

기기의 `UserActivityLogEntryV3` 구조체에 `time_synced` 필드가 추가되었습니다:

```cpp
// UserActivityLogEntryV3 구조체 (56 bytes)
struct UserActivityLogEntryV3 {
    ...
    uint8_t time_synced;        // 1: 실제 시간 (앱 연동), 0: 업타임 기반
    ...
};
```

**동작 원리**:
- 앱 연결 상태에서 세션 시작: `time_synced = 1` (실시간 타임스탬프)
- 앱 미연결 상태에서 세션 시작: `time_synced = 0` (업타임 기반)
- 앱이 세션 중간에 연결되면: 이미 시작된 세션이므로 Time Sync로 타임스탬프 보정 후 `time_synced = 1`

#### 6.5.2 타임스탬프 재할당 정책

앱이 `time_synced=false` 세션을 수신하면 다음과 같이 타임스탬프를 재할당합니다:

```
last_device_sync_timestamp = DB에서 마지막 기기 동기화 시간 조회

for each session in unsynced_sessions:
    if session.time_synced == false:
        session.start_time = last_device_sync_timestamp + cumulative_offset
        session.end_time = session.start_time + (working_duration + pause_duration)
        cumulative_offset += session.total_duration + 1초 (세션 간 간격)
```

**예시**:
```
마지막 동기화: 2026-01-27 10:00:00
미동기화 세션 3개 (각각 3분)

세션 1: 10:00:00 ~ 10:03:00
세션 2: 10:03:01 ~ 10:06:01
세션 3: 10:06:02 ~ 10:09:02
```

#### 6.5.3 UI 표시 정책

통계 그래프에서 `time_synced` 상태에 따라 다른 색상으로 표시합니다:

| 상태 | 색상 | 설명 |
|------|------|------|
| `time_synced=true` | 진한 파란색 (100%) | 실시간 동기화된 정확한 시간 |
| `time_synced=false` | 연한 파란색 (40%) | 추정 시간 (재할당된 타임스탬프) |

**주간 막대 그래프 (Bar Chart)**:
- 스택형 막대로 동기화/미동기화 사용량 분리 표시
- 미동기화 데이터가 있을 경우 범례와 설명 문구 표시

**월간 라인 그래프 (Line Chart)**:
- 동기화 데이터: 실선
- 미동기화 데이터: 점선 (dash pattern)
- 별도의 라인으로 구분하여 표시

**범례**:
- 동기화됨 (Synced): 앱과 연동하여 기록된 정확한 사용 시간
- 추정 시간 (Estimated): 앱 연결 없이 기록된 세션. 실제 시간과 다를 수 있음

#### 6.5.4 다국어 지원

```dart
// 영어
"syncedUsage": "Synced",
"unsyncedUsage": "Estimated",
"unsyncedTimeExplanation": "Estimated time: Sessions recorded while app was disconnected. Actual times may differ.",

// 한국어
"syncedUsage": "동기화됨",
"unsyncedUsage": "추정 시간",
"unsyncedTimeExplanation": "추정 시간: 앱 연결 없이 기록된 세션입니다. 실제 시간과 다를 수 있습니다.",
```

### 6.6 Connection State Machine

```dart
class BleConnectionStateMachine {
  Future<void> onConnected() async {
    // Step 1: Time Sync (REQUIRED)
    final timeSyncSuccess = await _sendTimeSync();
    if (!timeSyncSuccess) {
      _log.warning('Time sync failed, timestamps may be incorrect');
    }

    // Step 2: Pull unsynced sessions
    await _pullUnsyncedSessions();

    // Step 3: Subscribe to real-time notifications
    _subscribeToSessionNotifications();
  }

  Future<void> _sendTimeSync() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Send 0x002B with timestamp
  }

  Future<void> _pullUnsyncedSessions() async {
    // Send 0x0029 to get unsynced session list
    // For each session, send 0x002A to get details
    // Save to local DB
    // Send 0x0028 to confirm sync
  }
}
```

---

## 7. Architecture Design

### 7.1 Extended Clean Architecture

```
+-------------------------------------------------------------------------+
|                         PRESENTATION LAYER                               |
+-------------------------------------------------------------------------+
|                                                                          |
|  +------------------+  +------------------+  +----------------------+    |
|  |  StatisticsPage  |  |  SessionDetail   |  |  SyncStatusWidget    |    |
|  |  +- DailyView    |  |     Page         |  |  (Connection Status) |    |
|  |  +- WeeklyView   |  |  (Battery Graph) |  +----------------------+    |
|  |  +- MonthlyView  |  +------------------+                              |
|  +------------------+                                                    |
|                                                                          |
|  +------------------+  +------------------+  +----------------------+    |
|  |    ChartWidgets  |  | UsageStatistics  |  |   DeviceSyncBloc     |    |
|  |  +- BarChart     |  |      BLoC        |  |   (BLE Sync State)   |    |
|  |  +- PieChart     |  +------------------+  +----------------------+    |
|  |  +- LineChart    |                                                    |
|  |  +- HeatmapCal   |                                                    |
|  +------------------+                                                    |
|                                                                          |
+--------------------------------------------------------------------------+
                                    |
                                    v
+--------------------------------------------------------------------------+
|                          DOMAIN LAYER                                     |
+--------------------------------------------------------------------------+
|                                                                          |
|  +--------------------------------------------------------------------+  |
|  |                         USE CASES                                   |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  |  | GetDaily     |  | GetWeekly    |  | GetMonthly               |  |  |
|  |  | Statistics   |  | Statistics   |  | Statistics               |  |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  |  | SyncFromDev  |  | SyncToServer |  | GetSessionDetail         |  |  |
|  |  | ice (NEW)    |  | (NEW)        |  | (NEW)                    |  |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  |  | SendTimeSync |  | DeleteAll    |  | GetPendingSyncSessions   |  |  |
|  |  | (NEW v3.0)   |  | Data         |  | (NEW)                    |  |  |
|  |  +--------------+  +--------------+  +--------------------------+  |  |
|  +--------------------------------------------------------------------+  |
|                                                                          |
|  +---------------+  +----------------+  +-----------------------------+  |
|  | UsageSession  |  |UsageStatistics |  | Repository Interfaces      |  |
|  | Entity        |  | Entity         |  |  +- UsageRepository        |  |
|  |               |  |                |  |  +- SyncRepository (NEW)   |  |
|  | BatterySample |  | DailyUsage     |  |  +- AuthRepository (NEW)   |  |
|  | Entity (NEW)  |  | Entity         |  +-----------------------------+  |
|  +---------------+  +----------------+                                   |
|                                                                          |
+--------------------------------------------------------------------------+
                                    |
                                    v
+--------------------------------------------------------------------------+
|                           DATA LAYER                                      |
+--------------------------------------------------------------------------+
|                                                                          |
|  +--------------------------------------------------------------------+  |
|  |                       DATA SOURCES                                  |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  |  | UsageLocalData   |  | UsageRemoteData|  | BleDeviceDataSource|   |  |
|  |  | Source (SQLite)  |  | Source (API)   |  | (BLE Protocol)     |   |  |
|  |  |       (v)        |  |   NEW          |  |     (!) Extend     |   |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  +--------------------------------------------------------------------+  |
|                                                                          |
|  +--------------------------------------------------------------------+  |
|  |                    REPOSITORY IMPLEMENTATIONS                       |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  |  |UsageRepositoryImp|  |SyncRepositoryIm|  | AuthRepositoryImpl |   |  |
|  |  |       (v)        |  | (NEW)          |  | (NEW)              |   |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  +--------------------------------------------------------------------+  |
|                                                                          |
|  +--------------------------------------------------------------------+  |
|  |                      SYNC MANAGEMENT (NEW)                          |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  |  |  SyncManager     |  |  SyncQueue     |  | ConflictResolver   |   |  |
|  |  |  (Orchestrator)  |  |  (Offline Q)   |  | (Merge Strategy)   |   |  |
|  |  +------------------+  +----------------+  +--------------------+   |  |
|  +--------------------------------------------------------------------+  |
|                                                                          |
+--------------------------------------------------------------------------+
                    |                               |
                    v                               v
+----------------------------+    +------------------------------------+
|      LOCAL DATABASE        |    |         CLOUD SERVICE              |
+----------------------------+    +------------------------------------+
|  SQLite (dualtetrax.db)    |    |  REST API Server                   |
|  +- usage_sessions         |    |  +- POST /api/v1/sessions          |
|  +- battery_samples        |    |  +- GET  /api/v1/sessions          |
|  +- sync_queue             |    |  +- PUT  /api/v1/sessions/:uuid    |
|  +- sync_metadata          |    |  +- DELETE /api/v1/sessions/:uuid  |
+----------------------------+    |                                    |
                                  |  Auth Service                      |
                                  |  +- POST /api/v1/auth/login        |
                                  |  +- POST /api/v1/auth/refresh      |
                                  |  +- GET  /api/v1/user/profile      |
                                  +------------------------------------+
```

---

## 8. Cloud Service Design

### 8.1 REST API Specification

#### Base URL
```
Production: https://api.dualtetrax.com/v1
Staging: https://api-staging.dualtetrax.com/v1
```

#### Authentication
- OAuth 2.0 with JWT tokens
- Access Token lifetime: 1 hour
- Refresh Token lifetime: 30 days

#### Endpoints

##### Sessions API

**POST /sessions** - Upload session(s)
```json
// Request
{
  "sessions": [
    {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "device_id": "DT-XXXX-YYYY",
      "start_time": 1705276800000,
      "end_time": 1705277280000,
      "shot_type": 1,
      "mode": 2,
      "level": 2,
      "working_duration_seconds": 360,
      "pause_duration_seconds": 60,
      "pause_count": 1,
      "termination_reason": 0,
      "completion_percent": 75,
      "had_temperature_warning": false,
      "had_battery_warning": false,
      "battery_samples": [
        {"elapsed_seconds": 0, "voltage_mv": 4100},
        {"elapsed_seconds": 60, "voltage_mv": 4080},
        {"elapsed_seconds": 120, "voltage_mv": 4060}
      ]
    }
  ]
}

// Response (201 Created)
{
  "success": true,
  "uploaded_count": 1,
  "results": [
    {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "status": "created"
    }
  ]
}
```

**GET /sessions** - Get sessions with pagination
```
GET /sessions?from=1705190400000&to=1705276800000&limit=50&offset=0

// Response
{
  "total": 125,
  "limit": 50,
  "offset": 0,
  "sessions": [...]
}
```

**GET /sessions/:uuid** - Get session detail
```
// Response
{
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  ...full session data...
}
```

**DELETE /sessions/:uuid** - Delete session
```
// Response (204 No Content)
```

##### Statistics API

**GET /statistics/daily?date=2026-01-14**
```json
{
  "date": "2026-01-14",
  "total_usage_minutes": 45,
  "session_count": 3,
  "usage_by_shot": {"uShot": 25, "eShot": 20},
  "usage_by_mode": {...},
  "warning_count": 0
}
```

**GET /statistics/weekly?week_start=2026-01-13**
```json
{
  "week_start": "2026-01-13",
  "week_end": "2026-01-19",
  "total_usage_minutes": 180,
  "daily_breakdown": [
    {"date": "2026-01-13", "usage_minutes": 30},
    ...
  ]
}
```

**GET /statistics/monthly?year=2026&month=1**
```json
{
  "year": 2026,
  "month": 1,
  "total_usage_minutes": 720,
  "daily_breakdown": [...],
  "average_daily_usage": 24
}
```

##### Sync API

**GET /sync/status**
```json
{
  "last_sync_timestamp": 1705276800000,
  "pending_uploads": 0,
  "server_session_count": 125
}
```

**POST /sync/pull**
```json
// Request
{
  "last_sync_timestamp": 1705190400000
}

// Response
{
  "sessions": [...],
  "new_sync_timestamp": 1705276800000,
  "has_more": false
}
```

### 8.2 Data Sync Strategy

#### Sync Priorities
1. **Real-time sync**: 세션 종료 시 즉시 업로드 시도
2. **Background sync**: 앱 백그라운드에서 주기적 동기화 (15분)
3. **Manual sync**: 사용자 요청 시 전체 동기화

#### Conflict Resolution
```dart
enum ConflictResolution {
  serverWins,   // 서버 데이터 우선
  clientWins,   // 로컬 데이터 우선
  mergeLatest,  // 최신 업데이트 시간 기준
}

class ConflictResolver {
  UsageSession resolve(
    UsageSession local,
    UsageSession server,
    ConflictResolution strategy,
  ) {
    switch (strategy) {
      case ConflictResolution.serverWins:
        return server;
      case ConflictResolution.clientWins:
        return local;
      case ConflictResolution.mergeLatest:
        return local.updatedAt.isAfter(server.updatedAt) ? local : server;
    }
  }
}
```

#### Offline Queue
```dart
class SyncQueueManager {
  Future<void> enqueue(SyncOperation operation) async {
    await _db.insert('sync_queue', {
      'session_uuid': operation.sessionUuid,
      'action': operation.action.name,
      'payload': jsonEncode(operation.payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> processQueue() async {
    final pending = await _db.query('sync_queue',
      orderBy: 'created_at ASC',
      limit: 10,
    );

    for (final item in pending) {
      try {
        await _processItem(item);
        await _db.delete('sync_queue',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (e) {
        await _incrementRetryCount(item['id']);
      }
    }
  }
}
```

---

## 9. UI Design Specifications

### 9.1 Daily Statistics View

```
+-------------------------------------------------+
|  <- 2026년 1월 14일 (화)  ->                     |
+-------------------------------------------------+
|                                                  |
|  +------------------------------------------+   |
|  |  오늘의 사용 시간                         |   |
|  |  +-----+                                 |   |
|  |  | 45  | 분                              |   |
|  |  +-----+                                 |   |
|  |  목표: 60분 (75% 달성)                   |   |
|  |  ================------                   |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  샷 타입별 사용                           |   |
|  |                                           |   |
|  |   [PIE CHART]         U-Shot: 25분       |   |
|  |                       E-Shot: 20분       |   |
|  |                       LED: 0분           |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  세션 목록 (3개)                          |   |
|  |  +------------------------------------+  |   |
|  |  | U-Shot (Glow)    09:15-09:30       |  |   |
|  |  |    Level 2  |  15분  |  100%       |  |   |
|  |  +------------------------------------+  |   |
|  |  +------------------------------------+  |   |
|  |  | E-Shot (Lifting)  14:00-14:20      |  |   |
|  |  |    Level 3  |  20분  |  100%       |  |   |
|  |  +------------------------------------+  |   |
|  |  +------------------------------------+  |   |
|  |  | U-Shot (Tuning)  20:30-20:40       |  |   |
|  |  |    Level 2  |  10분  |  75% !      |  |   |
|  |  +------------------------------------+  |   |
|  +------------------------------------------+   |
|                                                  |
+-------------------------------------------------+
```

### 9.2 Weekly Statistics View

```
+-------------------------------------------------+
|  <- 2026년 1월 2주차 (13-19) ->                  |
+-------------------------------------------------+
|                                                  |
|  +------------------------------------------+   |
|  |  주간 총 사용 시간                        |   |
|  |  +------+                                |   |
|  |  | 180  | 분  (일평균 26분)              |   |
|  |  +------+                                |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  일별 사용 시간 (BAR CHART)               |   |
|  |                                           |   |
|  |  60|                ##                    |   |
|  |  45|     ##         ##   ##              |   |
|  |  30| ##  ##   ##    ##   ##   ##         |   |
|  |  15| ##  ##   ##    ##   ##   ##   ##    |   |
|  |   0+----------------------------------   |   |
|  |     월  화  수  목  금  토  일            |   |
|  |                         ^ 오늘           |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  샷 타입 분포                             |   |
|  |                                           |   |
|  |  U-Shot  ================--  120분 (67%) |   |
|  |  E-Shot  ==========--------   60분 (33%) |   |
|  |  LED     ------------------    0분 (0%)  |   |
|  +------------------------------------------+   |
|                                                  |
+-------------------------------------------------+
```

### 9.3 Monthly Statistics View

```
+-------------------------------------------------+
|  <- 2026년 1월 ->                                |
+-------------------------------------------------+
|                                                  |
|  +------------------------------------------+   |
|  |  월간 총 사용 시간                        |   |
|  |  +------+                                |   |
|  |  | 720  | 분  (일평균 24분)              |   |
|  |  +------+                                |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  월간 캘린더 히트맵                       |   |
|  |                                           |   |
|  |     일  월  화  수  목  금  토            |   |
|  |        []  []  [+] [+] [o] []            |   |
|  |     [] [+] [+] [#] [+] [+] []            |   |
|  |     [] [o] [+] [+] [#] [+] []            |   |
|  |     [] [+] [+] []  []  []  []            |   |
|  |     [] []  ...                           |   |
|  |                                           |   |
|  |  [] 0분  [+] 1-30분  [o] 31-45분  [#] 46+|   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  월간 트렌드 (LINE CHART)                 |   |
|  |                                           |   |
|  |  60|    /\      /\                        |   |
|  |  45|   /  \    /  \   /\                  |   |
|  |  30|  /    \  /    \ /  \                |   |
|  |  15| /      \/      \    ....            |   |
|  |   0+------------------------------------  |   |
|  |     1  5  10  15  20  25  30             |   |
|  +------------------------------------------+   |
|                                                  |
+-------------------------------------------------+
```

### 9.4 Session Detail View

```
+-------------------------------------------------+
|  <- 세션 상세                                    |
+-------------------------------------------------+
|                                                  |
|  +------------------------------------------+   |
|  |  U-Shot (Glow Mode)                       |   |
|  |  Level 2                                  |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  시간 정보                                |   |
|  |  시작: 2026-01-14 09:15:23               |   |
|  |  종료: 2026-01-14 09:30:45               |   |
|  |  작동 시간: 15분 22초                     |   |
|  |  일시정지: 2회 (총 3분 12초)              |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  종료 정보                                |   |
|  |  종료 사유: 수동 종료                     |   |
|  |  완료율: 100% (v)                         |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  배터리 변화 (LINE CHART)                 |   |
|  |                                           |   |
|  |  100%| o-----o                            |   |
|  |   80%|        -----o                      |   |
|  |   60%|              -----o                |   |
|  |   40%|                                    |   |
|  |   20%|                                    |   |
|  |    0%+----------------------------        |   |
|  |       0    5    10   15  분               |   |
|  |                                           |   |
|  |  시작: 92%  ->  종료: 85%  (소모: 7%)    |   |
|  +------------------------------------------+   |
|                                                  |
|  +------------------------------------------+   |
|  |  동기화 상태                              |   |
|  |  기기: (v)  앱: (v)  서버: (v)            |   |
|  |  UUID: 550e8400-e29b-41d4-a716-...       |   |
|  +------------------------------------------+   |
|                                                  |
+-------------------------------------------------+
```

---

## 10. Implementation Roadmap

### Phase 1: BLE Protocol Integration (Priority - v3.0)
1. **Time Sync (0x002B) 구현** - BLE 연결 시 즉시 전송
2. Bulk Session Request (0x0029) 구현
3. Session Detail Request (0x002A) 구현
4. Sync Confirm (0x0028) 구현
5. Real-time notification handlers (0x0025-0x0027)

### Phase 2: Core Statistics Enhancement
1. Weekly Statistics View 구현
2. Monthly Statistics View 구현
3. fl_chart 차트 컴포넌트 구현
   - Bar Chart (일별 사용량)
   - Pie Chart (샷 타입 분포)
   - Line Chart (트렌드)
4. Calendar Heatmap 위젯 구현
5. 날짜 네비게이션 UI

### Phase 3: Data Model Extension
1. Database schema migration (v2)
2. Extended UsageSession 모델
3. BatterySample 모델 추가
4. UUID 기반 데이터 관리
5. Migration script 구현

### Phase 4: Cloud Integration
1. REST API 클라이언트 구현
2. Authentication 모듈 (OAuth2)
3. SyncManager 구현
4. Offline queue 처리
5. Conflict resolution

### Phase 5: Advanced Features
1. 데이터 내보내기 (CSV, PDF)
2. 멀티 디바이스 지원
3. 푸시 알림 연동
4. 사용 목표 설정
5. 위젯/Apple Watch 연동

---

## 11. Dependencies

### 11.1 Existing Dependencies
```yaml
# State Management
flutter_bloc: ^8.1.3
equatable: ^2.0.5

# Local Storage
sqflite: ^2.3.0
shared_preferences: ^2.2.2

# Architecture
dartz: ^0.10.1
get_it: ^7.6.4

# Charts (already imported, not used)
fl_chart: ^0.66.0

# BLE
flutter_blue_plus: ^1.32.0
```

### 11.2 New Dependencies Needed
```yaml
# UUID Generation
uuid: ^4.2.1

# HTTP Client
dio: ^5.4.0

# Auth
flutter_secure_storage: ^9.0.0

# Date Handling
intl: ^0.18.1  # Already included

# Export
csv: ^5.1.0
pdf: ^3.10.0
share_plus: ^7.2.0

# Background Sync
workmanager: ^0.5.2
```

---

## Appendix A: Error Codes

| Code | Description | Action |
|------|-------------|--------|
| E001 | Database read error | Retry, show error |
| E002 | Database write error | Retry, show error |
| E003 | BLE connection lost | Reconnect, queue sync |
| E004 | Server unreachable | Queue for offline sync |
| E005 | Auth token expired | Refresh token |
| E006 | Sync conflict | Apply conflict resolution |
| E007 | Invalid UUID | Log error, skip record |
| E008 | Data corruption | Restore from server |
| E009 | Time sync failed | Retry, warn user about timestamps |

---

## Appendix B: Localization Keys

```dart
// Statistics Page
'statistics': '통계',
'daily': '일별',
'weekly': '주별',
'monthly': '월별',
'dailyUsageTime': '오늘의 사용 시간',
'weeklyUsageTime': '주간 사용 시간',
'monthlyUsageTime': '월간 사용 시간',
'usageByShot': '샷 타입별 사용',
'sessionList': '세션 목록',
'goalAchievement': '목표 달성률',
'averageDaily': '일평균',

// Session Detail
'sessionDetail': '세션 상세',
'startTime': '시작 시간',
'endTime': '종료 시간',
'workingDuration': '작동 시간',
'pauseDuration': '일시정지 시간',
'pauseCount': '일시정지 횟수',
'terminationReason': '종료 사유',
'completionPercent': '완료율',
'batteryChange': '배터리 변화',
'syncStatus': '동기화 상태',

// Termination Reasons
'timeout8Min': '8분 타임아웃',
'manualPowerOff': '수동 종료',
'batteryDrain': '배터리 방전',
'overheat': '과열',
'overheatUltrasonic': '초음파 과열',
'overheatBody': '본체 과열',
'chargingStarted': '충전 시작',

// Sync
'syncing': '동기화 중...',
'syncComplete': '동기화 완료',
'syncFailed': '동기화 실패',
'lastSynced': '마지막 동기화',
'pendingSync': '동기화 대기 중',
'timeSyncRequired': '시간 동기화 필요',
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-07 | - | Initial mobile app implementation |
| 2.0 | 2026-01-14 | Claude | Added weekly/monthly views, cloud sync, extended data model |
| 3.0 | 2026-01-14 | Claude | **RAM-only architecture update**: Added Time Sync Protocol (0x002B), Updated BLE sync flow, App becomes permanent storage |
| 3.1 | 2026-01-27 | Claude | **Time Sync Status**: Added `time_synced` field, timestamp reassignment policy, UI color differentiation |
