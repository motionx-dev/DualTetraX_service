# DualTetraX Cloud Services - 전체 요구사항 분석서

**버전**: 3.0
**작성일**: 2026-02-08
**상태**: 작성 완료

---

## 1. 프로젝트 개요

### 1.1 목적
DualTetraX 뷰티 디바이스 사용자를 위한 클라우드 서비스 플랫폼.
모바일 앱(Flutter)에서 BLE로 수집된 디바이스 사용 데이터를 서버에 동기화하고,
웹 대시보드에서 통계/관리/개인화 기능을 제공한다.

### 1.2 시스템 구성도

```
┌──────────────┐     BLE      ┌──────────────┐    REST API    ┌──────────────┐
│  DualTetraX  │◄────────────►│  Mobile App  │──────────────►│  Backend API │
│   Device     │              │  (Flutter)   │               │              │
└──────────────┘              └──────────────┘               └──────┬───────┘
                                                                    │
                                    ┌───────────────────────────────┤
                                    │               │               │
                              ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
                              │ Supabase   │  │ Supabase  │  │  Upstash  │
                              │ PostgreSQL │  │   Auth    │  │   Redis   │
                              └───────────┘  └───────────┘  └───────────┘

                              ┌──────────────┐
                              │  Frontend    │ ← 웹 대시보드 + 관리자 콘솔
                              │  (Next.js)   │
                              └──────────────┘
```

### 1.3 기술 스택

| 계층 | 기술 | 비고 |
|------|------|------|
| Backend API | Node.js + Vercel Serverless | `@vercel/node` runtime (MVP) |
| Frontend | Next.js 14 + Tailwind CSS | App Router, 다크모드 |
| Database | Supabase (PostgreSQL) | RLS 적용 |
| Authentication | Supabase Auth | 이메일/비밀번호 + 소셜 로그인 |
| Cache | Upstash Redis | JWT 블랙리스트, 세션 캐시 |
| Validation | Zod | API 입력 검증 |
| Charts | Recharts | 통계 시각화 |
| Target Infra | AWS (Phase 2+) | ECS, RDS, ElastiCache, S3 |

### 1.4 구현 단계 정의

| Phase | 인프라 | 범위 | 시기 |
|-------|--------|------|------|
| **Phase 1** | Vercel → AWS (사용자 증가 시 전환) | **전체 서비스**: 소셜 로그인, OTA, 관리자, 디바이스 분석, GDPR 등 | 현재~서비스 안정화 |
| **Phase 2** | AWS 확장 | AI 개인화 서비스 (ML 모델, 추천 시스템) | Phase 1 데이터 축적 후 |

> **Phase 1 상세**: Vercel에서 모든 기능을 구현하여 시작한다. 사용자가 증가하면 AWS(ECS, RDS, ElastiCache)로 무중단 전환한다. 전환을 위한 코드 추상화 레이어는 처음부터 설계한다.

### 1.5 사용자 규모 예측

| 시점 | 사용자 수 | 디바이스 수 | 일일 세션 | 인프라 |
|------|----------|------------|----------|--------|
| 초기 | < 20 | < 20 | < 50 | Vercel |
| 6개월 | 500 | 600 | ~1,000 | Vercel/AWS 판단 |
| 1년 | 2,000 | 2,500 | ~4,000 | AWS |
| 2년 | 10,000 | 12,000 | ~20,000 | AWS 스케일링 |

---

## 2. 기능 요구사항 (Functional Requirements)

### 2.1 사용자 관리 (User Management)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-UM-001 | 이메일/비밀번호 회원가입 및 로그인 | 필수 | 1 |
| FR-UM-002 | 소셜 로그인 (Google, Apple Sign-In) | **필수** | **1** |
| FR-UM-003 | 2단계 인증 (2FA) - TOTP, SMS | 보통 | 1 |
| FR-UM-004 | 비밀번호 재설정 (이메일 링크) | 필수 | 1 |
| FR-UM-005 | 프로필 관리 (이름, 성별, 생년월일, 프로필 사진) | 필수 | 1 |
| FR-UM-006 | 알림 설정 (푸시, 이메일, 사용 리마인더) | 보통 | 1 |

