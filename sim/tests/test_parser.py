import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scapy.all import rdpcap

print("LOADED TEST")

@cocotb.test()
async def simple_test(dut):

    print("STARTING TEST")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.pcap_byte.value = 0xFF
    await RisingEdge(dut.clk)   # t=10ns, RTL samples 0xFF
    dut.pcap_byte.value = 0x11
    await RisingEdge(dut.clk)   # t=20ns, RTL samples 0x11
    dut.pcap_byte.value = 0x22
    await RisingEdge(dut.clk)
    await Timer(100, unit="ns")

    val = dut.global_byte_counter.value
    print("Global_byte_counter:", int(val))

    print("DONE")