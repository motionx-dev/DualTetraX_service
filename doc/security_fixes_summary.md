# DualTetraX Services - 보안 수정 요약

**날짜**: 2026-02-08
**레드팀 검토**: 완료
**수정된 CRITICAL 이슈**: 6개 중 3개
**상태**: 구현 준비 완료

---

## 요약

포괄적인 레드팀 보안 평가 결과 6개 카테고리에서 **15개의 취약점**이 발견되었습니다:
- **6개 CRITICAL** 이슈 (즉시 수정 필요)
- **5개 HIGH** 심각도 이슈
- **4개 MEDIUM** 심각도 이슈

본 문서는 모든 발견 사항과 해결 상태를 요약합니다.

---

## CRITICAL 이슈 (총 6개)

### ✅ CRITICAL #1: 타이밍 상관 공격을 통한 가명화 우회

**상태**: 문서에서 **수정 완료**
**파일**: `services/doc/security_privacy_design.md`

**문제점**:
```sql
-- 취약점: 동일한 타임스탬프로 상관 관계 파악 가능
INSERT INTO pii.user_id_mapping (real_user_id, pseudo_user_id, created_at)
  VALUES (..., ..., NOW());  -- 2026-02-08 10:30:15.123456

INSERT INTO analytics.devices (pseudo_user_id, created_at)
  VALUES (..., NOW());  -- 2026-02-08 10:30:15.123456

-- 공격자가 정확한 타임스탬프로 매칭 가능!
```

**구현된 수정사항**: 3계층 방어 전략

**계층 1: 타임스탬프 지터**
```sql
CREATE OR REPLACE FUNCTION add_timestamp_jitter(ts TIMESTAMP WITH TIME ZONE)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
  RETURN ts + (RANDOM() * INTERVAL '10 minutes' - INTERVAL '5 minutes');
END;
$$ LANGUAGE plpgsql VOLATILE;

-- 사용법
INSERT INTO pii.user_id_mapping (real_user_id, pseudo_user_id, created_at)
  VALUES (..., ..., add_timestamp_jitter(NOW()));
```

**계층 2: 공유 타임스탬프를 사용한 일괄 삽입**
```typescript
// 삽입을 큐에 저장하고 시간당 한 번씩 플러시
async function flushQueueToBatch() {
  const batchTimestamp = roundToHour(new Date());
  await supabase.from('analytics.devices').insert(
    insertionQueue.map(record => ({
      ...record,
      created_at: batchTimestamp  // 배치의 모든 레코드가 동일한 타임스탬프 공유
    }))
  );
}
```

**계층 3: 정밀도 절삭 (뷰 레벨 보호)**
```sql
CREATE VIEW analytics.devices_public AS
SELECT
  id,
  pseudo_user_id,
  DATE_TRUNC('hour', registered_at) AS registered_at,  -- 2026-02-08 10:00:00
  DATE_TRUNC('hour', created_at) AS created_at          -- 마이크로초 제거
FROM analytics.devices;

-- 분석가는 원본 테이블이 아닌 이 뷰에만 접근
GRANT SELECT ON analytics.devices_public TO analyst_role;
REVOKE SELECT ON analytics.devices FROM analyst_role;
```

**검증**:
- [x] `security_privacy_design.md` 섹션 3.3에 추가
- [ ] 백엔드 API에 구현 (대기 중)
- [ ] 타이밍 공격 방지를 위한 통합 테스트 추가

---

### ✅ CRITICAL #3: 프로필 업데이트를 통한 관리자 권한 상승

**상태**: 문서에서 **수정 완료**
**파일**: `services/doc/database_schema.md`

**문제점**:
```typescript
// 취약점: 사용자가 관리자로 권한 상승 가능
await supabase
  .from('profiles')
  .update({ role: 'admin' })  // ❌ 차단되어야 함!
  .eq('id', userId);
```

**구현된 수정사항**: RLS 정책 업데이트

**수정 전 (취약)**:
```sql
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);
  -- ❌ WITH CHECK 누락 - 권한 상승 허용!
```

