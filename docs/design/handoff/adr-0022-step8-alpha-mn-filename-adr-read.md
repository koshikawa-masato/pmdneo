# ADR-0022 step 8 α handoff: `.MN` header から `pne_filename_adr` 読込 + workarea word 保存

- 日付: 2026-05-13 (= 9th session、 α 着手)
- 対応 ADR: [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) §決定 7 α
- 関連 commit: 本 handoff doc を含む α 着手 commit

## α scope (= 1 commit + 1 push)

- `src/driver/standalone_test.s` の `.MN` parser (= `pmdneo_mn_direct_load_lq_part_addr`) に `pne_filename_adr` field 読込経路追加
- 読んだ値 (= LE u16、 m_buf-relative) を `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) に保存
- `.equ` 定義追加 (= `driver_pne_filename_buf` / `driver_pne_filename_adr_word`)
- SRAM layout コメント更新 (= PNE runtime observation block を明記)
- filename string copy は実装しない (= β scope)
- buffer (= 0xFD20-0xFD2F) は未使用のまま (= β scope)
- overflow 規約も β scope

## 実装差分

### 1. `.equ` 定義追加 (= `standalone_test.s` line ~115)

```
        .equ    part_workarea,           0xF820
        ;; 20 x 64 = 1280 bytes occupies 0xF820-0xFD1F (= ADR-0006 §A 20 part)

        ;; ADR-0022 step 8: PNE runtime observation block (= 0xFD20-0xFD31, 18 byte)
        ;;   driver_pne_filename_buf      0xFD20-0xFD2F  16 byte  NUL-terminated ASCII (= β scope、 α 未使用)
        ;;   driver_pne_filename_adr_word 0xFD30-0xFD31   2 byte  LE u16 (= m_buf-relative pne_filename_adr)
        ;; α: pne_filename_adr word のみ書込、 buffer は未使用 (= ADR-0022 §決定 7 α scope)
        .equ    driver_pne_filename_buf,       0xFD20
        .equ    driver_pne_filename_adr_word,  0xFD30
