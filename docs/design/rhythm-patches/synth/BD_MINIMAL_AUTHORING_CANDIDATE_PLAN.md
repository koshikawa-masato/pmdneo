# BD minimal authoring candidate plan (= π15.12)

## 0. 本 doc の位置付け (= literal)

本 doc は ADR-0033 π15.12 で **minimal authoring candidate plan を design レベルで literal
固定する design note**。 実装 (= .fxp 生成 / WAV render / sensitivity 追加 sweep) には
**進まない**。 越川氏 別 directive 待ち。

### 0.1 起点 = π15.11 Option D の literal 採用

π15.11 で 4 択 (= A waveshaper / B noise / C OSC1 internal / D v3 不作成) を提示、
越川氏 directive で **Option D** を採用:

- v3 diagnostic baseline は作らない (= synth architecture 選択を回避)
- target の `noisiness_ratio = 0.000435` ほぼゼロ
- band balance すでに target に近い (= sub 0.813 / target 0.800)
- transient lever を追いすぎると解析軸に寄りすぎる (= [[reproducible-workflow-first-aesthetic-second]]
  の規律維持)
- v2 baseline + confirmed levers で authoring plan を作る

### 0.2 scope (= literal)

- 実装しない (= 本 doc は plan only)
- .fxp 生成しない
- WAV render しない
- 追加 sweep しない
- aesthetic candidate **まだ作らない** (= 本 plan は authoring 直前の design step、
  aesthetic acceptance gate を通った成果物ではない)
- optimizer / preference-learning なし
- accept / reject 判定なし
- human audition まだ行わない

### 0.3 前提 (= 越川氏 directive literal)

| カテゴリ | parameter | finding |
|---|---|---|
| **baseline** | `2608_bd-diagnostic-v2.fxp` | sha256 `c03d3228...`、 6/6 active |
| **confirmed clean lever** | `a_env1_release +3` | tail gap 解消 (= isolated、 副次微小) |
| **confirmed trade-off lever** | `a_osc1_octave -1` | body_freq target match だが band balance 悪化 |
| **unusable / weak** | `a_env1_attack` 負方向 | clamp (= -1 / -3 同 wav) |
|  | `a_ws_drive` | silent (= waveshaper routing missing) |
|  | `a_level_noise` | silent (= noise routing missing) |
|  | `a_filter1_resonance +1` | transient up だが band 軸大破壊 |

### 0.4 認識

target との literal feature gap (= π15 Phase 1 finding):

| feature | target | v2 baseline | gap |
|---|---|---|---|
| tail_length_ms | 0.0 | 168.6 | **+168.6** |
| rough_body_frequency_hz | 45.2 | 64.6 | **+19.4** |
| transient_strength | 3.10 | 1.70 | **-1.40** |
| pitch_contour_confidence | 0.285 | 0.579 | +0.29 |
| decay_1e_ms | 1.84 | 3.06 | +1.22 |
| attack_ms | 9.35 | 10.52 | +1.17 |
| band sub | 0.800 | 0.813 | +0.013 (= 既に近い) |
| band low | 0.199 | 0.187 | -0.012 (= 既に近い) |
| noisiness_ratio | 0.0004 | 0.0000 | -0.0004 (= ほぼ同) |

confirmed lever で動かせる gap: **tail (clean) + body_freq (trade-off)**。
動かせない gap: **transient (= lever 不在)**。

## 1. Plan A = minimal single-axis (= a_env1_release +3 only)

### 1.1 構成

| parameter | baseline | delta | new value | parameter_kind |
|---|---|---|---|---|
| `a_env1_release` | -4.321928 | +3 | -1.321928 | conversion + clean lever |

他軸は v2 baseline retain。

### 1.2 expected feature direction

| feature | v2 baseline | expected Plan A | vs target |
|---|---|---|---|
| **tail_length_ms** | 168.6 | **0.0** | **+0.0** (= literal match) |
| body_freq Hz | 64.6 | 64.6 (= 不変) | +19.4 (= gap retain) |
| transient | 1.70 | 1.70 (= 不変) | -1.40 (= gap retain) |
| pitch_conf | 0.579 | 0.665 (= 副次 +0.086) | +0.380 (= gap 微増) |
| band sub | 0.813 | 0.814 | +0.014 |
| band low | 0.187 | 0.186 | -0.013 |

