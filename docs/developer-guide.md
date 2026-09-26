# Developer Guide

## Prerequisites

Node 22+ and git. Everything else (purs, spago, purs-backend-es, purs-tidy,
esbuild, vite) is installed locally by `npm ci` — no global toolchain.

## Getting Started

1. Clone the repo.
2. Either run `npm ci` on the host, or open in VSCode and **Reopen in
   Container** (single-file devcontainer on `node:22-slim`).
3. Verify the build:

```bash
npm run build   # spago build — all packages + examples
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
├── scripts/                # dev.sh (HMR dev-server launcher)
├── extensions/purs-graphs/ # VSCode extension (DOT + JSON graph previews)
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

The devcontainer is one file: `.devcontainer/devcontainer.json`.

- Base image `node:22-slim`, `git` provided by a devcontainer feature.
- `postCreateCommand` runs `npm ci` — all toolchain comes from root
  `package.json` (versioned in `package-lock.json`).
- No Dockerfile, no prebuilt image, no registry dependency. Changing the image
  tag in the one file is the whole upgrade path.

## Debugging

### Common issues

- **`spago: command not found`** — run `npm ci` first; then use `npx spago …`
  for bare shell commands (npm scripts resolve it automatically).
- **`Cannot find module 'dagre'`** — the JS peer-dep isn't installed. Run
  `npm install` in the example directory.
- **HMR not updating** — ensure `spago build --watch` is running (check the
  concurrently output). The ES backend must regenerate `output-es/`.
- **Tests can't find viz.js** — viz.js tests need a browser or jsdom
  environment (WASM). Run them inside the devcontainer or on a host with Node 22.

### Purs IDE

The devcontainer ships the `nwolverson.ide-purescript` VSCode extension with
`purescript.addNpmPath: true`, so it uses `purs` and `purescript-language-server`
from `node_modules/.bin` (installed by `npm ci`). If it's not finding modules,
run `npm run build` once to generate `output/`.
