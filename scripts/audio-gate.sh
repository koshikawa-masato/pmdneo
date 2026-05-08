#!/usr/bin/env bash
#
# scripts/audio-gate.sh
# PMDNEO 自動 audio gate (= gngeo + BlackHole loopback + ffmpeg + numpy 解析)
#
# 設計原則 (= user 確言):
#   - audio gate emulator == 聴感確認 emulator (= gngeo lastbld2)、 同条件再現可能
#   - macOS audio loopback (BlackHole) で system audio を ffmpeg で wav 化
#   - gngeo は必ず window モード (= フルスクリーン禁則事項)
#
# 流れ:
#   1. (= optional) PMDNEO_FIXTURE 経由で再 build (= main.c 経由で fixture 切替)
#   2. BlackHole device 検出、 未 install なら案内 + exit 2
#   3. ffmpeg で BlackHole 入力を wav 化 (= background)
#   4. gngeo 起動 (= window モード background)
#   5. ffmpeg 録音終了待ち (= -t で実時間制御)
#   6. gngeo を必ず kill (= trap)
#   7. analyze-audio.py で assertion 評価
#
# 由来:
#   - neo-sisters/scripts/audio-runtime-verify.sh (= analyze ロジックの参考)
#   - neo-sisters/scripts/analyze-audio.py を pmdneo 用に拡張済 (= scripts/analyze-audio.py)
#
# Exit code:
#   0 = pass (= silent でない + 全 assertion 合格)
#   1 = audio assertion fail
#   2 = infra fail (= build / BlackHole 未 install / ffmpeg / python)

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# default values
DURATION=12
SKIP_SECONDS=0
OUTPUT_WAV="/tmp/pmdneo-audio-gate.wav"
SKIP_BUILD=0
EMIT_JSON=0
FIXTURE=""              # default | baseline | tempo | loop | fade
BASELINE_JSON=""

# assertion args (Python に passthrough)
PYTHON_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --duration|--seconds)  DURATION="$2"; shift 2 ;;
        --skip-seconds)        SKIP_SECONDS="$2"; PYTHON_ARGS+=("--skip-seconds" "$2"); shift 2 ;;
        --output)              OUTPUT_WAV="$2"; shift 2 ;;
        --skip-build)          SKIP_BUILD=1; shift ;;
        --json)                EMIT_JSON=1; shift ;;
        --fixture)             FIXTURE="$2"; shift 2 ;;
        --baseline)            BASELINE_JSON="$2"; PYTHON_ARGS+=("--baseline" "$2"); shift 2 ;;
        --assert-rms-min)      PYTHON_ARGS+=("--assert-rms-min" "$2"); shift 2 ;;
        --assert-peak-hz)      PYTHON_ARGS+=("--assert-peak-hz" "$2"); shift 2 ;;
        --tol-hz)              PYTHON_ARGS+=("--tol-hz" "$2"); shift 2 ;;
        --assert-bpm)          PYTHON_ARGS+=("--assert-bpm" "$2"); shift 2 ;;
        --tol-bpm)             PYTHON_ARGS+=("--tol-bpm" "$2"); shift 2 ;;
        --assert-onset-count)  PYTHON_ARGS+=("--assert-onset-count" "$2"); shift 2 ;;
        --assert-rms-window-min)
            PYTHON_ARGS+=("--assert-rms-window-min" "$2" "$3" "$4"); shift 4 ;;
        --assert-rms-window-max)
            PYTHON_ARGS+=("--assert-rms-window-max" "$2" "$3" "$4"); shift 4 ;;
        -h|--help)
            sed -n '4,30p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

log() {
    if [[ $EMIT_JSON -eq 0 ]]; then
        echo "$@" >&2
    fi
    return 0
}

