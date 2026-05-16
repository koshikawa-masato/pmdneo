#!/usr/bin/env bash
# verify-drum-samples.sh
#
# ADR-0033 §決定 21 4 系統 4 件目 = reproducibility gate interface stub.
# 23rd session sub-sprint α interface fixation = 中身は sub-sprint γ / δ で実装。
#
# ----------------------------------------------------------------------------
# 1. script purpose
# ----------------------------------------------------------------------------
# 「source wav から build_drum_samples.sh で生成される adpcma 6 件 + samples.inc が、
#  manifest に記録された canonical sha256 と byte-identical に一致するか」 を
# 機械的に検証する reproducibility gate。
#
# future contributor が source wav + 本 script + scripts/build_drum_samples.sh
# のみから同一 adpcma を再生成できることを保証する verification 軸。
#
# inventory (= forensic) = scripts/forensic-drum-samples.sh 担当 (= 別軸、 read-only)。
# 単一 wav 変換 = scripts/wav_to_adpcma.sh 担当。
# 一括ビルド = scripts/build_drum_samples.sh 担当。
#
# ----------------------------------------------------------------------------
# 2. ADR-0033 §決定 21 との対応
# ----------------------------------------------------------------------------
# §決定 21 literal:
# - forensic-drum-samples.sh   = read-only inventory      (1 件目、 23rd session α 完成 ✓)
# - wav_to_adpcma.sh           = one-file converter       (2 件目、 interface fixation ✓)
# - build_drum_samples.sh      = orchestration            (3 件目、 interface fixation ✓)
# - verify-drum-samples.sh     = reproducibility gate     (4 件目 = 本 script、 interface fixation ✓)
#
# §決定 20 sha256 canonical 規律と整合 (= forensic と同じ canonical identity 軸)。
# A 系統 (= runtime / audio) と B 系統 (= build / asset pipeline) の 2 系統 verify 体系
# (= memory `pmdneo-verify-two-subsystems`) の B 系統に位置。
#
# ----------------------------------------------------------------------------
# 3. input path
# ----------------------------------------------------------------------------
# 引数 1: source wav directory path (= 検証対象 kit、 build_drum_samples.sh と同 input)
# 引数 2: manifest file path (= 期待 sha256 + meta を記録した text/JSON file)
#
# canonical input 例:
#   引数 1: assets/drum_samples/synth/
#   引数 2: assets/drum_samples/synth/manifest.sha256
#
# manifest format (= sub-sprint γ で確定、 候補は plain text or JSON):
#   plain text 案 (= shasum 互換):
#     <sha256>  <relative_path>
#     例:
#       0dd42be876987e220f5ddb1192dfa83cd032258467d592a24b0ecca86a503656  2608_BD.adpcma
#       ...
#
#   JSON 案 (= meta も含める):
#     {
#       "kit": "synth",
#       "build_date": "2026-xx-xx",
#       "encoder": "superctr/adpcm <version>",
#       "files": [
#         { "name": "2608_BD.adpcma", "sha256": "...", "size": 1024, "duration_ms": 110.7 },
#         ...
#       ]
#     }
#
# manifest 形式の最終確定は sub-sprint γ commit で行う (= 本 stub では未確定 literal 維持)。
#
# ----------------------------------------------------------------------------
# 4. output path
# ----------------------------------------------------------------------------
# stdout: PASS / FAIL 結果 (= drum 別 + summary)
# exit code: PASS = 0 / FAIL = 1
#
# 出力例 (= sub-sprint γ 実装後):
#   verify-drum-samples.sh assets/drum_samples/synth/ assets/drum_samples/synth/manifest.sha256
#
#   [PASS] 2608_BD.adpcma  sha256 matches manifest
#   [PASS] 2608_SD.adpcma  sha256 matches manifest
#   [PASS] 2608_HH.adpcma  sha256 matches manifest
#   [PASS] 2608_RIM.adpcma sha256 matches manifest
#   [PASS] 2608_TOM.adpcma sha256 matches manifest
#   [PASS] 2608_TOP.adpcma sha256 matches manifest
#   summary: 6 / 6 PASS - reproducibility gate PASSED
#
# ----------------------------------------------------------------------------
# 5. expected format
# ----------------------------------------------------------------------------
# 検証方法 (= sub-sprint γ 実装時 literal):
#   step a: source wav directory → scripts/build_drum_samples.sh で adpcma 再生成 (= 一時 directory)
#   step b: 再生成 adpcma 6 件の sha256 計算
#   step c: manifest 記載 sha256 との byte-identical 比較
#   step d: 全 6 件一致 = PASS / 任意 1 件でも不一致 = FAIL
#
# verification 粒度 = byte-identical (= sha256 一致、 forensic と同じ canonical identity 規律)。
# sample-level similarity (= adpcma decode → wav RMS 比較等) は scope-out
# (= encoder reproducibility 軸では byte-identical で十分、 audio 軸は A 系統別軸)。
#
# ----------------------------------------------------------------------------
# 6. future implementation phase
# ----------------------------------------------------------------------------
# 23rd session = interface fixation のみ (= header + usage + not-implemented exit)。
# 中身実装 = ADR-0033 段階 1 sub-sprint γ / δ:
#   sub-sprint γ: manifest format 確定 + scripts/build_drum_samples.sh 中身完成同時に実装着手
#   sub-sprint δ: 段階 1 完了統合 verify として全 6 drum + samples.inc reproducibility gate 確立
#
# 前提条件:
#   - source wav 6 件存在 (= sub-sprint β 完了)
#   - scripts/build_drum_samples.sh 中身実装完了 (= sub-sprint γ 内)
#   - manifest format 確定 (= sub-sprint γ 初期 commit)
#
# ----------------------------------------------------------------------------
# 7. exit code policy
# ----------------------------------------------------------------------------
# 0   = usage 表示 (= -h / --help)、 または verify PASS (= 全 6 件 byte-identical)
# 1   = verify FAIL (= 任意 1 件以上の sha256 不一致、 reproducibility 破綻)
# 2   = not-implemented sentinel (= 23rd session interface stub、 source wav 完成前)
# 64  = usage error (= EX_USAGE 慣行、 引数不正)
#
# 0 が 2 役割兼用 (= usage / PASS) なのは shell convention 整合。
# CI 統合時は exit 0 = green、 exit 非 0 = red の単純区別で reproducibility gate 機能。
#
# ----------------------------------------------------------------------------
# 8. examples
# ----------------------------------------------------------------------------
# usage 表示:
#   scripts/verify-drum-samples.sh -h
#   scripts/verify-drum-samples.sh --help
#
# 想定 invocation (= sub-sprint γ / δ 中身実装後):
#   scripts/verify-drum-samples.sh \
#     assets/drum_samples/synth/ \
#     assets/drum_samples/synth/manifest.sha256
#
#   scripts/verify-drum-samples.sh \
#     assets/drum_samples/acoustic/ \
#     assets/drum_samples/acoustic/manifest.sha256
#
# 23rd session 現状 invocation:
#   scripts/verify-drum-samples.sh assets/drum_samples/synth/ manifest.sha256
#     → exit 2 + 「not implemented until source wav exists」 明示
#
# ----------------------------------------------------------------------------
# 9. TODO section (= sub-sprint γ / δ 実装時に reference)
# ----------------------------------------------------------------------------
# [ ] manifest format 確定 (= plain text vs JSON、 sub-sprint γ 初期 commit で決定)
# [ ] scripts/build_drum_samples.sh を一時 directory 経路で invoke (= 既存 output 破壊回避)
# [ ] 6 adpcma の sha256 計算 + manifest 値 comparison
# [ ] 不一致 detail report (= どの drum でどの sha256 が期待 vs 実測)
# [ ] samples.inc 自体の verify (= addr / size .equ values の reproducibility)
# [ ] encoder version 記録 (= manifest 内 encoder 列 / superctr/adpcm version)
# [ ] CI 統合 (= GitHub Actions / 等で reproducibility gate 自動実行)
# [ ] partial verify support (= 単一 drum だけ verify する option、 debug 用途)
# [ ] sub-sprint γ commit chain (= ε / ζ / η 候補) と sub-sprint δ 完了統合で段階実装
#
# ============================================================================

