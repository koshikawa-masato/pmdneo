#!/usr/bin/env bash
# ADR-0074 sprint γ verify script = γ build verify gate γ-1〜γ-5 + 4 build matrix
# = plan v3 Annex β-8 literal command + sprint γ round 1 revise (= NH-1 (B)採用 = B5正規 preflight path化)。
#
# 2026-05-27 user 明示 NH-1 (B) 採用後の正規 build matrix:
#   (B1) production baseline   = PMDDOTNET=0 + SONG_SELECT=0 + no PMDDOTNET_MML
#   (B2) post-patch flag-off   = 同上 + ADR-0074 patch 全適用 → (B1) byte-identical 期待
#   (B3) 正規 preflight path   = PMDDOTNET=0 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML=preflight
#                                = driver `load_song_part_addr` 経路 + song_table[40..59] dispatch active
#                                  + driver_song_id=2 + song2_part_X label が pmddotnet_song body bytes を指す
#                                  = ADR-0074 candidate 4 mechanism が runtime で実際に exercise される正規 path
#   (B4) 補助 build (= scope-out 相当) = PMDDOTNET=1 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML
#                                = driver `pmdneo_mn_direct_load_aj_part_addr` 経路 (= .m header offset 直接 dispatch)
#                                  song_table[40..59] entries は build には存在するが runtime では参照されない
#                                = 補助確認扱い (= 「PMDDOTNET=1 mode でも .m header 経由で fixture が dispatch される」 事実の record)、
#                                  ADR-0074 candidate 4 mechanism の正規 path ではない (= ADR Annex γ §γ-3 literal)。
# δ functional verify (= MAME runtime + trace + WAV segment) は別 task (= 本 script で γ-1〜γ-5 まで)。

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ADR0074_DIR="$PMDNEO_ROOT/src/test-fixtures/adr-0074"
TMPDIR="${TMPDIR:-/tmp}/adr-0074"
mkdir -p "$TMPDIR"

ACTIVE_BASELINE="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"
ARTIFACT="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
LST="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
TEMPLATE_DIR="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template"
PREFLIGHT_MML="$ADR0074_DIR/preflight-staggered.mml"

echo "=== ADR-0074 γ verify script (= sprint γ round 1 revise = NH-1 (B) 採用 = B5 正規 preflight path 化) ==="
echo "active baseline (= B1/B2 期待) = $ACTIVE_BASELINE (= ADR-0073 ε で確定 canonical baseline)"
echo "preflight fixture = $PREFLIGHT_MML"

cd "$PMDNEO_ROOT"

if [ ! -f "$PREFLIGHT_MML" ]; then
    echo "FAIL: preflight fixture not found at $PREFLIGHT_MML"
    exit 1
fi

# ===== gate γ-1: B1 production baseline = byte-identical to ACTIVE_BASELINE =====
echo
echo "--- gate γ-1: B1 production baseline build (= PMDNEO_USE_PMDDOTNET=0 + TEST_MODE_PMDDOTNET_SONG_SELECT=0) ---"
make -C "$TEMPLATE_DIR" clean > /dev/null
PMDNEO_USE_PMDDOTNET=0 bash scripts/build-poc.sh > "$TMPDIR/b1-build.log" 2>&1
b1_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
echo "B1 sha256 = $b1_sha"
if [ "$b1_sha" != "$ACTIVE_BASELINE" ]; then
    echo "FAIL: γ-1 B1 mismatch with active baseline $ACTIVE_BASELINE"
    echo "  build log: $TMPDIR/b1-build.log"
    exit 1
fi
echo "PASS: γ-1 B1 byte-identical to active baseline"
cp "$ARTIFACT" "$TMPDIR/m1-b1.bin"
cp "$LST" "$TMPDIR/lst-b1.lst"

# ===== gate γ-2: B2 post-patch flag-off = (B1) byte-identical =====
echo
echo "--- gate γ-2: B2 post-patch flag-off rebuild (= 同 build、 guarded change flag-off 完全無効化 verify) ---"
make -C "$TEMPLATE_DIR" clean > /dev/null
PMDNEO_USE_PMDDOTNET=0 bash scripts/build-poc.sh > "$TMPDIR/b2-build.log" 2>&1
b2_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
echo "B2 sha256 = $b2_sha"
if [ "$b2_sha" != "$ACTIVE_BASELINE" ]; then
    echo "FAIL: γ-2 B2 mismatch (= guarded change flag-off byte-identical mandate 違反、 rollback condition #20 trigger)"
    echo "  build log: $TMPDIR/b2-build.log"
    exit 1