**상세 설명**:
- **FR-UM-001**: Supabase Auth `signUp()`, `signInWithPassword()` 사용. 이메일 확인 필수.
- **FR-UM-002**: Supabase Auth의 OAuth2 Provider 활용. Google/Apple OAuth flow.
- **FR-UM-003**: Supabase Auth MFA 기능 또는 커스텀 TOTP 구현.
- **FR-UM-004**: Supabase Auth `resetPasswordForEmail()`. 매직 링크 지원.
- **FR-UM-005**: profiles 테이블에 사용자 프로필 저장. 프로필 사진은 Supabase Storage 사용.
- **FR-UM-006**: notification_settings 테이블. 푸시(FCM/APNs), 이메일, 앱 내 알림.

### 2.2 디바이스 관리 (Device Management)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-DM-001 | 시리얼 번호로 디바이스 등록 | 필수 | 1 |
| FR-DM-002 | 디바이스 소유권 이전 | 보통 | 1 |
| FR-DM-003 | 내 디바이스 목록 조회 | 필수 | 1 |
| FR-DM-004 | 디바이스 상세 정보 (펌웨어, BLE MAC, 마지막 동기화) | 필수 | 1 |
| FR-DM-005 | 디바이스 비활성화/삭제 | 보통 | 1 |
| FR-DM-006 | 디바이스 대량 관리 (관리자용) | 보통 | 1 |
| FR-DM-007 | 펌웨어 버전 관리 + OTA 배포 | **필수** | **1** |
| FR-DM-008 | 디바이스 이상 감지 알림 (과열, 배터리 이상 빈도) | 보통 | 1 |
| FR-DM-009 | 디바이스 펌웨어 업데이트 이력 관리 | 필수 | 1 |
| FR-DM-010 | 디바이스 분석 대시보드 (평균 사용시간, 기능별 사용빈도, 배터리 분석, 연령층 분포) | **필수** | **1** |

**상세 설명**:
- **FR-DM-001**: serial_number UNIQUE. 모바일 앱에서 BLE 연결 시 자동 등록 또는 수동 입력.
- **FR-DM-002**: device_transfers 테이블로 소유권 이전 이력 관리. 요청→승인 플로우.
- **FR-DM-003**: devices 테이블에서 user_id 기반 조회. RLS 적용.
- **FR-DM-004**: firmware_version, ble_mac_address, last_synced_at 등 표시.
- **FR-DM-005**: is_active 플래그로 소프트 삭제. 하드 삭제는 관리자만.
- **FR-DM-006**: 관리자 대시보드에서 전체 디바이스 목록, 필터, 검색.
- **FR-DM-007**: firmware_versions 테이블. 버전별 활성화/비활성화.
- **FR-DM-008**: 세션 데이터 분석 → 비정상 패턴(과열 빈도 높음 등) 감지.
- **FR-DM-009**: firmware_update_history 테이블. OTA 업데이트 이력 추적.
- **FR-DM-010**: 관리자 분석 대시보드 — 평균 사용 시간, 자주 사용하는 제품 기능(모드), 배터리 소모 분석, 사용자 연령층 분포, 시간대별 사용 히트맵, 종료 사유 분석, FW 버전 분포 그래프. 마케팅 전략 및 차기 제품 개발에 활용.

### 2.3 사용 데이터 (Usage Data)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-UD-001 | 세션 배치 업로드 (UUID 기반 중복 제거) | 필수 | 1 |
| FR-UD-002 | 세션 목록 조회 (날짜 범위, 디바이스 필터) | 필수 | 1 |
| FR-UD-003 | 일별/주별/월별 통계 집계 | 필수 | 1 |
| FR-UD-004 | 사용 패턴 분석 (선호 모드, 시간대별 사용) | 보통 | 1 |
| FR-UD-005 | 사용 목표 설정 및 달성률 추적 | 보통 | 1 |
| FR-UD-006 | 세션 기록 내보내기 (CSV/Excel) | 보통 | 1 |
| FR-UD-007 | 세션 기록 삭제 (개별/전체) | 보통 | 1 |
| FR-UD-008 | 배터리 샘플 데이터 저장 및 시각화 | 필수 | 1 |

**상세 설명**:
- **FR-UD-001**: `ON CONFLICT (id) DO NOTHING`으로 중복 방지. 앱 UUID = PK.
- **FR-UD-002**: 날짜 범위, 디바이스 ID, shot_type 등 복합 필터 지원.
- **FR-UD-003**: daily_statistics 테이블. 세션 업로드 시 자동 집계 + 주기적 배치 집계.
- **FR-UD-004**: 모드별/레벨별/시간대별 사용 빈도 분석. JSONB 필드 활용.
- **FR-UD-005**: user_goals 테이블. 주간/월간 목표 분(minutes). 달성률 계산.
- **FR-UD-006**: CSV 다운로드 API. 날짜 범위 선택. 최대 1년치.
- **FR-UD-007**: 세션 삭제 시 관련 battery_samples, daily_statistics 재계산.
- **FR-UD-008**: battery_samples 테이블. 세션별 1분 간격 전압(mV) 데이터.

