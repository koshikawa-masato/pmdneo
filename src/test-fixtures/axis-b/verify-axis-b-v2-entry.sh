#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 1 ε verify gate (= ADR-0052 FM/SSG v2 entry + trigger path)
#
# verify scope: ADR-0052 §決定 7 の verify gate 7 件を再現可能な verify script に
#   体系化する。 sub-sprint β (= cmd 0x07 trigger path) / γ (= FM 6ch v2 dispatcher) /
#   δ (= SSG 3ch v2 dispatcher) で実装した v2 entry を gate 1-7 で検証。 driver 改修なし。
#
#   --- static gate (= production build .lst) ---
#   gate 2: 既存 cmd path 非破壊   — nmi_dispatch に既存 cmd 2/5/6 分岐残存
#   gate 6: .org overflow / overlap — v2 並設 routine 4 件が 0x0610 セクション
#                                     (>= 0x0610) + 0x0066 セクション max addr < 0x0100
#   --- cmd 0x07 trigger path gate (= static + 動的 marker trace) ---
#   gate 1: cmd 0x07 trigger path  — nmi_dispatch に cmd 0x07 分岐 (jp z,
#                                     nmi_cmd_7_play_song_v2) + nmi_cmd_7_play_song_v2
#                                     / pmdneo_v2_entry_skeleton routine 存在 +
#                                     nmi_cmd_7_play_song_v2 が pmdneo_v2_entry_skeleton
#                                     を call (= 連結 edge、 .lst 静的) + V2 fixture
#                                     build z80-mem-trace で pmdneo_v2_entry_marker
#                                     (0xFD3B) <- 0x07 (動的 = skeleton 到達)
#   --- trace gate (= V2 fixture build、 ym2610 / ym2610b 両 chip) ---
#   gate 3: FM 6ch v2 dispatch     — reg 0x28 keyon set = ym2610 {F1,F2,F5,F6} /
#                                     ym2610b {F0,F1,F2,F4,F5,F6}
#   gate 4: SSG 3ch v2 dispatch    — reg 0x08/0x09/0x0A <- 値 0x0F が各 1 計 3 (両 chip)
#   gate 5: chip target flag 分岐  — FM keyon count = ym2610 4 / ym2610b 6 の差分
#   --- baseline gate ---
#   gate 7: baseline regression    — verify-fadeout-semantics.sh 16 gate (= 内部で
#                                     verify-mute 7 + baseline 9 script + verify-ssg
#                                     -tone-enable 15 gate を transitively 実行)
#
# 注 (= gate 1 verify 構成、 ADR-0052 ε user 判断 = 案 A): V2 fixture build は
#   nmi_cmd_5_init_mml_song -> pmdneo_v2_entry_skeleton 直接 call 経路 (= ADR-0052
#   Annex D-1) で、 実 NMI dispatch command 0x07 命令を MAME 68k 側から送出しない。
#   よって cmd 0x07 分岐と target routine の存在は production build .lst で静的確認、
#   skeleton 到達は V2 fixture marker trace で動的確認、 の組合せで gate 1 を構成
#   する (= cmd 0x07 命令そのものの動的 PC trace は本 gate の対象外、 ADR-0052
#   Annex G に literal 差分記録)。
#
# fixture: TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml (= FM-empty
#   fixture で song FM keyon 混入を排除)、 ym2610 / ym2610b 両 chip。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-entry.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

# V2 fixture trace 退避先 (= ym2610 / ym2610b 別 chip 比較用)
YMFM_2610="/tmp/v2-entry-ym2610-ymfm.tsv"
ZMEM_2610="/tmp/v2-entry-ym2610-zmem.tsv"
YMFM_2610B="/tmp/v2-entry-ym2610b-ymfm.tsv"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# production build (= ym2610 default) — gate 1 静的 / gate 2 / gate 6
# ============================================================
echo "=== production build (= ym2610 default) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }

# --- gate 2: 既存 cmd path 非破壊 (= nmi_dispatch に cmd 2/5/6 分岐残存) ---
CMD2=$(grep -cE 'z, nmi_cmd_2_play_song' "$LST" || true)
CMD5=$(grep -cE 'z, nmi_cmd_5_adpcmb_beat' "$LST" || true)
CMD6=$(grep -cE 'z, nmi_cmd_6_fade_start' "$LST" || true)
if [ "$CMD2" -ge 1 ] && [ "$CMD5" -ge 1 ] && [ "$CMD6" -ge 1 ]; then
  ok "gate 2: 既存 cmd path 非破壊 = nmi_dispatch に cmd 2($CMD2)/5($CMD5)/6($CMD6) 分岐残存 (= cmd 0x07 additive が既存分岐を破壊せず)"
else
  ng "gate 2: 既存 cmd 分岐 欠落 (cmd2=$CMD2 cmd5=$CMD5 cmd6=$CMD6)"
