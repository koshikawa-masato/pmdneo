#!/usr/bin/env bash
#
# PMDNEO 軸 B production-ready roadmap ② γ verify gate (= ADR-0058 v2 song parse + dispatch wiring)
#
# verify scope: ADR-0058 γ で並設した v2 PartWork compact slot 経由の song parse + dispatch wiring が
#   trace で確認できることを γ-1〜γ-6 で検証。 driver 既存 routine は不可触。
#
#   γ-1: song parse proof        — slot 0 (= 0xFD79) + slot 1 (= 0xFD85) ADDR への
#                                  z80-mem-trace write 観測 >= 1 件
#   γ-2: dispatch wiring proof   — γ fixture build trace で song-driven FM keyon 件数 +
#                                  fnum write value set が roadmap ① 固定 table と異なる
#   γ-3: LEN set proof           — z80-mem-trace で slot 0 LEN (= 0xFD7B) または
#                                  slot 1 LEN (= 0xFD87) への write 観測 >= 1 件 (= 値 != 0)
#   γ-4: baseline regression     — verify-axis-b-fm-ssg-real-sound.sh transitively PASS
#   γ-5: .org overflow なし       — 新 14 routine label addr >= 0x0610 + 0x0066 max < 0x0100
#   γ-6: production byte-identical — TEST_MODE_V2_SONG_FIXTURE=0 で新 routine 全 assemble なし +
#                                    nmi_cmd_7_play_song_v2 body byte が β 直後 (= call pmdneo_v2_entry_skeleton) と等価
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-song-parse.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_GAMMA="/tmp/v2-song-ymfm.tsv"
ZMEM_GAMMA="/tmp/v2-song-zmem.tsv"
LST_PROD="/tmp/v2-song-prod.lst"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# γ fixture build (= ym2610) + MAME headless trace
# ============================================================
echo "=== γ fixture build (= TEST_MODE_V2_SONG_FIXTURE=1, ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  γ fixture build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "NG  .lst 未生成"; exit 1; }

bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成"; exit 1; }
[ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 未生成"; exit 1; }
cp "$YMFM" "$YMFM_GAMMA"
cp "$ZMEM" "$ZMEM_GAMMA"

# --- γ-5: .org overflow check (= 14 routine + 0x0066 max) ---
G5BAD=0
G5DET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G5BAD=$((G5BAD + 1)); G5DET="$G5DET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST" | sort | tail -1)
if [ "$G5BAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "γ-5: 新 14 routine 全 >= 0x0610 + 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow なし)"
else
  ng "γ-5: .org overflow (routine_bad=${G5BAD} max0066=0x${MAX0066:-NONE}${G5DET})"
fi

# ============================================================
# γ-1: song parse proof = slot 0 (= 0xFD79) + slot 1 (= 0xFD85) ADDR write 観測
# ============================================================
# z80-mem-trace format: column 3 = addr (= 4 hex)、 column 4 = value (= 2 hex)
# slot 0 ADDR lo = 0xFD79、 hi = 0xFD7A、 slot 1 ADDR lo = 0xFD85、 hi = 0xFD86
SLOT0_ADDR=$(awk -F'\t' '$3=="FD79" || $3=="FD7A"' "$ZMEM_GAMMA" | wc -l | tr -d ' ')
SLOT1_ADDR=$(awk -F'\t' '$3=="FD85" || $3=="FD86"' "$ZMEM_GAMMA" | wc -l | tr -d ' ')
if [ "$SLOT0_ADDR" -ge 1 ] && [ "$SLOT1_ADDR" -ge 1 ]; then
  ok "γ-1: song parse proof = slot 0 ADDR (= 0xFD79/0xFD7A) write ${SLOT0_ADDR} + slot 1 ADDR (= 0xFD85/0xFD86) write ${SLOT1_ADDR}"
else
  ng "γ-1: song parse proof 不成立 (slot0_addr=${SLOT0_ADDR} 期待 >= 1 / slot1_addr=${SLOT1_ADDR} 期待 >= 1)"
fi

# ============================================================
# γ-3: LEN set proof = slot 0 LEN (= 0xFD7B) または slot 1 LEN (= 0xFD87) への write (= 値 != 0)
# ============================================================
# init で LEN=0 が書かれ、 part_note dispatch 後に LEN=0x10 が書かれる。 dispatch 経路通過 proof。
SLOT0_LEN_NONZERO=$(awk -F'\t' '$3=="FD7B" && $4!="00"' "$ZMEM_GAMMA" | wc -l | tr -d ' ')
SLOT1_LEN_NONZERO=$(awk -F'\t' '$3=="FD87" && $4!="00"' "$ZMEM_GAMMA" | wc -l | tr -d ' ')
LEN_TOTAL=$((SLOT0_LEN_NONZERO + SLOT1_LEN_NONZERO))
if [ "$LEN_TOTAL" -ge 1 ]; then
  ok "γ-3: LEN set proof = slot 0 LEN (= 0xFD7B) nonzero ${SLOT0_LEN_NONZERO} + slot 1 LEN (= 0xFD87) nonzero ${SLOT1_LEN_NONZERO} (= dispatch 経路通過)"
