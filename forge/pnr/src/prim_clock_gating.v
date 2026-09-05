// forge/pnr: the clock gate as the PDK's integrated clock-gating cell.
//
// prim_generic_clock_gating is a latch + AND, which is what a generic gate
// netlist can express; a Sky130 tape-out uses sky130_fd_sc_hd__dlclkp (a
// glitch-free ICG). Same function, physical cell. This file replaces the
// generated prim_clock_gating.v for the place-and-route leg only; the generic
// and cell netlists (forge/synth) keep the latch form so the gate layer shows it.
module prim_generic_clock_gating (
  input  clk_i,
  input  en_i,
  input  test_en_i,
  output clk_o
);
  sky130_fd_sc_hd__dlclkp_1 u_icg (
    .CLK  (clk_i),
    .GATE (en_i | test_en_i),
    .GCLK (clk_o)
  );
endmodule
