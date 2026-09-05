# FATHOM

**Tier: Tool.** Single artifact, sovereign, browser-native, maintained.
**Direction: Dense** (DIRECTIONS.md) — a workbench, operated for hours.
**Unity sentence:** *One event, followed down every layer of the machine, on one clock — an instrument for people who want to see the join, not read about it.*

Deploys to `fathom.naklitechie.com`. Repo `NakliTechie/fathom`. AGPL-3.0.

---

## 1. Thesis

Every layer between a line of source and a switching transistor has a good tool. Not one of them connects to the next.

Godbolt shows you source → assembly. Python Tutor shows you execution state. `python-bytecode-explorer` shows you bytecode. Ripes, Simulizer and a dozen course projects show you an instruction crossing a pipeline. Visual6502 shows you transistors switching. cpu.land — the best thing in this space — narrates the whole descent in prose and simulates none of it. Nand2Tetris builds upward from gates and never meets real code coming down.

**Nobody has shipped a continuous descent.** You cannot take one event, pick a layer, and follow it up or down with shared state and a single scrub-bar. That is the artifact. The gap is not "another CPU visualiser"; the gap is *the join*.

Fathom is that instrument: pick a program, pick a moment, and move through source · IR · assembly · architectural state · microarchitectural cycle · gate netlist — all keyed to the same clock, all showing the same instant.

---

## 2. The honest-machine decision

The obvious framing — *"what happens when Python runs `print()` on your laptop"* — cannot be delivered honestly. The real chain is `print()` → bytecode → ceval loop → CPython's C → libc → `write` syscall → kernel tty → x86-64 microarchitecture → transistors. **No transistor-level model of a modern x86-64 exists or will.** The bottom of that descent isn't available at any price, and manufacturing it would be exactly the claim inflation the portfolio refuses.

So: **keep the question, change the machine.**

```
C source  →  clang IR  →  RV32I assembly  →  architectural state
          →  pipeline cycles  →  gate netlist  →  (optional) standard cells
```

Every join is real. Nothing is a stand-in. We own or vendor every layer, so every layer can be instrumented honestly. RISC-V RV32I is small enough to render, mature enough to have permissive cores and a real toolchain, and the Yosys / Sky130 leg overlaps the toolchain literacy Hardlith is already buying.

**The "print" story arrives as v1.1**, not v1.0 — a Python-subset front end sits *above* a working spine as two more layers (bytecode + interpreter loop). Building it first would mean building the hardest layers last, which is the wrong order and always has been.

### Claims vocabulary — binding

Fathom describes the machine it actually simulates. Permitted: *"a five-stage RV32I core, synthesised to gates."* Forbidden, in UI copy, README, portfolio card, and any post: "your CPU," "how your laptop works," "x86," "down to the silicon" without naming the PDK, and any phrasing that lets a reader infer the descent runs on the machine in front of them. Where a layer is a model rather than a measurement, the layer's own header says so. Same discipline as Beagle's *"Darwin/XNU, never iOS in the browser."*

---

## 3. Architecture — two artifacts

Rove's shape: a browser app plus an offline preprocessing pipeline whose outputs are committed.

```
forge/                     (offline, Python + Make, runs on the dev box)
  clang → IR + DWARF line tables
  clang → RV32I ELF → objdump
  core simulator → per-cycle architectural + pipeline trace
  Yosys → gate netlist → gate-level sim → toggle events
  join pass → descent.json  (+ optional .parquet for the gate layer)

fathom.html                (single file, ships the app)
  loads a committed descent artifact, renders six layers, one scrub-bar
```

**Precompute is not an optimisation, it is rule 2.** Nothing compiles or synthesises in the browser. A descent artifact is built once, committed, and served static. Cold load shows a useful frame in under 5 s or the build has failed, whatever else passes.

### The spine — the correspondence table

Everything else is a view. The one invariant:

> **Every layer's state is keyed to a single monotonic cycle index, and every cycle carries a resolvable link upward to instruction → source line and downward to the gate events it caused.**

Join keys, and where each comes from:

| Join | Source of truth |
|---|---|
| source line ↔ IR ↔ instruction | DWARF line tables from clang, `-g -O0` |
| instruction ↔ cycle | the core simulator's own trace — we control the emitter |
| cycle ↔ gate toggle | gate-level sim VCD, timestamps aligned to the same clock |

Orphans on any join are a build failure, not a rendering nicety. The verifier asserts totality (§7, C0).

### Sidecar posture

