import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken } from '../lib/auth';
import { createUserClient, supabaseAdmin } from '../lib/supabase';
import { validateBody, validateQuery, SessionUploadSchema, SessionsQuerySchema, ExportQuerySchema } from '../lib/validate';
import { checkRateLimit } from '../lib/ratelimit';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id))) { return; }

  const sub = req.query.__sub as string | undefined;
  const id = req.query.__id as string | undefined;

  // POST /api/sessions/upload
  if (sub === 'upload') {
    if (req.method !== 'POST') { return res.status(405).json({ error: 'Method not allowed' }); }

    const supabase = createUserClient(extractToken(req)!);
    const body = validateBody(req, res, SessionUploadSchema);
    if (!body) { return; }

    const { data: device, error: deviceError } = await supabase.from('devices').select('id').eq('id', body.device_id).single();
    if (deviceError || !device) { return res.status(404).json({ error: 'Device not found or not owned by you' }); }

    let uploaded = 0;
    let duplicates = 0;
    let errors = 0;
    const affectedDates = new Set<string>();

    for (const session of body.sessions) {
      const { battery_samples, ...sessionData } = session;

      const { data: inserted, error: insertError } = await supabaseAdmin.from('usage_sessions').upsert({
        id: sessionData.id, device_id: body.device_id, user_id: user.id,
        shot_type: sessionData.shot_type, device_mode: sessionData.device_mode, level: sessionData.level,
        led_pattern: sessionData.led_pattern, start_time: sessionData.start_time, end_time: sessionData.end_time,
        working_duration: sessionData.working_duration, pause_duration: sessionData.pause_duration,
        pause_count: sessionData.pause_count, termination_reason: sessionData.termination_reason,
        completion_percent: sessionData.completion_percent, had_temperature_warning: sessionData.had_temperature_warning,
        had_battery_warning: sessionData.had_battery_warning, battery_start: sessionData.battery_start,
        battery_end: sessionData.battery_end, sync_status: 2, time_synced: sessionData.time_synced,
      }, { onConflict: 'id', ignoreDuplicates: true }).select('id');

      if (insertError) { errors++; continue; }
      if (!inserted || inserted.length === 0) { duplicates++; continue; }

      uploaded++;
      const dateStr = sessionData.start_time.substring(0, 10);
      affectedDates.add(dateStr);

      if (battery_samples && battery_samples.length > 0) {
        await supabaseAdmin.from('battery_samples').insert(
          battery_samples.map((s) => ({ session_id: sessionData.id, elapsed_seconds: s.elapsed_seconds, voltage_mv: s.voltage_mv }))
        );
      }
    }

    if (uploaded > 0) {
      const { data: currentDevice } = await supabaseAdmin.from('devices').select('total_sessions').eq('id', body.device_id).single();
      await supabaseAdmin.from('devices').update({
        total_sessions: (currentDevice?.total_sessions || 0) + uploaded, last_synced_at: new Date().toISOString(),
      }).eq('id', body.device_id);

      for (const dateStr of affectedDates) {
        try { await supabaseAdmin.rpc('aggregate_daily_stats', { p_user_id: user.id, p_device_id: body.device_id, p_date: dateStr }); } catch { /* noop */ }
      }
    }

    return res.status(200).json({ uploaded, duplicates, errors });
  }

  // GET /api/sessions/export
  if (sub === 'export') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const q = validateQuery(req, res, ExportQuerySchema);
    if (!q) { return; }

    let qb = supabaseAdmin.from('usage_sessions').select('*').eq('user_id', user.id);
    if (q.device_id) { qb = qb.eq('device_id', q.device_id); }
    if (q.start_date) { qb = qb.gte('start_time', q.start_date); }
    if (q.end_date) { qb = qb.lte('start_time', q.end_date + 'T23:59:59Z'); }
    qb = qb.order('start_time', { ascending: false }).limit(10000);

    const { data, error } = await qb;
    if (error) { return res.status(500).json({ error: error.message }); }

    const headers = ['id', 'device_id', 'shot_type', 'device_mode', 'level', 'start_time', 'end_time', 'working_duration', 'pause_duration', 'completion_percent', 'termination_reason'];
    const csv = [headers.join(','), ...(data || []).map((r: Record<string, unknown>) => headers.map(h => JSON.stringify(r[h] ?? '')).join(','))].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="sessions.csv"');
    return res.status(200).send(csv);
  }

  // DELETE /api/sessions/:id
  if (id) {
    if (req.method !== 'DELETE') { return res.status(405).json({ error: 'Method not allowed' }); }

    const supabase = createUserClient(extractToken(req)!);
    const { data: session, error: findError } = await supabase.from('usage_sessions').select('id').eq('id', id).single();
    if (findError || !session) { return res.status(404).json({ error: 'Session not found' }); }

    const { error } = await supabaseAdmin.from('usage_sessions').delete().eq('id', id);
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ deleted: true });
  }

  // GET /api/sessions — list
  if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

  const query = validateQuery(req, res, SessionsQuerySchema);
  if (!query) { return; }

  const supabase = createUserClient(extractToken(req)!);
  const limit = query.limit ?? 50;
  const offset = query.offset ?? 0;

  let qb = supabase.from('usage_sessions').select('*', { count: 'exact' }).order('start_time', { ascending: false });
  if (query.device_id) { qb = qb.eq('device_id', query.device_id); }
  if (query.start_date) { qb = qb.gte('start_time', `${query.start_date}T00:00:00Z`); }
  if (query.end_date) { qb = qb.lte('start_time', `${query.end_date}T23:59:59Z`); }
  qb = qb.range(offset, offset + limit - 1);

  const { data, error, count } = await qb;
  if (error) { return res.status(500).json({ error: error.message }); }

  return res.status(200).json({ sessions: data, total: count || 0, limit, offset });
}
