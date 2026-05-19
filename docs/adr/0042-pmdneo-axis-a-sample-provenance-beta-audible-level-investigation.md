# ADR-0042: 軸 A = sample provenance β sub-sprint 設計 = audible-level structural dependency investigation (= ADR-0033 §π15.14 Plan A reject 経緯踏襲、 normalize に逃げず .fxp 側 gain / mixer 構造で解く、 31st session β-1 で **採用案 = A mixer 構造 6 levers** literal 化済、 越川氏 directive literal 拘束)

- 状態: **Draft** (= 2026-05-18 31st session α 起票 + 2026-05-19 β-1 update commit で §決定 2 採用案 A mixer 構造 6 levers literal 化 + Codex layer 2 統合判断 session 019e3b50-... 147s response 引用 + 案 B reject 経緯記載、 ADR-0041 §決定 1-10 規律踏襲、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture / 既存 ADR / 既存 handoff doc 完全不変 doc-only ADR update、 Accepted 移行は β-2/β-3/β-4/γ/δ sub-sprint 完走 + 越川氏 audition gate accept + 主軸最終確認時)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa.)
- 関連 ADR:
  - ADR-0033 (= rhythm sample provenance / self-authored migration policy、 §π15.14 で v2 baseline + Plan A の peak -25 dBFS reject 経緯 + target -3 dBFS との 22 dB gap finding + 「normalize に逃げない、 .fxp 側 gain / mixer 構造で解く」 越川氏 directive literal、 本 ADR の母軸)
  - ADR-0041 (= 30th session 末起票 Claude Code 併走運用、 軸 A = ADR-0033 β sub-sprint 再開を sub-agent worker で進める 規律源、 §決定 1-10 + Annex A-4 軸 A 試行 prompt 概要 起点)
- 関連 memory:
  - `feedback_ai_engineering_gate_before_human_audition.md` (= engineering pre-condition gate と aesthetic acceptance gate の 2 layer 軸独立、 π15.14 audible-level engineering gate を aesthetic 判断前段に置く規律の根拠)
  - `feedback_minimize_user_engineering_touchpoints.md` (= 越川氏 hand-on engineering touchpoint 反復削減、 audible-level investigation も AI engineering 軸で機械検査化する規律源)
  - `feedback_metric_pass_is_not_aesthetic_pass.md` (= peak_dbfs / rms_dbfs は engineering 軸 only、 aesthetic accept ≠ level pass、 越川氏 audition gate is authoritative の wording 規律)
  - `feedback_relative_preference_vs_absolute_acceptance.md` (= pairwise preference と absolute acceptance の軸独立、 本 ADR では audition 結果は absolute accept / reject、 best 選別 wording 禁止)
  - `feedback_preference_learning_beats_metric_correlation.md` (= metric correlation gate ではなく preference learning が aesthetic 軸、 本 ADR は metric calibration ではなく structural dependency 解明軸 + audition primary gate)
  - `feedback_reproducible_workflow_first_aesthetic_second.md` (= workflow canonical 確立後の aesthetic refinement、 本 ADR β/γ/δ で BD 1 音先行 + 残り 5 音横展開 pattern 踏襲)
  - `feedback_doc_governance_two_systems.md` (= AI 協働用 ADR ground truth + 人間向け公開 docs 派生物、 本 ADR は AI 協働用 ADR 系)
  - `feedback_parallel_axis_orchestration.md` (= ADR-0041 規律 memory 化、 軸 A sub-agent 起動継承元)
  - `feedback_subagent_codex_loop_with_escalation.md` (= sub-agent ↔ Codex loop + escalation 6 種、 本 ADR α 内で design_judgment_needed escalate 規律源)
  - `feedback_explanation_style.md` (= return format 平易日本語 6 構造 + 説明 style 10 規律、 本 ADR 内 wording 規律と整合)

## 背景

### 1. ADR-0033 §π15.14 reject 経緯 (= literal)

ADR-0033 §決定 27 + § migration roadmap で確立した sub-sprint chain は、 23rd session で α 段階 (= forensic + scripts canonical 4 系統 + Makefile + Surge XT install) 完走、 24-25th session 周辺で BD 1 音先行 chain (= diagnostic baseline v1 → v2 + sensitivity sweep + authoring plan + transient lever design + minimal authoring candidate plan) を経て、 `BD_MINIMAL_AUTHORING_CANDIDATE_PLAN.md` § 9 (= π15.13) で **Plan A = leading verification plan** に literal 認定された。

その直後の π15.14 で Plan A を **初の aesthetic candidate phase artifact** として 4 件 scratch 生成し、 越川氏 audition gate を試みた:

- `.fxp` (= `2608_bd-plan-a.fxp`、 sha256 `e19241e3a103c11999b1b856078be78ec6be6ed4cab87861fbe26459e83ecd3b`)
- `.wav` (= `2608_bd-plan-a.wav`、 sha256 `ab90e1920848226a079a676f22b81caa506323b4969693c1c0d98b422078f261`)
- `2608_bd-plan-a.patch-spec.yaml`
- `2608_bd-plan-a.analysis-summary.yaml`

