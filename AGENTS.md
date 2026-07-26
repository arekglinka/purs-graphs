# AGENTS.md

## Project

`purs-graphs` is a PureScript monorepo providing FFI bindings to two JavaScript
graph-visualization libraries — `dagre` (programmatic directed-graph layout)
and `@viz-js/viz` (full Graphviz DOT → SVG via WASM) — plus three Tailwind-styled
Halogen example apps demonstrating each binding.

The two library packages (`purs-dagre`, `purs-viz`) are intended to be
publishable. The `examples/shared` package and the three example apps are not
published — they exist for documentation and live development.

## Stack

- PureScript 0.15.16
- spago 1.0.4 (workspace YAML config, `purs-backend-es` backend)
- Halogen 7 + halogen-hooks (UI)
- Tailwind CSS v4 (`@tailwindcss/vite` plugin, CSS-first config in `styles.css`)
- Vite 5 (bundler + HMR dev server)
- purescript-spec + spec-node + purescript-quickcheck (tests)
- purs-tidy (PureScript formatter, `.tidyrc.json`)
- biome (JS/TS/JSON formatter)
- Amazon Linux 2023 + Node 22 (devcontainer base image)

## Build Commands

| Command | Purpose |
|---|---|
| `npm run build` | `spago build` — compile all packages + examples (purs JS backend) |
| `npm test` | Run library package tests (purs-dagre + purs-viz) |
| `npm run test:examples` | Run example package tests (if any) |
| `npm run build:examples` | For each example: spago build + `purs-backend-es build` + vite-build into `dist/` |
| `npm run format` | purs-tidy + biome format in place |
| `npm run format:check` | CI gate — exits non-zero if unformatted |
| `npm run docs` | Generate HTML API docs under `generated-docs/` |
| `spago build -p <pkg>` | Build a single package |
| `spago test -p <pkg>` | Test a single package |
| `./scripts/dev.sh <example>` | Run dev server for `dagre-demo`/`viz-demo`/`showcase` |

**Container note:** PureScript toolchain (spago, purs, purs-tidy, purs-backend-es)
is installed in the devcontainer image, NOT on the host. Run build/test commands
inside the container via `podman exec -w /workspaces/purs-graphs <container> sh -c '...'`
or just use the VSCode integrated terminal inside the devcontainer.

