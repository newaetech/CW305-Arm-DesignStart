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

// This module utilizes the clk_wiz_enable wire to differentiate between two
// different clocks:
// 1. The Clock Wizard clock (+ dcm locked)
// 2. The sys_clock which is regarded as always being locked
module CW305_designstart_top (
  clk_wiz_enable,
  sys_clock,
  clk_wiz_clk,
  clk_wiz_locked,

  clk_cpu,
  locked,
);
  input  wire clk_wiz_enable; // 0 = sys_clock, 1 = clk_wiz
  input  wire sys_clock;
  input  wire clk_wiz_clk;
  input  wire clk_wiz_locked; // Active High

  output wire clk_cpu;
  output wire locked; // locked is Active High

  assign clk_cpu = clk_wiz_enable ? clk_wiz_clk : sys_clock;
  assign locked = ~clk_wiz_enable || clk_wiz_locked;
endmodule
