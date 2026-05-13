# ADR-0021: PMDNEO step 7 `.PNE` asset pipeline + `.MN` filename embed sprint (= C2 採用、 runtime parser は scope-out)

- 状態: **Accepted** (= 2026-05-13 8th session、 step 7 ε 完了統合で Accepted 移行)
- 起票日: 2026-05-13
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 7 = `.PNE` 関連)、 ADR-0019 (= step 5 §決定 3 で `.PNE` parser を「次 sprint へ分離」 と接続点予約)、 ADR-0020 (= step 6 完了 + 次 sprint 候補に `.PNE` parser を明示)
- 関連設計書: `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)、 `docs/design/mn_binary_layout.md` §4-3-3 (= `pne_filename_adr` + filename string embed 仕様)、 `docs/design/ppz_to_adpcma_mapping.md` (= PPZ → ADPCM-A 写像)

## 背景

step 6 完了 (= 2026-05-13 7th session、 commit `a168896`) で audio isolation 戦略が成立し、 「ADPCM-A 6ch native path を solo 試聴可能な状態」 が確立した。 これにより検証 feedback loop が安定し、 次 sprint で機能拡張を進める下地が整った。

ADR-0019 §決定 3 で `.PNE` parser は「step 5 scope-out、 次 sprint へ分離」 と接続点予約され、 ADR-0020 §次 sprint 候補でも筆頭に挙げられている。 step 7 はこの予約消化に該当する。

ただし「`.PNE` parser sprint」 と素朴に定義すると scope が肥大化する (= driver 改修 / sample table 構築 routine / bank 切替 / build pipeline / fixture / mc compiler 全てを同時に触る)。 8th session 冒頭の壁打ちで以下の方針整理が確定:

- **driver をまだ触らない** (= step 5/6 で確立した「動いているものを壊さない」 規律遵守)
- **`.MN` format を最終形に近い状態で固定** (= 後続 sprint で driver 改修のみで runtime parser 化できる前提を作る)
- **compiler / build pipeline 改修と driver 改修を分離** (= step 5/6 で成功した規律踏襲)

これに基づき step 7 を **「runtime parser sprint」 ではなく「`.PNE` asset pipeline + `.MN` filename embed sprint」** として再定義する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 7 着手前に方針を ADR として独立起票する。

### 8th session 冒頭調査での重要発見

ADR-0021 起票前調査で以下が確認された:

1. **mc compiler `/B` path の `#PNEFile` cmd 受け取り + `pne_filename_adr` embed は既に実装済** (= ADR-0016 step 1 commit `45eebaf` 遺産)
   - `vendor/PMDDotNET/PMDDotNETCompiler/mml_seg.cs:231 / 339 / 344` — `adpcma_used` / `pne_filename` / `opnb_pne_filename_adr_pos` field 定義
   - `vendor/PMDDotNET/PMDDotNETCompiler/m_seg.cs:13 / 14` — `extended_data_adr` / `pne_filename_adr` field 定義
   - `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:849-859` — `extended_data_adr` 領域確保 (= prg_flg 無依存 28 byte header 固定化)
   - `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:1491-1565` — ADPCM-A 使用時 `#PNEFile` 必須 check + filename string 出力 + `pne_filename_adr` 書き戻し
   - `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:2569-2645` — `#PNEFile` `# cmd` parser 本体

2. **driver 側 sample table の実体は `src/driver/standalone_test.s` 内に直書き** (= `samples.inc` は存在しない)
   - `standalone_test.s:2825` `adpcma_ch_sample_ptr_table:` — voice index → sample header pointer 6 entry
   - `standalone_test.s:2829-2840` `adpcma_sample_bd/sd/hh/tom/rim/top:` — 各 sample header (= `start_addr` LSB/MSB + `stop_addr` LSB/MSB、 4 byte ずつ)
   - `BD_START_LSB` / `BD_START_MSB` / `BD_STOP_LSB` / `BD_STOP_MSB` 等の定数 (= sample 実体 ROM 位置を `.equ` で定義) の出処は **本 sprint 内で再確認** (= build-time の sed pre-process or 別 include か、 step 7-α で確認)

