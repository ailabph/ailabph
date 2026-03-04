/**
 * GET /api/posts - List posts
 * POST /api/posts - Create new post
 */

import { renderMarkdown, slugify } from '../../lib/markdown.js';
import { verifyJWT } from '../../lib/jwt.js';
import { parseCookies } from '../../lib/cookies.js';

const POSTS_PER_PAGE = 20;

/**
 * Check if request is authenticated
 */
async function isAuthenticated(request, env) {
  const cookieHeader = request.headers.get('Cookie');
  const cookies = parseCookies(cookieHeader);
  const token = cookies.token;

  if (!token || !env.JWT_SECRET) {
    return false;
  }

  const payload = await verifyJWT(token, env.JWT_SECRET);
  return !!payload;
}

/**
 * GET /api/posts
 * List published posts (or all posts if ?all=1 with auth)
 * Supports pagination with ?page=N (0-indexed)
 */
export async function onRequestGet(context) {
  const { request, env } = context;

  try {
    const url = new URL(request.url);
    const showAll = url.searchParams.get('all') === '1';
    const page = Math.max(0, parseInt(url.searchParams.get('page')) || 0);
    const offset = page * POSTS_PER_PAGE;

    // Check auth if requesting all posts
    if (showAll) {
      const authed = await isAuthenticated(request, env);
      if (!authed) {
        return new Response(JSON.stringify({ error: 'Authentication required for all=1' }), {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    // Build query
    let query = 'SELECT id, slug, title, excerpt, status, published_at, created_at, updated_at FROM posts';
    const params = [];

    if (!showAll) {
      query += " WHERE status = 'published'";
    }

    query += ' ORDER BY ';
    if (showAll) {
      query += 'updated_at DESC';
    } else {
      query += 'published_at DESC';
    }

    query += ' LIMIT ? OFFSET ?';
    params.push(POSTS_PER_PAGE + 1, offset); // Fetch one extra to check hasMore

    const result = await env.DB.prepare(query).bind(...params).all();

    const hasMore = result.results.length > POSTS_PER_PAGE;
    const posts = result.results.slice(0, POSTS_PER_PAGE);

    return new Response(JSON.stringify({ posts, hasMore }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error listing posts:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

/**
 * POST /api/posts
 * Create new post
 * Required: title, body_md
 * Optional: slug (auto-generated from title if omitted), status (default 'draft'), excerpt
 */
export async function onRequestPost(context) {
  const { request, env } = context;

  try {
    const body = await request.json();
    const { title, body_md, slug: providedSlug, status = 'draft', excerpt } = body;

    // Validate required fields
    if (!title || !body_md) {
      return new Response(JSON.stringify({ error: 'Missing required fields: title, body_md' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Validate status
    if (status !== 'draft' && status !== 'published') {
      return new Response(JSON.stringify({ error: 'Invalid status. Must be draft or published' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Generate or validate slug
    const slug = providedSlug ? slugify(providedSlug) : slugify(title);

    if (!slug) {
      return new Response(JSON.stringify({ error: 'Could not generate valid slug from title' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Check for slug conflict
    const existing = await env.DB.prepare('SELECT id FROM posts WHERE slug = ?').bind(slug).first();
    if (existing) {
      return new Response(JSON.stringify({ error: `Slug '${slug}' already exists` }), {
        status: 409,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Render markdown to HTML
    const body_html = renderMarkdown(body_md);

    // Set published_at if publishing
    const published_at = status === 'published' ? new Date().toISOString() : null;

    // Insert post
    const insertResult = await env.DB.prepare(`
      INSERT INTO posts (slug, title, excerpt, body_md, body_html, status, published_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(slug, title, excerpt || null, body_md, body_html, status, published_at).run();

    // Fetch the created post
    const post = await env.DB.prepare('SELECT * FROM posts WHERE slug = ?').bind(slug).first();

    return new Response(JSON.stringify(post), {
      status: 201,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error creating post:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
