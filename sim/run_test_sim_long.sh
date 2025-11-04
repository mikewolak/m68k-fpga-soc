#!/bin/bash
#==============================================================================
# Long-running M68K LED Toggle Simulation with Status Updates
# Runs for up to 60 minutes with status every 1 minute
#==============================================================================

LOG_FILE="/tmp/m68k_test_sim.log"

echo "Starting M68K LED toggle simulation..."
echo "Log file: $LOG_FILE"
echo "Status updates every 60 seconds"
echo ""

# Build firmware first
echo "Building test firmware..."
cd /home/mwolak/m68k_soc/firmware
make -f Makefile.test_sim clean all install

# Go to sim directory
cd /home/mwolak/m68k_soc/sim

# Copy firmware to expected location
cp rom_test_sim.hex rom_vubug.hex
echo "✓ Firmware installed"
echo ""

# Find ModelSim
VSIM="/home/mwolak/intelFPGA_lite/20.1/modelsim_ase/bin/vsim"
if [ ! -f "$VSIM" ]; then
    echo "ERROR: ModelSim not found at $VSIM"
    exit 1
fi

echo "Starting simulation..."
echo ""

# Start simulation in background
(
    $VSIM -c -do "
        do compile_test_sim.do;
        do run_test_sim.do;

        # Run for up to 60 minutes, checking every 1 second of sim time
        set sim_time 0
        set increment 1000000000
        set max_time 3600000000000

        while {\$sim_time < \$max_time} {
            run 1s
            set sim_time [expr \$sim_time + \$increment]

            # Check every 10 seconds of sim time
            if {[expr \$sim_time % 10000000000] == 0} {
                set sim_sec [expr \$sim_time / 1000000000]
                echo \"=== STATUS: Simulated \$sim_sec seconds ===\"
            }
        }

        quit
    " 2>&1 | tee "$LOG_FILE"
) &

SIM_PID=$!

echo "Simulation started with PID: $SIM_PID"
echo ""

# Monitor progress every 60 seconds
START_TIME=$(date +%s)
while kill -0 $SIM_PID 2>/dev/null; do
    sleep 60

    ELAPSED=$(($(date +%s) - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))

    # Extract latest status from log
    LED_TOGGLES=$(grep -c "LED_TOGGLE" "$LOG_FILE" 2>/dev/null || echo "0")
    PATTERNS=$(grep -c "PATTERN CYCLE.*COMPLETE" "$LOG_FILE" 2>/dev/null || echo "0")
    LED_WRITES=$(grep -c "LED_WRITE" "$LOG_FILE" 2>/dev/null || echo "0")
    IFETCHES=$(grep "Instruction Fetches:" "$LOG_FILE" 2>/dev/null | tail -1 | awk '{print $NF}' || echo "0")

    echo "[$ELAPSED_MIN min] LED Toggles: $LED_TOGGLES | Patterns: $PATTERNS/10 | LED Writes: $LED_WRITES | IFetches: $IFETCHES"

    # Check for completion
    if grep -q "TEST PASSED" "$LOG_FILE" 2>/dev/null; then
        echo ""
        echo "✓✓✓ TEST PASSED ✓✓✓"
        break
    fi

    # Check for errors
    LAST_LOG=$(tail -5 "$LOG_FILE" 2>/dev/null)
    if echo "$LAST_LOG" | grep -q "ERROR\|FATAL\|STUCK"; then
        echo "!!! PROBLEM DETECTED - Check log file"
    fi
done

wait $SIM_PID
EXIT_CODE=$?

TOTAL_TIME=$(($(date +%s) - START_TIME))
TOTAL_MIN=$((TOTAL_TIME / 60))

echo ""
echo "========================================"
echo "Simulation completed in $TOTAL_MIN minutes"
echo "Exit code: $EXIT_CODE"
echo "========================================"
echo ""
echo "Final statistics:"
grep -E "Sim Startup|Test Complete|LED.*Toggles|Patterns|Instruction Fetches|TEST PASSED|TEST FAILED" "$LOG_FILE" | tail -15

echo ""
echo "Full log: $LOG_FILE"

exit $EXIT_CODE
