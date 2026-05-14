# ADR-0027 step 13 δ completion handoff: K/R drum kind expansion proof — s = SD sprint 完了統合

- 関連 ADR: [ADR-0027](../../adr/0027-pmdneo-step13-kr-drum-kind-expansion-sd.md) **Accepted** (= 2026-05-14 14th session δ 完了統合で移行)
- sub-sprint: δ (= 5 commit chain の 5 段目 = 最終、 完了統合 + Accepted 移行)
- commit: 本 commit
- 前段: γ commit `2aad439` (= R-SD fixture + K-SD vs R-SD differential + BD vs SD differential 2 verify 新規 + 13 gate 全 PASS)
- 次段: Step 14 候補 (= 本 handoff §Step 14 候補参照、 user 14th session γ レビューで drum 種拡張 (c/h/t/i) / BD+SD simultaneous bitmap OR semantics / `.PNE` rhythm bank migration 等を Step 14 候補として温存)

## Step 13 sprint の本質 (= Accepted 後の literal 固定、 user δ handoff 記載要件)

**Step 13 は K/R full compatibility ではなく K/R drum kind expansion proof stage**。 future contributor が「K/R drum 種完成版」 と誤解せず、 「K/R semantics の drum 種が b → b+s に 1 軸拡張した proof」 として扱えるよう本 handoff で literal 明記する。

### Step 12 → Step 13 の関係 (= user δ handoff 必須記載)

```
Step 12 (= ADR-0026 Accepted): b-only proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 不変)
Step 13 (= ADR-0027 Accepted): b + s expansion proof
```

Step 13 は Step 12 の **drum kind 軸 1 段拡張** であり、 dispatch path / routine entry / observability marker / K-R 共通 hook / driver-embedded fixture proof 規律 全て不変。 「dispatch path は drum 種拡張で増やさない」 (= ADR-0026 §決定 6 / 8 + ADR-0027 §決定 8) が **literal 実装的に保証された** 最小成立形。

### 達成したこと (= Step 13 で literal 成立)

