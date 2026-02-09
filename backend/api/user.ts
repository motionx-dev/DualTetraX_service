import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken } from '../lib/auth';
import { createUserClient, supabaseAdmin } from '../lib/supabase';
import { validateBody, ProfileUpdateSchema, NotificationSettingsSchema, SkinProfileSchema, ConsentCreateSchema } from '../lib/validate';
import { checkRateLimit } from '../lib/ratelimit';

const DEFAULT_NOTIFICATION_SETTINGS = {
  push_enabled: true, email_enabled: true, usage_reminder: false, reminder_time: '09:00', marketing_enabled: false,
};

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id))) { return; }

  const supabase = createUserClient(extractToken(req)!);
  const sub = req.query.__sub as string | undefined;

  // /api/profile
  if (sub === 'profile') {
    if (req.method === 'GET') {
      const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ profile: data });
    }
    if (req.method === 'PUT') {
      const body = validateBody(req, res, ProfileUpdateSchema);
      if (!body) { return; }
      const { data, error } = await supabase.from('profiles').update({ ...body }).eq('id', user.id).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ profile: data });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // /api/notifications
  if (sub === 'notifications') {
    if (req.method === 'GET') {
      const { data, error } = await supabase.from('notification_settings').select('*').eq('user_id', user.id).single();
      if (error && error.code === 'PGRST116') {
        return res.status(200).json({ settings: { user_id: user.id, ...DEFAULT_NOTIFICATION_SETTINGS } });
      }
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ settings: data });
    }
    if (req.method === 'PUT') {
      const body = validateBody(req, res, NotificationSettingsSchema);
      if (!body) { return; }
      const { data, error } = await supabaseAdmin.from('notification_settings').upsert({ user_id: user.id, ...body }, { onConflict: 'user_id' }).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ settings: data });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // /api/skin-profile
  if (sub === 'skin-profile') {
    if (req.method === 'GET') {
      const { data, error } = await supabase.from('skin_profiles').select('*').eq('user_id', user.id).single();
      if (error && error.code === 'PGRST116') {
        return res.status(200).json({ skin_profile: { user_id: user.id, skin_type: null, concerns: null, memo: null } });
      }
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ skin_profile: data });
    }
    if (req.method === 'PUT') {
      const body = validateBody(req, res, SkinProfileSchema);
      if (!body) { return; }
      const { data, error } = await supabaseAdmin.from('skin_profiles').upsert({ user_id: user.id, ...body }, { onConflict: 'user_id' }).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ skin_profile: data });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // /api/consent
  if (sub === 'consent') {
    if (req.method === 'GET') {
      const { data, error } = await supabase.from('consent_records').select('*').eq('user_id', user.id).order('created_at', { ascending: false });
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ consents: data });
    }
    if (req.method === 'POST') {
      const body = validateBody(req, res, ConsentCreateSchema);
      if (!body) { return; }
      const { data, error } = await supabaseAdmin.from('consent_records').insert({
        user_id: user.id, consent_type: body.consent_type, consented: body.consented,
        ip_address: (req.headers['x-forwarded-for'] as string) || null, user_agent: req.headers['user-agent'] || null,
      }).select().single();
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(201).json({ consent: data });
    }
    return res.status(405).json({ error: 'Method not allowed' });
  }

  return res.status(404).json({ error: 'Not found' });
}
