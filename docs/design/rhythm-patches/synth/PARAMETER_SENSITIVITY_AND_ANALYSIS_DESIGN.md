# Surge XT parameter sensitivity + analysis design investigation

- 状態: **investigation / design draft** (= 23rd session π15.5 軌道修正)
- 関連 ADR: ADR-0033 §決定 26 / §決定 27
- 関連 artifact: `assets/drum_samples/synth/2608_bd.wav`, `assets/drum_samples/synth/patches/2608_bd.fxp`
- scope: 6 音共通解析手段の選定設計 + drum profile 設計 + `.fxp` parameter sensitivity table 設計
- non-goal: metric 最大化 / optimizer 再実行 / `.fxp` 自動最適化 / 既存 `2608_BD.adpcma` 更新

---

## 1. 調査目的

現在の chain は `feature distance` と `optimizer` に寄りすぎている。
本来の目的は **`2608_*.wav` を Surge XT `.fxp` parameter file として再現可能に定義すること** であり、解析 score を 1 に近づけることではない。

本調査書の目的は、次の 2 点を先に固定すること。

1. `2608_BD.wav` と Surge XT render WAV を同じ方法で解析し、比較可能な deterministic data に変換する設計
2. Surge XT `.fxp` parameter を 1 件ずつ動かしたとき、解析 data のどこがどう変わるかを記録する対応表の設計

この 2 点がないまま optimizer を回すと、score は改善しても **`.fxp` authoring の知識** にならない。

## 2. 以前の ADR との対応

PMDDotNET / MML 検証では、2 経路で同じ WAV が得られることを byte / SHA256 で確認した。
今回も同じ考え方を使う。

```text
target:
  2608_BD.wav
    -> deterministic analysis data

candidate:
  Surge XT .fxp
    -> fxp2wav-surge render wav
    -> deterministic analysis data

compare:
  target analysis data と candidate analysis data の差分を見る
```

ただし今回は byte-identical WAV を目指すのではない。
WAV 全体の byte 一致ではなく、BD 再現に必要な特徴を deterministic data として比較する。

## 3. 解析 tool 選定の前提

解析 tool は **final judge ではない**。
解析 tool は、耳での判断に入る前の diagnostic data を作るためのもの。

採用条件:

- 同一 WAV から同一 feature が再生成できる
- sample rate / channel / bit depth などの前提を明示できる
- BD の主要要素を分けて観察できる
- `.fxp` parameter sensitivity table に転用できる
- YAML / CSV として artifact 化できる

除外条件:

- score だけを返し、どの音響要素が動いたか分からないもの
- human audition を置き換えるもの
- target WAV の sample data を再利用するもの

## 4. BD 再現で必要な観察軸

BD では、少なくとも次の軸を分けて観察する必要がある。

| 軸 | 見たいこと | 代表 feature 候補 |
|---|---|---|
| onset | 立ち上がりが遅くないか | leading silence, attack_ms, onset peak |
| transient | クリック / punch があるか | peak/RMS, onset envelope, spectral flux |
| body pitch | 胴鳴りの高さ | rough f0, low-band peak, pitch contour |
| pitch drop | BD らしい下降があるか | frame-wise f0, low-band centroid time series |
| decay | 短すぎる / 長すぎる / sustain 化していないか | RMS envelope, decay_1e_ms, tail length |
| spectral balance | 低域・中域・高域の比率 | band energy ratio, log-mel bands |
| noise/click | noise 成分が過不足ないか | spectral contrast, high-band transient |
| loudness | 音量差で誤判定していないか | peak, RMS, LUFS |

既存 `feature_search.py` の v1/v2 feature は出発点として使える。
ただし、BD 再現には **time-series 系 feature** が特に重要。

## 5. 解析 tool 群の候補

### 5.1 current baseline

既存:

- `scripts/feature_search.py extract`
- `scripts/feature_search.py compare`
- `scripts/feature_search.py validate`
- `docs/design/rhythm-patches/synth/feature-rules.yaml`
- `docs/design/rhythm-patches/synth/feature-rules-v2.yaml`

位置づけ:

- baseline として維持
- 既存 metric の採否は未確定
- optimizer objective ではなく、diagnostic feature extractor として再評価する

