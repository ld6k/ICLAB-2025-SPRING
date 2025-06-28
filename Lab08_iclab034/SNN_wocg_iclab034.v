module SNN(
	// Input signals
	input            clk,
	input            rst_n,
	input            in_valid,
	input [7:0]      img,
	input [7:0]      ker,
	input [7:0]      weight,
	// Output signals
	output reg       out_valid,
	output reg [9:0] out_data
);

// ============================================== //
//        parameter & integer declaration         //
// ============================================== //
integer i, j, k;

// ============================================== //
//            reg & wire declaration              //
// ============================================== //

// ----------- Input signals and CONV --------- //
reg [2:0] input_img_row;
reg [2:0] input_img_col;
reg [7:0] input_img_reg  [0:2][0:5];
reg [7:0] ker_reg        [0:2][0:2];
reg [7:0] ker_reg_mux    [0:2][0:2];
reg [7:0] weight_reg     [0:1][0:1];
reg       doin_0_or_1;
reg [1:0] input_lut;
reg [7:0] input_conv_img [0:2][0:2];

// ---------- Output signals and CONV --------- //
wire [19:0] conv_out;
reg         conv_valid;
wire        conv_out_valid;

reg [19:0] conv_out_reg;
reg [19:0] conv_out_reg_mux;
reg        conv_out_valid_reg;
// --------- Quantization and output --------- //
reg  [1:0] max_pool_cnt;
reg  [7:0] max_pool [0:1];
wire [7:0] quant_out;// = conv_out_reg / 'd2295;

// --------- MAX POOLING --------- //
reg        max_pool_row;
reg        max_pool_valid;
reg [7:0] ker_mux;
reg [7:0] img_mux;

// --------- encode and rest --------- //
reg        encode_up_or_down;
reg [16:0] fc_res [0:1];
wire [7:0] encode_res_quant_0;// = fc_res[0] / 'd510;
wire [7:0] encode_res_quant_1;// = fc_res[1] / 'd510;
reg [7:0] encode_res_four [0:3];
reg [7:0] encode_res_four_mux [0:3];

wire [9:0] before_relu;// = encode_res_four[0] + encode_res_four[1] + encode_res_four[2] + encode_res_four[3];
reg encode_valid;
reg delay_in_val, delay_in_val1;
quant_2295 u_quant_2295(
	.conv_out(conv_out_reg),
	.quant_out(quant_out)
);

final_add_four u_final_add_four(
	.encode_res_four({encode_res_four[0], encode_res_four[1], encode_res_four[2], encode_res_four[3]}),
	.before_relu(before_relu)
);

// ============================================== //
//                   design                       //
// ============================================== //

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		out_valid <= 0;
		delay_in_val <= 0;
		delay_in_val1 <= 0;
	end 
	else begin
		delay_in_val <= in_valid;
		delay_in_val1 <= delay_in_val;
		out_valid <= delay_in_val1 && !delay_in_val;
	end
end


always @(*) begin
	out_data = 0;
	if (out_valid) begin
		if (before_relu >= 16) begin
			out_data = before_relu;
		end
	end
end

// always @(*) begin
// 	encode_res_four_mux[0] = 0;
// 	encode_res_four_mux[1] = 0;
// 	encode_res_four_mux[2] = 0;
// 	encode_res_four_mux[3] = 0;
// 	if (out_valid) begin
// 		encode_res_four_mux[0] = encode_res_four[0];
// 		encode_res_four_mux[1] = encode_res_four[1];
// 		encode_res_four_mux[2] = encode_res_four[2];
// 		encode_res_four_mux[3] = encode_res_four[3];
// 	end
// end


always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		doin_0_or_1 <= 0;
	end
	else begin
		if (!doin_0_or_1 && input_img_col == 5 && input_img_row == 3) begin
			doin_0_or_1 <= 1;
		end
		else if (out_valid) begin
			doin_0_or_1 <= 0;
		end
	end
end

always @(*) begin
	if      (input_img_row == 6 || input_img_row == 1) begin
		input_lut = 0;
	end
	else if (input_img_row == 7 || input_img_row == 2) begin
		input_lut = 1;
	end
	else if (input_img_row == 0 || input_img_row == 3) begin
		input_lut = 2;
	end
	else begin
		input_lut = 3;
	end
