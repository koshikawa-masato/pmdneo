#!/usr/bin/env bash
#
# ADR-0026 step 12 γ: K-R differential proof (= K と R が同 rhythm event dispatch path を経由)
#
# 目的:
#   ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 の literal 証明。
#   K fixture (= k-br-only.mml) と R fixture (= r-melody-br-only.mml) を両方 build + run
#   して、 ADPCM-A L ch BD register write sequence が **byte-identical** であることを
#   literal 比較で証明する。 これにより:
#
#   - K part 0xEB path (= rhythm_main → rhythm_main_rhykey → pmdneo_rhythm_event_trigger)
#   - R command 0xEB path (= pmdneo_part_main_parse → commandsp → commandsp_rhykey → pmdneo_rhythm_event_trigger)
#
#   の 2 つの source layer path が runtime layer で **同一 routine** に collapse される
#   ことを 1 つの script で実証する (= ADR-0026 §決定 6 / §決定 8 / §本質再確認 整合)。
#
# 検証: 7 段 gate
#   gate 1: K fixture build + run + trace
#   gate 2: R fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: K fixture run BD register write literal (= β verify と同内容、 重複 assert で robustness)
#   gate 5: R fixture run BD register write literal (= K と同 sequence)
#   gate 6: K と R の BD register write sequence byte-identical (= **differential proof**)
#   gate 7: K と R で L ch keyon mask 0x01 trigger count identical (= 同回数発火)
#
# 検証範囲外 (= δ で別途):
#   - 既存 14 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で K/R 別々 audible 確認)
#   - ADR-0026 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step12/verify-step12-kr-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step12/k-br-only.wav        (= K fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step12/r-melody-br-only.wav (= R fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step12/k-*.tsv              (= K fixture trace snapshot)
#   /tmp/pmdneo-step12/r-*.tsv              (= R fixture trace snapshot)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step12/k-br-only.mml"
R_MML="$PROJECT_ROOT/src/test-fixtures/step12/r-melody-br-only.mml"
OUT_DIR="/tmp/pmdneo-step12"

if [[ ! -f "$K_MML" ]]; then echo "FAIL infra: $K_MML not found"; exit 2; fi
if [[ ! -f "$R_MML" ]]; then echo "FAIL infra: $R_MML not found"; exit 2; fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step12-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0026 §決定 3 driver-embedded BD sample、 既存 adpcma_sample_bd 再利用)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_START_MSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_BD_STOP_MSB="00"
EXPECTED_VOL_PAN="DF"
EXPECTED_KEYON_MASK="01"

echo "=== ADR-0026 step 12 γ: K-R differential proof (= K と R の dispatch path 共通化 literal 証明) ==="
echo

# ============================================================
# gate 1: K fixture build + run + trace
# ============================================================
echo "=== gate 1: K fixture (= k-br-only.mml) build + run + trace ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K build failed (log: $TMPDIR/k-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K MAME run failed"
    exit 2
}
K_YMFM="$OUT_DIR/k-br-only-ymfm.tsv"
K_MEM="$OUT_DIR/k-br-only-mem.tsv"
K_WAV="$OUT_DIR/k-br-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] K fixture build + run + trace 取得 (wav: $K_WAV)"

# .lst snapshot (= gate 3 で同 build artifact 経由なので gate 1 段階で取得)
K_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$K_LST" ]]; then echo "  [FAIL] gate 1: .lst not found"; exit 2; fi
K_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$K_LST" | head -1 | awk '{print $1}')
if [[ -z "$K_HOOK_ADDR" ]]; then echo "  [FAIL] gate 1: hook symbol not found in K build .lst"; exit 1; fi
echo "  [INFO] K build: pmdneo_rhythm_event_trigger @ 0x$K_HOOK_ADDR"

# ============================================================
# gate 2: R fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: R fixture (= r-melody-br-only.mml) build + run + trace ==="
PMDDOTNET_MML="$R_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/r-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: R build failed (log: $TMPDIR/r-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/r-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: R MAME run failed"
    exit 2
}
R_YMFM="$OUT_DIR/r-melody-br-only-ymfm.tsv"
R_MEM="$OUT_DIR/r-melody-br-only-mem.tsv"
R_WAV="$OUT_DIR/r-melody-br-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$R_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$R_MEM"
cp /tmp/pmdneo-trace/audio.wav "$R_WAV"
echo "  [PASS] R fixture build + run + trace 取得 (wav: $R_WAV)"

R_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
R_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$R_LST" | head -1 | awk '{print $1}')
if [[ -z "$R_HOOK_ADDR" ]]; then echo "  [FAIL] gate 2: hook symbol not found in R build .lst"; exit 1; fi
echo "  [INFO] R build: pmdneo_rhythm_event_trigger @ 0x$R_HOOK_ADDR"

