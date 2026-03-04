#!/usr/bin/env node

/**
 * Seed admin user for aiLab.ph blog
 *
 * Usage:
 *   ADMIN_USER=admin ADMIN_PASS=secret node scripts/seed-admin.js | wrangler d1 execute ailabph-blog --local --command=-
 *
 * Reads credentials from env vars or prompts interactively.
 * Outputs SQL INSERT statement to stdout.
 * Never accepts credentials via CLI args (shell history leakage).
 */

import { pbkdf2, randomBytes } from 'node:crypto';
import { promisify } from 'node:util';
import * as readline from 'node:readline/promises';

const pbkdf2Async = promisify(pbkdf2);

// PBKDF2 parameters (match the plan)
const ITERATIONS = 100_000;
const SALT_LENGTH = 16;
const KEY_LENGTH = 32;
const HASH_ALGORITHM = 'sha256';

/**
 * Hash password using PBKDF2
 * @param {string} password
 * @returns {Promise<string>} formatted as base64(salt):iterations:base64(hash)
 */
async function hashPassword(password) {
  const salt = randomBytes(SALT_LENGTH);
  const derivedKey = await pbkdf2Async(
    password,
    salt,
    ITERATIONS,
    KEY_LENGTH,
    HASH_ALGORITHM
  );

  const saltB64 = salt.toString('base64');
  const hashB64 = derivedKey.toString('base64');

  return `${saltB64}:${ITERATIONS}:${hashB64}`;
}

/**
 * Read credentials from env or prompt
 */
async function getCredentials() {
  let username = process.env.ADMIN_USER;
  let password = process.env.ADMIN_PASS;

  // If either is missing, prompt interactively
  if (!username || !password) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stderr, // Prompts go to stderr, SQL goes to stdout
    });

    try {
      if (!username) {
        username = await rl.question('Admin username: ');
      }
      if (!password) {
        password = await rl.question('Admin password: ');
      }
    } finally {
      rl.close();
    }
  }

  if (!username || !password) {
    console.error('Error: Both username and password are required');
    process.exit(1);
  }

  return { username, password };
}

/**
 * Main
 */
async function main() {
  const { username, password } = await getCredentials();
  const passwordHash = await hashPassword(password);

  // Output SQL INSERT statement
  // Use single quotes and escape any single quotes in the data
  const escapedUsername = username.replace(/'/g, "''");
  const escapedHash = passwordHash.replace(/'/g, "''");

  const sql = `INSERT INTO admins (username, password_hash) VALUES ('${escapedUsername}', '${escapedHash}');`;

  console.log(sql);
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
