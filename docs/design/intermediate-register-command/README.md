# Intermediate Register Command Data (IR) — schema + examples

PMDNEO の compiler / WebApp intermediate format。 ADR-0034 (= 24th session ratified、 2026-05-17) で 6 軸決定済。 設計の母体は `../intermediate_register_command.md` (= design notes) + `../reference_intermediate_register_command.md` (= 詳細参考資料)。

## 構成

- `ir-schema-v0.1.schema.json`: JSON Schema draft-2020-12 v0.1 本体 (= ADR-0034 §決定 1-6 を spec 化、 fully validated event 種 6 件)
- `ir-schema-v0.2.schema.json`: v0.2 minimal ChipEvent 拡張 (= 25th session、 v0.1 baseline + FMToneLoad / FMFrequency / KeyOn / KeyOff 4 件追加、 fully validated event 種 10 件、 backwards-compatible)
- `examples/`: v0.1 schema 適合 example file 群 (= positive fixture)
  - `minimal-fm-note.ir.json`: FM ch 2 で Tempo + ToneSelect + Note + Rest 4 event
  - `adpcma-trigger.ir.json`: ADPCM-A ch 1 で ADPCMATrigger 1 event
  - `raw-register-write.ir.json`: reg 0x27 FM3 mode RawRegisterWrite 1 event
