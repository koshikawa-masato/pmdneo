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

## alg-step/ — algorithm (topology) 全数検証

**目的**: 同 op パラメータで alg 0-7 全 8 種を切替、 op 接続 topology の出力 spectrum 効果を観察。

**改変**: `@001 000 005` の 2 番目の値 (= alg) を 0-7、 op パラメータは base @1 維持、 melody = 単音 long note。

期待値 (= 0.5-2.0 sec FFT):

| alg | RMS | peak | 主要 peak (上位 3) | 観察 |
|---|---|---|---|---|
| 0 | 398 | 1998 | 261Hz | linear chain、 op4 carrier、 純基本波 |
| 1 | 395 | 1977 | 261Hz, 523Hz | (op1+op2)→op3→op4、 微弱倍音 |
| 2 | 382 | 2020 | 522Hz, 785Hz, 261Hz | op1+op2→op3→op4、 倍音優位 |
| 3 | 400 | 1987 | 261Hz | (op1→op2)+(op3)→op4、 純基本波 |
| 4 | 366 | 2224 | 261Hz, 523Hz | op1→op2 + op3→op4 並列、 op2/op4 carrier |
| 5 | 388 | 2267 | 522Hz, 784Hz, 261Hz | op1→{op2,op3,op4}、 高倍音 |
| 6 | 462 | 2264 | 261Hz | op1→op2 + op3 + op4、 純基本 + 大音圧 |
| 7 | 683 | 2556 | 261Hz, 523Hz | 全 op carrier (= additive)、 RMS/peak 最大 |

→ alg=7 が RMS 最大 (= additive synthesis)、 alg=2/5 が高倍音優位 (= 522Hz dominant)、 alg=0/3/6 が基本波純度高い

## fbl-step/ — feedback level 段階検証

**目的**: op1 自己 feedback の効果、 高域ノイズ性の変化を FFT で観察。

**改変**: `@001 NNN ...` の 3 番目の値 (= fbl) を 0/2/5/7、 alg=7 + op1 TL=0 (= max output) で fbl 効果を増幅。

期待値 (= 0.5-2.0 sec FFT、 op1 TL=0、 alg=7):

| fbl | RMS | peak | >2kHz 比率 | >5kHz 比率 | 主要 peak | 観察 |
|---|---|---|---|---|---|---|
| 0 | 1621 | 4085 | 0.0% | 0.0% | 261Hz | 純基本波 (= feedback なし) |
| 2 | 1621 | 4116 | 0.0% | 0.0% | 261Hz | ほぼ純粋 |
| 5 | 1597 | 3968 | 0.0% | 0.0% | 261Hz | まだ純粋 |
| 7 | 1595 | 4099 | **48.4%** | **47.9%** | 0Hz, **15934Hz** | 強力 noise 化 |

→ fbl は **非線形** (= 0-5 までほぼ効果なし、 6-7 で激変)、 高 fbl で広域 spectrum 生成

**注**: 上記 fbl 検証は op1 を carrier として効果を増幅した特殊条件。 base @1 (= alg=0、 op1 modulator chain、 op1 TL=017) では fbl 効果は間接的で小さい。 fbl 効果を見るには **op1 が carrier 状態で TL 大** が必要。

## 検証手法サマリ (全 6 step)

| パラメータ | 測定指標 | window | 判別精度 | 備考 |
|---|---|---|---|---|
| TL | 全体 RMS / peak | 5 sec | dB ±0.5% | scale + loop で OK |
| AR | envelope follower (50-100ms 刻み) | 0-2 sec | 4 段階明確 | loop なし必須 |
| DR | envelope follower (100ms 刻み) | 0-2 sec | 4 段階明確 | loop なし、 AR=31 固定 |
| ML | FFT 主要 peak | 0.5-2 sec | Hz 単位 | 単音 long note |
| alg | FFT 主要 peak + RMS | 0.5-2 sec | 8 種別個性 | 全 8 種 |
| fbl | FFT 高域比率 (>2kHz) | 0.5-2 sec | 6-7 で激変 | op1 carrier + TL=0 で増幅必須 |

## 規律: 検証しづらい MML は再設計

検証目的に対して MML pattern が干渉する場合 (= AR の attack 観察に loop 干渉、 fbl 効果が op1 modulator 配置で見えない 等)、 **MML / 音色定義を再設計** して測定容易性を確保する。

例:
- AR/DR → loop なしで 1 note 完結観察
- fbl → op1 carrier + TL=0 max で効果増幅
- ML → 単音 long note で sustain 期間 FFT clean

## 後続 step (= 計画、 別 sprint)

- SR/RR/SL — sustain decay + release shape
- DT (Detune) — 微小ピッチずれ検証
- KS (Key Scale) — 周波数ごとの DR/SR 補正
- AMS (LFO 振幅変調) — LFO + AMS 組合わせ

## 規律: 検証しづらい MML は再設計

検証目的に対して MML pattern が干渉する場合 (= AR の attack 観察に loop 干渉、 等)、 **MML を再設計** して測定容易性を確保する。 解析手法の工夫だけで対処せず、 測定対象に最適な MML を選ぶ。
