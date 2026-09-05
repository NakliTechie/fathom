module ibex_cs_registers (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	hart_id_i,
	priv_mode_id_o,
	priv_mode_lsu_o,
	csr_mstatus_tw_o,
	csr_mtvec_o,
	csr_mtvec_init_i,
	boot_addr_i,
	csr_access_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_op_en_i,
	csr_rdata_o,
	cheriot_csr_access_i,
	cheriot_csr_addr_i,
	cheriot_csr_wdata_i,
	cheriot_csr_wcap_i,
	cheriot_csr_op_i,
	cheriot_csr_op_en_i,
	cheriot_csr_set_mie_i,
	cheriot_csr_clr_mie_i,
	cheriot_csr_rdata_o,
	cheriot_csr_rcap_o,
	csr_mshwm_o,
	csr_mshwmb_o,
	csr_mshwm_set_i,
	csr_mshwm_new_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	nmi_mode_i,
	irq_pending_o,
	irqs_o,
	csr_mstatus_mie_o,
	csr_mepc_o,
	csr_mtval_o,
	csr_pmp_cfg_o,
	csr_pmp_addr_o,
	csr_pmp_mseccfg_o,
	debug_mode_i,
	debug_mode_entering_i,
	debug_cause_i,
	debug_csr_save_i,
	csr_depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	debug_ebreaku_o,
	trigger_match_o,
	pc_if_i,
	pc_id_i,
	pc_wb_i,
	data_ind_timing_o,
	dummy_instr_en_o,
	dummy_instr_mask_o,
	dummy_instr_seed_en_o,
	dummy_instr_seed_o,
	icache_enable_o,
	csr_shadow_err_o,
	ic_scr_key_valid_i,
	mcounteren_writable_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_save_wb_i,
	csr_restore_mret_i,
	csr_restore_dret_i,
	csr_save_cause_i,
	csr_mepcc_clrtag_i,
	csr_mcause_i,
	csr_mtval_i,
	illegal_csr_insn_o,
	double_fault_seen_o,
	instr_ret_i,
	instr_ret_compressed_i,
	instr_ret_spec_i,
	instr_ret_compressed_spec_i,
	iside_wait_i,
	jump_i,
	branch_i,
	branch_taken_i,
	mem_load_i,
	mem_store_i,
	dside_wait_i,
	mul_wait_i,
	div_wait_i,
	cheriot_branch_req_i,
	cheriot_branch_target_i,
	pcc_cap_i,
	pcc_cap_o,
	csr_dbg_tclr_fault_o,
	cheriot_fatal_err_o
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] DbgTriggerEn = 0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ShadowCSR = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [31:0] MHPMCounterNum = 10;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] PMPEnable = 0;
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
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [31:0] CsrMvendorId = 32'b00000000000000000000000000000000;
	parameter [31:0] CsrMimpId = 32'b00000000000000000000000000000000;
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	input wire [31:0] hart_id_i;
	output wire [1:0] priv_mode_id_o;
	output wire [1:0] priv_mode_lsu_o;
	output wire csr_mstatus_tw_o;
	output wire [31:0] csr_mtvec_o;
	input wire csr_mtvec_init_i;
	input wire [31:0] boot_addr_i;
	input wire csr_access_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	input wire [1:0] csr_op_i;
	input wire csr_op_en_i;
	output wire [31:0] csr_rdata_o;
	input wire cheriot_csr_access_i;
	input wire [4:0] cheriot_csr_addr_i;
	input wire [31:0] cheriot_csr_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] cheriot_csr_wcap_i;
	input wire [4:0] cheriot_csr_op_i;
	input wire cheriot_csr_op_en_i;
	input wire cheriot_csr_set_mie_i;
	input wire cheriot_csr_clr_mie_i;
	output reg [31:0] cheriot_csr_rdata_o;
	output reg [34:0] cheriot_csr_rcap_o;
	output wire [31:0] csr_mshwm_o;
	output wire [31:0] csr_mshwmb_o;
	input wire csr_mshwm_set_i;
	input wire [31:0] csr_mshwm_new_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire nmi_mode_i;
	output wire irq_pending_o;
	output wire [17:0] irqs_o;
	output wire csr_mstatus_mie_o;
	output wire [31:0] csr_mepc_o;
	output wire [31:0] csr_mtval_o;
	output wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_o;
	output wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_o;
	output wire [2:0] csr_pmp_mseccfg_o;
	input wire debug_mode_i;
	input wire debug_mode_entering_i;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] csr_depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	output wire debug_ebreaku_o;
	output wire trigger_match_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire [31:0] pc_wb_i;
	output wire data_ind_timing_o;
	output wire dummy_instr_en_o;
	output wire [2:0] dummy_instr_mask_o;
	output wire dummy_instr_seed_en_o;
	output wire [31:0] dummy_instr_seed_o;
	output wire icache_enable_o;
	output wire csr_shadow_err_o;
	input wire ic_scr_key_valid_i;
	input wire [3:0] mcounteren_writable_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_save_wb_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_dret_i;
	input wire csr_save_cause_i;
	input wire csr_mepcc_clrtag_i;
	input wire [6:0] csr_mcause_i;
	input wire [31:0] csr_mtval_i;
	output wire illegal_csr_insn_o;
	output reg double_fault_seen_o;
	input wire instr_ret_i;
	input wire instr_ret_compressed_i;
	input wire instr_ret_spec_i;
	input wire instr_ret_compressed_spec_i;
	input wire iside_wait_i;
	input wire jump_i;
	input wire branch_i;
	input wire branch_taken_i;
	input wire mem_load_i;
	input wire mem_store_i;
	input wire dside_wait_i;
	input wire mul_wait_i;
	input wire div_wait_i;
	input wire cheriot_branch_req_i;
	input wire [31:0] cheriot_branch_target_i;
	localparam [31:0] ibex_cheriot_pkg_ADDR_W = 32;
	input wire [111:0] pcc_cap_i;
	output wire [111:0] pcc_cap_o;
	output wire csr_dbg_tclr_fault_o;
	output wire cheriot_fatal_err_o;
	function automatic is_mml_m_exec_cfg;
		input reg [5:0] pmp_cfg;
		reg unused_cfg;
		reg value;
		begin
			unused_cfg = ^{pmp_cfg[4-:2]};
			value = 1'b0;
			if (pmp_cfg[5])
				(* full_case, parallel_case *)
				case ({pmp_cfg[0], pmp_cfg[1], pmp_cfg[2]})
					3'b001, 3'b010, 3'b011, 3'b101: value = 1'b1;
					default: value = 1'b0;
				endcase
			is_mml_m_exec_cfg = value;
		end
	endfunction
	localparam [31:0] RV32BExtra = (RV32B != 32'sd0 ? 1 : 0);
	localparam [31:0] RV32MEnabled = (RV32M == 32'sd0 ? 0 : 1);
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	localparam [31:0] MisaXBit = RV32BExtra | sv2v_cast_32(BaseIsa == 32'sd1);
	localparam [31:0] PMPAddrWidth = (PMPGranularity > 0 ? ibex_pkg_PMP_ADDR_MSB - PMPGranularity : 32);
	localparam [31:0] MHPMCOUNTER_BASE = 3;
	localparam [1:0] ibex_pkg_CSR_MISA_MXL = 2'd1;
	localparam [31:0] MISA_VALUE = ((((((((4 | (sv2v_cast_32(RV32E) << 4)) | 0) | (sv2v_cast_32(!RV32E) << 8)) | (RV32MEnabled << 12)) | 0) | 0) | 1048576) | (MisaXBit << 23)) | (sv2v_cast_32(ibex_pkg_CSR_MISA_MXL) << 30);
	reg [31:0] exception_pc;
	reg [1:0] priv_lvl_q;
	reg [1:0] priv_lvl_d;
	wire [5:0] mstatus_q;
	reg [5:0] mstatus_d;
	wire mstatus_err;
	reg mstatus_en;
	wire [17:0] mie_q;
	wire [17:0] mie_d;
	reg mie_en;
	wire [31:0] mscratch_q;
	reg mscratch_en;
	wire [31:0] mepc_q;
	reg [31:0] mepc_d;
	reg mepc_en;
	wire [6:0] mcause_q;
	reg [6:0] mcause_d;
	reg [34:0] mepc_cap;
	reg mcause_en;
	wire [31:0] mtval_q;
	reg [31:0] mtval_d;
	reg mtval_en;
	wire [31:0] mtvec_q;
	reg [31:0] mtvec_d;
	reg [34:0] mtvec_cap;
	wire mtvec_err;
	reg mtvec_en;
	wire [17:0] mip;
	wire [31:0] dcsr_q;
	reg [31:0] dcsr_d;
	reg dcsr_en;
	wire [31:0] depc_q;
	reg [31:0] depc_d;
	reg depc_en;
	reg [34:0] depc_cap;
	wire [31:0] dscratch0_q;
	wire [31:0] dscratch1_q;
	reg dscratch0_en;
	reg dscratch1_en;
	reg [34:0] dscratch0_cap;
	reg [34:0] dscratch1_cap;
	wire [31:0] mshwm_q;
	wire [31:0] mshwm_d;
	wire [31:0] mshwmb_q;
	reg mshwm_en;
	reg mshwmb_en;
	wire [31:0] cdbg_ctrl_q;
	reg cdbg_ctrl_en;
	reg [111:0] pcc_cap_q;
	reg [111:0] pcc_cap_d;
	wire [2:0] mstack_q;
	reg [2:0] mstack_d;
	reg mstack_en;
	wire [31:0] mstack_epc_q;
	reg [31:0] mstack_epc_d;
	wire [6:0] mstack_cause_q;
	reg [6:0] mstack_cause_d;
	reg [31:0] pmp_addr_rdata [0:15];
	localparam [31:0] ibex_pkg_PMP_CFG_W = 8;
	wire [7:0] pmp_cfg_rdata [0:15];
	wire pmp_csr_err;
	wire [2:0] pmp_mseccfg;
	wire [31:0] mcountinhibit;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcountinhibit_d;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcountinhibit_q;
	reg mcountinhibit_we;
	wire [31:0] mcounteren;
	reg [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcounteren_d;
	wire [(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0] mcounteren_q;
	reg mcounteren_we;
	wire [63:0] mhpmcounter [0:31];
	reg [31:0] mhpmcounter_we;
	reg [31:0] mhpmcounterh_we;
	reg [31:0] mhpmcounter_incr;
	reg [31:0] mhpmevent [0:31];
	wire [4:0] mhpmcounter_idx;
	wire unused_mhpmcounter_we_1;
	wire unused_mhpmcounterh_we_1;
	wire unused_mhpmcounter_incr_1;
	wire [63:0] minstret_next;
	wire [63:0] minstret_raw;
	wire [31:0] tselect_rdata;
	wire [31:0] tmatch_control_rdata;
	wire [31:0] tmatch_value_rdata;
	wire [7:0] cpuctrlsts_part_q;
	reg [7:0] cpuctrlsts_part_d;
	wire [7:0] cpuctrlsts_part_wdata_raw;
	wire [7:0] cpuctrlsts_part_wdata;
	reg cpuctrlsts_part_we;
	wire cpuctrlsts_part_err;
	wire cpuctrlsts_ic_scr_key_valid_q;
	wire cpuctrlsts_ic_scr_key_err;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	wire csr_we_int;
	wire csr_wr;
	reg dbg_csr;
	reg illegal_csr;
	wire illegal_csr_priv;
	wire illegal_csr_dbg;
	wire illegal_csr_write;
	wire [7:0] unused_boot_addr;
	wire [2:0] unused_csr_addr;
	wire mepc_en_combi;
	wire mepc_en_cheriot;
	wire [31:0] mepc_d_combi;
	wire mtvec_en_combi;
	wire mtvec_en_cheriot;
	wire [31:0] mtvec_d_combi;
	wire depc_en_combi;
	wire depc_en_cheriot;
	wire [31:0] depc_d_combi;
	wire dscratch0_en_combi;
	wire dscratch0_en_cheriot;
	wire [31:0] dscratch0_d_combi;
	wire dscratch1_en_combi;
	wire dscratch1_en_cheriot;
	wire [31:0] dscratch1_d_combi;
	assign unused_boot_addr = boot_addr_i[7:0];
	wire [31:0] misa_value_masked;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign misa_value_masked = {MISA_VALUE[31:24], (BaseIsa == 32'sd1 ? (cheriot_enable_i == ibex_pkg_IbexMuBiOn) || (RV32BExtra != 0) : MISA_VALUE[23]), MISA_VALUE[22:9], (BaseIsa == 32'sd1 ? cheriot_enable_i != ibex_pkg_IbexMuBiOn : MISA_VALUE[8]), MISA_VALUE[7:5], (BaseIsa == 32'sd1 ? cheriot_enable_i == ibex_pkg_IbexMuBiOn : MISA_VALUE[4]), MISA_VALUE[3:0]};
	wire [11:0] csr_addr;
	assign csr_addr = csr_addr_i;
	assign unused_csr_addr = csr_addr[7:5];
	assign mhpmcounter_idx = csr_addr[4:0];
	assign illegal_csr_dbg = dbg_csr & ~debug_mode_i;
	assign illegal_csr_priv = csr_addr[9:8] > priv_lvl_q;
	assign illegal_csr_write = (csr_addr[11:10] == 2'b11) && csr_wr;
	assign illegal_csr_insn_o = csr_access_i & (((illegal_csr | illegal_csr_write) | illegal_csr_priv) | illegal_csr_dbg);
	assign mip[17] = irq_software_i;
	assign mip[16] = irq_timer_i;
	assign mip[15] = irq_external_i;
	assign mip[14-:15] = irq_fast_i;
	localparam [31:0] ibex_pkg_CSR_MARCHID_CHERIOT_VALUE = 32'h00000ce1;
	localparam [31:0] ibex_pkg_CSR_MARCHID_VALUE = 32'h00000016;
	localparam [31:0] ibex_pkg_CSR_MCONFIGPTR_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_HIGH = 30;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_LOW = 16;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MML_BIT = 0;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MMWP_BIT = 1;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_RLB_BIT = 2;
	localparam [31:0] ibex_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MIE_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPIE_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH = 12;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW = 11;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPRV_BIT = 17;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_TW_BIT = 21;
	localparam [31:0] ibex_pkg_CSR_MTIX_BIT = 7;
	always @(*) begin
		if (_sv2v_0)
			;
		csr_rdata_int = 1'sb0;
		illegal_csr = 1'b0;
		dbg_csr = 1'b0;
		(* full_case, parallel_case *)
		case (csr_addr_i)
			12'hf11: csr_rdata_int = CsrMvendorId;
			12'hf12: csr_rdata_int = ((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn) ? ibex_pkg_CSR_MARCHID_CHERIOT_VALUE : ibex_pkg_CSR_MARCHID_VALUE);
			12'hf13: csr_rdata_int = CsrMimpId;
			12'hf14: csr_rdata_int = hart_id_i;
			12'hf15: csr_rdata_int = ibex_pkg_CSR_MCONFIGPTR_VALUE;
			12'h300: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT] = mstatus_q[5];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT] = mstatus_q[4];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW] = mstatus_q[3-:2];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT] = mstatus_q[1];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT] = mstatus_q[0];
			end
			12'h310: csr_rdata_int = 1'sb0;
			12'h30a, 12'h31a: csr_rdata_int = 1'sb0;
			12'h301: csr_rdata_int = misa_value_masked;
			12'h304: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mie_q[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mie_q[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mie_q[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mie_q[14-:15];
			end
			12'h306: csr_rdata_int = mcounteren;
			12'h340: csr_rdata_int = mscratch_q;
			12'h305:
				if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
					illegal_csr = 1'b1;
				else
					csr_rdata_int = mtvec_q;
			12'h341:
				if ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))
					illegal_csr = 1'b1;
				else
					csr_rdata_int = mepc_q;
			12'h342: csr_rdata_int = {mcause_q[5] | mcause_q[6], (mcause_q[6] ? {26 {1'b1}} : 26'b00000000000000000000000000), mcause_q[4:0]};
			12'h343: csr_rdata_int = mtval_q;
			12'h344: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mip[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mip[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mip[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mip[14-:15];
			end
			12'h747:
				if (PMPEnable && !((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))) begin
					csr_rdata_int = 1'sb0;
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT] = pmp_mseccfg[0];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT] = pmp_mseccfg[1];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT] = pmp_mseccfg[2];
				end
				else
					illegal_csr = 1'b1;
			12'h757:
				if (PMPEnable && !((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn)))
					csr_rdata_int = 1'sb0;
				else
					illegal_csr = 1'b1;
			12'h3a0: csr_rdata_int = {pmp_cfg_rdata[3], pmp_cfg_rdata[2], pmp_cfg_rdata[1], pmp_cfg_rdata[0]};
			12'h3a1: csr_rdata_int = {pmp_cfg_rdata[7], pmp_cfg_rdata[6], pmp_cfg_rdata[5], pmp_cfg_rdata[4]};
			12'h3a2: csr_rdata_int = {pmp_cfg_rdata[11], pmp_cfg_rdata[10], pmp_cfg_rdata[9], pmp_cfg_rdata[8]};
			12'h3a3: csr_rdata_int = {pmp_cfg_rdata[15], pmp_cfg_rdata[14], pmp_cfg_rdata[13], pmp_cfg_rdata[12]};
			12'h3b0: csr_rdata_int = pmp_addr_rdata[0];
			12'h3b1: csr_rdata_int = pmp_addr_rdata[1];
			12'h3b2: csr_rdata_int = pmp_addr_rdata[2];
			12'h3b3: csr_rdata_int = pmp_addr_rdata[3];
			12'h3b4: csr_rdata_int = pmp_addr_rdata[4];
			12'h3b5: csr_rdata_int = pmp_addr_rdata[5];
			12'h3b6: csr_rdata_int = pmp_addr_rdata[6];
			12'h3b7: csr_rdata_int = pmp_addr_rdata[7];
			12'h3b8: csr_rdata_int = pmp_addr_rdata[8];
			12'h3b9: csr_rdata_int = pmp_addr_rdata[9];
			12'h3ba: csr_rdata_int = pmp_addr_rdata[10];
			12'h3bb: csr_rdata_int = pmp_addr_rdata[11];
			12'h3bc: csr_rdata_int = pmp_addr_rdata[12];
			12'h3bd: csr_rdata_int = pmp_addr_rdata[13];
			12'h3be: csr_rdata_int = pmp_addr_rdata[14];
			12'h3bf: csr_rdata_int = pmp_addr_rdata[15];
			12'h7b0: begin
				csr_rdata_int = dcsr_q;
				dbg_csr = 1'b1;
			end
			12'h7b1: begin
				csr_rdata_int = depc_q;
				dbg_csr = 1'b1;
			end
			12'h7b2: begin
				csr_rdata_int = dscratch0_q;
				dbg_csr = 1'b1;
			end
			12'h7b3: begin
				csr_rdata_int = dscratch1_q;
				dbg_csr = 1'b1;
			end
			12'h320: csr_rdata_int = mcountinhibit;
			12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent[mhpmcounter_idx];
			12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
			12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
			12'hc00, 12'hc02, 12'hc03, 12'hc04, 12'hc05, 12'hc06, 12'hc07, 12'hc08, 12'hc09, 12'hc0a, 12'hc0b, 12'hc0c, 12'hc0d, 12'hc0e, 12'hc0f, 12'hc10, 12'hc11, 12'hc12, 12'hc13, 12'hc14, 12'hc15, 12'hc16, 12'hc17, 12'hc18, 12'hc19, 12'hc1a, 12'hc1b, 12'hc1c, 12'hc1d, 12'hc1e, 12'hc1f: begin
				csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
				illegal_csr = (priv_lvl_q == 2'b00) && !mcounteren[mhpmcounter_idx];
			end
			12'hc80, 12'hc82, 12'hc83, 12'hc84, 12'hc85, 12'hc86, 12'hc87, 12'hc88, 12'hc89, 12'hc8a, 12'hc8b, 12'hc8c, 12'hc8d, 12'hc8e, 12'hc8f, 12'hc90, 12'hc91, 12'hc92, 12'hc93, 12'hc94, 12'hc95, 12'hc96, 12'hc97, 12'hc98, 12'hc99, 12'hc9a, 12'hc9b, 12'hc9c, 12'hc9d, 12'hc9e, 12'hc9f: begin
				csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
				illegal_csr = (priv_lvl_q == 2'b00) && !mcounteren[mhpmcounter_idx];
			end
			12'h7a0: begin
				csr_rdata_int = tselect_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a1: begin
				csr_rdata_int = tmatch_control_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a2: begin
				csr_rdata_int = tmatch_value_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a3: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h5a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7aa: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7c0: csr_rdata_int = {{23 {1'b0}}, cpuctrlsts_ic_scr_key_valid_q, cpuctrlsts_part_q};
			12'h7c1: csr_rdata_int = 1'sb0;
			12'hbc1:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = mshwm_q;
				else
					illegal_csr = 1'b1;
			12'hbc2:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = mshwmb_q;
				else
					illegal_csr = 1'b1;
			12'hbc4:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					csr_rdata_int = cdbg_ctrl_q;
				else
					illegal_csr = 1'b1;
			default: illegal_csr = 1'b1;
		endcase
		if (!PMPEnable || ((BaseIsa == 32'sd1) && (cheriot_enable_i == ibex_pkg_IbexMuBiOn))) begin
			if (|{csr_addr == 12'h3a0, csr_addr == 12'h3a1, csr_addr == 12'h3a2, csr_addr == 12'h3a3, csr_addr == 12'h3b0, csr_addr == 12'h3b1, csr_addr == 12'h3b2, csr_addr == 12'h3b3, csr_addr == 12'h3b4, csr_addr == 12'h3b5, csr_addr == 12'h3b6, csr_addr == 12'h3b7, csr_addr == 12'h3b8, csr_addr == 12'h3b9, csr_addr == 12'h3ba, csr_addr == 12'h3bb, csr_addr == 12'h3bc, csr_addr == 12'h3bd, csr_addr == 12'h3be, csr_addr == 12'h3bf})
				illegal_csr = 1'b1;
		end
	end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		exception_pc = pc_id_i;
		priv_lvl_d = priv_lvl_q;
		mstatus_en = 1'b0;
		mstatus_d = mstatus_q;
		mie_en = 1'b0;
		mscratch_en = 1'b0;
		mepc_en = 1'b0;
		mepc_d = {csr_wdata_int[31:1], 1'b0};
		mcause_en = 1'b0;
		mcause_d = {csr_wdata_int[31:30] == 2'b11, csr_wdata_int[31:30] == 2'b10, csr_wdata_int[4:0]};
		mtval_en = 1'b0;
		mtval_d = csr_wdata_int;
		mtvec_en = csr_mtvec_init_i;
		mtvec_d = (csr_mtvec_init_i ? {boot_addr_i[31:8], 7'b0000000, ~((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn))} : {csr_wdata_int[31:8], 7'b0000000, ~((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn))});
		dcsr_en = 1'b0;
		dcsr_d = dcsr_q;
		depc_d = {csr_wdata_int[31:1], 1'b0};
		depc_en = 1'b0;
		dscratch0_en = 1'b0;
		dscratch1_en = 1'b0;
		mstack_en = 1'b0;
		mstack_d[2] = mstatus_q[4];
		mstack_d[1-:2] = mstatus_q[3-:2];
		mstack_epc_d = mepc_q;
		mstack_cause_d = mcause_q;
		mcountinhibit_we = 1'b0;
		mcounteren_we = 1'b0;
		mhpmcounter_we = 1'sb0;
		mhpmcounterh_we = 1'sb0;
		cpuctrlsts_part_we = 1'b0;
		cpuctrlsts_part_d = cpuctrlsts_part_q;
		mshwm_en = 1'b0;
		mshwmb_en = 1'b0;
		cdbg_ctrl_en = 1'b0;
		double_fault_seen_o = 1'b0;
		if (csr_we_int)
			(* full_case, parallel_case *)
			case (csr_addr_i)
				12'h300: begin
					mstatus_en = 1'b1;
					mstatus_d = {csr_wdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW]), csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT]};
					if ((mstatus_d[3-:2] != 2'b11) && (mstatus_d[3-:2] != 2'b00))
						mstatus_d[3-:2] = 2'b00;
				end
				12'h304: mie_en = 1'b1;
				12'h340: mscratch_en = 1'b1;
				12'h341: mepc_en = ~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn);
				12'h342: mcause_en = 1'b1;
				12'h343: mtval_en = 1'b1;
				12'h305: mtvec_en = ~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn);
				12'h7b0: begin
					dcsr_d = csr_wdata_int;
					dcsr_d[31-:4] = 4'd4;
					if ((dcsr_d[1-:2] != 2'b11) && (dcsr_d[1-:2] != 2'b00))
						dcsr_d[1-:2] = 2'b00;
					dcsr_d[8-:3] = dcsr_q[8-:3];
					dcsr_d[11] = 1'b0;
					dcsr_d[3] = 1'b0;
					dcsr_d[4] = 1'b0;
					dcsr_d[10] = 1'b0;
					dcsr_d[9] = 1'b0;
					dcsr_d[5] = 1'b0;
					dcsr_d[14] = 1'b0;
					dcsr_d[27-:12] = 12'h000;
					dcsr_en = 1'b1;
				end
				12'h7b1: depc_en = 1'b1;
				12'h7b2: dscratch0_en = 1'b1;
				12'h7b3: dscratch1_en = 1'b1;
				12'h306: mcounteren_we = mcounteren_writable_i == ibex_pkg_IbexMuBiOn;
				12'h320: mcountinhibit_we = 1'b1;
				12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: mhpmcounter_we[mhpmcounter_idx] = 1'b1;
				12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: mhpmcounterh_we[mhpmcounter_idx] = 1'b1;
				12'h7c0: begin
					cpuctrlsts_part_d = cpuctrlsts_part_wdata;
					cpuctrlsts_part_we = 1'b1;
				end
				12'hbc1: mshwm_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				12'hbc2: mshwmb_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				12'hbc4: cdbg_ctrl_en = (BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
				default:
					;
			endcase
		(* full_case, parallel_case *)
		case (1'b1)
			csr_save_cause_i: begin
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_if_i: exception_pc = pc_if_i;
					csr_save_id_i: exception_pc = pc_id_i;
					csr_save_wb_i: exception_pc = pc_wb_i;
					default:
						;
				endcase
				priv_lvl_d = 2'b11;
				if (debug_csr_save_i) begin
					dcsr_d[1-:2] = priv_lvl_q;
					dcsr_d[8-:3] = debug_cause_i;
					dcsr_en = 1'b1;
					depc_d = exception_pc;
					depc_en = 1'b1;
				end
				else if (!debug_mode_i) begin
					mtval_en = 1'b1;
					mtval_d = csr_mtval_i;
					mstatus_en = 1'b1;
					mstatus_d[5] = 1'b0;
					mstatus_d[4] = mstatus_q[5];
					mstatus_d[3-:2] = priv_lvl_q;
					mepc_en = 1'b1;
					mepc_d = exception_pc;
					mcause_en = 1'b1;
					mcause_d = csr_mcause_i;
					mstack_en = 1'b1;
					if (!(mcause_d[5] || mcause_d[6])) begin
						cpuctrlsts_part_we = 1'b1;
						cpuctrlsts_part_d[6] = 1'b1;
						if (cpuctrlsts_part_q[6]) begin
							double_fault_seen_o = 1'b1;
							cpuctrlsts_part_d[7] = 1'b1;
						end
					end
				end
			end
			csr_restore_dret_i: priv_lvl_d = dcsr_q[1-:2];
			csr_restore_mret_i: begin
				priv_lvl_d = mstatus_q[3-:2];
				mstatus_en = 1'b1;
				mstatus_d[5] = mstatus_q[4];
				if (mstatus_q[3-:2] != 2'b11)
					mstatus_d[1] = 1'b0;
				cpuctrlsts_part_we = 1'b1;
				cpuctrlsts_part_d[6] = 1'b0;
				if (nmi_mode_i) begin
					mstatus_d[4] = mstack_q[2];
					mstatus_d[3-:2] = mstack_q[1-:2];
					mepc_en = 1'b1;
					mepc_d = mstack_epc_q;
					mcause_en = 1'b1;
					mcause_d = mstack_cause_q;
				end
				else begin
					mstatus_d[4] = 1'b1;
					mstatus_d[3-:2] = 2'b00;
				end
			end
			default:
				;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			priv_lvl_q <= 2'b11;
		else
			priv_lvl_q <= priv_lvl_d;
	assign priv_mode_id_o = priv_lvl_q;
	assign priv_mode_lsu_o = (mstatus_q[1] ? mstatus_q[3-:2] : priv_lvl_q);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (csr_op_i)
			2'd1: csr_wdata_int = csr_wdata_i;
			2'd2: csr_wdata_int = csr_wdata_i | csr_rdata_o;
			2'd3: csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			2'd0: csr_wdata_int = csr_wdata_i;
			default: csr_wdata_int = csr_wdata_i;
		endcase
	end
	assign csr_wr = |{csr_op_i == 2'd1, csr_op_i == 2'd2, csr_op_i == 2'd3};
	assign csr_we_int = ((csr_wr & csr_op_en_i) & (((~(BaseIsa == 32'sd1) | (cheriot_enable_i != ibex_pkg_IbexMuBiOn)) | debug_mode_i) | pcc_cap_q[42])) & ~illegal_csr_insn_o;
	assign csr_rdata_o = csr_rdata_int;
	assign csr_mepc_o = mepc_q;
	assign csr_depc_o = depc_q;
	assign csr_mtvec_o = mtvec_q;
	assign csr_mtval_o = mtval_q;
	assign csr_mshwm_o = mshwm_q;
	assign csr_mshwmb_o = mshwmb_q;
	assign csr_mstatus_mie_o = mstatus_q[5];
	assign csr_mstatus_tw_o = mstatus_q[0];
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	assign debug_ebreaku_o = dcsr_q[12];
	assign irqs_o = mip & mie_q;
	assign irq_pending_o = |irqs_o;
	localparam [5:0] MSTATUS_RST_VAL = 6'b010000;
	wire mstatus_en_combi;
	reg [5:0] mstatus_d_combi;
	assign mstatus_en_combi = mstatus_en | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & (cheriot_csr_clr_mie_i | cheriot_csr_set_mie_i));
	always @(*) begin
		if (_sv2v_0)
			;
		mstatus_d_combi = mstatus_d;
		mstatus_d_combi[5] = (mstatus_d[5] & ~((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_csr_clr_mie_i)) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_csr_set_mie_i);
	end
	ibex_csr #(
		.Width(6),
		.ShadowCopy(ShadowCSR),
		.ResetValue({MSTATUS_RST_VAL})
	) u_mstatus_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstatus_d_combi}),
		.wr_en_i(mstatus_en_combi),
		.rd_data_o(mstatus_q),
		.rd_error_o(mstatus_err)
	);
	assign mepc_en_combi = mepc_en | mepc_en_cheriot;
	assign mepc_d_combi = ({32 {mepc_en}} & mepc_d) | ({32 {mepc_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mepc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mepc_d_combi),
		.wr_en_i(mepc_en_combi),
		.rd_data_o(mepc_q),
		.rd_error_o()
	);
	assign mie_d[17] = csr_wdata_int[ibex_pkg_CSR_MSIX_BIT];
	assign mie_d[16] = csr_wdata_int[ibex_pkg_CSR_MTIX_BIT];
	assign mie_d[15] = csr_wdata_int[ibex_pkg_CSR_MEIX_BIT];
	assign mie_d[14-:15] = csr_wdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW];
	ibex_csr #(
		.Width(18),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mie_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mie_d}),
		.wr_en_i(mie_en),
		.rd_data_o(mie_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mscratch_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(mscratch_en),
		.rd_data_o(mscratch_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mcause_d}),
		.wr_en_i(mcause_en),
		.rd_data_o(mcause_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mtval_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtval_d),
		.wr_en_i(mtval_en),
		.rd_data_o(mtval_q),
		.rd_error_o()
	);
	assign mtvec_en_combi = mtvec_en | mtvec_en_cheriot;
	assign mtvec_d_combi = ({32 {mtvec_en}} & mtvec_d) | ({32 {mtvec_en_cheriot}} & {cheriot_csr_wdata_i[31:2], 2'b00});
	ibex_csr #(
		.Width(32),
		.ShadowCopy(ShadowCSR),
		.ResetValue(32'd1)
	) u_mtvec_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtvec_d_combi),
		.wr_en_i(mtvec_en_combi),
		.rd_data_o(mtvec_q),
		.rd_error_o(mtvec_err)
	);
	localparam [31:0] DCSR_RESET_VAL = 32'h40000003;
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue({DCSR_RESET_VAL})
	) u_dcsr_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({dcsr_d}),
		.wr_en_i(dcsr_en),
		.rd_data_o(dcsr_q),
		.rd_error_o()
	);
	assign depc_en_combi = depc_en | depc_en_cheriot;
	assign depc_d_combi = ({32 {depc_en}} & depc_d) | ({32 {depc_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_depc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(depc_d_combi),
		.wr_en_i(depc_en_combi),
		.rd_data_o(depc_q),
		.rd_error_o()
	);
	assign dscratch0_en_combi = dscratch0_en | dscratch0_en_cheriot;
	assign dscratch0_d_combi = ({32 {dscratch0_en}} & csr_wdata_int) | ({32 {dscratch0_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch0_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(dscratch0_d_combi),
		.wr_en_i(dscratch0_en_combi),
		.rd_data_o(dscratch0_q),
		.rd_error_o()
	);
	assign dscratch1_en_combi = dscratch1_en | dscratch1_en_cheriot;
	assign dscratch1_d_combi = ({32 {dscratch1_en}} & csr_wdata_int) | ({32 {dscratch1_en_cheriot}} & cheriot_csr_wdata_i);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch1_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(dscratch1_d_combi),
		.wr_en_i(dscratch1_en_combi),
		.rd_data_o(dscratch1_q),
		.rd_error_o()
	);
	localparam [2:0] MSTACK_RESET_VAL = 3'b100;
	ibex_csr #(
		.Width(3),
		.ShadowCopy(1'b0),
		.ResetValue({MSTACK_RESET_VAL})
	) u_mstack_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstack_d}),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_epc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_epc_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_epc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_cause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_cause_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_cause_q),
		.rd_error_o()
	);
	wire mshwm_en_combi;
	assign mshwm_en_combi = mshwm_en | csr_mshwm_set_i;
	assign mshwm_d = (csr_mshwm_set_i ? csr_mshwm_new_i : {csr_wdata_int[31:4], 4'h0});
	generate
		if (BaseIsa == 32'sd1) begin : g_mshwm
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_mshwm_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(mshwm_d),
				.wr_en_i(mshwm_en_combi),
				.rd_data_o(mshwm_q),
				.rd_error_o()
			);
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_mshwmb_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i({csr_wdata_int[31:4], 4'h0}),
				.wr_en_i(mshwmb_en),
				.rd_data_o(mshwmb_q),
				.rd_error_o()
			);
			ibex_csr #(
				.Width(32),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'sb0)
			) u_cdbg_ctrl_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i({31'h00000000, csr_wdata_int[0]}),
				.wr_en_i(cdbg_ctrl_en),
				.rd_data_o(cdbg_ctrl_q),
				.rd_error_o()
			);
			assign csr_dbg_tclr_fault_o = cdbg_ctrl_q[0];
		end
		else begin : g_mshwm_tieoff
			assign mshwm_q = 1'sb0;
			assign mshwmb_q = 1'sb0;
			assign cdbg_ctrl_q = 1'sb0;
			assign csr_dbg_tclr_fault_o = 1'b0;
			wire unused_mshwm_sigs;
			assign unused_mshwm_sigs = ^{mshwm_d, mshwmb_en, cdbg_ctrl_en, mshwm_en_combi};
		end
	endgenerate
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_ADDR = 12'h3b0;
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_CFG = 12'h3a0;
	generate
		if (PMPEnable) begin : g_pmp_registers
			wire [2:0] pmp_mseccfg_q;
			wire [2:0] pmp_mseccfg_d;
			wire pmp_mseccfg_we;
			wire pmp_mseccfg_err;
			wire [5:0] pmp_cfg [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_locked;
			wire [PMPNumRegions - 1:0] pmp_cfg_wr_suppress;
			reg [5:0] pmp_cfg_wdata [0:PMPNumRegions - 1];
			wire [PMPAddrWidth - 1:0] pmp_addr [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_we;
			wire [PMPNumRegions - 1:0] pmp_cfg_err;
			wire [PMPNumRegions - 1:0] pmp_addr_we;
			wire [PMPNumRegions - 1:0] pmp_addr_err;
			wire any_pmp_entry_locked;
			genvar _gv_i_1;
			for (_gv_i_1 = 0; _gv_i_1 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_1 = _gv_i_1 + 1) begin : g_exp_rd_data
				localparam i = _gv_i_1;
				if (i < PMPNumRegions) begin : g_implemented_regions
					assign pmp_cfg_rdata[i] = {pmp_cfg[i][5], 2'b00, pmp_cfg[i][4-:2], pmp_cfg[i][2], pmp_cfg[i][1], pmp_cfg[i][0]};
					if (PMPGranularity == 0) begin : g_pmp_g0
						wire [32:1] sv2v_tmp_66180;
						assign sv2v_tmp_66180 = pmp_addr[i];
						always @(*) pmp_addr_rdata[i] = sv2v_tmp_66180;
					end
					else if (PMPGranularity == 1) begin : g_pmp_g1
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = pmp_addr[i];
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
					else begin : g_pmp_g2
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = {pmp_addr[i], {PMPGranularity - 1 {1'b1}}};
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
				end
				else begin : g_other_regions
					assign pmp_cfg_rdata[i] = 1'sb0;
					wire [32:1] sv2v_tmp_8D4C0;
					assign sv2v_tmp_8D4C0 = 1'sb0;
					always @(*) pmp_addr_rdata[i] = sv2v_tmp_8D4C0;
				end
			end
			genvar _gv_i_2;
			for (_gv_i_2 = 0; _gv_i_2 < PMPNumRegions; _gv_i_2 = _gv_i_2 + 1) begin : g_pmp_csrs
				localparam i = _gv_i_2;
				assign pmp_cfg_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & ~pmp_cfg_wr_suppress[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_CFG + (i[11:0] >> 2)));
				wire [1:1] sv2v_tmp_54F96;
				assign sv2v_tmp_54F96 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 7];
				always @(*) pmp_cfg_wdata[i][5] = sv2v_tmp_54F96;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 3+:2])
						2'b00: pmp_cfg_wdata[i][4-:2] = 2'b00;
						2'b01: pmp_cfg_wdata[i][4-:2] = 2'b01;
						2'b10: pmp_cfg_wdata[i][4-:2] = (PMPGranularity == 0 ? 2'b10 : 2'b00);
						2'b11: pmp_cfg_wdata[i][4-:2] = 2'b11;
						default: pmp_cfg_wdata[i][4-:2] = 2'b00;
					endcase
				end
				wire [1:1] sv2v_tmp_A8DD4;
				assign sv2v_tmp_A8DD4 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 2];
				always @(*) pmp_cfg_wdata[i][2] = sv2v_tmp_A8DD4;
				wire [1:1] sv2v_tmp_B6327;
				assign sv2v_tmp_B6327 = (pmp_mseccfg_q[0] ? csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 1] : &csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W+:2]);
				always @(*) pmp_cfg_wdata[i][1] = sv2v_tmp_B6327;
				wire [1:1] sv2v_tmp_2F5D5;
				assign sv2v_tmp_2F5D5 = csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W];
				always @(*) pmp_cfg_wdata[i][0] = sv2v_tmp_2F5D5;
				ibex_csr #(
					.Width(6),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstCfg[(15 - i) * 6+:6])
				) u_pmp_cfg_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i({pmp_cfg_wdata[i]}),
					.wr_en_i(pmp_cfg_we[i]),
					.rd_data_o(pmp_cfg[i]),
					.rd_error_o(pmp_cfg_err[i])
				);
				assign pmp_cfg_locked[i] = pmp_cfg[i][5] & ~pmp_mseccfg_q[2];
				assign pmp_cfg_wr_suppress[i] = (pmp_mseccfg_q[0] & ~pmp_mseccfg_q[2]) & is_mml_m_exec_cfg(pmp_cfg_wdata[i]);
				if (i < (PMPNumRegions - 1)) begin : g_lower
					assign pmp_addr_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & (~pmp_cfg_locked[i + 1] | (pmp_cfg[i + 1][4-:2] != 2'b01))) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				else begin : g_upper
					assign pmp_addr_we[i] = (csr_we_int & ~pmp_cfg_locked[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				ibex_csr #(
					.Width(PMPAddrWidth),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstAddr[((15 - i) * 34) + ibex_pkg_PMP_ADDR_MSB-:PMPAddrWidth])
				) u_pmp_addr_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(csr_wdata_int[31-:PMPAddrWidth]),
					.wr_en_i(pmp_addr_we[i]),
					.rd_data_o(pmp_addr[i]),
					.rd_error_o(pmp_addr_err[i])
				);
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = pmp_cfg[i];
				assign csr_pmp_addr_o[0 + (((PMPNumRegions - 1) - i) * 34)+:34] = {pmp_addr_rdata[i], 2'b00};
			end
			assign pmp_mseccfg_we = csr_we_int & (csr_addr == 12'h747);
			assign pmp_mseccfg_d[0] = (pmp_mseccfg_q[0] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT]);
			assign pmp_mseccfg_d[1] = (pmp_mseccfg_q[1] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT]);
			assign any_pmp_entry_locked = |pmp_cfg_locked;
			assign pmp_mseccfg_d[2] = (any_pmp_entry_locked ? 1'b0 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT]);
			ibex_csr #(
				.Width(3),
				.ShadowCopy(ShadowCSR),
				.ResetValue(PMPRstMsecCfg)
			) u_pmp_mseccfg(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(pmp_mseccfg_d),
				.wr_en_i(pmp_mseccfg_we),
				.rd_data_o(pmp_mseccfg_q),
				.rd_error_o(pmp_mseccfg_err)
			);
			assign pmp_csr_err = (|pmp_cfg_err | (|pmp_addr_err)) | pmp_mseccfg_err;
			assign pmp_mseccfg = pmp_mseccfg_q;
		end
		else begin : g_no_pmp_tieoffs
			genvar _gv_i_3;
			for (_gv_i_3 = 0; _gv_i_3 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_3 = _gv_i_3 + 1) begin : g_rdata
				localparam i = _gv_i_3;
				wire [32:1] sv2v_tmp_8D4C0;
				assign sv2v_tmp_8D4C0 = 1'sb0;
				always @(*) pmp_addr_rdata[i] = sv2v_tmp_8D4C0;
				assign pmp_cfg_rdata[i] = 1'sb0;
			end
			genvar _gv_i_4;
			for (_gv_i_4 = 0; _gv_i_4 < PMPNumRegions; _gv_i_4 = _gv_i_4 + 1) begin : g_outputs
				localparam i = _gv_i_4;
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = 6'b000000;
				assign csr_pmp_addr_o[0 + (((PMPNumRegions - 1) - i) * 34)+:34] = 1'sb0;
			end
			assign pmp_csr_err = 1'b0;
			assign pmp_mseccfg = 1'sb0;
		end
	endgenerate
	assign csr_pmp_mseccfg_o = pmp_mseccfg;
	always @(*) begin : mcountinhibit_update
		if (_sv2v_0)
			;
		if (mcountinhibit_we == 1'b1) begin
			mcountinhibit_d = csr_wdata_int[(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0];
			mcountinhibit_d[1] = 1'b0;
		end
		else
			mcountinhibit_d = mcountinhibit_q;
	end
	always @(*) begin : mcounteren_update
		if (_sv2v_0)
			;
		if (mcounteren_we == 1'b1) begin
			mcounteren_d = csr_wdata_int[(MHPMCounterNum + MHPMCOUNTER_BASE) - 1:0];
			mcounteren_d[1] = 1'b0;
		end
		else
			mcounteren_d = mcounteren_q;
	end
	always @(*) begin : gen_mhpmcounter_incr
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmcounter_incr_inactive
					mhpmcounter_incr[i] = 1'b0;
				end
		end
		mhpmcounter_incr[0] = 1'b1;
		mhpmcounter_incr[1] = 1'b0;
		mhpmcounter_incr[2] = instr_ret_i;
		mhpmcounter_incr[3] = dside_wait_i;
		mhpmcounter_incr[4] = iside_wait_i;
		mhpmcounter_incr[5] = mem_load_i;
		mhpmcounter_incr[6] = mem_store_i;
		mhpmcounter_incr[7] = jump_i;
		mhpmcounter_incr[8] = branch_i;
		mhpmcounter_incr[9] = branch_taken_i;
		mhpmcounter_incr[10] = instr_ret_compressed_i;
		mhpmcounter_incr[11] = mul_wait_i;
		mhpmcounter_incr[12] = div_wait_i;
	end
	always @(*) begin : gen_mhpmevent
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmevent_active
					mhpmevent[i] = 1'sb0;
					if (i >= MHPMCOUNTER_BASE)
						mhpmevent[i][i - MHPMCOUNTER_BASE] = 1'b1;
				end
		end
		mhpmevent[1] = 1'sb0;
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = MHPMCOUNTER_BASE + MHPMCounterNum; i < 32; i = i + 1)
				begin : gen_mhpmevent_inactive
					mhpmevent[i] = 1'sb0;
				end
		end
	end
	ibex_counter #(.CounterWidth(64)) mcycle_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[0] & ~mcountinhibit[0]),
		.counterh_we_i(mhpmcounterh_we[0]),
		.counter_we_i(mhpmcounter_we[0]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(mhpmcounter[0]),
		.counter_val_upd_o()
	);
	ibex_counter #(
		.CounterWidth(64),
		.ProvideValUpd(1)
	) minstret_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[2] & ~mcountinhibit[2]),
		.counterh_we_i(mhpmcounterh_we[2]),
		.counter_we_i(mhpmcounter_we[2]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(minstret_raw),
		.counter_val_upd_o(minstret_next)
	);
	assign mhpmcounter[2] = (instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw);
	assign mhpmcounter[1] = 1'sb0;
	assign unused_mhpmcounter_we_1 = mhpmcounter_we[1];
	assign unused_mhpmcounterh_we_1 = mhpmcounterh_we[1];
	assign unused_mhpmcounter_incr_1 = mhpmcounter_incr[1];
	genvar _gv_i_5;
	generate
		for (_gv_i_5 = 0; _gv_i_5 < 29; _gv_i_5 = _gv_i_5 + 1) begin : gen_cntrs
			localparam i = _gv_i_5;
			localparam signed [31:0] Cnt = i + MHPMCOUNTER_BASE;
			if (i < MHPMCounterNum) begin : gen_imp
				wire [63:0] mhpmcounter_raw;
				wire [63:0] mhpmcounter_next;
				ibex_counter #(
					.CounterWidth(MHPMCounterWidth),
					.ProvideValUpd(Cnt == 10)
				) mcounters_variable_i(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.counter_inc_i(mhpmcounter_incr[Cnt] & ~mcountinhibit[Cnt]),
					.counterh_we_i(mhpmcounterh_we[Cnt]),
					.counter_we_i(mhpmcounter_we[Cnt]),
					.counter_val_i(csr_wdata_int),
					.counter_val_o(mhpmcounter_raw),
					.counter_val_upd_o(mhpmcounter_next)
				);
				if (Cnt == 10) begin : gen_compressed_instr_cnt
					assign mhpmcounter[Cnt] = (instr_ret_compressed_spec_i & ~mcountinhibit[Cnt] ? mhpmcounter_next : mhpmcounter_raw);
				end
				else begin : gen_other_cnts
					wire [63:0] unused_mhpmcounter_next;
					assign mhpmcounter[Cnt] = mhpmcounter_raw;
					assign unused_mhpmcounter_next = mhpmcounter_next;
				end
			end
			else begin : gen_unimp
				assign mhpmcounter[Cnt] = 1'sb0;
				if (Cnt == 10) begin : gen_no_compressed_instr_cnt
					wire unused_instr_ret_compressed_spec_i;
					assign unused_instr_ret_compressed_spec_i = instr_ret_compressed_spec_i;
				end
			end
		end
		if (MHPMCounterNum < 29) begin : g_mcountinhibit_reduced
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounterh_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_incr;
			assign mcountinhibit = {{29 - MHPMCounterNum {1'b0}}, mcountinhibit_q};
			assign unused_mhphcounter_we = mhpmcounter_we[31:MHPMCounterNum + MHPMCOUNTER_BASE];
			assign unused_mhphcounterh_we = mhpmcounterh_we[31:MHPMCounterNum + MHPMCOUNTER_BASE];
			assign unused_mhphcounter_incr = mhpmcounter_incr[31:MHPMCounterNum + MHPMCOUNTER_BASE];
		end
		else begin : g_mcountinhibit_full
			assign mcountinhibit = mcountinhibit_q;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mcountinhibit_q <= 1'sb0;
		else
			mcountinhibit_q <= mcountinhibit_d;
	generate
		if (MHPMCounterNum < 29) begin : g_mcounteren_reduced
			assign mcounteren = {{29 - MHPMCounterNum {1'b0}}, mcounteren_q};
		end
		else begin : g_mcounteren_full
			assign mcounteren = mcounteren_q;
		end
	endgenerate
	ibex_csr #(
		.Width(MHPMCounterNum + MHPMCOUNTER_BASE),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcounteren_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mcounteren_d),
		.wr_en_i(mcounteren_we),
		.rd_data_o(mcounteren_q),
		.rd_error_o()
	);
	generate
		if (DbgTriggerEn) begin : gen_trigger_regs
			localparam [31:0] DbgHwNumLen = (DbgHwBreakNum > 1 ? $clog2(DbgHwBreakNum) : 1);
			localparam [31:0] MaxTselect = DbgHwBreakNum - 1;
			wire [DbgHwNumLen - 1:0] tselect_d;
			wire [DbgHwNumLen - 1:0] tselect_q;
			wire tmatch_control_d;
			wire [DbgHwBreakNum - 1:0] tmatch_control_q;
			wire [31:0] tmatch_value_d;
			wire [31:0] tmatch_value_q [0:DbgHwBreakNum - 1];
			wire selected_tmatch_control;
			wire [31:0] selected_tmatch_value;
			wire tselect_we;
			wire [DbgHwBreakNum - 1:0] tmatch_control_we;
			wire [DbgHwBreakNum - 1:0] tmatch_value_we;
			wire [DbgHwBreakNum - 1:0] trigger_match;
			assign tselect_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a0);
			genvar _gv_i_6;
			for (_gv_i_6 = 0; _gv_i_6 < DbgHwBreakNum; _gv_i_6 = _gv_i_6 + 1) begin : g_dbg_tmatch_we
				localparam i = _gv_i_6;
				assign tmatch_control_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a1);
				assign tmatch_value_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a2);
			end
			assign tselect_d = (csr_wdata_int < DbgHwBreakNum ? csr_wdata_int[DbgHwNumLen - 1:0] : MaxTselect[DbgHwNumLen - 1:0]);
			assign tmatch_control_d = csr_wdata_int[2];
			assign tmatch_value_d = csr_wdata_int[31:0];
			ibex_csr #(
				.Width(DbgHwNumLen),
				.ShadowCopy(1'b0),
				.ResetValue(1'sb0)
			) u_tselect_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(tselect_d),
				.wr_en_i(tselect_we),
				.rd_data_o(tselect_q),
				.rd_error_o()
			);
			genvar _gv_i_7;
			for (_gv_i_7 = 0; _gv_i_7 < DbgHwBreakNum; _gv_i_7 = _gv_i_7 + 1) begin : g_dbg_tmatch_reg
				localparam i = _gv_i_7;
				ibex_csr #(
					.Width(1),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_control_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_control_d),
					.wr_en_i(tmatch_control_we[i]),
					.rd_data_o(tmatch_control_q[i]),
					.rd_error_o()
				);
				ibex_csr #(
					.Width(32),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_value_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_value_d),
					.wr_en_i(tmatch_value_we[i]),
					.rd_data_o(tmatch_value_q[i]),
					.rd_error_o()
				);
			end
			localparam [31:0] TSelectRdataPadlen = (DbgHwNumLen >= 32 ? 0 : 32 - DbgHwNumLen);
			assign tselect_rdata = {{TSelectRdataPadlen {1'b0}}, tselect_q};
			if (DbgHwBreakNum > 1) begin : g_dbg_tmatch_multiple_select
				assign selected_tmatch_control = tmatch_control_q[tselect_q];
				assign selected_tmatch_value = tmatch_value_q[tselect_q];
			end
			else begin : g_dbg_tmatch_single_select
				assign selected_tmatch_control = tmatch_control_q[0];
				assign selected_tmatch_value = tmatch_value_q[0];
			end
			assign tmatch_control_rdata = {29'h05000209, selected_tmatch_control, 2'b00};
			assign tmatch_value_rdata = selected_tmatch_value;
			genvar _gv_i_8;
			for (_gv_i_8 = 0; _gv_i_8 < DbgHwBreakNum; _gv_i_8 = _gv_i_8 + 1) begin : g_dbg_trigger_match
				localparam i = _gv_i_8;
				assign trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i]);
			end
			assign trigger_match_o = |trigger_match;
		end
		else begin : gen_no_trigger_regs
			assign tselect_rdata = 'b0;
			assign tmatch_control_rdata = 'b0;
			assign tmatch_value_rdata = 'b0;
			assign trigger_match_o = 'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata_raw = csr_wdata_int[7:0];
	generate
		if (DataIndTiming) begin : gen_dit
			assign cpuctrlsts_part_wdata[1] = cpuctrlsts_part_wdata_raw[1];
		end
		else begin : gen_no_dit
			wire unused_dit;
			assign unused_dit = cpuctrlsts_part_wdata_raw[1];
			assign cpuctrlsts_part_wdata[1] = 1'b0;
		end
	endgenerate
	assign data_ind_timing_o = cpuctrlsts_part_q[1];
	generate
		if (DummyInstructions) begin : gen_dummy
			assign cpuctrlsts_part_wdata[2] = cpuctrlsts_part_wdata_raw[2];
			assign cpuctrlsts_part_wdata[5-:3] = cpuctrlsts_part_wdata_raw[5-:3];
			assign dummy_instr_seed_en_o = csr_we_int && (csr_addr == 12'h7c1);
			assign dummy_instr_seed_o = csr_wdata_int;
		end
		else begin : gen_no_dummy
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			assign unused_dummy_en = cpuctrlsts_part_wdata_raw[2];
			assign unused_dummy_mask = cpuctrlsts_part_wdata_raw[5-:3];
			assign cpuctrlsts_part_wdata[2] = 1'b0;
			assign cpuctrlsts_part_wdata[5-:3] = 3'b000;
			assign dummy_instr_seed_en_o = 1'b0;
			assign dummy_instr_seed_o = 1'sb0;
		end
	endgenerate
	assign dummy_instr_en_o = cpuctrlsts_part_q[2];
	assign dummy_instr_mask_o = cpuctrlsts_part_q[5-:3];
	generate
		if (ICache) begin : gen_icache_enable
			assign cpuctrlsts_part_wdata[0] = cpuctrlsts_part_wdata_raw[0];
			ibex_csr #(
				.Width(1),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'b0)
			) u_cpuctrlsts_ic_scr_key_valid_q_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(ic_scr_key_valid_i),
				.wr_en_i(1'b1),
				.rd_data_o(cpuctrlsts_ic_scr_key_valid_q),
				.rd_error_o(cpuctrlsts_ic_scr_key_err)
			);
		end
		else begin : gen_no_icache
			wire unused_icen;
			assign unused_icen = cpuctrlsts_part_wdata_raw[0];
			assign cpuctrlsts_part_wdata[0] = 1'b0;
			wire unused_ic_scr_key_valid;
			assign unused_ic_scr_key_valid = ic_scr_key_valid_i;
			assign cpuctrlsts_ic_scr_key_valid_q = 1'b0;
			assign cpuctrlsts_ic_scr_key_err = 1'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata[7] = cpuctrlsts_part_wdata_raw[7];
	assign cpuctrlsts_part_wdata[6] = cpuctrlsts_part_wdata_raw[6];
	assign icache_enable_o = cpuctrlsts_part_q[0] & ~(debug_mode_i | debug_mode_entering_i);
	ibex_csr #(
		.Width(8),
		.ShadowCopy(ShadowCSR),
		.ResetValue(1'sb0)
	) u_cpuctrlsts_part_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({cpuctrlsts_part_d}),
		.wr_en_i(cpuctrlsts_part_we),
		.rd_data_o(cpuctrlsts_part_q),
		.rd_error_o(cpuctrlsts_part_err)
	);
	assign csr_shadow_err_o = (((mstatus_err | mtvec_err) | pmp_csr_err) | cpuctrlsts_part_err) | cpuctrlsts_ic_scr_key_err;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DEPCC = 5'h18;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0 = 5'h19;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1 = 5'h1a;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MEPCC = 5'h1f;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC = 5'h1e;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTCC = 5'h1c;
	localparam [4:0] ibex_cheriot_pkg_CHERIOT_SCR_MTDC = 5'h1d;
	function automatic [5:0] sv2v_cast_EDD05;
		input reg [5:0] inp;
		sv2v_cast_EDD05 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_1D696;
		input reg [2:0] inp;
		sv2v_cast_1D696 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_3B83B;
		input reg [3:0] inp;
		sv2v_cast_3B83B = inp;
	endfunction
	function automatic [8:0] sv2v_cast_7EF6C;
		input reg [8:0] inp;
		sv2v_cast_7EF6C = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_EDD05(1'sb0), sv2v_cast_1D696(1'sb0), sv2v_cast_3B83B(1'sb0), sv2v_cast_7EF6C(1'sb0), sv2v_cast_7EF6C(1'sb0)};
	localparam [111:0] ibex_cheriot_pkg_NULL_DECODED_CAP = 112'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TM = 6'b111111;
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
	function automatic [5:0] sv2v_cast_31206;
		input reg [5:0] inp;
		sv2v_cast_31206 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_CF4F5;
		input reg [2:0] inp;
		sv2v_cast_CF4F5 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_9C1BC;
		input reg [3:0] inp;
		sv2v_cast_9C1BC = inp;
	endfunction
	function automatic [8:0] sv2v_cast_E4E4A;
		input reg [8:0] inp;
		sv2v_cast_E4E4A = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TM = {4'b0010, sv2v_cast_31206(ibex_cheriot_pkg_CPERMS_TM), sv2v_cast_CF4F5(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_9C1BC(ibex_cheriot_pkg_MAXCEXP), sv2v_cast_E4E4A(9'h100), sv2v_cast_7EF6C(1'sb0)};
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TS = 6'b100111;
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TS = {4'b0010, sv2v_cast_31206(ibex_cheriot_pkg_CPERMS_TS), sv2v_cast_CF4F5(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_9C1BC(ibex_cheriot_pkg_MAXCEXP), sv2v_cast_E4E4A(9'h100), sv2v_cast_7EF6C(1'sb0)};
	localparam [5:0] ibex_cheriot_pkg_CPERMS_TX = 6'b101111;
	function automatic [5:0] sv2v_cast_6;
		input reg [5:0] inp;
		sv2v_cast_6 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
	localparam [111:0] ibex_cheriot_pkg_ROOT_DECODED_CAP_TX = {81'h100000000000000001eb2, sv2v_cast_6(ibex_cheriot_pkg_CPERMS_TX), sv2v_cast_3(ibex_cheriot_pkg_OTYPE_UNSEALED), sv2v_cast_4(ibex_cheriot_pkg_MAXCEXP), 18'h20000};
	function automatic [34:0] sv2v_cast_89126;
		input reg [34:0] inp;
		sv2v_cast_89126 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_ROOT_CAP_TX = sv2v_cast_89126(ibex_cheriot_pkg_ROOT_DECODED_CAP_TX);
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
	function automatic [34:0] ibex_cheriot_pkg_cheriot_encode_cap;
		input reg [111:0] d;
		reg [111:0] unused_d;
		begin
			unused_d = d;
			ibex_cheriot_pkg_cheriot_encode_cap = sv2v_cast_89126(d);
		end
	endfunction
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
	function automatic [34:0] ibex_cheriot_pkg_cheriot_pcc_to_mepc;
		input reg [111:0] pcc;
		input reg [31:0] address;
		input reg clrtag;
		reg [34:0] cap;
		reg [111:0] new_dcap;
		begin
			new_dcap = ibex_cheriot_pkg_cheriot_set_address(pcc, address);
			cap = ibex_cheriot_pkg_cheriot_encode_cap(new_dcap);
			if (clrtag)
				cap[32] = 1'b0;
			ibex_cheriot_pkg_cheriot_pcc_to_mepc = cap;
		end
	endfunction
	generate
		if (BaseIsa == 32'sd1) begin : gen_scr
			wire [34:0] pcc_exc_cap;
			reg [34:0] mtdc_cap;
			reg [31:0] mtdc_data;
			reg [34:0] mscratchc_cap;
			reg [31:0] mscratchc_data;
			reg [34:0] mstack_epc_cap_q;
			wire mtdc_en_cheriot;
			wire mscratchc_en_cheriot;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (cheriot_csr_addr_i)
					ibex_cheriot_pkg_CHERIOT_SCR_DEPCC: begin
						cheriot_csr_rdata_o = (debug_mode_i ? depc_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? depc_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0: begin
						cheriot_csr_rdata_o = (debug_mode_i ? dscratch0_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? dscratch0_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1: begin
						cheriot_csr_rdata_o = (debug_mode_i ? dscratch1_q : {32 {1'sb0}});
						cheriot_csr_rcap_o = (debug_mode_i ? dscratch1_cap : ibex_cheriot_pkg_NULL_CAP);
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MTCC: begin
						cheriot_csr_rdata_o = mtvec_q;
						cheriot_csr_rcap_o = mtvec_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MTDC: begin
						cheriot_csr_rdata_o = mtdc_data;
						cheriot_csr_rcap_o = mtdc_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC: begin
						cheriot_csr_rdata_o = mscratchc_data;
						cheriot_csr_rcap_o = mscratchc_cap;
					end
					ibex_cheriot_pkg_CHERIOT_SCR_MEPCC: begin
						cheriot_csr_rdata_o = mepc_q;
						cheriot_csr_rcap_o = mepc_cap;
					end
					default: begin
						cheriot_csr_rdata_o = 32'h00000000;
						cheriot_csr_rcap_o = ibex_cheriot_pkg_NULL_CAP;
					end
				endcase
			end
			assign pcc_cap_o = pcc_cap_q;
			assign pcc_exc_cap = ibex_cheriot_pkg_cheriot_pcc_to_mepc(pcc_cap_q, exception_pc, csr_mepcc_clrtag_i);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					pcc_cap_q <= ibex_cheriot_pkg_ROOT_DECODED_CAP_TX;
				else if (cheriot_enable_i == ibex_pkg_IbexMuBiOn)
					pcc_cap_q <= pcc_cap_d;
			reg [111:0] tf_cap;
			reg [34:0] tr_cap;
			reg [31:0] tr_addr;
			always @(*) begin
				if (_sv2v_0)
					;
				if (csr_save_cause_i) begin
					tr_cap = mtvec_cap;
					tr_addr = mtvec_q;
				end
				else if (csr_restore_mret_i) begin
					tr_cap = mepc_cap;
					tr_addr = mepc_q;
				end
				else if (csr_restore_dret_i & debug_mode_i) begin
					tr_cap = depc_cap;
					tr_addr = depc_q;
				end
				else begin
					tr_cap = ibex_cheriot_pkg_NULL_CAP;
					tr_addr = 32'h00000000;
				end
				tf_cap = ibex_cheriot_pkg_cheriot_decode_cap(tr_cap, tr_addr);
				if ((csr_save_cause_i | csr_restore_mret_i) | (csr_restore_dret_i & debug_mode_i))
					pcc_cap_d = tf_cap;
				else if (cheriot_branch_req_i)
					pcc_cap_d = pcc_cap_i;
				else
					pcc_cap_d = pcc_cap_q;
			end
			assign mtvec_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MTCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mtvec_cap <= ibex_cheriot_pkg_ROOT_CAP_TX;
				else if (mtvec_en_cheriot)
					mtvec_cap <= cheriot_csr_wcap_i;
			assign mepc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MEPCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mstack_epc_cap_q <= ibex_cheriot_pkg_NULL_CAP;
				else if (mstack_en)
					mstack_epc_cap_q <= mepc_cap;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mepc_cap <= ibex_cheriot_pkg_ROOT_CAP_TX;
				else if ((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_save_cause_i) && ~debug_csr_save_i) && ~debug_mode_i)
					mepc_cap <= pcc_exc_cap;
				else if (((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_restore_mret_i) && nmi_mode_i)
					mepc_cap <= mstack_epc_cap_q;
				else if (mepc_en_cheriot)
					mepc_cap <= cheriot_csr_wcap_i;
			assign mtdc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MTDC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mtdc_cap <= ibex_cheriot_pkg_ROOT_CAP_TM;
					mtdc_data <= 32'h00000000;
				end
				else if (mtdc_en_cheriot) begin
					mtdc_cap <= cheriot_csr_wcap_i;
					mtdc_data <= cheriot_csr_wdata_i;
				end
			assign mscratchc_en_cheriot = (cheriot_csr_op_en_i && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_MSCRATCHC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mscratchc_cap <= ibex_cheriot_pkg_ROOT_CAP_TS;
					mscratchc_data <= 32'h00000000;
				end
				else if (mscratchc_en_cheriot) begin
					mscratchc_cap <= cheriot_csr_wcap_i;
					mscratchc_data <= cheriot_csr_wdata_i;
				end
			assign depc_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DEPCC)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					depc_cap <= ibex_cheriot_pkg_NULL_CAP;
				else if ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && (csr_save_cause_i & debug_csr_save_i))
					depc_cap <= pcc_exc_cap;
				else if (depc_en_cheriot)
					depc_cap <= cheriot_csr_wcap_i;
			assign dscratch0_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC0)) && (cheriot_csr_op_i == 5'd1);
			assign dscratch1_en_cheriot = ((debug_mode_i & cheriot_csr_op_en_i) && (cheriot_csr_addr_i == ibex_cheriot_pkg_CHERIOT_SCR_DSCRATCHC1)) && (cheriot_csr_op_i == 5'd1);
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					dscratch0_cap <= ibex_cheriot_pkg_NULL_CAP;
					dscratch1_cap <= ibex_cheriot_pkg_NULL_CAP;
				end
				else if (dscratch0_en_cheriot)
					dscratch0_cap <= cheriot_csr_wcap_i;
				else if (dscratch1_en_cheriot)
					dscratch1_cap <= cheriot_csr_wcap_i;
			reg cheriot_fatal_err_q;
			assign cheriot_fatal_err_o = cheriot_fatal_err_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					cheriot_fatal_err_q <= 1'b0;
				else if (((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && csr_save_cause_i) && ~mtvec_cap[32])
					cheriot_fatal_err_q <= 1'b1;
		end
		else begin : gen_no_scr
			wire [32:1] sv2v_tmp_A9A6D;
			assign sv2v_tmp_A9A6D = 32'h00000000;
			always @(*) cheriot_csr_rdata_o = sv2v_tmp_A9A6D;
			wire [35:1] sv2v_tmp_7F78A;
			assign sv2v_tmp_7F78A = ibex_cheriot_pkg_NULL_CAP;
			always @(*) cheriot_csr_rcap_o = sv2v_tmp_7F78A;
			assign pcc_cap_o = ibex_cheriot_pkg_NULL_DECODED_CAP;
			wire [112:1] sv2v_tmp_61F0D;
			assign sv2v_tmp_61F0D = ibex_cheriot_pkg_NULL_DECODED_CAP;
			always @(*) pcc_cap_q = sv2v_tmp_61F0D;
			wire [112:1] sv2v_tmp_F0858;
			assign sv2v_tmp_F0858 = ibex_cheriot_pkg_NULL_DECODED_CAP;
			always @(*) pcc_cap_d = sv2v_tmp_F0858;
			wire [35:1] sv2v_tmp_006B9;
			assign sv2v_tmp_006B9 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) mepc_cap = sv2v_tmp_006B9;
			wire [35:1] sv2v_tmp_94A04;
			assign sv2v_tmp_94A04 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) mtvec_cap = sv2v_tmp_94A04;
			wire [35:1] sv2v_tmp_45FF7;
			assign sv2v_tmp_45FF7 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) depc_cap = sv2v_tmp_45FF7;
			wire [35:1] sv2v_tmp_35D9C;
			assign sv2v_tmp_35D9C = ibex_cheriot_pkg_NULL_CAP;
			always @(*) dscratch0_cap = sv2v_tmp_35D9C;
			wire [35:1] sv2v_tmp_35095;
			assign sv2v_tmp_35095 = ibex_cheriot_pkg_NULL_CAP;
			always @(*) dscratch1_cap = sv2v_tmp_35095;
			assign mtvec_en_cheriot = 1'b0;
			assign mepc_en_cheriot = 1'b0;
			assign depc_en_cheriot = 1'b0;
			assign dscratch0_en_cheriot = 1'b0;
			assign dscratch1_en_cheriot = 1'b0;
			assign cheriot_fatal_err_o = 1'b0;
			wire unused_cheriot_scr_sigs;
			assign unused_cheriot_scr_sigs = ((((((((((((^cheriot_csr_addr_i | ^cheriot_csr_op_i) | cheriot_csr_op_en_i) | ^cheriot_csr_wcap_i) | csr_mepcc_clrtag_i) | cheriot_branch_req_i) | ^pcc_cap_i) | ^mepc_cap) | ^mtvec_cap) | ^depc_cap) | ^dscratch0_cap) | ^dscratch1_cap) | ^pcc_cap_d) | ^pcc_cap_q;
		end
	endgenerate
	wire unused_cheriot_csr_inputs;
	assign unused_cheriot_csr_inputs = ^{cheriot_csr_access_i, cheriot_branch_target_i};
	initial _sv2v_0 = 0;
endmodule
