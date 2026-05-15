#!/usr/bin/env bash
#
# ADR-0032 step 18 γ: K-0x03 vs R-0x03 (= BD+TOM multi-bit) byte-identical proof (= K と R が同 multi-bit dispatch path を経由 = latent semantics 証明下で K=R 成立)
#
# 目的:
#   ADR-0032 §決定 4/6/8 「dispatch path は drum 種拡張で増やさない」 + 「dispatch path は simultaneous trigger でも増やさない」
#   = 第 2 invariant の literal 証明。
#   K-0x03 fixture (= k11.mml) と R-0x03 fixture (= r-melody-11.mml) を両方 build + run して、
#   ADPCM-A L ch multi-bit register write sequence (= BD reg writes → TOM reg writes、 last-write-dominant TOM)
#   が **byte-identical** であることを literal 比較で証明する。 これにより:
#
#   - K part 0xEB 0x03 path (= rhythm_main → rhythm_main_rhykey → pmdneo_rhythm_event_trigger →
#     bit 0 BD trigger + bit 1 TOM trigger 順次)
#   - R command 0xEB 0x03 path (= pmdneo_part_main_parse → commandsp → commandsp_rhykey →
#     pmdneo_rhythm_event_trigger → bit 0 BD trigger + bit 1 TOM trigger 順次)
#
#   の 2 つの source layer path が runtime layer で **同一 routine** に collapse され、
#   かつ multi-bit 状況下でも同一 register write sequence を発行することを literal で固定する
#   (= ADR-0026 §決定 6 + ADR-0027-0031 §決定 8 + ADR-0032 §決定 4 第 2 invariant 整合)。
#
#   fixture naming = bitmap-centric hex pattern (= k11.mml / r-melody-11.mml = bitmap 0x03、
#   drum-centric semantics naming Step 12-17 からの転換点 = sprint chain 軸転換 milestone)。
#
#   PMDDotNET 側 emit path = mc.cs rs00() OR 蓄積 (= 連続 \b\t → 単一 0xEB 0x03 bytecode に collapse)。
#
#   Step 12 K-BD vs R-BD differential + Step 13 K-SD vs R-SD differential + Step 14-17 各 drum 差分 +
#   Step 18 multi-bit K-0x03 vs R-0x03 differential = K-R dispatch path 1 本化が **multi-bit 状況下でも literal 維持**。
#
# 検証: 7 段 gate
#   gate 1: K-0x03 fixture build + run + trace
#   gate 2: R-0x03 fixture build + run + trace
#   gate 3: pmdneo_rhythm_event_trigger symbol 存在 (= 同 addr が両 build で出力) +
#           _rhythm_event_bd_trigger / _rhythm_event_tom_trigger 同 addr (= multi-bit dispatch sub-routine 共通)
#   gate 4: K-0x03 fixture run last-write-dominant TOM literal (= last-write tail = TOM)
#   gate 5: R-0x03 fixture run last-write-dominant TOM literal (= K-0x03 と同 last-write)
#   gate 6: K-0x03 と R-0x03 の L ch register write sequence byte-identical (= **multi-bit differential proof**)
#   gate 7: K-0x03 と R-0x03 で L ch keyon mask 0x01 trigger count identical (= 2 件以上、 BD + TOM multi-bit dispatch)
#
# 検証範囲外 (= δ で別途):
#   - representative pair 4 件 KR byte-identical (= verify-step18-kr-05/09/11/21-byte-identical.sh、 γ 同 commit)
#   - 0x3F full-boundary (= verify-step18-k3f-trigger.sh / r3f-trigger.sh / kr-3f-byte-identical.sh、 δ)
#   - 既存 全 script regression (= δ で serial 実行)
#   - user 試聴 audio gate (= δ で listen-step18.sh + 12 wav)
#   - ADR-0032 Accepted 移行 (= δ)
#
# 使い方:
#   bash src/test-fixtures/step18/verify-step18-kr-11-byte-identical.sh
#
# 副作用:
#   /tmp/pmdneo-step18/k11.wav              (= K-0x11 multi-bit audible 試聴用、 4 秒、 TOM 支配)
#   /tmp/pmdneo-step18/r-melody-11.wav      (= R-0x11 multi-bit audible 試聴用、 4 秒、 TOM 支配)
#   /tmp/pmdneo-step18/k11-*.tsv            (= K-0x03 trace snapshot)
#   /tmp/pmdneo-step18/r-melody-11-*.tsv    (= R-0x03 trace snapshot)
#
# Exit code:
#   0 = PASS (= 全 7 gate 通過)
#   1 = verify fail
#   2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

