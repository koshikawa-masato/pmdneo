# ADR-0023: PMDNEO step 9 runtime `.PNE` filename → `sample_table_id` resolver sprint (= D1 hand-written directory + T3 independent init routine + G2 memory inspection primary)

- 状態: **Proposed** (= 2026-05-13 10th session 着手前起票)
- 起票日: 2026-05-13
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 9 = runtime resolver 関連)、 ADR-0019 (= step 5 §決定 3 で `.PNE` parser を「次 sprint へ分離」 と接続点予約、 §決定 4 sample addr 引き build-time embed 維持)、 ADR-0020 (= step 6 完了 + 次 sprint 候補に runtime resolver を明示)、 ADR-0021 (= step 7 完了で `.MN` filename embed 経路成立、 §Accepted 後の重要境界で「runtime resolution は Step 8 以降」 と明記)、 ADR-0022 (= step 8 完了で runtime filename observation 成立、 §Accepted 後の重要境界で「driver は filename を読めるが解決していない」 と明記)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)、 `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様)

## 背景

step 8 完了 (= 2026-05-13 9th session、 commit `a08cfb6`) で runtime `.PNE` filename observation block が成立した。 driver は SRAM 0xFD20-0xFD31 に `.PNE` filename string と `pne_filename_adr` word を保持し、 trace 経由で「`.MN` ↔ `.PNE` 連携が runtime に届いている」 ことを観測可能になった。

ただし ADR-0022 §Accepted 後の重要境界に明記された通り、 step 8 時点では:

- driver は filename を **読める** が **解決には使っていない**
- sample addr は依然 build-time に `samples.inc` 経由で固定埋込 (= ADR-0019 §決定 3 / ADR-0022 §決定 8 維持)
- 楽曲交換時は依然 ROM rebuild が必要 (= multi-`.PNE` runtime 切替は未実装)
- `driver_pne_filename_buf` / `driver_pne_filename_adr_word` は **read 用 observation state** に留まる

step 9 はこの境界の **「読める」 から「使う」 段階への 1 段延伸** を担う。 filename を runtime key として最初に「使う」 sprint であり、 ADR-0022 §次 sprint 候補で筆頭に挙げた「runtime `.PNE` parser driver 実装 (= filename → sample table resolve)」 の最小成立形である。

ただし「runtime resolver sprint」 と素朴に定義すると scope が肥大化する (= filename 解決 + sample table addr 引き + adpcma_keyon path 改変 + .PNE binary parse + multi-bank switching を同時に触る)。 10th session 冒頭の壁打ちで以下の方針整理が確定:

- **filename → 「どの sample table か」 を identity (= 1 byte index) で resolve するに留める**
- **sample table addr 引き / keyon refactor / .PNE binary parse / multi-bank switching は scope-out**
- **resolver の出力 (= `sample_table_id`) は runtime state に保存するだけで、 既存 playback path には接続しない**
- **「動いているものを壊さない」 規律 (= step 5/6/7/8 で確立) を継続遵守**

これに基づき step 9 を **「runtime `.PNE` filename → `sample_table_id` resolver sprint」** として定義する。 resolver の出力は driver SRAM の新規 1 byte cell に現れ、 既存の音の出方は一切変えない。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 9 着手前に方針を ADR として独立起票する。

### 10th session 冒頭壁打ちでの 5 軸方針確定

ADR-0023 起票前に user 主導で 5 軸の壁打ちが行われ、 step 9 の出口像が以下に固定された。

**軸 1: resolve 対象 = sample table identity (= C2 採用)**

filename を key に「どの sample table か」 を index / id (= 1 byte) で確定する。 sample table addr 取得 (= identity → addr lookup) は呼出側の責務であり、 step 9 では実装しない。 identity 中間層を置くことで:

- 後続 sprint で addr の詰め方 (= directory addr 引き / hot rewrite / static pointer) を別軸で選べる
- multi-`.PNE` 拡張時に identity 層が抽象境界として残る
- 「filename validity check のみ」 (= C1) より resolver として意味があり、 「filename → addr 直返却」 (= C3) より scope が小さい

**軸 2: build-time directory ownership = D1 hand-written (= driver code 内)**

filename ↔ `sample_table_id` 対応表を **driver code 内 hand-written** で持つ。 vromtool.py / converter / build pipeline は一切触らない。 初期 entry は `step5.PNE` / id 0x00 の 1 件のみ (= γ 改訂、 §決定 5 §γ 着手時 finding 参照)。

D2 (= vromtool.py 拡張) / D3 (= 別 generated script) は scope を asset pipeline 側に広げるため step 9 では採らない。 future multi-`.PNE` 化で entry が増えたら D3 generated directory への migration を検討する。 ADR 内に「D1 は最小 resolver proof 用、 最終 directory ownership ではない」 と明記する。

**軸 3: resolve 発火 timing = T3 独立 init routine**

`pmdneo_resolve_sample_table_id` を新規 routine として追加し、 `.MN` load + filename copy 完了後の直列 chain 末尾に call する。 Step 8 で確立した filename copy routine (= `pmdneo_mn_direct_load_lq_part_addr`) は不変、 既存 keyon path (= `adpcma_keyon_simple`) も不変。

T1 (= filename copy 直後 inline 拡張) は Step 8 routine を太らせるため不採。 T2 (= keyon path での lazy resolve) は ADR-0016 step 5 で安定化した primary playback path を汚すため不採。 T3 が future D3 generated directory / multi-`.PNE` / resolver 拡張への移行余地が最も広い。

**軸 4: verify gate = G2 memory inspection primary + register trace secondary**

step 9 の新規成果は chip register ではなく driver SRAM 0xFD32 に現れる (= `sample_table_id` は ADPCM-A register に書かれない)。 primary gate は 0xFD32 の match / mismatch 観測、 secondary gate は register trace = step 8 と byte-identical (= chip path 不変確認)。

G1 (= register trace primary 継続) は新規 resolver 動作の証拠にならず false PASS risk があるため不採。 G3 (= 4 重 gate 並走) は過剰。 ADR-0016 以来の「register trace primary」 規律は step 9 では observation 対象に合わせて memory inspection に切替、 ただし register trace は引き続き regression gate として保持する (= 規律破棄ではなく primary 軸の切替)。

**軸 5: sub-sprint 分割 = S2 (= α/β/γ/δ 4 段)**

step 9 を **α / β / γ / δ の 4 sub-sprint 構造** で進める。 「作る」 と「接続する」 を分けることで trivial verify (= ADR-0016 step 3c-2 / V-1 / W-1 / W-3 で検出された false PASS) を防ぐ。

| sub | 範囲 |
|---|---|
| α | state cell 定義 + directory hand-written (= routine 未作成、 call 未挿入) |
| β | resolver routine 単体実装 (= call 未挿入) |
| γ | chain insertion + memory inspection primary gate |
| δ | verify infra 統合 + audible regression + ADR Accepted 移行 |

S1 (= 3 段、 routine + call insertion を 1 commit に同梱) は trivial verify の切り分けに弱いため不採。 S3 (= step 5 同等 5 段) は step 9 scope が step 5 より小さいため過剰。

## 決定

### 決定 1: step 9 を「runtime `.PNE` filename → `sample_table_id` resolver sprint」 として定義 (= C2 採用)

step 9 の最終 deliverable boundary を **C2 (= sample table identity resolver)** とする。 driver が runtime filename buffer (= 0xFD20-0xFD2F) と hand-written directory を比較し、 一致した entry の `sample_table_id` (= 1 byte index) を新規 runtime state cell (= 0xFD32) に保存することを目的とする。 既存 sample playback path には接続しない。

#### 補足: step 9 = filename contract の「使用」 始動、 ただし playback semantics は不変

step 9 は **filename を runtime key として最初に「使う」 sprint** であり、 ADPCM-A lookup / register write / keyon / keyoff / volume / pan / timing 等の **sample playback semantics 自体は変更しない**。 これらは step 5 で完了済 (= ADR-0019)、 step 7 で外部化済 (= ADR-0021)、 step 8 で filename observation 化済 (= ADR-0022)。

future contributor が「runtime resolver により sample addr 解決まで実装済」 と誤解しないよう明示。 register trace 軸で step 8 と byte-identical になることが本質的根拠 (= 決定 7 secondary gate + 決定 10 既存 path 不変)。

### 決定 2: sample table addr 直返却 / keyon refactor / `.PNE` binary parse / multi-bank は scope-out

step 9 では以下を **すべて scope-out**、 後続 sprint へ分離:

- sample table addr 直返却 (= C3 相当、 identity → addr lookup)
- selected table pointer の runtime use (= adpcma_keyon が selected pointer から引く)
- `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` の refactor (= 既存 build-time table 使用維持)
- `.PNE` binary 自体の runtime parse (= header / sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- dynamic reload (= 動的 `.PNE` 差替)
- generated directory (= future D3、 別 script / vromtool.py 拡張)
- silent flag / keyon skip 等の mismatch 時 audio 振舞い拡張
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- mc compiler / vromtool.py / converter / `samples.inc` 改修

これらは「runtime resolver Step 10+ sprint」 を別途立て、 driver 改修専念で進める。

### 決定 3: directory ownership = D1 hand-written (= driver code 内)

filename ↔ `sample_table_id` 対応表を **driver code 内 hand-written** で持つ。 配置候補:

- **採用**: `standalone_test.s` 末尾 (= 既存 sample table 群と同区画) または専用 .inc (= 例 `SAMPLE_DIRECTORY.inc`)
- vromtool.py / converter / build pipeline は一切触らない (= step 7 path B / step 8 で確立した「vromtool.py 不変」 方針を継承)
- 初期 entry: `step5.PNE` / id 0x00 の 1 件のみ (= γ 改訂、 §決定 5 §γ 着手時 finding 参照)
- terminator entry 1 件で directory 終端を示す (= 決定 5)

#### 配置根拠

- step 9 は「resolver の最小 runtime semantics 確認」 段階であり、 generation pipeline を作る段階ではない
- entry 数が 1 件のため hand-written が最小 scope
- 既存 source-of-truth ownership 規律 (= ADR-0021 §3 層 ownership: hand-written / generated / existing production) において **existing production (= driver source-of-truth)** 区分に該当
- future multi-`.PNE` 化で entry 数が増えたら D3 generated directory への migration を検討 (= scope-out)

#### 明示: D1 = 最小 resolver proof 用、 最終 directory ownership ではない

handoff doc / future contributor 向けに次を明記する:

- D1 は **step 9 が resolver semantics を最小 fixture で証明する** ための placeholder
- 最終 directory ownership は generated directory (= D3) になる見込み
- entry 数が増えた時点で migration sprint を別途立てる

### 決定 4: PNE runtime block 拡張 (= 0xFD20-0xFD32, 19 byte)

driver の Z80 SRAM 内の **PNE runtime block** を step 8 から 1 byte 拡張:

| address | symbol | size | 内容 | 出自 |
|---|---|---|---|---|
| 0xFD20-0xFD2F | `driver_pne_filename_buf` | 16 byte | NUL-terminated ASCII filename | Step 8 (= ADR-0022 §決定 4) |
| 0xFD30-0xFD31 | `driver_pne_filename_adr_word` | 2 byte | `pne_filename_adr` (LE u16、 m_buf-relative) | Step 8 (= ADR-0022 §決定 4) |
| 0xFD32 | `driver_pne_sample_table_id` | 1 byte | resolver 出力 (= 0x00-0xFE valid id / 0xFF mismatch sentinel) | **Step 9 新規 (= 本 ADR)** |

合計 19 byte (= 0xFD20-0xFD32)。 0xFD33 以降は future resolver 拡張用に reserve (= bank id / addr cache / dirty flag 等の余地)。

#### 配置根拠

- 0xFD32 は step 8 block 直後の連続配置で、 PNE runtime block の論理的延長
- 既存 `part_workarea` (= 0xF820-0xFD1F) と直接 1 byte の干渉なし
- 0xF800-0xF80F は future cmd FIFO reserved のため使わない
- `driver_state` (= 0xF810-0xF81F) は既存 runtime state 用として温存
- future resolver 拡張で 0xFD33-0xFD3F が即座に確保できる

### 決定 5: directory entry binary 構造 (= 17 byte/entry, fixed length)

driver code 内 hand-written directory の entry 構造:

| field | size | 内容 |
|---|---|---|
| `filename` | 16 byte | fixed length, NUL-padded ASCII (= `driver_pne_filename_buf` と同形) |
| `sample_table_id` | 1 byte | 0x00-0xFE = valid id, **0xFF = terminator marker** |

entry size = 17 byte 固定。 random access 容易 (= entry index × 17 で先頭計算可)、 `driver_pne_filename_buf` と filename field が完全同形のため compare routine が memcmp 1 発で済む。

#### terminator 規約

- **terminator design: `sample_table_id` = 0xFF を直接 sentinel として使う**
- terminator entry の `filename` field は don't care (= 16 byte 任意)
- driver の resolver routine は `sample_table_id == 0xFF` を検出した時点で directory 走査終了

代替案 (= `filename[0] == 0x00` を sentinel にする) は採らない。 理由:

- valid entry でも filename が短い場合 NUL-padded なので `filename[0]` 自体は valid value
- `sample_table_id == 0xFF` の方が「runtime mismatch sentinel」 と「directory terminator」 で同一 sentinel 値を共有でき、 設計が単純

#### 初期 directory 内容 (= step 9 出荷時、 γ 改訂版)

```
entry 0: filename = "step5.PNE\0\0\0\0\0\0\0" (= 9 char + 7 NUL pad = 16 byte fixed)
         sample_table_id = 0x00

