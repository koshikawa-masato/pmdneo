# ADR-0024 step 10 γ handoff: mismatch silent verify (= 0xFD32 = 0xFF state で ADPCM-A keyon-related register writes 不発生確認、 driver 不変、 verify infra 中心)

- 日付: 2026-05-14 (= 11th session、 γ 着手)
- 対応 ADR: [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 3 (= 2-C mismatch silent) / §決定 8 γ
- 関連 commit: 本 handoff doc を含む γ 着手 commit

## γ scope (= 1 commit + 1 push)

> **重要境界 (= future contributor 向け短文明記)**: Step 10 γ は **β で実装した mismatch silent 動作の動的検証 commit**。 driver source は **完全不変**、 `src/test-fixtures/step10/verify-step10-mismatch-silent.sh` 新規追加のみ。 mismatch silent は ADR-0024 §決定 3 (= 2-C accept rule) の意図的仕様変更であり、 regression ではない。

- `src/test-fixtures/step10/verify-step10-mismatch-silent.sh` 新規作成 (= 6 段階 gate)
- ROM patch approach 流用 (= step 9 δ で確立した directory entry 0 's' → 'S' 1 byte 改変、 source 不変)
- match path と mismatch path 双方を同一 fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) で trace 取得 + 比較
- driver source / asset / build pipeline は **完全不変** (= γ の核心要件)
- user 試聴用 wav file を `/tmp/pmdneo-step10/match.wav` / `mismatch.wav` に保存 (= 4 秒録音、 ADPCM-A drum audibility difference を聴感で確認可能)

## 実装差分

### 新規 verify script (= `src/test-fixtures/step10/verify-step10-mismatch-silent.sh`)

6 段階 gate 構成:

| gate | 内容 |
|---|---|
| 1 | match build + trace 取得 (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B、 既存 fixture) |
| 2 | match path 0xFD32 = 0x00 (= 6 件 idempotent、 step 9 verify 流用) |
| 3 | ROM patch (= directory entry 0 's' → 'S' at dynamic offset from .lst) |
| 4 | mismatch path 0xFD32 = 0xFF (= terminator sentinel、 6 件 idempotent) |
| 5 | ADPCM-A keyon trigger (= port B reg 0x00 bit set) 不発生 (= match 比で 39 件 skip) |
| 6 | ADPCM-A sample setup (= port B reg 0x10-0x2D) 完全消失 (= mismatch で 0 writes) |

### ymfm-trace 解析の reg field 形式 (= 重要 finding)

ymfm-trace の reg column は port B の場合 **"1XX" prefix** 形式で記録される:

- port A reg 0x27 → trace 値 "27"
- port B reg 0x00 (= ADPCM-A keyon control) → trace 値 **"100"**
- port B reg 0x10 (= ADPCM-A ch 1 sample start LSB) → trace 値 **"110"**
- port B reg 0x2D (= ADPCM-A ch 6 sample end MSB) → trace 値 **"12D"**

この形式は YM2610 chip 内部 address 表現で port + reg を 1 値で扱うため。 verify script の awk regex は "1XX" prefix を考慮:

```bash
# port B reg 0x00 (= keyon trigger): trace 値 "100"
awk -F'\t' '$2 == "B" && $3 == "100" {cnt++}'

# port B reg 0x10-0x2D (= sample setup): trace 値 "110"-"12D"
awk -F'\t' '$2 == "B" && $3 ~ /^(11[0-9A-D]|12[0-9A-D])$/ {cnt++}'
```

future verify script が ymfm-trace を扱う場合は本 finding を参照。

## 動作確認 (= γ 完了条件 6 件、 全 PASS)

### 条件 1: match build + trace 取得 ✅

`l-q-rhythm-song.mml + PMDDOTNET_MODE=B` で 4 秒 trace 取得、 wav 保存。 build PASS、 trace file 完備。

