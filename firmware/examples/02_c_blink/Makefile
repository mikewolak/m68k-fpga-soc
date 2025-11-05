#===============================================================================
# M68000 C Firmware Example - LED Blink
# Copyright (c) 2025 Michael Wolak
#===============================================================================

# Toolchain (m68k-elf-gcc)
PREFIX ?= m68k-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE = $(PREFIX)size

# Target name
TARGET = led_blink

# Compiler/Assembler flags
ARCH = -m68000
CFLAGS = $(ARCH) -O2 -g -Wall -Wextra -ffreestanding -fno-builtin -nostdlib
ASFLAGS = $(ARCH)
LDFLAGS = -T linker.ld -nostdlib

# Source files
OBJECTS = crt0.o main.o

# Output files
ELF = $(TARGET).elf
BIN = $(TARGET).bin
HEX = $(TARGET).hex
LST = $(TARGET).lst
MAP = $(TARGET).map

.PHONY: all clean disasm install

all: $(BIN) $(HEX) disasm
	@echo "Build Complete: $(TARGET)"
	@$(SIZE) $(ELF)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(AS) $(ASFLAGS) $< -o $@

$(ELF): $(OBJECTS) linker.ld
	$(LD) $(LDFLAGS) $(OBJECTS) -o $@ -Map=$(MAP)

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

$(HEX): $(BIN)
	od -An -tx1 -w1 -v $< | awk '{print $$1}' > $@

disasm: $(ELF)
	$(OBJDUMP) -D $< > $(LST)

install: $(HEX)
	cp $(HEX) ../../../sim/test_sim.hex

clean:
	rm -f *.o *.elf *.bin *.hex *.lst *.map

.SUFFIXES: .c .S .o