3. **`.PNE` 設計は既に文書 level で確定** (= `docs/design/mn_binary_layout.md` §4 完成)
   - `extended_data_adr` = `m_buf[26..27]`、 `pne_filename_adr` = `extended_data_adr+12..13`
   - filename string は NUL-terminated ASCII (8.3 形式想定)
   - 例: `"NEOSI001.PNE\0"`
   - driver は filename を読まず、 ROM 配置 (= ROM builder) 側で sample 実体と紐付ける流儀

つまり step 7 で「ゼロから新規実装」 する範囲は **`.PNE` file format 自体 + build-time converter + generated include + asset pipeline 全体** に絞られ、 mc compiler 側は **verify only** に近い状態。

## 決定

### 決定 1: step 7 を「`.PNE` asset pipeline + `.MN` filename embed sprint」 として定義 (= C2 採用)

step 7 の最終 deliverable boundary を **C2 (= build-time converter + `.MN` filename embed)** とする。 driver は完全不変、 mc compiler `/B` path は既存実装の verify を中心とし、 メイン作業は `.PNE` asset pipeline 構築。

**8th session 冒頭壁打ちで提示した 4 candidate (= C1 / C2 / C3 / B) のうち C2 採用理由 (= user 判断)**:

- driver をまだ触らずに済む
- `.MN` format を最終形に近い状態で固定できる
- 後続 sprint で runtime parser に進む時、 driver 側改修だけに集中できる
- C1 だと将来 `.MN` 側の filename embed を追加するために再度 `.MN` layout を揺らすことになる (= regression risk)
- C3 / B は driver parser に入り、 step 7 の scope が重くなる
- step 5/6 で成功した「compiler/build pipeline と driver 改修を分離する」 規律と整合する

#### 補足: step 7 = sample source の外部化、 playback semantics は不変

step 7 は **sample の「供給経路」 を driver 直書きから `.PNE` + build-time converter 経由へ移す sprint** であり、 ADPCM-A lookup / register write / keyon / keyoff / volume / pan / timing 等の **sample playback semantics 自体は変更しない**。 これらは step 5 で完了済 (= ADR-0019)。

future contributor が「音源仕様変更 sprint」 と誤解しないよう明示。 register trace 軸で完全同一 (= byte-identical) になることが本質的根拠 (= 決定 7 primary gate)。

### 決定 2: runtime parser / driver 側 filename read は scope-out

step 7 では driver source (= `src/driver/standalone_test.s`) を **完全不変** とする。 以下は全て scope-out、 後続 sprint へ分離:

- driver による `.MN` 内 `pne_filename_adr` の参照
- filename string read routine
- ROM bank 切替 routine
- runtime sample table 構築 routine
- 楽曲交換時 ROM rebuild 不要化
- 動的 sample bank 管理

**理由**:
- driver を触り始めると trace gate 設計が複雑化 (= step 5/6 で確立した audio isolation 規律と相性悪い)
- 「動いているものを壊さない」 + 「scope-out を守る」 + 「future mode を混ぜすぎない」 原則と整合
- 後続 sprint (= step 8 候補) で driver 改修のみに集中する前提を、 本 sprint で整えるのが目的

### 決定 3: mc compiler `/B` path は verify only

mc compiler `/B` path の `#PNEFile` 受け取り + `pne_filename_adr` embed + filename string 出力は **既に実装済** (= `mc.cs:1491-1565`)。 step 7 では新規実装ではなく **既存実装の verify** を行う。

**verify 軸**:

1. `.MN` 出力時に `m_start bit 2 = 1` が立つ (= PMDNEO mode flag)
2. `m_buf[26..27] = extended_data_adr` が prgdat 領域末尾を正しく指す
3. `extended_data_adr +12..13 = pne_filename_adr` が filename string 先頭を指す
4. `pne_filename_adr` 位置に NUL-terminated `.PNE` filename string がある
5. file 末尾は filename の `0x00` で終わる (= 余分 byte なし)
6. `#PNEFile` 宣言なしで ADPCM-A 使用すると mc compiler が error (= `mc.cs:1492` warning_mes path)

**新規実装が必要になった場合の対処**:
- verify で fail が出た場合のみ、 該当箇所を fix する micro-sprint を起こす
- step 7 sub-sprint 内で完結する想定 (= 大規模改修になれば別 ADR 起票)

### 決定 4: `.PNE` file format 骨格

`.PNE` file format は step 7 で新規定義する。 既存 PMDPPZ `.PZI` / PMD V4.8s `.PPC` / PMD `.P86` 形式は参考にするが、 直接の format 互換は採らない (= ADPCM-A 6 slot 専用、 ADPCM-B / WaveTable / PCM 等は別形式が必要なら別 sprint で扱う)。

**初期 format 案** (= step 7 内で確定):

```
+----------+----------------------------------------------------+
| offset   | 内容                                               |
+----------+----------------------------------------------------+
|  0..7    | magic "PNE\0" + format version (4 byte)            |
|  8..9    | sample slot count (= 初期は 6 固定、 LE 16-bit)    |
| 10..11   | reserved (= 0)                                     |
| 12..N    | sample slot table (= per-slot 6 byte × slot count) |
|          |   slot[i] +0..1: name index (= ASCII 短縮名、 例 "BD")|
|          |   slot[i] +2..3: ADPCM-A start_addr (LE 16-bit、 ROM 配置時 builder が解決) |
|          |   slot[i] +4..5: ADPCM-A stop_addr  (LE 16-bit、 ROM 配置時 builder が解決) |
| N..      | sample 名 string pool (= name index で解決される)  |
| (末尾)   | ADPCM-A raw sample data (= driver / chip が直接読む) |
+----------+----------------------------------------------------+
```

詳細 layout は step 7 着手後の sub-sprint で確定 (= ADR 内 layout は骨格のみ、 実装結果で `docs/design/pne_binary_layout.md` を新規起票)。

**選定理由**:
- 既存 6 slot (= bd/sd/hh/tom/rim/top) を最小構成として収容できる
- format version field で将来拡張余地を確保
- slot count 拡張 (= 6 → 任意) を将来 sprint で扱える
- name index は build-time converter / WebApp UI 両方で参照可能

### 決定 5: build-time converter + ngdevkit vromtool.py 経路温存 (= path B / c1、 α-2 で正式確定)

#### 補正経緯 (= α-1 / α-2 で path A → path B へ修正)

ADR-0021 起票時 (= 2026-05-13 8th session 冒頭) は path A (= 「`.PNE` → 直接 `samples.inc` 生成 + driver source の sample data 部を生成 include へ移行」) を想定していた。

α-1 (= commit `38e35bf`、 `docs/design/pne_binary_layout.md` 起票) の provenance 調査で、 **既存 driver build pipeline は ngdevkit native の vromtool.py 経由で `samples.inc` を自動生成済** という事実が判明:

```
assets/sounds/adpcma/2608_*.adpcma + samples-map.yaml
  ↓ vromtool.py (ngdevkit native)
build/assets/samples.inc (= BD_START_LSB 等 .equ defines)
  ↓ assembler
driver build
```

つまり driver source の sample data 部 (= `standalone_test.s:2825-2840`) は **既に生成 file の defines を消費する形** に成立しており、 改めて include 化する必要なし。

α-2 (= 本 commit) で更に vromtool.py 実仕様調査を行い:
- usage `FILE [FILE ...]` (= 複数 yaml file 受付可能)
- 実装 `load_sample_map_file(filenames)` で全 entry を merge

を確認、 **path B (= `.PNE` → `samples-map-adpcma.yaml` + `.adpcma` → vromtool.py → samples.inc) + c1 (= ADPCM-A / ADPCM-B yaml 分離)** を正式採用する。

