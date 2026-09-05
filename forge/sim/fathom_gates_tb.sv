`timescale 1ns/1ps
// fathom_gates_tb.sv — the same program, run on the synthesised netlist.
//
// Same memory, same clock, same reset timing as fathom_tb.sv. The netlist has no
// RVFI (that is simulation-only logic and is correctly absent from the gates), so
// equivalence with the RTL run is asserted on the bus log, cycle for cycle. The
// run length comes from the RTL run (+halt_cycle) so both logs cover the same
// cycles. The VCD this writes is join 3's source of truth.

module fathom_gates_tb;

  localparam int unsigned MemWords  = 32768;
  localparam bit [31:0]   MemBase   = 32'h8000_0000;
  localparam bit [31:0]   UartAddr  = 32'h1000_0000;
  localparam bit [31:0]   BootAddr  = 32'h8000_0000;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;                                  // T_clk = 10 ns, as RTL

  int unsigned cycle_q = 0;
  int unsigned t0_set  = 0;

  logic        instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;
  logic        data_req, data_gnt, data_rvalid, data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;
  integer      f_uart, f_bus, f_cycle;

  fathom_mem #(.MemWords(MemWords), .MemBase(MemBase), .UartAddr(UartAddr)) u_mem (
    .clk (clk), .rst_n (rst_n), .cycle (cycle_q),
    .instr_req (instr_req), .instr_gnt (instr_gnt), .instr_rvalid (instr_rvalid),
    .instr_addr (instr_addr), .instr_rdata (instr_rdata),
    .data_req (data_req), .data_gnt (data_gnt), .data_rvalid (data_rvalid),
    .data_we (data_we), .data_be (data_be), .data_addr (data_addr),
    .data_wdata (data_wdata), .data_rdata (data_rdata),
    .f_uart (f_uart), .f_bus (f_bus)
  );

`ifndef FATHOM_NETLIST
`define FATHOM_NETLIST ibex_top_gates
`endif
  `FATHOM_NETLIST u_gates (
    .clk_i (clk), .rst_ni (rst_n), .test_en_i (1'b0), .scan_rst_ni (1'b1),
    .ram_cfg_icache_tag_i (24'h0), .ram_cfg_icache_data_i (24'h0),
    .ram_cfg_icache_tag_o (), .ram_cfg_icache_data_o (),
    .cheriot_enable_i (4'b0000),
    .hart_id_i (32'h0), .boot_addr_i (BootAddr), .trvk_heap_base_addr_i (32'h0),

    .instr_req_o (instr_req), .instr_gnt_i (instr_gnt), .instr_rvalid_i (instr_rvalid),
    .instr_addr_o (instr_addr), .instr_rdata_i (instr_rdata),
    .instr_rdata_intg_i (7'h0), .instr_err_i (1'b0),

    .data_req_o (data_req), .data_gnt_i (data_gnt), .data_rvalid_i (data_rvalid),
    .data_we_o (data_we), .data_be_o (data_be), .data_addr_o (data_addr),
    .data_wdata_o (data_wdata), .data_wdata_intg_o (), .data_tag_o (),
    .data_rdata_i (data_rdata), .data_rdata_intg_i (7'h0), .data_tag_i (1'b0),
    .data_err_i (1'b0),

    .trvk_revbm_req_o (), .trvk_revbm_gnt_i (1'b0), .trvk_revbm_rvalid_i (1'b0),
    .trvk_revbm_addr_o (), .trvk_revbm_rdata_i (32'h0), .trvk_revbm_rdata_intg_i (7'h0),
    .trvk_revbm_err_i (1'b0),

    .irq_software_i (1'b0), .irq_timer_i (1'b0), .irq_external_i (1'b0),
    .irq_fast_i (15'h0), .irq_nm_i (1'b0),

    .scramble_key_valid_i (1'b0), .scramble_key_i (128'h0), .scramble_nonce_i (64'h0),
    .scramble_req_o (),

    .debug_req_i (1'b0), .crash_dump_o (), .double_fault_seen_o (),

    .fetch_enable_i (4'b0001), .mcounteren_writable_i (4'b0000),
    .alert_minor_o (), .alert_major_internal_o (), .alert_major_bus_o (),
    .core_sleep_o (), .lockstep_cmp_en_o (),
    .data_req_shadow_o (), .data_we_shadow_o (), .data_be_shadow_o (),
    .data_addr_shadow_o (), .data_wdata_shadow_o (), .data_wdata_intg_shadow_o (),
    .instr_req_shadow_o (), .instr_addr_shadow_o ()
  );

  string hexfile, vcdfile, outdir;
  int unsigned halt_cycle;

  initial begin
    if (!$value$plusargs("outdir=%s", outdir))        outdir = "build/gates";
    if (!$value$plusargs("hex=%s", hexfile))          hexfile = "build/uart_puts.hex";
    if (!$value$plusargs("vcd=%s", vcdfile))          vcdfile = "build/gates/gates.vcd";
    if (!$value$plusargs("halt_cycle=%d", halt_cycle)) halt_cycle = 100000;

    u_mem.load(hexfile);
    f_uart  = $fopen({outdir, "/uart.log"}, "w");
    f_bus   = $fopen({outdir, "/bus.log"},  "w");
    f_cycle = $fopen({outdir, "/cycle.log"}, "w");
    $fdisplay(f_bus, "cycle instr_req instr_addr data_req data_we data_be data_addr data_wdata");

    // Dump the core only: every net in the netlist, every cycle. The memory is
    // environment, not descent.
    $dumpfile(vcdfile);
    $dumpvars(0, u_gates);

    repeat (8) @(posedge clk);                          // identical to RTL
    @(negedge clk);
    rst_n = 1'b1;
  end

  // cycle 0 is the first rising edge after reset deassert (SPEC §1)
  always_ff @(posedge clk) begin
    if (rst_n) begin
      if (t0_set == 0) begin
        t0_set <= 1;
        $fdisplay(f_cycle, "# t0_ps %0d  t_clk_ps 10000", $time * 1000);
      end
      cycle_q <= cycle_q + 1;
    end
  end

  always_ff @(posedge clk) begin
    // > not >=: the bus logger for cycle halt_cycle runs on that edge, and
    // $finish on the same edge would race it. One more edge, then stop.
    if (rst_n && cycle_q > halt_cycle) begin
      $fdisplay(f_cycle, "halt_cycle %0d", halt_cycle);
      $fclose(f_uart); $fclose(f_bus); $fclose(f_cycle);
      $display("[fathom_gates_tb] halt: cycle=%0d", halt_cycle);
      $finish;
    end
  end

endmodule