### 2.4 개인화 서비스 (Personalization)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-PS-001 | AI 기반 사용 추천 (사용 패턴 분석) | 높음 | **2** |
| FR-PS-002 | 맞춤형 콘텐츠 제공 (사용 가이드, 팁) | 보통 | **2** |
| FR-PS-003 | 사용 리포트 (주간/월간 요약 이메일) | 보통 | 1 |
| FR-PS-004 | 사용 비교 (이전 기간 대비 변화) | 보통 | 1 |
| FR-PS-005 | 업적/뱃지 시스템 | 낮음 | **2** |
| FR-PS-006 | 피부 프로필 관리 (피부 타입, 고민) | 보통 | 1 |
| FR-PS-007 | 커뮤니티/공유 기능 | 낮음 | **2** |

**상세 설명**:
- **FR-PS-001**: 사용 패턴 기반 모드/레벨 추천. recommendations 테이블.
- **FR-PS-006**: skin_profiles 테이블. 피부 타입(건성/지성/복합/민감), 주요 고민.

### 2.5 관리자 기능 (Administration)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-AD-001 | 사용자 목록/검색 | 필수 | 1 |
| FR-AD-002 | 사용자 상세 정보 조회 | 필수 | 1 |
| FR-AD-003 | 사용자 계정 관리 (비활성화, 역할 변경) | 필수 | 1 |
| FR-AD-004 | 대시보드 (KPI: 총 사용자, 활성 사용자, 세션 수) | 필수 | 1 |
| FR-AD-005 | 디바이스 전체 관리 (등록 현황, 모델별 통계) | 필수 | 1 |
| FR-AD-006 | 감사 로그 (관리자 행위 기록) | 필수 | 1 |
| FR-AD-007 | 공지사항 관리 (CRUD) | 필수 | 1 |
| FR-AD-008 | 통계 리포트 (사용량 트렌드, 디바이스별 분석) | 필수 | 1 |
| FR-AD-009 | 펌웨어 배포 관리 (OTA 롤아웃) | **필수** | **1** |
| FR-AD-010 | 콘텐츠 관리 (사용 가이드, FAQ) | 보통 | **2** |

**상세 설명**:
- **FR-AD-001~003**: profiles 테이블의 role='admin' 사용자만 접근. admin_logs 기록.
- **FR-AD-004**: service_role_key로 집계 쿼리. 실시간 KPI 대시보드.
- **FR-AD-006**: admin_logs 테이블. 관리자 행위(사용자 수정, 디바이스 관리 등) 기록.
- **FR-AD-007**: announcements 테이블. 공지사항 CRUD + 앱/웹 푸시.

### 2.6 웹 프론트엔드 (Web Frontend)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-WF-001 | 랜딩 페이지 (서비스 소개) | 필수 | 1 |
| FR-WF-002 | 로그인/회원가입/비밀번호 재설정 페이지 | 필수 | 1 |
| FR-WF-003 | 사용자 대시보드 (요약 통계, 차트) | 필수 | 1 |
| FR-WF-004 | 반응형 디자인 + 다크모드 | 필수 | 1 |
| FR-WF-005 | 관리자 콘솔 (FR-AD 기능 웹 UI + 디바이스 분석 대시보드) | **필수** | **1** |
| FR-WF-006 | 프로필/설정 페이지 | 필수 | 1 |

### 2.7 개인정보 보호 (Privacy)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-PR-001 | 개인정보 동의 관리 (약관, 마케팅) | 필수 | 1 |
| FR-PR-002 | 동의 이력 관리 (동의/철회 시점 기록) | 필수 | 1 |
| FR-PR-003 | 데이터 열람 요청 (GDPR Article 15) | 보통 | 1 |
| FR-PR-004 | 데이터 삭제 요청 (GDPR Right to Erasure) | 보통 | 1 |
| FR-PR-005 | 데이터 이동성 (GDPR Data Portability) | 보통 | 1 |
| FR-PR-006 | PII 분리 저장 (민감 데이터 암호화) | 보통 | 1 |

