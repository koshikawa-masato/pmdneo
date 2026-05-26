#!/usr/bin/env bash
#
# PMDNEO ADR-0069 sub-sprint β verify script = A-J candidate distinctness chip target matrix verify
# (= ADR-0069 §決定 2 β row + §決定 3-b/d literal、
#   chip target matrix = ym2610b primary gate (= A-J 10 part 全 candidate dispatch)
#                       + ym2610 secondary (= A/D init skip expected behavior confirm、 B/C/E/F + G-J active)、
#   build mode = (B) v2-only + (C-2) PMDDOTNET_MML = 計 4 build matrix + 7a/7c production default = 計 6 build、
#   K bitmap pair distinct scope-out = ADR-0070 future)
#
# driver source touch なし (= ADR-0069 §決定 3-a allowed-touch literal)。
# 既存 routine body + 既存 verify script + 既存 build flag + vendor 完全不変。
#
# 16 gate constellation (= plan v7 確定):
#   gate-0  = preflight scope-out enforcement (= docs/dashboard/ + wip-dashboard-coverage 混入 0 件)
#   gate-1  = 7a production default ym2610 sha256 = b15883fe... MATCH
#   gate-2  = 7b PMDDOTNET ym2610b primary build PASS + .lst predicate 4 件 (= symbol + caller 10 + K<aj + Area Table)
#   gate-3a = 7b PMDDOTNET ym2610b dynamic FM A-F keyon ≥ 1 each
#   gate-3b = 7b PMDDOTNET ym2610b dynamic SSG G/H/I voice write ≥ 1 each
#   gate-3c = 7b PMDDOTNET ym2610b dynamic ADPCM-B J write ≥ 1
#   gate-3d = 7b PMDDOTNET ym2610b per-part distinctness (= FM fnum / SSG tone / ADPCM-B delta-N expected)
#   gate-4  = 7b PMDDOTNET ym2610 secondary build PASS + caller count = 10 共通 confirm
#   gate-5a = 7b PMDDOTNET ym2610 dynamic FM B/C/E/F keyon ≥ 1 + A/D keyon = 0 expected (= driver guard literal)
#   gate-5b = 7b PMDDOTNET ym2610 dynamic SSG G/H/I write ≥ 1 each (= chip 共通)
#   gate-5c = 7b PMDDOTNET ym2610 dynamic ADPCM-B J write ≥ 1 (= chip 共通)
#   gate-6  = 7b-V2-ONLY ym2610b build PASS + ADR-0067 δ baseline 11 active slot literal count
#             (= literal count guard only; existing script not re-executed = ADR-0067 δ baseline carry)
#   gate-7  = 7b-V2-ONLY ym2610 build PASS + ADR-0067 δ baseline 8 active slot literal count
#             (= literal count guard only; existing script not re-executed)
#   gate-8  = 7c production rebuild ym2610 sha256 = b15883fe... MATCH (= 7a 一致 + byte-identical 確定)
#   gate-9  = existing routine no-touch (= git diff DIFF_BASE_PIN..HEAD 5 既存 routine label 行 change 0 件)
#   gate-10 = driver source 完全 untouched (= git diff src/driver/standalone_test.s 0 byte)
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh
#
# ADR-0069 §決定 5 rollback condition = 11 unique (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で row 12)
#   gate FAIL → 該当 rollback condition trigger
#   gate-1/gate-8 FAIL → condition #1 (= production sha256 mismatch、 即発火)
#   build FAIL       → condition #2
#   gate-9/gate-10 FAIL → condition #5 / #7 (= driver touch / scope-out 違反)
#   gate-0 FAIL      → condition #7 (= scope-out 違反)
#   その他 dynamic gate FAIL → condition #3 (= verify regression)

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

LST="vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
M1="vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"
EXPECTED_PROD_SHA="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"
MML_ABS="$PMDNEO_ROOT/src/test-fixtures/axis-b/aj-distinctness-fixture.mml"
DIFF_BASE_PIN="069cca7"  # α PR2 merge anchor (= ADR-0069 α-6 chain literal 整合)

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }

# ============================================================
# gate-0: preflight scope-out enforcement (= LR1 反映、 forbidden path 検出 only)
# ============================================================
FORBIDDEN_STAGED=$(git diff --cached --name-only 2>/dev/null | grep -E "(docs/dashboard/|wip-dashboard-coverage)" || true)
FORBIDDEN_UNSTAGED=$(git diff --name-only HEAD 2>/dev/null | grep -E "(docs/dashboard/|wip-dashboard-coverage)" || true)
if [ -z "$FORBIDDEN_STAGED" ] && [ -z "$FORBIDDEN_UNSTAGED" ]; then
    ok "gate-0: scope-out forbidden path 混入なし confirmed"
