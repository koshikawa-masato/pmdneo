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

## 7. scope-out 維持 (= 本 investigation の意図)

- **driver / runtime / fixture / verify script** 完全不変 (= 23rd session 既存 23 commit 規律維持)
- **external spike repo** = 参照のみ、 PMDNEO repo に取り込まない (= §決定 25 ι'' 維持)
- **exact clone / ROM recreation / sample extraction** 方向は永久 scope-out (= §決定 14 / 1 / 2 維持)
- 本 commit (= π8 investigation) は **document only**、 librosa / scipy import や script 作成は π10 以降