**수정 후 (고정)**:
```sql
CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    -- 권한 상승 방지: role은 변경되지 않아야 함
    role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    -- name, timezone, language만 업데이트 허용
  );
```

**검증**:
- [x] `database_schema.md` 라인 85-92의 RLS 정책 업데이트
- [ ] Supabase/RDS에 배포 (대기 중)
- [ ] 테스트 케이스 추가: 권한 상승 시도 → 실패해야 함

---

### ✅ CRITICAL #5: JWT 토큰 무효화 불가 (로그아웃 없음)

**상태**: 문서에서 **수정 완료**
**파일**: `services/doc/api_specification.md`

**문제점**:
- API 명세에 로그아웃 엔드포인트 없음
- 탈취된 JWT 토큰이 만료까지 유효 (1시간)
- 계정이 탈취되어도 강제 로그아웃 불가

**구현된 수정사항**: Redis를 사용한 JWT 블랙리스트

**추가된 엔드포인트**: `POST /api/auth/logout`

**백엔드 구현 (Node.js + Redis)**:
```typescript
import { Redis } from '@upstash/redis';

const redis = Redis.fromEnv();

export async function POST(req: Request) {
  const token = extractToken(req.headers.get('authorization'));

  if (!token) {
    return Response.json({ error: 'No token provided' }, { status: 401 });
  }

  // 블랙리스트에 토큰 추가 (토큰 TTL과 일치하는 1시간 후 만료)
  await redis.set(`blacklist:${token}`, '1', { ex: 3600 });

  return Response.json({ message: 'Logged out successfully' });
}
```

**토큰 블랙리스트 확인을 위한 미들웨어**:
```typescript
export async function checkTokenBlacklist(token: string): Promise<boolean> {
  const isBlacklisted = await redis.get(`blacklist:${token}`);
  return isBlacklisted !== null;
}

// 인증 미들웨어에서 사용
async function authMiddleware(req: Request) {
  const token = extractToken(req.headers.get('authorization'));

  if (await checkTokenBlacklist(token)) {
    throw new Error('Token has been revoked');
  }

  // JWT 검증...
}
```

**비용**: Upstash Redis 무료 티어 (10K 커맨드/일) - $0/월

**검증**:
- [x] `api_specification.md` 섹션 2.4에 추가
- [ ] 로그아웃 엔드포인트 구현 (대기 중)
- [ ] 모든 인증 라우트에 블랙리스트 미들웨어 추가
- [ ] 테스트: 로그아웃 → 이후 API 호출은 실패해야 함

---

### ❌ CRITICAL #2: 무제한 분석가 데이터 내보내기

**상태**: **문서화됨 - 미구현**
**우선순위**: 출시 전 구현 필수

**문제점**:
```sql
-- 모든 분석가가 전체 analytics 스키마 내보내기 가능
SELECT * FROM analytics.sessions;  -- 1,000,000개 행 반환
SELECT * FROM analytics.devices;   -- 모든 기기 반환
```

**권장 수정사항**: 쿼리 결과 제한 + 감사 로깅

**계층 1: 행 제한이 있는 데이터베이스 뷰**
```sql
-- 직접 테이블 접근을 제한된 뷰로 대체
CREATE VIEW analytics.sessions_limited AS
SELECT * FROM analytics.sessions
LIMIT 10000;  -- 쿼리당 최대 10K 행

-- 분석가는 원본 테이블이 아닌 뷰에만 접근
GRANT SELECT ON analytics.sessions_limited TO analyst_role;
REVOKE SELECT ON analytics.sessions FROM analyst_role;
```

**계층 2: API 레벨 내보내기 제한**
```typescript
// 분석가용 백엔드 API 엔드포인트
export async function POST(req: Request) {
  const { query, limit = 1000 } = await req.json();

  // 최대 제한 강제
  if (limit > 10000) {
    return Response.json({ error: 'Max limit is 10,000 rows' }, { status: 400 });
  }

  // 모든 분석가 쿼리 로깅
  await auditLog.create({
    user_id: session.user.id,
    action: 'EXPORT_ANALYTICS',
    query: query,
    rows_returned: result.length,
    timestamp: new Date()
  });

  return Response.json(result);
}
```

