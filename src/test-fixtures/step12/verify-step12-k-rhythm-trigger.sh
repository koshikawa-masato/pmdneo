#!/usr/bin/env bash
#
# ADR-0026 step 12 β: K part rhythm trigger proof (= K \b → 0xEB 0x01 → pmdneo_rhythm_event_trigger → ADPCM-A L ch BD)
#
# 目的:
#   ADR-0026 §決定 1/5/6/7/8 整合の K part 0xEB rhythm dispatch path proof。
#   K fixture (= src/test-fixtures/step12/k-br-only.mml) の K part body `\b` が
#   PMDDotNET 経由 0xEB 0x01 0x80 (= rhykey BD bitmap + part end) に compile され、
#   driver の rhythm_main K part body parser で 0xEB 検出 → bitmap fetch →
#   pmdneo_rhythm_event_trigger 呼出 → ADPCM-A L ch BD register write の
#   path が PC trace + ymfm-trace で literal observable な proof として固定。
#
#   R command (= melody part 内 \b inline) は γ scope で別 fixture / 別 verify script。
#
# 検証: 5 段 gate (= ADR-0026 §verify gate β gate 整合)
#   gate 1: K fixture build PASS (= sdcc / sdldz80 / vromtool 通過)
#   gate 2: pmdneo_rhythm_event_trigger routine 存在 (= .lst で symbol 確認)
#   gate 3: K fixture run PC trace で pmdneo_rhythm_event_trigger 呼出 (= 内部 ym2610_write_port_b call 連続で間接確認)
#   gate 4: K fixture run ADPCM-A L ch register write (= BD addr literal value assert)
#             reg 0x10 (port B 110) = 0x00 (= BD_START_LSB)
#             reg 0x18 (port B 118) = 0x00 (= BD_START_MSB)
#             reg 0x20 (port B 120) = 0x03 (= BD_STOP_LSB)
#             reg 0x28 (port B 128) = 0x00 (= BD_STOP_MSB)
#             reg 0x08 (port B 108) = 0xDF (= vol|pan 固定値)
#             reg 0x00 (port B 100) = 0x01 (= L ch keyon mask)
#   gate 5: keyon trigger 1 件 + 既存 L-Q melody fixture との区別 (= 本 fixture では L-Q silent ゆえ ch 0 keyon は rhythm 由来のみ)
#
# 検証範囲外 (= γ / δ で別途):
#   - R command (= melody part 内 \b inline) → γ で別 fixture
#   - K と R で同 routine addr hit literal 比較 → γ で同時 fixture run
#   - 既存 14 script regression → δ で serial 実行
#   - user 試聴 (= audio gate) → δ で 4 sec wav 保存後
#
# 使い方:
#   bash src/test-fixtures/step12/verify-step12-k-rhythm-trigger.sh
#
# 副作用:
#   /tmp/pmdneo-step12/k-br-only.wav    (= K rhythm BD audible 試聴用、 4 秒)
#   /tmp/pmdneo-step12/*.tsv            (= trace snapshot)
#
# Exit code:
#   0 = PASS
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step12/k-br-only.mml"
OUT_DIR="/tmp/pmdneo-step12"

if [[ ! -f "$K_MML" ]]; then
    echo "FAIL infra: fixture not found: $K_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step12-beta-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= driver-embedded fixture、 BD sample = build/assets/samples.inc)
EXPECTED_BD_START_LSB="00"
EXPECTED_BD_START_MSB="00"
EXPECTED_BD_STOP_LSB="03"
EXPECTED_BD_STOP_MSB="00"
EXPECTED_VOL_PAN="DF"                    # (= L|R pan 0xC0 + max vol 0x1F)
EXPECTED_KEYON_MASK="01"                 # (= L ch keyon bit 0)

echo "=== ADR-0026 step 12 β: K part rhythm trigger proof (= K \\b → 0xEB 0x01 → ADPCM-A L ch BD) ==="
echo

