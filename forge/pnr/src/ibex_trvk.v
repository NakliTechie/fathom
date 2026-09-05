module ibex_trvk (
	clk_i,
	rst_ni,
	heap_base_addr_i,
	upstream_req_i,
	upstream_gnt_o,
	upstream_rvalid_o,
	upstream_we_i,
	upstream_be_i,
	upstream_addr_i,
	upstream_wdata_i,
	upstream_wdata_intg_i,
	upstream_rdata_o,
	upstream_rdata_intg_o,
	upstream_err_o,
	upstream_tag_i,
	upstream_tag_o,
	downstream_req_o,
	downstream_gnt_i,
	downstream_rvalid_i,
	downstream_we_o,
	downstream_be_o,
	downstream_addr_o,
	downstream_wdata_o,
	downstream_wdata_intg_o,
	downstream_rdata_i,
	downstream_rdata_intg_i,
	downstream_err_i,
	downstream_tag_o,
	downstream_tag_i,
	revbm_req_o,
	revbm_gnt_i,
	revbm_rvalid_i,
	revbm_addr_o,
	revbm_rdata_i,
	revbm_rdata_intg_i,
	revbm_err_i,
	revbm_data_intg_error_o,
	revbm_device_error_o
);
	parameter [31:0] NumOutstanding = 32'd4;
	parameter [31:0] RevBitmapAddrWidth = 32'd11;
	parameter [31:0] RevBitmapBaseAddr = 32'h00000000;
	parameter [0:0] MemECC = 1'b1;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] heap_base_addr_i;
	input wire upstream_req_i;
	output wire upstream_gnt_o;
	output wire upstream_rvalid_o;
	input wire upstream_we_i;
	input wire [3:0] upstream_be_i;
	input wire [31:0] upstream_addr_i;
	input wire [31:0] upstream_wdata_i;
	input wire [6:0] upstream_wdata_intg_i;
	output wire [31:0] upstream_rdata_o;
	output wire [6:0] upstream_rdata_intg_o;
	output wire upstream_err_o;
	input wire upstream_tag_i;
	output wire upstream_tag_o;
	output wire downstream_req_o;
	input wire downstream_gnt_i;
	input wire downstream_rvalid_i;
	output wire downstream_we_o;
	output wire [3:0] downstream_be_o;
	output wire [31:0] downstream_addr_o;
	output wire [31:0] downstream_wdata_o;
	output wire [6:0] downstream_wdata_intg_o;
	input wire [31:0] downstream_rdata_i;
	input wire [6:0] downstream_rdata_intg_i;
	input wire downstream_err_i;
	output wire downstream_tag_o;
	input wire downstream_tag_i;
	output wire revbm_req_o;
	input wire revbm_gnt_i;
	input wire revbm_rvalid_i;
	output wire [31:0] revbm_addr_o;
	input wire [31:0] revbm_rdata_i;
	input wire [6:0] revbm_rdata_intg_i;
	input wire revbm_err_i;
	output wire revbm_data_intg_error_o;
	output wire revbm_device_error_o;
	localparam [31:0] RevBitmapWordAddrWidth = RevBitmapAddrWidth - 32'd2;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	wire align_fork_valid;
	wire align_fork_ready;
	wire misalign_flag_out;
	wire misalign_flag_out_valid;
	wire misalign_flag_out_ready;
	reg [31:0] ptr_storage_q;
	reg ptr_storage_valid_q;
	wire ptr_storage_enable;
	wire [40:0] downstream_rsp_in;
	wire [40:0] downstream_rsp_out;
	wire downstream_rsp_out_valid;
	wire downstream_rsp_out_ready;
	wire downstream_rsp_wready;
	wire unused_downstream_rsp_wready;
	wire [(((ibex_cheriot_pkg_EXP_W + ibex_cheriot_pkg_CBOUND_W) + ibex_cheriot_pkg_OTYPE_W) + ibex_cheriot_pkg_CPERMS_W) - 1:0] cap_meta;
	wire unused_cap_meta;
	wire is_sealing_cap;
	wire [32:0] cap_base_33;
	wire unused_cap_base_33;
	wire [31:0] cap_base;
	wire [8:0] addr_mid;
	wire [1:0] cap_correction;
	wire unused_cap_correction;
	wire [31:0] revbm_cap_addr;
	wire [31:0] revbm_bit_addr;
	wire [4:0] revbm_bit_select;
	wire [RevBitmapWordAddrWidth - 1:0] revbm_addr;
	wire revbm_out_of_range;
	wire revbm_req_required;
	wire revbm_rsp_ready;
	reg revbm_outstanding_q;
	wire revbm_revoked;
	wire [1:0] revbm_rsp_data_intg_error;
	stream_fork #(.N_OUP(32'd2)) u_stream_fork_us2ds(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(upstream_req_i),
		.ready_o(upstream_gnt_o),
		.valid_o({align_fork_valid, downstream_req_o}),
		.ready_i({align_fork_ready, downstream_gnt_i})
	);
	stream_join_dynamic #(.N_INP(32'd2)) u_stream_join_dynamic_ds2us(
		.inp_valid_i({revbm_rvalid_i, downstream_rsp_out_valid}),
		.inp_ready_o({revbm_rsp_ready, downstream_rsp_out_ready}),
		.sel_i({revbm_req_required, 1'b1}),
		.oup_valid_o(upstream_rvalid_o),
		.oup_ready_i(1'b1)
	);
	assign downstream_we_o = upstream_we_i;
	assign downstream_be_o = upstream_be_i;
	assign downstream_addr_o = upstream_addr_i;
	assign downstream_wdata_o = upstream_wdata_i;
	assign downstream_wdata_intg_o = upstream_wdata_intg_i;
	assign upstream_rdata_o = downstream_rsp_out[40-:32];
	assign upstream_rdata_intg_o = downstream_rsp_out[8-:7];
	assign upstream_err_o = downstream_rsp_out[0];
	assign downstream_tag_o = upstream_tag_i;
	assign upstream_tag_o = (revbm_rvalid_i ? !revbm_revoked : 1'b1) & downstream_rsp_out[1];
	prim_fifo_sync #(
		.Width(32'd1),
		.Pass(1'b0),
		.Depth(NumOutstanding),
		.NeverClears(1'b1),
		.Secure(1'b0)
	) u_prim_fifo_sync_align(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(align_fork_valid),
		.wready_o(align_fork_ready),
		.wdata_i(upstream_addr_i[2]),
		.rvalid_o(misalign_flag_out_valid),
		.rready_i(misalign_flag_out_ready),
		.rdata_o(misalign_flag_out),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	assign misalign_flag_out_ready = upstream_rvalid_o;
	assign ptr_storage_enable = (downstream_rsp_out[1] && !misalign_flag_out) && misalign_flag_out_valid;
	always @(posedge clk_i or negedge rst_ni) begin : proc_pointer_store
		if (!rst_ni)
			ptr_storage_q <= 1'sb0;
		else if (misalign_flag_out_ready && ptr_storage_enable)
			ptr_storage_q <= downstream_rsp_out[40-:32];
	end
	always @(posedge clk_i or negedge rst_ni) begin : proc_pointer_valid_store
		if (!rst_ni)
			ptr_storage_valid_q <= 1'b0;
		else if (misalign_flag_out_ready)
			ptr_storage_valid_q <= ptr_storage_enable;
	end
	assign downstream_rsp_in = {downstream_rdata_i, downstream_rdata_intg_i, downstream_tag_i, downstream_err_i};
	prim_fifo_sync #(
		.Width(41),
		.Pass(1'b1),
		.Depth(NumOutstanding),
		.NeverClears(1'b1),
		.Secure(1'b0)
	) u_prim_fifo_ds_rsp_store(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(downstream_rvalid_i),
		.wready_o(downstream_rsp_wready),
		.wdata_i(downstream_rsp_in),
		.rvalid_o(downstream_rsp_out_valid),
		.rready_i(downstream_rsp_out_ready),
		.rdata_o(downstream_rsp_out),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
	endfunction
	function automatic [4:0] sv2v_cast_7C6B5;
		input reg [4:0] inp;
		sv2v_cast_7C6B5 = inp;
	endfunction
	function automatic [8:0] sv2v_cast_E4E4A;
		input reg [8:0] inp;
		sv2v_cast_E4E4A = inp;
	endfunction
	function automatic [2:0] sv2v_cast_CF4F5;
		input reg [2:0] inp;
		sv2v_cast_CF4F5 = inp;
	endfunction
	function automatic [5:0] sv2v_cast_31206;
		input reg [5:0] inp;
		sv2v_cast_31206 = inp;
	endfunction
	assign cap_meta = {sv2v_cast_7C6B5(ibex_cheriot_pkg_cheriot_expand_exp(downstream_rsp_out[30:27])), sv2v_cast_E4E4A(downstream_rsp_out[17:9]), sv2v_cast_CF4F5(downstream_rsp_out[33:31]), sv2v_cast_31206(downstream_rsp_out[39:34])};
	assign unused_cap_meta = ^{cap_meta[8-:3], cap_meta[5]};
	function automatic ibex_cheriot_pkg_cheriot_is_sealing_cap;
		input reg [5:0] cperms;
		reg unused_cperms_gl;
		begin
			unused_cperms_gl = cperms[5];
			ibex_cheriot_pkg_cheriot_is_sealing_cap = (cperms[4:3] == 2'b00) && |cperms[2:0];
		end
	endfunction
	assign is_sealing_cap = ibex_cheriot_pkg_cheriot_is_sealing_cap(cap_meta[5-:ibex_cheriot_pkg_CPERMS_W]);
	assign addr_mid = sv2v_cast_E4E4A(ptr_storage_q >> cap_meta[22-:5]);
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
	assign cap_correction = ibex_cheriot_pkg_cheriot_compute_corrections(1'sb0, cap_meta[17-:9], addr_mid);
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
	function automatic [1:0] ibex_cheriot_pkg_cheriot_get_base_correction;
		input reg [1:0] cap_cor;
		reg unused_top_cor_bit;
		begin
			unused_top_cor_bit = cap_cor[1];
			ibex_cheriot_pkg_cheriot_get_base_correction = {2 {cap_cor[0]}};
		end
	endfunction
	assign cap_base_33 = ibex_cheriot_pkg_cheriot_expand_bound33(cap_meta[17-:9], ibex_cheriot_pkg_cheriot_get_base_correction(cap_correction), cap_meta[22-:5], ptr_storage_q);
	assign unused_cap_correction = ^cap_correction;
	assign {unused_cap_base_33, cap_base} = cap_base_33;
	assign revbm_cap_addr = cap_base - heap_base_addr_i;
	assign revbm_bit_addr = revbm_cap_addr >> 3;
	assign revbm_addr = revbm_bit_addr[RevBitmapWordAddrWidth + 4:5];
	assign revbm_bit_select = revbm_bit_addr[4:0];
	assign revbm_out_of_range = |revbm_bit_addr[31:RevBitmapWordAddrWidth + 5];
	assign revbm_req_required = (((((!is_sealing_cap && ptr_storage_valid_q) && downstream_rsp_out[1]) && downstream_rsp_out_valid) && misalign_flag_out) && misalign_flag_out_valid) && !revbm_out_of_range;
	assign revbm_req_o = revbm_req_required && !revbm_outstanding_q;
	assign revbm_addr_o = RevBitmapBaseAddr + {{(32 - RevBitmapWordAddrWidth) - 2 {1'b0}}, revbm_addr, 2'b00};
	assign revbm_revoked = (revbm_rdata_i[revbm_bit_select] || revbm_err_i) || |revbm_rsp_data_intg_error;
	assign revbm_device_error_o = revbm_rvalid_i && revbm_err_i;
	generate
		if (MemECC) begin : gen_revbm_intg_check
			prim_secded_inv_39_32_dec u_prim_secded_inv_39_32_dec_bm_rsp_data(
				.data_i({revbm_rdata_intg_i, revbm_rdata_i}),
				.data_o(),
				.syndrome_o(),
				.err_o(revbm_rsp_data_intg_error)
			);
			assign revbm_data_intg_error_o = revbm_rvalid_i && |revbm_rsp_data_intg_error;
		end
		else begin : gen_no_revbm_intg_check
			wire unused_revbm_rdata_intg;
			assign unused_revbm_rdata_intg = ^revbm_rdata_intg_i;
			assign revbm_rsp_data_intg_error = 2'b00;
			assign revbm_data_intg_error_o = 1'b0;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni) begin : proc_rev_req_store
		if (!rst_ni)
			revbm_outstanding_q <= 1'b0;
		else if (revbm_rvalid_i && revbm_rsp_ready)
			revbm_outstanding_q <= 1'b0;
		else if (revbm_req_o && revbm_gnt_i)
			revbm_outstanding_q <= 1'b1;
	end
	assign unused_downstream_rsp_wready = downstream_rsp_wready;
endmodule
