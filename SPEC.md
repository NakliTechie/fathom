# Fathom — SPEC

The descent artifact, the correspondence table, and the contract the agent door answers to.
Companion to `FATHOM.md` (the handoff, which is normative on tier, claims and decisions).

Status: draft 1, 2026-09-05. Covers C0 only. C1–C5 extend it; they do not revise §1.

---

## 0. Agent contract

Fathom has two agent doors and they are not the same door:

- **`forge`** — the offline builder. Driven by a coding agent on the dev box.
- **`window.fathom`** — the browser instrument. Driven by an agent reading a descent.

Both answer to the ten DRIVER principles. This section is what subsequent design
decisions answer to; where a later choice conflicts with §0, §0 wins or §0 changes
explicitly.

### 0.1 The tower

Each layer consumes only the layer below. An agent enters at the altitude its task needs
and never has to reconstruct a lower layer to work at a higher one.

| # | Layer | Unit | Identity |
|---|---|---|---|
| L0 | source | line | `file:line` |
| L1 | IR | LLVM instruction | `ir:<func>:<n>` |
| L2 | machine code | static instruction | `pc` (byte address) |
| L2′ | execution | dynamic instruction | `xid` — monotonic retire index |
| L3 | architectural state | register file + traced memory, per cycle | `cycle` |
| L4 | microarchitecture | stage occupancy, per cycle | `cycle` |
| L5 | gates | net toggle events, per cycle | `cycle` |

`xid` is the load-bearing addition to the handoff's sketch. A `pc` is not unique in time —
a loop body executes it many times — so the descent cannot key on `pc` alone. `xid` is the
dynamic instance; `pc` is its static identity.

### 0.2 One perception act

`forge status` renders the whole build situation in one bounded read: which stages are
current, which artifact is committed, its hash, its verifier verdict, and the single next
command. An agent's first move is never `ls`.

In the browser, `fathom.describe()` is the same act: layers present, cycle range, current
position, artifact id, schema version. One call, bounded, no traversal.

### 0.3 Machine-decidable verdicts

Closed vocabulary. Every `forge` stage and every verifier assertion returns exactly one:

`OK` · `ORPHAN` · `AMBIGUOUS` · `SCHEMA` · `NONDETERMINISM` · `TOOLCHAIN` · `BUDGET`

One verdict maps to one next action. `ORPHAN` and `AMBIGUOUS` are distinct because the
remedies differ: an orphan means a join key was never emitted; an ambiguity means two
sources claim the same key. Every non-`OK` verdict carries `{verdict, where, remedy}`
where `remedy` is a literal command.

### 0.4 Bounded output

`forge verify` green is one line. Failures print at most 20 exemplars per verdict class
plus a total count, never the full orphan set — the full set goes to
`build/verify-report.json`. Output grows with *divergence*, never with trace length.

`window.fathom` queries are cycle-scoped or range-scoped; there is no call that returns
the whole descent. `export(range)` requires an explicit range and refuses an unbounded one.

### 0.5 Crash safety and idempotence

Every `forge` stage writes to a temp path and renames atomically. An interrupted build
leaves the previous artifact intact — never a hybrid. Every stage is safe to re-run and
is a no-op when its inputs are unchanged (content-hash stamps, not mtimes — mtimes are
the classic nondeterminism leak).

### 0.6 Where the trajectory lives

`build/journal.jsonl` — append-only, one record per stage invocation: stage, input hash,
output hash, verdict, wall-clock. The anti-circling device lives in the tool: an agent
that has failed the same join three ways can see that in the journal without holding it
in context. `forge status` renders the journal's tail.

### 0.7 Accretion mechanism

Every orphan class the verifier catches becomes a named assertion with a fixture in
`forge/tests/`. A join failure found once cannot recur silently. The verifier's assertion
list only grows.

### 0.8 The evaluator boundary — fail closed

`forge verify` and the schema validator are not writable by the build. The artifact is an
*input* to the verifier, never an output of it. If the verifier cannot run — missing
toolchain, unreadable artifact — the verdict is `TOOLCHAIN`, which is **not green**.
There is no path where absence of evidence renders as `OK`.

In the browser: the schema validator is the single ingress. `loadDescent` on an artifact
that fails validation renders nothing and reports `SCHEMA`. Fathom never paints a partial
descent.

### 0.9 Self-check

- [x] Single perception act — `forge status` / `fathom.describe()`
- [x] Closed verdict vocabulary with remedies
- [x] Output bound stated — grows with divergence, not trace length
- [x] Crash safety — temp + atomic rename, content-hash stamps
- [x] Trajectory — `build/journal.jsonl`, rendered by `forge status`
- [x] Accretion — every caught orphan class becomes a permanent assertion
- [x] Tower drawn — §0.1
- [x] Evaluator boundary — §0.8, fail closed on `TOOLCHAIN`

---

## 1. The spine

> **Every layer's state is keyed to a single monotonic cycle index, and every cycle
> carries a resolvable link upward to instruction → source line and downward to the gate
> events it caused.**

`cycle ∈ [0, N)`, integer, no gaps. Cycle 0 is the first cycle after reset deasserts.

