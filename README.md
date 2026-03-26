# Tang Primer 25K RISC-V Soft Core

This repository contains a compact RV32 soft core implementation targeting the Tang Primer 25K (GW5A-LV25MG121NC1/I0) with a fully open-source build flow.

## Design Overview

- `fpga/top.v` is a thin board wrapper (clock + LED pins).
- `rtl/riscv_soc.v` contains the SoC integration (reset, ROM, GPIO peripheral).
- `rtl/riscv_core.v` contains the CPU core only.
- `rtl/firmware_rom.v` contains the firmware image (instruction ROM contents).
- The current SoC has memory-mapped GPIO and ROM-backed instruction fetch.
- `fpga/tang_primer_25k.cst` contains board pin constraints.
- `fpga/tang_primer_25k.sdc` contains a 50 MHz timing constraint.

## CPU and SoC Details

- ISA coverage: compact RV32I subset used by the bundled firmware (loads/stores, ALU ops, branches, jumps, LUI/AUIPC).
- Reset: internal power-on reset counter.
- Memory map:
  - `0x4000_0000`: GPIO output register
- LED mapping:
  - `led0` = `GPIO[0]`
  - `led1` = inverse of `GPIO[0]`

## Included Firmware

The ROM contains a simple hand-coded RISC-V program that:

1. Sets up the GPIO base address.
2. Runs a software delay loop.
3. Writes an incrementing value to GPIO.

Result: `led0` blinks under software control from the RISC-V core, and `led1` mirrors the inverse state.

## Toolchain Requirements

Install these tools:

- `yosys`
- `nextpnr-himbaechel` (with Gowin support)
- `gowin_pack`
- `openFPGALoader` (optional, only needed for `make program`)

## Make Targets

- `make check-tools`
  - Verifies required tools are available in PATH.
- `make synth`
  - Runs Yosys and generates `build/top.json`.
- `make pnr`
  - Runs nextpnr-himbaechel and generates `build/top_pnr.json`.
- `make pack` or `make bitstream`
  - Runs gowin_pack and generates `build/top.fs`.
- `make program`
  - Programs the board using an existing `build/top.fs`.
- `make program-build`
  - Builds and then programs in one command.
- `make clean`
  - Removes the `build/` directory.

## Build

```sh
make bitstream
```

Generated output:

- `build/top.fs`

## Program the Board

```sh
make program
```

This target expects an existing bitstream (`build/top.fs`) and then runs:

```sh
openFPGALoader -b tangprimer25k build/top.fs
```

If your Linux user does not have USB permissions for the FTDI interface, use:

```sh
sudo make program
```

Typical workflow:

```sh
make bitstream
sudo make program
```

## Pin Notes

Current constraints are set to:

- `clk50` -> `E2`
- `led0` -> `E8`
- `led1` -> `D7`

If your board revision or dock mapping differs, edit `fpga/tang_primer_25k.cst`.
