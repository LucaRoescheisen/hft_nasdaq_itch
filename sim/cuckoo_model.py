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
    def insert(self, ref):
        h1 = toeplitz_hash(ref, KEY_A)
        h2 = toeplitz_hash(ref, KEY_B)
        n1 = len(self.table_1.get(h1, ()))
        n2 = len(self.table_2.get(h2, ()))
        
        if n1 == 4 and n2 == 4:
            self.stats["collisions"] += 1                   
        elif n1 <= n2:
            self.table_1.setdefault(h1, []).append(ref)
            self.stats["inserts_1"] += 1
        else:
            self.table_2.setdefault(h2, []).append(ref)
            self.stats["inserts_2"] += 1


      
    def remove(self, ref):
        h1 = toeplitz_hash(ref, KEY_A)
        h2 = toeplitz_hash(ref, KEY_B)
        in_table_1 = h1 in self.table_1
        in_table_2 = h2 in self.table_2
        if in_table_1 and ref in self.table_1[h1]:
            self.table_1[h1].remove(ref)
            self.stats["deletions_1"] += 1
        elif in_table_2 and ref in self.table_2[h2]:
            self.table_2[h2].remove(ref)
            self.stats["deletions_2"] += 1

    def replace(self, ref_old, ref_new):
        self.remove(ref_old)
        self.insert(ref_new)

    def contains(self, ref):
        h1 = toeplitz_hash(ref, KEY_A)
        h2 = toeplitz_hash(ref, KEY_B)
        return ref in self.table_1.get(h1, ()) or ref in self.table_2.get(h2, ())


    def process(self, msg):
        if msg is None:
            return None, None
        if msg.msg_type in ("A", "F") and msg.stock_symbol == "SPY":
            self.insert(msg.order_ref_number)
            self.shares[msg.order_ref_number] = msg.shares
            live = (self.stats["inserts_1"] + self.stats["inserts_2"] - self.stats["deletions_1"] - self.stats["deletions_2"])
            self.stats["peak_live"] = max(self.stats.get("peak_live", 0), live)
            return msg.order_ref_number, msg.msg_type
       
        return None, None
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

