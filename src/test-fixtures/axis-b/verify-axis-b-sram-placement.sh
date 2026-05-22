#!/usr/bin/env bash
#
# PMDNEO 軸 B 実装 sprint 2 γ verify gate (= ADR-0053 PartWork / SRAM placement)
#
# verify scope: ADR-0053 §決定 5 の verify gate 6 件を再現可能な verify script に
#   体系化する。 sub-sprint β (= PR #81) で driver に追加した v2 SRAM region 境界
#   定数 + sub-region map を gate 1-6 で検証。 driver 改修なし。
#
#   --- static gate (= production build .lst) ---
#   gate 1: sub-region 非重複 + 合計 — driver_state 64 + PartWork 256 + reserved
#                                     327 = 647、 各 region 境界が連続 + 非重複
#   gate 2: region 境界定数 一致     — pmdneo_v2_driver_state_base = 0xFD39 /
#                                     pmdneo_v2_partwork_base = 0xFD79 /
#                                     pmdneo_v2_reserved_base = 0xFE79 (= §決定 2 案 A)
#   gate 3: 既配置 3 field placement — pmdneo_v2_fade_level = 0xFD39 /
#                                     pmdneo_v2_ssg_mixer = 0xFD3A /
#                                     pmdneo_v2_entry_marker = 0xFD3B、 全て
#                                     driver_state region [0xFD39,0xFD79) 内
#   gate 4: 既存 SRAM layout 不変    — 0xF820-0xFD38 既存 field の .equ (= part_workarea
#                                     / PNE block / 軸 G scratch = ADR-0006/0022/0023
#                                     /0048) が documented address + PART_COUNT/SIZE のまま
#   gate 5: 命名規約 pmdneo_v2_     — v2 region [0xFD39,0xFFC0) に resolve する
#                                     .equ symbol が全て pmdneo_v2_ prefix
#   --- baseline gate ---
#   gate 6: baseline regression     — verify-axis-b-v2-entry.sh 7 gate (= 内部で
#                                     verify-fadeout 16 = mute 7 + baseline 9 +
#                                     verify-ssg-tone-enable 15 gate を transitively)
#
# 注: δ-2 = SRAM sub-region の placement 確定であり、 検証は driver `.lst` の
#   静的 address 解決の機械的確認が primary (= register trace / audio gate とは
#   別軸、 ADR-0053 §決定 5)。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-sram-placement.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"

FAIL=0
ok() { echo "✅ $1"; }
ng() { echo "❌ $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# equ_addr <symbol> : .lst から .equ symbol の resolve 値 (= 6-hex) を返す
equ_addr() {
  awk -v s="$1" '$3 == ".equ" && $4 == (s ",") { print $1; exit }' "$LST"
}

# ============================================================
# production build (= ym2610 default)
# ============================================================
echo "=== production build (= ym2610 default) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "❌ production build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "❌ .lst 未生成"; exit 1; }

DS=$(equ_addr pmdneo_v2_driver_state_base)
PW=$(equ_addr pmdneo_v2_partwork_base)
RS=$(equ_addr pmdneo_v2_reserved_base)

