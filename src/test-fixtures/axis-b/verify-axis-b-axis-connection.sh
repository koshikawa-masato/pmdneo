#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 4 γ verify gate (= ADR-0055 軸 C/G/rhythm 接続点定義)
#
# verify scope: ADR-0055 §決定 6 の verify gate 6 件を再現可能な verify script に
#   体系化する。 sub-sprint β (= PR #88) で実装した軸 C/G/rhythm 接続点 stub
#   (= pmdneo_v2_adpcmb_dispatch / pmdneo_v2_rhythm_dispatch) を gate 1-6 で
#   検証。 driver 改修なし。
#
#   --- cmd 0x07 v2 path gate (= static + V2 fixture marker trace) ---
#   gate 1: cmd 0x07 v2 path 到達維持 — pmdneo_v2_entry_skeleton が
#                                       pmdneo_v2_adpcmb_dispatch /
#                                       pmdneo_v2_rhythm_dispatch を call (.lst 静的)
#                                       + V2 fixture marker 0xFD3B <- 0x07 (動的)
#   --- 接続点 marker gate (= V2 fixture build、 ym2610 / ym2610b 両 chip) ---
#   gate 2: ADPCM-B 接続点 marker     — pmdneo_v2_adpcmb_marker (0xFD3C) <- 0x09
#                                       (= PART_PCM、 ADPCM-B dispatch boundary 到達)
#   gate 3: rhythm 接続点 marker      — pmdneo_v2_rhythm_marker (0xFD3D) <- 0x0A
#                                       (= PART_RHYTHM、 rhythm dispatch boundary 到達)
#   gate 4: 既存 v2 dispatch regression — FM 6ch keyon (reg 0x28、 ym2610 4 /
#                                       ym2610b 6) + SSG 3ch dispatch (reg 0x08-
#                                       0x0A 0x0F、 各 3) + F-2-B (reg 0x27 0xAA、
#                                       各 1) が接続点追加後も維持
#   --- static / baseline gate ---
#   gate 6: 軸 C/G/rhythm 不可触 + .org — 接続点 stub が既存 adpcmb_keyon /
#                                       pmdneo_rhythm_event_trigger を call しない
#                                       (= §決定 2 stub marker proof) + v2 並設
#                                       routine 7 件が 0x0610 セクション + 0x0066
#                                       セクション max addr < 0x0100
#   gate 5: baseline regression       — verify-axis-b-f2b-integration.sh 6 gate (=
#                                       内部で verify-axis-b-sram-placement 6 +
#                                       verify-axis-b-v2-entry 7 + verify-fadeout
#                                       16 + mute 7 + verify-ssg 15 gate を
#                                       transitively = ADR-0052/0053/0054 +
#                                       mute/fade/SSG tone-enable regression)
#
# 注: 接続点 = 簡易 stub marker proof (= ADR-0055 §決定 2)。 既存 軸 C/rhythm
#   routine は call しない (= 実音 dispatch は後続 future)。 検証は register /
#   z80-mem trace primary gate。
#
# fixture: TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml、 両 chip。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-axis-connection.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_2610="/tmp/cgr-verify-ym2610-ymfm.tsv"
ZMEM_2610="/tmp/cgr-verify-ym2610-zmem.tsv"
YMFM_2610B="/tmp/cgr-verify-ym2610b-ymfm.tsv"
ZMEM_2610B="/tmp/cgr-verify-ym2610b-zmem.tsv"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# seg_has_call <label> <callee> : label routine body に call <callee> があれば "bad"
seg_has_call() {
  awk -v l="$1" -v c="$2" '
    $0 ~ ("[ \t]" l ":"){seg=1; next}
    seg && /[A-Za-z0-9_]:[ \t]*$/{seg=0}
    seg && $0 ~ ("call[ \t]+" c){print "bad"; exit}
  ' "$LST"
}

# ============================================================
# production build (= ym2610 default) — gate 1 静的 / gate 6
# ============================================================
echo "=== production build (= ym2610 default) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "❌ .lst 未生成"; exit 1; }

