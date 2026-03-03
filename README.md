# aiLab.ph

Single-page website for [aiLab.ph](https://ailab.ph) — a software development company founded in 2018 in Manila, Philippines.

## Stack

- Pure HTML + CSS + vanilla JS
- Zero build step, zero dependencies
- Single `index.html` file (~44KB)
- Font: [Satoshi](https://www.fontshare.com/fonts/satoshi) via fontshare CDN

## Development

```bash
python3 -m http.server 8787
# open http://localhost:8787
```

## Deploy

### Cloudflare Pages

1. Connect this repo to Cloudflare Pages
2. Build command: (none)
3. Output directory: `/`

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
