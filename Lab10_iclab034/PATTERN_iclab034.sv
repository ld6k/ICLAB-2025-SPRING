
// `include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;
//================================================================
// parameters & integer
//================================================================
parameter DRAM_p_r  = "../00_TESTBED/DRAM/dram.dat";
parameter MAX_CYCLE = 1000;
parameter SEED      = 1900;
parameter PATNUM    = 4200;
parameter DEBUG     = 0;

// ANSI escape sequences
localparam string ANSI_RESET  = "\033[0m";
localparam string ANSI_RED    = "\033[31m";
localparam string ANSI_GREEN  = "\033[32m";
localparam string ANSI_BLUE  = "\033[34m";
localparam string ANSI_BOLD     = "\033[1m";
localparam string ANSI_BG_BLUE  = "\033[44m";
localparam string ANSI_YELLOW = "\033[33m";
localparam string str_warn_msg[0:3] = {"No_Warn", "Date_Warn", "Stock_Warn", "Restock_Warn"};
localparam string str_action[0:2] = {"Purchase", "Restock", "Check_Valid_Date"};
localparam string str_strategy[0:7] = {"Strategy_A", "Strategy_B", "Strategy_C", "Strategy_D", "Strategy_E", "Strategy_F", "Strategy_G", "Strategy_H"};
localparam string str_mode[0:3] = {"Single", "Group_Order", "Event", "Event"};

integer   total_cycles;
integer   local_cycles;
integer        i, j, k;
integer cur_patnum;
logic [1:0] lut[0:2];

//================================================================
// wire & registers 
//================================================================
logic [7 :0]      golden_DRAM [((65536+8*256)-1):(65536+0)];  // 256 box
logic [1 :0]   golden_warn_msg;
logic          golden_complete;
logic [1 :0]    action_buffer;
logic [2 :0]  strategy_buffer;
logic [1 :0]      mode_buffer;
logic [4 :0]       day_buffer;
logic [3 :0]     month_buffer;
logic [11:0]  rstk_amt_buffer [0:3];
logic [7 :0]   data_no_buffer;

integer               global_real_addr;
integer hit_ten_stock_warn;
logic [4:0]          original_dram_day;
logic [3:0]        original_dram_month;
logic [11:0]        original_dram_rose;
logic [11:0]        original_dram_lily;
logic [11:0]   original_dram_carnation;
logic [11:0] original_dram_baby_breath;

logic [63:0] wdata_queue [$];
logic [31:0] waddr_queue [$];
logic [63:0] wdata_from_queue;
logic [31:0] waddr_from_queue;
logic [31:0] design_addr;

logic [2:0] use_this_strategy;
logic [1:0] use_this_mode;
integer how_many_purchase;
//================================================================
// class random
//================================================================

/**
 * Class representing a random action.
 */
class random_act;
    randc Action act_id;
    constraint range{
        act_id inside{Purchase, Restock, Check_Valid_Date};
    }
    function new(int seed = 0);
        this.srandom(seed);
    endfunction
endclass

class random_strategy;
    randc Strategy_Type strategy_id;
    constraint range{
        strategy_id inside{Strategy_A, Strategy_B, Strategy_C, Strategy_D, Strategy_E, Strategy_F, Strategy_G, Strategy_H};
    }
endclass

class random_mode;
    randc Mode mode_id;
    constraint range{
        mode_id inside{Single, Group_Order, Event};
    }
endclass

class random_rstk_amt;
    randc logic [11:0] rstk_amt;
    constraint range{
        rstk_amt inside{[0:4095]};
    }
endclass

class random_data_no;
    randc logic [7:0] data_no;
    constraint range{
        data_no inside{[0:252]};
    }
endclass



class random_date;
	randc Date date;
	constraint month_range{
		date.M inside{[1:7]};
	}

    constraint day_range{
        (date.M == 1 | date.M == 3 | date.M == 5 | date.M == 7 | date.M == 8 | date.M == 10 | date.M == 12) -> date.D inside{[1:31]};
        (date.M == 4 | date.M == 6 | date.M == 9 | date.M == 11)                                            -> date.D inside{[1:30]};
        (date.M == 2)                                                                                       -> date.D inside{[1:28]};
    }