else
  ng "γ-3: LEN set proof 不成立 (slot0_len=${SLOT0_LEN_NONZERO} slot1_len=${SLOT1_LEN_NONZERO}、 dispatch 経路未通過)"
fi

# ============================================================
# γ-2: dispatch wiring proof = song-driven fnum + keyon (= roadmap ① 固定 table と区別)
# ============================================================
# γ song fixture note byte = 0x42/0x45/0x48 (= fnum 値 != roadmap ① 0x40/0x44/0x47 由来)。
# 但し γ では nmi_cmd_5 末尾の song_entry call で 1 回のみ dispatch (= IRQ なし)。
# slot 0 (= FM ch B) の最初の note = 0x42 → fnumset_fm で reg 0xA1 (= block+fnum hi) / 0xA5 (= fnum lo) write。
# slot 1 (= SSG ch G) の最初の note = 0x42 → fnumset_ssg で reg 0x00/0x01 (= ch G tone period) write。
# slot 0 (= FM ch B) keyon = reg 0x28 で 0xF1 (= ch B all-op keyon)、 1 件期待。
# slot 1 (= SSG ch G) volume = ssg_keyon で reg 0x08 <- 0x0F、 1 件期待。
FM_CHB_KEYON=$(awk -F'\t' '$2=="A" && $3=="28" && $4=="F1"' "$YMFM_GAMMA" | wc -l | tr -d ' ')
SSG_CHG_VOL=$(awk -F'\t' '$2=="A" && $3=="08" && $4=="0F"' "$YMFM_GAMMA" | wc -l | tr -d ' ')

# --- γ-2 literal value gate (= Codex layer 2 review revise = 件数のみではなく note→register 変換の literal proof、
# clean CI false PASS risk 解消のため roadmap ① ref trace を本 script 内で必須生成) ---
# fnumset_fm は note byte (= OCT<<4|ONKAI) を fnum/block に変換し reg 0xA4系 (high) と 0xA0系 (low) に write する。
# fixture note 0x42 (= OCT=4 ONKAI=2 = D4 相当) → fnum/block 値は roadmap ① 固定 note 0x44 (= OCT=4 ONKAI=4 = E4) と異なる literal 値になる。
# 本 gate では roadmap ① V2 entry build trace を本 script 内で再生成し、 γ trace との set 比較で song-driven literal value proof。
# 比較 file 不在を許容 (= noref fallback) すると clean CI 単独実行で false PASS リスクのため必須化。
FM_CHB_FNUM_GAMMA=$(awk -F'\t' '$2=="A" && ($3=="A1" || $3=="A5") {print $3"="$4}' "$YMFM_GAMMA" | sort -u)

# --- roadmap ① ref trace inline 生成 (= TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml + ym2610) ---
echo "=== roadmap ① ref trace 生成 (= γ-2 literal value 比較 ref、 本 script 内 build + MAME 必須) ==="
YMFM_ROADMAP1_REF="/tmp/v2-song-parse-roadmap1-ref-ymfm.tsv"
rm -f "$PREPROCESSED"
PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || ng "γ-2: roadmap ① ref build FAIL"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
if [ -f "$YMFM" ]; then
  cp "$YMFM" "$YMFM_ROADMAP1_REF"
else
  ng "γ-2: roadmap ① ref ymfm-trace 未生成"
fi

# γ trace の FM ch B fnum write set と roadmap ① ref set を literal 比較
LITERAL_VALUE_PROOF=""
if [ -f "$YMFM_ROADMAP1_REF" ]; then
  FM_CHB_FNUM_ROADMAP1=$(awk -F'\t' '$2=="A" && ($3=="A1" || $3=="A5") {print $3"="$4}' "$YMFM_ROADMAP1_REF" | sort -u)
  # set が完全一致なら song-driven proof 不成立 (= 同 note table を引いている、 wiring 効いていない)
  # γ set 非空 + set != ref → song-driven literal value proof OK
  if [ -n "$FM_CHB_FNUM_GAMMA" ] && [ "$FM_CHB_FNUM_GAMMA" != "$FM_CHB_FNUM_ROADMAP1" ]; then
    LITERAL_VALUE_PROOF="ok"
  fi
