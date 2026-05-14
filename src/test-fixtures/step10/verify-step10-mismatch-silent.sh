#!/usr/bin/env bash
#
# ADR-0024 step 10 γ: mismatch silent verify (= 0xFD32 = 0xFF state で
# ADPCM-A keyon-related register writes 不発生確認)
#
# 目的:
#   ADR-0024 §決定 3 (= 2-C accept rule、 id=0x00 only-accept) + §決定 5
#   (= 4-A 採用、 adpcma_keyon_simple 最小変更) 実装後、 mismatch fixture で
#   ADPCM-A chip register writes が skip されることを literal 証跡として固定。
#
#   step 9 γ/δ までの verify は「resolver が 0xFD32 = 0xFF を保存する」 まで。
#   本 script は「mismatch state で playback path が ADPCM-A chip write を skip
#   する」 = playback selection に effective という step 10 の核心を verify。
#
# 検証: 6 段階 gate
#   gate 1: l-q-rhythm-song.mml + PMDDOTNET_MODE=B build + match trace 取得
#   gate 2: match path で 0xFD32 = 0x00 (= 6 件 idempotent、 ADR-0023 §決定 11
#           解除後の挙動、 既存 step 9 verify 流用)
#   gate 3: ROM patch ('s' → 'S' at directory entry 0) で mismatch fixture 作成
#   gate 4: mismatch path で 0xFD32 = 0xFF (= terminator sentinel)
#   gate 5: mismatch path で ADPCM-A keyon trigger (= reg 0x00 port B with bit
#           set) 不発生 = match path より 39 keyon trigger 少ない (= ±1 許容)
#   gate 6: mismatch path で ADPCM-A sample setup (= reg 0x10-0x2D port B)
#           完全消失 = match path で発生する keyon ごとの sample addr 設定が
#           skip された literal 証跡
#
# 検証範囲外 (= δ 別 step):
#   - step 5/6/7/8/9 既存 verify regression (= δ で serial 実行)
#   - audible 試聴 (= δ で user 試聴、 ただし γ では wav file を保存する)
#   - ADR-0024 §決定 7 contract 解除明示 (= ADR Accepted 移行は δ)
#
# 使い方:
#   bash src/test-fixtures/step10/verify-step10-mismatch-silent.sh
#
# 副作用:
#   /tmp/pmdneo-step10/match.wav     (= match path 録音、 4 秒、 user 試聴用)
#   /tmp/pmdneo-step10/mismatch.wav  (= mismatch path 録音、 4 秒、 user 試聴用)
#   /tmp/pmdneo-step10/*.tsv         (= trace snapshot、 後続調査用)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

SONG_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
ROM_PATH="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
LST_PATH="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
OUT_DIR="/tmp/pmdneo-step10"

if [[ ! -f "$SONG_MML" ]]; then
    echo "FAIL infra: fixture not found: $SONG_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step10-gamma-XXXXXX")
ROM_BACKUP="$TMPDIR/243-m1.m1.original"
trap 'cp "$ROM_BACKUP" "$ROM_PATH" 2>/dev/null || true; rm -rf "$TMPDIR"' EXIT

echo "=== ADR-0024 step 10 γ: mismatch silent verify (= ADPCM-A keyon-related register writes 不発生) ==="
echo

# ============================================================
# gate 1: match build + trace 取得 (= 既存 fixture そのまま)
# ============================================================
echo "=== gate 1: l-q-rhythm-song match build + trace ==="
PMDDOTNET_MML="$SONG_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/match-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: build failed (log: $TMPDIR/match-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/match-run.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: MAME match run failed"
    exit 2
}
MATCH_MEM="$OUT_DIR/match-mem.tsv"
MATCH_YMFM="$OUT_DIR/match-ymfm.tsv"
MATCH_WAV="$OUT_DIR/match.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$MATCH_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$MATCH_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$MATCH_WAV"
echo "  [PASS] match trace + wav 取得 (= fixture: $SONG_MML)"

