# Tang Primer 25K Setup

This repository now includes a complete open-source FPGA flow for the Tang Primer 25K (GW5A-LV25MG121NC1/I0).

## What Was Added

- `fpga/top.v`: minimal LED blinker top module.
- `fpga/tang_primer_25k.cst`: board pin constraints.
- `fpga/tang_primer_25k.sdc`: 50 MHz clock timing constraint.
- `Makefile`: build, pack, and flash targets.

## LED Behavior

- Clock source is assumed to be 50 MHz (`clk50`).
- `led0` toggles every 5 seconds.
- `led1` is always the inverse of `led0`.
- A full `led0` blink cycle (on -> off -> on) is 10 seconds.

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
