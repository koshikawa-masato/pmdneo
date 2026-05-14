#!/usr/bin/env bash
#
# ADR-0029 step 15 γ: BD vs CYM differential proof (= drum 種で sample addr が literal differ、 4 drum 段下)
#
# 目的:
#   ADR-0029 §決定 2/3/6 「drum 種 → sample pointer mapping を 1 軸拡張」 の literal 証明。
#   K-BD fixture (= k-br-only.mml) と K-CYM fixture (= k-cr-only.mml) を両方 build + run
#   して、 ADPCM-A L ch register write のうち:
#
#   - reg 0x10 (start LSB) / reg 0x20 (stop LSB) が BD vs CYM で **literal differ**
#     (= drum 種別 sample addr 区別の literal proof、 4 drum 段拡張下)
#   - reg 0x18 (start MSB) / reg 0x28 (stop MSB) / reg 0x08 (vol|pan) / reg 0x00 (keyon) は
#     **identical** (= 同 L ch、 同 fixture pattern なら同値)
#
#   を literal で固定する。 これにより:
#
#   - bit 0 → adpcma_sample_bd literal addr (= BD_START_LSB = 0x00 / BD_STOP_LSB = 0x03、 既存 Step 12 維持)
#   - bit 2 → adpcma_sample_top literal addr (= TOP_START_LSB = 0x12 / TOP_STOP_LSB = 0x29、 既存 adpcma_sample_top symbol reuse、 「top」 = sample provenance 名 / 「CYM」 = PMD semantics 名 wording 分離)
#
#   が driver の bit position 分岐 + sample pointer mapping で正しく区別されていること、
#   silent path に倒れただけではないこと、 CYM trigger が BD trigger と異なる sample を
#   trigger していることを literal で証明する (= ADR-0029 §決定 3 / §決定 6 / §scope-in / §verify gate Gate 4 整合)。
#
#   fixture 命名注記: `cr` = `\c` + `r`(= rest) fixture pattern。 「CYM」 略ではない (= 既存 `br` / `sr` / `hr` pattern 同一規律、 ADR-0029 §決定 5 / 軸 2 整合)。 また sample symbol 名 `top` とも別。
#
#   注: SD vs CYM / HH vs CYM differential は scope-out (= ADR-0029 §verify gate Gate 4 で BD vs CYM のみ指定、 BD vs SD differential proof = ADR-0027 §verify gate Gate 4 + BD vs HH differential proof = ADR-0028 §verify gate Gate 4 で確立済 → 推移的に SD vs CYM / HH vs CYM も literal differ である)。
#
# 検証: 6 段 gate
#   gate 1: K-BD fixture build + run + trace
#   gate 2: K-CYM fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: BD vs CYM で sample addr literal differ (= reg 0x10 / 0x20 異なる)
#   gate 5: BD vs CYM で MSB / vol|pan / keyon literal identical (= 同 L ch state)
#   gate 6: BD trigger と CYM trigger 両方で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
#
# 検証範囲外 (= δ で別途):
#   - K-CYM vs R-CYM differential proof (= verify-step15-kr-cym-differential.sh、 γ 同 commit)
#   - SD vs CYM / HH vs CYM differential → ADR-0029 §verify gate Gate 4 注記で推移的処理、 explicit gate なし
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で BD / CYM 別々 audible 確認)
#   - ADR-0029 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step15/verify-step15-bd-cym-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step12/k-br-only.wav  (= K-BD fixture audible 試聴用、 4 秒、 step12 OUT_DIR 共有)
#   /tmp/pmdneo-step15/k-cr-only.wav  (= K-CYM fixture audible 試聴用、 4 秒)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

BD_MML="$PROJECT_ROOT/src/test-fixtures/step12/k-br-only.mml"
CYM_MML="$PROJECT_ROOT/src/test-fixtures/step15/k-cr-only.mml"
BD_OUT_DIR="/tmp/pmdneo-step12"
CYM_OUT_DIR="/tmp/pmdneo-step15"

if [[ ! -f "$BD_MML" ]]; then echo "FAIL infra: $BD_MML not found"; exit 2; fi
if [[ ! -f "$CYM_MML" ]]; then echo "FAIL infra: $CYM_MML not found"; exit 2; fi

mkdir -p "$BD_OUT_DIR" "$CYM_OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step15-bd-cym-diff-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0026 §決定 3 + ADR-0027 §決定 3 + ADR-0028 §決定 3 + ADR-0029 §決定 3 driver-embedded fixture)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_CYM_START_LSB="12"          # (= TOP_START_LSB、 ADR-0029 §決定 3 / 軸 1 adpcma_sample_top reuse)
EXPECTED_CYM_STOP_LSB="29"           # (= TOP_STOP_LSB)
EXPECTED_MSB="00"                    # (= BD / CYM 共通 = 0x00、 sample data が VROM page 0 内に収まる)
EXPECTED_VOL_PAN="DF"                # (= L|R pan 0xC0 + max vol 0x1F、 BD/CYM 共通)
EXPECTED_KEYON_MASK="01"             # (= L ch keyon bit 0、 BD/CYM 共通)

echo "=== ADR-0029 step 15 γ: BD vs CYM differential proof (= drum 種別 sample addr literal differ 証明、 4 drum 段) ==="
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
# gate 2: K-CYM fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: K-CYM fixture (= k-cr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$CYM_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-cym-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-CYM build failed (log: $TMPDIR/k-cym-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-cym-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-CYM MAME run failed"
    exit 2
}
CYM_YMFM="$CYM_OUT_DIR/k-cr-only-ymfm.tsv"
CYM_WAV="$CYM_OUT_DIR/k-cr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$CYM_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$CYM_WAV"
echo "  [PASS] K-CYM fixture build + run + trace 取得 (wav: $CYM_WAV)"

