# Contributing to purs-graphs

Thanks for your interest in contributing! This is a PureScript monorepo for
graph-visualization FFI bindings + Halogen example apps.

## Prerequisites

- A working devcontainer runtime (Podman recommended, Docker works).
- VSCode with the "Dev Containers" extension.

## Getting set up

1. Clone the repo.
2. **Reopen in Container** (VSCode pulls the prebuilt image — no local toolchain install needed).
3. Run `spago build` from the repo root to build all packages + examples.

See [`docs/developer-guide.md`](docs/developer-guide.md) for per-package build/run/debug instructions.

## Code style

- PureScript is formatted with **purs-tidy** (format-on-save is enabled in the devcontainer).
- TypeScript/JavaScript is formatted with **Biome** (`npx biome check --write .`).
- Bash scripts must pass `bash -n` (CI enforces this).

## PureScript conventions

- Use algebraic data types for graph elements, not raw records.
- FFI side effects live in `Effect`; pure wrappers wrap them where possible.
- Return `Maybe`/`Either` for nullable/throwable FFI — never throw from PureScript.
- Newtype-wrap foreign types: `newtype Graph = Graph (Ref ForeignGraph)`.
- No `unsafePerformEffect` outside test modules.

## Committing

This repo follows [Conventional Commits](https://www.conventionalcommits.org/):
`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

## Pull requests

- Keep PRs focused — one package or one example per PR where possible.
- CI must pass: `spago build`, `spago test` (both packages), both example `vite build`s.
- Add or update tests for any FFI behaviour change.

## Releasing

Releases are triggered by pushing a `v*` tag. The `release.yml` workflow bundles
the FFI bindings (esbuild, with the underlying JS libs as external peer-deps) and
attaches them to a GitHub Release. Consumers depend on the JS libs themselves so
they can dedupe across the dependency tree.