fi

# γ では note 0x42 1 回 + 0x45 (= LEN dispatch なし、 単発)、 但し song_entry は init+dispatch 1 回 = 最初の note のみ
# (= LEN=0 で part_parse 即時実行 → note 0x42 で fnumset + LEN=0x10 set + ret = 後続 note 進行なし、 1 dispatch のみ)。
# expected: γ では FM ch B keyon >= 1 (= song-driven dispatch 1 回) + SSG ch G volume 0x0F >= 1 + literal value proof
if [ "$FM_CHB_KEYON" -ge 1 ] && [ "$SSG_CHG_VOL" -ge 1 ] && [ "$LITERAL_VALUE_PROOF" = "ok" ]; then
  ok "γ-2: dispatch wiring proof = song-driven FM ch B keyon (reg 0x28 <- 0xF1) ${FM_CHB_KEYON} + SSG ch G volume (reg 0x08 <- 0x0F) ${SSG_CHG_VOL} + FM ch B fnum write value set が roadmap ① ref と異 (= song-driven literal value proof、 ref file = $YMFM_ROADMAP1_REF)"
else
  ng "γ-2: dispatch wiring proof 不成立 (FM ch B keyon=${FM_CHB_KEYON} 期待 >= 1 / SSG ch G volume=${SSG_CHG_VOL} 期待 >= 1 / literal value proof=${LITERAL_VALUE_PROOF:-fail = γ set と roadmap ① ref set が一致 or ref 不在})"
fi

# γ trace 復帰 (= γ-6 production build 復帰の前段で γ trace を再生成しないため不要、 LST/YMFM は次 step まで γ build のもの)
# 但し γ-6 production build は LST 上書きするため LST_PROD で退避する既存設計を維持。 ここでは特に追加処理不要。

# ============================================================
# γ-6: production build byte-identical = TEST_MODE_V2_SONG_FIXTURE=0 で新 routine 全 assemble なし
# ============================================================
echo "=== γ-6: production build (= TEST_MODE_V2_SONG_FIXTURE=0) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build FAIL"; exit 1; }
cp "$LST" "$LST_PROD"

# production .lst で新 14 routine の addr column が 6-hex でない (= assemble されていない) ことを assert
G6BAD=0
G6DET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_PROD")
  if [ -n "$addr" ]; then
    G6BAD=$((G6BAD + 1)); G6DET="$G6DET ${label}=0x${addr}(assembled)"
  fi
done

# nmi_cmd_7_play_song_v2 body の assembled byte 列が `CD ?? ??` (= call pmdneo_v2_entry_skeleton) と
# `C3 ?? ??` (= jp nmi_done) であることを assert (= .else block のみ assemble = β 直後 byte と等価)
NMI7_CALL=$(awk '
  /nmi_cmd_7_play_song_v2:/{flag=1; next}
  flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^CD$/ {print "ok"; exit}
  flag && /jp.*nmi_done/{exit}
' "$LST_PROD")
NMI7_JP=$(awk '
  /nmi_cmd_7_play_song_v2:/{flag=1; next}
  flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^C3$/ {print "ok"; exit}
' "$LST_PROD")

if [ "$G6BAD" -eq 0 ] && [ "$NMI7_CALL" = "ok" ] && [ "$NMI7_JP" = "ok" ]; then
  ok "γ-6: production byte-identical = 新 14 routine 全 assemble なし + nmi_cmd_7_play_song_v2 body = CD (call) + C3 (jp) (= .else block のみ assemble = β 直後 byte と等価)"
else
  ng "γ-6: production byte-identical 不成立 (assembled_routine_bad=${G6BAD}${G6DET} nmi7_call=${NMI7_CALL:-none} nmi7_jp=${NMI7_JP:-none})"
fi

# ============================================================
# γ-4: baseline regression = verify-axis-b-fm-ssg-real-sound.sh transitively
# ============================================================
echo "=== γ-4: baseline regression (= verify-axis-b-fm-ssg-real-sound.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-fm-ssg-real-sound.sh >/dev/null 2>&1; then
  ok "γ-4: baseline regression = verify-axis-b-fm-ssg-real-sound.sh 6 gate 全 PASS (= ADR-0049〜0057 transitively regression)"
else
  ng "γ-4: baseline regression FAIL"
fi

# ============================================================
# production build 復帰 + 集計
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "OK  ALL PASS (= 軸 B production-ready roadmap ② γ = v2 song parse + dispatch wiring 6 gate 全 PASS)"
  exit 0
else
  echo "NG  $FAIL gate FAIL"
  exit 1
fi
