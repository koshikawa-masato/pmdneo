# PMDDotNET 音色パラメータ検証 reference

PMDNEO 自前 driver の検証 dataset。 PMDDotNET → pmdplay 経路で取得した「期待 WAV 数値」 を保存。

## 使い方

PMDNEO 自前 driver で同 MML を再生 → WAV 録音 → 本 reference の RMS/peak/spectrum 期待値と比較。 一致すれば functional 等価。

## 共通条件

- base template: `../TEMPLATE-Bscale.mml` (= scale `o5l4 cdefgab>c`)
- 録音: `pmdplay -w out.wav -s 5 out.M`
- 計測: `scipy.io.wavfile` + numpy で RMS / peak / FFT (= int16 stereo、 L channel)
- 環境: dotnet 7.0.311 + PMDDotNETConsole.dll + pmdplay SDL 2022-07-26
- compile: `dotnet PMDDotNETConsole.dll /v /C foo.mml` (= /C 必須)

## MML pattern 設計指針

- **TL** (= 音量検証) → scale + loop で OK (= 全体 RMS で測定容易)
- **AR/DR/SR/RR** (= envelope 検証) → 単音 long note + **loop なし** で 1 note の attack/sustain/release 完全観察
- **ML/alg/fbl** (= 倍音検証) → 単音 long note (loop あり/なしどちらでも FFT robust)
- 共通: setup `@1v10q6` (= alg=0、 op4 carrier、 base @1)

## tl-step/ — TL (Total Level) 段階検証

**目的**: alg=0 op4 carrier の TL 段階変動、 OPN 仕様 0.75 dB/step の検証。

**改変**: `@001 000 005` ブロックの op4 行 (= 6 行目の TL 列、 0-indexed 5)。 melody = scale + loop あり (= 通常の template)。

| file | TL | RMS | peak | 倍率 | dB | dB/step |
|---|---|---|---|---|---|---|
| voice-tl-00.mml | 0 | 661.9 | 2042 | 1.0000 | 0.00 | base |
| voice-tl-10.mml | 10 | 278.3 | 858 | 0.4204 | -7.53 | -0.7527 |
| voice-tl-20.mml | 20 | 116.9 | 361 | 0.1767 | -15.06 | -0.7528 |
| voice-tl-40.mml | 40 | 20.6 | 63 | 0.0311 | -30.14 | -0.7536 |

→ 仕様 -0.75 dB/step、 実測 -0.7527 dB/step、 誤差 < 0.5%、 4 段階一致

## ar-step/ — AR (Attack Rate) 段階検証

**目的**: alg=0 op4 carrier の AR 段階変動、 OPN AR 指数特性の envelope follower 検証。

**改変**: op4 行の AR (= 1 列目)、 melody = `B\to5l1 c` (= 単音全音符)、 **L cmd 削除 (= loop なし)** で 1 note 完結。

期待値 (= 100ms 刻み RMS、 0-1.6 sec 範囲、 1.6 sec 以降は確実に silent=0):

| AR | 0-100 | 100-200 | 200-300 | 300-400 | 500-600 | 1000-1100 | 観察 |
|---|---|---|---|---|---|---|---|
| 31 | 763 | 794 | 708 | 702 | 610 | 783 | 即立ち上がり |
| 16 | 804 | 794 | 708 | 702 | 610 | 783 | 100ms で完結 |
| 8 | 1 | 40 | 205 | 563 | 1028 | 783 | 約 1 sec で完結 |
| 4 | 1 | 1 | 1 | 4 | 20 | 290 | 数 sec、 5 sec 内未完結 |

→ AR は OPN 指数特性 (= +8 で attack 約 1/16)、 envelope follower (50ms-100ms 刻み RMS) で判別可能

## dr-step/ — DR (Decay Rate) 段階検証

**目的**: AR=31 (即立ち上がり) 後の peak → SL plateau 形成過程を観察。

**改変**: op4 行の DR (= 2 列目)、 AR=31 固定、 SL=2 (base @1)、 melody = `B\to5l1 c`、 loop なし。

期待値 (= 100ms 刻み RMS):

| DR | 0-100 | 100-200 | 200-300 | 500-600 | 1000-1100 | 観察 |
|---|---|---|---|---|---|---|
| 31 | 685 | 794 | 708 | 610 | 783 | 即 SL plateau |
| 15 | 903 | 794 | 708 | 610 | 783 | 短期で plateau |
| 8 | 1296 | 1352 | 1078 | 650 | 783 | 約 0.5 sec で plateau |
| 4 | 1344 | 1520 | 1317 | 1038 | 1183 | 緩やか減衰 (5 sec 内 plateau 未達) |

→ DR は OPN 指数特性 (= +8 で減衰時間 約 1/16)、 plateau 形成形状で判別

## ml-step/ — ML (Multiple) 段階検証

**目的**: alg=0 op4 carrier の ML 段階変動、 carrier 周波数倍化を FFT で検証。

**改変**: op4 行の ML (= 8 列目、 0-indexed 7)、 melody = `B\to5l1 c` (= o5 c = PMD 基準で 261 Hz)。

FFT 主要 peak (= 0.5-2.0 sec sustain 期間):

| ML | 期待周波数 (= 261 Hz × ML) | 実測 主要 peak | 一致 |
|---|---|---|---|
| 1 | 261 Hz | 261 Hz | ✅ |
| 2 | 523 Hz | 523 Hz | ✅ |
| 4 | 1047 Hz | 1047 Hz | ✅ |
| 8 | 2095 Hz | 2095 Hz | ✅ |

→ ML は note 周波数の整数倍化、 carrier ML は出力周波数を直接 ML 倍に (= 1 オクターブ上 = ML 2 倍)

**重要発見**: PMD のオクターブ番号は MIDI/科学的記号より 1 つ低い。 PMD `o5 c` = MIDI C4 = 261 Hz (= MIDI C5 = 523 Hz ではない)。

## 検証手法サマリ

| パラメータ | 測定指標 | window | 判別精度 |
|---|---|---|---|
| TL | 全体 RMS / peak | 5 sec | dB ±0.5% |
| AR | envelope follower (50ms-100ms 刻み RMS) | 0-2 sec | 4 段階明確 |
| DR | envelope follower (100ms 刻み RMS) | 0-2 sec | 4 段階明確 |
| ML | FFT 主要 peak | 0.5-2 sec | Hz 単位精度 |

## 用途

PMDNEO 自前 driver で `@` cmd 実装後、 同 MML 再生 → 各 file の期待値と比較:

- TL: ±5% 以内なら functional 等価
- AR/DR: envelope curve 形状 + key time point の RMS 値が ±10% 以内
- ML: 主要 peak 周波数 ±1% 以内 (= 周波数精度)

差分があれば driver 実装の bug 候補を絞り込み。

## 後続 step (= 計画)

- SR/RR/SL — sustain decay + release shape (= note off 後の挙動)
- alg — FFT で topology 効果 (= alg 0/4/7 切替で倍音構造比較)
- fbl — FFT 高域でノイズ性 (= fbl 0/3/7 でスペクトル広がり)

## 規律: 検証しづらい MML は再設計

検証目的に対して MML pattern が干渉する場合 (= AR の attack 観察に loop 干渉、 等)、 **MML を再設計** して測定容易性を確保する。 解析手法の工夫だけで対処せず、 測定対象に最適な MML を選ぶ。
