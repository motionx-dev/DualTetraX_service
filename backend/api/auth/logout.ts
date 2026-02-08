import { Redis } from '@upstash/redis';
import { extractToken } from '../../lib/supabase';

export const config = {
  runtime: 'edge',
};

const redis = Redis.fromEnv();

export default async function handler(req: Request) {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const authHeader = req.headers.get('authorization');
    const token = extractToken(authHeader);

    if (!token) {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'No token provided',
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    await redis.set(`blacklist:${token}`, '1', { ex: 3600 });

    return new Response(JSON.stringify({
      message: 'Logged out successfully',
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: err.message,
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
