# ADR-0016 step 7 δ finding handoff: mc compiler `/B` path `pne_filename_adr` embed verify

- 起票日: 2026-05-13 (= 8th session δ)
- 起票者: Claude Code
- 関連: ADR-0021 §決定 3 (= mc compiler `/B` path は verify only、 fail 時は fix micro-sprint)、 §決定 8 sub-sprint 構造
- 関連 commit: α-1 `38e35bf` / α-2 `e30ef4c` / β-1 `a25155d` / β-2 `0668594` / β-3 `e3fdda5` / **δ-fix `d653d62`** / δ 本 commit
- 関連設計書: `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)、 `docs/design/pne_binary_layout.md` v0.2

## 概要

**δ は verify-only commit**。 改造 PMDDotNET `/B` mode で出力される `.MN` binary について、 `mn_binary_layout.md` §4-3-3 で定義した:

- `m_start` bit 2 = 1 (= PMDNEO mode flag)
- `m_buf[26..27]` = `extended_data_adr` (= 後方拡張領域先頭)
- `extended_data_adr +12..13` = `pne_filename_adr` (= filename string offset)
- `pne_filename_adr` 位置に NUL-terminated ASCII filename string

の 4 軸が正しく embed されていることを hex dump レベルで verify。 driver / build pipeline / `.PNE` converter は touch なし。

## δ-fix との関係 (= 前提 commit)

δ verify 着手時に finding 検出: mc compiler `/B` path が `#PNEFile "step5.PNE"` の surrounding quotes (= `"`) を strip せず、 `.MN` に `"step5.PNE"\0` (= 11 byte + NUL) を embed していた。

ADR-0021 §決定 3 末尾「verify で fail が出た場合のみ fix する micro-sprint を起こす」 path を適用し、 **δ-fix micro-sprint (= commit `d653d62`) で mc compiler 局所修正**:

- `mc.cs:2638-2647` 周辺 (= `pcm_path_set()`、 `#PNEFile` parser) に surrounding quote strip ブロック追加 (= +13 行)
- `#PNEFile "step5.PNE"` → `step5.PNE` (= 9 byte) に normalize
- `#PNEFile step5.PNE` (= quote なし) も壊さない (= idempotent)
- 片側のみ quote (= 異常入力) は副作用回避のため strip しない

本 δ commit は δ-fix 後の状態で **既存 verify script が 4/4 PASS する** ことを確認 + handoff doc + finding memory を残す sprint。 δ verify script 自体は δ-fix の前に作成 (= 直前 turn) されており、 δ-fix で前提が整って初めて PASS する設計。

## 検証戦略

### 経路

```
src/test-fixtures/step5/l-q-rhythm-song.mml (= #PNEFile "step5.PNE" 宣言済)
  ↓ PMDDOTNET_MML + PMDDOTNET_MODE=B (= 改造 PMDDotNET /B mode)
  ↓ build-poc.sh
vendor/ngdevkit-examples/00-template/pmddotnet_song.m (= .MN binary、 395 byte)
  ↓ python3 で hex parse + 4 gate verify
```

### 4 gate verify (= δ-fix 後の 4/4 PASS)

```
$ bash src/test-fixtures/step7/verify-step7-delta-mn-filename-embed.sh

=== step 7 δ: mc compiler /B path pne_filename_adr embed verify ===

--- step 1: 改造 PMDDotNET /B mode で .MN 生成 (= l-q-rhythm-song.mml) ---
  [PASS] .MN generated: pmddotnet_song.m (395 byte)
--- step 2: .MN binary を hex parse + 4 gate verify ---
  [PASS] gate 1: m_start = 0x04 (= PMDNEO mode flag = bit 2 set)
  [PASS] gate 2: extended_data_adr = 0x0027 (39) (= valid range)
  [PASS] gate 3: pne_filename_adr = 0x00a4 (164) (= valid range)
  [PASS] gate 4: filename = 'step5.PNE' (= expected 'step5.PNE'、 NUL-terminated)

  reference hex dump (= filename string 周辺、 file offset 165):
    offset 161: 05 30 60 80 73 74 65 70 35 2e 50 4e 45 00 00 00 00 00 00 00 00
             ascii: .0`.step5.PNE........

=== step 7 δ verify PASS (= 4/4 gate PASS) ===
```

### 各 gate の意味

| gate | 検証内容 | mn_binary_layout.md 該当節 |
|---|---|---|
| 1 | `m_start = 0x04` (= PMDNEO mode flag = bit 2 set) | §4-1 |
| 2 | `m_buf[26..27] = extended_data_adr` が file size 範囲内 | §4-2 |
| 3 | `extended_data_adr +12..13 = pne_filename_adr` が valid range | §4-3 |
| 4 | `pne_filename_adr` 位置に NUL-terminated ASCII filename string `"step5.PNE"` | §4-3-3 |

## 重要 finding (= δ-fix 起因、 別 memory 保存対象)

δ verify 着手時に検出された「mc compiler `/B` path の `#PNEFile` quote handling」 finding は δ-fix で解消済。 ただし以下の境界整理は残る:

### mc compiler の `#` directive quote handling 整理状況

- **`#PNEFile`**: 8th session δ-fix で surrounding quote strip 確立 (= commit `d653d62`)
- **その他 directive (= `#Title` / `#Composer` / `#Memo` 等)**: 未確認 (= 本 δ-fix では touch なし、 別 sprint 候補)

これは δ-fix commit message + source コメント + 本 handoff doc + memory `project_pmd_directive_quote_handling_status.md` の 4 箇所に明示。 future contributor が「quote parser 全体が直された」 と誤解しないよう scope を明確化。

### `mn_binary_layout.md` §4-3-3 の prose 表記について

