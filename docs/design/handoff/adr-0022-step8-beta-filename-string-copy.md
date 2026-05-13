# ADR-0022 step 8 β handoff: filename string copy + buffer observation 成立

- 日付: 2026-05-13 (= 9th session、 β 着手)
- 対応 ADR: [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) §決定 7 β
- 関連 commit: 本 handoff doc を含む β 着手 commit
- 前段: [α handoff](adr-0022-step8-alpha-mn-filename-adr-read.md) (= `pne_filename_adr` word observation 完了)

## β scope (= 1 commit + 1 push、 β-A 採用)

- `pne_filename_adr` を pointer follow して filename string を runtime buffer に copy
- copy 先 = `driver_pne_filename_buf` (= 0xFD20-0xFD2F、 16 byte)
- NUL-terminated ASCII を最大 15 byte copy + 早期終了
- overflow path 実装 (= 15 byte 全 copy で NUL 未検出時、 byte15 強制 NUL + halt せず継続)
- β-A 採用: 通常 contract (= DOS 8.3 / NUL-terminated) を通すのみ、 16+ byte fixture verify は γ / future hardening sprint に回す
- α の `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) は read のみで保持

## β-A 採用理由 (= user 判断)

- Step 8 は runtime filename observation sprint、 本命は「driver が `.MN` 内 filename string を runtime buffer に持てること」
- 16+ byte fixture は edge-case hardening であり、 β の主目的ではない
- fixture を増やすと mc compiler / `.MN` 改変 / artificial binary patch の論点が混ざる
- まず通常 contract = DOS 8.3 / NUL-terminated ASCII を通す方が安全

## 実装差分

### filename string copy logic 挿入 (= α 直後、 `pmdneo_mn_direct_load_lq_part_addr` 内)

α の `pop hl` (= offset_table base 復帰) 直後、 `offset_table[lq_idx]` 計算前に挿入:

```
        ;; ★ ADR-0022 step 8 β: filename string copy (= 0xFD20-0xFD2F buffer)
        ;; filename string file addr = pmddotnet_song + 1 + pne_filename_adr
        ;; β scope: NUL-terminated ASCII を最大 15 byte copy + byte15 強制 NUL (= §決定 5 overflow 規約)
        ;; β-A: 通常 contract (= DOS 8.3 / NUL-terminated) を通すのみ、 16+ byte fixture verify は γ / future
        push    hl                      ; preserve offset_table base
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = filename string file addr
        ld      de, #driver_pne_filename_buf  ; DE = 0xFD20 (buffer 先頭)
        ld      b, #15                  ; max non-NUL byte 数 (= byte15 は overflow 時 NUL 用に予約)
pmdneo_mn_pne_fn_copy_loop:
        ld      a, (hl)
        ld      (de), a                 ; copy 1 byte (= NUL も含めて write)
        or      a
        jr      z, pmdneo_mn_pne_fn_copy_done  ; A = NUL → 早期終了 (= 通常 path)
        inc     hl
        inc     de
        djnz    pmdneo_mn_pne_fn_copy_loop
        ;; overflow path: 15 byte 全 copy で NUL 未検出 (= source filename ≥ 16 byte)
        ;; byte15 (= 0xFD2F) を強制 NUL、 driver halt せず継続 (= §決定 5)
        xor     a
        ld      (de), a                 ; (DE) = 0xFD2F = 0x00 強制
pmdneo_mn_pne_fn_copy_done:
        pop     hl                      ; restore offset_table base
