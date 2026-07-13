# UtilityKit Documentation Site (`docs-site/`)

The canonical documentation site for UtilityKit. A React + Vite + Tailwind
single-page app that inlines to one self-contained HTML file, then ships to
GitHub Pages.

## Stack

- **React 19** + **React Router 7** (HashRouter — subpath agnostic)
- **Vite 7** with `vite-plugin-singlefile` — bundles JS + CSS + assets into a
  single `dist/index.html`
- **Tailwind CSS 4** with a semantic design-token system (`src/index.css`)
- **framer-motion** for micro-interactions and layout transitions
- **@phosphor-icons/react** — SVG icon set (no emojis)
- **Theme**: system-based light/dark with manual override; anti-flash inline
  script in `index.html`

## Scripts

```sh
npm install               # first time only
npm run dev               # local dev server with HMR (http://localhost:5173)
npm run typecheck         # tsc --noEmit
npm run build             # emit dist/index.html
npm run preview           # serve the built bundle
npm run deploy:docs       # build + copy dist/index.html → ../docs/index.html
```

## Deployment

Two paths, both supported:

### 1. GitHub Actions (recommended)

`.github/workflows/pages.yml` builds this app on every push to `master` that
touches `docs-site/` or `docs/`, then publishes the bundle via
`actions/deploy-pages`. Enable it in **Settings → Pages → Source: GitHub
Actions**.

### 2. Serving `/docs` directly

Some setups configure Pages to serve `/docs` from the branch. To refresh that
copy locally:

```sh
cd docs-site
npm run deploy:docs
git add ../docs/index.html ../docs/.nojekyll
git commit -m "docs: publish docs-site build"
git push
```

The `docs/.nojekyll` marker prevents Jekyll from processing the bundle.

## Architecture notes

- `src/index.css` — design tokens (`--bg`, `--text`, `--accent`, ...) driven by
  a `.dark` class on `<html>`. Add new tokens here, never per-component.
- `src/components/ThemeProvider.tsx` — manages `system | light | dark`, persists
  to `localStorage` (`uk-theme`), listens to `matchMedia`.
- `src/components/BackgroundCanvas.tsx` — animated aurora + grid + noise layer.
- `src/data/tools.ts` — the tool registry mirrored from the Bash source. Keep
  this in sync when adding a new tool to `modules/`.

## Local single-file test

```sh
npm run build
python3 -m http.server 8000 --directory dist
# open http://localhost:8000
```

The output works from any subpath (`vite.config.ts` sets `base: './'`).
