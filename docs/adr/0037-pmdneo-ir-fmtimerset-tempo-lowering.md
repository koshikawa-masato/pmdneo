# ADR-0037: FMTimerSet ChipEvent — Tempo lowering 設計 fix (= ADR-0035 §決定 14 defer 解消 / v0.3 schema 候補 / TIMER-B 採用 / driver runtime 不変 / 27th session 起点)

- 状態: **Draft** (= 2026-05-18 27th session 起票、 設計先行 ADR、 schema v0.3 追加 + spike 実装 + fixture は本 ADR scope-out で別 sprint commit chain、 Accepted 移行は実装 sprint 完走後 + user 最終確認時、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture 完全不変 doc-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0034 (= IR design consolidation 6 軸、 SemanticEvent Tempo 確定)
  - ADR-0035 (= ChipEvent → RawRegisterWrite lowering、 §決定 14 で「Tempo は semantic pass-through 維持、 chip 化は v0.3 FMTimerSet 等で別軸 defer」 と literal、 本 ADR が defer 解消)
  - ADR-0036 (= FM/SSG 並走方針、 driver runtime 駆動軸の責務境界整理)
- 関連設計書:
  - `docs/design/intermediate_register_command.md` §6-6 (= Tempo SemanticEvent 定義)、 §7 (= ChipEvent 詳細)
  - `docs/design/pmdneo_self_contained_driver.md` §5.4 (= TIMER-B 駆動仕様 literal、 PMDNEO driver の拍駆動源)、 §section table (= `timer_tempo` インライン 0x26 + 0x27 書込み、 multi-freq + TIMER-B run)
  - `docs/design/intermediate-register-command/ir-schema-v0.2.schema.json` (= v0.2 schema、 v0.3 拡張ベース)

## 背景

ADR-0034 §決定 3 で IR の 3 層 hybrid lowering 段階 (= SemanticEvent → ChipEvent → RawRegisterWrite) を確定し、 ADR-0035 で 2 段目 (= Chip → Raw) を spike 化した。 ADR-0035 §決定 14 (= e0923c4 で追加された決定) で `Tempo` (semantic) は raw 化せず semantic pass-through 維持、 chip 化は「v0.3 `FMTimerSet` 等で別軸 defer」 と literal 化。

本 ADR は ADR-0035 の defer 解消として、 `FMTimerSet` ChipEvent (= v0.3 schema 候補) の設計を文書 fix する。 schema 実装 / spike 実装 / fixture は本 ADR scope-out で、 別 sprint で commit chain。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 + ADR-0035 で確立した「ADR 起票 → schema → spike → fixture」 chain pattern を 27th session で踏襲。

## 決定

### 決定 1: FMTimerSet は ChipEvent (= layer="chip") として v0.3 schema 追加候補

`FMTimerSet` は ADR-0034 §決定 3 の 3 層 hybrid のうち ChipEvent (= OPNB 操作近傍) として扱う。

理由:
- BPM → Timer counter 値変換は「PMD MML semantic」 ではなく「OPNB chip layer 」 の数値表現
- semantic 層 Tempo (= bpm field) を残しつつ、 chip 層 FMTimerSet (= counter 値 + 0x27 bit 6 非破壊規律) に lowering する pattern が ADR-0035 で確立した Semantic → Chip lowering と整合
- raw 層 (= RawRegisterWrite) で表現も可能だが、 chip 層に挟むことで「optimization 余地 (= 同 BPM 連続時の重複削減 / barrier 解決)」 を future ADR で扱えるようになる

### 決定 2: Timer 選択 = TIMER-B 採用 (= PMDNEO driver 流儀整合)

YM2610 は TIMER-A (= 10-bit counter、 0x24/0x25) と TIMER-B (= 8-bit counter、 0x26) を持つ。 IR FMTimerSet が標準で扱うのは **TIMER-B のみ**。

理由:
- `docs/design/pmdneo_self_contained_driver.md` §5.4: 「TIMER-B は PMDNEO driver の拍駆動源」 literal
- PMD V4.8s 系流儀でも TIMER-B が tempo source
- TIMER-A は SCOPE-OUT (= 細かい sub-tick / sample timing 用途、 future ADR で別途扱う)
- 8-bit counter で BPM range を表現するのに十分

### 決定 3: BPM → TIMER-B counter 値変換式 = 方針 fix のみ、 数値 literal は defer

YM2610 (clock 8 MHz / prescaler 144) の TIMER-B は概念上:

- TIMER-B 1 IRQ 周期 = 18 × (256 - counter) μs (= datasheet 整合の単純式)

ただし PMDNEO driver の tempo 制御は **driver runtime の sub-tick accumulator** が担う (= `pmdneo_self_contained_driver.md` §5.4 末尾 literal:「PMDNEO の tempo は当面 sub-tick accumulator で制御する。 TIMER-B counter を MML tempo で頻繁に直書きしない」)。 すなわち TIMER-B IRQ は固定周期 source、 MML tempo は accumulator で実装。

このため、 本 ADR §決定 3 で確定するのは次の方針のみ:

1. TIMER-B 採用 (= 決定 2 引用)
2. driver IRQ 固定周期は driver runtime 軸 (= ADR-0036 関連別 ADR) で fix
3. IR `FMTimerSet` は driver start 時の初期 counter 設定を意味し、 runtime tempo 変更は sub-tick accumulator に委譲
4. 「runtime tempo 変更も FMTimerSet で chip 化対象に含めるか」 は **defer** (= 別 ADR で判断)

**数値 literal は本 ADR scope-out** (= ADR 段階で具体的 counter 値を fix すると driver runtime 軸と乖離する risk。 schema v0.3 / spike 実装段階で driver runtime 軸と同期し literal 化、 本 ADR は方針のみ)。

**判断**: 起票時 draft で記載した「BPM 120 → counter 約 200」 数値例は撤回 (= 概念式と矛盾していた + sub-tick accumulator 流儀と整合しない)。 数値例は本 ADR では出さず、 schema 実装 / spike 実装 commit で driver runtime 軸との同期確認上で literal 化する。

### 決定 4: 0x27 register bit 分解 — ADR 固定値と defer 値を明示

YM2610 (= YM2608 系) 0x27 register bit map (= datasheet ground truth):

| bit | 機能 | 本 ADR での扱い |
|---:|---|---|
| 7 | CSM mode (= TIMER-A IRQ で CSM mode KeyOn) | **defer** (= TIMER-A 軸別 ADR) |
| 6 | 3-slot mode (= FM3 extension mode、 PMDNEO driver §5.4 では「multi-frequency mode」 と呼称、 ADR-0034 §決定 4 と等価軸) | **ADR 固定**: 本 ADR は触らない (= FM3 mode は ADR-0034 §決定 4 + 別 ChipEvent `FM3Mode` で扱う、 FMTimerSet は bit 6 の現在値を破壊しない RMW or 既定値依存) |
| 5 | TIMER-B reset (= write 1 で flag clear、 IRQ ACK 用) | **defer** (= driver runtime 軸の IRQ handler 設計依存) |
| 4 | TIMER-A reset | **defer** (= TIMER-A 軸別 ADR) |
| 3 | TIMER-B IRQ enable | **defer** (= driver start シーケンス + IRQ handler 軸) |
| 2 | TIMER-A IRQ enable | **defer** (= TIMER-A 軸別 ADR) |
| 1 | TIMER-B start | **defer** (= driver start タイミング + tempo 変更 semantics 依存) |
| 0 | TIMER-A start | **defer** (= TIMER-A 軸別 ADR) |

**本 ADR で fix するのは bit 6 のみ** (= 「FMTimerSet lowering は bit 6 を破壊しない」)。 bit 0-5 / 7 は driver runtime 軸 (= ADR-0036 関連別 ADR) で確定。

PMDNEO driver §5.4 の `0x27 |= 0x40` literal は「bit 6 set = FM3 mode 維持」 を意味し、 TIMER-B start (= bit 1) は別 write or 別 sequence で発生する流儀 (= 詳細は driver runtime 軸 ADR で literal 化)。

FMTimerSet ChipEvent は 0x26 (= TIMER-B counter) への write を中心とし、 0x27 への write semantics は driver runtime 軸の責務 (= 上記 defer 列)。 spike 実装段階で「FMTimerSet → raw register write 列」 の literal 化は driver runtime 軸 fix 後に同期。

### 決定 5: driver runtime 軸との責務境界

| 軸 | 責務 |
|---|---|
| IR layer (= 本 ADR) | semantic Tempo → chip FMTimerSet の数値変換、 0x26 counter 値、 0x27 bit 6 非破壊規律、 event 並び固定 |
| driver runtime layer (= ADR-0036 関連別 ADR) | tick source 決定 / IRQ handler / sub-tick accumulator / 高頻度 TIMER-B counter 直書き禁止 / re-arm |
| WebApp layer | IR layer 出力を入力に visualization、 driver layer は触らない |

本 ADR は IR layer のみ。 driver runtime は ADR-0036 関連で別軸。

### 決定 6: schema v0.3 追加 event 列 (= 本 ADR scope-out)

本 ADR では schema 拡張案を literal 化のみで、 実装は別 commit:

- `FMTimerSet` (= layer="chip", type="FMTimerSet") 新規追加
  - 必須 field: `trackId` (= Tempo source track と event ordering の traceability 用、 v0.3 FMTimerSet では必須) + `counter` (= TIMER-B 8-bit value 0-255)
  - `mode` (= 0x27 register bits) は driver runtime 軸で 0x27 semantics fix 後に採否判断 (= 本 ADR scope-out)
  - optional field: `bpm` (= source BPM、 traceability 用)
  - source `Tempo` event との 1 対 1 対応

(= schema 追加 JSON Schema 形は別 sprint commit β で literal 化)

### 決定 7: lowering spike 設計 (= 本 ADR scope-out)

ADR-0035 spike (= chip → raw) を拡張する形で、 semantic Tempo → chip FMTimerSet → raw register write の chain を新規 spike `ir-lower-tempo-spike.py` (or 既存 chip spike 拡張) で実装する。 詳細は別 sprint commit γ。

### 決定 8: schema v0.3 必要性

**必要**。 ADR-0035 §決定 10 で「v0.3 schema 不要」 と判断したのは raw lowering 範囲内であり、 本 ADR の `FMTimerSet` は新規 chip event のため schema 拡張必須。

v0.3 schema は v0.2 を backward-compatible 拡張 (= 既存 event 種は touch しない、 `FMTimerSet` 追加 + `Event` discriminated union に oneOf 追加)。

## scope-out (= 本 ADR 不可触 + 別 sprint defer)

- schema v0.3 実装 (= 別 sprint commit β)
- spike 実装 (= 別 sprint commit γ)
- positive / negative fixture (= 別 sprint commit δ)
- driver / runtime / `.mn` / `.PNE` / `.NEO` 生成 / WebApp 実装
- TIMER-A 軸 (= 別 ADR、 future)
- IRQ handler 詳細 / sub-tick accumulator (= ADR-0036 関連 driver runtime 軸)
- BPM 変換式の厳密 literal 化 (= driver runtime 軸と同期 fix、 本 ADR は方針 fix のみ)
- automated CI / aesthetic / audio audition
- vendor 不可触

## 後続 sprint 想定 (= 別 ADR + 別 chain)

| commit | 内容 |
|---|---|
| β | schema v0.3 追加 (= `ir-schema-v0.3.schema.json`、 FMTimerSet event + Event oneOf 拡張) |
| γ | spike 実装 (= semantic Tempo → chip FMTimerSet → raw register write) |
| δ | positive fixture (= 既存 chip lowered IR を入力に Tempo 変換確認) + negative fixture (= unsupported BPM / counter overflow 等) + 全 regression |

本 ADR Accepted 移行は β/γ/δ commit chain 完走 + user 最終確認時。

## verify 計画 (= 本 ADR doc-only、 実装 verify は別 sprint)

- ADR-0034 / ADR-0035 と矛盾しない (= 3 層 hybrid + Tempo defer pattern 整合)
- pmdneo_self_contained_driver.md §5.4 TIMER-B 仕様と整合
- v0.2 schema fixture / spike output 完全不変 (= 本 ADR は doc 追加のみ)
- 既存 PR #3 / #4 / #5 を壊さない

## Annex

### A-1. 27th session 起点 / 後続 chain 計画

| sprint | 内容 | branch |
|---|---|---|
| 27 α (= 本 commit) | ADR-0037 起票 | `wip-ir-v0.3-fmtimerset-tempo-lowering` |
| 27 β | schema v0.3 追加 | (同上 or 別 branch) |
| 27 γ | spike 実装 | (同上 or 別 branch) |
| 27 δ | fixture + 全 regression | (同上 or 別 branch) |

stacked PR depth: PR #3 → #4 → #5 → #6 (= 本 ADR 起票 PR) → #7 (= 後続 chain PR)。 PR #6 は doc-only 1 commit PR で、 後続実装は別 PR で stacked。

### A-2. ADR-0036 並走整合

ADR-0036 は FM/SSG 軸並走方針を確定し、 driver runtime 軸 (= tick source 決定 / IRQ) を user × Codex 壁打ち主導で進める。 本 ADR (= IR layer 単独) は driver runtime 軸と分離独立、 並走可能。 IR FMTimerSet → driver runtime の bridge は ADR-0036 関連別 ADR で扱う。

### A-3. 26th session chain との連続性

26th session で ADR-0035 chain (= α/β/γ/δ + handoff doc 同梱 + Codex 11 round review) を完走、 PR #5 merge-ready 化。 27th session 起点として本 ADR を起票することで、 Codex 自律壁打ち運用 (= memory `feedback_codex_review_autonomous_no_user_judgment`) の context (= session `019e3425-...`、 gpt-5.5) を継承可能。