# --- gate 1: sub-region 非重複 + 合計 647 byte ---
if [ -n "$DS" ] && [ -n "$PW" ] && [ -n "$RS" ]; then
  ds=$(hex "$DS"); pw=$(hex "$PW"); rs=$(hex "$RS"); end=$((16#FFC0))
  size_ds=$((pw - ds)); size_pw=$((rs - pw)); size_rs=$((end - rs))
  total=$((size_ds + size_pw + size_rs))
  if [ "$size_ds" -eq 64 ] && [ "$size_pw" -eq 256 ] && [ "$size_rs" -eq 327 ] && [ "$total" -eq 647 ]; then
    ok "gate 1: sub-region 非重複 + 合計 = driver_state ${size_ds} + PartWork ${size_pw} + reserved ${size_rs} = ${total} byte (= 0xFD39-0xFFBF free region 連続充足)"
  else
    ng "gate 1: sub-region size 不一致 (driver_state=${size_ds} 期待 64 / PartWork=${size_pw} 期待 256 / reserved=${size_rs} 期待 327 / 合計=${total} 期待 647)"
  fi
else
  ng "gate 1: region 境界定数 未検出 (DS=0x${DS:-NONE} PW=0x${PW:-NONE} RS=0x${RS:-NONE})"
fi

# --- gate 2: region 境界定数 一致 (= §決定 2 案 A) ---
if [ "$DS" = "00FD39" ] && [ "$PW" = "00FD79" ] && [ "$RS" = "00FE79" ]; then
  ok "gate 2: region 境界定数 = pmdneo_v2_driver_state_base 0x${DS} / pmdneo_v2_partwork_base 0x${PW} / pmdneo_v2_reserved_base 0x${RS} (= ADR-0053 §決定 2 案 A 一致)"
else
  ng "gate 2: region 境界定数 不一致 (driver_state_base=0x${DS:-NONE} 期待 00FD39 / partwork_base=0x${PW:-NONE} 期待 00FD79 / reserved_base=0x${RS:-NONE} 期待 00FE79)"
fi

# --- gate 3: 既配置 3 field placement 不変 + driver_state region 内 ---
FL=$(equ_addr pmdneo_v2_fade_level)
SM=$(equ_addr pmdneo_v2_ssg_mixer)
EM=$(equ_addr pmdneo_v2_entry_marker)
G3OK=1
[ "$FL" = "00FD39" ] || G3OK=0
[ "$SM" = "00FD3A" ] || G3OK=0
[ "$EM" = "00FD3B" ] || G3OK=0
# driver_state region [0xFD39, 0xFD79) 内判定
if [ -n "$DS" ] && [ -n "$PW" ]; then
  for a in "$FL" "$SM" "$EM"; do
    [ -n "$a" ] || { G3OK=0; continue; }
    av=$(hex "$a")
    { [ "$av" -ge "$(hex "$DS")" ] && [ "$av" -lt "$(hex "$PW")" ]; } || G3OK=0
  done
else
  G3OK=0
fi
if [ "$G3OK" -eq 1 ]; then
  ok "gate 3: 既配置 3 field placement 不変 = pmdneo_v2_fade_level 0x${FL} / pmdneo_v2_ssg_mixer 0x${SM} / pmdneo_v2_entry_marker 0x${EM} (= 全て driver_state region [0xFD39,0xFD79) 内)"
else
  ng "gate 3: 既配置 3 field placement 異常 (fade_level=0x${FL:-NONE} 期待 00FD39 / ssg_mixer=0x${SM:-NONE} 期待 00FD3A / entry_marker=0x${EM:-NONE} 期待 00FD3B)"
fi

# --- gate 4: 既存 SRAM layout 0xF820-0xFD38 不変 ---
# ADR-0006/0022/0023/0048 owner の既存 field .equ が documented address のまま
# (= δ-2 が free region 0xFD39 より前の既存 layout = part_workarea / PNE block /
#  軸 G scratch を shift していない、 ADR-0053 §決定 5 gate 4 + §決定 7 不可触)。
# part_workarea region は base 0xF820 + PART_COUNT × PART_WORKAREA_SIZE で
# 0xF820-0xFD1F (= 20 × 64 byte)、 PART_COUNT/SIZE も併せて assert する。
PWA=$(equ_addr part_workarea)
PNEBUF=$(equ_addr driver_pne_filename_buf)
FADRW=$(equ_addr driver_pne_filename_adr_word)
SAMPID=$(equ_addr driver_pne_sample_table_id)
PCNT=$(equ_addr PART_COUNT)
PWSZ=$(equ_addr PART_WORKAREA_SIZE)
# 軸 G scratch 0xFD33-0xFD38 (= ADR-0048、 6 byte 全 .equ symbol を個別 assert)
GS1=$(equ_addr ppc_scratch_start_lsb)
GS2=$(equ_addr ppc_scratch_start_msb)
GS3=$(equ_addr ppc_scratch_stop_lsb)
GS4=$(equ_addr ppc_scratch_stop_msb)
GS5=$(equ_addr audition_frame_counter_lsb)
GS6=$(equ_addr audition_frame_counter_msb)
if [ "$PWA" = "00F820" ] && [ "$PNEBUF" = "00FD20" ] && [ "$FADRW" = "00FD30" ] && [ "$SAMPID" = "00FD32" ] \
   && [ "$PCNT" = "000014" ] && [ "$PWSZ" = "000040" ] \
   && [ "$GS1" = "00FD33" ] && [ "$GS2" = "00FD34" ] && [ "$GS3" = "00FD35" ] \
   && [ "$GS4" = "00FD36" ] && [ "$GS5" = "00FD37" ] && [ "$GS6" = "00FD38" ]; then
  ok "gate 4: 既存 SRAM layout 0xF820-0xFD38 不変 = part_workarea 0x${PWA} (= PART_COUNT $(hex "$PCNT") × PART_WORKAREA_SIZE $(hex "$PWSZ")) / driver_pne_filename_buf 0x${PNEBUF} / driver_pne_filename_adr_word 0x${FADRW} / driver_pne_sample_table_id 0x${SAMPID} / 軸 G scratch 0x${GS1}-0x${GS6} 6 byte 全 .equ (= ADR-0006/0022/0023/0048 layout shift なし)"
else
  ng "gate 4: 既存 SRAM layout shift (part_workarea=0x${PWA:-NONE}/filename_buf=0x${PNEBUF:-NONE}/filename_adr_word=0x${FADRW:-NONE}/sample_table_id=0x${SAMPID:-NONE}/PART_COUNT=0x${PCNT:-NONE}/PART_WORKAREA_SIZE=0x${PWSZ:-NONE}/軸G_scratch=0x${GS1:-NONE},0x${GS2:-NONE},0x${GS3:-NONE},0x${GS4:-NONE},0x${GS5:-NONE},0x${GS6:-NONE} 期待 00FD33-00FD38)"
fi

# --- gate 5: 命名規約 = v2 region [0xFD39,0xFFC0) 内 .equ symbol が全て pmdneo_v2_ prefix ---
G5BAD=0
G5BADSYM=""
while read -r addr sym; do
  [ -n "$addr" ] || continue
  d=$(hex "$addr")
  if [ "$d" -ge "$(hex FD39)" ] && [ "$d" -lt "$(hex FFC0)" ]; then
    case "$sym" in
      pmdneo_v2_*) ;;
      *) G5BAD=$((G5BAD + 1)); G5BADSYM="$G5BADSYM $sym(0x$addr)" ;;
    esac
  fi
