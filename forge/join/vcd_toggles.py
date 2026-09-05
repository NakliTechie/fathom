#!/usr/bin/env python3
"""forge stage: gate-level VCD -> per-cycle toggle events (join 3, SPEC §1.2).

    cycle = floor((t - t0) / T_clk)

t0 and T_clk come from the gate run's cycle.log, written by the harness at the
first rising edge after reset release -- the same definition the RTL run uses,
so both sides of join 3 share a clock by construction.

Conventions fixed here (SPEC §1.2):
- a toggle exactly at an edge belongs to the cycle that edge opens;
- multiple toggles of one net inside one cycle collapse to {net, count};
- events before t0 (reset) are dropped and counted, never silently ignored.

Writes build/gates/toggles.json:
  {"t0_ps", "t_clk_ps", "cycles", "nets": [names], "dropped_pre_t0",
   "toggles": [[cycle, net_index, count], ...]}
"""
import collections
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


_cache = {}
def remap_names(active_names):
    k = id(active_names)
    if k not in _cache:
        _cache[k] = set(active_names)
    return _cache[k]


def parse_clock(cycle_log):
    t0 = tclk = halt = None
    for ln in cycle_log.read_text().splitlines():
        m = re.match(r"# t0_ps (\d+)\s+t_clk_ps (\d+)", ln)
        if m:
            t0, tclk = int(m.group(1)), int(m.group(2))
        m = re.match(r"halt_cycle (\d+)", ln)
        if m:
            halt = int(m.group(1))
    if t0 is None or tclk is None or halt is None:
        print("TOOLCHAIN: gate cycle.log lacks t0/t_clk/halt\n  remedy: make gates")
        sys.exit(2)
    return t0, tclk, halt


def main():
    prog = sys.argv[1] if len(sys.argv) > 1 else "uart_puts"
    net = sys.argv[2] if len(sys.argv) > 2 else "gates"      # gates | sky130
    P = ROOT / "build" / prog
    vcd = P / net / "gates.vcd"
    clog = P / net / "cycle.log"
    for p in (vcd, clog):
        if not p.exists():
            print(f"TOOLCHAIN: missing {p.relative_to(ROOT)}\n  remedy: make {net} PROGRAM={prog}")
            sys.exit(2)
    t0, tclk, halt = parse_clock(clog)
    ncycles = halt + 1

    # VCD timescale -> ps
    text = vcd.read_text()
    m = re.search(r"\$timescale\s+(\d+)\s*(s|ms|us|ns|ps|fs)\s+\$end", text)
    unit = {"s": 1e12, "ms": 1e9, "us": 1e6, "ns": 1e3, "ps": 1, "fs": 1e-3}[m.group(2)]
    scale = int(m.group(1)) * unit                 # ps per VCD tick

    # symbol table: id -> (scope path, name, width); aliases: id -> other names
    ids, scope, aliases = {}, [], {}
    header, body = text.split("$enddefinitions", 1)
    for ln in header.splitlines():
        t = ln.split()
        if not t:
            continue
        if t[0] == "$scope":
            scope.append(t[2])
        elif t[0] == "$upscope":
            scope.pop()
        elif t[0] == "$var":
            width, vid, name = int(t[2]), t[3], t[4]
            full = ".".join(scope[1:] + [name]) if len(scope) > 1 else name
            if vid in ids:
                aliases.setdefault(vid, []).append(full)   # same value, another name
            else:
                ids[vid] = (full, width)

    names = sorted({v[0] for v in ids.values()})
    index = {n: i for i, n in enumerate(names)}

    # walk value changes
    t = 0
    counts = collections.Counter()               # (cycle, net_idx) -> toggles
    dropped_pre = dropped_post = 0
    t_last = 0
    first_value_seen = set()
    for ln in body.splitlines():
        if not ln:
            continue
        c = ln[0]
        if c == "#":
            t = int(ln[1:]) * scale
            t_last = max(t_last, t)
            continue
        if c in "01xzXZ":
            vid = ln[1:]
        elif c in "bBrR":
            _, vid = ln.split()
        else:
            continue
        if vid not in ids:
            continue
        if vid not in first_value_seen:          # the $dumpvars initial value, not a toggle
            first_value_seen.add(vid)
            continue
        if t < t0:
            dropped_pre += 1
            continue
        cyc = int((t - t0) // tclk)
        if cyc >= ncycles:
            dropped_post += 1                     # counted, never silent (SPEC §0.8)
            continue
        counts[(cyc, index[ids[vid][0]])] += 1

    # Only nets that toggle at least once are in the artifact's table (the rest
    # are mostly fill-cell power pins). Re-index densely; keep the static count.
    active = sorted({n for (_, n) in counts})
    remap = {old: new for new, old in enumerate(active)}
    active_names = [names[i] for i in active]
    toggles = sorted([c, remap[n], k] for (c, n), k in counts.items())
    per_cycle = collections.Counter(c for c, _, _ in toggles)
    canon = {}                                     # alias name -> canonical (active) name
    for vid, others in aliases.items():
        main = ids[vid][0]
        if main in remap_names(active_names):
            for o in others:
                canon[o] = main
    out = {
        "t0_ps": t0, "t_clk_ps": tclk, "cycles": ncycles,
        "nets": active_names, "static_nets": len(names) - len(active_names),
        "aliases": canon,
        "dropped_pre_t0": dropped_pre, "dropped_post_end": dropped_post,
        "toggles": toggles,
    }
    (P / net / "toggles.json").write_text(json.dumps(out, separators=(",", ":")))

    print(f"vcd timescale   : {m.group(1)} {m.group(2)}")
    print(f"t0 / t_clk      : {t0} ps / {tclk} ps")
    print(f"cycles          : {ncycles}")
    print(f"nets            : {len(active_names)} active of {len(names)} ({len(canon)} aliases kept)")
    print(f"toggle events   : {sum(counts.values())} raw, {len(toggles)} (cycle,net) pairs")
    print(f"pre-t0 dropped  : {dropped_pre}   (reset activity, expected)")
    print(f"post-end dropped: {dropped_post}   (the extra edge after halt, expected small)")
    # A timescale mismatch between harness and VCD makes every event land past the
    # end. That is a TOOLCHAIN failure, not a quiet netlist.
    if t_last < t0 or dropped_post > sum(counts.values()):
        print(f"TOOLCHAIN: VCD time range [0,{t_last}] ps vs t0={t0} ps -- timescale mismatch?")
        print("  remedy: check `timescale in forge/sim/*.sv and $timescale in the VCD")
        sys.exit(2)
    busiest = per_cycle.most_common(3)
    print(f"busiest cycles  : {busiest}")
    quiet = [c for c in range(ncycles) if per_cycle[c] == 0]
    print(f"silent cycles   : {len(quiet)}")
    orphan = [c for c, _, _ in toggles if c < 0 or c >= ncycles]
    print("JOIN 3  cycle -> gate toggle")
    print(f"  events outside [0,{ncycles}): {len(orphan)}")
    print("OK" if not orphan else "ORPHAN")
    sys.exit(1 if orphan else 0)


if __name__ == "__main__":
    main()
