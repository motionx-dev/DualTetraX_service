# DualTetraX Services - System Architecture

**Version**: 1.0
**Date**: 2026-02-08
**Status**: Draft

---

## 1. Architecture Overview

DualTetraX Services는 **Serverless 아키텍처**를 기반으로, **Supabase + Vercel** 조합을 사용하여 1,000개 이상의 디바이스를 관리하고 개인화 서비스를 제공합니다.

### 1.1 핵심 원칙
- **Serverless First**: 자동 스케일링, 비용 최적화
- **API-Driven**: RESTful API 중심 설계
- **Security by Default**: Row Level Security (RLS), JWT 인증
- **Microservices Ready**: 향후 서비스 분리 가능한 구조

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐  │
│  │  Flutter Mobile  │  │  Next.js Web     │  │  Admin Console (Web)     │  │
│  │  - iOS/Android   │  │  - Dashboard     │  │  - Device Management     │  │
│  │  - BLE Device    │  │  - Landing Page  │  │  - User Management       │  │
│  │  - Offline Sync  │  │  - Profile       │  │  - Analytics             │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────────────┘  │
│           │                     │                     │                     │
└───────────┼─────────────────────┼─────────────────────┼─────────────────────┘
            │                     │                     │
            │                     │                     │
┌───────────▼─────────────────────▼─────────────────────▼─────────────────────┐
│                           API GATEWAY LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                     Supabase Auth (Cognito Alternative)              │  │
│  │  - Email/Password, Social Login (Google, Apple)                     │  │
│  │  - JWT Token Management (Access + Refresh)                          │  │
│  │  - Row Level Security (RLS) Integration                             │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                 Supabase Auto-Generated REST API                     │  │
│  │  - CRUD operations (auto-generated from tables)                     │  │
│  │  - Real-time subscriptions (WebSocket)                              │  │
│  │  - PostgREST based                                                  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │              Vercel Serverless Functions (Custom API)                │  │
│  │  - Complex business logic (analytics, reports)                      │  │
│  │  - OTA Firmware Management                                          │  │
│  │  - Personalization Engine (AI/ML)                                   │  │
│  │  - Scheduled Jobs (Cron)                                            │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  │
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                          APPLICATION LAYER                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │   Auth      │  │   Device    │  │   Usage     │  │   Analytics     │   │
│  │  Service    │  │   Service   │  │   Service   │  │    Service      │   │
│  │             │  │             │  │             │  │                 │   │
│  │ - Login     │  │ - Register  │  │ - Sessions  │  │ - Patterns      │   │
│  │ - Signup    │  │ - Ownership │  │ - Sync      │  │ - Reports       │   │
│  │ - Profile   │  │ - Firmware  │  │ - Stats     │  │ - AI Recommend  │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘   │
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │   Admin     │  │   OTA       │  │ Notification│  │  Personalization│   │
│  │  Service    │  │   Service   │  │   Service   │  │     Engine      │   │
│  │             │  │             │  │             │  │                 │   │
│  │ - Users     │  │ - Firmware  │  │ - Push      │  │ - Skin Profile  │   │
│  │ - Devices   │  │ - Versioning│  │ - Email     │  │ - Recommend     │   │
│  │ - Metrics   │  │ - Rollout   │  │ - In-app    │  │ - Goals         │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘   │
│                                                                             │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  │
┌─────────────────────────────────▼───────────────────────────────────────────┐
│                            DATA LAYER                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │               Supabase PostgreSQL (Primary Database)                 │  │
│  │                                                                      │  │
│  │  Tables:                                                             │  │
│  │  - auth.users (Supabase built-in)                                   │  │
│  │  - profiles (user info)                                             │  │
│  │  - devices (device registry)                                        │  │
│  │  - usage_sessions (usage data)                                      │  │
│  │  - daily_statistics (aggregated stats)                              │  │
│  │  - firmware_versions (OTA firmware management)                      │  │
│  │  - firmware_rollouts (deployment tracking)                          │  │
│  │  - device_firmware_status (per-device OTA status)                   │  │
│  │  - skin_profiles (personalization)                                  │  │
│  │  - recommendations (AI recommendations)                             │  │
│  │  - notifications (push/email queue)                                 │  │
│  │                                                                      │  │
│  │  Features:                                                           │  │
│  │  - Row Level Security (RLS) for data isolation                      │  │
│  │  - Indexes for fast queries (user_id, device_id, timestamps)        │  │
│  │  - Triggers for auto-aggregation (daily_statistics)                 │  │
│  │  - Full-text search (device serial, user email)                     │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │              Supabase Storage (S3-compatible Object Storage)         │  │
│  │                                                                      │  │
│  │  Buckets:                                                            │  │
│  │  - profile-images (user avatars)                                    │  │
│  │  - reports (PDF/CSV exports)                                        │  │
│  │  - firmware-binaries (OTA firmware files)                           │  │
│  │  - device-logs (optional, for debugging)                            │  │
│  │                                                                      │  │
│  │  Features:                                                           │  │
│  │  - Presigned URLs for secure downloads                              │  │
│  │  - CDN for global distribution                                      │  │
│  │  - Access control via RLS policies                                  │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                      Vercel KV (Redis Cache)                         │  │
│  │  - Session cache (JWT token blacklist)                              │  │
│  │  - API rate limiting counters                                       │  │
│  │  - Temporary data (OTP codes)                                       │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
            │
            │
