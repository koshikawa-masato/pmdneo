#!/usr/bin/env python3
"""
scripts/ppc-to-ngdevkit.py — `.PPC` → ngdevkit 入力 converter (= 軸 G δ 案 C、 vromtool 外側)

責務 (= ADR-0048 §決定 8 案 C「部分 runtime parse」 経路):

  本 converter は **既存 production pipeline である vromtool.py の前段 layer** と
  位置付ける (= 35th session vromtool finding 反映、 vromtool 自体は ngdevkit
  外部 tool で拡張不能のため、 外側 generator として実装):

      `.PPC` → [本 converter] → ADPCM-B blob + directory bin + yaml entry + symbols
                                              ↓
                              vromtool.py (= ngdevkit native、 完全不変)
                                              ↓
                              VROM + samples.inc (= PPC_PCM_BLOB_START_LSB/MSB)

  本 converter の責務:
    - `.PPC` magic / size / format 検証 (= ADR-0048 Annex A-1〜A-4 spec)
    - directory binary (1024 byte = 256 entries × 4 byte) を抽出して
      `ppc_directory.bin` に書き出す (= driver `.incbin` 取り込み用)
    - ADPCM-B raw byte stream (= file offset 0x420 以降) を blob として抽出して
      `ppc_pcm_blob.adpcm_b` に書き出す (= vromtool yaml uri 参照用)
    - blob entry を `samples-map-adpcmb-ppc.yaml` に出力 (= 既存
      `samples-map-adpcmb.yaml` と build hook で merge cp される前提)
    - `ppc_symbols.inc` を emit して `PPC_VROM_BASE_OFFSET_WORD_LSB/MSB` を
      `PPC_PCM_BLOB_START_LSB/MSB` と同値定義 (= vromtool 配置後の
      samples.inc symbol を assembler が解決)
    - `--emit-fixture` mode で minimum `.PPC` fixture を生成 (= test fixture 用)
    - `--self-test` で round-trip parse / emit 整合確認

  本 converter が責務外とするもの (= scope-out):
    - vromtool 拡張 (= 35th session finding、 外部 tool で不可)
    - `.PPC` full binary runtime parser (= ADR-0048 §決定 8 案 B reject)
    - 既存 ADR-0043 ADPCM-B routine 改変 (= production-ready 保護)
    - selection key 以外の MML compiler 拡張 (= 軸 F defer)
    - `.PVI` / `.P86` / `.PPS` / `.PPZ` 別 format 対応 (= Annex A-8)

  format 仕様: docs/adr/0048-... Annex A 参照
"""

import argparse
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

# --- ADR-0048 Annex A spec literal 定数 (= spike script と重複、 self-contained 維持) ---

PPC_SIGNATURE_FULL = b"ADPCM DATA for  PMD ver.4.4-  "
PPC_MAGIC_PREFIX = b"ADPCM "
PPC_HEADER_SIZE = 30
PPC_NEXT_START_OFS = 0x1E
PPC_DIRECTORY_OFS = 0x20
PPC_DIRECTORY_ENTRIES = 256
PPC_DIRECTORY_ENTRY_SIZE = 4
PPC_DIRECTORY_SIZE = PPC_DIRECTORY_ENTRIES * PPC_DIRECTORY_ENTRY_SIZE
PPC_PCM_DATA_OFS = PPC_DIRECTORY_OFS + PPC_DIRECTORY_SIZE
PPC_PVI_MAGIC = b"PVI2"

assert PPC_HEADER_SIZE == 30
assert PPC_DIRECTORY_OFS == 0x20
assert PPC_DIRECTORY_SIZE == 1024
assert PPC_PCM_DATA_OFS == 0x420

DEFAULT_OUTPUT_DIR = Path("build/axis-g")
DEFAULT_YAML_NAME = "samples-map-adpcmb-ppc.yaml"
DEFAULT_DIRECTORY_BIN_NAME = "ppc_directory.bin"
DEFAULT_BLOB_NAME = "ppc_pcm_blob"
DEFAULT_BLOB_FILE_NAME = f"{DEFAULT_BLOB_NAME}.adpcm_b"
DEFAULT_SYMBOLS_INC_NAME = "ppc_symbols.inc"


@dataclass
class DirectoryEntry:
    start: int
    stop: int

    @property
    def is_unused(self) -> bool:
        return self.start == 0 and self.stop == 0

    @property
    def is_valid_range(self) -> bool:
        return self.start <= self.stop