K_MML="$PROJECT_ROOT/src/test-fixtures/step18/k11.mml"
R_MML="$PROJECT_ROOT/src/test-fixtures/step18/r-melody-11.mml"
OUT_DIR="/tmp/pmdneo-step18"

if [[ ! -f "$K_MML" ]]; then echo "FAIL infra: $K_MML not found"; exit 2; fi
if [[ ! -f "$R_MML" ]]; then echo "FAIL infra: $R_MML not found"; exit 2; fi

mkdir -p "$OUT_DIR"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step18-gamma-kr-11-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

## Literal expected values (= ADR-0032 §決定 7 BD-anchor pair、 last-write-dominant = TOM)
## last-write tail = TOM literal (= bitmap 0x03 末尾 drum、 bit 1 = adpcma_sample_sd reuse)
EXPECTED_LAST_START_LSB="0c"             # (= SD_START_LSB)
EXPECTED_LAST_START_MSB="00"             # (= SD_START_MSB)
EXPECTED_LAST_STOP_LSB="11"              # (= SD_STOP_LSB)
EXPECTED_LAST_STOP_MSB="00"              # (= SD_STOP_MSB)
EXPECTED_VOL_PAN="DF"
EXPECTED_KEYON_MASK="01"
EXPECTED_KEYON_COUNT_MIN=2               # (= BD + TOM 順次 multi-bit dispatch)
LAST_DRUM_LABEL="TOM"
BITMAP_HEX="11"

echo "=== ADR-0032 step 18 γ: K-0x${BITMAP_HEX} vs R-0x${BITMAP_HEX} (= BD+${LAST_DRUM_LABEL} multi-bit) byte-identical proof (= K と R が同 multi-bit dispatch path を経由 = latent semantics 証明下で K=R 成立) ==="
echo

# ============================================================
# gate 1: K-0xNN fixture build + run + trace
# ============================================================
echo "=== gate 1: K-0x${BITMAP_HEX} fixture (= k${BITMAP_HEX}.mml) build + run + trace ==="
PMDDOTNET_MML="$K_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/k-build.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-0x${BITMAP_HEX} build failed (log: $TMPDIR/k-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/k-run.log" 2>&1 || {
    echo "  [FAIL] gate 1: K-0x${BITMAP_HEX} MAME run failed"
    exit 2
}
K_YMFM="$OUT_DIR/k${BITMAP_HEX}-ymfm.tsv"
K_MEM="$OUT_DIR/k${BITMAP_HEX}-mem.tsv"
K_WAV="$OUT_DIR/k${BITMAP_HEX}.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$K_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$K_MEM"
cp /tmp/pmdneo-trace/audio.wav "$K_WAV"
echo "  [PASS] K-0x${BITMAP_HEX} fixture build + run + trace 取得 (wav: ${K_WAV})"

# .lst snapshot
K_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [[ ! -f "$K_LST" ]]; then echo "  [FAIL] gate 1: .lst not found"; exit 2; fi
K_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$K_LST" | head -1 | awk '{print $1}')
if [[ -z "$K_HOOK_ADDR" ]]; then echo "  [FAIL] gate 1: hook symbol not found in K build .lst"; exit 1; fi
echo "  [INFO] K-0x${BITMAP_HEX} build: pmdneo_rhythm_event_trigger @ 0x${K_HOOK_ADDR}"
K_BD_ADDR=$(grep -E "_rhythm_event_bd_trigger:" "$K_LST" | head -1 | awk '{print $1}')
K_TOM_ADDR=$(grep -E "_rhythm_event_tom_trigger:" "$K_LST" | head -1 | awk '{print $1}')
echo "  [INFO] K-0x${BITMAP_HEX} build: _rhythm_event_bd_trigger @ 0x${K_BD_ADDR}"
echo "  [INFO] K-0x${BITMAP_HEX} build: _rhythm_event_tom_trigger @ 0x${K_TOM_ADDR}"

