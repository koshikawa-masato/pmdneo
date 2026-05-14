#!/usr/bin/env bash
#
# ADR-0028 step 14 γ: K-HH vs R-HH differential proof (= K と R が同 HH trigger dispatch path を経由)
#
# 目的:
#   ADR-0028 §決定 4/8/9 「dispatch path 1 本化は 3 drum 段下で literal 維持」 の literal 証明。
#   K-HH fixture (= k-hr-only.mml) と R-HH fixture (= r-melody-hr-only.mml) を両方 build + run
#   して、 ADPCM-A L ch HH register write sequence が **byte-identical** であることを
#   literal 比較で証明する。 これにより:
#
#   - K part 0xEB HH path (= rhythm_main → rhythm_main_rhykey → pmdneo_rhythm_event_trigger → bit 3 → _rhythm_event_hh_trigger)
#   - R command 0xEB HH path (= pmdneo_part_main_parse → commandsp → commandsp_rhykey → pmdneo_rhythm_event_trigger → bit 3 → _rhythm_event_hh_trigger)
#
#   の 2 つの source layer path が runtime layer で **同一 routine** に collapse される
#   ことを、 HH trigger という 3 drum 段拡張下でも維持されていることを literal で固定する
#   (= ADR-0026 §決定 6 / §決定 8 + ADR-0027 §決定 4 / §決定 8 / §決定 9 + ADR-0028 §決定 4 / §決定 8 / §決定 9 整合)。
#
#   fixture 命名注記: `hr` = `\h` + `r`(= rest) fixture pattern。 「hi-hat」 略ではない (= 既存 `br` / `sr` pattern 同一規律、 ADR-0028 §決定 5 / 軸 2 整合)。
#
#   Step 12 K-BD vs R-BD differential proof (= verify-step12-kr-differential.sh) + Step 13 K-SD vs R-SD differential proof (= verify-step13-kr-sd-differential.sh) の HH 版。
#
# 検証: 7 段 gate
#   gate 1: K-HH fixture build + run + trace
#   gate 2: R-HH fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: K-HH fixture run HH register write literal (= β verify と同内容、 重複 assert)
#   gate 5: R-HH fixture run HH register write literal (= K-HH と同 sequence)
#   gate 6: K-HH と R-HH の HH register write sequence byte-identical (= **differential proof**)
#   gate 7: K-HH と R-HH で L ch keyon mask 0x01 trigger count identical (= 同回数発火)
#
# 検証範囲外 (= δ で別途):
#   - BD vs HH differential proof (= verify-step14-bd-hh-differential.sh、 γ 同 commit)
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で K-HH / R-HH 別々 audible 確認)
#   - ADR-0028 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step14/verify-step14-kr-hh-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step14/k-hr-only.wav         (= K-HH fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step14/r-melody-hr-only.wav  (= R-HH fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step14/k-hr-*.tsv            (= K-HH fixture trace snapshot)
#   /tmp/pmdneo-step14/r-melody-hr-*.tsv     (= R-HH fixture trace snapshot)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step14/k-hr-only.mml"
R_MML="$PROJECT_ROOT/src/test-fixtures/step14/r-melody-hr-only.mml"
OUT_DIR="/tmp/pmdneo-step14"

if [[ ! -f "$K_MML" ]]; then echo "FAIL infra: $K_MML not found"; exit 2; fi
if [[ ! -f "$R_MML" ]]; then echo "FAIL infra: $R_MML not found"; exit 2; fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step14-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0028 §決定 3 driver-embedded HH sample、 既存 adpcma_sample_hh symbol reuse)
EXPECTED_HH_START_LSB="07"
EXPECTED_HH_START_MSB="00"
EXPECTED_HH_STOP_LSB="09"
EXPECTED_HH_STOP_MSB="00"
EXPECTED_VOL_PAN="DF"
EXPECTED_KEYON_MASK="01"

echo "=== ADR-0028 step 14 γ: K-HH vs R-HH differential proof (= K-HH と R-HH の dispatch path 共通化 literal 証明) ==="
echo

