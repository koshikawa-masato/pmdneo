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

# ADR-0021 step 7 β-2: .PNE → ngdevkit 入力 converter 実行 (= path B / c1)
# 関連: docs/design/pne_binary_layout.md §6 / ADR-0021 §決定 5
echo "=== .PNE → samples-map-adpcma.yaml + .adpcma 抽出 (= path B / c1 converter) ==="
PNE_FILE="${PMDNEO_PNE:-$PMDNEO_ROOT/assets/pne/PMDNEO01.PNE}"
if [ ! -f "$PNE_FILE" ]; then
    echo "ERROR: .PNE file が見つからない: $PNE_FILE" >&2
    echo "  scripts/pne-pack-prototype.py で bootstrap してください" >&2
    exit 1
fi
python3 "$PMDNEO_ROOT/scripts/pne-to-ngdevkit.py" "$PNE_FILE" \
    --output-dir "$TEMPLATE_DIR/assets" > /dev/null
echo "  source: $PNE_FILE"
echo "  generated: samples-map-adpcma.yaml + {bd,sd,hh,rim,tom,top}.adpcma"

# ADR-0021 step 7 β-2: ADPCM-B passthrough yaml 配置 (= c1 採用、 hand-written retained)
echo "=== ADPCM-B passthrough yaml を配置 (= c1 採用、 hand-written) ==="
cp "$PMDNEO_ROOT/assets/pne/samples-map-adpcmb.yaml" "$TEMPLATE_DIR/assets/samples-map-adpcmb.yaml"
echo "  samples-map-adpcmb.yaml <- assets/pne/samples-map-adpcmb.yaml"

# ADR-0048 §決定 8 案 C: 軸 G .PPC → ngdevkit 入力 (= directory bin + adpcm_b blob + yaml + symbols)
# PMDNEO_PPC env で .PPC file path 指定 (= default は src/test-fixtures/axis-g/minimum.PPC)。
# generator は scripts/ppc-to-ngdevkit.py (= 35th session vromtool finding 反映、 vromtool 外側)。
# 軸 G 経路は sample_table_id bit7 set 時のみ driver runtime で走るため、 unconditional に
# build pipeline に組み込んでも既存 fixture (= bit7 clear) の byte-identical は維持される。
echo "=== ADR-0048 §決定 8 案 C: .PPC → ngdevkit 入力 (= generator scripts/ppc-to-ngdevkit.py) ==="
PMDNEO_PPC="${PMDNEO_PPC:-$PMDNEO_ROOT/src/test-fixtures/axis-g/minimum.PPC}"
if [ ! -f "$PMDNEO_PPC" ]; then
    echo "ERROR: .PPC file が見つからない: $PMDNEO_PPC" >&2
    echo "  scripts/ppc-to-ngdevkit.py --emit-fixture で生成可能" >&2
    exit 2
fi
python3 "$PMDNEO_ROOT/scripts/ppc-to-ngdevkit.py" \
    --input "$PMDNEO_PPC" \
    --output-dir "$TEMPLATE_DIR/assets" > /dev/null
echo "  source: $PMDNEO_PPC"
echo "  generated: assets/ppc_directory.bin (1024 byte) + assets/ppc_pcm_blob.adpcm_b + assets/ppc_symbols.inc"
# 既存 samples-map-adpcmb.yaml に軸 G blob entry を merge (= vromtool は 1 yaml/型 受領)
cat "$TEMPLATE_DIR/assets/samples-map-adpcmb-ppc.yaml" >> "$TEMPLATE_DIR/assets/samples-map-adpcmb.yaml"
echo "  samples-map-adpcmb.yaml <- 既存 + samples-map-adpcmb-ppc.yaml (= merge cp)"

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
    # ADR-0016 step V-1: pmddotnet_song.inc に分離 (= PMDNEO.s build top 経路で
    # song_data.inc を引き込まないため、 専用 .inc に独立配置)。 また互換のため
    # song_data.inc にも引き続き追記 (= standalone_test.s build top の旧経路用、
    # legacy 残置)。
    {
        echo ";; ADR-0016 step 3c-1 / V-1: raw .M を .incbin 経路で取り込み (= PMDDOTNET 未経由)"
        echo "pmddotnet_song: .incbin \"pmddotnet_song.m\""
    } > "$TEMPLATE_DIR/pmddotnet_song.inc"
    {
        echo ""
        echo ";; ADR-0016 step 3c-1: raw .M を .incbin 経路で取り込み (= PMDDOTNET 未経由、 legacy)"
        echo "pmddotnet_song: .incbin \"pmddotnet_song.m\""
    } >> "$TEMPLATE_DIR/song_data.inc"
    echo "  pmddotnet_song.m <- $(basename "$PMDNEO_M_RAW") ($(wc -c < "$TEMPLATE_DIR/pmddotnet_song.m" | tr -d ' ') byte)"
    echo "  pmddotnet_song.inc (= PMDNEO.s 用 .incbin wrapper) 生成"
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

    # ADR-0072 plan v7 build-side voice resolution (= MF-3 Option B):
    # PMDDotNET .M binary に voice table inline emit されない (= γ impl phase finding)
    # ため compile.py --voice-only で MML 内 voice 定義 + #FFFile 外部 voice file を抽出
    # + voice_table_pmddotnet.inc 生成 + song_data.inc の既存 empty `voice_table:` block 削除
    # + 新 voice_table_pmddotnet.inc を append。
    # driver source 完全 no-touch、 production sha256 invariant 維持 (= flag-off で
    # 本 block 実行されない = byte-identical)。
    echo
    echo "=== ADR-0072 plan v7: build-side voice resolution (= #FFFile support) ==="
    python3 "$PMDNEO_ROOT/src/tools/pmd-mml/compile.py" --voice-only \
        --output-voice-table "$TEMPLATE_DIR/voice_table_pmddotnet.inc" \
        "$PMDDOTNET_MML"
    if [[ ! -f "$TEMPLATE_DIR/voice_table_pmddotnet.inc" ]]; then
        echo "ERROR: voice_table_pmddotnet.inc 生成失敗" >&2
        exit 2
    fi
    # song_data.inc 内の既存 empty `voice_table:` block を削除 (= 末尾までを一旦削除)
    # macOS BSD sed + GNU sed 両対応の portable invocation (= `-i.bak` + 後で .bak 削除)
    sed -i.bak '/^voice_table:$/,$d' "$TEMPLATE_DIR/song_data.inc"
    rm -f "$TEMPLATE_DIR/song_data.inc.bak"
    # pmddotnet_song line + generated voice_table を再度 append (= 順序は pmddotnet_song 先 → voice_table 後)
    {
        echo ""
        echo ";; ADR-0016 step 3b carry: PMDDotNET .M binary incbin"
        echo "pmddotnet_song: .incbin \"pmddotnet_song.m\""
        echo ""
        echo ";; ADR-0072 plan v7: build-side voice resolution generated (= compile.py --voice-only)"
        cat "$TEMPLATE_DIR/voice_table_pmddotnet.inc"
    } >> "$TEMPLATE_DIR/song_data.inc"
    echo "  voice_table_pmddotnet.inc <- compile.py --voice-only (MML inline + #FFFile)"
