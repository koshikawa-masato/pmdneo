#!/usr/bin/env bash
#
# PMDNEO 軸 B production-ready roadmap ② ε verify script 体系化
# (= ADR-0058 v2 driver production-ready roadmap ② completion proof)
#
# verify scope: §決定 6 primary 6 gate (= roadmap2-gate-1〜6) +
#   supplemental 4 gate (= sup-IX/IY / sup-TIMER-B / sup-γ-pattern / sup-cold-boot) +
#   末尾 completion proof line (= ζ Accepted 移行 ready signal) を 1 verify script に統合。
#
#   roadmap2-gate-1 (v2 song parse):
#       z80-mem-trace で slot 0 ADDR lo (= 0xFD79) uniq value >= 3 AND
#       slot 0 LEN (= 0xFD7B) uniq value >= 3
#       (= init-only false PASS 排除 + IRQ tick による decrement + fixture byte advance proof)
#
#   roadmap2-gate-2 (v2 dispatch wiring):
#       song-driven FM ch B keyon (reg 0x28 <- 0xF1) >= 1 +
#       SSG ch G volume (reg 0x08 <- 0x0F) >= 1 +
#       FM ch B fnum write (reg 0xA1/0xA5) value set != roadmap ① ref set かつ γ set 非空。
#       ref trace = TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml + ym2610 を
#       本 script 内で必須生成 (= clean CI false PASS risk 解消)。
#
#   roadmap2-gate-3 (IRQ tick 駆動):
#       静的 .lst で irq_handler_body body 内 call pmdneo_v2_song_tick assembled +
#       z80-mem-trace で pmdneo_v2_tempo_acc (= 0xFD3F) write 件数 >= 2
#
#   roadmap2-gate-4 (tempo):
#       IRQ tick (= pmdneo_irq_count 0xF816 write 件数) > slot 0 LEN write 件数
#       (= tempo overflow gate 動作 proof = 全 IRQ で dispatch しない)
#
#   roadmap2-gate-5 (baseline regression):
#       bash src/test-fixtures/axis-b/verify-axis-b-fm-ssg-real-sound.sh exit 0
#
#   roadmap2-gate-6 (.org + build-mode 排他):
#       (a) .org overflow なし: 15 routine 全 >= 0x0610 + 0x0066 セクション max addr < 0x0100
#       (b) production build (= TEST_MODE_V2_SONG_FIXTURE=0) .lst で
#           15 routine 全 assemble なし + IRQ body の call pmdneo_v2_song_tick 未 assemble +
#           cold init の ld (pmdneo_v2_song_state),a 未 assemble
#
#   sup-IX/IY:
#       静的 .lst で pmdneo_v2_song_tick 単一 epilogue 経由全 exit +
#       push ix + push iy (tick body) + pop iy + pop ix (tick_done body) pair
#
#   sup-TIMER-B:
#       z80-mem-trace で pmdneo_irq_count (= 0xF816) write 件数 >= 10 件
#       (= TIMER-B IRQ 実発火 / 古い「6 秒で 2 回」 finding stale 再確認)
#
#   sup-γ-pattern:
#       静的 .lst で pmdneo_v2_song_entry body 内 call pmdneo_v2_song_init 存在 +
#       call pmdneo_v2_song_dispatch 撤去 + ld (pmdneo_v2_song_state),a 存在
#
#   sup-cold-boot:
#       z80-mem-trace で 0xFD3E (= song_state) write >= 2 件 + 先頭 write 値 0 +
#       後続 write 値 1 + 静的 .lst で nmi_cmd_5_init_mml_song body + nmi_cmd_7_play_song_v2 body
#       両者に call pmdneo_v2_song_entry 存在
#
# 命名: ADR-0058 §決定 1 ε literal 推奨 `verify-axis-b-v2-song-playback.sh`。
#   ε で旧 `verify-axis-b-v2-song-parse.sh` (= γ 6 gate → δ 10 gate) を rename + 体系化。
#   Annex D (γ) / Annex E (δ) 本文の旧 path 表記は当時の literal 記録として維持、
#   ε 以降は本 script + Annex F rename 注記 を ground truth とする。
#
# driver touch なし (= ADR-0058 §決定 1 ε row literal)。
# ADR-0049〜0057 routine + 既存 cmd 0x05 + 軸 C/G/rhythm + vendor 完全不可触。
#
# usage: bash src/test-fixtures/axis-b/verify-axis-b-v2-song-playback.sh

