# ADR-0039: RawRegisterMaskWrite event 設計 fix (= v0.5 schema 候補 / partial bit update semantics / 0x27 bit 6 preservation / FM3Mode raw lowering 接続条件 / driver runtime 不変 / 29th session 起点)

- 状態: **Draft** (= 2026-05-18 29th session 起票、 設計先行 ADR、 schema v0.5 追加 + spike 実装 + fixture は本 ADR scope-out で別 sprint commit chain、 Accepted 移行は実装 sprint 完走後 + user 最終確認時、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture 完全不変 doc-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0034 (= IR design 6 軸、 §決定 3 で 3 層 hybrid SemanticEvent → ChipEvent → RawRegisterWrite ratify、 `RawRegisterWrite` 既存)
  - ADR-0035 (= ChipEvent → RawRegisterWrite lowering、 §決定 4 で port/address/data literal 仕様、 RMW なし)
  - ADR-0037 (= FMTimerSet、 §決定 4 で 0x27 bit 6 = 3-slot mode 非破壊規律 = 「FMTimerSet は bit 6 を破壊しない」)
  - ADR-0038 (= FM3Mode、 §決定 5 で「raw lowering 全体は v0.5 以降別 ADR (= RMW/mask event 新設判断含む) に defer」 と literal、 本 ADR が defer 解消の前提軸を作る)
- 関連設計書:
  - `docs/design/intermediate_register_command.md` §8 (= RawRegisterWrite escape hatch、 port/address/data/barrier)
  - `docs/design/intermediate-register-command/ir-schema-v0.4.schema.json` (= v0.4 schema、 v0.5 拡張ベース)

## 背景

ADR-0034 §決定 3 で 3 層 hybrid (= Semantic → Chip → Raw) を ratify し、 raw 層 event として `RawRegisterWrite` (= port + address + data) を確立 (= ADR-0035 §決定 4 で literal lowering 実装)。 この event は OPNB register に **literal data** を書き込む形式。

ところが ADR-0037 (= FMTimerSet) + ADR-0038 (= FM3Mode) で、 **partial bit update** 制約が出現した:

**役割整理**:

- **ADR-0037 (= FMTimerSet)**: **bit 6 preservation 制約の根拠 ADR** (= 0x26 TIMER-B counter literal write が中心、 0x27 を触らない = bit 6 非破壊規律を確立、 本 ADR の RMW event の **直接 consumer ではない**)
- **ADR-0038 (= FM3Mode)**: **直近の RMW consumer** (= 0x27 bit 6 を能動的に set/clear する唯一の ChipEvent、 raw lowering 時に partial bit update が必須、 本 ADR の RMW event が直接 lowering 先になる)

既存 `RawRegisterWrite (port, address, data)` では「現在の register 値を保持しつつ一部 bit のみ変更」 を表現できない (= literal data を覆い書きする形式)。 結果として ADR-0038 §決定 5 で FM3Mode の raw lowering を「v0.5 以降別 ADR (= RMW/mask event 新設判断含む) で扱う」 と defer 確定。

本 ADR は ADR-0038 defer 解消の前提として、 **`RawRegisterMaskWrite` event を v0.5 schema に追加する設計** を fix する。 これは FM3Mode raw lowering (= ADR-0040 候補) 着手前の必須先行軸。

CLAUDE.md §設計書ファースト + 26-28 session 確立の「ADR 起票 → schema → spike → fixture」 chain pattern を 29th session で踏襲。

## 決定

### 決定 1: `RawRegisterMaskWrite` = raw layer event として v0.5 schema 追加

新規 event:

- layer: "raw" (= 既存 `RawRegisterWrite` と同 layer)
- type: "RawRegisterMaskWrite"
- 用途: partial bit update (= mask で指定した bit のみ value で書き、 mask 外 bit は driver runtime 軸で保持)

`RawRegisterWrite` (= literal write) と `RawRegisterMaskWrite` (= masked write) の **2 種類** を raw layer に並べる。

### 決定 2: `RawRegisterWrite` との責務境界

| event | semantics | 用途例 |
|---|---|---|
| `RawRegisterWrite` | 指定 address に data を **literal write** (= 全 8 bit 上書き) | 0x26 TIMER-B counter、 0xA0/0xA4 FM frequency、 operator parameter (0x30-0x90 系) など、 register 全 bit を IR layer で決定する場合 |
| `RawRegisterMaskWrite` | 指定 address の mask bit のみ value で書き、 mask 外 bit は driver runtime 軸で **preservation** | 0x27 bit 6 (= FM3 mode 制御)、 partial bit register 全般 (= 0x28 KeyOn は ADR-0035 §決定 6 で `(operatorMask << 4) | ch_code` literal write として既定義、 本 ADR では対象外) |

**判断**: `RawRegisterWrite` と `RawRegisterMaskWrite` は明確に **別 event** として並列定義 (= union 化や conditional schema は避ける、 schema 単純性優先)。 lowering spike では 2 種類を区別して emit。

### 決定 3: 必須 field 構成

```
- port: int 0-1
- address: int 0-255
- mask: int 1-255 (= 「どの bit を更新するか」、 minimum 1 で no-op 防止)
- value: int 0-255 (= 「mask bit に書く値」、 mask 外 bit の value は無視される)
- trackId: int (= 27/28 session 規律継承 = chip/raw event で traceability 必須化)
```

optional field:
```
- barrier: bool (= 既存 RawRegisterWrite と同、 RMW でも前後 reorder を禁止したい場合 true)
```

### 決定 4: mask / value semantics 規律

- `mask`: 更新対象 bit が 1、 保持対象 bit が 0 (= 例 mask=0x40 → bit 6 のみ更新)
- `value`: mask が 1 の bit に書く値、 mask が 0 の bit の value は **don't care** (= validator は value & ~mask != 0 を warning にしない、 spike は値そのまま emit)
- **driver runtime 軸 semantics**: 「**driver-maintained shadow register** (= driver code 側で保持する各 register の現在 logical 値、 YM2610 register は実機 read 不可のため driver 側 shadow を ground truth とする) に対して mask 外 bit を保持しつつ mask bit を value で更新し、 結果を実 register に write」 = `new_data = (shadow_data & ~mask) | (value & mask)`
- IR layer はこの semantics を **expression のみ** 保持 (= driver runtime 軸が実際の RMW 実行責務)

**判断**: `value & ~mask != 0` を error にしない理由は、 IR generator 側が「value = 0x40, mask = 0x40」 のように mask bit と一致する形で記述するのが自然 (= 「bit 6 を 1 にする」 = value=0x40, mask=0x40)。 ただし「value = 0xC0, mask = 0x40」 のように余分 bit を含むケースも valid (= 余分 bit は don't care)。 schema 単純性優先で warning 出さない。

### 決定 5: 0x27 bit 6 preservation 規律 (= ADR-0037/0038 対称軸 解消)

ADR-0037 + ADR-0038 で確立した「0x27 bit 6 = FM3 mode、 FMTimerSet 非破壊 / FM3Mode 能動制御」 を `RawRegisterMaskWrite` で literal 表現:

| 用途 | RawRegisterMaskWrite parameter |
|---|---|
| FM3 mode enable | port=0, address=0x27, mask=0x40, value=0x40 |
| FM3 mode disable | port=0, address=0x27, mask=0x40, value=0x00 |
| FMTimerSet 0x27 関連書込 | (= 本 ADR scope-out、 ADR-0037 §決定 4 で FMTimerSet は 0x27 を触らず 0x26 のみ literal write が確定、 RMW 不要 = FMTimerSet は RMW consumer ではない) |

### 決定 6: FM3Mode raw lowering 接続条件 (= ADR-0040 候補 前提)

本 ADR で `RawRegisterMaskWrite` が成立すれば、 ADR-0038 §決定 5 で defer された FM3Mode → raw lowering は別 ADR (= 仮 ADR-0040「FM3Mode raw lowering 実装」) で次のように扱える:

- FM3Mode (enabled=true) → `RawRegisterMaskWrite(0x27, 0x40, 0x40)` + 0xA8-0xAD literal writes
- FM3Mode (enabled=false) → `RawRegisterMaskWrite(0x27, 0x40, 0x00)`
- operator-split FNUM/Block → `RawRegisterWrite` (= literal、 mask 不要)

**本 ADR は接続条件の literal 化のみ** = FM3Mode → raw lowering 実装は別 ADR (= 別 sprint)。

### 決定 7: schema v0.5 必要性 + backward-compat

**必要**。 v0.4 schema (= 12 件) に `RawRegisterMaskWrite` 1 件追加 = 13 件。

- v0.4 backward-compat = 既存 v0.4 IR document は v0.5 でも validate PASS
- v0.3 / v0.2 / v0.1 も間接的 backward-compat 継承

### 決定 8: lowering spike 設計 = **新規 spike** 採用 (= 本 ADR α で fix、 28 γ pattern 踏襲)

ADR-0038 §決定 5-2 の chip event validation spike pattern を踏襲。 既存 raw spike (= `ir-lower-raw-register-spike.py`、 ADR-0035 chain) と分離して **新規 spike `scripts/ir-lower-rmw-spike.py`** を採用 (= 29 α で fix、 二択 (= 新規 vs 既存拡張) のうち新規採用)。

理由:
- 既存 raw spike は chip → raw lowering で複雑 (= 639 行)、 RawRegisterMaskWrite 認知拡張で更に複雑化
- 新規 spike は raw-to-raw identity + validation の scope 限定で軽量 (= 27 γ tempo spike + 28 γ fm3 spike pattern と整合)
- 既存 ADR-0035 raw spike は本 ADR scope では touch なし (= 既存出力 byte-identical 維持で regression risk 最小)

新規 spike 仕様:
- 入力: v0.5 IR (= RawRegisterMaskWrite event を含む)
- 出力: v0.5 IR (= raw-to-raw identity pass-through、 既存 RawRegisterWrite/ChipEvent も全 pass-through)
- validation: `mask` int 1-255 / `value` int 0-255 / port int 0-1 / address int 0-255 / 必須 field check / 型厳密 (= type(x) is int)
- 共通規律 (= 26-28 session spike pattern 踏襲): sort + 重複 reject + timeMode delta reject + allocator order 再採番

既存 ADR-0035 raw spike chain (= chip → raw lowering) との関係: 既存 raw spike は v0.5 schema の RawRegisterMaskWrite event を **scope 外**として扱う (= ADR-0035 chain では発生しない event のため、 既存 spike 不変)。 chip → RawRegisterMaskWrite の生成は ADR-0040 候補で扱う。

詳細は別 sprint commit γ。

### 決定 9: scope-out 列

- schema v0.5 実装 (= 別 sprint commit β)
- spike 実装 (= 別 sprint commit γ)
- positive / negative fixture (= 別 sprint commit δ)
- FM3Mode raw lowering 実装 (= ADR-0040 候補別 ADR、 本 ADR は接続条件 literal のみ)
- driver runtime での実際の RMW 実行 (= driver code 側責務、 IR layer は expression 保持のみ)
- 既存 RawRegisterWrite の RMW 化 (= 既存 event は touch なし、 RawRegisterMaskWrite は新規並列 event)
- optimization layer (= 同 address 連続 RMW の merge 等)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp 実装
- aesthetic / audio audition / automated CI
- vendor 不可触

## 後続 sprint 想定 (= 29 β/γ/δ chain + 別 ADR-0040 候補)

| commit | 内容 |
|---|---|
| β | schema v0.5 追加 (= `ir-schema-v0.5.schema.json`、 RawRegisterMaskWrite event + Event oneOf 拡張) |
| γ | spike 実装 (= raw-to-raw identity + validation) |
| δ | positive fixture (= 0x27 set/clear 2 件) + spike-invalid (= mask=0 / port out / value/address range out 等) + 全 regression |
| 別 ADR-0040 | FM3Mode → raw lowering 実装 (= 本 ADR §決定 6 接続条件 literal を実装) |

本 ADR Accepted 移行は β/γ/δ commit chain 完走 + user 最終確認時。

## verify 計画 (= 本 ADR doc-only、 実装 verify は別 sprint)

- ADR-0034 §決定 3 + ADR-0035 + ADR-0037/0038 と矛盾なし
- intermediate_register_command.md §8 RawRegisterWrite escape hatch 設計と並列 (= 別 event として並列定義、 既存 event 不変)
- v0.4 fixture / spike output 完全不変
- PR #3/#4/#5 merged chain + PR #6-#9 OPEN chain を壊さない

## Annex

### A-1. 29th session 起点 / 後続 chain 計画

| sprint | 内容 | branch |
|---|---|---|
| 29 α (= 本 commit) | ADR-0039 起票 | `wip-ir-v0.5-rmw-mask-event` |
| 29 β | schema v0.5 追加 | (= 27/28 pattern と同様、 別 branch impl) |
| 29 γ | spike 実装 | (同上) |
| 29 δ | fixture + 全 regression | (同上) |
| 30 候補 | ADR-0040 FM3Mode raw lowering 実装 | (別 branch) |

stacked PR chain: main ← #3/#4/#5 merged ← #6 ← #7 ← #8 ← #9 ← **#10 (= 本 ADR PR、 doc-only)** ← #11 候補 (= v0.5 impl)

### A-2. raw event 2 種 並列定義の意義

| event | data form | mask 外 bit | 用途 |
|---|---|---|---|
| RawRegisterWrite | literal (= 全 8 bit) | (= 全 bit 上書き) | 単純 register write |
| RawRegisterMaskWrite | masked (= mask + value) | preservation | partial bit update register |

将来 (= ADR-0040 以降) で「mask field を持つ generic event 1 種に統合」 する議論は別 ADR で扱う (= 本 ADR では並列定義の単純さを優先)。

### A-3. 26-28 session 連続性

26 ADR-0035 raw lowering + 27 ADR-0037 FMTimerSet + 28 ADR-0038 FM3Mode (= 0x27 RMW defer) → 29 ADR-0039 RMW event (= defer 解消前提) → 30 候補 ADR-0040 FM3Mode raw lowering 実装 = IR 軸 chain の自然な連続性。 Codex 自律壁打ち運用 (= session `019e3425-...`、 gpt-5.5、 memory `feedback_codex_review_autonomous_no_user_judgment`) 継承。
