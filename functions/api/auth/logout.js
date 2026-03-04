/**
 * POST /api/auth/logout
 *
 * Clears JWT cookie (Max-Age=0)
 * Returns { ok: true }
 */

import { buildSetCookie } from '../../lib/cookies.js';

export async function onRequestPost(context) {
  const { request } = context;

  // Clear cookie by setting Max-Age=0
  const setCookie = buildSetCookie('token', '', { request, maxAge: 0 });

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Set-Cookie': setCookie,
    },
  });
}
