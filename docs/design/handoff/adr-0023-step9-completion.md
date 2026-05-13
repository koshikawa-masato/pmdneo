# ADR-0023 step 9 δ completion handoff: runtime `.PNE` filename → `sample_table_id` resolver sprint 完了統合 + ADR Accepted 移行

- 日付: 2026-05-13 (= 10th session、 δ 完了統合)
- 対応 ADR: [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 9 δ + §完了判定 全 12 項目
- 関連 commit: 本 handoff doc を含む δ 完了統合 commit

## step 9 全体 sum-up

PMDNEO step 9 は **runtime `.PNE` filename → `sample_table_id` resolver** を「identity resolution まで」 の最小成立形で完成させた sprint。 ADR-0022 step 8 で確立した「filename を runtime で読める」 状態を 1 段だけ延伸し、 「filename を runtime key として使い、 sample table identity を resolve する」 段階まで進めた。 ただし sample table address 引き / `adpcma_keyon` refactor / `.PNE` binary parse / multi-`.PNE` switching は意図的に scope-out 維持し、 既存 playback path に 1 命令も影響しない。

### α/β/γ/δ 段階分離の本質

| sub | 出口像 | 0xFD32 状態 | 既存 playback path |
|---|---|---|---|
| α | state cell + directory data 配置 (= 置き場と表のみ) | 確保されたが書込みなし | 不変 |
| β | resolver routine 単体実装 (= routine 存在、 call なし) | 確保されたが書込みなし (= dead code) | 不変 |
| γ | `.MN` load chain への call insertion + match primary gate | **書込み発生** (= 0xFD32 = 0x00 match、 6 件 idempotent) | 不変 |
| δ | mismatch primary gate + 既存 regression + audible + Accepted 移行 | match + mismatch 両 path 動的検証完了 | 不変 |

この **「作る → 置く → 呼ぶ → 検証する」 4 段階分離** により、 各段で trivial verify (= 何もしていないのに PASS) を切り分けた。 結果として false PASS のリスクを literal に排除した。

### Step 9 の核心メッセージ

```
Step 8: filename を runtime で「読める」
Step 9: filename を runtime で「使える」 (= identity 段階まで)
Step 10+: identity を「消費する」 (= sample table addr / playback path 接続、 別 sprint)
```

「読む → 使う → 消費する」 という Step 8/9/10+ の役割分離が、 既存 playback path を破壊せずに runtime resolver を段階的に成立させる設計言語として機能した。

## 完了条件達成サマリ

ADR-0023 §完了判定 全 **12/12 項目達成**:

| # | 項目 | 達成 |
|---|---|---|
| 1 | α: state cell 定義 + WORKAREA | ✅ |
| 2 | α: hand-written directory 追加 + symbol export | ✅ (= γ で entry 0 補正含む) |
| 3 | β: resolver routine 単体実装 | ✅ |
| 4 | β: routine size sanity + byte-identical (dead code) | ✅ |
| 5 | γ: `.MN` load chain への call insertion | ✅ |
| 6 | γ: match primary gate (= 0xFD32 = 0x00) | ✅ |
| 7 | γ: α 補正 + ADR §決定 5 改訂 (= finding 反映) | ✅ |
| 8 | δ: mismatch primary gate (= 0xFD32 = 0xFF) | ✅ |
| 9 | δ: verify infra 整備 (= 5 段階 gate) | ✅ |
| 10 | δ: step 5/6/7/8 既存 verify script 全件 PASS | ✅ |
| 11 | δ: MAME 試聴で audible regression なし | ✅ |
| 12 | δ: 完了統合 handoff doc + ADR Accepted 移行 | ✅ |

## 実装差分まとめ (= file ごと)

### `src/driver/standalone_test.s` (= driver source、 4 段階で +約 120 行)

- **α**: `.equ driver_pne_sample_table_id, 0xFD32` 1 行 + SRAM layout コメント更新 + `pne_sample_directory` 34 byte data 追加
- **β**: `pmdneo_resolve_sample_table_id` routine 47 byte (= 0x1070-0x109E、 directory loop + terminator check + 16 byte memcmp + match/mismatch sentinel store)
- **γ**: `pmdneo_mn_direct_load_lq_part_addr` 末尾 filename copy 完了直後に `call pmdneo_resolve_sample_table_id` 1 行追加 + directory entry 0 filename 16 byte 上書き (= "PMDNEO01.PNE" → "step5.PNE" 補正)
- **δ**: source 不変

### `docs/adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md`

- **起票**: 12 決定 + scope-in/out + 完了判定 + 関連 memory/doc + 次 sprint 候補 (= 約 350 行)
- **γ 改訂**: §決定 5 に §γ 着手時 finding section 新規追加 (= 責務差明示) + §決定 3/7/9/scope-in/完了判定 統一改訂
- **δ Accepted 移行**: §完了判定達成状況 section 新規追加 + 状態 Proposed → Accepted

### `docs/design/handoff/` (= 5 doc 新規)

- `adr-0023-step9-alpha-state-cell-directory.md` (= α、 data placement only)
- `adr-0023-step9-beta-resolver-routine.md` (= β、 routine 単体実装 dead code)
- `adr-0023-step9-gamma-chain-insertion.md` (= γ、 call insertion + α 補正 + match gate)
- `adr-0023-step9-completion.md` (= 本 doc、 δ 完了統合)

### `src/test-fixtures/step9/verify-step9-resolver.sh` (= 新規、 5 段階 gate)

| gate | 検証内容 |
|---|---|
| 1 | l-q-rhythm-song.mml + PMDDOTNET_MODE=B build + trace 取得 |
| 2 | 0xFD32 への write が trace に存在 (= 6 件 expected = L-Q 6 part idempotent) |
| 3 | 0xFD32 = 0x00 (= match value、 全 write idempotent) |
| 4 | ROM patch (= entry 0 1 byte 改変、 source 不変、 trap で revert) |
| 5 | 0xFD32 = 0xFF (= mismatch sentinel、 terminator hit path、 全 write idempotent) |

### memory (= `~/.claude/.../memory/`、 git 外)

- `project_pne_directory_entry_runtime_fixture_vs_asset_canonical.md` (= γ 着手時 finding、 責務差 contract)
- `project_pmdneo_step9_complete.md` (= 本 sprint 完了 memory、 δ で別途作成)
- `MEMORY.md` 2 行追記

## verify infra (= 全 gate sum-up)

### step 9 新規 verify (= `verify-step9-resolver.sh`)
- 5 段階 gate 全 PASS (= match + mismatch primary)

### 既存 step 5/6/7/8 verify regression (= δ で 6 件 serial 実行)
- step 6-a silent-bcef audio isolation: **6 段階 gate PASS** (= wav sha256 = `7c028276a803423bb504e4818a0c3b16b3a0b7fc1a3378ab84971bee01b9e47c`、 register isolation 5 reg group × 6 ch)
- step 7 β-1 roundtrip: **4/4 gate PASS**
- step 7 β-3 byte-identical: **PASS** (= samples.inc sha256 = `74f2aec8...`、 VROM 4 件 byte-identical)
- step 7 δ MN filename embed: **PASS** (= "step5.PNE" 9 byte + NUL embed 確認)
- step 7 δ-fix quote strip: **3/3 gate PASS**
- step 8 filename observation: **5 段階 gate PASS** (= 0xFD20-0xFD31 driver SRAM 検証)

**合計 26 gate 全 PASS** (= step 9 新規 5 + 既存 21、 regression なし)

## audible regression 結果

- silent-bcef fixture build + MAME audio playback (= scripts/run-mame.sh)
- user 試聴コメント: **「同じ速さで同じ音がなりました」**
- → audible regression なし、 step 6-a 期と同等 (= ADPCM-A L-Q 6 音、 FM 同居なし、 速度同等)

## §決定 1-12 達成状況 (= ADR-0023 各 §決定の literal 達成)

| §決定 | 内容 | 達成 |
|---|---|---|
| 1 | C2 採用 (= sample table identity resolver として定義) | ✅ |
| 2 | addr 直返却 / keyon refactor / `.PNE` binary parse / multi-bank は scope-out | ✅ (= 全 12 項目 scope-out 維持) |
| 3 | D1 hand-written directory + driver code 内配置 + proof 用 placeholder 明示 | ✅ |
| 4 | PNE runtime block 拡張 (= 0xFD20-0xFD32, 19 byte) | ✅ |
| 5 | directory entry binary 構造 (= 17 byte/entry, fixed length, terminator = 0xFF) | ✅ (= γ で entry 0 を "step5.PNE" 補正 + §γ 着手時 finding 反映) |
| 6 | T3 独立 init routine (= `pmdneo_resolve_sample_table_id`) | ✅ |
| 7 | G2 memory inspection primary + register trace secondary | ✅ |
| 8 | mismatch 振舞い = 0xFF sentinel のみ、 silent flag は scope-out | ✅ |
| 9 | sub-sprint S2 (= α/β/γ/δ 4 段) + 1 sub = 1 commit + 1 push | ✅ (= 5 commit chain = ADR 起票 + α/β/γ/δ) |
| 10 | 既存 sample playback path 完全不変 | ✅ |
| 11 | Step 9 内で `sample_table_id` は playback decision に使用しない | ✅ (= 0xFD32 read 箇所は verify infra のみ、 write 箇所は resolver routine 1 か所のみ) |
| 12 | handoff doc 構造 (= sub-sprint 独立 + completion 別) | ✅ (= 4 handoff doc 作成) |

## §scope-out 維持確認 (= ADR §scope-out 全 12 項目)

| # | scope-out 項目 | 維持 |
|---|---|---|
| 1 | sample table addr 直返却 | ✅ |
| 2 | selected table pointer の runtime use | ✅ |
| 3 | `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` refactor | ✅ |
| 4 | `.PNE` binary runtime parse | ✅ |
| 5 | multi-`.PNE` switching | ✅ |
| 6 | ROM bank switching | ✅ |
| 7 | 楽曲交換時 ROM rebuild 不要化 | ✅ |
| 8 | dynamic reload | ✅ |
| 9 | generated directory (= future D3) | ✅ |
| 10 | mismatch silent flag / keyon skip 拡張 | ✅ |
| 11 | K/R rhythm compatibility 現役接続 | ✅ |
| 12 | mc compiler / vromtool.py / converter / `samples.inc` 改修 | ✅ |

## Accepted 後の重要境界 (= future contributor 向け明示)

**Step 9 は `sample_table_id` resolver までであり、 `sample_table_id` → sample table address / keyon path consumption は未実装**。 0xFD32 が runtime value (= 0x00 match / 0xFF mismatch) を持つようになったが、 これは「identity が確定した」 状態に留まり、 sample 再生経路 (= `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` / sample addr lookup) には一切反映されていない。 Step 10 以降で identity を addr / keyon に消費する sprint を別途立てる (= ADR-0023 §scope-out 1-3 項目)。

### 1. `sample_table_id` は保存されるが consume されない

`driver_pne_sample_table_id` (= 0xFD32) は step 9 で書込まれるが、 playback path (= `adpcma_keyon_simple` / `adpcma_volume_hook` / `adpcma_keyoff_hook` / `adpcma_ch_sample_ptr_table`) は **0xFD32 を読まない**。 sample addr 解決は依然 build-time 固定 (= `samples.inc` 経由)。 future contributor が「runtime resolver により sample addr 解決まで実装済」 と誤解しないよう、 ADR §決定 11 + 本 doc で literal 固定。

検査ポイント:
- `grep -rn "driver_pne_sample_table_id\|0xFD32" src/driver/`
  - write 箇所: `pmdneo_resolve_sample_table_id` 1 か所のみ
  - read 箇所: verify infra (= trace 解析) のみ、 driver runtime code からの read は **存在しない**

### 2. D1 hand-written directory は proof 用 placeholder

`pne_sample_directory` は **最終 directory ownership ではない**。 entry 1 件 + terminator の minimal placeholder。 future multi-`.PNE` 化で entry が増えたら D3 generated directory (= vromtool.py 拡張 or 別 script) への migration sprint を別途立てる。

### 3. asset canonical vs runtime fixture の責務差

- `PMDNEO01.PNE` = asset pipeline canonical asset 名 (= `assets/pne/PMDNEO01.PNE`)、 build-time VROM packing 対象
- `step5.PNE` = runtime filename observation fixture (= step 8 fixture で `.MN` に embed されている filename)、 driver runtime に実 copy される文字列

両者は別レイヤーの命名で、 directory entry は runtime fixture 側と整合させる (= ADR §決定 5 §γ 着手時 finding)。 future D3 migration sprint では命名軸 contract を最初に決定する (= memory `project_pne_directory_entry_runtime_fixture_vs_asset_canonical.md` 参照)。

### 4. mismatch でも既存音は変わらない

mismatch (= 0xFD32 = 0xFF) でも playback path は不変なので、 既存 build-time table からの sample addr 引きで sample は鳴り続ける。 mismatch → silent / keyon skip 等の audio 振舞い拡張は step 10+ scope (= ADR §決定 8 literal 維持)。

## Step 5/6/7/8/9 全体での役割位置づけ

```
Step 5: ADPCM-A 6ch native runtime (= 「どう鳴らすか」 semantics)
   ↓
Step 6: audio isolation / verification (= 「どう確認するか」 listening infra)
   ↓
Step 7: .PNE asset pipeline + .MN filename embed (= 「どこから持ってくるか」 source ownership)
   ↓
Step 8: runtime .PNE filename observation (= filename を「読める」、 runtime observation)
   ↓
Step 9: runtime .PNE filename → sample_table_id resolver (= filename を「使える」、 identity 段階) ← 本 sprint
   ↓
Step 10+: identity 消費 (= addr 解決 / keyon refactor / silent flag、 別 sprint)
   ↓
Step N: multi-.PNE switching / D3 generated directory / bank switching (= 大規模拡張)
```

PMDNEO の **「検証可能な進め方を固定しながら機能を増やす」** 設計言語が step 5 以降で連続的に確立されてきた。 step 9 は「runtime observation」 から「runtime resolution」 への 1 段延伸として位置付けられ、 各 sprint の scope を minimal に保つことで false PASS risk と未完成 architecture の積み重ねを回避している。

## 次 sprint 候補 (= step 10+)

ADR-0023 §scope-out から未消化:

1. **identity → addr lookup sprint** (= 0xFD32 を `adpcma_keyon_simple` で consume する最小 sprint、 selected table pointer 化)
2. **`adpcma_keyon` refactor sprint** (= selected pointer 経由で sample addr 引き、 既存 build-time table を runtime 動的選択 table に置換)
3. **mismatch silent flag sprint** (= 0xFD32 = 0xFF で keyon skip / silent flag 立ち上げ)
4. **`.PNE` binary runtime parse sprint** (= header / sample entry / addr table 読込)
5. **D3 generated directory migration sprint** (= vromtool.py 拡張 or 別 script で `.PNE` 群から自動生成)
6. **multi-`.PNE` switching sprint** (= 楽曲ごと別 `.PNE` 切替 + ROM bank switching)
7. **K/R rhythm compatibility 現役接続 micro-sprint** (= ADR-0019 §決定 2 から保留)

各 sprint は ADR-0023 〜 0024 〜 と続く形で 1 sprint = 1 ADR で起票し、 「検証可能な進め方を固定しながら機能を増やす」 規律を継続する。

## 関連

- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 1-12 + §完了判定達成状況 + §Accepted 後の重要境界
- [ADR-0023 step 9 α handoff](adr-0023-step9-alpha-state-cell-directory.md) (= data placement only)
- [ADR-0023 step 9 β handoff](adr-0023-step9-beta-resolver-routine.md) (= routine 単体実装 dead code)
- [ADR-0023 step 9 γ handoff](adr-0023-step9-gamma-chain-insertion.md) (= call insertion + α 補正 + match gate)
- [ADR-0022 step 8 completion](adr-0022-step8-completion.md) (= filename observation 完了状態の出発点)
- [ADR-0021 step 7 completion](adr-0021-step7-completion.md) (= `.MN` filename embed 経路成立、 3 層 ownership 確立)
- memory `project_pmdneo_step9_complete.md` (= 本 sprint 完了 memory、 δ で作成)
- memory `project_pne_directory_entry_runtime_fixture_vs_asset_canonical.md` (= γ 着手時 finding、 責務差 contract)
- memory `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離の延長)
