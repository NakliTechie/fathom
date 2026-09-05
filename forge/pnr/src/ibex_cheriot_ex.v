module ibex_cheriot_ex (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	debug_mode_i,
	fwd_we_i,
	fwd_waddr_i,
	fwd_wdata_i,
	fwd_wcap_i,
	rf_raddr_a_i,
	rf_rdata_a_i,
	rf_rcap_a_i,
	rf_raddr_b_i,
	rf_rdata_b_i,
	rf_rcap_b_i,
	rf_waddr_i,
	pcc_cap_i,
	pcc_cap_o,
	pc_id_i,
	branch_req_o,
	branch_req_spec_o,
	branch_target_o,
	cheriot_exec_id_i,
	instr_first_cycle_i,
	instr_valid_i,
	instr_is_cheriot_i,
	instr_is_rv32lsu_i,
	instr_is_compressed_i,
	cheriot_imm12_i,
	cheriot_imm20_i,
	cheriot_imm21_i,
	cheriot_cs2_dec_i,
	cheriot_operator_i,
	cheriot_cap_field_sel_i,
	cheriot_adder_a_sel_i,
	cheriot_adder_b_sel_i,
	cheriot_setaddr_sel_i,
	cheriot_setbounds_sel_i,
	cheriot_rf_we_o,
	result_data_o,
	result_cap_o,
	cheriot_ex_valid_o,
	cheriot_ex_err_o,
	cheriot_ex_err_info_o,
	cheriot_wb_err_o,
	cheriot_wb_err_info_o,
	lsu_req_o,
	lsu_cheriot_err_o,
	lsu_is_cap_o,
	lsu_lc_clrperm_o,
	lsu_we_o,
	lsu_addr_o,
	lsu_type_o,
	lsu_wdata_o,
	lsu_wcap_o,
	lsu_sign_ext_o,
	addr_incr_req_i,
	addr_last_i,
	rv32_lsu_req_i,
	rv32_lsu_we_i,
	rv32_lsu_type_i,
	rv32_lsu_wdata_i,
	rv32_lsu_sign_ext_i,
	rv32_lsu_addr_i,
	rv32_addr_incr_req_o,
	rv32_addr_last_o,
	csr_rdata_i,
	csr_rcap_i,
	csr_mstatus_mie_i,
	csr_access_o,
	csr_addr_o,
	csr_wdata_o,
	csr_wcap_o,
	csr_op_o,
	csr_op_en_o,
	csr_set_mie_o,
	csr_clr_mie_o,
	csr_mshwm_i,
	csr_mshwmb_i,
	csr_mshwm_set_o,
	csr_mshwm_new_o,
	ztop_rdata_i,
	ztop_rcap_i,
	csr_dbg_tclr_fault_i
);
	reg _sv2v_0;
	parameter [0:0] WritebackStage = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire debug_mode_i;
	input wire fwd_we_i;
	input wire [4:0] fwd_waddr_i;
	input wire [31:0] fwd_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] fwd_wcap_i;
	input wire [4:0] rf_raddr_a_i;
	input wire [31:0] rf_rdata_a_i;
	input wire [34:0] rf_rcap_a_i;
	input wire [4:0] rf_raddr_b_i;
	input wire [31:0] rf_rdata_b_i;
	input wire [34:0] rf_rcap_b_i;
	input wire [4:0] rf_waddr_i;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	input wire [111:0] pcc_cap_i;
	output reg [111:0] pcc_cap_o;
	input wire [31:0] pc_id_i;
	output wire branch_req_o;
	output wire branch_req_spec_o;
	output reg [31:0] branch_target_o;
	input wire cheriot_exec_id_i;
	input wire instr_first_cycle_i;
	input wire instr_valid_i;
	input wire instr_is_cheriot_i;
	input wire instr_is_rv32lsu_i;
	input wire instr_is_compressed_i;
	input wire [11:0] cheriot_imm12_i;
	input wire [19:0] cheriot_imm20_i;
	input wire [20:0] cheriot_imm21_i;
	input wire [4:0] cheriot_cs2_dec_i;
	input wire [25:0] cheriot_operator_i;
	input wire [2:0] cheriot_cap_field_sel_i;
	input wire [2:0] cheriot_adder_a_sel_i;
	input wire [1:0] cheriot_adder_b_sel_i;
	input wire [2:0] cheriot_setaddr_sel_i;
	input wire [2:0] cheriot_setbounds_sel_i;
	output wire cheriot_rf_we_o;
	output reg [31:0] result_data_o;
	output reg [34:0] result_cap_o;
	output wire cheriot_ex_valid_o;
	output wire cheriot_ex_err_o;
	output wire [11:0] cheriot_ex_err_info_o;
	output wire cheriot_wb_err_o;
	output wire [15:0] cheriot_wb_err_info_o;
	output wire lsu_req_o;
	output wire lsu_cheriot_err_o;
	output wire lsu_is_cap_o;
	output wire [2:0] lsu_lc_clrperm_o;
	output wire lsu_we_o;
	output wire [31:0] lsu_addr_o;
	output wire [1:0] lsu_type_o;
	output wire [31:0] lsu_wdata_o;
	output wire [34:0] lsu_wcap_o;
	output wire lsu_sign_ext_o;
	input wire addr_incr_req_i;
	input wire [31:0] addr_last_i;
	input wire rv32_lsu_req_i;
	input wire rv32_lsu_we_i;
	input wire [1:0] rv32_lsu_type_i;
	input wire [31:0] rv32_lsu_wdata_i;
	input wire rv32_lsu_sign_ext_i;
	input wire [31:0] rv32_lsu_addr_i;
	output wire rv32_addr_incr_req_o;
	output wire [31:0] rv32_addr_last_o;
	input wire [31:0] csr_rdata_i;
	input wire [34:0] csr_rcap_i;
	input wire csr_mstatus_mie_i;
	output reg csr_access_o;
	output reg [4:0] csr_addr_o;
	output reg [31:0] csr_wdata_o;
	output reg [34:0] csr_wcap_o;
	output reg [4:0] csr_op_o;
	output wire csr_op_en_o;
	output wire csr_set_mie_o;
	output wire csr_clr_mie_o;
	input wire [31:0] csr_mshwm_i;
	input wire [31:0] csr_mshwmb_i;
	output wire csr_mshwm_set_o;
	output wire [31:0] csr_mshwm_new_o;
	input wire [31:0] ztop_rdata_i;
	input wire [34:0] ztop_rcap_i;
	input wire csr_dbg_tclr_fault_i;
	wire cheriot_lsu_req;
	wire cheriot_lsu_we;
	wire [31:0] cheriot_lsu_addr;
	wire [31:0] cheriot_lsu_wdata;
	wire [34:0] cheriot_lsu_wcap;
	wire cheriot_lsu_err;
	wire cheriot_lsu_is_cap;
	wire [31:0] rf_rdata_a;
	reg [31:0] rf_rdata_ng_a;
	wire [31:0] rf_rdata_b;
	reg [31:0] rf_rdata_ng_b;
	wire [34:0] rf_rcap_a;
	reg [34:0] rf_rcap_ng_a;
	wire [34:0] rf_rcap_b;
	reg [34:0] rf_rcap_ng_b;
	wire [111:0] rf_fullcap_a;
	wire [111:0] rf_fullcap_b;
	reg [34:0] csc_wcap;
	wire is_load_cap;
	wire is_store_cap;
	wire is_cap;
	reg addr_bound_vio;
	reg perm_vio;
	reg perm_vio_slc;
	wire rv32_lsu_err;
	reg addr_bound_vio_rv32;
	reg perm_vio_rv32;
	localparam [31:0] ibex_cheriot_pkg_W_PVIO = 8;
	reg [7:0] perm_vio_vec;
	reg [7:0] perm_vio_vec_rv32;
	wire [31:0] cs1_addr_plusimm;
	wire [31:0] cs1_imm;
	reg [31:0] addr_result;
	reg cheriot_rf_we_raw;
	reg branch_req_raw;
	reg branch_req_spec_raw;
	reg csr_set_mie_raw;
	reg csr_clr_mie_raw;
	reg cheriot_ex_valid_raw;
	reg cheriot_ex_err_raw;
	reg csr_op_en_raw;
	reg cheriot_wb_err_raw;
	reg cheriot_wb_err_q;
	wire cheriot_wb_err_d;
	wire [2:0] cheriot_lsu_lc_clrperm;
	reg lc_cglg;
	reg lc_csdlm;
	reg lc_ctag;
	wire [31:0] pc_id_nxt;
	reg [111:0] setaddr1_outcap;
	reg [111:0] setbounds_outcap;
	reg [111:0] setbounds_rndn_outcap;
	reg [175:0] setbounds_result;
	reg [31:0] setbounds_maska;
	reg [31:0] setbounds_rlen;
	reg [15:0] cheriot_wb_err_info_q;
	reg [15:0] cheriot_wb_err_info_d;
	reg [4:0] cheriot_err_cause;
	reg [4:0] rv32_err_cause;
	wire [31:0] cpu_lsu_addr;
	wire [31:0] cpu_lsu_wdata;
	wire cpu_lsu_we;
	wire cpu_lsu_cheriot_err;
	wire cpu_lsu_is_cap;
	reg illegal_scr_addr;
	reg scr_legalization;
	reg [111:0] tfcap;
	reg [11:0] pmask;
	reg clr_sealed;
	reg instr_fault;
	reg is_write;
	reg is_ztop;
	reg [34:0] trcap;
	reg [2:0] seal_type;
	reg [31:0] tmp32a;
	reg [31:0] tmp32b;
	reg [111:0] tfcap1;
	reg [31:0] taddr1;
	reg [31:0] newlen;
	reg req_exact;
	reg [31:0] tmp_addr;
	reg [111:0] tfcap3;
	reg [31:0] rv32_top_offset;
	reg [32:0] rv32_top_bound;
	reg [31:0] rv32_base_bound;
	reg [31:0] rv32_base_chkaddr;
	reg rv32_top_vio;
	reg rv32_base_vio;
	reg [32:0] rv32_top_chkaddr;
	reg rv32_top_size_ok;
	reg [32:0] chk_top_bound;
	reg [31:0] chk_base_bound;
	reg [31:0] chk_base_chkaddr;
	reg [32:0] chk_top_chkaddr;
	reg chk_top_vio;
	reg chk_base_vio;
	reg chk_top_equal;
	reg chk_cs2_bad_type;
	reg chk_cs1_otype_0;
	reg chk_cs1_otype_1;
	reg chk_cs1_otype_45;
	reg chk_cs1_otype_23;
	always @(*) begin : fwd_data_merger
		if (_sv2v_0)
			;
		if (((rf_raddr_a_i == fwd_waddr_i) && fwd_we_i) && |rf_raddr_a_i) begin
			rf_rdata_ng_a = fwd_wdata_i;
			rf_rcap_ng_a = fwd_wcap_i;
		end
		else begin
			rf_rdata_ng_a = rf_rdata_a_i;
			rf_rcap_ng_a = rf_rcap_a_i;
		end
		if (((rf_raddr_b_i == fwd_waddr_i) && fwd_we_i) && |rf_raddr_b_i) begin
			rf_rdata_ng_b = fwd_wdata_i;
			rf_rcap_ng_b = fwd_wcap_i;
		end
		else begin
			rf_rdata_ng_b = rf_rdata_b_i;
			rf_rcap_ng_b = rf_rcap_b_i;
		end
	end
	function automatic [5:0] sv2v_cast_71AA1;
		input reg [5:0] inp;
		sv2v_cast_71AA1 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_877B8;
		input reg [2:0] inp;
		sv2v_cast_877B8 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_CFD5E;
		input reg [3:0] inp;
		sv2v_cast_CFD5E = inp;
	endfunction
	function automatic [8:0] sv2v_cast_B058B;
		input reg [8:0] inp;
		sv2v_cast_B058B = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_71AA1(1'sb0), sv2v_cast_877B8(1'sb0), sv2v_cast_CFD5E(1'sb0), sv2v_cast_B058B(1'sb0), sv2v_cast_B058B(1'sb0)};
	assign rf_rcap_a = (instr_is_cheriot_i | instr_is_rv32lsu_i ? rf_rcap_ng_a : ibex_cheriot_pkg_NULL_CAP);
	assign rf_rdata_a = (instr_is_cheriot_i | instr_is_rv32lsu_i ? rf_rdata_ng_a : 32'h00000000);
	assign rf_rcap_b = (instr_is_cheriot_i ? rf_rcap_ng_b : ibex_cheriot_pkg_NULL_CAP);
	assign rf_rdata_b = (instr_is_cheriot_i ? rf_rdata_ng_b : 32'h00000000);
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_expand_bound33;
		input reg [8:0] mant;
		input reg [1:0] cor;
		input reg [4:0] exp5;
		input reg [31:0] addr;
		reg [32:0] cor_val;
		reg [32:0] mask;
		reg [32:0] bound;
		reg [32:0] mant_ext;
		begin
			if (cor[1])
				cor_val = {33 {1'b1}};
			else
				cor_val = {32'h00000000, cor[0]};
			cor_val = (cor_val << exp5) << ibex_cheriot_pkg_CBOUND_W;
			mask = (33'h1ffffffff << exp5) << ibex_cheriot_pkg_CBOUND_W;
			bound = ({1'b0, addr} & mask) + cor_val;
			mant_ext = {24'h000000, mant};
			bound = bound | (mant_ext << exp5);
			ibex_cheriot_pkg_cheriot_expand_bound33 = bound;
		end
	endfunction
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	localparam [11:0] ibex_cheriot_pkg_PERM_EXE_IMSK = 12'h160;
	localparam [11:0] ibex_cheriot_pkg_PERM_MDO_IMSK = 12'h000;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRO_IMSK = 12'h060;
	localparam [11:0] ibex_cheriot_pkg_PERM_MRW_IMSK = 12'h064;
	localparam [11:0] ibex_cheriot_pkg_PERM_MWO_IMSK = 12'h044;
	localparam [11:0] ibex_cheriot_pkg_PERM_SEA_IMSK = 12'h000;
	function automatic [11:0] ibex_cheriot_pkg_cheriot_expand_perms;
		input reg [5:0] cperms;
		reg [11:0] perms;
		begin
			perms = 1'sb0;
			if (cperms[4:3] == 2'b11) begin
				perms = ibex_cheriot_pkg_PERM_MRW_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[4] = cperms[2];
			end
			else if (cperms[4:2] == 3'b101) begin
				perms = ibex_cheriot_pkg_PERM_MRO_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
			end
			else if (cperms[4:0] == 5'b10000)
				perms = ibex_cheriot_pkg_PERM_MWO_IMSK;
			else if (cperms[4:2] == 3'b100) begin
				perms = ibex_cheriot_pkg_PERM_MDO_IMSK;
				perms[2] = cperms[0];
				perms[5] = cperms[1];
			end
			else if (cperms[4:3] == 2'b01) begin
				perms = ibex_cheriot_pkg_PERM_EXE_IMSK;
				perms[1] = cperms[0];
				perms[3] = cperms[1];
				perms[7] = cperms[2];
			end
			else if (cperms[4:3] == 2'b00) begin
				perms = ibex_cheriot_pkg_PERM_SEA_IMSK;
				perms[9] = cperms[0];
				perms[10] = cperms[1];
				perms[11] = cperms[2];
			end
			perms[0] = cperms[5];
			ibex_cheriot_pkg_cheriot_expand_perms = perms;
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_base_correction;
		input reg [1:0] cap_cor;
		reg unused_top_cor_bit;
		begin
			unused_top_cor_bit = cap_cor[1];
			ibex_cheriot_pkg_cheriot_get_base_correction = {2 {cap_cor[0]}};
		end
	endfunction
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_top_correction;
		input reg [1:0] cap_cor;
		ibex_cheriot_pkg_cheriot_get_top_correction = {cap_cor[1] & cap_cor[0], cap_cor[1]};
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_decode_cap;
		input reg [34:0] cap;
		input reg [31:0] addr;
		reg [111:0] d;
		reg [4:0] exp5;
		begin
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			d[34-:2] = cap[34-:2];
			d[32] = cap[32];
			d[31] = cap[31];
			d[30-:6] = cap[30-:6];
			d[24-:3] = cap[24-:3];
			d[21-:4] = cap[21-:4];
			d[17-:9] = cap[17-:9];
			d[8-:ibex_cheriot_pkg_CBOUND_W] = cap[8-:ibex_cheriot_pkg_CBOUND_W];
			d[46-:12] = ibex_cheriot_pkg_cheriot_expand_perms(cap[30-:6]);
			d[111-:33] = ibex_cheriot_pkg_cheriot_expand_bound33(cap[17-:9], ibex_cheriot_pkg_cheriot_get_top_correction(cap[34-:2]), exp5, addr);
			d[78-:32] = sv2v_cast_32(ibex_cheriot_pkg_cheriot_expand_bound33(cap[8-:ibex_cheriot_pkg_CBOUND_W], ibex_cheriot_pkg_cheriot_get_base_correction(cap[34-:2]), exp5, addr));
			ibex_cheriot_pkg_cheriot_decode_cap = d;
		end
	endfunction
	assign rf_fullcap_a = ibex_cheriot_pkg_cheriot_decode_cap(rf_rcap_a, rf_rdata_a);
	assign rf_fullcap_b = ibex_cheriot_pkg_cheriot_decode_cap(rf_rcap_b, rf_rdata_b);
	assign cheriot_rf_we_o = cheriot_rf_we_raw & cheriot_exec_id_i;
	assign branch_req_o = branch_req_raw & cheriot_exec_id_i;
	assign branch_req_spec_o = branch_req_spec_raw & cheriot_exec_id_i;
	assign csr_set_mie_o = csr_set_mie_raw & cheriot_exec_id_i;
	assign csr_clr_mie_o = csr_clr_mie_raw & cheriot_exec_id_i;
	assign csr_op_en_o = csr_op_en_raw & cheriot_exec_id_i;
	assign cheriot_ex_valid_o = cheriot_ex_valid_raw & cheriot_exec_id_i;
	assign cheriot_ex_err_o = (cheriot_ex_err_raw & cheriot_exec_id_i) & ~debug_mode_i;
	generate
		if (WritebackStage) begin : gen_err_wb_stage
			assign cheriot_wb_err_o = cheriot_wb_err_q;
		end
		else begin : gen_err_no_wb_stage
			assign cheriot_wb_err_o = cheriot_wb_err_d;
		end
	endgenerate
	assign cheriot_lsu_lc_clrperm = (debug_mode_i ? {3 {1'sb0}} : {lc_ctag, lc_csdlm, lc_cglg});
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MEPCC = 5'h1f;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTCC = 5'h1c;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_ZTOPC = 5'h1b;
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD = 3'd4;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD = 3'd2;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD = 3'd5;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD = 3'd3;
	localparam [31:0] ibex_cheriot_pkg_PERMS_W = 12;
	function automatic [31:0] ibex_cheriot_pkg_cheriot_cap_length;
		input reg [111:0] full_cap;
		reg [32:0] tmp33;
		reg [31:0] result;
		reg [111:0] unused_full_cap;
		begin
			unused_full_cap = full_cap;
			tmp33 = full_cap[111-:33] - {1'b0, full_cap[78-:32]};
			result = (tmp33[32] ? 32'hffffffff : tmp33[31:0]);
			ibex_cheriot_pkg_cheriot_cap_length = result;
		end
	endfunction
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	function automatic [32:0] ibex_cheriot_pkg_cheriot_cap_to_mem;
		input reg [34:0] cap;
		reg [34:0] cap_bits;
		reg [1:0] unused_cap_corr;
		begin
			cap_bits = cap;
			unused_cap_corr = cap_bits[34:33];
			ibex_cheriot_pkg_cheriot_cap_to_mem = cap_bits[32:0];
		end
	endfunction
	function automatic ibex_cheriot_pkg_cheriot_caps_equal;
		input reg [111:0] cap_a;
		input reg [111:0] cap_b;
		input reg [31:0] addr_a;
		input reg [31:0] addr_b;
		reg [111:0] unused_cap_a;
		reg [111:0] unused_cap_b;
		begin
			unused_cap_a = cap_a;
			unused_cap_b = cap_b;
			ibex_cheriot_pkg_cheriot_caps_equal = (((((((cap_a[32] == cap_b[32]) && (cap_a[17-:9] == cap_b[17-:9])) && (cap_a[8-:ibex_cheriot_pkg_CBOUND_W] == cap_b[8-:ibex_cheriot_pkg_CBOUND_W])) && (cap_a[30-:6] == cap_b[30-:6])) && (cap_a[31] == cap_b[31])) && (cap_a[21-:4] == cap_b[21-:4])) && (cap_a[24-:3] == cap_b[24-:3])) && (addr_a == addr_b);
			ibex_cheriot_pkg_cheriot_caps_equal = ibex_cheriot_pkg_cheriot_caps_equal;
		end
	endfunction
	function automatic [11:0] sv2v_cast_D9A45;
		input reg [11:0] inp;
		sv2v_cast_D9A45 = inp;
	endfunction
	function automatic ibex_cheriot_pkg_cheriot_perms_covers;
		input reg [11:0] p;
		input reg [11:0] mask;
		ibex_cheriot_pkg_cheriot_perms_covers = &(sv2v_cast_D9A45(p) | ~sv2v_cast_D9A45(mask));
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_compress_perms;
		input reg [11:0] perms;
		reg [5:0] cperms;
		begin
			cperms = 1'sb0;
			cperms[5] = perms[0];
			if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_EXE_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[2] = perms[7];
				cperms[4:3] = 2'b01;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MRW_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[2] = perms[4];
				cperms[4:3] = 2'b11;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MRO_IMSK)) begin
				cperms[0] = perms[1];
				cperms[1] = perms[3];
				cperms[4:2] = 3'b101;
			end
			else if (ibex_cheriot_pkg_cheriot_perms_covers(perms, ibex_cheriot_pkg_PERM_MWO_IMSK))
				cperms[4:0] = 5'b10000;
			else if (perms[2] | perms[5]) begin
				cperms[0] = perms[2];
				cperms[1] = perms[5];
				cperms[4:2] = 3'b100;
			end
			else begin
				cperms[0] = perms[9];
				cperms[1] = perms[10];
				cperms[2] = perms[11];
				cperms[4:3] = 2'b00;
			end
			ibex_cheriot_pkg_cheriot_compress_perms = cperms;
		end
	endfunction
	function automatic [3:0] ibex_cheriot_pkg_cheriot_decode_otype;
		input reg [2:0] otype3;
		input reg perm_ex;
		reg [3:0] otype4;
		begin
			otype4 = {~perm_ex & (otype3 != 0), otype3};
			ibex_cheriot_pkg_cheriot_decode_otype = otype4;
		end
	endfunction
	function automatic [34:0] sv2v_cast_89126;
		input reg [34:0] inp;
		sv2v_cast_89126 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_encode_cap;
		input reg [111:0] d;
		reg [111:0] unused_d;
		begin
			unused_d = d;
			ibex_cheriot_pkg_cheriot_encode_cap = sv2v_cast_89126(d);
		end
	endfunction
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
	function automatic ibex_cheriot_pkg_cheriot_is_sealed;
		input reg [111:0] in_cap;
		reg result;
		reg [111:0] unused_in_cap;
		begin
			unused_in_cap = in_cap;
			result = in_cap[24-:3] != ibex_cheriot_pkg_OTYPE_UNSEALED;
			ibex_cheriot_pkg_cheriot_is_sealed = result;
		end
	endfunction
	localparam [31:0] ibex_cheriot_pkg_BASE_LO = 0;
	localparam [31:0] ibex_cheriot_pkg_TOP_LO = ibex_cheriot_pkg_BASE_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_CEXP_LO = ibex_cheriot_pkg_TOP_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_LO = ibex_cheriot_pkg_CEXP_LO + ibex_cheriot_pkg_CEXP_W;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_LO = ibex_cheriot_pkg_OTYPE_LO + ibex_cheriot_pkg_OTYPE_W;
	localparam [31:0] ibex_cheriot_pkg_RSVD_LO = ibex_cheriot_pkg_CPERMS_LO + ibex_cheriot_pkg_CPERMS_W;
	function automatic [1:0] ibex_cheriot_pkg_cheriot_compute_corrections;
		input reg [8:0] top;
		input reg [8:0] base;
		input reg [8:0] addr;
		reg top_hi;
		reg addr_hi;
		begin
			top_hi = top < base;
			addr_hi = addr < base;
			ibex_cheriot_pkg_cheriot_compute_corrections = {top_hi ^ addr_hi, addr_hi};
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_mask_loaded_cperms;
		input reg [5:0] cperms_in;
		input reg [2:0] clrperm;
		input reg valid_in;
		input reg sealed;
		reg [5:0] cperms_out;
		reg clr_gl;
		reg clr_lg;
		reg clr_sdlm;
		reg unused_ctag;
		begin
			unused_ctag = clrperm[2];
			clr_gl = clrperm[0] & valid_in;
			clr_lg = (clrperm[0] & valid_in) & ~sealed;
			clr_sdlm = (clrperm[1] & valid_in) & ~sealed;
			cperms_out = cperms_in;
			cperms_out[5] = cperms_in[5] & ~clr_gl;
			if (cperms_in[4:3] == 2'b11) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
				cperms_out[4:2] = (clr_sdlm ? 3'b101 : cperms_in[4:2]);
			end
			else if (cperms_in[4:2] == 3'b101) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			else if (cperms_in[4:0] == 5'b10000)
				cperms_out[4:0] = (clr_sdlm ? 5'h00 : cperms_in[4:0]);
			else if (cperms_in[4:2] == 3'b100) begin
				cperms_out[4] = ~(clr_sdlm & ~cperms_in[1]);
				cperms_out[0] = cperms_in[0] & ~clr_sdlm;
			end
			else if (cperms_in[4:3] == 2'b01) begin
				cperms_out[0] = cperms_in[0] & ~clr_lg;
				cperms_out[1] = cperms_in[1] & ~clr_sdlm;
			end
			ibex_cheriot_pkg_cheriot_mask_loaded_cperms = cperms_out;
		end
	endfunction
	function automatic [8:0] sv2v_cast_E4E4A;
		input reg [8:0] inp;
		sv2v_cast_E4E4A = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_mem_to_cap;
		input reg [32:0] cap_mw;
		input reg [32:0] addr33;
		input reg [2:0] clrperm;
		reg [34:0] cap;
		reg [4:0] exp5;
		reg [5:0] cperms_mem;
		reg [8:0] addrmi9;
		reg sealed;
		reg valid_in;
		begin
			valid_in = cap_mw[32] & addr33[32];
			cap[32] = valid_in & ~clrperm[2];
			cap[8-:ibex_cheriot_pkg_CBOUND_W] = cap_mw[ibex_cheriot_pkg_BASE_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[17-:9] = cap_mw[ibex_cheriot_pkg_TOP_LO+:ibex_cheriot_pkg_CBOUND_W];
			cap[21-:4] = cap_mw[ibex_cheriot_pkg_CEXP_LO+:ibex_cheriot_pkg_CEXP_W];
			cap[24-:3] = cap_mw[ibex_cheriot_pkg_OTYPE_LO+:ibex_cheriot_pkg_OTYPE_W];
			sealed = cap[24-:3] != ibex_cheriot_pkg_OTYPE_UNSEALED;
			cperms_mem = cap_mw[ibex_cheriot_pkg_CPERMS_LO+:ibex_cheriot_pkg_CPERMS_W];
			cap[30-:6] = ibex_cheriot_pkg_cheriot_mask_loaded_cperms(cperms_mem, clrperm, cap[32], sealed);
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(cap[21-:4]);
			addrmi9 = sv2v_cast_E4E4A(addr33[31:0] >> exp5);
			cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(cap[17-:9], cap[8-:ibex_cheriot_pkg_CBOUND_W], addrmi9);
			cap[31] = cap_mw[ibex_cheriot_pkg_RSVD_LO];
			ibex_cheriot_pkg_cheriot_mem_to_cap = cap;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_seal;
		input reg [111:0] in_cap;
		input reg [2:0] new_otype;
		reg [111:0] out_cap;
		begin
			out_cap = in_cap;
			out_cap[24-:3] = new_otype;
			ibex_cheriot_pkg_cheriot_seal = out_cap;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_unseal;
		input reg [111:0] in_cap;
		reg [111:0] out_cap;
		begin
			out_cap = in_cap;
			out_cap[24-:3] = ibex_cheriot_pkg_OTYPE_UNSEALED;
			ibex_cheriot_pkg_cheriot_unseal = out_cap;
		end
	endfunction
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	always @(*) begin : main_ex
		if (_sv2v_0)
			;
		cheriot_rf_we_raw = 1'b0;
		result_data_o = 32'h00000000;
		result_cap_o = ibex_cheriot_pkg_NULL_CAP;
		csc_wcap = ibex_cheriot_pkg_NULL_CAP;
		cheriot_ex_valid_raw = 1'b0;
		cheriot_ex_err_raw = 1'b0;
		cheriot_wb_err_raw = 1'b0;
		csr_access_o = 1'b0;
		csr_addr_o = 5'h00;
		csr_wdata_o = 32'h00000000;
		csr_wcap_o = ibex_cheriot_pkg_NULL_CAP;
		csr_op_o = 5'd0;
		csr_op_en_raw = 1'b0;
		scr_legalization = 1'b0;
		branch_req_raw = 1'b0;
		branch_req_spec_raw = 1'b0;
		csr_set_mie_raw = 1'b0;
		csr_clr_mie_raw = 1'b0;
		branch_target_o = 32'h00000000;
		pcc_cap_o = ibex_cheriot_pkg_NULL_DECODED_CAP;
		tfcap = ibex_cheriot_pkg_NULL_DECODED_CAP;
		lc_cglg = 1'b0;
		lc_csdlm = 1'b0;
		lc_ctag = 1'b0;
		(* full_case, parallel_case *)
		case (1'b1)
			cheriot_operator_i[0]: begin
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
				(* full_case, parallel_case *)
				case (cheriot_cap_field_sel_i)
					3'h0: result_data_o = {20'h00000, rf_fullcap_a[46-:12]};
					3'h1: result_data_o = {28'h0000000, ibex_cheriot_pkg_cheriot_decode_otype(rf_fullcap_a[24-:3], rf_fullcap_a[43])};
					3'h2: result_data_o = rf_fullcap_a[78-:32];
					3'h7: result_data_o = (rf_fullcap_a[111] ? 32'hffffffff : rf_fullcap_a[110:79]);
					3'h3: result_data_o = ibex_cheriot_pkg_cheriot_cap_length(rf_fullcap_a);
					3'h4: result_data_o = {31'h00000000, rf_fullcap_a[32]};
					3'h5: result_data_o = rf_rdata_a;
					3'h6: result_data_o = sv2v_cast_32(ibex_cheriot_pkg_cheriot_cap_to_mem(rf_rcap_a));
					default: result_data_o = 32'h00000000;
				endcase
			end
			cheriot_operator_i[1] | cheriot_operator_i[2]: begin
				result_data_o = rf_rdata_a;
				if (cheriot_operator_i[1])
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(ibex_cheriot_pkg_cheriot_seal(rf_fullcap_a, rf_rdata_b[2:0]));
				else begin
					tfcap = ibex_cheriot_pkg_cheriot_unseal(rf_fullcap_a);
					tfcap[35] = rf_fullcap_a[35] & rf_fullcap_b[35];
					tfcap[30-:6] = ibex_cheriot_pkg_cheriot_compress_perms(tfcap[46-:12]);
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				end
				result_cap_o[32] = (result_cap_o[32] & ~addr_bound_vio) & ~perm_vio;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[3]: begin
				result_data_o = rf_rdata_a;
				tfcap = rf_fullcap_a;
				tfcap[46-:12] = sv2v_cast_12(sv2v_cast_D9A45(tfcap[46-:12]) & rf_rdata_b[11:0]);
				tfcap[30-:6] = ibex_cheriot_pkg_cheriot_compress_perms(tfcap[46-:12]);
				pmask = sv2v_cast_12(rf_rdata_b[11:0]);
				pmask[0] = 1'b1;
				tfcap[32] = tfcap[32] & (~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) | &sv2v_cast_D9A45(pmask));
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[16]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = ibex_cheriot_pkg_cheriot_mem_to_cap({1'b0, rf_rdata_b}, {1'b0, rf_rdata_a}, 3'h0);
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			(((cheriot_operator_i[4] | cheriot_operator_i[5]) | cheriot_operator_i[6]) | cheriot_operator_i[21]) | cheriot_operator_i[22]: begin
				result_data_o = addr_result;
				clr_sealed = (cheriot_setaddr_sel_i == 3'h2 ? 1'b0 : ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a));
				tfcap = setaddr1_outcap;
				tfcap[32] = tfcap[32] & ~clr_sealed;
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				instr_fault = (csr_dbg_tclr_fault_i & (rf_fullcap_a[32] | (cheriot_setaddr_sel_i == 3'h2))) & ~result_cap_o[32];
				cheriot_wb_err_raw = instr_fault;
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_ex_valid_raw = 1'b1;
			end
			((((cheriot_operator_i[7] | cheriot_operator_i[9]) | cheriot_operator_i[8]) | cheriot_operator_i[23]) | cheriot_operator_i[24]) | cheriot_operator_i[25]: begin
				tfcap = (cheriot_setbounds_sel_i == 3'h2 ? setbounds_rndn_outcap : setbounds_outcap);
				tfcap[32] = tfcap[32] & ~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
				if (cheriot_setbounds_sel_i == 3'h5) begin
					result_data_o = setbounds_rlen;
					result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				end
				else if (cheriot_setbounds_sel_i == 3'h6) begin
					result_data_o = setbounds_maska;
					result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				end
				else begin
					result_data_o = rf_rdata_a;
					result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				end
				cheriot_ex_valid_raw = 1'b1;
				instr_fault = ((csr_dbg_tclr_fault_i & rf_fullcap_a[32]) & ~result_cap_o[32]) & ((((cheriot_setbounds_sel_i == 3'h1) || (cheriot_setbounds_sel_i == 3'h3)) || (cheriot_setbounds_sel_i == 3'h4)) || (cheriot_setbounds_sel_i == 3'h2));
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_wb_err_raw = instr_fault;
			end
			cheriot_operator_i[14]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = rf_rcap_a;
				result_cap_o[32] = 1'b0;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[10]: begin
				result_data_o = sv2v_cast_32(((rf_fullcap_a[32] == rf_fullcap_b[32]) && ~addr_bound_vio) && &(rf_fullcap_a[46-:12] | ~rf_fullcap_b[46-:12]));
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[11]: begin
				result_data_o = sv2v_cast_32(ibex_cheriot_pkg_cheriot_caps_equal(rf_fullcap_a, rf_fullcap_b, rf_rdata_a, rf_rdata_b));
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[13]: begin
				result_data_o = rf_rdata_a - rf_rdata_b;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[12]: begin
				result_data_o = rf_rdata_a;
				result_cap_o = rf_rcap_a;
				cheriot_rf_we_raw = 1'b1;
				cheriot_ex_valid_raw = 1'b1;
			end
			cheriot_operator_i[15]: begin
				lc_cglg = ~rf_fullcap_a[36];
				lc_csdlm = ~rf_fullcap_a[38];
				lc_ctag = ~rf_fullcap_a[41];
				result_data_o = 32'h00000000;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b0;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_ex_err_raw = 1'b0;
			end
			cheriot_operator_i[17]: begin
				result_data_o = 32'h00000000;
				result_cap_o = ibex_cheriot_pkg_NULL_CAP;
				cheriot_rf_we_raw = 1'b0;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_ex_err_raw = 1'b0;
				csc_wcap = rf_rcap_b;
				csc_wcap[32] = rf_rcap_b[32] & ~perm_vio_slc;
			end
			cheriot_operator_i[18]: begin
				is_ztop = cheriot_cs2_dec_i == ibex_cheriot_pkg_CHERIOT_SCR_ZTOPC;
				is_write = rf_raddr_a_i != 0;
				instr_fault = perm_vio | illegal_scr_addr;
				csr_access_o = ~instr_fault;
				csr_op_o = 5'd1;
				csr_op_en_raw = (~instr_fault && is_write) && ~is_ztop;
				csr_addr_o = cheriot_cs2_dec_i;
				if (cheriot_cs2_dec_i == ibex_cheriot_pkg_CHERIOT_SCR_MTCC) begin
					scr_legalization = 1'b1;
					csr_wdata_o = {rf_rdata_a[31:2], 2'b00};
					trcap = ibex_cheriot_pkg_cheriot_encode_cap(setaddr1_outcap);
					if (((rf_rdata_a[1:0] != 2'b00) || ~rf_fullcap_a[43]) || (rf_fullcap_a[24-:3] != 0))
						trcap[32] = 1'b0;
					else
						trcap[32] = rf_fullcap_a[32];
					csr_wcap_o = trcap;
				end
				else if (cheriot_cs2_dec_i == ibex_cheriot_pkg_CHERIOT_SCR_MEPCC) begin
					scr_legalization = 1'b1;
					csr_wdata_o = {rf_rdata_a[31:1], 1'b0};
					trcap = ibex_cheriot_pkg_cheriot_encode_cap(setaddr1_outcap);
					if (((rf_rdata_a[0] != 1'b0) || ~rf_fullcap_a[43]) || (rf_fullcap_a[24-:3] != 0))
						trcap[32] = 1'b0;
					else
						trcap[32] = rf_fullcap_a[32];
					csr_wcap_o = trcap;
				end
				else begin
					scr_legalization = 1'b0;
					csr_wdata_o = rf_rdata_a;
					csr_wcap_o = rf_rcap_a;
				end
				if (is_ztop) begin
					result_data_o = ztop_rdata_i;
					result_cap_o = ztop_rcap_i;
				end
				else begin
					result_data_o = csr_rdata_i;
					result_cap_o = csr_rcap_i;
				end
				cheriot_rf_we_raw = ~instr_fault;
				cheriot_ex_valid_raw = 1'b1;
				cheriot_wb_err_raw = instr_fault;
			end
			cheriot_operator_i[19] | cheriot_operator_i[20]: begin
				branch_target_o = {addr_result[31:1], 1'b0};
				pcc_cap_o = ibex_cheriot_pkg_cheriot_unseal(rf_fullcap_a);
				result_data_o = pc_id_nxt;
				seal_type = (csr_mstatus_mie_i ? ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD : ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD);
				tfcap = (rf_waddr_i == 5'h01 ? ibex_cheriot_pkg_cheriot_seal(setaddr1_outcap, seal_type) : setaddr1_outcap);
				result_cap_o = ibex_cheriot_pkg_cheriot_encode_cap(tfcap);
				instr_fault = perm_vio;
				cheriot_rf_we_raw = ~instr_fault;
				branch_req_raw = ~instr_fault & cheriot_operator_i[19];
				branch_req_spec_raw = ~instr_fault;
				cheriot_wb_err_raw = instr_fault;
				cheriot_ex_err_raw = 1'b0;
				csr_set_mie_raw = (~instr_fault && cheriot_operator_i[19]) && ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD));
				csr_clr_mie_raw = (~instr_fault && cheriot_operator_i[19]) && ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD));
				cheriot_ex_valid_raw = 1'b1;
			end
			default:
				;
		endcase
	end
	assign is_load_cap = cheriot_operator_i[15];
	assign is_store_cap = cheriot_operator_i[17];
	assign is_cap = cheriot_operator_i[15] | cheriot_operator_i[17];
	generate
		if (WritebackStage) begin : gen_lsu_req_wb_stage
			wire unused_instr_first_cycle;
			assign unused_instr_first_cycle = instr_first_cycle_i;
			assign cheriot_lsu_req = is_cap & cheriot_exec_id_i;
		end
		else begin : gen_lsu_req_no_wb_stage
			assign cheriot_lsu_req = (is_cap & cheriot_exec_id_i) & instr_first_cycle_i;
		end
	endgenerate
	assign cheriot_lsu_we = is_store_cap;
	assign cheriot_lsu_addr = cs1_addr_plusimm + {29'h00000000, addr_incr_req_i, 2'b00};
	assign cheriot_lsu_is_cap = is_cap;
	assign cheriot_lsu_wdata = (is_store_cap ? rf_rdata_b : 32'h00000000);
	assign cheriot_lsu_wcap = (is_store_cap ? csc_wcap : ibex_cheriot_pkg_NULL_CAP);
	assign cs1_imm = (is_cap | cheriot_operator_i[19] ? {{20 {cheriot_imm12_i[11]}}, cheriot_imm12_i} : {32 {1'sb0}});
	assign cs1_addr_plusimm = rf_rdata_a + cs1_imm;
	assign pc_id_nxt = pc_id_i + (instr_is_compressed_i ? 32'd2 : 32'd4);
	always @(*) begin : shared_adder
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (cheriot_adder_a_sel_i)
			3'h1: tmp32a = {{20 {cheriot_imm12_i[11]}}, cheriot_imm12_i};
			3'h2: tmp32a = {{11 {cheriot_imm21_i[20]}}, cheriot_imm21_i};
			3'h3: tmp32a = {cheriot_imm20_i[19], cheriot_imm20_i, 11'h000};
			3'h4: tmp32a = rf_rdata_b;
			default: tmp32a = 32'h00000000;
		endcase
		(* full_case, parallel_case *)
		case (cheriot_adder_b_sel_i)
			2'h1: tmp32b = rf_rdata_a;
			2'h2: tmp32b = pc_id_i;
			default: tmp32b = 32'h00000000;
		endcase
		addr_result = tmp32a + tmp32b;
	end
	function automatic [111:0] ibex_cheriot_pkg_cheriot_set_address;
		input reg [111:0] in_cap;
		input reg [31:0] newptr;
		reg [111:0] out_cap;
		reg [4:0] exp5;
		reg [32:0] ptr_minus_base;
		reg [8:0] unused_ptr_minus_base;
		reg [23:0] high_delta;
		reg [23:0] repr_mask;
		reg [8:0] ptr_mantissa;
		begin
			out_cap = in_cap;
			exp5 = ibex_cheriot_pkg_cheriot_expand_exp(in_cap[21-:4]);
			repr_mask = {24 {1'b1}} << exp5;
			ptr_minus_base = {1'b0, newptr} - {1'b0, in_cap[78-:32]};
			unused_ptr_minus_base = ptr_minus_base[8:0];
			high_delta = ptr_minus_base[32:ibex_cheriot_pkg_CBOUND_W] & repr_mask;
			if (high_delta != 0)
				out_cap[32] = 1'b0;
			ptr_mantissa = sv2v_cast_E4E4A(newptr >> exp5);
			out_cap[34-:2] = ibex_cheriot_pkg_cheriot_compute_corrections(out_cap[17-:9], out_cap[8-:ibex_cheriot_pkg_CBOUND_W], ptr_mantissa);
			ibex_cheriot_pkg_cheriot_set_address = out_cap;
		end
	endfunction
	always @(*) begin : set_address_comb
		if (_sv2v_0)
			;
		if (cheriot_setaddr_sel_i == 3'h1) begin
			tfcap1 = pcc_cap_i;
			taddr1 = pc_id_nxt;
		end
		else if (cheriot_setaddr_sel_i == 3'h2) begin
			tfcap1 = pcc_cap_i;
			taddr1 = addr_result;
		end
		else if (cheriot_setaddr_sel_i == 3'h3) begin
			tfcap1 = rf_fullcap_a;
			taddr1 = addr_result;
		end
		else if ((cheriot_setaddr_sel_i == 3'h4) && scr_legalization) begin
			tfcap1 = rf_fullcap_a;
			taddr1 = csr_wdata_o;
		end
		else begin
			tfcap1 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			taddr1 = 32'h00000000;
		end
		setaddr1_outcap = ibex_cheriot_pkg_cheriot_set_address(tfcap1, taddr1);
	end
	reg [55:0] bound_req;
	function automatic [5:0] ibex_cheriot_pkg_cheriot_thermometer_count;
		input reg [31:0] a32;
		reg [5:0] count;
		reg [15:0] b32;
		begin
			if (a32[31])
				count = 6'd32;
			else begin
				count[5] = 1'b0;
				count[4] = a32[15];
				b32[15:0] = (count[4] ? a32[31:16] : a32[15:0]);
				count[3] = b32[7];
				b32[7:0] = (count[3] ? b32[15:8] : b32[7:0]);
				count[2] = b32[3];
				b32[3:0] = (count[2] ? b32[7:4] : b32[3:0]);
				count[1] = b32[1];
				b32[1:0] = (count[1] ? b32[3:2] : b32[1:0]);
				count[0] = b32[0];
			end
			ibex_cheriot_pkg_cheriot_thermometer_count = count;
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_count_trailing_zeros;
		input reg [31:0] din;
		reg [5:0] count;
		reg [31:0] a32;
		reg signed [31:0] i;
		begin
			a32 = {31'h00000000, din[0]};
			for (i = 1; i < 32; i = i + 1)
				a32[i] = a32[i - 1] | din[i];
			count = ibex_cheriot_pkg_cheriot_thermometer_count(~a32);
			ibex_cheriot_pkg_cheriot_count_trailing_zeros = count;
		end
	endfunction
	function automatic [5:0] ibex_cheriot_pkg_cheriot_msb_position;
		input reg [31:0] din;
		reg [5:0] count;
		reg [31:0] a32;
		reg signed [31:0] i;
		begin
			a32 = {din[31], 31'h00000000};
			for (i = 30; i >= 0; i = i - 1)
				a32[i] = a32[i + 1] | din[i];
			count = ibex_cheriot_pkg_cheriot_thermometer_count(a32);
			ibex_cheriot_pkg_cheriot_msb_position = count;
		end
	endfunction
	function automatic [5:0] sv2v_cast_6;
		input reg [5:0] inp;
		sv2v_cast_6 = inp;
	endfunction
	function automatic [4:0] sv2v_cast_66B73;
		input reg [4:0] inp;
		sv2v_cast_66B73 = inp;
	endfunction
	function automatic [55:0] ibex_cheriot_pkg_cheriot_prep_bounds;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [31:0] length;
		reg [55:0] result;
		reg [5:0] size_result;
		reg [111:0] unused_in_cap;
		begin
			unused_in_cap = in_cap;
			result[55-:33] = {1'b0, addr} + {1'b0, length};
			result[6-:6] = ibex_cheriot_pkg_cheriot_count_trailing_zeros(addr);
			result[12-:6] = ibex_cheriot_pkg_cheriot_msb_position({9'h000, length[31:9]});
			size_result = result[12-:6];
			result[22-:5] = (size_result >= sv2v_cast_6(ibex_cheriot_pkg_MAXCEXP) ? sv2v_cast_66B73(ibex_cheriot_pkg_MAXEXP) : sv2v_cast_66B73(size_result));
			size_result = size_result + 6'd1;
			result[17-:5] = (size_result >= sv2v_cast_6(ibex_cheriot_pkg_MAXCEXP) ? sv2v_cast_66B73(ibex_cheriot_pkg_MAXEXP) : sv2v_cast_66B73(size_result));
			result[0] = ~((result[55-:33] > in_cap[111-:33]) || (addr < in_cap[78-:32]));
			ibex_cheriot_pkg_cheriot_prep_bounds = result;
		end
	endfunction
	function automatic [3:0] ibex_cheriot_pkg_cheriot_compress_exp;
		input reg [4:0] exp5;
		ibex_cheriot_pkg_cheriot_compress_exp = (exp5 == ibex_cheriot_pkg_MAXEXP ? ibex_cheriot_pkg_MAXCEXP : exp5[3:0]);
	endfunction
	function automatic [9:0] sv2v_cast_A2DBE;
		input reg [9:0] inp;
		sv2v_cast_A2DBE = inp;
	endfunction
	function automatic [175:0] ibex_cheriot_pkg_cheriot_set_bounds_ex;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [55:0] bound_req;
		input reg req_exact;
		reg [175:0] result;
		reg [111:0] out_cap;
		reg [55:0] unused_bound_req;
		reg [4:0] exp1;
		reg [4:0] exp2;
		reg [4:0] exp_sel;
		reg [32:0] top33req;
		reg [ibex_cheriot_pkg_CBOUND_W:0] base1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] base2;
		reg [ibex_cheriot_pkg_CBOUND_W:0] top1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] top2;
		reg [ibex_cheriot_pkg_CBOUND_W:0] len1;
		reg [ibex_cheriot_pkg_CBOUND_W:0] len2;
		reg [32:0] mask1;
		reg [32:0] mask2;
		reg ovrflw;
		reg topoff1;
		reg topoff2;
		reg topoff;
		reg baseoff1;
		reg baseoff2;
		reg baseoff;
		reg tophi1;
		reg tophi2;
		reg tophi;
		reg in_bound;
		begin
			unused_bound_req = bound_req;
			out_cap = in_cap;
			top33req = bound_req[55-:33];
			exp1 = bound_req[22-:5];
			exp2 = bound_req[17-:5];
			in_bound = bound_req[0];
			mask1 = {33 {1'b1}} << exp1;
			base1 = sv2v_cast_A2DBE(addr >> exp1);
			topoff1 = |(top33req & ~mask1);
			baseoff1 = |({1'b0, addr} & ~mask1);
			top1 = sv2v_cast_A2DBE(top33req >> exp1) + sv2v_cast_A2DBE(topoff1);
			len1 = top1 - base1;
			tophi1 = top1[8:0] >= base1[8:0];
			ovrflw = len1[9];
			mask2 = {33 {1'b1}} << exp2;
			base2 = sv2v_cast_A2DBE(addr >> exp2);
			topoff2 = |(top33req & ~mask2);
			baseoff2 = |({1'b0, addr} & ~mask2);
			top2 = sv2v_cast_A2DBE(top33req >> exp2) + sv2v_cast_A2DBE(topoff2);
			len2 = top2 - base2;
			tophi2 = top2[8:0] >= base2[8:0];
			if (~ovrflw) begin
				exp_sel = exp1;
				out_cap[17-:9] = top1[8:0];
				out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = base1[8:0];
				result[63-:32] = mask1[31:0];
				result[31-:32] = {22'h000000, len1} << exp1;
				topoff = topoff1;
				baseoff = baseoff1;
				tophi = tophi1;
			end
			else begin
				exp_sel = exp2;
				out_cap[17-:9] = top2[8:0];
				out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = base2[8:0];
				result[63-:32] = mask2[31:0];
				result[31-:32] = {22'h000000, len2} << exp2;
				topoff = topoff2;
				baseoff = baseoff2;
				tophi = tophi2;
			end
			out_cap[21-:4] = ibex_cheriot_pkg_cheriot_compress_exp(exp_sel);
			out_cap[34-:2] = (tophi ? 2'b00 : 2'b10);
			if (req_exact & (topoff | baseoff))
				out_cap[32] = 1'b0;
			if (~in_bound)
				out_cap[32] = 1'b0;
			result[175-:112] = out_cap;
			ibex_cheriot_pkg_cheriot_set_bounds_ex = result;
		end
	endfunction
	function automatic [111:0] ibex_cheriot_pkg_cheriot_set_bounds_rounddown;
		input reg [111:0] in_cap;
		input reg [31:0] addr;
		input reg [55:0] bound_req;
		reg [111:0] out_cap;
		reg [55:0] unused_bound_req;
		reg [ibex_cheriot_pkg_EXP_W:0] explen;
		reg [ibex_cheriot_pkg_EXP_W:0] expb;
		reg [ibex_cheriot_pkg_EXP_W:0] exp_final;
		reg [32:0] top33req;
		reg in_bound;
		reg el_gt_eb;
		reg el_gt_14;
		reg eb_gt_14;
		reg tophi;
		begin
			unused_bound_req = bound_req;
			out_cap = in_cap;
			top33req = bound_req[55-:33];
			explen = bound_req[12-:6];
			expb = bound_req[6-:6];
			in_bound = bound_req[0];
			el_gt_eb = explen > expb;
			el_gt_14 = explen > 14;
			eb_gt_14 = expb > 14;
			exp_final = (el_gt_eb & !eb_gt_14 ? expb : (el_gt_14 ? 6'd14 : explen));
			out_cap[21-:4] = ibex_cheriot_pkg_cheriot_compress_exp(exp_final[4:0]);
			out_cap[8-:ibex_cheriot_pkg_CBOUND_W] = sv2v_cast_E4E4A(addr >> exp_final);
			out_cap[17-:9] = (el_gt_eb | el_gt_14 ? out_cap[8-:ibex_cheriot_pkg_CBOUND_W] - sv2v_cast_E4E4A(1'b1) : sv2v_cast_E4E4A(top33req >> exp_final));
			if (~in_bound)
				out_cap[32] = 1'b0;
			tophi = out_cap[17-:9] >= out_cap[8-:ibex_cheriot_pkg_CBOUND_W];
			out_cap[34-:2] = (tophi ? 2'b00 : 2'b10);
			ibex_cheriot_pkg_cheriot_set_bounds_rounddown = out_cap;
		end
	endfunction
	always @(*) begin : set_bounds_comb
		if (_sv2v_0)
			;
		if ((cheriot_setbounds_sel_i == 3'h5) || (cheriot_setbounds_sel_i == 3'h6)) begin
			newlen = rf_rdata_a;
			req_exact = 1'b0;
			tfcap3 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			tmp_addr = 32'h00000000;
		end
		else if (cheriot_setbounds_sel_i == 3'h4) begin
			newlen = sv2v_cast_32(cheriot_imm12_i);
			req_exact = 1'b0;
			tfcap3 = rf_fullcap_a;
			tmp_addr = rf_rdata_a;
		end
		else if (cheriot_setbounds_sel_i != 3'h0) begin
			newlen = rf_rdata_b;
			req_exact = cheriot_setbounds_sel_i == 3'h3;
			tfcap3 = rf_fullcap_a;
			tmp_addr = rf_rdata_a;
		end
		else begin
			newlen = 32'h00000000;
			req_exact = 1'b0;
			tfcap3 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			tmp_addr = 32'h00000000;
		end
		bound_req = ibex_cheriot_pkg_cheriot_prep_bounds(tfcap3, tmp_addr, newlen);
		setbounds_result = ibex_cheriot_pkg_cheriot_set_bounds_ex(tfcap3, tmp_addr, bound_req, req_exact);
		setbounds_outcap = setbounds_result[175-:112];
		setbounds_maska = setbounds_result[63-:32];
		setbounds_rlen = setbounds_result[31-:32];
		setbounds_rndn_outcap = ibex_cheriot_pkg_cheriot_set_bounds_rounddown(tfcap3, tmp_addr, bound_req);
	end
	wire [31:0] rv32_ls_chkaddr;
	assign rv32_ls_chkaddr = rv32_lsu_addr_i;
	localparam [2:0] ibex_cheriot_pkg_PVIO_LD = 3'h3;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SD = 3'h4;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SEAL = 3'h1;
	localparam [2:0] ibex_cheriot_pkg_PVIO_TAG = 3'h0;
	always @(*) begin : check_rv32
		if (_sv2v_0)
			;
		rv32_base_chkaddr = rv32_ls_chkaddr;
		if (rv32_lsu_type_i == 2'b00) begin
			rv32_top_offset = 32'h00000004;
			rv32_top_size_ok = |rf_fullcap_a[111:81];
		end
		else if (rv32_lsu_type_i == 2'b01) begin
			rv32_top_offset = 32'h00000002;
			rv32_top_size_ok = |rf_fullcap_a[111:80];
		end
		else begin
			rv32_top_offset = 32'h00000001;
			rv32_top_size_ok = |rf_fullcap_a[111:79];
		end
		rv32_top_chkaddr = {1'b0, rv32_base_chkaddr};
		rv32_top_bound = rf_fullcap_a[111-:33] - {1'b0, rv32_top_offset};
		rv32_base_bound = rf_fullcap_a[78-:32];
		rv32_top_vio = (rv32_top_chkaddr > rv32_top_bound) || ~rv32_top_size_ok;
		rv32_base_vio = rv32_base_chkaddr < rv32_base_bound;
		addr_bound_vio_rv32 = (rv32_top_vio | rv32_base_vio) & ~addr_incr_req_i;
		perm_vio_vec_rv32 = 1'sb0;
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_LD] = ~rv32_lsu_we_i && ~rf_fullcap_a[40];
		perm_vio_vec_rv32[ibex_cheriot_pkg_PVIO_SD] = rv32_lsu_we_i && ~rf_fullcap_a[37];
		perm_vio_rv32 = |perm_vio_vec_rv32;
	end
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign rv32_lsu_err = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~debug_mode_i) & (addr_bound_vio_rv32 | perm_vio_rv32);
	wire [31:0] cheriot_ls_chkaddr;
	assign cheriot_ls_chkaddr = cs1_addr_plusimm;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_SENTRY_II_FWD = 3'd1;
	localparam [2:0] ibex_cheriot_pkg_PVIO_ALIGN = 3'h7;
	localparam [2:0] ibex_cheriot_pkg_PVIO_ASR = 3'h6;
	localparam [2:0] ibex_cheriot_pkg_PVIO_EX = 3'h2;
	localparam [2:0] ibex_cheriot_pkg_PVIO_SC = 3'h5;
	always @(*) begin : check_cheriot
		if (_sv2v_0)
			;
		if (cheriot_operator_i[1])
			chk_base_chkaddr = rf_rdata_b;
		else if (cheriot_operator_i[2])
			chk_base_chkaddr = {28'h0000000, ibex_cheriot_pkg_cheriot_decode_otype(rf_fullcap_a[24-:3], rf_fullcap_a[43])};
		else if (cheriot_operator_i[10])
			chk_base_chkaddr = rf_fullcap_b[78-:32];
		else
			chk_base_chkaddr = cheriot_ls_chkaddr;
		if (cheriot_operator_i[10])
			chk_top_chkaddr = rf_fullcap_b[111-:33];
		else if (is_cap)
			chk_top_chkaddr = {1'b0, chk_base_chkaddr[31:3], 3'b000};
		else
			chk_top_chkaddr = {1'b0, chk_base_chkaddr};
		if (cheriot_operator_i[1] | cheriot_operator_i[2]) begin
			chk_top_bound = rf_fullcap_b[111-:33];
			chk_base_bound = rf_fullcap_b[78-:32];
		end
		else if (is_cap) begin
			chk_top_bound = {rf_fullcap_a[111:82], 3'b000};
			chk_base_bound = rf_fullcap_a[78-:32];
		end
		else begin
			chk_top_bound = rf_fullcap_a[111-:33];
			chk_base_bound = rf_fullcap_a[78-:32];
		end
		chk_top_vio = chk_top_chkaddr > chk_top_bound;
		chk_base_vio = chk_base_chkaddr < chk_base_bound;
		chk_top_equal = chk_top_chkaddr == chk_top_bound;
		if (debug_mode_i)
			addr_bound_vio = 1'b0;
		else if (is_cap)
			addr_bound_vio = (chk_top_vio | chk_base_vio) | chk_top_equal;
		else if (cheriot_operator_i[10])
			addr_bound_vio = chk_top_vio | chk_base_vio;
		else if (cheriot_operator_i[1] | cheriot_operator_i[2])
			addr_bound_vio = (chk_top_vio | chk_base_vio) | chk_top_equal;
		else
			addr_bound_vio = 1'b0;
		perm_vio_vec = 1'sb0;
		perm_vio = 0;
		perm_vio_slc = 0;
		chk_cs2_bad_type = 1'b0;
		illegal_scr_addr = 1'b0;
		chk_cs1_otype_0 = rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_UNSEALED;
		chk_cs1_otype_1 = rf_fullcap_a[43] & (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_II_FWD);
		chk_cs1_otype_23 = rf_fullcap_a[43] & ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_FWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_FWD));
		chk_cs1_otype_45 = rf_fullcap_a[43] & ((rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_ID_BKWD) || (rf_fullcap_a[24-:3] == ibex_cheriot_pkg_OTYPE_SENTRY_IE_BKWD));
		if (is_load_cap) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
			perm_vio_vec[ibex_cheriot_pkg_PVIO_LD] = ~rf_fullcap_a[40];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] = cheriot_ls_chkaddr[2:0] != 0;
		end
		else if (is_store_cap) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a);
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SD] = ~rf_fullcap_a[37];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SC] = ~rf_fullcap_a[41] && rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] = cheriot_ls_chkaddr[2:0] != 0;
			perm_vio_slc = (~rf_fullcap_a[39] && rf_fullcap_b[32]) && ~rf_fullcap_b[35];
		end
		else if (cheriot_operator_i[1]) begin
			chk_cs2_bad_type = (rf_fullcap_a[43] ? (rf_rdata_b[31:3] != 0) || (rf_rdata_b[2:0] == 0) : |rf_rdata_b[31:4] || (rf_rdata_b[3:0] <= 8));
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = ((ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) || ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_b)) || ~rf_fullcap_b[45]) || chk_cs2_bad_type;
		end
		else if (cheriot_operator_i[2]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_b[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = (~ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) || ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_b)) || ~rf_fullcap_b[44];
		end
		else if (cheriot_operator_i[19]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG] = ~rf_fullcap_a[32];
			perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL] = (ibex_cheriot_pkg_cheriot_is_sealed(rf_fullcap_a) && (cheriot_imm12_i != 0)) || ~((((((rf_waddr_i == 0) && (rf_raddr_a_i == 5'h01)) && chk_cs1_otype_45) || (((rf_waddr_i == 0) && (rf_raddr_a_i != 5'h01)) && (chk_cs1_otype_0 || chk_cs1_otype_1))) || ((rf_waddr_i == 5'h01) && (chk_cs1_otype_0 | chk_cs1_otype_23))) || ((rf_waddr_i != 0) && (chk_cs1_otype_0 | chk_cs1_otype_1)));
			perm_vio_vec[ibex_cheriot_pkg_PVIO_EX] = ~rf_fullcap_a[43];
		end
		else if (cheriot_operator_i[18]) begin
			perm_vio_vec[ibex_cheriot_pkg_PVIO_ASR] = ~pcc_cap_i[42];
			illegal_scr_addr = ((csr_addr_o < 24) | (csr_addr_o == 27)) | (~debug_mode_i & (csr_addr_o < 28));
		end
		else
			perm_vio_vec = 1'sb0;
		perm_vio = |perm_vio_vec;
	end
	assign cheriot_lsu_err = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & ~debug_mode_i) & ((addr_bound_vio | perm_vio) | (csr_dbg_tclr_fault_i & perm_vio_slc));
	reg ls_addr_misaligned_only;
	assign cheriot_ex_err_info_o = 12'h000;
	assign cheriot_wb_err_info_o = cheriot_wb_err_info_q;
	assign cheriot_wb_err_d = ((cheriot_wb_err_raw & cheriot_exec_id_i) & cheriot_ex_valid_raw) & ~debug_mode_i;
	wire addr_bound_vio_ext;
	wire [32:0] cheriot_top_chkaddr_ext;
	assign cheriot_top_chkaddr_ext = cheriot_ls_chkaddr + 33'd8;
	assign addr_bound_vio_ext = (is_cap ? addr_bound_vio | (cheriot_top_chkaddr_ext > rf_fullcap_a[111-:33]) : addr_bound_vio);
	function automatic [4:0] ibex_cheriot_pkg_cheriot_violation_cause;
		input reg bound_vio;
		input reg [7:0] perm_vio_vec;
		reg [4:0] vio_cause;
		reg unused_align_vio;
		begin
			unused_align_vio = perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN];
			if (perm_vio_vec[ibex_cheriot_pkg_PVIO_TAG])
				vio_cause = 5'h02;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SEAL])
				vio_cause = 5'h03;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_EX])
				vio_cause = 5'h11;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_LD])
				vio_cause = 5'h12;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SD])
				vio_cause = 5'h13;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_SC])
				vio_cause = 5'h15;
			else if (perm_vio_vec[ibex_cheriot_pkg_PVIO_ASR])
				vio_cause = 5'h18;
			else if (bound_vio)
				vio_cause = 5'h01;
			else
				vio_cause = 5'h00;
			ibex_cheriot_pkg_cheriot_violation_cause = vio_cause;
		end
	endfunction
	always @(*) begin : err_cause_comb
		if (_sv2v_0)
			;
		cheriot_err_cause = ibex_cheriot_pkg_cheriot_violation_cause(addr_bound_vio_ext, perm_vio_vec);
		rv32_err_cause = ibex_cheriot_pkg_cheriot_violation_cause(addr_bound_vio_rv32, perm_vio_vec_rv32);
		ls_addr_misaligned_only = (perm_vio_vec[ibex_cheriot_pkg_PVIO_ALIGN] && (perm_vio_vec[6:0] == 0)) && ~addr_bound_vio_ext;
		if (((cheriot_operator_i[18] & cheriot_wb_err_raw) & illegal_scr_addr) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = 16'h1000;
		else if ((cheriot_operator_i[18] & cheriot_wb_err_raw) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {6'h01, cheriot_cs2_dec_i, cheriot_err_cause};
		else if (cheriot_wb_err_raw & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {6'h00, rf_raddr_a_i, cheriot_err_cause};
		else if (((is_load_cap | is_store_cap) & cheriot_lsu_err) & cheriot_exec_id_i)
			cheriot_wb_err_info_d = {4'h0, ls_addr_misaligned_only, 1'b0, rf_raddr_a_i, cheriot_err_cause};
		else if (rv32_lsu_req_i & rv32_lsu_err)
			cheriot_wb_err_info_d = {6'h00, rf_raddr_a_i, rv32_err_cause};
		else
			cheriot_wb_err_info_d = cheriot_wb_err_info_q;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			cheriot_wb_err_q <= 1'b0;
			cheriot_wb_err_info_q <= 1'sb0;
		end
		else begin
			cheriot_wb_err_q <= cheriot_wb_err_d;
			cheriot_wb_err_info_q <= cheriot_wb_err_info_d;
		end
	assign lsu_req_o = (instr_is_cheriot_i ? cheriot_lsu_req : rv32_lsu_req_i);
	assign cpu_lsu_cheriot_err = (instr_is_cheriot_i ? cheriot_lsu_err : rv32_lsu_err);
	assign cpu_lsu_addr = (instr_is_cheriot_i ? cheriot_lsu_addr : rv32_lsu_addr_i);
	assign cpu_lsu_we = (instr_is_cheriot_i ? cheriot_lsu_we : rv32_lsu_we_i);
	assign cpu_lsu_wdata = (instr_is_cheriot_i ? cheriot_lsu_wdata : rv32_lsu_wdata_i);
	assign cpu_lsu_is_cap = instr_is_cheriot_i & cheriot_lsu_is_cap;
	assign lsu_cheriot_err_o = cpu_lsu_cheriot_err;
	assign lsu_we_o = cpu_lsu_we;
	assign lsu_addr_o = cpu_lsu_addr;
	assign lsu_wdata_o = cpu_lsu_wdata;
	assign lsu_is_cap_o = cpu_lsu_is_cap;
	assign lsu_lc_clrperm_o = (instr_is_cheriot_i ? cheriot_lsu_lc_clrperm : {3 {1'sb0}});
	assign lsu_type_o = (~instr_is_cheriot_i ? rv32_lsu_type_i : 2'b00);
	assign lsu_wcap_o = (instr_is_cheriot_i ? cheriot_lsu_wcap : ibex_cheriot_pkg_NULL_CAP);
	assign lsu_sign_ext_o = (~instr_is_cheriot_i ? rv32_lsu_sign_ext_i : 1'b0);
	assign rv32_addr_incr_req_o = ((cheriot_enable_i != ibex_pkg_IbexMuBiOn) | instr_is_rv32lsu_i ? addr_incr_req_i : 1'b0);
	assign rv32_addr_last_o = addr_last_i;
	assign csr_mshwm_set_o = (((lsu_req_o & ~lsu_cheriot_err_o) & lsu_we_o) & (lsu_addr_o[31:4] >= csr_mshwmb_i[31:4])) & (lsu_addr_o[31:4] < csr_mshwm_i[31:4]);
	assign csr_mshwm_new_o = {lsu_addr_o[31:4], 4'h0};
	wire unused_dbg_status;
	wire unused_dbg_cs1_vec;
	wire unused_dbg_cs2_vec;
	wire unused_dbg_cd_vec;
	assign unused_dbg_status = |{instr_is_rv32lsu_i, rv32_lsu_req_i, rv32_lsu_we_i, rv32_lsu_err, cheriot_exec_id_i, cheriot_lsu_err, rf_fullcap_a[32], result_cap_o[32], addr_bound_vio, perm_vio, addr_bound_vio_rv32, perm_vio_rv32};
	assign unused_dbg_cs1_vec = |{rf_fullcap_a[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(rf_fullcap_a[21-:4]), rf_fullcap_a[17-:9], rf_fullcap_a[8-:ibex_cheriot_pkg_CBOUND_W], rf_fullcap_a[24-:3], rf_fullcap_a[30-:6], rf_rdata_a};
	assign unused_dbg_cs2_vec = |{rf_fullcap_b[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(rf_fullcap_b[21-:4]), rf_fullcap_b[17-:9], rf_fullcap_b[8-:ibex_cheriot_pkg_CBOUND_W], rf_fullcap_b[24-:3], rf_fullcap_b[30-:6], rf_rdata_b};
	assign unused_dbg_cd_vec = |{result_cap_o[34-:2], ibex_cheriot_pkg_cheriot_expand_exp(result_cap_o[21-:4]), result_cap_o[17-:9], result_cap_o[8-:ibex_cheriot_pkg_CBOUND_W], result_cap_o[24-:3], result_cap_o[30-:6], result_data_o};
	wire unused_cheriot_ex_signals;
	assign unused_cheriot_ex_signals = |{instr_valid_i, csr_mshwm_i[3:0], csr_mshwmb_i[3:0], cheriot_wb_err_q};
	initial _sv2v_0 = 0;
endmodule
