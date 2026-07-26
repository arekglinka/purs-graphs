---
description: PureScript FFI bindings to @viz-js/viz for Graphviz DOT rendering. Render-only — give it DOT, get SVG.
tags: [purs-viz, ffi, graphviz, viz-js]
---

# purs-viz

## Architecture

- `src/Viz.purs` — raw FFI: opaque `VizInstance`, async `new` via `makeAff`, sync `renderRaw`.
- `src/Viz.js` — JavaScript side of the FFI: async WASM instantiation, sync render call.
- `src/Viz/Render.purs` — idiomatic API: `Engine` ADT, `Either (Array RenderError) String` results.
- `test/Main.purs` — `purescript-spec` + `purescript-quickcheck` tests.

## Build & Test

```bash
spago build -p purs-viz
spago test  -p purs-viz
```

## Public API (publishable)

`Viz.Render` exports: `renderString`, `renderJSON`, `renderSVG`, `Engine`,
`engineToString`, `RenderError`, `RenderOptions`, `defaultRenderOptions`.

`Viz` exports: `VizInstance`, `new`, `renderRaw`, `RenderResultRaw`.

## Gotchas

- **`@viz-js/viz` is a peer-dep**: consumers install `@viz-js/viz@^3.28.0` themselves. Don't bundle it.
- **`new` is async**: it loads the WASM module. Call it once per app lifecycle and reuse the `VizInstance`. Creating one per render is expensive.
- **`renderRaw` is synchronous and never throws**: errors come back as `{ status: "failure", errors: [...] }`. The idiomatic `renderString` maps this to `Either`.
- **viz.js output is a full XML document**: it starts with `<?xml ...?>` and `<!DOCTYPE ...>` before the `<svg>`. To inject the SVG into the DOM via `innerHTML`, strip everything before `<svg` (see `examples/shared/src/Example/Viz.purs` for the `extractSvg` helper).
- **viz.js SVG is opaque to PureScript**: once injected, you can only style its wrapper (e.g. `#svg-container svg { max-width: 100%; }`), not the SVG internals. Graphviz controls the structure (e.g. `<g class="node"><title>NODE_ID</title>...</g>`).
- **Engine support varies by Graphviz build**: all 5 engines (`Dot`, `Neato`, `Circo`, `Fdp`, `Twopi`) work in viz.js 3.x. Other Graphviz engines (`sfdp`, `patchwork`) are not exposed.

## Conventions (overrides root)

- The public API (`Viz.Render` + `Viz`) is publishable. Changes here ripple to consumers — bump the version semantically.
- Keep `_startInstance` and `_render` private (leading underscore). They're not exported.
