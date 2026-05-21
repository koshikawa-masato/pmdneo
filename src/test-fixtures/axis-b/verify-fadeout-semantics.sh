#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 6 δ verify gate (= ADR-0050 fade-out semantics)
#
# verify scope: β (= fade decay path、 PR #64) + γ (= fade finish path、 PR #70) で
#   実装した楽曲全体 fade-out 挙動を、 再現可能な 16 gate verify script に体系化する。
#   driver 改修はしない (= δ = verify 整備、 ADR-0050 §決定 1 δ)。
#
# fixture: fade-out verify 専用 fadeout-verify.mml (= FM B/C/E/F + SSG G/H/I V15 を
#   t=0 から長 note で同時鳴動、 ADPCM-A/B/rhythm なし) + PMDNEO_FADE_FIXTURE=1。
#   test-tone-ladder.mml は聴覚診断専用であり fade 検証には流用しない (= staggered
#   構成で SSG が fade window 中に鳴らないため)。
#
# audition 役割 (= δ verify gate には audio gate を含めない、 §決定 6/7 = register
#   trace primary gate):
#   (a) fade fixture build (PMDNEO_FADE_FIXTURE=1) = 本 script の verify gate 用 trace
#   (b) default production build = main.c が cmd 6 を 16 sec 後に送る fade-out audition
#   (c) PMDNEO_NO_FADE=1 build  = cmd 6 抑止 tone-ladder audition (= verify-ssg-tone-enable.sh)
#
# gate 一覧 (= ADR-0050 §決定 7 の 10 gate を完全網羅 + γ/user 追加):
#   gate 1  [§7-1]  fade 開始            — driver_fade_state 0->1 + master/counter/level init
#   gate 2  [§7-2]  fade level 減衰       — pmdneo_v2_fade_level 単調減少 0x40->0x00
#   gate 3  [§7-2]  ADPCM-A master 減衰   — reg 0x01 単調減少 0x3F->0x00
#   gate 4  [§7-2]  FM TL 減衰            — reg 0x42 が faded range で単調増加 (= TL 増 = 音量減)
#   gate 5  [§7-2]  SSG volume 減衰       — reg 0x08-0x0A literal 単調減少 0x0F->0x00
#   gate 6  [§7-2]  ADPCM-B reapply 機構  — reg 0x1B が fade step 毎に write (= 機構 gate、
#                                          fadeout-verify.mml J empty で literal decay 未確認)
#   gate 7  [§7-3]  dispatch fade 適用    — fade 中 SSG dispatch volume write が raw V15 spike なし
#   gate 8  [§7-4]  finish burst 1 回     — fade finish burst が trace 全体で 1 回のみ発火
#   gate 9  [§7-4]  finish 全 chip keyoff — finish burst が FM/SSG/ADPCM-A/ADPCM-B 全 keyoff
#   gate 10 [γ]     SSG finish tone disable — finish 時 mixer reg 0x07 が tone disable (0x3F)
#   gate 11 [§7-5]  register preservation — fade routine の push/pop balance (= stack leak なし)
#   gate 12 [§7-6]  cmd 0x04 不可触        — IRQ.inc snd_command_04_fade_out byte-identical
#   gate 13 [§7-7+8] mute + baseline regression — verify-mute-semantics.sh 7 gate (baseline 9 内包)
#   gate 14 [add]   SSG tone-enable regression — verify-ssg-tone-enable.sh 12 gate
#   gate 15 [§7-9]  .org overflow / fixture isolation — fade routine >= 0x0610 +
#                                          fade fixture call が production build に生成なし
#   gate 16 [§7-10] SRAM placement        — pmdneo_v2_fade_level が free region 内 + prefix 規約
#
# usage: bash src/test-fixtures/axis-b/verify-fadeout-semantics.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
PROD_LST="/tmp/pmdneo-fadeout-prod.lst"
DRIVER="src/driver/standalone_test.s"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"
BASE_REF="origin/wip-pmddotnet-opnb-extension"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# 値列 (= 2 桁大文字 hex、 1 行 1 値) が単調非増加かを判定 (= 0 なら非増加)。
# 2 桁固定幅 hex は辞書順 = 数値順のため、 文字列比較 (v"") で判定する。
mono_noninc() { awk '{v=$1""} NR>1 && v>pp{bad++} {pp=v} END{print bad+0}'; }
# 値列が単調非減少かを判定 (= 0 なら非減少)。
mono_nondec() { awk '{v=$1""} NR>1 && v<pp{bad++} {pp=v} END{print bad+0}'; }

