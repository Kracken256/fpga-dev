TOP := top

# Device uses full part number for nextpnr-himbaechel.
DEVICE := GW5A-LV25MG121NC1/I0

# Family name used by both nextpnr vopt and gowin_pack.
FAMILY := GW5A-25A

RTL := fpga/$(TOP).v rtl/riscv_core.v rtl/riscv_soc.v rtl/uart_tx.v rtl/firmware_rom.v
CST := fpga/tang_primer_25k.cst
SDC := fpga/tang_primer_25k.sdc

FW_SCRIPT := firmware/build_rom.sh
FW_SRC := firmware/main.rs firmware/linker.ld
FW_ROM := rtl/firmware_rom.v

BUILD_DIR := build
JSON_SYN := $(BUILD_DIR)/$(TOP).json
JSON_PNR := $(BUILD_DIR)/$(TOP)_pnr.json
BITSTREAM := $(BUILD_DIR)/$(TOP).fs

YOSYS := yosys
NEXTPNR := nextpnr-himbaechel
GOWIN_PACK := gowin_pack
PROGRAMMER := openFPGALoader

DOCKER_IMAGE := riscv-soft-core:dev
DOCKER_RUN := docker run --rm -v $(CURDIR):/workspace -w /workspace $(DOCKER_IMAGE)
DOCKER_RUN_USB := docker run --rm --privileged -v /dev/bus/usb:/dev/bus/usb -v $(CURDIR):/workspace -w /workspace $(DOCKER_IMAGE)

.PHONY: all check-tools ensure-docker-image docker-build docker-shell firmware synth pnr pack bitstream program program-build clean
.PHONY: _check-tools _firmware _synth _pnr _pack _bitstream _program _program-build

all: bitstream

check-tools:
	@command -v docker >/dev/null || (echo "Missing tool: docker" && exit 1)

docker-build: check-tools
	docker build -t $(DOCKER_IMAGE) .

ensure-docker-image: check-tools
	@docker image inspect $(DOCKER_IMAGE) >/dev/null 2>&1 || docker build -t $(DOCKER_IMAGE) .

docker-shell: ensure-docker-image
	$(DOCKER_RUN) bash

ifeq ($(IN_DOCKER),1)

_check-tools:
	@command -v $(YOSYS) >/dev/null || (echo "Missing tool: $(YOSYS)" && exit 1)
	@command -v $(NEXTPNR) >/dev/null || (echo "Missing tool: $(NEXTPNR)" && exit 1)
	@command -v $(GOWIN_PACK) >/dev/null || (echo "Missing tool: $(GOWIN_PACK)" && exit 1)
	@command -v $(PROGRAMMER) >/dev/null || (echo "Missing tool: $(PROGRAMMER)" && exit 1)
	@command -v cargo >/dev/null || (echo "Missing tool: cargo" && exit 1)
	@command -v rustc >/dev/null || (echo "Missing tool: rustc" && exit 1)
	@command -v rustup >/dev/null || (echo "Missing tool: rustup" && exit 1)
	@command -v python3 >/dev/null || (echo "Missing tool: python3" && exit 1)
	@command -v bash >/dev/null || (echo "Missing tool: bash" && exit 1)
	@command -v grep >/dev/null || (echo "Missing tool: grep" && exit 1)
	@command -v llvm-objcopy-18 >/dev/null || command -v llvm-objcopy >/dev/null || (echo "Missing tool: llvm-objcopy-18 or llvm-objcopy" && exit 1)
	@command -v llvm-objdump-18 >/dev/null || command -v llvm-objdump >/dev/null || (echo "Missing tool: llvm-objdump-18 or llvm-objdump" && exit 1)
	@rustc --print target-list | grep -qx riscv32i-unknown-none-elf || (echo "Missing Rust target: riscv32i-unknown-none-elf (run: rustup target add riscv32i-unknown-none-elf)" && exit 1)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(FW_ROM): $(FW_SCRIPT) $(FW_SRC)
	cd firmware && bash ./build_rom.sh

_firmware: _check-tools $(FW_ROM)

_synth: _check-tools $(FW_ROM) | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog $(RTL); synth_gowin -top $(TOP) -json $(JSON_SYN)"

_pnr: _synth
	$(NEXTPNR) \
		--json $(JSON_SYN) \
		--write $(JSON_PNR) \
		--device $(DEVICE) \
		--vopt family=$(FAMILY) \
		--vopt cst=$(CST) \
		--vopt sspi_as_gpio \
		--freq 50

_pack: _pnr
	@PKG_BIN="$(GOWIN_PACK)"; \
	if [ -n "$$SUDO_USER" ] && [ -x "/home/$$SUDO_USER/.local/bin/gowin_pack" ]; then \
		PKG_BIN="/home/$$SUDO_USER/.local/bin/gowin_pack"; \
	fi; \
	$$PKG_BIN -d $(FAMILY) --sspi_as_gpio -s $(SDC) -o $(BITSTREAM) $(JSON_PNR)

_bitstream: _pack

_program:
	@test -f $(BITSTREAM) || (echo "Missing bitstream: $(BITSTREAM). Run 'make bitstream' first." && exit 1)
	$(PROGRAMMER) -b tangprimer25k $(BITSTREAM)

_program-build: _bitstream _program

firmware: _firmware
synth: _synth
pnr: _pnr
pack: _pack
bitstream: _bitstream
program: _program
program-build: _program-build

else

firmware: ensure-docker-image
	$(DOCKER_RUN) make IN_DOCKER=1 _firmware

synth: ensure-docker-image
	$(DOCKER_RUN) make IN_DOCKER=1 _synth

pnr: ensure-docker-image
	$(DOCKER_RUN) make IN_DOCKER=1 _pnr

pack: ensure-docker-image
	$(DOCKER_RUN) make IN_DOCKER=1 _pack

bitstream: ensure-docker-image
	$(DOCKER_RUN) make IN_DOCKER=1 _bitstream

program: ensure-docker-image
	$(DOCKER_RUN_USB) make IN_DOCKER=1 _program

program-build: ensure-docker-image
	$(DOCKER_RUN_USB) make IN_DOCKER=1 _program-build

endif

clean:
	rm -rf $(BUILD_DIR)