### 5.2 scalar feature

用途:

- 早い sanity check
- 異常 candidate の除外
- sensitivity table の summary column

候補:

- peak / RMS / LUFS
- attack_ms
- decay_1e_ms
- tail_length_ms
- low/mid/high band ratio
- spectral centroid
- rough_frequency_hz

弱点:

- 時間変化を潰す
- BD の pitch drop / transient shape を捉えにくい

### 5.3 time-series feature

用途:

- BD の再現性を見る主軸
- parameter sensitivity を見る主軸

候補:

- RMS envelope time series
- onset envelope time series
- low-band energy envelope
- log-mel spectrogram time series
- frame-wise spectral centroid
- frame-wise low-band centroid
- rough f0 / pitch contour

評価方法:

- fixed hop length
- fixed frame count または fixed time grid
- target / candidate を同じ長さに切り出して比較
- DTW は補助。最初は固定 time grid の差分を優先する

### 5.4 perceptual feature

用途:

- 音量差・聴感差の補助

候補:

- LUFS
- MFCC mean/std
- log-mel mean/std
- spectral contrast

注意:

- MFCC / log-mel は便利だが、理由説明が弱くなりやすい
- sensitivity table では scalar summary と time-series delta に分けて使う

## 6. 解析 tool 評価方法

解析 tool 自体も評価対象にする。

### 6.1 repeatability

同じ WAV を複数回解析し、出力 YAML が byte-identical になること。

```text
2608_BD.wav
  -> analysis A
  -> analysis B
  -> SHA256(A) == SHA256(B)
```

### 6.2 discrimination

明らかに違う candidate を区別できること。

例:

- silence
- pure sine long sustain
- click only
- low sine no transient
- noise only
- existing rejected candidate
- accepted / hand-authored candidate

ここで区別できない feature は、BD 再現の主 feature にしない。

### 6.3 interpretability

feature の差分から、修正すべき parameter 群を推測できること。

例:

- attack が遅い -> `a_env1_attack`
- decay が長い -> `a_env1_decay`, `a_env1_release`
- 低域が高すぎる / 低すぎる -> `a_osc1_pitch`, `a_osc1_octave`
- 高域 transient が足りない -> `a_level_noise`, filter / drive

### 6.4 correlation with audition

human audition との相関は必要。
ただし、これは metric を final judge にするためではない。

目的:

- 明らかに役に立たない feature set を退ける
- sensitivity table の読み方を改善する

## 7. `.fxp` parameter sensitivity table 設計

目的は、次の対応を機械的に作ること。

```text
Surge XT parameter delta
  -> rendered wav delta
  -> analysis feature delta
  -> human-readable effect label
```

これは optimization ではない。
1 parameter だけを動かし、音響特徴の変化を観察する。

## 8. 実験 protocol

### 8.1 fixed inputs

- baseline `.fxp`: 1 件に固定
- render note: MIDI 36
- velocity: 127
- duration: 800 ms
- sample rate: 44100 Hz
- channel: mono
- bit depth: 16-bit
- normalize: off
- leading: 0
- trailing trim: +50-100 ms
- seed: §決定 26 (6) literal 固定

### 8.2 one-factor-at-a-time

1 回の render で変更する parameter は 1 件だけ。

```text
baseline.fxp
  + a_env1_decay = baseline + delta
  -> render
  -> analyze
  -> compare with baseline analysis
```

複数 parameter の相互作用は、最初の sensitivity table ができた後に扱う。

### 8.3 parameter sweep

各 parameter は固定 grid で動かす。

例:

```yaml
parameter: a_env1_decay
baseline: -2.089
values:
  - -5.0
  - -4.0
  - -3.0
  - -2.089
  - -1.0
  - 0.0
```

grid は `feature-rules-v2.yaml` の `search_space` を初期値に使う。

## 9. 初期対象 parameter

最初は BD に効く可能性が高いものだけに絞る。

| parameter | 期待される主効果 |
|---|---|
| `a_env1_attack` | onset / transient |
| `a_env1_decay` | body decay |
| `a_env1_release` | tail / sustain 化 |
| `a_env2_decay` | pitch/filter envelope 期間 |
| `a_filter1_cutoff` | 明るさ / 高域抑制 |
| `a_lowcut` | 低域量 / body |
| `a_level_noise` | click / noise transient |
| `a_ws_drive` | punch / saturation / loudness |
| `a_osc1_pitch` | body pitch |
| `a_osc1_octave` | body pitch range |

