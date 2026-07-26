---
description: ByteByteGo-style 8-diagram showcase using both purs-dagre and purs-viz. Library toggle, click-to-detail, 3-column app shell.
tags: [example, showcase, halogen, dagre, viz-js]
---

# showcase

## Architecture

- `src/Showcase/Main.purs` — Halogen Hooks component. 3-column app shell: topbar + sidebar + canvas + detail-panel.
- `src/Showcase/Main.js` — FFI: `getClickedNodeId` (walks `<g class="node"><title>` produced by Graphviz). `setInnerHTMLById` was MOVED to `example-shared` — don't add it back here.
- `src/Showcase/Diagrams.purs` — 8 `DiagramSpec` records: nodes/edges (dagre), DOT source (viz), `nodeInfo` map (click details).
- `src/index.js` — HMR entry. Imports `styles.css` first, then compiled `output-es/Showcase.Main/index.js`.
- `src/styles.css` — Tailwind v4 entry: `@import "tailwindcss"`, `@theme` tokens (brand/surface/sidebar slate/node categories), `@layer base` for full-viewport body, raw CSS for `.canvas-dots` dotted background + `#svg-container svg` sizing.
- `index.html` — no `<style>` block.
- `vite.config.ts` — Tailwind plugin + aliases to `../../node_modules/{dagre,@viz-js/viz}` (showcase has no local `node_modules` for them — they're hoisted to root).

## Run

```bash
./scripts/dev.sh showcase   # HMR on http://localhost:5175
# or
spago build -p showcase && cd examples/showcase && npx vite build
```

## Gotchas

- **`HP.id "svg-container"` is an FFI contract**: `setInnerHTMLById` (from `example-shared`) injects viz.js SVG into this element. The `getClickedNodeId` FFI also walks UP from click targets to find this wrapper. Don't rename it.
- **`getClickedNodeId` walks `<g class="node"><title>`**: this DOM structure is produced by Graphviz. If you change the DOT source shape (e.g. use HTML-like labels, remove `<title>` emission), the click handler will silently break. Re-verify with Playwright after DOT changes.
- **Always-render `#svg-container` div**: it's in the DOM permanently (hidden via Tailwind `hidden`/`flex` class swap when in Dagre mode) so that `setInnerHTMLById` always finds the element. Don't conditionally mount/unmount it.
- **Two render modes share state**: clicking a diagram in the sidebar triggers both a dagre `buildAndLayout` AND a viz `renderString` (to `#svg-container`). This keeps both views current regardless of which mode is active, so toggling is instant.
- **DOT colors live in `Diagrams.purs`, NOT CSS**: the Material 100 palette (`#bbdefb`, `#ffe0b2`, `#c8e6c9`, `#f8bbd0`, `#e1bee7`) appears as `fillcolor=` attributes in DOT source. These are Graphviz-rendered, not Tailwind. The legend swatches in the UI mirror these via `HP.style "background:..."` (data-driven, kept as inline style).
- **`canvas-dots` class on the canvas body div** is the hook for the dotted background raw CSS in `styles.css`. Don't remove the class.
- **Dynamic class concatenation**: the 3 active-state classes (`toggle-btn` active, `sidebar-item` active) use a conditional helper. Use a single `cn` call with a pre-built string — don't try to use `HP.classes` (array) for active/inactive.
- **Tailwind v4 auto-scans `.purs` files**: the `HP.class_ (cn "...")` string literals are detected as plain text and turned into utilities. No `content:` config needed.
- **`web-events` polymorphic FFI**: `getClickedNodeId :: forall event. event -> String` accepts any event object — avoids the `web-uievents` dependency. Don't specialize the type to `MouseEvent` (would force an extra dep).

## Conventions (overrides root)

- The `cn :: String -> HH.ClassName; cn = HH.ClassName` helper is defined at module level in `Main.purs` — use it for all `HP.class_` calls.
- `svgEl`, `svgAttr` come from `Example.Svg`. `buildAndLayout`, `Position` from `Example.DagreRun`. `setInnerHTMLById`, `extractSvg` from `Example.Viz`. Don't redefine any of these locally.
- DOT source strings are kept in `Diagrams.purs`, never inlined in `Main.purs`. Add a new diagram by extending `Diagrams.purs` and updating the `findDiagram`/category lists.
- Node category colors (Material 100 palette) are duplicated between DOT source (`Diagrams.purs`) and the legend (`Main.purs`). Keep them in sync — if you add a new category to DOT, add it to the legend.
