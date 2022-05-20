#! /usr/bin/python3

from common import cw_connect, cw_set_glitching_params, ext_reset, enable_clk_glitching, disable_clk_glitching, reprogram_fpga

scope, ftarget = cw_connect()
target, fpga_io = cw_set_glitching_params(scope, ftarget)

scope.glitch.width       = ...
scope.glitch.offset      = ...
scope.glitch.width_fine  = ...
scope.glitch.offset_fine = ...
scope.glitch.ext_offset  = ...
scope.glitch.repeat      = ...

key = ...

def reboot_flush():
    ext_reset(fpga_io)
    target.flush()
    target.simpleserial_write('k', key)

# Reset before using
reboot_flush()

plaintext = ...
output_len = ...

target.simpleserial_write('p', plaintext)
reference_value = target.simpleserial_read('r', output_len)

successful_glitches = 0
resets = 0
memory_corruptions = 0

for i in ...:
    if scope.adc.state:
        # Trigger was never cleaned up
        resets += 1
        reboot_flush()

    # Test for instruction corruption
    disable_clk_glitching(scope)
    target.simpleserial_write('p', plaintext) # Can be replaced with a watchdog command
    val = target.simpleserial_read_witherrors('r', output_len, glitch_timeout=10)

    if val['valid'] is False or val['rv'] is False:
        print("Instructions corrupt - Reprogramming")
        memory_corruptions += 1
        reprogram_fpga(ftarget)

    enable_clk_glitching(scope)
    scope.arm()
    target.simpleserial_write('p', plaintext)
    ret = scope.capture()

    # Read the response command
    val = target.simpleserial_read_witherrors('r', output_len, glitch_timeout=10)

    if ret == None:
        resets += 1
        reboot_flush()
    else:
        # UART transmission is invalid
        if val['valid'] is False or val['rv'] is False:
            resets += 1
            reboot_flush()
        elif val['payload'] is None:
            print("\rPayload is none")
            resets += 1
            reboot_flush()
        else:
            result = val['payload']

            if result != reference_value:
                # If the output is not the same, we know we succesfully glitched
                print("\r🐙 Succesful attack")
                successful_glitches += 1
            else:
                # We don't care about the times were it did not produce
                # errors.
                continue

print("")
print("Succesful glitches: {}".format(successful_glitches))
print("Resets: {}".format(resets))
print("Memory corruptions: {}".format(memory_corruptions))

# Disconnect for all devices
target.dis()
ftarget.dis()
scope.dis()