┌───────────▼─────────────────────────────────────────────────────────────────┐
│                      MONITORING & OBSERVABILITY LAYER                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────┐    │
│  │  Vercel Logs    │  │  Supabase Logs  │  │  Sentry (Error Tracking)│    │
│  │  - API requests │  │  - DB queries   │  │  - Frontend errors      │    │
│  │  - Performance  │  │  - Auth events  │  │  - Backend errors       │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Vercel Analytics (Optional)                     │   │
│  │  - Web Vitals (LCP, FID, CLS)                                       │   │
│  │  - Traffic analysis                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Details

### 3.1 Client Layer

#### 3.1.1 Flutter Mobile App
**Purpose**: 사용자의 주요 인터페이스, BLE로 디바이스 직접 연결

**Responsibilities**:
- DualTetraX 디바이스와 BLE 연결
- 실시간 디바이스 상태 모니터링
- 사용 세션 로컬 저장 (SQLite)
- 서버와 데이터 동기화 (Supabase SDK)
- 오프라인 모드 지원
- OTA 펌웨어 업데이트 UI

**Tech Stack**:
- Flutter 3.x
- Supabase Flutter SDK
- flutter_blue_plus (BLE)
- sqflite (local database)

#### 3.1.2 Next.js Web App
**Purpose**: 사용자 대시보드 및 공개 랜딩 페이지

**Responsibilities**:
- 사용자 통계 조회 (웹에서)
- 프로필 관리
- 제품 소개 및 다운로드
- 반응형 디자인 (모바일/데스크톱)

**Tech Stack**:
- Next.js 14 (App Router)
- React 18
- Tailwind CSS
- shadcn/ui (UI components)
- Supabase JS SDK

#### 3.1.3 Admin Console (Web)
**Purpose**: 관리자 전용 대시보드

**Responsibilities**:
- 사용자/디바이스 관리
- 시스템 모니터링
- 펌웨어 업로드 및 배포
- 분석 리포트 생성

**Tech Stack**:
- Next.js 14
- React Admin (or custom)
- Charts (Recharts, Chart.js)

---

### 3.2 API Gateway Layer

#### 3.2.1 Supabase Auth
**Purpose**: 사용자 인증 및 권한 관리

**Features**:
- Email/Password 인증
- 소셜 로그인 (Google, Apple)
- JWT 토큰 발급 (Access + Refresh)
- 비밀번호 재설정
- 이메일 인증

**Security**:
- Bcrypt 비밀번호 해싱
- JWT 토큰 검증
- Rate Limiting (IP 기반)

#### 3.2.2 Supabase Auto-Generated REST API
**Purpose**: 데이터베이스 테이블에 대한 자동 CRUD API

**Features**:
- PostgREST 기반
- RESTful 엔드포인트 자동 생성
- Row Level Security (RLS) 자동 적용
- 필터링, 정렬, 페이지네이션 지원
- Real-time subscriptions (WebSocket)

**Example**:
```
GET /rest/v1/devices?user_id=eq.{userId}
POST /rest/v1/usage_sessions
GET /rest/v1/daily_statistics?user_id=eq.{userId}&stat_date=gte.2026-01-01
```

#### 3.2.3 Vercel Serverless Functions
**Purpose**: 복잡한 비즈니스 로직 처리

**Use Cases**:
- 통계 집계 (복잡한 쿼리)
- 리포트 생성 (PDF/CSV)
- AI 추천 엔진
- OTA 펌웨어 배포 로직
- Scheduled Jobs (Cron)

