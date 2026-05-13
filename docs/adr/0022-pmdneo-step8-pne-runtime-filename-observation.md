# ADR-0022: PMDNEO step 8 runtime `.PNE` filename observation sprint (= sub-A 採用、 resolver / multi-`.PNE` は scope-out)

- 状態: **Accepted** (= 2026-05-13 9th session、 step 8 γ 完了統合で Accepted 移行)
- 起票日: 2026-05-13
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 8 = runtime `.PNE` 関連)、 ADR-0019 (= step 5 §決定 3 で `.PNE` parser を「次 sprint へ分離」 と接続点予約)、 ADR-0020 (= step 6 完了 + 次 sprint 候補に `.PNE` parser を明示)、 ADR-0021 (= step 7 完了で `.MN` filename embed 経路成立、 §Accepted 後の重要境界で「runtime resolution は Step 8 以降」 と明記)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)

## 背景

step 7 完了 (= 2026-05-13 8th session、 commit `78afc94`) で `.PNE` asset pipeline と `.MN` filename embed 経路が成立した。 driver / vromtool.py 完全不変 + ROM final byte-identical 数学的同値が証明され、 `.PNE` は **build-time source-of-truth** として確立した。

ただし ADR-0021 §Accepted 後の重要境界に明記された通り、 step 7 時点では:

- driver / runtime は `.PNE` を直接読まない
- `pne_filename_adr` は format 先行固定のみ、 driver 不参照
- 楽曲交換時は ROM rebuild が必要

の状態にある。 これらは **future runtime parser のための format contract 先行固定** として意図的に scope-out された。

ADR-0019 §決定 3 / ADR-0020 §次 sprint 候補 / ADR-0021 §次 sprint 候補で「runtime `.PNE` parser sprint」 が筆頭候補として予約され続けており、 step 8 はこの予約消化に該当する。

ただし「runtime `.PNE` parser sprint」 と素朴に定義すると scope が肥大化する (= filename read + bank resolve + .PNE binary parse + multi-.PNE switching + sample table rebuild を同時に触る)。 9th session 冒頭の壁打ちで以下の方針整理が確定:

- **driver で「filename を読む」 ことのみに範囲を絞る** (= step 5/6/7 で確立した「動いているものを壊さない」 規律遵守)
- **filename resolve / sample table 再構築 / .PNE binary parse は scope-out** (= 後続 sprint で扱う)
- **observation 専門 sprint として定義し、 audible output には一切影響しない**

これに基づき step 8 を **「runtime `.PNE` parser sprint」 ではなく「runtime `.PNE` filename observation sprint」** として再定義する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 8 着手前に方針を ADR として独立起票する。

### 9th session 冒頭壁打ちでの方針確定

ADR-0022 起票前に user が提示した動機:

- **動機 2**: `.MN` ↔ `.PNE` 連携を runtime trace で観察可能にする (= verification 強化)
- **動機 4**: `.PNE` 形式の規約検証を runtime まで延ばす (= build-time だけでなく driver 側に format contract を届ける)

scope 候補 3 件 (= sub-A / sub-B / sub-C) のうち **sub-A (= filename read only)** が採用された。 理由:

- 現時点で sample resolution は build-time path B で成立済 (= ADR-0021 §決定 5)
- いきなり runtime resolve に入ると、 動作上不要な複雑性を追加する
- まず "driver が filename contract を読める" ことを trace で証明するのが自然
- Step 7 の `.MN` filename embed を runtime 側へ 1 段だけ延ばす sprint として安全
- "動いているものを壊さない" 規律と整合する

## 決定

### 決定 1: step 8 を「runtime `.PNE` filename observation sprint」 として定義 (= sub-A 採用)

step 8 の最終 deliverable boundary を **sub-A (= filename read only)** とする。 driver が `.MN` 内 `pne_filename_adr` を読み、 filename string を runtime buffer に load し、 trace で観察可能にすることを目的とする。 audible output は一切変えない。

#### 補足: step 8 = filename contract の runtime 延伸、 playback semantics は不変

step 8 は **`.MN` 内 filename embed を driver 側から「読み取り可能」 にする sprint** であり、 ADPCM-A lookup / register write / keyon / keyoff / volume / pan / timing 等の **sample playback semantics 自体は変更しない**。 これらは step 5 で完了済 (= ADR-0019)、 step 7 で外部化済 (= ADR-0021)。

future contributor が「runtime resolver 実装済」 と誤解しないよう明示。 register trace 軸で完全同一 (= byte-identical) になることが本質的根拠 (= 決定 6 primary gate + 決定 8 既存 path 不変)。

### 決定 2: filename resolver / `.PNE` binary runtime parse / multi-`.PNE` は scope-out

step 8 では以下を **すべて scope-out**、 後続 sprint へ分離:

