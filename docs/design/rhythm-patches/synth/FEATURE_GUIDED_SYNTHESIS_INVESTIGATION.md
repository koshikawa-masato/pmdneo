# Feature-guided synthesis investigation (= ADR-0033 §決定 27 π8 architectural pivot 候補調査)

- 状態: **investigation / proposal** (= 23rd session π8、 越川氏 directive ベース)
- 関連 ADR: ADR-0033 §決定 1 / §決定 14 / §決定 27 / §決定 25
- 関連 commit: be4fd7a (= π7 = passthrough 禁止 wording 確立 + Kick 909ish reference)
- scope: investigation + ADR analysis + prototype direction proposal、 implementation は scope-out
- inversion stance: **「FFT で Surge XT parameter を一意逆算」 は採用しない、 「feature-guided parameter search / wavetable encoding」 として扱う**

---

## 0. TL;DR (= recommendation 先出し)

PMDNEO に推奨する architecture = **Option A++ = hybrid feature-guided parameter search** (= 単純 search 拡張、 純粋 wavetable 路線は採用しない):

```text
target wav (= 越川氏 aesthetic reference、 例 Kick 909ish.fxp render or 70s/80s drum 録音)
        ↓
feature extraction (librosa = spectral centroid / flux / RMS / attack ms / decay curve / etc)
        ↓
reference patch baseline (= Kick 909ish.fxp 56 element values = 既知 starting point)
        ↓
CMA-ES / scipy.optimize 経由 continuous parameter search
  (= 6-10 element only = a_env1_attack / decay / release / cutoff / lowcut / drive 等)
        ↓
generated .fxp candidate (= bridge invoke)
        ↓
wav render (= fxp2wav-surge external producer)
        ↓
feature distance score (= AI self-analysis 10 項目 と統合)
        ↓
engineering_pass: passed (= score threshold under)
        ↓
越川氏 aesthetic audition / accept (= final gate)
```

**wavetable route は二次候補 / 将来検討** (= OSC scale mismatch のみ解決、 envelope / filter / drive unit conversion 依然必要、 sample derivative narrative risk あり、 §決定 14 sound-alike caution 境界に注意)。

---

## 1. 現状認識 (= π7 audition NG の root cause + 既存 attempted fix)

π7 越川氏 audition で `2608_bd.wav` (= bridge 生成) は「ものすごい低音だけで BD ではない」 評価 (= aesthetic gate FAIL)。 原因:

1. **patch-spec passthrough mismatch** = `decay_ms 280` 等の human-readable を Surge XT 内部 log-time scale (= -1.84) に変換せず直接注入 → 天文学的 decay = sustain 化
2. **template = Init Sine** = OSC1 Sine、 Kick 909ish reference (= OSC1 Classic + noise + filter) と構造的に大差
3. **filter / waveshaper / lowcut** がすべて未調整、 Kick 909ish の cutoff -41 / drive 3.5 / fb_config 4 等の BD-specific 設定が不在

直接的 fix = **D (unit conversion layer)** だが、 conversion table を hand-craft しても **「正常 BD として鳴る Surge XT 値の精密な定義」** が patch-spec.yaml 側で困難 (= 越川氏 hand-tune 軸も engineering correctness 軸も両方手数増)。

ここで **越川氏 directive = 「feature-guided synthesis」 軸を統合** = target audio の feature (= 例 Kick 909ish.wav の spectral characteristic) を「最終結果」 として patch parameter を **逆問題的に探索** する経路。

## 2. methodology 統合方針 (= NOT exact inversion / IS feature-guided search)

「FFT で parameter を一意逆算」 は **採用しない**:
- inverse synthesis は **非一意** (= 同じ rendered audio を産む parameter set は無数に存在、 underdetermined)
- exact clone / ROM recreation 方向は §決定 14 / §決定 2 違反
- aesthetic は数値的に encode 不可 (= 越川氏 final gate の主観領域)

採用する: **「feature-guided parameter search」** = target audio の feature vector を **目標** として、 Surge XT parameter を **探索** する経路:
- 「target wav の音色を **完全再現** する」 ではなく「**近づける**」 が目的
- 最終 accept は **越川氏 aesthetic gate** で決定 (= score 高いから accept 自動化はしない、 §決定 27 (10) acceptance is downstream 規律維持)
- target wav は **aesthetic reference** (= 「こういう感じの音」)、 generated wav は **new synthetic asset candidate** (= 「PMDNEO の BD」)
- inverse 性質を明示 = 数値的 distance は最終判断ではない、 越川氏 ear judgement が最終

## 3. 領域別調査 finding

### 3.1 feature extraction layer 調査

**librosa** (= 標準 Python audio analysis) で全 candidate feature が covered:

| feature | librosa function | drum 用途 |
|---------|------------------|----------|
| FFT / STFT | `librosa.stft()` | spectrogram base |
| spectral centroid | `librosa.feature.spectral_centroid()` | 「明るさ」 中心、 BD は低 / HH は高 |
| spectral flux | `librosa.onset.onset_strength()` | attack detection |
| low-band energy ratio | manual STFT band split | BD fundamental 領域 / HH 高域比率 |
| attack time | `librosa.onset.onset_detect()` + peak | transient sharpness |
| decay curve | RMS envelope fit (= exponential) | drum decay character |
| transient strength | peak/RMS ratio in attack window | snappy vs muddy |
| RMS / peak | `librosa.feature.rms()` + `np.max(np.abs(y))` | overall energy |
| tail length | silence threshold detection | release character |
| pitch tracking | `librosa.pyin()` | fundamental frequency |

**audiofeat** (= alternative、 PyPI) も attack feature 含む。

dependencies: librosa + numpy + scipy = Python 標準科学 stack、 install ≈ 100 MB。 既存 PMDNEO 環境 (= venv) で容易導入可。

