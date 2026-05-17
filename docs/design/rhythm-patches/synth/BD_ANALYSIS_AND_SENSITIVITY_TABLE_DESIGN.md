# BD one-shot 解析と parameter sensitivity table の設計提案

- 状態: Grok による設計提案（2026-05-17）
- 対象: Surge XT .fxp を用いた 2608_BD.wav 再現調査
- 焦点: 解析方法と対応表の設計のみ（最適化アルゴリズムは除外）
- 根拠: 既存 PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md を基に、deterministic で authoring に使える形に整理

## 1. 全体方針

解析の目的は「score を良くすること」ではなく、
「2608_BD.wav の音響的特徴を deterministic に記述し、
その特徴が Surge XT のどの parameter でどう変わるかを対応表として残すこと」です。

これにより、.fxp authoring 時に「この parameter をこの方向に動かせば、pitch drop が強まる」といった説明可能な知識が得られます。

human audition が最終判断であることを常に前提とし、解析結果はあくまで diagnostic aid として扱います。

## 2. 推奨解析 feature set

BD one-shot に特化して、以下の feature を2層で保存します。

### 2.1 scalar feature（要約・sanity check 用）

- attack_ms: 立ち上がり時間（onset から RMS peak までの時間）
- decay_1e_ms: RMS が初期値の 1/e になるまでの時間
- tail_length_ms: RMS が -60dB を下回るまでの時間
- peak_dbfs / rms_dbfs / integrated_lufs
- low_band_ratio (0-200Hz), mid_band_ratio (200-2000Hz), high_band_ratio (2000Hz-)
- rough_body_frequency_hz: 低域ピーク周波数
- spectral_centroid_mean

これらは速く計算でき、異常 candidate の除外に有効です。

### 2.2 time-series feature（時間変化を捉える主軸）

- rms_envelope: hop_length=512 で計算した RMS 時系列
- onset_envelope: librosa.onset.onset_strength
- low_band_energy_envelope: 0-200Hz 帯域のエネルギー時系列
- pitch_contour: pyin による frame-wise f0（fmin=30, voiced/unvoiced フラグ付き）
- spectral_contrast: 低域・高域のコントラスト時系列
- log_mel_spectrogram: 低解像度（n_mels=32）で保存

time-series は固定時間グリッドで保存し、target と candidate を直接比較可能にします。

## 3. feature ごとの目的・実装・限界

- attack_ms / onset_envelope  
  目的: クリックや transient の強さを定量  
  実装: librosa.onset + peak detection  
  限界: hop length が粗いと 10ms 以下の差が埋もれる → hop=256 または 512 を固定

- decay_1e_ms / rms_envelope  
  目的: 胴鳴りの減衰特性と tail の長さ  
  実装: RMS を計算し線形補間で 1/e 到達点を求める  
  限界: sustain 成分が多いと tail_length と重複 → 両方を併用

- pitch_contour  
  目的: body pitch の高さと pitch drop の再現度  
  実装: librosa.pyin（低域重視）  
  限界: ノイズが多いと voiced 判定が不安定 → voiced フラグを明示的に保存

- low/mid/high band ratio + spectral_contrast  
  目的: スペクトルバランスと noise/click 成分の分離  
  実装: バンドパスフィルタ + energy 計算  
  限界: 絶対値ではなく「baseline からの変化量」で解釈する

- LUFS  
  目的: 音量差による誤った比較を防ぐ  
  実装: pyloudnorm  
  限界: 最終判断ではないので補助情報として扱う

## 4. parameter sensitivity table の設計

### 4.1 基本 protocol

- baseline .fxp を1つ固定
- 1 parameter だけを変化（one-factor-at-a-time）
- 固定 render 条件で WAV を生成
- 同じ解析 pipeline で feature を抽出
- baseline との delta を記録
- human-readable effect label を付与

これを繰り返し、表として蓄積します。

### 4.2 初期対象 parameter（優先度順）

1. a_env1_attack（onset / transient）
2. a_env1_decay（body decay）
3. a_env1_release（tail / sustain）
4. a_osc1_pitch / a_osc1_octave（body pitch）
5. a_level_noise（click / noise transient）
6. a_ws_drive（punch / saturation）
7. a_filter1_cutoff / a_lowcut（スペクトルバランス）
8. a_env2_decay（pitch/filter envelope）

enum や routing は効果が大きいため、別途定性表として扱う。

### 4.3 記録する情報

各 sweep で以下を保存:
- parameter 名と変化値
- wav_sha256
- analysis_sha256
- scalar_delta（attack_ms_delta, decay_1e_ms_delta など）
- time_series_summary（例: pitch_drop_amount, tail_energy_ratio）
- effect_summary（primary: shorter_decay, secondary: lower_loudness）

## 5. YAML / CSV schema 案

### 5.1 analysis result（1 WAV あたり）

analysis-scalar.yaml:
- render_condition（固定値）
- scalar_features（上記一覧）
- sha256_of_source_wav

analysis-timeseries.npz:
- rms_envelope, pitch_contour, low_band_energy など key-value で保存

### 5.2 sensitivity table

sensitivity-table.yaml:
- schema_version: "0.2.0"
- baseline:
    fxp: ...
    analysis_sha256: ...
- sweeps:
    - parameter: a_env1_decay
      baseline_value: -2.089
      observations:
        - value: -5.0
          feature_delta:
            decay_1e_ms: -118.2
            tail_length_ms: -85.0
          effect_summary:
            primary: shorter_decay
            secondary: [lower_loudness, faster_pitch_drop]

CSV 版は上記を flatten した形で出力し、表計算ソフトで確認しやすくする。

## 6. 実装時の注意点（deterministic 確保）

- librosa / scipy の全パラメータ（hop_length, frame_length, center, fmin など）を明示的に固定
- 同一 WAV を 5 回解析して SHA256 が完全に一致することを検証
- render 時の seed、duration、trim ルールを literal で固定
- leading silence は自動検出せず、render 時に 0 で統一
- time-series は固定長（例: 800ms / hop で決まる frame 数）に揃えて保存

## 7. やるべきでないこと

- 解析結果だけで candidate を accept / reject する
- optimizer や自動探索をこの段階で導入する
- target WAV の sample を直接利用する
- human audition を置き換える metric を最終判断にする
- 相互作用を無視して全 parameter を同時に sweep する

## 8. 推奨する進め方

1. analysis extractor を deterministic に出力する形に整備
2. 既存 2608_BD.wav で repeatability を確認（SHA256 一致）
3. 初期 8 parameter で one-factor sweep を実行
4. sensitivity table を YAML/CSV で保存
5. 得られた表を基に .fxp authoring の指針を文書化

この設計により、解析データがそのまま authoring 知識として蓄積されていきます。

---
作成: Grok（xAI）
参考: PARAMETER_SENSITIVITY_AND_ANALYSIS_DESIGN.md