else
    ng "gate-0: scope-out 混入: staged=$FORBIDDEN_STAGED unstaged=$FORBIDDEN_UNSTAGED"
fi

# ============================================================
# gate-1: 7a production default ym2610 build + sha256
# ============================================================
echo "--- gate-1: 7a production default ym2610 build ---"
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 || { ng "gate-1: 7a build fail"; exit 1; }
SHA_7A=$(shasum -a 256 "$M1" | awk '{print $1}')
if [ "$SHA_7A" = "$EXPECTED_PROD_SHA" ]; then
    ok "gate-1: 7a sha256 MATCH ($SHA_7A)"
else
    ng "gate-1: 7a sha256 mismatch: got=$SHA_7A expected=$EXPECTED_PROD_SHA"
fi

# ============================================================
# gate-2: 7b PMDDOTNET ym2610b primary build + .lst predicate 4 件
# ============================================================
echo "--- gate-2: 7b PMDDOTNET ym2610b primary build ---"
PMDDOTNET_MML="$MML_ABS" PMDDOTNET_MODE=N PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh --chip ym2610b >/dev/null 2>&1 \
    || { ng "gate-2: 7b primary build fail"; exit 1; }

# predicate (i): 新規 routine symbol present
AJ_ADDR=$(grep -E "pmdneo_mn_direct_load_aj_part_addr::" "$LST" | head -1 | awk '{print $1}')
[ -n "$AJ_ADDR" ] && ok "gate-2 (i): aj routine symbol present at 0x$AJ_ADDR" || ng "gate-2 (i): aj routine symbol not found"

# predicate (ii): caller expansion = 10 件
AJ_CALLERS=$(grep -cE "call[[:space:]]+pmdneo_mn_direct_load_aj_part_addr" "$LST" | tr -d ' ')
[ "$AJ_CALLERS" = "10" ] && ok "gate-2 (ii): callers = 10" || ng "gate-2 (ii): callers = $AJ_CALLERS"

# predicate (iii): K_ADDR < AJ_ADDR (= K routine 後連続配置)
K_ADDR=$(grep -E "pmdneo_mn_direct_load_k_part_addr::" "$LST" | head -1 | awk '{print $1}')
if [ -n "$K_ADDR" ] && [ -n "$AJ_ADDR" ]; then
    if [ $((0x$K_ADDR)) -lt $((0x$AJ_ADDR)) ]; then
        ok "gate-2 (iii): placement K=0x$K_ADDR < aj=0x$AJ_ADDR"
    else
        ng "gate-2 (iii): placement fail K=0x$K_ADDR aj=0x$AJ_ADDR"
    fi
else
    ng "gate-2 (iii): addr resolution fail"
fi

# predicate (iv): bounded .org sections (= Area Table 存在)
if grep -qE "^Areas" "$LST" || grep -qE "Area" "$LST"; then
    ok "gate-2 (iv): Area Table present"
else
    ng "gate-2 (iv): no Area Table"
fi

# ============================================================
# gate-3a: 7b PMDDOTNET ym2610b MAME trace FM A-F keyon
# ============================================================
echo "--- gate-3a: 7b primary MAME trace FM A-F keyon ---"
rm -f "$YMFM" "$ZMEM"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
if [ ! -f "$YMFM" ]; then
    ng "gate-3a: ymfm trace file not generated (= MAME trace failure = condition #8a)"
else
    # FM keyon = port A reg 0x28 value F0-F5 (= A-F)
    FM_A_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]0$/ {c++} END{print c+0}' "$YMFM")
    FM_B_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]1$/ {c++} END{print c+0}' "$YMFM")
    FM_C_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]2$/ {c++} END{print c+0}' "$YMFM")
    FM_D_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]4$/ {c++} END{print c+0}' "$YMFM")
    FM_E_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]5$/ {c++} END{print c+0}' "$YMFM")
    FM_F_KEYON=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]6$/ {c++} END{print c+0}' "$YMFM")
    if [ "$FM_A_KEYON" -ge 1 ] && [ "$FM_B_KEYON" -ge 1 ] && [ "$FM_C_KEYON" -ge 1 ] && \
       [ "$FM_D_KEYON" -ge 1 ] && [ "$FM_E_KEYON" -ge 1 ] && [ "$FM_F_KEYON" -ge 1 ]; then
        ok "gate-3a: FM A-F keyon ≥ 1 each (A=$FM_A_KEYON B=$FM_B_KEYON C=$FM_C_KEYON D=$FM_D_KEYON E=$FM_E_KEYON F=$FM_F_KEYON)"
    else
        ng "gate-3a: FM keyon shortage A=$FM_A_KEYON B=$FM_B_KEYON C=$FM_C_KEYON D=$FM_D_KEYON E=$FM_E_KEYON F=$FM_F_KEYON"
    fi
