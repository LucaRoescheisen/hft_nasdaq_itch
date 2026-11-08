from scapy.all import RawPcapReader
from collections import namedtuple
import struct
from dataclasses import dataclass

MAX_LENGTH = 1024
ASSEMBLY_BYTES = 128
BUS_BYTES = 32


@dataclass
class NIC_TX:
    sof: int
    eof: int
    rx_valid: int
    rx_keep: int
    frame: int


class Assembly_Line:
    def __init__(self):
        self.buffer = bytearray()
        self.max_bytes = ASSEMBLY_BYTES

    def add_to_line(self, frame: NIC_TX):
        if not frame.rx_valid:
            return

        valid_bytes = frame.rx_keep.bit_count()
        data = frame.frame.to_bytes(BUS_BYTES, "big")
        data = data[:valid_bytes]

        if len(self.buffer) + len(data) > self.max_bytes:
            raise ValueError("Assembly buffer full")
        self.buffer.extend(data)

    def process(self):
        count = 0
        for i in range(2):
            if len(self.buffer) < 2:
                break

            msg_len = int.from_bytes(self.buffer[:2], "big")

            if msg_len == 0:
                print("ZERO LENGTH PREFIX")
                print("Buffer length:", len(self.buffer))
                print("First 32 bytes:", self.buffer[:32].hex(" "))
                raise ValueError("Zero length message error")
            total_len = 2 + msg_len
            if len(self.buffer) < total_len:
                break

            msg_body = bytes(self.buffer[2:total_len])
            del self.buffer[:total_len]

            print(
                f"Extracted type={chr(msg_body[0])}, "
                f"length={msg_len}, "
                f"buffer remaining={len(self.buffer) * 8}"
            )
            count = i + 1
        print(f"Processed : {count}")
        return count + 1


def msg_extractor(raw):
    payload = raw[46:]

    msg_count = struct.unpack(">H", payload[18:20])[0]
    payload = payload[20:]

    stream = bytearray()
    offset = 0

    for _ in range(msg_count):
        msg_len = int.from_bytes(payload[offset : offset + 2], "big")
        record_end = offset + 2 + msg_len

        if record_end > len(payload):
            raise ValueError("Message extends beyond packet payload")

        stream.extend(payload[offset:record_end])
        offset = record_end

    frames = []

    for start in range(0, len(stream), BUS_BYTES):
        chunk = bytes(stream[start : start + BUS_BYTES])
        valid_bytes = len(chunk)

        padded = chunk.ljust(BUS_BYTES, b"\x00")
        frame_value = int.from_bytes(padded, "big")

        frames.append(
            NIC_TX(
                sof=int(start == 0),
                eof=int(start + BUS_BYTES >= len(stream)),
                rx_valid=1,
                rx_keep=(1 << valid_bytes) - 1,
                frame=frame_value,
            )
        )

    return frames


def packets(path, limit=10):
    with RawPcapReader(path) as r:
        for i, (raw, _) in enumerate(r):
            if limit is not None and i >= limit:
                break
            yield raw, msg_extractor(raw)


def main():
    asm_line = Assembly_Line()
    # original_print = builtins.print
    # builtins.print = lambda *args, **kwargs: None
    for _, frames in packets("pcap/one.pcap"):
        for frame in frames:
            asm_line.add_to_line(frame)
            asm_line.process()

    # builtins.print = original_print


if __name__ == "__main__":
    main()
