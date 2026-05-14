#!/usr/bin/env bash
#
# ADR-0025 step 11 γ: multi-table id=0x01 differential proof
#
# 目的:
#   ADR-0025 §決定 6 (= axis 5 / hybrid + 3 観点同時 + literal value assert) 実装。
#   step5.PNE run (= 0xFD32=0x00 → table A → L ch BD) と step5b.PNE run
#   (= 0xFD32=0x01 → table B → L ch SD) の register write trace を比較し、
#   「L ch addr regs だけ differ / M-Q addr regs identical / keyon count identical」
#   の 3 観点同時で selection differentiation が observable な literal proof として固定。
#
#   step5b.PNE 経路は ROM patch ではなく、 直接 step5b MML fixture
#   (= src/test-fixtures/step11/l-q-rhythm-song-step5b.mml、 #PNEFile "step5b.PNE")
#   を build する path B 流儀で実現 (= filename string を runtime に流す source-of-truth path)。
#
#   keyon count identical (= ADR-0025 §決定 6 / axis 5-b 重要安全装置) で「silent path に
#   倒れただけ」 ではなく「同じ回数鳴る + 別 sample が選ばれる」 を literal 証明する。
#
# 検証: 7 gate
#   gate 1: step5.PNE fixture build + trace (= MML l-q-rhythm-song.mml)
#   gate 2: step5.PNE run → 0xFD32 = 0x00 (= match entry 0)
#   gate 3: step5b.PNE fixture build + trace (= MML l-q-rhythm-song-step5b.mml)
#   gate 4: step5b.PNE run → 0xFD32 = 0x01 (= match entry 1)
#   gate 5: L ch ADPCM-A addr regs differ literal (= 4 reg × BD/SD addr literal assert)
#           reg 0x10/0x18/0x20/0x28 で step5 = BD (0x00/0x00/0x03/0x00) / step5b = SD (0x04/0x00/0x06/0x00)
#   gate 6: M-Q ch ADPCM-A addr regs byte-identical (= 副作用なし証明、 ch 1-5 で 20 reg)
#   gate 7: keyon count identical (= 同じ回数鳴る、 silent ではない selection differentiation 証明)
#
# 検証範囲外 (= δ 別 step):
#   - step 5/6/7/8/9/10 既存 verify regression (= δ で serial 実行)
#   - audible 試聴 (= δ で user 試聴、 ただし γ では wav file を保存する)
#   - ADR-0025 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step11/verify-step11-multi-table.sh
#
# 副作用:
#   /tmp/pmdneo-step11/step5.wav      (= step5.PNE 録音、 4 秒、 user 試聴用 BD audible)
#   /tmp/pmdneo-step11/step5b.wav     (= step5b.PNE 録音、 4 秒、 user 試聴用 SD audible)
#   /tmp/pmdneo-step11/*.tsv          (= trace snapshot、 後続調査用)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

STEP5_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
STEP5B_MML="$PROJECT_ROOT/src/test-fixtures/step11/l-q-rhythm-song-step5b.mml"
OUT_DIR="/tmp/pmdneo-step11"

if [[ ! -f "$STEP5_MML" ]]; then
    echo "FAIL infra: fixture not found: $STEP5_MML"
    exit 2
fi
if [[ ! -f "$STEP5B_MML" ]]; then
    echo "FAIL infra: fixture not found: $STEP5B_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step11-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0025 §決定 6 axis 5-e、 trivial verify 防止)
## BD / SD addr literal は assets/samples.inc 由来 (= VROM offset 0x000-0x3FF = BD、 0x400-0x6FF = SD)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_START_MSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_BD_STOP_MSB="00"
EXPECTED_SD_START_LSB="04"
EXPECTED_SD_START_MSB="00"
EXPECTED_SD_STOP_LSB="06"
EXPECTED_SD_STOP_MSB="00"

echo "=== ADR-0025 step 11 γ: multi-table id=0x01 differential proof ==="
echo

