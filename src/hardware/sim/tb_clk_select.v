`timescale 1ns / 1ps


module tb_clk_select();
    reg CLK_WIZ_ENABLE;
    reg INPUT_CLK;
    reg TRIGGER;
    reg SYS_CLOCK;
    
    wire CLK_WIZ_CLK;
    wire CLK_WIZ_LOCKED;
    wire CLK_CPU;
    wire LOCKED;

    clk_wiz_0 clk_wizard (
        .clk_in1 (SYS_CLOCK),
        
        .clk_out1(CLK_WIZ_CLK),
        .locked(CLK_WIZ_LOCKED)
    );
    
    clk_select cs (
        .clk_wiz_enable (CLK_WIZ_ENABLE),
        .sys_clock (SYS_CLOCK),
        .clk_wiz_clk (CLK_WIZ_CLK),
        .clk_wiz_locked (CLK_WIZ_LOCKED),
        
        .clk_cpu (CLK_CPU),
        .locked (LOCKED)
    );
    
    always
        // 5ns ~ 20MHz
        #25 INPUT_CLK = ~INPUT_CLK;
        
    always @ (INPUT_CLK or TRIGGER)
    begin
        SYS_CLOCK <= INPUT_CLK ^ TRIGGER;
    end
    
    initial
    begin
    INPUT_CLK = 0;
    TRIGGER = 0;
    CLK_WIZ_ENABLE = 1;
    
    // The Clocking Wizard needs quite some time to stabilize
    #4000002 TRIGGER = 1;
    #4000003 TRIGGER = 0;
    end
endmodule
