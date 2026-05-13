#!/usr/bin/env bash
#
# ADR-0023 step 9 γ + δ: runtime .PNE filename → sample_table_id resolver verify script (= match + mismatch primary gate)
#
# 目的:
#   ADR-0023 §決定 9 γ で chain insertion + match primary gate を固定。
#   δ で mismatch primary gate を追加 (= ROM patch approach、 source 不変)。
#
# 検証: 5 段階 gate
#   gate 1: l-q-rhythm-song.mml + PMDDOTNET_MODE=B 経由 build + trace 取得 (= match fixture)
#   gate 2: 0xFD32 (= driver_pne_sample_table_id) への write が trace に存在
#   gate 3: 0xFD32 = 0x00 (= match value、 directory entry 0 "step5.PNE" と embedded filename 一致)
#   gate 4: ROM patch (= directory entry 0 を 1 byte 改変、 'step5.PNE' → 'Step5.PNE')
#   gate 5: 0xFD32 = 0xFF (= mismatch value、 terminator hit path)
#
# 検証範囲外 (= δ 別 step):
#   - step 5/6/7/8 既存 verify script regression (= 別 script を serial 実行)
#   - audible regression (= silent-bcef fixture、 user 試聴)
#   - register trace = step 8 byte-identical 確認 (= step 8 既存 verify で担保)
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

# ============================================================
# gate 4-5: mismatch verify (= ROM patch approach、 source 不変)
# ============================================================
# directory entry 0 の filename を 1 byte 改変 ('step5.PNE' → 'Step5.PNE') した
# patched ROM で MAME 起動。 driver_pne_filename_buf = 'step5.PNE' (= unchanged)
# と directory entry 'Step5.PNE' が不一致 → terminator hit → 0xFD32 = 0xFF
ROM_PATH="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
DIRECTORY_OFFSET=0x104E  # γ build 時の standalone_test.lst で確認した pne_sample_directory 先頭 addr
ROM_BACKUP="$TMPDIR/243-m1.m1.original"

echo ""
echo "=== gate 4: mismatch verify ROM patch (= entry 0 を 'Step5.PNE' に 1 byte 改変、 source 不変) ==="
if [[ ! -f "$ROM_PATH" ]]; then
    echo "  [FAIL] gate 4 infra: ROM not found at $ROM_PATH"
    exit 2
fi
cp "$ROM_PATH" "$ROM_BACKUP"
# trap で MAME run 失敗時も ROM revert を保証
trap 'cp "$ROM_BACKUP" "$ROM_PATH" 2>/dev/null || true; rm -rf "$TMPDIR"' EXIT

# Python で ROM の DIRECTORY_OFFSET byte 0 (= 's' = 0x73) を 'S' (= 0x53) に変える
python3 - "$ROM_PATH" "$DIRECTORY_OFFSET" <<'PYEOF'
import sys
rom_path = sys.argv[1]
offset = int(sys.argv[2], 16)
with open(rom_path, "r+b") as f:
    f.seek(offset)
    before = f.read(1)
    if before != b's':
        sys.stderr.write(f"FAIL: expected 's' at 0x{offset:04X}, got {before!r}\n")
        sys.exit(1)
    f.seek(offset)
    f.write(b'S')
print(f"patched ROM at 0x{offset:04X}: 's' (0x73) -> 'S' (0x53)")
PYEOF
echo "  [PASS] ROM patch 適用 (= entry 0 filename: step5.PNE -> Step5.PNE)"

echo ""
echo "=== gate 5: mismatch trace (= 0xFD32 = 0xFF terminator hit path) ==="
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace \
    > "$TMPDIR/run_mismatch.log" 2>&1 || {
    echo "  [FAIL] gate 5 infra: MAME run on patched ROM failed"
    exit 2
}
if [[ ! -f "$Z80_TRACE" ]]; then
    echo "  [FAIL] gate 5 infra: Z80 trace file missing after mismatch run"
    exit 2
fi
MISMATCH_WRITES=$(awk -F'\t' 'tolower($3) == "fd32"' "$Z80_TRACE")
MISMATCH_COUNT=$(echo -n "$MISMATCH_WRITES" | grep -c '' || true)
if [[ "$MISMATCH_COUNT" -eq 0 ]]; then
    echo "  [FAIL] gate 5: 0xFD32 への write 不検出 (= mismatch path も走っていない可能性)"
    exit 1
fi
MISMATCH_LAST=$(echo "$MISMATCH_WRITES" | awk -F'\t' 'END {print tolower($4)}')
MISMATCH_UNIQUE=$(echo "$MISMATCH_WRITES" | awk -F'\t' '{print tolower($4)}' | sort -u | tr '\n' ' ')
EXPECTED_MISMATCH_UNIQUE="ff "
if [[ "$MISMATCH_UNIQUE" != "$EXPECTED_MISMATCH_UNIQUE" ]]; then
    printf "  [FAIL] gate 5: 0xFD32 values not all 0xff (got: %s, expected: %s)\n" \
        "$MISMATCH_UNIQUE" "$EXPECTED_MISMATCH_UNIQUE"
    exit 1
fi
printf "  [PASS] 0xFD32 = 0x%s (= mismatch sentinel、 全 %d 件 idempotent、 terminator hit path)\n" \
    "$MISMATCH_LAST" "$MISMATCH_COUNT"

# ROM revert (= trap でも実行されるが明示)
cp "$ROM_BACKUP" "$ROM_PATH"
echo "  [INFO] ROM patch revert 完了 (= source 不変、 build artifact のみ patch だった)"

echo ""
echo "=== ADR-0023 step 9 γ + δ verify: 全 5 gate PASS ==="
echo "    fixture:           $SONG_MML"
echo "    embedded filename: $EXPECTED_FILENAME"
echo "    match (gate 3):    0xFD32 = 0x$EXPECTED_FD32_VALUE (= 6 件 idempotent)"
echo "    mismatch (gate 5): 0xFD32 = 0xff (= $MISMATCH_COUNT 件 idempotent、 ROM 1 byte patch path)"
echo ""
echo "    次 step: 既存 step 5/6/7/8 verify regression serial 実行 + audible 試聴 + ADR-0023 Accepted"
