set target_library /home/a01403474/lib/stdcell_hvt/db_nldm/saed32hvt_ss0p75v125c.db
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