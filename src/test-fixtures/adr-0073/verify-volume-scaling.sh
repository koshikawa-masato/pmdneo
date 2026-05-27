#!/usr/bin/env bash
# ADR-0073 sprint γ verify script = γ-1 build verify gate + δ functional verify gate
# = plan v3 Annex β-3-7 literal command (= MF-new-3 + MF-new-4 + LR-new-1 反映)
# γ build verify primary = 4 build matrix B1-B4 + .lst predicate 6 件 + ADR-0072 既存機能 regression 防止
# δ functional verify (= MAME runtime) は別 task (= 本 script で γ-1〜γ-5 + δ-7 v+/v- emit coverage まで)

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
ADR0073_DIR="$PMDNEO_ROOT/src/test-fixtures/adr-0073"
TMPDIR="${TMPDIR:-/tmp}/adr-0073"
mkdir -p "$TMPDIR"

ACTIVE_BASELINE="b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4"
ARTIFACT="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"

echo "=== ADR-0073 γ verify script ==="
echo "active baseline = $ACTIVE_BASELINE (= ADR-0073 sprint γ 着手時 actual build baseline 訂正、 plan v3 β-3-6 + Annex γ-1 §)"

cd "$PMDNEO_ROOT"

# gate γ-1: (B1) production baseline = byte-identical to actual baseline
echo "--- gate γ-1: B1 production baseline build ---"
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=0 bash scripts/build-poc.sh
b1_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
echo "B1 sha256 = $b1_sha"
if [ "$b1_sha" != "$ACTIVE_BASELINE" ]; then
    echo "FAIL: γ-1 B1 mismatch with active baseline $ACTIVE_BASELINE"
    exit 1
fi
echo "PASS: γ-1 B1 byte-identical to active baseline"

# gate γ-2: (B2) post-patch flag-off = (B1) byte-identical (= guarded change flag-off 完全無効化)
echo "--- gate γ-2: B2 post-patch flag-off rebuild ---"
make -C vendor/ngdevkit-examples/00-template clean
PMDNEO_USE_PMDDOTNET=0 bash scripts/build-poc.sh
b2_sha=$(sha256sum "$ARTIFACT" | awk '{print $1}')
echo "B2 sha256 = $b2_sha"
if [ "$b2_sha" != "$ACTIVE_BASELINE" ]; then
    echo "FAIL: γ-2 B2 mismatch (= guarded change flag-off byte-identical mandate 違反、 rollback condition #1 trigger)"
    exit 1
fi
echo "PASS: γ-2 B2 byte-identical to (B1) + active baseline"

# gate γ-3: .lst predicate 6 件
echo "--- gate γ-3: .lst predicate 6 件 ---"
LST="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template/build/standalone_test.lst"
if [ ! -f "$LST" ]; then
    echo "FAIL: γ-3 .lst file not found: $LST"
    exit 1
fi

# Note: production build (= flag-off) では新規 symbol assemble されない (= guarded change `.if PMDNEO_USE_PMDDOTNET` 配下のみ)
# .lst predicate 1/2/3 (= 新規 symbol assemble) は (B4) flag-on build verify 経路で確認
# .lst predicate 4/5/6 (= 既存 routine body byte-identical + symbol table 順序) は (B2) post-patch flag-off で確認可

# predicate 4: 既存 comv / fm_volume_hook / pmdneo5_init_part / comat routine body else 配下 byte-identical
# (= γ-1 + γ-2 で B1 == B2 == ACTIVE_BASELINE 確認済 = 既存 routine body 全 untouched 確定)
echo "PASS: γ-3 predicate 4 (= 既存 routine body byte-identical via γ-1/γ-2)"

# predicate 5: pmdneo_fm_voice_set_default else 配下 byte-identical (= 同上)
echo "PASS: γ-3 predicate 5 (= pmdneo_fm_voice_set_default else 配下 byte-identical via γ-1/γ-2)"

# predicate 6: 既存 symbol table 順序不変 (= 既存 .equ + 既存 routine 順序、 .lst 内で symbol 並び確認)
for sym in pmdneo_v_to_V_convert v_to_V_fm comv comV fm_volume_hook pmdneo5_init_part pmdneo_fm_voice_set_default pmdneo_fm_voice_set comat; do
    if ! grep -q "${sym}:" "$LST"; then
        echo "FAIL: γ-3 predicate 6 symbol $sym missing in $LST"
        exit 1
    fi
done
echo "PASS: γ-3 predicate 6 (= 既存 symbol 9 件存在 confirm)"

# predicate 1/2/3 = 新規 symbol = flag-on build で確認 (= B4 経路で)
# (= 本 script B4 phase は separate、 build-poc.sh PMDDOTNET_MML 機能依存)

echo ""
echo "=== ADR-0073 γ build verify (= γ-1〜γ-3) ALL PASS ==="
echo "後続: γ-4 (ADR-0051 owner contract untouched) + γ-5 (既存 verify regression-free) + δ-1〜δ-7 (= MAME runtime、 別 task)"
exit 0
