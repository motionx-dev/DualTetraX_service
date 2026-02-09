import { Ratelimit } from '@upstash/ratelimit';
import { redis } from './redis';
import type { VercelResponse } from '@vercel/node';

const generalLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(60, '1 m'),
  prefix: 'rl:general',
});

const uploadLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
  prefix: 'rl:upload',
});

const adminLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(30, '1 m'),
  prefix: 'rl:admin',
});

type LimitType = 'general' | 'upload' | 'admin';

const limiters: Record<LimitType, Ratelimit> = {
  general: generalLimiter,
  upload: uploadLimiter,
  admin: adminLimiter,
};

// Check rate limit. Returns true if allowed, false if rate limited (and sends 429 response).
export async function checkRateLimit(res: VercelResponse, identifier: string, type: LimitType = 'general'): Promise<boolean> {
  try {
    const { success, remaining, reset } = await limiters[type].limit(identifier);

    if (!success) {
      res.setHeader('X-RateLimit-Remaining', '0');
      res.setHeader('X-RateLimit-Reset', String(reset));
      res.status(429).json({ error: 'Too many requests' });
      return false;
    }

    res.setHeader('X-RateLimit-Remaining', String(remaining));
    return true;
  } catch {
    // If rate limiting fails, allow the request (fail-open)
    return true;
  }
}