**越川氏 audition 結果 = 「音として認識できない」 で reject**。 4 件は repo 投入されず `/private/tmp/pmdneo-plan-a-rejected/` に退避済 (= future evidence retain、 削除ではない、 31st session 時点で 4 件存在確認済)。

### 2. reject 根本原因 (= literal、 BD_MINIMAL_AUTHORING_CANDIDATE_PLAN.md § 10.1 / § 10.2 引用)

| metric | target (= 2608_BD-roundtrip.wav) | v2 baseline | Plan A | gap (Plan A vs target) |
|---|---|---|---|---|
| peak_dbfs | **-3.00** | -25.00 | **-25.00** | **-22.00 dB** |
| rms_dbfs | -15.06 | -34.55 | -34.32 | **-19.26 dB** |
| clipping_count | 0 | 0 | 0 | OK |

- v2 baseline 自体が **peak -25 dBFS** で audible threshold 不足 state
- Plan A は `a_env1_release +3` のみ修正、 gain 軸 touch せず baseline level をそのまま継承
- Plan A tail feature は target metric equality 達成 (= tail_length_ms 168.6 → 0.0 完全一致 literal、 metric 軸 only の事実、 aesthetic 含意なし)、 **but audible-level gate failed**
- feature similarity / sensitivity success は **audition-ready level を意味しない** literal proof
- diagnostic baseline は audible amplitude を保証しない (= 「6/6 active 化」 ≠ 「audition 可能」)

### 3. 越川氏 directive (= literal、 §π15.14 § 10.4 引用)

- **Plan A is not promoted** (= leading verification plan のまま、 aesthetic candidate 昇格は撤回)
- **Plan A scratch audition failed due to inaudible level**
- **next task is audible-level structural dependency investigation**
- this is a **pre-audition engineering gate**, not aesthetic acceptance
- **「normalize による解決はしない」** = render 後処理 (= peak normalize / loudness normalize / wav 段階 gain 適用) **禁止**
- audible amplitude は `.fxp` 側の **gain / mixer 構造** として解く

### 4. root cause classification (= literal、 §π15.14 § 10.5 新カテゴリ)

| category | π15.x reference | 例 |
|---|---|---|
| unit conversion 問題 | π15.8 (v0.1.0) | a_env1_decay 280ms → log2 変換 |
| structural routing 問題 | π15.9 (v0.2.0) | a_env2 → filter envmod chain |
| **audible-level structural problem** | **π15.14 (新規)** | **v2 baseline peak -25 dBFS** |
| synth architecture 選択問題 | π15.11 (BD_TRANSIENT_LEVER_DESIGN) | waveshaper / noise / OSC param |

audible-level structural problem は synth architecture 選択ではなく **structural dependency 延長軸**。 sensitivity 軸 (= feature delta observation) と audible level 軸 (= 越川氏 audition gate 到達可能性) は別軸であり、 6/6 active 化が audition 可能性を意味しない literal proof。

### 5. 30th session 末 → 31st session 軸 A 着手位置

ADR-0041 §決定 1-10 + Annex A-4 で軸 A = ADR-0033 β sub-sprint 再開を sub-agent worker で進める方針を確立。 本 ADR (= ADR-0042) は軸 A α task = β sub-sprint 設計 ADR の起票。 設計判断複数案 (= mixer 構造案 vs .fxp gain 案) は越川氏 user 判断 scope、 sub-agent 内で 1 案決定せず escalate `design_judgment_needed` で 2 案を主軸経由 user に提示する。

## 決定

### 決定 1: β sub-sprint の中核軸 = audible-level structural dependency investigation (= 越川氏 directive literal)

β sub-sprint は **audible-level structural dependency investigation** を中核軸とする。 目的は次の 3 項目:

1. v2 diagnostic baseline (= peak -25 dBFS) → target -3 dBFS 程度の audible level に持ち上げる .fxp 側 structural change の literal 同定
2. **normalize / loudness normalize / wav 段階 gain 適用は全 sub-sprint で永久禁止** (= 越川氏 directive literal)
3. peak / RMS / clipping 軸の literal effect を engineering gate として通す (= aesthetic candidate phase 3 entry condition、 BD_AUTHORING_PLAN.md § 6.4 audible-level pre-audition gate 整合)

β sub-sprint 完了判定 = audible-level gate (= peak -6〜-3 dBFS + clipping 0 + rms_dbfs target ± 6 dB) を通る .fxp baseline candidate が **少なくとも 1 件**生成され、 越川氏 audition gate (= aesthetic acceptance、 final gate) に進める state に至ること。

### 決定 2: 採用案 = A mixer 構造 6 levers 確定 (= 31st session β-1 sub-sprint で literal 化、 案 B reject 経緯記載)

**採用案 = A mixer 構造 6 levers** (= 越川氏 user 判断委譲 → Codex layer 2 統合判断確定 → 主軸推奨と完全一致 → 本 ADR §決定 2 update commit で literal 化)。 案 B (= .fxp gain 単一軸) は **reject** (= 31st session β-1 で確定、 経緯下記)。

#### 採用案 A literal: mixer 構造 6 levers

**内容 literal**:

- 中核 levers = `a_level_o1` (= 0.0-1.0、 OSC1 mixer level、 BD body 主成分) + `a_level_o2` + `a_level_o3` + `a_level_noise` + `a_volume` (= Scene A master volume、 template default 0.89089900255203) + `volume` (= Master output volume in dB、 template default -9.68199920654297)
- structural narrative = 「OSC mixer + scene/master volume = ADPCM-A / 80s digital drum hardware の mixer routing 相当」 (= ADR-0033 §決定 24 synthetic drum identity aesthetic 軸 = OPNA-era digital drum identity 継承表現と整合)
- 期待効果:
  - mixer routing 軸での gain stage 設計 = 「どの OSC を何割で混ぜるか」 + 「scene 単位 master gain」 + 「output volume」 の **3 段 cascade** で peak / RMS / clipping を制御可能
  - level distribution が semantically 説明可能 (= OSC1=body 主、 OSC2=harmonic、 noise=click 等の musical narrative 維持)
  - 越川氏 directive 「mixer 構造として解く」 (= §π15.14 § 10.4 literal) と literal match 最大
  - 6 drum 横展開時 (= SD/CYM/HH/TOM/RIM) に drum 種ごとの mixer balance 調整可能性 = 汎化能力高
- known risk + β-2 で扱う mitigation:
  - lever 数が多い (= 6 件 candidate) ため sensitivity sweep の dimensionality が増える → β-2 戦略で **6 lever 総当たりではなく individual sweep → 最小 cascade verify** で dimensionality 抑制
  - mixer level と scene/master volume の cascade 効果が線形ではない可能性 (= waveshaper drive / filter envmod 経由で gain stage が non-linear、 23rd session π15.9 structural routing 軸の延長) → individual sweep で各軸の literal effect curve 観察 + cascade 時の non-linear interaction を最小 step で literal 記録
  - clipping 0 維持には mixer level 上げで波形 sum が clip しないか sweep で個別確認要 (= waveshaper drive 前段で sum overflow リスク) → **clipping gate (= clipping_count == 0)** を sweep 毎軸の hard gate として β-2 spike script に組み込み
- 退避 4 artifact 適用範囲:
  - `2608_bd-plan-a.patch-spec.yaml` = `a_env1_release +3` 修正のみ含む = mixer 構造案には適用しない (= Plan A は env release 軸、 本案は mixer 軸で独立)
  - `2608_bd-plan-a.fxp` + `.wav` + `.analysis-summary.yaml` = mixer 構造案 baseline render evidence ではないが、 **peak -25 dBFS の literal evidence** として再利用 (= β sub-sprint 内 sweep の比較 baseline data point として参照、 repo 投入なし `/private/tmp` retain 維持)

#### Codex layer 2 統合判断引用 (= 採用根拠 literal)

採用案確定は **Codex layer 2 統合判断** session `019e3b50-8f23-7803-af9e-903d6587f891` 147 秒 response で確定 (= 主軸推奨と完全一致、 ADR-0041 §決定 4-2 layer 2 統合判断機能実証完了)。 越川氏 directive 「Codex 確認後 GO」 委譲経路で 8 軸 trade-off を Codex に提示し、 layer 2 結論として次の根拠で案 A 採用が approve された:

- **案 A 優位 4 軸**: structural narrative 強度 (= 「mixer 構造として解く」 directive literal match 最大) / 越川氏 directive literal match / 6 drum 横展開時の汎化能力 / clipping risk が sweep gate で明示制御可能
- **案 B 優位 4 軸**: sweep dimensionality 低 (= 2 軸先行) / β sub-sprint 早期完了予想 / 退避 artifact (= patch-spec.yaml env release 修正) 直接適用可能 / 副次効果軸への影響最小予想
- **layer 2 結論**: 越川氏 directive 「mixer 構造として解く」 literal match を最重視で 案 A 採用、 案 A 唯一の弱点 (= sweep dimensionality) は β-2 戦略 (= individual sweep + 最小 cascade verify) で mitigation 可能

#### 案 B reject 経緯 literal (= 31st session β-1 確定)

案 B (= .fxp gain 単一軸 = a_volume + volume 2 軸先行) は次の根拠で **reject**:

- **π15.13 Plan A 認定根拠と同型 reject 構造**: ADR-0033 §π15.13 で Plan A = 「a_env1_release +3 = single-axis clean lever」 として認定したが、 π15.14 で audible-level gate 未通過により越川氏 audition で reject 済。 案 B も同じ「single-axis clean lever」 規律を gain 軸に再適用するもので、 audible-level gate を通過しても **「single-axis では mixer 構造として解いていない」** 越川氏 directive literal mismatch の risk を継承
- **6 drum 横展開汎化未保証**: SD/CYM/HH/TOM/RIM の drum 種ごと mixer balance が異なる可能性が高く、 単一 a_volume / volume で全 drum gate 通過する保証なし。 案 A の mixer balance 軸は drum 種ごと調整可能で、 BD 1 音先行 + 5 音横展開 pattern (= memory `feedback_reproducible_workflow_first_aesthetic_second` 踏襲) に対する汎化能力が高い
- **越川氏 directive literal match 弱**: 「.fxp 側 gain / mixer 構造」 のうち gain 側 literal match のみで、 「mixer 構造として解く」 wording に対する説明力低下。 single-axis なため structural narrative 強度が中
- **案 A 採用に伴い defer**: 案 B 自体は技術的に invalid ではないが、 案 A 採用 = β sub-sprint primary lever sequence 確定により case B は **β sub-sprint scope-out** + 将来 sub-sprint 候補として defer (= 案 A で audible-level gate 通過しても aesthetic candidate phase 3 で aesthetic gap が残る場合の 2 軸目候補等として retain、 ただし本 ADR 内 commit + spike は案 A 専用)

