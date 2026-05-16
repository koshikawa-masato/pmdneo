#!/usr/bin/env bash
# wav_to_adpcma.sh
#
# ADR-0033 §決定 21 4 系統 2 件目 = one-file converter interface stub.
# 23rd session sub-sprint α interface fixation = 中身は sub-sprint γ で実装。
#
# ----------------------------------------------------------------------------
# 1. script purpose
# ----------------------------------------------------------------------------
# 1 wav file → 1 adpcma file の one-file converter。
# 「source wav 1 件を ADPCM-A nibble stream 1 件に変換する」 という単一責務。
# orchestration (= 複数 drum 一括処理) は scripts/build_drum_samples.sh 担当。
# inventory (= 既存 adpcma 棚卸し) は scripts/forensic-drum-samples.sh 担当。
# verification (= reproducibility gate) は scripts/verify-drum-samples.sh 担当。
#
# ----------------------------------------------------------------------------
# 2. ADR-0033 §決定 21 との対応
# ----------------------------------------------------------------------------
# §決定 21 literal:
# - forensic-drum-samples.sh   = read-only inventory      (1 件目、 23rd session α 完成 ✓)
# - wav_to_adpcma.sh           = one-file converter       (2 件目 = 本 script、 interface fixation ✓)
# - build_drum_samples.sh      = orchestration            (3 件目、 interface fixation ✓)
# - verify-drum-samples.sh     = reproducibility gate     (4 件目、 interface fixation ✓)
#
# 1 script = 1 責務原則。 4 系統境界が混ざらないよう interface fixation で固定。
#
# ----------------------------------------------------------------------------
# 3. input path
# ----------------------------------------------------------------------------
# 引数 1: 入力 wav file path (= 絶対 path / 相対 path どちらでも可)
# 引数 2: 出力 adpcma file path (= 同上)
#
# 入力 wav は §決定 8 source wav format 準拠想定:
# - RIFF WAVE PCM
# - 1 ch (mono)
# - 44100 Hz
# - 16 bit
#
# canonical 入力 path 例 (= §決定 23 prototype render naming literal):
#   assets/drum_samples/synth/2608_bd.wav
#   assets/drum_samples/synth/2608_sd.wav
#   ...
#   assets/drum_samples/synth/2608_top.wav
#
# ----------------------------------------------------------------------------
# 4. output path
# ----------------------------------------------------------------------------
# canonical 出力 path 例:
#   assets/sounds/adpcma/2608_BD.adpcma
#   ...
#
# 出力 = ADPCM-A 4-bit nibble stream (= headerless binary)、 §決定 9 chip 化 pipeline 経由:
# - 18.5 kHz decimate (= chip canonical sample rate 整合)
# - 4-bit ADPCM-A 圧縮
#
# ----------------------------------------------------------------------------
# 5. expected format
# ----------------------------------------------------------------------------
# 入力 wav format (= §決定 8 literal):
#   sample rate: 44100 Hz
#   channels:    1 (mono)
#   sample width: 16 bit
#   container:   RIFF WAVE PCM
#
# 出力 adpcma format (= §決定 9 + ADPCM-A chip 仕様):
#   sample rate: 18500 Hz (= chip canonical decode rate)
#   bit depth:   4 bit (= nibble stream)
#   container:   headerless raw binary
#
# 中間 stage:
#   stage 1: 44100 Hz wav → 18500 Hz wav (= decimation、 anti-alias filter 適用)
#   stage 2: 18500 Hz wav → 4-bit ADPCM-A nibble stream (= encoder 経由)
#
# ----------------------------------------------------------------------------
# 6. future implementation phase
# ----------------------------------------------------------------------------
# 23rd session = interface fixation のみ (= header + usage + not-implemented exit)。
# 中身実装 = ADR-0033 段階 1 sub-sprint γ = OPNA pipeline 構築:
#   - §決定 18 encoder = superctr/adpcm (= 既存 community encoder) + 本 script から薄い wrapper として invoke
#   - §決定 9 chip 化 pipeline (= 18.5 kHz decimate + 4-bit ADPCM-A 圧縮) の literal 実装
#   - §Annex A-7 後埋め枠 (= encoder 採用根拠) reference
#
# 前提条件:
#   - source wav (= §決定 8 source format) が project 内に存在すること
#   - 23rd session forensic 結果 = source wav 不在 (= §Annex A-5-5 finding 2)
#   - sub-sprint β (= Surge XT で 6 種 source wav 新規 create) 完了が前提
#
# ----------------------------------------------------------------------------
# 7. exit code policy
# ----------------------------------------------------------------------------
# 0   = usage 表示 (= -h / --help)
# 2   = not-implemented sentinel (= 23rd session interface stub、 source wav 完成前)
# 64  = usage error (= EX_USAGE 慣行、 引数不正)
# 1   = 一般エラー (= future 実装後の I/O 失敗等)
#
# ----------------------------------------------------------------------------
# 8. examples
# ----------------------------------------------------------------------------
# usage 表示:
#   scripts/wav_to_adpcma.sh -h
#   scripts/wav_to_adpcma.sh --help
#
# 想定 invocation (= sub-sprint γ 中身実装後):
#   scripts/wav_to_adpcma.sh \
#     assets/drum_samples/synth/2608_bd.wav \
#     assets/sounds/adpcma/2608_BD.adpcma
#
# 23rd session 現状 invocation:
#   scripts/wav_to_adpcma.sh in.wav out.adpcma
#     → exit 2 + 「not implemented until source wav exists」 明示
#
# ----------------------------------------------------------------------------
# 9. TODO section (= sub-sprint γ 実装時に reference)
# ----------------------------------------------------------------------------
# [ ] superctr/adpcm install + version 記録 (= §Annex A-7 後埋め)
# [ ] sox / ffmpeg / python scipy 等の decimation 経路選定
# [ ] 44100 Hz → 18500 Hz decimation filter 設計 (= anti-alias + group delay)
# [ ] 16-bit PCM → 4-bit ADPCM-A encoder invocation wrapper
# [ ] エラーハンドリング (= 入力 format 不正 / file 不在 / encoder 失敗)
# [ ] 出力 sha256 ログ (= verify-drum-samples.sh 連携、 reproducibility gate 対応)
# [ ] sub-sprint γ commit chain (= ε / ζ / η 候補) で段階実装
#
# ============================================================================

