#!/usr/bin/env bash
#
# ADR-0016 step 5 β-3: verify script for β-2 (= sample lookup chain)
#
# 目的:
#   β-2 (= commits 0029034 β-2a + 93bfc3d β-2b) で成立した sample A (= @0)
#   と sample B (= @1) の ADPCM-A register 差分を regression test 化。
#   driver 実装変更なし、 既存挙動の固定 verify のみ。
#
# 検証: 6 段階 trace gate (= α-3 派生 + sample 差分軸追加)
#   gate 1: sample A (= @0) build + trace 取得
#   gate 2: sample B (= @1) build + trace 取得
#   gate 3: PART_OFF_INSTRUMENT 差分 (= 0xFAFF write、 z80-mem-trace)
#   gate 4: reg 0x10 (start LSB) 差分 (= ymfm-trace port B)
#   gate 5: reg 0x20 (stop LSB) 差分 (= ymfm-trace port B)
#   gate 6: reg 0x18 / 0x28 / 0x08 / 0x00 同一性 (= 同じ keyon / vol / pan / MSB)
#
# source 分離 (= α-3 規律踏襲):
#   z80-mem-trace = gate 3 (= PART_OFF_INSTRUMENT 書込確認)
#   ymfm-trace    = gate 4-6 (= chip register write)
#
# robust 化:
#   expected reg 値は **動的取得** (= sample A trace の値を取得、 sample B と比較)
#   hardcode 禁止、 build / linker / samples.inc 変動でも追従
#
# ADPCM-A 必須 6 reg (= port B、 ymfm-trace 表記 100 + 内部 reg):
#   reg 0x10 (= 110): start LSB ← gate 4 差分軸
#   reg 0x18 (= 118): start MSB ← gate 6 同一性軸
#   reg 0x20 (= 120): stop LSB  ← gate 5 差分軸
#   reg 0x28 (= 128): stop MSB  ← gate 6 同一性軸
#   reg 0x08 (= 108): vol/pan   ← gate 6 同一性軸
#   reg 0x00 (= 100): keyon     ← gate 6 同一性軸 (= value 0x01 必須)
#
# 使い方:
#   bash src/test-fixtures/step5/verify-l-part-beta-sample-lookup.sh
#
# Exit code:
#   0 = PASS (= 全 6 gate PASS)
#   1 = verify fail (= gate 落ち、 出力で fail gate 明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

