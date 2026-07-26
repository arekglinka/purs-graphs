# Learning Path

An 8-week onboarding plan covering PureScript fundamentals, Halogen, FFI, the
dagre/viz mental model, and the contribution workflow.

## Week 1: PureScript Basics

**Goal**: Understand the type system, `Effect`, and basic syntax.

- Read: [PureScript by Example](https://book.purescript.org/) chapters 1–3
- Key concepts:
  - Algebraic data types (`data`, `newtype`, `type`)
  - Records and row polymorphism
  - `Maybe` / `Either` for error handling
  - `Effect` for side effects (no exceptions in PureScript)
- Exercise: write a function `parseAge :: String -> Maybe Int`

**In this repo**: read `packages/purs-dagre/src/Dagre/Graph.purs` — it uses
ADTs (`RankDir`), `Maybe`, and `Effect` for FFI wrapping.

## Week 2: spago + the Build System

**Goal**: Understand the workspace, dependencies, and build pipeline.

- Read: [spago README](https://github.com/purescript/spago) — workspace section
- Key concepts:
  - `spago.yaml` workspace root + per-package configs
  - Registry package sets (`workspace.packageSet.registry`)
  - `extraPackages` for local/git overrides
  - `spago build`, `spago test`, `purs-backend-es`
- Exercise: add a new dependency to `purs-dagre` and rebuild

**In this repo**: read `spago.yaml` (root) and `packages/*/spago.yaml`. Run
`spago build` and inspect `output/` and `output-es/`.

## Week 3: Foreign Function Interface (FFI)

**Goal**: Write safe FFI bindings with no exceptions crossing the boundary.

- Read: [PureScript FFI guide](https://github.com/purescript/documentation/blob/master/language/FFI.md)
- Key concepts:
  - `foreign import data` for opaque types
  - `Effect a` = `() => a` thunk on the JS side
  - `Nullable a` → `Data.Nullable.toMaybe` → `Maybe a`
  - `Effect.Uncurried` for efficient multi-arg FFI
- Exercise: bind a small JS function to PureScript

**In this repo**: read `packages/purs-dagre/src/Dagre.purs` + `Dagre.js`.
Trace how `newGraph`, `setNodeImpl`, and `nodeX` flow from PS to JS and back.

## Week 4: Halogen + halogen-hooks

**Goal**: Build a stateful UI component.

- Read: [Halogen guide](https://purescript-halogen.github.io/purescript-halogen/)
  and [halogen-hooks docs](https://thomashoneyman.github.io/purescript-halogen-hooks/)
- Key concepts:
  - `runHalogenAff` + `awaitBody` + `runUI`
  - `Hooks.component` with `useState`, `useLifecycleEffect`
  - `HH.div_`, `HH.text`, SVG via `HH.elementNS`
  - `liftAff` / `liftEffect` in HookM
- Exercise: render a counter button

**In this repo**: read `examples/dagre-demo/src/Main.purs`. It builds a graph,
lays it out, and renders SVG. Trace the `useLifecycleEffect` → `liftEffect`
→ `Hooks.put` flow.

## Week 5: dagre — Graph Layout Mental Model

**Goal**: Understand layered graph drawing and dagre's API.

- Read: [dagre wiki](https://github.com/dagrejs/dagre/wiki)
- Key concepts:
  - Rank assignment (TB/BT/LR/RL)
  - Node dimensions are required (default 0×0)
  - `layout()` mutates the graph in place, populating x/y
  - `setGraph` controls global layout options
- Exercise: lay out a 10-node graph and read back positions

**In this repo**: read `packages/purs-dagre/src/Dagre/Graph.purs`. Run
`spago test --config packages/purs-dagre/spago.yaml` and watch the test output.

## Week 6: viz.js — Graphviz Rendering Mental Model

**Goal**: Understand DOT syntax and Graphviz rendering.

- Read: [viz.js README](https://github.com/mdaines/viz-js) and
  [Graphviz docs](https://graphviz.org/)
- Key concepts:
  - DOT language: `digraph`, `->`, node/edge attributes
  - Engines: dot (hierarchical), neato (spring), circo (circular)
  - `instance()` is async (WASM); `render()` is sync and returns a result union
  - `renderString` throws on failure; the binding wraps it in `Either`
- Exercise: write DOT for a state machine, render to SVG

**In this repo**: read `packages/purs-viz/src/Viz.purs` + `Viz/Render.purs`.
Understand how `makeAff` bridges the WASM Promise to `Aff`.

## Week 7: DevContainer + CI Workflow

**Goal**: Understand the prebuilt image workflow and enterprise-forkable CI.

- Read: `.devcontainer/Dockerfile`, `.devcontainer/devcontainer.json`
- Key concepts:
  - `image:` (fast pull) vs `build:` (explicit rebuild) in devcontainer.json
  - `podman run --entrypoint '[]'` — clears Lambda base ENTRYPOINT
  - Three CI workflows: `ci.yml` (PR checks), `release.yml` (binding bundles),
    `devcontainer.yml` (image publishing)
  - Three-tag publishing: sha (immutable), latest (mutable), dev-YYYYMMDD
  - Path generic-ness: `${{ github.repository_owner }}` everywhere
- Exercise: fork the repo, change `YOUR_GH_OWNER`, rebuild the image

**In this repo**: read `scripts/build-devcontainer.sh` and trace the CI flow
in `.github/workflows/devcontainer.yml`.

## Week 8: Contribution Workflow

**Goal**: Make your first contribution.

- Read: `CONTRIBUTING.md`
- Steps:
  1. Pick an issue (or file one)
  2. Create a branch: `feat/my-feature` or `fix/my-bugfix`
  3. Write code following the PureScript conventions (ADTs, Effect, Maybe/Either)
  4. Add tests in `test/Main.purs`
  5. Run: `spago build && spago test --config packages/*/spago.yaml`
  6. Format: `purs-tidy format-in-place src test` and `biome check --write .`
  7. Commit with Conventional Commits: `feat: ...`, `fix: ...`
  8. Open a PR — CI runs build + test + both example builds

**Definition of done**: CI green, tests pass, docs updated if API changed.

## Suggested Reading Order

For a new contributor with no PureScript experience:

1. PureScript by Example (chapters 1–5) — 2 days
2. FFI guide — 1 day
3. This repo's `Dagre.purs` / `Dagre.js` — trace the FFI — 1 day
4. Halogen guide + hooks docs — 2 days
5. `examples/dagre-demo/src/Main.purs` — understand the full stack — 1 day
6. spago README (workspace section) — 1 day
7. Make a small contribution (add a test, fix a doc) — 1 day