**Tech Stack**:
- Node.js 18+
- TypeScript
- Vercel Runtime

**API Routes**:
```
/api/analytics/generate-report
/api/ota/check-update
/api/ota/upload-firmware
/api/recommendations/get
/api/cron/daily-aggregation
```

---

### 3.3 Application Layer (Services)

#### 3.3.1 Auth Service
- 사용자 회원가입/로그인
- 프로필 관리
- 토큰 관리

#### 3.3.2 Device Service
- 디바이스 등록/삭제
- 소유권 관리
- 펌웨어 버전 추적
- 디바이스 상태 모니터링

#### 3.3.3 Usage Service
- 사용 세션 업로드
- 통계 조회 (일/주/월)
- 데이터 동기화

#### 3.3.4 Analytics Service
- 사용 패턴 분석
- 리포트 생성
- AI 기반 인사이트

#### 3.3.5 OTA Service (NEW)
- 펌웨어 버전 관리
- 펌웨어 업로드
- 롤아웃 전략 (점진적 배포)
- 디바이스별 업데이트 상태 추적
- 실패 시 롤백

#### 3.3.6 Personalization Engine
- 피부 프로필 관리
- 사용자별 추천 알고리즘
- 사용 목표 설정

#### 3.3.7 Notification Service
- 푸시 알림 (FCM/APNs)
- 이메일 알림
- In-app 알림

#### 3.3.8 Admin Service
- 사용자 관리
- 디바이스 관리
- 시스템 메트릭 조회

---

### 3.4 Data Layer

#### 3.4.1 Supabase PostgreSQL

**Schema Overview**:
```
auth.users (Supabase built-in)
  ├─ profiles (1:1)
  └─ devices (1:N)
       └─ usage_sessions (1:N)
       └─ daily_statistics (1:N)
       └─ device_firmware_status (1:1)

firmware_versions
  └─ firmware_rollouts (1:N)

skin_profiles (1:1 with users)
recommendations (N:N with users)
notifications (1:N with users)
```

**Key Features**:
- Row Level Security (RLS) for multi-tenant isolation
- Indexes on frequently queried columns
- Materialized views for complex aggregations (optional)
- Triggers for auto-updating timestamps

#### 3.4.2 Supabase Storage

**Buckets**:
1. `profile-images`: User avatars (public read, user write)
2. `reports`: Generated PDF/CSV reports (private)
3. `firmware-binaries`: OTA firmware files (authenticated)
4. `device-logs`: Device debug logs (optional, private)

**Access Control**:
- RLS policies on storage objects
- Presigned URLs for secure downloads
- CDN for global distribution

#### 3.4.3 Vercel KV (Redis)

**Use Cases**:
- JWT token blacklist (logout)
- API rate limiting counters
- Session cache
- OTP codes (temporary)

**TTL Strategy**:
- Token blacklist: 30 days (refresh token expiry)
- Rate limit: 1 minute
- OTP: 5 minutes

---

## 4. OTA Firmware Management System

### 4.1 OTA Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        OTA Workflow                         │
└─────────────────────────────────────────────────────────────┘

1. Admin uploads new firmware
   ↓
2. Firmware stored in Supabase Storage
   ↓
3. Firmware version created in DB (firmware_versions table)
   ↓
4. Create rollout plan (firmware_rollouts)
   ↓
5. Mobile app periodically checks for updates
   ↓
6. Server returns firmware metadata (version, URL, changelog)
   ↓
7. User approves update in app
   ↓
8. App downloads firmware from presigned URL
   ↓
9. App sends firmware to device via BLE
   ↓
10. Device firmware updates (ESP32 OTA)
   ↓
11. App reports update status to server
   ↓
12. Server updates device_firmware_status table
```

### 4.2 OTA Components

#### Admin Upload Interface
- Drag-and-drop firmware binary upload
- Version number, changelog input
- Target device models selection
- Rollout strategy (all at once, gradual, manual)

#### Firmware Storage
- Supabase Storage bucket: `firmware-binaries`
- File naming: `dualtetra-esp32-v{version}.bin`
- Metadata: version, size, checksum (SHA256)

#### Update Check API
```typescript
// Mobile app calls periodically
GET /api/ota/check-update?device_id={id}&current_version={version}

