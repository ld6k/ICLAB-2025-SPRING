//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025
//		Version		: v1.0
//   	File Name   : BCH_TOP.v
//   	Module Name : BCH_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "Division_IP.v"

module BCH_TOP(
    // Input signals
    input            clk,
	input            rst_n,
	input            in_valid,
    input [3:0]      in_syndrome, 
    // Output signals
    output           out_valid, 
	output reg [3:0] out_location
);

    integer i, j, k;
    // ===============================================================
    // Reg & Wire Declaration
    // ===============================================================
    localparam S_IDLE = 0;
    localparam S_OUPU = 1;
    reg  state;
    reg  next_state;
    reg [3:0] in_syndrome_reg [0:5];
    reg [2:0] input_cnt;
    reg [1:0] output_cnt;

    wire [3:0] sp7_q_o [0:6];
    wire [3:0] sp7_r_o [0:6];
    wire [3:0] debug_div_7_r [0:4];
    wire [3:0] debug_div_7_q [0:2];

    wire [3:0] div_6_q_o [0:5];
    wire [3:0] div_6_r_o [0:5];
    
    reg [3:0] three_ans [0:2];


    reg  [3:0] er_func    [0:3];
    reg [3:0] er_func_reg [0:3];
    wire final_hit [0:14];
    wire [3:0] two_div [0:1];


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (input_cnt == 'd6) begin
                    next_state = S_OUPU;
                end
            end
            S_OUPU: begin
                if (output_cnt == 'd2) begin
                    next_state = S_IDLE;
                end
            end
        endcase
    end
    assign out_valid = state;

    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         out_location <= 4'd0;
    //     end else begin
    //         if (next_state == S_OUPU) begin
    //             out_location <= three_ans[output_cnt];
    //         end else begin
    //             out_location <= 4'd0;
    //         end
    //     end
    // end

    always @(*) begin
        if (state == S_OUPU) begin
            out_location = three_ans[output_cnt];
        end
        else begin
            out_location = 4'd0;
        end
    end

    always @(*) begin
        three_ans[0] = 4'd15;
        three_ans[1] = 4'd15;
        three_ans[2] = 4'd15;
        for (i = 0; i < 15; i = i + 1) begin
            if (final_hit[i]) begin
                if      (three_ans[0] == 4'd15) three_ans[0] = i[3:0];
                else if (three_ans[1] == 4'd15) three_ans[1] = i[3:0];
                else if (three_ans[2] == 4'd15) three_ans[2] = i[3:0];
            end
        end
    end

    // reg [2:0] cool_cnt;
    // always @(posedge clk, negedge rst_n) begin
    //     if (!rst_n) begin
    //         cool_cnt <= 3'd1;
    //     end else begin
    //         if (next_state == S_OUPU) begin
    //             cool_cnt <= cool_cnt + 1;
    //         end
    //         else if (state == S_IDLE) begin
    //             if (in_valid) begin
    //                 cool_cnt <= cool_cnt + 1;
    //             end
    //             else begin
    //                 cool_cnt <= 3'd1;
    //             end
    //         end
    //     end
    // end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            input_cnt <= 3'd0;
        end else begin
            if (in_valid) begin
                input_cnt <= input_cnt + 1;
            end
            else begin
                input_cnt <= 3'd0;
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            output_cnt <= 3'd0;
        end else begin
            if (state == S_OUPU) begin
                output_cnt <= output_cnt + 1;
            end
            else begin
                output_cnt <= 3'd0;
            end
        end
    end

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 6; i = i + 1) begin
                in_syndrome_reg[i] <= 4'd0;
            end
        end
        else begin
            if (in_valid) begin
                in_syndrome_reg[input_cnt] <= in_syndrome;
            end
        end
    end

   

    reg [3:0] div_7_r [0:6];
    reg [3:0] div_7_q [0:6];
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 7; i = i + 1) begin
                div_7_q[i] <= 4'd0;
                div_7_r[i] <= 4'd0;
            end
        end
        else begin
            if (input_cnt == 'd5) begin
                for (i = 0; i < 3; i = i + 1) begin
                    div_7_q[i] <= debug_div_7_q[i];
                end
                for (i = 0; i < 5; i = i + 1) begin
                    div_7_r[i] <= debug_div_7_r[i];
                end
            end
        end
    end

    wire [3:0] p_ma_0_final [0:3];
    logic [3:0] p_ma_1_final [0:3];
    wire [3:0] p_ma_2_final [0:3];

    wire [3:0] p_m_2_a_1 [0:3];
    wire [3:0] p_m_2_a_2 [0:3];


    wire [3:0] div_3_q_o [0:2];

    // real_d_ip_sp_7 #(.IP_WIDTH(7)) sp7 (
    //     .IN_Dividend   ({4'd0, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15, 4'd15}),
    //     .IN_Divisor    ({4'd15, in_syndrome, in_syndrome_reg[4], in_syndrome_reg[3], in_syndrome_reg[2], in_syndrome_reg[1], in_syndrome_reg[0]}),
    //     .OUT_Remainder ({sp7_r_o[6], sp7_r_o[5], sp7_r_o[4], sp7_r_o[3], sp7_r_o[2], sp7_r_o[1], sp7_r_o[0]}),
    //     .OUT_Quotient  ({sp7_q_o[6], sp7_q_o[5], sp7_q_o[4], sp7_q_o[3], sp7_q_o[2], sp7_q_o[1], sp7_q_o[0]})
    // );
    new_7 n7 (
        .IN_Divisor    ({in_syndrome, in_syndrome_reg[4], in_syndrome_reg[3], in_syndrome_reg[2], in_syndrome_reg[1], in_syndrome_reg[0]}),
        .OUT_Quotient  ({debug_div_7_q[2], debug_div_7_q[1], debug_div_7_q[0]}),
        .OUT_Remainder ({debug_div_7_r[4], debug_div_7_r[3], debug_div_7_r[2], debug_div_7_r[1], debug_div_7_r[0]})
    );

    real_d_ip #(.IP_WIDTH(6)) div6 (
        .IN_Dividend   ({in_syndrome_reg[5], in_syndrome_reg[4], in_syndrome_reg[3], in_syndrome_reg[2], in_syndrome_reg[1], in_syndrome_reg[0]}),
        .IN_Divisor    ({4'd15, div_7_r[4], div_7_r[3], div_7_r[2], div_7_r[1], div_7_r[0]}),
        .OUT_Remainder ({div_6_r_o[5], div_6_r_o[4], div_6_r_o[3], div_6_r_o[2], div_6_r_o[1], div_6_r_o[0]}),
        .OUT_Quotient  ({div_6_q_o[5], div_6_q_o[4], div_6_q_o[3], div_6_q_o[2], div_6_q_o[1], div_6_q_o[0]})
    );

    // GF2_4_Poly_Mult_Reduce #(.N(4), .M(4)) poly_mult_0 (
    //     .A   ({4'd15, div_7_q[2], div_7_q[1], div_7_q[0]}),
    //     .B   ({4'd15, 4'd15, 4'd15, 4'd0}),
    //     .P   ({p_ma_0_final[3], p_ma_0_final[2], p_ma_0_final[1], p_ma_0_final[0]})
    // );

    assign p_ma_0_final[2] = div_7_q[2];
    assign p_ma_0_final[1] = div_7_q[1];
    assign p_ma_0_final[0] = div_7_q[0];
    

    Division_IP #(.IP_WIDTH(3)) div3 (
        .IN_Dividend   ({div_7_r[4],   div_7_r[3],   div_7_r[2]}),
        .IN_Divisor    ({div_6_r_o[4], div_6_r_o[3], div_6_r_o[2]}),
        .OUT_Quotient  ({div_3_q_o[2], div_3_q_o[1], div_3_q_o[0]})
    );

    GF2_4_Poly_Mult_Reduce_custom #(.N(2), .M(3), .O(4)) poly_mult_0_custom (
        .A   ({p_ma_0_final[1], p_ma_0_final[0]}),
        .B   ({div_6_q_o[2], div_6_q_o[1], div_6_q_o[0]}),
        .P   ({p_m_2_a_1[3], p_m_2_a_1[2], p_m_2_a_1[1], p_m_2_a_1[0]})
    );

    // GF2_4_Poly_Mult_Reduce #(.N(4), .M(4)) poly_mult_1 (
    //     .A   ({p_ma_0_final[3], p_ma_0_final[2], p_ma_0_final[1], p_ma_0_final[0]}),
    //     .B   ({div_6_q_o[3], div_6_q_o[2], div_6_q_o[1], div_6_q_o[0]}),
    //     .P   ({p_m_2_a_1[3], p_m_2_a_1[2], p_m_2_a_1[1], p_m_2_a_1[0]})
    // );

    // GF2_4_Poly_Add #(.POLY_WIDTH(4)) poly_add_1 (
    //     .A   ({p_m_2_a_1[3], p_m_2_a_1[2], p_m_2_a_1[1], p_m_2_a_1[0]}),
    //     .B   ({4'd15, 4'd15, 4'd15, 4'd0}),
    //     .Sum ({p_ma_1_final[3], p_ma_1_final[2], p_ma_1_final[1], p_ma_1_final[0]})
    // );

    assign p_ma_1_final[3] = p_m_2_a_1[3];
    assign p_ma_1_final[2] = p_m_2_a_1[2];
    assign p_ma_1_final[1] = p_m_2_a_1[1];
    always @(*) begin
        case (p_m_2_a_1[0])
            4'd0:  p_ma_1_final[0] = 4'd15;
            4'd1:  p_ma_1_final[0] = 4'd4;
            4'd2:  p_ma_1_final[0] = 4'd8;
            4'd3:  p_ma_1_final[0] = 4'd14;
            4'd4:  p_ma_1_final[0] = 4'd1;
            4'd5:  p_ma_1_final[0] = 4'd10;
            4'd6:  p_ma_1_final[0] = 4'd13;
            4'd7:  p_ma_1_final[0] = 4'd9;
            4'd8:  p_ma_1_final[0] = 4'd2;
            4'd9:  p_ma_1_final[0] = 4'd7;
            4'd10: p_ma_1_final[0] = 4'd5;
            4'd11: p_ma_1_final[0] = 4'd12;
            4'd12: p_ma_1_final[0] = 4'd11;
            4'd13: p_ma_1_final[0] = 4'd6;
            4'd14: p_ma_1_final[0] = 4'd3;
            default: p_ma_1_final[0] = 4'd0;
        endcase
    end

    // GF2_4_Poly_Mult_Reduce #(.N(4), .M(4)) poly_mult_2 (
    //     .A   ({p_ma_1_final[3], p_ma_1_final[2], p_ma_1_final[1], p_ma_1_final[0]}),
    //     .B   ({4'd15, div_3_q_o[2], div_3_q_o[1], div_3_q_o[0]}),
    //     .P   ({p_m_2_a_2[3], p_m_2_a_2[2], p_m_2_a_2[1], p_m_2_a_2[0]})
    // );

    GF2_4_Poly_Mult_Reduce_custom #(.N(3), .M(2), .O(4)) poly_mult_2_custom (
        .A   ({p_ma_1_final[2], p_ma_1_final[1], p_ma_1_final[0]}),
        .B   ({div_3_q_o[1], div_3_q_o[0]}),
        .P   ({p_m_2_a_2[3], p_m_2_a_2[2], p_m_2_a_2[1], p_m_2_a_2[0]})
    );

    GF2_4_Poly_Add #(.POLY_WIDTH(4)) poly_add_2 (
        .A   ({p_m_2_a_2[3], p_m_2_a_2[2], p_m_2_a_2[1], p_m_2_a_2[0]}),
        .B   ({4'd15, p_ma_0_final[2], p_ma_0_final[1], p_ma_0_final[0]}),
        .Sum ({p_ma_2_final[3], p_ma_2_final[2], p_ma_2_final[1], p_ma_2_final[0]})
    );

    always @(*) begin
        if (div_7_r[4] == 'd15 && div_7_r[3] == 'd15) begin
            er_func[0] = p_ma_0_final[0];
            er_func[1] = p_ma_0_final[1];
            er_func[2] = p_ma_0_final[2];
            er_func[3] = 4'd15;
        end
        else if (div_6_r_o[5] == 'd15 && div_6_r_o[4] == 'd15 && div_6_r_o[3] == 'd15) begin
            er_func[0] = p_ma_1_final[0];
            er_func[1] = p_ma_1_final[1];
            er_func[2] = p_ma_1_final[2];
            er_func[3] = p_ma_1_final[3];
        end
        else begin
            er_func[0] = p_ma_2_final[0];
            er_func[1] = p_ma_2_final[1];
            er_func[2] = p_ma_2_final[2];
            er_func[3] = p_ma_2_final[3];
        end
    end

    // genvar gv_i;
    // generate
    //     for (gv_i = 0; gv_i < 15; gv_i = gv_i + 1) begin: gen_chien_search
    //         chien_search #(.SEARCH(gv_i)) search (
    //             .poly_in_3(er_func[3]),
    //             .poly_in_2(er_func[2]),
    //             .poly_in_1(er_func[1]),
    //             .poly_in_0(er_func[0]),
    //             .hit(final_hit[gv_i])
    //         );
    //     end
    // endgenerate

    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                er_func_reg[i] <= 4'd0;
            end
        end
        else begin
            if (input_cnt == 'd6) begin
                for (i = 0; i < 4; i = i + 1) begin
                    er_func_reg[i] <= er_func[i];
                end
            end
        end
    end

    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < 15; gv_i = gv_i + 1) begin: gen_chien_search
            chien_search #(.SEARCH(gv_i)) search (
                .poly_in_3(er_func_reg[3]),
                .poly_in_2(er_func_reg[2]),
                .poly_in_1(er_func_reg[1]),
                .poly_in_0(er_func_reg[0]),
                .hit(final_hit[gv_i])
            );
        end
    endgenerate


endmodule

module new_7 (
    IN_Divisor,
    OUT_Quotient,
    OUT_Remainder
);
    input  [6*4-1:0]  IN_Divisor;
    output reg [3*4-1:0]  OUT_Quotient;
    output reg [5*4-1:0]  OUT_Remainder;

    reg [3:0] A, B, C, D, E, F;
    reg [3:0] G, H, I, J, K, L;
    reg [3:0] M, N, O, P, Q, R;
    reg [3:0] S, T, U, V, W;
    reg [3:0] Q2, Q1, Q0;
    reg [3:0] pre_I;
    wire [3:0] DVS  [0:6-1];
    reg [3:0] norm_DVS [0:6-1];
    integer i;
    genvar gv_i;
    reg cool;
    generate
        for (gv_i = 0; gv_i < 6; gv_i = gv_i + 1) begin: gen_divisor_array
            assign DVS[gv_i] = IN_Divisor [gv_i*4 +: 4];
        end
    endgenerate

    always @(*) begin
        if (DVS[5] == 4'd15) begin
            norm_DVS = {DVS[4], DVS[3], DVS[2], DVS[1], DVS[0], 4'd15};
            cool = 1;
        end
        else begin
            norm_DVS = {DVS[5], DVS[4], DVS[3], DVS[2], DVS[1], DVS[0]};
            cool = 0;
        end

        A = gf_mul(gf_div(4'd0, norm_DVS[0]), norm_DVS[1]);
        B = gf_mul(gf_div(4'd0, norm_DVS[0]), norm_DVS[2]);
        C = gf_mul(gf_div(4'd0, norm_DVS[0]), norm_DVS[3]);
        D = gf_mul(gf_div(4'd0, norm_DVS[0]), norm_DVS[4]);
        U = gf_mul(gf_div(4'd0, norm_DVS[0]), norm_DVS[5]);


        pre_I = gf_div(4'd0, norm_DVS[0]);

        E = gf_mul(gf_div(A, norm_DVS[0]), norm_DVS[1]);
        F = gf_mul(gf_div(A, norm_DVS[0]), norm_DVS[2]);
        G = gf_mul(gf_div(A, norm_DVS[0]), norm_DVS[3]);
        H = gf_mul(gf_div(A, norm_DVS[0]), norm_DVS[4]);
        V = gf_mul(gf_div(A, norm_DVS[0]), norm_DVS[5]);

        I = gf_add(B, E);
        J = gf_add(C, F);
        K = gf_add(D, G);
        L = gf_add(U, H);
        W = V;

        M = gf_mul(gf_div(I, norm_DVS[0]), norm_DVS[1]);
        N = gf_mul(gf_div(I, norm_DVS[0]), norm_DVS[2]);
        O = gf_mul(gf_div(I, norm_DVS[0]), norm_DVS[3]);
        P = gf_mul(gf_div(I, norm_DVS[0]), norm_DVS[4]);

        Q = gf_add(J, M);
        R = gf_add(K, N);
        S = gf_add(L, O);
        T = P;

        Q2 = gf_div(4'd0, norm_DVS[0]);
        Q1 = gf_div(A, norm_DVS[0]);
        Q0 = gf_div(I, norm_DVS[0]);

        if (DVS[5] == 4'd15) begin
            OUT_Remainder = {4'd15, Q, R, S, T};
            OUT_Quotient  = {Q2, Q1, Q0};
        end
        else begin
            OUT_Remainder = {I, J, K, L, W};
            OUT_Quotient  = {4'd15, Q2, Q1};
        end
    end


    function [3:0] gf_mul;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15 || b == 4'd15) begin
                gf_mul = 4'd15;
            end
            else begin
                sum = a + b;
                if(sum >= 15) begin
                    sum = sum - 15;
                end
                gf_mul = sum[3:0];
            end
        end
    endfunction

    function [3:0] gf_div;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15) begin
                gf_div = 4'd15;
            end
            else begin
                sum = a + (15 - b);
                if (sum >= 15) begin
                    gf_div = sum - 15;
                end
                else begin
                    gf_div = sum[3:0];
                end
            end
        end
    endfunction

    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule

module chien_search #(parameter SEARCH = 0) (
    input  [3:0] poly_in_0,
    input  [3:0] poly_in_1,
    input  [3:0] poly_in_2,
    input  [3:0] poly_in_3,
    output hit
);
    localparam real_exp = 15 - SEARCH;
    reg [3:0] deg_3, deg_2, deg_1, deg_0;
    reg [3:0] sum;
    always @(*) begin
        deg_3 = gf_mul(poly_in_3, (3*real_exp)%15);
        deg_2 = gf_mul(poly_in_2, (2*real_exp)%15);
        deg_1 = gf_mul(poly_in_1, (1*real_exp)%15);
        deg_0 = poly_in_0;
        sum = gf_add(gf_add(gf_add(deg_3, deg_2), deg_1), deg_0);
    end
    assign hit = (sum == 4'hf) ? 1'b1 : 1'b0;

    function [3:0] gf_mul;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15 || b == 4'd15) begin
                gf_mul = 4'd15;
            end
            else begin
                sum = a + b;
                if(sum >= 15) begin
                    sum = sum - 15;
                end
                gf_mul = sum[3:0];
            end
        end
    endfunction

    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule


module real_d_ip #(parameter IP_WIDTH = 7) (
    IN_Dividend, 
    IN_Divisor,
    OUT_Quotient,
    OUT_Remainder
);

    input  [IP_WIDTH*4-1:0]  IN_Dividend;
    input  [IP_WIDTH*4-1:0]  IN_Divisor;
    output [IP_WIDTH*4-1:0]  OUT_Quotient;
    output [IP_WIDTH*4-1:0]  OUT_Remainder;
    
    reg    [IP_WIDTH*4-1:0]  OUT_Quotient;
    reg    [IP_WIDTH*4-1:0]  OUT_Remainder;

    wire [3:0] V  [0:IP_WIDTH-1];
    reg [3:0] Q [0:IP_WIDTH-1];
    reg [3:0] R [0:IP_WIDTH-1];
    
    integer i, j, k;
    reg [3:0] factor;
    
    integer q_deg;
    reg found;
    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < IP_WIDTH; gv_i = gv_i + 1) begin: gen_divisor_array
            assign V[gv_i] = IN_Divisor[gv_i*4 +: 4];
            assign OUT_Quotient [gv_i*4 +: 4] = Q[IP_WIDTH - gv_i - 1];
            assign OUT_Remainder[gv_i*4 +: 4] = R[IP_WIDTH - gv_i - 1];
        end
    endgenerate

    always @(*) begin
        for (i = 0; i < IP_WIDTH; i = i + 1) begin
            Q [i] = 4'd15;
            R[i] = IN_Dividend[((IP_WIDTH-1)-i)*4 +: 4];
        end

        q_deg = IP_WIDTH - 1;
        while (q_deg >= 0 && V[q_deg] == 4'd15) begin
            q_deg = q_deg - 1;
        end


        for (i = 0; i < 3; i = i + 1) begin
            if (R[i] != 4'd15 && (IP_WIDTH - q_deg > i)) begin
                factor = gf_div(R[i], V[q_deg]);
                Q[q_deg + i] = gf_div(R[i], V[q_deg]);
                for (j = 0; j < IP_WIDTH; j = j + 1) begin
                    if (i + j < IP_WIDTH) begin
                        if ((q_deg - j) >= 0) begin
                            R[i+j] = gf_add(R[i+j], gf_mul(factor, V[q_deg - j]));
                        end
                    end
                end
            end
        end
        
        // $display("%0d, %0d, %0d, %0d, %0d", R[0], R[1], R[2], R[3], R[4]);

    end


    function [3:0] gf_mul;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15 || b == 4'd15) begin
                gf_mul = 4'd15;
            end
            else begin
                sum = a + b;
                if(sum >= 15) begin
                    sum = sum - 15;
                end
                gf_mul = sum[3:0];
            end
        end
    endfunction

    function [3:0] gf_div;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15) begin
                gf_div = 4'd15;
            end
            else begin
                sum = a + (15 - b);
                if (sum >= 15) begin
                    gf_div = sum - 15;
                end
                else begin
                    gf_div = sum[3:0];
                end
            end
        end
    endfunction

    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule

module GF2_4_Poly_Mult_Reduce #(parameter N = 7,
                                parameter M = 7)
(
    input  [N*4-1:0] A,
    input  [N*4-1:0] B,
    output [M*4-1:0] P
);

    localparam PROD_LEN = N;
    
    integer i, j;
    reg [3:0] a_array [0:N-1];
    reg [3:0] b_array [0:N-1];
    reg [3:0] prod_array [0:PROD_LEN-1];
    reg [M*4-1:0] P_reg;

    always @(*) begin
        for (i = 0; i < N; i = i + 1) begin
            a_array[i] = A[i*4 +: 4];
        end
        for (j = 0; j < N; j = j + 1) begin
            b_array[j] = B[j*4 +: 4];
        end

        for (i = 0; i < PROD_LEN; i = i + 1) begin
            prod_array[i] = 4'd15;
        end

        for (i = 0; i < N - 1; i = i + 1) begin
            for (j = 0; j < N - 1; j = j + 1) begin
                if (i + j < PROD_LEN) begin
                    prod_array[i+j] = gf_add(prod_array[i+j], gf_mul(a_array[i], b_array[j]));
                end
            end
        end

        for (i = 0; i < M; i = i + 1) begin
            P_reg[i*4 +: 4] = prod_array[i];
        end
    end

    assign P = P_reg;


    function [3:0] gf_mul;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15 || b == 4'd15) begin
                gf_mul = 4'd15;
            end
            else begin
                sum = a + b;
                if(sum >= 15) begin
                    sum = sum - 15;
                end
                gf_mul = sum[3:0];
            end
        end
    endfunction

    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule

module GF2_4_Poly_Mult_Reduce_custom #(parameter N = 7,
                                parameter M = 7, parameter O = 7)
(
    input  [N*4-1:0] A,
    input  [M*4-1:0] B,
    output [O*4-1:0] P
);

    localparam PROD_LEN = N;
    
    integer i, j;
    reg [3:0] a_array [0:N-1];
    reg [3:0] b_array [0:M-1];
    reg [3:0] prod_array [0:O-1];
    reg [O*4-1:0] P_reg;

    always @(*) begin
        for (i = 0; i < N; i = i + 1) begin
            a_array[i] = A[i*4 +: 4];
        end
        for (j = 0; j < M; j = j + 1) begin
            b_array[j] = B[j*4 +: 4];
        end

        for (i = 0; i < O; i = i + 1) begin
            prod_array[i] = 4'd15;
        end

        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < M; j = j + 1) begin
                if (i + j < O) begin
                    prod_array[i+j] = gf_add(prod_array[i+j], gf_mul(a_array[i], b_array[j]));
                end
            end
        end

        for (i = 0; i < O; i = i + 1) begin
            P_reg[i*4 +: 4] = prod_array[i];
        end
    end

    assign P = P_reg;


    function [3:0] gf_mul;
        input [3:0] a, b;
        reg [4:0] sum;
        begin
            if (a == 4'd15 || b == 4'd15) begin
                gf_mul = 4'd15;
            end
            else begin
                sum = a + b;
                if(sum >= 15) begin
                    sum = sum - 15;
                end
                gf_mul = sum[3:0];
            end
        end
    endfunction

    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule


module GF2_4_Poly_Add #(parameter POLY_WIDTH = 4)(
    input  [POLY_WIDTH*4-1:0] A,
    input  [POLY_WIDTH*4-1:0] B,
    output [POLY_WIDTH*4-1:0] Sum
);

    reg [POLY_WIDTH*4-1:0] Sum_reg;
    integer i;
  
    always @(*) begin
        for (i = 0; i < POLY_WIDTH; i = i + 1) begin
              Sum_reg[i*4 +: 4] = gf_add(A[i*4 +: 4], B[i*4 +: 4]);
        end
    end
  
    assign Sum = Sum_reg;
  


    function [3:0] gf_add;
        input [3:0] a, b;
        reg [3:0] a_poly, b_poly, s_poly;
        begin
            a_poly = e2p(a);
            b_poly = e2p(b);
            s_poly = a_poly ^ b_poly;
            gf_add = p2e(s_poly);
        end
    endfunction

    function [3:0] e2p;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  e2p = 4'd1;
                4'd1:  e2p = 4'd2;
                4'd2:  e2p = 4'd4;
                4'd3:  e2p = 4'd8;
                4'd4:  e2p = 4'd3;
                4'd5:  e2p = 4'd6;
                4'd6:  e2p = 4'd12;
                4'd7:  e2p = 4'd11;
                4'd8:  e2p = 4'd5;
                4'd9:  e2p = 4'd10;
                4'd10: e2p = 4'd7;
                4'd11: e2p = 4'd14;
                4'd12: e2p = 4'd15;
                4'd13: e2p = 4'd13;
                4'd14: e2p = 4'd9;
                4'd15: e2p = 4'd0;
            endcase
        end
    endfunction

    function [3:0] p2e;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  p2e = 4'd15;
                4'd1:  p2e = 4'd0;
                4'd2:  p2e = 4'd1;
                4'd3:  p2e = 4'd4;
                4'd4:  p2e = 4'd2;
                4'd5:  p2e = 4'd8;
                4'd6:  p2e = 4'd5;
                4'd7:  p2e = 4'd10;
                4'd8:  p2e = 4'd3;
                4'd9:  p2e = 4'd14;
                4'd10: p2e = 4'd9;
                4'd11: p2e = 4'd7;
                4'd12: p2e = 4'd6;
                4'd13: p2e = 4'd13;
                4'd14: p2e = 4'd11;
                4'd15: p2e = 4'd12;
            endcase
        end
    endfunction

endmodule