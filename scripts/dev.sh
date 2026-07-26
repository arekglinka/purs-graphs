#!/usr/bin/env bash
#
# Launch a Vite dev server with HMR + auto-rebuild on .purs save.
# Usage: ./scripts/dev.sh [dagre-demo|viz-demo|showcase]   (default: dagre-demo)
#
# Runs two processes concurrently:
#   1. watchexec — watches .purs files, runs `spago build` on change
#      (spago's backend config auto-runs purs-backend-es → output-es/)
#   2. vite — dev server with HMR, picks up output-es/ changes automatically
#
set -euo pipefail

EXAMPLE="${1:-dagre-demo}"

case "$EXAMPLE" in
    dagre-demo|viz-demo|showcase) ;;
    *)
        echo "Usage: $0 [dagre-demo|viz-demo|showcase]" >&2
        exit 1
        ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/examples/$EXAMPLE"

export PATH="$REPO_ROOT/node_modules/.bin:$PATH"

log()  { printf '\033[1;34m[dev]\033[0m %s\n' "$*"; }

log "Initial build..."
(cd "$REPO_ROOT" && spago build)

log "Starting watcher (spago) + dev server (vite) for $EXAMPLE..."
log "  Vite:  http://localhost:$(case "$EXAMPLE" in dagre-demo) echo 5173;; viz-demo) echo 5174;; showcase) echo 5175;; esac)"
log "  Edit .purs files → auto-rebuild → HMR"

exec concurrently \
    -n "spago,vite" \
    -c "blue,green" \
    "watchexec -w $REPO_ROOT/packages -w $REPO_ROOT/examples -e purs -- sh -c 'cd $REPO_ROOT && spago build'" \
    "vite --host 0.0.0.0 --config $EXAMPLE_DIR/vite.config.ts $EXAMPLE_DIR"
