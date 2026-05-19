#!/usr/bin/env bash
#
# ADR-0043 §sub-sprint γ-3: ADPCM-A 軸独立性 trace (= ADPCM-B sample_table_id 切替時の ADPCM-A 副作用ゼロ proof、 8 gate)
#
# 目的:
#   ADR-0043 §決定 1 γ 完了判定の残り「ADPCM-A 軸との独立性 (= ADPCM-A 側 register
#   write 不変) trace 確認」 完全充足。 γ-2 hybrid 経路 (= J body compile.py + carrier
#   PMDDotNET .MN) を踏襲し、 γ-2 6 gate + ADPCM-A 観測 2 gate 拡張で 8 gate 構成。
#
#   step5.PNE 経路 (= 0xFD32=0x00 → J table A → beat) と step5b.PNE 経路 (= 0xFD32=0x01
#   → J table B → silence_b) の register write trace を比較し、 ADPCM-B sample 切替
#   (= reg 0x12-0x15 differ) + ADPCM-A M-Q ch (= ch 1-5) addr regs byte-identical
#   (= ADPCM-B 軸切替が ADPCM-A 非対象 ch に副作用なし proof) + ADPCM-A keyon count
#   identical (= silent ではない literal、 同回数鳴る) の 8 gate 同時 assert。
#
#   L ch (= ch 0、 reg 0x10/0x18/0x20/0x28) は step5/step5b で ADPCM-A 軸 sample_table_id
#   切替の影響を受ける (= ADR-0025 既実証、 step11 verify-step11-multi-table.sh gate 5
#   literal) ため gate 7 対象外、 M-Q ch (= ch 1-5、 step11 gate 6 同 pattern) のみ
#   byte-identical assert で「ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ」 を proof。
#
#   step11 verify pattern (= ADR-0025 ADPCM-A multi-table proof) を γ-3 で literal 流用。
#
# Codex layer 2 approve (= round 1 approve、 案 A 採用):
#   - gate 7 表記 = ADPCM-A M-Q ch (= ch 1-5、 20 reg) byte-identical (= L ch 含む 6 ch
#     ではない、 step5/step5b sample_table_id 切替で L ch differ 既実証)
#   - driver source touch なし (= γ-2 完了状態の driver で十分、 verify only sub-sprint)
#   - γ complete 宣言は同 PR 内別 commit、 ADR-0043 Accepted 移行は δ 完了待ち
#
# 前提:
#   - PMDNEO_ROOT で build + run-mame infra が動く
#   - src/test-fixtures/step4/j-part-minimum.mml (= 既存 J only fixture 流用)
#   - src/test-fixtures/step5/l-q-rhythm-song.mml (= 既存 carrier #PNEFile step5.PNE)
#   - src/test-fixtures/step11/l-q-rhythm-song-step5b.mml (= 既存 carrier #PNEFile step5b.PNE)
#   - 全 fixture + driver は γ-2 完了状態 (= PR #31 MERGED 7bd724bc)
#
# 使い方:
#   bash src/test-fixtures/axis-c/verify-gamma-3-axis-independence.sh
#
# 副作用:
#   /tmp/pmdneo-axis-c-gamma-3/id-zero.wav      (= step5.PNE carrier 録音、 4 秒)
#   /tmp/pmdneo-axis-c-gamma-3/id-one.wav       (= step5b.PNE carrier 録音、 4 秒)
#   /tmp/pmdneo-axis-c-gamma-3/*.tsv            (= trace snapshot、 後続調査用)
#
# Exit code:
#   0 = PASS (= 全 8 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

J_BODY_MML="$PROJECT_ROOT/src/test-fixtures/step4/j-part-minimum.mml"
ZERO_CARRIER_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
ONE_CARRIER_MML="$PROJECT_ROOT/src/test-fixtures/step11/l-q-rhythm-song-step5b.mml"
SAMPLES_INC="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/assets/samples.inc"
OUT_DIR="/tmp/pmdneo-axis-c-gamma-3"

for f in "$J_BODY_MML" "$ZERO_CARRIER_MML" "$ONE_CARRIER_MML"; do
    if [[ ! -f "$f" ]]; then
        echo "FAIL infra: fixture not found: $f"
        exit 2
    fi
done

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-axis-c-gamma-3-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

cp "$J_BODY_MML" "$TMPDIR/j-body.mml"

echo "=== ADR-0043 §sub-sprint γ-3: ADPCM-A 軸独立性 trace (= 8 gate、 hybrid 経路 + ADPCM-A 観測拡張) ==="
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