#### β-2 戦略 literal (= Codex 提案 = individual sweep + 最小 cascade verify + clipping gate)

採用案 A の sweep dimensionality 抑制策として、 β-2 sub-sprint で軸 A 専用 spike `scripts/audible-level-sweep-spike.py` を次の戦略で literal 化する:

- **6 lever 総当たりではない** = full 6 軸 grid sweep (= N^6 trial round = 過大 dimensionality) を **明示禁止**
- **individual sweep 先行** = 6 軸を 1 軸ずつ independent に sweep (= 1 軸 sweep × 6 = 6 trial round)、 各軸の literal effect curve (= peak_dbfs / rms_dbfs / clipping_count vs lever value) を観察
- **最小 cascade verify** = individual sweep で各軸の effective range 確定後、 cascade 効果検証は最小 step (= 案件依存、 例: o1+a_volume の 2 軸 cascade を 3-5 trial point で literal 記録) に limit。 cascade 時の non-linear interaction (= waveshaper drive / filter envmod 経由) を最小 effort で literal 観察
- **clipping gate (= hard gate)** = sweep 毎 trial で `clipping_count == 0` を hard gate として組み込み (= 越川氏 audition gate 到達前提、 ADR-0033 §π15.14 § 10.6 literal 踏襲)。 clipping 発生 trial は audible-level engineering gate FAIL として記録し candidate 化しない
- spike output format = peak_dbfs / rms_dbfs / clipping_count 3 軸 literal record + lever value literal record + render evidence `/private/tmp` 配下 retain (= repo 投入なし、 ADR-0033 §π15.14 § 10.6 literal 踏襲)

本戦略により案 A の唯一の弱点 (= sweep dimensionality 高) を 6 trial round + 最小 cascade verify で mitigation し、 β sub-sprint 完了時間を案 B 並 (= 1-2 round sweep) には届かないが reasonable round 数 (= 6 + 最小 cascade) に抑える。

#### β-1 sub-sprint 開始 literal

本 §決定 2 update commit が **β-1 sub-sprint** に相当 (= ADR-0041 §決定 4-2 layer 2 統合判断 + 主軸推奨と一致 + 採用案 literal 化 + β-2 戦略 literal)。 β-2 以降は本 ADR §後続 sprint 想定 table の literal に従い進行:

- **β-2 (= 次 sub-sprint)** = 軸 A 専用 spike `scripts/audible-level-sweep-spike.py` 新規作成 (= 案 A 採用 = 6 軸 individual sweep + 最小 cascade verify + clipping gate)
- **β-3** = layer 1 audible-level engineering gate PASS candidate 1 件生成 + analysis-summary.yaml literal + `/private/tmp` 配下 render evidence retain
- **β-4** = layer 2 越川氏 audition gate (= escalate `audit_gate`) → accept なら β 完了 → γ/δ chain へ進む

本 commit 範囲 = **doc-only ADR update 1 file** (= `docs/adr/0042-*.md` §決定 2 のみ書き換え)、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture / vendor / main / wip-ir-trunk / 他軸専用 file / dashboard / MEMORY.md / CLAUDE.md / 退避 4 artifact 全 touch なし (= ADR-0041 §決定 6 allowed write set 軸 A β-1 範囲遵守)。

### 決定 3: 退避 4 artifact (= `/private/tmp/pmdneo-plan-a-rejected/`) 評価規律

退避 4 artifact は **read-only evidence** として retain。 本 ADR β sub-sprint で次の方針:

| artifact | β sub-sprint 内扱い |
|---|---|
| `2608_bd-plan-a.fxp` | peak -25 dBFS reject 直前 state の literal binary evidence、 sweep baseline 比較用 sha256 確認のみ、 修正・上書き禁止 |
| `2608_bd-plan-a.wav` | peak -25 dBFS render 結果の literal acoustic evidence、 audible-level gate failure proof data point として参照、 修正・上書き・normalize 禁止 |
| `2608_bd-plan-a.patch-spec.yaml` | Plan A spec (= `a_env1_release +3` 修正含む) literal record、 案 B 採用時の env release 修正 retain 候補として参照、 修正・上書き禁止 |
| `2608_bd-plan-a.analysis-summary.yaml` | analysis-summary 出力 literal、 audible-level gate failure feature 軸記録、 修正・上書き禁止 |

repo 投入禁止 (= ADR-0033 §π15.14 § 10.3 literal 維持、 `/private/tmp` ephemeral retention)。 sub-agent / 主軸 ともに `/private/tmp/pmdneo-plan-a-rejected/` への write は全段階で禁止 (= read-only forensic evidence)。

