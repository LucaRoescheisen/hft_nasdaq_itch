import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
from collections import deque
from message_assembly import Assembly_Line, packets, NIC_TX


PCAP_FILE = os.path.join(os.path.dirname(__file__), "../pcap/one.pcap")
BUS_BYTES = 32


def reverse_bytes_256(val: int) -> int:
    byte_array = val.to_bytes(32, byteorder="big")

    reversed_array = byte_array[::-1]

    return int.from_bytes(reversed_array, byteorder="big")


async def drive_frame(dut, frames, messages_processed):
    bit_len = BUS_BYTES * 8
    flipped_value = reverse_bytes_256(frames.frame)
    dut.bus.value = flipped_value
    dut.rx_sof.value = frames.sof
    dut.rx_eof.value = frames.eof
    dut.rx_valid.value = frames.rx_valid

    dut.rx_keep.value = frames.rx_keep
    # assert int(dut.messages_processed.value) == messages_processed, (
    #   f"[  EXPECTED={messages_processed} GOT={int(dut.messages_processed.value)}"
    # )


@cocotb.test()
async def main(dut):
    assembly = Assembly_Line()
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    for _, frames in packets("pcap/one.pcap"):
        for frame in frames:
            await RisingEdge(dut.clk)
            assembly.add_to_line(frame)
            messages_processed = assembly.process()
            await drive_frame(dut, frame, messages_processed)
            # await RisingEdge(dut.clk)
