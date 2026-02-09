import { createClient, SupabaseClient } from '@supabase/supabase-js';

const SUPABASE_URL = (process.env.SUPABASE_URL || '').trim();
const SUPABASE_SERVICE_ROLE_KEY = (process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();
const SUPABASE_ANON_KEY = (process.env.SUPABASE_ANON_KEY || '').trim();

/**
 * Admin client — bypasses RLS. Use for aggregation, stats writes, etc.
 */
export const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

/**
 * Create a user-scoped client that respects RLS.
 */
export function createUserClient(accessToken: string): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
    auth: { persistSession: false },
  });
}
