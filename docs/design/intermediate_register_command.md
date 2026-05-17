# Intermediate Register Command Data (IR)

**ステータス**: design draft v0.2  
**更新日**: 2026-05-17  
**判断**: A. 具体性を保ちつつ、設計思想部分を復活させる

---

## 0. 結論

現時点では、設計を 2 ファイルへ分割せず、1 つの設計書内で以下を同居させる。

- 上位方針: IR の責務、非責務、`.mn` / `.PNE` / `.NEO` との関係
- 中位構造: SemanticEvent / ChipEvent / RawRegisterWrite の 3 層
- 下位定義: イベント種別、必須 field、検証規則

理由:

- 現在の文書量では B の分割は早い。分割すると、設計思想と field 定義が別々に更新されて乖離しやすい。
- C の整理し直しは不要。すでに具体的なイベント定義は有用で、捨てるより補強した方が早い。
- PMDNEO では既に `.mn` と `.PNE` の runtime format 設計が進んでいるため、IR は runtime format ではなく、compiler / WebApp 内の正規化形式として固定するべき。

将来、イベント定義が実装仕様レベルまで膨らんだ時点で、B に移行して `intermediate_register_command_events.md` を分離する。

---

## 1. IR の責務と非責務

### 1-1. 責務

IR は、MML 系入力から PMDNEO の成果物を生成する前段の正規化・検証・変換用データである。

主な責務:

- MewMML / PMD / mdx などの入力を OPNB 向けの共通表現へ正規化する
- `.mn` の part body、音色データ、`.PNE` sample reference を生成しやすい形へ落とす
- 変換元方言の情報、不可逆変換、警告理由を保持する
- YM2610 / YM2610B / OPNA 互換など、target profile ごとの発音可否を検証する
- raw register write を保持し、MML 方言固有の低レベル制御を失わない

### 1-2. 非責務

IR は Z80 runtime driver が直接読む形式ではない。

非責務:

- Z80 driver の演奏 binary format になること
- `.mn` の OPNA 互換 header / part offset table を置き換えること
- `.PNE` の ADPCM-A sample pack 実体を内包すること
- 完全に中立な高レベル MML を定義すること
- OPNB 以外の chip を完全抽象化すること

### 1-3. 生成物との関係

IR から生成する runtime 成果物は次の通り。

| 成果物 | 役割 | IR との関係 |
|---|---|---|
| `.mn` | Z80 driver が読む楽曲 binary | IR の event / tone / loop を PMDNEO part body へ lower する |
| `.PNE` | ADPCM-A sample pack | IR は sample id / slot / filename 参照のみを持つ |
| `.NEO` | WebApp / toolchain 用 package 候補 | IR を `IRCM` chunk として格納可能。ただし runtime は `.mn` + `.PNE` を使う |

---

## 2. 基本方針

### 2-1. レジスタ寄りのハイブリッド形式

PMD / MewMML / MewFM の音色構造は FM register に近い。したがって、IR は高レベル MML を再発明せず、OPNB register へ展開しやすい形式に寄せる。

ただし、全てを raw register write にすると `.mn` 生成、検証、警告表示が難しくなる。そこで次の 3 層を使う。

| 層 | 目的 | 例 |
|---|---|---|
| SemanticEvent | 変換元の音楽的意味を残す | Note, Rest, ToneSelect, Tempo |
| ChipEvent | OPNB に近い操作へ正規化する | KeyOn, FMToneLoad, FM3Mode, ADPCMATrigger |
| RawRegisterWrite | 低レベル制御の逃げ道 | port/address/data |

### 2-2. 標準イベントは少なく保つ

IR の標準イベントは、`.mn` / `.PNE` 生成に必要な最小集合にする。

標準化する:

- note / rest / tempo / loop
- tone select / tone load
- volume / pan
- FM3 extension mode
- ADPCM-A / ADPCM-B trigger
- raw register write

初期段階では標準化しすぎない:

- 方言固有 LFO
- portamento / pitch envelope の詳細差異
- mdx / OPM 固有 operator behavior
- tracker 固有 effect command

