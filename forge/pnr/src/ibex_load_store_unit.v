module ibex_load_store_unit (
	clk_i,
	rst_ni,
	cheriot_enable_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_bus_err_i,
	data_pmp_err_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_tag_o,
	data_rdata_i,
	data_tag_i,
	lsu_we_i,
	lsu_is_cap_i,
	lsu_cheriot_err_i,
	lsu_type_i,
	lsu_wdata_i,
	lsu_wcap_i,
	lsu_lc_clrperm_i,
	lsu_sign_ext_i,
	lsu_rcap_o,
	lsu_rdata_o,
	lsu_rdata_valid_o,
	lsu_req_i,
	adder_result_ex_i,
	addr_incr_req_o,
	addr_last_o,
	lsu_req_done_o,
	lsu_resp_valid_o,
	load_err_o,
	load_resp_intg_err_o,
	store_err_o,
	store_resp_intg_err_o,
	lsu_err_is_cheriot_o,
	busy_o,
	perf_load_o,
	perf_store_o
);
	reg _sv2v_0;
	parameter integer BaseIsa = 32'sd0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] cheriot_enable_i;
	output reg data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_bus_err_i;
	input wire data_pmp_err_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	output wire data_tag_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_tag_i;
	input wire lsu_we_i;
	input wire lsu_is_cap_i;
	input wire lsu_cheriot_err_i;
	input wire [1:0] lsu_type_i;
	input wire [31:0] lsu_wdata_i;
	localparam [31:0] ibex_cheriot_pkg_CBOUND_W = 9;
	localparam [31:0] ibex_cheriot_pkg_CEXP_W = 4;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_W = 6;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_W = 3;
	input wire [34:0] lsu_wcap_i;
	input wire [2:0] lsu_lc_clrperm_i;
	input wire lsu_sign_ext_i;
	output wire [34:0] lsu_rcap_o;
	output wire [31:0] lsu_rdata_o;
	output wire lsu_rdata_valid_o;
	input wire lsu_req_i;
	input wire [31:0] adder_result_ex_i;
	output reg addr_incr_req_o;
	output wire [31:0] addr_last_o;
	output wire lsu_req_done_o;
	output wire lsu_resp_valid_o;
	output wire load_err_o;
	output wire load_resp_intg_err_o;
	output wire store_err_o;
	output wire store_resp_intg_err_o;
	output wire lsu_err_is_cheriot_o;
	output wire busy_o;
	output reg perf_load_o;
	output reg perf_store_o;
	wire [31:0] data_addr;
	wire [31:0] data_addr_w_aligned;
	reg [31:0] addr_last_q;
	wire [31:0] addr_last_d;
	reg addr_update;
	reg ctrl_update;
	reg rdata_update;
	reg [31:8] rdata_q;
	reg [1:0] rdata_offset_q;
	reg [1:0] data_type_q;
	reg data_sign_ext_q;
	reg data_we_q;
	wire [1:0] data_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata_data;
	reg data_wdata_tag;
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	wire split_misaligned_access;
	reg handle_misaligned_q;
	reg handle_misaligned_d;
	reg pmp_err_q;
	reg pmp_err_d;
	reg lsu_err_q;
	reg lsu_err_d;
	wire data_intg_err;
	wire data_or_pmp_err;
	reg resp_is_cap_q;
	reg cheriot_err_d;
	reg cheriot_err_q;
	reg [2:0] resp_lc_clrperm_q;
	reg lsu_go;
	reg lsu_go_goodcap;
	wire cpu_req_erred;
	wire cpu_req_valid;
	reg [3:0] ls_fsm_cs;
	reg [3:0] ls_fsm_ns;
	reg [2:0] cap_rx_fsm_q;
	reg [2:0] cap_rx_fsm_d;
	reg cap_lsw_err_q;
	reg [31:0] cap_lsw_data_q;
	reg cap_lsw_tag_q;
	assign data_addr = adder_result_ex_i;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	assign data_offset = (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i ? 2'b00 : data_addr[1:0]);
	always @(*) begin
		if (_sv2v_0)
			;
		if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i)
			data_be = 4'b1111;
		else
			(* full_case, parallel_case *)
			case (lsu_type_i)
				2'b00:
					if (!handle_misaligned_q)
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b1111;
							2'b01: data_be = 4'b1110;
							2'b10: data_be = 4'b1100;
							2'b11: data_be = 4'b1000;
							default: data_be = 4'b1111;
						endcase
					else
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b0000;
							2'b01: data_be = 4'b0001;
							2'b10: data_be = 4'b0011;
							2'b11: data_be = 4'b0111;
							default: data_be = 4'b1111;
						endcase
				2'b01:
					if (!handle_misaligned_q)
						(* full_case, parallel_case *)
						case (data_offset)
							2'b00: data_be = 4'b0011;
							2'b01: data_be = 4'b0110;
							2'b10: data_be = 4'b1100;
							2'b11: data_be = 4'b1000;
							default: data_be = 4'b1111;
						endcase
					else
						data_be = 4'b0001;
				2'b10, 2'b11:
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0001;
						2'b01: data_be = 4'b0010;
						2'b10: data_be = 4'b0100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				default: data_be = 4'b1111;
			endcase
	end
	reg [31:0] wdata_int;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_offset)
			2'b00: wdata_int = lsu_wdata_i;
			2'b01: wdata_int = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
			2'b10: wdata_int = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
			2'b11: wdata_int = {lsu_wdata_i[7:0], lsu_wdata_i[31:8]};
			default: wdata_int = lsu_wdata_i;
		endcase
	end
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
	always @(*) begin
		if (_sv2v_0)
			;
		if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_is_cap_i) begin
			if (lsu_we_i & (ls_fsm_cs == 4'd6))
				{data_wdata_tag, data_wdata_data} = ibex_cheriot_pkg_cheriot_cap_to_mem(lsu_wcap_i);
			else if (lsu_we_i)
				{data_wdata_tag, data_wdata_data} = {lsu_wcap_i[32], lsu_wdata_i};
			else
				{data_wdata_tag, data_wdata_data} = {1'b1, lsu_wdata_i};
		end
		else
			{data_wdata_tag, data_wdata_data} = {1'b0, wdata_int};
	end
	wire [1:0] unused_lsu_wcap_cor;
	assign unused_lsu_wcap_cor = lsu_wcap_i[34-:2];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= 1'sb0;
		else if (rdata_update)
			rdata_q <= data_rdata_i[31:8];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rdata_offset_q <= 2'h0;
			data_type_q <= 2'h0;
			data_sign_ext_q <= 1'b0;
			data_we_q <= 1'b0;
		end
		else if (ctrl_update) begin
			rdata_offset_q <= data_offset;
			data_type_q <= lsu_type_i;
			data_sign_ext_q <= lsu_sign_ext_i;
			data_we_q <= lsu_we_i;
		end
	assign addr_last_d = (addr_incr_req_o ? data_addr_w_aligned : data_addr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			addr_last_q <= 1'sb0;
		else if (addr_update)
			addr_last_q <= addr_last_d;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00: rdata_w_ext = data_rdata_i[31:0];
			2'b01: rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
			default: rdata_w_ext = data_rdata_i[31:0];
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
				else
					rdata_h_ext = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
				else
					rdata_h_ext = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
				else
					rdata_h_ext = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
			default: rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
				else
					rdata_b_ext = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[15:8]};
				else
					rdata_b_ext = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[23:16]};
				else
					rdata_b_ext = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[31:24]};
				else
					rdata_b_ext = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
			default: rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
			default: data_rdata_ext = rdata_w_ext;
		endcase
	end
	generate
		if (MemECC) begin : g_mem_rdata_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] data_rdata_buf;
			prim_generic_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(data_rdata_i),
				.out_o(data_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_data_intg_dec(
				.data_i(data_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign data_intg_err = |ecc_err;
		end
		else begin : g_no_mem_data_ecc
			assign data_intg_err = 1'b0;
		end
	endgenerate
	assign split_misaligned_access = ((lsu_type_i == 2'b00) && (data_offset != 2'b00)) || ((lsu_type_i == 2'b01) && (data_offset == 2'b11));
	assign cpu_req_valid = lsu_req_i & ~((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & lsu_cheriot_err_i);
	assign cpu_req_erred = (lsu_req_i & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_cheriot_err_i;
	always @(*) begin
		if (_sv2v_0)
			;
		ls_fsm_ns = ls_fsm_cs;
		data_req_o = 1'b0;
		addr_incr_req_o = 1'b0;
		handle_misaligned_d = handle_misaligned_q;
		pmp_err_d = pmp_err_q;
		lsu_err_d = lsu_err_q;
		cheriot_err_d = cheriot_err_q & (cheriot_enable_i == ibex_pkg_IbexMuBiOn);
		addr_update = 1'b0;
		ctrl_update = 1'b0;
		rdata_update = 1'b0;
		perf_load_o = 1'b0;
		perf_store_o = 1'b0;
		lsu_go = 1'b0;
		lsu_go_goodcap = 1'b0;
		(* full_case, parallel_case *)
		case (ls_fsm_cs)
			4'd0: begin
				pmp_err_d = 1'b0;
				cheriot_err_d = 1'b0;
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & cpu_req_erred) begin
					data_req_o = 1'b0;
					cheriot_err_d = 1'b1;
					ctrl_update = 1'b1;
					addr_update = 1'b1;
					pmp_err_d = 1'b0;
					lsu_err_d = 1'b0;
					perf_load_o = 1'b0;
					lsu_go = 1'b1;
					ls_fsm_ns = 4'd0;
				end
				else if ((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & cpu_req_valid) & lsu_is_cap_i) begin
					data_req_o = 1'b1;
					cheriot_err_d = 1'b0;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					lsu_go = 1'b1;
					lsu_go_goodcap = 1'b1;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						ls_fsm_ns = 4'd6;
					end
					else
						ls_fsm_ns = 4'd5;
				end
				else if (cpu_req_valid) begin
					data_req_o = 1'b1;
					cheriot_err_d = 1'b0;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					lsu_go = 1'b1;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						handle_misaligned_d = split_misaligned_access;
						ls_fsm_ns = (split_misaligned_access ? 4'd2 : 4'd0);
					end
					else
						ls_fsm_ns = (split_misaligned_access ? 4'd1 : 4'd3);
				end
			end
			4'd1: begin
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					addr_update = 1'b1;
					ctrl_update = 1'b1;
					handle_misaligned_d = 1'b1;
					ls_fsm_ns = 4'd2;
				end
			end
			4'd2: begin
				data_req_o = 1'b1;
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i || pmp_err_q) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i | pmp_err_q;
					rdata_update = ~data_we_q;
					ls_fsm_ns = (data_gnt_i ? 4'd0 : 4'd3);
					addr_update = data_gnt_i & ~(data_bus_err_i | pmp_err_q);
					handle_misaligned_d = ~data_gnt_i;
				end
				else if (data_gnt_i) begin
					ls_fsm_ns = 4'd4;
					handle_misaligned_d = 1'b0;
				end
			end
			4'd3: begin
				addr_incr_req_o = handle_misaligned_q;
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					ctrl_update = 1'b1;
					addr_update = ~lsu_err_q;
					ls_fsm_ns = 4'd0;
					handle_misaligned_d = 1'b0;
				end
			end
			4'd4: begin
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i;
					addr_update = ~data_bus_err_i;
					rdata_update = ~data_we_q;
					ls_fsm_ns = 4'd0;
				end
			end
			4'd5:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b0;
					data_req_o = 1'b1;
					if (data_gnt_i) begin
						ls_fsm_ns = 4'd6;
						ctrl_update = 1'b1;
						addr_update = 1'b1;
					end
				end
				else
					ls_fsm_ns = 4'd0;
			4'd6:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b1;
					data_req_o = 1'b1;
					if (data_gnt_i && (data_rvalid_i || (cap_rx_fsm_q == 3'd2)))
						ls_fsm_ns = 4'd0;
					else if (data_gnt_i)
						ls_fsm_ns = 4'd7;
				end
				else
					ls_fsm_ns = 4'd0;
			4'd7:
				if (cheriot_enable_i == ibex_pkg_IbexMuBiOn) begin
					addr_incr_req_o = 1'b1;
					data_req_o = 1'b0;
					if (data_rvalid_i)
						ls_fsm_ns = 4'd0;
				end
				else
					ls_fsm_ns = 4'd0;
			default: ls_fsm_ns = 4'd0;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		cap_rx_fsm_d = cap_rx_fsm_q;
		(* full_case, parallel_case *)
		case (cap_rx_fsm_q)
			3'd0:
				if (((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) & lsu_go_goodcap)
					cap_rx_fsm_d = 3'd1;
			3'd1:
				if (data_rvalid_i)
					cap_rx_fsm_d = 3'd2;
			3'd2:
				if (data_rvalid_i && lsu_go_goodcap)
					cap_rx_fsm_d = 3'd1;
				else if (data_rvalid_i)
					cap_rx_fsm_d = 3'd0;
			default: cap_rx_fsm_d = 3'd0;
		endcase
	end
	wire lsu_req_done;
	assign lsu_req_done = (lsu_go | (ls_fsm_cs != 4'd0)) & (ls_fsm_ns == 4'd0);
	assign lsu_req_done_o = lsu_req_done;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ls_fsm_cs <= 4'd0;
			handle_misaligned_q <= 1'sb0;
			pmp_err_q <= 1'sb0;
			lsu_err_q <= 1'sb0;
			resp_is_cap_q <= 1'b0;
			resp_lc_clrperm_q <= 1'sb0;
			cheriot_err_q <= 1'b0;
			cap_rx_fsm_q <= 3'd0;
			cap_lsw_err_q <= 1'b0;
			cap_lsw_data_q <= 1'sb0;
			cap_lsw_tag_q <= 1'b0;
		end
		else begin
			ls_fsm_cs <= ls_fsm_ns;
			handle_misaligned_q <= handle_misaligned_d;
			pmp_err_q <= pmp_err_d;
			lsu_err_q <= lsu_err_d;
			cheriot_err_q <= cheriot_err_d;
			cap_rx_fsm_q <= cap_rx_fsm_d;
			if (lsu_go) begin
				resp_is_cap_q <= lsu_is_cap_i;
				resp_lc_clrperm_q <= lsu_lc_clrperm_i;
			end
			if (((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && (cap_rx_fsm_q == 3'd1)) && data_rvalid_i) && ~data_we_q) begin
				cap_lsw_data_q <= data_rdata_i[31:0];
				cap_lsw_tag_q <= data_tag_i;
			end
			if ((((BaseIsa == 32'sd1) & (cheriot_enable_i == ibex_pkg_IbexMuBiOn)) && (cap_rx_fsm_q == 3'd1)) && data_rvalid_i)
				cap_lsw_err_q <= data_bus_err_i;
		end
	wire all_resp;
	assign data_or_pmp_err = ((lsu_err_q | data_bus_err_i) | pmp_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & (cheriot_err_q | (resp_is_cap_q & cap_lsw_err_q)));
	assign all_resp = (data_rvalid_i | pmp_err_q) | ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_err_q);
	assign lsu_resp_valid_o = all_resp & (ls_fsm_cs == 4'd0);
	assign lsu_rdata_valid_o = ((((ls_fsm_cs == 4'd0) & data_rvalid_i) & ~data_or_pmp_err) & ~data_we_q) & ~data_intg_err;
	function automatic [5:0] sv2v_cast_B8199;
		input reg [5:0] inp;
		sv2v_cast_B8199 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_AFEA1;
		input reg [2:0] inp;
		sv2v_cast_AFEA1 = inp;
	endfunction
	function automatic [3:0] sv2v_cast_EAC0E;
		input reg [3:0] inp;
		sv2v_cast_EAC0E = inp;
	endfunction
	function automatic [8:0] sv2v_cast_2E4C7;
		input reg [8:0] inp;
		sv2v_cast_2E4C7 = inp;
	endfunction
	localparam [34:0] ibex_cheriot_pkg_NULL_CAP = {4'b0000, sv2v_cast_B8199(1'sb0), sv2v_cast_AFEA1(1'sb0), sv2v_cast_EAC0E(1'sb0), sv2v_cast_2E4C7(1'sb0), sv2v_cast_2E4C7(1'sb0)};
	localparam [31:0] ibex_cheriot_pkg_BASE_LO = 0;
	localparam [31:0] ibex_cheriot_pkg_TOP_LO = ibex_cheriot_pkg_BASE_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_CEXP_LO = ibex_cheriot_pkg_TOP_LO + ibex_cheriot_pkg_CBOUND_W;
	localparam [31:0] ibex_cheriot_pkg_OTYPE_LO = ibex_cheriot_pkg_CEXP_LO + ibex_cheriot_pkg_CEXP_W;
	localparam [31:0] ibex_cheriot_pkg_CPERMS_LO = ibex_cheriot_pkg_OTYPE_LO + ibex_cheriot_pkg_OTYPE_W;
	localparam [2:0] ibex_cheriot_pkg_OTYPE_UNSEALED = 3'd0;
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
	localparam [3:0] ibex_cheriot_pkg_MAXCEXP = 4'd15;
	localparam [31:0] ibex_cheriot_pkg_EXP_W = 5;
	localparam [4:0] ibex_cheriot_pkg_MAXEXP = 5'd24;
	function automatic [4:0] ibex_cheriot_pkg_cheriot_expand_exp;
		input reg [3:0] cexp;
		ibex_cheriot_pkg_cheriot_expand_exp = (cexp == ibex_cheriot_pkg_MAXCEXP ? ibex_cheriot_pkg_MAXEXP : {1'b0, cexp});
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
	generate
		if (BaseIsa == 32'sd1) begin : gen_memcap_rd
			assign lsu_rdata_o = ((cheriot_enable_i == ibex_pkg_IbexMuBiOn) & resp_is_cap_q ? cap_lsw_data_q : data_rdata_ext);
			assign lsu_rcap_o = (((((cheriot_enable_i == ibex_pkg_IbexMuBiOn) && resp_is_cap_q) && data_rvalid_i) && (cap_rx_fsm_q == 3'd2)) && ~data_or_pmp_err ? ibex_cheriot_pkg_cheriot_mem_to_cap({data_tag_i, data_rdata_i[31:0]}, {cap_lsw_tag_q, cap_lsw_data_q}, resp_lc_clrperm_q) : ibex_cheriot_pkg_NULL_CAP);
		end
		else begin : gen_no_cap_rd
			assign lsu_rdata_o = data_rdata_ext;
			assign lsu_rcap_o = ibex_cheriot_pkg_NULL_CAP;
			wire unused_cap_rd_sigs;
			assign unused_cap_rd_sigs = ^{resp_lc_clrperm_q, cap_lsw_data_q, cap_lsw_tag_q, data_tag_i};
		end
	endgenerate
	assign data_addr_w_aligned = {data_addr[31:2], 2'b00};
	assign data_addr_o = data_addr_w_aligned;
	assign data_we_o = lsu_we_i;
	assign data_be_o = data_be;
	generate
		if (MemECC) begin : g_mem_wdata_ecc
			prim_secded_inv_39_32_enc u_data_gen(
				.data_i(data_wdata_data),
				.data_o(data_wdata_o)
			);
		end
		else begin : g_no_mem_wdata_ecc
			assign data_wdata_o = data_wdata_data;
		end
	endgenerate
	assign data_tag_o = data_wdata_tag;
	assign addr_last_o = addr_last_q;
	assign load_err_o = (data_or_pmp_err & ~data_we_q) & lsu_resp_valid_o;
	assign store_err_o = (data_or_pmp_err & data_we_q) & lsu_resp_valid_o;
	assign load_resp_intg_err_o = (data_intg_err & data_rvalid_i) & ~data_we_q;
	assign store_resp_intg_err_o = (data_intg_err & data_rvalid_i) & data_we_q;
	assign lsu_err_is_cheriot_o = (cheriot_enable_i == ibex_pkg_IbexMuBiOn) & cheriot_err_q;
	assign busy_o = ls_fsm_cs != 4'd0;
	initial _sv2v_0 = 0;
endmodule
