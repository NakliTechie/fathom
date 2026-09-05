#!/usr/bin/env bash
# forge stage: build the gate-level harness with Icarus Verilog.
#
# Icarus, not Verilator, for the netlist: Yosys emits the clock-gate latch as
# `always @*`, which Verilator settles as combinational feedback and gets wrong
# (the core never fetched). Icarus has event semantics for latches, and its VCD
# dumps every net in the netlist, which is join 3's source of truth.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/gates"
mkdir -p "$OUT"

iverilog -g2012 -o "$OUT/fathom_gates_sim" -s fathom_gates_tb \
  "$ROOT/build/synth/ibex_top_gates.v" \
  "$ROOT/forge/sim/fathom_mem.sv" \
  "$ROOT/forge/sim/fathom_gates_tb.sv" \
  2>&1 | grep -vE 'warning: .*(cannot be synthesized|non-integral variable)' || true
test -f "$OUT/fathom_gates_sim"
echo "built: $OUT/fathom_gates_sim"
