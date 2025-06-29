//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Midterm Proejct            : MRA  
//   Author                     : Lin-Hung, Lai
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MRA.v
//   Module Name : MRA
//   Release version : V2.0 (Release Date: 2023-10)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module MRA(
	// CHIP IO
	clk            	,	
	rst_n          	,	
	in_valid       	,	
	frame_id        ,	
	net_id         	,	  
	loc_x          	,	  
    loc_y         	,
	cost	 		,		
	busy         	,

    // AXI4 IO
	     arid_m_inf,
	   araddr_m_inf,
	    arlen_m_inf,
	   arsize_m_inf,
	  arburst_m_inf,
	  arvalid_m_inf,
	  arready_m_inf,
	
	      rid_m_inf,
	    rdata_m_inf,
	    rresp_m_inf,
	    rlast_m_inf,
	   rvalid_m_inf,
	   rready_m_inf,
	
	     awid_m_inf,
	   awaddr_m_inf,
	   awsize_m_inf,
	  awburst_m_inf,
	    awlen_m_inf,
	  awvalid_m_inf,
	  awready_m_inf,
	
	    wdata_m_inf,
	    wlast_m_inf,
	   wvalid_m_inf,
	   wready_m_inf,
	
	      bid_m_inf,
	    bresp_m_inf,
	   bvalid_m_inf,
	   bready_m_inf 
);

// ===============================================================
//  					Input / Output 
// ===============================================================
parameter   ID_WIDTH = 4;
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;
// << CHIP io port with system >>
input             clk,rst_n;
input              in_valid;
input      [4 :0]  frame_id;
input      [3 :0]    net_id;     
input      [5 :0]     loc_x; 
input      [5 :0]     loc_y; 
output reg [13:0] 	   cost;
output reg             busy;       
  
// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       Your AXI-4 interface could be designed as a bridge in submodule,
	   therefore I declared output of AXI as wire.  
	   Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)	axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output reg                   arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)	axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output reg                    rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1) 	axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output reg                   awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)	axi write data channel 
output reg                    wvalid_m_inf;
input  wire                   wready_m_inf;
output reg [DATA_WIDTH-1:0]    wdata_m_inf;
output reg                     wlast_m_inf;
// -------------------------
// (3)	axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output                        bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

assign    arid_m_inf  = 0;
assign arburst_m_inf  = 2'b01;  // INCR
assign  arsize_m_inf  = 3'b100; // 
assign   arlen_m_inf  = 8'd127; // 128 beat

localparam     S_IDLE_READ = 3'b000;
localparam         S_CLEAR = 3'b001; // 001
localparam          S_FILL = 3'b010; // 100
localparam       S_RETRACE = 3'b011; // 101
localparam   S_WAIT_WEIGHT = 3'b100; // 010
localparam       S_WAIT_WB = 3'b101; // 011
localparam        S_DRM_WB = 3'b110;
localparam          S_WAIT = 4'b1000;

integer i, j;

reg [2:0]    state, next_state;
reg [4:0]         cur_frame_id;
reg [3:0]        cur_route_cnt;
reg [4:0]       route_count_32;

reg [6:0]             cost_cnt;
reg [5:0]             src_x_arr [0:14];
reg [5:0]             src_y_arr [0:14];
reg [5:0]             snk_x_arr [0:14];
reg [5:0]             snk_y_arr [0:14];
reg [3:0]             ne_id_arr [0:14];

reg  [1  :0]        reg_map_reg [0:63][0:63];
reg  [6  :0]           dram_ctr;
reg                  posedge_valid;

reg  [3:  0]              z2_o3;
reg  [3:  0]        z2_o3_final;

wire [3  :0]   dram_rdata_slice [0:31];

reg  [127:0]  sram_din_location;
reg  [6  :0] sram_addr_location;
reg  [127:0] sram_dout_location;
reg  [31 :0]   sram_we_location;

reg  [127:0]    sram_din_weight;
reg  [6  :0]   sram_addr_weight;
reg  [127:0]   sram_dout_weight;
reg              sram_we_weight;


reg        state_of_weight_sram;
reg               state_of_psum;
reg  [5  :0]          retrace_x;
reg  [5  :0]          retrace_y;
wire [6  :0]        retrace_x_l;

reg  [4  :0]        cost_pre_sum [0:15];

reg  [6 :0]     sram_addr_bitmap;
reg              sram_din_bitmap;
reg  [31:0]     sram_dout_bitmap;
reg  [31:0]       sram_we_bitmap;

wire [6  :0]         retrace_x_r;
wire [6  :0]         retrace_y_u;
wire [6:0]          retrace_y_uu;
wire [6  :0]         retrace_y_d;
wire [6:0]          retrace_y_dd;
reg [1:0]          walked_u_or_d;
reg                 walked_u1_d0;
reg  state_of_weight_sram_helper;

reg          delay_state_of_psum;
reg          reg_of_change_z2_o3;

reg [127:0] loc_sram_dout_reg;
reg [5:0] cur_src_x, cur_src_y;

assign retrace_x_l  = retrace_x - 1;
assign retrace_x_r  = retrace_x + 1;
assign retrace_y_u  = retrace_y - 1;
assign retrace_y_d  = retrace_y + 1;

genvar gv_i;
generate
	for (gv_i = 0; gv_i < 32; gv_i = gv_i + 1) begin
		assign dram_rdata_slice[gv_i] = rdata_m_inf[4*gv_i +: 4];
	end
endgenerate

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= S_IDLE_READ;
	end 
	else begin
		state <= next_state;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		cur_route_cnt <= 4'd0;
	end
	else begin
		if (state == S_IDLE_READ) begin
			cur_route_cnt <= 4'd0;
		end
		if (state == S_RETRACE
         && src_x_arr[cur_route_cnt] == retrace_x
		 && src_y_arr[cur_route_cnt] == retrace_y) begin
			cur_route_cnt <= cur_route_cnt + 1;
		end
	end
end


