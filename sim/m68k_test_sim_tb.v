//==============================================================================
// M68000-compatible SOC for iCE40 FPGA
// m68k_test_sim_tb.v - ModelSim testbench for LED toggle verification
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
// M68000 SOC Test Simulation Testbench
// Tests LED toggle pattern and debug UART output
//==============================================================================

`timescale 1ns/1ps

module m68k_test_sim_tb;

    //==========================================================================
    // Clock and Reset
    //==========================================================================
    reg clk_50mhz;
    reg uart_rx;

    wire uart_tx;
    wire led1, led2;

    // SRAM interface
    wire [17:0] sram_addr;
    wire [15:0] sram_data;
    wire sram_cs_n;
    wire sram_oe_n;
    wire sram_we_n;

    // Clock generation: 50 MHz = 20ns period
    initial begin
        clk_50mhz = 0;
        forever #10 clk_50mhz = ~clk_50mhz;  // 10ns high, 10ns low = 20ns period
    end

    //==========================================================================
    // DUT: M68000 SOC
    //==========================================================================
    m68k_soc_top dut (
        .clk_50mhz(clk_50mhz),

        .sram_addr(sram_addr),
        .sram_data(sram_data),
        .sram_cs_n(sram_cs_n),
        .sram_oe_n(sram_oe_n),
        .sram_we_n(sram_we_n),

        .led1(led1),
        .led2(led2),

        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    //==========================================================================
    // SRAM Model
    //==========================================================================
    sram_model_16bit sram (
        .addr(sram_addr),
        .data(sram_data),
        .cs_n(sram_cs_n),
        .oe_n(sram_oe_n),
        .we_n(sram_we_n)
    );

    //==========================================================================
    // LED State Monitoring
    //==========================================================================
    reg [1:0] prev_led_state;
    integer led_toggle_count = 0;
    integer led_pattern_count = 0;  // Counts complete 4-pattern cycles

    // LED state names for display
    function [63:0] led_state_name;
        input [1:0] state;
        begin
            case (state)
                2'b00: led_state_name = "OFF    ";
                2'b01: led_state_name = "LED1_ON";
                2'b10: led_state_name = "LED2_ON";
                2'b11: led_state_name = "BOTH_ON";
            endcase
        end
    endfunction

    // Monitor LED state changes
    initial prev_led_state = 2'b00;

    always @(led1, led2) begin
        if (dut.rst_n) begin  // Only after reset
            if ({led2, led1} != prev_led_state) begin
                led_toggle_count = led_toggle_count + 1;
                $display("[%0t] LED_TOGGLE[%0d]: %s -> %s (LED1=%b LED2=%b)",
                         $time, led_toggle_count,
                         led_state_name(prev_led_state),
                         led_state_name({led2, led1}),
                         led1, led2);
                prev_led_state = {led2, led1};

                // Count complete pattern cycles (every 4 toggles)
                if (led_toggle_count % 4 == 0) begin
                    led_pattern_count = led_pattern_count + 1;
                    $display("[%0t] *** PATTERN CYCLE %0d COMPLETE ***",
                             $time, led_pattern_count);
                end
            end
        end
    end

    //==========================================================================
    // CPU Signal Monitoring
    //==========================================================================
    wire        cpu_rd_ena     = dut.cpu_rd_ena;
    wire        cpu_wr_ena     = dut.cpu_wr_ena;
    wire        cpu_data_ack   = dut.cpu_data_ack;
    wire [1:0]  cpu_byte_ena   = dut.cpu_byte_ena;
    wire [31:0] cpu_address    = dut.cpu_address;
    wire [15:0] cpu_rd_data    = dut.cpu_rd_data;
    wire [15:0] cpu_wr_data    = dut.cpu_wr_data;
    wire [2:0]  cpu_fc         = dut.cpu_fc;
    wire        accessing_bootrom = dut.accessing_bootrom;
    wire        accessing_sram    = dut.accessing_sram;
    wire        accessing_leds    = dut.accessing_leds;
    wire        rst_n             = dut.rst_n;

    integer ifetch_count = 0;
    integer read_count = 0;
    integer write_count = 0;
    integer led_write_count = 0;

    // Monitor instruction fetches (FC=010 = Program fetch)
    always @(posedge clk_50mhz) begin
        if (cpu_rd_ena && cpu_data_ack && cpu_fc == 3'b010) begin
            ifetch_count = ifetch_count + 1;
        end
    end

    // Monitor data reads
    always @(posedge clk_50mhz) begin
        if (cpu_rd_ena && cpu_data_ack && cpu_fc != 3'b010) begin
            read_count = read_count + 1;
        end
    end

    // Monitor data writes
    always @(posedge clk_50mhz) begin
        if (cpu_wr_ena && cpu_data_ack) begin
            write_count = write_count + 1;
        end
    end

    // Monitor LED register writes specifically
    always @(posedge clk_50mhz) begin
        if (cpu_wr_ena && accessing_leds && (cpu_address[7:0] == 8'h00)) begin
            led_write_count = led_write_count + 1;
            $display("[%0t] LED_WRITE[%0d]: data=0x%04x (LED1=%b LED2=%b)",
                     $time, led_write_count, cpu_wr_data,
                     cpu_wr_data[0], cpu_wr_data[1]);
        end
    end

    //==========================================================================
    // Test Sequence
    //==========================================================================
    initial begin
        $display("");
        $display("========================================");
        $display("M68000 SOC LED Toggle Test Simulation");
        $display("========================================");
        $display("Clock: 50 MHz (20ns period)");
        $display("Firmware: test_sim (LED toggle + UART)");
        $display("Test: 10 LED pattern cycles");
        $display("Pattern: LED1 -> LED2 -> BOTH -> OFF");
        $display("========================================");
        $display("");

        // VCD waveform dump
        $dumpfile("m68k_test_sim.vcd");
        $dumpvars(0, m68k_test_sim_tb);

        // Initialize inputs
        uart_rx = 1'b1;  // UART idle

        // Wait for reset to complete (8192 cycles for j68_cpu)
        $display("[%0t] Waiting for reset (8192 cycles)...", $time);
        repeat(8250) @(posedge clk_50mhz);

        $display("[%0t] Reset released - CPU starting...", $time);
        $display("[%0t] ** Expect: 'Sim Startup' message **", $time);
        $display("");

        // Run simulation for sufficient time to complete test
        // Observed: ~59us per pattern cycle
        // 10 pattern cycles × 59us = 590us
        // Add margin: run for 800us to be safe
        #800000;  // 800us

        // Final report
        $display("");
        $display("========================================");
        $display("Simulation Complete");
        $display("========================================");
        $display("Execution Time: %0t ns", $time);
        $display("");
        $display("CPU Activity:");
        $display("  Instruction Fetches:  %0d", ifetch_count);
        $display("  Data Reads:           %0d", read_count);
        $display("  Data Writes:          %0d", write_count);
        $display("");
        $display("LED Activity:");
        $display("  LED Register Writes:  %0d", led_write_count);
        $display("  LED State Changes:    %0d", led_toggle_count);
        $display("  Complete Patterns:    %0d / 10 expected", led_pattern_count);
        $display("  Final State:          LED1=%b LED2=%b", led1, led2);
        $display("");

        // Check if test passed
        if (led_pattern_count >= 10) begin
            $display("✓✓✓ TEST PASSED ✓✓✓");
            $display("All 10 LED pattern cycles completed successfully!");
        end else begin
            $display("✗✗✗ TEST FAILED ✗✗✗");
            $display("Only %0d pattern cycles completed (expected 10)", led_pattern_count);
        end

        $display("========================================");
        $display("");

        $finish;
    end

    //==========================================================================
    // Timeout Watchdog (1 second maximum - plenty for this test)
    //==========================================================================
    initial begin
        #1000000000;  // 1 second in nanoseconds (fits in 32-bit)
        $display("");
        $display("========================================");
        $display("TIMEOUT: Simulation exceeded 1 second");
        $display("========================================");
        $display("");
        $finish;
    end

endmodule
