# ADR-0028 step 14 δ completion handoff: K/R drum kind expansion proof — h = HH sprint 完了統合

- 関連 ADR: [ADR-0028](../../adr/0028-pmdneo-step14-kr-drum-kind-expansion-hh.md) **Accepted** (= 2026-05-14 15th session δ 完了統合で移行)
- sub-sprint: δ (= 4 commit chain の 4 段目 = 最終、 完了統合 + Accepted 移行、 注: ADR-0027 同型 5 段表 (= ADR/α/β/γ/δ) のうち α は user 着手判断で ADR Draft commit に統合 = 独立 α commit なし)
- commit: 本 commit
- 前段: γ commit `78dfe74` (= R-HH fixture + K-HH vs R-HH differential + BD vs HH differential 2 verify 新規 + 13 gate 全 PASS)
- 次段: Step 15 候補 (= 本 handoff §Step 15 候補参照、 user 15th session γ レビューで drum 種拡張 c/t/i / simultaneous trigger bitmap OR semantics / `.PNE` rhythm bank migration / table-driven dispatch refactor 等を Step 15 候補として温存)

## Step 14 sprint の本質 (= Accepted 後の literal 固定、 user δ handoff 記載要件)

**Step 14 は K/R full compatibility ではなく K/R drum kind expansion proof stage の 2 段目**。 future contributor が「K/R drum 種完成版」 と誤解せず、 「K/R semantics の drum 種が b+s → b+s+h に 1 軸拡張した proof」 として扱えるよう本 handoff で literal 明記する。

### Step 13 → Step 14 の関係 (= user δ handoff 必須記載)

```
Step 12 (= ADR-0026 Accepted): b only proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 不変)
Step 13 (= ADR-0027 Accepted): b + s expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 3 drum 段下不変)
Step 14 (= ADR-0028 Accepted、 本 commit): b + s + h expansion proof
```

Step 14 は Step 13 の **drum kind 軸 1 段拡張** であり、 dispatch path / routine entry / observability marker / K-R 共通 hook / driver-embedded fixture proof 規律 全て不変。 「dispatch path は drum 種拡張で増やさない」 (= ADR-0026 §決定 6/8 + ADR-0027 §決定 8 + ADR-0028 §決定 8) が **3 drum 段下で literal 実装的に保証された** 段階。

### invariant 精密化 (= 15th session γ user 指示、 ADR-0028 §決定 1/4/8 で wording 精密化)

**invariant の本質 = shared dispatch entry 不変 + register write sequence 不変** (= sub-routine entry addr 不変ではない):

| 軸 | 不変保証 | 観測値 (Step 14 完了時点) |
|---|---|---|
| **primary**: shared dispatch entry | `pmdneo_rhythm_event_trigger` entry addr 完全同一 | Step 12/13/14 = 0x001126 不変 (= 6 fixture 全部) |
| **secondary**: register write sequence | 各 drum trigger sub-routine の 6 件 reg write の literal value 不変 | BD/SD/HH それぞれ sample addr のみ literal differ、 sequence 構造 + vol|pan + keyon mask 完全不変 |
| **NOT invariant**: internal sub-routine entry addr | dispatcher 改修で shift 可、 不変保証対象外 | `_rhythm_event_sd_trigger` Step 13 完了時 0x115F → Step 14 完了時 0x1166 に 7 bytes shift observed (= dispatcher の bit 1 SD `jr` → `call nz` 変更 + bit 3 分岐追加で計 7 bytes 増) |

verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0028 §verify gate Gate 2/3 + verify-step14-* 全 script 整合)。

### 達成したこと (= Step 14 で literal 成立)