| 項目 | 内容 |
|---|---|
| **K-SD path (= K part `\s`)** | PMD V4.8s K part 内 `\s` → PMDDotNET emit `0xEB 0x02 0x80` (= rhykey SD bitmap + part end、 mc.cs L9529 + L9697 + L9748 emit literal) → driver `rhythm_main_rhykey` → `pmdneo_rhythm_event_trigger` @ 0x1126 → bit 1 分岐 → `_rhythm_event_sd_trigger` @ 0x115F → ADPCM-A L ch SD register write (= reg 0x10 0x04 / 0x18 0x00 / 0x20 0x06 / 0x28 0x00 / 0x08 0xDF / 0x00 0x01) |
| **R-SD path (= melody part inline `\s`)** | melody part (= L part 採用) 内 `\s` inline → PMDDotNET emit `0xEB 0x02` inline → driver `commandsp_rhykey` (= Step 12 既存) → 同 `pmdneo_rhythm_event_trigger` @ 0x1126 → 同 bit 1 分岐 → 同 `_rhythm_event_sd_trigger` @ 0x115F → 同 ADPCM-A L ch SD register write |
| **K-SD と R-SD の dispatch path 1 本化** | K part / melody part の 2 source path が runtime layer で同 routine entry (= 0x1126) + 同 SD routine entry (= 0x115F) に collapse、 同 SD register write sequence が K-SD build / R-SD build で byte-identical (= 6 件)、 keyon count identical (= 1) |
| **BD vs SD drum kind expansion** | bit 0 BD trigger / bit 1 SD trigger が個別 if/jr 分岐で literal 区別、 BD start LSB 0x00 ≠ SD start LSB 0x04 + BD stop LSB 0x03 ≠ SD stop LSB 0x06 (= register addr literal で観測可能、 silent 倒れではない)、 MSB / vol|pan / keyon mask は BD=SD identical (= 同 L ch state) |
| **dispatch path 1 本化の drum 種拡張下維持** | `pmdneo_rhythm_event_trigger` entry addr @ 0x001126 が 4 fixture (= K-BD / R-BD / K-SD / R-SD) 全部で完全同一 (= ADR-0026 §決定 6 「K と R の dispatch = 共通 rhythm event hook」 が drum 種拡張下で literal 維持、 ADR-0027 §決定 8 「dispatch path は drum 種拡張で増やさない」 literal 達成) |
| **driver-embedded SD trigger** | 既存 `adpcma_sample_sd` (= proof 用 driver fixture、 ADR-0025 step 11 で既に embed 済) を再利用、 新規 sample embed なし (= ADR-0027 §決定 3 整合) |
| **observability marker (= 不変継続)** | 独立 routine label `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable (= ADR-0026 §決定 8 / ADR-0027 §決定 9 整合、 memory marker byte なし、 SRAM layout 増設なし) |
| **既存 layering 不変保証** | PMDDotNET / `.MN` format / 既存 L-Q ADPCM-A melody architecture / multi-table proof / silent-bcef audio isolation / Step 12 K-BD path 全て不変、 20/20 script regression PASS |

### 達成していないこと (= scope-out 維持、 future scope)

**user δ handoff 記載要件 (= 14th session γ user 重視軸)**:

| 項目 | scope-out 維持理由 |
|---|---|
| **Step 13 は b + s only proof** (= BD bit 0 + SD bit 1 accept) | c/h/t/i 残り 4 drum 種 (= CYM / HH / TOM / RIM、 PMDDotNET mc.cs rcomtbl `'i' → rimset` literal、 `\r` は rest 専用) は future sub-sprint、 dispatch path は不変で drum 種 → sample pointer mapping を 1 軸拡張のみ |
| **bit 2-5 ignore 維持** | driver は bit 0 + bit 1 のみ accept、 bit 2-5 (= CYM `\c` / HH `\h` / TOM `\t` / RIM `\i`) は **silent ignore** (= ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲、 ADR-0027 §決定 2 維持)。 future drum 種拡張時に bit 別 branch 追加で対応 |
| **BD+SD simultaneous trigger (= bitmap 0x03) scope-out** | Step 13 fixture では emit せず (= ADR-0027 §決定 11 + 軸 2 維持)。 driver 側は 0x03 arrive 時に BD trigger 6 件 reg write + SD trigger 6 件 reg write 連続 (= **観測上 harmful なし**、 ただし「0x03 が動く」 ことと「同時打ち semantics を仕様化する」 ことは別議題、 Step 14+ で bitmap OR semantics literal proof sprint 起票時に再評価) |
| **L ch allocation scaffold 維持** | ADR-0026 §決定 4 整合、 K/R rhythm event 受入 ch = ADPCM-A L ch (= ch 0) は **proof 用暫定 allocation**、 PMDNEO 恒久仕様ではない。 L-Q melody architecture は恒久的に縮小しない |
| **driver-embedded BD/SD sample は proof 用** | ADR-0026 §決定 3 / ADR-0027 §決定 3 整合、 `adpcma_sample_bd` / `adpcma_sample_sd` 再利用は最終 ownership ではない。 future sprint で `.PNE` rhythm bank へ migration path を維持 |
| **drum 種 → sample pointer mapping table 構造化 scope-out** | 2-3 drum 段階は explicit branch + literal addr 参照 (= ADR-0027 §決定 6 整合、 ADR-0024/0025/0026 流儀踏襲)。 4+ drum 拡張時に lookup table 構造化を再評価 (= 早すぎる抽象化を避ける) |
| **full 6 drum K/R compatibility は未実装** | Step 13 は dispatch path 1 本化が drum 種拡張下で維持されることの literal 証明が目的。 各 drum 種別の sample 切替 / volume / pan / 複数 drum 同時打ち / pattern loop / velocity は future sprint |
| **`.PNE` rhythm bank integration は future** | ADR-0026 §決定 3 / ADR-0027 §決定 3 / scope-out 整合、 `sample_table_id` id=0x02 rhythm bank / generated rhythm sample directory / driver-embedded fixture からの migration は future sprint で必要なら別途検討 |

加えて維持される他 scope-out 項目 (= ADR-0027 §scope-out 27 項目から抜粋):

| 項目 | scope-out 維持理由 |
|---|---|
| OPNA rhythm sound source register fake API (= 0x10-0x18) | PMDNEO は YM2610(B) で物理的に rhythm source 不在、 emulation は方針外 (= ADR-0026 §決定 2 / β 軸採用根拠) |
| 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation | 最終 channel allocation は future sprint で channel allocation 軸の sprint 起票時に検討 |
| PMDDotNET 改造 / `.MN` format new bytecode 追加 | ADR-0026 §決定 7 / ADR-0027 §決定 10 整合、 Step 7-13 layering 維持原則継続 |
| OPNA native rhythm timing fidelity | dispatch proof であり完全 timing compatibility ではない (= ADR-0026 scope-out 追加項目維持) |
| K と R 共通 dispatch 以外の K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件) | PMDNEO.s legacy 系 KR_STUB.inc の no-op stub 思想を継続維持、 standalone_test.s 本線でも他 cmd は silent fallback (= 1 byte 消費継続) |
| selected pointer runtime state cache (= A2/A3) | ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 維持 |
| 3 table 以上の multi-table / generated directory (D3) / runtime `.PNE` parser / multi-`.PNE` switching / bank switching | ADR-0025 §scope-out 継続維持 |

## sub-sprint chain 完了結果

### 5 commit chain (= ADR + α/β/γ/δ)

| sub | commit | 一文要約 |
|---|---|---|
| ADR | `e19bb29` | ADR-0027 起票 Draft、 14th session 冒頭壁打ち 5 軸確定 + §決定 11 件 + sub-sprint 分割 + scope-out 27 項目明示 + 「本質再確認」 callout + layering 図 literal 固定 |
| α | `37cf2f9` | ADR-0027 Annex A 追記 (= PMDDotNET SD emit 調査結果 9 sub-section literal 反映)、 driver 完全不変純調査 commit、 RIM 識別文字訂正 finding (= `\i`、 `\r` は rest 専用、 §決定 2 内 c/h/t/r → c/h/t/i 訂正)、 既存 16 script regression 動作影響なし、 fail-safe 3 件 evaluate → β 進行可 判定 |
| β | `36588b3` | standalone_test.s pmdneo_rhythm_event_trigger 改修 (= push af / bit 0 + call nz _rhythm_event_bd_trigger / pop af / bit 1 + ret z / jr _rhythm_event_sd_trigger 構造、 +70/-15 行) + k-sr-only.mml fixture 新規 + verify-step13-sd-trigger.sh 5 gate PASS、 既存 step12 K-BD path regression 2 件 PASS (= entry addr 0x1126 不変) |
| γ | `2aad439` | r-melody-sr-only.mml fixture 新規 + verify-step13-kr-sd-differential.sh 7 gate PASS (= K-SD vs R-SD byte-identical) + verify-step13-bd-sd-differential.sh 6 gate PASS (= BD vs SD sample addr literal differ)、 driver 完全不変 |
| δ | 本 commit | 完了統合 + ADR-0027 Accepted 移行 + 全 20 script regression PASS + audible 試聴 OK (= user judgement: K/R 同音 + BD/SD 区別可能) + handoff doc 起票 + memory + MEMORY.md update |

### 「動いているものを壊さない」 規律遵守 (= ADR-0021-0026 で確立、 Step 13 で継続)

各 sub-sprint で driver source 改修を最小化し、 trivial verify (= 既存 path で false PASS) を段階分離で防いだ。

- ADR Draft: driver / `.MN` format / PMDDotNET 完全不変 (= 純文書化 commit、 732 行追加)
- α: driver / `.MN` format / PMDDotNET 完全不変 (= 純調査 commit、 ADR §Annex A literal 反映 + §決定 2 訂正、 370 行追加 / 44 行削除)
- β: driver standalone_test.s に 70 行追加 / 15 行削除 (= pmdneo_rhythm_event_trigger 改修 + _rhythm_event_bd_trigger 別 routine 化 + _rhythm_event_sd_trigger 新規)、 既存 BD path content (= 6 件 reg write) 完全不変、 PMDDotNET / `.MN` format 完全不変
- γ: driver source 完全不変 (= fixture + verify script のみ、 535 行追加)
- δ: driver source 完全不変 (= regression + Accepted 移行 + handoff + memory のみ)

各段階の primary gate が trivial verify を弾く設計 (= memory `feedback_trivial_verify_detection_and_correction_commit` 整合):

- ADR Draft gate: doc only、 既存 16 script regression PASS 維持 (= ADR-0026 完了状態継続)
- α gate: driver 不変 literal 確認 + 既存 16 script regression PASS + RIM 訂正 finding は doc only 反映 (= 実装影響なし)
- β gate: build PASS + pmdneo_rhythm_event_trigger entry addr 0x1126 不変 + _rhythm_event_sd_trigger symbol 存在 + K-SD fixture run PC trace marker hit + ADPCM-A L ch SD register write literal (= 5 reg + keyon mask) + 既存 step12 K-BD path regression 2 件 PASS
- γ gate: K-SD vs R-SD routine addr identical + K-SD vs R-SD SD register write sequence byte-identical (= 6 件) + K-SD vs R-SD keyon count identical + BD vs SD sample addr literal differ + BD vs SD MSB/vol|pan/keyon identical + 既存 step12 K-BD path regression 2 件 PASS
- δ gate: 全 20 script regression PASS + user 試聴 OK

## 全 20 script regression 結果 (= δ で serial 実行、 `feedback_verify_script_serial_execution` 整合)

実行時間: 17:35:01 → 17:36:12 (= 71 秒、 全 20 script PASS、 driver 改修副作用なし literal 確認)

| step | script | 結果 |
|---|---|---|
| step 4 | `verify-j-part-fixture-driven.sh` | ✅ PASS |
| step 5 | `verify-l-part-alpha-trace-gate.sh` | ✅ PASS |
| step 5 | `verify-l-part-beta-sample-lookup.sh` | ✅ PASS |
| step 5 | `verify-l-part-delta-volume-pan.sh` | ✅ PASS |
| step 5 | `verify-l-q-rhythm-song-integration.sh` | ✅ PASS |
| step 5 | `verify-l-q-tutti-gamma.sh` | ✅ PASS |
| step 6 | `verify-silent-bcef-audio-isolation.sh` | ✅ PASS |
| step 7 | `verify-step7-b1-roundtrip.sh` | ✅ PASS |
| step 7 | `verify-step7-b3-byte-identical.sh` | ✅ PASS |
| step 7 | `verify-step7-delta-fix-quote-strip.sh` | ✅ PASS |
| step 7 | `verify-step7-delta-mn-filename-embed.sh` | ✅ PASS |
| step 8 | `verify-step8-filename-observation.sh` | ✅ PASS |
| step 9 | `verify-step9-resolver.sh` | ✅ PASS |
| step 10 | `verify-step10-mismatch-silent.sh` | ✅ PASS |
| step 11 | `verify-step11-multi-table.sh` | ✅ PASS |
| step 12 | `verify-step12-k-rhythm-trigger.sh` | ✅ PASS |
| step 12 | `verify-step12-kr-differential.sh` | ✅ PASS |
| step 13 | `verify-step13-sd-trigger.sh` | ✅ PASS (新規) |
| step 13 | `verify-step13-kr-sd-differential.sh` | ✅ PASS (新規) |
| step 13 | `verify-step13-bd-sd-differential.sh` | ✅ PASS (新規) |

20/20 PASS。 driver `pmdneo_rhythm_event_trigger` 改修 (= bit 1 SD 分岐追加) が他 step (= step 4-11) に副作用なし、 既存 L-Q ADPCM-A melody / multi-table proof / silent-bcef audio isolation / .PNE asset pipeline / runtime filename observation / sample_table_id resolver / mismatch silent / multi-table id=0x01 selection 全て不変保持を literal 確認。

## audio gate 結果 (= 14th session δ user 試聴)

user judgement (= 14th session δ):

- **k-br-only ≒ r-melody-br-only** (= K-BD と R-BD で同音)
- **k-sr-only ≒ r-melody-sr-only** (= K-SD と R-SD で同音)
- BD と SD で違う音色 (= sample addr literal differ literal を耳でも区別可能)
- FM 同居許容 (= test01/test02 chord 進行と並走、 Step 12 audio gate 規律踏襲)
- 「Step 13 audio gate OK」 判定

audio gate と register trace gate の二段 verify で:

- register trace: byte-identical proof (= K-SD vs R-SD literal proof)
- audio gate: 聴感同音 proof (= user judgement で K-SD ≒ R-SD、 BD ≠ SD 区別)

両 axis で Step 13 contract 達成。

## PMDNEO rhythm architecture layering (= Step 13 完了時点、 user 14th session γ 整理)

```
source syntax
  │ K part / melody part inline
  │ \b (BD) / \s (SD)
  │ (= PMD V4.8s K/R compatibility syntax)
  ↓
