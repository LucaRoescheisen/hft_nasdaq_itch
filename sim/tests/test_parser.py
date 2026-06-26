import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from scapy.all import rdpcap
from pcap_itch_decoder import MPID_MESSAGE, NOMPID_MESSAGE, REPLACE_MESSAGE, _read_pcap
from scapy.all import PcapReader
import os
from collections import deque

print("LOADED TEST")
PCAP_FILE = os.path.join(os.path.dirname(__file__), "../pcap/one.pcap")


async def drive_packet(dut, raw):
    dut.valid.value = 1
    for byte in raw:
        dut.pcap_byte.value = byte
        await RisingEdge(dut.clk)
    dut.valid.value = 0
    dut.pcap_byte.value = 0


async def monitor(dut, expected_queue):
    while True:
        await RisingEdge(dut.clk)
        if dut.msg_done.value:
            expected = expected_queue.popleft()
            print(expected)
            print(int(dut.debug_replace_price.value))
            if expected is not None:
                if expected.msg_type == "A" and isinstance(expected, NOMPID_MESSAGE):
                    print("NoMPID")
                    assert int(dut.debug_noMPID_price.value) == expected.price, (
                        f"[msg EXPECTED={expected.price} GOT={int(dut.debug_noMPID_price.value)}"
                    )
                    assert int(dut.debug_noMPID_shares.value) == expected.shares, (
                        f"[msg EXPECTED={expected.shares} GOT={int(dut.debug_noMPID_price.value)}"
                    )
                    assert int(dut.debug_noMPID_stock.value) == expected.stock, (
                        f"[msg EXPECTED={expected.stock} GOT={int(dut.debug_noMPID_stock.value)}"
                    )

                    assert int(dut.debug_noMPID_buy_sell.value) == expected.buy_sell, (
                        f"[msg EXPECTED={expected.buy_sell} GOT={int(dut.debug_noMPID_buy_sell.value)}"
                    )

                elif expected.msg_type == "U" and isinstance(expected, REPLACE_MESSAGE):
                    print("Order replace")
                    print(
                        f"[msg EXPECTED={expected.price} GOT={int(dut.debug_replace_price.value)}]"
                    )
                    assert int(dut.debug_replace_price.value) == expected.price, (
                        f"[msg EXPECTED={expected.price} GOT={int(dut.debug_replace_price.value)}"
                    )
                    assert int(dut.debug_replace_shares.value) == expected.shares, (
                        f"[msg EXPECTED={expected.shares} GOT={int(dut.debug_replace_shares.value)}"
                    )
                elif expected.msg_type == "F" and isinstance(expected, MPID_MESSAGE):
                    assert int(dut.debug_MPID_price.value) == expected.price
                    assert int(dut.debug_MPID_shares.value) == expected.shares
                    assert int(dut.debug_MPID_stock.value) == expected.stock
                    assert int(dut.debug_MPID_buy_sell.value) == expected.buy_sell
            else:
                print("Message currently not supported")


@cocotb.test()
async def main(dut):
    all_packets = []
    with PcapReader(PCAP_FILE) as reader:
        for i, packet in enumerate(reader):
            if i == 1000:
                break
            raw = bytes(packet)
            result = _read_pcap(raw)
            all_packets.append({"raw": raw, "expected": result})
    print("STARTING SIM")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    expected_queue = deque()
    monitor_task = cocotb.start_soon(monitor(dut, expected_queue))
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
