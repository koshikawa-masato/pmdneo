# ADR-0035: ChipEvent → RawRegisterWrite lowering spike — design fix (= v0.2 chip 4 event の YM2610 register 落とし込み / schema v0.3 不要判断 / FM-only minimal / driver runtime 不変 / 26th session 起点)

- 状態: **Draft** (= 2026-05-18 26th session 起票、 設計メモを ADR layer に昇格、 Accepted 移行は本 spike 4 commit chain 完走後 + user 最終確認時、 driver / fixture / verify script / runtime semantics 完全不変 doc + spike + fixture-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR: ADR-0034 (= IR design consolidation 6 軸 ratify、 IR は compiler / WebApp intermediate / JSON canonical / 3 層 hybrid の前提、 §17-3 で SemanticEvent → ChipEvent → RawRegisterWrite 段階 lowering を確定)、 PR #3 (= IR v0.1 schema + validator + MML → IR spike、 wip-intermediate-register-command branch)、 PR #4 (= IR schema v0.2 + ChipEvent 4 件 + Semantic → Chip lowering spike、 wip-ir-chipevent-lowering branch、 本 ADR の入力 source)
- 関連設計書: `docs/design/intermediate_register_command.md` §4-2 (= FM channel mapping、 port 0 / port 1 分割)、 §7 (= ChipEvent 詳細、 KeyOn / KeyOff / FMToneLoad / FMFrequency)、 §8 (= RawRegisterWrite escape hatch)、 §9 (= FMTone 構造、 algorithm / feedback / 4 operator)、 `docs/design/reference_intermediate_register_command.md` §3 (= OPNB / YM2610 特有の考慮点)、 `docs/design/intermediate-register-command/ir-schema-v0.2.schema.json` (= v0.2 schema、 RawRegisterWrite event 既定義)、 `scripts/ir-lower-chipevent-spike.py` (= 25th session β、 入力 source spike)

## 背景

24th session で ADR-0034 を起票し、 IR design 6 軸を確定 (= compiler intermediate / JSON canonical / 3 層 hybrid SemanticEvent → ChipEvent → RawRegisterWrite / FM3Mode ChipEvent + FMTone 共用 / sample reference only / `.NEO` candidate container)。 25th session で α = schema v0.2 minimal ChipEvent extension (= FMToneLoad / FMFrequency / KeyOn / KeyOff 追加、 commit 60c60e1) + β = Semantic → Chip lowering spike (= `scripts/ir-lower-chipevent-spike.py`、 commit de90ff9) を実装し、 PR #4 として stacked。 PR #4 review fix 3 件 (= timeMode delta reject / unsorted input sort / duplicate tick-order detect) を 3d7e50f まで反映し review-ready。

ADR-0034 §決定 3 で確定した 3 層 hybrid の lowering 段階は **Semantic → Chip → Raw** の 2 段。 PR #4 で 1 段目 (= Semantic → Chip) が成立した。 本 ADR は 2 段目 (= Chip → Raw) の最小 spike を設計し、 IR が YM2610 register write 列にまで到達できることを実証する。

これは IR が `.mn` (= Z80 driver 楽曲 binary) ではなく **abstract register command 列** にまで段階下降可能であることの proof で、 ADR-0034 §決定 1 (= IR は runtime ではなく compiler / WebApp intermediate) の literal 検証でもある。 spike が完走すれば、 IR から (driver semantics に依存しない形で) chip-level reproducible output が得られる前提が成立する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 spike 実装着手前に本 ADR で設計を fix する。 また CLAUDE.md §「記憶は AI に、 判断は自分が握る」 に従い、 spike 設計判断は本 ADR §決定 で literal 化し、 user ratify 済とする (= 26th session α、 user judgement「進めてよい」)。

## 決定

### 決定 1: 対象 ChipEvent は v0.2 minimal 4 件のみ

ChipEvent → Raw lowering の対象は v0.2 schema に追加済の 4 件のみ:

- `FMToneLoad`
- `FMFrequency`
- `KeyOn`
- `KeyOff`

scope 外:

- `ADPCMATrigger` は **pass-through** (= raw 化は別 sprint。 ADPCM-A driver layer 整合性は別軸で、 ADR-0019 step 5 native path が ground truth)
- `FM3Mode` / `Volume` / `Pan` / `LoopStart` / `LoopEnd` / `ADPCMBDma` は v0.3 以降 scope (= ADR-0034 §決定 3 の段階構造に従い、 別 ADR / spike で起票)
- SSG / ADPCM-B / rhythm_kr channel は v0.3 以降 scope

理由: ADR-0034 §決定 3 が最小集合確定済 / v0.2 schema は 4 件のみ chip event を追加した / 範囲を広げると 1 spike で扱える境界を越える / ADPCMATrigger の raw 落とし込みは ADPCM-A subsystem (= ADR-0019 step 5 + 後続 step) との整合が必要で本 spike 範囲外。

### 決定 2: pass-through は 3 種 (= Tempo / ADPCMATrigger / RawRegisterWrite)

入力 IR (= v0.2 lowered) に含まれる以下の event は raw 化せず pass-through する:

- `Tempo` (semantic): semantic 保持 (= ADR-0034 §決定 3 の 3 層 hybrid 維持、 chip 化は v0.3 `FMTimerSet` 等で別軸)
- `ADPCMATrigger` (chip): pass-through (= 決定 1 で raw 化 scope-out)
- `RawRegisterWrite` (raw): pass-through (= 既に raw layer)

pass-through 時の `order` は output allocator で再採番 (= 25th session β spike と同じ規律)。

### 決定 3: semantic 残存 (= Note / Rest / ToneSelect) は入力 reject

入力 IR に `Note` / `Rest` / `ToneSelect` (= semantic) が残存している場合は **exit 65 reject**。

理由: 本 spike は Semantic → Chip lowering を**前段で完了済**前提で動作する (= ADR-0034 §決定 3 の段階構造に従い、 chip → raw 段階で semantic 残存は前段不徹底)。 silent pass を許すと「semantic 通過しただけの raw 出力」 が trace 上 chip lowering 完了と区別できない。

### 決定 4: YM2610 port / channel mapping (= 既存設計書 §4-2 整合)

FM channel index (IR canonical 1-6) と YM2610 port + ch_offset の対応:

| FM index (IR) | OPNB internal ch | port | ch_offset | KeyOn ch_code |
|---:|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 | 0x00 |
| 2 | 1 | 0 | 1 | 0x01 |
| 3 | 2 | 0 | 2 | 0x02 |
| 4 | 3 | 1 | 0 | 0x04 |
| 5 | 4 | 1 | 1 | 0x05 |
| 6 | 5 | 1 | 2 | 0x06 |

- port 0 = FM ch 1-3 + 共通 register (= 0x22 LFO / 0x27 FM3 mode / 0x28 KeyOn)
- port 1 = FM ch 4-6 専用 (= operator parameter / frequency)
- KeyOn 0x28 のみ port 0 で全 channel 制御 (= bit 2 で port 0/1 識別、 bit 0-1 で ch_offset)

根拠: `docs/design/intermediate_register_command.md` §4-2 FM channel mapping table 整合 + YM2608/YM2610 datasheet 流儀。 PMDNEO 既存 driver の register write でも同 mapping (= ADR-0010 § driver fix で確認済)。

### 決定 5: FMFrequency → 2 register writes (= 0xA4 high → 0xA0 low 順序固定)

`FMFrequency(block, fnum)` を 2 件の `RawRegisterWrite` に展開:

```
write 1: port = (ch >= 4) ? 1 : 0
         address = 0xA4 + ch_offset
         data = (block << 3) | (fnum >> 8)         # bit 5-3 = block, bit 2-0 = fnum high 3 bit
write 2: port = (ch >= 4) ? 1 : 0
         address = 0xA0 + ch_offset
         data = fnum & 0xFF                         # 下位 8 bit
```

**順序 invariant**: 必ず 0xA4 (high) 先 → 0xA0 (low) 後。 0xA0 への write が latch 確定。 逆順は YM2608/YM2610 で undefined。 spike は同 tick 内 emit 順を 0xA4 → 0xA0 の literal 順で生成、 sort 後も order 単調増加で順序維持。

### 決定 6: KeyOn → 0x28 single write (= mask + ch_code)

`KeyOn(operatorMask)` を 1 件の `RawRegisterWrite` に展開:

```
port = 0
address = 0x28
data = (operatorMask << 4) | ch_code
```

- `operatorMask` は schema 上 minimum 1 (= 25th session finding 3 反映済、 no-op KeyOn 防止)
- `ch_code` は決定 4 の table 参照

### 決定 7: KeyOff → 0x28 single write (= operatorMask 無視 / 全 op release)

`KeyOff(operatorMask)` を 1 件の `RawRegisterWrite` に展開:

```
port = 0
address = 0x28
data = ch_code                                      # 上 4 bit clear = 全 op release
```

**判断**: YM2610 の 0x28 key-on register は **bit 4-7 = 0** で「対象 channel の全 op release」 を意味する。 schema の `KeyOff.operatorMask` は semantic 層では「どの op を release するか」 を表現する余地があるが、 v0.2 raw lowering では「対象 channel の key off」 だけを出す方針とし、 operatorMask の完全な意味保存は v0.3 spike の範囲外とする (= 26th session user ratify「OK」)。

実装上は `ch_code` のみで raw data を構成 (= `(0 << 4) | ch_code` = `ch_code`)。

### 決定 8: FMToneLoad → 25 (+ optional SSG-EG 4) register writes

`FMToneLoad(toneId)` を `tones[]` から resolve し、 以下を出力:

- DT/MUL × 4 op = 4 件 (base 0x30)
- TL × 4 op = 4 件 (base 0x40)
- KS/AR × 4 op = 4 件 (base 0x50)
- AM/DR × 4 op = 4 件 (base 0x60)
- SR × 4 op = 4 件 (base 0x70)
- SL/RR × 4 op = 4 件 (base 0x80)
- SSG-EG × 0-4 op = 0-4 件 (base 0x90、 `ssgEg` field がある op のみ出力)
- AL/FB × 1 = 1 件 (0xB0 + ch_offset)

**operator slot order (= YM2608/YM2610 仕様)**:

| operator | slot offset |
|---:|---:|
| op1 | 0x00 |
| op2 | 0x08 |
| op3 | 0x04 |
| op4 | 0x0C |

(= op1/op3/op2/op4 の literal 並びで slot offset 0/4/8/12 が割り当てられる。 PMD / MewFM と同じ流儀。 これを間違えると音色全壊。)

**parameter byte encoding**:

| param 組 | base reg | byte 構成 |
|---|---:|---|
| DT, MUL | 0x30 | `((dt + 3) << 4) \| (mul & 0x0F)` (= dt signed -3..+3 → unsigned 0..7 bias) |
| TL | 0x40 | `tl & 0x7F` |
| KS, AR | 0x50 | `((ks & 0x03) << 6) \| (ar & 0x1F)` |
| AM, DR | 0x60 | `((am ? 1 : 0) << 7) \| (dr & 0x1F)` |
| SR | 0x70 | `sr & 0x1F` |
| SL, RR | 0x80 | `((sl & 0x0F) << 4) \| (rr & 0x0F)` |
| SSG-EG | 0x90 | `ssgEg & 0x0F` |
| AL, FB | 0xB0 | `((feedback & 0x07) << 3) \| (algorithm & 0x07)` |

**判断 (= SSG-EG optional)**: schema 上 `ssgEg` は operator の optional field。 入力に存在する op のみ 0x90 系 register を出力 (= 26th session user ratify「OK」)。 schema 上 optional な field を無理に register write しない。

**判断 (= tone cache しない)**: 同一 toneId への FMToneLoad が連続しても spike は毎回全 register を出力する (= 26th session user ratify「OK」)。 重複削減 / cache / 最適化は後続 sprint で別 ADR。

**toneId resolve 失敗**: 入力 IR の `tones[]` に該当 `toneId` が無ければ exit 65 reject。

`toneId` resolve した tone が `FMTone` schema (= ADR-0034 §9) に違反していたら exit 65 reject (= defense in depth)。

### 決定 9: 同 tick 内 emit 順序

同 tick で複数 ChipEvent を raw 化する場合、 spike 内部で次の擬似順序を保証:

1. `FMToneLoad` 展開 (= 25-29 件)
2. `FMFrequency` 2 件 (= 0xA4 → 0xA0)
3. `KeyOn` 1 件 (= 0x28)
4. `KeyOff` は通常別 tick (= note_tick + duration) で同 tick 衝突は稀、 衝突時は入力 order に従う

**根拠**: YM2608/YM2610 では「tone 設定 → frequency 設定 → keyon」 の順序が必須 (= keyon 時に有効値が register に乗っている必要)。 PR #4 25th session β spike が semantic Note → 3 chip events (FMFrequency + KeyOn 同 tick、 KeyOff = tick + duration) を生成する規律と整合。

pass-through (= ADPCMATrigger / RawRegisterWrite) は入力順を維持。 異 chip event 間の order 衝突は output allocator で再採番。

**同 tick pass-through 混在時の規律** (= 25th session β spike の lower_events 規律と整合): 入力 IR を `(tick, trackId, order)` 昇順で sort 後、 linear scan で emit する。 同 tick 内で pass-through (= ADPCMATrigger / RawRegisterWrite) と ChipEvent が混在する場合、 入力 `order` 順に展開 = 先に来た event を先に emit。 ChipEvent 1 件は raw 複数件に展開されるが、 展開列内部は「tone → freq → keyon (→ keyoff)」 を維持。 pass-through は 1 件をその layer/type のまま 1 件 emit (= `ADPCMATrigger` は chip 1 件 / `RawRegisterWrite` は raw 1 件 / `Tempo` は semantic 1 件)。 output allocator が emit 順に order を再採番し、 最後に出力全体を `(tick, order)` で sort して正規化する。

### 決定 10: schema v0.3 不要

本 spike では schema v0.3 を**追加しない**。

理由:

- 出力は v0.2 既存 `RawRegisterWrite` (= `layer="raw"`, `type="RawRegisterWrite"`) のみ
- v0.2 schema は `RawRegisterWrite` event を fully validate 済 (= port 0-1 / address 0-255 / data 0-255)
- ChipEvent → Raw は同じ v0.2 schema 内での層下降
- 新規 event 種は本 spike では追加しない
- 既存 v0.2 fixture (= chip events 含む) も schema 上 unchanged

v0.3 が必要になる場面 (= 本 sprint scope-out):

- `FMTimerSet` (= Tempo の chip lowering)
- `ADPCMATrigger` → raw lowering (= ADPCM-A driver layer 整合)
- `FM3Mode` / `Volume` / `Pan` / `LoopStart` / `LoopEnd` / `ADPCMBDma`
- SSG event 群

これらは別 ADR / spike で起票。

### 決定 11: 実装後の strict validation は schema 変更ではなく spike 防衛層

26th session β 実装で追加された `type(x) is int` 厳密判定、 `am` bool 厳密判定、 `block` / `fnum` / `operatorMask` 範囲判定、 `tones[]` 同一 `toneId` 重複 reject、 tone schema 違反 reject は **v0.2 schema の意味変更ではなく spike 防衛層**として扱う。

選択肢:

- **A. schema v0.3 を起こして validation を schema 側へ移す**: JSON Schema 上の表現は明確になるが、 event 種追加なしで version を上げるため version churn が発生する。
- **B. v0.2 schema は維持し、 spike 内 defense in depth として reject する**: schema 互換を守りつつ、 Python / JSON の bool-is-int silent pass 等を実装層で塞げる。
- **C. validation を緩めて schema のみを正とする**: 実装は単純だが、 register byte 生成時の silent corruption を防げない。

**採用: B**。 本 ADR の判断は「RawRegisterWrite event 種を既存 v0.2 で使う」ことであり、 strict validation は spike 実装の安全柵である。 後続で importer / compiler 共有 validation が必要になった時点で、 schema v0.3 ではなく validator helper の共通化を先に検討する。

### 決定 12: positive fixture の期待値は 38 events (= raw 37 + Tempo 1) に固定

`spike-lowered-tiny-melody.ir.json` を入力した raw lowering の canonical expected count は **38 events** とする。

- `FMToneLoad` 1 件 → 29 raw writes (= SSG-EG 4 op field が存在するため 25 + 4)
- `FMFrequency` 2 件 → 4 raw writes
- `KeyOn` 2 件 → 2 raw writes
- `KeyOff` 2 件 → 2 raw writes
- `Tempo` 1 件 → semantic pass-through

合計は raw 37 + semantic Tempo 1 = 38 events。 既存 §verify 計画 A の 34-38 events 幅は SSG-EG optional の一般式として残し、 本 fixture 固有の期待値は 38 events に固定する。

選択肢:

- **A. 件数幅 34-38 のまま fixture 判定する**: optional SSG-EG の一般性は残るが、 fixture regression として緩すぎる。
- **B. fixture 固有値 38 を固定し、一般式 34-38 は仕様説明として残す**: regression が機械判定しやすく、 SSG-EG optional 仕様も維持できる。
- **C. SSG-EG を fixture から除去して 34 events にする**: 最小化はできるが、 optional SSG-EG emit の proof が失われる。

**採用: B**。 fixture は byte-identical 再生成の対象なので、 実 fixture の件数は固定値として扱う。

### 決定 13: 本 ADR の verify gate は schema / byte-identical / script regression まで

本 ADR の verify gate は docs + script + fixture 層に限定し、 driver / runtime / audio gate は要求しない。

選択肢:

- **A. raw register 列を MAME 実行まで接続して音で確認する**: end-to-end の安心感はあるが、 `.mn` 生成 / driver bridge / runtime fixture が必要になり本 ADR scope を越える。
- **B. JSON schema validate + spike 再実行 byte-identical + negative reject + 既存 v0.1/v0.2 regression に限定する**: ADR-0034 の「IR は compiler / WebApp intermediate」責務に合い、 driver 不変を守れる。
- **C. verify なしで設計 ADR のみ完了とする**: doc-only としては成立するが、 raw lowering spike の proof には足りない。

**採用: B**。 audio audition が必要な箇所は本 ADR では発生しない。 後続の driver trace 比較や FM/SSG 実音確認では **user gate 必要**として扱い、 本 ADR ではスキップする。

### 決定 14: Tempo raw lowering は ADR-0035 では閉じず、 v0.3 `FMTimerSet` 候補へ送る

Tempo を raw register write へ落とす判断は本 ADR では確定しない。

選択肢:

- **A. YM2610 Timer A/B register write へ直ちに lowering する**: raw 出力の完結性は上がるが、 tempo 単位 / timer 分周 / driver tick source の責務が混ざる。
- **B. `Tempo` は semantic pass-through のまま維持し、 v0.3 `FMTimerSet` または driver bridge ADR で扱う**: ADR-0034 の 3 層構造を守り、 runtime tick 設計を先送りできる。
- **C. Tempo を drop する**: raw register 列のみを見れば単純だが、 IR の音楽的意味を壊す。

**採用: B**。 Tempo は raw register lowering の未完ではなく、 runtime clock / driver bridge 側の別責務として残す。

### 決定 15: ADR-0036 / FM driver 軸への接続は「仕様 oracle」であり branch blocker ではない

ADR-0035 の RawRegisterWrite 出力は、 FM/SSG driver 軸で期待 register trace を作る際の **仕様 oracle**として使える。 ただし ADR-0035 Accepted 完了を FM/SSG 軸着手の blocking condition にはしない。

選択肢:

- **A. ADR-0035 Accepted 後まで FM/SSG 軸を止める**: 仕様同期は強いが、 並走方針に反する。
- **B. ADR-0035 Draft の §決定 1-14 を仕様 oracle として使い、 driver trace fixture は後続 ADR で独立 verify する**: 並走しつつ、 register 仕様の重複判断を避けられる。
- **C. FM/SSG driver 軸は ADR-0035 と完全に切り離す**: 独立性は高いが、 同じ YM2610 register 仕様を二重に決める risk がある。

**採用: B**。 ADR-0036 ではこの接続を「IR 出力 = 期待 trace の候補」として受け、 driver 実装 commit では MAME / ymfm trace / audio gate を別途満たす。

### 決定 16: ADR-0035 の完了判定は Draft 維持 + 後続 commit chain の明示で閉じる

本 session では ADR-0035 を Accepted に移行しない。 Draft のまま、 raw lowering spike の残り判断を本 §決定 11-16 に literal 化して閉じる。

選択肢:

- **A. 本 doc 追記 commit で Accepted にする**: 判断は閉じるが、 fixture / negative / regression chain が別 commit として残る場合に状態が先行する。
- **B. Draft 維持で残り判断を閉じ、 Accepted 移行は spike fixture / regression commit chain 完走後の user 最終確認へ送る**: 状態と実体のずれを避けられる。
- **C. ADR-0035 を ADR-0036 に統合する**: IR raw lowering と FM/SSG 並走方針の責務が混ざる。

**採用: B**。 ADR-0035 は IR ChipEvent → RawRegisterWrite lowering spike の ground truth として Draft 維持、 ADR-0036 は FM/SSG 並走方針の別 ADR として新規起票する。

## scope-out (= 本 ADR / spike 不可触)

- driver / runtime 変更なし (= `src/sound/` 配下不変)
- `.mn` / `.PNE` / `.NEO` 生成なし
- WebApp 実装なし
- full PMD parser なし (= 25th session α MML → IR spike は別 sprint で固定)
- ADPCM lowering なし (= ADPCMATrigger は pass-through)
- FM3Mode lowering なし
- 実機 pitch 補正なし
- optimization / cache / 重複削減なし
- aesthetic / audio audition なし (= 純粋に schema + script + fixture 範囲)
- 既存 driver / runtime semantics 不変
- PR #3 / PR #4 内容を壊さない (= 新 branch `wip-ir-raw-register-lowering` + 既存 schema/spike 不変)
- `vendor/ngdevkit-examples/06-sound-adpcma/assets/*.wav` 3 件 (= 26th session 開始時 untracked) 触らない
- vendor 配下全般触らない (= memory `project_pmdneo_branch_strategy` 系規律)

## verify 計画

### A. positive fixture

- `docs/design/intermediate-register-command/examples/v0.2/spike-rawlowered-tiny-melody.ir.json` 新規
  - 入力 = `spike-lowered-tiny-melody.ir.json` (= 25th session β output、 PR #4 commit chain で確立)
  - 入力 event 内訳 (= 実 fixture 計測値): total 8 件 = semantic Tempo 1 + chip FMToneLoad 1 + chip FMFrequency 2 + chip KeyOn 2 + chip KeyOff 2
  - spike 実行 → 出力 byte-identical fixture 化
  - 期待 event 数 (= raw 展開):
    - FMToneLoad 1 件 → 25-29 raw writes (= SSG-EG field の有無で 25 or 29)
    - FMFrequency 2 件 → 2 × 2 = 4 raw writes
    - KeyOn 2 件 → 2 raw writes
    - KeyOff 2 件 → 2 raw writes
    - Tempo 1 件 → semantic pass-through (= raw 化しない、 そのまま output に含む)
    - **total = 33-37 raw + 1 semantic = 34-38 events**

### B. negative fixtures (= spike-level reject、 schema validation では PASS する)

**配置 path**: `docs/design/intermediate-register-command/examples/v0.2/spike-invalid/` (= 既存 `examples/v0.2/invalid/` は schema layer reject 用で、 spike layer reject は別 directory に分離。 schema validation 経路 (= `validate-ir-schema.py --invalid-examples ...`) に spike-level fixture を混入させると「reject expected, passed」 で誤検出するため)

- `spike-invalid/semantic-residual-note.ir.json`
  - 入力 = Note (semantic) を含む schema-valid な v0.2 IR
  - 期待 = spike `ir-lower-raw-register-spike.py` 実行で exit 65 reject (= 決定 3)
  - schema validation: PASS (= Note は v0.2 schema で valid event)

- `spike-invalid/fmtoneload-unresolved-toneid.ir.json`
  - 入力 = FMToneLoad で参照する `toneId` が `tones[]` に存在しない schema-valid な v0.2 IR
  - 期待 = spike `ir-lower-raw-register-spike.py` 実行で exit 65 reject (= 決定 8)
  - schema validation: PASS (= toneId reference 整合は schema 表現外、 spike layer で enforce)

**verify approach** (= schema validation 経路と別軸):

```bash
python3 scripts/ir-lower-raw-register-spike.py <fixture> > /dev/null
# 期待 exit code: 65
```

shell exit code 確認で reject 検証。 schema validation 経路 (= `validate-ir-schema.py`) には混入させない。

### C. regression

- v0.1 fixture 全件 (= PR #3 baseline) validator PASS 維持
- v0.2 fixture 全件 (= PR #4 baseline) validator PASS 維持
- 既存 spike `ir-lower-chipevent-spike.py` の 6 spike-fixture 出力 byte-identical 維持

### D. exit codes (= 既存 spike と同)

| exit | 意味 |
|---|---|
| 0 | OK |
| 64 | argument error (= input not found / JSON parse / required field missing) |
| 65 | lowering error (= semantic 残存 / toneId resolve 失敗 / scope 外 event / MIDI 範囲外 等) |
| 66 | runtime error (= unexpected exception) |

## 後続 sprint 想定 (= 別 ADR)

- v0.3 schema: FMTimerSet (= Tempo lowering)、 Volume / Pan ChipEvent、 LoopStart / LoopEnd、 FM3Mode、 ADPCMBDma
- ADPCMATrigger → raw lowering (= ADPCM-A driver integration 軸)
- SSG event 群追加
- optimization layer (= tone cache、 重複 register write 削減、 barrier 解決)
- driver runtime と IR の bridge layer (= `.mn` 生成 spike)

これらは本 ADR scope-out。

## Annex

### A-1. 26th session α 起点 commit chain 想定

| commit | 内容 |
|---|---|
| α | ADR-0035 起票 (= 本 commit) |
| β | `scripts/ir-lower-raw-register-spike.py` 実装 |
| γ | positive fixture `spike-rawlowered-tiny-melody.ir.json` 追加 + chip → raw 連結確認 |
| δ | negative fixture 2 件 (= semantic-residual-note + fmtoneload-unresolved-toneid) + 全 regression PASS |

各 commit ごとに push (= memory `feedback_push_per_commit`)、 各 commit 前に平易日本語報告 (= memory `feedback_explain_in_plain_japanese_before_commit`)、 commit 後に決め書式報告 (= memory `feedback_post_commit_push_report_format`)。

### A-2. 入力 IR 想定 source

本 spike の標準入力は **25th session β `ir-lower-chipevent-spike.py` の出力 IR**。 すなわち PR #4 で確立した「Semantic → Chip lowering 完了済 IR」。 chip→raw lowering 単独動作 + chip lowering spike output との連結再現が proof の中心。