| 項目 | 内容 |
|---|---|
| **K-HH path (= K part `\h`)** | PMD V4.8s K part 内 `\h` → PMDDotNET emit `0xEB 0x08 0x80` (= rhykey HH bitmap + part end、 mc.cs L9530 + L9697-9725 hihset + L9748 emit literal、 ADR-0027 §Annex A-1/A-2 で literal 確認済) → driver `rhythm_main_rhykey` → `pmdneo_rhythm_event_trigger` @ 0x001126 → bit 3 分岐 → `_rhythm_event_hh_trigger` @ 0x001193 → ADPCM-A L ch HH register write (= reg 0x10 0x07 / 0x18 0x00 / 0x20 0x09 / 0x28 0x00 / 0x08 0xDF / 0x00 0x01) |
| **R-HH path (= melody part inline `\h`)** | melody part (= L part 採用) 内 `\h` inline → PMDDotNET emit `0xEB 0x08` inline → driver `commandsp_rhykey` (= Step 12 既存) → 同 `pmdneo_rhythm_event_trigger` @ 0x001126 → 同 bit 3 分岐 → 同 `_rhythm_event_hh_trigger` @ 0x001193 → 同 ADPCM-A L ch HH register write |
| **K-HH と R-HH の dispatch path 1 本化** | K part / melody part の 2 source path が runtime layer で同 routine entry (= 0x001126) + 同 HH routine entry (= 0x001193) に collapse、 同 HH register write sequence が K-HH build / R-HH build で byte-identical (= 6 件)、 keyon count identical (= 1) |
| **BD vs HH drum kind expansion** | bit 0 BD trigger / bit 1 SD trigger / bit 3 HH trigger が個別 if/jr 分岐で literal 区別、 BD start LSB 0x00 ≠ HH start LSB 0x07 + BD stop LSB 0x03 ≠ HH stop LSB 0x09 (= register addr literal で観測可能、 silent 倒れではない)、 MSB / vol|pan / keyon mask は BD=HH identical (= 同 L ch state) |
| **SD vs HH 推移的区別 (= explicit gate scope-out)** | BD vs SD literal differ (= ADR-0027 §Gate 4 確立) + BD vs HH literal differ (= 本 ADR §Gate 4 確立) → SD 0x04-0x06 ≠ HH 0x07-0x09 は推移的に literal differ proof 成立 (= explicit gate 不要、 N-1 pair gate で N 軸 differential を推移的に確立可能、 future c/t/i 拡張も同 pattern) |
| **dispatch path 1 本化の 3 drum 段下維持** | `pmdneo_rhythm_event_trigger` entry addr @ 0x001126 が 6 fixture (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH) 全部で完全同一 (= ADR-0026 §決定 6 + ADR-0027 §決定 8 + ADR-0028 §決定 8 「dispatch path は drum 種拡張で増やさない」 が 3 drum 段で literal 達成) |
| **既存 `adpcma_sample_hh` symbol reuse** | 既存 `adpcma_sample_hh` (= L-Q architecture N ch sample symbol、 ADR-0025 step 11 で embed 済) を rhythm proof 用に reuse、 新規 sample embed なし (= ADR-0028 §決定 3 / 軸 6 整合、 ADR-0027 SD = `adpcma_sample_sd` reuse pattern 踏襲)。 melody architecture N ch sample symbol と現段階で共有、 final rhythm sample ownership は `.PNE` rhythm bank migration future |
| **observability marker (= 不変継続)** | 独立 routine label `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 整合、 memory marker byte なし、 SRAM layout 増設なし、 6 fixture 全部で同 0x001126 hit) |
| **既存 layering 不変保証** | PMDDotNET / `.MN` format / 既存 L-Q ADPCM-A melody architecture / multi-table proof / silent-bcef audio isolation / Step 12 K-BD path / Step 13 K-SD path 全て不変、 23/23 script regression PASS |

### 達成していないこと (= scope-out 維持、 future scope)

**user δ handoff 記載要件 (= 15th session γ user 重視軸)**:

| 項目 | scope-out 維持理由 |
|---|---|
| **Step 14 は b + s + h only proof** (= bit 0 BD + bit 1 SD + bit 3 HH accept) | c/t/i 残り 3 drum 種 (= CYM bit 2 / TOM bit 4 / RIM bit 5、 `\r` は rest 専用、 PMDDotNET mc.cs rcomtbl `'i' → rimset` literal、 ADR-0027 §Annex A-1) は future sub-sprint、 dispatch path は不変で drum 種 → sample pointer mapping を 1 軸拡張のみ |
| **bit 2/4/5 ignore 維持** | driver は bit 0 + bit 1 + bit 3 のみ accept、 bit 2/4/5 (= CYM `\c` / TOM `\t` / RIM `\i`) は **silent ignore** (= ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲、 ADR-0027 §決定 2 / ADR-0028 §決定 2 維持)。 future drum 種拡張時に bit 別 branch 追加で対応 |
| **simultaneous trigger (= bitmap 0x03 / 0x09 / 0x0A / 0x0B = BD+SD / BD+HH / SD+HH / BD+SD+HH) scope-out** | Step 14 fixture では emit せず (= ADR-0028 §決定 11 + 軸 4 維持)。 driver 側は arrive 時に対応 bit の trigger を連続 register write で対応 (= **観測上 harmful なし**、 ただし「simultaneous semantics の literal 仕様化」 は別議題、 Step 15+ で bitmap OR semantics literal proof sprint 起票時に再評価) |
| **L ch allocation scaffold 維持** | ADR-0026 §決定 4 整合、 K/R rhythm event 受入 ch = ADPCM-A L ch (= ch 0) は **proof 用暫定 allocation**、 PMDNEO 恒久仕様ではない。 L-Q melody architecture は恒久的に縮小しない |
| **driver-embedded BD/SD/HH sample は proof 用** | ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 整合、 `adpcma_sample_bd` / `adpcma_sample_sd` / `adpcma_sample_hh` reuse は最終 ownership ではない。 future sprint で `.PNE` rhythm bank へ migration path を維持 |
| **rhythm-dedicated symbol 分離 scope-out** | ADR-0028 §決定 3 / 軸 6 整合、 melody architecture N ch sample symbol と rhythm proof sample source は現段階で symbol 共有。 future で `.PNE` rhythm bank migration 時に rhythm-dedicated symbol 分離を再評価 |
| **drum 種 → sample pointer mapping table 構造化 scope-out** | 3 drum 段階は explicit branch + literal addr 参照 (= ADR-0028 §決定 6 整合、 ADR-0024/0025/0026/0027 流儀踏襲)。 4+ drum 段到達時に lookup table 構造化を再評価 (= 早すぎる抽象化を避ける、 full drum set = 6 drum 段到達後優先) |
| **table-driven dispatch refactor scope-out** | ADR-0028 §決定 4 / 軸 5 整合、 hybrid 採用で sub-routine pattern 踏襲 + table-driven refactor は future sprint。 dispatch path 不変の本質は entry point と runtime event path が増えないことなので内部 sub-routine 追加は許容 |
| **full 6 drum K/R compatibility は未実装** | Step 14 は dispatch path 1 本化が 3 drum 段下で維持されることの literal 証明が目的。 各 drum 種別の sample 切替 / volume / pan / 複数 drum 同時打ち / pattern loop / velocity は future sprint |
| **`.PNE` rhythm bank integration は future** | ADR-0026 §決定 3 / ADR-0027 §決定 3 / ADR-0028 §決定 3 / scope-out 整合、 `sample_table_id` id=0x02 rhythm bank / generated rhythm sample directory / driver-embedded fixture からの migration は future sprint で必要なら別途検討 |

加えて維持される他 scope-out 項目 (= ADR-0028 §scope-out 28+ 項目から抜粋):

| 項目 | scope-out 維持理由 |
|---|---|
| OPNA rhythm sound source register fake API (= 0x10-0x18) | PMDNEO は YM2610(B) で物理的に rhythm source 不在、 emulation は方針外 (= ADR-0026 §決定 2 / β 軸採用根拠、 ADR-0027/0028 §scope-out 維持) |
| 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation | 最終 channel allocation は future sprint で channel allocation 軸の sprint 起票時に検討 |
| PMDDotNET 改造 / `.MN` format new bytecode 追加 | ADR-0026 §決定 7 / ADR-0027 §決定 10 / ADR-0028 §決定 10 整合、 Step 7-14 layering 維持原則継続 |
| OPNA native rhythm timing fidelity | dispatch proof であり完全 timing compatibility ではない (= ADR-0026 scope-out 追加項目維持) |
| K と R 共通 dispatch 以外の K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件) | PMDNEO.s legacy 系 KR_STUB.inc の no-op stub 思想を継続維持、 standalone_test.s 本線でも他 cmd は silent fallback (= 1 byte 消費継続) |
| selected pointer runtime state cache (= A2/A3) | ADR-0024 §決定 6 / ADR-0025 §決定 1 / ADR-0026 §決定 11 / ADR-0027 §決定 1 維持 |
| 3 table 以上の multi-table / generated directory (D3) / runtime `.PNE` parser / multi-`.PNE` switching / bank switching | ADR-0025 §scope-out 継続維持 |

## sub-sprint chain 完了結果

### 4 commit chain (= ADR(+α 統合) + β/γ/δ)

| sub | commit | 一文要約 |
|---|---|---|
| ADR (+α 統合) | `2273b85` | ADR-0028 起票 Draft、 15th session 冒頭壁打ち 6 軸 (= HH sample / fixture 命名 / bit mapping / simultaneous trigger / dispatch 構造 / HH symbol) 確定 + §決定 11 件 + sub-sprint 分割 + scope-out 28+ 項目明示 + 「本質再確認」 callout + layering 図 literal 固定 + Annex A (= ADR-0027 §Annex A-1 / §Annex A-2 引用で `\h → hihset → 0xEB 0x08` literal 確認済 ground truth)。 user 着手判断で独立 α commit なし (= ADR-0027 引用 path で α 内容を ADR Draft に統合) |
| β | `7c363a6` | standalone_test.s pmdneo_rhythm_event_trigger 改修 (= bit 1 SD `jr` tail call → `call nz` subroutine 変更 + bit 3 HH 分岐追加 + `_rhythm_event_hh_trigger` 新規 sub-routine + adpcma_sample_hh 既存 symbol reuse、 +290/-18 行) + k-hr-only.mml fixture 新規 (= UTF-8+CRLF、 `hr = \h + r(rest)` 注記) + verify-step14-hh-trigger.sh 5 gate PASS、 既存 step12 + step13 BD/SD path regression 5 件 PASS (= entry addr 0x001126 完全同一不変) |
| γ | `78dfe74` | r-melody-hr-only.mml fixture 新規 (= melody L `\h` inline) + verify-step14-kr-hh-differential.sh 7 gate PASS (= K-HH vs R-HH byte-identical、 K-HH=R-HH=0x001126 entry + K-HH=R-HH=0x001193 hh_trigger) + verify-step14-bd-hh-differential.sh 6 gate PASS (= BD vs HH sample addr literal differ、 BD 0x00-0x03 / HH 0x07-0x09)、 driver 完全不変、 +541/-0 行 |
| δ | 本 commit | 完了統合 + ADR-0028 Accepted 移行 + ADR-0028 wording 精密化 (= 15th session γ user 指示 6 項目、 §決定 1/4/8 内 sub-routine addr 不変 wording 訂正 + §verify gate Gate 4 内 SD vs HH 推移的区別注記) + 全 23 script regression PASS (= 87 秒、 18:56:27-18:57:54) + audible 試聴 OK (= user judgement: K/R 同音 + BD/SD/HH 3 種区別可能 + FM 同居許容) + handoff doc 起票 + memory + MEMORY.md update |

### 「動いているものを壊さない」 規律遵守 (= ADR-0021-0027 で確立、 Step 14 で継続)

各 sub-sprint で driver source 改修を最小化し、 trivial verify (= 既存 path で false PASS) を段階分離で防いだ。

- ADR(+α 統合) Draft: driver / `.MN` format / PMDDotNET 完全不変 (= 純文書化 commit、 1026 行追加)
- β: driver standalone_test.s に dispatcher 改修 + `_rhythm_event_hh_trigger` 新規追加 (= 70 行追加程度)、 既存 BD path content (= 6 件 reg write) 完全不変、 既存 SD path content 完全不変 (= entry addr のみ dispatcher 改修副作用で shift)、 PMDDotNET / `.MN` format 完全不変
- γ: driver source 完全不変 (= fixture + verify script のみ、 541 行追加)
- δ: driver source 完全不変 (= regression + Accepted 移行 + handoff + memory + ADR wording 精密化のみ)

各段階の primary gate が trivial verify を弾く設計 (= memory `feedback_trivial_verify_detection_and_correction_commit` 整合):

- ADR(+α 統合) Draft gate: doc only、 既存 20 script regression PASS 維持 (= ADR-0027 完了状態継続)
- β gate: build PASS + pmdneo_rhythm_event_trigger entry addr 0x001126 不変 + `_rhythm_event_hh_trigger` symbol 存在 + K-HH fixture run PC trace marker hit + ADPCM-A L ch HH register write literal (= 5 reg + keyon mask、 HH_START_LSB=0x07 / HH_STOP_LSB=0x09 expected) + 既存 step12+step13 path regression 5 件 PASS
- γ gate: K-HH vs R-HH routine addr identical (= hook + hh_trigger) + K-HH vs R-HH HH register write sequence byte-identical (= 6 件) + K-HH vs R-HH keyon count identical + BD vs HH sample addr literal differ + BD vs HH MSB/vol|pan/keyon identical + 既存 step12+step13 path regression 5 件 PASS
- δ gate: 全 23 script regression PASS (= 87 秒、 driver 改修副作用なし literal 確認) + user 試聴 OK + ADR wording 精密化反映

## 全 23 script regression 結果 (= δ で serial 実行、 `feedback_verify_script_serial_execution` 整合)

実行時間: 18:56:27 → 18:57:54 (= 87 秒、 全 23 script PASS、 driver 改修副作用なし literal 確認)

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
| step 13 | `verify-step13-sd-trigger.sh` | ✅ PASS |
| step 13 | `verify-step13-kr-sd-differential.sh` | ✅ PASS |
| step 13 | `verify-step13-bd-sd-differential.sh` | ✅ PASS |
| step 14 | `verify-step14-hh-trigger.sh` | ✅ PASS (新規) |
| step 14 | `verify-step14-kr-hh-differential.sh` | ✅ PASS (新規) |
| step 14 | `verify-step14-bd-hh-differential.sh` | ✅ PASS (新規) |

23/23 PASS。 driver `pmdneo_rhythm_event_trigger` 改修 (= bit 3 HH 分岐追加 + bit 1 SD jr→call nz 変更) が他 step (= step 4-13) に副作用なし、 既存 L-Q ADPCM-A melody / multi-table proof / silent-bcef audio isolation / .PNE asset pipeline / runtime filename observation / sample_table_id resolver / mismatch silent / multi-table id=0x01 selection / K/R BD path / K/R SD path 全て不変保持を literal 確認。

## audio gate 結果 (= 15th session δ user 試聴)

user judgement (= 15th session δ):

- **K-BD と R-BD は同一** (= K と R で同音、 Step 12 audio gate 継続)
- **K-SD と R-SD は同一** (= K と R で同音、 Step 13 audio gate 継続)
- **K-HH と R-HH は同一** (= K と R で同音、 **Step 14 新規 audio gate**)
- **BD / SD / HH はそれぞれ別の音色として区別可能** (= 3 drum 種で聴感的区別可能、 sample addr literal differ literal を耳でも確認)
- **FM 同居許容** (= test01/test02 chord 進行と並走、 Step 12/13 audio gate 規律踏襲)
- **Step 14 audio gate = OK** 判定

audio gate と register trace gate の二段 verify で:

- register trace: byte-identical proof (= K-HH vs R-HH literal proof) + sample addr literal differ proof (= BD vs HH literal proof)
- audio gate: 聴感同音 proof (= user judgement で K-HH ≒ R-HH、 BD/SD/HH 3 種区別)

両 axis で Step 14 contract 達成。

## PMDNEO rhythm architecture layering (= Step 14 完了時点、 user 15th session γ 整理)

```
source syntax
  │ K part / melody part inline
  │ \b (BD) / \s (SD) / \h (HH)
  │ (= PMD V4.8s K/R compatibility syntax)
  ↓
