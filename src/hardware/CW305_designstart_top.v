/* 
Copyright (c) 2019-2020, NewAE Technology Inc.
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

`timescale 1 ps / 1 ps
`default_nettype none
module CW305_designstart_top #(
  parameter pBYTECNT_SIZE = 7,
  parameter pADDR_WIDTH = 21
)(
  inout  wire swdio,
  input  wire swclk,
  input  wire TDI,
  inout  wire SWOTDO,
  input  wire nTRST,
  input  wire reset_pin_n, // active low
  input  wire tio_clkin,
  input  wire pll_clk1,
  input  wire j16_sel,  // clock source select
  input  wire k16_sel,  // unused
  input  wire l14_sel,  // unused
  input  wire k15_sel,  // unused

  // CW305 USB:
  input wire          USB_clk,
  inout wire [7:0]    USB_Data,
  input wire [pADDR_WIDTH-1:0] USB_Addr,
  input wire          USB_nRD,
  input wire          USB_nWE,
  input wire          USB_nCS,

  output wire swv,

  output wire ext_clock,
  output wire trig_out,
  input  wire uart_rxd,
  output wire uart_txd,
  output wire led1,
  output wire led2,
  output wire led3
);

  wire sys_clock;
  wire locked;
  wire SWDI;
  wire SWDO;
  wire SWDOEN;
  wire JTAGTOP;
  wire JTAGNSW;
  wire tdo;
  wire m3_reset_out;
  wire mmcm_locked;
  wire swotdo;
  wire nTDOEN;
  wire fpga_reset;

  assign swdio = SWDOEN ? SWDO : 1'bz;
  assign SWDI = swdio;

  reg [22:0] count;

  always @(posedge ext_clock or posedge fpga_reset) begin
     if (fpga_reset)
        count <= 23'b0;
     else if (trig_out == 1'b0) // disable counter during capture to minimize noise
        count <= count + 1;
  end

  assign led1 = count[22];              // clock alive
  assign led2 = ~m3_reset_out;          // LED off when reset is inactive
  assign led3 = uart_rxd ^ uart_txd;    // UART activity

  // controls where program is fetched from:
  wire [1:0] cfg = 2'b01;

  wire isout;
  wire [7:0] cmdfifo_din;
  wire [7:0] cmdfifo_dout;
  wire [pBYTECNT_SIZE-1:0]  reg_bytecnt;
  wire [7:0]   write_data;
  wire [7:0]   read_data;
  wire         reg_read;
  wire         reg_write;
  wire         reg_addrvalid;

  wire target_reset;
  wire pll_bypass;

  `ifndef __ICARUS__
  m3_for_arty_a7 m3_for_arty_a7_i
       (.SWCLK                  (swclk),
        .SWDI                   (SWDI),
        .SWDO                   (SWDO),
        .SWDOEN                 (SWDOEN),
        .JTAGTOP                (JTAGTOP),
        .JTAGNSW                (JTAGNSW),
        .TDI                    (TDI),
        .TDO                    (tdo),
        .nTDOEN                 (nTDOEN),
        .SWV                    (swv),
        .nTRST                  (nTRST),
        .reset                  (~target_reset),    // input is active low
        .sys_clock              (sys_clock),
        .ext_clock              (ext_clock),
        .gpio_rtl_0_tri_o       (trig_out),
        .usb_uart_rxd           (uart_rxd),
        .usb_uart_txd           (uart_txd),

        // connect to DIP switches to get right setting...
        .CFGITCMEN              (cfg),
        .M3_RESET_OUT           (m3_reset_out),
        .locked                 (locked),

        // unused AXI port inputs:
        .CM3_CODE_AXI3_arready  (1'b0),
        .CM3_CODE_AXI3_awready  (1'b0),
        .CM3_CODE_AXI3_bresp    (2'b0),
        .CM3_CODE_AXI3_bvalid   (1'b0),
        .CM3_CODE_AXI3_rdata    (32'b0),
        .CM3_CODE_AXI3_rlast    (1'b0),
        .CM3_CODE_AXI3_rresp    (2'b0),
        .CM3_CODE_AXI3_rvalid   (1'b0),
        .CM3_CODE_AXI3_wready   (1'b0),

        // unused AXI port outputs:
        .CM3_CODE_AXI3_araddr   (),
        .CM3_CODE_AXI3_arburst  (),
        .CM3_CODE_AXI3_arcache  (),
        .CM3_CODE_AXI3_arlen    (),
        .CM3_CODE_AXI3_arlock   (),
        .CM3_CODE_AXI3_arprot   (),
        .CM3_CODE_AXI3_arsize   (),
        .CM3_CODE_AXI3_aruser   (),
        .CM3_CODE_AXI3_arvalid  (),
        .CM3_CODE_AXI3_awaddr   (),
        .CM3_CODE_AXI3_awburst  (),
        .CM3_CODE_AXI3_awcache  (),
        .CM3_CODE_AXI3_awlen    (),
        .CM3_CODE_AXI3_awlock   (),
        .CM3_CODE_AXI3_awprot   (),
        .CM3_CODE_AXI3_awsize   (),
        .CM3_CODE_AXI3_awuser   (),
        .CM3_CODE_AXI3_awvalid  (),
        .CM3_CODE_AXI3_bready   (),
        .CM3_CODE_AXI3_rready   (),
        .CM3_CODE_AXI3_wdata    (),
        .CM3_CODE_AXI3_wlast    (),
        .CM3_CODE_AXI3_wstrb    (),
        .CM3_CODE_AXI3_wvalid   ()
       );
  `endif


   clk_select U_clk_select (
       .pll_clk1                (pll_clk1),
       .tio_clkin               (tio_clkin),
       .j16_sel                 (j16_sel),
       .pll_bypass              (pll_bypass),
       .sys_clock               (sys_clock),
       .locked                  (locked)
   );

  // JTAG or SW: multiplexing of other pins is handled by the M3 core, but the
  // SWO/TDO mux logic was left for us to handle:
  assign swotdo = JTAGNSW? tdo : swv;

  `ifndef __ICARUS__
  OBUF #(
         .DRIVE (12),                  // Specify the output drive strength
         .IOSTANDARD ("DEFAULT")       // Specify the I/O standard
        )
  OBUF_inst (
         .O (SWOTDO),
         .I (swotdo)
        ); 
  `else
      assign SWOTDO  = swotdo;
  `endif
     
  wire clk_usb_buf;

   `ifdef __ICARUS__
      assign clk_usb_buf = USB_clk;
   `else
      IBUFG U_usb_clk_buf (
           .O(clk_usb_buf),
           .I(USB_clk) );
   `endif

   assign USB_Data = isout ? cmdfifo_dout : 8'bZ;
   assign cmdfifo_din = USB_Data;


   wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0]  reg_address;
   cw305_usb_reg_fe #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE)
   ) U_usb_reg_main (
      .rst              (fpga_reset),
      .usb_clk          (clk_usb_buf), 
      .usb_din          (cmdfifo_din), 
      .usb_dout         (cmdfifo_dout), 
      .usb_rdn          (USB_nRD), 
      .usb_wrn          (USB_nWE),
      .usb_cen          (USB_nCS),
      .usb_addr         (USB_Addr),
      .usb_isout        (isout), 
      .I_drive_data     (1'b0),
      .reg_address      (reg_address), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (write_data), 
      .reg_datai        (read_data),
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .reg_addrvalid    ()
   );

   reg_main #(
      .pBYTECNT_SIZE            (pBYTECNT_SIZE),
      .pREGISTERED_READ         (1)
   ) U_reg_main (
      .reset_pin_n      (reset_pin_n),
      .fpga_reset       (fpga_reset),
      .target_reset     (target_reset),
      .reg_pll_bypass   (pll_bypass),

      .usb_clk          (clk_usb_buf), 
      .reg_address      (reg_address[7:0]), 
      .reg_bytecnt      (reg_bytecnt), 
      .read_data        (read_data), 
      .write_data       (write_data),
      .reg_read         (reg_read), 
      .reg_write        (reg_write)
   );


endmodule
`default_nettype wire