Response:
{
  "update_available": true,
  "version": "1.0.24",
  "download_url": "https://...",
  "size_bytes": 1400000,
  "changelog": "Bug fixes and improvements",
  "required": false
}
```

#### Update Status Reporting
```typescript
// Mobile app reports after update
POST /api/ota/report-status
{
  "device_id": "...",
  "old_version": "1.0.23",
  "new_version": "1.0.24",
  "status": "success" | "failed",
  "error_message": null
}
```

### 4.3 Rollout Strategies

1. **All at Once**: All devices eligible immediately
2. **Gradual Rollout**: 10% → 50% → 100% over days
3. **Manual Approval**: Only devices manually selected
4. **Beta Group**: Specific devices (tagged as beta testers)

### 4.4 OTA Security

- Firmware binary checksum verification (SHA256)
- HTTPS download (presigned URLs)
- ESP32 secure boot (optional)
- Rollback mechanism (if update fails)

---

## 5. Data Flow Diagrams

### 5.1 User Registration Flow

```
User (Mobile App)
  ↓
  [POST] /auth/signup (Supabase Auth)
  ↓
Supabase Auth creates user in auth.users
  ↓
Trigger: Create profile in public.profiles
  ↓
Return JWT tokens (access + refresh)
  ↓
App stores tokens in secure storage
  ↓
User authenticated
```

### 5.2 Device Registration Flow

```
User (Mobile App)
  ↓
Scans device QR code (serial number)
  ↓
[POST] /rest/v1/devices
  {
    "serial_number": "DTX-2024-001234",
    "model_name": "DualTetraX Pro",
    "firmware_version": "1.0.0"
  }
  ↓
Supabase RLS checks: user_id = auth.uid()
  ↓
Insert into devices table
  ↓
Return device_id
  ↓
App connects to device via BLE
  ↓
Device ownership confirmed
```

### 5.3 Usage Session Sync Flow

```
User uses device (BLE connected)
  ↓
App tracks session locally (SQLite)
  ↓
Session ends (device goes to standby)
  ↓
App saves session to local DB
  ↓
Background sync triggered
  ↓
[POST] /rest/v1/usage_sessions (batch insert)
  [
    { session_data_1 },
    { session_data_2 },
    ...
  ]
  ↓
Supabase inserts sessions
  ↓
Trigger: Update daily_statistics
  ↓
App marks local sessions as synced
  ↓
Sync complete
```

### 5.4 Analytics Report Generation Flow

```
User requests monthly report (Web)
  ↓
[GET] /api/analytics/generate-report?user_id={id}&month=2026-01
  ↓
Vercel Function queries usage_sessions
  ↓
Aggregates data (shot types, modes, levels)
  ↓
Generates charts (Chart.js)
  ↓
Renders PDF (jsPDF)
  ↓
Uploads PDF to Supabase Storage (reports bucket)
  ↓
Returns presigned download URL
  ↓
User downloads report
```

### 5.5 OTA Update Flow

```
App checks for updates (daily)
  ↓
[GET] /api/ota/check-update?device_id={id}&current_version=1.0.23
  ↓
Vercel Function queries firmware_versions + firmware_rollouts
  ↓
Checks if device is eligible (rollout strategy)
  ↓
Returns update metadata (version, URL, changelog)
  ↓
App shows update notification
  ↓
User approves update
  ↓
App downloads firmware from presigned URL (Supabase Storage)
  ↓
App sends firmware to device via BLE
  ↓
Device performs OTA update (ESP-IDF OTA API)
  ↓
Device reboots with new firmware
  ↓
App detects new version via BLE
  ↓
[POST] /api/ota/report-status (success)
  ↓
Server updates device_firmware_status
  ↓
Update complete
```

---

## 6. Security Architecture

### 6.1 Authentication & Authorization

**JWT Token Flow**:
```
1. User logs in → Supabase Auth returns JWT
2. App stores tokens in secure storage (Keychain/Keystore)
3. Every API request includes: Authorization: Bearer {access_token}
4. Supabase verifies JWT and checks RLS policies
5. Access token expires (1 hour) → App uses refresh token
6. Refresh token expires (30 days) → User must re-login
```

**Row Level Security (RLS)**:
```sql
-- Example: Users can only see their own devices
CREATE POLICY "users_own_devices" ON devices
  FOR SELECT USING (auth.uid() = user_id);

-- Example: Users can only insert sessions for their devices
CREATE POLICY "users_own_sessions" ON usage_sessions
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND device_id IN (SELECT id FROM devices WHERE user_id = auth.uid())
  );
