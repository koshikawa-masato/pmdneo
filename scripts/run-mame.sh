#!/usr/bin/env bash
#
# scripts/run-mame.sh
# PMDNEO MAME 起動 (= compact 前 ad-hoc 流儀の script 化)
#
# 流れ:
#   1. 既存 mame process を kill (= 二重起動 / 古い build 起動の事故防止)
#   2. (= optional) build-poc.sh で再 build
#   3. /tmp/pmdneo-mame-rom に lastbld2.zip だけ隔離 copy
#      (= build/rom には展開 file + zip 同居でノイズ、 隔離 path で確実)
#   4. mame lastbld2 -rompath /tmp/pmdneo-mame-rom -window -sound coreaudio
#      (= macOS system audio default に流す、 user は system output を
#         Babyface / Multi-Output Device に切替済 前提)
#
# 使用例:
#   bash scripts/run-mame.sh                                  # 既存 build で 起動
#   PMDNEO_FIXTURE=1 bash scripts/run-mame.sh --build         # baseline fixture で再 build + 起動
#   PMDNEO_FIXTURE=2 bash scripts/run-mame.sh --build         # tempo fixture
#   bash scripts/run-mame.sh --build --chip ym2610b           # AES+ YM2610B mode build (= ADR-0006 §4)
#
# 環境変数:
#   PMDNEO_FIXTURE  0/1/2/3/4 (= main.c の fixture selector、 --build 必須)
#   PMDNEO_CHIP     ym2610 (default) | ym2610b (= ADR-0006 §4 chip target、 --build 必須)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

DO_BUILD=0
# default GAMEROM は build-poc.sh が生成する lastbld2.zip と一致させる
# (= --gamerom 指定漏れで puzzledp が起動 → ROM not found 事故防止)
GAMEROM="lastbld2"
ISOLATED_ROM_DIR="/tmp/pmdneo-mame-rom"
DO_TRACE=0
TRACE_DIR="/tmp/pmdneo-trace"
DO_WAVWRITE=0
WAVWRITE_SECONDS=8
DO_LOOP_VIZ=0
LOOP_VIZ_RANGE="FB00-FB10"
PMDNEO_MASK_LETTERS=""
DO_HEADLESS=0
PMDNEO_CHIP_OPT="${PMDNEO_CHIP:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build) DO_BUILD=1; shift ;;
        --gamerom) GAMEROM="$2"; shift 2 ;;
        --trace) DO_TRACE=1; shift ;;
        --wavwrite) DO_WAVWRITE=1; shift ;;
        --wavwrite-seconds) WAVWRITE_SECONDS="$2"; shift 2 ;;
        --loop-viz) DO_LOOP_VIZ=1; DO_TRACE=1; shift ;;
        --loop-viz-range) LOOP_VIZ_RANGE="$2"; DO_LOOP_VIZ=1; DO_TRACE=1; shift 2 ;;
        --mask) PMDNEO_MASK_LETTERS="$2"; shift 2 ;;
        --headless) DO_HEADLESS=1; shift ;;
        --chip) PMDNEO_CHIP_OPT="$2"; shift 2 ;;
        -h|--help) sed -n '4,26p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

# ADR-0006 §4: --chip / env PMDNEO_CHIP は build-poc.sh に env で伝搬 (= --build 時のみ意味あり)
if [[ -n "$PMDNEO_CHIP_OPT" ]]; then
    case "$PMDNEO_CHIP_OPT" in
        ym2610|ym2610b) export PMDNEO_CHIP="$PMDNEO_CHIP_OPT" ;;
        *) echo "ERROR: --chip must be ym2610 or ym2610b (got: $PMDNEO_CHIP_OPT)" >&2; exit 2 ;;
    esac
fi

if [[ -n "$PMDNEO_MASK_LETTERS" ]]; then
    # PMDNEO_MASK_LETTERS (= "BCE" 等) を bit mask に変換 (= bit 0=A, bit 1=B, ..., bit 10=K, bit 11=X, bit 12=Y, bit 13=Z)
    mask_bits=0
    for ((i=0; i<${#PMDNEO_MASK_LETTERS}; i++)); do
        c="${PMDNEO_MASK_LETTERS:$i:1}"
        case "$c" in
            [A-K]) ch=$(($(printf '%d' "'$c") - 65)); mask_bits=$((mask_bits | (1 << ch))) ;;
            X) mask_bits=$((mask_bits | (1 << 11))) ;;
            Y) mask_bits=$((mask_bits | (1 << 12))) ;;
            Z) mask_bits=$((mask_bits | (1 << 13))) ;;
        esac
    done
    export PMDNEO_EXTRA_CFLAGS="${PMDNEO_EXTRA_CFLAGS:-} -DPMDNEO_MASK_BITS=$mask_bits"
    echo "    PMDNEO_MASK: $PMDNEO_MASK_LETTERS (= bit mask 0x$(printf '%x' $mask_bits))"
fi

