module MAZE(
    // input
    input clk,
    input rst_n,
	input in_valid,
	input [1:0] in,

    // output
    output out_valid,
    output reg [1:0] out
);

parameter IDLE_INPUT = 1'b0;
parameter WALK       = 1'b1;

parameter SWORD   = 2'b10;
parameter WALL    = 2'b01;
parameter ROAD    = 2'b00;
parameter MONSTER = 2'b11;
// Right: 2d0; Down: 2d1; Left: 2d2; Up: 2d3

reg state;
reg next_state;
reg [1:0] damn_mp     [0:16][0:16];
reg [4:0] w_x;
reg [4:0] w_y;
reg       has_sword;

// ----------------------------------------------------------------
// Notes on this iteration of AREA stealing!!
// ----------------------------------------------------------------
// 1. 
// Assuming FSM bits has large fanout, changing FSM from 2 bit to
// 1 FSM bit + 1 auxiliary bit (smaller fanout), and combine 
// one bit FSM with out_valid together to save DFF.
// 
// 2. 
// Maximum of x and y are 16, which is 10000, so use x[4] == 1'b1
// instead of x == 5'd16.
//
// 3. (**** Massive impact on area! ****)
// Assuming a 3 bit DFF as counter, ctr == 3'b000 and ctr == 3'b111
// will be smaller than any number else i.g. ctr == 3'b010.
// I guess thats because an equal is pretty large, for 3'b111 you can 
// just 'AND' them. So I did a re-encoding on the map to steal area.
// Works well because every entry of map matrix has it.
//
// 4. Algorithm of flooding the death path
// raster scan every cycle, chessboard scan


// Thoughts on algorithm
//  0  -1   0
//~-1   0  +1
//  0 ~+1   0

//   X  1   X
// -~1  0 -~3
//   X  3   X
// up: 0 + 0 + 1 - 1 - 0 = 0

// 010
// 000
// 010
// right: 0 + 0 + 0 - 1 - 1 = 0


reg [1:0] cur_dir;
reg [1:0] next_dir;
reg cool_reg;

assign out_valid = state;

wire [4:0] w_y_add_1 = w_y + 1'd1;
wire [4:0] w_y_sub_1 = w_y - 1'd1;
wire [4:0] w_x_add_1 = w_x + 1'd1;
wire [4:0] w_x_sub_1 = w_x - 1'd1;

wire [1:0] map_up = damn_mp[w_y_sub_1][w_x      ];
wire [1:0] map_dw = damn_mp[w_y_add_1][w_x      ];
wire [1:0] map_lf = damn_mp[w_y      ][w_x_sub_1];
wire [1:0] map_rg = damn_mp[w_y      ][w_x_add_1];

// sword:   10
// wall:    01
// empty:   00
// monster: 11

// sword:   10
// wall:    00
// empty:   01
// monster: 11