end

always @(*) begin
	if (in_valid) ker_mux = ker;
	else ker_mux = 0;
end

wire img_clk [0:5];
wire img_cg_en [0:5];// = !(input_img_col == 0);
assign img_cg_en[0] = !(input_img_col == 0);
assign img_cg_en[1] = !(input_img_col == 1);
assign img_cg_en[2] = !(input_img_col == 2);
assign img_cg_en[3] = !(input_img_col == 3);
assign img_cg_en[4] = !(input_img_col == 4);
assign img_cg_en[5] = !(input_img_col == 5);



always @(*) begin
	if (in_valid) img_mux = img;
	else img_mux = 0;
end

always @(posedge clk) begin
	if (input_img_col == 0) begin
		input_img_reg[input_lut][0] <= img;
	end
end

always @(posedge clk) begin
	if (input_img_col == 1) begin
		input_img_reg[input_lut][1] <= img;
	end
end

always @(posedge clk) begin
	if (input_img_col == 2) begin
		input_img_reg[input_lut][2] <= img;
	end
end

always @(posedge clk) begin
	if (input_img_col == 3) begin
		input_img_reg[input_lut][3] <= img;
	end
end

always @(posedge clk) begin
	if (input_img_col == 4) begin
		input_img_reg[input_lut][4] <= img;
	end
end

always @(posedge clk) begin
	if (input_img_col == 5) begin
		input_img_reg[input_lut][5] <= img;
	end
end



wire fuck_kernel_clk_6;
wire cond_kernel_clk_6 = !(!doin_0_or_1 && input_img_row == 6);

always @(posedge clk) begin
	if (!doin_0_or_1) begin
		if (input_img_row == 6 && input_img_col == 0) begin
			ker_reg[0][0] <= ker;
		end
		if (input_img_row == 6 && input_img_col == 1) begin
			ker_reg[0][1] <= ker;
		end
		if (input_img_row == 6 && input_img_col == 2) begin
			ker_reg[0][2] <= ker;
		end
		if (input_img_row == 6 && input_img_col == 3) begin
			ker_reg[1][0] <= ker;
		end
		if (input_img_row == 6 && input_img_col == 4) begin
			ker_reg[1][1] <= ker;
		end
		if (input_img_row == 6 && input_img_col == 5) begin
			ker_reg[1][2] <= ker;
		end
	end
end


always @(posedge clk) begin
	if (!doin_0_or_1) begin
		if (input_img_row == 7 && input_img_col == 0) begin
			ker_reg[2][0] <= ker;
		end
		if (input_img_row == 7 && input_img_col == 1) begin
			ker_reg[2][1] <= ker;
		end
		if (input_img_row == 7 && input_img_col == 2) begin
			ker_reg[2][2] <= ker;
		end
	end
end


always @(posedge clk) begin
	if (!doin_0_or_1 && input_img_row == 6) begin
		if (input_img_col == 0) begin
			weight_reg[0][0] <= weight;
		end
		if (input_img_col == 1) begin
			weight_reg[0][1] <= weight;
		end
	end
end

always @(posedge clk) begin
	if (!doin_0_or_1 && input_img_row == 6) begin
		if (input_img_col == 2) begin
			weight_reg[1][0] <= weight;
		end
		if (input_img_col == 3) begin
			weight_reg[1][1] <= weight;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		input_img_col <= 0;
	end
	else begin
		if (in_valid) begin
			if (input_img_col == 5) begin
				input_img_col <= 0;
			end
			else begin
				input_img_col <= input_img_col + 1;
			end
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		input_img_row <= 6;
	end
	else begin
		if (input_img_col == 5) begin
			if (input_img_row == 3) begin
				input_img_row <= 6;
			end
			else begin
				input_img_row <= input_img_row + 1;
			end
		end
	end
end



