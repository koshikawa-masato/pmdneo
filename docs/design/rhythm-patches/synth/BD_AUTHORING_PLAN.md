# BD authoring plan = v2 diagnostic baseline + sensitivity findings に基づく authoring 方針

## 0. 本 doc の位置付け (= literal)

本 doc は ADR-0033 π15.10 で確立する **BD authoring の設計方針** を記録する。 実装手順
や aesthetic 判断はここでは扱わない。 sensitivity 解析の深掘り (= π15.7 / π15.8 / π15.9
chain) をどこで切り上げ、 何を起点に authoring に戻すかの literal 規律を固定する。

**aesthetic candidate 作成 (= phase 3) は本方針の scope-out**。 phase 3 は別 directive
で別 commit 起点。

### 0.1 役割分担

| doc | 役割 |
|---|---|
| `PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md` | sensitivity の **finding** を蓄積 (= 解析軸) |
| `BD_AUTHORING_PLAN.md` (= 本 doc) | sensitivity findings を input にした **authoring decision protocol** (= 意思決定軸) |
| `2608_bd-diagnostic-v2.patch-spec.yaml` | baseline state 記録 (= 不変 retain) |

### 0.2 scope-out (= 越川氏 directive literal)

- 実装しない (= 本 doc は方針 only)
- aesthetic candidate 作らない (= phase 3 別 directive)
- optimizer 再開しない
- preference-learning 再開しない
- accept / reject 判定しない
- 既存 diagnostic v0.1.0 / v0.2.0 不変
- 既存 `2608_bd.fxp` / `2608_bd.patch-spec.yaml` 不変
- driver semantics 不変

## 1. authoring baseline = v2 diagnostic baseline

### 1.1 baseline 選定 literal

authoring baseline = `assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp`

- sha256: `c03d32284d5d9108da905bcce6674b09a5912845cb5b46f0262ab2c069013517`
- label: `unit-converted diagnostic baseline v2 / aesthetic-rejected /
  for sensitivity measurement only / structural dependency expansion`
- 6/6 軸 active 化済 (= π15.9 で確定)
- spec: `2608_bd-diagnostic-v2.patch-spec.yaml`

### 1.2 baseline 選定理由

- **6/6 軸 active**: a_osc1_octave / a_env1_attack / a_env1_decay / a_env1_release /
  a_env2_decay / a_lowcut すべて sensitivity sweep で audible effect が観察可能
- **sensitivity findings が直接適用可能**: π15.7 / π15.8 / π15.9 で確立した
  `parameter → feature delta` 対応知識を v2 baseline 上でそのまま参照できる
- **conversion + structural dependency 整理済**: `parameter-unit-conversion.yaml` v0.2.0
  で formula と setup が schema 分離されており、 baseline state の意味が literal で読める
- **aesthetic-rejected literal**: baseline 自体は aesthetic 判断対象ではない、 authoring
  起点として安全 (= 「success baseline」 ではなく「diagnostic baseline」 という性質維持)

### 1.3 baseline 不可触原則

authoring 中も `2608_bd-diagnostic-v2.fxp` 自体は変更しない。 trial 中の patched .fxp は
すべて `/private/tmp` 配下に生成、 repo には入れない。

## 2. target feature snapshot = authoring anchor

### 2.1 target reference

target = `assets/sounds/adpcma/2608_BD-roundtrip.wav`

`analyze-drum` 出力の feature_snapshot を **authoring anchor** として使用 (= 113d5bc /
π15.6 で deterministic 確認済):

```yaml
# 2608_BD-roundtrip.wav analyze-drum feature_snapshot (= literal)
band_energy_ratio:
  sub: 0.800388
  low: 0.198902
  low_mid: 0.000225
  mid: 5.0e-05
  high: 0.000431
  air: 4.0e-06
attack_ms: 9.351
decay_1e_ms: 1.838
tail_length_ms: 0.0
transient_strength: 3.101
rough_body_frequency_hz: 45.166
pitch_contour_confidence: 0.285038
noisiness_ratio: 0.000435
```

### 2.2 target 利用方針 (= reference-inspired 境界遵守)

