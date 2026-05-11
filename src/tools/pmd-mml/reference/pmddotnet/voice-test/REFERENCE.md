# PMDDotNET 音色パラメータ検証 reference

PMDNEO 自前 driver の検証 dataset。 PMDDotNET → pmdplay 経路で取得した「期待 WAV 数値」 を保存。

## 使い方

PMDNEO 自前 driver で同 MML を再生 → WAV 録音 → 本 reference の RMS/peak 期待値と比較。 一致すれば functional 等価。

## 共通条件

- base template: `../TEMPLATE-Bscale.mml` (= scale `o5l4 cdefgab>c`)
- 録音: `pmdplay -w out.wav -s 5 out.M`
- 計測: `scipy.io.wavfile` + numpy で RMS / peak (= int16 stereo、 L channel)
- 環境: dotnet 7.0.311 + PMDDotNETConsole.dll + pmdplay SDL 2022-07-26

## tl-step/ — TL (Total Level) 段階検証

**目的**: alg=0 の op4 carrier の TL を 0/10/20/40 と変動、 OPN 仕様 0.75 dB/step の検証。

**改変**: `@001 000 005` ブロックの op4 行 (= 6 行目の TL 列、 0-indexed 5)

### 期待値 (= PMDDotNET 実測、 2026-05-11)

| file | TL | RMS | peak | 倍率 | 実測 dB | 仕様一致 |
|---|---|---|---|---|---|---|
| voice-tl-00.mml | 0 | **661.9** | 2042 | 1.0000 | 0.00 | base |
| voice-tl-10.mml | 10 | **278.3** | 858 | 0.4204 | -7.53 | 仕様 -7.50、 差 0.4% |
| voice-tl-20.mml | 20 | **116.9** | 361 | 0.1767 | -15.06 | 仕様 -15.00、 差 0.4% |
| voice-tl-40.mml | 40 | **20.6** | 63 | 0.0311 | -30.14 | 仕様 -30.00、 差 0.5% |

**検証成功**: OPN TL = -0.7527 dB/step (= 仕様 -0.75 dB/step に対し誤差 < 0.5%)、 4 段階すべてで一貫。

### 学習成果

- TL は **対数減衰** (= 線形でなく dB 比例)
- alg=0 op4 = carrier、 TL は直接音量制御に効く
- RMS と peak は同比率で減衰 (= 純粋 amplitude scaling、 波形 shape は不変)
- 1 sec ごと推移は scale 進行のまま均一

### 用途

PMDNEO 自前 driver で `@` cmd 実装後、 同 MML を再生 → 4 file の RMS/peak が ±5% 以内に入れば「TL 機能の functional 等価性 OK」 判定。 5% 超の差は driver 実装 bug 候補。

## ar-step/ — AR (Attack Rate) 段階検証

**目的**: alg=0 op4 carrier の AR を 31/16/8/4 と変動、 OPN AR の指数特性を envelope follower で検証。

**改変**:
- 音色定義 op4 行の AR (= 1 列目) を 031/016/008/004 に変更
- melody を `B\to5l4 cdefgab>c` (scale) → `B\to5l1 c` (= 全音符 c 単音、 attack 観察用)
- setup `@1v10q6` (= base @1 alg=0)

### 期待値 (= PMDDotNET 実測、 2026-05-11)

| file | AR | 立ち上がり時間 | 0-50ms RMS | 1 sec 後 RMS | 形状 |
|---|---|---|---|---|---|
| voice-ar-31.mml | 31 | 即達 (= 0 ms) | 773 | 約 max | step 関数 |
| voice-ar-16.mml | 16 | 約 100 ms | 513 | 約 max | 急峻 |
| voice-ar-08.mml | 8 | 約 1 sec | 0.5 | 911 (= 80%) | 緩やか |
| voice-ar-04.mml | 4 | 数 sec (5 sec 内未完結) | 0.5 | 11 (= 1%) | 非常に緩やか |

**検証成功**: AR は OPN 仕様どおり **指数特性** (= 数値 +8 で attack 時間 約 1/16)。 envelope follower (= 50 ms 刻み RMS) で明確に判別可能。

### 学習成果

- AR は **指数 (= 対数) 特性** (= 線形でなく指数倍率)
- AR=31 = max attack (= 即立ち上がり)、 AR=0 = no attack (silent)
- 測定手法 = envelope follower (短 window RMS の時系列)、 50 ms 刻みで AR 4-31 範囲は判別可能
- AR=4 以下は 5 sec 録音では完結しない、 longer record (= 10-20 sec) 必要
- attack curve の形状 (= 指数立ち上がり) で AR 値の機械的推定可能

### 用途

PMDNEO 自前 driver で `@` cmd の AR 機能実装後、 同 MML 再生 → 各 file の 0-50ms RMS / 1 sec 後 RMS が ±10% 以内なら functional 等価。 envelope follower の curve 形状一致も追加判定指標。

## 後続 step (= 計画)

- DR/SR/RR/SL — sustain plateau + release shape (= AR=31 固定 + DR/SR 変動で観察)
- ML — FFT で倍音構成解析 (= 単音 + 周波数 spectrum)
- alg — FFT で topology 効果解析 (= alg 0/7 切替)
- fbl — FFT 高域でノイズ性解析