### 1.1 The anchor, and what a bubble is

A pipelined core has several instructions in flight in one cycle. "Every cycle resolves
to exactly one instruction" therefore needs a definition, not an assumption.

**Definition.** Each cycle has exactly one **anchor**: the `xid` occupying the core's
designated anchor stage in that cycle. The anchor stage is declared once per core in
`core.json` (for a multi-cycle core it is the whole core; for a five-stage pipeline it is
`EX`). `L4` still carries *every* stage's occupancy — the anchor is what the descent
follows, not what it shows.

**A bubble is a value, not a hole.** Cycles where the anchor stage holds no instruction
carry `anchor: null` with a required `stall: {cause}` drawn from a closed vocabulary
(`reset` · `fetch` · `load-use` · `branch-flush` · `mem-wait` · `halt`). This is the one
place the C0 checkpoint's "zero orphans" needs reading with care:

- an **orphan** is an id that does not resolve — a build failure;
- a **bubble** is a typed, caused absence — legitimate, and the thing the instrument
  most wants to show.

A cycle with `anchor: null` and no `stall.cause` is an orphan and fails the build.

### 1.2 The three joins

| Join | Source of truth | Mechanism |
|---|---|---|
| `file:line ↔ ir ↔ pc` | DWARF line table, `clang -g -O0` | `.debug_line` decoded per instruction address |
| `pc ↔ xid ↔ cycle` | the core simulator's trace | we own the emitter; it stamps every retire |
| `cycle ↔ net toggle` | gate-level sim VCD | `cycle = floor((t − t₀) / T_clk)` |

Conventions that must be fixed or the joins wobble:

- **Clock.** `t₀` = the first rising edge after reset deassert; `T_clk` constant, declared
  in `core.json`. A toggle exactly at an edge belongs to the cycle the edge *opens*.
- **Glitches.** Multiple toggles of one net inside one cycle collapse to
  `{net, count}`. The count is kept — it is real switching activity — but the descent
  does not model intra-cycle time.
- **Traced region.** The descent covers `[pc_start, pc_end)` declared in `program.json`.
  Reset vector and any startup stub outside that region are excluded by construction, not
  by silently dropping unresolvable rows. Excluded cycles are excluded from `N`.

### 1.3 Totality, asserted

`forge verify` asserts, over the whole artifact:

1. every `toggle.cycle` resolves to exactly one `cycle` in `[0, N)`;
2. every `cycle` carries an `anchor` that is either a resolvable `xid` or `null` with a
   `stall.cause` in the closed set;
3. every `xid` resolves to exactly one `pc`;
4. every `pc` in the traced region resolves to ≥ 1 `file:line`;
5. every `pc` resolves to ≥ 1 `ir` id, or is listed in `program.json:no_ir` with a reason
   (expected members: compiler-emitted prologue/epilogue fill, alignment padding);
6. no `xid` is referenced that no cycle anchors;
7. no `file:line` claimed present that the source file does not contain;
8. the artifact round-trips the schema validator byte-identically.

Assertions 5 and 7 are additions to the handoff's four. 5 exists because `-O0` still emits
instructions with no IR ancestor and the honest move is an explicit allow-list with
reasons, not a silent pass. 7 exists because a line number that points past end-of-file is
the failure mode a line-table bug actually produces.

---

## 2. The artifact

One file for C0: `artifacts/<program>/descent.json`. The gate layer moves to `.parquet`
at C3 if size demands it; the schema keeps the layer separable for exactly that reason.

```jsonc
{
  "schema": "fathom.descent/1",
  "artifact_id": "<sha256 of the canonical serialization, minus this field>",
  "program": { "name": "...", "source_files": ["..."], "pc_start": 0, "pc_end": 0,
               "no_ir": [{ "pc": 0, "reason": "..." }] },
  "core":    { "name": "...", "licence": "...", "shape": "five-stage | multi-cycle | ...",
               "stages": ["IF","ID","EX","MEM","WB"], "anchor_stage": "EX",
               "t_clk_ps": 0, "t0_ps": 0 },
  "cycles":  0,                                  // N

  "source":  { "<file>": ["line 1 text", "..."] },
  "ir":      [{ "id": "ir:main:7", "text": "...", "line": "<file>:12" }],
  "code":    [{ "pc": 0, "bytes": "...", "asm": "...",
                "lines": ["<file>:12"], "ir": ["ir:main:7"] }],

  "exec":    [{ "xid": 0, "pc": 0, "cycle_first": 0, "cycle_retire": 0 }],

  "arch":    { "encoding": "delta",              // full state at cycle 0, deltas after
               "x0": [/* ... */],
               "frames": [{ "cycle": 0, "regs": { "sp": 0 }, "mem": [{ "addr": 0, "val": 0 }] }] },

  "pipe":    [{ "cycle": 0, "anchor": 0, "stall": null,
                "stages": { "IF": 3, "ID": 2, "EX": 1, "MEM": 0, "WB": null } }],

  "gates":   { "nets": ["<net name>"],           // index → name, interned
               "toggles": [{ "cycle": 0, "net": 0, "count": 1 }] }
}
```

