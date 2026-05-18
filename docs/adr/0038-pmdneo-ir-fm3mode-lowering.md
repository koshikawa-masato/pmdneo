# ADR-0038: FM3Mode ChipEvent — v0.4 schema + lowering 設計 fix (= ADR-0034 §決定 4 ratify 済 FM3 extension mode を chip layer literal 化 / 0x27 bit 6 + 0xA8-0xAE register write 仕様 / driver runtime 不変 / 28th session 起点)

- 状態: **Draft** (= 2026-05-18 28th session 起票、 設計先行 ADR、 schema v0.4 追加 + spike 実装 + fixture は本 ADR scope-out で別 sprint commit chain、 Accepted 移行は実装 sprint 完走後 + user 最終確認時、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture 完全不変 doc-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0034 (= IR design 6 軸、 §決定 4 で FM3Mode ChipEvent + FMTone 共用 ratify、 本 ADR が v0.4 schema literal 化で defer 解消)
  - ADR-0035 (= ChipEvent → RawRegisterWrite lowering、 §後続 sprint 列で「FM3Mode」 を別 ADR と明示、 本 ADR でその軸を起票)
  - ADR-0037 (= FMTimerSet、 §決定 4 で 0x27 bit 6 = 3-slot mode = FM3 extension mode 非破壊規律 = 「FMTimerSet は bit 6 を破壊しない」 を確定、 本 ADR が「FM3Mode は bit 6 を能動的に set / clear する」 という対称軸を確立)
- 関連設計書:
  - `docs/design/intermediate_register_command.md` §7-4 (= FM3Mode ChipEvent 仕様 literal: enabled / operatorEnableMask / operatorBlock[4] / operatorFnum[4] / keyPolicy / FM ch 3 only / mode 切替直前 KeyOff 挿入推奨 / 0x27 + 0xA8-0xAE 系 register write 展開)
  - `docs/design/reference_intermediate_register_command.md` §3.1 (= FM3 extension mode 詳細、 OPN/OPNA/OPNB の operator split 仕様、 0x27 bit 6-7 + 0xA8-0xAE 独立 F-Number/Block)
  - `docs/design/intermediate-register-command/ir-schema-v0.3.schema.json` (= v0.3 schema、 v0.4 backward-compat 拡張ベース)

## 背景

ADR-0034 §決定 4 で FM3Mode ChipEvent は既に ratify 済 (= 24th session 軸 4 ratify、 「FM3 拡張音色をどこで表現するか」 = ChipEvent + FMTone 共用)。 ただし schema literal 化は v0.2 / v0.3 で scope-out (= ADR-0035 §後続 sprint 列に明示)。 v0.4 で FM3Mode event を schema 追加 + lowering spike 実装する軸を 28th session で着手。

ADR-0035 §後続 sprint 列に「FM3Mode」 を別 ADR と明示しているのは、 FM3Mode の register lowering が「通常 ch 3 と operator split の 4 operator 独立 frequency」 という非自明な分岐を含むため。 v0.2 raw lowering (= 通常 FM ch) の chain では扱わず、 v0.4 で別 ChipEvent として明示処理する。

ADR-0037 で「0x27 bit 6 = 3-slot mode = FM3 extension mode 非破壊規律」 を確定済。 FM3Mode はその bit 6 を能動的に set (= enable) / clear (= disable) する責務を持つ、 ADR-0037 の対称軸。

CLAUDE.md §設計書ファースト + 26 / 27 session で確立した「ADR 起票 → schema → spike → fixture」 chain pattern を 28th session で踏襲。

## 決定

### 決定 1: FM3Mode は ChipEvent (= layer="chip") として v0.4 schema 追加

ADR-0034 §決定 4 ratify を v0.4 schema layer に literal 化する。

- layer: "chip"
- type: "FM3Mode"
- 対象 channel: FM ch 3 固定 (= 後述 §決定 2)

理由:
- ADR-0034 §決定 4 既 ratify
- chip layer に置くことで「optimization 余地 (= 同一 mode 連続時の重複削減、 mode 切替直前 KeyOff 自動挿入等)」 を future ADR で扱える
- raw layer (= RawRegisterWrite) だけにすると音楽的意味 (= 「FM3 extension mode が enabled」) が失われる

### 決定 2: 対象 channel は FM ch 3 固定 (= channel field 不要)

FM3Mode は **FM ch 3 にだけ作用** する (= `intermediate_register_command.md` §7-4 規律)。 schema 上 channel field は不要 (= FM3Mode が常に ch 3 を意味する)。

理由:
- YM2608/YM2610 仕様で 3-slot mode (= 0x27 bit 6) は FM ch 3 専用機能
- 他 FM ch (= 1/2/4/5/6) で FM3 mode は意味なし
- channel field を持たせると invalid value (= ch 1/2/4/5/6) を受け入れる schema になり、 validation noise が増える

### 決定 3: 必須 field 構成

```
- enabled: bool (= FM3 extension on/off)
- operatorEnableMask: int 0-15 (= bit 0-3 = op1-4 keyon mask)
- operatorBlock: array of 4 int 0-7 (= op 1-4 個別 block、 enabled=true 時のみ意味、 enabled=false 時も schema 上 required)
- operatorFnum: array of 4 int 0-2047 (= op 1-4 個別 fnum、 同上)
- trackId: int (= ADR-0037 §決定 6 + 27 β user 意図継承で v0.4 chip event も traceability 必須化、 schema layer enforce)
```

optional field:
```
- keyPolicy: enum ("all" / "operator_masked") (= 省略時 "all" = 全 op keyon、 operator_masked = operatorEnableMask に従う)
```

`enabled=false` 時も `operatorBlock` / `operatorFnum` を required にする理由:
- schema 単純化 (= conditional required は schema 複雑化)
- enabled=false 時は値が使われない (= driver runtime 軸で無視) ため任意値 0 等 placeholder で OK
- 1 件の FM3Mode event で「enable + 4 op 周波数設定」 を atomic に伝える契約に

### 決定 4: 関連 register table — 参照のみ、 literal lowering は別 ADR で defer

FM3Mode lowering 時に書くべき YM2610 register (= datasheet 参照、 概要):

| register | 用途 |
|---:|---|
| 0x27 | TIMER mode + flag clear + **3-slot mode (= bit 6)** + CSM (= bit 7) |
| 0xA8-0xAD | FM ch 3 operator-split FNUM low/high (= datasheet「ch 3 op 2 / op 3 / op 4」 対応、 op 1 は通常 0xA0/0xA4 共用、 詳細 mapping は driver code + ymfm reference と同期段階で literal 化) |
| 0x28 | KeyOn (= operatorEnableMask 部分、 ADR-0035 §決定 6 と協調) |

**raw lowering 全体は本 ADR では scope-out** (= 後述 §決定 5 で defer 明示)。 本 ADR では table 参照と「FM3Mode lowering に必要な register 群」 概要のみ literal 化。 具体的な bit pattern / write 順 / RMW semantics は別 ADR で fix。

### 決定 5: FM3Mode → raw lowering は v0.5 以降別 ADR で defer

ADR 起票時 draft では「FM3Mode → RawRegisterWrite chain を 28 γ spike で実装」 と書いたが、 28 α Codex review で次の論点を fix:

- 0x27 bit 6 は **RMW (= Read-Modify-Write)** が必要 (= 他 bit を破壊しないため)
- 既存 `RawRegisterWrite` event (= ADR-0034 / v0.2 schema 定義) は `port + address + data` の literal で、 mask / RMW semantics を直接表現できない
- 解決案 3 件: (A) RMW 用 event を新設 / (B) FM3Mode を raw 化せず chip layer 維持 / (C) 0x27 全 bit を IR 側で固定値 literal write

**判断**: **(B) raw 化を defer** を採用。

理由:
- ADR-0037 (= FMTimerSet) と同 pattern (= chip event 定義 + counter literal 化を driver runtime 軸 fix 後 defer)
- v0.4 では FM3Mode chip event の **schema + chip layer validation + chip-to-chip identity pass-through spike** までを scope に絞り、 raw lowering は v0.5 以降別 ADR で扱う
- RMW event 新設 (= 案 A) は schema 大改修で 28th session scope を超える、 別 ADR (= 例 ADR-0039 「IR RMW / mask event 設計」) で扱う

「FM3Mode は bit 6 を能動的に set / clear する」 という ADR-0037 対称軸の **方針** は本 ADR で確定。 ただし raw lowering の literal 実装は v0.5 以降。

### 決定 5-2: 28 γ spike scope = chip event validation + pass-through

raw lowering を defer したため、 28 γ spike は次の最小 scope:

- 新規 spike `scripts/ir-lower-fm3mode-spike.py` (= or 既存 spike 拡張)
- 入力: v0.4 IR (= FM3Mode event を含む)
- 出力: v0.4 IR (= FM3Mode を pass-through、 他 event も pass-through、 chip-to-chip identity)
- validation: schema 表現外の制約 (= FM3Mode の operatorBlock/operatorFnum range の defense in depth、 keyPolicy enum check、 mode 切替直前 KeyOff 推奨警告 diagnostics 等)
- ADR-0035 raw spike pattern 踏襲 (= sort + 重複 reject + timeMode delta reject + allocator)

「lowering spike」 ではなく「chip event validation spike」 という性質に縮小。 raw lowering proof は v0.5 別 ADR で。

### 決定 6: schema v0.4 必要性

**必要**。 v0.3 schema (= 11 件 event) に FM3Mode 1 件追加 = 12 件。

- v0.3 backward-compatible 拡張 = 既存 v0.3 IR document は v0.4 schema でも validate PASS
- v0.2 / v0.1 backward-compat も継承 (= v0.3 → v0.4 で v0.2 も間接的に PASS、 v0.2 → v0.3 backward-compat は 27 β で literal 確認済)

### 決定 7: lowering spike 設計 (= 本 ADR scope-out、 別 commit γ、 §決定 5-2 で縮小済)

§決定 5 で raw lowering を defer したため、 28 γ spike は §決定 5-2 の **chip event validation + pass-through** scope。 詳細は §決定 5-2 参照。

### 決定 8: scope-out 列

- schema v0.4 実装 (= 別 sprint commit β)
- spike 実装 (= 別 sprint commit γ)
- positive / negative fixture (= 別 sprint commit δ)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp 実装
- **FM3Mode → RawRegisterWrite raw lowering chain の literal 実装** (= §決定 5 で v0.5 以降別 ADR に defer、 RMW / mask event 新設の判断含む)
- FM3 operator pitch 自動導出 (= 通常 note frequency 4 op 分割の計算は importer 軸、 chip event では入力済 fnum/block を信頼)
- importer 実装 (= MML → IR で FM3 mode を生成する側)
- optimization layer (= FM3Mode 連続時の重複削減、 KeyOff 自動挿入)
- 0x27 register の **bit 0-5/7** semantics (= ADR-0037 §決定 4 で defer 確定、 driver runtime 軸別 ADR)
- CSM mode (= 0x27 bit 7、 TIMER-A 軸別 ADR)
- aesthetic / audio audition / automated CI

## 後続 sprint 想定 (= 28 β/γ/δ chain)

| commit | 内容 |
|---|---|
| β | schema v0.4 追加 (= `ir-schema-v0.4.schema.json`、 FM3Mode event 追加 + Event oneOf 拡張) |
| γ | spike 実装 (= FM3Mode chip event validation + pass-through identity chain) |
| δ | positive fixture (= enable / disable 各 1 件) + spike-invalid (= missing operatorBlock / unexpected channel field / invalid range) + 全 regression |

本 ADR Accepted 移行は β/γ/δ commit chain 完走 + user 最終確認時。

## verify 計画 (= 本 ADR doc-only、 実装 verify は別 sprint)

- ADR-0034 §決定 4 + ADR-0035 §後続 sprint 列 + ADR-0037 §決定 4 と矛盾しない (= FM3Mode + 0x27 bit 6 + 対称軸維持)
- intermediate_register_command.md §7-4 仕様と整合
- v0.3 fixture / spike output 完全不変 (= 本 ADR doc 追加のみ)
- PR #3/#4/#5 merged chain + PR #6/#7 OPEN chain を壊さない

## Annex

### A-1. 28th session 起点 / 後続 chain 計画

| sprint | 内容 | branch |
|---|---|---|
| 28 α (= 本 commit) | ADR-0038 起票 | `wip-ir-v0.4-fm3mode-lowering` |
| 28 β | schema v0.4 追加 | (= 27 pattern と同様、 同 branch or 別 branch impl) |
| 28 γ | spike 実装 | (同上) |
| 28 δ | fixture + 全 regression | (同上) |

stacked PR chain: main ← #3/#4/#5 merged ← #6 ADR-0037 ← #7 v0.3 impl ← **#8 (= 本 ADR PR、 doc-only)** ← #9 候補 (= v0.4 impl、 27 pattern で別 branch / 別 PR)

### A-2. ADR-0037 (= FMTimerSet) との対称軸

| 軸 | ADR-0037 FMTimerSet | ADR-0038 FM3Mode |
|---|---|---|
| 主 register | 0x26 (= TIMER-B counter) | 0x27 bit 6 (= 3-slot mode) + 0xA8-0xAD |
| 0x27 bit 6 規律 | **非破壊** | **能動的 set / clear** |
| chip 化対象 | initial Tempo のみ (= runtime tempo は defer) | 全 enable/disable + operator pitch (= optimization は別軸 defer) |
| 数値 literal defer | counter (= driver runtime 軸同期) | operator-register mapping (= datasheet + ymfm 整合段階で fix) |
| schema | v0.3 で追加 | v0.4 で追加 |

両 ADR は 0x27 register を共有しつつ責務分担: FMTimerSet = bit 6 保護、 FM3Mode = bit 6 制御。

### A-3. 26/27 session chain との連続性

26th session = ADR-0035 chain (= raw lowering、 Codex 11 round)、 27th session = ADR-0037 chain (= FMTimerSet、 Codex 約 10 round)、 28th session = ADR-0038 chain (= FM3Mode、 同 pattern 予定)。 Codex 自律壁打ち運用 (= session `019e3425-...`、 gpt-5.5、 memory `feedback_codex_review_autonomous_no_user_judgment`) 継承。