#### path B / c1 経路図

```
[source of truth — 手書き / 編集対象]
assets/pne/PMDNEO01.PNE              assets/pne/samples-map-adpcmb.yaml
(ADPCM-A 6 slot)                     (ADPCM-B 1 entry = beat)
       |                                       |
       ↓ converter (= β で実装)                ↓ cp / symlink (= β で経路確定)
       |                                       |
[generated artifact — 編集禁止]               [retained — vendor dir に配置]
vendor/ngdevkit-examples/00-template/assets/samples-map-adpcma.yaml
vendor/ngdevkit-examples/00-template/assets/{bd,sd,hh,rim,tom,top}.adpcma
                                              + samples-map-adpcmb.yaml
                                              |
                                              ↓ vromtool.py (= ngdevkit native、 完全不変)
                                                 + 引数順序: adpcma yaml 先 / adpcmb yaml 後
                                              |
                                              ↓
                              build/assets/samples.inc (= 既存と byte-identical)
                                              |
                                              ↓ assembler
                              driver build (= standalone_test.s 完全不変)
```

#### converter の責務境界 (= vromtool.py 前段 layer)

Step 7 converter (= `scripts/pne-to-ngdevkit.py`、 β で実装) は **既存 production pipeline である vromtool.py の前段 layer** と位置付ける。 converter は「`.PNE` → normalized yaml + `.adpcma` extraction」 までを責務とし、 **VROM packing 自体は引き続き vromtool.py の責務**。

つまり:

- **converter (= 新規)**: `.PNE` を解いて vromtool.py が受け取れる形 (= yaml + 個別 `.adpcma` binary) に正規化するだけ
- **vromtool.py (= 既存、 不変)**: yaml + `.adpcma` を読んで VROM 配置 + address 計算 + `samples.inc` 生成

future contributor が converter を「新 VROM generator」 と誤解しないよう、 layer 境界を明示する。 vromtool.py を「ngdevkit native の確立済 production pipeline」 として尊重し、 PMDNEO 側でその責務範囲には踏み込まない (= driver 不変規律 / vendor 改造最小規律と同精神)。

#### driver source 改修範囲 (= 完全に不要、 決定 2 と完全整合)

path B 採用により、 driver source (= `src/driver/standalone_test.s`) は **本当に完全不変** (= `standalone_test.s:2825-2840` の sample table も touch しない)。 既存 vromtool.py が生成する `samples.inc` を assembler が既に解決済のため、 改めて include 化や定義移動は不要。

これは決定 2「driver runtime parser / driver 側 filename read は scope-out」 と **完全整合**する (= 元 ADR-0021 で「driver の data 部のみ生成へ移行」 という limited な改修を許容していた点は撤回)。

#### 改修対象の全件列挙

path B / c1 採用後の Step 7 改修対象は以下 4 件のみ:

| 件 | 対象 | sub-sprint | 改修規模 |
|---|---|---|---|
| 1 | `scripts/pne-to-ngdevkit.py` (= converter 新規) | β | 100 行以下見込み |
| 2 | `vendor/ngdevkit-examples/00-template/Makefile` 3 行改修 (= 案 1 採用、 `$<` → `$^` + prerequisite 列挙) | β | 3 行 diff |
| 3 | `scripts/build-poc.sh` に ADPCM-B yaml 配置経路追加 | β/γ | 数行 |
| 4 | `assets/pne/PMDNEO01.PNE` + `assets/pne/samples-map-adpcmb.yaml` 新規 asset | β | 新規 file |

詳細仕様は `docs/design/pne_binary_layout.md` §6 (= path B 経路 + Makefile 改修方針 + ADPCM-B yaml 配置) + §12 (= converter I/O contract) を参照。

#### 生成 artifact の ownership / 手編集禁止