fi

# --- gate 1 (静的部): cmd 0x07 分岐 + target routine 存在 + cmd7 routine が
#     pmdneo_v2_entry_skeleton を call すること (= cmd 0x07 -> skeleton 連結を
#     routine label の存在だけでなく call edge まで静的確認) ---
CMD7_BRANCH=$(grep -cE 'z, nmi_cmd_7_play_song_v2' "$LST" || true)
CMD7_ROUTINE=$(awk '/[ \t]nmi_cmd_7_play_song_v2:/{print "ok"; exit}' "$LST")
SKELETON_LBL=$(awk '/[ \t]pmdneo_v2_entry_skeleton:/{print "ok"; exit}' "$LST")
# nmi_cmd_7_play_song_v2 label から次 label までの routine body に
# `call pmdneo_v2_entry_skeleton` が存在するか (= 連結 edge の静的確認)。
CMD7_CALLS_SKELETON=$(awk '
  /[ \t]nmi_cmd_7_play_song_v2:/{seg=1; next}
  seg && /[A-Za-z0-9_]:[ \t]*$/{seg=0}
  seg && /call[ \t]+pmdneo_v2_entry_skeleton/{print "ok"; exit}
' "$LST")

# --- gate 6: .org overflow / section overlap ---
# v2 並設 routine 4 件 (= nmi_cmd_7_play_song_v2 / pmdneo_v2_entry_skeleton /
# pmdneo_v2_fm_dispatch / pmdneo_v2_ssg_dispatch) が .org 制約のない 0x0610
# セクション (>= 0x0610) に配置 + 0x0066 NMI セクションの max instruction addr が
# 0x0100 未満 (= cmd 0x07 分岐 additive 後も .org 0x0100 irq_handler_body と
# silent overlap しない、 memory feedback_org_section_overflow_silent_bug.md)。
G6BAD=0
G6DET=""
for label in nmi_cmd_7_play_song_v2 pmdneo_v2_entry_skeleton pmdneo_v2_fm_dispatch pmdneo_v2_ssg_dispatch; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":"){print $1; exit}' "$LST")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G6BAD=$((G6BAD + 1))
    G6DET="$G6DET $label=0x${addr:-NONE}"
  else
    G6DET="$G6DET $label=0x$addr"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST" | sort | tail -1)
