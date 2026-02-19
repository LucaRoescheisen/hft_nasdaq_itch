@echo off
call "D:\XilinxSoftware\2025.1\Vivado\settings64.bat"
vivado -source tcl/design_view.tcl -journal D:/u_risc/logs/vivado_build.jou -log D:/u_risc/logs/vivado_build.log