SIM = verilator
TOPLEVEL_LANG = verilog

VERILOG_SOURCES = \
    $(PWD)/../rtl/message_pckg.sv \
		$(PWD)/../rtl/parser.sv \
		$(PWD)/../rtl/order_book.sv \
    $(PWD)/../rtl/top.sv

TOPLEVEL = top
MODULE = tests.test_parser
COMPILE_ARGS = +define+DEBUG
EXTRA_ARGS += --sv --trace
WAVES = 1
include $(shell cocotb-config --makefiles)/Makefile.sim
