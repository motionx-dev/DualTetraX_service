# DualTetraX 펌웨어 요구사항 - 모바일 앱 연동 지원
Version: 1.0
Date: 2025-11-18

## 1. 개요

### 1.1 목적
본 문서는 DualTetraX 모바일 애플리케이션과의 연동을 위해 DualTetraX 디바이스 펌웨어에 추가로 구현되어야 할 요구사항을 정의한다.

### 1.2 범위
- BLE(Bluetooth Low Energy) Peripheral 기능 추가
- BLE 서비스 및 Characteristic 정의
- 상태 변화 이벤트 전송 메커니즘
- 사용 세션(Usage Session) 추적 및 전송
- 전력 효율적인 BLE 통신

### 1.3 참조 문서
- DualTetraX Mobile App Requirements (DualTetraX_Mobile_App_Requirements_v1.md)
- DualTetraX Device FW Requirements (Device_FW_Requirement-V2.md)

### 1.4 설계 원칙
- 기존 DualTetraX 펌웨어 요구사항과 충돌하지 않는다
- 모바일 앱은 디바이스의 동작을 제어하는 주체가 아니며, 상태를 조회하고 기록하는 역할만 수행한다
- BLE 통신은 디바이스 배터리 소모를 최소화하는 방향으로 설계한다
- 이벤트 기반(Event-driven) 데이터 전송을 기본으로 한다


## 2. BLE 기본 요구사항

### REQ-BLE-001: BLE Peripheral 역할
- DualTetraX는 BLE Peripheral로 동작해야 한다
- 모바일 앱(BLE Central)이 DualTetraX를 스캔하고 연결할 수 있어야 한다

### REQ-BLE-002: 디바이스 광고(Advertising)
- DualTetraX는 전원이 켜진 상태(PWR-On 이후)에 BLE 광고를 송출해야 한다
- 광고 데이터에 디바이스 이름을 포함해야 한다
- 디바이스 이름 형식: `DualTetraX-XXXX`
  - XXXX는 MAC 주소의 마지막 2바이트를 Hex로 표현 (예: `DualTetraX-A1B2`)
- 모바일 앱은 `DualTetraX-` Prefix를 기준으로 디바이스를 식별한다

### REQ-BLE-003: 광고 시작/중지 조건
- PWR-On 상태 진입 시 BLE 광고를 시작해야 한다
- PWR-Off 상태 진입 시 BLE 광고를 중지해야 한다
- Standby 상태에서는 광고를 유지하거나 중지할 수 있다 (전력 효율 고려)

### REQ-BLE-004: 연결 관리
- 동시에 최소 1개의 BLE Central(모바일 앱) 연결을 지원해야 한다
- 연결 상태와 무관하게 디바이스의 기본 동작(버튼, Shot, 모드, 레벨 등)은 정상 동작해야 한다
- 연결이 끊어진 경우에도 디바이스는 정상 동작을 유지해야 한다

### REQ-BLE-005: BLE Bonding 지원
- 재연결 시 페어링 과정을 생략하기 위해 BLE Bonding을 지원해야 한다
- 본딩된 디바이스 정보를 플래시 메모리에 저장해야 한다
- 최소 1개 이상의 본딩된 디바이스 정보를 저장할 수 있어야 한다


## 3. BLE 서비스 및 Characteristic 요구사항

### 3.1 Device Info Service

#### REQ-BLE-SVC-001: 서비스 정의
- UUID: 표준 Device Information Service (0x180A) 또는 커스텀 UUID 사용
- Read-only Characteristic들로 구성

#### REQ-BLE-CHAR-001: Firmware Version
- 현재 펌웨어 버전 정보 제공 (예: "1.2.3")
- Read 속성

#### REQ-BLE-CHAR-002: Model Name
- 디바이스 모델명 제공 (예: "DualTetraX")
- Read 속성

#### REQ-BLE-CHAR-003: Serial Number
- 디바이스 고유 시리얼 번호 제공
- Read 속성

#### REQ-BLE-CHAR-004: Hardware Revision (선택)
- 하드웨어 리비전 정보 제공
- Read 속성

### 3.2 Realtime Status Service

#### REQ-BLE-SVC-002: 서비스 정의
- 커스텀 UUID 사용
- 디바이스의 실시간 상태를 제공하는 Characteristic들로 구성

#### REQ-BLE-CHAR-010: Current Shot Type
- 현재 Shot 타입 제공: U-Shot(0x01), E-Shot(0x02), LED Care(0x03), Unknown(0x00)
- Read 및 Notify 속성
- Shot 타입 변경 시 자동으로 Notify 전송

