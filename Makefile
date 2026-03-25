TOP := top

# Device uses full part number for nextpnr-himbaechel.
DEVICE := GW5A-LV25MG121NC1/I0

# Family name used by both nextpnr vopt and gowin_pack.
FAMILY := GW5A-25A

RTL := fpga/$(TOP).v
CST := fpga/tang_primer_25k.cst
SDC := fpga/tang_primer_25k.sdc

BUILD_DIR := build
JSON_SYN := $(BUILD_DIR)/$(TOP).json
JSON_PNR := $(BUILD_DIR)/$(TOP)_pnr.json
BITSTREAM := $(BUILD_DIR)/$(TOP).fs

YOSYS := yosys
NEXTPNR := nextpnr-himbaechel
GOWIN_PACK := gowin_pack
PROGRAMMER := openFPGALoader

.PHONY: all check-tools synth pnr pack bitstream program program-build clean

# Default target: generate a flashable bitstream.
all: bitstream

# Fail early with clear diagnostics when required tools are missing.
check-tools:
	@command -v $(YOSYS) >/dev/null || (echo "Missing tool: $(YOSYS)" && exit 1)
	@command -v $(NEXTPNR) >/dev/null || (echo "Missing tool: $(NEXTPNR)" && exit 1)
	@command -v $(GOWIN_PACK) >/dev/null || (echo "Missing tool: $(GOWIN_PACK)" && exit 1)

# Build output directory for all generated artifacts.
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# 1) Synthesis: Verilog -> generic/tech-mapped JSON netlist.
synth: check-tools | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog $(RTL); synth_gowin -top $(TOP) -json $(JSON_SYN)"

# 2) Place and route: map netlist to Tang Primer 25K resources.
#    sspi_as_gpio aligns configuration pin behavior with the pack step.
pnr: synth
	$(NEXTPNR) \
		--json $(JSON_SYN) \
		--write $(JSON_PNR) \
		--device $(DEVICE) \
		--vopt family=$(FAMILY) \
		--vopt cst=$(CST) \
		--vopt sspi_as_gpio \
		--freq 50

# 3) Pack: routed JSON -> Gowin .fs bitstream.
#    Under sudo, prefer caller's local gowin_pack when available.
#    This avoids distro/system Python package mismatches.
pack: pnr
	@PKG_BIN="$(GOWIN_PACK)"; \
	if [ -n "$$SUDO_USER" ] && [ -x "/home/$$SUDO_USER/.local/bin/gowin_pack" ]; then \
		PKG_BIN="/home/$$SUDO_USER/.local/bin/gowin_pack"; \
	fi; \
	$$PKG_BIN -d $(FAMILY) --sspi_as_gpio -s $(SDC) -o $(BITSTREAM) $(JSON_PNR)

# Convenience alias for full build pipeline.
bitstream: pack

# Program only: requires an existing bitstream from a prior build.
# This is useful when flashing with sudo but building as normal user.
program:
	@test -f $(BITSTREAM) || (echo "Missing bitstream: $(BITSTREAM). Run 'make bitstream' first." && exit 1)
	$(PROGRAMMER) -b tangprimer25k $(BITSTREAM)

# Build and program in one command.
# Keep this target for convenience when environment supports it.
program-build: bitstream
	$(PROGRAMMER) -b tangprimer25k $(BITSTREAM)

# Remove generated artifacts.
clean:
	rm -rf $(BUILD_DIR)