endclass

class random_date_cvd;
	randc Date date;
	constraint month_range{
		date.M inside{[1:12]};
	}

    constraint day_range{
        (date.M == 1 | date.M == 3 | date.M == 5 | date.M == 7 | date.M == 8 | date.M == 10 | date.M == 12) -> date.D inside{[1:31]};
        (date.M == 4 | date.M == 6 | date.M == 9 | date.M == 11)                                            -> date.D inside{[1:30]};
        (date.M == 2)                                                                                       -> date.D inside{[1:28]};
    }
endclass

class random_date_ten;
	randc Date date;
	constraint month_range{
		date.M inside{[11:12]};
	}

    constraint day_range{
        (date.M == 1 | date.M == 3 | date.M == 5 | date.M == 7 | date.M == 8 | date.M == 10 | date.M == 12) -> date.D inside{[1:31]};
        (date.M == 4 | date.M == 6 | date.M == 9 | date.M == 11)                                            -> date.D inside{[1:30]};
        (date.M == 2)                                                                                       -> date.D inside{[1:28]};
    }

endclass

initial begin
    $readmemh(DRAM_p_r, golden_DRAM);
    total_cycles = 0;
    lut[0] = 0;
    lut[1] = 1;
    lut[2] = 3;
    how_many_purchase = 0;
    use_this_strategy = 0;
    use_this_mode     = 0;
    hit_ten_stock_warn = 0;
end

initial begin
    inf.rst_n            = 1'b1;
    inf.sel_action_valid = 1'b0;
    inf.strategy_valid   = 1'b0;
    inf.mode_valid       = 1'b0;
    inf.date_valid       = 1'b0;
    inf.data_no_valid    = 1'b0;
    inf.restock_valid    = 1'b0;
    inf.D                = 'x;
end

//================================================================
// MAIN()
//================================================================

initial begin
    reset_task;
    for (cur_patnum = 0; cur_patnum < PATNUM; cur_patnum = cur_patnum + 1) begin
        clear_all_buffered_random_input;
        if (cur_patnum <= 2699) begin
            case(cur_patnum % 9)
                0: begin
                    randomize_purchase_and_input_them;
                    calc_purchase_task;
                end
                1: begin
                    randomize_purchase_and_input_them;
                    calc_purchase_task;
                end
                2: begin
                    randomize_restock_and_input_them;
                    calc_restock_task;
                end
                3: begin
                    randomize_restock_and_input_them;
                    calc_restock_task;
                end
                4: begin
                    randomize_cvd_and_input_them;
                    calc_check_valid_date_task;
                end
                5: begin
                    randomize_cvd_and_input_them;
                    calc_check_valid_date_task;
                end
                6: begin
                    randomize_purchase_and_input_them;
                    calc_purchase_task;
                end
                7: begin
                    randomize_cvd_and_input_them;
                    calc_check_valid_date_task;
                end
                8: begin
                    randomize_restock_and_input_them;
                    calc_restock_task;
                end
            endcase
        end
        else begin
            randomize_purchase_and_input_them;
            calc_purchase_task;
        end
        wait_and_check_output_task;
    end
    pass_task;
    $finish;
end

// initial begin
//     forever begin
//         @(negedge clk);
//         if (inf.AW_READY && inf.AW_VALID) begin
//             design_addr = inf.AW_ADDR;
//             @(negedge clk);
//             while (!(inf.W_VALID && inf.W_READY)) begin
//                 @(negedge clk);
//             end
//             waddr_from_queue = waddr_queue.pop_front();
//             wdata_from_queue = wdata_queue.pop_front();
//             if (inf.W_DATA !== wdata_from_queue || design_addr !== waddr_from_queue) begin
//                 $display("ERROR: Write data mismatch");
//                 $display("YOURS:  %sW_DATA: %0h, W_ADDR: %0h%s", ANSI_RED, inf.W_DATA, inf.AW_ADDR, ANSI_RESET);
//                 $display("GOLDN:  %sW_DATA: %0h, W_ADDR: %0h%s", ANSI_YELLOW, wdata_from_queue, waddr_from_queue, ANSI_RESET);