**계층 3: 속도 제한**
```typescript
// 분석가당 시간당 10회 내보내기 제한
const rateLimit = new Ratelimit({
  redis: redis,
  limiter: Ratelimit.slidingWindow(10, '1h'),
});

const { success } = await rateLimit.limit(analystId);
if (!success) {
  return Response.json({ error: 'Rate limit exceeded' }, { status: 429 });
}
```

**구현 작업**:
- [ ] 데이터베이스 스키마에 analytics 제한 뷰 생성
- [ ] 속도 제한을 포함한 내보내기 API 엔드포인트 구현
- [ ] 모든 분석가 쿼리에 대한 감사 로깅 추가
- [ ] 분석가 활동 모니터링을 위한 관리자 대시보드 생성

---

### ❌ CRITICAL #4: 펌웨어 업로드 검증 없음

**상태**: **문서화됨 - 미구현**
**우선순위**: 펌웨어 업로드 기능 전 구현 필수

**문제점**:
```typescript
// 취약점: S3 업로드 전 검증 없음
await supabase.storage
  .from('firmware-binaries')
  .upload(`firmware-${version}.bin`, file);  // ❌ 체크섬, 크기, 멀웨어 검사 없음!
```

**권장 수정사항**: 다계층 검증 파이프라인

**계층 1: 클라이언트 측 사전 검증 (Flutter 앱)**
```dart
// 업로드 전 SHA256 체크섬 계산
import 'package:crypto/crypto.dart';

Future<String> calculateChecksum(File file) async {
  final bytes = await file.readAsBytes();
  final hash = sha256.convert(bytes);
  return hash.toString();
}

// 업로드 전 검증
if (file.lengthSync() > 10 * 1024 * 1024) {  // 10MB 제한
  throw Exception('File too large');
}
```

**계층 2: 백엔드 검증 (API)**
```typescript
export async function POST(req: Request) {
  const formData = await req.formData();
  const file = formData.get('file') as File;
  const providedChecksum = formData.get('checksum') as string;

  // 1. 크기 검증
  if (file.size > 10 * 1024 * 1024) {
    return Response.json({ error: 'File too large (max 10MB)' }, { status: 400 });
  }

  // 2. 체크섬 검증
  const actualChecksum = await calculateSHA256(file);
  if (actualChecksum !== providedChecksum) {
    return Response.json({ error: 'Checksum mismatch' }, { status: 400 });
  }

  // 3. 파일 확장자 검증
  if (!file.name.endsWith('.bin')) {
    return Response.json({ error: 'Invalid file type' }, { status: 400 });
  }

  // 4. 메타데이터와 함께 S3에 업로드
  await s3.putObject({
    Bucket: 'firmware-binaries',
    Key: `firmware-${version}.bin`,
    Body: await file.arrayBuffer(),
    Metadata: {
      'checksum-sha256': actualChecksum,
      'uploaded-by': session.user.id,
      'version': version
    }
  });

  return Response.json({ success: true });
}
```

**계층 3: 업로드 후 멀웨어 스캔 (AWS Lambda)**
```typescript
// S3 업로드 이벤트에 의해 트리거됨
export async function handler(event: S3Event) {
  const bucket = event.Records[0].s3.bucket.name;
  const key = event.Records[0].s3.object.key;

  // 스캔을 위해 ClamAV 또는 AWS GuardDuty 사용
  const scanResult = await scanFile(bucket, key);

  if (scanResult.infected) {
    // 감염된 파일 삭제
    await s3.deleteObject({ Bucket: bucket, Key: key });

    // 관리자에게 알림
    await sns.publish({
      TopicArn: 'arn:aws:sns:us-east-1:xxx:firmware-malware-alert',
      Message: `Infected firmware detected: ${key}`
    });
  }
}
```

**구현 작업**:
- [ ] 모바일 앱 펌웨어 업로드에 체크섬 계산 추가
- [ ] 백엔드 검증 엔드포인트 구현
- [ ] S3 버킷 정책 설정 (최대 크기 10MB)
- [ ] 멀웨어 스캔을 위한 Lambda 함수 배포
- [ ] 관리자 알림 시스템 추가

