## Copyright lowRISC contributors (OpenTitan project).
## Licensed under the Apache License, Version 2.0, see LICENSE for details.
## SPDX-License-Identifier: Apache-2.0

## ChipWhisperer CW340 + CW341 "Luna Board", Darjeeling target.
##
## Physical PACKAGE_PIN assignments below are split into two groups:
##
## 1) Pins reused verbatim from hw/top_earlgrey/data/pins_cw341.xdc. These are
##    either the same infrastructure signal (IO_CLK, POR_N, IO_CLKOUT,
##    IO_TRIGGER, JTAG_*) or a Darjeeling DIO landing on a board net that
##    earlgrey's own XDC documents as a generic, not fixed-function pad
##    (earlgrey's comments there state "All MIOs are connected to nets of the
##    same name (prefixed with OT_) in the PCB design" and label several pins
##    simply "GPIO"/"UARTn_RX"/"UARTn_TX" for whichever signal earlgrey happens
##    to mux there) -- i.e. the copper trace has no fixed function, so reusing
##    it for a different, equally general-purpose Darjeeling signal is safe.
##
## 2) TODO(hw-bringup) placeholders: Darjeeling exposes far more direct pads
##    (32x GPIO, 12x SOC_GPI, 12x SOC_GPO, 12x MIO) than earlgrey's XDC has
##    verified spare pins for (~22, all consumed by group 1 below). The
##    CW340/CW341 schematic (not present in this repository) must be
##    consulted to find further free FPGA-connected header/expansion pins
##    before these can be assigned. They are deliberately left WITHOUT a
##    PACKAGE_PIN assignment -- Vivado will flag them as unconstrained rather
##    than silently accepting a guessed pin on real hardware. Do not assign
##    these from guesswork.

## ============================================================
## Group 1: verified pins (reused from pins_cw341.xdc)
## ============================================================

## Clock Signal
set_property -dict { PACKAGE_PIN E22 IOSTANDARD LVCMOS18 } [get_ports { IO_CLK }]; # PLL_CLK2, drives clkgen_xil_ultrascale

## Power-on Reset
set_property -dict { PACKAGE_PIN  G26 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { POR_N }]; # Main PORN, requires jumper to SW0 CW340:SAM3X_OT_POR SAM3X:PC30

## JTAG (Darjeeling wires JTAG via dedicated manual pads, not pinmux straps)
set_property -dict { PACKAGE_PIN AL33 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { JTAG_TMS    }]; # earlgrey IOR0
set_property -dict { PACKAGE_PIN AK27 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { JTAG_TDO    }]; # earlgrey IOR1
set_property -dict { PACKAGE_PIN AK31 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { JTAG_TDI    }]; # earlgrey IOR2
set_property -dict { PACKAGE_PIN AL34 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { JTAG_TCK    }]; # earlgrey IOR3
set_property -dict { PACKAGE_PIN AJ34 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { JTAG_TRST_N }]; # earlgrey IOR4

## ChipWhisperer 20-Pin Connector (J14) -- reserved, unused for v1 bring-up
set_property -dict { PACKAGE_PIN AM11 IOSTANDARD LVCMOS18 } [get_ports { IO_TRIGGER }]; # CW341:CWIO_IO4
set_property -dict { PACKAGE_PIN AK12 IOSTANDARD LVCMOS18 } [get_ports { IO_CLKOUT  }]; # CW341:CWIO_HS1

## SPI device
set_property -dict { PACKAGE_PIN AM30 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_CLK  }]; # CW341:OT_SPI_DEVICE_CLK
set_property -dict { PACKAGE_PIN AL30 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_D0   }]; # CW341:OT_SPI_DEVICE_D0
set_property -dict { PACKAGE_PIN AM26 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_D1   }]; # CW341:OT_SPI_DEVICE_D1
set_property -dict { PACKAGE_PIN AN32 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_D2   }]; # CW341:OT_SPI_DEVICE_D2
set_property -dict { PACKAGE_PIN AN34 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_D3   }]; # CW341:OT_SPI_DEVICE_D3
set_property -dict { PACKAGE_PIN AM34 IOSTANDARD LVCMOS18 } [get_ports { SPI_DEV_CS_L }]; # CW341:OT_SPI_DEVICE_CS_L
## No physical TPM CS pin verified on the CW341 for a direct Darjeeling pad; see Group 2.

## SPI host
set_property -dict { PACKAGE_PIN AP31 IOSTANDARD LVCMOS18 } [get_ports { SPI_HOST_CLK  }]; # CW341:OT_SPI_HOST_CLK
set_property -dict { PACKAGE_PIN AP33 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { SPI_HOST_D0   }]; # CW341:OT_SPI_HOST_D0
set_property -dict { PACKAGE_PIN AP34 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { SPI_HOST_D1   }]; # CW341:OT_SPI_HOST_D1
set_property -dict { PACKAGE_PIN AL27 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { SPI_HOST_D2   }]; # CW341:OT_SPI_HOST_D2
set_property -dict { PACKAGE_PIN AN33 IOSTANDARD LVCMOS18 PULLTYPE PULLUP } [get_ports { SPI_HOST_D3   }]; # CW341:OT_SPI_HOST_D3
set_property -dict { PACKAGE_PIN AL32 IOSTANDARD LVCMOS18 } [get_ports { SPI_HOST_CS_L }]; # CW341:OT_SPI_HOST_CS_L

## UART -- reusing earlgrey's UART0 (IOC3/IOC4) physical pins. On the PCB these
## are generic muxed-IO nets; earlgrey happens to route its own pinmux-muxed
## UART0 there, but the copper itself is general purpose.
set_property -dict { PACKAGE_PIN P25 IOSTANDARD LVCMOS18 } [get_ports { UART_RX }]; # earlgrey IOC3 (UART0_RX)
set_property -dict { PACKAGE_PIN N24 IOSTANDARD LVCMOS18 } [get_ports { UART_TX }]; # earlgrey IOC4 (UART0_TX)