# fixture 名 → PMDNEO_FIXTURE 番号
FIXTURE_NUM=0
case "$FIXTURE" in
    "")           FIXTURE_NUM=0 ;;
    default)      FIXTURE_NUM=0 ;;
    baseline)     FIXTURE_NUM=1 ;;
    tempo)        FIXTURE_NUM=2 ;;
    loop)         FIXTURE_NUM=3 ;;
    fade)         FIXTURE_NUM=4 ;;
    *)
        echo "Unknown fixture: $FIXTURE (default | baseline | tempo | loop | fade)" >&2
        exit 2
        ;;
esac

# === Step 0: BlackHole 検出 (= sox coreaudio backend で list) ===
BLACKHOLE_DEVICE_NAME="BlackHole 2ch"
HAS_BLACKHOLE=0
if [[ -e "/Library/Audio/Plug-Ins/HAL/BlackHole2ch.driver" ]]; then
    HAS_BLACKHOLE=1
fi

if [[ $HAS_BLACKHOLE -eq 0 ]]; then
    cat >&2 <<'EOS'

✗ BlackHole 2ch loopback driver が未 install または検出不能。

PMDNEO の audio gate (= 聴感と同 ROM template / 同 emulator で録音) には
macOS audio loopback driver が必要。 one-time setup:

  1. brew install --cask blackhole-2ch
  2. macOS の Audio MIDI Setup (= /Applications/Utilities/) を起動
  3. 「+」 → 「Create Multi-Output Device」 で BlackHole 2ch + Built-in Output
     を含む aggregate device を作成、 Master Device を Built-in に設定
  4. 上記 Multi-Output Device を system audio output に設定
  5. これで gngeo audio が BlackHole + speakers の両方に流れる
     (= user 耳でも聴こえつつ ffmpeg が BlackHole から録音)

詳細: docs/design/handoff/audio-gate-usage.md

EOS
    exit 2
fi
log "    BlackHole device: $BLACKHOLE_DEVICE_NAME"

# === Step 1: build (= optional fixture select) ===
log "=== Step 1/4: build ==="
if [[ $SKIP_BUILD -eq 0 ]]; then
    if [[ -n "$FIXTURE" && "$FIXTURE_NUM" -gt 0 ]]; then
        # main.c rebuild を強制するため build/main.o 削除
        rm -f "$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/main.o" 2>/dev/null || true
        export CFLAGS="${CFLAGS:-} -DPMDNEO_FIXTURE=$FIXTURE_NUM"
        log "    PMDNEO_FIXTURE=$FIXTURE_NUM (= $FIXTURE)"
    fi
    if ! bash "$PROJECT_ROOT/scripts/build-poc.sh" >/tmp/pmdneo-audio-gate-build.log 2>&1; then
        echo "✗ build failed (= /tmp/pmdneo-audio-gate-build.log 参照)" >&2
        tail -10 /tmp/pmdneo-audio-gate-build.log >&2
        exit 2
    fi
    log "    build OK"
else
    log "    skipped (= --skip-build)"
fi

BUILD_ROM_DIR="$PROJECT_ROOT/vendor/ngdevkit-examples/00-template/build/rom"
if [[ ! -f "$BUILD_ROM_DIR/lastbld2.zip" ]]; then
    echo "✗ $BUILD_ROM_DIR/lastbld2.zip not found (= build 失敗?)" >&2
    exit 2
fi

# === Step 2: ffmpeg + gngeo 並行起動 + 録音 ===
log ""
log "=== Step 2/4: gngeo + ffmpeg 録音 ${DURATION} 秒 ==="
log "    Output: $OUTPUT_WAV"

# 既存 gngeo / ffmpeg を kill
pkill -f "ngdevkit-gngeo" 2>/dev/null || true
pkill -f "make gngeo" 2>/dev/null || true
sleep 0.3

# trap で確実に cleanup
GNGEO_PID=""
FFMPEG_PID=""
cleanup() {
    [[ -n "$FFMPEG_PID" ]] && kill -TERM "$FFMPEG_PID" 2>/dev/null || true
    [[ -n "$GNGEO_PID" ]] && kill -TERM "$GNGEO_PID" 2>/dev/null || true
    pkill -f "ngdevkit-gngeo" 2>/dev/null || true
    pkill -f "make gngeo" 2>/dev/null || true
}
trap cleanup EXIT

