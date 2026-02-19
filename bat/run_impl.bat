@echo off
call "D:\XilinxSoftware\2025.1\Vivado\settings64.bat"
vivado -mode batch -source tcl/impl.tcl -journal D:/hft_nasdaq_itch/logs/vivado_build.jou -log D:/hft_nasdaq_itch/logs/vivado_build.log