---
description: PureScript FFI bindings to dagre for directed-graph layout. Layout-only — pair with your own renderer.
tags: [purs-dagre, ffi, dagre, layout]
---

# purs-dagre

## Architecture

- `src/Dagre.purs` — raw FFI: opaque `ForeignGraph`, curried wrappers, `Nullable` returns.
- `src/Dagre.js` — JavaScript side of the FFI: wraps dagre's mutable `graphlib.Graph`.
- `src/Dagre/Graph.purs` — idiomatic API: `newtype Graph`, `RankDir` ADT, `Maybe`-wrapped results.
- `test/Main.purs` — `purescript-spec` + `purescript-quickcheck` tests.

## Build & Test

```bash
spago build -p purs-dagre
spago test  -p purs-dagre
```

## Public API (publishable)

`Dagre.Graph` exports: `Graph`, `RankDir`, `rankDirToString`, `NodeOptions`,
`Position`, `new`, `setRankDir`, `setNode`, `setEdge`, `layout`, `nodePosition`,
`nodeIds`, `dimensions`.

`Dagre` exports the raw FFI for callers who need direct access.

## Gotchas

- **dagre is a peer-dep**: consumers install `dagre@^0.8.5` themselves. Don't bundle it.
- **Mutable graph**: `setNode`/`setEdge`/`setRankDir` mutate in place. Don't share a `Graph` across threads or expect immutability.
- **Layout must be called before positions**: `nodePosition` returns `Nothing` until `layout` has run.
- **Coordinate origin**: dagre positions are non-negative from the top-left origin. The library doesn't shift them.
- **CJS interop in Vite**: if a downstream app uses Vite, it must `optimizeDeps.include: ["dagre"]` to force pre-bundling (dagre ships CommonJS).

## Conventions (overrides root)

- The public API (`Dagre.Graph`) is publishable. Changes here ripple to consumers — bump the version semantically.
- Internal FFI in `Dagre.js` may change freely; `Dagre.purs` signatures are the stable interface.
