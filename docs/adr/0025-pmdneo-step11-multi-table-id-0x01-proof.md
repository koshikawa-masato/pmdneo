# ADR-0025: PMDNEO step 11 multi-table id=0x01 proof (= 2 entry directory + filename A/B + table A/B + selector id 拡張、 L ch only sample swap、 entry_index=id 暗黙、 PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2、 differential register trace primary + memory inspection secondary、 verify-step11-multi-table.sh 新設)

- 状態: **Draft** (= 2026-05-14 12th session、 α 着手時に本 ADR 起票)
- 起票日: 2026-05-14
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 11 = identity resolution の selection differentiation 実証段階)、 ADR-0019 (= step 5 §決定 3 sample addr build-time embed、 §決定 4 で sample 増加は別 sprint 接続点予約)、 ADR-0021 (= step 7 `.PNE` asset pipeline + `.MN` filename embed)、 ADR-0022 (= step 8 runtime filename observation)、 ADR-0023 (= step 9 filename → sample_table_id resolver)、 ADR-0024 (= step 10 sample_table_id selection consumption、 §決定 3 で id=0x00 only-accept、 §決定 6 で selected pointer state cache 不採用)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)、 `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様、 directory entry 拡張)

## 背景

step 10 (= ADR-0024) 完了 (= 2026-05-14 11th session、 commit `0746073`) で identity resolution (= `.PNE` filename → `sample_table_id`) が playback selection に effective になった。 driver は 0xFD32 (= `driver_pne_sample_table_id`) を中間 routine `pmdneo_select_sample_pointer` で consume し、 id=0x00 ならば既存 `adpcma_ch_sample_ptr_table` から sample header pointer を返却、 それ以外 (= 0xFF 含む) は 0x0000 sentinel で silent 化する。

ADR-0024 Accepted 後の重要境界に明記された通り、 step 10 時点では:

- 受入 id は **0x00 のみ** (= ADR-0024 §決定 3 / 2-C 採用)
- `sample_table_id` は 「`0x00` 受入 / それ以外 silent」 という **gate** として機能、 「複数 table から 1 つを選ぶ」 という **selection key** としては未実証
- mismatch (= id=0xFF) と unknown (= id=0x01+) は同一の silent path に倒れる、 audio 観測上区別不能
- 直前 11th session 冒頭壁打ち (= ADR-0024 4 論点) で selected pointer runtime state cache (= A3 相当) は scope-out 確定、 step 11+ で必要に応じて検討と保留

step 11 はこの境界の **「gate」 から「selection key」 段階への 1 段延伸** を担う。 2 entry の directory + 2 table を構築し、 filename によって異なる id が立ち、 異なる id が異なる sample addr の register write を引き起こすことを literal 観測する sprint である。

ただし「multi-table proof sprint」 と素朴に定義すると scope が肥大化する (= dynamic asset management / generated directory / bank switching / runtime `.PNE` parser / multi-`.PNE` switching を同時に触る)。 12th session 冒頭の壁打ち (= 5 axes) で以下の方針整理が確定:

- **table B は L ch のみ別 sample に差替え、 M-Q は table A と同 pointer** (= axis 1 / 最小 differential proof)
- **sample source は既存 VROM 内 sample 再利用、 新規 wav import なし** (= axis 1-b / 推奨 α 採用)
- **filename / fixture 命名は既存 step5.PNE / step5.MN 維持 + 派生 step5b.PNE / step5b.MN 追加** (= axis 2 / 推奨組合せ採用)
- **directory entry format は filename only、 entry_index = id 暗黙決定、 PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2 で軽柔軟性** (= axis 3 / α' 採用)
- **selector 拡張は explicit if/jr、 table A 隣接 layout、 `_b` suffix label、 sentinel 流用、 EQU 再利用で id 上限管理** (= axis 4 / 推奨組合せ採用)
- **verify gate は hybrid (= differential register trace primary + memory inspection secondary)、 L ch addr differ + M-Q identical + keyon count identical の 3 観点同時、 literal register value assert で trivial verify 防止** (= axis 5 / 推奨組合せ採用)
- **A2 selected pointer cache は scope-out 維持、 A1 per-keyon selector 継続** (= 12th session 冒頭判断、 memory `project_pmdneo_step11_a2_deferred` 確立)
- **「動いているものを壊さない」 規律 (= step 5/6/7/8/9/10 で確立) を継続遵守**

これに基づき step 11 を **「multi-table id=0x01 proof sprint」** として定義する。 2 table + 2 directory entry + 2 filename fixture + selector id 拡張により、 `sample_table_id` が単なる gate から selection key として機能することを実証する最小成立形である。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 11 着手前に方針を ADR として独立起票する。

### 12th session 冒頭壁打ちでの 5 axes 方針確定

ADR-0025 起票前に user 主導で 5 axes の壁打ちが行われ、 step 11 の出口像が以下に固定された。

**前提軸: A1 vs A2 vs A3 = A1 (= per-keyon selector) 継続採用**

selected pointer runtime state を持つか否か:

- A1 (= **継続採用**): per-keyon に `pmdneo_select_sample_pointer` を呼出し、 selected pointer は runtime state 化しない (= Step 10 挙動継続)
- A2 (= scope-out): selected pointer runtime state 化、 keyon path は state を読むだけ
- A3 (= hybrid): future hook のみ先行配置

A1 継続根拠: `sample_table_id` は曲開始時に 1 度設定されるのみで再生中不変、 per-keyon resolve は構造的に冗長だが機能・速度ともに実害は小、 A2 は selected pointer state / invalidation timing / mismatch pointer 値の更新規約という 3 つの新規約を新たに持ち込む、 future hook 目的の先行配置は CLAUDE.md「仮想の将来要件のために抽象化しない」 に抵触、 役割分離は Step 10 selector routine 経由化で最低限達成済。 動的化局面 (= multi-table runtime / dynamic reload / bank switching) で A2 を再検討する。

**axis 1: table B 構成 = L ch only sample swap (= i 採用) + 既存 VROM 内 sample 再利用 (= α 採用)**

- i (= **採用**): L ch のみ別 sample 差替え、 M-Q = table A と同 pointer
- ii: 全 6 ch 別 sample (= overkill)
- iii: silent table (= mismatch silent path と区別不能で proof 弱い)
- iv: hybrid (= 中途半端)

i 採用根拠: Step 5/6/7 で L ch primary observation 軸が確立済 (= verify infra そのまま使える)、 M-Q は table A と完全同 pointer = register trace で 5 ch 不変が証明できる → 「id 切替で意図しない ch まで影響しない」 という副作用なし証明、 proof として最小 differential、 trivial verify 化しにくい。

sample source α (= 既存 VROM 内 sample 再利用) 採用根拠: 新規 wav import は asset pipeline / conversion / provenance の論点が混ざる、 Step 11 目的は「multi-table selection proof」 であって sample asset 増加ではない、 既存 VROM 内 sample 再利用なら VROM / converter / `.PNE` pipeline を触らずに済む、 register 差分も既存 BD vs SD addr で十分観測できる。 git status の未追跡 wav 3 件 (= `lefthook.wav` / `lightbulbbreaking.wav` / `woosh.wav`) は Step 11 では触らず、 handoff で「not used」 明記。

**axis 2: filename / fixture 命名 = 推奨組合せ (= 全 α) 採用**

- 2-a (= **採用 α**): filename B = `step5b.PNE` (= 既存 `step5.PNE` と並ぶ versioning 命名)
- 2-b (= **採用 α**): filename A = 既存 `step5.PNE` 維持 (= 最小変更)
- 2-c (= **採用 α**): `.MN` fixture = 既存 `step5.MN` 維持 + 新規 `step5b.MN` 派生 (= `#PNEFile` のみ差替、 MML body 同一流用)
- 2-d (= **採用 α**): MML body = 同一流用 (= 差分原因を filename / table selection に限定)

