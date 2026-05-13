#!/usr/bin/env bash
#
# ADR-0016 step 7 δ: mc compiler /B path の pne_filename_adr embed verify
#
# 目的:
#   ADR-0021 §決定 3 (= mc compiler /B path は verify only)、 §決定 8 sub-sprint
#   構造の δ 段階。 改造 PMDDotNET (= /B mode) が出力する .MN binary に対し:
#     - m_start bit 2 = 1 (= PMDNEO mode flag)
#     - m_buf[26..27] = extended_data_adr (= 後方拡張領域先頭)
#     - extended_data_adr +12..13 = pne_filename_adr (= filename string offset)
#     - pne_filename_adr 位置に NUL-terminated ASCII filename string
#   が正しく embed されていることを hex dump レベルで verify。
#
#   driver / mc compiler / 既存実装は touch なし (= 既存 mc.cs:1491-1565 実装の
#   verify only、 ADR-0016 step 1 commit 45eebaf 遺産)。
#
# 検証: 4 段階 gate
#   gate 1: m_start = 0x04 (= PMDNEO mode flag = bit 2 set)
#   gate 2: extended_data_adr が valid range (= [1, file size) )
#   gate 3: pne_filename_adr が valid range
#   gate 4: NUL-terminated ASCII filename string が "step5.PNE"
#
# verify 経路:
#   既存 build-poc.sh の PMDDOTNET_MML + PMDDOTNET_MODE=B 経路を使って
#   src/test-fixtures/step5/l-q-rhythm-song.mml (= #PNEFile "step5.PNE" 宣言済) を
#   .MN 出力 → vendor/ngdevkit-examples/00-template/pmddotnet_song.m として
#   配置されたものを直接 hex parse。
#
# 使い方:
#   bash src/test-fixtures/step7/verify-step7-delta-mn-filename-embed.sh
#
# Exit code:
#   0 = PASS (= 全 4 gate PASS)
#   1 = verify fail (= gate 落ち)
#   2 = infra fail (= build failure / file missing 等)

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIXTURE="$PMDNEO_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
MN_FILE="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/pmddotnet_song.m"
EXPECTED_FILENAME="step5.PNE"

echo "=== step 7 δ: mc compiler /B path pne_filename_adr embed verify ==="
echo

# infra check
if [ ! -f "$FIXTURE" ]; then
    echo "infra fail: $FIXTURE not found" >&2
    exit 2
fi
for tool in python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "infra fail: $tool not found in PATH" >&2
        exit 2
    fi
done

# step 1: build with PMDDOTNET_MML + MODE=B (= 改造 PMDDotNET /B mode で .MN 生成)
echo "--- step 1: 改造 PMDDotNET /B mode で .MN 生成 (= $(basename "$FIXTURE")) ---"
PMDDOTNET_MML="$FIXTURE" PMDDOTNET_MODE=B \
    bash "$PMDNEO_ROOT/scripts/build-poc.sh" > /dev/null 2>&1 || {
    echo "infra fail: build-poc.sh /B mode failed" >&2
    exit 2
}
if [ ! -f "$MN_FILE" ]; then
    echo "infra fail: $MN_FILE not generated" >&2
    exit 2
fi
MN_SIZE=$(wc -c < "$MN_FILE" | tr -d ' ')
echo "  [PASS] .MN generated: $(basename "$MN_FILE") ($MN_SIZE byte)"

# step 2: hex parse + gate verify (= python wrapper、 bash hex parse より clean)
echo "--- step 2: .MN binary を hex parse + 4 gate verify ---"
python3 - "$MN_FILE" "$EXPECTED_FILENAME" "$MN_SIZE" <<'PYEOF'
import struct
import sys

mn_path, expected_filename, mn_size_str = sys.argv[1], sys.argv[2], sys.argv[3]
mn_size = int(mn_size_str)

with open(mn_path, "rb") as f:
    data = f.read()

assert len(data) == mn_size, f"file size mismatch: read {len(data)}, expected {mn_size}"


def fail(msg):
    print(f"  [FAIL] {msg}", file=sys.stderr)
    sys.exit(1)


# gate 1: m_start = 0x04
m_start = data[0]
if m_start == 0x04:
    print(f"  [PASS] gate 1: m_start = 0x{m_start:02x} (= PMDNEO mode flag = bit 2 set)")
else:
    fail(f"gate 1: m_start = 0x{m_start:02x}, expected 0x04")

# m_buf 開始 = file byte 1、 m_buf[26..27] = file byte 27..28
# = extended_data_adr (LE u16、 m_buf 相対 offset)
ext_adr = struct.unpack("<H", data[27:29])[0]
if 0 < ext_adr < mn_size:
    print(f"  [PASS] gate 2: extended_data_adr = 0x{ext_adr:04x} ({ext_adr}) (= valid range)")
else:
    fail(f"gate 2: extended_data_adr = {ext_adr} out of range [1, {mn_size})")

# pne_filename_adr = extended_data_adr +12..13 (= m_buf 相対)
# file offset = m_buf offset + 1 (= file byte 0 が m_start)
pne_adr_field_offset = ext_adr + 12 + 1
if pne_adr_field_offset + 2 > mn_size:
    fail(f"gate 3: pne_filename_adr field offset {pne_adr_field_offset} out of range")
pne_adr = struct.unpack("<H", data[pne_adr_field_offset:pne_adr_field_offset + 2])[0]
if 0 < pne_adr < mn_size:
    print(f"  [PASS] gate 3: pne_filename_adr = 0x{pne_adr:04x} ({pne_adr}) (= valid range)")
else:
    fail(f"gate 3: pne_filename_adr = {pne_adr} out of range [1, {mn_size})")

# filename string at pne_filename_adr (m_buf 相対) → file offset = pne_adr + 1
pne_str_offset = pne_adr + 1
nul_idx = data.find(b"\x00", pne_str_offset)
if nul_idx < 0:
    fail(f"gate 4: NUL terminator not found from offset {pne_str_offset}")
filename_bytes = data[pne_str_offset:nul_idx]
try:
    filename = filename_bytes.decode("ascii")
except UnicodeDecodeError:
    fail(f"gate 4: filename bytes {filename_bytes!r} not ASCII")
if filename == expected_filename:
    print(f"  [PASS] gate 4: filename = {filename!r} (= expected {expected_filename!r}、 NUL-terminated)")
else:
    fail(f"gate 4: filename = {filename!r}, expected {expected_filename!r}")

# 参考 hex dump (= filename string 前後 8 byte ずつ)
print()
print(f"  reference hex dump (= filename string 周辺、 file offset {pne_str_offset}):")
dump_start = max(0, pne_str_offset - 4)
dump_end = min(mn_size, nul_idx + 8)
hex_str = " ".join(f"{b:02x}" for b in data[dump_start:dump_end])
ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in data[dump_start:dump_end])
print(f"    offset {dump_start}: {hex_str}")
print(f"             ascii: {ascii_str}")
PYEOF

echo
echo "=== step 7 δ verify PASS (= 4/4 gate PASS) ==="
echo "  fixture: $(basename "$FIXTURE") (= #PNEFile \"$EXPECTED_FILENAME\" 宣言済)"
echo "  .MN binary: $(basename "$MN_FILE") ($MN_SIZE byte)"
echo "  m_start / extended_data_adr / pne_filename_adr / filename string 全 PASS"