---

### ❌ CRITICAL #6: 다중 IP를 통한 속도 제한 우회

**상태**: **문서화됨 - 미구현**
**우선순위**: 공개 출시 전 구현

**문제점**:
```typescript
// 취약점: IP 기반 속도 제한은 쉽게 우회 가능
const rateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  keyGenerator: (req) => req.ip  // ❌ IP를 회전하여 우회 가능
});
```

**권장 수정사항**: 다요소 속도 제한

**계층 1: 지문 기반 속도 제한**
```typescript
import Fingerprint from '@fingerprintjs/fingerprintjs';

// 클라이언트 측 (브라우저)
const fp = await Fingerprint.load();
const result = await fp.get();
const visitorId = result.visitorId;  // 고유 기기 지문

// API 요청에 포함
fetch('/api/auth/login', {
  headers: {
    'X-Fingerprint': visitorId
  }
});
```

**백엔드 속도 제한**:
```typescript
const rateLimit = new Ratelimit({
  redis: redis,
  limiter: Ratelimit.slidingWindow(20, '1m'),

  // 지문으로 속도 제한, IP로 폴백
  prefix: (req) => {
    const fingerprint = req.headers.get('X-Fingerprint');
    return fingerprint || req.ip || 'unknown';
  }
});
```

**계층 2: 의심스러운 활동에 대한 CAPTCHA 챌린지**
```typescript
// 5회 실패한 로그인 시도 후 CAPTCHA 트리거
if (failedAttempts >= 5) {
  const captchaToken = req.headers.get('X-Captcha-Token');

  const captchaValid = await verifyCaptcha(captchaToken);
  if (!captchaValid) {
    return Response.json({
      error: 'CAPTCHA required',
      captcha_site_key: process.env.RECAPTCHA_SITE_KEY
    }, { status: 429 });
  }
}
```

**계층 3: 지수 백오프**
```typescript
// 각 위반 후 속도 제한 윈도우 증가
const violations = await redis.get(`violations:${fingerprint}`) || 0;
const backoffMinutes = Math.pow(2, violations);  // 1, 2, 4, 8, 16, 32...

await redis.set(`ratelimit:${fingerprint}`, '1', {
  ex: backoffMinutes * 60  // 잠금 시간을 지수적으로 증가
});
```

**구현 작업**:
- [ ] 프론트엔드에 FingerprintJS 통합
- [ ] 백엔드에서 지문 기반 속도 제한 구현
- [ ] 의심스러운 활동에 대한 Google reCAPTCHA v3 추가
- [ ] 반복 위반에 대한 지수 백오프 구현
- [ ] 속도 제한 위반을 위한 모니터링 대시보드 추가

---

## HIGH 심각도 이슈 (총 5개)

### 🟡 HIGH #1: 로그에 대한 입력 살균 없음

**문제점**: 사용자 입력이 살균 없이 로깅됨 → 로그 인젝션 공격

**예시**:
```typescript
// 취약점
console.log(`Login attempt from: ${email}`);
// email = "admin@test.com\n[ADMIN] Password: 12345"
// → 가짜 관리자 로그 주입됨!
```

**수정**: 로깅된 모든 사용자 입력 살균
```typescript
function sanitizeForLog(input: string): string {
  return input.replace(/[\n\r]/g, '').substring(0, 100);
}

console.log(`Login attempt from: ${sanitizeForLog(email)}`);
```

**상태**: 미구현

---

### 🟡 HIGH #2: 약한 비밀번호 재설정 플로우

**문제점**: 비밀번호 재설정 토큰이 SMS를 통해 전송됨 (쉽게 가로챌 수 있음)

**수정**: 이메일 기반 재설정을 주요 방법으로, SMS는 백업으로 추가
```typescript
// 이메일로 재설정 링크 전송 (주요)
await sendEmail({
  to: user.email,
  subject: 'Password Reset',
  body: `Reset your password: https://app.com/reset?token=${token}`
});