set -u
set -o pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
${SCRIPT_NAME} - ADR-0033 §決定 21 4 系統 4 件目 reproducibility gate

usage:
  ${SCRIPT_NAME} <source_wav_directory> <manifest_file>
  ${SCRIPT_NAME} -h | --help

description:
  source wav から scripts/build_drum_samples.sh 経由生成される adpcma 6 件 +
  samples.inc が、 manifest 記載の canonical sha256 と byte-identical に
  一致するかを検証する reproducibility gate。 future contributor が
  source wav + 本 script + scripts/build_drum_samples.sh のみから同一 adpcma を
  再生成できることを保証。

  canonical invocation:
    ${SCRIPT_NAME} assets/drum_samples/synth/ assets/drum_samples/synth/manifest.sha256

  verification 粒度 = byte-identical (= sha256 一致、 §決定 20 canonical identity 規律)。
  sample-level similarity (= audio RMS) は scope-out (= 別軸、 A 系統 runtime/audio)。

status:
  23rd session interface fixation 完了 (= header + usage + not-implemented exit)。
  中身実装 = sub-sprint γ build_drum_samples.sh 完成同時 + sub-sprint δ 完了統合。
  source wav 完成 = sub-sprint β Surge XT prototype 完了が前提。

exit codes:
  0   usage 表示 (= -h / --help)、 または verify PASS
  1   verify FAIL (= sha256 不一致)
  2   not-implemented sentinel (= 23rd session interface stub)
  64  usage error (= 引数不正)