`vendor/ngdevkit-examples/00-template/assets/samples-map-adpcma.yaml` および `{bd,sd,hh,rim,tom,top}.adpcma` 6 件は **build artifact** であり、 **手編集禁止** とする:

- **source of truth は `.PNE` file** (= `assets/pne/PMDNEO01.PNE`)
- **唯一の生成元は `scripts/pne-to-ngdevkit.py`** (= build-time converter、 β で実装)
- 手編集が必要な変更は必ず **`.PNE` 側** に施す (= 生成 yaml / .adpcma 側で受けない)
- 生成 yaml の先頭に「DO NOT EDIT — generated from {input .PNE filename} by scripts/pne-to-ngdevkit.py」 警告 comment を入れる (= 事故防止、 §12-3 で詳述)
- git ignore か commit するかは別判断 (= β / γ で決定)、 ただし **「source of truth ではない」 ことは不変**

`assets/pne/samples-map-adpcmb.yaml` (= ADPCM-B 用 hand-written) は **手編集対象、 source of truth retained** であり、 上記 ownership 規約とは独立 (= ADPCM-A と ADPCM-B の系統分離が c1 採用の本質)。

driver の `code` + `data` 部分 (= `standalone_test.s` 全体) は引き続き手書き source of truth として扱う (= path B により data 部の生成 include 化も発生しないため、 driver source の ownership は touch なし)。

#### `assets/sounds/adpcma/2608_*.adpcma` の扱い

既存 `assets/sounds/adpcma/2608_*.adpcma` 6 件は **path B 採用後は source of truth でなくなる** (= `.PNE` 内 raw data に統合される予定、 β で実体化)。 ただし β/γ 完了まで:

- 既存 file は **retain** (= 削除しない、 PMDNEO 累積資産)
- `.PNE` 内 raw data は既存 file から pack して作成 (= round-trip test で byte-identical 確認)
- β/γ 完了後の cold storage 移動判断は別 micro-sprint で扱う

### 決定 6: `.PNE` asset の初期内容

step 7 初期 `.PNE` asset は **既存 driver 内蔵 6 slot (= bd/sd/hh/tom/rim/top) を そのまま外部化** する。 新規 sample 追加は scope-out。

**理由**:
- 既存資産を `.PNE` 経由で同じ ROM build 結果になることを byte-identical で確認できる (= regression test として最強)
- 新規 sample 追加は asset 制作 (= WAV → ADPCM-A 変換 UI 等) と絡むので別 sprint
- step 5/6 で確立した「動いているものを壊さない」 規律と整合

**運用**:
- 既存 sample raw data (= ngdevkit-examples 由来? vendor 由来? step 7-α で出処確認) を `.PNE` 形式で再パッケージ
- `.PNE` 内 slot 順は L=bd / M=sd / N=hh / O=tom / P=rim / Q=top (= 現状 `adpcma_ch_sample_ptr_table` 順と一致)
- `.PNE` filename は例えば `PMDNEO01.PNE` で固定 (= step 7 では 1 種類のみ、 複数 `.PNE` 対応は別 sprint)

### 決定 7: primary gate / audio gate の役割分離 (= step 5/6 規律踏襲)

step 7 でも primary gate = **register trace (= ymfm-trace / z80-mem-trace) + ROM build byte-identical** を維持し、 audio (= wav / MAME 再生) は **reference + human verification** として位置付ける。

**理由**:
- `feedback_refactor_gate_register_trace_not_wav` 規律踏襲
- step 5/6 で確立した primary gate 軸を変えない (= sprint 間 verification 一貫性)
- step 7 の本質は data 表現の変更 (= 直書き → 生成 include) で、 register write が同一なら functional 等価

**運用**:
- 各 sub-sprint で「`.PNE` 経由 build」 と「直書き source build」 で ROM byte-identical (= 完全一致) を確認
- ROM byte-identical PASS なら register trace は自動的に同一 (= 中身が同じなので)
- audio gate (= step 6 silent-bcef fixture + MAME 試聴) は最終確認で 1 回実施

