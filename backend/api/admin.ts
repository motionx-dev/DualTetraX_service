import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticateAdmin } from '../lib/admin';
import { logAdminAction, getClientIp } from '../lib/audit';
import { checkRateLimit } from '../lib/ratelimit';
import { supabaseAdmin } from '../lib/supabase';
import { validateBody, validateQuery, PaginationQuerySchema, AdminLogsQuerySchema, AdminUserUpdateSchema, AnnouncementCreateSchema, AnnouncementUpdateSchema, FirmwareCreateSchema, RolloutCreateSchema, RolloutUpdateSchema, AdminSetupSchema, AdminPromoteSchema } from '../lib/validate';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }

  const route = req.query.__route as string | undefined;

  // --- /api/admin/setup --- (bootstrap: first admin account, no auth required)
  // NOTE: Future consideration - add 2FA (dual authentication) for admin accounts.
  //       When implementing 2FA, admin login should require TOTP or email-based OTP
  //       in addition to the Supabase Auth password. Store 2FA secrets in a separate
  //       table (admin_2fa) and enforce verification on every admin API call.
  if (route === 'setup') {
    if (req.method !== 'POST') { return res.status(405).json({ error: 'Method not allowed' }); }

    const body = validateBody(req, res, AdminSetupSchema);
    if (!body) { return; }

    // Verify setup_key matches the environment variable
    const expectedKey = process.env.ADMIN_SETUP_KEY;
    if (!expectedKey) {
      return res.status(500).json({ error: 'ADMIN_SETUP_KEY environment variable not configured' });
    }
    if (body.setup_key !== expectedKey) {
      return res.status(403).json({ error: 'Invalid setup key' });
    }

    // Check if any admin account already exists
    const { count: adminCount, error: countError } = await supabaseAdmin
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .eq('role', 'admin');

    if (countError) {
      return res.status(500).json({ error: countError.message });
    }
    if ((adminCount ?? 0) > 0) {
      return res.status(403).json({ error: 'Admin account already exists. Use the promote endpoint instead.' });
    }

    // Find the user by email in profiles
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('profiles')
      .select('id, email, role')
      .eq('email', body.email)
      .single();

    if (profileError || !profile) {
      return res.status(404).json({ error: 'User not found. The user must sign up first before being promoted to admin.' });
    }

    // Promote the user to admin
    const { error: updateError } = await supabaseAdmin
      .from('profiles')
      .update({ role: 'admin' })
      .eq('id', profile.id);

    if (updateError) {
      return res.status(500).json({ error: updateError.message });
    }

    // Log the bootstrap action (use the promoted user's own ID as admin_id since no admin existed)
    await logAdminAction(profile.id, 'admin.setup', 'user', profile.id, { email: body.email, method: 'bootstrap' }, getClientIp(req.headers));

    return res.status(200).json({
      message: 'Admin account created successfully',
      admin: { id: profile.id, email: profile.email },
    });
  }

  // --- All routes below require admin authentication ---
  const admin = await authenticateAdmin(req, res);
  if (!admin) { return; }

  if (!(await checkRateLimit(res, admin.id, 'admin'))) { return; }

  const id = req.query.__id as string | undefined;

  // --- /api/admin/promote --- (promote an existing user to admin, requires admin auth)
  if (route === 'promote') {
    if (req.method !== 'POST') { return res.status(405).json({ error: 'Method not allowed' }); }

    const body = validateBody(req, res, AdminPromoteSchema);
    if (!body) { return; }

    // Find the target user by user_id or email
    let targetQuery = supabaseAdmin.from('profiles').select('id, email, role');
    if (body.user_id) {
      targetQuery = targetQuery.eq('id', body.user_id);
    } else if (body.email) {
      targetQuery = targetQuery.eq('email', body.email);
    }
    const { data: target, error: targetError } = await targetQuery.single();

    if (targetError || !target) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (target.role === 'admin') {
      return res.status(409).json({ error: 'User is already an admin' });
    }

    // Promote to admin
    const { error: updateError } = await supabaseAdmin
      .from('profiles')
      .update({ role: 'admin' })
      .eq('id', target.id);

    if (updateError) {
      return res.status(500).json({ error: updateError.message });
    }

    await logAdminAction(admin.id, 'admin.promote', 'user', target.id, { email: target.email, promoted_by: admin.email }, getClientIp(req.headers));

    return res.status(200).json({
      message: 'User promoted to admin successfully',
      admin: { id: target.id, email: target.email },
    });
  }

  // --- /api/admin/stats ---
  if (route === 'stats') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const todayStr = new Date().toISOString().substring(0, 10);
    const [usersResult, devicesResult, activeDevicesResult, sessionsResult, todaySessionsResult] = await Promise.all([
      supabaseAdmin.from('profiles').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('devices').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('devices').select('id', { count: 'exact', head: true }).eq('is_active', true),
      supabaseAdmin.from('usage_sessions').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('usage_sessions').select('id', { count: 'exact', head: true }).gte('start_time', todayStr),
    ]);

    return res.status(200).json({
      total_users: usersResult.count ?? 0, total_devices: devicesResult.count ?? 0,
      active_devices: activeDevicesResult.count ?? 0, total_sessions: sessionsResult.count ?? 0,
      today_sessions: todaySessionsResult.count ?? 0,
    });
  }

  // --- /api/admin/users ---
  if (route === 'users') {
    if (id) {
      if (req.method === 'GET') {
        const [profileResult, deviceResult, sessionResult] = await Promise.all([
          supabaseAdmin.from('profiles').select('*').eq('id', id).single(),
          supabaseAdmin.from('devices').select('id', { count: 'exact' }).eq('user_id', id),
          supabaseAdmin.from('usage_sessions').select('id', { count: 'exact' }).eq('user_id', id),
        ]);
        if (profileResult.error || !profileResult.data) { return res.status(404).json({ error: 'User not found' }); }
        return res.status(200).json({ profile: profileResult.data, device_count: deviceResult.count ?? 0, session_count: sessionResult.count ?? 0 });
      }
      if (req.method === 'PUT') {
        const body = validateBody(req, res, AdminUserUpdateSchema);
        if (!body) { return; }
        const { data, error } = await supabaseAdmin.from('profiles').update(body).eq('id', id).select().single();
        if (error) { return res.status(500).json({ error: error.message }); }
        if (!data) { return res.status(404).json({ error: 'User not found' }); }
        await logAdminAction(admin.id, 'user.update', 'user', id, body, getClientIp(req.headers));
        return res.status(200).json(data);
      }
      return res.status(405).json({ error: 'Method not allowed' });
    }

    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }
    const query = validateQuery(req, res, PaginationQuerySchema);
    if (!query) { return; }

    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    let q = supabaseAdmin.from('profiles').select('*, devices(count)', { count: 'exact' });
    if (query.search) { q = q.or(`email.ilike.%${query.search}%,name.ilike.%${query.search}%`); }
    q = q.range(offset, offset + limit - 1).order('created_at', { ascending: false });

    const { data, count, error } = await q;
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ users: data, total: count, page, limit });
  }

  // --- /api/admin/devices ---
  if (route === 'devices') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }
    const query = validateQuery(req, res, PaginationQuerySchema);
    if (!query) { return; }

    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    let q = supabaseAdmin.from('devices').select('*, profiles(email, name)', { count: 'exact' });
    if (query.search) { q = q.or(`serial_number.ilike.%${query.search}%,model_name.ilike.%${query.search}%`); }
    q = q.range(offset, offset + limit - 1).order('registered_at', { ascending: false });

    const { data, count, error } = await q;
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ devices: data, total: count, page, limit });
  }

  // --- /api/admin/logs ---
  if (route === 'logs') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }
    const query = validateQuery(req, res, AdminLogsQuerySchema);
    if (!query) { return; }

    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const offset = (page - 1) * limit;

    let q = supabaseAdmin.from('admin_logs').select('*, profiles!admin_logs_admin_id_fkey(email, name)', { count: 'exact' });
    if (query.action) { q = q.ilike('action', `%${query.action}%`); }
    if (query.target_type) { q = q.eq('target_type', query.target_type); }
    if (query.admin_id) { q = q.eq('admin_id', query.admin_id); }
    q = q.range(offset, offset + limit - 1).order('created_at', { ascending: false });

    const { data, count, error } = await q;
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ logs: data, total: count, page, limit });
  }

  // --- /api/admin/announcements ---
  if (route === 'announcements') {
    if (id) {
      if (req.method === 'PUT') {
        const body = validateBody(req, res, AnnouncementUpdateSchema);
        if (!body) { return; }

        const updateObj: Record<string, unknown> = {};
        if (body.title !== undefined) { updateObj.title = body.title; }
        if (body.content !== undefined) { updateObj.content = body.content; }
        if (body.type !== undefined) { updateObj.type = body.type; }
        if (body.is_published === true) { updateObj.is_published = true; updateObj.published_at = new Date().toISOString(); }
        if (body.is_published === false) { updateObj.is_published = false; updateObj.published_at = null; }
        if (Object.keys(updateObj).length === 0) { return res.status(400).json({ error: 'No fields to update' }); }

        const { data, error } = await supabaseAdmin.from('announcements').update(updateObj).eq('id', id).select().single();
        if (error) { return res.status(500).json({ error: error.message }); }
        if (!data) { return res.status(404).json({ error: 'Announcement not found' }); }
        await logAdminAction(admin.id, 'announcement.update', 'announcement', id, updateObj, getClientIp(req.headers));
        return res.status(200).json(data);
      }
      if (req.method === 'DELETE') {
        const { error } = await supabaseAdmin.from('announcements').delete().eq('id', id);
        if (error) { return res.status(500).json({ error: error.message }); }
        await logAdminAction(admin.id, 'announcement.delete', 'announcement', id, null, getClientIp(req.headers));
        return res.status(200).json({ deleted: true });
      }
      return res.status(405).json({ error: 'Method not allowed' });
    }

    if (req.method === 'GET') {
      const { data, error } = await supabaseAdmin.from('announcements').select('*, profiles!announcements_created_by_fkey(email, name)').order('created_at', { ascending: false });
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ announcements: data });
    }
    if (req.method === 'POST') {
      const body = validateBody(req, res, AnnouncementCreateSchema);
      if (!body) { return; }
      const insertObj: Record<string, unknown> = { ...body, created_by: admin.id };
      if (body.is_published) { insertObj.published_at = new Date().toISOString(); }
      const { data, error } = await supabaseAdmin.from('announcements').insert(insertObj).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      await logAdminAction(admin.id, 'announcement.create', 'announcement', data.id, { title: body.title }, getClientIp(req.headers));
      return res.status(201).json(data);
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // --- /api/admin/firmware ---
  if (route === 'firmware') {
    if (req.method === 'GET') {
      const { data, error } = await supabaseAdmin.from('firmware_versions').select('*').order('version_code', { ascending: false });
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ firmware_versions: data });
    }
    if (req.method === 'POST') {
      const body = validateBody(req, res, FirmwareCreateSchema);
      if (!body) { return; }
      const { data, error } = await supabaseAdmin.from('firmware_versions').insert(body).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      await logAdminAction(admin.id, 'firmware.create', 'firmware', data.id, { version: body.version }, getClientIp(req.headers));
      return res.status(201).json(data);
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // --- /api/admin/firmware/rollouts ---
  if (route === 'firmware-rollouts') {
    if (id) {
      if (req.method !== 'PUT') { return res.status(405).json({ error: 'Method not allowed' }); }
      const body = validateBody(req, res, RolloutUpdateSchema);
      if (!body) { return; }

      const updateObj: Record<string, unknown> = {};
      if (body.status !== undefined) { updateObj.status = body.status; }
      if (body.target_percentage !== undefined) { updateObj.target_percentage = body.target_percentage; }
      if (body.notes !== undefined) { updateObj.notes = body.notes; }
      if (Object.keys(updateObj).length === 0) { return res.status(400).json({ error: 'No fields to update' }); }

      const { data, error } = await supabaseAdmin.from('firmware_rollouts').update(updateObj).eq('id', id).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      if (!data) { return res.status(404).json({ error: 'Rollout not found' }); }
      await logAdminAction(admin.id, 'rollout.update', 'rollout', id, updateObj, getClientIp(req.headers));
      return res.status(200).json(data);
    }

    if (req.method === 'GET') {
      const { data, error } = await supabaseAdmin.from('firmware_rollouts').select('*, firmware_versions(version, version_code)').order('created_at', { ascending: false });
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ rollouts: data });
    }
    if (req.method === 'POST') {
      const body = validateBody(req, res, RolloutCreateSchema);
      if (!body) { return; }
      const { data, error } = await supabaseAdmin.from('firmware_rollouts').insert({ ...body, created_by: admin.id }).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      await logAdminAction(admin.id, 'rollout.create', 'rollout', data.id, { firmware_version_id: body.firmware_version_id, target_percentage: body.target_percentage }, getClientIp(req.headers));
      return res.status(201).json(data);
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }


  // --- /api/admin/firmware/upload --- (signed upload URL for Storage)
  if (route === 'firmware-upload') {
    if (req.method === 'POST') {
      const { filename } = req.body || {};
      if (!filename || typeof filename !== 'string') {
        return res.status(400).json({ error: 'filename is required' });
      }
      const safeName = filename.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `${Date.now()}_${safeName}`;

      const { data, error } = await supabaseAdmin.storage
        .from('firmware')
        .createSignedUploadUrl(path);

      if (error) { return res.status(500).json({ error: error.message }); }

      await logAdminAction(admin.id, 'firmware.upload_url', 'firmware', null, { filename: safeName, path }, getClientIp(req.headers));

      return res.status(200).json({
        signed_url: data.signedUrl,
        token: data.token,
        path: data.path,
      });
    }
    if (req.method === 'GET') {
      const path = req.query.path as string;
      if (!path) {
        return res.status(400).json({ error: 'path query parameter is required' });
      }
      const { data, error } = await supabaseAdmin.storage
        .from('firmware')
        .createSignedUrl(path, 3600);

      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ download_url: data.signedUrl });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // --- /api/admin/analytics/overview ---
  if (route === 'analytics-overview') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const now = new Date();
    const d30 = new Date(now); d30.setDate(d30.getDate() - 30);
    const d7 = new Date(now); d7.setDate(d7.getDate() - 7);
    const todayStr = now.toISOString().substring(0, 10);
    const d30Str = d30.toISOString();
    const d7Str = d7.toISOString();

    const [
      totalUsers, activeUsers30d, newUsers7d,
      totalDevices, activeDevices, newDevices7d,
      totalSessions, todaySessions, sessions7d,
      avgStats,
    ] = await Promise.all([
      supabaseAdmin.from('profiles').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('usage_sessions').select('user_id').gte('start_time', d30Str).then(r => new Set((r.data || []).map(s => s.user_id)).size),
      supabaseAdmin.from('profiles').select('id', { count: 'exact', head: true }).gte('created_at', d7Str),
      supabaseAdmin.from('devices').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('devices').select('id', { count: 'exact', head: true }).eq('is_active', true),
      supabaseAdmin.from('devices').select('id', { count: 'exact', head: true }).gte('registered_at', d7Str),
      supabaseAdmin.from('usage_sessions').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('usage_sessions').select('id', { count: 'exact', head: true }).gte('start_time', todayStr),
      supabaseAdmin.from('usage_sessions').select('id', { count: 'exact', head: true }).gte('start_time', d7Str),
      supabaseAdmin.from('usage_sessions').select('working_duration, completion_percent'),
    ]);

    const durations = avgStats.data || [];
    const avgDuration = durations.length > 0 ? durations.reduce((s, d) => s + (d.working_duration || 0), 0) / durations.length : 0;
    const avgCompletion = durations.length > 0 ? durations.reduce((s, d) => s + (d.completion_percent || 0), 0) / durations.length : 0;

    return res.status(200).json({
      total_users: totalUsers.count ?? 0,
      active_users_30d: activeUsers30d,
      new_users_7d: newUsers7d.count ?? 0,
      total_devices: totalDevices.count ?? 0,
      active_devices: activeDevices.count ?? 0,
      new_devices_7d: newDevices7d.count ?? 0,
      total_sessions: totalSessions.count ?? 0,
      today_sessions: todaySessions.count ?? 0,
      sessions_7d: sessions7d.count ?? 0,
      avg_sessions_per_day_7d: Math.round(((sessions7d.count ?? 0) / 7) * 10) / 10,
      avg_duration_seconds: Math.round(avgDuration),
      avg_completion_percent: Math.round(avgCompletion * 10) / 10,
    });
  }

  // --- /api/admin/analytics/usage-trends ---
  if (route === 'analytics-usage-trends') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const days = parseInt(req.query.days as string) || 30;
    const start = new Date(); start.setDate(start.getDate() - days + 1);
    const startStr = start.toISOString().substring(0, 10);

    const { data, error } = await supabaseAdmin
      .from('usage_sessions')
      .select('start_time, working_duration')
      .gte('start_time', startStr);

    if (error) { return res.status(500).json({ error: error.message }); }

    // Group by date
    const byDate: Record<string, { sessions: number; total_duration: number }> = {};
    for (const s of data || []) {
      const date = s.start_time.substring(0, 10);
      if (!byDate[date]) { byDate[date] = { sessions: 0, total_duration: 0 }; }
      byDate[date].sessions++;
      byDate[date].total_duration += s.working_duration || 0;
    }

    // Fill missing dates
    const trends = [];
    for (let i = 0; i < days; i++) {
      const d = new Date(start); d.setDate(d.getDate() + i);
      const dateStr = d.toISOString().substring(0, 10);
      const entry = byDate[dateStr] || { sessions: 0, total_duration: 0 };
      trends.push({
        date: dateStr,
        sessions: entry.sessions,
        avg_duration: entry.sessions > 0 ? Math.round(entry.total_duration / entry.sessions) : 0,
        total_duration: entry.total_duration,
      });
    }

    return res.status(200).json({ trends });
  }

  // --- /api/admin/analytics/feature-usage ---
  if (route === 'analytics-feature-usage') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const days = parseInt(req.query.days as string) || 30;
    const start = new Date(); start.setDate(start.getDate() - days);

    const { data, error } = await supabaseAdmin
      .from('usage_sessions')
      .select('shot_type, device_mode, working_duration')
      .gte('start_time', start.toISOString());

    if (error) { return res.status(500).json({ error: error.message }); }

    // Shot type breakdown
    const shotTypes: Record<number, { count: number; total_duration: number }> = {};
    const modes: Record<number, { count: number; total_duration: number }> = {};

    for (const s of data || []) {
      const st = s.shot_type ?? 0;
      if (!shotTypes[st]) { shotTypes[st] = { count: 0, total_duration: 0 }; }
      shotTypes[st].count++;
      shotTypes[st].total_duration += s.working_duration || 0;

      const m = s.device_mode ?? 0;
      if (!modes[m]) { modes[m] = { count: 0, total_duration: 0 }; }
      modes[m].count++;
      modes[m].total_duration += s.working_duration || 0;
    }

    const total = (data || []).length;
    const SHOT_NAMES: Record<number, string> = { 0: 'U-Shot', 1: 'E-Shot', 2: 'LED' };
    const MODE_NAMES: Record<number, string> = {
      1: 'Glow', 2: 'Toneup', 3: 'Renew', 4: 'Volume',
      17: 'Clean', 18: 'Firm', 19: 'Line', 20: 'Lift',
      33: 'LED',
    };

    return res.status(200).json({
      shot_types: Object.entries(shotTypes).map(([k, v]) => ({
        shot_type: Number(k), name: SHOT_NAMES[Number(k)] || `Type ${k}`,
        count: v.count, total_duration: v.total_duration,
        percentage: total > 0 ? Math.round((v.count / total) * 1000) / 10 : 0,
      })),
      modes: Object.entries(modes).map(([k, v]) => ({
        device_mode: Number(k), name: MODE_NAMES[Number(k)] || `Mode ${k}`,
        count: v.count, total_duration: v.total_duration,
        percentage: total > 0 ? Math.round((v.count / total) * 1000) / 10 : 0,
      })).sort((a, b) => b.count - a.count),
    });
  }

  // --- /api/admin/analytics/demographics ---
  if (route === 'analytics-demographics') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const { data, error } = await supabaseAdmin
      .from('profiles')
      .select('date_of_birth, gender, timezone');

    if (error) { return res.status(500).json({ error: error.message }); }

    const now = new Date();
    const ageGroups: Record<string, number> = {};
    const genderDist: Record<string, number> = {};
    const tzDist: Record<string, number> = {};

    for (const p of data || []) {
      // Age
      if (p.date_of_birth) {
        const birth = new Date(p.date_of_birth);
        const age = now.getFullYear() - birth.getFullYear();
        const group = age < 20 ? '<20' : age < 30 ? '20s' : age < 40 ? '30s' : age < 50 ? '40s' : age < 60 ? '50s' : '60+';
        ageGroups[group] = (ageGroups[group] || 0) + 1;
      } else {
        ageGroups['unknown'] = (ageGroups['unknown'] || 0) + 1;
      }

      // Gender
      const g = p.gender || 'unknown';
      genderDist[g] = (genderDist[g] || 0) + 1;

      // Timezone
      const tz = p.timezone || 'unknown';
      tzDist[tz] = (tzDist[tz] || 0) + 1;
    }

    const total = (data || []).length;
    return res.status(200).json({
      age_distribution: Object.entries(ageGroups).map(([group, count]) => ({
        group, count, percentage: total > 0 ? Math.round((count / total) * 1000) / 10 : 0,
      })),
      gender_distribution: Object.entries(genderDist).map(([gender, count]) => ({
        gender, count, percentage: total > 0 ? Math.round((count / total) * 1000) / 10 : 0,
      })),
      timezone_distribution: Object.entries(tzDist).map(([tz, count]) => ({
        timezone: tz, count,
      })).sort((a, b) => b.count - a.count),
    });
  }

  // --- /api/admin/analytics/heatmap ---
  if (route === 'analytics-heatmap') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const days = parseInt(req.query.days as string) || 30;
    const start = new Date(); start.setDate(start.getDate() - days);

    const { data, error } = await supabaseAdmin
      .from('usage_sessions')
      .select('start_time')
      .gte('start_time', start.toISOString());

    if (error) { return res.status(500).json({ error: error.message }); }

    // Build heatmap: [day_of_week][hour] = count
    const heatmap: number[][] = Array.from({ length: 7 }, () => Array(24).fill(0));

    for (const s of data || []) {
      const d = new Date(s.start_time);
      const dow = d.getUTCDay(); // 0=Sun
      const hour = d.getUTCHours();
      heatmap[dow][hour]++;
    }

    // Flatten for response
    const cells = [];
    for (let dow = 0; dow < 7; dow++) {
      for (let hour = 0; hour < 24; hour++) {
        cells.push({ day: dow, hour, count: heatmap[dow][hour] });
      }
    }

    return res.status(200).json({ heatmap: cells });
  }

  // --- /api/admin/analytics/termination ---
  if (route === 'analytics-termination') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const days = parseInt(req.query.days as string) || 30;
    const start = new Date(); start.setDate(start.getDate() - days);

    const { data, error } = await supabaseAdmin
      .from('usage_sessions')
      .select('termination_reason, completion_percent')
      .gte('start_time', start.toISOString());

    if (error) { return res.status(500).json({ error: error.message }); }

    const REASON_NAMES: Record<number, string> = {
      0: 'Normal completion', 1: 'Manual stop', 2: 'Low battery',
      3: 'Overheating', 4: 'Charging started', 5: 'Pause timeout',
      6: 'Mode change', 7: 'Power event', 8: 'Ultrasonic overheat',
      9: 'Body overheat', 255: 'Other',
    };

    const reasons: Record<number, number> = {};
    let totalCompletion = 0;

    for (const s of data || []) {
      const r = s.termination_reason ?? 255;
      reasons[r] = (reasons[r] || 0) + 1;
      totalCompletion += s.completion_percent || 0;
    }

    const total = (data || []).length;
    return res.status(200).json({
      reasons: Object.entries(reasons).map(([k, count]) => ({
        reason: Number(k), name: REASON_NAMES[Number(k)] || `Reason ${k}`,
        count, percentage: total > 0 ? Math.round((count / total) * 1000) / 10 : 0,
      })).sort((a, b) => b.count - a.count),
      avg_completion_percent: total > 0 ? Math.round((totalCompletion / total) * 10) / 10 : 0,
      total_sessions: total,
    });
  }

  // --- /api/admin/analytics/firmware-dist ---
  if (route === 'analytics-firmware-dist') {
    if (req.method !== 'GET') { return res.status(405).json({ error: 'Method not allowed' }); }

    const { data, error } = await supabaseAdmin
      .from('devices')
      .select('firmware_version')
      .eq('is_active', true);

    if (error) { return res.status(500).json({ error: error.message }); }

    const versions: Record<string, number> = {};
    for (const d of data || []) {
      const v = d.firmware_version || 'unknown';
      versions[v] = (versions[v] || 0) + 1;
    }

    const total = (data || []).length;
    return res.status(200).json({
      firmware: Object.entries(versions).map(([version, count]) => ({
        version, count, percentage: total > 0 ? Math.round((count / total) * 1000) / 10 : 0,
      })).sort((a, b) => b.count - a.count),
      total_devices: total,
    });
  }

  return res.status(404).json({ error: 'Not found' });
}
