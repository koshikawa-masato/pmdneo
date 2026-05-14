#!/usr/bin/env bash
#
# ADR-0031 step 17 γ: TOM vs RIM differential proof (= Step 16 新参 TOM と Step 17 新参 RIM の前後関係 + bit 4 → bit 5 dispatch 順 + tail-call invariant 移動 literal proof = full 6 drum completion γ)
#
# 目的:
#   ADR-0031 §決定 2/3/4/6 「drum 種 → sample pointer mapping を 1 軸拡張 + 最後の active bit tail-call pattern 移動」 の literal 証明。
#   K-TOM fixture (= k-tr-only.mml) と K-RIM fixture (= k-ir-only.mml) を両方 build + run
#   して、 ADPCM-A L ch register write のうち:
#
#   - reg 0x10 (start LSB) / reg 0x20 (stop LSB) が TOM vs RIM で **literal differ**
#     (= drum 種別 sample addr 区別の literal proof、 Step 16 直前追加 drum と Step 17 最終追加 drum の前後関係)
#   - reg 0x18 (start MSB) / reg 0x28 (stop MSB) / reg 0x08 (vol|pan) / reg 0x00 (keyon) は
#     **identical** (= 同 L ch、 同 fixture pattern なら同値)
#
#   を literal で固定する。 これにより:
#
#   - bit 4 → adpcma_sample_tom literal addr (= TOM_START_LSB = 0x0c / TOM_STOP_LSB = 0x11、 既存 ADR-0030 Step 16 維持、 Step 17 で tail-call → call nz pattern 戻し)
#   - bit 5 → adpcma_sample_rim literal addr (= RIM_START_LSB = 0x0a / RIM_STOP_LSB = 0x0b、 既存 adpcma_sample_rim symbol reuse = full 6 drum completion = new tail-call target)
#
#   が driver の bit position 分岐 + sample pointer mapping で正しく区別されていること、
#   「最後の active bit = tail-call」 invariant が bit 4 TOM → bit 5 RIM に移動した結果 driver の
#   dispatch path 全体が consistent に動作すること、 silent path に倒れただけではないことを
#   literal で証明する (= ADR-0031 §決定 4 / §決定 6 / §scope-in / §verify gate Gate 6 整合)。
#
#   **Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit proof**:
#   - bit 4 TOM は ADR-0030 まで tail-call jp pattern → ADR-0031 で call nz pattern に戻し
#   - bit 5 RIM は ADR-0031 で new tail-call jp pattern target = **full 6 drum completion**
#   - 両 drum が同 dispatch path 内で隣接 bit (= 4 と 5) でありながら independent な register write を発火することの literal verify
#
#   fixture 命名注記: `ir` = `\i` + `r`(= rest) fixture pattern。 「RIM」 略ではない (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern 同一規律、 ADR-0031 §決定 5 / 軸 2 整合)。
#
#   PMDDotNET 内部名 `tamset` / `rimset` と PMDNEO 側 wording TOM / RIM の対応 (= ADR-0031 §決定 3 「用語対応表」):
#   - tamset = TOM (= TAM legacy naming、 PMDNEO 側 wording は TOM 統一 = ADR-0030 §決定 3)
#   - rimset = RIM (= RIM semantics と実質一致 = ADR-0031 §決定 3、 wording 分離なし)
#
#   注: 推移的 proof = SD vs RIM / CYM vs RIM / HH vs RIM は BD vs SD / BD vs HH / BD vs CYM の既存 differential + 本 verify の BD vs RIM + TOM vs RIM から N-1 pair gate で確立済 (= ADR-0031 §verify gate Gate 5/6 注記)。
#
# 検証: 6 段 gate
#   gate 1: K-TOM fixture build + run + trace
#   gate 2: K-RIM fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: TOM vs RIM で sample addr literal differ (= reg 0x10 / 0x20 異なる)
#   gate 5: TOM vs RIM で MSB / vol|pan / keyon literal identical (= 同 L ch state)
#   gate 6: TOM trigger と RIM trigger 両方で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない、 dispatch path 全体 consistent)
#
# 検証範囲外 (= γ 同 commit / δ で別途):
#   - K-RIM vs R-RIM byte-identical proof (= verify-step17-kr-rim-byte-identical.sh、 γ 同 commit)
#   - BD vs RIM differential proof (= verify-step17-bd-vs-rim-differential.sh、 γ 同 commit)
#   - SD vs RIM / CYM vs RIM / HH vs RIM differential → ADR-0031 §verify gate Gate 5/6 注記で推移的処理、 explicit gate なし
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で TOM / RIM 別々 audible 確認)
#   - ADR-0031 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step17/verify-step17-tom-vs-rim-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step16/k-tr-only.wav  (= K-TOM fixture audible 試聴用、 4 秒、 step16 OUT_DIR 共有)
#   /tmp/pmdneo-step17/k-ir-only.wav  (= K-RIM fixture audible 試聴用、 4 秒)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

