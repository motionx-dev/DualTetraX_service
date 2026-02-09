# DualTetraX 데이터 처리 계획

## 1. 현재 상태: 실시간 쿼리 (Phase 1)

### 구조
```
Frontend → API Request → Supabase 직접 쿼리 → JSON Response
```

### 대상 테이블
| 테이블 | 용도 | 예상 증가율 |
|--------|------|-------------|
| `usage_sessions` | 세션 데이터 (사용시간, 모드, 종료사유 등) | ~10-50건/사용자/월 |
| `profiles` | 사용자 프로필 (연령, 성별, timezone) | 사용자 수만큼 |
| `devices` | 디바이스 정보 (FW버전, 활성 상태) | ~1-3개/사용자 |

### 7개 Analytics API
1. **Overview** — 확장 KPI (활성 사용자, 신규, 평균 세션/완료율)
2. **Usage Trends** — 일별 세션 수 + 평균 사용시간
3. **Feature Usage** — 모드별/샷타입별 사용 빈도
4. **Demographics** — 연령/성별/timezone 분포
5. **Heatmap** — 시간대별 사용 히트맵 (시간 × 요일)
6. **Termination** — 종료 사유 분포 + 완료율
7. **Firmware Dist** — FW 버전 분포

### 적합한 규모
- 사용자 < 1,000명
- 세션 < 100,000건
- 응답시간 < 2초

---

## 2. Phase 2: 인덱스 최적화 (사용자 1,000~5,000명)

### Supabase에 인덱스 추가
```sql
-- usage_sessions 테이블 인덱스
CREATE INDEX idx_sessions_start_time ON usage_sessions(start_time);
CREATE INDEX idx_sessions_user_device ON usage_sessions(user_id, device_id);
CREATE INDEX idx_sessions_shot_type ON usage_sessions(shot_type, device_mode);

-- profiles 테이블 인덱스
CREATE INDEX idx_profiles_created ON profiles(created_at);
CREATE INDEX idx_profiles_dob ON profiles(date_of_birth);

-- devices 테이블 인덱스
CREATE INDEX idx_devices_active ON devices(is_active);
CREATE INDEX idx_devices_firmware ON devices(firmware_version);
```

### 변경 범위
- Supabase Dashboard에서 인덱스 생성 (SQL Editor)
- 코드 변경 없음
- API 응답 속도 2-5배 개선 예상

---

## 3. Phase 3: 집계 테이블 + Cron 배치 (사용자 5,000명 이상)

### 새 테이블 설계

```sql
-- 일별 집계 테이블
CREATE TABLE analytics_daily (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date date NOT NULL,
  total_sessions integer DEFAULT 0,
  total_duration_seconds integer DEFAULT 0,
  unique_users integer DEFAULT 0,
  new_users integer DEFAULT 0,
  -- 모드별 세션 수
  mode_breakdown jsonb DEFAULT '{}',
  -- 샷타입별 세션 수
  shot_type_breakdown jsonb DEFAULT '{}',
  -- 종료사유별 카운트
  termination_breakdown jsonb DEFAULT '{}',
  avg_completion_percent numeric(5,2) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(date)
);

-- 시간대별 집계 (히트맵용)
CREATE TABLE analytics_hourly (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  date date NOT NULL,
  hour smallint NOT NULL CHECK (hour >= 0 AND hour < 24),
  day_of_week smallint NOT NULL CHECK (day_of_week >= 0 AND day_of_week < 7),
  session_count integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(date, hour)
);

-- 사용자 인구통계 스냅샷 (주1회 갱신)
CREATE TABLE analytics_demographics_snapshot (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  snapshot_date date NOT NULL,
  age_distribution jsonb DEFAULT '[]',
  gender_distribution jsonb DEFAULT '[]',
  timezone_distribution jsonb DEFAULT '[]',
  total_users integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(snapshot_date)
);
```

### 배치 처리 방법

#### 방법 A: Supabase pg_cron (추천)
```sql
-- pg_cron 활성화 (Supabase Dashboard → Database → Extensions)
-- 매일 자정(UTC)에 전날 데이터 집계
SELECT cron.schedule(
  'aggregate-daily',
  '5 0 * * *',  -- 매일 00:05 UTC
  $$
  INSERT INTO analytics_daily (date, total_sessions, total_duration_seconds, unique_users, ...)
  SELECT
    (now() - interval '1 day')::date,
    count(*),
    sum(working_duration),
    count(distinct user_id),
    ...
  FROM usage_sessions
  WHERE start_time >= (now() - interval '1 day')::date
    AND start_time < now()::date
  ON CONFLICT (date) DO UPDATE SET
    total_sessions = EXCLUDED.total_sessions,
    ...
  $$
);
```

#### 방법 B: Vercel Cron Job
```json
// vercel.json
{
  "crons": [{
    "path": "/api/cron/aggregate-daily",
    "schedule": "5 0 * * *"
  }]
}
```
- 새 API endpoint `/api/cron/aggregate-daily` 추가
- CRON_SECRET 환경변수로 인증
- Vercel Hobby 플랜: Cron 2개까지 가능

#### 방법 C: Supabase Edge Function
```typescript
// supabase/functions/aggregate-daily/index.ts
Deno.serve(async () => {
  // Supabase client로 집계 쿼리 실행
  // pg_cron 대신 사용 가능 (Supabase Pro 이상)
});
```

### API 변경
```typescript
// 기존: usage_sessions 직접 쿼리 (느림)
const { data } = await supabaseAdmin.from('usage_sessions')
  .select('*').gte('start_time', startDate);

// 변경: analytics_daily 조회 (빠름)
const { data } = await supabaseAdmin.from('analytics_daily')
  .select('*').gte('date', startDate).lte('date', endDate);
```

### 마이그레이션 순서
1. 집계 테이블 생성 (SQL)
2. 과거 데이터 백필 (1회성 스크립트)
3. Cron 배치 설정
4. API 코드 변경 (analytics_daily 조회로 전환)
5. 실시간 쿼리 코드 제거

---

## 4. Phase 4: 고급 분석 (향후)

### 코호트 분석
- 가입 주(cohort)별 리텐션 테이블
- 주간/월간 배치로 코호트 매트릭스 갱신

### 예측 분석
- 이탈 예측 (마지막 세션 이후 7일 경과)
- 사용 패턴 클러스터링

### 실시간 대시보드 (선택)
- Supabase Realtime + WebSocket
- 관리자 대시보드에 실시간 세션 수 표시

---

## 요약

| Phase | 규모 | 방법 | 변경 범위 |
|-------|------|------|-----------|
| 1 (현재) | < 1,000 사용자 | 실시간 쿼리 | 없음 |
| 2 | 1K~5K | 인덱스 추가 | SQL만 |
| 3 | 5K+ | 집계 테이블 + Cron | 테이블 + API + Cron |
| 4 | 10K+ | 코호트/예측 | 추가 테이블 + 로직 |

현재 Phase 1으로 충분하며, 사용자 증가에 따라 Phase 2 → 3 순서로 마이그레이션합니다.
