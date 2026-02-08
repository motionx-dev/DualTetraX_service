-- ========================================
-- DualTetraX Services - Fresh Database Initialization Script
-- Version: 1.0 | Date: 2026-02-08
-- Purpose: Clean slate initialization (drops all existing objects first)
-- ========================================

-- ========================================
-- STEP 1: DROP ALL EXISTING OBJECTS
-- ========================================

-- Note: CASCADE automatically drops all dependent objects (policies, triggers, indexes, etc.)
-- This is the safest way to ensure a clean slate without errors

-- Drop all functions first (must drop before tables that use them)
DROP FUNCTION IF EXISTS create_profile_for_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS aggregate_daily_stats(DATE) CASCADE;

-- Drop all tables (CASCADE drops policies, triggers, indexes automatically)
-- Order: reverse dependency order for safety
DROP TABLE IF EXISTS public.admin_logs CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.recommendations CASCADE;
DROP TABLE IF EXISTS public.user_goals CASCADE;
DROP TABLE IF EXISTS public.skin_profiles CASCADE;
DROP TABLE IF EXISTS public.firmware_update_history CASCADE;
DROP TABLE IF EXISTS public.device_firmware_status CASCADE;
DROP TABLE IF EXISTS public.firmware_rollouts CASCADE;
DROP TABLE IF EXISTS public.firmware_versions CASCADE;
DROP TABLE IF EXISTS public.daily_statistics CASCADE;
DROP TABLE IF EXISTS public.usage_sessions CASCADE;
DROP TABLE IF EXISTS public.devices CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Success message for cleanup
DO $$ BEGIN
  RAISE NOTICE '🧹 All existing database objects dropped successfully!';
END $$;

-- ========================================
-- STEP 2: CREATE UTILITY FUNCTIONS
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- STEP 3: CREATE ALL TABLES
-- ========================================

-- 1. PROFILES TABLE
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  profile_image_url TEXT,
  phone_number TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  push_notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications_enabled BOOLEAN DEFAULT TRUE,
  marketing_notifications_enabled BOOLEAN DEFAULT FALSE,
  usage_reminder_enabled BOOLEAN DEFAULT TRUE,
  usage_reminder_time TIME DEFAULT '20:00:00',
  is_active BOOLEAN DEFAULT TRUE,
  is_beta_tester BOOLEAN DEFAULT FALSE,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'analyst')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE
);

-- 2. DEVICES TABLE
CREATE TABLE public.devices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  serial_number TEXT UNIQUE NOT NULL,
  model_name TEXT NOT NULL,
  firmware_version TEXT NOT NULL,
  firmware_updated_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  last_connected_at TIMESTAMP WITH TIME ZONE,
  connection_count INT DEFAULT 0,
  ble_mac_address TEXT,
  hardware_revision TEXT,
  manufacturing_date DATE,
  tags TEXT[] DEFAULT '{}',
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT valid_serial_number CHECK (char_length(serial_number) > 0)
);

-- 3. USAGE SESSIONS TABLE
CREATE TABLE public.usage_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  shot_type TEXT NOT NULL CHECK (shot_type IN ('USHOT', 'ESHOT', 'LED')),
  device_mode TEXT NOT NULL,
  level INT NOT NULL CHECK (level BETWEEN 1 AND 3),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  working_duration INT,
  pause_duration INT,
  battery_start INT CHECK (battery_start BETWEEN 0 AND 100),
  battery_end INT CHECK (battery_end BETWEEN 0 AND 100),
  warning_occurred BOOLEAN DEFAULT FALSE,
  warning_types TEXT[],
  local_session_id TEXT,
  synced_from_device_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (device_id, local_session_id)
);

-- 4. DAILY STATISTICS TABLE
CREATE TABLE public.daily_statistics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  stat_date DATE NOT NULL,
  total_sessions INT DEFAULT 0,
  total_working_duration INT DEFAULT 0,
  total_pause_duration INT DEFAULT 0,
  ushot_sessions INT DEFAULT 0,
  ushot_duration INT DEFAULT 0,
  eshot_sessions INT DEFAULT 0,
  eshot_duration INT DEFAULT 0,
  led_sessions INT DEFAULT 0,
  led_duration INT DEFAULT 0,
  mode_breakdown JSONB DEFAULT '{}',
  level_breakdown JSONB DEFAULT '{}',
  warning_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (device_id, stat_date)
);