### 条件 2: match path 0xFD32 = 0x00 ✅

`pmdneo_resolve_sample_table_id` (= step 9) が match path で 0xFD32 = 0x00 を 6 件 idempotent に保存。 ADR-0023 §決定 11 contract の β 解除後でも match 挙動は変化なし。

### 条件 3: ROM patch 適用 ✅

`.lst` から `pne_sample_directory` addr を dynamic に取得 (= step 10 β で 0x1049 に shift 確認)、 entry 0 byte 0 を 's' (= 0x73) から 'S' (= 0x53) に 1 byte 改変。 source / driver / build pipeline は完全不変、 ROM artifact のみの patch。

### 条件 4: mismatch path 0xFD32 = 0xFF ✅

ROM patch 後、 `driver_pne_filename_buf` (= "step5.PNE") と directory entry 0 (= "Step5.PNE") が不一致 → resolver は terminator まで走査 → 0xFD32 = 0xFF を 6 件 idempotent に保存。

### 条件 5: ADPCM-A keyon trigger 不発生 ✅

port B reg 0x00 writes (= ADPCM-A keyon control register):

| 項目 | match | mismatch | 差分 |
|---|---|---|---|
| reg 0x00 writes total | 41 | 2 | **-39** |

match path で 39 件の keyon trigger (= ch 0-5 で sample 再生開始 bit set) が発生。 mismatch path では 2 件のみ (= NMI 初期化時の `xor a / out (0x08), a` 由来の初期 reset writes)、 keyon trigger は **完全 0** 件。

39 件は step 10 β の PC trace primary gate (= PC=0FB3 78 entries / 2 = 39 calls) と数値完全一致。 `pmdneo_select_sample_pointer` が呼ばれて DE = 0x0000 sentinel を返却、 `adpcma_keyon_simple` の `ret z` で keyon path が完全 skip された literal 証跡。

### 条件 6: ADPCM-A sample setup 完全消失 ✅

port B reg 0x10-0x2D writes (= ADPCM-A ch 0-5 sample start/end LSB/MSB、 24 register):

| 項目 | match | mismatch | 差分 |
|---|---|---|---|
| reg 0x10-0x2D writes total | 156 | **0** | -156 |

match path で 156 件 (= 39 keyon × 4 register/keyon = sample start LSB + start MSB + end LSB + end MSB) の sample setup writes 発生。 mismatch path では **完全 0 件** = adpcma_keyon_simple の `ret z` で register write group が走らない literal 証跡。

156 件 (= keyon ごと 4 writes) と 39 件 (= keyon trigger 件数) の関係 (= 4 × 39 = 156) も整合。

## mismatch silent の audio impact (= user 試聴可能)

`/tmp/pmdneo-step10/match.wav` (= match path、 4 秒録音):
- ADPCM-A drum: 鳴る (= 39 keyon triggered、 sample played)
- FM channels: 鳴る (= 独立)

`/tmp/pmdneo-step10/mismatch.wav` (= mismatch path、 4 秒録音):
- ADPCM-A drum: **silent** (= 0 keyon triggers、 sample setup 完全 skip)
- FM channels: 鳴る (= 不変、 0xFD32 と独立)

両 wav を聴感比較することで mismatch silent の意図的仕様変更を user が直接確認可能。

## γ scope の重要境界 (= future contributor 向け)

**Step 10 γ は β で実装した mismatch silent 動作の動的検証 commit**。 driver source / asset / build pipeline は **完全不変**、 verify infra (= 新規 script + handoff doc) のみ追加。

mismatch silent は **ADR-0024 §決定 3 (= 2-C accept rule) で確定した意図的仕様変更** であり、 ADR-0023 §決定 8 (= step 9 では mismatch でも playback path 不変) からの挙動変更は β commit (= 9f454f5) で導入済。 γ commit は β commit の挙動を literal 証跡として固定するだけで、 新たな仕様変更を導入しない。

