#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 7 γ verify gate (= ADR-0051 SSG tone-enable semantics)
#
# verify scope: β (= PR #67) で実装した SSG tone-enable on-demand 挙動を再現可能な
#   15 gate verify script に体系化する。 gate 1-12 = γ (= PR #68)、 gate 13-15 =
#   ADR-0051 Annex D-3 follow-up (= V0 SSG keyon literal trace gate)。 driver 改修なし。
#
#   --- trace gate (= MAME register trace、 fade-free tone-ladder build) ---
#   gate 1: SSG tone period write       — G/H/I note dispatch で reg 0x00-0x05 write
#   gate 2: SSG volume write            — G/H/I で reg 0x08-0x0A write
#   gate 3: mixer tone enable           — reg 0x07 が G 0x3E / H 0x3D / I 0x3B
#   gate 4: mixer tone disable 復帰      — note 後 reg 0x07 が 0x3F へ復帰
#   gate 5: noise bit 不変               — reg 0x07 全 write で noise bit (3-5) set
#   gate 6: shadow 整合                  — reg 0x07 distinct 値が {3B,3D,3E,3F} のみ
#   gate 7: leading-rest non-enable      — V15 (V>0) が premature tone enable しない
#                                          (= 最初の SSG note より前に reg 0x07 enable なし)
#   gate 8: SSG tone period ascending   — G > H > I の tone period (= g4<a4<b4 周波数)
#   gate 9: FM 回帰                       — FM B/C/E/F keyon (reg 0x28 = F1/F2/F5/F6) 全発火
#   --- build / listing gate ---
#   gate 10: ADR-0049 mute regression   — verify-mute-semantics.sh 7 gate + baseline 9 script
#   gate 11: ADR-0050 fade regression   — default build に cmd 6 + fade routine 存在 (= fade audition 不破壊)
#   gate 12: .org overflow / overlap    — pmdneo_ssg_tone_sync が 0x0610 セクション、 section overlap なし
#   --- V0 SSG keyon trace gate (= ADR-0051 Annex D-3 follow-up、 ssg-v0-keyon.mml) ---
#   gate 13: V0 keyon dispatch          — V0 SSG note が keyon dispatch (reg 0x00-0x05 write)
#   gate 14: V0 volume = 0              — SSG volume reg 0x08-0x0A 全 write 0x00
#   gate 15: V0 keyon non-enable        — mixer reg 0x07 全 write 0x3F (= tone bit enable なし)
#
# 注: ADR-0051 §決定 5 本来の「V0 SSG keyon で tone enable しない」 の literal trace
#   gate は、 test-tone-ladder.mml に V0 SSG keyon が無いため γ では gate 7 を trace
#   観測可能な leading-rest non-enable に rename した。 literal な V0 keyon trace gate
#   (= gate 13-15) は専用 fixture ssg-v0-keyon.mml で ADR-0051 Annex D-3 follow-up
#   として追加し、 §決定 5 本来の V0 keyon non-enable 検証を closed にした。
#
# fixture: PMDNEO_NO_FADE=1 + test-tone-ladder.mml (= gate 1-9、 PR #65/#67) +
#   PMDNEO_NO_FADE=1 + ssg-v0-keyon.mml (= gate 13-15、 V0 keyon follow-up)。
#
# usage: bash src/test-fixtures/axis-b/verify-ssg-tone-enable.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
MAIN_O="$TEMPLATE_BUILD/main.o"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# production build (= default、 PMDNEO_NO_FADE 未指定)
# ============================================================
echo "=== production build (= default、 PMDNEO_NO_FADE 未指定) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }

# --- gate 12: .org overflow / section overlap ---
# pmdneo_ssg_tone_sync (= γ で検証する β 新規 routine) が .org 制約のない 0x0610
# セクション (>= 0x0610) に配置されること + 0x0100 セクション (= nmi handler) が
# .org 0x0200 と overlap しないこと。
TONE_ADDR=$(awk '/[ \t]pmdneo_ssg_tone_sync:/{print $1; exit}' "$LST")
UNMASK_ADDR=$(awk '/[ \t]nmi_cmd_unmask_part:/{print $1; exit}' "$LST")
WPA_ADDR=$(awk '/[ \t]ym2610_write_port_a:/{print $1; exit}' "$LST")
if [ -n "$TONE_ADDR" ] && [ -n "$UNMASK_ADDR" ] && [ -n "$WPA_ADDR" ] \
   && [ "$(hex "$TONE_ADDR")" -ge "$(hex 0610)" ] \
   && [ "$(hex "$UNMASK_ADDR")" -lt "$(hex "$WPA_ADDR")" ]; then
  ok "gate 12: pmdneo_ssg_tone_sync(0x$TONE_ADDR) >= 0x0610 + nmi_cmd_unmask_part(0x$UNMASK_ADDR) < .org 0x$WPA_ADDR = overlap なし"