-- 5. FIRMWARE VERSIONS TABLE
CREATE TABLE public.firmware_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT UNIQUE NOT NULL,
  version_code INT UNIQUE NOT NULL,
  storage_path TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  compatible_models TEXT[] DEFAULT '{"DualTetraX Pro"}',
  min_hardware_revision TEXT,
  changelog TEXT,
  release_notes_url TEXT,
  is_stable BOOLEAN DEFAULT FALSE,
  is_required BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  is_deprecated BOOLEAN DEFAULT FALSE,
  uploaded_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. FIRMWARE ROLLOUTS TABLE
CREATE TABLE public.firmware_rollouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firmware_version_id UUID REFERENCES public.firmware_versions(id) ON DELETE CASCADE NOT NULL,
  strategy TEXT NOT NULL CHECK (strategy IN ('all', 'gradual', 'manual', 'beta')),
  rollout_percentage INT DEFAULT 100 CHECK (rollout_percentage BETWEEN 0 AND 100),
  target_tags TEXT[],
  target_device_ids UUID[],
  start_at TIMESTAMP WITH TIME ZONE,
  end_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  paused BOOLEAN DEFAULT FALSE,
  devices_eligible INT DEFAULT 0,
  devices_updated INT DEFAULT 0,
  devices_failed INT DEFAULT 0,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. DEVICE FIRMWARE STATUS TABLE
CREATE TABLE public.device_firmware_status (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE UNIQUE NOT NULL,
  current_version TEXT NOT NULL,
  current_version_code INT NOT NULL,
  available_version TEXT,
  available_version_code INT,
  update_offered_at TIMESTAMP WITH TIME ZONE,
  last_update_attempt_at TIMESTAMP WITH TIME ZONE,
  last_update_success_at TIMESTAMP WITH TIME ZONE,
  last_update_error TEXT,
  total_updates INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. FIRMWARE UPDATE HISTORY TABLE
CREATE TABLE public.firmware_update_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id UUID REFERENCES public.devices(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  from_version TEXT NOT NULL,
  from_version_code INT NOT NULL,
  to_version TEXT NOT NULL,
  to_version_code INT NOT NULL,
  update_initiated_at TIMESTAMP WITH TIME ZONE NOT NULL,
  update_completed_at TIMESTAMP WITH TIME ZONE,
  status TEXT NOT NULL CHECK (status IN ('initiated', 'downloading', 'transferring', 'installing', 'success', 'failed', 'cancelled')),
  error_code TEXT,
  error_message TEXT,
  retry_count INT DEFAULT 0,
  battery_level_at_start INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. SKIN PROFILES TABLE
CREATE TABLE public.skin_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE UNIQUE NOT NULL,
  skin_type TEXT CHECK (skin_type IN ('dry', 'oily', 'combination', 'sensitive', 'normal')),
  concerns TEXT[] DEFAULT '{}',
  preferred_shot_type TEXT,
  preferred_modes TEXT[],
  preferred_level INT CHECK (preferred_level BETWEEN 1 AND 3),
  weekly_goal_sessions INT DEFAULT 3,
  daily_goal_duration INT DEFAULT 600,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. USER GOALS TABLE
CREATE TABLE public.user_goals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('weekly_sessions', 'daily_duration', 'streak', 'custom')),
  target_value INT NOT NULL,
  current_value INT DEFAULT 0,
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  is_achieved BOOLEAN DEFAULT FALSE,
  achieved_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. RECOMMENDATIONS TABLE
CREATE TABLE public.recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('mode', 'schedule', 'routine', 'content')),
  recommended_value JSONB NOT NULL,
  reason TEXT,
  confidence_score FLOAT CHECK (confidence_score BETWEEN 0 AND 1),
  shown_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  clicked_at TIMESTAMP WITH TIME ZONE,
  dismissed_at TIMESTAMP WITH TIME ZONE,
  followed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. NOTIFICATIONS TABLE
CREATE TABLE public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('push', 'email', 'in_app')),
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  action_url TEXT,
  data JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'read')),
  sent_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. ADMIN LOGS TABLE
CREATE TABLE public.admin_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id UUID,
  old_value JSONB,
  new_value JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- STEP 4: ENABLE ROW LEVEL SECURITY