γ 完了条件で確認したのは:

- match path と mismatch path が同一 fixture でも別 audio output になること (= condition 5/6)
- mismatch silent は ADPCM-A の chip register writes レベルで完全 skip されていること (= condition 6 で 0 writes literal)
- 0xFD32 state の match/mismatch 切替が ROM 1 byte patch だけで再現可能 (= condition 3-4、 source 不変流儀踏襲)

「mismatch silent = audio が一切出ない」 ではなく、 **「ADPCM-A drum 音が silent、 FM は独立に再生継続」** が正確な挙動境界。 future contributor が「mismatch = 完全 mute」 と誤解しないよう明示。

## scope-out 維持確認

γ では以下を一切実装しない:

- driver source 改修 (= adpcma_keyon_simple / pmdneo_select_sample_pointer / pmdneo_resolve_sample_table_id 等は完全不変)
- FM channel silent 化 (= γ は ADPCM-A のみ、 FM は独立)
- mismatch silent flag 追加 (= 別 runtime state、 step 11+ scope)
- mismatch fallback (= 別 table 使用、 ADR-0024 §決定 3 で不採用確定)
- silent-bcef 等 audible regression 試聴 (= δ scope、 user 試聴待ち)
- ADR-0024 Accepted 移行 (= δ scope)
- step 5/6/7/8/9 既存 verify script regression serial 実行 (= δ scope)
- memory `project_pmdneo_step10_complete.md` 起票 (= δ scope)

## 既存 path 不変確認

- `assets/samples.inc`: 不変
- VROM: 不変
- driver `standalone_test.s` / `PMDNEO.s` / 等: **完全不変** (= γ 改修ゼロ)
- step 9 α `pne_sample_directory`: 不変
- step 9 β `pmdneo_resolve_sample_table_id`: 不変
- step 10 α `pmdneo_select_sample_pointer`: 不変
- step 10 β `adpcma_keyon_simple` call insertion: 不変
- `.PNE` converter / vromtool.py / build pipeline: 不変
- step 9 verify-step9-resolver.sh (= β で dynamic offset 化済): 不変

## 次 step (= δ scope)

- step 5/6/7/8/9 既存 verify script regression 全件 serial 実行 (= 26 gate 全 PASS 確認)
- silent-bcef fixture で audible regression 試聴 (= user 試聴 OK 確認)
- `/tmp/pmdneo-step10/match.wav` / `mismatch.wav` で mismatch silent 確認 (= user 試聴 OK)
- ADR-0024 Annex 追記 (= commit hash + verify result + Accepted 移行根拠)
- ADR-0024 Status: Draft → Accepted
- memory `project_pmdneo_step10_complete.md` 起票
- memory `MEMORY.md` index 更新
- δ 完了統合 handoff doc 作成

## 関連

- [ADR-0024](../../adr/0024-pmdneo-step10-sample-table-id-selection-consumption.md) §決定 3 (= 2-C mismatch silent) / §決定 8 γ
- [ADR-0024 step 10 β handoff](adr-0024-step10-beta-keyon-call-insertion.md) (= β で実装した mismatch silent path を本 commit で動的検証)
- [ADR-0024 step 10 α handoff](adr-0024-step10-alpha-routine-implementation.md) (= α で routine を作り、 β で接続、 γ で挙動 verify、 と sub-sprint chain 完成)
- [ADR-0023 step 9 γ handoff](adr-0023-step9-gamma-chain-insertion.md) (= ROM patch approach の先例)
- [step 9 verify-step9-resolver.sh](../../../src/test-fixtures/step9/verify-step9-resolver.sh) (= 同手法 ROM patch、 β で dynamic offset 化済、 本 script はこれを step 10 chip-register verify に拡張)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 γ は ADPCM-A chip register writes 不発生で literal 証跡)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除、 γ では FM 不変・ADPCM-A silent で audio gate を構成)