```

### 2. SRAM layout コメント更新

```
;;; ----- Z80 SRAM layout (= 2 KB at 0xF800-0xFFFF) -----
;;;
;;;   0xF800 - 0xF80F   reserved future (16 bytes、cmd FIFO 検討中)
;;;   0xF810 - 0xF81F   driver_state (= 16 bytes 既存)
;;;   0xF820 - 0xFD1F   part_workarea (= 20 x 64 = 1280 bytes、ADR-0006 §A)
;;;   0xFD20 - 0xFD2F   driver_pne_filename_buf (= 16 bytes、ADR-0022 §決定 4、 β scope で使用)
;;;   0xFD30 - 0xFD31   driver_pne_filename_adr_word (= 2 bytes、ADR-0022 §決定 4、 α scope)
;;;   0xFD32 - 0xFFBF   free / 後続 phase 用 (= 654 bytes 余裕)
;;;   0xFFC0 - 0xFFFF   Z80 stack (= 64 bytes 既存、ld sp, #0xFFFF 起点)
```

### 3. `pne_filename_adr` 読込挿入 (= `pmdneo_mn_direct_load_lq_part_addr` 内)

挿入位置: `extended_data_adr` 読込直後、 `offset_table_base` 計算後、 `offset_table[lq_idx]` 計算前。

```
        ;; offset_table_base = pmddotnet_song + 1 + extended_data_adr
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = offset_table file addr

        ;; ★ ADR-0022 step 8 α: pne_filename_adr observation
        ;; pne_filename_adr field file addr = offset_table_base + 12 (= m_buf 相対 +12..13)
        ;; α scope: word を 0xFD30-0xFD31 に保存するのみ (= string copy は β、 §決定 7)
        push    hl                      ; preserve offset_table base
        ld      bc, #12
        add     hl, bc                  ; HL = pne_filename_adr field file addr
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = pne_filename_adr (LE u16、 m_buf-relative)
        ld      (driver_pne_filename_adr_word), de  ; store to 0xFD30-0xFD31
        pop     hl                      ; restore offset_table base
```

#### 設計判断

- 挿入位置を `pmdneo_mn_direct_load_lq_part_addr` 内に置く理由: 既存 `extended_data_adr` 読込と同一 routine。 register / pointer 計算が再利用でき、 routine 追加が不要。
- L-Q 6 part 各 init で 6 回同じ値を書き込む (= idempotent)。 trace に 6 件出るが、 値は常に同一 (= consistency が trace gate)。
- `push hl` / `pop hl` で offset_table base を保存し、 既存 logic (= offset_table[lq_idx] 計算) が完全不変。
- BC は 12 で clobber するが、 routine entry / exit で BC 保存規約なし (= caller が次 `call` 前に BC reload)。

## 動作確認 (= α 完了条件 5 件)

### 条件 1: `.MN` binary 上の `pne_filename_adr` と `driver_pne_filename_adr_word` が一致 ✅

- `.MN` binary 解析:
  - file size: 395 byte
  - `m_start`: 0x04 (= PMDNEO mode flag)
  - `extended_data_adr` (= m_buf[26..27]): 0x0027 (= 39)
  - `pne_filename_adr` (= ext_adr +12..13): **0x00A4 (= 164)**
  - filename string: `'step5.PNE'` (9 char + NUL)

- z80-mem-trace.tsv 観測:
  - 0xFD30 への write: **0xA4** (= LSB)
  - 0xFD31 への write: **0x00** (= MSB)
  - → `driver_pne_filename_adr_word` = **0x00A4**
  - PC = 0x10EB (= 同一 instruction、 L-Q 6 part init で 6 回 同値書込)

- → **完全一致** (= expected 0x00A4、 observed 0x00A4)

### 条件 2: 0xFD20-0xFD2F filename buffer は未使用 ✅

- z80-mem-trace.tsv で 0xFD20-0xFD2F への write 件数: **0 件**
- 0xFD32 以降への write 件数 (= 副作用 check): **0 件**
- → α scope 厳守 (= buffer は β で初めて使用される、 §決定 7 α 通り)

### 条件 3: ADPCM-A register writes は既存 Step 5/6/7 と同等 ✅

- `verify-l-q-tutti-gamma.sh` (= step 5 γ regression、 6 gate): **全 PASS**
  - gate 2: workarea independence ✅
  - gate 3: ch overlap (= 6 ch sample addr 全 unique) ✅
  - gate 4: register isolation (= start/stop/vol/pan × 6 ch) ✅
  - gate 5: simultaneous keyon (= ch 0-5 全 bit) ✅
  - gate 6: MSB 同一性 ✅
- wav sha256: `17bd67aa0fca4b27096d54edbf928a455ed88ff01593a9e52d4a5b87368be436` (= L-Q tutti reference)
- → ADPCM-A path 完全不変

### 条件 4: silent-bcef fixture で audible regression なし ✅

- `verify-silent-bcef-audio-isolation.sh` (= step 6-a regression、 7 gate): **全 PASS**
  - gate F: FM keyon = **0 件** (= audio isolation 成立、 silent-bcef fixture B/C/E/F mute)
  - gate 5: simultaneous + rhythm keyon = 39 件
  - 他 gate (= workarea / ch overlap / vol/pan / register isolation) 全 PASS
- wav sha256: `2611716cc0ab824e20a46cecab5d1b72ab9cf166ef45240253f50713ce98ba4f` (= silent-bcef reference)
- → audio isolation 戦略維持、 audible regression なし

### 条件 5: handoff doc に「α は address observation のみ、 string observation は β」 と明記 ✅

- 本 handoff doc §α scope 冒頭で明示
- `filename string copy は実装しない (= β scope)`
- `buffer (= 0xFD20-0xFD2F) は未使用のまま (= β scope)`
- `overflow 規約も β scope`

## 追加 regression check

α が build pipeline / converter / ROM final byte-identical を破壊しないことを補強:

### step 7 δ regression: `.MN` filename embed 維持 ✅

- `verify-step7-delta-mn-filename-embed.sh` (= 4 gate): **全 PASS**
  - gate 1: `m_start` = 0x04 ✅
  - gate 2: `extended_data_adr` = 0x0027 ✅
  - gate 3: `pne_filename_adr` = 0x00A4 ✅
  - gate 4: filename string = `'step5.PNE'` (NUL-terminated) ✅

### step 7 β-3 regression: samples.inc + VROM byte-identical ✅

- `verify-step7-b3-byte-identical.sh` (= 4 gate): **全 PASS**
  - samples.inc sha256: `74f2aec8f8859e062dd835470813788d889288d17c6716a5a46c2ddac0393ae4`
  - VROM 1: `c77f0888949aae30a1c67109a067dc0c08b915519de2593fbb128148ad6bc060`
  - VROM 2/3/4: `bb9f8df61474d25e71fa00722318cd387396ca1736605e1248821cc0de3d3af8`
- ROM final byte-identical は driver 改修ありのため厳密には保証されないが、 samples.inc / VROM 不変 + ADPCM-A path 不変から audible output 不変が成立。

## α 完了判定

| # | 条件 | 達成 |
|---|---|---|
| 1 | `.MN` binary 上の `pne_filename_adr` と `driver_pne_filename_adr_word` が一致 | ✅ (= 0x00A4 一致) |
| 2 | 0xFD20-0xFD2F filename buffer は未使用 | ✅ (= 0 writes) |
| 3 | ADPCM-A register writes は既存と同等 | ✅ (= step 5 γ regression PASS) |
| 4 | silent-bcef fixture で audible regression なし | ✅ (= step 6-a regression PASS) |
| 5 | handoff doc に「α は address observation のみ」 と明記 | ✅ (= 本 doc) |

→ **5/5 達成、 α 完了**

## β scope (= 次の commit)

- `pne_filename_adr` を pointer follow + filename string を `driver_pne_filename_buf` (= 0xFD20-0xFD2F) に copy
- overflow 規約適用 (= 15 byte copy + byte15 = 0x00 + trace warning)
- trace gate: runtime buffer の中身が `.MN` filename string と byte-identical

## α で touch しなかったもの (= 決定 8 厳守)

- `assets/samples.inc` (= 生成 sample include)
- VROM (= ngdevkit-examples 経由 ROM build pipeline)
- driver の sample lookup routine (= `adpcma_ch_sample_ptr_table` voice index 引き)
- ADPCM-A register writes (= keyon / keyoff / volume / pan / freq)
- L-Q part 6ch 経路 (= step 5 完成)
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`)
- build pipeline (= `vendor/Makefile` / `scripts/build-poc.sh`)
- 0xFD20-0xFD2F filename buffer (= β scope)
- overflow 規約 (= β scope)
- filename → sample table resolve (= 永続的に scope-out)
- multi-`.PNE` switching (= 永続的に scope-out)

→ ADR-0022 §決定 8「既存 sample playback path は完全不変」 literal 遵守。
