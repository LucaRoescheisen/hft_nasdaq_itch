import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scapy.all import rdpcap
from pcap_itch_decoder import MPID_MESSAGE, NOMPID_MESSAGE, ORDER_EXECUTE_MESSAGE, REPLACE_MESSAGE, ORDER_EXECUTE_WITH_PRICE_MESSAGE, CANCEL_MESSAGE, DELETE_MESSAGE, _read_pcap
from scapy.all import PcapReader
import os
import numpy as np
from collections import deque
import builtins
from cuckoo_model import Cuckoo, packets
PCAP_FILE = os.path.join(os.path.dirname(__file__), "../pcap/one.pcap")

# Cuckoo has Data structure




async def drive_message(dut, ref_num, msg_type):
    await RisingEdge(dut.clk);
    if msg_type == "A":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.add_order_noMPID_message.value = ref_num << 136
    elif msg_type == "F":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.add_order_MPID_message.value = ref_num << 200
    else:
        return
    await RisingEdge(dut.clk);
    dut.we.value = 0


async def monitor(dut, expected_queue, cuckoo_hmap, stats):
    counter = 0;
    while True:
        await RisingEdge(dut.clk)
        if len(expected_queue) == 0:
            continue
        expected = expected_queue.popleft()
        print(expected)
        if expected is not None:
            if expected.msg_type == "A" and isinstance(expected, NOMPID_MESSAGE):
                hash1 = toeplitz_hash1(expected.order_ref_number)
                hash2 = toeplitz_hash2(expected.order_ref_number)
                insert(hash1, hash2, cuckoo_hmap, stats)
                print("NoMPID")
                

            elif expected.msg_type == "U" and isinstance(expected, REPLACE_MESSAGE):
                print("Order replace")
                

            elif expected.msg_type == "F" and isinstance(expected, MPID_MESSAGE):
                print("MPID")
                hash1 = toeplitz_hash1(expected.order_ref_number)
                hash2 = toeplitz_hash2(expected.order_ref_number)
                insert(hash1, hash2, cuckoo_hmap, stats)

            elif expected.msg_type == "E" and isinstance(expected, ORDER_EXECUTE_MESSAGE):
                print("Order Executed")
                

            elif expected.msg_type == "C" and isinstance(expected, ORDER_EXECUTE_WITH_PRICE_MESSAGE):
                print("Order Executed with price")
                

            elif expected.msg_type == "X" and isinstance(expected, CANCEL_MESSAGE):
                print("Order cancel")
                

            elif expected.msg_type == "D" and isinstance(expected, DELETE_MESSAGE):
                print("Order delete")
                

            else:
                print("Message currently not supported")


@cocotb.test()
async def main(dut):
    all_packets = []
    cuckoo_hmap = {}
    m = Cuckoo()
    stats = {"collisions": 0}
    #original_print = builtins.print
    #builtins.print = lambda *args, **kwargs: None
    
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await RisingEdge(dut.clk);
    dut.reset.value = 1;
    await RisingEdge(dut.clk);
    dut.reset.value = 0;
    await RisingEdge(dut.clk);
    for _, msgs in packets("pcap/one.pcap"):
        for msg in msgs:
            await RisingEdge(dut.clk);
            ref_num, msg_type = m.process(msg)
            if ref_num is None or msg_type is None:
                continue
            await drive_message(dut, ref_num, msg_type)

            await RisingEdge(dut.clk);
           
    print(f"Collisions: {int(dut.collisions.value)}")
    print(f"Inserts 1: {int(dut.inserts_1.value)}")
    print(f"Inserts 2: {int(dut.inserts_2.value)}")
    print(m.stats)
    #builtins.print = original_print
    expected_queue = deque()
    #monitor_task = cocotb.start_soon(monitor(dut, expected_queue, cuckoo_hmap, stats))
    await RisingEdge(dut.clk)
    for _ in range(10):
        await RisingEdge(dut.clk)
    for i, packet in enumerate(all_packets):
        print(f"Packet: {i}")
        expected_queue.extend(packet["expected"])
        #await drive_packet(dut, packet["raw"])

    while expected_queue:
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    #monitor_task.cancel()




