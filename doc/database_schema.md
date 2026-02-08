# DualTetraX Services - Database Schema

**Version**: 1.0
**Date**: 2026-02-08
**Database**: PostgreSQL 15+ (Supabase)

---

## 1. Schema Overview

```
auth.users (Supabase built-in)
  ↓
public.profiles (1:1 with auth.users)
  ↓
public.devices (1:N with profiles)
  ├─ public.usage_sessions (1:N with devices)
  ├─ public.daily_statistics (1:N with devices, aggregated)
  └─ public.device_firmware_status (1:1 with devices)

public.firmware_versions
  ├─ public.firmware_rollouts (1:N)
  └─ public.firmware_update_history (N:N with devices)

public.skin_profiles (1:1 with profiles)
public.user_goals (1:N with profiles)
public.recommendations (N:N with profiles)
public.notifications (1:N with profiles)
public.admin_logs (audit trail)
```

---

## 2. Core Tables

### 2.1 auth.users (Supabase Built-in)

**Purpose**: Supabase의 내장 인증 테이블

```sql
-- This is managed by Supabase Auth, not created manually
-- Columns (simplified):
-- id UUID PRIMARY KEY
-- email TEXT UNIQUE
-- encrypted_password TEXT
-- email_confirmed_at TIMESTAMP
-- created_at TIMESTAMP
-- updated_at TIMESTAMP
```

**Note**: 이 테이블은 직접 수정하지 않음. Supabase Auth API 사용.

---

### 2.2 public.profiles

**Purpose**: 사용자 프로필 정보 (auth.users의 확장)

```sql
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  profile_image_url TEXT,
  phone_number TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),

  -- Notification preferences
  push_notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications_enabled BOOLEAN DEFAULT TRUE,
  marketing_notifications_enabled BOOLEAN DEFAULT FALSE,
  usage_reminder_enabled BOOLEAN DEFAULT TRUE,
  usage_reminder_time TIME DEFAULT '20:00:00', -- 8 PM default

  -- Account status
  is_active BOOLEAN DEFAULT TRUE,
  is_beta_tester BOOLEAN DEFAULT FALSE,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'analyst')),

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE
);

-- Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    -- Prevent role escalation: role must remain unchanged
    role = (SELECT role FROM public.profiles WHERE id = auth.uid())
  );

CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at DESC);

-- Trigger: Auto-update updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Create profile on user signup
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();
```

---

### 2.3 public.devices

**Purpose**: 디바이스 등록 및 관리

```sql
CREATE TABLE public.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Device identification
  serial_number TEXT UNIQUE NOT NULL,
  model_name TEXT NOT NULL, -- 'DualTetraX Pro', 'DualTetraX Lite', etc.

  -- Firmware info
  firmware_version TEXT NOT NULL, -- e.g., '1.0.23'
  firmware_updated_at TIMESTAMP WITH TIME ZONE,

  -- Device status
  is_active BOOLEAN DEFAULT TRUE,
  last_connected_at TIMESTAMP WITH TIME ZONE,
  connection_count INT DEFAULT 0,

  -- Device metadata
  ble_mac_address TEXT,
  hardware_revision TEXT,
  manufacturing_date DATE,

  -- Tags for grouping (e.g., 'beta', 'vip')
  tags TEXT[] DEFAULT '{}',

  -- Timestamps
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT valid_serial_number CHECK (char_length(serial_number) > 0)
);

-- Row Level Security
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own devices"
  ON public.devices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own devices"
  ON public.devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices"
  ON public.devices FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own devices"
  ON public.devices FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all devices"
  ON public.devices FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_devices_user_id ON public.devices(user_id);
CREATE INDEX idx_devices_serial_number ON public.devices(serial_number);
CREATE INDEX idx_devices_firmware_version ON public.devices(firmware_version);
CREATE INDEX idx_devices_last_connected_at ON public.devices(last_connected_at DESC);
CREATE INDEX idx_devices_tags ON public.devices USING GIN(tags);

-- Full-text search on serial number
CREATE INDEX idx_devices_serial_search ON public.devices USING GIN(to_tsvector('english', serial_number));

-- Trigger: Auto-update updated_at
CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON public.devices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

### 2.4 public.usage_sessions

**Purpose**: 디바이스 사용 세션 기록

```sql
CREATE TABLE public.usage_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Session data
  shot_type TEXT NOT NULL CHECK (shot_type IN ('USHOT', 'ESHOT', 'LED')),
  device_mode TEXT NOT NULL, -- 'GLOW', 'TONEUP', 'RENEW', 'CLEAN', 'FIRM', 'LINE', 'LIFT'
  level INT NOT NULL CHECK (level BETWEEN 1 AND 3),

  -- Timing
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  working_duration INT, -- seconds
  pause_duration INT,   -- seconds

  -- Battery status
  battery_start INT CHECK (battery_start BETWEEN 0 AND 100),
  battery_end INT CHECK (battery_end BETWEEN 0 AND 100),

  -- Warning flags
  warning_occurred BOOLEAN DEFAULT FALSE,
  warning_types TEXT[], -- ['TEMP_HIGH', 'BATTERY_LOW', etc.]

  -- Metadata
  local_session_id TEXT, -- Client-side session ID (for deduplication)
  synced_from_device_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Unique constraint to prevent duplicate uploads
  UNIQUE (device_id, local_session_id)
);