```

### 設計判断

- 挿入位置を `pmdneo_mn_direct_load_lq_part_addr` 内に置く理由: α と同 routine、 DE = `pne_filename_adr` を直接利用可。
- L-Q 6 part init 各回で copy 実行 (= idempotent、 6 回同値書込)。 trace に 6 回 × 10 byte = 60 件出るが、 buffer の最終値は常に `"step5.PNE\0"`。
- 早期終了は `ld (de), a` で NUL を書いた後に `or a; jr z` で判定。 NUL がちゃんと buffer に書かれる。
- overflow path は `djnz` が 0 まで降りた時のみ実行 (= 15 byte 全 copy で NUL 未検出)。 通常 path は通らない。
- `push hl` / `pop hl` で offset_table base を保存し、 既存 logic は完全不変。

## 動作確認 (= β 完了条件 6 件)

### 条件 1: `driver_pne_filename_adr_word` = 0x00A4 のまま (= α 不変保持) ✅

- z80-mem-trace.tsv で 0xFD30/0xFD31 への write:
  - 0xFD30 = 0xA4 (6 回、 全て同値)
  - 0xFD31 = 0x00 (6 回、 全て同値)
- PC = 0x10EB (= α と同一 instruction)
- → α の `driver_pne_filename_adr_word` = 0x00A4 完全保持

### 条件 2: `driver_pne_filename_buf` = `step5.PNE\0` ✅

- z80-mem-trace.tsv で 0xFD20-0xFD2F 各 address への最終値:

| address | value | char |
|---|---|---|
| 0xFD20 | 0x73 | 's' |
| 0xFD21 | 0x74 | 't' |
| 0xFD22 | 0x65 | 'e' |
| 0xFD23 | 0x70 | 'p' |
| 0xFD24 | 0x35 | '5' |
| 0xFD25 | 0x2E | '.' |
| 0xFD26 | 0x50 | 'P' |
| 0xFD27 | 0x4E | 'N' |
| 0xFD28 | 0x45 | 'E' |
| 0xFD29 | 0x00 | NUL |
| 0xFD2A | (no write) | — |
| 0xFD2B | (no write) | — |
| 0xFD2C | (no write) | — |
| 0xFD2D | (no write) | — |
| 0xFD2E | (no write) | — |
| 0xFD2F | (no write) | — |

- → `driver_pne_filename_buf[0..9]` = `"step5.PNE\0"` byte-identical (= `.MN` filename string と一致)
- → 0xFD2A-0xFD2F 未書込 (= 通常 path の早期終了で touch せず、 期待動作)

### 条件 3: filename buffer write が trace で確認できる ✅

- 0xFD20-0xFD29 への write 総件数: **60 件** (= 10 byte × 6 部位)
- PC = 0x10F8 (= 同一 loop instruction、 L-Q 6 部位 init で同 logic 再実行)
- 0xFD2A-0xFD2F への write 件数: **0 件**
- → trace 観測完璧

### 条件 4: sample lookup / ADPCM-A register writes / VROM / samples.inc は不変 ✅

- `verify-l-q-tutti-gamma.sh` (= step 5 γ regression、 6 gate): **全 PASS**
  - wav sha256: `30a5083f55903fb6b54a982ac785baeaa2e53ac75027c229e1d92f8a60f9fa0a` (= α と異なるが β 追加 instruction 由来の timing shift、 register trace primary gate は同等)
- `verify-step7-b3-byte-identical.sh` (= step 7 β-3 regression、 4 gate): **全 PASS**
  - samples.inc sha256: `74f2aec8f8859e062dd835470813788d889288d17c6716a5a46c2ddac0393ae4` (= α と完全一致)
  - VROM 1-4 sha256: 全 byte-identical (= α と完全一致)
- → ADPCM-A path / build pipeline 完全不変

### 条件 5: silent-bcef audible regression なし ✅

- `verify-silent-bcef-audio-isolation.sh` (= step 6-a regression、 7 gate): **全 PASS**
  - gate F: FM keyon (= reg 0x28) = **0 件** (= audio isolation 維持)
  - gate 5: simultaneous + rhythm keyon = **39 件** (= L-Q audible 維持)
- → audible regression なし

### 条件 6: handoff doc に「overflow path implemented, overflow fixture not included in β」 と明記 ✅

- 本 handoff doc §β scope 冒頭で明示:
  - `overflow path 実装 (= 15 byte 全 copy で NUL 未検出時、 byte15 強制 NUL + halt せず継続)`
  - `β-A 採用: 通常 contract (= DOS 8.3 / NUL-terminated) を通すのみ、 16+ byte fixture verify は γ / future hardening sprint に回す`

## β 完了判定

| # | 条件 | 達成 |
|---|---|---|
| 1 | `driver_pne_filename_adr_word` = 0x00A4 (= α 不変保持) | ✅ |
| 2 | `driver_pne_filename_buf` = `step5.PNE\0` | ✅ (= 0xFD20-0xFD29 byte-identical) |
| 3 | filename buffer write が trace で確認できる | ✅ (= 60 件 write 検出) |
| 4 | sample lookup / ADPCM-A register writes / VROM / samples.inc は不変 | ✅ (= step 5 γ / step 7 β-3 regression PASS) |
| 5 | silent-bcef audible regression なし | ✅ (= step 6-a regression PASS) |
| 6 | handoff doc に「overflow path implemented, overflow fixture not included in β」 と明記 | ✅ (= 本 doc) |

→ **6/6 達成、 β 完了**

## β で touch しなかったもの (= 決定 8 厳守)

- `assets/samples.inc` (= 生成 sample include) — byte-identical 確認済
- VROM (= ngdevkit-examples 経由 ROM build pipeline) — byte-identical 確認済
- driver の sample lookup routine (= `adpcma_ch_sample_ptr_table` voice index 引き)
- ADPCM-A register writes (= keyon / keyoff / volume / pan / freq)
- L-Q part 6ch 経路 (= step 5 完成)
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`)
- build pipeline (= `vendor/Makefile` / `scripts/build-poc.sh`)
- α で書いた 0xFD30-0xFD31 の word (= β は read のみ、 値は完全一致で保持)
- filename → sample table resolve (= 永続的に scope-out)
- multi-`.PNE` switching (= 永続的に scope-out)
- 16+ byte filename fixture / overflow fixture (= β-A 採用で γ / future へ)

