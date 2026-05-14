#!/usr/bin/env bash
#
# ADR-0028 step 14 γ: BD vs HH differential proof (= drum 種で sample addr が literal differ、 3 drum 段下)
#
# 目的:
#   ADR-0028 §決定 2/3/6 「drum 種 → sample pointer mapping を 1 軸拡張」 の literal 証明。
#   K-BD fixture (= k-br-only.mml) と K-HH fixture (= k-hr-only.mml) を両方 build + run
#   して、 ADPCM-A L ch register write のうち:
#
#   - reg 0x10 (start LSB) / reg 0x20 (stop LSB) が BD vs HH で **literal differ**
#     (= drum 種別 sample addr 区別の literal proof、 3 drum 段拡張下)
#   - reg 0x18 (start MSB) / reg 0x28 (stop MSB) / reg 0x08 (vol|pan) / reg 0x00 (keyon) は
#     **identical** (= 同 L ch、 同 fixture pattern なら同値)
#
#   を literal で固定する。 これにより:
#
#   - bit 0 → adpcma_sample_bd literal addr (= BD_START_LSB = 0x00 / BD_STOP_LSB = 0x03、 既存 Step 12 維持)
#   - bit 3 → adpcma_sample_hh literal addr (= HH_START_LSB = 0x07 / HH_STOP_LSB = 0x09、 既存 adpcma_sample_hh symbol reuse)
#
#   が driver の bit position 分岐 + sample pointer mapping で正しく区別されていること、
#   silent path に倒れただけではないこと、 HH trigger が BD trigger と異なる sample を
#   trigger していることを literal で証明する (= ADR-0028 §決定 3 / §決定 6 / §scope-in / §verify gate Gate 4 整合)。
#
#   fixture 命名注記: `hr` = `\h` + `r`(= rest) fixture pattern。 「hi-hat」 略ではない (= 既存 `br` / `sr` pattern 同一規律、 ADR-0028 §決定 5 / 軸 2 整合)。
#
#   注: SD vs HH differential は scope-out (= ADR-0028 §verify gate Gate 4 で BD vs HH のみ指定、 BD vs SD differential proof = ADR-0027 §verify gate Gate 4 で確立済 → 推移的に SD vs HH も literal differ である)。
#
# 検証: 6 段 gate
#   gate 1: K-BD fixture build + run + trace
#   gate 2: K-HH fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: BD vs HH で sample addr literal differ (= reg 0x10 / 0x20 異なる)
#   gate 5: BD vs HH で MSB / vol|pan / keyon literal identical (= 同 L ch state)
#   gate 6: BD trigger と HH trigger 両方で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
#
# 検証範囲外 (= δ で別途):
#   - K-HH vs R-HH differential proof (= verify-step14-kr-hh-differential.sh、 γ 同 commit)
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で BD / HH 別々 audible 確認)
#   - ADR-0028 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step14/verify-step14-bd-hh-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step12/k-br-only.wav  (= K-BD fixture audible 試聴用、 4 秒、 step12 OUT_DIR 共有)
#   /tmp/pmdneo-step14/k-hr-only.wav  (= K-HH fixture audible 試聴用、 4 秒)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

BD_MML="$PROJECT_ROOT/src/test-fixtures/step12/k-br-only.mml"
HH_MML="$PROJECT_ROOT/src/test-fixtures/step14/k-hr-only.mml"
BD_OUT_DIR="/tmp/pmdneo-step12"
HH_OUT_DIR="/tmp/pmdneo-step14"

if [[ ! -f "$BD_MML" ]]; then echo "FAIL infra: $BD_MML not found"; exit 2; fi
if [[ ! -f "$HH_MML" ]]; then echo "FAIL infra: $HH_MML not found"; exit 2; fi

mkdir -p "$BD_OUT_DIR" "$HH_OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step14-bd-hh-diff-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0026 §決定 3 + ADR-0027 §決定 3 + ADR-0028 §決定 3 driver-embedded fixture)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_HH_START_LSB="07"
EXPECTED_HH_STOP_LSB="09"
EXPECTED_MSB="00"                    # (= BD / HH 共通 = 0x00、 sample data が VROM page 0 内に収まる)
EXPECTED_VOL_PAN="DF"                # (= L|R pan 0xC0 + max vol 0x1F、 BD/HH 共通)
EXPECTED_KEYON_MASK="01"             # (= L ch keyon bit 0、 BD/HH 共通)

echo "=== ADR-0028 step 14 γ: BD vs HH differential proof (= drum 種別 sample addr literal differ 証明、 3 drum 段) ==="
echo

# ============================================================
# gate 1: K-BD fixture build + run + trace
# ============================================================
echo "=== gate 1: K-BD fixture (= k-br-only.mml) build + run + trace ==="
PMDDOTNET_MML="$BD_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-bd-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-BD build failed (log: $TMPDIR/k-bd-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-bd-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-BD MAME run failed"
    exit 2
}
BD_YMFM="$BD_OUT_DIR/k-br-only-ymfm.tsv"
BD_WAV="$BD_OUT_DIR/k-br-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$BD_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$BD_WAV"
echo "  [PASS] K-BD fixture build + run + trace 取得 (wav: $BD_WAV)"

BD_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
BD_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$BD_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-BD build: pmdneo_rhythm_event_trigger @ 0x$BD_HOOK_ADDR"

