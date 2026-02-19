open_project ./vivado/hft.xpr
set_property top tb_top [get_filesets sim_1]
update_compile_order -fileset sources_1

launch_simulation
open_wave_config {D:/hft_nasdaq_itch/vivado/wavetables/new.wcfg}
restart