# ============================================================
# production build (= default、 fade fixture 無効) + 静的 gate
# ============================================================
echo "=== production build (= default、 PMDNEO_FADE_FIXTURE 未指定) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }
cp "$LST" "$PROD_LST"

# --- gate 16: SRAM placement (= §決定 7 gate 10) ---
# pmdneo_v2_fade_level が (a) free region 0xFD39-0xFFBF 内、 (b) part_workarea
# (0xF820-0xFD1F) / driver_state (0xF810-0xF81F) / 既存 pmdneo_v2_ssg_mixer と非 overlap、
# (c) pmdneo_v2_ prefix 規約、 (d) legacy WORKAREA.inc drift なし (= 不変)。
FADE_EQU=$(awk '/\.equ[ \t]+pmdneo_v2_fade_level,/{print $3; exit}' "$DRIVER" | tr -d ',')
SSGMIX_EQU=$(awk '/\.equ[ \t]+pmdneo_v2_ssg_mixer,/{print $3; exit}' "$DRIVER" | tr -d ',')
if [ -n "$FADE_EQU" ]; then
  FADE_ADDR=$(hex "${FADE_EQU#0x}")
  G16_RANGE=0; G16_NOOVL=0; G16_WA=0
  { [ "$FADE_ADDR" -ge "$(hex FD39)" ] && [ "$FADE_ADDR" -le "$(hex FFBF)" ]; } && G16_RANGE=1
  { [ "$FADE_ADDR" -gt "$(hex FD1F)" ] && [ "$FADE_ADDR" -gt "$(hex F81F)" ] \
    && [ -n "$SSGMIX_EQU" ] && [ "$FADE_EQU" != "$SSGMIX_EQU" ]; } && G16_NOOVL=1
  if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
    git diff --quiet "$BASE_REF" -- src/driver/WORKAREA.inc && G16_WA=1
  else
    [ -z "$(git status --porcelain src/driver/WORKAREA.inc)" ] && G16_WA=1
  fi
  if [ "$G16_RANGE" -eq 1 ] && [ "$G16_NOOVL" -eq 1 ] && [ "$G16_WA" -eq 1 ]; then
    ok "gate 16: SRAM placement = pmdneo_v2_fade_level ($FADE_EQU) free region 0xFD39-0xFFBF 内 + part_workarea(〜0xFD1F)/driver_state(〜0xF81F)/pmdneo_v2_ssg_mixer($SSGMIX_EQU) と非 overlap + pmdneo_v2_ prefix + WORKAREA.inc drift なし"
  else
    ng "gate 16: SRAM placement 不整合 (range=$G16_RANGE non_overlap=$G16_NOOVL workarea_drift_none=$G16_WA fade=$FADE_EQU ssg_mixer=$SSGMIX_EQU)"
  fi
else
  ng "gate 16: pmdneo_v2_fade_level .equ 未検出"
fi