// SMS는 폴백으로만 (명시적인 사용자 동의 필요)
if (user.sms_reset_enabled) {
  await sendSMS({
    to: user.phone,
    message: `Reset code: ${code} (expires in 5 min)`
  });
}
```

**상태**: 미구현

---

### 🟡 HIGH #3: S3 버킷 암호화되지 않음

**문제점**: 펌웨어 바이너리와 사용자 데이터가 암호화되지 않음

**수정**: CDK에서 S3 버킷 암호화 활성화
```typescript
const firmwareBucket = new s3.Bucket(this, 'FirmwareBucket', {
  encryption: s3.BucketEncryption.S3_MANAGED,  // SSE-S3 활성화
  enforceSSL: true,  // HTTPS 필수
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL
});
```

**상태**: 미구현 (infrastructure/lib/storage-stack.ts에 추가)

---

### 🟡 HIGH #4: HTTPS 강제 없음

**문제점**: API가 HTTP 요청 허용 (MITM 공격에 취약)

**수정**: API Gateway에서 HTTPS 강제
```typescript
const api = new apigateway.RestApi(this, 'API', {
  restApiName: 'DualTetraX API',
  deployOptions: {
    stageName: 'prod',
    tracingEnabled: true,
  },
  // HTTPS만 강제
  policy: new iam.PolicyDocument({
    statements: [
      new iam.PolicyStatement({
        effect: iam.Effect.DENY,
        principals: [new iam.AnyPrincipal()],
        actions: ['execute-api:Invoke'],
        resources: ['execute-api:/*'],
        conditions: {
          Bool: { 'aws:SecureTransport': 'false' }
        }
      })
    ]
  })
});
```

**상태**: 미구현 (infrastructure/lib/api-stack.ts에 추가)

---

### 🟡 HIGH #5: 세션 타임아웃 없음

**문제점**: 사용자 세션이 만료되지 않음 (다른 기기에서 로그아웃 후에도)

**수정**: Supabase Auth에서 세션 타임아웃 구현
```typescript
const supabase = createClient(url, key, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
    // 1시간 비활성 후 세션 만료
    storageKey: 'dualtetrax-auth',
    storage: AsyncStorage,
  },
  global: {
    headers: {
      'X-Client-Info': 'dualtetrax-mobile-v1.0.0'
    }
  }
});

