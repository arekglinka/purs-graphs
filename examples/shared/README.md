# example-shared

Internal helpers shared across the three example apps. **Not published** —
exists only to deduplicate common SVG / FFI / layout plumbing between
[`dagre-demo`](../dagre-demo/), [`viz-demo`](../viz-demo/), and
[`showcase`](../showcase/).

## What it provides

| Module | Exports |
|---|---|
| `Example.Svg` | `svgEl`, `svgAttr` — Halogen SVG namespace helpers (`HH.elementNS` wrapper) |
| `Example.DagreRun` | `Position`, `buildAndLayout` — one-shot dagre layout runner |
| `Example.Viz` | `extractSvg`, `setInnerHTMLById` — viz.js output cleanup + raw HTML injection FFI |

## Usage

```purescript
import Example.Svg (svgEl, svgAttr)
import Example.DagreRun (buildAndLayout)
import Example.Viz (extractSvg, setInnerHTMLById)
```

Then add `example-shared` to your example's `spago.yaml` `dependencies:` list.

## Build

`example-shared` builds with the rest of the workspace — `spago build` from the
repo root. It depends on `purs-dagre` (for `buildAndLayout`).

## Why this exists

Without this package, the same ~40 lines of plumbing (`svgEl`, `svgAttr`,
`buildAndLayout`, `setInnerHTMLById` FFI + JS, `extractSvg`) would be
copy-pasted across dagre-demo and showcase (and viz-demo for the FFI). Central
here for DRY without polluting the publishable library packages.
