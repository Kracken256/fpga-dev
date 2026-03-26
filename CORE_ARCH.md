# RISC-V Core Architecture

## Overall Architecture: Von Neumann Single-Port, 2-Cycle In-Order

The core implements a **simplified RV32I processor** with a single shared memory bus and a two-phase fetch/execute pipeline using state machine sequencing.

---

## Key Architectural Features

### 1. Memory Interface (Single Shared Bus)

- **One unified memory port** carrying both instruction fetches and load/store operations
- Signals:
  - `mem_re` (read enable)
  - `mem_we` (write enable)
  - `mem_addr` (32-bit address)
  - `mem_rdata` (32-bit read data)
  - `mem_wdata` (32-bit write data)
  - `mem_wstrb` (4-bit per-byte write strobes)
- This is a **true Von Neumann architecture**—instruction and data contend on the same bus

### 2. Fetch/Execute Phase Machine

- **Two-cycle instruction execution**:
  - **Phase 0 (Fetch)**: `mem_re = 1`, `mem_addr = pc` — load instruction from memory into `instr_reg`
  - **Phase 1 (Execute)**: decode and execute instruction from `instr_reg`, optionally issue load/store
- Toggled via `exec_phase` register (0=fetch, 1=execute)
- **Stalls cannot occur**—every instruction takes exactly 2 cycles (fetch + execute)

### 3. Register File

- **32 × 32-bit registers** (`regs[0:31]`)
- **x0 (zero) is hardwired to 0** on every cycle
- Single-cycle read (combinational), write-back in execute phase only
- No bypassing/forwarding—data hazards cause incorrect behavior (intentional simplification)

### 4. Program Counter

- **32-bit PC**, initialized to 0
- Increments by 4 on successful execute phase (word-aligned)
- Updated by branch/jump instructions (JAL, JALR, conditional branches)

---

## Instruction Decode and Execution

### Instruction Fields (decoded combinationally)

- `opcode` [6:0] — determines instruction class
- `rd` [11:7] — destination register
- `rs1` [19:15], `rs2` [24:20] — source registers
- `funct3` [14:12] — sub-function within instruction class
- `funct7` [31:25] — further sub-function (ALU ops, shifts)

### Immediate Encoding (5 formats supported)

- **I-type**: `{{20{sign}}, instr[31:20]}` — loads, ADDI, shifts immediate
- **S-type**: `{{20{sign}}, instr[31:25], instr[11:7]}` — store address offset
- **B-type**: `{{19{sign}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}` — branch offset (<<1)
- **U-type**: `{instr[31:12], 12'b0}` — upper immediate (LUI, AUIPC)
- **J-type**: `{{11{sign}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}` — JAL offset (<<1)

---

## Supported Instructions

### Loads

- LW, LB, LBU, LH, LHU
- Byte/half-word sub-word selection via `load_addr[1:0]`

### Stores

- SB, SH, SW
- Per-byte write strobes via `mem_wstrb[3:0]`

### Immediate ALU

- ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
- Shift amounts from `instr[24:20]`

### Register ALU

- ADD, SUB, SLL, SLT, SLTU, XOR, OR, AND, SRL, SRA
- funct7 distinguishes ADD/SUB, SRL/SRA

### Branches

- BEQ, BNE, BLT, BGE, BLTU, BGEU
- Signed/unsigned comparison on rs1_val, rs2_val

### Jumps

- JAL, JALR
- Return address (PC+4) written to rd if rd≠0

### Upper Immediates

- LUI, AUIPC
- Load upper bits, optionally added to PC

### Fences/System

- FENCE, FENCE.I, ECALL, EBREAK
- Treated as no-ops (no trap support)

---

## Data Path Highlights

### Operand Selection

- **rs1_val, rs2_val**: forwarded from `regs[]`, with x0 hardwired to 0
- **Signed vs. Unsigned**: separate signed/unsigned wires (`rs1_s`, `rs2_s`) for comparison and shift operations

### Load/Store Addressing

- **Load address**: `rs1_val + imm_i` (I-type immediate)
- **Store address**: `rs1_val + imm_s` (S-type immediate)
- **Byte lane extraction**: `load_byte` and `load_half` use low 2 bits of load address to select bytes/words
- **Write strobes**: computed from store address alignment and funct3 to enable per-byte masking

### Write-Back Logic

- **wb_en**: gated by decode—only asserted for instructions that write registers
- **wb_data**: result mux selects load data, ALU output, PC+4 (for JAL/JALR), or immediates
- **Writes blocked**: if rd=0 (x0) or invalid instruction

---

## Pipeline Behavior

| Cycle | Phase   | Action                                                                   |
| ----- | ------- | ------------------------------------------------------------------------ |
| N     | Fetch   | PC→mem_addr, mem_re=1, await mem_rdata (instr_reg latched at cycle N+1)  |
| N+1   | Execute | decode instr_reg, perform ALU/load/store, update PC or branch to next_pc |
| N+2   | Fetch   | next instruction load begins                                             |

- **No hazard stalls**: Every instruction is 2 cycles, no exceptions or wait states
- **Data hazards**: RAW (read-after-write) hazards will cause incorrect results if not avoided in firmware
- **No branch prediction**: taken branches cost 2 cycles like any other instruction

---

## Limitations & Simplifications

1. **No pipelining**: 2-cycle CPI floor, cannot overlap fetch/execute across instructions
2. **No forwarding**: register reads are stale; hazards cause data corruption
3. **No interrupt support**: ECALL/EBREAK are no-ops
4. **No CSR reads/writes**: system registers not accessed
5. **No PMU counters**: no performance instrumentation
6. **Unaligned access unsupported**: load addresses with non-zero low bits select sub-words but don't trap
7. **No MMU/virtual memory**: flat address space
8. **Always little-endian**: sub-word reads/writes assume LE byte ordering

---

## Synthesis Characteristics

- **Logic depth**: 2-4 levels (decode, ALU, mux, FF)
- **Critical path**: ALU result → register write or next PC computation
- **Achieved frequency**: 90.99 MHz on GW5A-25A (50 MHz target, 45% slack)
- **Area**: ~30K LUT4 (medium embedded CPU)

---

## Summary

This is a **minimalist, educational RV32I core** optimized for simplicity and correctness over performance. The Von Neumann single-port memory architecture and 2-cycle fetch/execute pipeline make it suitable for embedded applications and pedagogical study of processor design.
