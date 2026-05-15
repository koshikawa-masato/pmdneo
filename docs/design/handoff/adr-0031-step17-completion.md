# ADR-0031 step 17 δ completion handoff: K/R drum kind expansion proof — i = RIM sprint 完了統合 = **full 6 drum completion milestone**

- 関連 ADR: [ADR-0031](../../adr/0031-pmdneo-step17-kr-drum-kind-expansion-rim.md) **Accepted** (= 2026-05-15 19th session δ 完了統合で移行 = **full 6 drum completion milestone 確定**)
- sub-sprint: δ (= 4 commit chain の 4 段目 = 最終、 完了統合 + Accepted 移行、 注: ADR-0030 同型 4 段表 (= ADR/β/γ/δ) のうち α は user 着手判断で ADR Draft commit に統合 = 独立 α commit なしで β 進行)
- commit: 本 commit
- 前段: γ commit `be4b919` (= R-RIM fixture + K-RIM vs R-RIM byte-identical + BD vs RIM differential + TOM vs RIM differential 4 verify 新規 + 24 gate 全 PASS)
- 次段: Step 18 候補 (= 本 handoff §Step 18 候補参照、 user レビューで simultaneous trigger bitmap OR semantics / table-driven dispatch refactor / `.PNE` rhythm bank migration / 制御 cmd 現役化 等を Step 18 候補として温存、 **drum 種拡張軸 sprint chain (= Step 12-17) は完了**)

## Step 17 sprint の本質 (= Accepted 後の literal 固定、 **full 6 drum completion milestone**、 user δ handoff 記載要件)

**Step 17 は K/R drum kind expansion proof stage の 5 段目 = 最終段 = full 6 drum completion**。 PMD V4.8s rcomtbl で定義された全 6 drum 種 (= b/s/c/h/t/i = BD/SD/CYM/HH/TOM/RIM) が PMDNEO で audible 化、 Step 12-17 6-step drum 種漸進拡張 sprint chain の **milestone 完成**。 future contributor が「PMDNEO の drum 種拡張軸」 を理解する起点としても機能する。

```text
BD / SD / CYM / HH / TOM / RIM = full PMD rhythm drum set
```

drum 種拡張軸は本 ADR で **完了** (= 残り drum 種なし)、 future sprint は simultaneous trigger semantics / table-driven refactor / `.PNE` rhythm bank migration 等の **別軸** へ移行。

### Step 12 → Step 17 sprint chain の完成 (= user δ handoff 必須記載)

```
Step 12 (= ADR-0026 Accepted): b only proof (= dispatch path 1 本化原理確立)
  ↓ (= drum 種 1 軸拡張、 dispatch path 不変)
Step 13 (= ADR-0027 Accepted): b + s expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 3 drum 段下不変)
Step 14 (= ADR-0028 Accepted): b + s + h expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 4 drum 段下不変)
Step 15 (= ADR-0029 Accepted): b + s + c + h expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 5 drum 段下不変)
Step 16 (= ADR-0030 Accepted): b + s + c + h + t expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 6 drum 段下不変)
Step 17 (= ADR-0031 Accepted、 本 commit): b + s + c + h + t + i expansion proof = **full 6 drum completion**
```

Step 17 は Step 16 の **drum kind 軸 1 段拡張** であり、 dispatch path / routine entry / observability marker / K-R 共通 hook / driver-embedded fixture proof 規律 全て不変。 「dispatch path は drum 種拡張で増やさない」 (= ADR-0026 §決定 6/8 + ADR-0027 §決定 8 + ADR-0028 §決定 8 + ADR-0029 §決定 8 + ADR-0030 §決定 8 + ADR-0031 §決定 8) が **6 drum 段 = full PMD drum set で literal 実装的に保証された** 段階 = **drum 種拡張軸 sprint chain の完成 milestone**。

### invariant の本質再確認 (= ADR-0028/0029/0030 §決定 1/4/8 wording 踏襲、 Step 17 で full 6 drum に拡張)

**invariant の本質 = shared dispatch entry 不変 + register write sequence 不変** (= sub-routine entry addr 不変ではない):

