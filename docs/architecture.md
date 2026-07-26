# Architecture

This document describes the build pipeline, devcontainer image workflow, and the
FFI bindings data flow for purs-graphs.

## Overview

purs-graphs is a PureScript monorepo providing two FFI binding packages and two
Halogen example apps, built on a prebuilt-devcontainer workflow.

```mermaid
graph TB
    subgraph "Workspace Root"
        WS[spago.yaml<br/>workspace config]
        PKG[package.json<br/>dev toolchain]
    end

    subgraph "packages/"
        DG[purs-dagre<br/>dagre FFI bindings]
        VZ[purs-viz<br/>viz.js FFI bindings]
    end

    subgraph "examples/"
        DD[dagre-demo<br/>Halogen + SVG]
        VD[viz-demo<br/>Halogen + DOT→SVG]
    end

    DG --> DD
    DG --> VD
    VZ --> VD
    WS --> DG
    WS --> VZ
    WS --> DD
    WS --> VD
```

## Build Pipeline

The workspace uses spago 0.93+ with YAML config and `purs-backend-es` as the
alternate backend. PureScript compiles to corefn, then the ES backend emits
optimized ES modules that Vite bundles for HMR.

```mermaid
flowchart LR
    A["*.purs<br/>source"] -->|"spago build"| B["output/<br/>corefn.json"]
    B -->|"purs-backend-es build"| C["output-es/<br/>optimized ES modules"]
    C -->|"vite dev"| D["HMR<br/>localhost:5173"]
    C -->|"vite build"| E["dist/<br/>production bundle"]
    A -->|"spago test"| F["spec runner<br/>console output"]
```

- **`spago build`** — compiles all `.purs` files in the workspace (all packages
  + examples) via the PureScript compiler. Produces `output/` with `corefn.json`
  per module.
- **`purs-backend-es build`** — reads `corefn.json` from `output/`, emits
  optimized ES module output to `output-es/`. Configured via
  `workspace.backend.cmd` in the root `spago.yaml`.
- **`spago test --config <pkg>/spago.yaml`** — runs a single package's test
  suite. Tests use the `spec` library with `consoleReporter`.
- **Vite dev** — `concurrently -k "spago build --watch" "vite"` watches `.purs`
  files (spago) and serves the example via Vite. The JS entry
  (`src/index.js`) imports `Main` from `output-es/Main/index.js`. Vite's HMR
  triggers via `import.meta.hot.accept` when spago rebuilds.

## DevContainer Image Workflow

The devcontainer uses a **prebuilt image** pattern: the Dockerfile installs the
full PureScript toolchain (spago, purs, purs-backend-es, vite, esbuild), and CI
bakes a warm dependency cache into a published image. Teammates pull instead of
rebuilding.

```mermaid
flowchart TB
    DF[".devcontainer/Dockerfile<br/>AL2023 + Node 20"] -->|"podman build"| BASE["base image"]
    BASE -->|"podman run --entrypoint '[]'"| PREP["prep container<br/>spago install + build"]
    PREP -->|"podman commit"| FINAL["final image"]
    FINAL -->|":sha"| GHCR["ghcr.io"]
    FINAL -->|":latest"| GHCR
    FINAL -->|":dev-YYYYMMDD"| GHCR
    GHCR -->|"pull"| DEV["developer<br/>Reopen in Container"]
```

- **`devcontainer.json`** has BOTH `"image"` (default — fast pull) AND `"build"`
  (explicit rebuild from Dockerfile). No `postCreateCommand` — everything is
  baked in.
