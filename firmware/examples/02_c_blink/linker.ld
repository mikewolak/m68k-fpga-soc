/*
 * M68000 SOC Linker Script
 * Boot ROM: 4KB at 0x00000000 (read-only, loaded from hex file)
 * SRAM: 508KB at 0x00001000 (read/write)
 */

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00001000, LENGTH = 508K
}

SECTIONS
{
    /* Exception vectors and code in boot ROM */
    . = 0x00000000;

    /* M68000 exception vectors (first 1KB) - MUST be at 0x00000000 */
    .vectors : {
        KEEP(*(.vectors))
        . = ALIGN(4);
    } > ROM

    /* Code section in boot ROM - explicitly placed after vectors */
    .text : {
        *(.text)
        *(.text*)
        . = ALIGN(4);
    } > ROM

    /* Read-only data in boot ROM */
    .rodata : {
        *(.rodata)
        *(.rodata*)
        . = ALIGN(4);
    } > ROM

    /* Runtime data in SRAM */
    . = 0x00001000;

    /* Initialized data in SRAM */
    .data : {
        *(.data)
        *(.data*)
        . = ALIGN(4);
    } > RAM

    /* Uninitialized data (BSS) in SRAM */
    .bss : {
        __bss_start = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    /* Heap starts after BSS in SRAM */
    __heap_start = ALIGN(., 4);
    __heap_end = ORIGIN(RAM) + LENGTH(RAM) - 0x10000;  /* Reserve 64KB for stack */

    /* Stack at top of RAM (grows downward from 0x00080000 = 512KB) */
    __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
