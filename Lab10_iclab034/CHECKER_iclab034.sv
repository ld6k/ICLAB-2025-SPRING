/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab10: SystemVerilog Coverage & Assertion
File Name   : CHECKER.sv
Module Name : CHECKER
Release version : v1.0 (Release Date: May-2025)
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/

`include "Usertype.sv"
module Checker(input clk, INF.CHECKER inf);
import usertype::*;

integer fp_w;

initial begin
    fp_w = $fopen("out_valid.txt", "w");
end


/**
 * This section contains the definition of the class and the instantiation of the object.
 *  * 
 * The always_ff blocks update the object based on the values of valid signals.
 * When valid signal is true, the corresponding property is updated with the value of inf.D
 */

class Strategy_and_mode;
    Strategy_Type f_type;
    Mode f_mode;
endclass
Strategy_and_mode fm_info = new();

always_comb begin
    if (inf.strategy_valid) begin
        fm_info.f_type = inf.D.d_strategy[0];    // store the Strategy_Type
    end
    if (inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];        // store the Mode
    end
end


// ====================================================== //
// | COVERAGE
// |----------------------------------------------------- //
// |                                  ... specification
// ====================================================== //

// -------------------------------------------------------//
// | SPEC 1, 2, 3
// | strategy and mode and cross each for 100 times
// -------------------------------------------------------//

covergroup SPEC1 @(posedge clk iff inf.strategy_valid);
    option.per_instance = 1;
    group_strat: coverpoint inf.D.d_strategy[0] {
        bins A          = {Strategy_A};
        bins B          = {Strategy_B};
        bins C          = {Strategy_C};
        bins D          = {Strategy_D};
        bins E          = {Strategy_E};
        bins F          = {Strategy_F};
        bins G          = {Strategy_G};
        bins H          = {Strategy_H};
        option.at_least = 100;
    }
endgroup
SPEC1 strat_group = new();

covergroup SPEC2 @(posedge clk iff inf.mode_valid);
    option.per_instance = 1;
    group_mode: coverpoint inf.D.d_mode[0] {
        bins Single      = {Single};
        bins GroupOrder  = {Group_Order};
        bins Event       = {Event};
        option.at_least  = 100;
    }
endgroup
SPEC2 mode_group = new();

covergroup SPEC3 @(posedge clk iff inf.mode_valid);
    option.per_instance = 1;
    group_mode_cross_strat: cross fm_info.f_mode, fm_info.f_type {
        option.at_least  = 100;
    }
endgroup
SPEC3 mode_cross_strat_group = new();

// -------------------------------------------------------//
// | SPEC 4
// | warn_msg each for 10 times
// -------------------------------------------------------//
covergroup SPEC4 @(posedge clk iff inf.out_valid);
    option.per_instance = 1;
    group_warn : coverpoint inf.warn_msg {
        bins No_Warn      =      {No_Warn};
        bins Date_Warn    =    {Date_Warn};
        bins Stock_Warn   =   {Stock_Warn};
        bins Restock_Warn = {Restock_Warn};
        option.at_least   = 10;
    }
endgroup
SPEC4 warn_msg_group = new();


// -------------------------------------------------------//
// | SPEC 5
// | Transistion bin
// -------------------------------------------------------//
covergroup SPEC5 @(posedge clk iff inf.sel_action_valid);
    option.per_instance = 1;
    group_act : coverpoint inf.D.d_act[0] {
        bins purchase_to_cvd[] = ([Purchase:Check_Valid_Date] => [Purchase:Check_Valid_Date]);
        option.at_least        = 300;
    }
endgroup
SPEC5 act_trans_group = new();


// -------------------------------------------------------//
// | SPEC 6
// | 32 bin for each restock amount
// -------------------------------------------------------//
covergroup SPEC6 @(posedge clk iff inf.restock_valid);
    option.per_instance = 1;
    group_rstk_amt : coverpoint inf.D.d_stock[0] {
        option.auto_bin_max = 32;
        option.at_least     = 1;
    }
endgroup
SPEC6 rstk_amt_group = new();

// ====================================================== //
// | ASSERTIONS
// |----------------------------------------------------- //
// |                                  ... specification
// ====================================================== //
Action   f_action;
Date       f_date;
Data_No f_data_no;
Stock     f_stock;
integer cc_count;

initial begin
    cc_count = 0;
end

always @(negedge clk) begin
    if (inf.data_no_valid || inf.out_valid || inf.restock_valid) begin
        cc_count <= 0;
    end
    else begin
        cc_count <= cc_count + 1;
    end
end

always @(*) begin
    if (inf.sel_action_valid) begin
        f_action = inf.D.d_act[0];
    end
    if (inf.strategy_valid) begin
        fm_info.f_type = inf.D.d_strategy[0];
    end
    if (inf.mode_valid) begin
        fm_info.f_mode = inf.D.d_mode[0];
    end
    if (inf.date_valid) begin
        f_date = inf.D.d_date[0];
    end
    if (inf.data_no_valid) begin
        f_data_no = inf.D.d_data_no[0];
    end
    if (inf.restock_valid) begin
        f_stock = inf.D.d_stock[0];
    end
end

// -------------------------------------------------------//
// | SPEC 1
// | RESET
// -------------------------------------------------------//

assertion_1_reset_1:
    assert property (
        @(posedge inf.rst_n)
        (inf.rst_n === 1'b0)
        |-> 
        (  inf.out_valid  === 0 && inf.warn_msg === 0 
        && inf.complete   === 0 && inf.AR_VALID === 0 
        && inf.AR_ADDR    === 0 && inf.R_READY  === 0 
        && inf.AW_VALID   === 0 && inf.AW_ADDR  === 0 
        && inf.W_VALID    === 0 && inf.W_DATA   === 0
        && inf.B_READY    === 0)
    )
    else
    begin
        $display("Assertion 1 is violated");
        $fwrite(fp_w, "Assertion 1 is violated\n");
        $fatal;
    end


// -------------------------------------------------------//
// | SPEC 2
// | Time Exceeded
// -------------------------------------------------------//

// ---------------------------------------//
// | RESTOCK
// ---------------------------------------//
sequence four_restock_cycles_to_tle;
    ##[1:1000]    inf.date_valid
    ##[1:1000] inf.data_no_valid
    ##[1:1000] inf.restock_valid
    ##[1:1000] inf.restock_valid
    ##[1:1000] inf.restock_valid
    ##[1:1000] inf.restock_valid
    ##[1:1000]     inf.out_valid;
endsequence

assertion_2_time_exceeded_at_restock:
    assert property (
        @(posedge clk) // posedge maybe
        (inf.sel_action_valid && (inf.D.d_act[0] === Restock))
        |-> 
        (four_restock_cycles_to_tle) 
    )
    else 
    begin
        $display("Assertion 2 is violated");
        $fwrite(fp_w, "Assertion 2 is violated\n");
        $fatal;
    end

// ---------------------------------------//
// | PURCHASE
// ---------------------------------------//
sequence four_prchs_cycles_to_tle;
    ##[1:1000] inf.strategy_valid
    ##[1:1000]     inf.mode_valid
    ##[1:1000]     inf.date_valid
    ##[1:1000]  inf.data_no_valid
    ##[1:1000]      inf.out_valid;
endsequence

assertion_2_time_exceeded_at_purchase:
    assert property (
        @(posedge clk)
        (inf.sel_action_valid && (inf.D.d_act[0] === Purchase)) 
        |->
        (four_prchs_cycles_to_tle)
    )
    else 
    begin
        $display("Assertion 2 is violated");
        $fwrite(fp_w, "Assertion 2 is violated\n");
        $fatal;
    end

// ---------------------------------------//
// | CHECK VALID DATE
// ---------------------------------------//
sequence four_prchs_chck_vld_dt_to_tle;
    ##[1:1000]     inf.date_valid
    ##[1:1000]  inf.data_no_valid
    ##[1:1000]      inf.out_valid;
endsequence

assertion_2_time_exceeded_at_cvd:
    assert property (
        @(posedge clk)
        (inf.sel_action_valid && (inf.D.d_act[0] === Check_Valid_Date)) 
        |->
        (four_prchs_chck_vld_dt_to_tle)
    )
    else 
    begin
        $display("Assertion 2 is violated");
        $fwrite(fp_w, "Assertion 2 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 3
// | Warn_msg
// -------------------------------------------------------//

assertion_3_warn_msg_shall_be_00_when_complete_is_1:
    assert property (
        @(negedge clk)
        (inf.complete === 1) 
        |-> 
        (inf.warn_msg === No_Warn)
    )
    else 
    begin
        $display("Assertion 3 is violated");
        $fwrite(fp_w, "Assertion 3 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 4
// | next valid 1-4 cycles
// -------------------------------------------------------//

// ---------------------------------------//
// | RESTOCK
// ---------------------------------------//
sequence next_valid_1_4_cycles_restock;
    ##[1:4] inf.date_valid
    ##[1:4] inf.data_no_valid
    ##[1:4] inf.restock_valid
    ##[1:4] inf.restock_valid
    ##[1:4] inf.restock_valid
    ##[1:4] inf.restock_valid;
endsequence

property p_restock_next_valids;
    @(negedge clk)
    (inf.sel_action_valid && (inf.D.d_act[0] === Restock))
    |->
    next_valid_1_4_cycles_restock;
endproperty

assertion_4_next_valid_1_4_cycles_restock:
    assert property (p_restock_next_valids)
    else 
    begin
        $display("Assertion 4 is violated");
        $fwrite(fp_w, "Assertion 4 is violated\n");
        $fatal;
    end

// ---------------------------------------//
// | PURCHASE
// ---------------------------------------//
sequence next_valid_1_4_cycles_purchase;
    ##[1:4] inf.strategy_valid
    ##[1:4] inf.mode_valid
    ##[1:4] inf.date_valid
    ##[1:4] inf.data_no_valid;
endsequence

property p_purchase_next_valids;
    @(negedge clk) // TODO: write pattern to check if negedge clk really works
    (inf.sel_action_valid && (inf.D.d_act[0] === Purchase))
    |->
    next_valid_1_4_cycles_purchase;
endproperty

assertion_4_next_valid_1_4_cycles_purchase:
    assert property (p_purchase_next_valids)
    else 
    begin
        $display("Assertion 4 is violated");
        $fwrite(fp_w, "Assertion 4 is violated\n");
        $fatal;
    end

// ---------------------------------------//
// | CHECK VALID DATE
// ---------------------------------------//
sequence next_valid_1_4_cycles_cvd;
    ##[1:4] inf.date_valid
    ##[1:4] inf.data_no_valid;
endsequence

property p_cvd_next_valids;
    @(negedge clk)
    (inf.sel_action_valid && (inf.D.d_act[0] === Check_Valid_Date))
    |->
    next_valid_1_4_cycles_cvd;
endproperty

assertion_4_next_valid_1_4_cycles_cvd:
    assert property (p_cvd_next_valids)
    else 
    begin
        $display("Assertion 4 is violated");
        $fwrite(fp_w, "Assertion 4 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 5
// | input valid overlap
// -------------------------------------------------------//

assertion_5_sel_action_valid_valid_overlap:
    assert property (
        @(posedge clk)
        (  !(inf.sel_action_valid === 1 && inf.strategy_valid === 1) 
        && !(inf.sel_action_valid === 1 && inf.mode_valid     === 1)   
        && !(inf.sel_action_valid === 1 && inf.date_valid     === 1)   
        && !(inf.sel_action_valid === 1 && inf.data_no_valid  === 1) 
        && !(inf.sel_action_valid === 1 && inf.restock_valid  === 1))
    )
    else
    begin
        $display("Assertion 5 is violated");
        $fwrite(fp_w, "Assertion 5 is violated\n");
        $fatal;
    end

assertion_5_strategy_valid_valid_overlap:
    assert property (
        @(posedge clk)
        (  !(inf.strategy_valid === 1 && inf.mode_valid    === 1) 
        && !(inf.strategy_valid === 1 && inf.date_valid    === 1)
        && !(inf.strategy_valid === 1 && inf.data_no_valid === 1) 
        && !(inf.strategy_valid === 1 && inf.restock_valid === 1))
    )
    else
    begin
        $display("Assertion 5 is violated");
        $fwrite(fp_w, "Assertion 5 is violated\n");
        $fatal;
    end

assertion_5_mode_valid_valid_overlap:
    assert property (
        @(posedge clk)
        (  !(inf.mode_valid === 1 && inf.date_valid    === 1)  
        && !(inf.mode_valid === 1 && inf.data_no_valid === 1) 
        && !(inf.mode_valid === 1 && inf.restock_valid === 1))
    )
    else
    begin
        $display("Assertion 5 is violated");
        $fwrite(fp_w, "Assertion 5 is violated\n");
        $fatal;
    end

assertion_5_date_valid_valid_overlap:
    assert property (
        @(posedge clk)
        (  !(inf.date_valid === 1 && inf.data_no_valid === 1) 
        && !(inf.date_valid === 1 && inf.restock_valid === 1))
    )
    else
    begin
        $display("Assertion 5 is violated");
        $fwrite(fp_w, "Assertion 5 is violated\n");
        $fatal;
    end

assertion_5_data_no_valid_valid_overlap:
    assert property (
        @(posedge clk)
        (!(inf.data_no_valid === 1 && inf.restock_valid === 1))
    )
    else
    begin
        $display("Assertion 5 is violated");
        $fwrite(fp_w, "Assertion 5 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 6
// | output valid only one cycle
// -------------------------------------------------------//

assertion_6_out_valid_only_one_cycle:
    assert property (
        @(negedge clk) // negedge to check design will be faster
        (inf.out_valid === 1)
        |=>
        (inf.out_valid === 0)
    )
    else
    begin
        $display("Assertion 6 is violated");
        $fwrite(fp_w, "Assertion 6 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 7
// | input 1-4 cycles after out_valid falls
// -------------------------------------------------------//

assertion_7_sel_action_valid_1_4_cycles:
    assert property (
        @(posedge clk) // posedge for this I guess
        (inf.out_valid === 1) 
        |-> 
        ##[1:4] (inf.sel_action_valid === 1)
    )
    else
    begin
        $display("Assertion 7 is violated");
        $fwrite(fp_w, "Assertion 7 is violated\n");
        $fatal;
    end

// -------------------------------------------------------//
// | SPEC 8
// | input date shall adhere real calender
// -------------------------------------------------------//

function bit is_31day_month(int unsigned M);
    return ((M === 1) || (M === 3) ||(M === 5) ||(M === 7) ||(M === 8) || (M === 10) || (M === 12));
endfunction

function bit is_30day_month(int unsigned M);
    return ((M === 4) || (M === 6) || (M === 9) || (M === 11));
endfunction

property p_real_date;
    @(posedge clk)
    inf.date_valid |->
    ((inf.D.d_date[0].M inside {[1:12]})
     && ( (is_31day_month(inf.D.d_date[0].M) && inf.D.d_date[0].D inside {[1:31]})
        ||(is_30day_month(inf.D.d_date[0].M) && inf.D.d_date[0].D inside {[1:30]})
        ||(inf.D.d_date[0].M == 2            && inf.D.d_date[0].D inside {[1:28]}))
    );
endproperty

assertion_8_input_date_shall_adhere_real_calender:
    assert property 
            (p_real_date)
        else begin
            $display("Assertion 8 is violated");
            $fwrite(fp_w, "Assertion 8 is violated\n");
            $fatal;
        end

// -------------------------------------------------------//
// | SPEC 9
// | AR/AW overlap
// -------------------------------------------------------//

property p_no_ar_aw_overlap;
    @(negedge clk)
    (inf.AR_VALID === 1)
    |->
    (inf.AW_VALID === 0);
endproperty

assertion_9_aw_ar_overlap:
    assert property (p_no_ar_aw_overlap)
        else begin
            $display("Assertion 9 is violated");
            $fwrite(fp_w, "Assertion 9 is violated\n");
            $fatal;
        end

endmodule