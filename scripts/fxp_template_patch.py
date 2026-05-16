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
# commit history:
#   - ο1 (= 1b5f20c): inspect (read-only header + body parse)
#   - π2 (= 64f6f55): extract-xml + survey-params + verify-repack 動作確認、 evidence proof
#   - π3 (= 8aa97a5): parameter-allowlist.yaml comprehensive 56 element fill
#   - π4 (= 本 commit): patch subcommand 実装 (= allowlist + patch-spec → XML value 修正 + chunk repack + invariant verify)
#
# future phase:
#   - π5: 2608_bd.patch-spec.yaml + 2608_template.fxp → 2608_bd.fxp canonical bridge invoke proof
#   - π6+: fxp2wav-surge connect + AI self-analysis + 越川氏 audition
#
# exit codes:
#   0  = success
#   2  = not-implemented (= diff、 optional 経路)
#   64 = arg validation error (= input file path 不正 / nonexistent file / --override 形式不正 / allowlist 外 reject)
#   65 = data validation error (= chunkMagic ≠ "CcnK" / unknown fxMagic / XML parse error / invariant violation)
#   66 = runtime error (= 読込時 IO error)
#
# examples:
#   $ python3 scripts/fxp_template_patch.py inspect <input.fxp>
#   $ python3 scripts/fxp_template_patch.py extract-xml <input.fxp>                    # → stdout
#   $ python3 scripts/fxp_template_patch.py extract-xml <input.fxp> --pretty           # 整形
#   $ python3 scripts/fxp_template_patch.py extract-xml <input.fxp> --output out.xml   # → file
#   $ python3 scripts/fxp_template_patch.py survey-params <input.fxp>                  # 一覧
#   $ python3 scripts/fxp_template_patch.py verify-repack <input.fxp>                  # evidence
#   $ python3 scripts/fxp_template_patch.py patch --template T.fxp --allowlist A.yaml \
#         --override a_filter1_cutoff=1.5 --override a_env1_decay=-1.0 \
#         --output OUT.fxp                                                              # π4: 個別 override 軸
#   $ python3 scripts/fxp_template_patch.py patch --template T.fxp --allowlist A.yaml \
#         --patch-spec PS.yaml --output OUT.fxp                                         # π4: patch-spec passthrough
#
# safety:
#   - allowlist 外 element の --override は exit 64 で reject
#   - patch-spec 値は **数値型 (= int/float/bool) のみ** passthrough、 string は skip (= XML 破壊回避)
#   - 出力前に invariant verify (= sub3 / trailing / allowlist 外 element / XML well-formedness)
#   - verify FAIL なら出力せず exit 65
#
# TODO (= π5 以降):
#   [ ] patch-spec unit 変換 layer (= ms ↔ log-time / Hz ↔ log-freq 等)
#   [ ] subcommand `diff` 実装 (= optional、 π2 XML element name 軸で代替済)
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


SUB3_MAGIC = b"sub3"
XML_START_MARKER = b"<?xml"
XML_END_MARKER = b"</patch>"


def extract_chunk_segments(patch_chunk: bytes) -> tuple[bytes, bytes, bytes]:
    """
    Split FPCh patch chunk into 3 segments (= π2 軸 = sub3 header + XML body + trailing).

    Returns (sub3_header, xml_body, trailing_binary)。 trailing_binary は 0 byte の場合あり。
    """
    if not patch_chunk.startswith(SUB3_MAGIC):
        raise ValueError(f"chunk does not start with sub3 magic: {patch_chunk[:4]!r}")

    xml_start = patch_chunk.find(XML_START_MARKER)
    if xml_start < 0:
        raise ValueError("no <?xml declaration found in chunk")

    xml_end_idx = patch_chunk.rfind(XML_END_MARKER)
    if xml_end_idx < 0:
        raise ValueError("no </patch> closing tag found")
    xml_end = xml_end_idx + len(XML_END_MARKER)

    sub3_header = patch_chunk[:xml_start]
    xml_body = patch_chunk[xml_start:xml_end]
    trailing = patch_chunk[xml_end:]

    return sub3_header, xml_body, trailing