# sox coreaudio で BlackHole 録音 (= background、 ffmpeg より stable)
rm -f "$OUTPUT_WAV"
sox -t coreaudio "$BLACKHOLE_DEVICE_NAME" -c 2 -r 48000 -b 16 \
    "$OUTPUT_WAV" trim 0 "$DURATION" \
    > /tmp/pmdneo-audio-gate-sox.log 2>&1 &
FFMPEG_PID=$!   # 変数名は legacy、 内容は sox PID
sleep 0.5   # sox 起動 settle

# gngeo 起動 (= window モード、 background)
(cd "$PROJECT_ROOT/vendor/ngdevkit-examples/00-template" && make gngeo) \
    > /tmp/pmdneo-audio-gate-gngeo.log 2>&1 &
GNGEO_PID=$!

# ffmpeg の録音終了待ち
wait "$FFMPEG_PID"
FFMPEG_EXIT=$?

# gngeo を必ず kill
cleanup

if [[ $FFMPEG_EXIT -ne 0 ]]; then
    echo "✗ sox 録音失敗 (= /tmp/pmdneo-audio-gate-sox.log 参照)" >&2
    tail -10 /tmp/pmdneo-audio-gate-sox.log >&2
    exit 2
fi

if [[ ! -f "$OUTPUT_WAV" ]]; then
    echo "✗ WAV 未生成: $OUTPUT_WAV" >&2
    exit 2
fi

WAV_SIZE=$(stat -f "%z" "$OUTPUT_WAV" 2>/dev/null || stat -c "%s" "$OUTPUT_WAV")
log "    WAV: $OUTPUT_WAV ($WAV_SIZE bytes)"

# === Step 3: python 解析 ===
log ""
log "=== Step 3/4: python 解析 ==="

# numpy + scipy 持ち python detection
PYTHON_BIN=""
for py in \
    "$HOME/.pyenv/versions/3.11.9/bin/python3" \
    "/opt/homebrew/opt/python@3.14/bin/python3" \
    "/opt/homebrew/opt/python@3.13/bin/python3" \
    "/opt/homebrew/opt/python@3.12/bin/python3" \
    "/opt/homebrew/opt/python@3.11/bin/python3" \
    "/opt/homebrew/bin/python3" \
    "python3"; do
    if command -v "$py" >/dev/null 2>&1 || [[ -x "$py" ]]; then
        if "$py" -c "import numpy, scipy" 2>/dev/null; then
            PYTHON_BIN="$py"
            break
        fi
    fi
done

if [[ -z "$PYTHON_BIN" ]]; then
    echo "✗ numpy + scipy 利用可能な python が見つかりません" >&2
    echo "  pip3 install numpy scipy で解決" >&2
    exit 2
fi

PYTHON_ARGS_FULL=("--input" "$OUTPUT_WAV")
if [[ ${#PYTHON_ARGS[@]} -gt 0 ]]; then
    PYTHON_ARGS_FULL+=("${PYTHON_ARGS[@]}")
fi
if [[ $EMIT_JSON -eq 1 ]]; then
    PYTHON_ARGS_FULL+=("--json")
fi

set +e
"$PYTHON_BIN" "$PROJECT_ROOT/scripts/analyze-audio.py" "${PYTHON_ARGS_FULL[@]}"
EXIT_CODE=$?
set -e

# === Step 4: verdict ===
log ""
log "=== Step 4/4: verdict ==="
case $EXIT_CODE in
    0) log "    ✓ PASS (= silent でない + 全 assertion 合格)" ;;
    1) log "    ✗ FAIL (= audio assertion fail)" ;;
    *) log "    ✗ INFRA FAIL (= python error)"; EXIT_CODE=2 ;;
esac

exit $EXIT_CODE
