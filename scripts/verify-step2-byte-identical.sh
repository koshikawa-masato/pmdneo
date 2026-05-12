#!/usr/bin/env bash
#
# scripts/verify-step2-byte-identical.sh
# ADR-0016 step 2 永続検証 — /N と /B (ADPCM-A 未使用) の byte-identical 一致
#
# 目的:
#   ADR-0013 D1 路線基盤 (= 同 .M を /N と /B 両方で compile して完全一致を保証)
#   を 28 entry voice-test MML について自動 verify する script。
#   step 1 で確立した「ADPCM-A 未使用なら /N と /B は byte-identical」 を継続的に検証。
#
# 流れ:
#   1. build/step1-baseline-N/ から 28 entry MML を作業 dir に copy
#   2. /N で compile → BASELINE-N.sha256 と完全一致 (= regression check)
#   3. /B で compile → /N output と 1:1 cmp (= byte-identical check)
#   4. /B 出力に .MN 0 件確認 (= adpcma_used = false 経路、 .M 維持)
#
# 出力先: build/step2-byte-identical/ (= /N と /B の作業 dir + verify log)
#
# 終了 status:
#   0 = 全 PASS
#   1 = 失敗 entry あり (= log で entry name + 差分対象 表示)
#   2 = 環境 error (= compiler dll 未 build、 baseline 不在 等)

set -uo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BASELINE_DIR="$REPO_ROOT/build/step1-baseline-N"
readonly COMPILER_DLL="$REPO_ROOT/vendor/PMDDotNET/PMDDotNETConsole/bin/Release/net6.0/PMDDotNETConsole.dll"
readonly WORK_DIR="$REPO_ROOT/build/step2-byte-identical"
readonly WORK_N="$WORK_DIR/N"
readonly WORK_B="$WORK_DIR/B"
readonly LOG_FILE="$WORK_DIR/verify-result.log"

# ANSI color (= 端末出力強化)
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_RESET='\033[0m'

