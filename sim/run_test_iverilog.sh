#!/bin/bash
#===============================================================================
# M68K Test Simulation Runner (Icarus Verilog)
# Compiles and runs the LED toggle test simulation
#===============================================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "=========================================="
echo "M68K Test Simulation Runner (Icarus)"
echo "=========================================="
echo ""

# Check for iverilog
if ! command -v iverilog &> /dev/null; then
    echo "ERROR: Icarus Verilog 'iverilog' not found in PATH"
    echo "Trying oss-cad-suite..."
    export PATH="../downloads/oss-cad-suite/bin:$PATH"
    if ! command -v iverilog &> /dev/null; then
        echo "ERROR: Cannot find iverilog"
        exit 1
    fi
fi

# Prepare firmware
echo "Step 1: Building test firmware..."
cd ../firmware
make -f Makefile.test_sim clean all install
cd ../sim

# Copy test firmware to rom_vubug.hex (what m68k_boot_rom.v loads)
echo ""
echo "Step 2: Preparing boot ROM..."
cp rom_test_sim.hex rom_vubug.hex
echo "✓ Test firmware installed as rom_vubug.hex"

# Compile Verilog sources
echo ""
echo "Step 3: Compiling HDL sources with Icarus Verilog..."

iverilog -g2005-sv \
    -D SIMULATION \
    -o test_sim.vvp \
    -I ../hdl \
    -I ../downloads/j68_cpu/rtl \
    ../hdl/sram_controller_unified.v \
    ../hdl/m68k_boot_rom.v \
    ../hdl/m68k_soc_top.v \
    ../downloads/j68_cpu/rtl/cpu_j68.v \
    ../downloads/j68_cpu/rtl/j68_addsub_32.v \
    ../downloads/j68_cpu/rtl/j68_alu.v \
    ../downloads/j68_cpu/rtl/j68_decode_rom.v \
    ../downloads/j68_cpu/rtl/j68_decode.v \
    ../downloads/j68_cpu/rtl/j68_dpram_2048x20.v \
    ../downloads/j68_cpu/rtl/j68_flags.v \
    ../downloads/j68_cpu/rtl/j68_loop.v \
    ../downloads/j68_cpu/rtl/j68_mem_io.v \
    ../downloads/j68_cpu/rtl/j68_test.v \
    sram_model_16bit.v \
    m68k_test_sim_tb.v

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "✓ Compilation successful"

# Run simulation
echo ""
echo "Step 4: Running simulation..."
echo "=========================================="
echo ""

vvp test_sim.vvp | tee test_sim_run.log

echo ""
echo "=========================================="
echo "Simulation complete!"
echo "=========================================="
echo ""
echo "Output files:"
echo "  test_sim_run.log    - Full simulation log"
echo "  m68k_test_sim.vcd   - Waveform dump"
echo ""

# Check for success
if grep -q "TEST PASSED" test_sim_run.log; then
    echo "✓✓✓ TEST PASSED ✓✓✓"
    echo ""
    echo "Extracting key results..."
    echo ""
    grep -E "LED_TOGGLE|PATTERN CYCLE|Sim Startup|Test Complete|Simulation Complete" test_sim_run.log | tail -20
    echo ""
    exit 0
else
    echo "✗✗✗ TEST FAILED or INCOMPLETE ✗✗✗"
    exit 1
fi
