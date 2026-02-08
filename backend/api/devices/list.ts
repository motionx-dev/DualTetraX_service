import { createSupabaseClient, extractToken } from '../../lib/supabase';

export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  if (req.method !== 'GET') {
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

    const { data, error } = await supabase
      .from('devices')
      .select('*')
      .eq('user_id', user.id)
      .order('registered_at', { ascending: false });

    if (error) {
      return new Response(JSON.stringify({
        error: 'Database error',
        message: error.message,
      }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify(data || []), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({
      error: 'Internal server error',
      message: err.message,
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