normalize
  │ driver .MN direct parser
  │ 0xEB <bitmap> rhykey opcode
  │ (= PMDDotNET / .MN format 完全不変)
  ↓
shared dispatch
  │ pmdneo_rhythm_event_trigger @ 0x1126
  │ (= K-BD / R-BD / K-SD / R-SD 4 fixture で完全同一 entry addr)
  ↓
drum kind mapping
  │ bit 0 → _rhythm_event_bd_trigger → adpcma_sample_bd
  │ bit 1 → _rhythm_event_sd_trigger → adpcma_sample_sd
  │ bit 2-5 → silent ignore (= future drum 種拡張で branch 追加、 entry addr 不変)
  ↓
ADPCM-A trigger
  │ L ch (ch 0、 暫定 scaffold)
  │ 6 件 register write (= reg 0x10/0x18/0x20/0x28/0x08/0x00)
  │ keyon mask 0x01
```

この layering が Step 12 → Step 13 で **drum kind mapping 軸のみ 1 段拡張**、 他 layer は完全不変。 future drum 種拡張 (= c/h/t/i) でも同 pattern (= drum kind mapping に 1 軸 branch 追加、 dispatch entry 不変) で実装予定。

## Step 14 候補 (= ADR-0027 §scope-out 未消化 + future sprint、 user γ レビュー軸)

1. **drum 種拡張 c/h/t/i** (= CYM / HH / TOM / RIM、 dispatch path 不変で drum 種 → sample pointer mapping 1 軸拡張、 全 6 drum compatibility 完成)
2. **BD+SD simultaneous trigger bitmap OR semantics literal proof** (= bitmap 0x03 fixture / verify、 PMDDotNET の bitmap OR 圧縮 emit を driver 側で literal 解釈する proof、 Step 13 で「観測上 harmful なし」 を踏まえ literal 仕様化)
3. **drum 種 → sample pointer mapping table 構造化** (= 4+ drum 状況で lookup table refactor を再評価、 早すぎる抽象化を避けつつ拡張性確保)
4. **`.PNE` rhythm bank migration** (= driver-embedded fixture → `.PNE` 経由 id=0x02 bank、 generated rhythm sample directory)
5. **rhythm channel concept formalization** (= ADR-0026 §決定 4 (c2)/(c3)/(c4) のいずれか採用、 channel allocation 最終仕様)
6. **複数 drum 同時打ち full proof** (= bitmap OR semantics + driver 側 timing 同時 trigger + audible 確認)
7. **OPNA native rhythm timing fidelity** (= ADR-0026 scope-out 追加項目、 Step 14+ で必要なら検討)
8. **K/R 制御 cmd 現役化** (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件、 OPNA rhythm pan / volume 周辺)
9. **selected pointer cache** (= A2/A3 動的化局面、 ADR-0024/0025/0026/0027 で全 sprint scope-out 維持)
10. **mismatch silent flag micro-sprint** (= ADR-0024 / 0025 §scope-out 継続)
11. **D3 generated directory migration** (= asset pipeline 完成版へ)
12. **runtime `.PNE` parser / multi-`.PNE` switching / bank switching**
13. **PMDNEO.s + nullsound integration** (= legacy 系統との reunification)
14. **WebApp Phase 4** (= WAV import / 新規 sample 追加 UI)

Step 13 完了で「K/R drum kind expansion proof」 path 成立、 Phase 3 driver の機能カバレッジは melody + multi-table + rhythm dispatch + drum kind 2 種まで完成。 「dispatch path は drum 種拡張で増やさない」 contract が Step 12 → Step 13 で literal 実装的に保証され、 future drum 種拡張 (= c/h/t/i 4 種) でも同 pattern で簡潔追加可能な architecture が成立。

## 関連

- ADR-0027 (= 本 sprint Accepted)
- ADR-0026 (= Step 12 K/R rhythm compatibility proof、 本 sprint の前段)
- ADR-0025 (= Step 11 multi-table id=0x01 proof、 SD sample 既存 reuse 経路)
- ADR-0024 (= Step 10 sample_table_id selection consumption、 explicit if/jr 流儀)
- ADR-0019 (= Step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= Step 5 §決定 2 K/R legacy retained but inactive → Step 12 reconnected → Step 13 expanded)
- memory `project-pmdneo-step13-complete` (= 本 sprint 完了 memory)
- memory `project-pmd-rim-drum-char-correction` (= 14th session α RIM 訂正 finding)
- memory `feedback-pmddotnet-mml-authoring-rules` (= CRLF authoring requirement、 14th session β で再確認)
