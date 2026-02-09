import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate } from '../lib/auth';
import { supabaseAdmin } from '../lib/supabase';
import { checkRateLimit } from '../lib/ratelimit';
import { validateQuery, FirmwareQuerySchema } from '../lib/validate';

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) { hash = ((hash << 5) - hash) + str.charCodeAt(i); hash |= 0; }
  return Math.abs(hash);
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }
  if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id, 'general'))) { return; }

  const sub = req.query.__sub as string | undefined;

  // GET /api/firmware/check
  if (sub === 'check') {
    const { data: latest, error } = await supabaseAdmin.from('firmware_versions').select('*')
      .eq('is_active', true).order('version_code', { ascending: false }).limit(1).single();

    if (error || !latest) { return res.status(200).json({ update_available: false }); }

    const currentCode = Number(req.query.current_version_code) || 0;
    if (latest.version_code <= currentCode) { return res.status(200).json({ update_available: false }); }

    const { data: rollout } = await supabaseAdmin.from('firmware_rollouts').select('*')
      .eq('firmware_version_id', latest.id).eq('status', 'active')
      .order('created_at', { ascending: false }).limit(1).maybeSingle();

    if (rollout) {
      const hash = hashCode(user.id + latest.id);
      const inRollout = (hash % 100) < rollout.target_percentage;
      if (!inRollout) { return res.status(200).json({ update_available: false }); }
    }

    return res.status(200).json({ update_available: true, firmware: latest });
  }

  // GET /api/firmware/latest (default)
  const query = validateQuery(req, res, FirmwareQuerySchema);
  if (!query) { return; }

  const { data, error } = await supabaseAdmin.from('firmware_versions').select('*')
    .eq('is_active', true).order('version_code', { ascending: false }).limit(1).single();

  if (error || !data) { return res.status(404).json({ error: 'No firmware version found' }); }
  return res.status(200).json(data);
}
