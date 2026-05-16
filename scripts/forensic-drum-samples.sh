#!/usr/bin/env bash
# forensic-drum-samples.sh
#
# ADR-0033 §決定 21 4 系統 1 件目 = read-only inventory.
# §決定 20 8 段階 flow mechanical 実装。
#
# 役割: assets/sounds/adpcma/ 配下の現存 drum sample (= wav + adpcma) を
# inventory + sha256 canonical 化 + meta 抽出 + driver source 対応確認 +
# 4 分類推定 (= confirmed / likely / unknown / not-applicable) を engineering
# provenance note として stdout に表形式 emit する。
#
# 規律:
# - read-only (= 既存 file 一切改変しない、 driver / fixture / verify script 完全不変)
# - 法的判断ではなく engineering note (= §決定 15 / 20 連動)
# - sha256 を canonical identity として用いる
# - observed facts first / provenance inference second
#
# usage: scripts/forensic-drum-samples.sh
#
# exit 0 = inventory 完了 (= file 不在 or meta 抽出失敗時も 0、 結果 stdout に明示)
# exit 1 = script 起動失敗 (= 環境問題、 file path 誤り等)

set -u
set -o pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ADPCMA_DIR="${ROOT_DIR}/assets/sounds/adpcma"
DRIVER_FILE="${ROOT_DIR}/src/driver/standalone_test.s"

DRUM_NAMES=(BD SD HH RIM TOM TOP)
DRUM_SEMANTICS_BD="bass drum"
DRUM_SEMANTICS_SD="snare drum"
DRUM_SEMANTICS_HH="hi-hat (closed)"
DRUM_SEMANTICS_RIM="rim shot"
DRUM_SEMANTICS_TOM="tom"
DRUM_SEMANTICS_TOP="top cymbal (= CYM PMD semantics 共用)"

print_header() {
    local title="$1"
    echo ""
    echo "================================================================"
    echo " ${title}"
    echo "================================================================"
}

print_subheader() {
    local title="$1"
    echo ""
    echo "---- ${title} ----"
}

# ---------------------------------------------------------------------------
# 段階 1: current wav inventory
# 段階 2: sha256
# 段階 3: sample rate / length / channel count
# 段階 4: file header
# ---------------------------------------------------------------------------
inventory_one_file() {
    local f="$1"

    if [[ ! -f "${f}" ]]; then
        echo "  [missing] ${f}"
        return
    fi

    local rel
    rel="${f#${ROOT_DIR}/}"
    local size
    size=$(wc -c <"${f}" | tr -d ' ')
    local sha
    sha=$(shasum -a 256 "${f}" | awk '{print $1}')
    local magic
    magic=$(xxd -l 4 -p "${f}" 2>/dev/null || echo "????????")

    echo "  file:   ${rel}"
    echo "  size:   ${size} bytes"
    echo "  sha256: ${sha}"
    echo "  magic:  ${magic}"

    case "${f}" in
        *.wav)
            # RIFF WAVE header parse via python
            python3 - <<PYEOF "${f}"
import sys, wave, contextlib
path = sys.argv[1]
try:
    with contextlib.closing(wave.open(path, "rb")) as w:
        sr = w.getframerate()
        nch = w.getnchannels()
        sw = w.getsampwidth()
        nf = w.getnframes()
        dur_ms = (nf * 1000.0) / sr if sr else 0
        print(f"  wav:    sample_rate={sr} Hz, channels={nch}, sample_width={sw*8} bit, frames={nf}, duration={dur_ms:.1f} ms")
except wave.Error as e:
    print(f"  wav:    [parse error] {e}")
except Exception as e:
    print(f"  wav:    [error] {e}")
PYEOF
            ;;
        *.adpcma)
            # ADPCM-A = headerless 4-bit nibble stream
            local samples=$((size * 2))
            # ADPCM-A canonical sample rate 18500 Hz (= §決定 9 chip pipeline 想定値)
            local dur_ms_18500=$(python3 -c "print(f'{${samples} * 1000.0 / 18500.0:.1f}')")
            echo "  adpcma: nibble_count=${samples} (= 4-bit samples), duration_at_18500Hz=${dur_ms_18500} ms (= ADPCM-A chip canonical rate)"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# 段階 5: current samples.inc / driver source 対応
# ---------------------------------------------------------------------------
inventory_driver_symbol_mapping() {
    print_subheader "段階 5: driver source 対応 (= standalone_test.s adpcma_sample_* symbol)"
    echo ""
    echo "  samples.inc = build-time generated (= vromtool.py 経由)、"
    echo "  driver source = src/driver/standalone_test.s 内 adpcma_sample_* label literal embed。"
    echo ""

    if [[ ! -f "${DRIVER_FILE}" ]]; then
        echo "  [warn] driver file 不在: ${DRIVER_FILE}"
        return
    fi

    echo "  driver embed symbol (= grep result):"
    grep -nE "^adpcma_sample_(bd|sd|hh|rim|tom|top):" "${DRIVER_FILE}" \
        | sed 's/^/    /'

    echo ""
    echo "  PMD semantics ↔ sample 名 対応 (= ADR-0026〜0031 §決定 3 整合):"
    echo "    BD  ↔ adpcma_sample_bd    (= bass drum、 ADR-0026 Step 12)"
    echo "    SD  ↔ adpcma_sample_sd    (= snare drum、 ADR-0027 Step 13)"
    echo "    HH  ↔ adpcma_sample_hh    (= hi-hat、 ADR-0028 Step 14)"
    echo "    CYM ↔ adpcma_sample_top   (= top cymbal symbol reuse、 ADR-0029 Step 15)"
    echo "    TOM ↔ adpcma_sample_tom   (= tom、 ADR-0030 Step 16)"
    echo "    RIM ↔ adpcma_sample_rim   (= rim shot、 ADR-0031 Step 17)"
}

