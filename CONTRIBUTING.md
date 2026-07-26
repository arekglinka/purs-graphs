# Contributing to purs-graphs

Thanks for your interest in contributing! This is a PureScript monorepo for
graph-visualization FFI bindings + Tailwind-styled Halogen example apps.

## Prerequisites

- A working devcontainer runtime (Podman recommended, Docker works).
- VSCode with the "Dev Containers" extension.

## Getting set up

1. Clone the repo.
2. **Reopen in Container** (VSCode pulls the prebuilt image — no local toolchain install needed).
3. Run `npm install` then `npm run build` from the repo root to build all packages + examples.

See [`docs/developer-guide.md`](docs/developer-guide.md) for per-package build/run/debug instructions.

## Code style

- PureScript is formatted with **purs-tidy** (config in `.tidyrc.json`, format-on-save is enabled in the devcontainer).
- TypeScript/JavaScript/JSON is formatted with **biome** (`npx biome check --write .`).
- CSS follows Tailwind v4 conventions (`@import "tailwindcss"`, `@theme`, `@layer base`).
- Bash scripts must pass `bash -n` (CI enforces this).

Before committing, run:

```bash
npm run format       # purs-tidy + biome, in place
npm run format:check # CI gate — exits non-zero if unformatted
```

## PureScript conventions

- Prefer **Hooks** (`Hooks.component`) for new Halogen components. Use classic `H.mkComponent` only for parent-child communication, queries, or perf-critical paths.
- Use algebraic data types for graph elements, not raw records.
- FFI side effects live in `Effect`; pure wrappers wrap them where possible.
- Use `Effect.Uncurried` (`EffectFn1/2/3`, `runEffectFn1/2/3`, `mkEffectFn1/2/3`) for multi-arg JS functions.
- Return `Maybe`/`Either` for nullable/throwable FFI — never throw from PureScript.
- Newtype-wrap foreign types: `newtype Graph = Graph ForeignGraph` (or `foreign import data` for fully-opaque types).
- Derive instances with `derive newtype instance` — don't hand-roll boilerplate.
- No `unsafeCoerce`/`unsafePerformEffect` outside test modules (and only with a justifying comment there).
- No type-error suppression (PureScript has no `as any` / `@ts-ignore` equivalent — and don't use `unsafeCoerce` to mimic it).

## Tailwind conventions

- Use Tailwind v4 via `@tailwindcss/vite` plugin — no PostCSS config, no `tailwind.config.js`.
- Per-app `src/styles.css` contains `@import "tailwindcss"`, `@theme { ... }`, `@layer base`, and any raw CSS for FFI-injected SVG.
- In Halogen, use `HP.class_ (cn "...")` where `cn = HH.ClassName` (defined at module level per app).
- Theme tokens (brand colors, fonts) go in the `@theme` block — they auto-generate utilities (`bg-brand`, `text-brand`, etc.).
- **Never** convert SVG presentation attributes (`fill`, `stroke`, `viewBox`, `marker-end`, etc.) to Tailwind classes. They stay as `svgAttr` calls.
- `HP.id "svg-container"` is an FFI contract — don't rename it in any example.

## Testing conventions

- Tests use `purescript-spec` + `spec-node` (runner) + `purescript-quickcheck` (property tests).
- Each library package has a `test/Main.purs` with both unit specs AND `purescript-quickcheck` property tests under a `describe "Property tests"` block.
- For FFI behaviour changes, add or update both a unit spec AND a property test where feasible.

## Committing

This repo follows [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

## Pull requests

- Keep PRs focused — one package or one example per PR where possible.
- CI must pass:
  - `npm run format:check`
  - `npm run build` (all packages + examples)
  - `npm test` (both library packages)
  - All three example `vite build`s
- Add or update tests for any FFI behaviour change.
- After touching `index.html` or `styles.css`, rebuild the example and verify the Tailwind CSS bundle size is non-zero (Tailwind v4 silently no-ops on config errors).

## Releasing

Releases are triggered by pushing a `v*` tag. The `release.yml` workflow bundles
the FFI bindings (esbuild, with the underlying JS libs as external peer-deps) and
attaches them to a GitHub Release. Consumers depend on the JS libs themselves so
they can dedupe across the dependency tree.