### 決定 4: audition gate 規律 (= ADR-0033 §π15.14 § 10.4 + BD_AUTHORING_PLAN.md § 6.4 整合)

β sub-sprint 内で生成する .fxp candidate に対する audition gate は 2 layer 構造:

#### layer 1: audible-level engineering gate (= AI 機械検査軸、 越川氏 hand-on 不要)

- peak_dbfs ∈ [-6, -3] dBFS 範囲 (= target ~-3 dBFS の近傍)
- clipping_count == 0 (= 越川氏 audition gate 到達前提)
- rms_dbfs target ± 6 dB 範囲 (= -15.06 ± 6 = [-21.06, -9.06])
- 上記 3 軸全 PASS → layer 2 へ進む
- 1 軸でも FAIL → AI revision loop (= sub-agent 内自律 sweep / mixer balance 修正 / 再 render) で再評価
- engineering pass は aesthetic accept を **意味しない** (= memory `feedback_metric_pass_is_not_aesthetic_pass` literal 維持)

#### layer 2: 越川氏 audition gate (= aesthetic acceptance、 final gate、 sub-agent 内で判定しない)

- layer 1 PASS した candidate を 越川氏 audition に提示
- audition 結果 = accept / reject の literal record
- accept = β sub-sprint 完了、 γ/δ sub-sprint へ進む
- reject = reject 経緯 + 越川氏 audition comment literal を escalate `audit_gate` 経由で主軸経由 user 共有、 retry 軸 (= 別 candidate 生成 / mixer balance 再設計 / lever 追加候補) を user 判断仰ぎ
- sub-agent / 主軸 / Codex は audition 判定を行わない (= memory `feedback_ai_engineering_gate_before_human_audition` literal 維持、 永久 scope-out)

#### audition gate trigger 経路

- sub-agent が layer 1 PASS candidate を生成 → return `status: escalate` + `問題種別: audit_gate` + candidate path + analysis-summary literal を主軸に return
- 主軸が user に提示 → 越川氏 audition → accept / reject literal を主軸が dashboard escalation 履歴に記録 → sub-agent 再 task で次 sub-sprint へ進む or retry

### 決定 5: β sub-sprint scope-out (= literal)

β sub-sprint 内で **行わない**項目:

- normalize / loudness normalize / wav 段階 gain 適用 (= 越川氏 directive literal、 永久禁止)
- driver / runtime / .mn / .PNE / .NEO / WebApp / FM3 / IR touch (= ADR-0042 doc-only ADR、 既存 driver / runtime 完全不変)
- 既存 schema / 既存 spike / 既存 fixture touch (= ADR-0033 / ADR-0034 既存資産不変)。 ただし β-2 で新規作成する軸 A 専用 spike script `scripts/audible-level-sweep-spike.py` は **ADR-0041 §決定 6 allowed write set 軸 A 専用 spike** として例外的に許可 (= 新規軸専用 spike、 既存 spike touch ではない)
- 退避 4 artifact への write (= read-only forensic evidence)
- 既存 `2608_bd.fxp` / `2608_bd-diagnostic-v2.fxp` / 6 ADPCM-A sample / driver embed sample / 既存 .PNE / 既存 ROM への触接
- aesthetic optimizer / preference-learning / preference model 再開 (= ADR-0033 §決定 27 (10) ν 規律維持、 audition gate is authoritative)
- BD 以外の drum 種 (= SD/CYM/HH/TOM/RIM) audible-level investigation (= γ/δ sub-sprint scope、 BD 1 音先行 + 5 音横展開 pattern、 memory `feedback_reproducible_workflow_first_aesthetic_second` 踏襲)
- ADPCM-A encode (= 越川氏 audition accept 後の別 directive 起点、 ADR-0033 §決定 25 fxp2wav-surge external producer 経由 evidence chain は本 ADR scope-out)
- ROM ビルド / MAME 再生確認 (= ADR-0042 doc-only + spike level、 audio gate は越川氏 audition のみ、 driver runtime functional verify は別軸)
- vendor 配下 touch (= `vendor/PMDDotNET/` 等、 完全不可触)
- main branch 直接 push / `wip-pmddotnet-opnb-extension` 直接 commit / `wip-ir-trunk` touch (= ADR-0041 §決定 3 + §決定 10 規律踏襲)
- 他軸 (= 軸 C / 軸 F / 軸 B / 軸 D / 軸 E) 領域 touch (= ADR-0041 §決定 6 forbidden write set 規律踏襲)
- 既存 ADR / handoff doc 削除 / 短縮 / 人間向け文体書き換え (= memory `feedback_doc_governance_two_systems` 規律踏襲)
- MEMORY.md / CLAUDE.md 直接 edit (= 主軸経由のみ、 sub-agent から提案 return)

## 後続 sprint 想定 (= β/γ/δ chain literal)

軸 A α (= 本 ADR 起票 + design_judgment_needed escalate) 完了後、 越川氏 user 判断 (= 案 A / 案 B) を受けて β/γ/δ chain を確定:

