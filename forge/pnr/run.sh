#!/usr/bin/env bash
# forge stage: place-and-route with OpenLane 2 (Docker backend), Sky130.
# Long-running. Output lands in forge/pnr/runs/<tag>/. D2 leg 2.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/forge/pnr"
export PDK_ROOT="${PDK_ROOT:-$HOME/.ciel}"
# OpenLane 2.3's Docker wrapper always attaches a TTY and has no flag not to,
# so a background run needs a pseudo-terminal: script(1) provides one.
mkdir -p "$ROOT/build"
script -q "$ROOT/build/openlane.log" \
  "$ROOT/.venv/bin/openlane" --dockerized --pdk-root "$PDK_ROOT" --pdk sky130A \
  --run-tag "fathom-$(date -u +%Y%m%dT%H%M%SZ)" config.json