(= Phase 2 trial 1 結果から literal 引用、 同 patch を再現すれば同 wav sha256
`ab90e1920848226a...` 期待)

### 1.3 known trade-off

- **target gap 残存**: body_freq +19.4 / transient -1.40 / decay +1.22 / attack +1.17
- pitch_contour_confidence 微増 (= 0.579 → 0.665、 audible 影響ほぼなし)
- それ以外の副次 effect なし (= clean isolated lever literal verified)

### 1.4 why it is still not an aesthetic candidate

- target との literal feature gap が **複数残存** (= body_freq / transient / decay /
  attack)
- 越川氏 audition gate を通っていない = `aesthetic_acceptance: rejected` のまま
- 「target に近い feature が 1 つ増えた」 ≠ 「BD として良い」
- §決定 27 (12) ν 規律「acceptance is downstream」 維持
- patch-spec.yaml の `acceptance.aesthetic_acceptance` を `pending` に書き換える操作は
  **本 plan scope-out** (= 越川氏 別 directive 起点)

### 1.5 required verification command (= 実行時の literal)

```bash
# Step 1: scratch patched .fxp (= /tmp、 ephemeral)
python3 -c "
import sys
sys.path.insert(0, '/Users/koshikawamasato/Projects/pmdneo/scripts')
from feature_search import _fxp_patch_single_parameter
from pathlib import Path
_fxp_patch_single_parameter(
    Path('/Users/koshikawamasato/Projects/pmdneo/assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp'),
    'a_env1_release', '-1.321928',
    Path('/private/tmp/pmdneo-plan-A/patched.fxp'),
)
"

# Step 2: render via fxp2wav-surge
SURGE_RNG_SEED=2608 ~/Projects/surge-spike/surge/build/src/fxp2wav-surge/fxp2wav-surge \
  --patch /private/tmp/pmdneo-plan-A/patched.fxp \
  --out /private/tmp/pmdneo-plan-A/rendered.wav \
  --note 36 --velocity 127 --duration-ms 800 --tail-ms 200 --sample-rate 44100

# Step 3: analyze-drum + literal diff with target
python3 /Users/koshikawamasato/Projects/pmdneo/scripts/feature_search.py analyze-drum \
  /private/tmp/pmdneo-plan-A/rendered.wav \
  --output-dir /private/tmp/pmdneo-plan-A

# Step 4: target との literal diff 計算 (= 越川氏 directive ad-hoc script で OK)
```

### 1.6 artifact repo 投入判断 = **pending**

- patched .fxp は `/private/tmp/pmdneo-plan-A/patched.fxp` ephemeral
- 越川氏 別 directive で「Plan A 採用 → aesthetic candidate label 化」 となれば repo 投入
  候補 (= `assets/drum_samples/synth/patches/2608_bd-candidate-A.fxp` 等)
- 本 plan では artifact 投入は **判断保留** literal

## 2. Plan B = body pitch も合わせる (= a_env1_release +3 + a_osc1_octave -1)

### 2.1 構成

| parameter | baseline | delta | new value | parameter_kind |
|---|---|---|---|---|
| `a_env1_release` | -4.321928 | +3 | -1.321928 | conversion + clean lever |
| `a_osc1_octave` | 0 | -1 | -1 | conversion + multi-axis trade-off lever |

### 2.2 expected feature direction

isolated trial 結果の **単純 sum 推定** (= 実 cumulative では interaction 未確認):

| feature | v2 baseline | Plan A 単独 | octave -1 単独 | Plan B 推定 (sum) | vs target |
|---|---|---|---|---|---|
| tail_length_ms | 168.6 | **0.0** | 165.6 | **0.0 〜 -3.0** | ~+0.0 (= ほぼ match) |
| body_freq Hz | 64.6 | 64.6 | **43.1** | **43.1** | **-2.1** (= ほぼ match) |
| attack_ms | 10.5 | 10.5 | 19.6 | ~19.6 | **+10.2** (= gap 増大) |
| decay_1e_ms | 3.1 | 3.1 | 6.3 | ~6.3 | +4.5 |
| band sub | 0.813 | 0.814 | **1.000** | **~1.000** | **+0.200** (= gap 増大) |
| band low | 0.187 | 0.186 | **0.000** | **~0.000** | **-0.199** (= gap 増大) |
| pitch_conf | 0.579 | 0.665 | 0.860 | ~0.86 | +0.575 |

