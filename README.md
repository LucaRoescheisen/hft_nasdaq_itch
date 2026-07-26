![Status: WIP](https://img.shields.io/badge/status-WIP-yellow)


# NASDAQ ITCH Hardware Parser & Trading Pipeline

A SystemVerilog implementation of a NASDAQ ITCH 5.0 feed handler, built and verified
against real market data captures. Long-term goal: parser → order book → matching
engine, cross-checked against Python and C++ reference models.

## Status

| Component        | Status | Notes  |
|------------------|--------|--------|
| ITCH Parser      | ✅ Done | Verified against 100k+ pcap captures |
| Order Book       | 🚧 In progress | Architecture design underway |
| Matching Engine  | ⏳ Planned |   |


## ITCH Parser

Parses NASDAQ ITCH 5.0 messages directly from raw packet streams, with no pre-stripped payloads. The decoder
tracks the byte offsets through the full stack:

`Ethernet → IP → UDP → MoldUDP64 (session/sequence/message count) → ITCH message body`

The packet length and message boundaries are computed dynamically from the UDP length field and MoldUPD64 message-length
prefix, so the design handles variable-length, multi-message packets.

### Message types supported
- Add Order (No MPID)
- Add Order (MPID)
- Order Executed
- Order Executed with Price
- Order Replace
- Order Cancel
- Order Delete
- Stock Directory
- System Event

### Verification
The parser is validated with a self-checking cocotb testbench rather than manual
waveform inspection:

1. A Python reference decoder (`pcap_itch_decoder.py`, using `scapy`) reads raw
   pcap files and independently decodes each ITCH message field-by-field via
   `struct.unpack`, producing an expected-value queue per packet.
2. `test_parser.py` streams the same raw packet bytes into the DUT byte-by-byte
   over `cocotb`, mirroring how bytes would actually arrive off a NIC.
3. A monitor coroutine watches for the `msg_done` strobe and asserts every decoded
   field (price, shares, order reference number, match number, stock symbol,
   buy/sell side, etc.) against the Python reference model for each message type.
4. Run across **100,000+ real ITCH pcap captures**, giving field-level correctness
   confidence at production-relevant scale rather than a handful of hand-crafted
   test vectors.

## Order Book (in progress)

Designing a limit order book that consumes the parser's decoded message stream,
built around three core structures: a stable array for order storage, a cuckoo
hash table for O(1) order lookup, and per-side price-level arrays for FIFO
matching order.

### Data structures

- **Stable array** — fixed-size array of 2048 entries, each holding an order's
  reference number, price, and share count. This is the canonical storage for
  live orders; every other structure stores indices into it rather than
  duplicating order data.
- **Freelist** — a stack of unused stable array indices. New orders pop an index
  off the freelist; deleted orders push their index back on.
- **Cuckoo hash table** — maps order reference number → stable array index.
  Each order reference number is hashed twice using a Toeplitz hash, giving two
  candidate table addresses (standard cuckoo hashing). Each table entry stores
  the stable array index of the order, plus the stable array index of the next
  order at the same price level (used to maintain FIFO order — see below).
- **Price-level arrays (buy/sell)** — 32 levels per side. Each level stores the
  order reference number of the FIFO head, the price, and the total share
  count resting at that level.

### Order insertion

1. New order arrives from the parser.
2. Freelist pop → get a free stable array index.
3. Store the order (reference number, price, shares) at that index.
4. Hash the order reference number (Toeplitz, two hash outputs) → insert into
   the cuckoo table at one of the two candidate addresses, recording the
   stable array index and linking it as the new tail at its price level.

### FIFO traversal at a price level

Each price level array stores only the *head* order reference number, not the
full queue. To walk the queue in FIFO order:
1. Hash the current order reference number → look up its cuckoo table entry.
2. The entry gives the stable array index (order details) and the stable array
   index of the *next* order at that price level.
3. Repeat to walk further down the queue.

This keeps the price-level arrays small (just head pointers) while still
supporting full FIFO ordering via the hash-linked chain.

### Deletion

On an Order Delete/Cancel:
1. Hash the order reference number → find its cuckoo table entry.
2. Remove the entry from the cuckoo table and return its stable array index to
   the freelist.
3. Update the price level's head pointer / share total accordingly.

### Price-level window management

The 32 price levels per side act as a bounded sliding window rather than
tracking every possible price. As the best bid/ask moves, the window slides up
or down, evicting the level(s) that fall outside the window and freeing their
associated cuckoo table entries and stable array slots back to the freelist.

## Matching Engine (planned)

Will consume order book state and parsed Add/Cancel/Replace/Execute messages to
reconstruct trade matching, verified against a Python and/or C++ reference model
(reusing the same "RTL vs. independent reference" verification approach used for
the parser).

## Repo layout
```
/rtl        SystemVerilog source code
/sim        cocotb testbench + Python reference decoder
```

## Motivation

Built to explore low-latency market data processing in hardware, where parsing,
book-building, and matching are core problems in FPGA-accelerated trading
infrastructure, and this project is a from-scratch exploration of that pipeline
end to end.
