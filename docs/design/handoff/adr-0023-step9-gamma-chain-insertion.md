# ADR-0023 step 9 γ handoff: `.MN` load chain への call insertion + memory inspection primary gate (= match fixture) + α 補正

- 日付: 2026-05-13 (= 10th session、 γ 着手)
- 対応 ADR: [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 6 / §決定 9 γ (= γ 改訂版)
- 関連 commit: 本 handoff doc を含む γ 着手 commit

## γ scope (= 1 commit + 1 push)

- `pmdneo_mn_direct_load_lq_part_addr` (= Step 8 filename copy routine) の末尾 filename copy 完了直後 + lq_idx 計算前に `call pmdneo_resolve_sample_table_id` を 1 行挿入
- **α 補正**: directory entry 0 の filename を `PMDNEO01.PNE` → `step5.PNE` に修正 (= γ 着手時 finding 反映、 ADR §決定 5 §γ 着手時 finding 参照)
- **ADR-0023 改訂**: §決定 5 / §決定 3 / §決定 7 / §決定 9 / §scope-in / §完了判定 を finding 反映で統一改訂、 mismatch fixture verify は δ scope へ繰下げ
- **verify script 作成**: `src/test-fixtures/step9/verify-step9-resolver.sh` (= match fixture primary gate、 3 段階 gate)
- **mismatch fixture verify は δ scope に繰下げ** (= 軽量化、 γ commit を膨らませない)

## γ 着手時 finding (= 重要)

call insertion 実装後、 default test01 build で trace 取得 → 0xFD32 への write が **0 件**。 調査結果:

- driver `pmdneo_mn_direct_load_lq_part_addr` は `m_start.bit 2 = 1` でのみ走る (= ADR-0021 `.MN` binary format 由来、 PMDNEO `.MN` mode signature)
- default test01 build は legacy fallback path (= bit 2 = 0) を通り、 filename copy routine 不実行 → 0xFD20-0xFD32 すべて未 touch
- step 8 verify (= ADR-0022 §決定 7 γ verify-step8-filename-observation.sh) は `src/test-fixtures/step5/l-q-rhythm-song.mml + PMDDOTNET_MODE=B` で `.MN` direct path を起動して trace 取得していた
- 当該 fixture の embedded filename = **"step5.PNE"** (= step 5 命名 history value)
- ADR-0023 α 起票時に entry 0 = "PMDNEO01.PNE" としたのは asset pipeline canonical asset 名 (= `assets/pne/PMDNEO01.PNE`)、 driver runtime が読み込む filename ではなかった

責務差の明示 (= future contributor 向け):

- **`PMDNEO01.PNE`** = asset pipeline canonical asset 名 (= `assets/pne/PMDNEO01.PNE`)、 build-time に VROM へ pack される `.PNE` ファイルの実 filename
- **`step5.PNE`** = runtime filename observation fixture (= step 8 fixture で `.MN` に embed されている filename、 driver runtime に実 copy される文字列)

両者は別レイヤーの命名で、 future multi-`.PNE` 化や D3 generated directory への migration では明示的に関係を詰める必要がある (= scope-out、 step 10+ で扱う)。

対処 (= A1 採用、 user 判断): directory entry 0 を "step5.PNE" に修正、 ADR-0023 改訂、 既存 step 8 fixture を γ match fixture として再利用 (= 新規 fixture 不要、 scope 最小)。

## 実装差分

### 1. directory entry 0 修正 (= `standalone_test.s` line ~2867)

旧 (= α 319aa3c 時点):
```
;; entry 0: filename = "PMDNEO01.PNE" (= 12 char + 4 NUL pad = 16 byte)
;;          sample_table_id = 0x00
.db     0x50, 0x4D, 0x44, 0x4E, 0x45, 0x4F, 0x30, 0x31   ; "PMDNEO01"
.db     0x2E, 0x50, 0x4E, 0x45, 0x00, 0x00, 0x00, 0x00   ; ".PNE\0\0\0\0"
.db     0x00                                              ; sample_table_id = 0x00
```

新 (= γ 改訂):
```
;; entry 0: filename = "step5.PNE" (= 9 char + 7 NUL pad = 16 byte)
;;          sample_table_id = 0x00
;;
;; γ 改訂 (= ADR-0023 §決定 5): α 時点では "PMDNEO01.PNE" としたが、 これは
;; asset pipeline canonical asset 名で、 driver runtime filename buffer
;; (= 0xFD20-0xFD2F) に実 copy される文字列ではない。 step 8 で確立した
;; runtime fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) では
;; "step5.PNE" が流れるため、 runtime resolver の match fixture もそれに合わせる。
.db     0x73, 0x74, 0x65, 0x70, 0x35, 0x2E, 0x50, 0x4E   ; "step5.PN"
.db     0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; "E\0\0\0\0\0\0\0"
.db     0x00                                              ; sample_table_id = 0x00
```

### 2. call insertion (= `pmdneo_mn_direct_load_lq_part_addr` line 3115-3122)

挿入位置: `pmdneo_mn_pne_fn_copy_done:` 直後 + `pop hl` 前 (= filename copy 完了直後、 lq_idx 計算前)

```
pmdneo_mn_pne_fn_copy_done:
        ;; ★ ADR-0023 step 9 γ: filename copy 完了後 → sample_table_id resolve
        ;; resolver は driver_pne_filename_buf を読み、 0xFD32 に id を保存
        ;; HL/DE/BC は resolver 内で clobber されるが、 直後の pop hl で
        ;; offset_table base を復元するため caller への影響なし
        ;; ADR-0023 §決定 6 timing: filename copy 完了後の独立 routine call
        ;; ADR-0023 §決定 11: 0xFD32 は本 routine 完了後 playback decision に使用しない
        call    pmdneo_resolve_sample_table_id
        pop     hl                      ; restore offset_table base
```

#### 設計判断

- ADR-0023 §決定 6 「末尾、 既存 ret 直前」 を **「filename copy routine block の末尾、 lq_idx 計算前」** として解釈
- 配置根拠: HL/DE/BC が resolver 内で clobber されるが、 直後の `pop hl` で offset_table base を自然復元 → push/pop 命令追加なし、 register pressure 最少
- L-Q 6 part init で 6 回 call (= ADR-0022 step 8 と同じパターン)。 idempotent なので trace 6 件、 値は常に同一

### 3. ADR-0023 改訂

- **§決定 5**: 初期 directory 内容を "step5.PNE" 化 + **§γ 着手時 finding section 新規追加** (= 責務差明示、 history 保持)
- **§決定 3 / §決定 7 / §scope-in / §完了判定**: "PMDNEO01.PNE" 言及を "step5.PNE" に統一 (= finding 内 history reference は保持)
- **§決定 9 sub-sprint 分割表**: γ は match fixture primary gate のみ、 mismatch fixture verify を **δ scope へ繰下げ**
- §完了判定: numbering 1 項目増 (= γ で α 補正、 δ で mismatch fixture が独立項目)

### 4. verify-step9-resolver.sh 作成 (= `src/test-fixtures/step9/verify-step9-resolver.sh`)

3 段階 gate (= γ scope 最小):

| gate | 検証内容 |
|---|---|
| 1 | l-q-rhythm-song.mml + PMDDOTNET_MODE=B 経由 build + trace 取得 |
| 2 | 0xFD32 (= driver_pne_sample_table_id) への write が trace に存在 (= 6 件 expected = L-Q 6 part idempotent) |
| 3 | 0xFD32 = 0x00 (= match value、 directory entry 0 "step5.PNE" と embedded filename "step5.PNE" 一致、 全 write idempotent) |

mismatch fixture verify (= 0xFD32 = 0xFF) / step 5/6/7/8 既存 verify script regression / audible regression / register trace = step 8 byte-identical 確認 は δ scope。

## 動作確認 (= γ 完了条件 4 件)

### 条件 1: build PASS ✅

`PMDDOTNET_MML=src/test-fixtures/step5/l-q-rhythm-song.mml PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh` 完了表示。 sdasz80 / sdldz80 / sdobjcopy / vromtool.py すべて PASS。

### 条件 2: call insertion 動作 (= 0xFD32 への write 検出) ✅

trace 解析: 0xFD32 への write **6 件検出** (= L-Q 6 part init で idempotent 呼出、 PC = 0x1090 = `pmdneo_resolve_sample_table_id` 内 match path)。

### 条件 3: match primary gate PASS (= 0xFD32 = 0x00) ✅

0xFD32 = **0x00** (= match value、 全 6 件 idempotent)。 directory entry 0 "step5.PNE" と embedded filename "step5.PNE" の一致を resolver が正しく判定。

### 条件 4: α 補正 + ADR 改訂完了 ✅

- directory entry 0: "PMDNEO01.PNE" → "step5.PNE" (= 16 byte 上書き) 反映済
- ADR-0023 §決定 5 §γ 着手時 finding 新規 section 追加済
- ADR-0023 §決定 3/7/9/scope-in/完了判定 改訂済
- verify script 作成済 (= 全 3 gate PASS)

## γ scope の重要境界 (= future contributor 向け)

**γ では resolver の match path (= 0xFD32 = 0x00) のみ検証済み。 mismatch path (= 0xFD32 = 0xFF) は δ で検証する。** resolver routine `pmdneo_resolve_sample_table_id` には directory loop の match branch と terminator hit branch の 2 経路があり、 γ では前者のみ trace で実走確認した。 後者の dynamic 確認は δ scope。

γ 時点で確認したのは **match fixture (= 0xFD32 = 0x00)** のみ。 次の挙動は **δ で初めて検証**:

- **mismatch fixture** (= directory に存在しない filename を持つ fixture): 0xFD32 = 0xFF
- **既存 verify regression** (= step 5/6/7/8 verify script 全件 PASS): chip register write path 不変確認
- **audible regression** (= silent-bcef fixture): step 9 で sample playback 経路に影響がないことを聴感確認
- **register trace = step 8 byte-identical**: call insertion 1 行のみ追加で、 既存 chip register write は完全不変であることの動的確認

つまり γ 完了は **「resolver が match path を正しく走る」** ことを保証し、 **「mismatch path も正しく走る」** + 「既存音不変」 は δ scope。 future contributor が「γ で resolver 完全動作確認済」 と誤解しないよう明示。

## scope-out 維持確認

γ では以下を一切実装しない:

- mismatch fixture verify → δ scope
- step 5/6/7/8 既存 verify script 全件 regression → δ scope
- audible regression (= silent-bcef fixture) → δ scope
- register trace = step 8 byte-identical 確認 → δ scope
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
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`): 不変
- vromtool.py: 不変
- build pipeline (= `scripts/build-poc.sh`): 不変
- `pmdneo_resolve_sample_table_id` routine 本体 (= β で実装): 不変 (= γ は call insertion のみ、 routine 内部不変)
- Step 8 `pmdneo_mn_direct_load_lq_part_addr` の filename copy 経路 (= line 3094-3115): 不変 (= γ は末尾に `call` 1 行追加のみ、 既存 logic は完全不変)

## 次 step (= δ scope)

- mismatch fixture verify (= 0xFD32 = 0xFF) の整備
  - 方法候補: directory entry binary patch / 別 fixture MML 作成 / 一時 directory 改変 build
  - 軽量化方針 (= user 方針): 無理に fixture file 増やさない、 verify script 内で一時改変等を活用
- step 5/6/7/8 既存 verify script 全件 PASS 確認 (= regression なし)
- silent-bcef fixture (= step 6-a) で audible regression なし最終確認
- step 9 完了統合 handoff doc 作成 (= adr-0023-step9-completion.md)
- ADR-0023 Accepted 移行 + commit + push

## 関連

- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 5 §γ 着手時 finding / §決定 6 / §決定 9 γ
- [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) (= filename copy routine の出発点、 fixture 「step5.PNE」 の出自)
- [ADR-0023 step 9 α handoff](adr-0023-step9-alpha-state-cell-directory.md) (= directory data 配置の初版、 γ で entry 0 修正)
- [ADR-0023 step 9 β handoff](adr-0023-step9-beta-resolver-routine.md) (= resolver routine 単体実装、 γ で初めて call される)
- ADR-0023 §決定 11: Step 9 内で `sample_table_id` は playback decision に使用しない (= γ で 0xFD32 = 0x00 を書込んでも playback 経路は不参照、 既存音不変)
- `feedback_record_unexpected_findings.md` (= γ 着手時 finding を memory に保存対象として記録、 適用)
