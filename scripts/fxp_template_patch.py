#!/usr/bin/env python3
"""
PMDNEO ADR-0033 §決定 27 ξ ο spike = Surge XT `.fxp` template bridge (read-only stage).

# ============================================================================
# 9 項目 header (= shell 規律踏襲、 [[interface-fixation-stub-pattern]] 整合)
# ============================================================================
#
# purpose:
#   Surge XT VST2 `.fxp` file の binary structure を parse + report する spike tool。
#   ADR-0033 §決定 27 ξ で scope-in 化された template-based bridge の最小 spike。
#   現段階 (= ο1) は **read-only**、 actual parameter patching は ο4 以降。
#
# ADR mapping:
#   - ADR-0033 §決定 27 (1)  AI 役割 2 軸 = template-based bridge
#   - ADR-0033 §決定 27 (9)  ξ artifact path canonical
#   - ADR-0033 §決定 27 (11) ξ scope-in literal 5 件
#
# input:
#   <input.fxp>  = parse 対象 .fxp file (= Surge XT 出力)
#
# output:
#   stdout に VST2 header (= 28 byte) + FPCh body (= programName + chunkByteSize) literal を report
#   exit code 0 で全 parse 成功、 0 以外 = error
#
# format:
#   VST2 FXP container (= big-endian):
#     [0:4]   chunkMagic   = "CcnK"
#     [4:8]   byteSize     = uint32 BE (= 残部 byte 数)
#     [8:12]  fxMagic      = "FxCk" | "FPCh" | "FxBk" | "FBCh"
#     [12:16] version      = uint32 BE
#     [16:20] idUint       = uint32 BE (= plugin ID)
#     [20:24] fxVersion    = uint32 BE
#     [24:28] count        = uint32 BE
#     [28:..] body (= fxMagic dependent)
#
#   FPCh body (= Surge XT preset 想定):
#     [28:56] programName    = 28 byte ASCII (NUL-padded)
#     [56:60] chunkByteSize  = uint32 BE
#     [60:..] patchChunk     = raw bytes (= Surge XT internal serialization、 XML or binary)
#
# future phase (= ο2 以降):
#   - ο2: 越川氏 hand-on で 2608_template.fxp 作成
#   - ο3: 同一 template から 2 parameter 値で .fxp 保存 → binary diff で byte offset 同定
#   - ο4: parameter allowlist literal patching 実装 (= write mode 追加)
#   - ο5: patch-spec.yaml + template.fxp → drum-specific .fxp bridge invoke
#
# exit codes:
#   0  = parse 成功
#   2  = not-implemented (= write mode 等、 ο4 以降で fill)
#   64 = arg validation error (= input file path 不正 / nonexistent file)
#   65 = data validation error (= chunkMagic ≠ "CcnK" or unknown fxMagic)
#   66 = runtime error (= 読込時 IO error)
#
# examples:
#   $ python3 scripts/fxp_template_patch.py inspect <input.fxp>
#   $ python3 scripts/fxp_template_patch.py inspect assets/drum_samples/synth/templates/2608_template.fxp
#
# TODO (= ο4 以降):
#   [ ] subcommand `patch` 追加 (= parameter-allowlist + patch-spec → patched .fxp 生成)
#   [ ] byte_offset_diff subcommand (= 2 .fxp file の差分 byte offset を report、 binary diff 用)
#   [ ] verify subcommand (= patched .fxp の change_protected_zones 不変性 verify)
#
# ============================================================================
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

# Exit code constants
EXIT_OK = 0
EXIT_NOT_IMPLEMENTED = 2
EXIT_ARG_ERROR = 64
EXIT_DATA_ERROR = 65
EXIT_RUNTIME_ERROR = 66

# VST2 FXP container constants
VST2_HEADER_SIZE = 28
EXPECTED_CHUNK_MAGIC = b"CcnK"
VALID_FX_MAGIC = {b"FxCk", b"FPCh", b"FxBk", b"FBCh"}
FX_MAGIC_DESCRIPTION = {
    b"FxCk": "FXP simple params (= float32 array)",
    b"FPCh": "FXP custom chunk (= Surge XT preset 想定)",
    b"FxBk": "FXB bank (= program list)",
    b"FBCh": "FXB custom chunk",
}
FPCH_PROGRAM_NAME_SIZE = 28


def parse_vst2_header(data: bytes) -> dict:
    """Parse VST2 FXP container 28 byte header (= big-endian)."""
    if len(data) < VST2_HEADER_SIZE:
        raise ValueError(
            f"file too short: {len(data)} byte (= VST2 header {VST2_HEADER_SIZE} byte 不足)"
        )

    chunk_magic = data[0:4]
    if chunk_magic != EXPECTED_CHUNK_MAGIC:
        raise ValueError(
            f"chunkMagic mismatch: got {chunk_magic!r}, expected {EXPECTED_CHUNK_MAGIC!r}"
        )

    byte_size = struct.unpack(">I", data[4:8])[0]
    fx_magic = data[8:12]
    if fx_magic not in VALID_FX_MAGIC:
        raise ValueError(
            f"unknown fxMagic: {fx_magic!r} (= 期待 {sorted(VALID_FX_MAGIC)!r})"
        )

    version = struct.unpack(">I", data[12:16])[0]
    id_uint = struct.unpack(">I", data[16:20])[0]
    fx_version = struct.unpack(">I", data[20:24])[0]
    count = struct.unpack(">I", data[24:28])[0]

    return {
        "chunkMagic": chunk_magic.decode("ascii"),
        "byteSize": byte_size,
        "fxMagic": fx_magic.decode("ascii"),
        "fxMagicDescription": FX_MAGIC_DESCRIPTION[fx_magic],
        "version": version,
        "idUint": id_uint,
        "idString": data[16:20].decode("ascii", errors="replace"),
        "fxVersion": fx_version,
        "count": count,
    }


def parse_fpch_body(data: bytes) -> dict:
    """Parse FPCh body = programName (28B) + chunkByteSize (4B) + patchChunk (raw)."""
    body_start = VST2_HEADER_SIZE
    if len(data) < body_start + FPCH_PROGRAM_NAME_SIZE + 4:
        raise ValueError(
            f"file too short for FPCh body: {len(data)} byte"
        )

    program_name_raw = data[body_start : body_start + FPCH_PROGRAM_NAME_SIZE]
    program_name = program_name_raw.rstrip(b"\x00").decode("ascii", errors="replace")

    chunk_size_offset = body_start + FPCH_PROGRAM_NAME_SIZE
    chunk_byte_size = struct.unpack(
        ">I", data[chunk_size_offset : chunk_size_offset + 4]
    )[0]

    chunk_start = chunk_size_offset + 4
    chunk_end = chunk_start + chunk_byte_size
    if chunk_end > len(data):
        raise ValueError(
            f"chunkByteSize {chunk_byte_size} exceeds file size "
            f"(chunk_start={chunk_start}, file_size={len(data)})"
        )

    patch_chunk = data[chunk_start:chunk_end]

    return {
        "programName": program_name,
        "programNameRawBytes": program_name_raw.hex(),
        "chunkByteSize": chunk_byte_size,
        "chunkStartOffset": chunk_start,
        "chunkEndOffset": chunk_end,
        "patchChunkPreviewHex": patch_chunk[:64].hex() if patch_chunk else "",
        "patchChunkPreviewAscii": patch_chunk[:64].decode("ascii", errors="replace") if patch_chunk else "",
        "totalFileSize": len(data),
        "trailingBytes": len(data) - chunk_end,
    }


def inspect_command(input_path: Path) -> int:
    """Inspect `.fxp` file: print header + body structure."""
    try:
        data = input_path.read_bytes()
    except FileNotFoundError:
        print(f"error: file not found: {input_path}", file=sys.stderr)
        return EXIT_ARG_ERROR
    except OSError as exc:
        print(f"error: cannot read {input_path}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR

    try:
        header = parse_vst2_header(data)
    except ValueError as exc:
        print(f"error: VST2 header parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    print(f"# VST2 FXP container inspect: {input_path}")
    print(f"# file size = {len(data)} byte")
    print()
    print("VST2 header (= 28 byte literal):")
    for key, value in header.items():
        print(f"  {key}: {value}")
    print()

    fx_magic = header["fxMagic"]
    if fx_magic == "FPCh":
        try:
            body = parse_fpch_body(data)
        except ValueError as exc:
            print(f"error: FPCh body parse failed: {exc}", file=sys.stderr)
            return EXIT_DATA_ERROR

        print("FPCh body:")
        for key, value in body.items():
            if key in ("patchChunkPreviewHex", "patchChunkPreviewAscii"):
                print(f"  {key}:")
                print(f"    {value!r}")
            else:
                print(f"  {key}: {value}")
    elif fx_magic == "FxCk":
        print("FxCk body: parse not implemented (= simple float array、 future)")
    else:
        print(f"{fx_magic} body: bank format、 single-preset bridge では使用しない")

    return EXIT_OK


def diff_command(_args: argparse.Namespace) -> int:
    """Diff 2 .fxp files = byte offset of differences (= future ο3 use)."""
    print(
        "[not-implemented] diff subcommand は ο3 (= template + parameter 変更 2 file の "
        "binary diff で byte offset 同定) で実装予定。",
        file=sys.stderr,
    )
    return EXIT_NOT_IMPLEMENTED


def patch_command(_args: argparse.Namespace) -> int:
    """Patch parameter values via allowlist (= future ο4 use)."""
    print(
        "[not-implemented] patch subcommand は ο4 (= parameter-allowlist + patch-spec → "
        "drum-specific .fxp 生成) で実装予定。",
        file=sys.stderr,
    )
    return EXIT_NOT_IMPLEMENTED


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="fxp_template_patch.py",
        description="PMDNEO ADR-0033 §決定 27 ξ ο = Surge XT .fxp template bridge spike",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_inspect = subparsers.add_parser("inspect", help="Inspect VST2 FXP header + body")
    p_inspect.add_argument("input", type=Path, help="input .fxp file path")

    p_diff = subparsers.add_parser(
        "diff",
        help="Diff 2 .fxp files = byte offset of differences (= future ο3)",
    )
    p_diff.add_argument("a", type=Path, help="first .fxp")
    p_diff.add_argument("b", type=Path, help="second .fxp")

    p_patch = subparsers.add_parser(
        "patch",
        help="Patch parameter values via allowlist (= future ο4)",
    )
    p_patch.add_argument("--template", type=Path, required=True)
    p_patch.add_argument("--patch-spec", type=Path, required=True)
    p_patch.add_argument("--allowlist", type=Path, required=True)
    p_patch.add_argument("--output", type=Path, required=True)

    args = parser.parse_args()

    if args.command == "inspect":
        return inspect_command(args.input)
    if args.command == "diff":
        return diff_command(args)
    if args.command == "patch":
        return patch_command(args)

    parser.print_help()
    return EXIT_ARG_ERROR


if __name__ == "__main__":
    sys.exit(main())
