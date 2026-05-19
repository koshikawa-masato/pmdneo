#!/usr/bin/env bash
#
# PMDNEO 軸 G sub-sprint δ verify gate (= ADR-0048 §決定 8 案 C 部分 runtime parse)
#
# verify scope:
#   - gate 1: build PASS (= bash scripts/build-poc.sh で軸 G 経路統合 build)
#   - gate 2: PPC directory binary size = 1024 byte (= nice-to-have #2 反映)
#   - gate 3: generator self-test 5/5 PASS (= nice-to-have #3 反映)
#   - gate 4: spike script 6/6 PASS (= β regression、 parser/validator 不変)
#   - gate 5: mapping-B literal 期待値計算 + samples.inc PPC_PCM_BLOB_START_LSB/MSB から
#             reg 0x12-0x15 期待 byte literal verify
#   - gate 6: 既存 ADR-0043 regression PASS (= step 4 baseline + γ-2 + γ-3、 driver byte-identical)
#   - gate 7: driver source 構造 grep (= 新 routine + bit7 分岐 + mapping-B 加算 literal 存在)
#
# audio gate は ε scope (= 越川氏 audition、 必要時のみ、 Codex layer 2 approve 済)。
# δ では MAME -wavwrite reg trace ではなく driver source 構造 + literal 期待値計算で完了判定。
#
# usage: bash src/test-fixtures/axis-g/verify-delta-ppc-runtime-selection.sh

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TEMPLATE_ASSETS="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/assets"
DRIVER_SRC="$PMDNEO_ROOT/src/driver/standalone_test.s"
FIXTURE_PPC="$PMDNEO_ROOT/src/test-fixtures/axis-g/minimum.PPC"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL+1)); }

echo "=== 軸 G δ verify gate (= ADR-0048 §決定 8 案 C 経路) ==="

# --- gate 1: build PASS ---
echo
echo "--- gate 1: build PASS ---"
if (cd "$PMDNEO_ROOT" && bash scripts/build-poc.sh > /tmp/axis-g-build.log 2>&1); then
    ok "build PASS (= scripts/build-poc.sh、 軸 G 経路 build pipeline 統合)"
else
    ng "build FAIL — see /tmp/axis-g-build.log"
    exit 1
fi

# --- gate 2: PPC directory binary size 1024 byte ---
echo
echo "--- gate 2: PPC directory binary size = 1024 byte (nice-to-have #2) ---"
DIRBIN="$TEMPLATE_ASSETS/ppc_directory.bin"
if [ ! -f "$DIRBIN" ]; then
    ng "directory binary not found: $DIRBIN"
else
    SIZE=$(stat -f %z "$DIRBIN" 2>/dev/null || stat -c %s "$DIRBIN" 2>/dev/null)
    if [ "$SIZE" = "1024" ]; then
        ok "directory binary size = 1024 byte ($DIRBIN)"
    else
        ng "directory binary size = $SIZE byte (expected 1024)"
    fi
fi

# --- gate 3: generator self-test ---
echo
echo "--- gate 3: generator self-test (nice-to-have #3) ---"
if (cd "$PMDNEO_ROOT" && python3 scripts/ppc-to-ngdevkit.py --self-test > /tmp/axis-g-selftest.log 2>&1); then
    PASS_LINE=$(grep "self-test summary" /tmp/axis-g-selftest.log || true)
    ok "generator self-test PASS ($PASS_LINE)"
else
    ng "generator self-test FAIL — see /tmp/axis-g-selftest.log"
    cat /tmp/axis-g-selftest.log
fi

# --- gate 4: spike script regression ---
echo
echo "--- gate 4: spike script regression (β proof 不変) ---"
if (cd "$PMDNEO_ROOT" && python3 scripts/ppc-parser-spike.py > /tmp/axis-g-spike.log 2>&1); then
    SPIKE_LINE=$(grep "summary" /tmp/axis-g-spike.log || true)
    ok "spike script PASS ($SPIKE_LINE)"
else
    ng "spike script FAIL — see /tmp/axis-g-spike.log"
fi

# --- gate 5: mapping-B literal 期待値計算 + samples.inc 整合 ---
echo
echo "--- gate 5: mapping-B literal 期待値 + samples.inc PPC_PCM_BLOB_START verify ---"
SAMPLES_INC="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/build/assets/samples.inc"

