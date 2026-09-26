# purs-graphs (VSCode extension)

Live preview for two graph formats, powered by this repo's PureScript bindings:

| Preview | File type | Engine |
|---|---|---|
| **DOT preview** | `.dot` / `.gv` | Graphviz (viz.js WASM) via [`purs-viz`](../../packages/purs-viz/) |
| **Graph (JSON) preview** | `*.graph.json` | dagre layout via [`purs-dagre`](../../packages/purs-dagre/) |

## Usage

1. Open a `.dot` file → run **Purs Graphs: Preview DOT** (`Ctrl+Shift+G`).
2. Open a `*.graph.json` file → run **Purs Graphs: Preview Graph (JSON)**.

The preview opens beside the editor and **live-refreshes** as you type.
Errors (bad DOT syntax, invalid JSON spec) render inline in the webview.

### JSON graph spec

```json
{
  "rankDir": "LR",
  "nodes": [
    { "id": "api", "label": "API", "width": 120, "height": 60 },
    { "id": "db", "label": "Postgres", "width": 140, "height": 60 }
  ],
  "edges": [
    { "from": "api", "to": "db", "label": "SQL" }
  ]
}
```

- `rankDir`: optional, one of `TB` (default) | `BT` | `LR` | `RL`
- `nodes[].id` is required; `label`, `width`, `height` optional
- `edges[]`: `from`/`to` reference node ids; `label` optional

### Settings

| Setting | Default | Description |
|---|---|---|
| `pursGraphs.dotEngine` | `dot` | Graphviz engine (`dot`, `neato`, `fdp`, `circo`, `twopi`) |

## Architecture

```
extensions/purs-graphs/
├── src/extension.ts        TS extension host: commands, webview panel, CSP, file watching
├── webview-src/            PureScript webview package (spago workspace member)
│   └── src/                DOT + dagre renderers reusing purs-viz / purs-dagre
├── media/webview.js        esbuild bundle of the compiled PureScript (output-es) + deps
└── esbuild.mjs             two bundles: dist/extension.js (host) + media/webview.js (webview)
```

Message protocol (host ↔ webview), see `src/extension.ts`:

- host → webview: `{ type: "update", kind: "dot" | "graph", source, fileName }`
- webview → host: `{ type: "ready" } | { type: "rendered", kind, ms } | { type: "error", kind, message }`

The webview is fully self-contained: viz.js WASM is inlined in the bundle, and
the webview runs under a strict CSP (nonce + `wasm-unsafe-eval`).

## Build

Requires Node 22+ (`npm ci` at the workspace root provides the toolchain).

```bash
cd extensions/purs-graphs
npm install
npm run compile     # host bundle + webview bundle (calls spago at workspace root)
npm run package     # → purs-graphs.vsix
```

Install the built extension: VSCode → Extensions view → `…` → *Install from VSIX*.