@dataclass
class PpcImage:
    signature: bytes
    next_start: int
    entries: list[DirectoryEntry]
    pcm_data: bytes


class PpcRejectError(ValueError):
    pass


# --- parser (= spike script と重複、 self-contained 維持) ---

def parse_ppc(data: bytes) -> PpcImage:
    if len(data) < PPC_HEADER_SIZE:
        raise PpcRejectError(f"size < {PPC_HEADER_SIZE} (= header signature 未満)")
    if data[:4] == PPC_PVI_MAGIC and len(data) > 10 and data[10] == 2:
        raise PpcRejectError("PVI2 magic detected at offset 0 = scope-out 別 path (= .PVI)")
    if data[:len(PPC_MAGIC_PREFIX)] != PPC_MAGIC_PREFIX:
        raise PpcRejectError(f"magic mismatch (= 先頭 6 byte != {PPC_MAGIC_PREFIX!r})")
    if len(data) < PPC_PCM_DATA_OFS:
        raise PpcRejectError(f"size < {PPC_PCM_DATA_OFS} (= directory + signature 未満)")
    signature = data[:PPC_HEADER_SIZE]
    next_start = struct.unpack("<H", data[PPC_NEXT_START_OFS:PPC_NEXT_START_OFS + 2])[0]
    entries: list[DirectoryEntry] = []
    for i in range(PPC_DIRECTORY_ENTRIES):
        ofs = PPC_DIRECTORY_OFS + i * PPC_DIRECTORY_ENTRY_SIZE
        start, stop = struct.unpack("<HH", data[ofs:ofs + 4])
        entries.append(DirectoryEntry(start, stop))
    pcm_data = data[PPC_PCM_DATA_OFS:]
    return PpcImage(signature=signature, next_start=next_start,
                    entries=entries, pcm_data=pcm_data)


# --- emitter (= spike script と重複、 self-contained 維持) ---

def emit_minimum_fixture(entries: list[DirectoryEntry], pcm_data: bytes,
                         next_start: Optional[int] = None) -> bytes:
    if len(entries) > PPC_DIRECTORY_ENTRIES:
        raise ValueError(f"entries count {len(entries)} > {PPC_DIRECTORY_ENTRIES}")
    if next_start is None:
        last_used = max((e.stop for e in entries if not e.is_unused), default=0)
        next_start = last_used
    buf = bytearray()
    sig = (PPC_SIGNATURE_FULL + b"\x00" * PPC_HEADER_SIZE)[:PPC_HEADER_SIZE]
    buf += sig
    buf += struct.pack("<H", next_start)
    for i in range(PPC_DIRECTORY_ENTRIES):
        if i < len(entries):
            e = entries[i]
        else:
            e = DirectoryEntry(0, 0)
        buf += struct.pack("<HH", e.start, e.stop)
    assert len(buf) == PPC_PCM_DATA_OFS, f"header size {len(buf)} != {PPC_PCM_DATA_OFS}"
    buf += pcm_data
    return bytes(buf)


# --- ngdevkit-bound emit ---

def extract_directory_binary(image: PpcImage) -> bytes:
    buf = bytearray()
    for e in image.entries:
        buf += struct.pack("<HH", e.start, e.stop)
    assert len(buf) == PPC_DIRECTORY_SIZE, f"directory size {len(buf)} != {PPC_DIRECTORY_SIZE}"
    return bytes(buf)


def emit_yaml_entry(name: str, blob_abs_path: Path) -> str:
    return (
        f"# DO NOT EDIT — generated by scripts/ppc-to-ngdevkit.py\n"
        f"# source of truth: caller-supplied .PPC file (= regenerate via converter)\n"
        f"# 軸 G δ 案 C: .PPC ADPCM raw data を 1 blob として vromtool yaml に渡す\n"
        f"#             vromtool 配置後の samples.inc symbol {name.upper()}_START_LSB/MSB\n"
        f"#             を driver runtime が PPC_VROM_BASE_OFFSET_WORD として参照\n"
        f"\n"
        f"- adpcm_b:\n"
        f"    name: {name}\n"
        f"    uri: file://{blob_abs_path}\n"
    )