else
  ng "gate 12: .org overlap risk (tone_sync=0x$TONE_ADDR unmask=0x$UNMASK_ADDR wpa=0x$WPA_ADDR)"
fi

# --- gate 11: ADR-0050 fade regression (= default fade audition 不破壊) ---
# default build (= PMDNEO_NO_FADE 未指定) で 68k main.o に cmd 6 (= REG_SOUND=6 fade
# trigger) が残り、 driver に fade routine が存在 = SSG β が fade 経路を壊していない。
CMD6=$(m68k-neogeo-elf-objdump -d "$MAIN_O" 2>/dev/null | grep -cE 'moveb #6,320000' || true)
FADEBEGIN=$(awk '/[ \t]pmdneo_fade_begin:/{print "ok"; exit}' "$LST")
FADETICK=$(awk '/[ \t]pmdneo_v2_fade_tick:/{print "ok"; exit}' "$LST")
if [ "${CMD6:-0}" -ge 1 ] && [ "$FADEBEGIN" = "ok" ] && [ "$FADETICK" = "ok" ]; then
  ok "gate 11: ADR-0050 fade regression なし (= default build に cmd 6 + fade routine 存在)"
else
  ng "gate 11: fade 経路 regression (cmd6=$CMD6 fade_begin=$FADEBEGIN fade_tick=$FADETICK)"
fi

# --- gate 10: ADR-0049 mute regression (+ baseline 9 script) ---
echo "=== gate 10: mute + baseline regression (= verify-mute-semantics.sh) ==="
if bash src/test-fixtures/axis-b/verify-mute-semantics.sh >/dev/null 2>&1; then
  ok "gate 10: ADR-0049 mute regression + baseline 9 script 全 PASS"
else
  ng "gate 10: mute / baseline regression FAIL"
fi

# ============================================================
# fade-free tone-ladder build (= PMDNEO_NO_FADE=1 + test-tone-ladder.mml) + MAME trace
# ============================================================
echo "=== fade-free tone-ladder build (= PMDNEO_NO_FADE=1) + MAME headless trace ==="
rm -f "$PREPROCESSED"
PMDNEO_NO_FADE=1 MML_INPUTS=test-tone-ladder.mml bash scripts/build-poc.sh >/dev/null 2>&1 \
  || { echo "❌ tone-ladder build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 80 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成"; exit 1; }

# --- gate 1: SSG tone period write (reg 0x00-0x05) ---
TP=$(awk -F'\t' '$2=="A" && $3~/^0[0-5]$/' "$YMFM" | wc -l | tr -d ' ')
if [ "$TP" -ge 6 ]; then
  ok "gate 1: SSG tone period write (reg 0x00-0x05) $TP 件 (= G/H/I note dispatch 成立)"
else
  ng "gate 1: SSG tone period write 不足 ($TP)"
fi

# --- gate 2: SSG volume write (reg 0x08-0x0A) ---
VW=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A")' "$YMFM" | wc -l | tr -d ' ')
if [ "$VW" -ge 3 ]; then
  ok "gate 2: SSG volume write (reg 0x08-0x0A) $VW 件"
else
  ng "gate 2: SSG volume write 不足 ($VW)"
fi

# --- gate 3: mixer tone enable (reg 0x07 = G 0x3E / H 0x3D / I 0x3B) ---
G3E=$(awk -F'\t' '$2=="A" && $3=="07" && $4=="3E"' "$YMFM" | wc -l | tr -d ' ')
H3D=$(awk -F'\t' '$2=="A" && $3=="07" && $4=="3D"' "$YMFM" | wc -l | tr -d ' ')
I3B=$(awk -F'\t' '$2=="A" && $3=="07" && $4=="3B"' "$YMFM" | wc -l | tr -d ' ')
if [ "$G3E" -ge 1 ] && [ "$H3D" -ge 1 ] && [ "$I3B" -ge 1 ]; then
  ok "gate 3: mixer tone enable G=0x3E($G3E) / H=0x3D($H3D) / I=0x3B($I3B)"
else
  ng "gate 3: mixer tone enable 不足 (G3E=$G3E H3D=$H3D I3B=$I3B)"
fi

# --- gate 4: mixer tone disable 復帰 (reg 0x07 = 0x3F) ---
R3F=$(awk -F'\t' '$2=="A" && $3=="07" && $4=="3F"' "$YMFM" | wc -l | tr -d ' ')
if [ "$R3F" -ge 3 ]; then
  ok "gate 4: mixer tone disable 復帰 = reg 0x07 0x3F $R3F 件 (= note 後 disable)"
else
  ng "gate 4: 0x3F 復帰 不足 ($R3F)"
fi