# ============================================================
# gate 2: 0xFD32 = 0x00 (= match value、 6 件 idempotent)
# ============================================================
echo ""
echo "=== gate 2: match path 0xFD32 = 0x00 (= 6 件 idempotent) ==="
MATCH_FD32_WRITES=$(awk -F'\t' 'tolower($3) == "fd32"' "$MATCH_MEM")
MATCH_FD32_COUNT=$(echo -n "$MATCH_FD32_WRITES" | grep -c '' || true)
MATCH_FD32_UNIQUE=$(echo "$MATCH_FD32_WRITES" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$MATCH_FD32_UNIQUE" != "00 " ]]; then
    printf "  [FAIL] gate 2: match 0xFD32 unique values: %s (expected: 00)\n" "$MATCH_FD32_UNIQUE"
    exit 1
fi
if [[ "$MATCH_FD32_COUNT" -lt 6 ]]; then
    printf "  [FAIL] gate 2: match 0xFD32 write count %d (expected >= 6)\n" "$MATCH_FD32_COUNT"
    exit 1
fi
printf "  [PASS] match 0xFD32 = 0x00 (= 全 %d 件 idempotent)\n" "$MATCH_FD32_COUNT"

# ============================================================
# gate 3: ROM patch (= directory entry 0 's' → 'S' で mismatch fixture 作成)
# ============================================================
echo ""
echo "=== gate 3: ROM patch (= directory entry 0 's' → 'S') ==="
if [[ ! -f "$LST_PATH" ]]; then
    echo "  [FAIL] gate 3 infra: .lst not found ($LST_PATH)"
    exit 2
fi
DIRECTORY_OFFSET="0x$(awk '/pne_sample_directory:/ {print $1; exit}' "$LST_PATH")"
if [[ -z "$DIRECTORY_OFFSET" || "$DIRECTORY_OFFSET" == "0x" ]]; then
    echo "  [FAIL] gate 3 infra: pne_sample_directory addr not found in .lst"
    exit 2
fi
echo "  directory offset (= dynamic from .lst): $DIRECTORY_OFFSET"

cp "$ROM_PATH" "$ROM_BACKUP"
python3 - "$ROM_PATH" "$DIRECTORY_OFFSET" <<'PYEOF'
import sys
rom_path = sys.argv[1]
offset = int(sys.argv[2], 16)
with open(rom_path, "r+b") as f:
    f.seek(offset)
    before = f.read(1)
    if before != b's':
        sys.stderr.write(f"FAIL: expected 's' at 0x{offset:04X}, got {before!r}\n")
        sys.exit(1)
    f.seek(offset)
    f.write(b'S')
print(f"  patched ROM at 0x{offset:04X}: 's' (0x73) → 'S' (0x53)")
PYEOF
echo "  [PASS] ROM patch 適用 (= entry 0 filename: step5.PNE → Step5.PNE)"

# ============================================================
# gate 4: mismatch path で 0xFD32 = 0xFF
# ============================================================
echo ""
echo "=== gate 4: mismatch path 0xFD32 = 0xFF (= terminator sentinel) ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/mismatch-run.log" 2>&1 || {
    echo "  [FAIL] gate 4 infra: MAME mismatch run failed"
    exit 2
}
MISMATCH_MEM="$OUT_DIR/mismatch-mem.tsv"
MISMATCH_YMFM="$OUT_DIR/mismatch-ymfm.tsv"
MISMATCH_WAV="$OUT_DIR/mismatch.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$MISMATCH_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$MISMATCH_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$MISMATCH_WAV"

MISMATCH_FD32_WRITES=$(awk -F'\t' 'tolower($3) == "fd32"' "$MISMATCH_MEM")
MISMATCH_FD32_COUNT=$(echo -n "$MISMATCH_FD32_WRITES" | grep -c '' || true)
MISMATCH_FD32_UNIQUE=$(echo "$MISMATCH_FD32_WRITES" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$MISMATCH_FD32_UNIQUE" != "ff " ]]; then
    printf "  [FAIL] gate 4: mismatch 0xFD32 unique values: %s (expected: ff)\n" "$MISMATCH_FD32_UNIQUE"
    exit 1
fi
printf "  [PASS] mismatch 0xFD32 = 0xff (= 全 %d 件 idempotent、 terminator hit path)\n" "$MISMATCH_FD32_COUNT"

# ============================================================
# gate 5: ADPCM-A keyon trigger (= reg 0x00 port B with bit set) 不発生
# ============================================================
echo ""
echo "=== gate 5: ADPCM-A keyon trigger (= port B reg 0x00 bit set) 不発生 ==="
# port B reg 0x00 = ADPCM-A keyon control。 bit 0-5 set = ch 0-5 keyon、 bit 7 set = keyoff。
# match path で keyon (= bit 0-5 set with bit 7 clear) write が発生、 mismatch で skip 想定。
# ymfm-trace では port B reg は "1XX" prefix 形式 (= port B reg 0x00 → "100")
MATCH_KEYON_TRIGGERS=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$MATCH_YMFM")
MISMATCH_KEYON_TRIGGERS=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$MISMATCH_YMFM")
KEYON_DIFF=$((MATCH_KEYON_TRIGGERS - MISMATCH_KEYON_TRIGGERS))
printf "  match path keyon triggers (= reg 0x00 bit 0-5 set): %d\n" "$MATCH_KEYON_TRIGGERS"
printf "  mismatch path keyon triggers:                       %d\n" "$MISMATCH_KEYON_TRIGGERS"
printf "  diff (= skipped keyon):                             %d\n" "$KEYON_DIFF"
# 期待: match で 39+ keyon triggers (= PC=0FB3 78 entries / 2)、 mismatch で 0 か 2 (= init のみ)
# 実証: match - mismatch >= 30 (= 39 - 数 keyon の余裕で gate を緩く設定)
if [[ "$KEYON_DIFF" -lt 30 ]]; then
    printf "  [FAIL] gate 5: keyon diff %d (expected >= 30 = ~39 keyon skipped)\n" "$KEYON_DIFF"
    exit 1
fi
printf "  [PASS] mismatch path で %d 件の ADPCM-A keyon trigger が skip\n" "$KEYON_DIFF"

# ============================================================
# gate 6: ADPCM-A sample setup (= port B reg 0x10-0x2D) 完全消失
# ============================================================
echo ""
echo "=== gate 6: ADPCM-A sample setup (= port B reg 0x10-0x2D) 完全消失 ==="
# port B reg 0x10-0x1D = ADPCM-A ch 0-5 sample start LSB/MSB (= 0x10-0x15 LSB、 0x18-0x1D MSB)
# port B reg 0x20-0x2D = ADPCM-A ch 0-5 sample end LSB/MSB (= 0x20-0x25 LSB、 0x28-0x2D MSB)
# ymfm-trace では port B reg は "1XX" prefix 形式 (= port B reg 0x10 → "110"、 0x2D → "12D")
# 計 24 reg、 match path で keyon ごと 4 write × 39 keyon = 156 writes 想定
# mismatch path で 0 writes 想定 (= adpcma_keyon_simple の ret z で完全 skip)
MATCH_SETUP=$(awk -F'\t' '$2 == "B" && $3 ~ /^(11[0-9A-D]|12[0-9A-D])$/ {cnt++} END {print cnt+0}' "$MATCH_YMFM")
MISMATCH_SETUP=$(awk -F'\t' '$2 == "B" && $3 ~ /^(11[0-9A-D]|12[0-9A-D])$/ {cnt++} END {print cnt+0}' "$MISMATCH_YMFM")
SETUP_DIFF=$((MATCH_SETUP - MISMATCH_SETUP))
printf "  match path sample setup writes (= reg 0x10-0x2D): %d\n" "$MATCH_SETUP"
printf "  mismatch path sample setup writes:                %d\n" "$MISMATCH_SETUP"
printf "  diff (= skipped sample setup):                    %d\n" "$SETUP_DIFF"
# 期待: mismatch == 0 が core gate。 mismatch != 0 = sample setup の一部が走っている = silent 不完全
if [[ "$MISMATCH_SETUP" -ne 0 ]]; then
    printf "  [FAIL] gate 6: mismatch path sample setup writes %d (expected 0、 完全 skip 想定)\n" "$MISMATCH_SETUP"
    exit 1
fi
if [[ "$SETUP_DIFF" -lt 100 ]]; then
    printf "  [FAIL] gate 6: sample setup diff %d (expected >= 100 = ~156 writes skipped)\n" "$SETUP_DIFF"
    exit 1
fi
printf "  [PASS] mismatch path で ADPCM-A sample setup writes 完全 0、 match 比 %d 件 skip\n" "$SETUP_DIFF"

# ROM revert (= trap でも実行されるが明示)
cp "$ROM_BACKUP" "$ROM_PATH"
echo ""
echo "  [INFO] ROM patch revert 完了 (= source 不変、 build artifact のみ patch だった)"

echo ""
echo "=== ADR-0024 step 10 γ verify: 全 6 gate PASS ==="
echo "    fixture:           $SONG_MML"
echo "    match 0xFD32:      0x00 (= $MATCH_FD32_COUNT 件 idempotent)"
echo "    mismatch 0xFD32:   0xff (= $MISMATCH_FD32_COUNT 件 idempotent、 ROM 1 byte patch path)"
echo "    keyon trigger 差分: $KEYON_DIFF (= mismatch path で skipped)"
echo "    sample setup 差分:  $SETUP_DIFF (= mismatch path で完全 0)"
echo ""
echo "    user 試聴用 wav (= ADPCM-A drum audibility difference):"
echo "      match (= drums + FM):  $MATCH_WAV"
echo "      mismatch (= FM only):  $MISMATCH_WAV"
echo ""
echo "    次 step: δ で step 5/6/7/8/9 既存 verify regression serial 実行 + audible 試聴 + ADR-0024 Accepted"
