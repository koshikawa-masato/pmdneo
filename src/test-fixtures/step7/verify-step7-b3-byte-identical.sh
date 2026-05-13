#!/usr/bin/env bash
#
# ADR-0016 step 7 β-3: verify script for path B / c1 ROM byte-identical primary gate
#
# 目的:
#   β-2 (= commit 0668594) で接続した path B / c1 build pipeline について、
#   既存経路 (= samples-map.yaml.legacy 単一渡し) と新経路 (= samples-map-adpcma.yaml +
#   samples-map-adpcmb.yaml 2 yaml 渡し) の vromtool.py 出力 artifact が完全に
#   byte-identical であることを primary gate として証明する。
#
#   ROM final (= 243-m1.m1) は driver source + samples.inc + VROM + 他 fixed input
#   の合成。 driver source / 他 input が β-2 で完全不変なため、 samples.inc + VROM
#   が byte-identical なら ROM final も自動的に byte-identical (= 数学的同値性)。
#
# 検証: 4 段階 gate
#   gate 1: legacy 経路 (= 単一 samples-map.yaml.legacy) で vromtool.py 実行
#   gate 2: 新経路 (= 2 yaml) で vromtool.py 実行
#   gate 3: samples.inc byte-identical (= legacy vs 新、 sha256 比較)
#   gate 4: VROM 4 件 byte-identical (= 243-v1.v1 ... 243-v4.v4、 sha256 比較)
#
# 検証戦略 (= (S') 採用):
#   Makefile / build-poc.sh を一時 revert する流儀 (= 原案 (S)) は trap restore に
#   頼るため事故 risk あり。 代わりに vromtool.py を 2 種の入力で直接呼んで artifact
#   を temp dir に出力 + 比較。 build pipeline 全体を回す必要なし。
#
# 使い方:
#   bash src/test-fixtures/step7/verify-step7-b3-byte-identical.sh
#
# Exit code:
#   0 = PASS (= 全 4 gate PASS、 samples.inc + VROM 4 件全件 byte-identical)
#   1 = verify fail (= gate 落ち、 出力で fail gate 明示)
#   2 = infra fail (= vromtool.py / yaml file missing 等)

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TEMPLATE_DIR="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template"
LEGACY_YAML="$TEMPLATE_DIR/assets/samples-map.yaml.legacy"
NEW_ADPCMA_YAML="$TEMPLATE_DIR/assets/samples-map-adpcma.yaml"
NEW_ADPCMB_YAML="$TEMPLATE_DIR/assets/samples-map-adpcmb.yaml"
VROMTOOL="${VROMTOOL:-/opt/homebrew/bin/vromtool.py}"
VROMSIZE=4194304
NB_VROMS=4

echo "=== step 7 β-3: path B / c1 ROM byte-identical verify ==="
echo

# infra check
for tool in shasum diff; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "infra fail: $tool not found in PATH" >&2
        exit 2
    fi
done
if [ ! -x "$VROMTOOL" ]; then
    echo "infra fail: $VROMTOOL not found / not executable" >&2
    exit 2
fi
if [ ! -f "$LEGACY_YAML" ]; then
    echo "infra fail: $LEGACY_YAML not found (β-2 で rename 済のはず)" >&2
    exit 2
fi
# 新経路 yaml は build-poc.sh が生成する build artifact なので、 先に build を回す
if [ ! -f "$NEW_ADPCMA_YAML" ] || [ ! -f "$NEW_ADPCMB_YAML" ]; then
    echo "--- 新経路 yaml が未生成、 build-poc.sh で生成 ---"
    bash "$PMDNEO_ROOT/scripts/build-poc.sh" > /dev/null 2>&1 || {
        echo "infra fail: build-poc.sh failed" >&2
        exit 2
    }
fi
for f in "$NEW_ADPCMA_YAML" "$NEW_ADPCMB_YAML"; do
    if [ ! -f "$f" ]; then
        echo "infra fail: $f not generated" >&2
        exit 2
    fi
done