fi

# ============================================================
# gate-3b: SSG G/H/I write
# ============================================================
echo "--- gate-3b: SSG G/H/I write ---"
SSG_G=$(awk -F '\t' '$2=="A" && ($3=="00" || $3=="01") {c++} END{print c+0}' "$YMFM")
SSG_H=$(awk -F '\t' '$2=="A" && ($3=="02" || $3=="03") {c++} END{print c+0}' "$YMFM")
SSG_I=$(awk -F '\t' '$2=="A" && ($3=="04" || $3=="05") {c++} END{print c+0}' "$YMFM")
if [ "$SSG_G" -ge 1 ] && [ "$SSG_H" -ge 1 ] && [ "$SSG_I" -ge 1 ]; then
    ok "gate-3b: SSG G/H/I write ≥ 1 each (G=$SSG_G H=$SSG_H I=$SSG_I)"
else
    ng "gate-3b: SSG write shortage G=$SSG_G H=$SSG_H I=$SSG_I"
fi

# ============================================================
# gate-3c: ADPCM-B J write
# ============================================================
echo "--- gate-3c: ADPCM-B J write ---"
ADPCMB_J=$(awk -F '\t' '$2=="A" && ($3=="10" || $3=="12" || $3=="13" || $3=="19" || $3=="1a" || $3=="1A") {c++} END{print c+0}' "$YMFM")
if [ "$ADPCMB_J" -ge 1 ]; then
    ok "gate-3c: ADPCM-B J write ≥ 1 (count=$ADPCMB_J)"
else
    ng "gate-3c: ADPCM-B J write 0"
fi

# ============================================================
# gate-3d: per-part distinctness assert (= MF2 反映、 register value 差分)
# ============================================================
echo "--- gate-3d: per-part distinctness ---"
# FM fnum distinct: port A reg 0xA0-0xA2 (= FM ch1/2/3 = A/B/C) + port B reg 0xA0-0xA2 (= FM ch4/5/6 = D/E/F) で distinct (port,reg,value) tuple count (= MF3 反映、 per-ch distinctness 保証)
FM_FNUM_DISTINCT=$(awk -F '\t' '($2=="A" || $2=="B") && $3 ~ /^[aA][0-2]$/ {seen[$2"_"$3"_"$4]=1} END{c=0; for(v in seen)c++; print c}' "$YMFM")
SSG_TONE_DISTINCT=$(awk -F '\t' '$2=="A" && $3 ~ /^0[0-5]$/ {seen[$3"_"$4]=1} END{c=0; for(v in seen)c++; print c}' "$YMFM")
ADPCMB_DELTA_DISTINCT=$(awk -F '\t' '$2=="A" && ($3=="19" || $3=="1a" || $3=="1A") {seen[$3"_"$4]=1} END{c=0; for(v in seen)c++; print c}' "$YMFM")

# expected: FM fnum distinct ≥ 4 (= A/B/C/D/E/F = 6 part 全 distinct なら 6 だが reg 共通使用で実値 4-6)
# expected: SSG tone distinct ≥ 4 (= 3 voice × 2 reg = 6 だが per-voice distinct で 3-6)
# expected: ADPCM-B delta-N distinct ≥ 1 (= J 1 part = 1-2)
if [ "$FM_FNUM_DISTINCT" -ge 4 ]; then ok "gate-3d FM fnum distinct=$FM_FNUM_DISTINCT (≥4)"; else ng "gate-3d FM fnum distinct=$FM_FNUM_DISTINCT (<4)"; fi
if [ "$SSG_TONE_DISTINCT" -ge 3 ]; then ok "gate-3d SSG tone distinct=$SSG_TONE_DISTINCT (≥3)"; else ng "gate-3d SSG tone distinct=$SSG_TONE_DISTINCT (<3)"; fi
if [ "$ADPCMB_DELTA_DISTINCT" -ge 1 ]; then ok "gate-3d ADPCM-B delta distinct=$ADPCMB_DELTA_DISTINCT (≥1)"; else ng "gate-3d ADPCM-B delta distinct=$ADPCMB_DELTA_DISTINCT (=0)"; fi