done < <(awk '$3 == ".equ" && $1 ~ /^[0-9A-F]{6}$/ { sym=$4; gsub(/,$/, "", sym); print $1, sym }' "$LST")
if [ "$G5BAD" -eq 0 ]; then
  ok "gate 5: 命名規約 = v2 region [0xFD39,0xFFC0) に resolve する .equ symbol は全て pmdneo_v2_ prefix"
else
  ng "gate 5: v2 region に pmdneo_v2_ prefix 外の .equ symbol $G5BAD 件 ($G5BADSYM)"
fi

# ============================================================
# gate 6: baseline regression (= verify-axis-b-v2-entry.sh 7 gate)
# ============================================================
echo "=== gate 6: baseline regression (= verify-axis-b-v2-entry.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-v2-entry.sh >/dev/null 2>&1; then
  ok "gate 6: baseline regression = verify-axis-b-v2-entry.sh 7 gate 全 PASS (= verify-fadeout 16 + verify-mute 7 + baseline 9 script + verify-ssg-tone-enable 15 gate を transitively)"
else
  ng "gate 6: baseline regression FAIL"
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
  echo "✅ ALL PASS (= 軸 B 実装 sprint 2 = δ-2 PartWork/SRAM placement 6 gate 全 PASS)"
  exit 0
else
  echo "❌ $FAIL gate FAIL"
  exit 1
fi