# ============================================================
# gate 1: step5.PNE build + trace
# ============================================================
echo "=== gate 1: step5.PNE fixture build + trace (= filename embed step5.PNE) ==="
PMDDOTNET_MML="$STEP5_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/step5-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: step5 build failed (log: $TMPDIR/step5-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/step5-run.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: step5 MAME run failed"
    exit 2
}
STEP5_MEM="$OUT_DIR/step5-mem.tsv"
STEP5_YMFM="$OUT_DIR/step5-ymfm.tsv"
STEP5_WAV="$OUT_DIR/step5.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$STEP5_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$STEP5_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$STEP5_WAV"
echo "  [PASS] step5.PNE trace + wav 取得 (= fixture: $STEP5_MML)"

# ============================================================
# gate 2: step5 0xFD32 = 0x00
# ============================================================
echo
echo "=== gate 2: step5.PNE → 0xFD32 = 0x00 (= resolver entry 0 match) ==="
STEP5_FD32_UNIQUE=$(awk -F'\t' 'tolower($3) == "fd32"' "$STEP5_MEM" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$STEP5_FD32_UNIQUE" != "00 " ]]; then
    printf "  [FAIL] gate 2: step5 0xFD32 unique values: '%s' (expected: '00 ')\n" "$STEP5_FD32_UNIQUE"
    exit 1
fi
STEP5_FD32_COUNT=$(awk -F'\t' 'tolower($3) == "fd32"' "$STEP5_MEM" | grep -c '' || true)
printf "  [PASS] step5 0xFD32 = 0x00 (= 全 %d 件 idempotent、 entry 0 match)\n" "$STEP5_FD32_COUNT"

# ============================================================
# gate 3: step5b.PNE build + trace
# ============================================================
echo
echo "=== gate 3: step5b.PNE fixture build + trace (= filename embed step5b.PNE) ==="
PMDDOTNET_MML="$STEP5B_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/step5b-build.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: step5b build failed (log: $TMPDIR/step5b-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/step5b-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: step5b MAME run failed"
    exit 2
}
STEP5B_MEM="$OUT_DIR/step5b-mem.tsv"
STEP5B_YMFM="$OUT_DIR/step5b-ymfm.tsv"
STEP5B_WAV="$OUT_DIR/step5b.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$STEP5B_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$STEP5B_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$STEP5B_WAV"
echo "  [PASS] step5b.PNE trace + wav 取得 (= fixture: $STEP5B_MML)"

