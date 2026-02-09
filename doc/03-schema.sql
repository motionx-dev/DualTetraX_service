-- ============================================================
-- DualTetraX Services - Database Schema v2.0
-- Target: Supabase PostgreSQL
-- Date: 2026-02-08
--
-- 전체 Phase 1 스키마 (기본 6개 + 추가 9개 = 15개 테이블)
-- 실행 방법: Supabase Dashboard → SQL Editor → 붙여넣기 → Run
-- ============================================================

-- ============================================================
-- 0. 기존 테이블 전체 삭제 (CASCADE로 의존 객체 자동 제거)
-- ============================================================
DROP TABLE IF EXISTS admin_logs CASCADE;
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS firmware_update_history CASCADE;
DROP TABLE IF EXISTS firmware_rollouts CASCADE;
DROP TABLE IF EXISTS device_transfers CASCADE;
DROP TABLE IF EXISTS user_goals CASCADE;
DROP TABLE IF EXISTS skin_profiles CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;
DROP TABLE IF EXISTS consent_records CASCADE;
DROP TABLE IF EXISTS battery_samples CASCADE;
DROP TABLE IF EXISTS daily_statistics CASCADE;
DROP TABLE IF EXISTS usage_sessions CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS firmware_versions CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- 이전 버전에서 남아있을 수 있는 테이블도 삭제
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS recommendations CASCADE;
DROP TABLE IF EXISTS device_firmware_status CASCADE;

-- 기존 함수 삭제
DROP FUNCTION IF EXISTS create_profile_for_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS aggregate_daily_stats(UUID, UUID, DATE) CASCADE;

-- ============================================================
-- 기본 테이블 (6개) — 이미 운영 중
-- ============================================================

-- ============================================================
-- 1. profiles (사용자 프로필)
-- ============================================================
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  date_of_birth DATE,
  timezone TEXT NOT NULL DEFAULT 'Asia/Seoul',
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE profiles IS '사용자 프로필. auth.users 회원가입 시 트리거로 자동 생성';

-- ============================================================
-- 2. devices (디바이스)
-- ============================================================
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  serial_number TEXT NOT NULL UNIQUE,
  model_name TEXT NOT NULL DEFAULT 'DualTetraX',
  firmware_version TEXT,
  ble_mac_address TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  registered_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_devices_user_id ON devices(user_id);
CREATE INDEX idx_devices_serial_number ON devices(serial_number);

COMMENT ON TABLE devices IS '등록된 디바이스. serial_number UNIQUE로 중복 등록 방지';

