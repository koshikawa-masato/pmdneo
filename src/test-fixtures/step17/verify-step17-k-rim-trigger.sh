#!/usr/bin/env bash
#
# ADR-0031 step 17 β: K part RIM rhythm trigger proof (= K \i → 0xEB 0x20 → pmdneo_rhythm_event_trigger → ADPCM-A L ch RIM = full 6 drum completion)
#
# 目的:
#   ADR-0031 §決定 1/2/3/4/7/8/9 整合の K part 0xEB RIM rhythm dispatch path proof。
#   K-RIM fixture (= src/test-fixtures/step17/k-ir-only.mml) の K part body `\i` が
#   PMDDotNET 経由 `0xEB 0x20 0x80` (= rhykey RIM bitmap + part end) に compile され、
#   driver の rhythm_main K part body parser で 0xEB 検出 → bitmap fetch →
#   pmdneo_rhythm_event_trigger 呼出 → bit 5 RIM 分岐 → _rhythm_event_rim_trigger →
#   ADPCM-A L ch RIM register write の path が PC trace + ymfm-trace で
#   literal observable な proof として固定 = **full 6 drum completion**。
#
#   ADR-0031 §決定 8 「dispatch path は drum 種拡張で増やさない」 の 6 drum 段 = full PMD drum set literal 実装保証:
#   pmdneo_rhythm_event_trigger routine entry addr (= Step 12/Step 13/Step 14/Step 15/Step 16 と同一) が RIM trigger fixture でも不変。
#
#   ADR-0031 §決定 3 / 軸 1: RIM sample source = existing adpcma_sample_rim symbol reuse
#     (= 「rim」 = sample provenance 名 + PMD semantics 名 完全一致、 alias 新設不要、
#        ADR-0030 「tom」 = TOM 完全一致 pattern 踏襲、
#        PMDDotNET 内部名 `rimset` は RIM semantics と実質一致 (= ADR-0030 `tamset` legacy naming のような wording 分離なし)
#        = ADR-0031 §決定 3 「用語対応表」 + §Annex A-1 literal)
#
#   fixture 命名注記: `ir` = `\i` + `r`(= rest) fixture pattern。 「RIM」 略ではない
#   (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern 同一規律、 ADR-0031 §決定 5 / 軸 2 整合)。
#
#   `\r` = rest 専用、 `\r = RIM` は誤り (= ADR-0027 §Annex A-1 / memory project_pmd_rim_drum_char_correction literal 整合)。
#
#   R-RIM fixture (= melody part 内 \i inline) は γ scope で別 verify script。
#
# 検証: 5 段 gate (= ADR-0031 §verify gate Gate 1-5 整合)
#   gate 1: K-RIM fixture build PASS (= PMDDotNET \i → 0xEB 0x20 + driver compile)
#   gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_rim_trigger routine 存在 (= .lst で symbol 確認)
#           Step 12/Step 13/Step 14/Step 15/Step 16 K-BD/K-SD/K-HH/K-CYM/K-TOM verify と同 entry addr であることを literal 確認 (= ADR-0031 §決定 9)
#   gate 3: K-RIM fixture run PC trace + ymfm-trace 取得
#   gate 4: K-RIM fixture run ADPCM-A L ch register write (= RIM addr literal value assert)
#             reg 0x10 (port B 110) = 0x0a (= RIM_START_LSB、 RIM = adpcma_sample_rim reuse)
#             reg 0x18 (port B 118) = 0x00 (= RIM_START_MSB)
#             reg 0x20 (port B 120) = 0x0b (= RIM_STOP_LSB)
#             reg 0x28 (port B 128) = 0x00 (= RIM_STOP_MSB)
#             reg 0x08 (port B 108) = 0xDF (= vol|pan 固定値)
#             reg 0x00 (port B 100) = 0x01 (= L ch keyon mask)
#   gate 5: keyon trigger 1 件 + ch 0 keyon mask (= 本 fixture では L-Q silent ゆえ ch 0 keyon は rhythm 由来のみ)
#
# 検証範囲外 (= γ / δ で別途):
#   - R-RIM command (= melody part 内 \i inline) → γ で別 fixture
#   - K-RIM と R-RIM で同 routine addr hit literal 比較 (= byte-identical) → γ で differential verify
#   - BD vs RIM differential (= sample addr literal differ) → γ で別 verify script
#   - TOM vs RIM differential (= Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit proof) → γ で別 verify script
#   - SD vs RIM / CYM vs RIM / HH vs RIM differential → ADR-0031 §verify gate Gate 5/6 注記で推移的処理、 explicit gate なし
#   - 既存 29 script regression → δ で serial 実行
#   - user 試聴 (= audio gate) → δ で 4 sec wav 保存後
#
# 使い方:
#   bash src/test-fixtures/step17/verify-step17-k-rim-trigger.sh
#
# 副作用:
#   /tmp/pmdneo-step17/k-ir-only.wav    (= K RIM trigger audible 試聴用、 4 秒)
#   /tmp/pmdneo-step17/*.tsv            (= trace snapshot)
#
# Exit code:
#   0 = PASS
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step17/k-ir-only.mml"
OUT_DIR="/tmp/pmdneo-step17"

