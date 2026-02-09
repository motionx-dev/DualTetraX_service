import { Redis } from '@upstash/redis';

export const redis = new Redis({
  url: (process.env.UPSTASH_REDIS_REST_URL || '').trim(),
  token: (process.env.UPSTASH_REDIS_REST_TOKEN || '').trim(),
});

/**
 * Add a JWT token hash to the blacklist with TTL matching the token's remaining lifetime.
 */
export async function blacklistToken(tokenHash: string, expiresAt: number): Promise<void> {
  const ttl = expiresAt - Math.floor(Date.now() / 1000);
  if (ttl > 0) {
    await redis.set(`bl:${tokenHash}`, '1', { ex: ttl });
  }
}

/**
 * Check if a token hash is blacklisted.
 */
export async function isTokenBlacklisted(tokenHash: string): Promise<boolean> {
  const result = await redis.get(`bl:${tokenHash}`);
  return result !== null;
}
