#!/usr/bin/env bash
# build_drum_samples.sh
#
# ADR-0033 §決定 21 4 系統 3 件目 = orchestration interface stub.
# 23rd session sub-sprint α interface fixation = 中身は sub-sprint γ で実装。
#
# ----------------------------------------------------------------------------
# 1. script purpose
# ----------------------------------------------------------------------------
# 6 種 source wav (= BD / SD / HH / RIM / TOM / TOP) を一括変換し、
# samples.inc + adpcma 群を生成する orchestration script。
# 「source wav directory を 1 件指定すると、 PMDNEO build に embed 可能な
#  adpcma 6 件 + samples.inc 1 件を一括出力する」 全自動化エントリポイント。
#
# 単一 wav 変換 = scripts/wav_to_adpcma.sh 担当 (= 本 script から loop で invoke)。
# 既存 adpcma 棚卸し = scripts/forensic-drum-samples.sh 担当。
# 再現性検証 = scripts/verify-drum-samples.sh 担当。
#
# ----------------------------------------------------------------------------
# 2. ADR-0033 §決定 21 との対応
# ----------------------------------------------------------------------------
# §決定 21 literal:
# - forensic-drum-samples.sh   = read-only inventory      (1 件目、 23rd session α 完成 ✓)
# - wav_to_adpcma.sh           = one-file converter       (2 件目、 interface fixation ✓)
# - build_drum_samples.sh      = orchestration            (3 件目 = 本 script、 interface fixation ✓)
# - verify-drum-samples.sh     = reproducibility gate     (4 件目、 interface fixation ✓)
#
# §決定 17 OPNA pipeline 完全 scripts 化 / canonical source / WebApp future UI 役割分離。
# 手作業変換は禁止 (= 段階 3 完全ホワイト化 milestone まで全部 script 経路)。
#
# ----------------------------------------------------------------------------
# 3. input path
# ----------------------------------------------------------------------------
# 引数 1: source wav directory path
#   canonical default (= §決定 23 prototype render naming literal):
#     assets/drum_samples/synth/
#
# directory 内 file 配置 (= §決定 7 命名規則 literal):
#   assets/drum_samples/synth/2608_bd.wav
#   assets/drum_samples/synth/2608_sd.wav
#   assets/drum_samples/synth/2608_hh.wav
#   assets/drum_samples/synth/2608_rim.wav
#   assets/drum_samples/synth/2608_tom.wav
#   assets/drum_samples/synth/2608_top.wav
#
# kit 切替 (= §決定 23 directory = kit identity literal):
#   assets/drum_samples/synth/      = 段階 1 Surge XT 合成 kit
#   assets/drum_samples/acoustic/   = 段階 2 acoustic 録音 kit (= future)
#
# ----------------------------------------------------------------------------
# 4. output path
# ----------------------------------------------------------------------------
# canonical default output:
#   assets/sounds/adpcma/2608_BD.adpcma
#   assets/sounds/adpcma/2608_SD.adpcma
#   assets/sounds/adpcma/2608_HH.adpcma
#   assets/sounds/adpcma/2608_RIM.adpcma
#   assets/sounds/adpcma/2608_TOM.adpcma
#   assets/sounds/adpcma/2608_TOP.adpcma
#   assets/samples.inc                    (= build-time generated、 driver source `.include` 経路)
#
# 既存 12 file (= roundtrip wav + adpcma) との関係:
#   段階 1 sub-sprint δ で本 script 経由再生成された adpcma 6 件が、
#   既存「unknown 起源 adpcma 6 件」 を literal 置換する (= 段階 3 完全ホワイト化 milestone)。
#   roundtrip wav 6 件は段階 3 で削除 (= source wav が canonical source となり roundtrip 不要)。
#
# ----------------------------------------------------------------------------
# 5. expected format
# ----------------------------------------------------------------------------
# 入力 (= source wav directory):
#   全 6 wav 共通 format (= §決定 8 literal):
#     RIFF WAVE PCM / 1 ch / 44100 Hz / 16 bit
#
# 出力 (= adpcma + samples.inc):
#   adpcma: headerless 4-bit nibble stream (= 18.5 kHz decode rate、 §決定 9)
#   samples.inc: `.equ <DRUM>_START_LSB/MSB / <DRUM>_STOP_LSB/MSB` 形式
#     (= vendor/ngdevkit-examples/06-sound-adpcma/build/assets/samples.inc 参照)
#
# ----------------------------------------------------------------------------
# 6. future implementation phase
# ----------------------------------------------------------------------------
# 23rd session = interface fixation のみ (= header + usage + not-implemented exit)。
# 中身実装 = ADR-0033 段階 1 sub-sprint γ = OPNA pipeline 構築:
#   step γ-1: source wav 6 件存在確認 + format 検証 (= §決定 8 準拠)
#   step γ-2: 6 件並列 / 順次 ループで wav_to_adpcma.sh invoke
#   step γ-3: 6 adpcma の sha256 記録 (= verify-drum-samples.sh manifest 連携)
#   step γ-4: samples.inc 生成 (= adpcma addr / size を `.equ` 形式 emit)
#   step γ-5: build 統合確認 (= driver source `.include "assets/samples.inc"` 経路)
#
# 前提条件:
#   - source wav 6 件が assets/drum_samples/synth/ に存在 (= sub-sprint β 完了)
#   - wav_to_adpcma.sh 中身実装完了 (= sub-sprint γ 内同時 commit chain)
#   - superctr/adpcm install 完了 (= §決定 18 + §Annex A-7)
#
# ----------------------------------------------------------------------------
# 7. exit code policy
# ----------------------------------------------------------------------------
# 0   = usage 表示 (= -h / --help)
# 2   = not-implemented sentinel (= 23rd session interface stub、 source wav 完成前)
# 64  = usage error (= EX_USAGE 慣行、 引数不正)
# 1   = 一般エラー (= future 実装後の wav 不在 / format 不正 / wav_to_adpcma.sh 失敗等)
#
# ----------------------------------------------------------------------------
# 8. examples
# ----------------------------------------------------------------------------
# usage 表示:
#   scripts/build_drum_samples.sh -h
#   scripts/build_drum_samples.sh --help
#
# 想定 invocation (= sub-sprint γ 中身実装後):
#   scripts/build_drum_samples.sh assets/drum_samples/synth/
#     → assets/sounds/adpcma/*.adpcma 6 件 + assets/samples.inc 生成
#
#   scripts/build_drum_samples.sh assets/drum_samples/acoustic/
#     → 段階 2 完了後の acoustic kit ビルド (= §決定 23 parallel kit families)
#
# 23rd session 現状 invocation:
#   scripts/build_drum_samples.sh assets/drum_samples/synth/
#     → exit 2 + 「not implemented until source wav exists」 明示
#
# ----------------------------------------------------------------------------
# 9. TODO section (= sub-sprint γ 実装時に reference)
# ----------------------------------------------------------------------------
# [ ] source wav directory 存在 + 6 件揃い check (= 2608_{bd,sd,hh,rim,tom,top}.wav)
# [ ] 各 wav の format 検証 (= 44100 Hz mono 16 bit RIFF WAVE PCM、 §決定 8 準拠)
# [ ] wav_to_adpcma.sh を 6 回 loop invoke (= 並列化判断は実装時)
# [ ] 6 adpcma の sha256 記録 (= reproducibility manifest 出力 = verify-drum-samples.sh 連携)
# [ ] samples.inc 自動生成 (= addr / size 計算 + `.equ` emit)
# [ ] driver source `.include "assets/samples.inc"` 経路と byte-level 統合確認
# [ ] エラーハンドリング (= partial failure 時の rollback or atomic 出力判断)
# [ ] log 出力 (= build 日時 / encoder version / source wav sha256 / output sha256 chain)
# [ ] sub-sprint γ commit chain (= ε / ζ / η 候補) で段階実装
#
# ============================================================================