always @(*) begin
	next_state = state;
	case (state)
		S_IDLE_READ: begin
			if (rlast_m_inf) begin
				next_state = S_CLEAR;
			end
		end
		S_CLEAR: begin
			next_state = S_FILL;
		end
		S_FILL: begin
			if  (reg_map_reg[retrace_y_d [5:0]][retrace_x   [5:0]][1]
			  || reg_map_reg[retrace_y_u [5:0]][retrace_x   [5:0]][1]
			  || reg_map_reg[retrace_y   [5:0]][retrace_x_l [5:0]][1]
			  || reg_map_reg[retrace_y   [5:0]][retrace_x_r [5:0]][1]) begin
				next_state = S_RETRACE;
			end
		end
		S_RETRACE: begin
			if  (src_x_arr[cur_route_cnt] == retrace_x
			  && src_y_arr[cur_route_cnt] == retrace_y) begin
				if (cur_route_cnt + 1 == route_count_32[4:1]) begin
					if (state_of_weight_sram) begin
						next_state = S_WAIT_WEIGHT;
					end
					else begin
						next_state = S_WAIT_WB;
					end
				end
				else begin
					next_state = S_CLEAR;
				end
			end
		end
		S_WAIT_WEIGHT: begin
			if (!state_of_weight_sram) begin
				next_state = S_WAIT_WB;
			end
		end
		S_WAIT_WB: begin
			if (awready_m_inf) begin
				next_state = S_DRM_WB;
			end
		end
		S_DRM_WB: begin
			if (bvalid_m_inf) begin
				next_state = S_IDLE_READ;
			end
		end
	endcase
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		busy <= 1'd0;
	end
	else begin
		if (posedge_valid && ~in_valid) begin
			busy <= 1'd1;
		end
		else if (bvalid_m_inf) begin
			busy <= 0;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		dram_ctr <= 'd0;
	end
	else begin
		if (state == S_IDLE_READ || state_of_weight_sram) begin
			if (rvalid_m_inf) begin
				dram_ctr <= dram_ctr + 1;
			end
		end
		else if (state == S_DRM_WB) begin
            if (!wready_m_inf && wvalid_m_inf) begin
                dram_ctr <= 1;
            end
            if (wready_m_inf && wvalid_m_inf && !wlast_m_inf) begin
                dram_ctr <= dram_ctr + 1;
            end
		end
	end
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        reg_of_change_z2_o3 <= 1'b0;
    end
    else begin
        reg_of_change_z2_o3 <= (state == S_FILL);
    end
end

// Optimization of faster 2233 propogation
always @(*) begin
    z2_o3_final = z2_o3;
    if (reg_of_change_z2_o3) begin
        z2_o3_final = {z2_o3[1], z2_o3[0], z2_o3[3], z2_o3[2]};
    end
end

always @(posedge clk) begin
		if (state == S_CLEAR) begin
			z2_o3 <= 4'b0110;
		end
		else if (state == S_RETRACE && !reg_of_change_z2_o3) begin
			z2_o3 <= {z2_o3[2], z2_o3[1], z2_o3[0], z2_o3[3]};
		end
		else if (state == S_FILL || reg_of_change_z2_o3) begin
			z2_o3 <= {z2_o3[0], z2_o3[3], z2_o3[2], z2_o3[1]};
		end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cur_frame_id <= 0;
	end 
	else if (in_valid) begin
		cur_frame_id <= frame_id;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		route_count_32 <= 4'd0;
	end
	else begin
        if (state == S_WAIT_WB) begin
            route_count_32 <= 4'd0;
        end
		if (in_valid) begin
			route_count_32 <= route_count_32 + 1;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		for (i = 0; i < 15; i = i + 1) begin
			snk_x_arr[i] <= 6'd0;
			snk_y_arr[i] <= 6'd0;
		end
	end
	else begin
		if (in_valid && route_count_32[0]) begin
			snk_x_arr[route_count_32 [4:1]] <= loc_x ;
			snk_y_arr[route_count_32 [4:1]] <= loc_y;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		for (i = 0; i < 15; i = i + 1) begin
			src_x_arr[i] <= 6'd0;
			src_y_arr[i] <= 6'd0;
			ne_id_arr[i] <= 6'd0;

		end
	end
	else begin
		if (in_valid && !route_count_32[0]) begin
			src_x_arr[route_count_32[4:1]] <= loc_x;
			src_y_arr[route_count_32[4:1]] <= loc_y;
			ne_id_arr[route_count_32 [4:1]] <= net_id;
		end
	end
end

