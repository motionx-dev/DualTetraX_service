import { supabaseAdmin } from './supabase';

type TargetType = 'user' | 'device' | 'firmware' | 'rollout' | 'announcement' | 'system';

// Insert an audit log entry for admin actions
export async function logAdminAction(
  adminId: string,
  action: string,
  targetType: TargetType,
  targetId: string | null,
  details: Record<string, unknown> | null,
  ipAddress: string | null
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

// Extract client IP from request headers
export function getClientIp(headers: Record<string, string | string[] | undefined>): string | null {
  const forwarded = headers['x-forwarded-for'];
  if (typeof forwarded === 'string') { return forwarded.split(',')[0].trim(); }
  if (Array.isArray(forwarded)) { return forwarded[0]; }
  return null;
}