これらはまず SemanticEvent の source metadata と RawRegisterWrite / ChipEvent 展開で保持し、共通化できるものだけ後で昇格する。

### 2-3. OPNB native を第一にする

IR は chip 非依存の完全抽象層ではない。PMDNEO の主対象は OPNB(YM2610/B) なので、channel、tone、ADPCM、FM3 mode は OPNB 視点で定義する。

OPNA 互換は入力・検証・一部変換のために扱うが、IR の中心ではない。

---

## 3. 全体データ構造

IR document は以下の logical section を持つ。

```text
IRDocument
  header
  target_profile
  timing
  channels
  tone_bank
  sample_refs
  tracks
  diagnostics
```

### 3-1. header

| field | 型 | 内容 |
|---|---|---|
| `magic` | string | `"PMDNEO-IR"` |
| `version` | uint16 | 初期値 `1` |
| `sourceDialect` | enum | `pmd`, `mewmml`, `mdx`, `mucom88`, `fmp7`, `unknown` |
| `createdBy` | string | compiler / converter 名 |
| `sourceHash` | string? | 入力ファイル追跡用。任意 |

### 3-2. target_profile

`targetProfile` は、変換・警告・lowering の前提になる chip profile である。

| Profile ID | FM | SSG | ADPCM-A | ADPCM-B | K/R Rhythm | 主用途 |
|---|---:|---:|---:|---:|---:|---|
| `ym2610_aes` | 4 audible / 6 writable | 3 | 6 | 1 | 0 | 標準 NEOGEO / AES 想定 |
| `ym2610b` | 6 | 3 | 6 | 1 | 0 | AES+ / YM2610B full FM |
| `opna_compat` | 6 | 3 | 0 | 1 | 6 | OPNA 由来入力の検証用 |

注意:

- `ym2610_aes` でも FM ch 1 / 4 への register write は許可する。ただし audio output は mute として warning を出す。
- PMDNEO runtime driver は YM2610B 仕様で 6ch FM dispatch を持つ。target profile は「鳴るか」「警告するか」の判断に使う。
- OPNB には OPNA K/R rhythm はない。PMD 入力の K/R command は `.mn` 側では no-op stub へ落とす。

### 3-3. timing

| field | 型 | 内容 |
|---|---|---|
| `ticksPerBeat` | uint16 | 標準 `192` |
| `timeMode` | enum | `absolute` を標準、`delta` は import 時のみ許容 |
| `tempoBase` | float32 | 初期 BPM |
| `swing` | optional | 初期 scope では非標準 |

IR 内部では absolute tick を正規形にする。入力方言の C 値 / #Zenlen / 分解能差は import 時に `ticksPerBeat = 192` へ変換する。

同一 tick の event 順は `order` で保証する。`order` は track 内で同一 tick ごとに 0 から増える。

---

## 4. channel model

### 4-1. channel kind

| kind | logical range | `.mn` 対応 | 備考 |
|---|---:|---|---|
| `fm` | 1-6 | Part A-F | `ym2610_aes` では 1 / 4 が mute warning |
| `ssg` | 1-3 | Part G-I | PSG/SSG |
| `adpcm_b` | 1 | Part J | YM2610/B ADPCM-B |
| `rhythm_kr` | 1 | Part K/R | PMD/OPNA 互換入力用。PMDNEO では no-op |
| `adpcm_a` | 1-6 | Part L-Q | PMDNEO 後方拡張 |

IR の `channelId` は `(kind, index)` で表す。数値だけで FM / ADPCM-A を混在させない。

### 4-2. FM channel mapping

| FM index | PMD part | OPNB register channel | `ym2610_aes` |
|---:|---|---:|---|
| 1 | A | 0 | mute warning |
| 2 | B | 1 | audible |
| 3 | C | 2 | audible / FM3 target |
| 4 | D | 3 | mute warning |
| 5 | E | 4 | audible |
| 6 | F | 5 | audible |

---

## 5. 共通 event field

全 event は以下の共通 field を持つ。

