/**
 * POST /api/auth/login
 *
 * Validates JSON { username, password } against D1 admins table
 * Sets JWT cookie on success
 * Returns { ok: true } or 401
 */

import { verifyPassword } from '../../lib/crypto.js';
import { signJWT } from '../../lib/jwt.js';
import { buildSetCookie } from '../../lib/cookies.js';

export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    // Parse JSON body
    const contentType = request.headers.get('Content-Type') || '';
    if (!contentType.includes('application/json')) {
      return new Response(JSON.stringify({ error: 'Content-Type must be application/json' }), {
        status: 415,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const body = await request.json();
    const { username, password } = body;

    if (!username || !password) {
      return new Response(JSON.stringify({ error: 'Missing username or password' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Query admin from database
    const result = await env.DB.prepare(
      'SELECT username, password_hash FROM admins WHERE username = ?'
    )
      .bind(username)
      .first();

    if (!result) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Verify password
    const valid = await verifyPassword(password, result.password_hash);
    if (!valid) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Generate JWT
    const jwtSecret = env.JWT_SECRET;
    if (!jwtSecret) {
      console.error('JWT_SECRET not configured');
      return new Response(JSON.stringify({ error: 'Server configuration error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const token = await signJWT(username, jwtSecret);

    // Set cookie
    const setCookie = buildSetCookie('token', token, { request });

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Set-Cookie': setCookie,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
