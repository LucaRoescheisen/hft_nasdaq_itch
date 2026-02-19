@echo off
call "D:\XilinxSoftware\2025.1\Vivado\settings64.bat"
vivado -mode batch -source tcl/impl.tcl -journal D:/u_risc/logs/vivado_build.jou -log D:/u_risc/logs/vivado_build.log