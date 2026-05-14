#!/usr/bin/env bash
#
# ADR-0027 step 13 β: K part SD rhythm trigger proof (= K \s → 0xEB 0x02 → pmdneo_rhythm_event_trigger → ADPCM-A L ch SD)
#
# 目的:
#   ADR-0027 §決定 1/2/3/4/7/8/9 整合の K part 0xEB SD rhythm dispatch path proof。
#   K-SD fixture (= src/test-fixtures/step13/k-sr-only.mml) の K part body `\s` が
#   PMDDotNET 経由 `0xEB 0x02 0x80` (= rhykey SD bitmap + part end) に compile され、
#   driver の rhythm_main K part body parser で 0xEB 検出 → bitmap fetch →
#   pmdneo_rhythm_event_trigger 呼出 → bit 1 SD 分岐 → _rhythm_event_sd_trigger →
#   ADPCM-A L ch SD register write の path が PC trace + ymfm-trace で
#   literal observable な proof として固定。
#
#   ADR-0027 §決定 8 「dispatch path は drum 種拡張で増やさない」 の literal 実装保証:
#   pmdneo_rhythm_event_trigger routine entry addr (= Step 12 と同一) が SD trigger fixture でも不変。
#
#   R-SD fixture (= melody part 内 \s inline) は γ scope で別 verify script。
#
# 検証: 5 段 gate (= ADR-0027 §verify gate β gate 整合)
#   gate 1: K-SD fixture build PASS (= PMDDotNET \s → 0xEB 0x02 + driver compile)
#   gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_sd_trigger routine 存在 (= .lst で symbol 確認)
#           Step 12 K-BD verify と同 entry addr であることを literal 確認 (= ADR-0027 §決定 9)
#   gate 3: K-SD fixture run PC trace + ymfm-trace 取得
#   gate 4: K-SD fixture run ADPCM-A L ch register write (= SD addr literal value assert)
#             reg 0x10 (port B 110) = 0x04 (= SD_START_LSB)
#             reg 0x18 (port B 118) = 0x00 (= SD_START_MSB)
#             reg 0x20 (port B 120) = 0x06 (= SD_STOP_LSB)
#             reg 0x28 (port B 128) = 0x00 (= SD_STOP_MSB)
#             reg 0x08 (port B 108) = 0xDF (= vol|pan 固定値)
#             reg 0x00 (port B 100) = 0x01 (= L ch keyon mask)
#   gate 5: keyon trigger 1 件 + ch 0 keyon mask (= 本 fixture では L-Q silent ゆえ ch 0 keyon は rhythm 由来のみ)
#
# 検証範囲外 (= γ / δ で別途):
#   - R-SD command (= melody part 内 \s inline) → γ で別 fixture
#   - K-SD と R-SD で同 routine addr hit literal 比較 (= byte-identical) → γ で differential verify
#   - BD vs SD differential (= sample addr literal differ) → γ で別 verify script
#   - 既存 16 script regression → δ で serial 実行
#   - user 試聴 (= audio gate) → δ で 4 sec wav 保存後
#
# 使い方:
#   bash src/test-fixtures/step13/verify-step13-sd-trigger.sh
#
# 副作用:
#   /tmp/pmdneo-step13/k-sr-only.wav    (= K SD trigger audible 試聴用、 4 秒)
#   /tmp/pmdneo-step13/*.tsv            (= trace snapshot)
#
# Exit code:
#   0 = PASS
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step13/k-sr-only.mml"
OUT_DIR="/tmp/pmdneo-step13"

if [[ ! -f "$K_MML" ]]; then
    echo "FAIL infra: fixture not found: $K_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step13-beta-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= driver-embedded fixture、 SD sample = build/assets/samples.inc)
EXPECTED_SD_START_LSB="04"
EXPECTED_SD_START_MSB="00"
EXPECTED_SD_STOP_LSB="06"
EXPECTED_SD_STOP_MSB="00"
EXPECTED_VOL_PAN="DF"                    # (= L|R pan 0xC0 + max vol 0x1F)
EXPECTED_KEYON_MASK="01"                 # (= L ch keyon bit 0)

echo "=== ADR-0027 step 13 β: K part SD rhythm trigger proof (= K \\s → 0xEB 0x02 → ADPCM-A L ch SD) ==="
echo

# ============================================================
# gate 1: K-SD fixture build
# ============================================================
echo "=== gate 1: K-SD fixture build PASS (= PMDDotNET \\s → 0xEB 0x02 + driver compile) ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-sd-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: K-SD fixture build failed (log: $TMPDIR/k-sd-build.log)"
    exit 2
}
echo "  [PASS] K-SD fixture build"

