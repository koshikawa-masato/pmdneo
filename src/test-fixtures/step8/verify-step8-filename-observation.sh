#!/usr/bin/env bash
#
# ADR-0022 step 8 γ: runtime .PNE filename observation verify script
#
# 目的:
#   ADR-0022 §決定 7 γ で sprint 完了統合する前に、 α/β で成立した
#   PNE runtime observation block (= 0xFD20-0xFD31) の動作を 5 段 gate で固定。
#   driver / build pipeline 改修は α/β で完了、 γ は verify infra + doc のみ。
#
# 検証: 5 段階 gate
#   gate 1: l-q-rhythm-song.mml 経由 build + trace 取得
#   gate 2: 0xFD30-0xFD31 (= driver_pne_filename_adr_word) = .MN 内 pne_filename_adr 値
#   gate 3: 0xFD20-0xFD29 (= driver_pne_filename_buf) = filename string byte-identical
#   gate 4: 0xFD2A-0xFD2F (= buffer 余剰領域) untouched (= β scope-out + overflow 不通過)
#   gate 5: .MN binary 上の pne_filename_adr / filename string と runtime state 一致
#
# 検証範囲外 (= ADR-0022 §決定 2 / 8):
#   resolver / bank lookup / .PNE runtime parse / multi-.PNE / overflow fixture
#
# 使い方:
#   bash src/test-fixtures/step8/verify-step8-filename-observation.sh
#
# Exit code:
#   0 = PASS (= 全 5 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

SONG_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
MN_FILE="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/pmddotnet_song.m"
EXPECTED_FILENAME="step5.PNE"

# infra: fixture 存在確認
if [[ ! -f "$SONG_MML" ]]; then
    echo "FAIL infra: fixture not found: $SONG_MML"
    exit 2
fi

echo "=== ADR-0022 step 8 γ: runtime filename observation verify ==="
echo