set -euo pipefail
PMDNEO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$PMDNEO_ROOT"

TEMPLATE_BUILD="vendor/ngdevkit-examples/00-template/build"
PREPROCESSED="$TEMPLATE_BUILD/standalone_test.preprocessed.s"
LST="$TEMPLATE_BUILD/standalone_test.lst"
TRACE_DIR="/tmp/pmdneo-trace"
YMFM="$TRACE_DIR/ymfm-trace.tsv"
ZMEM="$TRACE_DIR/z80-mem-trace.tsv"

YMFM_PLAYBACK="/tmp/v2-song-playback-ymfm.tsv"
ZMEM_PLAYBACK="/tmp/v2-song-playback-zmem.tsv"
LST_PLAYBACK="/tmp/v2-song-playback.lst"
LST_PROD="/tmp/v2-song-playback-prod.lst"
YMFM_ROADMAP1_REF="/tmp/v2-song-playback-roadmap1-ref-ymfm.tsv"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# ε fixture build (= TEST_MODE_V2_SONG_FIXTURE=1, ym2610) + MAME headless trace
# ============================================================
echo "=== ε fixture build (= TEST_MODE_V2_SONG_FIXTURE=1, ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  ε fixture build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "NG  .lst 未生成"; exit 1; }
cp "$LST" "$LST_PLAYBACK"

