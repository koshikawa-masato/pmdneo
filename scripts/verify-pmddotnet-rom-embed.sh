#!/usr/bin/env bash
#
# scripts/verify-pmddotnet-rom-embed.sh
# ADR-0016 step 3b-2 永続検証 — 改造 PMDDotNET .M が ROM 内に embed されていることを
# byte-identical で確認 + 既存 baseline との regression 監視。
#
# 目的:
#   driver sprint (= 3c) 着手前に「ROM には正しい .M が入っている」 と機械的に保証。
#   3c で音が出ない時の原因候補を driver 側に絞り込める state を establish。
#
# 4 layer verify:
#   layer A: pmddotnet_song.m 生成 + sha256 計算 + size 確認
#   layer B: 243-m1.m1 (= ROM 内 M ROM = Z80 binary) 存在 / size 確認
#   layer C: .M payload byte 列が ROM 内に完全一致で見つかるか + offset 報告
#   layer D: 入力 MML が build/step1-baseline-N/ 配下なら step 1 baseline sha256 と一致確認
#            (= /N compile の継続的 byte-identical regression 監視)
#
# 流れ:
#   1. build-poc.sh を PMDDOTNET_MML 指定で実行 (= 再 build、 .M + ROM 生成)
#   2. layer A-D を順次実行
#   3. 失敗時に entry name / .M hash / ROM 内検出可否 / size を log + exit 1
#
# 使い方:
#   bash scripts/verify-pmddotnet-rom-embed.sh                              # default = voice-ar-04.mml
#   bash scripts/verify-pmddotnet-rom-embed.sh --mml path/to/file.mml       # MML 指定
#   bash scripts/verify-pmddotnet-rom-embed.sh --mode B                     # /B mode (= ADPCM-A 経路、 step 5 用)
#
# 終了 status:
#   0 = 全 PASS
#   1 = 失敗 (= layer A-D のどれかが不一致)
#   2 = 環境 error (= build dll 不在、 MML 不在、 build 失敗、 ROM 未生成 等)

set -uo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD_DIR="$REPO_ROOT/vendor/ngdevkit-examples/00-template"
readonly ROM_M1="$BUILD_DIR/build/rom/243-m1.m1"
readonly PMDDOTNET_OUT="$BUILD_DIR/pmddotnet_song.m"
readonly BASELINE_SHA="$REPO_ROOT/build/step1-baseline-N/BASELINE-N.sha256"
readonly LOG_FILE="$REPO_ROOT/build/step3b2-rom-embed-verify.log"

# default = step 1 baseline と整合確認できる voice-ar-04.mml (= /N でも /B でも .M 出力)
readonly DEFAULT_MML="$REPO_ROOT/build/step1-baseline-N/voice-ar-04.mml"
MML_PATH="$DEFAULT_MML"
MODE="N"

readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_RESET='\033[0m'

log_info() { echo -e "${C_GREEN}[INFO]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "${C_RED}[FAIL]${C_RESET}  $*" | tee -a "$LOG_FILE"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mml) MML_PATH="$2"; shift 2 ;;
        --mode) MODE="$2"; shift 2 ;;
        -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

# log file init
mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE"

echo "=========================================="
echo "ADR-0016 step 3b-2 verify — PMDDotNET .M ROM embed 整合"
echo "=========================================="

# 環境 check
if [[ ! -f "$MML_PATH" ]]; then
    log_err "MML file が見つからない: $MML_PATH"
    exit 2
fi
log_info "MML: $(basename "$MML_PATH") (= $MML_PATH)"
log_info "mode: /$MODE"

# build 実行 (= 再 build、 ROM + .M 再生成)
log_info "build-poc.sh を PMDDOTNET_MML 指定で実行..."
if ! PMDDOTNET_MML="$MML_PATH" PMDDOTNET_MODE="$MODE" bash "$REPO_ROOT/scripts/build-poc.sh" > "$LOG_FILE.build" 2>&1; then
    log_err "build-poc.sh が失敗"
    log_err "  log: $LOG_FILE.build"
    log_err "  末尾 20 行:"
    tail -20 "$LOG_FILE.build" | sed 's/^/    /' | tee -a "$LOG_FILE"
    exit 2
fi
log_info "build 完了"

# layer A: pmddotnet_song.m 存在 + sha256 + size
log_info "layer A check: pmddotnet_song.m (= PMDDotNET 出力 .M / .MN)"
if [[ ! -f "$PMDDOTNET_OUT" ]]; then
    log_err "layer A FAIL — pmddotnet_song.m が見つからない: $PMDDOTNET_OUT"
    exit 1