// Supabase 대시보드에서 JWT 만료 설정을 1시간으로 설정
// Auth > Settings > JWT Expiry = 3600 seconds
```

**상태**: 미구현 (Supabase 프로젝트 설정에서 구성)

---

## MEDIUM 심각도 이슈 (총 4개)

### 🟢 MEDIUM #1: CORS 구성 없음

**수정**: API Gateway에서 CORS 구성
```typescript
defaultCorsPreflightOptions: {
  allowOrigins: ['https://app.dualtetrax.com', 'https://admin.dualtetrax.com'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: cdk.Duration.hours(1)
}
```

**상태**: api_specification.md에 이미 구현됨

---

### 🟢 MEDIUM #2: 데이터베이스 연결 풀링 없음

**수정**: PgBouncer 또는 RDS Proxy 사용
```typescript
const dbProxy = new rds.DatabaseProxy(this, 'DBProxy', {
  proxyTarget: rds.ProxyTarget.fromCluster(cluster),
  secrets: [secret],
  vpc,
  maxConnectionsPercent: 90  // 사용 가능한 연결의 90% 사용
});
```

**상태**: 미구현 (infrastructure/lib/database-stack.ts에 추가)

---

### 🟢 MEDIUM #3: API 버전 관리 없음

**수정**: API 라우트에 버전 관리 추가
```
/api/v1/auth/login
/api/v1/devices
/api/v2/devices  (향후)
```

**상태**: 미구현

---

### 🟢 MEDIUM #4: 오류율 모니터링 없음

**수정**: 오류율에 대한 CloudWatch 알람 추가
```typescript
new cloudwatch.Alarm(this, 'HighErrorRate', {
  metric: apiFunction.metricErrors(),
  threshold: 10,  // 5분 내 10개 이상 오류 시 알림
  evaluationPeriods: 1,
});
```

**상태**: 미구현 (infrastructure/lib/monitoring-stack.ts에 추가)

---

## 구현 우선순위

### 출시 전 (차단):
1. ✅ **CRITICAL #1**: 가명화 타이밍 공격 수정
2. ✅ **CRITICAL #3**: 관리자 권한 상승 수정
3. ✅ **CRITICAL #5**: JWT 로그아웃 엔드포인트
4. ❌ **CRITICAL #2**: 분석가 데이터 내보내기 제한
5. ❌ **HIGH #3**: S3 버킷 암호화
6. ❌ **HIGH #4**: HTTPS 강제

### 첫 달 내:
7. ❌ **CRITICAL #4**: 펌웨어 업로드 검증
8. ❌ **CRITICAL #6**: 속도 제한 개선
9. ❌ **HIGH #1**: 로그 살균
10. ❌ **HIGH #2**: 비밀번호 재설정 플로우 개선

### 첫 분기 내:
11. ❌ **HIGH #5**: 세션 타임아웃
12. ❌ **MEDIUM #2**: 데이터베이스 연결 풀링
13. ❌ **MEDIUM #3**: API 버전 관리
14. ❌ **MEDIUM #4**: 오류율 모니터링

---

## 테스트 요구사항

### 추가할 보안 테스트 케이스:

**타이밍 공격 테스트**:
```typescript
describe('Pseudonymization Timing Attack', () => {
  it('should prevent correlation via timestamp matching', async () => {
    const user1 = await createUser('user1@test.com');
    const user2 = await createUser('user2@test.com');

    // 두 스키마에서 타임스탬프 가져오기
    const piiTimestamp = await getPIITimestamp(user1.id);
    const analyticsTimestamp = await getAnalyticsTimestamp(user1.pseudoId);

    // 타임스탬프는 최소 1분 이상 차이가 나야 함 (지터로 인해)
    const diff = Math.abs(piiTimestamp - analyticsTimestamp);
    expect(diff).toBeGreaterThan(60 * 1000);  // >1분
  });
});
```

**권한 상승 테스트**:
```typescript
describe('Admin Role Escalation', () => {
  it('should prevent users from escalating to admin', async () => {
    const user = await createUser('user@test.com', 'user');

    // 권한 상승 시도
    await expect(
      supabase
        .from('profiles')
        .update({ role: 'admin' })
        .eq('id', user.id)
    ).rejects.toThrow('RLS policy violation');

    // 권한이 변경되지 않았는지 확인
    const profile = await getProfile(user.id);
    expect(profile.role).toBe('user');
  });
});
```

**JWT 블랙리스트 테스트**:
```typescript
describe('JWT Logout', () => {
  it('should invalidate token after logout', async () => {
    const { token } = await login('user@test.com', 'password');

    // 로그아웃
    await fetch('/api/auth/logout', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` }
    });

    // 이후 API 호출은 실패해야 함
    const response = await fetch('/api/devices', {
      headers: { Authorization: `Bearer ${token}` }
    });

    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ error: 'Token has been revoked' });
  });
});
```

---

## 보안 수정의 비용 영향

| 수정사항 | 추가 월 비용 |
|---------|------------|
| Redis (JWT 블랙리스트) | $0 (Upstash 무료 티어) |
| S3 암호화 | $0 (SSE-S3 포함) |
| HTTPS 강제 | $0 (API Gateway 네이티브) |
| 멀웨어 스캔 (ClamAV Lambda) | ~$2-5 (Lambda 실행) |
| 속도 제한 (Upstash Redis) | $0 (무료 티어: 10K 커맨드/일) |
| 감사 로깅 (CloudWatch) | ~$3-5 (추가 로그) |
| **합계** | **~$5-10/월** |

**순 영향**: 보안 수정사항으로 인프라 비용이 월 ~$10 추가됩니다.

---

## 다음 단계

1. **팀과 이 요약 검토**
2. **출시 전 CRITICAL 이슈 구현 우선순위 지정**
3. **백엔드 테스트 스위트에 보안 테스트 케이스 추가**
4. **수정사항 배포 후 침투 테스트 일정 계획**
5. **보안 모니터링 설정** (CloudWatch + 알림)

---

**문서 끝**