# ============================================================
# gate 1: K-HH fixture build + run + trace
# ============================================================
echo "=== gate 1: K-HH fixture (= k-hr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-hh-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-HH build failed (log: $TMPDIR/k-hh-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-hh-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-HH MAME run failed"
    exit 2
}
K_YMFM="$OUT_DIR/k-hr-only-ymfm.tsv"
K_MEM="$OUT_DIR/k-hr-only-mem.tsv"
K_WAV="$OUT_DIR/k-hr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] K-HH fixture build + run + trace 取得 (wav: $K_WAV)"

# .lst snapshot
K_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$K_LST" ]]; then echo "  [FAIL] gate 1: .lst not found"; exit 2; fi
K_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$K_LST" | head -1 | awk '{print $1}')
if [[ -z "$K_HOOK_ADDR" ]]; then echo "  [FAIL] gate 1: hook symbol not found in K-HH build .lst"; exit 1; fi
echo "  [INFO] K-HH build: pmdneo_rhythm_event_trigger @ 0x$K_HOOK_ADDR"
K_HH_ADDR=$(grep -E "_rhythm_event_hh_trigger:" "$K_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-HH build: _rhythm_event_hh_trigger @ 0x$K_HH_ADDR"

# ============================================================
# gate 2: R-HH fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: R-HH fixture (= r-melody-hr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$R_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/r-hh-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-HH build failed (log: $TMPDIR/r-hh-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/r-hh-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-HH MAME run failed"
    exit 2
}
R_YMFM="$OUT_DIR/r-melody-hr-only-ymfm.tsv"
R_MEM="$OUT_DIR/r-melody-hr-only-mem.tsv"
R_WAV="$OUT_DIR/r-melody-hr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$R_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$R_MEM"
cp /tmp/pmdneo-trace/audio.wav "$R_WAV"
echo "  [PASS] R-HH fixture build + run + trace 取得 (wav: $R_WAV)"

R_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
R_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$R_LST" | head -1 | awk '{print $1}')
if [[ -z "$R_HOOK_ADDR" ]]; then echo "  [FAIL] gate 2: hook symbol not found in R-HH build .lst"; exit 1; fi
echo "  [INFO] R-HH build: pmdneo_rhythm_event_trigger @ 0x$R_HOOK_ADDR"
R_HH_ADDR=$(grep -E "_rhythm_event_hh_trigger:" "$R_LST" | head -1 | awk '{print $1}')
echo "  [INFO] R-HH build: _rhythm_event_hh_trigger @ 0x$R_HH_ADDR"

