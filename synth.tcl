set target_library /opt/pdk/digitalbootcamp/ICC2/lib/sky130_fd_sc_hd/db_nldm/sky130_fd_sc_hd__tt_025C_1v80.db
set link_library "* $target_library"

read_file -format sverilog {ALU.sv RegisterFile.sv ImmediateGenerator.sv ProgramCounter.sv InstructionMemory.sv DataMemory.sv ControlUnit.sv RV32I.sv}
current_design RV32I
current_design RV32I
create_clock -name clk -period 20 [get_ports clk]
compile_ultra

report_area   > area.txt
report_timing > timing.txt
report_power  > power.txt

write -format verilog -hierarchy -output RV32I_synth.v
exit