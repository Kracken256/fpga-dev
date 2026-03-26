#!/bin/bash

set -e

find_tool() {
    for candidate in "$@"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

RUSTC=$(find_tool rustc) || {
    echo "Error: rustc not found. Install Rust first (rustup)." >&2
    exit 1
}

OBJCOPY=$(find_tool llvm-objcopy-18 llvm-objcopy) || {
    echo "Error: llvm-objcopy not found (looked for llvm-objcopy-18/llvm-objcopy)." >&2
    exit 1
}

OBJDUMP=$(find_tool llvm-objdump-18 llvm-objdump) || {
    echo "Error: llvm-objdump not found (looked for llvm-objdump-18/llvm-objdump)." >&2
    exit 1
}

TARGET=riscv32i-unknown-none-elf

if ! "$RUSTC" --print target-list | grep -qx "$TARGET"; then
    echo "Error: Rust target $TARGET not installed." >&2
    echo "Run: rustup target add $TARGET" >&2
    exit 1
fi

echo "Building firmware..."

# Compile and link Rust firmware for RV32I.
"$RUSTC" \
    --target "$TARGET" \
    -C opt-level=s \
    -C panic=abort \
    -C lto=true \
    -C code-model=small \
    -C relocation-model=static \
    -C linker=rust-lld \
    -C link-arg=-Tlinker.ld \
    main.rs \
    -o main.elf

# Extract binary
"$OBJCOPY" -O binary main.elf main.bin

# Generate Verilog ROM from binary
python3 > ../rtl/firmware_rom.v << 'PYTHON'
import sys

# Read binary
with open('main.bin', 'rb') as f:
    data = f.read()

# Pad to multiple of 4 bytes
while len(data) % 4 != 0:
    data += b'\x00'

# Convert to words (little-endian)
words = []
for i in range(0, len(data), 4):
    word = int.from_bytes(data[i:i+4], byteorder='little')
    words.append(word)

# Generate Verilog
print("// Auto-generated firmware ROM from main.bin")
print("// Contains {} words ({} bytes)".format(len(words), len(data)))
print()
print("module firmware_rom (")
print("    input wire [31:0] addr,")
print("    output reg [31:0] data")
print(");")
print()
print("    wire [4:0] word_addr = addr[6:2];")
print()
print("    always @(*) begin")
print("        data = 32'h0000_0013; // nop")
print()
print("        case (word_addr)")

if len(words) > 32:
    print(f"Error: firmware is {len(words)} words, but ROM supports 32 words.", file=sys.stderr)
    sys.exit(1)

for i, word in enumerate(words):
    print(f"            5'd{i}:  data = 32'h{word:08x};")

print()
print("            default: data = 32'h0000_0013;")
print("        endcase")
print("    end")
print()
print("endmodule")
PYTHON

echo "✓ Generated ../rtl/firmware_rom.v"

# Show disassembly for debugging
echo ""
echo "=== Disassembly ==="
"$OBJDUMP" -d main.elf
rm main.elf main.bin