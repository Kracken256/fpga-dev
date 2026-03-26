# AGENTS

## Purpose

This file provides default guidance for coding agents working in this repository.

## Project Context

- Target board: Sipeed Tang Primer 25K Dock + SoM (Gowin GW5A-LV25MG121)
- Primary language: Verilog
- Build flow: yosys -> nextpnr-himbaechel -> gowin_pack
- Main entrypoint: fpga/top.v

## RTL Structure

- fpga/top.v: board wrapper and top-level pin mapping
- rtl/riscv_soc.v: SoC integration (reset, peripheral decode, ROM hookup)
- rtl/riscv_core.v: CPU core logic
- rtl/firmware_rom.v: instruction ROM contents

Keep this separation intact:

- Core should remain board-agnostic.
- SoC should handle memory map and peripheral glue.
- Top should only handle board I/O and SoC instantiation.

## Build Commands

- make check-tools
- make synth
- make pnr
- make bitstream
- make program

## Constraints and Timing

- Pin constraints: fpga/tang_primer_25k.cst
- Timing constraints: fpga/tang_primer_25k.sdc
- Default design target is 50 MHz.

When changing clocks, always update timing constraints and re-run full build.

## Coding Guidelines

- Prefer small, explicit Verilog modules over monolithic files.
- Preserve existing signal names unless there is a clear benefit to rename.
- Keep memory map constants centralized in SoC-level modules.
- Avoid adding vendor-specific primitives unless necessary.
- Add short comments only where logic is non-obvious.

## Validation Expectations

After RTL changes:

1. Run make bitstream
2. Confirm no synthesis or PNR errors
3. Confirm timing passes at 50 MHz
4. Verify bitstream artifact exists in build/top.fs

## Documentation Expectations

If behavior or architecture changes, update:

- README.md
- HARDWARE.md (if board-related assumptions changed)
