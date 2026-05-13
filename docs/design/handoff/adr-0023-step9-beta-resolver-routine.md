# ADR-0023 step 9 β handoff: `pmdneo_resolve_sample_table_id` routine 単体実装 (= call insertion 未挿入)

- 日付: 2026-05-13 (= 10th session、 β 着手)
- 対応 ADR: [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 9 β
- 関連 commit: 本 handoff doc を含む β 着手 commit

## β scope (= 1 commit + 1 push)

- `src/driver/standalone_test.s` 内に `pmdneo_resolve_sample_table_id` routine を新規追加
- 配置: α で追加した `pne_sample_directory` 直後、 `rhythm_main:` 直前 (= directory と隣接配置、 ADR-0023 §決定 6 補足)
- routine 単体実装:
  - directory loop + terminator check + 16 byte memcmp
  - match → `driver_pne_sample_table_id` (= 0xFD32) に entry の id を保存
  - mismatch / terminator → 0xFF sentinel を保存
- `.MN` load chain への call insertion は **しない** (= γ scope)
- routine は **存在するが未参照** の状態で閉じる
- playback path (= `adpcma_keyon_simple` 等) は完全不変

## 実装差分

### routine 実装 (= `standalone_test.s` line 2878-2944)

```asm
;;; ----------------------------------------------------------------
;;; ADR-0023 step 9 β: pmdneo_resolve_sample_table_id
;;;
;;; ADR-0023 §決定 6 整合: 独立 init routine、 .MN load chain 末尾 call (= γ scope)
;;; β scope: routine 単体実装、 call insertion は γ scope (= まだ呼ばれない)
;;; ADR-0023 §決定 11: 出力 (= 0xFD32) は Step 9 内で playback decision に使用しない
;;;
;;; 入力:
;;;   driver_pne_filename_buf (= 0xFD20-0xFD2F): NUL-padded ASCII filename (= Step 8 で書込済)
;;;   pne_sample_directory: hand-written directory (= 17 byte/entry, 0xFF terminator)
;;;
;;; 出力:
;;;   driver_pne_sample_table_id (= 0xFD32): 0x00-0xFE = valid id、 0xFF = mismatch sentinel
;;;
;;; 動作:
;;;   1. HL = pne_sample_directory (= entry head)
;;;   2. loop:
;;;        terminator check (= entry+16 が 0xFF か peek) → 0xFF なら mismatch branch
;;;        16 byte memcmp (entry filename vs driver_pne_filename_buf)
;;;        match → A = entry+16 (= sample_table_id) を 0xFD32 に store + ret
;;;        mismatch → HL += 17 (= next entry) + loop
;;;
;;; clobber: A, B, DE, HL (= caller 保存規約は既存 driver routine 群と同じ無し)
pmdneo_resolve_sample_table_id:
        ld      hl, #pne_sample_directory
resolve_loop:
        ;; HL = current entry head
        ;; --- terminator check (= entry+16 が 0xFF か peek) ---
        push    hl                              ; save entry head
        ld      de, #16
        add     hl, de
        ld      a, (hl)                         ; A = entry の sample_table_id byte
        pop     hl                              ; restore entry head
        cp      #0xFF
        jr      z, resolve_mismatch             ; terminator hit → mismatch

        ;; --- 16 byte memcmp (entry filename vs driver_pne_filename_buf) ---
        push    hl                              ; save entry head (for resolve_next)
        ld      de, #driver_pne_filename_buf
        ld      b, #16
resolve_cmp_loop:
        ld      a, (de)
        cp      (hl)
        jr      nz, resolve_next                ; byte mismatch → next entry
        inc     hl
        inc     de
        djnz    resolve_cmp_loop

        ;; match: HL = entry head + 16 = sample_table_id field
        ld      a, (hl)                         ; A = sample_table_id
        ld      (driver_pne_sample_table_id), a
        pop     hl                              ; discard saved entry head
        ret

resolve_next:
        pop     hl                              ; restore entry head
        ld      de, #17
        add     hl, de                          ; HL = next entry head
        jr      resolve_loop

resolve_mismatch:
        ld      a, #0xFF
        ld      (driver_pne_sample_table_id), a
        ret
```

#### 設計判断

- **terminator check を memcmp 前に置く理由**: directory の末尾 entry (= filename 16 byte don't care + id 0xFF) を踏んで誤って memcmp に入ると、 終端 entry の filename (= NUL × 16) が偶然 `driver_pne_filename_buf` (= NUL-padded だが先頭は実 filename) と一致する確率はゼロではない (= filename が空の場合) ため、 sample_table_id field を先に peek して 0xFF を検出する設計が安全
- **memcmp は 16 byte 固定**: `driver_pne_filename_buf` と entry filename が両方 NUL-padded 16 byte 固定形のため、 strcmp ではなく単純 memcmp で OK (= NUL padding が一致すれば match)
- **register 使用**: `clobber A, B, DE, HL`、 caller 保存規約は driver 内 routine 群と統一 (= caller が保存)。 call が γ で挿入される時、 caller side は必要に応じて push / pop で保存
- **stack 使用**: 最大 1 階層の push/pop (= entry head 保持) のみ。 Z80 stack 64 byte (= 0xFFC0-0xFFFF) に対して十分余裕

## 動作確認 (= β 完了条件 4 件)

### 条件 1: build PASS ✅

`bash scripts/build-poc.sh` で「=== build 完了 ===」 表示。 sdasz80 / sdldz80 / sdobjcopy / vromtool.py すべて PASS。

### 条件 2: routine size sanity ✅

`build/standalone_test.lst` 確認:
- `pmdneo_resolve_sample_table_id` 開始 addr = **0x1070**
- routine 末尾 (= `resolve_mismatch` の `ret`) addr = **0x109E**
- routine size = **47 byte (= 0x2F)**

47 byte は妥当 size (= directory loop + terminator check + memcmp + match/mismatch branch 込み)。

### 条件 3: call insertion されていない ✅

`src/driver/standalone_test.s` 全体に対して `pmdneo_resolve_sample_table_id` の参照を grep:
- line 2879: コメント `;;; ADR-0023 step 9 β: pmdneo_resolve_sample_table_id`
- line 2901: label 定義 `pmdneo_resolve_sample_table_id:`

→ **call 呼出箇所は 0 件**。 routine は定義されているが、 driver 内のどこからも呼ばれない。

### 条件 4: register trace = α と byte-identical (= 静的論証) ✅

β は routine を ROM に embed しただけで、 chip register write 経路には 1 命令も影響しない:

- routine は call されないため、 実行されない (= dead code 状態)
- chip register write は α と同じ場所 (= `adpcma_keyon_simple` 等) でのみ発生
- VROM / `samples.inc` / build pipeline は完全不変
- driver SRAM 0xFD32 は α 時点でも β 時点でも書込まれない (= call insertion が γ で初めて発生)

→ 静的論証で「chip register write pattern = α と byte-identical」 を保証。 動的 trace 実行は γ で初めて意味を持つ (= call insertion 後)。

## β scope の重要境界 (= future contributor 向け)

β 時点の `pmdneo_resolve_sample_table_id` routine は **dead code** であり、 driver 内のどこからも呼出されない。 routine の実 runtime 挙動 (= directory compare / match で 0xFD32 = 0x00 / mismatch で 0xFD32 = 0xFF) は **γ の call insertion 後に初めて検証可能** となる。

β 完了条件で確認したのは:

- routine が ROM に正しく embed されていること (= build PASS + size + address)
- routine が driver 内から呼ばれていないこと (= call insertion 0 件)
- 既存 chip register write pattern が α と byte-identical であること (= dead code なので影響なし)

つまり β 完了は「routine が存在する」 ことのみを保証し、 「routine が期待通り動く」 ことは γ scope。 future contributor が「β で resolver 動作確認済」 と誤解しないよう明示。

## scope-out 維持確認

β では以下を一切実装しない:

- chain insertion (= `.MN` load chain 末尾への `call pmdneo_resolve_sample_table_id`) → γ scope
- memory inspection primary gate 整備 (= 0xFD32 観測 script) → γ scope
- mismatch fixture (= directory に存在しない filename の `.MN`) → γ scope
- `adpcma_keyon` refactor → step 10+ scope
- `.PNE` binary parse → step 10+ scope
- multi-`.PNE` switching → step 10+ scope
- generated directory (= D3) → future scope
- mismatch 時 silent flag / keyon skip 拡張 → step 10+ scope

## 既存 path 不変確認

- `assets/samples.inc`: 不変
- VROM: 不変
- `adpcma_ch_sample_ptr_table` / `adpcma_sample_bd` 〜 `adpcma_sample_top`: 不変
- `adpcma_keyon_simple` / `adpcma_keyoff_hook` / `adpcma_volume_hook`: 不変
- L-Q part 6ch playback path: 不変
- step 8 `pmdneo_mn_direct_load_lq_part_addr`: 不変 (= β でも call insertion しない)
- `pne_sample_directory` (= α で追加): 不変
- `.equ` block (= α で追加した `driver_pne_sample_table_id` 含む): 不変
- `.PNE` converter / vromtool.py / build pipeline: 不変

## 次 step (= γ scope)

- `.MN` load chain (= `pmdneo_mn_direct_load_lq_part_addr` 末尾) への `call pmdneo_resolve_sample_table_id` 1 行挿入
- memory inspection primary gate 整備 (= 0xFD32 観測 script の作成)
- match fixture (= `PMDNEO01.PNE`) で `0xFD32 == 0x00` 確認
- mismatch fixture (= directory に存在しない filename を持つ `.MN`) で `0xFD32 == 0xFF` 確認
- γ primary gate = memory inspection (= 0xFD32 = 0x00 / 0xFF) + register trace = β と byte-identical の確認

## 関連

- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 6 (= T3 独立 init routine) / §決定 9 β (= sub-sprint 分割)
- [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) (= `driver_pne_filename_buf` を入力として利用)
- [ADR-0023 step 9 α handoff](adr-0023-step9-alpha-state-cell-directory.md) (= α で `driver_pne_sample_table_id` cell 定義 + `pne_sample_directory` data 配置済)
- ADR-0023 §決定 11: Step 9 内で `sample_table_id` は playback decision に使用しない (= β でも routine 出力先は確保するが、 既存 playback path は読まない)
