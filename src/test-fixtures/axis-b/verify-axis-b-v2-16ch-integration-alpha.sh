#!/usr/bin/env bash
#
# PMDNEO ADR-0068 sub-sprint α verify script = (a) 実 MML 再生 統合 verify
# (= existing resource activation = 既存 candidate K=3 union + α-task 1 rhythm-only proof、
#   10 env × 2 trace 種 = 20 trace file capture + union coverage 統合 report)
#
# verify scope: ADR-0068 §決定 2 α row literal (= plan v6-revised diff 3):
#   α-task 1 = rhythm-only proof (= src/test-fixtures/step5/l-q-rhythm-song.mml、 ADPCM-A L-Q)
#   α-task 2 = existing resource activation = 既存 candidate K=3 union:
#     - vendor/PMDDotNET/SAMPLE2-baseline.mml (= FM A/B/C + SSG I + ADPCM-A L)
#     - vendor/PMDDotNET/test-aes-ad.mml      (= FM A/B/D)
#     - src/test-fixtures/step4/j-part-g.mml  (= ADPCM-B J)
#
# build mode (= ADR-0068 §決定 3 literal):
#   (B) v2 only trace capture: PMDNEO_V2_SONG_FIXTURE=1 + PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1
#   (C-2) PMDDOTNET_MML:       PMDDOTNET_MML=<path> + PMDDOTNET_MODE=<N|B> + PMDNEO_USE_PMDDOTNET=1
#
# 10 env literal (= ADR-0068 §決定 2 α row 「10 env × ymfm/z80-mem 2 trace 種 = 20 trace file」):
#   env # 1 = (B) v2-only ym2610
#   env # 2 = (B) v2-only ym2610b
#   env # 3 = (C-2) α-task 1 rhythm-only ym2610  (= l-q-rhythm-song、 mode B)
#   env # 4 = (C-2) α-task 1 rhythm-only ym2610b (= 同、 mode B)
#   env # 5 = (C-2) α-task 2 SAMPLE2-baseline ym2610  (= mode B、 ABCI+L)
#   env # 6 = (C-2) α-task 2 SAMPLE2-baseline ym2610b (= 同、 mode B)
#   env # 7 = (C-2) α-task 2 test-aes-ad ym2610  (= mode N、 ABD)
#   env # 8 = (C-2) α-task 2 test-aes-ad ym2610b (= 同、 mode N)
#   env # 9 = (C-2) α-task 2 j-part-g ym2610  (= mode N、 J)
#   env #10 = (C-2) α-task 2 j-part-g ym2610b (= 同、 mode N)
#
# 16 ch enumeration (= ADR-0068 §決定 1(a) hybrid 原則 sub-section 表 literal):
#   FM (6 ch = A-F):       chip A/B/C/D/E/F (= MML part A-F、 port A reg 0x28 keyon F0-F6)
#   SSG (3 ch = G-I):      chip G/H/I (= MML part G-I、 port A reg 0x07 mixer + voice trigger)
#   ADPCM-B (1 ch = J):    MML part J (= port A reg 0x10-0x1C ADPCM-B start)
#   ADPCM-A (6 ch = L-Q):  MML part L-Q (= port B reg 0x00 keyon mask bit 0-5)
#
# α union expected coverage (= task #50 ground truth):
#   FM: A, B, C, D       (= 不足 E, F)
#   SSG: I               (= 不足 G, H)
#   ADPCM-B: J           (= OK)
#   ADPCM-A: L, M, N, O, P, Q (= OK)
#   合計: 12 / 16 ch carry confirm + 不足 4 ch (= FM E/F + SSG G/H) literal 報告
#   = ADR-0068 §決定 1(a) hybrid 原則 sub-section literal: 残 4 ch は β minimal MML 例外許可 carry
#
# α 完了判定 (= ADR-0068 §決定 2 α row 完了判定 literal):
#   - α-task 1 + α-task 2 両完了 (= 10 env 全 build + trace OK)
#   - 12/16 ch carry confirm (= existing resource union)
#   - 不足 4 ch literal 報告 (= FM E/F + SSG G/H)
#   - 残 4 ch β minimal MML carry plan literal (= ADR-0068 §決定 1(a) hybrid 原則 sub-section reference)
#
# driver touch なし (= ADR-0068 §決定 5 (ii) runtime/driver allowed-touch = 完全不変、
#   既存 fixture / 既存 verify script / 既存 build flag / vendor 完全不変、
#   PR2 (i) repo diff allowed-touch = doc + 本新規 verify script のみ)。
#
# trace-equivalence 比較は ADR-0068 §決定 1(a) α union 境界明記 literal「α union coverage
#   ≠ β trace-equivalence 完了条件 代替」 で β scope future、 本 α script は capture + report only。
#
# polling monitor 併走想定 (= memory feedback_long_running_hang_auto_recovery_rule.md +
#   feedback_codex_rescue_always_monitor.md literal、 機械復旧 default rule)。
#   10 env × build (~30s) + MAME trace (~5s) = ~6 分目安、 hang threshold = 15 分。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-alpha.sh

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