TOM_MML="$PROJECT_ROOT/src/test-fixtures/step16/k-tr-only.mml"
RIM_MML="$PROJECT_ROOT/src/test-fixtures/step17/k-ir-only.mml"
TOM_OUT_DIR="/tmp/pmdneo-step16"
RIM_OUT_DIR="/tmp/pmdneo-step17"

if [[ ! -f "$TOM_MML" ]]; then echo "FAIL infra: $TOM_MML not found"; exit 2; fi
if [[ ! -f "$RIM_MML" ]]; then echo "FAIL infra: $RIM_MML not found"; exit 2; fi

mkdir -p "$TOM_OUT_DIR" "$RIM_OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step17-tom-rim-diff-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0030 §決定 3 + ADR-0031 §決定 3 driver-embedded fixture)
EXPECTED_TOM_START_LSB="0c"          # (= TOM_START_LSB、 ADR-0030 §決定 3 adpcma_sample_tom reuse)
EXPECTED_TOM_STOP_LSB="11"           # (= TOM_STOP_LSB)
EXPECTED_RIM_START_LSB="0a"          # (= RIM_START_LSB、 ADR-0031 §決定 3 / 軸 1 adpcma_sample_rim reuse)
EXPECTED_RIM_STOP_LSB="0b"           # (= RIM_STOP_LSB)
EXPECTED_MSB="00"                    # (= TOM / RIM 共通 = 0x00、 sample data が VROM page 0 内に収まる)
EXPECTED_VOL_PAN="DF"                # (= L|R pan 0xC0 + max vol 0x1F、 TOM/RIM 共通)
EXPECTED_KEYON_MASK="01"             # (= L ch keyon bit 0、 TOM/RIM 共通)

echo "=== ADR-0031 step 17 γ: TOM vs RIM differential proof (= Step 16 新参 TOM と Step 17 新参 RIM の前後関係 + bit 4 → bit 5 dispatch 順 + tail-call invariant 移動 literal proof = full 6 drum completion) ==="
echo

# ============================================================
# gate 1: K-TOM fixture build + run + trace
# ============================================================
echo "=== gate 1: K-TOM fixture (= k-tr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$TOM_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-tom-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-TOM build failed (log: $TMPDIR/k-tom-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-tom-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-TOM MAME run failed"
    exit 2
}
TOM_YMFM="$TOM_OUT_DIR/k-tr-only-ymfm.tsv"
TOM_WAV="$TOM_OUT_DIR/k-tr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TOM_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$TOM_WAV"
echo "  [PASS] K-TOM fixture build + run + trace 取得 (wav: $TOM_WAV)"

