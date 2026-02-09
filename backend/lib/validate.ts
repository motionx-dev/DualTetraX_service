import { z } from 'zod';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Validate request body against a Zod schema
export function validateBody<T>(req: VercelRequest, res: VercelResponse, schema: z.ZodType<T>): T | null {
  const result = schema.safeParse(req.body);
  if (!result.success) {
    res.status(400).json({ error: 'Validation failed', details: result.error.flatten().fieldErrors });
    return null;
  }
  return result.data;
}

// Validate query parameters against a Zod schema
export function validateQuery<T>(req: VercelRequest, res: VercelResponse, schema: z.ZodType<T>): T | null {
  const result = schema.safeParse(req.query);
  if (!result.success) {
    res.status(400).json({ error: 'Invalid query parameters', details: result.error.flatten().fieldErrors });
    return null;
  }
  return result.data;
}

// -- Device schemas --

export const DeviceRegisterSchema = z.object({
  serial_number: z.string().min(1).max(100),
  model_name: z.string().max(100).optional().default('DualTetraX'),
  firmware_version: z.string().max(50).optional(),
  ble_mac_address: z.string().max(20).optional(),
});

export const DeviceUpdateSchema = z.object({
  nickname: z.string().max(100).optional(),
  firmware_version: z.string().max(50).optional(),
});

export const DeviceTransferSchema = z.object({
  to_email: z.string().email(),
});

// -- Session schemas --

const BatterySampleSchema = z.object({
  elapsed_seconds: z.number().int().min(0),
  voltage_mv: z.number().int().min(0).max(5000),
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

export const SessionUploadSchema = z.object({
  device_id: z.string().uuid(),
  sessions: z.array(SessionItemSchema).min(1).max(100),
});

export const SessionsQuerySchema = z.object({
  device_id: z.string().uuid().optional(),
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional().default(50),
  offset: z.coerce.number().int().min(0).optional().default(0),
});

export const ExportQuerySchema = z.object({
  device_id: z.string().uuid().optional(),
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

// -- Stats schemas --

export const DailyStatsQuerySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  device_id: z.string().uuid().optional(),
});

export const RangeStatsQuerySchema = z.object({
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  device_id: z.string().uuid().optional(),
  group_by: z.enum(['day', 'week', 'month']).optional().default('day'),
});

// -- Profile schemas --

export const ProfileUpdateSchema = z.object({
  name: z.string().max(100).optional(),
  gender: z.enum(['male', 'female', 'other']).optional(),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  timezone: z.string().max(50).optional(),
});

// -- Notification schemas --

export const NotificationSettingsSchema = z.object({
  push_enabled: z.boolean().optional(),
  email_enabled: z.boolean().optional(),
  usage_reminder: z.boolean().optional(),
  reminder_time: z.string().regex(/^\d{2}:\d{2}$/).optional(),
  marketing_enabled: z.boolean().optional(),
});

// -- Skin profile schemas --

export const SkinProfileSchema = z.object({
  skin_type: z.enum(['dry', 'oily', 'combination', 'sensitive', 'normal']).optional().nullable(),
  concerns: z.array(z.string()).optional(),
  memo: z.string().max(500).optional().nullable(),
});

// -- Goal schemas --

export const GoalCreateSchema = z.object({
  goal_type: z.enum(['weekly', 'monthly']),
  target_minutes: z.number().int().min(1),
  start_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  end_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

export const GoalUpdateSchema = z.object({
  target_minutes: z.number().int().min(1).optional(),
  is_active: z.boolean().optional(),
});

// -- Consent schemas --

export const ConsentCreateSchema = z.object({
  consent_type: z.enum(['terms', 'privacy', 'marketing', 'data_collection']),
  consented: z.boolean(),
});

// -- Firmware schemas --

export const FirmwareQuerySchema = z.object({
  model_name: z.string().optional().default('DualTetraX'),
  current_version: z.string().optional(),
});

export const FirmwareCreateSchema = z.object({
  version: z.string().min(1).max(50),
  version_code: z.number().int().min(1),
  changelog: z.string().optional(),
  binary_url: z.string().url().optional(),
  binary_size: z.number().int().optional(),
  binary_checksum: z.string().optional(),
  min_version_code: z.number().int().optional(),
  is_active: z.boolean().optional().default(true),
});

export const RolloutCreateSchema = z.object({
  firmware_version_id: z.string().uuid(),
  target_percentage: z.number().int().min(1).max(100),
  notes: z.string().optional(),
});

export const RolloutUpdateSchema = z.object({
  status: z.enum(['draft', 'active', 'paused', 'completed']).optional(),
  target_percentage: z.number().int().min(1).max(100).optional(),
  notes: z.string().optional(),
});

// -- Announcement schemas --

export const AnnouncementCreateSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  type: z.enum(['notice', 'maintenance', 'update']).optional().default('notice'),
  is_published: z.boolean().optional().default(false),
});

export const AnnouncementUpdateSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().min(1).optional(),
  type: z.enum(['notice', 'maintenance', 'update']).optional(),
  is_published: z.boolean().optional(),
});

// -- Admin query schemas --

export const PaginationQuerySchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
  search: z.string().optional(),
});

export const AdminUserUpdateSchema = z.object({
  role: z.enum(['user', 'admin']).optional(),
  is_active: z.boolean().optional(),
});

export const AdminLogsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
  action: z.string().optional(),
  target_type: z.enum(['user', 'device', 'firmware', 'rollout', 'announcement', 'system']).optional(),
  admin_id: z.string().uuid().optional(),
});

// -- Admin setup/promote schemas --

export const AdminSetupSchema = z.object({
  email: z.string().email(),
  setup_key: z.string().min(1),
});

export const AdminPromoteSchema = z.object({
  user_id: z.string().uuid().optional(),
  email: z.string().email().optional(),
}).refine(data => data.user_id || data.email, {
  message: 'Either user_id or email must be provided',
});

// -- Analytics schemas --

export const AnalyticsQuerySchema = z.object({
  days: z.coerce.number().int().min(1).max(365).optional().default(30),
});

// -- Inferred types --

export type DeviceRegisterInput = z.infer<typeof DeviceRegisterSchema>;
export type DeviceUpdateInput = z.infer<typeof DeviceUpdateSchema>;
export type SessionUploadInput = z.infer<typeof SessionUploadSchema>;
export type SessionsQueryInput = z.infer<typeof SessionsQuerySchema>;
export type DailyStatsQueryInput = z.infer<typeof DailyStatsQuerySchema>;
export type RangeStatsQueryInput = z.infer<typeof RangeStatsQuerySchema>;
export type ProfileUpdateInput = z.infer<typeof ProfileUpdateSchema>;
export type NotificationSettingsInput = z.infer<typeof NotificationSettingsSchema>;
export type SkinProfileInput = z.infer<typeof SkinProfileSchema>;
export type GoalCreateInput = z.infer<typeof GoalCreateSchema>;
export type GoalUpdateInput = z.infer<typeof GoalUpdateSchema>;
export type ConsentCreateInput = z.infer<typeof ConsentCreateSchema>;
export type FirmwareCreateInput = z.infer<typeof FirmwareCreateSchema>;
export type RolloutCreateInput = z.infer<typeof RolloutCreateSchema>;
export type AnnouncementCreateInput = z.infer<typeof AnnouncementCreateSchema>;
export type PaginationQueryInput = z.infer<typeof PaginationQuerySchema>;