| field | 型 | 内容 |
|---|---|---|
| `type` | enum | event 種別 |
| `tick` | uint32 | absolute tick |
| `order` | uint16 | 同一 tick 内順序 |
| `trackId` | uint16 | logical track |
| `source` | SourceRef? | 変換元追跡 |
| `lossyFlags` | uint32 | 不可逆変換 flag |

### 5-1. SourceRef

| field | 型 | 内容 |
|---|---|---|
| `dialect` | enum | `pmd`, `mewmml`, `mdx`, ... |
| `file` | string? | 入力 file |
| `line` | uint32? | 行番号 |
| `column` | uint32? | 桁 |
| `rawCommand` | string? | 元 command 断片 |

### 5-2. lossyFlags

| flag | 意味 |
|---|---|
| `pitch_approx` | pitch / tuning を近似した |
| `lfo_approx` | LFO を近似した |
| `tone_approx` | 音色 parameter を近似した |
| `channel_muted` | target profile 上、発音しない channel を使った |
| `unsupported_effect` | 未対応 effect を raw write または無視へ落とした |
| `timing_quantized` | tick 変換で丸めが発生した |

---

## 6. SemanticEvent

SemanticEvent は入力 MML の意味を残す層である。`.mn` へ直接 lower できるものもあるが、原則として検証・編集・表示に使う。

### 6-1. Note

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | 対象 channel |
| `note` | uint8 | MIDI note 相当。C-1 = 0 |
| `duration` | uint32 | tick |
| `gate` | uint32? | 実発音 tick。省略時は `duration` |
| `velocity` | uint8 | 0-127 |
| `tie` | bool | tie continuation |

`NoteOn` / `NoteOff` に分けず、正規形では duration 付き Note を基本にする。理由は PMD / MML 系の part body 生成が音長中心であり、`.mn` lower が容易なため。

### 6-2. Rest

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | 対象 channel |
| `duration` | uint32 | tick |

### 6-3. ToneSelect

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | 対象 channel |
| `toneId` | uint16 | `tone_bank` 内 id |

### 6-4. Volume

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | 対象 channel |
| `value` | uint16 | normalized 0-1024 |
| `sourceScale` | enum | `pmd`, `mewmml`, `midi`, `raw` |

0-127 固定にしない。PMD / ADPCM-A / FM TL / SSG volume では意味が異なるため、IR 内では normalized 値と source scale を併記する。

### 6-5. Pan

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | 対象 channel |
| `left` | bool | left enable |
| `right` | bool | right enable |

OPN 系 pan は連続値ではなく L/R bit が基本なので、`-64..+63` ではなく bit 表現を正規形にする。

### 6-6. Tempo

| field | 型 | 内容 |
|---|---|---|
| `bpm` | float32 | BPM |

### 6-7. LoopStart / LoopEnd

| field | 型 | 内容 |
|---|---|---|
| `loopId` | uint16 | 対応する loop id |
| `count` | uint16? | `LoopEnd` のみ。0 = infinite |

`.mn` 生成時に PMD の loop 表現へ lower する。IR 内では nest を許容するかは未決定。初期実装では non-nested loop を推奨する。

---

## 7. ChipEvent

ChipEvent は OPNB 操作に近い層である。SemanticEvent から lower して生成してもよいし、importer が直接生成してもよい。

### 7-1. KeyOn / KeyOff

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | FM / SSG / ADPCM 対象 |
| `operatorMask` | uint8 | FM の operator key mask。通常は `0x0f` |

FM3 extension mode では `operatorMask` が意味を持つ。通常 FM note では `0x0f` 固定でよい。

### 7-2. FMToneLoad

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | FM channel |
| `toneId` | uint16 | `tone_bank` 参照 |
| `inlineTone` | FMTone? | 直接 tone を埋める場合 |

通常は `toneId` を使う。MewMML の inline tone や raw import では `inlineTone` を許容する。

### 7-3. FMFrequency

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | FM channel |
| `block` | uint8 | 0-7 |
| `fnum` | uint16 | 11-bit |

