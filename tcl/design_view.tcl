open_project ./vivado/un_risc5.xpr
open_run synth_1
report_utilization -file ./vivado/reports/synth_util_rpt.txt
select_objects [get_cells ]
show_objects [get_cells ]