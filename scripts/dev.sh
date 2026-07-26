#!/usr/bin/env bash
#
# Launch a Vite dev server with HMR for the chosen example.
# Usage: ./scripts/dev.sh [dagre-demo|viz-demo]   (default: dagre-demo)
#
# Requires: spago build to have produced output/ for the example's package.
# The Vite config re-bundles on .purs save via purs-backend-es watch mode.
#
set -euo pipefail

EXAMPLE="${1:-dagre-demo}"

case "$EXAMPLE" in
    dagre-demo|viz-demo) ;;
    *)
        echo "Usage: $0 [dagre-demo|viz-demo]" >&2
        exit 1
        ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$REPO_ROOT/examples/$EXAMPLE"

log()  { printf '\033[1;34m[dev]\033[0m %s\n' "$*"; }

log "Building PureScript for $EXAMPLE (first run cold; subsequent runs cached)..."
(cd "$EXAMPLE_DIR" && spago build)

log "Starting Vite dev server with HMR on http://localhost:5173 ..."
exec npx vite --config "$EXAMPLE_DIR/vite.config.ts" "$EXAMPLE_DIR"
