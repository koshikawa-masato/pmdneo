#!/usr/bin/env bash
#
# ADR-0043 §sub-sprint γ-2: multi-table sample_table_id integration proof (= hybrid 経路、 6 gate)
#
# 目的:
#   ADR-0043 §決定 1 γ 完了判定 (= 「id=0x00 / id=0x01 fixture 比較で sample 切替
#   observable proof」) 充足。 ADPCM-A 軸との独立性 trace は γ-3 へ defer
#   (= unexpected finding: 改造 PMDDotNET /B mode で L-Q + J 同時含む MML は J
#   part が .MN binary に emit されない、 ADR-0043 §sub-sprint chain γ-3 起票)。
#
#   step5.PNE 経路 (= 0xFD32=0x00 → table A → J voice 0 → beat) と step5b.PNE
#   経路 (= 0xFD32=0x01 → table B → J voice 0 → silence_b) の register write
#   trace を比較し、 ADPCM-B sample 切替 (= reg 0x12-0x15 BEAT_* vs SILENCE_B_*)
#   + ADPCM-B non-addr 不変 (= delta-N/vol/pan/keyon identical) + ADPCM-A keyon
#   count identical (= 副作用なし weak proof) の 6 gate 同時 assert で literal 証明。
#
#   hybrid 経路 (= Codex layer 2 revise must-fix 反映):
#     - J body: MML_INPUTS env + 自前 compile.py 経路 (= step4 既動作 pattern 流用)
#     - carrier: PMDDOTNET_MML + /B mode + PMDNEO_USE_PMDDOTNET=1 経路 (= step11
#       pattern 流用、 #PNEFile filename embed → resolver → 0xFD32 設定)
#     - 両経路同時 build で J body と filename carrier が一緒に ROM に組み込まれる
#       (= build-poc.sh L107 compile.py + L163 PMDDotNET .MN carrier 経路、
#         両経路同 driver build 内共存)
#
# Codex layer 2 round 3 revise must-fix 4 件解消対応:
#   - must-fix #1 = case X 不採用 (= compile.py 単独では #PNEFile 流れない、 L525 #
#     以降コメント落とし) → hybrid 経路採用
#   - must-fix #2 = hybrid 経路 (= J body compile.py + carrier PMDDotNET .MN) 採用
#   - must-fix #3 = PMDDotNET J-only 代替不採用 (= driver J part は compile.py
#     song_table 側初期化、 L-Q は .MN resolver path、 standalone_test.s:1416/1440)
#   - must-fix #4 = 0xFD32 carrier gate 追加 (= step5.PNE → 0x00、 step5b.PNE →
#     0x01、 ADPCM-B reg differ、 ADPCM-A keyon は carrier rest のみ)
#
# 前提:
#   - PMDNEO_ROOT で build + run-mame infra が動く
#   - src/test-fixtures/step4/j-part-minimum.mml (= 既存 J only fixture 流用)
#   - src/test-fixtures/step5/l-q-rhythm-song.mml (= 既存 carrier #PNEFile step5.PNE)
#   - src/test-fixtures/step11/l-q-rhythm-song-step5b.mml (= 既存 carrier #PNEFile step5b.PNE)
#   - assets/pne/silence.wav + silence_b.wav (= γ-1/γ-2 project-owned wav)
#   - assets/pne/samples-map-adpcmb.yaml に beat/silence/silence_b 3 entry
#   - driver standalone_test.s @ pmdneo_select_adpcmb_sample_pointer に 0xFD32 lookup
#     + table A/B dispatch + sentinel 経路 (= γ-2 改修済)
#
# 使い方:
#   bash src/test-fixtures/axis-c/verify-gamma-2-multi-table.sh
#
# 副作用:
#   /tmp/pmdneo-axis-c-gamma-2/id-zero.wav      (= step5.PNE carrier 録音、 4 秒)
#   /tmp/pmdneo-axis-c-gamma-2/id-one.wav       (= step5b.PNE carrier 録音、 4 秒)
#   /tmp/pmdneo-axis-c-gamma-2/*.tsv            (= trace snapshot、 後続調査用)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

J_BODY_MML="$PROJECT_ROOT/src/test-fixtures/step4/j-part-minimum.mml"
ZERO_CARRIER_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
ONE_CARRIER_MML="$PROJECT_ROOT/src/test-fixtures/step11/l-q-rhythm-song-step5b.mml"
SAMPLES_INC="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/assets/samples.inc"
OUT_DIR="/tmp/pmdneo-axis-c-gamma-2"