- filename string → ROM sample table resolve
- `.PNE` binary 自体の runtime parse (= header / sample entry / addr table 読込)
- multi-`.PNE` switching (= 楽曲ごと別 `.PNE` 切替)
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- sample table 再構築 routine
- asset reload (= 動的 `.PNE` 差替)
- mc compiler / vromtool.py / converter / `samples.inc` 改修

これらは「runtime parser sprint」 を別途立て、 driver 改修専念で進める。

### 決定 3: filename format 規約 = NUL-terminated ASCII (= `.MN` embed と同一)

driver が runtime buffer に load する filename string format:

- **NUL-terminated ASCII** (= `.MN` embed と完全同一、 DOS 8.3 想定)
- 例: `"step5.PNE\0"` (= 9 char + NUL = 10 byte)、 `"PMDNEO01.PNE\0"` (= 12 char + NUL = 13 byte)
- len-prefix 等の新規 format は導入しない (= format 揺らぎを避ける)

### 決定 4: PNE runtime observation block の SRAM 配置 (= 0xFD20-0xFD31, 18 byte)

driver の Z80 SRAM 内に **PNE runtime observation block** を新規確保:

| address | symbol | size | 内容 |
|---|---|---|---|
| 0xFD20-0xFD2F | `driver_pne_filename_buf` | 16 byte | NUL-terminated ASCII filename |
| 0xFD30-0xFD31 | `driver_pne_filename_adr_word` | 2 byte | `pne_filename_adr` (LE u16、 m_buf-relative) |

合計 18 byte (= 0xFD20-0xFD31)。

#### 配置根拠

- 0xFD20 は **free 領域先頭** (= `standalone_test.s:117-126` SRAM layout、 0xFD20-0xFFBF が 672 byte 余裕)
- 既存 `part_workarea` (= 0xF820-0xFD1F) と直接 1 byte の干渉なし
- 0xF800-0xF80F は **future cmd FIFO reserved** のため使わない
- `driver_state` (= 0xF810-0xF81F) は既存 runtime state 用として温存
- PNE observation 関連 state を free region にまとめることで、 future resolver 化で 0xFD20 起点に block 拡張しやすい

#### buffer size 根拠

- 現状 `.MN` embed: `step5.PNE` = 10 byte
- 現状 `.PNE` 自身: `PMDNEO01.PNE` = 13 byte
- DOS 8.3 max: 12 char + NUL = 13 byte
- → **16 byte で十分** (= margin 3 byte)、 32 byte は observation sprint には過剰

### 決定 5: overflow 規約

`pne_filename_adr` が指す string が 16 byte 以上の場合の動作:

- **15 byte copy + byte15 = 0x00** (= 末尾 NUL 強制で必ず NUL-terminated 状態を保つ)
- **halt せず trace warning に記録** (= driver は正常動作継続)
- handoff doc / finding に overflow 発生を明示

#### 根拠

- observation sprint のため、 overflow を runtime fault として扱わない
- driver halt は audible 出力を止めるため、 既存 step 5/6/7 path を壊さない原則と整合しない
- format 違反の検出と通知に留め、 修正は build-time 側 (= `.PNE` filename 命名規約遵守) で行う

### 決定 6: trace gate primary + byte-identical regression secondary (= step 5/6/7 規律踏襲)

step 5 (= ADR-0019) / step 6 (= ADR-0020) / step 7 (= ADR-0021) で確立した検証規律を継続:

- **primary gate**: trace gate (= driver 内 filename buf / word の中身が `.MN` binary と一致)
- **secondary gate**: byte-identical regression (= step 5/6/7 の既存 verify script が全 PASS)

audio gate は step 8 では必須としない (= audible 出力に影響しないため)。 ただし γ で MAME 試聴を 1 回行い、 regression がないことを最終確認する。

### 決定 7: sub-sprint 分割案 (= α/β/γ 3 段)

step 8 を **α / β / γ の 3 sub-sprint 構造** で進める。

