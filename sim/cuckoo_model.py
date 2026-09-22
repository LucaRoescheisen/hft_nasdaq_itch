from scapy.all import RawPcapReader
from pcap_itch_decoder import _read_pcap

import builtins
KEY_A = 0x6c62272e07bb01428d7f
KEY_B = 0x9E3779B97F4A7C15FD13 
def bit_slice(value, high, width):
    low = high - width + 1
    mask = (1<< width) - 1
    return (value >>low) & mask

def xor_reduction(value):
    return bin(value).count('1') & 1


def toeplitz_hash(ref_number, key_val):
    hash1 = 0
    for i in range(10):
        key = bit_slice(key_val, 63 + i, 64)
        anded_val = ref_number & key
        hash1 |= xor_reduction(anded_val) << i
    return hash1




def insert(hash1_num, hash2_num,cuckoo_hmap, stats):
    if hash1_num in cuckoo_hmap:
        stats["collisions"] += 1

        cuckoo_hmap[hash2_num] = 1
        print("Collision Occured:", stats["collisions"])
    else:
        
        cuckoo_hmap[hash1_num] = 1


class Cuckoo:
    def __init__(self):
        self.table_1 = {}
        self.table_2 = {}
        self.stats = {"inserts_1": 0, "inserts_2": 0, "collisions": 0, "deletions_1": 0, "deletions_2":0, "peak_live":0, "exec_cancel_hits":0}
        self.shares = {} #used just for testing
        self.h1 = 0
        self.h2 = 0
        self.n1 = 0
        self.n2 = 0
    def insert(self, ref):
        self.h1 = toeplitz_hash(ref, KEY_A)
        self.h2 = toeplitz_hash(ref, KEY_B)
        self.n1 = len(self.table_1.get(self.h1, ()))
        self.n2 = len(self.table_2.get(self.h2, ()))
        
        if self.n1 == 4 and self.n2 == 4:
            self.stats["collisions"] += 1                   
        elif self.n1 <= self.n2:
            self.table_1.setdefault(self.h1, []).append(ref)
            self.stats["inserts_1"] += 1
        else:
            self.table_2.setdefault(self.h2, []).append(ref)
            self.stats["inserts_2"] += 1


      
    def remove(self, ref):
        self.h1 = toeplitz_hash(ref, KEY_A)
        self.h2 = toeplitz_hash(ref, KEY_B)
        in_table_1 = self.h1 in self.table_1
        in_table_2 = self.h2 in self.table_2
        if in_table_1 and ref in self.table_1[self.h1]:
            self.table_1[self.h1].remove(ref)
            self.stats["deletions_1"] += 1
        elif in_table_2 and ref in self.table_2[self.h2]:
            self.table_2[self.h2].remove(ref)
            self.stats["deletions_2"] += 1

    def replace(self, ref_old, ref_new):
        self.remove(ref_old)
        self.insert(ref_new)

    def contains(self, ref):
        self.h1 = toeplitz_hash(ref, KEY_A)
        self.h2 = toeplitz_hash(ref, KEY_B)
        return ref in self.table_1.get(self.h1, ()) or ref in self.table_2.get(self.h2, ())


    def process(self, msg):
        if msg is None:
            return None, None, None
        if msg.msg_type in ("A", "F") and msg.stock_symbol == "SPY":
            self.insert(msg.order_ref_number)
            self.shares[msg.order_ref_number] = msg.shares
            live = (self.stats["inserts_1"] + self.stats["inserts_2"] - self.stats["deletions_1"] - self.stats["deletions_2"])
            self.stats["peak_live"] = max(self.stats.get("peak_live", 0), live)
            return msg.order_ref_number, 0, msg.msg_type
        elif msg.msg_type == "D" and msg.stock_locate == b'%%':
            self.remove(msg.order_ref_number)
            self.shares.pop(msg.order_ref_number, None)
            return msg.order_ref_number, 0, msg.msg_type
        elif msg.msg_type == "U" and msg.stock_locate == b'%%':
            self.replace(msg.original_ref, msg.new_ref)
            return msg.original_ref, msg.new_ref, msg.msg_type
            #  elif msg.msg_type in ("E", "C", "X") and msg.stock_locate == b'%%':
            #if self.contains(msg.order_ref_number):
            # self.stats["exec_cancel_hits"] += 1
            #   if msg.order_ref_number in self.shares:
            #  self.shares[msg.order_ref_number] -= msg.shares
            #  if self.shares[msg.order_ref_number] <= 0:
            # del self.shares[msg.order_ref_number]
            # self.remove(msg.order_ref_number)
        return None, None, None
def packets(path, limit=100000):
    with RawPcapReader(path) as r:
        for i, (raw, _) in enumerate(r):
            if limit is not None and i >= limit:
                break
            yield raw, _read_pcap(raw)


if __name__ == "__main__":
    m = Cuckoo()
    original_print = builtins.print
    builtins.print = lambda *args, **kwargs: None
    for _, msgs in packets("pcap/one.pcap"):
        for msg in msgs:
            m.process(msg)

    builtins.print = original_print

    print(m.stats)