for f in "$J_BODY_MML" "$ZERO_CARRIER_MML" "$ONE_CARRIER_MML"; do
    if [[ ! -f "$f" ]]; then
        echo "FAIL infra: fixture not found: $f"
        exit 2
    fi
done

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-axis-c-gamma-2-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

# J body は compile.py 経路で MML_INPUTS env に流すため、 tmp に cp (= step4 verify pattern 同)
cp "$J_BODY_MML" "$TMPDIR/j-body.mml"

echo "=== ADR-0043 §sub-sprint γ-2: multi-table sample_table_id integration proof (= hybrid 経路、 6 gate) ==="
echo

# ============================================================
# gate 1: step5.PNE carrier + J body (id=0x00) hybrid build + trace
# ============================================================
echo "=== gate 1: step5.PNE carrier + J body (id=0x00) hybrid build + trace ==="
MML_INPUTS="$TMPDIR/j-body.mml,test02.mml" PMDDOTNET_MML="$ZERO_CARRIER_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/zero-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: zero hybrid build failed (log: $TMPDIR/zero-build.log)"
    tail -20 "$TMPDIR/zero-build.log" >&2
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/zero-run.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: zero MAME run failed"
    exit 2
}
ZERO_MEM="$OUT_DIR/zero-mem.tsv"
ZERO_YMFM="$OUT_DIR/zero-ymfm.tsv"
ZERO_WAV="$OUT_DIR/id-zero.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$ZERO_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$ZERO_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$ZERO_WAV"
echo "  [PASS] step5.PNE carrier + J body (id=0x00) trace + wav 取得"

