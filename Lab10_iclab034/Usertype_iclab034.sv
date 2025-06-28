/*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NYCU Institute of Electronic
2025 Spring IC Design Laboratory 
Lab09: SystemVerilog Design and Verification 
File Name   : Usertype.sv
Module Name : usertype
Release version : v1.0 (Release Date: April-2025)
Author : Yun-Chiao Chen
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
*/
`ifndef USERTYPE
`define USERTYPE

package usertype;

typedef enum logic  [1:0] { Purchase	        = 2'h0,
                            Restock	            = 2'h1,
							Check_Valid_Date    = 2'h2
							}  Action ;

typedef enum logic  [1:0] { No_Warn       		    = 2'b00, 
                            Date_Warn               = 2'b01, 
							Stock_Warn              = 2'b10,
                            Restock_Warn              = 2'b11 
                            }  Warn_Msg ;

typedef enum logic  [2:0] { Strategy_A = 3'h0,
							Strategy_B = 3'h1,
							Strategy_C = 3'h2,
							Strategy_D = 3'h3,
                            Strategy_E = 3'h4,
                            Strategy_F = 3'h5,
                            Strategy_G = 3'h6,
                            Strategy_H = 3'h7
                            }  Strategy_Type; 

typedef enum logic  [1:0]	{ Single  = 2'b00,
							  Group_Order  = 2'b01,
							  Event  = 2'b11
                            } Mode ;

typedef logic [11:0] Stock; //Flowers
typedef logic [3:0] Month;
typedef logic [4:0] Day;
typedef logic [7:0] Data_No;

typedef struct packed {
    Month M;
    Day D;
} Date;

typedef struct packed {
    Stock Rose;
    Stock Lily;
    Stock Carnation;
    Stock Baby_Breath;
    Month M;
    Day D;     
} Data_Dir;

typedef struct packed {
	Strategy_Type Strategy_Type_O;
    Mode Mode_O;
} Order_Info;

typedef union packed{ 
    Action [35:0] d_act;  // 2
    Strategy_Type [23:0] d_strategy;  // 3
    Mode [35:0] d_mode;  // 2
    Date [7:0] d_date;  // 9
    Data_No [8:0] d_data_no;  // 8
    Stock [5:0] d_stock;  // 12
} Data;

//################################################## Don't revise the code above

//#################################
// Type your user define type here
//#################################





//################################################## Don't revise the code below
endpackage

import usertype::*; //import usertype into $unit

`endif