always @(posedge clk) begin
	if (state == S_IDLE_READ) begin
		if (!dram_ctr[0]) begin
			for (i = 0; i < 32; i = i + 1) begin
				reg_map_reg[dram_ctr[6:1]][i] <= |dram_rdata_slice[i];
			end
		end
		else begin
			for (i = 32; i < 64; i = i + 1) begin
				reg_map_reg[dram_ctr[6:1]][i] <= |dram_rdata_slice[i - 32];
			end
		end
	end
	else if (state == S_CLEAR) begin
		for (i = 0; i < 64; i = i + 1) begin
			for (j = 0; j < 64; j = j + 1) begin
				if (reg_map_reg[i][j][1] == 1'b1) begin
					reg_map_reg[i][j] <= 2'd0;
				end
			end
		end
		reg_map_reg[src_y_arr[cur_route_cnt]][src_x_arr[cur_route_cnt]] <= 2'd2;
	end
	else if (state == S_FILL) begin
		for (i = 1; i < 63; i = i + 1) begin
			for (j = 1; j < 63; j = j + 1) begin
				if (reg_map_reg[i][j] == 2'b00 && 
						(  reg_map_reg[i+1][j  ][1] 
						|| reg_map_reg[i-1][j  ][1] 
						|| reg_map_reg[i  ][j-1][1] 
						|| reg_map_reg[i  ][j+1][1])) begin
					reg_map_reg[i][j] <= {1'b1, z2_o3[0]};
				end
			end
		end
		// Boundaries
		for (i = 1; i < 63; i = i + 1) begin
			if (reg_map_reg[i][0] == 2'b00 && 
					(  reg_map_reg[i+1][0][1] 
					|| reg_map_reg[i-1][0][1] 
					|| reg_map_reg[i  ][1][1])) begin
				reg_map_reg[i][0] <= {1'b1, z2_o3[0]};
			end
		end
		for (i = 1; i < 63; i = i + 1) begin
			if (reg_map_reg[i][63] == 2'b00 && 
					(  reg_map_reg[i+1][63][1] 
					|| reg_map_reg[i-1][63][1] 
					|| reg_map_reg[i  ][62][1])) begin
				reg_map_reg[i][63] <= {1'b1, z2_o3[0]};
			end
		end
		for (i = 1; i < 63; i = i + 1) begin
			if (reg_map_reg[0][i] == 2'b00 && 
					(  reg_map_reg[0][i+1][1] 
					|| reg_map_reg[0][i-1][1] 
					|| reg_map_reg[1][i  ][1])) begin
				reg_map_reg[0][i] <= {1'b1, z2_o3[0]};
			end
		end
		for (i = 1; i < 63; i = i + 1) begin
			if (reg_map_reg[63][i] == 2'b00 && 
					(  reg_map_reg[63][i+1][1] 
					|| reg_map_reg[63][i-1][1] 
					|| reg_map_reg[62][i  ][1])) begin
				reg_map_reg[63][i] <= {1'b1, z2_o3[0]};
			end
		end
		if (reg_map_reg[0][63] == 2'b00 && 
				(  reg_map_reg[0][62][1] 
				|| reg_map_reg[1][63][1])) begin
			reg_map_reg[0][63] <= {1'b1, z2_o3[0]};
		end
		if (reg_map_reg[63][0] == 2'b00 && 
				(  reg_map_reg[63][1][1] 
				|| reg_map_reg[62][0][1])) begin
			reg_map_reg[63][0] <= {1'b1, z2_o3[0]};
		end
		if (reg_map_reg[63][63] == 2'b00 && 
				(  reg_map_reg[63][62][1] 
				|| reg_map_reg[62][63][1])) begin
			reg_map_reg[63][63] <= {1'b1, z2_o3[0]};
		end
	end
	else if (state == S_RETRACE) begin
		reg_map_reg[retrace_y][retrace_x] <= 2'b01;
	end
end
reg stalled;

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		retrace_x <= 6'd0;
		retrace_y <= 6'd0;
	end
	else begin
		if (state == S_CLEAR) begin
			retrace_x <= snk_x_arr[cur_route_cnt];
			retrace_y <= snk_y_arr[cur_route_cnt];
		end
		else if (state == S_RETRACE) begin
			if    (reg_map_reg[retrace_y_d [5:0]][retrace_x [5:0]][1] == 1'b1
				&& reg_map_reg[retrace_y_d [5:0]][retrace_x [5:0]][0] == z2_o3_final[0]
				&& retrace_y_d[6] == 1'b0) begin
				retrace_y <= retrace_y_d;
			end
			else if (reg_map_reg[retrace_y_u [5:0]][retrace_x [5:0]][1] == 1'b1
				  && reg_map_reg[retrace_y_u [5:0]][retrace_x [5:0]][0] == z2_o3_final[0]
				  && retrace_y_u[6] == 1'b0) begin
				retrace_y <= retrace_y_u;
			end
			else if (reg_map_reg[retrace_y [5:0]][retrace_x_r [5:0]][1] == 1'b1
				  && reg_map_reg[retrace_y [5:0]][retrace_x_r [5:0]][0] == z2_o3_final[0]
				  && retrace_x_r[6] == 1'b0) begin
				retrace_x <= retrace_x_r;
			end
            else begin
                retrace_x <= retrace_x_l;
            end
		end
	end
end


always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        cur_src_x <= 'd0;
        cur_src_y <= 'd0;
    end
    else begin
        cur_src_x <= src_x_arr[cur_route_cnt];
        cur_src_y <= src_y_arr[cur_route_cnt]; 
    end
end



always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		posedge_valid <= 'd0;
	end 
	else begin
		posedge_valid <= in_valid;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		delay_state_of_psum <= 1'b0;
	end
	else begin
		delay_state_of_psum <= state_of_psum;
	end
end

always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cost <= 0;
	end
	else begin
    	if (!state[2]) begin
    	    cost <= 0;
    	end
		else if (delay_state_of_psum) begin
			cost <= cost + cost_pre_sum[0 ] + cost_pre_sum[1 ]
						 + cost_pre_sum[2 ] + cost_pre_sum[3 ]
						 + cost_pre_sum[4 ] + cost_pre_sum[5 ]
						 + cost_pre_sum[6 ] + cost_pre_sum[7 ]
						 + cost_pre_sum[8 ] + cost_pre_sum[9 ] 
						 + cost_pre_sum[10] + cost_pre_sum[11]
						 + cost_pre_sum[12] + cost_pre_sum[13]
						 + cost_pre_sum[14] + cost_pre_sum[15];
		end
	end
end

// ===========================
//   AXI READ
// ===========================

assign araddr_m_inf = {14'h0, (state != S_IDLE_READ), (state == S_IDLE_READ), cur_frame_id, 11'h0};

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		arvalid_m_inf <= 1'd0;
	end
	else begin
		if (arready_m_inf) begin
			arvalid_m_inf <= 1'd0;
		end
		else if (~posedge_valid && in_valid) begin
			arvalid_m_inf <= 1'd1;
		end
		else if (state == S_IDLE_READ && rlast_m_inf) begin
			arvalid_m_inf <= 1'd1;
		end
	end
end

assign rready_m_inf = 1'd1;

// ===========================
//   AXI WRITE
// ===========================

assign awid_m_inf    = 0;
assign awburst_m_inf = 2'b01; // INCR
assign awsize_m_inf  = 3'b100; //
assign awlen_m_inf   = 8'd127;  // 128 beat
assign awaddr_m_inf  = {16'h1, cur_frame_id, 11'h0};

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		wlast_m_inf <= 1'b0;
	end
	else begin
		wlast_m_inf <= (dram_ctr == 7'd127);
	end
end

always @(*) begin
	wdata_m_inf = loc_sram_dout_reg;
end

assign bready_m_inf = 1'd1;
assign awvalid_m_inf = (state == S_WAIT_WB);


always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		wvalid_m_inf <= 1'b0;
	end
	else begin
		if (awready_m_inf) begin
			wvalid_m_inf <= 1'b1;
		end
		else if (wlast_m_inf) begin
			wvalid_m_inf <= 1'b0;
		end
	end
end


// ===========================
//   COST CALCULATION
// ===========================

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		state_of_psum <= 1'b0;
	end
	else begin
		if (state == S_WAIT_WB) begin
			state_of_psum <= 1'b1;
		end
		else if (state_of_psum && cost_cnt == 7'd0) begin
			state_of_psum <= 1'b0;
		end
	end
end 

always @(posedge clk) begin
	if (state_of_psum) begin
        cost_pre_sum[ 0] <= ({4{sram_dout_bitmap[ 0]}} & sram_dout_weight[  0+:4]) 
		                  + ({4{sram_dout_bitmap[ 1]}} & sram_dout_weight[  4+:4]);

        cost_pre_sum[ 1] <= ({4{sram_dout_bitmap[ 2]}} & sram_dout_weight[  8+:4])
                          + ({4{sram_dout_bitmap[ 3]}} & sram_dout_weight[ 12+:4]);

        cost_pre_sum[ 2] <= ({4{sram_dout_bitmap[ 4]}} & sram_dout_weight[ 16+:4])
                          + ({4{sram_dout_bitmap[ 5]}} & sram_dout_weight[ 20+:4]);

        cost_pre_sum[ 3] <= ({4{sram_dout_bitmap[ 6]}} & sram_dout_weight[ 24+:4])
                          + ({4{sram_dout_bitmap[ 7]}} & sram_dout_weight[ 28+:4]);

        cost_pre_sum[ 4] <= ({4{sram_dout_bitmap[ 8]}} & sram_dout_weight[ 32+:4])
                          + ({4{sram_dout_bitmap[ 9]}} & sram_dout_weight[ 36+:4]);

        cost_pre_sum[ 5] <= ({4{sram_dout_bitmap[10]}} & sram_dout_weight[ 40+:4])
                          + ({4{sram_dout_bitmap[11]}} & sram_dout_weight[ 44+:4]);

        cost_pre_sum[ 6] <= ({4{sram_dout_bitmap[12]}} & sram_dout_weight[ 48+:4])
                          + ({4{sram_dout_bitmap[13]}} & sram_dout_weight[ 52+:4]);

        cost_pre_sum[ 7] <= ({4{sram_dout_bitmap[14]}} & sram_dout_weight[ 56+:4])
                          + ({4{sram_dout_bitmap[15]}} & sram_dout_weight[ 60+:4]);

        cost_pre_sum[ 8] <= ({4{sram_dout_bitmap[16]}} & sram_dout_weight[ 64+:4])
                          + ({4{sram_dout_bitmap[17]}} & sram_dout_weight[ 68+:4]);

        cost_pre_sum[ 9] <= ({4{sram_dout_bitmap[18]}} & sram_dout_weight[ 72+:4])
                          + ({4{sram_dout_bitmap[19]}} & sram_dout_weight[ 76+:4]);

        cost_pre_sum[10] <= ({4{sram_dout_bitmap[20]}} & sram_dout_weight[ 80+:4])
                          + ({4{sram_dout_bitmap[21]}} & sram_dout_weight[ 84+:4]);

        cost_pre_sum[11] <= ({4{sram_dout_bitmap[22]}} & sram_dout_weight[ 88+:4])
                          + ({4{sram_dout_bitmap[23]}} & sram_dout_weight[ 92+:4]);

        cost_pre_sum[12] <= ({4{sram_dout_bitmap[24]}} & sram_dout_weight[ 96+:4])
                          + ({4{sram_dout_bitmap[25]}} & sram_dout_weight[100+:4]);

        cost_pre_sum[13] <= ({4{sram_dout_bitmap[26]}} & sram_dout_weight[104+:4])
                          + ({4{sram_dout_bitmap[27]}} & sram_dout_weight[108+:4]);

        cost_pre_sum[14] <= ({4{sram_dout_bitmap[28]}} & sram_dout_weight[112+:4])
                          + ({4{sram_dout_bitmap[29]}} & sram_dout_weight[116+:4]);
						  
        cost_pre_sum[15] <= ({4{sram_dout_bitmap[30]}} & sram_dout_weight[120+:4])
                          + ({4{sram_dout_bitmap[31]}} & sram_dout_weight[124+:4]);
	end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		cost_cnt <= 0;
	end
	else begin
		if (state == S_WAIT_WB || state_of_psum) begin
			cost_cnt <= cost_cnt + 1;
		end
		else begin
			cost_cnt <= 0;
		end
	end
end 

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_addr_location = dram_ctr;
	end
	else if (state == S_RETRACE) begin
		sram_addr_location = {retrace_y[5:0], retrace_x[5]};
	end
	else if (state == S_DRM_WB) begin
		sram_addr_location = dram_ctr;
        if (wvalid_m_inf && wready_m_inf) begin
            sram_addr_location = dram_ctr + 1;
        end
	end
	else begin
		sram_addr_location = 7'd0;
	end
end

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_din_location = rdata_m_inf;
	end
	else begin
		sram_din_location = 128'd0;
		sram_din_location[4*retrace_x[4:0]+:4] = ne_id_arr[cur_route_cnt];
	end
end

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_we_location = 32'b0;
	end
	else if (state == S_RETRACE) begin
		sram_we_location = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
		sram_we_location[retrace_x[4:0]] = 1'b0;
	end
	else begin
		sram_we_location = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
	end
end

memory_wrapper_loc sram_location (
	.clk  (clk),
	.addr (sram_addr_location),
	.din  (sram_din_location),
	.dout (sram_dout_location),
	.web   (sram_we_location),
	.oe   (1'b1),
	.cs   (1'b1)
);

always @(*) begin
	if (state_of_weight_sram) begin
		sram_addr_weight = dram_ctr;
	end
	else begin
		sram_addr_weight = cost_cnt;
	end
end

always @(*) begin
	if (state_of_weight_sram) begin
	    sram_din_weight = rdata_m_inf;
	end
	else begin
	    sram_din_weight = 128'd0;
	end
end

always @(*) begin
	if (state_of_weight_sram) begin
		sram_we_weight = 1'b0;
	end
	else begin
		sram_we_weight = 1'b1;
	end
end

always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        state_of_weight_sram_helper <= 1'b0;
    end
    else begin
        state_of_weight_sram_helper <= (state == S_IDLE_READ);
    end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		state_of_weight_sram <= 1'b0;
	end
	else begin
		if (state_of_weight_sram == 1'b1 && dram_ctr == 'd127) begin
			state_of_weight_sram <= 1'b0;
		end
		else if (next_state == S_CLEAR && state == S_IDLE_READ) begin
			state_of_weight_sram <= 1'b1;
		end
	end
end

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_addr_bitmap = dram_ctr;
	end
	else if (state == S_RETRACE) begin
		sram_addr_bitmap = {retrace_y[5:0], retrace_x[5]};
	end
	else begin
		sram_addr_bitmap = cost_cnt;
	end
end

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_din_bitmap = 1'b0;
	end
	else begin
		sram_din_bitmap = 1'b1;
	end
end

always @(*) begin
	if (state == S_IDLE_READ) begin
		sram_we_bitmap = 32'b0000_0000_0000_0000_0000_0000_0000_0000;
	end
	else if (state == S_RETRACE) begin
		sram_we_bitmap = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
		if (!(retrace_x == snk_x_arr[cur_route_cnt] && retrace_y == snk_y_arr[cur_route_cnt]) && !(retrace_x == src_x_arr[cur_route_cnt] && retrace_y == src_y_arr[cur_route_cnt])) begin
			sram_we_bitmap[retrace_x[4:0]] = 1'b0;
		end
	end
	else begin
		sram_we_bitmap = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
	end
end


always @(posedge clk) begin
    if (wvalid_m_inf && ~wready_m_inf) begin
        loc_sram_dout_reg <= loc_sram_dout_reg;
    end
    else begin
        loc_sram_dout_reg <= sram_dout_location;
    end
end

memory_wrapper sram_weight (
	.clk  (clk),
	.addr (sram_addr_weight),
	.din  (sram_din_weight),
	.dout (sram_dout_weight),
	.we   (sram_we_weight),
	.oe   (1'b1),
	.cs   (1'b1)
);

memory_wrapper_bitmap sram_bitmap (
	.clk(clk),
	.addr(sram_addr_bitmap),
	.din({32{sram_din_bitmap}}),
	.dout(sram_dout_bitmap),
	.web (sram_we_bitmap),
	.oe(1'b1),
	.cs(1'b1)
);


endmodule

module memory_wrapper_loc (
    input         clk,
    input  [6:0]  addr,
    input  [127:0]  din,
    output [127:0]  dout,
    input  [31:0]  web,
    input         oe,
    input         cs
);

    // Instantiate the memory module: loc_sram_128X128
    loc_sram_128X128 mem_inst (
    .A0   (addr[  0]), .A1   (addr[  1]), .A2   (addr[  2]), .A3   (addr[  3]),
    .A4   (addr[  4]), .A5   (addr[  5]), .A6   (addr[  6]), .DO0  (dout[  0]),
    .DO1  (dout[  1]), .DO2  (dout[  2]), .DO3  (dout[  3]), .DO4  (dout[  4]),
    .DO5  (dout[  5]), .DO6  (dout[  6]), .DO7  (dout[  7]), .DO8  (dout[  8]),
    .DO9  (dout[  9]), .DO10 (dout[ 10]), .DO11 (dout[ 11]), .DO12 (dout[ 12]),
    .DO13 (dout[ 13]), .DO14 (dout[ 14]), .DO15 (dout[ 15]), .DO16 (dout[ 16]),
    .DO17 (dout[ 17]), .DO18 (dout[ 18]), .DO19 (dout[ 19]), .DO20 (dout[ 20]),
    .DO21 (dout[ 21]), .DO22 (dout[ 22]), .DO23 (dout[ 23]), .DO24 (dout[ 24]),
    .DO25 (dout[ 25]), .DO26 (dout[ 26]), .DO27 (dout[ 27]), .DO28 (dout[ 28]),
    .DO29 (dout[ 29]), .DO30 (dout[ 30]), .DO31 (dout[ 31]), .DO32 (dout[ 32]),
    .DO33 (dout[ 33]), .DO34 (dout[ 34]), .DO35 (dout[ 35]), .DO36 (dout[ 36]),
    .DO37 (dout[ 37]), .DO38 (dout[ 38]), .DO39 (dout[ 39]), .DO40 (dout[ 40]),
    .DO41 (dout[ 41]), .DO42 (dout[ 42]), .DO43 (dout[ 43]), .DO44 (dout[ 44]),
    .DO45 (dout[ 45]), .DO46 (dout[ 46]), .DO47 (dout[ 47]), .DO48 (dout[ 48]),
    .DO49 (dout[ 49]), .DO50 (dout[ 50]), .DO51 (dout[ 51]), .DO52 (dout[ 52]),
    .DO53 (dout[ 53]), .DO54 (dout[ 54]), .DO55 (dout[ 55]), .DO56 (dout[ 56]),
    .DO57 (dout[ 57]), .DO58 (dout[ 58]), .DO59 (dout[ 59]), .DO60 (dout[ 60]),
    .DO61 (dout[ 61]), .DO62 (dout[ 62]), .DO63 (dout[ 63]), .DO64 (dout[ 64]),
    .DO65 (dout[ 65]), .DO66 (dout[ 66]), .DO67 (dout[ 67]), .DO68 (dout[ 68]),
    .DO69 (dout[ 69]), .DO70 (dout[ 70]), .DO71 (dout[ 71]), .DO72 (dout[ 72]),
    .DO73 (dout[ 73]), .DO74 (dout[ 74]), .DO75 (dout[ 75]), .DO76 (dout[ 76]),
    .DO77 (dout[ 77]), .DO78 (dout[ 78]), .DO79 (dout[ 79]), .DO80 (dout[ 80]),
    .DO81 (dout[ 81]), .DO82 (dout[ 82]), .DO83 (dout[ 83]), .DO84 (dout[ 84]),
    .DO85 (dout[ 85]), .DO86 (dout[ 86]), .DO87 (dout[ 87]), .DO88 (dout[ 88]),
    .DO89 (dout[ 89]), .DO90 (dout[ 90]), .DO91 (dout[ 91]), .DO92 (dout[ 92]),
    .DO93 (dout[ 93]), .DO94 (dout[ 94]), .DO95 (dout[ 95]), .DO96 (dout[ 96]),
    .DO97 (dout[ 97]), .DO98 (dout[ 98]), .DO99 (dout[ 99]), .DO100(dout[100]),
    .DO101(dout[101]), .DO102(dout[102]), .DO103(dout[103]), .DO104(dout[104]),
    .DO105(dout[105]), .DO106(dout[106]), .DO107(dout[107]), .DO108(dout[108]),
    .DO109(dout[109]), .DO110(dout[110]), .DO111(dout[111]), .DO112(dout[112]),
    .DO113(dout[113]), .DO114(dout[114]), .DO115(dout[115]), .DO116(dout[116]),
    .DO117(dout[117]), .DO118(dout[118]), .DO119(dout[119]), .DO120(dout[120]),
    .DO121(dout[121]), .DO122(dout[122]), .DO123(dout[123]), .DO124(dout[124]),
    .DO125(dout[125]), .DO126(dout[126]), .DO127(dout[127]), .DI0  (din [  0]),
    .DI1  (din [  1]), .DI2  (din [  2]), .DI3  (din [  3]), .DI4  (din [  4]),
    .DI5  (din [  5]), .DI6  (din [  6]), .DI7  (din [  7]), .DI8  (din [  8]),
    .DI9  (din[9]), .DI10(din[10]), .DI11(din[11]), .DI12(din[12]),
    .DI13 (din[13]), .DI14(din[14]), .DI15(din[15]), .DI16(din[16]),
    .DI17 (din[17]), .DI18(din[18]), .DI19(din[19]), .DI20(din[20]),
    .DI21 (din[21]), .DI22(din[22]), .DI23(din[23]), .DI24(din[24]),
    .DI25 (din[25]), .DI26(din[26]), .DI27(din[27]), .DI28(din[28]),
    .DI29 (din[29]), .DI30(din[30]), .DI31(din[31]), .DI32(din[32]),
    .DI33 (din[33]), .DI34(din[34]), .DI35(din[35]), .DI36(din[36]),
    .DI37 (din[37]), .DI38(din[38]), .DI39(din[39]), .DI40(din[40]),
    .DI41 (din[41]), .DI42(din[42]), .DI43(din[43]), .DI44(din[44]),
    .DI45 (din[45]), .DI46(din[46]), .DI47(din[47]), .DI48(din[48]),
    .DI49 (din[49]), .DI50(din[50]), .DI51(din[51]), .DI52(din[52]),
    .DI53 (din[53]), .DI54(din[54]), .DI55(din[55]), .DI56(din[56]),
    .DI57 (din[57]), .DI58(din[58]), .DI59(din[59]), .DI60(din[60]),
    .DI61 (din[61]), .DI62(din[62]), .DI63(din[63]), .DI64(din[64]),
    .DI65 (din[65]), .DI66(din[66]), .DI67(din[67]), .DI68(din[68]),
    .DI69 (din[69]), .DI70(din[70]), .DI71(din[71]), .DI72(din[72]),
    .DI73 (din[73]), .DI74(din[74]), .DI75(din[75]), .DI76(din[76]),
    .DI77 (din[77]), .DI78(din[78]), .DI79(din[79]), .DI80(din[80]),
    .DI81 (din[81]), .DI82(din[82]), .DI83(din[83]), .DI84(din[84]),
    .DI85 (din[85]), .DI86(din[86]), .DI87(din[87]), .DI88(din[88]),
    .DI89 (din[89]), .DI90(din[90]), .DI91(din[91]), .DI92(din[92]),
    .DI93 (din[93]), .DI94(din[94]), .DI95(din[95]), .DI96(din[96]),
    .DI97 (din[97]), .DI98(din[98]), .DI99(din[99]), .DI100(din[100]),
    .DI101(din[101]), .DI102(din[102]), .DI103(din[103]), .DI104(din[104]),
    .DI105(din[105]), .DI106(din[106]), .DI107(din[107]), .DI108(din[108]),
    .DI109(din[109]), .DI110(din[110]), .DI111(din[111]), .DI112(din[112]),
    .DI113(din[113]), .DI114(din[114]), .DI115(din[115]), .DI116(din[116]),
    .DI117(din[117]), .DI118(din[118]), .DI119(din[119]), .DI120(din[120]),
    .DI121(din[121]), .DI122(din[122]), .DI123(din[123]), .DI124(din[124]),
    .DI125(din[125]), .DI126(din[126]), .DI127(din[127]), .CK(clk),
    .WEB0 (web[0]), .WEB1(web[1]), .WEB2(web[2]), .WEB3(web[3]),
    .WEB4 (web[4]), .WEB5(web[5]), .WEB6(web[6]), .WEB7(web[7]),
    .WEB8 (web[8]), .WEB9(web[9]), .WEB10(web[10]), .WEB11(web[11]),
    .WEB12(web[12]), .WEB13(web[13]), .WEB14(web[14]), .WEB15(web[15]),
    .WEB16(web[16]), .WEB17(web[17]), .WEB18(web[18]), .WEB19(web[19]),
    .WEB20(web[20]), .WEB21(web[21]), .WEB22(web[22]), .WEB23(web[23]),
    .WEB24(web[24]), .WEB25(web[25]), .WEB26(web[26]), .WEB27(web[27]),
    .WEB28(web[28]), .WEB29(web[29]), .WEB30(web[30]), .WEB31(web[31]),
    .OE   (oe),      .CS(cs)
    );

endmodule



module memory_wrapper(
    input         clk,                      // Clock,
    input  [6:0]  addr,         // Consolidated address bus,
    input  [127:0]  din,          // Consolidated data input,
    output [127:0]  dout,         // Consolidated data output,
    input         we,                       // Write enable (active-high),
    input         oe,                       // Output enable,
    input         cs                        // Chip select
);

    // Instantiate the memory module with dynamic name: sram_128x128b
    sram_128x128b mem_inst (
        .A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]),
        .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .DO0(dout[0]),
        .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]),
        .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]), .DO8(dout[8]),
        .DO9(dout[9]), .DO10(dout[10]), .DO11(dout[11]), .DO12(dout[12]),
        .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]), .DO16(dout[16]),
        .DO17(dout[17]), .DO18(dout[18]), .DO19(dout[19]), .DO20(dout[20]),
        .DO21(dout[21]), .DO22(dout[22]), .DO23(dout[23]), .DO24(dout[24]),
        .DO25(dout[25]), .DO26(dout[26]), .DO27(dout[27]), .DO28(dout[28]),
        .DO29(dout[29]), .DO30(dout[30]),
        .DO31(dout[31]),
        .DO32(dout[32]),
        .DO33(dout[33]),
        .DO34(dout[34]),
        .DO35(dout[35]),
        .DO36(dout[36]),
        .DO37(dout[37]),
        .DO38(dout[38]),
        .DO39(dout[39]),
        .DO40(dout[40]),
        .DO41(dout[41]),
        .DO42(dout[42]),
        .DO43(dout[43]),
        .DO44(dout[44]),
        .DO45(dout[45]),
        .DO46(dout[46]),
        .DO47(dout[47]),
        .DO48(dout[48]),
        .DO49(dout[49]),
        .DO50(dout[50]),
        .DO51(dout[51]),
        .DO52(dout[52]),
        .DO53(dout[53]),
        .DO54(dout[54]),
        .DO55(dout[55]),
        .DO56(dout[56]),
        .DO57(dout[57]),
        .DO58(dout[58]),
        .DO59(dout[59]),
        .DO60(dout[60]),
        .DO61(dout[61]),
        .DO62(dout[62]),
        .DO63(dout[63]),
        .DO64(dout[64]),
        .DO65(dout[65]),
        .DO66(dout[66]),
        .DO67(dout[67]),
        .DO68(dout[68]),
        .DO69(dout[69]),
        .DO70(dout[70]),
        .DO71(dout[71]),
        .DO72(dout[72]),
        .DO73(dout[73]),
        .DO74(dout[74]),
        .DO75(dout[75]),
        .DO76(dout[76]),
        .DO77(dout[77]),
        .DO78(dout[78]),
        .DO79(dout[79]),
        .DO80(dout[80]),
        .DO81(dout[81]),
        .DO82(dout[82]),
        .DO83(dout[83]),
        .DO84(dout[84]),
        .DO85(dout[85]),
        .DO86(dout[86]),
        .DO87(dout[87]),
        .DO88(dout[88]),
        .DO89(dout[89]),
        .DO90(dout[90]),
        .DO91(dout[91]),
        .DO92(dout[92]),
        .DO93(dout[93]),
        .DO94(dout[94]),
        .DO95(dout[95]),
        .DO96(dout[96]),
        .DO97(dout[97]),
        .DO98(dout[98]),
        .DO99(dout[99]),
        .DO100(dout[100]),
        .DO101(dout[101]),
        .DO102(dout[102]),
        .DO103(dout[103]),
        .DO104(dout[104]),
        .DO105(dout[105]),
        .DO106(dout[106]),
        .DO107(dout[107]),
        .DO108(dout[108]),
        .DO109(dout[109]),
        .DO110(dout[110]),
        .DO111(dout[111]),
        .DO112(dout[112]),
        .DO113(dout[113]),
        .DO114(dout[114]),
        .DO115(dout[115]),
        .DO116(dout[116]),
        .DO117(dout[117]),
        .DO118(dout[118]),
        .DO119(dout[119]),
        .DO120(dout[120]),
        .DO121(dout[121]),
        .DO122(dout[122]),
        .DO123(dout[123]),
        .DO124(dout[124]),
        .DO125(dout[125]),
        .DO126(dout[126]),
        .DO127(dout[127]), .DI0(din[0]), .DI1(din[1]), .DI2(din[2]),
        .DI3(din[3]), .DI4(din[4]), .DI5(din[5]), .DI6(din[6]),
        .DI7(din[7]), .DI8(din[8]), .DI9(din[9]), .DI10(din[10]),
        .DI11(din[11]), .DI12(din[12]), .DI13(din[13]), .DI14(din[14]),
        .DI15(din[15]), .DI16(din[16]), .DI17(din[17]), .DI18(din[18]),
        .DI19(din[19]), .DI20(din[20]), .DI21(din[21]), .DI22(din[22]),
        .DI23(din[23]), .DI24(din[24]), .DI25(din[25]), .DI26(din[26]),
        .DI27(din[27]), .DI28(din[28]), .DI29(din[29]), .DI30(din[30]), .DI31(din[31]),
        .DI32(din[32]), .DI33(din[33]), .DI34(din[34]), .DI35(din[35]),
        .DI36(din[36]), .DI37(din[37]), .DI38(din[38]), .DI39(din[39]),
        .DI40(din[40]), .DI41(din[41]), .DI42(din[42]), .DI43(din[43]),
        .DI44(din[44]), .DI45(din[45]), .DI46(din[46]), .DI47(din[47]),
        .DI48(din[48]), .DI49(din[49]), .DI50(din[50]), .DI51(din[51]),
        .DI52(din[52]), .DI53(din[53]), .DI54(din[54]), .DI55(din[55]),
        .DI56(din[56]), .DI57(din[57]), .DI58(din[58]), .DI59(din[59]),
        .DI60(din[60]), .DI61(din[61]), .DI62(din[62]), .DI63(din[63]),
        .DI64(din[64]), .DI65(din[65]), .DI66(din[66]), .DI67(din[67]),
        .DI68(din[68]), .DI69(din[69]), .DI70(din[70]), .DI71(din[71]),
        .DI72(din[72]), .DI73(din[73]), .DI74(din[74]), .DI75(din[75]),
        .DI76(din[76]), .DI77(din[77]), .DI78(din[78]),
        .DI79(din[79]),
        .DI80(din[80]),
        .DI81(din[81]),
        .DI82(din[82]),
        .DI83(din[83]),
        .DI84(din[84]),
        .DI85(din[85]),
        .DI86(din[86]),
        .DI87(din[87]),
        .DI88(din[88]),
        .DI89(din[89]),
        .DI90(din[90]),
        .DI91(din[91]),
        .DI92(din[92]),
        .DI93(din[93]),
        .DI94(din[94]),
        .DI95(din[95]),
        .DI96(din[96]),
        .DI97(din[97]),
        .DI98(din[98]),
        .DI99(din[99]),
        .DI100(din[100]),
        .DI101(din[101]),
        .DI102(din[102]),
        .DI103(din[103]),
        .DI104(din[104]),
        .DI105(din[105]),
        .DI106(din[106]),
        .DI107(din[107]),
        .DI108(din[108]),
        .DI109(din[109]),
        .DI110(din[110]),
        .DI111(din[111]),
        .DI112(din[112]),
        .DI113(din[113]),
        .DI114(din[114]),
        .DI115(din[115]),
        .DI116(din[116]),
        .DI117(din[117]),
        .DI118(din[118]),
        .DI119(din[119]),
        .DI120(din[120]),
        .DI121(din[121]),
        .DI122(din[122]),
        .DI123(din[123]),
        .DI124(din[124]),
        .DI125(din[125]),
        .DI126(din[126]),
        .DI127(din[127]),
        .CK(clk),
        .WEB(we),
        .OE(oe),
        .CS(cs)
    );

endmodule

module memory_wrapper_bitmap(
    input         clk,
    input  [6:0]  addr,
    input  [31:0]  din,
    output [31:0]  dout,
    input  [31:0]  web,
    input         oe,
    input         cs
);

    bitmap_sram_128x32 mem_inst (
        .A0(addr[0]), .A1(addr[1]), .A2(addr[2]), .A3(addr[3]),
        .A4(addr[4]), .A5(addr[5]), .A6(addr[6]), .DO0(dout[0]),
        .DO1(dout[1]), .DO2(dout[2]), .DO3(dout[3]), .DO4(dout[4]),
        .DO5(dout[5]), .DO6(dout[6]), .DO7(dout[7]), .DO8(dout[8]),
        .DO9(dout[9]), .DO10(dout[10]), .DO11(dout[11]), .DO12(dout[12]),
        .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]), .DO16(dout[16]),
        .DO17(dout[17]), .DO18(dout[18]), .DO19(dout[19]), .DO20(dout[20]),
        .DO21(dout[21]), .DO22(dout[22]), .DO23(dout[23]), .DO24(dout[24]),
        .DO25(dout[25]), .DO26(dout[26]), .DO27(dout[27]), .DO28(dout[28]),
        .DO29(dout[29]), .DO30(dout[30]), .DO31(dout[31]),
        .DI0(din[0]), .DI1(din[1]), .DI2(din[2]), .DI3(din[3]),
        .DI4(din[4]), .DI5(din[5]), .DI6(din[6]), .DI7(din[7]),
        .DI8(din[8]), .DI9(din[9]), .DI10(din[10]), .DI11(din[11]),
        .DI12(din[12]), .DI13(din[13]), .DI14(din[14]), .DI15(din[15]),
        .DI16(din[16]), .DI17(din[17]), .DI18(din[18]), .DI19(din[19]),
        .DI20(din[20]), .DI21(din[21]), .DI22(din[22]), .DI23(din[23]),
        .DI24(din[24]), .DI25(din[25]), .DI26(din[26]), .DI27(din[27]),
        .DI28(din[28]), .DI29(din[29]), .DI30(din[30]), .DI31(din[31]),
        .CK(clk), .WEB0(web[0]), .WEB1(web[1]),
        .WEB2(web[2]), .WEB3(web[3]), .WEB4(web[4]), .WEB5(web[5]),
        .WEB6(web[6]), .WEB7(web[7]), .WEB8(web[8]), .WEB9(web[9]),
        .WEB10(web[10]), .WEB11(web[11]), .WEB12(web[12]), .WEB13(web[13]),
        .WEB14(web[14]), .WEB15(web[15]), .WEB16(web[16]), .WEB17(web[17]),
        .WEB18(web[18]), .WEB19(web[19]), .WEB20(web[20]), .WEB21(web[21]),
        .WEB22(web[22]), .WEB23(web[23]), .WEB24(web[24]), .WEB25(web[25]),
        .WEB26(web[26]), .WEB27(web[27]), .WEB28(web[28]), .WEB29(web[29]),
        .WEB30(web[30]), .WEB31(web[31]),
        .OE(oe),
        .CS(cs)
    );

endmodule