# Codex layer 2 ε 実装 review revise = stale trace false PASS risk 解消:
# MAME 呼び出し前に trace dir を clean rm して、 MAME 失敗時に前回 trace が残らず literal 未生成判定可能化。
rm -rf "$TRACE_DIR"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成 (= MAME run 失敗 or trace 出力なし)"; exit 1; }
[ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 未生成 (= MAME run 失敗 or trace 出力なし)"; exit 1; }
cp "$YMFM" "$YMFM_PLAYBACK"
cp "$ZMEM" "$ZMEM_PLAYBACK"

# 共通 metric 事前計算 (= 複数 gate で参照)
IRQ_TICKS=$(awk -F'\t' '$3=="F816"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')
SLOT0_LEN_WRITES=$(awk -F'\t' '$3=="FD7B"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')

# ============================================================
# roadmap2-gate-1 (v2 song parse) = init-only false PASS 排除 + IRQ decrement + fixture byte advance proof
# ============================================================
SLOT0_ADDR_LO_UNIQ=$(awk -F'\t' '$3=="FD79" {print $4}' "$ZMEM_PLAYBACK" | sort -u | wc -l | tr -d ' ')
SLOT0_LEN_UNIQ=$(awk -F'\t' '$3=="FD7B" {print $4}' "$ZMEM_PLAYBACK" | sort -u | wc -l | tr -d ' ')
if [ "$SLOT0_ADDR_LO_UNIQ" -ge 3 ] && [ "$SLOT0_LEN_UNIQ" -ge 3 ]; then
  ok "roadmap2-gate-1 (v2 song parse): slot 0 ADDR lo (= 0xFD79) uniq value ${SLOT0_ADDR_LO_UNIQ} 件 (>= 3 期待 = init 1 + dispatch advance >= 2) + slot 0 LEN (= 0xFD7B) uniq value ${SLOT0_LEN_UNIQ} 件 (>= 3 期待 = LEN set + IRQ dec values) = init-only false PASS 排除 + IRQ tick による decrement + fixture byte advance proof"
else
  ng "roadmap2-gate-1 (v2 song parse) 不成立 (slot0_addr_lo_uniq=${SLOT0_ADDR_LO_UNIQ} 期待 >= 3 / slot0_len_uniq=${SLOT0_LEN_UNIQ} 期待 >= 3、 init-only false PASS 排除のため両 AND 必須)"
fi

# ============================================================
# roadmap2-gate-2 (v2 dispatch wiring) = song-driven keyon + ref 比較 literal value proof
# ============================================================
FM_CHB_KEYON=$(awk -F'\t' '$2=="A" && $3=="28" && $4=="F1"' "$YMFM_PLAYBACK" | wc -l | tr -d ' ')
SSG_CHG_VOL=$(awk -F'\t' '$2=="A" && $3=="08" && $4=="0F"' "$YMFM_PLAYBACK" | wc -l | tr -d ' ')
FM_CHB_FNUM_PLAYBACK=$(awk -F'\t' '$2=="A" && ($3=="A1" || $3=="A5") {print $3"="$4}' "$YMFM_PLAYBACK" | sort -u)

# --- roadmap ① ref trace inline 生成 (= TEST_MODE_V2_ENTRY_FIXTURE=1 + MML_INPUTS=ssg-v0-keyon.mml + ym2610) ---
# 比較 file 不在を許容 (= noref fallback) すると clean CI 単独実行で false PASS リスクのため必須化。
# ref build/trace 失敗時は ng() 一度のみ呼び出し (= FAIL+1 二重カウント回避)。
echo "=== roadmap ① ref trace 生成 (= roadmap2-gate-2 literal value 比較 ref、 本 script 内 build + MAME 必須) ==="
LITERAL_VALUE_PROOF=""
REF_BUILD_OK=""
rm -f "$PREPROCESSED"
if PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1; then
  # stale trace 排除 = MAME run 前に trace dir 強制 clean (= ε MAME run 由来の trace と区別)
  rm -rf "$TRACE_DIR"
  bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
  if [ -f "$YMFM" ]; then
    cp "$YMFM" "$YMFM_ROADMAP1_REF"
    REF_BUILD_OK="ok"
  fi
fi

if [ "$REF_BUILD_OK" = "ok" ]; then
  FM_CHB_FNUM_ROADMAP1=$(awk -F'\t' '$2=="A" && ($3=="A1" || $3=="A5") {print $3"="$4}' "$YMFM_ROADMAP1_REF" | sort -u)
  # set が完全一致なら song-driven proof 不成立 (= 同 note table を引いている、 wiring 効いていない)
  # ε set 非空 + set != ref → song-driven literal value proof OK
  if [ -n "$FM_CHB_FNUM_PLAYBACK" ] && [ "$FM_CHB_FNUM_PLAYBACK" != "$FM_CHB_FNUM_ROADMAP1" ]; then
    LITERAL_VALUE_PROOF="ok"
  fi
fi

if [ "$REF_BUILD_OK" != "ok" ]; then
  ng "roadmap2-gate-2 (v2 dispatch wiring): roadmap ① ref build/trace FAIL (= clean CI false PASS risk 解消のため必須)"
elif [ "$FM_CHB_KEYON" -ge 1 ] && [ "$SSG_CHG_VOL" -ge 1 ] && [ "$LITERAL_VALUE_PROOF" = "ok" ]; then
  ok "roadmap2-gate-2 (v2 dispatch wiring): song-driven FM ch B keyon (reg 0x28 <- 0xF1) ${FM_CHB_KEYON} + SSG ch G volume (reg 0x08 <- 0x0F) ${SSG_CHG_VOL} + FM ch B fnum write value set が roadmap ① ref と異 (= song-driven literal value proof、 ref file = $YMFM_ROADMAP1_REF)"
else
  ng "roadmap2-gate-2 (v2 dispatch wiring) 不成立 (FM ch B keyon=${FM_CHB_KEYON} 期待 >= 1 / SSG ch G volume=${SSG_CHG_VOL} 期待 >= 1 / literal value proof=${LITERAL_VALUE_PROOF:-fail = ε set と roadmap ① ref set が一致 or ε set 空})"
fi

# --- ε fixture build 復帰 (= 後続 gate で ε build の .lst / trace を再利用するため再度 ε fixture build + MAME run) ---
echo "=== ε fixture build 復帰 (= TEST_MODE_V2_SONG_FIXTURE=1, ym2610) + MAME trace 再生成 ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  ε fixture build 復帰 FAIL"; exit 1; }
cp "$LST" "$LST_PLAYBACK"
# stale trace 排除 = MAME run 前に trace dir 強制 clean (= roadmap ① ref MAME run 由来の trace と区別)
rm -rf "$TRACE_DIR"
bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 復帰 未生成 (= MAME run 失敗 or trace 出力なし)"; exit 1; }
[ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 復帰 未生成 (= MAME run 失敗 or trace 出力なし)"; exit 1; }
cp "$YMFM" "$YMFM_PLAYBACK"
cp "$ZMEM" "$ZMEM_PLAYBACK"
# 共通 metric 再計算
IRQ_TICKS=$(awk -F'\t' '$3=="F816"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')
SLOT0_LEN_WRITES=$(awk -F'\t' '$3=="FD7B"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')

# ============================================================
# roadmap2-gate-3 (IRQ tick 駆動) = 静的 .lst call assemble + tempo_acc write 件数
# ============================================================
IRQ_CALL_OK=$(awk '
  /irq_handler_body:/{flag=1; next}
  flag && /irq_done:/{flag=0}
  flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^CD$/ && /call.*pmdneo_v2_song_tick/ {print "ok"; exit}
' "$LST_PLAYBACK")
TEMPO_ACC_WRITE=$(awk -F'\t' '$3=="FD3F"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')
if [ "$IRQ_CALL_OK" = "ok" ] && [ "$TEMPO_ACC_WRITE" -ge 2 ]; then
  ok "roadmap2-gate-3 (IRQ tick 駆動): irq_handler_body 内 call pmdneo_v2_song_tick assembled + tempo_acc (= 0xFD3F) write ${TEMPO_ACC_WRITE} 件 (>= 2 期待)"
else
  ng "roadmap2-gate-3 (IRQ tick 駆動) 不成立 (irq_call=${IRQ_CALL_OK:-none} tempo_acc_write=${TEMPO_ACC_WRITE} 期待 >= 2)"
fi

# ============================================================
# roadmap2-gate-4 (tempo) = IRQ tick > slot 0 LEN write = overflow gate 動作 proof
# ============================================================
if [ "$IRQ_TICKS" -ge 2 ] && [ "$SLOT0_LEN_WRITES" -lt "$IRQ_TICKS" ]; then
  ok "roadmap2-gate-4 (tempo): IRQ tick ${IRQ_TICKS} > slot0 LEN write ${SLOT0_LEN_WRITES} (= overflow gate 動作 = 全 IRQ で dispatch しない)"
else
  ng "roadmap2-gate-4 (tempo) 不成立 (irq_ticks=${IRQ_TICKS} slot0_len_writes=${SLOT0_LEN_WRITES}、 期待 LEN write < IRQ tick)"
fi

# ============================================================
# roadmap2-gate-6 (.org + build-mode 排他) AND 構造
#   (a) .org overflow なし: 15 routine 全 >= 0x0610 + 0x0066 max < 0x0100
#   (b) production build (= TEST_MODE_V2_SONG_FIXTURE=0) で 15 routine 全 assemble なし +
#       IRQ body の call 未 assemble + cold init の ld (song_state),a 未 assemble
# ============================================================
# --- (a) .org overflow check on ε fixture build .lst ---
G6ABAD=0
G6ADET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_tick pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_PLAYBACK")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    G6ABAD=$((G6ABAD + 1)); G6ADET="$G6ADET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST_PLAYBACK" | sort | tail -1)

# --- (b) production build = TEST_MODE_V2_SONG_FIXTURE=0 で build-mode 排他 ---
echo "=== roadmap2-gate-6 (b): production build (= TEST_MODE_V2_SONG_FIXTURE=0) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build FAIL"; exit 1; }
cp "$LST" "$LST_PROD"

G6BBAD=0
G6BDET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_tick pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_PROD")
  if [ -n "$addr" ]; then
    G6BBAD=$((G6BBAD + 1)); G6BDET="$G6BDET ${label}=0x${addr}(assembled)"
  fi
done

IRQ_CALL_PROD=$(awk '/irq_handler_body:/{flag=1; next} flag && /irq_done:/{flag=0} flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^CD$/ && /call.*pmdneo_v2_song_tick/ {print "assembled"; exit}' "$LST_PROD")
COLD_INIT_PROD=$(awk '$1 ~ /^[0-9A-F]{6}$/ && /ld.*\(pmdneo_v2_song_state\), *a/{print "assembled"; exit}' "$LST_PROD")

if [ "$G6ABAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ] \
   && [ "$G6BBAD" -eq 0 ] && [ -z "$IRQ_CALL_PROD" ] && [ -z "$COLD_INIT_PROD" ]; then
  ok "roadmap2-gate-6 (.org + build-mode 排他): (a) 新 15 routine 全 >= 0x0610 + 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow なし) + (b) production build で 15 routine 全 assemble なし + IRQ body call pmdneo_v2_song_tick 未 assemble + cold init song_state clear 未 assemble"
else
  ng "roadmap2-gate-6 (.org + build-mode 排他) 不成立 ((a) routine_bad=${G6ABAD} max0066=0x${MAX0066:-NONE}${G6ADET} / (b) routine_bad=${G6BBAD}${G6BDET} irq_call_prod=${IRQ_CALL_PROD:-none-expected} cold_init_prod=${COLD_INIT_PROD:-none-expected})"
fi

# ============================================================
# supplemental gate IX/IY = pmdneo_v2_song_tick 単一 epilogue + push/pop pair
# ============================================================
TICK_PUSH_IX=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && /push.*ix/{print "ok"; exit}' "$LST_PLAYBACK")
TICK_PUSH_IY=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && /push.*iy/{print "ok"; exit}' "$LST_PLAYBACK")
DONE_POP_IY=$(awk '/pmdneo_v2_song_tick_done:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_tick_done/{exit} flag && /pop.*iy/{print "ok"; exit}' "$LST_PLAYBACK")
DONE_POP_IX=$(awk '/pmdneo_v2_song_tick_done:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_tick_done/{exit} flag && /pop.*ix/{print "ok"; exit}' "$LST_PLAYBACK")
TICK_BODY_RET=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && $1 ~ /^[0-9A-F]{6}$/ && /^[^;]*\<ret\>/{print "found"; exit}' "$LST_PLAYBACK")
if [ "$TICK_PUSH_IX" = "ok" ] && [ "$TICK_PUSH_IY" = "ok" ] && [ "$DONE_POP_IY" = "ok" ] && [ "$DONE_POP_IX" = "ok" ] && [ -z "$TICK_BODY_RET" ]; then
  ok "supplemental gate IX/IY: push ix + push iy (tick body) + pop iy + pop ix (tick_done) + 全 exit 単一 epilogue 経由 (= tick body 内 ret 直接出現なし)"
else
  ng "supplemental gate IX/IY 不成立 (push_ix=${TICK_PUSH_IX:-none} push_iy=${TICK_PUSH_IY:-none} pop_iy=${DONE_POP_IY:-none} pop_ix=${DONE_POP_IX:-none} tick_body_ret=${TICK_BODY_RET:-none-expected})"
fi

# ============================================================
# supplemental gate TIMER-B = IRQ tick 件数 >= 10
# ============================================================
if [ "$IRQ_TICKS" -ge 10 ]; then
  ok "supplemental gate TIMER-B: pmdneo_irq_count (= 0xF816) write ${IRQ_TICKS} 件 (>= 10 期待、 ADR-0050 fade verify 66 tick literal 同等以上、 古い「6 秒で 2 回」 finding stale 再確認)"
else
  ng "supplemental gate TIMER-B 不足 (irq_ticks=${IRQ_TICKS} < 10、 古い stale 再確認 risk)"
fi

# ============================================================
# supplemental gate γ-pattern = song_entry body 内 init+state 存在 + dispatch 撤去
# ============================================================
ENTRY_CALL_INIT=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /call.*pmdneo_v2_song_init/{print "ok"; exit}' "$LST_PLAYBACK")
ENTRY_CALL_DISPATCH=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /call.*pmdneo_v2_song_dispatch/{print "found"; exit}' "$LST_PLAYBACK")
ENTRY_SET_STATE=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /ld.*\(pmdneo_v2_song_state\), *a/{print "ok"; exit}' "$LST_PLAYBACK")
if [ "$ENTRY_CALL_INIT" = "ok" ] && [ -z "$ENTRY_CALL_DISPATCH" ] && [ "$ENTRY_SET_STATE" = "ok" ]; then
  ok "supplemental gate γ-pattern: song_entry body 内 call song_init 存在 + call song_dispatch 撤去 + ld (song_state),a 存在 (= dispatch は IRQ 駆動へ委ね)"
else
  ng "supplemental gate γ-pattern 不成立 (entry_call_init=${ENTRY_CALL_INIT:-none} entry_call_dispatch=${ENTRY_CALL_DISPATCH:-none-expected} entry_set_state=${ENTRY_SET_STATE:-none})"
fi

# ============================================================
# supplemental gate cold-boot = 0xFD3E write sequence + cmd 0x05/0x07 callsite 静的確認
# ============================================================
SONG_STATE_WRITES=$(awk -F'\t' '$3=="FD3E"' "$ZMEM_PLAYBACK" | wc -l | tr -d ' ')
SONG_STATE_FIRST=$(awk -F'\t' '$3=="FD3E"{print $4; exit}' "$ZMEM_PLAYBACK")
SONG_STATE_HAS_ONE=$(awk -F'\t' '$3=="FD3E" && $4=="01"' "$ZMEM_PLAYBACK" | head -1 | wc -l | tr -d ' ')

CMD5_CALL=$(awk '/nmi_cmd_5_init_mml_song:/{flag=1; next} flag && $0 ~ /[ \t]nmi_cmd_[6-9a-z_]/{exit} flag && /call.*pmdneo_v2_song_entry/{print "ok"; exit}' "$LST_PLAYBACK")
CMD7_CALL=$(awk '/nmi_cmd_7_play_song_v2:/{flag=1; next} flag && $0 ~ /[ \t]nmi_cmd_[89a-z_]/{exit} flag && /call.*pmdneo_v2_song_entry/{print "ok"; exit}' "$LST_PLAYBACK")

if [ "$SONG_STATE_WRITES" -ge 2 ] && [ "$SONG_STATE_FIRST" = "00" ] && [ "$SONG_STATE_HAS_ONE" -ge 1 ] && [ "$CMD5_CALL" = "ok" ] && [ "$CMD7_CALL" = "ok" ]; then
  ok "supplemental gate cold-boot: song_state write ${SONG_STATE_WRITES} 件 + first=${SONG_STATE_FIRST} + has-1=${SONG_STATE_HAS_ONE} + cmd 0x05 call=${CMD5_CALL} + cmd 0x07 call=${CMD7_CALL}"
else
  ng "supplemental gate cold-boot 不成立 (song_state_writes=${SONG_STATE_WRITES} 期待 >= 2 / first=${SONG_STATE_FIRST:-none} 期待 00 / has_one=${SONG_STATE_HAS_ONE} 期待 >= 1 / cmd5_call=${CMD5_CALL:-none} / cmd7_call=${CMD7_CALL:-none})"
fi

# ============================================================
# roadmap2-gate-5 (baseline regression) = verify-axis-b-fm-ssg-real-sound.sh transitively
# (= 末尾配置 = ADR-0049〜0057 transitively regression、 production build 中で実行可能)
# ============================================================
echo "=== roadmap2-gate-5 (baseline regression) = verify-axis-b-fm-ssg-real-sound.sh ==="
if bash src/test-fixtures/axis-b/verify-axis-b-fm-ssg-real-sound.sh >/dev/null 2>&1; then
  ok "roadmap2-gate-5 (baseline regression): verify-axis-b-fm-ssg-real-sound.sh 6 gate 全 PASS (= ADR-0049〜0057 transitively regression)"
else
  ng "roadmap2-gate-5 (baseline regression) FAIL"
fi

# ============================================================
# production build 復帰 + 集計 + completion proof line
# ============================================================
echo "=== production build 復帰 ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build 復帰 FAIL"; exit 1; }
ok "production build 復帰完了"

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "=== roadmap ② completion proof (ADR-0058 §決定 6 全 PASS = ζ Accepted 移行 ready) ==="
  echo "§決定 6 gate 1 (v2 song parse):          PASS"
  echo "§決定 6 gate 2 (v2 dispatch wiring):     PASS"
  echo "§決定 6 gate 3 (IRQ tick 駆動):          PASS"
  echo "§決定 6 gate 4 (tempo):                  PASS"
  echo "§決定 6 gate 5 (baseline regression):    PASS"
  echo "§決定 6 gate 6 (.org + build-mode 排他): PASS"
  echo "supplemental gate IX/IY:                 PASS"
  echo "supplemental gate TIMER-B:               PASS"
  echo "supplemental gate γ-pattern:             PASS"
  echo "supplemental gate cold-boot:             PASS"
  echo "ζ Accepted 移行 ready: yes (ADR-0058 §決定 1 ε 完了)"
  echo ""
  echo "OK  ALL PASS (= 軸 B production-ready roadmap ② ε = verify script 体系化 + completion proof + 10 gate 全 PASS)"
  exit 0
else
  echo ""
  echo "NG  $FAIL gate FAIL"
  exit 1
fi
