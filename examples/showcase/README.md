# showcase

ByteByteGo-style system-design showcase using **both** [`purs-dagre`](../../packages/purs-dagre/)
and [`purs-viz`](../../packages/purs-viz/). Eight iconic system-design diagrams,
each renderable in two modes with a library toggle, plus click-to-detail on
every node.

**Port**: `5175` — Google/Material palette with a dark slate sidebar.

## What it shows

Eight curated diagrams across three categories:

| # | Category | Diagram | Concepts illustrated |
|---|---|---|---|
| 1 | Architecture | Scale a Single Server | baseline before scaling |
| 2 | Architecture | Blueprint of a Backend | layered architecture (gateway, services, cache, DB) |
| 3 | Architecture | Scale from Zero to Million | LB, primary-replica, CDN, async workers |
| 4 | Pipeline | CI/CD Pipeline | build → test → package → deploy |
| 5 | Pipeline | YouTube Architecture | upload → transcode → CDN → client |
| 6 | Pipeline | Kafka Event Pipeline | producer → broker → consumer groups |
| 7 | Auth & Data | OAuth 2.0 Flow | client → auth server → resource server |
| 8 | Auth & Data | Database Sharding | hash router → N shards |

Each diagram has:
- **dagre data** (`dagreNodes`, `dagreEdges`, `dagreRankDir`) — used in Dagre mode
- **DOT source** — used in Graphviz mode (often with subgraphs/clusters, edge labels, dashed edges for failure paths)
- **`nodeInfo` map** — click any node to see a detail card with its label, id, and explanation

## Run

```bash
./scripts/dev.sh showcase
# → http://localhost:5175
```

Or build for production:

```bash
cd examples/showcase
npm install
npm run build
npm run preview
```

## Three-column app shell

```
┌───────────────────────────────────────────────────────────────────────┐
│ Topbar: [logo] Title  Subtitle                [Dagre] [Graphviz]      │
├──────────┬───────────────────────────────────┬────────────────────────┤
│ Sidebar  │ Canvas (dotted grid bg)           │ Detail Panel           │
│          │                                   │                        │
│ ARCH     │   [rendered SVG diagram]          │ Node Details           │
│ 1 Scale  │                                   │ ┌────────────────────┐ │
│ 2 Bluepr │                                   │ │ Node label         │ │
│ 3 Zero-M │                                   │ │ node_id            │ │
│          │                                   │ │ Description...     │ │
│ PIPELINE │                                   │ └────────────────────┘ │
│ 4 CI/CD  │                                   │                        │
│ 5 YouTub │                                   │ Legend                 │
│ 6 Kafka  │                                   │ ▪ Entry ▪ Process ...  │
│          │                                   │                        │
│ AUTH     │                                   │                        │
│ 7 OAuth  │                                   │                        │
│ 8 Shard  │                                   │                        │
└──────────┴───────────────────────────────────┴────────────────────────┘
```

## Tailwind setup

Styling uses Tailwind CSS v4 with a richer theme than the other examples:

- `src/styles.css` — `@theme` tokens for brand, surfaces, sidebar slate, node category colors, Inter font, mono font
- `@layer base` for full-viewport body (no scroll, `h-screen`)
- Raw CSS for the dotted grid background on the canvas (`.canvas-dots`)
- Raw CSS for `#svg-container svg` (FFI-injected SVG sizing)
- `src/Showcase/Main.purs` uses `HP.class_ (cn "...")` + conditional-class helper for active states

## Files

```
showcase/
├── spago.yaml              Deps: halogen, hooks, purs-dagre, purs-viz, example-shared, web-events
├── package.json            npm deps (dagre, @viz-js/viz, vite, tailwindcss)
├── vite.config.ts          Port 5175 + Tailwind plugin + aliases to ../../node_modules/
├── index.html              No <style> — just <div id="app"> + script
└── src/
    ├── styles.css          Tailwind entry + theme tokens + canvas-dots + FFI-SVG raw rules
    ├── index.js            HMR entry, imports styles.css
    └── Showcase/
        ├── Main.purs       Halogen component (cn helper, conditional classes, click handlers, mode toggle)
        ├── Main.js         FFI: getClickedNodeId (DOM walk to <g class="node"><title>)
        └── Diagrams.purs   8 DiagramSpec records (nodes, edges, DOT source, nodeInfo)
```

## License

MIT — see [../../LICENSE](../../LICENSE).