- **literal target feature snapshot を authoring anchor として使う** = §決定 14
  reference-inspired (= OK) の範囲
- **target WAV sample byte の直接利用は禁止** = §決定 14 derivative (= NG) の範囲
- target wav の sample / spectrogram / waveform を直接 import / sample / wavetable 化する
  操作はすべて scope-out (= §決定 27 (12) literal)
- target feature snapshot は intent 記録 + diff 観察用、 audible 判断は越川氏 audition のみ

### 2.3 feature diff は完成 gate ではない (= 越川氏 directive literal)

target との literal match を完成 gate にしない:

- **feature diff 縮小は authoring 指針**、 越川氏 acceptance gate ではない
- **越川氏 aesthetic gate is authoritative** (= §決定 27 (12) literal 維持)
- feature diff が小さくても越川氏 reject 可能、 feature diff が大きくても越川氏 accept 可能
- 「target に近づいた」 wording 禁止、 「current feature diff = X」 のみ literal

[[metric-pass-is-not-aesthetic-pass]] / [[relative-preference-vs-absolute-acceptance]] 規律維持。

## 3. workflow protocol = 1 parameter change → render → analyze-drum → feature diff → decision

### 3.1 trial 最小単位 (= literal)

```text
1 parameter change
  -> 1 patched .fxp (= /private/tmp、 ephemeral)
  -> 1 render (= fxp2wav-surge invoke)
  -> 1 analyze-drum (= deterministic feature extraction)
  -> 1 feature diff record (= target との literal 差分)
  -> 1 decision (= 次の trial の方向決め)
```

### 3.2 multi-parameter trial 禁止 (= まだ)

- 複数 parameter 同時変更は **本方針段階では禁止**
- 理由: interaction effect が混入し、 sensitivity findings の literal 参照性が崩れる
- grouped multi-parameter trial は future 別判断軸 (= 本 phase scope-out)

### 3.3 trial output retention (= 越川氏 directive literal)

| 成果物 | 配置 | repo 投入 |
|---|---|---|
| patched .fxp | `/private/tmp/<trial-id>/patched.fxp` | ✗ |
| rendered .wav | `/private/tmp/<trial-id>/rendered.wav` | ✗ |
| analysis-scalar.yaml | `/private/tmp/<trial-id>/analysis-scalar.yaml` | ✗ |
| analysis-timeseries.json | `/private/tmp/<trial-id>/analysis-timeseries.json` | ✗ |
| analysis-summary.yaml | `/private/tmp/<trial-id>/analysis-summary.yaml` | ✗ |
| sensitivity-table.yaml / .csv | `/private/tmp/<trial-id>/` | ✗ |
| 決定の literal 記録 (= decision log) | 越川氏判断軸 (= 本方針 scope-out) | (= 越川氏 directive 待ち) |

generated artifact は ephemeral retain、 trial 結果は文書化 (= 後段判断) ではなく
**「次の trial をどうするか」 の literal input** に閉じる。

### 3.4 deterministic 保証

- 全 render に `SURGE_RNG_SEED=2608` env 経由 (= §決定 25 ι'' producer 規律)
- 同 fxp + 同 producer 設定で wav sha256 bit-identical 期待
- baseline render sha256 self-consistency = 各 trial の delta=0 row で自動 check

## 4. phase 区分

### 4.1 phase 1 = target vs v2 baseline literal diff (= read-only)

**目的**: target feature snapshot と v2 baseline の feature snapshot の literal 差分を
取得、 どの軸を動かすかの方向感を確立。

**操作**:
- v2 baseline `2608_bd-diagnostic-v2.fxp` を render (= 1 回)
- analyze-drum で feature_snapshot 取得
- target (= 2608_BD-roundtrip.wav の既存 feature_snapshot) との literal diff 計算
- diff 大きい feature を identify

**output**: feature diff table (= ephemeral / `/private/tmp` retain、 repo 投入なし)

**gate**:
- v2 baseline render が deterministic (= sha256 self-consistent)
- analyze-drum が exit 0
- feature diff record 取得

**scope-out**: aesthetic 判断、 候補生成、 越川氏 audition。

### 4.2 phase 2 = targeted parameter trials