→ ADR-0022 §決定 8「既存 sample playback path は完全不変」 literal 遵守。

## γ scope (= 次の commit)

- filename runtime observation 用 trace gate script 整備 (= `src/test-fixtures/step8/verify-step8-filename-observation.sh` 等)
- step 5/6/7 既存 verify script 全件 regression 再確認 (= γ で 1 commit にまとめる)
- MAME 試聴で audible regression なし最終確認 (= step 6-a silent-bcef fixture)
- ADR-0022 完了統合 + Accepted 移行

## 観察事項 (= future contributor 向け)

### β で確立した runtime state

```
Z80 SRAM after song init (= PMDNEO mode .MN load 完了):
  0xFD20: 0x73 's'
  0xFD21: 0x74 't'
  0xFD22: 0x65 'e'
  0xFD23: 0x70 'p'
  0xFD24: 0x35 '5'
  0xFD25: 0x2E '.'
  0xFD26: 0x50 'P'
  0xFD27: 0x4E 'N'
  0xFD28: 0x45 'E'
  0xFD29: 0x00 NUL
  0xFD2A-0xFD2F: (uninitialized、 buffer 残余)
  0xFD30: 0xA4 (pne_filename_adr LSB)
  0xFD31: 0x00 (pne_filename_adr MSB)
  = "step5.PNE" + NUL + 6 byte uninitialized + 0x00A4 (= LE u16 pne_filename_adr)
```

これで `.MN` ↔ `.PNE` の build-time contract が runtime にも届いた。 driver は filename string と its source address の両方を runtime state として保持する。

### overflow path は実装済だが未 verify

- code path は実装 (= `djnz` 落ち後の `xor a; ld (de), a`)
- 通常 fixture (= `step5.PNE` = 9 char) では overflow path 不通過
- 16+ byte filename fixture を作って overflow path 動作確認するのは β-A scope-out
- γ scope-out、 future hardening sprint で扱う

### β を `pmdneo_mn_direct_load_lq_part_addr` 内に置いた選択

L-Q 6 部位 init 各回で同 logic 実行 (= 6 回 redundant copy)。 idempotent なため副作用なし、 trace 量は増えるが verify ロジックには影響なし。 future の resolver 化 (= sub-B / sub-C) で「filename を 1 回だけ resolve したい」 要件が出た時に、 song init 1 回呼出への refactor を検討。
