# BD transient lever design note (= π15.11)

## 0. 本 doc の位置付け (= literal)

本 doc は ADR-0033 π15.11 で **設計判断 + 規律を固定する design note**。 実装 (= v3
diagnostic baseline 生成 / 新 sweep / patch 修正) には **進まない**。

### 0.1 起点 = Phase 2.5 の認知

Phase 2 / Phase 2.5 (= π15.10 BD_AUTHORING_PLAN.md phase 2 実行 + 追加 6 軸 sweep) で、
v2 diagnostic baseline (= 6/6 active 化済) でも **transient_strength gap が埋まる lever
が不在** という finding に到達した。

### 0.2 設計判断が必要な理由

v3 baseline で「何を active 化するか」 は、 もはや **unit conversion / structural
dependency setup の延長** ではなく、 **synth architecture の選択** (= 「BD をどう作るか」
の sound design 判断) に踏み込んでいる:

- a_ws_drive を active 化する = **waveshaper を BD の音作りに使う**
- a_level_noise を active 化する = **noise OSC を BD に混ぜる**
- a_osc1 internal parameters = **OSC source design そのもの**

これは π15.10 で literal 固定した「**diagnostic baseline は aesthetic-rejected**」 の
線を、 v3 baseline がどこまで尊重できるかの境界判断。

### 0.3 scope (= literal)

- 実装しない (= 本 doc は design note only)
- v3 .fxp 作らない
- sweep しない
- aesthetic candidate 作らない
- optimizer / preference-learning なし
- accept / reject 判定なし
- commit するのは本 design note + ADR-0033 frontmatter chain entry のみ

## 1. Phase 2.5 summary (= literal finding 反映)

### 1.1 transient lever 候補 (= A 系 3 軸)

| parameter | baseline | result | transient delta | 判定 |
|---|---|---|---|---|
| `a_ws_drive` | 3.0 | 全 delta silent | 0.000 | **NOT usable** (= waveshaper inactive) |
| `a_level_noise` | 1.0 | 全 delta silent | 0.000 | **NOT usable** (= noise routing missing) |
| `a_filter1_resonance` | 0.1 | partial active | +0.397 (delta=+1) | **partial** (= band 軸 trade-off 大) |

### 1.2 band 補正 lever 候補 (= B 系 3 軸)

| parameter | baseline | result | band sub delta | 判定 |
|---|---|---|---|---|
| `a_osc1_pitch` | 0 | microscale | ±0.16 (delta=±3) | **weak** (= microscale partial offset only) |
| `a_filter1_cutoff` | 10.35 | microscale silent | ≈0 | **NOT usable** |
| `a_lowcut` | -72 | attack 副次のみ | ≈0 | **NOT usable for band** |

### 1.3 主要 finding

- **transient_strength gap (-1.4)** を埋める **clean lever は v2 baseline に存在しない**
- **band 補正 lever** も **存在しない or microscale only**
- `a_filter1_resonance +1` は transient lever だが、 sub band -0.724 / low band -0.166 で
  **target band balance を破壊する trade-off**
- baseline SHA self-consistency OK ✓ (= `28442a6ed106fa2c...` 全 sweep 一致)

## 2. root cause 分類 (= literal、 越川氏 directive 通り)

Phase 2.5 silent / weak lever の原因を 3 カテゴリに分離する:

### 2.1 unit conversion 問題ではないもの

`a_filter1_resonance` の partial usability + 「band 軸 trade-off」 は **conversion
formula の問題ではない**:

- `a_filter1_resonance` の value 0.1 は既に Surge XT 内部 scale 整合
- delta +1 で audible effect が出ている = active 化済
- band 軸 trade-off は **filter resonance の物理的性質** (= high-Q で sub band dip)
- → **conversion 表の修正対象ではない**

### 2.2 structural routing 問題

`a_ws_drive` / `a_level_noise` の silent は **routing 設定の問題**:

- `a_ws_drive` value=3.0 は scale 上有効値、 但し **waveshaper が baseline で active で
  ない** (= a_ws_type=0 or routing 設定で waveshaper path に signal 流れていない可能性)
- `a_level_noise` value=1.0 は max、 但し **noise OSC の output が mixer 経由で audio
  path に乗っていない** (= OSC mixer 設定 missing)
