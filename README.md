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

