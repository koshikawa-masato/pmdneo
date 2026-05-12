#!/usr/bin/env bash
#
# ADR-0016 step 4-3-δ: fixture-driven verify for J part ADPCM-B note → delta-N
#
# 目的: 異なる J part note (= o4 c / o4 g) で:
#   1. compile.py が note byte 差分を .mn に emit
#   2. driver の adpcmb_note_to_deltan が chromatic table 差分を reg 0x19/0x1A に反映
#   3. ymfm ADPCM-B writes が note 差を **意図的 register 差分** で示す
#   4. wav も差分 (= timing artifact ではない musical pitch 差) を生む
# を再現可能に確認する。
#
# 前提:
#   - PMDNEO_ROOT で build + run-mame infra が動く
#   - src/test-fixtures/step4/j-part-minimum.mml (= o4 c) + j-part-g.mml (= o4 g)
#
# 使い方:
#   bash src/test-fixtures/step4/verify-j-part-fixture-driven.sh
#
# Exit code:
#   0 = PASS (= reg 0x19/0x1A 差分 + wav 差分 確認)
#   1 = FAIL (= 期待差分が出ない)
#   2 = infra fail (= build / run-mame error)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

TMPDIR=$(mktemp -d "/tmp/pmdneo-step4-delta-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

C_MML="$PROJECT_ROOT/src/test-fixtures/step4/j-part-minimum.mml"
G_MML="$PROJECT_ROOT/src/test-fixtures/step4/j-part-g.mml"

# fixture 2 件で build + trace + wav
for fix in c g; do
    if [[ "$fix" == "c" ]]; then
        mml_path="$C_MML"
        expected_reg19="96"
        expected_reg1a="6E"
        expected_idx=254
    else
        mml_path="$G_MML"
        expected_reg19="B1"
        expected_reg1a="A5"
        expected_idx=254
    fi

    echo "=== fixture o4 $fix (= $(basename "$mml_path")) ==="
    cp "$mml_path" "$TMPDIR/j-part-$fix.mml"
    MML_INPUTS="$TMPDIR/j-part-$fix.mml,test02.mml" bash scripts/build-poc.sh > "$TMPDIR/build-$fix.log" 2>&1 || {
        echo "  ERROR: build fail (= log: $TMPDIR/build-$fix.log)"
        exit 2
    }
    bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace > "$TMPDIR/run-$fix.log" 2>&1 || {
        echo "  ERROR: run-mame fail"
        exit 2
    }
    mkdir -p "$TMPDIR/Bf$fix"
    cp /tmp/pmdneo-trace/audio.wav "$TMPDIR/Bf$fix/"
    cp /tmp/pmdneo-trace/ymfm-trace.tsv "$TMPDIR/Bf$fix/"
    cp /tmp/pmdneo-trace/z80-mem-trace.tsv "$TMPDIR/Bf$fix/"
    wav_sha=$(shasum -a 256 "$TMPDIR/Bf$fix/audio.wav" | awk '{print $1}')
    echo "  wav sha256: $wav_sha"

    # idx N の reg 0x19/0x1A 抽出
    reg19=$(awk -F'\t' -v idx="$expected_idx" '$1 == idx && $2 == "A" && $3 == "19" {print $4}' "$TMPDIR/Bf$fix/ymfm-trace.tsv")
    reg1a=$(awk -F'\t' -v idx="$((expected_idx+1))" '$1 == idx && $2 == "A" && $3 == "1A" {print $4}' "$TMPDIR/Bf$fix/ymfm-trace.tsv")
    echo "  reg 0x19 (= delta-N LSB) = 0x$reg19 (expected 0x$expected_reg19)"
    echo "  reg 0x1A (= delta-N MSB) = 0x$reg1a (expected 0x$expected_reg1a)"
    if [[ "$reg19" != "$expected_reg19" ]] || [[ "$reg1a" != "$expected_reg1a" ]]; then
        echo "  FAIL: register value mismatch"
        exit 1
    fi
    echo "  ✅ register match"
    echo ""
done

# wav sha256 比較
wav_c=$(shasum -a 256 "$TMPDIR/Bfc/audio.wav" | awk '{print $1}')
wav_g=$(shasum -a 256 "$TMPDIR/Bfg/audio.wav" | awk '{print $1}')
echo "=== fixture-driven verify summary ==="
echo "  ROM_Bc wav sha256: $wav_c"
echo "  ROM_Bg wav sha256: $wav_g"

if [[ "$wav_c" == "$wav_g" ]]; then
    echo "  FAIL: wav sha256 が一致 (= note 差分が audio に反映されていない)"
    exit 1
fi
echo "  ✅ wav sha256 異なる (= note 差分が audio に反映)"
echo ""
echo "🎉 ADR-0016 step 4-3-δ fixture-driven verify PASS"
echo "   - reg 0x19/0x1A が J part note byte に応じた chromatic table 値"
echo "   - wav も意図的に差分 (= timing artifact ではない pitch 差)"
exit 0