-- Row Level Security
ALTER TABLE public.usage_sessions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own sessions"
  ON public.usage_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions"
  ON public.usage_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions"
  ON public.usage_sessions FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all sessions"
  ON public.usage_sessions FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_sessions_user_id_start_time ON public.usage_sessions(user_id, start_time DESC);
CREATE INDEX idx_sessions_device_id_start_time ON public.usage_sessions(device_id, start_time DESC);
CREATE INDEX idx_sessions_start_time ON public.usage_sessions(start_time DESC);
CREATE INDEX idx_sessions_shot_type ON public.usage_sessions(shot_type);
CREATE INDEX idx_sessions_device_mode ON public.usage_sessions(device_mode);
CREATE INDEX idx_sessions_created_at ON public.usage_sessions(created_at DESC);

-- Composite index for analytics
CREATE INDEX idx_sessions_user_shot_mode ON public.usage_sessions(user_id, shot_type, device_mode);
```

---

### 2.5 public.daily_statistics

**Purpose**: 일별 사용 통계 (집계 테이블)

```sql
CREATE TABLE public.daily_statistics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  stat_date DATE NOT NULL,

  -- Overall stats
  total_sessions INT DEFAULT 0,
  total_working_duration INT DEFAULT 0, -- seconds
  total_pause_duration INT DEFAULT 0,   -- seconds

  -- Shot type breakdown
  ushot_sessions INT DEFAULT 0,
  ushot_duration INT DEFAULT 0,
  eshot_sessions INT DEFAULT 0,
  eshot_duration INT DEFAULT 0,
  led_sessions INT DEFAULT 0,
  led_duration INT DEFAULT 0,

  -- Mode breakdown (JSONB for flexibility)
  mode_breakdown JSONB DEFAULT '{}', -- { "GLOW": 120, "TONEUP": 300, ... }
  level_breakdown JSONB DEFAULT '{}', -- { "1": 5, "2": 3, "3": 2 }

  -- Warnings
  warning_count INT DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE (device_id, stat_date)
);

-- Row Level Security
ALTER TABLE public.daily_statistics ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own statistics"
  ON public.daily_statistics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all statistics"
  ON public.daily_statistics FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_daily_stats_user_date ON public.daily_statistics(user_id, stat_date DESC);
CREATE INDEX idx_daily_stats_device_date ON public.daily_statistics(device_id, stat_date DESC);
CREATE INDEX idx_daily_stats_date ON public.daily_statistics(stat_date DESC);

-- Trigger: Auto-update updated_at
CREATE TRIGGER update_daily_statistics_updated_at
  BEFORE UPDATE ON public.daily_statistics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to aggregate sessions into daily stats
