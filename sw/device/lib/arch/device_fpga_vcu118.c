// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>

#include "sw/device/lib/arch/device.h"
#include "sw/device/lib/base/macros.h"
#include "sw/device/silicon_creator/lib/drivers/ibex.h"
#include "sw/device/silicon_creator/lib/drivers/uart.h"

/**
 * @file
 * @brief Device-specific symbol definitions for the AMD/Xilinx VCU118
 * device.
 *
 * clkgen_xil_ultrascale's MMCM is configured (see
 * hw/top_darjeeling/templates/chiplevel.sv.tpl's vcu118 branch) to reproduce
 * the exact same 1200MHz VCO -- and therefore the exact same output
 * frequencies -- as the cw340 target does from its own, differently
 * -frequenced reference clock (90MHz EMCCLK here vs. 100MHz IO_CLK there).
 * So these clock constants are intentionally identical to
 * device_fpga_cw340.c's, not board-specific values.
 */

const device_type_t kDeviceType = kDeviceFpgaVcu118;

const uint64_t kClockFreqCpuMhz = 24;

const uint64_t kClockFreqCpuHz = kClockFreqCpuMhz * 1000 * 1000;

uint64_t to_cpu_cycles(uint64_t usec) { return usec * kClockFreqCpuMhz; }

const uint64_t kClockFreqHiSpeedPeripheralHz = 24 * 1000 * 1000;  // 24MHz

const uint64_t kClockFreqPeripheralHz = 6 * 1000 * 1000;  // 6MHz

const uint64_t kClockFreqUsbHz = 48 * 1000 * 1000;  // 48MHz

const uint64_t kClockFreqAonHz = 250 * 1000;  // 250kHz

const uint64_t kUartBaudrate = 115200;

const uint32_t kUartNCOValue =
    CALCULATE_UART_NCO(kUartBaudrate, kClockFreqPeripheralHz);

const uint32_t kUartBaud115K =
    CALCULATE_UART_NCO(115200, kClockFreqPeripheralHz);
const uint32_t kUartBaud230K =
    CALCULATE_UART_NCO(115200 * 2, kClockFreqPeripheralHz);
const uint32_t kUartBaud460K =
    CALCULATE_UART_NCO(115200 * 4, kClockFreqPeripheralHz);
const uint32_t kUartBaud921K =
    CALCULATE_UART_NCO(115200 * 8, kClockFreqPeripheralHz);
const uint32_t kUartBaud1M33 =
    CALCULATE_UART_NCO(1333333, kClockFreqPeripheralHz);
const uint32_t kUartBaud1M50 =
    CALCULATE_UART_NCO(1500000, kClockFreqPeripheralHz);

const uint32_t kAstCheckPollCpuCycles =
    CALCULATE_AST_CHECK_POLL_CPU_CYCLES(kClockFreqCpuHz);

uintptr_t device_test_status_address(void) { return 0; }

uintptr_t device_log_bypass_uart_address(void) { return 0; }

const bool kJitterEnabled = false;
