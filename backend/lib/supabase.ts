/**
 * Supabase Client Library
 *
 * Provides server-side Supabase client with service role key
 * for privileged operations (bypassing RLS)
 */

import { createClient } from '@supabase/supabase-js';

// Validate environment variables
if (!process.env.SUPABASE_URL) {
  throw new Error('Missing SUPABASE_URL environment variable');
}

if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('Missing SUPABASE_SERVICE_ROLE_KEY environment variable');
}

/**
 * Supabase client with service role key
 * WARNING: This bypasses Row Level Security (RLS). Use with caution.
 * Only use this for admin operations or when RLS needs to be bypassed.
 */
export const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

/**
 * Create a Supabase client with user's JWT token
 * This respects Row Level Security (RLS) policies
 *
 * @param accessToken - User's JWT access token from Authorization header
 */
export function createSupabaseClient(accessToken: string) {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
    throw new Error('Missing Supabase environment variables');
  }

  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`
        }
      },
      auth: {
        persistSession: false
      }
    }
  );
}

/**
 * Extract JWT token from Authorization header
 *
 * @param authHeader - Authorization header value (e.g., "Bearer token123")
 * @returns JWT token or null
 */
export function extractToken(authHeader: string | null): string | null {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7); // Remove "Bearer " prefix
}
