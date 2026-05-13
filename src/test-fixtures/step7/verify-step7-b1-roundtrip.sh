#!/usr/bin/env bash
#
# ADR-0016 step 7 β-1: verify script for converter prototype round-trip
#
# 目的:
#   β-1 (= scripts/pne-pack-prototype.py + scripts/pne-to-ngdevkit.py) で成立する
#   .PNE pack → unpack の round-trip を regression test 化。 6 sample 全件 sha256
#   byte-identical を必須 gate (= 8th session user 指示)。
#
#   本 verify は β-1 commit content (= converter prototype + assets/pne/PMDNEO01.PNE)
#   が正しく動いていることの primary gate であり、 build pipeline 接続 / vendor
#   Makefile 改修 / ROM byte-identical 検証は β-2 / β-3 で扱う (= 本 verify では
#   touch なし)。
#
# 検証: 4 段階 gate
#   gate 1: pack tool が assets/pne/PMDNEO01.PNE を生成できる (= 11008 byte 期待)
#   gate 2: converter が PMDNEO01.PNE を unpack できる (= 6 .adpcma file + yaml 1 件)
#   gate 3: 6 sample 全件で 元 2608_*.adpcma と unpacked {slot}.adpcma が byte-identical
#   gate 4: 生成 yaml の構造確認 (= DO NOT EDIT comment + 6 entry + name + uri)
#
# source 分離:
#   pack tool input  = assets/sounds/adpcma/2608_*.adpcma 6 件 (= 既存 source、 不変)
#   pack tool output = assets/pne/PMDNEO01.PNE (= canonical test asset、 β-1 で生成)
#   converter input  = assets/pne/PMDNEO01.PNE
#   converter output = temp dir 内 {slot}.adpcma 6 件 + samples-map-adpcma.yaml
#
# 使い方:
#   bash src/test-fixtures/step7/verify-step7-b1-roundtrip.sh
#
# Exit code:
#   0 = PASS (= 全 4 gate PASS)
#   1 = verify fail (= gate 落ち、 出力で fail gate 明示)
#   2 = infra fail (= python3 / shasum / tool missing 等)

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PACK_TOOL="$PMDNEO_ROOT/scripts/pne-pack-prototype.py"
CONVERTER="$PMDNEO_ROOT/scripts/pne-to-ngdevkit.py"
SOURCE_DIR="$PMDNEO_ROOT/assets/sounds/adpcma"
PNE_FILE="$PMDNEO_ROOT/assets/pne/PMDNEO01.PNE"
EXPECTED_PNE_SIZE=11008
SLOTS=("bd" "sd" "hh" "rim" "tom" "top")
SLOT_UPPER=("BD" "SD" "HH" "RIM" "TOM" "TOP")

echo "=== step 7 β-1: converter prototype round-trip verify ==="
echo

# infra check
for tool in python3 shasum; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "infra fail: $tool not found in PATH" >&2
        exit 2
    fi
done
for f in "$PACK_TOOL" "$CONVERTER"; do
    if [ ! -f "$f" ]; then
        echo "infra fail: $f not found" >&2
        exit 2
    fi
done
for slot_upper in "${SLOT_UPPER[@]}"; do
    if [ ! -f "$SOURCE_DIR/2608_${slot_upper}.adpcma" ]; then
        echo "infra fail: $SOURCE_DIR/2608_${slot_upper}.adpcma not found" >&2
        exit 2
    fi
done

# gate 1: pack
echo "--- gate 1: pack (= 既存 6 .adpcma → PMDNEO01.PNE) ---"
PACK_ARGS=()
for i in "${!SLOTS[@]}"; do
    PACK_ARGS+=(--slot "${SLOTS[$i]}:$SOURCE_DIR/2608_${SLOT_UPPER[$i]}.adpcma")
done
python3 "$PACK_TOOL" --output "$PNE_FILE" "${PACK_ARGS[@]}" >/dev/null

PNE_SIZE=$(wc -c < "$PNE_FILE" | tr -d ' ')
if [ "$PNE_SIZE" != "$EXPECTED_PNE_SIZE" ]; then
    echo "  [FAIL] gate 1: PMDNEO01.PNE size $PNE_SIZE != expected $EXPECTED_PNE_SIZE"
    exit 1
fi
echo "  [PASS] gate 1: PMDNEO01.PNE = $PNE_SIZE byte (expected $EXPECTED_PNE_SIZE)"

# gate 2: unpack
echo "--- gate 2: unpack (= PMDNEO01.PNE → temp dir 内 6 .adpcma + yaml) ---"
TMPDIR=$(mktemp -d /tmp/pne-roundtrip-XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT
python3 "$CONVERTER" "$PNE_FILE" --output-dir "$TMPDIR" >/dev/null

YAML_FILE="$TMPDIR/samples-map-adpcma.yaml"
if [ ! -f "$YAML_FILE" ]; then
    echo "  [FAIL] gate 2: samples-map-adpcma.yaml not generated"
    exit 1
fi
for slot in "${SLOTS[@]}"; do
    if [ ! -f "$TMPDIR/${slot}.adpcma" ]; then
        echo "  [FAIL] gate 2: ${slot}.adpcma not generated"
        exit 1
    fi
done
echo "  [PASS] gate 2: 6 .adpcma + 1 yaml generated"

# gate 3: byte-identical (= 必須 gate、 user 指示)
echo "--- gate 3: byte-identical 検証 (= 6 sample 全件 sha256、 必須 gate) ---"
FAIL=0
for i in "${!SLOTS[@]}"; do
    slot="${SLOTS[$i]}"
    slot_upper="${SLOT_UPPER[$i]}"
    orig="$SOURCE_DIR/2608_${slot_upper}.adpcma"
    unpacked="$TMPDIR/${slot}.adpcma"
    orig_hash=$(shasum -a 256 "$orig" | awk '{print $1}')
    unpacked_hash=$(shasum -a 256 "$unpacked" | awk '{print $1}')
    if [ "$orig_hash" = "$unpacked_hash" ]; then
        echo "  [PASS] $slot: $orig_hash"
    else
        echo "  [FAIL] $slot: orig=$orig_hash unpacked=$unpacked_hash"
        FAIL=1
    fi
done
if [ "$FAIL" = "1" ]; then
    echo "  [FAIL] gate 3: byte-identical 失敗、 round-trip 不成立"
    exit 1
fi
echo "  [PASS] gate 3: 6/6 byte-identical"

# gate 4: yaml structure
echo "--- gate 4: 生成 yaml 構造確認 ---"
if ! head -1 "$YAML_FILE" | grep -q "DO NOT EDIT"; then
    echo "  [FAIL] gate 4: yaml 先頭 DO NOT EDIT comment missing"
    exit 1
fi
ENTRY_COUNT=$(grep -c "^- adpcm_a:" "$YAML_FILE")
if [ "$ENTRY_COUNT" != "6" ]; then
    echo "  [FAIL] gate 4: adpcm_a entry count $ENTRY_COUNT != 6"
    exit 1
fi
for slot in "${SLOTS[@]}"; do
    if ! grep -q "name: $slot$" "$YAML_FILE"; then
        echo "  [FAIL] gate 4: slot name '$slot' not in yaml"
        exit 1
    fi
done
echo "  [PASS] gate 4: DO NOT EDIT + 6 adpcm_a entry + 6 slot name 全件確認"

echo
echo "=== step 7 β-1 round-trip verify PASS (= 4/4 gate PASS) ==="
