#!/usr/bin/env python3
"""
scripts/pne-pack-prototype.py — `.PNE` 初期 asset bootstrap 専用 prototype pack tool

注意 (= ADR-0021 / docs/design/pne_binary_layout.md §6 / 8th session β-1 user 指示):

  bootstrap only / production packer ではない。

  本 tool の責務:
    - 既存 `assets/sounds/adpcma/2608_*.adpcma` 等の ADPCM-A binary 6 件を読み、
      docs/design/pne_binary_layout.md §3-§5 に従って `.PNE` binary を組み立てる
    - β-1 round-trip test の入力 `.PNE` 生成にも使用

  本 tool が責務外とするもの:
    - WAV → ADPCM-A 変換 (= WebApp Phase 4 領域)
    - production-grade pack tool (= ADR-0021 §scope-out、 Phase 4)
    - format version up / slot 数拡張 (= 別 sprint)
    - 複数 `.PNE` file 同時生成 (= 別 sprint)

  PMDNEO01.PNE は β-1 段階の **canonical test asset** として扱うが、 将来
  production asset format の唯一例とは限らない。 後続 sprint で別 `.PNE` を生成
  する場合は、 本 tool ではなく WebApp 経由 (= Phase 4) または別 production tool
  で行う想定。

使用例:
    python3 scripts/pne-pack-prototype.py \\
        --output assets/pne/PMDNEO01.PNE \\
        --slot bd:assets/sounds/adpcma/2608_BD.adpcma \\
        --slot sd:assets/sounds/adpcma/2608_SD.adpcma \\
        --slot hh:assets/sounds/adpcma/2608_HH.adpcma \\
        --slot rim:assets/sounds/adpcma/2608_RIM.adpcma \\
        --slot tom:assets/sounds/adpcma/2608_TOM.adpcma \\
        --slot top:assets/sounds/adpcma/2608_TOP.adpcma

format 仕様 (= docs/design/pne_binary_layout.md §3-§5):
    header (16 byte):
        0..3   "PNE\\0"
        4..5   format version (LE u16、 0x0001)
        6..7   slot count (LE u16、 初期 6 固定)
        8..15  予約 (= 0)
    slot table (16 byte × slot count):
        +0..7   sample name (ASCII NUL terminated、 8 byte 固定)
        +8..9   raw data offset (LE u16、 .PNE 先頭からの byte offset)
        +10..11 raw data size (LE u16、 byte 数)
        +12..13 ADPCM-A start_addr (LE u16、 256 byte 単位)
        +14..15 ADPCM-A stop_addr (LE u16、 256 byte 単位)
    raw data:
        256 byte alignment、 slot 順に連続配置
"""

import argparse
import struct
import sys
from pathlib import Path

MAGIC = b"PNE\0"
FORMAT_VERSION = 0x0001
HEADER_SIZE = 16
SLOT_ENTRY_SIZE = 16
RAW_DATA_ALIGNMENT = 256


def align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) & ~(alignment - 1)


def parse_slot_arg(arg: str) -> tuple[str, Path]:
    if ":" not in arg:
        raise argparse.ArgumentTypeError(
            f"--slot must be 'name:path' (got '{arg}')"
        )
    name, path = arg.split(":", 1)
    name = name.strip()
    if not name or not name.isascii() or len(name.encode("ascii")) > 7:
        raise argparse.ArgumentTypeError(
            f"slot name '{name}' must be ASCII and <= 7 byte (NUL terminator 込で 8 byte)"
        )
    return name, Path(path)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=".PNE prototype pack tool (= bootstrap only、 production packer ではない)"
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="出力 .PNE file path (= 例: assets/pne/PMDNEO01.PNE)",
    )
    parser.add_argument(
        "--slot",
        action="append",
        type=parse_slot_arg,
        required=True,
        help="slot 定義 (= 'name:path' 形式、 複数指定可、 slot 順 = ADPCM-A chip ch L=0..Q=5)",
    )
    args = parser.parse_args()

    slots = args.slot
    if len(slots) != 6:
        print(
            f"error: slot count must be 6 (got {len(slots)}). β-1 では 6 slot 固定。",
            file=sys.stderr,
        )
        return 1

    for name, path in slots:
        if not path.is_file():
            print(f"error: slot '{name}' source file not found: {path}", file=sys.stderr)
            return 1

    raw_data_start = align_up(HEADER_SIZE + SLOT_ENTRY_SIZE * len(slots), RAW_DATA_ALIGNMENT)

    slot_entries = []
    raw_data_chunks = []
    current_offset = raw_data_start
    current_addr_block = 0

    for name, path in slots:
        data = path.read_bytes()
        size = len(data)
        if size % RAW_DATA_ALIGNMENT != 0:
            print(
                f"warning: slot '{name}' size {size} byte is not multiple of "
                f"{RAW_DATA_ALIGNMENT} byte (ADPCM-A address unit)",
                file=sys.stderr,
            )
        if size == 0:
            print(f"error: slot '{name}' has zero size", file=sys.stderr)
            return 1

        block_count = (size + RAW_DATA_ALIGNMENT - 1) // RAW_DATA_ALIGNMENT
        start_addr = current_addr_block
        stop_addr = current_addr_block + block_count - 1

        name_bytes = name.encode("ascii").ljust(8, b"\0")
        slot_entries.append(
            struct.pack(
                "<8sHHHH",
                name_bytes,
                current_offset,
                size,
                start_addr,
                stop_addr,
            )
        )

        raw_data_chunks.append(data)
        current_offset += size
        current_addr_block += block_count

    header = struct.pack(
        "<4sHH8s",
        MAGIC,
        FORMAT_VERSION,
        len(slots),
        b"\0" * 8,
    )

    args.output.parent.mkdir(parents=True, exist_ok=True)

    with args.output.open("wb") as f:
        f.write(header)
        for entry in slot_entries:
            f.write(entry)
        padding_size = raw_data_start - (HEADER_SIZE + SLOT_ENTRY_SIZE * len(slots))
        if padding_size > 0:
            f.write(b"\0" * padding_size)
        for chunk in raw_data_chunks:
            f.write(chunk)

    total_size = args.output.stat().st_size
    print(f"=== .PNE pack 完了: {args.output} ({total_size} byte) ===")
    print(f"  slot count: {len(slots)}")
    for (name, path), entry in zip(slots, slot_entries):
        _, raw_offset, raw_size, start_addr, stop_addr = struct.unpack("<8sHHHH", entry)
        print(
            f"  [{name:>4}] offset={raw_offset:>5} size={raw_size:>5} "
            f"start_addr=0x{start_addr:02x} stop_addr=0x{stop_addr:02x} ({path})"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