echo "=== Step 1/4: 既存 mame process kill ==="
pkill -9 -f "mame puzzledp" 2>/dev/null || true
pkill -9 -f "mame.*lastbld2" 2>/dev/null || true
sleep 0.3

if [[ $DO_BUILD -eq 1 ]]; then
    echo ""
    echo "=== Step 2/4: build-poc.sh ==="
    if [[ -n "${PMDNEO_FIXTURE:-}" && "$PMDNEO_FIXTURE" -gt 0 ]]; then
        export PMDNEO_EXTRA_CFLAGS="${PMDNEO_EXTRA_CFLAGS:-} -DPMDNEO_FIXTURE=$PMDNEO_FIXTURE"
        echo "    PMDNEO_FIXTURE=$PMDNEO_FIXTURE"
    fi
    if [[ -n "${PMDNEO_CHIP:-}" ]]; then
        echo "    PMDNEO_CHIP=$PMDNEO_CHIP"
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
    if [[ $DO_LOOP_VIZ -eq 1 ]]; then
        export Z80_MEM_TRACE_RANGE="$LOOP_VIZ_RANGE"
    fi
    echo "    改造 MAME 経由 trace mode:"
    echo "      binary: $MAME_BIN"
    echo "      YMFM_TRACE: $YMFM_TRACE"
    echo "      Z80_MEM_TRACE: $Z80_MEM_TRACE"
    if [[ $DO_LOOP_VIZ -eq 1 ]]; then
        echo "      Z80_MEM_TRACE_RANGE: $Z80_MEM_TRACE_RANGE (= LOOP visualization mode)"
        echo "      解析: python3 scripts/analyze-loop-trace.py $Z80_MEM_TRACE"
    fi
    echo ""
    echo "    終了後 trace file を解析: ls -la $TRACE_DIR/"
    if [[ $DO_WAVWRITE -eq 1 ]]; then
        rm -f "$TRACE_DIR/audio.wav"
        echo "      wav 録音: $TRACE_DIR/audio.wav (= ${WAVWRITE_SECONDS} 秒、 window モード維持)"
    fi
    echo ""
    if [[ $DO_HEADLESS -eq 1 ]]; then
        # headless mode (= ADR-0005 F1 前提 a 解決、 SDL_VIDEODRIVER=dummy で fullscreen 完全抑止)
        echo "    headless mode (= no window、 fullscreen フォーカス奪取なし)"
        export SDL_VIDEODRIVER=dummy
        if [[ $DO_WAVWRITE -eq 1 ]]; then
            exec "$MAME_BIN" "$GAMEROM" \
                -rompath "$ISOLATED_ROM_DIR" \
                -video none \
                -sound coreaudio \
                -samplerate 48000 \
                -nothrottle \
                -noautosave \
                -skip_gameinfo \
                -wavwrite "$TRACE_DIR/audio.wav" \
                -seconds_to_run "$WAVWRITE_SECONDS"
        else
            exec "$MAME_BIN" "$GAMEROM" \
                -rompath "$ISOLATED_ROM_DIR" \
                -video none \
                -sound coreaudio \
                -samplerate 48000 \
                -nothrottle \
                -noautosave \
                -skip_gameinfo \
                -seconds_to_run 30
        fi
    elif [[ $DO_WAVWRITE -eq 1 ]]; then
        exec "$MAME_BIN" "$GAMEROM" \
            -rompath "$ISOLATED_ROM_DIR" \
            -window \
            -nomaximize \
            -resolution 960x672 \
            -noautosave \
            -skip_gameinfo \
            -sound coreaudio \
            -wavwrite "$TRACE_DIR/audio.wav" \
            -seconds_to_run "$WAVWRITE_SECONDS"
    else
        exec "$MAME_BIN" "$GAMEROM" \
            -rompath "$ISOLATED_ROM_DIR" \
            -window \
            -nomaximize \
            -resolution 960x672 \
            -noautosave \
            -skip_gameinfo \
            -sound coreaudio
    fi
fi

if [[ $DO_HEADLESS -eq 1 ]]; then
    echo "    mame $GAMEROM headless mode (= SDL_VIDEODRIVER=dummy + -video none)"
    echo ""
    export SDL_VIDEODRIVER=dummy
    if [[ $DO_WAVWRITE -eq 1 ]]; then
        rm -f "$TRACE_DIR/audio.wav"
        mkdir -p "$TRACE_DIR"
        exec mame "$GAMEROM" \
            -rompath "$ISOLATED_ROM_DIR" \
            -video none \
            -sound coreaudio \
            -samplerate 48000 \
            -nothrottle \
            -noautosave \
            -skip_gameinfo \
            -wavwrite "$TRACE_DIR/audio.wav" \
            -seconds_to_run "$WAVWRITE_SECONDS"
    else
        exec mame "$GAMEROM" \
            -rompath "$ISOLATED_ROM_DIR" \
            -video none \
            -sound coreaudio \
            -samplerate 48000 \
            -nothrottle \
            -noautosave \
            -skip_gameinfo \
            -seconds_to_run 30
    fi
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
