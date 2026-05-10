#!/bin/bash
#
# PMDNEO Phase 1 PoC ビルド script
#
# 動作:
#   1. src/driver/ の Z80 source (.s / .inc) を vendor/ngdevkit-examples/00-template/ に symlink
#   2. cd vendor/ngdevkit-examples/00-template && make
#
# 前提:
#   - ngdevkit + ngdevkit-gngeo が install 済 (brew install ngdevkit ngdevkit-gngeo)
#   - vendor/ngdevkit-examples で `./configure` 実行済 (= config.mk + build.mk + emu.mk 生成済)
#   - ~/Downloads/neogeo.zip (NEOGEO 純正 BIOS romset) が用意済 (起動確認時)
#
# 使用例:
#   bash scripts/build-poc.sh           # build のみ
#   bash scripts/build-poc.sh && cd vendor/ngdevkit-examples/00-template && make gngeo  # build + 起動

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER_SRC="$PMDNEO_ROOT/src/driver"
TEMPLATE_DIR="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template"

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "ERROR: $TEMPLATE_DIR が見つかりません。 vendor/ngdevkit-examples を取り込み済か確認してください。"
    exit 1
fi

if [ ! -f "$TEMPLATE_DIR/build.mk" ]; then
    echo "ERROR: $TEMPLATE_DIR/build.mk がありません。"
    echo "vendor/ngdevkit-examples で autoreconf + ./configure を実行してください:"
    echo "  cd $PMDNEO_ROOT/vendor/ngdevkit-examples && autoreconf -i && ./configure"
    exit 1
fi

# 00-template には configure で config.mk が rsync されない (= 00-template は rsync source)
# 親の vendor/ngdevkit-examples/config.mk を symlink で参照
if [ ! -f "$PMDNEO_ROOT/vendor/ngdevkit-examples/config.mk" ]; then
    echo "ERROR: $PMDNEO_ROOT/vendor/ngdevkit-examples/config.mk がありません。"
    echo "./configure を実行してください。"
    exit 1
fi

echo "=== config.mk を 00-template/ に symlink ==="
ln -sfn "../config.mk" "$TEMPLATE_DIR/config.mk"

echo "=== src/driver/ の Z80 source を 00-template/ に symlink ==="
cd "$TEMPLATE_DIR"
for f in "$DRIVER_SRC"/*.s "$DRIVER_SRC"/*.inc; do
    base=$(basename "$f")
    if [ "$base" = "standalone_test.s" ]; then
        echo "  $base (kept local for generated song_data.inc include)"
        continue
    fi
    ln -sfn "../../../src/driver/$base" "$base"
    echo "  $base -> ../../../src/driver/$base"
done

echo "=== SAMPLE.M を sdasz80 用 .db source に変換 ==="
python3 "$PMDNEO_ROOT/scripts/bin2db.py" \
    "$PMDNEO_ROOT/vendor/pmd48s/SAMPLE.M" \
    "$TEMPLATE_DIR/sample_m.s" \
    "sample_m_data"
echo "  sample_m.s <- vendor/pmd48s/SAMPLE.M"

echo "=== compile.py: MML → song_data.inc ==="
# MML_INPUT 環境変数で fixture 切替 (= default test01.mml = chord-mode、
# test02.mml = drum-mode 14 part 等)
MML_INPUT="${MML_INPUT:-test01.mml}"
echo "    MML_INPUT: ${MML_INPUT}"
python3 "${PMDNEO_ROOT}/src/tools/pmd-mml/compile.py" \
    "${PMDNEO_ROOT}/src/tools/pmd-mml/${MML_INPUT}" \
    -o "${TEMPLATE_DIR}/song_data.inc"

echo
echo "=== make poc ==="
make STANDALONE_Z80_SRC=standalone_test.s -W standalone_test.s poc

echo
echo "=== build 完了 ==="
echo "起動確認:"
echo "  cd $TEMPLATE_DIR && make gngeo"
