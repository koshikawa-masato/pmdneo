#!/usr/bin/env bash
#
# scripts/run-mame.sh
# PMDNEO MAME 起動 (= compact 前 ad-hoc 流儀の script 化)
#
# 流れ:
#   1. 既存 mame process を kill (= 二重起動 / 古い build 起動の事故防止)
#   2. (= optional) build-poc.sh で再 build
#   3. /tmp/pmdneo-mame-rom に puzzledp.zip だけ隔離 copy
#      (= build/rom には展開 file + zip 同居でノイズ、 隔離 path で確実)
#   4. mame puzzledp -rompath /tmp/pmdneo-mame-rom -window -sound coreaudio
#      (= macOS system audio default に流す、 user は system output を
#         Babyface / Multi-Output Device に切替済 前提)
#
# 使用例:
#   bash scripts/run-mame.sh                                  # 既存 build で 起動
#   PMDNEO_FIXTURE=1 bash scripts/run-mame.sh --build         # baseline fixture で再 build + 起動
#   PMDNEO_FIXTURE=2 bash scripts/run-mame.sh --build         # tempo fixture
#
# 環境変数:
#   PMDNEO_FIXTURE  0/1/2/3/4 (= main.c の fixture selector、 --build 必須)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

DO_BUILD=0
GAMEROM="puzzledp"
ISOLATED_ROM_DIR="/tmp/pmdneo-mame-rom"
DO_TRACE=0
TRACE_DIR="/tmp/pmdneo-trace"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build) DO_BUILD=1; shift ;;
        --gamerom) GAMEROM="$2"; shift 2 ;;
        --trace) DO_TRACE=1; shift ;;
        -h|--help) sed -n '4,25p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

echo "=== Step 1/4: 既存 mame process kill ==="
pkill -9 -f "mame puzzledp" 2>/dev/null || true
pkill -9 -f "mame.*lastbld2" 2>/dev/null || true
sleep 0.3

if [[ $DO_BUILD -eq 1 ]]; then
    echo ""
    echo "=== Step 2/4: build-poc.sh ==="
    if [[ -n "${PMDNEO_FIXTURE:-}" && "$PMDNEO_FIXTURE" -gt 0 ]]; then
        export PMDNEO_EXTRA_CFLAGS="-DPMDNEO_FIXTURE=$PMDNEO_FIXTURE"
        echo "    PMDNEO_FIXTURE=$PMDNEO_FIXTURE"
    fi
    # main.c rebuild 強制 (= CFLAGS 変化を make が見ないため)
    touch vendor/ngdevkit-examples/00-template/main.c
    rm -f vendor/ngdevkit-examples/00-template/build/main.o \
          vendor/ngdevkit-examples/00-template/build/p1.p1
    bash scripts/build-poc.sh 2>&1 | tail -5
fi

ROM_ZIP="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/${GAMEROM}.zip"
if [[ ! -f "$ROM_ZIP" ]]; then
    echo "✗ ROM not found: $ROM_ZIP" >&2
    exit 2
fi

NEOGEO_ZIP="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/neogeo.zip"
if [[ ! -f "$NEOGEO_ZIP" ]]; then
    echo "✗ neogeo.zip not found: $NEOGEO_ZIP" >&2
    exit 2
fi

echo ""
echo "=== Step 3/4: /tmp/pmdneo-mame-rom に zip 隔離 copy + MD5 check ==="

# raw M1 と zip 内 M1 の一致確認 (= make poc 後 zip 再 packing 忘れ防止)
RAW_M1="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1"
RAW_M1_PUZZLEDP="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom/202-m1.m1"
M1_FILE_IN_ZIP=""
RAW_M1_PATH=""
if [[ "$GAMEROM" == "lastbld2" && -f "$RAW_M1" ]]; then
    RAW_M1_PATH="$RAW_M1"
    M1_FILE_IN_ZIP="243-m1.m1"
elif [[ "$GAMEROM" == "puzzledp" && -f "$RAW_M1_PUZZLEDP" ]]; then
    RAW_M1_PATH="$RAW_M1_PUZZLEDP"
    M1_FILE_IN_ZIP="202-m1.m1"
fi

