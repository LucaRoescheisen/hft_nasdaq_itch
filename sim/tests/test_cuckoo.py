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




async def drive_message(dut, ref_num, ref_num_new, msg_type):
    await RisingEdge(dut.clk);
    if msg_type == "A":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.add_order_noMPID_message.value = ref_num << 136
    elif msg_type == "F":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.add_order_MPID_message.value = ref_num << 168
    elif msg_type == "D":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.order_delete_message.value = ref_num << 0;
    elif msg_type == "U":
        dut.msg_type.value = ' '.join(f"{ord(char):08b}" for char in msg_type)
        dut.we.value = 1
        dut.order_replace_message.value = (ref_num << 128) | (ref_num_new << 64)
    else:
        return
    await RisingEdge(dut.clk);
    dut.we.value = 0


  
@cocotb.test()
async def main(dut):
    all_packets = []
    m = Cuckoo()
    hdl_stats = {"inserts_1": 0, "inserts_2": 0, "collisions": 0, "deletions_1": 0, "deletions_2":0, "peak_live":0, "exec_cancel_hits":0}
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
            ref_num, ref_num_new, msg_type = m.process(msg)
            if ref_num is None or msg_type is None:
                continue
            await drive_message(dut, ref_num, ref_num_new, msg_type)
            await RisingEdge(dut.clk);
            #assert int(dut.h1_debug.value) == m.h1, f"{counter}"
            #assert int(dut.ref_num_r.value) == ref_num, f"{counter}, {msg_type}, {ref_num}"
            #assert int(dut.msg_type_debug.value) == ord(msg_type), f"{counter}"
    hdl_stats["inserts_1"] = int(dut.inserts_1.value)
    hdl_stats["inserts_2"] = int(dut.inserts_2.value)
    hdl_stats["collisions"] = int(dut.collisions.value)
    hdl_stats["deletions_1"] = int(dut.deletions_1.value)
    hdl_stats["deletions_2"] = int(dut.deletions_2.value)
    print(hdl_stats)
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




