#!/usr/bin/env bash
# forge stage: SystemVerilog -> Verilog for the vendored Ibex core.
# Mirrors vendor/ibex/syn/syn_yosys.sh, minus the ASIC/liberty legs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IBEX="$ROOT/vendor/ibex"
OUT="$ROOT/build/synth/generated"
mkdir -p "$OUT"

PRIM="$IBEX/vendor/lowrisc_ip/ip/prim/rtl"
PRIMG="$IBEX/vendor/lowrisc_ip/ip/prim_generic/rtl"

DEPS=(
  "$PRIM/prim_count.sv" "$PRIM/prim_secded_inv_39_32_dec.sv"
  "$PRIM/prim_secded_inv_39_32_enc.sv" "$PRIM/prim_lfsr.sv"
  "$PRIMG/prim_and2.sv" "$PRIMG/prim_buf.sv"
  "$PRIMG/prim_clock_mux2.sv" "$PRIMG/prim_flop.sv"
)

fixup() { perl -pi -e 's/\bprim_(and2|buf|clock_mux2|flop)\b/prim_generic_$1/g' "$1"; }

for f in "${DEPS[@]}"; do
  m=$(basename "$f" .sv)
  sv2v --define=SYNTHESIS --define=YOSYS \
    "$PRIM/prim_count_pkg.sv" "$PRIM/prim_cipher_pkg.sv" \
    -I"$PRIM" "$f" > "$OUT/$m.v"
  fixup "$OUT/$m.v"
done

for f in "$IBEX"/rtl/*.sv; do
  m=$(basename "$f" .sv)
  case "$m" in *_pkg) continue;; esac
  sv2v --define=SYNTHESIS --define=YOSYS \
    "$IBEX"/rtl/*_pkg.sv "$PRIMG/prim_ram_1p_pkg.sv" \
    "$PRIM/prim_secded_pkg.sv" "$PRIM/prim_util_pkg.sv" \
    -I"$PRIM" -I"$IBEX/vendor/lowrisc_ip/dv/sv/dv_utils" \
    "$f" > "$OUT/$m.v"
  fixup "$OUT/$m.v"
done
echo "sv2v: $(ls "$OUT"/*.v | wc -l | tr -d ' ') modules -> $OUT"