```

### 6.2 API Security

**Rate Limiting**:
- Vercel Edge Functions: 100 req/min per IP
- Supabase API: 2,000 req/hour per user (free tier)

**CORS**:
- Allowed origins: `https://dualtetrax.com`, `https://*.vercel.app`
- Mobile app: No CORS (native HTTP client)

**Input Validation**:
- Zod schema validation (TypeScript)
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitize user input)

### 6.3 Data Encryption

**In Transit**:
- HTTPS (TLS 1.3)
- BLE encryption (if supported by device)

**At Rest**:
- PostgreSQL encryption at rest (Supabase default)
- S3 encryption (AES-256)

**Sensitive Data**:
- Passwords: bcrypt (Supabase Auth)
- API keys: Vercel Environment Variables
- Firmware binaries: Presigned URLs (expire in 1 hour)

---

## 7. Performance & Scalability

### 7.1 Database Optimization

**Indexes**:
```sql
-- User queries
CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_sessions_user_id_start_time ON usage_sessions(user_id, start_time DESC);

-- Admin queries
CREATE INDEX idx_devices_serial_number ON devices(serial_number);
CREATE INDEX idx_devices_firmware_version ON devices(firmware_version);

-- Analytics queries
CREATE INDEX idx_sessions_start_time ON usage_sessions(start_time DESC);
CREATE INDEX idx_statistics_user_date ON daily_statistics(user_id, stat_date DESC);
```

**Materialized Views** (for heavy analytics):
```sql
CREATE MATERIALIZED VIEW mv_weekly_stats AS
SELECT
  user_id,
  date_trunc('week', stat_date) AS week_start,
  SUM(total_sessions) AS total_sessions,
  SUM(total_working_duration) AS total_duration
FROM daily_statistics
GROUP BY user_id, week_start;

REFRESH MATERIALIZED VIEW mv_weekly_stats; -- Run daily via cron
```

### 7.2 Caching Strategy

**Vercel KV (Redis)**:
- User profile cache (TTL: 1 hour)
- Device list cache (TTL: 5 minutes)
- Rate limit counters (TTL: 1 minute)

**CDN Caching**:
- Static assets (Next.js): Edge cache
- API responses (GET): Cache-Control headers (5 minutes)

### 7.3 Scalability Plan

**Current Architecture** (1,000 devices):
- Supabase Free Tier: 500MB DB, 1GB Storage
- Vercel Hobby: 100GB bandwidth

**Growth Scenario** (10,000 devices):
- Supabase Pro: $25/month (8GB DB, 100GB Storage)
- Vercel Pro: $20/month (1TB bandwidth)
- Total: $45/month

**Large Scale** (100,000 devices):
- Supabase Team: $599/month
- Vercel Enterprise: Custom pricing
- Consider: Read replicas, connection pooling, sharding

---

## 8. Deployment Architecture

### 8.1 Infrastructure as Code

**Supabase**:
- Schema migrations: SQL migration files (version controlled)
- Deployment: Supabase CLI (`supabase db push`)

**Vercel**:
- Configuration: `vercel.json`
- Deployment: Git-based (push to `main` → auto deploy)

### 8.2 Environments

| Environment | Branch | Domain | Purpose |
|-------------|--------|--------|---------|
| Production | `main` | `dualtetrax.com` | Live users |
| Staging | `staging` | `staging.dualtetrax.com` | Pre-release testing |
| Development | `dev` | `dev.dualtetrax.com` | Internal testing |

### 8.3 CI/CD Pipeline

```
Git Push (GitHub)
  ↓
Vercel CI/CD (automatic)
  ↓
Build Next.js app
  ↓
Run tests (unit + integration)
  ↓
Deploy to Vercel Edge Network
  ↓
Deployment complete (preview URL or production)
```

**Database Migrations**:
```bash
# Manual trigger (for now)
supabase db push --db-url $SUPABASE_DB_URL
```

### 8.4 Deployment Options: Supabase+Vercel vs AWS

본 프로젝트는 두 가지 배포 옵션을 지원합니다. 각 옵션은 스타트업의 성장 단계와 예산에 맞게 선택할 수 있습니다.

#### 8.4.1 Option A: Supabase + Vercel (현재 기본 아키텍처)

**적합한 단계**: MVP, 프리시드, 시드 단계 스타트업