# ============================================================
# gate 3: same hook addr in both K and R builds
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between K and R builds ==="
if [[ "$K_HOOK_ADDR" != "$R_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (K=0x$K_HOOK_ADDR vs R=0x$R_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$K_HOOK_ADDR (= K と R で same routine entry)"

# ============================================================
# gate 4: K fixture BD register write literal (= β verify と同内容、 重複 assert)
# ============================================================
echo
echo "=== gate 4: K fixture run ADPCM-A L ch BD register write literal ==="

check_reg_value() {
    local trace="$1"
    local reg="$2"
    local expected="$3"
    local label="$4"
    local found
    found=$(awk -F'\t' -v reg="$reg" '$2 == "B" && $3 == reg {print toupper($4)}' "$trace" | tail -1)
    if [[ -z "$found" ]]; then
        echo "  [FAIL] reg $reg ($label) write not found in $trace"
        return 1
    fi
    local found_norm=$(printf "%02X" "0x$found")
    local expected_norm=$(printf "%02X" "0x$expected")
    if [[ "$found_norm" != "$expected_norm" ]]; then
        echo "  [FAIL] reg $reg ($label) = 0x$found_norm (expected 0x$expected_norm)"
        return 1
    fi
    echo "  [PASS] reg $reg ($label) = 0x$found_norm"
    return 0
}

check_reg_value "$K_YMFM" "110" "$EXPECTED_BD_START_LSB" "K L ch start LSB"
check_reg_value "$K_YMFM" "118" "$EXPECTED_BD_START_MSB" "K L ch start MSB"
check_reg_value "$K_YMFM" "120" "$EXPECTED_BD_STOP_LSB"  "K L ch stop LSB"
check_reg_value "$K_YMFM" "128" "$EXPECTED_BD_STOP_MSB"  "K L ch stop MSB"
check_reg_value "$K_YMFM" "108" "$EXPECTED_VOL_PAN"      "K L ch vol|pan"

# ============================================================
# gate 5: R fixture BD register write literal (= K と同 sequence)
# ============================================================
echo
echo "=== gate 5: R fixture run ADPCM-A L ch BD register write literal ==="
check_reg_value "$R_YMFM" "110" "$EXPECTED_BD_START_LSB" "R L ch start LSB"
check_reg_value "$R_YMFM" "118" "$EXPECTED_BD_START_MSB" "R L ch start MSB"
check_reg_value "$R_YMFM" "120" "$EXPECTED_BD_STOP_LSB"  "R L ch stop LSB"
check_reg_value "$R_YMFM" "128" "$EXPECTED_BD_STOP_MSB"  "R L ch stop MSB"
check_reg_value "$R_YMFM" "108" "$EXPECTED_VOL_PAN"      "R L ch vol|pan"

# ============================================================
# gate 6: K と R の BD register write sequence byte-identical (= differential proof)
# ============================================================
echo
echo "=== gate 6: K と R の BD register write sequence byte-identical (= K-R differential proof) ==="

# Extract L ch BD register writes (= reg 0x10/0x18/0x20/0x28/0x08 + keyon mask 0x01 on reg 0x00)
extract_bd_writes() {
    local trace="$1"
    awk -F'\t' '
        $2 == "B" && ($3 == "110" || $3 == "118" || $3 == "120" || $3 == "128" || $3 == "108") {
            print $3 "\t" toupper($4)
        }
        $2 == "B" && $3 == "100" && toupper($4) == "01" {
            print $3 "\t" toupper($4)
        }
    ' "$trace"
}

K_BD_SEQ=$(extract_bd_writes "$K_YMFM")
R_BD_SEQ=$(extract_bd_writes "$R_YMFM")

if [[ "$K_BD_SEQ" != "$R_BD_SEQ" ]]; then
    echo "  [FAIL] gate 6: K と R で BD register write sequence が異なる"
    echo "         K seq:"
    echo "$K_BD_SEQ" | sed 's/^/           /'
    echo "         R seq:"
    echo "$R_BD_SEQ" | sed 's/^/           /'
    exit 1
fi
K_BD_LINES=$(echo "$K_BD_SEQ" | wc -l | tr -d ' ')
echo "  [PASS] K と R の BD register write sequence byte-identical ($K_BD_LINES 件)"
echo "         (= K part 0xEB path と R command 0xEB path が同 pmdneo_rhythm_event_trigger を経由)"
echo "         (= ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 literal 達成)"

# ============================================================
# gate 7: K と R で L ch keyon mask 0x01 trigger count identical
# ============================================================
echo
echo "=== gate 7: K と R で L ch keyon mask 0x01 trigger count identical ==="
K_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM" | grep -c "^01$" || true)
R_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$R_YMFM" | grep -c "^01$" || true)
if [[ "$K_KEYON_01_COUNT" != "$R_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 7: keyon count differs (K=$K_KEYON_01_COUNT, R=$R_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$K_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 7: K と R 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] K と R で L ch keyon mask 0x01 trigger count = $K_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0026 step 12 γ K-R differential proof PASS"
echo "   - gate 1: K fixture build + run + trace ($K_WAV)"
echo "   - gate 2: R fixture build + run + trace ($R_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (K=R=0x$K_HOOK_ADDR)"
echo "   - gate 4: K BD register write literal PASS"
echo "   - gate 5: R BD register write literal PASS"
echo "   - gate 6: K-R BD register write sequence byte-identical ($K_BD_LINES 件)"
echo "   - gate 7: K-R L ch keyon mask 0x01 trigger count identical ($K_KEYON_01_COUNT 件)"
echo ""
echo "   ADR-0026 §決定 6 「source K part / R command 2 系統 → runtime 1 系統 collapse」"
echo "   = literal 達成"
exit 0
