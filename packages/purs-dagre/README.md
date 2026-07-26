# purs-dagre

PureScript FFI bindings to [dagre 0.8.5](https://github.com/dagrejs/dagre) —
programmatic directed-graph layout for Node and the browser.

## What this gives you

- Build a directed graph in PureScript (nodes with dimensions, edges)
- Run dagre's layered layout algorithm
- Read computed x/y coordinates for each node
- Render the result with any SVG/canvas library of your choice (Halogen, smolder, …)

This package is **layout only** — it computes positions. It does NOT render.
Pair it with your own SVG rendering (see [`examples/dagre-demo`](../../examples/dagre-demo/)
and [`examples/showcase`](../../examples/showcase/) for Halogen HTML DSL examples).

## Install

`dagre` is a peer-dependency — install it yourself so you control the version.

```bash
npm install dagre@^0.8.5
spago install purs-dagre
```

## Quick start

```purescript
module Main where

import Prelude
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Console (logShow)
import Dagre.Graph

main :: Effect Unit
main = do
  g <- new
  setRankDir TopBottom g
  setNode { id: "a", width: 120.0, height: 50.0, label: "A" } g
  setNode { id: "b", width: 120.0, height: 50.0, label: "B" } g
  setEdge { source: "a", target: "b" } g
  layout g
  posA <- nodePosition "a" g
  posB <- nodePosition "b" g
  logShow posA  -- Just { x: ..., y: ... }
  logShow posB
```

## API

### `Dagre.Graph` (idiomatic — recommended)

| Symbol | Type |
|---|---|
| `Graph` | `newtype` (opaque mutable graph) |
| `RankDir` | `data` — `TopBottom` \| `BottomTop` \| `LeftRight` \| `RightLeft` |
| `rankDirToString` | `RankDir -> String` (`"TB"`, `"BT"`, `"LR"`, `"RL"`) |
| `NodeOptions` | `{ id :: String, width :: Number, height :: Number, label :: String }` |
| `Position` | `{ x :: Number, y :: Number }` |
| `new` | `Effect Graph` |
| `setRankDir` | `RankDir -> Graph -> Effect Unit` |
| `setNode` | `NodeOptions -> Graph -> Effect Unit` |
| `setEdge` | `{ source :: String, target :: String } -> Graph -> Effect Unit` |
| `layout` | `Graph -> Effect Unit` |
| `nodePosition` | `String -> Graph -> Effect (Maybe Position)` |
| `nodeIds` | `Graph -> Effect (Array String)` |
| `dimensions` | `Graph -> Effect (Maybe { width :: Number, height :: Number })` |

### `Dagre` (raw FFI — usually not needed)

Exposes the opaque `ForeignGraph` type and curried wrappers over `graphlib.Graph`.
Prefer `Dagre.Graph` unless you need a graphlib feature that's not surfaced yet.

## Architecture

Two-layer FFI pattern:

1. **`Dagre`** — raw FFI: opaque `ForeignGraph`, curried JS functions, `Nullable` returns.
2. **`Dagre.Graph`** — idiomatic API: `newtype Graph`, `RankDir` ADT, `Maybe`-wrapped results.

`Dagre.js` wraps dagre's mutable `graphlib.Graph` — operations mutate in place.
The PureScript `Graph` newtype prevents callers from reaching into the foreign
object directly.

## Testing

```bash
spago test -p purs-dagre
```

The test suite has unit specs (5) and `purescript-quickcheck` property tests
covering `rankDirToString` validity, node-id round-tripping, layout determinism,
and non-negative positions.

## License

MIT — see [../../LICENSE](../../LICENSE).
