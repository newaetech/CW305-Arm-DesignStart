compile:
	iverilog -ccmdfile \
	-g2005-sv \
	-Wportbind \
	-Wselect-range \
	-I. \

lint:
	verilator --lint-only -Wall \
	-Wno-PINCONNECTEMPTY \
	-f cmdfile \
	-I. \
	-D__ICARUS__ \
	--top-module CW305_designstart_top \
	2>&1 | tee lint.out \

