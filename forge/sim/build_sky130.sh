#!/usr/bin/env bash
# forge stage: build the Sky130 cell-netlist harness with Icarus Verilog.
# Same testbench as the generic gates. The DUT is the PINNED place-and-route
# netlist (forge/pnr/out/ibex_top.nl.v, module ibex_top): its instance names are
# the DEF's, so the cells layer joins toggles to coordinates by name. The cells
# come from the PDK's functional models; the PDK path is the one external input.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PDK="${FATHOM_PDK:-/Users/chiragpatnaik/.ciel/ciel/sky130/versions/1689ac3f2dc763876eaf967227c7dfe831b031ae/sky130A}"
CELLS="$PDK/libs.ref/sky130_fd_sc_hd/verilog"
OUT="$ROOT/build/sky130"
mkdir -p "$OUT"
iverilog -g2012 -o "$OUT/fathom_sky130_sim" -s fathom_gates_tb \
  -DFATHOM_NETLIST=ibex_top -DFUNCTIONAL -DUNIT_DELAY='#0' \
  "$CELLS/primitives.v" "$CELLS/sky130_fd_sc_hd.v" \
  "$ROOT/forge/pnr/out/ibex_top.nl.v" \
  "$ROOT/forge/sim/fathom_mem.sv" \
  "$ROOT/forge/sim/fathom_gates_tb.sv" \
  2>&1 | grep -vE 'warning: .*(cannot be synthesized|non-integral variable|timescale)' || true
test -f "$OUT/fathom_sky130_sim"
echo "built: $OUT/fathom_sky130_sim"
