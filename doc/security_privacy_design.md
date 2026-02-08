# DualTetraX Services - Security & Privacy Design

**Version**: 1.0
**Date**: 2026-02-08
**Classification**: Confidential

---

## 1. Executive Summary

DualTetraX Services는 **개인정보 보호를 최우선**으로 하는 스타트업으로, 사용자 데이터 유출 위험을 최소화하기 위해 **데이터 분리 아키텍처**를 채택합니다.

### 1.1 핵심 원칙
1. **Data Minimization**: 최소한의 개인정보만 수집
2. **Separation of Concerns**: 개인정보와 분석 데이터 완전 분리
3. **Pseudonymization**: 개인화 서비스에 익명 ID만 사용
4. **Encryption Everywhere**: 저장/전송 중 모두 암호화
5. **GDPR Compliance**: 유럽 개인정보 보호법 준수

---

## 2. Data Separation Architecture

### 2.1 개인정보 vs 분석 데이터 분리

**문제**: 개인정보(이름, 이메일, 전화번호)와 사용 데이터가 같은 DB에 저장되면, DB 해킹 시 개인정보와 행동 패턴이 동시에 유출됨.

**해결책**: 두 개의 **논리적으로 분리된 데이터베이스 스키마** 사용

```
┌────────────────────────────────────────────────────────────┐
│              Supabase PostgreSQL Instance                  │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────┐  ┌─────────────────────────┐   │
│  │  pii_schema          │  │  analytics_schema       │   │
│  │  (Personal Data)     │  │  (Pseudonymized Data)   │   │
│  ├──────────────────────┤  ├─────────────────────────┤   │
│  │ - auth.users         │  │ - devices               │   │
│  │ - profiles           │  │   (pseudo_user_id only) │   │
│  │   (email, name,      │  │ - usage_sessions        │   │
│  │    phone_number)     │  │   (pseudo_user_id only) │   │
│  │                      │  │ - daily_statistics      │   │
│  │ - user_id_mapping    │  │ - skin_profiles         │   │
│  │   (real_id ↔ pseudo) │  │   (pseudo_user_id only) │   │
│  └──────────────────────┘  │ - recommendations       │   │
│           ↑                │   (pseudo_user_id only) │   │
│           │                └─────────────────────────┘   │
│           │                         ↑                    │
│           │                         │                    │
│           └─────────────────────────┘                    │
│              (Mapping via secure API only)               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 2.2 Pseudonymization (익명화 ID)

**개념**:
- `real_user_id` (UUID): auth.users의 실제 사용자 ID
- `pseudo_user_id` (UUID): 분석용 익명 ID
- 두 ID 간 매핑은 `pii_schema.user_id_mapping` 테이블에만 저장

**장점**:
- `analytics_schema`가 유출되어도 개인정보와 직접 연결 불가
- 분석가는 `pseudo_user_id`만 보고 분석 가능
- GDPR "Right to be Forgotten" 구현 용이 (매핑만 삭제)

---

## 3. Database Schema Separation

### 3.1 PII Schema (Personal Identifiable Information)

**접근 제한**:
- 관리자 중 극소수만 접근 가능
- 모든 접근 기록 (audit log)

```sql
-- PII Schema (개인정보 보호 구역)
CREATE SCHEMA pii;