# --- gate 15: .org overflow / fixture isolation (= §決定 7 gate 9) ---
# (a) fade routine が .org 制約のない 0x0610 セクション (>= 0x0610) + 0x0100 セクション
#     (nmi handler) が .org 0x0200 と overlap しない。
# (b) fade fixture call (= TEST_MODE_FADE_FIXTURE guard の call pmdneo_fade_begin) が
#     production build に生成されない = production .lst の emit された call pmdneo_fade_begin
#     が 1 件のみ (= nmi_cmd_6_fade_start = production trigger のみ、 fixture 分なし)。
FINISH_ADDR=$(awk '/[ \t]pmdneo_fade_finish_silence:/{print $1; exit}' "$PROD_LST")
UNMASK_ADDR=$(awk '/[ \t]nmi_cmd_unmask_part:/{print $1; exit}' "$PROD_LST")
WPA_ADDR=$(awk '/[ \t]ym2610_write_port_a:/{print $1; exit}' "$PROD_LST")
PROD_FADEBEGIN_CALL=$(grep -cE '^[ \t]+[0-9A-F]{6} CD .*call[ \t]+pmdneo_fade_begin' "$PROD_LST" || true)
if [ -n "$FINISH_ADDR" ] && [ -n "$UNMASK_ADDR" ] && [ -n "$WPA_ADDR" ] \
   && [ "$(hex "$FINISH_ADDR")" -ge "$(hex 0610)" ] \
   && [ "$(hex "$UNMASK_ADDR")" -lt "$(hex "$WPA_ADDR")" ] \
   && [ "${PROD_FADEBEGIN_CALL:-0}" -eq 1 ]; then
  ok "gate 15: .org overflow なし (pmdneo_fade_finish_silence=0x$FINISH_ADDR >= 0x0610、 nmi_cmd_unmask_part=0x$UNMASK_ADDR < 0x$WPA_ADDR) + fixture isolation (= production の call pmdneo_fade_begin $PROD_FADEBEGIN_CALL 件 = cmd 6 のみ)"
else
  ng "gate 15: .org overlap or fixture leak (finish=0x$FINISH_ADDR unmask=0x$UNMASK_ADDR wpa=0x$WPA_ADDR fade_begin_call=$PROD_FADEBEGIN_CALL)"
fi

# --- gate 11: register preservation (= §決定 7 gate 5、 Annex G-2 破壊 register 一覧整合) ---
# ADR-0050 fade routine 領域 (nmi_cmd_6_fade_start 〜 pmdneo_fade_finish_silence) で:
#  (a) push/pop 命令総数が balance (= stack leak なし)
#  (b) IY 命令使用 0 (= 全 fade routine で IY 不変、 Annex G-2 整合)
#  (c) IX 命令使用は pmdneo_v2_fade_reapply 内のみ (= 他 fade routine は IX 不変、 Annex G-2 整合)
#  (d) pmdneo_v2_fade_reapply の最初の IX 命令 = push ix、 最後 = pop ix (= 入口 save /
#      出口 restore で caller IX 不変、 §決定 7 gate 5)
# 命令行のみ抽出 (= comment ;; 行 / label 行を除外)、 ix/iy は token 単位で照合。
FADE_REGION=$(awk '/^nmi_cmd_6_fade_start:/{f=1} /ADR-0051 軸 B 実装 sprint 7/{f=0} f' "$DRIVER")
FADE_INSN=$(echo "$FADE_REGION" | grep -E '^[ \t]+[a-z]' || true)
REAPPLY_INSN=$(awk '/^pmdneo_v2_fade_reapply:/{f=1} /^pmdneo_fade_scale:/{f=0} f' "$DRIVER" | grep -E '^[ \t]+[a-z]' || true)
PUSH_N=$(echo "$FADE_INSN" | grep -cE '(^|[^a-zA-Z0-9_])push([^a-zA-Z0-9_])' || true)
POP_N=$(echo "$FADE_INSN" | grep -cE '(^|[^a-zA-Z0-9_])pop([^a-zA-Z0-9_])' || true)
IY_USE=$(echo "$FADE_INSN" | grep -cE '(^|[^a-zA-Z0-9_])iy([^a-zA-Z0-9_]|$)' || true)
IX_ALL=$(echo "$FADE_INSN" | grep -cE '(^|[^a-zA-Z0-9_])ix([^a-zA-Z0-9_]|$)' || true)
IX_REAPPLY=$(echo "$REAPPLY_INSN" | grep -cE '(^|[^a-zA-Z0-9_])ix([^a-zA-Z0-9_]|$)' || true)
IX_FIRST=$(echo "$REAPPLY_INSN" | grep -E '(^|[^a-zA-Z0-9_])ix([^a-zA-Z0-9_]|$)' | head -1)
IX_LAST=$(echo "$REAPPLY_INSN" | grep -E '(^|[^a-zA-Z0-9_])ix([^a-zA-Z0-9_]|$)' | tail -1)
if [ "$PUSH_N" -eq "$POP_N" ] && [ "$PUSH_N" -ge 1 ] \
   && [ "$IY_USE" -eq 0 ] \
   && [ "$IX_ALL" -eq "$IX_REAPPLY" ] && [ "$IX_REAPPLY" -ge 2 ] \
   && echo "$IX_FIRST" | grep -qE '(^|[^a-zA-Z0-9_])push[ \t]+ix' \
   && echo "$IX_LAST" | grep -qE '(^|[^a-zA-Z0-9_])pop[ \t]+ix'; then
  ok "gate 11: register preservation = push/pop balance (${PUSH_N}/${POP_N}) + IY 命令不使用 + IX 命令は pmdneo_v2_fade_reapply 内のみ (${IX_REAPPLY} 件、 入口 push ix / 出口 pop ix で caller IX save/restore)"
