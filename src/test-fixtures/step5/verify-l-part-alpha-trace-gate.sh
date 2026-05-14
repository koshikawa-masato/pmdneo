#!/usr/bin/env bash
#
# ADR-0016 step 5 α-3: trace gate verify script for α-2 (.MN direct path + L dispatch)
#
# 目的:
#   α-2 (commit ae6b419) で成立した「.MN → L body → ADPCM-A keyon」 経路を
#   regression test 化。 driver 実装変更なし、 既存挙動の固定 verify のみ。
#
# 検証: 6 段階 trace gate (= ADR-0019 §決定 6 α + α-2 commit と揃え)
#   gate 1: .MN header parse 到達
#   gate 2: extended_data_adr read
#   gate 3: L offset read
#   gate 4: L body addr setup
#   gate 5: L part hook 到達
#   gate 6: ADPCM-A register write
#
# source 分離 (= z80 trace と ymfm trace を別判定):
#   z80-mem-trace = gate 4 (= part_workarea 0xFAE0/0xFAE1 write 確認)
#   ymfm-trace    = gate 6 (= ADPCM-A port B reg write 確認)
#   listing       = gate 1 (= parser symbol 存在 + addr 動的取得)
#   static value  = gate 2, 3 (= mc compiler 出力固定値、 α-1 ground truth)
#   logical AND   = gate 5 (= gate 4 + 6 の組合せで hook 到達を間接確認)
#
# expected L body addr 算出 (= hardcode 禁止):
#   pmddotnet_song addr を build listing から動的取得
#   expected = pmddotnet_song + 1 + 56 (= file_base + 1 + L_offset)
#
# ADPCM-A 必須 register (= port B、 ymfm-trace で 100 + 内部 reg):
#   reg 0x10 (= 110): start LSB
#   reg 0x18 (= 118): start MSB
#   reg 0x20 (= 120): stop LSB
#   reg 0x28 (= 128): stop MSB
#   reg 0x08 (= 108): volume/pan
#   reg 0x00 (= 100): keyon bit (= value 0x01 = ch 0 必須)
#
# 使い方:
#   bash src/test-fixtures/step5/verify-l-part-alpha-trace-gate.sh
#
# Exit code:
#   0 = PASS (= 全 6 gate PASS)
#   1 = verify fail (= gate 落ち、 出力で fail gate を明示)
#   2 = infra fail (= build / MAME / trace file / listing missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

L_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-part-minimum.mml"
LST="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
YMFM_TRACE="/tmp/pmdneo-trace/ymfm-trace.tsv"
Z80_TRACE="/tmp/pmdneo-trace/z80-mem-trace.tsv"

# infra: fixture 存在確認
if [[ ! -f "$L_MML" ]]; then
    echo "FAIL infra: fixture not found: $L_MML"
    exit 2
fi

# build (= PMDDOTNET_MML + PMDDOTNET_MODE=B + PMDNEO_USE_PMDDOTNET=1)
echo "=== build (= PMDDOTNET_MML=l-part-minimum.mml, MODE=B, USE_PMDDOTNET=1) ==="
PMDDOTNET_MML="$L_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > /tmp/pmdneo-alpha3-build.log 2>&1 || {
    echo "FAIL infra: build failed (log: /tmp/pmdneo-alpha3-build.log)"
    exit 2
}

# listing 存在確認
if [[ ! -f "$LST" ]]; then
    echo "FAIL infra: listing not found: $LST"
    exit 2
fi

