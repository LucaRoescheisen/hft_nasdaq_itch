set proj_name un_risc5
set part xc7s50csga324-1
set proj_dir [file normalize "./vivado"]
set top top

create_project $proj_name $proj_dir -part $part -force

add_files [glob ./rtl/*.v]
set_property top $top [current_fileset]

add_files -fileset constrs_1 ./constr/Arty-S7-50-Master.xdc

#foreach ip_script [glob ./tcl/ip/*.tcl] {
   # source $ip_script
#}
update_compile_order -fileset sources_1
check_syntax -fileset sources_1