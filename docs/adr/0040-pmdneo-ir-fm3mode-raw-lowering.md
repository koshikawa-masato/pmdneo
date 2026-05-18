# ADR-0040: FM3Mode → raw lowering 実装 (= ADR-0038 §決定 5 defer 解消 / ADR-0039 §決定 6 接続条件 literal 実装 / v0.5 内完結 / operator-split FNUM/Block register mapping literal 化 / driver runtime 不変 / 30th session 起点)

- 状態: **Draft** (= 2026-05-18 30th session 起票、 設計先行 ADR、 spike 実装 + fixture は本 ADR scope-out で別 sprint commit chain、 Accepted 移行は実装 sprint 完走後 + user 最終確認時、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture 完全不変 doc-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0034 (= IR design 6 軸、 §決定 3 で 3 層 hybrid SemanticEvent → ChipEvent → RawRegisterWrite ratify、 §決定 4 で FM3Mode ChipEvent + FMTone 共用 ratify)
  - ADR-0035 (= ChipEvent → RawRegisterWrite lowering、 §決定 5 で FMFrequency 2 register writes (= 0xA4 high → 0xA0 low 順序固定)、 §後続 sprint 列で「FM3Mode」 を別 ADR と明示、 本 ADR がその defer 解消)
  - ADR-0038 (= FM3Mode chip event、 §決定 5 で raw lowering 全体を「v0.5 以降別 ADR (= RMW/mask event 新設判断含む)」 に defer、 §決定 5-2 で 28 γ spike を chip event validation + identity pass-through に縮小、 本 ADR が defer 解消)
  - ADR-0039 (= RawRegisterMaskWrite event、 §決定 6 で FM3Mode raw lowering 接続条件 literal、 本 ADR がその接続条件を実装軸として展開)
- 関連設計書:
  - `docs/design/intermediate_register_command.md` §7-4 (= FM3Mode ChipEvent 仕様、 「lowering 時は 0x27 と 0xA8-0xAE 系 register write へ展開」 literal)
  - `docs/design/reference_intermediate_register_command.md` §3.1 (= FM3 拡張モード詳細、 0x27 bit 6-7 + 0xA8-0xAE operator 別 fnum/block)
  - `docs/design/intermediate-register-command/ir-schema-v0.5.schema.json` (= v0.5 schema、 FM3Mode chip event + RawRegisterMaskWrite raw event 両方 fully validated、 本 ADR で新規 event 追加なし)
  - `scripts/ir-lower-raw-register-spike.py` (= ADR-0035 raw lowering spike、 0xA4→0xA0 順序 invariant 既存実装、 本 ADR では touch なし regression risk 最小)

## 背景

ADR-0034 §決定 4 で FM3Mode ChipEvent + FMTone 共用を ratify、 ADR-0038 で v0.4 schema literal 化 + chip event validation + identity pass-through spike を実装。 ただし ADR-0038 §決定 5 で「FM3Mode → raw lowering 全体は v0.5 以降別 ADR (= RMW/mask event 新設判断含む) で扱う」 と defer 確定。 理由は 0x27 bit 6 = FM3 mode が **partial bit update (= RMW)** を要し、 既存 `RawRegisterWrite (port, address, data)` literal write では表現不可だったため。

29th session で ADR-0039 を起票し、 v0.5 schema に `RawRegisterMaskWrite (port, address, mask, value, trackId)` event を追加 (= 13 件目 fully validated event)。 ADR-0039 §決定 6 で FM3Mode raw lowering 接続条件 literal:

- FM3Mode (enabled=true) → `RawRegisterMaskWrite(port=0, address=0x27, mask=0x40, value=0x40)` + operator-split FNUM/Block literal writes
- FM3Mode (enabled=false) → `RawRegisterMaskWrite(port=0, address=0x27, mask=0x40, value=0x00)`
- operator-split FNUM/Block → `RawRegisterWrite` (= literal、 mask 不要)

本 ADR (= ADR-0040) はこの接続条件を **実装軸として展開** する: FM3Mode chip event を入力に取り、 ADR-0039 接続条件に従って v0.5 既存 raw event 2 種 (= RawRegisterMaskWrite + RawRegisterWrite) の列に lowering する spike + fixture を fix する設計 ADR。 schema 拡張なし (= v0.5 内完結)、 新規 event 追加なし。

CLAUDE.md §設計書ファースト + 26-29 session 確立の「ADR 起票 → (schema) → spike → fixture」 chain pattern を 30th session で踏襲。 ただし schema 拡張なしのため commit chain は α/γ/δ の 3 段 (= β skip)。

## 決定

### 決定 1: schema 拡張なし = v0.5 既存 event 2 種で完結

ADR-0040 は **schema を拡張しない**。 出力に使う raw event は v0.5 で既に fully validated な 2 種類:

- `RawRegisterWrite` (= ADR-0034 §決定 3 / ADR-0035 §決定 4 で確立、 literal data write)
- `RawRegisterMaskWrite` (= ADR-0039 §決定 1-7 で確立、 partial bit update)

ADR-0035 §決定 10 (= raw lowering で schema v0.3 不要判断) と同 pattern。 v0.6 schema 新設は本 ADR scope 外 (= event 種同一で version bump は churn のみ)。

選択肢:

- **A. v0.5 内完結 (= 採用)**: schema 拡張なし、 既存 event 2 種を組み合わせて lowering 表現可能
- B. v0.6 schema 新設 (= event 種同一 version bump): documentation 軸の差分明示は強くなるが、 event 種が増えない version bump は schema version の意味を薄める
- C. v0.6 + 新規 event (= FM3FrequencyExt 等 operator-split FNUM/Block 専用 chip event): ADR-0034 §決定 4 の「FM3Mode ChipEvent + operator frequency control」 と重複、 最小集合方針に反する

**判断**: ADR-0040 は **FM3Mode chip event の raw lowering 実装** であり、 schema 拡張は不要。 ADR-0035 が v0.2 既存 RawRegisterWrite のみで raw lowering を閉じた pattern と同じ。

### 決定 2: FM3Mode (enabled=true) → RMW + operator-split 列

`FM3Mode (enabled=true, operatorEnableMask, operatorBlock[4], operatorFnum[4], keyPolicy?)` を入力に、 同 tick 内で次の raw event 列を emit:

1. `RawRegisterMaskWrite(port=0, address=0x27, mask=0x40, value=0x40)` (= 0x27 bit 6 set、 ADR-0039 §決定 5)
2. operator-split FNUM/Block × 4 operator (= 後述 §決定 5 mapping table、 high → low 順 = 8 件の `RawRegisterWrite`)

合計 1 + 8 = **9 raw events** を emit (= enabled=true 1 件入力)。

### 決定 3: FM3Mode (enabled=false) → RMW のみ

`FM3Mode (enabled=false, ...)` を入力に、 次の raw event 1 件のみ emit:

1. `RawRegisterMaskWrite(port=0, address=0x27, mask=0x40, value=0x00)` (= 0x27 bit 6 clear、 ADR-0039 §決定 5)

operatorBlock / operatorFnum は schema 上 required (= ADR-0038 §決定 3 で「enabled=false 時も required、 任意値 0 placeholder で OK」) だが、 enabled=false 時は **operator-split register 書き込みを emit しない** (= driver runtime 軸で意味なし、 ADR-0038 §決定 3 整合)。

合計 **1 raw event** を emit (= enabled=false 1 件入力)。

### 決定 4: 0x28 KeyOn / keyPolicy は scope-out

`keyPolicy` (= "all" / "operator_masked"、 schema optional) と `operatorEnableMask` を **本 spike では使用しない**。 0x28 KeyOn 制御は既存 `KeyOn` chip event の raw lowering 責務 (= ADR-0035 §決定 6) に残し、 本 ADR では FM3Mode chip event を「mode + operator frequency 設定」 のみに分解。

理由:

- `keyPolicy` は upstream importer 軸の責務 (= MML → IR で FM3Mode + 後続 KeyOn 生成、 ADR-0034 §決定 4 整合)
- ADR-0038 §決定 4 の register table でも 0x28 KeyOn は別 lowering 経路 (= 既存 KeyOn event)
- ADR-0035 §決定 6 で 0x28 literal write は `(operatorMask << 4) | ch_code` 既定義、 RMW でも本 ADR でも touch なし

scope-out 明示:

- 0x28 KeyOn 自動挿入なし
- keyPolicy 解釈なし
- mode 切替直前 KeyOff 自動挿入なし (= ADR-0038 §決定 5-2 で別 sprint defer 済)

### 決定 5: operator-split FNUM/Block register mapping (= YM2608/YM2610 datasheet 流儀 + ADR-0035 §決定 8 slot offset 規律整合 literal 化)

FM3 extension mode (= 0x27 bit 6 = 1) 有効時、 ch 3 の 4 operator が独立 FNUM/Block を持つ。 IR の operator index (= op1-4、 FM3Mode field の index 0-3 に対応) と datasheet slot 番号 (= S1-S4) の対応は **非直線的** で、 ADR-0035 §決定 8 (= operator parameter register 0x30 base の slot offset = op1=0x00 / op2=0x08 / op3=0x04 / op4=0x0C) と同じ規律を踏襲する (= PMD/MewFM/ymfm/fmgen reference 慣習)。

register mapping (= datasheet + ADR-0035 §決定 8 整合、 exact 列挙 = 0xA2/0xA6/0xA8/0xA9/0xAA/0xAC/0xAD/0xAE、 ground truth = `vendor/pmd48s/source/pmd48s/PMD.ASM` L4512 + `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` L6605 + YM2608 Application Manual Table 2-2):

| operator (IR) | slot (datasheet) | FM3Mode field index | low byte register (= fnum LSB) | high byte register (= block + fnum high) |
|---|---|---:|---:|---:|
| op1 | slot 1 / S1 | `operatorBlock[0]` / `operatorFnum[0]` | 0xA9 | 0xAD |
| op2 | slot 3 / S3 | `operatorBlock[1]` / `operatorFnum[1]` | 0xAA | 0xAE |
| op3 | slot 2 / S2 | `operatorBlock[2]` / `operatorFnum[2]` | 0xA8 | 0xAC |
| op4 | slot 4 / S4 | `operatorBlock[3]` / `operatorFnum[3]` | 0xA2 | 0xA6 |

- 全 register は **port 0** (= ch3 共通 register、 ADR-0035 §決定 4 port mapping 整合)
- op4 (= slot 4 / S4) は通常 ch3 frequency register pair (= 0xA2 / 0xA6) を共用 (= datasheet 規律、 通常 mode から extension mode への切替で op4 frequency は通常 ch3 と同経路)
- IR `operatorBlock[i]` / `operatorFnum[i]` の i は **operator index (= op1-4 の 0-base)** で固定 (= ADR-0038 §決定 3 + schema v0.5 description「operator 1-4 個別 block / fnum」 literal)、 slot index への変換は本 lowering spike 内で table 適用
- byte encoding は ADR-0035 §決定 5 と同形式:
  - high byte: `(block << 3) | (fnum >> 8)` (= bit 5-3 = block, bit 2-0 = fnum high 3 bit)
  - low byte: `fnum & 0xFF` (= 下位 8 bit)

**ADR-0035 §決定 8 との整合**: ADR-0035 §決定 8 で「op1/op3/op2/op4 の literal 並びで slot offset 0/4/8/12」 と確立した operator parameter slot order を本 ADR でも踏襲。 すなわち FM3 extension frequency register の slot 割り当ても **op1→S1, op2→S3, op3→S2, op4→S4** で固定 (= operator parameter register と同じ slot mapping、 PMD/MewFM/ymfm/fmgen 慣習)。 これを破ると音色 + extension frequency の両方が壊れる。

選択肢:

- **A. ADR §決定 で table literal 化 (= 採用)**: ADR-0035 §決定 5 の 0xA4→0xA0 同 pattern、 spike 実装は本 table を ground truth として動く、 datasheet/ymfm/fmgen reference は ADR 内で参照
- B. ADR は概要のみ / spike で fix: ADR 量は減るが、 spike review 時に datasheet 検証負荷が混入、 「実装が仕様」 化 risk
- C. 別 sub-ADR (= ADR-0040-A 等) で reference 整合: chain 長くなる、 ADR-0040 主論点そのものを分離するのは過剰

**判断**: 本 ADR の主論点は「FM3Mode raw lowering 実装」 であり、 operator-split register mapping は実装核心。 ADR-0035 §決定 5 (= 0xA4→0xA0 literal) と同等の重みで本 ADR §決定 5 に literal 化する。

### 決定 6: register write 順序 invariant (= high → low / operator 番号順)

同 tick 内 emit 順序を次の literal 順で固定:

1. `RawRegisterMaskWrite(0x27, mask=0x40, value=0x40 or 0x00)` (= enabled bit 制御、 最初)
2. enabled=true 時のみ: operator-split FNUM/Block × 4 op (= op1, op2, op3, op4 の順)
3. 各 operator pair 内: **high byte (= 0xA*E/0xA*C/0xA*D/0xA6) 先 → low byte (= 0xA*A/0xA*8/0xA*9/0xA2) 後**

**順序 invariant の根拠**:

- 0x27 mode bit を **先に set** することで、 後続 operator-split register write が extension mode register として認識される (= 順序逆だと通常 ch3 frequency register として一時的に解釈される undefined window)
- ADR-0035 §決定 5 で確立した「high → low 順、 low write が latch trigger」 規律と同 pattern (= 0xA4 high → 0xA0 low を operator slot 毎に踏襲)
- operator 番号順 (= op1→op2→op3→op4) は決定的 emit 順保証のため (= spike 出力 byte-identical 維持、 datasheet/fmgen/ymfm reference は順序を強制しないが、 spike は decisive な順序で動く必要)

spike は同 tick 内で本 §決定 6 literal 順を生成、 sort 後も order 単調増加で順序維持 (= ADR-0035 §決定 9 同 pattern)。

### 決定 7: 新規 spike `scripts/ir-lower-fm3-raw-spike.py` 採用 (= ADR-0035/0038/0039 spike 全 unchanged)

26-29 session 確立の spike pattern を踏襲し、 **新規 spike** を採用する。

選択肢:

- **A. 新規 spike `scripts/ir-lower-fm3-raw-spike.py` 作成 (= 採用)**: 既存 ADR-0035 raw lowering spike (= 639 行、 v0.2 chip→raw) + ADR-0038 fm3mode chip event validation spike (= chip-to-chip identity) + ADR-0039 RMW raw spike (= raw-to-raw identity) すべて touch なし、 regression risk 最小、 27 γ tempo / 28 γ fm3 chip / 29 γ RMW pattern の自然な連続
- B. 既存 `ir-lower-raw-register-spike.py` 拡張 (= ADR-0035 chain): ADR-0035 spike に FM3Mode → raw lowering 認知追加。 既存 fixture byte-identical 維持必要、 regression surface 大
- C. 既存 `ir-lower-fm3mode-spike.py` 拡張 (= ADR-0038 chain): ADR-0038 §決定 5-2 で「raw lowering 全体は v0.5 以降別 ADR で defer」 と明示済の境界を侵食、 28 γ spike 性格を変える

**判断**: A 採用。 既存 3 spike (= raw / fm3mode chip / rmw) 全 unchanged で、 30th session 新規 spike は単一責務 (= FM3Mode chip event → RawRegisterMaskWrite + RawRegisterWrite 列の lowering)。

新規 spike 仕様 (= 別 sprint 30 γ で実装、 本 ADR は仕様 fix のみ):

- 入力: v0.5 IR (= FM3Mode chip event を含む、 他 event は schema-valid)
- 出力: v0.5 IR (= FM3Mode を §決定 2/3 に従って RawRegisterMaskWrite + RawRegisterWrite 列に展開、 他 event は pass-through identity)
- validation: schema 表現外の defense in depth (= operatorBlock 各 0-7 / operatorFnum 各 0-2047 / array length 4 / keyPolicy enum / 必須 field check / 型厳密 = type(x) is int / type(x) is bool)
- 共通規律 (= 26-29 session spike pattern 踏襲): sort + 重複 (tick, trackId, order) reject + timeMode delta reject + allocator order 再採番 + 出力 (tick, order) sort 正規化
- non-FM3Mode event は pass-through (= raw / chip / semantic 全 layer 不問、 ADR-0035 raw spike や ADR-0039 RMW spike の出力を経由した IR も入力として受理可能)

### 決定 8: scope-out 列

- schema v0.6 / 新規 event 追加 (= 本 ADR では schema 不変、 §決定 1)
- FM3FrequencyExt / 専用 chip event (= ADR-0034 §決定 4 最小集合方針)
- 0x27 bit 0-5/7 semantics (= ADR-0037 §決定 4 で defer、 driver runtime 軸別 ADR)
- 0x28 KeyOn 自動挿入 / keyPolicy 解釈 (= §決定 4 で既存 KeyOn lowering 経路に残す)
- mode 切替直前 KeyOff 自動挿入 / diagnostics (= ADR-0038 §決定 5-2 で別 sprint defer 済)
- driver runtime での実際の shadow register RMW 実行 (= driver code 側責務、 IR layer は expression 保持のみ、 ADR-0039 §決定 4 整合)
- optimization layer (= 同 address 連続 RMW の merge、 同一 mode 連続 FM3Mode 重複削減)
- importer 実装 (= MML → IR で FM3Mode を生成する側)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp 実装
- aesthetic / audio audition / automated CI
- vendor 不可触

## 後続 sprint 想定 (= 30 γ/δ chain)

| commit | 内容 |
|---|---|
| α (= 本 commit) | ADR-0040 起票 (= doc-only) |
| γ | 新規 spike `scripts/ir-lower-fm3-raw-spike.py` 実装 (= §決定 2/3/5/6/7 literal 実装) |
| δ | positive fixture (= enable / disable 各 1 件) + spike-invalid (= range / missing / duplicate 等) + README §IR FM3Mode raw lowering spike section + 全 regression |

本 ADR Accepted 移行は γ/δ commit chain 完走 + user 最終確認時。

## verify 計画 (= 本 ADR doc-only、 実装 verify は別 sprint)

### A. ADR 整合性
- ADR-0034 §決定 3/4 + ADR-0035 §決定 5 + ADR-0037 §決定 4 + ADR-0038 §決定 5 (defer 解消) + ADR-0039 §決定 6 (接続条件) と矛盾なし
- `intermediate_register_command.md` §7-4 + `reference_intermediate_register_command.md` §3.1 整合
- v0.5 schema fully validated event のみ使用 (= 新規 event 追加なし)

### B. 既存 chain 不変
- PR #3/#4/#5 merged + PR #6-#11 OPEN chain を壊さない
- v0.5 fixture / 既存 ADR-0035/0038/0039 spike output 完全不変 (= 本 ADR doc 追加のみ)
- v0.4/v0.3/v0.2/v0.1 backward-compat 全 PASS 維持

### C. 後続 sprint verify gate (= γ/δ commit chain で実施、 本 ADR では計画明示のみ)

- 30 γ: 新規 spike 単独動作 + enable fixture 入力で 9 raw events 出力 + disable fixture 入力で 1 raw event 出力 + invalid input exit 65
- 30 δ: positive deterministic byte-identical (= 2 回実行で同一出力) + spike-invalid 全 reject + ADR-0035/0038/0039 spike output 完全不変

## Annex

### A-1. 30th session 起点 / 後続 chain 計画

| sprint | 内容 | branch |
|---|---|---|
| 30 α (= 本 commit) | ADR-0040 起票 | `wip-ir-fm3mode-raw-lowering` (= base wip-ir-v0.5-rmw-mask-event-impl = PR #11 head) |
| 30 γ | 新規 spike 実装 | (= 27/28/29 pattern と同様、 同 branch or 別 branch impl) |
| 30 δ | fixture + 全 regression | (同上) |

stacked PR chain: main ← #3/#4/#5 merged ← #6 ADR-0037 ← #7 v0.3 impl ← #8 ADR-0038 ← #9 v0.4 impl ← #10 ADR-0039 ← #11 v0.5 impl ← **#12 (= 本 ADR PR、 doc-only)** ← #13 候補 (= 30 γ/δ 実装、 26-29 pattern で別 branch / 別 PR)

### A-2. FM3 operator-split register mapping table (= datasheet + fmgen + ymfm + PMD V4.8s 整合)

§決定 5 の table を本 Annex で再掲し、 各 operator pair の write byte 構成を例示:

```
operatorBlock = [4, 5, 6, 7]
operatorFnum  = [0x100, 0x200, 0x300, 0x400]
```

の場合の write byte 列 (= port 0 固定、 §決定 5 mapping table 適用):

| step | register | byte | encoding | operator (IR) | slot (datasheet) |
|---:|---:|---:|---|---|---|
| 1 | 0xAD | (4 << 3) \| (0x100 >> 8) = 0x21 | high (op1) | op1 | S1 |
| 2 | 0xA9 | 0x100 & 0xFF = 0x00 | low (op1) | op1 | S1 |
| 3 | 0xAE | (5 << 3) \| (0x200 >> 8) = 0x2A | high (op2) | op2 | S3 |
| 4 | 0xAA | 0x200 & 0xFF = 0x00 | low (op2) | op2 | S3 |
| 5 | 0xAC | (6 << 3) \| (0x300 >> 8) = 0x33 | high (op3) | op3 | S2 |
| 6 | 0xA8 | 0x300 & 0xFF = 0x00 | low (op3) | op3 | S2 |
| 7 | 0xA6 | (7 << 3) \| (0x400 >> 8) = 0x3C | high (op4) | op4 | S4 |
| 8 | 0xA2 | 0x400 & 0xFF = 0x00 | low (op4) | op4 | S4 |

各 step は 1 件の `RawRegisterWrite(port=0, address=<register>, data=<byte>)` event として emit。 これら 8 件の前に §決定 2 step 0 の `RawRegisterMaskWrite(0x27, mask=0x40, value=0x40)` が来て、 enable lowering 出力は合計 9 raw events。

### A-3. ADR-0038 §決定 5 defer 解消 / ADR-0039 §決定 6 接続条件 対応表

| ADR-0038 §決定 5 / ADR-0039 §決定 6 規約 | 本 ADR-0040 §決定 | 状態 |
|---|---|---|
| FM3Mode → raw lowering は v0.5 以降別 ADR で defer (= ADR-0038 §決定 5) | §決定 2/3 で literal 化 | defer 解消 |
| FM3Mode (enabled=true) → RMW(0x27, 0x40, 0x40) + 0xA8-0xAD literal (= ADR-0039 §決定 6) | §決定 2 + §決定 5 mapping table | 接続条件展開 |
| FM3Mode (enabled=false) → RMW(0x27, 0x40, 0x00) (= ADR-0039 §決定 6) | §決定 3 | 接続条件展開 |
| operator-split FNUM/Block → RawRegisterWrite literal、 mask 不要 (= ADR-0039 §決定 6) | §決定 5 mapping table + §決定 6 順序 invariant | 接続条件展開 |
| RMW event 新設判断含む (= ADR-0038 §決定 5) | v0.5 で既に RawRegisterMaskWrite 追加済 (= ADR-0039 §決定 1)、 本 ADR では schema 不変 (= §決定 1) | 解消 |

### A-4. raw event 2 種の役割整理 (= ADR-0039 §A-2 継承)

| event | data form | mask 外 bit | 本 ADR-0040 lowering での用途 |
|---|---|---|---|
| `RawRegisterWrite` | literal (= 全 8 bit) | (= 全 bit 上書き) | operator-split FNUM/Block × 8 件 (= 0xA8-0xAE、 0xA2/0xA6) |
| `RawRegisterMaskWrite` | masked (= mask + value) | preservation (= driver shadow) | 0x27 bit 6 set / clear × 1 件 |

ADR-0039 §A-2 で示した「将来 mask field を持つ generic event 1 種に統合」 議論は本 ADR でも対象外 (= 並列定義の単純さ優先)。

### A-5. 26-29 session 連続性

| session | ADR | chain | spike |
|---|---|---|---|
| 26th | ADR-0035 raw lowering | α/β/γ/δ | ir-lower-raw-register-spike.py 新規 |
| 27th | ADR-0037 FMTimerSet | α/β/γ/δ | ir-lower-tempo-spike.py 新規 |
| 28th | ADR-0038 FM3Mode chip event | α/β/γ/δ | ir-lower-fm3mode-spike.py 新規 |
| 29th | ADR-0039 RawRegisterMaskWrite | α/β/γ/δ | ir-lower-rmw-spike.py 新規 |
| 30th (= 本 ADR) | ADR-0040 FM3Mode raw lowering | α/γ/δ (= β skip = schema 不変) | ir-lower-fm3-raw-spike.py 新規 |

各 session で「ADR 起票 → (schema) → 新規 spike → fixture」 chain pattern を踏襲。 Codex 自律壁打ち運用 (= session `019e3425-3327-74e1-95bc-461cc5d0af66`、 gpt-5.5、 memory `feedback_codex_review_autonomous_no_user_judgment`) 継承。

### A-6. spike I/O 概略 example (= 30 γ 実装軸の事前提示)

**enable 入力 (= 1 event)**:

```json
{
  "tick": 0, "order": 0, "layer": "chip", "type": "FM3Mode",
  "trackId": 0, "enabled": true,
  "operatorEnableMask": 15,
  "operatorBlock": [4, 5, 6, 7],
  "operatorFnum": [256, 512, 768, 1024]
}
```

**enable 出力 (= 9 events)**: §A-2 table の通り 1 件 RMW + 8 件 RawRegisterWrite。

**disable 入力 (= 1 event)**:

```json
{
  "tick": 0, "order": 0, "layer": "chip", "type": "FM3Mode",
  "trackId": 0, "enabled": false,
  "operatorEnableMask": 1,
  "operatorBlock": [0, 0, 0, 0],
  "operatorFnum": [0, 0, 0, 0]
}
```

**disable 出力 (= 1 event)**:

```json
{
  "tick": 0, "order": 0, "layer": "raw", "type": "RawRegisterMaskWrite",
  "trackId": 0, "port": 0, "address": 39, "mask": 64, "value": 0
}
```

(= operatorBlock/operatorFnum は schema required の placeholder、 enabled=false 時は emit しない、 ADR-0038 §決定 3 整合)