ALPHA_OUT_DIR="/tmp/pmdneo-adr-0068-alpha"
PMDDOTNET_DLL="${PMDDOTNET_DLL:-$PMDNEO_ROOT/vendor/PMDDotNET/PMDDotNETConsole/bin/Release/net6.0/PMDDotNETConsole.dll}"

EXPECTED_PROD_SHA="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

# trace 解析 helper
# count_writes <port=A|B> <reg hex> <trace tsv>
count_writes() { awk -F'\t' -v p="$1" -v r="$2" '$2==p && $3==r' "$3" | wc -l | tr -d ' '; }
# count_writes_value <port> <reg> <value hex> <trace tsv>
count_writes_value() { awk -F'\t' -v p="$1" -v r="$2" -v v="$3" '$2==p && $3==r && $4==v' "$4" | wc -l | tr -d ' '; }
# unique <port> <reg> <trace tsv>
list_values() { awk -F'\t' -v p="$1" -v r="$2" '$2==p && $3==r {print $4}' "$3" | sort -u | tr '\n' ' '; }

# ============================================================
# 共通 helper: build + MAME trace + 出力 file copy
# ============================================================
build_and_trace_v2_only() {
  local chip="$1"
  local label="$2"

  local ymfm_out="$ALPHA_OUT_DIR/env-${label}-ymfm.tsv"
  local zmem_out="$ALPHA_OUT_DIR/env-${label}-zmem.tsv"

  rm -f "$PREPROCESSED"
  if ! PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 bash scripts/build-poc.sh --chip "$chip" >"$ALPHA_OUT_DIR/env-${label}-build.log" 2>&1; then
    ng "env $label v2-only build FAIL (chip=$chip)、 build log = $ALPHA_OUT_DIR/env-${label}-build.log"
    return 1
  fi

  rm -rf "$TRACE_DIR"
  bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >"$ALPHA_OUT_DIR/env-${label}-mame.log" 2>&1 || true
  if [ ! -f "$YMFM" ] || [ ! -f "$ZMEM" ]; then
    ng "env $label trace 未生成 (chip=$chip)、 mame log = $ALPHA_OUT_DIR/env-${label}-mame.log"
    return 1
  fi
  cp "$YMFM" "$ymfm_out"
  cp "$ZMEM" "$zmem_out"
  ok "env $label build + trace OK (chip=$chip、 ymfm=$(wc -l < "$ymfm_out" | tr -d ' ') lines、 zmem=$(wc -l < "$zmem_out" | tr -d ' ') lines)"
}

build_and_trace_pmddotnet_mml() {
  local chip="$1"
  local mml_path="$2"
  local mode="$3"
  local label="$4"

  local ymfm_out="$ALPHA_OUT_DIR/env-${label}-ymfm.tsv"
  local zmem_out="$ALPHA_OUT_DIR/env-${label}-zmem.tsv"

  if [ ! -f "$mml_path" ]; then
    ng "env $label MML 不在 ($mml_path)"
    return 1
  fi
  if [ ! -f "$PMDDOTNET_DLL" ]; then
    ng "env $label PMDDOTNET_DLL 不在 ($PMDDOTNET_DLL)"
    return 1
  fi

  rm -f "$PREPROCESSED"
  if ! PMDDOTNET_MML="$mml_path" PMDDOTNET_MODE="$mode" PMDDOTNET_DLL="$PMDDOTNET_DLL" PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip "$chip" >"$ALPHA_OUT_DIR/env-${label}-build.log" 2>&1; then
    ng "env $label PMDDOTNET_MML build FAIL (chip=$chip、 mode=$mode、 mml=$mml_path)、 build log = $ALPHA_OUT_DIR/env-${label}-build.log"
    return 1
  fi

  rm -rf "$TRACE_DIR"
  bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >"$ALPHA_OUT_DIR/env-${label}-mame.log" 2>&1 || true
  if [ ! -f "$YMFM" ] || [ ! -f "$ZMEM" ]; then
    ng "env $label trace 未生成 (chip=$chip、 mode=$mode、 mml=$mml_path)、 mame log = $ALPHA_OUT_DIR/env-${label}-mame.log"
    return 1
  fi
  cp "$YMFM" "$ymfm_out"
  cp "$ZMEM" "$zmem_out"
  ok "env $label build + trace OK (chip=$chip、 mode=$mode、 mml=$(basename "$mml_path")、 ymfm=$(wc -l < "$ymfm_out" | tr -d ' ') lines、 zmem=$(wc -l < "$zmem_out" | tr -d ' ') lines)"
}

