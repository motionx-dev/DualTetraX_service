import { createSupabaseClient, extractToken } from '../../lib/supabase';
import { deviceRegistrationSchema, validateBody } from '../../lib/validation';

export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const authHeader = req.headers.get('authorization');
    const token = extractToken(authHeader);

    if (!token) {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'No token provided',
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const supabase = createSupabaseClient(token);

    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({
        error: 'Unauthorized',
        message: 'Invalid token',
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const deviceData = validateBody(deviceRegistrationSchema, body);

    const { data, error } = await supabase
      .from('devices')
      .insert({
        user_id: user.id,
        serial_number: deviceData.serial_number,
        model_name: deviceData.model_name,
        firmware_version: deviceData.firmware_version,
        ble_mac_address: deviceData.ble_mac_address,
        is_active: true,
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        return new Response(JSON.stringify({
          error: 'Conflict',
          message: 'Serial number already registered',
        }), {
          status: 409,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      return new Response(JSON.stringify({
        error: 'Database error',
        message: error.message,
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify(data), {
      status: 201,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    if (err.status === 400) {
      return new Response(JSON.stringify(err), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: err.message,
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