| sprint | 内容 (= 案 A / 案 B 共通 + 案別差分) |
|---|---|
| **α (= ADR-0042 Draft 起票 b6dbc0d)** | ADR-0042 起票 (= 2 案併記 doc-only) + 退避 4 artifact 評価軸 + audition gate 規律 literal 確定 + escalate `design_judgment_needed` で主軸経由 user 上げ |
| **β-1 (= 本 update commit)** | **採用案 = A mixer 構造 6 levers** literal 確定 + ADR-0042 §決定 2 update commit (= Codex layer 2 session 019e3b50-... 147s 引用 + 案 B reject 経緯記載 + β-2 戦略 literal = individual sweep + 最小 cascade verify + clipping gate) |
| **β-2 (= 本 commit、 31st session 主軸 fallback)** | **完了** = `scripts/audible-level-sweep-spike.py` 新規作成 (= ~210 行 Python、 individual sweep 6 lever + clipping_count == 0 hard gate + dry-run mode default + --execute は環境依存 stub)、 layer 1 engineering gate literal (= peak ∈ [-6,-3] dBFS + clipping 0 + rms target ± 6 dB)、 退避 4 artifact read-only forensic 規律強調、 cascade verify stub、 syntax check + dry-run 動作確認 OK、 主軸 fallback 経由 (= sub-agent ae741b1c9a1e53f69 isolation worktree base ref 4 回連続 fail + guard 9 件機能ゼロ越境 → Codex layer 2 approve 即時 fallback、 軸 C 実装 sub-sprint α 同 pattern) |
| β-3 | layer 1 audible-level engineering gate PASS candidate 1 件生成 + analysis-summary literal + `/private/tmp` 配下 render evidence retain (= repo 投入なし) |
| β-4 | layer 2 越川氏 audition gate (= escalate `audit_gate`) → accept なら β 完了、 reject なら retry 軸 user 判断仰ぎ |
| γ | β 完了 candidate を BD authoring chain に統合 (= patch-spec.yaml literal 化 + 採用 .fxp evidence 化) + ADR-0033 §π15.14 § 10.6 next step literal 完了反映 + BD_AUTHORING_PLAN.md § 6.4 audible-level pre-audition gate 規律 update |
| δ | ADR-0042 Accepted 移行 + 軸 A β 1 軸 1 PR で本拠地 `wip-pmddotnet-opnb-extension` に merge (= ADR-0041 §決定 3 規律踏襲) + dashboard update + 5 drum 横展開 (= SD/CYM/HH/TOM/RIM) 軸 A γ 後継 sub-sprint 起票準備 |

β/γ/δ 各 sprint は ADR-0041 §決定 4 Codex 自律壁打ち + 3 重 zero-trust review + §決定 5 escalation 6 種規律踏襲。

## verify 計画

### A. ADR 整合性 (= 本 ADR Draft commit で達成)

- ADR-0033 §π15.14 reject 経緯 + § 10.4 越川氏 directive literal + § 10.5 root cause classification + § 10.6 next step と整合
- ADR-0041 §決定 1-10 + Annex A-4 軸 A 試行 prompt 概要 と整合
- CLAUDE.md §中核原則「記憶は AI に、 判断は自分が握る」 + §「設計書ファースト」 + §「動作確認義務」 と整合 (= 本 ADR は doc-only、 driver runtime 触接なし)
- memory `feedback_ai_engineering_gate_before_human_audition` + `feedback_minimize_user_engineering_touchpoints` + `feedback_metric_pass_is_not_aesthetic_pass` 規律継承
- memory `feedback_doc_governance_two_systems` 規律踏襲 (= AI 協働用 ADR ground truth)

### B. 既存 chain 不変 (= 本 ADR Draft commit で達成)

- driver / runtime / .mn / .PNE / .NEO / WebApp / FM3 / IR / schema / spike / fixture touch なし (= doc-only、 1 new file: `docs/adr/0042-*.md` のみ)
- vendor 配下 touch なし (= `vendor/PMDDotNET/` 等、 完全不可触)
- main branch 不変 (= 本 commit は wip-axis-a-sample-provenance branch 上、 main 保護維持)
- wip-pmddotnet-opnb-extension 直接 commit なし (= 軸 A wip- branch 経由、 ADR-0041 §決定 3 規律踏襲)
- wip-ir-trunk touch なし (= IR 軸隔離保管維持)
- 退避 4 artifact 不変 (= `/private/tmp/pmdneo-plan-a-rejected/` read-only retain、 本 ADR では sha256 / size literal 引用のみ)
- 既存 ADR (= 0033 / 0034 / 0041 等) / handoff doc 不変 (= 本 ADR は新規 ADR 0042 起票のみ)

### C. 後続 sub-sprint verify gate (= β/γ/δ で実施、 本 ADR では計画明示のみ)

- **β-2**: spike script (= `scripts/audible-level-sweep-spike.py`) deterministic exit 0 + spike output format consistency + Codex review 1 round approve
- **β-3**: layer 1 audible-level engineering gate PASS = peak_dbfs ∈ [-6, -3] + clipping 0 + rms_dbfs target ± 6 dB の 3 軸全 PASS + analysis-summary.yaml literal 整合
- **β-4**: layer 2 越川氏 audition gate accept literal 取得 + dashboard escalation 履歴に audit_gate 結果記録
- **γ**: BD authoring chain integration (= patch-spec.yaml literal 化 + ADR-0033 §π15.14 § 10.6 literal 反映 + BD_AUTHORING_PLAN.md § 6.4 update)
- **δ**: 軸 A β 1 軸 1 PR merged + dashboard 軸 A 状態 = Accepted + ADR-0042 Accepted 移行
- 全 verify gate (= β-2 + β-3 + β-4 + γ + δ) 完走後、 5 drum 横展開 (= SD/CYM/HH/TOM/RIM) を軸 A γ 後継 sub-sprint で起票準備

