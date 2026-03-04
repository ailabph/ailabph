/**
 * Middleware scoped to /api/posts/* only
 *
 * On GET: pass through (call next())
 * On POST/PUT/DELETE:
 *   - Verify JWT from cookie
 *   - Check Origin header against ALLOWED_ORIGINS env var
 *   - Reject non-application/json Content-Type
 *   - Return 401/403/415 on failure
 */

import { verifyJWT } from '../../lib/jwt.js';
import { parseCookies } from '../../lib/cookies.js';

export async function onRequest(context) {
  const { request, next, env } = context;
  const method = request.method;

  // GET requests pass through without auth
  if (method === 'GET') {
    return next();
  }

  // POST/PUT/DELETE require authentication and validation
  if (method === 'POST' || method === 'PUT' || method === 'DELETE') {
    // 1. Check Content-Type (only for POST/PUT which have request bodies)
    if (method === 'POST' || method === 'PUT') {
      const contentType = request.headers.get('Content-Type') || '';
      if (!contentType.includes('application/json')) {
        return new Response(JSON.stringify({ error: 'Content-Type must be application/json' }), {
          status: 415,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    // 2. Verify JWT
    const cookieHeader = request.headers.get('Cookie');
    const cookies = parseCookies(cookieHeader);
    const token = cookies.token;

    if (!token) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const jwtSecret = env.JWT_SECRET;
    if (!jwtSecret) {
      console.error('JWT_SECRET not configured');
      return new Response(JSON.stringify({ error: 'Server configuration error' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const payload = await verifyJWT(token, jwtSecret);
    if (!payload) {
      return new Response(JSON.stringify({ error: 'Invalid or expired token' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 3. Check Origin header against ALLOWED_ORIGINS
    const origin = request.headers.get('Origin');
    const allowedOrigins = env.ALLOWED_ORIGINS;

    if (origin && allowedOrigins) {
      const allowed = allowedOrigins.split(',').map(o => o.trim());
      if (!allowed.includes(origin)) {
        return new Response(JSON.stringify({ error: 'Origin not allowed' }), {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    // Store authenticated user in context for downstream handlers
    context.user = { username: payload.sub };
  }

  return next();
}