- `examples/invalid/`: v0.1 schema validation が **失敗する** ことを期待する fixture 群 (= negative fixture)
  - `bad-magic.ir.json`: `metadata.magic` const violation (= "PMDNEO-IR" 以外)
  - `unknown-event-type.ir.json`: events oneOf 不適合 (= semantic / Portamento は v0.1 未定義 type)
  - `invalid-channel-kind.ir.json`: `channelId.kind` enum violation (= "opm" 等は対象外)
  - `raw-register-out-of-range.ir.json`: `RawRegisterWrite.address` / `data` maximum violation (= 256 以上)
  - `missing-required-field.ir.json`: Note event の `duration` 欠落 (= required violation)
  - `zero-duration-rest.ir.json`: Rest event の `duration: 0` (= RestEvent.duration minimum 1 violation、 PR #3 review 反映)
- `examples/v0.2/`: v0.2 schema 適合 example file 群 (= positive fixture)
  - `chipevent-fm-note-lowered.ir.json`: `minimal-fm-note.ir.json` の semantic Note を chip layer (= FMToneLoad / FMFrequency / KeyOn / KeyOff) に lowering した hand-crafted fixture
  - `keyon-keyoff-minimal.ir.json`: chip KeyOn / KeyOff の minimal 単体 (= `operatorMask` 省略時 default = 15 動作確認)
- `examples/v0.2/invalid/`: v0.2 schema validation が **失敗する** ことを期待する fixture 群
  - `fmfrequency-out-of-range.ir.json`: `FMFrequency.block` = 8 / `fnum` = 2048 (= maximum violation)
  - `keyon-non-fm-channel.ir.json`: `KeyOn.channel.kind` = "ssg" (= FMChannelId.kind const "fm" violation、 v0.2 minimal scope literal)

## v0.1 で fully validated な event types (= 6 件)

| layer | type | 出典 (= ADR-0034) |
|---|---|---|
| semantic | `Note` | §決定 3 |
| semantic | `Rest` | §決定 3 |
| semantic | `Tempo` | §決定 3 |
| semantic | `ToneSelect` | §決定 3 |
| chip | `ADPCMATrigger` | §決定 5 |
| raw | `RawRegisterWrite` | §決定 3 |

## v0.2 で追加された event types (= 4 件、 25th session)

| layer | type | 用途 |
|---|---|---|
| chip | `FMToneLoad` | ToneSelect (semantic) を chip lowering したもの。 `tones[]` から `toneId` で参照される FM tone param を ch slot にロード |
| chip | `FMFrequency` | YM2610 FM frequency 設定 (= `block` 3-bit + `fnum` 11-bit) |
| chip | `KeyOn` | FM ch keyon (= `operatorMask` で op 1-4 個別有効化、 省略時 15 = 全 op) |
| chip | `KeyOff` | FM ch keyoff (= `operatorMask` で op 1-4 個別無効化、 省略時 15 = 全 op) |

v0.2 minimal scope は **FM ch のみ** (= `FMChannelId` const "fm" 制約)。 ADPCM-A keyon は既存 `ADPCMATrigger` 経由。

v0.3 以降の event types (= 拡張予定): `FM3Mode` (= 軸 4 ratify) / `ADPCMBDma` / `Volume` / `Pan` / `LoopStart` / `LoopEnd` / SSG 用 chip event 等。

## 検証 command

repo root で実行。

### v0.1 positive validation のみ (= default)

```bash
python3 scripts/validate-ir-schema.py
```

実行内容:

1. schema 自身が JSON Schema draft-2020-12 として正当か (= meta-validation)
2. `examples/*.ir.json` 全件が schema に適合するか (= positive validation)

期待 exit: **0** (= 全 positive example が PASS)

### v0.1 positive + negative validation

```bash
python3 scripts/validate-ir-schema.py \
  --invalid-examples 'docs/design/intermediate-register-command/examples/invalid/*.ir.json'
```

実行内容:

1. 上記 positive validation
2. `examples/invalid/*.ir.json` 全件が schema validation で **失敗する** ことを確認 (= negative validation、 失敗 = PASS、 通過 = FAIL)
3. 各 invalid fixture の representative error (= JSON pointer 式 location + message) を表示

期待 exit: **0** (= 全 invalid fixture が想定通り reject される)

### v0.2 positive + negative validation

```bash
python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples 'docs/design/intermediate-register-command/examples/v0.2/*.ir.json' \
  --invalid-examples 'docs/design/intermediate-register-command/examples/v0.2/invalid/*.ir.json'
```

実行内容:

1. schema v0.2 meta-validation
2. `examples/v0.2/*.ir.json` 全件 (= chipevent-fm-note-lowered + keyon-keyoff-minimal) が v0.2 schema に適合
3. `examples/v0.2/invalid/*.ir.json` 全件 (= fmfrequency-out-of-range + keyon-non-fm-channel) が schema validation で失敗

期待 exit: **0**

backwards compat 確認 (= v0.1 fixture が v0.2 schema で通る) は `--schema` を v0.2 にして `--examples 'examples/*.ir.json'` で実行可能。

### option

```bash
python3 scripts/validate-ir-schema.py --schema <path> --examples '<glob>' --invalid-examples '<glob>'
```

## exit code

| code | 意味 |
|---|---|
| 0 | all pass |
| 64 | argument error (= file not found / JSON parse error) |
| 65 | schema / data validation fail |
| 66 | runtime error (= unexpected exception / missing dependency) |

## 依存

- Python 3.10+ (= `from __future__ import annotations` + `list[Path]` 型 hint 利用)
- `jsonschema` package (= draft-2020-12 support 必要、 4.18+ 推奨。 開発確認は 4.26.0)

## scope (= ADR-0034 + 24th session user 指示遵守)

- compiler 実装は含まない
- WebApp 実装は含まない
- runtime / driver source は touch しない
- `.NEO` container は作らない
- `.mn` / `.PNE` 生成 path は触らない
- binary IR encoder は作らない
- YAML 版は作らない

---

## MML → IR spike (v0.1)

「MML から IR に落ちる最小の道がある」 ことを示す read-only spike。 compiler 本体 / WebApp / runtime / driver は touch しない。

### script

- path: `scripts/mml-to-ir-spike.py` (= chmod +x、 Python 3.10+)
- 役割: tiny PMD-flavored MML subset 入力 → IR JSON v0.1 出力

### サポート tokens (= tiny PMD-flavored subset)

| token | 意味 | 例 |
|---|---|---|
| `t<bpm>` | Tempo event | `t120` |
| `@<n>` | ToneSelect | `@0` |
| `o<n>` | octave state (= 1-9) | `o5` |
| `<a-g>[+\|-]?<len>?` | Note event | `c4` / `c+8` / `c-2` |
| `r<len>?` | Rest event | `r4` / `r` |
| `;` から行末 | comment | `; comment` |

octave / length state は state machine が保持、 length 省略時は直前 length を引き継ぎ。 default `o4` / `len 4`。

### tick / pitch convention

- IR の `ticksPerBeat` は **PPQN (= Pulses Per Quarter Note) MIDI 流規約**
- ticksPerBeat 192 で **quarter note = 192 ticks** (= 既存 `minimal-fm-note.ir.json` example の duration 値と一致)
- 注: PMD MML 内部の #Zenlen 192 convention (= whole=192、 quarter=48) とは違う。 PMD importer は変換 (= PMD c4 内部 48 ticks → IR 192 ticks へ ×4 換算) する設計、 spike は IR canonical PPQN を直接 emit
- PMD `o5 c` = MIDI 60 = C4 (= memory `project_pmd_voice_ml_verified` 確認済)
- spike では PMD `o<n> c` = MIDI `n * 12` を採用

### hardcoded constants

- `targetProfile`: `ym2610_aes`
- `ticksPerBeat`: 192
- 単一 channel: FM ch 2 / Part B
- 単一 tone: toneId 0 (= dummy FMTone、 `minimal-fm-note.ir.json` example と同一構造)

### CLI

```bash
python3 scripts/mml-to-ir-spike.py <input.mml> [--output <path>]
```

- `--output` なしなら stdout
- `--output` ありなら file 書き出し (= stderr に `[OK] wrote N events to <path>`)

### 検証例

```bash
python3 scripts/mml-to-ir-spike.py \
  docs/design/intermediate-register-command/spike-fixtures/tiny-melody.mml \
  --output /tmp/tiny-melody.ir.json

python3 scripts/validate-ir-schema.py --examples /tmp/tiny-melody.ir.json
```

期待: validator が exit 0 + 1/1 PASS。

### exit code (= mml-to-ir-spike.py)

| code | 意味 |
|---|---|
| 0 | OK (= MML parse + IR build 成功) |
| 64 | argument error (= input file not found) |
| 65 | MML parse error (= unrecognized token / value out of range) |
| 66 | runtime error |

### fixture

- `spike-fixtures/tiny-melody.mml`: 6 event (= Tempo + ToneSelect + Note C4 + Rest + Note E4 + Rest) を出力する最小 fixture

### spike scope-out

- multi channel
- tone parameter parsing (= 音色 import は別 sprint)
- volume / pan / loop / tie / chord
- portamento / LFO / pitch envelope
- octave shift `<` / `>`
- gate time / velocity 制御
- compiler 本体改修
- WebApp 実装
- driver / runtime / `.mn` / `.PNE` / `.NEO` 生成
- automated CI 化

---

## IR → ChipEvent lowering spike (v0.2)

「IR の semantic 層から chip 層に落ちる最小の道がある」 ことを示す read-only spike。 compiler 本体 / WebApp / runtime / driver は touch しない。

### script

- path: `scripts/ir-lower-chipevent-spike.py` (= chmod +x、 Python 3.10+)
- 役割: v0.1 IR JSON 入力 → v0.2 IR JSON 出力 (= SemanticEvent → ChipEvent lowering、 一部は pass-through)

### lowering rule

| 入力 (= v0.1 event) | 出力 |
|---|---|
| `Tempo` (semantic) | `Tempo` (semantic) として **そのまま保持** (= 下記参照) |
| `ToneSelect` (semantic, channel.kind=fm) | `FMToneLoad` (chip) 1 件、 同 tick |
| `Note` (semantic, channel.kind=fm) | `FMFrequency` (chip) + `KeyOn` (chip) 同 tick 2 件 + `KeyOff` (chip) tick+duration 1 件、 計 3 件 |
| `Rest` (semantic) | 出力なし (= tick 進めるだけ、 free slot 扱い) |
| `ADPCMATrigger` (chip) | pass-through |
| `RawRegisterWrite` (raw) | pass-through |

### Tempo の扱い (= 25th session user 指示で明示)

`Tempo` は **semantic 層に保持** する (= lowering output から除外しない)。

理由:

- v0.2 minimal scope の ChipEvent (= FMToneLoad / FMFrequency / KeyOn / KeyOff) に Tempo 等価物はない。
- chip / driver level の tempo 設定は YM2610 Timer A/B register write (= RawRegisterWrite level) で表現するのが正しく、 v0.3 以降の `FMTimerSet` 等で別 sprint に分離する。
- spike では Tempo を semantic 層のまま下流 (= compiler / runtime translator / WebApp) に流し、 chip lowering の判断は下流に委ねる。

### MIDI → block/fnum 変換

PMD o5 c = MIDI 60 = C4 を基準に YM2610 FM frequency (= 3-bit block + 11-bit fnum) に変換:

- `block = (midi // 12) - 1`     ← MIDI 60 (C4) → block 4
- `semitone = midi % 12`
- `fnum = FNUM_TABLE[semitone]`

`FNUM_TABLE` (= 1 octave reference): C=617 / C#=654 / D=693 / D#=734 / E=778 / F=824 / F#=873 / G=925 / G#=980 / A=1038 / A#=1100 / B=1165

block が 0-7 範囲外 (= MIDI 0-11 / 108-127) は exit 65 (= silent pass 防止)。

### channel scope

ToneSelect / Note は **channel.kind = "fm" のみ** lowering。 他 kind (= SSG / ADPCM-A / ADPCM-B / rhythm_kr) は v0.2 minimal scope 外で exit 65 reject。

### operatorMask 規約

KeyOn / KeyOff の `operatorMask` は spike では常に `15` (= 全 op 有効) を emit。 op 個別制御は v0.3 以降。

### CLI

```bash
python3 scripts/ir-lower-chipevent-spike.py <input.ir.json> [--output <path>] [--stats]
```

- `--output` なしなら stdout
- `--output` ありなら file 書き出し (= stderr に `[OK] lowered N events -> M events: <path>`)
- `--stats` で lowering 統計を stderr 表示 (= input_total / tempo_kept / tone_select_lowered / note_lowered / rest_dropped / chip_passthrough / raw_passthrough / output_total)

### 検証例

minimal-fm-note (= 既存 v0.1 fixture) で直接実行:

```bash
python3 scripts/ir-lower-chipevent-spike.py \
  docs/design/intermediate-register-command/examples/minimal-fm-note.ir.json \
  --output /tmp/spike-out-minimal-fm-note.ir.json --stats

python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples /tmp/spike-out-minimal-fm-note.ir.json
```

期待: lowered 4 events → 5 events、 validator が exit 0 + 1/1 PASS。

tiny-melody.mml → v0.1 IR → v0.2 IR の chain:

```bash
python3 scripts/mml-to-ir-spike.py \
  docs/design/intermediate-register-command/spike-fixtures/tiny-melody.mml \
  --output /tmp/tiny-melody.ir.json

python3 scripts/ir-lower-chipevent-spike.py \
  /tmp/tiny-melody.ir.json \
  --output /tmp/tiny-melody.lowered.ir.json --stats

python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples /tmp/tiny-melody.lowered.ir.json
```

期待: MML 6 event → v0.1 IR 6 event → v0.2 IR 8 event (= Tempo + FMToneLoad + FMFrequency(C4) + KeyOn + KeyOff + FMFrequency(E4) + KeyOn + KeyOff)、 validator exit 0 + 1/1 PASS。

### exit code (= ir-lower-chipevent-spike.py)

| code | 意味 |
|---|---|
| 0 | OK (= lowering 成功) |
| 64 | argument error (= input file not found / JSON parse error / required field missing) |
| 65 | lowering parse error (= 未対応 event 種 / scope 外 channel kind / MIDI out-of-range) |
| 66 | runtime error |

### fixture

- input: 既存 `examples/minimal-fm-note.ir.json` (= v0.1)、 chain で `spike-fixtures/tiny-melody.mml` (= MML)
- output 例 (= 委員会 review 用 committed sample): `examples/v0.2/spike-lowered-tiny-melody.ir.json` (= tiny-melody chain の 8 event 出力、 spike 再実行で再生可能な deterministic output)

### spike scope-out

- gate / tie / velocity
- FM3Mode (= 3 ch independent freq、 v0.3 軸 4)
- Volume / Pan (= chip event、 v0.3)
- LoopStart / LoopEnd (= flow control、 v0.3)
- ADPCMBDma (= ADPCM-B、 v0.3)
- SSG ch (= v0.3)
- raw register write lowering (= chip event は block/fnum / operatorMask 抽象維持、 register write 展開は別 sprint)
- driver / runtime / `.mn` / `.PNE` / `.NEO` 生成
- compiler 本体改修 / WebApp 実装 / automated CI 化