-- ========================================

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (role = (SELECT role FROM public.profiles WHERE id = auth.uid()));
CREATE POLICY "Admins can view all profiles" ON public.profiles FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Devices
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own devices" ON public.devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own devices" ON public.devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own devices" ON public.devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own devices" ON public.devices FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all devices" ON public.devices FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Usage Sessions
ALTER TABLE public.usage_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own sessions" ON public.usage_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own sessions" ON public.usage_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own sessions" ON public.usage_sessions FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all sessions" ON public.usage_sessions FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Daily Statistics
ALTER TABLE public.daily_statistics ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own statistics" ON public.daily_statistics FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all statistics" ON public.daily_statistics FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Firmware Versions
ALTER TABLE public.firmware_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view active firmware" ON public.firmware_versions FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage firmware" ON public.firmware_versions FOR ALL USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Device Firmware Status
ALTER TABLE public.device_firmware_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their device firmware status" ON public.device_firmware_status FOR SELECT USING (device_id IN (SELECT id FROM devices WHERE user_id = auth.uid()));
CREATE POLICY "Admins can view all firmware status" ON public.device_firmware_status FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Firmware Update History
ALTER TABLE public.firmware_update_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their update history" ON public.firmware_update_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their update history" ON public.firmware_update_history FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can view all update history" ON public.firmware_update_history FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Skin Profiles
ALTER TABLE public.skin_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own skin profile" ON public.skin_profiles FOR ALL USING (auth.uid() = user_id);

-- User Goals
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own goals" ON public.user_goals FOR ALL USING (auth.uid() = user_id);

-- Recommendations
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own recommendations" ON public.recommendations FOR SELECT USING (auth.uid() = user_id);

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Firmware Rollouts (Admin-only table)
ALTER TABLE public.firmware_rollouts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage firmware rollouts" ON public.firmware_rollouts FOR ALL USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- Admin Logs (Admin-only table)
ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view admin logs" ON public.admin_logs FOR SELECT USING (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));
CREATE POLICY "Admins can insert admin logs" ON public.admin_logs FOR INSERT WITH CHECK (auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin'));

-- ========================================
-- STEP 5: CREATE INDEXES
-- ========================================

-- Profiles indexes
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_created_at ON public.profiles(created_at DESC);

-- Devices indexes
CREATE INDEX idx_devices_user_id ON public.devices(user_id);
CREATE INDEX idx_devices_serial_number ON public.devices(serial_number);
CREATE INDEX idx_devices_firmware_version ON public.devices(firmware_version);
CREATE INDEX idx_devices_last_connected_at ON public.devices(last_connected_at DESC);

-- Usage Sessions indexes
CREATE INDEX idx_sessions_user_id_start_time ON public.usage_sessions(user_id, start_time DESC);
CREATE INDEX idx_sessions_device_id_start_time ON public.usage_sessions(device_id, start_time DESC);
CREATE INDEX idx_sessions_start_time ON public.usage_sessions(start_time DESC);

-- Daily Statistics indexes
CREATE INDEX idx_daily_stats_user_date ON public.daily_statistics(user_id, stat_date DESC);
CREATE INDEX idx_daily_stats_device_date ON public.daily_statistics(device_id, stat_date DESC);

-- Firmware Versions indexes
CREATE INDEX idx_firmware_versions_version_code ON public.firmware_versions(version_code DESC);
CREATE INDEX idx_firmware_versions_is_active ON public.firmware_versions(is_active);

-- Firmware Rollouts indexes
CREATE INDEX idx_rollouts_firmware_version ON public.firmware_rollouts(firmware_version_id);
CREATE INDEX idx_rollouts_is_active ON public.firmware_rollouts(is_active);

-- Device Firmware Status indexes
CREATE INDEX idx_device_fw_status_device_id ON public.device_firmware_status(device_id);
CREATE INDEX idx_device_fw_status_current_version ON public.device_firmware_status(current_version_code);

-- Firmware Update History indexes
CREATE INDEX idx_fw_history_device_id ON public.firmware_update_history(device_id, update_initiated_at DESC);
CREATE INDEX idx_fw_history_status ON public.firmware_update_history(status);

-- Skin Profiles indexes
CREATE INDEX idx_skin_profiles_user_id ON public.skin_profiles(user_id);

-- User Goals indexes
CREATE INDEX idx_user_goals_user_id ON public.user_goals(user_id, is_active);

-- Recommendations indexes
CREATE INDEX idx_recommendations_user_id ON public.recommendations(user_id, shown_at DESC);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id, created_at DESC);

