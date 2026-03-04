/**
 * JWT sign and verify using Web Crypto HMAC-SHA256
 *
 * Token payload: { sub: username, iat, exp }
 * Expiry: 24 hours
 */

const EXPIRY_SECONDS = 86400; // 24 hours

/**
 * Base64URL encode (URL-safe base64 without padding)
 */
function base64urlEncode(data) {
  const base64 = btoa(String.fromCharCode(...new Uint8Array(data)));
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

/**
 * Base64URL decode
 */
function base64urlDecode(str) {
  // Add padding back
  str = str.replace(/-/g, '+').replace(/_/g, '/');
  while (str.length % 4) {
    str += '=';
  }
  const decoded = atob(str);
  const bytes = new Uint8Array(decoded.length);
  for (let i = 0; i < decoded.length; i++) {
    bytes[i] = decoded.charCodeAt(i);
  }
  return bytes;
}

/**
 * Import HMAC key from secret
 */
async function importKey(secret) {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  return await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

/**
 * Sign a JWT
 * @param {string} username - Username to encode in token
 * @param {string} secret - JWT secret from env
 * @returns {Promise<string>} - JWT token
 */
export async function signJWT(username, secret) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    sub: username,
    iat: now,
    exp: now + EXPIRY_SECONDS,
  };

  // Create header and payload
  const header = { alg: 'HS256', typ: 'JWT' };
  const encoder = new TextEncoder();

  const headerB64 = base64urlEncode(encoder.encode(JSON.stringify(header)));
  const payloadB64 = base64urlEncode(encoder.encode(JSON.stringify(payload)));

  const message = `${headerB64}.${payloadB64}`;

  // Sign with HMAC-SHA256
  const key = await importKey(secret);
  const messageData = encoder.encode(message);
  const signature = await crypto.subtle.sign('HMAC', key, messageData);
  const signatureB64 = base64urlEncode(signature);

  return `${message}.${signatureB64}`;
}

/**
 * Verify and decode a JWT
 * @param {string} token - JWT token
 * @param {string} secret - JWT secret from env
 * @returns {Promise<object|null>} - Decoded payload or null if invalid
 */
export async function verifyJWT(token, secret) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }

    const [headerB64, payloadB64, signatureB64] = parts;
    const message = `${headerB64}.${payloadB64}`;

    // Verify signature
    const key = await importKey(secret);
    const encoder = new TextEncoder();
    const messageData = encoder.encode(message);
    const signature = base64urlDecode(signatureB64);

    const valid = await crypto.subtle.verify('HMAC', key, signature, messageData);
    if (!valid) {
      return null;
    }

    // Decode payload
    const payloadBytes = base64urlDecode(payloadB64);
    const payloadStr = new TextDecoder().decode(payloadBytes);
    const payload = JSON.parse(payloadStr);

    // Check expiry
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return null;
    }

    return payload;
  } catch (error) {
    console.error('JWT verification error:', error);
    return null;
  }
}
