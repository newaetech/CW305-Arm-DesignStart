# Introduction

Arm freely provides its Cortex M1 and Cortex M3 processors as soft-core IP for
evaluation through its
[DesignStart](https://www.arm.com/resources/free-arm-cortex-m-on-fpga)
program. This will require one to both *Apply* and sign-up. Arm also
provides a workflow and tutorials for implementing the
M1 or M3 on the popular [Digilent Arty
A7](https://reference.digilentinc.com/reference/programmable-logic/arty-a7/start)
FPGA platform.

In this note we explain how to port the Arty DesignStart platform to our own
[CW305](https://rtfm.newae.com/Targets/CW305%20Artix%20FPGA/) or CW312 A35
platform.  We show how to generate the FPGA bitfile, then we show how to build
our
[standard simpleserial AES victim
firmware](https://github.com/newaetech/chipwhisperer/tree/develop/hardware/victims/firmware/simpleserial-aes) and run our standard Jupyter tutorials.

The end result is a powerful side-channel platform with a customizable Arm
Cortex target, which you can use as a starting point and customize for your
own needs. Here are a few examples of what you can do:

- add additional peripherals and interfaces to the Arm processor
- instantiate multiple Arm processors
- add additional side-channel attack logic to the target FPGA -- for example,
  [Arm trace sniffing logic](https://github.com/newaetech/DesignStartTrace).

Before starting, it's a good idea to watch the series of videos that Arm put
together to show the development cycle for DesignStart on the Arty board:
https://youtu.be/kSaQJGSu-yI

This will give you an idea of what's possible and what the development cycle
is like.


## Warning!
Porting the Arm IP from the Arty platform to one of our target FPGAs requires you
to do a lot of work in Vivado. This write-up assumes some prior experience
with Vivado.  It is not a Vivado tutorial! Vivado can be a fickle tool and
its error messages will have you scratching your head if you aren't familiar
with FPGA development. Attempting to follow the steps below without any FPGA
development experience is almost guaranteed to be a frustrating experience.
The instructions below are very long and fairly detailed, but they are not
intended for beginners.

On the other hand, if you've used Vivado before, then don't let this scare
you away. You probably won't be doing anything you haven't done before!
For an experienced FPGA developer, there's nothing hard or tricky here. The
intent of this note is to show that it *is* possible to run DesignStart on
our target FPGAs, and hopefully save you some time in getting there.


## Limitations
- The Cortex processors included in the DesignStart release have limited
  configuration options.
- The free version of Keil does not support programs larger that 32 Kbytes (the
  free version includes a 30-day trial for the unlimited professional version).

# Requirements
## Hardware Requirements:
- CW-Nano, Lite, Pro or Husky
- CW305 or CW312-A35

## Software Requirements:
These are all free downloads:
- Xilinx Vivado version 2019.1
    * other versions may work but some tweaks to the steps may be required
    * Xilinx makes it easy to install arbitrary versions, so please use
      2019.1!
- Keil uVision version 5.26.2.0
    * current version is 5.30, should work as well
- Arm DesignStart for Xilinx FPGA package

While Vivado is available for Windows and Linux, Keil is Windows-only.
The recipe provided here was tested with Windows 10.

### Install Xilinx Vivado

Create a Xilinx account and download Vivado Design Suite 2019.1 from 
https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html.
You should select the original 2019.1 release, *not* the update 1 or update 2
version.  You want the one where the Windows installer has this MD5 checksum:

`743003070fb77857ad098bd6873bdf0b`

When you run the installer, choose the the Vivado HL WebPACK install.

Other versions of Vivado may work as well, but the Vivado project files
provided by Arm were created with this version of Vivado; there may be
hiccups if you use a different version (in particular, the Xilinx SDK
appears to have undergone significant changes in 2019.2).

### Download DesignStart package

Create an Arm account and download the DesignStart package 
from https://www.arm.com/resources/free-arm-cortex-m-on-fpga.

You have the option of choosing the M1 package or the M3 package. These
instructions are written for the M3 target, but they will work for the M1
target as well -- just substitute M3 for M1 wherever you encounter it in the
steps below.

The M3 fits on the XC7A100 FPGA with lots of room to spare for other logic
(approximately 20% utilization); it may be tight on the XC7A35 FPGA. The M1
should fit very comfortably on both.

These instructions were developed and tested with version r0p1-00-rel0.

### Install Keil
Download and install the Keil IDE from
https://www.keil.com/demo/eval/arm.htm.



# Creating the FPGA bitfile
This is by far the longest step, so buckle in. 

We're going to remove some unnecessary peripherals around the reference
Cortex design and change the configuration of others. The goal is to make a
target which resembles our STM32 targets, which communicate with
ChipWhisperer via UART. This will allow our existing Jupyter notebook
tutorials to be very easily ported to this platform.

(Other approaches are possible too! That's the beauty of having the target as
soft IP in an FPGA. For example one may choose to leverage the 8-bit
parallel data interface provided by 
[CW305.py](https://github.com/newaetech/chipwhisperer/blob/develop/software/chipwhisperer/capture/targets/CW305.py),
or make up an entirely new interface.)

Since this guide was originally developed for the CW305 target, it contains
many references to the CW305; unless otherwise noted, these also apply to the
CW312 A35 target.

1. Open the Arm DesignStart user guide
(`<Arm bundle>/docs/arm_cortex_m3_designstart_fpga_xilinx...pdf`)
and follow the instructions in sections 2.1, 2.2, and 2.3.


2. Clone the DesignStart project in Vivado:
   - Open Vivado and open either the DesignStart project, found here:
     `v:/hardware/m3_for_arty_a7/m3_for_arty_a7/m3_for_arty_a7.xpr`
   - There will be some warnings; this is ok.
   - File > Project > Save As, with a new project name of
     CW305\_DesignStart, to `V:/hardware/CW305_DesignStart` as shown below:  
   ![picture](images/new_project.png)

2. Copy `v:/software/m3_for_arty_a7/` to `v:/software/CW305_DesignStart`

3. Follow the instructions in section 2.4 of the Arm DesignStart user guide,
   but replace `m3_for_arty_a7` with `CW305_DesignStart`.

4. Make sure `Arty A7-100` is selected at `Tools -> Settings -> Project Settings
   -> General -> Project device` afterwards.

5. Do not follows steps 2.5 and 2.6:
    - Step 2.5 is not necessary because our CW305 port does not use QSPI
      memory.
    - Step 2.6 is not necessary because we will not be simulating our CW305
      port in Vivado. (You, on the other hand, may wish to do so --
      especially if you decide to deviate from this recipe.)

6. Restart Vivado. Then in Vivado, update the block diagram. There is a *very long* list of
   changes to make! At the end of the changes, we'll show a picture of what
   the updated block diagram should look like, so that you can double-check
   that you've made all the changes correctly.
    - Double click on the block diagram file `m3_for_arty_a7_i` in the
      Design Sources tree; there will be errors but that's ok.  
    ![picture](images/open_bd.png)
    - in the block diagram window, delete the following blocks:
        - `axi_gpio_0`
        - `axi_gpio_1`
        - `axi_quad_spi_0`
        - `daplink_if_0`
    - delete the following ports which are now dangling:
        - `rgb_led`
        - `led_4bits`
        - `dip_switches_4bits`
        - `push_button_4bits`
        - `qspi_flash`
        - `DAPLink`
    - connect the dangling `usb_uart` port to the `axi_uartlite_0` block

    - Add AXI GPIO block:
        - rick-click on diagram > Add IP, search "gpio", select AXI GPIO
        - double-click the newly created `axi_gpio_0` block to configure it:
            - select "All Outputs"
            - set width to 1
            - click OK
        - connect left-side ports of `axi_gpio_0` block:
            - `S_AXI` to `M01_AXI` port on the `axi_interconnect_0` block
            - `s_axi_aclk` to the same wire that goes to the `s_axi_aclk` port
              of other blocks
            - same for `s_axi_aresetn`
        - right-click on GPIO port of `axi_gpio_0` block and select "Create
          Interface Port"; name it `gpio_rtl_0`

    - Update `axi_interconnect_0` block:
        - move the `M03_AXI` connection on the interconnect to `M02_AXI` so
          that only the first three `Mxx_AXI` ports are used
        - double-click on the `axi_interconnect_0` block to edit its
          properties; change number of master interfaces from 6 to 3

    - Double-click on the `axi_uartlite_0` block to edit its configuration:
        - change AXI clock frequency from AUTO to MANUAL and set it to 20
          MHz
        - set the baud rate you intend to use; we'll use 38400
        - click OK  
        ![picture](images/axi_uartlite.png)

    - Double-click the `Clocks_and_Resets` block:
        - delete the `clk_wiz_0`, `proc_sys_reset_DAPLink`, `i_interconnect_aresetn`,
          `i_peripheral_aresetn1`, and `i_sysresetn_or` blocks
        - delete the dangling `clk_qspi` and `aux_reset_in` ports
        - connect the `mb_reset` output of `proc_sys_reset_base` to the
          input of `i_inv_dbgresetn` and to the input of `i_in_sysresetn1`
        - connect the `interconnect_aresetn` output of `proc_sys_reset_base`
          to the `interconnect_aresetn` output port
        - connect the `peripheral_aresetn` output of `proc_sys_reset_base`
          to the `peripheral_aresetn` output port
        - connect the `sysresetreq` input pin to the `mb_debug_sys_rst`
          input of `proc_sys_reset_base`
        - connect the `xlconstant_1` output to the `aux_reset_in` input of
          `proc_sys_reset_base`
		- right-click in the design window, select "Add Module" and select
		  `clk_select.v`.
		- Add a connection from `clk_select_0->sys_clock` to the `sys_clock`
		  input pin.
        - right-click in the design window, select Create Pin, and create an
          input pin named "locked_i"; connect it to the `dcm_locked` input of
          `proc_sys_reset_base`
        - connect the `sys_clock` input to the `clk_cpu` output and to the 
          `proc_sys_reset_base` `slowest_sync_clk` input
        - the `Clocks_and_Resets` block diagram should now look like this:
        ![picture](images/clocks_and_resets.png)

    - Returning to the main block diagram, right-click in the design window,
      Create Port, and fill in these properties:
        - name: `ext_clock`
        - direction: output
        - type: clock
        - click OK
        - wire the newly-created `ext_clock` to the `clk_cpu` net
        ![picture](images/ext_clk.png)

    - Repeat the above to create an input data pin named `locked`,
      connected to the `locked_i` input of `Clocks_and_Resets`

    - Repeat the above to create an output data pin named `M3_RESET_OUT`,
      connected to the `sysresetn` output of `Clocks_and_Resets`

    - Delete the `tri_io_buf_0` block
        - delete the dangling `TDO[0:0]` output port
        - for each of the following `Cortex_M3_0` outputs, right-click on
          the output pin, select Create Port, and accept the defaults:
            - `TDO`
            - `nTDOEN`
            - `SWV`

    - Add many more missing ports:
        - right-click on the `SWDITMS` input of the `Cortex_M3_0` block and
          select "Create Port"
            - change name to `SWDI`, set type to data

        - do the same with `SWCLKTCK` input of the `Cortex_M3_0` block
            - name: `SWCLK`
            - direction: input
            - type: clock
            - frequency (MHz): 20

        - select `CM3_CODE_AXI3` port of `Cortex_M3_0` block, then
          right-click in the design window and select "Create Interface
          Port"; keep the pre-filled values and click OK  
        ![picture](images/CM3_CODE_AXI3.png)
        - right-click on `CM3_CODE_AXI3` output port, select "External
          Interface Properties", and set the Clock Port to `ext_clk`
        - for each of the `JTAGNSW`, `JTAGTOP`, `SWDO`, `SWDOEN` ports of
          the `Cortex_M3_0` block:
            - select the port, then right-click in the design window, select
              "Create Port", and accept  the default pre-filled values

    - Delete the `xlconcat_1` block
        - right-click the CFGITCMEN[1:0] input of the `Cortex_M3_0` block
          and select "Create Port"; accept pre-filled settings and click
          "OK"

    - Almost done! This is the last big step:
        - double-click the `xlconstant_1` block and change the "Const Val"
          field from 1 to 0; click OK
        - right-click the `xlconstant_1` block, select copy
        - right-click in the design window and select paste; repeat this 6
          times
            - this will create the blocks `xlconstant_2` through to
              `xlconstant_7`
        - connect the `dout` port of each of our seven `xlconstant_*` blocks
          to an unconnected `In*` port of the `xlconcat_0` block
        - you should have something that looks like this:  
          ![picture](images/xlconstant.png)

    - Assign missing addresses: switch to the Address Editor tab
        - assign an address to `axi_gpio_0` by right-clicking in its Offset
          Address column and select "Assign Address"
        - do the same to `CM3_CODE_AXI3`  
          ![picture](images/addresses.png)

    - Configure Arm processor (optional): there are a limited number of
      configuration options. The default values are fine, but you may wish
      to enable additional debug facilities.

    - The block diagram changes are now done; verify that it looks like this:  
    ![picture](images/final_bd.png)

    - Phew! Now save and validate:
        - File -> Save Block Design
        - Tools -> Validate Design
        - If you get a "Validation successful" message: congratulation!
          You've completed the most tedious part of the porting exercise!
          Otherwise, any errors **must be** investigated and resolved.
        ![picture](images/success.png)

7. Change the target from Arty to CW305:
    - Settings > Device > Parts: choose the correct part for your target
        - for the CW305 this is either `xc7a100tftg256-2` or `xc7a35tftg256-2`
        - for the CW312 A35 target this is `xc7a35tcsg324-1`
    - upgrade IP blocks as required: next to the message "The design has 23
      blocks that should be upgraded.", click on "Report IP Status", then
      "upgrade selected"
    - you will see three critical warnings related to the `proc_sys_reset_base`
      blocks
      - open the `proc_sys_reset_base` block (inside the
          `Clocks_and_Resets` block) and fix its configuration:
            - set Ext Reset Active Width to 1
            - set Aux Reset Active Width to 1
    - save and validate again (there should be no errors or critical
      warnings) 
    - click on "Generate Block Design" (should be clean)

8. Replace the top-level design file:
    - File > Add Sources > Add or create design sources > Next;
        - Add Files, select all `*.v` files in 
          [`src/hardware/`](src/hardware/)
        - select "Copy sources into project"; Finish
    - in the Sources tree, right-click on `CW305_designstart_top.v` and select
      "Set As Top"
    - right-click on the old top-level file, `m3_for_arty_a7_wrapper`, and
      select Remove File from Project
    - also remove `tri_io_buf` from the project

9. Replace the constraint file:
    - File > Add Sources > Add or create constraints > Next;
        - Add Files, select either
          [`CW305_designstart.xdc`](src/hardware/CW305_designstart.xdc)
          or
          [`a35_designstart.xdc`](src/hardware/a35_designstart.xdc)
        - ensure "Copy constraints files into project" is selected; Finish
    - in the Sources tree, expand Constraints and constrs\_1, right-click
      the file you just added, select "Set as Target Constraint File"
    - remove the other two constraint files (`m3_for_arty_a7.xdc`,
      `m3_for_arty_a7_impl.xdc`) from the project

10. Generate the FPGA PLL: this is needed because we've deleted the PLL from
    the `clocks_and_resets` block and moved it to the top-level Verilog.
    Under "Project Manager", click on "IP Catalog", search for "clock
	wizard", and double-click on the "Clocking Wizard" search result (Customize
	IP). In the "Clocking Options" tab, select the following options:
     - MMCM
     - Frequency Synthesis
     - Phase Alignment
     - Safe Clock Startup
     - Balanced
     - set clk_in1 frequency to 100 MHz

    In the "Output Clocks" tab, set the following:
     - clk_out1 requested frequency to 100 MHz
     - clocking feedback: Automatic Control On-Chip
     - Enable Optional Inputs/Outputs: enable locked, disable reset

    Then click "OK", and "generate" (this can take a while).

11. If using the CW312 A35 target, go to `Tools -> Settings -> Project Settings
   -> General -> Verilog options`, click on the three dots (`...`), and add a
   define with a name of `SS2_WRAPPER` (no value needed).

12. Generate the FPGA bitstream: in the Flow Navigator pane, select "Generate
    Bitstream". This will take on the order of 30 minutes. There should be
    no errors, but there will be warnings. In particular, timing will not be
    met: I haven't figured out how to change the target clock rate from 100
    MHz to something more reasonable. We'll be setting the actual clock to
    something much lower, so that's ok.

    *It's possible that a "route\_design ERROR" will occur. The runme.log
    file in the implementation directory would show no errors, and
    hs\_err\_pidXXXXX.log would show: "An unexpected error has occurred
    (EXCEPTION\_ACCESS\_VIOLATION)". In this case, try to generate the
    bistream again (and again?) until it completes successfully. Thanks
    Vivado :-)*


13. File > Export > Export Hardware, to `V:/software`


# Generate the BSP (Board Support Package)

1. In Vivado, select File > Launch SDK:
    - set exported location to `V:/software/`
    - set workspace to `V:/software/CW305_DesignStart/sdk_workspace/`

2. In the Xilinx SDK tool, select File > New > Board Support Package. Ensure
   that `CW305_designstart_top_hw_platform_0` is selected in the Hardware
   Platform dropdown; click Finish.
    - In the BSP Setting pop-up, change the OS version to 6.7.
    - Under "Overview", click on standalone.
    - Even though stdin and stdout are both correctly set to
      `axi_uartlite_0`, they must each be changed to none and then back to
      `axi_uartlite_0`; failure to do this will possible result in a
      non-functional UART peripheral. Then, click OK.

3. To ensure that the UART is properly configured, in Project Explorer
  on the left-hand side, navigate to `standalone_bsp_0/Cortex_M3_0/include`,
  open xparameters.h, and verify that `STDIN_BASEADDRESS` and
  `STDOUT_BASEADDRESS` are defined:
  ![picture](images/stdio.png)

4. Copy `xpseudo_asm_rcvt.c` and `xpseudo_asm_rcvt.h` from:
  `V:\vivado\Arm_sw_repository\CortexM\bsp\standalone_v6_7\src\arm\cortexm3\armcc\`
  to:
  `V:\software\CW305_DesignStart\sdk_workspace\standalone_bsp_0\Cortex_M3_0\include\`

5. Add `C:\Keil_v5\ARM\ARMCC\bin\` to your system path envar and add
   `C:\Xilinx\Vivado\2019.1\bin\` to your user path envar.

6. You can now exit the Xilinx SDK as we will not be using it any further.


# Prepare to compile software
1. Edit `v:\software\CW305_DesignStart\Build_Keil\make_hex_a7.bat`:
    - change second last line from:
      `copy bram_a7.* ..\..\..\hardware\m3_for_arty_a7\m3_for_arty_a7`
      to:
      `copy bram_a7.* ..\..\..\hardware\CW305_DesignStart\`
    - delete this last line:
      `copy qspi_a7.hex ..\..\..\hardware\m3_for_arty_a7\testbench`
    - change all instances of `m3_for_arty_a7.axf` to
      `CW305_DesignStart.axf`

2. Copy the following files from
  `V:\hardware\m3_for_arty_a7\m3_for_arty_a7\` to `V:\hardware\CW305_DesignStart\`:  
    - `make_prog_files.bat`
    - `make_prog_files.tcl`
    - `make_mmi_file.tcl`

3. Edit `v:/hardware/CW305_DesignStart/make_prog_files.tcl`:
    - change `source_bit_file` to
      `./CW305_DesignStart.runs/impl_1/CW305_designstart_top.bit`
    - rename `output_bit_file` to `CW305_DesignStart.bit`
    - rename `output_mcs_file` to `CW305_DesignStart.mcs`

4. Copy the following from [src/software](src/software) to
   `v:/software/CW305_DesignStart/`:
   - `cw_main.c` to `v:/software/CW305_DesignStart/main/`
   - `cw_gpio.c` and `cw_gpio.h` to `v:/software/CW305_DesignStart/gpio/`
   - simpleserial directory to `v:/software/CW305_DesignStart/`
   - crypto directory to `v:/software/CW305_DesignStart/`

5. Copy project file
   [`CW305_DesignStart.uvprojx`](src/keil/CW305_DesignStart.uvprojx) to
   `v:/software/CW305_DesignStart/Build_Keil/`


# Update MMI file
The Cortex target's program memory is local to the FPGA, and the program
memory contents is included in the FPGA bitfile. When we generated the
bitfile a few steps ago, this was done using the reference program provided
by Arm for their DesignStart reference design. Obviously, that won't work
for us.

Fortunately, it's possible to update the program memory content in an
existing FPGA bitfile without having to regenerate the bitfile from scratch.
Xilinx uses an MMI file to describe the location of internal FPGA memories,
so that their contents may be updated. First we must generate this MMI file:

1. Edit the `set part` line in
   `V:/hardware/CW305_DesignStart/make_mmi_file.tcl`
   to set the correct part for your CW305 board (`xc7a100tftg256-2` or
   `xc7a35tftg256-2`).

2. In Vivado, reopen the project and in the sidebar click "Open Implemented Design",
   then in the Tcl console, navigate to project directory and run: `source make_mmi_file.tcl`


# Compile software
1. Open the project file (`CW305_DesignStart.uvprojx`) in Keil and select
   Project > Rebuild all target files

2. Build should be clean except for several warnings from Xilinx SDK file
   `xil_assert.h` having "*last line of file ends without a newline*";
   consider fixing this to have a clean build.

3. Note that `make_hex_a7.bat` is automatically run post-build, and any
   errors in that script will *not* be captured in the final tally of errors
   and warnings, so look at the build output carefully to make sure that it
   did in fact run cleanly.


# Update FPGA bitfile
In `v:/hardware/CW305_DesignStart`, run the `make_prog_files.bat` script to
stitch the Cortex program data into the FPGA bitfile that we generated
previously. This should take less than a minute -- orders of magnitude
faster than re-generating a bitfile from scratch!

**Caution!** This can silently fail if the MMI file has not been updated.
There will be no indication of any errors, other than an unresponsive target
processor.


# Done!
Now you can have fun! One thing you can do is try some of the ChipWhisperer
tutorials. Since we have built a target which looks and feels like an STM32
target (as far as the ChipWhisperer capture hardware is concerned), any of
the tutorials which support the CWLITEARM platform should work (if not, read
on to [debugging](#debugging) below).

Simply skip over the initial part of the tutorials which deals with
programming the target. This means you do **not** use `STM32FProgrammer`. 
Do not run the `%run
"Helper_Scripts/Setup_Generic.ipynb"` cell; on the CW305, use the
`Setup_DesignStart.ipynb` notebook supplied
[here](src/jupyter/Setup_DesignStart.ipynb).

On the CW312-A35, set up as follows:
```Python
scope.default_setup()
target = cw.target(scope, cw.targets.SimpleSerial)
scope.clock.clkgen_freq = 20e6
```

The following tutorials have been verified to succeed:
- [`Lab 3_3 - DPA on Firmware Implementation of AES`](https://github.com/newaetech/chipwhisperer-jupyter/blob/master/courses/sca101/Lab%203_3%20-%20DPA%20on%20Firmware%20Implementation%20of%20AES%20(MAIN).ipynb)
- [`Lab 4_2 - CPA on Firmware Implememtation of AES`](https://github.com/newaetech/chipwhisperer-jupyter/blob/master/courses/sca101/Lab%204_2%20-%20CPA%20on%20Firmware%20Implementation%20of%20AES%20(MAIN).ipynb) (requires a slightly higher number of traces, around 150)

Note that communication with the softcore is done over the UART interface,
using the IO1 and IO2 lines of the 20-pin ChipWhisperer connector (i.e. just
like with our "normal" microprocessor targets), **not** the CW305 USB
interface. This means that the CW305 cannot be used in standalone mode; it
needs to be connected to a [ChipWhisperer capture
device](https://rtfm.newae.com/Capture/).

Do not try to run the "normal" CW305 FPGA target notebooks (like
[this one](https://github.com/newaetech/chipwhisperer-jupyter/blob/master/demos/PA_HW_CW305_1-Attacking_AES_on_an_FPGA.ipynb));
these notebooks communicate with the target using the USB interface. That USB
interface is not connected to the DesignStart softcore, and so these notebooks
will not work with this DesignStart core.

## CW305 switches

The SW4 push-button is connected to the M3 reset; it can be used to reset
the running program.

The J16 DIP-switch selects the M3 input clock:
- 0: the input clock is the CW305 PLL1
- 1: the input clock is the HS2 pin (e.g. clkgen from ChipWhisperer)
The `Setup_DesignStart.ipynb` notebook expects J16 to be set to 0.

Refer to the [CW305 documentation](https://www.newae.com/products/NAE-CW305)
for more information on the features and capabilities of the CW305 board.

The CW312 A35 lacks these bells and whistles.

## Clock glitching (CW305 only)

The DesignStart reference design included a PLL to clean up the input clock;
we removed this when we modified the `Clocks_and_Resets` block in Vivado,
because it's been moved to the top-level `CW305_designstart_top.v` Verilog
file. This was done to allow you to selectively bypass this PLL, which can
be useful for clock glitching. When the PLL is bypassed, the input clock
goes directly to the Arm core.

To bypass the PLL, call `bypass_fpga_pll()`. To use the PLL (which is the
default behaviour out of reset), call `use_fpga_pll()`.  These functions are
defined in
[`src/jupyter/Setup_DesignStart.ipynb`](src/jupyter/Setup_DesignStart.ipynb).

On the CW312-A35, you'll have to customize and rebuild to get this
functionality.

# FPGA and target resets (CW305 only)

The pushbutton labeled "FPGA R1 USR SW4" (near the 3 side SMA connectors)
resets the CW305 FPGA (including the Arm DesignStart core).

The FPGA can also be reset by calling `reset_fpga()` (defined in
[`src/jupyter/Setup_DesignStart.ipynb`](src/jupyter/Setup_DesignStart.ipynb)).

Finally, to reset only the Arm core, use `reset_arm_target()`.

Currently the only FPGA logic which is unaffected by the Arm core reset is
the PLL bypass setting, but if you extend this work and add more FPGA logic,
you may find it useful to have the two separate resets.

Resetting the Arm core is sometimes required after startup. If the target is
unresponsive (e.g. captures time out with no trigger), try resetting the
target.

# Next steps

## Software modifications
Modifying the target software is easy. Make your changes and rebuild in Keil,
then update the previous FPGA bitfile with the `make_prog_files.bat` script.
No need to recompile the FPGA bitfile from scratch.

## Additional information for clock glitching

For clock glitching you probably do not want to use the clock wizard. Thus, the
PLL should be bypassed. One thing to consider is that the softcore processor now
directly utilizes the `sys_clock` instead of stabilizing the clock in the FPGA
DCM. This clock is running at a 20MHz by default.

Furthermore, the glitched clock signal from the capture device is coming in on
`hs2`. We can enable and disable glitching then with

```python
# Enable glitching
scope.io.hs2 = "glitch"

# Disable glitching
scope.io.hs2 = "clkgen"
```

Here are some other notes when wanting to clock glitch the softcore.

#### Problem: corruption of instruction data

Compared to the *ASIC*, it is relatively easy to corrupt the memory holding the
code data. This will usually show itself as only receiving the following error
after a while.

```
WARNING:ChipWhisperer Scope:Timeout in OpenADC capture(), no trigger seen! Trigger forced, data is invalid.
```

This will persist even if you restart your measurement. If you want do normal
measurements again, you need to reset the FPGA.

```python
ftarget = cw.target(
	scope, cw.targets.CW305,
	bsfile='V:/hardware/CW305_DesignStart/CW305_DesignStart.bit',
	fpga_id='100t', # or the other board
	force=True
)
```

## Hardware modifications
In this example, there is minimal FPGA logic alongside the Arm target. The
CW305 FPGA has lots of space remaining for your ideas! Our
[DesignStartTrace](https://github.com/newaetech/DesignStartTrace) project
is one example of what you can do, and gives an worked-out example of adding
configuration registers and setting them from Python.

Keep in mind that whenever a new bitstream is generated in Vivado, the 
`make_mmi_file.tcl` and `make_prog_files.bat` scripts must be re-run.


Additionally, if the address map changed, then the BSP also needs to be
regenerated.

Finally, update the FPGA bitfile with the `make_prog_files.bat` script.


# Debugging
The three LEDs located above the SMA connectors on the bottom of the CW305
provide some limited visibility into the target status:
- Red LED (LED7): Cortex clock, should be periodically toggling. If it's
  constantly on or off, then the Cortex has no clock. The clock is generated
  on the CW305 itself. Check your modifications to the `Clocks_and_Resets`
  block.
- Green LED (LED5): Cortex reset signal, should be off.
  If it's on, then the Cortex reset signal hasn't been released. Again,
  check your modifications to the `Clocks_and_Resets` block.
- Blue LED (LED6): UART activity. Should see fast bursts of activity
  whenever there is UART traffic. Check your modifications to the
  `axi_uartlite_0` block. Inactivity can also be caused by mistakes in the
  bitfile update flow.

On the CW312-A35, these map to LED1/2/3 respectively on the CW313.

If you get clean FPGA and software builds but yet the target isn't
responding, here is a list of possible causes:
- Did you [update the MMI file?](#update-mmi-file)
- Did you try [resetting the target?](#fpga-and-target-resets)
- There are a number of scripts which move the executable generated by Keil
  towards its final destination in the FPGA bitfile; make sure these all ran
  cleanly:
     - Keil build outputs are in `v:/software/CW305_DesignStart/Build_Keil/objects`
     - the `make_hex_a7.bat` script creates `bram_a7.elf` and `bram_a7.hex`
       in `v:/software/CW305_DesignStart/Build_Keil` and in
       `v:/hardware/CW305_designstart`
     - the `make_prog_files.bat` script creates the final bitfile:
       `v:/hardware/CW305_DesignStart/CW305_DesignStart.bit`
- If the CFGITCMEN[1:0] inputs aren't properly assigned, the processor will
  attempt to fetch the program from the wrong place.
- If the modifications to the `Clocks_and_Resets` blocks weren't done
  properly, clocks and resets may not be getting propagated correctly. Note
  that there are several internal resets, not just the one which is routed
  to LED5.

If you're still stuck, try simulation, ILAs, or routing internal signals to
the JP3 header. Simulation is probably the right choice, unless you enjoy
[FPGA hell](https://zipcpu.com/blog/2017/05/19/fpga-hell.html). DesignStart
comes with a Verilog testbench (see
`v:/docs/arm_cortex_m3_designstart_fpga_xilinx...pdf`), but you will need to
modify it to account for the changes we have made to the design.

Once you've determined that there are no hardware issues, you can move on to
software. If you have an external debugger, connect it to the the JTAG or
SWD signals which have been routed to the JP3 header (refer to the
`CW305_designstart.xdc` constraints file for details).

Debugging has been successfully tested using a Segger J-link Plus, using
either the JTAG or SWD interface, with speed set to "auto".

On the CW312-A35, set CW JTAG select switches 1-4 to "on" to connect the
"FPGA Jaytag" header to the DesignStart soft-core JTAG.