Note から OPNB frequency へ lower した後の表現。pitch bend / detune 展開後の値を保持できる。

### 7-4. FM3Mode

| field | 型 | 内容 |
|---|---|---|
| `enabled` | bool | FM3 extension on/off |
| `operatorEnableMask` | uint8 | bit0-3 |
| `operatorBlock[4]` | uint8 | operator 別 block |
| `operatorFnum[4]` | uint16 | operator 別 fnum |
| `keyPolicy` | enum | `all`, `operator_masked` |

規則:

- FM3Mode は FM ch 3 にだけ作用する。
- `enabled = true` の期間中、通常 ch 3 Note と operator split Note を同時に生成しない。
- mode 切替直前には KeyOff を挿入することを推奨する。
- lowering 時は `0x27` と `0xA8-0xAE` 系 register write へ展開する。

### 7-5. ADPCMATrigger

| field | 型 | 内容 |
|---|---|---|
| `channel` | ChannelId | `adpcm_a:1-6` |
| `sampleRef` | uint16 | `sample_refs` 参照 |
| `volume` | uint8 | ADPCM-A volume |
| `panLeft` | bool | left enable |
| `panRight` | bool | right enable |

`.PNE` 内 sample 実体は参照しない。`sampleRef` から `.PNE` slot / sample name を引く。

### 7-6. ADPCMBDma

| field | 型 | 内容 |
|---|---|---|
| `sampleRef` | uint16 | ADPCM-B sample 参照 |
| `start` | uint32? | resolved 後の start address |
| `stop` | uint32? | resolved 後の stop address |
| `volume` | uint8 | ADPCM-B volume |

初期 `.PNE` は ADPCM-A 用なので、ADPCM-B sample pack 連携は別設計でもよい。IR では将来拡張のために event を予約する。

---

## 8. RawRegisterWrite

RawRegisterWrite は OPNB register write をそのまま保持する escape hatch である。

| field | 型 | 内容 |
|---|---|---|
| `port` | uint8 | `0` = address/data port 0, `1` = port 1 |
| `address` | uint8 | register address |
| `data` | uint8 | write data |
| `barrier` | bool | 前後の並べ替え禁止 |

規則:

- 同一 tick 内の順序は共通 field の `order` で決める。
- `barrier = true` の write は最適化・重複削除の対象にしない。
- `targetProfile` 上で無効な register でも保持はする。ただし diagnostics に warning を出す。
- MewMML の `y` command は原則 RawRegisterWrite に import する。

---

## 9. FMTone 構造

FM tone は PMD / MewFM の register 寄り構造に合わせる。

```text
FMTone
  algorithm: 0..7
  feedback: 0..7
  operators[4]: FMOperator
```

### 9-1. FMOperator

| field | 型 | register 系 |
|---|---|---|
| `ar` | uint8 | Attack Rate |
| `dr` | uint8 | Decay Rate |
| `sr` | uint8 | Sustain Rate |
| `rr` | uint8 | Release Rate |
| `sl` | uint8 | Sustain Level |
| `tl` | uint8 | Total Level |
| `ks` | uint8 | Key Scale |
| `mul` | uint8 | Multiple |
| `dt` | int8 | Detune |
| `am` | bool | Amplitude Modulation enable |
| `ssgEg` | uint8 | SSG-EG |

方針:

- PMD / MewFM の音色 import はこの構造へほぼ直接 map する。
- register byte 列だけで保持せず、operator parameter として保持する。理由は UI 編集、差分表示、YM2610B / OPNA 検証がしやすいため。
- 最終 lowering で OPNB register write 列へ展開する。

### 9-2. FM3 用 tone

FM3 extension mode でも、tone 自体は通常の 4 operator tone を使う。operator ごとの独立 pitch は FMTone ではなく FM3Mode / FMFrequency 側に持つ。

---

## 10. sample_refs

IR は sample 実体を持たず、sample reference だけを持つ。