else
  ng "gate 11: register preservation 不整合 (push=$PUSH_N pop=$POP_N iy=$IY_USE ix_all=$IX_ALL ix_reapply=$IX_REAPPLY first=[$IX_FIRST] last=[$IX_LAST])"
fi

# --- gate 12: cmd 0x04 即時 silence 不可触 (= §決定 7 gate 6) ---
if git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  if git diff --quiet "$BASE_REF" -- src/driver/IRQ.inc; then
    ok "gate 12: cmd 0x04 不可触 = src/driver/IRQ.inc が $BASE_REF と byte-identical"
  else
    ng "gate 12: src/driver/IRQ.inc が $BASE_REF から変更されている (= cmd 0x04 byte-identical 違反)"
  fi
else
  if git diff --quiet HEAD -- src/driver/IRQ.inc && [ -z "$(git status --porcelain src/driver/IRQ.inc)" ]; then
    ok "gate 12: cmd 0x04 不可触 = src/driver/IRQ.inc 無変更 (= base ref 不在、 working tree 比較)"
  else
    ng "gate 12: src/driver/IRQ.inc に変更あり"
  fi
fi

# ============================================================
# fade fixture build (= PMDNEO_FADE_FIXTURE=1 + fadeout-verify.mml) + MAME trace
# ============================================================
echo "=== fade fixture build (= PMDNEO_FADE_FIXTURE=1 + fadeout-verify.mml) + MAME headless trace ==="
rm -f "$PREPROCESSED"
PMDNEO_FADE_FIXTURE=1 MML_INPUTS=fadeout-verify.mml bash scripts/build-poc.sh >/dev/null 2>&1 \
  || { echo "❌ fade fixture build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 6 >/dev/null 2>&1 || true
[ -s "$YMFM" ] || { echo "❌ ymfm-trace 未生成"; exit 1; }
[ -s "$ZMEM" ] || { echo "❌ z80-mem-trace 未生成"; exit 1; }

# --- gate 1: fade 開始 (= §決定 7 gate 1) ---
S_ON=$(awk -F'\t' 'tolower($3)=="f819" && $4=="01"' "$ZMEM" | wc -l | tr -d ' ')
M_INIT=$(awk -F'\t' 'tolower($3)=="f81b" && $4=="3F"' "$ZMEM" | wc -l | tr -d ' ')
C_INIT=$(awk -F'\t' 'tolower($3)=="f81a" && $4=="00"' "$ZMEM" | wc -l | tr -d ' ')
L_INIT=$(awk -F'\t' 'tolower($3)=="fd39" && $4=="40"' "$ZMEM" | wc -l | tr -d ' ')
if [ "$S_ON" -ge 1 ] && [ "$M_INIT" -ge 1 ] && [ "$C_INIT" -ge 1 ] && [ "$L_INIT" -ge 1 ]; then
  ok "gate 1: fade 開始 = driver_fade_state->1 ($S_ON) + master 0x3F ($M_INIT) + counter 0 ($C_INIT) + level 0x40 ($L_INIT) init write"
else
  ng "gate 1: fade 開始 init write 不足 (state=$S_ON master=$M_INIT counter=$C_INIT level=$L_INIT)"
fi

# --- gate 2: fade level 単調減少 (= §決定 7 gate 2) ---
LVL=$(awk -F'\t' 'tolower($3)=="fd39"{print $4}' "$ZMEM")
LVL_N=$(echo "$LVL" | grep -c . || true)
LVL_BAD=$(echo "$LVL" | mono_noninc)
LVL_FIRST=$(echo "$LVL" | head -1)
LVL_LAST=$(echo "$LVL" | tail -1)
if [ "$LVL_BAD" -eq 0 ] && [ "$LVL_FIRST" = "40" ] && [ "$LVL_LAST" = "00" ]; then
  ok "gate 2: fade level 単調減少 = pmdneo_v2_fade_level $LVL_FIRST->$LVL_LAST 非増加 ($LVL_N writes)"
else
  ng "gate 2: fade level 非単調 (bad=$LVL_BAD first=$LVL_FIRST last=$LVL_LAST)"
fi

# --- gate 3: ADPCM-A master reg 0x01 単調減少 (= §決定 7 gate 2) ---
# port B reg は ymfm-trace で 3 桁 (= 0x100 offset)、 reg 0x01 = "101"。
AMA=$(awk -F'\t' '$2=="B" && $3=="101"{print $4}' "$YMFM")
AMA_N=$(echo "$AMA" | grep -c . || true)
AMA_BAD=$(echo "$AMA" | mono_noninc)
AMA_FIRST=$(echo "$AMA" | head -1)
AMA_LAST=$(echo "$AMA" | tail -1)
if [ "$AMA_BAD" -eq 0 ] && [ "$AMA_LAST" = "00" ] && [ "$AMA_N" -ge 60 ]; then
  ok "gate 3: ADPCM-A master 単調減少 = reg 0x01 $AMA_FIRST->$AMA_LAST 非増加 ($AMA_N writes)"
else
  ng "gate 3: ADPCM-A master 非単調 (bad=$AMA_BAD first=$AMA_FIRST last=$AMA_LAST n=$AMA_N)"
fi

# --- gate 4: FM TL 減衰 (= §決定 7 gate 2) ---
# reg 0x42 (port B = "142") は voice-load の loud TL write + fade reapply の faded TL
# write が混在。 faded range (>= 0x70) の write 列で最長単調非減少 run を取り、 fade
# 減衰 ramp (= 単調増加 = TL 増 = 音量減) が 0x7F へ到達することを確認。
FMTL=$(awk -F'\t' '$2=="B" && $3=="142" && $4>="70"{print $4}' "$YMFM")
read -r FM_RUN FM_RS FM_RE <<< "$(echo "$FMTL" | awk '{v=$1""; if(NR==1){rl=1;rs=v}else if(v>=p){rl++}else{rl=1;rs=v}; if(rl>best){best=rl;bs=rs;be=v}; p=v} END{print best+0, bs, be}')"
if [ "${FM_RUN:-0}" -ge 40 ] && [ "$FM_RE" = "7F" ] && [ -n "$FM_RS" ] && [ "$FM_RS" != "$FM_RE" ]; then
  ok "gate 4: FM TL 減衰 = reg 0x42 faded ramp $FM_RS->$FM_RE 単調非減少 run $FM_RUN 件 (= TL 増 = 音量減)"
else
  ng "gate 4: FM TL 減衰 ramp 不足 (run=$FM_RUN start=$FM_RS end=$FM_RE)"
fi

# --- gate 5: SSG volume 単調減少 (= §決定 7 gate 2、 literal 減衰) ---
# reg 0x08/0x09/0x0A 各 ch で先頭 init write (0x00) を落とし、 keyon 0x0F から 0x00
# まで単調非増加に減衰することを確認 (= fadeout-verify.mml で SSG が fade window 中に
# 鳴るため literal value 減衰を観測可能)。
SSG_OK=1
for r in 08 09 0A; do
  SV=$(awk -F'\t' -v r="$r" '$2=="A" && $3==r{print $4}' "$YMFM" | tail -n +2)
  SV_BAD=$(echo "$SV" | mono_noninc)
  SV_FIRST=$(echo "$SV" | head -1)
  SV_LAST=$(echo "$SV" | tail -1)
  if [ "$SV_BAD" -ne 0 ] || [ "$SV_FIRST" != "0F" ] || [ "$SV_LAST" != "00" ]; then
    SSG_OK=0
    ng "gate 5: SSG reg 0x$r 非単調減衰 (bad=$SV_BAD first=$SV_FIRST last=$SV_LAST)"
  fi
done
[ "$SSG_OK" -eq 1 ] && ok "gate 5: SSG volume 単調減少 = reg 0x08/0x09/0x0A 全 ch で 0x0F->0x00 literal 非増加減衰"

# --- gate 6: ADPCM-B reapply 機構 gate (= §決定 7 gate 2) ---
# ADPCM-B volume reg 0x1B が fade step 毎に reapply 経路で write される (= reapply
# loop が ADPCM-B part を対象に含む)。 fadeout-verify.mml は J empty のため ADPCM-B
# の literal value decay は未確認 (= user 判断 = ADPCM-B literal 減衰は scope 外)。
ADPB=$(awk -F'\t' '$2=="A" && $3=="1B"' "$YMFM" | wc -l | tr -d ' ')
if [ "$ADPB" -ge 60 ]; then
  ok "gate 6: ADPCM-B reapply 機構 = reg 0x1B が fade step 毎に write ($ADPB 件、 = reapply loop が ADPCM-B part を loop、 literal value decay は J empty で未確認)"
else
  ng "gate 6: ADPCM-B reg 0x1B reapply write 不足 (${ADPB}, 期待 >= 60)"
fi

# --- gate 7: dispatch volume write が fade factor 適用後値 (= §決定 7 gate 3) ---
# 案 (b) = volume hook 自体に fade factor 混入。 fade 減衰開始後、 SSG note dispatch
# 経路が raw note volume (= V15 = 0x0F) を書き戻さない (= raw spike なし) = dispatch
# 経路も fade 適用済。 FM TL の fade 適用は gate 4 の faded ramp で観測。
SSG_RAW_SPIKE=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A"){
  if(seen[$3] && $4=="0F"){spike++}
  if($4!="0F" && $4!="00"){seen[$3]=1}
} END{print spike+0}' "$YMFM")
if [ "$SSG_RAW_SPIKE" -eq 0 ]; then
  ok "gate 7: dispatch fade 適用 = fade 減衰開始後 SSG raw volume (0x0F) spike なし (= volume hook factor 混入で dispatch 経路も fade 適用済)"
