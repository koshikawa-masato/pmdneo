#!/bin/bash
#
# PMDNEO Phase 1 PoC ビルド script
#
# 動作:
#   1. src/driver/ の Z80 source (.s / .inc) を vendor/ngdevkit-examples/00-template/ に symlink
#   2. cd vendor/ngdevkit-examples/00-template && make
#
# 前提:
#   - ngdevkit + ngdevkit-gngeo が install 済 (brew install ngdevkit ngdevkit-gngeo)
#   - vendor/ngdevkit-examples で `./configure` 実行済 (= config.mk + build.mk + emu.mk 生成済)
#   - ~/Downloads/neogeo.zip (NEOGEO 純正 BIOS romset) が用意済 (起動確認時)
#
# 使用例:
#   bash scripts/build-poc.sh                  # build のみ (= chip=ym2610 default)
#   bash scripts/build-poc.sh --chip ym2610b   # AES+ YM2610B 想定 build (= ADR-0006 §4)
#   bash scripts/build-poc.sh && cd vendor/ngdevkit-examples/00-template && make gngeo  # build + 起動
#
# option:
#   --chip ym2610|ym2610b   PMDNEO target chip (= default ym2610、 ADR-0006 §B/§4)
#                           env PMDNEO_CHIP でも指定可、 option 優先

set -euo pipefail

PMDNEO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRIVER_SRC="$PMDNEO_ROOT/src/driver"
TEMPLATE_DIR="$PMDNEO_ROOT/vendor/ngdevkit-examples/00-template"

# ADR-0006 §4: chip target (= driver standalone_test.s:32 の .equ を build 時 override)
PMDNEO_CHIP="${PMDNEO_CHIP:-ym2610}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --chip) PMDNEO_CHIP="$2"; shift 2 ;;
        -h|--help) sed -n '3,21p' "$0"; exit 0 ;;
        *) echo "ERROR: Unknown option: $1" >&2; exit 2 ;;
    esac
done

case "$PMDNEO_CHIP" in
    ym2610|ym2610b) ;;
    *) echo "ERROR: --chip must be ym2610 or ym2610b (got: $PMDNEO_CHIP)" >&2; exit 2 ;;
esac
export PMDNEO_CHIP
echo "=== PMDNEO_CHIP=$PMDNEO_CHIP (= ADR-0006 §4 chip target) ==="

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "ERROR: $TEMPLATE_DIR が見つかりません。 vendor/ngdevkit-examples を取り込み済か確認してください。"
    exit 1
fi

if [ ! -f "$TEMPLATE_DIR/build.mk" ]; then
    echo "ERROR: $TEMPLATE_DIR/build.mk がありません。"
    echo "vendor/ngdevkit-examples で autoreconf + ./configure を実行してください:"
    echo "  cd $PMDNEO_ROOT/vendor/ngdevkit-examples && autoreconf -i && ./configure"
    exit 1
fi

# 00-template には configure で config.mk が rsync されない (= 00-template は rsync source)
# 親の vendor/ngdevkit-examples/config.mk を symlink で参照
if [ ! -f "$PMDNEO_ROOT/vendor/ngdevkit-examples/config.mk" ]; then
    echo "ERROR: $PMDNEO_ROOT/vendor/ngdevkit-examples/config.mk がありません。"
    echo "./configure を実行してください。"
    exit 1
fi

echo "=== config.mk を 00-template/ に symlink ==="
ln -sfn "../config.mk" "$TEMPLATE_DIR/config.mk"