| sub | 範囲 | trace gate |
|---|---|---|
| α | driver の `.MN` parser に `pne_filename_adr` field 読込経路追加 + `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) 保存 | trace で `pne_filename_adr` 値が `.MN` binary と一致 |
| β | `pne_filename_adr` を pointer follow + filename string を `driver_pne_filename_buf` (= 0xFD20-0xFD2F) に copy + overflow 規約適用 | trace で runtime buffer の中身が `.MN` filename string と byte-identical |
| γ | trace gate script 整備 + step 5/6/7 regression 再確認 + handoff doc + ADR-0022 Accepted 移行 | step 5/6/7 verify script 全 PASS + filename trace PASS |

**1 sub = 1 commit + 1 push 規律** (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) を維持。

### 決定 8: 既存 sample playback path は完全不変

step 8 では以下を **すべて完全不変** とする:

- `assets/samples.inc` (= 生成 sample include)
- VROM (= ngdevkit-examples 経由 ROM build pipeline)
- driver の sample lookup routine (= `adpcma_ch_sample_ptr_table` voice index 引き)
- ADPCM-A register writes (= keyon / keyoff / volume / pan / freq)
- L-Q part 6ch 経路 (= step 5 完成)
- `.PNE` converter (= `scripts/pne-to-ngdevkit.py`)
- build pipeline (= `vendor/Makefile` / `scripts/build-poc.sh`)

step 8 は **runtime filename を読むだけで、 音の出方は一切変えない**。 future contributor が「runtime resolver 実装済」 と誤解しないよう、 この決定で literal に固定する。

### 決定 9: handoff doc 構造

step 8 の handoff doc は sub-sprint ごと独立、 完了統合は別 doc。

| 段階 | 文書 | 内容 |
|---|---|---|
| α | `docs/design/handoff/adr-0022-step8-alpha-mn-filename-adr-read.md` | `pne_filename_adr` field 読込実装 + trace 結果 |
| β | `docs/design/handoff/adr-0022-step8-beta-filename-string-copy.md` | filename string copy 実装 + overflow 規約適用 + trace 結果 |
| γ | `docs/design/handoff/adr-0022-step8-completion.md` | step 8 統合 sum-up + ADR-0022 Accepted 移行 |

## scope-in / scope-out 明示

### scope-in (= step 8 本 sprint 範囲)

- driver `.MN` parser に `pne_filename_adr` field (= extended_data_adr +12..13) 読込経路追加 (= α)
- `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) への word 保存 (= α)
- `pne_filename_adr` を pointer follow + filename string copy routine (= β)
- `driver_pne_filename_buf` (= 0xFD20-0xFD2F) への string copy (= β)
- overflow 規約 (= 15 byte copy + byte15 = 0x00 + trace warning) 適用 (= β)
- filename runtime observation 用 trace script 整備 (= γ)
- step 5/6/7 既存 verify script 全件 regression 再確認 (= γ)
- MAME 試聴で audible regression なし最終確認 (= γ)
- step 8 完了統合 handoff doc + ADR-0022 Accepted 移行 (= γ)

### scope-out (= step 8 範囲外、 後続 sprint で扱う)