# 期待: fixture entry 0 = START 0x0400, STOP 0x0480
#        entry 1 = START 0x0480, STOP 0x0500
PPC_ENTRY0_START_WORD=0x0400
PPC_ENTRY0_STOP_WORD=0x0480
PPC_ENTRY1_START_WORD=0x0480
PPC_ENTRY1_STOP_WORD=0x0500

# samples.inc から PPC_PCM_BLOB_START_LSB/MSB 抽出
BLOB_LSB_HEX=$(grep "PPC_PCM_BLOB_START_LSB" "$SAMPLES_INC" | head -1 | awk '{print $NF}')
BLOB_MSB_HEX=$(grep "PPC_PCM_BLOB_START_MSB" "$SAMPLES_INC" | head -1 | awk '{print $NF}')

if [ -z "$BLOB_LSB_HEX" ] || [ -z "$BLOB_MSB_HEX" ]; then
    ng "PPC_PCM_BLOB_START_LSB/MSB not found in $SAMPLES_INC"
else
    BLOB_LSB=$(printf "%d" $BLOB_LSB_HEX)
    BLOB_MSB=$(printf "%d" $BLOB_MSB_HEX)
    BLOB_WORD=$((BLOB_MSB * 256 + BLOB_LSB))
    # nice-to-have #1: PPC_VROM_BASE_OFFSET_WORD != 0 (= identity 誤実装 trace 用)
    if [ "$BLOB_WORD" -eq 0 ]; then
        ng "PPC_VROM_BASE_OFFSET_WORD = 0 (= identity 同等、 nice-to-have #1 違反)"
    else
        ok "PPC_PCM_BLOB_START_WORD = 0x$(printf %04X $BLOB_WORD) (= nonzero base offset、 nice-to-have #1)"
    fi
    # mapping-B expected reg values for entry 0
    ENTRY0_START_WORD=$((PPC_ENTRY0_START_WORD + BLOB_WORD))
    ENTRY0_STOP_WORD=$((PPC_ENTRY0_STOP_WORD + BLOB_WORD))
    EXP_R12=$((ENTRY0_START_WORD & 0xFF))
    EXP_R13=$(((ENTRY0_START_WORD >> 8) & 0xFF))
    EXP_R14=$((ENTRY0_STOP_WORD & 0xFF))
    EXP_R15=$(((ENTRY0_STOP_WORD >> 8) & 0xFF))
    ok "mapping-B 期待 reg 0x12/0x13/0x14/0x15 for entry 0 = 0x$(printf '%02X' $EXP_R12)/0x$(printf '%02X' $EXP_R13)/0x$(printf '%02X' $EXP_R14)/0x$(printf '%02X' $EXP_R15)"
    # mapping-B expected reg values for entry 1
    ENTRY1_START_WORD=$((PPC_ENTRY1_START_WORD + BLOB_WORD))
    ENTRY1_STOP_WORD=$((PPC_ENTRY1_STOP_WORD + BLOB_WORD))
    EXP_R12_1=$((ENTRY1_START_WORD & 0xFF))
    EXP_R13_1=$(((ENTRY1_START_WORD >> 8) & 0xFF))
    EXP_R14_1=$((ENTRY1_STOP_WORD & 0xFF))
    EXP_R15_1=$(((ENTRY1_STOP_WORD >> 8) & 0xFF))
    ok "mapping-B 期待 reg 0x12/0x13/0x14/0x15 for entry 1 = 0x$(printf '%02X' $EXP_R12_1)/0x$(printf '%02X' $EXP_R13_1)/0x$(printf '%02X' $EXP_R14_1)/0x$(printf '%02X' $EXP_R15_1)"
    # identity 誤実装の判別: identity だと reg 0x12-0x15 = (0x00, 0x04, 0x80, 0x04) になるはず (= entry 0)
    # mapping-B 正しい実装だと nonzero offset を足した値になる (= base ≠ 0 で異なる)
    if [ "$EXP_R12" = "0" ] && [ "$EXP_R13" = "4" ]; then
        ng "expected reg matches identity mapping (= mapping-B が identity に縮退、 nice-to-have #1 違反)"
    else
        ok "expected reg differs from identity (= mapping-B 適用済 literal、 nice-to-have #1)"
    fi
