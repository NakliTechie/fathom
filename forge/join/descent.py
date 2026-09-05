#!/usr/bin/env python3
"""forge stage: the join pass. Every layer's output -> one descent.json (SPEC §2).

Inputs (all under build/):
  uart_puts.elf, .ll, line.txt          layers L0-L2 (source, IR, code)
  sim/retire.log, sim/cycle.log         L2'/L3/L4 (exec, arch deltas, pipe)
  gates/toggles.json                    L5 (gates)

Deterministic by construction: sorted keys, no whitespace, no timestamps, no
absolute paths. artifact_id is the sha256 of the canonical serialisation minus
itself. C1's byte-identity check is on this file.
"""
import hashlib
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"
LLVM = pathlib.Path("/opt/homebrew/opt/llvm/bin")
sys.path.insert(0, str(ROOT / "forge" / "join"))
from probe_joins import read_line_table, lookup  # noqa: E402

STALL_CAUSES = ("reset", "fetch", "load-use", "branch-flush", "mem-wait", "halt")
HELD_CAUSES = ("mem-wait", "branch", "wb-stall", "multi-cycle")


def die(verdict, where, remedy):
    print(f"{verdict}: {where}\n  remedy: {remedy}")
    sys.exit(2 if verdict == "TOOLCHAIN" else 1)


def need(p):
    if not p.exists():
        die("TOOLCHAIN", f"missing {p.relative_to(ROOT)}", "make all")
    return p


# ---- L2: code, from objdump ------------------------------------------------
def read_code(elf):
    out = subprocess.run([LLVM / "llvm-objdump", "-d", elf], capture_output=True,
                         text=True, check=True).stdout
    code, syms = [], {}
    func = None
    for ln in out.splitlines():
        m = re.match(r"^([0-9a-f]{8}) <(\w+)>:", ln)
        if m:
            func = m.group(2)
            syms[int(m.group(1), 16)] = func
            continue
        m = re.match(r"^([0-9a-f]{8}): ([0-9a-f]{8}|[0-9a-f]{4})\s+(\S+)\s*(.*)$", ln)
        if m:
            asm = (m.group(3) + " " + m.group(4)).strip()
            asm = re.sub(r"\s+", " ", asm)
            code.append({"pc": int(m.group(1), 16), "bytes": m.group(2),
                         "asm": asm, "func": func})
    return code, syms


# ---- L1: IR, from the .ll ---------------------------------------------------
def read_ir(ll):
    text = ll.read_text()
    dloc = {}
    for m in re.finditer(r"^!(\d+) = !DILocation\(line: (\d+), column: (\d+)", text, re.M):
        dloc[int(m.group(1))] = (int(m.group(2)), int(m.group(3)))
    ir = []
    func = None
    n = 0
    for ln in text.splitlines():
        m = re.match(r"^define .*@(\w+)\(", ln)
        if m:
            func, n = m.group(1), 0
            continue
        if ln.startswith("}"):
            func = None
            continue
        if func is None or not ln.strip() or ln.strip().startswith(("#dbg", ";")):
            continue
        if re.match(r"^\d+:|^\w[\w.]*:", ln.strip()):     # a label
            continue
        n += 1
        m = re.search(r"!dbg !(\d+)", ln)
        loc = dloc.get(int(m.group(1))) if m else None
        ir.append({"id": f"ir:{func}:{n}", "func": func,
                   "text": re.sub(r"\s+", " ", ln.strip()),
                   "line": loc[0] if loc else None,
                   "col": loc[1] if loc else None})
    return ir


# ---- decode enough of RV32I to name stalls -----------------------------------
def kind(insn):
    op = insn & 0x7F
    return {0x03: "load", 0x23: "store", 0x63: "branch", 0x6F: "jal", 0x67: "jalr"}.get(op, "alu")