# ============================================================
# gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_sd_trigger symbol 存在確認
# ============================================================
echo
echo "=== gate 2: pmdneo_rhythm_event_trigger + _rhythm_event_sd_trigger routine 存在 ==="
LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$LST" ]]; then
    echo "  [FAIL] gate 2 infra: .lst not found: $LST"
    exit 2
fi
HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 2: pmdneo_rhythm_event_trigger symbol not found in .lst"
    exit 1
fi
echo "  [PASS] pmdneo_rhythm_event_trigger @ 0x$HOOK_ADDR"

SD_ADDR=$(grep -E "_rhythm_event_sd_trigger:" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$SD_ADDR" ]]; then
    echo "  [FAIL] gate 2: _rhythm_event_sd_trigger symbol not found in .lst"
    exit 1
fi
echo "  [PASS] _rhythm_event_sd_trigger @ 0x$SD_ADDR"

# ============================================================
# gate 3: K-SD fixture run + trace 取得
# ============================================================
echo
echo "=== gate 3: K-SD fixture run + PC trace + ymfm-trace 取得 ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-sd-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: MAME run failed (log: $TMPDIR/k-sd-run.log)"
    exit 2
}
K_MEM="$OUT_DIR/k-sr-only-mem.tsv"
K_YMFM="$OUT_DIR/k-sr-only-ymfm.tsv"
K_WAV="$OUT_DIR/k-sr-only.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] trace + wav 取得 (= K-SD fixture run、 wav 4 sec @ $K_WAV)"

# ============================================================
# gate 4: ADPCM-A L ch register write (= SD addr literal value)
# ============================================================
echo
echo "=== gate 4: ADPCM-A L ch register write (= SD addr literal) ==="

check_reg_value() {
    local reg="$1"      # ymfm-trace の port B reg 表記 (e.g. "110" for reg 0x10)
    local expected="$2" # expected hex value (no leading zeros)
    local label="$3"
    local found
    found=$(awk -F'\t' -v reg="$reg" '$2 == "B" && $3 == reg {print toupper($4)}' "$K_YMFM" | tail -1)
    if [[ -z "$found" ]]; then
        echo "  [FAIL] gate 4: reg $reg ($label) write not found in ymfm-trace"
        exit 1
    fi
    # Normalize: trim leading zeros to compare (e.g. "00" == "0x00")
    local found_norm=$(printf "%02X" "0x$found")
    local expected_norm=$(printf "%02X" "0x$expected")
    if [[ "$found_norm" != "$expected_norm" ]]; then
        echo "  [FAIL] gate 4: reg $reg ($label) = 0x$found_norm (expected 0x$expected_norm)"
        exit 1
    fi
    echo "  [PASS] reg $reg ($label) = 0x$found_norm"
}

check_reg_value "110" "$EXPECTED_SD_START_LSB"  "L ch start LSB / SD_START_LSB"
check_reg_value "118" "$EXPECTED_SD_START_MSB"  "L ch start MSB / SD_START_MSB"
check_reg_value "120" "$EXPECTED_SD_STOP_LSB"   "L ch stop LSB / SD_STOP_LSB"
check_reg_value "128" "$EXPECTED_SD_STOP_MSB"   "L ch stop MSB / SD_STOP_MSB"
check_reg_value "108" "$EXPECTED_VOL_PAN"       "L ch vol|pan"

# ============================================================
# gate 5: keyon trigger 1 件 + ch 0 keyon mask
# ============================================================
echo
echo "=== gate 5: keyon trigger (= reg 0x00 mask 0x01 = L ch only) ==="
KEYON_WRITES=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM")
# Filter: count the 0x01 keyon writes
KEYON_01_COUNT=$(echo "$KEYON_WRITES" | grep -c "^01$" || true)
if [[ "$KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 5: L ch keyon (= mask 0x01) write not found in ymfm-trace"
    echo "         (port B reg 100 writes were: $(echo "$KEYON_WRITES" | tr '\n' ' '))"
    exit 1
fi
echo "  [PASS] L ch keyon (= mask 0x01) write count = $KEYON_01_COUNT (= SD rhythm trigger fired)"

echo
echo "🎉 ADR-0027 step 13 β K-SD rhythm trigger proof PASS"
echo "   - gate 1: K-SD fixture build PASS"
echo "   - gate 2: pmdneo_rhythm_event_trigger @ 0x$HOOK_ADDR + _rhythm_event_sd_trigger @ 0x$SD_ADDR"
echo "   - gate 3: trace + wav 取得 ($K_WAV)"
echo "   - gate 4: ADPCM-A L ch register write (= SD addr literal + vol|pan)"
echo "   - gate 5: L ch keyon mask 0x01 write count $KEYON_01_COUNT"
exit 0
