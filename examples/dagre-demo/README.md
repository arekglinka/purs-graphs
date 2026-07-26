# dagre-demo

Interactive dagre playground using [`purs-dagre`](../../packages/purs-dagre/).
Add/remove nodes and edges, switch rank direction, see SVG rendered live via
the Halogen HTML DSL.

**Port**: `5173` — Material Blue accent.

## What it shows

- A Halogen Hooks component with:
  - Inputs to add a new node (id + label + dimensions)
  - Inputs to add a new directed edge (source + target)
  - A `<select>` for rank direction (`TB`, `BT`, `LR`, `RL`)
  - Clickable chips listing current nodes/edges (click to remove)
  - A live SVG canvas showing the laid-out graph
- All rendering uses Halogen's `HH.elementNS` (via the `svgEl` helper from
  [`example-shared`](../shared/)) — no FFI injection, every SVG element is a
  first-class Halogen `HTML` node
- Layout runs via `buildAndLayout` (from `example-shared`) which wraps
  `purs-dagre`'s `new` / `setNode` / `setEdge` / `layout` sequence

This is the simplest example of **dagre-only** rendering (no viz.js, no DOT).

## Run

```bash
./scripts/dev.sh dagre-demo
# → http://localhost:5173
```

Or build for production:

```bash
cd examples/dagre-demo
npm install
npm run build
npm run preview
```

## Tailwind setup

Styling uses Tailwind CSS v4. Per-app files:

- `vite.config.ts` — `plugins: [tailwindcss()]`
- `src/styles.css` — `@import "tailwindcss"`, `@theme { --color-brand: #1976d2; ... }`, `@layer base { body { ... } }`, raw CSS for `.canvas-area svg`
- `src/index.js` — `import "./styles.css";` as the first line
- `src/DagreDemo/Main.purs` — uses `HP.class_ (cn "...")` where `cn = HH.ClassName`

## Files

```
dagre-demo/
├── spago.yaml              PureScript deps (halogen, hooks, purs-dagre, example-shared)
├── package.json            npm deps (dagre, vite, tailwindcss)
├── vite.config.ts          Port 5173 + Tailwind plugin + dagre alias + optimizeDeps
├── index.html              No <style> — just <div id="app"> + script
└── src/
    ├── styles.css          Tailwind entry + theme + canvas-svg raw rule
    ├── index.js            HMR entry, imports styles.css
    └── DagreDemo/Main.purs Halogen component (cn helper, Tailwind utilities, SVG render)
```

## License

MIT — see [../../LICENSE](../../LICENSE).