#### REQ-BLE-CHAR-011: Current Mode
- 현재 모드 제공
  - U-Shot: Glow(0x01), Tuning(0x02), Renewal(0x03), Volume(0x04)
  - E-Shot: Cleansing(0x11), Firming(0x12), Lifting(0x13), LF(0x14)
  - LED Care: LED Mode(0x21)
  - Unknown(0x00)
- Read 및 Notify 속성
- 모드 변경 시 자동으로 Notify 전송

#### REQ-BLE-CHAR-012: Current Level
- 현재 Level 제공: Level 1(0x01), Level 2(0x02), Level 3(0x03), Unknown(0x00)
- Read 및 Notify 속성
- Level 변경 시 자동으로 Notify 전송

#### REQ-BLE-CHAR-013: Working State
- 현재 동작 상태 제공
  - Working(0x01): U-Shot/E-Shot 동작 중
  - Pause(0x02): 일시정지 상태
  - Standby(0x03): 대기 상태
  - Off(0x00): 전원 꺼짐
- Read 및 Notify 속성
- 상태 변경 시 자동으로 Notify 전송

#### REQ-BLE-CHAR-014: Battery Status
- 배터리 상태 제공
  - Level: 0~100 (퍼센트)
  - State: 충분(0x01), 부족(0x02), 방전 경고(0x03), 충전 중(0x04)
- Read 및 Notify 속성
- 배터리 상태 임계점 변경 시 Notify 전송 (충분↔부족↔방전 경고 전환 시)

#### REQ-BLE-CHAR-015: Warning Status
- 현재 Warning 상태 제공
  - Bit 0: 온도 Warning (1=발생, 0=정상)
  - Bit 1: 배터리 부족 Warning
  - Bit 2: 배터리 방전 Warning
  - Bit 3~7: 추후 확장용
- Read 및 Notify 속성
- Warning 발생/해제 시 자동으로 Notify 전송

#### REQ-BLE-CHAR-016: Charging Status
- 충전 상태 제공
  - Not Charging(0x00), Charging(0x01), Fully Charged(0x02)
- Read 및 Notify 속성
- 충전 상태 변경 시 Notify 전송

### 3.3 Usage Session Service

#### REQ-BLE-SVC-003: 서비스 정의
- 커스텀 UUID 사용
- 사용 세션(Usage Session) 정보를 제공하는 Characteristic들로 구성

#### REQ-BLE-CHAR-020: Session Event
- 세션 관련 이벤트를 Notify로 전송
- 이벤트 타입:
  - SESSION_START(0x01): Working 상태 진입 시
  - SESSION_END(0x02): Working 종료 시 (Pause, Standby, Off 전환)
  - MODE_CHANGED(0x03): 모드 변경 시
  - LEVEL_CHANGED(0x04): 레벨 변경 시
  - WARNING_OCCURRED(0x05): Warning 발생 시
  - WARNING_CLEARED(0x06): Warning 해제 시
- 데이터 포맷:
  - Byte 0: Event Type
  - Byte 1-4: Timestamp (Unix time 또는 디바이스 uptime in seconds)
  - Byte 5-N: Event-specific data
- Notify 속성 (Read 불필요)

#### REQ-BLE-CHAR-021: Session Details (선택)
- 현재 진행 중인 세션의 상세 정보 제공
  - 세션 시작 시각
  - 현재까지의 사용 시간 (초)
  - Shot 타입, 모드, 레벨
  - Pause 시간 누적 (초)
  - Warning 발생 이력
- Read 속성

### 3.4 Config/Control Service (선택 사항)

#### REQ-BLE-SVC-004: 서비스 정의
- 커스텀 UUID 사용
- 디바이스 설정 및 제어를 위한 Characteristic들로 구성

#### REQ-BLE-CHAR-030: Time Sync
- 모바일 앱에서 디바이스로 현재 시각 전송
- Unix timestamp (4 bytes)
- Write 속성
- 디바이스는 수신한 시각을 RTC 또는 내부 타이머에 반영

#### REQ-BLE-CHAR-031: Device Control (선택)
- 제한적인 디바이스 제어 기능 (추후 확장 시 고려)
- 예: 데이터 리셋 요청, 디바이스 리부팅 등
- Write 속성
- 주의: 기존 FW 요구사항과 충돌하지 않는 범위 내에서만 구현


## 4. 이벤트 기반 데이터 전송 요구사항