- **`scripts/build-devcontainer.sh`** — builds the Dockerfile, runs
  `spago install && spago build` inside a prep container (using
  `podman run --entrypoint '[]'` to clear the Lambda base's ENTRYPOINT), commits
  the container state, tags with sha + latest + date, pushes to ghcr.io.
- **`scripts/push-devcontainer.sh`** — commits a *running* container (known-good
  state) and pushes 3 tags.
- **`scripts/save-devcontainer-tarball.sh`** — exports to `.tar.gz` + `.sha256`
  for airgap distribution.
- **CI** (`.github/workflows/devcontainer.yml`) — triggers on
  `.devcontainer/**`, `packages/**`, `examples/**`, and weekly cron for
  security refresh. Logs into ghcr.io *before* the build script (which pushes
  during the run).

## Bindings Data Flow

### purs-dagre (synchronous layout)

dagre is a pure-JS synchronous layout engine. The FFI creates a mutable
`graphlib.Graph`, the layout algorithm mutates it in place, and PureScript reads
back coordinates.

```mermaid
sequenceDiagram
    participant PS as PureScript (Dagre.Graph)
    participant FFI as Dagre.js (FFI)
    participant JS as dagre (npm peer-dep)

    PS->>FFI: newGraph()
    FFI->>JS: new dagre.graphlib.Graph()
    JS-->>FFI: graph object
    FFI-->>PS: ForeignGraph

    PS->>FFI: setNode(id, {width, height})
    FFI->>JS: g.setNode(id, {...})
    PS->>FFI: setEdge(src, tgt)
    FFI->>JS: g.setEdge(src, tgt)

    PS->>FFI: layout(g)
    FFI->>JS: dagre.layout(g)
    Note over JS: mutates g in place<br/>writes x/y to each node

    PS->>FFI: nodeX(g, id)
    FFI->>JS: g.node(id).x
    JS-->>FFI: number | null
    FFI-->>PS: Nullable Number → Maybe Number
```

### purs-viz (async Graphviz rendering)

viz.js is a WebAssembly build of Graphviz. Instance creation is async (WASM
instantiation); rendering is synchronous. The FFI uses `Aff` + `makeAff` to
bridge the Promise, and wraps `viz.render()` (which never throws) to return
`Either` — no exceptions cross the FFI boundary.

```mermaid
sequenceDiagram
    participant PS as PureScript (Viz)
    participant FFI as Viz.js (FFI)
    participant VIZ as @viz-js/viz (WASM)

    PS->>FFI: new (Aff)
    FFI->>VIZ: instance()
    VIZ-->>FFI: Promise<Viz>
    Note over FFI: makeAff bridges<br/>Promise → Aff
    FFI-->>PS: VizInstance

    PS->>FFI: renderString(viz, dot, opts)
    FFI->>VIZ: viz.render(dot, {format, engine})
    VIZ-->>FFI: {status, output, errors}
    Note over FFI: maps to Either<br/>Right svg | Left errors
    FFI-->>PS: Either (Array String) String
```

## Workspace Package Graph

```mermaid
graph LR
    subgraph "Registry packages"
        P[prelude]
        E[effect]
        M[maybe]
        A[aff]
        HL[halogen]
        HH[halogen-hooks]
    end

    subgraph "Workspace packages"
        DG[purs-dagre]
        VZ[purs-viz]
    end

    subgraph "Examples"
        DD[dagre-demo]
        VD[viz-demo]
    end

    P --> DG
    E --> DG
    M --> DG
    P --> VZ
    E --> VZ
    A --> VZ
    M --> VZ

    DG --> DD
    HL --> DD
    HH --> DD
    VZ --> VD
    HL --> VD
    HH --> VD
```

## Key Design Decisions

| Decision | Rationale |
|---|---|
| spago 0.93+ YAML (not Dhall) | New spago uses YAML workspace configs with registry-based package sets |
| `purs-backend-es` as backend | Produces optimized ES modules; smaller + faster than the default JS backend |
| npm peer-deps for JS libs | dagre + @viz-js/viz are NOT bundled in the PureScript packages; consumers install them so they can dedupe |
| `Effect` for sync FFI, `Aff` for async | dagre layout is synchronous (Effect); viz.js instance creation is async (Aff via WASM) |
| `Maybe`/`Either` for FFI returns | No exceptions cross the FFI boundary — nullable returns use `Nullable` → `toMaybe`, error returns use `Either` |
| Newtypes around foreign types | `newtype Graph = Graph ForeignGraph` provides type safety without runtime cost |
| Prebuilt devcontainer image | Fast team onboarding (pull vs rebuild); AL2023 + Node 20 base matches Lambda handoff pattern |
| Three-tag image publishing | `:sha` (immutable), `:latest` (mutable), `:dev-YYYYMMDD` (date-stamped for rollbacks) |
