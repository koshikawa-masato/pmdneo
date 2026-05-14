#!/usr/bin/env bash
#
# ADR-0031 step 17 γ: K-RIM vs R-RIM byte-identical proof (= K と R が同 RIM trigger dispatch path を経由 = full 6 drum completion で K=R 成立)
#
# 目的:
#   ADR-0031 §決定 4/8/9 「dispatch path 1 本化は 6 drum 段 = full PMD drum set 下で literal 維持」 の literal 証明。
#   K-RIM fixture (= k-ir-only.mml) と R-RIM fixture (= r-melody-ir-only.mml) を両方 build + run
#   して、 ADPCM-A L ch RIM register write sequence が **byte-identical** であることを
#   literal 比較で証明する。 これにより:
#
#   - K part 0xEB RIM path (= rhythm_main → rhythm_main_rhykey → pmdneo_rhythm_event_trigger → bit 5 → _rhythm_event_rim_trigger)
#   - R command 0xEB RIM path (= pmdneo_part_main_parse → commandsp → commandsp_rhykey → pmdneo_rhythm_event_trigger → bit 5 → _rhythm_event_rim_trigger)
#
#   の 2 つの source layer path が runtime layer で **同一 routine** に collapse される
#   ことを、 RIM trigger という 6 drum 段拡張下 (= full PMD drum set) でも維持されていることを
#   literal で固定する (= ADR-0026 §決定 6 / §決定 8 + ADR-0027 §決定 4 / §決定 8 / §決定 9 + ADR-0028 §決定 4 / §決定 8 / §決定 9 + ADR-0029 §決定 4 / §決定 8 / §決定 9 + ADR-0030 §決定 4 / §決定 8 / §決定 9 + ADR-0031 §決定 4 / §決定 8 / §決定 9 整合)。
#
#   fixture 命名注記: `ir` = `\i` + `r`(= rest) fixture pattern。 「RIM」 略ではない (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern 同一規律、 ADR-0031 §決定 5 / 軸 2 整合)。
#
#   PMDDotNET 内部名 `rimset` と PMDNEO 側 wording RIM は実質一致 (= ADR-0030 `tamset` legacy naming のような wording 分離なし、 ADR-0031 §決定 3 「用語対応表」 + §Annex A-1 literal)。
#
#   Step 12 K-BD vs R-BD differential proof + Step 13 K-SD vs R-SD differential proof + Step 14 K-HH vs R-HH differential proof + Step 15 K-CYM vs R-CYM differential proof + Step 16 K-TOM vs R-TOM differential proof の RIM 版 = **full 6 drum completion で K-R dispatch path 1 本化が最終的に literal 保証**。
#
# 検証: 7 段 gate
#   gate 1: K-RIM fixture build + run + trace
#   gate 2: R-RIM fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力) + _rhythm_event_rim_trigger 同 addr
#   gate 4: K-RIM fixture run RIM register write literal (= β verify と同内容、 重複 assert)
#   gate 5: R-RIM fixture run RIM register write literal (= K-RIM と同 sequence)
#   gate 6: K-RIM と R-RIM の RIM register write sequence byte-identical (= **differential proof**)
#   gate 7: K-RIM と R-RIM で L ch keyon mask 0x01 trigger count identical (= 同回数発火)
#
# 検証範囲外 (= δ で別途):
#   - BD vs RIM differential proof (= verify-step17-bd-vs-rim-differential.sh、 γ 同 commit)
#   - TOM vs RIM differential proof (= verify-step17-tom-vs-rim-differential.sh、 γ 同 commit)
#   - SD vs RIM / CYM vs RIM / HH vs RIM differential → ADR-0031 §verify gate Gate 5/6 注記で推移的処理、 explicit gate なし
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で K-RIM / R-RIM 別々 audible 確認)
#   - ADR-0031 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step17/verify-step17-kr-rim-byte-identical.sh
#
# 副作用:
#   /tmp/pmdneo-step17/k-ir-only.wav         (= K-RIM fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step17/r-melody-ir-only.wav  (= R-RIM fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step17/k-ir-*.tsv            (= K-RIM fixture trace snapshot)
#   /tmp/pmdneo-step17/r-melody-ir-*.tsv     (= R-RIM fixture trace snapshot)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step17/k-ir-only.mml"
R_MML="$PROJECT_ROOT/src/test-fixtures/step17/r-melody-ir-only.mml"
OUT_DIR="/tmp/pmdneo-step17"

