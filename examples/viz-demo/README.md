# viz-demo

Interactive DOT playground using [`purs-viz`](../../packages/purs-viz/). Edit
DOT source, switch layout engines, see the SVG re-render live.

**Port**: `5174` — Material Green accent.

## What it shows

- A Halogen Hooks component with:
  - A `<textarea>` for DOT source (live-editable)
  - A `<select>` for Graphviz layout engine (`dot`, `neato`, `fdp`, `circo`, `twopi`)
  - A "Render" button that calls `Viz.Render.renderString`
- viz.js output is injected into `#svg-container` via `setInnerHTMLById` FFI
  (from [`example-shared`](../shared/))
- Errors render in a red error box below the canvas

This is the simplest example — pure viz.js (no dagre), single-page layout.

## Run

```bash
./scripts/dev.sh viz-demo
# → http://localhost:5174
```

Or build for production:

```bash
cd examples/viz-demo
npm install
npm run build   # spago build && purs-backend-es build && vite build
npm run preview # → port 4173
```

## Tailwind setup

Styling uses Tailwind CSS v4 (`@tailwindcss/vite` plugin). Per-app files:

- `vite.config.ts` — `plugins: [tailwindcss()]`
- `src/styles.css` — `@import "tailwindcss"`, `@theme { --color-brand: #2e7d32; ... }`, `@layer base { body { ... } }`, raw CSS for `#svg-container svg`
- `src/index.js` — `import "./styles.css";` as the first line
- `src/VizDemo/Main.purs` — uses `HP.class_ (cn "...")` where `cn = HH.ClassName`

The `#svg-container svg { max-width: 100%; height: auto; }` rule lives in
`styles.css` because the SVG is FFI-injected (no PureScript-side class hook).

## Files

```
viz-demo/
├── spago.yaml              PureScript deps (halogen, hooks, purs-viz, example-shared)
├── package.json            npm deps (@viz-js/viz, vite, tailwindcss)
├── vite.config.ts          Port 5174 + Tailwind plugin + viz alias
├── index.html              No <style> — just <div id="app"> + script
└── src/
    ├── styles.css          Tailwind entry + theme + FFI-SVG raw rule
    ├── index.js            HMR entry, imports styles.css
    └── VizDemo/Main.purs   Halogen component (cn helper, Tailwind utilities)
```

## License

MIT — see [../../LICENSE](../../LICENSE).
