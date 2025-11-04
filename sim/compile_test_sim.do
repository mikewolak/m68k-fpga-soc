# ModelSim compilation script for M68K test simulation

# Create work library
vlib work

# Compile SRAM model
vlog -sv sram_model_16bit.v

# Compile j68 CPU core files
vlog -sv ../downloads/j68_cpu/rtl/j68_addsub_32.v
vlog -sv ../downloads/j68_cpu/rtl/j68_alu.v
vlog -sv ../downloads/j68_cpu/rtl/j68_decode_rom.v
vlog -sv ../downloads/j68_cpu/rtl/j68_decode.v
vlog -sv ../downloads/j68_cpu/rtl/j68_dpram_2048x20.v
vlog -sv ../downloads/j68_cpu/rtl/j68_flags.v
vlog -sv ../downloads/j68_cpu/rtl/j68_loop.v
vlog -sv ../downloads/j68_cpu/rtl/j68_mem_io.v
vlog -sv ../downloads/j68_cpu/rtl/j68_test.v
vlog -sv ../downloads/j68_cpu/rtl/cpu_j68.v

# Compile SOC components
vlog -sv ../hdl/sram_controller_unified.v
vlog -sv ../hdl/m68k_boot_rom.v
vlog -sv +define+SIMULATION ../hdl/m68k_soc_top.v

# Compile testbench
vlog -sv m68k_test_sim_tb.v

echo "Compilation complete"