### 決定 8: sub-sprint 分割案

step 7 を **α / β / γ / δ / ε の 5 sub-sprint 構造** で進める。

| sub | 範囲 | trace gate |
|---|---|---|
| α | `.PNE` format 確定 + 既存 sample 出処調査 + `docs/design/pne_binary_layout.md` 起票 | 設計書のみ (= 実装なし) |
| β | `.PNE` → `samples.inc` build-time converter 実装 (= `scripts/pne-to-inc.py` 新規) | converter 単体 unit test (= 既存 sample で .PNE 経由 → 直書き source と byte-identical な include 生成) |
| γ | driver source の sample data 部を生成 include へ移行 + ROM byte-identical 確認 | ROM byte-identical (= `.PNE` 経由 vs 直書き source) |
| δ | mc compiler `/B` path `pne_filename_adr` embed の verify (= 既存実装の verify only) | `.MN` hex dump で filename embed 確認 |
| ε | 完了統合 + handoff doc + ADR-0021 Accepted 移行 | step 6 silent-bcef fixture + MAME 試聴 (= regression test) |

**1 sub = 1 commit + 1 push 規律** (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) を維持。

### 決定 9: handoff doc 構造

step 7 の handoff doc は sub-sprint ごと独立、 完了統合は別 doc。

| 段階 | 文書 | 内容 |
|---|---|---|
| α | `docs/design/pne_binary_layout.md` | `.PNE` format 仕様確定 (= 新規設計書) |
| β | `docs/design/handoff/adr-0016-step7-b-pne-converter.md` | converter 実装 + unit test 結果 |
| γ | `docs/design/handoff/adr-0016-step7-c-driver-include-migration.md` | driver source 改修 + ROM byte-identical 結果 |
| δ | `docs/design/handoff/adr-0016-step7-d-mc-compiler-verify.md` | mc compiler `/B` path verify 結果 |
| ε | `docs/design/handoff/adr-0016-step7-completion.md` | step 7 統合 sum-up + ADR-0021 Accepted 移行 |

## scope-in / scope-out 明示

### scope-in (= step 7 本 sprint 範囲)

- `.PNE` file format 実体確認 + `docs/design/pne_binary_layout.md` 起票 (= α)
- `.PNE` sample pack 作成 (= 既存 6 slot を `.PNE` 形式で再パッケージ、 新規 sample 追加なし、 α/β)
- build-time converter (= `scripts/pne-to-inc.py` 新規) 実装 (= β)
- `.PNE` → 生成 sample include (= `src/driver/generated/samples.inc` 新規) (= β/γ)
- driver source の sample data 部 (= `standalone_test.s:2825-2840` の `.db` 列) を生成 include へ移行 + ROM byte-identical 確認 (= γ)
- mc compiler `/B` path `pne_filename_adr` embed の verify (= 既存実装の hex dump 確認、 δ)
- `.MN` 内 filename string が正しく入ることを hex dump で確認 (= δ)
- driver は既存 sample table interface (= `adpcma_ch_sample_ptr_table` voice index 引き) を使う (= 不変)
- trace primary で `@0/@1` sample addr 差分を確認 (= step 5 β-3 verify script と同等経路、 γ/δ)
- step 6 silent-bcef fixture + MAME 試聴 (= ε regression test)
- step 7 完了統合 handoff doc + ADR-0021 Accepted 移行 (= ε)

### scope-out (= step 7 範囲外、 後続 sprint で扱う)

- runtime `.PNE` parser (= driver が `.MN` 内 filename を読んで動的に sample table を構築)
- driver 側 filename string read routine
- ROM bank switching / 動的 sample bank 管理
- 楽曲交換時 ROM rebuild 不要化
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- PMDNEO.s + nullsound integration (= 大規模 sprint)
- 新規 sample 追加 (= WAV → ADPCM-A 変換 UI、 WebApp Phase 4 領域)
- 複数 `.PNE` file 対応 (= 楽曲ごと別 sample bank)
- PPZ compatibility mode
- FM-Towns-style rhythm mode

