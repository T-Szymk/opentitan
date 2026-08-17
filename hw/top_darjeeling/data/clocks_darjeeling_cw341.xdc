## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0

## Commonly used instances. Adapt only here if their location changes.
## Darjeeling wires JTAG directly to tlul_jtag_dtm (no pinmux TAP mux, unlike
## earlgrey), and has no spi_device-internal generated-clock buffers verified
## yet for SPI -- see the TODO block at the end of this file.
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
create_generated_clock -name clk_aon [get_pin ${clkgen}/CLKOUT4]

set_clock_groups -asynchronous \
    -group clk_main \
    -group clk_aon \
    -group clk_io_pre \
    -group sys_clk_pin

## JTAG
## Darjeeling has a single dedicated JTAG TAP (tlul_jtag_dtm), not earlgrey's
## pinmux-muxed lc/rv TAPs, so only a port-level clock declaration is given
## here for v1 -- see the TODO block below for a possible tighter,
## generated-clock refinement now that tlul_jtag_dtm's internal buffer
## (a BUFGMUX) is confirmed.
create_clock -add -name jtag_tck -period 100.00 -waveform {0 50} [get_ports JTAG_TCK]
set_output_delay -add_delay -clock jtag_tck -max 10.0 [get_ports JTAG_TDO]
set_output_delay -add_delay -clock jtag_tck -min -5.0 [get_ports JTAG_TDO]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -min  0.0 [get_ports {JTAG_TMS JTAG_TDI}]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -max 12.5 [get_ports {JTAG_TMS JTAG_TDI}]

## JTAG_TCK's IBUF drives tlul_jtag_dtm's internal BUFGMUX
## (prim_xilinx's BUFGMUX-based prim_clock_mux2, reached via
## prim_xilinx_ultrascale.core's virtual-core mapping) directly, with no
## intervening logic -- unlike earlgrey, which gates TCK through a LUT
## (prim_and2) before its own BUFG, avoiding this rule entirely. JTAG_TCK's
## package pin (AL34, fixed by the CW340/CW341 board's JTAG header wiring)
## is not a global-clock-capable pin in the BUFGMUX's clock region. Accepted
## trade-off: JTAG is board-driven and not timing-critical, so a
## non-dedicated clock route here is fine. NOTE: gen_dio_pads[1] is tied to
## the current padring generate-block ordering for JTAG_TCK's dedicated pad
## and may need re-deriving from a fresh synthesis run if that ordering ever
## changes.
set_property CLOCK_DEDICATED_ROUTE FALSE \
    [get_nets u_padring/gen_dio_pads[1].u_dio_pad/gen_input_only.u_ibuf/O]

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
## - JTAG: confirmed -- tlul_jtag_dtm's u_prim_clock_mux2 resolves, for this
##   build, to prim_xilinx's BUFGMUX-based prim_clock_mux2 (gen_bufg.bufgmux_i)
##   via prim_xilinx_ultrascale.core's virtual-core mapping (there is no
##   prim_xilinx_ultrascale-specific override for clock_mux2 -- BUFGMUX is
##   common to both 7-series and UltraScale, unlike clock_buf). Since
##   JTAG_TCK's IBUF drives that BUFGMUX directly with no intervening gating
##   logic (unlike earlgrey's pinmux_jtag_buf, which gates TCK through a LUT
##   first), this trips Vivado's rule_gclkio_bufg placement DRC; worked around
##   above via CLOCK_DEDICATED_ROUTE FALSE. The deeper refinement earlgrey
##   does -- a create_generated_clock sourced directly at the BUFGMUX's output
##   pin (u_tlul_jtag_dtm/u_prim_clock_mux2/gen_bufg.bufgmux_i/O at
##   chip-level), which could let the override be dropped entirely -- is still
##   open, pending confirming that exact path against a real post-synthesis
##   netlist.
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
