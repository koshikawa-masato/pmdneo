#!/usr/bin/env bash
#
# ADR-0020 step 6-a verify script (= silent-bcef.mml audio isolation)
#
# 目的:
#   step 5 ε-c で残った FM 同居 audio finding に対し、 ADR-0020 §決定 2
#   (= silent-bcef fixture first choice) に基づき、 MML_INPUTS を
#   silent-bcef.mml に差替えて FM keyon (= reg 0x28) 0 件を確認する。
#   並走する PMDDOTNET_MML=l-q-rhythm-song.mml の .MN direct path で
#   L-Q ADPCM-A 6 ch のみ発音される状態を成立させる。
#
# 検証: 7 段階 trace gate (= ε-b 6 gate + gate F)
#   gate 1: silent-bcef + l-q-rhythm-song build + trace
#   gate F: FM keyon (= reg 0x28 高 nibble = F) for B/C/E/F = 0 件 (= 6-a 主目的)
#   gate 2: 6 ch ADPCM-A workarea independence (= ε-b gate 2 と同等)
#   gate 3: 6 ch ADPCM-A sample addr (= ε-b gate 3 と同等)
#   gate 4: 6 ch ADPCM-A volume/pan (= ε-b gate 4 と同等)
#   gate 5: 6 ch ADPCM-A simultaneous + rhythm keyon (= ε-b gate 5 と同等)
#   gate 6: 6 ch ADPCM-A register isolation (= ε-b gate 6 と同等)
#
# source 分離 (= step 5 規律踏襲):
#   z80-mem-trace = gate 2 (= workarea)
#   ymfm-trace    = gate F / 3-6 (= chip register)
#
# audio gate:
#   ymfm-trace 経由の primary gate が PASS した後、 human listening reference
#   として MAME 起動 + wav 再生で「ADPCM-A L-Q 6 音 + FM 同居音なし」 を体感確認。
#   wav sha256 は timing-sensitive reference (= primary gate にしない)。
#
# 使い方:
#   bash src/test-fixtures/step6/verify-silent-bcef-audio-isolation.sh
#
# Exit code:
#   0 = PASS、 1 = verify fail、 2 = infra fail

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