**Architecture Diagram**:
```
┌─────────────────────────────────────────────────────────────┐
│                     OPTION A: Supabase + Vercel             │
└─────────────────────────────────────────────────────────────┘

Client Layer
├─ Flutter Mobile App (iOS/Android)
├─ Next.js Web App
└─ Admin Console

         │ HTTPS
         ▼

API Gateway Layer (Managed Services)
├─ Supabase Auth
│  └─ Email/Password, Social Login (Google, Apple)
│  └─ JWT Token Management
│
├─ Supabase Auto-Generated REST API
│  └─ PostgREST (auto CRUD)
│  └─ Real-time WebSocket subscriptions
│
└─ Vercel Serverless Functions
   └─ Custom business logic
   └─ OTA firmware management
   └─ Analytics & Reports
   └─ Cron jobs

         │
         ▼

Data Layer (Managed Services)
├─ Supabase PostgreSQL (Primary DB)
│  └─ Tables: users, devices, sessions, firmware, etc.
│  └─ Row Level Security (RLS)
│  └─ Auto-backups (7 days on free tier)
│
├─ Supabase Storage (S3-compatible)
│  └─ Buckets: profile-images, firmware-binaries, reports
│  └─ CDN for global distribution
│
└─ Vercel KV (Redis)
   └─ Session cache, rate limiting, OTP codes
```

**특징**:
- **완전 관리형**: 인프라 관리 불필요 (Serverless)
- **자동 스케일링**: 트래픽에 따라 자동 확장
- **빠른 배포**: Git push만으로 자동 배포
- **무료 티어**: 월 $0부터 시작 가능
- **간편한 SDK**: Supabase Flutter/JS SDK 제공

**비용** (예상):
| 단계 | 사용자 수 | Supabase | Vercel | 총 비용 |
|------|----------|----------|--------|---------|
| MVP | < 1,000 | Free Tier | Free Tier | **$0/월** |
| 성장 | 1,000-10,000 | Pro ($25) | Hobby ($0) | **$25/월** |
| 확장 | 10,000-50,000 | Pro ($25) | Pro ($20) | **$45/월** |

**장점**:
- ✅ 초기 비용 $0 (무료 티어)
- ✅ 빠른 개발 속도 (자동 API 생성)
- ✅ 인프라 관리 부담 없음
- ✅ Flutter/React SDK 공식 지원
- ✅ Git 기반 자동 배포

**단점**:
- ❌ Vendor lock-in (Supabase 종속)
- ❌ 데이터베이스 크기 제한 (Free: 500MB)
- ❌ 커스텀 네트워크 구성 불가
- ❌ 대규모 확장 시 비용 증가 가능성

---

#### 8.4.2 Option B: AWS (RDS + Lambda + API Gateway)

**적합한 단계**: 시드 펀딩 이상, 커스텀 인프라 필요 시

**Architecture Diagram**:
```
┌─────────────────────────────────────────────────────────────┐
│                         OPTION B: AWS                       │
└─────────────────────────────────────────────────────────────┘

Client Layer
├─ Flutter Mobile App (iOS/Android)
├─ Next.js Web App (CloudFront + S3)
└─ Admin Console

         │ HTTPS
         ▼

API Gateway Layer
├─ Amazon Cognito
│  └─ User pools (authentication)
│  └─ Identity pools (authorization)
│
├─ API Gateway (REST API)
│  └─ Rate limiting (100 req/min)
│  └─ Request validation
│  └─ CORS configuration
│
└─ AWS Lambda Functions (Node.js 18)
   ├─ Auth service
   ├─ Device service
   ├─ Usage service
   ├─ OTA service
   └─ Analytics service

         │
         ▼

Data Layer
├─ Amazon RDS PostgreSQL
│  ├─ db.t4g.micro (dev) - $15/월
│  ├─ db.t4g.small (prod) - $30/월
│  └─ Aurora Serverless v2 (scale) - $100+/월
│  └─ Automated backups (7-30 days)
│  └─ Multi-AZ (optional)
│
├─ Amazon S3
│  ├─ Buckets: profile-images, firmware-binaries, reports
│  └─ Lifecycle policies (auto-archiving)
│
├─ Amazon ElastiCache (Redis) - Optional
│  └─ Session cache, rate limiting
│
└─ AWS Secrets Manager
   └─ DB credentials, API keys

Monitoring & Security
├─ CloudWatch (logs, metrics, alarms)
├─ CloudTrail (audit logs)
├─ WAF (Web Application Firewall) - Optional
└─ Cost Explorer (billing alerts)
```