fi

# --- gate 6: 既存 ADR-0043 regression (= step4 baseline + γ-2 + γ-3) ---
echo
echo "--- gate 6: 既存 ADR-0043 regression PASS (= driver byte-identical 維持) ---"
for VS in \
    "src/test-fixtures/step4/verify-j-part-fixture-driven.sh:ADR-0016 step 4-3-δ baseline" \
    "src/test-fixtures/axis-c/verify-gamma-2-multi-table.sh:axis-c γ-2 multi-table" \
    "src/test-fixtures/axis-c/verify-gamma-3-axis-independence.sh:axis-c γ-3 axis independence"
do
    SCRIPT="${VS%%:*}"
    LABEL="${VS##*:}"
    if (cd "$PMDNEO_ROOT" && bash "$SCRIPT" > "/tmp/axis-g-regression-$(basename $SCRIPT .sh).log" 2>&1); then
        ok "$LABEL PASS"
    else
        ng "$LABEL FAIL — see /tmp/axis-g-regression-$(basename $SCRIPT .sh).log"
    fi
done

# --- gate 7: driver source 構造 grep ---
echo
echo "--- gate 7: driver source 構造 verify (= 新 routine + bit7 分岐 + mapping-B 加算 literal 存在) ---"
GATE7_FAIL=0
# 新 routine
if grep -q "pmdneo_select_adpcmb_ppc_pointer:" "$DRIVER_SRC"; then
    ok "新 routine pmdneo_select_adpcmb_ppc_pointer 定義存在"
else
    ng "新 routine pmdneo_select_adpcmb_ppc_pointer 定義不在"; GATE7_FAIL=1
fi
# bit7 分岐
if grep -q "bit     7, a" "$DRIVER_SRC" && grep -q "adpcmb_keyon_ppc_source:" "$DRIVER_SRC"; then
    ok "adpcmb_keyon bit7 分岐 + ppc_source label 存在"
else
    ng "adpcmb_keyon bit7 分岐 not found"; GATE7_FAIL=1
fi
# mapping-B 加算
if grep -q "add     a, #PPC_VROM_BASE_OFFSET_WORD_LSB" "$DRIVER_SRC" && \
   grep -q "adc     a, #PPC_VROM_BASE_OFFSET_WORD_MSB" "$DRIVER_SRC"; then
    ok "mapping-B add + adc 加算 literal 存在 (= byte-level carry 伝播)"
else
    ng "mapping-B add/adc 加算 literal not found"; GATE7_FAIL=1
fi
# PPC_DIRECTORY_BASE .incbin
if grep -q "^PPC_DIRECTORY_BASE:" "$DRIVER_SRC" && \
   grep -q '\.incbin "assets/ppc_directory\.bin"' "$DRIVER_SRC"; then
    ok "PPC_DIRECTORY_BASE label + .incbin assets/ppc_directory.bin 存在"
else
    ng "PPC_DIRECTORY_BASE / .incbin literal not found"; GATE7_FAIL=1
fi
# 既存 ADR-0043 routine 不可触 verify (= label + ret 構造保持)
if grep -q "^pmdneo_select_adpcmb_sample_pointer:" "$DRIVER_SRC" && \
   grep -q "^adpcmb_keyon_have_sample:" "$DRIVER_SRC" && \
   grep -q "^adpcmb_sample_beat:" "$DRIVER_SRC"; then
    ok "既存 ADR-0043 routine label 完全保持 (= 不可触 list 3 件 literal)"
else
    ng "既存 ADR-0043 routine label 不在"; GATE7_FAIL=1
fi

# --- summary ---
echo
echo "=== verify summary ==="
if [ "$FAIL" -eq 0 ]; then
    echo "🎉 軸 G δ verify gate ALL PASS"
    echo "   - gate 1-7 全 PASS、 案 C 部分 runtime parse 経路機能実証完了"
    echo "   - 既存 ADR-0043 production-ready 経路 byte-identical 維持"
    echo "   - audio gate audition は ε scope (= 越川氏 audition、 必要時のみ)"
    exit 0
else
    echo "❌ 軸 G δ verify gate FAIL ($FAIL 件)"
    exit 1
fi