**目的**: phase 1 で identify した「diff 大きい feature」 を、 sensitivity findings を
参照しながら、 1 軸ずつ targeted parameter trial で縮める。

**操作 (= 1 trial 1 ループ)**:
1. phase 1 / 前回 trial の feature diff から、 最大 gap の feature を 1 つ選ぶ
2. sensitivity findings から「その feature を変える parameter」 を 1 つ選ぶ
3. baseline + delta で 1 parameter 変更 → patched .fxp 生成
4. fxp2wav-surge で render
5. analyze-drum で feature_snapshot 取得
6. target との feature diff を literal 記録
7. 「diff が縮んだか」 を literal record (= 判断は越川氏軸ではない、 next trial input)
8. → 次の trial へ (= 2 へ戻る or 別 feature 軸へ)

**iteration 終了条件 (= 越川氏判断軸ではなく literal record gate)**:
- 主要 feature の diff が一定 threshold 以下 (= 越川氏 別 directive 必要)、 or
- sensitivity findings 上で「これ以上動かせる parameter がない」 と literal 判定、 or
- 越川氏 directive で iteration 終了指示

**output**:
- 各 trial の literal 記録 (= parameter / delta / feature diff before-after) は
  `/private/tmp` retain
- 蓄積した「どの parameter で何が変わったか」 を **decision log** として残すかは越川氏判断軸
  (= 本方針では未定義、 phase 3 着手時に別 directive)

**scope-out**: aesthetic candidate label 化、 越川氏 audition、 best 選別、 multi-parameter
trial、 optimizer / preference-learning。

### 4.3 phase 3 = aesthetic candidate 作成 (= 本方針 scope-out)

**本方針では phase 3 は含めない** (= 越川氏 directive literal)。

phase 2 で蓄積した parameter / feature 知識を使って、 越川氏 hand-on で aesthetic
candidate fxp を作るのは **別 directive / 別 commit 起点**。 phase 3 では:

- patch-spec.yaml の `acceptance` を `aesthetic-rejected` から `pending` に書き換える
- 越川氏 audition gate を通す
- accept / reject の literal record

これらはすべて越川氏 別判断軸、 本方針では言及のみ。

## 5. authoring 優先軸 (= target との literal gap を起点)

phase 1 / 2 で focus する axis 候補を sensitivity findings から literal 引用:

| target feature | target value | v2 baseline 推定 | 主な lever (= sensitivity findings 由来) |
|---|---|---|---|
| `rough_body_frequency_hz` | 45.166 | 110+ Hz 想定 | `a_osc1_octave` (multi-axis lever) / `a_osc1_pitch` |
| `band_energy_ratio.sub` | 0.800 | 要 phase 1 measure | `a_osc1_octave` (= sub ↔ low shift) |
| `attack_ms` | 9.351 | a_env1_attack 5 ms 換算 | `a_env1_attack` (isolated axis) |
| `decay_1e_ms` | 1.838 | a_env1_decay 280 ms 換算 | `a_env1_decay` (v2 で attack 軸 effect) |
| `tail_length_ms` | 0.0 | sustain + release effect | `a_env1_release` (= sustain dependency 下) |
| `noisiness_ratio` | 0.000435 | level_noise 1.0 baseline | `a_level_noise` (= sensitivity 未 sweep、 phase 2 候補) |

これらは **authoring 指針のみ**、 完成 gate ではない。 phase 1 で literal 比較取得後、
phase 2 で 1 軸ずつ trial。

## 6. 完成 gate / acceptance gate の literal 規律

### 6.1 feature diff は完成 gate ではない (= 越川氏 directive literal)

- feature diff 縮小 = authoring 指針 (= advisory)
- 越川氏 audition = acceptance gate (= authoritative)
- 両者は **別軸**、 混同しない

### 6.2 human audition が final gate

- phase 1 / 2 の trial 結果は越川氏 audition の input、 selection ではない
- LLM + sensitivity-sweep + analyze-drum + feature diff 全部 supporting layer
- 越川氏 final accept のみが authoritative (= §決定 27 (12) ν 規律維持)

### 6.3 wording 規律