entry 1 (= terminator):
         filename = (don't care, 16 byte)
         sample_table_id = 0xFF
```

合計 34 byte (= 17 × 2 entry)。

#### γ 着手時 finding (= 2026-05-13 10th session、 commit 7241b0d/319aa3c 後)

α 起票時の本決定 §初期 directory 内容では entry 0 filename を **"PMDNEO01.PNE"** (= 12 char + 4 NUL pad) として固定していた。 γ 着手時、 `pmdneo_resolve_sample_table_id` を `.MN` load chain に call insertion して trace 取得を試みたところ、 **default test01 build では `.MN` direct path が走らず 0xFD32 への write が 0 件** であることが判明した。

原因:

- driver `pmdneo_mn_direct_load_lq_part_addr` は `m_start.bit 2 = 1` でのみ走る (= ADR-0021 `.MN` binary format 由来、 PMDNEO `.MN` mode signature)
- default test01 build は legacy fallback path (= bit 2 = 0) を通り、 filename copy routine 不実行 → 0xFD20-0xFD32 すべて未 touch
- step 8 verify (= ADR-0022 §決定 7 γ verify-step8-filename-observation.sh) は `src/test-fixtures/step5/l-q-rhythm-song.mml` + `PMDDOTNET_MODE=B` で `.MN` direct path を起動して trace 取得していた
- 当該 fixture の embedded filename = **"step5.PNE"** (= step 5 命名の history value)

つまり ADR-0023 起票時に entry 0 = "PMDNEO01.PNE" としたのは **asset pipeline canonical asset 名** (= `assets/pne/PMDNEO01.PNE` の `.PNE` ファイル名) であり、 driver runtime が読み込む filename ではなかった。 runtime に流れる唯一の filename は step 8 fixture 由来の "step5.PNE"。

γ で取った対処 (= A1 採用):

- directory entry 0 を **"step5.PNE"** に修正 (= `standalone_test.s` の `.db` 16 byte 上書き)
- 本決定 5 §初期 directory 内容 + §決定 3 + §決定 7 + §決定 9 + §scope-in + §完了判定 内の "PMDNEO01.PNE" 言及を "step5.PNE" に統一改訂
- 既存 step 8 fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) を γ match fixture として再利用 (= 新規 fixture 不要、 scope 最小)

責務差の明示 (= future contributor 向け):

- **`PMDNEO01.PNE`** = asset pipeline canonical asset 名 (= `assets/pne/PMDNEO01.PNE`)、 build-time に VROM へ pack される `.PNE` ファイルの実 filename
- **`step5.PNE`** = runtime filename observation fixture (= step 8 fixture で `.MN` に embed されている filename、 driver runtime に実 copy される文字列)

両者は別レイヤーの命名であり、 future multi-`.PNE` 化や D3 generated directory への migration では asset pipeline canonical 側 (= `PMDNEO01.PNE`) と runtime fixture 側 (= `step5.PNE`) の関係を明示的に詰める必要がある (= scope-out、 step 10+ で扱う)。

### 決定 6: resolve 発火 timing = T3 独立 init routine (= `pmdneo_resolve_sample_table_id`)

新規 routine `pmdneo_resolve_sample_table_id` を独立して追加し、 `.MN` load + filename copy 完了後の直列 chain 末尾に call を 1 行挿入する。

#### routine の擬似コード

```
pmdneo_resolve_sample_table_id:
    ; HL = directory 先頭 addr
    ; DE = driver_pne_filename_buf (= 0xFD20)
    ; loop: entry が terminator (= sample_table_id == 0xFF) ならば mismatch
    ; entry filename と driver_pne_filename_buf を 16 byte memcmp
    ; 一致 → entry の sample_table_id を 0xFD32 に store + return
    ; 不一致 → 次 entry へ (= HL += 17)
    ; terminator 到達 → 0xFD32 = 0xFF (mismatch sentinel) + return
    ret
```

#### routine 配置と call point

- routine 本体は `standalone_test.s` 内 or 専用 .inc (= directory と隣接配置)
- call point: `pmdneo_mn_direct_load_lq_part_addr` (= Step 8 で確立した filename copy routine) の末尾、 既存 ret 直前
- filename copy routine 自体の logic は完全不変、 末尾に 1 行 `call pmdneo_resolve_sample_table_id` を追加するのみ

#### timing 根拠

- filename copy が完了していないと resolver 入力 (= 0xFD20-0xFD2F) が valid でないため、 filename copy 後にしなければならない
- keyon path で lazy resolve すると primary playback path に分岐が入り、 ADR-0016 step 5 で安定化したシンプルさを損ねる
- 独立 routine にすることで future D3 generated directory / multi-`.PNE` / resolver 拡張時の置換が容易

### 決定 7: verify gate = G2 memory inspection primary + register trace secondary

step 9 の新規挙動 (= `sample_table_id` 保存) は driver SRAM 0xFD32 にのみ現れ、 chip register には一切書かれない。 このため verify gate の primary 軸を memory inspection に切替える:

- **primary gate**: 0xFD32 観測
  - filename match 時 (= step 8 fixture `l-q-rhythm-song.mml` + `PMDDOTNET_MODE=B`、 embedded filename = "step5.PNE"): `0xFD32 == 0x00`
  - filename mismatch 時 (= directory に存在しない filename を持つ fixture): `0xFD32 == 0xFF` (= δ で fixture 整備、 §決定 9 改訂参照)
- **secondary gate**: register trace
  - ADPCM-A register write trace = step 8 と byte-identical
  - sample lookup / keyon / volume / pan / freq に regression なし
- **audio gate** (= 軽量 subset): step 6-a silent-bcef fixture で audible regression なし
- **byte-identical gate**: `assets/samples.inc` / VROM / `.PNE` / `.MN` (= filename 部分以外) / converter / vromtool.py / build pipeline 不変

#### primary 軸切替の根拠

- step 9 の新規 deliverable は driver SRAM の 1 byte 書込みのみ
- chip register には影響を与えないため、 register trace は新規挙動の証拠にならない
- 0xFD32 の match / mismatch 観測こそが resolver 動作の literal proof
- ADR-0016 以来確立した「register trace primary」 規律は破棄ではなく、 step 9 の観測対象に合わせた切替
- step 10+ で keyon refactor / addr resolve に進む際は register trace primary に戻る

#### memory inspection 実装方針 (= γ で詰める)

- MAME debug script (= `-debugscript` または `mame -d` console 経由) で 0xFD32 を読む
- driver 経由 IRQ 内 dump (= debug build で 0xFD32 を chip 経由 trace に乗せる) は将来検討
- γ sub-sprint で具体的 script を作成 + commit + push

### 決定 8: mismatch 振舞い = 0xFF sentinel のみ、 silent flag / keyon skip は scope-out

filename が directory に一致しない場合の driver 振舞い:

- `driver_pne_sample_table_id` = 0xFF (= mismatch sentinel) を保存
- keyon skip しない (= 既存 build-time table から引き続き鳴る)
- silent flag 立てない (= 0xFD32 以外の state は変えない)
- driver halt しない

#### 根拠

- step 9 は resolver semantics の最小成立確認 sprint であり、 mismatch 時の audio 振舞い拡張は別軸
- 既存 build-time playback path を完全不変に保つ規律 (= 決定 10) と整合
- mismatch を audible 化したい場合は step 10+ で「mismatch → silent」 ADR を別途立てる
- step 9 では mismatch sentinel が 0xFD32 に正しく現れることのみを完了判定とする

### 決定 9: sub-sprint 分割 = S2 (= α/β/γ/δ 4 段)

step 9 を **α / β / γ / δ の 4 sub-sprint 構造** で進める。

| sub | 範囲 | primary gate |
|---|---|---|
| α | `driver_pne_sample_table_id` (= 0xFD32) state cell 定義 + .equ / WORKAREA 追加 + hand-written directory 追加 (= entry 構造 + 初期 entry + terminator) | build PASS + symbol export 確認 + 0xFD32 が ROM 内に reserve されている |
| β | `pmdneo_resolve_sample_table_id` routine 単体実装 (= directory compare + match/mismatch sentinel store)、 ただし call は未挿入 | build PASS + routine size sanity + register trace = α と byte-identical (= call されていないため挙動同一) |
| γ | `.MN` load chain (= `pmdneo_mn_direct_load_lq_part_addr` 末尾 filename copy 直後) に `call pmdneo_resolve_sample_table_id` 追加 + memory inspection primary gate (= 0xFD32 = 0x00 確認、 match fixture のみ) + α 補正 (= directory entry 0 を `step5.PNE` に修正 + 本 ADR §決定 5 改訂、 γ 着手時 finding 反映) | 0xFD32 match: step 8 fixture `l-q-rhythm-song.mml` + `PMDDOTNET_MODE=B` で 0x00 (= mismatch fixture verify は δ へ繰下げ、 γ 着手時 finding §決定 5 参照) |
| δ | mismatch fixture verify (= 0xFD32 = 0xFF) + verify infra 統合 (= `verify-step9-resolver.sh` 等) + step 5/6/7/8 既存 verify script 全件 PASS + MAME 試聴で audible regression なし + step 9 完了統合 handoff doc + ADR-0023 Accepted 移行 | mismatch primary gate PASS + 全 sub primary gate PASS + 既存 verify regression PASS + audible OK |

**1 sub = 1 commit + 1 push 規律** (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) を維持。 各 commit で user 都度レビュー待ち。

#### 分割根拠

- α は「state を確保し table を置く」 だけで routine も call も無い → trivial verify (= 何も動いていないのに build PASS) を detect しやすい
- β は routine 実装するが call されていない → 静的 build/size 確認のみで挙動同一 (= register trace で byte-identical 検証可能)
- γ で初めて call が挿入され primary gate が「実 resolver 動作」 を捕捉
- δ で既存 verify infra と統合し regression を保証

### 決定 10: 既存 sample playback path は完全不変

step 9 では以下を **すべて完全不変** とする:

- `assets/samples.inc` (= 生成 sample include)
- VROM (= ngdevkit-examples 経由 ROM build pipeline)
- driver の sample lookup routine (= `adpcma_ch_sample_ptr_table` voice index 引き)
- `adpcma_keyon_simple` / `adpcma_keyoff_hook` / `adpcma_volume_hook`
- ADPCM-A register writes (= keyon / keyoff / volume / pan / freq)
- L-Q part 6ch 経路 (= step 5 完成)
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`)
- vromtool.py
- build pipeline (= `vendor/Makefile` / `scripts/build-poc.sh`)
- step 8 で確立した `pmdneo_mn_direct_load_lq_part_addr` (= filename copy routine 本体は不変、 末尾に 1 行 call 追加するのみ)

