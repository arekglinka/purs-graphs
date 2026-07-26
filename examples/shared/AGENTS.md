---
description: Internal helpers (SVG primitives, viz.js FFI, dagre layout runner) shared by example apps. Not published.
tags: [examples, shared, internal]
---

# example-shared

## Architecture

- `src/Example/Svg.purs` — Halogen SVG element helpers (`svgEl`, `svgAttr`).
- `src/Example/DagreRun.purs` — dagre layout runner (`buildAndLayout`, `Position`).
- `src/Example/Viz.purs` + `src/Example/Viz.js` — viz.js output helpers (`extractSvg`, `setInnerHTMLById` FFI).

## Build

`example-shared` builds with the workspace (`spago build` from repo root). No
standalone build is supported — it's a workspace package only.

## Gotchas

- **Not publishable**: this package exists for example-app DRY. Don't depend on it from external code — its API may change freely.
- **`setInnerHTMLById` is intentionally raw**: Halogen has no built-in way to set `innerHTML`. We use a 3-line FFI so we can inject viz.js SVG strings into `#svg-container`.
- **`extractSvg` strips the XML declaration + DOCTYPE**: viz.js output starts with `<?xml ...?>` and `<!DOCTYPE svg ...>` before the actual `<svg>` element. For direct `innerHTML` injection, those leading lines must go (browsers reject DOCTYPE inside a div).
- **`buildAndLayout` returns `Effect`**: it allocates a fresh mutable `Dagre.Graph`, runs layout, and returns the snapshot. Callers don't see the graph itself.

## Conventions (overrides root)

- New shared helpers go here, NOT into the publishable library packages.
- Keep this package small — if a helper is genuinely library-grade, propose it upstream to `purs-dagre` or `purs-viz` instead.