always @(*) begin
	if (input_img_row[1:0] == 1) begin
		input_conv_img[0][0] = input_img_reg[1][input_img_col-2];
		input_conv_img[0][1] = input_img_reg[1][input_img_col-1];
		input_conv_img[0][2] = input_img_reg[1][input_img_col  ];

		input_conv_img[1][0] = input_img_reg[2][input_img_col-2];
		input_conv_img[1][1] = input_img_reg[2][input_img_col-1];
		input_conv_img[1][2] = input_img_reg[2][input_img_col  ];

		input_conv_img[2][0] = input_img_reg[0][input_img_col-2];
		input_conv_img[2][1] = input_img_reg[0][input_img_col-1];
		input_conv_img[2][2] = img;
	end
	else if (input_img_row[1:0] == 2) begin
		input_conv_img[0][0] = input_img_reg[2][input_img_col-2];
		input_conv_img[0][1] = input_img_reg[2][input_img_col-1];
		input_conv_img[0][2] = input_img_reg[2][input_img_col  ];

		input_conv_img[1][0] = input_img_reg[0][input_img_col-2];
		input_conv_img[1][1] = input_img_reg[0][input_img_col-1];
		input_conv_img[1][2] = input_img_reg[0][input_img_col  ];
		
		input_conv_img[2][0] = input_img_reg[1][input_img_col-2];
		input_conv_img[2][1] = input_img_reg[1][input_img_col-1];
		input_conv_img[2][2] = img;
	end
	else begin
		input_conv_img[0][0] = input_img_reg[0][input_img_col-2];
		input_conv_img[0][1] = input_img_reg[0][input_img_col-1];
		input_conv_img[0][2] = input_img_reg[0][input_img_col  ];

		input_conv_img[1][0] = input_img_reg[1][input_img_col-2];
		input_conv_img[1][1] = input_img_reg[1][input_img_col-1];
		input_conv_img[1][2] = input_img_reg[1][input_img_col  ];
		
		input_conv_img[2][0] = input_img_reg[2][input_img_col-2];
		input_conv_img[2][1] = input_img_reg[2][input_img_col-1];
		input_conv_img[2][2] = img;
	end
end

always @(*) begin
		ker_reg_mux[0][0] = ker_reg[0][0];
		ker_reg_mux[0][1] = ker_reg[0][1];
		ker_reg_mux[0][2] = ker_reg[0][2];

		ker_reg_mux[1][0] = ker_reg[1][0];
		ker_reg_mux[1][1] = ker_reg[1][1];
		ker_reg_mux[1][2] = ker_reg[1][2];
		
		ker_reg_mux[2][0] = ker_reg[2][0];
		ker_reg_mux[2][1] = ker_reg[2][1];
		ker_reg_mux[2][2] = ker_reg[2][2];
end

always @(*) begin
	conv_valid = 0;
	if (input_img_row == 0 || input_img_row == 1 || input_img_row == 2 || input_img_row == 3) begin
		if (input_img_col == 2 || input_img_col == 3 || input_img_col == 4 || input_img_col == 5) begin
			conv_valid = 1;
		end
	end
end

// parameter GARBAGE_CNT = 48;
// parameter G_HALF = GARBAGE_CNT / 2;
// reg [GARBAGE_CNT-1:0] dummy;
// wire fuck_dummy_clk;
// wire cond_dummy_clk = cg_en && !(|dummy[(GARBAGE_CNT-1)-:4]);
// GATED_OR GATED_dummy (
// 	.CLOCK(clk),
// 	.SLEEP_CTRL(cond_dummy_clk),
// 	.RST_N(rst_n),
// 	.CLOCK_GATED(fuck_dummy_clk)
// );

// always @(posedge fuck_dummy_clk, negedge rst_n) begin
// 	if (!rst_n) begin
// 		dummy <= {G_HALF{2'b10}};
// 	end
// 	else begin
// 		if (cg_en) begin
// 			dummy <= 0;
// 		end
// 		else begin
// 			if ((!delay_in_val1 && delay_in_val)) begin
// 				dummy <= {G_HALF{2'b10}};
// 			end
// 			else begin
// 				dummy <= {dummy[GARBAGE_CNT-2:0], dummy[GARBAGE_CNT-1]};
// 			end
// 		end
// 	end
// end

// reg [GARBAGE_CNT-1:0] dummy_1;
// wire fuck_dummy_clk_1;
// wire cond_dummy_clk_1 = cg_en && !(|dummy_1[(GARBAGE_CNT-1)-:4]);
// GATED_OR GATED_dummy_1 (
// 	.CLOCK(clk),
// 	.SLEEP_CTRL(cond_dummy_clk_1),
// 	.RST_N(rst_n),
// 	.CLOCK_GATED(fuck_dummy_clk_1)
// );

