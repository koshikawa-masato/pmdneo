#!/usr/bin/env bash
#
# ADR-0016 step 5 δ-b: verify script for δ-a (= adpcma_volume_hook bug fix)
#
# 目的:
#   δ-a (= commit d1ebdfc) で fix した adpcma_volume_hook (= reg 0x10+ch →
#   0x08+ch) を fixture-driven regression test 化。 v0 (= PCM V=0) と
#   v16 (= PCM V=255、 PMD V4.8s max) で reg 0x08+ch (= vol/pan) 差分を確認、
#   同時に reg 0x10+ch (= start LSB) が V cmd で破壊されないことを verify。
#
# 検証: 6 段階 trace gate (= β-3 派生)
#   gate 1: v0 fixture build + trace
#   gate 2: v16 fixture build + trace
#   gate 3: reg 0x08+0 (= vol/pan) 差分 (= 0xC0 vs 0xDF)
#   gate 4: reg 0x10+0 (= start LSB) 同一性 (= V cmd で破壊されない)
#   gate 5: reg 0x18/0x20/0x28+0 (= MSB / stop LSB / stop MSB) 同一性
#   gate 6: reg 0x00 (= keyon) 同一性 (= 両 fixture で ch 0 keyon)
#
# vol mapping (= PMD V4.8s 規約):
#   v0  → V(1) table = 0   → PART_OFF_VOLUME = 0   → /8 = 0  → reg 0x08+0 = 0xC0
#   v16 → V(1) table = 255 → PART_OFF_VOLUME = 255 → /8 = 31 → reg 0x08+0 = 0xDF
#
# source 分離 (= α-3 規律踏襲):
#   ymfm-trace = chip register write (= 全 gate で)
#
# robust 化:
#   - reg 0x08+0 最初の write (= adpcma_volume_hook 経由) を取得
#   - reg 0x10/0x18/0x20/0x28+0 最初の write (= adpcma_keyon_simple 経由) を取得
#   - 値は trace から動的取得、 hardcode は expected value のみ
#
# 使い方:
#   bash src/test-fixtures/step5/verify-l-part-delta-volume-pan.sh
#
# Exit code:
#   0 = PASS、 1 = verify fail、 2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