# --- gate 1 (静的部): skeleton が adpcmb_dispatch / rhythm_dispatch を call ---
SKEL_CALLS_ADPCMB=$(awk '
  /[ \t]pmdneo_v2_entry_skeleton:/{seg=1; next}
  seg && /[A-Za-z0-9_]:[ \t]*$/{seg=0}
  seg && /call[ \t]+pmdneo_v2_adpcmb_dispatch/{print "ok"; exit}
' "$LST")
SKEL_CALLS_RHYTHM=$(awk '
  /[ \t]pmdneo_v2_entry_skeleton:/{seg=1; next}
  seg && /[A-Za-z0-9_]:[ \t]*$/{seg=0}
  seg && /call[ \t]+pmdneo_v2_rhythm_dispatch/{print "ok"; exit}
' "$LST")

# --- gate 6: 軸 C/G/rhythm 不可触 + .org overflow / section overlap ---
# (a) 接続点 stub が既存 adpcmb_keyon / pmdneo_rhythm_event_trigger を call しない
ADPCMB_BADCALL=$(seg_has_call pmdneo_v2_adpcmb_dispatch adpcmb_keyon)
RHYTHM_BADCALL=$(seg_has_call pmdneo_v2_rhythm_dispatch pmdneo_rhythm_event_trigger)
# (b) v2 並設 routine 7 件が 0x0610 セクション
G6BAD=0
G6DET=""
for label in nmi_cmd_7_play_song_v2 pmdneo_v2_entry_skeleton pmdneo_v2_fm_dispatch pmdneo_v2_ssg_dispatch pmdneo_v2_fm3ext_dispatch pmdneo_v2_adpcmb_dispatch pmdneo_v2_rhythm_dispatch; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":"){print $1; exit}' "$LST")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G6BAD=$((G6BAD + 1)); G6DET="$G6DET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST" | sort | tail -1)
if [ -z "$ADPCMB_BADCALL" ] && [ -z "$RHYTHM_BADCALL" ] && [ "$G6BAD" -eq 0 ] \
   && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "gate 6: 軸 C/G/rhythm 不可触 (= 接続点 stub が adpcmb_keyon / pmdneo_rhythm_event_trigger を call しない、 §決定 2) + v2 並設 routine 7 件全 >= 0x0610 + 0x0066 セクション max addr 0x${MAX0066} < 0x0100"
else
  ng "gate 6: 不可触違反 or .org overflow (adpcmb_badcall=${ADPCMB_BADCALL:-none} rhythm_badcall=${RHYTHM_BADCALL:-none} routine_bad=${G6BAD} max0066=0x${MAX0066:-NONE}${G6DET})"
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

# --- gate 1: cmd 0x07 v2 path 到達維持 (= 静的 + marker) ---
MARKER=$(awk -F'\t' '$3=="FD3B" && $4=="07"' "$ZMEM_2610" | wc -l | tr -d ' ')
if [ "$SKEL_CALLS_ADPCMB" = "ok" ] && [ "$SKEL_CALLS_RHYTHM" = "ok" ] && [ "$MARKER" -ge 1 ]; then
  ok "gate 1: cmd 0x07 v2 path 到達維持 = pmdneo_v2_entry_skeleton が adpcmb_dispatch / rhythm_dispatch を call (静的) + pmdneo_v2_entry_marker 0xFD3B <- 0x07 (${MARKER} 件、 動的)"
else
  ng "gate 1: cmd 0x07 v2 path 不成立 (skel_calls_adpcmb=${SKEL_CALLS_ADPCMB} skel_calls_rhythm=${SKEL_CALLS_RHYTHM} marker=${MARKER})"
fi

# ym2610 trace 抽出
ADPCMB_M_2610=$(awk -F'\t' '$3=="FD3C" && $4=="09"' "$ZMEM_2610" | wc -l | tr -d ' ')
RHYTHM_M_2610=$(awk -F'\t' '$3=="FD3D" && $4=="0A"' "$ZMEM_2610" | wc -l | tr -d ' ')
FM_2610=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610" | wc -l | tr -d ' ')
SSG_2610=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')
F2B_2610=$(awk -F'\t' '$2=="A" && $3=="27" && $4=="AA"' "$YMFM_2610" | wc -l | tr -d ' ')

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

ADPCMB_M_2610B=$(awk -F'\t' '$3=="FD3C" && $4=="09"' "$ZMEM_2610B" | wc -l | tr -d ' ')
RHYTHM_M_2610B=$(awk -F'\t' '$3=="FD3D" && $4=="0A"' "$ZMEM_2610B" | wc -l | tr -d ' ')
FM_2610B=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
SSG_2610B=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')
F2B_2610B=$(awk -F'\t' '$2=="A" && $3=="27" && $4=="AA"' "$YMFM_2610B" | wc -l | tr -d ' ')

# --- gate 2: ADPCM-B 接続点 marker (= 0xFD3C <- 0x09、 両 chip 各 1) ---
if [ "$ADPCMB_M_2610" -eq 1 ] && [ "$ADPCMB_M_2610B" -eq 1 ]; then
  ok "gate 2: ADPCM-B 接続点 marker = pmdneo_v2_adpcmb_marker (0xFD3C) <- 0x09 (= PART_PCM、 ADPCM-B dispatch boundary 到達) ym2610 ${ADPCMB_M_2610} 件 / ym2610b ${ADPCMB_M_2610B} 件"
else
  ng "gate 2: ADPCM-B 接続点 marker 不一致 (ym2610=${ADPCMB_M_2610} / ym2610b=${ADPCMB_M_2610B}、 期待 各 1)"
fi

# --- gate 3: rhythm 接続点 marker (= 0xFD3D <- 0x0A、 両 chip 各 1) ---
if [ "$RHYTHM_M_2610" -eq 1 ] && [ "$RHYTHM_M_2610B" -eq 1 ]; then
  ok "gate 3: rhythm 接続点 marker = pmdneo_v2_rhythm_marker (0xFD3D) <- 0x0A (= PART_RHYTHM、 rhythm dispatch boundary 到達) ym2610 ${RHYTHM_M_2610} 件 / ym2610b ${RHYTHM_M_2610B} 件"
else
  ng "gate 3: rhythm 接続点 marker 不一致 (ym2610=${RHYTHM_M_2610} / ym2610b=${RHYTHM_M_2610B}、 期待 各 1)"
fi

# --- gate 4: 既存 v2 dispatch regression ---
if [ "$FM_2610" -eq 4 ] && [ "$FM_2610B" -eq 6 ] && [ "$SSG_2610" -eq 3 ] && [ "$SSG_2610B" -eq 3 ] \
   && [ "$F2B_2610" -eq 1 ] && [ "$F2B_2610B" -eq 1 ]; then
  ok "gate 4: 既存 v2 dispatch 維持 = FM keyon (reg 0x28) ym2610 ${FM_2610} / ym2610b ${FM_2610B} + SSG dispatch (reg 0x08-0x0A 0x0F) ym2610 ${SSG_2610} / ym2610b ${SSG_2610B} + F-2-B (reg 0x27 0xAA) ym2610 ${F2B_2610} / ym2610b ${F2B_2610B} (= 接続点追加後も regression なし)"
else
  ng "gate 4: 既存 v2 dispatch regression (FM ym2610=${FM_2610} 期待 4 / ym2610b=${FM_2610B} 期待 6 / SSG ym2610=${SSG_2610} ym2610b=${SSG_2610B} 期待 各 3 / F-2-B ym2610=${F2B_2610} ym2610b=${F2B_2610B} 期待 各 1)"
fi

# ============================================================
# gate 5: baseline regression (= verify-axis-b-f2b-integration.sh)
# ============================================================
echo "=== gate 5: baseline regression (= verify-axis-b-f2b-integration.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-f2b-integration.sh >/dev/null 2>&1; then
  ok "gate 5: baseline regression = verify-axis-b-f2b-integration.sh 6 gate 全 PASS (= 内部で verify-axis-b-sram-placement 6 + verify-axis-b-v2-entry 7 + verify-fadeout 16 + verify-mute 7 + baseline 9 script + verify-ssg-tone-enable 15 gate を transitively = ADR-0052/0053/0054 + mute/fade/SSG tone-enable regression)"
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
  echo "✅ ALL PASS (= 軸 B 実装 sprint 4 = δ-4 軸 C/G/rhythm 接続点定義 6 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
