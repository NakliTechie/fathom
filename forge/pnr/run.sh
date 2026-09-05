#!/usr/bin/env bash
# forge stage: place-and-route with OpenLane 2, Sky130. D2 leg 2. Long-running.
#
# The container is run directly rather than through `openlane --dockerized`:
# that wrapper always attaches a TTY (-t) and 2.3.10 has no flag not to, so it
# cannot run from a background shell. Same image, same arguments, no -t.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IMAGE="${OPENLANE_IMAGE:-ghcr.io/efabless/openlane2:2.3.10}"
PDK_ROOT="${PDK_ROOT:-$HOME/.ciel}"
TAG="fathom-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$ROOT/build" "$ROOT/forge/pnr/runs"
docker run --rm -i \
  -v "$ROOT/forge/pnr:/work" -v "$PDK_ROOT:/pdk" -w /work \
  -e PDK_ROOT=/pdk -e PDK=sky130A \
  "$IMAGE" \
  openlane --pdk-root /pdk --pdk sky130A --run-tag "$TAG" config.json
echo "run: forge/pnr/runs/$TAG"
