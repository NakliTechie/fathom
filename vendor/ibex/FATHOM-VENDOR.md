# Vendored: Ibex

Upstream: https://github.com/lowRISC/ibex
Pinned commit: 34b0705760ef3dfa00e99637432473d2be8f22f3 (2026-08-31)
Licence: Apache-2.0 — see LICENSE.

**Unmodified.** Fathom edits no Ibex source; configuration is by parameter only,
applied at synthesis time in `forge/synth/synth.ys`.

**Pruned, not modified.** Only the subtrees `forge` reads are kept:
`rtl/`, `syn/`, and under `vendor/lowrisc_ip/` the `prim`, `prim_generic`
and `dv_utils` RTL. Dropped: the upstream `.git`, `dv/`, `examples/`, `doc/`,
`util/`, and the vendored riscv-dv / riscv-isa-sim / riscv-arch-tests / CoreMark
trees (57 MB -> the tree you see). Nothing kept was edited; re-clone at the pinned
commit to verify.
