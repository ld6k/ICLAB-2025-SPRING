//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//    Date       : 2023/10
//    Version    : v1.0
//    File Name  : Division_IP.v
//    Module Name: Division_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module Division_IP #(parameter IP_WIDTH = 6) (
    IN_Dividend, 
    IN_Divisor,
    OUT_Quotient
);

    input  [IP_WIDTH*4-1:0] IN_Dividend;
    input  [IP_WIDTH*4-1:0] IN_Divisor;
    output [IP_WIDTH*4-1:0] OUT_Quotient;

    wire [3:0] V [0:IP_WIDTH-1];
    reg [3:0] Q [0:IP_WIDTH-1];
    reg [3:0] R [0:IP_WIDTH-1];

    integer i, j, k;
    integer degV;
    integer q_deg;
    reg [3:0] factor;
    reg found;


    genvar gv_i;
    generate
        for (gv_i = 0; gv_i < IP_WIDTH; gv_i = gv_i + 1) begin: gen_divisor_array
            assign V[gv_i] = IN_Divisor[gv_i*4 +: 4];
            assign OUT_Quotient [gv_i*4 +: 4] = Q[gv_i];
        end
    endgenerate

    always @(*) begin
        for (i = 0; i < IP_WIDTH; i = i + 1) begin
            R[i] = IN_Dividend[i*4 +: 4];
            Q[i] = 4'd15;
        end
        
        found = 0;
        degV = 0;
        for (i = IP_WIDTH-1; i >= 0; i = i - 1) begin
            if (!found && (V[i] != 4'd15)) begin
                degV = i;
                found = 1;
            end
        end
        if (!found) begin
            degV = 0;
        end
        
        q_deg = IP_WIDTH - degV - 1;
        for (k = IP_WIDTH - 1; k >= 0; k = k - 1) begin
            if (k <= q_deg) begin
                if (R[k + degV] != 4'd15) begin
                    factor = gf_div(R[k + degV], V[degV]);
                    Q[k] = factor;
                    for (j = IP_WIDTH - 1; j >= 0; j = j - 1) begin
                        if ((k + j) < IP_WIDTH) begin
                            R[k + j] = gf_add(R[k + j], gf_mul(factor, V[j]));
                        end
                    end
                end 
                else begin
                    Q[k] = 4'd15;
                end
            end
            else begin
                Q[k] = 4'd15;
            end
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
            a_poly = gf_poly_of_exp(a);
            b_poly = gf_poly_of_exp(b);
            s_poly = a_poly ^ b_poly;
            gf_add = gf_exp_of_poly(s_poly);
        end
    endfunction

    function [3:0] gf_poly_of_exp;
        input [3:0] exp;
        begin
            case(exp)
                4'd0:  gf_poly_of_exp = 4'd1;
                4'd1:  gf_poly_of_exp = 4'd2;
                4'd2:  gf_poly_of_exp = 4'd4;
                4'd3:  gf_poly_of_exp = 4'd8;
                4'd4:  gf_poly_of_exp = 4'd3;
                4'd5:  gf_poly_of_exp = 4'd6;
                4'd6:  gf_poly_of_exp = 4'd12;
                4'd7:  gf_poly_of_exp = 4'd11;
                4'd8:  gf_poly_of_exp = 4'd5;
                4'd9:  gf_poly_of_exp = 4'd10;
                4'd10: gf_poly_of_exp = 4'd7;
                4'd11: gf_poly_of_exp = 4'd14;
                4'd12: gf_poly_of_exp = 4'd15;
                4'd13: gf_poly_of_exp = 4'd13;
                4'd14: gf_poly_of_exp = 4'd9;
                4'd15: gf_poly_of_exp = 4'd0;
              default: gf_poly_of_exp = 4'd0;
            endcase
        end
    endfunction

    function [3:0] gf_exp_of_poly;
        input [3:0] poly;
        begin
            case(poly)
                4'd0:  gf_exp_of_poly = 4'd15;
                4'd1:  gf_exp_of_poly = 4'd0;
                4'd2:  gf_exp_of_poly = 4'd1;
                4'd3:  gf_exp_of_poly = 4'd4;
                4'd4:  gf_exp_of_poly = 4'd2;
                4'd5:  gf_exp_of_poly = 4'd8;
                4'd6:  gf_exp_of_poly = 4'd5;
                4'd7:  gf_exp_of_poly = 4'd10;
                4'd8:  gf_exp_of_poly = 4'd3;
                4'd9:  gf_exp_of_poly = 4'd14;
                4'd10: gf_exp_of_poly = 4'd9;
                4'd11: gf_exp_of_poly = 4'd7;
                4'd12: gf_exp_of_poly = 4'd6;
                4'd13: gf_exp_of_poly = 4'd13;
                4'd14: gf_exp_of_poly = 4'd11;
                4'd15: gf_exp_of_poly = 4'd12;
                default: gf_exp_of_poly = 4'd15;
            endcase
        end
    endfunction

endmodule