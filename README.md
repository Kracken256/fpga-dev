# Tang Primer 25K RISC-V Soft Core

This repository contains a compact RV32 soft core targeting the Sipeed Tang Primer 25K (GW5A-LV25MG121NC1/I0), with a Docker-first open-source build flow.

## Design Overview

- `fpga/top.v`: board wrapper and pin-level I/O
- `rtl/riscv_soc.v`: SoC integration (reset, single-bus shared memory hookup, GPIO/UART map)
- `rtl/riscv_core.v`: CPU core logic (fetch/execute over one shared memory port)
- `rtl/uart_tx.v`: UART transmitter peripheral
- `rtl/firmware_rom.v`: generated shared firmware memory contents
- `firmware/src/main.rs`: firmware entrypoint (Rust, no_std)
- `firmware/src/*.rs`: additional firmware modules
- `firmware/build_rom.sh`: compiles Rust firmware and regenerates `rtl/firmware_rom.v`

## Current SoC Memory Map

- `0x0000_0000` - `0x0000_007F`: shared firmware memory (instruction + load reads)
- `0x4000_0000`: GPIO output register
- `0x4000_0004`: UART TX write / UART ready read

LED mapping in `fpga/top.v`:

- `led0` = `GPIO[0]`
- `led1` = inverse of `GPIO[0]`

## Firmware Flow

Firmware is authored as a Cargo package in `firmware/src/` and converted into a Verilog ROM module:

1. `cargo rustc` compiles firmware for `riscv32i-unknown-none-elf`
2. Assembly is extracted to `firmware/build/main.s`
3. `llvm-objcopy` extracts raw binary from ELF
4. `firmware/build_rom.sh` writes `rtl/firmware_rom.v`

The build script enforces the current ROM size limit (32 words).

Current firmware behavior:

- Writes `"Hello, World!\n"` to UART once
- Enters an infinite loop

## Docker-Only Workflow

The Makefile is Docker-only at the host level. Running normal targets like `make bitstream` or `make program-build` will execute inside the container image `riscv-soft-core:dev`.

### Prerequisite

- Docker

### Main Commands

Build image:

```sh
make docker-build
```

Open shell in container:

```sh
make docker-shell
```

Generate firmware ROM only:

```sh
make firmware
```

Build bitstream:

```sh
make bitstream
```

Program existing bitstream (persistent, writes on-board flash):

```sh
make program
```

Build and program:

```sh
make program-build
```

Notes:

- `make program` and `make program-build` use a privileged container and mount `/dev/bus/usb`.
- `make program` now programs flash (`openFPGALoader -f`), so the bitstream persists after power cycle.
- If image `riscv-soft-core:dev` does not exist, Makefile auto-builds it.

## Docker Compose (Optional)

The repository also includes `docker-compose.yml` with two services:

- `fpga`: build-only workflows
- `fpga-usb`: privileged USB passthrough for programming

Examples:

```sh
docker compose run --rm fpga make IN_DOCKER=1 _bitstream
docker compose run --rm fpga-usb make IN_DOCKER=1 _program-build
```

## Make Targets

Public host-level targets:

- `make check-tools` (checks Docker only)
- `make docker-build`
- `make docker-shell`
- `make firmware`
- `make synth`
- `make pnr`
- `make pack`
- `make bitstream`
- `make program`
- `make program-build`
- `make clean`

Internal in-container targets (used by Makefile forwarding):

- `_check-tools`, `_firmware`, `_synth`, `_pnr`, `_pack`, `_bitstream`, `_program`, `_program-build`

## Build Artifacts

- `build/top.json`: synthesized netlist
- `build/top_pnr.json`: placed/routed netlist
- `build/top.fs`: final bitstream

## Constraints

- Pin constraints: `fpga/tang_primer_25k.cst`
- Timing constraints: `fpga/tang_primer_25k.sdc`
- Target frequency: 50 MHz