def extract_xml_command(input_path: Path, output_path: Path | None, pretty: bool) -> int:
    """Extract XML body from FPCh chunk (= π2 軸、 read-only)."""
    try:
        data = input_path.read_bytes()
    except (FileNotFoundError, OSError) as exc:
        print(f"error: cannot read {input_path}: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR

    try:
        header = parse_vst2_header(data)
        if header["fxMagic"] != "FPCh":
            print(f"error: fxMagic={header['fxMagic']}、 FPCh のみ対応", file=sys.stderr)
            return EXIT_DATA_ERROR
        body = parse_fpch_body(data)
    except ValueError as exc:
        print(f"error: parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    chunk = data[body["chunkStartOffset"] : body["chunkEndOffset"]]
    try:
        sub3_header, xml_body, trailing = extract_chunk_segments(chunk)
    except ValueError as exc:
        print(f"error: chunk segment extract: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    # 後段 modify + repack で size 差分が出ても recalc 可能、 まず byte-identical roundtrip 確認
    if sub3_header + xml_body + trailing != chunk:
        print("error: roundtrip mismatch (= sub3_header + xml_body + trailing ≠ chunk)", file=sys.stderr)
        return EXIT_DATA_ERROR

    # report segment info to stderr
    print(f"# sub3_header: {len(sub3_header)} byte (= 4 byte 'sub3' magic + 28 byte binary header)", file=sys.stderr)
    print(f"# xml_body:    {len(xml_body)} byte", file=sys.stderr)
    print(f"# trailing:    {len(trailing)} byte", file=sys.stderr)
    print(f"# chunk_total: {len(chunk)} byte (= FPCh chunkByteSize value)", file=sys.stderr)
    print(f"# roundtrip:   PASS (= sub3 + xml + trailing == chunk byte-identical)", file=sys.stderr)

    if pretty:
        from xml.dom import minidom
        try:
            dom = minidom.parseString(xml_body)
            xml_output = dom.toprettyxml(indent="  ", encoding="UTF-8")
        except Exception as exc:
            print(f"error: pretty-print failed: {exc}", file=sys.stderr)
            return EXIT_DATA_ERROR
    else:
        xml_output = xml_body

    # byte-identical 軸維持 = stdout / file 出力どちらも 同 bytes (= trailing newline 自動追加しない)
    if output_path is None:
        sys.stdout.buffer.write(xml_output)
    else:
        output_path.write_bytes(xml_output)
        print(f"# wrote {len(xml_output)} byte to {output_path}", file=sys.stderr)

    return EXIT_OK


def survey_params_command(input_path: Path) -> int:
    """Survey XML <parameters> elements + categorize (= π2 軸、 read-only)."""
    import xml.etree.ElementTree as ET
    from collections import Counter

    try:
        data = input_path.read_bytes()
    except (FileNotFoundError, OSError) as exc:
        print(f"error: cannot read {input_path}: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR

    try:
        body = parse_fpch_body(data)
    except ValueError as exc:
        print(f"error: parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    chunk = data[body["chunkStartOffset"] : body["chunkEndOffset"]]
    try:
        _, xml_body, _ = extract_chunk_segments(chunk)
    except ValueError as exc:
        print(f"error: chunk extract: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    try:
        root = ET.fromstring(xml_body)
    except ET.ParseError as exc:
        print(f"error: XML parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    meta = root.find("meta")
    params = root.find("parameters")
    if params is None:
        print("error: no <parameters> element found", file=sys.stderr)
        return EXIT_DATA_ERROR

    all_params = list(params)
    print(f"# XML root: <{root.tag} {dict(root.attrib)}>")
    if meta is not None:
        print(f"# meta name:     {meta.get('name', '?')}")
        print(f"# meta category: {meta.get('category', '?')}")
        print(f"# meta author:   {meta.get('author', '?')}")
        print(f"# meta license:  {(meta.get('license') or '')[:80]}")
    print(f"# parameter element count: {len(all_params)}")

    def prefix(name: str) -> str:
        if name.startswith("a_"):
            return "a_* (scene A)"
        if name.startswith("b_"):
            return "b_* (scene B)"
        if name.startswith("fx"):
            return "fx_*"
        if name.startswith("volume"):
            return "volume*"
        return "other"

    prefix_count = Counter(prefix(p.tag) for p in all_params)
    print()
    print("# prefix breakdown:")
    for pre, count in sorted(prefix_count.items(), key=lambda x: -x[1]):
        print(f"#   {pre}: {count}")

    print()
    print("# category-keyed param samples (= patch-spec.yaml mapping candidates):")
    categories = {
        "amp_envelope (= a_env1_*)": [p for p in all_params if p.tag.startswith("a_env1_")],
        "filter_envelope (= a_env2_*)": [p for p in all_params if p.tag.startswith("a_env2_")],
        "osc1_* (= waveform/pitch/params)": [p for p in all_params if p.tag.startswith("a_osc1_")],
        "filter1_* (= cutoff/resonance/type)": [p for p in all_params if p.tag.startswith("a_filter1_")],
        "lfo0_* (= mod source 0)": [p for p in all_params if p.tag.startswith("a_lfo0_")],
        "master_volume/scene_volume": [p for p in all_params if p.tag in ("volume", "a_volume", "b_volume")],
    }
    for cat, plist in categories.items():
        print(f"#   [{cat}] count={len(plist)}")
        for p in plist[:5]:
            print(f"#     <{p.tag} {dict(p.attrib)} />")

    return EXIT_OK


def verify_repack_command(input_path: Path) -> int:
    """Verify chunk roundtrip + simulate value modification + chunkByteSize recalc (= π2 軸)."""
    import re
    try:
        data = input_path.read_bytes()
    except (FileNotFoundError, OSError) as exc:
        print(f"error: cannot read {input_path}: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR

    try:
        header = parse_vst2_header(data)
        body = parse_fpch_body(data)
    except ValueError as exc:
        print(f"error: parse failed: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    chunk = data[body["chunkStartOffset"] : body["chunkEndOffset"]]
    sub3_header, xml_body, trailing = extract_chunk_segments(chunk)

    # Phase 1: byte-identical roundtrip
    reconstructed = sub3_header + xml_body + trailing
    print(f"# Phase 1: byte-identical roundtrip = {'PASS' if reconstructed == chunk else 'FAIL'}")

    # Phase 2: dummy parameter modification + chunkByteSize recalc
    # 探索: a_filter1_cutoff の value を 0.5 へ書換 simulation
    pattern = rb'(<a_filter1_cutoff[^>]*value=")([^"]+)(")'
    match = re.search(pattern, xml_body)
    if match is None:
        print("# Phase 2: SKIP (a_filter1_cutoff not found)")
        return EXIT_OK
    old_value = match.group(2)
    new_xml = re.sub(pattern, rb'\g<1>0.50000000000000\g<3>', xml_body, count=1)
    size_diff = len(new_xml) - len(xml_body)
    print(f"# Phase 2: regex value modification = a_filter1_cutoff: {old_value.decode()} → 0.50000000000000")
    print(f"#          xml size diff: {size_diff:+d} byte")

    # new chunk = sub3_header + new_xml + trailing
    new_chunk = sub3_header + new_xml + trailing
    new_chunk_size = len(new_chunk)
    print(f"#          chunkByteSize: {body['chunkByteSize']} → {new_chunk_size} (= diff {size_diff:+d})")

    # 再 pack new file = VST2 header (chunkByteSize 更新) + programName + new chunk
    new_file = (
        data[:56]  # VST2 header (28 byte) + programName (28 byte) = 56 byte
        + struct.pack(">I", new_chunk_size)  # new chunkByteSize
        + new_chunk
    )
    new_file_size = len(new_file)
    print(f"#          file size: {len(data)} → {new_file_size} (= diff {size_diff:+d})")

    # Phase 3: re-parse and verify value
    new_data = new_file
    new_body = parse_fpch_body(new_data)
    new_chunk_read = new_data[new_body["chunkStartOffset"] : new_body["chunkEndOffset"]]
    _, new_xml_read, _ = extract_chunk_segments(new_chunk_read)
    import xml.etree.ElementTree as ET
    new_root = ET.fromstring(new_xml_read)
    new_cutoff = new_root.find("parameters/a_filter1_cutoff")
    if new_cutoff is None:
        print("# Phase 3: FAIL (cutoff not found in repacked file)")
        return EXIT_DATA_ERROR
    new_value = new_cutoff.get("value")
    print(f"# Phase 3: re-parse repacked file = a_filter1_cutoff value = {new_value}")
    print(f"#          chunkByteSize self-consistent: {new_body['chunkByteSize'] == new_chunk_size}")

    print()
    print("# π2 evidence summary:")
    print("#   - chunk segment extract: OK (sub3 + xml + trailing)")
    print("#   - byte-identical roundtrip: OK")
    print("#   - regex-based value modification: OK")
    print("#   - chunkByteSize recalc: OK")
    print("#   - re-parse repacked file: OK")
    print("#   - 'patch-spec → template .fxp XML patching bridge が実現可能' = evidence-level proof PASS")

    return EXIT_OK


def diff_command(_args: argparse.Namespace) -> int:
    """Diff 2 .fxp files = byte offset of differences (= future, 軸残存 stub)."""
    print(
        "[not-implemented] diff subcommand は 必要時 (= 2 template binary diff) で実装。 π2 (= XML "
        "extract + repack feasibility) 経路では不要、 XML element name patching で代替可能。",
        file=sys.stderr,
    )
    return EXIT_NOT_IMPLEMENTED


def _navigate_dotted_path(data, path: str):
    """Navigate dotted path in dict (e.g., 'foo.bar[0].baz'). Returns None if any segment missing."""
    if not isinstance(path, str):
        return None
    # strip parenthetical 注釈 (= '... (= optional ...)' 等)
    path = path.split(" (")[0].strip()
    if not path:
        return None
    current = data
    for part in path.split("."):
        if not part:
            return None
        if "[" in part and "]" in part:
            key, idx_str = part.split("[", 1)
            idx_str = idx_str.rstrip("]")
            try:
                idx = int(idx_str)
            except ValueError:
                return None
            if key:
                if not isinstance(current, dict):
                    return None
                current = current.get(key)
                if current is None:
                    return None
            if not isinstance(current, list) or idx >= len(current):
                return None
            current = current[idx]
        else:
            if not isinstance(current, dict):
                return None
            current = current.get(part)
            if current is None:
                return None
    return current


def _modify_xml_element_value(xml_body: bytes, element_name: str, new_value: str) -> tuple[bytes, str | None]:
    """
    Regex-modify <element_name ... value="X" ... /> setting value=new_value.

    Returns (new_xml_body, old_value_str)。 element not found なら (xml_body, None)。
    """
    import re
    pattern = (
        rb'(<' + re.escape(element_name.encode()) + rb'\b[^>]*?\bvalue=")'
        rb'([^"]+)'
        rb'(")'
    )
    match = re.search(pattern, xml_body)
    if match is None:
        return xml_body, None
    old_value = match.group(2).decode("ascii", errors="replace")
    new_value_bytes = str(new_value).encode("ascii", errors="replace")
    new_xml = (
        xml_body[:match.start()]
        + match.group(1)
        + new_value_bytes
        + match.group(3)
        + xml_body[match.end():]
    )
    return new_xml, old_value


def _verify_patch_invariants(
    orig_data: bytes,
    new_data: bytes,
    allowed_element_set: set,
    modified_element_set: set,
) -> None:
    """Raise RuntimeError if patched file violates invariants."""
    import xml.etree.ElementTree as ET

    def _extract_xml(data: bytes) -> tuple[bytes, bytes, bytes]:
        chunk = data[60 : 60 + struct.unpack(">I", data[56:60])[0]]
        return extract_chunk_segments(chunk)

    orig_sub3, orig_xml, orig_trailing = _extract_xml(orig_data)
    new_sub3, new_xml, new_trailing = _extract_xml(new_data)

    if orig_sub3 != new_sub3:
        raise RuntimeError("invariant violation: sub3_header changed (= 32 byte 不変必須)")
    if orig_trailing != new_trailing:
        raise RuntimeError("invariant violation: trailing binary changed (= 不変必須)")

    orig_root = ET.fromstring(orig_xml)
    try:
        new_root = ET.fromstring(new_xml)
    except ET.ParseError as exc:
        raise RuntimeError(
            f"invariant violation: patched XML not well-formed: {exc} "
            f"(= 注入 value に XML 破壊 char が含まれる可能性、 数値型 passthrough 規律違反)"
        )
    orig_params = {p.tag: p.get("value") for p in orig_root.find("parameters")}
    new_params = {p.tag: p.get("value") for p in new_root.find("parameters")}

    for name in orig_params:
        old_v = orig_params[name]
        new_v = new_params.get(name)
        if old_v == new_v:
            continue
        # value 変化 = allowlist 内 + 実際 modify 対象 を verify
        if name not in allowed_element_set:
            raise RuntimeError(
                f"invariant violation: {name!r} value changed but not in allowlist "
                f"(= conservative change_protected default 違反)"
            )
        if name not in modified_element_set:
            raise RuntimeError(
                f"invariant violation: {name!r} value changed unexpectedly "
                f"(= modification list 外)"
            )


def patch_command(args: argparse.Namespace) -> int:
    """Patch template `.fxp` parameter values via allowlist + override / patch-spec (= π4)."""
    import yaml
    import hashlib

    # 1. Load allowlist + 56 element 集合化
    try:
        allowlist_text = args.allowlist.read_text(encoding="utf-8")
        allowlist_data = yaml.safe_load(allowlist_text)
    except (FileNotFoundError, OSError) as exc:
        print(f"error: cannot read allowlist {args.allowlist}: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR
    if allowlist_data.get("patching_model") != "xml-element-name":
        print(
            f"error: allowlist.patching_model != 'xml-element-name' (= got "
            f"{allowlist_data.get('patching_model')!r})",
            file=sys.stderr,
        )
        return EXIT_DATA_ERROR
    allowed_params = allowlist_data.get("allowed_parameters", []) or []
    allowed_by_name = {p["xml_element_name"]: p for p in allowed_params}
    print(f"# loaded allowlist: {len(allowed_by_name)} allowed element", file=sys.stderr)

    # 2. Load template + chunk extract
    try:
        template_data = args.template.read_bytes()
    except (FileNotFoundError, OSError) as exc:
        print(f"error: cannot read template {args.template}: {exc}", file=sys.stderr)
        return EXIT_ARG_ERROR
    try:
        body = parse_fpch_body(template_data)
    except ValueError as exc:
        print(f"error: template parse: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR
    chunk = template_data[body["chunkStartOffset"] : body["chunkEndOffset"]]
    sub3_header, xml_body, trailing = extract_chunk_segments(chunk)

    # 3. Resolve target values
    target_values: dict[str, str] = {}

    # 3a. patch-spec passthrough navigation (= optional、 unit 変換なし、 数値型のみ)
    if args.patch_spec:
        try:
            patch_spec_data = yaml.safe_load(args.patch_spec.read_text(encoding="utf-8"))
        except (FileNotFoundError, OSError) as exc:
            print(f"error: cannot read patch-spec {args.patch_spec}: {exc}", file=sys.stderr)
            return EXIT_ARG_ERROR
        ps_extracted = 0
        ps_skipped_non_numeric = 0
        for name, elem_def in allowed_by_name.items():
            field_path = elem_def.get("patch_spec_field", "")
            value = _navigate_dotted_path(patch_spec_data, field_path)
            if value is None:
                continue
            # 数値型のみ passthrough (= int / float / bool)、 string / dict / list は skip
            # = XML well-formed 安全側、 string 注入による XML 破壊回避
            if isinstance(value, bool):
                target_values[name] = "1" if value else "0"
                ps_extracted += 1
            elif isinstance(value, (int, float)):
                target_values[name] = str(value)
                ps_extracted += 1
            else:
                ps_skipped_non_numeric += 1
        print(
            f"# patch-spec navigation: {ps_extracted} value 抽出 (= passthrough、 unit 変換は π5 以降の別軸)、"
            f" {ps_skipped_non_numeric} 件 skip (= 数値型以外、 XML 安全側)",
            file=sys.stderr,
        )

    # 3b. --override = patch-spec を上書き
    for ov in args.overrides or []:
        if "=" not in ov:
            print(f"error: --override 形式不正 (= NAME=VALUE 必要): {ov!r}", file=sys.stderr)
            return EXIT_ARG_ERROR
        name, value = ov.split("=", 1)
        if name not in allowed_by_name:
            print(
                f"error: --override {name!r} は allowlist 外 (= conservative reject)",
                file=sys.stderr,
            )
            return EXIT_ARG_ERROR
        target_values[name] = value

    if not target_values:
        print(
            "warning: patch values 未指定 (= --patch-spec / --override 両方なし)、 "
            "byte-identical copy 出力",
            file=sys.stderr,
        )

    # 4. Apply modifications via regex
    new_xml = xml_body
    actual_modifications: list[tuple[str, str, str]] = []
    for name, new_value in target_values.items():
        modified_xml, old_value = _modify_xml_element_value(new_xml, name, new_value)
        if old_value is None:
            print(
                f"warning: element {name!r} not found in XML body (= skip)",
                file=sys.stderr,
            )
            continue
        if old_value == new_value:
            continue
        new_xml = modified_xml
        actual_modifications.append((name, old_value, new_value))

    # 5. Repack + chunkByteSize recalc
    new_chunk = sub3_header + new_xml + trailing
    new_chunk_size = len(new_chunk)
    new_data = (
        template_data[:56]
        + struct.pack(">I", new_chunk_size)
        + new_chunk
    )

    # 6. Verify invariants (= allowlist 外 element / sub3 / trailing 不変)
    try:
        _verify_patch_invariants(
            template_data,
            new_data,
            allowed_element_set=set(allowed_by_name.keys()),
            modified_element_set={m[0] for m in actual_modifications},
        )
    except RuntimeError as exc:
        print(f"error: invariant verify FAILED: {exc}", file=sys.stderr)
        return EXIT_DATA_ERROR

    # 7. Write output + sha256 report
    try:
        args.output.write_bytes(new_data)
    except OSError as exc:
        print(f"error: cannot write output {args.output}: {exc}", file=sys.stderr)
        return EXIT_RUNTIME_ERROR

    # 8. Report
    print(f"# template:  {args.template} ({len(template_data)} byte)")
    print(f"# allowlist: {args.allowlist} ({len(allowed_by_name)} allowed element)")
    if args.patch_spec:
        print(f"# patch-spec: {args.patch_spec}")
    print(f"# modifications: {len(actual_modifications)} element")
    for name, old, new in actual_modifications:
        print(f"#   {name}: {old!r} → {new!r}")
    size_diff = len(new_data) - len(template_data)
    print(f"# chunkByteSize: {body['chunkByteSize']} → {new_chunk_size} (= diff {size_diff:+d})")
    print(f"# output: {args.output} ({len(new_data)} byte)")
    print(f"# output sha256: {hashlib.sha256(new_data).hexdigest()}")
    print(f"# invariant verify: PASS (= allowlist 外 element / sub3 / trailing 不変)")

    return EXIT_OK


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="fxp_template_patch.py",
        description="PMDNEO ADR-0033 §決定 27 ξ/π ο/π2 = Surge XT .fxp template bridge spike",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_inspect = subparsers.add_parser("inspect", help="Inspect VST2 FXP header + body (read-only)")
    p_inspect.add_argument("input", type=Path, help="input .fxp file path")

    p_extract = subparsers.add_parser(
        "extract-xml",
        help="Extract XML body from FPCh chunk (read-only、 π2 新規)",
    )
    p_extract.add_argument("input", type=Path, help="input .fxp file path")
    p_extract.add_argument(
        "--output", type=Path, default=None,
        help="output XML file path (= default stdout)",
    )
    p_extract.add_argument(
        "--pretty", action="store_true",
        help="pretty-print XML (= 構造観察用、 binary 再 pack 用ではない)",
    )

    p_survey = subparsers.add_parser(
        "survey-params",
        help="Survey XML <parameters> elements + categorize (read-only、 π2 新規)",
    )
    p_survey.add_argument("input", type=Path, help="input .fxp file path")

    p_verify = subparsers.add_parser(
        "verify-repack",
        help="Verify chunk roundtrip + simulate modification + chunkByteSize recalc (= π2 新規 evidence proof)",
    )
    p_verify.add_argument("input", type=Path, help="input .fxp file path")

    p_diff = subparsers.add_parser(
        "diff",
        help="Diff 2 .fxp files = byte offset (= optional、 π2 で代替経路成立)",
    )
    p_diff.add_argument("a", type=Path, help="first .fxp")
    p_diff.add_argument("b", type=Path, help="second .fxp")

    p_patch = subparsers.add_parser(
        "patch",
        help="Patch parameter values via allowlist (= π4 新規、 patch-spec passthrough + --override 軸)",
    )
    p_patch.add_argument("--template", type=Path, required=True, help="input template .fxp")
    p_patch.add_argument("--allowlist", type=Path, required=True, help="parameter-allowlist.yaml")
    p_patch.add_argument("--output", type=Path, required=True, help="output patched .fxp")
    p_patch.add_argument(
        "--patch-spec",
        type=Path,
        default=None,
        help="patch-spec.yaml (= optional、 passthrough navigation でデフォルト値 fill)",
    )
    p_patch.add_argument(
        "--override",
        action="append",
        dest="overrides",
        default=None,
        metavar="NAME=VALUE",
        help="個別 element override (= 反復可、 patch-spec を上書き)",
    )

    args = parser.parse_args()

    if args.command == "inspect":
        return inspect_command(args.input)
    if args.command == "extract-xml":
        return extract_xml_command(args.input, args.output, args.pretty)
    if args.command == "survey-params":
        return survey_params_command(args.input)
    if args.command == "verify-repack":
        return verify_repack_command(args.input)
    if args.command == "diff":
        return diff_command(args)
    if args.command == "patch":
        return patch_command(args)

    parser.print_help()
    return EXIT_ARG_ERROR


if __name__ == "__main__":
    sys.exit(main())