evidence: [librosa docs](https://librosa.org/doc/0.11.0/feature.html) + [audiofeat PyPI](https://pypi.org/project/audiofeat/)

### 3.2 Surge XT parameter optimization feasibility

**最有力 = CMA-ES evolutionary optimizer + 関連 spike 1 件**

直近 academic work [Instrumental (arxiv:2603.15905, March 2026)](https://arxiv.org/html/2603.15905) が我々の use case と最も近い:
- **28-parameter subtractive synthesizer** (= Surge XT subtractive scene 構造に類似)
- **CMA-ES (Covariance Matrix Adaptation Evolution Strategy)** = derivative-free evolutionary optimizer
- **composite perceptual loss** = mel-STFT + spectral centroid + MFCC divergence
- **PoC**: ~28 parameter で audio matching 動作確認、 我々の 56 element subset (= 6-10 continuous) なら現実的

**他 reference work:**
- [DiffMoog (arxiv:2401.12570, 2024)](https://arxiv.org/html/2401.12570v1) = differentiable modular synth + neural net + signal-chain loss = **differentiable な PyTorch 経路必要、 Surge XT は non-differentiable で適合せず**
- [Modulation Discovery (arxiv:2510.06204, Oct 2025)](https://arxiv.org/html/2510.06204v1) = DDSP-based、 modulation source 推定中心、 我々の use case と斜め
- Bayesian optimization (= BoTorch / Ax) = scipy.optimize で代替可、 dependency 軽

**実装観点 = scipy + librosa で十分:**
```python
from scipy.optimize import minimize  # = CMA-ES なら scikit-optimize / cma library
import librosa

def feature_distance(surge_params, target_features):
    fxp = bridge_invoke(template, allowlist, surge_params)
    wav = fxp2wav_surge_invoke(fxp)
    gen_features = extract_features(wav)
    return weighted_l2(gen_features, target_features)

# optimizer
result = minimize(
    feature_distance,
    x0=baseline_kick_909ish_params,  # = Kick 909ish reference
    args=(target_features,),
    method='Nelder-Mead',  # = derivative-free
    options={'maxiter': 100},
)
```

**continuous parameter候補 (= 6-10 件 search 対象):**

| element | scale | search range | notes |
|---------|-------|-------------|-------|
| `a_env1_attack` | log-time | [-10, -4] | drum attack 0.001-0.06 sec |
| `a_env1_decay` | log-time | [-5, 0] | drum decay 0.03-1.0 sec |
| `a_env1_release` | log-time | [-10, -2] | drum release |
| `a_env2_decay` | log-time | [-7, -2] | pitch sweep 期間 |
| `a_filter1_cutoff` | log-freq | [-60, 0] | filter sweep |
| `a_lowcut` | log-freq | [-72, -20] | HPF |
| `a_level_noise` | normalized | [0, 1] | noise mix |
| `a_ws_drive` | dB or scale | [0, 10] | saturation |
| `a_osc1_pitch` | semitones | [-12, 12] | pitch shift |
| `a_osc1_octave` | integer | [-2, 1] | (= enum、 discrete) |

**enum / routing 系は baseline 固定** (= `a_osc1_type`、 `a_filter1_type`、 `a_fb_config`、 `a_ws_type`、 `a_mute_noise` 等は Kick 909ish 値で固定、 search 対象外)。

**feasibility 総合 = HIGH** (= 既存技術 + 軽 dependency + 6-10 dim search は CMA-ES / Nelder-Mead で 100 iter 程度で収束見込み、 各 iter ≈ 1-3 sec で全体 5-10 分想定)

### 3.3 wavetable route 調査

**WaveEdit** (= Synthesis Technology open source、 [GitHub](https://github.com/synthesistechnology/waveedit)):
- GUI 経由で waveform drawing / FFT harmonic editing / sample import / FX 適用 → wavetable WAV export
- format = 256 sample × 64 cycle × 16-bit
- normalization 必須 (= Surge XT clipping 回避)

**Surge XT 同梱 `wt-tool.py`** ([wt-tool docs](https://github.com/surge-synthesizer/surge-synthesizer.github.io/wiki/Creating-Wavetables-For-Surge)):
- Python CLI = wavetable WAV → Surge XT `.wt` format 変換
- harmonic content programmatic creation 可能 (= 既知 issue #1078 = "Create" mode 一部問題あり)
- `wt-tool.py create --harmonics ...` 形式想定

**wavetable route の architecture (= IFFT-based synthetic、 sample derivative 回避):**

```text
target spectral signature
    ↓ (= 越川氏 indicates "BD で fundamental 65 Hz + Nth harmonic energy ...")
harmonic content design (= 各 cycle で N 個 sine partial 振幅指定)
    ↓ (= IFFT で time-domain waveform 再構成)
wavetable 64 cycle (= 各 cycle 256 sample、 例 time 軸で harmonic 変化させる)
    ↓ (= wt-tool.py で Surge XT .wt format 変換)
Surge XT wavetable osc に load + 既存 envelope/filter/drive で shape
```

**重要 finding 1: wavetable は OSC scale mismatch のみ解決**:
- OSC1 type = Wavetable (= enum) + OSC1 param0-6 (= wavetable index / interpolation 等) で wavetable がそのまま 「音色 source」 になる
- **envelope (a_env1_*) / filter (a_filter1_*) / drive (a_ws_*) は依然 log-time / log-freq / dB scale**、 unit conversion 必要
- = **silver bullet ではない**、 partial solution

**重要 finding 2: sample derivative narrative risk**:
- IFFT-based synthetic (= 設計 harmonic で生成) = **safe** (= 越川氏 100% 著作物方針整合)
- 既存 wav から STFT → wavetable 抽出 = **derivative risk** (= §決定 14 sound-alike caution / §決定 2 ROM dump 排除に近接)
- target wav = aesthetic reference のみ、 wavetable は別途設計が推奨

**重要 finding 3: wavetable workflow は engineering complexity 上がる**:
- WaveEdit GUI (= 越川氏 hand-on 復活する risk)、 or wt-tool.py + Python script + IFFT design
- 越川氏 hand-on engineering ゼロ規律 (= π 軸転換 narrative) と整合させるには **全 AI/toolchain 化** 必要
- 引きずる complexity = librosa + numpy + wt-tool.py + wavetable validation

**feasibility 総合 = MEDIUM** (= 技術的可能 / partial solution / narrative complexity / engineering overhead 中-高)

### 3.4 ADR-0033 への影響分析

**§決定 27 との整合:**
- §決定 27 (1) AI 役割 3 (= bridge、 unit conversion 必須 = π7 拡張) の **拡張** として feature-guided search を組込可能
- §決定 27 (5) AI self-analysis 10 項目 = feature extraction layer の **第一 customer** = 既存 analysis を最適化 loss としても再利用可能
- §決定 27 (6) workflow step 4-6 (= AI self-analysis → revision proposal → re-iterate loop) が **最適化 loop と native 整合**
- §決定 27 (10) engineering pass ≠ aesthetic accept = score 高い ≠ 採用、 最終 gate は越川氏 = **規律維持**

**§決定 14 sound-alike caution との境界:**
- target wav = **aesthetic reference として扱う** (= 「こういう感じの音」)、 **「同じ音にする」 ではない**
- feature distance score は **convergence indicator**、 **identity match** ではない
- search 結果 = **new synthetic candidate**、 「derivative」 ではない
- 禁止 target = Yamaha mask ROM dump / RX-11 recording / 商用 sample pack (= §決定 2/3/4 既存規律維持)
- 推奨 target = Surge XT 同梱 factory patch / 越川氏 自作 reference / public domain 録音

**§決定 1 100% 著作物との整合:**
- target wav から harmonic / temporal feature を **読み取る** = OK (= 情報読取)
- target wav の sample data を **コピー** = NG (= 「derivative」 = §決定 14 違反)
- 生成 .fxp = patch parameter の組合せ = 「越川氏 設計 spec + AI 探索 + 越川氏 accept」 で 越川氏 100% 著作物 narrative 維持

**FFT direct inversion 非採用理由:**
- 非一意性 (= 同じ wav 産む parameter 無数)
- aesthetic = 数値的 encode 不可
- §決定 14 sound-alike caution との緊張 (= exact clone 方向へ slipping)
- 越川氏 final gate を bypass する risk (= acceptance is downstream 違反)

**「reference-inspired」 vs 「derivative」 の境界 literal 提案:**

| pattern | reference-inspired (= OK) | derivative (= NG) |
|---------|--------------------------|------------------|
| feature 経由 | spectral characteristic を guide として使う | wav の sample byte をそのまま再生 |
| 数値関係 | distance score < threshold で convergence | byte-level identical |
| 結果 wav | new synthetic = 越川氏 設計 spec + accept | 元 wav の degraded copy |
| narrative | 「こういう感じの音を目指す」 | 「同じ音を再現する」 |
| ADR-0033 整合 | §決定 14 sound-alike caution 範囲内 | §決定 14 / 1 / 2 違反 |

### 3.5 implementation candidate 比較

3 候補 全軸比較:

| 軸 | A: parameter search | B: wavetable synthesis | C: hybrid (= wavetable + param) |
|----|---------------------|------------------------|--------------------------------|
| reproducibility | ✓ (= deterministic + seed 固定) | △ (= wavetable creation 経路に依存) | △ |
| legality | ✓ (= 純 synthesis) | △ (= synthetic IFFT なら OK、 sample-based なら NG) | △ |
| explainability | ✓ (= 56 element 数値で全説明可能) | △ (= wavetable buffer = opaque) | △ |
| PMDNEO narrative | ✓ (= patch-spec → search → element 全部 human-traceable) | △ (= wavetable provenance 設計余地) | △ |
| AI/toolchain 自動化 | ✓ (= scipy / librosa で完結) | △ (= wt-tool + WaveEdit dependency、 越川氏 GUI risk) | △ |
| aesthetic controllability | ★ (= target feature 経由 + 越川氏 final gate) | ★ (= timbre 直接 encode) | ★★ (= 両軸 control) |
| engineering complexity | medium | high | very high |
| §決定 27 整合 | ✓ (= AI 役割 3 + 5 自然拡張) | △ (= 越川氏 hand-on 復活 risk) | △ |
| §決定 14 sound-alike 境界 | ✓ (= search で convergence、 derivative ではない) | △ (= wavetable 設計次第) | △ |
| §決定 1 100% 著作物 | ✓ (= 越川氏 spec + AI search + 越川氏 accept) | △ (= wavetable source narrative 必要) | △ |
| 実装期間想定 | 1-2 commit (= librosa + scipy 統合) | 3-5 commit (= wt-tool 統合 + wavetable design + validation) | 5+ commit |
| 失敗時の rollback 容易さ | ✓ (= 既存 bridge に additive) | △ (= 別 workflow layer) | △ |
| 6 drum 種横展開 | ✓ (= per-drum target で再利用) | △ (= 各 drum 用 wavetable 設計負担) | △ |

### 3.6 推奨 architecture 提案

**Option A++ = feature-guided parameter search を推奨** (= 単純 A の拡張、 Kick 909ish baseline + librosa + scipy/CMA-ES):

```text
patch-spec.yaml (= 越川氏 design intent + AI candidate)
        ↓
target_wav_ref (= Kick 909ish.wav 等の reference wav、 spike repo 同居 OK)
        ↓
feature extraction (= librosa = spectral centroid / flux / attack / decay / RMS / pitch)
        ↓
baseline_params (= Kick 909ish.fxp 56 element 値、 search 開始点)
        ↓
search loop (= CMA-ES / scipy.optimize、 6-10 continuous parameter のみ、 enum 固定):
    propose params
        ↓
    bridge invoke (= patch_template_patch.py with proposed params)
        ↓
    fxp2wav-surge render
        ↓
    feature distance score
        ↓
    optimizer update
    ↑__________________ (max 100 iter, ~10 min)
        ↓
converged params → final .fxp candidate
        ↓
AI self-analysis 10 項目 (= ν step 4、 重複なし統合)
        ↓
engineering_pass (= 全 10 項目 PASS)
        ↓
越川氏 aesthetic audition (= ν step 10、 final gate)
```

**理由:**
1. **§決定 27 自然拡張** = AI 役割 3 (= bridge) + AI 役割 5 (= self-analysis) と native 統合、 新 §決定 不要
2. **既存 framework 拡張** = bridge / allowlist / patch-spec / fxp2wav-surge / fxp_template_patch.py 全部再利用
3. **engineering complexity 低** = librosa + scipy = 標準 Python stack、 dependency 軽
4. **legality 軸 clean** = 純 synthesis、 sample derivative narrative risk なし
5. **越川氏 hand-on engineering ゼロ規律維持** = 全 AI/toolchain 化、 WaveEdit GUI 不要
6. **6 drum 種横展開容易** = drum-specific target で再利用、 baseline + search range 共通化

**wavetable route は二次候補 / future enhancement** として保留:
- Option A++ で aesthetic accept に届かない場合に検討
- WaveEdit GUI を 越川氏 hand-on 復活させるリスク回避のため、 wavetable も AI/toolchain 化する architecture を別途検討必要
- sample derivative narrative risk を §決定 14 で明確に境界線引きする ADR update が前提

## 4. ADR-0033 § 決定 27 update 提案 (= 別 commit 候補)

本 investigation 結果を ADR-0033 に反映する場合の wording 候補:

**§決定 27 (1) AI 役割 5 軸 (= rendered audio self-analysis) の拡張:**
- self-analysis 出力を **同時に feature-guided search の optimization loss として再利用** wording 追加
- 「engineering candidate before aesthetic judgement」 軸の **loop 化** narrative

**§決定 27 (5) AI self-analysis 10 項目 wording 維持:**
- waveform / peak / RMS / clipping / silence / attack / decay / transient / spectral / tail = optimization loss の **feature vector component** として再解釈

**§決定 14 sound-alike caution wording 補強:**
- 「target wav は aesthetic reference として feature 経由参照する pattern は OK」 + 「sample byte derivative は NG」 の境界 literal 追加 (= 上記 § 3.4 table 参照)

**新規 §決定 28 候補 (= optional):**
- 「feature-guided parameter search workflow」 を independent §決定 として定義
- + scope-out 明示 = FFT direct inversion / wavetable from existing sample / exact clone

但し: 上記 ADR update は **本 investigation 結果に対する越川氏 review + 採用判断後** に commit (= π9 候補)。 本 commit (= π8) は **investigation のみ**、 ADR 本体は §決定 27 (1) 軸への brief reference 追加程度に留める。

## 5. π9 以降 chain (= recommendation 採用時の implementation roadmap)

- **π9** (= ADR update): §決定 27 (1) AI 役割 5 拡張 wording + §決定 14 reference-inspired vs derivative 境界 wording 追加
- **π10** (= 実装 step 1): `librosa` + `scipy.optimize` 統合 spike = `scripts/feature_search.py` 新規作成、 librosa feature extraction 単独動作確認 + baseline test
- **π11** (= 実装 step 2): feature distance metric 設計 + Kick 909ish.wav vs 2608_bd.wav (= π7 NG) の score 計測 = 「現状 score が高い (= 距離大)」 ことの実証
- **π12** (= 実装 step 3): search loop 実装 = CMA-ES 等で 6-10 continuous parameter search + bridge invoke + render + score 計算の閉ループ + 100 iter 実行 verify
- **π13** (= 実装 step 4): 最適 parameter set で `2608_bd.fxp` 再生成 + fxp2wav-surge render
- **π14**: AI self-analysis 10 項目 + analysis-report.yaml
- **π15**: 越川氏 audition = aesthetic accept gate
- (失敗時): wavetable route 検討、 別 investigation commit

## 6. 関連外部資料

- [Instrumental: Automatic Synthesizer Parameter Recovery (arxiv:2603.15905, March 2026)](https://arxiv.org/html/2603.15905) — CMA-ES + 28-param subtractive、 最も PMDNEO 整合性高い
- [DiffMoog: a Differentiable Modular Synthesizer (arxiv:2401.12570, 2024)](https://arxiv.org/html/2401.12570v1) — differentiable approach reference (= PMDNEO 採用せず、 比較用)
- [Modulation Discovery with DDSP (arxiv:2510.06204, Oct 2025)](https://arxiv.org/html/2510.06204v1) — modulation 推定 reference
- [librosa documentation](https://librosa.org/doc/0.11.0/feature.html) — feature extraction library
- [audiofeat PyPI](https://pypi.org/project/audiofeat/) — alternative feature extraction
- [WaveEdit GitHub](https://github.com/synthesistechnology/waveedit) — wavetable creation GUI (= 二次候補 route)
- [Surge XT wt-tool.py Wiki](https://github.com/surge-synthesizer/surge-synthesizer.github.io/wiki/Creating-Wavetables-For-Surge) — wavetable CLI (= 二次候補 route)
- [Surge XT wavetable creation with WaveEdit Wiki](https://github.com/surge-synthesizer/surge-synthesizer.github.io/wiki/Creating-Wavetables-With-WaveEdit) — workflow reference

## 6. π10 feature extraction spike + Kick 909ish baseline (= 2026-05-17 23rd session π10)

### 6.1 spike script 投入

`scripts/feature_search.py` 新規作成 (= ~340 行、 librosa + scipy + numpy + soundfile 経由):

| subcommand | role | status |
|------------|------|--------|
| `extract <wav>` | 16 feature 抽出 + JSON dump (= --pretty 整形) | **π10 新規動作** |
| `compare <ref> <tgt>` | 2 WAV 比較 + weighted L2 distance + per-feature diff | **π10 新規動作** |
| (future π12) `optimize` | search loop (= CMA-ES / scipy.optimize) | stub なし、 π12 で実装予定 |

16 feature breakdown (= AI self-analysis 10 項目 + 6 補助):
- waveform_sanity (= samples / sample_rate / duration / channels)
- peak_amplitude (linear + dBFS)
- rms_amplitude (linear + dBFS)
- clipping_count
- leading_silence_ms / trailing_silence_ms / tail_length_ms (= 同 semantic redundant)
- attack_ms (= onset → peak)
- decay_1e_ms (= peak → 1/e 減衰までの ms)
- transient_strength (= peak/RMS ratio in first 50ms)
- spectral_centroid_hz
- spectral_flux_mean (= onset_strength avg)
- low_band_ratio (= <500 Hz)
- mid_band_ratio (= 500-2000 Hz)
- high_band_ratio (= >2000 Hz)
- rough_frequency_hz (= librosa.pyin fundamental)

distance metric = weighted L2 (= per-feature relative diff × weight、 weight は preliminary、 π11 で tune)。

### 6.2 Kick 909ish.wav baseline (= BD reference) feature extraction

`python3 scripts/feature_search.py extract ~/Projects/surge-spike/test-assets/kick_909ish.wav --pretty`:

| feature | value | semantic interpretation |
|---------|-------|------------------------|
| peak_amplitude_dbfs | **-4.495** | punchy、 0 dBFS 近接 |
| rms_amplitude_dbfs | -25.879 | moderate energy |
| attack_ms | **5.782** | fast attack = classic BD transient |
| decay_1e_ms | **1.066** | 超絶速 1/e (= snappy transient のみ) |
| transient_strength | 2.799 | clear peak/RMS ratio |
| spectral_centroid_hz | **158.84** | 低域 dominant (= BD characteristic) |
| low_band_ratio | **79.78%** | <500 Hz energy 主体 (= BD fundamental 領域) |
| mid_band_ratio | 17.26% | small mid |
| high_band_ratio | 2.96% | minimal high |
| trailing_silence_ms | **766.236** | sound decays fast、 大部分 silent (= BD らしい short tail) |
| leading_silence_ms | 0.068 | virtually no onset delay |
| rough_frequency_hz | 0.0 | (= pyin pitched 不可、 percussive signal 期待通り) |

**Kick 909ish の BD feature profile 確定** = 低域 dominant + fast attack + fast decay + 高い transient_strength + 短い tail。 残 5 音 (= SD/CYM/HH/TOM/RIM) も将来 reference として同 extraction 経路で baseline 確立可能。

### 6.3 2608_bd.wav (= π5 bridge 生成 NG) 比較 distance metric

`python3 scripts/feature_search.py compare kick_909ish.wav 2608_bd.wav --pretty`:

**distance_score = 39.83** (= weighted L2 normalized、 大差)

per-feature diff (= 主要 abs_diff):

| feature | reference (Kick) | target (2608_bd NG) | abs_diff | engineering 解釈 |
|---------|------------------|---------------------|----------|------------------|
| **attack_ms** | 5.782 | **781.088** | **775.3** | 絶望的差 = envelope 完全 broken (= patch-spec attack_ms=0 passthrough で 1 sec attack 化) |
| **trailing_silence_ms** | 766.236 | **0.0** | **766.2** | **decay 効かず sustain 化** (= patch-spec decay_ms=280 passthrough で 2^280 秒 decay) |
| peak_amplitude_dbfs | -4.495 | **-25.093** | 20.6 dB | **音量不足 20 dB** (= 越川氏 「低音量」 audition と完全一致) |
| rms_amplitude_dbfs | -25.879 | -32.275 | 6.4 dB | overall energy 不足 |
| spectral_centroid_hz | 158.84 | 261.99 | 103.2 Hz | 我々の方が高 (= BD らしくない) |
| spectral_flux_mean | 0.088 | 0.024 | 0.064 | 我々の方が「動き」 少ない (= static sine tone 確認) |
| low_band_ratio | 79.78% | **98.7%** | 18.92% | 我々は 99% 低域 (= filter かかっていない pure sine) |
| mid_band_ratio | 17.26% | 0.27% | 16.99% | mid 領域ほぼ 0 (= filter sweep / drive 不在) |
| high_band_ratio | 2.96% | 1.03% | 1.93% | high 領域も低い |

### 6.4 π10 finding = aesthetic gate と feature distance の方向一致

越川氏 2026-05-17 audition = 「ものすごい低音だけで BD ではない」 と feature distance metric = 主要 5 feature で大差 が **完全方向一致**:

| 越川氏 audition wording | feature evidence |
|-------------------------|------------------|
| 「低音だけ」 | low_band_ratio 99% (= filter 効かず) + spectral_centroid 262 Hz (= 我々は high シフト) |
| 「BD ではない」 | attack 781 ms (= envelope broken) + trailing 0 ms (= decay 効かず 1 sec 鳴り続け) |
| 「音量低い」 | peak -25 dBFS (= 越川氏感覚通り) |

→ **feature extraction layer が aesthetic gate NG を engineering 軸で literal 数値化できることが実証された** = π11+ search loop が aesthetic gate 通過率を高める道筋 (= score 39.83 を 5 以下に下げる方向に parameter search)。

### 6.5 π10 deliverable + π11 以降 chain

deliverable:
- [x] `scripts/feature_search.py` extract + compare 2 subcommand 動作確認
- [x] Kick 909ish.wav baseline feature 確立 (= BD reference profile)
- [x] 2608_bd.wav vs Kick 909ish 比較 = distance score 39.83 + 主要 differ 5 feature
- [x] aesthetic gate ↔ feature distance 方向一致確認
- [x] librosa + scipy install + 単独動作確認

π11 以降 chain:
- **π11**: distance metric tune (= weight 調整 + 各 feature の reasonable threshold 設計)
- **π12**: `optimize` subcommand 実装 = CMA-ES / scipy.optimize で 6-10 continuous parameter search + bridge invoke + render の closed loop
- **π13**: converged params で 2608_bd.fxp 再生成
- **π14**: AI self-analysis report literal (= 16 feature を analysis-report.yaml に format 化)
- **π15**: 越川氏 audition (= aesthetic final gate)

## 7. π11 metric calibration + validate subcommand + analysis-report.yaml schema (= 2026-05-17 23rd session π11)

### 7.1 deliverables

3 件:
- 新規 file: `docs/design/rhythm-patches/synth/feature-rules.yaml` (= 230+ 行、 BD threshold + weight + failure category + analysis-report schema 固定)
- 新規 subcommand: `scripts/feature_search.py validate <wav> [--rules ... ] [--drum-type ... ] [--format yaml|json]` (= per-drum rule 評価 + analysis-report.yaml format 出力)
- helper functions = `_evaluate_criterion` (= rule DSL safe parser、 `value < N` / `A <= value <= B` 等) + `_get_feature_value` (= flat dict + sub-dict 経由 access)

### 7.2 越川氏 directive 初期 5 rule + 補助 2 + π11 追加 1 = 8 rule

越川氏 directive 通り BD-specific threshold + π11 calibration findings 反映の 8 rule:

| # | feature | criterion | severity | discriminator? |
|---|---------|-----------|----------|----------------|
| 1 | attack_ms | `value < 20` | critical | ✓ 強 (K:5.78 / N:781) |
| 2 | peak_amplitude_dbfs | `-6 <= value <= -3` | warning | ✓ (K:-4.5 / N:-25.1) |
| 3 | low_band_ratio | `0.5 <= value <= 0.95` | critical | ✓ (= π11 upper bound 追加で pure sine N:0.987 を catch) |
| 4 | decay_1e_ms | `0.5 <= value <= 500` | warning | × 両方 pass (= range 緩和 + severity 下げ) |
| 5 | clipping_count | `value == 0` | critical | (両方 pass) |
| 6 | spectral_centroid_hz | `value < 500` | warning | (両方 pass) |
| 7 | transient_strength | `value > 2.0` | warning | ✓ borderline (K:2.80 / N:1.997) |
| 8 | **trailing_silence_ms** | `value > 300` | critical | ✓ **最強 (K:766 / N:0)** = π11 新規追加、 sustain 化 detect 軸 |

### 7.3 π11 calibration findings (= rule 初期版から refine の根拠)

**finding 1: `decay_1e_ms` 初期 strict range (= 150-400 ms) が Kick 909ish baseline を fail させた**:
- Kick 909ish.wav decay_1e_ms = 1.066 ms (= transient-heavy 形状、 peak は sharp)
- 1/e measure (= peak から 1/e 振幅まで) は **percussive 音で body decay を反映できず** = transient-only の measure に dominant
- 修正 = range 0.5-500 ms へ緩和 + severity critical → warning へ降下
- 真の sustain 化 detect は別 rule (= trailing_silence_ms) で代替

**finding 2: `low_band_ratio` 初期 lower bound only (= value > 0.5) では pure sine 99% も pass**:
- 2608_bd.wav low_band_ratio = 0.987 = filter / harmonic / transient 不在の pure sine
- 真の BD は OSC harmonic / filter sweep / drive で mid-high にも energy 持つ (= Kick 909ish: low 80% / mid 17% / high 3%)
- 修正 = upper bound 追加 = `0.5 <= value <= 0.95` で pure sine を catch

**finding 3: sustain 化 detect の最強 discriminator = `trailing_silence_ms`**:
- Kick 909ish: trailing 766 ms (= 234 ms sound / 766 ms silence、 BD らしい short tail)
- 2608_bd: trailing 0 ms (= 1 sec 鳴り続け、 sustain 化、 decay envelope 完全 broken)
- 新規 rule = `value > 300` (= 1 sec render で 300 ms 以上 silence あり)
- severity critical、 failure_category = `sustain_化` (= patch-spec passthrough の root cause を直接 categorize)

### 7.4 validate subcommand 動作確認

```bash
$ python3 scripts/feature_search.py validate kick_909ish.wav --drum-type BD
... (= 8 rule 全 PASS)
summary:
  total_rules: 8
  passed: 8
  critical_fails: 0
  warning_fails: 0
  overall_status: engineering_pass
exit code: 0

$ python3 scripts/feature_search.py validate 2608_bd.wav --drum-type BD
... (= 3 critical + 2 warning FAIL)
summary:
  total_rules: 8
  passed: 3
  critical_fails: 3
  warning_fails: 2
  overall_status: engineering_fail
  failure_categories:
    - envelope_broken_attack
    - spectral_imbalance_low
    - sustain_化
    - transient_weak
    - volume_mismatch_peak
exit code: 67
```

→ **Kick 909ish.wav が engineering_pass、 2608_bd.wav が engineering_fail with 5 failure_categories** で **完全 discriminate** 達成、 越川氏 audition と 100% 方向一致。

### 7.5 analysis-report.yaml schema 固定

`feature-rules.yaml` 末尾の `analysis_report_schema` section で literal 固定 (= ν step 4 deliverable と field 共有):

```text
top_level_keys: [metadata, features, rule_evaluation, summary]
metadata_fields: generated_at / generator / input_wav / drum_type / rules_file / rules_version
features_fields: 16 feature (= scripts/feature_search.py extract と同 schema)
rule_evaluation_fields: feature / criterion / actual / passed / severity / failure_category / rationale
summary_fields: total_rules / passed / critical_fails / warning_fails / overall_status / failure_categories
```

これで π14 = AI self-analysis report deliverable が **本 validate subcommand 出力 そのまま** で literal 化可能 = ν step 4 implementation = `feature_search.py validate` invoke + output redirect で 完成。

### 7.6 failure_categories 8 件 + likely_root_cause + fix_axis 分類 literal

`feature-rules.yaml` の `failure_categories` section に 8 category 全部 = description + likely_root_cause + fix_axis literal 化:

| category | likely root cause | fix axis |
|----------|-------------------|----------|
| envelope_broken_attack | attack_ms passthrough 未変換 | unit conversion = log2(sec) |
| envelope_broken_decay | decay_ms passthrough 未変換 (warning) | 同上 |
| **sustain_化** | decay_ms passthrough で天文学的 decay = 1 sec 鳴り続け (= critical、 π11 新規) | unit conversion + a_env1_release も短く |
| volume_mismatch_peak | amp env / drive / OSC level 累積 gain | a_env1 + a_level_o1 + a_volume + a_ws_drive 調整 |
| spectral_imbalance_low | OSC pitch / filter cutoff / osc type 不適切 | a_osc1_octave 下 / cutoff 下 / type = Classic |
| spectral_imbalance_centroid | filter cutoff 高 / OSC harmonic 不適切 | a_filter1_cutoff 下方 |
| transient_weak | attack 緩い / drive 不足 | a_env1_attack 短く / drive 上げ |
| clipping | volume / drive 累積 over | volume 下げ |

→ 各 failure_categories が **具体的 fix axis に対応** = π12 search loop の **per-failure-category guided update** に転用可能。

### 7.7 π12 以降 chain (= search loop 実装着手準備完了)

- **π12**: `optimize` subcommand 実装
  - input = target wav + initial params (= Kick 909ish baseline) + drum rules YAML
  - process = CMA-ES (= `pip install cma`) or scipy.optimize.minimize (= Nelder-Mead) で 6-10 continuous parameter search
  - per iteration = propose params → bridge invoke (= `fxp_template_patch.py patch`) → fxp2wav-surge render → feature distance score → optimizer update
  - max iter ≈ 100、 各 iter ≈ 1-3 sec、 全体 ≈ 5-10 分想定
- **π13**: converged params で 2608_bd.fxp 再生成 + verify-pass via validate subcommand
- **π14**: validate output redirect → `docs/design/rhythm-patches/synth/2608_bd.analysis-report.yaml` 配置 (= ν step 4 deliverable)
- **π15**: 越川氏 aesthetic audition (= final gate)
- **ι commit**: 越川氏 accept 後、 2608_bd_self.adpcma 並行配置 + commit

## 8. π12 black-box optimization loop = engineering_pass 到達 (= 2026-05-17 23rd session π12)

### 8.1 deliverables

3 件:
- `feature-rules.yaml` の `drum_rules.BD` に **`search_space`** 9 continuous parameter literal 追加 (= log-time / log-freq / normalized / dB / semitones の bounds + baseline + scale 注釈)
- `scripts/feature_search.py` に **`optimize`** subcommand 実装 = scipy.optimize.differential_evolution + bridge invoke (= subprocess) + fxp2wav-surge render + feature extract + score の closed loop + trial history + reports 生成
- 1 回 end-to-end run + 2 reports + best .fxp + best .wav 生成

### 8.2 中核 design principle (= user directive、 ADR レベル wording 候補)

**「LLM is not the selector; optimizer is the selector」**:
- LLM (= Claude) は (1) search space 設計 (2) feature weight / rule 設計 (3) failure reason 説明 (4) report 生成 (5) ADR 反映 = 設計 + 説明 + integration 軸
- Optimizer (= scipy.optimize.differential_evolution) は (1) parameter 候補生成 (2) score 最小化 (3) seed 固定 (4) trial history 保存 (5) best candidate 選定 = **数値判定 + 候補選定軸**
- LLM の「良さそう」 判断は **patch 採用には使わない**、 feature distance score + hard gate + fixed seed で deterministic に選定

**「fixed seed + trial history + reproducibility」**:
- random seed = 2608 (= SURGE_RNG_SEED と同値 = render + optimizer 両方 deterministic)
- 全 trial の (params, score) を `optimization-report.yaml` 内 `full_trial_history` に保存
- reproducibility_command literal = 同 command で同結果再現可能

**「machine-checkable engineering gate before human audition」**:
- engineering_pass 条件 = (a) distance_score <= threshold (= 5.0) + (b) validate 8 rules all PASS or critical PASS
- engineering FAIL の candidate は **越川氏 audition に回さない** hard gate
- 越川氏 aesthetic gate (= π15) は engineering_pass 後のみ

### 8.3 search space 設計 (= LLM 役割 (1))

9 continuous parameter (= `feature-rules.yaml drum_rules.BD.search_space` literal):

| element | min | max | baseline (= Kick 909ish) | scale |
|---------|-----|-----|--------------------------|-------|
| a_env1_attack | -12.0 | -3.0 | -8.0 | log-time (= BD attack 1-15 ms 想定) |
| a_env1_decay | -5.0 | 0.0 | -2.089 | log-time (= BD decay 31-1000 ms) |
| a_env1_release | -10.0 | -2.0 | -5.0 | log-time |
| a_env2_decay | -7.0 | -2.0 | -4.716 | log-time (= pitch sweep 期間) |
| a_filter1_cutoff | -60.0 | -5.0 | -40.99 | log-freq |
| a_lowcut | -72.0 | -20.0 | -32.38 | log-freq HPF |
| a_level_noise | 0.0 | 1.0 | 0.55 | normalized |
| a_ws_drive | 0.0 | 10.0 | 3.514 | dB |
| a_osc1_pitch | -12.0 | 0.0 | -1.732 | semitones |

**fixed_baseline = 45 elements** (= Kick 909ish.fxp から allowlist 内 + search space 外 elements = enum/routing 系) を全 trial で applied。

### 8.4 1 回 end-to-end run 実測

```bash
python3 scripts/feature_search.py optimize \
    --template assets/drum_samples/synth/templates/2608_template.fxp \
    --allowlist docs/design/rhythm-patches/synth/parameter-allowlist.yaml \
    --rules docs/design/rhythm-patches/synth/feature-rules.yaml \
    --drum-type BD \
    --target-wav ~/Projects/surge-spike/test-assets/kick_909ish.wav \
    --baseline-fxp ~/Projects/surge-spike/test-assets/kick_909ish.fxp \
    --fxp2wav-bin ~/Projects/surge-spike/surge/build/src/fxp2wav-surge/fxp2wav-surge \
    --output-fxp /tmp/pmdneo_2608_bd_optimized.fxp \
    --output-wav ~/Projects/surge-spike/test-assets/2608_bd.optimized.wav \
    --output-report docs/design/rhythm-patches/synth/2608_bd.optimization-report.yaml \
    --output-analysis-report docs/design/rhythm-patches/synth/2608_bd.analysis-report.yaml \
    --seed 2608 --max-iter 1 --popsize 4 --threshold 5.0
```

**結果:**
- **128 trials / 12 秒 / best score 0.9110** (= π7 NG baseline 39.83 から **43x 改善**)
- **status: `engineering_pass`** ✓
- failure_categories: `[volume_mismatch_peak]` のみ (= warning、 critical 0 件)
- score_histogram: `score<5: 119 / 5-20: 9 / 20-100: 0 / 100+: 0` = 大半の trial が distance threshold 内 (= search space + baseline が reasonable)

### 8.5 best candidate feature 比較 = NG → Optimized → Reference

| feature | NG (= π7 passthrough) | Optimized (= π12 result) | Kick 909ish (= target) |
|---------|------------------------|--------------------------|------------------------|
| peak_amplitude_dbfs | -25.093 | **-15.521** | -4.495 |
| attack_ms | **781.088** | **10.998** | 5.782 |
| decay_1e_ms | 2.993 | 1.95 | 1.066 |
| spectral_centroid_hz | 261.99 | **215.55** | 158.84 |
| low_band_ratio | **0.987** | **0.9021** | 0.7978 |
| trailing_silence_ms | **0.0** | **693.719** | 766.236 |
| transient_strength | 1.997 | **2.094** | 2.799 |

**critical 改善:**
- attack 781 → 11 ms (= envelope 完全修復)
- trailing 0 → 694 ms (= sustain 化 完全解消)
- peak -25 → -15.5 dBFS (= 10 dB up、 まだ target -6〜-3 には届かず = warning only)
- low_band 99% → 90% (= pure sine 緩和)
- spectral centroid 262 → 215 Hz (= 低域寄り)

### 8.6 best params (= optimizer 出力)

```yaml
a_env1_attack: -7.44     # = ~3 ms (baseline -8 から)
a_env1_decay: -1.60      # = ~330 ms (baseline -2.09 から)
a_env1_release: -4.31    # = ~50 ms
a_env2_decay: -2.81      # = ~144 ms
a_filter1_cutoff: -7.42  # = 中位 cutoff (baseline -41 から大変動)
a_lowcut: -54.49         # = 低 HPF
a_level_noise: 0.29      # = 中位 noise mix
a_ws_drive: 7.03         # = 高 drive (baseline 3.5 から大幅up)
a_osc1_pitch: -3.73      # = 4 semitones 下
```

→ optimizer は baseline (= Kick 909ish reference value) から **大幅に動いた** = Kick 909ish と異なる音色 candidate を発見、 但し engineering_pass 規律内。 これは **「reference-inspired」 (= 設計 inspiration) であり「derivative」 ではない** (= §決定 14 補強 5 軸 table 整合) の literal 実証。

### 8.7 deliverable files

| path | role | size |
|------|------|------|
| `docs/design/rhythm-patches/synth/2608_bd.optimization-report.yaml` | π12 deliverable = 全 trial history + best params + reproducibility command | ~55 KB |
| `docs/design/rhythm-patches/synth/2608_bd.analysis-report.yaml` | best candidate validate output (= ν step 4 deliverable format) | ~3.4 KB |
| `/tmp/pmdneo_2608_bd_optimized.fxp` | best candidate .fxp (= ephemeral、 越川氏 accept 後に PMDNEO repo 移動候補) | ~31 KB |
| `~/Projects/surge-spike/test-assets/2608_bd.optimized.wav` | best candidate rendered wav (= 越川氏 audition 用、 external) | 88 KB |

### 8.8 π13+ chain (= 越川氏 audition + ι commit)

- **π13** (= 越川氏 audition): `afplay ~/Projects/surge-spike/test-assets/2608_bd.optimized.wav` で aesthetic gate
  - accept: π14 ι commit へ
  - reject: search space / weight / threshold 再検討 + optimizer 再 run
- **π14** (= ι commit、 越川氏 accept 時): `/tmp/pmdneo_2608_bd_optimized.fxp` → `assets/drum_samples/synth/patches/2608_bd.fxp` (= canonical path、 overwrite NG version) + provenance_chain step_2_fxp update + step_3_wav status 反映
- **π15+**: superctr/adpcm encode (= ν step 8 = `.adpcma` 生成) + 並行配置 + final commit

## 9. π13 metric calibration failure analysis = aesthetic_rejected + metric_v1 retroactive reclassification (= 2026-05-17 23rd session π13)

### 9.1 越川氏 audition 結果 = aesthetic_rejected

π12 で生成した `~/Projects/surge-spike/test-assets/2608_bd.optimized.wav` を 越川氏 audition:

> 越川氏 audition comment literal (= 2026-05-17): 「reference / target の BD と全然似ていない」

**判定 = aesthetic_rejected** = π12 で metric_v1 上 best score 0.911 + validate engineering_pass を達成したが、 **human aesthetic gate を通過していない**。 metric_v1 score 改善と human audition 判断が **乖離**。

### 9.2 重要 design lesson (= ADR レベル wording 追加)

π12 結果が aesthetic で reject されたことから 3 件の literal wording 確立:

| wording | meaning |
|---------|---------|
| **「optimizer is also not the final selector」** | LLM だけでなく optimizer も final 選定権限なし、 越川氏 audition が最終 gate |
| **「human aesthetic gate is authoritative」** | metric pass / score / validate result は necessary but not sufficient、 越川氏 judgement が ground truth |
| **「metric pass ≠ aesthetic pass」** | metric は **versioning** 軸で iterate、 各 version で audition correlation check 経由 verify、 v1 で reject なら v2 へ |

これらは ν 「acceptance is downstream」 → ξ 「越川氏 hand-on engineering ゼロ」 → π 「越川氏 aesthetic final gate」 chain の **literal 強化** (= π13 evidence 反映)。

### 9.3 wording 規律 = aesthetic 含意の有無を厳密分離

π12 と π13 を切り分ける wording 規律:

| 言ってよい (= engineering 軸 only) | 言わない (= aesthetic 含意) |
|------------------------------------|---------------------------|
| "current metric (= weighted L2 v1) decreased from 39.83 to 0.911" | "近づいた" |
| "score histogram: 119 trials with score < 5" | "BD に類似" |
| "validate 8 rules passed with 1 warning" | "似ている" |
| "engineering metric pass v1" | "engineering_pass" (= aesthetic 含意あり) |
| "metric_v1 と human audition が乖離" | "後一歩で aesthetic pass" |
| "feature distance reduction" | "BD らしさが出てきた" |

「engineering metric pass」 は **aesthetic 軸を保証しない数値結果のみ** を意味する、 metric の subscript (= v1 / v2 ...) を必ず添える。

### 9.4 metric_v1 (= π10-12) の limitation 分析 = aesthetic 不一致 root cause

metric_v1 = 16 feature の weighted L2 + 8 rule validate gate。 audition reject から逆算した **不足 feature 軸**:

| 軸 | metric_v1 でカバー | metric_v1 で不在 | 重要度推定 |
|----|---------------------|------------------|-----------|
| static peak / RMS | ✓ | - | 中 (= 越川氏 audition で volume 軸言及あったが root cause ではない) |
| static spectral centroid / band ratio | ✓ | - | 中 (= 低域 dominance OK だったが BD らしさ不足) |
| envelope shape (= attack / decay 1/e / trailing silence) | ✓ | - | 中 |
| **time-varying spectral envelope** | - | ✗ | **高** (= drum 音色 character の中核、 静的 centroid では不十分) |
| **MFCC / log-mel** | - | ✗ | **高** (= perceptual 軸 (= human ear bark / mel scale) を encode、 spectral centroid + band ratio より perception 近) |
| **onset envelope detail** | - | ✗ (= 単一 onset detection あり) | 中-高 (= attack 直後の transient detail) |
| **perceptual loudness (= LUFS)** | - | ✗ (= peak/RMS のみ) | 中-高 (= subjective loudness != peak dBFS、 ITU-R BS.1770 等) |
| pitch tracking | ✓ (= pyin) | - | 中 (= percussive で pyin 信頼性低) |
| transient strength (= peak/RMS in 50 ms) | ✓ | - | 中 |
| polyphonic content / inharmonic | - | ✗ | 中 (= drum は inharmonic 中心、 sine osc 軸で抜けやすい) |

**結論**: metric_v1 は **static feature 中心**、 time-varying / perceptual 軸を欠く = **drum 音色の core を捉えきれない** = aesthetic 軸と乖離。

### 9.5 metric_v2 calibration 計画 (= π14+ 着手予定)

**追加予定 feature** (= metric_v2 計算 layer):

| feature | librosa function | rationale |
|---------|------------------|-----------|
| MFCC (= 13 coeff) | `librosa.feature.mfcc()` | perceptual cepstral 表現、 timbre 軸の標準 |
| log-mel spectrogram | `librosa.feature.melspectrogram()` + log | time-varying spectral envelope、 drum 音色 core |
| onset envelope time-series | `librosa.onset.onset_strength(aggregate=np.mean)` (= time series) | attack detail + transient shape |
| time-varying spectral flux | `librosa.onset.onset_strength()` (= per-frame) | spectral motion 軸 |
| perceptual loudness (= LUFS) | `pyloudnorm.Meter().integrated_loudness()` (= 外部 dep) | ITU-R BS.1770、 subjective loudness |
| spectral contrast | `librosa.feature.spectral_contrast()` | tonal vs noise 軸、 drum で重要 |

**distance metric refinement**:
- 静的 feature L2 + **時系列 feature の DTW (= dynamic time warping) or Euclidean per-frame** で時系列軸 加算
- weight 再設計 = audition correlation check で empirical tuning

### 9.6 「human audition correlation check」 methodology = optimize 着手前必須 gate

metric_v2 が aesthetic と相関するか **optimize 実行前に literal verify**:

1. N candidate (= 5-10 件) を hand-craft / random sample で生成 = parameter space の dispersion 確保
2. 越川氏 audition で各 candidate を aesthetic score (= 1-5 or thumbs up/down) 評価
3. metric_v2 で各 candidate の score 計算
4. Spearman correlation = metric_v2 score と human aesthetic score の rank correlation
5. **correlation > 0.7 (= 仮 threshold) なら metric_v2 採用、 optimize 実行 OK**
6. correlation < 0.7 なら metric_v2 design 修正、 audition + correlation check を loop

この pre-check 経由で 「optimize 実行 → audition で reject → metric の問題 retro 認識」 という π12 pattern を **prevent**。 metric の aesthetic 整合性が optimize 前に verify される。

### 9.7 π14+ chain (= metric_v2 着手 + 再 optimize)

- **π14** (= metric_v2 spike 実装): `scripts/feature_search.py` に新 feature extraction = MFCC + log-mel + onset env + LUFS + spectral_contrast + time-varying flux 追加、 feature dict 拡張、 `feature-rules-v2.yaml` (= 新 file) で weight 再設計
- **π15** (= human audition correlation check): N=5-8 candidate を hand-craft + 越川氏 audition で aesthetic score 取得 + metric_v2 score 計算 + Spearman correlation verify
- **π16** (= correlation > 0.7 達成時): metric_v2 で optimize 再 run = `scripts/feature_search.py optimize --rules feature-rules-v2.yaml`
- **π17**: 新 best candidate の 越川氏 audition (= aesthetic gate)
- **π17 reject 時**: metric_v3 へ iteration、 または target / search space / weight 再壁打ち
- **π17 accept 時**: ι commit (= canonical asset 化)

### 9.8 π12 の正しい treatment

π12 (= commit 4ab5fc0) の re-framing:

- **status**: `aesthetic_rejected` (= NOT `engineering_pass`)
- **literal milestone**: 「black-box optimization loop works mechanically, but metric_v1 failed to predict human judgement」
- **deliverable value**: trial history + 2 reports = 「metric_v1 の limitation evidence」 として保存、 metric_v2 設計の base data
- **2608_bd.optimized.wav**: rejected candidate (= aesthetic 軸で却下、 削除はしないが asset として採用しない)
- **NOT accepted candidate** (= canonical `2608_bd.fxp` への昇格は不適)
- 2608_bd.optimization-report.yaml + analysis-report.yaml = `aesthetic_audition.status: rejected` + `metric_calibration_status.v1_status: aesthetic_uncorrelated` を追記済 (= 本 commit)
- 既存 `assets/drum_samples/synth/patches/2608_bd.fxp` (= π5 NG version) は維持 (= overwrite せず、 metric_v2 calibration 完了後の再 optimize で再判断)

## 10. π14 metric_v2 feature extraction + audition-check + N=8 candidate generation (= 2026-05-17 23rd session π14)

### 10.1 deliverables (= 越川氏 π14 directive 通り)

5 件:
- `scripts/feature_search.py extract_features()` に **v2 feature 10 件追加** = MFCC mean/std (= 13 coeff list × 2) + log-mel mean/std (= 13 mel bands list × 2) + onset_strength mean/std/peak (= 3 scalar) + spectral_contrast_mean (= 7 bands list) + spectral_flux_std (= 1 scalar) + lufs_integrated (= 1 scalar)
- `_compute_distance_score` を **vector feature 対応に拡張** (= list of floats を L2 vector distance、 target norm で normalize、 既存 scalar feature handling と共存)
- `feature-rules-v2.yaml` 新規 = v1 thresholds 維持 + v2 distance_weights (= mfcc 3.0 / log_mel 2.5 / spectral_contrast 2.0 / lufs 1.5 等)
- `scripts/feature_search.py` に **`audition-check` subcommand** 新規 = audition-input.yaml + `--scores "5,1,4,3,..." --threshold 0.7` で Spearman correlation 計算 + verdict + audition-output.yaml 生成
- **N=8 candidate wav 生成** + `audition-input.yaml` 越川氏 scoring template

### 10.2 metric_v2 feature 追加 (= librosa + pyloudnorm)

```python
# v1 (= scalar、 static aggregates) は維持
# v2 (= time-varying + perceptual) 追加:
mfcc_mean: list[13]       # = librosa.feature.mfcc per coeff mean
mfcc_std: list[13]        # = per coeff std
log_mel_mean: list[13]    # = librosa.feature.melspectrogram per band mean (log scale)
log_mel_std: list[13]     # = per band std
onset_strength_mean: float
onset_strength_std: float
onset_strength_peak: float
spectral_contrast_mean: list[7]   # = librosa.feature.spectral_contrast per band mean
spectral_flux_std: float
lufs_integrated: float    # = pyloudnorm.Meter().integrated_loudness (= ITU-R BS.1770)
```

dependencies: librosa 0.11.0 (= π10 install 済) + pyloudnorm 0.1.1 (= π14 新規 install)。

### 10.3 distance metric = vector feature 対応

`_compute_distance_score(candidate, target, weights)` を拡張:

- **scalar features** (= int/float): `rel = (a - b) / max(|a|, 1)` の単純相対差
- **vector features** (= list of floats): `rel = sqrt(sum((a_i - b_i)^2)) / max(sqrt(sum(a_i^2)), 1)` = L2 vector distance / target L2 norm で normalize
- 統合: `weighted_sq = w_i × rel^2` の累積、 最終 score = `sqrt(weighted_sq / weight_sum)`

これで MFCC (= 13 dim) も log-mel (= 13 dim) も spectral_contrast (= 7 dim) も group weight 1 個で扱える。

### 10.4 8 candidate generation = audition pool 設計

audition pool 構成 (= ~/Projects/surge-spike/test-assets/audition_candidates/):

| id | wav | source | 期待 human score (= Claude 予想、 ground truth は越川氏 audition) |
|----|-----|--------|------------------------------------------------------------------|
| candidate_01 | kick_909ish target render の copy | target_reference | 5 (= anchor) |
| candidate_02 | π5 passthrough NG render の copy | pi5_passthrough_ng | 1 (= 既聴) |
| candidate_03 | hand-crafted typical BD (= attack -10 / decay -1.7 / filter -30 / drive 4) | hand_crafted | (= 越川氏判断) |
| candidate_04 | hand-crafted snappy BD (= attack -11 / decay -3 / filter -20 / drive 6) | hand_crafted | (= 越川氏判断) |
| candidate_05 | hand-crafted deep BD (= attack -8 / decay -0.5 / filter -50 / drive 1) | hand_crafted | (= 越川氏判断) |
| candidate_06 | hand-crafted midrange BD (= attack -9 / decay -2 / filter -35 / drive 3) | hand_crafted | (= 越川氏判断) |
| candidate_07 | random sample seed=2608 | random_sample | (= 越川氏判断) |
| candidate_08 | random sample seed=31337 | random_sample | (= 越川氏判断) |

各 candidate の sha256 + parameter 値は `audition-input.yaml` に literal 記録。

### 10.5 audition-check subcommand 動作

dummy run (= Claude が予想した scores `5,1,4,3,3,4,2,2` で動作確認):

```json
{
  "spearman_r": -0.788,        // ← negative = correct direction (= human 高 = metric 低)
  "abs_r": 0.788,
  "threshold": 0.7,
  "abs_r_pass": true,
  "sign_correct": true,
  "verdict": "metric_v2 correlates with human audition (= |r| > threshold) → π16 optimize 着手可"
}
```

→ subcommand 動作確認 OK。 但し **越川氏 実 audition で異なる scores になる可能性大** = 上記 dummy は Claude 予想、 ground truth は越川氏。

exit code:
- 0 = correlation_pass (= |r| > 0.7 + 負方向)
- 68 = correlation_fail (= 0.7 未満 or 符号 inverted)

### 10.6 越川氏 π15 audition + scoring 手順

```bash
# 1. 試聴 (= 8 candidate を順番に afplay、 各 1 sec)
for i in 01 02 03 04 05 06 07 08; do
    echo "=== candidate_$i ==="
    afplay ~/Projects/surge-spike/test-assets/audition_candidates/candidate_$i.wav
    sleep 1
done

# 2. 採点 (= 1-5 score per candidate)
#    1 = BD として全く不可
#    2 = BD っぽさは少しあるが採用不可
#    3 = 方向性はあるが要改善
#    4 = かなり良い、 採用候補
#    5 = PMDNEO BD として採用可能

# 3. 採点結果 (= scores) を Claude に渡す
#    例: "5,1,3,2,3,3,1,1"

# 4. Claude 側で audition-check invoke
python3 scripts/feature_search.py audition-check \
    docs/design/rhythm-patches/synth/audition-input.yaml \
    --scores "<8 scores comma-separated>" \
    --threshold 0.7 \
    --output docs/design/rhythm-patches/synth/audition-output.yaml
```

### 10.7 「human audition correlation check」 = optimize 前 hard gate

correlation 判定:
- **PASS** (= |r| > 0.7 + r < 0): metric_v2 が aesthetic と相関 = π16 optimize 着手可
- **FAIL** (= |r| < 0.7 or r > 0): metric_v3 calibration へ戻し
  - feature 追加 (= 例 spectral_rolloff / chroma / tempo)
  - weight 再設計
  - threshold 再評価
  - π15 audition 再実施

これで 「数値は良いのに耳では違う」 (= π12 pattern) を **optimize 実行前に detect** 可能。

### 10.8 wording 規律 (= π13 確立分の遵守確認)

本 commit で使用する wording:
- ✓ 「current metric correlation = 0.XX」
- ✓ 「metric_v2 calibration draft」
- ✓ 「audition correlation check 前段」
- ✗ 「metric_v2 が aesthetic を捉えた」 (= aesthetic 含意あり、 越川氏 verify 前)
- ✗ 「reference に近接」 (= aesthetic 含意)

### 10.9 π15 以降 chain (= 越川氏 audition + correlation 判定後)

- **π15** (= 越川氏 audition、 user-side work): 8 candidate scoring + Claude へ scores 共有
- **π15.5** (= Claude、 user 採点後): audition-check 実行 + audition-output.yaml 生成 + 判定報告
- **π16** (= correlation PASS なら): metric_v2 で optimize 再 run = `scripts/feature_search.py optimize --rules feature-rules-v2.yaml`
- **π16** (= correlation FAIL なら): metric_v3 design + π15 再 audition、 feature 追加 / weight tune iterate
- **π17**: 越川氏 audition (= final gate)、 accept → ι commit / reject → metric_vN+1 へ

## 11. π15 directive shift = metric correlation → human preference learning (= 2026-05-17 23rd session π15)

### 11.1 越川氏 directive 反映 = π14 plan was insufficient

π14 で提案した audition correlation check (= 1-5 absolute score + Spearman correlation) は **metric calibration only** であり、 越川氏 aesthetic preference の **学習** にはならない。 π15 directive で軸転換:

> 越川氏 directive (2026-05-17): 「feature matching alone does not model human aesthetic preference / metric correlation is not preference learning」

旧 plan (= π14):
* candidate 1-5 score → metric score の Spearman correlation
* correlation > 0.7 で metric_v2 採用 → optimize 再 run
* 中核問題 = metric が target feature に correlate しても aesthetic preference は不明、 越川氏 何を好むかは別軸

新 plan (= π15):
* pairwise comparison (= A vs B) + reject label による preference data 収集
* logistic pairwise ranking で preference model 学習
* model は **越川氏 が何を好むか** を generalizable form で encode、 新 candidate にも predict 可能
* optimizer objective に preference model output を統合 (= feature distance だけでなく predicted human preference も最小化対象)

### 11.2 deliverables (= π15、 docs + 軽量 implementation)

3 件:
- `scripts/feature_search.py` に **`preference-learn` subcommand** 新規 +204 行 = sklearn LogisticRegression on pairwise feature differences + reject label expansion + per-candidate predicted preference + feature importance top5 + standardization
- `docs/design/rhythm-patches/synth/preference-input.yaml` 新規 = 8 candidate × 28 pairs all enumerate + reject section + 越川氏 input flow literal
- preference-model-report.yaml schema (= preference-learn 出力先) = metadata + dataset_summary + model_quality + candidate_predicted_preference + feature_importance_top5 + training_pairs + scaler_params + model_coefficients + next_step_options

### 11.3 logistic pairwise ranking model 設計

**alternatives 検討:**
- Bradley-Terry (= classical 単純、 但し new candidate に generalize 不可)
- **logistic pairwise ranking** (= feature difference を入力に LogisticRegression、 採用)
- preference regression (= 直接 score 予測、 absolute score 必要で π15 directive (= pairwise only) と整合せず)
- Bayesian optimization with human feedback (= 重い、 軽量初期実装の趣旨外れ)

**logistic pairwise ranking 採用根拠:**
- pairwise だけで学習可能 (= 越川氏 directive 整合)
- new candidate に generalize 可能 (= optimizer 統合の前提)
- 線形 model = interpretable + 過学習 risk 低
- sklearn 標準、 軽量

**学習 protocol:**

```python
# For each pair "A > B":
#   X[i]   = features(A) - features(B), y[i]   = 1  (= A wins)
#   X[i+1] = features(B) - features(A), y[i+1] = 0  (= B loses、 mirror)
# Rejected: each non-rejected candidate beats rejected (= multiple pairs added)
# Standardize features (= StandardScaler)
# Fit LogisticRegression(C=1.0)
# Predict: σ(W · (candidate - neutral)) = probability of being preferred over neutral mean
```

**feature set = scalar 20 dim** (= robust to overfitting):
- peak_amplitude_dbfs / rms_amplitude_dbfs / clipping_count
- leading_silence_ms / trailing_silence_ms / tail_length_ms
- attack_ms / decay_1e_ms / transient_strength
- spectral_centroid_hz / spectral_flux_mean
- low_band_ratio / mid_band_ratio / high_band_ratio
- rough_frequency_hz
- onset_strength_mean / std / peak
- spectral_flux_std / lufs_integrated

vector feature (= MFCC / log-mel / spectral_contrast) は **preference learning v2** で検討、 v1 では scalar 軸のみで model robustness 確保。

### 11.4 越川氏 π15 input flow

```bash
# 1. 8 candidate を試聴 (= 既存 audition_candidates/、 π14 で生成済)
for i in 01 02 03 04 05 06 07 08; do
    echo "=== candidate_$i ==="
    afplay ~/Projects/surge-spike/test-assets/audition_candidates/candidate_$i.wav
    sleep 1
done

# 2. preference-input.yaml の pairs section を直接編集:
#    各 pair の preference field に "A" / "B" / "tie" のいずれかを記入
#    20 pair 程度で十分 (= 28 全 pair 可能なら最強)

# 3. rejected section に「明らかに BD として不可」 candidate を追加 (= optional):
#    rejected: ["candidate_02", "candidate_08"]  # = 例

# 4. Claude 側で preference-learn invoke (= π15.5):
python3 scripts/feature_search.py preference-learn \
    docs/design/rhythm-patches/synth/preference-input.yaml \
    --output docs/design/rhythm-patches/synth/preference-model-report.yaml
```

### 11.5 dummy run 動作確認

11 pair + 1 reject (= 7 pair 暗黙追加) = 18 pair × 2 mirror = 36 training samples:
- train_accuracy: 1.0 (= dummy data なので perfectly separable、 越川氏実 audition で <1.0 想定)
- ranking (= best first): candidate_01 > 03 > 04 > 06 > 05 > 07 > 02 > 08
- top feature: spectral_flux_mean (= dummy preference data の bias 反映、 越川氏実 data で異なる feature 想定)

= subcommand 動作 OK、 越川氏 実 data で training を実施する flow 確立。

### 11.6 中核 wording 規律 (= π15 ADR §決定 27 (12) 追加)

5 件:
- 「**feature matching alone does not model human aesthetic preference**」 (= metric distance ≠ preference)
- 「**metric correlation is not preference learning**」 (= π14 plan の限界明示)
- 「**human preference is the primary objective**」 (= optimize objective の中核)
- 「**feature distance is auxiliary**」 (= preference model に対する補助軸)
- 「**optimizer is not final selector; preference model is also not final selector**」 (= 越川氏 final gate 維持、 π13 ADR wording 拡張)

### 11.7 next_step (= 越川氏 audition + π15.5 chain)

- **π15** (= 越川氏、 user-side): preference-input.yaml の pairs に "A"/"B"/"tie" 記入 + rejected list 編集
- **π15.5** (= Claude、 user 完了後): preference-learn invoke + preference-model-report.yaml 生成 + 結果 報告
- **π16** (= preference model 学習成功時): optimize objective に preference model 統合検討 (= score = α × feature_distance + β × (1 - predicted_preference))
- **π17**: 越川氏 audition (= final gate)、 accept → ι commit / reject → preference data 拡充 + 再学習

### 11.8 π14 retroactive treatment = audition-check は v1 retroactive

π14 で実装した `audition-check` subcommand (= 1-5 score + Spearman) は **retroactively v1** label:
- 削除はしない (= backward compat、 metric calibration 用途で再利用余地)
- `feature_search.py audition-check` help text に「retroactively replaced by preference-learn in π15」 明示
- π15 で primary path は **preference-learn**

audition-input.yaml は **v1 audition input** retroactive label、 preference-input.yaml が π15 primary。

## 12. scope-out 維持 (= 本 investigation の意図)

- **driver / runtime / fixture / verify script** 完全不変 (= 23rd session 既存 23 commit 規律維持)
- **external spike repo** = 参照のみ、 PMDNEO repo に取り込まない (= §決定 25 ι'' 維持)
- **exact clone / ROM recreation / sample extraction** 方向は永久 scope-out (= §決定 14 / 1 / 2 維持)
- 本 commit (= π8 investigation) は **document only**、 librosa / scipy import や script 作成は π10 以降
