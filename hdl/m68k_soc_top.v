//==============================================================================
// M68000-compatible SOC for iCE40 FPGA
// m68k_soc_top.v - Top-level M68K SOC with j68 CPU, SRAM, and peripherals
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

// M68000 SOC for iCE40HX8K
// Uses j68_cpu core (plain Verilog 68000 implementation)

module m68k_soc_top (
    input  wire clk_50mhz,

    // SRAM interface (512KB) - 16-bit
    output wire [17:0] sram_addr,
    inout  wire [15:0] sram_data,
    output wire sram_cs_n,
    output wire sram_oe_n,
    output wire sram_we_n,

    // LEDs
    output wire led1,
    output wire led2,

    // UART
    input  wire uart_rx,
    output wire uart_tx
);

    //==========================================================================
    // Reset
    //==========================================================================
    // j68_cpu requires long reset - use 13-bit counter for 8192 cycles
    // (matching official testbench reset duration)
    reg [12:0] reset_counter = 0;
    reg rst_n = 0;  // Initialize to 0 (reset asserted)

    always @(posedge clk_50mhz) begin
        `ifdef SIMULATION
        // Debug: Show counter every 1000 cycles
        if (reset_counter[9:0] == 10'h000) begin
            $display("[%0t] RESET COUNTER: %d (0x%h), rst_n=%b", $time, reset_counter, reset_counter, rst_n);
        end
        `endif

        if (reset_counter != 13'h1FFF) begin  // Count to 8191
            reset_counter <= reset_counter + 1;
            rst_n <= 0;
        end else begin
            if (rst_n == 0) begin
                `ifdef SIMULATION
                $display("[%0t] RESET RELEASED: rst_n=1, ~rst_n=0", $time);
                `endif
            end
            rst_n <= 1;
        end
    end

    //==========================================================================
    // j68_cpu CPU (16-bit interface)
    //==========================================================================
    wire        cpu_rd_ena;
    wire        cpu_wr_ena;
    wire        cpu_data_ack;
    wire [1:0]  cpu_byte_ena;
    wire [31:0] cpu_address;
    wire [15:0] cpu_rd_data;
    wire [15:0] cpu_wr_data;
    wire [2:0]  cpu_fc;

    // Debug: Monitor reset signal to CPU
    wire cpu_rst = ~rst_n;

    `ifdef SIMULATION
    reg cpu_running_displayed = 0;
    always @(posedge clk_50mhz) begin
        if (cpu_rst == 1'b0 && rst_n == 1'b1 && !cpu_running_displayed) begin
            $display("[%0t] *** CPU RUNNING (cpu_rst=0, rst_n=1) ***", $time);
            cpu_running_displayed <= 1;
        end
    end
    `endif

    cpu_j68 #(
        .USE_CLK_ENA(0)
    ) cpu (
        .rst(cpu_rst),
        .clk(clk_50mhz),
        .clk_ena(1'b1),  // Always enabled - matches official testbench

        .rd_ena(cpu_rd_ena),
        .wr_ena(cpu_wr_ena),
        .data_ack(cpu_data_ack),
        .byte_ena(cpu_byte_ena),
        .address(cpu_address),
        .rd_data(cpu_rd_data),
        .wr_data(cpu_wr_data),

        .fc(cpu_fc),
        .ipl_n(3'b111),  // No interrupts

        // Debug signals (unused)
        .dbg_reg_addr(),
        .dbg_reg_wren(),
        .dbg_reg_data(),
        .dbg_sr_reg(),
        .dbg_pc_reg(),
        .dbg_usp_reg(),
        .dbg_ssp_reg(),
        .dbg_vbr_reg(),
        .dbg_cycles(),
        .dbg_ifetch(),
        .dbg_irq_lvl()
    );

    //==========================================================================
    // Memory Map
    //==========================================================================
    // 0x00000000-0x00000FFF: Boot ROM (4KB)
    // 0x00001000-0x0007FFFF: SRAM (512KB - 4KB)
    // 0xFF000000-0xFF0000FF: LED control

    wire accessing_bootrom = (cpu_address[31:12] == 20'h00000);  // 0x00000000-0x00000FFF
    wire accessing_sram = (cpu_address[31:19] == 13'h0000) && !accessing_bootrom;
    wire accessing_leds = (cpu_address[31:8] == 24'hFF0000);

    //==========================================================================
    // SRAM Controller Interface (adapt 16-bit CPU to 32-bit controller)
    //==========================================================================
    wire        sram_valid;
    wire        sram_ready;
    wire [3:0]  sram_wstrb;
    wire [31:0] sram_wdata;
    wire [31:0] sram_rdata;

    // Convert j68 16-bit interface to SRAM controller 32-bit
    assign sram_valid = (cpu_rd_ena | cpu_wr_ena) & accessing_sram;
    assign sram_wstrb = cpu_wr_ena ? {2'b00, cpu_byte_ena} : 4'b0000;
    assign sram_wdata = {16'h0000, cpu_wr_data};

    sram_controller_unified sram_ctrl (
        .clk(clk_50mhz),
        .resetn(rst_n),

        .valid(sram_valid),
        .ready(sram_ready),
        .wstrb(sram_wstrb),
        .addr(cpu_address),
        .wdata(sram_wdata),
        .rdata(sram_rdata),

        .sram_addr(sram_addr),
        .sram_data(sram_data),
        .sram_cs_n(sram_cs_n),
        .sram_oe_n(sram_oe_n),
        .sram_we_n(sram_we_n)
    );

    //==========================================================================
    // Boot ROM (4KB at 0x00000000)
    //==========================================================================
    wire [15:0] bootrom_rdata;

    m68k_boot_rom boot_rom (
        .clk(clk_50mhz),
        .resetn(rst_n),
        .addr(cpu_address[11:0]),
        .enable(cpu_rd_ena & accessing_bootrom),
        .rdata(bootrom_rdata)
    );

    // Multiplex read data: Boot ROM or SRAM
    assign cpu_rd_data = accessing_bootrom ? bootrom_rdata : sram_rdata[15:0];

    //==========================================================================
    // LED Control (memory-mapped at 0xFF000000)
    //==========================================================================
    reg led1_reg, led2_reg;

    always @(posedge clk_50mhz) begin
        if (~rst_n) begin
            led1_reg <= 0;
            led2_reg <= 0;
        end else if (cpu_wr_ena & accessing_leds) begin
            if (cpu_address[7:0] == 8'h00) begin
                if (cpu_byte_ena[0]) led1_reg <= cpu_wr_data[0];
                if (cpu_byte_ena[0]) led2_reg <= cpu_wr_data[1];
            end
        end
    end

    assign led1 = led1_reg;
    assign led2 = led2_reg;

    //==========================================================================
    // Debug UART (memory-mapped at 0xFF000004 - simulation only)
    //==========================================================================
    `ifdef SIMULATION
    always @(posedge clk_50mhz) begin
        if (cpu_wr_ena & accessing_leds & (cpu_address[7:0] == 8'h04)) begin
            if (cpu_byte_ena[0]) begin
                $write("%c", cpu_wr_data[7:0]);
                $fflush();
            end
        end
    end
    `endif

    //==========================================================================
    // Data ACK generation (matching soc_j68 timing)
    //==========================================================================
    // j68_cpu requires:
    // - IMMEDIATE ack for writes
    // - DELAYED ack (1 cycle) for reads
    // CRITICAL: Uses ASYNC reset like official soc_j68.v

    reg rd_ena_dly;

    // Async reset for rd_ena_dly (matches soc_j68.v line 376)
    always @(posedge clk_50mhz or negedge rst_n) begin
        if (~rst_n) begin
            rd_ena_dly <= 1'b0;
        end else begin
            // Delay ROM/RAM reads by 1 cycle
            rd_ena_dly <= cpu_rd_ena;
        end
    end

    // Combinational data_ack (matches soc_j68.v lines 394-396)
    // Writes get immediate ack, reads get delayed ack
    assign cpu_data_ack = cpu_wr_ena                          // Immediate write ack
                        | rd_ena_dly & ~accessing_sram        // Delayed ROM read ack
                        | rd_ena_dly & accessing_sram & sram_ready;  // Delayed SRAM read ack (with ready check)

    //==========================================================================
    // UART placeholder
    //==========================================================================
    assign uart_tx = uart_rx;

endmodule
