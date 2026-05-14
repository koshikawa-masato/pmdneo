#!/usr/bin/env bash
#
# ADR-0027 step 13 γ: BD vs SD differential proof (= drum 種で sample addr が literal differ)
#
# 目的:
#   ADR-0027 §決定 2/3/6 「drum 種 → sample pointer mapping を 1 軸拡張」 の literal 証明。
#   K-BD fixture (= k-br-only.mml) と K-SD fixture (= k-sr-only.mml) を両方 build + run
#   して、 ADPCM-A L ch register write のうち:
#
#   - reg 0x10 (start LSB) / reg 0x20 (stop LSB) が BD vs SD で **literal differ**
#     (= drum 種別 sample addr 区別の literal proof)
#   - reg 0x18 (start MSB) / reg 0x28 (stop MSB) / reg 0x08 (vol|pan) / reg 0x00 (keyon) は
#     **identical** (= 同 L ch、 同 fixture pattern なら同値)
#
#   を literal で固定する。 これにより:
#
#   - bit 0 → adpcma_sample_bd literal addr (= BD_START_LSB = 0x00 / BD_STOP_LSB = 0x03)
#   - bit 1 → adpcma_sample_sd literal addr (= SD_START_LSB = 0x04 / SD_STOP_LSB = 0x06)
#
#   が driver の bit position 分岐 + sample pointer mapping で正しく区別されていること、
#   silent path に倒れただけではないこと、 SD trigger が BD trigger と異なる sample を
#   trigger していることを literal で証明する (= ADR-0027 §決定 6 / §scope-in / §verify gate 4 整合)。
#
# 検証: 6 段 gate
#   gate 1: K-BD fixture build + run + trace
#   gate 2: K-SD fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力)
#   gate 4: BD vs SD で sample addr literal differ (= reg 0x10 / 0x20 異なる)
#   gate 5: BD vs SD で MSB / vol|pan / keyon literal identical (= 同 L ch state)
#   gate 6: BD trigger と SD trigger 両方で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
#
# 検証範囲外 (= δ で別途):
#   - K-SD vs R-SD differential proof (= verify-step13-kr-sd-differential.sh、 γ 同 commit)
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で BD / SD 別々 audible 確認)
#   - ADR-0027 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step13/verify-step13-bd-sd-differential.sh
#
# 副作用:
#   /tmp/pmdneo-step12/k-br-only.wav  (= K-BD fixture audible 試聴用、 4 秒、 step12 OUT_DIR 共有)
#   /tmp/pmdneo-step13/k-sr-only.wav  (= K-SD fixture audible 試聴用、 4 秒)
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

BD_MML="$PROJECT_ROOT/src/test-fixtures/step12/k-br-only.mml"
SD_MML="$PROJECT_ROOT/src/test-fixtures/step13/k-sr-only.mml"
BD_OUT_DIR="/tmp/pmdneo-step12"
SD_OUT_DIR="/tmp/pmdneo-step13"

if [[ ! -f "$BD_MML" ]]; then echo "FAIL infra: $BD_MML not found"; exit 2; fi
if [[ ! -f "$SD_MML" ]]; then echo "FAIL infra: $SD_MML not found"; exit 2; fi

mkdir -p "$BD_OUT_DIR" "$SD_OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step13-bd-sd-diff-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0026 §決定 3 + ADR-0027 §決定 3 driver-embedded fixture)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_SD_START_LSB="04"
EXPECTED_SD_STOP_LSB="06"
EXPECTED_MSB="00"                    # (= BD / SD 共通 = 0x00、 sample data が VROM page 0 内に収まる)
EXPECTED_VOL_PAN="DF"                # (= L|R pan 0xC0 + max vol 0x1F、 BD/SD 共通)
EXPECTED_KEYON_MASK="01"             # (= L ch keyon bit 0、 BD/SD 共通)

echo "=== ADR-0027 step 13 γ: BD vs SD differential proof (= drum 種別 sample addr literal differ 証明) ==="
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
# gate 2: K-SD fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: K-SD fixture (= k-sr-only.mml) build + run + trace ==="
PMDDOTNET_MML="$SD_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-sd-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-SD build failed (log: $TMPDIR/k-sd-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-sd-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: K-SD MAME run failed"
    exit 2
}
SD_YMFM="$SD_OUT_DIR/k-sr-only-ymfm.tsv"
SD_WAV="$SD_OUT_DIR/k-sr-only.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$SD_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$SD_WAV"
echo "  [PASS] K-SD fixture build + run + trace 取得 (wav: $SD_WAV)"

SD_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
SD_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$SD_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-SD build: pmdneo_rhythm_event_trigger @ 0x$SD_HOOK_ADDR"

