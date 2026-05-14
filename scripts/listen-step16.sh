#!/usr/bin/env bash
#
# scripts/listen-step16.sh
# ADR-0030 step 16 δ: audio gate 試聴 helper (= 10 wav file 順次再生 + sleep 3 interval + 無限繰り返し)
#
# 目的:
#   Step 16 audio gate 判定用に、 K/R × BD/SD/HH/CYM/TOM 10 fixture の wav file を
#   macOS afplay で順次再生する。 各 wav 再生終了後に sleep 3 で interval を挟み、
#   全 10 wav 1 周ごとに while true で繰り返す。 user は Ctrl+C で停止する。
#
#   user が K-X と R-X (= K と R 同音) + BD vs SD vs HH vs CYM vs TOM (= 5 drum 種別区別) を
#   聴感判定しやすいよう、 同 drum を K-R ペアで連続再生する順序を組む。
#
# 再生順 (= 1 周分、 これを無限繰り返し):
#   1. K-BD   → 3 sec sleep → R-BD   (= K-BD ≒ R-BD 同音判定)
#   2. K-SD   → 3 sec sleep → R-SD   (= K-SD ≒ R-SD 同音判定)
#   3. K-HH   → 3 sec sleep → R-HH   (= K-HH ≒ R-HH 同音判定)
#   4. K-CYM  → 3 sec sleep → R-CYM  (= K-CYM ≒ R-CYM 同音判定、 Step 15 既存)
#   5. K-TOM  → 3 sec sleep → R-TOM  (= K-TOM ≒ R-TOM 同音判定、 Step 16 新規)
#
# 判定軸 (= ADR-0030 §audio gate):
#   - K-BD  ≒ R-BD  (= K/R 同音)
#   - K-SD  ≒ R-SD  (= K/R 同音)
#   - K-HH  ≒ R-HH  (= K/R 同音)
#   - K-CYM ≒ R-CYM (= K/R 同音、 Step 15 既存)
#   - K-TOM ≒ R-TOM (= K/R 同音、 Step 16 新規 = ADR-0030 §決定 4/8/9 整合)
#   - BD ≠ SD ≠ HH ≠ CYM ≠ TOM (= 5 drum 種で聴感的区別可能、 sample addr literal differ 整合)
#   - FM 同居許容 (= test01/test02 chord 進行と並走、 Step 12/13/14/15 規律踏襲)
#
# 前提:
#   - 全 10 wav file は事前 build 済 (= verify-step12/13/14/15/16 実行で生成)
#   - macOS afplay (= 標準同梱)
#
# 使い方:
#   bash /Users/koshikawamasato/Projects/pmdneo/scripts/listen-step16.sh
#   または相対:
#   bash scripts/listen-step16.sh
#
# 停止:
#   Ctrl+C で停止 (= 無限繰り返し)
#
# Exit code:
#   0 = 通常終了 (= Ctrl+C 経由)
#   1 = wav file missing
#   2 = infra fail (= afplay 不在等)

set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WAVS=(
    "K-BD                |/tmp/pmdneo-step12/k-br-only.wav"
    "R-BD                |/tmp/pmdneo-step12/r-melody-br-only.wav"
    "K-SD                |/tmp/pmdneo-step13/k-sr-only.wav"
    "R-SD                |/tmp/pmdneo-step13/r-melody-sr-only.wav"
    "K-HH                |/tmp/pmdneo-step14/k-hr-only.wav"
    "R-HH                |/tmp/pmdneo-step14/r-melody-hr-only.wav"
    "K-CYM               |/tmp/pmdneo-step15/k-cr-only.wav"
    "R-CYM               |/tmp/pmdneo-step15/r-melody-cr-only.wav"
    "K-TOM (Step 16 新規)|/tmp/pmdneo-step16/k-tr-only.wav"
    "R-TOM (Step 16 新規)|/tmp/pmdneo-step16/r-melody-tr-only.wav"
)

if ! command -v afplay > /dev/null 2>&1; then
    echo "FAIL infra: afplay not found (macOS only)"
    exit 2
fi

for entry in "${WAVS[@]}"; do
    label="${entry%%|*}"
    path="${entry##*|}"
    if [[ ! -f "$path" ]]; then
        echo "FAIL: wav not found ($label): $path"
        echo "  -> verify-step12/13/14/15/16 を先に実行して wav を生成してください"
        exit 1
    fi
done

echo "=== ADR-0030 step 16 δ: audio gate listen helper (= 10 wav 順次再生 + sleep 3 interval + 無限繰り返し) ==="
echo "判定軸:"
echo "  - K-BD  ≒ R-BD  (= K/R 同音)"
echo "  - K-SD  ≒ R-SD  (= K/R 同音)"
echo "  - K-HH  ≒ R-HH  (= K/R 同音)"
echo "  - K-CYM ≒ R-CYM (= K/R 同音、 Step 15 既存)"
echo "  - K-TOM ≒ R-TOM (= K/R 同音、 Step 16 新規)"
echo "  - BD ≠ SD ≠ HH ≠ CYM ≠ TOM (= 5 drum 種で聴感的区別可能)"
echo "  - FM 同居許容 (= Step 12/13/14/15 規律踏襲)"
echo
echo "Ctrl+C で停止"
echo

trap 'echo; echo "=== 停止 (Ctrl+C) === audio gate 判定をお願いします。"; exit 0' INT

LOOP=1
while true; do
    echo "--- ループ $LOOP 周目 ---"
    for entry in "${WAVS[@]}"; do
        label="${entry%%|*}"
        path="${entry##*|}"
        echo "[$label] $path"
        afplay "$path"
        echo "  (sleep 3)"
        sleep 3
    done
    echo
    LOOP=$((LOOP+1))
done
