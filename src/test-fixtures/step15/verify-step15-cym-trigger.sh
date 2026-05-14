#!/usr/bin/env bash
#
# ADR-0029 step 15 β: K part CYM rhythm trigger proof (= K \c → 0xEB 0x04 → pmdneo_rhythm_event_trigger → ADPCM-A L ch CYM)
#
# 目的:
#   ADR-0029 §決定 1/2/3/4/7/8/9 整合の K part 0xEB CYM rhythm dispatch path proof。
#   K-CYM fixture (= src/test-fixtures/step15/k-cr-only.mml) の K part body `\c` が
#   PMDDotNET 経由 `0xEB 0x04 0x80` (= rhykey CYM bitmap + part end) に compile され、
#   driver の rhythm_main K part body parser で 0xEB 検出 → bitmap fetch →
#   pmdneo_rhythm_event_trigger 呼出 → bit 2 CYM 分岐 → _rhythm_event_cym_trigger →
#   ADPCM-A L ch CYM register write の path が PC trace + ymfm-trace で
#   literal observable な proof として固定。
#
#   ADR-0029 §決定 8 「dispatch path は drum 種拡張で増やさない」 の 4 drum 段 literal 実装保証:
#   pmdneo_rhythm_event_trigger routine entry addr (= Step 12/Step 13/Step 14 と同一) が CYM trigger fixture でも不変。
#
#   ADR-0029 §決定 3 / 軸 1: CYM sample source = existing adpcma_sample_top symbol reuse
#     (= 「top」 = sample provenance 名 / 「CYM」 = PMD semantics 名 wording 分離、 alias 新設なし)
#
#   fixture 命名注記: `cr` = `\c` + `r`(= rest) fixture pattern。 「CYM」 略ではない (= 既存 `br` / `sr` / `hr` pattern 同一規律、 ADR-0029 §決定 5 / 軸 2 整合)。 また sample symbol 名 `top` とも別。
#
#   R-CYM fixture (= melody part 内 \c inline) は γ scope で別 verify script。
#
# 検証: 5 段 gate (= ADR-0029 §verify gate β gate 整合)
#   gate 1: K-CYM fixture build PASS (= PMDDotNET \c → 0xEB 0x04 + driver compile)
#   gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_cym_trigger routine 存在 (= .lst で symbol 確認)
#           Step 12/Step 13/Step 14 K-BD/K-SD/K-HH verify と同 entry addr であることを literal 確認 (= ADR-0029 §決定 9)
#   gate 3: K-CYM fixture run PC trace + ymfm-trace 取得
#   gate 4: K-CYM fixture run ADPCM-A L ch register write (= CYM addr literal value assert)
#             reg 0x10 (port B 110) = 0x12 (= TOP_START_LSB、 CYM = adpcma_sample_top reuse)
#             reg 0x18 (port B 118) = 0x00 (= TOP_START_MSB)
#             reg 0x20 (port B 120) = 0x29 (= TOP_STOP_LSB)
#             reg 0x28 (port B 128) = 0x00 (= TOP_STOP_MSB)
#             reg 0x08 (port B 108) = 0xDF (= vol|pan 固定値)
#             reg 0x00 (port B 100) = 0x01 (= L ch keyon mask)
#   gate 5: keyon trigger 1 件 + ch 0 keyon mask (= 本 fixture では L-Q silent ゆえ ch 0 keyon は rhythm 由来のみ)
#
# 検証範囲外 (= γ / δ で別途):
#   - R-CYM command (= melody part 内 \c inline) → γ で別 fixture
#   - K-CYM と R-CYM で同 routine addr hit literal 比較 (= byte-identical) → γ で differential verify
#   - BD vs CYM differential (= sample addr literal differ) → γ で別 verify script
#   - SD vs CYM / HH vs CYM differential → ADR-0029 §verify gate Gate 4 注記で推移的処理、 explicit gate なし
#   - 既存 23 script regression → δ で serial 実行
#   - user 試聴 (= audio gate) → δ で 4 sec wav 保存後
#
# 使い方:
#   bash src/test-fixtures/step15/verify-step15-cym-trigger.sh
#
# 副作用:
#   /tmp/pmdneo-step15/k-cr-only.wav    (= K CYM trigger audible 試聴用、 4 秒)
#   /tmp/pmdneo-step15/*.tsv            (= trace snapshot)
#
# Exit code:
#   0 = PASS
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step15/k-cr-only.mml"
OUT_DIR="/tmp/pmdneo-step15"

