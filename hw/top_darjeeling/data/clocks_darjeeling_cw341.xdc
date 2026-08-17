## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0

## Commonly used instances. Adapt only here if their location changes.
## Darjeeling wires JTAG directly to tlul_jtag_dtm (no pinmux TAP mux, unlike
## earlgrey). spi_device's internal generated-clock buffers (u_clk_spi_in_buf/
## u_clk_spi_out_buf) are shared IP and confirmed valid for Darjeeling too --
## see the TODO block at the end of this file for what's still open.
set clkgen u_clkgen/pll
set u_clkmgr     top_*/*_pd_aon/u_clkmgr
set u_spi_device top_*/*_pd_main/u_spi_device

###############################
## CREATE CLOCKS
###############################

## Clock Signal
## clkgen_xil_ultrascale's MMCM is configured for a 100MHz reference input
## (hw/top_darjeeling/rtl/clkgen_xil_ultrascale.sv: CLKIN1_PERIOD=10.000),
## matching the CW340/CW341 board's PLL_CLK2 oscillator on this same pin in
## earlgrey's clocks_cw341.xdc. Must come before the MMCM output clocks below
## -- their -source pin (CLKIN1) needs an already-declared upstream clock.
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports IO_CLK]

## Explicit MMCM output clocks (clkgen_xil_ultrascale.sv: CLKFBOUT_MULT_F=12
## -> 1200MHz VCO; CLKOUT0/CLKOUT2_DIVIDE=50 -> 1200/50 = 24MHz;
## CLKOUT4_CASCADE=TRUE chains CLKOUT4_DIVIDE=40 with CLKOUT6_DIVIDE=120 ->
## 1200/(40*120) = 250kHz). Declared explicitly via -source/-multiply_by/
## -divide_by rather than the bare create_generated_clock [get_pins ...]
## auto-derive-and-rename form -- that form silently creates nothing (just a
## "could not find an automatically derived clock to rename" warning) unless
## sys_clk_pin above is already a declared clock by the time it's evaluated.
create_generated_clock -name clk_main -source [get_pins ${clkgen}/CLKIN1] \
    -multiply_by 12 -divide_by 50 [get_pins ${clkgen}/CLKOUT0]
create_generated_clock -name clk_io_pre -source [get_pins ${clkgen}/CLKIN1] \
    -multiply_by 12 -divide_by 50 [get_pins ${clkgen}/CLKOUT2]
create_generated_clock -name clk_aon -source [get_pins ${clkgen}/CLKIN1] \
    -multiply_by 12 -divide_by 4800 [get_pins ${clkgen}/CLKOUT4]

## JTAG
## Darjeeling has a single dedicated JTAG TAP (tlul_jtag_dtm), not earlgrey's
## pinmux-muxed lc/rv TAPs, so only a port-level clock declaration is given
## here for v1 -- see the TODO block below for a possible tighter,
## generated-clock refinement now that tlul_jtag_dtm's internal buffer
## (a BUFGMUX) is confirmed.
create_clock -add -name jtag_tck -period 100.00 -waveform {0 50} [get_ports JTAG_TCK]

## SPI clocks
## SPI device, host, and passthrough clocks, ported from earlgrey's
## clocks_cw341.xdc -- spi_device's internal buffer hierarchy
## (u_clk_spi_in_buf/u_clk_spi_out_buf) is shared IP and confirmed valid for
## Darjeeling, so the multicycle-path/IO-delay budgets below are ported, not
## placeholders.

set spi_dev_period 80.00
set spi_dev_half_period [expr ${spi_dev_period} / 2]

create_clock -add -name clk_spi  -period ${spi_dev_period} \
    -waveform "0 ${spi_dev_half_period}" [get_ports SPI_DEV_CLK]

## SPI Device

create_generated_clock -name clk_spi_in  -divide_by 1 -add \
    -source [get_ports SPI_DEV_CLK] \
    -master_clock [get_clocks clk_spi] \
    [get_pins ${u_spi_device}/u_clk_spi_in_buf/gen_fpga_buf.bufg_i/O]