if [[ ! -f "$K_MML" ]]; then echo "FAIL infra: $K_MML not found"; exit 2; fi
if [[ ! -f "$R_MML" ]]; then echo "FAIL infra: $R_MML not found"; exit 2; fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step17-gamma-kr-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0031 §決定 3 driver-embedded RIM sample、 既存 adpcma_sample_rim symbol reuse)
EXPECTED_RIM_START_LSB="0a"              # (= RIM_START_LSB)
EXPECTED_RIM_START_MSB="00"              # (= RIM_START_MSB)
EXPECTED_RIM_STOP_LSB="0b"               # (= RIM_STOP_LSB)
EXPECTED_RIM_STOP_MSB="00"               # (= RIM_STOP_MSB)
EXPECTED_VOL_PAN="DF"
EXPECTED_KEYON_MASK="01"

echo "=== ADR-0031 step 17 γ: K-RIM vs R-RIM byte-identical proof (= K-RIM と R-RIM の dispatch path 共通化 literal 証明 = full 6 drum completion で K=R 成立) ==="
echo

# ============================================================
# gate 1: K-RIM fixture build + run + trace
# ============================================================
echo "=== gate 1: K-RIM fixture (= k-ir-only.mml) build + run + trace ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-rim-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-RIM build failed (log: $TMPDIR/k-rim-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-rim-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-RIM MAME run failed"
    exit 2
}
K_YMFM="$OUT_DIR/k-ir-only-ymfm.tsv"
K_MEM="$OUT_DIR/k-ir-only-mem.tsv"
K_WAV="$OUT_DIR/k-ir-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] K-RIM fixture build + run + trace 取得 (wav: $K_WAV)"

# .lst snapshot
K_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$K_LST" ]]; then echo "  [FAIL] gate 1: .lst not found"; exit 2; fi
K_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$K_LST" | head -1 | awk '{print $1}')
if [[ -z "$K_HOOK_ADDR" ]]; then echo "  [FAIL] gate 1: hook symbol not found in K-RIM build .lst"; exit 1; fi
echo "  [INFO] K-RIM build: pmdneo_rhythm_event_trigger @ 0x$K_HOOK_ADDR"
K_RIM_ADDR=$(grep -E "_rhythm_event_rim_trigger:" "$K_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-RIM build: _rhythm_event_rim_trigger @ 0x$K_RIM_ADDR"

# ============================================================
# gate 2: R-RIM fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: R-RIM fixture (= r-melody-ir-only.mml) build + run + trace ==="
PMDDOTNET_MML="$R_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/r-rim-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-RIM build failed (log: $TMPDIR/r-rim-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/r-rim-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-RIM MAME run failed"
    exit 2
}
R_YMFM="$OUT_DIR/r-melody-ir-only-ymfm.tsv"
R_MEM="$OUT_DIR/r-melody-ir-only-mem.tsv"
R_WAV="$OUT_DIR/r-melody-ir-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$R_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$R_MEM"
cp /tmp/pmdneo-trace/audio.wav "$R_WAV"
echo "  [PASS] R-RIM fixture build + run + trace 取得 (wav: $R_WAV)"

R_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
R_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$R_LST" | head -1 | awk '{print $1}')
if [[ -z "$R_HOOK_ADDR" ]]; then echo "  [FAIL] gate 2: hook symbol not found in R-RIM build .lst"; exit 1; fi
echo "  [INFO] R-RIM build: pmdneo_rhythm_event_trigger @ 0x$R_HOOK_ADDR"
R_RIM_ADDR=$(grep -E "_rhythm_event_rim_trigger:" "$R_LST" | head -1 | awk '{print $1}')
echo "  [INFO] R-RIM build: _rhythm_event_rim_trigger @ 0x$R_RIM_ADDR"