-- ============================================================
-- 3. usage_sessions (사용 세션)
--    id = 앱에서 생성한 UUID (dedup key)
-- ============================================================
CREATE TABLE usage_sessions (
  id UUID PRIMARY KEY,  -- 앱 UUID = 중복 제거 키
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shot_type SMALLINT NOT NULL CHECK (shot_type BETWEEN 0 AND 2),
    -- 0=U-Shot, 1=E-Shot, 2=LED Care
  device_mode SMALLINT NOT NULL,
    -- 0x01=Glow, 0x02=Toneup, 0x03=Renew, 0x04=Volume
    -- 0x11=Clean, 0x12=Firm, 0x13=Line, 0x14=Lift, 0x21=LED
  level SMALLINT NOT NULL CHECK (level BETWEEN 1 AND 3),
  led_pattern SMALLINT,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  working_duration INTEGER NOT NULL DEFAULT 0,  -- 초
  pause_duration INTEGER NOT NULL DEFAULT 0,    -- 초
  pause_count INTEGER NOT NULL DEFAULT 0,
  termination_reason SMALLINT,
    -- 0=timeout8Min, 1=manualPowerOff, 2=batteryDrain, 3=overheat,
    -- 4=chargingStarted, 5=pauseTimeout, 6=modeSwitch, 7=powerOn,
    -- 8=overheatUltrasonic, 9=overheatBody, 255=other
  completion_percent INTEGER NOT NULL DEFAULT 0 CHECK (completion_percent BETWEEN 0 AND 100),
  had_temperature_warning BOOLEAN NOT NULL DEFAULT false,
  had_battery_warning BOOLEAN NOT NULL DEFAULT false,
  battery_start INTEGER,  -- mV
  battery_end INTEGER,    -- mV
  sync_status SMALLINT NOT NULL DEFAULT 2,
    -- 0=notSynced, 1=syncedToApp, 2=syncedToServer, 3=fullySynced
  time_synced BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sessions_device_id ON usage_sessions(device_id);
CREATE INDEX idx_sessions_user_id ON usage_sessions(user_id);
CREATE INDEX idx_sessions_start_time ON usage_sessions(user_id, start_time DESC);
-- Note: Expression index on (start_time::date) removed because TIMESTAMPTZ→date
-- cast is not IMMUTABLE. Use idx_sessions_start_time for date-range queries instead.

COMMENT ON TABLE usage_sessions IS '사용 세션. 앱 UUID를 PK로 사용하여 ON CONFLICT DO NOTHING으로 중복 방지';

-- ============================================================
-- 4. battery_samples (배터리 전압 샘플)
-- ============================================================
CREATE TABLE battery_samples (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id UUID NOT NULL REFERENCES usage_sessions(id) ON DELETE CASCADE,
  elapsed_seconds INTEGER NOT NULL,
  voltage_mv INTEGER NOT NULL
);

CREATE INDEX idx_battery_session ON battery_samples(session_id, elapsed_seconds);

COMMENT ON TABLE battery_samples IS '세션 중 배터리 전압 샘플 (시계열)';

-- ============================================================
-- 5. daily_statistics (일별 집계 통계)
-- ============================================================
CREATE TABLE daily_statistics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  stat_date DATE NOT NULL,
  total_sessions INTEGER NOT NULL DEFAULT 0,
  total_duration INTEGER NOT NULL DEFAULT 0,    -- 초
  ushot_sessions INTEGER NOT NULL DEFAULT 0,
  ushot_duration INTEGER NOT NULL DEFAULT 0,    -- 초
  eshot_sessions INTEGER NOT NULL DEFAULT 0,
  eshot_duration INTEGER NOT NULL DEFAULT 0,    -- 초
  led_sessions INTEGER NOT NULL DEFAULT 0,
  led_duration INTEGER NOT NULL DEFAULT 0,      -- 초
  mode_breakdown JSONB NOT NULL DEFAULT '{}',
    -- { "1": {"sessions": 2, "duration": 960}, "17": {...} }
  level_breakdown JSONB NOT NULL DEFAULT '{}',
    -- { "1": 3, "2": 5, "3": 2 }
  warning_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, device_id, stat_date)
);

CREATE INDEX idx_stats_user_date ON daily_statistics(user_id, stat_date DESC);
CREATE INDEX idx_stats_device_date ON daily_statistics(device_id, stat_date DESC);

COMMENT ON TABLE daily_statistics IS '일별 집계 통계. (user_id, device_id, stat_date) UNIQUE';

-- ============================================================
-- 6. firmware_versions (펌웨어 버전)
-- ============================================================
CREATE TABLE firmware_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL UNIQUE,
  version_code INTEGER NOT NULL UNIQUE,
  changelog TEXT,
  binary_url TEXT,                  -- S3/Storage URL (OTA 바이너리)
  binary_size INTEGER,              -- 바이너리 크기 (bytes)
  binary_checksum TEXT,             -- SHA256 해시
  min_version_code INTEGER,         -- 이 버전으로 업데이트 가능한 최소 버전
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE firmware_versions IS '펌웨어 버전 목록 + OTA 바이너리 메타데이터';

-- ============================================================
-- Phase 1 추가 테이블 (9개)
-- ============================================================

-- ============================================================
-- 7. consent_records (개인정보 동의 이력)
-- FR-PR-001, FR-PR-002
-- ============================================================
CREATE TABLE consent_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL CHECK (consent_type IN ('terms', 'privacy', 'marketing', 'data_collection')),
  consented BOOLEAN NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_consent_user_id ON consent_records(user_id);
CREATE INDEX idx_consent_type ON consent_records(user_id, consent_type, created_at DESC);

COMMENT ON TABLE consent_records IS '개인정보 동의/철회 이력. 각 변경 시 새 행 추가 (이력 추적)';

