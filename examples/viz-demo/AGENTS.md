---
description: Interactive DOT playground using purs-viz. Edit DOT, switch engines, see SVG re-render live.
tags: [example, viz-demo, halogen, viz-js]
---

# viz-demo

## Architecture

- `src/VizDemo/Main.purs` — Halogen Hooks component. Single page: header + controls + canvas.
- `src/index.js` — HMR entry. Imports `styles.css` first, then the compiled `output-es/VizDemo.Main/index.js`.
- `src/styles.css` — Tailwind v4 entry: `@import "tailwindcss"`, `@theme` tokens (brand green), `@layer base` for body, raw CSS for `#svg-container svg`.
- `index.html` — no `<style>` block. Just `<div id="app">` + script tag.
- `vite.config.ts` — Tailwind plugin + `@viz-js/viz` alias + `optimizeDeps.include`.

## Run

```bash
./scripts/dev.sh viz-demo   # HMR on http://localhost:5174
# or
spago build -p viz-demo && cd examples/viz-demo && npx vite build
```

## Gotchas

- **`HP.id "svg-container"` is an FFI contract**: `setInnerHTMLById` (from `example-shared`) injects the viz.js SVG string into the element with that exact id. Don't rename it.
- **DOT fontname quoting**: when writing DOT source that includes `fontname="sans-serif"`, the quotes inside the string must be escaped properly. See the `initialDot` value in `Main.purs`.
- **viz.js SVG is opaque**: the injected SVG can only be styled via the wrapper (`#svg-container svg { max-width: 100%; }` in `styles.css`). PureScript-side styling of viz.js SVG internals is impossible.
- **Tailwind v4 auto-scans `.purs` files**: the `HP.class_ (cn "...")` string literals are detected as plain text and turned into utilities. No `content:` config needed.
- **No DAGRE in this example**: this app is viz-only. For dagre, see [`dagre-demo`](../dagre-demo/).
- **Tailwind peer-dep**: this example's `package.json` lists `tailwindcss` + `@tailwindcss/vite` as devDeps so it can be built in isolation.

## Conventions (overrides root)

- The `cn :: String -> HH.ClassName; cn = HH.ClassName` helper is defined at module level in `Main.purs` — use it for all `HP.class_` calls.
- SVG presentation attributes (`fill`, `stroke`, `viewBox`, etc.) stay as `svgAttr` calls. They are NOT Tailwind candidates.
