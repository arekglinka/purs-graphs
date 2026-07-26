# purs-viz

PureScript FFI bindings to [@viz-js/viz 3.x](https://github.com/mdaines/viz-js)
— full Graphviz DOT rendering via a WebAssembly build of Graphviz.

## What this gives you

- Build DOT source strings in PureScript (or accept user input)
- Render to SVG (or JSON, dot, plain) with any of 5 Graphviz layout engines
- Get an `Either` of the output string or an array of error messages — no exceptions cross the FFI boundary

This package is **render only** — you give it DOT, it gives you SVG. Pair it
with `setInnerHTMLById`-style FFI in your Halogen (or other UI) app to inject
the result into the DOM (see [`examples/viz-demo`](../../examples/viz-demo/)
and [`examples/showcase`](../../examples/showcase/) for working patterns).

## Install

`@viz-js/viz` is a peer-dependency — install it yourself so you control the version.

```bash
npm install @viz-js/viz@^3.28.0
spago install purs-viz
```

## Quick start

```purescript
module Main where

import Prelude
import Data.Either (Either(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (logShow)
import Viz (new)
import Viz.Render (renderString, Dot)

main :: Effect Unit
main = launchAff_ do
  viz <- new
  let
    dot = "digraph { rankdir=LR; a -> b -> c; }"
  liftEffect $ case renderString viz dot Nothing of
    Right svg -> logShow svg  -- "<?xml ...<svg ...>...</svg>"
    Left errs -> logShow errs
```

## API

### `Viz.Render` (idiomatic — recommended)

| Symbol | Type |
|---|---|
| `Engine` | `data` — `Dot` \| `Neato` \| `Circo` \| `Fdp` \| `Twopi` |
| `engineToString` | `Engine -> String` |
| `RenderError` | `type RenderError = String` |
| `RenderOptions` | `{ format :: String, engine :: Engine }` |
| `defaultRenderOptions` | `{ format: "svg", engine: Dot }` |
| `renderString` | `VizInstance -> String -> Maybe RenderOptions -> Either (Array RenderError) String` |
| `renderSVG` | `VizInstance -> String -> Maybe Engine -> Either (Array RenderError) String` |
| `renderJSON` | `VizInstance -> String -> Maybe Engine -> Either (Array RenderError) String` |

### `Viz` (raw FFI — usually not needed)

| Symbol | Type |
|---|---|
| `VizInstance` | opaque foreign type (a loaded WASM Graphviz) |
| `new` | `Aff VizInstance` (async — WASM instantiation) |
| `renderRaw` | `VizInstance -> { input, format, engine } -> RenderResultRaw` (sync) |
| `RenderResultRaw` | `{ status :: String, output :: Nullable String, errors :: Array { message :: String } }` |

## Architecture

Two-layer FFI pattern:

1. **`Viz`** — raw FFI: opaque `VizInstance`, async `new` via `makeAff`, sync `renderRaw` returning a raw `{ status, output, errors }` record.
2. **`Viz.Render`** — idiomatic API: `Engine` ADT, `Either (Array RenderError) String` results, no exceptions cross the boundary.

`Viz.js` wires up the async WASM instantiation via `_startInstance` (callbacks
into `Effect`) and the synchronous render call via `Fn4` (`runFn4` for uncurried
performance on saturated calls).

## Engines

| Engine | Use case |
|---|---|
| `Dot` | Hierarchical / flowchart-style directed graphs (default) |
| `Neato` | Spring-model layout for undirected graphs |
| `Fdp` | Force-directed placement |
| `Circo` | Circular layout |
| `Twopi` | Radial layout |

## Testing

```bash
spago test -p purs-viz
```

The test suite has unit specs (5) and `purescript-quickcheck` property tests
covering `engineToString` validity, well-formed digraph rendering, SVG output
prefix, and rejection of malformed DOT.

## License

MIT — see [../../LICENSE](../../LICENSE).