Notes that are decisions, not prose:

- **Architectural state is delta-encoded.** Full frames at every cycle is the obvious
  encoding and it is quadratic-ish in size for no gain; `stateAt(layer, cycle)` in the
  agent face is what reconstructs. Cycle 0 carries the full frame so reconstruction never
  needs a second source.
- **Net names are interned.** The gate layer's size is dominated by the name strings, not
  the events.
- **`artifact_id` is content-addressed** over a canonical serialization (sorted keys, no
  insignificant whitespace, fixed number formatting). This is the C1 determinism check's
  subject.
- **No timestamps, no absolute paths, no build-host identifiers anywhere in the
  artifact.** Every one of those is a determinism leak and C1's checkpoint is
  byte-identity across two clean runs.

---

## 3. The v1.0 program (D4)

**Chosen 2026-09-05: a called function with a real stack frame, whose body performs a
memory-mapped write.** Freestanding C, `-O0`, no libc, no `printf`.

Rationale: the handoff requires D4 to bottom out in a memory-mapped write — that is what
"print" is once the abstractions are gone — and a call frame is the more comprehensive
story, so the program does both rather than choosing. In one ~25-instruction trace it
exercises a call and return, a prologue/epilogue touching the stack, a loop with a
backward branch, a load, and a store to a memory-mapped address.

```c
/* uart_puts.c — freestanding, -O0, no libc */
#define UART_TX ((volatile unsigned char *)0x10000000)

static void uart_putc(char c) { *UART_TX = (unsigned char)c; }

static void uart_puts(const char *s) {
    while (*s) { uart_putc(*s); s++; }
}

void _start(void) {
    uart_puts("hi\n");
    for (;;) { }          /* halt: the trace's declared end */
}
```

Why each element is present:
- `uart_putc` — the memory-mapped store. The bottom of the descent.
- `uart_puts` — the call frame: `sp` adjustment, `ra` spill, restore, `ret`.
- `while (*s)` — the load and the backward branch, which is where the pipeline layer
  earns its place (branch flush, and a load-use adjacency).
- `"hi\n"` — three characters keeps the trace short enough to render whole.

`pc_end` is the address of the infinite loop; the trace stops on first reaching it.

### 3.1 Measured, 2026-09-05

Built and linked; numbers below are measurements, not estimates.

- **42 static instructions**, `pc_start = 0x8000_0000`, `pc_end = 0x8000_00a4`.
- The memory-mapped store is `80000090: lui a1, 0x10000` / `80000094: sb a0, 0x0(a1)`.
  The bottom of the descent exists as specified.
- **20 DWARF line-table rows**, carrying column numbers, `is_stmt`, and `prologue_end`.
  Join 1 has more resolution than the spec assumed — `file:line:col`, not just `file:line`.
- Layout: ROM at `0x8000_0000`, RAM at `0x8001_0000`, MMIO window at `0x1000_0000`
  (`forge/program/link.ld`).

**The dynamic count overshoots the handoff's D4 constraint.** FATHOM.md §5 asks for
~10-30 instructions. Static is 42; the *dynamic* trace — what the descent actually
renders — is ~94, because `uart_puts` calls `uart_putc` once per character and `-O0`
spills to the stack at every step. Three characters is what makes it ~94.

Levers, if 94 is too long: emit one character instead of three (~46 dynamic); or drop
`uart_puts` and call `uart_putc` directly (~25, but loses the loop and one call frame).
Both are one-line edits. Unresolved — see `plan/pending.md`.

---

## 4. Toolchain

Fixed for C0:

- **`clang` from Homebrew LLVM**, targeting `riscv32-unknown-elf`, with `ld.lld`.
  Apple's system clang has no RISC-V target. Deliberately **no `riscv-gnu-toolchain`**:
  clang alone covers freestanding RV32I, and the handoff's chain names clang for the IR
  leg anyway — adding GCC would mean two compilers disagreeing about the line table.
- **Yosys** for synthesis to a gate netlist.
- **Icarus Verilog** (present) for gate-level simulation and VCD.
- **Verilator** (present) as the fast RTL path if the cycle trace needs it.
- **Python 3.12** + **GNU Make** for `forge`.

---

## 5. The core (D1) — closed 2026-09-05

**Ibex**, pinned at `34b0705760ef3dfa00e99637432473d2be8f22f3`, Apache-2.0, vendored unmodified
under `vendor/ibex/`. Licence basis in `PERMISSIONS.md`.

Configured **by parameter only**, at synthesis time (`forge/synth/synth.ys`):

| Parameter | Value | Why |
|---|---|---|
| `BaseIsa` | `BaseIsaRV32I` (0) | the target ISA |
| `RV32M` | `RV32MNone` (0) | no multiplier — dead logic in the gate layer otherwise |
| `RV32B` | `RV32BNone` (0) | no bit-manipulation |
| `RV32ZC` | `RV32Zca` (0) | minimum; this Ibex has no fully-`None` option |
| `WritebackStage` | `1` | **three stages: IF · ID/EX · WB** |
| `BranchTargetALU`, `ICache`, `BranchPredictor`, `SecureIbex`, `PMPEnable` | `0` | keep the netlist to the story |

