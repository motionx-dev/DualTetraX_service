import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken } from '../lib/auth';
import { createUserClient, supabaseAdmin } from '../lib/supabase';
import { validateBody, GoalCreateSchema, GoalUpdateSchema } from '../lib/validate';
import { checkRateLimit } from '../lib/ratelimit';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id))) { return; }

  const supabase = createUserClient(extractToken(req)!);
  const id = req.query.__id as string | undefined;

  // PUT/DELETE /api/goals/:id
  if (id) {
    if (req.method === 'PUT') {
      const body = validateBody(req, res, GoalUpdateSchema);
      if (!body) { return; }

      const { data: existing, error: findError } = await supabase.from('user_goals').select('id').eq('id', id).single();
      if (findError || !existing) { return res.status(404).json({ error: 'Goal not found' }); }

      const { data, error } = await supabaseAdmin.from('user_goals').update(body).eq('id', id).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ goal: data });
    }

    if (req.method === 'DELETE') {
      const { data: existing, error: findError } = await supabase.from('user_goals').select('id').eq('id', id).single();
      if (findError || !existing) { return res.status(404).json({ error: 'Goal not found' }); }

      const { error } = await supabaseAdmin.from('user_goals').delete().eq('id', id);
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ deleted: true });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  }

  // GET /api/goals
  if (req.method === 'GET') {
    const { data, error } = await supabase.from('user_goals').select('*').eq('user_id', user.id).order('created_at', { ascending: false });
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ goals: data });
  }

  // POST /api/goals
  if (req.method === 'POST') {
    const body = validateBody(req, res, GoalCreateSchema);
    if (!body) { return; }

    const { data, error } = await supabaseAdmin.from('user_goals').insert({ user_id: user.id, ...body }).select().single();
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(201).json({ goal: data });
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