## Annex

### A-1. 31st session 軸 A α 着手経緯

| 時系列 | 内容 |
|---|---|
| 30th session 末 | ADR-0041 起票 + 軸 0 = orchestration setup chain γ で軸 A/C/F 予約 + sub-agent context 調査 完了 |
| 31st session 起点 | 軸 A α task = ADR-0042 起票 sub-agent 起動 + ADR-0041 §決定 1-10 規律遵守 |
| 軸 A sub-agent 内処理 | (1) 必読 context read = ADR-0041 / ADR-0033 §π15.14 / dashboard / 退避 4 artifact / 関連 memory、 (2) ADR-0042 draft 作成 = 2 案併記 doc-only、 (3) Codex review (= 軸 A 専用 session 新規取得)、 (4) 3 重 zero-trust 自己 verify、 (5) approve なら commit + push、 (6) escalate `design_judgment_needed` で越川氏 user 判断仰ぎ |

### A-2. 退避 4 artifact literal 詳細 (= read-only forensic evidence)

```
/private/tmp/pmdneo-plan-a-rejected/
├── 2608_bd-plan-a.fxp                          (31399 byte、 sha256 e19241e3a103c11999b1b856078be78ec6be6ed4cab87861fbe26459e83ecd3b)
├── 2608_bd-plan-a.wav                          (88244 byte = 44 RIFF header + 44100 samples × 2 byte、 sha256 ab90e1920848226a079a676f22b81caa506323b4969693c1c0d98b422078f261)
├── 2608_bd-plan-a.patch-spec.yaml              (7489 byte)
└── 2608_bd-plan-a.analysis-summary.yaml        (1826 byte)
```

patch-spec.yaml 主要 field (= literal):

- candidate_id: plan-a
- modification_summary: "a_env1_release +3 (= single-axis clean lever、 tail gap 解消)"
- baseline_fxp: assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp (= sha256 c03d32284d5d9108da905bcce6674b09a5912845cb5b46f0262ab2c069013517)
- modification.parameter: a_env1_release / baseline_value -4.321928 / delta 3.0 / new_value -1.321928 / human_intent.value 350.0 ms
- acceptance.human_audition_required: true / human_audition_result: null / aesthetic_acceptance: pending / accepted: false
- out_of_scope: ["existing 2608_bd.fxp overwrite", "existing 2608_BD.adpcma overwrite", "optimizer / preference-learning 再開", "accept / reject 判定 (= 越川氏 audition gate)", "best / accepted wording (= leading verification plan のまま、 audition 前)", "ADPCM-A encode", "Plan B / Plan C 並行作成", "v3 diagnostic baseline 作成"]

analysis-summary.yaml 主要 field (= literal):

- predicted_kind: BD / confidence 0.773905
- selected_profile: BD
- feature_snapshot.band_energy_ratio.sub: 0.813907 / low: 0.186093 / その他 0.0
- attack_ms: 10.522 / decay_1e_ms: 3.061 / tail_length_ms: 0.0
- transient_strength: 1.704 / rough_body_frequency_hz: 64.6 / pitch_contour_confidence: 0.665135

scope.metric_is_final_judge: false / optimizer_involved: false / human_audition_final_gate: true (= memory `feedback_ai_engineering_gate_before_human_audition` literal 整合)

### A-3. parameter-allowlist.yaml 既存 levers (= ADR-0033 §決定 21 確立、 案 A / 案 B 候補根拠)

`docs/design/rhythm-patches/synth/parameter-allowlist.yaml` で確立済の 56 件 allowlist のうち、 audible-level structural dependency 関連 levers:

| xml_element_name | template_default_value | patch_spec_field | notes |
|---|---|---|---|
| a_level_o1 | (= 0.0-1.0、 normalized scale) | oscillator_plan.osc1_mix_level | OSC1 mixer level (= drum body 主成分) |
| a_level_o2 | (= 0.0-1.0、 normalized scale) | oscillator_plan.osc2_mix_level | OSC2 mixer level |
| a_level_o3 | (= 0.0-1.0、 normalized scale) | oscillator_plan.osc3_mix_level | OSC3 mixer level |
| a_level_noise | (= 0.0-1.0、 normalized scale) | noise_transient_plan.level | Noise generator level |
| a_volume | 0.89089900255203 | oscillator_plan.scene_master_amplitude | Scene A master volume |
| volume | -9.68199920654297 | output_constraint.peak_target_dbfs | Master output volume (= dB) |
| a_noisecol | 0.00000000000000 | noise_transient_plan.color | Noise color (= -1.0 brown / 0.0 white / 1.0 pink/violet) |

