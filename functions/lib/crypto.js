/**
 * PBKDF2 hash and verify utilities using Web Crypto API
 *
 * Parameters:
 * - Salt: 16 bytes, crypto-random
 * - Iterations: 100,000
 * - Hash: SHA-256
 * - Derived key length: 32 bytes
 * - Storage format: base64(salt):iterations:base64(hash)
 */

const ITERATIONS = 100_000;
const SALT_LENGTH = 16;
const KEY_LENGTH = 32;
const HASH_ALGORITHM = 'SHA-256';

/**
 * Hash a password using PBKDF2
 * @param {string} password - Plain text password
 * @returns {Promise<string>} - Formatted as base64(salt):iterations:base64(hash)
 */
export async function hashPassword(password) {
  // Generate random salt
  const salt = crypto.getRandomValues(new Uint8Array(SALT_LENGTH));

  // Import password as key material
  const passwordBuffer = new TextEncoder().encode(password);
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    passwordBuffer,
    'PBKDF2',
    false,
    ['deriveBits']
  );

  // Derive key using PBKDF2
  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: salt,
      iterations: ITERATIONS,
      hash: HASH_ALGORITHM,
    },
    keyMaterial,
    KEY_LENGTH * 8 // bits
  );

  // Convert to base64
  const saltB64 = btoa(String.fromCharCode(...salt));
  const hashB64 = btoa(String.fromCharCode(...new Uint8Array(derivedBits)));

  return `${saltB64}:${ITERATIONS}:${hashB64}`;
}

/**
 * Verify a password against a stored hash
 * @param {string} password - Plain text password to verify
 * @param {string} storedHash - Hash in format base64(salt):iterations:base64(hash)
 * @returns {Promise<boolean>} - True if password matches
 */
export async function verifyPassword(password, storedHash) {
  try {
    // Parse stored hash
    const parts = storedHash.split(':');
    if (parts.length !== 3) {
      return false;
    }

    const [saltB64, iterationsStr, expectedHashB64] = parts;
    const iterations = parseInt(iterationsStr, 10);

    if (isNaN(iterations)) {
      return false;
    }

    // Decode salt from base64
    const saltStr = atob(saltB64);
    const salt = new Uint8Array(saltStr.length);
    for (let i = 0; i < saltStr.length; i++) {
      salt[i] = saltStr.charCodeAt(i);
    }

    // Import password as key material
    const passwordBuffer = new TextEncoder().encode(password);
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      passwordBuffer,
      'PBKDF2',
      false,
      ['deriveBits']
    );

    // Derive key with same parameters
    const derivedBits = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt: salt,
        iterations: iterations,
        hash: HASH_ALGORITHM,
      },
      keyMaterial,
      KEY_LENGTH * 8
    );

    // Convert to base64 and compare
    const actualHashB64 = btoa(String.fromCharCode(...new Uint8Array(derivedBits)));

    return actualHashB64 === expectedHashB64;
  } catch (error) {
    console.error('Password verification error:', error);
    return false;
  }
}
