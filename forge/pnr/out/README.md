# Pinned place-and-route outputs

The physical design, as OpenLane 2.3.10 (Docker) produced it on `sky130A` from
`forge/pnr/src/` + `config.json`. **Pinned, not built:** place-and-route is not
byte-deterministic and takes ~40 min under Docker, so `forge` treats these as
inputs — the same posture as the vendored core. `./forge/pnr/run.sh` regenerates
them; a regeneration is a deliberate, recorded change.

- `ibex_top.nl.v` — the post-fill netlist. **This is the cells layer's netlist**:
  its instance names are the DEF's by construction, so every toggle lands on a
  coordinate. Includes the clock tree, hold/antenna fixes, fill and tap cells.
- `coords.json` — `(x, y, orientation, type)` per placed component, die outline,
  from the routed DEF (`forge/pnr/def_coords.py`).
- `metrics.json` — the flow's design/route/timing/antenna metrics.

Not pinned (size): the DEF (18 MB), GDS (41 MB), ODB. They live under
`forge/pnr/runs/<tag>/` on the machine that ran the flow.
