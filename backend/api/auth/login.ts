import { supabaseAdmin } from '../../lib/supabase';
import { loginSchema, validateBody } from '../../lib/validation';

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
    const body = await req.json();
    const { email, password } = validateBody(loginSchema, body);

    const { data, error } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      return new Response(JSON.stringify({
        error: 'Authentication failed',
        message: error.message,
      }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({
      access_token: data.session?.access_token,
      token_type: 'bearer',
      expires_in: data.session?.expires_in,
      refresh_token: data.session?.refresh_token,
      user: {
        id: data.user?.id,
        email: data.user?.email,
        created_at: data.user?.created_at,
      },
    }), {
      status: 200,
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
