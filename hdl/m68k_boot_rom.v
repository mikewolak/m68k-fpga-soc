//==============================================================================
// M68000-compatible SOC for iCE40 FPGA
// m68k_boot_rom.v - Boot ROM with initialization code
//
// Copyright (c) 2025 Michael Wolak
// Email: mikewolak@gmail.com
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//
// SPDX-License-Identifier: ISC
//==============================================================================

//==============================================================================
// M68000 SOC Boot ROM
// m68k_boot_rom.v - Boot ROM loaded from firmware hex file
//
// Copyright (c) November 2025
//==============================================================================

/*
 * Boot ROM - 4KB at 0x00000000
 *
 * READ-ONLY memory initialized from firmware hex file at synthesis time
 *
 * For M68000 CPU with 16-bit data bus:
 *   - Stores bytes but returns 16-bit words
 *   - Address[0] selects low/high byte of word
 *   - 4KB capacity = 2048 words
 *
 * Memory layout:
 *   0x00000000 - 0x00000FFF : Boot ROM (4KB)
 *   0x00001000 - 0x0007FFFF : SRAM (512KB - 4KB)
 *
 * Interface:
 *   - 16-bit read-only interface
 *   - Single cycle latency (combinational output for now)
 *   - No write capability (true ROM)
 */

`default_nettype none

module m68k_boot_rom (
    input  wire        clk,
    input  wire        resetn,
    input  wire [11:0] addr,        // 4KB = 2^12 bytes, word address [11:1]
    input  wire        enable,
    output wire [15:0] rdata
);

    // Memory declaration - 4096 bytes stored as individual bytes
    // This matches the hex file format (one byte per line)
    reg [7:0] memory [0:4095];

    // Initialize memory from firmware hex file
    initial begin
        // Load firmware for both simulation and synthesis
        $readmemh("rom_vubug.hex", memory);
        `ifdef SIMULATION
            $display("[M68K_BOOTROM] Loaded rom_vubug.hex (%0d bytes)", 4096);
            $display("[M68K_BOOTROM] First 8 bytes: %02x %02x %02x %02x %02x %02x %02x %02x",
                     memory[0], memory[1], memory[2], memory[3],
                     memory[4], memory[5], memory[6], memory[7]);
        `endif
    end

    // Read logic - combine two bytes into 16-bit word
    // M68000 is BIG ENDIAN: address N contains high byte, N+1 contains low byte
    wire [11:0] word_addr = {addr[11:1], 1'b0};  // Force even address

    // ROM always outputs data - enable signal unused (ROM is combinational)
    assign rdata = {memory[word_addr], memory[word_addr + 1]};

endmodule

`default_nettype wire