step 9 は **runtime filename を resolve するだけで、 音の出方は一切変えない**。 future contributor が「runtime resolver により sample addr 解決まで実装済」 と誤解しないよう、 この決定で literal に固定する。

### 決定 11: Step 9 内で `sample_table_id` は playback decision に使用しない

`pmdneo_resolve_sample_table_id` が 0xFD32 に保存する `driver_pne_sample_table_id` は **runtime state として保存するのみ**、 step 9 内では playback decision に一切使用しない。

具体的には:

- `adpcma_keyon_simple` / `adpcma_keyoff_hook` / `adpcma_volume_hook` 等の playback path は 0xFD32 を読まない
- sample lookup (= `adpcma_ch_sample_ptr_table` voice index 引き) は build-time table のまま不変
- mismatch (= 0xFD32 == 0xFF) でも playback 動作は変えない (= 決定 8 と整合)
- volume / pan / freq / keyon / keyoff の dispatch 経路はすべて 0xFD32 と独立

#### 根拠

- step 9 の成果は **identity resolution まで** であり、 identity を playback に使うのは step 10+ の領域
- 0xFD32 が driver state に現れると future contributor が「keyon / sample lookup に既に使われている」 と誤解しやすい
- 本決定で「resolver の出力は保存されるが消費されない」 ことを literal に固定し、 step 9 の責務境界を明示
- step 10+ で identity → addr lookup / keyon refactor / mismatch silent flag 等の sprint を別途立て、 そこで初めて 0xFD32 を playback decision に消費する

