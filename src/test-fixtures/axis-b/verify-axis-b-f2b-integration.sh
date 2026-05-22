#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 3 γ verify gate (= ADR-0054 F-2-B ch3 4-op integration)
#
# verify scope: ADR-0054 §決定 5 の verify gate 6 件を再現可能な verify script に
#   体系化する。 sub-sprint β (= PR #84) で実装した F-2-B 並設 proof path
#   (= pmdneo_v2_fm3ext_dispatch) を gate 1-6 で検証。 driver 改修なし。
#
#   --- cmd 0x07 v2 path gate (= static + V2 fixture marker trace) ---
#   gate 1: cmd 0x07 v2 path 到達維持 — pmdneo_v2_entry_skeleton が
#                                       pmdneo_v2_fm3ext_dispatch を call (.lst 静的)
#                                       + V2 fixture marker 0xFD3B <- 0x07 (動的)
#   --- F-2-B trace gate (= V2 fixture build、 ym2610 / ym2610b 両 chip) ---
#   gate 2: reg 0x27 bit 7 set       — reg 0x27 <- 0xAA (= bit 7 = CH3 individual
#                                      mode enable、 init 0x2A | 0x80) 各 1 write
#   gate 3: ch3 op1-4 individual reg — reg 0x42/0x46/0x4A/0x4E <- 0x20/0x21/0x22/
#                                      0x23 (= ch3 op1-4 per-op individual TL) 各 1
#   gate 4: 既存 FM/SSG v2 dispatch — FM 6ch keyon (reg 0x28、 ym2610 4 / ym2610b
#                                      6) + SSG 3ch dispatch (reg 0x08-0x0A 0x0F、
#                                      各 3) が F-2-B 追加後も維持
#   --- static / baseline gate ---
#   gate 6: .org overflow / overlap — v2 並設 routine 5 件が 0x0610 セクション
#                                      + 0x0066 セクション max addr < 0x0100
#   gate 5: baseline regression     — verify-axis-b-sram-placement.sh 6 gate (=
#                                      内部で verify-axis-b-v2-entry.sh 7 gate +
#                                      verify-fadeout 16 + mute 7 + verify-ssg 15
#                                      gate を transitively = ADR-0052/0053 +
#                                      mute/fade/SSG tone-enable regression)
#
# 注: F-2-B = 簡易実装 trace-proof (= ADR-0054 §決定 2)。 検証は register trace
#   primary gate (= 実音 individual mode 完全動作は scope-out)。
#
# fixture: TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml、 両 chip。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-f2b-integration.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_2610="/tmp/f2b-verify-ym2610-ymfm.tsv"
ZMEM_2610="/tmp/f2b-verify-ym2610-zmem.tsv"
YMFM_2610B="/tmp/f2b-verify-ym2610b-ymfm.tsv"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# production build (= ym2610 default) — gate 1 静的 / gate 6
# ============================================================
echo "=== production build (= ym2610 default) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "❌ .lst 未生成"; exit 1; }

# --- gate 1 (静的部): skeleton が fm3ext_dispatch を call ---
SKEL_CALLS_F2B=$(awk '
  /[ \t]pmdneo_v2_entry_skeleton:/{seg=1; next}
  seg && /[A-Za-z0-9_]:[ \t]*$/{seg=0}
  seg && /call[ \t]+pmdneo_v2_fm3ext_dispatch/{print "ok"; exit}
' "$LST")

# --- gate 6: .org overflow / section overlap ---
G6BAD=0
G6DET=""
for label in nmi_cmd_7_play_song_v2 pmdneo_v2_entry_skeleton pmdneo_v2_fm_dispatch pmdneo_v2_ssg_dispatch pmdneo_v2_fm3ext_dispatch; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":"){print $1; exit}' "$LST")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G6BAD=$((G6BAD + 1)); G6DET="$G6DET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST" | sort | tail -1)
if [ "$G6BAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "gate 6: v2 並設 routine 5 件全 >= 0x0610 (= pmdneo_v2_fm3ext_dispatch 含む) + 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow / overlap なし)"
else
  ng "gate 6: .org overflow / overlap risk (bad=${G6BAD} max0066=0x${MAX0066:-NONE}${G6DET})"
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
if [ "$SKEL_CALLS_F2B" = "ok" ] && [ "$MARKER" -ge 1 ]; then
  ok "gate 1: cmd 0x07 v2 path 到達維持 = pmdneo_v2_entry_skeleton が pmdneo_v2_fm3ext_dispatch を call (静的) + pmdneo_v2_entry_marker 0xFD3B <- 0x07 (${MARKER} 件、 動的)"
else
  ng "gate 1: cmd 0x07 v2 path 不成立 (skel_calls_f2b=${SKEL_CALLS_F2B} marker=${MARKER})"
fi

# ym2610 trace 抽出
R27_2610=$(awk -F'\t' '$2=="A" && $3=="27" && $4=="AA"' "$YMFM_2610" | wc -l | tr -d ' ')
TL42_2610=$(awk -F'\t' '$2=="A" && $3=="42" && $4=="20"' "$YMFM_2610" | wc -l | tr -d ' ')
TL46_2610=$(awk -F'\t' '$2=="A" && $3=="46" && $4=="21"' "$YMFM_2610" | wc -l | tr -d ' ')
TL4A_2610=$(awk -F'\t' '$2=="A" && $3=="4A" && $4=="22"' "$YMFM_2610" | wc -l | tr -d ' ')
TL4E_2610=$(awk -F'\t' '$2=="A" && $3=="4E" && $4=="23"' "$YMFM_2610" | wc -l | tr -d ' ')
FM_2610=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610" | wc -l | tr -d ' ')
SSG_2610=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4=="0F"' "$YMFM_2610" | wc -l | tr -d ' ')