| field | 型 | 内容 |
|---|---|---|
| `sampleRef` | uint16 | IR 内 id |
| `kind` | enum | `adpcm_a`, `adpcm_b` |
| `packFile` | string? | 例: `NEOSI001.PNE` |
| `slot` | uint8? | ADPCM-A slot |
| `name` | string? | `bd`, `sd`, etc |
| `sourceUri` | string? | converter 入力追跡 |

`.PNE` 生成時:

- `kind = adpcm_a` の sample を `.PNE` slot table へ配置する。
- `.mn` には `pne_filename_adr` と ADPCM-A part body を出す。
- IR の `sampleRef` は `.mn` lowering 時に voice index / slot へ解決する。

---

## 11. `.NEO` コンテナとの関係

`.NEO` を採用する場合、IR は authoring / exchange 用 chunk として入れる。

候補 chunk:

| chunk | 内容 | runtime 必須 |
|---|---|---|
| `META` | 曲名、作者、tool version | 任意 |
| `IRCM` | Intermediate Register Command Data | 任意 |
| `MN  ` | `.mn` binary | 必須 |
| `PNE ` | `.PNE` binary | ADPCM-A 使用時必須 |
| `DIAG` | 変換 warning / lossy report | 任意 |

重要:

- Z80 runtime driver は `.NEO` を直接読まない。
- `.NEO` は WebApp / builder / archive 用 container として扱う。
- `.mn` と `.PNE` が既に存在するため、`.NEO` はそれらを置き換えない。

---

## 12. 変換元別 mapping 方針

### 12-1. PMD

優先度: 高

- FM tone は FMTone へ直接 map しやすい。
- Part A-F / G-I / J / R は `.mn` の既存 mapping と相性が良い。
- K/R rhythm は PMDNEO では no-op または ADPCM-A への置換候補として扱う。
- Part A/D は `ym2610_aes` profile では mute warning。

### 12-2. MewMML / MewFM

優先度: 高

- MewFM tone は FMTone と相性が良い。
- `y` 系 register direct command は RawRegisterWrite へ map する。
- FMP/PMD/MUCOM import 済み tone の橋渡しとして使いやすい。

### 12-3. mdx

優先度: 中から低

- OPM から OPNB への tone 変換は近似になる。
- LFO / pitch modulation / portamento は lossyFlags を立てる。
- まず mdx -> MewMML 経由、または mdx importer が SemanticEvent + FMTone へ近似 import する方針。

### 12-4. MUCOM88 / FMP7

優先度: 後続

- OPN/OPNA 系 tone は FMTone に寄せられる可能性が高い。
- 方言固有 command は最初から標準 event 化せず、SourceRef と RawRegisterWrite を併用する。

---

## 13. validation rules

初期 validator は以下を検出する。

| ID | severity | 条件 |
|---|---|---|
| `IR001` | error | tick が負、または track 内 event order が不正 |
| `IR002` | error | ChannelId が target profile に存在しない |
| `IR003` | warning | `ym2610_aes` で FM ch 1 / 4 に note がある |
| `IR004` | warning | K/R rhythm を PMDNEO target へ出力しようとした |
| `IR005` | warning | FM3 enabled 中に通常 FM ch 3 Note が混在 |
| `IR006` | warning | RawRegisterWrite が target profile 非対応 register を触る |
| `IR007` | warning | mdx / OPM 由来 tone で近似変換が発生 |
| `IR008` | error | sampleRef が未解決 |
| `IR009` | error | `.PNE` slot 範囲外の ADPCM-A trigger |

---

## 14. lowering 方針

### 14-1. IR -> `.mn`

- `fm:1-6` は Part A-F へ出力する。
- `ssg:1-3` は Part G-I へ出力する。
- `adpcm_b:1` は Part J へ出力する。
- `rhythm_kr` は PMDNEO では no-op stub 対象。必要なら warning を出す。
- `adpcm_a:1-6` は Part L-Q の後方拡張領域へ出力する。
- `.PNE` filename は `.mn` の `pne_filename_adr` へ埋め込む。

### 14-2. IR -> `.PNE`