SILENT_MML="$PROJECT_ROOT/src/test-fixtures/step6/silent-bcef.mml"
SONG_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
TMPDIR=$(mktemp -d "/tmp/pmdneo-step6a-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

if [[ ! -f "$SILENT_MML" ]]; then
    echo "FAIL infra: silent-bcef fixture not found: $SILENT_MML"
    exit 2
fi
if [[ ! -f "$SONG_MML" ]]; then
    echo "FAIL infra: l-q rhythm song fixture not found: $SONG_MML"
    exit 2
fi

# ============================================================
# gate 1: silent-bcef + l-q-rhythm-song build + trace
# ============================================================
echo "=== gate 1: silent-bcef + l-q-rhythm-song build + trace ==="
MML_INPUTS="$SILENT_MML" \
PMDDOTNET_MML="$SONG_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build.log" 2>&1 || {
    echo "  ❌ FAIL infra: build failed"
    echo "  build.log tail:"
    tail -30 "$TMPDIR/build.log"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run.log" 2>&1 || {
    echo "  ❌ FAIL infra: MAME run failed"
    echo "  run.log tail:"
    tail -30 "$TMPDIR/run.log"
    exit 2
}
Z80_TRACE="/tmp/pmdneo-trace/z80-mem-trace.tsv"
YMFM_TRACE="/tmp/pmdneo-trace/ymfm-trace.tsv"
if [[ ! -f "$Z80_TRACE" ]] || [[ ! -f "$YMFM_TRACE" ]]; then
    echo "  ❌ FAIL infra: trace file missing"
    exit 2
fi
WAV_SHA=$(shasum -a 256 /tmp/pmdneo-trace/audio.wav | awk '{print $1}')
echo "  ✅ build + trace 取得 (wav: ${WAV_SHA:0:16}...)"

# ============================================================
# gate F: FM keyon (= reg 0x28、 高 nibble = F) for B/C/E/F = 0 件 (= 6-a 主目的)
# ============================================================
echo ""
echo "=== gate F: FM keyon 0 件 (= reg 0x28 高 nibble = F、 silent BCEF 主目的) ==="

# reg 0x28 (port A) で高 nibble = F (= keyon all 4 ops) は B/C/E/F どの ch でも 0 件期待
# YM2610 reg 0x28 format: bits 4-7 = op mask (F = 全 op keyon)、 bits 0-2 = ch (0=A, 1=B, 2=C, 4=D, 5=E, 6=F)
# silent BCEF fixture では FM stream 全 part [0x80] なので keyon 命令 0 件期待
# 一方 keyoff (= 高 nibble = 0) は init で必ず走るので 0 件期待しない

FM_KEYON_TOTAL=$(awk -F'\t' '$2 == "A" && toupper($3) == "028" && substr(toupper($4),1,1) == "F" {print}' "$YMFM_TRACE" | wc -l | tr -d ' ')
if [[ "$FM_KEYON_TOTAL" -ne 0 ]]; then
    echo "  ❌ FAIL gate F: FM keyon 検出 ($FM_KEYON_TOTAL 件、 silent BCEF で 0 件期待)"
    echo "  検出 keyon writes:"
    awk -F'\t' '$2 == "A" && toupper($3) == "028" && substr(toupper($4),1,1) == "F" {print "    " $0}' "$YMFM_TRACE" | head -10
    exit 1
fi
echo "  ✅ FM keyon (= reg 0x28 高 nibble = F) = 0 件 (= silent BCEF audio isolation 成立)"

# 参考: FM keyoff (= 高 nibble = 0) は init で複数件入る期待
FM_KEYOFF_TOTAL=$(awk -F'\t' '$2 == "A" && toupper($3) == "028" && substr(toupper($4),1,1) == "0" {print}' "$YMFM_TRACE" | wc -l | tr -d ' ')
echo "  (参考: FM keyoff = $FM_KEYOFF_TOTAL 件、 init silence 由来)"

# ============================================================
# gate 2: 6 ch ADPCM-A workarea independence (= ε-b gate 2 同等)
# ============================================================
echo ""
echo "=== gate 2: 6 ch ADPCM-A workarea independence (= PART_OFF_INSTRUMENT) ==="

CH_NAMES=("L" "M" "N" "O" "P" "Q")
INST_ADDRS=("FAFF" "FB3F" "FB7F" "FBBF" "FBFF" "FC3F")
EXPECTED_VOICES=("00" "01" "02" "03" "04" "05")

GATE2_PASS=1
for i in 0 1 2 3 4 5; do
    CH="${CH_NAMES[$i]}"
    ADDR="${INST_ADDRS[$i]}"
    EXP="${EXPECTED_VOICES[$i]}"
    OBS=$(awk -F'\t' -v a="$ADDR" '$3 == a {v=$4} END {print v}' "$Z80_TRACE")
    OBS_U=$(echo "$OBS" | tr 'a-f' 'A-F')
    if [[ "$OBS_U" != "$EXP" ]]; then
        echo "  ❌ $CH (= 0x$ADDR): expected 0x$EXP, observed 0x$OBS"
        GATE2_PASS=0
    else
        echo "  ✅ $CH (= 0x$ADDR): voice idx 0x$OBS"
    fi
done
if [[ "$GATE2_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 2"
    exit 1
fi

# ============================================================
# gate 3: 6 ch ADPCM-A sample addr (= ε-b gate 3 同等)
# ============================================================
echo ""
echo "=== gate 3: 6 ch ADPCM-A sample addr (= ch overlap、 全 ch 異なる) ==="

START_LSB_REGS=("110" "111" "112" "113" "114" "115")
declare -a START_LSB_VALUES
for i in 0 1 2 3 4 5; do
    CH="${CH_NAMES[$i]}"
    REG="${START_LSB_REGS[$i]}"
    VAL=$(awk -F'\t' -v r="$REG" '$2 == "B" && $3 == r {print $4; exit}' "$YMFM_TRACE")
    if [[ -z "$VAL" ]]; then
        echo "  ❌ $CH (= reg $REG): write 不検出"
        exit 1
    fi
    START_LSB_VALUES[$i]="$VAL"
    echo "  $CH (= reg $REG): 0x$VAL"
done

UNIQ=$(printf '%s\n' "${START_LSB_VALUES[@]}" | sort -u | wc -l | tr -d ' ')
if [[ "$UNIQ" -ne 6 ]]; then
    echo "  ❌ FAIL gate 3: 6 ch sample addr が全 unique でない (uniq=$UNIQ)"
    exit 1
fi
echo "  ✅ 全 6 ch で異なる sample addr (= bd/sd/hh/tom/rim/top)"

# ============================================================
# gate 4: 6 ch ADPCM-A volume/pan (= ε-b gate 4 同等)
# ============================================================
echo ""
echo "=== gate 4: 6 ch ADPCM-A volume/pan (= reg 0x08+ch、 各 ch v cmd 由来) ==="

VOL_REGS=("108" "109" "10A" "10B" "10C" "10D")
declare -a VOL_VALUES
for i in 0 1 2 3 4 5; do
    CH="${CH_NAMES[$i]}"
    REG="${VOL_REGS[$i]}"
    REG_U=$(echo "$REG" | tr 'a-f' 'A-F')
    VAL=$(awk -F'\t' -v r="$REG_U" '$2 == "B" && toupper($3) == r {print $4; exit}' "$YMFM_TRACE")
    if [[ -z "$VAL" ]]; then
        echo "  ❌ $CH (= reg 0x08+$i): write 不検出"
        exit 1
    fi
    VOL_VALUES[$i]="$VAL"
    echo "  $CH (= reg 0x08+$i): 0x$VAL"
done
echo "  ✅ 6 ch 全部 reg 0x08+ch に v cmd 由来 vol/pan 書込確認"

# ============================================================
# gate 5: 6 ch ADPCM-A simultaneous + rhythm keyon (= ε-b gate 5 同等)
# ============================================================
echo ""
echo "=== gate 5: 6 ch ADPCM-A simultaneous + rhythm keyon (= reg 0x00 連発) ==="

EXPECTED_KEYONS=("01" "02" "04" "08" "10" "20")
GATE5_PASS=1
TOTAL_KEYON=0
for EXP in "${EXPECTED_KEYONS[@]}"; do
    COUNT=$(awk -F'\t' -v v="$EXP" '$2 == "B" && $3 == "100" && toupper($4) == toupper(v)' "$YMFM_TRACE" | wc -l | tr -d ' ')
    if [[ "$COUNT" -eq 0 ]]; then
        echo "  ❌ ch keyon bit 0x$EXP: 不検出"
        GATE5_PASS=0
    else
        TOTAL_KEYON=$((TOTAL_KEYON + COUNT))
        echo "  ✅ ch keyon bit 0x$EXP: $COUNT 件"
    fi
done

if [[ "$GATE5_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 5: 6 ch simultaneous keyon 不完全"
    exit 1
fi
echo "  ✅ 総 keyon 数 $TOTAL_KEYON (= 初回 6 + リズム連発)"

# ============================================================
# gate 6: 6 ch ADPCM-A register isolation (= ε-b gate 6 同等)
# ============================================================
echo ""
echo "=== gate 6: register isolation (= 5 reg group × 6 ch 全部 write) ==="

REG_GROUPS=("110:111:112:113:114:115" "118:119:11A:11B:11C:11D" "120:121:122:123:124:125" "128:129:12A:12B:12C:12D" "108:109:10A:10B:10C:10D")
GROUP_NAMES=("start LSB" "start MSB" "stop LSB" "stop MSB" "vol/pan")

GATE6_PASS=1
for g in 0 1 2 3 4; do
    GROUP="${REG_GROUPS[$g]}"
    NAME="${GROUP_NAMES[$g]}"
    IFS=':' read -r -a REGS <<< "$GROUP"
    MISSING=""
    for r in "${REGS[@]}"; do
        UR=$(echo "$r" | tr 'a-f' 'A-F')
        COUNT=$(awk -F'\t' -v r="$UR" '$2 == "B" && toupper($3) == r' "$YMFM_TRACE" | wc -l | tr -d ' ')
        if [[ "$COUNT" -eq 0 ]]; then
            MISSING="$MISSING $r"
        fi
    done
    if [[ -n "$MISSING" ]]; then
        echo "  ❌ $NAME: write 不検出 reg$MISSING"
        GATE6_PASS=0
    else
        echo "  ✅ $NAME: 6 ch 全 reg write"
    fi
done

if [[ "$GATE6_PASS" -eq 0 ]]; then
    echo "  ❌ FAIL gate 6: register isolation 不完全"
    exit 1
fi

# ============================================================
# 全 gate PASS
# ============================================================
echo ""
echo "🎉 ADR-0020 step 6-a verify PASS"
echo "   - gate 1: silent-bcef + l-q-rhythm-song build + trace ✅"
echo "   - gate F: FM keyon (= reg 0x28) = 0 件 (= audio isolation 成立) ✅"
echo "   - gate 2: workarea independence ✅"
echo "   - gate 3: ch overlap (= 6 ch sample addr 全 unique) ✅"
echo "   - gate 4: volume/pan (= 6 ch v cmd 由来 reg 0x08+ch) ✅"
echo "   - gate 5: simultaneous + rhythm keyon (= $TOTAL_KEYON 件) ✅"
echo "   - gate 6: register isolation (= 5 reg group × 6 ch) ✅"
echo ""
echo "   wav sha256 (= human listening reference、 primary gate にしない):"
echo "     $WAV_SHA"
echo ""
echo "   human listening (= 別軸 audio gate):"
echo "     bash scripts/run-mame.sh"
echo "     → ADPCM-A L-Q 6 音だけ聴き取れる (= FM 同居なし) ことを耳で確認"
exit 0
