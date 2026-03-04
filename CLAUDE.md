# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

aiLab.ph website with blog system. Main site is pure HTML + CSS + vanilla JS in `index.html`. Blog system uses Cloudflare Pages Functions + D1 database for server-side rendering and content management. No build step, minimal dependencies.

## Development

### Main Site (Static)

```bash
python3 -m http.server 8787
# open http://localhost:8787
```

### Blog System (with D1 and Functions)

```bash
# Set up local database
npx wrangler d1 execute ailabph-blog --local --file=schema.sql

# Seed admin user
ADMIN_USER=admin ADMIN_PASS=yourpass node scripts/seed-admin.js > /tmp/seed.sql
npx wrangler d1 execute ailabph-blog --local --file=/tmp/seed.sql

# Start dev server with D1
npx wrangler pages dev . --port 8788 --d1=DB

# open http://localhost:8788
```

Environment variables (create `.dev.vars` file):
```
JWT_SECRET=dev-secret-change-in-production
ALLOWED_ORIGINS=http://localhost:8788,http://localhost:8787,http://127.0.0.1:8788
```

## Architecture

### Main Site (`index.html`)

Everything lives in `index.html`:
- `<style>` block: All CSS, including responsive breakpoints and animations
- HTML body: Semantic markup with `<nav>`, `<main>`, `<footer>` landmarks
- `<script>` block at end of body: Intersection Observer animations, nav tracking, counter animations, mouse-tracking glow

### Blog System

**Server-Side Rendered (Cloudflare Pages Functions):**
- `/blog/` — Post listing (published posts only)
- `/blog/?post=slug` — Single post view
- `/blog/?page=N` — Pagination
- Server renders full HTML, works without JavaScript
- Progressive enhancement: JS adds scroll animations and hover effects

**API Endpoints (Cloudflare Pages Functions):**
- `/api/auth/login` — POST: authenticate admin
- `/api/auth/logout` — POST: clear session
- `/api/auth/me` — GET: check auth status
- `/api/posts` — GET: list posts, POST: create post
- `/api/posts/:slug` — GET: single post, PUT: update, DELETE: delete

**Admin Panel (`admin/index.html`):**
- Single-page application (JavaScript required)
- Authentication via JWT cookies
- CRUD operations for blog posts
- Live markdown preview
- Matches site aesthetic

**Database (Cloudflare D1):**
- `admins` — Username + PBKDF2 hashed password
- `posts` — Title, slug, body (markdown + HTML), status, dates

**File Structure:**
```
index.html              # Main site
admin/index.html        # Admin panel SPA
functions/
  api/
    auth/               # Auth endpoints
    posts/              # Posts CRUD + middleware
  blog/                 # Server-rendered blog pages
  lib/                  # Shared utilities (crypto, jwt, markdown, cookies)
schema.sql             # Database schema
scripts/
  seed-admin.js        # Admin user seeder
  test-*.sh            # Test suites
wrangler.toml          # Cloudflare config
```

## Key Constraints

- **Content must render without JS.** All text is in static HTML. JS only adds visual polish (scroll animations, counters, hover effects). A `<noscript>` block ensures `.reveal` elements are visible when JS is disabled.
- **No external dependencies** except the Satoshi font from fontshare CDN. Everything else is self-contained.
- **`prefers-reduced-motion`** is respected — all animations and transitions are disabled.
- **Deploy target:** Cloudflare Pages or any static host. No build step.

## CSS Custom Properties

All colors and tokens are in `:root` — edit there to change the theme. Key vars: `--black`, `--bg`, `--accent`, `--text`, `--font`, `--max-w`.

## Responsive Breakpoints

- `900px`: Cards collapse to single column, approach grid to 2-col
- `680px`: Nav links hidden
- `480px`: Mobile layout, hero height auto