- ADPCM-A sampleRef を slot table へ配置する。
- raw ADPCM-A binary は `.PNE` 側に保持する。
- IR から `.PNE` への direct binary embed はしない。IR は参照と provenance のみを持つ。

### 14-3. IR -> register trace

検証・preview 用に、ChipEvent と RawRegisterWrite から timestamped register trace を生成できるようにする。

この trace は debug / emulator preview 用であり、正式 runtime format ではない。

---

## 15. 未決定事項

優先して決めるもの:

- IR の serialization format: JSON / YAML / binary chunk のどれを正とするか
- `.NEO` container を正式採用するか、WebApp 内部 package に留めるか
- loop nest を許可するか
- LFO / portamento を標準 SemanticEvent に昇格する条件
- ADPCM-B sample pack を `.PNE` と統合するか、別 format にするか

現時点の推奨:

- 設計・検証段階は JSON 表現を正とする。
- runtime は引き続き `.mn` + `.PNE` を正とする。
- `.NEO` は package / archive として後続検討に回す。

---

## 16. Codex 判断

この設計は、A の方針で進めるべき。

採用:

- IR は compiler / WebApp 内の正規化形式であり、Z80 runtime format ではない。
- 3 層 hybrid 形式を採用する。
- targetProfile を必須にする。
- FM3 extension mode は専用 ChipEvent と検証規則を持たせる。
- YM2610 / YM2610B の差は channel capability と warning policy で吸収する。
- `.mn` / `.PNE` は既存設計を維持し、IR はそれらを生成する前段に置く。

要検討:

- `.NEO` container の正式採用範囲。
- LFO / portamento の標準 event 化。
- mdx / OPM tone 変換の品質基準。
- ADPCM-B asset 管理を `.PNE` に含めるかどうか。

---

## 17. ADR 起票候補事項 (user ratification log)

このセクションは、 user (越川将人) が壁打ちで明示的に ratify した決定を順次記録する。
ADR 起票時にこのセクションを根拠として参照する。

### 17-1. 軸 1: IR の位置づけ (ratified 2026-05-17)

**決定**: IR は compiler / WebApp intermediate format として確定する。

**内容**:

- IR は Z80 driver が直接読む runtime format ではない
- runtime は引き続き `.mn` + `.PNE`
- IR は build / authoring / WebApp / diagnostics のための正規化形式
- IR から `.mn` / `.PNE` / diagnostics を生成する
- `.NEO` は archive / WebApp / builder 用 container 候補であり、 runtime replacement ではない

**理由**:

- Z80 driver semantics を巻き込まない
- 現行 `.mn` / `.PNE` chain を壊さない
- MML 方言差、 WebApp 編集、 診断、 将来の変換を IR 側で吸収できる
- runtime format にすると scope が大きくなりすぎる

**根拠 docs section**: §0 結論、 §1-2 非責務、 §1-3 生成物との関係、 §16 Codex 判断 採用 1 件目。

### 17-2. 軸 2: IR serialization format (ratified 2026-05-17)

**決定**: IR canonical serialization は JSON に確定する。

**内容**:

- IR canonical format は JSON
- schema は JSON Schema で定義する
- YAML は手書きメモや設計補助に使ってよいが canonical ではない
- binary chunk は現時点では canonical にしない (= scope-out for now)
- `.NEO` に入れる場合は、 まず JSON UTF-8 payload として IRCM chunk に入れる案を future とする
- binary encoding が必要になった時点で別 ADR / decision として扱う

**理由**:

- 軸 1 ratify (= IR は compiler / WebApp intermediate format) で runtime efficiency 制約が外れた
- Z80 driver は JSON を読まない (= runtime compactness は `.mn` + `.PNE` 側で確保)
- WebApp では JSON が最も扱いやすい (= JS native parse)
- git diff / review / regression test に向いている
- diagnostics と schema validation が作りやすい
- binary も同時規格化すると dual maintenance になる
- 設計 doc §15 現時点の推奨 と整合する

**根拠 docs section**: §15 未決定事項 1 件目 (= IR の serialization format)、 §15 現時点の推奨 (= 設計・検証段階は JSON 表現を正とする)。