# ============================================================
# gate 4: step5b 0xFD32 = 0x01
# ============================================================
echo
echo "=== gate 4: step5b.PNE → 0xFD32 = 0x01 (= resolver entry 1 match) ==="
STEP5B_FD32_UNIQUE=$(awk -F'\t' 'tolower($3) == "fd32"' "$STEP5B_MEM" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$STEP5B_FD32_UNIQUE" != "01 " ]]; then
    printf "  [FAIL] gate 4: step5b 0xFD32 unique values: '%s' (expected: '01 ')\n" "$STEP5B_FD32_UNIQUE"
    exit 1
fi
STEP5B_FD32_COUNT=$(awk -F'\t' 'tolower($3) == "fd32"' "$STEP5B_MEM" | grep -c '' || true)
printf "  [PASS] step5b 0xFD32 = 0x01 (= 全 %d 件 idempotent、 entry 1 match)\n" "$STEP5B_FD32_COUNT"

# ============================================================
# gate 5: L ch addr regs literal value assert (= step5 = BD / step5b = SD)
# ============================================================
echo
echo "=== gate 5: L ch (= ch 0) addr regs literal value assert ==="
# L ch = ADPCM-A ch 0 の addr regs (= port B reg 0x10/0x18/0x20/0x28、 ymfm-trace では "110"/"118"/"120"/"128")
# bash 3.2 互換のため case 文で reg → label / expected value を mapping
# proof 経路: literal value assert (= step5 = BD literal AND step5b = SD literal)
#             + 少なくとも 1 reg で step5 != step5b (= 実 differentiation 証跡)
# 注意: BD_*_MSB と SD_*_MSB は偶然両方 0x00 (= 両 sample が VROM 0x000-0xFFF 内)、
#       MSB reg では step5 == step5b でも問題なし (= 値は正しい literal)。
#       LSB reg (= 0x10/0x20) で literal が異なるため differentiation 証拠が立つ。
GATE5_LSB_DIFFER=0
for reg in 110 118 120 128; do
    case "$reg" in
        110) LABEL="start_lsb"; EXP_S5="$EXPECTED_BD_START_LSB"; EXP_S5B="$EXPECTED_SD_START_LSB"; LSB_FLAG=1 ;;
        118) LABEL="start_msb"; EXP_S5="$EXPECTED_BD_START_MSB"; EXP_S5B="$EXPECTED_SD_START_MSB"; LSB_FLAG=0 ;;
        120) LABEL="stop_lsb";  EXP_S5="$EXPECTED_BD_STOP_LSB";  EXP_S5B="$EXPECTED_SD_STOP_LSB";  LSB_FLAG=1 ;;
        128) LABEL="stop_msb";  EXP_S5="$EXPECTED_BD_STOP_MSB";  EXP_S5B="$EXPECTED_SD_STOP_MSB";  LSB_FLAG=0 ;;
    esac
    S5_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$STEP5_YMFM" | sort -u | head -1)
    S5B_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$STEP5B_YMFM" | sort -u | head -1)
    if [[ "$S5_VAL" != "$EXP_S5" ]]; then
        printf "  [FAIL] gate 5: step5 reg 0x%s (%s) = 0x%s (expected: 0x%s = BD literal)\n" "${reg:1}" "$LABEL" "$S5_VAL" "$EXP_S5"
        exit 1
    fi
    if [[ "$S5B_VAL" != "$EXP_S5B" ]]; then
        printf "  [FAIL] gate 5: step5b reg 0x%s (%s) = 0x%s (expected: 0x%s = SD literal)\n" "${reg:1}" "$LABEL" "$S5B_VAL" "$EXP_S5B"
        exit 1
    fi
    if [[ "$LSB_FLAG" -eq 1 && "$S5_VAL" != "$S5B_VAL" ]]; then
        GATE5_LSB_DIFFER=$((GATE5_LSB_DIFFER + 1))
        printf "  reg 0x%s (%s): step5 = 0x%s (BD literal) / step5b = 0x%s (SD literal) — DIFFER\n" "${reg:1}" "$LABEL" "$S5_VAL" "$S5B_VAL"
    else
        printf "  reg 0x%s (%s): step5 = 0x%s / step5b = 0x%s (= BD/SD literal は偶然同値、 両 sample が VROM 0x000-0xFFF 内のため MSB は 0x00)\n" "${reg:1}" "$LABEL" "$S5_VAL" "$S5B_VAL"
    fi
done
if [[ "$GATE5_LSB_DIFFER" -lt 2 ]]; then
    printf "  [FAIL] gate 5: LSB reg differentiation count %d (expected: 2 = start_lsb + stop_lsb で differ)\n" "$GATE5_LSB_DIFFER"
    exit 1
fi
echo "  [PASS] L ch addr regs differ literal: step5 BD (0x00/0x00/0x03/0x00) vs step5b SD (0x04/0x00/0x06/0x00)"

