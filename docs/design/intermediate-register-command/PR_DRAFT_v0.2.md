# PR Draft: IR schema v0.2 minimal ChipEvent extension + IR → ChipEvent lowering spike

## 1. Overview

この branch (`wip-ir-chipevent-lowering`) は、 PR #3 (= `wip-intermediate-register-command`、 IR design + schema v0.1 + MML → IR spike) を base に、 IR schema v0.2 で minimal ChipEvent 4 件を ratify、 IR v0.1 SemanticEvent → v0.2 ChipEvent lowering spike を成立させたものです。

これにより MML → SemanticEvent IR v0.1 → ChipEvent IR v0.2 の 2 段 pipeline が、 doc / helper / spike-only で literal に成立し、 IR の「中間表現」 としての価値が具体化しました。

driver / fixture / verify script (= legacy step5-18) / runtime semantics は完全不変です。 compiler 本体 / WebApp / `.mn` / `.PNE` / `.NEO` 生成 path も touch しません。

## 2. Branch / Scope

- **branch**: `wip-ir-chipevent-lowering`
- **base**: `wip-intermediate-register-command` (= PR #3、 tip `2733d19`、 stacked PR pattern)
- **commit chain**: 2 commit (= α schema v0.2 + β lowering spike)
- **runtime / driver**: 完全不変 (= 全 commit doc / helper / spike-only)
- **PR target**: PR #3 merge 後に main へ retarget (= 通常 stacked PR workflow)。 PR #3 と並行 review 可。

## 3. What's Included

### 3-1. schema v0.2 minimal ChipEvent extension (= commit α、 `60c60e1`)

v0.1 baseline (= 6 件) に minimal ChipEvent 4 件を追加。 全 chip layer:

| layer | type | required field | 用途 |
|---|---|---|---|
| chip | `FMToneLoad` | channel (FM only) / toneId | ToneSelect の chip lowering 後の形 |
| chip | `FMFrequency` | channel / block (0-7) / fnum (0-2047) | YM2610 FM frequency 設定 |
| chip | `KeyOn` | channel / operatorMask (省略時 15) | FM ch keyon |
| chip | `KeyOff` | channel / operatorMask (省略時 15) | FM ch keyoff |

v0.2 minimal scope = **FM ch のみ** (= `FMChannelId` const `"fm"` で schema literal 化)。 ADPCM-A keyon は既存 `ADPCMATrigger` 経由。 SSG / FM3Mode / Volume / Pan / Loop / ADPCM-B は v0.3 以降。

backwards-compatible (= v0.1 fixture 全件 + v0.1 invalid 全件が v0.2 schema 下でも v0.1 schema と同 PASS / 同 reject)。

#### 追加 file

- `docs/design/intermediate-register-command/ir-schema-v0.2.schema.json` (= +400 行、 v0.1 baseline + 4 chip event + `FMChannelId` $def)
- `docs/design/intermediate-register-command/examples/v0.2/chipevent-fm-note-lowered.ir.json` (= positive、 minimal-fm-note の Note を chip layer 3 件 + Tempo + FMToneLoad に展開した hand-crafted)
- `docs/design/intermediate-register-command/examples/v0.2/keyon-keyoff-minimal.ir.json` (= positive、 chip KeyOn / KeyOff 単体、 operatorMask 省略時 default = 15 動作確認)
- `docs/design/intermediate-register-command/examples/v0.2/invalid/fmfrequency-out-of-range.ir.json` (= negative、 block=8 / fnum=2048 maximum violation)
- `docs/design/intermediate-register-command/examples/v0.2/invalid/keyon-non-fm-channel.ir.json` (= negative、 KeyOn channel.kind="ssg" FMChannelId violation)
- `docs/design/intermediate-register-command/README.md` 修正 (= v0.2 構成 / event type 表 / 検証 command 追加)

### 3-2. IR → ChipEvent lowering spike (= commit β、 `de90ff9`)

v0.1 IR JSON 入力 → v0.2 IR JSON 出力 の read-only spike。 compiler 本体 / WebApp / runtime / driver は touch しない。

#### lowering rule

| 入力 (= v0.1 event) | 出力 |
|---|---|
| `Tempo` (semantic) | `Tempo` (semantic) として **そのまま保持** |
| `ToneSelect` (semantic, channel.kind=fm) | `FMToneLoad` (chip) 1 件、 同 tick |
| `Note` (semantic, channel.kind=fm) | `FMFrequency` (chip) + `KeyOn` (chip) 同 tick 2 件 + `KeyOff` (chip) tick+duration 1 件、 計 3 件 |
| `Rest` (semantic) | 出力なし (= tick 進行のみ、 free slot 扱い) |
| `ADPCMATrigger` (chip) | pass-through |
| `RawRegisterWrite` (raw) | pass-through |

#### Tempo の扱い (= user 指示で明示)

`Tempo` は **semantic 層に保持** (= lowering output から除外しない)。

理由:

- v0.2 minimal scope の ChipEvent (= FMToneLoad / FMFrequency / KeyOn / KeyOff) に Tempo 等価物はない
- chip / driver level の tempo は YM2610 Timer A/B register write (= RawRegisterWrite level) で表現するのが正しく、 v0.3 以降の `FMTimerSet` 等で別 sprint に分離
- spike は Tempo を semantic 層のまま下流 (= compiler / runtime translator / WebApp) に流し、 chip lowering 判断は下流に委ねる

#### channel / operator scope

- ToneSelect / Note は **channel.kind = "fm" のみ** lowering。 他 kind (= SSG / ADPCM-A / ADPCM-B / rhythm_kr) は exit 65 で reject (= silent pass 防止、 v0.2 minimal scope 外)
- KeyOn / KeyOff の `operatorMask` は spike では常に `15` (= 全 op 有効) を emit。 op 個別制御は v0.3 以降

#### block/fnum の責務境界 (= 重要な明示、 25th session user 指摘)

spike の `block` (= 0-7) / `fnum` (= 0-2047) は **ChipEvent 層の暫定 frequency 表現** であり、 **最終 register 値ではない**。

- ChipEvent layer = chip-conceptual な抽象表現 (= 3-bit block + 11-bit fnum + operatorMask 等)
- v0.3 以降の raw register lowering で実 YM2610 register byte layout (= reg 0xA0/0xA4 系の low/high byte split、 fnum block 合成、 keyon reg 0x28 mask encoding) に合わせて再変換される
- 値域は YM2610 仕様に合わせて schema 上で 0-7 / 0-2047 として制約済だが、 spike が emit する具体値 (= FNUM_TABLE 1-octave reference) は PMD V4.8s 系 OPN 流の代表値であり、 実機での pitch 整合 / 補正は v0.3 raw lowering + driver runtime 検証で確定する
- 本 PR の責務は「semantic → chip 階層差を literal に証明する」 ことであり、 chip → register の byte 配置 / 実周波数精度は別 sprint scope

この境界を守ることで、 raw register lowering で pitch 値や register byte 配置にズレが見つかっても、 v0.2 ChipEvent 層の責務は破綻しない。

#### MIDI → block/fnum 変換 (= spike 内)

PMD o5 c = MIDI 60 = C4 を基準に:

- `block = (midi // 12) - 1`     (= MIDI 60 (C4) → block 4)
- `semitone = midi % 12`
- `fnum = FNUM_TABLE[semitone]`

`FNUM_TABLE` (= PMD V4.8s OPN 流 1 octave reference): C=617 / C#=654 / D=693 / D#=734 / E=778 / F=824 / F#=873 / G=925 / G#=980 / A=1038 / A#=1100 / B=1165

block 範囲外 (= MIDI 0-11 / 108-127) は exit 65 reject (= silent pass 防止)。

#### 追加 file

- `scripts/ir-lower-chipevent-spike.py` (= +253 行、 chmod +x、 Python 3.10+)
- `docs/design/intermediate-register-command/examples/v0.2/spike-lowered-tiny-melody.ir.json` (= tiny-melody.mml chain の 8 event 出力、 reviewer 用 committed sample、 spike 再実行で deterministic 再生可能)
- `docs/design/intermediate-register-command/README.md` 修正 (= lowering spike セクション +122 行、 lowering rule / Tempo 扱い / block-fnum 計算 / CLI / 検証例 / scope-out)

## 4. Scope Out

本 PR には以下を **含めない** (= 25th session user 指示遵守):

- driver / runtime 変更
- `.mn` / `.PNE` / `.NEO` 生成 path
- WebApp 実装
- full PMD parser (= spike は tiny PMD subset の既存 mml-to-ir-spike を再利用)
- raw register write lowering (= chip event は block/fnum / operatorMask 抽象維持)
- ADPCM lowering (= ADPCMATrigger は pass-through、 ADPCM-B は v0.3+)
- FM3Mode (= 軸 4、 v0.3)
- Volume / Pan / LoopStart / LoopEnd (= chip event 拡張、 v0.3)
- SSG channel 系 chip event (= v0.3)
- gate / tie / velocity / chord / portamento / LFO (= SemanticEvent 拡張、 v0.3+)
- automated CI 化
- vendor untracked wav touch (= `vendor/ngdevkit-examples/06-sound-adpcma/assets/*.wav` は scope 外、 一切触らない)

PR #3 内容 (= v0.1 schema / spike script / 既存 fixture) も不変。

## 5. Verification

repo root で実行。

### 5-1. v0.1 baseline regression

```bash
python3 scripts/validate-ir-schema.py \
  --invalid-examples 'docs/design/intermediate-register-command/examples/invalid/*.ir.json'
```

期待: `Valid examples: 3/3 passed` + `Invalid fixtures: 6/6 correctly rejected` + exit 0 (= PR #3 既存 fixture 退化なし)

### 5-2. v0.2 schema positive + negative

```bash
python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples 'docs/design/intermediate-register-command/examples/v0.2/*.ir.json' \
  --invalid-examples 'docs/design/intermediate-register-command/examples/v0.2/invalid/*.ir.json'
```

期待: `Valid examples: 3/3 passed` (= chipevent-fm-note-lowered / keyon-keyoff-minimal / spike-lowered-tiny-melody) + `Invalid fixtures: 2/2 correctly rejected` (= fmfrequency-out-of-range / keyon-non-fm-channel) + exit 0

### 5-3. v0.1 backwards compatibility (= v0.2 schema で v0.1 fixture を validate)

```bash
python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples 'docs/design/intermediate-register-command/examples/*.ir.json' \
  --invalid-examples 'docs/design/intermediate-register-command/examples/invalid/*.ir.json'
```

期待: v0.1 positive 3/3 PASS + v0.1 invalid 6/6 correctly rejected + exit 0 (= v0.2 schema は v0.1 fixture を v0.1 schema と同じ判定で扱う)

### 5-4. lowering spike chain 1 (= minimal-fm-note 直接)

```bash
python3 scripts/ir-lower-chipevent-spike.py \
  docs/design/intermediate-register-command/examples/minimal-fm-note.ir.json \
  --output /tmp/spike-out-minimal-fm-note.ir.json --stats

python3 scripts/validate-ir-schema.py \
  --schema docs/design/intermediate-register-command/ir-schema-v0.2.schema.json \
  --examples /tmp/spike-out-minimal-fm-note.ir.json
```

期待: lowered 4 events → 5 events (= stats: tempo_kept=1 / tone_select_lowered=1 / note_lowered=1 / rest_dropped=1) + validator exit 0 + 1/1 PASS

### 5-5. lowering spike chain 2 (= MML → v0.1 IR → v0.2 IR)

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

期待: MML 6 event → v0.1 IR 6 event → v0.2 IR 8 event (= Tempo + FMToneLoad + FMFrequency(C4) + KeyOn + KeyOff + FMFrequency(E4) + KeyOn + KeyOff) + stats: tempo_kept=1 / tone_select_lowered=1 / note_lowered=2 / rest_dropped=2 + validator exit 0 + 1/1 PASS

### 5-6. spike error path

```bash
echo '{"metadata":{"magic":"PMDNEO-IR","version":1,"sourceDialect":"unknown","createdBy":"test"},"targetProfile":"ym2610b","timing":{"ticksPerBeat":192},"channels":[],"events":[{"tick":0,"order":0,"layer":"semantic","type":"Note","channel":{"kind":"ssg","index":1},"note":60,"duration":192}]}' \
  | python3 scripts/ir-lower-chipevent-spike.py /dev/stdin --output /tmp/x.ir.json; echo "exit=$?"
```

期待: `[FAIL] lowering error: Note channel.kind = 'ssg' は v0.2 minimal scope (= FM only) 外` + exit 65 (= non-fm reject、 silent pass 防止)

### 検証 summary (= 期待 result)

| test | expected |
|---|---|
| 5-1. v0.1 regression | positive 3/3 + invalid 6/6 reject |
| 5-2. v0.2 positive + negative | positive 3/3 + invalid 2/2 reject |
| 5-3. v0.1 backwards compat | positive 3/3 + invalid 6/6 reject (v0.2 schema 下で) |
| 5-4. spike chain 1 (minimal-fm-note) | 4 → 5 events + 1/1 PASS |
| 5-5. spike chain 2 (tiny-melody) | MML 6 → v0.1 6 → v0.2 8 events + 1/1 PASS |
| 5-6. spike error path | exit 65 |

## 6. Key Files

| path | 役割 |
|---|---|
| `docs/design/intermediate-register-command/ir-schema-v0.2.schema.json` | JSON Schema v0.2 (= v0.1 baseline + 4 chip event + FMChannelId) |
| `docs/design/intermediate-register-command/examples/v0.2/*.ir.json` | v0.2 positive fixtures 3 件 |
| `docs/design/intermediate-register-command/examples/v0.2/invalid/*.ir.json` | v0.2 negative fixtures 2 件 |
| `scripts/ir-lower-chipevent-spike.py` | IR v0.1 → v0.2 lowering spike |
| `docs/design/intermediate-register-command/README.md` | v0.2 セクション + lowering spike セクション追加 |
| `docs/design/intermediate-register-command/PR_DRAFT_v0.2.md` | 本 file |

## 7. Commit Chain

| # | commit | 内容 |
|---|---|---|
| α | `60c60e1` | IR schema v0.2 minimal ChipEvent extension (= FMToneLoad / FMFrequency / KeyOn / KeyOff、 v0.1 backwards compatible、 FMChannelId const "fm"、 positive 2 + negative 2 fixture) |
| β | `de90ff9` | IR → ChipEvent lowering spike (= v0.1 SemanticEvent → v0.2 ChipEvent、 Tempo semantic 保持、 Note → FMFrequency + KeyOn + KeyOff、 ToneSelect → FMToneLoad、 Rest drop、 ADPCMATrigger / RawRegisterWrite pass-through、 channel FM-only、 MIDI → block/fnum 変換) |
| γ | (本 commit) | PR_DRAFT_v0.2.md 追加 + block/fnum 暫定表現の責務境界明示 |

## 8. Next Work

本 PR merge 後の implementation candidate (= 別 branch / 別 sprint):

- **raw register lowering spike** (= ChipEvent → RawRegisterWrite、 YM2610 reg 0xA0/0xA4 fnum/block byte split + reg 0x28 keyon encoding + reg 0x30 系 tone load 展開、 block/fnum の実 register byte 整合確認)
- **FMTimerSet ChipEvent** (= chip-level tempo 設定、 YM2610 Timer A/B 基準、 Tempo (semantic) lowering target)
- **v0.3 schema 拡張** (= FM3Mode / Volume / Pan / LoopStart / LoopEnd / ADPCMBDma / SSG chip event 等)
- **PMD importer spike** (= PMD MML → IR、 #Zenlen → PPQN 変換 + tone import + 多 part 対応、 memory `project_ir_ppqn_vs_pmd_zenlen_distinction` 適用)
- **WebApp integration** (= IR を WebApp 編集 / preview / build pipeline と接続、 Phase 3-4)

## 関連 ADR / docs

| ADR / doc | 関連 |
|---|---|
| ADR-0034 | IR design consolidation (= §決定 1-6 ratify、 PR #3 で起票 Draft) |
| PR #3 | IR design + schema v0.1 + MML → IR spike (= 本 PR の base、 stacked PR pattern) |
| memory `project_ir_ppqn_vs_pmd_zenlen_distinction` | IR PPQN ticks vs PMD #Zenlen 192 内部 convention の区別 (= spike chain 2 で守られている) |
| memory `project_pmd_voice_ml_verified` | PMD o5 c = MIDI 60 = C4 (= MIDI → block/fnum 変換の基準) |

## 検証履歴 (= 25th session で実施した検証 evidence)

- schema v0.2 meta-validation: PASS (= draft-2020-12 として正当)
- v0.2 positive 3 件: 全 PASS (= hand-crafted 2 件 + spike output 1 件)
- v0.2 negative 2 件: 全 correctly rejected
- v0.1 regression: 3/3 PASS + 6/6 reject (= 退化なし)
- v0.1 backwards compat under v0.2 schema: 3/3 PASS + 6/6 reject (= v0.2 schema は v0.1 を superset として扱う)
- spike chain 1 (minimal-fm-note 直接): 4 → 5 events + schema validate PASS
- spike chain 2 (tiny-melody MML → v0.1 → v0.2): 6 → 6 → 8 events + schema validate PASS
- spike error path 2 件 (non-fm channel / MIDI out-of-range): 全 exit 65 reject
- driver / fixture / verify script (= legacy step5-18) / runtime semantics: 完全不変

CLAUDE.md §動作確認義務 = driver / runtime 層を touch する commit が無いため emulator 起動 / 動作確認は不要。 doc / helper / spike-only PR 構成。
