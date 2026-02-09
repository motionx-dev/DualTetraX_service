import type { VercelRequest, VercelResponse } from '@vercel/node';
import { createHash } from 'crypto';
import { supabaseAdmin } from './supabase';
import { isTokenBlacklisted } from './redis';

export interface AuthUser {
  id: string;
  email: string;
}

/**
 * Extract Bearer token from Authorization header.
 */
export function extractToken(req: VercelRequest): string | null {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

/**
 * Hash a token for Redis storage (don't store raw JWTs).
 */
export function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex').substring(0, 32);
}

/**
 * Decode JWT payload without verification (for reading exp claim).
 */
export function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = Buffer.from(parts[1], 'base64url').toString('utf8');
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

/**
 * Authenticate a request. Returns the user or sends a 401 response.
 */
export async function authenticate(
  req: VercelRequest,
  res: VercelResponse
): Promise<AuthUser | null> {
  const token = extractToken(req);
  if (!token) {
    res.status(401).json({ error: 'Missing authorization token' });
    return null;
  }

  // Check Redis blacklist
  const tokenHash = hashToken(token);
  if (await isTokenBlacklisted(tokenHash)) {
    res.status(401).json({ error: 'Token has been revoked' });
    return null;
  }

  // Verify with Supabase
  const { data, error } = await supabaseAdmin.auth.getUser(token);
  if (error || !data.user) {
    res.status(401).json({ error: 'Invalid or expired token' });
    return null;
  }

  return {
    id: data.user.id,
    email: data.user.email || '',
  };
}
