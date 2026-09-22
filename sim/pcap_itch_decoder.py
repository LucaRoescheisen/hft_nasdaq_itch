from collections import namedtuple
import struct

NOMPID_MESSAGE = namedtuple(
    "NOMPID_MESSAGE", ["order_ref_number", "msg_type", "stock", "shares", "price", "buy_sell", "stock_symbol"]
)
REPLACE_MESSAGE = namedtuple(
    "REPLACE_MESSAGE",
    ["msg_type", "shares", "price", "original_ref", "new_ref", "stock_locate"],
)
MPID_MESSAGE = namedtuple(
    "MPID_MESSAGE", ["order_ref_number", "msg_type", "stock", "shares", "price", "buy_sell", "stock_symbol"]
)
ORDER_EXECUTE_MESSAGE = namedtuple(
    "ORDER_EXECUTE_MESSAGE",
    ["msg_type", "shares", "order_ref_number", "match_number", "stock_locate"]
)
ORDER_EXECUTE_WITH_PRICE_MESSAGE = namedtuple(
    "ORDER_EXECUTE_WITH_PRICE_MESSAGE",
    ["msg_type", "shares", "order_ref_number", "match_number", "price", "stock_locate"]
)
CANCEL_MESSAGE = namedtuple(
    "CANCEL_MESSAGE", ["msg_type", "shares", "order_ref_number", "stock_locate"]
)
DELETE_MESSAGE = namedtuple(
    "DELETE_MESSAGE", ["msg_type", "order_ref_number", "stock_locate"]
)





def _read_pcap(raw):
    payload = raw[46:]
    session = payload[:10].decode("ascii", errors="replace")
    seq_num = struct.unpack(">Q", payload[10:18])[0]
    msg_count = struct.unpack(">H", payload[18:20])[0]
    # print(f"Session: {session}, Sequence Number: {seq_num}, Message Count: {msg_count}")
    if msg_count == 0xFFFF:
        return

    offset = 20
    results = []
    for k in range(msg_count):
        msg_len = struct.unpack(">H", payload[offset : offset + 2])[0]
        msg_body = payload[offset + 2 : offset + 2 + msg_len]
        offset += 2 + msg_len
        msg_type = chr(msg_body[0])
        #print(f"Message type: {msg_type}")
        if msg_type == "A":
            #print(f"Found NoMPID at message {k + 1} of {msg_count}")
            order_reference_number = int.from_bytes(msg_body[11:19], "big")
            
            stock_bytes = msg_body[24:32]
            stock_int = int.from_bytes(stock_bytes, "big")
            
            shares = struct.unpack(">I", msg_body[20:24])[0]
            price = struct.unpack(">I", msg_body[32:36])[0]
            buy_sell = msg_body[19]  # raw int, matches dut signal comparison
            stock_symbol = stock_bytes.decode('ascii').strip()
            #print(f"  Add Order No MPID: {stock_symbol}"
             #   f"{'B' if buy_sell == ord('B') else 'S'} {shares} @${price / 10000:.4f}")
            results.append(NOMPID_MESSAGE(order_reference_number, msg_type, stock_int, shares, price, buy_sell, stock_symbol))
        elif msg_type == "U":
            #print(f"Found replace at message {k + 1} of {msg_count}")
            shares = struct.unpack(">I", msg_body[27:31])[0]
            price = struct.unpack(">I", msg_body[31:35])[0]
            original_ref = struct.unpack(">Q", msg_body[11:19])[0]
            new_ref = struct.unpack(">Q", msg_body[19:27])[0]
            #print(f" Replace Order: {shares} @${price / 10000:.4f}")
            stock_locate = msg_body[1:3]
            
            results.append(REPLACE_MESSAGE(msg_type, shares, price, original_ref, new_ref, stock_locate))
        elif msg_type == "F":
            
            order_reference_number = int.from_bytes(msg_body[11:19], "big")
            #print(f"Found MPID at message {k + 1} of {msg_count}")
            stock_bytes = msg_body[24:32]
            stock_int = int.from_bytes(stock_bytes, "big")
            stock_symbol = stock_bytes.decode('ascii').strip()
            shares = struct.unpack(">I", msg_body[20:24])[0]
            price = struct.unpack(">I", msg_body[32:36])[0]
            buy_sell = msg_body[19]  # raw int, matches dut signal comparison
            #print(f"  Add Order MPID: {stock_symbol} "
             #   f"{'B' if buy_sell == ord('B') else 'S'} {shares} @${price / 10000:.4f}")
            results.append(MPID_MESSAGE(order_reference_number, msg_type, stock_int, shares, price, buy_sell, stock_symbol))
        elif msg_type == "E":
            #print(f"Found order executed at message {k + 1} of {msg_count}")
            order_reference_number = struct.unpack(">Q", msg_body[11:19])[0]
            shares = struct.unpack(">I", msg_body[19:23])[0]
            match_number = struct.unpack(">Q", msg_body[23:31])[0]
            stock_locate = msg_body[1:3]
            results.append(ORDER_EXECUTE_MESSAGE(msg_type, shares, order_reference_number, match_number, stock_locate))
        elif msg_type == "C":
            #print(f"Found order executed with price at message {k + 1} of {msg_count}")
            order_reference_number = struct.unpack(">Q", msg_body[11:19])[0]
            shares = struct.unpack(">I", msg_body[19:23])[0]
            match_number = struct.unpack(">Q", msg_body[23:31])[0]
            price = struct.unpack(">I", msg_body[32:36])[0]
            stock_locate = msg_body[1:3]
            results.append(ORDER_EXECUTE_WITH_PRICE_MESSAGE(msg_type, shares, order_reference_number, match_number, price, stock_locate))
        elif msg_type == "X":
            #print(f"Found cancel at message {k + 1} of {msg_count}")
            order_reference_number = struct.unpack(">Q", msg_body[11:19])[0]
            shares = struct.unpack(">I", msg_body[19:23])[0]
            stock_locate = msg_body[1:3]
            results.append(CANCEL_MESSAGE(msg_type, shares, order_reference_number, stock_locate))
        elif msg_type == "D":
            #print(f"Found delete at message {k + 1} of {msg_count}")

            stock_locate = msg_body[1:3]

            order_reference_number = struct.unpack(">Q", msg_body[11:19])[0]
            results.append(DELETE_MESSAGE(msg_type, order_reference_number, stock_locate))
        else:
            results.append(None)
    return results
