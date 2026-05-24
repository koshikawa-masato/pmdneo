#!/usr/bin/env bash
#
# PMDNEO ADR-0067 sub-sprint δ verify script = 全 16 ch fixture 駆動 trace gate verify
# (= ADR-0067 §決定 5 δ 6 gate literal、 機能 verify only、 trace-equivalence は ADR-0068 future)
#
# verify scope: ADR-0067 §決定 5 6 gate:
#   gate-1 = production sha256 維持 (= b15883fe... literal 一致)
#   gate-2 = v2 fixture build PASS + active slot driven (= chip target 別 = ym2610 primary 8 slot + ym2610b secondary 11 slot)
#   gate-3 = 全 16 ch chip 別代表 register literal 期待値出力 (= FM/SSG/ADPCM-B/ADPCM-A 4 chip 別、 ym2610 primary + ym2610b secondary)
#   gate-4 = .org section overflow なし
#   gate-5 = representative 2 script regression (= verify-axis-b-v2-song-playback.sh + verify-axis-b-v2-roadmap3-dispatch.sh、 ADR-0067 §決定 5 gate-5 literal「ADR-0049〜0059 既存 verify script ALL PASS 維持」 を v2 driver 関連 representative 2 script で direct cover、 他 ADR-0049〜0057 系 verify script は production sha256 維持 = m1 ROM byte-identical = transitively regression OK)
#   gate-6 = IRQ tick 処理量 trace window 適合 (= threshold IRQ count >= 2000、 γ 後 baseline 2261 件 - 12% 余白)
#
# ADPCM-A gate-3 仕様 (= 主軸 verified + Codex plan review round 1/2 must-fix 反映):
#   現行 driver `pmdneo_rhythm_event_trigger` (= standalone_test.s:5295-5345) は **L ch (= ch 0) 固定** で、
#   各 drum (= BD/SD/CYM/HH/TOM/RIM) は同 6 件 register write を ym2610_write_port_b 経由で発行:
#     port B reg 0x10 = START_LSB (= drum 別 sample addr 差分)
#     port B reg 0x18 = START_MSB (= 全 drum 0x00 固定、 sample 16-bit space 内)
#     port B reg 0x20 = STOP_LSB (= drum 別 sample addr 差分)
#     port B reg 0x28 = STOP_MSB (= 全 drum 0x00 固定)
#     port B reg 0x08 = vol/pan 0xDF 固定 (= 0xC0 pan | 0x1F vol)
#     port B reg 0x00 = keyon mask 0x01 (= L ch bit 0、 全 drum 共通)
#   ADR-0067 §決定 5 gate-3 ADPCM-A literal「per-ch keyon 0x00 + per-ch start LSB/MSB 0x10-0x15 系」 は
#   ADR 起票時の理論的 register map で、 実 driver = L ch 固定 + sample addr 差分仕様
#   (= ADR-0026 §決定 4「L ch (= ch 0) 暫定占有 scaffold」 由来)。 ADR 修正は scope-out。
#
# FM gate-3 仕様 (= Codex plan review round 1 must-fix 2 反映):
#   FM keyon = 全 ch port A reg 0x28 一本 (= fm_keyon_values F0/F1/F2/F4/F5/F6、 standalone_test.s:1238/1523)。
#   port B 経由は fnum/TL 等 ch >= 3 のみ (= standalone_test.s:1045/4397、 ym2610b 限定)。
#
# gate-5 scope literal (= Codex plan review round 1 must-fix 3 反映):
#   ADR-0067 §決定 5 gate-5 literal「ADR-0049〜0059 既存 verify script ALL PASS 維持」 を
#   **v2 driver 関連 representative 2 script** で direct cover、 他 script は production sha256 維持
#   (= gate-1) によって transitively regression OK。
#
# driver touch なし (= ADR-0067 §決定 7 allowed-touch literal「driver source 完全不変、
#   新規 verify script のみ追加」 遵守)。 既存 verify script 完全不変。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-fixture-expansion-delta.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
M1="$TEMPLATE_BUILD/rom/243-m1.m1"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_DELTA_2610="/tmp/v2-delta-ymfm-ym2610.tsv"
ZMEM_DELTA_2610="/tmp/v2-delta-zmem-ym2610.tsv"
YMFM_DELTA_2610B="/tmp/v2-delta-ymfm-ym2610b.tsv"
ZMEM_DELTA_2610B="/tmp/v2-delta-zmem-ym2610b.tsv"
LST_DELTA_2610="/tmp/v2-delta-ym2610.lst"
LST_DELTA_2610B="/tmp/v2-delta-ym2610b.lst"