log_info() { echo -e "${C_GREEN}[INFO]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
log_warn() { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" | tee -a "$LOG_FILE"; }
log_err()  { echo -e "${C_RED}[FAIL]${C_RESET}  $*" | tee -a "$LOG_FILE"; }

# 環境 check
check_env() {
    if [[ ! -f "$COMPILER_DLL" ]]; then
        log_err "compiler dll が見つからない: $COMPILER_DLL"
        log_err "vendor/PMDDotNET/PMDDotNETConsole を dotnet build -c Release してください"
        exit 2
    fi
    if [[ ! -d "$BASELINE_DIR" ]]; then
        log_err "baseline dir が見つからない: $BASELINE_DIR"
        exit 2
    fi
    if [[ ! -f "$BASELINE_DIR/BASELINE-N.sha256" ]]; then
        log_err "baseline sha256 が見つからない: $BASELINE_DIR/BASELINE-N.sha256"
        exit 2
    fi
    local mml_count
    mml_count=$(find "$BASELINE_DIR" -maxdepth 1 -name '*.mml' | wc -l | tr -d ' ')
    if [[ "$mml_count" -eq 0 ]]; then
        log_err "baseline dir に MML が無い: $BASELINE_DIR/*.mml"
        exit 2
    fi
    log_info "環境 check OK (MML $mml_count entry)"
}

# 作業 dir 準備 (= 既存があれば clean、 log file は保持)
prepare_workdir() {
    rm -rf "$WORK_N" "$WORK_B" "$WORK_DIR"/N.sha256
    mkdir -p "$WORK_N" "$WORK_B"
    cp "$BASELINE_DIR"/*.mml "$WORK_N/"
    cp "$BASELINE_DIR"/*.mml "$WORK_B/"
}

# 共通 compile helper (= /N or /B、 失敗時 entry 名 + stderr log path 出力 + exit 2)
# PASS path では成功時に stderr log を削除して output を従来通り維持
compile_one() {
    local mode=$1       # "N" or "B"
    local workdir=$2    # 作業 dir 絶対 path
    log_info "/$mode compile 開始 (= $workdir)"
    pushd "$workdir" > /dev/null
    local count=0
    for f in *.mml; do
        local err_log
        err_log=$(mktemp "$WORK_DIR/_compile_err_${mode}_XXXXXX.log")
        if ! dotnet "$COMPILER_DLL" /C "/$mode" "$f" > "$err_log" 2>&1; then
            log_err "/$mode compile failed: entry=$f"
            log_err "  stderr log: $err_log (= retained for diagnostics)"
            log_err "  log 末尾 16 行抜粋:"
            tail -16 "$err_log" | sed 's/^/    /' | tee -a "$LOG_FILE"
            popd > /dev/null
            exit 2
        fi
        rm -f "$err_log"
        count=$((count + 1))
    done
    popd > /dev/null
    log_info "/$mode compile 完了 ($count entry)"
}

# /N で compile
compile_N() { compile_one "N" "$WORK_N"; }

# /B で compile
compile_B() { compile_one "B" "$WORK_B"; }

# layer A: /N regression (= BASELINE-N.sha256 と完全一致)
verify_layer_a() {
    log_info "layer A check: /N regression vs BASELINE-N.sha256"
    pushd "$WORK_N" > /dev/null
    shasum -a 256 *.M | sort > "$WORK_DIR/N.sha256"
    popd > /dev/null
    if diff -q <(sort "$BASELINE_DIR/BASELINE-N.sha256") "$WORK_DIR/N.sha256" > /dev/null; then
        log_info "layer A PASS — /N output と BASELINE-N.sha256 が完全一致"
        return 0
    fi
    log_err "layer A FAIL — /N output が baseline と不一致"
    log_err "差分:"
    diff <(sort "$BASELINE_DIR/BASELINE-N.sha256") "$WORK_DIR/N.sha256" | tee -a "$LOG_FILE"
    return 1
}

# layer B: /N vs /B byte-identical (= cmp -s で 1:1 完全一致)
verify_layer_b() {
    log_info "layer B check: /N vs /B byte-identical (cmp -s で全 entry 比較)"
    local failed=0
    local failed_entries=()
    for n_file in "$WORK_N"/*.M; do
        local base
        base=$(basename "$n_file")
        local b_file="$WORK_B/$base"
        if [[ ! -f "$b_file" ]]; then
            log_err "/B output 欠落: $base"
            failed=$((failed + 1))
            failed_entries+=("$base (missing in /B)")
            continue
        fi
        if ! cmp -s "$n_file" "$b_file"; then
            failed=$((failed + 1))
            failed_entries+=("$base")
            log_err "byte 不一致: $base"
            log_err "  /N size: $(wc -c < "$n_file" | tr -d ' ') byte"
            log_err "  /B size: $(wc -c < "$b_file" | tr -d ' ') byte"
            # 最初の差分 byte offset を表示
            local diff_offset
            diff_offset=$(cmp "$n_file" "$b_file" 2>&1 | head -1)
            log_err "  cmp 差分: $diff_offset"
        fi
    done
    if [[ "$failed" -eq 0 ]]; then
        log_info "layer B PASS — 28 entry 全件 /N と /B が byte-identical"
        return 0
    fi
    log_err "layer B FAIL — $failed entry 不一致"
    log_err "失敗 entry list:"
    for e in "${failed_entries[@]}"; do
        log_err "  - $e"
    done
    return 1
}

# layer C: /B 出力に .MN が 0 件 (= adpcma_used = false、 .M 維持)
verify_layer_c() {
    log_info "layer C check: /B 出力に .MN 不在 (= ADPCM-A 未使用 = .M 維持)"
    local mn_count
    # null-glob trick: find で counting (= ls の no-match shell error 回避)
    mn_count=$(find "$WORK_B" -maxdepth 1 -name '*.MN' | wc -l | tr -d ' ')
    if [[ "$mn_count" -eq 0 ]]; then
        log_info "layer C PASS — /B 出力に .MN 0 件 (= ADPCM-A 未使用 経路で .M 維持)"
        return 0
    fi
    log_err "layer C FAIL — /B 出力に .MN が $mn_count 件 (= 期待 0 件)"
    log_err "意図しない .MN 一覧:"
    find "$WORK_B" -maxdepth 1 -name '*.MN' | tee -a "$LOG_FILE"
    return 1
}

main() {
    echo "=========================================="
    echo "ADR-0016 step 2 verify — /N vs /B byte-identical"
    echo "=========================================="
    # log file は check_env / prepare_workdir 前に init (= log_info / log_err を最初から tee 可能)
    mkdir -p "$WORK_DIR"
    : > "$LOG_FILE"
    check_env
    prepare_workdir
    compile_N
    compile_B

    local result=0
    verify_layer_a || result=1
    verify_layer_b || result=1
    verify_layer_c || result=1

    echo
    if [[ "$result" -eq 0 ]]; then
        log_info "===== step 2 verify TOTAL PASS ====="
        log_info "log: $LOG_FILE"
        exit 0
    fi
    log_err "===== step 2 verify TOTAL FAIL ====="
    log_err "log: $LOG_FILE"
    exit 1
}

main "$@"