if [[ -n "$RAW_M1_PATH" ]]; then
    RAW_M1_MD5=$(md5 -q "$RAW_M1_PATH")
    ZIP_M1_MD5=$(unzip -p "$ROM_ZIP" "$M1_FILE_IN_ZIP" 2>/dev/null | md5 -q)
    if [[ "$RAW_M1_MD5" != "$ZIP_M1_MD5" ]]; then
        echo "    ⚠ raw M1 ↔ zip 内 M1 が MD5 不一致" >&2
        echo "      raw $M1_FILE_IN_ZIP MD5: $RAW_M1_MD5" >&2
        echo "      zip $M1_FILE_IN_ZIP MD5: $ZIP_M1_MD5" >&2
        echo "    → zip を再 packing します (= make poc 後の更新忘れ自動 fix)" >&2
        (cd "$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom" && zip -j "${GAMEROM}.zip" "$M1_FILE_IN_ZIP") >/dev/null
        ZIP_M1_MD5_AFTER=$(unzip -p "$ROM_ZIP" "$M1_FILE_IN_ZIP" 2>/dev/null | md5 -q)
        echo "    再 packing 後 zip M1 MD5: $ZIP_M1_MD5_AFTER" >&2
        if [[ "$RAW_M1_MD5" != "$ZIP_M1_MD5_AFTER" ]]; then
            echo "    ✗ 再 packing しても不一致、 abort" >&2
            exit 2
        fi
    fi
    echo "    raw $M1_FILE_IN_ZIP MD5: $RAW_M1_MD5"
    echo "    zip $M1_FILE_IN_ZIP MD5 (一致確認済): $ZIP_M1_MD5"
fi

# 隔離 path への copy
rm -rf "$ISOLATED_ROM_DIR"
mkdir -p "$ISOLATED_ROM_DIR"
cp "$ROM_ZIP" "$ISOLATED_ROM_DIR/"
cp "$NEOGEO_ZIP" "$ISOLATED_ROM_DIR/"

# copy 後 MD5 一致確認 (= 隔離 path に古い zip が残ることを防ぐ)
SRC_ZIP_MD5=$(md5 -q "$ROM_ZIP")
ISO_ZIP_MD5=$(md5 -q "$ISOLATED_ROM_DIR/${GAMEROM}.zip")
if [[ "$SRC_ZIP_MD5" != "$ISO_ZIP_MD5" ]]; then
    echo "    ✗ 隔離 copy 後 MD5 不一致 (= cp 失敗)" >&2
    exit 2
fi
echo "    ${GAMEROM}.zip MD5: $SRC_ZIP_MD5 (= isolated copy 一致確認済)"
echo "    ${GAMEROM}.zip + neogeo.zip → $ISOLATED_ROM_DIR/"

echo ""
echo "=== Step 4/4: MAME 起動 (window mode、 coreaudio) ==="

if [[ $DO_TRACE -eq 1 ]]; then
    MAME_BIN="$PROJECT_ROOT/vendor/mame-fork/neogeo"
    if [[ ! -x "$MAME_BIN" ]]; then
        echo "✗ 改造 MAME binary not found: $MAME_BIN" >&2
        exit 2
    fi
    rm -rf "$TRACE_DIR"
    mkdir -p "$TRACE_DIR"
    export YMFM_TRACE="$TRACE_DIR/ymfm-trace.tsv"
    export Z80_MEM_TRACE="$TRACE_DIR/z80-mem-trace.tsv"
    echo "    改造 MAME 経由 trace mode:"
    echo "      binary: $MAME_BIN"
    echo "      YMFM_TRACE: $YMFM_TRACE"
    echo "      Z80_MEM_TRACE: $Z80_MEM_TRACE"
    echo ""
    echo "    終了後 trace file を解析: ls -la $TRACE_DIR/"
    echo ""
    exec "$MAME_BIN" "$GAMEROM" \
        -rompath "$ISOLATED_ROM_DIR" \
        -window \
        -nomaximize \
        -resolution 960x672 \
        -noautosave \
        -skip_gameinfo \
        -sound coreaudio
fi

echo "    mame $GAMEROM -rompath $ISOLATED_ROM_DIR -window -skip_gameinfo -sound coreaudio"
echo ""

exec mame "$GAMEROM" \
    -rompath "$ISOLATED_ROM_DIR" \
    -window \
    -nomaximize \
    -resolution 960x672 \
    -noautosave \
    -skip_gameinfo \
    -sound coreaudio
