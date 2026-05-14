# ADR-0029 step 15 δ completion handoff: K/R drum kind expansion proof — c = CYM sprint 完了統合

- 関連 ADR: [ADR-0029](../../adr/0029-pmdneo-step15-kr-drum-kind-expansion-cym.md) **Accepted** (= 2026-05-14 16th session δ 完了統合で移行)
- sub-sprint: δ (= 4 commit chain の 4 段目 = 最終、 完了統合 + Accepted 移行、 注: ADR-0028 同型 5 段表 (= ADR/α/β/γ/δ) のうち α は user 着手判断で ADR Draft commit に統合 = 独立 α commit なし)
- commit: 本 commit
- 前段: γ commit `4c4c55c` (= R-CYM fixture + K-CYM vs R-CYM differential + BD vs CYM differential 2 verify 新規 + 13 gate 全 PASS)
- 次段: Step 16 候補 (= 本 handoff §Step 16 候補参照、 user 16th session レビューで drum 種拡張 t/i / table-driven dispatch refactor / simultaneous trigger bitmap OR semantics / `.PNE` rhythm bank migration 等を Step 16 候補として温存)

## Step 15 sprint の本質 (= Accepted 後の literal 固定、 user δ handoff 記載要件)

**Step 15 は K/R full compatibility ではなく K/R drum kind expansion proof stage の 3 段目**。 future contributor が「K/R drum 種完成版」 と誤解せず、 「K/R semantics の drum 種が b+s+h → b+s+c+h に 1 軸拡張した proof」 として扱えるよう本 handoff で literal 明記する。

### Step 14 → Step 15 の関係 (= user δ handoff 必須記載)

```
Step 12 (= ADR-0026 Accepted): b only proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 不変)
Step 13 (= ADR-0027 Accepted): b + s expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 3 drum 段下不変)
Step 14 (= ADR-0028 Accepted): b + s + h expansion proof
  ↓ (= drum 種 1 軸拡張、 dispatch path 4 drum 段下不変)
Step 15 (= ADR-0029 Accepted、 本 commit): b + s + c + h expansion proof
```

Step 15 は Step 14 の **drum kind 軸 1 段拡張** であり、 dispatch path / routine entry / observability marker / K-R 共通 hook / driver-embedded fixture proof 規律 全て不変。 「dispatch path は drum 種拡張で増やさない」 (= ADR-0026 §決定 6/8 + ADR-0027 §決定 8 + ADR-0028 §決定 8 + ADR-0029 §決定 8) が **4 drum 段下で literal 実装的に保証された** 段階。

### invariant の本質再確認 (= ADR-0028 §決定 1/4/8 wording 踏襲、 Step 15 で 4 drum 段に拡張)

**invariant の本質 = shared dispatch entry 不変 + register write sequence 不変** (= sub-routine entry addr 不変ではない):

| 軸 | 不変保証 | 観測値 (Step 15 完了時点) |
|---|---|---|
| **primary**: shared dispatch entry | `pmdneo_rhythm_event_trigger` entry addr 完全同一 | Step 12/13/14/15 = 0x001126 不変 (= 8 fixture 全部) |
| **secondary**: register write sequence | 各 drum trigger sub-routine の 6 件 reg write の literal value 不変 | BD/SD/HH/CYM それぞれ sample addr のみ literal differ、 sequence 構造 + vol|pan + keyon mask 完全不変 |
| **NOT invariant**: internal sub-routine entry addr | dispatcher 改修で shift 可、 不変保証対象外 | `_rhythm_event_cym_trigger` @ 0x00119B 新規、 SD/HH trigger entry addr は Step 14 完了時点から再 shift observed (= dispatcher の bit 2 CYM 分岐挿入 + jr → jp 変更で bytecode 増加) |

verify script 側も sub-routine entry addr literal value を hard-code assert せず、 symbol 存在 + K=R addr identical で proof 成立する設計 (= ADR-0029 §verify gate Gate 2/3 + verify-step15-* 全 script 整合)。

### branch 流儀 wording 精密化 (= ADR-0029 で「explicit if/jr」 → 「explicit if/jr/jp」 に literal 拡張)

ADR-0024 から ADR-0028 まで「explicit if/jr」 と表記していた branch 流儀を、 ADR-0029 で「**explicit if/jr/jp**」 に精密化:

- distance に応じて `jr` (= 2 byte 相対 jump、 範囲 ±128 byte) または `jp` (= 3 byte 絶対 jump、 範囲制限なし) を選択する Z80 標準対応
- **explicit branch の精神** (= dispatch macro / jump table を使わない、 各 bit 分岐は個別 instruction で記述) は **完全維持**
- Step 15 β で `_rhythm_event_cym_trigger` sub-routine 挿入により dispatch path 末尾 `jr _rhythm_event_hh_trigger` が jr 範囲 ±128 byte 超過 → `jp _rhythm_event_hh_trigger` に 1 行変更 (= driver 改修 1 行のみ、 設計方針変更ではない)
- future drum 種拡張 (= Step 16 t / Step 17 i) でも同 pattern (= dispatch path 末尾 tail jp、 中間分岐は jr or call nz、 distance 適応で literal 選択)

### 達成したこと (= Step 15 で literal 成立)

| 項目 | 内容 |
|---|---|
| **K-CYM path (= K part `\c`)** | PMD V4.8s K part 内 `\c` → PMDDotNET emit `0xEB 0x04 0x80` (= rhykey CYM bitmap + part end、 mc.cs L9529 + L9697-9725 cymset + L9748 emit literal、 ADR-0028 §Annex A-1/A-2 で literal 確認済) → driver `rhythm_main_rhykey` → `pmdneo_rhythm_event_trigger` @ 0x001126 → bit 2 分岐 → `_rhythm_event_cym_trigger` @ 0x00119B → ADPCM-A L ch CYM register write (= reg 0x10 0x12 / 0x18 0x00 / 0x20 0x29 / 0x28 0x00 / 0x08 0xDF / 0x00 0x01) |
| **R-CYM path (= melody part inline `\c`)** | melody part (= L part 採用) 内 `\c` inline → PMDDotNET emit `0xEB 0x04` inline → driver `commandsp_rhykey` (= Step 12 既存) → 同 `pmdneo_rhythm_event_trigger` @ 0x001126 → 同 bit 2 分岐 → 同 `_rhythm_event_cym_trigger` @ 0x00119B → 同 ADPCM-A L ch CYM register write |
| **K-CYM と R-CYM の dispatch path 1 本化** | K part / melody part の 2 source path が runtime layer で同 routine entry (= 0x001126) + 同 CYM routine entry (= 0x00119B) に collapse、 同 CYM register write sequence が K-CYM build / R-CYM build で byte-identical (= 6 件)、 keyon count identical (= 1) |
| **BD vs CYM drum kind expansion** | bit 0 BD trigger / bit 1 SD trigger / bit 2 CYM trigger / bit 3 HH trigger が個別 if/jr/jp 分岐で literal 区別、 BD start LSB 0x00 ≠ CYM start LSB 0x12 + BD stop LSB 0x03 ≠ CYM stop LSB 0x29 (= register addr literal で観測可能、 silent 倒れではない)、 MSB / vol|pan / keyon mask は BD=CYM identical (= 同 L ch state) |
| **SD vs CYM / HH vs CYM 推移的区別 (= explicit gate scope-out)** | BD vs SD literal differ (= ADR-0027 §Gate 4 確立) + BD vs HH literal differ (= ADR-0028 §Gate 4 確立) + BD vs CYM literal differ (= 本 ADR §Gate 4 確立) → SD/HH/CYM 全 mutual pair は推移的に literal differ proof 成立 (= explicit gate 不要、 N-1 pair gate で N 軸 differential を推移的に確立可能、 future t/i 拡張も同 pattern) |
| **dispatch path 1 本化の 4 drum 段下維持** | `pmdneo_rhythm_event_trigger` entry addr @ 0x001126 が 8 fixture (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM) 全部で完全同一 (= ADR-0026 §決定 6 + ADR-0027 §決定 8 + ADR-0028 §決定 8 + ADR-0029 §決定 8 「dispatch path は drum 種拡張で増やさない」 が 4 drum 段で literal 達成) |
| **既存 `adpcma_sample_top` symbol reuse** | 既存 `adpcma_sample_top` (= L-Q architecture Q ch sample symbol、 ADR-0025 step 11 で embed 済) を rhythm proof 用に reuse、 新規 sample embed なし (= ADR-0029 §決定 3 / 軸 1 整合、 ADR-0027 SD + ADR-0028 HH = 既存再利用 pattern 踏襲)。 「**top**」 = sample provenance 名 (= asset 由来 `assets/sounds/adpcma/2608_TOP.adpcma`、 Q ch symbol) / 「**CYM**」 = PMD semantics 名 (= `\c`、 cymset、 bitmap bit 2) を wording 分離、 alias 新設なし (= driver 差分最小化) |
| **observability marker (= 不変継続)** | 独立 routine label `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable (= ADR-0026 §決定 8 / ADR-0027 §決定 9 / ADR-0028 §決定 9 / ADR-0029 §決定 9 整合、 memory marker byte なし、 SRAM layout 増設なし、 8 fixture 全部で同 0x001126 hit) |
| **既存 layering 不変保証** | PMDDotNET / `.MN` format / 既存 L-Q ADPCM-A melody architecture / multi-table proof / silent-bcef audio isolation / Step 12 K-BD path / Step 13 K-SD path / Step 14 K-HH path 全て不変、 26/26 script regression PASS |

### 達成していないこと (= scope-out 維持、 future scope)

**user δ handoff 記載要件 (= 16th session γ user 重視軸)**:

| 項目 | scope-out 維持理由 |
|---|---|
| **Step 15 は b + s + c + h only proof** (= bit 0 BD + bit 1 SD + bit 2 CYM + bit 3 HH accept) | t/i 残り 2 drum 種 (= TOM bit 4 / RIM bit 5、 `\r` は rest 専用、 PMDDotNET mc.cs rcomtbl `'i' → rimset` literal、 ADR-0028 §Annex A-1) は future sub-sprint、 dispatch path は不変で drum 種 → sample pointer mapping を 1 軸拡張のみ |
| **bit 4/5 ignore 維持** | driver は bit 0 + bit 1 + bit 2 + bit 3 のみ accept、 bit 4/5 (= TOM `\t` / RIM `\i`) は **silent ignore** (= ADR-0026 §決定 11 「未対応 cmd スルー」 思想踏襲、 ADR-0027 / ADR-0028 / ADR-0029 §決定 2 維持)。 future drum 種拡張時に bit 別 branch 追加で対応 |
| **simultaneous trigger (= bitmap 11 combo = BD+SD / BD+CYM / SD+CYM / BD+SD+CYM / BD+HH / SD+HH / BD+SD+HH / CYM+HH / BD+CYM+HH / SD+CYM+HH / BD+SD+CYM+HH) scope-out** | Step 15 fixture では emit せず (= ADR-0029 §決定 11 + 軸 4 維持)。 driver 側は arrive 時に対応 bit の trigger を連続 register write で対応 (= **観測上 harmful なし**)、 ただし「driver 動作可能性」 と「ADR で仕様として明示化」 は別軸 = ADR-0029 §決定 11 内「未定義」 literal 明記。 Step 16+ で bitmap OR semantics literal proof sprint 起票時に再評価 |
| **L ch allocation scaffold 維持** | ADR-0026 §決定 4 整合、 K/R rhythm event 受入 ch = ADPCM-A L ch (= ch 0) は **proof 用暫定 allocation**、 PMDNEO 恒久仕様ではない。 L-Q melody architecture は恒久的に縮小しない |
| **driver-embedded CYM sample proof 用** | 既存 `adpcma_sample_top` symbol を rhythm proof 用 reuse、 final ownership は `.PNE` rhythm bank migration future (= ADR-0026/0027/0028/0029 §決定 3 + 軸 1 future migration path 継続) |
| **drum 種 → sample pointer mapping table 構造化 scope-out** | 4 drum 段階は explicit branch + literal addr 参照、 full 6 drum (= b/s/c/h/t/i) 段到達後に lookup table refactor を再評価 (= ADR-0028 §決定 6 + ADR-0029 §決定 6 維持) |
| **full 6 drum K/R compatibility は未実装** | 各 drum 種別の volume / pan / 複数 drum 同時打ち / pattern loop / velocity は future sprint |
| **`.PNE` rhythm bank integration future** | ADR-0026/0027/0028/0029 §決定 3 維持、 future sprint で `sample_table_id` id=0x02 を rhythm bank として確保する migration path 候補温存 |

## verify gate 結果 (= ADR-0029 §verify gate 5 段全 PASS)

| Gate | 内容 | 結果 (Step 15 完了時点) |
|---|---|---|
| Gate 1 build | 全 26 script regression build PASS | ✅ δ 最終 run 全 26/26 PASS、 約 108 秒 |
| Gate 2 K-CYM trigger 単独 | `verify-step15-cym-trigger.sh` 5 gate PASS | ✅ pmdneo_rhythm_event_trigger @ 0x001126 + _rhythm_event_cym_trigger @ 0x00119B + CYM register literal 0x12/0x00/0x29/0x00 + vol|pan 0xDF + keyon mask 0x01 count=1 |
| Gate 3 K-CYM vs R-CYM | `verify-step15-kr-cym-differential.sh` 7 gate PASS | ✅ K-CYM=R-CYM=0x001126 entry identical + K-CYM=R-CYM=0x00119B cym_trigger identical + CYM register write sequence byte-identical (= 6 件) + keyon count identical |
| Gate 4 BD vs CYM | `verify-step15-bd-cym-differential.sh` 6 gate PASS | ✅ BD start/stop LSB (0x00/0x03) ≠ CYM start/stop LSB (0x12/0x29) literal differ + MSB/vol|pan/keyon identical + keyon count BD=CYM=1 identical、 SD vs CYM / HH vs CYM は推移的 proof 成立 |
| Gate 5 既存 regression 不破壊 | 既存 23 script + step15 新規 3 件 全 PASS 維持 | ✅ step12 K-BD path 2 件 + step13 K-SD path 3 件 + step14 K-HH path 3 件 + step5-11 系 14 件 + step4 1 件 全 PASS、 driver 改修副作用なし |

## audio gate 結果 (= user 試聴 OK 判定、 16th session δ)

- ✅ 8 wav (= K-BD / R-BD / K-SD / R-SD / K-HH / R-HH / K-CYM / R-CYM、 各 4 sec @ 48 kHz stereo PCM、 γ commit `4c4c55c` driver state で生成) を `scripts/listen-step15.sh` 経由で user 試聴 (= 8 wav + sleep 3 + 無限繰り返し + Ctrl+C 停止)
- ✅ user judgement: 「K-BD と R-BD は同一」 「K-SD と R-SD は同一」 「K-HH と R-HH は同一」 「**K-CYM と R-CYM は同一**」 = K/R で同音
- ✅ BD vs SD vs HH vs CYM で違う音色 (= 4 drum 種で聴感的に区別可能、 sample addr literal differ 整合)
- ✅ FM 同居許容 (= Step 12 / Step 13 / Step 14 audio gate 規律踏襲、 本 fixture では FM silent / V0 SSG / L 単独 sample なので干渉なし)

## transient finding (= 16th session γ regression run で 1 回 observed)

`verify-step7-b3-byte-identical.sh` が γ regression run の 1 回目で transient FAIL → 再 run + 単独 run で全 PASS resolved。 これは **verify B 系統 (= build / asset pipeline)** の I/O 一時 issue であり、 **driver runtime regression (= verify A 系統)** とは独立した現象。

詳細 + 切り分け方針 + 同型 future fail 観測時の解釈 reference は memory [`project-step7-b3-transient-fail-finding.md`](#)、 verify 体系 2 系統整理は memory [`project-pmdneo-verify-two-subsystems.md`](#) 参照。

## Step 16 候補 (= ADR-0029 §scope-out 未消化 + future sprint)

1. **drum 種拡張 t/i (= TOM / RIM)** (= 推奨、 dispatch path 不変で 1 軸ずつ拡張、 full 6 drum compatibility 完成、 同 pattern 踏襲、 Step 15 と同 4 commit chain 想定)
2. **table-driven dispatch refactor** (= full drum set = 6 drum 段到達後の lookup table refactor 再評価、 ADR-0028/0029 §決定 6 維持、 explicit if/jr/jp の延長として再評価)
3. **simultaneous trigger bitmap OR semantics literal proof** (= bitmap 0x03 等 fixture / verify、 4 drum 段で 11 combo、 future = 6 drum 段で 57 combo)
4. **`.PNE` rhythm bank migration** (= driver-embedded fixture → `.PNE` 経由 id=0x02 bank、 ADR-0021/0022/0023/0024/0025 layering 継続)
5. **rhythm channel concept formalization** (= ADR-0026 §決定 4 channel allocation 最終仕様)
6. **複数 drum 同時打ち full proof** (= bitmap OR + driver 側 timing 同時 trigger + audible)
7. **OPNA native rhythm timing fidelity** (= ADR-0026 §scope-out 維持項目)
8. **K/R 制御 cmd 現役化** (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件、 silent fallback 解除)

## 関連

- ADR-0029 (= 本 sprint Accepted)
- ADR-0028 (= Step 14 K/R drum kind expansion proof — h = HH、 本 sprint の前段、 §Annex A-1/A-2 引用で α 統合)
- ADR-0027 (= Step 13 K/R drum kind expansion proof — s = SD、 N-1 pair gate 推移的 proof pattern 確立)
- ADR-0026 (= Step 12 K/R rhythm compatibility proof — b-only、 dispatch path 1 本化原理確立)
- ADR-0025 (= Step 11 multi-table id=0x01 proof、 TOP sample 既存 reuse 経路の前提)
- ADR-0019 (= Step 5 §決定 3 sample addr build-time embed)
- ADR-0016 (= Step 5 §決定 2 K/R legacy retained but inactive → Step 12 reconnected → Step 13 b+s → Step 14 b+s+h → 本 Step 15 b+s+c+h)
- memory `project-pmdneo-step15-complete` (= 本 sprint 完了統合 memory)
- memory `project-pmdneo-verify-two-subsystems` (= verify A/B 系統整理、 本 sprint γ で確立)
- memory `project-step7-b3-transient-fail-finding` (= verify B 系統 transient I/O issue finding、 本 sprint γ で 1 回 observed)
