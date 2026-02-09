# DualTetraX Cloud Services - 서비스 설계서

**버전**: 1.0
**작성일**: 2026-02-08
**상태**: 작성 완료

> **Phase 정의**:
> - **Phase 1**: 전체 서비스 -- Vercel에서 시작 (소셜 로그인 Google/Apple, OTA 펌웨어 관리, 관리자 기능, 디바이스 분석 대시보드 모두 포함). 사용자 증가 시 AWS로 전환
> - **Phase 2**: AI 개인화 (ML 모델, 추천 시스템)

---

## 목차

1. [서비스 개요](#1-서비스-개요)
2. [인증 서비스 (Auth Service)](#2-인증-서비스-auth-service-상세)
3. [사용자 서비스 (User Service)](#3-사용자-서비스-user-service-상세)
4. [디바이스 관리 서비스 (Device Service)](#4-디바이스-관리-서비스-device-service-상세)
5. [세션 데이터 서비스 (Session Service)](#5-세션-데이터-서비스-session-service-상세)
6. [통계 서비스 (Statistics Service)](#6-통계-서비스-statistics-service-상세)
7. [OTA 펌웨어 관리 서비스](#7-ota-펌웨어-관리-서비스-상세)
8. [관리자 서비스 (Admin Service)](#8-관리자-서비스-admin-service-상세)
9. [알림 서비스 (Notification Service)](#9-알림-서비스-notification-service-상세)
10. [데이터 동기화 서비스](#10-데이터-동기화-서비스-상세)
11. [보안 서비스](#11-보안-서비스-상세)
12. [AWS 전환 서비스 설계](#12-aws-전환-서비스-설계)
13. [에러 처리 표준](#13-에러-처리-표준)
14. [API 공통 규격](#14-api-공통-규격)

---

## 1. 서비스 개요

### 1.1 Phase 1 전체 서비스 목록

Phase 1은 Vercel + Supabase + Upstash 인프라에서 전체 서비스를 제공한다.

| # | 서비스 | 역할 | 핵심 기술 |
|---|--------|------|----------|
| 1 | **인증 서비스** (Auth) | 회원가입, 로그인, 소셜 로그인, 토큰 관리 | Supabase Auth, JWT, Redis |
| 2 | **사용자 서비스** (User) | 프로필 CRUD, 피부 프로필, 동의 관리 | Supabase DB, RLS |
| 3 | **디바이스 관리 서비스** (Device) | 등록, 조회, 수정, 소유권 이전 | Supabase DB, RLS |
| 4 | **세션 데이터 서비스** (Session) | 배치 업로드, 조회, 삭제, 내보내기 | Supabase DB, UUID dedup |
| 5 | **통계 서비스** (Statistics) | 일별 집계, 기간별 조회, 분석 대시보드 | PostgreSQL, Redis 캐시 |
| 6 | **OTA 펌웨어 서비스** (OTA) | 바이너리 업로드, 롤아웃, 체크, 이력 | Supabase Storage / S3 |
| 7 | **관리자 서비스** (Admin) | 사용자/디바이스 관리, KPI, 감사 로그 | service_role, admin_logs |
| 8 | **알림 서비스** (Notification) | 푸시, 이메일, 리마인더 | FCM, APNs, SES |
| 9 | **데이터 동기화 서비스** (Sync) | BLE->App->Server 동기화 조율 | UUID, SyncStatus |
| 10 | **보안 서비스** (Security) | 입력 검증, Rate Limiting, CORS | Zod, Redis |

### 1.2 서비스 의존성 매트릭스

```
                  Auth  User  Device  Session  Stats  OTA  Admin  Notif  Sync  Security
Auth               -     -      -       -       -     -     -      -      -      O
User               O     -      -       -       -     -     -      -      -      O
Device             O     O      -       -       -     O     -      -      -      O
Session            O     O      O       -       O     -     -      -      O      O
Stats              O     O      O       O       -     -     -      -      -      O
OTA                O     -      O       -       -     -     -      O      -      O
Admin              O     O      O       O       O     O     -      O      -      O
Notif              O     O      -       -       -     -     -      -      -      O
Sync               O     -      O       O       O     -     -      -      -      O
Security           -     -      -       -       -     -     -      -      -      -

O = 의존함, - = 의존 없음
```

### 1.3 서비스 간 호출 플로우

```
                          +-----------+
                          |  Security |
                          | (횡단관심) |
                          +-----+-----+
                                |
          +---------------------+---------------------+
          |         |         |         |         |    |
     +----v---+ +--v----+ +-v------+ +v------+ +v--v---+
     |  Auth  | | User  | | Device | |Session| | Stats |
     +----+---+ +--+----+ +---+----+ +--+----+ +--+----+
          |        |           |         |         |
          +--------+-----------+---------+---------+
                               |
                    +----------+-----------+
                    |          |           |
               +----v---+ +---v----+ +----v---+
               |  OTA   | | Admin  | | Notif  |
               +--------+ +--------+ +--------+
```

### 1.4 기술 스택 상세

| 계층 | Phase 1 (Vercel) | AWS 전환 후 |
|------|-----------------|-------------|
| API Runtime | Vercel Serverless (@vercel/node) | ECS Fargate (Express.js) |
| Database | Supabase PostgreSQL | RDS Aurora PostgreSQL |
| Auth | Supabase Auth (OAuth2) | Supabase Auth 또는 Auth0 |
| Cache | Upstash Redis (REST) | ElastiCache Redis (TCP) |
| Storage | Supabase Storage | S3 + CloudFront |
| Validation | Zod | Zod (동일) |
| Push | FCM/APNs | FCM/APNs (동일) |
| Email | Supabase Email / SES | SES |
| Monitoring | Vercel Analytics | CloudWatch + X-Ray |

---

## 2. 인증 서비스 (Auth Service) 상세

### 2.1 서비스 개요

인증 서비스는 Supabase Auth를 기반으로 사용자 인증 및 세션 관리를 담당한다.

**핵심 기능:**
- 이메일/비밀번호 회원가입 및 로그인
- 소셜 로그인 (Google, Apple Sign-In)
- JWT 발급 및 검증
- Redis 블랙리스트 기반 토큰 무효화
- 토큰 갱신 (Refresh Token)
- 로그아웃

### 2.2 소셜 로그인 (Google, Apple) -- Phase 1 포함

#### 2.2.1 Google OAuth2 플로우

```
Mobile App (Flutter)                  Supabase Auth              Google OAuth
      |                                    |                          |
      | 1. signInWithOAuth('google')       |                          |
      |----------------------------------->|                          |
      |                                    | 2. Redirect to Google    |
      |                                    |------------------------->|
      |                                    |                          |
      |                    3. 사용자 동의 (Google 로그인 화면)           |
      |<----------------------------------------------------------------|
      |                                    |                          |
      | 4. Authorization Code              |                          |
      |----------------------------------->|                          |
      |                                    | 5. Code -> Token 교환     |
      |                                    |------------------------->|
      |                                    |                          |
      |                                    | 6. Google User Info 조회  |
      |                                    |<-------------------------|
      |                                    |                          |
      |                                    | 7. profiles 생성/연결      |
      |                                    | (트리거: auth.users INSERT)|
      |                                    |                          |
      | 8. Supabase JWT + Refresh Token    |                          |
      |<-----------------------------------|                          |
      |                                    |                          |
      | 9. API 호출 (Authorization: Bearer) |                          |
      |----------------------------------->|                          |
```

#### 2.2.2 Apple Sign-In 플로우

```
Mobile App (Flutter)                  Supabase Auth              Apple Auth
      |                                    |                          |
      | 1. signInWithOAuth('apple')        |                          |
      |----------------------------------->|                          |
      |                                    | 2. Apple Authorization    |
      |<----------------------------------------------------------------|
      |                                    |                          |
      |  3. Face ID / Touch ID 인증         |                          |
      |  4. 이메일 공개/비공개 선택           |                          |
      |----------------------------------->|                          |
      |                                    | 5. Identity Token 교환    |
      |                                    |------------------------->|
      |                                    |                          |
      |                                    | 6. Apple User Info        |
      |                                    |<-------------------------|
      |                                    |                          |
      | 7. Supabase JWT 발급               |                          |
      |<-----------------------------------|                          |
```

**Apple Sign-In 특이사항:**
- Apple은 최초 로그인 시에만 이메일을 제공한다 (이후 요청에서는 미제공)
- `Hide My Email` 선택 시 프록시 이메일 (xxx@privaterelay.appleid.com) 수신
- iOS 앱 필수 요건: Apple Sign-In을 소셜 로그인 중 하나로 제공 시 반드시 포함해야 함

#### 2.2.3 Supabase Auth 설정

```typescript
// Flutter 앱에서의 소셜 로그인 호출
// Google
final response = await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'com.dualtetrax.app://login-callback',
);

// Apple
final response = await supabase.auth.signInWithOAuth(
  OAuthProvider.apple,
  redirectTo: 'com.dualtetrax.app://login-callback',
);
```

### 2.3 JWT 발급/검증 플로우

#### 2.3.1 JWT 구조

Supabase Auth가 발급하는 JWT 토큰 구조:

```json
{
  "aud": "authenticated",
  "exp": 1707400800,
  "iat": 1707397200,
  "iss": "https://jivpguvy.supabase.co/auth/v1",
  "sub": "uuid-of-user",
  "email": "user@example.com",
  "role": "authenticated",
  "session_id": "uuid-of-session",
  "app_metadata": {
    "provider": "google",
    "providers": ["google"]
  },
  "user_metadata": {
    "name": "사용자 이름",
    "avatar_url": "..."
  }
}
```

#### 2.3.2 JWT 검증 플로우 (현재 구현)

```
클라이언트 요청
    |
    v
1. Authorization 헤더에서 Bearer 토큰 추출
    |  extractToken(req)
    |  - 없음 -> 401 "Missing authorization token"
    v
2. Redis 블랙리스트 확인
    |  SHA256(token) -> hash -> Redis GET bl:<hash>
    |  - 존재 -> 401 "Token has been revoked"
    v
3. Supabase Auth 검증
    |  supabaseAdmin.auth.getUser(token)
    |  - 무효/만료 -> 401 "Invalid or expired token"
    v
4. AuthUser 객체 반환
    |  { id: string, email: string }
    v
5. API 핸들러에서 user.id 기반 비즈니스 로직 수행
```

**현재 구현 코드 (backend/lib/auth.ts):**

```typescript
export interface AuthUser {
  id: string;
  email: string;
}

export async function authenticate(
  req: VercelRequest,
  res: VercelResponse
): Promise<AuthUser | null> {
  const token = extractToken(req);
  if (!token) {
    res.status(401).json({ error: 'Missing authorization token' });
    return null;
  }

  const tokenHash = hashToken(token);
  if (await isTokenBlacklisted(tokenHash)) {
    res.status(401).json({ error: 'Token has been revoked' });
    return null;
  }

  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    res.status(401).json({ error: 'Invalid or expired token' });
    return null;
  }

  return { id: data.user.id, email: data.user.email || '' };
}
```

### 2.4 Redis 블랙리스트 상세

#### 2.4.1 키 구조

```
키:     bl:<sha256_hash_32chars>
값:     "1"
TTL:    토큰 남은 유효 시간 (exp - now)
```

#### 2.4.2 블랙리스트 등록 (로그아웃 시)

```typescript
export async function blacklistToken(tokenHash: string, expiresAt: number): Promise<void> {
  const ttl = expiresAt - Math.floor(Date.now() / 1000);
  if (ttl > 0) {
    await redis.set(`bl:${tokenHash}`, '1', { ex: ttl });
  }
}
```

**설계 의도:**
- JWT의 `exp` 클레임을 기반으로 TTL 설정 -> 만료 후 자동 삭제
- 토큰 원본 저장 금지 -> SHA256 해시만 저장 (보안)
- 해시는 32자로 자름 (충돌 확률 무시 가능)

#### 2.4.3 블랙리스트 확인 (매 요청)

```typescript
export async function isTokenBlacklisted(tokenHash: string): Promise<boolean> {
  const result = await redis.get(`bl:${tokenHash}`);
  return result !== null;
}
```

**성능 고려:**
- Upstash Redis REST API: ~5ms 응답 (글로벌 엣지)
- 매 API 요청에 Redis 조회 1회 추가
- Phase 1 규모(500 사용자)에서 부하 무시 가능

### 2.5 토큰 갱신 전략

```
1. Supabase Auth 기본 동작:
   - Access Token 유효 기간: 1시간 (3600초)
   - Refresh Token 유효 기간: 기본 무제한 (설정 가능)

2. 자동 갱신 (모바일 앱):
   - Supabase Flutter SDK의 autoRefreshToken 기능 활용
   - Access Token 만료 10분 전에 자동 갱신
   - onAuthStateChange 리스너로 새 토큰 수신

3. 갱신 실패 시:
   - 네트워크 오류 -> 재시도 (최대 3회, exponential backoff)
   - Refresh Token 무효 -> 재로그인 유도
   - 로그아웃 처리 후 로그인 화면으로 리다이렉트

4. 웹 대시보드:
   - Supabase JS SDK의 자동 갱신 사용
   - middleware.ts에서 세션 체크 및 갱신
```

### 2.6 로그아웃 전체 플로우

```
1. 클라이언트 -> POST /api/auth/logout
   |  Authorization: Bearer <token>
   v
2. 서버: authenticate(req, res)
   |  - 토큰 유효성 검증
   v
3. 서버: JWT 디코딩 (검증 없이 exp 읽기)
   |  decodeJwtPayload(token) -> { exp: 1707400800 }
   v
4. 서버: Redis 블랙리스트 등록
   |  SET bl:<hash> "1" EX <ttl>
   |  ttl = exp - now()
   v
5. 서버: 200 { message: "Logged out successfully" }
   v
6. 클라이언트: 로컬 토큰 삭제
   |  - Supabase SDK: supabase.auth.signOut()
   |  - 로컬 스토리지/Secure Storage 클리어
   v
7. 클라이언트: 로그인 화면으로 리다이렉트

전체 디바이스 로그아웃 (Phase 2):
   - 모든 활성 세션의 토큰 해시를 일괄 블랙리스트 등록
   - Supabase Admin API로 사용자의 모든 세션 무효화
```

### 2.7 API 엔드포인트

#### POST /api/auth/logout

**Request:**
```
POST /api/auth/logout
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "message": "Logged out successfully"
}
```

**에러 케이스:**

| 상태 코드 | 에러 메시지 | 원인 |
|----------|-----------|------|
| 401 | Missing authorization token | Authorization 헤더 없음 |
| 401 | Token has been revoked | 이미 로그아웃된 토큰 |
| 401 | Invalid or expired token | 만료 또는 위조된 토큰 |
| 405 | Method not allowed | POST 이외 메서드 |

---

## 3. 사용자 서비스 (User Service) 상세

### 3.1 서비스 개요

사용자 프로필 관리, 피부 프로필, 개인정보 동의, 계정 삭제 등 사용자 관련 모든 CRUD를 담당한다.

### 3.2 프로필 CRUD 상세

#### GET /api/profile

사용자 본인 프로필 조회.

**Request:**
```
GET /api/profile
Authorization: Bearer <jwt_token>
```

**Response (200):**
```typescript
interface ProfileResponse {
  id: string;          // UUID
  email: string;
  name: string | null;
  gender: 'male' | 'female' | 'other' | null;
  date_of_birth: string | null;   // YYYY-MM-DD
  timezone: string;    // 기본값 'Asia/Seoul'
  role: 'user' | 'admin';
  created_at: string;  // ISO 8601
  updated_at: string;  // ISO 8601
}
```

**비즈니스 로직:**
```
1. authenticate(req, res) -> user.id
2. supabase.from('profiles').select('*').eq('id', user.id).single()
3. RLS가 자동으로 본인 데이터만 반환
```

**DB 쿼리 패턴:**
```sql
SELECT * FROM profiles WHERE id = auth.uid();
-- RLS: profiles_select_own 정책에 의해 자동 필터
```

#### PUT /api/profile

프로필 업데이트.

**Request:**
```typescript
// PUT /api/profile
interface ProfileUpdateRequest {
  name?: string;                          // 최대 100자
  gender?: 'male' | 'female' | 'other';
  date_of_birth?: string;                 // YYYY-MM-DD
  timezone?: string;                       // IANA timezone
}
```

**Zod 스키마:**
```typescript
const ProfileUpdateSchema = z.object({
  name: z.string().max(100).optional(),
  gender: z.enum(['male', 'female', 'other']).optional(),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  timezone: z.string().max(50).optional(),
});
```

**Response (200):**
```json
{
  "profile": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "홍길동",
    "gender": "female",
    "date_of_birth": "1990-05-15",
    "timezone": "Asia/Seoul",
    "role": "user",
    "created_at": "2026-02-01T00:00:00Z",
    "updated_at": "2026-02-08T10:30:00Z"
  }
}
```

**에러 케이스:**

| 상태 코드 | 원인 |
|----------|------|
| 400 | 유효하지 않은 timezone, date_of_birth 형식 오류 |
| 401 | 인증 실패 |
| 404 | 프로필 미존재 (정상적으로는 발생하지 않음) |

### 3.3 피부 프로필 관리

#### GET /api/skin-profile

**Response (200):**
```typescript
interface SkinProfileResponse {
  id: string;
  user_id: string;
  skin_type: 'dry' | 'oily' | 'combination' | 'sensitive' | null;
  concerns: string[];     // ['wrinkles', 'pores', 'pigmentation', 'elasticity', 'dryness']
  age_range: '20s' | '30s' | '40s' | '50s' | '60+' | null;
  created_at: string;
  updated_at: string;
}
```

#### PUT /api/skin-profile

**Request:**
```typescript
interface SkinProfileUpdateRequest {
  skin_type?: 'dry' | 'oily' | 'combination' | 'sensitive';
  concerns?: string[];
  age_range?: '20s' | '30s' | '40s' | '50s' | '60+';
}
```

**Zod 스키마:**
```typescript
const SkinProfileSchema = z.object({
  skin_type: z.enum(['dry', 'oily', 'combination', 'sensitive']).optional(),
  concerns: z.array(z.string().max(50)).max(10).optional(),
  age_range: z.enum(['20s', '30s', '40s', '50s', '60+']).optional(),
});
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. UPSERT skin_profiles (user_id = user.id)
   - ON CONFLICT (user_id) DO UPDATE
3. 반환: 업데이트된 피부 프로필
```

### 3.4 개인정보 동의 관리

#### GET /api/consent

**Request:**
```
GET /api/consent
Authorization: Bearer <jwt_token>
```

**Response (200):**
```typescript
interface ConsentResponse {
  consents: ConsentRecord[];
}

interface ConsentRecord {
  id: string;
  consent_type: 'terms' | 'privacy' | 'marketing';
  consented: boolean;
  ip_address: string | null;
  user_agent: string | null;
  created_at: string;
}
```

#### POST /api/consent

**Request:**
```typescript
interface ConsentCreateRequest {
  consent_type: 'terms' | 'privacy' | 'marketing';
  consented: boolean;
}
```

**Zod 스키마:**
```typescript
const ConsentSchema = z.object({
  consent_type: z.enum(['terms', 'privacy', 'marketing']),
  consented: z.boolean(),
});
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. INSERT INTO consent_records (
     user_id, consent_type, consented,
     ip_address, user_agent
   )
   - ip_address: req.headers['x-forwarded-for']
   - user_agent: req.headers['user-agent']
3. 동의 이력은 INSERT-only (UPDATE/DELETE 금지)
4. 최신 동의 상태 = 해당 consent_type의 가장 최근 레코드
```

**DB 쿼리 패턴 -- 최신 동의 상태 조회:**
```sql
SELECT DISTINCT ON (consent_type)
  id, consent_type, consented, created_at
FROM consent_records
WHERE user_id = $1
ORDER BY consent_type, created_at DESC;
```

### 3.5 계정 삭제 (GDPR)

#### DELETE /api/profile

**비즈니스 로직 플로우:**
```
1. 사용자: DELETE /api/profile 요청
   |
   v
2. 서버: 30일 유예 기간 시작
   |  profiles.deleted_at = now()
   |  profiles.delete_scheduled_at = now() + 30 days
   v
3. (30일 이내) 사용자가 로그인 -> 삭제 취소 가능
   |  profiles.deleted_at = null
   v
4. (30일 경과) 스케줄러가 확인 -> 영구 삭제 실행
   |
   +-- a. Supabase Storage에서 프로필 사진 삭제
   +-- b. auth.users에서 사용자 삭제
   |      CASCADE로 다음 테이블 자동 삭제:
   |      - profiles
   |      - devices
   |      - usage_sessions
   |      - battery_samples
   |      - daily_statistics
   |      - consent_records
   |      - notification_settings
   |      - skin_profiles
   |      - user_goals
   +-- c. Redis에서 관련 캐시 삭제
   +-- d. admin_logs에 삭제 기록 (익명화된 형태)
```

**Request:**
```
DELETE /api/profile
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "confirm_email": "user@example.com",
  "reason": "더 이상 사용하지 않습니다"   // 선택
}
```

**Response (200):**
```json
{
  "message": "계정 삭제가 예약되었습니다. 30일 이내에 로그인하면 삭제가 취소됩니다.",
  "delete_scheduled_at": "2026-03-10T10:30:00Z"
}
```

---

## 4. 디바이스 관리 서비스 (Device Service) 상세

### 4.1 디바이스 등록 플로우

#### 4.1.1 등록 시퀀스

```
Mobile App                    Backend API                  Database
    |                              |                          |
    | POST /api/devices            |                          |
    | { serial_number,             |                          |
    |   model_name,                |                          |
    |   firmware_version,          |                          |
    |   ble_mac_address }          |                          |
    |----------------------------->|                          |
    |                              |                          |
    |                              | 1. authenticate()        |
    |                              | 2. validateBody()        |
    |                              |                          |
    |                              | INSERT INTO devices      |
    |                              | (serial_number UNIQUE)   |
    |                              |------------------------->|
    |                              |                          |
    |                              |    23505 (UNIQUE 위반)?   |
    |                              |<-------------------------|
    |                              |                          |
    |   성공: 201 { device }       |   실패: 409              |
    |<-----------------------------|                          |
```

#### 4.1.2 serial_number 중복 방지

```
시나리오 1: 동일 사용자 재등록
  -> 409 "Device already registered"
  -> 앱에서 기존 디바이스 연결로 안내

시나리오 2: 다른 사용자가 등록 시도
  -> 409 "Device already registered"
  -> 소유권 이전 플로우 안내 (Phase 1 포함)

시나리오 3: 소유권 이전 완료 후 등록
  -> 이전 소유자 devices 레코드에서 user_id 변경
  -> 새 소유자로 디바이스 연결
```

#### POST /api/devices

**Request:**
```typescript
interface DeviceRegisterRequest {
  serial_number: string;       // 필수, 1-100자
  model_name?: string;         // 기본값 'DualTetraX'
  firmware_version?: string;   // 예: '1.0.23-rc1'
  ble_mac_address?: string;    // 예: 'AA:BB:CC:DD:EE:FF'
}
```

**Zod 스키마 (현재 구현):**
```typescript
const DeviceRegisterSchema = z.object({
  serial_number: z.string().min(1).max(100),
  model_name: z.string().max(100).optional().default('DualTetraX'),
  firmware_version: z.string().max(50).optional(),
  ble_mac_address: z.string().max(20).optional(),
});
```

**Response (201):**
```json
{
  "device": {
    "id": "uuid",
    "user_id": "uuid",
    "serial_number": "DT-2026-001",
    "model_name": "DualTetraX",
    "firmware_version": "1.0.23-rc1",
    "ble_mac_address": "AA:BB:CC:DD:EE:FF",
    "is_active": true,
    "last_synced_at": null,
    "total_sessions": 0,
    "registered_at": "2026-02-08T10:00:00Z"
  }
}
```

#### GET /api/devices

**Request:**
```
GET /api/devices
Authorization: Bearer <jwt_token>
```

**Response (200):**
```json
{
  "devices": [
    {
      "id": "uuid",
      "serial_number": "DT-2026-001",
      "model_name": "DualTetraX",
      "firmware_version": "1.0.23-rc1",
      "ble_mac_address": "AA:BB:CC:DD:EE:FF",
      "is_active": true,
      "last_synced_at": "2026-02-08T10:30:00Z",
      "total_sessions": 42,
      "registered_at": "2026-01-15T09:00:00Z"
    }
  ]
}
```

**DB 쿼리 패턴:**
```sql
-- RLS가 자동으로 user_id = auth.uid() 필터 적용
SELECT * FROM devices
ORDER BY registered_at DESC;
```

### 4.2 디바이스 정보 조회/수정

#### GET /api/devices/:id

**Response (200):**
```typescript
interface DeviceDetailResponse {
  device: {
    id: string;
    serial_number: string;
    model_name: string;
    firmware_version: string | null;
    ble_mac_address: string | null;
    is_active: boolean;
    last_synced_at: string | null;
    total_sessions: number;
    registered_at: string;
  };
  recent_sessions: UsageSession[];  // 최근 10개 세션
  stats_summary: {
    total_duration: number;         // 전체 사용 시간 (초)
    avg_daily_duration: number;     // 일 평균 사용 시간 (초)
    favorite_mode: string | null;   // 가장 많이 사용한 모드
    last_battery: number | null;    // 마지막 배터리 전압 (mV)
  };
}
```

#### PUT /api/devices/:id

**Request:**
```typescript
interface DeviceUpdateRequest {
  firmware_version?: string;
  ble_mac_address?: string;
  model_name?: string;
}
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. devices 조회 (id = params.id, RLS로 본인 소유 확인)
3. 없으면 404
4. UPDATE devices SET ... WHERE id = params.id
5. 반환: 업데이트된 디바이스 정보
```

### 4.3 소유권 이전 플로우

#### 4.3.1 전체 상태 다이어그램

```
+----------+      요청       +---------+      승인      +----------+
| 소유자 A  |--------------->| pending |--------------->| 이전 완료  |
| (현 소유) |                +---------+                | (소유자 B) |
+----------+                     |                     +----------+
                                 |  거부
                                 v
                            +---------+
                            | rejected|
                            +---------+

상태 전이:
  pending   -> accepted  (수신자가 승인)
  pending   -> rejected  (수신자가 거부)
  pending   -> cancelled (발신자가 취소)

accepted 시 처리:
  1. devices.user_id = to_user_id
  2. device_transfers.status = 'accepted'
  3. device_transfers.resolved_at = now()
  4. 기존 세션 데이터는 이전 소유자에게 유지
  5. 새 소유자는 이전 후 발생한 세션만 조회 가능
```

#### POST /api/devices/:id/transfer

소유권 이전 요청.

**Request:**
```typescript
interface TransferRequest {
  to_email: string;   // 수신자 이메일
}
```

**비즈니스 로직:**
```
1. authenticate -> from_user_id
2. 디바이스 소유 확인 (devices.user_id = from_user_id)
3. 수신자 이메일로 to_user_id 조회
   - 없으면 400 "수신자를 찾을 수 없습니다"
4. 자기 자신에게 이전 방지
   - from_user_id == to_user_id -> 400
5. 이미 진행 중인 이전 요청 확인
   - device_transfers WHERE device_id AND status = 'pending'
   - 있으면 409 "이미 진행 중인 이전 요청이 있습니다"
6. INSERT INTO device_transfers
7. (선택) 수신자에게 푸시 알림 발송
```

#### PUT /api/devices/transfer/:id

이전 승인/거부.

**Request:**
```typescript
interface TransferResolveRequest {
  action: 'accept' | 'reject';
}
```

**비즈니스 로직 (accept):**
```
1. authenticate -> to_user_id (수신자)
2. device_transfers 조회 (id, status='pending', to_user_id)
3. 트랜잭션:
   a. UPDATE devices SET user_id = to_user_id WHERE id = device_id
   b. UPDATE device_transfers SET status = 'accepted', resolved_at = now()
4. (선택) 발신자에게 승인 알림
```

### 4.4 디바이스 상태 모니터링

디바이스의 실시간 상태는 BLE를 통해 앱에서 관리하며, 서버에는 last_synced_at과 세션 데이터를 통해 간접 모니터링한다.

```
모니터링 지표:
  +-- 마지막 동기화 시각 (last_synced_at)
  +-- 총 세션 수 (total_sessions)
  +-- 최근 세션의 배터리 상태 (battery_end)
  +-- 펌웨어 버전 (firmware_version)
  +-- 온도/배터리 경고 빈도 (had_temperature_warning, had_battery_warning)
  +-- 비정상 종료 빈도 (termination_reason = 2,3,8,9)
```

### 4.5 비활성화/삭제

#### DELETE /api/devices/:id

소프트 삭제 (is_active = false).

**비즈니스 로직:**
```
1. authenticate -> user.id
2. 디바이스 소유 확인
3. UPDATE devices SET is_active = false WHERE id = params.id
4. 세션 데이터는 보존 (통계 연속성)
5. 비활성 디바이스는 GET /api/devices 목록에서 필터 가능
   - ?include_inactive=true 파라미터로 포함 가능
```

**하드 삭제 (관리자만):**
```sql
-- CASCADE로 관련 데이터 자동 삭제
DELETE FROM devices WHERE id = $1;
-- -> usage_sessions CASCADE 삭제
-- -> battery_samples CASCADE 삭제
-- -> daily_statistics CASCADE 삭제
```

---

## 5. 세션 데이터 서비스 (Session Service) 상세

### 5.1 세션 업로드 API (배치) -- UUID dedup 상세

#### POST /api/sessions/upload

**Request:**
```typescript
interface SessionUploadRequest {
  device_id: string;   // UUID
  sessions: SessionItem[];  // 1-100개
}

interface SessionItem {
  id: string;                         // 앱에서 생성한 UUID (dedup 키)
  shot_type: 0 | 1 | 2;              // 0=U-Shot, 1=E-Shot, 2=LED
  device_mode: number;                // 0x01-0x21
  level: 1 | 2 | 3;
  led_pattern?: number | null;
  start_time: string;                 // ISO 8601
  end_time?: string | null;           // ISO 8601
  working_duration: number;           // 초
  pause_duration: number;             // 초
  pause_count: number;
  termination_reason?: number | null; // 0-9, 255
  completion_percent: number;         // 0-100
  had_temperature_warning: boolean;
  had_battery_warning: boolean;
  battery_start?: number | null;      // mV
  battery_end?: number | null;        // mV
  time_synced: boolean;
  battery_samples?: BatterySample[];  // 배터리 시계열 데이터
}

interface BatterySample {
  elapsed_seconds: number;  // 세션 시작부터 경과 시간
  voltage_mv: number;       // 0-5000
}
```

**Response (200):**
```json
{
  "uploaded": 5,
  "duplicates": 2,
  "errors": 0
}
```

#### 5.1.1 UUID 중복 제거 상세

```
앱 (Flutter)                             서버
    |                                      |
    | UUID v4 생성 (앱에서)                 |
    | id = "550e8400-e29b-..."             |
    |                                      |
    | POST /api/sessions/upload            |
    |------------------------------------->|
    |                                      |
    |                                      | UPSERT usage_sessions
    |                                      | ON CONFLICT (id) DO NOTHING
    |                                      | (ignoreDuplicates: true)
    |                                      |
    |                                      | 결과 확인:
    |                                      | - inserted 배열에 데이터 있음 -> uploaded++
    |                                      | - inserted 배열 비어 있음 -> duplicates++
    |                                      |
    |   200 { uploaded, duplicates }       |
    |<-------------------------------------|
```

**핵심 구현 (현재 코드):**
```typescript
const { data: inserted, error: insertError } = await supabaseAdmin
  .from('usage_sessions')
  .upsert(
    { id: sessionData.id, ...sessionData },
    { onConflict: 'id', ignoreDuplicates: true }
  )
  .select('id');

if (!inserted || inserted.length === 0) {
  duplicates++;  // 이미 존재하는 UUID
} else {
  uploaded++;    // 신규 삽입 성공
}
```

**설계 의도:**
- 앱에서 UUID를 생성하여 PK로 사용
- 네트워크 오류로 재전송 시에도 중복 삽입 방지
- `ON CONFLICT DO NOTHING`으로 기존 데이터 보존 (덮어쓰기 금지)
- 멱등성(idempotency) 보장: 동일 요청을 여러 번 보내도 결과 동일

#### 5.1.2 업로드 후 통계 집계

```
세션 업로드 성공 (uploaded > 0)
    |
    v
1. 디바이스 통계 업데이트
   |  UPDATE devices SET
   |    total_sessions = total_sessions + uploaded,
   |    last_synced_at = now()
   |  WHERE id = device_id
   v
2. 영향받은 날짜 수집
   |  affectedDates = Set<string>
   |  각 세션의 start_time.substring(0, 10) 추가
   v
3. 날짜별 통계 재집계
   |  for each date in affectedDates:
   |    supabaseAdmin.rpc('aggregate_daily_stats', {
   |      p_user_id, p_device_id, p_date
   |    })
   v
4. 통계 캐시 무효화 (Redis)
   |  DEL stats:<user_id>:<device_id>:*
```

### 5.2 배터리 샘플 처리

**저장 플로우:**
```
세션 업로드 시 battery_samples 배열이 있으면:
    |
    v
1. 세션 INSERT 성공 확인 (중복이 아닌 경우)
    |
    v
2. supabaseAdmin.from('battery_samples').insert(
     battery_samples.map(s => ({
       session_id: sessionData.id,
       elapsed_seconds: s.elapsed_seconds,
       voltage_mv: s.voltage_mv,
     }))
   )
    |
    v
3. 배터리 그래프 데이터로 활용
   - 세션 상세 화면에서 시계열 라인 차트 표시
   - 관리자 분석: 평균 배터리 소모 패턴 추출
```

**DB 쿼리 패턴 -- 세션별 배터리 그래프:**
```sql
SELECT elapsed_seconds, voltage_mv
FROM battery_samples
WHERE session_id = $1
ORDER BY elapsed_seconds ASC;
```

### 5.3 세션 조회 (필터, 페이지네이션)

#### GET /api/sessions

**Query Parameters:**
```typescript
interface SessionsQuery {
  device_id?: string;      // UUID - 디바이스 필터
  start_date?: string;     // YYYY-MM-DD
  end_date?: string;       // YYYY-MM-DD
  limit?: number;          // 1-200, 기본 50
  offset?: number;         // 0+, 기본 0
}
```

**Response (200):**
```json
{
  "sessions": [
    {
      "id": "uuid",
      "device_id": "uuid",
      "user_id": "uuid",
      "shot_type": 0,
      "device_mode": 1,
      "level": 2,
      "start_time": "2026-02-08T10:30:00Z",
      "end_time": "2026-02-08T10:38:00Z",
      "working_duration": 480,
      "pause_duration": 0,
      "pause_count": 0,
      "termination_reason": 0,
      "completion_percent": 100,
      "had_temperature_warning": false,
      "had_battery_warning": false,
      "battery_start": 4100,
      "battery_end": 3950,
      "sync_status": 2,
      "time_synced": true,
      "created_at": "2026-02-08T10:38:05Z"
    }
  ],
  "total": 42,
  "limit": 50,
  "offset": 0
}
```

**DB 쿼리 패턴:**
```sql
SELECT *, COUNT(*) OVER() AS total_count
FROM usage_sessions
WHERE user_id = auth.uid()
  AND ($1::uuid IS NULL OR device_id = $1)
  AND ($2::date IS NULL OR start_time >= $2::timestamptz)
  AND ($3::date IS NULL OR start_time <= ($3::date + 1)::timestamptz)
ORDER BY start_time DESC
LIMIT $4 OFFSET $5;
```

### 5.4 세션 삭제

#### DELETE /api/sessions/:id

**비즈니스 로직:**
```
1. authenticate -> user.id
2. usage_sessions 조회 (id = params.id, RLS로 소유 확인)
3. 없으면 404
4. 트랜잭션:
   a. 세션의 start_time에서 날짜 추출
   b. DELETE FROM usage_sessions WHERE id = params.id
      -> battery_samples CASCADE 자동 삭제
   c. 디바이스 total_sessions 감소
   d. 해당 날짜 daily_statistics 재집계
5. 통계 캐시 무효화
```

**Response (200):**
```json
{
  "message": "세션이 삭제되었습니다",
  "stats_recalculated": true
}
```

### 5.5 데이터 내보내기 (CSV)

#### GET /api/sessions/export

**Query Parameters:**
```typescript
interface ExportQuery {
  start_date: string;      // YYYY-MM-DD (필수)
  end_date: string;        // YYYY-MM-DD (필수)
  device_id?: string;
  format?: 'csv';          // 기본 csv
}
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. 날짜 범위 검증 (최대 365일)
3. 세션 조회 (전체 데이터, 페이지네이션 없음)
4. CSV 변환:
   - 헤더: Date,Time,Shot Type,Mode,Level,Duration(s),Completion(%),Battery Start(mV),Battery End(mV),Termination
   - 모드명은 사용자 친화적 이름으로 변환 (0x01 -> "Glow")
   - termination_reason도 사용자 친화적 이름으로 변환
5. Content-Type: text/csv
6. Content-Disposition: attachment; filename="dualtetrax-sessions-20260201-20260208.csv"
```

**Response:**
```
HTTP/1.1 200 OK
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="dualtetrax-sessions-20260201-20260208.csv"

Date,Time,Shot Type,Mode,Level,Duration(s),Completion(%),Battery Start(mV),Battery End(mV),Termination
2026-02-08,10:30:00,U-Shot,Glow,2,480,100,4100,3950,정상완료
2026-02-08,10:22:00,E-Shot,Firm,3,480,100,4200,4050,정상완료
```

---

## 6. 통계 서비스 (Statistics Service) 상세

### 6.1 일별 통계 집계 함수 (aggregate_daily_stats) 상세

#### 6.1.1 함수 시그니처

```sql
CREATE OR REPLACE FUNCTION aggregate_daily_stats(
  p_user_id UUID,
  p_device_id UUID,
  p_date DATE
) RETURNS void
```

#### 6.1.2 집계 로직 상세

```
입력: (user_id, device_id, date)
    |
    v
1. usage_sessions에서 해당 날짜의 세션 조회
   WHERE user_id = p_user_id
     AND device_id = p_device_id
     AND start_time::date = p_date
    |
    v
2. 집계 항목 계산:
   +-- total_sessions: COUNT(*)
   +-- total_duration: SUM(working_duration)
   +-- ushot_sessions/duration: FILTER (WHERE shot_type = 0)
   +-- eshot_sessions/duration: FILTER (WHERE shot_type = 1)
   +-- led_sessions/duration: FILTER (WHERE shot_type = 2)
   +-- mode_breakdown: { "mode_value": { sessions, duration } }
   +-- level_breakdown: { "level": count }
   +-- warning_count: COUNT(*) FILTER (WHERE had_*_warning)
    |
    v
3. UPSERT daily_statistics
   ON CONFLICT (user_id, device_id, stat_date) DO UPDATE
   -> 동일 날짜 재집계 시 기존 데이터 덮어쓰기
```

#### 6.1.3 mode_breakdown JSONB 구조

```json
{
  "1": { "sessions": 2, "duration": 960 },
  "2": { "sessions": 1, "duration": 480 },
  "17": { "sessions": 3, "duration": 1440 },
  "18": { "sessions": 1, "duration": 480 }
}
```

키는 device_mode 값(정수)의 문자열 표현:
- "1" = Glow (0x01)
- "2" = Toneup (0x02)
- "17" = Clean (0x11)
- "18" = Firm (0x12)

#### 6.1.4 집계 트리거 시점

```
1. 세션 업로드 시 (실시간):
   POST /api/sessions/upload 성공 후
   -> affectedDates에 해당하는 날짜들의 통계 재집계
   -> supabaseAdmin.rpc('aggregate_daily_stats', {...})

2. 일일 배치 (보정):
   매일 03:00 UTC (한국 12:00)
   -> 전일 모든 사용자/디바이스 조합의 통계 재집계
   -> Vercel Cron 또는 AWS EventBridge

3. 수동 트리거 (관리자):
   세션 삭제, 데이터 보정 시
   -> 영향받은 날짜의 통계 재집계
```

### 6.2 기간별 통계 조회 (일/주/월)

#### GET /api/stats/daily

특정 날짜의 통계 조회.

**Query Parameters:**
```typescript
interface DailyStatsQuery {
  date?: string;       // YYYY-MM-DD, 기본값: 오늘
  device_id?: string;  // UUID, 없으면 전체 디바이스 합산
}
```

**Response (200):**
```json
{
  "date": "2026-02-08",
  "total_sessions": 5,
  "total_duration": 2400,
  "ushot_sessions": 2,
  "ushot_duration": 960,
  "eshot_sessions": 2,
  "eshot_duration": 960,
  "led_sessions": 1,
  "led_duration": 480,
  "mode_breakdown": {
    "1": { "sessions": 1, "duration": 480 },
    "2": { "sessions": 1, "duration": 480 },
    "17": { "sessions": 1, "duration": 480 },
    "18": { "sessions": 1, "duration": 480 },
    "33": { "sessions": 1, "duration": 480 }
  },
  "level_breakdown": { "1": 1, "2": 2, "3": 2 },
  "warning_count": 0
}
```

**다중 디바이스 합산 로직 (현재 구현):**
```typescript
// device_id 필터 없이 조회 시 모든 디바이스 통계를 합산
const aggregated = data.reduce(
  (acc, row) => ({
    total_sessions: acc.total_sessions + row.total_sessions,
    total_duration: acc.total_duration + row.total_duration,
    // ... 각 필드별 합산
  }),
  { total_sessions: 0, total_duration: 0, /* ... */ }
);
```

#### GET /api/stats/range

기간별 통계 조회 (일/주/월 그룹핑).

**Query Parameters:**
```typescript
interface RangeStatsQuery {
  start_date: string;   // YYYY-MM-DD (필수)
  end_date: string;     // YYYY-MM-DD (필수)
  device_id?: string;   // UUID
  group_by?: 'day' | 'week' | 'month';  // 기본 'day'
}
```

**Response (200):**
```json
{
  "range": {
    "start": "2026-02-01",
    "end": "2026-02-08"
  },
  "data": [
    {
      "period": "2026-02-01",
      "total_sessions": 3,
      "total_duration": 1440,
      "ushot_sessions": 1,
      "eshot_sessions": 1,
      "led_sessions": 1
    },
    {
      "period": "2026-02-02",
      "total_sessions": 5,
      "total_duration": 2400,
      "ushot_sessions": 2,
      "eshot_sessions": 2,
      "led_sessions": 1
    }
  ],
  "summary": {
    "total_sessions": 25,
    "total_duration": 12000,
    "avg_sessions_per_day": 3.6
  }
}
```

**주간 그룹핑 로직 (현재 구현):**
```typescript
if (query.group_by === 'week') {
  // ISO week start (Monday)
  const d = new Date(row.stat_date + 'T00:00:00Z');
  const day = d.getUTCDay();
  const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(d);
  monday.setUTCDate(diff);
  periodKey = monday.toISOString().substring(0, 10);
} else if (query.group_by === 'month') {
  periodKey = row.stat_date.substring(0, 7); // YYYY-MM
}
```

### 6.3 통계 캐싱 전략 (Redis)

```
캐시 구조:
  키:     stats:<user_id>:<device_id|all>:<date|range>
  값:     JSON 직렬화된 통계 데이터
  TTL:    5분 (300초)

캐시 히트 플로우:
  1. Redis GET stats:<key>
  2. 있으면 -> JSON.parse -> 즉시 반환
  3. 없으면 -> DB 쿼리 -> Redis SET (TTL 5분) -> 반환

캐시 무효화:
  1. 세션 업로드 성공 시:
     DEL stats:<user_id>:*   (패턴 매칭 삭제)
  2. 세션 삭제 시:
     DEL stats:<user_id>:*
  3. 강제 새로고침:
     ?no_cache=true 쿼리 파라미터 -> 캐시 우회

Phase 1 (Upstash Redis):
  - REST API 기반 -> 패턴 삭제 불가
  - 대안: 개별 키 삭제 또는 TTL만 의존
  - 5분 TTL로 최종 일관성 허용

AWS 전환 후 (ElastiCache):
  - SCAN + DEL 패턴 매칭 가능
  - Pub/Sub로 캐시 무효화 이벤트 전파
```

### 6.4 디바이스 분석 대시보드 API (관리자용)

#### 6.4.1 평균 사용 시간 추이

**GET /api/admin/analytics/usage-trends**

```typescript
interface UsageTrendsQuery {
  period: 'daily' | 'weekly' | 'monthly';
  start_date: string;
  end_date: string;
}

interface UsageTrendsResponse {
  data: {
    period: string;
    avg_duration_seconds: number;
    total_sessions: number;
    active_users: number;
    active_devices: number;
  }[];
}
```

**DB 쿼리:**
```sql
SELECT
  stat_date AS period,
  AVG(total_duration) AS avg_duration_seconds,
  SUM(total_sessions) AS total_sessions,
  COUNT(DISTINCT user_id) AS active_users,
  COUNT(DISTINCT device_id) AS active_devices
FROM daily_statistics
WHERE stat_date BETWEEN $1 AND $2
GROUP BY stat_date
ORDER BY stat_date;
```

#### 6.4.2 기능별 사용 빈도

**GET /api/admin/analytics/feature-usage**

```typescript
interface FeatureUsageResponse {
  data: {
    device_mode: number;
    mode_name: string;       // "Glow", "Toneup", ...
    shot_type: number;
    session_count: number;
    avg_duration: number;
    total_duration: number;
    percentage: number;      // 전체 대비 비율
  }[];
}
```

**DB 쿼리:**
```sql
SELECT device_mode, shot_type,
       COUNT(*) as session_count,
       AVG(working_duration) as avg_duration,
       SUM(working_duration) as total_duration
FROM usage_sessions
WHERE start_time >= now() - INTERVAL '30 days'
GROUP BY device_mode, shot_type
ORDER BY session_count DESC;
```

#### 6.4.3 배터리 소모 분석

**GET /api/admin/analytics/battery**

```typescript
interface BatteryAnalysisResponse {
  by_mode: {
    device_mode: number;
    mode_name: string;
    avg_consumption_mv: number;  // 평균 소모량 (mV)
    sample_count: number;
  }[];
  weekly_trend: {
    week: string;
    avg_consumption_mv: number;
  }[];
}
```

**DB 쿼리:**
```sql
-- 모드별 평균 배터리 소모
SELECT device_mode,
       AVG(battery_start - battery_end) as avg_consumption_mv,
       COUNT(*) as sample_count
FROM usage_sessions
WHERE battery_start IS NOT NULL AND battery_end IS NOT NULL
  AND start_time >= now() - INTERVAL '30 days'
GROUP BY device_mode
ORDER BY avg_consumption_mv DESC;
```

#### 6.4.4 사용자 연령 분포

**GET /api/admin/analytics/demographics**

```typescript
interface DemographicsResponse {
  age_distribution: {
    age_group: string;   // "10대", "20대", ...
    user_count: number;
    percentage: number;
  }[];
  gender_distribution: {
    gender: string;
    user_count: number;
    percentage: number;
  }[];
  timezone_distribution: {
    timezone: string;
    user_count: number;
  }[];
}
```

**DB 쿼리:**
```sql
-- 연령 분포
SELECT
  CASE
    WHEN age < 20 THEN '10대'
    WHEN age < 30 THEN '20대'
    WHEN age < 40 THEN '30대'
    WHEN age < 50 THEN '40대'
    WHEN age < 60 THEN '50대'
    ELSE '60대 이상'
  END as age_group,
  COUNT(*) as user_count
FROM (
  SELECT EXTRACT(YEAR FROM AGE(now(), date_of_birth)) as age
  FROM profiles
  WHERE date_of_birth IS NOT NULL
) sub
GROUP BY age_group
ORDER BY age_group;
```

#### 6.4.5 시간대별 히트맵

**GET /api/admin/analytics/heatmap**

```typescript
interface HeatmapResponse {
  data: {
    day_of_week: number;    // 0=일, 1=월, ..., 6=토
    hour_of_day: number;    // 0-23
    session_count: number;
  }[];
}
```

**DB 쿼리:**
```sql
SELECT
  EXTRACT(DOW FROM start_time) as day_of_week,
  EXTRACT(HOUR FROM start_time) as hour_of_day,
  COUNT(*) as session_count
FROM usage_sessions
WHERE start_time >= now() - INTERVAL '30 days'
GROUP BY day_of_week, hour_of_day
ORDER BY day_of_week, hour_of_day;
```

#### 6.4.6 종료 사유 분석

**GET /api/admin/analytics/termination**

```typescript
interface TerminationResponse {
  data: {
    termination_reason: number;
    reason_name: string;
    count: number;
    percentage: number;
  }[];
}
```

**DB 쿼리:**
```sql
SELECT
  termination_reason,
  COUNT(*) as count,
  ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER() * 100, 1) as percentage
FROM usage_sessions
WHERE start_time >= now() - INTERVAL '30 days'
  AND termination_reason IS NOT NULL
GROUP BY termination_reason
ORDER BY count DESC;
```

**종료 사유 명칭 매핑:**
```typescript
const TERMINATION_NAMES: Record<number, string> = {
  0: '정상 완료 (8분)',
  1: '수동 종료',
  2: '배터리 부족',
  3: '과열',
  4: '충전 시작',
  5: '일시정지 타임아웃',
  6: '모드 변경',
  7: '전원 이벤트',
  8: '초음파 과열',
  9: '본체 과열',
  255: '기타',
};
```

#### 6.4.7 FW 버전 분포

**GET /api/admin/analytics/firmware**

```typescript
interface FirmwareDistributionResponse {
  data: {
    firmware_version: string;
    device_count: number;
    percentage: number;
  }[];
}
```

**DB 쿼리:**
```sql
SELECT firmware_version,
       COUNT(*) as device_count,
       ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER() * 100, 1) as percentage
FROM devices
WHERE is_active = true
  AND firmware_version IS NOT NULL
GROUP BY firmware_version
ORDER BY device_count DESC;
```

#### 6.4.8 분석 데이터 내보내기

**GET /api/admin/analytics/export**

```typescript
interface AnalyticsExportQuery {
  type: 'usage-trends' | 'feature-usage' | 'battery' | 'demographics' |
        'heatmap' | 'termination' | 'firmware';
  start_date: string;
  end_date: string;
  format: 'csv' | 'json';
}
```

**비즈니스 로직:**
```
1. 관리자 인증 확인 (role = 'admin')
2. 해당 type의 분석 데이터 조회
3. format에 따라 CSV 또는 JSON 변환
4. Content-Disposition: attachment 헤더로 파일 다운로드
```

---

## 7. OTA 펌웨어 관리 서비스 상세

### 7.1 펌웨어 바이너리 업로드

#### POST /api/admin/firmware

**Request (multipart/form-data):**
```typescript
interface FirmwareUploadRequest {
  file: File;              // .bin 바이너리 파일
  version: string;         // 예: "1.0.24"
  version_code: number;    // 예: 10024 (정수 비교용)
  changelog: string;       // 변경 내역
  min_version?: string;    // 최소 요구 버전 (이전 버전)
}
```

**비즈니스 로직:**
```
1. 관리자 인증 확인
    |
    v
2. 바이너리 파일 검증
   +-- 파일 크기 제한: 최대 2MB
   +-- 확장자: .bin
   +-- (선택) 헤더 매직 넘버 확인
    |
    v
3. Supabase Storage 업로드
   |  버킷: firmware-binaries
   |  경로: firmware/{version}/dualtetra-esp32-v{version}.bin
    |
    v
4. firmware_versions 테이블 INSERT
   |  version, version_code, changelog, is_active=false
    |
    v
5. 관리자 감사 로그 기록
   |  admin_logs: action='firmware_upload'
    |
    v
6. Response: 201 { firmware_version }
```

**Response (201):**
```json
{
  "firmware_version": {
    "id": "uuid",
    "version": "1.0.24",
    "version_code": 10024,
    "changelog": "배터리 소모 개선, 과열 임계값 조정",
    "is_active": false,
    "download_url": null,
    "created_at": "2026-02-08T10:00:00Z"
  }
}
```

### 7.2 펌웨어 롤아웃 관리

#### POST /api/admin/firmware/:id/rollout

**Request:**
```typescript
interface RolloutCreateRequest {
  target_percentage: number;    // 1-100
}
```

**롤아웃 단계별 배포 전략:**
```
단계 1: 내부 테스트 (5%)
    |  target_percentage = 5
    |  대상: 관리자/테스터 디바이스
    |  기간: 1-2일
    v
단계 2: 소규모 배포 (20%)
    |  target_percentage = 20
    |  대상: 랜덤 선정된 20% 디바이스
    |  기간: 3-5일
    |  모니터링: 오류 보고, 비정상 종료 빈도
    v
단계 3: 확대 배포 (50%)
    |  target_percentage = 50
    |  이상 없으면 50%로 확대
    |  기간: 3-5일
    v
단계 4: 전체 배포 (100%)
    |  target_percentage = 100
    |  firmware_versions.is_active = true
    v
(비상 시) 롤백:
    |  rollout.status = 'paused'
    |  firmware_versions.is_active = false
```

**롤아웃 대상 디바이스 결정 로직:**
```sql
-- device_id의 해시값을 0-99 범위로 매핑하여 대상 선정
-- 결정적(deterministic): 동일 디바이스는 항상 같은 결과
SELECT id FROM devices
WHERE is_active = true
  AND firmware_version != $target_version
  AND MOD(
    ('x' || SUBSTR(id::text, 1, 8))::bit(32)::int,
    100
  ) < $target_percentage;
```

### 7.3 디바이스 펌웨어 체크 API

#### GET /api/firmware/check

앱에서 주기적으로 호출하여 업데이트 가능 여부를 확인한다.

**Query Parameters:**
```typescript
interface FirmwareCheckQuery {
  device_id: string;
  current_version: string;       // "1.0.23-rc1"
  current_version_code: number;  // 10023
}
```

**Response (200) -- 업데이트 가능:**
```json
{
  "update_available": true,
  "latest_version": {
    "version": "1.0.24",
    "version_code": 10024,
    "changelog": "배터리 소모 개선, 과열 임계값 조정",
    "download_url": "https://storage.supabase.co/firmware/1.0.24/dualtetra-esp32-v1.0.24.bin",
    "file_size": 1474560
  }
}
```

**Response (200) -- 최신 버전:**
```json
{
  "update_available": false,
  "current_version": "1.0.24"
}
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. 디바이스 소유 확인
3. firmware_versions에서 최신 활성 버전 조회
   WHERE is_active = true
   ORDER BY version_code DESC
   LIMIT 1
4. version_code 비교:
   latest.version_code > current_version_code -> 업데이트 가능
5. 롤아웃 대상 확인:
   해당 디바이스가 롤아웃 target_percentage 범위 내인지 확인
6. 대상이면 download_url 제공, 아니면 update_available = false
```

### 7.4 OTA 업데이트 결과 보고

#### POST /api/firmware/report

앱에서 OTA 완료/실패 후 서버에 결과를 보고한다.

**Request:**
```typescript
interface FirmwareReportRequest {
  device_id: string;
  from_version: string;
  to_version: string;
  status: 'success' | 'failed';
  error_message?: string;
  duration_seconds?: number;   // OTA 소요 시간
}
```

**비즈니스 로직:**
```
1. authenticate -> user.id
2. 디바이스 소유 확인
3. INSERT INTO firmware_update_history
4. status == 'success' 이면:
   UPDATE devices SET firmware_version = to_version
5. status == 'failed' 이면:
   실패 로그 기록, 관리자 알림 (반복 실패 시)
```

### 7.5 펌웨어 업데이트 이력 관리

#### GET /api/devices/:id/firmware-history

**Response (200):**
```json
{
  "history": [
    {
      "id": "uuid",
      "from_version": "1.0.22",
      "to_version": "1.0.23-rc1",
      "status": "success",
      "duration_seconds": 45,
      "updated_at": "2026-01-20T14:30:00Z"
    },
    {
      "id": "uuid",
      "from_version": "1.0.23-rc1",
      "to_version": "1.0.24",
      "status": "failed",
      "error_message": "BLE 연결 끊김",
      "updated_at": "2026-02-05T10:15:00Z"
    }
  ]
}
```

---

## 8. 관리자 서비스 (Admin Service) 상세

### 8.1 관리자 인증/인가 (role 기반)

#### 8.1.1 관리자 검증 미들웨어

```typescript
async function authenticateAdmin(
  req: VercelRequest,
  res: VercelResponse
): Promise<AuthUser | null> {
  // 1. 일반 인증
  const user = await authenticate(req, res);
  if (!user) return null;

  // 2. 관리자 역할 확인
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  if (!profile || profile.role !== 'admin') {
    res.status(403).json({ error: 'Admin access required' });
    return null;
  }

  return user;
}
```

#### 8.1.2 인가 플로우

```
클라이언트 요청
    |
    v
1. JWT 토큰 검증 (일반 authenticate)
    |
    v
2. profiles.role 확인
   |  role === 'admin' -> 허용
   |  role === 'user' -> 403
    |
    v
3. API 핸들러 실행
    |
    v
4. 감사 로그 기록
   INSERT INTO admin_logs (admin_id, action, target_type, target_id, details)
```

### 8.2 사용자 관리

#### GET /api/admin/users

**Query Parameters:**
```typescript
interface AdminUsersQuery {
  search?: string;       // 이메일 또는 이름 검색
  role?: 'user' | 'admin';
  sort_by?: 'created_at' | 'name' | 'email';
  sort_order?: 'asc' | 'desc';
  limit?: number;        // 1-100, 기본 20
  offset?: number;
}
```

**Response (200):**
```json
{
  "users": [
    {
      "id": "uuid",
      "email": "user@example.com",
      "name": "홍길동",
      "gender": "female",
      "role": "user",
      "created_at": "2026-01-15T09:00:00Z",
      "device_count": 1,
      "total_sessions": 42,
      "last_active_at": "2026-02-08T10:30:00Z"
    }
  ],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

**DB 쿼리:**
```sql
SELECT
  p.id, p.email, p.name, p.gender, p.role, p.created_at,
  COUNT(DISTINCT d.id) AS device_count,
  COALESCE(SUM(d.total_sessions), 0) AS total_sessions,
  MAX(d.last_synced_at) AS last_active_at
FROM profiles p
LEFT JOIN devices d ON d.user_id = p.id AND d.is_active = true
WHERE ($1::text IS NULL OR p.email ILIKE '%' || $1 || '%' OR p.name ILIKE '%' || $1 || '%')
  AND ($2::text IS NULL OR p.role = $2)
GROUP BY p.id
ORDER BY p.created_at DESC
LIMIT $3 OFFSET $4;
```

#### GET /api/admin/users/:id

특정 사용자 상세 정보.

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "홍길동",
    "gender": "female",
    "date_of_birth": "1990-05-15",
    "timezone": "Asia/Seoul",
    "role": "user",
    "created_at": "2026-01-15T09:00:00Z",
    "updated_at": "2026-02-08T10:30:00Z"
  },
  "devices": [
    { "id": "uuid", "serial_number": "DT-2026-001", "firmware_version": "1.0.23" }
  ],
  "stats_summary": {
    "total_sessions": 42,
    "total_duration": 20160,
    "favorite_mode": "Glow",
    "active_days": 28
  },
  "consent_status": {
    "terms": true,
    "privacy": true,
    "marketing": false
  }
}
```

#### PUT /api/admin/users/:id

사용자 정보 수정 (역할 변경, 비활성화).

**Request:**
```typescript
interface AdminUserUpdateRequest {
  role?: 'user' | 'admin';
  is_active?: boolean;     // false = 계정 비활성화
  name?: string;
}
```

**비즈니스 로직:**
```
1. authenticateAdmin -> admin.id
2. 대상 사용자 조회
3. 자기 자신의 역할 변경 방지 (admin -> user)
4. UPDATE profiles
5. admin_logs 기록:
   {
     admin_id: admin.id,
     action: 'user_update',
     target_type: 'user',
     target_id: params.id,
     details: { changed_fields: ['role'], old: 'user', new: 'admin' }
   }
```

### 8.3 디바이스 관리 (전체 조회, 필터)

#### GET /api/admin/devices

**Query Parameters:**
```typescript
interface AdminDevicesQuery {
  search?: string;            // serial_number 검색
  is_active?: boolean;
  firmware_version?: string;
  sort_by?: 'registered_at' | 'last_synced_at' | 'total_sessions';
  sort_order?: 'asc' | 'desc';
  limit?: number;
  offset?: number;
}
```

**Response (200):**
```json
{
  "devices": [
    {
      "id": "uuid",
      "serial_number": "DT-2026-001",
      "model_name": "DualTetraX",
      "firmware_version": "1.0.23-rc1",
      "is_active": true,
      "total_sessions": 42,
      "last_synced_at": "2026-02-08T10:30:00Z",
      "registered_at": "2026-01-15T09:00:00Z",
      "owner": {
        "id": "uuid",
        "email": "user@example.com",
        "name": "홍길동"
      }
    }
  ],
  "total": 234,
  "limit": 20,
  "offset": 0
}
```

### 8.4 KPI 대시보드 API

#### GET /api/admin/stats

**Response (200):**
```typescript
interface AdminStatsResponse {
  overview: {
    total_users: number;
    active_users_30d: number;      // 최근 30일 활성 사용자
    new_users_7d: number;          // 최근 7일 신규 가입
    total_devices: number;
    active_devices_30d: number;
    total_sessions_today: number;
    total_sessions_7d: number;
    avg_sessions_per_user: number;
  };
  trends: {
    user_growth: { period: string; count: number }[];         // 최근 12개월
    device_registrations: { period: string; count: number }[]; // 최근 12개월
    daily_sessions: { date: string; count: number }[];         // 최근 30일
  };
}
```

**DB 쿼리:**
```sql
-- 총 사용자 수
SELECT COUNT(*) FROM profiles;

-- 최근 30일 활성 사용자
SELECT COUNT(DISTINCT user_id)
FROM usage_sessions
WHERE start_time >= now() - INTERVAL '30 days';

-- 최근 7일 신규 가입
SELECT COUNT(*)
FROM profiles
WHERE created_at >= now() - INTERVAL '7 days';

-- 월별 사용자 증가 추이
SELECT
  DATE_TRUNC('month', created_at) AS period,
  COUNT(*) AS count
FROM profiles
WHERE created_at >= now() - INTERVAL '12 months'
GROUP BY period
ORDER BY period;
```

### 8.5 공지사항 CRUD

#### POST /api/admin/announcements

**Request:**
```typescript
interface AnnouncementCreateRequest {
  title: string;        // 최대 200자
  content: string;      // 최대 5000자
  type: 'info' | 'warning' | 'update';
  is_active: boolean;
}
```

#### GET /api/announcements (사용자용)

```
SELECT * FROM announcements
WHERE is_active = true
  AND (published_at IS NULL OR published_at <= now())
ORDER BY created_at DESC
LIMIT 20;
```

#### PUT /api/admin/announcements/:id

공지사항 수정.

#### DELETE /api/admin/announcements/:id

공지사항 삭제 (소프트 삭제: is_active = false).

### 8.6 감사 로그

#### GET /api/admin/logs

**Query Parameters:**
```typescript
interface AdminLogsQuery {
  admin_id?: string;       // 특정 관리자 필터
  action?: string;         // 행위 유형 필터
  target_type?: string;    // 대상 유형 필터
  start_date?: string;
  end_date?: string;
  limit?: number;
  offset?: number;
}
```

**감사 로그 기록 항목:**

| action | target_type | 설명 |
|--------|------------|------|
| user_update | user | 사용자 정보 수정 |
| user_deactivate | user | 사용자 비활성화 |
| user_role_change | user | 역할 변경 |
| device_deactivate | device | 디바이스 비활성화 |
| device_delete | device | 디바이스 삭제 |
| firmware_upload | firmware | 펌웨어 업로드 |
| firmware_rollout | firmware | 롤아웃 생성/변경 |
| announcement_create | announcement | 공지사항 생성 |
| announcement_update | announcement | 공지사항 수정 |
| announcement_delete | announcement | 공지사항 삭제 |

**감사 로그 기록 헬퍼:**
```typescript
async function logAdminAction(
  adminId: string,
  action: string,
  targetType: string,
  targetId: string,
  details: Record<string, unknown>,
  ipAddress?: string
): Promise<void> {
  await supabaseAdmin.from('admin_logs').insert({
    admin_id: adminId,
    action,
    target_type: targetType,
    target_id: targetId,
    details,
    ip_address: ipAddress,
  });
}
```

---

## 9. 알림 서비스 (Notification Service) 상세

### 9.1 FCM/APNs 푸시 알림

#### 9.1.1 푸시 토큰 등록

```
앱 시작 시:
  1. FCM/APNs 토큰 발급 받기
  2. POST /api/notifications/token
     { token: "fcm_token_here", platform: "ios" | "android" }
  3. 서버: notification_tokens 테이블에 저장
     (user_id, token, platform, updated_at)
```

#### 9.1.2 푸시 알림 유형

| 유형 | 제목 | 내용 | 트리거 |
|------|------|------|--------|
| sync_complete | 동기화 완료 | "3건의 세션이 동기화되었습니다" | 세션 업로드 성공 |
| firmware_update | 펌웨어 업데이트 | "새 펌웨어 v1.0.24가 있습니다" | 롤아웃 활성화 |
| transfer_request | 소유권 이전 요청 | "홍길동님이 디바이스 이전을 요청했습니다" | 이전 요청 생성 |
| transfer_resolved | 소유권 이전 결과 | "디바이스 이전이 승인되었습니다" | 이전 승인/거부 |
| announcement | 공지사항 | 공지 제목 | 공지 발행 |
| usage_reminder | 사용 리마인더 | "오늘 뷰티 루틴을 시작해 보세요" | 설정된 시간 |
| weekly_report | 주간 리포트 | "이번 주 사용 요약을 확인하세요" | 매주 월요일 |

#### 9.1.3 푸시 발송 플로우

```
이벤트 발생 (세션 업로드, FW 업데이트 등)
    |
    v
1. 대상 사용자 결정
    |
    v
2. notification_settings 확인
   |  push_enabled = true 인지 확인
   |  해당 알림 유형이 활성화되어 있는지 확인
    |
    v
3. notification_tokens에서 토큰 조회
    |
    v
4. FCM/APNs API 호출
   |  FCM: firebase-admin SDK
   |  APNs: node-apn 또는 FCM 통합
    |
    v
5. 발송 결과 처리
   |  성공 -> 완료
   |  토큰 만료 -> notification_tokens에서 삭제
   |  실패 -> 재시도 (최대 3회)
```

### 9.2 이메일 알림 (SES)

#### 9.2.1 이메일 유형

| 유형 | 발신자 | 제목 |
|------|--------|------|
| welcome | noreply@dualtetrax.com | DualTetraX에 오신 것을 환영합니다 |
| password_reset | noreply@dualtetrax.com | 비밀번호 재설정 (Supabase 관리) |
| weekly_report | report@dualtetrax.com | [DualTetraX] 주간 사용 리포트 |
| account_deletion | noreply@dualtetrax.com | 계정 삭제 예정 안내 |

#### 9.2.2 Phase 1 이메일 전략

```
Phase 1 (Vercel):
  - Supabase Auth 기본 이메일 사용 (비밀번호 재설정, 이메일 확인)
  - 커스텀 이메일은 Supabase Edge Functions 또는 별도 트리거

AWS 전환 후:
  - SES를 통한 커스텀 이메일 템플릿
  - SES Template API로 HTML 이메일 발송
  - 바운스/컴플레인 처리 (SNS 연동)
```

### 9.3 알림 설정 관리

#### GET /api/notifications

**Response (200):**
```json
{
  "settings": {
    "push_enabled": true,
    "email_enabled": true,
    "usage_reminder": true,
    "reminder_time": "21:00",
    "weekly_report": true,
    "marketing": false
  }
}
```

#### PUT /api/notifications

**Request:**
```typescript
interface NotificationSettingsUpdate {
  push_enabled?: boolean;
  email_enabled?: boolean;
  usage_reminder?: boolean;
  reminder_time?: string;      // HH:MM
  weekly_report?: boolean;
  marketing?: boolean;
}
```

### 9.4 사용 리마인더

```
리마인더 스케줄러:
  1. 매 시간 실행 (Vercel Cron 또는 AWS EventBridge)
  2. notification_settings에서 해당 시간의 리마인더 대상 조회:
     SELECT ns.user_id, p.timezone
     FROM notification_settings ns
     JOIN profiles p ON p.id = ns.user_id
     WHERE ns.usage_reminder = true
       AND ns.reminder_time = EXTRACT(HOUR FROM now() AT TIME ZONE p.timezone)::text || ':00'
  3. 오늘 세션이 없는 사용자에게만 푸시 발송
  4. 푸시 내용: "오늘 뷰티 루틴을 시작해 보세요"
```

---

## 10. 데이터 동기화 서비스 상세

### 10.1 BLE -> App -> Server 동기화 플로우

```
+----------+     BLE      +----------+     HTTPS     +----------+     DB
| Device   |              | Mobile   |               | Backend  |
| (ESP32)  |              | App      |               | API      |
+----+-----+              +----+-----+               +----+-----+
     |                         |                          |
     | 1. 세션 완료              |                          |
     |  (RAM 버퍼에 저장)         |                          |
     |                         |                          |
     | <-- 2. BLE 연결 -->      |                          |
     |                         |                          |
     | 3. Time Sync (0x002B)   |                          |
     |<------------------------|                          |
     | 4. 타임스탬프 보정         |                          |
     |                         |                          |
     | 5. Bulk Session Req     |                          |
     |  (0x0029)               |                          |
     |<------------------------|                          |
     |                         |                          |
     | 6. Session List         |                          |
     |------------------------>|                          |
     |                         |                          |
     | 7. Session Detail Req   |                          |
     |  (0x002A) x N           |                          |
     |<------------------------|                          |
     |                         |                          |
     | 8. Session Data         |                          |
     |------------------------>|                          |
     |                         | 9. 로컬 DB 저장           |
     |                         |   (UUID 생성, SQLite)     |
     |                         |   syncStatus = 1         |
     |                         |                          |
     | 10. Sync Confirm        |                          |
     |  (0x0028)               |                          |
     |<------------------------|                          |
     |                         |                          |
     |                         | 11. POST /api/sessions/  |
     |                         |     upload               |
     |                         |------------------------->|
     |                         |                          |
     |                         |                          | 12. UPSERT
     |                         |                          |   (ON CONFLICT
     |                         |                          |    DO NOTHING)
     |                         |                          |
     |                         |                          | 13. aggregate
     |                         |                          |   _daily_stats
     |                         |                          |
     |                         | 14. 200 { uploaded,      |
     |                         |     duplicates }         |
     |                         |<-------------------------|
     |                         |                          |
     |                         | 15. syncStatus = 2       |
     |                         |   (syncedToServer)       |
     |                         |                          |
     |                         | 16. 서버 확인 ->          |
     |                         |   syncStatus = 3         |
     |                         |   (fullySynced)          |
```

### 10.2 SyncStatus 상태 머신 (0->1->2->3)

```
+---------------+     BLE 수신      +---------------+
|  0: notSynced |  ----------------> | 1: syncedToApp|
| (디바이스에만   |                    | (앱 로컬 DB에  |
|  존재)         |                    |  저장됨)       |
+---------------+                    +-------+-------+
                                             |
                                    서버 업로드 성공
                                             |
                                     +-------v---------+
                                     | 2: syncedToServer|
                                     | (서버 업로드 완료) |
                                     +-------+---------+
                                             |
                                    서버 확인 응답
                                             |
                                     +-------v--------+
                                     | 3: fullySynced  |
                                     | (최종 동기화)    |
                                     +----------------+

상태 전이 규칙:
  0 -> 1: BLE로 세션 데이터 수신 + 앱 로컬 DB 저장
  1 -> 2: POST /api/sessions/upload 성공 (uploaded > 0)
  2 -> 3: 서버 응답 확인 후 앱에서 업데이트

역전이 없음: 상태는 항상 순방향으로만 진행
```

### 10.3 중복 제거 (UUID + ON CONFLICT)

```
중복 제거 전략:
  +-- 앱에서 UUID v4 생성 (세션 PK)
  +-- UUID는 전 세계적으로 고유 (충돌 확률 무시 가능)
  +-- 서버: ON CONFLICT (id) DO NOTHING
  |
  +-- 시나리오 1: 정상 업로드
  |   앱 -> 서버: UUID-A, UUID-B, UUID-C
  |   결과: uploaded=3, duplicates=0
  |
  +-- 시나리오 2: 네트워크 오류로 재전송
  |   1차: UUID-A, UUID-B (성공, uploaded=2)
  |   2차: UUID-A, UUID-B, UUID-C (재전송)
  |   결과: uploaded=1 (UUID-C만), duplicates=2 (UUID-A,B 이미 존재)
  |
  +-- 시나리오 3: 앱 재설치 후 동기화
  |   디바이스에서 다시 세션 Pull -> 새 UUID 생성
  |   -> 이전 세션과 UUID가 다르므로 새로 업로드됨
  |   -> 문제: 동일 세션이 다른 UUID로 중복 가능
  |   -> 해결: 앱에서 (device_id, start_time, device_mode) 조합으로
  |            서버에 기존 세션 존재 여부 확인 후 업로드
```

### 10.4 Time Sync 미적용 세션 처리 (time_synced=false)

```
time_synced 필드의 의미:
  true:  앱 연동 상태에서 기록됨 (정확한 실시간 타임스탬프)
  false: 앱 미연동 상태에서 기록됨 (추정 시간)

time_synced=false 발생 시나리오:
  1. 사용자가 앱 없이 디바이스만 사용
  2. BLE 연결 없이 디바이스 전원 ON -> 사용 -> OFF
  3. 나중에 앱 연결 시 세션 Pull
     -> 디바이스의 uptime 기반 타임스탬프 (부팅 시점부터의 상대 시간)
     -> 앱에서 "현재 시간 - 경과 시간" 으로 추정 시간 재할당
     -> time_synced = false로 표기

통계 처리 시 주의:
  - time_synced=false 세션은 시간 정확도가 낮음
  - 통계 화면에서 "(추정)" 표시 가능
  - 히트맵, 시간대별 분석에서 가중치 낮출 수 있음 (Phase 2)
```

### 10.5 오프라인 -> 온라인 재동기화

```
오프라인 시나리오:
  1. 앱이 세션 데이터를 로컬 DB에 보유 (syncStatus = 1)
  2. 네트워크 없음 -> 서버 업로드 불가
  3. 앱은 미동기화 세션 수를 사용자에게 표시
     "미동기화 세션: 5건"

온라인 복귀 시:
  1. 앱이 네트워크 상태 감지 (connectivity_plus 패키지)
  2. syncStatus = 1인 세션 목록 조회
  3. 배치 업로드 (POST /api/sessions/upload)
     - 한 번에 최대 100개씩
     - 여러 배치로 분할 가능
  4. 성공 -> syncStatus = 2 -> 3
  5. 부분 실패 -> 실패 세션만 재시도

재동기화 정책:
  - 앱 실행 시 자동 확인
  - 홈 화면에 동기화 배너 표시
  - 수동 동기화 버튼 제공 (디바이스 탭)
  - 백그라운드 동기화 (iOS: BackgroundTasks, Android: WorkManager)
```

---

## 11. 보안 서비스 상세

### 11.1 입력 검증 (Zod 스키마)

#### 11.1.1 검증 아키텍처

```
클라이언트 요청
    |
    v
1. Content-Type 확인 (application/json)
    |
    v
2. Zod 스키마 검증
   |  validateBody(req, res, schema)
   |  validateQuery(req, res, schema)
   |  - 성공 -> 파싱된 타입 안전 데이터 반환
   |  - 실패 -> 400 { error, details }
    |
    v
3. 비즈니스 로직에서 추가 검증
   (DB 관계 확인, 권한 확인 등)
```

#### 11.1.2 현재 구현된 Zod 스키마

```typescript
// 디바이스 등록
const DeviceRegisterSchema = z.object({
  serial_number: z.string().min(1).max(100),
  model_name: z.string().max(100).optional().default('DualTetraX'),
  firmware_version: z.string().max(50).optional(),
  ble_mac_address: z.string().max(20).optional(),
});

// 세션 업로드
const SessionUploadSchema = z.object({
  device_id: z.string().uuid(),
  sessions: z.array(SessionItemSchema).min(1).max(100),
});

const SessionItemSchema = z.object({
  id: z.string().uuid(),
  shot_type: z.number().int().min(0).max(2),
  device_mode: z.number().int(),
  level: z.number().int().min(1).max(3),
  led_pattern: z.number().int().optional().nullable(),
  start_time: z.string().datetime(),
  end_time: z.string().datetime().optional().nullable(),
  working_duration: z.number().int().min(0).default(0),
  pause_duration: z.number().int().min(0).default(0),
  pause_count: z.number().int().min(0).default(0),
  termination_reason: z.number().int().optional().nullable(),
  completion_percent: z.number().int().min(0).max(100).default(0),
  had_temperature_warning: z.boolean().default(false),
  had_battery_warning: z.boolean().default(false),
  battery_start: z.number().int().optional().nullable(),
  battery_end: z.number().int().optional().nullable(),
  time_synced: z.boolean().default(true),
  battery_samples: z.array(BatterySampleSchema).optional().default([]),
});

// 세션 조회
const SessionsQuerySchema = z.object({
  device_id: z.string().uuid().optional(),
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional().default(50),
  offset: z.coerce.number().int().min(0).optional().default(0),
});

// 통계 조회
const DailyStatsQuerySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  device_id: z.string().uuid().optional(),
});

const RangeStatsQuerySchema = z.object({
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  device_id: z.string().uuid().optional(),
  group_by: z.enum(['day', 'week', 'month']).optional().default('day'),
});
```

#### 11.1.3 검증 실패 응답 형식

```json
{
  "error": "Validation failed",
  "details": {
    "serial_number": ["Required"],
    "sessions": ["Array must contain at least 1 element(s)"]
  }
}
```

#### 11.1.4 추가 검증 스키마 (Phase 1 확장)

```typescript
// 프로필 업데이트
const ProfileUpdateSchema = z.object({
  name: z.string().max(100).optional(),
  gender: z.enum(['male', 'female', 'other']).optional(),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  timezone: z.string().max(50).refine(
    (tz) => Intl.supportedValuesOf('timeZone').includes(tz),
    'Invalid timezone'
  ).optional(),
});

// 동의 기록
const ConsentSchema = z.object({
  consent_type: z.enum(['terms', 'privacy', 'marketing']),
  consented: z.boolean(),
});

// 관리자 사용자 검색
const AdminUsersQuerySchema = z.object({
  search: z.string().max(100).optional(),
  role: z.enum(['user', 'admin']).optional(),
  sort_by: z.enum(['created_at', 'name', 'email']).optional().default('created_at'),
  sort_order: z.enum(['asc', 'desc']).optional().default('desc'),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
  offset: z.coerce.number().int().min(0).optional().default(0),
});

// 펌웨어 업로드
const FirmwareUploadSchema = z.object({
  version: z.string().regex(/^\d+\.\d+\.\d+(-\w+)?$/),
  version_code: z.number().int().min(1),
  changelog: z.string().max(5000),
  min_version: z.string().optional(),
});

// 소유권 이전
const TransferRequestSchema = z.object({
  to_email: z.string().email(),
});

// 알림 설정
const NotificationSettingsSchema = z.object({
  push_enabled: z.boolean().optional(),
  email_enabled: z.boolean().optional(),
  usage_reminder: z.boolean().optional(),
  reminder_time: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  weekly_report: z.boolean().optional(),
  marketing: z.boolean().optional(),
});
```

### 11.2 Rate Limiting 구현

#### 11.2.1 Phase 1 (Vercel + Upstash Redis)

```typescript
// Upstash Redis 기반 슬라이딩 윈도우 Rate Limiter
import { Ratelimit } from '@upstash/ratelimit';
import { redis } from './redis';

// 일반 API: 100 req / 60s / IP
const generalLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(100, '60 s'),
  prefix: 'rl:general',
});

// 인증 API: 10 req / 60s / IP (브루트포스 방지)
const authLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '60 s'),
  prefix: 'rl:auth',
});

// 업로드 API: 20 req / 60s / User
const uploadLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(20, '60 s'),
  prefix: 'rl:upload',
});

// Rate Limit 미들웨어
async function rateLimit(
  req: VercelRequest,
  res: VercelResponse,
  limiter: Ratelimit,
  identifier: string
): Promise<boolean> {
  const { success, limit, remaining, reset } = await limiter.limit(identifier);

  res.setHeader('X-RateLimit-Limit', limit.toString());
  res.setHeader('X-RateLimit-Remaining', remaining.toString());
  res.setHeader('X-RateLimit-Reset', reset.toString());

  if (!success) {
    res.status(429).json({
      error: 'Too many requests',
      retry_after: Math.ceil((reset - Date.now()) / 1000),
    });
    return false;
  }
  return true;
}
```

#### 11.2.2 엔드포인트별 Rate Limit 정책

| 엔드포인트 | 제한 | 식별자 | 근거 |
|-----------|------|--------|------|
| POST /api/auth/logout | 10/분 | IP | 인증 API 보호 |
| POST /api/devices | 5/분 | User | 디바이스 과다 등록 방지 |
| POST /api/sessions/upload | 20/분 | User | 배치 업로드 보호 |
| GET /api/sessions | 60/분 | User | 일반 조회 |
| GET /api/stats/* | 60/분 | User | 통계 조회 |
| GET /api/admin/* | 100/분 | User | 관리자 API |
| POST /api/admin/* | 30/분 | User | 관리자 쓰기 |

### 11.3 CORS 설정

```typescript
// vercel.json CORS 헤더 설정
{
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "https://qp-dualtetrax-web.vercel.app" },
        { "key": "Access-Control-Allow-Methods", "value": "GET,POST,PUT,DELETE,OPTIONS" },
        { "key": "Access-Control-Allow-Headers", "value": "Authorization,Content-Type" },
        { "key": "Access-Control-Max-Age", "value": "86400" }
      ]
    }
  ]
}

// 허용 도메인 목록
const ALLOWED_ORIGINS = [
  'https://qp-dualtetrax-web.vercel.app',  // 프로덕션 웹
  'http://localhost:3000',                   // 로컬 개발
  // 모바일 앱은 Origin 헤더가 없으므로 별도 처리 불필요
];
```

### 11.4 환경 변수 관리

```
Phase 1 (Vercel):
  +-- Vercel Dashboard -> Settings -> Environment Variables
  +-- .env.local (로컬 개발용, .gitignore에 포함)
  +-- 주의: Vercel 환경 변수에 줄바꿈 이슈 -> .trim() 적용

  Backend (Vercel):
    SUPABASE_URL              # Supabase 프로젝트 URL
    SUPABASE_ANON_KEY         # 프론트엔드용 키 (RLS 적용)
    SUPABASE_SERVICE_ROLE_KEY # 백엔드 어드민 키 (RLS 우회)
    UPSTASH_REDIS_REST_URL    # Redis REST API URL
    UPSTASH_REDIS_REST_TOKEN  # Redis 인증 토큰
    NODE_ENV                  # production

  Frontend (Vercel):
    NEXT_PUBLIC_SUPABASE_URL
    NEXT_PUBLIC_SUPABASE_ANON_KEY
    NEXT_PUBLIC_API_URL

AWS 전환 후:
  +-- AWS Secrets Manager (DB 비밀번호, API 키)
  +-- ECS Task Definition 환경 변수
  +-- Parameter Store (비민감 설정)
```

### 11.5 API 키 관리

```
현재 사용 중인 키:
  1. SUPABASE_ANON_KEY
     - 역할: 클라이언트용 (RLS 적용)
     - 노출: 프론트엔드에서 사용 가능 (NEXT_PUBLIC_ 접두사)
     - 보안: RLS가 데이터 격리 보장

  2. SUPABASE_SERVICE_ROLE_KEY
     - 역할: 백엔드 어드민 (RLS 우회)
     - 노출: 절대 클라이언트에 노출 금지
     - 사용: 통계 집계, 관리자 API, 배치 작업

  3. UPSTASH_REDIS_REST_TOKEN
     - 역할: Redis 인증
     - 노출: 백엔드에서만 사용

키 로테이션 정책:
  - 90일마다 키 로테이션 권장
  - Supabase: Dashboard -> Settings -> API -> Regenerate
  - Upstash: Dashboard -> Database -> Credentials -> Reset
  - 로테이션 시 무중단 적용: 이전 키 + 새 키 동시 지원 기간 설정
```

---

## 12. AWS 전환 서비스 설계

### 12.1 Vercel -> AWS 전환 체크리스트

```
사전 준비:
  [ ] AWS 계정 생성 및 IAM 설정
  [ ] VPC, 서브넷, 보안 그룹 설계
  [ ] Route 53 도메인 등록

인프라 구축:
  [ ] RDS Aurora PostgreSQL 클러스터 생성
  [ ] ElastiCache Redis 클러스터 생성
  [ ] S3 버킷 생성 (펌웨어 바이너리, 프로필 사진)
  [ ] CloudFront CDN 설정
  [ ] ECR 레지스트리 생성

데이터 마이그레이션:
  [ ] Supabase PostgreSQL -> RDS 데이터 이전
  [ ] Supabase Storage -> S3 파일 이전
  [ ] Upstash Redis -> ElastiCache 데이터 이전 (필요 시)

코드 수정:
  [ ] DB 추상화 레이어 구현
  [ ] Redis 추상화 레이어 구현
  [ ] Auth 추상화 레이어 구현
  [ ] Storage 추상화 레이어 구현
  [ ] Dockerfile 작성
  [ ] Express.js 래퍼 구현

배포:
  [ ] ECS Fargate Task Definition 작성
  [ ] ALB + Target Group 설정
  [ ] ECS Service 생성 (API, Web, Worker)
  [ ] EventBridge 스케줄 설정
  [ ] CI/CD 파이프라인 구축 (CodePipeline 또는 GitHub Actions)

전환:
  [ ] DNS 전환 (Route 53)
  [ ] 모니터링 설정 (CloudWatch)
  [ ] 성능 테스트
  [ ] Vercel 프로젝트 비활성화
```

### 12.2 코드 추상화 레이어 설계

#### 12.2.1 DB 추상화

```typescript
// lib/db/interface.ts
interface DatabaseClient {
  query<T>(table: string): QueryBuilder<T>;
  rpc(fn: string, params: Record<string, unknown>): Promise<void>;
}

interface QueryBuilder<T> {
  select(columns?: string): QueryBuilder<T>;
  insert(data: Partial<T>): QueryBuilder<T>;
  update(data: Partial<T>): QueryBuilder<T>;
  delete(): QueryBuilder<T>;
  eq(column: string, value: unknown): QueryBuilder<T>;
  gte(column: string, value: unknown): QueryBuilder<T>;
  lte(column: string, value: unknown): QueryBuilder<T>;
  order(column: string, options?: { ascending: boolean }): QueryBuilder<T>;
  limit(count: number): QueryBuilder<T>;
  single(): QueryBuilder<T>;
  execute(): Promise<{ data: T[] | T | null; error: Error | null; count?: number }>;
}

// lib/db/supabase.ts (Phase 1)
class SupabaseDatabase implements DatabaseClient {
  constructor(private client: SupabaseClient) {}
  query<T>(table: string): QueryBuilder<T> {
    return new SupabaseQueryBuilder(this.client.from(table));
  }
}

// lib/db/pg.ts (AWS 전환 후)
class PgDatabase implements DatabaseClient {
  constructor(private pool: Pool) {}
  query<T>(table: string): QueryBuilder<T> {
    return new PgQueryBuilder(this.pool, table);
  }
}
```

#### 12.2.2 Redis 추상화

```typescript
// lib/cache/interface.ts
interface CacheClient {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, options?: { ex?: number }): Promise<void>;
  del(key: string): Promise<void>;
}

// lib/cache/upstash.ts (Phase 1)
class UpstashCache implements CacheClient {
  constructor(private redis: Redis) {}
  async get(key: string) { return await this.redis.get(key); }
  async set(key: string, value: string, opts?: { ex?: number }) {
    await this.redis.set(key, value, opts);
  }
  async del(key: string) { await this.redis.del(key); }
}

// lib/cache/ioredis.ts (AWS 전환 후)
class IoRedisCache implements CacheClient {
  constructor(private redis: IORedis) {}
  async get(key: string) { return await this.redis.get(key); }
  async set(key: string, value: string, opts?: { ex?: number }) {
    if (opts?.ex) await this.redis.setex(key, opts.ex, value);
    else await this.redis.set(key, value);
  }
  async del(key: string) { await this.redis.del(key); }
}
```

#### 12.2.3 Auth 추상화

```typescript
// lib/auth/interface.ts
interface AuthProvider {
  verifyToken(token: string): Promise<AuthUser | null>;
  signOut(token: string): Promise<void>;
}

// lib/auth/supabase-auth.ts (Phase 1)
class SupabaseAuthProvider implements AuthProvider {
  async verifyToken(token: string) {
    const { data, error } = await supabaseAdmin.auth.getUser(token);
    if (error || !data.user) return null;
    return { id: data.user.id, email: data.user.email || '' };
  }
}

// lib/auth/custom-jwt.ts (AWS 전환 후)
class CustomJwtAuthProvider implements AuthProvider {
  async verifyToken(token: string) {
    const payload = jwt.verify(token, JWT_SECRET);
    return { id: payload.sub, email: payload.email };
  }
}
```

#### 12.2.4 Storage 추상화

```typescript
// lib/storage/interface.ts
interface StorageProvider {
  upload(bucket: string, path: string, file: Buffer): Promise<string>;
  getUrl(bucket: string, path: string): Promise<string>;
  delete(bucket: string, path: string): Promise<void>;
}

// lib/storage/supabase-storage.ts (Phase 1)
// lib/storage/s3.ts (AWS 전환 후)
```

### 12.3 ECS Fargate Task Definition 예시

```json
{
  "family": "dualtetrax-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::role/dualtetrax-api-task-role",
  "containerDefinitions": [
    {
      "name": "api",
      "image": "123456789.dkr.ecr.ap-northeast-2.amazonaws.com/dualtetrax-api:latest",
      "portMappings": [
        { "containerPort": 3000, "protocol": "tcp" }
      ],
      "environment": [
        { "name": "NODE_ENV", "value": "production" },
        { "name": "PORT", "value": "3000" }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:123456789:secret:dualtetrax/db-url"
        },
        {
          "name": "REDIS_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:123456789:secret:dualtetrax/redis-url"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:123456789:secret:dualtetrax/jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/dualtetrax-api",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "api"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      }
    }
  ]
}
```

### 12.4 RDS Aurora 마이그레이션 계획

```
1. 스키마 마이그레이션:
   - Supabase에서 스키마 덤프: pg_dump --schema-only
   - auth.users 테이블은 커스텀 users 테이블로 변환
   - RLS 정책 제거 (애플리케이션 레벨 권한 검사로 대체)
   - 트리거 함수 이전 (create_profile_for_new_user 등)

2. 데이터 마이그레이션:
   - pg_dump --data-only (Supabase)
   - pg_restore (RDS Aurora)
   - 마이그레이션 스크립트로 데이터 정합성 검증

3. auth.users 마이그레이션:
   a. Supabase Auth 유지 방안:
      - Supabase Auth만 계속 사용 (DB는 RDS로 이전)
      - API에서 Supabase Auth SDK로 토큰 검증
   b. 자체 인증 구축 방안:
      - auth.users -> custom users 테이블 이전
      - bcrypt 비밀번호 해시 이전
      - JWT 발급/검증 자체 구현
      - OAuth2 Provider (Google, Apple) 직접 연동
   권장: (a) Supabase Auth 유지 + DB만 RDS로 이전

4. 데이터 동기화 기간:
   - 전환 전 양방향 동기화 설정 (1-2주)
   - Supabase -> RDS 실시간 복제
   - DNS 전환 후 Supabase 쓰기 중단
```

### 12.5 무중단 전환 전략

```
Phase A: 병행 운영 (1-2주)
  +-- Vercel API (현재) + AWS API (미러)
  +-- 양쪽 모두 Supabase DB 참조
  +-- 트래픽: Vercel 100%, AWS 0% (내부 테스트만)

Phase B: 트래픽 점진 이전 (1주)
  +-- Route 53 가중치 기반 라우팅
  +-- Vercel 90% -> 50% -> 10% -> 0%
  +-- AWS     10% -> 50% -> 90% -> 100%
  +-- 이상 발생 시 즉시 Vercel로 롤백

Phase C: DB 전환 (1일)
  +-- 짧은 유지보수 윈도우 (새벽 03:00-05:00)
  +-- Supabase -> RDS 최종 데이터 동기화
  +-- API의 DB 연결을 RDS로 전환
  +-- 모니터링 강화

Phase D: 정리 (1주)
  +-- Vercel 프로젝트 비활성화
  +-- Supabase 프로젝트 백업 후 보존 (30일)
  +-- DNS TTL 정상화
```

---

## 13. 에러 처리 표준

### 13.1 에러 코드 체계

```
에러 코드 형식: ERR_<SERVICE>_<NUMBER>

서비스 접두사:
  AUTH    - 인증/인가
  USER    - 사용자
  DEVICE  - 디바이스
  SESSION - 세션
  STATS   - 통계
  OTA     - 펌웨어
  ADMIN   - 관리자
  NOTIF   - 알림
  SYS     - 시스템
```

| 코드 | HTTP | 메시지 |
|------|------|--------|
| ERR_AUTH_001 | 401 | 인증 토큰이 없습니다 |
| ERR_AUTH_002 | 401 | 토큰이 만료되었습니다 |
| ERR_AUTH_003 | 401 | 토큰이 무효화되었습니다 (로그아웃됨) |
| ERR_AUTH_004 | 403 | 관리자 권한이 필요합니다 |
| ERR_AUTH_005 | 429 | 로그인 시도가 너무 많습니다 |
| ERR_USER_001 | 404 | 사용자를 찾을 수 없습니다 |
| ERR_USER_002 | 400 | 유효하지 않은 프로필 데이터입니다 |
| ERR_USER_003 | 409 | 이메일이 이미 사용 중입니다 |
| ERR_DEVICE_001 | 409 | 디바이스가 이미 등록되어 있습니다 |
| ERR_DEVICE_002 | 404 | 디바이스를 찾을 수 없습니다 |
| ERR_DEVICE_003 | 403 | 디바이스 소유자가 아닙니다 |
| ERR_DEVICE_004 | 409 | 진행 중인 이전 요청이 있습니다 |
| ERR_DEVICE_005 | 400 | 자기 자신에게 이전할 수 없습니다 |
| ERR_SESSION_001 | 400 | 유효하지 않은 세션 데이터입니다 |
| ERR_SESSION_002 | 404 | 세션을 찾을 수 없습니다 |
| ERR_SESSION_003 | 400 | 내보내기 범위가 365일을 초과합니다 |
| ERR_OTA_001 | 400 | 유효하지 않은 펌웨어 파일입니다 |
| ERR_OTA_002 | 409 | 이미 존재하는 버전입니다 |
| ERR_OTA_003 | 400 | 파일 크기가 2MB를 초과합니다 |
| ERR_SYS_001 | 500 | 내부 서버 오류 |
| ERR_SYS_002 | 503 | 서비스 일시 중단 |
| ERR_SYS_003 | 429 | 요청이 너무 많습니다 |

### 13.2 에러 응답 포맷

```typescript
interface ErrorResponse {
  error: {
    code: string;           // "ERR_DEVICE_001"
    message: string;        // 사용자 표시용 메시지
    details?: unknown;      // 추가 정보 (개발 환경에서만)
  };
}

// 예시
{
  "error": {
    "code": "ERR_DEVICE_001",
    "message": "디바이스가 이미 등록되어 있습니다",
    "details": {
      "serial_number": "DT-2026-001",
      "existing_device_id": "uuid"
    }
  }
}
```

### 13.3 에러 로깅

```
로깅 레벨:
  ERROR:   서버 오류 (500), 예외 발생
  WARN:    비즈니스 규칙 위반 (409, 403), Rate Limit 초과
  INFO:    정상 요청/응답 로그
  DEBUG:   상세 디버깅 (개발 환경에서만)

로그 포맷 (구조화된 JSON):
{
  "timestamp": "2026-02-08T10:30:00.123Z",
  "level": "ERROR",
  "request_id": "uuid",
  "method": "POST",
  "path": "/api/sessions/upload",
  "user_id": "uuid",
  "status": 500,
  "error": {
    "code": "ERR_SYS_001",
    "message": "Database connection timeout",
    "stack": "..." // 개발 환경에서만
  },
  "duration_ms": 5023
}
```

### 13.4 재시도 전략

```
클라이언트 (모바일 앱) 재시도 정책:

1. 네트워크 오류 (timeout, connection refused):
   - 최대 3회 재시도
   - 지수 백오프: 1초 -> 2초 -> 4초
   - 지터(jitter): +/- 500ms 랜덤

2. 서버 오류 (500, 502, 503):
   - 최대 2회 재시도
   - 지수 백오프: 2초 -> 4초
   - 503 + Retry-After 헤더 시 해당 값 사용

3. 재시도 불필요한 에러:
   - 400 (검증 실패) -> 요청 수정 후 재전송
   - 401 (인증 실패) -> 토큰 갱신 후 재전송
   - 403 (권한 없음) -> 재시도 불필요
   - 404 (없음) -> 재시도 불필요
   - 409 (충돌) -> 상태 확인 후 판단
   - 429 (Rate Limit) -> Retry-After 대기 후 재전송

서버 측 재시도 (비동기 작업):
  - 통계 집계 실패: 최대 3회 재시도, 5분 간격
  - 푸시 알림 실패: 최대 3회 재시도, 1분 간격
  - 이메일 발송 실패: 최대 5회 재시도, 지수 백오프
```

---

## 14. API 공통 규격

### 14.1 요청/응답 포맷

```
요청:
  Content-Type: application/json
  Accept: application/json

응답:
  Content-Type: application/json; charset=utf-8

날짜/시간:
  - ISO 8601 형식: "2026-02-08T10:30:00Z"
  - 타임존: UTC 기준으로 저장/전송
  - 클라이언트에서 사용자 타임존으로 변환

숫자:
  - 정수: JSON number
  - 통화/소수: 사용하지 않음
  - 시간: 초(seconds) 단위 정수
  - 전압: mV 단위 정수

NULL:
  - JSON null 사용
  - 빈 문자열("") 대신 null 사용
  - 빈 배열([])과 null 구분
```

### 14.2 인증 헤더

```
모든 인증 필요 API:
  Authorization: Bearer <supabase_jwt_token>

토큰 구조:
  - Supabase Auth에서 발급한 JWT
  - Header: { alg: "HS256", typ: "JWT" }
  - Payload: { sub: user_id, exp: expiry, role: "authenticated" }
  - 유효 기간: 1시간

토큰 없는 API (공개):
  GET /api/health
  GET /api/ping
```

### 14.3 페이지네이션 규격

```
요청:
  ?limit=20&offset=0

파라미터:
  limit:  1-200 (기본값은 엔드포인트별 상이, 보통 20 또는 50)
  offset: 0 이상의 정수

응답:
{
  "data": [...],          // 결과 배열
  "total": 156,           // 전체 개수
  "limit": 20,            // 요청한 limit
  "offset": 0,            // 요청한 offset
  "has_more": true        // offset + limit < total
}

다음 페이지:
  offset = offset + limit
  마지막 페이지: offset + limit >= total

대안 (커서 기반, Phase 2 고려):
  ?cursor=<last_item_id>&limit=20
  장점: 삽입/삭제 시에도 안정적
```

### 14.4 필터링/정렬 규격

```
필터링:
  ?device_id=uuid          # 정확 매칭
  ?start_date=2026-02-01   # 범위 시작
  ?end_date=2026-02-08     # 범위 끝
  ?search=홍길동            # 텍스트 검색 (ILIKE)
  ?is_active=true          # 불리언 필터
  ?role=admin              # 열거형 필터

정렬:
  ?sort_by=created_at      # 정렬 기준 컬럼
  ?sort_order=desc         # asc | desc (기본 desc)

복합 예시:
  GET /api/admin/users?search=김&role=user&sort_by=created_at&sort_order=desc&limit=20&offset=0

필터 기본값:
  - is_active: true (명시적으로 false를 보내지 않으면 활성 항목만)
  - sort_order: desc (최신순)
  - limit: 20 (목록), 50 (세션)
```

### 14.5 Rate Limit 헤더

```
모든 API 응답에 Rate Limit 정보를 헤더로 포함:

X-RateLimit-Limit: 100        # 윈도우당 최대 요청 수
X-RateLimit-Remaining: 95     # 남은 요청 수
X-RateLimit-Reset: 1707400860 # 윈도우 리셋 시각 (Unix timestamp)

Rate Limit 초과 시 (429):
{
  "error": {
    "code": "ERR_SYS_003",
    "message": "요청이 너무 많습니다",
    "retry_after": 30
  }
}

Retry-After 헤더: 30 (초)
```

### 14.6 HTTP 메서드 규칙

| 메서드 | 용도 | 멱등성 | 안전성 |
|--------|------|--------|--------|
| GET | 리소스 조회 | O | O |
| POST | 리소스 생성, 작업 실행 | X (세션 업로드는 UUID로 멱등) | X |
| PUT | 리소스 전체/부분 수정 | O | X |
| DELETE | 리소스 삭제/비활성화 | O | X |
| OPTIONS | CORS preflight | O | O |

### 14.7 CORS Preflight 처리

```
모든 API 핸들러의 첫 줄:
  if (req.method === 'OPTIONS') return res.status(200).end();

이유:
  - 브라우저의 CORS preflight 요청 (OPTIONS) 처리
  - Authorization 헤더 사용 시 preflight 필수
  - 200 OK 반환으로 실제 요청 허용
```

### 14.8 API 버전 관리

```
Phase 1:
  - 버전 없는 경로: /api/devices, /api/sessions
  - 초기 단계이므로 버전 관리 불필요

AWS 전환 후 (필요 시):
  - URL 기반 버전: /api/v1/devices, /api/v2/devices
  - 또는 헤더 기반: Accept: application/vnd.dualtetrax.v1+json
  - 이전 버전 최소 6개월 지원 후 폐기
```

---

**문서 끝**

*이 서비스 설계서는 DualTetraX 클라우드 서비스의 전체 서비스 구현 기준으로 사용되며, 개발 진행에 따라 지속적으로 업데이트된다.*
