import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken, hashToken, decodeJwtPayload } from '../../lib/auth';
import { blacklistToken } from '../../lib/redis';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const user = await authenticate(req, res);
  if (!user) return;

  const token = extractToken(req)!;
  const tokenHash = hashToken(token);
  const payload = decodeJwtPayload(token);
  const exp = typeof payload?.exp === 'number' ? payload.exp : Math.floor(Date.now() / 1000) + 3600;

  await blacklistToken(tokenHash, exp);

  return res.status(200).json({ message: 'Logged out successfully' });
}
