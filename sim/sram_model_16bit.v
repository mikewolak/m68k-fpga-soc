//==============================================================================
// M68000-compatible SOC for iCE40 FPGA
// sram_model_16bit.v - 16-bit SRAM behavioral model for simulation
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
// Behavioral SRAM Model - 16-bit
// IS61WV51216BLL-10TLI (512KB, 16-bit, 10ns access)
//
// Memory organization: 256K x 16-bit words (18-bit address)
//==============================================================================

`timescale 1ns/1ps

module sram_model_16bit (
    input  wire [17:0] addr,
    inout  wire [15:0] data,
    input  wire cs_n,
    input  wire oe_n,
    input  wire we_n
);

    // Memory array: 256K x 16-bit = 512KB
    reg [15:0] memory [0:262143];  // 2^18 = 262144 words

    // Internal data register
    reg [15:0] data_out;

    // Tri-state output control
    assign data = (!cs_n && !oe_n && we_n) ? data_out : 16'hzzzz;

    // Initialize memory with test pattern
    integer i;
    initial begin
        for (i = 0; i < 262144; i = i + 1) begin
            memory[i] = 16'h0000;
        end

        // Add some test data at known locations
        memory[18'h00000] = 16'hDEAD;  // Address 0x00000
        memory[18'h00001] = 16'hBEEF;  // Address 0x00001
        memory[18'h00002] = 16'hCAFE;  // Address 0x00002
        memory[18'h00003] = 16'hBABE;  // Address 0x00003
        memory[18'h00010] = 16'h1234;  // Address 0x00010
        memory[18'h00011] = 16'h5678;  // Address 0x00011

        $display("[SRAM_MODEL] Initialized 512KB (256K x 16-bit)");
    end

    // Read operation (10ns access time modeled)
    always @(*) begin
        if (!cs_n && !oe_n && we_n) begin
            #10 data_out = memory[addr];  // 10ns access time
        end else begin
            data_out = 16'hzzzz;
        end
    end

    // Write operation
    always @(cs_n or we_n or addr or data) begin
        if (!cs_n && !we_n) begin
            #7;  // 7ns write pulse width
            memory[addr] <= data;
            $display("[SRAM_MODEL] WRITE: addr=0x%05x data=0x%04x", addr, data);
        end
    end

endmodule
