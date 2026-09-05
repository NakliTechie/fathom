#!/usr/bin/env python3
"""forge stage: probe the descent's joins for totality.

C0's whole point (FATHOM.md §8.1): the joins may not be total. This probes them
against a real trace and reports orphans by class. It is the ancestor of
`forge verify` — same verdict vocabulary (SPEC §0.3), narrower scope.

Exit 0 = OK. Exit 1 = ORPHAN. Exit 2 = TOOLCHAIN (fail closed, SPEC §0.8).
"""
import collections
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BUILD = ROOT / "build"


def die(verdict, where, remedy):
    print(f"{verdict}: {where}\n  remedy: {remedy}")
    sys.exit(2 if verdict == "TOOLCHAIN" else 1)


def read_line_table(path):
    """DWARF rows as (address, source_name, line, column, is_end_sequence).

    The file index alone is NOT a key. Every compile unit numbers its own file
    table from 0, so `crt0.S` and `uart_puts.c` are both file[0] and their line
    numbers collide. The key is (compile unit, file index) resolved to a name.
    """
    rows = []
    cu = None                      # current debug_line[<offset>] section
    names = {}                     # (cu, index) -> source path
    pending_idx = None
    for ln in path.read_text().splitlines():
        m = re.match(r"^debug_line\[0x([0-9a-f]+)\]", ln)
        if m:
            cu = int(m.group(1), 16)
            continue
        m = re.match(r"^file_names\[\s*(\d+)\]:", ln)
        if m:
            pending_idx = int(m.group(1))
            continue
        m = re.match(r'^\s+name: "(.*)"', ln)
        if m and pending_idx is not None:
            names[(cu, pending_idx)] = m.group(1)
            pending_idx = None
            continue
        m = re.match(r"^0x([0-9a-f]{16})\s+(\d+)\s+(\d+)\s+(\d+)\s", ln)
        if m:
            rows.append((int(m.group(1), 16), (cu, int(m.group(4))),
                         int(m.group(2)), int(m.group(3)),
                         "end_sequence" in ln))
    rows.sort()
    return [(a, names.get(k, f"<unknown {k}>"), l, c, e)
            for a, k, l, c, e in rows]


def lookup(rows, pc):
    """The last row at or below pc, unless that row closes a sequence."""
    lo, hi, best = 0, len(rows) - 1, None
    while lo <= hi:
        mid = (lo + hi) // 2
        if rows[mid][0] <= pc:
            best, lo = rows[mid], mid + 1
        else:
            hi = mid - 1
    if best is None or best[4]:
        return None
    return (best[1], best[2], best[3])          # file, line, column


def main():
    prog = sys.argv[1] if len(sys.argv) > 1 else "uart_puts"
    P = BUILD / prog
    line_txt = P / "line.txt"
    retire = P / "sim" / "retire.log"
    cycles = P / "sim" / "cycle.log"
    for p in (line_txt, retire, cycles):
        if not p.exists():
            die("TOOLCHAIN", f"missing {p.relative_to(ROOT)}",
                f"run: make sim PROGRAM={prog}")

    rows = read_line_table(line_txt)
    retires = []
    for ln in retire.read_text().splitlines()[1:]:
        f = ln.split()
        retires.append({"cycle": int(f[0]), "xid": int(f[1]), "pc": int(f[2], 16)})
    cyc = [l.split() for l in cycles.read_text().splitlines()
           if l and not l.startswith(("cycle", "#"))]

    pcs = sorted({r["pc"] for r in retires})
    orphans = [pc for pc in pcs if lookup(rows, pc) is None]

    print(f"line-table rows : {len(rows)}")
    print(f"retires         : {len(retires)}")
    print(f"distinct pcs    : {len(pcs)}")
    print()
    print("JOIN 1  pc -> file:line:col")
    print(f"  resolved : {len(pcs) - len(orphans)}/{len(pcs)}")
    print(f"  orphans  : {len(orphans)}")

    per_site = collections.Counter()
    for r in retires:
        v = lookup(rows, r["pc"])
        if v:
            per_site[(v[0], v[1])] += 1
    print("  retires per (source, line):")
    for (src, line), n in sorted(per_site.items()):
        print(f"    {src}:{line:<4} {n:>3}")

    n = len(cyc)
    occupied = sum(1 for c in cyc if c[4] == "1")
    print()
    print("JOIN 2  cycle -> anchor (ID/EX)")
    print(f"  cycles         : {n}")
    print(f"  ID/EX occupied : {occupied}")
    print(f"  bubbles        : {n - occupied} ({100 * (n - occupied) / n:.0f}%)")
    print(f"  retires        : {len(retires)}  IPC = {len(retires) / n:.2f}")
    print()
    tj = P / "gates" / "toggles.json"
    if tj.exists():
        import json
        d = json.loads(tj.read_text())
        outside = [t for t in d["toggles"] if not (0 <= t[0] < d["cycles"])]
        print("JOIN 3  cycle -> gate toggle")
        print(f"  cycles   : {d['cycles']}   nets: {len(d['nets'])}")
        print(f"  events   : {len(d['toggles'])} (cycle,net) pairs")
        print(f"  orphans  : {len(outside)}")
        if d["cycles"] != n:
            die("AMBIGUOUS", f"gate run has {d['cycles']} cycles, RTL run has {n}",
                "make gates   (the gate run takes its halt cycle from the RTL run)")
        if outside:
            die("ORPHAN", f"{len(outside)} toggle events outside the cycle range",
                "python3 forge/join/vcd_toggles.py  (check t0 / timescale)")
    else:
        print("JOIN 3  cycle -> gate toggle: NOT PROBED -- run `make toggles`")

    if orphans:
        print()
        for pc in orphans:
            print(f"  ORPHAN pc=0x{pc:08x}")
        die("ORPHAN", f"{len(orphans)} executed pc(s) resolve to no source line",
            "add them to program.json:no_ir with a reason, or widen the traced region")
    print("OK")


if __name__ == "__main__":
    main()