### REQ-EVENT-001: 이벤트 트리거 조건
- 다음 상태 변화 시 BLE Notify를 통해 이벤트를 전송해야 한다:
  1. Working 상태 진입 (SESSION_START)
  2. Working 상태 종료 (SESSION_END)
  3. Shot 타입 변경 (U ↔ E ↔ LED)
  4. 모드 변경
  5. 레벨 변경
  6. Warning 발생
  7. Warning 해제
  8. 배터리 상태 임계점 변경 (충분 ↔ 부족 ↔ 방전)
  9. 충전 상태 변경 (충전 시작, 충전 완료)

### REQ-EVENT-002: 이벤트 전송 타이밍
- 상태 변화 발생 후 1초 이내에 BLE Notify를 전송해야 한다
- BLE 연결이 없는 경우 이벤트는 전송하지 않는다 (저장하지 않음)

### REQ-EVENT-003: 주기적 폴링 최소화
- 모바일 앱의 주기적인 Read 요청을 최소화하기 위해 Notify 기반 전송을 우선한다
- 상태가 변경되지 않았을 때는 데이터를 전송하지 않는다

### REQ-EVENT-004: 연결 시 초기 상태 전송
- 모바일 앱이 BLE 연결 직후, 현재 상태를 알 수 있도록 연결 직후 1회 모든 상태 Characteristic에 대해 Notify를 전송할 수 있다 (선택)
- 또는 앱이 연결 직후 각 Characteristic을 Read하는 방식으로 초기 상태를 파악할 수 있다


## 5. 사용 세션(Usage Session) 추적 요구사항

### REQ-SESSION-001: 세션 시작 감지
- Working 상태 진입 시를 세션 시작으로 정의한다
- SESSION_START 이벤트를 전송하며, 다음 정보를 포함한다:
  - Timestamp (세션 시작 시각)
  - Shot 타입
  - 모드
  - 레벨
  - 배터리 상태

### REQ-SESSION-002: 세션 종료 감지
- Working 상태에서 Pause, Standby, 또는 Off 상태로 전환 시를 세션 종료로 정의한다
- SESSION_END 이벤트를 전송하며, 다음 정보를 포함한다:
  - Timestamp (세션 종료 시각)
  - 총 Working 시간 (초)
  - 총 Pause 시간 (초)
  - 세션 중 발생한 Warning 플래그

### REQ-SESSION-003: 세션 중 상태 변경 추적
- Working 상태가 유지되는 동안 모드/레벨이 변경되면:
  - 해당 변경 이벤트를 전송하되, 세션은 종료하지 않는다
  - 모바일 앱에서 동일 세션 내 여러 모드/레벨 사용 이력을 기록할 수 있도록 한다

### REQ-SESSION-004: 타임스탬프 제공
- 각 이벤트에 타임스탬프를 포함해야 한다
- Unix timestamp (초 단위) 또는 디바이스 부팅 후 경과 시간(uptime)을 사용할 수 있다
- 모바일 앱과 시각 동기화를 위해 Time Sync Characteristic을 지원하는 것이 권장된다


## 6. 전력 효율 요구사항

### REQ-POWER-001: BLE 광고 간격 최적화
- BLE 광고 간격은 전력 소모와 연결 속도를 고려하여 설정한다
- 권장: 100ms ~ 1000ms 범위 내에서 설정
- Standby 상태에서는 광고 간격을 늘리거나 광고를 중지하여 전력을 절약할 수 있다

### REQ-POWER-002: BLE Connection Interval 최적화
- BLE 연결 시 Connection Interval을 적절히 설정하여 전력 소모를 최소화한다
- 권장: 100ms ~ 400ms 범위 (데이터 전송 빈도와 배터리 수명 균형)
- Slave Latency를 활용하여 불필요한 통신을 생략할 수 있다

### REQ-POWER-003: 불필요한 데이터 전송 제한
- Standby 또는 Off 상태에서는 Notify 전송을 최소화한다
- 상태가 변경되지 않는 경우 중복된 데이터를 전송하지 않는다

### REQ-POWER-004: BLE 연결 유지 정책
- 장시간(예: 5분 이상) Working 상태가 없고 앱에서 요청이 없는 경우, 연결을 자동으로 해제할 수 있다 (선택)
- 디바이스의 배터리 절약을 위해 불필요한 연결 유지를 피한다


## 7. 보안 및 인증 요구사항

### REQ-SEC-001: BLE Bonding
- BLE Bonding을 통해 페어링 정보를 저장하고, 재연결 시 인증 과정을 생략한다
- 본딩된 디바이스 정보는 플래시 메모리에 저장한다

### REQ-SEC-002: 접근 제어 (선택)
- 특정 모바일 앱만 연결할 수 있도록 고유 식별자/토큰 교환 메커니즘을 고려할 수 있다
- 초기 버전에서는 BLE Bonding으로 충분할 수 있으며, 추후 확장 시 고려

