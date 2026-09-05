`timescale 1ns/1ps
// fathom_tb.sv — the C0 simulation harness.
//
// Ibex + one flat memory + a memory-mapped UART, run to the traced region's end.
// Emits two streams that forge joins (SPEC §1.2):
//   retire.log — one line per retired instruction, from RVFI (join 2, upper half)
//   cycle.log  — one line per cycle: stage occupancy and stall cause (join 2, lower half)
// A VCD of the same run is written for eyeballing; the gate leg produces its own.

module fathom_tb;

  // ---- parameters kept in step with forge/synth/synth.ys -------------------
  localparam int unsigned MemWords  = 32768;            // 128 KiB at 0x8000_0000
  localparam bit [31:0]   MemBase   = 32'h8000_0000;
  localparam bit [31:0]   UartAddr  = 32'h1000_0000;
  localparam bit [31:0]   BootAddr  = 32'h8000_0000;
  localparam int unsigned MaxCycles = 100000;

  // ---- clock and reset ----------------------------------------------------
  logic clk = 1'b0;
  logic rst_n = 1'b0;
  always #5 clk = ~clk;                                  // 100 MHz, T_clk = 10 ns

  int unsigned cycle_q = 0;                              // the spine's cycle index
  int unsigned t0_set  = 0;

  // ---- memory (shared with the gate-level harness) -------------------------
  logic        instr_req, instr_gnt, instr_rvalid;
  logic [31:0] instr_addr, instr_rdata;
  logic        data_req, data_gnt, data_rvalid, data_we;
  logic [3:0]  data_be;
  logic [31:0] data_addr, data_wdata, data_rdata;
  integer      f_retire, f_cycle, f_uart, f_bus;

  fathom_mem #(.MemWords(MemWords), .MemBase(MemBase), .UartAddr(UartAddr)) u_mem (
    .clk (clk), .rst_n (rst_n), .cycle (cycle_q),
    .instr_req (instr_req), .instr_gnt (instr_gnt), .instr_rvalid (instr_rvalid),
    .instr_addr (instr_addr), .instr_rdata (instr_rdata),
    .data_req (data_req), .data_gnt (data_gnt), .data_rvalid (data_rvalid),
    .data_we (data_we), .data_be (data_be), .data_addr (data_addr),
    .data_wdata (data_wdata), .data_rdata (data_rdata),
    .f_uart (f_uart), .f_bus (f_bus)
  );

  // ---- RVFI ---------------------------------------------------------------
  logic        rvfi_valid;
  logic [63:0] rvfi_order;
  logic [31:0] rvfi_insn, rvfi_pc_rdata, rvfi_pc_wdata;
  logic [4:0]  rvfi_rd_addr;
  logic [31:0] rvfi_rd_wdata;
  logic [31:0] rvfi_mem_addr, rvfi_mem_rdata, rvfi_mem_wdata;
  logic [3:0]  rvfi_mem_rmask, rvfi_mem_wmask;
  logic        rvfi_trap, rvfi_halt, rvfi_intr;
  logic [4:0]  rvfi_rs1_addr, rvfi_rs2_addr;
  logic [31:0] rvfi_rs1_rdata, rvfi_rs2_rdata;

  // ---- the core -----------------------------------------------------------
  ibex_top #(
    .BaseIsa         (ibex_pkg::BaseIsaRV32I),
    .RV32M           (ibex_pkg::RV32MNone),
    .RV32B           (ibex_pkg::RV32BNone),
    .RV32ZC          (ibex_pkg::RV32Zca),
    .RegFile         (ibex_pkg::RegFileFF),
    .WritebackStage  (1'b1),
    .BranchTargetALU (1'b0),
    .ICache          (1'b0),
    .BranchPredictor (1'b0),
    .SecureIbex      (1'b0),
    .PMPEnable       (1'b0),
    .DbgTriggerEn    (1'b0)
  ) u_top (
    .clk_i (clk), .rst_ni (rst_n), .test_en_i (1'b0), .scan_rst_ni (1'b1),
    .ram_cfg_icache_tag_i ('0), .ram_cfg_icache_data_i ('0),
    .ram_cfg_icache_tag_o (), .ram_cfg_icache_data_o (),
    .cheriot_enable_i (4'b0000),
    .hart_id_i ('0), .boot_addr_i (BootAddr), .trvk_heap_base_addr_i ('0),

    .instr_req_o (instr_req), .instr_gnt_i (instr_gnt), .instr_rvalid_i (instr_rvalid),
    .instr_addr_o (instr_addr), .instr_rdata_i (instr_rdata),
    .instr_rdata_intg_i ('0), .instr_err_i (1'b0),

    .data_req_o (data_req), .data_gnt_i (data_gnt), .data_rvalid_i (data_rvalid),
    .data_we_o (data_we), .data_be_o (data_be), .data_addr_o (data_addr),
    .data_wdata_o (data_wdata), .data_wdata_intg_o (), .data_tag_o (),
    .data_rdata_i (data_rdata), .data_rdata_intg_i ('0), .data_tag_i (1'b0),
    .data_err_i (1'b0),

    .trvk_revbm_req_o (), .trvk_revbm_gnt_i (1'b0), .trvk_revbm_rvalid_i (1'b0),
    .trvk_revbm_addr_o (), .trvk_revbm_rdata_i ('0), .trvk_revbm_rdata_intg_i ('0),
    .trvk_revbm_err_i (1'b0),

    .irq_software_i (1'b0), .irq_timer_i (1'b0), .irq_external_i (1'b0),
    .irq_fast_i ('0), .irq_nm_i (1'b0),

    .scramble_key_valid_i (1'b0), .scramble_key_i ('0), .scramble_nonce_i ('0),
    .scramble_req_o (),

    .debug_req_i (1'b0), .crash_dump_o (), .double_fault_seen_o (),

    .rvfi_valid (rvfi_valid), .rvfi_order (rvfi_order), .rvfi_insn (rvfi_insn),
    .rvfi_trap (rvfi_trap), .rvfi_halt (rvfi_halt), .rvfi_intr (rvfi_intr),
    .rvfi_mode (), .rvfi_ixl (),
    .rvfi_rs1_addr (rvfi_rs1_addr), .rvfi_rs2_addr (rvfi_rs2_addr), .rvfi_rs3_addr (),
    .rvfi_rs1_rdata (rvfi_rs1_rdata), .rvfi_rs2_rdata (rvfi_rs2_rdata), .rvfi_rs3_rdata (),
    .rvfi_rs1_rcap (), .rvfi_rs2_rcap (), .rvfi_rd_wcap (),
    .rvfi_rd_addr (rvfi_rd_addr), .rvfi_rd_wdata (rvfi_rd_wdata),
    .rvfi_pc_rdata (rvfi_pc_rdata), .rvfi_pc_wdata (rvfi_pc_wdata),
    .rvfi_mem_addr (rvfi_mem_addr), .rvfi_mem_rmask (rvfi_mem_rmask),
    .rvfi_mem_wmask (rvfi_mem_wmask), .rvfi_mem_rdata (rvfi_mem_rdata),
    .rvfi_mem_wdata (rvfi_mem_wdata), .rvfi_mem_is_cap (),
    .rvfi_mem_rcap (), .rvfi_mem_wcap (),
    .rvfi_ext_pre_mip (), .rvfi_ext_post_mip (), .rvfi_ext_nmi (), .rvfi_ext_nmi_int (),
    .rvfi_ext_debug_req (), .rvfi_ext_debug_mode (), .rvfi_ext_rf_wr_suppress (),
    .rvfi_ext_mcycle (), .rvfi_ext_mhpmcounters (), .rvfi_ext_mhpmcountersh (),
    .rvfi_ext_ic_scr_key_valid (), .rvfi_ext_irq_valid (),
    .rvfi_ext_expanded_insn_valid (), .rvfi_ext_expanded_insn (),
    .rvfi_ext_expanded_insn_last (),

    .fetch_enable_i (4'b0001), .mcounteren_writable_i (4'b0000),
    .alert_minor_o (), .alert_major_internal_o (), .alert_major_bus_o (),
    .core_sleep_o (),
    .lockstep_cmp_en_o (),
    .data_req_shadow_o (), .data_we_shadow_o (), .data_be_shadow_o (),
    .data_addr_shadow_o (), .data_wdata_shadow_o (), .data_wdata_intg_shadow_o (),
    .instr_req_shadow_o (), .instr_addr_shadow_o ()
  );

  // ---- stage taps (SPEC §5.4): the cycle-accurate half RVFI does not expose ----
  wire        tap_id_valid = u_top.u_ibex_core.instr_valid_id;
  wire        tap_id_new   = u_top.u_ibex_core.instr_new_id;
  wire        tap_id_ready = u_top.u_ibex_core.id_in_ready;
  wire [31:0] tap_pc_if    = u_top.u_ibex_core.pc_if;
  wire [31:0] tap_pc_id    = u_top.u_ibex_core.pc_id;
  wire [31:0] tap_pc_wb    = u_top.u_ibex_core.pc_wb;
  wire        tap_wb_done  = u_top.u_ibex_core.wb_stage_i.instr_done_wb_o;
  wire        tap_ld_out   = u_top.u_ibex_core.wb_stage_i.outstanding_load_wb_o;
  wire        tap_st_out   = u_top.u_ibex_core.wb_stage_i.outstanding_store_wb_o;

  // ---- logs ---------------------------------------------------------------
  string  hexfile, vcdfile, outdir;

  initial begin
    if (!$value$plusargs("outdir=%s", outdir)) outdir = "build/sim";
    if (!$value$plusargs("hex=%s", hexfile))   hexfile = "build/uart_puts.hex";
    if (!$value$plusargs("vcd=%s", vcdfile))   vcdfile = "build/sim/rtl.vcd";

    u_mem.load(hexfile);

    f_retire = $fopen({outdir, "/retire.log"}, "w");
    f_cycle  = $fopen({outdir, "/cycle.log"},  "w");
    f_uart   = $fopen({outdir, "/uart.log"},   "w");
    f_bus    = $fopen({outdir, "/bus.log"},    "w");
    $fdisplay(f_bus, "cycle instr_req instr_addr data_req data_we data_be data_addr data_wdata");
    // Column headers are part of the contract forge parses against.
    $fdisplay(f_retire,
      "cycle order pc insn rd rd_wdata rs1 rs1_rdata rs2 rs2_rdata mem_addr mem_rmask mem_wmask mem_rdata mem_wdata trap");
    $fdisplay(f_cycle, "cycle pc_if pc_id pc_wb id_valid id_new id_ready wb_done ld_out st_out");

    $dumpfile(vcdfile);
    $dumpvars(0, fathom_tb);

    repeat (8) @(posedge clk);
    @(negedge clk);                                    // release between edges:
    rst_n = 1'b1;                                      // no race with the samplers
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
    if (rst_n) begin
      $fdisplay(f_cycle, "%0d %08x %08x %08x %0d %0d %0d %0d %0d %0d",
                cycle_q, tap_pc_if, tap_pc_id, tap_pc_wb,
                tap_id_valid, tap_id_new, tap_id_ready, tap_wb_done,
                tap_ld_out, tap_st_out);
      if (rvfi_valid) begin
        $fdisplay(f_retire, "%0d %0d %08x %08x %0d %08x %0d %08x %0d %08x %08x %0d %0d %08x %08x %0d",
                  cycle_q, rvfi_order, rvfi_pc_rdata, rvfi_insn,
                  rvfi_rd_addr, rvfi_rd_wdata,
                  rvfi_rs1_addr, rvfi_rs1_rdata, rvfi_rs2_addr, rvfi_rs2_rdata,
                  rvfi_mem_addr, rvfi_mem_rmask, rvfi_mem_wmask,
                  rvfi_mem_rdata, rvfi_mem_wdata, rvfi_trap);
      end
    end
  end

  // ---- stop condition -----------------------------------------------------
  // The traced region ends at the infinite loop in fathom_main. Stop the first
  // time it retires twice — once to enter, once to prove it is the self-loop.
  int unsigned halt_hits = 0;
  bit [31:0] pc_end;
  initial if (!$value$plusargs("pc_end=%h", pc_end)) pc_end = 32'hFFFF_FFFF;

  always_ff @(posedge clk) begin
    if (rst_n && rvfi_valid && rvfi_pc_rdata == pc_end) halt_hits <= halt_hits + 1;
    if (halt_hits >= 2) begin
      $fdisplay(f_cycle, "# halt at cycle %0d, %0d retires", cycle_q, rvfi_order);
      $fclose(f_retire); $fclose(f_cycle); $fclose(f_uart); $fclose(f_bus);
      $display("\n[fathom_tb] halt: cycle=%0d retires=%0d", cycle_q, rvfi_order);
      $finish;
    end
    if (cycle_q > MaxCycles) begin
      $display("[fathom_tb] TIMEOUT at cycle %0d", cycle_q);
      $fclose(f_retire); $fclose(f_cycle); $fclose(f_uart); $fclose(f_bus);
      $fatal(1, "timeout");
    end
  end

endmodule
