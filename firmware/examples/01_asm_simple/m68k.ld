/*
 * M68K Linker Script
 * For j68_cpu M68000 SOC
 *
 * Memory Map:
 *   0x00000000 - 0x00000FFF: Boot ROM (4KB)
 *   0x00001000 - 0x0007FFFF: SRAM (508KB)
 *   0xFF000000 - 0xFF0000FF: LED control (memory-mapped I/O)
 */

OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY
{
    ROM   (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx)  : ORIGIN = 0x00001000, LENGTH = 508K
}

SECTIONS
{
    /* Exception vectors and code in ROM */
    .vectors : {
        KEEP(*(.vectors))
    } > ROM

    .text : {
        *(.text)
        *(.text.*)
        *(.gnu.linkonce.t.*)
        . = ALIGN(4);
    } > ROM

    .rodata : {
        *(.rodata)
        *(.rodata.*)
        *(.gnu.linkonce.r.*)
        . = ALIGN(4);
    } > ROM

    /* Data section - loaded to ROM, copied to RAM at startup */
    .data : AT (ADDR(.rodata) + SIZEOF(.rodata)) {
        __data_start = .;
        *(.data)
        *(.data.*)
        *(.gnu.linkonce.d.*)
        . = ALIGN(4);
        __data_end = .;
    } > RAM

    /* BSS section - zero-initialized data in RAM */
    .bss (NOLOAD) : {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    /* Heap (if needed) */
    .heap (NOLOAD) : {
        __heap_start = .;
        . = . + 0x1000;  /* 4KB heap */
        __heap_end = .;
    } > RAM

    /* Stack grows down from top of RAM */
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);

    /* Discard debugging sections */
    /DISCARD/ : {
        *(.comment)
        *(.note*)
    }
}
