set REF /opt/pdk/digitalbootcamp/ICC2
lappend search_path $REF/lib/sky130_fd_sc_hd/db_nldm

set TECH $REF/tech/milkyway/skywater130_fd_sc_hd.tf
set NDM  $REF/lib/sky130_fd_sc_hd/ndm/sky130_fd_sc_hd.ndm
set MAP  $REF/tech/star_rcxt/skywater130.mw2itf.map
set TLU  $REF/tech/star_rcxt/skywater130.nominal.tluplus

sh rm -rf RV32I_lib
create_lib -technology $TECH -ref_libs $NDM RV32I_lib

read_verilog RV32I_synth.v
current_design RV32I
link_block

create_corner "worst"
read_parasitic_tech -tlup $TLU -layermap $MAP -name maxTLU
set_parasitic_parameters -early_spec maxTLU -late_spec maxTLU -corner "worst"
set_process_label "nominal"

connect_pg_net -automatic

create_mode functional
create_scenario -mode "functional" -name "functional_worst" -corner worst
read_sdc RV32I.sdc

initialize_floorplan -core_utilization 0.6
set_app_options -name place.coarse.continue_on_missing_scandef -value true

place_opt
clock_opt
route_auto

create_stdcell_fillers -lib_cells [get_lib_cells *fill*]
connect_pg_net -automatic

report_utilization    > pnr_area.txt
report_global_timing  > pnr_timing.txt

write_gds -merge_files $REF/lib/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds RV32I.gds
save_lib
exit