CREATE OR REPLACE FUNCTION aggregate_daily_stats(target_date DATE)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.daily_statistics (
    user_id, device_id, stat_date,
    total_sessions, total_working_duration, total_pause_duration,
    ushot_sessions, ushot_duration,
    eshot_sessions, eshot_duration,
    led_sessions, led_duration,
    warning_count
  )
  SELECT
    user_id,
    device_id,
    target_date,
    COUNT(*) AS total_sessions,
    SUM(COALESCE(working_duration, 0)) AS total_working_duration,
    SUM(COALESCE(pause_duration, 0)) AS total_pause_duration,
    SUM(CASE WHEN shot_type = 'USHOT' THEN 1 ELSE 0 END) AS ushot_sessions,
    SUM(CASE WHEN shot_type = 'USHOT' THEN COALESCE(working_duration, 0) ELSE 0 END) AS ushot_duration,
    SUM(CASE WHEN shot_type = 'ESHOT' THEN 1 ELSE 0 END) AS eshot_sessions,
    SUM(CASE WHEN shot_type = 'ESHOT' THEN COALESCE(working_duration, 0) ELSE 0 END) AS eshot_duration,
    SUM(CASE WHEN shot_type = 'LED' THEN 1 ELSE 0 END) AS led_sessions,
    SUM(CASE WHEN shot_type = 'LED' THEN COALESCE(working_duration, 0) ELSE 0 END) AS led_duration,
    SUM(CASE WHEN warning_occurred THEN 1 ELSE 0 END) AS warning_count
  FROM public.usage_sessions
  WHERE DATE(start_time) = target_date
  GROUP BY user_id, device_id
  ON CONFLICT (device_id, stat_date)
  DO UPDATE SET
    total_sessions = EXCLUDED.total_sessions,
    total_working_duration = EXCLUDED.total_working_duration,
    total_pause_duration = EXCLUDED.total_pause_duration,
    ushot_sessions = EXCLUDED.ushot_sessions,
    ushot_duration = EXCLUDED.ushot_duration,
    eshot_sessions = EXCLUDED.eshot_sessions,
    eshot_duration = EXCLUDED.eshot_duration,
    led_sessions = EXCLUDED.led_sessions,
    led_duration = EXCLUDED.led_duration,
    warning_count = EXCLUDED.warning_count,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
```

---

## 3. OTA Firmware Management Tables

### 3.1 public.firmware_versions

**Purpose**: 펌웨어 버전 관리

```sql
CREATE TABLE public.firmware_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- Version info
  version TEXT UNIQUE NOT NULL, -- e.g., '1.0.24'
  version_code INT UNIQUE NOT NULL, -- Integer for comparison (10024)

  -- File info
  storage_path TEXT NOT NULL, -- Path in Supabase Storage
  file_size_bytes BIGINT NOT NULL,
  checksum_sha256 TEXT NOT NULL, -- For integrity verification

  -- Compatibility
  compatible_models TEXT[] DEFAULT '{"DualTetraX Pro", "DualTetraX Lite"}',
  min_hardware_revision TEXT,

  -- Release info
  changelog TEXT, -- Markdown format
  release_notes_url TEXT,
  is_stable BOOLEAN DEFAULT FALSE, -- Beta vs stable release
  is_required BOOLEAN DEFAULT FALSE, -- Force update if true

  -- Status
  is_active BOOLEAN DEFAULT TRUE, -- Can be offered to users
  is_deprecated BOOLEAN DEFAULT FALSE, -- Old version, no longer recommended

  -- Metadata
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  CONSTRAINT version_format CHECK (version ~ '^\d+\.\d+\.\d+$')
);

-- Indexes
CREATE INDEX idx_firmware_versions_version_code ON public.firmware_versions(version_code DESC);
CREATE INDEX idx_firmware_versions_is_active ON public.firmware_versions(is_active);
CREATE INDEX idx_firmware_versions_created_at ON public.firmware_versions(created_at DESC);

-- Trigger: Auto-update updated_at
CREATE TRIGGER update_firmware_versions_updated_at
  BEFORE UPDATE ON public.firmware_versions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

### 3.2 public.firmware_rollouts

**Purpose**: 펌웨어 배포 전략 관리

