#!/usr/bin/env python3
"""
scripts/m-to-z80-incbin.py

PMDDotNET 出力 .M / .MN を Z80 source の `.incbin` 取り込み用 binary として
配置する小 helper。 bin2db.py 流儀 (= `.db` source 変換) ではなく、 binary を
そのまま .incbin で取り込めるよう copy + size 情報を出力。

ADR-0016 step 3b sub-commit 用。 改造 PMDDotNET 経路の build chain establish。

使い方:
    python3 m-to-z80-incbin.py <input.M> <output.m> [--label LABEL]

引数:
    input.M     PMDDotNET dotnet PMDDotNETConsole の出力 (.M or .MN)
    output.m    .incbin 取り込み用 binary 配置先 (= 00-template 配下)
    --label     emit する label 名 (default = "pmddotnet_song")

出力 (stdout):
    label name + binary size を 1 行で表示 (= build-poc.sh が parse 可能)
"""

import argparse
import shutil
import sys
from pathlib import Path


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input", type=Path, help="PMDDotNET .M / .MN file")
    p.add_argument("output", type=Path, help=".incbin 取り込み用 binary 配置先")
    p.add_argument("--label", default="pmddotnet_song",
                   help="emit する Z80 label 名 (default: pmddotnet_song)")
    args = p.parse_args()

    if not args.input.exists():
        print(f"ERROR: input file not found: {args.input}", file=sys.stderr)
        return 2
    if not args.input.is_file():
        print(f"ERROR: input is not a regular file: {args.input}", file=sys.stderr)
        return 2

    args.output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(args.input, args.output)

    size = args.output.stat().st_size
    # ADR-0016 §4-2-1: .M = m_start byte 0、 .MN なら bit 2 = 1 (= 0x04)
    with open(args.output, "rb") as f:
        m_start = f.read(1)[0] if size > 0 else None

    print(f"label={args.label} size={size} m_start=0x{m_start:02x}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