cumulative trial は **未実行** (= Phase 2 isolated only) なので、 上記は **単純 sum 推定**。
実 cumulative 結果は interaction で異なる可能性 (= envelope phase shift / band coupling
等)。

### 2.3 known trade-off

- **body_freq target match に向かう** (= +19.4 → -2.1 Hz)
- **tail target match に向かう** (= +168.6 → ~0)
- **band balance 大幅悪化** (= sub gap +0.013 → +0.200、 low gap -0.012 → -0.199)
- **attack 大幅延長** (= +1.2 → +10.2 ms)
- decay 延長 / pitch_conf 増加

### 2.4 why it is still not an aesthetic candidate

- target との literal feature gap は **tail / body は close、 band / attack は破壊** =
  multi-axis trade-off literal
- cumulative interaction 未検証 (= 単純 sum 推定のみ、 実 wav 取得後の literal verify
  必要)
- 越川氏 audition gate なし
- multi-parameter patch は π15.10 BD_AUTHORING_PLAN §3.2 「multi-parameter trial 禁止」
  の cumulative-build phase = phase 3 領域、 本 plan は **設計段階** のみ
- band 軸 target 破壊 = 「BD identity の sub/low balance」 が target と乖離

### 2.5 required verification command

```bash
# Step 1: scratch .fxp chain (= release patch → octave patch)
python3 -c "
import sys
sys.path.insert(0, '/Users/koshikawamasato/Projects/pmdneo/scripts')
from feature_search import _fxp_patch_single_parameter
from pathlib import Path
_fxp_patch_single_parameter(
    Path('/Users/koshikawamasato/Projects/pmdneo/assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp'),
    'a_env1_release', '-1.321928',
    Path('/private/tmp/pmdneo-plan-B/step1.fxp'),
)
_fxp_patch_single_parameter(
    Path('/private/tmp/pmdneo-plan-B/step1.fxp'),
    'a_osc1_octave', '-1',
    Path('/private/tmp/pmdneo-plan-B/patched.fxp'),
)
"

# Step 2/3/4: 同 Plan A (= render + analyze + diff)
```

### 2.6 artifact repo 投入判断 = **pending**

Plan A 同様 pending、 越川氏 別 directive 起点。

## 3. Plan C = band 補正仮説付き (= release +3 + octave -1 + pitch +1)

### 3.1 構成

| parameter | baseline | delta | new value | parameter_kind |
|---|---|---|---|---|
| `a_env1_release` | -4.321928 | +3 | -1.321928 | conversion + clean lever |
| `a_osc1_octave` | 0 | -1 | -1 | conversion + multi-axis trade-off |
| `a_osc1_pitch` | 0 | +1 | 1 | conversion + weak band 補正 |

### 3.2 expected feature direction (= 仮説、 cumulative interaction 未検証)

a_osc1_pitch +1 単独 effect (= Phase 2.5 finding):
- sub -0.109 / low +0.109 (= microscale band shift、 octave -1 と逆方向)

Plan B 推定 + pitch +1 補正 sum:

| feature | Plan B 推定 | pitch +1 単独 | Plan C 推定 (sum) | vs target |
|---|---|---|---|---|
| tail_length_ms | ~0.0 | ~0 | ~0.0 | ~+0.0 |
| body_freq Hz | 43.1 | +0.0 (= semitone only、 not octave) | **~45.6** | **+0.4** (= 更に target match) |
| band sub | 1.000 | -0.109 | **~0.891** | **+0.091** (= gap 部分補正、 だが完全には戻らない) |
| band low | 0.000 | +0.109 | **~0.109** | -0.090 |
| attack_ms | ~19.6 | -0.5 | ~19.1 | +9.7 |

a_osc1_pitch +1 で **band shift を ~55% offset** + body_freq 微増 (= -1 octave +1 semitone)
= target 45.2 Hz に更に近い。

### 3.3 known trade-off

- **band 部分補正だが完全ではない** (= sub gap +0.200 → +0.091、 約 55% offset)
- **body_freq target にさらに近づく** (= 43.1 → 45.6 Hz、 |gap| 2.1 → 0.4)
- attack 軸 gap retain (= +9.7 ms 延長)
- **cumulative interaction 未検証** = 単純 sum 推定、 実 wav で literal verify 必要
- 3 parameter cumulative = isolated trial の単純加算ではなく、 interaction で band shift
  の coupling や envelope phase の干渉が起こり得る

