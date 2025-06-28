/**************************************************************************/
// Copyright (c) 2025, OASIS Lab
// MODULE: STA
// FILE NAME: STA.v
// VERSRION: 1.0
// DATE: 2025/02/26
// AUTHOR: Yu-Hao Cheng, NYCU IEE
// DESCRIPTION: ICLAB 2025 Spring / LAB3 / STA
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/
module STA(
	//INPUT
	rst_n,
	clk,
	in_valid,
	delay,
	source,
	destination,
	//OUTPUT
	out_valid,
	worst_delay,
	path
);

	//---------------------------------------------------------------------
	//   PORT DECLARATION          
	//---------------------------------------------------------------------
	input				rst_n, clk, in_valid;
	input		[3:0]	delay;
	input		[3:0]	source;
	input		[3:0]	destination;

	output reg			out_valid;
	output reg	[7:0]	worst_delay;
	output reg	[3:0]	path;

	//---------------------------------------------------------------------
	//   PARAMETER & INTEGER DECLARATION
	//---------------------------------------------------------------------
	parameter IDLE = 2'b00;
	parameter INPU = 2'b01;
	parameter CALC = 2'b10;
	parameter OUTP = 2'b11;

	integer i, j, k, l;

	//---------------------------------------------------------------------
	//   REG & WIRE DECLARATION
	//---------------------------------------------------------------------
	reg [1:0] state;
	reg [1:0] next_state;
	reg  [0:0]     adj_mat     [0:15][0:15];
	reg [3:0] value       [0:15];
	reg [4:0] ctr;
	reg [7:0] cost [0:15];
	reg [3:0] backtrace [0:15];
	reg [0:0] node_all_edge_clear [0:15];
	wire is_new_source [0:15];
	reg [3:0] cur_node;
	wire check_out_sel [0:15];
	reg [3:0] sel_node;
	reg [3:0] cur_node_pipline;
	reg [7:0] cur_node_pipline_cost;
	reg [3:0] cur_node_pipline_1;
	reg check_out_sel_pipeline [0:15];
	reg check_out_sel_pipeline_1 [0:15];
	wire [7:0] cost_add_val [0:15];
	wire [0:0] update [0:15];
	reg aux_16;

	//---------------------------------------------------------------------
	//   DESIGN
	//---------------------------------------------------------------------

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 16; i = i + 1) begin
				node_all_edge_clear[i] <= 1'b0;
			end
			node_all_edge_clear[0] <= 1'b1;
		end
		else begin
			if (state == INPU) begin
				for (i = 0; i < 16; i = i + 1) begin
					node_all_edge_clear[i] <= 1'b0;
				end
			end
			else begin
				node_all_edge_clear[cur_node] <= 1'b1;
			end
			node_all_edge_clear[0] <= 1'b1;
		end
	end


	assign is_new_source[0 ] = (adj_mat[0][0 ] == 1'b0) && (adj_mat[1][0 ] == 1'b0) && (adj_mat[2][0 ] == 1'b0) && (adj_mat[3][0 ] == 1'b0) && (adj_mat[4][0 ] == 1'b0) && (adj_mat[5][0 ] == 1'b0) && (adj_mat[6][0 ] == 1'b0) && (adj_mat[7][0 ] == 1'b0) && (adj_mat[8][0 ] == 1'b0) && (adj_mat[9][0 ] == 1'b0) && (adj_mat[10][0 ] == 1'b0) && (adj_mat[11][0 ] == 1'b0) && (adj_mat[12][0 ] == 1'b0) && (adj_mat[13][0 ] == 1'b0) && (adj_mat[14][0 ] == 1'b0) && (adj_mat[15][0 ] == 1'b0);
	assign is_new_source[1 ] = (adj_mat[0][1 ] == 1'b0) && (adj_mat[1][1 ] == 1'b0) && (adj_mat[2][1 ] == 1'b0) && (adj_mat[3][1 ] == 1'b0) && (adj_mat[4][1 ] == 1'b0) && (adj_mat[5][1 ] == 1'b0) && (adj_mat[6][1 ] == 1'b0) && (adj_mat[7][1 ] == 1'b0) && (adj_mat[8][1 ] == 1'b0) && (adj_mat[9][1 ] == 1'b0) && (adj_mat[10][1 ] == 1'b0) && (adj_mat[11][1 ] == 1'b0) && (adj_mat[12][1 ] == 1'b0) && (adj_mat[13][1 ] == 1'b0) && (adj_mat[14][1 ] == 1'b0) && (adj_mat[15][1 ] == 1'b0);
	assign is_new_source[2 ] = (adj_mat[0][2 ] == 1'b0) && (adj_mat[1][2 ] == 1'b0) && (adj_mat[2][2 ] == 1'b0) && (adj_mat[3][2 ] == 1'b0) && (adj_mat[4][2 ] == 1'b0) && (adj_mat[5][2 ] == 1'b0) && (adj_mat[6][2 ] == 1'b0) && (adj_mat[7][2 ] == 1'b0) && (adj_mat[8][2 ] == 1'b0) && (adj_mat[9][2 ] == 1'b0) && (adj_mat[10][2 ] == 1'b0) && (adj_mat[11][2 ] == 1'b0) && (adj_mat[12][2 ] == 1'b0) && (adj_mat[13][2 ] == 1'b0) && (adj_mat[14][2 ] == 1'b0) && (adj_mat[15][2 ] == 1'b0);
	assign is_new_source[3 ] = (adj_mat[0][3 ] == 1'b0) && (adj_mat[1][3 ] == 1'b0) && (adj_mat[2][3 ] == 1'b0) && (adj_mat[3][3 ] == 1'b0) && (adj_mat[4][3 ] == 1'b0) && (adj_mat[5][3 ] == 1'b0) && (adj_mat[6][3 ] == 1'b0) && (adj_mat[7][3 ] == 1'b0) && (adj_mat[8][3 ] == 1'b0) && (adj_mat[9][3 ] == 1'b0) && (adj_mat[10][3 ] == 1'b0) && (adj_mat[11][3 ] == 1'b0) && (adj_mat[12][3 ] == 1'b0) && (adj_mat[13][3 ] == 1'b0) && (adj_mat[14][3 ] == 1'b0) && (adj_mat[15][3 ] == 1'b0);
	assign is_new_source[4 ] = (adj_mat[0][4 ] == 1'b0) && (adj_mat[1][4 ] == 1'b0) && (adj_mat[2][4 ] == 1'b0) && (adj_mat[3][4 ] == 1'b0) && (adj_mat[4][4 ] == 1'b0) && (adj_mat[5][4 ] == 1'b0) && (adj_mat[6][4 ] == 1'b0) && (adj_mat[7][4 ] == 1'b0) && (adj_mat[8][4 ] == 1'b0) && (adj_mat[9][4 ] == 1'b0) && (adj_mat[10][4 ] == 1'b0) && (adj_mat[11][4 ] == 1'b0) && (adj_mat[12][4 ] == 1'b0) && (adj_mat[13][4 ] == 1'b0) && (adj_mat[14][4 ] == 1'b0) && (adj_mat[15][4 ] == 1'b0);
	assign is_new_source[5 ] = (adj_mat[0][5 ] == 1'b0) && (adj_mat[1][5 ] == 1'b0) && (adj_mat[2][5 ] == 1'b0) && (adj_mat[3][5 ] == 1'b0) && (adj_mat[4][5 ] == 1'b0) && (adj_mat[5][5 ] == 1'b0) && (adj_mat[6][5 ] == 1'b0) && (adj_mat[7][5 ] == 1'b0) && (adj_mat[8][5 ] == 1'b0) && (adj_mat[9][5 ] == 1'b0) && (adj_mat[10][5 ] == 1'b0) && (adj_mat[11][5 ] == 1'b0) && (adj_mat[12][5 ] == 1'b0) && (adj_mat[13][5 ] == 1'b0) && (adj_mat[14][5 ] == 1'b0) && (adj_mat[15][5 ] == 1'b0);
	assign is_new_source[6 ] = (adj_mat[0][6 ] == 1'b0) && (adj_mat[1][6 ] == 1'b0) && (adj_mat[2][6 ] == 1'b0) && (adj_mat[3][6 ] == 1'b0) && (adj_mat[4][6 ] == 1'b0) && (adj_mat[5][6 ] == 1'b0) && (adj_mat[6][6 ] == 1'b0) && (adj_mat[7][6 ] == 1'b0) && (adj_mat[8][6 ] == 1'b0) && (adj_mat[9][6 ] == 1'b0) && (adj_mat[10][6 ] == 1'b0) && (adj_mat[11][6 ] == 1'b0) && (adj_mat[12][6 ] == 1'b0) && (adj_mat[13][6 ] == 1'b0) && (adj_mat[14][6 ] == 1'b0) && (adj_mat[15][6 ] == 1'b0);
	assign is_new_source[7 ] = (adj_mat[0][7 ] == 1'b0) && (adj_mat[1][7 ] == 1'b0) && (adj_mat[2][7 ] == 1'b0) && (adj_mat[3][7 ] == 1'b0) && (adj_mat[4][7 ] == 1'b0) && (adj_mat[5][7 ] == 1'b0) && (adj_mat[6][7 ] == 1'b0) && (adj_mat[7][7 ] == 1'b0) && (adj_mat[8][7 ] == 1'b0) && (adj_mat[9][7 ] == 1'b0) && (adj_mat[10][7 ] == 1'b0) && (adj_mat[11][7 ] == 1'b0) && (adj_mat[12][7 ] == 1'b0) && (adj_mat[13][7 ] == 1'b0) && (adj_mat[14][7 ] == 1'b0) && (adj_mat[15][7 ] == 1'b0);
	assign is_new_source[8 ] = (adj_mat[0][8 ] == 1'b0) && (adj_mat[1][8 ] == 1'b0) && (adj_mat[2][8 ] == 1'b0) && (adj_mat[3][8 ] == 1'b0) && (adj_mat[4][8 ] == 1'b0) && (adj_mat[5][8 ] == 1'b0) && (adj_mat[6][8 ] == 1'b0) && (adj_mat[7][8 ] == 1'b0) && (adj_mat[8][8 ] == 1'b0) && (adj_mat[9][8 ] == 1'b0) && (adj_mat[10][8 ] == 1'b0) && (adj_mat[11][8 ] == 1'b0) && (adj_mat[12][8 ] == 1'b0) && (adj_mat[13][8 ] == 1'b0) && (adj_mat[14][8 ] == 1'b0) && (adj_mat[15][8 ] == 1'b0);
	assign is_new_source[9 ] = (adj_mat[0][9 ] == 1'b0) && (adj_mat[1][9 ] == 1'b0) && (adj_mat[2][9 ] == 1'b0) && (adj_mat[3][9 ] == 1'b0) && (adj_mat[4][9 ] == 1'b0) && (adj_mat[5][9 ] == 1'b0) && (adj_mat[6][9 ] == 1'b0) && (adj_mat[7][9 ] == 1'b0) && (adj_mat[8][9 ] == 1'b0) && (adj_mat[9][9 ] == 1'b0) && (adj_mat[10][9 ] == 1'b0) && (adj_mat[11][9 ] == 1'b0) && (adj_mat[12][9 ] == 1'b0) && (adj_mat[13][9 ] == 1'b0) && (adj_mat[14][9 ] == 1'b0) && (adj_mat[15][9 ] == 1'b0);
	assign is_new_source[10] = (adj_mat[0][10] == 1'b0) && (adj_mat[1][10] == 1'b0) && (adj_mat[2][10] == 1'b0) && (adj_mat[3][10] == 1'b0) && (adj_mat[4][10] == 1'b0) && (adj_mat[5][10] == 1'b0) && (adj_mat[6][10] == 1'b0) && (adj_mat[7][10] == 1'b0) && (adj_mat[8][10] == 1'b0) && (adj_mat[9][10] == 1'b0) && (adj_mat[10][10] == 1'b0) && (adj_mat[11][10] == 1'b0) && (adj_mat[12][10] == 1'b0) && (adj_mat[13][10] == 1'b0) && (adj_mat[14][10] == 1'b0) && (adj_mat[15][10] == 1'b0);
	assign is_new_source[11] = (adj_mat[0][11] == 1'b0) && (adj_mat[1][11] == 1'b0) && (adj_mat[2][11] == 1'b0) && (adj_mat[3][11] == 1'b0) && (adj_mat[4][11] == 1'b0) && (adj_mat[5][11] == 1'b0) && (adj_mat[6][11] == 1'b0) && (adj_mat[7][11] == 1'b0) && (adj_mat[8][11] == 1'b0) && (adj_mat[9][11] == 1'b0) && (adj_mat[10][11] == 1'b0) && (adj_mat[11][11] == 1'b0) && (adj_mat[12][11] == 1'b0) && (adj_mat[13][11] == 1'b0) && (adj_mat[14][11] == 1'b0) && (adj_mat[15][11] == 1'b0);
	assign is_new_source[12] = (adj_mat[0][12] == 1'b0) && (adj_mat[1][12] == 1'b0) && (adj_mat[2][12] == 1'b0) && (adj_mat[3][12] == 1'b0) && (adj_mat[4][12] == 1'b0) && (adj_mat[5][12] == 1'b0) && (adj_mat[6][12] == 1'b0) && (adj_mat[7][12] == 1'b0) && (adj_mat[8][12] == 1'b0) && (adj_mat[9][12] == 1'b0) && (adj_mat[10][12] == 1'b0) && (adj_mat[11][12] == 1'b0) && (adj_mat[12][12] == 1'b0) && (adj_mat[13][12] == 1'b0) && (adj_mat[14][12] == 1'b0) && (adj_mat[15][12] == 1'b0);
	assign is_new_source[13] = (adj_mat[0][13] == 1'b0) && (adj_mat[1][13] == 1'b0) && (adj_mat[2][13] == 1'b0) && (adj_mat[3][13] == 1'b0) && (adj_mat[4][13] == 1'b0) && (adj_mat[5][13] == 1'b0) && (adj_mat[6][13] == 1'b0) && (adj_mat[7][13] == 1'b0) && (adj_mat[8][13] == 1'b0) && (adj_mat[9][13] == 1'b0) && (adj_mat[10][13] == 1'b0) && (adj_mat[11][13] == 1'b0) && (adj_mat[12][13] == 1'b0) && (adj_mat[13][13] == 1'b0) && (adj_mat[14][13] == 1'b0) && (adj_mat[15][13] == 1'b0);
	assign is_new_source[14] = (adj_mat[0][14] == 1'b0) && (adj_mat[1][14] == 1'b0) && (adj_mat[2][14] == 1'b0) && (adj_mat[3][14] == 1'b0) && (adj_mat[4][14] == 1'b0) && (adj_mat[5][14] == 1'b0) && (adj_mat[6][14] == 1'b0) && (adj_mat[7][14] == 1'b0) && (adj_mat[8][14] == 1'b0) && (adj_mat[9][14] == 1'b0) && (adj_mat[10][14] == 1'b0) && (adj_mat[11][14] == 1'b0) && (adj_mat[12][14] == 1'b0) && (adj_mat[13][14] == 1'b0) && (adj_mat[14][14] == 1'b0) && (adj_mat[15][14] == 1'b0);
	assign is_new_source[15] = (adj_mat[0][15] == 1'b0) && (adj_mat[1][15] == 1'b0) && (adj_mat[2][15] == 1'b0) && (adj_mat[3][15] == 1'b0) && (adj_mat[4][15] == 1'b0) && (adj_mat[5][15] == 1'b0) && (adj_mat[6][15] == 1'b0) && (adj_mat[7][15] == 1'b0) && (adj_mat[8][15] == 1'b0) && (adj_mat[9][15] == 1'b0) && (adj_mat[10][15] == 1'b0) && (adj_mat[11][15] == 1'b0) && (adj_mat[12][15] == 1'b0) && (adj_mat[13][15] == 1'b0) && (adj_mat[14][15] == 1'b0) && (adj_mat[15][15] == 1'b0);

	always @(*) begin
		case(1'b1) // 
			((!node_all_edge_clear[0 ]) && is_new_source[0 ]): cur_node = 4'd0;
			((!node_all_edge_clear[1 ]) && is_new_source[1 ]): cur_node = 4'd1;
			((!node_all_edge_clear[2 ]) && is_new_source[2 ]): cur_node = 4'd2;
			((!node_all_edge_clear[3 ]) && is_new_source[3 ]): cur_node = 4'd3;
			((!node_all_edge_clear[4 ]) && is_new_source[4 ]): cur_node = 4'd4;
			((!node_all_edge_clear[5 ]) && is_new_source[5 ]): cur_node = 4'd5;
			((!node_all_edge_clear[6 ]) && is_new_source[6 ]): cur_node = 4'd6;
			((!node_all_edge_clear[7 ]) && is_new_source[7 ]): cur_node = 4'd7;
			((!node_all_edge_clear[8 ]) && is_new_source[8 ]): cur_node = 4'd8;
			((!node_all_edge_clear[9 ]) && is_new_source[9 ]): cur_node = 4'd9;
			((!node_all_edge_clear[10]) && is_new_source[10]): cur_node = 4'd10;
			((!node_all_edge_clear[11]) && is_new_source[11]): cur_node = 4'd11;
			((!node_all_edge_clear[12]) && is_new_source[12]): cur_node = 4'd12;
			((!node_all_edge_clear[13]) && is_new_source[13]): cur_node = 4'd13;
			((!node_all_edge_clear[14]) && is_new_source[14]): cur_node = 4'd14;
			default:                                           cur_node = 4'd15;
		endcase
	end

	genvar gv_i;
	generate
		for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin
			assign check_out_sel[gv_i] = (adj_mat[cur_node][gv_i] == 1'b1);
		end
	endgenerate

	generate
		for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin
			assign update[gv_i] = ((cost_add_val[gv_i] >= cost[gv_i]) && check_out_sel_pipeline_1[gv_i]);
		end
	endgenerate

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			cur_node_pipline <= 4'b0;
			cur_node_pipline_1 <= 4'b0;
			cur_node_pipline_cost <= 8'b0;
		end
		else begin
			cur_node_pipline <= cur_node;
			cur_node_pipline_1 <= cur_node_pipline;
			cur_node_pipline_cost <= (update[cur_node_pipline] == 1'b0) ? cost[cur_node_pipline] : cost_add_val[cur_node_pipline];
		end

	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			for (i = 0; i < 16; i = i + 1) begin
				check_out_sel_pipeline[i] <= 1'b0;
				check_out_sel_pipeline_1[i] <= 1'b0;
			end
		end
		else begin
			for (i = 0; i < 16; i = i + 1) begin
				check_out_sel_pipeline[i] <= check_out_sel[i];
				check_out_sel_pipeline_1[i] <= check_out_sel_pipeline[i];
			end
		end
	end

	generate
		for (gv_i = 0; gv_i < 16; gv_i = gv_i + 1) begin
			if (gv_i != 1) begin
				kogge_stone_adder_8b4b addr (
					.a_8(cur_node_pipline_cost),
					.b_4(value[gv_i]),
					.sum_8(cost_add_val[gv_i])
				);
			end
		end
	endgenerate

	always @(posedge clk) begin
			if (next_state == INPU) begin
				for (i = 0; i < 16; i = i + 1) begin
					if (i != 1) begin
						cost[i] <= 8'b0;
					end
					backtrace[i] <= 4'b0;
				end
			end
			else if (state == CALC && ctr >= 5'd1) begin
				for (i = 0; i < 16; i = i + 1) begin
					if (i != 1) begin
						if (update[i]) begin
							cost[i] <= cost_add_val[i];
							backtrace[i] <= cur_node_pipline_1;
						end
					end
				end
			end
			cost[1] <= {4'b0000, value[1]};
			backtrace[1] <= 4'b0;
	end
	
	
	always @(posedge clk) begin
		if (next_state == IDLE) begin
			for (i = 0; i < 16; i = i + 1) begin
				for (j = 0; j < 16; j = j + 1) begin
					adj_mat[i][j] <= 1'b0;
				end
			end	
		end
		else if (next_state == INPU || state == INPU) begin
			adj_mat[destination][source] <= 1'b1;
		end
		else if (state == CALC) begin
			for (i = 0; i < 16; i = i + 1) begin
				adj_mat[cur_node][i] <= 1'b0;
			end
		end
		for (i = 0; i < 16; i = i + 1) begin
			for (j = 0; j < 16; j = j + 1) begin
				if (i == j) begin
					adj_mat[i][j] <= 1'b0;
				end
			end
		end
		for (i = 0; i < 16; i = i + 1) begin
			adj_mat[0][i] <= 1'b0;
			adj_mat[i][1] <= 1'b0;
		end
	end

	always @(*) begin
		case(state)
			IDLE: begin
				if (in_valid) begin
					next_state = INPU;
				end
				else begin
					next_state = IDLE;
				end
			end
			INPU: begin
				if (ctr != 5'd31) begin
					next_state = INPU;
				end
				else begin
					next_state = CALC;
				end
			end
			CALC: begin
				if (ctr == 5'd16) begin
					next_state = OUTP;
				end
				else begin
					next_state = CALC;
				end
			end
			OUTP: begin
				if (path == 4'd1) begin
					next_state = IDLE;
				end
				else begin
					next_state = OUTP;
				end
			end
			default: begin
				next_state = IDLE;
			end
		endcase
	end

	always @(*) begin
		if (out_valid && path == 4'b0) begin
			worst_delay = cost[0];
		end
		else begin
			worst_delay = 8'd0;
		end
	end

	always @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			out_valid <= 1'b0;
			path <= 4'b0;
		end
		else if (next_state == OUTP && state != OUTP) begin
			out_valid <= 1'b1;
			path <= 4'b0;
		end
		else if (state == OUTP && path != 4'd1) begin
			out_valid <= 1'b1;
			path <= backtrace[path];
		end
		else begin
			out_valid <= 1'b0;
			path <= 4'b0;
		end
	end

	always @(posedge clk) begin
			if (next_state == IDLE) begin
				ctr <= 5'b0;
			end
			else begin
				ctr <= ctr + 1'b1;
			end
	end

	always @(posedge clk) begin
			if (next_state == IDLE) begin
				for (i = 0; i < 16; i = i + 1) begin
					value[i] <= 4'b0;
				end
			end
			else if (next_state == INPU &&  ctr <= 5'd15) begin
				value[ctr] <= delay;
			end
	end



	

endmodule




module kogge_stone_adder_8b4b (
    input  [7:0] a_8,
    input  [3:0] b_4,
    output [7:0] sum_8
);
    // Step 0
    wire [7:0] P0, G0;
	assign P0[0] = a_8[0] ^ b_4[0];
	assign G0[0] = a_8[0] & b_4[0];
	assign P0[1] = a_8[1] ^ b_4[1];
	assign G0[1] = a_8[1] & b_4[1];
	assign P0[2] = a_8[2] ^ b_4[2];
	assign G0[2] = a_8[2] & b_4[2];
	assign P0[3] = a_8[3] ^ b_4[3];
	assign G0[3] = a_8[3] & b_4[3];
	assign P0[4] = a_8[4];
	assign G0[4] = 1'b0;
	assign P0[5] = a_8[5];
	assign G0[5] = 1'b0;
	assign P0[6] = a_8[6];
	assign G0[6] = 1'b0;
	assign P0[7] = a_8[7];
	assign G0[7] = 1'b0;

    // Step 1: Distance = 1
    wire [7:0] G1, P1;
    assign G1[0] = G0[0];
    assign G1[1] = G0[1] | (P0[1] & G0[0]);
    assign P1[2] = P0[2] & P0[1];
    assign G1[2] = G0[2] | (P0[2] & G0[1]);
    assign P1[3] = P0[3] & P0[2];
    assign G1[3] = G0[3] | (P0[3] & G0[2]);
    assign P1[4] = P0[4] & P0[3];
    assign G1[4] = G0[4] | (P0[4] & G0[3]);
    assign P1[5] = P0[5] & P0[4];
    assign G1[5] = G0[5] | (P0[5] & G0[4]);
    assign P1[6] = P0[6] & P0[5];
    assign G1[6] = G0[6] | (P0[6] & G0[5]);
    assign P1[7] = P0[7] & P0[6];
    assign G1[7] = G0[7] | (P0[7] & G0[6]);

    // Step 2: Distance = 2
    wire [7:0] G2, P2;
    assign G2[0] = G1[0];
    assign G2[1] = G1[1];
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    assign G2[3] = G1[3] | (P1[3] & G1[1]);
    assign P2[4] = P1[4] & P1[2];
    assign G2[4] = G1[4] | (P1[4] & G1[2]);
    assign P2[5] = P1[5] & P1[3];
    assign G2[5] = G1[5] | (P1[5] & G1[3]);
    assign P2[6] = P1[6] & P1[4];
    assign G2[6] = G1[6] | (P1[6] & G1[4]);
    assign P2[7] = P1[7] & P1[5];
    assign G2[7] = G1[7] | (P1[7] & G1[5]);

    // Step 3: Distance = 4
    wire [7:0] G3;
    assign G3[0] = G2[0];                 // C1
    assign G3[1] = G2[1];                 // C2
    assign G3[2] = G2[2];                 // C3
    assign G3[3] = G2[3];                 // C4
    assign G3[4] = G2[4] | (P2[4] & G2[0]); // C5
    assign G3[5] = G2[5] | (P2[5] & G2[1]); // C6
    assign G3[6] = G2[6] | (P2[6] & G2[2]); // C7

    assign sum_8[0] = P0[0];
    assign sum_8[1] = P0[1] ^ G3[0];         // S1 = P1 ^ C1
    assign sum_8[2] = P0[2] ^ G3[1];          // S2 = P2 ^ C2
    assign sum_8[3] = P0[3] ^ G3[2];          // S3 = P3 ^ C3
    assign sum_8[4] = P0[4] ^ G3[3];           // S4 = P4 ^ C4
    assign sum_8[5] = P0[5] ^ G3[4];          // S5 = P5 ^ C5
    assign sum_8[6] = P0[6] ^ G3[5];         // S6 = P6 ^ C6
    assign sum_8[7] = P0[7] ^ G3[6];          // S7 = P7 ^ C7

endmodule