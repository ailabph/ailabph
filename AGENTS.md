# AGENTS.md

This repository is a static, single-page marketing site for aiLab.ph.

- Stack: pure HTML + CSS + vanilla JS
- No build step, no dependencies, no framework
- Primary artifact: `index.html` (contains HTML + `<style>` + `<script>`)
- External resources: Satoshi font via fontshare CDN (keep this minimal)

## Commands (Build / Lint / Test)

### Local development (recommended)

Serve the repo root and open the site:

```bash
python3 -m http.server 8787
# open http://localhost:8787
```

### Build

- Build command: (none)
- Output directory: `/` (repo root)

### Lint

- No repo-provided linting/formatting commands.
- Do not introduce a mandatory lint/build toolchain unless explicitly asked.

Optional (only if you already have the tools installed):

```bash
# Format / normalize HTML/CSS/JS (optional; not in repo)
npx prettier --check index.html
npx prettier -w index.html
```

### Tests

- No automated test suite in the current codebase.
- "Single test" does not apply yet.

Manual smoke checks (fast, high-signal):

1. Load the page with JS enabled and verify: hero entrance, reveal-on-scroll, nav active state.
2. Load the page with JS disabled and verify all content is visible (noscript fallback).
3. Toggle `prefers-reduced-motion` and confirm animations/transitions are disabled.
4. Mobile breakpoints: 900px, 680px, 480px; ensure layout remains intentional.
5. Keyboard navigation: skip link, focus-visible outlines, no focus traps.

If you add a test harness later, prefer Playwright for end-to-end checks.

```bash
# Example Playwright usage (only if Playwright is added)
npx playwright test
npx playwright test -g "nav"          # run a single test by name/grep
npx playwright test tests/home.spec.ts # run a single spec file
```

## Deployment / CI

- CI deploys on pushes to `main` via `.github/workflows/deploy.yml`.
- Cloudflare Pages deploy command used in CI:

```bash
wrangler pages deploy . --project-name=ailabph --branch=main
```

Notes:

- Repo has `CNAME` (currently `stage.ailab.tools`); keep it consistent with the target.
- Avoid adding runtime secrets to the repo; use Cloudflare environment variables.

## Code Organization

Everything user-facing must work without JavaScript.

- HTML: semantic structure with landmarks (`<nav>`, `<main>`, `<footer>`).
- CSS: single `<style>` block in `index.html`.
- JS: single `<script>` at end of body; used for progressive enhancement only.

When adding new pages/features, default to the same "no-build" approach (plain HTML/CSS/JS).

## Naming Conventions

- Files: keep top-level pages as `index.html`; if adding pages, use directory-based routing (e.g. `blog/index.html`).
- HTML ids: kebab-case (e.g. `track-record`); keep anchors stable.
- HTML `data-*`: kebab-case (e.g. `data-count`, `data-suffix`); treat values as strings in JS.
- CSS: custom properties `--kebab-case`; classes `kebab-case`.
- JS: variables/functions `camelCase`; constants `SCREAMING_SNAKE_CASE`.

## HTML Style Guidelines

- Keep content in static HTML; JS may only enhance interactions/visual polish.
- Prefer semantic elements over div soup; only add ARIA when semantics are insufficient.
- IDs: kebab-case (e.g. `track-record`); use IDs primarily for section anchors.
- Links/buttons:
  - Use `<a>` for navigation, `<button>` for actions.
  - Ensure keyboard operability and visible focus.
- Meta:
  - Keep `title`, `description`, canonical, and OG tags accurate.
  - Avoid adding third-party trackers/scripts.

## CSS Style Guidelines

- Tokens live in `:root` as CSS custom properties; extend there before hardcoding.
- Prefer variables for colors, spacing, easing, and repeated values.
- Class names: lowercase with hyphens (e.g. `.nav-links`, `.build-item`).
- Keep responsive breakpoints aligned with the existing ones:
  - `900px` (layout collapse), `680px` (nav links hidden), `480px` (mobile).
- Respect reduced motion:
  - Any new animations/transitions must be disabled under `prefers-reduced-motion: reduce`.
- Keep the current aesthetic ("Dark OLED Luxury") consistent unless the task says otherwise.

Formatting:

- Indentation matches existing file (4 spaces).
- Keep section headers/comments consistent with surrounding style.
- Avoid introducing new non-ASCII characters unless the file section already uses them.

## JavaScript Style Guidelines

- Progressive enhancement only: the page must remain readable/usable with JS off.
- Keep code inline in `index.html` (no `import`, no bundler assumptions).
- Avoid external JS dependencies; if you must add one, justify it and keep payload small.
- Prefer simple DOM APIs and feature detection.
- Style matches current script:
  - IIFE wrapper + `'use strict';`
  - `var` + function expressions are acceptable and consistent here.
  - Guard DOM queries (`if (el) { ... }`) and avoid throwing.
- Types: there is no TypeScript; parse/validate inputs explicitly (e.g. `parseInt(value, 10)`), and handle `NaN`.
- Avoid noisy logging; no `console.log` in production code.

## Error Handling / Resilience

- Treat browser APIs as optional (e.g. `IntersectionObserver`):
  - Feature-detect and fall back to "everything visible" behavior.
- Never block rendering on JS.
- When reading `data-*` attributes, validate/parse defensively.

## Accessibility Requirements

- Keep the skip-to-content link working.
- Preserve and extend `:focus-visible` styling (do not remove focus outlines).
- Maintain WCAG AA contrast; test new colors against the black background.
- Ensure interactive components are usable via keyboard and screen readers.

## Performance / Privacy

- Keep external requests minimal (currently just the font CSS).
- Prefer CSS effects over heavy assets; avoid large images unless required.
- Do not add analytics, trackers, or fingerprinting scripts.

## Existing Repo Rules To Preserve

From `CLAUDE.md` and `README.md`:

- No build step; deploy as static assets.
- Content renders without JS; `<noscript>` keeps reveal elements visible.
- `prefers-reduced-motion` disables animations and transitions.
- Keep the core tokens in `:root` (`--black`, `--bg`, `--accent`, `--text`, `--font`, `--max-w`).

## Cursor / Copilot Instructions

- No Cursor rules found (no `.cursor/rules/` and no `.cursorrules`).
- No Copilot instructions found (no `.github/copilot-instructions.md`).