### 3.4 why it is still not an aesthetic candidate

- Plan B と同 reason: cumulative interaction 未検証、 越川氏 audition gate なし
- 仮説段階 (= 単純 sum 推定) であり、 実 wav で band 補正が有効か未確認
- multi-parameter cumulative は π15.10 §3.2 で禁止された軸を design レベルで取り扱う
  境界

### 3.5 required verification command

```bash
# Step 1: scratch .fxp chain (= release → octave → pitch)
python3 -c "
import sys
sys.path.insert(0, '/Users/koshikawamasato/Projects/pmdneo/scripts')
from feature_search import _fxp_patch_single_parameter
from pathlib import Path
_fxp_patch_single_parameter(
    Path('/Users/koshikawamasato/Projects/pmdneo/assets/drum_samples/synth/patches/2608_bd-diagnostic-v2.fxp'),
    'a_env1_release', '-1.321928',
    Path('/private/tmp/pmdneo-plan-C/step1.fxp'),
)
_fxp_patch_single_parameter(
    Path('/private/tmp/pmdneo-plan-C/step1.fxp'),
    'a_osc1_octave', '-1',
    Path('/private/tmp/pmdneo-plan-C/step2.fxp'),
)
_fxp_patch_single_parameter(
    Path('/private/tmp/pmdneo-plan-C/step2.fxp'),
    'a_osc1_pitch', '1.000000',
    Path('/private/tmp/pmdneo-plan-C/patched.fxp'),
)
"

# Step 2/3/4: 同 Plan A
```

### 3.6 artifact repo 投入判断 = **pending**

## 4. 3 plan 比較 table (= literal)

| feature | target | v2 baseline | Plan A | Plan B (sum 推定) | Plan C (sum 推定) |
|---|---|---|---|---|---|
| tail_length_ms | 0.0 | 168.6 | **0.0** | **~0.0** | **~0.0** |
| body_freq Hz | 45.2 | 64.6 | 64.6 | **43.1** | **~45.6** |
| band sub | 0.800 | 0.813 | 0.814 | ~1.000 | ~0.891 |
| band low | 0.199 | 0.187 | 0.186 | ~0.000 | ~0.109 |
| attack_ms | 9.4 | 10.5 | 10.5 | ~19.6 | ~19.1 |
| transient | 3.10 | 1.70 | 1.70 | 1.70 | 1.70 |

| plan | target match (tail) | target match (body) | band integrity | overall risk |
|---|---|---|---|---|
| **A** | ✓ | ✗ (= +19 Hz retain) | ✓ retain | **low** (= minimal scope) |
| **B** | ✓ | ✓ | **✗ broken** | mid |
| **C** | ✓ | ✓ (better) | **△ partial** | mid (= 仮説含む) |

## 5. plan 選定の判断軸 (= 越川氏別 directive 待ち)

### 5.1 越川氏 判断ポイント

1. どの plan を verify execute する? (= A / B / C / 複数並列 / 全部)
2. cumulative interaction 検証は本 plan で許容?
   (= π15.10 §3.2「multi-parameter trial 禁止」 を本 phase で破る判断必要)
3. verify execute 後の artifact repo 投入判断は越川氏個別 directive で決定?
4. 「target match priority」 vs 「band integrity priority」 の trade-off 軸は越川氏軸?
5. transient gap (= lever 不在) を許容しての aesthetic candidate 進行は越川氏 audition
   gate で判断?

### 5.2 私の推奨 (= 越川氏 directive 形成支援、 literal 判断ではない)

- **まず Plan A verify execute** (= minimal scope、 cumulative なし、 clean lever のみ)
  - tail target match の literal evidence 取得
  - 他 gap (= body_freq / transient) は越川氏 audition で許容するか別 lever 探索か判断
- Plan B / C は **Plan A 結果を見てから決める** (= cumulative interaction 検証は phase
  分離維持)
- artifact repo 投入は越川氏個別 directive (= 全 plan で pending 維持)

## 6. scope-out (= 越川氏 directive literal)

- 実装しない (= 本 doc は plan only)
- .fxp 生成しない
- WAV render しない
- 追加 sweep しない
- aesthetic candidate 作らない (= 本 plan は authoring 直前の design step、 越川氏
  audition gate を通った成果物ではない)