TOM_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
TOM_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$TOM_LST" | head -1 | awk '{print $1}')
TOM_TOM_ADDR=$(grep -E "_rhythm_event_tom_trigger:" "$TOM_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-TOM build: pmdneo_rhythm_event_trigger @ 0x$TOM_HOOK_ADDR / _rhythm_event_tom_trigger @ 0x$TOM_TOM_ADDR"

# ============================================================
# gate 2: K-RIM fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: K-RIM fixture (= k-ir-only.mml) build + run + trace ==="
PMDDOTNET_MML="$RIM_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-rim-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-RIM build failed (log: $TMPDIR/k-rim-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-rim-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-RIM MAME run failed"
    exit 2
}
RIM_YMFM="$RIM_OUT_DIR/k-ir-only-ymfm.tsv"
RIM_WAV="$RIM_OUT_DIR/k-ir-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$RIM_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$RIM_WAV"
echo "  [PASS] K-RIM fixture build + run + trace 取得 (wav: $RIM_WAV)"

RIM_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
RIM_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$RIM_LST" | head -1 | awk '{print $1}')
RIM_RIM_ADDR=$(grep -E "_rhythm_event_rim_trigger:" "$RIM_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-RIM build: pmdneo_rhythm_event_trigger @ 0x$RIM_HOOK_ADDR / _rhythm_event_rim_trigger @ 0x$RIM_RIM_ADDR"

# ============================================================
# gate 3: same hook addr in TOM and RIM builds (= dispatch path 1 本化 literal 維持、 full 6 drum completion)
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between TOM and RIM builds ==="
if [[ "$TOM_HOOK_ADDR" != "$RIM_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (TOM=0x$TOM_HOOK_ADDR vs RIM=0x$RIM_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$TOM_HOOK_ADDR (= TOM と RIM で same routine entry、 6 drum 段 = full PMD drum set 下不変)"

# ============================================================
# gate 4: TOM vs RIM で sample addr literal differ (= reg 0x10 / 0x20 異なる)
# ============================================================
echo
echo "=== gate 4: TOM vs RIM で sample addr literal differ (= Step 16 直前 drum と Step 17 最終 drum の前後関係 proof) ==="

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

# TOM literal (= ADR-0030 §決定 3 既存維持)
check_reg_value "$TOM_YMFM" "110" "$EXPECTED_TOM_START_LSB"  "TOM L ch start LSB = 0x0c (= TOM_START_LSB)"
check_reg_value "$TOM_YMFM" "120" "$EXPECTED_TOM_STOP_LSB"   "TOM L ch stop LSB = 0x11 (= TOM_STOP_LSB)"

# RIM literal (= ADR-0031 §決定 3 新規)
check_reg_value "$RIM_YMFM" "110" "$EXPECTED_RIM_START_LSB"  "RIM L ch start LSB = 0x0a (= RIM_START_LSB)"
check_reg_value "$RIM_YMFM" "120" "$EXPECTED_RIM_STOP_LSB"   "RIM L ch stop LSB = 0x0b (= RIM_STOP_LSB)"

# Confirm TOM differs from RIM (= literal differ assert)
TOM_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$TOM_YMFM" | tail -1)
RIM_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$RIM_YMFM" | tail -1)
TOM_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$TOM_YMFM" | tail -1)
RIM_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$RIM_YMFM" | tail -1)

if [[ "$TOM_START_LSB" == "$RIM_START_LSB" ]]; then
    echo "  [FAIL] gate 4: TOM start LSB (0x$TOM_START_LSB) と RIM start LSB (0x$RIM_START_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
if [[ "$TOM_STOP_LSB" == "$RIM_STOP_LSB" ]]; then
    echo "  [FAIL] gate 4: TOM stop LSB (0x$TOM_STOP_LSB) と RIM stop LSB (0x$RIM_STOP_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
echo "  [PASS] TOM start LSB (0x$TOM_START_LSB) ≠ RIM start LSB (0x$RIM_START_LSB) literal differ"
echo "  [PASS] TOM stop LSB (0x$TOM_STOP_LSB) ≠ RIM stop LSB (0x$RIM_STOP_LSB) literal differ"
echo "         (= ADR-0031 §決定 6 「drum 種 → sample pointer mapping bit 4 TOM / bit 5 RIM」 literal 達成 = full 6 drum completion)"
echo "         (= ADR-0031 §決定 4 「最後の active bit = tail-call」 invariant 移動 = bit 4 TOM call nz pattern + bit 5 RIM new tail-call target = full 6 drum dispatch path consistent)"

# ============================================================
# gate 5: TOM と RIM で MSB / vol|pan / keyon identical (= 同 L ch state)
# ============================================================
echo
echo "=== gate 5: TOM と RIM で MSB / vol|pan / keyon literal identical (= 同 L ch、 同 fixture pattern) ==="

check_reg_value "$TOM_YMFM" "118" "$EXPECTED_MSB"      "TOM L ch start MSB = 0x00"
check_reg_value "$RIM_YMFM" "118" "$EXPECTED_MSB"      "RIM L ch start MSB = 0x00"
check_reg_value "$TOM_YMFM" "128" "$EXPECTED_MSB"      "TOM L ch stop MSB = 0x00"
check_reg_value "$RIM_YMFM" "128" "$EXPECTED_MSB"      "RIM L ch stop MSB = 0x00"
check_reg_value "$TOM_YMFM" "108" "$EXPECTED_VOL_PAN"  "TOM L ch vol|pan = 0xDF"
check_reg_value "$RIM_YMFM" "108" "$EXPECTED_VOL_PAN"  "RIM L ch vol|pan = 0xDF"

# ============================================================
# gate 6: TOM と RIM で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない、 dispatch path 全体 consistent)
# ============================================================
echo
echo "=== gate 6: TOM と RIM で L ch keyon mask 0x01 trigger 1 件 (= 同回数発火、 dispatch path 全体 consistent、 silent path に倒れていないことの proof) ==="
TOM_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$TOM_YMFM" | grep -c "^01$" || true)
RIM_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$RIM_YMFM" | grep -c "^01$" || true)
if [[ "$TOM_KEYON_01_COUNT" != "$RIM_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 6: keyon count differs (TOM=$TOM_KEYON_01_COUNT, RIM=$RIM_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$TOM_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 6: TOM と RIM 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] TOM と RIM で L ch keyon mask 0x01 trigger count = $TOM_KEYON_01_COUNT 件 (= 同回数発火、 dispatch path 全体 consistent)"

echo
echo "🎉 ADR-0031 step 17 γ TOM vs RIM differential proof PASS (= full 6 drum completion、 Step 16 直前 + Step 17 最終 drum の前後関係 literal 確定)"
echo "   - gate 1: K-TOM fixture build + run + trace ($TOM_WAV)"
echo "   - gate 2: K-RIM fixture build + run + trace ($RIM_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (TOM=RIM=0x$TOM_HOOK_ADDR)"
echo "   - gate 4: TOM start/stop LSB ≠ RIM start/stop LSB literal differ"
echo "             (TOM start=0x$TOM_START_LSB stop=0x$TOM_STOP_LSB / RIM start=0x$RIM_START_LSB stop=0x$RIM_STOP_LSB)"
echo "   - gate 5: TOM/RIM で MSB / vol|pan literal identical (= 同 L ch state)"
echo "   - gate 6: TOM/RIM で L ch keyon mask 0x01 trigger count = $TOM_KEYON_01_COUNT 件 identical"
echo ""
echo "   ADR-0031 §決定 4 「最後の active bit = tail-call」 invariant 移動 = literal 達成 (= bit 4 TOM call nz pattern + bit 5 RIM new tail-call target)"
echo "   ADR-0031 §決定 6 「drum 種 → sample pointer mapping bit 4 TOM / bit 5 RIM」 = literal 達成 (= full 6 drum completion)"
echo "   (= Step 16 直前追加 drum と Step 17 最終追加 drum が register addr literal で観測可能に区別されており、 dispatch path 全体が consistent に動作)"
echo "   (= SD vs RIM / CYM vs RIM / HH vs RIM literal differ は BD-vs-SD + BD-vs-HH + BD-vs-CYM + BD-vs-TOM + BD-vs-RIM + TOM-vs-RIM の N-1 pair gate から推移的に proof 成立、 ADR-0031 §verify gate Gate 6 注記)"
exit 0