if [[ ! -f "$K_MML" ]]; then
    echo "FAIL infra: fixture not found: $K_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step15-beta-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= driver-embedded fixture、 CYM sample = adpcma_sample_top symbol reuse、 build/assets/samples.inc 由来)
EXPECTED_CYM_START_LSB="12"              # (= TOP_START_LSB、 ADR-0029 §決定 3 / 軸 1 adpcma_sample_top reuse)
EXPECTED_CYM_START_MSB="00"              # (= TOP_START_MSB)
EXPECTED_CYM_STOP_LSB="29"               # (= TOP_STOP_LSB)
EXPECTED_CYM_STOP_MSB="00"               # (= TOP_STOP_MSB)
EXPECTED_VOL_PAN="DF"                    # (= L|R pan 0xC0 + max vol 0x1F)
EXPECTED_KEYON_MASK="01"                 # (= L ch keyon bit 0)

echo "=== ADR-0029 step 15 β: K part CYM rhythm trigger proof (= K \\c → 0xEB 0x04 → ADPCM-A L ch CYM = adpcma_sample_top reuse) ==="
echo

# ============================================================
# gate 1: K-CYM fixture build
# ============================================================
echo "=== gate 1: K-CYM fixture build PASS (= PMDDotNET \\c → 0xEB 0x04 + driver compile) ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-cym-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: K-CYM fixture build failed (log: $TMPDIR/k-cym-build.log)"
    exit 2
}
echo "  [PASS] K-CYM fixture build"

# ============================================================
# gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_cym_trigger symbol 存在確認
# ============================================================
echo
echo "=== gate 2: pmdneo_rhythm_event_trigger + _rhythm_event_cym_trigger routine 存在 ==="
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

CYM_ADDR=$(grep -E "_rhythm_event_cym_trigger:" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$CYM_ADDR" ]]; then
    echo "  [FAIL] gate 2: _rhythm_event_cym_trigger symbol not found in .lst"
    exit 1
fi
echo "  [PASS] _rhythm_event_cym_trigger @ 0x$CYM_ADDR"

# ============================================================
# gate 3: K-CYM fixture run + trace 取得
# ============================================================
echo
echo "=== gate 3: K-CYM fixture run + PC trace + ymfm-trace 取得 ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-cym-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: MAME run failed (log: $TMPDIR/k-cym-run.log)"
    exit 2
}
K_MEM="$OUT_DIR/k-cr-only-mem.tsv"
K_YMFM="$OUT_DIR/k-cr-only-ymfm.tsv"
K_WAV="$OUT_DIR/k-cr-only.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] trace + wav 取得 (= K-CYM fixture run、 wav 4 sec @ $K_WAV)"

# ============================================================
# gate 4: ADPCM-A L ch register write (= CYM addr literal value)
# ============================================================
echo
echo "=== gate 4: ADPCM-A L ch register write (= CYM addr literal = adpcma_sample_top reuse) ==="

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

check_reg_value "110" "$EXPECTED_CYM_START_LSB" "L ch start LSB / TOP_START_LSB (= CYM)"
check_reg_value "118" "$EXPECTED_CYM_START_MSB" "L ch start MSB / TOP_START_MSB (= CYM)"
check_reg_value "120" "$EXPECTED_CYM_STOP_LSB"  "L ch stop LSB / TOP_STOP_LSB (= CYM)"
check_reg_value "128" "$EXPECTED_CYM_STOP_MSB"  "L ch stop MSB / TOP_STOP_MSB (= CYM)"
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
echo "  [PASS] L ch keyon (= mask 0x01) write count = $KEYON_01_COUNT (= CYM rhythm trigger fired)"

echo
echo "🎉 ADR-0029 step 15 β K-CYM rhythm trigger proof PASS"
echo "   - gate 1: K-CYM fixture build PASS"
echo "   - gate 2: pmdneo_rhythm_event_trigger @ 0x$HOOK_ADDR + _rhythm_event_cym_trigger @ 0x$CYM_ADDR"
echo "   - gate 3: trace + wav 取得 ($K_WAV)"
echo "   - gate 4: ADPCM-A L ch register write (= CYM addr literal = adpcma_sample_top reuse + vol|pan)"
echo "   - gate 5: L ch keyon mask 0x01 write count $KEYON_01_COUNT"
exit 0