set -u
set -o pipefail

SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
${SCRIPT_NAME} - ADR-0033 §決定 21 4 系統 3 件目 orchestration

usage:
  ${SCRIPT_NAME} <source_wav_directory>
  ${SCRIPT_NAME} -h | --help

description:
  source wav directory (= 6 drum wav literal 配置) を一括変換し、
  adpcma 6 件 + samples.inc 1 件を生成する orchestration script。
  単一 wav 変換は wav_to_adpcma.sh 担当 (= 本 script から loop で invoke)。

  canonical input directory:
    assets/drum_samples/synth/      (= 段階 1 Surge XT 合成 kit)
    assets/drum_samples/acoustic/   (= 段階 2 acoustic 録音 kit、 future)

  canonical output:
    assets/sounds/adpcma/*.adpcma   (= 6 件)
    assets/samples.inc              (= build-time include 経路)

status:
  23rd session interface fixation 完了 (= header + usage + not-implemented exit)。
  中身実装 = sub-sprint γ OPNA pipeline 構築時 (= wav_to_adpcma.sh + samples.inc 生成統合)。
  source wav 完成 = sub-sprint β Surge XT prototype 完了が前提。

exit codes:
  0   usage 表示 (= -h / --help)
  2   not-implemented sentinel (= 23rd session interface stub)
  64  usage error (= 引数不正)
  1   一般エラー (= future 実装後)

see also:
  scripts/forensic-drum-samples.sh   - read-only inventory (23rd session α 完成)
  scripts/wav_to_adpcma.sh           - one-file converter (interface fixation のみ)
  scripts/verify-drum-samples.sh     - reproducibility gate (interface fixation のみ)
  docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md
    §決定 7 / §決定 8 / §決定 9 / §決定 17 / §決定 21 / §決定 23 / §Annex A-7
EOF
}

# --- arg parse ---
if [[ $# -eq 0 ]]; then
    usage
    echo ""
    echo "[error] source wav directory が指定されていません。"
    exit 64
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [[ $# -ne 1 ]]; then
    usage
    echo ""
    echo "[error] 引数は 1 件必要です (= source wav directory)。 received: $#"
    exit 64
fi

SOURCE_WAV_DIR="$1"

# --- not-implemented sentinel ---
cat <<EOF
${SCRIPT_NAME}: ADR-0033 §決定 21 4 系統 3 件目 interface stub.

  source wav directory: ${SOURCE_WAV_DIR}
  expected output:      assets/sounds/adpcma/*.adpcma (6 件) + assets/samples.inc

[not-implemented] source wav が project 内に存在するまで本 script は実装されません。

理由 (= ADR-0033 §Annex A-5-5 finding 2 literal):
  23rd session forensic 結果 = 現存 wav 6 件は全部 18500 Hz roundtrip output で、
  source wav (= §決定 8 = 44100 Hz mono 16 bit) は project 内不在。
  source wav 6 件完成 = sub-sprint β Surge XT prototype の 6 種 wav render が前提。

実装は sub-sprint γ OPNA pipeline 構築時に行います (= wav_to_adpcma.sh 中身実装 + samples.inc 自動生成 + sha256 manifest 連携)。
詳細 = docs/adr/0033-...md §決定 17 / §決定 21 / §Annex A-7 参照。
EOF

exit 2
