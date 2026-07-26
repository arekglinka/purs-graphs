# purs-graphs

PureScript FFI bindings for graph visualization — [dagre](https://github.com/dagrejs/dagre)
for directed graph layout and [viz.js](https://github.com/mdaines/viz-js) for
full Graphviz (DOT) rendering — with Halogen example apps.

## Packages

| Package | Wraps | Use Case |
|---|---|---|
| **purs-dagre** | `dagre@0.8.5` | Compute layout (nodes/edges → x/y coordinates), render with any SVG/canvas lib |
| **purs-viz** | `@viz-js/viz` 3.x | Write DOT source, get an SVG string back (full Graphviz via WASM) |

Both bindings keep the JavaScript dependencies as **npm peer-deps** (not bundled)
so consumers can dedupe across their dependency tree.

## Quick Start

```bash
git clone https://github.com/YOUR_GH_OWNER/purs-graphs.git
cd purs-graphs
# In VSCode: Reopen in Container (pulls the prebuilt devcontainer image)
./scripts/dev.sh dagre-demo   # HMR dev server on http://localhost:5173
```

> Replace `YOUR_GH_OWNER` with your GitHub owner/org. See
> [Enterprise Forks](#enterprise-forks) below.

## Examples

Both examples render the **same 5-node build pipeline** (source → compile → link
→ test → package):

- **dagre-demo** (port 5173): builds a Graph in PureScript, calls purs-dagre
  for layout, renders SVG via the Halogen HTML DSL.
- **viz-demo** (port 5174): writes DOT source in PureScript, calls purs-viz for
  an SVG string.

```bash
./scripts/dev.sh dagre-demo   # or: viz-demo
```

## Build & Test

```bash
spago build                                          # all packages + examples
spago test --config packages/purs-dagre/spago.yaml   # dagre tests
spago test --config packages/purs-viz/spago.yaml     # viz tests
```

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

The devcontainer uses a **prebuilt image** pattern (Amazon Linux 2023 + Node 20):

- **`image:`** key — fast pull for daily use.
- **`build:`** key — explicit rebuild from Dockerfile when the toolchain changes.
- No `postCreateCommand` — everything is baked into the published image.

### Rebuild the image

```bash
./scripts/build-devcontainer.sh          # build + push to ghcr.io
./scripts/push-devcontainer.sh           # commit + push running container
./scripts/save-devcontainer-tarball.sh   # airgap tarball + sha256
```

## Tech Stack

- PureScript 0.15.15
- spago 0.93+ with workspaces (YAML config)
- purs-backend-es (ES backend)
- Halogen 6 + halogen-hooks
- Vite 5 with HMR
- Amazon Linux 2023 + Node 20 (devcontainer base)

## Documentation

- [Architecture](docs/architecture.md) — Mermaid diagrams of build pipeline, devcontainer flow, and bindings data flow
- [Developer Guide](docs/developer-guide.md) — build, run, debug each package + example
- [Learning Path](docs/learning-path.md) — 8-week onboarding plan

## License

MIT — see [LICENSE](LICENSE).
