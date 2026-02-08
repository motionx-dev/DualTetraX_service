/**
 * Health Check API
 */

import type { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({
      error: 'Method not allowed'
    });
  }

  const hasSupabaseUrl = !!process.env.SUPABASE_URL;
  const hasSupabaseKey = !!process.env.SUPABASE_SERVICE_ROLE_KEY;
  const hasRedisUrl = !!process.env.UPSTASH_REDIS_REST_URL;
  const hasRedisToken = !!process.env.UPSTASH_REDIS_REST_TOKEN;

  return res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    config: {
      supabase_url_set: hasSupabaseUrl,
      supabase_key_set: hasSupabaseKey,
      redis_url_set: hasRedisUrl,
      redis_token_set: hasRedisToken
    }
  });
}
