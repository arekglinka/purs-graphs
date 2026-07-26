---
description: Interactive dagre playground using purs-dagre. Add/remove nodes and edges, switch rank direction, SVG rendered via Halogen HTML DSL.
tags: [example, dagre-demo, halogen, dagre]
---

# dagre-demo

## Architecture

- `src/DagreDemo/Main.purs` — Halogen Hooks component. Two-column layout: controls (left) + canvas (right).
- `src/index.js` — HMR entry. Imports `styles.css` first, then the compiled `output-es/DagreDemo.Main/index.js`.
- `src/styles.css` — Tailwind v4 entry: `@import "tailwindcss"`, `@theme` tokens (brand blue + chip colors), `@layer base` for body, raw CSS for `.canvas-area svg`.
- `index.html` — no `<style>` block. Just `<div id="app">` + script tag.
- `vite.config.ts` — Tailwind plugin + `dagre` alias + `optimizeDeps.include: ["dagre"]`.

## Run

```bash
./scripts/dev.sh dagre-demo   # HMR on http://localhost:5173
# or
spago build -p dagre-demo && cd examples/dagre-demo && npx vite build
```

## Gotchas

- **`canvas-area` class on the canvas div**: this is the hook for the raw CSS rule `.canvas-area svg { max-width: 100%; height: auto; }` in `styles.css`. Don't remove the class.
- **`dagre` is CJS**: Vite needs `optimizeDeps.include: ["dagre"]` to pre-bundle it. Without this, you get `require is not defined` at runtime.
- **`HP.class_` takes `ClassName`, not `String`**: use the `cn = HH.ClassName` helper defined at module level in `Main.purs`.
- **SVG presentation attributes are not Tailwind**: `svgAttr "fill" "#e3f2fd"`, `svgAttr "stroke" "#1976d2"`, `svgAttr "viewBox" "..."`, etc. stay as `svgAttr` calls. They MUST NOT become utility classes.
- **No viz.js in this example**: this app is dagre-only. For DOT rendering, see [`viz-demo`](../viz-demo/).

## Conventions (overrides root)

- The `cn :: String -> HH.ClassName; cn = HH.ClassName` helper is defined at module level in `Main.purs` — use it for all `HP.class_` calls.
- `svgEl` and `svgAttr` come from `Example.Svg` in `example-shared`. Don't redefine them locally.
- `buildAndLayout` and `Position` come from `Example.DagreRun` in `example-shared`.
- `rankDirToString` is exported from `Dagre.Graph` — don't redefine locally.