# ============================================================
# V2 fixture build (= ym2610b) + MAME headless trace
# ============================================================
echo "=== V2 fixture build (= ym2610b) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610b >/dev/null 2>&1 \
  || { echo "❌ V2 fixture (ym2610b) build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 10 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成 (ym2610b)"; exit 1; }
cp "$YMFM" "$YMFM_2610B"

R27_2610B=$(awk -F'\t' '$2=="A" && $3=="27" && $4=="AA"' "$YMFM_2610B" | wc -l | tr -d ' ')
TL42_2610B=$(awk -F'\t' '$2=="A" && $3=="42" && $4=="20"' "$YMFM_2610B" | wc -l | tr -d ' ')
TL46_2610B=$(awk -F'\t' '$2=="A" && $3=="46" && $4=="21"' "$YMFM_2610B" | wc -l | tr -d ' ')
TL4A_2610B=$(awk -F'\t' '$2=="A" && $3=="4A" && $4=="22"' "$YMFM_2610B" | wc -l | tr -d ' ')
TL4E_2610B=$(awk -F'\t' '$2=="A" && $3=="4E" && $4=="23"' "$YMFM_2610B" | wc -l | tr -d ' ')
FM_2610B=$(awk -F'\t' '$2=="A" && $3=="28" && $4 ~ /^F[0-9A-F]$/' "$YMFM_2610B" | wc -l | tr -d ' ')
SSG_2610B=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4=="0F"' "$YMFM_2610B" | wc -l | tr -d ' ')

# --- gate 2: reg 0x27 bit 7 set (= 0xAA、 両 chip 各 1) ---
if [ "$R27_2610" -eq 1 ] && [ "$R27_2610B" -eq 1 ]; then
  ok "gate 2: reg 0x27 bit 7 set = reg 0x27 <- 0xAA (= CH3 individual mode enable、 init 0x2A | 0x80) ym2610 ${R27_2610} 件 / ym2610b ${R27_2610B} 件"
else
  ng "gate 2: reg 0x27 0xAA write 数 不一致 (ym2610=${R27_2610} / ym2610b=${R27_2610B}、 期待 各 1)"
fi

# --- gate 3: ch3 op1-4 individual register write (= reg 0x42/0x46/0x4A/0x4E per-op 異値、 両 chip 各 1) ---
if [ "$TL42_2610" -eq 1 ] && [ "$TL46_2610" -eq 1 ] && [ "$TL4A_2610" -eq 1 ] && [ "$TL4E_2610" -eq 1 ] \
   && [ "$TL42_2610B" -eq 1 ] && [ "$TL46_2610B" -eq 1 ] && [ "$TL4A_2610B" -eq 1 ] && [ "$TL4E_2610B" -eq 1 ]; then
  ok "gate 3: ch3 op1-4 individual register write = reg 0x42<-0x20 / 0x46<-0x21 / 0x4A<-0x22 / 0x4E<-0x23 (= per-op 異値) ym2610 各 1 (${TL42_2610}/${TL46_2610}/${TL4A_2610}/${TL4E_2610}) / ym2610b 各 1 (${TL42_2610B}/${TL46_2610B}/${TL4A_2610B}/${TL4E_2610B})"
else
  ng "gate 3: ch3 op1-4 individual register write 不一致 (ym2610 0x42=${TL42_2610}/0x46=${TL46_2610}/0x4A=${TL4A_2610}/0x4E=${TL4E_2610}、 ym2610b 0x42=${TL42_2610B}/0x46=${TL46_2610B}/0x4A=${TL4A_2610B}/0x4E=${TL4E_2610B}、 期待 各 1)"
fi

# --- gate 4: 既存 FM/SSG v2 dispatch regression ---
if [ "$FM_2610" -eq 4 ] && [ "$FM_2610B" -eq 6 ] && [ "$SSG_2610" -eq 3 ] && [ "$SSG_2610B" -eq 3 ]; then
  ok "gate 4: 既存 FM/SSG v2 dispatch 維持 = FM keyon (reg 0x28) ym2610 ${FM_2610} (= B/C/E/F) / ym2610b ${FM_2610B} (= 全 6ch) + SSG dispatch (reg 0x08-0x0A 0x0F) ym2610 ${SSG_2610} / ym2610b ${SSG_2610B} (= F-2-B 追加後も regression なし)"
else
  ng "gate 4: 既存 FM/SSG v2 dispatch regression (FM ym2610=${FM_2610} 期待 4 / ym2610b=${FM_2610B} 期待 6 / SSG ym2610=${SSG_2610} ym2610b=${SSG_2610B} 期待 各 3)"
fi

# ============================================================
# gate 5: baseline regression (= verify-axis-b-sram-placement.sh)
# ============================================================
echo "=== gate 5: baseline regression (= verify-axis-b-sram-placement.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-sram-placement.sh >/dev/null 2>&1; then
  ok "gate 5: baseline regression = verify-axis-b-sram-placement.sh 6 gate 全 PASS (= 内部で verify-axis-b-v2-entry.sh 7 gate + verify-fadeout 16 + verify-mute 7 + baseline 9 script + verify-ssg-tone-enable 15 gate を transitively = ADR-0052/0053 + mute/fade/SSG tone-enable regression)"
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
  echo "✅ ALL PASS (= 軸 B 実装 sprint 3 = δ-3 F-2-B ch3 4-op integration 6 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