採用根拠: 既存 step5 fixture を壊さない、 Step 11 の差分を「filename が違う → id が違う → L ch sample addr が違う」 に限定できる、 step5 / step5b は A/B 比較として読みやすい、 step11a / step11b にすると既存 step5.PNE の位置付け整理が増える、 semantic 名は fixture 名に仕様を入れすぎる、 MML body を同一にすることで差分原因を filename / table selection に限定できる。

ADR / handoff 記載要件:
- `step5.PNE` = baseline fixture
- `step5b.PNE` = table B selection fixture
- 命名は runtime proof 用、 asset canonical name ではない
- `PMDNEO01.PNE` (= ADR-0023 経緯の canonical) とは役割が異なる

**axis 3: directory entry format = 推奨組合せ + 3-b α' 採用**

- 3-a (= **採用 α**): filename only、 entry_index = sample_table_id 暗黙
- 3-b (= **採用 α'**): entry count は `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` で軽柔軟性、 純 hard-code 2 ではなく EQU で magic number 排除
- 3-c (= **採用 α**): Step 9 layout 踏襲、 entry を 2 件連結
- 3-d (= **採用 α**): 先勝ち (= 最小実装)

採用根拠: filename + explicit id は今は過剰、 terminator / count header も generated directory 化までは不要、 entry_index = id は proof として十分、 EQU 定数なら「2 entries 固定」 の意図を明示でき magic number を避けられる、 将来 D3 generated directory に移行する時も count 生成に繋げやすい、 先勝ちは最小実装で十分。

ADR / handoff 記載要件:
- 「entry_index = id は Step 11 proof 用の暫定規約」
- 最終 directory ownership / explicit id / terminator は D3 migration 以降で再検討
- duplicate filename は scope-out、 現時点では先勝ち

**axis 4: selector accept rule 拡張 = 推奨組合せ採用**

- 4-a (= **採用 α**): explicit if/jr (= `or a` → table A、 `cp 1` → table B、 else sentinel)
- 4-b (= **採用 α**): table A / table B を同 file 同 section に隣接配置
- 4-c (= **採用 α**): `adpcma_ch_sample_ptr_table_b` (= `_b` suffix、 step5b.PNE と命名軸が揃う)
- 4-d (= **採用 α**): 既存 sentinel path 流用 (= Step 10 mismatch silent 挙動保存)
- 4-e (= **採用 α'**): `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` を再利用、 `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` で範囲外判定 (= axis 3 EQU と整合)

採用根拠: id=0x00 / id=0x01 の 2 table だけなら explicit if/jr が一番読みやすい、 table-of-tables はまだ早い、 table A/B を隣接配置すると proof 用差分が読みやすい、 `_b` suffix は `step5b.PNE` と対応していて直感的、 semantic 名は仕様を label 名に入れすぎる、 mismatch / unknown は Step 10 の sentinel silent をそのまま維持すべき、 hard-code 2 より EQU 再利用の方が directory entry count と accepted id range の関係が明示される。 4-a explicit if/jr と 4-e EQU 上限管理の軽い混在は許容。

ADR / handoff 記載要件:
- explicit branch は Step 11 proof 用
- N table 化する場合は table-of-tables / generated directory で再検討
- `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は accepted id range の上限にも使う
- `id >= PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は sentinel silent

**axis 5: verify gate = 推奨組合せ採用**

- 5-a (= **採用 γ**): hybrid (= differential register trace primary + memory inspection secondary)
- 5-b (= **採用**): L ch ADPCM-A addr regs = different / M-Q addr regs = identical / keyon count = identical の 3 観点同時
- 5-c (= **採用 α**): user 試聴 で step5 = BD audible / step5b = SD audible 確認 (= secondary)
- 5-d (= **採用 α**): 既存 Step 5/6/7/8/9/10 verify script 群 全 PASS 維持
- 5-e (= **採用 α**): literal register value assert (= BD addr literal / SD addr literal を script に書く)
- 5-f (= **採用 α**): `verify-step11-multi-table.sh` 新設 (= step5.PNE / step5b.PNE 比較 differential proof script)

採用根拠: differential register trace は「selection が effective」 の literal 証跡として最強、 memory inspection は「resolver が正しく id を立てた」 確認、 両方ないと proof が片足、 「L 違う + M-Q 同じ + keyon 数同じ」 の 3 件同時で「意図した ch だけ差分」 「副作用なし」 「silent 化していない」 を 1 script で literal 化、 試聴 は ear gate として独立軸 (= `feedback_audio_gate_solo_isolation` 整合)、 driver source 改修なので regression 必須、 「2 run で diff が出た」 だけだと noise でも PASS する trivial、 addr 値そのものを literal に書くと改修ミスで addr が変化した場合検出できる、 Step 9/10 と同パターンで script 配置で既存 step5 / step10 script を base に派生。

**5-b 重要安全装置: keyon count identical**

mismatch silent path に倒れても「差分がある」 だけなら PASS してしまう。 Step 11 の本質は **「selection により違う sample が鳴る」** であって **「silent になる」 ではない**。 keyon count identical を入れることで「同じ回数鳴っている、 でも sample addr が違う」 を literal に証明できる。

## 決定

### 決定 1: step 11 を「multi-table id=0x01 proof sprint」 として定義 (= A1 継続 + 2 entry proof)

step 11 の最終 deliverable boundary を **「2 entry directory + 2 table + selector id=0x01 accept」** とする。 driver は filename によって異なる id を立て、 selector が id によって異なる table から L ch sample pointer を返却することで、 `sample_table_id` が selection key として機能することを literal 観測可能にすることを目的とする。

#### A2 selected pointer cache は scope-out 維持

selected pointer runtime state cache (= A2 / A3 相当) は Step 11 でも scope-out 維持。 selector は per-keyon に呼出し続け、 runtime state は `sample_table_id` (= 0xFD32、 1 byte) のままに保つ。 動的化局面 (= multi-table runtime / dynamic reload / bank switching / `.PNE` runtime parser) が成立する将来 sprint で A2 / A3 を再検討する。

採用根拠: ADR-0024 §決定 6 (= selected pointer runtime state は持たない) との連続性、 `sample_table_id` 再生中不変 / per-keyon resolve は構造的に冗長だが実害小、 「再生中不変な runtime state は cache 化しない」 という設計判断軸を Step 11 でも維持 (= memory `project_pmdneo_step11_a2_deferred` 整合)。

#### Step 10 → Step 11 拡張点

ADR-0024 で確立した contract のうち、 Step 11 で **拡張** されるのは:

- 受入 id 範囲: `{0x00}` → `{0x00, 0x01}`
- table 数: 1 (= `adpcma_ch_sample_ptr_table`) → 2 (= `adpcma_ch_sample_ptr_table` + `adpcma_ch_sample_ptr_table_b`)
- directory entry 数: 1 (= `step5.PNE`) → 2 (= `step5.PNE` + `step5b.PNE`)
- `.MN` fixture 数: 1 (= `step5.MN`) → 2 (= `step5.MN` + `step5b.MN`)

Step 11 で **不変** に保つもの:

- selected pointer runtime state cache 不採用 (= ADR-0024 §決定 6 維持)
- `adpcma_keyon_simple` keyon path (= ADR-0024 §決定 5 で改修済の最終形)
- `pmdneo_select_sample_pointer` ABI (= 入力 voice index + 0xFD32 read、 出力 DE = pointer or 0x0000 sentinel、 ADR-0024 §決定 4 維持)
- sentinel pointer 0x0000 silent semantics (= ADR-0024 §決定 3 維持、 id 上限超過にも適用拡張)
- sample table addr は依然 build-time `samples.inc` 経由で固定埋込 (= ADR-0019 §決定 3 / ADR-0024 §決定 2 1-A 維持)

### 決定 2: table B 構成 = L ch only sample swap、 M-Q = table A と完全同 pointer (= axis 1 / i 採用)

`adpcma_ch_sample_ptr_table_b` (= 新規 label) を以下の構成で追加:

| ch | table A (= `adpcma_ch_sample_ptr_table`) | table B (= `adpcma_ch_sample_ptr_table_b`) |
|---|---|---|
| L | sample BD (= `@0` 相当) | sample SD (= `@1` 相当、 既存 VROM 内 sample 再利用) |
| M | sample X | sample X (= table A と同 pointer / 同 symbol) |
| N | sample Y | sample Y (= table A と同 pointer / 同 symbol) |
| O | sample Z | sample Z (= table A と同 pointer / 同 symbol) |
| P | sample W | sample W (= table A と同 pointer / 同 symbol) |
| Q | sample V | sample V (= table A と同 pointer / 同 symbol) |

実装上 M-Q entries は table A と同 symbol を `.dw` で参照することで物理的に同 pointer を保証 (= memory layout 上は別 word だが、 中身の addr 値は同一)。

#### 採用根拠

- L ch primary observation 軸が Step 5/6/7 で確立済、 verify infra と相性が良い
- M-Q identical 期待値で「副作用なし」 (= id 切替で L 以外の ch が影響を受けない) を literal 証明
- 最小 differential で trivial verify 化しにくい
- 新規 wav import は scope-out (= asset pipeline / conversion / provenance の論点を Step 11 に持ち込まない)
- 既存 VROM 内 sample 再利用なら VROM / converter / `.PNE` pipeline を完全不変

#### sample 選定 (= α 採用、 詳細は α sub-sprint で確定)

`adpcma_ch_sample_ptr_table_b` の L ch entry に割当てる既存 VROM 内 sample は α sub-sprint で `samples.inc` を読んで確定する。 典型的に既存 `@0` (= BD 相当) と `@1` (= SD 相当) が VROM 内に存在するので、 これを再利用する想定。 異なる方が register diff 観測上 clearer であれば別 sample を選ぶ余地あり。 ただし新規 sample 追加は scope-out。

### 決定 3: filename / fixture 命名 = step5.PNE / step5b.PNE 既存維持 + 派生 (= axis 2 / 推奨組合せ採用)

filename / `.MN` fixture の命名 contract:

| fixture | role | 扱い |
|---|---|---|
| `step5.PNE` | baseline (= filename A) | 既存維持 (= ADR-0021 / ADR-0022 / ADR-0023 / ADR-0024 で確立済の primary fixture) |
| `step5b.PNE` | table B selection fixture (= filename B) | 新規追加 (= α sub-sprint) |
| `step5.MN` | baseline (= MML body + `#PNEFile step5.PNE`) | 既存維持 |
| `step5b.MN` | step5.MN 派生 (= MML body 同一流用 + `#PNEFile step5b.PNE` のみ差替) | 新規追加 (= α sub-sprint) |

#### MML body 同一流用根拠

差分原因を「filename が違う → id が違う → L ch sample addr が違う」 に限定するため、 MML body は完全同一とする。 keyon 数 / note 順 / volume / pan / freq 等の演奏要素はすべて同一。 これにより:

- step5.MN run と step5b.MN run の register trace は L ch ADPCM-A addr regs (= 0x10/0x18/0x20/0x28) のみ differ する期待値が成立
- M-Q ch register writes / FM register writes / SSG register writes / keyon trigger 数 / tempo / loop / fade 等はすべて identical
- 差分の root cause が filename / table selection の 1 点に絞れる

#### ADR / handoff 記載 contract

- `step5.PNE` = baseline fixture (= primary 観測 fixture、 Step 5-10 で確立)
- `step5b.PNE` = table B selection fixture (= Step 11 で新規追加)
- 命名は **runtime proof 用、 asset canonical name ではない**
- `PMDNEO01.PNE` (= ADR-0023 γ 経緯で出てきた asset canonical 想定名) とは役割が異なる
- 将来 D3 generated directory に移行する際、 fixture 命名の asset canonical 化は別 sprint で検討

### 決定 4: directory entry format = Step 9 既存 layout 踏襲 (= filename 16 byte + sample_table_id 1 byte + 0xFF terminator)、 entry_index = id byte 値一致 convention、 EQU 軽柔軟性 (= axis 3 / α + α' 採用)

`.PNE` 内 directory の format / 拡張方針:

#### entry layout (= Step 9 既存 layout 踏襲、 axis 3-c 採用整合)

| entry | filename (16 byte、 NUL-pad ASCII) | sample_table_id (1 byte) |
|---|---|---|
| 0 | `"step5.PNE\0\0\0\0\0\0\0"` (= 9 char + 7 NUL = 16 byte) | `0x00` |
| 1 | `"step5b.PNE\0\0\0\0\0\0"` (= 10 char + 6 NUL = 16 byte) | `0x01` |
| terminator | `0x00 × 16` (= don't care) | `0xFF` (= terminator marker) |

- entry stride = **17 byte** (= filename 16 + sample_table_id 1) (= Step 9 既存 layout 踏襲)
- terminator = **sample_table_id == `0xFF`** marker (= entry の filename field は don't care、 17th byte が `0xFF` なら resolver は loop 終了 + mismatch branch)
- resolver は **terminator driven loop** (= entry 数 hard-code なし、 自然に entry 追加に追従、 既存 routine `pmdneo_resolve_sample_table_id` 完全不変)
- sample_table_id byte literal は **entry_index と一致する convention** で書く (= entry 0 byte = `0x00`、 entry 1 byte = `0x01`)、 この一致は Step 11 proof 用の暫定規約
- match 優先 = **先勝ち** (= 最小実装、 resolver は entry 0 から順に memcmp、 最初の match で確定、 重複 filename は実運用想定外で scope-out)

#### Step 11 で entry 1 を追加 (= α scope)

既存 entry 0 と terminator entry の間に entry 1 (= filename `step5b.PNE` + `sample_table_id 0x01`) を挿入。 terminator entry は 17 byte 後ろにずれる。 resolver は terminator driven のため code 改修不要、 entry 1 を自然に loop 対象として認識する。

#### EQU 定数導入 (= α' 採用、 selector 上限判定用)

`PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` を driver source に α で宣言追加。 用途:

- **resolver は参照しない** (= terminator driven loop のため、 本 EQU は resolver 動作に無関係)
- **selector が β で参照** (= `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` で id 上限判定、 範囲外は sentinel silent に倒す)
- 1 つの定数で「directory entry 数」 と「accepted id range」 を同期する規約 (= entry 数変更時 1 行修正で driver 全体に伝播)

α 時点では declare のみで unused reserve、 β の selector 拡張で参照開始する。

#### ADR / handoff 記載 contract

- **entry の `sample_table_id` byte 値は entry_index と一致するように書く convention** (= explicit id byte field 自体は Step 9 から既存、 Step 11 で値の決め方を convention 化)
- 最終 directory ownership / explicit id 自由割当 / count header / multi-entry random access は **D3 migration 以降で再検討** (= ADR-0021 §決定 / generated directory 化局面で)
- duplicate filename 処理は **scope-out**、 現時点では先勝ち
- `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は **entry 数 + accepted id range の上限を兼ねる**
- entry 数を変更する将来 sprint では本 EQU の 1 行修正 + directory entry 追記 + terminator 位置移動で対応 (= resolver / selector の hard-code を増やさない)

### 決定 5: selector accept rule 拡張 = explicit if/jr + table 隣接 + `_b` suffix (= axis 4 / 推奨組合せ採用)

`pmdneo_select_sample_pointer` (= ADR-0024 §決定 4 で確立) の accept rule 拡張:

#### routine 擬似コード (= 拡張後)

```
pmdneo_select_sample_pointer:
    ; 入力: A = voice index
    ; 出力: DE = sample header pointer or 0x0000

    push    af                              ; voice index 退避
    ld      a, (driver_pne_sample_table_id)
    ;; id 範囲 check (= axis 4 / 4-e EQU 再利用)
    cp      #PNE_SAMPLE_DIRECTORY_ENTRY_COUNT
    jr      nc, .select_unknown_id          ; id >= EQU → sentinel
    ;; id 値で dispatch (= axis 4 / 4-a explicit if/jr)
    or      a
    jr      z, .use_table_a                 ; id == 0x00 → table A
    cp      #1
    jr      z, .use_table_b                 ; id == 0x01 → table B
    ;; (future: cp #2 / jr z, .use_table_c ... の形で N table 拡張)
    ;; ここに来るのは EQU >= 3 の不整合時のみ (= 通常 unreachable)
    jr      .select_unknown_id

.use_table_a:
    pop     af
    ld      l, a
    ld      h, #0
    add     hl, hl                          ; HL = voice * 2
    ld      de, #adpcma_ch_sample_ptr_table
    add     hl, de                          ; HL = sample ptr table entry
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ret

.use_table_b:
    pop     af
    ld      l, a
    ld      h, #0
    add     hl, hl                          ; HL = voice * 2
    ld      de, #adpcma_ch_sample_ptr_table_b
    add     hl, de
    ld      e, (hl)
    inc     hl
    ld      d, (hl)
    ret

.select_unknown_id:
    pop     af
    ld      de, #0x0000
    ret
```

#### table B 物理 layout = table A 隣接 (= axis 4 / 4-b 採用)

```
adpcma_ch_sample_ptr_table:        ; (= 既存、 ADR-0019 §決定 3 / ADR-0024 §決定 2 維持)
    .dw     sample_ptr_l_a
    .dw     sample_ptr_m
    .dw     sample_ptr_n
    .dw     sample_ptr_o
    .dw     sample_ptr_p
    .dw     sample_ptr_q

adpcma_ch_sample_ptr_table_b:      ; (= 新規追加、 Step 11 α sub-sprint)
    .dw     sample_ptr_l_b          ; (= table A と異なる sample、 既存 VROM 内 sample 再利用)
    .dw     sample_ptr_m            ; (= table A と同 symbol、 物理的に同 pointer)
    .dw     sample_ptr_n            ; (= table A と同 symbol)
    .dw     sample_ptr_o            ; (= table A と同 symbol)
    .dw     sample_ptr_p            ; (= table A と同 symbol)
    .dw     sample_ptr_q            ; (= table A と同 symbol)
```

#### 採用根拠

- explicit if/jr: 2 table なら最も読みやすい、 table-of-tables / uniform calc は overkill
- 隣接 layout: maintenance 性、 proof 用差分が読みやすい、 別 section / 別 file は build 構造を変える scope expansion
- `_b` suffix: filename `step5b.PNE` と命名軸が揃う、 numeric suffix は index 軸の意味になり semantic 不在
- sentinel 流用: Step 10 mismatch silent path 挙動を完全保存、 regression risk 0
- EQU 再利用: axis 3 で EQU 化したのに axis 4 で hard-code 2 を再導入すると意図逸脱、 EQU 1 個で directory entry count と selector 上限を同期

#### ADR / handoff 記載 contract

- explicit branch は **Step 11 proof 用**
- N table 化する場合は **table-of-tables / generated directory で再検討**
- `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は accepted id range の上限にも使う
- `id >= PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` は sentinel silent

#### 4-a / 4-e 軽い混在の許容

explicit if/jr 形式で書きつつ EQU で上限管理する軽い混在は許容。 完全整合 (= table-of-tables で EQU loop) は D3 migration 以降の課題。

### 本質再確認 (= 決定 6 verify gate 設計前の purpose reminder、 future contributor 向け literal 明記)

**Step 11 の目的は multi-table architecture の完成ではなく、 selection differentiation が observable であることの proof である**。 具体的には:

- ✅ Step 11 で達成: `sample_table_id` が selection key として機能することの literal 観測 (= 2 entry / 2 table で最小成立、 L ch addr regs の differ / M-Q identical / keyon count identical の 3 観点同時)
- ✗ Step 11 で達成しない: generated directory (= D3 migration) / table-of-tables refactor / selected pointer cache (= A2/A3) / runtime `.PNE` parser / multi-`.PNE` switching / bank switching

future contributor が Step 11 完了状態を「multi-table 完成版」 と誤解せず、 **「proof-of-selection stage」** として扱えるよう本 ADR で literal 固定。 multi-table architecture 完成は本 ADR §scope-out 群を含む将来 sprint で段階的に進める。 §決定 6 以下の verify gate 設計はこの「proof-of-selection stage」 という目的に整合させる (= 「complete multi-table」 ではなく「observable selection differentiation」 を検証する)。

### 決定 6: verify gate = hybrid + 3 観点同時 + literal value assert (= axis 5 / 推奨組合せ採用)

Step 11 の verify gate 構造:

#### primary gate = differential register trace

`step5.PNE` run と `step5b.PNE` run の ymfm-trace を比較し、 以下 3 観点を **同時** に literal 検証:

| 観点 | 期待値 | 検証手段 |
|---|---|---|
| L ch ADPCM-A addr regs (= `0x10/0x18/0x20/0x28`) | **differ** | step5 addr literal vs step5b addr literal、 両方の値を script に書込で trivial verify 防止 |
| M-Q ch ADPCM-A addr regs (= 同 group の M-Q) | **identical** | M-Q reg writes byte-identical 比較、 副作用なし証明 |
| keyon trigger count (= reg `0x00`) | **identical** | 両 run で同 count、 silent path 経由ではない literal |

#### secondary gate = memory inspection

step5.PNE run / step5b.PNE run それぞれの 0xFD32 値を memory inspection で確認:

- `step5.PNE` run → `0xFD32` = `0x00` (= entry 0 match)
- `step5b.PNE` run → `0xFD32` = `0x01` (= entry 1 match)

これにより「resolver が正しく id を立てた」 を独立に検証 (= primary とは別の観測点)。

#### tertiary gate = user 試聴

- `step5.PNE` run = BD audible (= L ch table A から BD sample 再生)
- `step5b.PNE` run = SD audible (= L ch table B から SD sample 再生)
- silent 経路 (= mismatch / id 上限超過) に倒れていない ear 確認

#### regression gate = 既存 Step 5-10 verify script 群

既存 Step 5/6/7/8/9/10 verify script 全件 PASS 維持 (= 約 12 script + 50 gate)。 driver source 改修なので regression 必須。

#### trivial verify 防止 = literal register value assert

- BD addr literal (= `0xZZZZ` 形式の具体値) を script に書込
- SD addr literal (= `0xYYYY` 形式の具体値) を script に書込
- 「diff 件数が N」 だけでなく「両 run でこの addr 値が観測される」 を literal assert

これにより noise や unintended addr shift で false PASS する trivial を防げる。

#### verify script 新設 = `verify-step11-multi-table.sh`

Step 9/10 pattern と同じく、 Step 11 専用の差分 verify script を新設:

- 入力: step5.PNE / step5b.PNE 各 ROM
- 動作: 両方を MAME headless で再生 → ymfm-trace 取得 → 差分 assert
- 出力: PASS / FAIL + 詳細 log

#### 5-b 重要安全装置: keyon count identical

mismatch silent path に倒れても「差分がある」 だけなら PASS してしまう。 Step 11 本質は **「selection により違う sample が鳴る」** であって **「silent になる」 ではない**。 keyon count identical を入れることで「同じ回数鳴っている、 でも sample addr が違う」 を literal 証明する。

具体 expected value:
- `step5.PNE` run keyon count = N (= MML body の note 数)
- `step5b.PNE` run keyon count = N (= 同 MML body、 同 keyon 数)
- 両方で keyon count が一致 + addr regs が differ = proof 成立

### 決定 7: 暫定規約 + ADR / handoff 記載 contract (= future contributor 向け literal 固定)

Step 11 で導入される暫定規約 / 命名 contract を future contributor 向けに literal 明記:

| 項目 | 内容 | 再検討契機 |
|---|---|---|
| entry の `sample_table_id` byte 値 = entry_index 一致 convention | Step 9 から explicit id byte field 自体は既存、 Step 11 で「値は entry_index と一致するように書く」 と convention 化 (= entry 0 → 0x00 byte、 entry 1 → 0x01 byte) | D3 generated directory migration 以降で id 自由割当を再検討 |
| filename 命名 `step5b.PNE` 等 | runtime proof 用、 asset canonical 名ではない | asset canonical 化が必要な sprint で別途 |
| `PMDNEO01.PNE` との区別 | `PMDNEO01.PNE` は ADR-0023 γ 経緯の asset canonical 想定名、 `step5*.PNE` とは役割が異なる | D3 migration 以降で命名軸統合検討 |
| explicit if/jr selector dispatch | Step 11 proof 用、 N table 化は別 sprint | multi-table が 3 table 以上になる sprint で table-of-tables 化検討 |
| `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` 兼用 | entry 数 + accepted id range 上限を 1 定数で同期、 resolver は参照せず (= terminator driven) selector が β で参照 | 暫定規約として継続維持 |
| duplicate filename = 先勝ち | 最小実装、 重複は実運用想定外 | duplicate を意図的に許容する sprint で別途 |
| MML body 同一流用 | 差分原因を filename / table selection に限定 | proof 完了後の現役 fixture では body 変更可 |
| resolver terminator driven loop 継承 | Step 9 既存 routine 完全不変、 entry 数増減は terminator 位置で表現 (= EQU 不参照) | future D3 migration で count header / static count 化検討時に変更 |

### 決定 8: sub-sprint 分割 = α/β/γ/δ 4 段 (= 12th session α 着手時に user 指示で revised、 ADR commit を α と分離 + 旧 α/β を新 α に合流)

step 11 を **α / β / γ / δ の 4 sub-sprint 構造** で進める。 trivial verify (= ADR-0016 step 3c-2 / V-1 / W-1 / W-3 / ADR-0023 / ADR-0024 で確立した「dead code → call insertion → behavior change」 段階分離) を防ぐため、 各 sub の primary gate を明確化する。

#### 12th session α 着手時の sub-sprint 分割改定

ADR-0025 commit (= `bc60663`) 直後、 user 12th session α 着手指示で sub-sprint 分割は以下に **revised**:

- **ADR-0025 起票は α と分離** (= 単独 commit `bc60663` で完了済、 driver source 不変の純文書化)
- **旧 α + 旧 β を新 α に合流** (= EQU 宣言 + directory entry 1 + table B + step5b fixture をすべて α scope)
- **selector 拡張は新 β** (= 元 γ scope を β に前倒し)
- **verify script 新設は新 γ** (= 元 δ 前半を γ に分離)
- **regression + audible + Accepted 移行は新 δ** (= 元 δ 後半のみ)

revised split の理由 (= user 12th session α 着手時整理):
- Step 11 α は fixture / table / directory / EQU など複数軸が入るため、 ADR を先に固定してから実装に入った方が review が読みやすい
- 旧 resolver が **terminator driven** で entry 数を hard-code しない finding により、 EQU declaration を α に前倒ししても resolver code 改修なしで成立 (= EQU は β で selector が参照開始する unused reserve)
- これにより α は driver code path 完全不変 = pure data placement、 「data placement / selector behavior / verify infra / completion」 の 4 軸分離が clean に成立

#### revised sub-sprint table

| sub | 範囲 | primary gate |
|---|---|---|
| α | (post ADR commit) `adpcma_ch_sample_ptr_table_b` 追加 (= dead code、 selector 未拡張) + `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` 新規 fixture + `pne_sample_directory` entry 1 = `step5b.PNE` + `0x01` byte 挿入 + `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` 宣言 (= α では unused reserve) + ADR-0025 §決定 8 sub-sprint 表改定 | build PASS + step5.PNE register write trace byte-identical (= regression 0) + 新 symbol 存在確認 (= table B / directory entry 1 / EQU) + driver source の resolver / selector / keyon path 完全不変 (= terminator driven resolver は自然に entry 1 を見るが、 selector id=0x00 only-accept のため step5b.PNE run は依然 sentinel silent) |
| β | `pmdneo_select_sample_pointer` 拡張 (= id=0x01 accept、 explicit if/jr、 `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` で範囲外判定、 `adpcma_ch_sample_ptr_table_b` 引き) | build PASS + step5.PNE register write trace byte-identical (= regression 0) + step5b.PNE run `0xFD32` = `0x01` (= memory inspection primary) + step5b.PNE run L ch addr regs differ literal + step5b.PNE run M-Q addr regs identical + step5b.PNE run keyon count = step5.PNE run keyon count + step5b.PNE run audio audible (= silent ではない、 L ch SD 音色) |
| γ | `verify-step11-multi-table.sh` 新設 (= differential proof script、 step5.PNE / step5b.PNE 比較 + L differ / M-Q identical / keyon count identical の 3 観点同時 + BD addr literal / SD addr literal 具体値 assert で trivial verify 防止) | script PASS + 既存 Step 5/6/7/8/9/10 verify script regression 全件確認 |
| δ | user 試聴 (= step5 BD audible / step5b SD audible secondary gate) + ADR-0025 Accepted 移行 + handoff doc 起票 + memory `project_pmdneo_step11_complete.md` 起票 + MEMORY.md index 更新 | 全 sub primary gate PASS + 既存 verify regression PASS + audible OK |

#### α 時点での重要境界 (= revised 後の future contributor 向け短文明記)

**Step 11 α 時点では `adpcma_ch_sample_ptr_table_b` は dead code (= selector 未拡張で到達しない)、 directory entry 1 = `step5b.PNE` は resolver から read される (= terminator driven のため自然に追加 entry を見る)、 `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` EQU は declare 済だが selector 未拡張のため unused reserve**。 α 完了時点で:

- step5.PNE run: 既存挙動完全保存 (= filename match → `0xFD32` = `0x00` → selector id=0x00 accept → table A 引き → audible)
- step5b.PNE run: resolver は entry 1 を match → `0xFD32` = `0x01` (= memory inspection で observable な新挙動)、 selector は id=0x00 only-accept のため sentinel silent → keyon trigger 0 → audio silent
- 「id=0x01 はまだ playback に影響しない」 (= user α scope 整合、 0xFD32 値は変わるが playback は silent path 経由で不変)
- ADR-0024 §決定 3 (= id=0x00 only-accept) は **依然有効** (= selector 完全不変)
- table B symbol は ROM に存在するが selector からは到達しない (= dead code)
- EQU 定数は declare 済だが driver code から参照されない (= β で selector が参照開始)
- step5.PNE run register write trace は Step 10 完了時 (= commit `0746073`) と byte-identical

β で selector 拡張により selection differentiation が initial に effective になる (= step5b.PNE run で L ch = table B 引きで SD addr regs write、 audible 差分が出る)。 γ で literal value assert script を新設して formal proof 確立。 δ で regression + audible + completion 統合。

**1 sub = 1 commit + 1 push 規律** (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) を維持。 各 commit で user 都度レビュー待ち。

#### revised 分割根拠

- α は「data placement only」 (= driver code path 完全不変、 connect 未挿入、 EQU は unused reserve) → trivial verify (= 既存 path で false PASS) を detect しやすい pure dead code 段階
- β で selector 拡張により id=0x01 accept、 step5b.PNE で L ch table B 引きが effective → differential register trace で「selection が effective」 を literal 観測、 audio で audible 差分が出る
- γ で literal value assert script を新設 (= BD addr literal / SD addr literal 具体値で trivial verify 防止)、 既存 regression と並列確認
- δ で user 試聴 + Accepted 移行 + handoff + memory 起票で完了統合

## scope-in / scope-out 明示

### scope-in (= step 11 本 sprint 範囲、 12th session α 着手時 revised split に基づく)

- ADR-0025 起票 (= 単独 commit、 12th session 冒頭壁打ち 5 axes + §決定 8 件 + sub-sprint 分割を文書化) (= **ADR commit、 done at `bc60663`**)
- `adpcma_ch_sample_ptr_table_b` 新規追加 (= L ch のみ別 sample = adpcma_sample_sd、 M-Q = table A と同 symbol) (= α)
- `pne_sample_directory` に entry 1 = `step5b.PNE` + `0x01` byte 挿入 + terminator 後ろにずらし (= α、 resolver は terminator driven で自然に対応)
- `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` 宣言 (= α、 declare のみで unused reserve、 β で selector が参照開始)
- `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` 新規 fixture 作成 (= step5/l-q-rhythm-song.mml body 同一流用 + `#PNEFile "step5b.PNE"` 差替) (= α)
- ADR-0025 §決定 8 sub-sprint 表改定 (= revised split を ADR に反映) (= α 内、 α commit に含める)
- `pmdneo_select_sample_pointer` 拡張 (= id=0x01 accept、 explicit if/jr、 `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` 範囲外判定、 `_b` table 引き) (= β)
- `verify-step11-multi-table.sh` 新設 (= differential proof script、 L ch differ + M-Q identical + keyon count identical + literal value assert) (= γ)
- step 5/6/7/8/9/10 既存 verify script regression 全件確認 (= γ)
- MAME 試聴で step5 BD / step5b SD audible 確認 (= δ)
- step 11 完了統合 handoff doc + ADR-0025 Accepted 移行 + memory + MEMORY.md index (= δ)

### scope-out (= step 11 範囲外、 後続 sprint で扱う)

- selected pointer runtime state cache (= A2 / A3、 ADR-0024 §決定 6 維持、 memory `project_pmdneo_step11_a2_deferred` 整合)
- mismatch silent flag micro-sprint (= 別 runtime state で silent 化指示)
- D1 hand-written → D3 generated directory migration (= asset pipeline 軸、 別 sprint)
- `.PNE` binary runtime parse (= directory header / sample entry / addr table 動的読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- dynamic reload (= 動的 `.PNE` 差替)
- K/R rhythm compatibility 現役接続 (= ADR-0019 / ADR-0016 §決定 2 micro-sprint 候補、 Step 12 候補として温存)
- 新規 sample 追加 (= WAV import / ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- 未追跡 wav 3 件 (= `lefthook.wav` / `lightbulbbreaking.wav` / `woosh.wav`) (= Step 11 では touch しない、 handoff で「not used」 明記)
- mc compiler / vromtool.py / converter / `samples.inc` 改修
- PPZ compatibility mode
- FM-Towns-style rhythm mode
- 3 table 以上の multi-table 化 (= table-of-tables refactor が必要な段階)
- explicit id field 化 (= D3 migration 以降で再検討)
- duplicate filename 処理
- terminator / count header 化
- `adpcma_keyon_simple` 全体 refactor (= ADR-0019 / ADR-0024 §scope-out 維持)
- `adpcma_ch_sample_ptr_table` rename (= ADR-0024 §scope-out 維持)
- PMDNEO.s + nullsound integration (= 大規模 sprint)

## 完了判定

### step 11 全体完了判定 (= ADR-0025 Accepted 移行条件、 revised split 後)

1. **ADR**: ADR-0025 draft file 起票 (= 章 1-5 全章記述、 Annex は δ で追記) + commit + push (= **done at commit `bc60663`**)
2. **α**: `adpcma_ch_sample_ptr_table_b` 追加 (= L ch のみ別 sample、 M-Q = table A 同 symbol、 dead code 状態)
3. **α**: `pne_sample_directory` entry 1 = `step5b.PNE` + `0x01` byte 挿入 (= terminator 後ろ移動、 resolver は terminator driven で自然対応)
4. **α**: `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` 宣言 (= α では unused reserve)
5. **α**: `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` 新規 fixture 作成 + ADR-0025 §決定 8 sub-sprint 表改定 (= revised split を ADR に反映) + commit + push
6. **α**: build PASS + step5.PNE register write trace byte-identical (= regression 0) + 新 symbol 存在確認 (= table B / directory entry 1 / EQU) + driver source の resolver / selector / keyon path 完全不変
7. **β**: `pmdneo_select_sample_pointer` 拡張 (= id=0x01 accept + EQU 上限判定 + table B 引き) + commit + push
8. **β**: build PASS + step5.PNE byte-identical + step5b.PNE run `0xFD32` = `0x01` + L ch addr differ literal + M-Q identical + keyon count identical + audio audible (= silent ではない)
9. **γ**: `verify-step11-multi-table.sh` 新設 (= differential proof script、 BD addr literal / SD addr literal 具体値 assert) + step 5/6/7/8/9/10 既存 regression 全 PASS + commit + push
10. **δ**: user 試聴 (= step5 BD audible / step5b SD audible) + ADR-0025 Accepted 移行 + handoff doc 起票 + commit + push
11. **δ**: memory `project_pmdneo_step11_complete.md` 起票 + MEMORY.md index 更新

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## verify gate 構成 (= revised split 後)

### α gate (= data placement 段階、 4 段)

1. **build PASS**: sdcc / sdasz80 / lkz80 通過、 ROM .neo 生成
2. **step5.PNE register write trace byte-identical**: reachable code path 完全不変 (= table B / entry 1 / EQU が dead/unused、 driver の resolver / selector / keyon source 完全不変、 既存 register write 完全一致)
3. **新 symbol 存在確認**: `.lst` / `.map` / symbol dump で `adpcma_ch_sample_ptr_table_b` + `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` + `pne_sample_directory` 領域内の entry 1 (= "step5b.PNE" string + 0x01 byte) が確認可能
4. **driver source 完全不変確認**: `pmdneo_resolve_sample_table_id` / `pmdneo_select_sample_pointer` / `adpcma_keyon_simple` の code 行が Step 10 完了時 (= commit `0746073`) と byte-identical (= data 領域のみ追加、 routine 自体は無改修)

(= step5b.PNE run の動的 verify は β scope で初めて行う。 α では data placement のみで step5b 駆動 verify は不要、 user α scope 「id=0x01 はまだ playback に影響しない」 整合)

### β gate (= selector 拡張、 6 段)

1. **build PASS**: 同上
2. **step5.PNE register write trace byte-identical**: match path で既存 audio 再現 (= 0xFD32 = 0x00 で table A 引き、 既存 register write 完全一致、 regression 0)
3. **step5b.PNE run `0xFD32` = `0x01`**: memory inspection primary gate (= resolver が entry 1 を見て filename match 成立、 id=0x01 立つ、 α から確認可能だが β で audio に反映)
4. **step5b.PNE run L ch addr regs differ literal**: L ch reg `0x10/0x18/0x20/0x28` write 値が step5 と異なる、 step5 = BD addr literal / step5b = SD addr literal で具体値 observable
5. **step5b.PNE run M-Q addr regs identical**: M-Q ch reg `0x10/0x18/0x20/0x28` write 値が step5 と byte-identical (= 副作用なし)
6. **step5b.PNE run keyon count = step5.PNE run keyon count**: 両 run で keyon trigger 数が一致 (= silent 経路ではない literal、 selection differentiation が effective)

### γ gate (= verify infra 確立、 包括)

1. **build PASS**: 同上
2. **`verify-step11-multi-table.sh` PASS**: differential proof script、 β gate 4-6 + BD addr literal / SD addr literal 具体値 assert で trivial verify 防止
3. **step 5 verify script 全件 PASS**
4. **step 6 verify script 全件 PASS**
5. **step 7 verify script 全件 PASS**
6. **step 8 verify script 全件 PASS**
7. **step 9 verify script 全件 PASS**
8. **step 10 verify script 全件 PASS**

### δ gate (= audible + completion、 包括)

- silent-bcef fixture audible regression なし最終確認 (= verify-silent-bcef-audio-isolation.sh PASS)
- step5 BD audible 試聴 OK (= user)
- step5b SD audible 試聴 OK (= user、 silent ではない、 BD と区別可能)
- handoff doc 起票
- ADR-0025 Accepted 移行
- memory + MEMORY.md update

## 関連 memory

- `project_pmdneo_step10_complete.md` (= step 10 完了状態、 identity → selection consumption 成立、 ADR-0024 Accepted)
- `project_pmdneo_step11_a2_deferred.md` (= 12th session 冒頭判断、 A2 selected pointer cache scope-out、 A1 per-keyon selector 継続)
- `project_pmdneo_step11_direction_multi_table.md` (= 12th session、 multi-table id=0x01 proof sprint 採用判断 + scope 境界)
- `project_pmdneo_step9_complete.md` (= step 9 完了状態、 0xFD32 identity resolver 成立)
- `project_pmdneo_step8_complete.md` (= step 8 完了状態、 runtime filename observation 成立)
- `project_pmdneo_step7_complete.md` (= step 7 完了状態、 `.PNE` asset pipeline 成立)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 11 は「runtime selection」 軸の 2 段目)
- `project_pmdneo_step6_complete.md` (= step 6 完了状態、 audio isolation 戦略、 silent-bcef fixture 流用)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ADPCM-A 6ch native path、 既存 keyon path 改修対象)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 Step 11 で differential register trace primary)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律、 α dead code → β resolver → γ selector の段階分離が直接対応)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 silent-bcef fixture 流用)
- `feedback_verify_script_serial_execution.md` (= verify script 群は serial 実行、 δ で適用)
- `project_pne_directory_entry_runtime_fixture_vs_asset_canonical.md` (= asset canonical vs runtime fixture 責務差、 Step 11 fixture 命名 contract と直接対応)

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= `.PNE` parser 次 sprint 接続点予約)、 §決定 4 (= sample addr は build 時 embed)
- ADR-0021 §Accepted 後の重要境界 (= runtime resolution は Step 8 以降)
- ADR-0022 §Accepted 後の重要境界 (= driver は filename を読めるが解決していない)
- ADR-0023 §決定 11 (= Step 9 内で sample_table_id は playback decision に使用しない、 ADR-0024 §決定 7 で解除済)
- ADR-0024 §決定 1-8 (= step 10 sample_table_id selection consumption、 §決定 3 id=0x00 only-accept は本 ADR §決定 5 で 0x00/0x01 accept に拡張)
- ADR-0024 §決定 4 (= 中間 routine ABI、 本 ADR で routine 内部のみ拡張、 ABI は完全維持)
- ADR-0024 §決定 6 (= selected pointer runtime state は持たない、 本 ADR §決定 1 で継続維持)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/design/mn_binary_layout.md` §4-3-3 / §7-2 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様、 step 7 α-1 起票、 directory 多 entry 化が本 ADR §決定 4 で適用)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止 / §「記憶は AI に、 判断は自分が握る」

## 次 sprint 候補

1. **α 着手 (= 本 commit 直後)** (= `adpcma_ch_sample_ptr_table_b` 追加 + `step5b.PNE` / `step5b.MN` fixture + directory entry 1 追加、 dead code 状態)
2. β 着手 (= `PNE_SAMPLE_DIRECTORY_ENTRY_COUNT EQU 2` 導入 + resolver loop EQU 参照化、 step5b.PNE run で 0xFD32 = 0x01 立つ)
3. γ 着手 (= selector id=0x01 accept、 explicit if/jr 拡張、 differential register trace primary gate 確立)
4. δ 着手 (= verify-step11-multi-table.sh 新設 + regression + audible + 完了統合 + Accepted 移行)
5. **step 12 候補** (= 本 ADR scope-out のうち未消化、 user 12th session 発言で K/R rhythm compatibility を Step 12 候補として温存):
   - K/R rhythm compatibility 現役接続 (= ADR-0016 §決定 2 micro-sprint 候補、 user 推奨温存)
   - mismatch silent flag micro-sprint (= 別 runtime state で silent 化指示、 future hook 性が強く CLAUDE.md 注意)
   - generated directory migration (= D1 → D3、 asset pipeline 軸)
   - 3 table 以上の multi-table 化 (= table-of-tables refactor)
   - selected pointer cache (= A2 / A3、 動的化局面で再検討)
   - overflow / edge-case hardening
   - `.PNE` runtime parser
   - bank switching / multi-`.PNE`