# ============================================================
# trace 解析: 1 trace tsv から 16 ch 各 ch の register write 検出
# ============================================================
# detect_fm_keyon <trace> = FM A-F 各 ch keyon 検出 (= port A reg 0x28 = F0/F1/F2/F4/F5/F6)
# fm_a=0xF0、 fm_b=0xF1、 fm_c=0xF2、 fm_d=0xF4、 fm_e=0xF5、 fm_f=0xF6 (= ADR-0067 δ comment literal)
detect_fm() {
  local trace="$1"
  local ch_letter="$2"
  local keyon_value
  case "$ch_letter" in
    A) keyon_value="F0" ;;
    B) keyon_value="F1" ;;
    C) keyon_value="F2" ;;
    D) keyon_value="F4" ;;
    E) keyon_value="F5" ;;
    F) keyon_value="F6" ;;
    *) echo 0; return ;;
  esac
  count_writes_value A 28 "$keyon_value" "$trace"
}

# detect_ssg <trace> <ch_letter> = SSG G/H/I 各 ch voice / volume / mixer 検出
# SSG ch 0 = G、 1 = H、 2 = I (= ADR-0058 / 0067 慣習)
# SSG volume reg = 0x08 (G) / 0x09 (H) / 0x0A (I)
# SSG tone fine reg = 0x00 (G) / 0x02 (H) / 0x04 (I)
detect_ssg() {
  local trace="$1"
  local ch_letter="$2"
  local vol_reg tone_reg
  case "$ch_letter" in
    G) vol_reg="08"; tone_reg="00" ;;
    H) vol_reg="09"; tone_reg="02" ;;
    I) vol_reg="0A"; tone_reg="04" ;;
    *) echo 0; return ;;
  esac
  local vol_count tone_count
  vol_count=$(count_writes A "$vol_reg" "$trace")
  tone_count=$(count_writes A "$tone_reg" "$trace")
  # vol or tone のどちらか書込み発生で active 判定
  echo $((vol_count + tone_count))
}

# detect_adpcmb <trace> = ADPCM-B J ch start 検出 (= port A reg 0x10 = ADPCM-B start)
detect_adpcmb() {
  local trace="$1"
  # ADPCM-B keyon = port A reg 0x10 (= bit 7 set 含む write 全)
  count_writes A 10 "$trace"
}