if [ "$G6BAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "gate 6: v2 並設 routine 全 >= 0x0610 +0x0066 セクション max addr 0x$MAX0066 < 0x0100 (= overflow / overlap なし)"
else
  ng "gate 6: .org overflow / overlap risk (bad=$G6BAD max0066=0x${MAX0066:-NONE}${G6DET})"
fi

# ============================================================
# V2 fixture build (= ym2610) + MAME headless trace
# ============================================================
echo "=== V2 fixture build (= ym2610、 TEST_MODE_V2_ENTRY_FIXTURE=1 + ssg-v0-keyon.mml) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "❌ V2 fixture (ym2610) build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成 (ym2610)"; exit 1; }
[ -f "$ZMEM" ] || { echo "❌ z80-mem-trace 未生成 (ym2610)"; exit 1; }
cp "$YMFM" "$YMFM_2610"
cp "$ZMEM" "$ZMEM_2610"

# --- gate 1: cmd 0x07 trigger path (= 静的 + 動的 marker) ---
MARKER=$(awk -F'\t' '$3=="FD3B" && $4=="07"' "$ZMEM_2610" | wc -l | tr -d ' ')
if [ "$CMD7_BRANCH" -ge 1 ] && [ "$CMD7_ROUTINE" = "ok" ] && [ "$SKELETON_LBL" = "ok" ] \
   && [ "$CMD7_CALLS_SKELETON" = "ok" ] && [ "$MARKER" -ge 1 ]; then
  ok "gate 1: cmd 0x07 trigger path = nmi_dispatch cmd 0x07 分岐($CMD7_BRANCH) + nmi_cmd_7_play_song_v2 routine が pmdneo_v2_entry_skeleton を call (= 連結 edge 静的確認) + routine label 存在 (静的) + pmdneo_v2_entry_marker 0xFD3B <- 0x07 ($MARKER 件、 動的 = skeleton 到達)"
else
  ng "gate 1: cmd 0x07 trigger path 不成立 (branch=$CMD7_BRANCH routine=$CMD7_ROUTINE skeleton=$SKELETON_LBL calls_skeleton=$CMD7_CALLS_SKELETON marker=$MARKER)"
fi

# ym2610 FM keyon set / count (= reg 0x28 keyon = high nibble F) + SSG 0x0F per-ch count
FM_SET_2610=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/{print $4}' "$YMFM_2610" | sort -u | tr '\n' ',' | sed 's/,$//')
FM_CNT_2610=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610" | wc -l | tr -d ' ')
SSG08_2610=$(awk -F'\t' '$2=="A" && $3=="08" && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')
SSG09_2610=$(awk -F'\t' '$2=="A" && $3=="09" && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')
SSG0A_2610=$(awk -F'\t' '$2=="A" && $3=="0A" && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')

# ============================================================
# V2 fixture build (= ym2610b) + MAME headless trace
# ============================================================
echo "=== V2 fixture build (= ym2610b) + MAME headless trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610b >/dev/null 2>&1 \
  || { echo "❌ V2 fixture (ym2610b) build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成 (ym2610b)"; exit 1; }
cp "$YMFM" "$YMFM_2610B"

FM_SET_2610B=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/{print $4}' "$YMFM_2610B" | sort -u | tr '\n' ',' | sed 's/,$//')
FM_CNT_2610B=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
SSG08_2610B=$(awk -F'\t' '$2=="A" && $3=="08" && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')
SSG09_2610B=$(awk -F'\t' '$2=="A" && $3=="09" && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')
SSG0A_2610B=$(awk -F'\t' '$2=="A" && $3=="0A" && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')

# --- gate 3: FM 6ch v2 dispatch (= reg 0x28 keyon set 両 chip) ---
if [ "$FM_SET_2610" = "F1,F2,F5,F6" ] && [ "$FM_SET_2610B" = "F0,F1,F2,F4,F5,F6" ]; then
  ok "gate 3: FM 6ch v2 dispatch = reg 0x28 keyon set ym2610 {$FM_SET_2610} (= B/C/E/F) / ym2610b {$FM_SET_2610B} (= A-F)"
else
  ng "gate 3: FM keyon set 不一致 (ym2610={$FM_SET_2610} 期待 F1,F2,F5,F6 / ym2610b={$FM_SET_2610B} 期待 F0,F1,F2,F4,F5,F6)"
fi

# --- gate 4: SSG 3ch v2 dispatch (= reg 0x08/0x09/0x0A <- 値 0x0F、 各 ch 個別 1 件、 両 chip) ---
# 総数 3 件ではなく reg 0x08/0x09/0x0A を個別 assert (= ある ch 2 件 + 別 ch 0 件で
# 総数 3 になる擦り抜けを排除、 SSG ch 0/1/2 各 1 を担保)。
if [ "$SSG08_2610" -eq 1 ] && [ "$SSG09_2610" -eq 1 ] && [ "$SSG0A_2610" -eq 1 ] \
   && [ "$SSG08_2610B" -eq 1 ] && [ "$SSG09_2610B" -eq 1 ] && [ "$SSG0A_2610B" -eq 1 ]; then
  ok "gate 4: SSG 3ch v2 dispatch = reg 0x08/0x09/0x0A <- 値 0x0F 各 ch 個別 1 件 (ym2610 08=${SSG08_2610}/09=${SSG09_2610}/0A=${SSG0A_2610}、 ym2610b 08=${SSG08_2610B}/09=${SSG09_2610B}/0A=${SSG0A_2610B} = SSG ch 0/1/2 各 1)"
else
  ng "gate 4: SSG 0x0F per-ch write 数 不一致 (ym2610 08=${SSG08_2610}/09=${SSG09_2610}/0A=${SSG0A_2610}、 ym2610b 08=${SSG08_2610B}/09=${SSG09_2610B}/0A=${SSG0A_2610B}、 期待 各 1)"
fi

# --- gate 5: chip target flag 分岐 (= FM keyon count 差分) ---
if [ "$FM_CNT_2610" -eq 4 ] && [ "$FM_CNT_2610B" -eq 6 ]; then
  ok "gate 5: chip target flag 分岐 = FM keyon count ym2610 $FM_CNT_2610 (= A/D skip 4ch) / ym2610b $FM_CNT_2610B (= 全 6ch) の差分が register trace で観測可能"
else
  ng "gate 5: FM keyon count 差分 不一致 (ym2610=$FM_CNT_2610 期待 4 / ym2610b=$FM_CNT_2610B 期待 6)"
fi

# ============================================================
# gate 7: baseline regression (= verify-fadeout-semantics.sh 16 gate)
# ============================================================
echo "=== gate 7: baseline regression (= verify-fadeout-semantics.sh) ==="
if bash src/test-fixtures/axis-b/verify-fadeout-semantics.sh >/dev/null 2>&1; then
  ok "gate 7: baseline regression = verify-fadeout-semantics.sh 16 gate 全 PASS (= verify-mute 7 + baseline 9 script + verify-ssg-tone-enable 15 gate を transitively)"
else
  ng "gate 7: baseline regression FAIL"
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
  echo "✅ ALL PASS (= 軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry 7 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
