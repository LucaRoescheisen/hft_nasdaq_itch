import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scapy.all import rdpcap
from pcap_itch_decoder import MPID_MESSAGE, NOMPID_MESSAGE, ORDER_EXECUTE_MESSAGE, REPLACE_MESSAGE, ORDER_EXECUTE_WITH_PRICE_MESSAGE, CANCEL_MESSAGE, DELETE_MESSAGE, _read_pcap
from scapy.all import PcapReader
import os
import numpy as np
from collections import deque
PCAP_FILE = os.path.join(os.path.dirname(__file__), "../pcap/one.pcap")
KEY_A = 0x6c62272e07bb01428d7f
KEY_B = 0x9E3779B97F4A7C15FD13 
# Cuckoo has Data structure




async def drive_packet(dut, raw):
    dut.valid.value = 1
    for byte in raw:
        dut.pcap_byte.value = byte
        await RisingEdge(dut.clk)
    dut.valid.value = 0
    dut.pcap_byte.value = 0


async def monitor(dut, expected_queue, cuckoo_hmap, collision_counter):
    while True:
        await RisingEdge(dut.clk)
        if dut.msg_done.value:
            expected = expected_queue.popleft()
            print(expected)
            print(int(dut.debug_replace_price.value))
            if expected is not None:
                if expected.msg_type == "A" and isinstance(expected, NOMPID_MESSAGE):
                    hash1 = toeplitz_hash1(dut.debug_noMPID_order_ref_number)
                    hash2 = toeplitz_hash2(dut.debug_noMPID_order_ref_number)
                    insert(hash1, hash2, dut.debug_noMPID_order_ref_number, collision_counter)
                    print("NoMPID")
                    print(dut.debug_noMPID_order_ref_number)
                    

                elif expected.msg_type == "U" and isinstance(expected, REPLACE_MESSAGE):
                    print("Order replace")
                    

                elif expected.msg_type == "F" and isinstance(expected, MPID_MESSAGE):
                    print("MPID")
                    hash1 = toeplitz_hash1(dut.debug_MPID_order_ref_number)
                    hash2 = toeplitz_hash2(dut.debug_MPID_order_ref_number)
                    insert(hash1, hash2, dut.debug_MPID_order_ref_number, collision_counter)

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
    cuckoo_hmap = np.zeros(2048)
    collision_counter = 0


    with PcapReader(PCAP_FILE) as reader:
        for i, packet in enumerate(reader):
            if i == 1000:
                break
            raw = bytes(packet)
            result = _read_pcap(raw)
            all_packets.append({"raw": raw, "expected": result})
    print("STARTING Cuckoo hash SIM")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    expected_queue = deque()
    monitor_task = cocotb.start_soon(monitor(dut, expected_queue, cuckoo_hmap, collision_counter))
    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    for _ in range(10):
        await RisingEdge(dut.clk)

    for i, packet in enumerate(all_packets):
        print(f"Packet: {i}")
        expected_queue.extend(packet["expected"])
        await drive_packet(dut, packet["raw"])

    while expected_queue:
        await RisingEdge(dut.clk)

    await RisingEdge(dut.clk)
    monitor_task.cancel()




def bit_slice(value, high, width):
    low = high - width + 1
    mask = (1<< width) - 1
    return (value >>low) & mask

def xor_reduction(value):
    return bin(value).count('1') & 1


def toeplitz_hash1(ref_number):
    hash1 = 0
    for i in range(10):
        key = bit_slice(KEY_A, 63 + i, 64)
        anded_val = ref_number & key
        hash1 |= xor_reduction(anded_val)
    return hash1

def toeplitz_hash2(ref_number):
    hash1 = 0
    for i in range(10):
        key = bit_slice(KEY_B, 63 + i, 64)
        anded_val = ref_number & key
        hash1 |= xor_reduction(anded_val)
    return hash1



def insert(hash1_num, hash2_num,cuckoo_hmap, collision_counter):
    if(cuckoo_hmap[hash2_num] == 1):
        collision_counter += 1
        print("Collision Occured:", collision_counter)
    else:
        cuckoo_hmap[hash2_num] = 1
        
    return

