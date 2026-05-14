#!/usr/bin/env bash
#
# ADR-0030 step 16 γ: K-TOM vs R-TOM differential proof (= K と R が同 TOM trigger dispatch path を経由)
#
# 目的:
#   ADR-0030 §決定 4/8/9 「dispatch path 1 本化は 5 drum 段下で literal 維持」 の literal 証明。
#   K-TOM fixture (= k-tr-only.mml) と R-TOM fixture (= r-melody-tr-only.mml) を両方 build + run
#   して、 ADPCM-A L ch TOM register write sequence が **byte-identical** であることを
#   literal 比較で証明する。 これにより:
#
#   - K part 0xEB TOM path (= rhythm_main → rhythm_main_rhykey → pmdneo_rhythm_event_trigger → bit 4 → _rhythm_event_tom_trigger)
#   - R command 0xEB TOM path (= pmdneo_part_main_parse → commandsp → commandsp_rhykey → pmdneo_rhythm_event_trigger → bit 4 → _rhythm_event_tom_trigger)
#
#   の 2 つの source layer path が runtime layer で **同一 routine** に collapse される
#   ことを、 TOM trigger という 5 drum 段拡張下でも維持されていることを literal で固定する
#   (= ADR-0026 §決定 6 / §決定 8 + ADR-0027 §決定 4 / §決定 8 / §決定 9 + ADR-0028 §決定 4 / §決定 8 / §決定 9 + ADR-0029 §決定 4 / §決定 8 / §決定 9 + ADR-0030 §決定 4 / §決定 8 / §決定 9 整合)。
#
#   fixture 命名注記: `tr` = `\t` + `r`(= rest) fixture pattern。 「TOM」 略ではない (= 既存 `br` / `sr` / `cr` / `hr` pattern 同一規律、 ADR-0030 §決定 5 / 軸 2 整合)。
#
#   PMDDotNET 内部名は `tamset` (= TAM legacy naming) だが、 PMDNEO 側 wording は TOM 統一
#   (= ADR-0030 §決定 3 「用語対応表」 + §Annex A-1 literal、 ground truth `tamset` 記録 + PMDNEO 側 TOM 統一)。
#
#   Step 12 K-BD vs R-BD differential proof (= verify-step12-kr-differential.sh) + Step 13 K-SD vs R-SD differential proof (= verify-step13-kr-sd-differential.sh) + Step 14 K-HH vs R-HH differential proof (= verify-step14-kr-hh-differential.sh) + Step 15 K-CYM vs R-CYM differential proof (= verify-step15-kr-cym-differential.sh) の TOM 版。
#
# 検証: 7 段 gate
#   gate 1: K-TOM fixture build + run + trace
#   gate 2: R-TOM fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: K-TOM fixture run TOM register write literal (= β verify と同内容、 重複 assert)
#   gate 5: R-TOM fixture run TOM register write literal (= K-TOM と同 sequence)
#   gate 6: K-TOM と R-TOM の TOM register write sequence byte-identical (= **differential proof**)
#   gate 7: K-TOM と R-TOM で L ch keyon mask 0x01 trigger count identical (= 同回数発火)
#
# 検証範囲外 (= δ で別途):
#   - BD vs TOM differential proof (= verify-step16-bd-tom-differential.sh、 γ 同 commit)
#   - SD vs TOM / CYM vs TOM / HH vs TOM differential → ADR-0030 §verify gate Gate 4 注記で推移的処理、 explicit gate なし
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で K-TOM / R-TOM 別々 audible 確認)
#   - ADR-0030 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step16/verify-step16-kr-tom-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step16/k-tr-only.wav         (= K-TOM fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step16/r-melody-tr-only.wav  (= R-TOM fixture audible 試聴用、 4 秒)
#   /tmp/pmdneo-step16/k-tr-*.tsv            (= K-TOM fixture trace snapshot)
#   /tmp/pmdneo-step16/r-melody-tr-*.tsv     (= R-TOM fixture trace snapshot)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step16/k-tr-only.mml"
R_MML="$PROJECT_ROOT/src/test-fixtures/step16/r-melody-tr-only.mml"
OUT_DIR="/tmp/pmdneo-step16"

if [[ ! -f "$K_MML" ]]; then echo "FAIL infra: $K_MML not found"; exit 2; fi
if [[ ! -f "$R_MML" ]]; then echo "FAIL infra: $R_MML not found"; exit 2; fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step16-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0030 §決定 3 driver-embedded TOM sample、 既存 adpcma_sample_tom symbol reuse)
EXPECTED_TOM_START_LSB="0c"              # (= TOM_START_LSB)
EXPECTED_TOM_START_MSB="00"              # (= TOM_START_MSB)
EXPECTED_TOM_STOP_LSB="11"               # (= TOM_STOP_LSB)
EXPECTED_TOM_STOP_MSB="00"               # (= TOM_STOP_MSB)
EXPECTED_VOL_PAN="DF"
EXPECTED_KEYON_MASK="01"