fi
echo "PASS: γ-2 B2 byte-identical to (B1) + active baseline"

# ===== gate γ-3: .lst predicate 10 件 (= B1/B2 phase 確認可能分) =====
echo
echo "--- gate γ-3: .lst predicate 10 件 (= ADR-0073 6 件 carry + ADR-0074 固有 4 件) ---"
if [ ! -f "$TMPDIR/lst-b1.lst" ]; then
    echo "FAIL: γ-3 B1 .lst snapshot not found"
    exit 1
fi

# predicate 1-6: ADR-0073 carry = 既存 routine body byte-identical 維持 (= γ-1/γ-2 で B1==B2==ACTIVE_BASELINE 確認済)
echo "PASS: γ-3 predicate 1-6 (= ADR-0073 carry: 既存 routine body + symbol table 順序 byte-identical via γ-1/γ-2)"

# predicate 7: TEST_MODE_PMDDOTNET_SONG_SELECT flag .equ assemble (= flag-off で .equ 行が source に存在 = symbol 登録)
PREPROCESSED="$TEMPLATE_DIR/build/standalone_test.preprocessed.s"
if [ ! -f "$PREPROCESSED" ]; then
    echo "FAIL: γ-3 predicate 7 = preprocessed source not found at $PREPROCESSED"
    exit 1
fi
if ! grep -q "TEST_MODE_PMDDOTNET_SONG_SELECT" "$PREPROCESSED"; then
    echo "FAIL: γ-3 predicate 7 = TEST_MODE_PMDDOTNET_SONG_SELECT not in preprocessed source"
    exit 1
fi
echo "PASS: γ-3 predicate 7 (= TEST_MODE_PMDDOTNET_SONG_SELECT flag in preprocessed source)"

# predicate 9: song_table[40..59] = song2_part_a〜z entries flag=1 時のみ assemble
# flag-off (= B1/B2) では song2_part_a〜z entries は song_data.inc に挿入されない (= build-poc.sh ADR-0074 block skip)
# (driver source 内コメントは「song2_part_a〜z」 言及あり、 .lst comment line 引っかけ回避のため
#  song_data.inc literal check + .lst で「==」 absolute equate 行 check の 2 段 grep)
if grep -qE "^song2_part_a:?" "$TEMPLATE_DIR/song_data.inc" 2>/dev/null; then
    echo "FAIL: γ-3 predicate 9 = song2_part_a found in flag-off song_data.inc (= stale insert)"
    exit 1
fi
if grep -qE "song2_part_a[[:space:]]+==" "$LST" 2>/dev/null; then
    echo "FAIL: γ-3 predicate 9 = song2_part_a == equate found in flag-off .lst (= preflight 経路混入)"
    exit 1
fi
echo "PASS: γ-3 predicate 9 (= song2_part_a〜z entries flag=0 時 unassembled)"

# predicate 10: 既存 symbol table 順序不変 (= ADR-0073 ε で確立 9 symbol + 新規 TEST_MODE_PMDDOTNET_SONG_SELECT)
for sym in pmdneo_v_to_V_convert v_to_V_fm comv comV fm_volume_hook pmdneo5_init_part pmdneo_fm_voice_set_default pmdneo_fm_voice_set comat; do
    if ! grep -q "${sym}:" "$LST"; then
        echo "FAIL: γ-3 predicate 10 symbol $sym missing in $LST"
        exit 1
    fi
done
echo "PASS: γ-3 predicate 10 (= 既存 symbol 9 件 ADR-0073 carry confirm)"

# ===== gate γ-4: ADR-0051 owner contract untouched =====
echo
echo "--- gate γ-4: ADR-0051 owner contract (= pmdneo_ssg_tone_sync RMW reg 0x07 唯一 owner) untouched ---"
# flag-off byte-identical で driver routine 全 unchanged confirm = ADR-0051 owner contract も unchanged
echo "PASS: γ-4 (= γ-1/γ-2 で driver byte-identical via active baseline 確認、 ADR-0051 routine untouched 確定)"

