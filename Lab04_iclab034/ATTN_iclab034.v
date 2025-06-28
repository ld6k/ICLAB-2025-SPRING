//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Two Head Attention
//   Author     		: Yu-Chi Lin (a6121461214.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : ATTN.v
//   Module Name : ATTN
//   Release version : V1.0 (Release Date: 2025-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


module ATTN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    in_str,
    q_weight,
    k_weight,
    v_weight,
    out_weight,

    //Output Port
    out_valid,
    out
    );

	//---------------------------------------------------------------------
	//   PARAMETER
	//---------------------------------------------------------------------
	integer i, j, k, l;
	// IEEE floating point parameter
	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch_type = 0;
	parameter inst_arch = 0;
	parameter inst_faithful_round = 0;
	parameter sqare_root_2      = 32'b00111111101101010000010011110011;
	parameter rcp_square_root_2 = 32'b00111111001101010000010011110011;

	parameter IDLE = 3'd0;
	parameter IN = 3'd1;
	parameter CAL = 3'd2;
	parameter OUT = 3'd3;

	input rst_n, clk, in_valid;
	input [inst_sig_width+inst_exp_width:0] in_str, q_weight, k_weight, v_weight, out_weight;

	output reg	out_valid;
	output reg [inst_sig_width+inst_exp_width:0] out;

	//---------------------------------------------------------------------
	//   Reg & Wires
	//---------------------------------------------------------------------
	reg  [7:0] cnt;
	reg  [inst_sig_width+inst_exp_width:0] in_str_r   [0:4][0:3];
	reg  [inst_sig_width+inst_exp_width:0] q_weight_r [0:3][0:3];
	reg  [inst_sig_width+inst_exp_width:0] k_weight_r [0:3][0:3];
	reg  [inst_sig_width+inst_exp_width:0] v_weight_r [0:3][0:3];
	reg  [inst_sig_width+inst_exp_width:0] o_weight_r [0:3][0:3];

	reg  [inst_sig_width+inst_exp_width:0] K [0:4][0:3];
	reg  [inst_sig_width+inst_exp_width:0] V [0:4][0:3];
	reg  [inst_sig_width+inst_exp_width:0] Q [0:4][0:3];


	reg  [inst_sig_width+inst_exp_width:0] mac_1_a, mac_1_b, mac_1_c;
	wire [inst_sig_width+inst_exp_width:0] mac_1_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_2_a, mac_2_b, mac_2_c;
	wire [inst_sig_width+inst_exp_width:0] mac_2_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_3_a, mac_3_b, mac_3_c;
	wire [inst_sig_width+inst_exp_width:0] mac_3_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_4_a, mac_4_b, mac_4_c;
	wire [inst_sig_width+inst_exp_width:0] mac_4_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_5_a, mac_5_b, mac_5_c;
	wire [inst_sig_width+inst_exp_width:0] mac_5_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_6_a, mac_6_b, mac_6_c;
	wire [inst_sig_width+inst_exp_width:0] mac_6_z;

	reg  [inst_sig_width+inst_exp_width:0] mac_7_a, mac_7_b, mac_7_c;
	wire [inst_sig_width+inst_exp_width:0] mac_7_z;

	reg  [inst_sig_width+inst_exp_width:0] dp4_1_a, dp4_1_b, dp4_1_c, dp4_1_d, dp4_1_e, dp4_1_f, dp4_1_g, dp4_1_h;
	wire [inst_sig_width+inst_exp_width:0] dp4_1_z;

	reg  [inst_sig_width+inst_exp_width:0] dp2_1_a, dp2_1_b, dp2_1_c, dp2_1_d;
	wire [inst_sig_width+inst_exp_width:0] dp2_1_z;

	reg  [inst_sig_width+inst_exp_width:0] dp2_2_a, dp2_2_b, dp2_2_c, dp2_2_d;
	wire [inst_sig_width+inst_exp_width:0] dp2_2_z;

	reg  [inst_sig_width+inst_exp_width:0] div_1_a, div_1_b;
	wire [inst_sig_width+inst_exp_width:0] div_1_z;

	reg  [inst_sig_width+inst_exp_width:0] div_2_a, div_2_b;
	wire [inst_sig_width+inst_exp_width:0] div_2_z;

	reg  [inst_sig_width+inst_exp_width:0] exp_1_a;
	wire [inst_sig_width+inst_exp_width:0] exp_1_z;

	reg  [inst_sig_width+inst_exp_width:0] exp_2_a;
	wire [inst_sig_width+inst_exp_width:0] exp_2_z;

	reg  [inst_sig_width+inst_exp_width:0] add_1_a, add_1_b;
	wire [inst_sig_width+inst_exp_width:0] add_1_z;

	reg  [inst_sig_width+inst_exp_width:0] add_2_a, add_2_b;
	wire [inst_sig_width+inst_exp_width:0] add_2_z;

	reg  [inst_sig_width+inst_exp_width:0] div_s1_a, div_s1_b;
	wire [inst_sig_width+inst_exp_width:0] div_s1_z;

	reg  [inst_sig_width+inst_exp_width:0] div_s2_a, div_s2_b;
	wire [inst_sig_width+inst_exp_width:0] div_s2_z;



	wire [7:0] NULL [8:0];

	reg flush_trigger_mac_23;
	reg flush_trigger_mac_567;

	reg [31:0] exp_val_1 [0:4];
	reg [31:0] exp_val_2 [0:4];

	reg [31:0] ad_2_a_fw_1;
	reg [31:0] ad_2_a_fw_2;
	reg [31:0] ad_2_a_fw_3;
	reg [31:0] ad_2_a_fw_4;

	reg [31:0] ad_1_a_fw_1;
	reg [31:0] ad_1_a_fw_2;
	reg [31:0] ad_1_a_fw_3;
	reg [31:0] ad_1_a_fw_4;


	reg [31:0] exp_1_pipeline;
	reg [31:0] exp_2_pipeline;

	wire [31:0] fz_dp2_dv_1, fz_dp2_dv_2;

	reg o_r;

	//---------------------------------------------------------------------
	// IPs
	//---------------------------------------------------------------------
	// mac
	mac_no_pipe_1  mac_1 (.a(mac_1_a), .b(mac_1_b), .c(mac_1_c), .z(mac_1_z));
	mac_no_pipe_1  mac_2 (.a(mac_2_a), .b(mac_2_b), .c(mac_2_c), .z(mac_2_z));
	mac_no_pipe_1  mac_3 (.a(mac_3_a), .b(mac_3_b), .c(mac_3_c), .z(mac_3_z));
	mac_no_pipe_1  mac_4 (.a(mac_4_a), .b(mac_4_b), .c(mac_4_c), .z(mac_4_z));
	mac_no_pipe_1  mac_5 (.a(mac_5_a), .b(mac_5_b), .c(mac_5_c), .z(mac_5_z));
	mac_no_pipe_1  mac_6 (.a(mac_6_a), .b(mac_6_b), .c(mac_6_c), .z(mac_6_z));
	mac_no_pipe_1  mac_7 (.a(mac_7_a), .b(mac_7_b), .c(mac_7_c), .z(mac_7_z));

	dp4_no_pipe dp4_1 (.a(dp4_1_a), .b(dp4_1_b), .c(dp4_1_c), .d(dp4_1_d), .e(dp4_1_e), .f(dp4_1_f), .g(dp4_1_g), .h(dp4_1_h), .z(dp4_1_z));

	// dot 2
	dot2_no_pipe dp2_1 (.a(dp2_1_a), .b(dp2_1_b), .c(dp2_1_c), .d(dp2_1_d), .z(fz_dp2_dv_1));
	dot2_no_pipe dp2_2 (.a(dp2_2_a), .b(dp2_2_b), .c(dp2_2_c), .d(dp2_2_d), .z(fz_dp2_dv_2));

	// div
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	DIV1 ( .a(fz_dp2_dv_1), .b(rcp_square_root_2), .z(div_1_z), .rnd(3'b000), .status(NULL[0]));

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	DIV2 ( .a(fz_dp2_dv_2), .b(rcp_square_root_2), .z(div_2_z), .rnd(3'b000), .status(NULL[1]));

	DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
	EXP1 ( .a(exp_1_a), .z(exp_1_z), .status(NULL[2]));

	DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch)
	EXP2 ( .a(exp_2_a), .z(exp_2_z), .status(NULL[3]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD1 ( .a(add_1_a), .b(add_1_b), .z(add_1_z), .rnd(3'b000), .status(NULL[4]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD2 ( .a(add_2_a), .b(add_2_b), .z(add_2_z), .rnd(3'b000), .status(NULL[5]));

	DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
	DIVs1 ( .a(div_s1_a), .b(div_s1_b), .z(div_s1_z), .rnd(3'b000), .status(NULL[6]));

	DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_faithful_round)
	DIVs2 ( .a(div_s2_a), .b(div_s2_b), .z(div_s2_z), .rnd(3'b000), .status(NULL[7]));

	//---------------------------------------------------------------------
	// Design
	//---------------------------------------------------------------------

	always @(posedge clk or negedge rst_n) begin
	    if (~rst_n) begin
			cnt <= 'd0;
		end
		else begin
			if (in_valid) begin
				cnt <= cnt + 'b1;
			end
			else if (cnt == 'd54) begin
				cnt <= 'd0;
			end
			else if (cnt > 'd0) begin
				cnt <= cnt + 'b1;
			end
			else begin
				cnt <= 'd0;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 4; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					q_weight_r[i][j] <= 'd0;
					v_weight_r[i][j] <= 'd0;
					o_weight_r[i][j] <= 'd0;
				end
			end
		end
		else begin
			if (cnt < 'd16 && in_valid) begin
				q_weight_r[cnt[3:2]][cnt[1:0]] <= q_weight;
				v_weight_r[cnt[3:2]][cnt[1:0]] <= v_weight;
				o_weight_r[cnt[3:2]][cnt[1:0]] <= out_weight;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			o_r <= 'd0;
		end
		else begin
			if (cnt < 'd15 || cnt == 'd54) begin
				o_r <= 1'b1;
			end
			else begin
				o_r <= 1'b0;
			end
		end
	end
	

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					in_str_r[i][j] <= 'd0;
				end
			end
		end
		else begin
			if (cnt < 'd20 && in_valid) begin
				in_str_r[cnt[4:2]][cnt[1:0]] <= in_str;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			out_valid <= 'd0;
		end
		else if (cnt == 'd34) begin
			out_valid <= 'd1;
		end
		else if (cnt == 'd54) begin
			out_valid <= 'd0;
		end
	end




	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			out <= 'b0;
		end
		else begin
			if (cnt > 'd33 && cnt < 'd54) begin
				out <= dp4_1_z;
			end
			else if (cnt == 'd54) begin
				out <= 'd0;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_4_c <= 'd0;
		end
		else begin
			if (cnt == 'd0 || cnt == 'd4 || cnt == 'd8 || cnt == 'd12 || cnt == 'd16 || cnt == 'd20 || cnt == 'd24 || cnt == 'd29 || cnt == 'd34 || cnt == 'd39 || cnt == 'd44) begin
				mac_4_c <= 'd0;
			end
			else begin
				mac_4_c <= mac_4_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_1_c <= 'd0;
		end
		else begin
			if (cnt == 'd0 || cnt == 'd4 || cnt == 'd8 || cnt == 'd12 || cnt == 'd16 || cnt == 'd20 || cnt == 'd24 || cnt == 'd29 || cnt == 'd34 || cnt == 'd39 || cnt == 'd44) begin
				mac_1_c <= 'd0;
			end
			else begin
				mac_1_c <= mac_1_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			flush_trigger_mac_23 <= 'd0;
		end
		else begin
			if (cnt == 'd3 || cnt == 'd7 || cnt == 'd11 || cnt == 'd15 || cnt == 'd19 || cnt == 'd23 || cnt == 'd28 || cnt == 'd33 || cnt == 'd38 || cnt == 'd43) begin
				flush_trigger_mac_23 <= 'd1;
			end
			else begin
				flush_trigger_mac_23 <= 'd0;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_2_c <= 'd0;
		end
		else begin
			if (flush_trigger_mac_23) begin
				mac_2_c <= 'd0;
			end
			else begin
				mac_2_c <= mac_2_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_3_c <= 'd0;
		end
		else begin
			if (flush_trigger_mac_23) begin
				mac_3_c <= 'd0;
			end
			else begin
				mac_3_c <= mac_3_z;
			end
		end
	end

	
	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			flush_trigger_mac_567 <= 'd0;
		end
		else begin
			if (cnt[1:0] == 2'b11) begin
				flush_trigger_mac_567 <= 'd1;
			end
			else begin
				flush_trigger_mac_567 <= 'd0;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_5_c <= 'd0;
		end
		else begin
			if (flush_trigger_mac_567) begin
				mac_5_c <= 'd0;
			end
			else begin
				mac_5_c <= mac_5_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_6_c <= 'd0;
		end
		else begin
			if (flush_trigger_mac_567) begin
				mac_6_c <= 'd0;
			end
			else begin
				mac_6_c <= mac_6_z;
			end
		end
	end
	

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_7_c <= 'd0;
		end
		else begin
			if (flush_trigger_mac_567) begin
				mac_7_c <= 'd0;
			end
			else begin
				mac_7_c <= mac_7_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					Q[i][j] <= 'd0;
				end
			end
		end
		else begin
			// if (cnt == 'd0) begin
			// 	for (i = 0; i < 5; i = i + 1) begin
			// 		for (j = 0; j < 4; j = j + 1) begin
			// 			Q[i][j] <= 'd0;
			// 		end
			// 	end
			// end
			// else begin
				case (cnt)
					'd1, 'd2, 'd3, 'd4: begin
						Q[0][0] <= mac_1_z;
					end
					'd5, 'd6, 'd7, 'd8: begin
						Q[0][1] <= mac_1_z;
						Q[1][0] <= mac_2_z;
						Q[1][1] <= mac_3_z;
					end
					'd9, 'd10, 'd11, 'd12: begin
						Q[0][2] <= mac_1_z;
						Q[1][2] <= mac_2_z;
						Q[2][0] <= mac_3_z;
					end
					'd13, 'd14, 'd15, 'd16: begin
						Q[0][3] <= mac_1_z;
					end
					'd17, 'd18, 'd19, 'd20: begin
						Q[1][3] <= mac_1_z;
					end
					'd21, 'd22, 'd23: begin
						Q[2][1] <= mac_1_z;
						Q[2][2] <= mac_2_z;
						Q[2][3] <= mac_3_z;
					end
					'd24: begin
						Q[2][1] <= mac_1_z;
						Q[2][2] <= mac_2_z;
						Q[2][3] <= mac_3_z;
						Q[3][0] <= dp4_1_z;
					end
					'd25: begin
						Q[3][1] <= dp4_1_z;
					end
					'd26: begin
						Q[3][2] <= dp4_1_z;
					end
					'd27: begin
						Q[3][3] <= dp4_1_z;
					end
					'd28: begin
						Q[4][0] <= dp4_1_z;
					end
					'd29: begin
						Q[4][1] <= dp4_1_z;
					end
					'd30: begin
						Q[4][2] <= dp4_1_z;
					end
					'd31: begin
						Q[4][3] <= dp4_1_z;
					end
				endcase
			// end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					K[i][j] <= 'd0;
				end
			end
		end
		else begin
			// if (cnt == 'd0) begin
			// 	for (i = 0; i < 5; i = i + 1) begin
			// 		for (j = 0; j < 4; j = j + 1) begin
			// 			K[i][j] <= 'd0;
			// 		end
			// 	end
			// end
			// else begin
				case (cnt)
					'd1, 'd2, 'd3, 'd4: begin
						K[0][0] <= mac_4_z;
					end
					'd5, 'd6, 'd7, 'd8: begin
						K[0][1] <= mac_4_z;
						K[1][0] <= mac_5_z;
						K[1][1] <= mac_6_z;
					end
					'd9: begin
						K[0][2] <= mac_4_z;
						K[1][2] <= mac_5_z;
						K[2][0] <= mac_6_z;
						K[2][2] <= mac_7_z;
					end
					'd10: begin
						K[0][2] <= mac_4_z;
						K[1][2] <= mac_5_z;
						K[2][0] <= mac_6_z;
						K[2][2] <= mac_7_z;
					end
					'd11: begin
						K[0][2] <= mac_4_z;
						K[1][2] <= mac_5_z;
						K[2][0] <= mac_6_z;
						K[2][2] <= mac_7_z;
					end
					'd12: begin
						K[0][2] <= mac_4_z;
						K[1][2] <= mac_5_z;
						K[2][0] <= mac_6_z;
						K[2][1] <= dp4_1_z;
						K[2][2] <= mac_7_z;
					end
					'd13, 'd14, 'd15, 'd16: begin
						K[2][3] <= mac_2_z;
						K[1][3] <= mac_3_z;
						K[0][3] <= mac_4_z;
						K[3][0] <= mac_5_z;
						K[3][1] <= mac_6_z;
						K[3][3] <= mac_7_z;
					end
					'd17: begin
						K[4][2] <= mac_2_z;
						K[4][1] <= mac_3_z;
						K[4][0] <= mac_4_z;
						K[4][3] <= mac_5_z;
						K[3][2] <= dp4_1_z;
					end
					'd18: begin
						K[4][2] <= mac_2_z;
						K[4][1] <= mac_3_z;
						K[4][0] <= mac_4_z;
						K[4][3] <= mac_5_z;
					end
					'd19: begin
						K[4][2] <= mac_2_z;
						K[4][1] <= mac_3_z;
						K[4][0] <= mac_4_z;
						K[4][3] <= mac_5_z;
					end
					'd20: begin
						K[4][2] <= mac_2_z;
						K[4][1] <= mac_3_z;
						K[4][0] <= mac_4_z;
						K[4][3] <= mac_5_z;
					end
				endcase
			// end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					V[i][j] <= 'd0;
				end
			end
		end
		else begin
			// if (cnt == 'd0) begin
			// 	for (i = 0; i < 5; i = i + 1) begin
			// 		for (j = 0; j < 4; j = j + 1) begin
			// 			V[i][j] <= 'd0;
			// 		end
			// 	end
			// end
			// else begin
				case (cnt)
					'd1, 'd2, 'd3, 'd4: begin
					end
					'd8: begin
						V[0][0] <= dp4_1_z;
					end
					'd9: begin
						V[0][1] <= dp4_1_z;
					end
					'd10: begin
						V[1][0] <= dp4_1_z;
					end
					'd11: begin
						V[1][1] <= dp4_1_z;
					end
					'd13: begin
						V[0][2] <= dp4_1_z;
					end
					'd14: begin
						V[2][0] <= dp4_1_z;
					end
					'd15: begin
						V[2][1] <= dp4_1_z;
					end
					'd16: begin
						V[2][3] <= dp4_1_z;
					end
					'd17: begin
						V[3][0] <= mac_7_z;
						V[0][3] <= mac_6_z;
					end
					'd18: begin
						V[3][0] <= mac_7_z;
						V[0][3] <= mac_6_z;
						V[3][1] <= dp4_1_z;
					end
					'd19: begin
						V[3][0] <= mac_7_z;
						V[0][3] <= mac_6_z;
						V[3][2] <= dp4_1_z;
					end
					'd20: begin
						V[3][0] <= mac_7_z;
						V[0][3] <= mac_6_z;
						V[4][0] <= dp4_1_z;
					end
					'd21: begin
						V[1][2] <= mac_4_z;
						V[2][2] <= mac_5_z;
						V[1][3] <= mac_6_z;
						V[3][3] <= mac_7_z;
						V[4][1] <= dp4_1_z;
					end
					'd22: begin
						V[1][2] <= mac_4_z;
						V[2][2] <= mac_5_z;
						V[1][3] <= mac_6_z;
						V[3][3] <= mac_7_z;
						V[4][2] <= dp4_1_z;
					end
					'd23: begin
						V[1][2] <= mac_4_z;
						V[2][2] <= mac_5_z;
						V[1][3] <= mac_6_z;
						V[3][3] <= mac_7_z;
						V[4][3] <= dp4_1_z;
					end
					'd24: begin
						V[1][2] <= mac_4_z;
						V[2][2] <= mac_5_z;
						V[1][3] <= mac_6_z;
						V[3][3] <= mac_7_z;
					end
				endcase
			// end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_1_a <= 'd0;
			mac_1_b <= 'd0;
		end
		else begin
			case (cnt)
				// Q00
				'd0, 'd1, 'd2, 'd3: begin
					mac_1_a <= in_str;
					mac_1_b <= q_weight;
				end
				// Q01
				'd4: begin
					mac_1_a <= in_str_r  [0][0];
					mac_1_b <= q_weight;
				end
				'd5: begin
					mac_1_a <= in_str_r  [0][1];
					mac_1_b <= q_weight;
				end
				'd6: begin
					mac_1_a <= in_str_r  [0][2];
					mac_1_b <= q_weight;
				end
				'd7: begin
					mac_1_a <= in_str_r  [0][3];
					mac_1_b <= q_weight;
				end
				// Q02
				'd8: begin
					mac_1_a <= in_str_r  [0][0];
					mac_1_b <= q_weight;
				end
				'd9: begin
					mac_1_a <= in_str_r  [0][1];
					mac_1_b <= q_weight;
				end
				'd10: begin
					mac_1_a <= in_str_r  [0][2];
					mac_1_b <= q_weight;
				end
				'd11: begin
					mac_1_a <= in_str_r  [0][3];
					mac_1_b <= q_weight;
				end
				// Q03
				'd12: begin
					mac_1_a <= in_str_r  [0][0];
					mac_1_b <= q_weight;
				end
				'd13: begin
					mac_1_a <= in_str_r  [0][1];
					mac_1_b <= q_weight;
				end
				'd14: begin
					mac_1_a <= in_str_r  [0][2];
					mac_1_b <= q_weight;
				end
				'd15: begin
					mac_1_a <= in_str_r  [0][3];
					mac_1_b <= q_weight;
				end
				// Q13
				'd16: begin
					mac_1_a <= in_str_r   [1][0];
					mac_1_b <= q_weight_r [3][0];
				end
				'd17: begin
					mac_1_a <= in_str_r   [1][1];
					mac_1_b <= q_weight_r [3][1];
				end
				'd18: begin
					mac_1_a <= in_str_r   [1][2];
					mac_1_b <= q_weight_r [3][2];
				end
				'd19: begin
					mac_1_a <= in_str_r   [1][3];
					mac_1_b <= q_weight_r [3][3];
				end
				// Q21
				'd20: begin
					mac_1_a <= in_str_r   [2][0];
					mac_1_b <= q_weight_r [1][0];
				end
				'd21: begin
					mac_1_a <= in_str_r   [2][1];
					mac_1_b <= q_weight_r [1][1];
				end
				'd22: begin
					mac_1_a <= in_str_r   [2][2];
					mac_1_b <= q_weight_r [1][2];
				end
				'd23: begin
					mac_1_a <= in_str_r   [2][3];
					mac_1_b <= q_weight_r [1][3];
				end
				// HO
				'd24: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [0][0];
				end
				'd25: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [1][0];
				end
				'd26: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [2][0];
				end
				'd27: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [3][0];
				end
				'd28: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [4][0];
				end
				'd29: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [0][0];
				end
				'd30: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [1][0];
				end
				'd31: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [2][0];
				end
				'd32: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [3][0];
				end
				'd33: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [4][0];
				end
				'd34: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [0][0];
				end
				'd35: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [1][0];
				end
				'd36: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [2][0];
				end
				'd37: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [3][0];
				end
				'd38: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [4][0];
				end
				'd39: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [0][0];
				end
				'd40: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [1][0];
				end
				'd41: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [2][0];
				end
				'd42: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [3][0];
				end
				'd43: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [4][0];
				end
				'd44: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [0][0];
				end
				'd45: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [1][0];
				end
				'd46: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [2][0];
				end
				'd47: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [3][0];
				end
				'd48: begin
					mac_1_a <= div_s1_z;
					mac_1_b <= V [4][0];
				end
				'd54: begin
					mac_1_a <= 'd0;
					mac_1_b <= 'd0;
				end

				default: begin
					mac_1_a <= 'd0;
					mac_1_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_2_a <= 'd0;
			mac_2_b <= 'd0;
		end
		else begin
			case (cnt)
				// Q10
				'd4: begin
					mac_2_a <= in_str;
					mac_2_b <= q_weight_r [0][0];
				end
				'd5: begin
					mac_2_a <= in_str;
					mac_2_b <= q_weight_r [0][1];
				end
				'd6: begin
					mac_2_a <= in_str;
					mac_2_b <= q_weight_r [0][2];
				end
				'd7: begin
					mac_2_a <= in_str;
					mac_2_b <= q_weight_r [0][3];
				end
				// Q12
				'd8: begin
					mac_2_a <= in_str_r   [1][0];
					mac_2_b <= q_weight;
				end
				'd9: begin
					mac_2_a <= in_str_r   [1][1];
					mac_2_b <= q_weight;
				end
				'd10: begin
					mac_2_a <= in_str_r   [1][2];
					mac_2_b <= q_weight;
				end
				'd11: begin
					mac_2_a <= in_str_r   [1][3];
					mac_2_b <= q_weight;
				end
				// K23
				'd12: begin
					mac_2_a <= in_str_r   [2][0];
					mac_2_b <= k_weight;
				end
				'd13: begin
					mac_2_a <= in_str_r   [2][1];
					mac_2_b <= k_weight;
				end
				'd14: begin
					mac_2_a <= in_str_r   [2][2];
					mac_2_b <= k_weight;
				end
				'd15: begin
					mac_2_a <= in_str_r   [2][3];
					mac_2_b <= k_weight;
				end
				// K42
				'd16: begin
					mac_2_a <= in_str;
					mac_2_b <= k_weight_r [2][0];
				end
				'd17: begin
					mac_2_a <= in_str;
					mac_2_b <= k_weight_r [2][1];
				end
				'd18: begin
					mac_2_a <= in_str;
					mac_2_b <= k_weight_r [2][2];
				end
				'd19: begin
					mac_2_a <= in_str;
					mac_2_b <= k_weight_r [2][3];
				end
				// Q22
				'd20: begin
					mac_2_a <= in_str_r   [2][0];
					mac_2_b <= q_weight_r [2][0];
				end
				'd21: begin
					mac_2_a <= in_str_r   [2][1];
					mac_2_b <= q_weight_r [2][1];
				end
				'd22: begin
					mac_2_a <= in_str_r   [2][2];
					mac_2_b <= q_weight_r [2][2];
				end
				'd23: begin
					mac_2_a <= in_str_r   [2][3];
					mac_2_b <= q_weight_r [2][3];
				end
				// HO
				'd24: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [0][1];
				end
				'd25: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [1][1];
				end
				'd26: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [2][1];
				end
				'd27: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [3][1];
				end
				'd28: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [4][1];
				end
				'd29: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [0][1];
				end
				'd30: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [1][1];
				end
				'd31: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [2][1];
				end
				'd32: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [3][1];
				end
				'd33: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [4][1];
				end
				'd34: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [0][1];
				end
				'd35: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [1][1];
				end
				'd36: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [2][1];
				end
				'd37: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [3][1];
				end
				'd38: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [4][1];
				end
				'd39: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [0][1];
				end
				'd40: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [1][1];
				end
				'd41: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [2][1];
				end
				'd42: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [3][1];
				end
				'd43: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [4][1];
				end
				'd44: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [0][1];
				end
				'd45: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [1][1];
				end
				'd46: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [2][1];
				end
				'd47: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [3][1];
				end
				'd48: begin
					mac_2_a <= div_s1_z;
					mac_2_b <= V [4][1];
				end

				default: begin
					mac_2_a <= 'd0;
					mac_2_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_3_a <= 'd0;
			mac_3_b <= 'd0;
		end
		else begin
			case (cnt)
				// Q11
				'd4: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight;
				end
				'd5: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight;
				end
				'd6: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight;
				end
				'd7: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight;
				end
				// Q20
				'd8: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight_r [0][0];
				end
				'd9: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight_r [0][1];
				end
				'd10: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight_r [0][2];
				end
				'd11: begin
					mac_3_a <= in_str;
					mac_3_b <= q_weight_r [0][3];
				end
				// K13
				'd12: begin
					mac_3_a <= in_str_r   [1][0];
					mac_3_b <= k_weight;
				end
				'd13: begin
					mac_3_a <= in_str_r   [1][1];
					mac_3_b <= k_weight;
				end
				'd14: begin
					mac_3_a <= in_str_r   [1][2];
					mac_3_b <= k_weight;
				end
				'd15: begin
					mac_3_a <= in_str_r   [1][3];
					mac_3_b <= k_weight;
				end
				// K41
				'd16: begin
					mac_3_a <= in_str;
					mac_3_b <= k_weight_r [1][0];
				end
				'd17: begin
					mac_3_a <= in_str;
					mac_3_b <= k_weight_r [1][1];
				end
				'd18: begin
					mac_3_a <= in_str;
					mac_3_b <= k_weight_r [1][2];
				end
				'd19: begin
					mac_3_a <= in_str;
					mac_3_b <= k_weight_r [1][3];
				end
				// Q23
				'd20: begin
					mac_3_a <= in_str_r   [2][0];
					mac_3_b <= q_weight_r [3][0];
				end
				'd21: begin
					mac_3_a <= in_str_r   [2][1];
					mac_3_b <= q_weight_r [3][1];
				end
				'd22: begin
					mac_3_a <= in_str_r   [2][2];
					mac_3_b <= q_weight_r [3][2];
				end
				'd23: begin
					mac_3_a <= in_str_r   [2][3];
					mac_3_b <= q_weight_r [3][3];
				end
				// HO
				'd24: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [0][2];
				end
				'd25: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [1][2];
				end
				'd26: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [2][2];
				end
				'd27: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [3][2];
				end
				'd28: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [4][2];
				end
				'd29: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [0][2];
				end
				'd30: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [1][2];
				end
				'd31: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [2][2];
				end
				'd32: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [3][2];
				end
				'd33: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [4][2];
				end
				'd34: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [0][2];
				end
				'd35: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [1][2];
				end
				'd36: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [2][2];
				end
				'd37: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [3][2];
				end
				'd38: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [4][2];
				end
				'd39: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [0][2];
				end
				'd40: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [1][2];
				end
				'd41: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [2][2];
				end
				'd42: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [3][2];
				end
				'd43: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [4][2];
				end
				'd44: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [0][2];
				end
				'd45: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [1][2];
				end
				'd46: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [2][2];
				end
				'd47: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [3][2];
				end
				'd48: begin
					mac_3_a <= div_s2_z;
					mac_3_b <= V [4][2];
				end

				default: begin
					mac_3_a <= 'd0;
					mac_3_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_4_a <= 'd0;
			mac_4_b <= 'd0;
		end
		else begin
			case (cnt)
				// K00
				'd0, 'd1, 'd2, 'd3: begin
					mac_4_a <= in_str;
					mac_4_b <= k_weight;
				end
				// K01
				'd4: begin
					mac_4_a <= in_str_r  [0][0];
					mac_4_b <= k_weight;
				end
				'd5: begin
					mac_4_a <= in_str_r  [0][1];
					mac_4_b <= k_weight;
				end
				'd6: begin
					mac_4_a <= in_str_r  [0][2];
					mac_4_b <= k_weight;
				end
				'd7: begin
					mac_4_a <= in_str_r  [0][3];
					mac_4_b <= k_weight;
				end
				// K02
				'd8: begin
					mac_4_a <= in_str_r  [0][0];
					mac_4_b <= k_weight;
				end
				'd9: begin
					mac_4_a <= in_str_r  [0][1];
					mac_4_b <= k_weight;
				end
				'd10: begin
					mac_4_a <= in_str_r  [0][2];
					mac_4_b <= k_weight;
				end
				'd11: begin
					mac_4_a <= in_str_r  [0][3];
					mac_4_b <= k_weight;
				end
				// K03
				'd12: begin
					mac_4_a <= in_str_r  [0][0];
					mac_4_b <= k_weight;
				end
				'd13: begin
					mac_4_a <= in_str_r  [0][1];
					mac_4_b <= k_weight;
				end
				'd14: begin
					mac_4_a <= in_str_r  [0][2];
					mac_4_b <= k_weight;
				end
				'd15: begin
					mac_4_a <= in_str_r  [0][3];
					mac_4_b <= k_weight;
				end
				// K40
				'd16: begin
					mac_4_a <= in_str;
					mac_4_b <= k_weight_r [0][0];
				end
				'd17: begin
					mac_4_a <= in_str;
					mac_4_b <= k_weight_r [0][1];
				end
				'd18: begin
					mac_4_a <= in_str;
					mac_4_b <= k_weight_r [0][2];
				end
				'd19: begin
					mac_4_a <= in_str;
					mac_4_b <= k_weight_r [0][3];
				end
				// V12
				'd20: begin
					mac_4_a <= in_str_r   [1][0];
					mac_4_b <= v_weight_r [2][0];
				end
				'd21: begin
					mac_4_a <= in_str_r   [1][1];
					mac_4_b <= v_weight_r [2][1];
				end
				'd22: begin
					mac_4_a <= in_str_r   [1][2];
					mac_4_b <= v_weight_r [2][2];
				end
				'd23: begin
					mac_4_a <= in_str_r   [1][3];
					mac_4_b <= v_weight_r [2][3];
				end
				// HO
				'd24: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [0][3];
				end
				'd25: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [1][3];
				end
				'd26: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [2][3];
				end
				'd27: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [3][3];
				end
				'd28: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [4][3];
				end
				'd29: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [0][3];
				end
				'd30: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [1][3];
				end
				'd31: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [2][3];
				end
				'd32: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [3][3];
				end
				'd33: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [4][3];
				end
				'd34: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [0][3];
				end
				'd35: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [1][3];
				end
				'd36: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [2][3];
				end
				'd37: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [3][3];
				end
				'd38: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [4][3];
				end
				'd39: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [0][3];
				end
				'd40: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [1][3];
				end
				'd41: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [2][3];
				end
				'd42: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [3][3];
				end
				'd43: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [4][3];
				end
				'd44: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [0][3];
				end
				'd45: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [1][3];
				end
				'd46: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [2][3];
				end
				'd47: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [3][3];
				end
				'd48: begin
					mac_4_a <= div_s2_z;
					mac_4_b <= V [4][3];
				end

				default: begin
					mac_4_a <= 'd0;
					mac_4_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_5_a <= 'd0;
			mac_5_b <= 'd0;
		end
		else begin
			case (cnt)
				// K10
				'd4: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][0];
				end
				'd5: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][1];
				end
				'd6: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][2];
				end
				'd7: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][3];
				end
				// K12
				'd8: begin
					mac_5_a <= in_str_r  [1][0];
					mac_5_b <= k_weight;
				end
				'd9: begin
					mac_5_a <= in_str_r  [1][1];
					mac_5_b <= k_weight;
				end
				'd10: begin
					mac_5_a <= in_str_r  [1][2];
					mac_5_b <= k_weight;
				end
				'd11: begin
					mac_5_a <= in_str_r  [1][3];
					mac_5_b <= k_weight;
				end
				// K30
				'd12: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][0];
				end
				'd13: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][1];
				end
				'd14: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][2];
				end
				'd15: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [0][3];
				end
				// K43
				'd16: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [3][0];
				end
				'd17: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [3][1];
				end
				'd18: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [3][2];
				end
				'd19: begin
					mac_5_a <= in_str;
					mac_5_b <= k_weight_r [3][3];
				end
				// V22
				'd20: begin
					mac_5_a <= in_str_r   [2][0];
					mac_5_b <= v_weight_r [2][0];
				end
				'd21: begin
					mac_5_a <= in_str_r   [2][1];
					mac_5_b <= v_weight_r [2][1];
				end
				'd22: begin
					mac_5_a <= in_str_r   [2][2];
					mac_5_b <= v_weight_r [2][2];
				end
				'd23: begin
					mac_5_a <= in_str_r   [2][3];
					mac_5_b <= v_weight_r [2][3];
				end
				default: begin
					mac_5_a <= 'd0;
					mac_5_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_6_a <= 'd0;
			mac_6_b <= 'd0;
		end
		else begin
			case (cnt)
				// K11
				'd4: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight;
				end
				'd5: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight;
				end
				'd6: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight;
				end
				'd7: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight;
				end
				// K20
				'd8: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r   [0][0];
				end
				'd9: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r   [0][1];
				end
				'd10: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r   [0][2];
				end
				'd11: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r   [0][3];
				end
				// K31
				'd12: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r [1][0];
				end
				'd13: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r [1][1];
				end
				'd14: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r [1][2];
				end
				'd15: begin
					mac_6_a <= in_str;
					mac_6_b <= k_weight_r [1][3];
				end
				// V03
				'd16: begin
					mac_6_a <= in_str_r   [0][0];
					mac_6_b <= v_weight_r [3][0];
				end
				'd17: begin
					mac_6_a <= in_str_r   [0][1];
					mac_6_b <= v_weight_r [3][1];
				end
				'd18: begin
					mac_6_a <= in_str_r   [0][2];
					mac_6_b <= v_weight_r [3][2];
				end
				'd19: begin
					mac_6_a <= in_str_r   [0][3];
					mac_6_b <= v_weight_r [3][3];
				end
				// V13
				'd20: begin
					mac_6_a <= in_str_r   [1][0];
					mac_6_b <= v_weight_r [3][0];
				end
				'd21: begin
					mac_6_a <= in_str_r   [1][1];
					mac_6_b <= v_weight_r [3][1];
				end
				'd22: begin
					mac_6_a <= in_str_r   [1][2];
					mac_6_b <= v_weight_r [3][2];
				end
				'd23: begin
					mac_6_a <= in_str_r   [1][3];
					mac_6_b <= v_weight_r [3][3];
				end
				default: begin
					mac_6_a <= 'd0;
					mac_6_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			mac_7_a <= 'd0;
			mac_7_b <= 'd0;
		end
		else begin
			case (cnt)
				// K22
				'd8: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd9: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd10: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd11: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				// K33
				'd12: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd13: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd14: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd15: begin
					mac_7_a <= in_str;
					mac_7_b <= k_weight;
				end
				'd16: begin
					mac_7_a <= in_str_r   [3][0];
					mac_7_b <= v_weight_r [0][0];
				end
				'd17: begin
					mac_7_a <= in_str_r   [3][1];
					mac_7_b <= v_weight_r [0][1];
				end
				'd18: begin
					mac_7_a <= in_str_r   [3][2];
					mac_7_b <= v_weight_r [0][2];
				end
				'd19: begin
					mac_7_a <= in_str_r   [3][3];
					mac_7_b <= v_weight_r [0][3];
				end
				// V33
				'd20: begin
					mac_7_a <= in_str_r   [3][0];
					mac_7_b <= v_weight_r [3][0];
				end
				'd21: begin
					mac_7_a <= in_str_r   [3][1];
					mac_7_b <= v_weight_r [3][1];
				end
				'd22: begin
					mac_7_a <= in_str_r   [3][2];
					mac_7_b <= v_weight_r [3][2];
				end
				'd23: begin
					mac_7_a <= in_str_r   [3][3];
					mac_7_b <= v_weight_r [3][3];
				end
				default: begin
					mac_7_a <= 'd0;
					mac_7_b <= 'd0;
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			dp4_1_a <= 'd0;
			dp4_1_b <= 'd0;
			dp4_1_c <= 'd0;
			dp4_1_d <= 'd0;
			dp4_1_e <= 'd0;
			dp4_1_f <= 'd0;
			dp4_1_g <= 'd0;
		end
		else begin
			case (cnt)
				'd7: begin // V00
					dp4_1_a <= in_str_r   [0][0];
					dp4_1_b <= v_weight_r [0][0];

					dp4_1_c <= in_str_r   [0][1];
					dp4_1_d <= v_weight_r [0][1];

					dp4_1_e <= in_str_r   [0][2];
					dp4_1_f <= v_weight_r [0][2];

					dp4_1_g <= in_str_r   [0][3];
					dp4_1_h <= v_weight_r [0][3];
				end
				'd8: begin // V01
					dp4_1_a <= in_str_r   [0][0];
					dp4_1_b <= v_weight_r [1][0];

					dp4_1_c <= in_str_r   [0][1];
					dp4_1_d <= v_weight_r [1][1];

					dp4_1_e <= in_str_r   [0][2];
					dp4_1_f <= v_weight_r [1][2];

					dp4_1_g <= in_str_r   [0][3];
					dp4_1_h <= v_weight_r [1][3];
				end
				'd9: begin // V10
					dp4_1_a <= in_str_r   [1][0];
					dp4_1_b <= v_weight_r [0][0];

					dp4_1_c <= in_str_r   [1][1];
					dp4_1_d <= v_weight_r [0][1];

					dp4_1_e <= in_str_r   [1][2];
					dp4_1_f <= v_weight_r [0][2];

					dp4_1_g <= in_str_r   [1][3];
					dp4_1_h <= v_weight_r [0][3];
				end
				'd10: begin // V11
					dp4_1_a <= in_str_r   [1][0];
					dp4_1_b <= v_weight_r [1][0];

					dp4_1_c <= in_str_r   [1][1];
					dp4_1_d <= v_weight_r [1][1];

					dp4_1_e <= in_str_r   [1][2];
					dp4_1_f <= v_weight_r [1][2];

					dp4_1_g <= in_str_r   [1][3];
					dp4_1_h <= v_weight_r [1][3];
				end
				'd11: begin // K21
					dp4_1_a <= in_str_r   [2][0];
					dp4_1_b <= k_weight_r [1][0];

					dp4_1_c <= in_str_r   [2][1];
					dp4_1_d <= k_weight_r [1][1];

					dp4_1_e <= in_str_r   [2][2];
					dp4_1_f <= k_weight_r [1][2];

					dp4_1_g <= in_str;
					dp4_1_h <= k_weight_r [1][3];
				end
				'd12: begin // V02
					dp4_1_a <= in_str_r   [0][0];
					dp4_1_b <= v_weight_r [2][0];

					dp4_1_c <= in_str_r   [0][1];
					dp4_1_d <= v_weight_r [2][1];

					dp4_1_e <= in_str_r   [0][2];
					dp4_1_f <= v_weight_r [2][2];

					dp4_1_g <= in_str_r   [0][3];
					dp4_1_h <= v_weight_r [2][3];
				end
				'd13: begin // V20
					dp4_1_a <= in_str_r   [2][0];
					dp4_1_b <= v_weight_r [0][0];

					dp4_1_c <= in_str_r   [2][1];
					dp4_1_d <= v_weight_r [0][1];

					dp4_1_e <= in_str_r   [2][2];
					dp4_1_f <= v_weight_r [0][2];

					dp4_1_g <= in_str_r   [2][3];
					dp4_1_h <= v_weight_r [0][3];
				end
				'd14: begin // V21
					dp4_1_a <= in_str_r   [2][0];
					dp4_1_b <= v_weight_r [1][0];

					dp4_1_c <= in_str_r   [2][1];
					dp4_1_d <= v_weight_r [1][1];

					dp4_1_e <= in_str_r   [2][2];
					dp4_1_f <= v_weight_r [1][2];

					dp4_1_g <= in_str_r   [2][3];
					dp4_1_h <= v_weight_r [1][3];
				end
				'd15: begin // V23
					dp4_1_a <= in_str_r   [2][0];
					dp4_1_b <= v_weight_r [3][0];

					dp4_1_c <= in_str_r   [2][1];
					dp4_1_d <= v_weight_r [3][1];

					dp4_1_e <= in_str_r   [2][2];
					dp4_1_f <= v_weight_r [3][2];

					dp4_1_g <= in_str_r   [2][3];
					dp4_1_h <= v_weight;
				end
				'd16: begin // K32
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= k_weight_r [2][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= k_weight_r [2][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= k_weight_r [2][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= k_weight_r [2][3];
				end
				'd17: begin // V31
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= v_weight_r [1][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= v_weight_r [1][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= v_weight_r [1][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= v_weight_r [1][3];
				end
				'd18: begin // V32
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= v_weight_r [2][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= v_weight_r [2][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= v_weight_r [2][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= v_weight_r [2][3];
				end
				'd19: begin // V40
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= v_weight_r [0][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= v_weight_r [0][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= v_weight_r [0][2];

					dp4_1_g <= in_str;
					dp4_1_h <= v_weight_r [0][3];
				end
				'd20: begin // V41
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= v_weight_r [1][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= v_weight_r [1][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= v_weight_r [1][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= v_weight_r [1][3];
				end
				'd21: begin // V42
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= v_weight_r [2][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= v_weight_r [2][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= v_weight_r [2][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= v_weight_r [2][3];
				end
				'd22: begin // V43
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= v_weight_r [3][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= v_weight_r [3][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= v_weight_r [3][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= v_weight_r [3][3];
				end
				'd23: begin // Q30
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= q_weight_r [0][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= q_weight_r [0][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= q_weight_r [0][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= q_weight_r [0][3];
				end
				'd24: begin // Q31
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= q_weight_r [1][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= q_weight_r [1][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= q_weight_r [1][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= q_weight_r [1][3];
				end
				'd25: begin // Q32
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= q_weight_r [2][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= q_weight_r [2][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= q_weight_r [2][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= q_weight_r [2][3];
				end
				'd26: begin // Q33
					dp4_1_a <= in_str_r   [3][0];
					dp4_1_b <= q_weight_r [3][0];

					dp4_1_c <= in_str_r   [3][1];
					dp4_1_d <= q_weight_r [3][1];

					dp4_1_e <= in_str_r   [3][2];
					dp4_1_f <= q_weight_r [3][2];

					dp4_1_g <= in_str_r   [3][3];
					dp4_1_h <= q_weight_r [3][3];
				end
				'd27: begin // Q40
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= q_weight_r [0][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= q_weight_r [0][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= q_weight_r [0][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= q_weight_r [0][3];
				end
				'd28: begin // Q41
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= q_weight_r [1][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= q_weight_r [1][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= q_weight_r [1][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= q_weight_r [1][3];
				end
				'd29: begin // Q42
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= q_weight_r [2][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= q_weight_r [2][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= q_weight_r [2][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= q_weight_r [2][3];
				end
				'd30: begin // Q43
					dp4_1_a <= in_str_r   [4][0];
					dp4_1_b <= q_weight_r [3][0];

					dp4_1_c <= in_str_r   [4][1];
					dp4_1_d <= q_weight_r [3][1];

					dp4_1_e <= in_str_r   [4][2];
					dp4_1_f <= q_weight_r [3][2];

					dp4_1_g <= in_str_r   [4][3];
					dp4_1_h <= q_weight_r [3][3];
				end
				// HO
				'd33: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [0][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [0][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [0][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [0][3];
				end
				'd34: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [1][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [1][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [1][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [1][3];
				end
				'd35: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [2][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [2][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [2][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [2][3];
				end
				'd36: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [3][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [3][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [3][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [3][3];
				end
				'd37: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [0][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [0][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [0][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [0][3];
				end
				'd38: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [1][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [1][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [1][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [1][3];
				end
				'd39: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [2][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [2][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [2][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [2][3];
				end
				'd40: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [3][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [3][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [3][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [3][3];
				end
				'd41: begin
					dp4_1_a <= k_weight_r[2][0];
					dp4_1_b <= o_weight_r [0][0];

					dp4_1_c <= k_weight_r[2][1];
					dp4_1_d <= o_weight_r [0][1];

					dp4_1_e <= k_weight_r[2][2];
					dp4_1_f <= o_weight_r [0][2];

					dp4_1_g <= k_weight_r[2][3];
					dp4_1_h <= o_weight_r [0][3];
				end
				'd42: begin
					dp4_1_a <= k_weight_r[2][0];
					dp4_1_b <= o_weight_r [1][0];

					dp4_1_c <= k_weight_r[2][1];
					dp4_1_d <= o_weight_r [1][1];

					dp4_1_e <= k_weight_r[2][2];
					dp4_1_f <= o_weight_r [1][2];

					dp4_1_g <= k_weight_r[2][3];
					dp4_1_h <= o_weight_r [1][3];
				end
				'd43: begin
					dp4_1_a <= k_weight_r[2][0];
					dp4_1_b <= o_weight_r [2][0];

					dp4_1_c <= k_weight_r[2][1];
					dp4_1_d <= o_weight_r [2][1];

					dp4_1_e <= k_weight_r[2][2];
					dp4_1_f <= o_weight_r [2][2];

					dp4_1_g <= k_weight_r[2][3];
					dp4_1_h <= o_weight_r [2][3];
				end
				'd44: begin
					dp4_1_a <= k_weight_r[2][0];
					dp4_1_b <= o_weight_r [3][0];

					dp4_1_c <= k_weight_r[2][1];
					dp4_1_d <= o_weight_r [3][1];

					dp4_1_e <= k_weight_r[2][2];
					dp4_1_f <= o_weight_r [3][2];

					dp4_1_g <= k_weight_r[2][3];
					dp4_1_h <= o_weight_r [3][3];
				end
				'd45: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [0][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [0][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [0][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [0][3];
				end
				'd46: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [1][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [1][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [1][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [1][3];
				end
				'd47: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [2][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [2][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [2][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [2][3];
				end
				'd48: begin
					dp4_1_a <= k_weight_r[0][0];
					dp4_1_b <= o_weight_r [3][0];

					dp4_1_c <= k_weight_r[0][1];
					dp4_1_d <= o_weight_r [3][1];

					dp4_1_e <= k_weight_r[0][2];
					dp4_1_f <= o_weight_r [3][2];

					dp4_1_g <= k_weight_r[0][3];
					dp4_1_h <= o_weight_r [3][3];
				end
				'd49: begin
					dp4_1_a <= mac_1_z;
					dp4_1_b <= o_weight_r [0][0];

					dp4_1_c <= mac_2_z;
					dp4_1_d <= o_weight_r [0][1];

					dp4_1_e <= mac_3_z;
					dp4_1_f <= o_weight_r [0][2];

					dp4_1_g <= mac_4_z;
					dp4_1_h <= o_weight_r [0][3];
				end
				'd50: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [1][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [1][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [1][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [1][3];
				end
				'd51: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [2][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [2][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [2][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [2][3];
				end
				'd52: begin
					dp4_1_a <= k_weight_r[1][0];
					dp4_1_b <= o_weight_r [3][0];

					dp4_1_c <= k_weight_r[1][1];
					dp4_1_d <= o_weight_r [3][1];

					dp4_1_e <= k_weight_r[1][2];
					dp4_1_f <= o_weight_r [3][2];

					dp4_1_g <= k_weight_r[1][3];
					dp4_1_h <= o_weight_r [3][3];
				end
			endcase
		end
	end

	wire [5:0] sc_cnt = cnt - 'd17;

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			dp2_1_a <= 'd0;
			dp2_1_b <= 'd0;
			dp2_1_c <= 'd0;
			dp2_1_d <= 'd0;
		end
		else begin
			case (cnt)
				'd16: begin
					dp2_1_a <= Q[0][0];
					dp2_1_b <= K[0][0];
					dp2_1_c <= Q[0][1];
					dp2_1_d <= K[0][1];
				end
				'd17: begin
					dp2_1_a <= Q[0][0];
					dp2_1_b <= K[1][0];
					dp2_1_c <= Q[0][1];
					dp2_1_d <= K[1][1];
				end
				'd18: begin
					dp2_1_a <= Q[0][0];
					dp2_1_b <= K[2][0];
					dp2_1_c <= Q[0][1];
					dp2_1_d <= K[2][1];
				end
				'd19: begin
					dp2_1_a <= Q[0][0];
					dp2_1_b <= K[3][0];
					dp2_1_c <= Q[0][1];
					dp2_1_d <= K[3][1];
				end
				'd20: begin
					dp2_1_a <= Q[0][0];
					dp2_1_b <= mac_4_z;
					dp2_1_c <= Q[0][1];
					dp2_1_d <= mac_3_z;
				end
				'd21: begin
					dp2_1_a <= Q[1][0];
					dp2_1_b <= K[0][0];
					dp2_1_c <= Q[1][1];
					dp2_1_d <= K[0][1];
				end
				'd22: begin
					dp2_1_a <= Q[1][0];
					dp2_1_b <= K[1][0];
					dp2_1_c <= Q[1][1];
					dp2_1_d <= K[1][1];
				end
				'd23: begin
					dp2_1_a <= Q[1][0];
					dp2_1_b <= K[2][0];
					dp2_1_c <= Q[1][1];
					dp2_1_d <= K[2][1];
				end
				'd24: begin
					dp2_1_a <= Q[1][0];
					dp2_1_b <= K[3][0];
					dp2_1_c <= Q[1][1];
					dp2_1_d <= K[3][1];
				end
				'd25: begin
					dp2_1_a <= Q[1][0];
					dp2_1_b <= K[4][0];
					dp2_1_c <= Q[1][1];
					dp2_1_d <= K[4][1];
				end
				'd26: begin
					dp2_1_a <= Q[2][0];
					dp2_1_b <= K[0][0];
					dp2_1_c <= Q[2][1];
					dp2_1_d <= K[0][1];
				end
				'd27: begin
					dp2_1_a <= Q[2][0];
					dp2_1_b <= K[1][0];
					dp2_1_c <= Q[2][1];
					dp2_1_d <= K[1][1];
				end
				'd28: begin
					dp2_1_a <= Q[2][0];
					dp2_1_b <= K[2][0];
					dp2_1_c <= Q[2][1];
					dp2_1_d <= K[2][1];
				end
				'd29: begin
					dp2_1_a <= Q[2][0];
					dp2_1_b <= K[3][0];
					dp2_1_c <= Q[2][1];
					dp2_1_d <= K[3][1];
				end
				'd30: begin
					dp2_1_a <= Q[2][0];
					dp2_1_b <= K[4][0];
					dp2_1_c <= Q[2][1];
					dp2_1_d <= K[4][1];
				end
				'd31: begin
					dp2_1_a <= Q[3][0];
					dp2_1_b <= K[0][0];
					dp2_1_c <= Q[3][1];
					dp2_1_d <= K[0][1];
				end
				'd32: begin
					dp2_1_a <= Q[3][0];
					dp2_1_b <= K[1][0];
					dp2_1_c <= Q[3][1];
					dp2_1_d <= K[1][1];
				end
				'd33: begin
					dp2_1_a <= Q[3][0];
					dp2_1_b <= K[2][0];
					dp2_1_c <= Q[3][1];
					dp2_1_d <= K[2][1];
				end
				'd34: begin
					dp2_1_a <= Q[3][0];
					dp2_1_b <= K[3][0];
					dp2_1_c <= Q[3][1];
					dp2_1_d <= K[3][1];
				end
				'd35: begin
					dp2_1_a <= Q[3][0];
					dp2_1_b <= K[4][0];
					dp2_1_c <= Q[3][1];
					dp2_1_d <= K[4][1];
				end
				'd36: begin
					dp2_1_a <= Q[4][0];
					dp2_1_b <= K[0][0];
					dp2_1_c <= Q[4][1];
					dp2_1_d <= K[0][1];
				end
				'd37: begin
					dp2_1_a <= Q[4][0];
					dp2_1_b <= K[1][0];
					dp2_1_c <= Q[4][1];
					dp2_1_d <= K[1][1];
				end
				'd38: begin
					dp2_1_a <= Q[4][0];
					dp2_1_b <= K[2][0];
					dp2_1_c <= Q[4][1];
					dp2_1_d <= K[2][1];
				end
				'd39: begin
					dp2_1_a <= Q[4][0];
					dp2_1_b <= K[3][0];
					dp2_1_c <= Q[4][1];
					dp2_1_d <= K[3][1];
				end
				'd40: begin
					dp2_1_a <= Q[4][0];
					dp2_1_b <= K[4][0];
					dp2_1_c <= Q[4][1];
					dp2_1_d <= K[4][1];
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			dp2_2_a <= 'd0;
			dp2_2_b <= 'd0;
			dp2_2_c <= 'd0;
			dp2_2_d <= 'd0;
		end
		else begin
			case (cnt)
				'd16: begin
					dp2_2_a <= Q[0][2];
					dp2_2_b <= K[0][2];
					dp2_2_c <= mac_1_z;
					dp2_2_d <= mac_4_z;
				end
				'd17: begin
					dp2_2_a <= Q[0][2];
					dp2_2_b <= K[1][2];
					dp2_2_c <= Q[0][3];
					dp2_2_d <= K[1][3];
				end
				'd18: begin
					dp2_2_a <= Q[0][2];
					dp2_2_b <= K[2][2];
					dp2_2_c <= Q[0][3];
					dp2_2_d <= K[2][3];
				end
				'd19: begin
					dp2_2_a <= Q[0][2];
					dp2_2_b <= K[3][2];
					dp2_2_c <= Q[0][3];
					dp2_2_d <= K[3][3];
				end
				'd20: begin
					dp2_2_a <= Q[0][2];
					dp2_2_b <= mac_2_z;
					dp2_2_c <= Q[0][3];
					dp2_2_d <= mac_5_z;
				end
				'd21: begin
					dp2_2_a <= Q[1][2];
					dp2_2_b <= K[0][2];
					dp2_2_c <= Q[1][3];
					dp2_2_d <= K[0][3];
				end
				'd22: begin
					dp2_2_a <= Q[1][2];
					dp2_2_b <= K[1][2];
					dp2_2_c <= Q[1][3];
					dp2_2_d <= K[1][3];
				end
				'd23: begin
					dp2_2_a <= Q[1][2];
					dp2_2_b <= K[2][2];
					dp2_2_c <= Q[1][3];
					dp2_2_d <= K[2][3];
				end
				'd24: begin
					dp2_2_a <= Q[1][2];
					dp2_2_b <= K[3][2];
					dp2_2_c <= Q[1][3];
					dp2_2_d <= K[3][3];
				end
				'd25: begin
					dp2_2_a <= Q[1][2];
					dp2_2_b <= K[4][2];
					dp2_2_c <= Q[1][3];
					dp2_2_d <= K[4][3];
				end
				'd26: begin
					dp2_2_a <= Q[2][2];
					dp2_2_b <= K[0][2];
					dp2_2_c <= Q[2][3];
					dp2_2_d <= K[0][3];
				end
				'd27: begin
					dp2_2_a <= Q[2][2];
					dp2_2_b <= K[1][2];
					dp2_2_c <= Q[2][3];
					dp2_2_d <= K[1][3];
				end
				'd28: begin
					dp2_2_a <= Q[2][2];
					dp2_2_b <= K[2][2];
					dp2_2_c <= Q[2][3];
					dp2_2_d <= K[2][3];
				end
				'd29: begin
					dp2_2_a <= Q[2][2];
					dp2_2_b <= K[3][2];
					dp2_2_c <= Q[2][3];
					dp2_2_d <= K[3][3];
				end
				'd30: begin
					dp2_2_a <= Q[2][2];
					dp2_2_b <= K[4][2];
					dp2_2_c <= Q[2][3];
					dp2_2_d <= K[4][3];
				end
				'd31: begin
					dp2_2_a <= Q[3][2];
					dp2_2_b <= K[0][2];
					dp2_2_c <= Q[3][3];
					dp2_2_d <= K[0][3];
				end
				'd32: begin
					dp2_2_a <= Q[3][2];
					dp2_2_b <= K[1][2];
					dp2_2_c <= Q[3][3];
					dp2_2_d <= K[1][3];
				end
				'd33: begin
					dp2_2_a <= Q[3][2];
					dp2_2_b <= K[2][2];
					dp2_2_c <= Q[3][3];
					dp2_2_d <= K[2][3];
				end
				'd34: begin
					dp2_2_a <= Q[3][2];
					dp2_2_b <= K[3][2];
					dp2_2_c <= Q[3][3];
					dp2_2_d <= K[3][3];
				end
				'd35: begin
					dp2_2_a <= Q[3][2];
					dp2_2_b <= K[4][2];
					dp2_2_c <= Q[3][3];
					dp2_2_d <= K[4][3];
				end
				'd36: begin
					dp2_2_a <= Q[4][2];
					dp2_2_b <= K[0][2];
					dp2_2_c <= Q[4][3];
					dp2_2_d <= K[0][3];
				end
				'd37: begin
					dp2_2_a <= Q[4][2];
					dp2_2_b <= K[1][2];
					dp2_2_c <= Q[4][3];
					dp2_2_d <= K[1][3];
				end
				'd38: begin
					dp2_2_a <= Q[4][2];
					dp2_2_b <= K[2][2];
					dp2_2_c <= Q[4][3];
					dp2_2_d <= K[2][3];
				end
				'd39: begin
					dp2_2_a <= Q[4][2];
					dp2_2_b <= K[3][2];
					dp2_2_c <= Q[4][3];
					dp2_2_d <= K[3][3];
				end
				'd40: begin
					dp2_2_a <= Q[4][2];
					dp2_2_b <= K[4][2];
					dp2_2_c <= Q[4][3];
					dp2_2_d <= K[4][3];
				end
			endcase
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			div_1_a <= 'd0;
			div_2_a <= 'd0;
		end
		else begin
			div_1_a <= dp2_1_z;
			div_2_a <= dp2_2_z;
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			exp_1_a <= 'd0;
			exp_2_a <= 'd0;
		end
		else begin
			exp_1_a <= div_1_z;
			exp_2_a <= div_2_z;
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			exp_1_pipeline <= 'd0;
			exp_2_pipeline <= 'd0;
		end
		else begin
			exp_1_pipeline <= exp_1_z;
			exp_2_pipeline <= exp_2_z;
		end
	end

	reg [2:0] ring_cnt;

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			ring_cnt <= 'd0;
		end
		else begin
			if (cnt == 'd17 || ring_cnt == 'd4) begin
				ring_cnt <= 'd0;
			end
			else begin
				ring_cnt <= ring_cnt + 1'b1;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				exp_val_1[i] <= 'd0;
				exp_val_2[i] <= 'd0;
			end
		end
		else begin
			exp_val_1[ring_cnt] <= exp_1_z;
			exp_val_2[ring_cnt] <= exp_2_z;
		end			
	end


	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			add_1_a <= 'd0;
			add_2_a <= 'd0;
			add_1_b <= 'd0;
			add_2_b <= 'd0;
			ad_1_a_fw_1 <= 'd0; ad_1_a_fw_2 <= 'd0; ad_1_a_fw_3 <= 'd0; ad_1_a_fw_4 <= 'd0;
			ad_2_a_fw_1 <= 'd0; ad_2_a_fw_2 <= 'd0; ad_2_a_fw_3 <= 'd0; ad_2_a_fw_4 <= 'd0;
		end
		else begin
			add_1_a <= exp_1_z;
			add_2_a <= exp_2_z;
			{ad_1_a_fw_1, ad_1_a_fw_2, ad_1_a_fw_3, ad_1_a_fw_4} <= {ad_1_a_fw_2, ad_1_a_fw_3, ad_1_a_fw_4, add_1_a};
			{ad_2_a_fw_1, ad_2_a_fw_2, ad_2_a_fw_3, ad_2_a_fw_4} <= {ad_2_a_fw_2, ad_2_a_fw_3, ad_2_a_fw_4, add_2_a};
			if (cnt == 'd18 || cnt == 'd23 || cnt == 'd28 || cnt == 'd33 || cnt == 'd38 || cnt == 'd43) begin
				add_1_b <= 'd0;
				add_2_b <= 'd0;
			end
			else begin
				add_1_b <= add_1_z;
				add_2_b <= add_2_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			div_s1_b <= 'd0;
			div_s2_b <= 'd0;
		end
		else begin
			if (cnt == 'd23 || cnt == 'd28 || cnt == 'd33 || cnt == 'd38 || cnt == 'd43) begin
				div_s1_b <= add_1_z;
				div_s2_b <= add_2_z;
			end
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			div_s1_a <= 'd0;
			div_s2_a <= 'd0;
		end
		else begin
			div_s1_a <= ad_1_a_fw_1;
			div_s2_a <= ad_2_a_fw_1;
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 5; i = i + 1) begin
				for (j = 0; j < 4; j = j + 1) begin
					k_weight_r[i][j] <= 'd0;
				end
			end
		end
		else begin
			if (cnt < 'd16 && in_valid) begin
				k_weight_r[cnt[3:2]][cnt[1:0]] <= k_weight;
			end
			else if (cnt > 'd24 && cnt < 'd30) begin
				k_weight_r[0][0] <= mac_1_z;
				k_weight_r[0][1] <= mac_2_z;
				k_weight_r[0][2] <= mac_3_z;
				k_weight_r[0][3] <= mac_4_z;
			end
			else if (cnt > 'd29 && cnt < 'd35) begin
				k_weight_r[1][0] <= mac_1_z;
				k_weight_r[1][1] <= mac_2_z;
				k_weight_r[1][2] <= mac_3_z;
				k_weight_r[1][3] <= mac_4_z;
			end
			else if (cnt > 'd34 && cnt < 'd40) begin
				k_weight_r[2][0] <= mac_1_z;
				k_weight_r[2][1] <= mac_2_z;
				k_weight_r[2][2] <= mac_3_z;
				k_weight_r[2][3] <= mac_4_z;
			end
			else if (cnt > 'd39 && cnt < 'd45) begin
				k_weight_r[0][0] <= mac_1_z;
				k_weight_r[0][1] <= mac_2_z;
				k_weight_r[0][2] <= mac_3_z;
				k_weight_r[0][3] <= mac_4_z;
			end
			else if (cnt > 'd44 && cnt < 'd50) begin
				k_weight_r[1][0] <= mac_1_z;
				k_weight_r[1][1] <= mac_2_z;
				k_weight_r[1][2] <= mac_3_z;
				k_weight_r[1][3] <= mac_4_z;
			end
		end
	end
	


endmodule


module dp4_no_pipe (
	input [31:0] a, b, c, d, e, f, g, h,
	output [31:0] z
);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch_type = 0;
	parameter inst_arch = 0;
	parameter inst_faithful_round = 0;

	wire [31:0] pipe_wire [3:0];

	wire [31:0] pipe_wire_add [1:0];
	wire [7:0] NULL [6:0];

	integer i;

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL1 ( .a(a), .b(b), .rnd(3'b000), .z(pipe_wire[0]), .status(NULL[0]));

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL2 ( .a(c), .b(d), .rnd(3'b000), .z(pipe_wire[1]), .status(NULL[1]));

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL3 ( .a(e), .b(f), .rnd(3'b000), .z(pipe_wire[2]), .status(NULL[2]));

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL4 ( .a(g), .b(h), .rnd(3'b000), .z(pipe_wire[3]), .status(NULL[3]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD1 ( .a(pipe_wire[0]), .b(pipe_wire[1]), .rnd(3'b000), .z(pipe_wire_add[0]), .status(NULL[4]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD2 ( .a(pipe_wire[2]), .b(pipe_wire[3]), .rnd(3'b000), .z(pipe_wire_add[1]), .status(NULL[5]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD3 ( .a(pipe_wire_add[0]), .b(pipe_wire_add[1]), .rnd(3'b000), .z(z), .status(NULL[6]));

endmodule

module dot2_no_pipe (
	input [31:0] a, b, c, d,
	output [31:0] z
);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;
	parameter inst_arch_type = 0;
	parameter inst_arch = 0;
	parameter inst_faithful_round = 0;

	wire [31:0] temp_out_1 [3:0];
	wire [31:0] temp_out_2 [1:0];
	wire [31:0] out_wire;
	wire [7:0] NULL [3:0];

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL1 ( .a(a), .b(b), .rnd(3'b000), .z(temp_out_1[0]), .status(NULL[0]));

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL2 ( .a(c), .b(d), .rnd(3'b000), .z(temp_out_1[1]), .status(NULL[1]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD1 ( .a(temp_out_1[0]), .b(temp_out_1[1]), .rnd(3'b000), .z(z), .status(NULL[2]));

endmodule

module mac_no_pipe (
	input clk,
	input rst_n,
	input clear,
	input [31:0] a, b,
	output [31:0] z
);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;

	wire [31:0] pipe_wire;
	wire [31:0] zz;
	wire [7:0] NULL [1:0];

	reg [inst_sig_width+inst_exp_width:0] c_r;

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			c_r <= 'd0;
		end
		else if (clear) begin
			c_r <= 'd0;
		end
		else begin
			c_r <= zz;
		end
	end

	assign z = c_r;

	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL1 ( .a(a), .b(b), .rnd(3'b000), .z(pipe_wire), .status(NULL[0]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD1 ( .a(pipe_wire), .b(c_r), .rnd(3'b000), .z(zz), .status(NULL[1]));



endmodule

module mac_no_pipe_1 (
	input [31:0] a, b, c,
	output [31:0] z
);

	parameter inst_sig_width = 23;
	parameter inst_exp_width = 8;
	parameter inst_ieee_compliance = 0;

	wire [31:0] pipe_wire;
	wire [31:0] zz;
	wire [7:0] NULL [1:0];




	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	MUL1 ( .a(a), .b(b), .rnd(3'b000), .z(pipe_wire), .status(NULL[0]));

	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	ADD1 ( .a(pipe_wire), .b(c), .rnd(3'b000), .z(z), .status(NULL[1]));



endmodule