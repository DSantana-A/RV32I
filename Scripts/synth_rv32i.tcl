set target_library /opt/pdk/digitalbootcamp/ICC2/lib/sky130_fd_sc_hd/db_nldm/sky130_fd_sc_hd__tt_025C_1v80.db
set link_library "* $target_library"
set_host_options -max_cores 8

read_file -format sverilog {Modules/ALU.sv Modules/RegisterFile.sv Modules/ImmediateGenerator.sv Modules/ProgramCounter.sv Modules/ControlUnit.sv Modules/Core.sv Modules/InstructionMemory.sv Modules/DataMemory.sv Modules/RV32Iasic.sv}
current_design RV32I_asic
link

create_clock -name clk -period 25 [get_ports clk]

set_dont_use [get_lib_cells */sky130_fd_sc_hd__fa_*]
set_dont_use [get_lib_cells */sky130_fd_sc_hd__ha_*]
set_dont_use [get_lib_cells */sky130_fd_sc_hd__fah*]

compile_ultra

report_area > area.txt
report_timing > timing.txt
report_power > power.txt

set verilogout_no_tri true
change_names -rules verilog -hierarchy
write -format verilog -hierarchy -output RV32I_synth.v
exit