`mn_binary_layout.md` §4-3-3 の例 `"NEOSI001.PNE\0"` は prose の引用符表記 (= literal embed の意味ではない、 通常の string 引用慣習) として理解される。 δ-fix で確立した「quote 文字は filename 本体に含めない」 流儀と整合。 設計書本文の修正は不要 (= 解釈の明確化は本 handoff doc で十分)。

### `pne_filename_adr` の現状利用範囲 (= scope 境界明示)

**重要 (= future contributor 向け)**: 本 δ commit で verify した `pne_filename_adr` + filename string embed は **format contract の先行固定** であり、 **現 Step 7 では driver runtime resolution には まだ使われない**。

| 利用主体 | 現状 (= Step 7 完了時点) | 将来 (= Step 8 候補以降) |
|---|---|---|
| mc compiler `/B` path | filename を `.MN` に embed する | (= 不変、 本 δ で確立) |
| driver (= `standalone_test.s`) | **filename を読まない** (= 完全不変) | runtime parser sprint で読込 routine 追加 (= ADR-0021 §決定 2 scope-out) |
| ROM builder / asset resolver | **filename を読まない** (= 現状は path B / c1 経由で build-time 解決) | dynamic sample bank / 複数 `.PNE` 対応で利用 (= 別 sprint) |

つまり本 δ で実証したのは「`.MN` binary に filename が **正しい形式で書き込まれている**」 ことのみ。 「driver / runtime が filename を **使って sample を解決している**」 ことは Step 7 では検証していない (= driver / runtime は filename string を一切参照しない)。 これは ADR-0021 §決定 2「runtime parser / driver 側 filename read は scope-out」 と完全整合。

future contributor が「driver が `.PNE` filename を解決済み」 「runtime parser が動いている」 等の誤解をしないよう、 本 §で scope 境界を明示。

## ADR-0021 §決定 3 / §決定 7 整合性

| 規律 | δ commit での確認 |
|---|---|
| §決定 3 「mc compiler `/B` path は verify only」 | ✅ 本 commit は verify-only (= source / build pipeline touch なし)、 mc compiler 改修は δ-fix で別 commit 化済 |
| §決定 3 末尾「fail 時は fix micro-sprint」 | ✅ δ verify finding を δ-fix micro-sprint で処理した実例 |
| §決定 7 primary gate / audio gate 役割分離 | ✅ δ verify は trace / binary parse 軸のみ、 audio gate は β-3 で確認済 + step 6 経路で再現可能 |

## step 7 全体進捗 (= δ 完了で残り ε のみ)

| sub-sprint | commit | 状態 | 主要成果 |
|---|---|---|---|
| α-1 | `38e35bf` | ✅ | `.PNE` binary layout 起票 + provenance 調査 |
| α-2 | `e30ef4c` | ✅ | path B / c1 正式採用 + converter I/O contract + ADR-0021 §決定 5 補正 |
| β-1 | `a25155d` | ✅ | converter prototype + `.PNE` 初期 asset + round-trip 4 gate |
| β-2 | `0668594` | ✅ | build pipeline 接続 (= Makefile 3 行 + build-poc.sh + ADPCM-B yaml 分離) |
| β-3 | `e3fdda5` | ✅ | byte-identical + regression verify、 path B / c1 数学的同値性証明 |
| γ | (skip) | — | path B 採用で不要 (= ADR-0021 §決定 5 補正で撤回) |
| **δ-fix** | `d653d62` | ✅ | mc compiler `#PNEFile` quote strip 局所修正 (= ADR-0021 §決定 3 末尾 path 適用) |
| **δ** | 本 commit | ✅ | mc compiler `/B` path `pne_filename_adr` embed 4 gate verify、 .MN ↔ .PNE format contract 接続確認 |
| ε | 次 sprint | 未着手 | step 7 完了統合 + ADR-0021 Proposed → Accepted 移行 + 関連 memory 総括 |

## δ 改修対象

| 件 | file | 種別 | 行数 |
|---|---|---|---|
| 1 | `src/test-fixtures/step7/verify-step7-delta-mn-filename-embed.sh` | 新規 (= 4 gate verify) | 138 |
| 2 | 本 handoff doc | 新規 | (本 file) |
| 3 | memory `project_pmd_directive_quote_handling_status.md` 起票 + MEMORY.md index 追記 | 新規 | (memory dir) |

**触らなかったもの**: driver / mc compiler (= δ-fix で別 commit 済) / build pipeline / `.PNE` converter / vromtool.py / 既存 yaml / 既存 sample asset。 完全に verify-only commit。

## ε 着手前の整理

ε で扱う未対応事項:
- step 7 完了統合 handoff doc (= α-1/2 + β-1/2/3 + δ-fix + δ + γ skip の総括)
- ADR-0021 Proposed → Accepted 移行
- 関連 memory 総括 (= `project_pmdneo_step7_complete.md` 起票候補)
- 8th session 全体総括 (= 8 commit 連続 + Step 5/6/7 役割分離の言語化)

## 関連 file

- ADR-0021 (= step 7 sprint 起票 + §決定 5 path B / c1 + §決定 3 mc compiler verify only)
- `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)
- `docs/design/pne_binary_layout.md` v0.2 (= path B / c1 + converter I/O contract)
- `docs/design/handoff/adr-0016-step7-b-1-converter-prototype.md` (= β-1 finding)
- `docs/design/handoff/adr-0016-step7-b-3-byte-identical.md` (= β-3 finding、 primary gate 数学的同値性)
- `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:2638-2660` (= δ-fix で改修した `#PNEFile` parser)
- memory `project_pmd_directive_quote_handling_status.md` (= δ commit 起票、 `#` directive quote handling 整理状況)