SAMPLE_A_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-part-sample-a.mml"
SAMPLE_B_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-part-sample-b.mml"
TMPDIR=$(mktemp -d "/tmp/pmdneo-beta3-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

# infra: fixture 存在確認
if [[ ! -f "$SAMPLE_A_MML" ]] || [[ ! -f "$SAMPLE_B_MML" ]]; then
    echo "FAIL infra: fixture not found ($SAMPLE_A_MML / $SAMPLE_B_MML)"
    exit 2
fi

# ============================================================
# gate 1: sample A (= @0) build + trace 取得
# ============================================================
echo "=== gate 1: sample A (= @0) build + trace ==="
PMDDOTNET_MML="$SAMPLE_A_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build-a.log" 2>&1 || {
    echo "  ❌ FAIL infra: sample A build failed (log: $TMPDIR/build-a.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run-a.log" 2>&1 || {
    echo "  ❌ FAIL infra: sample A MAME run failed"
    exit 2
}
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TMPDIR/ymfm-a.tsv"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$TMPDIR/z80-a.tsv"
A_WAV_SHA=$(shasum -a 256 /tmp/pmdneo-trace/audio.wav | awk '{print $1}')
echo "  ✅ sample A trace 取得 (wav sha256: ${A_WAV_SHA:0:16}...)"

# ============================================================
# gate 2: sample B (= @1) build + trace 取得
# ============================================================
echo ""
echo "=== gate 2: sample B (= @1) build + trace ==="
PMDDOTNET_MML="$SAMPLE_B_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build-b.log" 2>&1 || {
    echo "  ❌ FAIL infra: sample B build failed (log: $TMPDIR/build-b.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run-b.log" 2>&1 || {
    echo "  ❌ FAIL infra: sample B MAME run failed"
    exit 2
}
cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TMPDIR/ymfm-b.tsv"
cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$TMPDIR/z80-b.tsv"
B_WAV_SHA=$(shasum -a 256 /tmp/pmdneo-trace/audio.wav | awk '{print $1}')
echo "  ✅ sample B trace 取得 (wav sha256: ${B_WAV_SHA:0:16}...)"

# ============================================================
# 動的値抽出 (= hardcode 禁止、 trace から動的に取得)
# ============================================================
# PART_OFF_INSTRUMENT 書込 value (= 最後の 0xFAFF write、 comat_pcm 経由)
A_INSTRUMENT=$(awk -F'\t' '$3 == "FAFF" {v=$4} END {print v}' "$TMPDIR/z80-a.tsv")
B_INSTRUMENT=$(awk -F'\t' '$3 == "FAFF" {v=$4} END {print v}' "$TMPDIR/z80-b.tsv")

# ADPCM-A reg 値 (= 最初の port B write、 ymfm-trace の各 reg)
extract_reg() { awk -F'\t' -v r="$2" '$2 == "B" && $3 == r {print $4; exit}' "$1"; }

A_REG10=$(extract_reg "$TMPDIR/ymfm-a.tsv" "110")  # start LSB
A_REG18=$(extract_reg "$TMPDIR/ymfm-a.tsv" "118")  # start MSB
A_REG20=$(extract_reg "$TMPDIR/ymfm-a.tsv" "120")  # stop LSB
A_REG28=$(extract_reg "$TMPDIR/ymfm-a.tsv" "128")  # stop MSB
A_REG08=$(extract_reg "$TMPDIR/ymfm-a.tsv" "108")  # vol/pan
# reg 0x00 keyon は init で複数 write、 ch 0 keyon (= value 0x01) を抽出
A_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" && toupper($4) == "01" {print $4; exit}' "$TMPDIR/ymfm-a.tsv")

B_REG10=$(extract_reg "$TMPDIR/ymfm-b.tsv" "110")
B_REG18=$(extract_reg "$TMPDIR/ymfm-b.tsv" "118")
B_REG20=$(extract_reg "$TMPDIR/ymfm-b.tsv" "120")
B_REG28=$(extract_reg "$TMPDIR/ymfm-b.tsv" "128")
B_REG08=$(extract_reg "$TMPDIR/ymfm-b.tsv" "108")
B_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" && toupper($4) == "01" {print $4; exit}' "$TMPDIR/ymfm-b.tsv")

# ============================================================
# gate 3: PART_OFF_INSTRUMENT 差分 (= z80-mem-trace)
# ============================================================
echo ""
echo "=== gate 3: PART_OFF_INSTRUMENT (= 0xFAFF) 差分 ==="
echo "  sample A: 0x$A_INSTRUMENT (= voice 0 期待)"
echo "  sample B: 0x$B_INSTRUMENT (= voice 1 期待)"
if [[ "$A_INSTRUMENT" == "$B_INSTRUMENT" ]]; then
    echo "  ❌ FAIL gate 3: PART_OFF_INSTRUMENT 同一 (期待差分)"
    exit 1
fi
echo "  ✅ 差分検出"

# ============================================================
# gate 4: reg 0x10 (start LSB) 差分
# ============================================================
echo ""
echo "=== gate 4: reg 0x10 (start LSB) 差分 ==="
echo "  sample A: 0x$A_REG10 (= sample 0 = bd start LSB)"
echo "  sample B: 0x$B_REG10 (= sample 1 = sd start LSB)"
if [[ -z "$A_REG10" ]] || [[ -z "$B_REG10" ]]; then
    echo "  ❌ FAIL gate 4: reg 0x10 write 不検出"
    exit 1
fi
if [[ "$A_REG10" == "$B_REG10" ]]; then
    echo "  ❌ FAIL gate 4: reg 0x10 同一 (期待差分)"
    exit 1
fi
echo "  ✅ 差分検出"

# ============================================================
# gate 5: reg 0x20 (stop LSB) 差分
# ============================================================
echo ""
echo "=== gate 5: reg 0x20 (stop LSB) 差分 ==="
echo "  sample A: 0x$A_REG20 (= sample 0 = bd stop LSB)"
echo "  sample B: 0x$B_REG20 (= sample 1 = sd stop LSB)"
if [[ -z "$A_REG20" ]] || [[ -z "$B_REG20" ]]; then
    echo "  ❌ FAIL gate 5: reg 0x20 write 不検出"
    exit 1
fi
if [[ "$A_REG20" == "$B_REG20" ]]; then
    echo "  ❌ FAIL gate 5: reg 0x20 同一 (期待差分)"
    exit 1
fi
echo "  ✅ 差分検出"

# ============================================================
# gate 6: 同一性検証 (= reg 0x18/0x28/0x08/0x00)
# ============================================================
echo ""
echo "=== gate 6: reg 0x18/0x28/0x08/0x00 同一性検証 ==="

check_same() {
    local label="$1"
    local av="$2"
    local bv="$3"
    if [[ -z "$av" ]] || [[ -z "$bv" ]]; then
        echo "  ❌ FAIL gate 6 ($label): write 不検出 (A=$av, B=$bv)"
        return 1
    fi
    if [[ "$av" != "$bv" ]]; then
        echo "  ❌ FAIL gate 6 ($label): A=0x$av != B=0x$bv (期待同一)"
        return 1
    fi
    echo "  ✅ $label: 両 0x$av 同一"
    return 0
}

GATE6_PASS=1
check_same "reg 0x18 (start MSB)" "$A_REG18" "$B_REG18" || GATE6_PASS=0
check_same "reg 0x28 (stop MSB)"  "$A_REG28" "$B_REG28" || GATE6_PASS=0
check_same "reg 0x08 (vol/pan)"   "$A_REG08" "$B_REG08" || GATE6_PASS=0
check_same "reg 0x00 (keyon)"     "$A_KEYON" "$B_KEYON" || GATE6_PASS=0

if [[ "$GATE6_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 6: 同一性検証で 1 件以上失敗"
    exit 1
fi

# ============================================================
# 全 gate PASS
# ============================================================
echo ""
echo "🎉 ADR-0016 step 5 β-2 sample lookup verify PASS"
echo "   - gate 1: sample A build + trace ✅"
echo "   - gate 2: sample B build + trace ✅"
echo "   - gate 3: PART_OFF_INSTRUMENT 差分 (= 0x$A_INSTRUMENT vs 0x$B_INSTRUMENT)"
echo "   - gate 4: reg 0x10 start LSB 差分 (= 0x$A_REG10 vs 0x$B_REG10)"
echo "   - gate 5: reg 0x20 stop LSB 差分 (= 0x$A_REG20 vs 0x$B_REG20)"
echo "   - gate 6: reg 0x18/0x28/0x08/0x00 同一性 ✅"
echo ""
echo "   wav sha256 (= 参考、 FM 同居で primary gate にしない):"
echo "     A: $A_WAV_SHA"
echo "     B: $B_WAV_SHA"
exit 0