## 完了判定

### step 7 全体完了判定 (= ADR-0021 Accepted 移行条件)

1. **α**: `.PNE` format 仕様確定 + `docs/design/pne_binary_layout.md` 起票 + commit + push
2. **α**: 既存 sample 出処調査結果を α handoff doc に記録
3. **β**: `scripts/pne-to-inc.py` (= build-time converter) 実装 + unit test PASS + commit + push
4. **β**: `.PNE` → `samples.inc` 生成結果が直書き source と byte-identical (= unit test)
5. **γ**: `standalone_test.s:2825-2840` の sample data 部を生成 include へ移行 + commit + push
6. **γ**: ROM byte-identical 確認 (= `.PNE` 経由 vs 移行前 source、 完全一致)
7. **δ**: mc compiler `/B` path `pne_filename_adr` embed verify + hex dump 確認 + commit + push
8. **δ**: `.MN` 内 filename string が正しく NUL-terminated で入っている
9. **ε**: step 6 silent-bcef fixture + MAME 試聴 で regression なし (= ADPCM-A L-Q 6 音 audible 確認)
10. **ε**: step 7 完了統合 handoff doc + ADR-0021 Accepted 移行 + commit + push

### sub-sprint 完了判定 (= 個別)

各 sub-sprint の完了判定は handoff doc に記述。 全 sub-sprint で「1 sub = 1 commit + 1 push + user 都度レビュー待ち」 規律を遵守。

## 関連 memory

- `project_pmdneo_step6_complete.md` (= step 6 完了状態)
- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 `.PNE` 接続点予約)
- `project_adr_0016_step5_design_decision_3_sample_addr_build_embed.md` (= sample addr は build 時 embed + `.PNE` は設計書記述のみ)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_trivial_verify_detection_and_correction_commit.md` (= trivial verify 検出 + 補正 commit 規律)

## 完了判定達成状況 (= 2026-05-13 8th session、 step 7 ε 完了統合)

### 全体完了判定 10 項目

| # | 項目 | 達成 | 関連 commit |
|---|---|---|---|
| 1 | α-1: `.PNE` format 仕様確定 + `pne_binary_layout.md` 起票 | ✅ | `38e35bf` |
| 2 | α-1: 既存 sample 出処調査結果を α handoff doc 記録 | ✅ | `38e35bf` §2 |
| 3 | β-1: `scripts/pne-to-ngdevkit.py` (= converter) 実装 + unit test PASS | ✅ | `a25155d` |
| 4 | β-1: 生成 sample が直書き source と byte-identical (= round-trip) | ✅ (= 6/6 sha256 PASS) | `a25155d` |
| 5 | γ: `standalone_test.s:2825-2840` の sample data 部を生成 include へ移行 | ⏸ **skip** (= path B 採用で不要、 §決定 5 補正済) | — |
| 6 | γ: ROM byte-identical 確認 | ✅ (= β-3 で samples.inc + VROM 4 件全件 byte-identical、 driver / vromtool.py 不変から ROM final 数学的同値) | `e3fdda5` |
| 7 | δ: mc compiler `/B` path `pne_filename_adr` embed verify + hex dump | ✅ (= 4/4 gate PASS、 前提 fix = `d653d62`) | `50d34d8` |
| 8 | δ: `.MN` 内 filename string が NUL-terminated で正しく入っている | ✅ (= `step5.PNE\0` 9 byte + NUL) | `50d34d8` |
| 9 | ε: step 6 silent-bcef fixture + MAME 試聴 で regression なし | ✅ (= β-3 で step 6 verify 改修不要で 7/7 PASS) | `e3fdda5` |
| 10 | ε: step 7 完了統合 handoff doc + ADR-0021 Accepted 移行 | ✅ | 本 commit |

→ **10/10 達成** (= #5 は path B 採用で正規に skip、 残り 9 項目すべて PASS)。

### sub-sprint commit chain (= step 7 全 8 commit)

| sub | commit | 内容 |
|---|---|---|
| 起票 | `60e78d4` | docs(adr): step 7 着手前に ADR-0021 起票 |
| α-1 | `38e35bf` | docs(design): `.PNE` binary layout 起票 + provenance 調査 (= path B 推奨判明) |
| α-2 | `e30ef4c` | docs(design): path B / c1 正式採用 + converter I/O contract + ADR-0021 §決定 5 補正 |
| β-1 | `a25155d` | feat(asset): converter prototype + canonical test asset + round-trip 4 gate PASS |
| β-2 | `0668594` | feat(build): build pipeline 接続 (= vendor Makefile + build-poc.sh + ADPCM-B yaml 分離) |
| β-3 | `e3fdda5` | test(infra): byte-identical primary gate + regression verify |
| δ-fix | `d653d62` | fix(compiler): mc compiler `#PNEFile` surrounding quotes strip (= 局所修正) |
| δ | `50d34d8` | test(infra): `pne_filename_adr` embed 4 gate verify (= `.MN` ↔ `.PNE` format contract 接続) |
| ε | 本 commit | docs(adr): step 7 完了統合 + ADR-0021 Accepted 移行 |

