/**
 * Server-side rendered blog pages
 *
 * Routes:
 * - /blog/ - List of published posts
 * - /blog/?post=slug - Single post view
 * - /blog/?page=N - Pagination
 */

const POSTS_PER_PAGE = 20;

/**
 * Format date to readable string
 */
function formatDate(isoString) {
  if (!isoString) return '';
  const date = new Date(isoString);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

/**
 * Escape HTML for safe output
 */
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}

/**
 * Generate HTML template for blog pages
 */
function generateHTML({ title, description, content, currentUrl = '' }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${escapeHtml(title)}</title>
    <meta name="description" content="${escapeHtml(description)}">
    <meta name="theme-color" content="#000000">
    <link rel="canonical" href="https://ailab.ph${currentUrl}">
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><rect width='32' height='32' rx='6' fill='%23000'/><text x='16' y='22' font-size='18' font-weight='700' fill='%2300d4aa' text-anchor='middle' font-family='sans-serif'>a</text></svg>">
    <link rel="preconnect" href="https://api.fontshare.com" crossorigin>
    <link href="https://api.fontshare.com/v2/css?f[]=satoshi@300,400,500,700,900&display=swap" rel="stylesheet">
    <style>
        /* aiLab.ph — Dark OLED Luxury */
        *, *::before, *::after {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --black: #000000;
            --bg: #050505;
            --bg-card: #0a0a0a;
            --bg-card-hover: #0f0f0f;
            --border: #161616;
            --border-hover: #222222;
            --text: #eeeeee;
            --text-secondary: #808080;
            --text-dim: #4a4a4a;
            --accent: #00d4aa;
            --accent-soft: rgba(0, 212, 170, 0.08);
            --accent-glow: rgba(0, 212, 170, 0.15);
            --accent-bright: #33f0c8;
            --font: 'Satoshi', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            --font-mono: 'SF Mono', 'Fira Code', 'JetBrains Mono', Menlo, Consolas, monospace;
            --max-w: 1120px;
            --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
            --ease-spring: cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        html {
            scroll-behavior: smooth;
            -webkit-text-size-adjust: 100%;
        }

        body {
            font-family: var(--font);
            background: var(--black);
            color: var(--text);
            line-height: 1.7;
            font-size: 16px;
            font-weight: 400;
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        /* Film grain overlay */
        body::after {
            content: '';
            position: fixed;
            inset: 0;
            pointer-events: none;
            z-index: 9999;
            opacity: 0.025;
            background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 512 512' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
            background-size: 256px 256px;
        }

        /* Focus & accessibility */
        :focus { outline: none; }
        :focus-visible {
            outline: 2px solid var(--accent);
            outline-offset: 3px;
            border-radius: 4px;
        }

        /* Nav */
        nav {
            position: sticky;
            top: 0;
            z-index: 100;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(16px);
            border-bottom: 1px solid var(--border);
        }

        .nav-inner {
            max-width: var(--max-w);
            margin: 0 auto;
            padding: 1.25rem 2rem;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .logo {
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--text);
            text-decoration: none;
            letter-spacing: -0.02em;
        }

        .logo span { color: var(--accent); }

        .nav-links {
            list-style: none;
            display: flex;
            gap: 2.5rem;
        }

        .nav-links a {
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 0.9rem;
            font-weight: 500;
            transition: color 0.3s ease;
        }

        .nav-links a:hover,
        .nav-links a.active {
            color: var(--accent);
        }

        /* Main content */
        main {
            max-width: var(--max-w);
            margin: 0 auto;
            padding: 4rem 2rem;
            min-height: 70vh;
        }

        /* Blog header */
        .blog-header {
            margin-bottom: 4rem;
        }

        .blog-header h1 {
            font-size: 3rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            margin-bottom: 1rem;
            background: linear-gradient(135deg, var(--text) 0%, var(--accent-bright) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .blog-header p {
            font-size: 1.1rem;
            color: var(--text-secondary);
        }

        /* Post cards */
        .posts-grid {
            display: grid;
            gap: 1.5rem;
            margin-bottom: 3rem;
        }

        .post-card {
            padding: 2rem;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            text-decoration: none;
            color: inherit;
            display: block;
            transition: all 0.3s var(--ease-out);
            position: relative;
            overflow: hidden;
        }

        .post-card::before {
            content: '';
            position: absolute;
            inset: 0;
            background: radial-gradient(
                600px circle at var(--mouse-x, 50%) var(--mouse-y, 50%),
                var(--accent-soft),
                transparent 50%
            );
            opacity: 0;
            transition: opacity 0.4s ease;
            pointer-events: none;
        }

        .post-card:hover {
            border-color: var(--border-hover);
            transform: translateY(-2px);
            background: var(--bg-card-hover);
        }

        .post-card:hover::before { opacity: 1; }

        .post-meta {
            font-size: 0.85rem;
            color: var(--text-dim);
            margin-bottom: 0.75rem;
            font-family: var(--font-mono);
        }

        .post-card h2 {
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 0.75rem;
            letter-spacing: -0.02em;
        }

        .post-excerpt {
            color: var(--text-secondary);
            font-size: 0.95rem;
            line-height: 1.6;
        }

        /* Single post */
        .post-single {
            max-width: 720px;
            margin: 0 auto;
        }

        .post-single .back-link {
            display: inline-block;
            color: var(--text-secondary);
            text-decoration: none;
            margin-bottom: 2rem;
            font-size: 0.9rem;
            transition: color 0.3s ease;
        }

        .post-single .back-link:hover {
            color: var(--accent);
        }

        .post-single h1 {
            font-size: 2.5rem;
            font-weight: 900;
            letter-spacing: -0.03em;
            margin-bottom: 1rem;
            line-height: 1.2;
        }

        .post-single .post-meta {
            margin-bottom: 3rem;
        }

        .post-content {
            color: var(--text);
            font-size: 1.05rem;
            line-height: 1.8;
        }

        .post-content h1,
        .post-content h2,
        .post-content h3,
        .post-content h4,
        .post-content h5,
        .post-content h6 {
            margin: 2.5rem 0 1rem;
            font-weight: 700;
            letter-spacing: -0.02em;
            line-height: 1.3;
        }

        .post-content h1 { font-size: 2rem; }
        .post-content h2 { font-size: 1.75rem; }
        .post-content h3 { font-size: 1.5rem; }
        .post-content h4 { font-size: 1.25rem; }

        .post-content p {
            margin-bottom: 1.5rem;
        }

        .post-content a {
            color: var(--accent);
            text-decoration: none;
            border-bottom: 1px solid transparent;
            transition: border-color 0.3s ease;
        }

        .post-content a:hover {
            border-bottom-color: var(--accent);
        }

        .post-content code {
            font-family: var(--font-mono);
            font-size: 0.9em;
            background: var(--bg-card);
            padding: 0.2em 0.4em;
            border-radius: 4px;
            color: var(--accent-bright);
        }

        .post-content pre {
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 1.5rem;
            overflow-x: auto;
            margin: 2rem 0;
        }

        .post-content pre code {
            background: none;
            padding: 0;
            color: var(--text);
        }

        .post-content ul,
        .post-content ol {
            margin: 1.5rem 0;
            padding-left: 2rem;
        }

        .post-content li {
            margin-bottom: 0.5rem;
        }

        .post-content blockquote {
            border-left: 3px solid var(--accent);
            padding-left: 1.5rem;
            margin: 2rem 0;
            color: var(--text-secondary);
            font-style: italic;
        }

        .post-content hr {
            border: none;
            border-top: 1px solid var(--border);
            margin: 3rem 0;
        }

        /* Pagination */
        .pagination {
            display: flex;
            justify-content: center;
            gap: 1rem;
            margin-top: 3rem;
        }

        .pagination a,
        .pagination span {
            padding: 0.75rem 1.5rem;
            background: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 8px;
            color: var(--text);
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s ease;
        }

        .pagination a:hover {
            border-color: var(--accent);
            background: var(--bg-card-hover);
        }

        .pagination span {
            color: var(--text-dim);
        }

        /* Footer */
        footer {
            border-top: 1px solid var(--border);
            padding: 3rem 2rem;
            text-align: center;
            color: var(--text-secondary);
            font-size: 0.9rem;
        }

        /* 404 */
        .error-page {
            text-align: center;
            padding: 6rem 2rem;
        }

        .error-page h1 {
            font-size: 4rem;
            font-weight: 900;
            color: var(--accent);
            margin-bottom: 1rem;
        }

        .error-page p {
            font-size: 1.2rem;
            color: var(--text-secondary);
            margin-bottom: 2rem;
        }

        /* Animations */
        .reveal {
            opacity: 0;
            transform: translateY(20px);
            transition: opacity 0.6s var(--ease-out), transform 0.6s var(--ease-out);
        }

        .reveal.visible {
            opacity: 1;
            transform: translateY(0);
        }

        /* No JS fallback */
        noscript .reveal {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }

        /* Responsive */
        @media (max-width: 900px) {
            .nav-links { gap: 1.5rem; }
            .blog-header h1 { font-size: 2.5rem; }
            .post-single h1 { font-size: 2rem; }
        }

        @media (max-width: 680px) {
            .nav-links {
                display: none;
            }
            .blog-header h1 { font-size: 2rem; }
            .post-single h1 { font-size: 1.75rem; }
            main { padding: 2rem 1.5rem; }
        }

        @media (max-width: 480px) {
            .blog-header h1 { font-size: 1.75rem; }
            .post-card { padding: 1.5rem; }
        }

        /* Reduced motion */
        @media (prefers-reduced-motion: reduce) {
            *,
            *::before,
            *::after {
                animation: none !important;
                transition: none !important;
            }
            html { scroll-behavior: auto; }
        }
    </style>
</head>
<body>
    <noscript><style>.reveal { opacity: 1 !important; transform: translateY(0) !important; }</style></noscript>

    <nav>
        <div class="nav-inner">
            <a href="/" class="logo">ai<span>Lab</span>.ph</a>
            <ul class="nav-links">
                <li><a href="/">Home</a></li>
                <li><a href="/blog/" class="active">Blog</a></li>
            </ul>
        </div>
    </nav>

    <main>
        ${content}
    </main>

    <footer>
        <p>&copy; ${new Date().getFullYear()} aiLab.ph. Built in Manila, Philippines.</p>
    </footer>

    <script>
    (function() {
        'use strict';

        // Respect prefers-reduced-motion
        const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        if (!reducedMotion) {
            // Scroll-triggered reveals
            const revealObs = new IntersectionObserver(function (entries) {
                entries.forEach(function (e) {
                    if (e.isIntersecting) {
                        e.target.classList.add('visible');
                        revealObs.unobserve(e.target);
                    }
                });
            }, { threshold: 0.12, rootMargin: '0px 0px -80px 0px' });

            document.querySelectorAll('.reveal').forEach(function (el) {
                revealObs.observe(el);
            });
        } else {
            // Show all reveals immediately
            document.querySelectorAll('.reveal').forEach(function (el) {
                el.classList.add('visible');
            });
        }

        // Mouse-tracking glow for post cards
        document.querySelectorAll('.post-card').forEach(function (card) {
            card.addEventListener('mousemove', function (e) {
                var r = card.getBoundingClientRect();
                card.style.setProperty('--mouse-x', (e.clientX - r.left) + 'px');
                card.style.setProperty('--mouse-y', (e.clientY - r.top) + 'px');
            });
        });
    })();
    </script>
</body>
</html>`;
}

/**
 * Render post listing page
 */
function renderPostList(posts, page, hasMore) {
  const postCards = posts.map(post => `
    <a href="/blog/?post=${escapeHtml(post.slug)}" class="post-card reveal">
        <div class="post-meta">${formatDate(post.published_at)}</div>
        <h2>${escapeHtml(post.title)}</h2>
        ${post.excerpt ? `<p class="post-excerpt">${escapeHtml(post.excerpt)}</p>` : ''}
    </a>
  `).join('');

  const pagination = [];
  if (page > 0) {
    pagination.push(`<a href="/blog/?page=${page - 1}">← Previous</a>`);
  } else {
    pagination.push(`<span>← Previous</span>`);
  }

  if (hasMore) {
    pagination.push(`<a href="/blog/?page=${page + 1}">Next →</a>`);
  } else {
    pagination.push(`<span>Next →</span>`);
  }

  const content = `
    <div class="blog-header">
        <h1>Blog</h1>
        <p>Thoughts on software, security, and building at scale.</p>
    </div>

    <div class="posts-grid">
        ${postCards || '<p class="post-card">No posts yet.</p>'}
    </div>

    ${posts.length > 0 ? `<div class="pagination">${pagination.join('')}</div>` : ''}
  `;

  return generateHTML({
    title: 'Blog — aiLab.ph',
    description: 'Thoughts on software, security, and building at scale from the aiLab.ph team.',
    content,
    currentUrl: '/blog/'
  });
}

/**
 * Render single post page
 */
function renderPost(post) {
  const content = `
    <div class="post-single">
        <a href="/blog/" class="back-link">← Back to all posts</a>

        <article>
            <h1>${escapeHtml(post.title)}</h1>
            <div class="post-meta">${formatDate(post.published_at)}</div>

            <div class="post-content">
                ${post.body_html}
            </div>
        </article>
    </div>
  `;

  return generateHTML({
    title: `${post.title} — aiLab.ph Blog`,
    description: post.excerpt || post.title,
    content,
    currentUrl: `/blog/?post=${post.slug}`
  });
}

/**
 * Render 404 page
 */
function render404() {
  const content = `
    <div class="error-page">
        <h1>404</h1>
        <p>Post not found.</p>
        <a href="/blog/" style="color: var(--accent); text-decoration: none;">← Back to blog</a>
    </div>
  `;

  return generateHTML({
    title: '404 — Post Not Found',
    description: 'The post you are looking for does not exist.',
    content,
    currentUrl: '/blog/'
  });
}

/**
 * Handle blog requests
 */
export async function onRequestGet(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const postSlug = url.searchParams.get('post');
  const page = parseInt(url.searchParams.get('page') || '0', 10);

  try {
    // Single post view
    if (postSlug) {
      const post = await env.DB.prepare(
        "SELECT * FROM posts WHERE slug = ? AND status = 'published'"
      ).bind(postSlug).first();

      if (!post) {
        return new Response(render404(), {
          status: 404,
          headers: { 'Content-Type': 'text/html; charset=utf-8' }
        });
      }

      return new Response(renderPost(post), {
        status: 200,
        headers: { 'Content-Type': 'text/html; charset=utf-8' }
      });
    }

    // Post listing
    const offset = page * POSTS_PER_PAGE;
    const result = await env.DB.prepare(`
      SELECT id, slug, title, excerpt, published_at
      FROM posts
      WHERE status = 'published'
      ORDER BY published_at DESC
      LIMIT ? OFFSET ?
    `).bind(POSTS_PER_PAGE + 1, offset).all();

    const hasMore = result.results.length > POSTS_PER_PAGE;
    const posts = result.results.slice(0, POSTS_PER_PAGE);

    return new Response(renderPostList(posts, page, hasMore), {
      status: 200,
      headers: { 'Content-Type': 'text/html; charset=utf-8' }
    });
  } catch (error) {
    console.error('Blog page error:', error);
    return new Response('Internal Server Error', {
      status: 500,
      headers: { 'Content-Type': 'text/plain' }
    });
  }
}
