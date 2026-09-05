module ibex_core (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	cheriot_enable_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_tag_o,
	data_rdata_i,
	data_tag_i,
	data_err_i,
	dummy_instr_id_o,
	dummy_instr_wb_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_wb_o,
	rf_we_wb_o,
	rf_wdata_wb_ecc_o,
	rf_rdata_a_ecc_i,
	rf_rdata_b_ecc_i,
	rf_wcap_ecc_wb_o,
	rf_rcap_a_ecc_i,
	rf_rcap_b_ecc_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	mcounteren_writable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_o
);
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [31:0] ibex_pkg_PMP_ADDR_MSB = 33;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RV32ZC = 32'sd3;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] ICacheTweakInfection = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	localparam [31:0] ibex_cheriot_pkg_REGCAP_W = 35;
	parameter [31:0] RegFileCapEccWidth = ibex_cheriot_pkg_REGCAP_W;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	output wire data_tag_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_tag_i;
	input wire data_err_i;
	output wire dummy_instr_id_o;
	output wire dummy_instr_wb_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire rf_we_wb_o;
	output wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_o;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_i;
	output wire [RegFileCapEccWidth - 1:0] rf_wcap_ecc_wb_o;
	input wire [RegFileCapEccWidth - 1:0] rf_rcap_a_ecc_i;
	input wire [RegFileCapEccWidth - 1:0] rf_rcap_b_ecc_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	output wire irq_pending_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	input wire [3:0] fetch_enable_i;
	input wire [3:0] mcounteren_writable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire [3:0] core_busy_o;
	localparam [31:0] PMPNumChan = 3;
	localparam [0:0] DataIndTiming = SecureIbex;
	localparam [0:0] PCIncrCheck = SecureIbex;
	localparam [0:0] ShadowCSR = 1'b0;
	wire dummy_instr_id;
	wire instr_valid_id;
	wire instr_new_id;
	wire [31:0] instr_rdata_id;
	wire [31:0] instr_rdata_alu_id;
	wire [15:0] instr_rdata_c_id;
	wire instr_is_compressed_id;
	wire [1:0] instr_gets_expanded_id;
	wire [15:0] instr_expanded_id;
	wire instr_perf_count_id;
	wire instr_bp_taken_id;
	wire instr_fetch_err;
	wire instr_fetch_err_plus2;
	wire instr_fetch_cheriot_acc_vio;
	wire instr_fetch_cheriot_bound_vio;
	wire illegal_c_insn_id;
	wire [31:0] pc_if;
	wire [31:0] pc_id;
	wire [31:0] pc_wb;
	wire [67:0] imd_val_d_ex;
	wire [67:0] imd_val_q_ex;
	wire [1:0] imd_val_we_ex;
	wire data_ind_timing;
	wire dummy_instr_en;
	wire [2:0] dummy_instr_mask;
	wire dummy_instr_seed_en;
	wire [31:0] dummy_instr_seed;
	wire icache_enable;
	wire icache_inval;
	wire icache_ecc_error;
	wire pc_mismatch_alert;
	wire csr_shadow_err;
	wire cheriot_enable_mubi_err;
	wire instr_first_cycle_id;
	wire instr_valid_clear;
	wire pc_set;
	wire nt_branch_mispredict;
	wire [31:0] nt_branch_addr;
	wire [2:0] pc_mux_id;
	wire [1:0] exc_pc_mux_id;
	wire [6:0] exc_cause;
	wire instr_intg_err;
	wire lsu_load_err;
	wire lsu_load_err_raw;
	wire lsu_store_err;
	wire lsu_store_err_raw;
	wire lsu_load_resp_intg_err;
	wire lsu_store_resp_intg_err;
	wire lsu_err_is_cheriot;
	wire expecting_load_resp_id;
	wire expecting_store_resp_id;
	wire lsu_addr_incr_req;
	wire [31:0] lsu_addr_last;
	wire [31:0] lsu_addr;
	wire [31:0] branch_target_ex_rv32;
	wire [31:0] branch_target_ex_cheriot;
	wire [31:0] branch_target_ex;
	wire branch_decision;
	wire ctrl_busy;
	wire if_busy;
	wire lsu_busy;
	wire [4:0] rf_raddr_a;
	wire [31:0] rf_rdata_a;
	wire [4:0] rf_raddr_b;
	wire [31:0] rf_rdata_b;
	wire rf_ren_a;
	wire rf_ren_b;
	wire [4:0] rf_waddr_wb;
	wire [31:0] rf_wdata_wb;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	wire [34:0] rf_wcap_wb;
	wire [34:0] rf_rcap_a;
	wire [34:0] rf_rcap_b;
	function automatic [34:0] sv2v_cast_89126;
		input reg [34:0] inp;
		sv2v_cast_89126 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_vec_to_regcap;
		input reg [34:0] vec_in;
		ibex_cheriot_pkg_cheriot_vec_to_regcap = sv2v_cast_89126(vec_in);
	endfunction
	assign rf_rcap_a = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_a_ecc_i[34:0]);
	assign rf_rcap_b = ibex_cheriot_pkg_cheriot_vec_to_regcap(rf_rcap_b_ecc_i[34:0]);
	wire [31:0] rf_wdata_fwd_wb;
	wire [34:0] rf_wcap_fwd_wb;
	wire [31:0] rf_wdata_lsu;
	wire [34:0] rf_wcap_lsu;
	wire rf_we_wb;
	wire rf_we_lsu;
	wire rf_ecc_err_comb;
	wire [4:0] rf_waddr_id;
	wire [31:0] rf_wdata_id;
	wire rf_we_id;
	wire rf_rd_a_wb_match;
	wire rf_rd_b_wb_match;
	wire [6:0] alu_operator_ex;
	wire [31:0] alu_operand_a_ex;
	wire [31:0] alu_operand_b_ex;
	wire [31:0] bt_a_operand;
	wire [31:0] bt_b_operand;
	wire [31:0] alu_adder_result_ex;
	wire [31:0] result_ex;
	wire mult_en_ex;
	wire div_en_ex;
	wire mult_sel_ex;
	wire div_sel_ex;
	wire [1:0] multdiv_operator_ex;
	wire [1:0] multdiv_signed_mode_ex;
	wire [31:0] multdiv_operand_a_ex;
	wire [31:0] multdiv_operand_b_ex;
	wire multdiv_ready_id;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_op_en;
	wire [11:0] csr_addr;
	wire [31:0] csr_rdata;
	wire [31:0] csr_wdata;
	wire illegal_csr_insn_id;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_rdata_valid;
	wire [31:0] lsu_wdata;
	wire [34:0] lsu_wcap;
	wire lsu_req_done;
	wire id_in_ready;
	wire ex_valid;
	wire lsu_resp_valid;
	wire lsu_resp_err;
	wire instr_req_int;
	wire instr_req_gated;
	wire instr_exec;
	wire en_wb;
	wire [1:0] instr_type_wb;
	wire ready_wb;
	wire rf_write_wb;
	wire outstanding_load_wb;
	wire outstanding_store_wb;
	wire dummy_instr_wb;
	wire nmi_mode;
	wire [17:0] irqs;
	wire csr_mstatus_mie;
	wire [31:0] csr_mepc;
	wire [31:0] csr_depc;
	wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr;
	wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg;
	wire [2:0] csr_pmp_mseccfg;
	wire pmp_req_err [0:2];
	wire data_req_out;
	wire csr_save_if;
	wire csr_save_id;
	wire csr_save_wb;
	wire csr_restore_mret_id;
	wire csr_restore_dret_id;
	wire csr_save_cause;
	wire csr_mepcc_clrtag;
	wire csr_mtvec_init;
	wire [31:0] csr_mtvec;
	wire [31:0] csr_mtval;
	wire csr_mstatus_tw;
	wire [1:0] priv_mode_id;
	wire [1:0] priv_mode_lsu;
	wire debug_mode;
	wire debug_mode_entering;
	wire [2:0] debug_cause;
	wire debug_csr_save;
	wire debug_single_step;
	wire debug_ebreakm;
	wire debug_ebreaku;
	wire trigger_match;
	wire instr_id_done;
	wire instr_done_wb;
	wire perf_instr_ret_wb;
	wire perf_instr_ret_compressed_wb;
	wire perf_instr_ret_wb_spec;
	wire perf_instr_ret_compressed_wb_spec;
	wire perf_iside_wait;
	wire perf_dside_wait;
	wire perf_mul_wait;
	wire perf_div_wait;
	wire perf_jump;
	wire perf_branch;
	wire perf_tbranch;
	wire perf_load;
	wire perf_store;
	wire illegal_insn_id;
	wire unused_illegal_insn_id;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	wire [111:0] pcc_cap_r;
	wire [111:0] pcc_cap_w;
	wire cheriot_branch_req;
	wire cheriot_branch_req_spec;
	wire instr_is_cheriot_id;
	wire instr_is_rv32lsu_id;
	wire cheriot_exec_id;
	wire [11:0] cheriot_imm12;
	wire [19:0] cheriot_imm20;
	wire [20:0] cheriot_imm21;
	wire [4:0] cheriot_cs2_dec;
	wire [2:0] cheriot_cap_field_sel;
	wire [2:0] cheriot_adder_a_sel;
	wire [1:0] cheriot_adder_b_sel;
	wire [2:0] cheriot_setaddr_sel;
	wire [2:0] cheriot_setbounds_sel;
	wire cheriot_load_id;
	wire cheriot_store_id;
	wire cheriot_rf_we;
	wire [31:0] cheriot_result_data;
	wire [34:0] cheriot_result_cap;
	wire cheriot_ex_valid;
	wire cheriot_ex_err;
	wire [11:0] cheriot_ex_err_info;
	wire cheriot_wb_err;
	wire [15:0] cheriot_wb_err_info;
	wire [25:0] cheriot_operator;
	wire rv32_lsu_req;
	wire rv32_lsu_we;
	wire [1:0] rv32_lsu_type;
	wire [31:0] rv32_lsu_wdata;
	wire rv32_lsu_sign_ext;
	wire rv32_lsu_addr_incr_req;
	wire [31:0] rv32_lsu_addr_last;
	wire cheriot_csr_access;
	wire [4:0] cheriot_csr_addr;
	wire [31:0] cheriot_csr_wdata;
	wire [34:0] cheriot_csr_wcap;
	wire [4:0] cheriot_csr_op;
	wire cheriot_csr_op_en;
	wire [31:0] cheriot_csr_rdata;
	wire [34:0] cheriot_csr_rcap;
	wire cheriot_csr_set_mie;
	wire cheriot_csr_clr_mie;
	wire lsu_is_cap;
	wire lsu_cheriot_err;
	wire [2:0] lsu_lc_clrperm;
	wire csr_dbg_tclr_fault;
	wire cheriot_fatal_err;
	wire [31:0] csr_mshwm;
	wire [31:0] csr_mshwmb;
	wire csr_mshwm_set;
	wire [31:0] csr_mshwm_new;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (SecureIbex) begin : g_core_busy_secure
			localparam [31:0] NumBusySignals = 3;
			localparam [31:0] NumBusyBits = ibex_pkg_IbexMuBiWidth * NumBusySignals;
			wire [NumBusyBits - 1:0] busy_bits_buf;
			prim_generic_buf #(.Width(NumBusyBits)) u_fetch_enable_buf(
				.in_i({ibex_pkg_IbexMuBiWidth {ctrl_busy, if_busy, lsu_busy}}),
				.out_o(busy_bits_buf)
			);
			genvar _gv_i_1;
			for (_gv_i_1 = 0; _gv_i_1 < ibex_pkg_IbexMuBiWidth; _gv_i_1 = _gv_i_1 + 1) begin : g_core_busy_bits
				localparam i = _gv_i_1;
				if (ibex_pkg_IbexMuBiOn[i] == 1'b1) begin : g_pos
					assign core_busy_o[i] = |busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
				else begin : g_neg
					assign core_busy_o[i] = ~|busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
			end
		end
		else begin : g_core_busy_non_secure
			assign core_busy_o = ((ctrl_busy || if_busy) || lsu_busy ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_I = 0;
	localparam [31:0] ibex_pkg_PMP_I2 = 1;
	ibex_if_stage #(
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.DummyInstructions(DummyInstructions),
		.ICache(ICache),
		.RV32ZC(RV32ZC),
		.ICacheECC(ICacheECC),
		.ICacheTweakInfection(ICacheTweakInfection),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.PCIncrCheck(PCIncrCheck),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.BaseIsa(BaseIsa)
	) if_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.boot_addr_i(boot_addr_i),
		.req_i(instr_req_gated),
		.debug_mode_i(debug_mode),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_bus_err_i(instr_err_i),
		.instr_intg_err_o(instr_intg_err),
		.ic_tag_req_o(ic_tag_req_o),
		.ic_tag_write_o(ic_tag_write_o),
		.ic_tag_addr_o(ic_tag_addr_o),
		.ic_tag_wdata_o(ic_tag_wdata_o),
		.ic_tag_rdata_i(ic_tag_rdata_i),
		.ic_data_req_o(ic_data_req_o),
		.ic_data_write_o(ic_data_write_o),
		.ic_data_addr_o(ic_data_addr_o),
		.ic_data_wdata_o(ic_data_wdata_o),
		.ic_data_rdata_i(ic_data_rdata_i),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.ic_scr_key_req_o(ic_scr_key_req_o),
		.instr_valid_id_o(instr_valid_id),
		.instr_new_id_o(instr_new_id),
		.instr_rdata_id_o(instr_rdata_id),
		.instr_rdata_alu_id_o(instr_rdata_alu_id),
		.instr_rdata_c_id_o(instr_rdata_c_id),
		.instr_is_compressed_id_o(instr_is_compressed_id),
		.instr_gets_expanded_id_o(instr_gets_expanded_id),
		.instr_expanded_id_o(instr_expanded_id),
		.instr_bp_taken_o(instr_bp_taken_id),
		.instr_fetch_err_o(instr_fetch_err),
		.instr_fetch_err_plus2_o(instr_fetch_err_plus2),
		.instr_fetch_cheriot_acc_vio_o(instr_fetch_cheriot_acc_vio),
		.instr_fetch_cheriot_bound_vio_o(instr_fetch_cheriot_bound_vio),
		.illegal_c_insn_id_o(illegal_c_insn_id),
		.dummy_instr_id_o(dummy_instr_id),
		.pc_if_o(pc_if),
		.pc_id_o(pc_id),
		.pmp_err_if_i(pmp_req_err[ibex_pkg_PMP_I]),
		.pmp_err_if_plus2_i(pmp_req_err[ibex_pkg_PMP_I2]),
		.instr_valid_clear_i(instr_valid_clear),
		.pc_set_i(pc_set),
		.pc_mux_i(pc_mux_id),
		.nt_branch_mispredict_i(nt_branch_mispredict),
		.exc_pc_mux_i(exc_pc_mux_id),
		.exc_cause(exc_cause),
		.dummy_instr_en_i(dummy_instr_en),
		.dummy_instr_mask_i(dummy_instr_mask),
		.dummy_instr_seed_en_i(dummy_instr_seed_en),
		.dummy_instr_seed_i(dummy_instr_seed),
		.icache_enable_i(icache_enable),
		.icache_inval_i(icache_inval),
		.icache_ecc_error_o(icache_ecc_error),
		.branch_target_ex_i(branch_target_ex),
		.nt_branch_addr_i(nt_branch_addr),
		.csr_mepc_i(csr_mepc),
		.csr_depc_i(csr_depc),
		.csr_mtvec_i(csr_mtvec),
		.csr_mtvec_init_o(csr_mtvec_init),
		.id_in_ready_i(id_in_ready),
		.pc_mismatch_alert_o(pc_mismatch_alert),
		.if_busy_o(if_busy),
		.pcc_cap_i(pcc_cap_r)
	);
	assign perf_iside_wait = id_in_ready & ~instr_valid_id;
	generate
		if (SecureIbex) begin : g_instr_req_gated_secure
			assign instr_req_gated = instr_req_int & (fetch_enable_i == ibex_pkg_IbexMuBiOn);
			assign instr_exec = fetch_enable_i == ibex_pkg_IbexMuBiOn;
		end
		else begin : g_instr_req_gated_non_secure
			wire unused_fetch_enable;
			assign unused_fetch_enable = ^fetch_enable_i[3:1];
			assign instr_req_gated = instr_req_int & fetch_enable_i[0];
			assign instr_exec = fetch_enable_i[0];
		end
	endgenerate
	ibex_id_stage #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.DataIndTiming(DataIndTiming),
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.BaseIsa(BaseIsa)
	) id_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.ctrl_busy_o(ctrl_busy),
		.illegal_insn_o(illegal_insn_id),
		.instr_valid_i(instr_valid_id),
		.instr_rdata_i(instr_rdata_id),
		.instr_rdata_alu_i(instr_rdata_alu_id),
		.instr_rdata_c_i(instr_rdata_c_id),
		.instr_is_compressed_i(instr_is_compressed_id),
		.instr_gets_expanded_i(instr_gets_expanded_id),
		.instr_bp_taken_i(instr_bp_taken_id),
		.branch_decision_i(branch_decision),
		.instr_first_cycle_id_o(instr_first_cycle_id),
		.instr_valid_clear_o(instr_valid_clear),
		.id_in_ready_o(id_in_ready),
		.instr_exec_i(instr_exec),
		.instr_req_o(instr_req_int),
		.pc_set_o(pc_set),
		.pc_mux_o(pc_mux_id),
		.nt_branch_mispredict_o(nt_branch_mispredict),
		.nt_branch_addr_o(nt_branch_addr),
		.exc_pc_mux_o(exc_pc_mux_id),
		.exc_cause_o(exc_cause),
		.icache_inval_o(icache_inval),
		.instr_fetch_err_i(instr_fetch_err),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2),
		.instr_fetch_cheriot_acc_vio_i(instr_fetch_cheriot_acc_vio),
		.instr_fetch_cheriot_bound_vio_i(instr_fetch_cheriot_bound_vio),
		.illegal_c_insn_i(illegal_c_insn_id),
		.pc_id_i(pc_id),
		.ex_valid_i(ex_valid),
		.lsu_resp_valid_i(lsu_resp_valid),
		.alu_operator_ex_o(alu_operator_ex),
		.alu_operand_a_ex_o(alu_operand_a_ex),
		.alu_operand_b_ex_o(alu_operand_b_ex),
		.imd_val_q_ex_o(imd_val_q_ex),
		.imd_val_d_ex_i(imd_val_d_ex),
		.imd_val_we_ex_i(imd_val_we_ex),
		.bt_a_operand_o(bt_a_operand),
		.bt_b_operand_o(bt_b_operand),
		.mult_en_ex_o(mult_en_ex),
		.div_en_ex_o(div_en_ex),
		.mult_sel_ex_o(mult_sel_ex),
		.div_sel_ex_o(div_sel_ex),
		.multdiv_operator_ex_o(multdiv_operator_ex),
		.multdiv_signed_mode_ex_o(multdiv_signed_mode_ex),
		.multdiv_operand_a_ex_o(multdiv_operand_a_ex),
		.multdiv_operand_b_ex_o(multdiv_operand_b_ex),
		.multdiv_ready_id_o(multdiv_ready_id),
		.csr_access_o(csr_access),
		.csr_op_o(csr_op),
		.csr_addr_o(csr_addr),
		.csr_op_en_o(csr_op_en),
		.csr_save_if_o(csr_save_if),
		.csr_save_id_o(csr_save_id),
		.csr_save_wb_o(csr_save_wb),
		.csr_restore_mret_id_o(csr_restore_mret_id),
		.csr_restore_dret_id_o(csr_restore_dret_id),
		.csr_save_cause_o(csr_save_cause),
		.csr_mepcc_clrtag_o(csr_mepcc_clrtag),
		.csr_mtval_o(csr_mtval),
		.priv_mode_i(priv_mode_id),
		.csr_mstatus_tw_i(csr_mstatus_tw),
		.illegal_csr_insn_i(illegal_csr_insn_id),
		.data_ind_timing_i(data_ind_timing),
		.csr_pcc_perm_sr_i(pcc_cap_r[42]),
		.lsu_req_o(rv32_lsu_req),
		.lsu_we_o(rv32_lsu_we),
		.lsu_type_o(rv32_lsu_type),
		.lsu_sign_ext_o(rv32_lsu_sign_ext),
		.lsu_wdata_o(rv32_lsu_wdata),
		.lsu_req_done_i(lsu_req_done),
		.lsu_addr_incr_req_i(rv32_lsu_addr_incr_req),
		.lsu_addr_last_i(rv32_lsu_addr_last),
		.lsu_load_err_i(lsu_load_err),
		.lsu_load_resp_intg_err_i(lsu_load_resp_intg_err),
		.lsu_store_err_i(lsu_store_err),
		.lsu_store_resp_intg_err_i(lsu_store_resp_intg_err),
		.lsu_err_is_cheriot_i(lsu_err_is_cheriot),
		.expecting_load_resp_o(expecting_load_resp_id),
		.expecting_store_resp_o(expecting_store_resp_id),
		.csr_mstatus_mie_i(csr_mstatus_mie),
		.irq_pending_i(irq_pending_o),
		.irqs_i(irqs),
		.irq_nm_i(irq_nm_i),
		.nmi_mode_o(nmi_mode),
		.debug_mode_o(debug_mode),
		.debug_mode_entering_o(debug_mode_entering),
		.debug_cause_o(debug_cause),
		.debug_csr_save_o(debug_csr_save),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step),
		.debug_ebreakm_i(debug_ebreakm),
		.debug_ebreaku_i(debug_ebreaku),
		.trigger_match_i(trigger_match),
		.result_ex_i(result_ex),
		.csr_rdata_i(csr_rdata),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_rdata_a_i(rf_rdata_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_rdata_b_i(rf_rdata_b),
		.rf_ren_a_o(rf_ren_a),
		.rf_ren_b_o(rf_ren_b),
		.rf_waddr_id_o(rf_waddr_id),
		.rf_wdata_id_o(rf_wdata_id),
		.rf_we_id_o(rf_we_id),
		.rf_rd_a_wb_match_o(rf_rd_a_wb_match),
		.rf_rd_b_wb_match_o(rf_rd_b_wb_match),
		.rf_waddr_wb_i(rf_waddr_wb),
		.rf_wdata_fwd_wb_i(rf_wdata_fwd_wb),
		.rf_write_wb_i(rf_write_wb),
		.en_wb_o(en_wb),
		.instr_type_wb_o(instr_type_wb),
		.instr_perf_count_id_o(instr_perf_count_id),
		.ready_wb_i(ready_wb),
		.outstanding_load_wb_i(outstanding_load_wb),
		.outstanding_store_wb_i(outstanding_store_wb),
		.perf_jump_o(perf_jump),
		.perf_branch_o(perf_branch),
		.perf_tbranch_o(perf_tbranch),
		.perf_dside_wait_o(perf_dside_wait),
		.perf_mul_wait_o(perf_mul_wait),
		.perf_div_wait_o(perf_div_wait),
		.instr_id_done_o(instr_id_done),
		.cheriot_exec_id_o(cheriot_exec_id),
		.instr_is_cheriot_id_o(instr_is_cheriot_id),
		.instr_is_rv32lsu_id_o(instr_is_rv32lsu_id),
		.cheriot_imm12_o(cheriot_imm12),
		.cheriot_imm20_o(cheriot_imm20),
		.cheriot_imm21_o(cheriot_imm21),
		.cheriot_operator_o(cheriot_operator),
		.cheriot_cs2_dec_o(cheriot_cs2_dec),
		.cheriot_cap_field_sel_o(cheriot_cap_field_sel),
		.cheriot_adder_a_sel_o(cheriot_adder_a_sel),
		.cheriot_adder_b_sel_o(cheriot_adder_b_sel),
		.cheriot_setaddr_sel_o(cheriot_setaddr_sel),
		.cheriot_setbounds_sel_o(cheriot_setbounds_sel),
		.cheriot_load_o(cheriot_load_id),
		.cheriot_store_o(cheriot_store_id),
		.cheriot_ex_valid_i(cheriot_ex_valid),
		.cheriot_ex_err_i(cheriot_ex_err),
		.cheriot_ex_err_info_i(cheriot_ex_err_info),
		.cheriot_wb_err_i(cheriot_wb_err),
		.cheriot_wb_err_info_i(cheriot_wb_err_info),
		.cheriot_branch_req_i(cheriot_branch_req_spec),
		.cheriot_branch_target_i(branch_target_ex_cheriot)
	);
	assign unused_illegal_insn_id = illegal_insn_id;
	ibex_ex_block #(
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) ex_block_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.alu_operator_i(alu_operator_ex),
		.alu_operand_a_i(alu_operand_a_ex),
		.alu_operand_b_i(alu_operand_b_ex),
		.alu_instr_first_cycle_i(instr_first_cycle_id),
		.bt_a_operand_i(bt_a_operand),
		.bt_b_operand_i(bt_b_operand),
		.multdiv_operator_i(multdiv_operator_ex),
		.mult_en_i(mult_en_ex),
		.div_en_i(div_en_ex),
		.mult_sel_i(mult_sel_ex),
		.div_sel_i(div_sel_ex),
		.multdiv_signed_mode_i(multdiv_signed_mode_ex),
		.multdiv_operand_a_i(multdiv_operand_a_ex),
		.multdiv_operand_b_i(multdiv_operand_b_ex),
		.multdiv_ready_id_i(multdiv_ready_id),
		.data_ind_timing_i(data_ind_timing),
		.imd_val_we_o(imd_val_we_ex),
		.imd_val_d_o(imd_val_d_ex),
		.imd_val_q_i(imd_val_q_ex),
		.alu_adder_result_ex_o(alu_adder_result_ex),
		.result_ex_o(result_ex),
		.branch_target_o(branch_target_ex_rv32),
		.branch_decision_o(branch_decision),
		.ex_valid_o(ex_valid)
	);
	function automatic [5:0] sv2v_cast_ADFD4;
		input reg [5:0] inp;
		sv2v_cast_ADFD4 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_AB532;
		input reg [2:0] inp;
		sv2v_cast_AB532 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_AF5D3;
		input reg [3:0] inp;
		sv2v_cast_AF5D3 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_E9444;
		input reg [8:0] inp;
		sv2v_cast_E9444 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_ADFD4(1'sb0), sv2v_cast_AB532(1'sb0), sv2v_cast_AF5D3(1'sb0), sv2v_cast_E9444(1'sb0), sv2v_cast_E9444(1'sb0)};
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	generate
		if (BaseIsa == 32'sd1) begin : g_cheriot_ex
			ibex_cheriot_ex #(.WritebackStage(WritebackStage)) u_ibex_cheriot_ex(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.cheriot_enable_i(cheriot_enable_i),
				.debug_mode_i(debug_mode),
				.fwd_we_i(rf_write_wb),
				.fwd_waddr_i(rf_waddr_wb),
				.fwd_wdata_i(rf_wdata_fwd_wb),
				.fwd_wcap_i(rf_wcap_fwd_wb),
				.rf_raddr_a_i(rf_raddr_a),
				.rf_rdata_a_i(rf_rdata_a),
				.rf_rcap_a_i(rf_rcap_a),
				.rf_raddr_b_i(rf_raddr_b),
				.rf_rdata_b_i(rf_rdata_b),
				.rf_rcap_b_i(rf_rcap_b),
				.rf_waddr_i(rf_waddr_id),
				.pcc_cap_i(pcc_cap_r),
				.pcc_cap_o(pcc_cap_w),
				.pc_id_i(pc_id),
				.branch_req_o(cheriot_branch_req),
				.branch_req_spec_o(cheriot_branch_req_spec),
				.branch_target_o(branch_target_ex_cheriot),
				.cheriot_exec_id_i(cheriot_exec_id),
				.instr_valid_i(instr_valid_id),
				.instr_first_cycle_i(instr_first_cycle_id),
				.instr_is_cheriot_i(instr_is_cheriot_id),
				.instr_is_rv32lsu_i(instr_is_rv32lsu_id),
				.instr_is_compressed_i(instr_is_compressed_id),
				.cheriot_imm12_i(cheriot_imm12),
				.cheriot_imm20_i(cheriot_imm20),
				.cheriot_imm21_i(cheriot_imm21),
				.cheriot_operator_i(cheriot_operator),
				.cheriot_cs2_dec_i(cheriot_cs2_dec),
				.cheriot_cap_field_sel_i(cheriot_cap_field_sel),
				.cheriot_adder_a_sel_i(cheriot_adder_a_sel),
				.cheriot_adder_b_sel_i(cheriot_adder_b_sel),
				.cheriot_setaddr_sel_i(cheriot_setaddr_sel),
				.cheriot_setbounds_sel_i(cheriot_setbounds_sel),
				.cheriot_rf_we_o(cheriot_rf_we),
				.result_data_o(cheriot_result_data),
				.result_cap_o(cheriot_result_cap),
				.cheriot_ex_valid_o(cheriot_ex_valid),
				.cheriot_ex_err_o(cheriot_ex_err),
				.cheriot_ex_err_info_o(cheriot_ex_err_info),
				.cheriot_wb_err_o(cheriot_wb_err),
				.cheriot_wb_err_info_o(cheriot_wb_err_info),
				.lsu_req_o(lsu_req),
				.lsu_is_cap_o(lsu_is_cap),
				.lsu_lc_clrperm_o(lsu_lc_clrperm),
				.lsu_cheriot_err_o(lsu_cheriot_err),
				.lsu_we_o(lsu_we),
				.lsu_addr_o(lsu_addr),
				.lsu_type_o(lsu_type),
				.lsu_wdata_o(lsu_wdata),
				.lsu_wcap_o(lsu_wcap),
				.lsu_sign_ext_o(lsu_sign_ext),
				.addr_incr_req_i(lsu_addr_incr_req),
				.addr_last_i(lsu_addr_last),
				.rv32_lsu_req_i(rv32_lsu_req),
				.rv32_lsu_we_i(rv32_lsu_we),
				.rv32_lsu_type_i(rv32_lsu_type),
				.rv32_lsu_wdata_i(rv32_lsu_wdata),
				.rv32_lsu_sign_ext_i(rv32_lsu_sign_ext),
				.rv32_lsu_addr_i(alu_adder_result_ex),
				.rv32_addr_incr_req_o(rv32_lsu_addr_incr_req),
				.rv32_addr_last_o(rv32_lsu_addr_last),
				.csr_rdata_i(cheriot_csr_rdata),
				.csr_rcap_i(cheriot_csr_rcap),
				.csr_mstatus_mie_i(csr_mstatus_mie),
				.csr_access_o(cheriot_csr_access),
				.csr_addr_o(cheriot_csr_addr),
				.csr_wdata_o(cheriot_csr_wdata),
				.csr_wcap_o(cheriot_csr_wcap),
				.csr_op_o(cheriot_csr_op),
				.csr_op_en_o(cheriot_csr_op_en),
				.csr_set_mie_o(cheriot_csr_set_mie),
				.csr_clr_mie_o(cheriot_csr_clr_mie),
				.csr_mshwm_i(csr_mshwm),
				.csr_mshwmb_i(csr_mshwmb),
				.csr_mshwm_set_o(csr_mshwm_set),
				.csr_mshwm_new_o(csr_mshwm_new),
				.ztop_rdata_i(32'h00000000),
				.ztop_rcap_i(ibex_cheriot_pkg_NULL_CAP),
				.csr_dbg_tclr_fault_i(csr_dbg_tclr_fault)
			);
			assign branch_target_ex = (instr_valid_id & instr_is_cheriot_id ? branch_target_ex_cheriot : branch_target_ex_rv32);
		end
		else begin : gen_no_cheriot_ex
			assign cheriot_branch_req = 1'b0;
			assign cheriot_branch_req_spec = 1'b0;
			assign branch_target_ex = branch_target_ex_rv32;
			assign pcc_cap_w = ibex_cheriot_pkg_NULL_DECODED_CAP;
			assign cheriot_rf_we = 1'b0;
			assign cheriot_result_data = 32'h00000000;
			assign cheriot_result_cap = ibex_cheriot_pkg_NULL_CAP;
			assign cheriot_ex_valid = 1'b0;
			assign cheriot_ex_err = 1'b0;
			assign cheriot_ex_err_info = 12'h000;
			assign cheriot_wb_err = 1'b0;
			assign cheriot_wb_err_info = 16'h0000;
			assign lsu_req = rv32_lsu_req;
			assign lsu_is_cap = 1'b0;
			assign lsu_lc_clrperm = 1'sb0;
			assign lsu_cheriot_err = 1'b0;
			assign lsu_we = rv32_lsu_we;
			assign lsu_addr = alu_adder_result_ex;
			assign lsu_type = rv32_lsu_type;
			assign lsu_wdata = rv32_lsu_wdata;
			assign lsu_wcap = ibex_cheriot_pkg_NULL_CAP;
			assign lsu_sign_ext = rv32_lsu_sign_ext;
			assign rv32_lsu_addr_incr_req = lsu_addr_incr_req;
			assign rv32_lsu_addr_last = lsu_addr_last;
			assign cheriot_csr_access = 1'b0;
			assign cheriot_csr_addr = 5'h00;
			assign cheriot_csr_wdata = 32'h00000000;
			assign cheriot_csr_wcap = ibex_cheriot_pkg_NULL_CAP;
			assign cheriot_csr_op = 5'd0;
			assign cheriot_csr_op_en = 1'b0;
			assign cheriot_csr_set_mie = 1'b0;
			assign cheriot_csr_clr_mie = 1'b0;
			assign csr_mshwm_set = 1'b0;
			assign csr_mshwm_new = 32'h00000000;
			assign branch_target_ex_cheriot = 32'h00000000;
			wire unused_cheriot_core_sigs;
			assign unused_cheriot_core_sigs = ((((((((((((((((((((^rf_rcap_a_ecc_i | ^rf_rcap_b_ecc_i) | cheriot_exec_id) | instr_is_rv32lsu_id) | ^cheriot_imm12) | ^cheriot_imm20) | ^cheriot_imm21) | ^cheriot_cs2_dec) | ^cheriot_operator) | ^cheriot_csr_rdata) | ^cheriot_csr_rcap) | csr_dbg_tclr_fault) | ^csr_mshwm) | ^csr_mshwmb) | ^rf_wcap_fwd_wb) | ^cheriot_cap_field_sel) | ^cheriot_adder_a_sel) | ^cheriot_adder_b_sel) | ^cheriot_setaddr_sel) | ^cheriot_setbounds_sel) | ^rf_rcap_a) | ^rf_rcap_b;
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_D = 2;
	assign data_req_o = data_req_out & ~pmp_req_err[ibex_pkg_PMP_D];
	assign lsu_resp_err = lsu_load_err | lsu_store_err;
	ibex_load_store_unit #(
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.BaseIsa(BaseIsa)
	) load_store_unit_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.data_req_o(data_req_out),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_bus_err_i(data_err_i),
		.data_pmp_err_i(pmp_req_err[ibex_pkg_PMP_D]),
		.data_addr_o(data_addr_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_wdata_o(data_wdata_o),
		.data_tag_o(data_tag_o),
		.data_rdata_i(data_rdata_i),
		.data_tag_i(data_tag_i),
		.lsu_we_i(lsu_we),
		.lsu_type_i(lsu_type),
		.lsu_wdata_i(lsu_wdata),
		.lsu_wcap_i(lsu_wcap),
		.lsu_sign_ext_i(lsu_sign_ext),
		.lsu_rdata_o(rf_wdata_lsu),
		.lsu_rcap_o(rf_wcap_lsu),
		.lsu_rdata_valid_o(lsu_rdata_valid),
		.lsu_req_i(lsu_req),
		.lsu_is_cap_i(lsu_is_cap),
		.lsu_lc_clrperm_i(lsu_lc_clrperm),
		.lsu_cheriot_err_i(lsu_cheriot_err),
		.adder_result_ex_i(lsu_addr),
		.addr_incr_req_o(lsu_addr_incr_req),
		.addr_last_o(lsu_addr_last),
		.lsu_req_done_o(lsu_req_done),
		.lsu_resp_valid_o(lsu_resp_valid),
		.load_err_o(lsu_load_err_raw),
		.load_resp_intg_err_o(lsu_load_resp_intg_err),
		.store_err_o(lsu_store_err_raw),
		.store_resp_intg_err_o(lsu_store_resp_intg_err),
		.lsu_err_is_cheriot_o(lsu_err_is_cheriot),
		.busy_o(lsu_busy),
		.perf_load_o(perf_load),
		.perf_store_o(perf_store)
	);
	ibex_wb_stage #(
		.ResetAll(ResetAll),
		.WritebackStage(WritebackStage),
		.DummyInstructions(DummyInstructions)
	) wb_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.en_wb_i(en_wb),
		.instr_type_wb_i(instr_type_wb),
		.pc_id_i(pc_id),
		.instr_is_compressed_id_i(instr_is_compressed_id),
		.instr_perf_count_id_i(instr_perf_count_id),
		.instr_is_cheriot_i(instr_is_cheriot_id),
		.cheriot_load_i(cheriot_load_id),
		.cheriot_store_i(cheriot_store_id),
		.ready_wb_o(ready_wb),
		.rf_write_wb_o(rf_write_wb),
		.outstanding_load_wb_o(outstanding_load_wb),
		.outstanding_store_wb_o(outstanding_store_wb),
		.pc_wb_o(pc_wb),
		.perf_instr_ret_wb_o(perf_instr_ret_wb),
		.perf_instr_ret_compressed_wb_o(perf_instr_ret_compressed_wb),
		.perf_instr_ret_wb_spec_o(perf_instr_ret_wb_spec),
		.perf_instr_ret_compressed_wb_spec_o(perf_instr_ret_compressed_wb_spec),
		.rf_waddr_id_i(rf_waddr_id),
		.rf_wdata_id_i(rf_wdata_id),
		.rf_we_id_i(rf_we_id),
		.dummy_instr_id_i(dummy_instr_id),
		.cheriot_rf_we_i(cheriot_rf_we),
		.cheriot_rf_wdata_i(cheriot_result_data),
		.cheriot_rf_wcap_i(cheriot_result_cap),
		.rf_wdata_lsu_i(rf_wdata_lsu),
		.rf_wcap_lsu_i(rf_wcap_lsu),
		.rf_we_lsu_i(rf_we_lsu),
		.rf_wdata_fwd_wb_o(rf_wdata_fwd_wb),
		.rf_wcap_fwd_wb_o(rf_wcap_fwd_wb),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_wdata_wb_o(rf_wdata_wb),
		.rf_wcap_wb_o(rf_wcap_wb),
		.rf_we_wb_o(rf_we_wb),
		.dummy_instr_wb_o(dummy_instr_wb),
		.lsu_resp_valid_i(lsu_resp_valid),
		.lsu_resp_err_i(lsu_resp_err),
		.instr_done_wb_o(instr_done_wb)
	);
	generate
		if (SecureIbex) begin : g_check_mem_response
			assign lsu_load_err = lsu_load_err_raw & (outstanding_load_wb | expecting_load_resp_id);
			assign lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
			assign rf_we_lsu = lsu_rdata_valid & (outstanding_load_wb | expecting_load_resp_id);
		end
		else begin : g_no_check_mem_response
			assign lsu_load_err = lsu_load_err_raw;
			assign lsu_store_err = lsu_store_err_raw;
			assign rf_we_lsu = lsu_rdata_valid;
			wire unused_expecting_load_resp_id;
			wire unused_expecting_store_resp_id;
			assign unused_expecting_load_resp_id = expecting_load_resp_id;
			assign unused_expecting_store_resp_id = expecting_store_resp_id;
		end
	endgenerate
	assign dummy_instr_id_o = dummy_instr_id;
	assign dummy_instr_wb_o = dummy_instr_wb;
	assign rf_raddr_a_o = rf_raddr_a;
	assign rf_waddr_wb_o = rf_waddr_wb;
	assign rf_we_wb_o = rf_we_wb;
	assign rf_raddr_b_o = rf_raddr_b;
	function automatic [34:0] sv2v_cast_11991;
		input reg [34:0] inp;
		sv2v_cast_11991 = inp;
	endfunction
	function automatic [34:0] ibex_cheriot_pkg_cheriot_regcap_to_vec;
		input reg [34:0] cap;
		ibex_cheriot_pkg_cheriot_regcap_to_vec = sv2v_cast_11991(cap);
	endfunction
	generate
		if (RegFileECC) begin : gen_regfile_ecc
			wire [1:0] rf_ecc_err_a;
			wire [1:0] rf_ecc_err_b;
			wire rf_ecc_err_a_id;
			wire rf_ecc_err_b_id;
			prim_secded_inv_39_32_enc regfile_ecc_enc(
				.data_i(rf_wdata_wb),
				.data_o(rf_wdata_wb_ecc_o)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_a(
				.data_i(rf_rdata_a_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_a)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_b(
				.data_i(rf_rdata_b_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_b)
			);
			assign rf_rdata_a = rf_rdata_a_ecc_i[31:0];
			assign rf_rdata_b = rf_rdata_b_ecc_i[31:0];
			if (BaseIsa == 32'sd1) begin : gen_cheriot_cap_ecc
				wire [1:0] rf_cap_ecc_err_a;
				wire [1:0] rf_cap_ecc_err_b;
				wire [63:0] wcap_ecc_tmp;
				wire [56:0] unused_wcap_ecc_tmp;
				prim_secded_inv_64_57_enc regfile_cap_ecc_enc(
					.data_i({22'b0000000000000000000000, ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)}),
					.data_o(wcap_ecc_tmp)
				);
				assign rf_wcap_ecc_wb_o = {wcap_ecc_tmp[63:57], ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)};
				assign unused_wcap_ecc_tmp = wcap_ecc_tmp[56:0];
				prim_secded_inv_64_57_dec regfile_cap_ecc_dec_a(
					.data_i({rf_rcap_a_ecc_i[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W], 22'b0000000000000000000000, rf_rcap_a_ecc_i[34:0]}),
					.data_o(),
					.syndrome_o(),
					.err_o(rf_cap_ecc_err_a)
				);
				prim_secded_inv_64_57_dec regfile_cap_ecc_dec_b(
					.data_i({rf_rcap_b_ecc_i[RegFileCapEccWidth - 1:ibex_cheriot_pkg_REGCAP_W], 22'b0000000000000000000000, rf_rcap_b_ecc_i[34:0]}),
					.data_o(),
					.syndrome_o(),
					.err_o(rf_cap_ecc_err_b)
				);
				assign rf_ecc_err_a_id = ((|rf_ecc_err_a | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & |rf_cap_ecc_err_a)) & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
				assign rf_ecc_err_b_id = ((|rf_ecc_err_b | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & |rf_cap_ecc_err_b)) & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
				assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
			end
			else begin : gen_no_cheriot_cap_ecc
				wire unused_rf_cap_ecc_i;
				assign unused_rf_cap_ecc_i = ^rf_rcap_a_ecc_i ^ ^rf_rcap_b_ecc_i;
				assign rf_wcap_ecc_wb_o = {7'b0000000, ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb)};
				assign rf_ecc_err_a_id = (|rf_ecc_err_a & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
				assign rf_ecc_err_b_id = (|rf_ecc_err_b & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
				assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
			end
		end
		else begin : gen_no_regfile_ecc
			wire unused_rf_ren_a;
			wire unused_rf_ren_b;
			wire unused_rf_rd_a_wb_match;
			wire unused_rf_rd_b_wb_match;
			assign unused_rf_ren_a = rf_ren_a;
			assign unused_rf_ren_b = rf_ren_b;
			assign unused_rf_rd_a_wb_match = rf_rd_a_wb_match;
			assign unused_rf_rd_b_wb_match = rf_rd_b_wb_match;
			assign rf_wdata_wb_ecc_o = rf_wdata_wb;
			assign rf_wcap_ecc_wb_o = ibex_cheriot_pkg_cheriot_regcap_to_vec(rf_wcap_wb);
			assign rf_rdata_a = rf_rdata_a_ecc_i;
			assign rf_rdata_b = rf_rdata_b_ecc_i;
			assign rf_ecc_err_comb = 1'b0;
		end
	endgenerate
	wire [31:0] crash_dump_mtval;
	assign crash_dump_o[159-:32] = pc_id;
	assign crash_dump_o[127-:32] = pc_if;
	assign crash_dump_o[95-:32] = lsu_addr_last;
	assign crash_dump_o[63-:32] = csr_mepc;
	assign crash_dump_o[31-:32] = crash_dump_mtval;
	assign alert_minor_o = icache_ecc_error;
	generate
		if (BaseIsa == 32'sd1) begin : gen_cheriot_enable_check
			assign cheriot_enable_mubi_err = instr_exec & !((cheriot_enable_i == ibex_pkg_IbexMuBiOn) || (cheriot_enable_i == ibex_pkg_IbexMuBiOff));
		end
		else begin : gen_no_cheriot_enable_check
			assign cheriot_enable_mubi_err = 1'b0;
		end
	endgenerate
	assign alert_major_internal_o = (((rf_ecc_err_comb | pc_mismatch_alert) | csr_shadow_err) | cheriot_fatal_err) | cheriot_enable_mubi_err;
	assign alert_major_bus_o = (lsu_load_resp_intg_err | lsu_store_resp_intg_err) | instr_intg_err;
	assign csr_wdata = alu_operand_a_ex;
	ibex_cs_registers #(
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.DataIndTiming(DataIndTiming),
		.DummyInstructions(DummyInstructions),
		.ShadowCSR(ShadowCSR),
		.ICache(ICache),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.CsrMvendorId(CsrMvendorId),
		.CsrMimpId(CsrMimpId),
		.BaseIsa(BaseIsa)
	) cs_registers_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.cheriot_enable_i(cheriot_enable_i),
		.hart_id_i(hart_id_i),
		.priv_mode_id_o(priv_mode_id),
		.priv_mode_lsu_o(priv_mode_lsu),
		.csr_mtvec_o(csr_mtvec),
		.csr_mtvec_init_i(csr_mtvec_init),
		.boot_addr_i(boot_addr_i),
		.csr_access_i(csr_access),
		.csr_addr_i(csr_addr),
		.csr_wdata_i(csr_wdata),
		.csr_op_i(csr_op),
		.csr_op_en_i(csr_op_en),
		.csr_rdata_o(csr_rdata),
		.cheriot_csr_access_i(cheriot_csr_access),
		.cheriot_csr_addr_i(cheriot_csr_addr),
		.cheriot_csr_wdata_i(cheriot_csr_wdata),
		.cheriot_csr_wcap_i(cheriot_csr_wcap),
		.cheriot_csr_op_i(cheriot_csr_op),
		.cheriot_csr_op_en_i(cheriot_csr_op_en),
		.cheriot_csr_set_mie_i(cheriot_csr_set_mie),
		.cheriot_csr_clr_mie_i(cheriot_csr_clr_mie),
		.cheriot_csr_rdata_o(cheriot_csr_rdata),
		.cheriot_csr_rcap_o(cheriot_csr_rcap),
		.csr_mshwm_o(csr_mshwm),
		.csr_mshwmb_o(csr_mshwmb),
		.csr_mshwm_set_i(csr_mshwm_set),
		.csr_mshwm_new_i(csr_mshwm_new),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.nmi_mode_i(nmi_mode),
		.irq_pending_o(irq_pending_o),
		.irqs_o(irqs),
		.csr_mstatus_mie_o(csr_mstatus_mie),
		.csr_mstatus_tw_o(csr_mstatus_tw),
		.csr_mepc_o(csr_mepc),
		.csr_mtval_o(crash_dump_mtval),
		.csr_pmp_cfg_o(csr_pmp_cfg),
		.csr_pmp_addr_o(csr_pmp_addr),
		.csr_pmp_mseccfg_o(csr_pmp_mseccfg),
		.csr_depc_o(csr_depc),
		.debug_mode_i(debug_mode),
		.debug_mode_entering_i(debug_mode_entering),
		.debug_cause_i(debug_cause),
		.debug_csr_save_i(debug_csr_save),
		.debug_single_step_o(debug_single_step),
		.debug_ebreakm_o(debug_ebreakm),
		.debug_ebreaku_o(debug_ebreaku),
		.trigger_match_o(trigger_match),
		.pc_if_i(pc_if),
		.pc_id_i(pc_id),
		.pc_wb_i(pc_wb),
		.data_ind_timing_o(data_ind_timing),
		.dummy_instr_en_o(dummy_instr_en),
		.dummy_instr_mask_o(dummy_instr_mask),
		.dummy_instr_seed_en_o(dummy_instr_seed_en),
		.dummy_instr_seed_o(dummy_instr_seed),
		.icache_enable_o(icache_enable),
		.csr_shadow_err_o(csr_shadow_err),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.mcounteren_writable_i(mcounteren_writable_i),
		.csr_save_if_i(csr_save_if),
		.csr_save_id_i(csr_save_id),
		.csr_save_wb_i(csr_save_wb),
		.csr_restore_mret_i(csr_restore_mret_id),
		.csr_restore_dret_i(csr_restore_dret_id),
		.csr_save_cause_i(csr_save_cause),
		.csr_mepcc_clrtag_i(csr_mepcc_clrtag),
		.csr_mcause_i(exc_cause),
		.csr_mtval_i(csr_mtval),
		.illegal_csr_insn_o(illegal_csr_insn_id),
		.double_fault_seen_o(double_fault_seen_o),
		.instr_ret_i(perf_instr_ret_wb),
		.instr_ret_compressed_i(perf_instr_ret_compressed_wb),
		.instr_ret_spec_i(perf_instr_ret_wb_spec),
		.instr_ret_compressed_spec_i(perf_instr_ret_compressed_wb_spec),
		.iside_wait_i(perf_iside_wait),
		.jump_i(perf_jump),
		.branch_i(perf_branch),
		.branch_taken_i(perf_tbranch),
		.mem_load_i(perf_load),
		.mem_store_i(perf_store),
		.dside_wait_i(perf_dside_wait),
		.mul_wait_i(perf_mul_wait),
		.div_wait_i(perf_div_wait),
		.cheriot_branch_req_i(cheriot_branch_req),
		.cheriot_branch_target_i(branch_target_ex_cheriot),
		.pcc_cap_i(pcc_cap_w),
		.pcc_cap_o(pcc_cap_r),
		.csr_dbg_tclr_fault_o(csr_dbg_tclr_fault),
		.cheriot_fatal_err_o(cheriot_fatal_err)
	);
	generate
		if (PMPEnable) begin : g_pmp
			wire [31:0] pc_if_inc;
			wire [101:0] pmp_req_addr;
			wire [5:0] pmp_req_type;
			wire [5:0] pmp_priv_lvl;
			wire [0:2] pmp_req_err_raw;
			assign pc_if_inc = pc_if + 32'd2;
			if (BaseIsa == 32'sd1) begin : g_pmp_addr_gate
				assign pmp_req_addr[68+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, pc_if});
				assign pmp_req_addr[34+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, pc_if_inc});
				assign pmp_req_addr[0+:34] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? {34 {1'sb0}} : {2'b00, data_addr_o[31:0]});
			end
			else begin : g_pmp_addr_no_gate
				assign pmp_req_addr[68+:34] = {2'b00, pc_if};
				assign pmp_req_addr[34+:34] = {2'b00, pc_if_inc};
				assign pmp_req_addr[0+:34] = {2'b00, data_addr_o[31:0]};
			end
			assign pmp_req_type[4+:2] = 2'b00;
			assign pmp_priv_lvl[4+:2] = priv_mode_id;
			assign pmp_req_type[2+:2] = 2'b00;
			assign pmp_priv_lvl[2+:2] = priv_mode_id;
			assign pmp_req_type[0+:2] = (data_we_o ? 2'b01 : 2'b10);
			assign pmp_priv_lvl[0+:2] = priv_mode_lsu;
			ibex_pmp #(
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.PMPGranularity(PMPGranularity),
				.PMPNumChan(PMPNumChan),
				.PMPNumRegions(PMPNumRegions)
			) pmp_i(
				.csr_pmp_cfg_i(csr_pmp_cfg),
				.csr_pmp_addr_i(csr_pmp_addr),
				.csr_pmp_mseccfg_i(csr_pmp_mseccfg),
				.debug_mode_i(debug_mode),
				.priv_mode_i(pmp_priv_lvl),
				.pmp_req_addr_i(pmp_req_addr),
				.pmp_req_type_i(pmp_req_type),
				.pmp_req_err_o(pmp_req_err_raw)
			);
			if (BaseIsa == 32'sd1) begin : g_pmp_cheriot_gate
				assign pmp_req_err[ibex_pkg_PMP_I] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_I]);
				assign pmp_req_err[ibex_pkg_PMP_I2] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_I2]);
				assign pmp_req_err[ibex_pkg_PMP_D] = (cheriot_enable_i == ibex_pkg_IbexMuBiOn ? 1'b0 : pmp_req_err_raw[ibex_pkg_PMP_D]);
			end
			else begin : g_pmp_no_cheriot_gate
				assign pmp_req_err[ibex_pkg_PMP_I] = pmp_req_err_raw[ibex_pkg_PMP_I];
				assign pmp_req_err[ibex_pkg_PMP_I2] = pmp_req_err_raw[ibex_pkg_PMP_I2];
				assign pmp_req_err[ibex_pkg_PMP_D] = pmp_req_err_raw[ibex_pkg_PMP_D];
			end
		end
		else begin : g_no_pmp
			wire [1:0] unused_priv_lvl_ls;
			wire [(PMPNumRegions * 34) - 1:0] unused_csr_pmp_addr;
			wire [(PMPNumRegions * 6) - 1:0] unused_csr_pmp_cfg;
			wire [2:0] unused_csr_pmp_mseccfg;
			assign unused_priv_lvl_ls = priv_mode_lsu;
			assign unused_csr_pmp_addr = csr_pmp_addr;
			assign unused_csr_pmp_cfg = csr_pmp_cfg;
			assign unused_csr_pmp_mseccfg = csr_pmp_mseccfg;
			assign pmp_req_err[ibex_pkg_PMP_I] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_I2] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_D] = 1'b0;
		end
	endgenerate
	wire unused_instr_new_id;
	wire unused_instr_id_done;
	wire unused_instr_done_wb;
	wire unused_instr_expanded_id;
	wire unused_instr_gets_expanded_id;
	assign unused_instr_id_done = instr_id_done;
	assign unused_instr_new_id = instr_new_id;
	assign unused_instr_done_wb = instr_done_wb;
	assign unused_instr_expanded_id = ^instr_expanded_id;
	assign unused_instr_gets_expanded_id = ^instr_gets_expanded_id;
endmodule