# ============================================================
# gate 3: same hook addr in both K-RIM and R-RIM builds
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between K-RIM and R-RIM builds ==="
if [[ "$K_HOOK_ADDR" != "$R_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (K-RIM=0x$K_HOOK_ADDR vs R-RIM=0x$R_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$K_HOOK_ADDR (= K-RIM と R-RIM で same routine entry)"
if [[ "$K_RIM_ADDR" != "$R_RIM_ADDR" ]]; then
    echo "  [FAIL] gate 3: RIM trigger addr differs (K-RIM=0x$K_RIM_ADDR vs R-RIM=0x$R_RIM_ADDR)"
    exit 1
fi
echo "  [PASS] RIM trigger addr identical = 0x$K_RIM_ADDR (= K-RIM と R-RIM で same RIM routine)"

# ============================================================
# gate 4: K-RIM fixture RIM register write literal
# ============================================================
echo
echo "=== gate 4: K-RIM fixture run ADPCM-A L ch RIM register write literal ==="

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

check_reg_value "$K_YMFM" "110" "$EXPECTED_RIM_START_LSB" "K-RIM L ch start LSB"
check_reg_value "$K_YMFM" "118" "$EXPECTED_RIM_START_MSB" "K-RIM L ch start MSB"
check_reg_value "$K_YMFM" "120" "$EXPECTED_RIM_STOP_LSB"  "K-RIM L ch stop LSB"
check_reg_value "$K_YMFM" "128" "$EXPECTED_RIM_STOP_MSB"  "K-RIM L ch stop MSB"
check_reg_value "$K_YMFM" "108" "$EXPECTED_VOL_PAN"       "K-RIM L ch vol|pan"

# ============================================================
# gate 5: R-RIM fixture RIM register write literal (= K-RIM と同 sequence)
# ============================================================
echo
echo "=== gate 5: R-RIM fixture run ADPCM-A L ch RIM register write literal ==="
check_reg_value "$R_YMFM" "110" "$EXPECTED_RIM_START_LSB" "R-RIM L ch start LSB"
check_reg_value "$R_YMFM" "118" "$EXPECTED_RIM_START_MSB" "R-RIM L ch start MSB"
check_reg_value "$R_YMFM" "120" "$EXPECTED_RIM_STOP_LSB"  "R-RIM L ch stop LSB"
check_reg_value "$R_YMFM" "128" "$EXPECTED_RIM_STOP_MSB"  "R-RIM L ch stop MSB"
check_reg_value "$R_YMFM" "108" "$EXPECTED_VOL_PAN"       "R-RIM L ch vol|pan"

# ============================================================
# gate 6: K-RIM と R-RIM の RIM register write sequence byte-identical (= differential proof)
# ============================================================
echo
echo "=== gate 6: K-RIM と R-RIM の RIM register write sequence byte-identical (= K-R RIM differential proof) ==="

# Extract L ch RIM register writes (= reg 0x10/0x18/0x20/0x28/0x08 + keyon mask 0x01 on reg 0x00)
extract_rim_writes() {
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

K_RIM_SEQ=$(extract_rim_writes "$K_YMFM")
R_RIM_SEQ=$(extract_rim_writes "$R_YMFM")

if [[ "$K_RIM_SEQ" != "$R_RIM_SEQ" ]]; then
    echo "  [FAIL] gate 6: K-RIM と R-RIM で RIM register write sequence が異なる"
    echo "         K-RIM seq:"
    echo "$K_RIM_SEQ" | sed 's/^/           /'
    echo "         R-RIM seq:"
    echo "$R_RIM_SEQ" | sed 's/^/           /'
    exit 1
fi
K_RIM_LINES=$(echo "$K_RIM_SEQ" | wc -l | tr -d ' ')
echo "  [PASS] K-RIM と R-RIM の RIM register write sequence byte-identical ($K_RIM_LINES 件)"
echo "         (= K part 0xEB RIM path と R command 0xEB RIM path が同 pmdneo_rhythm_event_trigger を経由)"
echo "         (= ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 が 6 drum 段 = full PMD drum set 拡張下で literal 維持)"
echo "         (= ADR-0031 §決定 8 「dispatch path は drum 種拡張で増やさない」 = full 6 drum completion で literal 達成)"

# ============================================================
# gate 7: K-RIM と R-RIM で L ch keyon mask 0x01 trigger count identical
# ============================================================
echo
echo "=== gate 7: K-RIM と R-RIM で L ch keyon mask 0x01 trigger count identical ==="
K_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM" | grep -c "^01$" || true)
R_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$R_YMFM" | grep -c "^01$" || true)
if [[ "$K_KEYON_01_COUNT" != "$R_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 7: keyon count differs (K-RIM=$K_KEYON_01_COUNT, R-RIM=$R_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$K_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 7: K-RIM と R-RIM 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] K-RIM と R-RIM で L ch keyon mask 0x01 trigger count = $K_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0031 step 17 γ K-RIM vs R-RIM byte-identical proof PASS (= full 6 drum completion で K=R 成立)"
echo "   - gate 1: K-RIM fixture build + run + trace ($K_WAV)"
echo "   - gate 2: R-RIM fixture build + run + trace ($R_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (K-RIM=R-RIM=0x$K_HOOK_ADDR)"
echo "             _rhythm_event_rim_trigger addr identical (K-RIM=R-RIM=0x$K_RIM_ADDR)"
echo "   - gate 4: K-RIM RIM register write literal PASS"
echo "   - gate 5: R-RIM RIM register write literal PASS"
echo "   - gate 6: K-RIM/R-RIM RIM register write sequence byte-identical ($K_RIM_LINES 件)"
echo "   - gate 7: K-RIM/R-RIM L ch keyon mask 0x01 trigger count identical ($K_KEYON_01_COUNT 件)"
echo ""
echo "   ADR-0031 §決定 8 「dispatch path は drum 種拡張で増やさない」 = literal 達成 (= full 6 drum completion)"
echo "   (= drum 種が b+s+c+h+t → b+s+c+h+t+i = full PMD drum set に拡張されても K-R dispatch path 1 本化が維持)"
exit 0
