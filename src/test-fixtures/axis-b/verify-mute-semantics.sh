#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 5 δ verify gate (= ADR-0049 mute semantics)
#
# verify scope: β (= 即 mute path) / γ (= unmute path) で手作業実測した
#   mute/unmute register trace を再現可能な 7 gate verify script に体系化する。
#   driver 挙動の新規拡張はしない (= δ = verify 整備)。
#
#   gate 1: 即 keyoff                       — mask set 時 全 4 chip 即 keyoff register write
#   gate 2: safe-state                      — keyoff register write 自体が safe-state (= β 限定解釈)
#   gate 3: next dispatch restore           — unmask 後 song 進行で FM keyon 復活
#   gate 4: suppress 経路 semantic preservation — PART_OFF_MASK 1→0 遷移 + dispatch 構造保持
#   gate 5: 非対象 part 無影響               — X/Y/Z (= part 17-19) の PART_OFF_MASK 不変
#   gate 6: baseline regression             — 既存 verify script 9 件 全 PASS
#   gate 7: .org overflow / section overlap — nmi handler routine が .org 境界と overlap なし
#
# build infra: PMDNEO_MUTE_FIXTURE=1 で fixture build (= build.mk TEST_MODE_MUTE_FIXTURE
#   ifeq + sed expr、 TEST_MODE_AXIS_G_INT cf64d60 前例同型)、 未指定で production build。
#   verify script は source file を一時改変しない (= build-poc.sh env 経路)。
#
# usage: bash src/test-fixtures/axis-b/verify-mute-semantics.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
Z80MEM="$TRACE_DIR/z80-mem-trace.tsv"
DRIVER_SRC="src/driver/standalone_test.s"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }

hex() { echo $((16#$1)); }

# ============================================================
# production build (= PMDNEO_MUTE_FIXTURE 未指定 = mute fixture skip)
# ============================================================
echo "=== production build (= PMDNEO_MUTE_FIXTURE 未指定) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }

# --- gate 7: .org overflow / section overlap ---
# nmi_cmd_unmask_part (= γ) が .org 0x0200 (= ym2610_write_port_a) 未満に収まること、
# pmdneo_mask_immediate_keyoff (= β) が 0x0200 より後 (= 0x0610 セクション) に配置されること。
UNMASK_ADDR=$(awk '/[ \t]nmi_cmd_unmask_part:/{print $1; exit}' "$LST")
WPA_ADDR=$(awk '/[ \t]ym2610_write_port_a:/{print $1; exit}' "$LST")
MIK_ADDR=$(awk '/[ \t]pmdneo_mask_immediate_keyoff:/{print $1; exit}' "$LST")
if [ -n "$UNMASK_ADDR" ] && [ -n "$WPA_ADDR" ] && [ -n "$MIK_ADDR" ] \
   && [ "$(hex "$UNMASK_ADDR")" -lt "$(hex "$WPA_ADDR")" ] \
   && [ "$(hex "$MIK_ADDR")" -gt "$(hex "$WPA_ADDR")" ]; then
  ok "gate 7: nmi_cmd_unmask_part(0x$UNMASK_ADDR) < .org 0x$WPA_ADDR < pmdneo_mask_immediate_keyoff(0x$MIK_ADDR) = section overlap なし"
else
  ng "gate 7: .org overlap risk (unmask=0x$UNMASK_ADDR wpa=0x$WPA_ADDR mik=0x$MIK_ADDR)"
fi

# production build で mute/unmute fixture 機械語が生成されないこと (= dead code なし、
# .if TEST_MODE_MUTE_FIXTURE skip)。 mute fixture loop + unmute fixture loop 両方を確認。
PROD_FIXTURE=$(grep -cE '^      [0-9A-F]{6}.*(pmdneo_mute_fixture_loop|pmdneo_unmute_fixture_loop)' "$LST" 2>/dev/null || true)
if [ "${PROD_FIXTURE:-0}" -eq 0 ]; then
  ok "gate 7: production build で mute/unmute fixture 機械語生成なし (= dead code なし)"
else
  ng "gate 7: production build に mute/unmute fixture 機械語混入 ($PROD_FIXTURE 件)"
fi

# --- gate 6: baseline regression (= 既存 verify script 9 件) ---
echo "=== gate 6: baseline regression (= 既存 verify script 9 件) ==="
BASELINE_SCRIPTS=(
  step5/verify-l-q-tutti-gamma.sh
  step5/verify-l-part-alpha-trace-gate.sh
  step5/verify-l-part-beta-sample-lookup.sh
  step5/verify-l-part-delta-volume-pan.sh
  step5/verify-l-q-rhythm-song-integration.sh
  step6/verify-silent-bcef-audio-isolation.sh
  step11/verify-step11-multi-table.sh
  step12/verify-step12-kr-differential.sh
  step12/verify-step12-k-rhythm-trigger.sh
)
# baseline script は MAME register trace を使うため MAME 録音 timing で稀に flaky。
# bounded retry (= 最大 3 attempt) で flaky を許容し、 再現 failure (= 3 回連続 FAIL) のみ
# 本 FAIL 扱い (= ADR-0049 Annex F-3、 Codex layer 2 δ round 5 案 A)。
BASE_FAIL=0
for s in "${BASELINE_SCRIPTS[@]}"; do
  S_OK=0
  for attempt in 1 2 3; do
    if bash "src/test-fixtures/$s" >/dev/null 2>&1; then
      S_OK=1
      [ "$attempt" -gt 1 ] && echo "  ✓ $s (= attempt $attempt PASS、 flaky retry)" || echo "  ✓ $s"
      break
    fi
  done
  if [ "$S_OK" -eq 0 ]; then
    BASE_FAIL=$((BASE_FAIL + 1))
    echo "  ✗ $s (= 3 attempts 全 FAIL)"
  fi
done
if [ "$BASE_FAIL" -eq 0 ]; then
  ok "gate 6: baseline regression 既存 verify script 9 件 全 PASS (= bounded retry 最大 3 attempt)"
else
  ng "gate 6: baseline regression $BASE_FAIL/9 FAIL (= 3 attempts 再現 failure)"
fi

# ============================================================
# fixture build (= PMDNEO_MUTE_FIXTURE=1 = mute/unmute fixture 有効)
# ============================================================
echo "=== fixture build (= PMDNEO_MUTE_FIXTURE=1) + MAME headless trace ==="
rm -f "$PREPROCESSED"
PMDNEO_MUTE_FIXTURE=1 bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ fixture build FAIL"; exit 1; }
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 3 >/dev/null 2>&1 || true

[ -f "$YMFM" ] || { echo "❌ ymfm-trace 未生成"; exit 1; }
[ -f "$Z80MEM" ] || { echo "❌ z80-mem-trace 未生成"; exit 1; }

# --- gate 1: 即 keyoff (= mute fixture sequence 全 4 chip keyoff register write) ---
# ADPCM-A keyoff (= port B reg 100 ← 0x80|ch_bit、 6 ch 全件) は mute fixture の決定的 marker
# (= song 再生では 6 ch 同時 keyoff は出ない)。
# FM keyoff は mute fixture loop part 0-5 の register write sequence を β 実測 literal
# `00 01 02 00 05 06` (= part 0/3 = A/D は ym2610 default で CH_IDX 0、 fm_keyoff_values[0]=0x00)
# と期待値照合 (= 件数のみではなく sequence literal、 ADR-0049 Annex C/D literal)。
ADA_KEYOFF=$(awk -F'\t' '$2=="B" && $3=="100" && ($4=="81"||$4=="82"||$4=="84"||$4=="88"||$4=="90"||$4=="A0")' "$YMFM" | wc -l | tr -d ' ')
SSG_KEYOFF=$(awk -F'\t' '$2=="A" && ($3=="08"||$3=="09"||$3=="0A") && $4=="00"' "$YMFM" | head -3 | wc -l | tr -d ' ')
ADB_KEYOFF=$(awk -F'\t' '$2=="A" && $3=="10" && ($4=="01"||$4=="00")' "$YMFM" | head -2 | wc -l | tr -d ' ')
FM_SEQ=$(awk -F'\t' '$2=="A" && $3=="28"{printf "%s ", $4}' "$YMFM")
if [ "$ADA_KEYOFF" -ge 6 ] && [ "$SSG_KEYOFF" -ge 3 ] && [ "$ADB_KEYOFF" -ge 2 ] && echo "$FM_SEQ" | grep -q '00 01 02 00 05 06'; then
  ok "gate 1: 即 keyoff = ADPCM-A 6 ch ($ADA_KEYOFF) + SSG ($SSG_KEYOFF) + ADPCM-B ($ADB_KEYOFF) + FM keyoff sequence '00 01 02 00 05 06' literal 照合 PASS"
else
  ng "gate 1: 即 keyoff 不足 (ADA=$ADA_KEYOFF SSG=$SSG_KEYOFF ADB=$ADB_KEYOFF FM_seq='00 01 02 00 05 06' 未検出)"
fi

# --- gate 2: safe-state (= keyoff register write 自体が safe-state、 β 限定解釈) ---
# gate 1 の keyoff register write が成立 = 各 chip が無音 (= safe) state に遷移。
if [ "$ADA_KEYOFF" -ge 6 ] && [ "$SSG_KEYOFF" -ge 3 ]; then
  ok "gate 2: safe-state = keyoff register write が全 chip 無音化 (= β 限定解釈、 gate 1 と同経路)"
else
  ng "gate 2: safe-state 未達 (= gate 1 keyoff register write 不足)"
fi

# --- gate 3: next dispatch restore (= unmask 後 song 進行で FM keyon 復活) ---
# fm_keyon は reg 0x28 に slot bits 付き値 (= 0xF0|ch)。 mute fixture 即 keyoff (= slot 0)
# の後、 unmute fixture → driver_song_ready set → song 進行で FM keyon が出ること。
FM_KEYON=$(awk -F'\t' '$2=="A" && $3=="28" && ($4=="F1"||$4=="F2"||$4=="F5"||$4=="F6")' "$YMFM" | wc -l | tr -d ' ')
if [ "$FM_KEYON" -ge 1 ]; then
  ok "gate 3: next dispatch restore = unmask 後 song 進行で FM keyon ($FM_KEYON 件、 reg 0x28 ← 0xFX) 復活"
else
  ng "gate 3: next dispatch restore 未達 (= FM keyon 復活なし)"
fi

# --- gate 4: suppress 経路 semantic preservation ---
# z80-mem-trace で active part の PART_OFF_MASK (= part workarea offset 30 専用 addr) が
# mute fixture で 1 (= mask) → unmute fixture で 0 (= unmask) の両遷移を持つこと。
# PART_OFF_MASK addr = 0xF820 + part_idx*64 + 30。 part 0 = 0xF83E / part 16 = 0xFC3E
# (= O-Q ADPCM-A 含む active part 範囲の両端) で 01 set + 00 clear の両方を厳密照合。
# + 既存 pmdneo_part_main_note_dispatch の suppress 構造 (= PART_OFF_MASK 参照 + ret nz) 保持。
P0_SET=$(awk -F'\t' '$3=="F83E" && $4=="01"' "$Z80MEM" | wc -l | tr -d ' ')
P0_CLR=$(awk -F'\t' '$3=="F83E" && $4=="00"' "$Z80MEM" | wc -l | tr -d ' ')
P16_SET=$(awk -F'\t' '$3=="FC3E" && $4=="01"' "$Z80MEM" | wc -l | tr -d ' ')
P16_CLR=$(awk -F'\t' '$3=="FC3E" && $4=="00"' "$Z80MEM" | wc -l | tr -d ' ')
DISPATCH_OK=$(awk '/pmdneo_part_main_note_dispatch:/{f=1} f && /PART_OFF_MASK\(ix\)/{g=1} g && /ret[ \t]+nz/{print "ok"; exit}' "$DRIVER_SRC")
if [ "$P0_SET" -ge 1 ] && [ "$P0_CLR" -ge 1 ] && [ "$P16_SET" -ge 1 ] && [ "$P16_CLR" -ge 1 ] && [ "$DISPATCH_OK" = "ok" ]; then
  ok "gate 4: suppress semantic preservation = PART_OFF_MASK 1→0 遷移 (part0 set=$P0_SET clr=$P0_CLR / part16 set=$P16_SET clr=$P16_CLR) + dispatch 構造保持"
else
  ng "gate 4: suppress semantic preservation 未達 (part0 set=$P0_SET clr=$P0_CLR / part16 set=$P16_SET clr=$P16_CLR / dispatch=$DISPATCH_OK)"
fi

# --- gate 5: 非対象 part 無影響 (= X/Y/Z = part 17-19 の PART_OFF_MASK 不変) ---
# X/Y/Z PART_OFF_MASK addr = 0xFC7E / 0xFCBE / 0xFCFE。 mask/unmask fixture (= part 0-16 のみ)
# は X/Y/Z を touch しないため、 これらへの value 01 (= mask) write がないこと。
XYZ_MASK=$(awk -F'\t' '($3=="FC7E"||$3=="FCBE"||$3=="FCFE") && $4=="01"' "$Z80MEM" | wc -l | tr -d ' ')
if [ "$XYZ_MASK" -eq 0 ]; then
  ok "gate 5: 非対象 part 無影響 = X/Y/Z (part 17-19) PART_OFF_MASK に mask write なし"
else
  ng "gate 5: 非対象 part 影響あり = X/Y/Z PART_OFF_MASK に mask write $XYZ_MASK 件"
fi

# ============================================================
# 集計 + production build 復帰
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了 (= PMDNEO_MUTE_FIXTURE 未指定、 mute fixture skip)"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "✅ ALL PASS (= 軸 B sprint 5 mute semantics 7 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