def emit_symbols_inc(blob_symbol: str) -> str:
    upper = blob_symbol.upper()
    return (
        f";;; DO NOT EDIT — generated by scripts/ppc-to-ngdevkit.py\n"
        f";;; 軸 G δ 案 C: PPC_VROM_BASE_OFFSET_WORD = vromtool 配置済 blob start word\n"
        f";;;             mapping-B 式: v_rom_word = ppc_word + PPC_VROM_BASE_OFFSET_WORD\n"
        f";;;             assembler が samples.inc 解決後に linker level で resolve\n"
        f";;; ref: ADR-0048 §決定 8 (= mapping-B 採用確定式)\n"
        f"\n"
        f"        .equ    PPC_VROM_BASE_OFFSET_WORD_LSB, {upper}_START_LSB\n"
        f"        .equ    PPC_VROM_BASE_OFFSET_WORD_MSB, {upper}_START_MSB\n"
    )


# --- minimum fixture emit (= --emit-fixture mode、 nice-to-have #1 反映) ---

def make_minimum_fixture_bytes(base_offset_pad_words: int = 0x002A) -> bytes:
    """
    minimum .PPC fixture (= 2 entry):
      entry 0: START=0x0400, STOP=0x0480 (= identity 誤実装 trace 用 nonzero word)
      entry 1: START=0x0480, STOP=0x0500

    base_offset_pad_words 引数は無視する (= fixture 自体は .PPC 内 word のみ持つ、
    vromtool 配置時の base offset は runtime resolve)。 引数は documentation 用。

    pcm data = 0x100 byte filler (= deterministic byte pattern、 audio gate は ε scope)。
    """
    entries = [
        DirectoryEntry(start=0x0400, stop=0x0480),
        DirectoryEntry(start=0x0480, stop=0x0500),
    ]
    pcm = bytes((i & 0x7F) for i in range(0x100))
    return emit_minimum_fixture(entries, pcm, next_start=0x0500)


# --- main convert ---

def convert_ppc_to_ngdevkit(input_path: Path, output_dir: Path,
                             yaml_path: Optional[Path] = None,
                             blob_name: str = DEFAULT_BLOB_NAME,
                             verbose: bool = False) -> None:
    data = input_path.read_bytes()
    image = parse_ppc(data)
    output_dir.mkdir(parents=True, exist_ok=True)

    directory_bin_path = output_dir / DEFAULT_DIRECTORY_BIN_NAME
    directory_bin_path.write_bytes(extract_directory_binary(image))
    if verbose:
        print(f"  wrote: {directory_bin_path} ({PPC_DIRECTORY_SIZE} byte)", file=sys.stderr)

    blob_path = output_dir / f"{blob_name}.adpcm_b"
    blob_path.write_bytes(image.pcm_data)
    if verbose:
        print(f"  wrote: {blob_path} ({len(image.pcm_data)} byte)", file=sys.stderr)

    if yaml_path is None:
        yaml_path = output_dir / DEFAULT_YAML_NAME
    yaml_text = emit_yaml_entry(blob_name, blob_path.resolve())
    yaml_path.write_text(yaml_text, encoding="utf-8")
    if verbose:
        print(f"  wrote: {yaml_path}", file=sys.stderr)

    symbols_path = output_dir / DEFAULT_SYMBOLS_INC_NAME
    symbols_path.write_text(emit_symbols_inc(blob_name), encoding="utf-8")
    if verbose:
        print(f"  wrote: {symbols_path}", file=sys.stderr)

    used_entries = sum(1 for e in image.entries if not e.is_unused)
    print(f"=== .PPC → ngdevkit 入力 変換完了: {input_path} → {output_dir} ===")
    print(f"  used entries: {used_entries} / {PPC_DIRECTORY_ENTRIES}")
    print(f"  pcm data size: {len(image.pcm_data)} byte")
    print(f"  generated: {directory_bin_path}")
    print(f"  generated: {blob_path}")
    print(f"  generated: {yaml_path}")
    print(f"  generated: {symbols_path}")


# --- self-test (= nice-to-have #3、 verify script からも呼ばれる) ---

