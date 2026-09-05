module ibex_register_file_ff (
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
	reg _sv2v_0;
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
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
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
			wire [DataWidth - 1:0] rf_data [0:15];
			wire [CapWidth - 1:0] rf_shared [0:15];
			reg [15:0] we_a_dec;
			always @(*) begin : we_a_decoder
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_1
					reg [31:0] i;
					for (i = 0; i < 16; i = i + 1)
						we_a_dec[i] = (waddr_a_i[3:0] == sv2v_cast_4(i) ? we_a_i : 1'b0);
				end
			end
			wire [CapWidth - 1:0] wshared_data;
			assign wshared_data = (cheriot_enabled ? wcap_a_i : sv2v_cast_3CCAF(wdata_a_i));
			genvar _gv_i_1;
			for (_gv_i_1 = 1; _gv_i_1 < 16; _gv_i_1 = _gv_i_1 + 1) begin : g_rf_data_flops
				localparam i = _gv_i_1;
				reg [DataWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= WordZeroVal;
					else if (we_a_dec[i] && !waddr_a_i[4])
						rf_reg_q <= wdata_a_i;
				assign rf_data[i] = rf_reg_q;
			end
			genvar _gv_i_2;
			for (_gv_i_2 = 1; _gv_i_2 < 16; _gv_i_2 = _gv_i_2 + 1) begin : g_rf_shared_flops
				localparam i = _gv_i_2;
				reg [CapWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= CapWordZeroVal;
					else if (((cheriot_enabled && we_a_dec[i]) && !waddr_a_i[4]) || (((!cheriot_enabled && !RV32E) && we_a_dec[i]) && waddr_a_i[4]))
						rf_reg_q <= wshared_data;
				assign rf_shared[i] = rf_reg_q;
			end
			wire [CapWidth - 1:0] rcap_r0;
			if (DummyInstructions) begin : g_dummy_r0
				wire we_data_r0;
				wire we_shared_r0;
				assign we_data_r0 = (we_a_dec[0] && !waddr_a_i[4]) && dummy_instr_wb_i;
				assign we_shared_r0 = (cheriot_enabled ? we_data_r0 : (!RV32E && we_a_dec[0]) && waddr_a_i[4]);
				reg [DataWidth - 1:0] rf_data_r0_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_data_r0_q <= WordZeroVal;
					else if (we_data_r0)
						rf_data_r0_q <= wdata_a_i;
				assign rf_data[0] = (dummy_instr_id_i ? rf_data_r0_q : WordZeroVal);
				reg [CapWidth - 1:0] rf_shared_r0_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_shared_r0_q <= CapWordZeroVal;
					else if (we_shared_r0)
						rf_shared_r0_q <= wshared_data;
				assign rf_shared[0] = rf_shared_r0_q;
				assign rcap_r0 = (dummy_instr_id_i ? rf_shared[0] : CapWordZeroVal);
			end
			else begin : g_normal_r0
				assign rf_data[0] = WordZeroVal;
				assign rcap_r0 = CapWordZeroVal;
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				if (!RV32E) begin : g_rf_shared0_x16
					reg [DataWidth - 1:0] rf_shared_r0_q;
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							rf_shared_r0_q <= WordZeroVal;
						else if ((!cheriot_enabled && we_a_dec[0]) && waddr_a_i[4])
							rf_shared_r0_q <= wdata_a_i;
					assign rf_shared[0] = sv2v_cast_3CCAF(rf_shared_r0_q);
				end
				else begin : g_rf_shared0_no_x16
					assign rf_shared[0] = CapWordZeroVal;
					wire unused_we_a_dec0;
					assign unused_we_a_dec0 = we_a_dec[0];
				end
			end
			assign rdata_a_o = (raddr_a_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_a_i[3:0]]) : rf_data[raddr_a_i[3:0]]);
			assign rdata_b_o = (raddr_b_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_b_i[3:0]]) : rf_data[raddr_b_i[3:0]]);
			assign rcap_a_o = (cheriot_enabled ? (raddr_a_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_a_i[3:0]]) : CapWordZeroVal);
			assign rcap_b_o = (cheriot_enabled ? (raddr_b_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_b_i[3:0]]) : CapWordZeroVal);
			wire unused_test_en;
			assign unused_test_en = test_en_i;
		end
		else begin : g_plain_rf
			localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
			localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
			wire [DataWidth - 1:0] rf_reg [0:NUM_WORDS - 1];
			reg [NUM_WORDS - 1:0] we_a_dec;
			always @(*) begin : we_a_decoder
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_2
					reg [31:0] i;
					for (i = 0; i < NUM_WORDS; i = i + 1)
						we_a_dec[i] = (waddr_a_i == sv2v_cast_5(i) ? we_a_i : 1'b0);
				end
			end
			wire unused_strobe;
			assign unused_strobe = we_a_dec[0];
			genvar _gv_i_3;
			for (_gv_i_3 = 1; _gv_i_3 < NUM_WORDS; _gv_i_3 = _gv_i_3 + 1) begin : g_rf_flops
				localparam i = _gv_i_3;
				reg [DataWidth - 1:0] rf_reg_q;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_reg_q <= WordZeroVal;
					else if (we_a_dec[i])
						rf_reg_q <= wdata_a_i;
				assign rf_reg[i] = rf_reg_q;
			end
			if (DummyInstructions) begin : g_dummy_r0
				wire we_r0_dummy;
				reg [DataWidth - 1:0] rf_r0_q;
				assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						rf_r0_q <= WordZeroVal;
					else if (we_r0_dummy)
						rf_r0_q <= wdata_a_i;
				assign rf_reg[0] = (dummy_instr_id_i ? rf_r0_q : WordZeroVal);
			end
			else begin : g_normal_r0
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				assign rf_reg[0] = WordZeroVal;
			end
			assign rdata_a_o = rf_reg[raddr_a_i[ADDR_WIDTH - 1:0]];
			assign rdata_b_o = rf_reg[raddr_b_i[ADDR_WIDTH - 1:0]];
			if (RV32E) begin : g_unused_raddr_msb
				wire [1:0] unused_raddr_msb;
				assign unused_raddr_msb = {raddr_a_i[4], raddr_b_i[4]};
			end
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
	initial _sv2v_0 = 0;
endmodule