## I2C -- reusing earlgrey's I2C_HOST_SCL/SDA (IOB10/IOB9) physical pins.
set_property -dict { PACKAGE_PIN AM12 IOSTANDARD LVCMOS18 } [get_ports { I2C_SCL }]; # earlgrey IOB10 (I2C_HOST_SCL)
set_property -dict { PACKAGE_PIN AP11 IOSTANDARD LVCMOS18 } [get_ports { I2C_SDA }]; # earlgrey IOB9  (I2C_HOST_SDA)

## GPIO0-17 -- reusing earlgrey's "GPIO"-labeled spare pins, including the
## board's LED-connected pins (IOR6/8/9/10/11/12/13), which are a good choice
## for a first liveness bring-up test (toggle -> observe LED).
set_property -dict { PACKAGE_PIN AH32 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO0  }]; # earlgrey IOR6  (LED0)
set_property -dict { PACKAGE_PIN AH34 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO1  }]; # earlgrey IOR8  (LED2)
set_property -dict { PACKAGE_PIN AH31 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO2  }]; # earlgrey IOR9  (LED3)
set_property -dict { PACKAGE_PIN AH27 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO3  }]; # earlgrey IOR10 (LED4)
set_property -dict { PACKAGE_PIN AH33 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO4  }]; # earlgrey IOR11 (LED5)
set_property -dict { PACKAGE_PIN AH28 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO5  }]; # earlgrey IOR12 (LED6)
set_property -dict { PACKAGE_PIN AH26 DRIVE 8 IOSTANDARD LVCMOS18 } [get_ports { GPIO6  }]; # earlgrey IOR13 (LED7)
set_property -dict { PACKAGE_PIN AN27 IOSTANDARD LVCMOS18 } [get_ports { GPIO7  }]; # earlgrey IOA2
set_property -dict { PACKAGE_PIN AP26 IOSTANDARD LVCMOS18 } [get_ports { GPIO8  }]; # earlgrey IOA3
set_property -dict { PACKAGE_PIN AP29 IOSTANDARD LVCMOS18 } [get_ports { GPIO9  }]; # earlgrey IOA6
set_property -dict { PACKAGE_PIN AM10 IOSTANDARD LVCMOS18 } [get_ports { GPIO10 }]; # earlgrey IOB6
set_property -dict { PACKAGE_PIN AP10 IOSTANDARD LVCMOS18 } [get_ports { GPIO11 }]; # earlgrey IOB7
set_property -dict { PACKAGE_PIN AL9  IOSTANDARD LVCMOS18 } [get_ports { GPIO12 }]; # earlgrey IOB8
set_property -dict { PACKAGE_PIN M27  IOSTANDARD LVCMOS18 } [get_ports { GPIO13 }]; # earlgrey IOC6
set_property -dict { PACKAGE_PIN K26  IOSTANDARD LVCMOS18 } [get_ports { GPIO14 }]; # earlgrey IOC9
set_property -dict { PACKAGE_PIN J26  IOSTANDARD LVCMOS18 } [get_ports { GPIO15 }]; # earlgrey IOC10
set_property -dict { PACKAGE_PIN H24  IOSTANDARD LVCMOS18 } [get_ports { GPIO16 }]; # earlgrey IOC11
set_property -dict { PACKAGE_PIN H26  IOSTANDARD LVCMOS18 } [get_ports { GPIO17 }]; # earlgrey IOC12

## MIO0-3 -- reusing earlgrey's unused UART2/UART3 pins (IOA0/1/4/5); Darjeeling
## has no UART2/3, so these copper traces are otherwise idle.
set_property -dict { PACKAGE_PIN AN26 IOSTANDARD LVCMOS18 } [get_ports { MIO0 }]; # earlgrey IOA0
set_property -dict { PACKAGE_PIN AK26 IOSTANDARD LVCMOS18 } [get_ports { MIO1 }]; # earlgrey IOA1
set_property -dict { PACKAGE_PIN AP28 IOSTANDARD LVCMOS18 } [get_ports { MIO2 }]; # earlgrey IOA4
set_property -dict { PACKAGE_PIN AM27 IOSTANDARD LVCMOS18 } [get_ports { MIO3 }]; # earlgrey IOA5

## ============================================================
## Group 2: TODO(hw-bringup) -- no verified physical pin yet.
## Consult the CW340/CW341 schematic for further free FPGA-connected
## header/expansion pins before synthesizing. DO NOT guess PACKAGE_PIN
## values for these -- an unconstrained port is safer than a wrong one.
## ============================================================
## SPI_DEV_TPM_CS_L
## GPIO18, GPIO19, GPIO20, GPIO21, GPIO22, GPIO23, GPIO24, GPIO25, GPIO26,
##   GPIO27, GPIO28, GPIO29, GPIO30, GPIO31
## SOC_GPI0, SOC_GPI1, SOC_GPI2, SOC_GPI3, SOC_GPI4, SOC_GPI5, SOC_GPI6,
##   SOC_GPI7, SOC_GPI8, SOC_GPI9, SOC_GPI10, SOC_GPI11
## SOC_GPO0, SOC_GPO1, SOC_GPO2, SOC_GPO3, SOC_GPO4, SOC_GPO5, SOC_GPO6,
##   SOC_GPO7, SOC_GPO8, SOC_GPO9, SOC_GPO10, SOC_GPO11
## MIO4, MIO5, MIO6, MIO7, MIO8, MIO9, MIO10, MIO11

## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
