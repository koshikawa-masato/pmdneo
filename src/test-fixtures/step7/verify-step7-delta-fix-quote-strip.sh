#!/usr/bin/env bash
#
# ADR-0016 step 7 δ-fix: mc compiler #PNEFile surrounding quote strip verify
#
# 目的:
#   δ verify で発見された finding (= mc compiler /B path が #PNEFile "step5.PNE" の
#   surrounding quotes を strip せず、 .MN に "step5.PNE"\0 (= 11 byte + NUL) を
#   embed してしまう問題) の修正 verify。
#
#   ADR-0021 §決定 3 (= mc compiler /B path は verify only、 fail 時は fix
#   micro-sprint) に基づき、 mc.cs を局所修正 (= surrounding quotes strip 1 ブロック
#   追加) し、 .MN embed が step5.PNE\0 (= 9 byte + NUL) になることを確認。
#
# 検証: 3 段階 gate
#   gate 1: quote あり入力 (= #PNEFile "step5.PNE") で .MN embed が step5.PNE\0
#   gate 2: 既存 fixture (= l-q-rhythm-song.mml) でも quote なし embed が成立
#   gate 3: filename string 長が 9 byte (= "step5.PNE" の中身)、 11 byte ではない
#
# scope:
#   - driver / build pipeline / .PNE converter は touch なし
#   - mc compiler の surrounding quote strip 1 ブロックのみ verify
#
# 使い方:
#   bash src/test-fixtures/step7/verify-step7-delta-fix-quote-strip.sh
#
# Exit code:
#   0 = PASS (= 全 3 gate PASS、 quote strip 成立)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FIXTURE="$PMDNEO_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
MN_FILE="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/pmddotnet_song.m"
EXPECTED_FILENAME="step5.PNE"
EXPECTED_LEN=9  # = len("step5.PNE")

echo "=== step 7 δ-fix: mc compiler #PNEFile surrounding quote strip verify ==="
echo

# infra check
if [ ! -f "$FIXTURE" ]; then
    echo "infra fail: $FIXTURE not found" >&2
    exit 2
fi

# step 1: build with /B mode (= fix 反映後の改造 PMDDotNET で .MN 生成)
echo "--- step 1: build with /B mode (= mc.cs fix 反映後の .MN 生成) ---"
PMDDOTNET_MML="$FIXTURE" PMDDOTNET_MODE=B \
    bash "$PMDNEO_ROOT/scripts/build-poc.sh" > /dev/null 2>&1 || {
    echo "infra fail: build-poc.sh /B mode failed" >&2
    exit 2
}
if [ ! -f "$MN_FILE" ]; then
    echo "infra fail: $MN_FILE not generated" >&2
    exit 2
fi
echo "  [PASS] .MN generated: $(basename "$MN_FILE") ($(wc -c < "$MN_FILE" | tr -d ' ') byte)"

# step 2: hex parse + gate verify
echo "--- step 2: filename string embed を hex parse + 3 gate verify ---"
python3 - "$MN_FILE" "$EXPECTED_FILENAME" "$EXPECTED_LEN" <<'PYEOF'
import struct
import sys

mn_path, expected, expected_len_str = sys.argv[1], sys.argv[2], sys.argv[3]
expected_len = int(expected_len_str)

with open(mn_path, "rb") as f:
    data = f.read()

# m_buf[26..27] = extended_data_adr (LE u16、 m_buf 相対)
ext_adr = struct.unpack("<H", data[27:29])[0]
# pne_filename_adr = extended_data_adr +12..13
pne_adr = struct.unpack("<H", data[ext_adr + 1 + 12:ext_adr + 1 + 14])[0]
# filename string at file offset = pne_adr + 1
pne_str_offset = pne_adr + 1
nul_idx = data.find(b"\x00", pne_str_offset)
filename_bytes = data[pne_str_offset:nul_idx]
filename = filename_bytes.decode("ascii")
filename_len = len(filename_bytes)


def fail(msg):
    print(f"  [FAIL] {msg}", file=sys.stderr)
    sys.exit(1)


# gate 1: quote strip 成立 (= filename が expected と完全一致)
if filename == expected:
    print(f"  [PASS] gate 1: filename = {filename!r} (= expected {expected!r}、 quote 込み非該当)")
else:
    fail(f"gate 1: filename = {filename!r}, expected {expected!r}")

# gate 2: 先頭末尾に quote 文字なし
if not filename.startswith('"') and not filename.endswith('"'):
    print(f"  [PASS] gate 2: filename 先頭末尾に quote 文字なし (= surrounding quotes 正しく strip)")
else:
    fail(f"gate 2: filename には quote 文字が含まれる: {filename!r}")

# gate 3: filename string 長が expected (= 9 byte = "step5.PNE")
if filename_len == expected_len:
    print(f"  [PASS] gate 3: filename string 長 = {filename_len} byte (= expected {expected_len}、 quote 込み 11 byte ではない)")
else:
    fail(f"gate 3: filename string 長 = {filename_len}, expected {expected_len}")

# hex dump 参考表示
print()
print(f"  reference hex dump (= filename string 周辺、 file offset {pne_str_offset}):")
dump_start = max(0, pne_str_offset - 4)
dump_end = min(len(data), nul_idx + 4)
hex_str = " ".join(f"{b:02x}" for b in data[dump_start:dump_end])
ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in data[dump_start:dump_end])
print(f"    offset {dump_start}: {hex_str}")
print(f"             ascii: {ascii_str}")
PYEOF

echo
echo "=== step 7 δ-fix verify PASS (= 3/3 gate PASS) ==="
echo "  mc.cs fix: surrounding quote strip 1 ブロック追加 (= mc.cs:2647-2657 周辺)"
echo "  .MN embed: \"$EXPECTED_FILENAME\\0\" (= $EXPECTED_LEN byte + NUL、 quote 込み embed 解消)"
