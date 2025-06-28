//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2025/4
//		Version		: v1.0
//   	File Name   : AFS.sv
//   	Module Name : AFS
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module AFS(input clk, INF.AFS_inf inf);
import usertype::*;

parameter S_IDLE_INPU   = 3'b000;
parameter S_READ_DRAM   = 3'b001;
parameter S_CALC_0      = 3'b010;
parameter S_CALC_01     = 3'b011;
parameter S_CALC_02     = 3'b100;
parameter S_CALC_03     = 3'b101;
parameter S_CALC_1      = 3'b110;
parameter S_CALC_11     = 3'b111;

parameter RESTOCK_WARN = 2'b11;
parameter STOCK_WARN   = 2'b10;
parameter NO_WARN      = 2'b00;
parameter DATE_WARN    = 2'b01;

    //==============================================//
    //              logic declaration               //
    // ============================================ //

logic [2 :0]      state;
logic [2 :0] next_state;
logic [1 :0] pre_warn_msg;

    //==============================================//
    //              AXI4-Lite Related               //
    // ============================================ //
logic              addr_conflict_r;
logic                delay_write_r;
logic               write_busy_W_r;
logic               write_busy_B_r;
logic              r_valid_delay_r;
logic  update_the_data_handshake_r;

    //==============================================//
    //              Operation Related               //
    // ============================================ //
logic [1 :0]              action_r;
logic [2 :0]            strategy_r;
logic [1 :0]                mode_r;
logic [3 :0]               month_r;
logic [4 :0]                 day_r;
logic [7 :0]             data_no_r;
logic [7 :0]          aw_data_no_r;
logic [11:0]          rstk_prchs_r [0:3];
// 0: Rose
// 1: Lily
// 2: Carnation
// 3: Baby's Breath
logic                      sr_flag;

logic [1 :0]      restock_in_cnt_r;
logic                    input_end;
logic [63:0]            the_data_r;

logic [4 :0]        the_data_day_r;
logic [3 :0]        the_data_mon_r;
logic [11:0]        the_data_b_b_r;
logic [11:0]        the_data_car_r;
logic [11:0]        the_data_lil_r;
logic [11:0]        the_data_ros_r;

logic [12:0]         rose_rstk_add;
logic [12:0]       adder_added;
logic [12:0]         lily_rstk_add;
logic [12:0]         carn_rstk_add;
logic [12:0]         b_b__rstk_add;

logic [11:0]             pre_add_a;
logic [11:0]             pre_add_b;
logic [12:0]                 added;

logic               flow_bit_ros_r;
logic               flow_bit_lil_r;
logic               flow_bit_car_r;
logic               flow_bit_b_b_r;

logic [9 :0] base_prchs_flower_cnt;
logic [11:0]       pipeline_rstk_r;
logic             rstk_valid_delay;

logic                  fucking_one;
logic                 fucking_zero;

// 2025/5/3
// debt:
// conflict on same address.
// 64 data switch
// busy_w busy_B usage
logic [2:0] add_state;
assign add_state = state + 1'b1;

    //==============================================//
    //                   FSM LOGICS                 //
    // ============================================ //
always @(*) begin
    next_state = state;
    case(state)
        S_IDLE_INPU: begin // 000
            if (input_end && !write_busy_B_r) begin
                next_state = S_READ_DRAM;
            end
        end
        S_READ_DRAM: begin // 001
            if (update_the_data_handshake_r) begin
                next_state = S_CALC_0;
            end
        end
        S_CALC_0: begin   // 100
            next_state = S_CALC_01;
        end
        S_CALC_01: begin // 101
            next_state = S_CALC_02;
        end
        S_CALC_02: begin // 110
            next_state = S_CALC_03;
        end
        S_CALC_03: begin // 111
            next_state = S_CALC_1;
        end
        S_CALC_1: begin // 010
            next_state = S_IDLE_INPU;
        end
    endcase
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        state <= S_IDLE_INPU;
    end 
    else begin
        state <= next_state;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        sr_flag <= 1'b0;
    end
    else begin
        if (state == S_READ_DRAM && update_the_data_handshake_r) begin
            sr_flag <= 1'b1;
        end
        else if (state == S_CALC_03) begin
            sr_flag <= 1'b0;
        end
        else begin
            sr_flag <= sr_flag;
        end
    end