**Infrastructure as Code**:
```typescript
// AWS CDK (TypeScript)
const dbStack = new DatabaseStack(app, 'DualTetraXDB-dev', {
  environment: 'dev',
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MICRO),
});

const apiStack = new ApiStack(app, 'DualTetraXAPI-dev', {
  environment: 'dev',
  databaseSecretArn: dbStack.secret.secretArn,
});
```

**비용** (예상):
| 서비스 | Dev | Prod | 비고 |
|--------|-----|------|------|
| RDS PostgreSQL | $15 | $30 | db.t4g.micro/small |
| Lambda | $0-5 | $10-20 | 무료 티어 (1M 요청) |
| API Gateway | $0-3 | $5-10 | 무료 티어 (1M 요청) |
| S3 + CloudFront | $1-2 | $5-10 | < 1GB 전송 |
| Cognito | $0 | $0 | < 50K MAU |
| CloudWatch | $3-5 | $10-15 | 로그 및 메트릭 |
| **합계** | **$19-30/월** | **$60-85/월** | |

**Aurora Serverless v2 옵션**:
- 비용: $50-100/월 (dev), $100-200/월 (prod)
- 자동 스케일링 (0.5 → 2 ACU)
- Multi-AZ 고가용성
- 10,000명 이상 사용자 시 권장

**장점**:
- ✅ 완전한 커스터마이징 가능
- ✅ Vendor lock-in 없음 (표준 PostgreSQL)
- ✅ 대규모 확장성 (Aurora Serverless v2)
- ✅ 세밀한 보안 제어 (VPC, Security Groups)
- ✅ 다양한 AWS 서비스 통합 가능

**단점**:
- ❌ 초기 설정 복잡 (AWS CDK 필요)
- ❌ 인프라 관리 부담
- ❌ 무료 티어 이후 최소 비용 $30/월
- ❌ 개발 속도 느림 (수동 API 구축)

---

#### 8.4.3 Deployment Strategy Recommendation

**Phase 1: MVP (0-3개월)**
```
Option A: Supabase + Vercel (무료 티어)
- 비용: $0/월
- 목표: 제품-시장 적합성 검증
- 사용자: < 1,000명
```

**Phase 2: 출시 (3-12개월)**
```
Option A: Supabase Pro + Vercel
- 비용: $25/월
- 목표: 베타 출시, 초기 사용자 확보
- 사용자: 1,000-10,000명

또는

Option B: AWS RDS db.t4g.micro (시드 펀딩 확보 시)
- 비용: $30-50/월
- 목표: 커스텀 인프라 구축
- 사용자: 5,000-10,000명
```

**Phase 3: 성장 (시리즈 A 이후)**
```
Option B: AWS Aurora Serverless v2
- 비용: $100-200/월
- 목표: 대규모 확장, 고가용성
- 사용자: 10,000-100,000명
```

**마이그레이션 경로**:
```
Supabase Free
  ↓ (500MB 한계 또는 시드 펀딩)
Supabase Pro ($25/월)
  ↓ (커스텀 인프라 필요 또는 10K+ 사용자)
AWS RDS ($30-50/월)
  ↓ (대규모 확장 또는 시리즈 A 펀딩)
AWS Aurora Serverless v2 ($100+/월)
```

**마이그레이션 방법** (Supabase → AWS):
1. `pg_dump`로 Supabase DB 내보내기
2. AWS CDK 스택 배포 (RDS + Lambda)
3. `psql`로 RDS에 데이터 가져오기
4. 환경 변수 업데이트 (SUPABASE_URL → AWS_RDS_ENDPOINT)
5. DNS를 AWS API Gateway로 전환
6. 예상 다운타임: < 1시간

---

#### 8.4.4 Comparison Matrix

| 기준 | Supabase + Vercel | AWS (RDS + Lambda) |
|------|-------------------|---------------------|
| **초기 비용** | $0/월 (무료 티어) | $30/월 (최소) |
| **설정 시간** | 1일 | 1-2주 (CDK 구성) |
| **인프라 관리** | 불필요 (완전 관리형) | 필요 (VPC, RDS, Lambda) |
| **자동 API 생성** | ✅ PostgREST | ❌ 수동 구축 필요 |
| **인증** | ✅ Built-in (간편) | Cognito (복잡) |
| **DB 크기 제한** | 500MB (Free) / 무제한 (Pro) | 무제한 |
| **확장성** | 중간 (~50K 사용자) | 높음 (100K+ 사용자) |
| **Vendor Lock-in** | High (Supabase) | Low (표준 PostgreSQL) |
| **Flutter SDK** | ✅ 공식 지원 | ⚠️ 커뮤니티 |
| **백업** | 7일 (Free) / 30일 (Pro) | 7-30일 (설정 가능) |
| **고가용성** | ✅ 자동 (Multi-region) | ⚠️ Multi-AZ 추가 비용 |
| **커스터마이징** | 낮음 | 높음 |
| **배포 속도** | Git push (즉시) | CDK deploy (~10분) |
| **학습 곡선** | 낮음 | 높음 (AWS 전문 지식 필요) |