# detect_adpcma <trace> <ch_letter> = ADPCM-A L-Q 各 ch keyon mask bit 検出
# ADPCM-A keyon = port B reg 0x00 bit mask、 L=bit0、 M=bit1、 N=bit2、 O=bit3、 P=bit4、 Q=bit5
detect_adpcma() {
  local trace="$1"
  local ch_letter="$2"
  local bit
  case "$ch_letter" in
    L) bit=0 ;;
    M) bit=1 ;;
    N) bit=2 ;;
    O) bit=3 ;;
    P) bit=4 ;;
    Q) bit=5 ;;
    *) echo 0; return ;;
  esac
  # port B reg 0x00 の各 value で bit が立っているか check
  local total=0
  for v in $(list_values B 00 "$trace"); do
    # hex value to decimal
    local dec=$((16#${v}))
    local mask=$((1 << bit))
    if [ $((dec & mask)) -ne 0 ]; then
      local cnt
      cnt=$(count_writes_value B 00 "$v" "$trace")
      total=$((total + cnt))
    fi
  done
  echo "$total"
}

# ============================================================
# main
# ============================================================
mkdir -p "$ALPHA_OUT_DIR"
echo "==== ADR-0068 sub-sprint α verify (= plan v6-revised) ===="
echo "==== existing resource activation = K=3 candidate + α-task 1 rhythm-only proof ===="
echo "==== 10 env × 2 trace = 20 trace file capture + union coverage report ===="
echo "==== output dir = $ALPHA_OUT_DIR ===="
date "+START %Y-%m-%dT%H:%M:%S"

# ----- env # 1 = (B) v2-only ym2610 -----
echo "---- env # 1 = (B) v2-only ym2610 ----"
build_and_trace_v2_only ym2610 "01-v2only-ym2610" || true

# ----- env # 2 = (B) v2-only ym2610b -----
echo "---- env # 2 = (B) v2-only ym2610b ----"
build_and_trace_v2_only ym2610b "02-v2only-ym2610b" || true

# ----- env # 3 = (C-2) α-task 1 rhythm-only ym2610 (mode=B) -----
echo "---- env # 3 = (C-2) α-task 1 rhythm-only ym2610 (mode=B) ----"
build_and_trace_pmddotnet_mml ym2610 "$PMDNEO_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml" B "03-rhythmonly-ym2610" || true

# ----- env # 4 = (C-2) α-task 1 rhythm-only ym2610b (mode=B) -----
echo "---- env # 4 = (C-2) α-task 1 rhythm-only ym2610b (mode=B) ----"
build_and_trace_pmddotnet_mml ym2610b "$PMDNEO_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml" B "04-rhythmonly-ym2610b" || true

# ----- env # 5 = (C-2) α-task 2 SAMPLE2-baseline ym2610 (mode=B) -----
echo "---- env # 5 = (C-2) α-task 2 SAMPLE2-baseline ym2610 (mode=B) ----"
build_and_trace_pmddotnet_mml ym2610 "$PMDNEO_ROOT/vendor/PMDDotNET/SAMPLE2-baseline.mml" B "05-sample2-ym2610" || true

# ----- env # 6 = (C-2) α-task 2 SAMPLE2-baseline ym2610b (mode=B) -----
echo "---- env # 6 = (C-2) α-task 2 SAMPLE2-baseline ym2610b (mode=B) ----"
build_and_trace_pmddotnet_mml ym2610b "$PMDNEO_ROOT/vendor/PMDDotNET/SAMPLE2-baseline.mml" B "06-sample2-ym2610b" || true

# ----- env # 7 = (C-2) α-task 2 test-aes-ad ym2610 (mode=N) -----
echo "---- env # 7 = (C-2) α-task 2 test-aes-ad ym2610 (mode=N) ----"
build_and_trace_pmddotnet_mml ym2610 "$PMDNEO_ROOT/vendor/PMDDotNET/test-aes-ad.mml" N "07-testaesad-ym2610" || true

# ----- env # 8 = (C-2) α-task 2 test-aes-ad ym2610b (mode=N) -----
echo "---- env # 8 = (C-2) α-task 2 test-aes-ad ym2610b (mode=N) ----"
build_and_trace_pmddotnet_mml ym2610b "$PMDNEO_ROOT/vendor/PMDDotNET/test-aes-ad.mml" N "08-testaesad-ym2610b" || true

# ----- env # 9 = (C-2) α-task 2 j-part-g ym2610 (mode=N) -----
echo "---- env # 9 = (C-2) α-task 2 j-part-g ym2610 (mode=N) ----"
build_and_trace_pmddotnet_mml ym2610 "$PMDNEO_ROOT/src/test-fixtures/step4/j-part-g.mml" N "09-jpartg-ym2610" || true

# ----- env # 10 = (C-2) α-task 2 j-part-g ym2610b (mode=N) -----
echo "---- env # 10 = (C-2) α-task 2 j-part-g ym2610b (mode=N) ----"
build_and_trace_pmddotnet_mml ym2610b "$PMDNEO_ROOT/src/test-fixtures/step4/j-part-g.mml" N "10-jpartg-ym2610b" || true

# ============================================================
# union coverage report (= 16 ch enumeration + 12/16 carry confirm + 不足 4 ch literal)
# ============================================================
echo ""
echo "==== union coverage report (= 16 ch × 10 env) ===="

# 16 ch × 10 env matrix
ENVS=("01-v2only-ym2610" "02-v2only-ym2610b" "03-rhythmonly-ym2610" "04-rhythmonly-ym2610b" \
      "05-sample2-ym2610" "06-sample2-ym2610b" "07-testaesad-ym2610" "08-testaesad-ym2610b" \
      "09-jpartg-ym2610" "10-jpartg-ym2610b")

# 16 ch identifier list (= MML part letter)
CHANNELS=("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "L" "M" "N" "O" "P" "Q")

declare -a UNION_CARRY

echo ""
printf "ch  |"
for env in "${ENVS[@]}"; do
  printf " %5s |" "${env%%-*}"
done
printf " union\n"
printf "----+"
for _ in "${ENVS[@]}"; do printf "-------+"; done
printf "------\n"

for ch in "${CHANNELS[@]}"; do
  printf " %s  |" "$ch"
  ch_union=0
  for env in "${ENVS[@]}"; do
    trace="$ALPHA_OUT_DIR/env-${env}-ymfm.tsv"
    if [ ! -f "$trace" ]; then
      printf " %5s |" "MISS"
      continue
    fi
    case "$ch" in
      A|B|C|D|E|F)  cnt=$(detect_fm "$trace" "$ch") ;;
      G|H|I)        cnt=$(detect_ssg "$trace" "$ch") ;;
      J)            cnt=$(detect_adpcmb "$trace") ;;
      L|M|N|O|P|Q)  cnt=$(detect_adpcma "$trace" "$ch") ;;
      *)            cnt=0 ;;
    esac
    if [ "$cnt" -gt 0 ]; then
      ch_union=$((ch_union + cnt))
      printf " %5d |" "$cnt"
    else
      printf " %5s |" "-"
    fi
  done
  if [ "$ch_union" -gt 0 ]; then
    printf "  YES (= %d total writes)\n" "$ch_union"
    UNION_CARRY+=("$ch")
  else
    printf "  no\n"
  fi