end



    //==============================================//
    //              Output Logics                   //
    // ============================================ //

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        inf.out_valid <= 1'b0;
    end
    else begin
        if (state == S_CALC_1) begin
            inf.out_valid <= 1'b1;
        end
        else begin
            inf.out_valid <= 1'b0;
        end
    end
end

always @(*) begin
    inf.complete = 1'b0;
    if (inf.warn_msg == 2'b00 && inf.out_valid) begin
        inf.complete = 1'b1;
    end
end

always @(*) begin
    inf.warn_msg = 2'b0;
    if (inf.out_valid) begin
        inf.warn_msg = pre_warn_msg;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        pre_warn_msg <= NO_WARN;
    end
    else begin
        if (action_r == 2'b01) begin
            if (flow_bit_b_b_r | flow_bit_car_r | flow_bit_lil_r | flow_bit_ros_r) begin
                pre_warn_msg <= RESTOCK_WARN;
            end
            else begin
                pre_warn_msg <= NO_WARN;
            end
        end
        else if (action_r == 2'b00) begin
            if ({month_r, day_r} < {the_data_mon_r, the_data_day_r}) begin
                pre_warn_msg <= DATE_WARN;
            end
            else if (!flow_bit_b_b_r | !flow_bit_car_r | !flow_bit_lil_r | !flow_bit_ros_r) begin
                pre_warn_msg <= STOCK_WARN;
                
            end
            else begin
                pre_warn_msg <= NO_WARN;
            end
        end
        else if ({month_r, day_r} < {the_data_mon_r, the_data_day_r}) begin
            pre_warn_msg <= DATE_WARN;
        end
        else begin
            pre_warn_msg <= NO_WARN;
        end
    end
end


    //==============================================//
    //              Operation Related               //
    // ============================================ //
assign adder_added = the_data_ros_r + rstk_prchs_r[0];


always @(posedge clk, negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        the_data_ros_r <= 12'b0;
    end
    else begin
        if (sr_flag) begin
            the_data_ros_r <= the_data_lil_r;
        end
        else if (update_the_data_handshake_r) begin
            the_data_ros_r <= inf.R_DATA[63:52];
        end
        else begin
            the_data_ros_r <= the_data_ros_r;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        the_data_lil_r <= 12'b0;
    end
    else begin
        if (sr_flag) begin
            the_data_lil_r <= the_data_car_r;
        end
        else if (update_the_data_handshake_r) begin
            the_data_lil_r <= inf.R_DATA[51:40];
        end
        else begin
            the_data_lil_r <= the_data_lil_r;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        the_data_car_r <= 12'b0;
    end
    else begin
        if (sr_flag) begin
            the_data_car_r <= the_data_b_b_r;
        end
        else if (update_the_data_handshake_r) begin
            the_data_car_r <= inf.R_DATA[31:20];
        end
        else begin
            the_data_car_r <= the_data_car_r;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        the_data_b_b_r <= 12'b0;
    end
    else begin
        if (sr_flag) begin
            if (adder_added[12] && action_r == 2'b01) begin
                the_data_b_b_r <= 12'd4095;
            end
            else begin
                the_data_b_b_r <= adder_added[11:0]; 
            end
        end
        else if (update_the_data_handshake_r) begin
            the_data_b_b_r <= inf.R_DATA[19:8];
        end
        else begin
            the_data_b_b_r <= the_data_b_b_r;
        end
    end
end




always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        the_data_day_r <=  5'b0;
        the_data_mon_r <= 12'b0;
    end 
    else begin
        if (update_the_data_handshake_r) begin
            the_data_day_r <= inf.R_DATA[ 4: 0];
            the_data_mon_r <= inf.R_DATA[35:32];
        end
        else if (state == S_CALC_1) begin
            if (action_r != 2'b00) begin
                the_data_day_r <= day_r;
            end
            if (action_r != 2'b00) begin
                the_data_mon_r <= month_r;
            end
        end
    end
end


always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        flow_bit_ros_r <= 1'b0;
        flow_bit_lil_r <= 1'b0;
        flow_bit_car_r <= 1'b0;
        flow_bit_b_b_r <= 1'b0;
    end
    else begin
        if (sr_flag) begin
            if (action_r == 2'b01) begin
                flow_bit_b_b_r <= adder_added[12];
            end
            else begin
                flow_bit_b_b_r <= (adder_added[12] | (!rstk_prchs_r[0][11]));
            end
        end
        flow_bit_ros_r <= flow_bit_lil_r;
        flow_bit_lil_r <= flow_bit_car_r;
        flow_bit_car_r <= flow_bit_b_b_r;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        input_end <= 1'b0;
    end
    else if ((action_r == 2'b00 || action_r == 2'b10) && inf.data_no_valid) begin
        input_end <= 1'b1;
    end
    else if (action_r == 2'b01 && rstk_valid_delay && (restock_in_cnt_r == 2'b11)) begin
        input_end <= 1'b1;
    end
    else if (state == S_CALC_0) begin
        input_end <= 1'b0;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        action_r <= 2'b0;
    end 
    else begin
        if (inf.sel_action_valid) begin
            action_r <= inf.D[1:0];
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        strategy_r <= 3'b0;
    end 
    else begin
        if (inf.strategy_valid) begin
            strategy_r <= inf.D[2:0];
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        mode_r <= 2'b0;
    end 
    else begin
        if (inf.mode_valid) begin
            mode_r <= inf.D[1:0];
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        month_r <= 4'b0;
    end 
    else begin
        if (inf.date_valid) begin
            month_r <= inf.D[8:5];
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        day_r <= 5'b0;
    end 
    else begin
        if (inf.date_valid) begin
            day_r <= inf.D[4:0];
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        data_no_r <= 8'b0;
    end 
    else begin
        if (inf.data_no_valid) begin
            data_no_r <= inf.D[7:0];
        end
    end
end

always @(*) begin
    if (mode_r == 2'b00) begin
        base_prchs_flower_cnt = 10'd120;
    end
    else if (mode_r == 2'b01) begin
        base_prchs_flower_cnt = 10'd480;
    end
    else begin
        base_prchs_flower_cnt = 10'd960;
    end
end

// logic [9:0] base_prchs_flower_cnt_inv = ~base_prchs_flower_cnt

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        pipeline_rstk_r <= 12'b0;
        rstk_valid_delay <= 1'b0;
    end 
    else begin
        pipeline_rstk_r <= inf.D[11:0];
        rstk_valid_delay <= inf.restock_valid;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        rstk_prchs_r[0] <= 12'b0; // Rose
        rstk_prchs_r[1] <= 12'b0; // Lily
        rstk_prchs_r[2] <= 12'b0; // Carnation
        rstk_prchs_r[3] <= 12'b0; // Baby's Breath
        restock_in_cnt_r <=  2'b0;
    end
    else begin
        if (sr_flag) begin
            rstk_prchs_r[0] <= rstk_prchs_r[1];
            rstk_prchs_r[1] <= rstk_prchs_r[2];
            rstk_prchs_r[2] <= rstk_prchs_r[3];
        end
        else if (action_r == 2'b01 && rstk_valid_delay) begin // TODO: danger when read latency = 1
            restock_in_cnt_r <= restock_in_cnt_r + 1'b1;
            // rstk_prchs_r[restock_in_cnt_r] <= pipeline_rstk_r;
            rstk_prchs_r[0] <= rstk_prchs_r[1];
            rstk_prchs_r[1] <= rstk_prchs_r[2];
            rstk_prchs_r[2] <= rstk_prchs_r[3];
            rstk_prchs_r[3] <= pipeline_rstk_r;
        end
        else if (action_r == 2'b00) begin
            case(strategy_r) // synopsys parallel_case
                3'd0: begin
                    rstk_prchs_r[0] <= -base_prchs_flower_cnt;
                    rstk_prchs_r[1] <= 12'b0;
                    rstk_prchs_r[2] <= 12'b0;
                    rstk_prchs_r[3] <= 12'b0;
                end
                3'd1: begin
                    rstk_prchs_r[0] <= 12'b0;
                    rstk_prchs_r[1] <= -base_prchs_flower_cnt;
                    rstk_prchs_r[2] <= 12'b0;
                    rstk_prchs_r[3] <= 12'b0;
                end
                3'd2: begin
                    rstk_prchs_r[0] <= 12'b0;
                    rstk_prchs_r[1] <= 12'b0;
                    rstk_prchs_r[2] <= -base_prchs_flower_cnt;
                    rstk_prchs_r[3] <= 12'b0;
                end
                3'd3: begin
                    rstk_prchs_r[0] <= 12'b0;
                    rstk_prchs_r[1] <= 12'b0;
                    rstk_prchs_r[2] <= 12'b0;
                    rstk_prchs_r[3] <= -base_prchs_flower_cnt;
                end
                3'd4: begin
                    rstk_prchs_r[0] <= -(base_prchs_flower_cnt >> 1);
                    rstk_prchs_r[1] <= -(base_prchs_flower_cnt >> 1);
                    rstk_prchs_r[2] <= 12'b0;
                    rstk_prchs_r[3] <= 12'b0;
                end
                3'd5: begin
                    rstk_prchs_r[0] <= 12'd0;
                    rstk_prchs_r[1] <= 12'd0;
                    rstk_prchs_r[2] <= -(base_prchs_flower_cnt >> 1);
                    rstk_prchs_r[3] <= -(base_prchs_flower_cnt >> 1);
                end
                3'd6: begin
                    rstk_prchs_r[0] <= -(base_prchs_flower_cnt >> 1);
                    rstk_prchs_r[1] <= 12'b0;
                    rstk_prchs_r[2] <= -(base_prchs_flower_cnt >> 1);
                    rstk_prchs_r[3] <= 12'b0;
                end
                default: begin
                    rstk_prchs_r[0] <= -(base_prchs_flower_cnt >> 2);
                    rstk_prchs_r[1] <= -(base_prchs_flower_cnt >> 2);
                    rstk_prchs_r[2] <= -(base_prchs_flower_cnt >> 2);
                    rstk_prchs_r[3] <= -(base_prchs_flower_cnt >> 2);
                end
            endcase
        end
        else begin
            rstk_prchs_r[0] <= rstk_prchs_r[0];
            rstk_prchs_r[1] <= rstk_prchs_r[1];
            rstk_prchs_r[2] <= rstk_prchs_r[2];
            rstk_prchs_r[3] <= rstk_prchs_r[3];
        end
    end
end

    //==============================================//
    //                AXI4-Lite Logics              //
    // ============================================ //

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        fucking_one <= 1'b0;
    end 
    else begin
        fucking_one <= 1'b1;
    end
end

assign inf.B_READY = fucking_one;
assign inf.AR_ADDR = {fucking_one, 5'b00000, data_no_r, 3'b000};
assign inf.AW_ADDR = {fucking_one, 5'b00000, data_no_r, 3'b000};
assign inf.W_DATA  = {the_data_ros_r, the_data_lil_r, 4'b0000, the_data_mon_r, the_data_car_r, the_data_b_b_r, 3'b000, the_data_day_r};

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        update_the_data_handshake_r <= 1'b0;
    end
    else begin
        update_the_data_handshake_r <= inf.R_VALID && state == S_READ_DRAM;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        inf.AR_VALID <= 1'b0;
    end 
    else begin
        if (inf.AR_READY) begin
            inf.AR_VALID <= 1'b0;
        end
        else if (state == S_IDLE_INPU && input_end && !write_busy_B_r) begin
            inf.AR_VALID <= 1'b1;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        r_valid_delay_r <= 1'b0;
    end
    else begin
        r_valid_delay_r <= inf.R_VALID;
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        inf.W_VALID <= 1'b0;
    end 
    else begin
        if (inf.AW_READY) begin
            inf.W_VALID <= 1'b1;
        end
        else if (inf.W_READY) begin
            inf.W_VALID <= 1'b0;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        inf.AW_VALID <= 1'b0;
    end 
    else begin
        if (inf.AW_READY) begin
            inf.AW_VALID <= 1'b0;
        end
        else if (delay_write_r) begin
            inf.AW_VALID <= 1'b1;
        end
    end
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        inf.R_READY <= 1'b0;
    end 
    else begin
        if (inf.out_valid) begin
            inf.R_READY <= 1'b1;
        end
        else begin
            inf.R_READY <= 1'b0;
        end
    end
end

always @(*) begin
    delay_write_r = (inf.out_valid && ((action_r == 2'b01) || (action_r == 2'b00 && inf.warn_msg == 2'b00)));
end

always @(posedge clk, negedge inf.rst_n) begin
    if (~inf.rst_n) begin
        write_busy_B_r <= 1'b0;
    end 
    else begin
        if (write_busy_B_r && inf.B_VALID) begin
            write_busy_B_r <= 1'b0;
        end
        else if (inf.AW_VALID) begin // or look at aw_ready (lower at 1.9)
            write_busy_B_r <= 1'b1;
        end
        else begin
            write_busy_B_r <= write_busy_B_r;
        end
    end
end


endmodule