案 A (= mixer 構造) levers = 6 件 (= a_level_o1/o2/o3/noise + a_volume + volume)。
案 B (= .fxp gain) levers = 2 件 (= a_volume + volume)。
全 levers は既存 allowlist 内 = β sub-sprint で新規 allowlist 拡張不要 (= ADR-0033 §決定 21 既存範囲内で完結可能、 schema 拡張なし)。

### A-4. 案 A / 案 B 退避 artifact 適用 sketch (= 31st session α 時点 user 判断材料 literal sketch、 β-1 update で §決定 2 採用案 = A 確定、 案 B sketch は reject 経緯 evidence として retain)

#### 案 A 採用時:

- β-2: `scripts/audible-level-sweep-spike.py` = 6 軸 individual sweep + cascade verify (= a_level_o1 0.0→1.0 sweep N 段 / a_level_o2 同 / ... / a_volume 0.0→1.0 sweep / volume -20→0 dB sweep / 各軸 peak / rms / clipping literal record)
- β-3: 退避 4 artifact = 比較 baseline data point (= peak -25 dBFS reject 直前 state) として参照、 mixer 構造 candidate (例 v3 baseline = a_level_o1 + a_volume 調整) との literal diff 観察
- β-4: 越川氏 audition = mixer 構造 candidate を audition (= 案 A 採用時の primary candidate)。 退避 Plan A wav は **optional reference playback only / Plan A 再昇格ではない / read-only playback** として並列参照可能 (= 越川氏判断で proactive に提示、 reject 済 artifact の再評価ではない、 candidate identity は新規 mixer 構造 candidate に純化)

#### 案 B 採用時:

- β-2: `scripts/audible-level-sweep-spike.py` = 2 軸先行 sweep (= a_volume 0.0→1.0 sweep N 段 / volume -20→0 dB sweep / 各軸 peak / rms / clipping literal record)
- β-3: 退避 `2608_bd-plan-a.patch-spec.yaml` = `a_env1_release +3` 修正 retain + `a_volume` or `volume` 修正追加で **Plan A' candidate** 再評価可能 (= env release + gain 軸の 2 axis 修正、 single-axis clean lever 規律 → 2 axis sequential lever 規律へ拡張)
- β-4: 越川氏 audition = Plan A' candidate (= env release + gain) を audition。 退避 Plan A wav (= env release のみ) は **optional reference playback only / Plan A 再昇格ではない / read-only playback** として literal A/B 比較材料に提示可能 (= reject 済 artifact の再評価ではない、 新規 Plan A' candidate identity を維持)

### A-5. ADR-0033 §π15.14 § 10.6 next step 整合 (= 越川氏別 directive、 本 ADR で具体化)

ADR-0033 §π15.14 § 10.6 で示された next step:

- 対象候補 = a_volume / a_level_o1 / mixer / scene gain 系 allowlist parameter
- v2 baseline 基準で isolated gain sweep
- target peak_dbfs -6〜-3 dBFS 目安
- no normalize
- gain → peak / RMS / clipping への影響
- clipping_count == 0 維持
- generated artifacts は /private/tmp のみ
- これは pre-audition engineering gate、 越川氏 audition gate ではない

本 ADR (= ADR-0042) 決定 1-5 + Annex A-3 + A-4 はこの literal を案 A / 案 B として 2 案併記化したもの。 越川氏 user 判断後の採用案で β-2 spike script を literal 化する。

### A-6. ADR-0042 wording 規律 (= literal、 ADR-0033 § 重要 wording 規律踏襲)

本 ADR で使用する wording:

- 「audible-level structural problem」 (= ADR-0033 §π15.14 § 10.5 新カテゴリ literal)
- 「audible-level engineering gate」 (= BD_AUTHORING_PLAN.md § 6.4 literal)
- 「越川氏 audition gate」 (= aesthetic acceptance、 final gate、 永久維持)
- 「normalize による解決はしない」 (= 越川氏 directive literal、 永久禁止 wording)
- 「.fxp 側 gain / mixer 構造」 (= 越川氏 directive literal、 structural narrative)
- 「pre-audition engineering gate」 (= 越川氏 audition gate と別軸の AI 機械検査 layer literal)
- 「current peak_dbfs increased」 / 「current rms_dbfs increased」 (= engineering 軸 only 記述、 「近づいた」 「audible になった」 等の aesthetic 含意 wording 禁止)
- 「mixer 構造案」 / 「.fxp gain 案」 (= 案 A / 案 B literal naming、 本 ADR 内で統一)

使用禁止 wording (= ADR-0033 § 重要 wording 規律踏襲):

- 「normalize で解決」 / 「peak normalize」 / 「loudness normalize」 / 「wav 後処理 gain」 (= 越川氏 directive literal 違反、 永久禁止)
- 「audible になった」 / 「聞こえるようになった」 / 「target に近づいた」 (= aesthetic 含意、 越川氏 audition gate を represent するなし)
- 「accepted」 / 「best」 / 「final」 (= candidate に対する acceptance 含意 wording、 越川氏 audition gate のみが authoritative)
- 「Plan A is rejected」 (= literal は「越川氏 audition で reject」、 Plan A 自体は leading verification plan のまま retain)
