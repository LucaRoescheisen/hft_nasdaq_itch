from scapy.all import PcapReader
from collections import namedtuple
import struct

ITCHMessage = namedtuple(
    "ITCH_MESSAGE", ["msg_type", "stock", "shares", "price", "buy_sell"]
)


def _read_pcap(raw):
    payload = raw[46:]
    session = payload[:10].decode("ascii", errors="replace")
    seq_num = struct.unpack(">Q", payload[10:18])[0]
    msg_count = struct.unpack(">H", payload[18:20])[0]
    # print(f"Session: {session}, Sequence Number: {seq_num}, Message Count: {msg_count}")
    if msg_count == 0xFFFF:
        return
    msg_type = chr(payload[22])
    print(f"  Message type: {msg_type}")
    offset = 20
    for _ in range(msg_count):
        msg_len = struct.unpack(">H", payload[offset : offset + 2])[0]
        msg_body = payload[offset + 2 : offset + 2 + msg_len]
        offset += 2 + msg_len
        msg_type = chr(msg_body[0])

        if msg_type == "A":
            stock_bytes = msg_body[24:32]
            stock_int = int.from_bytes(stock_bytes, "big")
            shares = struct.unpack(">I", msg_body[20:24])[0]
            price = struct.unpack(">I", msg_body[32:36])[0]
            buy_sell = msg_body[19]  # raw int, matches dut signal comparison
            print(
                f"  Add Order No MPID: {stock_bytes.decode('ascii').strip()} "
                f"{'B' if buy_sell == ord('B') else 'S'} {shares} @${price / 10000:.4f}"
            )
            return ITCHMessage(msg_type, stock_int, shares, price, buy_sell)