see also:
  scripts/forensic-drum-samples.sh   - read-only inventory (23rd session α 完成)
  scripts/wav_to_adpcma.sh           - one-file converter (interface fixation のみ)
  scripts/build_drum_samples.sh      - orchestration (interface fixation のみ)
  docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md
    §決定 17 / §決定 18 / §決定 20 / §決定 21 / §Annex A-7
EOF
}

# --- arg parse ---
if [[ $# -eq 0 ]]; then
    usage
    echo ""
    echo "[error] 引数が指定されていません (= source wav directory + manifest file)。"
    exit 64
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [[ $# -ne 2 ]]; then
    usage
    echo ""
    echo "[error] 引数は 2 件必要です (= source_wav_directory + manifest_file)。 received: $#"
    exit 64
fi

SOURCE_WAV_DIR="$1"
MANIFEST_FILE="$2"

# --- not-implemented sentinel ---
cat <<EOF
${SCRIPT_NAME}: ADR-0033 §決定 21 4 系統 4 件目 interface stub.

  source wav directory: ${SOURCE_WAV_DIR}
  manifest file:        ${MANIFEST_FILE}

[not-implemented] source wav + manifest が project 内に存在するまで本 script は実装されません。

理由 (= ADR-0033 §Annex A-5-5 finding 2 literal + §決定 21 4 系統 sub-sprint 配分):
  23rd session forensic 結果 = 現存 wav 6 件は roundtrip output で source wav 不在。
  manifest 自体も sub-sprint γ で format 確定 + 値記録される (= 段階 1 sub-sprint γ 初期 commit)。
  sub-sprint β (= Surge XT で 6 種 source wav 新規 create) + sub-sprint γ
  (= build_drum_samples.sh 中身実装) 完了が前提。

実装は sub-sprint γ build_drum_samples.sh 完成同時 + sub-sprint δ 段階 1 完了統合で行います。
詳細 = docs/adr/0033-...md §決定 20 / §決定 21 / §Annex A-7 参照。
EOF

exit 2