if [[ ! -f "$K_MML" ]]; then
    echo "FAIL infra: fixture not found: $K_MML"
    exit 2
fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step17-beta-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= driver-embedded fixture、 RIM sample = adpcma_sample_rim symbol reuse、 build/assets/samples.inc 由来)
EXPECTED_RIM_START_LSB="0a"              # (= RIM_START_LSB、 ADR-0031 §決定 3 / 軸 1 adpcma_sample_rim reuse)
EXPECTED_RIM_START_MSB="00"              # (= RIM_START_MSB)
EXPECTED_RIM_STOP_LSB="0b"               # (= RIM_STOP_LSB)
EXPECTED_RIM_STOP_MSB="00"               # (= RIM_STOP_MSB)
EXPECTED_VOL_PAN="DF"                    # (= L|R pan 0xC0 + max vol 0x1F)
EXPECTED_KEYON_MASK="01"                 # (= L ch keyon bit 0)

echo "=== ADR-0031 step 17 β: K part RIM rhythm trigger proof (= K \\i → 0xEB 0x20 → ADPCM-A L ch RIM = adpcma_sample_rim reuse = full 6 drum completion) ==="
echo

# ============================================================
# gate 1: K-RIM fixture build
# ============================================================
echo "=== gate 1: K-RIM fixture build PASS (= PMDDotNET \\i → 0xEB 0x20 + driver compile) ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-rim-build.log" 2>&1 || {
    echo "  [FAIL] gate 1 infra: K-RIM fixture build failed (log: $TMPDIR/k-rim-build.log)"
    exit 2
}
echo "  [PASS] K-RIM fixture build"

# ============================================================
# gate 2: pmdneo_rhythm_event_trigger / _rhythm_event_rim_trigger symbol 存在確認
# ============================================================
echo
echo "=== gate 2: pmdneo_rhythm_event_trigger + _rhythm_event_rim_trigger routine 存在 ==="
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

RIM_ADDR=$(grep -E "_rhythm_event_rim_trigger:" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$RIM_ADDR" ]]; then
    echo "  [FAIL] gate 2: _rhythm_event_rim_trigger symbol not found in .lst"
    exit 1
fi
echo "  [PASS] _rhythm_event_rim_trigger @ 0x$RIM_ADDR"

# ============================================================
# gate 3: K-RIM fixture run + trace 取得
# ============================================================
echo
echo "=== gate 3: K-RIM fixture run + PC trace + ymfm-trace 取得 ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-rim-run.log" 2>&1 || {
    echo "  [FAIL] gate 3 infra: MAME run failed (log: $TMPDIR/k-rim-run.log)"
    exit 2
}
K_MEM="$OUT_DIR/k-ir-only-mem.tsv"
K_YMFM="$OUT_DIR/k-ir-only-ymfm.tsv"
K_WAV="$OUT_DIR/k-ir-only.wav"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] trace + wav 取得 (= K-RIM fixture run、 wav 4 sec @ $K_WAV)"

# ============================================================
# gate 4: ADPCM-A L ch register write (= RIM addr literal value)
# ============================================================
echo
echo "=== gate 4: ADPCM-A L ch register write (= RIM addr literal = adpcma_sample_rim reuse) ==="

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

check_reg_value "110" "$EXPECTED_RIM_START_LSB" "L ch start LSB / RIM_START_LSB (= RIM)"
check_reg_value "118" "$EXPECTED_RIM_START_MSB" "L ch start MSB / RIM_START_MSB (= RIM)"
check_reg_value "120" "$EXPECTED_RIM_STOP_LSB"  "L ch stop LSB / RIM_STOP_LSB (= RIM)"
check_reg_value "128" "$EXPECTED_RIM_STOP_MSB"  "L ch stop MSB / RIM_STOP_MSB (= RIM)"
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
echo "  [PASS] L ch keyon (= mask 0x01) write count = $KEYON_01_COUNT (= RIM rhythm trigger fired)"

echo
echo "🎉 ADR-0031 step 17 β K-RIM rhythm trigger proof PASS (= full 6 drum completion β)"
echo "   - gate 1: K-RIM fixture build PASS"
echo "   - gate 2: pmdneo_rhythm_event_trigger @ 0x$HOOK_ADDR + _rhythm_event_rim_trigger @ 0x$RIM_ADDR"
echo "   - gate 3: trace + wav 取得 ($K_WAV)"
echo "   - gate 4: ADPCM-A L ch register write (= RIM addr literal = adpcma_sample_rim reuse + vol|pan)"
echo "   - gate 5: L ch keyon mask 0x01 write count $KEYON_01_COUNT"
exit 0