- これらは π15.9 v0.2.0 の structural_dependencies と **同 nature の問題** (= 「baseline
  state を整えれば active 化する」 type)

→ **理論上は v3 で structural dependency 追加で解消可能**

### 2.3 synth architecture 選択問題

但し「v3 で waveshaper / noise を active 化する」 こと自体が、 **BD の音作りそのものに
入る**:

- waveshaper を有効化 = **BD に harmonic distortion を加える設計判断**
- noise を有効化 = **BD に noise transient を加える設計判断**
- OSC1 internal parameters = **OSC source 形状の設計判断**

これは π15.10 BD_AUTHORING_PLAN §0.1 の「sensitivity findings = 解析軸」 と「authoring
decision = 意思決定軸」 の境界を **diagnostic baseline 側に持ち込む** ことになる。

→ **「どこから先が音作りか」 の線引きが必要**

### 2.4 3 カテゴリの関係 (= literal)

```text
unit conversion 問題     = parameter-unit-conversion.yaml v0.1.0 で解消済 (π15.8)
structural routing 問題  = parameter-unit-conversion.yaml v0.2.0 で 4 件解消 (π15.9)
                             但し waveshaper / noise routing は未解消
synth architecture 問題  = ここから先は diagnostic ではなく authoring design
                             choice (= 音作り)
```

Phase 2.5 finding は **structural routing と synth architecture の境界線** で停止して
いる状態。 v3 で両方踏み込むか、 architecture 判断は別軸に分けるか、 が本 design note
の核心判断。

## 3. v3 baseline の選択肢

### 3.1 option A: waveshaper routing を active 化

- 新規 structural dependency: `a_ws_type` を 0 → 1 以上 (= shaper type 選択)
- 副次 dependency 候補: waveshaper input routing 設定 (= OSC1 → shaper path)
- 期待: `a_ws_drive` が transient lever として active 化

### 3.2 option B: noise routing を active 化

- 新規 structural dependency: noise OSC mixer routing 設定
- 副次 dependency 候補: a_osc?_type or OSC mixer settings
- 期待: `a_level_noise` が transient / noise transient lever として active 化

### 3.3 option C: OSC1 internal parameters を sweep

- 新 sweep 対象: `a_osc1_param0` 〜 `a_osc1_param6` (= OSC source 形状)
- 期待: OSC waveform shape で transient 特性が変わる可能性
- 但し OSC source 設計は **音作りそのもの**

### 3.4 option D: v3 を作らず、 現 lever map で authoring candidate 方針へ進む

- v2 baseline + 確定 lever (= a_env1_release / a_osc1_octave (trade-off) /
  a_filter1_resonance (partial trade-off) / a_osc1_pitch (weak)) で authoring
- transient gap を **越川氏 audition で許容するか別軸補正に頼る**
- diagnostic baseline は v2 のまま fix、 architecture 判断は別 commit chain で

## 4. 各選択肢の risk

### 4.1 共通 risk: diagnostic baseline が sound design baseline に寄りすぎる

option A / B / C いずれも、 v3 baseline が「**6/6 axis active な diagnostic state**」
から「**特定の synth architecture を選んだ BD design baseline**」 に意味が変わる。

これは π15.10 の literal 規律 「**diagnostic baseline は aesthetic-rejected**」 を
violate しないが、 **「diagnostic」 という wording の射程を超える** 可能性。

### 4.2 option A risk = waveshaper routing

- waveshaper を有効化 = **harmonic distortion を BD に加える設計判断**
- BD identity の典型 = pure tone + transient click、 distortion 加えるとキャラ変動
- waveshaper type 選択肢が複数 (= Soft Clip / Hard Clip / Tanh / etc) で **探索空間増大**
- target wav が distorted BD か否か未確認

### 4.3 option B risk = noise routing (= **越川氏 directive 強調**)

- **target `noisiness_ratio = 0.000435`** = ほぼ完全 pure tone BD
- noise routing 有効化 = **noise を加える方向**、 target から離れる
- 越川氏 directive literal: 「noise 増やす方向は危険」
- transient だけ上がるかを確認する価値はあるが、 noise 増やすと target band balance も
  乱れる (= mid / high band ratio 上昇)

### 4.4 option C risk = OSC1 internal parameters

