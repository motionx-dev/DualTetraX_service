import type { VercelRequest, VercelResponse } from '@vercel/node';
import { authenticate, extractToken } from '../lib/auth';
import { createUserClient, supabaseAdmin } from '../lib/supabase';
import { validateBody, DeviceRegisterSchema, DeviceUpdateSchema, DeviceTransferSchema } from '../lib/validate';
import { checkRateLimit } from '../lib/ratelimit';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method === 'OPTIONS') { return res.status(200).end(); }

  const user = await authenticate(req, res);
  if (!user) { return; }

  if (!(await checkRateLimit(res, user.id))) { return; }

  const supabase = createUserClient(extractToken(req)!);
  const id = req.query.__id as string | undefined;
  const sub = req.query.__sub as string | undefined;

  // POST /api/devices/:id/transfer
  if (id && sub === 'transfer') {
    if (req.method !== 'POST') { return res.status(405).json({ error: 'Method not allowed' }); }

    const body = validateBody(req, res, DeviceTransferSchema);
    if (!body) { return; }

    const { data: device, error: deviceError } = await supabase.from('devices').select('id, user_id').eq('id', id).single();
    if (deviceError || !device) { return res.status(404).json({ error: 'Device not found or not owned by you' }); }

    const { data: targetUser, error: targetError } = await supabaseAdmin.from('profiles').select('id, email').eq('email', body.to_email).single();
    if (targetError || !targetUser) { return res.status(404).json({ error: 'Target user not found' }); }
    if (targetUser.id === user.id) { return res.status(400).json({ error: 'Cannot transfer device to yourself' }); }

    const { data: transfer, error: transferError } = await supabaseAdmin.from('device_transfers').insert({
      device_id: id, from_user_id: user.id, to_user_id: targetUser.id, status: 'pending',
    }).select().single();
    if (transferError) { return res.status(500).json({ error: transferError.message }); }

    const { error: updateError } = await supabaseAdmin.from('devices').update({ user_id: targetUser.id }).eq('id', id);
    if (updateError) { return res.status(500).json({ error: updateError.message }); }

    return res.status(200).json({ transfer });
  }

  // GET/PUT/DELETE /api/devices/:id
  if (id) {
    if (req.method === 'GET') {
      const { data, error } = await supabase.from('devices').select('*').eq('id', id).single();
      if (error && error.code === 'PGRST116') { return res.status(404).json({ error: 'Device not found' }); }
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ device: data });
    }

    if (req.method === 'PUT') {
      const body = validateBody(req, res, DeviceUpdateSchema);
      if (!body) { return; }

      const updateObj: Record<string, unknown> = {};
      if (body.nickname !== undefined) { updateObj.nickname = body.nickname; }
      if (body.firmware_version !== undefined) { updateObj.firmware_version = body.firmware_version; }

      const { data, error } = await supabase.from('devices').update(updateObj).eq('id', id).select().single();
      if (error && error.code === 'PGRST116') { return res.status(404).json({ error: 'Device not found' }); }
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ device: data });
    }

    if (req.method === 'DELETE') {
      const { data, error } = await supabase.from('devices').update({ is_active: false }).eq('id', id).select().single();
      if (error && error.code === 'PGRST116') { return res.status(404).json({ error: 'Device not found' }); }
      if (error) { return res.status(500).json({ error: error.message }); }
      return res.status(200).json({ device: data });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  }

  // GET /api/devices — list
  if (req.method === 'GET') {
    const { data, error } = await supabase.from('devices').select('*').order('registered_at', { ascending: false });
    if (error) { return res.status(500).json({ error: error.message }); }
    return res.status(200).json({ devices: data });
  }

  // POST /api/devices — register
  if (req.method === 'POST') {
    const body = validateBody(req, res, DeviceRegisterSchema);
    if (!body) { return; }

    const { data, error } = await supabase.from('devices').insert({
      user_id: user.id, serial_number: body.serial_number, model_name: body.model_name,
      firmware_version: body.firmware_version, ble_mac_address: body.ble_mac_address,
    }).select().single();

    if (error) {
      if (error.code === '23505') { return res.status(409).json({ error: 'Device already registered' }); }
      return res.status(500).json({ error: error.message });
    }
    return res.status(201).json({ device: data });
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