// always @(posedge fuck_dummy_clk_1, negedge rst_n) begin
// 	if (!rst_n) begin
// 		dummy_1 <= {G_HALF{2'b10}};
// 	end
// 	else begin
// 		if (cg_en) begin
// 			dummy_1 <= 0;
// 		end
// 		else begin
// 			if ((!delay_in_val1 && delay_in_val)) begin
// 				dummy_1 <= {G_HALF{2'b10}};
// 			end
// 			else begin
// 				dummy_1 <= {dummy_1[GARBAGE_CNT-2:0], dummy_1[GARBAGE_CNT-1]};
// 			end
// 		end
// 	end
// end


// reg [47:0] dummy;
// wire fuck_dummy_clk;
// wire cond_dummy_clk = cg_en && !(|dummy);
// GATED_OR GATED_dummy (
// 	.CLOCK(clk),
// 	.SLEEP_CTRL(cond_dummy_clk),
// 	.RST_N(rst_n),
// 	.CLOCK_GATED(fuck_dummy_clk)
// );

// always @(posedge fuck_dummy_clk, negedge rst_n) begin
// 	if (!rst_n) begin
// 		dummy <= 0;
// 	end
// 	else begin
// 		if (cg_en)         dummy <= 0;
// 		else if (img == 0) dummy <= {8'b1010_0101, dummy[47:8]};
// 		else               dummy <= {img,          dummy[47:8]};
// 	end
// end

// reg [47:0] dummy_1;
// wire fuck_dummy_1_clk;
// wire cond_dummy_1_clk = cg_en && !(|dummy_1);
// GATED_OR GATED_dummy_1 (
// 	.CLOCK(clk),
// 	.SLEEP_CTRL(cond_dummy_1_clk),
// 	.RST_N(rst_n),
// 	.CLOCK_GATED(fuck_dummy_1_clk)
// );

// always @(posedge fuck_dummy_1_clk, negedge rst_n) begin
// 	if (!rst_n) begin
// 		dummy_1 <= 0;
// 	end
// 	else begin
// 		if (cg_en)         dummy_1 <= 0;
// 		else if (img == 0) dummy_1 <= {8'b1110_1001, dummy_1[47:8]};
// 		else               dummy_1 <= {~img,          dummy_1[47:8]};
// 	end
// end

// reg [31:0] dummy_2;
// wire fuck_dummy_2_clk;
// wire cond_dummy_2_clk = cg_en && !(|dummy_2);
// GATED_OR GATED_dummy_2 (
// 	.CLOCK(clk),
// 	.SLEEP_CTRL(cond_dummy_2_clk),
// 	.RST_N(rst_n),
// 	.CLOCK_GATED(fuck_dummy_2_clk)
// );

// always @(posedge fuck_dummy_2_clk, negedge rst_n) begin
// 	if (!rst_n) begin
// 		dummy_2 <= 0;
// 	end
// 	else begin
// 		if (img == 0) dummy_2 <= {8'b1010_0001, dummy_2[31:8]};
// 		else          dummy_2 <= {img,          dummy_2[31:8]};
// 	end
// end


cool_conv u_cool_conv(
	.in_valid  (conv_valid),
	.ker       ({ker_reg_mux[0][0], ker_reg_mux[0][1], ker_reg_mux[0][2], ker_reg_mux[1][0], ker_reg_mux[1][1], ker_reg_mux[1][2], ker_reg_mux[2][0], ker_reg_mux[2][1], ker_reg_mux[2][2]}), 
	.img       ({input_conv_img[0][0], input_conv_img[0][1], input_conv_img[0][2], input_conv_img[1][0], input_conv_img[1][1], input_conv_img[1][2], input_conv_img[2][0], input_conv_img[2][1], input_conv_img[2][2]}), 
	.out_valid (conv_out_valid),
	.out_data  (conv_out)
);
always @(posedge clk) begin
	if (out_valid) begin
		conv_out_reg <= 0;
	end
	else begin
		conv_out_reg <= conv_out;
	end
