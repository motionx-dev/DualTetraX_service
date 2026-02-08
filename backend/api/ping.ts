/**
 * Simple Ping API - No dependencies
 */

export const config = {
  runtime: 'edge',
};

export default async function handler(req: Request) {
  return new Response(JSON.stringify({
    status: 'ok',
    timestamp: new Date().toISOString(),
    message: 'pong'
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}
