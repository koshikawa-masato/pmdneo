#!/usr/bin/env bash
#
# ADR-0016 step 5 γ-b: verify script for L-Q 6 ch simultaneous keyon
#
# 目的:
#   γ-a (= commit cc51116) で成立した L-Q 汎用 .MN direct path を、
#   L-Q tutti fixture (= 6 ch 同時 keyon) で regression test 化。
#   driver 実装変更なし、 既存挙動の固定 verify のみ。
#
# 検証: 6 段階 trace gate (= user 4 観点をカバー)
#   gate 1: L-Q tutti build + trace 取得
#   gate 2: workarea independence (= 6 ch 各 PART_OFF_INSTRUMENT が独立書込)
#   gate 3: ch overlap (= 6 ch reg 0x10+ch が全 ch 異なる sample addr)
#   gate 4: register isolation (= reg 0x10/0x11/.../0x15 全 ch 個別書込)
#   gate 5: simultaneous keyon (= reg 0x00 で ch 0-5 全 bit keyon = 0x01/0x02/.../0x20)
#   gate 6: MSB 同一性 (= reg 0x18-0x1D 全 0x00、 sample addr < 1024 byte で正常)
#
# source 分離:
#   z80-mem-trace = gate 2 (= workarea write)
#   ymfm-trace    = gate 3-6 (= chip register write)
#
# 期待 mapping (= β-2b で確立した voice → sample 再解釈、 既存
# adpcma_ch_sample_ptr_table[] を voice index 引きで再利用):
#   @0 → bd / @1 → sd / @2 → hh / @3 → tom / @4 → rim / @5 → top
#
# ch ↔ workarea mapping (= PART_WORKAREA_SIZE=64 で計算可):
#   L (= PART_ADPCMA1 = part 11) → 0xF820 + 11*64 = 0xFAE0
#   M (= part 12) → 0xFB20
#   N (= part 13) → 0xFB60
#   O (= part 14) → 0xFBA0
#   P (= part 15) → 0xFBE0
#   Q (= part 16) → 0xFC20
# PART_OFF_INSTRUMENT = offset 31:
#   L: 0xFAFF / M: 0xFB3F / N: 0xFB7F / O: 0xFBBF / P: 0xFBFF / Q: 0xFC3F
#
# 使い方:
#   bash src/test-fixtures/step5/verify-l-q-tutti-gamma.sh
#
# Exit code:
#   0 = PASS (= 全 6 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