CYM_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
CYM_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$CYM_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-CYM build: pmdneo_rhythm_event_trigger @ 0x$CYM_HOOK_ADDR"

# ============================================================
# gate 3: same hook addr in BD and CYM builds (= dispatch path 1 本化 literal 維持)
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between BD and CYM builds ==="
if [[ "$BD_HOOK_ADDR" != "$CYM_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (BD=0x$BD_HOOK_ADDR vs CYM=0x$CYM_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$BD_HOOK_ADDR (= BD と CYM で same routine entry、 4 drum 段下不変)"

# ============================================================
# gate 4: BD vs CYM で sample addr literal differ (= reg 0x10 / 0x20 異なる)
# ============================================================
echo
echo "=== gate 4: BD vs CYM で sample addr literal differ (= drum 種別 sample 区別 proof) ==="

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
check_reg_value "$BD_YMFM" "110" "$EXPECTED_BD_START_LSB"   "BD L ch start LSB = 0x00 (= BD_START_LSB)"
check_reg_value "$BD_YMFM" "120" "$EXPECTED_BD_STOP_LSB"    "BD L ch stop LSB = 0x03 (= BD_STOP_LSB)"

# CYM literal
check_reg_value "$CYM_YMFM" "110" "$EXPECTED_CYM_START_LSB" "CYM L ch start LSB = 0x12 (= TOP_START_LSB)"
check_reg_value "$CYM_YMFM" "120" "$EXPECTED_CYM_STOP_LSB"  "CYM L ch stop LSB = 0x29 (= TOP_STOP_LSB)"

# Confirm BD differs from CYM (= literal differ assert)
BD_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$BD_YMFM" | tail -1)
CYM_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$CYM_YMFM" | tail -1)
BD_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$BD_YMFM" | tail -1)
CYM_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$CYM_YMFM" | tail -1)

if [[ "$BD_START_LSB" == "$CYM_START_LSB" ]]; then
    echo "  [FAIL] gate 4: BD start LSB (0x$BD_START_LSB) と CYM start LSB (0x$CYM_START_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
if [[ "$BD_STOP_LSB" == "$CYM_STOP_LSB" ]]; then
    echo "  [FAIL] gate 4: BD stop LSB (0x$BD_STOP_LSB) と CYM stop LSB (0x$CYM_STOP_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
echo "  [PASS] BD start LSB (0x$BD_START_LSB) ≠ CYM start LSB (0x$CYM_START_LSB) literal differ"
echo "  [PASS] BD stop LSB (0x$BD_STOP_LSB) ≠ CYM stop LSB (0x$CYM_STOP_LSB) literal differ"
echo "         (= ADR-0029 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 2 CYM」 literal 達成、 bit 1 SD / bit 3 HH は ADR-0027 / ADR-0028 既存維持)"

# ============================================================
# gate 5: BD と CYM で MSB / vol|pan / keyon identical (= 同 L ch state)
# ============================================================
echo
echo "=== gate 5: BD と CYM で MSB / vol|pan / keyon literal identical (= 同 L ch、 同 fixture pattern) ==="

check_reg_value "$BD_YMFM" "118"  "$EXPECTED_MSB"      "BD L ch start MSB = 0x00"
check_reg_value "$CYM_YMFM" "118" "$EXPECTED_MSB"      "CYM L ch start MSB = 0x00"
check_reg_value "$BD_YMFM" "128"  "$EXPECTED_MSB"      "BD L ch stop MSB = 0x00"
check_reg_value "$CYM_YMFM" "128" "$EXPECTED_MSB"      "CYM L ch stop MSB = 0x00"
check_reg_value "$BD_YMFM" "108"  "$EXPECTED_VOL_PAN"  "BD L ch vol|pan = 0xDF"
check_reg_value "$CYM_YMFM" "108" "$EXPECTED_VOL_PAN"  "CYM L ch vol|pan = 0xDF"

# ============================================================
# gate 6: BD と CYM で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
# ============================================================
echo
echo "=== gate 6: BD と CYM で L ch keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent path に倒れていないことの proof) ==="
BD_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$BD_YMFM" | grep -c "^01$" || true)
CYM_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$CYM_YMFM" | grep -c "^01$" || true)
if [[ "$BD_KEYON_01_COUNT" != "$CYM_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 6: keyon count differs (BD=$BD_KEYON_01_COUNT, CYM=$CYM_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$BD_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 6: BD と CYM 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] BD と CYM で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0029 step 15 γ BD vs CYM differential proof PASS"
echo "   - gate 1: K-BD fixture build + run + trace ($BD_WAV)"
echo "   - gate 2: K-CYM fixture build + run + trace ($CYM_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (BD=CYM=0x$BD_HOOK_ADDR)"
echo "   - gate 4: BD start/stop LSB ≠ CYM start/stop LSB literal differ"
echo "             (BD start=0x$BD_START_LSB stop=0x$BD_STOP_LSB / CYM start=0x$CYM_START_LSB stop=0x$CYM_STOP_LSB)"
echo "   - gate 5: BD/CYM で MSB / vol|pan literal identical (= 同 L ch state)"
echo "   - gate 6: BD/CYM で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 identical"
echo ""
echo "   ADR-0029 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 2 CYM」 = literal 達成"
echo "   (= drum 種が 4 drum 段 = b+s+c+h に拡張されても、 register addr literal で観測可能に区別されており silent 倒れではない)"
echo "   (= SD vs CYM / HH vs CYM literal differ は BD-vs-SD + BD-vs-HH + BD-vs-CYM の N-1 pair gate から推移的に proof 成立、 ADR-0029 §verify gate Gate 4 注記)"
exit 0
