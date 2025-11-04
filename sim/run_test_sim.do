# ModelSim simulation script for M68K LED toggle test

# Load the design
vsim -t 1ns work.m68k_test_sim_tb

# Add signals to waveform
add wave -divider "Top Level"
add wave /m68k_test_sim_tb/clk_50mhz
add wave /m68k_test_sim_tb/dut/rst_n
add wave /m68k_test_sim_tb/led1
add wave /m68k_test_sim_tb/led2
add wave /m68k_test_sim_tb/uart_tx

add wave -divider "LED State Tracking"
add wave -hex /m68k_test_sim_tb/prev_led_state
add wave /m68k_test_sim_tb/led_toggle_count
add wave /m68k_test_sim_tb/led_pattern_count

add wave -divider "CPU Interface"
add wave /m68k_test_sim_tb/cpu_rd_ena
add wave /m68k_test_sim_tb/cpu_wr_ena
add wave /m68k_test_sim_tb/cpu_data_ack
add wave -hex /m68k_test_sim_tb/cpu_address
add wave -hex /m68k_test_sim_tb/cpu_rd_data
add wave -hex /m68k_test_sim_tb/cpu_wr_data
add wave -hex /m68k_test_sim_tb/cpu_fc

add wave -divider "Memory Decode"
add wave /m68k_test_sim_tb/accessing_bootrom
add wave /m68k_test_sim_tb/accessing_sram
add wave /m68k_test_sim_tb/accessing_leds

add wave -divider "CPU Internal (j68)"
add wave -hex /m68k_test_sim_tb/dut/cpu/dbg_pc_reg
add wave -hex /m68k_test_sim_tb/dut/cpu/dbg_sr_reg
add wave /m68k_test_sim_tb/dut/cpu/dbg_ifetch

add wave -divider "SRAM Controller"
add wave /m68k_test_sim_tb/dut/sram_ctrl/valid
add wave /m68k_test_sim_tb/dut/sram_ctrl/ready
add wave -hex /m68k_test_sim_tb/dut/sram_ctrl/addr
add wave -hex /m68k_test_sim_tb/dut/sram_ctrl/wdata
add wave -hex /m68k_test_sim_tb/dut/sram_ctrl/rdata
add wave -hex /m68k_test_sim_tb/dut/sram_ctrl/wstrb
add wave -hex /m68k_test_sim_tb/dut/sram_ctrl/state

add wave -divider "SRAM Physical"
add wave -hex /m68k_test_sim_tb/sram_addr
add wave -hex /m68k_test_sim_tb/sram_data
add wave /m68k_test_sim_tb/sram_cs_n
add wave /m68k_test_sim_tb/sram_oe_n
add wave /m68k_test_sim_tb/sram_we_n

# Run simulation
run -all