# --- gate 5: noise bit 不変 (reg 0x07 全 write で bit 3-5 set) ---
# reg 0x07 byte の bit 3-5 (= noise A/B/C) が set = 値が 3[89A-F] (= high nibble 3、
# low nibble 8-F)。 noise bit が cleared な write が 1 件もないこと。
BADNOISE=$(awk -F'\t' '$2=="A" && $3=="07" && $4!~/^3[89A-F]$/' "$YMFM" | wc -l | tr -d ' ')
if [ "$BADNOISE" -eq 0 ]; then
  ok "gate 5: noise bit 不変 = reg 0x07 全 write で noise bit (3-5) set"
else
  ng "gate 5: noise bit cleared な reg 0x07 write $BADNOISE 件"
fi

# --- gate 6: shadow 整合 (reg 0x07 distinct 値が {3B,3D,3E,3F} のみ) ---
DISTINCT=$(awk -F'\t' '$2=="A" && $3=="07"{print $4}' "$YMFM" | sort -u | tr '\n' ' ')
BAD6=$(awk -F'\t' '$2=="A" && $3=="07" && $4!~/^3[BDEF]$/' "$YMFM" | wc -l | tr -d ' ')
if [ "$BAD6" -eq 0 ]; then
  ok "gate 6: shadow 整合 = reg 0x07 distinct {$DISTINCT}⊆ {3B,3D,3E,3F} (= 単一 tone bit 操作、 他 ch 非破壊)"
else
  ng "gate 6: reg 0x07 に想定外値 $BAD6 件 (distinct = {$DISTINCT})"
fi

# --- gate 7: leading-rest non-enable (V15 が premature tone enable しない) ---
# G/H/I の leading rest 区間 (= 最初の SSG note dispatch より前、 V15 は part 先頭で
# dispatch 済) で reg 0x07 が 0x3F のまま = V15 (V>0) が premature に tone enable
# しない。 最初の SSG tone period write (reg 0x00-0x05) より前に reg 0x07 の
# 非 0x3F (= tone enable) write が 1 件もないことを確認。
# 注: tone enable value (0x3E/3D/3B) の write 件数自体は note 数と一致しない。
# pmdneo_ssg_tone_sync は reg 0x07 を無条件 write するため、 ある ch が enable 中に
# 別 ch の rest-keyoff (= disable、 既 disabled で no-op) が現 shadow 値を再 write
# する (= 無害な冗長 write)。 premature enable の判定は leading rest 区間の値で行う。
FIRST_TP=$(awk -F'\t' '$2=="A" && $3~/^0[0-5]$/{print $1; exit}' "$YMFM")
if [ -n "$FIRST_TP" ]; then
  PREMATURE=$(awk -F'\t' -v lim="$FIRST_TP" '$2=="A" && $3=="07" && $1+0<lim+0 && $4!="3F"' "$YMFM" | wc -l | tr -d ' ')
  if [ "$PREMATURE" -eq 0 ]; then
    ok "gate 7: leading-rest non-enable = 最初の SSG note (idx $FIRST_TP) より前の reg 0x07 は全 0x3F (= V15 premature enable なし)"
  else
    ng "gate 7: leading-rest 区間に reg 0x07 enable write $PREMATURE 件 (= premature enable 疑い)"
  fi
else
  ng "gate 7: SSG tone period write 未検出"
fi

# --- gate 8: SSG tone period ascending (G > H > I) ---
# G = reg 0x00(lo)/0x01(hi)、 H = 0x02/0x03、 I = 0x04/0x05。 note period (= lo/hi の
# 最大値、 init 0 より大) で 16-bit period を組み、 G > H > I (= g4<a4<b4 の周波数) を確認。
g_lo=$(awk -F'\t' '$2=="A" && $3=="00"{print $4}' "$YMFM" | sort -u | tail -1)
g_hi=$(awk -F'\t' '$2=="A" && $3=="01"{print $4}' "$YMFM" | sort -u | tail -1)
h_lo=$(awk -F'\t' '$2=="A" && $3=="02"{print $4}' "$YMFM" | sort -u | tail -1)
h_hi=$(awk -F'\t' '$2=="A" && $3=="03"{print $4}' "$YMFM" | sort -u | tail -1)
i_lo=$(awk -F'\t' '$2=="A" && $3=="04"{print $4}' "$YMFM" | sort -u | tail -1)
i_hi=$(awk -F'\t' '$2=="A" && $3=="05"{print $4}' "$YMFM" | sort -u | tail -1)
if [ -n "$g_lo" ] && [ -n "$h_lo" ] && [ -n "$i_lo" ]; then
  g_period=$(( $(hex "${g_hi:-0}") * 256 + $(hex "$g_lo") ))
  h_period=$(( $(hex "${h_hi:-0}") * 256 + $(hex "$h_lo") ))
  i_period=$(( $(hex "${i_hi:-0}") * 256 + $(hex "$i_lo") ))
  if [ "$g_period" -gt "$h_period" ] && [ "$h_period" -gt "$i_period" ]; then
    ok "gate 8: SSG tone period ascending G($g_period) > H($h_period) > I($i_period) (= g4<a4<b4 周波数)"
  else
    ng "gate 8: SSG tone period 非 ascending (G=$g_period H=$h_period I=$i_period)"
  fi