-- ============================================================
-- 8. notification_settings (알림 설정)
-- FR-UM-006
-- ============================================================
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  email_enabled BOOLEAN NOT NULL DEFAULT true,
  usage_reminder BOOLEAN NOT NULL DEFAULT false,
  reminder_time TIME DEFAULT '21:00',
  marketing_enabled BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE notification_settings IS '사용자별 알림 설정. user_id UNIQUE (1:1)';

-- ============================================================
-- 9. skin_profiles (피부 프로필)
-- FR-PS-006
-- ============================================================
CREATE TABLE skin_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
  skin_type TEXT CHECK (skin_type IN ('dry', 'oily', 'combination', 'sensitive', 'normal')),
  concerns JSONB NOT NULL DEFAULT '[]',
    -- ["wrinkles", "acne", "pigmentation", "pores", "dryness", "elasticity"]
  memo TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE skin_profiles IS '피부 프로필 (피부 타입, 고민). Phase 2 AI 추천의 입력 데이터';

-- ============================================================
-- 10. user_goals (사용 목표)
-- FR-UD-005
-- ============================================================
CREATE TABLE user_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('weekly', 'monthly')),
  target_minutes INTEGER NOT NULL CHECK (target_minutes > 0),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_goals_user_active ON user_goals(user_id, is_active) WHERE is_active = true;

COMMENT ON TABLE user_goals IS '사용 목표 (주간/월간 목표 분). 달성률은 daily_statistics에서 계산';

-- ============================================================
-- 11. device_transfers (디바이스 소유권 이전)
-- FR-DM-002
-- ============================================================
CREATE TABLE device_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  from_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'cancelled')),
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at TIMESTAMPTZ
);

CREATE INDEX idx_transfers_device ON device_transfers(device_id);
CREATE INDEX idx_transfers_to_user ON device_transfers(to_user_id, status);

COMMENT ON TABLE device_transfers IS '디바이스 소유권 이전 요청/승인 이력';

-- ============================================================
-- 12. firmware_rollouts (OTA 펌웨어 롤아웃)
-- FR-AD-009, FR-DM-007
-- ============================================================
CREATE TABLE firmware_rollouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firmware_version_id UUID NOT NULL REFERENCES firmware_versions(id) ON DELETE CASCADE,
  target_percentage INTEGER NOT NULL CHECK (target_percentage BETWEEN 1 AND 100),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed')),
  notes TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_rollouts_status ON firmware_rollouts(status) WHERE status = 'active';

COMMENT ON TABLE firmware_rollouts IS 'OTA 펌웨어 단계별 배포 관리. 대상 비율(%)로 점진적 롤아웃';

-- ============================================================
-- 13. firmware_update_history (펌웨어 업데이트 이력)
-- FR-DM-009
-- ============================================================
CREATE TABLE firmware_update_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  rollout_id UUID REFERENCES firmware_rollouts(id),
  from_version TEXT,
  to_version TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'started' CHECK (status IN ('started', 'downloading', 'installing', 'success', 'failed')),
  error_message TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_fw_history_device ON firmware_update_history(device_id, started_at DESC);

COMMENT ON TABLE firmware_update_history IS '디바이스별 OTA 업데이트 이력. 성공/실패 추적';

-- ============================================================
-- 14. announcements (공지사항)
-- FR-AD-007
-- ============================================================
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'notice' CHECK (type IN ('notice', 'maintenance', 'update')),
  is_published BOOLEAN NOT NULL DEFAULT false,
  published_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_announcements_published ON announcements(published_at DESC) WHERE is_published = true;

COMMENT ON TABLE announcements IS '공지사항. 앱/웹에서 표시. 관리자만 CRUD';

-- ============================================================
-- 15. admin_logs (관리자 감사 로그)
-- FR-AD-006
-- ============================================================
CREATE TABLE admin_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES profiles(id),
  action TEXT NOT NULL,
    -- 'user.update', 'user.deactivate', 'device.delete',
    -- 'firmware.upload', 'rollout.create', 'announcement.publish' 등
  target_type TEXT NOT NULL CHECK (target_type IN ('user', 'device', 'firmware', 'rollout', 'announcement', 'system')),
  target_id UUID,
  details JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_admin_logs_admin ON admin_logs(admin_id, created_at DESC);