| 軸 | 不変保証 | 観測値 (Step 17 完了時点 = full 6 drum completion) |
|---|---|---|
| **primary**: shared dispatch entry | `pmdneo_rhythm_event_trigger` entry addr 完全同一 | Step 12/13/14/15/16/17 = 0x001126 不変 (= **12 fixture 全部** = K-BD/R-BD/K-SD/R-SD/K-HH/R-HH/K-CYM/R-CYM/K-TOM/R-TOM/K-RIM/R-RIM) |
| **secondary**: register write sequence | 各 drum trigger sub-routine の 6 件 reg write の literal value 不変 | BD/SD/HH/CYM/TOM/RIM それぞれ sample addr のみ literal differ、 sequence 構造 + vol|pan + keyon mask 完全不変 (= **full 6 drum 全て同 sequence 構造**) |
| **NOT invariant**: internal sub-routine entry addr | dispatcher 改修で shift 可、 不変保証対象外 | `_rhythm_event_rim_trigger` @ 0x001230 新規、 TOM trigger entry addr は Step 16 完了時点から再 shift observed (= dispatcher の bit 4 TOM tail-call → call nz pattern 戻し + bit 5 RIM 新規 tail-call で bytecode 増加) |

verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0031 §verify gate Gate 2/3 + verify-step17-* 全 script 整合)。

### tail-call invariant の維持 (= ADR-0031 §決定 4 「最後の active bit = tail-call」 invariant = **full 6 drum で最終移動**)

Step 16 で `_rhythm_event_tom_trigger` を末尾 tail-call (= `jp _rhythm_event_tom_trigger`) としていた構造を、 Step 17 で `_rhythm_event_rim_trigger` に **移動**:

- Step 16 まで: bit 4 TOM = ret z + jp _rhythm_event_tom_trigger (= 末尾 tail-call)
- Step 17: bit 4 TOM = call nz, pop af (= 中間 call nz pattern に戻し) / bit 5 RIM = ret z + jp _rhythm_event_rim_trigger (= **new tail-call target = full 6 drum completion で最終的に固定**)
- **「最後の active bit = tail-call」 invariant** は維持 (= 単に bit 4 → bit 5 に移動しただけで、 「最後の active bit が tail-call である」 性質は不変)
- tail-call invariant 移動規律: Step 14 → 15 → 16 → 17 で 3 回連続成立 (= bit 3 HH → bit 4 TOM → bit 5 RIM)
- **drum 種拡張軸完了**: bit 6-7 = reserved (= PMD bitmap 範囲外、 silent ignore) で future 移動先なし、 tail-call invariant は本 ADR で **bit 5 RIM に最終固定**

### branch 流儀 (= ADR-0029 で「explicit if/jr/jp」 として精密化、 Step 17 でも同 流儀踏襲)

- distance に応じて `jr` (= 2 byte 相対 jump、 範囲 ±128 byte) または `jp` (= 3 byte 絶対 jump、 範囲制限なし) を選択する Z80 標準対応
- **explicit branch の精神** (= dispatch macro / jump table を使わない、 各 bit 分岐は個別 instruction で記述) は **完全維持**
- Step 17 β で `_rhythm_event_rim_trigger` sub-routine 新規挿入により dispatch path 末尾 tail jp の target が `_rhythm_event_tom_trigger` → `_rhythm_event_rim_trigger` に切替 (= driver 改修 + bit 4 TOM を call nz pattern に戻し)
- future Step 18 候補 (= table-driven dispatch refactor) で explicit branch 流儀の再評価可能 (= full 6 drum 段到達後の判断材料が揃ったため)

### 達成したこと (= Step 17 で literal 成立 = full 6 drum completion)