# ============================================================
# gate 3: same hook addr in BD and SD builds (= dispatch path 1 本化 literal 維持)
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger addr identical between BD and SD builds ==="
if [[ "$BD_HOOK_ADDR" != "$SD_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (BD=0x$BD_HOOK_ADDR vs SD=0x$SD_HOOK_ADDR)"
    echo "         これは driver layout が build 間で違うことを意味する (= 想定外)"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x$BD_HOOK_ADDR (= BD と SD で same routine entry)"

# ============================================================
# gate 4: BD vs SD で sample addr literal differ (= reg 0x10 / 0x20 異なる)
# ============================================================
echo
echo "=== gate 4: BD vs SD で sample addr literal differ (= drum 種別 sample 区別 proof) ==="

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

# SD literal
check_reg_value "$SD_YMFM" "110" "$EXPECTED_SD_START_LSB" "SD L ch start LSB = 0x04 (= SD_START_LSB)"
check_reg_value "$SD_YMFM" "120" "$EXPECTED_SD_STOP_LSB"  "SD L ch stop LSB = 0x06 (= SD_STOP_LSB)"

# Confirm BD differs from SD (= literal differ assert)
BD_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$BD_YMFM" | tail -1)
SD_START_LSB=$(awk -F'\t' '$2 == "B" && $3 == "110" {print toupper($4)}' "$SD_YMFM" | tail -1)
BD_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$BD_YMFM" | tail -1)
SD_STOP_LSB=$(awk -F'\t' '$2 == "B" && $3 == "120" {print toupper($4)}' "$SD_YMFM" | tail -1)

if [[ "$BD_START_LSB" == "$SD_START_LSB" ]]; then
    echo "  [FAIL] gate 4: BD start LSB (0x$BD_START_LSB) と SD start LSB (0x$SD_START_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
if [[ "$BD_STOP_LSB" == "$SD_STOP_LSB" ]]; then
    echo "  [FAIL] gate 4: BD stop LSB (0x$BD_STOP_LSB) と SD stop LSB (0x$SD_STOP_LSB) が identical (= 区別なし、 想定外)"
    exit 1
fi
echo "  [PASS] BD start LSB (0x$BD_START_LSB) ≠ SD start LSB (0x$SD_START_LSB) literal differ"
echo "  [PASS] BD stop LSB (0x$BD_STOP_LSB) ≠ SD stop LSB (0x$SD_STOP_LSB) literal differ"
echo "         (= ADR-0027 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 1 SD」 literal 達成)"

# ============================================================
# gate 5: BD と SD で MSB / vol|pan / keyon identical (= 同 L ch state)
# ============================================================
echo
echo "=== gate 5: BD と SD で MSB / vol|pan / keyon literal identical (= 同 L ch、 同 fixture pattern) ==="

check_reg_value "$BD_YMFM" "118" "$EXPECTED_MSB"     "BD L ch start MSB = 0x00"
check_reg_value "$SD_YMFM" "118" "$EXPECTED_MSB"     "SD L ch start MSB = 0x00"
check_reg_value "$BD_YMFM" "128" "$EXPECTED_MSB"     "BD L ch stop MSB = 0x00"
check_reg_value "$SD_YMFM" "128" "$EXPECTED_MSB"     "SD L ch stop MSB = 0x00"
check_reg_value "$BD_YMFM" "108" "$EXPECTED_VOL_PAN" "BD L ch vol|pan = 0xDF"
check_reg_value "$SD_YMFM" "108" "$EXPECTED_VOL_PAN" "SD L ch vol|pan = 0xDF"

# ============================================================
# gate 6: BD と SD で keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent ではない)
# ============================================================
echo
echo "=== gate 6: BD と SD で L ch keyon mask 0x01 trigger 1 件 (= 同回数発火、 silent path に倒れていないことの proof) ==="
BD_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$BD_YMFM" | grep -c "^01$" || true)
SD_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$SD_YMFM" | grep -c "^01$" || true)
if [[ "$BD_KEYON_01_COUNT" != "$SD_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 6: keyon count differs (BD=$BD_KEYON_01_COUNT, SD=$SD_KEYON_01_COUNT)"
    exit 1
fi
if [[ "$BD_KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 6: BD と SD 共に keyon trigger 0 件 (= silent path に倒れた)"
    exit 1
fi
echo "  [PASS] BD と SD で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 (= 同回数発火)"

echo
echo "🎉 ADR-0027 step 13 γ BD vs SD differential proof PASS"
echo "   - gate 1: K-BD fixture build + run + trace ($BD_WAV)"
echo "   - gate 2: K-SD fixture build + run + trace ($SD_WAV)"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (BD=SD=0x$BD_HOOK_ADDR)"
echo "   - gate 4: BD start/stop LSB ≠ SD start/stop LSB literal differ"
echo "             (BD start=0x$BD_START_LSB stop=0x$BD_STOP_LSB / SD start=0x$SD_START_LSB stop=0x$SD_STOP_LSB)"
echo "   - gate 5: BD/SD で MSB / vol|pan literal identical (= 同 L ch state)"
echo "   - gate 6: BD/SD で L ch keyon mask 0x01 trigger count = $BD_KEYON_01_COUNT 件 identical"
echo ""
echo "   ADR-0027 §決定 6 「drum 種 → sample pointer mapping bit 0 BD / bit 1 SD」 = literal 達成"
echo "   (= drum 種が register addr literal で観測可能に区別されており、 silent 倒れではない)"
exit 0