normalize
  │ driver .MN direct parser
  │ 0xEB <bitmap> rhykey opcode
  │ (= PMDDotNET / .MN format 完全不変)
  ↓
shared dispatch  (= invariant primary)
  │ pmdneo_rhythm_event_trigger @ 0x001126
  │ (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH 6 fixture で完全同一 entry addr)
  ↓
drum kind mapping
  │ bit 0 → _rhythm_event_bd_trigger → adpcma_sample_bd
  │ bit 1 → _rhythm_event_sd_trigger → adpcma_sample_sd  (= sub-routine entry addr は dispatcher 改修で shift 可、 invariant 対象外)
  │ bit 3 → _rhythm_event_hh_trigger → adpcma_sample_hh  (= 既存 L-Q N ch symbol reuse)
  │ bit 2/4/5 → silent ignore (= future drum 種拡張で branch 追加、 dispatch entry addr 不変)
  ↓
ADPCM-A trigger  (= invariant secondary)
  │ L ch (ch 0、 暫定 scaffold)
  │ 6 件 register write (= reg 0x10/0x18/0x20/0x28/0x08/0x00、 sequence 不変、 sample addr のみ drum 種で literal differ)
  │ keyon mask 0x01
```

この layering が Step 12 → Step 13 → Step 14 で **drum kind mapping 軸のみ 1 段ずつ拡張**、 他 layer は完全不変。 future drum 種拡張 (= c/t/i) でも同 pattern (= drum kind mapping に 1 軸 branch 追加、 dispatch entry 不変、 register write sequence 不変) で実装予定。

## Step 15 候補 (= ADR-0028 §scope-out 未消化 + future sprint、 user γ レビュー軸)

1. **drum 種拡張 c/t/i** (= CYM bit 2 / TOM bit 4 / RIM bit 5、 dispatch path 不変で drum 種 → sample pointer mapping 1 軸ずつ拡張、 全 6 drum compatibility 完成)
2. **simultaneous trigger bitmap OR semantics literal proof** (= bitmap 0x03 / 0x09 / 0x0A / 0x0B fixture / verify、 PMDDotNET の bitmap OR 圧縮 emit を driver 側で literal 解釈する proof、 Step 14 で「観測上 harmful なし」 を踏まえ literal 仕様化)
3. **drum 種 → sample pointer mapping table 構造化** (= 4+ drum 段で lookup table refactor を再評価、 早すぎる抽象化を避けつつ拡張性確保、 full drum set = 6 drum 段到達後優先)
4. **table-driven dispatch refactor** (= dispatch path + sub-routine を 1 本に集約、 ADR-0028 §決定 4 / 軸 5 で future sprint scope-out)
5. **`.PNE` rhythm bank migration** (= driver-embedded fixture → `.PNE` 経由 id=0x02 bank、 generated rhythm sample directory、 rhythm-dedicated symbol 分離)
6. **rhythm channel concept formalization** (= ADR-0026 §決定 4 (c2)/(c3)/(c4) のいずれか採用、 channel allocation 最終仕様)
7. **複数 drum 同時打ち full proof** (= bitmap OR semantics + driver 側 timing 同時 trigger + audible 確認)
8. **OPNA native rhythm timing fidelity** (= ADR-0026 scope-out 追加項目、 Step 15+ で必要なら検討)
9. **K/R 制御 cmd 現役化** (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件、 OPNA rhythm pan / volume 周辺)
10. **selected pointer cache** (= A2/A3 動的化局面、 ADR-0024/0025/0026/0027/0028 で全 sprint scope-out 維持)
11. **mismatch silent flag micro-sprint** (= ADR-0024 / 0025 §scope-out 継続)
12. **D3 generated directory migration** (= asset pipeline 完成版へ)
13. **runtime `.PNE` parser / multi-`.PNE` switching / bank switching**
14. **PMDNEO.s + nullsound integration** (= legacy 系統との reunification)
15. **WebApp Phase 4** (= WAV import / 新規 sample 追加 UI)

Step 14 完了で「K/R drum kind expansion proof 2 段目」 path 成立、 Phase 3 driver の機能カバレッジは melody + multi-table + rhythm dispatch + drum kind 3 種まで完成。 「dispatch path は drum 種拡張で増やさない」 contract が Step 12 → Step 13 → Step 14 で **3 drum 段で literal 実装的に保証** され、 future drum 種拡張 (= c/t/i 3 種) でも同 pattern で簡潔追加可能な architecture が成立。

## 関連

- ADR-0028 (= 本 sprint Accepted)
- ADR-0027 (= Step 13 K/R drum kind expansion proof — s = SD、 本 sprint の前段、 §Annex A-1/A-2 引用で α 統合)
- ADR-0026 (= Step 12 K/R rhythm compatibility proof — b-only、 dispatch path 1 本化原理確立)
- ADR-0025 (= Step 11 multi-table id=0x01 proof、 HH sample 既存 reuse 経路の前提)
- ADR-0024 (= Step 10 sample_table_id selection consumption、 explicit if/jr 流儀)
- ADR-0019 (= Step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= Step 5 §決定 2 K/R legacy retained but inactive → Step 12 reconnected → Step 13 b+s → Step 14 b+s+h)
- memory `project-pmdneo-step14-complete` (= 本 sprint 完了 memory)
- memory `project-pmdneo-step13-complete` (= 前段 sprint 完了 memory)
- memory `project-pmd-rim-drum-char-correction` (= ADR-0027 α RIM 訂正 finding、 bit 5 silent ignore 確認に reused)
- memory `project-pmdneo-adpcma-subsystem-boundary` (= YM2610(B) ADPCM-A subsystem 専用 runtime-managed architecture、 本 sprint で 3 drum 段に拡張)
- memory `feedback-pmddotnet-mml-authoring-rules` (= CRLF authoring requirement、 15th session β/γ で fixture 作成時遵守)