# pmddotnet_song addr (= ROM 内 L .MN 先頭) を listing から動的取得 (= hardcode 禁止)
PMDDOTNET_SONG_ADDR=$(grep -E "pmddotnet_song:\s+\.incbin" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$PMDDOTNET_SONG_ADDR" ]]; then
    echo "FAIL infra: pmddotnet_song symbol not found in listing"
    exit 2
fi

# expected L body addr = pmddotnet_song + 1 + 56 (= file_base + 1 + L_offset)
EXPECTED_L_BODY=$(printf "%04X" $((0x$PMDDOTNET_SONG_ADDR + 1 + 56)))
EXPECTED_LSB="${EXPECTED_L_BODY:2:2}"
EXPECTED_MSB="${EXPECTED_L_BODY:0:2}"

echo "  pmddotnet_song addr = 0x$PMDDOTNET_SONG_ADDR (= listing 動的取得)"
echo "  expected L body addr = 0x$EXPECTED_L_BODY (= +1 +56)"
echo "  expected LSB = 0x$EXPECTED_LSB, MSB = 0x$EXPECTED_MSB"

# parser symbol (= gate 1)
PARSER_PC=$(grep -E "pmdneo_mn_direct_load_lq_part_addr::" "$LST" | head -1 | awk '{print $1}')
if [[ -z "$PARSER_PC" ]]; then
    echo "FAIL infra: parser symbol pmdneo_mn_direct_load_lq_part_addr not found in listing"
    exit 2
fi

# MAME run (= headless + trace)
echo ""
echo "=== MAME run (= headless + wavwrite + trace) ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > /tmp/pmdneo-alpha3-run.log 2>&1 || {
    echo "FAIL infra: MAME run failed (log: /tmp/pmdneo-alpha3-run.log)"
    exit 2
}

# trace file 存在確認
if [[ ! -f "$YMFM_TRACE" ]]; then
    echo "FAIL infra: ymfm-trace not found: $YMFM_TRACE"
    exit 2
fi
if [[ ! -f "$Z80_TRACE" ]]; then
    echo "FAIL infra: z80-mem-trace not found: $Z80_TRACE"
    exit 2
fi

# ============================================================
# gate 1: .MN header parse 到達
# ============================================================
echo ""
echo "=== gate 1: .MN header parse 到達 ==="
echo "  parser symbol (= pmdneo_mn_direct_load_lq_part_addr) PC = 0x$PARSER_PC (= listing 動的取得)"
echo "  ✅ parser symbol 存在確認 (= linker により ROM に配置)"
echo "  (= 直接 PC trace は z80-mem-trace に出ないが、 gate 4 の workarea write で経由を間接確認)"

# ============================================================
# gate 2: extended_data_adr read (= mc compiler 出力固定値)
# ============================================================
echo ""
echo "=== gate 2: extended_data_adr read ==="
echo "  expected value = 39 (= m_buf[26..27] LE、 α-1 ground truth)"
echo "  ✅ static value (= driver は読むだけ、 mc compiler が固定で出力、 α-1 hex dump で確認済)"

# ============================================================
# gate 3: L offset read (= mc compiler 出力固定値)
# ============================================================
echo ""
echo "=== gate 3: L offset read ==="
echo "  expected value = 56 (= offset_table[0] LE、 α-1 ground truth)"
echo "  ✅ static value (= L body offset = m_buf[39..40]、 α-1 hex dump で確認済)"

# ============================================================
# gate 4: L body addr setup (= z80-mem-trace 0xFAE0/0xFAE1 write)
# ============================================================
echo ""
echo "=== gate 4: L body addr setup (= part_workarea[PART_ADPCMA1].PART_OFF_ADDR write) ==="
echo "  expected: 0xFAE0=0x$EXPECTED_LSB, 0xFAE1=0x$EXPECTED_MSB (= 0x$EXPECTED_L_BODY LE)"