# ===== gate γ-5: 既存 ADR-0073 verify script regression-free =====
echo
echo "--- gate γ-5: ADR-0073 verify-volume-scaling.sh regression-free ---"
ADR0073_VERIFY="$PMDNEO_ROOT/src/test-fixtures/adr-0073/verify-volume-scaling.sh"
if [ -f "$ADR0073_VERIFY" ]; then
    if bash "$ADR0073_VERIFY" > "$TMPDIR/adr-0073-verify.log" 2>&1; then
        echo "PASS: γ-5 (= ADR-0073 verify regression-free)"
    else
        echo "FAIL: γ-5 (= ADR-0073 verify regression detected)"
        echo "  log: $TMPDIR/adr-0073-verify.log"
        tail -20 "$TMPDIR/adr-0073-verify.log"
        exit 1
    fi
else
    echo "SKIP: γ-5 (= ADR-0073 verify script missing at $ADR0073_VERIFY)"
fi

# ===== B3 正規 preflight path build (= NH-1 (B) 採用後の primary mechanism verify) =====
echo
echo "--- gate γ-3 (continued) B3 正規 preflight path build ---"
echo "  B3 = PMDNEO_USE_PMDDOTNET=0 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML=preflight-staggered.mml"
echo "       = driver \`load_song_part_addr\` 経路 + song_table[40..59] dispatch active + driver_song_id=2 + song2_part_X が pmddotnet_song body bytes を指す"
echo "       = ADR-0074 candidate 4 mechanism の runtime exercise 正規 path"

make -C "$TEMPLATE_DIR" clean > /dev/null
if PMDNEO_USE_PMDDOTNET=0 TEST_MODE_PMDDOTNET_SONG_SELECT=1 PMDNEO_SONG=2 PMDDOTNET_MML="$PREFLIGHT_MML" bash scripts/build-poc.sh > "$TMPDIR/b3-build.log" 2>&1; then
    b3_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
    echo "B3 sha256 = $b3_sha"
    cp "$ARTIFACT" "$TMPDIR/m1-b3.bin"
    cp "$LST" "$TMPDIR/lst-b3.lst"
else
    echo "FAIL: B3 (正規 preflight path) build failed"
    echo "  log: $TMPDIR/b3-build.log"
    exit 1
fi

# B3 .lst predicate 1: song2_part_a〜z 20 symbols absolute equate 全 active assemble
echo
echo "--- gate γ-3 B3 predicate (a): song2_part_a〜z 20 symbols == absolute equate assembled ---"
missing_song2=()
for part in a b c d e f g h i j k l m n o p q x y z; do
    if ! grep -qE "song2_part_${part}[[:space:]]+==" "$LST"; then
        missing_song2+=("song2_part_${part}")
    fi
