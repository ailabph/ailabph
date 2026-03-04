# aiLab.ph

Website and blog for [aiLab.ph](https://ailab.ph) — a software development company founded in 2018 in Manila, Philippines.

## Stack

**Main Site:**
- Pure HTML + CSS + vanilla JS
- Single `index.html` file (~44KB)
- Zero build step, zero dependencies

**Blog System:**
- Cloudflare Pages Functions (server-side rendering)
- Cloudflare D1 (SQLite database)
- PBKDF2 auth, JWT sessions, markdown rendering
- Admin panel (SPA with live preview)

**Common:**
- Font: [Satoshi](https://www.fontshare.com/fonts/satoshi) via fontshare CDN
- Dark OLED aesthetic throughout

## Development

### Main Site Only

```bash
python3 -m http.server 8787
# open http://localhost:8787
```

### Blog System (Full Stack)

**1. Install Wrangler (Cloudflare CLI)**

```bash
npm install -g wrangler
# or use npx wrangler for one-off commands
```

**2. Create D1 Database**

```bash
# Create database (production)
npx wrangler d1 create ailabph-blog

# Update wrangler.toml with the database_id returned above
```

**3. Apply Database Schema**

```bash
# Local database
npx wrangler d1 execute ailabph-blog --local --file=schema.sql

# Production database (when ready)
npx wrangler d1 execute ailabph-blog --file=schema.sql
```

**4. Seed Admin User**

```bash
# Generate SQL for admin user
ADMIN_USER=admin ADMIN_PASS=yourpassword node scripts/seed-admin.js > /tmp/seed.sql

# Apply to local database
npx wrangler d1 execute ailabph-blog --local --file=/tmp/seed.sql

# Apply to production (when ready)
npx wrangler d1 execute ailabph-blog --file=/tmp/seed.sql
```

**5. Configure Environment Variables**

Create `.dev.vars` file for local development:

```env
JWT_SECRET=dev-secret-change-in-production
ALLOWED_ORIGINS=http://localhost:8788,http://localhost:8787,http://127.0.0.1:8788
```

For production, set these in Cloudflare Pages dashboard:
- Go to Pages project → Settings → Environment variables
- Add `JWT_SECRET` (generate a strong random string)
- Add `ALLOWED_ORIGINS` (your production domains)

**6. Start Development Server**

```bash
npx wrangler pages dev . --port 8788 --d1=DB

# open http://localhost:8788
# Main site: http://localhost:8788
# Blog: http://localhost:8788/blog/
# Admin: http://localhost:8788/admin/
```

**7. Run Tests**

```bash
# Ensure dev server is running on port 8788

# End-to-end test suite
./scripts/test-e2e.sh http://localhost:8788

# Individual milestone tests
./scripts/test-milestone2.sh http://localhost:8788  # Auth API
./scripts/test-milestone3.sh http://localhost:8788  # Posts CRUD
./scripts/test-milestone4.sh http://localhost:8788  # Blog Pages
./scripts/test-milestone5.sh http://localhost:8788  # Admin Panel
```

## Deploy

### Cloudflare Pages

**Initial Setup:**

1. Create D1 database in Cloudflare dashboard or via CLI:
   ```bash
   npx wrangler d1 create ailabph-blog
   ```

2. Update `wrangler.toml` with the `database_id` from step 1

3. Apply schema to production database:
   ```bash
   npx wrangler d1 execute ailabph-blog --file=schema.sql
   ```

4. Seed admin user in production:
   ```bash
   ADMIN_USER=admin ADMIN_PASS=strong-password node scripts/seed-admin.js > /tmp/seed.sql
   npx wrangler d1 execute ailabph-blog --file=/tmp/seed.sql
   rm /tmp/seed.sql  # Clean up
   ```

**Cloudflare Pages Setup:**

1. Connect this repo to Cloudflare Pages
2. Build command: (none)
3. Output directory: `/`
4. Add D1 binding:
   - Go to Pages project → Settings → Functions
   - Add D1 database binding: `DB` → `ailabph-blog`
5. Set environment variables:
   - `JWT_SECRET`: Generate a strong random string (32+ characters)
   - `ALLOWED_ORIGINS`: Your production domains (comma-separated)

   Example:
   ```
   JWT_SECRET=your-production-secret-here
   ALLOWED_ORIGINS=https://ailab.ph,https://www.ailab.ph
   ```

### Any static host / VPS

Just serve `index.html`. No build step required.
With nginx:

```nginx
server {
    listen 80;
    server_name ailab.ph;
    root /var/www/ailab.ph;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

## Design

- **Aesthetic:** Dark OLED Luxury
- **Background:** True black (`#000000`)
- **Accent:** Teal (`#00d4aa`)
- **Font:** Satoshi (fontshare.com)

## Accessibility

- All content renders without JavaScript (`<noscript>` fallback)
- Semantic HTML with proper landmarks (`<nav>`, `<main>`, `<footer>`)
- Skip-to-content link
- `prefers-reduced-motion` support
- `focus-visible` keyboard navigation styles
- WCAG AA contrast compliance
