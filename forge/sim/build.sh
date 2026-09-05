#!/usr/bin/env bash
# forge stage: build the RTL simulation harness with Verilator.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IBEX="$ROOT/vendor/ibex"
PRIM="$IBEX/vendor/lowrisc_ip/ip/prim/rtl"
PRIMG="$IBEX/vendor/lowrisc_ip/ip/prim_generic/rtl"
DVU="$IBEX/vendor/lowrisc_ip/dv/sv/dv_utils"
OUT="$ROOT/build/sim/obj"

verilator --binary --timing -j 0 \
  -DRVFI -DSYNTHESIS=0 \
  --top-module fathom_tb \
  -Wno-fatal \
  --trace \
  -y "$IBEX/rtl" -y "$PRIM" -y "$PRIMG" \
  +incdir+"$PRIM" +incdir+"$DVU" +incdir+"$IBEX/rtl" \
  --Mdir "$OUT" -o fathom_sim \
  "$PRIM/prim_mubi_pkg.sv" "$PRIM/prim_secded_pkg.sv" "$PRIM/prim_util_pkg.sv" \
  "$PRIM/prim_count_pkg.sv" "$PRIM/prim_cipher_pkg.sv" \
  "$PRIMG/prim_ram_1p_pkg.sv" \
  "$IBEX/rtl/ibex_pkg.sv" "$IBEX/rtl/ibex_cheriot_pkg.sv" \
  "$ROOT/forge/sim/fathom_tb.sv"
echo "built: $OUT/fathom_sim"