else
  ng "gate 8: SSG tone period 未検出 (g_lo=$g_lo h_lo=$h_lo i_lo=$i_lo)"
fi

# --- gate 9: FM 回帰 (FM B/C/E/F keyon = reg 0x28 F1/F2/F5/F6) ---
FMKEYON=$(awk -F'\t' '$2=="A" && $3=="28" && ($4=="F1"||$4=="F2"||$4=="F5"||$4=="F6")' "$YMFM" | wc -l | tr -d ' ')
if [ "$FMKEYON" -ge 8 ]; then
  ok "gate 9: FM 回帰 = FM B/C/E/F keyon (reg 0x28 = F1/F2/F5/F6) $FMKEYON 件"
else
  ng "gate 9: FM keyon 不足 ($FMKEYON、 期待 >= 8 = B/C/E/F x2)"
fi

# ============================================================
# V0 SSG keyon build (= PMDNEO_NO_FADE=1 + ssg-v0-keyon.mml) + MAME trace
#   ADR-0051 Annex D-3 follow-up = V0 SSG keyon literal trace gate。
#   SSG G/H/I を V0 で keyon = note dispatch するが volume 0、 tone bit は enable しない。
# ============================================================
echo "=== V0 SSG keyon build (= PMDNEO_NO_FADE=1 + ssg-v0-keyon.mml) + MAME headless trace ==="
rm -f "$PREPROCESSED"
PMDNEO_NO_FADE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh >/dev/null 2>&1 \
  || { echo "❌ V0 SSG keyon build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成"; exit 1; }

# --- gate 13: V0 SSG keyon dispatch (= tone period write 発生) ---
# V0 でも SSG note は keyon として dispatch される (= reg 0x00-0x05 に tone period write)。
V0TP=$(awk -F'\t' '$2=="A" && $3~/^0[0-5]$/' "$YMFM" | wc -l | tr -d ' ')
if [ "$V0TP" -ge 6 ]; then
  ok "gate 13: V0 keyon dispatch = SSG tone period write (reg 0x00-0x05) $V0TP 件 (= V0 でも G/H/I note keyon 成立)"
else
  ng "gate 13: V0 SSG tone period write 不足 (${V0TP}, 期待 >= 6)"
fi

# --- gate 14: V0 volume = 0 (= reg 0x08-0x0A 全 write 0x00) ---
V0VOL_TOTAL=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A")' "$YMFM" | wc -l | tr -d ' ')
V0VOL_BAD=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4!="00"' "$YMFM" | wc -l | tr -d ' ')
if [ "$V0VOL_TOTAL" -ge 3 ] && [ "$V0VOL_BAD" -eq 0 ]; then
  ok "gate 14: V0 volume = 0 = SSG volume reg 0x08-0x0A 全 write 0x00 ($V0VOL_TOTAL 件)"
else
  ng "gate 14: V0 SSG volume に非 0x00 write (total=$V0VOL_TOTAL non-00=$V0VOL_BAD)"
fi

# --- gate 15: V0 keyon non-enable (= mixer reg 0x07 全 write 0x3F) ---
# V0 keyon = pmdneo_psg_keyon が tone_sync(A=0) を call = tone bit を enable しない。
# reg 0x07 の全 write が 0x3F (= 全 tone+noise disable) のまま = tone bit enable なし
# (= ADR-0051 §決定 5 本来の V0 keyon non-enable literal trace 証跡)。
V0R07_TOTAL=$(awk -F'\t' '$2=="A" && $3=="07"' "$YMFM" | wc -l | tr -d ' ')
V0R07_BAD=$(awk -F'\t' '$2=="A" && $3=="07" && $4!="3F"' "$YMFM" | wc -l | tr -d ' ')
if [ "$V0R07_TOTAL" -ge 1 ] && [ "$V0R07_BAD" -eq 0 ]; then
  ok "gate 15: V0 keyon non-enable = mixer reg 0x07 全 write 0x3F ($V0R07_TOTAL 件、 = tone bit enable なし)"
else
  ng "gate 15: V0 SSG keyon で reg 0x07 に tone enable write (total=$V0R07_TOTAL non-3F=$V0R07_BAD)"
fi

# ============================================================
# production build 復帰 + 集計
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了 (= PMDNEO_NO_FADE 未指定、 default)"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ ALL PASS (= 軸 B sprint 7 SSG tone-enable 15 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
