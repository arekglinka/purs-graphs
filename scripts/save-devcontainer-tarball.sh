#!/usr/bin/env bash
#
# Export the devcontainer image to a tarball for airgapped / shared-drive
# distribution (alternative to ghcr.io when registry access isn't available).
#
# Produces: purs-graphs-dev-<tag>.tar.gz + .sha256
#
# Recipients load it with:
#     sha256sum -c purs-graphs-dev-<tag>.tar.gz.sha256
#     gunzip purs-graphs-dev-<tag>.tar.gz
#     podman load -i purs-graphs-dev-<tag>.tar
#
set -euo pipefail

OWNER="${OWNER:-$(git remote get-url origin 2>/dev/null \
    | sed -E 's|.*[:/]([^/]+)/[^/]+$|\1|' || true)}"
OWNER="${OWNER:-YOUR_GH_OWNER}"

IMAGE="${IMAGE:-ghcr.io/${OWNER}/purs-graphs-dev}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
DATE_TAG="$(date -u +%Y%m%d)"
TAG="${TAG:-${SHORT_SHA}}"

log()  { printf '\033[1;34m[save]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[ok]\033[0m   %s\n' "$*"; }
die()  { printf '\033[1;31m[err]\033[0m  %s\n' "$*" >&2; exit 1; }

command -v podman >/dev/null 2>&1 || die "podman not found on PATH."

SOURCE="${SOURCE:-${IMAGE}:${TAG}}"
OUT_FILE="${OUT_FILE:-purs-graphs-dev-${TAG}.tar}"

if podman image exists "$SOURCE" 2>/dev/null; then
    log "Exporting local image ${SOURCE}..."
elif podman container exists "$SOURCE" 2>/dev/null; then
    log "Committing running container '${SOURCE}' to image first..."
    podman commit --format oci "$SOURCE" "${IMAGE}:${TAG}"
    SOURCE="${IMAGE}:${TAG}"
else
    log "Pulling ${SOURCE} from registry..."
    podman pull "$SOURCE"
fi

# gzip halves the file size; for a ~1 GB image this is ~500 MB output.
log "Saving to ${OUT_FILE} (this takes a few minutes)..."
podman save --format oci-archive -o "${OUT_FILE}.tmp" "$SOURCE"
mv "${OUT_FILE}.tmp" "$OUT_FILE"

log "Compressing + checksumming..."
gzip -6 "${OUT_FILE}" &
GZIP_PID=$!
sha256sum "${OUT_FILE}" > "${OUT_FILE}.sha256" &
SHA_PID=$!
wait "$GZIP_PID" "$SHA_PID"

COMPRESSED="${OUT_FILE}.gz"
SIZE_HR="$(numfmt --to=iec "$(stat -c%s "$COMPRESSED")")"
ok "Wrote: ${COMPRESSED} (${SIZE_HR})"
ok "Wrote: ${OUT_FILE}.sha256"
echo
ok "Share both files. Recipient runs:"
ok "  sha256sum -c ${OUT_FILE##*/}.sha256"
ok "  gunzip ${OUT_FILE##*/}.gz"
ok "  podman load -i ${OUT_FILE##*/}"