次段階で追加候補:

- `a_level_o1`
- `a_level_o2`
- `a_mute_noise`
- `a_filter1_resonance`
- `a_filter1_type`
- OSC type / routing enum

enum / routing は効果が大きいので、continuous sweep とは別表にする。

## 10. table 出力 format

### 10.1 machine-readable YAML

```yaml
schema_version: "0.1.0"
target: BD
baseline:
  fxp: assets/drum_samples/synth/patches/2608_bd.fxp
  wav: assets/drum_samples/synth/2608_bd.wav
  analysis_sha256: "<sha256>"
render_condition:
  sample_rate: 44100
  channels: 1
  bit_depth: 16
  normalize: false
  note: 36
  velocity: 127
sweeps:
  - parameter: a_env1_decay
    scale: log-time
    baseline_value: -2.089
    observations:
      - value: -5.0
        wav_sha256: "<sha256>"
        analysis_sha256: "<sha256>"
        feature_delta:
          decay_1e_ms: -120.4
          tail_length_ms: -90.0
          rms_amplitude_dbfs: -2.1
        effect_summary:
          primary: shorter_decay
          secondary:
            - lower_loudness
```

### 10.2 CSV summary

Claude Code が読みやすい summary も出す。

```csv
parameter,value,primary_effect,attack_ms_delta,decay_1e_ms_delta,low_band_ratio_delta,rough_frequency_delta,notes
a_env1_decay,-5.0,shorter_decay,0.0,-120.4,-0.02,0.0,"tail shortened"
```

## 11. 解析 data 出力 format

解析結果は raw score だけにしない。
次の 3 層を保存する。

1. `analysis-scalar.yaml`
2. `analysis-timeseries.npz` または `analysis-timeseries.json`
3. `analysis-summary.yaml`

`analysis-summary.yaml` は人間と Claude Code が読む。
`analysis-timeseries.*` は再計算と図示用。

## 12. 判定 wording

使ってよい wording:

- feature delta
- diagnostic similarity
- candidate differs in attack / decay / pitch contour
- sensitivity observed
- parameter affects feature

使わない wording:

- match
- clone
- reproduced by metric
- score が良いので成功
- optimizer が選んだので accept

## 13. 推奨 next step

まず実装するのは optimizer ではない。

1. analysis extractor の出力を deterministic artifact 化する
2. 6 音共通 feature set の schema を固定する
3. rule-based drum-kind classifier を追加する
4. profile-specific summary を追加する
5. analysis tool 評価用の small fixture set を作る
6. `parameter-sensitivity` subcommand を設計する
7. 初期 parameter で one-factor sweep を実行する
8. YAML / CSV の sensitivity table を artifact として保存する
9. Claude Code はその表を使って `.fxp` authoring 方針を立てる

## 14. scope constraints

- driver semantics 不変
- 既存 `2608_BD.adpcma` 非破壊
- `assets/drum_samples/synth/2608_bd.wav` は source artifact として扱う
- metric / table は final judge ではない
- human audition が final gate
- 新 artifact chain 追加 only

## 15. 6音共通 feature set + profile selection

対象は BD だけではなく、最終的には `2608_*.wav` 6 音すべて。
解析 extractor は音種ごとに別実装しない。
まず全音に同じ common feature set を出し、その後で drum profile を選ぶ。

```text
WAV
  -> common feature extraction
  -> deterministic drum-kind classifier
  -> profile selection
  -> profile-specific interpretation
```

### 15.1 common feature set

全音に必ず出す feature:

```yaml
waveform:
  - duration_ms
  - sample_rate
  - channels
  - bit_depth
  - total_samples
level:
  - peak_dbfs
  - rms_dbfs
  - integrated_lufs
  - clipping_count
timing:
  - leading_silence_ms
  - attack_ms
  - decay_1e_ms
  - tail_length_ms
  - transient_strength
spectrum:
  - band_energy_ratio
  - band_energy_envelope
  - spectral_centroid_mean
  - spectral_centroid_series
  - spectral_flux_mean
  - spectral_contrast_mean
  - log_mel_spectrogram
pitchedness_noise:
  - rough_body_frequency_hz
  - pitch_contour
  - pitch_contour_confidence
  - low_band_centroid_series
  - noisiness_ratio
  - voiced_frame_ratio
```

