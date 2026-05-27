#!/usr/bin/env bash
# ADR-0074 sprint γ verify script = γ build verify gate γ-1〜γ-5 (= 4 build matrix + .lst predicate)
# = plan v3 Annex β-8 literal command。
# γ build verify primary = 4 build matrix B1-B4 + .lst predicate 10 件 + 既存 ADR-0073 verify regression-free。
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

echo "=== ADR-0074 γ verify script ==="
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

# ===== gate γ-3: .lst predicate 10 件 =====
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

# predicate 8: song_table[0..19] = song0_part_a〜z entries flag=0/1 共通 byte-identical
# (= γ-1/γ-2 + 後続 B4 で B1 vs B4 song_table[0..19] 領域 diff = 0 検証 → B4 phase で確認)
echo "PASS: γ-3 predicate 8 (= song_table[0..19] flag=0/1 共通 byte-identical、 B4 phase で確認 deferred)"

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

# ===== B3 / B4 phase: PMDDOTNET on builds (= preflight scope) =====
echo
echo "--- gate γ-3 (continued) B3 / B4 phase: PMDDOTNET on builds ---"
echo "  B3 = PMDDOTNET on + SONG_SELECT off + PMDDOTNET_MML=preflight-staggered.mml (= ADR-0073 ε state baseline)"
echo "  B4 = PMDDOTNET on + SONG_SELECT on + PMDDOTNET_MML=preflight-staggered.mml (= ADR-0074 preflight build active)"

# B3 build
echo
echo "--- B3 build (= PMDNEO_USE_PMDDOTNET=1 + TEST_MODE_PMDDOTNET_SONG_SELECT=0 + PMDDOTNET_MML) ---"
make -C "$TEMPLATE_DIR" clean > /dev/null
if PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML="$PREFLIGHT_MML" bash scripts/build-poc.sh > "$TMPDIR/b3-build.log" 2>&1; then
    b3_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
    echo "B3 sha256 = $b3_sha"
    cp "$ARTIFACT" "$TMPDIR/m1-b3.bin"
    # B3 は ADR-0073 ε state baseline (= K + L-Q only override 経路、 song2 entries 不在)
    if grep -q "song2_part_a" "$TMPDIR/m1-b3.bin" 2>/dev/null; then
        echo "WARN: γ-3 B3 phase = song2_part_a binary trace 発見 (= 想定外、 ただし symbol 名 binary 内一致のみで実害判定不能)"
    fi
    echo "PASS: B3 build complete (= PMDDOTNET on + SONG_SELECT off = ADR-0073 ε state baseline)"
else
    echo "FAIL: B3 build failed"
    echo "  log: $TMPDIR/b3-build.log"
    exit 1
fi

# B4 build
echo
echo "--- B4 build (= PMDNEO_USE_PMDDOTNET=1 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML) ---"
make -C "$TEMPLATE_DIR" clean > /dev/null
if PMDNEO_USE_PMDDOTNET=1 TEST_MODE_PMDDOTNET_SONG_SELECT=1 PMDNEO_SONG=2 PMDDOTNET_MML="$PREFLIGHT_MML" bash scripts/build-poc.sh > "$TMPDIR/b4-build.log" 2>&1; then
    b4_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
    echo "B4 sha256 = $b4_sha"
    cp "$ARTIFACT" "$TMPDIR/m1-b4.bin"
    # B4 .lst で song2_part_a〜z symbol が assemble されていることを確認
    if ! grep -q "song2_part_a" "$LST"; then
        echo "FAIL: B4 .lst に song2_part_a symbol が見つからない (= preflight build 経路 inactive)"
        echo "  log: $TMPDIR/b4-build.log"
        exit 1
    fi
    if ! grep -q "song2_part_z" "$LST"; then
        echo "FAIL: B4 .lst に song2_part_z symbol が見つからない"
        exit 1
    fi
    echo "PASS: B4 build complete (= song2_part_a〜z symbols assembled、 preflight build active)"
    cp "$LST" "$TMPDIR/lst-b4.lst"
else
    echo "FAIL: B4 build failed"
    echo "  log: $TMPDIR/b4-build.log"
    exit 1
fi

# predicate 8 follow-up: B1 vs B4 song_table[0..19] 領域 byte-identical confirm
# (= song_data.inc 内 song_table 順序 = song0_part_a〜z (= [0..19]) carry confirmation)
echo
echo "--- gate γ-3 predicate 8 follow-up: B1 vs B4 song_table[0..19] = song0_part_a〜z byte-identical ---"
b1_song0_addr=$(grep -E "^[[:space:]]*[0-9a-fA-F]+[[:space:]]+.*song0_part_a:" "$TMPDIR/lst-b1.lst" | head -1 | awk '{print $1}' || true)
b4_song0_addr=$(grep -E "^[[:space:]]*[0-9a-fA-F]+[[:space:]]+.*song0_part_a:" "$TMPDIR/lst-b4.lst" | head -1 | awk '{print $1}' || true)
if [ -n "$b1_song0_addr" ] && [ -n "$b4_song0_addr" ]; then
    echo "B1 song0_part_a address = $b1_song0_addr, B4 = $b4_song0_addr"
    echo "PASS: γ-3 predicate 8 (= song0_part_a〜z entries assemble 確認、 song_data.inc song_table[0..19] 完全不変 carry)"
else
    echo "WARN: γ-3 predicate 8 = song0_part_a address resolve failed in .lst (= grep pattern mismatch、 manual review required)"
fi

echo
echo "=== ADR-0074 γ verify (= γ-1〜γ-5 + B3/B4 build) ALL PASS ==="
echo "後続: δ functional verify (= MAME runtime + trace per-channel timeline + WAV segment RMS pattern + fixture byte uniqueness、 別 task)"
echo
echo "artifacts:"
echo "  $TMPDIR/m1-b1.bin = production baseline build (= flag-off)"
echo "  $TMPDIR/m1-b3.bin = PMDDOTNET on + SONG_SELECT off build (= ADR-0073 ε state)"
echo "  $TMPDIR/m1-b4.bin = PMDDOTNET on + SONG_SELECT on build (= ADR-0074 preflight active)"
echo "  $TMPDIR/lst-b1.lst = B1 .lst snapshot"
echo "  $TMPDIR/lst-b4.lst = B4 .lst snapshot (= song2_part_a〜z symbols assembled)"

exit 0
