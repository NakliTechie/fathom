module ibex_wb_stage (
	clk_i,
	rst_ni,
	en_wb_i,
	instr_type_wb_i,
	pc_id_i,
	instr_is_compressed_id_i,
	instr_perf_count_id_i,
	instr_is_cheriot_i,
	cheriot_load_i,
	cheriot_store_i,
	ready_wb_o,
	rf_write_wb_o,
	outstanding_load_wb_o,
	outstanding_store_wb_o,
	pc_wb_o,
	perf_instr_ret_wb_o,
	perf_instr_ret_compressed_wb_o,
	perf_instr_ret_wb_spec_o,
	perf_instr_ret_compressed_wb_spec_o,
	rf_waddr_id_i,
	rf_wdata_id_i,
	rf_we_id_i,
	cheriot_rf_we_i,
	cheriot_rf_wdata_i,
	cheriot_rf_wcap_i,
	dummy_instr_id_i,
	rf_wdata_lsu_i,
	rf_wcap_lsu_i,
	rf_we_lsu_i,
	rf_wdata_fwd_wb_o,
	rf_wcap_fwd_wb_o,
	rf_waddr_wb_o,
	rf_wdata_wb_o,
	rf_wcap_wb_o,
	rf_we_wb_o,
	dummy_instr_wb_o,
	lsu_resp_valid_i,
	lsu_resp_err_i,
	instr_done_wb_o
);
	parameter [0:0] ResetAll = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire en_wb_i;
	input wire [1:0] instr_type_wb_i;
	input wire [31:0] pc_id_i;
	input wire instr_is_compressed_id_i;
	input wire instr_perf_count_id_i;
	input wire instr_is_cheriot_i;
	input wire cheriot_load_i;
	input wire cheriot_store_i;
	output wire ready_wb_o;
	output wire rf_write_wb_o;
	output wire outstanding_load_wb_o;
	output wire outstanding_store_wb_o;
	output wire [31:0] pc_wb_o;
	output wire perf_instr_ret_wb_o;
	output wire perf_instr_ret_compressed_wb_o;
	output wire perf_instr_ret_wb_spec_o;
	output wire perf_instr_ret_compressed_wb_spec_o;
	input wire [4:0] rf_waddr_id_i;
	input wire [31:0] rf_wdata_id_i;
	input wire rf_we_id_i;
	input wire cheriot_rf_we_i;
	input wire [31:0] cheriot_rf_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] cheriot_rf_wcap_i;
	input wire dummy_instr_id_i;
	input wire [31:0] rf_wdata_lsu_i;
	input wire [34:0] rf_wcap_lsu_i;
	input wire rf_we_lsu_i;
	output wire [31:0] rf_wdata_fwd_wb_o;
	output wire [34:0] rf_wcap_fwd_wb_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire [31:0] rf_wdata_wb_o;
	output wire [34:0] rf_wcap_wb_o;
	output wire rf_we_wb_o;
	output wire dummy_instr_wb_o;
	input wire lsu_resp_valid_i;
	input wire lsu_resp_err_i;
	output wire instr_done_wb_o;
	wire [31:0] rf_wdata_wb_mux [0:1];
	wire [1:0] rf_wdata_wb_mux_we;
	wire [34:0] rf_wcap_wb;
	function automatic [5:0] sv2v_cast_67FCC;
		input reg [5:0] inp;
		sv2v_cast_67FCC = inp;
	endfunction
	function automatic [2:0] sv2v_cast_D855E;
		input reg [2:0] inp;
		sv2v_cast_D855E = inp;
	endfunction
	function automatic [3:0] sv2v_cast_A455A;
		input reg [3:0] inp;
		sv2v_cast_A455A = inp;
	endfunction
	function automatic [8:0] sv2v_cast_52713;
		input reg [8:0] inp;
		sv2v_cast_52713 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_67FCC(1'sb0), sv2v_cast_D855E(1'sb0), sv2v_cast_A455A(1'sb0), sv2v_cast_52713(1'sb0), sv2v_cast_52713(1'sb0)};
	generate
		if (WritebackStage) begin : g_writeback_stage
			reg [31:0] rf_wdata_wb_q;
			reg rf_we_wb_q;
			reg [4:0] rf_waddr_wb_q;
			wire wb_done;
			reg wb_valid_q;
			reg [31:0] wb_pc_q;
			reg wb_compressed_q;
			reg wb_count_q;
			reg [1:0] wb_instr_type_q;
			wire wb_valid_d;
			reg wb_is_cheriot_q;
			reg wb_cheriot_load_q;
			reg wb_cheriot_store_q;
			reg cheriot_rf_we_q;
			reg [31:0] cheriot_rf_wdata_q;
			reg [34:0] cheriot_rf_wcap_q;
			assign wb_valid_d = (en_wb_i & ready_wb_o) | (wb_valid_q & ~wb_done);
			assign wb_done = ((wb_instr_type_q == 2'd2) && ~(wb_is_cheriot_q && (wb_cheriot_load_q | wb_cheriot_store_q))) | lsu_resp_valid_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					wb_valid_q <= 1'b0;
				else
					wb_valid_q <= wb_valid_d;
			if (ResetAll) begin : g_wb_regs_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rf_we_wb_q <= 1'sb0;
						rf_waddr_wb_q <= 1'sb0;
						rf_wdata_wb_q <= 1'sb0;
						wb_instr_type_q <= 2'd0;
						wb_pc_q <= 1'sb0;
						wb_compressed_q <= 1'sb0;
						wb_count_q <= 1'sb0;
						wb_is_cheriot_q <= 1'b0;
						wb_cheriot_load_q <= 1'b0;
						wb_cheriot_store_q <= 1'b0;
						cheriot_rf_we_q <= 1'b0;
						cheriot_rf_wdata_q <= 1'sb0;
						cheriot_rf_wcap_q <= ibex_cheriot_pkg_NULL_CAP;
					end
					else if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
						wb_is_cheriot_q <= instr_is_cheriot_i;
						wb_cheriot_load_q <= cheriot_load_i;
						wb_cheriot_store_q <= cheriot_store_i;
						cheriot_rf_we_q <= cheriot_rf_we_i;
						cheriot_rf_wdata_q <= cheriot_rf_wdata_i;
						cheriot_rf_wcap_q <= cheriot_rf_wcap_i;
					end
			end
			else begin : g_wb_regs_nr
				always @(posedge clk_i)
					if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
						wb_is_cheriot_q <= instr_is_cheriot_i;
						wb_cheriot_load_q <= cheriot_load_i;
						wb_cheriot_store_q <= cheriot_store_i;
						cheriot_rf_we_q <= cheriot_rf_we_i;
						cheriot_rf_wdata_q <= cheriot_rf_wdata_i;
						cheriot_rf_wcap_q <= cheriot_rf_wcap_i;
					end
			end
			assign rf_waddr_wb_o = rf_waddr_wb_q;
			assign rf_wdata_wb_mux[0] = (wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q);
			assign rf_wdata_wb_mux_we[0] = (wb_is_cheriot_q ? cheriot_rf_we_q : rf_we_wb_q) & wb_valid_q;
			assign ready_wb_o = ~wb_valid_q | wb_done;
			assign rf_write_wb_o = wb_valid_q & (((rf_we_wb_q | (wb_is_cheriot_q & cheriot_rf_we_q)) | (wb_instr_type_q == 2'd0)) | wb_cheriot_load_q);
			assign outstanding_load_wb_o = wb_valid_q & ((wb_instr_type_q == 2'd0) | wb_cheriot_load_q);
			assign outstanding_store_wb_o = wb_valid_q & ((wb_instr_type_q == 2'd1) | wb_cheriot_store_q);
			assign pc_wb_o = wb_pc_q;
			assign instr_done_wb_o = wb_valid_q & wb_done;
			assign perf_instr_ret_wb_spec_o = wb_count_q & wb_valid_q;
			assign perf_instr_ret_compressed_wb_spec_o = perf_instr_ret_wb_spec_o & wb_compressed_q;
			assign perf_instr_ret_wb_o = (instr_done_wb_o & wb_count_q) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & wb_compressed_q;
			assign rf_wdata_fwd_wb_o = (wb_is_cheriot_q ? cheriot_rf_wdata_q : rf_wdata_wb_q);
			assign rf_wcap_fwd_wb_o = (wb_is_cheriot_q ? cheriot_rf_wcap_q : ibex_cheriot_pkg_NULL_CAP);
			assign rf_wcap_wb = (wb_is_cheriot_q && ~wb_cheriot_load_q ? cheriot_rf_wcap_q : ibex_cheriot_pkg_NULL_CAP);
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			if (DummyInstructions) begin : g_dummy_instr_wb
				reg dummy_instr_wb_q;
				if (ResetAll) begin : g_dummy_instr_wb_regs_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							dummy_instr_wb_q <= 1'b0;
						else if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				else begin : g_dummy_instr_wb_regs_nr
					always @(posedge clk_i)
						if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				assign dummy_instr_wb_o = dummy_instr_wb_q;
			end
			else begin : g_no_dummy_instr_wb
				wire unused_dummy_instr_id;
				assign unused_dummy_instr_id = dummy_instr_id_i;
				assign dummy_instr_wb_o = 1'b0;
			end
		end
		else begin : g_bypass_wb
			assign rf_waddr_wb_o = rf_waddr_id_i;
			assign rf_wdata_wb_mux[0] = (instr_is_cheriot_i ? cheriot_rf_wdata_i : rf_wdata_id_i);
			assign rf_wdata_wb_mux_we[0] = (instr_is_cheriot_i ? cheriot_rf_we_i : rf_we_id_i);
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			assign rf_wcap_wb = (instr_is_cheriot_i && ~cheriot_load_i ? cheriot_rf_wcap_i : ibex_cheriot_pkg_NULL_CAP);
			assign dummy_instr_wb_o = dummy_instr_id_i;
			assign perf_instr_ret_wb_spec_o = 1'b0;
			assign perf_instr_ret_compressed_wb_spec_o = 1'b0;
			assign perf_instr_ret_wb_o = (instr_perf_count_id_i & en_wb_i) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & instr_is_compressed_id_i;
			assign ready_wb_o = 1'b1;
			wire unused_clk;
			wire unused_rst;
			wire [1:0] unused_instr_type_wb;
			wire [31:0] unused_pc_id;
			wire unused_dummy_instr_id;
			wire unused_cheriot_store;
			assign unused_clk = clk_i;
			assign unused_rst = rst_ni;
			assign unused_instr_type_wb = instr_type_wb_i;
			assign unused_pc_id = pc_id_i;
			assign unused_dummy_instr_id = dummy_instr_id_i;
			assign unused_cheriot_store = cheriot_store_i;
			assign outstanding_load_wb_o = 1'b0;
			assign outstanding_store_wb_o = 1'b0;
			assign pc_wb_o = 1'sb0;
			assign rf_write_wb_o = 1'b0;
			assign rf_wdata_fwd_wb_o = 32'b00000000000000000000000000000000;
			assign rf_wcap_fwd_wb_o = ibex_cheriot_pkg_NULL_CAP;
			assign instr_done_wb_o = 1'b0;
		end
	endgenerate
	assign rf_wdata_wb_mux[1] = rf_wdata_lsu_i;
	assign rf_wdata_wb_o = ({32 {rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) | ({32 {rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]);
	assign rf_we_wb_o = |rf_wdata_wb_mux_we;
	assign rf_wcap_wb_o = (rf_wdata_wb_mux_we[0] ? rf_wcap_wb : (rf_wdata_wb_mux_we[1] ? rf_wcap_lsu_i : ibex_cheriot_pkg_NULL_CAP));
endmodule