echo "  samples.inc literal value: BEAT ${BEAT_START_LSB}/${BEAT_START_MSB}/${BEAT_STOP_LSB}/${BEAT_STOP_MSB} + SILENCE_B ${SILENCE_B_START_LSB}/${SILENCE_B_START_MSB}/${SILENCE_B_STOP_LSB}/${SILENCE_B_STOP_MSB}"

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
# gate 5: ADPCM-B reg 0x12-0x15 BEAT vs SILENCE_B literal differ (= γ-2 gate 5 踏襲)
# ============================================================
echo
echo "=== gate 5: ADPCM-B reg 0x12-0x15 BEAT vs SILENCE_B literal differ (= γ-2 gate 5 踏襲) ==="
for spec in "12:BEAT_START_LSB:$BEAT_START_LSB:SILENCE_B_START_LSB:$SILENCE_B_START_LSB" \
            "13:BEAT_START_MSB:$BEAT_START_MSB:SILENCE_B_START_MSB:$SILENCE_B_START_MSB" \
            "14:BEAT_STOP_LSB:$BEAT_STOP_LSB:SILENCE_B_STOP_LSB:$SILENCE_B_STOP_LSB" \
            "15:BEAT_STOP_MSB:$BEAT_STOP_MSB:SILENCE_B_STOP_MSB:$SILENCE_B_STOP_MSB"; do
    REG=$(echo "$spec" | cut -d: -f1)
    EXP_ZERO_VAL=$(echo "$spec" | cut -d: -f3)
    EXP_ONE_VAL=$(echo "$spec" | cut -d: -f5)
    ZERO_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ZERO_YMFM" | tr 'A-Z' 'a-z')
    ONE_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ONE_YMFM" | tr 'A-Z' 'a-z')
    if [[ "$ZERO_VAL" != "$EXP_ZERO_VAL" ]]; then
        printf "  [FAIL] gate 5: zero reg 0x%s = 0x%s (expected: 0x%s)\n" "$REG" "$ZERO_VAL" "$EXP_ZERO_VAL"
        exit 1
    fi
    if [[ "$ONE_VAL" != "$EXP_ONE_VAL" ]]; then
        printf "  [FAIL] gate 5: one reg 0x%s = 0x%s (expected: 0x%s)\n" "$REG" "$ONE_VAL" "$EXP_ONE_VAL"
        exit 1
    fi
done
echo "  [PASS] ADPCM-B reg 0x12-0x15 全て BEAT_* / SILENCE_B_* literal value 一致"

# ============================================================
# gate 6: ADPCM-B delta-N / vol / pan / keyon identical (= γ-2 gate 6 踏襲)
# ============================================================
echo
echo "=== gate 6: ADPCM-B delta-N / vol / pan / keyon identical (= γ-2 gate 6 踏襲) ==="
ADPCMB_NON_ADDR_DIFFS=0
for spec in "10:keyon" "11:pan" "19:delta-n-lsb" "1A:delta-n-msb" "1B:volume"; do
    REG=$(echo "$spec" | cut -d: -f1)
    LABEL=$(echo "$spec" | cut -d: -f2)
    Z_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ZERO_YMFM" | tr 'A-Z' 'a-z')
    O_VAL=$(awk -F'\t' -v r="$REG" '$2 == "A" && $3 == r {val=$4} END {print val}' "$ONE_YMFM" | tr 'A-Z' 'a-z')
    if [[ "$Z_VAL" != "$O_VAL" ]]; then
        printf "  [DIFF] reg 0x%s (%s): zero = 0x%s / one = 0x%s\n" "$REG" "$LABEL" "$Z_VAL" "$O_VAL"
        ADPCMB_NON_ADDR_DIFFS=$((ADPCMB_NON_ADDR_DIFFS + 1))
    fi
done
if [[ "$ADPCMB_NON_ADDR_DIFFS" -gt 0 ]]; then
    printf "  [FAIL] gate 6: ADPCM-B non-addr regs に %d 件 differ あり (expected: 0)\n" "$ADPCMB_NON_ADDR_DIFFS"
    exit 1
fi
echo "  [PASS] ADPCM-B delta-N / vol / pan / keyon identical (= 5 reg 全 identical)"