create_generated_clock -name clk_spi_out -divide_by 1 -invert -add \
    -source [get_ports SPI_DEV_CLK] \
    -master_clock [get_clocks clk_spi] \
    [get_pins ${u_spi_device}/u_clk_spi_out_buf/gen_fpga_buf.bufg_i/O]

# CSB must act as a clock, in addition to data and a reset.
# The waveform is semi-arbitrary: This choice shows that both edges happen near
# the falling edge of clk_spi. The source clock latency constraints then
# function like set_input_delay where SPI_DEV_CS_L acts as data.
create_clock -name clk_spid_csb -period [expr 2 * ${spi_dev_period}] \
    -waveform "${spi_dev_half_period} [expr ${spi_dev_half_period} + ${spi_dev_period}]" \
    [get_ports SPI_DEV_CS_L]

## SPI Host

# SPI Host clock origin buffer
set spi_host_0_peri [get_pins ${u_clkmgr}/u_clk_io_peri_cg/gen_gate.u_bufgce/O]

# Even though it's 2x the max possible frequency, keep the peripheral clock
# frequency for the output. This will enable shifting the latch edge for hold
# analysis by the proper amount to effect "half-cycle sampling" of SPI.
create_generated_clock -name clk_spi_host0 -divide_by 2 -add \
  -source ${spi_host_0_peri} \
  -master_clock [get_clocks clk_io_pre] \
  [get_ports SPI_HOST_CLK]

## SPI Passthrough

## SPI Passthrough constraints
create_generated_clock -name clk_spi_pt -divide_by 1 -add \
    -source [get_ports SPI_DEV_CLK] \
    -master_clock [get_clocks clk_spi] \
    [get_ports SPI_HOST_CLK]


###############################
## IO DELAYS
###############################

## JTAG
set_output_delay -add_delay -clock jtag_tck -max 10.0 [get_ports JTAG_TDO]
set_output_delay -add_delay -clock jtag_tck -min -5.0 [get_ports JTAG_TDO]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -min  0.0 [get_ports {JTAG_TMS JTAG_TDI}]
set_input_delay  -add_delay -clock_fall -clock jtag_tck -max 12.5 [get_ports {JTAG_TMS JTAG_TDI}]

## SPI Device

# Max board skew between signals
set spi_dev_board_skew  0.5
# Max board delay
set spi_dev_board_delay 0.85
# Board skew affects input path for sampling
set spi_dev_in_delay_min [expr -2.0 - ${spi_dev_board_skew}]
set spi_dev_in_delay_max [expr  3.0 + ${spi_dev_board_skew}]
# The board delay affects time remaining on the output path.
set spi_dev_out_hold      -5.0
set spi_dev_out_hold_fc   -3.0
set spi_dev_out_setup     [expr  5.0 + 2 * ${spi_dev_board_delay}]

set spi_dev_data [get_ports {SPI_DEV_D0 SPI_DEV_D1 SPI_DEV_D2 SPI_DEV_D3}]

set_input_delay -clock clk_spi -clock_fall -min ${spi_dev_in_delay_min} ${spi_dev_data} -add_delay
set_input_delay -clock clk_spi -clock_fall -max ${spi_dev_in_delay_max} ${spi_dev_data} -add_delay

## For half-cycle
#set_output_delay -clock clk_spi -min ${spi_dev_out_hold}  ${spi_dev_data} -add_delay
#set_output_delay -clock clk_spi -max ${spi_dev_out_setup} ${spi_dev_data} -add_delay

## For full-cycle
set_output_delay -clock clk_spi -clock_fall -min ${spi_dev_out_hold_fc} ${spi_dev_data} -add_delay
set_output_delay -clock clk_spi -clock_fall -max ${spi_dev_out_setup}   ${spi_dev_data} -add_delay