//                 $fatal;
//             end
//             $display("[INFO] Write-back matched!");
//         end
//     end
// end

//================================================================
// INPUT TASKS
//================================================================

task reset_task; begin
    #(10);
    inf.rst_n = 1'b0;
    #(10);
    inf.rst_n = 1'b1;
end endtask

task clear_all_buffered_random_input; begin
    action_buffer      = 'x;
    strategy_buffer    = 'x;
    mode_buffer        = 'x;
    day_buffer         = 'x;
    month_buffer       = 'x;
    rstk_amt_buffer[0] = 'x;
    rstk_amt_buffer[1] = 'x;
    rstk_amt_buffer[2] = 'x;
    rstk_amt_buffer[3] = 'x;
    data_no_buffer     = 'x;
end endtask

task randomize_purchase_and_input_them; begin
    random_strategy strategy = new();
    random_mode         mode = new();
    random_date         date = new();
    random_date_ten   date_ten = new();
    random_data_no   data_no = new();

    assert(strategy.randomize()) else $fatal("strategy randomize() failed");
    assert(mode    .randomize()) else $fatal("mode randomize() failed");
    assert(date    .randomize()) else $fatal("date randomize() failed");
    assert(data_no .randomize()) else $fatal("data_no randomize() failed");
    assert(date_ten.randomize()) else $fatal("date_ten randomize() failed");
    if (how_many_purchase % 300 == 0) begin
        use_this_strategy = use_this_strategy + 1;
    end
    action_buffer   =             Purchase;
    strategy_buffer =          use_this_strategy;
    mode_buffer     =         lut[how_many_purchase % 3];
    
    if (hit_ten_stock_warn < 10) begin
        day_buffer      =             date_ten.date.D;
        month_buffer    =           date_ten.date.M;
    end
    else begin
        day_buffer      =             date.date.D;
        month_buffer    =           date.date.M;
    end

    hit_ten_stock_warn = hit_ten_stock_warn + 1;
    data_no_buffer  =      data_no.data_no;

    @(negedge clk)
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0]       = action_buffer;
    
    @(negedge clk)
    inf.sel_action_valid = 1'b0;
    inf.strategy_valid   = 1'b1;
    inf.D.d_strategy[0]  = strategy_buffer;
    
    @(negedge clk)
    inf.strategy_valid   = 1'b0;
    inf.mode_valid       = 1'b1;
    inf.D.d_mode[0]      = mode_buffer;
    
    @(negedge clk)
    inf.mode_valid       = 1'b0;
    inf.date_valid       = 1'b1;
    inf.D.d_date[0]      = {month_buffer, day_buffer};
    
    @(negedge clk)
    inf.date_valid       = 1'b0;
    inf.data_no_valid    = 1'b1;
    inf.D.d_data_no[0]   = data_no_buffer;
    
    @(negedge clk)
    inf.data_no_valid    = 1'b0;
    inf.D                =   'x;
    how_many_purchase = how_many_purchase + 1;
end endtask