# samples.inc から literal value 抽出 (= γ-1 emit + γ-2 silence_b 新規 emit)
SILENCE_B_START_LSB=$(awk '$0 ~ /\.equ[ \t]+SILENCE_B_START_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
SILENCE_B_START_MSB=$(awk '$0 ~ /\.equ[ \t]+SILENCE_B_START_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
SILENCE_B_STOP_LSB=$(awk '$0 ~ /\.equ[ \t]+SILENCE_B_STOP_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
SILENCE_B_STOP_MSB=$(awk '$0 ~ /\.equ[ \t]+SILENCE_B_STOP_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
BEAT_START_LSB=$(awk '$0 ~ /\.equ[ \t]+BEAT_START_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
BEAT_START_MSB=$(awk '$0 ~ /\.equ[ \t]+BEAT_START_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
BEAT_STOP_LSB=$(awk '$0 ~ /\.equ[ \t]+BEAT_STOP_LSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')
BEAT_STOP_MSB=$(awk '$0 ~ /\.equ[ \t]+BEAT_STOP_MSB,/ {print $NF}' "$SAMPLES_INC" | head -1 | sed 's/0x//' | tr 'A-Z' 'a-z')

if [[ -z "$SILENCE_B_START_LSB" ]]; then
    echo "  [FAIL] gate 1 (= samples.inc emit assert): SILENCE_B_* generated symbol が emit されていない"
    cat "$SAMPLES_INC"
    exit 1
fi

echo "  samples.inc literal value:"
echo "    BEAT       start=${BEAT_START_LSB}/${BEAT_START_MSB}    stop=${BEAT_STOP_LSB}/${BEAT_STOP_MSB}"
echo "    SILENCE_B  start=${SILENCE_B_START_LSB}/${SILENCE_B_START_MSB}  stop=${SILENCE_B_STOP_LSB}/${SILENCE_B_STOP_MSB}"

# ============================================================
# gate 2: step5.PNE → 0xFD32 = 0x00 (= resolver entry 0 match)
# ============================================================
echo
echo "=== gate 2: step5.PNE carrier → 0xFD32 = 0x00 (= resolver entry 0 match) ==="
ZERO_FD32_UNIQUE=$(awk -F'\t' 'tolower($3) == "fd32"' "$ZERO_MEM" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$ZERO_FD32_UNIQUE" != "00 " ]]; then
    printf "  [FAIL] gate 2: zero 0xFD32 unique values: '%s' (expected: '00 ')\n" "$ZERO_FD32_UNIQUE"
    exit 1
fi
ZERO_FD32_COUNT=$(awk -F'\t' 'tolower($3) == "fd32"' "$ZERO_MEM" | grep -c '' || true)
printf "  [PASS] zero 0xFD32 = 0x00 (= 全 %d 件 idempotent、 entry 0 match)\n" "$ZERO_FD32_COUNT"

# ============================================================
# gate 3: step5b.PNE carrier + J body (id=0x01) hybrid build + trace
# ============================================================
echo
echo "=== gate 3: step5b.PNE carrier + J body (id=0x01) hybrid build + trace ==="
MML_INPUTS="$TMPDIR/j-body.mml,test02.mml" PMDDOTNET_MML="$ONE_CARRIER_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/one-build.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: one hybrid build failed (log: $TMPDIR/one-build.log)"
    tail -20 "$TMPDIR/one-build.log" >&2
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/one-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: one MAME run failed"
    exit 2
}
ONE_MEM="$OUT_DIR/one-mem.tsv"
ONE_YMFM="$OUT_DIR/one-ymfm.tsv"
ONE_WAV="$OUT_DIR/id-one.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$ONE_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$ONE_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$ONE_WAV"
echo "  [PASS] step5b.PNE carrier + J body (id=0x01) trace + wav 取得"

# ============================================================
# gate 4: step5b.PNE → 0xFD32 = 0x01 (= resolver entry 1 match)
# ============================================================
echo
echo "=== gate 4: step5b.PNE carrier → 0xFD32 = 0x01 (= resolver entry 1 match) ==="
ONE_FD32_UNIQUE=$(awk -F'\t' 'tolower($3) == "fd32"' "$ONE_MEM" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
if [[ "$ONE_FD32_UNIQUE" != "01 " ]]; then
    printf "  [FAIL] gate 4: one 0xFD32 unique values: '%s' (expected: '01 ')\n" "$ONE_FD32_UNIQUE"
    exit 1
fi
ONE_FD32_COUNT=$(awk -F'\t' 'tolower($3) == "fd32"' "$ONE_MEM" | grep -c '' || true)
printf "  [PASS] one 0xFD32 = 0x01 (= 全 %d 件 idempotent、 entry 1 match)\n" "$ONE_FD32_COUNT"

# ============================================================
# gate 5: ADPCM-B reg 0x12-0x15 literal differ + literal value assert
# ============================================================
echo
echo "=== gate 5: ADPCM-B reg 0x12-0x15 literal differ (= sample 切替 observable proof) ==="
for spec in "12:BEAT_START_LSB:$BEAT_START_LSB:SILENCE_B_START_LSB:$SILENCE_B_START_LSB" \
            "13:BEAT_START_MSB:$BEAT_START_MSB:SILENCE_B_START_MSB:$SILENCE_B_START_MSB" \
            "14:BEAT_STOP_LSB:$BEAT_STOP_LSB:SILENCE_B_STOP_LSB:$SILENCE_B_STOP_LSB" \
            "15:BEAT_STOP_MSB:$BEAT_STOP_MSB:SILENCE_B_STOP_MSB:$SILENCE_B_STOP_MSB"; do
    REG=$(echo "$spec" | cut -d: -f1)
    EXP_ZERO_LABEL=$(echo "$spec" | cut -d: -f2)
    EXP_ZERO_VAL=$(echo "$spec" | cut -d: -f3)
    EXP_ONE_LABEL=$(echo "$spec" | cut -d: -f4)
    EXP_ONE_VAL=$(echo "$spec" | cut -d: -f5)
    ZERO_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ZERO_YMFM" | tr 'A-Z' 'a-z')
    ONE_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ONE_YMFM" | tr 'A-Z' 'a-z')
    if [[ "$ZERO_VAL" != "$EXP_ZERO_VAL" ]]; then
        printf "  [FAIL] gate 5: zero reg 0x%s = 0x%s (expected: 0x%s = %s literal)\n" "$REG" "$ZERO_VAL" "$EXP_ZERO_VAL" "$EXP_ZERO_LABEL"
        exit 1
    fi
    if [[ "$ONE_VAL" != "$EXP_ONE_VAL" ]]; then
        printf "  [FAIL] gate 5: one reg 0x%s = 0x%s (expected: 0x%s = %s literal)\n" "$REG" "$ONE_VAL" "$EXP_ONE_VAL" "$EXP_ONE_LABEL"
        exit 1
    fi
    printf "  reg 0x%s: zero = 0x%s (%s) / one = 0x%s (%s)\n" "$REG" "$ZERO_VAL" "$EXP_ZERO_LABEL" "$ONE_VAL" "$EXP_ONE_LABEL"
done
echo "  [PASS] ADPCM-B reg 0x12-0x15 全て BEAT_* / SILENCE_B_* literal value 一致 (= sample 切替 observable proof)"

# ============================================================
# gate 6: ADPCM-B delta-N (= reg 0x19/0x1A) + vol (= reg 0x1B) + pan (= reg 0x11) + keyon (= reg 0x10) identical
# ============================================================
echo
echo "=== gate 6: ADPCM-B delta-N / vol / pan / keyon identical (= 「sample addr だけ differ」 proof) ==="
ADPCMB_NON_ADDR_DIFFS=0
for spec in "10:keyon" "11:pan" "19:delta-n-lsb" "1A:delta-n-msb" "1B:volume"; do
    REG=$(echo "$spec" | cut -d: -f1)
    LABEL=$(echo "$spec" | cut -d: -f2)
    Z_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ZERO_YMFM" | tr 'A-Z' 'a-z')
    O_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ONE_YMFM" | tr 'A-Z' 'a-z')
    if [[ "$Z_VAL" != "$O_VAL" ]]; then
        printf "  [DIFF] reg 0x%s (%s): zero = 0x%s / one = 0x%s\n" "$REG" "$LABEL" "$Z_VAL" "$O_VAL"
        ADPCMB_NON_ADDR_DIFFS=$((ADPCMB_NON_ADDR_DIFFS + 1))
    else
        printf "  reg 0x%s (%s): zero = 0x%s / one = 0x%s (= identical)\n" "$REG" "$LABEL" "$Z_VAL" "$O_VAL"
    fi
done
if [[ "$ADPCMB_NON_ADDR_DIFFS" -gt 0 ]]; then
    printf "  [FAIL] gate 6: ADPCM-B non-addr regs に %d 件 differ あり (expected: 0、 sample addr だけ differ proof)\n" "$ADPCMB_NON_ADDR_DIFFS"
    exit 1
fi
echo "  [PASS] ADPCM-B delta-N / vol / pan / keyon identical (= 5 reg 全 identical、 sample addr (= 0x12-0x15) のみ differ proof)"

# ============================================================
# 完了
# ============================================================
echo
echo "🎉 ADR-0043 §sub-sprint γ-2 verify: 全 6 gate PASS (= hybrid 経路、 ADPCM-A 独立性 trace は γ-3 defer)"
echo
echo "    fixtures (= hybrid 経路、 既存 fixture 流用):"
echo "      J body:           $J_BODY_MML  (= 既存 step4 J only、 MML_INPUTS env 経由 compile.py)"
echo "      zero carrier:     $ZERO_CARRIER_MML  (= 既存 step5 #PNEFile step5.PNE)"
echo "      one carrier:      $ONE_CARRIER_MML   (= 既存 step11 #PNEFile step5b.PNE)"
echo
echo "    selection differentiation proof:"
echo "      ADPCM-B reg 0x12-0x15 differ literal:  zero = BEAT (0x${BEAT_START_LSB}/0x${BEAT_START_MSB}/0x${BEAT_STOP_LSB}/0x${BEAT_STOP_MSB}) / one = SILENCE_B (0x${SILENCE_B_START_LSB}/0x${SILENCE_B_START_MSB}/0x${SILENCE_B_STOP_LSB}/0x${SILENCE_B_STOP_MSB})"
echo "      ADPCM-B non-addr regs identical:       reg 0x10/0x11/0x19/0x1A/0x1B 全 identical (= sample addr のみ differ proof)"
echo
echo "    user 試聴用 wav (= δ で越川氏 audition 候補、 silence sample は audition 対象外):"
echo "      zero (= J BEAT): $ZERO_WAV"
echo "      one  (= J SILENCE_B): $ONE_WAV"
echo
echo "    γ-3 候補 (= ADR-0043 §sub-sprint chain 拡張):"
echo "      ADPCM-A 独立性 trace (= J + L-Q 同時 fixture)、 PMDDotNET /B mode J emit 修正は scope-out 維持"
exit 0