# ============================================================
# gate 3: same hook addr in both K-HH and R-HH builds
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between K-HH and R-HH builds ==="
if [[ "$K_HOOK_ADDR" != "$R_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (K-HH=0x$K_HOOK_ADDR vs R-HH=0x$R_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$K_HOOK_ADDR (= K-HH と R-HH で same routine entry)"
if [[ "$K_HH_ADDR" != "$R_HH_ADDR" ]]; then
    echo "  [FAIL] gate 3: HH trigger addr differs (K-HH=0x$K_HH_ADDR vs R-HH=0x$R_HH_ADDR)"
    exit 1
fi
echo "  [PASS] HH trigger addr identical = 0x$K_HH_ADDR (= K-HH と R-HH で same HH routine)"

# ============================================================
# gate 4: K-HH fixture HH register write literal
# ============================================================
echo
echo "=== gate 4: K-HH fixture run ADPCM-A L ch HH register write literal ==="

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

check_reg_value "$K_YMFM" "110" "$EXPECTED_HH_START_LSB" "K-HH L ch start LSB"
check_reg_value "$K_YMFM" "118" "$EXPECTED_HH_START_MSB" "K-HH L ch start MSB"
check_reg_value "$K_YMFM" "120" "$EXPECTED_HH_STOP_LSB"  "K-HH L ch stop LSB"
check_reg_value "$K_YMFM" "128" "$EXPECTED_HH_STOP_MSB"  "K-HH L ch stop MSB"
check_reg_value "$K_YMFM" "108" "$EXPECTED_VOL_PAN"      "K-HH L ch vol|pan"

# ============================================================
# gate 5: R-HH fixture HH register write literal (= K-HH と同 sequence)
# ============================================================
echo
echo "=== gate 5: R-HH fixture run ADPCM-A L ch HH register write literal ==="
check_reg_value "$R_YMFM" "110" "$EXPECTED_HH_START_LSB" "R-HH L ch start LSB"
check_reg_value "$R_YMFM" "118" "$EXPECTED_HH_START_MSB" "R-HH L ch start MSB"
check_reg_value "$R_YMFM" "120" "$EXPECTED_HH_STOP_LSB"  "R-HH L ch stop LSB"
check_reg_value "$R_YMFM" "128" "$EXPECTED_HH_STOP_MSB"  "R-HH L ch stop MSB"
check_reg_value "$R_YMFM" "108" "$EXPECTED_VOL_PAN"      "R-HH L ch vol|pan"

# ============================================================
# gate 6: K-HH と R-HH の HH register write sequence byte-identical (= differential proof)
# ============================================================
echo
echo "=== gate 6: K-HH と R-HH の HH register write sequence byte-identical (= K-R HH differential proof) ==="

# Extract L ch HH register writes (= reg 0x10/0x18/0x20/0x28/0x08 + keyon mask 0x01 on reg 0x00)
extract_hh_writes() {
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

K_HH_SEQ=$(extract_hh_writes "$K_YMFM")
R_HH_SEQ=$(extract_hh_writes "$R_YMFM")

if [[ "$K_HH_SEQ" != "$R_HH_SEQ" ]]; then
    echo "  [FAIL] gate 6: K-HH と R-HH で HH register write sequence が異なる"
    echo "         K-HH seq:"
    echo "$K_HH_SEQ" | sed 's/^/           /'
    echo "         R-HH seq:"
    echo "$R_HH_SEQ" | sed 's/^/           /'
    exit 1
fi
K_HH_LINES=$(echo "$K_HH_SEQ" | wc -l | tr -d ' ')
echo "  [PASS] K-HH と R-HH の HH register write sequence byte-identical ($K_HH_LINES 件)"
echo "         (= K part 0xEB HH path と R command 0xEB HH path が同 pmdneo_rhythm_event_trigger を経由)"
echo "         (= ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 が 3 drum 段拡張下で literal 維持)"
echo "         (= ADR-0028 §決定 8 「dispatch path は drum 種拡張で増やさない」 literal 達成)"

# ============================================================
# gate 7: K-HH と R-HH で L ch keyon mask 0x01 trigger count identical
# ============================================================
echo
echo "=== gate 7: K-HH と R-HH で L ch keyon mask 0x01 trigger count identical ==="
K_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM" | grep -c "^01$" || true)
R_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$R_YMFM" | grep -c "^01$" || true)
if [[ "$K_KEYON_01_COUNT" != "$R_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 7: keyon count differs (K-HH=$K_KEYON_01_COUNT, R-HH=$R_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$K_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 7: K-HH と R-HH 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] K-HH と R-HH で L ch keyon mask 0x01 trigger count = $K_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0028 step 14 γ K-HH vs R-HH differential proof PASS"
echo "   - gate 1: K-HH fixture build + run + trace ($K_WAV)"
echo "   - gate 2: R-HH fixture build + run + trace ($R_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (K-HH=R-HH=0x$K_HOOK_ADDR)"
echo "             _rhythm_event_hh_trigger addr identical (K-HH=R-HH=0x$K_HH_ADDR)"
echo "   - gate 4: K-HH HH register write literal PASS"
echo "   - gate 5: R-HH HH register write literal PASS"
echo "   - gate 6: K-HH/R-HH HH register write sequence byte-identical ($K_HH_LINES 件)"
echo "   - gate 7: K-HH/R-HH L ch keyon mask 0x01 trigger count identical ($K_KEYON_01_COUNT 件)"
echo ""
echo "   ADR-0028 §決定 8 「dispatch path は drum 種拡張で増やさない」 = literal 達成"
echo "   (= drum 種が b+s → b+s+h に拡張されても K-R dispatch path 1 本化が維持)"
exit 0