**권장 선택 기준**:

| 상황 | 추천 옵션 |
|------|----------|
| MVP 단계, 예산 < $20/월 | **Supabase + Vercel** |
| 빠른 출시 우선 | **Supabase + Vercel** |
| 시드 펀딩 확보 | **AWS RDS** |
| 커스텀 인프라 필요 | **AWS** |
| 대규모 확장 계획 (100K+ 사용자) | **AWS Aurora** |
| Vendor lock-in 회피 | **AWS** |

---

## 9. Monitoring & Observability

### 9.1 Logging

**Vercel Logs**:
- API request logs (endpoint, status, latency)
- Error logs (stack traces)
- Custom logs (console.log in functions)

**Supabase Logs**:
- Database query logs
- Auth events (login, signup, failures)
- Storage access logs

### 9.2 Error Tracking

**Sentry**:
- Frontend errors (React)
- Backend errors (Vercel Functions)
- Mobile app errors (Flutter)

### 9.3 Metrics

**Key Metrics**:
- API response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Database query time
- Active users (DAU, WAU, MAU)
- OTA update success rate

**Alerts**:
- Error rate > 5% → Slack notification
- API latency p95 > 1s → Email
- Database CPU > 80% → PagerDuty

---

## 10. Disaster Recovery

### 10.1 Backup Strategy

**Database Backups**:
- Supabase: Automatic daily backups (retained 7 days on free tier)
- Point-in-Time Recovery (PITR): Available on Pro tier

**Storage Backups**:
- Supabase Storage: S3-based, highly durable (99.999999999%)
- Critical files: Manual backup to external S3 bucket (weekly)

### 10.2 Recovery Plan

**Database Failure**:
1. Supabase automatically fails over to replica
2. Restore from latest backup if needed
3. Estimated RTO: < 1 hour

**Storage Failure**:
1. Restore from S3 backup
2. Estimated RTO: < 30 minutes

**Total System Failure**:
1. Re-deploy Vercel app from Git
2. Restore Supabase database
3. Estimated RTO: < 2 hours

---

## 11. Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Next.js 14, React 18, Tailwind CSS | Web dashboard & landing |
| **Mobile** | Flutter 3.x, Supabase Flutter SDK | iOS/Android app |
| **API Gateway** | Supabase Auto API, Vercel Functions | RESTful API |
| **Database** | PostgreSQL (Supabase) | Primary data store |
| **Storage** | Supabase Storage (S3) | Files, firmware, images |
| **Cache** | Vercel KV (Redis) | Session, rate limiting |
| **Auth** | Supabase Auth | User authentication |
| **Deployment** | Vercel, Supabase CLI | CI/CD, hosting |
| **Monitoring** | Vercel Logs, Sentry | Logging, error tracking |

---

## 12. Decision Records

### 12.1 Why Supabase over AWS?

| Criteria | Supabase | AWS (Lambda + RDS) |
|----------|----------|---------------------|
| **Initial Cost** | $0/month | $50-100/month |
| **Setup Time** | 1 day | 1-2 weeks |
| **PostgreSQL** | Included | Aurora $50+/month |
| **Auto API** | Yes (PostgREST) | Manual (API Gateway) |
| **Auth** | Built-in | Cognito (complex) |
| **Flutter SDK** | Official | Community |

**Decision**: Supabase for MVP, migrate to AWS if needed at scale.

### 12.2 Why Vercel over AWS Lambda?

| Criteria | Vercel | AWS Lambda |
|----------|--------|------------|
| **Deployment** | Git push | SAM/CDK setup |
| **Cold Start** | < 100ms | 200-500ms (Node.js) |
| **Edge Network** | Yes (CDN) | CloudFront (separate) |
| **Cost** | $0-20/month | $10-50/month |

**Decision**: Vercel for simplicity, AWS for complex workloads later.

---

**Document End**