### 5.1 Why Ibex, and the shape it actually has

D1's tension (FATHOM.md §5, §8.3) is the canonical five-stage picture versus the
permissive cores that exist. Resolved by **labelling, not by drawing a pipeline the core
does not have** — Fathom says "a three-stage RV32I core" everywhere, never "five-stage".

Ibex wins on the two things C0 is actually at risk on, both of which it already has
in-tree:

1. **RVFI** — the RISC-V Formal Interface, a standardised per-retire trace port, already
   on `ibex_core` (514 references in `ibex_core.sv`). Join 2 gets a standard rather
   than a bespoke emitter tapped into internals.
2. **A Yosys synthesis flow** (`vendor/ibex/syn/`), so the gate leg is a known-good
   path rather than a research project.

Considered and rejected:

- **VexRiscv** (MIT) — genuinely five-stage and configurable, so it is the one core that
  would give the canonical picture honestly. Rejected on build cost: no pre-generated
  Verilog and no release assets, so `forge` would need JVM + sbt + SpinalHDL to emit
  RTL. That makes the pipeline non-hermetic for the sake of two stages. **Revisit if the
  three-stage picture proves to under-serve the pipeline layer** — this is the one
  reversal in the stack that is worth its cost.
- **PicoRV32** (ISC) and **SERV** (ISC) — both eliminate layer L4 rather than shrink it.
  PicoRV32 is multi-cycle: there is no pipeline to show. SERV is bit-serial: ~32 cycles
  per instruction, so L4 becomes a shift register. Neither can carry the microarchitecture
  layer the product is built around.
- **darkriscv** (BSD-3), **neorv32** (BSD-3) — permissive and small, but neither ships an
  RVFI port or a maintained Yosys flow, so both cost more than Ibex at every leg.

### 5.2 The anchor stage

Ibex with `WritebackStage=1` has IF · ID/EX · WB. **Anchor stage = ID/EX** — the stage
where an instruction executes, which is what the descent follows. Retire is observed at
WB via RVFI, which is what stamps `cycle_retire`. Both facts go in `core.json`
(SPEC §2) so no layer infers them.

### 5.3 Synthesis, measured 2026-09-05

`forge/synth/sv2v.sh` then `yosys -s forge/synth/synth.ys`:

- 38 modules through sv2v; `ibex_top_tracing` and `ibex_tracer` excluded — they are
  simulation-only and `$finish` at elaboration demanding a global RVFI define.
- **8091 cells** after `abc -g AND,OR,XOR,NAND,NOR,XNOR,MUX` and `opt_clean -purge`:
  **883 flip-flops** and **7208 combinational gates**
  (`$_AND_` 2076, `$_NAND_` 3376, `$_MUX_` 631, `$_OR_` 478, `$_NOR_` 204,
  `$_XOR_` 171, `$_XNOR_` 156, `$_NOT_` 115).
- **4.31 s** wall-clock, 170 MB peak.
- Outputs: `build/synth/ibex_core_gates.v` (720 KB),
  `build/synth/ibex_core_gates.json` (4.5 MB).

7208 combinational gates is the number layer L5 has to survive. It is inside the range
aggregation can carry (FATHOM.md §8.2's legibility risk is not retired, but it is now
quantified rather than feared).

### 5.4 The trace emitter

Ours to build regardless, but thinner than assumed: RVFI gives retire events with the
architectural deltas already attached. What `forge` adds is the **cycle-accurate**
half — per-cycle stage occupancy and stall causes, which RVFI does not expose — tapped
from the ID/EX and WB stage-valid signals in the simulation wrapper, never from the
synthesised netlist.


---

## 6. C0 measurements — the simulation and join legs, 2026-09-05

### 6.1 The harness

`forge/sim/fathom_tb.sv` — Ibex + one flat 128 KiB memory at `0x8000_0000` + a
memory-mapped UART at `0x1000_0000`. Verilator 5.050, `--binary --timing`, `-DRVFI`.
Zero-latency grant, one-cycle response; out-of-range accesses `$fatal` rather than wrap
(SPEC §0.8, fail closed).

**Ibex's reset vector is `boot_addr_i + 0x80`**, and `boot_addr_i` must be 256-byte
aligned. The program is therefore linked at `0x8000_0080`, not `0x8000_0000` — putting the
program at the vector rather than un-aligning the boot address. `forge/program/mkimage.py`
pads the image by `0x80` so word index stays `(addr - MemBase) / 4`.

`crt0.S` sets `sp` and enters `fathom_main`. It is outside `[pc_start, pc_end)` by
construction (§1.2) — without it `_start` ran with `sp` uninitialised.

### 6.2 The run

- **95 retires in 136 cycles**, IPC 0.70. `pc_end = 0x8000_00ac`, the self-loop.
- **The memory-mapped write happens**: `0x1000_0000` receives `0x68 0x69 0x0a` at cycles
  43, 74, 105. The bottom of the descent is observed, not assumed.