set -u
set -o pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
${SCRIPT_NAME} - ADR-0033 §決定 21 4 系統 2 件目 one-file converter

usage:
  ${SCRIPT_NAME} <input.wav> <output.adpcma>
  ${SCRIPT_NAME} -h | --help

description:
  source wav (= §決定 8 = 44100 Hz mono 16 bit RIFF WAVE PCM) を
  ADPCM-A nibble stream (= §決定 9 = 18.5 kHz decimate + 4-bit) に変換する
  one-file converter。 orchestration ではない (= build_drum_samples.sh 担当)。

status:
  23rd session interface fixation 完了 (= header + usage + not-implemented exit)。
  中身実装 = sub-sprint γ OPNA pipeline 構築時 (= §決定 18 superctr/adpcm + 薄い wrapper)。
  source wav 完成 = sub-sprint β Surge XT prototype 完了が前提。

exit codes:
  0   usage 表示 (= -h / --help)
  2   not-implemented sentinel (= 23rd session interface stub)
  64  usage error (= 引数不正)
  1   一般エラー (= future 実装後)

see also:
  scripts/forensic-drum-samples.sh   - read-only inventory (23rd session α 完成)
  scripts/build_drum_samples.sh      - orchestration (interface fixation のみ)
  scripts/verify-drum-samples.sh     - reproducibility gate (interface fixation のみ)
  docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md
    §決定 8 / §決定 9 / §決定 18 / §決定 21 / §Annex A-7
EOF
}

# --- arg parse ---
if [[ $# -eq 0 ]]; then
    usage
    echo ""
    echo "[error] 引数が指定されていません。"
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
    echo "[error] 引数は 2 件必要です (= input.wav + output.adpcma)。 received: $#"
    exit 64
fi

INPUT_WAV="$1"
OUTPUT_ADPCMA="$2"

# --- not-implemented sentinel ---
cat <<EOF
${SCRIPT_NAME}: ADR-0033 §決定 21 4 系統 2 件目 interface stub.

  input wav:     ${INPUT_WAV}
  output adpcma: ${OUTPUT_ADPCMA}

[not-implemented] source wav が project 内に存在するまで本 script は実装されません。

理由 (= ADR-0033 §Annex A-5-5 finding 2 literal):
  23rd session forensic 結果 = 現存 wav 6 件は全部 18500 Hz roundtrip output で、
  encoder input となる source wav (= §決定 8 = 44100 Hz mono 16 bit) は project 内不在。
  source wav 完成 = sub-sprint β Surge XT prototype + 6 種 wav render が前提。

実装は sub-sprint γ OPNA pipeline 構築時に行います (= §決定 18 superctr/adpcm + 薄い wrapper)。
詳細 = docs/adr/0033-...md §決定 18 / §決定 21 / §Annex A-7 参照。
EOF

exit 2