# ============================================================
# gate 7: ADPCM-A M-Q ch (= ch 1-5) addr regs byte-identical (= step11 gate 6 pattern、 ADPCM-B 軸切替が ADPCM-A 非対象 ch に副作用なし proof)
# ============================================================
echo
echo "=== gate 7: ADPCM-A M-Q ch (= ch 1-5) addr regs byte-identical (= 20 reg、 ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ proof) ==="
# ADPCM-A M-Q ch (= ch 1-5) addr regs (= port B reg 0x11-0x15 / 0x19-0x1D / 0x21-0x25 / 0x29-0x2D)
# ymfm-trace では port B prefix "1" 付与: "111"-"115" / "119"-"11D" / "121"-"125" / "129"-"12D"
# (注: L ch = ch 0 = reg 0x10/0x18/0x20/0x28 = "110"/"118"/"120"/"128" は step5/step5b 切替で
#  ADPCM-A 軸 sample_table_id 切替 = ADR-0025 既実証 = differ するため gate 7 対象外。
#  γ-3 は「ADPCM-B 軸切替が ADPCM-A 非対象 ch (= M-Q ch 1-5) に副作用ゼロ」 を proof する)
MQ_DIFFS=0
for reg in 111 112 113 114 115 119 11A 11B 11C 11D 121 122 123 124 125 129 12A 12B 12C 12D; do
    Z_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$ZERO_YMFM" | sort -u | head -1)
    O_VAL=$(awk -F'\t' -v r="$reg" '$2 == "B" && $3 == r {print tolower($4)}' "$ONE_YMFM" | sort -u | head -1)
    if [[ "$Z_VAL" != "$O_VAL" ]]; then
        printf "  [DIFF] reg 0x%s: zero = 0x%s / one = 0x%s\n" "${reg:1}" "$Z_VAL" "$O_VAL"
        MQ_DIFFS=$((MQ_DIFFS + 1))
    fi
done
if [[ "$MQ_DIFFS" -gt 0 ]]; then
    printf "  [FAIL] gate 7: ADPCM-A M-Q ch addr regs に %d 件 differ あり (expected: 0、 ADPCM-B 軸 → ADPCM-A 副作用ゼロ proof violation)\n" "$MQ_DIFFS"
    exit 1
fi
echo "  [PASS] ADPCM-A M-Q ch addr regs identical (= 20 reg × ch 1-5 で 0 件 differ、 ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ proof)"

# ============================================================
# gate 8: ADPCM-A keyon count identical (= step11 gate 7 pattern、 silent ではない literal、 同回数鳴る)
# ============================================================
echo
echo "=== gate 8: ADPCM-A keyon count identical (= step11 gate 7 pattern、 silent ではない literal) ==="
# port B reg 0x00 = ADPCM-A keyon control (= ymfm "100" prefix)
ZERO_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$ZERO_YMFM")
ONE_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" {cnt++} END {print cnt+0}' "$ONE_YMFM")
printf "  zero ADPCM-A keyon trigger count: %d\n" "$ZERO_KEYON"
printf "  one  ADPCM-A keyon trigger count: %d\n" "$ONE_KEYON"
if [[ "$ZERO_KEYON" -ne "$ONE_KEYON" ]]; then
    printf "  [FAIL] gate 8: ADPCM-A keyon count differ (= zero %d / one %d)\n" "$ZERO_KEYON" "$ONE_KEYON"
    exit 1
fi
if [[ "$ZERO_KEYON" -lt 30 ]]; then
    printf "  [FAIL] gate 8: ADPCM-A keyon count too low (= zero %d < 30、 expected: ~41 from step11 baseline)\n" "$ZERO_KEYON"
    exit 1
fi
echo "  [PASS] ADPCM-A keyon count identical: $ZERO_KEYON (= 同じ回数鳴る、 silent ではない、 selection differentiation 維持)"

# ============================================================
# 完了
# ============================================================
echo
echo "🎉 ADR-0043 §sub-sprint γ-3 verify: 全 8 gate PASS (= ADPCM-A 軸独立性 trace 完全成立)"
echo
echo "    fixtures (= γ-2 hybrid 経路完全踏襲、 既存 fixture 流用):"
echo "      J body:           $J_BODY_MML"
echo "      zero carrier:     $ZERO_CARRIER_MML"
echo "      one carrier:      $ONE_CARRIER_MML"
echo
echo "    axis independence proof (= γ-3 完了判定):"
echo "      ADPCM-A M-Q ch (= ch 1-5) addr regs identical: 20 reg で 0 件 differ (= ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ)"
echo "      ADPCM-A keyon count identical:                  $ZERO_KEYON (= 同じ回数鳴る、 silent ではない)"
echo "      ADPCM-B sample 切替 + ADPCM-A 軸独立性 同時成立 = ADR-0043 §決定 1 γ 完全充足"
echo
echo "    user 試聴用 wav (= δ で越川氏 audition 候補、 γ-3 verify only sub-sprint):"
echo "      zero (= J BEAT + L-Q ADPCM-A 6 ch step5.PNE 経路): $ZERO_WAV"
echo "      one  (= J SILENCE_B + L-Q ADPCM-A 6 ch step5b.PNE 経路): $ONE_WAV"
echo
echo "    次 step: γ 全体 complete 宣言 (= γ-1 + γ-2 + γ-3 全 sub-sprint 完了) → δ statement audio gate (= 越川氏 audition、 永久 user scope) → ADR-0043 Draft → Accepted 移行 (= δ 完了後)"
exit 0