task randomize_restock_and_input_them; begin
    random_date           date = new();
    random_data_no     data_no = new();
    random_rstk_amt rstk_amt_0 = new();
    random_rstk_amt rstk_amt_1 = new();
    random_rstk_amt rstk_amt_2 = new();
    random_rstk_amt rstk_amt_3 = new();



    assert(date      .randomize()) else $fatal("strategy randomize() failed");
    assert(data_no   .randomize()) else $fatal("data_no randomize() failed");
    assert(rstk_amt_0.randomize()) else $fatal("restock amount randomize() failed");
    assert(rstk_amt_1.randomize()) else $fatal("restock amount randomize() failed");
    assert(rstk_amt_2.randomize()) else $fatal("restock amount randomize() failed");
    assert(rstk_amt_3.randomize()) else $fatal("restock amount randomize() failed");

    action_buffer      =             Restock;
    day_buffer         =         date.date.D;
    month_buffer       =         date.date.M;
    data_no_buffer     =     255;
    rstk_amt_buffer[0] = rstk_amt_0.rstk_amt;
    rstk_amt_buffer[1] = rstk_amt_1.rstk_amt;
    rstk_amt_buffer[2] = rstk_amt_2.rstk_amt;
    rstk_amt_buffer[3] = rstk_amt_3.rstk_amt;

    @(negedge clk)
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0]       = action_buffer;

    @(negedge clk)
    inf.sel_action_valid = 1'b0;
    inf.date_valid       = 1'b1;
    inf.D.d_date[0]      = {month_buffer, day_buffer};

    @(negedge clk)
    inf.date_valid       = 1'b0;
    inf.data_no_valid    = 1'b1;
    inf.D.d_data_no[0]   = data_no_buffer;

    @(negedge clk)
    inf.data_no_valid    = 1'b0;
    inf.restock_valid    = 1'b1;
    inf.D.d_stock[0]     = rstk_amt_buffer[0];

    @(negedge clk)
    inf.restock_valid    = 1'b1;
    inf.D.d_stock[0]     = rstk_amt_buffer[1];

    @(negedge clk)
    inf.restock_valid    = 1'b1;
    inf.D.d_stock[0]     = rstk_amt_buffer[2];

    @(negedge clk)
    inf.restock_valid    = 1'b1;
    inf.D.d_stock[0]     = rstk_amt_buffer[3];

    @(negedge clk)
    inf.restock_valid    = 1'b0;
    inf.D                =   'x;
end endtask

task randomize_cvd_and_input_them; begin
    random_date_cvd           date = new();
    random_data_no         data_no = new();

    assert(date   .randomize()) else $fatal("strategy randomize() failed");
    assert(data_no.randomize()) else $fatal("data_no randomize() failed");

    action_buffer  = Check_Valid_Date;
    day_buffer     =         date.date.D;
    month_buffer   =       date.date.M;
    data_no_buffer =  data_no.data_no;

    @(negedge clk)
    inf.sel_action_valid = 1'b1;
    inf.D.d_act[0]       = action_buffer;

    @(negedge clk)
    inf.sel_action_valid = 1'b0;
    inf.date_valid       = 1'b1;
    inf.D.d_date[0]      = {month_buffer, day_buffer};

    @(negedge clk)
    inf.date_valid       = 1'b0;
    inf.data_no_valid    = 1'b1;
    inf.D.d_data_no[0]   = data_no_buffer;

    @(negedge clk)
    inf.data_no_valid    = 1'b0;
    inf.D                =   'x;

end endtask

//================================================================
// WAIT FOR AFS
//================================================================

