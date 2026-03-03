# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Single-page website for aiLab.ph. Pure HTML + CSS + vanilla JS in a single `index.html` file. No build step, no dependencies, no framework.

## Development

```bash
python3 -m http.server 8787
# open http://localhost:8787
```

## Architecture

Everything lives in `index.html`:
- `<style>` block: All CSS, including responsive breakpoints and animations
- HTML body: Semantic markup with `<nav>`, `<main>`, `<footer>` landmarks
- `<script>` block at end of body: Intersection Observer animations, nav tracking, counter animations, mouse-tracking glow

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
