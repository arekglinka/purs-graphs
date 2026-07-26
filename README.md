# purs-graphs

PureScript FFI bindings for graph visualization — [dagre](https://github.com/dagrejs/dagre)
for directed graph layout and [viz.js](https://github.com/mdaines/viz-js) for
full Graphviz (DOT) rendering — with Tailwind-styled Halogen example apps.

## Packages

| Package | Wraps | Use Case |
|---|---|---|
| **[purs-dagre](packages/purs-dagre/)** | `dagre@0.8.5` | Compute layout (nodes/edges → x/y coordinates), render with any SVG/canvas lib |
| **[purs-viz](packages/purs-viz/)** | `@viz-js/viz` 3.x | Write DOT source, get an SVG string back (full Graphviz via WASM) |
| **[example-shared](examples/shared/)** | (internal) | SVG primitives, FFI helpers, layout runners shared across examples |

Both library bindings keep their JavaScript dependencies as **npm peer-deps**
(not bundled) so consumers can dedupe across their dependency tree.

## Examples

All three examples run as Vite-powered Halogen apps with hot-module reload.

| Example | Port | Library | What it shows |
|---|---|---|---|
| **[dagre-demo](examples/dagre-demo/)** | 5173 | purs-dagre | Interactive dagre playground: add/remove nodes & edges, switch rank direction, see SVG rendered via Halogen HTML DSL |
| **[viz-demo](examples/viz-demo/)** | 5174 | purs-viz | Interactive DOT playground: edit DOT source, switch Graphviz engines (dot/neato/fdp/circo/twopi), see SVG injected via FFI |
| **[showcase](examples/showcase/)** | 5175 | both | ByteByteGo-style system-design showcase: 8 diagrams (scale, cache, CI/CD, Kafka, OAuth, sharding, …) with library toggle and click-to-detail |

## Quick Start

```bash
git clone https://github.com/YOUR_GH_OWNER/purs-graphs.git
cd purs-graphs

# Option A — open in VSCode DevContainer (recommended, pulls prebuilt image)
#   Reopen in Container → ready in seconds

# Option B — host with Node 20+ and the devcontainer CLI
npm install
./scripts/dev.sh showcase   # HMR dev server on http://localhost:5175
```

> Replace `YOUR_GH_OWNER` with your GitHub owner/org (see
> [Enterprise Forks](#enterprise-forks)).

## Build & Test

| Command | Purpose |
|---|---|
| `npm run build` | `spago build` — compile every package + example |
| `npm test` | Run property + unit tests for both library packages |
| `npm run test:examples` | Run tests for example packages (if defined) |
| `npm run build:examples` | Production-vite-build all three examples into `dist/` |
| `npm run format` | purs-tidy + biome format in place |
| `npm run format:check` | CI check — fails if any file is unformatted |
| `npm run docs` | Generate HTML API docs under `generated-docs/` |

Per-package variants:

```bash
spago build -p purs-dagre      # build only one package
spago test  -p purs-viz        # test only one package
```

## Architecture

```
purs-graphs/
├── packages/
│   ├── purs-dagre/        FFI → dagre (programmatic layout)
│   └── purs-viz/          FFI → @viz-js/viz (DOT → SVG via WASM)
├── examples/
│   ├── shared/            Internal helpers (SVG primitives, FFI, layout runners)
│   ├── dagre-demo/        Interactive dagre playground  (port 5173)
│   ├── viz-demo/          Interactive DOT playground    (port 5174)
│   └── showcase/          ByteByteGo 8-diagram showcase (port 5175)
├── scripts/               dev.sh, devcontainer build/push/save
├── docs/                  architecture.md, developer-guide.md, learning-path.md
├── .devcontainer/         AL2023 + Node 20 prebuilt image
└── .github/workflows/     ci.yml (build + test), release.yml, devcontainer.yml
```

Each library package uses a **two-layer FFI pattern**:

1. **Raw FFI** (`Dagre.purs` / `Viz.purs`) — opaque foreign types, curried
   wrappers, `Nullable` returns.
2. **Idiomatic API** (`Dagre.Graph` / `Viz.Render`) — `newtype` wrappers, ADTs
   (`RankDir`, `Engine`), `Maybe` / `Either` for fallible operations.

dagre + @viz-js/viz are NOT bundled by the libraries — they're npm peer-deps so
consumers dedupe. The example apps install them at the workspace root and alias
them in each `vite.config.ts`.

## Tech Stack

| Layer | Choice |
|---|---|
| Language | PureScript 0.15.16 |
| Build | spago 1.0+ with workspaces, `purs-backend-es` backend |
| UI | Halogen 7 + halogen-hooks |
| Styling | Tailwind CSS v4 (`@tailwindcss/vite` plugin, CSS-first config) |
| Bundler | Vite 5 with HMR |
| Tests | purescript-spec + spec-node + purescript-quickcheck |
| Formatter | purs-tidy (`.tidyrc.json`) + biome (JS/TS/JSON) |
| DevContainer | Amazon Linux 2023 + Node 22 (prebuilt image pattern) |

## Enterprise Forks

This repo is enterprise-forkable — **no hardcoded GitHub paths**.

1. Fork the repo.
2. Update `.devcontainer/devcontainer.json`: replace `YOUR_GH_OWNER` with your
   GitHub owner or org.
3. Update `.github/CODEOWNERS`: replace `YOUR_GH_OWNER`.
4. The scripts auto-detect the owner from `git remote get-url origin`. Override
   with `OWNER=my-org ./scripts/build-devcontainer.sh`.
5. CI uses `${{ github.repository_owner }}` — no changes needed.

## DevContainer

The devcontainer uses a **prebuilt image** pattern:

- **`image:`** key — fast pull for daily use.
- **`build:`** key — explicit rebuild from Dockerfile when the toolchain changes.
- No `postCreateCommand` — everything is baked into the published image.

### Rebuild the image

```bash
./scripts/build-devcontainer.sh          # build + push to ghcr.io
./scripts/push-devcontainer.sh           # commit + push running container
./scripts/save-devcontainer-tarball.sh   # airgap tarball + sha256
```

## Documentation

- [Architecture](docs/architecture.md) — Mermaid diagrams of build pipeline, devcontainer flow, and bindings data flow
- [Developer Guide](docs/developer-guide.md) — build, run, debug each package + example
- [Learning Path](docs/learning-path.md) — 8-week onboarding plan
- [CONTRIBUTING](CONTRIBUTING.md) — code style, commit format, PR checklist

Per-package docs: each package and example has its own `README.md` and
`AGENTS.md` (for AI agents working in that subtree).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Briefly:

- `npm run format` before commit (purs-tidy + biome)
- `npm test` must pass
- PureScript: no `as any` / `@ts-ignore` equivalents — fix type errors properly
- Halogen: prefer Hooks over classic components for new code
- FFI: keep raw bindings thin, push logic into PureScript

## License

MIT — see [LICENSE](LICENSE).