- **A store's effect precedes its retire by 2 cycles** — the UART log records cycles 41,
  72, 103 against retires at 43, 74, 105. The descent must render this honestly rather
  than collapsing effect and retire onto one cycle.
- Simulation wall-clock: 0.007 s.

### 6.3 Join totality — the C0 risk, probed

`forge/join/probe_joins.py`, run by `make probe`:

| Join | Result |
|---|---|
| 1 — `pc -> file:line:col` | **45/45 distinct executed pcs resolve. Zero orphans.** |
| 2 — `cycle -> anchor` | 136 cycles, ID/EX occupied 132, **4 bubbles (3%)** |
| 3 — `cycle -> gate toggle` | **131,172 events, 11,149 nets, 137 cycles. Zero silent cycles, zero orphans.** |

FATHOM.md §8.1's risk is retired for join 1 **on this program class** (freestanding C,
`-O0`, one translation unit plus an assembly stub). It is not retired in general, and
join 3 is untested.

**132 occupied cycles against 95 retires** means an instruction sits in ID/EX for several
cycles. §1.1's "exactly one anchor per cycle" holds as a **many-to-one** relation:
consecutive cycles legitimately share an `xid`. The verifier must assert one anchor per
cycle, never one cycle per instruction.

### 6.4 A correction to §1.2 — the file index is not a key

The DWARF file index alone does **not** identify a source file. Every compile unit numbers
its own file table from 0, so `crt0.S` and `uart_puts.c` are both `file[0]` and their line
numbers silently merge — the first probe run reported `line 7: 7 retires` where the truth
was `crt0.S:7` 2 and `uart_puts.c:7` 5.

**Join 1's key is `(compile unit, file index, line, column)`**, resolved to a source path
via that CU's own file table. This is an `AMBIGUOUS`, not an `ORPHAN`: the ids resolved,
they resolved to the wrong thing, and a totality count alone would never have caught it.
Verifier assertion 7 (§1.3) is extended: two distinct sources must not share a key.

### 6.5 The gate leg and join 3 — 2026-09-05, later

**Top is `ibex_top`, not `ibex_core`** (decision recorded in `plan/history.md`): the
register file lives in `ibex_top`, and the netlist has to run the program standalone.
**13,213 cells** — 1,877 flip-flops, one latch (the clock gate), 11,335 combinational —
in 5.17 s.

**Two simulators, deliberately.** RTL runs under Verilator; the netlist runs under Icarus.
Yosys emits the clock-gate latch as `always @*`, which Verilator settles as combinational
feedback and gets wrong — the core never fetched. Icarus has event semantics for latches,
and its VCD dumps every net in the netlist. Verilator's `--binary` trace produced a VCD
with zero variables besides. The split is recorded in `forge/sim/build_gates.sh`.

**RTL == gates, asserted** (`forge/join/check_equiv.py`, `make equiv`): 137/137 cycles,
0 mismatches, 48 data requests each, 131 instruction fetches each, UART bytes on identical
cycles. Comparison follows the bus protocol — `instr_addr` under `instr_req`, data columns
under `data_req` — because outside a request Verilator reads 0 and Icarus reads `x`, and
neither is a core difference. That masking is the only leniency and it is stated in the
script.

**Join 3** (`forge/join/vcd_toggles.py`, `make toggles`): `t₀ = 85,000 ps` on both sides
by construction, `T_clk = 10,000 ps`. 131,172 raw toggle events collapse to 130,899
`(cycle, net)` pairs — 273 intra-cycle glitches. Toggles per cycle: min 6, median 904,
max 2,691 (cycle 3, the first post-reset fetch). 7,764 events before `t₀` dropped and
counted (reset); 383 after the halt dropped and counted (the one extra edge). **4,822 of
11,149 nets toggle at least once** across the run; the other 6,327 are static for this
program — CSR, PMP-adjacent and debug logic the program never reaches. That static
majority is itself a fact the gate layer should show, not hide.

Three harness faults found and fixed on the way, all simulator-portability bugs in *my*
code, none in the core:
- **Reset-release race** — `rst_n = 1` as a blocking assignment on a `posedge` is resolved
  differently by Verilator and Icarus. Released on the `negedge` now.
- **Icarus's default timescale is 1 s.** With no `` `timescale ``, `#5` meant five seconds
  and every VCD event landed 10¹² past `t₀` — and my parser **dropped them silently**. The
  parser now counts post-end drops and fails `TOOLCHAIN` when the VCD range cannot contain
  `t₀`. A silent drop is a §0.8 violation in its own right.
- **`$finish` on the halt edge raced the logger** for that edge's row. The gate run now
  runs one edge past the halt and the RTL run is the reference length.

`toggles.json` is 1.7 MB for 137 cycles — the gate layer's size is the events, not the
names, and `.parquet` at C3 remains the plan for longer traces.


---

## 7. C0 and C1 checkpoints — met, 2026-09-05

### 7.1 `forge verify`

