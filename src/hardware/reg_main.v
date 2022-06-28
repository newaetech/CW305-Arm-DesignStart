//////////////////////////////////////////////////////////////////////////////////
// Company: NewAE
// Engineer: Jean-Pierre Thibault
// 
// Create Date: 
// Design Name: 
// Module Name: reg_trace
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Register block for trace module. To be paired with
// cw305_usb_reg_fe.v.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`default_nettype none
`timescale 1ns / 1ps
`include "defines.v"

module reg_main #(
   parameter pBYTECNT_SIZE = 7,
   parameter pREGISTERED_READ = 1
)(
   input  wire         reset_pin_n,
   output wire         fpga_reset,
   output wire         target_reset,
   output reg          reg_pll_bypass,

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire [7:0]                            reg_address,  // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output wire [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write        // Write flag. When high on rising edge valid data is
                                                                 // present on write_data


);


   reg  [7:0] reg_read_data;
   reg  [7:0] read_data_r;
   reg  [31:0] reg_echo;

   wire reset_pin = ~reset_pin_n;

   reg reg_fpga_reset = 1'b0;
   reg reg_target_reset;
   assign fpga_reset = reset_pin || reg_fpga_reset;
   assign target_reset = reset_pin || reg_fpga_reset || reg_target_reset;


   //////////////////////////////////
   // read logic:
   //////////////////////////////////

   always @(*) begin
      if (reg_read) begin
         case (reg_address)
            `REG_ECHO:                  reg_read_data = reg_echo[reg_bytecnt*8 +: 8];
            `REG_PLL_BYPASS:            reg_read_data = reg_pll_bypass;
            default:                    reg_read_data = 0;
         endcase
      end
      else
         reg_read_data = 0;
   end

   // Register output read data to ease timing. If you need data one clock
   // cycle earlier, simply remove this stage.
   always @(posedge usb_clk)
      read_data_r <= reg_read_data;
   assign read_data = pREGISTERED_READ? read_data_r : reg_read_data;

   //////////////////////////////////
   // write logic (USB clock domain):
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (fpga_reset) begin
          reg_target_reset <= 1'b0;
          reg_echo <= 32'b0;
      end

      else begin
         if (reg_write) begin
            case (reg_address)
               `REG_ECHO:               reg_echo[reg_bytecnt*8 +: 8] <= write_data;
               `REG_PLL_BYPASS:         reg_pll_bypass <= write_data[0];
               `REG_TARGET_RESET_REG:   reg_target_reset <= write_data[0];
            endcase
         end

      end
   end

   // special case: register-triggered reset:
   always @(posedge usb_clk) begin
      if (reg_write && (reg_address == `REG_FPGA_RESET_REG))
         reg_fpga_reset <= write_data[0];
   end

endmodule

`default_nettype wire
