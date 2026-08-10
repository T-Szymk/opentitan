// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdint.h>

#include "hw/top/dt/api.h"  // Generated

// Frequencies produced by hw/top_darjeeling/rtl/clkgen_xil_ultrascale.sv's
// MMCM configuration (shared verbatim with earlgrey's cw340 clkgen, see
// hw/top_earlgrey/sw/dt/fpga_cw340.c's clk_main/io/aon entries).
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
