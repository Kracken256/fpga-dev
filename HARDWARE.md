# Hardware Reference: Sipeed Tang Primer 25K Dock

## Product

- Name: youyeetoo Sipeed Tang Primer 25K Dock FPGA Development Board
- FPGA family: Gowin GW5A
- Device (on SoM): GW5A-LV25MG121
- Package mention: 25K Basic Package
- Logic capacity (listing): about 23K LUT4

## High-Level Architecture

This platform is split into two parts:

1. Tang Primer 25K SoM (System on Module)

- Compact FPGA compute module
- Includes FPGA, SPI flash, power management, and board-to-board connector

2. Tang Primer 25K Dock

- Baseboard used with the SoM
- Exposes debug, PMOD, and expansion interfaces for peripherals

## Tang Primer 25K SoM Details (from listing)

- FPGA: Gowin GW5A-LV25MG121
- SPI flash: 64 Mbit
- Power: onboard DC-DC supply
- GPIO: up to 76 GPIOs exposed
- MIPI: 1 hard-core 4-lane MIPI D-PHY
- Power outputs: 3 rails exposed
- Form factor: coin-sized compact SoM with BTB connector

## Tang Primer 25K Dock Details (from listing)

- Integrated USB-JTAG debugger
- 3x PMOD interfaces
- 1x 40-pin header interface
- Typical PMOD use cases:
  - HDMI module
  - gamepad module
  - LED module
- Typical 40-pin expansion use cases:
  - SDRAM module
  - dual DVP camera modules

## Connectivity and Expansion Summary

- PMOD is best for simple/modular peripherals.
- 40-pin header is best for wider or higher-bandwidth external modules.
- The SoM + Dock combination allows rapid prototyping with external I/O.

## Memory and Bus Notes for This Board

- Built-in non-volatile memory: 64 Mbit SPI flash on the SoM.
- Built-in volatile memory on FPGA fabric: on-chip block RAM resources inside the GW5A FPGA.
- External memory: possible through expansion interfaces (for example SDRAM modules on the 40-pin path).
- Bus architecture: FPGA boards do not provide a fixed CPU memory bus by default; memory buses are created in your HDL design (for example simple custom bus, Wishbone, or AXI-style interconnect).

## Power and Bring-Up

- Provide 5V input to the SoM/Dock setup.
- Configure FPGA bitstream correctly for your target design and pin constraints.
- Use onboard USB-JTAG for programming and debug.

## Practical Project Notes

For this repository:

- Keep board-level pin mapping in fpga/tang_primer_25k.cst.
- Keep timing constraints in fpga/tang_primer_25k.sdc.
- Keep CPU and SoC modules separate from board wrapper for portability.

## Source Context

This document is normalized from the product description text provided in chat, including repeated marketing content, with duplicates removed and details grouped by function.