`forge/verify.py` reads **only** the committed artifact and the source tree — never
`build/` — and fails closed. Eight assertions from §1.3 plus the cells layer's totality.
Green is one line. Failures print at most 20 exemplars per verdict class and the total.

`make verify` runs it on every committed artifact. All three pass 8/8.

### 7.2 Determinism (C1)

Two consecutive `make clean && make programs` runs: **34 s wall-clock each**, all three
artifacts **byte-identical** to the committed ones and to each other. `git status
artifacts/` is empty after either run. This held without any dedicated work: canonical
serialisation, no timestamps, no absolute paths, interned names, and a harness whose
`t₀` is fixed by construction were enough.

| artifact | descent.json | gates.parquet | cells.parquet | cycles | exec | gate toggles | cell toggles |
|---|---|---|---|---|---|---|---|
| `uart_puts` | 1.88 MB | 0.12 MB | 0.61 MB | 137 | 95 | 120,179 | 388,823 |
| `popcount` | 1.91 MB | 0.22 MB | 1.31 MB | 259 | 174 | 250,996 | 821,938 |
| `chase` | 1.87 MB | 0.06 MB | 0.31 MB | 80 | 45 | 66,241 | 214,706 |
| `sum` | 1.89 MB | 0.14 MB | 0.84 MB | 175 | 119 | 162,277 | 537,393 |

The two toggle tables are Parquet (zstd, one row group, no statistics, no writer string —
byte-identical across writes, so the determinism check covers them). `descent.json`
carries each table's row count and sha256, and the content address covers both. As
JSON, `popcount` was 15 MB; as JSON + Parquet it is 3.4 MB, of which the JSON's 1.9 MB
is now mostly net and cell **names** — the next size lever, if C2 needs one, is
interning those.

### 7.3 The three programs

| program | teaches | static | dynamic | stalls (held) |
|---|---|---|---|---|
| `uart_puts` | a call frame, a loop, a memory-mapped write | 45 | 95 | branch 18 · load-use 17 |
| `popcount` | data-dependent branches, taken and not | 50 | 174 | branch 45 · load-use 29 · 6 branch-flushes |
| `chase` | load-use on every hop of a pointer walk | 25 | 45 | branch 13 · load-use 15 |
| `sum` | **two translation units**; an extern call across them | 60 | 119 | — |

Join 1 is total on all four. The program class the claim now covers: freestanding C,
`-O0`, **one or more translation units** plus the assembly stub, static and extern
functions, `const` data in ROM. `sum` resolves 60/60 pcs across three source files in
two compile units — the (compile unit, file index) key from §6.4 doing its job. Not
covered: inlining, anything above `-O0`, and division (`-march=rv32i` has no `M`, and
there is no compiler-rt by design — `__divsi3` is an undefined symbol, which is the
honest boundary of a freestanding RV32I program).

### 7.4 What the traces say about the core

With a zero-latency memory, **Ibex never waits on memory** — `mem-wait` and `wb-stall`
appear in no artifact. Every held cycle is control (`branch`: taken branches and jumps
take two cycles) or data (`load-use`). The vocabulary keeps both names for a memory with
latency; the artifacts say what is true for this one.

`load-use` is named by its **signature**, not by instruction kind: the instruction
arrived (`id_new`), was stalled (`id_ready=0`) while a load was outstanding in WB
(`ld_out`); the held row is the cycle after. It fires on a dependent `lw` and on a
`beqz` consuming a loaded value alike. Naming by kind mislabelled both.

---

## 8. Layer L6 — cells (D2, leg 1)

`descent.json` gains `cells`: PDK, library, corner, the cell-type table (72 types), all
11,004 cells with their type, the nets, and per-cycle toggles from running the same
program on the `sky130_fd_sc_hd` netlist. `make equiv` asserts RTL == gates **and** RTL
== sky130 on every cycle. The claims vocabulary for this layer: *"mapped to Sky130
standard cells, typical corner"* — the PDK is named; nothing is placed yet.

Synthesis: `dfflibmap` + `abc -liberty` + one techmap for the clock-gate latch
(`$_DLATCH_N_` → `dlxtn_1`, which `dfflibmap` does not cover). 97,586 µm², 1,877
sequential cells — the same 1,877 the generic netlist has, which is the check that the
mapping lost nothing.