- optimizer / preference-learning なし
- accept / reject 判定なし
- human audition まだ行わない
- artifact repo 投入は越川氏別 directive 起点

## 7. 関連 ADR / doc

- `docs/adr/0033-pmdneo-rhythm-sample-provenance-and-self-authored-migration-policy.md`
  §決定 14 / §決定 27 (12) ν 規律
- `docs/design/rhythm-patches/synth/BD_AUTHORING_PLAN.md`
  workflow protocol literal (= phase 1/2/3)
- `docs/design/rhythm-patches/synth/BD_TRANSIENT_LEVER_DESIGN.md`
  π15.11 design note (= Option D 採用根拠)
- `docs/design/rhythm-patches/synth/PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md`
  § 19/20/21 sensitivity findings
- `docs/design/rhythm-patches/synth/2608_bd-diagnostic-v2.patch-spec.yaml`
  v2 baseline spec (= 6/6 active)

## 8. 本 plan の commit value

> 「v3 architecture 選択を回避し、 v2 baseline + confirmed levers で BD authoring
> candidate plan を 3 件 literal 固定。 「音を作る」 直前の計画として、 探索を広げず
> 少数 candidate に絞ることで authoring 目的に戻る。」

ここで plan literal 化することで、 次に「Plan を verify execute するか / aesthetic
candidate に進むか」 を越川氏 別 directive で判断する materials を repo に固定する。 本
commit は **plan doc + ADR entry のみ**、 実 verify / artifact 投入は越川氏別 directive
起点。

## 9. Plan A/B/C scratch verify result (= π15.13)

§ 1〜8 で literal 固定した Plan A/B/C を v2 baseline から scratch verify した結果を
本 section に追記固定する。 generated artifact (= scratch .fxp / rendered wav /
analysis-drum 出力) は `/private/tmp` ephemeral retain、 **repo 投入しない** (= 越川氏
directive literal)。

### 9.1 verify identity

| plan | wav sha256 | classify | confidence |
|---|---|---|---|
| **Plan A** | `ab90e1920848226a...` | BD | 0.774 |
| **Plan B** | `c63a10cc0b0ec9c7...` | BD | 0.834 |
| **Plan C** | `1b7d1d95776d6b42...` | BD | 0.829 |

Plan A の wav sha256 は Phase 2 trial 1 と **完全一致** = deterministic round-trip
literal verified ✓。

### 9.2 feature literal comparison (= target / v2 baseline / Plan A / B / C)

| feature | target | v2 base | Plan A | Plan B | Plan C |
|---|---|---|---|---|---|
| tail_length_ms | 0.0 | 168.6 | **0.0** | **0.0** | **0.0** |
| rough_body_frequency_hz | 45.2 | 64.6 | 64.6 | **43.1** | **43.1** |
| attack_ms | 9.4 | 10.5 | 10.5 | 19.6 | 18.7 |
| decay_1e_ms | 1.8 | 3.1 | 3.1 | 6.3 | 5.9 |
| transient_strength | 3.10 | 1.70 | 1.70 | 1.66 | 1.64 |
| pitch_contour_confidence | 0.285 | 0.579 | 0.665 | 0.957 | 0.938 |
| band sub | 0.800 | 0.813 | 0.814 | **0.9995** | **0.9995** |
| band low | 0.199 | 0.187 | 0.186 | **0.0005** | **0.0005** |

### 9.3 per-plan summary

#### Plan A: a_env1_release +3 (= clean isolated)

- **tail 168.6 → 0.0** (= target match literal、 完全解消)
- band / body_freq / attack / decay / transient ほぼ v2 baseline 維持
- pitch_contour_confidence +0.086 (= 微小副次、 audible 影響ほぼなし想定)
- target との literal gap retention: body_freq +19.4 / transient -1.40 / decay +1.22
- 副作用の少ない確実な改善 = **clean isolated plan**

#### Plan B: + a_osc1_octave -1 (= body match だが band 破壊)

- body_freq 64.6 → 43.1 (= target match、 |gap| 2.1)
- **band sub 0.813 → 0.9995** (= target 0.800 から大乖離)
- **band low 0.187 → 0.0005** (= target 0.199 から大乖離、 殆ど消失)
- attack 10.5 → 19.6 ms (= +10.2 ms 延長)
- decay 3.1 → 6.3 ms (= 約 2 倍延長)
- transient 改善なし
- **band balance broken** = trade-off 大

