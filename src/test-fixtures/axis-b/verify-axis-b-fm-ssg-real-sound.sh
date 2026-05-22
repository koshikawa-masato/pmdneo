#!/usr/bin/env bash
#
# PMDNEO 軸 B production-ready roadmap ① γ verify gate (= ADR-0057 FM/SSG 実音)
#
# verify scope: ADR-0057 §決定 7 の verify gate 6 件を再現可能な verify script に
#   体系化する。 sub-sprint β (= PR #93) で実音化した v2 FM/SSG dispatcher
#   (= pmdneo_v2_fm_dispatch / pmdneo_v2_ssg_dispatch) が trace-proof stub から
#   実音 register write へ昇格したことを gate 1-6 で検証。 driver 改修なし。
#
#   --- 実音 call chain gate (= production .lst 静的) ---
#   gate 1: FM 実音 proof       — pmdneo_v2_fm_dispatch → pmdneo_v2_fm_voice_note
#                                 → pmdneo_fm_voice_set + fnumset_fm + fm_keyon を
#                                 call (静的) + V2 fixture trace で FM fnum
#                                 (reg 0xA0系) 実音 register write 存在
#   gate 2: SSG 実音 proof      — pmdneo_v2_ssg_dispatch → pmdneo_v2_ssg_voice_note
#                                 → fnumset_ssg + ssg_keyon + pmdneo_ssg_tone_sync
#                                 を call (静的) + V2 fixture trace で SSG tone
#                                 period (reg 0x00-0x05) + volume 0x0F 実音 write
#   gate 3: reg 0x07 契約準拠   — pmdneo_v2_ssg_voice_note が pmdneo_ssg_tone_sync
#                                 を call + ym2610_write_port を直接 call しない
#                                 (= reg 0x07 直接 write なし、 ADR-0051 §決定 4)
#   --- dynamic / static gate ---
#   gate 4: chip target 分岐維持 — V2 fixture trace 両 chip で FM keyon (reg 0x28、
#                                 ym2610 4 = F1/F2/F5/F6 / ym2610b 6) + reg 0x07
#                                 tone-enable write + entry marker 0xFD3B <- 0x07
#   gate 6: .org overflow       — v2 並設 routine 9 件 >= 0x0610 + 0x0066 セクション
#                                 max addr < 0x0100
#   gate 5: baseline regression — verify-axis-b-axis-connection.sh 6 gate (= 内部で
#                                 verify-axis-b-f2b-integration / sram-placement /
#                                 v2-entry + verify-fadeout / mute / ssg-tone-enable
#                                 を transitively = ADR-0049〜0056 regression)
#
# 注: 実音化は既存実音 routine 本体 call (= ADR-0057 §決定 2/3)。 検証は register /
#   z80-mem trace primary gate。 実 MML song parse は roadmap ② = 本 verify は
#   固定 note (= C4/E4/G4) の v2 dispatcher 実音 register write を gate する。
#
# fixture: TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml、 両 chip。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-fm-ssg-real-sound.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_2610="/tmp/fmssg-ym2610-ymfm.tsv"
ZMEM_2610="/tmp/fmssg-ym2610-zmem.tsv"
YMFM_2610B="/tmp/fmssg-ym2610b-ymfm.tsv"
ZMEM_2610B="/tmp/fmssg-ym2610b-zmem.tsv"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# seg_calls <label> <callee> : label routine body (= label 行 〜 最初の ret) が
#   call <callee> を含めば "ok"。 seg 境界は ret (= routine 末尾) で判定する
#   (= 内部 _loop: / _next: label でセグメントを打ち切らない)。
seg_calls() {
  awk -v l="$1" -v c="$2" '
    $0 ~ ("[ \t]" l ":"){seg=1}
    seg && $0 ~ ("call[ \t]+" c "([ \t]|$)"){found=1}
    seg && /[ \t]ret([ \t]|$)/{seg=0}
    END{if(found)print "ok"}
  ' "$LST"
}

# ============================================================
# production build (= ym2610 default) — gate 1/2/3 静的 / gate 6
# ============================================================
echo "=== production build (= ym2610 default) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "❌ .lst 未生成"; exit 1; }

# --- gate 1 静的部: FM 実音 call chain ---
FM_D2N=$(seg_calls pmdneo_v2_fm_dispatch pmdneo_v2_fm_voice_note)
FM_VOICE=$(seg_calls pmdneo_v2_fm_voice_note pmdneo_fm_voice_set)
FM_FNUM=$(seg_calls pmdneo_v2_fm_voice_note fnumset_fm)
FM_KEYON=$(seg_calls pmdneo_v2_fm_voice_note fm_keyon)

# --- gate 2 静的部: SSG 実音 call chain ---
SSG_D2N=$(seg_calls pmdneo_v2_ssg_dispatch pmdneo_v2_ssg_voice_note)
SSG_TONE=$(seg_calls pmdneo_v2_ssg_voice_note fnumset_ssg)
SSG_VOL=$(seg_calls pmdneo_v2_ssg_voice_note ssg_keyon)
SSG_SYNC=$(seg_calls pmdneo_v2_ssg_voice_note pmdneo_ssg_tone_sync)