### REQ-SEC-003: 데이터 암호화
- BLE 통신 시 암호화를 적용하여 데이터 보안을 강화한다
- ESP32의 BLE 스택이 제공하는 암호화 기능을 활용한다


## 8. 예외 처리 및 안정성 요구사항

### REQ-EXC-001: BLE 연결 실패 시 동작
- BLE 연결이 실패하거나 끊어진 경우에도 디바이스의 기본 동작(버튼, Shot, 모드, 레벨 등)은 정상 동작해야 한다
- 사용자는 모바일 앱 없이도 디바이스를 사용할 수 있어야 한다

### REQ-EXC-002: 버퍼 오버플로우 방지
- BLE Notify 큐가 가득 찬 경우, 새로운 이벤트를 전송하지 못할 수 있다
- 이 경우 중요한 이벤트(예: SESSION_START, SESSION_END, WARNING)를 우선적으로 전송하고, 덜 중요한 이벤트는 드롭할 수 있다

### REQ-EXC-003: 연결 끊김 시 데이터 손실
- BLE 연결이 끊어진 동안 발생한 이벤트는 전송되지 않는다
- 디바이스는 이벤트 이력을 저장하지 않으며, 모바일 앱은 연결이 끊어진 시간 동안의 데이터 손실을 감수해야 한다
- (추후 확장 시 디바이스 내부에 이벤트 로그를 저장하고, 재연결 시 동기화하는 기능을 추가할 수 있다)

### REQ-EXC-004: 충전 중 BLE 동작
- 충전 중에도 BLE 광고 및 연결은 유지될 수 있다
- 모바일 앱이 충전 상태를 확인할 수 있도록 Charging Status Characteristic을 제공한다
- 충전 중에는 Working 상태가 발생하지 않으므로, SESSION_START/END 이벤트는 발생하지 않는다


## 9. 성능 요구사항

### REQ-PERF-001: BLE 연결 시간
- 모바일 앱이 스캔을 시작한 후 10초 이내에 디바이스를 발견할 수 있어야 한다 (광고 중인 경우)
- 연결 요청 후 5초 이내에 연결이 완료되어야 한다

### REQ-PERF-002: 이벤트 전송 지연
- 상태 변화 발생 후 1초 이내에 BLE Notify를 전송해야 한다
- 네트워크 상태에 따라 실제 수신 시간은 더 걸릴 수 있다

### REQ-PERF-003: 다중 Characteristic Notify
- 동시에 여러 Characteristic의 상태가 변경되는 경우 (예: Shot 타입, 모드, 레벨이 동시에 변경), 각 Characteristic에 대해 개별적으로 Notify를 전송해야 한다
- Notify 전송 간격은 최소 10ms 이상 확보하여 BLE 스택의 안정성을 보장한다


## 10. 테스트 요구사항

### REQ-TEST-001: BLE 광고 확인
- 디바이스 전원 On 시 BLE 광고가 정상적으로 송출되는지 확인한다
- 모바일 앱 또는 BLE 스캐너 앱으로 "DualTetraX-XXXX" 이름을 확인한다

### REQ-TEST-002: 연결 및 재연결 테스트
- 모바일 앱과 정상적으로 연결되는지 확인한다
- 연결 해제 후 재연결이 자동으로 이루어지는지 확인한다
- BLE Bonding이 정상 동작하는지 확인한다

### REQ-TEST-003: 이벤트 전송 테스트
- Working 상태 진입/종료 시 SESSION_START/END 이벤트가 전송되는지 확인한다
- 모드/레벨 변경 시 해당 Characteristic의 Notify가 전송되는지 확인한다
- Warning 발생/해제 시 Notify가 전송되는지 확인한다

### REQ-TEST-004: 전력 소모 테스트
- BLE 광고 및 연결 상태에서의 전력 소모를 측정한다
- BLE 활성화로 인한 배터리 수명 감소가 허용 범위 내인지 확인한다
- (예: BLE 활성화 시 배터리 수명이 10% 이상 감소하지 않도록)

### REQ-TEST-005: 안정성 테스트
- BLE 연결 상태와 무관하게 디바이스의 기본 기능이 정상 동작하는지 확인한다
- BLE 연결 실패, 타임아웃, 연결 끊김 등의 예외 상황에서도 디바이스가 정상 동작하는지 확인한다


## 11. 기존 FW 요구사항과의 정합성

