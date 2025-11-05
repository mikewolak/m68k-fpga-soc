/*
 * M68K Startup Code (crt0.S)
 * For j68_cpu M68000 SOC
 *
 * Memory Map:
 *   0x00000000 - 0x00000FFF: Boot ROM (4KB)
 *   0x00001000 - 0x0007FFFF: SRAM (508KB)
 *   0xFF000000 - 0xFF0000FF: LED control
 */

    .section .vectors, "ax"
    .globl _vectors

_vectors:
    /* M68000 Exception Vectors (256 vectors x 4 bytes = 1KB) */

    /* Vector 0: Initial SSP (Supervisor Stack Pointer) */
    .long   0x00080000          /* Top of RAM (512KB) */

    /* Vector 1: Initial PC (Program Counter / Reset) */
    .long   _start

    /* Vector 2: Bus Error */
    .long   _default_handler

    /* Vector 3: Address Error */
    .long   _default_handler

    /* Vector 4: Illegal Instruction */
    .long   _default_handler

    /* Vector 5: Divide by Zero */
    .long   _default_handler

    /* Vector 6: CHK Instruction */
    .long   _default_handler

    /* Vector 7: TRAPV Instruction */
    .long   _default_handler

    /* Vector 8: Privilege Violation */
    .long   _default_handler

    /* Vector 9: Trace */
    .long   _default_handler

    /* Vector 10: Line 1010 Emulator */
    .long   _default_handler

    /* Vector 11: Line 1111 Emulator */
    .long   _default_handler

    /* Vectors 12-14: Reserved */
    .long   _default_handler
    .long   _default_handler
    .long   _default_handler

    /* Vector 15: Uninitialized Interrupt */
    .long   _default_handler

    /* Vectors 16-23: Reserved */
    .rept   8
    .long   _default_handler
    .endr

    /* Vector 24: Spurious Interrupt */
    .long   _default_handler

    /* Vectors 25-31: Level 1-7 Auto-Vector Interrupts */
    .rept   7
    .long   _default_handler
    .endr

    /* Vectors 32-47: TRAP #0 through TRAP #15 */
    .rept   16
    .long   _default_handler
    .endr

    /* Vectors 48-63: Reserved */
    .rept   16
    .long   _default_handler
    .endr

    /* Vectors 64-255: User-Defined Interrupts */
    .rept   192
    .long   _default_handler
    .endr

/*
 * Startup Code
 */
    .section .text
    .globl _start
    .type _start, @function

_start:
    /* Disable interrupts */
    move.w  #0x2700, %sr        /* Set interrupt mask to 7, supervisor mode */

    /* Initialize stack pointer (already set by reset vector) */
    /* SP = 0x00080000 from vector 0 */

    /* Clear BSS section */
    lea     __bss_start, %a0    /* Start of BSS */
    lea     __bss_end, %a1      /* End of BSS */
    moveq   #0, %d0             /* Clear value */

clear_bss_loop:
    cmp.l   %a0, %a1            /* Check if done */
    beq     clear_bss_done
    move.b  %d0, (%a0)+         /* Clear byte and increment */
    bra     clear_bss_loop

clear_bss_done:
    /* Call main() */
    jsr     main

    /* If main returns, loop forever */
hang:
    bra     hang

/*
 * Default Exception Handler
 */
    .globl _default_handler
    .type _default_handler, @function

_default_handler:
    /* Flash LEDs to indicate exception */
    lea     0xFF000000, %a0     /* LED control register */
    move.w  #0x0003, (%a0)      /* Turn on both LEDs */

    /* Infinite loop */
1:  nop
    bra     1b