固定 band:

| band | range | 主用途 |
|---|---:|---|
| sub | 0-80 Hz | BD low body |
| low | 80-250 Hz | BD / TOM body |
| low_mid | 250-700 Hz | TOM / SD body |
| mid | 700-2000 Hz | SD / RIM body |
| high | 2000-8000 Hz | HH / CYM / click |
| air | 8000 Hz+ | HH / CYM brightness |

### 15.2 drum profiles

common feature は全音共通。
profile は「どの feature を重く見るか」「どう解釈するか」だけを定義する。

| profile | 重視する feature |
|---|---|
| BD | sub/low energy, body frequency, pitch drop, attack, decay, tail |
| SD | transient, mid/high energy, noisiness, noise tail, decay |
| HH | high/air energy, centroid, short noise decay, onset sharpness |
| CYM | high/air energy, spectral spread, long tail, spectral contrast |
| TOM | low/low_mid energy, body frequency, pitch contour, decay, tail |
| RIM | transient, mid/high energy, very short tail, peak/RMS |

### 15.3 deterministic classifier

profile 選択は手入力に依存させない。
同じ WAV から同じ common feature が得られ、同じ rule で同じ `predicted_kind` が出る必要がある。

classifier input:

- band energy ratio
- spectral centroid
- tail_length_ms
- attack_ms
- transient_strength
- rough_body_frequency_hz
- pitch_contour_confidence
- noisiness_ratio
- voiced_frame_ratio

classifier output:

```yaml
drum_kind_classifier:
  schema_version: "0.1.0"
  predicted_kind: BD
  confidence: 0.82
  candidates:
    BD: 0.82
    TOM: 0.54
    SD: 0.18
    RIM: 0.12
    HH: 0.05
    CYM: 0.03
  rule_version: "drum-kind-rules-v0.1.0"
```

初期 rule は ML ではなく固定式でよい。

| kind | rule sketch |
|---|---|
| BD | sub+low が高い、centroid 低い、pitch confidence あり、tail 中程度 |
| TOM | low/low_mid が高い、pitch confidence あり、BD より centroid 高い |
| SD | mid/high が高い、noise が多い、transient 強い、tail 中程度 |
| RIM | transient 強い、tail 非常に短い、mid/high が高い |
| HH | high/air が高い、tail 短い、pitch confidence 低い |
| CYM | high/air が高い、tail 長い、spectral spread 大きい |

classifier は profile 選択の入口であり、音源の正しさを判定しない。

## 16. deterministic trial protocol

試行錯誤は許可する。
ただし 1 回ごとの trial は常に決定論的に記録する。

```text
same input
same render condition
same analysis condition
same classifier rule
same profile rule
same parameter delta
  -> same output artifact
```

1 trial の最小単位:

```text
1 baseline .fxp
1 parameter
1 delta
1 render
1 common analysis
1 classifier result
1 profile-specific summary
1 sensitivity table row
```

この単位を崩して、複数 parameter を同時に動かさない。

## 17. Codex 設計上の着地点

本設計の着地点は次の 4 点。

1. 6 音すべてに common feature set を適用する
2. common feature から deterministic classifier で drum profile を選ぶ
3. profile ごとに feature の重みと解釈を切り替える
4. sensitivity table は `1 parameter / 1 delta / 1 row` で蓄積する

以後の実装指示は次の形にできる。

```text
optimizer を再開しない。
まず deterministic analysis extractor と drum profile classifier を実装し、
6 音共通 feature set と profile-specific summary を artifact 化する。
その後、one-factor sensitivity table を作る。
```

## 18. 実装入口 (= Claude Code 用)

`scripts/feature_search.py analyze-drum` を deterministic analysis の入口にする。
この command は optimizer を呼ばない。