end

always @(*) begin
	if (conv_out_valid_reg) begin
		conv_out_reg_mux = conv_out_reg;
	end
	else begin
		conv_out_reg_mux = 0;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		max_pool_cnt <= 0;
	end
	else begin
		if (conv_out_valid_reg) begin
			max_pool_cnt <= max_pool_cnt + 1;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		conv_out_valid_reg <= 0;
	end
	else begin
		conv_out_valid_reg <= conv_out_valid;
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		max_pool_row <= 0;
	end
	else begin
		if (max_pool_cnt == 3) begin
			max_pool_row <= max_pool_row + 1;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		max_pool[0] <= 0;
		max_pool[1] <= 0;
	end
	else begin
		if (conv_out_valid_reg) begin
			if (!max_pool_cnt[1]) begin
				if (max_pool[0] < quant_out) begin
					max_pool[0] <= quant_out;
				end
			end
			else begin
				if (max_pool[1] < quant_out) begin
					max_pool[1] <= quant_out;
				end
			end
		end
		else if (max_pool_cnt == 0 && !max_pool_row) begin
			max_pool[0] <= 0;
			max_pool[1] <= 0;
		end
	end
end

always @(*) begin
	max_pool_valid = 0;
	if (max_pool_row && max_pool_cnt == 3) begin
		max_pool_valid = 1;
	end
end

reg [7:0] max_pool_mux [0:1];
reg [7:0] weight_reg_mux [0:1][0:1];
always @(*) begin
	if (encode_valid) begin
		max_pool_mux[0] = max_pool[0];
		max_pool_mux[1] = max_pool[1];
		weight_reg_mux[0][0] = weight_reg[0][0];
		weight_reg_mux[0][1] = weight_reg[0][1];
		weight_reg_mux[1][0] = weight_reg[1][0];
		weight_reg_mux[1][1] = weight_reg[1][1];
	end
	else begin
		max_pool_mux[0] = 0;
		max_pool_mux[1] = 0;
		weight_reg_mux[0][0] = 0;
		weight_reg_mux[0][1] = 0;
		weight_reg_mux[1][0] = 0;
		weight_reg_mux[1][1] = 0;
	end
end


wire [7:0] abb[0:1];
fc u_fc(
	.max_pool  ({max_pool_mux[0], max_pool_mux[1]}),
	.weight_reg({weight_reg_mux[0][0], weight_reg_mux[0][1], weight_reg_mux[1][0], weight_reg_mux[1][1]}),
	.fc_res_quant    ({abb[0], abb[1]})
);

assign encode_res_quant_0 = abb[0];
assign encode_res_quant_1 = abb[1];
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		encode_up_or_down <= 0;
	end
	else begin
		if (max_pool_valid) begin
			encode_up_or_down <= encode_up_or_down + 1;
		end
	end
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		encode_valid <= 0;
	end
	else begin
		encode_valid <= max_pool_valid;
	end
end

always @(posedge clk) begin
		if (encode_valid) begin
			if (encode_up_or_down == 1) begin
				encode_res_four[0] <= (encode_res_four[0] > encode_res_quant_0) ? encode_res_four[0] - encode_res_quant_0 : encode_res_quant_0 - encode_res_four[0];
				encode_res_four[1] <= (encode_res_four[1] > encode_res_quant_1) ? encode_res_four[1] - encode_res_quant_1 : encode_res_quant_1 - encode_res_four[1];
			end
			else if (encode_up_or_down == 0) begin
				encode_res_four[2] <= (encode_res_four[2] > encode_res_quant_0) ? encode_res_four[2] - encode_res_quant_0 : encode_res_quant_0 - encode_res_four[2];
				encode_res_four[3] <= (encode_res_four[3] > encode_res_quant_1) ? encode_res_four[3] - encode_res_quant_1 : encode_res_quant_1 - encode_res_four[3];
			end
		end
		else if (!delay_in_val1 && delay_in_val) begin
			encode_res_four[0] <= 0;
			encode_res_four[1] <= 0;
			encode_res_four[2] <= 0;
			encode_res_four[3] <= 0;
		end
end


endmodule




