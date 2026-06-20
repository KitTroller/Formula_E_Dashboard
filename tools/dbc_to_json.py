#!/usr/bin/env python3
"""Convert a CAN .dbc into the compact JSON the dashboard's CAN sniffer reads.

Only the bits the sniffer needs are kept: each message's id/name/dlc and, per
signal, the bit layout + scaling. CAN_MCU.dbc is all little-endian (@1), 11-bit
ids, so we don't bother with Motorola bit ordering here.

Usage:  python3 tools/dbc_to_json.py "Sources for CAN frame extraction/DBC_files/CAN_MCU.dbc" can_dbc.json
Output: messages sorted by id ascending (smaller id = higher priority/top of list).
"""
import json
import re
import sys

BO_RE = re.compile(r"^BO_\s+(\d+)\s+(\w+)\s*:\s*(\d+)\s+(\S+)")
# SG_ Name [mux] : start|len@order sign (factor,offset) [min|max] "unit" receivers
# The optional (?:\s+[mM]\d*) captures multiplexed signals like "SG_ Foo m2 : ...".
SG_RE = re.compile(
    r'^\s*SG_\s+(\w+)(?:\s+[mM]\d*)?\s*:\s*(\d+)\|(\d+)@([01])([+-])\s*'
    r'\(([^,]+),([^)]+)\)\s*\[([^|]*)\|([^\]]*)\]\s*"([^"]*)"?'
    # closing quote optional: a few rows in CAN_MCU.dbc wrap the unit oddly (e.g. "°C)
)


def parse(dbc_path):
    messages = []
    current = None
    # DBC here is ISO-8859 / latin-1 with CRLF line endings
    with open(dbc_path, encoding="latin-1") as fh:
        for line in fh:
            line = line.rstrip("\r\n")
            m = BO_RE.match(line)
            if m:
                current = {
                    "id": int(m.group(1)),
                    "name": m.group(2),
                    "dlc": int(m.group(3)),
                    "tx": m.group(4),
                    "signals": [],
                }
                messages.append(current)
                continue
            s = SG_RE.match(line)
            if s and current is not None:
                current["signals"].append({
                    "name": s.group(1),
                    "start": int(s.group(2)),
                    "len": int(s.group(3)),
                    "le": s.group(4) == "1",          # @1 = little-endian (Intel)
                    "signed": s.group(5) == "-",
                    "factor": float(s.group(6)),
                    "offset": float(s.group(7)),
                    "min": float(s.group(8)) if s.group(8).strip() else 0.0,
                    "max": float(s.group(9)) if s.group(9).strip() else 0.0,
                    "unit": s.group(10),
                })
    messages.sort(key=lambda mm: mm["id"])
    return messages


def main():
    dbc = sys.argv[1] if len(sys.argv) > 1 else \
        "Sources for CAN frame extraction/DBC_files/CAN_MCU.dbc"
    out = sys.argv[2] if len(sys.argv) > 2 else "can_dbc.json"
    msgs = parse(dbc)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump({"messages": msgs}, fh, ensure_ascii=False, indent=1)
    sigs = sum(len(m["signals"]) for m in msgs)
    print(f"Wrote {out}: {len(msgs)} messages, {sigs} signals")


if __name__ == "__main__":
    main()
