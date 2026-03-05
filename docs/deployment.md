# Deployment — ailab.ph

## Overview

| Property | Value |
|----------|-------|
| **Domain** | `ailab.ph` |
| **Hosting** | Cloudflare Pages |
| **Pages Project** | `ailabph` |
| **Repo** | `ailabph/ailabph` (GitHub) |
| **Branch** | `main` |
| **Build command** | (none — static site) |
| **Output directory** | `/` (repo root) |
| **Staging** | `stage.ailab.tools` (GitHub Pages, CNAME file) |

## How Deploys Work

Pushes to `main` trigger the GitHub Action at `.github/workflows/deploy.yml`:

```
push to main → GitHub Actions → wrangler pages deploy . --project-name=ailabph --branch=main → live on ailab.ph
```

The action uses:
- `cloudflare/wrangler-action@v3`
- Secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` (Danny's personal Cloudflare account)

No build step — the repo root is deployed as-is.

## Cloudflare Account

The Pages project lives on **Danny's personal Cloudflare account** (not the `sage.kafra@proton.me` account used for `ailab.tools` Workers/DNS).

To access the Pages dashboard: Cloudflare Dashboard → Pages → `ailabph`

## DNS

`ailab.ph` domain DNS is managed separately from `ailab.tools`. The Cloudflare Pages custom domain is configured in the Pages project settings.

## D1 Database (Blog)

| Property | Value |
|----------|-------|
| **Database name** | `ailabph-blog` |
| **Database ID** | `e85c52ae-095c-48ac-baa6-39490cb0c6e9` |
| **Binding** | `DB` (configured in `wrangler.toml`) |
| **Schema** | `schema.sql` |

The blog system uses Cloudflare Pages Functions (`functions/`) with D1 for server-side rendered blog posts and an admin panel.

### Environment Variables (Production)

Set in Cloudflare Pages → Settings → Environment variables:

- `JWT_SECRET` — strong random string for admin auth
- `ALLOWED_ORIGINS` — `https://ailab.ph,https://www.ailab.ph`

## File Structure

```
index.html              # Main site (single file, ~44KB, HTML + CSS + JS)
admin/index.html        # Blog admin panel (SPA)
functions/              # Cloudflare Pages Functions (blog API + SSR)
  api/auth/             # Auth endpoints (login, logout, me)
  api/posts/            # Posts CRUD
  blog/                 # Server-rendered blog pages
  lib/                  # Shared utils (crypto, jwt, markdown)
schema.sql              # D1 database schema
scripts/                # Dev tools (seeder, test scripts)
wrangler.toml           # Cloudflare config (D1 binding)
CNAME                   # GitHub Pages staging domain (stage.ailab.tools)
.github/workflows/      # CI/CD
  deploy.yml            # Auto-deploy to Cloudflare Pages on push
```

## Contact / CTA

- **CTA email:** `dan@ailab.ph` (in the Contact section of `index.html`)

## Local Development

```bash
# Main site only
python3 -m http.server 8787

# Full stack (with blog + D1)
npx wrangler pages dev . --port 8788 --d1=DB
```

See `README.md` for full local setup instructions including D1 seeding.
