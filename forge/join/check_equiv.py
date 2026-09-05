#!/usr/bin/env python3
"""forge stage: RTL-vs-gates equivalence on the bus, cycle for cycle.

Both harnesses log the same bus columns every cycle. Any divergence is a
synthesis or harness bug and fails the build. This is C3's "asserted equal by a
test, not by eye" (FATHOM.md §7), landed in C0.

Exit 0 = OK. Exit 1 = a mismatch. Exit 2 = TOOLCHAIN (a log is missing).
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


def rows(path):
    return [l.split() for l in path.read_text().splitlines()[1:] if l.strip()]


def main():
    prog = sys.argv[1] if len(sys.argv) > 1 else "uart_puts"
    P = ROOT / "build" / prog
    rtl = P / "sim/bus.log"
    gates = P / "gates/bus.log"
    for p in (rtl, gates):
        if not p.exists():
            print(f"TOOLCHAIN: missing {p.relative_to(ROOT)}\n  remedy: make gates PROGRAM={prog}")
            sys.exit(2)
    a, b = rows(rtl), rows(gates)
    # The RTL run is the reference: it halts on the program's own self-loop. The
    # gate run is told that halt cycle and runs one edge past it so the last row
    # is logged, so it must cover the RTL rows, not equal them.
    if len(b) < len(a):
        print(f"gate run too short: {len(b)} rows < rtl {len(a)}\nMISMATCH")
        sys.exit(1)
    n = len(a)
    cols = ["cycle", "instr_req", "instr_addr", "data_req", "data_we", "data_be",
            "data_addr", "data_wdata"]
    # The bus protocol defines address/data only while the request is asserted.
    # Outside a request the RTL sim reads 0 (Verilator zero-initialises) and the
    # gate sim reads x (Icarus does not); neither is a core difference. So:
    # compare cycle and both req lines always, instr_addr under instr_req, and
    # the data columns under data_req. This masking is the only leniency here.
    def view(r):
        cycle, ireq, iaddr, dreq, dwe, dbe, daddr, dwdata = r
        out = [cycle, ireq, dreq]
        out.append(iaddr if ireq == "1" else "-")
        out += [dwe, dbe, daddr, dwdata] if dreq == "1" else ["-"] * 4
        return out
    bad = []
    for i in range(n):
        if view(a[i]) != view(b[i]):
            bad.append((i, a[i], b[i]))
    print(f"rtl cycles   : {len(a)}")
    print(f"gate cycles  : {len(b)}")
    print(f"compared     : {n}")
    print(f"mismatches   : {len(bad)}   (instr_addr under instr_req; data columns under data_req)")
    print(f"data requests: rtl {sum(1 for r in a if r[3] == '1')}  gates {sum(1 for r in b[:n] if r[3] == '1')}")
    print(f"instr fetches: rtl {sum(1 for r in a if r[1] == '1')}  gates {sum(1 for r in b[:n] if r[1] == '1')}")
    for i, x, y in bad[:20]:
        diff = [c for c, p, q in zip(cols, x, y) if p != q]
        print(f"  cycle {x[0]}: differs in {', '.join(diff)}\n    rtl   {' '.join(x)}\n    gates {' '.join(y)}")
    if bad:
        print("MISMATCH")
        sys.exit(1)
    # the UART bytes too — the bottom of the descent must land on the same cycles
    ua = (P / "sim/uart.log").read_text().split()
    ub = (P / "gates/uart.log").read_text().split()
    print(f"uart         : rtl {ua}  gates {ub}")
    if ua != ub:
        print("MISMATCH (uart)")
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
