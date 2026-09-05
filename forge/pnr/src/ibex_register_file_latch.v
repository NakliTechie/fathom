module ibex_register_file_latch (
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
	function automatic signed [4:0] sv2v_cast_5_signed;
		input reg signed [4:0] inp;
		sv2v_cast_5_signed = inp;
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
			reg [DataWidth - 1:0] rf_data [0:15];
			reg [CapWidth - 1:0] rf_shared [0:15];
			wire clk_int;
			prim_generic_clock_gating cg_we_global(
				.clk_i(clk_i),
				.en_i(we_a_i),
				.test_en_i(test_en_i),
				.clk_o(clk_int)
			);
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
			reg [DataWidth - 1:0] wdata_a_q;
			reg [CapWidth - 1:0] wshared_a_q;
			always @(posedge clk_int or negedge rst_ni) begin : sample_wdata
				if (!rst_ni)
					wdata_a_q <= WordZeroVal;
				else if (we_a_i)
					wdata_a_q <= wdata_a_i;
			end
			always @(posedge clk_int or negedge rst_ni) begin : sample_wshared
				if (!rst_ni)
					wshared_a_q <= CapWordZeroVal;
				else if (we_a_i)
					wshared_a_q <= wshared_data;
			end
			wire [15:1] data_clocks;
			wire [15:1] shared_clocks;
			genvar _gv_x_1;
			for (_gv_x_1 = 1; _gv_x_1 < 16; _gv_x_1 = _gv_x_1 + 1) begin : gen_data_cg_word_iter
				localparam x = _gv_x_1;
				prim_generic_clock_gating cg_i(
					.clk_i(clk_int),
					.en_i(we_a_dec[x] && !waddr_a_i[4]),
					.test_en_i(test_en_i),
					.clk_o(data_clocks[x])
				);
			end
			genvar _gv_x_2;
			for (_gv_x_2 = 1; _gv_x_2 < 16; _gv_x_2 = _gv_x_2 + 1) begin : gen_shared_cg_word_iter
				localparam x = _gv_x_2;
				prim_generic_clock_gating cg_i(
					.clk_i(clk_int),
					.en_i(((cheriot_enabled && we_a_dec[x]) && !waddr_a_i[4]) || (((!cheriot_enabled && !RV32E) && we_a_dec[x]) && waddr_a_i[4])),
					.test_en_i(test_en_i),
					.clk_o(shared_clocks[x])
				);
			end
			genvar _gv_i_1;
			for (_gv_i_1 = 1; _gv_i_1 < 16; _gv_i_1 = _gv_i_1 + 1) begin : g_rf_data_latches
				localparam i = _gv_i_1;
				always @(*) begin
					if (_sv2v_0)
						;
					if (data_clocks[i])
						rf_data[i] = wdata_a_q;
				end
			end
			genvar _gv_i_2;
			for (_gv_i_2 = 1; _gv_i_2 < 16; _gv_i_2 = _gv_i_2 + 1) begin : g_rf_shared_latches
				localparam i = _gv_i_2;
				always @(*) begin
					if (_sv2v_0)
						;
					if (shared_clocks[i])
						rf_shared[i] = wshared_a_q;
				end
			end
			wire [CapWidth - 1:0] rcap_r0;
			if (DummyInstructions) begin : g_dummy_r0
				wire we_data_r0;
				wire we_shared_r0;
				assign we_data_r0 = (we_a_dec[0] && !waddr_a_i[4]) && dummy_instr_wb_i;
				assign we_shared_r0 = (cheriot_enabled ? we_data_r0 : (!RV32E && we_a_dec[0]) && waddr_a_i[4]);
				wire r0_data_clock;
				wire r0_shared_clock;
				prim_generic_clock_gating cg_r0_data(
					.clk_i(clk_int),
					.en_i(we_data_r0),
					.test_en_i(test_en_i),
					.clk_o(r0_data_clock)
				);
				prim_generic_clock_gating cg_r0_shared(
					.clk_i(clk_int),
					.en_i(we_shared_r0),
					.test_en_i(test_en_i),
					.clk_o(r0_shared_clock)
				);
				reg [DataWidth - 1:0] rf_data_r0;
				reg [CapWidth - 1:0] rf_shared_r0;
				always @(*) begin : latch_data_r0
					if (_sv2v_0)
						;
					if (r0_data_clock)
						rf_data_r0 = wdata_a_q;
				end
				always @(*) begin : latch_shared_r0
					if (_sv2v_0)
						;
					if (r0_shared_clock)
						rf_shared_r0 = wshared_a_q;
				end
				wire [DataWidth:1] sv2v_tmp_B49E2;
				assign sv2v_tmp_B49E2 = (dummy_instr_id_i ? rf_data_r0 : WordZeroVal);
				always @(*) rf_data[0] = sv2v_tmp_B49E2;
				wire [CapWidth:1] sv2v_tmp_798DA;
				assign sv2v_tmp_798DA = rf_shared_r0;
				always @(*) rf_shared[0] = sv2v_tmp_798DA;
				assign rcap_r0 = (dummy_instr_id_i ? rf_shared[0] : CapWordZeroVal);
			end
			else begin : g_normal_r0
				wire [DataWidth:1] sv2v_tmp_CB483;
				assign sv2v_tmp_CB483 = WordZeroVal;
				always @(*) rf_data[0] = sv2v_tmp_CB483;
				assign rcap_r0 = CapWordZeroVal;
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				if (!RV32E) begin : g_rf_shared0_x16
					wire r0_shared_clock;
					reg [DataWidth - 1:0] rf_shared_r0;
					prim_generic_clock_gating cg_r0_shared(
						.clk_i(clk_int),
						.en_i((we_a_dec[0] && waddr_a_i[4]) && !cheriot_enabled),
						.test_en_i(test_en_i),
						.clk_o(r0_shared_clock)
					);
					always @(*) begin : latch_shared_r0
						if (_sv2v_0)
							;
						if (r0_shared_clock)
							rf_shared_r0 = wdata_a_q;
					end
					wire [CapWidth:1] sv2v_tmp_30C3B;
					assign sv2v_tmp_30C3B = sv2v_cast_3CCAF(rf_shared_r0);
					always @(*) rf_shared[0] = sv2v_tmp_30C3B;
				end
				else begin : g_rf_shared0_no_x16
					wire [CapWidth:1] sv2v_tmp_86C1B;
					assign sv2v_tmp_86C1B = CapWordZeroVal;
					always @(*) rf_shared[0] = sv2v_tmp_86C1B;
					wire unused_we_a_dec0;
					assign unused_we_a_dec0 = we_a_dec[0];
				end
			end
			assign rdata_a_o = (raddr_a_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_a_i[3:0]]) : rf_data[raddr_a_i[3:0]]);
			assign rdata_b_o = (raddr_b_i[4] && !cheriot_enabled ? sv2v_cast_9719B(rf_shared[raddr_b_i[3:0]]) : rf_data[raddr_b_i[3:0]]);
			assign rcap_a_o = (cheriot_enabled ? (raddr_a_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_a_i[3:0]]) : CapWordZeroVal);
			assign rcap_b_o = (cheriot_enabled ? (raddr_b_i[3:0] == {4 {1'sb0}} ? rcap_r0 : rf_shared[raddr_b_i[3:0]]) : CapWordZeroVal);
		end
		else begin : g_plain_rf
			localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
			localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
			reg [DataWidth - 1:0] mem [0:NUM_WORDS - 1];
			reg [NUM_WORDS - 1:0] waddr_onehot_a;
			wire [NUM_WORDS - 1:1] mem_clocks;
			reg [DataWidth - 1:0] wdata_a_q;
			wire [ADDR_WIDTH - 1:0] raddr_a_int;
			wire [ADDR_WIDTH - 1:0] raddr_b_int;
			wire [ADDR_WIDTH - 1:0] waddr_a_int;
			assign raddr_a_int = raddr_a_i[ADDR_WIDTH - 1:0];
			assign raddr_b_int = raddr_b_i[ADDR_WIDTH - 1:0];
			assign waddr_a_int = waddr_a_i[ADDR_WIDTH - 1:0];
			wire clk_int;
			assign rdata_a_o = mem[raddr_a_int];
			assign rdata_b_o = mem[raddr_b_int];
			assign rcap_a_o = CapWordZeroVal;
			assign rcap_b_o = CapWordZeroVal;
			wire unused_wcap_a;
			assign unused_wcap_a = ^wcap_a_i;
			wire unused_cheriot_enable;
			assign unused_cheriot_enable = ^cheriot_enable_i;
			prim_generic_clock_gating cg_we_global(
				.clk_i(clk_i),
				.en_i(we_a_i),
				.test_en_i(test_en_i),
				.clk_o(clk_int)
			);
			always @(posedge clk_int or negedge rst_ni) begin : sample_wdata
				if (!rst_ni)
					wdata_a_q <= WordZeroVal;
				else if (we_a_i)
					wdata_a_q <= wdata_a_i;
			end
			always @(*) begin : wad
				if (_sv2v_0)
					;
				begin : sv2v_autoblock_2
					reg signed [31:0] i;
					for (i = 0; i < NUM_WORDS; i = i + 1)
						begin : wad_word_iter
							if (we_a_i && (waddr_a_int == sv2v_cast_5_signed(i)))
								waddr_onehot_a[i] = 1'b1;
							else
								waddr_onehot_a[i] = 1'b0;
						end
				end
			end
			wire unused_strobe;
			assign unused_strobe = waddr_onehot_a[0];
			genvar _gv_x_3;
			for (_gv_x_3 = 1; _gv_x_3 < NUM_WORDS; _gv_x_3 = _gv_x_3 + 1) begin : gen_cg_word_iter
				localparam x = _gv_x_3;
				prim_generic_clock_gating cg_i(
					.clk_i(clk_int),
					.en_i(waddr_onehot_a[x]),
					.test_en_i(test_en_i),
					.clk_o(mem_clocks[x])
				);
			end
			genvar _gv_i_3;
			for (_gv_i_3 = 1; _gv_i_3 < NUM_WORDS; _gv_i_3 = _gv_i_3 + 1) begin : g_rf_latches
				localparam i = _gv_i_3;
				always @(*) begin
					if (_sv2v_0)
						;
					if (mem_clocks[i])
						mem[i] = wdata_a_q;
				end
			end
			if (DummyInstructions) begin : g_dummy_r0
				wire we_r0_dummy;
				wire r0_clock;
				reg [DataWidth - 1:0] mem_r0;
				assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
				prim_generic_clock_gating cg_i(
					.clk_i(clk_int),
					.en_i(we_r0_dummy),
					.test_en_i(test_en_i),
					.clk_o(r0_clock)
				);
				always @(*) begin : latch_wdata
					if (_sv2v_0)
						;
					if (r0_clock)
						mem_r0 = wdata_a_q;
				end
				wire [DataWidth:1] sv2v_tmp_EC5DE;
				assign sv2v_tmp_EC5DE = (dummy_instr_id_i ? mem_r0 : WordZeroVal);
				always @(*) mem[0] = sv2v_tmp_EC5DE;
			end
			else begin : g_normal_r0
				wire unused_dummy_instr;
				assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
				wire [DataWidth:1] sv2v_tmp_63277;
				assign sv2v_tmp_63277 = WordZeroVal;
				always @(*) mem[0] = sv2v_tmp_63277;
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
