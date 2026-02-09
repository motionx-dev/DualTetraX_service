import type { VercelRequest, VercelResponse } from '@vercel/node';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  let dbOk = false;
  let redisOk = false;
  let dbError = '';
  let redisError = '';

  try {
    const { createClient } = await import('@supabase/supabase-js');
    const supabase = createClient(
      (process.env.SUPABASE_URL || '').trim(),
      (process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim(),
      { auth: { autoRefreshToken: false, persistSession: false } }
    );
    const { error } = await supabase.from('profiles').select('id').limit(1);
    if (error) {
      dbOk = error.code === '42P01'; // table doesn't exist yet but connection works
      dbError = error.message;
    } else {
      dbOk = true;
    }
  } catch (e: unknown) {
    dbError = e instanceof Error ? e.message : String(e);
  }

  try {
    const { Redis } = await import('@upstash/redis');
    const redis = new Redis({
      url: (process.env.UPSTASH_REDIS_REST_URL || '').trim(),
      token: (process.env.UPSTASH_REDIS_REST_TOKEN || '').trim(),
    });
    await redis.ping();
    redisOk = true;
  } catch (e: unknown) {
    redisError = e instanceof Error ? e.message : String(e);
  }

  const status = dbOk && redisOk ? 'healthy' : 'degraded';

  return res.status(200).json({
    status,
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    environment: (process.env.NODE_ENV || 'development').trim(),
    services: { database: dbOk, redis: redisOk },
    ...((!dbOk || !redisOk) && {
      errors: {
        ...(dbError && { database: dbError }),
        ...(redisError && { redis: redisError }),
      },
    }),
  });
}
