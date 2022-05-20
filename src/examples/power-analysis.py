#! /usr/bin/python3

from common import cw_connect, cw_set_params, ext_reset

scope, ftarget = cw_connect()
target, fpga_io = cw_set_params(scope, ftarget)

def reset_flush():
    ext_reset(fpga_io)
    target.flush()

# Reset before using
reset_flush()

key = ...
plaintext = ...
output_len = ...

target.simpleserial_write('k', key)

scope.arm()
target.simpleserial_write('p', plaintext)
ret = scope.capture()

response = target.simpleserial_read('r', output_len, ack=True)
wave = scope.get_last_trace()

# Disconnect for all devices
target.dis()
ftarget.dis()
scope.dis()