echo "=== ADR-0030 step 16 γ: K-TOM vs R-TOM differential proof (= K-TOM と R-TOM の dispatch path 共通化 literal 証明) ==="
echo

# ============================================================
# gate 1: K-TOM fixture build + run + trace
# ============================================================
echo "=== gate 1: K-TOM fixture (= k-tr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-tom-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-TOM build failed (log: $TMPDIR/k-tom-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-tom-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-TOM MAME run failed"
    exit 2
}
K_YMFM="$OUT_DIR/k-tr-only-ymfm.tsv"
K_MEM="$OUT_DIR/k-tr-only-mem.tsv"
K_WAV="$OUT_DIR/k-tr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] K-TOM fixture build + run + trace 取得 (wav: $K_WAV)"

# .lst snapshot
K_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$K_LST" ]]; then echo "  [FAIL] gate 1: .lst not found"; exit 2; fi
K_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$K_LST" | head -1 | awk '{print $1}')
if [[ -z "$K_HOOK_ADDR" ]]; then echo "  [FAIL] gate 1: hook symbol not found in K-TOM build .lst"; exit 1; fi
echo "  [INFO] K-TOM build: pmdneo_rhythm_event_trigger @ 0x$K_HOOK_ADDR"
K_TOM_ADDR=$(grep -E "_rhythm_event_tom_trigger:" "$K_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-TOM build: _rhythm_event_tom_trigger @ 0x$K_TOM_ADDR"

# ============================================================
# gate 2: R-TOM fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: R-TOM fixture (= r-melody-tr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$R_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/r-tom-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-TOM build failed (log: $TMPDIR/r-tom-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/r-tom-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-TOM MAME run failed"
    exit 2
}
R_YMFM="$OUT_DIR/r-melody-tr-only-ymfm.tsv"
R_MEM="$OUT_DIR/r-melody-tr-only-mem.tsv"
R_WAV="$OUT_DIR/r-melody-tr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$R_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$R_MEM"
cp /tmp/pmdneo-trace/audio.wav "$R_WAV"
echo "  [PASS] R-TOM fixture build + run + trace 取得 (wav: $R_WAV)"

R_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
R_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$R_LST" | head -1 | awk '{print $1}')
if [[ -z "$R_HOOK_ADDR" ]]; then echo "  [FAIL] gate 2: hook symbol not found in R-TOM build .lst"; exit 1; fi
echo "  [INFO] R-TOM build: pmdneo_rhythm_event_trigger @ 0x$R_HOOK_ADDR"
R_TOM_ADDR=$(grep -E "_rhythm_event_tom_trigger:" "$R_LST" | head -1 | awk '{print $1}')
echo "  [INFO] R-TOM build: _rhythm_event_tom_trigger @ 0x$R_TOM_ADDR"