// 	fc_res_quant[0] = fc_res[0] / 'd510;
// 	fc_res_quant[1] = fc_res[1] / 'd510;
// end

// endmodule

module quant_2295(
	input  [19:0] conv_out,
	output reg [7:0] quant_out
);

always @(*) begin
	quant_out = conv_out / 'd2295;
end

endmodule

// module final_add_four(
// 	input [7:0] encode_res_four [0:3],
// 	output reg [9:0] before_relu
// );

// always @(*) begin
// 	before_relu = encode_res_four[0] + encode_res_four[1] + encode_res_four[2] + encode_res_four[3];
// end

// endmodule

// Flattened I/O versions of the three modules

// final_add_four: encode_res_four[0:3] (4×8 bits) → flat 32-bit input
module final_add_four(
    input  [31:0] encode_res_four,  // {e0,e1,e2,e3}
    output reg [9:0]  before_relu
);

wire [7:0] e[0:3];
// unpack flat vector: e[0]=bits[31:24], e[1]=[23:16], … e[3]=[7:0]
genvar i;
generate
  for (i = 0; i < 4; i = i + 1) begin : UNPACK
    assign e[i] = encode_res_four[8*(3-i) +: 8];
  end
endgenerate

always @(*) begin
    before_relu = e[0] + e[1] + e[2] + e[3];
end

endmodule


// fc: max_pool[0:1] (2×8) → 16-bit flat; weight_reg[0:1][0:1] (2×2×8) → 32-bit flat; fc_res_quant[0:1] → 16-bit flat
module fc(
    input  [15:0] max_pool,    // {mp0, mp1}
    input  [31:0] weight_reg,  // {w00,w01,w10,w11}
    output reg [15:0] fc_res_quant // {q0, q1}
);

wire [7:0] mp[0:1];
wire [7:0] w [0:1][0:1];

// unpack max_pool
assign mp[0] = max_pool[15:8];
assign mp[1] = max_pool[ 7:0];

// unpack weight_reg (row-major: w[0][0]=[31:24], w[0][1]=[23:16], w[1][0]=[15:8], w[1][1]=[7:0])
assign w[0][0] = weight_reg[31:24];
assign w[0][1] = weight_reg[23:16];
assign w[1][0] = weight_reg[15: 8];
assign w[1][1] = weight_reg[ 7: 0];

reg [16:0] fc_res[0:1];

always @(*) begin
    fc_res[0] = mp[0] * w[0][0] + mp[1] * w[1][0];
    fc_res[1] = mp[0] * w[0][1] + mp[1] * w[1][1];
    // quantize and pack output
    fc_res_quant[15:8] = (fc_res[0] / 'd510);
	fc_res_quant[7:0]  = (fc_res[1] / 'd510);
end

endmodule


// cool_conv: ker[0:2][0:2] & img[0:2][0:2] → each 9×8=72 bits flat
module cool_conv(
    input            in_valid,
    input  [71:0]    ker,   // {ker00,ker01,...,ker22}
    input  [71:0]    img,   // same layout
    output           out_valid,
    output reg [19:0] out_data
);

wire [7:0] ker_[0:2][0:2];
wire [7:0] img_[0:2][0:2];

// unpack 3×3 arrays (row-major: index = r*3+c)
generate
  genvar r, c;
  for (r = 0; r < 3; r = r + 1) begin: UPK_ROW
    for (c = 0; c < 3; c = c + 1) begin: UPK_COL
      localparam idx = r*3 + c;
      // element = bits[(9-idx)*8-1 -: 8]
      assign ker_[r][c] = ker[(9-idx)*8-1 -: 8];
      assign img_[r][c] = img[(9-idx)*8-1 -: 8];
    end
  end
endgenerate

always @(*) begin
    out_data = 
        (ker_[0][0]*img_[0][0]) + (ker_[0][1]*img_[0][1]) + (ker_[0][2]*img_[0][2]) +
        (ker_[1][0]*img_[1][0]) + (ker_[1][1]*img_[1][1]) + (ker_[1][2]*img_[1][2]) +
        (ker_[2][0]*img_[2][0]) + (ker_[2][1]*img_[2][1]) + (ker_[2][2]*img_[2][2]);
end
assign out_valid = in_valid;

endmodule