CREATE INDEX idx_admin_logs_target ON admin_logs(target_type, target_id);

COMMENT ON TABLE admin_logs IS '관리자 행위 감사 로그. INSERT only (수정/삭제 불가)';

-- ============================================================
-- RLS (Row Level Security)
-- ============================================================

-- profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_update_own"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- devices
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "devices_select_own"
  ON devices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "devices_insert_auth"
  ON devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "devices_update_own"
  ON devices FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- usage_sessions
ALTER TABLE usage_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sessions_select_own"
  ON usage_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "sessions_insert_auth"
  ON usage_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- battery_samples
ALTER TABLE battery_samples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "battery_select_own"
  ON battery_samples FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM usage_sessions s
      WHERE s.id = battery_samples.session_id
      AND s.user_id = auth.uid()
    )
  );

CREATE POLICY "battery_insert_auth"
  ON battery_samples FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usage_sessions s
      WHERE s.id = battery_samples.session_id
      AND s.user_id = auth.uid()
    )
  );

-- daily_statistics (service_role only for write, user can read own)
ALTER TABLE daily_statistics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stats_select_own"
  ON daily_statistics FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT/UPDATE는 service_role_key로만 (RLS bypass)

-- firmware_versions (인증된 사용자 읽기 가능)
ALTER TABLE firmware_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "firmware_select_auth"
  ON firmware_versions FOR SELECT
  USING (auth.role() = 'authenticated');

-- consent_records
ALTER TABLE consent_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "consent_select_own"
  ON consent_records FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "consent_insert_auth"
  ON consent_records FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- notification_settings
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_select_own"
  ON notification_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notif_insert_own"
  ON notification_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notif_update_own"
  ON notification_settings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- skin_profiles
ALTER TABLE skin_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "skin_select_own"
  ON skin_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "skin_insert_own"
  ON skin_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "skin_update_own"
  ON skin_profiles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- user_goals
ALTER TABLE user_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "goals_select_own"
  ON user_goals FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "goals_insert_own"
  ON user_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "goals_update_own"
  ON user_goals FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- device_transfers
ALTER TABLE device_transfers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transfers_select_involved"
  ON device_transfers FOR SELECT
  USING (auth.uid() = from_user_id OR auth.uid() = to_user_id);

CREATE POLICY "transfers_insert_owner"
  ON device_transfers FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);

CREATE POLICY "transfers_update_recipient"
  ON device_transfers FOR UPDATE
  USING (auth.uid() = to_user_id)
  WITH CHECK (auth.uid() = to_user_id);

-- firmware_rollouts (관리자만 — service_role로 접근)
ALTER TABLE firmware_rollouts ENABLE ROW LEVEL SECURITY;

-- 일반 사용자에게는 비공개. service_role_key로만 CRUD.

-- firmware_update_history
ALTER TABLE firmware_update_history ENABLE ROW LEVEL SECURITY;

-- INSERT는 service_role_key로만. 사용자는 자기 디바이스 이력만 조회.
CREATE POLICY "fw_history_select_own_device"
  ON firmware_update_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM devices d
      WHERE d.id = firmware_update_history.device_id
      AND d.user_id = auth.uid()
    )
  );

-- announcements (모든 인증 사용자 읽기 가능)
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "announcements_select_published"
  ON announcements FOR SELECT
  USING (is_published = true AND auth.role() = 'authenticated');

-- INSERT/UPDATE/DELETE는 service_role_key로만 (관리자 API에서 처리)

-- admin_logs (관리자만 — service_role로 접근)
ALTER TABLE admin_logs ENABLE ROW LEVEL SECURITY;

-- 일반 사용자에게는 비공개. service_role_key로만 INSERT/SELECT.

