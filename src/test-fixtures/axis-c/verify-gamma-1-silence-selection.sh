#!/usr/bin/env bash
#
# ADR-0043 §sub-sprint γ-1: γ-1 専用 differential verify (= voice 1 silence selection)
#
# 目的: γ-1 actual silence sample 投入後、 voice 1 selection 経路が:
#   1. compile.py が @1 を PART_OFF_INSTRUMENT=1 として .mn に emit
#   2. driver pmdneo_select_adpcmb_sample_pointer が voice 1 → sample id 1 → adpcmb_sample_silence 経路通過
#   3. adpcmb_keyon が reg 0x12-0x15 に SILENCE_START_LSB/MSB/STOP_LSB/MSB literal 値書込
#   4. 値が beat addr (= reg 0x12=0x2a, 0x13=0x00, 0x14=0xa8, 0x15=0x00) と differ
#   5. samples.inc に SILENCE_START_LSB 等 generated symbol が emit されている
# を再現可能に確認する。
#
# Codex layer 2 revise plan v2 must-fix 3 件解消対応:
#   - must-fix #1 = voice 1 fixture 明記 (= gamma-1-silence-selection.mml @1 経路)
#   - must-fix #2 = verify gate 分離 (= step4 byte-identical regression と独立)
#   - must-fix #3 = samples.inc emit assert (= SILENCE_START_LSB grep)
#
# 前提:
#   - PMDNEO_ROOT で build + run-mame infra が動く
#   - src/test-fixtures/axis-c/gamma-1-silence-selection.mml
#   - assets/pne/silence.wav (= 16-bit 8 kHz mono 0.1s zero PCM)
#   - assets/pne/samples-map-adpcmb.yaml に silence entry 追加済
#
# 使い方:
#   bash src/test-fixtures/axis-c/verify-gamma-1-silence-selection.sh
#
# Exit code:
#   0 = PASS (= samples.inc emit + reg 0x12-0x15 SILENCE_* 一致 + beat addr と differ)
#   1 = FAIL (= 期待値不一致 / SILENCE_* emit なし / beat と一致)
#   2 = infra fail (= build / run-mame error)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