fi
M_SHA=$(shasum -a 256 "$PMDDOTNET_OUT" | awk '{print $1}')
M_SIZE=$(wc -c < "$PMDDOTNET_OUT" | tr -d ' ')
M_START_HEX=$(xxd -l 1 -p "$PMDDOTNET_OUT")
log_info "  size: $M_SIZE byte"
log_info "  sha256: $M_SHA"
log_info "  m_start: 0x$M_START_HEX (= $(if [[ "$M_START_HEX" == "00" ]]; then echo ".M 互換 mode"; elif [[ "$M_START_HEX" == "04" ]]; then echo ".MN PMDNEO mode"; else echo "unknown"; fi))"
log_info "layer A PASS"

# layer B: ROM M1 binary 存在 + size
log_info "layer B check: 243-m1.m1 (= ROM 内 M ROM = Z80 binary)"
if [[ ! -f "$ROM_M1" ]]; then
    log_err "layer B FAIL — 243-m1.m1 が見つからない: $ROM_M1"
    exit 1
fi
ROM_SIZE=$(wc -c < "$ROM_M1" | tr -d ' ')
ROM_SHA=$(shasum -a 256 "$ROM_M1" | awk '{print $1}')
log_info "  size: $ROM_SIZE byte"
log_info "  sha256: $ROM_SHA"
log_info "layer B PASS"

# layer C: .M payload が ROM 内に完全一致で埋め込まれているか
log_info "layer C check: .M payload byte 列が ROM 内に完全一致で embed されているか"
EMBED_OFFSET=$(python3 -c "
import sys
m = open('$PMDDOTNET_OUT', 'rb').read()
rom = open('$ROM_M1', 'rb').read()
idx = rom.find(m)
if idx < 0:
    sys.exit(1)
print(f'0x{idx:04x}')
" 2>/dev/null)
if [[ -z "$EMBED_OFFSET" ]]; then
    log_err "layer C FAIL — .M payload が ROM 内に見つからない"
    log_err "  対象 .M: $PMDDOTNET_OUT ($M_SIZE byte、 sha256 $M_SHA)"
    log_err "  対象 ROM: $ROM_M1 ($ROM_SIZE byte)"
    log_err "  → build chain で .incbin 取り込み経路が壊れている可能性"
    exit 1
fi
log_info "  embed offset: $EMBED_OFFSET"
log_info "layer C PASS — .M 全 $M_SIZE byte が ROM 内 offset $EMBED_OFFSET に完全一致 embed"

# layer D: 入力 MML が step 1 baseline 配下なら sha256 regression 確認 (= optional)
log_info "layer D check: step 1 baseline (= BASELINE-N.sha256) との regression"
MML_BASENAME=$(basename "$MML_PATH" .mml)
EXPECTED_M_NAME="${MML_BASENAME}.M"
if [[ -f "$BASELINE_SHA" ]] && grep -q " $EXPECTED_M_NAME$" "$BASELINE_SHA"; then
    EXPECTED_SHA=$(grep " $EXPECTED_M_NAME$" "$BASELINE_SHA" | awk '{print $1}')
    if [[ "$MODE" == "N" ]]; then
        if [[ "$M_SHA" == "$EXPECTED_SHA" ]]; then
            log_info "layer D PASS — /N 出力 .M が step 1 baseline と sha256 完全一致 ($M_SHA)"
        else
            log_err "layer D FAIL — /N 出力 .M が step 1 baseline と不一致"
            log_err "  expected: $EXPECTED_SHA"
            log_err "  actual:   $M_SHA"
            log_err "  対象 file: $EXPECTED_M_NAME"
            exit 1
        fi
    else
        # /B mode: step 1 baseline は /N で取得、 比較は適切でない (= step 5 で別 baseline)
        log_info "layer D SKIP — /B mode は step 1 baseline と比較対象外 (= step 5 で別 verify)"
    fi
else
    log_warn "layer D SKIP — 入力 MML が step 1 baseline 配下に無い、 or BASELINE-N.sha256 が見つからない"
    log_warn "  (= 任意 MML での verify として扱う、 regression chk 対象外)"
fi

echo
log_info "===== step 3b-2 verify TOTAL PASS ====="
log_info "log: $LOG_FILE"
exit 0
