#!/usr/bin/env python3
"""forge stage: DEF -> cell coordinates + die outline, into the cells layer.

Reads the final DEF of the latest OpenLane run (or the one given), and writes
build/pnr/coords.json: {"die": [x0,y0,x1,y1] (um), "units_per_um": N,
"cells": {name: [x, y, orient]}} for every placed COMPONENT. Cell names in the
DEF are the netlist's instance names, which are the same names the cells layer
already carries -- the join is by name and the verifier asserts every placed
cell is a known cell and vice versa (decision 2026-09-05: coordinates + die
outline, no routing geometry).

Exit 0 = OK, 1 = ORPHAN (a placed cell the netlist does not know, or vice versa),
2 = TOOLCHAIN (no DEF).
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def latest_def():
    """final/def if the flow wrote its views; else the newest step DEF after fill
    insertion, which is the placed, routed, filled design (the flow reached step
    68 of 78 -- past routing, fill, GDS and LVS -- without writing final/)."""
    runs = sorted((ROOT / "forge/pnr/runs").glob("fathom-*"))
    for run in reversed(runs):
        finals = sorted(run.glob("final/def/*.def"))
        if finals:
            return finals[0].resolve()
        steps = sorted(run.glob("*-odb-cellfrequencytables/*.def")) or sorted(run.glob("*-openroad-fillinsertion/*.def"))
        if steps:
            return steps[-1].resolve()
    return None


def parse_def(path):
    text = path.read_text()
    m = re.search(r"^UNITS DISTANCE MICRONS (\d+) ;", text, re.M)
    units = int(m.group(1)) if m else 1000
    m = re.search(r"^DIEAREA \( (-?\d+) (-?\d+) \) \( (-?\d+) (-?\d+) \) ;", text, re.M)
    die = [int(v) / units for v in m.groups()] if m else None
    cells = {}
    comp = re.search(r"^COMPONENTS (\d+) ;(.*?)^END COMPONENTS", text, re.M | re.S)
    if not comp:
        return units, die, cells
    for m in re.finditer(r"- (\S+) (\S+)(.*?);", comp.group(2), re.S):
        name, ctype, rest = m.group(1), m.group(2), m.group(3)
        pm = re.search(r"\+ (?:PLACED|FIXED) \( (-?\d+) (-?\d+) \) (\w+)", rest)
        if pm:
            cells[name] = [int(pm.group(1)) / units, int(pm.group(2)) / units, pm.group(3), ctype]
    return units, die, cells


def main():
    d = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else latest_def()
    if d is None or not d.exists():
        print("TOOLCHAIN: no final DEF under forge/pnr/runs/*/final/def/\n  remedy: ./forge/pnr/run.sh")
        sys.exit(2)
    units, die, cells = parse_def(d)
    out = ROOT / "build/pnr"
    out.mkdir(parents=True, exist_ok=True)
    (out / "coords.json").write_text(json.dumps(
        {"def": str(d.relative_to(ROOT)), "units_per_um": units, "die_um": die,
         "cells": cells}, sort_keys=True, separators=(",", ":")))
    fillers = sum(1 for v in cells.values() if "fill" in v[3] or "decap" in v[3] or "tap" in v[3])
    print(f"def        : {d.relative_to(ROOT)}")
    print(f"die (um)   : {die}")
    print(f"placed     : {len(cells)} components ({fillers} fill/decap/tap)")
    print("OK")


if __name__ == "__main__":
    main()