else
  ng "gate 7: fade 中に SSG raw volume write spike 検出 ($SSG_RAW_SPIKE 件)"
fi

# --- gate 8: finish burst 1 回のみ (= §決定 7 gate 4) ---
# fade finish burst = pmdneo_fade_finish_silence の ADPCM-A keyoff (reg 0x00 = "100")
# が 0x81 (= ch0 keyoff) / 0xA0 (= ch5 keyoff) を各 1 回だけ write。
FINISH_81=$(awk -F'\t' '$2=="B" && $3=="100" && $4=="81"' "$YMFM" | wc -l | tr -d ' ')
FINISH_A0=$(awk -F'\t' '$2=="B" && $3=="100" && $4=="A0"' "$YMFM" | wc -l | tr -d ' ')
if [ "$FINISH_81" -eq 1 ] && [ "$FINISH_A0" -eq 1 ]; then
  ok "gate 8: finish burst 1 回 = ADPCM-A keyoff burst (reg 0x00 0x81/0xA0) が trace 全体で各 1 回"
else
  ng "gate 8: finish burst 回数異常 (0x81=$FINISH_81 0xA0=${FINISH_A0}, 期待 各 1)"
fi

# --- gate 9: finish burst 全 chip keyoff (= §決定 7 gate 4) ---
ANCHOR=$(awk -F'\t' '$2=="B" && $3=="100" && $4=="81"{print $1; exit}' "$YMFM")
if [ -n "$ANCHOR" ]; then
  LO=$((ANCHOR - 15)); HI=$((ANCHOR + 10))
  BURST=$(awk -F'\t' -v lo="$LO" -v hi="$HI" '$1+0>=lo && $1+0<=hi' "$YMFM")
  FM_KO=$(echo "$BURST" | awk -F'\t' '$2=="A" && $3=="28"' | wc -l | tr -d ' ')
  SSG_KO=$(echo "$BURST" | awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A")' | wc -l | tr -d ' ')
  AA_KO=$(echo "$BURST" | awk -F'\t' '$2=="B" && $3=="100"' | wc -l | tr -d ' ')
  AB_KO=$(echo "$BURST" | awk -F'\t' '$2=="A" && $3=="10"' | wc -l | tr -d ' ')
  if [ "$FM_KO" -ge 6 ] && [ "$SSG_KO" -ge 3 ] && [ "$AA_KO" -eq 6 ] && [ "$AB_KO" -eq 2 ]; then
    ok "gate 9: finish 全 chip keyoff = FM reg0x28 x$FM_KO + SSG reg0x08-0x0A x$SSG_KO + ADPCM-A reg0x00 x$AA_KO + ADPCM-B reg0x10 x$AB_KO"
  else
    ng "gate 9: finish burst keyoff 不足 (FM=$FM_KO SSG=$SSG_KO ADPCM-A=$AA_KO ADPCM-B=$AB_KO)"
  fi
else
  ng "gate 9: finish burst anchor (ADPCM-A 0x81) 未検出"
fi

# --- gate 10: SSG finish tone disable (= γ 追加) ---
# finish burst で SSG 3 ch の tone bit を progressive disable する (= pmdneo_ssg_tone_sync
# A=0 を ch 0/1/2 順に call、 ADR-0051 §決定 3/4 symmetric tone disable)。 fadeout-verify.mml
# は SSG が鳴るため shadow の tone bit は song 中 enable 済 = finish で 1 ch ずつ bit set
# され reg 0x07 は単調非減少で最終 0x3F (= 全 SSG tone disable) に到達。 noise bit (3-5) は
# 全 write で set 維持 (= 値 0x38-0x3F、 ADR-0051 §決定 5 noise 不変)。
if [ -n "${ANCHOR:-}" ]; then
  LO=$((ANCHOR - 15)); HI=$((ANCHOR + 10))
  R07=$(awk -F'\t' -v lo="$LO" -v hi="$HI" '$1+0>=lo && $1+0<=hi && $2=="A" && $3=="07"{print $4}' "$YMFM")
  R07_N=$(echo "$R07" | grep -c . || true)
  R07_LAST=$(echo "$R07" | tail -1)
  R07_BADNOISE=$(echo "$R07" | grep -cvE '^3[89A-F]$' || true)
  R07_NONMONO=$(echo "$R07" | mono_nondec)
  if [ "$R07_N" -ge 3 ] && [ "$R07_LAST" = "3F" ] && [ "$R07_BADNOISE" -eq 0 ] && [ "$R07_NONMONO" -eq 0 ]; then
    ok "gate 10: SSG finish tone disable = finish burst で reg 0x07 が progressive tone disable (${R07_N} writes, 単調非減少, 最終 0x3F = 全 SSG tone disable, noise bit 不変)"
  else
    ng "gate 10: SSG finish tone disable 異常 (n=$R07_N last=$R07_LAST bad_noise=$R07_BADNOISE non_mono=$R07_NONMONO)"
  fi
else
  ng "gate 10: finish burst anchor 未検出"
fi

# ============================================================
# regression gate (= 既存 verify script、 serial 実行)
# ============================================================
echo "=== gate 13: ADR-0049 mute + baseline regression (= verify-mute-semantics.sh) ==="
if bash src/test-fixtures/axis-b/verify-mute-semantics.sh >/dev/null 2>&1; then
  ok "gate 13: ADR-0049 mute regression 7 gate + baseline 9 script 全 PASS"
else
  ng "gate 13: mute / baseline regression FAIL"
fi

echo "=== gate 14: ADR-0051 SSG tone-enable regression (= verify-ssg-tone-enable.sh) ==="
if bash src/test-fixtures/axis-b/verify-ssg-tone-enable.sh >/dev/null 2>&1; then
  ok "gate 14: ADR-0051 SSG tone-enable regression 12 gate 全 PASS"
else
  ng "gate 14: SSG tone-enable regression FAIL"
fi

# ============================================================
# production build 復帰 + 集計
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了 (= PMDNEO_FADE_FIXTURE 未指定、 default)"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ ALL PASS (= 軸 B sprint 6 fade-out semantics 16 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
