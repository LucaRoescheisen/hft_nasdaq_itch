from scapy.all import PcapReader
import struct

with PcapReader("sim/pcap/ny4-xnas-tvitch-a-20230822T133000.pcap") as reader:
  for i, packet in enumerate(reader):
    if i == 100:
      break

    raw = bytes(packet)
    payload = raw[46:]
    session = payload[:10].decode('ascii', errors='replace')
    seq_num   = struct.unpack('>Q', payload[10:18])[0]
    msg_count = struct.unpack('>H', payload[18:20])[0]

    #print(f"Session: {session}, Sequence Number: {seq_num}, Message Count: {msg_count}")

    if msg_count == 0xFFFF:
      continue

    msg_type = chr(payload[22])
    print(f"  Message type: {msg_type}")
    offset = 20
    for _ in range(msg_count):
      msg_len = struct.unpack(">H", payload[offset: offset + 2])[0]
      msg_body = payload[offset+2:offset+2+msg_len]
      msg_type = chr(msg_body[0])

      if msg_type == "A": #No MPID
        stock = msg_body[24:32].decode('ascii').strip()
        shares = struct.unpack('>I', msg_body[20:24])[0]
        price    = struct.unpack('>I', msg_body[32:36])[0] / 10000.0
        buy_sell = chr(msg_body[19])
        print(f"  Add Order No MPID: {stock} {buy_sell} {shares} @${price}")
