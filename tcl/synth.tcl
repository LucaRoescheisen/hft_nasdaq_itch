open_project ./vivado/hft.xpr

# Reset previous run if it exists
reset_run synth_1

# Launch synthesis
launch_runs synth_1 -jobs 8 -verbose
wait_on_run synth_1

# Generate reports from this new run
open_run synth_1

# Now you can generate reports
report_timing_summary -file ./vivado/reports/synth_timing_rpt.txt
report_utilization -file ./vivado/reports/synth_util_rpt.txt
report_methodology -file ./vivado/reports/linter_methodology.txt
report_drc -file ./vivado/reports/drc/synth_drc.rpt