wire up_wall = (w_y == 5'd0)  || (map_up == 2'd0) || (~has_sword && (map_up == 2'd3)); // re-encoding
wire dw_wall = (w_y == 5'd16) || (map_dw == 2'd0) || (~has_sword && (map_dw == 2'd3)); // re-encoding
wire lf_wall = (w_x == 5'd0)  || (map_lf == 2'd0) || (~has_sword && (map_lf == 2'd3)); // re-encoding
wire rg_wall = (w_x == 5'd16) || (map_rg == 2'd0) || (~has_sword && (map_rg == 2'd3)); // re-encoding

wire [1:0] optim_dir;
assign optim_dir = {next_dir[0], next_dir[1]};

// FSM
always @(posedge clk, negedge rst_n) begin
	if (~rst_n) state <= IDLE_INPUT;
	else        state <= next_state;
end


always @(posedge clk, negedge rst_n) begin
    if (~rst_n)                                 cool_reg <= 1'b0;
    else if (w_x == 5'd16 && out_valid == 1'b0) cool_reg <= 1'b1;
    else                                        cool_reg <= 1'b0;
end

always @(*) begin
	next_state = state;
	case(1'b1) // synopsys full_case
		~state: begin
            if (in_valid == 1'b0 && cool_reg == 1'b1) next_state = WALK;
            else next_state = IDLE_INPUT;
        end
		state: begin
			if (w_x[4] == 1'b1 && w_y[4] == 1'b1)     next_state = IDLE_INPUT;
			else                                      next_state = WALK;
		end
	endcase
end

always @(posedge clk) begin
    if (next_state == WALK) begin
        cur_dir <= next_dir;
    end
    else begin
        cur_dir <= 2'b00;
    end
end

// 0 X X

// 0 1 1
// 0 1 0
// 0 0 0
// 0 0 1

// 1 1 1
// 1 1 0
// 1 0 X

// -(~{0}), +{1}, +{1}
// first  bit: if 0 then -1 and sec, third bit mux to 0
//             if 1 then -0

// second bit: if 0 then +0 and third bit mux to 0
//             if 1 then all 
integer i, j, k, l, m, n;
always @(posedge clk) begin
    if (next_state == IDLE_INPUT && in_valid == 1'b0) begin
        for (i = 0; i < 17; i = i + 1) begin
            for (j = 0; j < 17; j = j + 1) begin
                if (!(i[0] == 1 && j[0] == 1)) begin
                    damn_mp[i][j][0] <= 2'b1;
                end
                else begin
                    damn_mp[i][j][0] <= 2'b0;
                end
            end
        end
        for (i = 0; i < 17; i = i + 1) begin
            for (j = 0; j < 17; j = j + 1) begin
                if (!(i[0] == 1 && j[0] == 1)) begin
                    damn_mp[i][j][1] <= 2'b0;
                end
                else begin
                    damn_mp[i][j][1] <= 2'b0;
                end
            end
        end
    end
    else if (next_state == IDLE_INPUT && in_valid == 1'b1) begin
        for (k = 1; k <= 15; k = k + 1) begin
            if (k[0] == 1) begin
                if ((damn_mp[k-1][0] == 2'd0) + (damn_mp[k+1][0] == 2'd0) == 2 || (damn_mp[k-1][0] == 2'd0) + (damn_mp[k+1][0] == 2'd0) == 1) begin
                    if ((damn_mp[k][0] != 2'b10)) begin
                        damn_mp[k][0][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
            else begin
                if ((damn_mp[k-1][0] == 2'd0) + (damn_mp[k+1][0] == 2'd0) + (damn_mp[k][1] == 2'd0) == 2 || (damn_mp[k-1][0] == 2'd0) + (damn_mp[k+1][0] == 2'd0) + (damn_mp[k][1] == 2'd0) == 3 ) begin
                    if ((damn_mp[k][0] != 2'b10)) begin
                        damn_mp[k][0][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
        end
        for (l = 1; l <= 15; l = l + 1) begin
            if (l[0] == 1) begin
                if ((damn_mp[0][l-1] == 2'd0) + (damn_mp[0][l+1] == 2'd0) == 2 || (damn_mp[0][l-1] == 2'd0) + (damn_mp[0][l+1] == 2'd0) == 1) begin
                    if ((damn_mp[0][l] != 2'b10)) begin
                        damn_mp[0][l][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
            else begin
                if ((damn_mp[0][l-1] == 2'd0) + (damn_mp[0][l+1] == 2'd0) + (damn_mp[1][l] == 2'd0) > 1) begin
                    if ((damn_mp[0][l] != 2'b10)) begin
                        damn_mp[0][l][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
        end
        for (m = 1; m <= 15; m = m + 1) begin
            if (m[0] == 1) begin
                if ((damn_mp[m+1][16] == 2'd0) + (damn_mp[m-1][16] == 2'd0) == 2 || (damn_mp[m+1][16] == 2'd0) + (damn_mp[m-1][16] == 2'd0) == 1) begin
                    if ((damn_mp[m][16] !== 2'b10)) begin
                        damn_mp[m][16][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
            else begin
                if ((damn_mp[m+1][16] == 2'd0) + (damn_mp[m-1][16] == 2'd0) + (damn_mp[m][15] == 2'd0) > 1) begin
                    if ((damn_mp[m][16] !== 2'b10)) begin
                        damn_mp[m][16][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
        end
        for (n = 1; n <= 15; n = n + 1) begin
            if (n[0] == 1) begin
                if ((damn_mp[16][n+1] == 2'd0) + (damn_mp[16][n-1] == 2'd0) == 2 || (damn_mp[16][n+1] == 2'd0) + (damn_mp[16][n-1] == 2'd0) == 1) begin
                    if ((damn_mp[16][n] !== 2'b10)) begin
                        damn_mp[16][n][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
            else begin
                if ((damn_mp[16][n+1] == 2'd0) + (damn_mp[16][n-1] == 2'd0) + (damn_mp[15][n] == 2'd0) > 1) begin
                    if ((damn_mp[16][n] !== 2'b10)) begin
                        damn_mp[16][n][0] <= 1'b0; // trade-off from latency to area
                    end
                end
            end
        end

        
        if ((damn_mp[15][0] == 2'd0) || (damn_mp[16][1] == 2'd0)) begin
            if ((damn_mp[16][0] !== 2'b10)) begin
                damn_mp[16][0][0] <= 1'b0; // trade-off from latency to area
            end
        end
        if ((damn_mp[0][15] == 2'd0) || (damn_mp[1][16] == 2'd0)) begin
            if ((damn_mp[0][16] !== 2'b10)) begin
                damn_mp[0][16][0] <= 1'b0; // trade-off from latency to area
            end
        end
        for (i = 1; i <= 15; i = i + 1) begin
            for (j = 1; j <= 15; j = j + 1) begin
                if (i[0] == 1 && j[0] == 0) begin
                    if ((damn_mp[i-1][j] == 2'd0) || (damn_mp[i+1][j] == 2'd0)) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0; // trade-off from latency to area
                        end
                    end 
                end
                else if (i[0] == 0 && j[0] == 0) begin
                    if ((damn_mp[i+1][j] == 2'd0) + (damn_mp[i-1][j] == 2'd0) + (damn_mp[i][j+1] == 2'd0) + (damn_mp[i][j-1] == 2'd0) == 3 || (damn_mp[i+1][j] == 2'd0) + (damn_mp[i-1][j] == 2'd0) + (damn_mp[i][j+1] == 2'd0) + (damn_mp[i][j-1] == 2'd0) == 4) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0; // trade-off from latency to area
                        end
                    end
                end
                else if (i[0] == 0 && j[0] == 1) begin
                    if ((damn_mp[i][j-1] == 2'd0) || (damn_mp[i][j+1] == 2'd0)) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0; // trade-off from latency to area
                        end
                    end
                end
            end
        end
		damn_mp[w_y][w_x] <= {in[1], ~(in[0] ^ in[1])};
        for (i = 0; i < 17; i = i + 1) begin
            for (j = 0; j < 17; j = j + 1) begin
                if ((i[0] == 1 && j[0] == 1)) begin
                    damn_mp[i][j] <= 2'b00; // reset to road
                end
            end
        end
    end
    else begin
        for (i = 0; i < 17; i = i + 1) begin
            for (j = 0; j < 17; j = j + 1) begin
                if ((i[0] == 1 && j[0] == 1)) begin
                    if (damn_mp[i][j] != 2'b01) begin
                        damn_mp[i][j] <= 2'b00; // reset to road
                    end
                end
            end
        end
        
        for (i = 1; i <= 15; i = i + 1) begin
            for (j = 1; j <= 15; j = j + 1) begin
                if (i[0] == 1 && j[0] == 0) begin
                    if ((damn_mp[i-1][j] == 2'd0) || (damn_mp[i+1][j] == 2'd0)) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0;
                        end
                    end 
                end
                else if (i[0] == 0 && j[0] == 0) begin
                    if ((damn_mp[i+1][j] == 2'd0) + (damn_mp[i-1][j] == 2'd0) + (damn_mp[i][j+1] == 2'd0) + (damn_mp[i][j-1] == 2'd0) == 3 || (damn_mp[i+1][j] == 2'd0) + (damn_mp[i-1][j] == 2'd0) + (damn_mp[i][j+1] == 2'd0) + (damn_mp[i][j-1] == 2'd0) == 4) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0;
                        end
                    end
                end
                else if (i[0] == 0 && j[0] == 1) begin
                    if ((damn_mp[i][j-1] == 2'd0) || (damn_mp[i][j+1] == 2'd0)) begin
                        if ((damn_mp[i][j] != 2'b10)) begin
                            damn_mp[i][j][0] <= 1'b0;
                        end
                    end
                end
            end
        end
    end
end

always @(*) begin
    case (cur_dir)
        2'd0: begin
            if      (!up_wall) next_dir = 2'd3; // up
            else if (!rg_wall) next_dir = 2'd0; // rg
            else if (!dw_wall) next_dir = 2'd1; // dw
            else               next_dir = 2'd2; // lf
        end
        2'd1: begin
            if      (!rg_wall) next_dir = 2'd0; // rg
            else if (!dw_wall) next_dir = 2'd1; // dw
            else if (!lf_wall) next_dir = 2'd2; // lf
            else               next_dir = 2'd3; // up
        end
        2'd2: begin
            if      (!dw_wall) next_dir = 2'd1; // dw
            else if (!lf_wall) next_dir = 2'd2; // lf
            else if (!up_wall) next_dir = 2'd3; // up
            else               next_dir = 2'd0; // rg
        end
        default: begin
            if      (!lf_wall) next_dir = 2'd2; // lf
            else if (!up_wall) next_dir = 2'd3; // up
            else if (!rg_wall) next_dir = 2'd0; // rg
            else               next_dir = 2'd1; // dw
        end
    endcase
end

always @(posedge clk) begin
    if (next_state == IDLE_INPUT) begin
        if (damn_mp[0][0] == 2'b10) has_sword <= 1'b1;
        else has_sword <= 1'b0;
    end
    else if (next_state == WALK) begin
        case (next_dir) // synopsys parallel_case
            2'd0: begin
                if (map_rg == 2'b10) has_sword <= 1'b1;
            end
            2'd1: begin
                if (map_dw == 2'b10) has_sword <= 1'b1;
            end
            2'd2: begin
                if (map_lf == 2'b10) has_sword <= 1'b1;
            end
            default: begin
                if (map_up == 2'b10) has_sword <= 1'b1;
            end
        endcase
    end
end

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) begin
		out <= 2'd0;
	end
	else begin
		if (next_state == WALK) begin
			out <= next_dir;
		end
		else begin
			out <= 2'd0;
		end 
	end
end


always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        w_x <= 5'd0;
        w_y <= 5'd0;
    end
    else begin
	    if (next_state == IDLE_INPUT && in_valid == 1'b0) begin
	    	w_x <= 5'd0;
	    	w_y <= 5'd0;
	    end
	    else if (next_state == IDLE_INPUT && in_valid == 1'b1) begin
	    	if      (w_x[4] == 1'd1)                 w_x <= 5'd0;
	    	else                                     w_x <= w_x_add_1;

	    	if      (w_y == 5'd16 && w_x[4] == 1'd1) w_y <= 5'd0;
	    	else if (w_x[4] == 1'd1)                 w_y <= w_y_add_1;
	    end
        else begin
            case (next_dir) // 
                2'd0: begin
                    w_x <= w_x_add_1;
                end
                2'd1: begin
                    w_y <= w_y_add_1;
                end
                2'd2: begin
                    w_x <= w_x_sub_1;
                end
                default: begin
                    w_y <= w_y_sub_1;
                end
            endcase
        end
    end
end




endmodule