- filename string → ROM sample table resolve
- `.PNE` binary runtime parse (= header / sample entry / addr table)
- multi-`.PNE` switching
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- PMDNEO.s + nullsound integration (= 大規模 sprint)
- 新規 sample 追加 (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- sample table 再構築 / asset reload
- mc compiler / vromtool.py / converter / `samples.inc` 改修
- PPZ compatibility mode
- FM-Towns-style rhythm mode

## 完了判定

### step 8 全体完了判定 (= ADR-0022 Accepted 移行条件)

1. **α**: driver `.MN` parser に `pne_filename_adr` field 読込経路追加 + commit + push
2. **α**: `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) に `pne_filename_adr` 値が保存されることを trace で確認
3. **β**: `pne_filename_adr` follow + filename string copy 実装 + commit + push
4. **β**: `driver_pne_filename_buf` (= 0xFD20-0xFD2F) の中身が `.MN` filename string と byte-identical
5. **β**: overflow 規約 (= 15 byte copy + byte15 = 0x00 + trace warning) が 16+ byte filename で正しく動作
6. **γ**: filename runtime observation 用 trace script 整備 + commit + push
7. **γ**: step 5/6/7 既存 verify script 全件 PASS (= 既存 architecture regression なし)
8. **γ**: MAME 試聴で audible regression なし (= step 6 silent-bcef fixture で確認)
9. **γ**: step 8 完了統合 handoff doc + ADR-0022 Accepted 移行 + commit + push

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## 関連 memory

- `project_pmdneo_step7_complete.md` (= step 7 完了状態、 `.MN` filename embed 経路成立)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 8 は source 軸の延伸)
- `project_pmdneo_step6_complete.md` (= step 6 完了状態、 audio isolation 戦略)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ADPCM-A 6ch native path)
- `project_pmdneo_mn_header_byte_count.md` (= `.MN` header 28 byte 固定、 driver は m_start bit 2 = 1 で固定解釈可)
- `project_pmd_directive_quote_handling_status.md` (= `#PNEFile` quote handling 状況)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除)

## 完了判定達成状況 (= 2026-05-13 9th session、 step 8 γ 完了統合)

### 全体完了判定 9 項目

| # | 項目 | 達成 | 関連 commit |
|---|---|---|---|
| 1 | α: driver `.MN` parser に `pne_filename_adr` field 読込経路追加 + commit + push | ✅ | `a6c6695` |
| 2 | α: `driver_pne_filename_adr_word` (= 0xFD30-0xFD31) に保存される trace 確認 | ✅ (= 0x00A4 一致) | `a6c6695` |
| 3 | β: `pne_filename_adr` follow + filename string copy 実装 + commit + push | ✅ | `6cf30dd` |
| 4 | β: `driver_pne_filename_buf` の中身が `.MN` filename string と byte-identical | ✅ (= `"step5.PNE\0"` 一致) | `6cf30dd` |
| 5 | β: overflow 規約が 16+ byte filename で正しく動作 | ⏸ **β-A 正規 scope-out** (= code path 実装済、 fixture verify は future) | `6cf30dd` |
| 6 | γ: filename runtime observation 用 trace script 整備 | ✅ (= `verify-step8-filename-observation.sh` 5 gate) | 本 commit |
| 7 | γ: step 5/6/7 既存 verify script 全件 PASS | ✅ (= 21 gate 全 PASS) | 本 commit |
| 8 | γ: MAME 試聴で audible regression なし | ✅ (= user 試聴 OK + step 6-a PASS) | 本 commit |
| 9 | γ: step 8 完了統合 handoff doc + ADR-0022 Accepted 移行 + commit + push | ✅ | 本 commit |

→ **9/9 達成** (= #5 は β-A 採用で正規 scope-out、 残り 8 項目すべて PASS)

### sub-sprint commit chain (= step 8 全 4 commit)

| sub | commit | 内容 |
|---|---|---|
| 起票 | `57b4bad` | docs(adr): step 8 着手前に ADR-0022 起票 (= sub-A 採用) |
| α | `a6c6695` | feat(driver): step 8 α — driver_pne_filename_adr_word read (= word observation) |
| β | `6cf30dd` | feat(driver): step 8 β — filename string copy to driver_pne_filename_buf (= β-A 採用) |
| γ | 本 commit | docs(adr): step 8 γ 完了統合 + ADR-0022 Accepted + verify-step8-filename-observation.sh |

### Accepted 移行根拠

- 完了判定 9 項目中 8 項目 PASS + 1 項目 (= #5) 正規 scope-out (= β-A 採用)
- ADR-0022 §scope-out 全 12 項目 維持確認済 (= 完了統合 handoff doc 参照)
- step 5/6/7 verify 改修不要で 21 gate 全 PASS (= 既存 architecture 整合性確認)
- α/β の driver 改修は `pmdneo_mn_direct_load_lq_part_addr` 内 +37 line に限局、 既存 logic literal 不変
- `samples.inc` / VROM 4 件 byte-identical 維持 (= step 7 β-3 PASS、 build pipeline 完全不変)
- audible regression なし (= user 試聴 OK + step 6-a 7 gate PASS)

→ ADR-0022 = **Accepted**

### Accepted 後の重要境界 (= future contributor 向け明示)

**Step 8 は `.PNE` runtime resolver / parser を実装していない**。 現時点で driver は:

- `.MN` 内 filename string を runtime state として **観測可能** にしているが、 **解決には使っていない**
- sample addr は依然 build-time に `samples.inc` 経由で固定埋込 (= ADR-0019 §決定 3 維持)
- 楽曲交換時は依然 ROM rebuild が必要 (= multi-`.PNE` runtime 切替は未実装)

`driver_pne_filename_buf` / `driver_pne_filename_adr_word` が現状 **read 用 observation state** に留まっていることを future contributor が誤解しないよう明示。 これは ADR-0022 §決定 8 (= 既存 sample playback path は完全不変) の literal 整合。

完了統合 handoff doc §Accepted 後の重要境界 + §Step 5/6/7/8 全体での役割位置づけ も参照。

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= `.PNE` parser 次 sprint 接続点予約)
- ADR-0020 §次 sprint 候補 (= `.PNE` parser を筆頭に挙示)
- ADR-0021 §Accepted 後の重要境界 (= runtime resolution は Step 8 以降)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/design/mn_binary_layout.md` §4-3-3 / §7-2 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/pne_binary_layout.md` (= `.PNE` format 仕様、 step 7 α-1 起票)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止

## 次 sprint 候補

1. **α 着手** (= driver `.MN` parser に `pne_filename_adr` field 読込追加 + `driver_pne_filename_adr_word` 保存 + trace)
2. β 着手 (= `pne_filename_adr` follow + filename string copy + overflow 規約)
3. γ 着手 (= trace gate script + 既存 verify script regression + MAME 試聴 + 完了統合 + Accepted 移行)
4. **step 9 候補** (= 本 ADR scope-out のうち未消化): runtime `.PNE` parser driver 実装 (= filename → sample table resolve、 sub-B/sub-C 相当) / K-R rhythm compat micro-sprint / multi-`.PNE` switching / `.PNE` binary runtime parse / nullsound integration 再検討
