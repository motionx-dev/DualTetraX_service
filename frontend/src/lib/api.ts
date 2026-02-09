const API_URL = process.env.NEXT_PUBLIC_API_URL || "https://qp-dualtetrax-api.vercel.app";

interface FetchOptions {
  method?: string;
  body?: unknown;
  token?: string;
}

async function apiFetch<T>(path: string, options: FetchOptions = {}): Promise<T> {
  const { method = "GET", body, token } = options;

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const res = await fetch(`${API_URL}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const data = await res.json();
  if (!res.ok) {
    throw new Error(data.error || `API error: ${res.status}`);
  }
  return data as T;
}

// -- API functions --

export async function getDevices(token: string) {
  return apiFetch<{ devices: Device[] }>("/api/devices", { token });
}

export async function registerDevice(token: string, body: RegisterDeviceBody) {
  return apiFetch<{ device: Device }>("/api/devices", { method: "POST", body, token });
}

export async function getSessions(token: string, params?: SessionsParams) {
  const qs = new URLSearchParams();
  if (params?.device_id) qs.set("device_id", params.device_id);
  if (params?.start_date) qs.set("start_date", params.start_date);
  if (params?.end_date) qs.set("end_date", params.end_date);
  if (params?.limit) qs.set("limit", String(params.limit));
  if (params?.offset) qs.set("offset", String(params.offset));
  const q = qs.toString();
  return apiFetch<SessionsResponse>(`/api/sessions${q ? `?${q}` : ""}`, { token });
}

export async function getDailyStats(token: string, params?: { date?: string; device_id?: string }) {
  const qs = new URLSearchParams();
  if (params?.date) qs.set("date", params.date);
  if (params?.device_id) qs.set("device_id", params.device_id);
  const q = qs.toString();
  return apiFetch<DailyStats>(`/api/stats/daily${q ? `?${q}` : ""}`, { token });
}

export async function getRangeStats(token: string, params: RangeStatsParams) {
  const qs = new URLSearchParams({
    start_date: params.start_date,
    end_date: params.end_date,
  });
  if (params.device_id) qs.set("device_id", params.device_id);
  if (params.group_by) qs.set("group_by", params.group_by);
  return apiFetch<RangeStatsResponse>(`/api/stats/range?${qs}`, { token });
}

export async function logout(token: string) {
  return apiFetch<{ message: string }>("/api/auth/logout", { method: "POST", token });
}

// -- Types --

export interface Device {
  id: string;
  user_id: string;
  serial_number: string;
  model_name: string;
  firmware_version: string | null;
  ble_mac_address: string | null;
  is_active: boolean;
  last_synced_at: string | null;
  total_sessions: number;
  registered_at: string;
}

export interface RegisterDeviceBody {
  serial_number: string;
  model_name?: string;
  firmware_version?: string;
  ble_mac_address?: string;
}

export interface Session {
  id: string;
  device_id: string;
  user_id: string;
  shot_type: number;
  device_mode: number;
  level: number;
  start_time: string;
  end_time: string | null;
  working_duration: number;
  pause_duration: number;
  pause_count: number;
  termination_reason: number | null;
  completion_percent: number;
  had_temperature_warning: boolean;
  had_battery_warning: boolean;
  battery_start: number | null;
  battery_end: number | null;
  sync_status: number;
  time_synced: boolean;
  created_at: string;
}

export interface SessionsParams {
  device_id?: string;
  start_date?: string;
  end_date?: string;
  limit?: number;
  offset?: number;
}

export interface SessionsResponse {
  sessions: Session[];
  total: number;
  limit: number;
  offset: number;
}

export interface DailyStats {
  date: string;
  total_sessions: number;
  total_duration: number;
  ushot_sessions: number;
  ushot_duration: number;
  eshot_sessions: number;
  eshot_duration: number;
  led_sessions: number;
  led_duration: number;
  mode_breakdown: Record<string, { sessions: number; duration: number }>;
  level_breakdown: Record<string, number>;
  warning_count: number;
}

export interface RangeStatsParams {
  start_date: string;
  end_date: string;
  device_id?: string;
  group_by?: "day" | "week" | "month";
}

export interface RangeStatsResponse {
  range: { start: string; end: string };
  data: Array<{
    period: string;
    total_sessions: number;
    total_duration: number;
    ushot_sessions: number;
    eshot_sessions: number;
    led_sessions: number;
  }>;
  summary: {
    total_sessions: number;
    total_duration: number;
    avg_sessions_per_day: number;
  };
}

export interface Profile {
  id: string;
  email: string;
  name: string | null;
  gender: string | null;
  date_of_birth: string | null;
  timezone: string;
  role: string;
  created_at: string;
  updated_at: string;
}

export interface NotificationSettings {
  id: string;
  user_id: string;
  push_enabled: boolean;
  email_enabled: boolean;
  usage_reminder: boolean;
  reminder_time: string;
  marketing_enabled: boolean;
}

export interface SkinProfile {
  id: string;
  user_id: string;
  skin_type: string | null;
  concerns: string[];
  memo: string | null;
}

export interface UserGoal {
  id: string;
  user_id: string;
  goal_type: string;
  target_minutes: number;
  start_date: string;
  end_date: string;
  is_active: boolean;
  created_at: string;
}

export interface ConsentRecord {
  id: string;
  user_id: string;
  consent_type: string;
  consented: boolean;
  created_at: string;
}

export interface Announcement {
  id: string;
  title: string;
  content: string;
  type: string;
  is_published: boolean;
  published_at: string | null;
  created_by: string;
  created_at: string;
}

export interface FirmwareVersion {
  id: string;
  version: string;
  version_code: number;
  changelog: string | null;
  binary_url: string | null;
  binary_size: number | null;
  binary_checksum: string | null;
  is_active: boolean;
  created_at: string;
}

export interface Rollout {
  id: string;
  firmware_version_id: string;
  target_percentage: number;
  status: string;
  notes: string | null;
  created_by: string;
  created_at: string;
  firmware_versions?: { version: string; version_code: number };
}

export interface AdminStats {
  total_users: number;
  total_devices: number;
  active_devices: number;
  total_sessions: number;
  today_sessions: number;
}

export interface AdminUser extends Profile {
  devices: { count: number }[];
}

export interface AdminLog {
  id: string;
  admin_id: string;
  action: string;
  target_type: string;
  target_id: string | null;
  details: Record<string, unknown> | null;
  created_at: string;
  profiles: { email: string; name: string | null };
}

// Profile
export async function getProfile(token: string) {
  return apiFetch<{ profile: Profile }>("/api/profile", { token });
}
export async function updateProfile(token: string, body: Partial<Profile>) {
  return apiFetch<{ profile: Profile }>("/api/profile", { method: "PUT", body, token });
}

// Notifications
export async function getNotifications(token: string) {
  return apiFetch<{ settings: NotificationSettings }>("/api/notifications", { token });
}
export async function updateNotifications(token: string, body: Partial<NotificationSettings>) {
  return apiFetch<{ settings: NotificationSettings }>("/api/notifications", { method: "PUT", body, token });
}

// Skin Profile
export async function getSkinProfile(token: string) {
  return apiFetch<{ skin_profile: SkinProfile | null }>("/api/skin-profile", { token });
}
export async function updateSkinProfile(token: string, body: Partial<SkinProfile>) {
  return apiFetch<{ skin_profile: SkinProfile }>("/api/skin-profile", { method: "PUT", body, token });
}

// Goals
export async function getGoals(token: string) {
  return apiFetch<{ goals: UserGoal[] }>("/api/goals", { token });
}
export async function createGoal(token: string, body: { goal_type: string; target_minutes: number; start_date: string; end_date: string }) {
  return apiFetch<{ goal: UserGoal }>("/api/goals", { method: "POST", body, token });
}
export async function updateGoal(token: string, id: string, body: { target_minutes?: number; is_active?: boolean }) {
  return apiFetch<{ goal: UserGoal }>(`/api/goals/${id}`, { method: "PUT", body, token });
}
export async function deleteGoal(token: string, id: string) {
  return apiFetch<{ deleted: boolean }>(`/api/goals/${id}`, { method: "DELETE", token });
}

// Consent
export async function getConsent(token: string) {
  return apiFetch<{ records: ConsentRecord[] }>("/api/consent", { token });
}
export async function addConsent(token: string, body: { consent_type: string; consented: boolean }) {
  return apiFetch<{ record: ConsentRecord }>("/api/consent", { method: "POST", body, token });
}

// Device detail & actions
export async function getDeviceDetail(token: string, id: string) {
  return apiFetch<{ device: Device }>(`/api/devices/${id}`, { token });
}
export async function updateDevice(token: string, id: string, body: { nickname?: string; firmware_version?: string }) {
  return apiFetch<{ device: Device }>(`/api/devices/${id}`, { method: "PUT", body, token });
}
export async function deleteDevice(token: string, id: string) {
  return apiFetch<{ device: Device }>(`/api/devices/${id}`, { method: "DELETE", token });
}
export async function transferDevice(token: string, id: string, toEmail: string) {
  return apiFetch<{ transfer: { id: string; status: string } }>(`/api/devices/${id}/transfer`, { method: "POST", body: { to_email: toEmail }, token });
}

// Session actions
export async function deleteSession(token: string, id: string) {
  return apiFetch<{ deleted: boolean }>(`/api/sessions/${id}`, { method: "DELETE", token });
}
export function getExportUrl(token: string, params?: { device_id?: string; start_date?: string; end_date?: string }) {
  const url = process.env.NEXT_PUBLIC_API_URL || "https://qp-dualtetrax-api.vercel.app";
  const qs = new URLSearchParams();
  if (params?.device_id) { qs.set("device_id", params.device_id); }
  if (params?.start_date) { qs.set("start_date", params.start_date); }
  if (params?.end_date) { qs.set("end_date", params.end_date); }
  return `${url}/api/sessions/export?${qs}`;
}

// Admin APIs
export async function getAdminStats(token: string) {
  return apiFetch<AdminStats>("/api/admin/stats", { token });
}
export async function getAdminUsers(token: string, params?: { page?: number; limit?: number; search?: string }) {
  const qs = new URLSearchParams();
  if (params?.page) { qs.set("page", String(params.page)); }
  if (params?.limit) { qs.set("limit", String(params.limit)); }
  if (params?.search) { qs.set("search", params.search); }
  return apiFetch<{ users: AdminUser[]; total: number; page: number; limit: number }>(`/api/admin/users?${qs}`, { token });
}
export async function getAdminUser(token: string, id: string) {
  return apiFetch<{ profile: Profile; device_count: number; session_count: number }>(`/api/admin/users/${id}`, { token });
}
export async function updateAdminUser(token: string, id: string, body: { role?: string; is_active?: boolean }) {
  return apiFetch<{ profile: Profile }>(`/api/admin/users/${id}`, { method: "PUT", body, token });
}
export async function getAdminDevices(token: string, params?: { page?: number; limit?: number; search?: string }) {
  const qs = new URLSearchParams();
  if (params?.page) { qs.set("page", String(params.page)); }
  if (params?.limit) { qs.set("limit", String(params.limit)); }
  if (params?.search) { qs.set("search", params.search); }
  return apiFetch<{ devices: (Device & { profiles: { email: string; name: string | null } })[]; total: number; page: number; limit: number }>(`/api/admin/devices?${qs}`, { token });
}
export async function getAdminLogs(token: string, params?: { page?: number; limit?: number; action?: string; target_type?: string }) {
  const qs = new URLSearchParams();
  if (params?.page) { qs.set("page", String(params.page)); }
  if (params?.limit) { qs.set("limit", String(params.limit)); }
  if (params?.action) { qs.set("action", params.action); }
  if (params?.target_type) { qs.set("target_type", params.target_type); }
  return apiFetch<{ logs: AdminLog[]; total: number; page: number; limit: number }>(`/api/admin/logs?${qs}`, { token });
}
export async function getAnnouncements(token: string) {
  return apiFetch<{ announcements: Announcement[] }>("/api/admin/announcements", { token });
}
export async function createAnnouncement(token: string, body: { title: string; content: string; type?: string; is_published?: boolean }) {
  return apiFetch<{ announcement: Announcement }>("/api/admin/announcements", { method: "POST", body, token });
}
export async function updateAnnouncement(token: string, id: string, body: Partial<Announcement>) {
  return apiFetch<{ announcement: Announcement }>(`/api/admin/announcements/${id}`, { method: "PUT", body, token });
}
export async function deleteAnnouncement(token: string, id: string) {
  return apiFetch<{ deleted: boolean }>(`/api/admin/announcements/${id}`, { method: "DELETE", token });
}
export async function getAdminFirmware(token: string) {
  return apiFetch<{ firmware_versions: FirmwareVersion[] }>("/api/admin/firmware", { token });
}
export async function createFirmware(token: string, body: { version: string; version_code: number; changelog?: string; binary_url?: string; binary_size?: number; binary_checksum?: string; is_active?: boolean }) {
  return apiFetch<{ firmware: FirmwareVersion }>("/api/admin/firmware", { method: "POST", body, token });
}
export async function getRollouts(token: string) {
  return apiFetch<{ rollouts: Rollout[] }>("/api/admin/firmware/rollouts", { token });
}
export async function createRollout(token: string, body: { firmware_version_id: string; target_percentage: number; notes?: string }) {
  return apiFetch<{ rollout: Rollout }>("/api/admin/firmware/rollouts", { method: "POST", body, token });
}
export async function updateRollout(token: string, id: string, body: { status?: string; target_percentage?: number; notes?: string }) {
  return apiFetch<{ rollout: Rollout }>(`/api/admin/firmware/rollouts/${id}`, { method: "PUT", body, token });
}

// Firmware upload
export async function getFirmwareUploadUrl(token: string, filename: string) {
  return apiFetch<{ signed_url: string; token: string; path: string }>("/api/admin/firmware/upload", {
    method: "POST",
    body: { filename },
    token,
  });
}

export async function getFirmwareDownloadUrl(token: string, path: string) {
  return apiFetch<{ download_url: string }>(`/api/admin/firmware/upload?path=${encodeURIComponent(path)}`, { token });
}

export async function computeSha256(file: File): Promise<string> {
  const buffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest("SHA-256", buffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Analytics types
export interface AnalyticsOverview {
  total_users: number;
  active_users_30d: number;
  new_users_7d: number;
  total_devices: number;
  active_devices: number;
  new_devices_7d: number;
  total_sessions: number;
  today_sessions: number;
  sessions_7d: number;
  avg_sessions_per_day_7d: number;
  avg_duration_seconds: number;
  avg_completion_percent: number;
}

export interface UsageTrend {
  date: string;
  sessions: number;
  avg_duration: number;
  total_duration: number;
}

export interface FeatureUsageItem {
  name: string;
  count: number;
  total_duration: number;
  percentage: number;
}

export interface DemographicsData {
  age_distribution: Array<{ group: string; count: number; percentage: number }>;
  gender_distribution: Array<{ gender: string; count: number; percentage: number }>;
  timezone_distribution: Array<{ timezone: string; count: number }>;
}

export interface HeatmapCell {
  day: number;
  hour: number;
  count: number;
}

export interface TerminationData {
  reasons: Array<{ reason: number; name: string; count: number; percentage: number }>;
  avg_completion_percent: number;
  total_sessions: number;
}

export interface FirmwareDistItem {
  version: string;
  count: number;
  percentage: number;
}

// Analytics API functions
export async function getAnalyticsOverview(token: string) {
  return apiFetch<AnalyticsOverview>("/api/admin/analytics/overview", { token });
}
export async function getUsageTrends(token: string, days = 30) {
  return apiFetch<{ trends: UsageTrend[] }>(`/api/admin/analytics/usage-trends?days=${days}`, { token });
}
export async function getFeatureUsage(token: string, days = 30) {
  return apiFetch<{ shot_types: FeatureUsageItem[]; modes: FeatureUsageItem[] }>(`/api/admin/analytics/feature-usage?days=${days}`, { token });
}
export async function getDemographics(token: string) {
  return apiFetch<DemographicsData>("/api/admin/analytics/demographics", { token });
}
export async function getHeatmap(token: string, days = 30) {
  return apiFetch<{ heatmap: HeatmapCell[] }>(`/api/admin/analytics/heatmap?days=${days}`, { token });
}
export async function getTermination(token: string, days = 30) {
  return apiFetch<TerminationData>(`/api/admin/analytics/termination?days=${days}`, { token });
}
export async function getFirmwareDist(token: string) {
  return apiFetch<{ firmware: FirmwareDistItem[]; total_devices: number }>("/api/admin/analytics/firmware-dist", { token });
}