def main():
    elf = need(BUILD / "uart_puts.elf")
    ll = need(BUILD / "uart_puts.ll")
    line_txt = need(BUILD / "line.txt")
    retire_log = need(BUILD / "sim" / "retire.log")
    cycle_log = need(BUILD / "sim" / "cycle.log")
    toggles_js = need(BUILD / "gates" / "toggles.json")

    # ---- L0 source ------------------------------------------------------------
    rows = read_line_table(line_txt)
    src_names = sorted({r[1] for r in rows})
    source = {}
    for name in src_names:
        p = ROOT / name
        if not p.exists():
            die("TOOLCHAIN", f"source {name} named by DWARF is not on disk", "make program")
        source[name] = p.read_text().splitlines()

    # ---- L2 code + L1 IR ------------------------------------------------------
    code, syms = read_code(elf)
    ir = read_ir(ll)
    ir_by_site = {}
    for e in ir:
        if e["line"] is not None:
            ir_by_site.setdefault((e["func"], e["line"], e["col"]), []).append(e["id"])
    ir_by_line = {}
    for e in ir:
        if e["line"] is not None:
            ir_by_line.setdefault((e["func"], e["line"]), []).append(e["id"])

    pc_start = next(pc for pc, f in syms.items() if f == "fathom_main")
    pc_end = max(c["pc"] for c in code)
    # the self-loop: last `j` to itself in fathom_main
    for c in code:
        if c["func"] == "fathom_main" and c["bytes"] == "0000006f":
            pc_end = c["pc"]

    no_ir = []
    for c in code:
        loc = lookup(rows, c["pc"])
        c["lines"] = [f"{loc[0]}:{loc[1]}:{loc[2]}"] if loc else []
        ids = []
        if loc and c["func"]:
            ids = ir_by_site.get((c["func"], loc[1], loc[2])) \
                or ir_by_line.get((c["func"], loc[1])) or []
        c["ir"] = ids
        if not ids and c["func"] not in ("_start",) and pc_start <= c["pc"] <= pc_end:
            # -O0 prologue/epilogue and stack spills carry the function's decl
            # line and column 0: real instructions with no IR ancestor.
            no_ir.append({"pc": c["pc"],
                          "reason": "prologue/epilogue or spill at -O0; no IR ancestor"})
    no_ir_pcs = {e["pc"] for e in no_ir}

    # ---- L2' exec + L3 arch deltas, from RVFI ---------------------------------
    exec_, frames = [], []
    for ln in retire_log.read_text().splitlines()[1:]:
        f = ln.split()
        cyc, order, pc, insn = int(f[0]), int(f[1]), int(f[2], 16), int(f[3], 16)
        rd, rdw = int(f[4]), int(f[5], 16)
        maddr, rmask, wmask, mrd, mwd = int(f[10], 16), int(f[11]), int(f[12]), int(f[13], 16), int(f[14], 16)
        xid = order - 1                                   # RVFI order is 1-based
        exec_.append({"xid": xid, "pc": pc, "insn": insn, "cycle_retire": cyc,
                      "cycle_first": None,
                      "region": "program" if pc_start <= pc <= pc_end else "stub"})
        delta = {"cycle": cyc, "xid": xid, "regs": {}, "mem": []}
        if rd != 0:
            delta["regs"][f"x{rd}"] = rdw
        if wmask:
            delta["mem"].append({"addr": maddr, "mask": wmask, "val": mwd})
        if delta["regs"] or delta["mem"]:
            frames.append(delta)

    # ---- L4 pipe: cycle -> anchor xid + stall cause ---------------------------
    cyc_rows = [l.split() for l in cycle_log.read_text().splitlines()
                if l and not l.startswith(("cycle", "#"))]
    N = len(cyc_rows)
    by_pc = {}
    for e in exec_:
        by_pc.setdefault(e["pc"], []).append(e)
    pipe = []
    prev_pc_if = None
    prev_ld_out = False
    for r in cyc_rows:
        cyc = int(r[0])
        pc_if, pc_id, pc_wb = int(r[1], 16), int(r[2], 16), int(r[3], 16)
        id_valid, id_new, id_ready = r[4] == "1", r[5] == "1", r[6] == "1"
        wb_done, ld_out = r[7] == "1", r[8] == "1"
        anchor, stall, held = None, None, None
        if id_valid:
            cands = [e for e in by_pc.get(pc_id, []) if e["cycle_retire"] >= cyc]
            if not cands and pc_id == pc_end:
                # The self-loop at pc_end is in ID/EX but its next retire lies past
                # the end of the trace. That is the `halt` cause (SPEC §1.1), not an
                # orphan: the trace ends because the program has nowhere left to go.
                pipe.append({"cycle": cyc, "anchor": None, "stall": "halt", "held": None,
                             "stages": {"IF": pc_if, "ID_EX": pc_id, "WB": pc_wb if wb_done else None}})
                prev_pc_if = pc_if
                prev_ld_out = ld_out
                continue
            if not cands:
                die("ORPHAN", f"cycle {cyc}: ID/EX holds pc 0x{pc_id:08x} with no later retire",
                    "check the halt condition; the trace may be cut before this retires")
            e = min(cands, key=lambda e: e["cycle_retire"])
            anchor = e["xid"]
            if e["cycle_first"] is None:
                e["cycle_first"] = cyc
            if not id_new:
                k = kind(e["insn"])
                # load-use: the stall asserts on the cycle the dependent
                # instruction arrives (id_ready=0, ld_out=1); the held row is the
                # cycle after, by which time ld_out has cleared. Read the previous
                # cycle's ld_out for the held row.
                held = ("wb-stall" if not id_ready else
                        "mem-wait" if k in ("load", "store") else
                        "branch" if k in ("branch", "jal", "jalr") else
                        "load-use" if (ld_out or prev_ld_out) else "multi-cycle")
        else:
            if pc_if == 0:
                stall = "reset"
            elif prev_pc_if is not None and pc_if not in (prev_pc_if, prev_pc_if + 4):
                stall = "branch-flush"
            else:
                stall = "fetch"
        pipe.append({"cycle": cyc, "anchor": anchor, "stall": stall, "held": held,
                     "stages": {"IF": pc_if, "ID_EX": pc_id if id_valid else None,
                                "WB": pc_wb if wb_done else None}})
        prev_pc_if = pc_if
        prev_ld_out = ld_out
    for e in exec_:
        if e["cycle_first"] is None:
            e["cycle_first"] = e["cycle_retire"]

    # ---- L5 gates -------------------------------------------------------------
    tg = json.loads(toggles_js.read_text())
    if tg["cycles"] != N:
        die("AMBIGUOUS", f"gate run {tg['cycles']} cycles vs RTL {N}", "make gates")

    core = {"name": "ibex", "upstream": "lowRISC/ibex", "pin": "34b0705760ef3dfa00e99637432473d2be8f22f3",
            "licence": "Apache-2.0", "shape": "three-stage",
            "stages": ["IF", "ID_EX", "WB"], "anchor_stage": "ID_EX",
            "t_clk_ps": tg["t_clk_ps"], "t0_ps": tg["t0_ps"],
            "config": {"BaseIsa": "RV32I", "RV32M": "None", "RV32B": "None",
                       "RV32ZC": "Zca", "WritebackStage": 1, "RegFile": "FF"}}
    program = {"name": "uart_puts", "source_files": src_names,
               "pc_start": pc_start, "pc_end": pc_end, "no_ir": no_ir}

    art = {"schema": "fathom.descent/1", "artifact_id": "",
           "program": program, "core": core, "cycles": N,
           "source": source, "ir": ir, "code": code, "exec": exec_,
           "arch": {"encoding": "delta", "regs_at_0": {f"x{i}": 0 for i in range(32)},
                    "frames": frames},
           "pipe": pipe,
           "gates": {"nets": tg["nets"], "toggles": tg["toggles"]}}

    canon = json.dumps(art, sort_keys=True, separators=(",", ":"))
    art["artifact_id"] = "sha256:" + hashlib.sha256(canon.encode()).hexdigest()
    outdir = ROOT / "artifacts" / "uart_puts"
    outdir.mkdir(parents=True, exist_ok=True)
    out = outdir / "descent.json"
    tmp = out.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(art, sort_keys=True, separators=(",", ":")))
    tmp.replace(out)                                     # atomic (SPEC §0.5)

    print(f"artifact     : {out.relative_to(ROOT)}  {out.stat().st_size/1e6:.2f} MB")
    print(f"artifact_id  : {art['artifact_id'][:23]}...")
    print(f"cycles       : {N}   exec: {len(exec_)}   code: {len(code)}   ir: {len(ir)}")
    print(f"no_ir        : {len(no_ir)} pcs")
    print(f"stalls       : { {p['stall'] for p in pipe if p['stall']} }")
    print(f"held causes  : { {p['held'] for p in pipe if p['held']} }")
    print(f"arch frames  : {len(frames)}   gate pairs: {len(tg['toggles'])}")
    print("OK")


if __name__ == "__main__":
    main()