**v1.0 ships no AI.** The tool stands completely without it and the quality floor for "explain this instruction" isn't met by anything we'd want to ship. Petri's precedent. A sidecar that annotates a selected layer in prose is a v1.2 candidate; it proposes text, never touches the trace, and pulling it out changes nothing. Removability is trivially satisfied because the artifact is precomputed and deterministic.

---

## 4. Locked decisions

1. **Name:** Fathom. Subdomain `fathom.naklitechie.com`. Locked, no sweep.
2. **Target ISA:** RISC-V RV32I.
3. **No live compilation or synthesis in the browser, ever, in v1.x.**
4. **Descent artifacts are committed to the repo**, not fetched from a service.
5. **Vendor the core; don't write one.** Build Doctrine — no NIH on commodity plumbing. Permissive licence required (Apache-2.0 / ISC / BSD class). Whatever is chosen goes in `PERMISSIONS.md` with its licence basis, Beige precedent.
6. **The C64 chip-level visualiser is dropped, not parked.** It was scoped as Beige's successor before a better substrate existed. It teaches the opposite lesson — a whole machine at one instant (breadth) rather than one instruction all the way down (depth) — and shares only the scrub-bar. Its descent chain has no compiler leg, no RTL, and no synthesis step; the bottom layer is a polygon mesh extracted from die photographs, not a netlist we generate. **Do not resurrect it as a second target on this chassis.** Fathom is the portfolio's only descent engine. Beige remains unaffected as an emulator.
7. **Agent face is mandatory**, `window.fathom` + `navigator.modelContext` where present, parity linted.

---

## 5. Open decisions — close before C1 opens

| # | Decision | Note |
|---|---|---|
| **D1** | **Which core.** A classic five-stage textbook pipeline is the canonical picture and the one people came to see; the permissive cores that actually exist (PicoRV32 — ISC, multi-cycle; Ibex — Apache-2.0, two-stage; SERV — bit-serial) are all something else. Vendor an honest real core and label its shape, or vendor a teaching five-stage if a permissive one exists. **Do not build one to make the diagram prettier.** | Blocks C1 |
| **D2** | **How deep the bottom goes.** Gate netlist only, or push through Sky130 standard cells to a physical layer. Gates are sufficient for the claim; cells buy the Hardlith overlap and a much better final frame. | Blocks C3 |
| **D3** | **Type family.** Dense direction, one family, mono-adjacent, two weights minimum, chosen per tool — never inherited from the scaffold. Distinctiveness pass lands here. | Blocks C2 |
| **D4** | **The v1.0 program.** Something ~10–30 instructions that bottoms out in a memory-mapped write — which is what "print" actually *is* once the abstractions are gone. Not `printf`; libc drags in hundreds of instructions and buries the story on day one. | Blocks C0 |

---

## 6. Roadmap

**v1.0 — the descent, one program.** Six layers, one committed artifact, one scrub-bar, progressive disclosure between layers, keyboard-first, generated guide, agent face at parity. Ships when a person can select a source line and watch the gates that line causes to toggle.

**v1.1 — Python on top.** A Python-subset front end adds bytecode and interpreter-loop layers above the existing spine. This is where *"how does `print` work"* becomes answerable end to end, on a machine we can name.

**v1.2 — the library, and possibly a sidecar.** Three to five programs chosen to teach different things (a branch, a load-use hazard, a function call and its stack frame). Optional prose annotation sidecar, gated on quality.

**v1.3 — live build, opt-in.** A bridge-hosted `forge` run so a person can descend their *own* program. Never the first-run path; `nakli-local-bridge`, not a new broker.

**Non-roadmap, ever:** x86 or ARM targets · an OS layer · claiming to model the reader's own machine · accounts · telemetry · a hosted compile service.

---

## 7. Agent handoff

Read this whole file before writing a line. Chunks are large and autonomous: name internals, pick implementations, debug, and try alternatives freely. Stop only at a genuine blocker — a conflict with a locked decision, a new dependency, or scope ambiguity that changes what the product is.

**Loop exits.** Same root-cause failure three times → stop, write the tried-trail to `STATE.md`, escalate. Per-chunk budget cap applies. Escalating with a readable trail is success behaviour.

**"Done" is the verifier's word.** Every checkpoint below is machine-checkable and runs in a fresh context with no knowledge of what the maker built. The checker's first question is whether the goal was gamed — a deleted or skipped test is the classic hack.

### C0 — Spine spike. Riskiest assumption first.

