/* 
Copyright (c) 2022, NewAE Technology Inc.
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
module clk_select (
  input  wire   pll_clk1,
  input  wire   tio_clkin,
  input  wire   j16_sel,
  input  wire   use_pll,
  output wire   sys_clock,
  output wire   locked
);

wire mmcm_locked;

    // choose and buffer input clock based on J16 dip switch:
`ifndef __ICARUS__
    wire sys_clock_nopll;
    wire sys_clock_pll;
    /*
    BUFGCTRL CCLK_MUX (
       .O                       (sys_clock_nopll),    // Clock output
       .CE0                     (1'b1),         // Clock enable input for I0
       .CE1                     (1'b1),         // Clock enable input for I1
       .I0                      (pll_clk1),     // Primary clock
       .I1                      (tio_clkin),    // Secondary clock
       .IGNORE0                 (1'b1),         // Clock ignore input for I0
       .IGNORE1                 (1'b1),         // Clock ignore input for I1
       .S0                      (~j16_sel),     // Clock select for I0
       .S1                      (j16_sel)       // Clock select for I1
    );
    */
    BUFGMUX #(
        .CLK_SEL_TYPE("ASYNC")
    ) U_clk_sel1 (
        .O      (sys_clock_nopll),
        .I0     (pll_clk1),
        .I1     (tio_clkin),
        .S      (j16_sel)
    );


    clk_wiz_0 clk_wiz_0 (
        .clk_in1    (sys_clock_nopll),
        .clk_out1   (sys_clock_pll),
        .locked     (mmcm_locked)
    );

    BUFGMUX #(
        .CLK_SEL_TYPE("ASYNC")
    ) U_clk_sel2 (
        .O      (sys_clock),
        .I0     (sys_clock_nopll),
        .I1     (sys_clock_pll),
        .S      (use_pll)
    );

`else
    assign sys_clock = j16_sel? tio_clkin : pll_clk1;
`endif

assign locked = use_pll ? mmcm_locked : 1'b1;


endmodule
`default_nettype wire