**spago 1.x backend note:** spago 1.0+ no longer auto-runs `purs-backend-es` from
the workspace config (it tries to pass `--run` which the backend doesn't accept).
Instead, `spago build` writes the purs JS backend to `output/`, then
`purs-backend-es build --corefn-dir ../../output --output-dir ../../output-es`
produces the optimized ES output in `output-es/`. The example build scripts
(`npm run build` in each `examples/<app>/`) handle this automatically.

## Code Style

- **PureScript**: 2-space indent, 100-char width, `arrowFirst`, import sort.
  Configured in `.tidyrc.json`. Run `npx purs-tidy format-in-place packages examples`.
- **JS/TS/JSON**: biome. 2-space, double-quote, semicolons. Configured in `biome.json`.
- **Halogen**: Hooks (`Hooks.component`) for new components. Classic `H.mkComponent`
  only for parent-child communication, queries, or perf-critical paths.
- **FFI**: three-layer pattern — raw FFI binding → safe wrapper → idiomatic API.
  Use `Effect.Uncurried` for multi-arg JS functions. Use `Data.Nullable` + `toMaybe`
  for nullable returns. Keep foreign imports thin — push logic into PureScript.
- **Tailwind**: utility classes via `HP.class_ (cn "...")` where `cn = HH.ClassName`.
  Theme tokens in `@theme` blocks of `examples/<app>/src/styles.css`. SVG
  presentation attributes (`fill`, `stroke`, `viewBox`, etc.) stay as `svgAttr`
  calls — they are NOT Tailwind candidates.
- **Newtypes**: derive instances with `derive newtype instance`. Don't write
  boilerplate hand-rolled instances.

## Always

- Run `npm run format` before committing
- Run `npm test` before committing — must pass
- Read the package's `AGENTS.md` before modifying that package (overrides here)
- For FFI changes: confirm the JS export shape matches the PureScript `foreign import` signature
- After touching `index.html` or `styles.css`: rebuild the example and verify the
  Tailwind CSS bundle size is non-zero (Tailwind v4 silently no-ops on config errors)

## Ask First

- Before adding a new npm dependency (ask: is it worth the supply-chain risk?)
- Before modifying the library packages' public API (`Dagre.Graph`, `Viz.Render`)
  — these are intended to be publishable
- Before changing the spago `packageSet` registry version in root `spago.yaml`
  — bumps ripple across every package
- Before adding a new PureScript dependency to a library package
- Before changing the devcontainer base image (Dockerfile) — affects every contributor

## Never

- Commit `output/`, `output-es/`, `.spago/`, `node_modules/`, or `dist/`
- Use `unsafeCoerce` or any `Unsafe.*` module without justification in a comment
- Suppress type errors (no PureScript equivalent of `as any` / `@ts-ignore` — but
  don't use `unsafeCoerce`/`unsafePerformEffect` to mimic that)
- Modify generated files (`output-es/`, `generated-docs/`, `dist/`) — regenerate instead
- Hardcode GitHub owner/repo paths (use `YOUR_GH_OWNER` placeholder or
  `${{ github.repository_owner }}` in CI)
- Touch `.spago` package sources — they're the immutable registry
- Convert SVG presentation attributes (`svgAttr "fill"`, `svgAttr "stroke"`, etc.)
  to Tailwind classes — they MUST stay as `svgAttr` calls
- Change `HP.id "svg-container"` in any example — it's an FFI contract

## Gotchas

- **Vite + dagre CJS**: dagre 0.8.5 ships CommonJS. Each `vite.config.ts` needs
  `optimizeDeps.include: ["dagre"]` to force pre-bundling. Without it, you get
  `require is not defined` at runtime.
- **Halogen `HP.class_`**: takes `ClassName`, not `String`. Wrap with
  `HH.ClassName "..."` (or define `cn = HH.ClassName`).
- **`web-events` polymorphic FFI**: if you write an FFI callback that accepts
  any event object, use `forall event. event -> ...` instead of importing
  `MouseEvent` — avoids the `web-uievents` dep.
- **viz.js SVG is opaque**: `setInnerHTMLById` injects a raw SVG string from
  viz.js. You can only style its wrapper (via `#svg-container svg` CSS rule),
  not the SVG internals from PureScript.
- **Spago 1.x requires Node 22.5+**: spago uses `node:sqlite` (unflagged in Node
  22.13+). The devcontainer base is now `public.ecr.aws/lambda/nodejs:22`. If
  you upgrade spago further and hit `ERR_UNKNOWN_BUILTIN_MODULE: node:sqlite`,
  bump Node to the latest 22.x LTS.
- **Two output dirs**: `purs` writes `output/`, `purs-backend-es` writes
  `output-es/`. The examples import from `output-es/`. If you delete one, you
  must rebuild (`spago build` + `purs-backend-es build`).
- **Registry 61.0.0 quirks**: `maps` package was renamed to `ordered-collections`.
  `Tuple` constructor `(/\)` operator isn't exported — use `Tuple a b` directly.
- **`getClickedNodeId` FFI** (showcase only): walks `<g class="node"><title>`
  produced by Graphviz. If you change the DOT source shape, the DOM walk may
  break — re-verify with Playwright after DOT changes.

## Package Layout

| Path | What | AGENTS.md |
|---|---|---|
| `packages/purs-dagre/` | FFI → dagre. Publishable. | [`AGENTS.md`](packages/purs-dagre/AGENTS.md) |
| `packages/purs-viz/` | FFI → @viz-js/viz. Publishable. | [`AGENTS.md`](packages/purs-viz/AGENTS.md) |
| `examples/shared/` | Internal helpers shared by examples | [`AGENTS.md`](examples/shared/AGENTS.md) |
| `examples/dagre-demo/` | Interactive dagre playground (port 5173) | [`AGENTS.md`](examples/dagre-demo/AGENTS.md) |
| `examples/viz-demo/` | Interactive DOT playground (port 5174) | [`AGENTS.md`](examples/viz-demo/AGENTS.md) |
| `examples/showcase/` | 8-diagram showcase (port 5175) | [`AGENTS.md`](examples/showcase/AGENTS.md) |
| `docs/` | architecture, developer-guide, learning-path | — |
| `scripts/` | dev.sh, devcontainer build/push/save | — |
| `.devcontainer/` | Dockerfile + devcontainer.json | — |

## What to read before modifying each area

| Area | Read first |
|------|-----------|
| Library FFI | `packages/<lib>/AGENTS.md` + the existing `.purs` + `.js` pair |
| Halogen example | `examples/<app>/AGENTS.md` + `Main.purs` |
| Tailwind styles | `examples/<app>/src/styles.css` (theme tokens) + this file's "Tailwind" rule under Code Style |
| CI | `.github/workflows/ci.yml` + the `format:check` and `test` npm scripts |
| Devcontainer | `.devcontainer/Dockerfile` + `scripts/build-devcontainer.sh` |