EXPECTED_PROD_SHA="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

count_writes() { awk -F'\t' -v p="$1" -v r="$2" '$2==p && $3==r' "$3" | wc -l | tr -d ' '; }
count_writes_value() { awk -F'\t' -v p="$1" -v r="$2" -v v="$3" '$2==p && $3==r && $4==v' "$4" | wc -l | tr -d ' '; }
count_unique() { awk -F'\t' -v p="$1" -v r="$2" '$2==p && $3==r {print $4}' "$3" | sort -u | wc -l | tr -d ' '; }

# ============================================================
# 共通 helper: 指定 chip target で v2 fixture build + MAME trace capture
# ============================================================
build_and_trace() {
  local chip="$1"
  local ymfm_out="$2"
  local zmem_out="$3"
  local lst_out="$4"

  rm -f "$PREPROCESSED"
  PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 bash scripts/build-poc.sh --chip "$chip" >/dev/null 2>&1 \
    || { echo "NG  v2 fixture build FAIL (chip=$chip)"; exit 1; }
  [ -f "$LST" ] || { echo "NG  .lst 未生成 (chip=$chip)"; exit 1; }
  cp "$LST" "$lst_out"

  rm -rf "$TRACE_DIR"
  bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
  [ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成 (chip=$chip、 MAME run 失敗 or trace 出力なし)"; exit 1; }
  [ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 未生成 (chip=$chip)"; exit 1; }
  cp "$YMFM" "$ymfm_out"
  cp "$ZMEM" "$zmem_out"
}

# ============================================================
# gate-1 = production sha256 維持 (= b15883fe... literal 一致)
# ============================================================
echo "=== gate-1 production sha256 維持 verify ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 || { echo "NG  production build FAIL"; exit 1; }
PROD_SHA=$(shasum -a 256 "$M1" | awk '{print $1}')
if [ "$PROD_SHA" = "$EXPECTED_PROD_SHA" ]; then
  ok "gate-1 (production sha256 維持): m1 sha256 = ${PROD_SHA} (= expected baseline literal 一致、 通算 ADR-0058〜0064〜0067 α/β/γ 継承、 β/γ 改変後も維持)"
else
  ng "gate-1 (production sha256 維持) 不成立 (prod_sha=${PROD_SHA} 期待 ${EXPECTED_PROD_SHA})"
fi

# ============================================================
# ym2610 target = primary v2 fixture build + trace capture
# ============================================================
echo "=== ym2610 target = primary v2 fixture build + MAME trace ==="
build_and_trace "ym2610" "$YMFM_DELTA_2610" "$ZMEM_DELTA_2610" "$LST_DELTA_2610"

# ============================================================
# ym2610b target = secondary v2 fixture build + trace capture
# ============================================================
echo "=== ym2610b target = secondary v2 fixture build + MAME trace ==="
build_and_trace "ym2610b" "$YMFM_DELTA_2610B" "$ZMEM_DELTA_2610B" "$LST_DELTA_2610B"

# ============================================================
# gate-2 = v2 fixture build PASS + active slot driven (= ym2610 8 slot + ym2610b 11 slot)
#
# active slot = pmdneo_v2_song_init 内 FLAGS=1 set されている slot:
#   ym2610: slot 0 (FM B) / slot 1 (SSG G) / slot 3 (FM C) / slot 5 (FM E) /
#           slot 7 (SSG H) / slot 8 (SSG I) / slot 9 (ADPCM-B J) / slot 10 (rhythm K full)
#           = 8 slot (= slot 2/4/6 = FM A/D/F は chip target 別 active policy で skip)
#   ym2610b: + slot 2 (FM A) + slot 4 (FM D) + slot 6 (FM F) = 11 slot
#
# z80-mem-trace の slot N FLAGS offset 9 (= ADR-0058 PMDNEO_V2_PART_OFF_FLAGS = 9) を確認:
#   slot N FLAGS addr = 0xFD79 + N*12 + 9 = 0xFD82 (slot 0) / 0xFD8E (slot 1) / 0xFD9A (slot 2) /
#     0xFDA6 (slot 3) / 0xFDB2 (slot 4) / 0xFDBE (slot 5) / 0xFDCA (slot 6) / 0xFDD6 (slot 7) /
#     0xFDE2 (slot 8) / 0xFDEE (slot 9) / 0xFDFA (slot 10)
#   value 01 (= active) write が init 段階で発生
# ============================================================
echo "=== gate-2 v2 fixture build PASS + active slot driven (chip target 別) ==="
# ym2610 active slot = 0/1/3/5/7/8/9/10 = 8 slot
YM2610_ACTIVE_COUNT=0
for offset in FD82 FD8E FDA6 FDBE FDD6 FDE2 FDEE FDFA; do
  cnt=$(count_writes_value - "$offset" "01" "$ZMEM_DELTA_2610")
  # port column for z80-mem-trace = "-" 表記 想定、 awk 第 2 col の filter は z80-mem では使えない
  # 既存 script では $3 (= addr) と $4 (= value) 使う pattern なので、 ここも同じ
  cnt=$(awk -F'\t' -v r="$offset" -v v="01" '$3==r && $4==v' "$ZMEM_DELTA_2610" | wc -l | tr -d ' ')
  if [ "$cnt" -ge 1 ]; then
    YM2610_ACTIVE_COUNT=$((YM2610_ACTIVE_COUNT + 1))
  fi
done
# ym2610b active slot = 0/1/2/3/4/5/6/7/8/9/10 = 11 slot
YM2610B_ACTIVE_COUNT=0
for offset in FD82 FD8E FD9A FDA6 FDB2 FDBE FDCA FDD6 FDE2 FDEE FDFA; do
  cnt=$(awk -F'\t' -v r="$offset" -v v="01" '$3==r && $4==v' "$ZMEM_DELTA_2610B" | wc -l | tr -d ' ')
  if [ "$cnt" -ge 1 ]; then
    YM2610B_ACTIVE_COUNT=$((YM2610B_ACTIVE_COUNT + 1))
  fi
done
if [ "$YM2610_ACTIVE_COUNT" -eq 8 ] && [ "$YM2610B_ACTIVE_COUNT" -eq 11 ]; then
  ok "gate-2 (v2 fixture build PASS + active slot driven): ym2610 active slot = ${YM2610_ACTIVE_COUNT} (期待 8 = FM B/C/E + SSG G/H/I + ADPCM-B J + rhythm K) + ym2610b active slot = ${YM2610B_ACTIVE_COUNT} (期待 11 = + FM A/D/F)"
else
  ng "gate-2 (v2 fixture build PASS + active slot driven) 不成立 (ym2610 active=${YM2610_ACTIVE_COUNT} 期待 8 / ym2610b active=${YM2610B_ACTIVE_COUNT} 期待 11)"
fi

# ============================================================
# gate-3 = 全 16 ch chip 別代表 register literal 期待値出力
#
# ym2610 primary expected (= 13 ch audible literal):
#   FM 3 ch B/C/E = port A reg 0x28 value F1/F2/F5 each >= 1
#   SSG 3 ch G/H/I = port A reg 0x00-0x05 (tone period) + 0x07 (mixer) + 0x08-0x0A (volume) write
#   ADPCM-B J = port A reg 0x10 (keyon bit 7) + 0x11 (pan) + 0x12/0x13 (start) + 0x14/0x15 (stop) + 0x19/0x1A (delta-N) + 0x1B (volume) write
#   ADPCM-A K full (= 6 drum 順次 trigger via pmdneo_rhythm_event_trigger):
#     port B reg 0x00 value 0x01 (= L ch keyon mask、 全 drum 共通) write >= 6 件
#     port B reg 0x08 value 0xDF (= vol/pan 固定) write >= 6 件
#     port B reg 0x10 (= START_LSB) write >= 6 件 + unique value 件数 >= 6 (= 6 drum sample addr LSB 差分)
#     port B reg 0x18 (= START_MSB) write >= 6 件 + value 0x00 出現 (= 全 drum 固定)
#     port B reg 0x20 (= STOP_LSB) write >= 6 件 + unique value 件数 >= 6
#     port B reg 0x28 (= STOP_MSB) write >= 6 件 + value 0x00 出現
#
# ym2610b secondary expected (= + FM A/D/F):
#   FM 6 ch + port A reg 0x28 value F0/F4/F6 each >= 1
# ============================================================
echo "=== gate-3 全 16 ch chip 別代表 register literal 期待値出力 (= ym2610 primary + ym2610b secondary) ==="

# --- FM gate-3 (= ym2610 primary) ---
G3_FM_FAIL=""
for keyon_val in F1 F2 F5; do
  cnt=$(awk -F'\t' -v v="$keyon_val" '$2=="A" && $3=="28" && $4==v' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
  if [ "$cnt" -lt 1 ]; then
    G3_FM_FAIL="${G3_FM_FAIL} ym2610.A.28.${keyon_val}=${cnt}"
  fi
done
# --- FM gate-3 (= ym2610b secondary) ---
for keyon_val in F0 F1 F2 F4 F5 F6; do
  cnt=$(awk -F'\t' -v v="$keyon_val" '$2=="A" && $3=="28" && $4==v' "$YMFM_DELTA_2610B" | wc -l | tr -d ' ')
  if [ "$cnt" -lt 1 ]; then
    G3_FM_FAIL="${G3_FM_FAIL} ym2610b.A.28.${keyon_val}=${cnt}"
  fi
done

# --- SSG gate-3 (= ym2610 primary、 G/H/I 3 ch + mixer + volume) ---
G3_SSG_FAIL=""
for reg in 00 01 02 03 04 05 07; do
  cnt=$(awk -F'\t' -v r="$reg" '$2=="A" && $3==r' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
  if [ "$cnt" -lt 1 ]; then
    G3_SSG_FAIL="${G3_SSG_FAIL} A.${reg}=${cnt}"
  fi
done
# SSG ch G volume literal 0x0F + ch H/I volume write
SSG_VOL_G=$(awk -F'\t' '$2=="A" && $3=="08" && $4=="0F"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$SSG_VOL_G" -lt 1 ] && G3_SSG_FAIL="${G3_SSG_FAIL} A.08.0F=${SSG_VOL_G}"
for reg in 09 0A; do
  cnt=$(awk -F'\t' -v r="$reg" '$2=="A" && $3==r' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
  if [ "$cnt" -lt 1 ]; then
    G3_SSG_FAIL="${G3_SSG_FAIL} A.${reg}=${cnt}"
  fi
done

# --- ADPCM-B gate-3 (= ym2610 primary、 keyon + pan + start + stop + delta-N + volume) ---
G3_ADPCMB_FAIL=""
# keyon = port A reg 0x10 value bit 7 set (= 0x80 以上)、 hex first char が 8/9/A-F なら bit 7 set
# (= awk strtonum() は BSD awk 非対応のため hex string regex で代替)
ADPCMB_KEYON=$(awk -F'\t' '$2=="A" && $3=="10" && $4 ~ /^[89A-Fa-f]/' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$ADPCMB_KEYON" -lt 1 ] && G3_ADPCMB_FAIL="${G3_ADPCMB_FAIL} keyon(A.10.>=0x80)=${ADPCMB_KEYON}"
for reg in 11 12 13 14 15 19 1A 1B; do
  cnt=$(awk -F'\t' -v r="$reg" '$2=="A" && $3==r' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
  if [ "$cnt" -lt 1 ]; then
    G3_ADPCMB_FAIL="${G3_ADPCMB_FAIL} A.${reg}=${cnt}"
  fi
done

# --- ADPCM-A gate-3 (= L ch 固定 + sample addr 差分 + keyon mask repeated、 6 drum 順次 trigger) ---
# trace TSV では port B の reg は 3 桁 hex (= 0x100-0x1FF) で記録される:
#   reg 0x100 = ADPCM-A keyon mask (= ADR-0067 §決定 5 ADPCM-A literal「per-ch keyon 0x00」 = trace 表記 100)
#   reg 0x108 = L ch volume (= literal 0x08 = trace 108)
#   reg 0x110 = L ch START_LSB (= literal 0x10 = trace 110)
#   reg 0x118 = L ch START_MSB (= literal 0x18 = trace 118)
#   reg 0x120 = L ch STOP_LSB  (= literal 0x20 = trace 120)
#   reg 0x128 = L ch STOP_MSB  (= literal 0x28 = trace 128)
G3_ADPCMA_FAIL=""
# keyon mask = port B reg 0x100 value 0x01 (= L ch bit 0) write >= 6 件
ADPCMA_KEYON=$(awk -F'\t' '$2=="B" && $3=="100" && $4=="01"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$ADPCMA_KEYON" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.100.01=${ADPCMA_KEYON}(期待>=6)"
# vol/pan = port B reg 0x108 value 0xDF write >= 6 件
ADPCMA_VOL=$(awk -F'\t' '$2=="B" && $3=="108" && $4=="DF"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$ADPCMA_VOL" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.108.DF=${ADPCMA_VOL}(期待>=6)"
# START_LSB = port B reg 0x110 write >= 6 件 + unique value 件数 >= 6 (= drum 別差分)
ADPCMA_START_LSB_CNT=$(awk -F'\t' '$2=="B" && $3=="110"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
ADPCMA_START_LSB_UNIQ=$(awk -F'\t' '$2=="B" && $3=="110" {print $4}' "$YMFM_DELTA_2610" | sort -u | wc -l | tr -d ' ')
[ "$ADPCMA_START_LSB_CNT" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.110.cnt=${ADPCMA_START_LSB_CNT}(期待>=6)"
[ "$ADPCMA_START_LSB_UNIQ" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.110.uniq=${ADPCMA_START_LSB_UNIQ}(期待>=6)"
# START_MSB = port B reg 0x118 write >= 6 件 + value 0x00 出現
ADPCMA_START_MSB_CNT=$(awk -F'\t' '$2=="B" && $3=="118"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
ADPCMA_START_MSB_ZERO=$(awk -F'\t' '$2=="B" && $3=="118" && $4=="00"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$ADPCMA_START_MSB_CNT" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.118.cnt=${ADPCMA_START_MSB_CNT}(期待>=6)"
[ "$ADPCMA_START_MSB_ZERO" -lt 1 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.118.00=${ADPCMA_START_MSB_ZERO}(期待>=1)"
# STOP_LSB = port B reg 0x120 write >= 6 件 + unique value 件数 >= 6
ADPCMA_STOP_LSB_CNT=$(awk -F'\t' '$2=="B" && $3=="120"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
ADPCMA_STOP_LSB_UNIQ=$(awk -F'\t' '$2=="B" && $3=="120" {print $4}' "$YMFM_DELTA_2610" | sort -u | wc -l | tr -d ' ')
[ "$ADPCMA_STOP_LSB_CNT" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.120.cnt=${ADPCMA_STOP_LSB_CNT}(期待>=6)"
[ "$ADPCMA_STOP_LSB_UNIQ" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.120.uniq=${ADPCMA_STOP_LSB_UNIQ}(期待>=6)"
# STOP_MSB = port B reg 0x128 write >= 6 件 + value 0x00 出現
ADPCMA_STOP_MSB_CNT=$(awk -F'\t' '$2=="B" && $3=="128"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
ADPCMA_STOP_MSB_ZERO=$(awk -F'\t' '$2=="B" && $3=="128" && $4=="00"' "$YMFM_DELTA_2610" | wc -l | tr -d ' ')
[ "$ADPCMA_STOP_MSB_CNT" -lt 6 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.128.cnt=${ADPCMA_STOP_MSB_CNT}(期待>=6)"
[ "$ADPCMA_STOP_MSB_ZERO" -lt 1 ] && G3_ADPCMA_FAIL="${G3_ADPCMA_FAIL} B.128.00=${ADPCMA_STOP_MSB_ZERO}(期待>=1)"

# --- gate-3 summary ---
if [ -z "$G3_FM_FAIL" ] && [ -z "$G3_SSG_FAIL" ] && [ -z "$G3_ADPCMB_FAIL" ] && [ -z "$G3_ADPCMA_FAIL" ]; then
  ok "gate-3 (全 16 ch chip 別代表 register literal 期待値出力): FM (= ym2610 B/C/E + ym2610b A/D/F port A reg 0x28 keyon) + SSG (= G/H/I tone period + mixer + volume) + ADPCM-B (= keyon + pan + start + stop + delta-N + volume) + ADPCM-A (= L ch 固定 6 drum trigger = keyon mask 0x01 x ${ADPCMA_KEYON} + vol 0xDF x ${ADPCMA_VOL} + START_LSB uniq ${ADPCMA_START_LSB_UNIQ}/${ADPCMA_START_LSB_CNT} + START_MSB 0x00 x ${ADPCMA_START_MSB_ZERO}/${ADPCMA_START_MSB_CNT} + STOP_LSB uniq ${ADPCMA_STOP_LSB_UNIQ}/${ADPCMA_STOP_LSB_CNT} + STOP_MSB 0x00 x ${ADPCMA_STOP_MSB_ZERO}/${ADPCMA_STOP_MSB_CNT}) 全 PASS"
else
  ng "gate-3 (全 16 ch chip 別代表 register literal 期待値出力) 不成立 (FM:${G3_FM_FAIL:-OK} SSG:${G3_SSG_FAIL:-OK} ADPCMB:${G3_ADPCMB_FAIL:-OK} ADPCMA:${G3_ADPCMA_FAIL:-OK})"
fi

# ============================================================
# gate-4 = .org section overflow なし
# (= ε build .lst で 0x0066 セクション max addr < 0x0100 確認、 既存 script roadmap2-gate-6 (a) 同 pattern)
# ============================================================
echo "=== gate-4 .org section overflow なし verify ==="
# 既存 verify-axis-b-v2-song-playback.sh line 222 同 algorithm 再利用 (= .org 0x0066 〜 .org 0x0100 範囲の max addr)
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST_DELTA_2610" | sort | tail -1)
if [ -n "$MAX0066" ] && [ "$((16#$MAX0066))" -lt "$((16#0100))" ]; then
  ok "gate-4 (.org section overflow なし): 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow なし、 δ で K full bitmap 拡張後も維持)"
else
  ng "gate-4 (.org section overflow なし) 不成立 (max0066=0x${MAX0066:-NONE} 期待 < 0x0100)"
fi

# ============================================================
# gate-5 = representative 2 script regression
# (= ADR-0067 §決定 5 gate-5 literal「ADR-0049〜0059 既存 verify script ALL PASS 維持」 を
#    v2 driver 関連 representative 2 script で direct cover、 他 script は production sha256 維持で transitively OK)
# ============================================================
echo "=== gate-5 representative 2 script regression ==="
G5_FAIL=""
if bash src/test-fixtures/axis-b/verify-axis-b-v2-song-playback.sh >/dev/null 2>&1; then
  ok "gate-5a verify-axis-b-v2-song-playback.sh ALL PASS (= ADR-0058 ε + transitively ADR-0049〜0057 regression)"
else
  G5_FAIL="${G5_FAIL} verify-axis-b-v2-song-playback.sh"
fi
if bash src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh >/dev/null 2>&1; then
  ok "gate-5b verify-axis-b-v2-roadmap3-dispatch.sh ALL PASS (= ADR-0059 ε regression)"
else
  G5_FAIL="${G5_FAIL} verify-axis-b-v2-roadmap3-dispatch.sh"
fi
if [ -z "$G5_FAIL" ]; then
  ok "gate-5 (representative 2 script regression) ALL PASS"
else
  ng "gate-5 (representative 2 script regression) 不成立 (${G5_FAIL})"
fi

# ============================================================
# gate-5 後 production build 復帰 (= gate-6 用 trace は v2 fixture build 状態を維持必要)
# gate-5 内で verify-axis-b-v2-song-playback.sh が production build 復帰しているため、
# gate-6 の前に再度 v2 fixture build + trace を取り直す必要がある
# ============================================================
echo "=== gate-6 用 v2 fixture build 再復帰 + trace 再取得 (= chip ym2610) ==="
build_and_trace "ym2610" "$YMFM_DELTA_2610" "$ZMEM_DELTA_2610" "$LST_DELTA_2610"

# ============================================================
# gate-6 = IRQ tick 処理量 trace window 適合 (= threshold IRQ count >= 2000)
# (= γ 後 baseline 2261 件、 -12% 余白、 slot 7/8 active + K full bitmap 6 段 trigger による
#    dispatch loop 処理量増加でも閾値超え期待、 -seconds_to_run 5 + clean trace + actual count 出力)
# ============================================================
echo "=== gate-6 IRQ tick 処理量 trace window 適合 verify ==="
IRQ_COUNT=$(awk -F'\t' '$3=="F816"' "$ZMEM_DELTA_2610" | wc -l | tr -d ' ')
G6_THRESHOLD=2000
if [ "$IRQ_COUNT" -ge "$G6_THRESHOLD" ]; then
  ok "gate-6 (IRQ tick 処理量 trace window 適合): actual IRQ count = ${IRQ_COUNT} (>= ${G6_THRESHOLD} 期待、 γ baseline 2261 件から -12% 余白、 5 秒 trace + clean trace + actual count 出力 pattern)"
else
  ng "gate-6 (IRQ tick 処理量 trace window 適合) 不成立 (actual IRQ count = ${IRQ_COUNT} 期待 >= ${G6_THRESHOLD}、 trace window 不足 or dispatch loop 急減 risk、 trace capture 秒数 or threshold 見直し必要)"
fi

# ============================================================
# production build 復帰 (= 後続 sprint 環境の整合維持)
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 || { echo "NG  production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了"

# ============================================================
# completion proof
# ============================================================
echo ""
echo "=== ADR-0067 δ completion proof (= §決定 5 6 gate 全 PASS = δ 機能 verify only ready) ==="
echo "§決定 5 gate-1 (production sha256 維持):                  $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "§決定 5 gate-2 (v2 fixture build PASS + active slot):     $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "§決定 5 gate-3 (全 16 ch chip 別代表 register literal):   $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "§決定 5 gate-4 (.org section overflow なし):              $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "§決定 5 gate-5 (representative 2 script regression):      $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "§決定 5 gate-6 (IRQ tick 処理量 trace window 適合):       $([ $FAIL -eq 0 ] && echo PASS || echo CHECK)"
echo "ε Accepted 移行 ready: $([ $FAIL -eq 0 ] && echo "yes (= ADR-0067 §決定 5 6 gate 全 PASS = δ 完了)" || echo "no (= FAIL=${FAIL} 件)")"
echo ""

if [ $FAIL -eq 0 ]; then
  ok "ALL PASS (= ADR-0067 sub-sprint δ = 全 16 ch fixture 駆動 trace gate verify = 6 gate 全 PASS、 機能 verify only、 trace-equivalence は ADR-0068 future)"
  exit 0
else
  echo "NG  FAIL=${FAIL} 件"
  exit 1
fi
