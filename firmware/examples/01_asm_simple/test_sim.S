| M68K Simulation Test Firmware
| Tests: LED toggling with debug output
| Target: j68 CPU @ 25 MHz
|
| Memory Map:
|   0x00000000 - 0x00000FFF: Boot ROM (this code)
|   0x00001000 - 0x0007FFFF: SRAM
|   0xFF000000: LED register (bit 0=LED1, bit 1=LED2)
|   0xFF000004: Debug UART register (simulation only)

|=========================================
| M68000 Exception Vector Table
|=========================================
    .section .vectors, "ax"
    .long   0x00080000      | Initial SSP (top of SRAM at 512KB)
    .long   _start          | Initial PC (reset vector)

    .text
    .globl _start

|=========================================
| Reset Vector and Stack Setup
|=========================================
_start:
    | Set up stack pointer in SRAM
    lea     0x00004000, %sp    | Stack at 16KB into SRAM

    | Print startup message via debug UART
    | "Sim Startup\r\n"
    bsr     print_startup

    | Initialize LED state
    moveq   #0, %d0
    move.w  %d0, 0xFF000000    | LEDs off initially

    | Set loop counter (10 LED toggle cycles)
    moveq   #10, %d7           | D7 = loop counter

|=========================================
| Main LED Toggle Loop
|=========================================
led_loop:
    | Toggle LED1 on, LED2 off
    moveq   #1, %d0
    move.w  %d0, 0xFF000000

    | Short delay (10 cycles as requested)
    moveq   #10, %d1
delay1:
    subq.l  #1, %d1
    bne     delay1

    | Toggle LED1 off, LED2 on
    moveq   #2, %d0
    move.w  %d0, 0xFF000000

    | Short delay (10 cycles)
    moveq   #10, %d1
delay2:
    subq.l  #1, %d1
    bne     delay2

    | Toggle both LEDs on
    moveq   #3, %d0
    move.w  %d0, 0xFF000000

    | Short delay (10 cycles)
    moveq   #10, %d1
delay3:
    subq.l  #1, %d1
    bne     delay3

    | Toggle both LEDs off
    moveq   #0, %d0
    move.w  %d0, 0xFF000000

    | Short delay (10 cycles)
    moveq   #10, %d1
delay4:
    subq.l  #1, %d1
    bne     delay4

    | Decrement loop counter
    subq.l  #1, %d7
    bne     led_loop

|=========================================
| Test Complete - Stop Simulation
|=========================================
test_done:
    | Print completion message
    bsr     print_done

    | Halt by infinite loop
halt:
    stop    #0x2700
    bra     halt

|=========================================
| Subroutine: Print Startup Message
|=========================================
print_startup:
    lea     msg_startup, %a0
    bra     print_string

|=========================================
| Subroutine: Print Done Message
|=========================================
print_done:
    lea     msg_done, %a0
    bra     print_string

|=========================================
| Subroutine: Print String (Null-terminated)
| Input: A0 = pointer to string
|=========================================
print_string:
    move.l  %a0, %a1           | Save A0 (we'll use A1)
print_loop:
    move.b  (%a1)+, %d0        | Get character
    beq     print_end          | If null, done

    | Write to debug UART register (0xFF000004)
    move.b  %d0, 0xFF000004

    | Small delay for UART
    moveq   #5, %d1
print_delay:
    subq.l  #1, %d1
    bne     print_delay

    bra     print_loop
print_end:
    rts

|=========================================
| String Data
|=========================================
    .data
    .align  2

msg_startup:
    .ascii  "Sim Startup\r\n"
    .byte   0

msg_done:
    .ascii  "\r\nTest Complete! 10 LED cycles executed.\r\n"
    .byte   0

    .end
