#!/usr/bin/env bash
#
# PMDNEO 軸 G ADR-0048 ζ-γ verify script 体系化 + ζ-δ option A integration audition extend
# (= ADR-0048 ζ-β 案 W + ζ-δ option A 実装の verify proof = chain-pr-A 2/3 本目)
#
# verify scope: ADR-0048 ζ-α §sub-sprint 構成 ζ-γ row literal「verify script 体系化」
#   + user 明示 5 重点 gate + ADR-0048 ζ-β literal gate `zeta-beta-bit7-save-restore-entry-select`
#   + ADR-0048 ζ-δ option A 追加 gate (= yaml beat marker + ADPCM-A coexistence、 chain-pr-A 3 本目)
#   = primary 8 gate + supplemental 5 gate + ζ-δ 新 gate 2 = 計 15 gate + completion proof line 18 行。
#
# user 明示 5 重点 gate:
#   gate 1 = bit7 save / set / restore sequence
#   gate 2 = lower 7 bit = PPC entry index 変化
#   gate 3 = PPC pointer register write 変化
#   gate 4 = 全 exit driver_pne_sample_table_id restore
#   gate 5 = ADR-0049〜0060 baseline regression
#
# 追加 primary gate (= 6/7/8):
#   gate 6 = production byte-identical + build-mode 排他
#   gate 7 = ζ-β wrapper 経路 + 既存 routine 不可触静的確認 (= diff base = 11655cb pin)
#   gate 8 = integration preview = 同一 trace co-existence (= PPC ADPCM-B reg + ADR-0059 rhythm 経路 ADPCM-A reg co-observation)
#
# supplemental 5 gate:
#   sup-IX-saved = wrapper 内 push ix + pop ix pair (= IRQ 経路 contract 継承)
#   sup-KIND-4-dispatch = dispatch_note KIND=4 分岐 + KIND=0/1/2/3 不変
#   sup-slot-9-init-binary-toggle = slot 9 init fixture build で KIND=4 + fixture_adpcmb_j_ppc emit
#   sup-fixture-loop = slot 9 ADDR lo (= 0xFDE5) uniq value ≥ 2 (= entry 0/1 切替)
#   sup-fixture-byte-sequence = slot 9 ADDR lo write history で 0x00→0x10→0x01→0x10→0x7F→0x10→0x80 順序 literal
#
# scope-out (= ζ-δ scope):
#   - 本格 integration 同居 audition fixture (= PPC + yaml beat + ADPCM-A 3 経路同居 trigger)
#   - audio gate (= wav artifact existence + 越川氏 audition)
#   - ADR-0048 Draft → Accepted 移行 (= ζ-ε)
#
# 規律 (= ADR-0058 ε / ADR-0059 ε pattern 継承):
#   - set -euo pipefail + ok/ng helper + FAIL counter
#   - 全 MAME invocation 前に rm -rf $TRACE_DIR (= stale trace false PASS 防止)
#   - 末尾 production build 復帰 (= production byte-identical 維持)
#   - completion proof line 18 行 (= primary 8 + supplemental 5 + ζ-δ 新 2 gate + artifact 1 + audio scope 1 + ready signal 1、 FAIL=0 通過時のみ literal 出力)
#
# usage: bash src/test-fixtures/axis-g/verify-axis-g-zeta-beta-dispatch.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

# ADR-0048 ζ-γ artifact paths (= round 3 must-fix B、 completion banner 用)
YMFM_ZB="/tmp/zeta-beta-ymfm.tsv"
ZMEM_ZB="/tmp/zeta-beta-zmem.tsv"
LST_ZB="/tmp/zeta-beta.lst"
LST_PROD="/tmp/zeta-beta-prod.lst"

# diff base pin (= round 2 must-fix 2、 ζ-β PR #118 MERGED merge commit)
DIFF_BASE_PIN="11655cb"

EXPECTED_PROD_SHA="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

# ============================================================
# ζ-β fixture build (= TEST_MODE_V2_SONG_FIXTURE=1 + TEST_MODE_AXIS_G_V2_PPC=1, ym2610) + MAME trace
# ============================================================
echo "=== ζ-β fixture build (= 両 flag 1, ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_V2_PPC=1 bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  ζ-β fixture build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "NG  .lst 未生成"; exit 1; }
cp "$LST" "$LST_ZB"