# ============================================================
# gate 6: M-Q ch addr regs byte-identical (= 副作用なし証明)
# ============================================================
echo
echo "=== gate 6: M-Q ch (= ch 1-5) addr regs identical (= 副作用なし証明) ==="
# M-Q ch = ADPCM-A ch 1-5 の addr regs (= port B reg 0x11-0x15 / 0x19-0x1D / 0x21-0x25 / 0x29-0x2D)
# ymfm-trace では port B prefix "1" を付与: "111"-"115" / "119"-"11D" / "121"-"125" / "129"-"12D"
MQ_DIFFS=0
for reg in 111 112 113 114 115 119 11A 11B 11C 11D 121 122 123 124 125 129 12A 12B 12C 12D; do
    S5_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$STEP5_YMFM" | sort -u | head -1)
    S5B_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$STEP5B_YMFM" | sort -u | head -1)
    if [[ "$S5_VAL" != "$S5B_VAL" ]]; then
        printf "  [DIFF] reg 0x%s: step5 = 0x%s / step5b = 0x%s\n" "${reg:1}" "$S5_VAL" "$S5B_VAL"
        MQ_DIFFS=$((MQ_DIFFS + 1))
    fi
done
if [[ "$MQ_DIFFS" -gt 0 ]]; then
    printf "  [FAIL] gate 6: M-Q ch addr regs に %d 件 differ あり (expected: 0、 副作用なし)\n" "$MQ_DIFFS"
    exit 1
fi
echo "  [PASS] M-Q ch addr regs identical (= 20 reg × ch 1-5 で 0 件 differ、 副作用なし証明)"

# ============================================================
# gate 7: keyon count identical (= 同じ回数鳴る、 silent 経路ではない literal)
# ============================================================
echo
echo "=== gate 7: keyon count identical (= silent 経路ではない literal、 selection differentiation 証明) ==="
# port B reg 0x00 = ADPCM-A keyon control (= ymfm "100" prefix)
# step5 と step5b で同じ回数 keyon trigger される (= 同 MML body、 keyon path 完全不変)
STEP5_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$STEP5_YMFM")
STEP5B_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$STEP5B_YMFM")
printf "  step5 keyon trigger count:  %d\n" "$STEP5_KEYON"
printf "  step5b keyon trigger count: %d\n" "$STEP5B_KEYON"
if [[ "$STEP5_KEYON" -ne "$STEP5B_KEYON" ]]; then
    printf "  [FAIL] gate 7: keyon count differ (= step5 %d / step5b %d、 selection ではなく silent path 等の possibility)\n" "$STEP5_KEYON" "$STEP5B_KEYON"
    exit 1
fi
if [[ "$STEP5_KEYON" -lt 30 ]]; then
    printf "  [FAIL] gate 7: keyon count too low (= step5 %d < 30、 expected: ~41 from Step 10 baseline)\n" "$STEP5_KEYON"
    exit 1
fi
printf "  [PASS] keyon count identical: %d (= 同じ回数鳴る、 step5b は silent 経路ではない、 別 sample が選ばれた literal proof)\n" "$STEP5_KEYON"

# ============================================================
# 完了
# ============================================================
echo
echo "=== ADR-0025 step 11 γ verify: 全 7 gate PASS ==="
echo "    fixtures:"
echo "      step5:  $STEP5_MML  (= filename embed step5.PNE  → 0xFD32=0x00 → table A → L ch BD)"
echo "      step5b: $STEP5B_MML (= filename embed step5b.PNE → 0xFD32=0x01 → table B → L ch SD)"
echo
echo "    selection differentiation proof:"
echo "      L ch addr regs differ literal:  step5 = BD (0x00/0x00/0x03/0x00) / step5b = SD (0x04/0x00/0x06/0x00)"
echo "      M-Q ch addr regs identical:     20 reg × ch 1-5 で 0 件 differ (= 副作用なし)"
echo "      keyon count identical:          $STEP5_KEYON (= 同じ回数鳴る、 silent ではない)"
echo
echo "    user 試聴用 wav (= γ から audible 差分が出る):"
echo "      step5  (= L ch BD): $STEP5_WAV"
echo "      step5b (= L ch SD): $STEP5B_WAV"
echo
echo "    次 step: δ で step 5/6/7/8/9/10 既存 verify regression serial 実行 + user 試聴 + ADR-0025 Accepted"