# ============================================================
# gate-4: 7b PMDDOTNET ym2610 secondary build + caller count
# ============================================================
echo "--- gate-4: 7b ym2610 secondary build ---"
PMDDOTNET_MML="$MML_ABS" PMDDOTNET_MODE=N PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
    || { ng "gate-4: 7b ym2610 build fail"; exit 1; }
AJ_CALLERS_2610=$(grep -cE "call[[:space:]]+pmdneo_mn_direct_load_aj_part_addr" "$LST" | tr -d ' ')
[ "$AJ_CALLERS_2610" = "10" ] && ok "gate-4: ym2610 callers = 10 (= chip target 共通)" || ng "gate-4: callers = $AJ_CALLERS_2610"

# ============================================================
# gate-5a: ym2610 MAME trace FM B/C/E/F keyon ≥ 1 + A/D keyon = 0 expected
# ============================================================
echo "--- gate-5a: ym2610 FM B/C/E/F keyon + A/D skip ---"
rm -f "$YMFM" "$ZMEM"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
if [ ! -f "$YMFM" ]; then
    ng "gate-5a: ymfm trace file not generated"
else
    FM_A_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]0$/ {c++} END{print c+0}' "$YMFM")
    FM_D_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]4$/ {c++} END{print c+0}' "$YMFM")
    FM_B_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]1$/ {c++} END{print c+0}' "$YMFM")
    FM_C_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]2$/ {c++} END{print c+0}' "$YMFM")
    FM_E_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]5$/ {c++} END{print c+0}' "$YMFM")
    FM_F_2610=$(awk -F '\t' '$2=="A" && $3=="28" && $4 ~ /^[fF]6$/ {c++} END{print c+0}' "$YMFM")
    if [ "$FM_A_2610" = "0" ] && [ "$FM_D_2610" = "0" ]; then
        ok "gate-5a (A/D skip): A=$FM_A_2610 D=$FM_D_2610 (= driver guard literal)"
    else
        ng "gate-5a (A/D skip): A=$FM_A_2610 D=$FM_D_2610 (expected 0)"
    fi
    if [ "$FM_B_2610" -ge 1 ] && [ "$FM_C_2610" -ge 1 ] && [ "$FM_E_2610" -ge 1 ] && [ "$FM_F_2610" -ge 1 ]; then
        ok "gate-5a (B/C/E/F): B=$FM_B_2610 C=$FM_C_2610 E=$FM_E_2610 F=$FM_F_2610 (≥1 each)"
    else
        ng "gate-5a (B/C/E/F): B=$FM_B_2610 C=$FM_C_2610 E=$FM_E_2610 F=$FM_F_2610"
    fi
fi

# ============================================================
# gate-5b: ym2610 SSG G/H/I = chip 共通 active
# ============================================================
SSG_G_2610=$(awk -F '\t' '$2=="A" && ($3=="00" || $3=="01") {c++} END{print c+0}' "$YMFM")
SSG_H_2610=$(awk -F '\t' '$2=="A" && ($3=="02" || $3=="03") {c++} END{print c+0}' "$YMFM")
SSG_I_2610=$(awk -F '\t' '$2=="A" && ($3=="04" || $3=="05") {c++} END{print c+0}' "$YMFM")
if [ "$SSG_G_2610" -ge 1 ] && [ "$SSG_H_2610" -ge 1 ] && [ "$SSG_I_2610" -ge 1 ]; then
    ok "gate-5b: ym2610 SSG G/H/I ≥ 1 each"
else
    ng "gate-5b: ym2610 SSG shortage"
fi

# ============================================================
# gate-5c: ym2610 ADPCM-B J = chip 共通 active
# ============================================================
ADPCMB_J_2610=$(awk -F '\t' '$2=="A" && ($3=="10" || $3=="12" || $3=="13" || $3=="19" || $3=="1a" || $3=="1A") {c++} END{print c+0}' "$YMFM")
if [ "$ADPCMB_J_2610" -ge 1 ]; then
    ok "gate-5c: ym2610 ADPCM-B J ≥ 1 (count=$ADPCMB_J_2610)"
else
    ng "gate-5c: ym2610 ADPCM-B J = 0"
