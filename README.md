# Fathom

**One event, followed down every layer of the machine, on one clock.**

Live at **[fathom.naklitechie.com](https://fathom.naklitechie.com)**.

Pick a moment in a running program and see it in seven places at once: the C source line,
the compiler's IR, the assembly, the register file, the pipeline, the gate netlist, and the
standard cells switching on a real chip floorplan. Press play and watch the machine run.

The machine is a **three-stage RV32I core** — lowRISC's Ibex, vendored unmodified —
synthesised to gates with Yosys, mapped to Sky130 standard cells, and placed and routed with
OpenLane. It is not the computer in front of you, and it is not x86: it is a small real core
we can show completely, which is the point.

## What makes it different

Godbolt shows source → assembly. Python Tutor shows execution state. Ripes shows a pipeline.
Visual6502 shows transistors. cpu.land narrates the whole descent and simulates none of it.
None of them connect to the next. **Fathom is the join** — one artifact, one cycle index, every
layer keyed to it, and a verifier that fails the build if a single event cannot be resolved
from source line to switching cell.

## How it is built

Two artifacts, and nothing heavy runs in the browser:

- **`forge/`** — an offline pipeline. `clang` → IR and DWARF line tables → RV32I ELF; the
  program run on the RTL under Verilator (RVFI for retires, stage taps for occupancy); the
  same program run on the synthesised netlist and on the placed-and-routed netlist under
  Icarus; the VCDs joined into one `descent.json` plus two Parquet tables.
- **`index.html`** — a single file that renders a committed artifact. No build step.

`make programs` builds all four artifacts from clean in ~30 s, byte-identically.
`make verify` runs nine assertions over each committed artifact and is the only thing
allowed to say the word "done". `forge/test` is the browser harness.

Four programs ship: a call frame writing to a memory-mapped port, a branchy loop, a pointer
chase full of load-use stalls, and a call across two translation units.

## Honest limits

Placed and routed, **not tape-out clean**: setup slack is −3.69 ns against a 10 ns clock,
with 3,589 routing DRC errors and 68 antenna-violating pins — all reported inside the
artifact. Join totality is proven for freestanding C at `-O0`; inlining and `-O1` are not
covered. The physical design is pinned rather than rebuilt, because place-and-route is
neither fast nor deterministic.

`SPEC.md` is the working spec and carries every measurement; `FATHOM.md` is the original
handoff, left as written.

## Licence

AGPL-3.0-only. Vendored dependencies and their bases are listed in `PERMISSIONS.md`.
