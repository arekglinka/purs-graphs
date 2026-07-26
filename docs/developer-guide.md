# Developer Guide

## Prerequisites

The only local requirement is a devcontainer runtime (Podman recommended,
Docker works). All toolchain is inside the prebuilt image.

## Getting Started

1. Clone the repo.
2. In VSCode: **Reopen in Container** (pulls `ghcr.io/<owner>/purs-graphs-dev:latest`).
3. Verify the build:

```bash
spago install   # install all workspace dependencies
spago build     # build all packages + examples
```

## Workspace Layout

```
purs-graphs/
├── spago.yaml              # workspace root (packageSet, backend config)
├── package.json            # workspace dev deps (spago, purs, vite, biome)
├── packages/
│   ├── purs-dagre/         # FFI bindings to dagre
│   └── purs-viz/           # FFI bindings to @viz-js/viz
├── examples/
│   ├── dagre-demo/         # Halogen + SVG via dagre layout
│   └── viz-demo/           # Halogen + DOT→SVG via viz.js
├── scripts/                # devcontainer build/push/save + dev launcher
└── docs/
```

## Building Packages

### Workspace-wide build (all packages + examples)

```bash
spago build
```

### Build a single package

```bash
spago build --config packages/purs-dagre/spago.yaml
```

### Run tests

```bash
spago test --config packages/purs-dagre/spago.yaml
spago test --config packages/purs-viz/spago.yaml
```

Or all at once:

```bash
npm test
```

### purs-backend-es (ES output)

The workspace is configured to use `purs-backend-es` as the backend
(`workspace.backend.cmd` in `spago.yaml`). To produce optimized ES output:

```bash
spago build                      # produces output/ with corefn.json
purs-backend-es build            # reads corefn, writes output-es/
```

## Running Examples with HMR

### dagre-demo (port 5173)

```bash
cd examples/dagre-demo
npm install        # install dagre + vite
npm run dev        # spago build --watch + vite dev server
```

Or from the repo root:

```bash
./scripts/dev.sh dagre-demo
```

### viz-demo (port 5174)

```bash
cd examples/viz-demo
npm install        # install @viz-js/viz + vite
npm run dev        # spago build --watch + vite dev server
```

Or:

```bash
./scripts/dev.sh viz-demo
```

### How HMR works

The `dev` script runs `concurrently -k`:
1. `spago build --watch` — recompiles `.purs` on save, updates `output/`.
2. `purs-backend-es build` — regenerates `output-es/` (triggered by spago watch).

Vite's dev server watches `output-es/`. The JS entry (`src/index.js`) imports
`Main` from `output-es/Main/index.js` and registers `import.meta.hot.accept` to
re-run `main()` on hot updates. Sub-second rebuilds in dev.

### Production build

```bash
cd examples/dagre-demo
npm run build   # spago build && purs-backend-es build && vite build → dist/
```

## FFI Development

### Adding a new binding

1. Create `packages/purs-<name>/src/<Name>.purs` with `foreign import`
   declarations (opaque types via `foreign import data`, functions via
   `foreign import`).
2. Create `packages/purs-<name>/src/<Name>.js` with the JS implementations.
   The JS imports the npm peer-dep directly (`import lib from "libname"`).
3. Create `packages/purs-<name>/spago.yaml` with dependencies + test config.
4. Add tests in `packages/purs-<name>/test/Main.purs`.

### FFI conventions

- **Opaque types**: `foreign import data ForeignGraph :: Type`
- **Effect functions**: declared as `Effect a`, implemented as `() => a` thunks
  on the JS side (curried for multi-arg).
- **Nullable returns**: declare as `Nullable a` on the PS side, use
  `Data.Nullable.toMaybe` to convert to `Maybe`.
- **No exceptions**: wrap all JS in try/catch and return a result type. Use
  `Either`/`Maybe` for error handling.
- **Newtypes**: wrap foreign types as `newtype Graph = Graph ForeignGraph`.

## DevContainer

### Rebuilding the image

When `.devcontainer/Dockerfile` changes:

```bash
./scripts/build-devcontainer.sh     # builds + pushes to ghcr.io
```

### Saving a known-good state

If your running container is in a good state:

```bash
./scripts/push-devcontainer.sh      # commits + pushes running container
```

### Airgap distribution

```bash
./scripts/save-devcontainer-tarball.sh   # produces .tar.gz + .sha256
```

## Debugging

### Common issues

- **`spago: command not found`** — you're outside the devcontainer. Reopen in
  container, or `npm install -g spago@next` locally.
- **`Cannot find module 'dagre'`** — the JS peer-dep isn't installed. Run
  `npm install` in the example directory.
- **HMR not updating** — ensure `spago build --watch` is running (check the
  concurrently output). The ES backend must regenerate `output-es/`.
- **Tests can't find viz.js** — viz.js tests need a browser or jsdom
  environment (WASM). Run them in the devcontainer.

### Purs IDE

The devcontainer includes the PureScript Language Server (via the
`nwolverson.ide-purescript` VSCode extension). It uses spago as the build
command. If it's not finding modules, run `spago build` once to generate
`output/`.