echo "=== src/driver/ の Z80 source を 00-template/ に symlink ==="
cd "$TEMPLATE_DIR"
for f in "$DRIVER_SRC"/*.s "$DRIVER_SRC"/*.inc; do
    base=$(basename "$f")
    if [ "$base" = "standalone_test.s" ]; then
        echo "  $base (kept local for generated song_data.inc include)"
        continue
    fi
    ln -sfn "../../../src/driver/$base" "$base"
    echo "  $base -> ../../../src/driver/$base"
done

echo "=== SAMPLE.M を sdasz80 用 .db source に変換 ==="
python3 "$PMDNEO_ROOT/scripts/bin2db.py" \
    "$PMDNEO_ROOT/vendor/pmd48s/SAMPLE.M" \
    "$TEMPLATE_DIR/sample_m.s" \
    "sample_m_data"
echo "  sample_m.s <- vendor/pmd48s/SAMPLE.M"

echo "=== compile.py: MML → .mn parts + song_data.inc wrapper ==="
# MML_INPUTS 環境変数で fixture 群を切替 (= default test01.mml + test02.mml)。
# 互換: 旧 MML_INPUT のみ指定された場合は単一入力として扱う。
MML_INPUTS="${MML_INPUTS:-${MML_INPUT:-test01.mml,test02.mml}}"
echo "    MML_INPUTS: ${MML_INPUTS}"
IFS=',' read -r -a MML_INPUT_ARRAY <<< "$MML_INPUTS"
MML_INPUT_PATHS=()
for mml_input in "${MML_INPUT_ARRAY[@]}"; do
    if [[ "$mml_input" = /* ]]; then
        input_path="$mml_input"
    else
        input_path="${PMDNEO_ROOT}/src/tools/pmd-mml/${mml_input}"
    fi
    MML_INPUT_PATHS+=("$input_path")
    input_base=$(basename "$mml_input")
    song_name="${input_base%.*}"
    mkdir -p "${TEMPLATE_DIR}/songs/${song_name}"
done
python3 "${PMDNEO_ROOT}/src/tools/pmd-mml/compile.py" \
    "${MML_INPUT_PATHS[@]}" \
    --out-dir "${TEMPLATE_DIR}/songs" \
    --wrapper "${TEMPLATE_DIR}/song_data.inc"

# ADR-0016 step 3c-1: raw .M 直接取り込み経路 (= PMDDOTNET 未経由)
# 環境変数 PMDNEO_M_RAW が設定されていれば、 指定された .M / .MN binary を
# そのまま pmddotnet_song.m に copy + song_data.inc に追記。 改造 PMDDotNET
# 経由ではなく、 既存 SAMPLE.M 等の任意 binary を取り込み経路でテスト可能に。
# PMDDOTNET_MML と排他 (= PMDNEO_M_RAW 優先)。 driver / standalone_test.s 不可侵。
if [[ -n "${PMDNEO_M_RAW:-}" ]]; then
    if [[ ! -f "$PMDNEO_M_RAW" ]]; then
        echo "ERROR: PMDNEO_M_RAW file が見つからない: $PMDNEO_M_RAW" >&2
        exit 2
    fi
    echo
    echo "=== ADR-0016 step 3c-1: raw .M 直接取り込み (PMDNEO_M_RAW=$(basename "$PMDNEO_M_RAW")) ==="
    python3 "$PMDNEO_ROOT/scripts/m-to-z80-incbin.py" \
        "$PMDNEO_M_RAW" "$TEMPLATE_DIR/pmddotnet_song.m" \
        --label pmddotnet_song
    {
        echo ""
        echo ";; ADR-0016 step 3c-1: raw .M を .incbin 経路で取り込み (= PMDDOTNET 未経由)"
        echo "pmddotnet_song: .incbin \"pmddotnet_song.m\""
    } >> "$TEMPLATE_DIR/song_data.inc"
    echo "  pmddotnet_song.m <- $(basename "$PMDNEO_M_RAW") ($(wc -c < "$TEMPLATE_DIR/pmddotnet_song.m" | tr -d ' ') byte)"
fi

# ADR-0016 step 3b: 改造 PMDDotNET 経路 (= 並走、 既存 compile.py 経路と共存)
# 環境変数 PMDDOTNET_MML が設定されていれば、 改造 PMDDotNET dotnet で .M / .MN
# compile + 00-template/pmddotnet_song.m に配置 + song_data.inc に追記 1 行で取り込み。
# 未設定なら従来 (= 自前 compile.py 経路のみ) で完全不変。
# driver source / standalone_test.s は touch せず、 既存 song_table 維持。
if [[ -n "${PMDDOTNET_MML:-}" ]]; then
    PMDDOTNET_MODE="${PMDDOTNET_MODE:-N}"    # N (= /N、 default) or B (= /B、 ADPCM-A 経路)
    PMDDOTNET_DLL="${PMDDOTNET_DLL:-$PMDNEO_ROOT/vendor/PMDDotNET/PMDDotNETConsole/bin/Release/net6.0/PMDDotNETConsole.dll}"
    if [[ ! -f "$PMDDOTNET_DLL" ]]; then
        echo "ERROR: PMDDotNETConsole dll が見つからない: $PMDDOTNET_DLL" >&2
        echo "  vendor/PMDDotNET/PMDDotNETConsole を dotnet build -c Release してください" >&2
        exit 2
    fi
    if [[ ! -f "$PMDDOTNET_MML" ]]; then
        echo "ERROR: PMDDOTNET_MML file が見つからない: $PMDDOTNET_MML" >&2
        exit 2
    fi
    echo
    echo "=== ADR-0016 step 3b: 改造 PMDDotNET 経路 (PMDDOTNET_MML=$(basename "$PMDDOTNET_MML") /$PMDDOTNET_MODE) ==="
    # macOS 絶対 path bug 回避 (= memory project_adr_0016_step1_findings.md §3) — cd で working dir 移動 + 相対 path
    PMDDOTNET_TMPDIR=$(mktemp -d "/tmp/pmdneo-pmddotnet-XXXXXX")
    cp "$PMDDOTNET_MML" "$PMDDOTNET_TMPDIR/"
    PMDDOTNET_MML_BASE=$(basename "$PMDDOTNET_MML")
    (cd "$PMDDOTNET_TMPDIR" && dotnet "$PMDDOTNET_DLL" /C "/$PMDDOTNET_MODE" "$PMDDOTNET_MML_BASE" > pmddotnet.log 2>&1)
    # 出力 .M / .MN を探す (= /N → .M、 /B + ADPCM-A 未使用 → .M、 /B + ADPCM-A 使用 → .MN)
    PMDDOTNET_OUT=$(find "$PMDDOTNET_TMPDIR" -maxdepth 1 \( -name "*.M" -o -name "*.MN" \) | head -1)
    if [[ -z "$PMDDOTNET_OUT" ]]; then
        echo "ERROR: PMDDotNET compile failed — .M / .MN not generated" >&2
        echo "  log: $PMDDOTNET_TMPDIR/pmddotnet.log" >&2
        cat "$PMDDOTNET_TMPDIR/pmddotnet.log" >&2
        exit 2
    fi
    python3 "$PMDNEO_ROOT/scripts/m-to-z80-incbin.py" \
        "$PMDDOTNET_OUT" "$TEMPLATE_DIR/pmddotnet_song.m" \
        --label pmddotnet_song
    # song_data.inc 末尾に追記 (= 既存 song_table 不変、 新規 label のみ追加)
    {
        echo ""
        echo ";; ADR-0016 step 3b: 改造 PMDDotNET 経路で取り込んだ .M / .MN (= driver 解釈は 3c で実装)"
        echo "pmddotnet_song: .incbin \"pmddotnet_song.m\""
    } >> "$TEMPLATE_DIR/song_data.inc"
    echo "  pmddotnet_song.m <- $(basename "$PMDDOTNET_OUT") ($(wc -c < "$TEMPLATE_DIR/pmddotnet_song.m" | tr -d ' ') byte)"
    rm -rf "$PMDDOTNET_TMPDIR"
fi

echo
echo "=== make poc ==="
# ADR-0016 step 3c-2: PMDNEO_USE_PMDDOTNET env を make に伝搬 (= pmdneo_load_m の
# 入力 label を sample_m_data / pmddotnet_song で切替、 sed pre-process 経由)
make PMDNEO_CHIP="$PMDNEO_CHIP" PMDNEO_USE_PMDDOTNET="${PMDNEO_USE_PMDDOTNET:-0}" STANDALONE_Z80_SRC=standalone_test.s -W standalone_test.s poc

echo
echo "=== build 完了 ==="
echo "起動確認:"
echo "  cd $TEMPLATE_DIR && make gngeo"