-- Admin Logs indexes
CREATE INDEX idx_admin_logs_admin_id ON public.admin_logs(admin_id, created_at DESC);
CREATE INDEX idx_admin_logs_action ON public.admin_logs(action);

-- ========================================
-- STEP 6: CREATE TRIGGERS
-- ========================================

-- Profiles updated_at trigger
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Devices updated_at trigger
CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON public.devices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Daily Statistics updated_at trigger
CREATE TRIGGER update_daily_statistics_updated_at
  BEFORE UPDATE ON public.daily_statistics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Firmware Versions updated_at trigger
CREATE TRIGGER update_firmware_versions_updated_at
  BEFORE UPDATE ON public.firmware_versions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Profile auto-creation on user signup
CREATE OR REPLACE FUNCTION create_profile_for_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email) VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_new_user();

-- ========================================
-- STEP 7: CREATE AGGREGATION FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION aggregate_daily_stats(target_date DATE)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.daily_statistics (
    user_id,
    device_id,
    stat_date,
    total_sessions,
    total_working_duration,
    total_pause_duration,
    ushot_sessions,
    ushot_duration,
    eshot_sessions,
    eshot_duration,
    led_sessions,
    led_duration,
    warning_count
  )
  SELECT
    user_id,
    device_id,
    target_date,
    COUNT(*),
    SUM(COALESCE(working_duration, 0)),
    SUM(COALESCE(pause_duration, 0)),
    SUM(CASE WHEN shot_type = 'USHOT' THEN 1 ELSE 0 END),
    SUM(CASE WHEN shot_type = 'USHOT' THEN COALESCE(working_duration, 0) ELSE 0 END),
    SUM(CASE WHEN shot_type = 'ESHOT' THEN 1 ELSE 0 END),
    SUM(CASE WHEN shot_type = 'ESHOT' THEN COALESCE(working_duration, 0) ELSE 0 END),
    SUM(CASE WHEN shot_type = 'LED' THEN 1 ELSE 0 END),
    SUM(CASE WHEN shot_type = 'LED' THEN COALESCE(working_duration, 0) ELSE 0 END),
    SUM(CASE WHEN warning_occurred THEN 1 ELSE 0 END)
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

-- ========================================
-- FINAL SUCCESS MESSAGE
-- ========================================

DO $$ BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ DualTetraX Database Initialized!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE '📊 Tables Created (13):';
  RAISE NOTICE '   1. ✓ profiles';
  RAISE NOTICE '   2. ✓ devices';
  RAISE NOTICE '   3. ✓ usage_sessions';
  RAISE NOTICE '   4. ✓ daily_statistics';
  RAISE NOTICE '   5. ✓ firmware_versions';
  RAISE NOTICE '   6. ✓ firmware_rollouts';
  RAISE NOTICE '   7. ✓ device_firmware_status';
  RAISE NOTICE '   8. ✓ firmware_update_history';
  RAISE NOTICE '   9. ✓ skin_profiles';
  RAISE NOTICE '  10. ✓ user_goals';
  RAISE NOTICE '  11. ✓ recommendations';
  RAISE NOTICE '  12. ✓ notifications';
  RAISE NOTICE '  13. ✓ admin_logs';
  RAISE NOTICE '';
  RAISE NOTICE '🔒 Security Features:';
  RAISE NOTICE '   ✓ Row Level Security enabled';
  RAISE NOTICE '   ✓ All RLS policies created';
  RAISE NOTICE '   ✓ User isolation enforced';
  RAISE NOTICE '';
  RAISE NOTICE '📈 Performance Features:';
  RAISE NOTICE '   ✓ All indexes created';
  RAISE NOTICE '   ✓ Optimized for queries';
  RAISE NOTICE '';
  RAISE NOTICE '🔄 Automation:';
  RAISE NOTICE '   ✓ Auto-create profile on signup';
  RAISE NOTICE '   ✓ Auto-update timestamps';
  RAISE NOTICE '   ✓ Daily stats aggregation';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '🎉 Database ready for use!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;