fi

echo
echo "=== make poc ==="
# ADR-0016 step W-3 補正 (= 2026-05-12): V-1 で PMDNEO.s build top に切替えたが、
# nullsound integration 未完成と判明。 build top を standalone_test.s に戻す。
# PMDNEO.s + IRQ.inc + PMD_Z80.inc + ADPCMB_DRV.inc 系は legacy として retain、
# 将来 nullsound integration sprint で完成させる予定。
# PMDNEO_USE_PMDDOTNET env は維持 (= standalone_test.s でも sed pre-process で
# .equ 切替できるよう standalone_test.s に .equ PMDNEO_USE_PMDDOTNET 0 を残置)。
# ただし standalone_test.s 内では pmddotnet_song label 参照経路は未整備、 V-1/W-1
# 以前と同じ動作に戻る (= song_table 経由の自前 compile.py 経路)。
### PMDNEO_NO_FADE: audition harness 分離 flag (= main.c harness 側、 driver 非改修)。
### =1 で main.c が cmd 6 fade trigger を送らない (= tone-ladder audition、 fade なし全長再生)。
### `-W main.c` = CFLAGS 変更 (= PMDNEO_NO_FADE / PMDNEO_FIXTURE 等) を main.o rebuild に
### 確実に反映させる (= make は CFLAGS 変化を timestamp 追跡しないため)。
make PMDNEO_CHIP="$PMDNEO_CHIP" PMDNEO_USE_PMDDOTNET="${PMDNEO_USE_PMDDOTNET:-0}" TEST_MODE_AXIS_G_INT="${PMDNEO_AXIS_G_INT:-0}" TEST_MODE_AXIS_G_V2_PPC="${PMDNEO_AXIS_G_V2_PPC:-0}" TEST_MODE_AXIS_G_AUDITION_REVISE="${PMDNEO_AXIS_G_AUDITION_REVISE:-0}" TEST_MODE_AXIS_G_AUDITION_MUTE_FM_B="${PMDNEO_AXIS_G_AUDITION_MUTE_FM_B:-0}" TEST_MODE_AXIS_G_AUDITION_MUTE_SSG_G="${PMDNEO_AXIS_G_AUDITION_MUTE_SSG_G:-0}" TEST_MODE_AXIS_G_AUDITION_MUTE_ADPCMB="${PMDNEO_AXIS_G_AUDITION_MUTE_ADPCMB:-0}" TEST_MODE_AXIS_G_AUDITION_MUTE_RHYTHM="${PMDNEO_AXIS_G_AUDITION_MUTE_RHYTHM:-0}" TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP="${PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP:-0}" TEST_MODE_MUTE_FIXTURE="${PMDNEO_MUTE_FIXTURE:-0}" TEST_MODE_FADE_FIXTURE="${PMDNEO_FADE_FIXTURE:-0}" TEST_MODE_V2_ENTRY_FIXTURE="${PMDNEO_V2_ENTRY_FIXTURE:-0}" TEST_MODE_V2_SONG_FIXTURE="${PMDNEO_V2_SONG_FIXTURE:-0}" PMDNEO_NO_FADE="${PMDNEO_NO_FADE:-0}" STANDALONE_Z80_SRC=standalone_test.s -W standalone_test.s -W main.c poc

echo
echo "=== build 完了 ==="
echo "起動確認:"
echo "  cd $TEMPLATE_DIR && make gngeo"