# --- gate 3: reg 0x07 契約 = ssg_voice_note は ym2610_write_port を直接 call しない ---
SSG_DIRECT_A=$(seg_calls pmdneo_v2_ssg_voice_note ym2610_write_port_a)
SSG_DIRECT_B=$(seg_calls pmdneo_v2_ssg_voice_note ym2610_write_port_b)

# --- gate 6: .org overflow ---
G6BAD=0
G6DET=""
for label in nmi_cmd_7_play_song_v2 pmdneo_v2_entry_skeleton pmdneo_v2_fm_dispatch pmdneo_v2_fm_voice_note pmdneo_v2_ssg_dispatch pmdneo_v2_ssg_voice_note pmdneo_v2_fm3ext_dispatch pmdneo_v2_adpcmb_dispatch pmdneo_v2_rhythm_dispatch; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":"){print $1; exit}' "$LST")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G6BAD=$((G6BAD + 1)); G6DET="$G6DET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST" | sort | tail -1)
if [ "$G6BAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "gate 6: v2 並設 routine 9 件全 >= 0x0610 + 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow / overlap なし)"
else
  ng "gate 6: .org overflow (routine_bad=${G6BAD} max0066=0x${MAX0066:-NONE}${G6DET})"
fi

# ============================================================
# V2 fixture build (= ym2610) + MAME headless trace
# ============================================================
echo "=== V2 fixture build (= ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "❌ V2 fixture (ym2610) build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成 (ym2610)"; exit 1; }
[ -f "$ZMEM" ] || { echo "❌ z80-mem-trace 未生成 (ym2610)"; exit 1; }
cp "$YMFM" "$YMFM_2610"
cp "$ZMEM" "$ZMEM_2610"

# fnum reg = port A 0xA0系 (= "A1" 等) + port B 0xA0系 (= ymfm-trace は port B を
# "1" prefix で記録 = "1A1" 等)。 両 port を /^1?A[0-9A-F]$/ で count。
FNUM_2610=$(awk -F'\t' '$3 ~ /^1?A[0-9A-F]$/' "$YMFM_2610" | wc -l | tr -d ' ')
TONE_2610=$(awk -F'\t' '$2=="A" && $3 ~ /^0[0-5]$/' "$YMFM_2610" | wc -l | tr -d ' ')
VOL_2610=$(awk -F'\t' '$2=="A" && $3 ~ /^0[89A]$/ && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')
M07_2610=$(awk -F'\t' '$2=="A" && $3=="07"' "$YMFM_2610" | wc -l | tr -d ' ')
KEYON_2610=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610" | wc -l | tr -d ' ')
MARK_2610=$(awk -F'\t' '$3=="FD3B" && $4=="07"' "$ZMEM_2610" | wc -l | tr -d ' ')

# ============================================================
# V2 fixture build (= ym2610b) + MAME headless trace
# ============================================================
echo "=== V2 fixture build (= ym2610b) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610b >/dev/null 2>&1 \
  || { echo "❌ V2 fixture (ym2610b) build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成 (ym2610b)"; exit 1; }
[ -f "$ZMEM" ] || { echo "❌ z80-mem-trace 未生成 (ym2610b)"; exit 1; }
cp "$YMFM" "$YMFM_2610B"
cp "$ZMEM" "$ZMEM_2610B"