task wait_and_check_output_task; begin
    local_cycles = -1;
    while (inf.out_valid !== 1'b1) begin
        local_cycles = local_cycles + 1;
        if (local_cycles > MAX_CYCLE) begin
            $display("================================================================");
            $display("| PATNUM %0d FAIL: Latency more than %0d cycles!", cur_patnum, MAX_CYCLE);
            $display("|---------------------------------------------------------------");
            $display("|                                                  YOU LOSER!");
            $display("================================================================");
            $fatal;
        end
        @(negedge clk);
    end
    if ((golden_complete === inf.complete) && (golden_warn_msg === inf.warn_msg)) begin
        if (DEBUG) begin
            $display("%sPASS PATNUM %0d, %s %2d cycles used%s", ANSI_GREEN, cur_patnum, ANSI_BLUE, local_cycles, ANSI_RESET);
            show_this_action_details;
            show_original_dram;
        end
    end
    else begin
        $display("Wrong Answer");
        if (DEBUG) begin
            $display("================================================================");
            $display("  %sPATNUM %0d FAIL: Wrong Answer ! YOU LOSER !%s", ANSI_BG_BLUE, cur_patnum, ANSI_RESET);
            $display("----------------------------------------------------------------");
            $display("   %sgolden_complete = %0d%s, %sinf.complete = %0d%s", ANSI_YELLOW, golden_complete, ANSI_RESET, ANSI_RED, inf.complete, ANSI_RESET);
            $display("   %sgolden_warn_msg = %0d%s, %sinf.warn_msg = %0d%s", ANSI_YELLOW, golden_warn_msg, ANSI_RESET, ANSI_RED, inf.warn_msg, ANSI_RESET);
            $display("----------------------------------------------------------------");
            $display("  ACTION: %0d, STRATEGY: %0d, MODE: %0d", action_buffer, strategy_buffer, mode_buffer);
            $display("  CUR DATE: %0d/%0d, USED DATA_NO: %0d", month_buffer, day_buffer, data_no_buffer);
            $display("  RESTOCK AMT (ROSE): %0d", rstk_amt_buffer[0]);
            $display("  RESTOCK AMT (LILY): %0d", rstk_amt_buffer[1]);
            $display("  RESTOCK AMT (CARNATION): %0d", rstk_amt_buffer[2]);
            $display("  RESTOCK AMT (BABY BREATH): %0d", rstk_amt_buffer[3]);
            $display("================================================================");
            $display("");
            show_original_dram;
        end
        $fatal;
    end
    total_cycles = total_cycles + local_cycles;
end endtask

task show_original_dram; begin
    $display("================================================================");
    $display("  %sOriginal DRAM Address: %0H%s", ANSI_BG_BLUE, global_real_addr, ANSI_RESET);
    $display("----------------------------------------------------------------");
    $display("  Original DATE: %0d/%0d", original_dram_month, original_dram_day);
    $display("  Original DRAM (ROSE)       : D: %0d, H: %0h", original_dram_rose, original_dram_rose);
    $display("  Original DRAM (LILY)       : D: %0d, H: %0h", original_dram_lily, original_dram_lily);
    $display("  Original DRAM (CARNATION)  : D: %0d, H: %0h", original_dram_carnation, original_dram_carnation);
    $display("  Original DRAM (BABY BREATH): D: %0d, H: %0h", original_dram_baby_breath, original_dram_baby_breath);
    $display("================================================================");
end endtask

task show_this_action_details; begin
    $display("----------------------------------------------------------------");
    $display("   golden_complete = %0d, golden_warn_msg = %0s", golden_complete, str_warn_msg[golden_warn_msg]);
    $display("   inf.complete    = %0d, inf.warn_msg    = %0s", inf.complete, str_warn_msg[inf.warn_msg]);
    $display("----------------------------------------------------------------");
    $display("  ACTION: %0s, STRATEGY: %0s", str_action[action_buffer], str_strategy[strategy_buffer]);
    $display("  MODE: %0s", str_mode[mode_buffer]);
    $display("  CUR DATE: %0d/%0d, USED DATA_NO: %0d", month_buffer, day_buffer, data_no_buffer);
    $display("  RESTOCK AMT (ROSE): %0d", rstk_amt_buffer[0]);
    $display("  RESTOCK AMT (LILY): %0d", rstk_amt_buffer[1]);
    $display("  RESTOCK AMT (CARNATION): %0d", rstk_amt_buffer[2]);
    $display("  RESTOCK AMT (BABY BREATH): %0d", rstk_amt_buffer[3]);
    $display("================================================================");
end endtask


//================================================================
// CALCULATE GOLDEN RESULT
//================================================================

task calc_check_valid_date_task; begin
    integer                    real_addr;
    logic [4:0]          golden_dram_day;
    logic [3:0]        golden_dram_month;
    logic [11:0]        golden_dram_rose;
    logic [11:0]        golden_dram_lily;
    logic [11:0]   golden_dram_carnation;
    logic [11:0] golden_dram_baby_breath;
    logic [63:0]     golden_dram_temp_64;


    real_addr           = 65536 + (data_no_buffer * 8);
    golden_dram_temp_64 = {golden_DRAM[real_addr+7], golden_DRAM[real_addr+6], golden_DRAM[real_addr+5], golden_DRAM[real_addr+4],
                           golden_DRAM[real_addr+3], golden_DRAM[real_addr+2], golden_DRAM[real_addr+1], golden_DRAM[real_addr]};
    golden_dram_day         = golden_dram_temp_64[4 : 0]; // [7:0]   -> [4:0]
    golden_dram_baby_breath = golden_dram_temp_64[19: 8];
    golden_dram_carnation   = golden_dram_temp_64[31:20];
    golden_dram_month       = golden_dram_temp_64[39:32]; // [39:32] -> [35:32]
    golden_dram_lily        = golden_dram_temp_64[51:40];
    golden_dram_rose        = golden_dram_temp_64[63:52];

    global_real_addr          = real_addr;
    original_dram_day         = golden_dram_day;
    original_dram_month       = golden_dram_month;
    original_dram_rose        = golden_dram_rose;
    original_dram_lily        = golden_dram_lily;
    original_dram_carnation   = golden_dram_carnation;
    original_dram_baby_breath = golden_dram_baby_breath;

    golden_warn_msg = No_Warn;
    golden_complete = 1'b1;

    if (month_buffer < golden_dram_month) begin
        golden_warn_msg = Date_Warn;
        golden_complete = 1'b0;
    end
    else if (month_buffer === golden_dram_month) begin
        if (day_buffer < golden_dram_day) begin
            golden_warn_msg = Date_Warn;
            golden_complete = 1'b0;
        end
    end
end endtask

task calc_restock_task; begin
    integer                    real_addr;
    logic [4:0]          golden_dram_day;
    logic [3:0]        golden_dram_month;
    logic [11:0]        golden_dram_rose;
    logic [11:0]        golden_dram_lily;
    logic [11:0]   golden_dram_carnation;
    logic [11:0] golden_dram_baby_breath;
    logic [63:0]     golden_dram_temp_64;
    integer               temp_rstk_rose;
    integer               temp_rstk_lily;
    integer          temp_rstk_carnation;
    integer        temp_rstk_baby_breath;
    

    real_addr               = 65536 + (data_no_buffer * 8);
    golden_dram_temp_64     = {golden_DRAM[real_addr+7], golden_DRAM[real_addr+6], golden_DRAM[real_addr+5], golden_DRAM[real_addr+4],
                               golden_DRAM[real_addr+3], golden_DRAM[real_addr+2], golden_DRAM[real_addr+1], golden_DRAM[real_addr]};
    golden_dram_day         = golden_dram_temp_64[4 : 0]; // [7:0]   -> [4:0]
    golden_dram_baby_breath = golden_dram_temp_64[19: 8];
    golden_dram_carnation   = golden_dram_temp_64[31:20];
    golden_dram_month       = golden_dram_temp_64[39:32]; // [39:32] -> [35:32]
    golden_dram_lily        = golden_dram_temp_64[51:40];
    golden_dram_rose        = golden_dram_temp_64[63:52];

    global_real_addr          = real_addr;
    original_dram_day         = golden_dram_day;
    original_dram_month       = golden_dram_month;
    original_dram_rose        = golden_dram_rose;
    original_dram_lily        = golden_dram_lily;
    original_dram_carnation   = golden_dram_carnation;
    original_dram_baby_breath = golden_dram_baby_breath;


    golden_warn_msg         = No_Warn;
    golden_complete         = 1'b1;

    temp_rstk_rose = golden_dram_rose + rstk_amt_buffer[0];
    if (temp_rstk_rose > 4095) begin
        golden_warn_msg = Restock_Warn;
        golden_complete = 1'b0;
        temp_rstk_rose  = 4095;
    end

    temp_rstk_lily = golden_dram_lily + rstk_amt_buffer[1];
    if (temp_rstk_lily > 4095) begin
        golden_warn_msg = Restock_Warn;
        golden_complete = 1'b0;
        temp_rstk_lily  = 4095;
    end

    temp_rstk_carnation = golden_dram_carnation + rstk_amt_buffer[2];
    if (temp_rstk_carnation > 4095) begin
        golden_warn_msg = Restock_Warn;
        golden_complete = 1'b0;
        temp_rstk_carnation  = 4095;
    end

    temp_rstk_baby_breath = golden_dram_baby_breath + rstk_amt_buffer[3];
    if (temp_rstk_baby_breath > 4095) begin
        golden_warn_msg = Restock_Warn;
        golden_complete = 1'b0;
        temp_rstk_baby_breath  = 4095;
    end

    golden_dram_temp_64 = {temp_rstk_rose     [11:0], temp_rstk_lily       [11:0], 4'b0000, month_buffer, 
                           temp_rstk_carnation[11:0], temp_rstk_baby_breath[11:0], 3'b000,  day_buffer};

    golden_DRAM[real_addr+7] = golden_dram_temp_64[63:56];
    golden_DRAM[real_addr+6] = golden_dram_temp_64[55:48];
    golden_DRAM[real_addr+5] = golden_dram_temp_64[47:40];
    golden_DRAM[real_addr+4] = golden_dram_temp_64[39:32];
    golden_DRAM[real_addr+3] = golden_dram_temp_64[31:24];
    golden_DRAM[real_addr+2] = golden_dram_temp_64[23:16];
    golden_DRAM[real_addr+1] = golden_dram_temp_64[15: 8];
    golden_DRAM[real_addr+0] = golden_dram_temp_64[ 7: 0];
    waddr_queue.push_back(real_addr);
    wdata_queue.push_back(golden_dram_temp_64);;
    
end endtask

task calc_purchase_task; begin
    integer                    real_addr;
    logic [4:0]          golden_dram_day;
    logic [3:0]        golden_dram_month;
    logic [11:0]        golden_dram_rose;
    logic [11:0]        golden_dram_lily;
    logic [11:0]   golden_dram_carnation;
    logic [11:0] golden_dram_baby_breath;
    logic [63:0]     golden_dram_temp_64;
    integer           temp_purchase_rose;
    integer           temp_purchase_lily;
    integer      temp_purchase_carnation;
    integer    temp_purchase_baby_breath;

    integer      base_number_to_purchase;

    integer final_purchase_rose;
    integer final_purchase_lily;
    integer final_purchase_carnation;
    integer final_purchase_baby_breath;
    

    real_addr               = 65536 + (data_no_buffer * 8);
    golden_dram_temp_64     = {golden_DRAM[real_addr+7], golden_DRAM[real_addr+6], golden_DRAM[real_addr+5], golden_DRAM[real_addr+4],
                               golden_DRAM[real_addr+3], golden_DRAM[real_addr+2], golden_DRAM[real_addr+1], golden_DRAM[real_addr]};
    golden_dram_day         = golden_dram_temp_64[4 : 0]; // [7:0]   -> [4:0]
    golden_dram_baby_breath = golden_dram_temp_64[19: 8];
    golden_dram_carnation   = golden_dram_temp_64[31:20];
    golden_dram_month       = golden_dram_temp_64[39:32]; // [39:32] -> [35:32]
    golden_dram_lily        = golden_dram_temp_64[51:40];
    golden_dram_rose        = golden_dram_temp_64[63:52];

    global_real_addr          = real_addr;
    original_dram_day         = golden_dram_day;
    original_dram_month       = golden_dram_month;
    original_dram_rose        = golden_dram_rose;
    original_dram_lily        = golden_dram_lily;
    original_dram_carnation   = golden_dram_carnation;
    original_dram_baby_breath = golden_dram_baby_breath;

    golden_warn_msg         = No_Warn;
    golden_complete         = 1'b1;

    if (mode_buffer === Single) begin
        base_number_to_purchase = 120;
    end
    else if (mode_buffer === Group_Order) begin
        base_number_to_purchase = 480;
    end
    else if (mode_buffer === Event) begin
        base_number_to_purchase = 960;
    end
    else begin
        $display("ERROR: Invalid mode, %0d", mode_buffer);
        $fatal;
    end

    if (strategy_buffer === Strategy_A) begin
        temp_purchase_rose        = base_number_to_purchase;
        temp_purchase_lily        = 0;
        temp_purchase_carnation   = 0;
        temp_purchase_baby_breath = 0;
    end
    else if (strategy_buffer === Strategy_B) begin
        temp_purchase_rose        = 0;
        temp_purchase_lily        = base_number_to_purchase;
        temp_purchase_carnation   = 0;
        temp_purchase_baby_breath = 0;
    end
    else if (strategy_buffer === Strategy_C) begin
        temp_purchase_rose        = 0;
        temp_purchase_lily        = 0;
        temp_purchase_carnation   = base_number_to_purchase;
        temp_purchase_baby_breath = 0;
    end
    else if (strategy_buffer === Strategy_D) begin
        temp_purchase_rose        = 0;
        temp_purchase_lily        = 0;
        temp_purchase_carnation   = 0;
        temp_purchase_baby_breath = base_number_to_purchase;
    end
    else if (strategy_buffer === Strategy_E) begin
        temp_purchase_rose        = base_number_to_purchase/2;
        temp_purchase_lily        = base_number_to_purchase/2;
        temp_purchase_carnation   = 0;
        temp_purchase_baby_breath = 0;
    end
    else if (strategy_buffer === Strategy_F) begin
        temp_purchase_rose        = 0;
        temp_purchase_lily        = 0;
        temp_purchase_carnation   = base_number_to_purchase/2;
        temp_purchase_baby_breath = base_number_to_purchase/2;
    end
    else if (strategy_buffer === Strategy_G) begin
        temp_purchase_rose        = base_number_to_purchase/2;
        temp_purchase_lily        = 0;
        temp_purchase_carnation   = base_number_to_purchase/2;
        temp_purchase_baby_breath = 0;
    end
    else if (strategy_buffer === Strategy_H) begin
        temp_purchase_rose        = base_number_to_purchase / 4;
        temp_purchase_lily        = base_number_to_purchase / 4;
        temp_purchase_carnation   = base_number_to_purchase / 4;
        temp_purchase_baby_breath = base_number_to_purchase / 4;
    end
    else begin
        $display("ERROR: Invalid strategy");
        $fatal;
    end

    golden_complete = 1'b1;
    golden_warn_msg = No_Warn;

    if (golden_dram_rose < temp_purchase_rose) begin
        golden_warn_msg = Stock_Warn;
        golden_complete = 1'b0;
    end
    else begin
        final_purchase_rose = golden_dram_rose - temp_purchase_rose;
    end

    if (golden_dram_lily < temp_purchase_lily) begin
        golden_warn_msg = Stock_Warn;
        golden_complete = 1'b0;
    end
    else begin
        final_purchase_lily = golden_dram_lily - temp_purchase_lily;
    end

    if (golden_dram_carnation < temp_purchase_carnation) begin
        golden_warn_msg = Stock_Warn;
        golden_complete = 1'b0;
    end
    else begin
        final_purchase_carnation = golden_dram_carnation - temp_purchase_carnation;
    end

    if (golden_dram_baby_breath < temp_purchase_baby_breath) begin
        golden_warn_msg = Stock_Warn;
        golden_complete = 1'b0;
    end
    else begin
        final_purchase_baby_breath = golden_dram_baby_breath - temp_purchase_baby_breath;
    end


    if (month_buffer < golden_dram_month) begin
        golden_warn_msg = Date_Warn;
        golden_complete = 1'b0;
    end
    else if (month_buffer === golden_dram_month) begin
        if (day_buffer < golden_dram_day) begin
            golden_warn_msg = Date_Warn;
            golden_complete = 1'b0;
        end
    end

    if (golden_complete === 1'b1) begin
        golden_dram_temp_64 = {final_purchase_rose     [11:0], final_purchase_lily       [11:0], 4'b0000, golden_dram_month, 
                               final_purchase_carnation[11:0], final_purchase_baby_breath[11:0], 3'b000,  golden_dram_day};

        golden_DRAM[real_addr+7] = golden_dram_temp_64[63:56];
        golden_DRAM[real_addr+6] = golden_dram_temp_64[55:48];
        golden_DRAM[real_addr+5] = golden_dram_temp_64[47:40];
        golden_DRAM[real_addr+4] = golden_dram_temp_64[39:32];
        golden_DRAM[real_addr+3] = golden_dram_temp_64[31:24];
        golden_DRAM[real_addr+2] = golden_dram_temp_64[23:16];
        golden_DRAM[real_addr+1] = golden_dram_temp_64[15: 8];
        golden_DRAM[real_addr+0] = golden_dram_temp_64[ 7: 0];
        waddr_queue.push_back(real_addr);
        wdata_queue.push_back(golden_dram_temp_64);
        // $display("purchase push_back: %0h", golden_dram_temp_64);
        // $display("addr: %0h", real_addr);

    end

end endtask


task pass_task; begin
    $display("Congratulations");
end endtask

task fail_task; begin
    $display("Wrong Answer");
    $fatal;
end endtask


endprogram
