//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2021 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2021-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
       bready_m_inf,
                    
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
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output logic  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/

// axi write address channel 
output  logic [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  logic [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  logic [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  logic [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  logic [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  logic [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   logic [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  logic [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  logic [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  logic [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   logic [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   logic [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   logic [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   logic [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  logic [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  logic [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  logic [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  logic [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  logic [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  logic [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  logic [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   logic [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   logic [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   logic [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   logic [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   logic [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   logic [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  logic [DRAM_NUMBER-1:0]                 rready_m_inf;

// -----------------------------
typedef enum logic [2:0] {
    S_PRE_IF   = 3'b000,
    S_IF       = 3'b001,
    S_ID       = 3'b010,
    S_EXE      = 3'b011,
    S_PRE_MEM  = 3'b100,
    S_MEM      = 3'b101,
    S_WB       = 3'b110,
    S_BURST_WRITE_BACK = 3'b111
} cpu_state_t;

typedef enum logic [2:0] {
    CACHE_IDLE        = 3'b000,
    CACHE_AW = 3'b001,
    CACHE_BURST_WRITE = 3'b010,
    CACHE_AR          = 3'b011,
    CACHE_BURST       = 3'b100
} cache_state_t;

/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0,  core_r1,  core_r2,  core_r3;
reg signed [15:0] core_r4,  core_r5,  core_r6,  core_r7;
reg signed [15:0] core_r8,  core_r9,  core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

// end of the do not touch area.

cpu_state_t                      state;
cpu_state_t                 next_state;
cache_state_t              cache_state;
cache_state_t         next_cache_state;
logic                       cache_we_r;
reg                   type_add_sub_slt;
reg                          type_mult;
reg                             type_j;
logic                    i_cache_hit_r;
reg                           type_beq;
reg                            type_lw;
reg                            type_sw;

logic [15:0]                   rdata_r;

logic [10:0]                      pc_r;
logic [3 :0]             i_cache_tag_r;
logic [3 :0]             d_cache_tag_r;

logic [15:0] current_exe_instruction_r;
logic [2:0]                  op_code_r;

logic signed [15:0]   RS_r, RT_r, RD_r;
logic [15:0]          resgister_file_w [0:15];
logic [3 :0]                  RS_idx_w;
logic [3 :0]                  RT_idx_w;
logic [3 :0]                  RD_idx_w;
logic [15:0]               cache_din_r;
logic                         rvalid_r;
logic transaction_on_the_fly;
// -----------------------------------------------------
// ALU operations
// -----------------------------------------------------
logic signed [15:0] ALU_result_add_w;
logic signed [15:0] ALU_result_sub_w;
logic signed [15:0] ALU_result_slt_w;
logic signed [31:0] ALU_result_mult_w;
logic [11:0] calc_data_addr_r;
logic [11:0] wb_data_addr_r;
logic rlast_r;
logic rlast_delay_r;
logic [4:0] imm5_w;
logic d_cache_hit_w;
logic d_cache_hit_r;
logic i_cache_hit_w;
logic i_cache_empty_r;
logic d_cache_empty_r;
logic wb_finish;
logic [3:0] RT_idx_cur_w;
logic is_sw_r;
logic is_lw_r;
logic is_beq_r;
logic    is_j_r;
logic       fetching_1i0d;
logic [15:0] cache_dout_w;
logic [15:0] cache_dout_r;
logic [6 :0] cache_addr_r;
logic multi_dirty;
logic [6:0] wb_lower_bound_r;
logic [6:0] wb_upper_bound_r;
logic [6:0] len_r;
logic cache_state_cnt_r;

logic [11:0] sw_burst_write_lower_addr_r;
logic [11:0] sw_burst_write_upper_addr_r;

logic dirty;

logic wb_en;
logic one_r;
logic mult_stage;
logic [3:0] ten_inst_cnt;

assign ALU_result_add_w  = RS_r + RT_r;
assign ALU_result_sub_w  = RS_r - RT_r;
assign ALU_result_slt_w  = (RS_r < RT_r) ? 16'h0001 : 16'h0000;
// assign ALU_result_mult_w = RS_r * RT_r;
DW02_mult_2_stage #(16, 16) ALU_mult_ip ( 
    .A(RS_r),
    .B(RT_r),
    .TC(1'd1),
    .CLK(clk),
    .PRODUCT(ALU_result_mult_w) 
);


//####################################################
//               reg & wire
//####################################################

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        core_r0  <= 16'h0000;  core_r1 <= 16'h0000;  core_r2 <= 16'h0000;  core_r3 <= 16'h0000;
        core_r4  <= 16'h0000;  core_r5 <= 16'h0000;  core_r6 <= 16'h0000;  core_r7 <= 16'h0000;
        core_r8  <= 16'h0000;  core_r9 <= 16'h0000; core_r10 <= 16'h0000; core_r11 <= 16'h0000;
        core_r12 <= 16'h0000; core_r13 <= 16'h0000; core_r14 <= 16'h0000; core_r15 <= 16'h0000;
    end
    else if (state == S_WB && !is_sw_r) begin
        if (!is_lw_r) begin
            case(RD_idx_w)
                4'b0000: core_r0  <= RD_r;
                4'b0001: core_r1  <= RD_r;
                4'b0010: core_r2  <= RD_r;
                4'b0011: core_r3  <= RD_r;
                4'b0100: core_r4  <= RD_r;
                4'b0101: core_r5  <= RD_r;
                4'b0110: core_r6  <= RD_r;
                4'b0111: core_r7  <= RD_r;
                4'b1000: core_r8  <= RD_r;
                4'b1001: core_r9  <= RD_r;
                4'b1010: core_r10 <= RD_r;
                4'b1011: core_r11 <= RD_r;
                4'b1100: core_r12 <= RD_r;
                4'b1101: core_r13 <= RD_r;
                4'b1110: core_r14 <= RD_r;
                4'b1111: core_r15 <= RD_r;
            endcase
        end
        else begin
            case(RT_idx_cur_w)
                4'b0000: core_r0  <= cache_dout_r;
                4'b0001: core_r1  <= cache_dout_r;
                4'b0010: core_r2  <= cache_dout_r;
                4'b0011: core_r3  <= cache_dout_r;
                4'b0100: core_r4  <= cache_dout_r;
                4'b0101: core_r5  <= cache_dout_r;
                4'b0110: core_r6  <= cache_dout_r;
                4'b0111: core_r7  <= cache_dout_r;
                4'b1000: core_r8  <= cache_dout_r;
                4'b1001: core_r9  <= cache_dout_r;
                4'b1010: core_r10 <= cache_dout_r;
                4'b1011: core_r11 <= cache_dout_r;
                4'b1100: core_r12 <= cache_dout_r;
                4'b1101: core_r13 <= cache_dout_r;
                4'b1110: core_r14 <= cache_dout_r;
                4'b1111: core_r15 <= cache_dout_r;
            endcase
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        IO_stall <= 1'b1;
    end
    else begin
        if (next_state == S_BURST_WRITE_BACK || state == S_BURST_WRITE_BACK) begin
            if (wb_finish) begin
                IO_stall <= 1'b0; // Write back finished, no stall
            end
            else begin
                IO_stall <= 1'b1; // Still waiting for write back to finish
            end
        end
        else if (current_exe_instruction_r[15:14] == 2'b10 && state == S_EXE) begin
            IO_stall <= 1'b0; // J and BEQ
        end
        else if (state == S_WB) begin
            IO_stall <= 1'b0;
        end
        else begin
            IO_stall <= 1'b1;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        one_r <= 1'b0;
    end
    else begin
        one_r <= 1'b1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        ten_inst_cnt <= 4'd9;
    end
    else begin
        if (IO_stall == 1'b0 && ten_inst_cnt == 4'd9) begin
            ten_inst_cnt <= 0;
        end
        else if (IO_stall == 1'b0) begin
            ten_inst_cnt <= ten_inst_cnt + 1;
        end
    end
end

// -----------------------------------------------------
//   Cache
// -----------------------------------------------------

assign i_cache_hit_w = (pc_r            [10:7] == i_cache_tag_r) & !i_cache_empty_r;
assign d_cache_hit_w = (calc_data_addr_r[11:8] == d_cache_tag_r) & !d_cache_empty_r;

// always @(posedge clk, negedge rst_n) begin
//     if (!rst_n) begin
//         d_cache_hit_r <= 1'b0;
//         i_cache_hit_r <= 1'b0;
//     end
//     else begin
//         d_cache_hit_r <= d_cache_hit_w;
//         i_cache_hit_r <= i_cache_hit_w;
//     end
// end

always @(*) begin
    fetching_1i0d = 1'b0;
    if (state == S_PRE_IF || state == S_IF) begin
        fetching_1i0d = 1'b1;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        i_cache_empty_r <= 1'b1;
        d_cache_empty_r <= 1'b1;
        // -------------------------------------
        i_cache_tag_r <= 6'b0;
        d_cache_tag_r <= 6'b0;
    end
    else begin
        if (fetching_1i0d == 1'b1 && rlast_delay_r == 1'b1) begin
            i_cache_tag_r <= pc_r[10:7];
        end
        if (fetching_1i0d == 1'b0 && rlast_delay_r == 1'b1) begin
            d_cache_tag_r <= calc_data_addr_r[11:8];
        end
        // -------------------------------------
        if (fetching_1i0d == 1'b0 && rlast_delay_r == 1'b1) begin
            d_cache_empty_r <= 1'b0;
        end
        if (fetching_1i0d == 1'b1 && rlast_delay_r == 1'b1) begin
            i_cache_empty_r <= 1'b0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rlast_r   <= 1'b0;
        rlast_delay_r <= 'd0;
    end
    else begin
        rlast_r   <= |rlast_m_inf;
        rlast_delay_r <= rlast_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_state <= CACHE_IDLE;
    end
    else begin
        cache_state <= next_cache_state;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        dirty <= 1'b0;
        wb_lower_bound_r <= 7'b111_1111;
        wb_upper_bound_r <= 7'b000_0000;
    end
    else begin
        if (state == S_MEM && is_sw_r && d_cache_hit_w) begin
            dirty <= 1'b1; // Set dirty bit for SW instruction
            if (wb_lower_bound_r > calc_data_addr_r[7:1]) begin
                wb_lower_bound_r <= calc_data_addr_r[7:1]; // Update lower bound
            end
            if (wb_upper_bound_r < calc_data_addr_r[7:1]) begin
                wb_upper_bound_r <= calc_data_addr_r[7:1]; // Update upper bound
            end
        end
        else if ((cache_state == CACHE_BURST_WRITE && wb_finish)) begin
            dirty <= 1'b0; // Reset dirty bit after write back
            wb_lower_bound_r <= 7'b111_1111;
            wb_upper_bound_r <= 7'b000_0000; 
        end
    end
end

always @(*) begin
    next_cache_state = cache_state;
    case(cache_state)
        CACHE_IDLE: begin
            if ((state == S_PRE_IF && i_cache_hit_w == 1'b0)) begin
                next_cache_state = CACHE_AR;
            end
            else if (state == S_BURST_WRITE_BACK) begin
                next_cache_state = CACHE_AW; 
            end
            else if ((state == S_PRE_MEM && d_cache_hit_w == 1'b0)) begin
                if (dirty) begin
                    next_cache_state = CACHE_AW;
                end
                else begin
                    next_cache_state = CACHE_AR;
                end
            end
        end
        CACHE_AW: begin
            if (awready_m_inf) begin
                next_cache_state = CACHE_BURST_WRITE;
            end
        end
        CACHE_BURST_WRITE: begin
            if (wb_finish) begin
                if (state == S_BURST_WRITE_BACK) begin
                    next_cache_state = CACHE_IDLE;
                end
                else begin
                    next_cache_state = CACHE_AR;
                end
            end
        end
        CACHE_AR: begin
            if (|arready_m_inf) begin
                next_cache_state = CACHE_BURST;
            end
        end
        CACHE_BURST: begin
            if (rlast_delay_r) begin
                next_cache_state = CACHE_IDLE;
            end
        end
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_addr_r <= 7'h00;
    end
    else begin
        if (cache_state == CACHE_AR) begin
            cache_addr_r <= 0;
        end
        else if (cache_state == CACHE_AW) begin
            cache_addr_r <= wb_lower_bound_r;
        end
        else if (rvalid_r | wready_m_inf) begin
            cache_addr_r <= cache_addr_r + 1;
        end
        else if (cache_state == CACHE_IDLE && state == S_PRE_IF) begin
            cache_addr_r <= pc_r[7:0];
        end
        else if (cache_state == CACHE_IDLE && state == S_PRE_MEM) begin
            cache_addr_r <= calc_data_addr_r[8:1];
        end
    end
end

assign arid_m_inf    = 8'b0000_0000;


// -----------------------------------------------------
assign araddr_m_inf  = {16'b0, 4'b0001, pc_r[10:7], 8'b0, 16'b0, 4'b0001, calc_data_addr_r[11:8], 8'b0};
assign arsize_m_inf  = 6'b010010;
assign arburst_m_inf = 4'b0101;
assign arlen_m_inf   = 14'b1111111_1111111;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_din_r <= 16'h0000;
    end
    else begin
        if (state == S_MEM) begin
            cache_din_r <= RT_r;
        end
        else if (fetching_1i0d == 1'b1) begin
            cache_din_r <= rdata_m_inf[31:16]; 
        end
        else begin
            cache_din_r <= rdata_m_inf[15:0]; 
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rvalid_r <= 1'b0;
    end
    else begin
        rvalid_r <= |rvalid_m_inf;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_we_r <= 1'b1;
    end
    else begin
        if (cache_state == CACHE_BURST) begin
            cache_we_r <= ~(|rvalid_m_inf);
        end
        else if (state == S_MEM && is_sw_r && d_cache_hit_w) begin
            cache_we_r <= 1'b0; // Write enable for SW instruction
        end
        else begin
            cache_we_r <= 1'b1; // Disable write for other states
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        arvalid_m_inf <= 2'b00;
    end
    else begin
        if (arready_m_inf) begin
            arvalid_m_inf <= 2'b00;
        end
        else if (cache_state == CACHE_AR) begin
            if (fetching_1i0d == 1'b1) begin
                arvalid_m_inf[1] <= 1'b1;
            end
            else begin
                arvalid_m_inf[0] <= 1'b1;
            end
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_state_cnt_r <= 1'b0;
    end
    else begin
        if (state == S_IF || (state == S_MEM)) begin
            cache_state_cnt_r <= cache_state_cnt_r + 1;
        end
    end
end

// -----------------------------------------------------
//   PC
// -----------------------------------------------------

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        pc_r <= 11'h000;
    end
    else begin
        if (state == S_ID) begin
            pc_r <= pc_r + 1;
        end
        else if (state == S_EXE && is_beq_r && (RS_r == RT_r)) begin
            pc_r <= pc_r + {{8{current_exe_instruction_r[4]}}, current_exe_instruction_r[4:0]};
        end
        else if (state == S_EXE && is_j_r) begin
            pc_r <= current_exe_instruction_r[11:1];
        end
    end
end

assign RS_idx_w     =              cache_dout_r[12:9];
assign RT_idx_w     =              cache_dout_r[8 :5];
assign RD_idx_w     = current_exe_instruction_r[4 :1];
assign RT_idx_cur_w = current_exe_instruction_r[8 :5];
assign imm5_w       = current_exe_instruction_r[4 :0];

// assign resgister_file_w[ 0] =  core_r0;
// assign resgister_file_w[ 1] =  core_r1;
// assign resgister_file_w[ 2] =  core_r2;
// assign resgister_file_w[ 3] =  core_r3;
// assign resgister_file_w[ 4] =  core_r4;
// assign resgister_file_w[ 5] =  core_r5;
// assign resgister_file_w[ 6] =  core_r6;
// assign resgister_file_w[ 7] =  core_r7;
// assign resgister_file_w[ 8] =  core_r8;
// assign resgister_file_w[ 9] =  core_r9;
// assign resgister_file_w[10] = core_r10;
// assign resgister_file_w[11] = core_r11;
// assign resgister_file_w[12] = core_r12;
// assign resgister_file_w[13] = core_r13;
// assign resgister_file_w[14] = core_r14;
// assign resgister_file_w[15] = core_r15;

// -----------------------------------------------------
//   IF
// -----------------------------------------------------

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cache_dout_r <= 16'h0000;
    end
    else begin
        cache_dout_r <= cache_dout_w;
    end
end

// -----------------------------------------------------
//   ID
// -----------------------------------------------------

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        current_exe_instruction_r <= 16'h0000;
    end
    else begin
        if (state == S_ID) begin
            current_exe_instruction_r <= cache_dout_r;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        state <= S_PRE_IF;
    end
    else begin
        state <= next_state;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        mult_stage <= 1'b0;
    end
    else begin
        if (state == S_ID && cache_dout_r[13] == 1'b1 && cache_dout_r[0] == 1'b1) begin
            mult_stage <= 1'b1; // MULT instruction
        end
        else begin
            mult_stage <= 1'b0; // Reset for next instruction
        end
    end
end


always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        is_sw_r <= 1'b0;
    end
    else begin
        if (current_exe_instruction_r[15:13] == 3'b011) begin
            is_sw_r <= 1'b1; // SW instruction
        end
        else begin
            is_sw_r <= 1'b0; // Not SW instruction
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        is_beq_r <= 1'b0;
    end
    else begin
        if (state == S_ID) begin
            is_beq_r <= (cache_dout_r[15:13] == 3'b100) ? 1'b1 : 1'b0; // BEQ instruction
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        is_j_r <= 1'b0;
    end
    else begin
        if (state == S_ID) begin
            is_j_r <= (cache_dout_r[15:13] == 3'b101) ? 1'b1 : 1'b0; // BEQ instruction
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        is_lw_r <= 1'b0;
    end
    else begin
        if (current_exe_instruction_r[15:13] == 3'b010) begin
            is_lw_r <= 1'b1; 
        end
        else begin
            is_lw_r <= 1'b0;
        end
    end
end

always @(*) begin
    next_state = state;
    case(state)
        S_PRE_IF: begin // 0
            if (i_cache_hit_w == 1'b1) begin
                next_state = S_IF;
            end
        end
        S_IF: begin // 1
            if (cache_state_cnt_r == 1'b1) begin
                next_state = S_ID;
            end
        end
        S_ID: begin // 2
            next_state = S_EXE;
        end
        S_EXE: begin // 3
            if (current_exe_instruction_r[15:14] == 2'b01) begin
                next_state = S_PRE_MEM; // LW or SW
            end
            else if (current_exe_instruction_r[15:14] == 2'b10) begin
                if (ten_inst_cnt == 9 && dirty) begin
                    next_state = S_BURST_WRITE_BACK;
                end 
                else begin
                    next_state = S_PRE_IF; // BEQ or J
                end
            end
            else if (mult_stage == 1'b0) begin
                next_state = S_WB;
            end
        end
        S_PRE_MEM: begin // 4
            if (d_cache_hit_w == 1'b1) begin
                next_state = S_MEM;
            end
        end
        S_MEM: begin // 5
            if (cache_state_cnt_r == 1'b1) begin
                next_state = S_WB;
            end
        end
        S_WB: begin // 6
            if (ten_inst_cnt == 9 && dirty) begin
                next_state = S_BURST_WRITE_BACK;
            end
            else begin
                next_state = S_PRE_IF;
            end
        end
        S_BURST_WRITE_BACK: begin // 7
            if (wb_finish == 1'b1) begin
                next_state = S_PRE_IF;
            end
        end
    endcase
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        RS_r <= 16'h0000;
        RT_r <= 16'h0000;
    end
    else begin
        if (state == S_ID) begin
            case(RS_idx_w)
                4'b0000: RS_r <= core_r0;
                4'b0001: RS_r <= core_r1;
                4'b0010: RS_r <= core_r2;
                4'b0011: RS_r <= core_r3;
                4'b0100: RS_r <= core_r4;
                4'b0101: RS_r <= core_r5;
                4'b0110: RS_r <= core_r6;
                4'b0111: RS_r <= core_r7;
                4'b1000: RS_r <= core_r8;
                4'b1001: RS_r <= core_r9;
                4'b1010: RS_r <= core_r10;
                4'b1011: RS_r <= core_r11;
                4'b1100: RS_r <= core_r12;
                4'b1101: RS_r <= core_r13;
                4'b1110: RS_r <= core_r14;
                4'b1111: RS_r <= core_r15; // Default case
            endcase
            case(RT_idx_w)
                4'b0000: RT_r <= core_r0;
                4'b0001: RT_r <= core_r1;
                4'b0010: RT_r <= core_r2;
                4'b0011: RT_r <= core_r3;
                4'b0100: RT_r <= core_r4;
                4'b0101: RT_r <= core_r5;
                4'b0110: RT_r <= core_r6;
                4'b0111: RT_r <= core_r7;
                4'b1000: RT_r <= core_r8;
                4'b1001: RT_r <= core_r9;
                4'b1010: RT_r <= core_r10;
                4'b1011: RT_r <= core_r11;
                4'b1100: RT_r <= core_r12;
                4'b1101: RT_r <= core_r13;
                4'b1110: RT_r <= core_r14;
                4'b1111: RT_r <= core_r15; // Default case
            endcase
            // RS_r <= resgister_file_w[RS_idx_w];
            // RT_r <= resgister_file_w[RT_idx_w];
        end
    end
end

// -----------------------------------------------------
//   EXE
// -----------------------------------------------------

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        RD_r <= 16'h0000;
    end
    else begin
        case ({current_exe_instruction_r[13], current_exe_instruction_r[0]})
            2'b00: RD_r <= ALU_result_add_w;   // ADD
            2'b01: RD_r <= ALU_result_sub_w;   // SUB
            2'b10: RD_r <= ALU_result_slt_w;   // SLT
            2'b11: RD_r <= ALU_result_mult_w[15:0];  // MULT
        endcase
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        calc_data_addr_r <= 12'b0;
    end
    else begin
        calc_data_addr_r <= ((RS_r + {{11{imm5_w[4]}}, imm5_w}) << 1);
    end
end

// -----------------------------------------------------
//  Write Back Unit
// -----------------------------------------------------

assign wdata_m_inf   = cache_dout_r;
assign awid_m_inf    = 4'b0000;
assign awaddr_m_inf  = {20'b1, d_cache_tag_r, wb_lower_bound_r, 1'b0};
assign awsize_m_inf  = 3'b010;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf   = len_r;
assign bready_m_inf  = 1'b1;
assign wb_en = cache_state == CACHE_AW || cache_state == CACHE_BURST_WRITE;

logic [1:0] wvalid_cnt_r;
logic has_run_that_trick;
logic wlast_pre_r;

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        len_r <= 0;
    end
    else begin
        len_r <= wb_upper_bound_r - wb_lower_bound_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        wlast_pre_r <= 1'b0;
        wlast_m_inf <= 1'b0;
    end
    else begin
        if (dirty == 1'b1 && wb_lower_bound_r == wb_upper_bound_r) begin
            wlast_pre_r <= 1'b1;
        end
        else if (dirty == 1'b1 && wb_lower_bound_r != wb_upper_bound_r) begin
            wlast_pre_r <= (cache_addr_r == wb_upper_bound_r);
        end
        // else begin
        //     wlast_pre_r <= 1'b0; // Reset wlast_pre_r if not 
        // end
        wlast_m_inf <= wlast_pre_r;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        transaction_on_the_fly <= 1'b0;
    end
    else begin
        if (wb_en && wb_finish) begin
            transaction_on_the_fly <= 1'b0;
        end
        else if (wb_en && !wb_finish) begin
            transaction_on_the_fly <= 1'b1;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        wvalid_cnt_r <= 2'b0;
    end
    else begin
        if (wvalid_m_inf && wready_m_inf) begin
            wvalid_cnt_r <= 2'b0;
        end
        else if (wvalid_m_inf == 1'b0 && wready_m_inf) begin
            wvalid_cnt_r <= wvalid_cnt_r + 1;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        wb_finish <= 1'b0;
    end
    else begin
        wb_finish <= bvalid_m_inf;
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        awvalid_m_inf <= 1'b0;
    end
    else begin
        if (wb_en && transaction_on_the_fly == 1'b0) begin
            awvalid_m_inf <= 1'b1;
        end
        else if (awready_m_inf) begin
            awvalid_m_inf <= 1'b0;
        end
    end
end

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        wvalid_m_inf <= 1'b0;
        has_run_that_trick <= 1'b0;
    end
    else begin
        if (awready_m_inf) begin
            wvalid_m_inf <= 1'b1;
            has_run_that_trick <= 1'b0;
        end
        else if (wvalid_m_inf && wready_m_inf && has_run_that_trick == 1'b0) begin
            wvalid_m_inf <= 1'b0;
            has_run_that_trick <= 1'b1;
        end
        else if (wvalid_m_inf == 1'b0 && has_run_that_trick == 1'b1 && wvalid_cnt_r == 2'b01) begin
            wvalid_m_inf <= 1'b1; // Disable wvalid after two cycles
        end
        else if (wvalid_m_inf && wready_m_inf && wlast_m_inf) begin
            wvalid_m_inf <= 1'b0;
        end
    end
end

ID_CACHE_WRAPPER ID_CACHE_inst (
    .clk  (clk),
    .addr ({fetching_1i0d, cache_addr_r}),
    .din  (cache_din_r),
    .dout (cache_dout_w),
    .we   (cache_we_r), .oe(1'b1), .cs(1'b1)
);

endmodule

module ID_CACHE_WRAPPER(
    input         clk,                      // Clock,
    input  [7:0]  addr,         // Consolidated address bus,
    input  [15:0]  din,          // Consolidated data input,
    output [15:0]  dout,         // Consolidated data output,
    input         we, oe, cs
);
    ID_CACHE mem_inst (
        .A0  (addr[0]),  .A1  (addr[1]),  .A2  (addr[2]),  .A3  (addr[ 3]),
        .A4  (addr[4]),  .A5  (addr[5]),  .A6  (addr[6]),  .A7  (addr[ 7]),
        .DO0 (dout[0]),  .DO1 (dout[1]),  .DO2 (dout[2]),  .DO3 (dout[ 3]),
        .DO4 (dout[4]),  .DO5 (dout[5]),  .DO6 (dout[6]),  .DO7 (dout[ 7]),
        .DO8 (dout[8]),  .DO9 (dout[9]),  .DO10(dout[10]), .DO11(dout[11]),
        .DO12(dout[12]), .DO13(dout[13]), .DO14(dout[14]), .DO15(dout[15]),
        .DI0 (din[0]),   .DI1 (din[1]),   .DI2 (din[2]),   .DI3 ( din[ 3]),
        .DI4 (din[4]),   .DI5 (din[5]),   .DI6 (din[6]),   .DI7 ( din[ 7]),
        .DI8 (din[8]),   .DI9 (din[9]),   .DI10(din[10]),  .DI11( din[11]),
        .DI12(din[12]),  .DI13(din[13]),  .DI14(din[14]),  .DI15( din[15]),
        .CK(clk), .WEB(we),  .OE(oe), .CS(cs)
    );
endmodule