### 11.1 충돌하지 않는 부분
- BLE 기능은 기존 디바이스의 전원, Shot, 모드, 레벨, Working/Pause/Standby, 배터리, Warning 동작 로직을 변경하지 않는다
- BLE는 기존 상태를 **외부로 노출**하는 역할만 수행한다
- 모바일 앱은 디바이스의 동작을 제어하는 주체가 아니며, 상태를 조회하고 기록하는 역할만 수행한다

### 11.2 추가되는 부분
- BLE Peripheral 기능 (ESP32 BLE 스택 활용)
- BLE 서비스 및 Characteristic 정의 및 구현
- 상태 변화 감지 및 이벤트 전송 로직
- 사용 세션 추적 및 타임스탬프 관리
- BLE 연결 관리 및 전력 최적화

### 11.3 확장 고려 사항
- 추후 모바일 앱에서 디바이스 설정을 변경하는 기능이 추가될 경우, 기존 FW 요구사항과 충돌하지 않는 범위 내에서만 구현한다
- 예: 사용자가 선호하는 기본 모드/레벨 설정을 저장하는 기능 (디바이스 전원 On 시 해당 모드/레벨로 자동 설정)


## 12. 구현 우선순위

### 우선순위 1 (필수)
- REQ-BLE-001 ~ REQ-BLE-005: BLE 기본 기능
- REQ-BLE-SVC-001 ~ REQ-BLE-CHAR-003: Device Info Service
- REQ-BLE-SVC-002, REQ-BLE-CHAR-010 ~ REQ-BLE-CHAR-016: Realtime Status Service
- REQ-EVENT-001 ~ REQ-EVENT-004: 이벤트 기반 데이터 전송
- REQ-SESSION-001 ~ REQ-SESSION-004: 사용 세션 추적

### 우선순위 2 (권장)
- REQ-BLE-SVC-003, REQ-BLE-CHAR-020 ~ REQ-BLE-CHAR-021: Usage Session Service
- REQ-POWER-001 ~ REQ-POWER-004: 전력 효율
- REQ-SEC-001: BLE Bonding

### 우선순위 3 (선택)
- REQ-BLE-SVC-004, REQ-BLE-CHAR-030 ~ REQ-BLE-CHAR-031: Config/Control Service
- REQ-SEC-002 ~ REQ-SEC-003: 고급 보안 기능


## 13. BLE 프로토콜 상세 정의 (별도 문서 필요)

본 요구사항 문서는 BLE 기능의 **전반적인 요구사항**을 정의한다.
실제 구현을 위해서는 다음 내용을 포함하는 **BLE 프로토콜 상세 설계 문서**가 별도로 작성되어야 한다:

1. **각 서비스 및 Characteristic의 UUID**
   - Device Info Service: UUID
   - Realtime Status Service: UUID
   - Usage Session Service: UUID
   - Config/Control Service: UUID
   - 각 Characteristic의 UUID

2. **데이터 포맷 정의**
   - 각 Characteristic의 바이트 레이아웃
   - Endianness (Big/Little Endian)
   - Enum 값 정의 (Shot 타입, 모드, 레벨, 상태 등)

3. **이벤트 데이터 구조**
   - SESSION_START 이벤트 데이터 포맷
   - SESSION_END 이벤트 데이터 포맷
   - 기타 이벤트 데이터 포맷

4. **타임스탬프 동기화 메커니즘**
   - Unix timestamp vs. Uptime
   - Time Sync Characteristic 사용 방법

5. **오류 처리 및 예외 상황**
   - 각 Characteristic의 오류 코드 정의
   - 연결 실패, 타임아웃 등의 처리 방법


## 14. 요약

본 문서는 DualTetraX 모바일 애플리케이션과의 연동을 위해 DualTetraX 디바이스 펌웨어에 추가로 구현되어야 할 요구사항을 정의하였다.

**주요 추가 기능:**
- BLE Peripheral 기능 (광고, 연결, Bonding)
- 3개의 주요 BLE 서비스 (Device Info, Realtime Status, Usage Session)
- 이벤트 기반 데이터 전송 (상태 변화 시 자동 Notify)
- 사용 세션 추적 및 타임스탬프 관리
- 전력 효율적인 BLE 통신

**설계 원칙:**
- 기존 FW 요구사항과 충돌하지 않음
- 이벤트 기반 전송으로 배터리 효율 최적화
- 모바일 앱은 상태 조회 및 기록 역할만 수행

**다음 단계:**
- BLE 프로토콜 상세 설계 문서 작성
- BLE 서비스/Characteristic UUID 할당
- 데이터 포맷 및 이벤트 구조 정의
- 펌웨어 구현 및 테스트