Build nothing user-facing. Take the D4 program, run it through the whole chain by hand, and produce one `descent.json` plus a verifier.

**Checkpoint:** `make verify` exits 0, asserting — every gate toggle event resolves to exactly one cycle; every cycle resolves to exactly one instruction; every instruction resolves to at least one source line; zero orphans in either direction; the artifact round-trips through the schema validator. If the joins can't be made total, that is the finding, and it is worth more than any amount of UI. Escalate rather than paper over.

### C1 — `forge`, the pipeline

Make the C0 hand-run reproducible: one `make` target, source in, committed artifact out. Deterministic — same input, byte-identical artifact.

**Checkpoint:** two consecutive clean runs produce identical output hashes; verifier still green; artifact size and build wall-clock recorded in `STATE.md`.

### C2 — Shell and the upper layers

`fathom.html`. Source · IR · assembly · architectural state. Tokens first (D3), then layout. One ingress: the artifact passes the schema validator before anything renders.

**Checkpoint:** timeline captures at 0 s / 5 s / 30 s / failure — the 5 s frame is useful, not a spinner, not scaffolding. Four deterministic checks pass at the Dense budgets: line count within budget and every line traceable to a token; zero tinted neutrals (channel spread ≥ 8 on a value meant to be neutral); ≤ 6 type styles per screenful; no blank or pending band. Interaction states probed by computed style, not photographed. Weight availability verified against the shipped family.

### C3 — The bottom

Pipeline-cycle layer and gate layer. Throttling is the real problem: gate activity cannot be painted per cycle at any honest rate. Aggregate, then let a person step into a single cycle. Precedent worth reading before designing this: Visual6502's ~1 kHz ceiling is the wall everyone hits.

**Checkpoint:** stepping one cycle at the gate layer renders under 100 ms at the floor viewport; the cycle shown at the gate layer and the cycle shown at the pipeline layer are asserted equal by a test, not by eye.

### C4 — Descent and time-travel

The actual product: click a source line, descend; scrub, and all six layers move together. Progressive disclosure between adjacent layers — never six panels shouting at once. Keyboard-first, conflicts resolved and documented.

**Checkpoint:** a headless test drives a full descent and a full ascent **through the agent face, not the DOM**, and asserts layer coherence at every stop. A tool that can't be exercised through its own agent face isn't testable.

### C5 — Close-out

Version string in UI and meta tag. `?` on the welcome screen, generated guide with reproducibly-captured screenshots. `PERMISSIONS.md` for the vendored core and any bundled artifact. Portfolio and profile updated in plain what-it-does-for-a-user language — no model names, no line counts. One forward pass in fresh context: logical errors, security issues, stubs. One rubric pass at ship, worst-first, fixed in order: flow → structure → ornament → spacing → type → tokens → states → motion.

**Checkpoint:** forward-pass list empty; manifest ⊇ command bus lint green; guide builds; timeline check still passes on the shipped file.

### Hard NOTs

- No compilation, synthesis, or simulation in the browser in v1.x.
- No network at runtime. Artifacts are static and same-origin.
- No claim, anywhere, that this is the reader's own machine or an x86 one.
- No writing our own CPU core.
- No AI in v1.0.
- No `localStorage` beyond UI preferences and last position — the artifact is the source of truth and is read-only.
- No second Playwright harness; the design checks fork into the existing `/guide` capture path.

### Agent face — v1.0 manifest

`loadDescent` · `layers` · `seek(cycle)` · `descend(layer, selector)` · `ascend()` · `stateAt(layer, cycle)` · `trace(instruction)` · `export(range)`.

Read and query tools register on load, no setting. There are no mutating operations in v1.0 and therefore no staging surface; if v1.3 adds a live build, that command stages before it lands. Cross-tab channel stays behind a developer setting. Every call is recorded with its door so History can tell a click from a call.

---

## 8. Risks, named

1. **The joins may not be total.** Optimisation, even at `-O0`, can leave instructions with no clean source line. C0 exists to find this in days, not months. If it holds only for a restricted program class, ship that class and document the boundary.
2. **The gate layer may be visually illegible** at any real design size. Mitigation is aggregation plus step-in, and the honest fallback is a smaller core.
3. **D1 tension is real** — the five-stage picture people expect versus the cores that permissively exist. Resolve it by labelling, never by drawing a pipeline the simulated core doesn't have.
4. **Scope gravity.** Every layer invites a better version of itself. The product is the descent; a layer is only as good as it needs to be to make the join legible.
