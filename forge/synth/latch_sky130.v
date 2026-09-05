// techmap: Yosys's generic negative-enable latch -> the sky130_fd_sc_hd latch.
// dfflibmap covers flops only; the clock gate's en_latch is the one latch in
// the design (prim_generic_clock_gating) and would otherwise ship unmapped.
module \$_DLATCH_N_ (input E, input D, output Q);
  sky130_fd_sc_hd__dlxtn_1 _TECHMAP_REPLACE_ (.GATE_N(E), .D(D), .Q(Q));
endmodule
