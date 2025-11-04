# Makefile for M68K Test Simulation Firmware
# Builds test_sim.S into hex format for boot ROM

# Toolchain
M68K_PREFIX = /home/mwolak/marsdev/mars/m68k-elf
M68K_AS = $(M68K_PREFIX)/bin/m68k-elf-as
M68K_LD = $(M68K_PREFIX)/bin/m68k-elf-ld
M68K_OBJCOPY = $(M68K_PREFIX)/bin/m68k-elf-objcopy
M68K_OBJDUMP = $(M68K_PREFIX)/bin/m68k-elf-objdump

# Output files
TARGET = test_sim
ASM_SRC = test_sim.S
OBJ = $(TARGET).o
ELF = $(TARGET).elf
BIN = $(TARGET).bin
HEX = $(TARGET).hex
LST = $(TARGET).lst

# Assembler flags
ASFLAGS = -m68000 -mcpu=68000

# Linker script and flags
LDSCRIPT = m68k.ld
LDFLAGS = -T $(LDSCRIPT) -Map=$(TARGET).map

.PHONY: all clean hex install

all: $(HEX) $(LST)
	@echo ""
	@echo "✓ Firmware built: $(HEX)"
	@ls -lh $(HEX)

# Assemble
$(OBJ): $(ASM_SRC)
	@echo "Assembling $(ASM_SRC)..."
	$(M68K_AS) $(ASFLAGS) -o $@ $<

# Link
$(ELF): $(OBJ) $(LDSCRIPT)
	@echo "Linking..."
	$(M68K_LD) $(LDFLAGS) -o $@ $(OBJ)

# Binary
$(BIN): $(ELF)
	@echo "Creating binary..."
	$(M68K_OBJCOPY) -O binary $< $@

# Hex file (for Verilog $readmemh - byte format)
$(HEX): $(BIN)
	@echo "Creating hex file..."
	@# Create hex dump with address prefix
	@echo "@00000000" > $@
	@od -An -tx1 -v $< | awk '{for(i=1;i<=NF;i++) print $$i}' >> $@
	@echo ""
	@echo "Hex file format: 1 byte per line (Verilog readmemh compatible)"
	@wc -l $@

# Disassembly listing
$(LST): $(ELF)
	@echo "Creating disassembly..."
	$(M68K_OBJDUMP) -D -S $< > $@

# Install to simulation directory
install: $(HEX)
	@echo "Installing to ../sim/..."
	@cp $(HEX) ../sim/rom_test_sim.hex
	@echo "✓ Installed: ../sim/rom_test_sim.hex"

clean:
	@echo "Cleaning..."
	@rm -f $(OBJ) $(ELF) $(BIN) $(HEX) $(LST) $(TARGET).map
	@echo "✓ Clean complete"

help:
	@echo "M68K Test Simulation Firmware Build"
	@echo "===================================="
	@echo "Targets:"
	@echo "  make         - Build all outputs"
	@echo "  make install - Copy hex to ../sim/"
	@echo "  make clean   - Remove build artifacts"
	@echo ""
	@echo "Outputs:"
	@echo "  $(HEX) - Hex file for Verilog simulation"
	@echo "  $(BIN) - Raw binary"
	@echo "  $(LST) - Disassembly listing"
