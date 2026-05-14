# ADR-0024 step 10 δ 完了統合 handoff: `sample_table_id` selection consumption sprint 完了 (= identity resolution → playback selection contract 成立、 ADR-0024 Accepted 移行)

- 日付: 2026-05-14 (= 11th session、 δ 着手 + 完了統合)
- 対応 ADR: [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 8 δ + 全 §決定 1-8 統合
- 関連 commit chain: α `a9bb169` + β `9f454f5` + γ `7abf533` + δ (= 本 commit)

## δ scope (= 1 commit + 1 push)

> **核心境界 (= future contributor 向け短文明記)**: Step 10 δ で **「identity resolution → playback selection」 contract が成立**。 step 9 完了時は「filename から sample_table_id への resolution」 まで、 step 10 完了時は「sample_table_id から playback selection への consumption」 まで延伸。 `.MN` 内 filename string が runtime の chip register write を制御する 1 本の鎖が initial に完成した。

- step 5/6/7/8/9 既存 verify script regression suite (= 12 script) を serial 実行 + 全 PASS 確認
- step 5 α-3 verify script の pre-existing 古い symbol 参照 (= `pmdneo_mn_direct_load_l_part_addr`) を current 名 (= `pmdneo_mn_direct_load_lq_part_addr`) に rename 修正
- silent-bcef audible regression なし (= verify-silent-bcef-audio-isolation.sh PASS、 user 試聴用 wav 保存)
- ADR-0024 Annex 追記 (= 完了判定 12 項目 + commit chain + regression result + Accepted 移行根拠)
- ADR-0024 status: Draft → **Accepted**
- memory `project_pmdneo_step10_complete.md` 起票
- memory `MEMORY.md` index 更新 (= step 10 完了行追加)
- driver source は **完全不変** (= δ scope 厳守、 verify infra + doc + memory のみ更新)

## 「identity resolution → playback selection」 contract 成立

### Step 5 から Step 10 までの責務鎖

| step | 役割 | runtime state | playback effect |
|---|---|---|---|
| step 5 | runtime semantics (= どう鳴らすか) | `adpcma_ch_sample_ptr_table` (= build-time) | ADPCM-A 6ch L-Q part 駆動 |
| step 6 | verification / listening (= どう確認するか) | (= 無) | silent-bcef fixture 等で audio isolation |
| step 7 | asset ownership / pipeline (= どこから持ってくるか) | (= 無、 build-time `.PNE` → VROM) | source-of-truth / generated / production 3 層分離 |
| step 8 | runtime observation (= runtime で何が見えるか) | `driver_pne_filename_buf` (= 0xFD20-0xFD2F) + `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) | (= 観測のみ、 playback 不変) |
| step 9 | runtime identity resolution (= runtime で何を意味づけるか) | `driver_pne_sample_table_id` (= 0xFD32) | (= 保存のみ、 playback 不変、 §決定 11 で literal 固定) |
| **step 10** | **runtime playback selection (= 意味を音に反映する)** | (= 0xFD32 を読むのみ、 新規 state なし) | **selection effective**: id=0x00 → audible / else → silent |

### 完成した鎖 (= step 10 完了後の runtime data flow)

```
build-time asset:        assets/pne/PMDNEO01.PNE
                                ↓ (= step 7 .PNE pipeline)
build-time embed:        VROM + .MN 内 filename string "step5.PNE"
                                ↓ (= step 8 .MN load chain)
runtime observation:     driver_pne_filename_buf (= 0xFD20-0xFD2F)
                                ↓ (= step 9 pmdneo_resolve_sample_table_id)
runtime identity:        driver_pne_sample_table_id (= 0xFD32)
                                ↓ (= step 10 pmdneo_select_sample_pointer)
runtime selection:       DE = adpcma_ch_sample_ptr_table[voice] or 0x0000
                                ↓ (= step 10 adpcma_keyon_simple)
chip register writes:    ADPCM-A reg 0x10/0x18/0x20/0x28/0x08/0x00 (= match)
                         or 完全 skip (= mismatch、 silent)
                                ↓
audible output:          drum 音 audible (= match) / silent (= mismatch)
```

## δ 完了条件 (= 7 件、 全 PASS)

### 条件 1: step 5/6/7/8/9 既存 verify script regression suite 全 PASS ✅

12 script を serial 実行 (= feedback_verify_script_serial_execution.md 整合)、 全件 PASS:

| step | script | gates | 結果 |
|---|---|---|---|
| 5 | verify-l-part-alpha-trace-gate.sh | 6 | PASS (= pre-existing symbol rename 修正後) |
| 5 | verify-l-part-beta-sample-lookup.sh | 3 | PASS |
| 5 | verify-l-part-delta-volume-pan.sh | 2 | PASS |
| 5 | verify-l-q-tutti-gamma.sh | 6 | PASS |
| 5 | verify-l-q-rhythm-song-integration.sh | 7 | PASS |
| 6 | verify-silent-bcef-audio-isolation.sh | 4 | PASS |
| 7 | verify-step7-b1-roundtrip.sh | 3 | PASS |
| 7 | verify-step7-b3-byte-identical.sh | 2 | PASS |
| 7 | verify-step7-delta-mn-filename-embed.sh | 4 | PASS |
| 7 | verify-step7-delta-fix-quote-strip.sh | 3 | PASS |
| 8 | verify-step8-filename-observation.sh | 5 | PASS |
| 9 | verify-step9-resolver.sh | 5 | PASS (= β commit 9f454f5 で dynamic DIRECTORY_OFFSET 化済) |

合計 **約 50 gate 全 PASS**。

### 条件 2: step 5 α-3 verify script の pre-existing symbol rename 修正 ✅

verify-l-part-alpha-trace-gate.sh (= 2026-05-12 commit e97210c で起票) の `pmdneo_mn_direct_load_l_part_addr` 参照を `pmdneo_mn_direct_load_lq_part_addr` に rename。

- 当時の routine 名: `pmdneo_mn_direct_load_l_part_addr` (= L only)
- 現在の routine 名: `pmdneo_mn_direct_load_lq_part_addr` (= L-Q parts、 step 5 γ-a 以降に generalize)
- script 側が generalize に追従していなかった pre-existing 問題 (= β/γ で導入された regression ではない)
- δ scope の regression suite 整備として simple rename 修正

### 条件 3: silent-bcef audible regression なし ✅

verify-silent-bcef-audio-isolation.sh PASS。 wav file (= 4 秒録音) を `/tmp/pmdneo-step10/silent-bcef.wav` に保存。 user 試聴で audible regression なし最終確認可能。

### 条件 4: match / mismatch audible difference (= user 試聴用 wav) ✅

γ 段階で `/tmp/pmdneo-step10/match.wav` / `mismatch.wav` を保存済。 両 wav の聴感比較で:

- match.wav: drum 音 audible (= ADPCM-A 39 keyon trigger)
- mismatch.wav: drum 音 silent、 FM 不変 (= ADPCM-A keyon 完全 skip、 FM 独立)

これは ADR-0024 §決定 3 (= 2-C) の意図的仕様変更を **聴感で literal 確認** する手段。

### 条件 5: ADR-0024 Annex 追記 + Accepted 移行 ✅

ADR-0024 に以下を追記:

- 完了判定達成状況 12 項目 (= 全項目 ✅ + 関連 commit hash)
- sub-sprint commit chain table (= α/β/γ/δ)
- regression suite 結果 table (= 12 script / 約 50 gate)
- Accepted 移行根拠 (= 5 件、 driver source 改修最小限 + scope-out 維持確認 + 既存 verify regression なし + audible なし + 設計判断記録の literal 固定)
- Accepted 後の重要境界 (= future contributor 向け、 「identity resolution → playback selection」 contract literal 明記)

status: Draft → **Accepted**

### 条件 6: memory 起票 + index 更新 ✅

- `project_pmdneo_step10_complete.md` 起票 (= step 10 完了状態の literal snapshot)
- `MEMORY.md` に index 行追加 (= 既存 step 5-9 完了 memory と同形)
- 既存 memory との link で「Step 5/6/7/8/9 → Step 10」 の系譜可視化

### 条件 7: step 10 完了統合 handoff doc 作成 ✅

本 doc。 identity resolution → playback selection contract 成立明記、 future contributor 向け runtime data flow 図示。

## Accepted 後の重要境界 (= future contributor 向け、 ADR-0024 §Accepted 後の重要境界 と整合)

### 既に成立したこと

- `.MN` 内 filename string が runtime に流れ (= step 8)、 identity (= sample_table_id) として resolve され (= step 9)、 playback selection に consume される (= step 10) という **1 本の連続した鎖** が成立
- match (= 0xFD32 == 0x00) で ADPCM-A drum 音 audible、 mismatch (= 0xFD32 != 0x00) で silent という **意図的仕様分岐** が runtime で effective
- 中間 routine `pmdneo_select_sample_pointer` (= ADR-0024 §決定 1/4) が identity と sample addr の **抽象境界** として確立、 future の selected pointer state cache 化 / multi-table 化 / silent flag 拡張の **接続点** として準備済

### まだ成立していないこと (= step 11+ scope、 ADR-0024 §scope-out 維持)

- selected pointer の runtime state cache 化 (= A3、 都度解決 vs 一度解決の trade-off)
- silent flag 拡張 (= flag-based silent、 sentinel pointer 0x0000 以外の表現)
- `adpcma_keyon_simple` 全体 refactor (= voice load / sample pointer / register write 分離、 ADR-0019 予告分)
- `adpcma_ch_sample_ptr_table` rename (= 1-C、 命名で意味明確化)
- 新規 table 並置 (= 1-B、 multi-table 化の最初の 1 段)
- `.PNE` binary 自体の runtime parse (= header / sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- dynamic reload (= 動的 `.PNE` 差替)
- generated directory (= D3 migration、 別 script / vromtool.py 拡張)
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)

### 誤解されがちなポイント (= future contributor 向け literal 明記)

- 「step 10 で multi-table / dynamic asset 化された」 → **誤**。 step 10 完了時点で table は 1 つ (= `adpcma_ch_sample_ptr_table`、 id=0x00 only-accept)、 multi-table は step 11+ scope。
- 「mismatch silent は step 9 から既に存在した」 → **誤**。 ADR-0023 §決定 8 で step 9 までは mismatch でも playback 続行、 step 10 β commit (= 9f454f5) で initial 解除、 ADR-0024 §決定 3/7 で明文化。
- 「sample_table_id == 0xFF は silent flag」 → **誤**。 0xFF はあくまで mismatch sentinel (= terminator hit path 由来)、 silent 実現は中間 routine の sentinel pointer 0x0000 返却で行う。 flag-based silent は step 11+ scope。
- 「ADR-0023 §決定 11 contract は step 9 完了時点でも有効」 → **誤**。 step 10 β commit (= 9f454f5) で **initial 解除**、 step 10 γ で chip register write 不発生を literal 証跡として固定、 step 10 δ (= 本 ADR Accepted) で literal 明文化。
- 「`pmdneo_select_sample_pointer` は selected pointer cache を持つ」 → **誤**。 ADR-0024 §決定 6 で selected pointer state は持たない明示、 routine 内で都度解決 (= directory addr 引きを毎 keyon 実行)、 cache 化は step 11+ scope。

## 既存 path 不変確認

δ では以下を一切改修しない (= driver source 完全不変):

- `assets/samples.inc`: 不変
- VROM: 不変
- driver `standalone_test.s` / `PMDNEO.s` / `*.inc`: **完全不変** (= δ 改修ゼロ)
- step 5 α/β/γ/δ/ε 既存 implementation: 不変
- step 6 silent-bcef fixture: 不変
- step 7 .PNE asset pipeline / converter / vromtool.py: 不変
- step 8 runtime filename observation: 不変
- step 9 resolver routine + directory: 不変
- step 10 α/β/γ implementation (= a9bb169 + 9f454f5 + 7abf533): 不変
- `.PNE` converter / vromtool.py / build pipeline: 不変

δ で改修したのは:
- step 5 α-3 verify script (= pre-existing 古い symbol rename、 driver source とは無関係の test infra maintenance)
- ADR-0024 Annex (= 完了判定 + commit chain + regression result + Accepted 移行)
- 本 completion handoff doc
- memory `project_pmdneo_step10_complete.md` + `MEMORY.md` index

## 次 sprint 候補 (= step 11+)

ADR-0024 scope-out のうち、 step 11+ で扱う候補:

1. **selected pointer runtime state 化 (= A3)** — cache + invalidation 規律設計、 都度解決から一度解決への切替、 multi-`.PNE` 化への前提準備
2. **silent flag 拡張 (= flag-based silent)** — sentinel pointer 0x0000 以外の silent 表現、 runtime state 追加
3. **`adpcma_keyon_simple` 全体 refactor (= 4-B / 4-C)** — voice load / sample pointer / register write 分離、 ADR-0019 予告の本格 refactor
4. **多 table 並置 (= 1-B)** — id=0x01, 0x02, ... 追加、 multi-table 化の最初の 1 段
5. **`adpcma_ch_sample_ptr_table` rename (= 1-C)** — 命名で意味明確化
6. **`.PNE` binary runtime parse** — header / sample entry / addr table 読込、 build-time embed → runtime parse への大規模転換
7. **multi-`.PNE` switching** — 楽曲ごと別 `.PNE` 切替、 楽曲交換時 ROM rebuild 不要化
8. **ROM bank switching / 動的 sample bank 管理** — 大容量 sample 対応
9. **generated directory (= D3) migration** — D1 hand-written から D3 generated への移行、 別 script / vromtool.py 拡張
10. **K/R rhythm compatibility 現役接続** — ADR-0019 §決定 2 micro-sprint 候補
11. **PMDNEO.s + nullsound integration** — 大規模 sprint、 driver 二系統の統合
12. **新規 sample 追加** — WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域
13. **PPZ compatibility mode**
14. **FM-Towns-style rhythm mode**

優先順位は user 都度判断 (= CLAUDE.md §「記憶は AI に、 判断は自分が握る」 整合)。

## 関連

- [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) Accepted (= 本 sprint 設計判断記録)
- [ADR-0024 step 10 α handoff](adr-0024-step10-alpha-routine-implementation.md) (= α dead code routine 単体実装)
- [ADR-0024 step 10 β handoff](adr-0024-step10-beta-keyon-call-insertion.md) (= β keyon path call insertion、 ADR-0023 §決定 11 contract 解除)
- [ADR-0024 step 10 γ handoff](adr-0024-step10-gamma-mismatch-silent-verify.md) (= γ mismatch silent literal 証跡)
- [ADR-0023](../../adr/0023-pmdneo-step9-pne-filename-sample-table-id-resolver.md) §決定 11 (= step 9 内で sample_table_id は playback decision に使用しない、 本 ADR §決定 7 で解除)
- [ADR-0022](../../adr/0022-pmdneo-step8-pne-runtime-filename-observation.md) (= runtime filename observation 基盤)
- [ADR-0021](../../adr/0021-pmdneo-step7-pne-asset-pipeline-and-mn-filename-embed.md) (= `.PNE` asset pipeline + `.MN` filename embed)
- [ADR-0019](../../adr/0019-pmdneo-step5-adpcma-6ch-design-decisions.md) (= step 5 ADPCM-A 6ch、 本 sprint の base playback path)
- [ADR-0016](../../adr/0016-pmdneo-implementation-sprint-plan.md) (= 改造実装 sprint 作業計画)
- `project_pmdneo_step10_complete.md` (= memory、 step 10 完了 literal snapshot)
- `project_pmdneo_step9_complete.md` (= memory、 step 9 完了 = 本 sprint の入力)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= memory、 Step 5/6/7 役割分離、 step 10 は「runtime selection」 軸の 2 段目)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= α/β 分離 + PC trace primary で trivial verify 防止、 本 sprint で実証)
- `feedback_refactor_gate_register_trace_not_wav.md` (= ymfm-trace byte-identical が refactor 系 primary gate、 本 sprint β で実証)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 silent-bcef fixture 流用)
- `feedback_verify_script_serial_execution.md` (= verify script は serial 実行、 本 sprint δ で 12 script serial PASS)

## 完了告知

**PMDNEO ADR-0024 step 10 sprint 完了**。 `sample_table_id` selection consumption が成立、 `.MN` filename → runtime identity → playback selection の 1 本の鎖が initial に効果的に。 ADR-0024 Accepted、 全 12 regression PASS、 audible なし、 driver source 改修最小限 (= keyon path 5 byte 削減 + 新 routine 22 byte 追加)。 「動いているものを壊さない」 規律遵守、 future step 11+ への接続点 (= 中間 routine 抽象境界 + scope-out 維持) 準備済。