# ============================================================
# gate 1: l-q-rhythm-song.mml 経由 build + trace
# ============================================================
echo "=== gate 1: l-q-rhythm-song build + trace ==="
TMPDIR=$(mktemp -d "/tmp/pmdneo-step8-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

PMDDOTNET_MML="$SONG_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build.log" 2>&1 || {
    echo "  [FAIL] infra: build failed (log: $TMPDIR/build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run.log" 2>&1 || {
    echo "  [FAIL] infra: MAME run failed"
    exit 2
}
Z80_TRACE="/tmp/pmdneo-trace/z80-mem-trace.tsv"
YMFM_TRACE="/tmp/pmdneo-trace/ymfm-trace.tsv"
if [[ ! -f "$Z80_TRACE" ]] || [[ ! -f "$YMFM_TRACE" ]] || [[ ! -f "$MN_FILE" ]]; then
    echo "  [FAIL] infra: trace / .MN file missing"
    exit 2
fi
echo "  [PASS] build + trace 取得 (.MN: $(wc -c < "$MN_FILE" | tr -d ' ') byte)"

# ============================================================
# gate 5 前段: .MN binary 解析 (= gate 2/3/5 の expected 値を計算)
# ============================================================
PARSE_OUT=$(python3 - "$MN_FILE" <<'PYEOF'
import struct
import sys

mn_path = sys.argv[1]
with open(mn_path, "rb") as f:
    data = f.read()

ext_adr = struct.unpack("<H", data[27:29])[0]
pne_field_offset = ext_adr + 12 + 1
pne_adr = struct.unpack("<H", data[pne_field_offset:pne_field_offset + 2])[0]
pne_str_offset = pne_adr + 1
nul_idx = data.find(b"\x00", pne_str_offset)
filename = data[pne_str_offset:nul_idx].decode("ascii")

# 1 行 TSV で出力: pne_adr / filename / filename_with_nul_hex
nul_hex = " ".join(f"{b:02X}" for b in data[pne_str_offset:nul_idx + 1])
print(f"{pne_adr}\t{filename}\t{nul_hex}")
PYEOF
)
EXPECTED_PNE_ADR=$(echo "$PARSE_OUT" | cut -f1)
PARSED_FILENAME=$(echo "$PARSE_OUT" | cut -f2)
EXPECTED_FILENAME_HEX=$(echo "$PARSE_OUT" | cut -f3)

# ============================================================
# gate 2: 0xFD30-0xFD31 (= driver_pne_filename_adr_word) = pne_filename_adr
# ============================================================
echo ""
echo "=== gate 2: driver_pne_filename_adr_word (= 0xFD30-0xFD31) ==="
FD30_LAST=$(awk -F'\t' 'toupper($3) == "FD30" {v=$4} END {print v}' "$Z80_TRACE")
FD31_LAST=$(awk -F'\t' 'toupper($3) == "FD31" {v=$4} END {print v}' "$Z80_TRACE")
if [[ -z "$FD30_LAST" ]] || [[ -z "$FD31_LAST" ]]; then
    echo "  [FAIL] gate 2: 0xFD30 or 0xFD31 への write 不検出"
    exit 1
fi
OBSERVED_PNE_ADR=$(printf "%d" $((0x${FD31_LAST}${FD30_LAST})))
if [[ "$OBSERVED_PNE_ADR" != "$EXPECTED_PNE_ADR" ]]; then
    printf "  [FAIL] gate 2: observed 0x%04X (=%d), expected 0x%04X (=%d)\n" \
        "$OBSERVED_PNE_ADR" "$OBSERVED_PNE_ADR" "$EXPECTED_PNE_ADR" "$EXPECTED_PNE_ADR"
    exit 1
fi
printf "  [PASS] driver_pne_filename_adr_word = 0x%04X (= pne_filename_adr from .MN)\n" "$OBSERVED_PNE_ADR"

# ============================================================
# gate 3: 0xFD20-0xFD29 (= driver_pne_filename_buf) = filename string byte-identical
# ============================================================
echo ""
echo "=== gate 3: driver_pne_filename_buf (= 0xFD20-0xFD29 = filename string) ==="
# filename string = step5.PNE\0 = 10 byte = 0xFD20-0xFD29
# 期待 hex: 73 74 65 70 35 2E 50 4E 45 00
OBSERVED_HEX=""
GATE3_PASS=1
for offset in 0 1 2 3 4 5 6 7 8 9; do
    addr=$(printf "FD%02X" $((0x20 + offset)))
    val=$(awk -F'\t' -v a="$addr" 'toupper($3) == a {v=$4} END {print v}' "$Z80_TRACE")
    if [[ -z "$val" ]]; then
        echo "  [FAIL] gate 3: 0x$addr への write 不検出 (offset $offset)"
        GATE3_PASS=0
        break
    fi
    OBSERVED_HEX+="${val} "
done
OBSERVED_HEX=$(echo "$OBSERVED_HEX" | tr 'a-f' 'A-F' | sed 's/  *$//')
EXPECTED_HEX=$(echo "$EXPECTED_FILENAME_HEX" | tr 'a-f' 'A-F')
if [[ "$GATE3_PASS" -eq 0 ]]; then
    exit 1
fi
if [[ "$OBSERVED_HEX" != "$EXPECTED_HEX" ]]; then
    echo "  [FAIL] gate 3: filename byte mismatch"
    echo "         observed: $OBSERVED_HEX"
    echo "         expected: $EXPECTED_HEX"
    exit 1
fi
echo "  [PASS] driver_pne_filename_buf = '${PARSED_FILENAME}\\0' (= $EXPECTED_HEX)"

# ============================================================
# gate 4: 0xFD2A-0xFD2F untouched (= β scope-out + overflow 不通過)
# ============================================================
echo ""
echo "=== gate 4: 0xFD2A-0xFD2F untouched (= overflow path 不通過 confirm) ==="
UNTOUCHED_COUNT=$(awk -F'\t' 'BEGIN{c=0} { addr=toupper($3); if(addr>="FD2A" && addr<="FD2F") c++ } END{print c}' "$Z80_TRACE")
if [[ "$UNTOUCHED_COUNT" -ne 0 ]]; then
    echo "  [FAIL] gate 4: 0xFD2A-0xFD2F に $UNTOUCHED_COUNT 件 write 検出 (= 0 件期待)"
    awk -F'\t' '{ addr=toupper($3); if(addr>="FD2A" && addr<="FD2F") print }' "$Z80_TRACE" | head -10
    exit 1
fi
echo "  [PASS] 0xFD2A-0xFD2F write 件数 = 0 (= 通常 contract で overflow path 不通過)"

# ============================================================
# gate 5: .MN binary と runtime state の整合 (= contract verify)
# ============================================================
echo ""
echo "=== gate 5: .MN ↔ runtime state contract verify ==="
if [[ "$PARSED_FILENAME" != "$EXPECTED_FILENAME" ]]; then
    echo "  [FAIL] gate 5: .MN filename = '$PARSED_FILENAME', expected '$EXPECTED_FILENAME'"
    exit 1
fi
printf "  [PASS] .MN pne_filename_adr = 0x%04X、 filename = '%s' (= runtime と一致)\n" \
    "$EXPECTED_PNE_ADR" "$PARSED_FILENAME"

# ============================================================
# 完了報告
# ============================================================
echo ""
echo "🎉 ADR-0022 step 8 γ verify PASS (= 5/5 gate)"
echo "   - gate 1: build + trace ✅"
echo "   - gate 2: driver_pne_filename_adr_word (= 0xFD30-0xFD31) ✅"
echo "   - gate 3: driver_pne_filename_buf (= 0xFD20-0xFD29) ✅"
echo "   - gate 4: 0xFD2A-0xFD2F untouched (= overflow 不通過) ✅"
echo "   - gate 5: .MN ↔ runtime state contract ✅"
echo ""
echo "   PNE runtime observation block 成立:"
printf "     0xFD20-0xFD29: '%s' + NUL (= filename string)\n" "$PARSED_FILENAME"
echo "     0xFD2A-0xFD2F: untouched (= 6 byte 余剰)"
printf "     0xFD30-0xFD31: 0x%04X LE (= pne_filename_adr、 m_buf-relative)\n" "$EXPECTED_PNE_ADR"
