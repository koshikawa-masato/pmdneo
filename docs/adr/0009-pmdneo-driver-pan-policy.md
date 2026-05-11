# ADR-0009: PMDNEO driver PAN 規律 (= 識別用分離撤廃 + 全 ch Center 初期化 + 将来動的制御)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0001 (= FM ch1/ch4 no use policy)、 ADR-0006 (= MML 文法 + chip target)、 memory `feedback_pmddotnet_mml_authoring_rules.md`

## 背景

ADR-0006 §4 sprint 完了後の option E (= AES+ test MML、 A/B/D 構成) 検証で、 PMDDotNET pmdplay (= OPNA reference) 経路と PMDNEO MAME 経路の発音差異が判明:

| 経路 | RMS | peak freqs | 鳴音 |
|---|---|---|---|
| PMDDotNET pmdplay (= OPNA reference) | 0.0147 | 131/165/196 Hz | A/B/D の C major 和音 (3 音) |
| MAME --chip ym2610b (= 自作 driver) | 0.0146 | 330 Hz のみ | **B の単音のみ + L 側のみ** |

driver source 調査で **`src/driver/standalone_test.s:1277-1292`** に Phase 9R R-5b 期 (= 7 ch 識別用聴感比較) のハードコード PAN 分離が判明:

```
ld b, #0xB5; ld c, #0x80  ; ch2 (B) = Left only
ld b, #0xB6; ld c, #0x40  ; ch3 (C) = Right only
ld b, #0xB5; ld c, #0x80  ; ch5 (E) = Left only (port B)
ld b, #0xB6; ld c, #0x40  ; ch6 (F) = Right only (port B)
```

これは過去 sprint の聴感判別用設計で、 ADR-0006 が想定する **OPNA pmdplay 等価発音** (= 「PMDNEO MML 文法は PMDDotNET 互換、 PMDNEO driver は OPNA 等価出力」) と相容れない遺物。

また、 A (= ch1 port A reg 0xB4) / D (= ch4 port B reg 0xB4) の PAN 初期化は driver 全体で **未設定**だったが、 これは ADR-0006 §B「ym2610 mode で A/D mute」 規律で許容範囲 (= ym2610 mode は元々 A/D 発音しない、 ym2610b mode で発音時は明示初期化必要)。

## OPNA / OPNB PAN register 仕様

YM2608 / YM2610 / YM2610B datasheet 共通仕様 (= AMS/PMS/Output Enable register):

| reg | port | 対象 ch |
|---|---|---|
| 0xB4 | A | ch1 (= A) |
| 0xB5 | A | ch2 (= B) |
| 0xB6 | A | ch3 (= C) |
| 0xB4 | B | ch4 (= D) |
| 0xB5 | B | ch5 (= E) |
| 0xB6 | B | ch6 (= F) |

bit map:
- **bit 7 = L Output Enable** (0=OFF, 1=ON)
- **bit 6 = R Output Enable** (0=OFF, 1=ON)
- bit 5-4 = AMS (= Amplitude Modulation Sensitivity)
- bit 2-0 = PMS (= Phase/Frequency Modulation Sensitivity)

主要値:

| 値 | bit 7 | bit 6 | 意味 |
|---|---|---|---|
| 0x00 | 0 | 0 | L/R 両側 disable (= datasheet 仕様、 ymfm 実機検証は別途要) |
| 0x40 | 0 | 1 | R only |
| 0x80 | 1 | 0 | L only |
| **0xC0** | 1 | 1 | **L+R 両側 enable = Center (default)** |

## 決定

### A. 識別用 PAN 分離撤廃 + 全 ch Center 初期化

`src/driver/standalone_test.s` の song init `pmdneo5_init` 内 PAN 設定 block (= 旧 1277-1292 行) を全 FM ch Center (= 0xC0) で初期化する形に書き換え。 Phase 9R R-5b の BC=L / EF=R 識別用分離は撤廃。

A (ch1) / D (ch4) の PAN 初期化を `.if PMDNEO_TARGET_CHIP_YM2610B` conditional で追加 (= ADR-0006 §B chip target 規約継承)。