# ============================================================
# gate 2: K-HH fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: K-HH fixture (= k-hr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$HH_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-hh-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-HH build failed (log: $TMPDIR/k-hh-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-hh-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-HH MAME run failed"
    exit 2
}
HH_YMFM="$HH_OUT_DIR/k-hr-only-ymfm.tsv"
HH_WAV="$HH_OUT_DIR/k-hr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$HH_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$HH_WAV"
echo "  [PASS] K-HH fixture build + run + trace 取得 (wav: $HH_WAV)"

HH_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
HH_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$HH_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-HH build: pmdneo_rhythm_event_trigger @ 0x$HH_HOOK_ADDR"

# ============================================================
# gate 3: same hook addr in BD and HH builds (= dispatch path 1 本化 literal 維持)
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between BD and HH builds ==="
if [[ "$BD_HOOK_ADDR" != "$HH_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (BD=0x$BD_HOOK_ADDR vs HH=0x$HH_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$BD_HOOK_ADDR (= BD と HH で same routine entry、 3 drum 段下不変)"

# ============================================================
# gate 4: BD vs HH で sample addr literal differ (= reg 0x10 / 0x20 異なる)
# ============================================================
echo
echo "=== gate 4: BD vs HH で sample addr literal differ (= drum 種別 sample 区別 proof) ==="

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

# BD literal
check_reg_value "$BD_YMFM" "110" "$EXPECTED_BD_START_LSB" "BD L ch start LSB = 0x00 (= BD_START_LSB)"
check_reg_value "$BD_YMFM" "120" "$EXPECTED_BD_STOP_LSB"  "BD L ch stop LSB = 0x03 (= BD_STOP_LSB)"

# HH literal
check_reg_value "$HH_YMFM" "110" "$EXPECTED_HH_START_LSB" "HH L ch start LSB = 0x07 (= HH_START_LSB)"
check_reg_value "$HH_YMFM" "120" "$EXPECTED_HH_STOP_LSB"  "HH L ch stop LSB = 0x09 (= HH_STOP_LSB)"

# Confirm BD differs from HH (= literal differ assert)
BD_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$BD_YMFM" | tail -1)
HH_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$HH_YMFM" | tail -1)
BD_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$BD_YMFM" | tail -1)
HH_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$HH_YMFM" | tail -1)

if [[ "$BD_START_LSB" == "$HH_START_LSB" ]]; then
    echo "  [FAIL] gate 4: BD start LSB (0x$BD_START_LSB) と HH start LSB (0x$HH_START_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
if [[ "$BD_STOP_LSB" == "$HH_STOP_LSB" ]]; then
    echo "  [FAIL] gate 4: BD stop LSB (0x$BD_STOP_LSB) と HH stop LSB (0x$HH_STOP_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
echo "  [PASS] BD start LSB (0x$BD_START_LSB) ≠ HH start LSB (0x$HH_START_LSB) literal differ"
echo "  [PASS] BD stop LSB (0x$BD_STOP_LSB) ≠ HH stop LSB (0x$HH_STOP_LSB) literal differ"
echo "         (= ADR-0028 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 3 HH」 literal 達成、 bit 1 SD は ADR-0027 既存維持)"

# ============================================================
# gate 5: BD と HH で MSB / vol|pan / keyon identical (= 同 L ch state)
# ============================================================
echo
echo "=== gate 5: BD と HH で MSB / vol|pan / keyon literal identical (= 同 L ch、 同 fixture pattern) ==="

check_reg_value "$BD_YMFM" "118" "$EXPECTED_MSB"     "BD L ch start MSB = 0x00"
check_reg_value "$HH_YMFM" "118" "$EXPECTED_MSB"     "HH L ch start MSB = 0x00"
check_reg_value "$BD_YMFM" "128" "$EXPECTED_MSB"     "BD L ch stop MSB = 0x00"
check_reg_value "$HH_YMFM" "128" "$EXPECTED_MSB"     "HH L ch stop MSB = 0x00"
check_reg_value "$BD_YMFM" "108" "$EXPECTED_VOL_PAN" "BD L ch vol|pan = 0xDF"
check_reg_value "$HH_YMFM" "108" "$EXPECTED_VOL_PAN" "HH L ch vol|pan = 0xDF"

# ============================================================
# gate 6: BD と HH で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
# ============================================================
echo
echo "=== gate 6: BD と HH で L ch keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent path に倒れていないことの proof) ==="
BD_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$BD_YMFM" | grep -c "^01$" || true)
HH_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$HH_YMFM" | grep -c "^01$" || true)
if [[ "$BD_KEYON_01_COUNT" != "$HH_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 6: keyon count differs (BD=$BD_KEYON_01_COUNT, HH=$HH_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$BD_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 6: BD と HH 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] BD と HH で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0028 step 14 γ BD vs HH differential proof PASS"
echo "   - gate 1: K-BD fixture build + run + trace ($BD_WAV)"
echo "   - gate 2: K-HH fixture build + run + trace ($HH_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (BD=HH=0x$BD_HOOK_ADDR)"
echo "   - gate 4: BD start/stop LSB ≠ HH start/stop LSB literal differ"
echo "             (BD start=0x$BD_START_LSB stop=0x$BD_STOP_LSB / HH start=0x$HH_START_LSB stop=0x$HH_STOP_LSB)"
echo "   - gate 5: BD/HH で MSB / vol|pan literal identical (= 同 L ch state)"
echo "   - gate 6: BD/HH で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 identical"
echo ""
echo "   ADR-0028 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 3 HH」 = literal 達成"
echo "   (= drum 種が 3 drum 段 = b+s+h に拡張されても、 register addr literal で観測可能に区別されており silent 倒れではない)"
exit 0