-- User profiles (only PII fields)
CREATE TABLE pii.profiles (
  real_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  phone_number TEXT,
  profile_image_url TEXT,

  -- Sensitive fields
  date_of_birth DATE,
  gender TEXT,

  -- Encrypted notes (for support)
  encrypted_notes TEXT,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User ID Mapping (real ↔ pseudo)
CREATE TABLE pii.user_id_mapping (
  real_user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  pseudo_user_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE pii.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pii.user_id_mapping ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own PII
CREATE POLICY "users_own_pii" ON pii.profiles
  FOR SELECT USING (auth.uid() = real_user_id);

-- Policy: Only system can access mapping (no direct user access)
CREATE POLICY "no_direct_mapping_access" ON pii.user_id_mapping
  FOR SELECT USING (FALSE); -- No one can SELECT directly

-- Function to get pseudo_user_id (secure)
CREATE OR REPLACE FUNCTION pii.get_pseudo_user_id(p_real_user_id UUID)
RETURNS UUID AS $$
DECLARE
  v_pseudo_id UUID;
BEGIN
  -- Only allow if caller is authenticated as p_real_user_id
  IF auth.uid() != p_real_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT pseudo_user_id INTO v_pseudo_id
  FROM pii.user_id_mapping
  WHERE real_user_id = p_real_user_id;

  RETURN v_pseudo_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### 3.2 Analytics Schema (Pseudonymized Data)

**접근 제한**:
- 일반 직원, 분석가 접근 가능
- `pseudo_user_id`만 존재, 개인정보 없음

```sql
-- Analytics Schema (분석 데이터 구역)
CREATE SCHEMA analytics;

-- Devices (pseudonymized)
CREATE TABLE analytics.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pseudo_user_id UUID NOT NULL, -- NO FOREIGN KEY to pii schema

  -- Device info (no PII)
  serial_number TEXT UNIQUE NOT NULL,
  model_name TEXT NOT NULL,
  firmware_version TEXT NOT NULL,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  last_connected_at TIMESTAMP WITH TIME ZONE,

  -- Timestamps
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Usage sessions (pseudonymized)
CREATE TABLE analytics.usage_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES analytics.devices(id) ON DELETE CASCADE NOT NULL,
  pseudo_user_id UUID NOT NULL, -- Pseudonymized

  -- Session data (no PII)
  shot_type TEXT NOT NULL,
  device_mode TEXT NOT NULL,
  level INT NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  working_duration INT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Skin profiles (pseudonymized)
CREATE TABLE analytics.skin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  pseudo_user_id UUID UNIQUE NOT NULL, -- NO PII

  -- Skin info (no PII)
  skin_type TEXT,
  concerns TEXT[],
  preferred_modes TEXT[],

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_devices_pseudo_user ON analytics.devices(pseudo_user_id);
CREATE INDEX idx_sessions_pseudo_user ON analytics.usage_sessions(pseudo_user_id);
```

---

### 3.3 Anti-Timing Attack Measures

**CRITICAL SECURITY**: Prevent correlation attacks that link `real_user_id` to `pseudo_user_id` via timestamp analysis.

#### Problem: Timing Correlation Attack
```typescript
// ATTACK SCENARIO:
// 1. User creates account at T1 → real_user_id = UUID_A
// 2. User registers device at T2 → analytics.devices created with pseudo_user_id = UUID_B
// 3. Attacker queries analytics.devices WHERE created_at BETWEEN T1 AND T2
// 4. Result: UUID_A → UUID_B mapping discovered WITHOUT accessing pii.user_id_mapping
```

#### Solution 1: Timestamp Jitter (Random Noise)

**Implementation**:
```sql
-- Add random jitter function
CREATE OR REPLACE FUNCTION add_timestamp_jitter(ts TIMESTAMP WITH TIME ZONE)
RETURNS TIMESTAMP WITH TIME ZONE AS $$
BEGIN
  -- Add random offset: -5 minutes to +5 minutes
  RETURN ts + (RANDOM() * INTERVAL '10 minutes' - INTERVAL '5 minutes');
END;
$$ LANGUAGE plpgsql VOLATILE;

-- Apply jitter to analytics tables
CREATE TABLE analytics.devices (
  -- ... other columns
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT add_timestamp_jitter(NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT add_timestamp_jitter(NOW())
);

CREATE TABLE analytics.usage_sessions (
  -- ... other columns
  synced_from_device_at TIMESTAMP WITH TIME ZONE DEFAULT add_timestamp_jitter(NOW()),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT add_timestamp_jitter(NOW())
);
```

#### Solution 2: Batch Insertion (Hourly Grouping)

**Implementation**:
```typescript
// Backend API: Queue insertions, insert in batches every hour
const insertionQueue = [];

export async function queueAnalyticsRecord(record: any) {
  insertionQueue.push(record);

  // Flush queue every hour (not immediately)
  if (shouldFlushQueue()) {
    await flushQueueToBatch();
  }
}

async function flushQueueToBatch() {
  // All records in batch get SAME created_at timestamp
  const batchTimestamp = roundToHour(new Date());

  await supabase.from('analytics.devices').insert(
    insertionQueue.map(record => ({
      ...record,
      created_at: batchTimestamp
    }))
  );

  insertionQueue.length = 0;
}
```

#### Solution 3: Remove Precision from Timestamps

**Implementation**:
```sql
-- Truncate timestamps to hour precision (hide exact time)
CREATE VIEW analytics.devices_public AS
SELECT
  id,
  pseudo_user_id,
  serial_number,
  model_name,
  DATE_TRUNC('hour', registered_at) AS registered_at,  -- Hour precision only
  DATE_TRUNC('hour', created_at) AS created_at
FROM analytics.devices;

-- Analysts query the VIEW (not raw table)
REVOKE SELECT ON analytics.devices FROM analyst_role;
GRANT SELECT ON analytics.devices_public TO analyst_role;
```

#### Recommendation: Use All Three

1. **Jitter**: Immediate protection, easy to implement
2. **Batch Insertion**: Best protection, but adds latency
3. **Truncate Precision**: Defense-in-depth for analyst queries

---

## 4. API Layer: Data Separation

### 4.1 Public API (User-facing)

**Challenge**: 사용자는 `real_user_id`로 인증하지만, 분석 데이터는 `pseudo_user_id`로 저장됨.

**Solution**: API Layer에서 자동 변환

```typescript
// api/devices/register.ts (Vercel Function)
import { createClient } from '@supabase/supabase-js'

export async function POST(req: Request) {
  const supabase = createClient(...)
  const { user } = await supabase.auth.getUser()
  const real_user_id = user.id

  // 1. Get pseudo_user_id
  const { data: mapping } = await supabase.rpc('pii.get_pseudo_user_id', {
    p_real_user_id: real_user_id
  })
  const pseudo_user_id = mapping.pseudo_user_id

  // 2. Register device with pseudo_user_id (NOT real_user_id)
  const { serial_number, model_name } = await req.json()

  const { data: device } = await supabase
    .schema('analytics')
    .from('devices')
    .insert({
      pseudo_user_id: pseudo_user_id, // ← Pseudonymized!
      serial_number,
      model_name
    })

  return Response.json(device)
}
```

**Result**:
- `analytics.devices` 테이블에는 `pseudo_user_id`만 저장
- 해커가 `analytics` 스키마를 탈취해도 개인정보와 연결 불가

---

### 4.2 Admin API (Restricted)

**Challenge**: 관리자는 사용자 이메일로 검색해야 함.

**Solution**: Admin API에서만 매핑 테이블 접근 허용

```typescript
// api/admin/users.ts (Admin only)
export async function GET(req: Request) {
  // 1. Verify admin role
  const { user } = await supabase.auth.getUser()
  const { data: profile } = await supabase
    .from('pii.profiles')
    .select('role')
    .eq('real_user_id', user.id)
    .single()

  if (profile.role !== 'admin') {
    return Response.json({ error: 'Forbidden' }, { status: 403 })
  }

  // 2. Get PII data (email, name) + pseudo_user_id
  const { data: users } = await supabase
    .schema('pii')
    .from('profiles')
    .select(`
      real_user_id,
      email,
      name,
      user_id_mapping!inner(pseudo_user_id)
    `)

  // 3. For each user, get analytics data from analytics schema
  const enrichedUsers = await Promise.all(users.map(async (u) => {
    const { data: devices } = await supabase
      .schema('analytics')
      .from('devices')
      .select('count')
      .eq('pseudo_user_id', u.user_id_mapping.pseudo_user_id)

    return {
      email: u.email, // PII
      name: u.name,   // PII
      device_count: devices.count // Analytics
    }
  }))

  return Response.json(enrichedUsers)
}
```

---

## 5. Encryption Strategy

### 5.1 Encryption at Rest

**Database**:
- Supabase PostgreSQL: AES-256 encryption (automatic)
- Encrypted disk volumes

**Storage**:
- Supabase Storage: AES-256 (automatic)
- Firmware binaries: Server-side encryption
- Profile images: Public (no sensitive data)

**Secrets**:
- API keys, tokens: Vercel Environment Variables (encrypted)
- Database password: Supabase managed (auto-rotated)

---

### 5.2 Encryption in Transit

**HTTPS Only**:
- TLS 1.3 for all API calls
- Certificate pinning in mobile app (optional, for extra security)

**BLE Encryption**:
- BLE pairing with encryption (if supported by device)
- Firmware OTA: Checksum verification (SHA256)

---

### 5.3 Field-Level Encryption (Optional for ultra-sensitive data)

**Use Case**: 사용자가 민감한 메모를 남기는 경우 (예: 건강 정보)

```sql
-- Example: Encrypted notes field
CREATE TABLE pii.user_notes (
  id UUID PRIMARY KEY,
  real_user_id UUID REFERENCES auth.users(id),
  encrypted_content TEXT, -- Encrypted with user's key
  iv TEXT, -- Initialization vector
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Implementation**:
- Client-side encryption (AES-256-GCM)
- User's encryption key derived from password (PBKDF2)
- Server never sees plaintext

---

## 6. Access Control

### 6.1 Role-Based Access Control (RBAC)

**Roles**:
```sql
CREATE TYPE user_role AS ENUM ('user', 'analyst', 'admin', 'super_admin');

ALTER TABLE pii.profiles ADD COLUMN role user_role DEFAULT 'user';
```

**Permissions**:

| Role | PII Schema | Analytics Schema | Admin API |
|------|------------|------------------|-----------|
| user | Own data only | Own data (via API) | ❌ |
| analyst | ❌ | All (read-only) | ❌ |
| admin | All (with audit log) | All | ✅ (limited) |
| super_admin | All | All | ✅ (full) |

---

### 6.2 Row Level Security (RLS) Policies

**PII Schema**:
```sql
-- Users can only see their own PII
CREATE POLICY "users_own_pii" ON pii.profiles
  FOR ALL USING (auth.uid() = real_user_id);

-- Admins can see all PII (with audit logging)
CREATE POLICY "admins_see_all_pii" ON pii.profiles
  FOR SELECT USING (
    auth.uid() IN (
      SELECT real_user_id FROM pii.profiles WHERE role IN ('admin', 'super_admin')
    )
  );
```

**Analytics Schema**:
```sql
-- Users can see their own analytics (via pseudo_user_id)
CREATE POLICY "users_own_analytics" ON analytics.usage_sessions
  FOR SELECT USING (
    pseudo_user_id = (
      SELECT pseudo_user_id FROM pii.user_id_mapping WHERE real_user_id = auth.uid()
    )
  );

-- Analysts can see all analytics (no PII)
CREATE POLICY "analysts_see_all_analytics" ON analytics.usage_sessions
  FOR SELECT USING (
    auth.uid() IN (
      SELECT real_user_id FROM pii.profiles WHERE role IN ('analyst', 'admin', 'super_admin')
    )
  );
```

---

## 7. Audit Logging

### 7.1 PII Access Logs

**Requirement**: 모든 PII 접근 기록

```sql
CREATE TABLE pii.access_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  accessor_id UUID REFERENCES auth.users(id), -- Who accessed
  target_user_id UUID, -- Whose PII was accessed
  action TEXT NOT NULL, -- 'SELECT', 'UPDATE', 'DELETE'
  table_name TEXT NOT NULL,
  accessed_fields TEXT[], -- Which columns were accessed
  ip_address INET,
  user_agent TEXT,
  accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Trigger to log all PII access
CREATE OR REPLACE FUNCTION pii.log_pii_access()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO pii.access_logs (accessor_id, target_user_id, action, table_name)
  VALUES (auth.uid(), NEW.real_user_id, TG_OP, TG_TABLE_NAME);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_pii_profiles
  AFTER SELECT OR UPDATE OR DELETE ON pii.profiles
  FOR EACH ROW EXECUTE FUNCTION pii.log_pii_access();
```

---

### 7.2 Admin Action Logs

**Requirement**: 관리자의 모든 중요 액션 기록

```sql
CREATE TABLE admin_action_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES auth.users(id),
  action TEXT NOT NULL, -- 'user_deleted', 'device_banned', etc.
  resource_type TEXT, -- 'user', 'device', 'firmware'
  resource_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address INET,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**API Example**:
```typescript
// api/admin/delete-user.ts
async function deleteUser(userId: string, adminId: string) {
  // 1. Log the action BEFORE deletion
  await supabase.from('admin_action_logs').insert({
    admin_id: adminId,
    action: 'user_deleted',
    resource_type: 'user',
    resource_id: userId,
    old_value: await getUserData(userId) // Save data before deletion
  })

  // 2. Delete user
  await supabase.from('pii.profiles').delete().eq('real_user_id', userId)
}
```

---

## 8. GDPR Compliance

### 8.1 Right to Access (데이터 열람권)

**API**: `GET /api/gdpr/my-data`

```typescript
// Returns ALL user data in JSON format
export async function GET(req: Request) {
  const { user } = await supabase.auth.getUser()
  const real_user_id = user.id

  // 1. Get PII data
  const { data: pii } = await supabase
    .schema('pii')
    .from('profiles')
    .select('*')
    .eq('real_user_id', real_user_id)
    .single()

  // 2. Get pseudo_user_id
  const { data: mapping } = await supabase
    .schema('pii')
    .from('user_id_mapping')
    .select('pseudo_user_id')
    .eq('real_user_id', real_user_id)
    .single()

  // 3. Get analytics data
  const { data: devices } = await supabase
    .schema('analytics')
    .from('devices')
    .select('*')
    .eq('pseudo_user_id', mapping.pseudo_user_id)

  const { data: sessions } = await supabase
    .schema('analytics')
    .from('usage_sessions')
    .select('*')
    .eq('pseudo_user_id', mapping.pseudo_user_id)

  // 4. Return everything
  return Response.json({
    personal_info: pii,
    devices,
    sessions,
    generated_at: new Date().toISOString()
  })
}
```

---

### 8.2 Right to be Forgotten (삭제권)

**API**: `DELETE /api/gdpr/delete-my-data`

**Implementation**:
```typescript
export async function DELETE(req: Request) {
  const { user } = await supabase.auth.getUser()
  const real_user_id = user.id

  // 1. Get pseudo_user_id
  const { data: mapping } = await supabase
    .schema('pii')
    .from('user_id_mapping')
    .select('pseudo_user_id')
    .eq('real_user_id', real_user_id)
    .single()

  // 2. Delete from PII schema (cascades to auth.users)
  await supabase
    .schema('pii')
    .from('profiles')
    .delete()
    .eq('real_user_id', real_user_id)

  // 3. Delete mapping (makes analytics data anonymous)
  await supabase
    .schema('pii')
    .from('user_id_mapping')
    .delete()
    .eq('real_user_id', real_user_id)

  // 4. Analytics data remains BUT pseudo_user_id is now orphaned
  // → Cannot be linked back to real user (anonymous)

  // Optional: Also delete analytics data
  await supabase
    .schema('analytics')
    .from('devices')
    .delete()
    .eq('pseudo_user_id', mapping.pseudo_user_id)

  return Response.json({ message: 'All data deleted' })
}
```

---

### 8.3 Right to Data Portability (이동권)

**API**: `GET /api/gdpr/export-data?format=json|csv`

**Formats**:
- JSON: Machine-readable
- CSV: Human-readable (for Excel)

---

## 9. Security Best Practices

### 9.1 Password Policy

- Minimum 8 characters
- Must include: uppercase, lowercase, number, special char
- Password strength meter in UI
- Prevent common passwords (e.g., "password123")

```typescript
// Zod validation
const passwordSchema = z.string()
  .min(8, "Password must be at least 8 characters")
  .regex(/[A-Z]/, "Must include uppercase")
  .regex(/[a-z]/, "Must include lowercase")
  .regex(/[0-9]/, "Must include number")
  .regex(/[@$!%*?&#]/, "Must include special character")
```

---

### 9.2 Rate Limiting

**Purpose**: Prevent brute force attacks

```typescript
// Vercel Edge Middleware
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'), // 10 requests per 10 seconds
})

export async function middleware(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous'
  const { success } = await ratelimit.limit(ip)

  if (!success) {
    return Response.json({ error: 'Too many requests' }, { status: 429 })
  }

  return next()
}
```

---

### 9.3 SQL Injection Prevention

**Supabase**: Automatic (parameterized queries)

**Custom Functions**: Always use parameterized queries

```typescript
// ❌ BAD (SQL injection risk)
const query = `SELECT * FROM users WHERE email = '${userInput}'`

// ✅ GOOD (parameterized)
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userInput) // Supabase escapes this
```

---

### 9.4 XSS Prevention

**Next.js**: Automatic escaping in JSX

**User-generated content**: Sanitize with DOMPurify

```typescript
import DOMPurify from 'isomorphic-dompurify'

const sanitizedHTML = DOMPurify.sanitize(userInput)
```

---

## 10. Incident Response Plan

### 10.1 Data Breach Detection

**Monitoring**:
- Unusual PII access patterns (e.g., admin accessing 100+ users in 1 minute)
- Failed login attempts spike
- Database query anomalies

**Alerts**:
- Slack notification
- Email to security team
- PagerDuty (for critical)

---

### 10.2 Breach Response Procedure

1. **Immediate** (< 1 hour):
   - Isolate affected systems
   - Revoke compromised credentials
   - Enable audit logging (if not already)

2. **Investigation** (< 24 hours):
   - Identify scope of breach (which data leaked)
   - Check audit logs for unauthorized access
   - Notify affected users (if PII leaked)

3. **Remediation** (< 7 days):
   - Patch vulnerabilities
   - Force password reset for affected users
   - Notify authorities (GDPR requires 72 hours)

4. **Post-Mortem**:
   - Write incident report
   - Update security policies
   - Train team

---

## 11. Summary: Why This Design is Secure

| Risk | Mitigation |
|------|------------|
| **PII Leak** | Separated schemas, pseudonymization |
| **Analytics Data Leak** | No PII in analytics schema |
| **Database Breach** | RLS, encryption at rest, audit logs |
| **Insider Threat** | Audit logs, role-based access control |
| **GDPR Violation** | Data portability, right to be forgotten APIs |
| **SQL Injection** | Supabase parameterized queries |
| **XSS** | Next.js auto-escaping, DOMPurify |
| **Brute Force** | Rate limiting, strong password policy |

---

## 12. Checklist for Developers

- [ ] Always use `pseudo_user_id` in analytics schema
- [ ] Never store PII (email, name, phone) in analytics schema
- [ ] Use Supabase RLS policies (never bypass)
- [ ] Log all PII access in `pii.access_logs`
- [ ] Validate user input (Zod schemas)
- [ ] Use HTTPS only (no HTTP)
- [ ] Rotate secrets every 90 days
- [ ] Review audit logs weekly
- [ ] Test GDPR export/delete APIs monthly

---

**Document End**