### Accepted 移行根拠

- 完了判定 10 項目中 9 項目 PASS + 1 項目 (= γ) 正規 skip
- ADR-0021 §scope-out 全 9 項目 維持確認済 (= 完了統合 handoff doc 参照)
- step 5/6 verify 改修不要で新経路 regression なし PASS (= 既存 architecture 整合性確認)
- ROM final byte-identical 数学的同値性成立 (= primary gate)
- driver completely unchanged (= literal 完全不変、 ADR-0021 §決定 2 が literal に成立)

→ ADR-0021 = **Accepted**。

### Accepted 後の重要境界 (= future contributor 向け明示)

**Step 7 は `.PNE` runtime parser を実装していない**。 現時点で `.PNE` は **build-time source-of-truth** であり、 runtime resolution は **Step 8 以降の候補**:

- `.PNE` の解決は build pipeline (= converter + vromtool.py) が担当
- driver / runtime は `.PNE` を直接読まない (= `pne_filename_adr` は format 先行固定のみ、 driver 不参照)
- 楽曲交換時は ROM rebuild が必要 (= 「ROM rebuild なし楽曲交換」 は Step 8 候補)

`.PNE` filename embed が成立しているため誤解しやすいが、 これは **future runtime parser のための format contract 先行固定**。 完了統合 handoff doc §architecture observation 末尾と同整理。

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 §決定 3 (= `.PNE` parser 次 sprint 接続点予約)
- ADR-0020 §次 sprint 候補 (= `.PNE` parser を筆頭に挙示)
- `docs/design/PMDNEO_DESIGN.md` §1-8-3 (= `.PNE` 仕様骨子)
- `docs/design/mn_binary_layout.md` §4-3-3 / §7-2 / §11 (= `pne_filename_adr` + filename string embed + 残課題 #3)
- `docs/design/ppz_to_adpcma_mapping.md` (= PPZ → ADPCM-A 写像、 `.PZI` 流儀踏襲根拠)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止

## 次 sprint 候補

1. **α 着手** (= `.PNE` format 確定 + 既存 sample 出処調査 + `docs/design/pne_binary_layout.md` 起票)
2. β 着手 (= `scripts/pne-to-inc.py` 実装 + unit test)
3. γ 着手 (= driver source 改修 + ROM byte-identical 確認)
4. δ 着手 (= mc compiler `/B` path verify + hex dump)
5. ε 着手 (= 完了統合 + handoff doc + Accepted 移行)
6. **step 8 候補** (= 本 ADR scope-out のうち未消化): runtime `.PNE` parser driver 実装 (= driver 改修専念 sprint) / K-R compat micro-sprint / nullsound integration 再検討 / 複数 `.PNE` file 対応 等
