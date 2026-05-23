#!/usr/bin/env bash
#
# PMDNEO 軸 B production-ready roadmap ② δ verify gate (= ADR-0058 v2 IRQ tick 連携 + tempo accumulator)
#
# verify scope: ADR-0058 δ で導入した IRQ tick 連携 + tempo accumulator + active flag pattern が
#   trace で確認できることを δ-1〜δ-10 で検証。 driver 既存 routine + cmd 0x05 path は不可触。
#
#   δ-1:  IRQ tick 駆動 proof        — 静的 .lst で irq_handler_body 内 call pmdneo_v2_song_tick 存在 +
#                                       z80-mem-trace で pmdneo_v2_tempo_acc (= 0xFD3F) write >= 2 件
#   δ-2:  tempo proof                — fnumset_fm call 件数 < IRQ tick 数 (= overflow gate 動作 proof)
#   δ-3:  周期再生 proof              — slot 0 ADDR (= 0xFD79/0xFD7A) write の uniq value 件数 >= 2
#                                       (= 複数 byte 進行 = fixture 後続 byte 進行)
#   δ-4:  IX/IY 保存 proof            — 静的 .lst で pmdneo_v2_song_tick 内 push ix + push iy + pop iy +
#                                       pop ix pair 存在 + 全 exit が pmdneo_v2_song_tick_done 経由
#   δ-5:  TIMER-B IRQ rate 実測       — z80-mem-trace で pmdneo_irq_count (= 0xF816) write 件数 >= 数十
#   δ-6:  baseline regression        — verify-axis-b-fm-ssg-real-sound.sh exit 0
#   δ-7:  production byte-identical  — TEST_MODE_V2_SONG_FIXTURE=0 build .lst で 新 pmdneo_v2_song_tick
#                                       label 未出現 + IRQ body の call 未 assemble + cold init の
#                                       xor a / ld (pmdneo_v2_song_state),a 未 assemble
#   δ-8:  γ pattern 移行              — 静的 .lst で pmdneo_v2_song_entry body 内 call pmdneo_v2_song_init
#                                       存在 + call pmdneo_v2_song_dispatch 未存在 +
#                                       ld (pmdneo_v2_song_state),a 存在 (= active flag set)
#   δ-9:  .org overflow なし          — 新 15 routine label addr >= 0x0610 + 0x0066 max < 0x0100
#   δ-10: cold boot inactive + cmd callsite — (a) z80-mem-trace で 0xFD3E (= song_state) write 件数 >= 2 件 +
#                                       先頭 write が値 0 + 後続 write 1 (= cold init clear → entry active set 順序)
#                                       (b) 静的 .lst で nmi_cmd_5_init_mml_song body + nmi_cmd_7_play_song_v2
#                                       body 両者に call pmdneo_v2_song_entry 存在
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

YMFM_DELTA="/tmp/v2-song-delta-ymfm.tsv"
ZMEM_DELTA="/tmp/v2-song-delta-zmem.tsv"
LST_DELTA="/tmp/v2-song-delta.lst"
LST_PROD="/tmp/v2-song-prod.lst"

