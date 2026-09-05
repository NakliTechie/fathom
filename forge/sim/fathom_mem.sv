`timescale 1ns/1ps
// fathom_mem.sv — the memory both harnesses share.
//
// One flat memory, a memory-mapped UART, and a per-cycle bus log. The RTL and
// gate-level testbenches instantiate this identically, so any difference between
// the two runs is the core's, not the environment's.

module fathom_mem #(
  parameter int unsigned MemWords = 32768,             // 128 KiB
  parameter bit [31:0]   MemBase  = 32'h8000_0000,
  parameter bit [31:0]   UartAddr = 32'h1000_0000
) (
  input  logic        clk,
  input  logic        rst_n,
  input  int unsigned cycle,

  input  logic        instr_req,
  output logic        instr_gnt,
  output logic        instr_rvalid,
  input  logic [31:0] instr_addr,
  output logic [31:0] instr_rdata,

  input  logic        data_req,
  output logic        data_gnt,
  output logic        data_rvalid,
  input  logic        data_we,
  input  logic [3:0]  data_be,
  input  logic [31:0] data_addr,
  input  logic [31:0] data_wdata,
  output logic [31:0] data_rdata,

  input  integer      f_uart,
  input  integer      f_bus
);

  logic [31:0] mem [MemWords];

  function automatic bit in_mem(input logic [31:0] a);
    return (a >= MemBase) && (a < MemBase + (MemWords * 4));
  endfunction

  function automatic int unsigned widx(input logic [31:0] a);
    return (a - MemBase) >> 2;
  endfunction

  // Fail closed (SPEC §0.8): an access outside the modelled memory is a harness
  // bug, not something to silently wrap into a valid index.
  task automatic bad_access(input string kind, input logic [31:0] a);
    $display("[fathom_mem] %s access out of range: %08x at cycle %0d", kind, a, cycle);
    $fatal(1, "address out of range");
  endtask

  task automatic load(input string hexfile);
    foreach (mem[i]) mem[i] = 32'h0;
    $readmemh(hexfile, mem);
  endtask

  // Zero-latency grant, one-cycle response — the simplest protocol-legal memory.
  assign instr_gnt = instr_req;
  assign data_gnt  = data_req;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      instr_rvalid <= 1'b0;
      data_rvalid  <= 1'b0;
    end else begin
      instr_rvalid <= instr_req;
      data_rvalid  <= data_req;
      if (instr_req) begin
        if (!in_mem(instr_addr)) bad_access("instr", instr_addr);
        instr_rdata <= mem[widx(instr_addr)];
      end
      if (data_req) begin
        if (data_we) begin
          if (data_addr[31:28] == UartAddr[31:28]) begin
            // the memory-mapped write: the bottom of the descent
            $fdisplay(f_uart, "%0d %02x", cycle, data_wdata[7:0]);
          end else begin
            if (!in_mem(data_addr)) bad_access("store", data_addr);
            if (data_be[0]) mem[widx(data_addr)][ 7: 0] <= data_wdata[ 7: 0];
            if (data_be[1]) mem[widx(data_addr)][15: 8] <= data_wdata[15: 8];
            if (data_be[2]) mem[widx(data_addr)][23:16] <= data_wdata[23:16];
            if (data_be[3]) mem[widx(data_addr)][31:24] <= data_wdata[31:24];
          end
        end else begin
          if (data_addr[31:28] != UartAddr[31:28] && !in_mem(data_addr))
            bad_access("load", data_addr);
          data_rdata <= (data_addr[31:28] == UartAddr[31:28]) ? 32'h0
                                                             : mem[widx(data_addr)];
        end
      end
    end
  end

  // The bus, every cycle. This is what RTL-vs-gates equivalence is asserted on.
  always_ff @(posedge clk) begin
    if (rst_n)
      $fdisplay(f_bus, "%0d %0d %08x %0d %0d %0d %08x %08x",
                cycle, instr_req, instr_addr, data_req, data_we, data_be,
                data_addr, data_wdata);
  end

endmodule