LOW_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-part-volume-low.mml"
HIGH_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-part-volume-high.mml"
TMPDIR=$(mktemp -d "/tmp/pmdneo-delta-b-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

if [[ ! -f "$LOW_MML" ]] || [[ ! -f "$HIGH_MML" ]]; then
    echo "FAIL infra: fixture not found"
    exit 2
fi

# build + trace helper
run_fixture() {
    local mml="$1"
    local label="$2"
    PMDDOTNET_MML="$mml" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
        bash scripts/build-poc.sh > "$TMPDIR/build-$label.log" 2>&1 || return 2
    bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
        > "$TMPDIR/run-$label.log" 2>&1 || return 2
    cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TMPDIR/ymfm-$label.tsv"
    cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$TMPDIR/z80-$label.tsv"
    shasum -a 256 /tmp/pmdneo-trace/audio.wav | awk '{print $1}'
    return 0
}

# extract first ymfm-trace value for port B reg
extract_first() { awk -F'\t' -v r="$2" '$2 == "B" && $3 == r {print $4; exit}' "$1"; }

# ============================================================
# gate 1: v0 (low) fixture build + trace
# ============================================================
echo "=== gate 1: v0 (low) fixture build + trace ==="
LOW_WAV_SHA=$(run_fixture "$LOW_MML" "low") || {
    echo "  ❌ FAIL infra: v0 build/run failed"
    exit 2
}
echo "  ✅ v0 trace 取得 (wav: ${LOW_WAV_SHA:0:16}...)"

# ============================================================
# gate 2: v16 (high) fixture build + trace
# ============================================================
echo ""
echo "=== gate 2: v16 (high) fixture build + trace ==="
HIGH_WAV_SHA=$(run_fixture "$HIGH_MML" "high") || {
    echo "  ❌ FAIL infra: v16 build/run failed"
    exit 2
}
echo "  ✅ v16 trace 取得 (wav: ${HIGH_WAV_SHA:0:16}...)"

# ============================================================
# 動的値抽出 (= 最初の write、 hook 経由は idx 早い順)
# ============================================================
LOW_REG08=$(extract_first "$TMPDIR/ymfm-low.tsv" "108")
HIGH_REG08=$(extract_first "$TMPDIR/ymfm-high.tsv" "108")
LOW_REG10=$(extract_first "$TMPDIR/ymfm-low.tsv" "110")
HIGH_REG10=$(extract_first "$TMPDIR/ymfm-high.tsv" "110")
LOW_REG18=$(extract_first "$TMPDIR/ymfm-low.tsv" "118")
HIGH_REG18=$(extract_first "$TMPDIR/ymfm-high.tsv" "118")
LOW_REG20=$(extract_first "$TMPDIR/ymfm-low.tsv" "120")
HIGH_REG20=$(extract_first "$TMPDIR/ymfm-high.tsv" "120")
LOW_REG28=$(extract_first "$TMPDIR/ymfm-low.tsv" "128")
HIGH_REG28=$(extract_first "$TMPDIR/ymfm-high.tsv" "128")
# keyon (= reg 0x00) は ch 0 keyon = 0x01 が出現するか
LOW_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" && toupper($4) == "01" {print $4; exit}' "$TMPDIR/ymfm-low.tsv")
HIGH_KEYON=$(awk -F'\t' '$2 == "B" && $3 == "100" && toupper($4) == "01" {print $4; exit}' "$TMPDIR/ymfm-high.tsv")

# ============================================================
# gate 3: reg 0x08+0 (= vol/pan) 差分検出
# ============================================================
echo ""
echo "=== gate 3: reg 0x08+0 (= vol/pan) 差分 ==="
echo "  v0 (low):  reg 0x08+0 = 0x$LOW_REG08 (= 期待 0xC0 = pan|vol 0)"
echo "  v16 (high): reg 0x08+0 = 0x$HIGH_REG08 (= 期待 0xDF = pan|vol 31)"
LOW_U=$(echo "$LOW_REG08" | tr 'a-f' 'A-F')
HIGH_U=$(echo "$HIGH_REG08" | tr 'a-f' 'A-F')
if [[ "$LOW_U" == "$HIGH_U" ]]; then
    echo "  ❌ FAIL gate 3: reg 0x08+0 同一 (= 期待差分)"
    exit 1
fi
echo "  ✅ 差分検出 (= adpcma_volume_hook → reg 0x08+0 経路成立)"

# ============================================================
# gate 4: reg 0x10+0 (= start LSB) 同一性 (= V cmd で破壊なし)
# ============================================================
echo ""
echo "=== gate 4: reg 0x10+0 (= start LSB) 同一性 ==="
echo "  v0:  reg 0x10+0 = 0x$LOW_REG10"
echo "  v16: reg 0x10+0 = 0x$HIGH_REG10"
LOW_U=$(echo "$LOW_REG10" | tr 'a-f' 'A-F')
HIGH_U=$(echo "$HIGH_REG10" | tr 'a-f' 'A-F')
if [[ "$LOW_U" != "$HIGH_U" ]]; then
    echo "  ❌ FAIL gate 4: reg 0x10+0 差分 (= V cmd で破壊された可能性、 δ-a bug fix regression)"
    exit 1
fi
echo "  ✅ 同一 (= V cmd で start LSB は破壊されない、 δ-a bug fix 維持)"

# ============================================================
# gate 5: reg 0x18/0x20/0x28+0 (= 他 sample addr reg) 同一性
# ============================================================
echo ""
echo "=== gate 5: reg 0x18/0x20/0x28+0 (= sample addr 他) 同一性 ==="

check_same_reg() {
    local label="$1"
    local lv="$2"
    local hv="$3"
    local lu=$(echo "$lv" | tr 'a-f' 'A-F')
    local hu=$(echo "$hv" | tr 'a-f' 'A-F')
    echo "  $label: low=0x$lv, high=0x$hv"
    if [[ "$lu" != "$hu" ]]; then
        echo "  ❌ FAIL gate 5 ($label): 差分 (= 期待同一)"
        return 1
    fi
    return 0
}

GATE5_PASS=1
check_same_reg "reg 0x18+0 (start MSB)" "$LOW_REG18" "$HIGH_REG18" || GATE5_PASS=0
check_same_reg "reg 0x20+0 (stop LSB)"  "$LOW_REG20" "$HIGH_REG20" || GATE5_PASS=0
check_same_reg "reg 0x28+0 (stop MSB)"  "$LOW_REG28" "$HIGH_REG28" || GATE5_PASS=0

if [[ "$GATE5_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 5: sample addr reg で 1 件以上不一致"
    exit 1
fi
echo "  ✅ 全 reg 同一 (= sample addr 不変)"

# ============================================================
# gate 6: reg 0x00 (= keyon) 同一性
# ============================================================
echo ""
echo "=== gate 6: reg 0x00 keyon 同一性 ==="
echo "  v0:  ch 0 keyon (= 0x01) 出現: ${LOW_KEYON:-不検出}"
echo "  v16: ch 0 keyon (= 0x01) 出現: ${HIGH_KEYON:-不検出}"
if [[ -z "$LOW_KEYON" ]] || [[ -z "$HIGH_KEYON" ]]; then
    echo "  ❌ FAIL gate 6: ch 0 keyon (= 0x01) 不検出"
    exit 1
fi
LOW_U=$(echo "$LOW_KEYON" | tr 'a-f' 'A-F')
HIGH_U=$(echo "$HIGH_KEYON" | tr 'a-f' 'A-F')
if [[ "$LOW_U" != "$HIGH_U" ]]; then
    echo "  ❌ FAIL gate 6: keyon value 差分 (= 期待 0x01 同一)"
    exit 1
fi
echo "  ✅ 両 fixture で ch 0 keyon (= 0x01) 同一 (= vol で keyon 動作は変わらない)"

# ============================================================
# 全 gate PASS
# ============================================================
echo ""
echo "🎉 ADR-0016 step 5 δ-a adpcma_volume_hook bug fix verify PASS"
echo "   - gate 3: reg 0x08+0 vol/pan 差分 (= 0x$LOW_REG08 vs 0x$HIGH_REG08)"
echo "   - gate 4: reg 0x10+0 start LSB 同一 (= V cmd で破壊なし、 bug fix 維持)"
echo "   - gate 5: reg 0x18/0x20/0x28+0 同一 (= sample addr 不変)"
echo "   - gate 6: reg 0x00 keyon 同一 (= 0x01 ch 0)"
echo ""
echo "   wav sha256 (= 参考、 FM 同居で primary gate にしない):"
echo "     low:  $LOW_WAV_SHA"
echo "     high: $HIGH_WAV_SHA"
exit 0
