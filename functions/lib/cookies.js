/**
 * Cookie helper to build Set-Cookie header
 *
 * Attributes:
 * - HttpOnly: always
 * - Secure: true when request URL scheme is https, omitted on http (local dev)
 * - SameSite: Strict
 * - Path: /
 * - Max-Age: 86400 (24 hours) or custom
 */

const DEFAULT_MAX_AGE = 86400; // 24 hours

/**
 * Build Set-Cookie header value
 * @param {string} name - Cookie name
 * @param {string} value - Cookie value
 * @param {object} options - Cookie options
 * @param {Request} options.request - Request object to determine scheme
 * @param {number} options.maxAge - Max-Age in seconds (default 86400)
 * @returns {string} - Set-Cookie header value
 */
export function buildSetCookie(name, value, options = {}) {
  const { request, maxAge = DEFAULT_MAX_AGE } = options;

  const parts = [`${name}=${value}`];

  // Max-Age
  parts.push(`Max-Age=${maxAge}`);

  // HttpOnly (always)
  parts.push('HttpOnly');

  // SameSite (always Strict)
  parts.push('SameSite=Strict');

  // Path (always /)
  parts.push('Path=/');

  // Secure (only on https)
  if (request) {
    const url = new URL(request.url);
    if (url.protocol === 'https:') {
      parts.push('Secure');
    }
  }

  return parts.join('; ');
}

/**
 * Parse cookies from Cookie header
 * @param {string|null} cookieHeader - Cookie header value
 * @returns {Record<string, string>} - Parsed cookies
 */
export function parseCookies(cookieHeader) {
  const cookies = {};
  if (!cookieHeader) {
    return cookies;
  }

  cookieHeader.split(';').forEach(cookie => {
    const [name, ...rest] = cookie.trim().split('=');
    if (name) {
      cookies[name] = rest.join('=');
    }
  });

  return cookies;
}