FNUM_2610B=$(awk -F'\t' '$3 ~ /^1?A[0-9A-F]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
TONE_2610B=$(awk -F'\t' '$2=="A" && $3 ~ /^0[0-5]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
VOL_2610B=$(awk -F'\t' '$2=="A" && $3 ~ /^0[89A]$/ && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')
M07_2610B=$(awk -F'\t' '$2=="A" && $3=="07"' "$YMFM_2610B" | wc -l | tr -d ' ')
KEYON_2610B=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
MARK_2610B=$(awk -F'\t' '$3=="FD3B" && $4=="07"' "$ZMEM_2610B" | wc -l | tr -d ' ')

# ============================================================
# gate 判定
# ============================================================

# --- gate 1: FM 実音 proof = call chain (静的) + fnum write (動的) ---
# v2 FM dispatcher は固定 note で per ch fnumset_fm を call = ym2610 4ch / ym2610b 6ch、
# 各 fnumset_fm = 0xA4系 + 0xA0系 の 2 write。 期待 = ym2610 8 / ym2610b 12。
if [ "$FM_D2N" = "ok" ] && [ "$FM_VOICE" = "ok" ] && [ "$FM_FNUM" = "ok" ] && [ "$FM_KEYON" = "ok" ] \
   && [ "$FNUM_2610" -eq 8 ] && [ "$FNUM_2610B" -eq 12 ]; then
  ok "gate 1: FM 実音 proof = pmdneo_v2_fm_dispatch → fm_voice_note → pmdneo_fm_voice_set + fnumset_fm + fm_keyon (静的) + V2 fixture trace で FM fnum (reg 0xA0系) write ym2610 ${FNUM_2610} (= 4ch x 2) / ym2610b ${FNUM_2610B} (= 6ch x 2)"
else
  ng "gate 1: FM 実音 proof 不成立 (call chain d2n=${FM_D2N} voice=${FM_VOICE} fnum=${FM_FNUM} keyon=${FM_KEYON} / fnum write ym2610=${FNUM_2610} 期待 8 / ym2610b=${FNUM_2610B} 期待 12)"
fi

# --- gate 2: SSG 実音 proof = call chain (静的) + tone period/volume write (動的) ---
# v2 SSG dispatcher は per ch fnumset_ssg を call = 3ch、 各 2 write = tone period >= 6。
# volume 0x0F は v2 dispatcher のみ (= song は V0)、 各 ch 1 = 3。
if [ "$SSG_D2N" = "ok" ] && [ "$SSG_TONE" = "ok" ] && [ "$SSG_VOL" = "ok" ] && [ "$SSG_SYNC" = "ok" ] \
   && [ "$TONE_2610" -ge 6 ] && [ "$TONE_2610B" -ge 6 ] \
   && [ "$VOL_2610" -eq 3 ] && [ "$VOL_2610B" -eq 3 ]; then
  ok "gate 2: SSG 実音 proof = pmdneo_v2_ssg_dispatch → ssg_voice_note → fnumset_ssg + ssg_keyon + pmdneo_ssg_tone_sync (静的) + V2 fixture trace で SSG tone period (reg 0x00-0x05) write ym2610 ${TONE_2610} / ym2610b ${TONE_2610B} (>= 6) + volume 0x0F ym2610 ${VOL_2610} / ym2610b ${VOL_2610B} (= 各 3)"
else
  ng "gate 2: SSG 実音 proof 不成立 (call chain d2n=${SSG_D2N} tone=${SSG_TONE} vol=${SSG_VOL} sync=${SSG_SYNC} / tone period ym2610=${TONE_2610} ym2610b=${TONE_2610B} 期待 >= 6 / volume 0x0F ym2610=${VOL_2610} ym2610b=${VOL_2610B} 期待 各 3)"
fi

# --- gate 3: reg 0x07 契約準拠 ---
# pmdneo_v2_ssg_voice_note は pmdneo_ssg_tone_sync を call し、 ym2610_write_port を
# 直接 call しない (= reg 0x07 直接 write なし、 ADR-0051 §決定 4 RMW owner 経由のみ)。
if [ "$SSG_SYNC" = "ok" ] && [ -z "$SSG_DIRECT_A" ] && [ -z "$SSG_DIRECT_B" ] \
   && [ "$M07_2610" -ge 1 ] && [ "$M07_2610B" -ge 1 ]; then
  ok "gate 3: reg 0x07 契約準拠 = pmdneo_v2_ssg_voice_note が pmdneo_ssg_tone_sync を call + ym2610_write_port 直接 call なし (= reg 0x07 直接 write なし、 ADR-0051 §決定 4) + V2 trace で reg 0x07 write ym2610 ${M07_2610} / ym2610b ${M07_2610B}"
else
  ng "gate 3: reg 0x07 契約違反 (sync=${SSG_SYNC} direct_a=${SSG_DIRECT_A:-none} direct_b=${SSG_DIRECT_B:-none} m07 ym2610=${M07_2610} ym2610b=${M07_2610B})"
fi

# --- gate 4: chip target 分岐維持 + entry marker ---
if [ "$KEYON_2610" -eq 4 ] && [ "$KEYON_2610B" -eq 6 ] \
   && [ "$MARK_2610" -ge 1 ] && [ "$MARK_2610B" -ge 1 ]; then
  ok "gate 4: chip target 分岐維持 = FM keyon (reg 0x28 F-prefix) ym2610 ${KEYON_2610} (= A/D skip、 B/C/E/F) / ym2610b ${KEYON_2610B} (= 全 6ch) + entry marker 0xFD3B <- 0x07 ym2610 ${MARK_2610} / ym2610b ${MARK_2610B}"
else
  ng "gate 4: chip 分岐 or marker 不一致 (FM keyon ym2610=${KEYON_2610} 期待 4 / ym2610b=${KEYON_2610B} 期待 6 / marker ym2610=${MARK_2610} ym2610b=${MARK_2610B})"
fi

# ============================================================
# gate 5: baseline regression
# ============================================================
echo "=== gate 5: baseline regression (= verify-axis-b-axis-connection.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-axis-connection.sh >/dev/null 2>&1; then
  ok "gate 5: baseline regression = verify-axis-b-axis-connection.sh 6 gate 全 PASS (= 内部で verify-axis-b-f2b-integration / sram-placement / v2-entry + verify-fadeout / mute / ssg-tone-enable + baseline 9 script を transitively = ADR-0049〜0056 regression)"
else
  ng "gate 5: baseline regression FAIL"
fi

# ============================================================
# production build 復帰 + 集計
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了 (= ym2610 default)"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ ALL PASS (= 軸 B production-ready roadmap ① = FM/SSG 実音 6 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
