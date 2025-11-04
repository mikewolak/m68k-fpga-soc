# M68000 SOC for iCE40HX8K
# fx68k core + SRAM controller

.DEFAULT_GOAL := all

# Toolchain paths
export PATH := $(CURDIR)/downloads/oss-cad-suite/bin:$(PATH)

YOSYS := $(CURDIR)/downloads/oss-cad-suite/bin/yosys
NEXTPNR := $(CURDIR)/downloads/oss-cad-suite/bin/nextpnr-ice40
ICEPACK := $(CURDIR)/downloads/oss-cad-suite/bin/icepack
ICETIME := $(CURDIR)/downloads/oss-cad-suite/bin/icetime

# iCE40HX8K settings
FPGA_DEVICE := hx8k
FPGA_PACKAGE := ct256
FPGA_FREQ := 25

# Directories
BUILD_DIR := build
HDL_DIR := hdl
J68_DIR := downloads/j68_cpu/rtl

# Pin constraints
PCF_FILE := m68k_soc.pcf

all: tools build

help:
	@echo "========================================="
	@echo "M68000 SOC iCE40HX8K Build System"
	@echo "========================================="
	@echo ""
	@echo "Setup:"
	@echo "  make tools           - Download toolchain"
	@echo ""
	@echo "Build:"
	@echo "  make build           - Build bitstream"
	@echo "  make synth           - Synthesis only"
	@echo "  make pack            - Pack bitstream"
	@echo "  make timing          - Timing analysis"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean           - Remove build artifacts"
	@echo ""

# ============================================================================
# Toolchain Download
# ============================================================================

tools:
	@if [ -f "$(YOSYS)" ] && [ -f "$(NEXTPNR)" ]; then \
		echo "✓ Toolchain already installed"; \
	else \
		echo "Downloading OSS CAD Suite..."; \
		./scripts/download_prebuilt_tools.sh; \
	fi

# ============================================================================
# Synthesis
# ============================================================================

synth: tools
	@echo ""
	@echo "========================================="
	@echo "Synthesizing M68000 SOC (J68 Core)"
	@echo "========================================="
	@echo "FPGA:    iCE40$(FPGA_DEVICE)"
	@echo "Package: $(FPGA_PACKAGE)"
	@echo "Target:  $(FPGA_FREQ) MHz"
	@echo ""
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && $(YOSYS) -p "read_verilog \
		../$(J68_DIR)/cpu_j68.v \
		../$(J68_DIR)/j68_addsub_32.v \
		../$(J68_DIR)/j68_alu.v \
		../$(J68_DIR)/j68_decode_rom.v \
		../$(J68_DIR)/j68_decode.v \
		../$(J68_DIR)/j68_dpram_2048x20.v \
		../$(J68_DIR)/j68_flags.v \
		../$(J68_DIR)/j68_loop.v \
		../$(J68_DIR)/j68_mem_io.v \
		../$(J68_DIR)/j68_test.v; \
		read_verilog ../$(HDL_DIR)/sram_controller_unified.v ../$(HDL_DIR)/m68k_boot_rom.v ../$(HDL_DIR)/m68k_soc_top.v; \
		hierarchy -top m68k_soc_top; \
		synth_ice40 -top m68k_soc_top -json m68k_soc.json" 2>&1 | tee synthesis.log
	@echo ""
	@echo "✓ Synthesis complete: $(BUILD_DIR)/m68k_soc.json"
	@echo ""

# ============================================================================
# Place & Route
# ============================================================================

$(BUILD_DIR)/m68k_soc.asc: synth
	@echo ""
	@echo "========================================="
	@echo "Place & Route"
	@echo "========================================="
	@echo "Device:  iCE40$(FPGA_DEVICE)"
	@echo "Package: $(FPGA_PACKAGE)"
	@echo "PCF:     $(PCF_FILE)"
	@echo ""
	@$(NEXTPNR) --$(FPGA_DEVICE) --package $(FPGA_PACKAGE) \
		--json $(BUILD_DIR)/m68k_soc.json \
		--pcf $(PCF_FILE) \
		--asc $(BUILD_DIR)/m68k_soc.asc \
		--freq $(FPGA_FREQ) \
		2>&1 | tee $(BUILD_DIR)/pnr.log
	@echo ""
	@echo "✓ Place & Route complete"
	@echo ""

# ============================================================================
# Pack Bitstream
# ============================================================================

pack: $(BUILD_DIR)/m68k_soc.asc
	@echo ""
	@echo "========================================="
	@echo "Packing Bitstream"
	@echo "========================================="
	@$(ICEPACK) $(BUILD_DIR)/m68k_soc.asc $(BUILD_DIR)/m68k_soc.bin
	@ls -lh $(BUILD_DIR)/m68k_soc.bin
	@echo ""
	@echo "✓ Bitstream ready: $(BUILD_DIR)/m68k_soc.bin"
	@echo ""

bitstream: pack

build: pack timing

# ============================================================================
# Timing Analysis
# ============================================================================

timing: $(BUILD_DIR)/m68k_soc.asc
	@echo ""
	@echo "========================================="
	@echo "Timing Analysis"
	@echo "========================================="
	@$(ICETIME) -d $(FPGA_DEVICE) -c $(FPGA_FREQ) \
		$(BUILD_DIR)/m68k_soc.asc 2>&1 | tee $(BUILD_DIR)/timing.rpt
	@echo ""
	@echo "✓ Timing report: $(BUILD_DIR)/timing.rpt"
	@echo ""

# ============================================================================
# Clean
# ============================================================================

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)/*.json $(BUILD_DIR)/*.asc $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.log $(BUILD_DIR)/*.rpt
	@echo "✓ Clean complete"

distclean: clean
	@echo "Removing downloads..."
	@rm -rf downloads/oss-cad-suite
	@echo "✓ Distclean complete"

.PHONY: all help tools synth pack bitstream build timing clean distclean