TMPDIR=$(mktemp -d "/tmp/pmdneo-axis-c-gamma-1-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

FIXTURE_MML="$PROJECT_ROOT/src/test-fixtures/axis-c/gamma-1-silence-selection.mml"
SAMPLES_INC="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/assets/samples.inc"

echo "=== γ-1 silence selection fixture build ==="
cp "$FIXTURE_MML" "$TMPDIR/gamma-1-silence-selection.mml"
MML_INPUTS="$TMPDIR/gamma-1-silence-selection.mml,test02.mml" bash scripts/build-poc.sh > "$TMPDIR/build.log" 2>&1 || {
    echo "  ERROR: build fail (= log: $TMPDIR/build.log)"
    tail -30 "$TMPDIR/build.log" >&2
    exit 2
}
echo "  ✅ build PASS"
echo ""

# must-fix #3: samples.inc emit assert
echo "=== samples.inc に SILENCE_* generated symbol emit assert ==="
if [[ ! -f "$SAMPLES_INC" ]]; then
    echo "  FAIL: samples.inc 不在 ($SAMPLES_INC)"
    exit 1
fi
for sym in SILENCE_START_LSB SILENCE_START_MSB SILENCE_STOP_LSB SILENCE_STOP_MSB; do
    if ! grep -q "$sym" "$SAMPLES_INC"; then
        echo "  FAIL: $sym が samples.inc に emit されていない"
        echo "  --- samples.inc 内容 ---"
        cat "$SAMPLES_INC"
        exit 1
    fi
    val=$(awk -v s="$sym" '$0 ~ "\\.equ[ \t]+" s "," {print $NF}' "$SAMPLES_INC" | head -1)
    echo "  ✅ $sym = $val"
done
echo ""

# samples.inc から SILENCE_* 値抽出 (= 期待 reg 値計算用、 hex literal 0x.. format)
silence_start_lsb=$(awk '$0 ~ /\.equ[ \t]+SILENCE_START_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
silence_start_msb=$(awk '$0 ~ /\.equ[ \t]+SILENCE_START_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
silence_stop_lsb=$(awk '$0 ~ /\.equ[ \t]+SILENCE_STOP_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
silence_stop_msb=$(awk '$0 ~ /\.equ[ \t]+SILENCE_STOP_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')

# beat addr (= 既知固定値、 step4 fixture と同 samples.inc layout、 既存 driver L2820 BEAT_*)
beat_start_lsb=$(awk '$0 ~ /\.equ[ \t]+BEAT_START_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
beat_start_msb=$(awk '$0 ~ /\.equ[ \t]+BEAT_START_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
beat_stop_lsb=$(awk '$0 ~ /\.equ[ \t]+BEAT_STOP_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')
beat_stop_msb=$(awk '$0 ~ /\.equ[ \t]+BEAT_STOP_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//')

echo "=== samples.inc literal value extracted ==="
echo "  silence: start=${silence_start_lsb}/${silence_start_msb} stop=${silence_stop_lsb}/${silence_stop_msb}"
echo "  beat:    start=${beat_start_lsb}/${beat_start_msb} stop=${beat_stop_lsb}/${beat_stop_msb}"
echo ""

# silence と beat addr が differ assert (= 同一なら vromtool が新規 sample 認識せず or 衝突)
differ_count=0
[[ "$silence_start_lsb" != "$beat_start_lsb" ]] && differ_count=$((differ_count+1))
[[ "$silence_start_msb" != "$beat_start_msb" ]] && differ_count=$((differ_count+1))
[[ "$silence_stop_lsb" != "$beat_stop_lsb" ]] && differ_count=$((differ_count+1))
[[ "$silence_stop_msb" != "$beat_stop_msb" ]] && differ_count=$((differ_count+1))
if [[ "$differ_count" -eq 0 ]]; then
    echo "  FAIL: silence addr が beat addr と全て一致 (= 別 sample として認識されていない)"
    exit 1
fi
echo "  ✅ silence addr が beat addr と differ ($differ_count / 4 byte differ)"
echo ""

# run-mame + trace 取得
echo "=== run-mame + trace 取得 (= reg 0x12-0x15 ADPCM-B sample addr) ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace > "$TMPDIR/run.log" 2>&1 || {
    echo "  ERROR: run-mame fail"
    tail -20 "$TMPDIR/run.log" >&2
    exit 2
}
cp /tmp/pmdneo-trace/audio.wav "$TMPDIR/"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TMPDIR/"
echo "  ✅ trace 取得 PASS"
echo ""

# reg 0x12-0x15 ADPCM-B port 'A' 値抽出 (= adpcmb_keyon 経路の write、 last match)
# ymfm-trace.tsv format: idx<TAB>port<TAB>reg<TAB>val (= step4 同 format)
# (注: first match 取得だと ADPCM-B init で 0x00 書込を拾うため、 last match で
# adpcmb_keyon → adpcmb_keyon_have_sample → reg 0x12-0x15 write を取得する)
# (注: bash 3.2 互換のため ${var,,} 構文は使わず tr で lowercase 変換)
echo "=== reg 0x12-0x15 trace 抽出 (= last match) + SILENCE_* 一致 assert ==="
trace_reg12=$(awk -F'\t' '$2 == "A" && $3 == "12" {val=$4} END {print val}' "$TMPDIR/ymfm-trace.tsv" | tr 'A-Z' 'a-z')
trace_reg13=$(awk -F'\t' '$2 == "A" && $3 == "13" {val=$4} END {print val}' "$TMPDIR/ymfm-trace.tsv" | tr 'A-Z' 'a-z')
trace_reg14=$(awk -F'\t' '$2 == "A" && $3 == "14" {val=$4} END {print val}' "$TMPDIR/ymfm-trace.tsv" | tr 'A-Z' 'a-z')
trace_reg15=$(awk -F'\t' '$2 == "A" && $3 == "15" {val=$4} END {print val}' "$TMPDIR/ymfm-trace.tsv" | tr 'A-Z' 'a-z')

exp_reg12=$(echo "$silence_start_lsb" | tr 'A-Z' 'a-z')
exp_reg13=$(echo "$silence_start_msb" | tr 'A-Z' 'a-z')
exp_reg14=$(echo "$silence_stop_lsb"  | tr 'A-Z' 'a-z')
exp_reg15=$(echo "$silence_stop_msb"  | tr 'A-Z' 'a-z')

echo "  reg 0x12 (= ADPCM-B start LSB) trace = 0x${trace_reg12} (expected 0x${exp_reg12})"
echo "  reg 0x13 (= ADPCM-B start MSB) trace = 0x${trace_reg13} (expected 0x${exp_reg13})"
echo "  reg 0x14 (= ADPCM-B stop LSB)  trace = 0x${trace_reg14} (expected 0x${exp_reg14})"
echo "  reg 0x15 (= ADPCM-B stop MSB)  trace = 0x${trace_reg15} (expected 0x${exp_reg15})"

fail=0
[[ "$trace_reg12" != "$exp_reg12" ]] && { echo "  FAIL: reg 0x12 mismatch"; fail=1; }
[[ "$trace_reg13" != "$exp_reg13" ]] && { echo "  FAIL: reg 0x13 mismatch"; fail=1; }
[[ "$trace_reg14" != "$exp_reg14" ]] && { echo "  FAIL: reg 0x14 mismatch"; fail=1; }
[[ "$trace_reg15" != "$exp_reg15" ]] && { echo "  FAIL: reg 0x15 mismatch"; fail=1; }
if [[ "$fail" -eq 1 ]]; then
    exit 1
fi
echo "  ✅ reg 0x12-0x15 全て SILENCE_* 値と一致"
echo ""

echo "🎉 ADR-0043 §sub-sprint γ-1 silence selection verify PASS"
echo "   - samples.inc に SILENCE_* generated symbol emit OK"
echo "   - silence addr と beat addr が differ ($differ_count / 4 byte)"
echo "   - reg 0x12-0x15 trace が SILENCE_* literal 値と一致"
echo "   - voice 1 = sample B = adpcmb_sample_silence 経路 register trace 実証完了"
exit 0