**상세 설명**:
- **FR-PR-001~002**: consent_records 테이블. 동의 항목별 동의/철회 이력.
- **FR-PR-004**: 계정 삭제 시 CASCADE로 모든 관련 데이터 삭제. 30일 유예 기간.

### 2.8 타임존 관리 (Timezone)

| ID | 요구사항 | 우선순위 | Phase |
|----|---------|---------|-------|
| FR-TZ-001 | 사용자별 타임존 설정 (profiles.timezone) | 필수 | 1 |
| FR-TZ-002 | 통계 집계 시 타임존 기반 날짜 경계 적용 | 필수 | 1 |
| FR-TZ-003 | 세션 시간 표시 시 사용자 타임존 변환 | 필수 | 1 |

---

## 3. 비기능 요구사항 (Non-Functional Requirements)

### 3.1 성능 (Performance)

| ID | 요구사항 | 목표 |
|----|---------|------|
| NFR-PF-001 | API 응답 시간 (p95) | < 200ms |
| NFR-PF-002 | 세션 배치 업로드 (50개 기준) | < 2s |
| NFR-PF-003 | 통계 조회 (월별 집계) | < 500ms |
| NFR-PF-004 | 프론트엔드 초기 로딩 (FCP) | < 1.5s |
| NFR-PF-005 | 동시 접속 사용자 | 100+ (MVP), 1000+ (AWS) |

### 3.2 확장성 (Scalability)

| ID | 요구사항 | 목표 |
|----|---------|------|
| NFR-SC-001 | 10,000+ 디바이스 지원 | Phase 2 |
| NFR-SC-002 | 수평 확장 가능한 아키텍처 | AWS ECS 기반 |
| NFR-SC-003 | DB 읽기 복제본 지원 | AWS RDS Read Replica |
| NFR-SC-004 | CDN 정적 자산 배포 | CloudFront |

### 3.3 보안 (Security)

| ID | 요구사항 | Phase |
|----|---------|-------|
| NFR-SE-001 | HTTPS 전송 암호화 | 1 |
| NFR-SE-002 | JWT 기반 인증 + Redis 블랙리스트 | 1 |
| NFR-SE-003 | Row Level Security (모든 테이블) | 1 |
| NFR-SE-004 | API Rate Limiting | 1 |
| NFR-SE-005 | SQL Injection 방지 (파라미터화 쿼리) | 1 |
| NFR-SE-006 | XSS 방지 (입력 검증 + CSP 헤더) | 1 |
| NFR-SE-007 | CORS 정책 적용 | 1 |
| NFR-SE-008 | 민감 데이터 암호화 (PII) | 1 |
| NFR-SE-009 | 감사 로그 (관리자 행위) | 1 |
| NFR-SE-010 | DDoS 방지 (AWS WAF / Vercel 자체) | 1 |

### 3.4 가용성 (Availability)

| ID | 요구사항 | 목표 |
|----|---------|------|
| NFR-AV-001 | 서비스 가용성 | 99.9% |
| NFR-AV-002 | 데이터베이스 백업 | 일 1회 자동 |
| NFR-AV-003 | 장애 복구 시간 (RTO) | < 1시간 |
| NFR-AV-004 | 데이터 복구 시점 (RPO) | < 1시간 |

---

## 4. 데이터 동기화 플로우

### 4.1 세션 동기화 (Device → App → Server)

```
1. 디바이스 사용 완료
   └→ RAM 버퍼에 세션 저장 (uptime 기반 타임스탬프)

2. BLE 연결 시
   └→ 앱 → 디바이스: Time Sync (0x002B) 전송
   └→ 디바이스: 타임스탬프 보정 (real_time = uptime + offset)

3. 앱에서 세션 Pull
   └→ 0x0029 Bulk Session Request
   └→ 0x002A Session Detail Request
   └→ UUID 기반 로컬 DB 저장
   └→ 0x0028 Sync Confirm (syncStatus = 1)

4. 앱 → 서버 배치 업로드
   └→ POST /api/sessions/upload
   └→ UUID 기반 중복 제거 (ON CONFLICT DO NOTHING)
   └→ syncStatus = 2 (syncedToServer)

5. 서버 확인 응답 → 앱 업데이트
   └→ syncStatus = 3 (fullySynced)
```

### 4.2 SyncStatus