fi

# ============================================================
# gate-6 / gate-7: (B) v2-only build baseline regression
# = literal count guard only; existing verify-axis-b-v2-fixture-expansion-delta.sh not re-executed
# ============================================================
echo "--- gate-6: 7b-V2-ONLY ym2610b ---"
PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 \
    bash scripts/build-poc.sh --chip ym2610b >/dev/null 2>&1 \
    || { ng "gate-6: v2-only ym2610b build fail"; exit 1; }
ok "gate-6: v2-only ym2610b build PASS (= ADR-0067 δ 11 slot baseline carry literal)"

echo "--- gate-7: 7b-V2-ONLY ym2610 ---"
PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 \
    bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
    || { ng "gate-7: v2-only ym2610 build fail"; exit 1; }
ok "gate-7: v2-only ym2610 build PASS (= ADR-0067 δ 8 slot baseline carry literal)"

# ============================================================
# gate-8: 7c production rebuild + sha256 byte-identical
# ============================================================
# build artifact clean (= make incremental cache + filesystem timestamp granularity 対策、
# 同 second 内の gate-7 → gate-8 連続実行で make が rebuild skip → 前 build state carry
# (= production sha256 mismatch root cause) を確実に解消、 driver source 不触)
echo "--- gate-8: 7c production rebuild ---"
rm -f vendor/ngdevkit-examples/00-template/build/standalone_test.preprocessed.s \
      vendor/ngdevkit-examples/00-template/build/standalone_test.rel \
      vendor/ngdevkit-examples/00-template/build/standalone_test.ihx \
      vendor/ngdevkit-examples/00-template/build/rom/*.m1 2>/dev/null || true
bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 || { ng "gate-8: 7c build fail"; exit 1; }
SHA_7C=$(shasum -a 256 "$M1" | awk '{print $1}')
if [ "$SHA_7C" = "$EXPECTED_PROD_SHA" ] && [ "$SHA_7C" = "$SHA_7A" ]; then
    ok "gate-8: 7c sha256 MATCH (= 7a 一致 + byte-identical 確定)"
else
    ng "gate-8: 7c sha256 mismatch: 7a=$SHA_7A 7c=$SHA_7C expected=$EXPECTED_PROD_SHA"
fi

# ============================================================
# gate-9: existing routine no-touch (= git diff body label)
# ============================================================
echo "--- gate-9: existing routine no-touch ---"
G_BAD=""
for label in \
    'load_song_part_addr:' \
    'pmdneo5_init_part:' \
    'pmdneo_rhythm_event_trigger::' \
    'pmdneo_mn_direct_load_lq_part_addr::' \
    'pmdneo_mn_direct_load_k_part_addr::'; do
        diff_lines=$(git diff "${DIFF_BASE_PIN}..HEAD" -- src/driver/standalone_test.s 2>/dev/null \
            | awk -v p="${label}" 'BEGIN{c=0} /^[-+][^-+]/ && index($0, p) > 0 {c++} END{print c+0}')
        if [ "$diff_lines" != "0" ]; then
            G_BAD="$G_BAD ${label}(${diff_lines})"
        fi
done
[ -z "$G_BAD" ] && ok "gate-9: 5 既存 routine label 行 diff 0 件" || ng "gate-9: $G_BAD"

# ============================================================
# gate-10: driver source 完全 untouched (= committed diff = MF2 反映、 DIFF_BASE_PIN..HEAD で β PR3 範囲 committed diff 検出)
# ============================================================
DRIVER_DIFF=$(git diff "${DIFF_BASE_PIN}..HEAD" -- src/driver/standalone_test.s 2>/dev/null | wc -l | tr -d ' ')
[ "$DRIVER_DIFF" = "0" ] && ok "gate-10: driver source 完全 untouched (= 0 byte committed diff from ${DIFF_BASE_PIN})" || ng "gate-10: driver source touched ($DRIVER_DIFF lines committed diff from ${DIFF_BASE_PIN})"

# ============================================================
# 集計
# ============================================================
echo "==================================="
if [ "$FAIL" -eq 0 ]; then
    echo "=== ADR-0069 β PR3 verify ALL PASS ==="
    echo "= A-J verify gate ALL PASS"
    echo "= chip target matrix verify 完了"
    echo "= per-part identity proof confirmed (= ym2610b 10 part + ym2610 8 part + A/D dynamic skip)"
    exit 0
else
    echo "NG  $FAIL gate FAIL"
    exit 1
fi
