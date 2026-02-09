import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, AuthUser } from './auth';
import { supabaseAdmin } from './supabase';

export interface AdminUser extends AuthUser {
  role: 'admin';
}

// Authenticate and verify admin role
export async function authenticateAdmin(req: VercelRequest, res: VercelResponse): Promise<AdminUser | null> {
  const user = await authenticate(req, res);
  if (!user) { return null; }

  const { data: profile, error } = await supabaseAdmin
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .single();

  if (error || !profile || profile.role !== 'admin') {
    res.status(403).json({ error: 'Admin access required' });
    return null;
  }

  return { ...user, role: 'admin' };
}