実装後 block:
- ch1 (A) port A 0xB4 = 0xC0 [ym2610b 限定]
- ch2 (B) port A 0xB5 = 0xC0
- ch3 (C) port A 0xB6 = 0xC0
- ch4 (D) port B 0xB4 = 0xC0 [ym2610b 限定]
- ch5 (E) port B 0xB5 = 0xC0
- ch6 (F) port B 0xB6 = 0xC0

### B. MML `p` cmd 経由の動的 PAN 制御は将来 sprint

PMDDotNET MML 仕様の `p` cmd (= per-note PAN 制御、 PMD V4.8s 公式マニュアル §6) は本 ADR では実装対象外。 driver の PAN は init 時 Center 固定、 演奏中の動的変更は将来 sprint (= 別 ADR、 MML 文法 `p` cmd + driver dispatch hook 追加で対応)。

### C. PAN 規律と silent root cause の分離

実機検証 (= 2026-05-11 MAME ym2610b mode wav 録音 + RMS/FFT 解析) で:
- B/C/E/F の Center 化は機能 (= L+R 両側 enable で RMS が 2 倍化)
- **A/D は PAN 0xC0 でも silent** (= 別 root cause)

つまり A/D silent の真因は PAN ではなく driver の **voice 設定 / keyon dispatch / TL ハードコード / その他** のどこか。 これは本 ADR スコープ外で別 sprint (= 想定 ADR-0010、 A/D silent root cause 追跡) で扱う。

### D. octave +1 shift 観察

副次観察として、 同 MML `o4l1 e` に対し:
- PMDDotNET pmdplay = 165 Hz (= MIDI E3、 PMD V4.8s 規約 `o5 c = MIDI C4 = 261 Hz` より o4 e = E3 = 165 Hz)
- PMDNEO MAME = 330 Hz (= MIDI E4、 1 octave 高い)

PMDNEO driver の fnum 計算 + octave shift が PMD V4.8s 規約から +1 octave ずれている可能性。 これも本 ADR スコープ外 (= 別 sprint で fnum table 検証)。

## 影響

- driver PAN 分離 (= Phase 9R R-5b 遺物) 撤廃で、 ADR-0006 が想定する OPNA pmdplay 等価発音規律へ整合
- test01.mml / voice-test 28 entry の発音は **PAN 中央化で RMS が増減**する可能性あり (= 既存 reference との数値乖離、 再 baseline 必要)
- A/D silent + octave shift は本 ADR では touched せず、 別 sprint で順次対応

## 残論点 / 後続 sprint

- **ADR-0010 (= 想定)**: A/D silent root cause 追跡 (= voice 設定 / keyon / TL / dispatch 経路)
- **ADR-0011 (= 想定)**: octave +1 shift 修正 (= fnum table + o_offset 検証)
- **MML `p` cmd 実装**: 上記 2 つ完了後に着手、 PAN 動的制御の MML 文法 + driver dispatch hook
- **voice-test 28 entry の baseline 再取得**: PAN 中央化で RMS / FFT 数値が変動するため、 ADR-0005 reference DB の値を再計算

## 改訂履歴

- **2026-05-11 起票**: 初版 (= 決定 A-D 4 論点、 PAN 撤廃 + 全 ch Center + 残課題分離)

## 参照

- ADR-0001 (C) 方針: 「楽曲側 A/D 不使用」 規律 を default mode で継承
- ADR-0006 §B: PMDNEO_TARGET_CHIP_YM2610B 条件で A/D init 経路有効化
- memory `feedback_pmddotnet_mml_authoring_rules.md`: PMDDotNET MML 規律 (= CRLF / header / OPNA part letter)
- memory `feedback_step_pacing_and_artifact_attribution.md`: 検証 wav の出自明示規律
- YM2610 / YM2608 / YM2610B datasheet: register 0xB4-0xB6 bit map
- PMD V4.8s 公式マニュアル §1-1-3: OPNA part letter 対応 (= A-F FM / G-I SSG / J PCM / K Rhythm)