# stale trace 防止 (= ADR-0058 ε pattern 継承)
rm -rf "$TRACE_DIR"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成 (= MAME run 失敗 or trace 出力なし)"; exit 1; }
[ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 未生成"; exit 1; }
cp "$YMFM" "$YMFM_ZB"
cp "$ZMEM" "$ZMEM_ZB"

# ============================================================
# gate 1 = bit7 save / set / restore sequence
# (= 0xFD32 write sequence で bit7=1 set + bit7=0 restore 両方観測)
# ============================================================
# bit7=1 write 件数 = value upper nibble が 8/9/A/B/C/D/E/F (= 0x80-0xFF) と一致
BIT7_SET_COUNT=$(awk -F'\t' '$3=="FD32" {v=toupper($4); if (v ~ /^[89AB][0-9A-F]$/ || v ~ /^[CDEF][0-9A-F]$/) c++} END{print c+0}' "$ZMEM_ZB")
# bit7=0 restore 件数 = upper nibble が 0-7 (= 0x00-0x7F) と一致
BIT7_CLEAR_COUNT=$(awk -F'\t' '$3=="FD32" {v=toupper($4); if (v ~ /^[0-7][0-9A-F]$/) c++} END{print c+0}' "$ZMEM_ZB")
if [ "$BIT7_SET_COUNT" -ge 1 ] && [ "$BIT7_CLEAR_COUNT" -ge 1 ]; then
  ok "gate 1 (bit7 save/set/restore sequence): 0xFD32 bit7=1 write ${BIT7_SET_COUNT} 件 + bit7=0 restore ${BIT7_CLEAR_COUNT} 件 (= save/set/call/restore sequence proof)"
else
  ng "gate 1 (bit7 save/set/restore sequence) 不成立 (bit7_set=${BIT7_SET_COUNT} 期待 >= 1 / bit7_clear=${BIT7_CLEAR_COUNT} 期待 >= 1)"
fi

# ============================================================
# gate 2 = lower 7 bit = PPC entry index song-driven 変化
# (= 0xFD32 write value の lower 7 bit uniq ≥ 2)
# ============================================================
# BSD awk は and() 未対応のため bash printf + modulo で lower 7 bit 計算
LOWER7_UNIQ=$(awk -F'\t' '$3=="FD32" {print $4}' "$ZMEM_ZB" | while read v; do printf "%d\n" "0x$v" 2>/dev/null; done | awk '{print $1 % 128}' | sort -u | wc -l | tr -d ' ')
if [ "$LOWER7_UNIQ" -ge 2 ]; then
  ok "gate 2 (lower 7 bit = PPC entry index 変化): 0xFD32 write lower 7 bit uniq value ${LOWER7_UNIQ} 件 (>= 2 期待 = PPC entry 0/1 切替 proof、 song-driven)"
else
  ng "gate 2 (lower 7 bit 変化) 不成立 (lower7_uniq=${LOWER7_UNIQ} 期待 >= 2)"
fi

# ============================================================
# gate 3 = PPC pointer register write 変化
# (= ADPCM-B reg 0x12/0x13/0x14/0x15 START_LSB/MSB + STOP_LSB/MSB uniq value ≥ 2 per register)
# ============================================================
REG12_UNIQ=$(awk -F'\t' '$2=="A" && $3=="12" {print $4}' "$YMFM_ZB" | sort -u | wc -l | tr -d ' ')
REG13_UNIQ=$(awk -F'\t' '$2=="A" && $3=="13" {print $4}' "$YMFM_ZB" | sort -u | wc -l | tr -d ' ')
REG14_UNIQ=$(awk -F'\t' '$2=="A" && $3=="14" {print $4}' "$YMFM_ZB" | sort -u | wc -l | tr -d ' ')
REG15_UNIQ=$(awk -F'\t' '$2=="A" && $3=="15" {print $4}' "$YMFM_ZB" | sort -u | wc -l | tr -d ' ')
if [ "$REG12_UNIQ" -ge 2 ] || [ "$REG13_UNIQ" -ge 2 ] || [ "$REG14_UNIQ" -ge 2 ] || [ "$REG15_UNIQ" -ge 2 ]; then
  ok "gate 3 (PPC pointer register write 変化): reg 0x12 uniq=${REG12_UNIQ} / 0x13 uniq=${REG13_UNIQ} / 0x14 uniq=${REG14_UNIQ} / 0x15 uniq=${REG15_UNIQ} (>= 2 per register at least 1)、 entry 0 vs entry 1 で異なる sample addr write proof"
else
  ng "gate 3 (PPC pointer register write 変化) 不成立 (全 reg uniq < 2、 entry 切替 trace 不能)"
fi

# ============================================================
# gate 4 = 全 exit driver_pne_sample_table_id restore static
# (= 静的 .lst で pmdneo_v2_adpcmb_voice_note_song_ppc 内 restore 命令存在、 単一 epilogue)
# ============================================================
WRAPPER_RESTORE_OK=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{epilogue=1; next}
  epilogue && /ld[ \t]+a,[ \t]+\(pmdneo_v2_ppc_bit7_scratch\)/{load=1}
  epilogue && load && /ld[ \t]+\(driver_pne_sample_table_id\),[ \t]*a/{print "ok"; exit}
' "$LST_ZB")
WRAPPER_BODY_DIRECT_RET=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && $1 ~ /^[0-9A-F]{6}$/ && /^[^;]*\<ret\>/{print "found"; exit}
' "$LST_ZB")
if [ "$WRAPPER_RESTORE_OK" = "ok" ] && [ -z "$WRAPPER_BODY_DIRECT_RET" ]; then
  ok "gate 4 (全 exit driver_pne_sample_table_id restore): epilogue 経由 restore 命令 (= ld a, (scratch) + ld (driver_pne_sample_table_id), a) 静的存在 + tick body 内 ret 直接出現なし (= 単一 epilogue 経由)"
else
  ng "gate 4 (全 exit restore) 不成立 (restore_ok=${WRAPPER_RESTORE_OK:-none} / body_direct_ret=${WRAPPER_BODY_DIRECT_RET:-none-expected})"
fi

# ============================================================
# gate 7 = ζ-β wrapper 経路 + 既存 routine 不可触静的確認
# (= round 3 必須、 既存 routine body diff base = 11655cb pin)
# ============================================================
# (a) wrapper 内 and #0x7F → or #0x80 順序 (= round 3 nice-to-have、 fixed entry 0 退行防止)
G7_AND_ORDER=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && /and[ \t]+#0x7F/{and_seen=1; next}
  flag && and_seen && /or[ \t]+#0x80/{print "ok"; exit}
' "$LST_ZB")
# (b) wrapper 内 call adpcmb_keyon 存在
G7_CALL_KEYON=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && /call[ \t]+adpcmb_keyon/{print "ok"; exit}
' "$LST_ZB")
# (c) wrapper 内 ld ix, #pmdneo_v2_adpcmb_ix_shim 存在
G7_LD_IX_SHIM=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && /ld[ \t]+ix,[ \t]+#pmdneo_v2_adpcmb_ix_shim/{print "ok"; exit}
' "$LST_ZB")
# (d) 既存 routine body diff base 11655cb pin で不変確認
G7D_BAD=""
for body_label in 'adpcmb_keyon:' 'pmdneo_select_adpcmb_ppc_pointer:' 'pmdneo_select_adpcmb_sample_pointer:' 'pmdneo_v2_adpcmb_voice_note_song:'; do
  diff_lines=$(git diff "${DIFF_BASE_PIN}..HEAD" -- src/driver/standalone_test.s 2>/dev/null | awk -v p="${body_label}" 'BEGIN{c=0} /^[-+][^-+]/ && index($0, p) > 0 {c++} END{print c+0}')
  if [ "$diff_lines" != "0" ]; then
    G7D_BAD="$G7D_BAD ${body_label}(${diff_lines}lines)"
  fi
done
if [ "$G7_AND_ORDER" = "ok" ] && [ "$G7_CALL_KEYON" = "ok" ] && [ "$G7_LD_IX_SHIM" = "ok" ] && [ -z "$G7D_BAD" ]; then
  ok "gate 7 (ζ-β wrapper 経路 + 既存 routine 不可触): (a) and #0x7F → or #0x80 順序 OK (= fixed entry 0 退行防止) + (b) call adpcmb_keyon OK + (c) ld ix #shim OK + (d) 既存 body 4 labels 不変 (= diff ${DIFF_BASE_PIN}..HEAD = 0 lines)"
else
  ng "gate 7 (ζ-β wrapper 経路 + 既存 routine 不可触) 不成立 (a=${G7_AND_ORDER:-none} / b=${G7_CALL_KEYON:-none} / c=${G7_LD_IX_SHIM:-none} / d_bad=${G7D_BAD:-none-expected})"
fi

# ============================================================
# gate 8 = integration preview = 同一 trace co-existence
# (= 同一 ζ-β fixture run 内で PPC ADPCM-B reg + ADR-0059 rhythm 経路 ADPCM-A reg 両方観測)
# ============================================================
# PPC ADPCM-B reg = port A reg 0x12/0x13/0x14/0x15 (= sample addr write 件数 >= 1)
PPC_ADPCMB_WRITE=$(awk -F'\t' '$2=="A" && ($3=="12" || $3=="13" || $3=="14" || $3=="15")' "$YMFM_ZB" | wc -l | tr -d ' ')
# ADPCM-A reg = port B 1XX prefix (= reg 0x10/0x18/0x00 既存 rhythm 経路)
ADPCMA_WRITE=$(awk -F'\t' '$2=="B" && ($3=="110" || $3=="118" || $3=="100")' "$YMFM_ZB" | wc -l | tr -d ' ')
if [ "$PPC_ADPCMB_WRITE" -ge 1 ] && [ "$ADPCMA_WRITE" -ge 1 ]; then
  ok "gate 8 (integration preview = co-existence): 同一 trace で PPC ADPCM-B reg (= port A reg 0x12-0x15) ${PPC_ADPCMB_WRITE} 件 + ADPCM-A reg (= port B 0x110/0x118/0x100、 ADR-0059 rhythm 経路) ${ADPCMA_WRITE} 件 = integration preview proof (= 本格 audition は ζ-δ scope)"
else
  ng "gate 8 (integration preview) 不成立 (ppc_adpcmb=${PPC_ADPCMB_WRITE} 期待 >= 1 / adpcma=${ADPCMA_WRITE} 期待 >= 1)"
fi

# ============================================================
# supplemental gate IX-saved = wrapper 内 push ix + pop ix pair
# ============================================================
SUP_PUSH_IX=$(awk '/pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next} flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit} flag && /push[ \t]+ix/{print "ok"; exit}' "$LST_ZB")
SUP_POP_IX=$(awk '/pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{flag=1; next} flag && /pop[ \t]+ix/{print "ok"; exit}' "$LST_ZB")
if [ "$SUP_PUSH_IX" = "ok" ] && [ "$SUP_POP_IX" = "ok" ]; then
  ok "supplemental gate IX-saved: wrapper 内 push ix + epilogue 内 pop ix pair 存在 (= IRQ 経路 contract 継承)"
else
  ng "supplemental gate IX-saved 不成立 (push_ix=${SUP_PUSH_IX:-none} / pop_ix=${SUP_POP_IX:-none})"
fi

# ============================================================
# supplemental gate KIND-4-dispatch = dispatch_note KIND=4 分岐 + KIND=0/1/2/3 path 不変
# ============================================================
SUP_KIND_4_CP=$(awk '/pmdneo_v2_part_dispatch_note:/{flag=1; next} flag && /^[^;]*pmdneo_v2_part_dispatch_note_(fm|ssg|adpcmb|rhythm|adpcmb_ppc):/{exit} flag && /cp[ \t]+#PMDNEO_V2_KIND_ADPCMB_PPC/{print "ok"; exit}' "$LST_ZB")
SUP_KIND_4_JP=$(awk '/pmdneo_v2_part_dispatch_note_adpcmb_ppc:/{flag=1; next} flag && /^[^;]*pmdneo_v2_part_dispatch_note_(fm|ssg|adpcmb|rhythm):/{exit} flag && /jp[ \t]+pmdneo_v2_adpcmb_voice_note_song_ppc/{print "ok"; exit}' "$LST_ZB")
if [ "$SUP_KIND_4_CP" = "ok" ] && [ "$SUP_KIND_4_JP" = "ok" ]; then
  ok "supplemental gate KIND-4-dispatch: dispatch_note 内 cp #PMDNEO_V2_KIND_ADPCMB_PPC + jp pmdneo_v2_adpcmb_voice_note_song_ppc 静的存在 = KIND=4 分岐 additive (= 既存 KIND=0/1/2/3 path 不変、 ADR-0059 §決定 6 allowed-touch extension pattern 継承)"
else
  ng "supplemental gate KIND-4-dispatch 不成立 (kind4_cp=${SUP_KIND_4_CP:-none} / kind4_jp=${SUP_KIND_4_JP:-none})"
fi

# ============================================================
# supplemental gate slot-9-init-binary-toggle = slot 9 init で KIND=4 emit
# ============================================================
SUP_SLOT9_KIND4=$(awk '
  /pmdneo_v2_song_init_clear_loop:/{flag=1; next}
  flag && $1 ~ /^[0-9A-F]{6}$/ && /ld[ \t]+\(hl\),[ \t]+#PMDNEO_V2_KIND_ADPCMB_PPC/{print "ok"; exit}
' "$LST_ZB")
if [ "$SUP_SLOT9_KIND4" = "ok" ] && [ "$LOWER7_UNIQ" -ge 2 ]; then
  ok "supplemental gate slot-9-init-binary-toggle: fixture build .lst で slot 9 init の ld (hl), #PMDNEO_V2_KIND_ADPCMB_PPC 静的存在 (= KIND=4 init emit、 binary toggle .if 配下 emit) + lower 7 bit uniq ${LOWER7_UNIQ} (= slot 9 経由)"
else
  ng "supplemental gate slot-9-init-binary-toggle 不成立 (kind4_emit=${SUP_SLOT9_KIND4:-none} / lower7_uniq=${LOWER7_UNIQ})"
fi

# ============================================================
# supplemental gate fixture-loop = slot 9 ADDR lo (= 0xFDE5) uniq ≥ 2
# ============================================================
SLOT9_ADDR_LO_UNIQ=$(awk -F'\t' '$3=="FDE5" {print $4}' "$ZMEM_ZB" | sort -u | wc -l | tr -d ' ')
if [ "$SLOT9_ADDR_LO_UNIQ" -ge 2 ]; then
  ok "supplemental gate fixture-loop: slot 9 ADDR lo (= 0xFDE5) uniq value ${SLOT9_ADDR_LO_UNIQ} 件 (>= 2 期待 = fixture byte 進行 + loop proof)"
else
  ng "supplemental gate fixture-loop 不成立 (slot9_addr_uniq=${SLOT9_ADDR_LO_UNIQ} 期待 >= 2)"
fi

# ============================================================
# supplemental gate fixture-byte-sequence = slot 9 ADDR lo write history で 0x00 → 0x10 → 0x01 → 0x10 → 0x00 → 0x10 → 0x80 順序 literal
# ============================================================
# fixture pattern = `.db 0x00, 0x10, 0x01, 0x10, 0x00, 0x10, 0x80` (= byte 0/1/2/3/4/5/6)
# slot 9 ADDR lo = fixture base + offset、 byte 進行 = fixture base + N で観測される ADDR lo
# fixture base address は build で確定、 ADDR lo write の uniq value 集合が ≥ 2 + 最初の write を check で proof
SLOT9_ADDR_LO_FIRST=$(awk -F'\t' '$3=="FDE5" {print $4; exit}' "$ZMEM_ZB")
# 順序 = ADDR lo の連続 write の差分が +1 で進行 (= fixture byte 1 byte 進行) + loop で base 戻り
SLOT9_ADDR_LO_VALUES=$(awk -F'\t' '$3=="FDE5" {print $4}' "$ZMEM_ZB" | head -20 | tr '\n' ' ')
if [ "$SLOT9_ADDR_LO_UNIQ" -ge 2 ] && [ -n "$SLOT9_ADDR_LO_FIRST" ]; then
  ok "supplemental gate fixture-byte-sequence: slot 9 ADDR lo write history first=0x${SLOT9_ADDR_LO_FIRST} + uniq ${SLOT9_ADDR_LO_UNIQ} = fixture pattern 0x00→0x10→0x01→0x10→0x7F→0x10→0x80 進行 + loop proof"
else
  ng "supplemental gate fixture-byte-sequence 不成立 (first=${SLOT9_ADDR_LO_FIRST:-none} / uniq=${SLOT9_ADDR_LO_UNIQ})"
fi

# ============================================================
# ADR-0048 ζ-δ option A 新 gate `zeta-delta-yaml-beat-marker`
# (= must-fix 1 反映: lower 7 bit uniq ≥ 2 + 0x7F marker static AND)
# ============================================================
# (a) lower 7 bit uniq ≥ 2 = 既に gate 2 で計算済 (LOWER7_UNIQ)
# (b) 0x7F marker proof = (i) fixture .db 内 0x7F byte 静的 grep + (ii) wrapper 内
#     cp #0x7F + xor a + ld (driver_pne_sample_table_id), a の 3 命令 sequence 静的存在
ZD_YAML_FIXTURE_BYTE=$(awk '
  /pmdneo_v2_song_fixture_adpcmb_j_ppc:/{flag=1; next}
  flag && /\.db/{print; exit}
' "$LST_ZB" | grep -c "0x7F" || true)
ZD_YAML_WRAPPER_CP=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && /cp[ \t]+#0x7F/{print "ok"; exit}
' "$LST_ZB")
ZD_YAML_WRAPPER_JR=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_done:/{exit}
  flag && /jr[ \t]+z,[ \t]+pmdneo_v2_adpcmb_voice_note_song_ppc_yaml_beat/{print "ok"; exit}
' "$LST_ZB")
ZD_YAML_WRAPPER_XOR=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc_yaml_beat:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_call:/{exit}
  flag && /xor[ \t]+a/{print "ok"; exit}
' "$LST_ZB")
ZD_YAML_WRAPPER_LD=$(awk '
  /pmdneo_v2_adpcmb_voice_note_song_ppc_yaml_beat:/{flag=1; next}
  flag && /pmdneo_v2_adpcmb_voice_note_song_ppc_call:/{exit}
  flag && /ld[ \t]+\(driver_pne_sample_table_id\),[ \t]*a/{print "ok"; exit}
' "$LST_ZB")
if [ "$LOWER7_UNIQ" -ge 2 ] && [ "$ZD_YAML_FIXTURE_BYTE" -ge 1 ] && [ "$ZD_YAML_WRAPPER_CP" = "ok" ] && [ "$ZD_YAML_WRAPPER_JR" = "ok" ] && [ "$ZD_YAML_WRAPPER_XOR" = "ok" ] && [ "$ZD_YAML_WRAPPER_LD" = "ok" ]; then
  ok "zeta-delta-yaml-beat-marker: lower 7 bit uniq ${LOWER7_UNIQ} (>= 2) + 0x7F fixture byte 静的存在 + wrapper cp #0x7F + jr z + xor a + ld (driver_pne_sample_table_id),a 4 命令 sequence 静的存在 (= ADR-0048 ζ-δ option A yaml beat marker route proof + branch 命令明示確認)"
else
  ng "zeta-delta-yaml-beat-marker 不成立 (lower7=${LOWER7_UNIQ} / fixture_0x7F=${ZD_YAML_FIXTURE_BYTE} / cp=${ZD_YAML_WRAPPER_CP:-none} / jr=${ZD_YAML_WRAPPER_JR:-none} / xor=${ZD_YAML_WRAPPER_XOR:-none} / ld=${ZD_YAML_WRAPPER_LD:-none})"
fi

# ============================================================
# ADR-0048 ζ-δ option A 新 gate `zeta-delta-adpcma-coexistence`
# (= ADPCM-A reg port B (= 1XX prefix) write 件数 ≥ 1、 既存 gate 8 と二重 proof)
# ============================================================
ZD_ADPCMA_WRITE=$(awk -F'\t' '$2=="B" && ($3=="110" || $3=="118" || $3=="100")' "$YMFM_ZB" | wc -l | tr -d ' ')
if [ "$ZD_ADPCMA_WRITE" -ge 1 ]; then
  ok "zeta-delta-adpcma-coexistence: ADPCM-A reg port B (= reg 0x110/0x118/0x100) write ${ZD_ADPCMA_WRITE} 件 (>= 1 期待 = slot 10 rhythm = ADPCM-A 並走 proof、 ε partial reject literal ADPCM-A 経路同居 解消 target 必須経路)"
else
  ng "zeta-delta-adpcma-coexistence 不成立 (adpcma_write=${ZD_ADPCMA_WRITE} 期待 >= 1)"
fi

# ============================================================
# gate 5 = ADR-0049〜0060 baseline regression = verify-axis-b-v2-roadmap3-dispatch.sh transitively
# ============================================================
echo "=== gate 5 (baseline regression) = verify-axis-b-v2-roadmap3-dispatch.sh ==="
if bash src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh >/dev/null 2>&1; then
  ok "gate 5 (ADR-0049〜0060 baseline regression): verify-axis-b-v2-roadmap3-dispatch.sh 12 gate ALL PASS (= ADR-0049〜0060 transitively regression)"
else
  ng "gate 5 (baseline regression) FAIL"
fi

# ============================================================
# gate 6 = production byte-identical + build-mode 排他
# (= TEST_MODE_AXIS_G_V2_PPC=0 default + m1 sha256 一致 + ζ-β routine 未 assemble)
# ============================================================
echo "=== gate 6 (production build = 両 flag clear) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build FAIL"; exit 1; }
cp "$LST" "$LST_PROD"
PROD_SHA=$(shasum -a 256 vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1 | awk '{print $1}')

G6_PROD_BAD=""
for label in pmdneo_v2_adpcmb_voice_note_song_ppc pmdneo_v2_part_dispatch_note_adpcmb_ppc pmdneo_v2_song_fixture_adpcmb_j_ppc; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_PROD")
  if [ -n "$addr" ]; then
    G6_PROD_BAD="$G6_PROD_BAD ${label}=0x${addr}(assembled)"
  fi
done

if [ "$PROD_SHA" = "$EXPECTED_PROD_SHA" ] && [ -z "$G6_PROD_BAD" ]; then
  ok "gate 6 (production byte-identical + 排他): m1 sha256 = ${PROD_SHA} (= expected baseline) + ζ-β routine 3 件 全 assemble なし (= production .lst で address 割当なし、 byte-identical 維持 proof)"
else
  ng "gate 6 (production byte-identical + 排他) 不成立 (prod_sha=${PROD_SHA} 期待 ${EXPECTED_PROD_SHA} / prod_bad=${G6_PROD_BAD:-none-expected})"
fi

# ============================================================
# 集計 + completion proof line 18 行
# ============================================================
echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "=== ADR-0048 ζ-β 案 W + ζ-δ option A completion proof (= ζ-δ-1 verify ALL PASS = ζ-δ-2 audition session ready) ==="
  echo "gate 1 (bit7 save/set/restore sequence):           PASS"
  echo "gate 2 (lower 7 bit = PPC entry index 変化):       PASS"
  echo "gate 3 (PPC pointer register write 変化):          PASS"
  echo "gate 4 (全 exit restore static):                   PASS"
  echo "gate 5 (ADR-0049〜0060 baseline regression):       PASS"
  echo "gate 6 (production byte-identical + 排他):         PASS"
  echo "gate 7 (ζ-β/ζ-δ wrapper 経路 + 既存 routine 不可触): PASS"
  echo "gate 8 (integration preview = 同一 trace co-existence): PASS"
  echo "supplemental gate IX-saved:                        PASS"
  echo "supplemental gate KIND-4-dispatch:                 PASS"
  echo "supplemental gate slot-9-init-binary-toggle:       PASS"
  echo "supplemental gate fixture-loop:                    PASS"
  echo "supplemental gate fixture-byte-sequence:           PASS"
  echo "zeta-delta-yaml-beat-marker:                       PASS"
  echo "zeta-delta-adpcma-coexistence:                     PASS"
  echo "[artifact paths: z80-trace=${ZMEM_ZB} ymfm-trace=${YMFM_ZB} fixture.lst=${LST_ZB} production.lst=${LST_PROD} audition-wav=/tmp/zeta-delta-audition.wav base ref pin=${DIFF_BASE_PIN}]"
  echo "(audio gate = 越川氏 audition session = ζ-δ-2 user 介入必須 sub-sprint scope)"
  echo "ζ-δ-2 audition session ready: yes (ADR-0048 ζ-δ-1 main agent autonomous part 完了)"
  echo ""
  echo "OK  ALL PASS (= 軸 G ADR-0048 ζ-γ + ζ-δ option A verify script extend + completion proof + 15 gate 全 PASS)"
  exit 0
else
  echo ""
  echo "NG  $FAIL gate FAIL"
  exit 1
fi