TUTTI_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-tutti.mml"
TMPDIR=$(mktemp -d "/tmp/pmdneo-gamma-b-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

# infra: fixture 存在確認
if [[ ! -f "$TUTTI_MML" ]]; then
    echo "FAIL infra: fixture not found: $TUTTI_MML"
    exit 2
fi

# ============================================================
# gate 1: L-Q tutti build + trace 取得
# ============================================================
echo "=== gate 1: L-Q tutti build + trace ==="
PMDDOTNET_MML="$TUTTI_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build.log" 2>&1 || {
    echo "  ❌ FAIL infra: build failed (log: $TMPDIR/build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run.log" 2>&1 || {
    echo "  ❌ FAIL infra: MAME run failed"
    exit 2
}
Z80_TRACE="/tmp/pmdneo-trace/z80-mem-trace.tsv"
YMFM_TRACE="/tmp/pmdneo-trace/ymfm-trace.tsv"
if [[ ! -f "$Z80_TRACE" ]] || [[ ! -f "$YMFM_TRACE" ]]; then
    echo "  ❌ FAIL infra: trace file missing"
    exit 2
fi
WAV_SHA=$(shasum -a 256 /tmp/pmdneo-trace/audio.wav | awk '{print $1}')
echo "  ✅ build + trace 取得 (wav sha256: ${WAV_SHA:0:16}...)"

# ============================================================
# gate 2: workarea independence (= 6 ch PART_OFF_INSTRUMENT 独立書込)
# ============================================================
echo ""
echo "=== gate 2: workarea independence ==="
# 各 ch の voice idx 書込 (= 0xFAFF / 0xFB3F / ... ) を抽出
# init clear (= 0x00) の後、 comat_pcm 経由で voice idx 書込される
# 期待: L=0x00, M=0x01, N=0x02, O=0x03, P=0x04, Q=0x05

CH_NAMES=("L" "M" "N" "O" "P" "Q")
INSTRUMENT_ADDRS=("FAFF" "FB3F" "FB7F" "FBBF" "FBFF" "FC3F")
EXPECTED_INSTRUMENTS=("00" "01" "02" "03" "04" "05")

GATE2_PASS=1
for i in 0 1 2 3 4 5; do
    CH="${CH_NAMES[$i]}"
    ADDR="${INSTRUMENT_ADDRS[$i]}"
    EXPECTED="${EXPECTED_INSTRUMENTS[$i]}"
    # 最後の write を取得 (= comat_pcm 経由の voice idx)
    OBSERVED=$(awk -F'\t' -v a="$ADDR" '$3 == a {v=$4} END {print v}' "$Z80_TRACE")
    if [[ -z "$OBSERVED" ]]; then
        echo "  ❌ FAIL gate 2 ($CH @ 0x$ADDR): write 不検出"
        GATE2_PASS=0
        continue
    fi
    if [[ "$(echo "$OBSERVED" | tr 'a-f' 'A-F')" != "$(echo "$EXPECTED" | tr 'a-f' 'A-F')" ]]; then
        echo "  ❌ FAIL gate 2 ($CH @ 0x$ADDR): expected 0x$EXPECTED, observed 0x$OBSERVED"
        GATE2_PASS=0
        continue
    fi
    echo "  ✅ $CH (= 0x$ADDR): voice idx 0x$OBSERVED"
done
if [[ "$GATE2_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 2: workarea independence で 1 件以上不一致"
    exit 1
fi

# ============================================================
# gate 3: ch overlap (= 6 ch reg 0x10+ch sample addr 全 ch 異なる)
# ============================================================
echo ""
echo "=== gate 3: ch overlap (= 6 ch start LSB 全 ch 異なる) ==="
START_LSB_REGS=("110" "111" "112" "113" "114" "115")
declare -a START_LSB_VALUES
for i in 0 1 2 3 4 5; do
    CH="${CH_NAMES[$i]}"
    REG="${START_LSB_REGS[$i]}"
    VAL=$(awk -F'\t' -v r="$REG" '$2 == "B" && $3 == r {v=$4} END {print v}' "$YMFM_TRACE")
    if [[ -z "$VAL" ]]; then
        echo "  ❌ FAIL gate 3 ($CH @ reg 0x10+$i): write 不検出"
        exit 1
    fi
    START_LSB_VALUES[$i]="$VAL"
    echo "  $CH reg 0x10+$i (= ymfm $REG): 0x$VAL"
done

# 全 ch 異なるか確認 (= sample 0-5 が別 addr)
UNIQ_COUNT=$(printf '%s\n' "${START_LSB_VALUES[@]}" | sort -u | wc -l | tr -d ' ')
if [[ "$UNIQ_COUNT" -ne 6 ]]; then
    echo "  ❌ FAIL gate 3: 6 ch start LSB が全部 unique でない (uniq=$UNIQ_COUNT)"
    exit 1
fi
echo "  ✅ 全 6 ch で異なる sample addr 引き (= ch overlap 成立)"

# ============================================================
# gate 4: register isolation (= 6 ch 全 reg group で個別書込確認)
# ============================================================
echo ""
echo "=== gate 4: register isolation ==="
# 各 reg group (= 0x10/0x18/0x20/0x28/0x08+ch) で 6 ch 全 reg に write が存在することを確認
REG_GROUPS=("110:111:112:113:114:115" "118:119:11A:11B:11C:11D" "120:121:122:123:124:125" "128:129:12A:12B:12C:12D" "108:109:10A:10B:10C:10D")
GROUP_NAMES=("start LSB" "start MSB" "stop LSB" "stop MSB" "vol/pan")

GATE4_PASS=1
for g in 0 1 2 3 4; do
    GROUP="${REG_GROUPS[$g]}"
    NAME="${GROUP_NAMES[$g]}"
    IFS=':' read -r -a REGS <<< "$GROUP"
    MISSING=""
    for r in "${REGS[@]}"; do
        # toupper 比較 (= ymfm reg は大文字、 bash 3.x 対応で tr 経由)
        UR=$(echo "$r" | tr 'a-f' 'A-F')
        COUNT=$(awk -F'\t' -v r="$UR" '$2 == "B" && toupper($3) == r' "$YMFM_TRACE" | wc -l | tr -d ' ')
        if [[ "$COUNT" -eq 0 ]]; then
            MISSING="$MISSING $r"
        fi
    done
    if [[ -n "$MISSING" ]]; then
        echo "  ❌ $NAME: write 不検出 reg$MISSING"
        GATE4_PASS=0
    else
        echo "  ✅ $NAME: 全 6 ch 個別書込確認"
    fi
done
if [[ "$GATE4_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 4: register isolation で 1 件以上不検出"
    exit 1
fi

# ============================================================
# gate 5: simultaneous keyon (= reg 0x00 で 6 ch 全 bit keyon)
# ============================================================
echo ""
echo "=== gate 5: simultaneous keyon ==="
# reg 0x00 (= 100) write のうち、 ch keyon bit (= 0x01/0x02/0x04/0x08/0x10/0x20)
# が **全部** 出現することを確認

EXPECTED_KEYONS=("01" "02" "04" "08" "10" "20")
GATE5_PASS=1
for i in 0 1 2 3 4 5; do
    EXP="${EXPECTED_KEYONS[$i]}"
    COUNT=$(awk -F'\t' -v v="$EXP" '$2 == "B" && $3 == "100" && toupper($4) == toupper(v)' "$YMFM_TRACE" | wc -l | tr -d ' ')
    if [[ "$COUNT" -eq 0 ]]; then
        echo "  ❌ ch $i keyon (= reg 0x00 = 0x$EXP): write 不検出"
        GATE5_PASS=0
    else
        echo "  ✅ ch $i keyon (= reg 0x00 = 0x$EXP): $COUNT 件確認"
    fi
done
if [[ "$GATE5_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 5: 6 ch simultaneous keyon で 1 件以上不検出"
    exit 1
fi

# ============================================================
# gate 6: MSB 同一性 (= reg 0x18-0x1D, 0x28-0x2D 全 0x00)
# ============================================================
echo ""
echo "=== gate 6: MSB 同一性 (= sample addr < 1024 byte で全 ch MSB 0x00) ==="
MSB_REGS=("118" "119" "11A" "11B" "11C" "11D" "128" "129" "12A" "12B" "12C" "12D")
GATE6_PASS=1
for REG in "${MSB_REGS[@]}"; do
    UR=$(echo "$REG" | tr 'a-f' 'A-F')
    VAL=$(awk -F'\t' -v r="$UR" '$2 == "B" && toupper($3) == r {v=$4} END {print v}' "$YMFM_TRACE")
    if [[ -z "$VAL" ]]; then
        echo "  ❌ reg 0x${REG:1} (= ymfm $UR): write 不検出"
        GATE6_PASS=0
        continue
    fi
    VAL_U=$(echo "$VAL" | tr 'a-f' 'A-F')
    if [[ "$VAL_U" != "00" ]]; then
        echo "  ❌ reg 0x${REG:1} (= ymfm $UR): 0x$VAL (= 期待 0x00)"
        GATE6_PASS=0
        continue
    fi
done
if [[ "$GATE6_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 6: MSB 同一性で 1 件以上不一致"
    exit 1
fi
echo "  ✅ 全 12 reg (= start/stop MSB × 6 ch) 0x00 同一"

# ============================================================
# 全 gate PASS
# ============================================================
echo ""
echo "🎉 ADR-0016 step 5 γ L-Q tutti verify PASS"
echo "   - gate 1: build + trace ✅"
echo "   - gate 2: workarea independence (= 6 ch voice idx 独立書込) ✅"
echo "   - gate 3: ch overlap (= 6 ch sample addr 全 ch 異なる) ✅"
echo "   - gate 4: register isolation (= 5 reg group × 6 ch 全部書込) ✅"
echo "   - gate 5: simultaneous keyon (= ch 0-5 全 bit 順次 keyon) ✅"
echo "   - gate 6: MSB 同一性 (= start/stop MSB 全 0x00) ✅"
echo ""
echo "   wav sha256 (= 参考、 FM 同居で primary gate にしない):"
echo "     $WAV_SHA"
exit 0