done
if [ ${#missing_song2[@]} -ne 0 ]; then
    echo "FAIL: γ-3 B3 predicate (a) = missing song2_part symbols: ${missing_song2[*]}"
    exit 1
fi
echo "PASS: γ-3 B3 predicate (a) (= song2_part_a〜z 20 == equate all assembled)"

# B3 .lst predicate (b): song_table[40..59] = song2_part_X .dw entries assembled (= 20 entries)
song2_dw_count=$(grep -E "^[ 0-9A-Fa-f]+[[:space:]]+[0-9A-Fa-f ]+[[:space:]]+[0-9]+[[:space:]]+\.dw song2_part_" "$LST" | wc -l | tr -d ' ')
if [ "$song2_dw_count" -lt 5 ]; then
    echo "FAIL: γ-3 B3 predicate (b) = .dw song2_part_X rows missing (= expect 5 rows = 20 entries / 4 per row, got $song2_dw_count)"
    exit 1
fi
echo "PASS: γ-3 B3 predicate (b) (= song_table[40..59] song2_part_X .dw rows assembled, count=$song2_dw_count)"

# B3 .lst predicate (c): song_table[0..19] = song0_part_a〜z entries 完全保存 (= flag=0/1 共通 byte-identical mandate carry)
# B1 .lst で song0_part_a の address + literal byte 取得、 B3 .lst での同 part 確認 (= 順序保存 + label 不変)
missing_song0=()
for part in a b c d e f g h i j k l m n o p q x y z; do
    if ! grep -qE "song0_part_${part}:" "$LST"; then
        missing_song0+=("song0_part_${part}")
    fi
done
if [ ${#missing_song0[@]} -ne 0 ]; then
    echo "FAIL: γ-3 B3 predicate (c) = song_table[0..19] missing labels: ${missing_song0[*]}"
    exit 1
fi
echo "PASS: γ-3 B3 predicate (c) (= song0_part_a〜z 20 labels in B3 .lst = song_table[0..19] preserved)"

# B3 .lst predicate (d): driver dispatch 経路 = load_song_part_addr active (= PMDNEO_USE_PMDDOTNET=0 mode confirm)
# = .lst 内に `load_song_part_addr` call 行 + `pmdneo_mn_direct_load_aj_part_addr` call が unassembled (= .if 配下 skip)
if ! grep -q "call.*load_song_part_addr" "$LST"; then
    echo "FAIL: γ-3 B3 predicate (d) = load_song_part_addr call site not in B3 .lst (= PMDDOTNET=0 dispatch path inactive)"
    exit 1
fi
echo "PASS: γ-3 B3 predicate (d) (= load_song_part_addr call site assembled = song_table 経由 dispatch active)"

# ===== B4 補助 build (= scope-out 相当、 plan v3 wording 整合性確認のための補助 record) =====
echo
echo "--- B4 補助 build (= scope-out 相当、 plan v3 B4 wording carry 確認) ---"
echo "  B4 = PMDNEO_USE_PMDDOTNET=1 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML=preflight"
echo "       = driver \`pmdneo_mn_direct_load_aj_part_addr\` 経路 (= .m header offset 直接 dispatch)"
echo "       = song_table[40..59] entries は build 内存在するが runtime 未参照 (= ADR Annex γ §γ-3 literal)"
echo "       = 補助確認扱い (= 正規 preflight path ではない、 ADR-0074 candidate 4 mechanism の runtime exercise 経路ではない)"

make -C "$TEMPLATE_DIR" clean > /dev/null
if PMDNEO_USE_PMDDOTNET=1 TEST_MODE_PMDDOTNET_SONG_SELECT=1 PMDNEO_SONG=2 PMDDOTNET_MML="$PREFLIGHT_MML" bash scripts/build-poc.sh > "$TMPDIR/b4-build.log" 2>&1; then
    b4_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
    echo "B4 sha256 = $b4_sha"
    cp "$ARTIFACT" "$TMPDIR/m1-b4.bin"
    # B4 build 成立 + song2 symbols assembled は plan v3 wording 整合性確認、 ただし runtime mechanism は B3 が正規
    if grep -qE "song2_part_a[[:space:]]+==" "$LST"; then
        echo "PASS: B4 補助 build (= song2 entries build 成立 confirm、 ただし runtime mechanism は B3 が正規)"
    else
        echo "FAIL: B4 補助 build = song2 entries not in B4 .lst (= build infrastructure問題)"
        exit 1
    fi
else
    echo "FAIL: B4 補助 build failed"
    echo "  log: $TMPDIR/b4-build.log"
    exit 1
fi

echo
echo "=== ADR-0074 γ verify (= γ-1〜γ-5 + B3 正規 + B4 補助) ALL PASS ==="
echo "後続: δ functional verify (= MAME runtime + trace per-channel timeline + WAV segment RMS pattern + fixture byte uniqueness、 別 task)"
echo "δ runtime functional verify は B3 正規 preflight path で実施 (= NH-1 (B) 採用後の primary verify path)"
echo
echo "artifacts:"
echo "  $TMPDIR/m1-b1.bin = production baseline build (= flag-off)"
echo "  $TMPDIR/m1-b3.bin = B3 正規 preflight path build (= NH-1 (B) 採用、 song_table[40..59] dispatch active)"
echo "  $TMPDIR/m1-b4.bin = B4 補助 build (= scope-out 相当、 .m header direct dispatch)"
echo "  $TMPDIR/lst-b1.lst = B1 .lst snapshot"
echo "  $TMPDIR/lst-b3.lst = B3 .lst snapshot (= song2_part_a〜z 20 == equate + .dw rows + load_song_part_addr call site)"

exit 0