```sql
CREATE TABLE public.firmware_rollouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firmware_version_id UUID REFERENCES public.firmware_versions(id) ON DELETE CASCADE NOT NULL,

  -- Rollout strategy
  strategy TEXT NOT NULL CHECK (strategy IN ('all', 'gradual', 'manual', 'beta')),

  -- Gradual rollout config
  rollout_percentage INT DEFAULT 100 CHECK (rollout_percentage BETWEEN 0 AND 100),
  -- 10 = 10% of users, 50 = 50%, 100 = all users

  -- Target selection
  target_tags TEXT[], -- e.g., ['beta', 'vip']
  target_device_ids UUID[], -- Specific devices (for manual/beta)

  -- Schedule
  start_at TIMESTAMP WITH TIME ZONE,
  end_at TIMESTAMP WITH TIME ZONE,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  paused BOOLEAN DEFAULT FALSE,

  -- Stats
  devices_eligible INT DEFAULT 0,
  devices_updated INT DEFAULT 0,
  devices_failed INT DEFAULT 0,

  -- Metadata
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_rollouts_firmware_version ON public.firmware_rollouts(firmware_version_id);
CREATE INDEX idx_rollouts_is_active ON public.firmware_rollouts(is_active);
CREATE INDEX idx_rollouts_created_at ON public.firmware_rollouts(created_at DESC);
```

---

### 3.3 public.device_firmware_status

**Purpose**: 디바이스별 현재 펌웨어 상태

```sql
CREATE TABLE public.device_firmware_status (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE UNIQUE NOT NULL,

  -- Current firmware
  current_version TEXT NOT NULL,
  current_version_code INT NOT NULL,

  -- Available update (if any)
  available_version TEXT,
  available_version_code INT,
  update_offered_at TIMESTAMP WITH TIME ZONE,

  -- Last update attempt
  last_update_attempt_at TIMESTAMP WITH TIME ZONE,
  last_update_success_at TIMESTAMP WITH TIME ZONE,
  last_update_error TEXT,

  -- Update history count
  total_updates INT DEFAULT 0,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.device_firmware_status ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own device firmware status"
  ON public.device_firmware_status FOR SELECT
  USING (
    device_id IN (SELECT id FROM devices WHERE user_id = auth.uid())
  );

CREATE POLICY "Admins can view all firmware status"
  ON public.device_firmware_status FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_device_fw_status_device_id ON public.device_firmware_status(device_id);
CREATE INDEX idx_device_fw_status_current_version ON public.device_firmware_status(current_version_code);
```

---

### 3.4 public.firmware_update_history

**Purpose**: 개인별 펌웨어 업데이트 이력 (요구사항 반영)

```sql
CREATE TABLE public.firmware_update_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Version info
  from_version TEXT NOT NULL,
  from_version_code INT NOT NULL,
  to_version TEXT NOT NULL,
  to_version_code INT NOT NULL,

  -- Update process
  update_initiated_at TIMESTAMP WITH TIME ZONE NOT NULL,
  update_completed_at TIMESTAMP WITH TIME ZONE,

  -- Status
  status TEXT NOT NULL CHECK (status IN ('initiated', 'downloading', 'transferring', 'installing', 'success', 'failed', 'cancelled')),

  -- Error handling
  error_code TEXT,
  error_message TEXT,
  retry_count INT DEFAULT 0,

  -- Download info
  firmware_downloaded_at TIMESTAMP WITH TIME ZONE,
  firmware_size_bytes BIGINT,
  download_duration_ms INT,

  -- BLE transfer info (NEW - 모바일 앱에서 BLE로 전송)
  ble_transfer_started_at TIMESTAMP WITH TIME ZONE,
  ble_transfer_completed_at TIMESTAMP WITH TIME ZONE,
  ble_transfer_duration_ms INT,
  ble_transfer_speed_kbps FLOAT, -- KB per second

  -- Device info at update time
  battery_level_at_start INT,
  signal_strength_at_start INT, -- BLE RSSI

  -- Rollback info
  rollback_performed BOOLEAN DEFAULT FALSE,
  rollback_reason TEXT,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.firmware_update_history ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own update history"
  ON public.firmware_update_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own update history"
  ON public.firmware_update_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all update history"
  ON public.firmware_update_history FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
  );

-- Indexes
CREATE INDEX idx_fw_history_device_id ON public.firmware_update_history(device_id, update_initiated_at DESC);
CREATE INDEX idx_fw_history_user_id ON public.firmware_update_history(user_id, update_initiated_at DESC);
CREATE INDEX idx_fw_history_status ON public.firmware_update_history(status);
CREATE INDEX idx_fw_history_to_version ON public.firmware_update_history(to_version_code);
CREATE INDEX idx_fw_history_created_at ON public.firmware_update_history(created_at DESC);
```