# ============================================================
# gate 2: R-0xNN fixture build + run + trace
# ============================================================
echo
echo "=== gate 2: R-0x${BITMAP_HEX} fixture (= r-melody-${BITMAP_HEX}.mml) build + run + trace ==="
PMDDOTNET_MML="$R_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/r-build.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-0x${BITMAP_HEX} build failed (log: $TMPDIR/r-build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/r-run.log" 2>&1 || {
    echo "  [FAIL] gate 2: R-0x${BITMAP_HEX} MAME run failed"
    exit 2
}
R_YMFM="$OUT_DIR/r-melody-${BITMAP_HEX}-ymfm.tsv"
R_MEM="$OUT_DIR/r-melody-${BITMAP_HEX}-mem.tsv"
R_WAV="$OUT_DIR/r-melody-${BITMAP_HEX}.wav"
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$R_YMFM"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$R_MEM"
cp /tmp/pmdneo-trace/audio.wav "$R_WAV"
echo "  [PASS] R-0x${BITMAP_HEX} fixture build + run + trace 取得 (wav: ${R_WAV})"

R_LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
R_HOOK_ADDR=$(grep -E "pmdneo_rhythm_event_trigger::" "$R_LST" | head -1 | awk '{print $1}')
if [[ -z "$R_HOOK_ADDR" ]]; then echo "  [FAIL] gate 2: hook symbol not found in R build .lst"; exit 1; fi
echo "  [INFO] R-0x${BITMAP_HEX} build: pmdneo_rhythm_event_trigger @ 0x${R_HOOK_ADDR}"
R_BD_ADDR=$(grep -E "_rhythm_event_bd_trigger:" "$R_LST" | head -1 | awk '{print $1}')
R_TOM_ADDR=$(grep -E "_rhythm_event_tom_trigger:" "$R_LST" | head -1 | awk '{print $1}')
echo "  [INFO] R-0x${BITMAP_HEX} build: _rhythm_event_bd_trigger @ 0x${R_BD_ADDR}"
echo "  [INFO] R-0x${BITMAP_HEX} build: _rhythm_event_tom_trigger @ 0x${R_TOM_ADDR}"

# ============================================================
# gate 3: same hook + sub-routine addr in both K and R builds
# ============================================================
echo
echo "=== gate 3: pmdneo_rhythm_event_trigger + drum sub-routine addr identical between K and R builds ==="
if [[ "$K_HOOK_ADDR" != "$R_HOOK_ADDR" ]]; then
    echo "  [FAIL] gate 3: hook addr differs (K=0x${K_HOOK_ADDR} vs R=0x${R_HOOK_ADDR})"
    exit 1
fi
echo "  [PASS] hook addr identical = 0x${K_HOOK_ADDR} (= K と R で same routine entry、 multi-bit でも不変 = 第 2 invariant)"
if [[ "$K_BD_ADDR" != "$R_BD_ADDR" ]]; then
    echo "  [FAIL] gate 3: BD trigger addr differs (K=0x${K_BD_ADDR} vs R=0x${R_BD_ADDR})"
    exit 1
fi
echo "  [PASS] _rhythm_event_bd_trigger addr identical = 0x${K_BD_ADDR}"
if [[ "$K_TOM_ADDR" != "$R_TOM_ADDR" ]]; then
    echo "  [FAIL] gate 3: TOM trigger addr differs (K=0x${K_TOM_ADDR} vs R=0x${R_TOM_ADDR})"
    exit 1
fi
echo "  [PASS] _rhythm_event_tom_trigger addr identical = 0x${K_TOM_ADDR}"

# ============================================================
# gate 4: K-0xNN fixture last-write-dominant tail literal
# ============================================================
echo
echo "=== gate 4: K-0x${BITMAP_HEX} fixture run ADPCM-A L ch last-write tail = ${LAST_DRUM_LABEL} literal ==="