#### 補足: future contributor 向け検査ポイント

step 9 完了後の driver source に対して、 次が PASS することで本決定の整合を確認可能:

- `driver_pne_sample_table_id` / `0xFD32` の symbol で grep して、 **read 箇所は trace / verify infra のみ** (= playback routine からの read は存在しない)
- write 箇所は `pmdneo_resolve_sample_table_id` の **1 か所のみ**

### 決定 12: handoff doc 構造

step 9 の handoff doc は sub-sprint ごと独立、 完了統合は別 doc。

| 段階 | 文書 | 内容 |
|---|---|---|
| α | `docs/design/handoff/adr-0023-step9-alpha-state-cell-directory.md` | state cell 定義 + directory hand-written 実装 + build PASS 確認 |
| β | `docs/design/handoff/adr-0023-step9-beta-resolver-routine.md` | `pmdneo_resolve_sample_table_id` routine 実装 + register trace byte-identical 確認 |
| γ | `docs/design/handoff/adr-0023-step9-gamma-chain-insertion.md` | chain insertion + memory inspection primary gate 整備 + match/mismatch fixture |
| δ | `docs/design/handoff/adr-0023-step9-completion.md` | step 9 統合 sum-up + ADR-0023 Accepted 移行 |

## scope-in / scope-out 明示

