module ibex_register_file_fpga (
	clk_i,
	rst_ni,
	test_en_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	cheriot_enable_i,
	raddr_a_i,
	rdata_a_o,
	rcap_a_o,
	raddr_b_i,
	rdata_b_o,
	rcap_b_o,
	waddr_a_i,
	wdata_a_i,
	wcap_a_i,
	we_a_i
);
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] RV32E = 0;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] DummyInstructions = 0;
	parameter [DataWidth - 1:0] WordZeroVal = 1'sb0;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	parameter [31:0] CapWidth = ibex_cheriot_pkg_REGCAP_W;
	parameter [CapWidth - 1:0] CapWordZeroVal = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [4:0] raddr_a_i;
	output wire [DataWidth - 1:0] rdata_a_o;
	output wire [CapWidth - 1:0] rcap_a_o;
	input wire [4:0] raddr_b_i;
	output wire [DataWidth - 1:0] rdata_b_o;
	output wire [CapWidth - 1:0] rcap_b_o;
	input wire [4:0] waddr_a_i;
	input wire [DataWidth - 1:0] wdata_a_i;
	input wire [CapWidth - 1:0] wcap_a_i;
	input wire we_a_i;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	function automatic [CapWidth - 1:0] sv2v_cast_3CCAF;
		input reg [CapWidth - 1:0] inp;
		sv2v_cast_3CCAF = inp;
	endfunction
	function automatic [DataWidth - 1:0] sv2v_cast_9719B;
		input reg [DataWidth - 1:0] inp;
		sv2v_cast_9719B = inp;
	endfunction
	generate
		if (BaseIsa == 32'sd1) begin : g_cheriot_rf
			wire cheriot_enabled;
			assign cheriot_enabled = cheriot_enable_i == ibex_pkg_IbexMuBiOn;
			reg [DataWidth - 1:0] rf_data [0:15];
			reg [CapWidth - 1:0] rf_shared [0:15];
			wire unused_dummy_instr;
			assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
			always @(posedge clk_i) begin : sync_data_write
				if ((we_a_i && !waddr_a_i[4]) && (waddr_a_i[3:0] != {4 {1'sb0}}))
					rf_data[waddr_a_i[3:0]] <= wdata_a_i;
			end
			always @(posedge clk_i) begin : sync_shared_write
				if (cheriot_enabled) begin
					if ((we_a_i && !waddr_a_i[4]) && (waddr_a_i[3:0] != {4 {1'sb0}}))
						rf_shared[waddr_a_i[3:0]] <= wcap_a_i;
				end
				else if (!RV32E) begin
					if (we_a_i && waddr_a_i[4])
						rf_shared[waddr_a_i[3:0]] <= sv2v_cast_3CCAF(wdata_a_i);
				end
			end
			initial begin : sv2v_autoblock_1
				reg signed [31:0] k;
				for (k = 0; k < 16; k = k + 1)
					begin
						rf_data[k] = WordZeroVal;
						rf_shared[k] = CapWordZeroVal;
					end
			end
			assign rdata_a_o = (raddr_a_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_a_i[3:0]]) : rf_data[raddr_a_i[3:0]]);
			assign rdata_b_o = (raddr_b_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_b_i[3:0]]) : rf_data[raddr_b_i[3:0]]);
			assign rcap_a_o = (cheriot_enabled ? (raddr_a_i[3:0] == {4 {1'sb0}} ? CapWordZeroVal : rf_shared[raddr_a_i[3:0]]) : CapWordZeroVal);
			assign rcap_b_o = (cheriot_enabled ? (raddr_b_i[3:0] == {4 {1'sb0}} ? CapWordZeroVal : rf_shared[raddr_b_i[3:0]]) : CapWordZeroVal);
			wire unused_rst_ni;
			assign unused_rst_ni = rst_ni;
			wire unused_test_en;
			assign unused_test_en = test_en_i;
		end
		else begin : g_plain_rf
			localparam signed [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
			localparam signed [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
			reg [DataWidth - 1:0] mem [0:NUM_WORDS - 1];
			wire we;
			assign rdata_a_o = (raddr_a_i == {5 {1'sb0}} ? WordZeroVal : mem[raddr_a_i]);
			assign rdata_b_o = (raddr_b_i == {5 {1'sb0}} ? WordZeroVal : mem[raddr_b_i]);
			assign we = (waddr_a_i == {5 {1'sb0}} ? 1'b0 : we_a_i);
			always @(posedge clk_i) begin : sync_write
				if (we == 1'b1)
					mem[waddr_a_i] <= wdata_a_i;
			end
			initial begin : sv2v_autoblock_2
				reg signed [31:0] k;
				for (k = 0; k < NUM_WORDS; k = k + 1)
					mem[k] = WordZeroVal;
			end
			wire unused_rst_ni;
			assign unused_rst_ni = rst_ni;
			wire unused_dummy_instr;
			assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
			wire unused_test_en;
			assign unused_test_en = test_en_i;
			assign rcap_a_o = CapWordZeroVal;
			assign rcap_b_o = CapWordZeroVal;
			wire unused_wcap_a;
			assign unused_wcap_a = ^wcap_a_i;
			wire unused_cheriot_enable;
			assign unused_cheriot_enable = ^cheriot_enable_i;
		end
	endgenerate
endmodule
