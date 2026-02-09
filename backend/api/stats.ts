import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken } from '../lib/auth';
import { createUserClient } from '../lib/supabase';
import { validateQuery, DailyStatsQuerySchema, RangeStatsQuerySchema } from '../lib/validate';
import { checkRateLimit } from '../lib/ratelimit';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }
  if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id))) { return; }

  const sub = req.query.__sub as string | undefined;
  const supabase = createUserClient(extractToken(req)!);

  // GET /api/stats/range
  if (sub === 'range') {
    const query = validateQuery(req, res, RangeStatsQuerySchema);
    if (!query) { return; }

    let qb = supabase.from('daily_statistics').select('*')
      .gte('stat_date', query.start_date).lte('stat_date', query.end_date)
      .order('stat_date', { ascending: true });

    if (query.device_id) { qb = qb.eq('device_id', query.device_id); }

    const { data, error } = await qb;
    if (error) { return res.status(500).json({ error: error.message }); }

    const rows = data || [];

    const grouped = new Map<string, typeof rows>();
    for (const row of rows) {
      let periodKey: string;
      if (query.group_by === 'week') {
        const d = new Date(row.stat_date + 'T00:00:00Z');
        const day = d.getUTCDay();
        const diff = d.getUTCDate() - day + (day === 0 ? -6 : 1);
        const monday = new Date(d);
        monday.setUTCDate(diff);
        periodKey = monday.toISOString().substring(0, 10);
      } else if (query.group_by === 'month') {
        periodKey = row.stat_date.substring(0, 7);
      } else {
        periodKey = row.stat_date;
      }
      if (!grouped.has(periodKey)) { grouped.set(periodKey, []); }
      grouped.get(periodKey)!.push(row);
    }

    const result = Array.from(grouped.entries()).map(([period, periodRows]) => {
      const agg = periodRows.reduce((acc, r) => ({
        total_sessions: acc.total_sessions + r.total_sessions,
        total_duration: acc.total_duration + r.total_duration,
        ushot_sessions: acc.ushot_sessions + r.ushot_sessions,
        eshot_sessions: acc.eshot_sessions + r.eshot_sessions,
        led_sessions: acc.led_sessions + r.led_sessions,
      }), { total_sessions: 0, total_duration: 0, ushot_sessions: 0, eshot_sessions: 0, led_sessions: 0 });
      return { period, ...agg };
    });

    const summary = rows.reduce((acc, r) => ({
      total_sessions: acc.total_sessions + r.total_sessions,
      total_duration: acc.total_duration + r.total_duration,
    }), { total_sessions: 0, total_duration: 0 });

    const dayCount = grouped.size || 1;

    return res.status(200).json({
      range: { start: query.start_date, end: query.end_date },
      data: result,
      summary: { ...summary, avg_sessions_per_day: Math.round((summary.total_sessions / dayCount) * 10) / 10 },
    });
  }

  // GET /api/stats/daily (default)
  const query = validateQuery(req, res, DailyStatsQuerySchema);
  if (!query) { return; }

  const date = query.date || new Date().toISOString().substring(0, 10);

  let qb = supabase.from('daily_statistics').select('*').eq('stat_date', date);
  if (query.device_id) { qb = qb.eq('device_id', query.device_id); }

  const { data, error } = await qb;
  if (error) { return res.status(500).json({ error: error.message }); }

  if (!data || data.length === 0) {
    return res.status(200).json({
      date, total_sessions: 0, total_duration: 0, ushot_sessions: 0, ushot_duration: 0,
      eshot_sessions: 0, eshot_duration: 0, led_sessions: 0, led_duration: 0,
      mode_breakdown: {}, level_breakdown: {}, warning_count: 0,
    });
  }

  const aggregated = data.reduce((acc, row) => ({
    total_sessions: acc.total_sessions + row.total_sessions, total_duration: acc.total_duration + row.total_duration,
    ushot_sessions: acc.ushot_sessions + row.ushot_sessions, ushot_duration: acc.ushot_duration + row.ushot_duration,
    eshot_sessions: acc.eshot_sessions + row.eshot_sessions, eshot_duration: acc.eshot_duration + row.eshot_duration,
    led_sessions: acc.led_sessions + row.led_sessions, led_duration: acc.led_duration + row.led_duration,
    warning_count: acc.warning_count + row.warning_count,
  }), {
    total_sessions: 0, total_duration: 0, ushot_sessions: 0, ushot_duration: 0,
    eshot_sessions: 0, eshot_duration: 0, led_sessions: 0, led_duration: 0, warning_count: 0,
  });

  return res.status(200).json({ date, ...aggregated, mode_breakdown: data[0]?.mode_breakdown || {}, level_breakdown: data[0]?.level_breakdown || {} });
}