def self_test() -> int:
    fail = 0

    # case 1: minimum fixture round-trip
    raw = make_minimum_fixture_bytes()
    image = parse_ppc(raw)
    if image.entries[0].start != 0x0400 or image.entries[0].stop != 0x0480:
        print(f"[FAIL] entry 0 round-trip: {image.entries[0]}")
        fail += 1
    elif image.entries[1].start != 0x0480 or image.entries[1].stop != 0x0500:
        print(f"[FAIL] entry 1 round-trip: {image.entries[1]}")
        fail += 1
    else:
        print("[PASS] minimum fixture round-trip (entry 0/1)")

    # case 2: directory binary size = 1024 byte (= nice-to-have #2 関連 assert)
    dirbin = extract_directory_binary(image)
    if len(dirbin) != PPC_DIRECTORY_SIZE:
        print(f"[FAIL] directory binary size {len(dirbin)} != {PPC_DIRECTORY_SIZE}")
        fail += 1
    else:
        print(f"[PASS] directory binary size = {PPC_DIRECTORY_SIZE} byte")

    # case 3: nonzero ppc_word (= nice-to-have #1 反映、 identity 誤実装 trace 用)
    if image.entries[0].start == 0 or image.entries[1].start == 0:
        print("[FAIL] fixture entry start word must be nonzero "
              "(= identity 誤実装 trace 用、 nice-to-have #1)")
        fail += 1
    else:
        print(f"[PASS] fixture entries nonzero "
              f"(entry0.start=0x{image.entries[0].start:04X}, "
              f"entry1.start=0x{image.entries[1].start:04X})")

    # case 4: symbols emit literal check
    syms = emit_symbols_inc(DEFAULT_BLOB_NAME)
    expected_lsb_eq = "PPC_VROM_BASE_OFFSET_WORD_LSB, PPC_PCM_BLOB_START_LSB"
    expected_msb_eq = "PPC_VROM_BASE_OFFSET_WORD_MSB, PPC_PCM_BLOB_START_MSB"
    if expected_lsb_eq not in syms or expected_msb_eq not in syms:
        print("[FAIL] symbols.inc missing expected .equ literal")
        fail += 1
    else:
        print("[PASS] symbols.inc PPC_VROM_BASE_OFFSET_WORD_LSB/MSB literal")

    # case 5: emit-fixture → write → re-parse round-trip
    tmp_path = Path("/tmp/ppc-self-test-fixture.PPC")
    tmp_path.write_bytes(raw)
    image2 = parse_ppc(tmp_path.read_bytes())
    if image2.entries[0].start != 0x0400:
        print("[FAIL] file write + re-parse round-trip")
        fail += 1
    else:
        print("[PASS] file write + re-parse round-trip")
    tmp_path.unlink(missing_ok=True)

    total = 5
    print(f"--- self-test summary: {total - fail}/{total} PASS ---")
    return fail


def main() -> int:
    parser = argparse.ArgumentParser(
        description=".PPC → ngdevkit 入力 (= directory bin + adpcm_b blob + yaml + symbols) converter"
    )
    parser.add_argument("--input", type=Path, default=None,
                        help=".PPC file path")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR,
                        help=f"出力 dir (= default: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--yaml-path", type=Path, default=None,
                        help="output yaml path (= default: <output-dir>/{DEFAULT_YAML_NAME})")
    parser.add_argument("--blob-name", default=DEFAULT_BLOB_NAME,
                        help=f"blob symbol name (= default: {DEFAULT_BLOB_NAME})")
    parser.add_argument("--emit-fixture", type=Path, default=None,
                        help="emit minimum .PPC fixture to given path and exit")
    parser.add_argument("--self-test", action="store_true",
                        help="run internal self-test and exit")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    if args.self_test:
        return self_test()

    if args.emit_fixture is not None:
        args.emit_fixture.parent.mkdir(parents=True, exist_ok=True)
        args.emit_fixture.write_bytes(make_minimum_fixture_bytes())
        print(f"=== minimum .PPC fixture emit: {args.emit_fixture} "
              f"({args.emit_fixture.stat().st_size} byte) ===")
        return 0

    if args.input is None:
        print("error: --input <ppc> required (or use --self-test / --emit-fixture)",
              file=sys.stderr)
        return 1
    if not args.input.is_file():
        print(f"error: cannot read .PPC file: {args.input}: file not found",
              file=sys.stderr)
        return 1

    convert_ppc_to_ngdevkit(args.input, args.output_dir,
                             yaml_path=args.yaml_path,
                             blob_name=args.blob_name,
                             verbose=args.verbose)
    return 0


if __name__ == "__main__":
    sys.exit(main())
