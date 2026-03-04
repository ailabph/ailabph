/**
 * GET /api/posts/:slug - Get single post
 * PUT /api/posts/:slug - Update post
 * DELETE /api/posts/:slug - Delete post
 */

import { renderMarkdown, slugify } from '../../lib/markdown.js';
import { verifyJWT } from '../../lib/jwt.js';
import { parseCookies } from '../../lib/cookies.js';

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
 * GET /api/posts/:slug
 * Returns single post by slug
 * If draft and not authenticated, returns 404
 */
export async function onRequestGet(context) {
  const { params, request, env } = context;
  const slug = params.slug;

  try {
    const post = await env.DB.prepare('SELECT * FROM posts WHERE slug = ?').bind(slug).first();

    if (!post) {
      return new Response(JSON.stringify({ error: 'Post not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // If draft, require authentication
    if (post.status === 'draft') {
      const authed = await isAuthenticated(request, env);
      if (!authed) {
        return new Response(JSON.stringify({ error: 'Post not found' }), {
          status: 404,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }

    return new Response(JSON.stringify(post), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error fetching post:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

/**
 * PUT /api/posts/:slug
 * Update post
 * Accepts: title, slug, body_md, excerpt, status
 * Re-renders body_html if body_md changed
 * Sets updated_at on every update
 * Publishing logic: sets published_at on first publish only
 */
export async function onRequestPut(context) {
  const { params, request, env } = context;
  const currentSlug = params.slug;

  try {
    const body = await request.json();
    const { title, slug: newSlug, body_md, excerpt, status } = body;

    // Fetch current post
    const post = await env.DB.prepare('SELECT * FROM posts WHERE slug = ?').bind(currentSlug).first();

    if (!post) {
      return new Response(JSON.stringify({ error: 'Post not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Validate status if provided
    if (status && status !== 'draft' && status !== 'published') {
      return new Response(JSON.stringify({ error: 'Invalid status. Must be draft or published' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Build update query
    const updates = [];
    const params = [];

    if (title !== undefined) {
      updates.push('title = ?');
      params.push(title);
    }

    if (excerpt !== undefined) {
      updates.push('excerpt = ?');
      params.push(excerpt);
    }

    if (body_md !== undefined) {
      updates.push('body_md = ?');
      params.push(body_md);
      // Re-render HTML
      const body_html = renderMarkdown(body_md);
      updates.push('body_html = ?');
      params.push(body_html);
    }

    if (status !== undefined) {
      updates.push('status = ?');
      params.push(status);

      // Publishing logic: set published_at only on first publish
      if (status === 'published' && !post.published_at) {
        updates.push('published_at = ?');
        params.push(new Date().toISOString());
      }
      // If unpublishing, keep published_at intact (no update)
    }

    // Handle slug change
    let finalSlug = currentSlug;
    if (newSlug !== undefined && newSlug !== currentSlug) {
      const normalizedSlug = slugify(newSlug);

      if (!normalizedSlug) {
        return new Response(JSON.stringify({ error: 'Invalid slug' }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      // Check for slug conflict
      const existing = await env.DB.prepare('SELECT id FROM posts WHERE slug = ? AND id != ?')
        .bind(normalizedSlug, post.id)
        .first();

      if (existing) {
        return new Response(JSON.stringify({ error: `Slug '${normalizedSlug}' already exists` }), {
          status: 409,
          headers: { 'Content-Type': 'application/json' },
        });
      }

      updates.push('slug = ?');
      params.push(normalizedSlug);
      finalSlug = normalizedSlug;
    }

    // Always update updated_at
    updates.push("updated_at = datetime('now')");

    if (updates.length === 0) {
      // No updates, just return current post
      return new Response(JSON.stringify(post), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Execute update
    params.push(post.id);
    await env.DB.prepare(`
      UPDATE posts SET ${updates.join(', ')} WHERE id = ?
    `).bind(...params).run();

    // Fetch updated post
    const updatedPost = await env.DB.prepare('SELECT * FROM posts WHERE slug = ?').bind(finalSlug).first();

    return new Response(JSON.stringify(updatedPost), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error updating post:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

/**
 * DELETE /api/posts/:slug
 * Delete post
 */
export async function onRequestDelete(context) {
  const { params, env } = context;
  const slug = params.slug;

  try {
    // Check if post exists
    const post = await env.DB.prepare('SELECT id FROM posts WHERE slug = ?').bind(slug).first();

    if (!post) {
      return new Response(JSON.stringify({ error: 'Post not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Delete post
    await env.DB.prepare('DELETE FROM posts WHERE slug = ?').bind(slug).run();

    return new Response(null, {
      status: 204,
    });
  } catch (error) {
    console.error('Error deleting post:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