# ============================================================
# gate 3: same hook addr in both K-TOM and R-TOM builds
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between K-TOM and R-TOM builds ==="
if [[ "$K_HOOK_ADDR" != "$R_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (K-TOM=0x$K_HOOK_ADDR vs R-TOM=0x$R_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$K_HOOK_ADDR (= K-TOM と R-TOM で same routine entry)"
if [[ "$K_TOM_ADDR" != "$R_TOM_ADDR" ]]; then
    echo "  [FAIL] gate 3: TOM trigger addr differs (K-TOM=0x$K_TOM_ADDR vs R-TOM=0x$R_TOM_ADDR)"
    exit 1
fi
echo "  [PASS] TOM trigger addr identical = 0x$K_TOM_ADDR (= K-TOM と R-TOM で same TOM routine)"

# ============================================================
# gate 4: K-TOM fixture TOM register write literal
# ============================================================
echo
echo "=== gate 4: K-TOM fixture run ADPCM-A L ch TOM register write literal ==="

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

check_reg_value "$K_YMFM" "110" "$EXPECTED_TOM_START_LSB" "K-TOM L ch start LSB"
check_reg_value "$K_YMFM" "118" "$EXPECTED_TOM_START_MSB" "K-TOM L ch start MSB"
check_reg_value "$K_YMFM" "120" "$EXPECTED_TOM_STOP_LSB"  "K-TOM L ch stop LSB"
check_reg_value "$K_YMFM" "128" "$EXPECTED_TOM_STOP_MSB"  "K-TOM L ch stop MSB"
check_reg_value "$K_YMFM" "108" "$EXPECTED_VOL_PAN"       "K-TOM L ch vol|pan"

# ============================================================
# gate 5: R-TOM fixture TOM register write literal (= K-TOM と同 sequence)
# ============================================================
echo
echo "=== gate 5: R-TOM fixture run ADPCM-A L ch TOM register write literal ==="
check_reg_value "$R_YMFM" "110" "$EXPECTED_TOM_START_LSB" "R-TOM L ch start LSB"
check_reg_value "$R_YMFM" "118" "$EXPECTED_TOM_START_MSB" "R-TOM L ch start MSB"
check_reg_value "$R_YMFM" "120" "$EXPECTED_TOM_STOP_LSB"  "R-TOM L ch stop LSB"
check_reg_value "$R_YMFM" "128" "$EXPECTED_TOM_STOP_MSB"  "R-TOM L ch stop MSB"
check_reg_value "$R_YMFM" "108" "$EXPECTED_VOL_PAN"       "R-TOM L ch vol|pan"

# ============================================================
# gate 6: K-TOM と R-TOM の TOM register write sequence byte-identical (= differential proof)
# ============================================================
echo
echo "=== gate 6: K-TOM と R-TOM の TOM register write sequence byte-identical (= K-R TOM differential proof) ==="

# Extract L ch TOM register writes (= reg 0x10/0x18/0x20/0x28/0x08 + keyon mask 0x01 on reg 0x00)
extract_tom_writes() {
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

K_TOM_SEQ=$(extract_tom_writes "$K_YMFM")
R_TOM_SEQ=$(extract_tom_writes "$R_YMFM")

if [[ "$K_TOM_SEQ" != "$R_TOM_SEQ" ]]; then
    echo "  [FAIL] gate 6: K-TOM と R-TOM で TOM register write sequence が異なる"
    echo "         K-TOM seq:"
    echo "$K_TOM_SEQ" | sed 's/^/           /'
    echo "         R-TOM seq:"
    echo "$R_TOM_SEQ" | sed 's/^/           /'
    exit 1
fi
K_TOM_LINES=$(echo "$K_TOM_SEQ" | wc -l | tr -d ' ')
echo "  [PASS] K-TOM と R-TOM の TOM register write sequence byte-identical ($K_TOM_LINES 件)"
echo "         (= K part 0xEB TOM path と R command 0xEB TOM path が同 pmdneo_rhythm_event_trigger を経由)"
echo "         (= ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 が 5 drum 段拡張下で literal 維持)"
echo "         (= ADR-0030 §決定 8 「dispatch path は drum 種拡張で増やさない」 literal 達成)"

# ============================================================
# gate 7: K-TOM と R-TOM で L ch keyon mask 0x01 trigger count identical
# ============================================================
echo
echo "=== gate 7: K-TOM と R-TOM で L ch keyon mask 0x01 trigger count identical ==="
K_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM" | grep -c "^01$" || true)
R_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$R_YMFM" | grep -c "^01$" || true)
if [[ "$K_KEYON_01_COUNT" != "$R_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 7: keyon count differs (K-TOM=$K_KEYON_01_COUNT, R-TOM=$R_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$K_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 7: K-TOM と R-TOM 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] K-TOM と R-TOM で L ch keyon mask 0x01 trigger count = $K_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0030 step 16 γ K-TOM vs R-TOM differential proof PASS"
echo "   - gate 1: K-TOM fixture build + run + trace ($K_WAV)"
echo "   - gate 2: R-TOM fixture build + run + trace ($R_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (K-TOM=R-TOM=0x$K_HOOK_ADDR)"
echo "             _rhythm_event_tom_trigger addr identical (K-TOM=R-TOM=0x$K_TOM_ADDR)"
echo "   - gate 4: K-TOM TOM register write literal PASS"
echo "   - gate 5: R-TOM TOM register write literal PASS"
echo "   - gate 6: K-TOM/R-TOM TOM register write sequence byte-identical ($K_TOM_LINES 件)"
echo "   - gate 7: K-TOM/R-TOM L ch keyon mask 0x01 trigger count identical ($K_KEYON_01_COUNT 件)"
echo ""
echo "   ADR-0030 §決定 8 「dispatch path は drum 種拡張で増やさない」 = literal 達成"
echo "   (= drum 種が b+s+c+h → b+s+c+h+t に拡張されても K-R dispatch path 1 本化が維持)"
exit 0
