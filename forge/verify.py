#!/usr/bin/env python3
"""forge verify -- the C0 checkpoint. SPEC §1.3, all eight assertions.

Runs in a fresh context against the committed artifact only. It reads no build/
output: what it cannot prove from the artifact and the source tree, it fails.

Verdicts (SPEC §0.3): OK | ORPHAN | AMBIGUOUS | SCHEMA | TOOLCHAIN.
Green is one line. Failures print at most 20 exemplars per class and the total.
"""
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
STALLS = {"reset", "fetch", "load-use", "branch-flush", "mem-wait", "halt"}
HELD = {"mem-wait", "branch", "wb-stall", "load-use", "multi-cycle"}
MAX_SHOW = 20


class Verify:
    def __init__(self, path):
        self.path = path
        self.failures = {}          # verdict -> [messages]

    def fail(self, verdict, msg):
        self.failures.setdefault(verdict, []).append(msg)

    # ---- schema: shape, types, closed vocabularies ---------------------------
    def schema(self, a):
        need = {"schema", "artifact_id", "program", "core", "cycles", "source", "ir",
                "code", "exec", "arch", "pipe", "gates"}
        missing = need - set(a)
        if missing:
            self.fail("SCHEMA", f"top-level keys missing: {sorted(missing)}")
            return False
        if a["schema"] != "fathom.descent/1":
            self.fail("SCHEMA", f"schema is {a['schema']!r}")
        if not isinstance(a["cycles"], int) or a["cycles"] <= 0:
            self.fail("SCHEMA", "cycles must be a positive int")
        for k in ("pc_start", "pc_end", "source_files", "no_ir", "name"):
            if k not in a["program"]:
                self.fail("SCHEMA", f"program.{k} missing")
        for k in ("anchor_stage", "stages", "t_clk_ps", "t0_ps", "shape", "name"):
            if k not in a["core"]:
                self.fail("SCHEMA", f"core.{k} missing")
        if a["core"].get("anchor_stage") not in a["core"].get("stages", []):
            self.fail("SCHEMA", "core.anchor_stage is not one of core.stages")
        for p in a["pipe"]:
            if p["stall"] is not None and p["stall"] not in STALLS:
                self.fail("SCHEMA", f"cycle {p['cycle']}: stall {p['stall']!r} not in closed set")
            if p["held"] is not None and p["held"] not in HELD:
                self.fail("SCHEMA", f"cycle {p['cycle']}: held {p['held']!r} not in closed set")
            if p["anchor"] is None and p["stall"] is None:
                self.fail("SCHEMA", f"cycle {p['cycle']}: anchor null without a stall cause")
            if p["anchor"] is not None and p["stall"] is not None:
                self.fail("SCHEMA", f"cycle {p['cycle']}: both anchor and stall set")
        return "SCHEMA" not in self.failures

    # ---- assertion 8: canonical round-trip and content address ----------------
    def roundtrip(self, a, raw):
        canon = json.dumps(a, sort_keys=True, separators=(",", ":"))
        if canon != raw:
            self.fail("SCHEMA", "artifact is not in canonical serialisation (sorted keys, no whitespace)")
        import hashlib
        b = dict(a); b["artifact_id"] = ""
        h = "sha256:" + hashlib.sha256(json.dumps(b, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
        if h != a["artifact_id"]:
            self.fail("SCHEMA", f"artifact_id does not match content: {a['artifact_id'][:23]} vs {h[:23]}")

    # ---- the joins ------------------------------------------------------------
    def joins(self, a):
        N = a["cycles"]
        xids = {e["xid"] for e in a["exec"]}
        pcs = {c["pc"]: c for c in a["code"]}
        p0, p1 = a["program"]["pc_start"], a["program"]["pc_end"]
        no_ir = {e["pc"] for e in a["program"]["no_ir"]}

        # 1. every toggle -> exactly one cycle in [0, N)
        nnets = len(a["gates"]["nets"])
        for c, n, k in a["gates"]["toggles"]:
            if not (0 <= c < N):
                self.fail("ORPHAN", f"toggle at cycle {c} outside [0,{N})")
            if not (0 <= n < nnets):
                self.fail("ORPHAN", f"toggle on net index {n} outside the net table")
        # 2. every cycle -> one anchor xid or null+cause; cycles contiguous
        seen = [p["cycle"] for p in a["pipe"]]
        if seen != list(range(N)):
            self.fail("ORPHAN", f"pipe cycles are not exactly 0..{N-1} (got {len(seen)} rows)")
        for p in a["pipe"]:
            if p["anchor"] is not None and p["anchor"] not in xids:
                self.fail("ORPHAN", f"cycle {p['cycle']}: anchor xid {p['anchor']} has no exec row")
        # 3. every xid -> exactly one pc, present in code
        by_xid = {}
        for e in a["exec"]:
            by_xid.setdefault(e["xid"], []).append(e["pc"])
        for x, ps in by_xid.items():
            if len(ps) != 1:
                self.fail("AMBIGUOUS", f"xid {x} has {len(ps)} exec rows")
            if ps[0] not in pcs:
                self.fail("ORPHAN", f"xid {x}: pc 0x{ps[0]:08x} not in code")
        # 4. every pc in the traced region -> >= 1 source line
        for pc, c in pcs.items():
            if p0 <= pc <= p1 and not c["lines"]:
                self.fail("ORPHAN", f"pc 0x{pc:08x} ({c['asm']}) has no source line")
        # 5. every pc in region -> >= 1 IR id, or is in no_ir with a reason
        ir_ids = {e["id"] for e in a["ir"]}
        for pc, c in pcs.items():
            if p0 <= pc <= p1:
                if not c["ir"] and pc not in no_ir:
                    self.fail("ORPHAN", f"pc 0x{pc:08x} ({c['asm']}) has no IR and is not in no_ir")
                for i in c["ir"]:
                    if i not in ir_ids:
                        self.fail("ORPHAN", f"pc 0x{pc:08x} names IR id {i} that does not exist")
        for e in a["program"]["no_ir"]:
            if not e.get("reason"):
                self.fail("SCHEMA", f"no_ir entry 0x{e['pc']:08x} has no reason")
            if pcs.get(e["pc"], {}).get("ir"):
                self.fail("AMBIGUOUS", f"pc 0x{e['pc']:08x} is in no_ir but has IR ids")
        # 6. no xid referenced that no cycle anchors (every retired instruction was in ID/EX)
        anchored = {p["anchor"] for p in a["pipe"] if p["anchor"] is not None}
        for x in xids - anchored:
            self.fail("ORPHAN", f"xid {x} retired but no cycle anchors it")
        # 7. every source line claimed exists in the file; distinct sources never share a key
        for pc, c in pcs.items():
            for ref in c["lines"]:
                src, line, col = ref.rsplit(":", 2)
                lines = a["source"].get(src)
                if lines is None:
                    self.fail("ORPHAN", f"pc 0x{pc:08x} names source {src!r} not in artifact")
                elif not (1 <= int(line) <= len(lines)):
                    self.fail("ORPHAN", f"pc 0x{pc:08x} names {src}:{line} past end of file ({len(lines)} lines)")
        for src in a["program"]["source_files"]:
            if not (ROOT / src).exists():
                self.fail("TOOLCHAIN", f"source file {src} not on disk")
            elif (ROOT / src).read_text().splitlines() != a["source"][src]:
                self.fail("AMBIGUOUS", f"source {src} in artifact differs from the file on disk")
        # arch: every delta cycle within range and names an xid
        for f in a["arch"]["frames"]:
            if not (0 <= f["cycle"] < N):
                self.fail("ORPHAN", f"arch frame at cycle {f['cycle']} outside range")
            if f["xid"] not in xids:
                self.fail("ORPHAN", f"arch frame names xid {f['xid']} with no exec row")

    def run(self):
        if not self.path.exists():
            print(f"TOOLCHAIN: {self.path.relative_to(ROOT)} missing\n  remedy: make descent")
            return 2
        raw = self.path.read_text()
        try:
            a = json.loads(raw)
        except json.JSONDecodeError as e:
            print(f"SCHEMA: not JSON: {e}\n  remedy: make descent")
            return 1
        if self.schema(a):
            self.roundtrip(a, raw)
            self.joins(a)
        if not self.failures:
            n = a["cycles"]
            print(f"OK  {self.path.relative_to(ROOT)}  {a['artifact_id'][:23]}  "
                  f"{n} cycles  {len(a['exec'])} exec  {len(a['code'])} code  "
                  f"{len(a['gates']['toggles'])} toggles  8/8 assertions")
            return 0
        for verdict in ("TOOLCHAIN", "SCHEMA", "AMBIGUOUS", "ORPHAN"):
            msgs = self.failures.get(verdict, [])
            if msgs:
                print(f"{verdict}: {len(msgs)}")
                for m in msgs[:MAX_SHOW]:
                    print(f"  {m}")
                if len(msgs) > MAX_SHOW:
                    print(f"  ... {len(msgs) - MAX_SHOW} more")
        print("remedy: make descent, then read the exemplars above")
        return 2 if "TOOLCHAIN" in self.failures else 1


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "artifacts/uart_puts/descent.json"
    sys.exit(Verify(ROOT / arg).run())