---

## 4. Personalization Tables

### 4.1 public.skin_profiles

**Purpose**: 사용자 피부 프로필 (개인화 서비스용)

```sql
CREATE TABLE public.skin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,

  -- Skin type
  skin_type TEXT CHECK (skin_type IN ('dry', 'oily', 'combination', 'sensitive', 'normal')),

  -- Skin concerns (multiple selection)
  concerns TEXT[] DEFAULT '{}',
  -- Options: 'wrinkles', 'elasticity', 'pores', 'pigmentation', 'acne', 'redness', 'dullness'

  -- User preferences
  preferred_shot_type TEXT, -- 'USHOT', 'ESHOT', 'LED'
  preferred_modes TEXT[],
  preferred_level INT CHECK (preferred_level BETWEEN 1 AND 3),

  -- Usage goals
  weekly_goal_sessions INT DEFAULT 3,
  daily_goal_duration INT DEFAULT 600, -- seconds (10 minutes)

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.skin_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own skin profile"
  ON public.skin_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own skin profile"
  ON public.skin_profiles FOR ALL
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_skin_profiles_user_id ON public.skin_profiles(user_id);
CREATE INDEX idx_skin_profiles_skin_type ON public.skin_profiles(skin_type);
```

---

### 4.2 public.user_goals

**Purpose**: 사용자 목표 설정 및 추적

```sql
CREATE TABLE public.user_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Goal details
  goal_type TEXT NOT NULL CHECK (goal_type IN ('weekly_sessions', 'daily_duration', 'streak', 'custom')),
  target_value INT NOT NULL, -- e.g., 3 sessions, 600 seconds
  current_value INT DEFAULT 0,

  -- Period
  start_date DATE NOT NULL,
  end_date DATE,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_achieved BOOLEAN DEFAULT FALSE,
  achieved_at TIMESTAMP WITH TIME ZONE,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage their own goals"
  ON public.user_goals FOR ALL
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_user_goals_user_id ON public.user_goals(user_id, is_active);
CREATE INDEX idx_user_goals_start_date ON public.user_goals(start_date DESC);
```

---

### 4.3 public.recommendations

**Purpose**: AI 기반 추천 이력

```sql
CREATE TABLE public.recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Recommendation details
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('mode', 'schedule', 'routine', 'content')),
  recommended_value JSONB NOT NULL, -- Flexible: { "mode": "GLOW", "level": 2 }
  reason TEXT, -- Human-readable explanation
  confidence_score FLOAT CHECK (confidence_score BETWEEN 0 AND 1),

  -- User interaction
  shown_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  clicked_at TIMESTAMP WITH TIME ZONE,
  dismissed_at TIMESTAMP WITH TIME ZONE,
  followed BOOLEAN DEFAULT FALSE,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own recommendations"
  ON public.recommendations FOR SELECT
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_recommendations_user_id ON public.recommendations(user_id, shown_at DESC);
CREATE INDEX idx_recommendations_type ON public.recommendations(recommendation_type);
```

---

## 5. Notification Tables

### 5.1 public.notifications

**Purpose**: 알림 큐 및 이력

```sql
CREATE TABLE public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,

  -- Notification details
  notification_type TEXT NOT NULL CHECK (notification_type IN ('push', 'email', 'in_app')),
  category TEXT NOT NULL, -- 'device_alert', 'firmware_update', 'usage_reminder', 'goal_achieved'

  -- Content
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_url TEXT,
  data JSONB, -- Additional data

  -- Delivery status
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'read')),
  sent_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,

  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" -- For marking as read
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_status ON public.notifications(status);
CREATE INDEX idx_notifications_sent_at ON public.notifications(sent_at DESC);
```

---

## 6. Admin & Analytics Tables

### 6.1 public.admin_logs