# CSB must act as a clock, in addition to data and a reset.
# The waveform is semi-arbitrary: This choice shows that both edges happen near
# the falling edge of clk_spi. The source clock latency constraints then
# function like set_input_delay where SPI_DEV_CS_L acts as data.
set_clock_latency -source -min ${spi_dev_in_delay_min} [get_ports SPI_DEV_CS_L]
set_clock_latency -source -max ${spi_dev_in_delay_max} [get_ports SPI_DEV_CS_L]

# CSB to SPI_DEV output enables. Primarily affects generic mode with CPHA=0
# and the first bit.
# Because SPI_DEV_CS_L is a clock pin, various constraint styles will not take.
# Use output delay to constrain the allowed CSB-to-Q outputs.
set spi_dev_csb_clk_q_min -5.0
set spi_dev_csb_clk_q_max 30.0
set spi_dev_csb_out_delay_min [expr 0 - ${spi_dev_csb_clk_q_min}]
set spi_dev_csb_out_delay_max [expr ${spi_dev_period} - ${spi_dev_csb_clk_q_max}]
set_output_delay -clock clk_spid_csb -add_delay -min ${spi_dev_csb_out_delay_min} \
    ${spi_dev_data}
set_output_delay -clock clk_spid_csb -add_delay -max ${spi_dev_csb_out_delay_max} \
    ${spi_dev_data}

## SPI Host

set spi_pt_data [get_ports {SPI_HOST_D0 SPI_HOST_D1 SPI_HOST_D2 SPI_HOST_D3}]

set spi_host_board_skew 0.5
set spi_host_board_delay 0.85
set spi_host_out_hold      [expr -3.0 - ${spi_host_board_skew}]
set spi_host_out_setup     [expr  3.0 + ${spi_host_board_skew}]
set spi_host_in_delay_min 0
set spi_host_in_delay_max [expr  9.0 + 2 * ${spi_host_board_delay}]

set_output_delay -clock clk_spi_pt -min ${spi_host_out_hold}  ${spi_pt_data} -add_delay
set_output_delay -clock clk_spi_pt -max ${spi_host_out_setup} ${spi_pt_data} -add_delay
set_output_delay -clock clk_spi_pt -min ${spi_host_out_hold}  [get_ports SPI_HOST_CS_L] -add_delay
set_output_delay -clock clk_spi_pt -max ${spi_host_out_setup} [get_ports SPI_HOST_CS_L] -add_delay

set_input_delay  -clock clk_spi_pt -clock_fall -min ${spi_host_in_delay_min} \
    ${spi_pt_data} -add_delay
set_input_delay  -clock clk_spi_pt -clock_fall -max ${spi_host_in_delay_max} \
    ${spi_pt_data} -add_delay

###############################
## TIMING EXCEPTIONS
###############################

## JTAG
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

## SPI Device
# CSB-clocked status bits to various negedge-triggered flops, especially in the
# serializer.
# Advance the hold edge by one cycle, since CSB changes nominally on the same
# edge as SPI_DEV_OUT_CLK, but SPI_DEV_OUT_CLK isn't actually toggling.
set_multicycle_path -hold -end -from [get_clocks clk_spid_csb] \
    -to [get_clocks clk_spi_out] 1
# Because this section does full-cycle sampling, the same moving of the capture
# edge is needed for SPI_DEV_CSB_CLK -> SPI_DEV_D* hold analysis. The default
# falling edge of SPI_DEV_CLK would not be active.
set_multicycle_path -hold -end -from [get_clocks clk_spid_csb] \
    -to [get_clocks clk_spi] -through [get_ports ${spi_dev_data}] 1
# Relax the hold time constraint for the passthrough clock gate. Really this is
# to accommodate the gate for the inverted clock, which isn't active for the
# modes used for these constraints. However, it would be an okay outcome if the
# filter result reached the gate before even the 7th clock edge got out.
set_multicycle_path -hold -end 1 -from [get_clocks clk_spi] \
    -to [get_pins -filter "DIRECTION == IN && IS_LEAF" -of_objects \
        [get_nets -segments ${u_spi_device}/u_passthrough/sck_gate_en]]