check_reg_tail() {
    local trace="$1"
    local reg="$2"
    local expected="$3"
    local label="$4"
    local found
    found=$(awk -F'\t' -v reg="$reg" '$2 == "B" && $3 == reg {print toupper($4)}' "$trace" | tail -1)
    if [[ -z "$found" ]]; then
        echo "  [FAIL] reg $reg ($label) write not found in $trace"
        exit 1
    fi
    local found_norm=$(printf "%02X" "0x$found")
    local expected_norm=$(printf "%02X" "0x$expected")
    if [[ "$found_norm" != "$expected_norm" ]]; then
        echo "  [FAIL] reg $reg ($label) tail = 0x$found_norm (expected 0x$expected_norm)"
        exit 1
    fi
    echo "  [PASS] reg $reg ($label) tail = 0x$found_norm"
}

check_reg_tail "$K_YMFM" "110" "$EXPECTED_LAST_START_LSB" "K-0x${BITMAP_HEX} L ch start LSB / ${LAST_DRUM_LABEL}_START_LSB"
check_reg_tail "$K_YMFM" "118" "$EXPECTED_LAST_START_MSB" "K-0x${BITMAP_HEX} L ch start MSB / ${LAST_DRUM_LABEL}_START_MSB"
check_reg_tail "$K_YMFM" "120" "$EXPECTED_LAST_STOP_LSB"  "K-0x${BITMAP_HEX} L ch stop LSB / ${LAST_DRUM_LABEL}_STOP_LSB"
check_reg_tail "$K_YMFM" "128" "$EXPECTED_LAST_STOP_MSB"  "K-0x${BITMAP_HEX} L ch stop MSB / ${LAST_DRUM_LABEL}_STOP_MSB"
check_reg_tail "$K_YMFM" "108" "$EXPECTED_VOL_PAN"        "K-0x${BITMAP_HEX} L ch vol|pan"

# ============================================================
# gate 5: R-0xNN fixture last-write-dominant tail literal (= K と同)
# ============================================================
echo
echo "=== gate 5: R-0x${BITMAP_HEX} fixture run ADPCM-A L ch last-write tail = ${LAST_DRUM_LABEL} literal (= K と同) ==="
check_reg_tail "$R_YMFM" "110" "$EXPECTED_LAST_START_LSB" "R-0x${BITMAP_HEX} L ch start LSB / ${LAST_DRUM_LABEL}_START_LSB"
check_reg_tail "$R_YMFM" "118" "$EXPECTED_LAST_START_MSB" "R-0x${BITMAP_HEX} L ch start MSB / ${LAST_DRUM_LABEL}_START_MSB"
check_reg_tail "$R_YMFM" "120" "$EXPECTED_LAST_STOP_LSB"  "R-0x${BITMAP_HEX} L ch stop LSB / ${LAST_DRUM_LABEL}_STOP_LSB"
check_reg_tail "$R_YMFM" "128" "$EXPECTED_LAST_STOP_MSB"  "R-0x${BITMAP_HEX} L ch stop MSB / ${LAST_DRUM_LABEL}_STOP_MSB"
check_reg_tail "$R_YMFM" "108" "$EXPECTED_VOL_PAN"        "R-0x${BITMAP_HEX} L ch vol|pan"

# ============================================================
# gate 6: K-0xNN と R-0xNN の L ch register write sequence byte-identical (= multi-bit differential proof)
# ============================================================
echo
echo "=== gate 6: K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} の L ch register write sequence byte-identical (= K-R multi-bit dispatch differential proof) ==="