**`ResetAll = 1`, set on the generated `ibex_top.v`.** Ibex resets only the flops
function needs; the remaining 345 start X in a gate-level sim, and the PDK's cell
primitives propagate that X into the fetch address (the generic netlist had merged it
away through Verilog's `?:`). `ibex_top` pins `ResetAll` to `Lockstep` as a localparam,
so `forge/synth/sv2v.sh` sets it on the *generated* Verilog — a forge knob, not an edit to
vendored source. Both netlists carry it; the three programs re-verified with upper layers
unchanged.

### 8.1 Place-and-route (D2, leg 2) — closed 2026-09-05

`forge/pnr/`: OpenLane 2.3.10 under Docker, `sky130A`, `FP_CORE_UTIL 18` (928 I/O pins
need a 3155 µm perimeter). The flow ran synthesis → floorplan → placement → CTS → detailed
routing → fill → GDS streamout → LVS (**passed**) → antenna check, reaching step 68 of 78
and stopping without writing `final/`; step 52's DEF is the placed, routed, filled design
and is what the coordinates come from.

| metric | value |
|---|---|
| die | 831.8 × 842.5 µm, 700,733 µm² (0.70 mm²) |
| instances | 23,284 (13,740 logic incl. 3,995 clock/hold buffers and 370 antenna diodes; 59,811 fill/decap/tap) |
| utilisation | 24.9 % |
| wirelength | 888 k µm |
| setup slack, tt | **−3.69 ns** against a 10 ns clock (≈ 73 MHz would close) |
| hold slack, tt | +0.17 ns |
| routing DRC | **3,589** after three iterations |
| antenna | **68** violating pins, 60 nets |

**Placed and routed, not tape-out clean.** The claims vocabulary for L6 is *"placed and
routed on Sky130; timing and DRC as reported"* and the artifact carries the numbers in
`cells.pnr`. Closing timing and DRC is engineering the instrument does not need; it needs
the geometry to be real, and it is.

### 8.2 The join by name — and why the routed netlist is the cells layer

The plan was: run my Yosys netlist, read the DEF, join toggles to coordinates by instance
name. **Zero of 11,004 names overlapped** — not the flops either. Two synthesis runs of
the same RTL (`abc` on my side, OpenLane's Yosys flow on theirs) share no instance
naming, and OpenLane renames what it keeps.

So the cells layer is **OpenLane's post-fill netlist** (`forge/pnr/out/ibex_top.nl.v`),
whose instance names are the DEF's by construction. It runs the same programs under the
same harness against the PDK's cell models; RTL == routed netlist on every cycle for all
four programs. The verifier asserts every listed cell is placed inside the die and that
placed == netlist by name (one Verilog escaped identifier, `\core_clock_gate_i.u_icg`,
normalised). Fill, decap and tap cells are omitted from the artifact's list and counted:
they carry no signal.

**The physical design is pinned, not built** — `forge/pnr/out/` holds the netlist
(4.7 MB), the coordinates (4.6 MB) and the flow metrics, with a README. Place-and-route
is neither byte-deterministic nor fast (≈ 40 min under Docker), so `forge` treats these
as inputs, the same posture as the vendored core. A regeneration is a deliberate,
recorded change. C1's byte-identity claim is over the chain from pinned inputs.

The earlier `synth_sky130.ys` mapping (11,004 cells, 97,586 µm²) stays in the repo as
the fast, deterministic cell mapping; it is no longer a layer.

### 8.3 Sizes, with the physical layer

| artifact | descent.json | gates.parquet | cells.parquet | cell toggles |
|---|---|---|---|---|
| `uart_puts` | 3.25 MB | 0.12 MB | 0.88 MB | 595,019 |
| `popcount` | 3.28 MB | 0.22 MB | 1.82 MB | 1,214,059 |
| `chase` | 3.24 MB | 0.06 MB | 0.45 MB | 325,059 |
| `sum` | 3.26 MB | 0.14 MB | 1.15 MB | 775,968 |

The JSON is ~3.2 MB regardless of program: 13,740 placed cells with names and
coordinates, and ~14 k net names. Cell toggles rose ~50 % over the un-routed netlist —
the clock tree is real switching activity.


---

## 9. C2 — the shell and the upper layers, 2026-09-05

`fathom.html` — one file, 300 lines, no build step. Dense direction; JetBrains Mono at
400/700, four sizes, true neutrals only, eight layer accents. Loads
`artifacts/<program>/descent.json` through the schema validator as the single ingress
(SPEC §0.8): a failing artifact renders nothing and reports the verdict.

Layers landed: **source** (every file in the artifact, retire counts per line) · **IR** ·
**assembly** (anchor, IF and WB rows marked) · **architectural state** (x0–x31 and last
stores, delta-decoded from RVFI, changed registers marked) · **pipeline** (one column per
cycle, IF / ID-EX / WB rows, anchor · held · stall · occupied · retire as token colours,
click to seek). One scrub bar; `←`/`→` step a cycle, `⇧` ×10, `Home`/`End`.

**Agent face** (`window.fathom`): `loadDescent` · `describe` · `layers` · `seek` ·
`stateAt(layer, cycle)` · `trace(xid)` · `history` · `timing`. Every call is recorded
with its door (`ui` / `agent`), so History tells a click from a call. Driven from the
browser pane: `seek(43)` lands on xid 31 with `a0 = 0x68` and `a1 = 0x1000_0000` in the
architectural state — the UART store's operands at its retire cycle.

**Checks.** Static (`forge/design/check.py`, 4/4): every colour a token (31 tokens, 0
stray literals); zero tinted neutrals (9 neutral tokens, channel spread < 8); 3 sizes × 2
weights = 6 type styles at the Dense budget; shipped weights = used weights. Runtime, by
computed style in the browser pane: no blank band across five layers; three distinct
interaction-state backgrounds (`row` / `hot` / `now`); both font faces loaded; four type
styles in use.

**The 5 s frame.** `fathom.timing()` reads a `performance.mark` set when the layers are
built: **84 ms** from navigation start on localhost with the 3.25 MB artifact (response
6 ms, DOMContentLoaded 14 ms). On a 30 Mbit connection the fetch alone is ≈ 0.9 s; the
frame is inside the gate with margin. A cold-cache capture over a real network is the
C5 measurement, not this one.

**Not in C2:** the gate and cells layers (C3: DuckDB-wasm over the Parquet tables, the
gate layer aggregated with step-in, the cells layer as a floorplan on the real die), and
`?` help (C5).

## 10. C1, re-checked against the pinned physical design

Clean build, four programs, from the pinned `forge/pnr/out/`: **32 s**, all four
artifacts byte-identical to the committed ones, `git status artifacts/` empty.


---

## 11. C3 — the bottom, 2026-09-05

Two layers, both **lazy**: a button or `fathom.loadBottom()` imports the vendored
DuckDB-wasm (18 MB, same-origin, never on the first-frame path), registers
`gates.parquet` and `cells.parquet`, and runs one ordered scan per layer into typed
columns with per-cycle offsets. **A step is then an array slice, never a query.**
Pulling the block out removes both layers and nothing above them changes.

DuckDB's ESM imports `apache-arrow` as a bare specifier and expects a bundler. Fathom has
none, so it ships an import map and single-file ESM builds of apache-arrow 13.0.0,
flatbuffers 23.5.26 and tslib 2.6.2 with their cross-package imports rewritten to
relative paths. No CDN at runtime (`PERMISSIONS.md`).

**Gates (L5)** — a strip, one bar per cycle, height ∝ toggle events; step-in lists the
cycle's nets by toggle count. **Cells (L6)** — the floorplan: a canvas of the
832 × 842 µm die, all 13,740 placed cells drawn dark once, the cycle's switching cells
lit through each cell's driven net, and a side list by cell type. Both follow the scrub.

**Checkpoint, measured on `popcount`** (259 cycles, 251 k gate rows, 1.21 M cell rows):

| | |
|---|---|
| first frame | 45 ms |
| load, gates | 1.38 s (212 KB Parquet, 137→259 bars, no cycle missing) |
| load, cells | 2.68 s (1.68 MB Parquet, 13,740 cells, 4,528 drivers) |
| one-cycle step, both layers live | **7.3 – 18.2 ms** (budget 100 ms) |
| gate cycle == pipe cycle | asserted at load (no cycle missing from the table) and on every step (bar == column == scrub) |

At cycle 122 of `popcount` (a branch flush): 1,172 gate toggles, 2,428 cells switching.
At cycle 43 of `uart_puts` (the first UART store retiring): 3,922 cell toggles on 2,615
nets, 1,107 cells lit — a `mux2_4` at (656, 305) µm among them.

**What the floorplan is honest about.** 4,567 of 13,740 logic cells drive a net that
toggles in `uart_puts`; the rest are placed and dark for this program and are drawn so.
Fill, decap and tap cells are not drawn: they are the die's background, not the machine.
The cell footprint is drawn at a fixed four-site width; real per-cell widths are a later
refinement, not a truth issue — the position is the DEF's.


---

## 12. C4 — descent and time-travel, 2026-09-05

**`descend(layer, selector)`** puts a layer in focus and resolves a selector on it to the
cycle the descent follows — a source line to the first cycle it ran, an IR id or a pc
likewise, a register to the first cycle it was written, a cycle number as itself — and
pushes the stop on a **trail**; **`ascend()`** pops it. The focused layer opens, its two
neighbours stay open as context, the rest fold to their headers; `Esc` opens everything.
`↓`/`↑`, clicking a layer's header, a source line, or an assembly row do the same through
the `ui` door. `describe()` reports `focus` and `depth`; `trail()` the stops.

**Checkpoint — `forge/test/descent.test.js`.** Drives a full descent and a full ascent
**through `window.fathom` only**; the DOM is read for assertions, never driven. At every
stop it asserts the pipe, gate and cell cycles equal the scrub, the bar and the column;
that focus and depth are what the face reports; on the way up, that each stop returns
to its recorded cycle; and that exactly `2 × stops` agent-door calls were recorded.

Observed in the browser pane on `uart_puts`: `ok: true` — seven stops
(`source@35 → ir@35 → asm@35 → arch@6 → pipe@6 → gates@6 → cells@6`), seven ascents
back to all layers, 14 agent-door calls, zero console errors. The cycle moves as
selectors resolve — line 5 first ran at 35; `sp` was first written at 6 — and the trail
carries each stop's cycle so the ascent lands where the descent was.

On the other three programs, from the browser pane: `popcount` `ok` (`source@15 … cells@6`),
`chase` `ok` (`source@8 … cells@6`), `sum` `ok` (`source@8 … cells@6`), 14 agent-door calls
each, zero console errors.

**Harness.** The test needs a browser (canvas, wasm). The repo has no Playwright harness;
today the script runs from the browser pane. One `forge/test/` Playwright harness that
C5's guide capture also uses satisfies FATHOM.md's "no second harness". Pending a word.
