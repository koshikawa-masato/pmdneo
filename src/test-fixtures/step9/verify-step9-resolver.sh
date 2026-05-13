#!/usr/bin/env bash
#
# ADR-0023 step 9 γ: runtime .PNE filename → sample_table_id resolver verify script (= match fixture primary gate)
#
# 目的:
#   ADR-0023 §決定 9 γ で chain insertion + memory inspection primary gate を固定する。
#   γ scope では match fixture (= 0xFD32 = 0x00) のみ検証、 mismatch fixture は δ scope。
#
# 検証: 3 段階 gate (= γ scope 最小)
#   gate 1: l-q-rhythm-song.mml + PMDDOTNET_MODE=B 経由 build + trace 取得
#   gate 2: 0xFD32 (= driver_pne_sample_table_id) への write が trace に存在
#   gate 3: 0xFD32 = 0x00 (= match value、 directory entry 0 "step5.PNE" と embedded filename "step5.PNE" 一致)
#
# 検証範囲外 (= δ scope):
#   - mismatch fixture (= 0xFD32 = 0xFF) verify
#   - step 5/6/7/8 既存 verify script regression
#   - audible regression (= silent-bcef fixture)
#   - register trace = step 8 byte-identical 確認
#
# 使い方:
#   bash src/test-fixtures/step9/verify-step9-resolver.sh
#
# Exit code:
#   0 = PASS (= 全 3 gate 通過)
#   1 = verify fail (= 落ちた gate 番号 + 内容明示)
#   2 = infra fail (= build / MAME / trace file missing 等)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$PROJECT_ROOT"

SONG_MML="$PROJECT_ROOT/src/test-fixtures/step5/l-q-rhythm-song.mml"
EXPECTED_FILENAME="step5.PNE"
EXPECTED_FD32_VALUE="00"

# infra: fixture 存在確認
if [[ ! -f "$SONG_MML" ]]; then
    echo "FAIL infra: fixture not found: $SONG_MML"
    exit 2
fi

echo "=== ADR-0023 step 9 γ: runtime resolver verify (= match fixture) ==="
echo

# ============================================================
# gate 1: l-q-rhythm-song.mml + PMDDOTNET_MODE=B 経由 build + trace
# ============================================================
echo "=== gate 1: l-q-rhythm-song build + trace ==="
TMPDIR=$(mktemp -d "/tmp/pmdneo-step9-gamma-XXXXXX")
trap 'rm -rf "$TMPDIR"' EXIT

PMDDOTNET_MML="$SONG_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 \
    bash scripts/build-poc.sh > "$TMPDIR/build.log" 2>&1 || {
    echo "  [FAIL] infra: build failed (log: $TMPDIR/build.log)"
    exit 2
}
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run.log" 2>&1 || {
    echo "  [FAIL] infra: MAME run failed"
    exit 2
}
Z80_TRACE="/tmp/pmdneo-trace/z80-mem-trace.tsv"
if [[ ! -f "$Z80_TRACE" ]]; then
    echo "  [FAIL] infra: Z80 trace file missing ($Z80_TRACE)"
    exit 2
fi
echo "  [PASS] build + trace 取得 (= fixture: $SONG_MML, embedded filename: $EXPECTED_FILENAME)"

# ============================================================
# gate 2: 0xFD32 (= driver_pne_sample_table_id) への write 存在
# ============================================================
echo ""
echo "=== gate 2: driver_pne_sample_table_id (= 0xFD32) write 検出 ==="
FD32_WRITES=$(awk -F'\t' 'tolower($3) == "fd32"' "$Z80_TRACE")
FD32_COUNT=$(echo -n "$FD32_WRITES" | grep -c '' || true)
if [[ "$FD32_COUNT" -eq 0 ]]; then
    echo "  [FAIL] gate 2: 0xFD32 への write 不検出 (= resolver routine が呼ばれていない)"
    exit 1
fi
printf "  [PASS] 0xFD32 への write %d 件検出 (= L-Q part init で idempotent 呼出)\n" "$FD32_COUNT"

# ============================================================
# gate 3: 0xFD32 = 0x00 (= match value)
# ============================================================
echo ""
echo "=== gate 3: 0xFD32 = 0x$EXPECTED_FD32_VALUE (= match value) ==="
FD32_LAST_VALUE=$(echo "$FD32_WRITES" | awk -F'\t' 'END {print tolower($4)}')
if [[ "$FD32_LAST_VALUE" != "$EXPECTED_FD32_VALUE" ]]; then
    printf "  [FAIL] gate 3: observed 0xFD32 = 0x%s, expected 0x%s (= match value)\n" \
        "$FD32_LAST_VALUE" "$EXPECTED_FD32_VALUE"
    echo "         (= directory entry 0 \"$EXPECTED_FILENAME\" と embedded filename が不一致の可能性)"
    exit 1
fi
# 全 write が同一 value (= idempotent) 確認
UNIQUE_VALUES=$(echo "$FD32_WRITES" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
EXPECTED_UNIQUE="$EXPECTED_FD32_VALUE "
if [[ "$UNIQUE_VALUES" != "$EXPECTED_UNIQUE" ]]; then
    printf "  [FAIL] gate 3: 0xFD32 write values not idempotent (got: %s, expected: %s)\n" \
        "$UNIQUE_VALUES" "$EXPECTED_UNIQUE"
    exit 1
fi
printf "  [PASS] 0xFD32 = 0x%s (= match、 全 %d 件 idempotent)\n" "$FD32_LAST_VALUE" "$FD32_COUNT"

echo ""
echo "=== ADR-0023 step 9 γ verify: 全 3 gate PASS ==="
echo "    fixture:           $SONG_MML"
echo "    embedded filename: $EXPECTED_FILENAME"
echo "    0xFD32:            0x$EXPECTED_FD32_VALUE (= match)"
echo "    write count:       $FD32_COUNT (= L-Q 6 part idempotent)"
echo ""
echo "    次 step: δ で mismatch fixture (= 0xFD32 = 0xFF) verify + 既存 regression + audible + ADR Accepted"