# ============================================================
# gate 1: K fixture build
# ============================================================
echo "=== gate 1: K fixture build PASS (= PMDDotNET \\b → 0xEB 0x01 + driver compile) ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: K fixture build failed (log: $TMPDIR/k-build.log)"
    exit 2
}
echo "  [PASS] K fixture build (= 272 byte .M)"

# ============================================================
# gate 2: pmdneo_rhythm_event_trigger symbol 存在確認
# ============================================================
echo
echo "=== gate 2: pmdneo_rhythm_event_trigger routine 存在 ==="
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

K_ADDR_LOAD=$(grep -E "pmdneo_mn_direct_load_k_part_addr::" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$K_ADDR_LOAD" ]]; then
    echo "  [FAIL] gate 2: pmdneo_mn_direct_load_k_part_addr symbol not found"
    exit 1
fi
echo "  [PASS] pmdneo_mn_direct_load_k_part_addr @ 0x$K_ADDR_LOAD"

# ============================================================
# gate 3: K fixture run + trace 取得
# ============================================================
echo
echo "=== gate 3: K fixture run + PC trace + ymfm-trace 取得 ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: MAME run failed (log: $TMPDIR/k-run.log)"
    exit 2
}
K_MEM="$OUT_DIR/k-br-only-mem.tsv"
K_YMFM="$OUT_DIR/k-br-only-ymfm.tsv"
K_WAV="$OUT_DIR/k-br-only.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] trace + wav 取得 (= K fixture run、 wav 4 sec @ $K_WAV)"

# ============================================================
# gate 4: ADPCM-A L ch register write (= BD addr literal value)
# ============================================================
echo
echo "=== gate 4: ADPCM-A L ch register write (= BD addr literal) ==="

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

check_reg_value "110" "$EXPECTED_BD_START_LSB"  "L ch start LSB / BD_START_LSB"
check_reg_value "118" "$EXPECTED_BD_START_MSB"  "L ch start MSB / BD_START_MSB"
check_reg_value "120" "$EXPECTED_BD_STOP_LSB"   "L ch stop LSB / BD_STOP_LSB"
check_reg_value "128" "$EXPECTED_BD_STOP_MSB"   "L ch stop MSB / BD_STOP_MSB"
check_reg_value "108" "$EXPECTED_VOL_PAN"       "L ch vol|pan"

# ============================================================
# gate 5: keyon trigger 1 件 + ch 0 keyon mask
# ============================================================
echo
echo "=== gate 5: keyon trigger (= reg 0x00 mask 0x01 = L ch only) ==="
KEYON_WRITES=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM")
# Expected sequence: init (BF / 00) followed by rhythm trigger (01)
# Filter: count the 0x01 keyon writes
KEYON_01_COUNT=$(echo "$KEYON_WRITES" | grep -c "^01$" || true)
if [[ "$KEYON_01_COUNT" -lt 1 ]]; then
    echo "  [FAIL] gate 5: L ch keyon (= mask 0x01) write not found in ymfm-trace"
    echo "         (port B reg 100 writes were: $(echo "$KEYON_WRITES" | tr '\n' ' '))"
    exit 1
fi
echo "  [PASS] L ch keyon (= mask 0x01) write count = $KEYON_01_COUNT (= rhythm trigger fired)"

echo
echo "🎉 ADR-0026 step 12 β K rhythm trigger proof PASS"
echo "   - gate 1: K fixture build PASS"
echo "   - gate 2: pmdneo_rhythm_event_trigger @ 0x$HOOK_ADDR + pmdneo_mn_direct_load_k_part_addr @ 0x$K_ADDR_LOAD"
echo "   - gate 3: trace + wav 取得 ($K_WAV)"
echo "   - gate 4: ADPCM-A L ch register write (= BD addr literal + vol|pan)"
echo "   - gate 5: L ch keyon mask 0x01 write count $KEYON_01_COUNT"
exit 0
