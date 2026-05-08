#!/usr/bin/env python3
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: bin2db.py <input> <output> <symbol_name>", file=sys.stderr)
        return 1

    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    symbol = sys.argv[3]

    data = in_path.read_bytes()
    with out_path.open("w", encoding="ascii") as f:
        f.write(f";;; auto-generated from {in_path}\n")
        f.write(f";;; size = {len(data)} byte\n")
        f.write("        .area CODE\n\n")
        f.write(f"{symbol}::\n")
        for i in range(0, len(data), 16):
            chunk = data[i:i + 16]
            f.write("        .db " + ", ".join(f"0x{b:02X}" for b in chunk) + "\n")
        f.write(f"{symbol}_end::\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