- OSC1 source waveform 自体を変える = **音作りそのもの**
- a_osc1_param0 〜 param6 で **7 軸増加**、 探索空間が急増
- 各 param の意味は OSC1 type 依存 (= Classic / Modern / Sine / 等で param 意味変動)
- baseline a_osc1_type=1 (= 確認必要) の意味も literal で固定が必要

### 4.5 option D risk = v3 を作らない

- transient gap を **diagnostic 軸で埋められない** ことを literal 受容
- authoring candidate を作る段階で「target feature gap が完全 close できない state」
  で進む = **越川氏 audition で transient 不足を許容する判断が必要**
- 探索空間は広がらない、 但し authoring 段階で「lever 不在」 が顕在化する可能性

### 4.6 同時複合の risk

option A + B を **同時に v3 で入れる** と、 distortion + noise 同時導入で BD 像が大きく
変わる。 同時に入れると個別 effect が判別不能。 越川氏 directive 通り **同時導入は避ける**。

## 5. 推奨 (= literal 規律)

### 5.1 まだ aesthetic candidate は作らない (= 越川氏 directive literal)

option A/B/C/D のいずれを取っても、 本段階では **aesthetic candidate は作らない**。

### 5.2 v3 を作る場合の分離規律

option A / B / C は **同時導入しない**:

- 1 commit = 1 structural axis 追加
- 例: v3a = waveshaper only / v3b = noise only / v3c = OSC1 param only
- 各 v3 候補で個別に sensitivity sweep verify
- 副次 trade-off が target を破壊しないか literal record

### 5.3 越川氏 directive の wording 整合

- **target `noisiness_ratio = 0.000435`** = ほぼ 0
- **option B (= noise routing 有効化) は危険軸** = 越川氏 directive で literal 警告済
- noise は最後の選択肢、 まず option A or C から
- option A (= waveshaper) は distortion 軸、 target が distorted か否かは越川氏 audition
  判断軸

### 5.4 option D の意義

option D を取ると **「現 lever map で authoring に進む」** = transient gap が残ったまま
aesthetic candidate を作る。 これは「sensitivity の深掘りを切り上げる」 という π15.10
の chain 切り替え規律の **literal 帰結**。

「target feature を完全 close する diagnostic baseline」 は **存在しない可能性** を受容、
authoring 段階で「越川氏 audition gate が最終判断」 (= §決定 27 (12) literal) を貫徹。

### 5.5 推奨 (= literal、 越川氏 directive で判断する材料として)

私の推奨は **option A (waveshaper only) or option D (現 lever で進む)** のいずれか:

- **option B (noise) は最後の選択肢** (= 越川氏 directive literal「noise 増やす方向は危険」)
- option C (OSC1 internal) は探索空間が大きすぎる
- option A は distortion 軸で transient lever 期待、 但し band balance 副次 effect 注意
- option D は **transient gap を authoring 段階で許容**、 越川氏 audition gate に委ねる

最終判断は越川氏 directive 待ち、 本 design note は判断材料の literal 固定のみ。

## 6. 関連 ADR / doc

- `docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md`
  §決定 14 / §決定 27 (12) ν 規律 (= aesthetic gate authoritative)
- `docs/design/rhythm-patches/synth/PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md`
  § 19 (π15.7) / § 20 (π15.8) / § 21 (π15.9) sensitivity findings
- `docs/design/rhythm-patches/synth/parameter-unit-conversion.yaml`
  v0.2.0 conversions + structural_dependencies 2 section
- `docs/design/rhythm-patches/synth/2608_bd-diagnostic-v2.patch-spec.yaml`
  v2 baseline spec (= 6/6 active、 transient lever 不在)
- `docs/design/rhythm-patches/synth/BD_AUTHORING_PLAN.md`
  authoring workflow (= phase 1/2/2.5 までで本 design note へ chain)

## 7. 本 design note の commit value

> 「v3 baseline で何を active 化するかは、 unit conversion / structural dependency
> の延長ではなく synth architecture 選択になる。 ここで「どこから先が音作りか」 の線引きを
> 設計 note で literal 固定してから進める。」

ここで note 化することで、 次に v3 baseline を作るとき or authoring candidate に進むときに
「設計判断を改めて確認する materials」 を repo に固定できる。 本 commit は **設計 note と
ADR entry のみ**、 実装は越川氏 別 directive 起点。