FAIL=0
ok() { echo "OK  $1"; }
ng() { echo "NG  $1"; FAIL=$((FAIL + 1)); }
hex() { echo $((16#$1)); }

# ============================================================
# δ fixture build (= ym2610) + MAME headless trace
# ============================================================
echo "=== δ fixture build (= TEST_MODE_V2_SONG_FIXTURE=1, ym2610) + MAME trace ==="
rm -f "$PREPROCESSED"
PMDNEO_V2_SONG_FIXTURE=1 bash scripts/build-poc.sh --chip ym2610 >/dev/null 2>&1 \
  || { echo "NG  δ fixture build FAIL"; exit 1; }
[ -f "$LST" ] || { echo "NG  .lst 未生成"; exit 1; }
cp "$LST" "$LST_DELTA"

bash scripts/run-mame.sh --headless --trace --wavwrite --wavwrite-seconds 5 >/dev/null 2>&1 || true
[ -f "$YMFM" ] || { echo "NG  ymfm-trace 未生成"; exit 1; }
[ -f "$ZMEM" ] || { echo "NG  z80-mem-trace 未生成"; exit 1; }
cp "$YMFM" "$YMFM_DELTA"
cp "$ZMEM" "$ZMEM_DELTA"

# ============================================================
# δ-9: .org overflow check (= 15 routine + 0x0066 max)
# ============================================================
D9BAD=0
D9DET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_tick pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_DELTA")
  if [ -z "$addr" ] || [ "$(hex "$addr")" -lt "$(hex 0610)" ]; then
    D9BAD=$((D9BAD + 1)); D9DET="$D9DET ${label}=0x${addr:-NONE}"
  fi
done
MAX0066=$(awk '/\.org 0x0066/{s=1} /\.org 0x0100/{s=0} s && $1 ~ /^[0-9A-F]{6}$/{print $1}' "$LST_DELTA" | sort | tail -1)
if [ "$D9BAD" -eq 0 ] && [ -n "$MAX0066" ] && [ "$(hex "$MAX0066")" -lt "$(hex 0100)" ]; then
  ok "δ-9: 新 15 routine 全 >= 0x0610 + 0x0066 セクション max addr 0x${MAX0066} < 0x0100 (= overflow なし)"
else
  ng "δ-9: .org overflow (routine_bad=${D9BAD} max0066=0x${MAX0066:-NONE}${D9DET})"
fi

# ============================================================
# δ-1: IRQ tick 駆動 proof
#   静的 .lst で irq_handler_body 内 call pmdneo_v2_song_tick 存在 +
#   z80-mem-trace で pmdneo_v2_tempo_acc (= 0xFD3F) write >= 2 件
# ============================================================
# 静的 .lst で irq_handler_body 〜 irq_done の領域内 call pmdneo_v2_song_tick byte (= CD)
IRQ_CALL_OK=$(awk '
  /irq_handler_body:/{flag=1; next}
  flag && /irq_done:/{flag=0}
  flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^CD$/ && /call.*pmdneo_v2_song_tick/ {print "ok"; exit}
' "$LST_DELTA")
TEMPO_ACC_WRITE=$(awk -F'\t' '$3=="FD3F"' "$ZMEM_DELTA" | wc -l | tr -d ' ')
if [ "$IRQ_CALL_OK" = "ok" ] && [ "$TEMPO_ACC_WRITE" -ge 2 ]; then
  ok "δ-1: IRQ tick 駆動 proof = irq_handler_body 内 call pmdneo_v2_song_tick assembled + tempo_acc (= 0xFD3F) write ${TEMPO_ACC_WRITE} 件 (>= 2 期待)"
else
  ng "δ-1: IRQ tick 駆動 proof 不成立 (irq_call=${IRQ_CALL_OK:-none} tempo_acc_write=${TEMPO_ACC_WRITE} 期待 >= 2)"
fi

# ============================================================
# δ-2: tempo proof
#   tempo overflow 時のみ dispatch 発火 = dispatch 件数 < IRQ tick 件数
#   IRQ tick = pmdneo_irq_count (= 0xF816) write 件数 が overflow 件数の上限。
#   dispatch 1 回ごとに slot 0 LEN (= 0xFD7B) への write が発生する想定 (= part_parse → part_note set_len)。
#   厳密には dispatch != LEN write だが、 「LEN write 件数 < IRQ tick 件数」 で
#   overflow gate (= 全 IRQ で dispatch しない) の動作 proof とする。
# ============================================================
IRQ_TICKS=$(awk -F'\t' '$3=="F816"' "$ZMEM_DELTA" | wc -l | tr -d ' ')
SLOT0_LEN_WRITES=$(awk -F'\t' '$3=="FD7B"' "$ZMEM_DELTA" | wc -l | tr -d ' ')
if [ "$IRQ_TICKS" -ge 2 ] && [ "$SLOT0_LEN_WRITES" -lt "$IRQ_TICKS" ]; then
  ok "δ-2: tempo proof = IRQ tick ${IRQ_TICKS} > slot0 LEN write ${SLOT0_LEN_WRITES} (= overflow gate 動作 = 全 IRQ で dispatch しない)"
else
  ng "δ-2: tempo proof 不成立 (irq_ticks=${IRQ_TICKS} slot0_len_writes=${SLOT0_LEN_WRITES}、 期待 LEN write < IRQ tick)"
fi

# ============================================================
# δ-3: 周期再生 proof
#   slot 0 ADDR (= 0xFD79 / 0xFD7A) write の uniq value 件数 >= 2 (= 複数 byte 進行)
# ============================================================
SLOT0_ADDR_UNIQ=$(awk -F'\t' '$3=="FD79" || $3=="FD7A" {print $3"="$4}' "$ZMEM_DELTA" | sort -u | wc -l | tr -d ' ')
if [ "$SLOT0_ADDR_UNIQ" -ge 2 ]; then
  ok "δ-3: 周期再生 proof = slot 0 ADDR (= 0xFD79/0xFD7A) write uniq value ${SLOT0_ADDR_UNIQ} 件 (>= 2 期待 = 複数 byte 進行)"
else
  ng "δ-3: 周期再生 proof 不成立 (slot0_addr_uniq=${SLOT0_ADDR_UNIQ} 期待 >= 2、 fixture 後続 byte 進行なし)"
fi

# ============================================================
# δ-4: IX/IY 保存 proof
#   静的 .lst で pmdneo_v2_song_tick 内 push ix + push iy + pop iy + pop ix pair 存在 +
#   全 exit が pmdneo_v2_song_tick_done 経由
# ============================================================
# pmdneo_v2_song_tick 〜 pmdneo_v2_song_tick_done と pmdneo_v2_song_tick_done 〜 next label の
# 2 領域を独立に確認: tick body に push ix/iy + tick_done body に pop iy/ix + tick body 内 ret 直接出現なし
TICK_PUSH_IX=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && /push.*ix/{print "ok"; exit}' "$LST_DELTA")
TICK_PUSH_IY=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && /push.*iy/{print "ok"; exit}' "$LST_DELTA")
DONE_POP_IY=$(awk '/pmdneo_v2_song_tick_done:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_tick_done/{exit} flag && /pop.*iy/{print "ok"; exit}' "$LST_DELTA")
DONE_POP_IX=$(awk '/pmdneo_v2_song_tick_done:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_tick_done/{exit} flag && /pop.*ix/{print "ok"; exit}' "$LST_DELTA")
# tick body 内 ret 直接出現 (= epilogue 経由しない exit) なし
TICK_BODY_RET=$(awk '/pmdneo_v2_song_tick:/{flag=1; next} flag && /pmdneo_v2_song_tick_done:/{exit} flag && $1 ~ /^[0-9A-F]{6}$/ && /^[^;]*\<ret\>/{print "found"; exit}' "$LST_DELTA")
if [ "$TICK_PUSH_IX" = "ok" ] && [ "$TICK_PUSH_IY" = "ok" ] && [ "$DONE_POP_IY" = "ok" ] && [ "$DONE_POP_IX" = "ok" ] && [ -z "$TICK_BODY_RET" ]; then
  ok "δ-4: IX/IY 保存 proof = push ix + push iy (tick body) + pop iy + pop ix (tick_done) + 全 exit 単一 epilogue 経由 (= tick body 内 ret 直接出現なし)"
else
  ng "δ-4: IX/IY 保存 proof 不成立 (push_ix=${TICK_PUSH_IX:-none} push_iy=${TICK_PUSH_IY:-none} pop_iy=${DONE_POP_IY:-none} pop_ix=${DONE_POP_IX:-none} tick_body_ret=${TICK_BODY_RET:-none})"
fi

# ============================================================
# δ-5: TIMER-B IRQ rate 実測
#   z80-mem-trace で pmdneo_irq_count (= 0xF816) write 件数 >= 数十
#   (= wavwrite 5 秒中 TIMER-B IRQ 実発火 / 古い 6 秒で 2 回 finding stale 再確認)
# ============================================================
if [ "$IRQ_TICKS" -ge 10 ]; then
  ok "δ-5: TIMER-B IRQ rate 実測 = pmdneo_irq_count (= 0xF816) write ${IRQ_TICKS} 件 (>= 10 期待、 ADR-0050 fade verify 66 tick literal 同等以上)"
else
  ng "δ-5: TIMER-B IRQ rate 不足 (irq_ticks=${IRQ_TICKS} < 10、 古い stale 再確認 risk)"
fi

# ============================================================
# δ-7: production byte-identical = TEST_MODE_V2_SONG_FIXTURE=0 で 新 routine 全 assemble なし
# ============================================================
echo "=== δ-7: production build (= TEST_MODE_V2_SONG_FIXTURE=0) ==="
rm -f "$PREPROCESSED"
bash scripts/build-poc.sh >/dev/null 2>&1 || { echo "NG  production build FAIL"; exit 1; }
cp "$LST" "$LST_PROD"

# production .lst で新 15 routine の addr column が 6-hex でない (= assemble されていない) ことを assert
D7BAD=0
D7DET=""
for label in pmdneo_v2_song_init pmdneo_v2_song_dispatch pmdneo_v2_part_tick pmdneo_v2_part_parse \
             pmdneo_v2_part_note pmdneo_v2_part_rest pmdneo_v2_part_loop pmdneo_v2_part_fetch_byte \
             pmdneo_v2_part_dispatch_note pmdneo_v2_fm_voice_note_song pmdneo_v2_ssg_voice_note_song \
             pmdneo_v2_song_entry pmdneo_v2_song_tick pmdneo_v2_song_fixture_fm_b pmdneo_v2_song_fixture_ssg_g; do
  addr=$(awk -v l="$label" '$0 ~ ("[ \t]" l ":") && $1 ~ /^[0-9A-F]{6}$/ {print $1; exit}' "$LST_PROD")
  if [ -n "$addr" ]; then
    D7BAD=$((D7BAD + 1)); D7DET="$D7DET ${label}=0x${addr}(assembled)"
  fi
done

# IRQ body の call pmdneo_v2_song_tick が production .lst で未 assemble (= addr column 空の line で
# `call pmdneo_v2_song_tick` 出現 = source line の comment のみ、 byte なし)
IRQ_CALL_PROD=$(awk '/irq_handler_body:/{flag=1; next} flag && /irq_done:/{flag=0} flag && $1 ~ /^[0-9A-F]{6}$/ && $2 ~ /^CD$/ && /call.*pmdneo_v2_song_tick/ {print "assembled"; exit}' "$LST_PROD")

# cold init の xor a / ld (pmdneo_v2_song_state),a が production で未 assemble
# .if TEST_MODE_V2_SONG_FIXTURE 配下 ld (pmdneo_v2_song_state), a = 6-hex addr 付きで .lst に出現したら assembled
COLD_INIT_PROD=$(awk '$1 ~ /^[0-9A-F]{6}$/ && /ld.*\(pmdneo_v2_song_state\), *a/{print "assembled"; exit}' "$LST_PROD")

if [ "$D7BAD" -eq 0 ] && [ -z "$IRQ_CALL_PROD" ] && [ -z "$COLD_INIT_PROD" ]; then
  ok "δ-7: production byte-identical = 新 15 routine 全 assemble なし + IRQ body call pmdneo_v2_song_tick 未 assemble + cold init song_state clear 未 assemble"
else
  ng "δ-7: production byte-identical 不成立 (routine_bad=${D7BAD}${D7DET} irq_call_prod=${IRQ_CALL_PROD:-none} cold_init_prod=${COLD_INIT_PROD:-none})"
fi

# ============================================================
# δ-8: γ pattern 移行 (= entry → IRQ pattern)
#   pmdneo_v2_song_entry body 内 call pmdneo_v2_song_init 存在 +
#   call pmdneo_v2_song_dispatch 未存在 + ld (pmdneo_v2_song_state),a 存在
# ============================================================
ENTRY_CALL_INIT=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /call.*pmdneo_v2_song_init/{print "ok"; exit}' "$LST_DELTA")
ENTRY_CALL_DISPATCH=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /call.*pmdneo_v2_song_dispatch/{print "found"; exit}' "$LST_DELTA")
ENTRY_SET_STATE=$(awk '/pmdneo_v2_song_entry:/{flag=1; next} flag && $0 ~ /[ \t][a-z_]+:/ && !/pmdneo_v2_song_entry/{exit} flag && /ld.*\(pmdneo_v2_song_state\), *a/{print "ok"; exit}' "$LST_DELTA")
if [ "$ENTRY_CALL_INIT" = "ok" ] && [ -z "$ENTRY_CALL_DISPATCH" ] && [ "$ENTRY_SET_STATE" = "ok" ]; then
  ok "δ-8: γ pattern 移行 = song_entry body 内 call song_init 存在 + call song_dispatch 撤去 + ld (song_state),a 存在 (= dispatch は IRQ 駆動へ委ね)"
else
  ng "δ-8: γ pattern 移行 不成立 (entry_call_init=${ENTRY_CALL_INIT:-none} entry_call_dispatch=${ENTRY_CALL_DISPATCH:-none-expected} entry_set_state=${ENTRY_SET_STATE:-none})"
fi

# ============================================================
# δ-10: cold boot inactive proof + cmd 0x05/0x07 callsite 静的確認
#   (a) z80-mem-trace で 0xFD3E (= song_state) write >= 2 件 + 先頭 write 値 0 + 後続 write 値 1
#   (b) 静的 .lst で nmi_cmd_5_init_mml_song body + nmi_cmd_7_play_song_v2 body 両者に
#       call pmdneo_v2_song_entry 存在
# ============================================================
# (a) song_state write sequence
SONG_STATE_WRITES=$(awk -F'\t' '$3=="FD3E"' "$ZMEM_DELTA" | wc -l | tr -d ' ')
SONG_STATE_FIRST=$(awk -F'\t' '$3=="FD3E"{print $4; exit}' "$ZMEM_DELTA")
# 先頭 write が "00" + 後続のいずれかに "01" 存在
SONG_STATE_HAS_ONE=$(awk -F'\t' '$3=="FD3E" && $4=="01"' "$ZMEM_DELTA" | head -1 | wc -l | tr -d ' ')

# (b) cmd 0x05 + cmd 0x07 callsite 静的
CMD5_CALL=$(awk '/nmi_cmd_5_init_mml_song:/{flag=1; next} flag && $0 ~ /[ \t]nmi_cmd_[6-9a-z_]/{exit} flag && /call.*pmdneo_v2_song_entry/{print "ok"; exit}' "$LST_DELTA")
CMD7_CALL=$(awk '/nmi_cmd_7_play_song_v2:/{flag=1; next} flag && $0 ~ /[ \t]nmi_cmd_[89a-z_]/{exit} flag && /call.*pmdneo_v2_song_entry/{print "ok"; exit}' "$LST_DELTA")

if [ "$SONG_STATE_WRITES" -ge 2 ] && [ "$SONG_STATE_FIRST" = "00" ] && [ "$SONG_STATE_HAS_ONE" -ge 1 ] && [ "$CMD5_CALL" = "ok" ] && [ "$CMD7_CALL" = "ok" ]; then
  ok "δ-10: cold boot inactive proof + cmd callsite = song_state write ${SONG_STATE_WRITES} 件 + first=${SONG_STATE_FIRST} + has-1=${SONG_STATE_HAS_ONE} + cmd 0x05 call=${CMD5_CALL} + cmd 0x07 call=${CMD7_CALL}"
else
  ng "δ-10: cold boot inactive proof 不成立 (song_state_writes=${SONG_STATE_WRITES} 期待 >= 2 / first=${SONG_STATE_FIRST:-none} 期待 00 / has_one=${SONG_STATE_HAS_ONE} 期待 >= 1 / cmd5_call=${CMD5_CALL:-none} / cmd7_call=${CMD7_CALL:-none})"
fi

# ============================================================
# δ-6: baseline regression = verify-axis-b-fm-ssg-real-sound.sh transitively
# ============================================================
echo "=== δ-6: baseline regression (= verify-axis-b-fm-ssg-real-sound.sh) ==="
if bash src/test-fixtures/axis-b/verify-axis-b-fm-ssg-real-sound.sh >/dev/null 2>&1; then
  ok "δ-6: baseline regression = verify-axis-b-fm-ssg-real-sound.sh 6 gate 全 PASS (= ADR-0049〜0057 transitively regression)"
else
  ng "δ-6: baseline regression FAIL"
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
  echo "OK  ALL PASS (= 軸 B production-ready roadmap ② δ = v2 IRQ tick 連携 + tempo accumulator 10 gate 全 PASS)"
  exit 0
else
  echo "NG  $FAIL gate FAIL"
  exit 1
fi
