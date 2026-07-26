![Status: WIP](https://img.shields.io/badge/status-WIP-yellow)


# NASDAQ ITCH Hardware Parser & Trading Pipeline

A SystemVerilog implementation of a NASDAQ ITCH 5.0 feed handler, built and verified
against real market data captures. Long-term goal: parser → order book → matching
engine, cross-checked against Python and C++ reference models.

## Status

| Component        | Status | Notes  |
|------------------|--------|--------|
| ITCH Parser      | ✅ Done | Verified against 100k+ real pcap captures |
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

Currently designing the architecture for the limit order book that consumes the
parser's decoded message stream. Planned design:

The 

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
