#!/usr/bin/env python3
"""
scripts/pne-to-ngdevkit.py — `.PNE` → ngdevkit 入力 converter (= production-grade、 unpack only)

責務 (= ADR-0021 §決定 5 / docs/design/pne_binary_layout.md §6 / §12):

  本 converter は **既存 production pipeline である vromtool.py の前段 layer** と
  位置付ける:

      `.PNE` → [本 converter] → normalized yaml + extracted `.adpcma`
                                              ↓
                              vromtool.py (= ngdevkit native、 完全不変)
                                              ↓
                              VROM + samples.inc

  本 converter の責務:
    - `.PNE` magic / version 検証
    - slot table parse、 各 slot の name / raw data offset / size 抽出
    - raw ADPCM-A binary を slot 名で `{slot_name}.adpcma` file に書き出す
    - `samples-map-adpcma.yaml` を slot 順で生成 (= 先頭に「DO NOT EDIT」 警告 comment)
    - 出力 dir は default `vendor/ngdevkit-examples/00-template/assets/`

  本 converter が責務外とするもの (= scope-out):
    - pack mode (= `.PNE` 生成、 → `scripts/pne-pack-prototype.py` (= bootstrap) or
      WebApp Phase 4)
    - VROM packing / samples.inc 生成 / ADPCM-A address 計算 (= vromtool.py 責務、 不変)
    - ADPCM-B slot (= `samples-map-adpcmb.yaml` は別系統で hand-written retain、
      c1 採用根拠)
    - runtime parser 経路 (= Step 8 候補)
    - 複数 `.PNE` file 対応 (= 別 sprint)

  generated artifact (= 出力 yaml + .adpcma) は **手編集禁止**:
    - source of truth は `.PNE` file
    - 唯一の生成元は本 converter
    - 手編集が必要な変更は `.PNE` 側に施す
    - 出力 yaml 先頭の「DO NOT EDIT」 警告 comment が事故防止用

使用例:
    python3 scripts/pne-to-ngdevkit.py assets/pne/PMDNEO01.PNE
    python3 scripts/pne-to-ngdevkit.py assets/pne/PMDNEO01.PNE --output-dir /tmp/test
    python3 scripts/pne-to-ngdevkit.py assets/pne/PMDNEO01.PNE -v

format 仕様: docs/design/pne_binary_layout.md §3-§5 参照
"""

import argparse
import struct
import sys
from pathlib import Path

EXPECTED_MAGIC = b"PNE\0"
SUPPORTED_VERSION = 0x0001
EXPECTED_SLOT_COUNT = 6
HEADER_SIZE = 16
SLOT_ENTRY_SIZE = 16
DEFAULT_OUTPUT_DIR = Path("vendor/ngdevkit-examples/00-template/assets")


def die(msg: str) -> None:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=".PNE → ngdevkit 入力 (= samples-map-adpcma.yaml + .adpcma) converter (unpack only)"
    )
    parser.add_argument("input", type=Path, help=".PNE file path (= 例: assets/pne/PMDNEO01.PNE)")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"出力 dir (= default: {DEFAULT_OUTPUT_DIR})",
    )
    parser.add_argument("-v", "--verbose", action="store_true", help="詳細 log")
    args = parser.parse_args()

    if not args.input.is_file():
        die(f"cannot read .PNE file: {args.input}: file not found")

    data = args.input.read_bytes()
    fsize = len(data)

    if fsize < HEADER_SIZE:
        die(f"invalid .PNE: file size {fsize} byte < header size {HEADER_SIZE} byte")

    magic, version, slot_count, _reserved = struct.unpack_from("<4sHH8s", data, 0)
    if magic != EXPECTED_MAGIC:
        die(f"invalid magic in {args.input}: expected {EXPECTED_MAGIC!r}, got {magic!r}")
    if version != SUPPORTED_VERSION:
        die(f"unsupported .PNE version: {version} (supported: {SUPPORTED_VERSION})")
    if slot_count != EXPECTED_SLOT_COUNT:
        die(f"slot count must be {EXPECTED_SLOT_COUNT} (got {slot_count})")

    if fsize < HEADER_SIZE + SLOT_ENTRY_SIZE * slot_count:
        die(
            f"invalid .PNE: file size {fsize} byte < header + slot table "
            f"{HEADER_SIZE + SLOT_ENTRY_SIZE * slot_count} byte"
        )

    slots = []
    for i in range(slot_count):
        offset = HEADER_SIZE + SLOT_ENTRY_SIZE * i
        name_bytes, raw_offset, raw_size, start_addr, stop_addr = struct.unpack_from(
            "<8sHHHH", data, offset
        )
        name = name_bytes.rstrip(b"\0").decode("ascii", errors="strict")
        if not name or not name.isascii():
            die(f"invalid slot name {name_bytes!r} at slot {i}")
        if raw_offset + raw_size > fsize:
            die(
                f"corrupted .PNE: slot {i} ('{name}') raw data range "
                f"{raw_offset}+{raw_size} exceeds file size {fsize}"
            )
        slots.append((name, raw_offset, raw_size, start_addr, stop_addr))

    try:
        args.output_dir.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        die(f"cannot write to output dir: {args.output_dir}: {e}")

    yaml_path = args.output_dir / "samples-map-adpcma.yaml"
    yaml_lines = [
        f"# DO NOT EDIT — generated from {args.input.name} by scripts/pne-to-ngdevkit.py",
        f"# source of truth: {args.input}",
        f"# regenerate with: python3 scripts/pne-to-ngdevkit.py {args.input}",
        "",
    ]

    for name, raw_offset, raw_size, _start, _stop in slots:
        adpcma_filename = f"{name}.adpcma"
        adpcma_path = args.output_dir / adpcma_filename
        chunk = data[raw_offset : raw_offset + raw_size]
        adpcma_path.write_bytes(chunk)
        absolute_uri = adpcma_path.resolve()
        yaml_lines.append("- adpcm_a:")
        yaml_lines.append(f"    name: {name}")
        yaml_lines.append(f"    uri: file://{absolute_uri}")
        if args.verbose:
            print(
                f"  [{name:>4}] extracted: {adpcma_path} ({raw_size} byte)",
                file=sys.stderr,
            )

    yaml_path.write_text("\n".join(yaml_lines) + "\n", encoding="utf-8")

    print(f"=== .PNE unpack 完了: {args.input} → {args.output_dir} ===")
    print(f"  slot count: {slot_count}")
    print(f"  generated: {yaml_path}")
    for name, _raw_offset, raw_size, _start, _stop in slots:
        print(f"  generated: {args.output_dir / f'{name}.adpcma'} ({raw_size} byte)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