```bash
python3 scripts/feature_search.py analyze-drum \
  assets/sounds/adpcma/2608_BD-roundtrip.wav \
  --output-dir /private/tmp/pmdneo-analyze-drum
```

出力 artifact:

```text
analysis-scalar.yaml
analysis-timeseries.json
analysis-summary.yaml
```

役割:

- `analysis-scalar.yaml`: common feature set + analysis params
- `analysis-timeseries.json`: envelope / band energy / pitch contour / log-frequency spectrogram
- `analysis-summary.yaml`: classifier result + selected profile + profile-specific focus + sensitivity parameter axes

profile を固定したい場合:

```bash
python3 scripts/feature_search.py analyze-drum \
  path/to/input.wav \
  --profile BD \
  --output-dir /private/tmp/pmdneo-analyze-drum
```

repeatability condition:

- 同じ input WAV
- 同じ command
- 同じ script version

で 3 artifact の SHA256 が一致すること。

smoke evidence:

```text
input: assets/sounds/adpcma/2608_BD-roundtrip.wav
predicted_kind: BD
selected_profile: BD
repeatability: analysis-scalar.yaml / analysis-timeseries.json / analysis-summary.yaml all SHA256 identical across two output directories
```

## 19. 6 軸 horizontal sweep finding (= π15.7 diagnostic record)

π15.6 で vertical slice (= a_osc1_pitch 1 軸縦通し) が成立した後、 残り 6 軸を horizontal
sweep として diagnostic 実行した結果を本節に固定する。 これは generated artifact ではなく
**finding 記録** = 「今の baseline (= 2608_bd.fxp) は sensitivity を測るには一部壊れている」
という事実を repo レベルで literal 化する。

baseline = `assets/drum_samples/synth/patches/2608_bd.fxp` (= diagnostic-baseline /
aesthetic-rejected label、 π5 NG patch、 patch-spec passthrough 未変換 state)。

### 19.1 共通 deterministic 保証

全 6 軸の `delta=0` row の `wav_sha256` が完全一致:

```text
e46960ae934370b9ab2656217d7ddeaa7fa7e0a9b01b22b4d5ec68f77a3f1969
```

deterministic sweep chain は成立 = same baseline + same patched .fxp (= same XML value
text) + same producer + same SURGE_RNG_SEED で bit-identical render。

### 19.2 軸別分類

| classification | axes | 観察 |
|---|---|---|
| **silent axis** | `a_env1_decay`, `a_env2_decay` | delta ±3 で全 feature delta = 0 |
| **isolated axis** | `a_env1_attack` | attack 軸のみ動く、 band / body / tail 不変 |
| **multi-axis lever** | `a_osc1_octave` | attack + body_freq + band balance 同時 |
| **unexpected interaction** | `a_lowcut`, `a_env1_release` | 副次 effect or sign asymmetry |

### 19.3 silent axes (= a_env1_decay / a_env2_decay)

baseline `a_env1_decay = 280` および `a_env2_decay = 50` は Surge XT 内部 log-time scale
で `2^280 sec` / `2^50 sec` という完全非物理値。 Surge XT 内部 clamp で delta ±3 程度では
output 不変 = sensitivity を測れない。

これは π5 patch-spec passthrough mismatch の **literal evidence**:

- patch-spec.yaml 側 `a_env1_decay: 280` は「280 ms」 を意図した human-readable value
- Surge XT XML 側 `<a_env1_decay value="280"/>` は log-time scale (= seconds の log2) として解釈
- mismatch = `2^280 sec` という非物理値、 internal clamp で effect 不能

これら 2 軸は **「現 baseline では sensitivity を測れない parameter」** として記録され、
unit conversion 適用後の別 baseline で再評価すべき (= 後段判断、 本 commit では実装しない)。

### 19.4 isolated axis (= a_env1_attack)

`a_env1_attack baseline 0`、 deltas -3, -1, 0, 1, 3 で attack_ms のみ動く (= band / body /
tail 全 0 delta)。 但し sign 非線形 = baseline 0 が log-time 極大点 (= 2^0 = 1 sec):

| delta | attack delta | 観察 |
|---|---|---|
| -3 | -650 ms | 最強 attack 短縮 |
| -1 | -283 ms | |
| 0 | 0 | reference |
| +1 | -15 ms | 正方向でも短縮 |
| +3 | -100 ms | |