### scope-in (= step 9 本 sprint 範囲)

- `driver_pne_sample_table_id` (= 0xFD32) state cell 定義 + .equ + WORKAREA layout 追加 (= α)
- driver code 内 hand-written directory 追加 (= entry 構造 + 初期 entry `step5.PNE` / 0x00 + terminator entry) (= α 追加 + γ 補正、 §決定 5 §γ 着手時 finding 参照)
- `pmdneo_resolve_sample_table_id` routine 実装 (= directory compare + match/mismatch sentinel store) (= β)
- `.MN` load chain (= `pmdneo_mn_direct_load_lq_part_addr` 末尾) への `call pmdneo_resolve_sample_table_id` 1 行追加 (= γ)
- memory inspection primary gate 整備 (= 0xFD32 = 0x00 / 0xFF 観測 script) (= γ)
- mismatch fixture 検証 (= directory に存在しない filename を持つ `.MN` fixture で 0xFD32 = 0xFF 確認) (= γ)
- step 5/6/7/8 既存 verify script 全件 regression 再確認 (= δ)
- MAME 試聴で audible regression なし最終確認 (= δ、 step 6-a silent-bcef fixture 流用)
- step 9 完了統合 handoff doc + ADR-0023 Accepted 移行 (= δ)

### scope-out (= step 9 範囲外、 後続 sprint で扱う)

