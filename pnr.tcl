set REF /opt/pdk/digitalbootcamp/ICC2
lappend search_path $REF/lib/sky130_fd_sc_hd/db_nldm
set TECH $REF/tech/milkyway/skywater130_fd_sc_hd.tf
set NDM  $REF/lib/sky130_fd_sc_hd/ndm/sky130_fd_sc_hd.ndm
set MAP  $REF/tech/star_rcxt/skywater130.mw2itf.map
set TLU  $REF/tech/star_rcxt/skywater130.nominal.tluplus

set_host_options -max_cores 8

sh rm -rf RV32I_lib
create_lib -technology $TECH -ref_libs $NDM RV32I_lib
read_verilog RV32I_synth.v
current_design RV32I_asic
link_block

create_corner "worst"
read_parasitic_tech -tlup $TLU -layermap $MAP -name maxTLU
set_parasitic_parameters -early_spec maxTLU -late_spec maxTLU -corner "worst"
set_process_label "nominal"

create_mode functional
create_scenario -mode "functional" -name "functional_worst" -corner worst
read_sdc RV32I.sdc

# Floorplan con margen para el anillo
initialize_floorplan -core_utilization 0.5 -core_offset 15
place_pins -self

# Tap cells
create_tap_cells -lib_cell [get_lib_cells */sky130_fd_sc_hd__tapvpwrvgnd_1] \
                 -distance 14 -pattern stagger -skip_fixed_cells

# Redes de power
create_net -power VPWR
create_net -ground VGND
connect_pg_net -net VPWR [get_pins -hierarchical {*/VPWR */VPB}]
connect_pg_net -net VGND [get_pins -hierarchical {*/VGND */VNB}]

# Anillo
create_pg_ring_pattern ring_pat -horizontal_layer met5 -vertical_layer met4 \
    -horizontal_width 3 -vertical_width 3 -horizontal_spacing 2 -vertical_spacing 2
set_pg_strategy ring_strat -core -pattern {{name: ring_pat} {nets: {VPWR VGND}} {offset: {3 3}}}
compile_pg -strategies ring_strat

# Malla
create_pg_mesh_pattern mesh_pat -layers { \
    {{vertical_layer: met4}   {width: 1.6} {pitch: 50} {spacing: interleaving}} \
    {{horizontal_layer: met5} {width: 1.6} {pitch: 50} {spacing: interleaving}} }
set_pg_strategy mesh_strat -core -pattern {{name: mesh_pat} {nets: {VPWR VGND}}} \
    -extension {{stop: outermost_ring}}
compile_pg -strategies mesh_strat

# Rieles de celdas
create_pg_std_cell_conn_pattern rail_pat -layers {met1}
set_pg_strategy rail_strat -core -pattern {{name: rail_pat} {nets: {VPWR VGND}}}
compile_pg -strategies rail_strat

check_pg_connectivity > pnr_pg.txt

# Placement, reloj y ruteo
set_app_options -name place.coarse.continue_on_missing_scandef -value true
place_opt
clock_opt
route_auto
route_detail -incremental true -max_number_iterations 40
route_opt
route_detail -incremental true -max_number_iterations 20
check_routes > pnr_drc.txt

# Fillers y conexión final de power
create_stdcell_fillers -lib_cells [get_lib_cells *fill*]
connect_pg_net -net VPWR [get_pins -hierarchical {*/VPWR */VPB}]
connect_pg_net -net VGND [get_pins -hierarchical {*/VGND */VNB}]
check_pg_connectivity > pnr_pg_final.txt

report_utilization > pnr_area.txt
report_global_timing > pnr_timing.txt
write_gds -merge_files [glob /opt/pdk/sky130/lib/sky130_fd_sc_hd/gds/*.gds] RV32I.gds
save_lib
exit