-- ============================================================
-- 트리거 & 함수
-- ============================================================

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_stats_updated_at
  BEFORE UPDATE ON daily_statistics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_notif_updated_at
  BEFORE UPDATE ON notification_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_skin_updated_at
  BEFORE UPDATE ON skin_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_goals_updated_at
  BEFORE UPDATE ON user_goals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_rollouts_updated_at
  BEFORE UPDATE ON firmware_rollouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_announcements_updated_at
  BEFORE UPDATE ON announcements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 회원가입 시 프로필 자동 생성
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER tr_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();

-- 일별 통계 집계 함수
CREATE OR REPLACE FUNCTION aggregate_daily_stats(
  p_user_id UUID,
  p_device_id UUID,
  p_date DATE
)
RETURNS void AS $$
BEGIN
  INSERT INTO daily_statistics (
    user_id, device_id, stat_date,
    total_sessions, total_duration,
    ushot_sessions, ushot_duration,
    eshot_sessions, eshot_duration,
    led_sessions, led_duration,
    mode_breakdown, level_breakdown, warning_count
  )
  SELECT
    p_user_id,
    p_device_id,
    p_date,
    COUNT(*)::INTEGER,
    COALESCE(SUM(working_duration), 0)::INTEGER,
    COUNT(*) FILTER (WHERE shot_type = 0)::INTEGER,
    COALESCE(SUM(working_duration) FILTER (WHERE shot_type = 0), 0)::INTEGER,
    COUNT(*) FILTER (WHERE shot_type = 1)::INTEGER,
    COALESCE(SUM(working_duration) FILTER (WHERE shot_type = 1), 0)::INTEGER,
    COUNT(*) FILTER (WHERE shot_type = 2)::INTEGER,
    COALESCE(SUM(working_duration) FILTER (WHERE shot_type = 2), 0)::INTEGER,
    COALESCE(
      (SELECT jsonb_object_agg(
        device_mode::text,
        jsonb_build_object('sessions', cnt, 'duration', dur)
      )
      FROM (
        SELECT device_mode, COUNT(*) as cnt, COALESCE(SUM(working_duration), 0) as dur
        FROM usage_sessions
        WHERE user_id = p_user_id AND device_id = p_device_id
          AND start_time::date = p_date
        GROUP BY device_mode
      ) sub),
      '{}'::jsonb
    ),
    COALESCE(
      (SELECT jsonb_object_agg(level::text, cnt)
      FROM (
        SELECT level, COUNT(*) as cnt
        FROM usage_sessions
        WHERE user_id = p_user_id AND device_id = p_device_id
          AND start_time::date = p_date
        GROUP BY level
      ) sub),
      '{}'::jsonb
    ),
    (COUNT(*) FILTER (WHERE had_temperature_warning OR had_battery_warning))::INTEGER
  FROM usage_sessions
  WHERE user_id = p_user_id
    AND device_id = p_device_id
    AND start_time::date = p_date
  ON CONFLICT (user_id, device_id, stat_date) DO UPDATE SET
    total_sessions = EXCLUDED.total_sessions,
    total_duration = EXCLUDED.total_duration,
    ushot_sessions = EXCLUDED.ushot_sessions,
    ushot_duration = EXCLUDED.ushot_duration,
    eshot_sessions = EXCLUDED.eshot_sessions,
    eshot_duration = EXCLUDED.eshot_duration,
    led_sessions = EXCLUDED.led_sessions,
    led_duration = EXCLUDED.led_duration,
    mode_breakdown = EXCLUDED.mode_breakdown,
    level_breakdown = EXCLUDED.level_breakdown,
    warning_count = EXCLUDED.warning_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 초기 데이터 (펌웨어 버전)
-- ============================================================
INSERT INTO firmware_versions (version, version_code, changelog, is_active) VALUES
  ('1.0.23-rc1', 10023, 'Initial release candidate', true);

-- ============================================================
-- 완료!
-- 테이블 15개, RLS 정책 22개, 트리거 8개, 함수 3개 생성됨
--
-- 기본 테이블 (6):
--   profiles, devices, usage_sessions, battery_samples,
--   daily_statistics, firmware_versions
--
-- Phase 1 추가 (9):
--   consent_records, notification_settings, skin_profiles,
--   user_goals, device_transfers, firmware_rollouts,
--   firmware_update_history, announcements, admin_logs
-- ============================================================
