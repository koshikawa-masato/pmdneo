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
  - `spike-lowered-tiny-melody.ir.json`: tiny-melody.mml chain (= MML → v0.1 IR → v0.2 IR) の spike 出力 deterministic sample
  - `spike-lowered-unsorted-events.ir.json`: `spike-fixtures/unsorted-events.ir.json` の spike 出力 (= input array 順と (tick, order) 順が逆の valid v0.1 IR を spike が semantic 真順で処理した literal 証跡、 PR #4 review finding 4 反映)
  - `spike-rawlowered-tiny-melody.ir.json`: `spike-lowered-tiny-melody.ir.json` を `ir-lower-raw-register-spike.py` に通した出力 (= chip 4 種 → YM2610 RawRegisterWrite 列、 Tempo は semantic 保持、 38 events = raw 37 + semantic Tempo 1、 26th session γ / ADR-0035 §verify 計画 A 整合)
- `examples/v0.2/invalid/`: v0.2 schema validation が **失敗する** ことを期待する fixture 群 (= schema layer reject)
  - `fmfrequency-out-of-range.ir.json`: `FMFrequency.block` = 8 / `fnum` = 2048 (= maximum violation)
  - `keyon-non-fm-channel.ir.json`: `KeyOn.channel.kind` = "ssg" (= FMChannelId.kind const "fm" violation、 v0.2 minimal scope literal)
  - `keyon-zero-operator-mask.ir.json`: `KeyOn.operatorMask` = 0 (= minimum 1 violation、 no-op KeyOn 防止、 PR #4 review finding 3 反映)
- `examples/v0.2/spike-invalid/`: schema validation は **PASS** するが spike `ir-lower-raw-register-spike.py` で **exit 65 reject** されることを期待する fixture 群 (= spike layer reject、 schema 表現外の invariant を spike layer で enforce、 26th session δ / ADR-0035 §verify 計画 B)
  - `semantic-residual-note.ir.json`: schema-valid な Note (semantic) を含む IR (= 前段 Semantic→Chip lowering 不徹底検出、 §決定 3)
  - `fmtoneload-unresolved-toneid.ir.json`: FMToneLoad で `tones[]` に存在しない toneId = 999 を参照 (= toneId reference 整合検出、 §決定 8)

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
2. `examples/v0.2/*.ir.json` 全件 (= chipevent-fm-note-lowered + keyon-keyoff-minimal + spike-lowered-tiny-melody + spike-lowered-unsorted-events + spike-rawlowered-tiny-melody) が v0.2 schema に適合
3. `examples/v0.2/invalid/*.ir.json` 全件 (= fmfrequency-out-of-range + keyon-non-fm-channel + keyon-zero-operator-mask) が schema validation で失敗

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

KeyOn / KeyOff の `operatorMask` は spike では常に `15` (= 全 op 有効) を emit。 op 個別制御は v0.3 以降。 schema 上は minimum 1 (= no-op 防止、 PR #4 review finding 3)。

### timeMode 制約 (= PR #4 review finding 1 反映)

`timing.timeMode` は `"absolute"` のみ受け付ける (= 省略時 default = "absolute")。 `"delta"` は spike で exit 65 reject (= delta IR を絶対 tick 扱いで lowering すると timing が静かに破壊されるため、 importer 側で absolute 正規化必須)。

### pass-through 規律 (= PR #4 review finding 2 反映)

ADPCMATrigger / RawRegisterWrite は元 event を残しつつ `order` は allocator で再採番 (= 同一 tick 内で semantic lowering 由来 event と pass-through event が混在しても order 衝突しない)。

### 入力 sort 規律 (= PR #4 review finding 4 + finding 5 反映)

入力 events 配列の **array 順は not authoritative** = IR の `(tick, trackId, order)` フィールドが semantic 真の順序。 lower_events() は処理前に `(tick, trackId, order)` で sort し直す (= array 順依存の silent semantic 順序反転 防止)。 入力に tick / order / layer / type の必須 field 欠落があれば sort 前に exit 65 reject。

同一 `(tick, trackId, order)` 重複は Python の stable sort 経由で input array 順が silently authoritative 化するため、 sort 前に検出して exit 65 reject (= finding 5、 schema 上 `order` は track 内で単調増加と規定されているため (tick, trackId, order) global unique を spike layer で enforce)。 重複検出時の error message は両 event を literal に出力し、 どこで衝突したかを debug 可能にする。

`spike-fixtures/unsorted-events.ir.json` (= raw order=9 が array[0] / Tempo order=0 が array[1] / ToneSelect order=5 が array[2]) を lowering すると、 出力は (tick, order) 順で Tempo (order=0) → FMToneLoad (order=1) → RawRegisterWrite (order=2) として正規化される。

`spike-fixtures/duplicate-tick-order.ir.json` (= (tick=0, trackId=0, order=0) を 2 件持つ valid v0.1 IR) は spike layer で exit 65 reject (= schema は uniqueness を強制しないが spike が enforce する safety gate の literal 実例)。

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

---

## IR → RawRegisterWrite lowering spike (v0.2)

「IR の chip 層から raw 層 (= YM2610 register write 列) に落ちる最小の道がある」 ことを示す read-only spike。 compiler 本体 / WebApp / runtime / driver / `.mn` / `.PNE` は touch しない。 ADR-0035 (= 26th session) で設計 fix。

### path / 入出力

- path: `scripts/ir-lower-raw-register-spike.py` (= chmod +x、 Python 3.10+)
- 入力: v0.2 ChipEvent lowered IR JSON (= `ir-lower-chipevent-spike.py` 出力想定、 Semantic→Chip lowering 完了済)
- 出力: v0.2 RawRegisterWrite (+ Tempo semantic pass-through) IR JSON

### lowering rule (= ADR-0035 §決定 1-9 整合)

| 入力 event | 出力 |
|---|---|
| `Tempo` (semantic) | semantic Tempo として pass-through 1 件 |
| `FMToneLoad` (chip) | `RawRegisterWrite` 25-29 件 (= DT/MUL/TL/KS,AR/AM,DR/SR/SL,RR × 4 op + AL/FB 1 + optional SSG-EG × 0-4 op) |
| `FMFrequency` (chip) | `RawRegisterWrite` 2 件 (= 0xA4 high → 0xA0 low 順序固定、 latch は 0xA0 write) |
| `KeyOn` (chip) | `RawRegisterWrite` 1 件 (= port 0 0x28、 data = `(operatorMask << 4) \| ch_code`) |
| `KeyOff` (chip) | `RawRegisterWrite` 1 件 (= port 0 0x28、 data = `ch_code`、 上 4 bit clear で全 op release、 §決定 7) |
| `ADPCMATrigger` (chip) | pass-through 1 件 (= chip layer 維持、 raw 化は別 sprint) |
| `RawRegisterWrite` (raw) | pass-through 1 件 |
| `Note` / `Rest` / `ToneSelect` (semantic) | exit 65 reject (= 前段 Semantic→Chip lowering 不徹底) |

### YM2610 routing (= ADR-0035 §決定 4)

| FM index (IR) | port | ch_offset | KeyOn ch_code |
|---:|---:|---:|---:|
| 1 / 2 / 3 | 0 | 0 / 1 / 2 | 0x00 / 0x01 / 0x02 |
| 4 / 5 / 6 | 1 | 0 / 1 / 2 | 0x04 / 0x05 / 0x06 |

KeyOn / KeyOff の 0x28 のみ port 0 で全 ch 制御 (= bit 2 で port 識別、 bit 0-1 で ch_offset)。

operator slot order (= ADR-0035 §決定 8、 YM2608/YM2610 仕様、 PMD/MewFM 整合): op1 → 0x00 / op2 → 0x08 / op3 → 0x04 / op4 → 0x0C。

### 順序 invariant

入力 IR は `(tick, trackId, order)` 昇順で sort 後、 linear scan で emit。 ChipEvent は 1 件 raw 複数件に展開、 展開列内部は tone → freq → keyon → keyoff 維持。 pass-through は 1 件をその layer/type のまま 1 件 emit。 output allocator が emit 順に order を再採番し、 最後に出力全体を `(tick, order)` で sort 正規化。 ADR-0035 §決定 9。

### timing 制約 / 重複 reject

`timing.timeMode` は `"absolute"` のみ受け付ける (= "delta" は exit 65 reject)。 同一 `(tick, trackId, order)` 重複は sort 前に exit 65 reject。 (= 25th session β spike 規律踏襲)

### 検証 command

```bash
python3 scripts/ir-lower-raw-register-spike.py <input.ir.json> [--output <path>] [--stats]
```

### 検証例

`spike-lowered-tiny-melody.ir.json` (= 25th session β output) を入力に連結再現:

```bash
python3 scripts/ir-lower-raw-register-spike.py \
  docs/design/intermediate-register-command/examples/v0.2/spike-lowered-tiny-melody.ir.json \
  --output /tmp/tiny-melody.rawlowered.ir.json --stats

diff docs/design/intermediate-register-command/examples/v0.2/spike-rawlowered-tiny-melody.ir.json \
  /tmp/tiny-melody.rawlowered.ir.json
```

期待: 8 events → 38 events (= raw 37 + semantic Tempo 1)、 diff 0 行 (= deterministic byte-identical)、 exit 0。

MML → v0.1 IR → v0.2 chip IR → v0.2 raw IR の full chain:

```bash
python3 scripts/mml-to-ir-spike.py \
  docs/design/intermediate-register-command/spike-fixtures/tiny-melody.mml \
  --output /tmp/tiny-melody.ir.json

python3 scripts/ir-lower-chipevent-spike.py \
  /tmp/tiny-melody.ir.json \
  --output /tmp/tiny-melody.chiplowered.ir.json

python3 scripts/ir-lower-raw-register-spike.py \
  /tmp/tiny-melody.chiplowered.ir.json \
  --output /tmp/tiny-melody.rawlowered.ir.json --stats

python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples /tmp/tiny-melody.rawlowered.ir.json
```

期待: MML 6 event → v0.1 IR 6 event → v0.2 chip IR 8 event → v0.2 raw IR 38 event、 validator exit 0 + 1/1 PASS。

### exit code (= ir-lower-raw-register-spike.py)

| code | 意味 |
|---|---|
| 0 | OK (= raw lowering 成功) |
| 64 | argument error (= input file not found / JSON parse error / required field missing) |
| 65 | lowering parse error (= semantic 残存 / toneId 未解決 / tone schema 違反 / scope 外 channel / range out / `timeMode != "absolute"` / `(tick, trackId, order)` 重複 等) |
| 66 | runtime error |

### fixture

- 入力 (= chain): `examples/v0.2/spike-lowered-tiny-melody.ir.json` (= 25th session β output)
- 出力例 (= 委員会 review 用 committed sample): `examples/v0.2/spike-rawlowered-tiny-melody.ir.json` (= 38 event 出力、 spike 再実行で byte-identical 再生可能な deterministic output、 26th session γ)
- spike-level reject 期待 (= negative): `examples/v0.2/spike-invalid/semantic-residual-note.ir.json` + `examples/v0.2/spike-invalid/fmtoneload-unresolved-toneid.ir.json` (= schema validation は PASS、 spike 実行で exit 65 reject、 26th session δ)
- 注: `examples/v0.2/spike-lowered-unsorted-events.ir.json` (= 25th session β output) は **本 spike (= raw lowering) の positive 入力としては成立しない**。 `tones[]` を持たないため `FMToneLoad` の toneId resolve が必ず失敗し、 raw spike では exit 65 となる。 これは chip spike の sort 正規化挙動を観察するための fixture であり、 raw spike chain には使わない。

### spike-level reject 検証 (= schema validation 経路と別軸)

```bash
# 各 spike-invalid fixture を spike に通して exit 65 reject 確認
for f in docs/design/intermediate-register-command/examples/v0.2/spike-invalid/*.ir.json; do
  python3 scripts/ir-lower-raw-register-spike.py "$f" > /dev/null
  echo "$f: exit=$?"
done

# 上記 fixture が schema validation 経路では PASS することも確認 (= 設計通り)
python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples 'docs/design/intermediate-register-command/examples/v0.2/spike-invalid/*.ir.json'
```

期待: 各 spike-invalid fixture が `exit=65`、 schema validation は `2/2 passed`。

### spike scope-out (= ADR-0035 §scope-out 抜粋)

- ADPCMATrigger raw 化 (= chip pass-through 維持、 別 sprint)
- Tempo の chip lowering (= `FMTimerSet` 等、 v0.3)
- FM3Mode / Volume / Pan / LoopStart / LoopEnd / ADPCMBDma
- SSG / ADPCM-B / rhythm_kr channel
- optimization / cache / 重複 register write 削減 / barrier 解決
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp / pitch correction / aesthetic audition / automated CI 化

---

## IR Tempo → FMTimerSet lowering spike (v0.3)

「IR semantic 層の Tempo から chip 層 FMTimerSet (= TIMER-B counter 設定) に落ちる最小の道がある」 ことを示す read-only spike。 ADR-0037 (= 27th session) で設計 fix。 compiler 本体 / WebApp / runtime / driver / `.mn` / `.PNE` は touch しない。

### path / 入出力

- path: `scripts/ir-lower-tempo-spike.py` (= chmod +x、 Python 3.10+)
- 入力: v0.2 / v0.3 IR JSON (= Tempo を semantic で含む)
- 出力: v0.3 IR JSON (= initial Tempo → FMTimerSet、 runtime Tempo は semantic pass-through)

### lowering rule (= ADR-0037 §決定 1-3 + §決定 6 整合)

| 入力 event | 出力 |
|---|---|
| **initial Tempo (semantic) 1 件のみ** (= `(tick, trackId, order)` 昇順 sort 後の最初に出現する Tempo) | `FMTimerSet` (chip) 1 件 (= 同 tick、 同 trackId、 counter=128 placeholder + bpm 保持) |
| 2 件目以降の `Tempo` (semantic) (= runtime tempo 変更) | pass-through (= ADR-0037 §決定 3-4 で sub-tick accumulator 委譲、 chip 化は defer) |
| 他全 event | pass-through (= allocator で order 再採番) |

### counter placeholder

ADR-0037 §決定 3 で「BPM → TIMER-B counter 変換式の数値 literal は driver runtime 軸 (= ADR-0036 関連別 ADR) 同期後に literal 化」 と defer 規律。 本 spike は `counter = 128` (= 中庸 8-bit 値、 placeholder)。 source `bpm` を traceability で保持。 production 用 literal 化は driver runtime 軸 fix 後の別 sprint。

### 検証 command

```bash
python3 scripts/ir-lower-tempo-spike.py <input.ir.json> [--output <path>] [--stats]
```

### 検証例

```bash
python3 scripts/ir-lower-tempo-spike.py \
  docs/design/intermediate-register-command/examples/v0.2/spike-lowered-tiny-melody.ir.json \
  --output /tmp/tempo.json --stats

diff docs/design/intermediate-register-command/examples/v0.3/spike-tempo-lowered-tiny-melody.ir.json /tmp/tempo.json
```

期待: 8 events → 8 events (= Tempo 1 → FMTimerSet 1 + 他 7 pass-through)、 diff 0 行 (= deterministic byte-identical)、 exit 0。

### exit code (= ir-lower-tempo-spike.py)

| code | 意味 |
|---|---|
| 0 | OK |
| 64 | argument error (= input file not found / JSON parse error / required field missing) |
| 65 | lowering parse error (= `timeMode != "absolute"` / `(tick, trackId, order)` 重複 / 必須 common field 欠落 / Tempo `bpm` 欠落・非正値・非数値 等) |
| 66 | runtime error |

### fixture

- 入力 (= chain): `examples/v0.2/spike-lowered-tiny-melody.ir.json` (= 25th session β output)
- 出力例 (= committed sample): `examples/v0.3/spike-tempo-lowered-tiny-melody.ir.json` (= 8 event 出力、 deterministic、 27th session δ)
- spike-level reject 期待 (= negative): `examples/v0.3/spike-invalid/tempo-bpm-missing.ir.json` + `examples/v0.3/spike-invalid/tempo-bpm-zero.ir.json` (= spike 実行で exit 65 reject、 27th session δ)

### v0.3 spike-level reject 検証 (= raw lowering spike と parity)

```bash
# 各 spike-invalid fixture を tempo spike に通して exit 65 reject 確認
for f in docs/design/intermediate-register-command/examples/v0.3/spike-invalid/*.ir.json; do
  python3 scripts/ir-lower-tempo-spike.py "$f" > /dev/null 2>&1
  code=$?
  echo "$(basename $f): exit=$code"
done
```

期待: 各 spike-invalid fixture が `exit=65` (= 全 2 件 reject)。 schema validation 経路は spike-invalid fixture が schema layer でも reject される (= tempo-bpm-missing は Tempo.bpm required violation、 tempo-bpm-zero は exclusiveMinimum 0 violation) ため raw chain の「schema PASS / spike reject」 二軸分離とは性質が違うが、 spike layer defense in depth 経路の literal 証跡として配置。

### spike scope-out (= ADR-0037 §scope-out 抜粋)

- BPM → counter 変換 literal (= 数値 literal defer)
- runtime tempo 変更の chip 化 (= sub-tick accumulator 委譲)
- 0x27 register bit 操作 (= bit 6 非破壊規律のみ、 他 defer)
- raw register write 展開 (= 26th session β raw spike chain と分離)
- driver / runtime / `.mn` / `.PNE` / `.NEO` / WebApp / FM3Mode / SSG / pitch correction / aesthetic / automated CI