#### Plan C: + a_osc1_pitch +1 (= band 補正仮説 failed)

- Plan B の band 軸結果と **完全同一** = sub 0.9995 / low 0.0005
- a_osc1_pitch +1 の単独 effect (= Phase 2.5: sub -0.109 / low +0.109) が **cumulative
  で消失**
- 期待値 (= 単純 sum): sub ~0.891 / low ~0.109
- 実際値: sub 0.9995 / low 0.0005
- 微小差分: attack -0.93 ms / transient -0.02 / pitch_conf -0.019 (= a_osc1_pitch +1 の
  attack / pitch_conf effect は部分残存)
- **band compensation hypothesis is failed** = Plan B の band 破壊を補正できない

### 9.4 Important finding (= literal 規律、 越川氏 directive)

#### Finding 1: cumulative parameter interaction is nonlinear

isolated sensitivity sweep で得た per-axis effect を **線形に足し合わせても cumulative
patch の literal feature value にならない**。 Plan C で literal 反証された。

#### Finding 2: single-axis sensitivity cannot be linearly summed

期待:
- a_osc1_octave -1 → band sub +0.187
- a_osc1_pitch +1 → band sub -0.109
- 単純 sum 仮説: 0.813 + 0.187 - 0.109 = ~0.891

実際 (= Plan C):
- 0.9995 (= Plan B と同じ saturation 状態)

→ **single-axis 効果の線形重ね合わせは cumulative state に成り立たない**。

#### Finding 3: octave -1 causes band saturation

a_osc1_octave -1 が band sub を 0.9995 まで押し上げ、 **limit 値 (= ~1.0) に saturate**。
saturate 状態では additional shift (= 反対方向 shift も) が clamp で吸収される。

#### Finding 4: pitch +1 cannot recover low band after saturation

a_osc1_pitch +1 の本来の band shift effect (= sub -0.109 / low +0.109) は、 octave -1 で
saturation が発生した後では **band 軸で消失**。 但し非 band 軸 (= attack / pitch_conf)
には部分 effect 残存。

これは sensitivity findings の **線形累積仮定** が cumulative patch では破綻する literal
evidence。 future cumulative authoring では「saturation 軸の identify」 が必要。

### 9.5 Plan ranking (= literal、 越川氏 directive wording)

| plan | status | reason |
|---|---|---|
| **Plan A** | **leading verification plan** | 副作用の少ない確実な改善 (= tail clean 解消) |
| Plan B | not promoted | band balance broken (= sub 0.9995 / low 0.0005、 target から大乖離) |
| Plan C | not promoted | band compensation hypothesis failed (= Plan B と band 同一、 補正効果消失) |

**重要 wording 規律** (= 越川氏 directive literal):
- ✓ "leading verification plan" = Plan A の現状記述
- ✗ "best plan" = 禁止 (= 越川氏 audition gate 通過前の wording)
- ✗ "accepted plan" = 禁止 (= aesthetic acceptance gate 通過前の wording)

Plan A は **leading verification plan** = 現時点で最も副作用少ない verification candidate
であり、 aesthetic candidate ではない、 best / accepted ではない。

### 9.6 next decision (= 越川氏別 directive 起点)

- Plan A may be promoted to aesthetic candidate **only by separate 越川氏 directive**
- no generated artifact is committed yet (= scratch .fxp / wav / analysis-drum 出力は
  `/private/tmp` ephemeral retain、 repo 投入しない)
- human audition remains final gate (= §決定 27 (12) ν 規律維持)
- Plan A 昇格時の選択肢:
  - new patch-spec.yaml = `2608_bd-candidate-A.patch-spec.yaml` 等で aesthetic candidate
    label 化
  - acceptance.aesthetic_acceptance = `pending` (= 越川氏 audition 待ち)
  - 越川氏 audition → accept / reject の literal record

### 9.7 scope-out (= 越川氏 directive literal、 § 9 追記範囲)

- aesthetic candidate 昇格しない (= 本 § 9 は finding doc 化のみ)
- generated artifact repo 投入なし
- accept / reject 判定なし
- best candidate 選別なし
- optimizer / preference-learning なし
- 別 plan combination 探索なし (= 本 § は 3 plan literal record のみ)
- human audition まだ行わない
