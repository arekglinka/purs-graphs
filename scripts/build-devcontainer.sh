#!/usr/bin/env bash
#
# Build the devcontainer image from .devcontainer/Dockerfile and bake in the
# PureScript toolchain + spago global cache (the equivalent of postCreateCommand,
# but committed into the image so teammates can pull instead of rebuild).
#
# Used by:
#   - .github/workflows/devcontainer.yml (CI publishes to ghcr.io)
#   - Local "rebuild from scratch" invocations when the Dockerfile changes
#
# Requires: podman, ghcr.io login (already done in CI; locally run
#           `gh auth token | podman login ghcr.io -u <user> --password-stdin`).
#
set -euo pipefail

# Derive the GH owner from the origin remote so this is enterprise-forkable.
# Override with OWNER=... for non-standard setups (e.g. cross-org publishing).
# The sed handles both SSH (git@github.com:owner/repo.git) and HTTPS URLs.
OWNER="${OWNER:-$(git remote get-url origin 2>/dev/null \
    | sed -E 's|.*[:/]([^/]+)/[^/]+$|\1|' || true)}"
OWNER="${OWNER:-YOUR_GH_OWNER}"

IMAGE="${IMAGE:-ghcr.io/${OWNER}/purs-graphs-dev}"
REGISTRY="${REGISTRY:-ghcr.io}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Use short SHA for the immutable tag, plus 'latest' mutable pointer and a
# date-stamped tag for human-readable rollbacks.
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
DATE_TAG="$(date -u +%Y%m%d)"
TAG="${TAG:-${SHORT_SHA}}"

log()  { printf '\033[1;34m[build]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m   %s\n' "$*"; }
die()  { printf '\033[1;31m[err]\033[0m  %s\n' "$*" >&2; exit 1; }

command -v podman >/dev/null 2>&1 || die "podman not found on PATH."

BASE_IMAGE="localhost/purs-graphs-dev-base:${TAG}"

log "Building base image from .devcontainer/Dockerfile (installing purs/spago/vite toolchain)..."
podman build \
    -f .devcontainer/Dockerfile \
    -t "$BASE_IMAGE" \
    .

# Run postCreateCommand-equivalent inside a temp container, then commit.
# This bakes the global spago/purs package cache + a warm build of every
# package + example into the image so teammates skip the cold-start phase.
#
# --entrypoint '[]' clears the Lambda base image's ENTRYPOINT (which points
# at the Lambda Runtime Interface Emulator and would otherwise try to invoke
# our command as a Lambda handler, causing immediate container exit). This is
# the documented handoff pattern for AL2023 Lambda-style base images.
PREP_CONTAINER="devcontainer-prep-${TAG}"
log "Running spago install + build inside prep container (warms the cache)..."
podman rm -f "$PREP_CONTAINER" 2>/dev/null || true

# Bind-mount the workspace so that the build output (output/) lands in the host
# tree for THIS run only — the committed image captures ~/.spago + system state,
# not the workspace (which is bind-mounted per-user at open time).
podman run --name "$PREP_CONTAINER" \
    --entrypoint '[]' \
    -v "$REPO_ROOT:/workspaces/purs-graphs:Z" \
    -w /workspaces/purs-graphs \
    "$BASE_IMAGE" \
    bash -lc '
        set -euo pipefail
        cd /workspaces/purs-graphs
        npm ci || npm install
        spago install
        spago build
        for pkg in packages/purs-dagre packages/purs-viz; do
            spago test --config "$pkg/spago.yaml" || true
        done
    '

# Container has now exited but its filesystem (including ~/.spago + npm cache)
# is preserved — commit captures that state into the final image.
log "Committing prep container as image..."
FINAL_IMAGE="${IMAGE}:${TAG}"
podman commit \
    --format oci \
    "$PREP_CONTAINER" \
    "$FINAL_IMAGE"
podman tag "$FINAL_IMAGE" "${IMAGE}:latest"
podman tag "$FINAL_IMAGE" "${IMAGE}:dev-${DATE_TAG}"

podman rm "$PREP_CONTAINER" >/dev/null

ok "Built: ${FINAL_IMAGE}"
ok "Tagged: ${IMAGE}:latest, ${IMAGE}:dev-${DATE_TAG}"

if [[ "${PUSH:-1}" == "1" ]]; then
    log "Pushing to ${REGISTRY}..."
    podman push "${IMAGE}:${TAG}"
    podman push "${IMAGE}:latest"
    podman push "${IMAGE}:dev-${DATE_TAG}"
    ok "Pushed 3 tags to ${REGISTRY}"
fi

ok "Done. Teammates: git pull, then 'Reopen in Container' (image pull ~1-2 min)."