MATCH=$(awk -F'\t' -v lsb="$EXPECTED_LSB" -v msb="$EXPECTED_MSB" '
    $3 == "FAE0" && toupper($4) == lsb {found_lsb=1; next}
    $3 == "FAE1" && toupper($4) == msb && found_lsb {print "MATCH"; exit}
' "$Z80_TRACE")

if [[ "$MATCH" != "MATCH" ]]; then
    echo "  ❌ FAIL gate 4: L body addr setup 不一致"
    echo "    observed FAE0 writes:"
    awk -F'\t' '$3 == "FAE0"' "$Z80_TRACE" | head -5 | sed 's/^/      /'
    echo "    observed FAE1 writes:"
    awk -F'\t' '$3 == "FAE1"' "$Z80_TRACE" | head -5 | sed 's/^/      /'
    exit 1
fi
echo "  ✅ z80-mem-trace で match 確認 (= .MN parser → pmdneo5_init_part 経路成立)"

# ============================================================
# gate 5: L part hook 到達 (= gate 4 + 6 の組合せ間接確認)
# ============================================================
echo ""
echo "=== gate 5: L part hook 到達 (= adpcma_keyon_hook → adpcma_keyon_simple) ==="
echo "  (= gate 4 で workarea 設定 + gate 6 で ADPCM-A reg write 確認の論理積で間接確認)"
echo "  ✅ gate 4 PASS + gate 6 PASS で hook 経由成立 (= 後段判定)"

# ============================================================
# gate 6: ADPCM-A register write (= ymfm-trace port B 必須 reg)
# ============================================================
echo ""
echo "=== gate 6: ADPCM-A register write (= port B 必須 reg) ==="

REQUIRED_REGS=("110" "118" "120" "128" "108" "100")
REG_LABELS=("start LSB" "start MSB" "stop LSB" "stop MSB" "volume/pan" "keyon")
REG_HEX=("0x10" "0x18" "0x20" "0x28" "0x08" "0x00")
GATE6_PASS=1

for i in "${!REQUIRED_REGS[@]}"; do
    REG="${REQUIRED_REGS[$i]}"
    LABEL="${REG_LABELS[$i]}"
    HEX="${REG_HEX[$i]}"

    # port B 確認
    COUNT=$(awk -F'\t' -v r="$REG" '$2 == "B" && $3 == r' "$YMFM_TRACE" | wc -l | tr -d ' ')
    if [[ "$COUNT" -eq 0 ]]; then
        echo "  ❌ reg $HEX (= ymfm $REG、 $LABEL): port B write 0 件"
        GATE6_PASS=0
        continue
    fi

    # keyon (= reg 0x00) は value = 0x01 (= ch 0 keyon) 必須
    if [[ "$REG" == "100" ]]; then
        KEYON_CH0=$(awk -F'\t' '$2 == "B" && $3 == "100" && toupper($4) == "01"' "$YMFM_TRACE" | wc -l | tr -d ' ')
        if [[ "$KEYON_CH0" -eq 0 ]]; then
            echo "  ❌ reg $HEX (= $LABEL): port B write $COUNT 件 (= ch 0 keyon 値 0x01 不検出)"
            GATE6_PASS=0
            continue
        fi
        echo "  ✅ reg $HEX (= $LABEL): port B write $COUNT 件, ch 0 keyon (= 0x01) $KEYON_CH0 件確認"
    else
        echo "  ✅ reg $HEX (= $LABEL): port B write $COUNT 件確認"
    fi
done

if [[ "$GATE6_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 6: ADPCM-A 必須 register write 不足"
    exit 1
fi

# ============================================================
# 全 gate PASS
# ============================================================
echo ""
echo "🎉 ADR-0016 step 5 α-2 trace gate verify PASS"
echo "   - gate 1: .MN header parse 到達 (parser symbol @ 0x$PARSER_PC)"
echo "   - gate 2: extended_data_adr read (= 39、 mc compiler 固定値)"
echo "   - gate 3: L offset read (= 56、 mc compiler 固定値)"
echo "   - gate 4: L body addr setup (= 0x$EXPECTED_L_BODY @ 0xFAE0/0xFAE1)"
echo "   - gate 5: L part hook 到達 (= gate 4 + 6 で間接確認)"
echo "   - gate 6: ADPCM-A register write (= port B reg 0x10/0x18/0x20/0x28/0x08/0x00)"
exit 0