clean な single-axis lever、 BD attack 短縮には `-3` が最強。

### 19.5 multi-axis lever (= a_osc1_octave)

`a_osc1_octave` 1 軸で attack / body_freq / band balance が同時に動く:

| delta | new | attack | body_freq | sub | low | low_mid |
|---|---|---|---|---|---|---|
| -2 | -2 | -11.5 ms | -21.5 Hz | +0.186 | -0.186 | 0 |
| -1 | -1 | +0.5 ms | -21.5 Hz | +0.186 | -0.186 | 0 |
| 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| +1 | +1 | +3.2 ms | +64.6 Hz | -0.814 | +0.814 | 0 |
| +2 | +2 | +4.6 ms | +193.8 Hz | -0.814 | -0.084 | +0.898 |

+1 で sub→low に完全 band shift、 +2 で low_mid dominant = BD identity から離れる方向。
-1 と -2 で sub band shift saturate (= +0.186 で同値) = band cap or pitch quantize 仮説。

### 19.6 unexpected interaction

#### 19.6.1 a_lowcut → attack 副次 effect

`a_lowcut baseline -72` (= minimum)、 deltas 0,10,20,30,40 (= -72 → -32 まで lowcut 引き上げ):

| delta | new | attack delta |
|---|---|---|
| 0 | -72 | 0 |
| +10 | -62 | -0.3 ms |
| +20 | -52 | **-7.4 ms** |
| +30 | -42 | -1.3 ms |
| +40 | -32 | **-16.8 ms** |

attack 軸のみ動く (= body / band / tail 不変)、 但し **non-monotonic** = +20 と +40 が
+30 より effect 強い。 filter envelope or waveshaper feedback path 経由仮説。

#### 19.6.2 a_env1_release sign asymmetry

`a_env1_release baseline 0`、 deltas -3,-1,0,1,3:

| delta | new | tail delta | attack delta |
|---|---|---|---|
| -3 | -3 | **+108.6 ms** | 0 |
| -1 | -1 | 0 | 0 |
| 0 | 0 | 0 | 0 |
| +1 | +1 | 0 | 0 |
| +3 | +3 | 0 | +7.7 ms |

負方向のみ tail 大増加、 正方向は dead zone + delta=+3 で attack 微小 effect (= unexpected
attack 干渉)。

### 19.7 重要 finding (= 固定)

- delta=0 row は全 6 軸で baseline render SHA 一致 → deterministic sweep chain 成立
- `a_env1_attack` は isolated attack axis (= 唯一の clean single-axis lever)
- `a_osc1_octave` は body_freq / band / attack を同時に動かす strong lever (= BD identity 大変動)
- `a_env1_decay` / `a_env2_decay` は silent axis (= 現 baseline では sensitivity 測れず)
- silent axis は π5 patch-spec passthrough mismatch の **literal evidence**
  - patch-spec ms 値が Surge XT log-time field に直接注入された structural defect
  - `2^280 sec` / `2^50 sec` という非物理値で internal clamp 化、 effect 不能
- `a_lowcut` と `a_env1_release` は unexpected interaction あり
  - lowcut: non-monotonic attack 副次 effect
  - release: sign asymmetric、 -3 で tail +108 ms、 +3 で attack 微小干渉

### 19.8 結論 (= 次判断候補、 本 commit では実装しない)

現 baseline (= 2608_bd.fxp、 π5 patch-spec passthrough 未変換) は sensitivity を測るには
一部壊れている (= 6 軸中 2 軸が silent axis)。 unit-converted baseline (= patch-spec の
human-readable ms / Hz 値を Surge XT 内部 log-time / log-freq scale に変換した別 baseline)
を作るかどうかが次判断軸。

**本 π15.7 commit ではこの structural defect を finding として固定するのみ**、 unit
conversion layer の実装には進まない。 越川氏 directive 維持:

- optimizer 再開禁止
- preference-learning 再開禁止
- unit conversion layer 実装は次 commit の判断軸 (= ここでは記録のみ)
- best candidate selection 禁止
- accept / reject 判定禁止
- generated artifact (= /private/tmp 配下) は repo 未投入