- 「target に近づいた」 ✗ (= aesthetic 含意 wording 禁止)
- 「current feature diff = X」 ○ (= literal record only)
- 「ranking best」 ✗ (= asset acceptance 軸ではない)
- 「relative feature distance smaller」 ○

[[metric-pass-is-not-aesthetic-pass]] / [[preference-learning-beats-metric-correlation]]
規律維持。

### 6.4 audible-level pre-audition gate (= π15.14 追加)

aesthetic candidate phase に進む前に、 **audible-level engineering gate** を通す必要が
ある:

- baseline render の **peak_dbfs** が **-6 〜 -3 dBFS** 範囲に収まること
- **clipping_count == 0** 維持
- rms_dbfs が target wav の rms_dbfs ± 6 dB 範囲に収まること

これは π15.14 で Plan A audition が **「音として認識できない」** と reject された literal
evidence (= v2 baseline / Plan A peak -25 dBFS / target -3 dBFS、 gap 22 dB) を踏まえて
追加した規律。

#### 6.4.1 audible-level gate は越川氏 audition gate と別軸

- audible-level gate = **engineering pre-condition** (= 音が聞こえる前提)
- 越川氏 audition gate = **aesthetic acceptance** (= BD として良いか判断)
- audible-level gate を通過しないと audition gate に到達できない = 「音として認識できない」
  と aesthetic 判断不能

#### 6.4.2 normalize による解決 禁止

audible-level の解決方法として、 **render 後処理 (= normalize)** で peak amplitude を
調整することは **禁止**。 audible amplitude は `.fxp` 側の **gain / mixer 構造** として
解くべき (= source-of-truth 規律維持)。

- 候補: `a_volume` / `a_level_o1` / mixer / scene gain 系 allowlist parameter
- 各軸の isolated gain sweep で peak / RMS / clipping への literal effect 観察
- target peak_dbfs ~ -3 dBFS を達成する gain setup を baseline structural dependency に
  追加 (= v2.1 audible-level extension 候補 or 別 baseline chain)

#### 6.4.3 phase 3 entry 条件 update (= π15.14 補正)

phase 3 aesthetic candidate phase に進む前に **必要な gate**:

```text
1. v2 diagnostic baseline 上の feature gap が advisory advisory 確認済
2. 1 parameter 修正の sensitivity findings 蓄積済
3. authoring candidate plan literal 固定済 (= BD_MINIMAL_AUTHORING_CANDIDATE_PLAN.md)
4. ★ audible-level engineering gate clear ★ (= π15.14 新規追加)
5. scratch candidate generation
6. 越川氏 audition gate (= aesthetic acceptance、 final gate)
```

gate 4 が clear しないまま gate 5 / 6 に進むと、 「音として認識できない」 で audition
gate が機械的 reject される (= π15.14 で literal experienced)。

## 7. 関連 ADR / doc

- `docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md`
  - §決定 14 sound-alike caution (= reference-inspired vs derivative)
  - §決定 25 fxp2wav-surge external producer (= scope-in but not repo-in)
  - §決定 27 (12) target-feature matching optimization axis (= ν 規律 + π13 / π15 / π15.5
    中核 wording)
- `docs/design/rhythm-patches/synth/PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md`
  - § 15-18 deterministic analysis chain (= 113d5bc)
  - § 19 π15.7 = π5 baseline structural defect
  - § 20 π15.8 = 1st round diagnostic baseline
  - § 21 π15.9 = v0.2.0 structural dependency expansion
- `docs/design/rhythm-patches/synth/USAGE.md`
  - analyze-drum / sensitivity-sweep / make-diagnostic-baseline command literal

## 8. 本方針の commit value

> 「sensitivity 解析の深掘りを切り上げ、 v2 diagnostic baseline + sensitivity findings を
> 起点に BD authoring 軸に戻す literal 規律」

ここで doc 化することで、 次の作業者が「解析を深掘りし続ける」 のではなく「authoring 方針
に戻る」 ことを明確化できる。 本方針自体は実装ではなく **設計方針段階の record**、
phase 1 / 2 / 3 への着手は越川氏 別 directive 待ち。
