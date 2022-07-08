import chipwhisperer as cw
from chipwhisperer.capture.targets.CW305 import CW305

default_bitfile = r"V:/hardware/CW305_DesignStart/CW305_DesignStart.bit"

def cw_connect(bitfile_path = default_bitfile, force = False):
    scope = cw.scope()

    ftarget = cw.target(
        scope, CW305,
        bsfile=bitfile_path,
        fpga_id='100t', force=force
    )

    return (scope, ftarget)

def cw_set_params(scope, ftarget, frequency = 20E6):
    # Disable all the clocks on the FPGA
    ftarget.vccint_set(1.0)

    ftarget.pll.pll_enable_set(True)
    ftarget.pll.pll_outenable_set(False, 0)
    ftarget.pll.pll_outenable_set(True, 1)
    ftarget.pll.pll_outenable_set(False, 2)

    ftarget.pll.pll_outfreq_set(frequency, 1)

    # 1ms is plenty of idling time
    ftarget.clkusbautooff = False
    ftarget.clksleeptime = 1

    # ensure ADC is locked:
    scope.clock.reset_adc()
    assert (scope.clock.adc_locked), "ADC failed to lock"

    fpga_io = ftarget.gpio_mode()

    scope.gain.gain = 25
    scope.adc.basic_mode = "rising_edge"
    scope.adc.timeout = 0.1

    scope.clock.clkgen_src = "system"
    scope.clock.adc_src = "clkgen_x4"
    scope.clock.extclk_freq = frequency
    scope.clock.clkgen_freq = frequency

    scope.io.hs2 = "clkgen" # Clock glitching is disabled by default
    scope.io.tio1 = "serial_rx"
    scope.io.tio2 = "serial_tx"
    scope.trigger.triggers = "tio4"

    scope.io.glitch_lp = False
    scope.glitch.clk_src = "clkgen" # set glitch input clock
    scope.glitch.output = "clock_xor" # glitch_out = clk ^ glitch
    scope.glitch.trigger_src = "ext_single" # glitch only after scope.arm() called

    target = cw.target(scope)

    return (target, fpga_io)

def enable_clk_glitching(scope):
    scope.io.hs2 = "glitch"

def disable_clk_glitching(scope):
    scope.io.hs2 = "clkgen"

# some convenience functions:
def reset_fpga(ftarget):
    # resets the full CW305 FPGA
    ftarget.fpga_write(3, [1])
    ftarget.fpga_write(3, [0])

def reset_arm_target(ftarget):
    # resets only the Arm DesignStart core within the CW305 FPGA
    ftarget.fpga_write(2, [1])
    ftarget.fpga_write(2, [0])
    
def use_fpga_pll(ftarget):
    # The target clock goes through a PLL (MMCM) in the FPGA before getting to the Arm DesignStart core.
    # This PLL can clean up the clock and filter glitches.
    ftarget.fpga_write(1, [1])

def bypass_fpga_pll(ftarget):
    # The target clock is connected directly to the Arm DesignStart core, bypassing the PLL.
    # This can make clock glitching more effective.
    ftarget.fpga_write(1, [0])

# Useful for when instruction memory gets corrupted
def reprogram_fpga(ftarget, bitfile_path = default_bitfile):
    ftarget.fpga.FPGAProgram(
        open(bitfile_path, "rb"),
        exceptOnDoneFailure=False,
        prog_speed=10E6
    )