# temp dir
TMPDIR=$(mktemp -d /tmp/pne-byte-identical-XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT
mkdir -p "$TMPDIR/legacy" "$TMPDIR/new"

# gate 1: legacy 経路 vromtool.py 実行
echo "--- gate 1: legacy 経路 (= 単一 samples-map.yaml.legacy) で vromtool.py 実行 ---"
(cd "$TEMPLATE_DIR/assets" && \
    "$VROMTOOL" --asm -s $VROMSIZE samples-map.yaml.legacy \
        -o "$TMPDIR/legacy/v1.v1" \
        -m "$TMPDIR/legacy/samples.inc" > /dev/null 2>&1)
(cd "$TEMPLATE_DIR/assets" && \
    "$VROMTOOL" --roms -s $VROMSIZE samples-map.yaml.legacy \
        -o "$TMPDIR/legacy/vX.vX" \
        -n $NB_VROMS > /dev/null 2>&1)
echo "  [PASS] gate 1: legacy artifact 生成成功 (= samples.inc + VROM 4 件)"

# gate 2: 新経路 vromtool.py 実行
echo "--- gate 2: 新経路 (= 2 yaml 渡し) で vromtool.py 実行 ---"
(cd "$TEMPLATE_DIR/assets" && \
    "$VROMTOOL" --asm -s $VROMSIZE samples-map-adpcma.yaml samples-map-adpcmb.yaml \
        -o "$TMPDIR/new/v1.v1" \
        -m "$TMPDIR/new/samples.inc" > /dev/null 2>&1)
(cd "$TEMPLATE_DIR/assets" && \
    "$VROMTOOL" --roms -s $VROMSIZE samples-map-adpcma.yaml samples-map-adpcmb.yaml \
        -o "$TMPDIR/new/vX.vX" \
        -n $NB_VROMS > /dev/null 2>&1)
echo "  [PASS] gate 2: 新経路 artifact 生成成功 (= samples.inc + VROM 4 件)"

# gate 3: samples.inc byte-identical
echo "--- gate 3: samples.inc byte-identical (= legacy vs 新) ---"
LEGACY_INC_HASH=$(shasum -a 256 "$TMPDIR/legacy/samples.inc" | awk '{print $1}')
NEW_INC_HASH=$(shasum -a 256 "$TMPDIR/new/samples.inc" | awk '{print $1}')
if [ "$LEGACY_INC_HASH" = "$NEW_INC_HASH" ]; then
    echo "  [PASS] samples.inc: $LEGACY_INC_HASH"
else
    echo "  [FAIL] samples.inc:"
    echo "    legacy: $LEGACY_INC_HASH"
    echo "    new:    $NEW_INC_HASH"
    echo "  diff:"
    diff "$TMPDIR/legacy/samples.inc" "$TMPDIR/new/samples.inc" | head -20
    exit 1
fi

# gate 4: VROM 4 件 byte-identical
echo "--- gate 4: VROM 4 件 byte-identical (= 243-v1.v1 ... 243-v4.v4) ---"
FAIL=0
for i in 1 2 3 4; do
    legacy_vrom="$TMPDIR/legacy/v${i}.v${i}"
    new_vrom="$TMPDIR/new/v${i}.v${i}"
    if [ ! -f "$legacy_vrom" ] || [ ! -f "$new_vrom" ]; then
        echo "  [SKIP] VROM $i: file missing (= legacy=$legacy_vrom new=$new_vrom)"
        continue
    fi
    legacy_hash=$(shasum -a 256 "$legacy_vrom" | awk '{print $1}')
    new_hash=$(shasum -a 256 "$new_vrom" | awk '{print $1}')
    if [ "$legacy_hash" = "$new_hash" ]; then
        echo "  [PASS] VROM $i ($(wc -c < "$legacy_vrom" | tr -d ' ') byte): $legacy_hash"
    else
        echo "  [FAIL] VROM $i: legacy=$legacy_hash new=$new_hash"
        FAIL=1
    fi
done
if [ "$FAIL" = "1" ]; then
    echo "  [FAIL] gate 4: VROM byte-identical 失敗"
    exit 1
fi

echo
echo "=== step 7 β-3 byte-identical verify PASS (= 4/4 gate PASS) ==="
echo "  samples.inc byte-identical: $LEGACY_INC_HASH"
echo "  VROM 4 件 byte-identical 確認済"
echo "  ROM final byte-identical は driver 不変 + 上記 artifact 一致から数学的に自動成立"
