## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0

## Commonly used instances. Adapt only here if their location changes.
## Darjeeling wires JTAG directly to tlul_jtag_dtm (no pinmux TAP mux, unlike
## earlgrey), and has no spi_device-internal generated-clock buffers verified
## yet -- see the TODO block at the end of this file.
set clkgen u_clkgen/pll

## Clock Signal
## clkgen_xil_ultrascale's MMCM is configured for a 100MHz reference input
## (hw/top_darjeeling/rtl/clkgen_xil_ultrascale.sv: CLKIN1_PERIOD=10.000),
## matching the CW340/CW341 board's PLL_CLK2 oscillator on this same pin in
## earlgrey's clocks_cw341.xdc.
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports IO_CLK]

## Rename MMCM outputs for less bug-prone parsing.
create_generated_clock -name clk_main [get_pin ${clkgen}/CLKOUT0]
create_generated_clock -name clk_io_pre [get_pin ${clkgen}/CLKOUT2]
create_generated_clock -name clk_usb_48 [get_pin ${clkgen}/CLKOUT1]
create_generated_clock -name clk_aon [get_pin ${clkgen}/CLKOUT4]

set_clock_groups -asynchronous \
    -group clk_main \
    -group clk_usb_48 \
    -group clk_aon \
    -group clk_io_pre \
    -group sys_clk_pin

## JTAG
## Darjeeling has a single dedicated JTAG TAP (tlul_jtag_dtm), not earlgrey's
## pinmux-muxed lc/rv TAPs, so only a port-level clock declaration is given
## here for v1 -- see the TODO block below for refining this once the
## post-synthesis buffer hierarchy inside tlul_jtag_dtm is known.
create_clock -add -name jtag_tck -period 100.00 -waveform {0 50} [get_ports JTAG_TCK]
set_output_delay -add_delay -clock jtag_tck -max 10.0 [get_ports JTAG_TDO]
set_output_delay -add_delay -clock jtag_tck -min -5.0 [get_ports JTAG_TDO]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -min  0.0 [get_ports {JTAG_TMS JTAG_TDI}]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -max 12.5 [get_ports {JTAG_TMS JTAG_TDI}]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks jtag_tck] \
    -group clk_main

## SPI device and host clocks (port-level declarations only for v1 -- see the
## TODO block below for the multicycle/passthrough refinements earlgrey's
## clocks_cw341.xdc applies once spi_device's internal buffer hierarchy for
## Darjeeling is confirmed).
create_clock -add -name clk_spi -period 80.00 -waveform {0 40} [get_ports SPI_DEV_CLK]
create_clock -add -name clk_spi_host0 -period 80.00 -waveform {0 40} [get_ports SPI_HOST_CLK]

set_clock_groups -asynchronous \
    -group clk_spi \
    -group clk_spi_host0 \
    -group clk_main

## ============================================================
## TODO(hw-bringup): timing refinements deferred to post-synthesis bring-up,
## once the actual implemented netlist hierarchy can be inspected in Vivado:
##
## - JTAG: earlgrey's clocks_cw341.xdc derives jtag_tck as a *generated* clock
##   sourced through pinmux's TAP clock buffers
##   (u_pinmux/u_pinmux_strap_sampling/u_pinmux_jtag_buf_*/.../bufg_i), which
##   does not apply here since Darjeeling has no pinmux-muxed TAP. Once
##   tlul_jtag_dtm's internal clock buffering (if any) is confirmed for
##   Darjeeling, tighten this into a proper generated clock the same way.
## - SPI device/host: earlgrey's file adds detailed multicycle-path and
##   input/output delay budgets referencing internal spi_device buffer pins
##   (u_spi_device/u_clk_spi_{in,out}_buf/.../bufg_i/O) and SPI passthrough/TPM
##   mode timing. These need the equivalent Darjeeling spi_device instance
##   path confirmed before porting; the port-level create_clock above is a
##   conservative placeholder that lets synthesis/implementation proceed
##   without an undeclared-clock warning, not a substitute for real closure.
## - GPIO/SOC_GPI/SOC_GPO/MIO: no clock relationship, no constraints needed
##   beyond the PACKAGE_PIN/IOSTANDARD assignments in pins_darjeeling_cw341.xdc.
## ============================================================