| 값 | 의미 | 설명 |
|----|------|------|
| 0 | notSynced | 디바이스에만 존재 |
| 1 | syncedToApp | 앱 로컬 DB에 저장됨 |
| 2 | syncedToServer | 서버 업로드 완료 |
| 3 | fullySynced | 서버 확인 후 최종 동기화 |

### 4.3 Shot Type (0-based, 펌웨어 일치)

| 값 | 타입 | 설명 |
|----|------|------|
| 0 (0x00) | U-Shot | 초음파 |
| 1 (0x01) | E-Shot | 전기 자극 |
| 2 (0x02) | LED Care | LED 광 치료 |

### 4.4 Device Mode (펌웨어 일치)

| 값 | 모드 | Shot Type | 약어 |
|----|------|-----------|------|
| 0x01 | Glow | U-Shot | GL |
| 0x02 | Toneup | U-Shot | TN |
| 0x03 | Renew | U-Shot | RE |
| 0x04 | Volume | U-Shot | VO |
| 0x11 | Clean | E-Shot | CL |
| 0x12 | Firm | E-Shot | FM |
| 0x13 | Line | E-Shot | LN |
| 0x14 | Lift | E-Shot | LF |
| 0x21 | LED Mode | LED | LED |

### 4.5 Termination Reason

| 값 | 이유 | 설명 |
|----|------|------|
| 0 | timeout8Min | 8분 타임아웃 (정상 완료) |
| 1 | manualPowerOff | 수동 종료 |
| 2 | batteryDrain | 배터리 방전 |
| 3 | overheat | 과열 |
| 4 | chargingStarted | 충전 시작 |
| 5 | pauseTimeout | 일시정지 타임아웃 |
| 6 | modeSwitch | 모드 변경 |
| 7 | powerOn | 전원 켜짐 이벤트 |
| 8 | overheatUltrasonic | 초음파 과열 |
| 9 | overheatBody | 본체 과열 |
| 255 | other | 기타 |

### 4.6 Device Level

| 값 | 레벨 |
|----|------|
| 1 | Level 1 (약) |
| 2 | Level 2 (중) |
| 3 | Level 3 (강) |

### 4.7 time_synced 필드

| 값 | 의미 | 설명 |
|----|------|------|
| true | 실시간 동기화 | 앱 연동 상태에서 기록 (정확한 시간) |
| false | 추정 시간 | 앱 미연동 상태에서 기록 (재할당된 시간) |

---

## 5. Phase별 구현 범위 요약

### Phase 1 — 전체 서비스 (Vercel 시작 → AWS 전환)

**사용자 관리**:
- 이메일/비밀번호 인증 + **소셜 로그인 (Google, Apple)** (FR-UM-001~002, 004)
- 2FA, 프로필, 알림 설정 (FR-UM-003, 005~006)

**디바이스 관리**:
- 디바이스 등록/조회/수정/삭제/소유권 이전 (FR-DM-001~006)
- **OTA 펌웨어 배포 및 업데이트** (FR-DM-007, 009)
- 디바이스 이상 감지 (FR-DM-008)
- **디바이스 분석 대시보드** — 마케팅/제품개발용 (FR-DM-010)

**사용 데이터**:
- 세션 업로드/조회/삭제/내보내기 (FR-UD-001~003, 006~008)
- 사용 패턴 분석, 사용 목표 (FR-UD-004~005)

**개인화 (데이터 축적)**:
- 사용 리포트, 기간 비교 (FR-PS-003~004)
- 피부 프로필 (FR-PS-006)

**관리자**:
- 사용자/디바이스/통계/공지사항/감사로그 전체 (FR-AD-001~009)
- **관리자 콘솔 + 디바이스 분석 대시보드** (FR-WF-005)
- **펌웨어 배포 관리 (OTA 롤아웃)** (FR-AD-009)

**웹 프론트엔드**:
- 랜딩, 인증, 대시보드, 통계, 관리자 콘솔 (FR-WF-001~006)

**개인정보 보호 & 보안**:
- 동의 관리 + GDPR 전체 (FR-PR-001~006)
- 타임존 (FR-TZ-001~003)
- 보안 전체 (NFR-SE-001~010)

### Phase 2 — AI 개인화 서비스

- AI 기반 사용 추천 (FR-PS-001)
- 맞춤형 콘텐츠 (FR-PS-002)
- 업적/뱃지 시스템 (FR-PS-005)
- 커뮤니티/공유 기능 (FR-PS-007)
- 콘텐츠 관리 (FR-AD-010)
