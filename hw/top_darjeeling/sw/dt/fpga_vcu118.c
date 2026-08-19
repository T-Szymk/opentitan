// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "hw/top/dt/api.h"  // Generated

// Frequencies produced by hw/top_darjeeling/rtl/clkgen_xil_ultrascale.sv's
// MMCM configuration for the vcu118 target (90MHz EMCCLK reference,
// DIVCLK_DIVIDE=3, CLKFBOUT_MULT_F=40.000 -- same 1200MHz VCO, and therefore
// the same output frequencies, as the cw340 target's 100MHz-reference
// config; see fpga_cw340.c and chiplevel.sv.tpl's vcu118 branch).
static const uint32_t clock_freqs[kDtClockCount] = {
    [kDtClockMain] = 24 * 1000 * 1000,
    [kDtClockIo] = 24 * 1000 * 1000,
    [kDtClockAon] = 250 * 1000,
};

uint32_t dt_clock_frequency(dt_clock_t clk) {
  if (clk < kDtClockCount) {
    return clock_freqs[clk];
  }
  return 0;
}
