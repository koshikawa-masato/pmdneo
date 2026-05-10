#!/usr/bin/env python3
# scripts/analyze-loop-trace.py
# PMDNEO LOOP nest visualization (= MAME 改造 trace 経由)
#
# 入力: Z80_MEM_TRACE_RANGE=FB00-FB10 で取得した z80-mem-trace.tsv
#   - 0xFB00-0xFB0F = BD part LOOPSTACK (= 4 entry × 4 byte)
#       entry: [0]=ADDR lower, [1]=ADDR upper, [2]=COUNT, [3]=未使用
#   - 0xFB10        = BD part LOOPDEPTH (= 0..4)
#
# 出力: nest stack 状態 timeline (= depth + stack[0..3].COUNT)
#       例: idx=12345 PC=0CA3 depth=2 stack=[3,1,-,-]
#
# 使用例:
#   bash scripts/run-mame.sh --gamerom lastbld2 --loop-viz --wavwrite
#   python3 scripts/analyze-loop-trace.py /tmp/pmdneo-trace/z80-mem-trace.tsv
#
# 既定 part = BD (= part_workarea[11] = 0xFAE0 起点、 LOOPSTACK 0xFB00、 LOOPDEPTH 0xFB10)
# 別 part 観測時: --base <hex> で part 起点 SRAM 指定 (= 0xF820 + index*64 + 32)

import sys
import argparse


def main() -> int:
    parser = argparse.ArgumentParser(
        description="PMDNEO LOOP nest visualization (= z80-mem-trace 経由)"
    )
    parser.add_argument(
        "trace", help="z80-mem-trace.tsv path (= run-mame.sh --loop-viz 出力)"
    )
    parser.add_argument(
        "--base",
        default="FB00",
        help="LOOPSTACK 起点 SRAM addr (hex、 既定 FB00 = BD part)",
    )
    parser.add_argument(
        "--depth-addr",
        default="",
        help="LOOPDEPTH addr (hex、 既定 base+0x10)",
    )
    parser.add_argument(
        "--filter-changes",
        action="store_true",
        help="depth or stack 状態が変化した event のみ表示",
    )
    args = parser.parse_args()

    base = int(args.base, 16)
    depth_addr = int(args.depth_addr, 16) if args.depth_addr else base + 0x10

    # stack[entry][field]、 entry = 0..3、 field 0=ADDRL/1=ADDRH/2=COUNT/3=unused
    stack = [[0, 0, 0, 0] for _ in range(4)]
    depth = 0
    last_state = None

    with open(args.trace, "r") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("\t")
            if len(parts) < 4:
                continue
            try:
                idx = int(parts[0])
                pc = int(parts[1], 16)
                addr = int(parts[2], 16)
                value = int(parts[3], 16)
            except ValueError:
                continue

            # LOOPSTACK 範囲 (= 16 byte = 4 entry × 4 byte)
            if base <= addr < base + 0x10:
                offset = addr - base
                entry = offset // 4
                field = offset % 4
                stack[entry][field] = value
            elif addr == depth_addr:
                depth = value
            else:
                continue

            counts = [stack[i][2] if i < depth else None for i in range(4)]
            state = (depth, tuple(counts))

            if args.filter_changes and state == last_state:
                continue
            last_state = state

            display = ",".join(str(c) if c is not None else "-" for c in counts)
            print(
                f"idx={idx:>8} PC=0x{pc:04X} addr=0x{addr:04X} val=0x{value:02X} "
                f"depth={depth} stack=[{display}]"
            )

    return 0


if __name__ == "__main__":
    sys.exit(main())