**Purpose**: 관리자 활동 감사 로그

```sql
CREATE TABLE public.admin_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- Action details
  action TEXT NOT NULL, -- 'user_created', 'device_deleted', 'firmware_uploaded', etc.
  resource_type TEXT, -- 'user', 'device', 'firmware', etc.
  resource_id UUID,

  -- Changes
  old_value JSONB,
  new_value JSONB,

  -- Metadata
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_admin_logs_admin_id ON public.admin_logs(admin_id, created_at DESC);
CREATE INDEX idx_admin_logs_action ON public.admin_logs(action);
CREATE INDEX idx_admin_logs_created_at ON public.admin_logs(created_at DESC);
```

---

## 7. Utility Functions

### 7.1 update_updated_at_column()

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 7.2 get_user_statistics()

```sql
CREATE OR REPLACE FUNCTION get_user_statistics(
  p_user_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_sessions BIGINT,
  total_duration INT,
  ushot_duration INT,
  eshot_duration INT,
  led_duration INT,
  avg_session_duration FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_sessions,
    SUM(COALESCE(working_duration, 0))::INT AS total_duration,
    SUM(CASE WHEN shot_type = 'USHOT' THEN COALESCE(working_duration, 0) ELSE 0 END)::INT AS ushot_duration,
    SUM(CASE WHEN shot_type = 'ESHOT' THEN COALESCE(working_duration, 0) ELSE 0 END)::INT AS eshot_duration,
    SUM(CASE WHEN shot_type = 'LED' THEN COALESCE(working_duration, 0) ELSE 0 END)::INT AS led_duration,
    AVG(COALESCE(working_duration, 0))::FLOAT AS avg_session_duration
  FROM public.usage_sessions
  WHERE user_id = p_user_id
    AND start_time >= p_start_date::TIMESTAMP
    AND start_time < (p_end_date + INTERVAL '1 day')::TIMESTAMP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 8. Indexes Summary

### 8.1 Critical Indexes (High Priority)

```sql
-- User queries
CREATE INDEX idx_devices_user_id ON public.devices(user_id);
CREATE INDEX idx_sessions_user_id_start_time ON public.usage_sessions(user_id, start_time DESC);
CREATE INDEX idx_daily_stats_user_date ON public.daily_statistics(user_id, stat_date DESC);

-- Admin queries
CREATE INDEX idx_devices_serial_number ON public.devices(serial_number);
CREATE INDEX idx_devices_firmware_version ON public.devices(firmware_version);
CREATE INDEX idx_sessions_created_at ON public.usage_sessions(created_at DESC);

-- OTA queries
CREATE INDEX idx_device_fw_status_current_version ON public.device_firmware_status(current_version_code);
CREATE INDEX idx_fw_history_device_id ON public.firmware_update_history(device_id, update_initiated_at DESC);
```

### 8.2 Full-Text Search Indexes

```sql
-- Device search
CREATE INDEX idx_devices_serial_search ON public.devices USING GIN(to_tsvector('english', serial_number));

-- User search
CREATE INDEX idx_profiles_email_search ON public.profiles USING GIN(to_tsvector('english', email));
```

---

## 9. Sample Data

### 9.1 Insert Sample Firmware Version

```sql
INSERT INTO public.firmware_versions (
  version, version_code, storage_path, file_size_bytes, checksum_sha256,
  compatible_models, changelog, is_stable, is_required
) VALUES (
  '1.0.24',
  10024,
  'firmware-binaries/dualtetra-esp32-v1.0.24.bin',
  1400000,
  'abc123def456...',
  '{"DualTetraX Pro", "DualTetraX Lite"}',
  '## What''s New\n- Bug fixes\n- Performance improvements',
  TRUE,
  FALSE
);
```

---

## 10. Maintenance

### 10.1 Daily Aggregation (Cron Job)

```sql
-- Run this daily via Vercel Cron
SELECT aggregate_daily_stats(CURRENT_DATE - INTERVAL '1 day');
```

### 10.2 Vacuum & Analyze (Weekly)

```sql
VACUUM ANALYZE public.usage_sessions;
VACUUM ANALYZE public.daily_statistics;
```

---

**Document End**