# Since this section is for full-cycle sampling, move the capture edge out for
# data driven clk_spi_in. These cases would actually wait for the clk_spi_out
# edge to change the data on the port and get sampled by the host on the next
# clk_spi_out edge.
set_multicycle_path -setup -end 2 -from [get_clocks clk_spi_in] \
    -through [get_ports ${spi_dev_data}] \
    -to [get_clocks clk_spi]
set_multicycle_path -hold -end 2 -from [get_clocks clk_spi_in] \
    -through [get_ports ${spi_dev_data}] \
    -to [get_clocks clk_spi]

# Then mark the paths using other clocks as false paths. CSB does not actually
# sample these clocks.
set_false_path -from [get_clocks {clk_spi_in clk_spi_out clk_spi_pt}] -through ${spi_dev_data} \
    -to [get_clocks clk_spid_csb]

## SPI Host

set_multicycle_path -hold 1 -end \
    -from [get_clocks clk_spid_csb] \
    -to [get_clocks clk_spi_pt]

# Multi-cycle path to adjust the hold edge, since launch and capture edges are
# opposite in the SPI_HOST_CLK domain.
set_multicycle_path -setup 1 -start \
    -from [get_clocks -of_objects ${spi_host_0_peri}] \
    -to [get_clocks clk_spi_host0]
set_multicycle_path -hold 1 -start \
    -from [get_clocks -of_objects ${spi_host_0_peri}] \
    -to [get_clocks clk_spi_host0]

# set multicycle path for data going from SPI_HOST_CLK to logic
# the SPI host logic will read these paths at "full cycle"
set_multicycle_path -setup -end 2 \
    -from [get_clocks clk_spi_host0] \
    -to [get_clocks -of_objects ${spi_host_0_peri}]
set_multicycle_path -hold -end 2 \
    -from [get_clocks clk_spi_host0] \
    -to [get_clocks -of_objects ${spi_host_0_peri}]

set spi_host_0_data [get_ports {SPI_HOST_D0 SPI_HOST_D1 SPI_HOST_D2 SPI_HOST_D3 SPI_HOST_CS_L}]
set_output_delay -clock clk_spi_host0 -min ${spi_host_out_hold} \
    ${spi_host_0_data} -add_delay
set_output_delay -clock clk_spi_host0 -max ${spi_host_out_setup} \
    ${spi_host_0_data} -add_delay
set_input_delay  -clock clk_spi_host0 -clock_fall -min ${spi_host_in_delay_min} \
    ${spi_host_0_data} -add_delay
set_input_delay  -clock clk_spi_host0 -clock_fall -max ${spi_host_in_delay_max} \
    ${spi_host_0_data} -add_delay

## Set Asynchronous groups
set_clock_groups -asynchronous \
    -group clk_main \
    -group clk_aon \
    -group {clk_io_pre clk_spi_host0} \
    -group {clk_spi clk_spi_in clk_spi_out clk_spi_pt clk_spid_csb} \
    -group [get_clocks -include_generated_clocks jtag_tck] \
    -group sys_clk_pin

# CSB and clocks are not active simultaneously, and CSB does not actually sample
# data from these clocks.
set_clock_groups -logically_exclusive \
    -group {clk_spi} \
    -group {clk_spid_csb}

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
## - SPI device/host: confirmed -- spi_device's internal buffer hierarchy
##   (u_spi_device/u_clk_spi_{in,out}_buf/.../bufg_i/O) is shared IP,
##   unconditionally instantiated, and valid for Darjeeling. The
##   multicycle-path/IO-delay budgets and clk_spi_pt passthrough clock have
##   been ported from earlgrey's clocks_cw341.xdc using these paths. TPM mode
##   timing is not yet ported (Darjeeling's SPI_DEV_TPM_CS_L wiring/timing has
##   not been separately verified).
## - GPIO/SOC_GPI/SOC_GPO/MIO: no clock relationship, no constraints needed
##   beyond the PACKAGE_PIN/IOSTANDARD assignments in pins_darjeeling_cw341.xdc.
## ============================================================