# Extract L ch register writes (= reg 0x10/0x18/0x20/0x28/0x08 + keyon mask 0x01 on reg 0x00)
extract_lch_writes() {
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

K_SEQ=$(extract_lch_writes "$K_YMFM")
R_SEQ=$(extract_lch_writes "$R_YMFM")

if [[ "$K_SEQ" != "$R_SEQ" ]]; then
    echo "  [FAIL] gate 6: K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} で L ch register write sequence が異なる"
    echo "         K-0x${BITMAP_HEX} seq:"
    echo "$K_SEQ" | sed 's/^/           /'
    echo "         R-0x${BITMAP_HEX} seq:"
    echo "$R_SEQ" | sed 's/^/           /'
    exit 1
fi
K_SEQ_LINES=$(echo "$K_SEQ" | wc -l | tr -d ' ')
echo "  [PASS] K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} の L ch register write sequence byte-identical (${K_SEQ_LINES} 件)"
echo "         (= K part 0xEB ${BITMAP_HEX} path と R command 0xEB ${BITMAP_HEX} path が同 pmdneo_rhythm_event_trigger を経由)"
echo "         (= multi-bit dispatch も K-R で literal 同一 = 第 2 invariant 「dispatch path は simultaneous trigger でも増やさない」 literal 維持)"
echo "         (= ADR-0032 §決定 4/6 整合)"

# ============================================================
# gate 7: K-0xNN と R-0xNN で L ch keyon mask 0x01 trigger count identical (= multi-bit = 2 件以上)
# ============================================================
echo
echo "=== gate 7: K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} で L ch keyon mask 0x01 trigger count identical (= multi-bit = ${EXPECTED_KEYON_COUNT_MIN} 件以上) ==="
K_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$K_YMFM" | grep -c "^01$" || true)
R_KEYON_01_COUNT=$(awk -F'\t' '$2 == "B" && $3 == "100" {print toupper($4)}' "$R_YMFM" | grep -c "^01$" || true)
if [[ "$K_KEYON_01_COUNT" != "$R_KEYON_01_COUNT" ]]; then
    echo "  [FAIL] gate 7: keyon count differs (K-0x${BITMAP_HEX}=${K_KEYON_01_COUNT}, R-0x${BITMAP_HEX}=${R_KEYON_01_COUNT})"
    exit 1
fi
if [[ "$K_KEYON_01_COUNT" -lt "$EXPECTED_KEYON_COUNT_MIN" ]]; then
    echo "  [FAIL] gate 7: K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} 共に keyon trigger ${K_KEYON_01_COUNT} 件 (expected >= ${EXPECTED_KEYON_COUNT_MIN}、 multi-bit dispatch 動作未確認)"
    exit 1
fi
echo "  [PASS] K-0x${BITMAP_HEX} と R-0x${BITMAP_HEX} で L ch keyon mask 0x01 trigger count = ${K_KEYON_01_COUNT} 件 (= 同回数発火、 multi-bit dispatch 動作)"

echo
echo "🎉 ADR-0032 step 18 γ K-0x${BITMAP_HEX} vs R-0x${BITMAP_HEX} (= BD+${LAST_DRUM_LABEL} multi-bit) byte-identical proof PASS (= latent semantics 証明下で K=R 成立)"
echo "   - gate 1: K-0x${BITMAP_HEX} fixture build + run + trace (${K_WAV})"
echo "   - gate 2: R-0x${BITMAP_HEX} fixture build + run + trace (${R_WAV})"
echo "   - gate 3: pmdneo_rhythm_event_trigger addr identical (K=R=0x${K_HOOK_ADDR}) + drum sub-routine addr identical"
echo "   - gate 4: K-0x${BITMAP_HEX} last-write tail = ${LAST_DRUM_LABEL} literal PASS"
echo "   - gate 5: R-0x${BITMAP_HEX} last-write tail = ${LAST_DRUM_LABEL} literal PASS"
echo "   - gate 6: K-0x${BITMAP_HEX}/R-0x${BITMAP_HEX} L ch register write sequence byte-identical (${K_SEQ_LINES} 件)"
echo "   - gate 7: K-0x${BITMAP_HEX}/R-0x${BITMAP_HEX} L ch keyon mask 0x01 trigger count identical (${K_KEYON_01_COUNT} 件)"
echo ""
echo "   ADR-0032 §決定 4 第 2 invariant 「dispatch path は simultaneous trigger でも増やさない」 literal 確立"
echo "   (= multi-bit bitmap 0x${BITMAP_HEX} 下でも K-R dispatch path 1 本化が維持、 driver Z80 source 完全不変、 latent semantics 証明 paradigm)"
exit 0