done

# ============================================================
# 12/16 ch carry confirm + 不足 4 ch literal report
# ============================================================
echo ""
echo "==== α-task 1 + α-task 2 union coverage 結果 ===="

CARRY_COUNT=${#UNION_CARRY[@]}
echo "carry ch ($CARRY_COUNT / 16): ${UNION_CARRY[*]}"

# 期待 union = ["A" "B" "C" "D" "I" "J" "L" "M" "N" "O" "P" "Q"]
# 不足 = ["E" "F" "G" "H"]
EXPECTED_CARRY=("A" "B" "C" "D" "I" "J" "L" "M" "N" "O" "P" "Q")
EXPECTED_MISSING=("E" "F" "G" "H")

# carry confirm
all_expected_present=1
for exp in "${EXPECTED_CARRY[@]}"; do
  found=0
  for c in "${UNION_CARRY[@]}"; do
    if [ "$c" = "$exp" ]; then found=1; break; fi
  done
  if [ "$found" = 0 ]; then
    ng "期待 carry ch $exp が union に含まれない (= existing resource union 不足)"
    all_expected_present=0
  fi
done

# missing confirm (= 期待通り不足 = β minimal MML carry 対象)
unexpected_present=0
for miss in "${EXPECTED_MISSING[@]}"; do
  for c in "${UNION_CARRY[@]}"; do
    if [ "$c" = "$miss" ]; then
      ng "期待 不足 ch $miss が union に含まれている (= existing resource で carry 不可期待だったが trace に検出)"
      unexpected_present=1
    fi
  done
done

if [ "$all_expected_present" = 1 ] && [ "$unexpected_present" = 0 ]; then
  ok "12/16 ch carry confirm (= ${EXPECTED_CARRY[*]})"
  ok "不足 4 ch literal report = ${EXPECTED_MISSING[*]} (= β minimal MML carry 対象、 ADR-0068 §決定 1(a) hybrid 原則 sub-section reference)"
fi

# ============================================================
# 結果 summary
# ============================================================
echo ""
echo "==== ADR-0068 sub-sprint α verify summary ===="
date "+END %Y-%m-%dT%H:%M:%S"
echo "trace files = $(ls "$ALPHA_OUT_DIR"/env-*-ymfm.tsv 2>/dev/null | wc -l | tr -d ' ') / 10 ymfm + $(ls "$ALPHA_OUT_DIR"/env-*-zmem.tsv 2>/dev/null | wc -l | tr -d ' ') / 10 zmem (= 期待 10+10 = 20 file)"
echo "carry ch = $CARRY_COUNT / 16"
echo "不足 ch (= β minimal MML carry 対象) = ${EXPECTED_MISSING[*]}"
echo "FAIL count = $FAIL"

if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "OK  α verify PASS (= 10 env × 2 trace = 20 file capture + 12/16 ch carry confirm + 不足 4 ch literal report)"
  echo "    残 4 ch (= ${EXPECTED_MISSING[*]}) は β minimal MML carry plan (= ADR-0068 §決定 1(a) hybrid 原則 sub-section literal)"
  exit 0
else
  echo ""
  echo "NG  α verify FAIL = $FAIL"
  exit 1
fi