# ---------------------------------------------------------------------------
# 段階 6: vendor wav 対応 (= drum 軸との関係確認)
# ---------------------------------------------------------------------------
inventory_vendor_wav() {
    print_subheader "段階 6: vendor wav 対応 (= drum 軸との関係確認)"
    echo ""
    echo "  vendor 配下に存在する wav (= 種別ごとに分類、 drum 軸ではない確認):"
    echo ""
    echo "  - vendor/PMDDotNET/*.wav             = PMDDotNET 動作確認 wav (= voice 検証等、 drum 軸 ✗)"
    echo "  - vendor/PMDDotNET/voice-*/*.wav     = voice 検証 dataset (= TL/AR/DR/ML/ALG/FBL、 drum 軸 ✗)"
    echo "  - vendor/ngdevkit-examples/06-sound-adpcma/assets/*.wav = ngdevkit example sample"
    echo "                                          (lefthook / lightbulbbreaking / woosh、 drum 軸 ✗)"
    echo "  - data/blob/voice-*.wav              = Phase 0 voice 検証 wav (= drum 軸 ✗)"
    echo ""
    echo "  → drum sample に該当する vendor wav は不在。"
    echo "    assets/sounds/adpcma/ 配下 6 件のみが現存 drum sample。"
}

# ---------------------------------------------------------------------------
# 段階 7: 4 分類推定 (= confirmed / likely / unknown / not-applicable)
# ---------------------------------------------------------------------------
inventory_4class_estimation() {
    print_subheader "段階 7: 4 分類推定 (= confirmed / likely / unknown / not-applicable)"
    echo ""
    echo "  分類 = engineering provenance note (= §決定 20 literal、 法的判断ではない)。"
    echo "  4 分類定義:"
    echo "    confirmed       = 起源 file path + history 明確、 sha256 で外部 source と一致"
    echo "    likely          = 命名 / 内容 / 規約から起源を強く推定可能、 外部 source 未確認"
    echo "    unknown         = 起源不明、 命名のみ手がかり、 forensic 深度では確定不可"
    echo "    not-applicable  = drum 軸対象外 (= vendor voice / ngdevkit example 等)"
    echo ""
    echo "  current assessment (= 観察事実から、 inference 後追い):"
    echo "    - assets/sounds/adpcma/2608_*.wav   命名「2608_<drum>-roundtrip.wav」"
    echo "                                        roundtrip suffix = ADPCM-A 経由 round-trip 痕跡"
    echo "                                        = encoded から decode 結果の可能性が高い"
    echo "                                        → 分類 = unknown (= 起源 wav は別 file 想定、 観察事実は roundtrip output)"
    echo "    - assets/sounds/adpcma/2608_*.adpcma  ADPCM-A 4-bit 圧縮 binary"
    echo "                                        命名規則 = §決定 7 公式 (= 2608_{bd,sd,top,hh,tom,rim})"
    echo "                                        → 分類 = unknown (= encoder 不明、 source wav 不明)"
    echo ""
    echo "  ※ 詳細 origin inference は §Annex A-5 後埋め時に 4 分類別表で記録。"
    echo "    本 script の役割は observed facts (= sha256 / meta / 命名) の mechanical 収集まで。"
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    print_header "forensic-drum-samples.sh — ADR-0033 §決定 20 8 段階 flow"
    echo ""
    echo " root:    ${ROOT_DIR}"
    echo " target:  ${ADPCMA_DIR}"
    echo " date:    $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo " script:  $(basename "$0")"
    echo " 役割:    read-only inventory (= driver / fixture / verify script 完全不変)"

    print_header "段階 1-4: current wav / adpcma inventory (= file + sha256 + meta + magic)"

    for drum in "${DRUM_NAMES[@]}"; do
        local drum_lower
        drum_lower=$(echo "${drum}" | tr 'A-Z' 'a-z')
        # PMD semantics 名 (= 別表記がある drum のみ別途記載)
        local semantics_var="DRUM_SEMANTICS_${drum}"
        local semantics="${!semantics_var:-${drum}}"

        print_subheader "drum: ${drum} (= ${semantics})"

        local wav_file="${ADPCMA_DIR}/2608_${drum}-roundtrip.wav"
        local adpcma_file="${ADPCMA_DIR}/2608_${drum}.adpcma"

        echo ""
        echo "  ── wav side ──"
        inventory_one_file "${wav_file}"

        echo ""
        echo "  ── adpcma side ──"
        inventory_one_file "${adpcma_file}"
    done

    inventory_driver_symbol_mapping
    inventory_vendor_wav
    inventory_4class_estimation

    print_header "forensic-drum-samples.sh 完了 (= 段階 8 git/external comparison は必要時別途実行)"
    echo ""
    echo " observed facts 収集完了。 §Annex A-5 後埋めには本 stdout を engineering note literal 反映。"
    echo ""
}

main "$@"
