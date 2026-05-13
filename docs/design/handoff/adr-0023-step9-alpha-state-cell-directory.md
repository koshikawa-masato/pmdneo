# ADR-0023 step 9 α handoff: PNE filename directory data placement + state cell 定義

- 日付: 2026-05-13 (= 10th session、 α 着手)
- 対応 ADR: [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 9 α
- 関連 commit: 本 handoff doc を含む α 着手 commit

## α scope (= 1 commit + 1 push)

- `src/driver/standalone_test.s` 上部 `.equ` block に `driver_pne_sample_table_id` (= 0xFD32) を追加
- Z80 SRAM layout コメント更新 (= PNE runtime block を 0xFD20-0xFD32 = 19 byte に拡張、 0xFD32 を新規明示)
- `src/driver/standalone_test.s` 末尾 (= `adpcma_sample_top` 直後、 `rhythm_main` 直前) に hand-written directory data `pne_sample_directory` を追加
  - entry 0: filename = `"PMDNEO01.PNE"` (= 12 char + 4 NUL pad = 16 byte) + `sample_table_id` = 0x00
  - terminator entry: filename 16 byte don't care (= NUL) + `sample_table_id` = 0xFF
  - 合計 34 byte (= 17 byte/entry × 2 entry、 ADR-0023 §決定 5)
- resolver routine (= `pmdneo_resolve_sample_table_id`) は **作らない** (= β scope)
- `.MN` load chain への call insertion は **しない** (= γ scope)
- playback path (= `adpcma_keyon_simple` 等) は完全不変

## 実装差分

### 1. `.equ` block 拡張 (= `standalone_test.s` line 115-124)

```
        ;; ADR-0022 step 8 + ADR-0023 step 9: PNE runtime block (= 0xFD20-0xFD32, 19 byte)
        ;;   driver_pne_filename_buf       0xFD20-0xFD2F  16 byte  NUL-terminated ASCII (= ADR-0022 §決定 4)
        ;;   driver_pne_filename_adr_word  0xFD30-0xFD31   2 byte  LE u16 m_buf-relative (= ADR-0022 §決定 4)
        ;;   driver_pne_sample_table_id    0xFD32          1 byte  resolver 出力 (= ADR-0023 §決定 4)
        ;;     0x00-0xFE = valid id、 0xFF = mismatch sentinel
        ;;     ADR-0023 step 9 α scope = data placement only、 まだ書込みされない (= resolver routine は β、 call は γ)
        ;;     ADR-0023 §決定 11: Step 9 内で playback decision に使用しない
        .equ    driver_pne_filename_buf,       0xFD20
        .equ    driver_pne_filename_adr_word,  0xFD30
        .equ    driver_pne_sample_table_id,    0xFD32
```

### 2. SRAM layout コメント更新 (= line 124-135)

```
;;; ----- Z80 SRAM layout (= 2 KB at 0xF800-0xFFFF) -----
;;;
;;;   0xF800 - 0xF80F   reserved future (16 bytes、cmd FIFO 検討中)
;;;   0xF810 - 0xF81F   driver_state (= 16 bytes 既存)
;;;   0xF820 - 0xFD1F   part_workarea (= 20 x 64 = 1280 bytes、ADR-0006 §A)
;;;   0xFD20 - 0xFD2F   driver_pne_filename_buf (= 16 bytes、ADR-0022 §決定 4)
;;;   0xFD30 - 0xFD31   driver_pne_filename_adr_word (= 2 bytes、ADR-0022 §決定 4)
;;;   0xFD32            driver_pne_sample_table_id (= 1 byte、ADR-0023 §決定 4、 α scope = placement only)
;;;   0xFD33 - 0xFFBF   free / 後続 phase 用 (= 653 bytes 余裕)
;;;   0xFFC0 - 0xFFFF   Z80 stack (= 64 bytes 既存、ld sp, #0xFFFF 起点)
```

### 3. directory data 追加 (= line 2849 直後、 `adpcma_sample_top` と `rhythm_main` の間)

```
adpcma_sample_top:
        .db     TOP_START_LSB, TOP_START_MSB, TOP_STOP_LSB, TOP_STOP_MSB

;;; ----------------------------------------------------------------
;;; ADR-0023 step 9 α: PNE filename directory (= hand-written D1 placeholder)
;;;
;;; ADR-0023 §決定 3 / §決定 5 整合: 17 byte/entry, fixed length
;;;   filename:         16 byte, fixed length, NUL-padded ASCII
;;;   sample_table_id:   1 byte (= 0x00-0xFE valid id、 0xFF terminator marker)
;;;
;;; α scope: data placement only. resolver routine は β、 call insertion は γ。
;;; ADR-0023 §決定 11: driver_pne_sample_table_id は Step 9 内で playback decision に使用しない。
;;; ADR-0023 §決定 3: D1 = proof 用 placeholder、 最終 directory ownership ではない (= future D3 generated)
pne_sample_directory:
        ;; entry 0: filename = "PMDNEO01.PNE" (= 12 char + 4 NUL pad = 16 byte)
        ;;          sample_table_id = 0x00
        .db     0x50, 0x4D, 0x44, 0x4E, 0x45, 0x4F, 0x30, 0x31   ; "PMDNEO01"
        .db     0x2E, 0x50, 0x4E, 0x45, 0x00, 0x00, 0x00, 0x00   ; ".PNE\0\0\0\0"
        .db     0x00                                              ; sample_table_id = 0x00

        ;; terminator entry (= sample_table_id == 0xFF、 filename don't care = NUL)
        .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        .db     0xFF                                              ; sample_table_id = 0xFF (terminator)

rhythm_main:
```

#### 設計判断

- 配置場所: `adpcma_sample_top` 直後 (= 既存 sample data 群の隣接区画) で、 sample 関連 data の論理的延長として読みやすい
- entry binary 構造は ADR-0023 §決定 5 と literal 整合 (= 17 byte fixed、 16 byte filename + 1 byte id、 terminator は id = 0xFF)
- string literal は numeric `.db` で表記 (= driver 内に既存 `.ascii` 用例がないため流儀踏襲、 ASCII code 直書きで encoding 揺らぎ回避)
- terminator entry の filename を NUL 埋めにしたのは可読性のため (= don't care だが 0x00 統一)

## 動作確認 (= α 完了条件 4 件)

### 条件 1: build PASS ✅

`bash scripts/build-poc.sh` で「=== build 完了 ===」 表示。 sdasz80 / sdldz80 / sdobjcopy / vromtool.py すべて PASS。

### 条件 2: symbol / label が期待通り存在 ✅

`build/standalone_test.lst` 確認:

- `00FD32   124  .equ    driver_pne_sample_table_id,    0xFD32` ✅
- `00104E       2866  pne_sample_directory:` ✅ (= ROM 内 addr 0x104E)

### 条件 3: directory data 34 byte が ROM 内に embed ✅

`pne_sample_directory` が ROM addr 0x104E から 34 byte 連続配置。 entry 0 (= 17 byte: PMDNEO01.PNE + 0x00) + terminator (= 17 byte: NUL × 16 + 0xFF) の構造。

### 条件 4: 既存 regression に影響なし (= 静的論証) ✅

α は data placement only:

- 既存 routine の logic は 1 行も変更していない (= 機械的 diff で確認可)
- `.equ` 1 行追加 (= linker symbol 定義のみ、 runtime に影響なし)
- `.db` 34 byte 追加 (= ROM 内 data segment 末尾、 既存 code 領域に影響なし)
- driver の chip register write 経路は完全不変
- `adpcma_keyon_simple` / `adpcma_volume_hook` / `adpcma_keyoff_hook` は不変
- step 8 で確立した `pmdneo_mn_direct_load_lq_part_addr` も不変 (= α では call insertion しない)

→ 静的論証で「既存 regression が起きる経路がない」 ことを確認。 register trace / audio gate の動的確認は β/γ/δ 各段階で実施。

## scope-out 維持確認

α では以下を一切実装しない:

- resolver routine (= `pmdneo_resolve_sample_table_id`) → β scope
- chain insertion (= `.MN` load chain 末尾への `call`) → γ scope
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
- `adpcma_ch_sample_ptr_table`: 不変
- `adpcma_sample_bd` 〜 `adpcma_sample_top`: 不変
- `adpcma_keyon_simple` / `adpcma_keyoff_hook` / `adpcma_volume_hook`: 不変
- L-Q part 6ch playback path: 不変
- step 8 `pmdneo_mn_direct_load_lq_part_addr`: 不変 (= α では call insertion しない)
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`): 不変
- vromtool.py: 不変
- build pipeline (= `scripts/build-poc.sh`): 不変

## 将来 migration 余地 (= future D3 generated directory)

`pne_sample_directory` は **Step 9 α 時点では proof 用の hand-written static directory** であり、 将来 D3 generated directory (= vromtool.py 拡張 or 別 script で `.PNE` 群から自動生成) へ migration 可能。 D1 hand-written は最終 directory ownership ではない (= ADR-0023 §決定 3 整合)。

future contributor が hand-written directory を恒久仕様と誤解しないよう、 D3 migration sprint を起票する際は本 doc の「実装差分 #3」 を更新し、 directory ownership 区分を generated artifact (= ADR-0021 §3 層 ownership) 側に移すことを想定する。

## 次 step (= β scope)

- `pmdneo_resolve_sample_table_id` routine 単体実装 (= directory compare + match/mismatch sentinel store)
- routine 本体は `standalone_test.s` 内、 directory data と隣接配置を想定
- call insertion は γ scope のため、 β では routine だけ作って call は **しない**
- β primary gate = build PASS + routine size sanity + register trace = α と byte-identical (= call されていないため挙動同一)

## 関連

- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 1-12
- [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) (= step 8 完了状態、 PNE runtime block の出発点)
- ADR-0023 §決定 9: sub-sprint 分割 α/β/γ/δ
- ADR-0023 §決定 11: Step 9 内で `sample_table_id` は playback decision に使用しない (= 本 α で 0xFD32 を確保するが、 playback 経路は touch しない遵守確認)