- sample table addr 直返却 (= C3 相当、 identity → addr lookup)
- selected table pointer の runtime use (= adpcma_keyon が selected pointer から引く)
- `adpcma_keyon_simple` / `adpcma_ch_sample_ptr_table` の refactor
- `.PNE` binary 自体の runtime parse (= header / sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- dynamic reload (= 動的 `.PNE` 差替)
- generated directory (= future D3、 別 script / vromtool.py 拡張)
- silent flag / keyon skip 等の mismatch 時 audio 振舞い拡張
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- PMDNEO.s + nullsound integration (= 大規模 sprint)
- 新規 sample 追加 (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- sample table 再構築 / asset reload
- mc compiler / vromtool.py / converter / `samples.inc` 改修
- PPZ compatibility mode
- FM-Towns-style rhythm mode

## 完了判定

### step 9 全体完了判定 (= ADR-0023 Accepted 移行条件)

1. **α**: `driver_pne_sample_table_id` (= 0xFD32) state cell 定義 + .equ + WORKAREA 追加 + commit + push
2. **α**: driver code 内 hand-written directory 追加 (= 初期 entry + terminator) + symbol export 確認
3. **β**: `pmdneo_resolve_sample_table_id` routine 単体実装 + commit + push (= call は未挿入)
4. **β**: routine size sanity + register trace = α と byte-identical (= call されていないため挙動同一)
5. **γ**: `.MN` load chain 末尾に `call pmdneo_resolve_sample_table_id` 追加 + commit + push
6. **γ**: filename match fixture (= step 8 fixture `l-q-rhythm-song.mml` + `PMDDOTNET_MODE=B`、 embedded filename = "step5.PNE") で `0xFD32 == 0x00` を memory inspection で確認
7. **γ**: α 補正 (= directory entry 0 を `step5.PNE` に修正 + 本 ADR §決定 5 改訂、 §γ 着手時 finding 反映)
8. **δ**: filename mismatch fixture (= directory に存在しない filename を持つ fixture) で `0xFD32 == 0xFF` を確認
9. **δ**: verify infra (= `verify-step9-resolver.sh` 等) 整備 + commit + push
10. **δ**: step 5/6/7/8 既存 verify script 全件 PASS (= 既存 architecture regression なし)
11. **δ**: MAME 試聴で audible regression なし (= step 6-a silent-bcef fixture で確認)
12. **δ**: step 9 完了統合 handoff doc + ADR-0023 Accepted 移行 + commit + push

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## 関連 memory

- `project_pmdneo_step8_complete.md` (= step 8 完了状態、 runtime filename observation 成立)
- `project_pmdneo_step7_complete.md` (= step 7 完了状態、 `.MN` filename embed 経路成立)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 9 は「runtime resolution」 軸の最初の 1 段)
- `project_pmdneo_step6_complete.md` (= step 6 完了状態、 audio isolation 戦略、 silent-bcef fixture 流用)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ADPCM-A 6ch native path、 既存 keyon path 不変対象)
- `project_pmdneo_mn_header_byte_count.md` (= `.MN` header 28 byte 固定、 driver は m_start bit 2 = 1 で固定解釈可)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 step 9 は memory inspection primary に切替)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律、 sub α/β/γ 分割で対応)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 step 6-a fixture 流用)
- `feedback_verify_script_serial_execution.md` (= verify script 群は serial 実行、 δ で適用)

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= `.PNE` parser 次 sprint 接続点予約)、 §決定 4 (= sample addr は build 時 embed)
- ADR-0020 §次 sprint 候補 (= runtime resolver を筆頭に挙示)
- ADR-0021 §Accepted 後の重要境界 (= runtime resolution は Step 8 以降)
- ADR-0022 §Accepted 後の重要境界 (= driver は filename を読めるが解決していない)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/design/mn_binary_layout.md` §4-3-3 / §7-2 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様、 step 7 α-1 起票)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止 / §「記憶は AI に、 判断は自分が握る」

## 次 sprint 候補

1. **α 着手** (= `driver_pne_sample_table_id` state cell 定義 + hand-written directory 追加 + build PASS)
2. β 着手 (= `pmdneo_resolve_sample_table_id` routine 単体実装、 call 未挿入)
3. γ 着手 (= chain insertion + memory inspection primary gate + match/mismatch fixture)
4. δ 着手 (= verify infra 統合 + step 5/6/7/8 regression + audible 確認 + 完了統合 + Accepted 移行)
5. **step 10 候補** (= 本 ADR scope-out のうち未消化): sample table addr 直返却 sprint (= identity → addr lookup) / adpcma_keyon refactor で selected table pointer 使用化 / `.PNE` binary runtime parse / multi-`.PNE` switching / K-R rhythm compat micro-sprint / generated directory (= D3) migration / mismatch silent flag 拡張
