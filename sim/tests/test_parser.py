import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scapy.all import rdpcap
from pcap_itch_decoder import _read_pcap
from scapy.all import PcapReader
import os

print("LOADED TEST")
PCAP_FILE = os.path.join(os.path.dirname(__file__), "../pcap/ny4-xnas-tvitch-a-20230822T133000.pcap")
@cocotb.test()
async def simple_test(dut):

    print("STARTING TEST")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    with PcapReader(PCAP_FILE) as reader:
        for i, packet in enumerate(reader):
            if i < 16:
                continue
            if i > 16:
                break
            raw = bytes(packet)
            values = _read_pcap(raw)
            if values is None:
                continue

            packet_length =  len(raw)
            dut.valid.value = 1
            j = 0
            while j < packet_length:
                dut.pcap_byte.value = raw[j]
                await RisingEdge(dut.clk)
                j += 1
            print(f"share {dut.debug_shares.value}")
            if values.msg_type == 'A':
                print("CALLED!!!")

                assert int(dut.debug_price.value)  == values.price
                assert int(dut.debug_buy_sell.value) == values.buy_sell

            dut.valid.value = 0

    dut.pcap_byte.value = 0xFF
    await RisingEdge(dut.clk)
    dut.pcap_byte.value = 0x11
    await RisingEdge(dut.clk)
    dut.pcap_byte.value = 0x22
    await RisingEdge(dut.clk)
    await Timer(100, unit="ns")

    val = dut.global_byte_counter.value
    print("Global_byte_counter:", int(val))

    print("DONE")