| 項目 | 内容 |
|---|---|
| **K-RIM path (= K part `\i`)** | PMD V4.8s K part 内 `\i` → PMDDotNET emit `0xEB 0x20 0x80` (= rhykey RIM bitmap + part end、 mc.cs L9533 + L9721 rimset + L9748 emit literal、 ADR-0031 §Annex A-1/A-2 で literal 確認済) → driver `rhythm_main_rhykey` → `pmdneo_rhythm_event_trigger` @ 0x001126 → bit 5 分岐 → `_rhythm_event_rim_trigger` @ 0x001230 → ADPCM-A L ch RIM register write (= reg 0x10 0x0a / 0x18 0x00 / 0x20 0x0b / 0x28 0x00 / 0x08 0xDF / 0x00 0x01) |
| **R-RIM path (= melody part inline `\i`)** | melody part (= L part 採用) 内 `\i` inline → PMDDotNET emit `0xEB 0x20` inline → driver `commandsp_rhykey` (= Step 12 既存) → 同 `pmdneo_rhythm_event_trigger` @ 0x001126 → 同 bit 5 分岐 → 同 `_rhythm_event_rim_trigger` @ 0x001230 → 同 ADPCM-A L ch RIM register write |
| **K-RIM と R-RIM の dispatch path 1 本化** | K part / melody part の 2 source path が runtime layer で同 routine entry (= 0x001126) + 同 RIM routine entry (= 0x001230) に collapse、 同 RIM register write sequence が K-RIM build / R-RIM build で byte-identical (= 6 件)、 keyon count identical (= 1) |
| **BD vs RIM drum kind expansion** | bit 0 BD trigger / bit 1 SD trigger / bit 2 CYM trigger / bit 3 HH trigger / bit 4 TOM trigger / bit 5 RIM trigger が個別 if/jr/jp 分岐で literal 区別、 BD start LSB 0x00 ≠ RIM start LSB 0x0A + BD stop LSB 0x03 ≠ RIM stop LSB 0x0B (= register addr literal で観測可能、 silent 倒れではない)、 MSB / vol|pan / keyon mask は BD=RIM identical (= 同 L ch state) |
| **TOM vs RIM drum kind expansion (= Step 17 explicit gate 新規追加)** | bit 4 TOM trigger / bit 5 RIM trigger の前後関係 + tail-call invariant 移動下で literal 区別、 TOM start LSB 0x0C ≠ RIM start LSB 0x0A + TOM stop LSB 0x11 ≠ RIM stop LSB 0x0B (= Step 16 新参 TOM と Step 17 新参 RIM の前後関係 explicit proof、 dispatch path 全体 consistent literal verify) |
| **SD vs RIM / CYM vs RIM / HH vs RIM 推移的区別 (= explicit gate scope-out)** | BD vs SD literal differ (= ADR-0027 §Gate 4 確立) + BD vs HH literal differ (= ADR-0028 §Gate 4 確立) + BD vs CYM literal differ (= ADR-0029 §Gate 4 確立) + BD vs TOM literal differ (= ADR-0030 §Gate 4 確立) + BD vs RIM literal differ (= 本 ADR §Gate 5 確立) + TOM vs RIM literal differ (= 本 ADR §Gate 6 確立) → SD/HH/CYM/TOM/RIM 全 mutual pair は推移的に literal differ proof 成立 (= explicit gate 不要、 N-1 pair gate で N 軸 differential を推移的に確立) |
| **dispatch path 1 本化の 6 drum 段下維持 = full 6 drum completion** | `pmdneo_rhythm_event_trigger` entry addr @ 0x001126 が **12 fixture** (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM / K-TOM / R-TOM / K-RIM / R-RIM) 全部で完全同一 (= ADR-0026 §決定 6 + ADR-0027 §決定 8 + ADR-0028 §決定 8 + ADR-0029 §決定 8 + ADR-0030 §決定 8 + ADR-0031 §決定 8 「dispatch path は drum 種拡張で増やさない」 が **6 drum 段 = full PMD drum set で literal 達成** = **drum 種拡張軸 sprint chain の完成 milestone**) |
| **既存 `adpcma_sample_rim` symbol reuse** | 既存 `adpcma_sample_rim` (= L-Q architecture P ch sample symbol、 ADR-0025 step 11 で embed 済) を rhythm proof 用に reuse、 新規 sample embed なし (= ADR-0031 §決定 3 / 軸 1 整合、 ADR-0027 SD + ADR-0028 HH + ADR-0029 CYM + ADR-0030 TOM = 既存再利用 pattern 踏襲)。 「**rim**」 = sample provenance 名 (= asset 由来 `assets/sounds/adpcma/2608_RIM.adpcma`、 P ch symbol) + PMD semantics 名 (= `\i`、 rimset、 bitmap bit 5) **完全一致** (= ADR-0030 「tom」 = TOM 完全一致 pattern 踏襲)、 PMDDotNET 内部名 `rimset` も RIM semantics と実質一致 (= ADR-0030 `tamset` (= TAM legacy naming) のような wording 分離なし) + PMDNEO 側 wording も **RIM 統一** (= ADR-0031 §決定 3 「用語対応表」 + §Annex A-1 literal) |
| **`\i` = RIM trigger / `\r` = rest 専用** | mc.cs rcomtbl L9533 `'i' → rimset` ground truth (= ADR-0027 §Annex A-1 / memory `project_pmd_rim_drum_char_correction` literal 整合)、 fixture 命名 `ir` = `\i` + `r`(rest) pattern (= 既存 `br` / `sr` / `cr` / `hr` / `tr` pattern 同一規律、 「RIM」 略ではない)、 `\r = RIM` は **誤り** (= future contributor 向け literal 注記) |
| **observability marker (= 不変継続)** | 独立 routine label `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 / ADR-0030 §決定 9 / ADR-0031 §決定 9 整合、 memory marker byte なし、 SRAM layout 増設なし、 **12 fixture 全部で同 0x001126 hit**) |
| **既存 layering 不変保証** | PMDDotNET / `.MN` format / 既存 L-Q ADPCM-A melody architecture / multi-table proof / silent-bcef audio isolation / Step 12 K-BD path / Step 13 K-SD path / Step 14 K-HH path / Step 15 K-CYM path / Step 16 K-TOM path 全て不変、 34/34 script regression PASS |

### 達成していないこと (= scope-out 維持、 future scope = drum 種拡張軸以外の sprint へ移行)

**user δ handoff 記載要件 (= 18th session γ user 重視軸)**:

| 項目 | scope-out 維持理由 |
|---|---|
| **Step 17 は b + s + c + h + t + i full proof = drum 種拡張軸の最終段** (= bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH + bit 4 TOM + bit 5 RIM accept = full 6 drum) | **drum 種拡張軸は本 ADR で完了** (= 残り drum 種なし、 future drum 種拡張は発生しない)、 future sprint は別軸 (= simultaneous trigger semantics / table-driven refactor / `.PNE` rhythm bank migration / 制御 cmd 現役化) へ移行 |
| **bit 6-7 ignore 維持** | driver は bit 0-5 のみ accept、 bit 6-7 は **silent ignore** (= PMD bitmap 範囲外、 PMDDotNET note byte 識別 flag 等、 ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲、 ADR-0027/0028/0029/0030/0031 §決定 2 維持) |
| **simultaneous trigger (= bitmap 57 combo = RIM 込み 0x21-0x3F + Step 16 までの 31 combo + 全 6 drum simultaneous 0x3F) scope-out** | Step 17 fixture では emit せず (= ADR-0031 §決定 11 + 軸 4 維持)。 driver 側は arrive 時に対応 bit の trigger を連続 register write で対応 (= **観測上 harmful なし**)、 ただし「driver 動作可能性」 と「ADR で仕様として明示化」 は別軸 = ADR-0031 §決定 11 内「未定義」 literal 明記。 **Step 18 候補 = simultaneous trigger semantics proof sprint = full 6 drum completion 後の最有力 candidate** |
| **L ch allocation scaffold 維持** | ADR-0026 §決定 4 整合、 K/R rhythm event 受入 ch = ADPCM-A L ch (= ch 0) は **proof 用暫定 allocation**、 PMDNEO 恒久仕様ではない。 L-Q melody architecture は恒久的に縮小しない |
| **driver-embedded RIM sample proof 用** | 既存 `adpcma_sample_rim` symbol を rhythm proof 用 reuse、 final ownership は `.PNE` rhythm bank migration future (= ADR-0026/0027/0028/0029/0030/0031 §決定 3 + 軸 1 future migration path 継続) |
| **drum 種 → sample pointer mapping table 構造化 scope-out → Step 18+ candidate** | full 6 drum (= b/s/c/h/t/i) 段到達後 = 本 ADR Accepted 後の lookup table refactor 再評価が **可能** = ADR-0028/0029/0030 §決定 6 + ADR-0031 §決定 6 整合、 explicit if/jr/jp の延長として再評価。 **Step 18 候補 = table-driven dispatch refactor = full 6 drum completion 後の最有力 candidate** |
| **full 6 drum × K/R volume / pan / 複数 drum 同時打ち / pattern loop / velocity は未実装** | 各 drum 種別の制御 cmd は future sprint。 6 drum 完成後の semantics expansion (= simultaneous trigger / 制御 cmd 現役化 / channel allocation 改定) で対応 |
| **`.PNE` rhythm bank integration future** | ADR-0026/0027/0028/0029/0030/0031 §決定 3 維持、 future sprint で `sample_table_id` id=0x02 を rhythm bank として確保する migration path 候補 = full 6 drum completion 後の最有力 future candidate |

## verify gate 結果 (= ADR-0031 §verify gate 7 段全 PASS)

| Gate | 内容 | 結果 (Step 17 完了時点 = full 6 drum completion) |
|---|---|---|
| Gate 1 build | 全 34 script regression build PASS | ✅ δ 最終 run 全 34/34 PASS、 128 秒 (= fresh state、 orphan MAME zombie 切り分け済、 19th session δ で再 run、 γ commit `be4b919` 時の 127 秒とほぼ同等で driver 完全不変の再現性高し) |
| Gate 2 K-RIM trigger 単独 | `verify-step17-k-rim-trigger.sh` 5 gate PASS | ✅ pmdneo_rhythm_event_trigger @ 0x001126 + _rhythm_event_rim_trigger @ 0x001230 + RIM register literal 0x0A/0x00/0x0B/0x00 + vol|pan 0xDF + keyon mask 0x01 count=1 |
| Gate 3 R-RIM trigger 単独 | `verify-step17-r-rim-trigger.sh` 5 gate PASS | ✅ K-RIM 同型 5 gate、 R 側 source path (= melody part inline `\i`) でも同 register write literal |
| Gate 4 K-RIM vs R-RIM byte-identical | `verify-step17-kr-rim-byte-identical.sh` 7 gate PASS | ✅ K-RIM=R-RIM=0x001126 entry identical + K-RIM=R-RIM=0x001230 rim_trigger identical + RIM register write sequence byte-identical (= 6 件) + keyon count identical |
| Gate 5 BD vs RIM | `verify-step17-bd-vs-rim-differential.sh` 6 gate PASS | ✅ BD start/stop LSB (0x00/0x03) ≠ RIM start/stop LSB (0x0A/0x0B) literal differ + MSB/vol|pan/keyon identical + keyon count BD=RIM=1 identical |
| Gate 6 TOM vs RIM | `verify-step17-tom-vs-rim-differential.sh` 6 gate PASS | ✅ TOM start/stop LSB (0x0C/0x11) ≠ RIM start/stop LSB (0x0A/0x0B) literal differ + MSB/vol|pan/keyon identical + keyon count TOM=RIM=1 identical = **Step 16 新参 TOM と Step 17 新参 RIM の前後関係 + tail-call invariant 移動下で dispatch path 全体 consistent literal proof**、 SD vs RIM / CYM vs RIM / HH vs RIM は推移的 proof 成立 |
| Gate 7 既存 regression 不破壊 | 既存 29 script + step17 新規 5 件 全 PASS 維持 | ✅ step12 K-BD path 2 件 + step13 K-SD path 3 件 + step14 K-HH path 3 件 + step15 K-CYM path 3 件 + step16 K-TOM path 3 件 + step5-11 系 14 件 + step4 1 件 全 PASS、 driver 改修副作用なし |

## audio gate 結果 (= user 試聴 OK 判定、 19th session δ = **full 6 drum completion**)

- ✅ 12 wav (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM / K-TOM / R-TOM / K-RIM / R-RIM、 各 4 sec @ 48 kHz stereo PCM、 γ commit `be4b919` driver state で生成) を `scripts/listen-step17.sh` 経由で user 試聴 (= 12 wav + sleep 3 interval + 無限繰り返し + Ctrl+C 停止、 Step 15 / Step 16 listen-stepNN.sh convention 踏襲)
- ✅ user judgement: 「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「K-CYM と R-CYM は同一」 「K-TOM と R-TOM は同一」 「**K-RIM と R-RIM は同一**」 = **6 drum K/R で全 K-X ≒ R-X 同音 = full 6 drum completion 達成**
- ✅ BD vs SD vs HH vs CYM vs TOM vs RIM で違う音色 (= **6 drum 種で聴感的に区別可能 = full PMD drum set 達成**、 sample addr literal differ 整合)
- ✅ FM 同居許容 (= Step 12 / Step 13 / Step 14 / Step 15 / Step 16 audio gate 規律踏襲、 本 fixture では FM silent / V0 SSG / L 単独 sample なので干渉なし)

## Step 18 候補 (= ADR-0031 §scope-out 未消化 + future sprint = drum 種拡張軸以外へ移行)

**drum 種拡張軸は本 ADR で完了**。 future sprint は以下の **別軸** から選択:

1. **simultaneous trigger bitmap OR semantics literal proof** (= **推奨**、 bitmap 0x03 等 fixture / verify、 6 drum 段 = full PMD drum set で 57 combo、 PMDDotNET bitmap OR 圧縮 emit が ADR-0027/0028/0029/0030/0031 §Annex A-3 で確認済 → driver 側「ADR で仕様として明示化」 path を埋める full 6 drum completion 後の最有力 candidate)
2. **table-driven dispatch refactor** (= **推奨**、 6 drum 段到達後の lookup table refactor 再評価、 ADR-0028/0029/0030 §決定 6 + ADR-0031 §決定 6 整合、 explicit if/jr/jp の延長として再評価、 full 6 drum completion で判断材料が揃った段階)
3. **`.PNE` rhythm bank migration** (= driver-embedded fixture → `.PNE` 経由 id=0x02 bank、 ADR-0021/0022/0023/0024/0025 layering 継続、 final rhythm sample ownership 確定)
4. **rhythm channel concept formalization** (= ADR-0026 §決定 4 channel allocation 最終仕様、 L ch scaffold → 恒久 ch allocation)
5. **複数 drum 同時打ち full proof** (= bitmap OR + driver 側 timing 同時 trigger + audible、 §1 と組合せ)
6. **OPNA native rhythm timing fidelity** (= ADR-0026 §scope-out 維持項目)
7. **K/R 制御 cmd 現役化** (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件、 silent fallback 解除)
8. **PMDDotNET 改造 / `.MN` new bytecode** (= ADR-0026/0027/0028/0029/0030/0031 §決定 10 維持の scope-out 解除、 必要時のみ)

## 関連

- ADR-0031 (= 本 sprint Accepted = **full 6 drum completion milestone**)
- ADR-0030 (= Step 16 K/R drum kind expansion proof — t = TOM、 本 sprint の前段、 §Annex A-1/A-2 引用で α 統合 + 5 drum 段 → 6 drum 段拡張)
- ADR-0029 (= Step 15 K/R drum kind expansion proof — c = CYM、 wording 分離 pattern (= top vs CYM) 比較対象)
- ADR-0028 (= Step 14 K/R drum kind expansion proof — h = HH、 §Annex A-1 mc.cs rcomtbl literal 引用、 ADR-0031 §Annex A-1 で再引用)
- ADR-0027 (= Step 13 K/R drum kind expansion proof — s = SD、 N-1 pair gate 推移的 proof pattern 確立、 §Annex A-1 で `\i ≠ \r` literal 訂正済 = 本 sprint 命名軸の起点)
- ADR-0026 (= Step 12 K/R rhythm compatibility proof — b-only、 dispatch path 1 本化原理確立、 本 sprint で 6 drum 段に拡張完成)
- ADR-0025 (= Step 11 multi-table id=0x01 proof、 RIM sample 既存 reuse 経路の前提)
- ADR-0019 (= Step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= Step 5 §決定 2 K/R legacy retained but inactive → Step 12 reconnected → Step 13 b+s → Step 14 b+s+h → Step 15 b+s+c+h → Step 16 b+s+c+h+t → 本 Step 17 b+s+c+h+t+i = **full 6 drum completion**)
- memory `project-pmdneo-step17-complete` (= 本 sprint 完了統合 memory)
- memory `project-pmdneo-step16-complete` (= 直前 Step 16 TOM、 同型 pattern)
- memory `feedback-orphan-mame-zombie-audio-lock` (= 17th session 観測の transient hang root cause、 future contributor 向け切り分け方針)
- memory `project-pmdneo-verify-two-subsystems` (= verify A/B 系統整理、 Step 15 γ で確立)
- memory `project-pmd-rim-drum-char-correction` (= `\i` = RIM / `\r` = rest 専用 literal 訂正、 本 sprint 命名軸の起点)
