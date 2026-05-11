# ADR-0015: PMDDotNET 改造 技術調査 sprint — 改造 PMDNEO.ASM 設計のための作業計画

- 状態: Proposed (= 調査未着手、 結果は段階的に追記)
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0013 (= 同 .M 2 経路比較 路線へ切替)、 ADR-0014 (= ADR-0006 sprint 成果のカテゴリ別判断 + PMDPPZ 流儀発見)

## 背景

ADR-0013/0014 で次の路線が確定した:

- 検証経路: 同 .M (= 同一 MD5) 2 経路比較
- PMDNEO 本体 driver: PMD V4.8s 公式 driver (= `vendor/pmd48s/source/pmd48s/PMD.ASM`、 10864 行) を改造、 PMDPPZ 流儀で wrapper file + 条件 assemble 拡張
- 改造規模見込み: 推定 100-150 件 if 分岐 + wrapper file 1 つ = 元の 5-10% 修正
- mc compiler 側も OPNB 出力対応に改造 (= `vendor/PMDDotNET/PMDDotNETConsole`)

ただし「どこに if 分岐を入れるか」 「NEOGEO 環境依存層は具体的にどう書くか」 「mc compiler の OPNB 出力分岐はどこに挟むか」 は未確定。 改造着手 sprint (= 想定 ADR-0016) の前にこれらを技術調査として固定する必要がある。

本 ADR は改造着手に向けた **技術調査 sprint の作業計画** を立てる。 調査結果は本 ADR 自体に段階的に追記し、 完了時に ADR-0016 起票へ移行する。

## 調査範囲 (= 5 軸)

### 軸 1: PMD.ASM 内の chip 別経路特定

**目的**: PMD V4.8s の条件 assemble 構造を把握し、 新規 `neogeo` / `opnb` flag を挿入する場所を見極める。

**作業内容**:
- PMD.ASM 内の `if board2` / `if adpcm` / `if ppz` / `if pcm` / 組合せの全 203 件を分類
- 各分岐の目的 (= 例「ppz が立っている時に PPZDRV を include」、「board2 が立っている時に OPNA register を使う」 等) を読解
- ADPCM 関連 (= adpcm flag、 OPNA 内蔵 ADPCM-B) の register write 経路を特定
- PPZ8 関連 (= ppz flag) の構造を踏襲手本として整理 (= PMDNEO の opnb flag 設計の参考)

**期待成果**: 「PMD.ASM 内の chip / 環境分岐 map」 (= 行番号 + flag + 目的の対応表)。 ADR-0015 に追記 or 別 memory 化。

### 軸 1 中間結果 (= 2026-05-11 着手、 全 203 件集計 + ppz 関連 38 件中 10 件サンプリング読解)

#### 全 203 件 flag 別集計

| flag | 件数 | 意味 |
|---|---|---|
| `board2` | 90 | サウンドボード 2 (= OPNA、 PC-9801-86 等) |
| `ppz` | 35 | PPZ8 (= 8ch PCM 拡張、 **PMDPPZ 流儀の手本**) |
| `va` | 22 | VA (= VA1/VA2 機種) |
| `pcm` | 11 | 86PCM (= サウンドボード 86 内蔵 PCM) |
| `board2*adpcm` | 8 | OPNA + 内蔵 ADPCM-B 組合せ |
| `ademu` | 8 | ADPCM emulation (= 内蔵 ADPCM 無い機種用) |
| `board2*pcm` | 7 | OPNA + 86PCM 組合せ |
| `adpcm` | 6 | 内蔵 ADPCM (= 単独) |
| `vsync` | 4 | VSync 関連 timing |
| `sync` | 3 | MIDI sync |
| `pcm+ppz` | 2 | 86PCM + PPZ8 組合せ |
| 各種組合せ | 計 7 | |
| その他 (= `_myname` / `_optnam` / `resmes` / `1`) | 4 | name 系 + 突撃 mix flag |

**全部 PC-9801 環境前提**。 PMDNEO で必要なのは:
- `neogeo` flag (= 新規、 環境移植層): 推定 20-40 件
- `opnb` flag (= 新規、 chip 移植層): 推定 50-80 件
- 不使用 flag (= `va` / `pcm` / `ppz` / 関連組合せ): 計 85 件、 wrapper で立てなければ自動除外

#### PPZ8 拡張の 7 component (= サンプリング読解結果)

PPZ8 拡張 (= ppz 35 件 + 組合せ 3 件) を行番号別にサンプリング読解、 typical pattern を抽出:

| # | 行範囲 | component | PMDNEO への対応案 |
|---|---|---|---|
| 1 | 250-258 | `_ppz` macro (= ppz call wrapper) | `_neogeo_main_cpu_recv` macro 等 |
| 2 | 367-369 | `if ppz / include ppzdrv.asm` | `if neogeo / include neogeo-env.asm` + `if opnb / include opnb-driver.asm` |
| 3 | 475-488 | PPZ8 driver 初期化 (= ppz_call_seg 設定 + int 呼出) | NEOGEO sound subsystem 初期化 (= main CPU command 受付 establish) |
| 4 | 703-706 | `_ppz_voldown` 変数 transfer | (= NEOGEO は単 chip、 該当部分薄い) |
| 5 | 6142-6159 | サウンド停止 routine の ppz keyoff loop | OPNB 全 ch keyoff routine (= FM + SSG + ADPCM-A + ADPCM-B) |
| 6 | 7177+ | part_table 拡張 (= PPZ1/2/3 行追加) | OPNB 用 part 配置 (= 既存 PMDDotNET 流儀踏襲、 PPZ 行削除) |
| 7 | 10164+ | /Z option (= PPZ8 CLI 接続 / 切断) | (= 不要、 NEOGEO に CLI なし) |

#### 重要な構造的違い (= PPZ8 と PMDNEO)

- **PPZ8**: 外部 driver (= PPZDRV.ASM) を **間接呼出** する wrapper 構造 (= ppz_call_seg / ppz_vec 経由)
- **PMDNEO**: 自身が driver の本体、 **OPNB register を直接 write** する構造

つまり PMDNEO の `if neogeo` / `if opnb` 分岐は、 PPZ8 流儀をそのまま踏襲できない部分がある:
- macro 化 / include 切替 / 初期化 / 停止 / part table の pattern は流用可能
- **register write 経路の OPNB 化は新規**、 PPZ8 では参考にならない。 むしろ `board2` 90 件のうち「register / port 関連部分」 (= 軸 3 で調査) の方が手本

#### 推定改造規模 (= 軸 1 結果を踏まえた更新)

| 区分 | 推定件数 | 内訳根拠 |
|---|---|---|
| macro / include / 初期化 / 停止 routine | 10-20 件 | PPZ8 流儀踏襲、 PMDPPZ で同等規模 |
| part table / cmd handler 拡張 | 15-25 件 | PPZ8 で 15-20 件、 PMDNEO 同等 |
| register write 経路の OPNB 化 | 50-80 件 | 新規、 board2 90 件のうち register 関連部分が手本 |
| NEOGEO 環境移植 | 20-40 件 | 新規、 軸 2 で具体化 |
| **合計** | **95-165 件** | ADR-0014 で立てた 100-150 件と整合 |

#### 残作業 (= 軸 1 後半、 軸 3 と並行可能)

- ppz 関連 38 件のうち未読 28 件 (= 8k-9k 領域の cmd handler 中心) は、 軸 3 (= OPNB 差分) で「OPNB 用 cmd handler 設計」 と並行調査
- `board2` 90 件のうち「register / port 関連」 部分を抽出、 OPNB 並行 / 置換候補として整理 (= 軸 3 と統合)
- `adpcm` / `board2*adpcm` 14 件は OPNB 内蔵 ADPCM-B 経路として継承可能性、 軸 3 で判定

### 軸 2: NEOGEO 環境依存箇所の特定

**目的**: PC-9801 想定の環境依存層を NEOGEO 環境に置換える具体的箇所を特定。

**作業内容**:
- I/O port (= PC-9801 OPNA は port 0x188-0x18B、 NEOGEO YM2610 は port 0x04-0x05 / 0x06-0x07) の差分整理
- IRQ (= PC-9801 vsync IRQ / timer IRQ、 NEOGEO は別 vector + timing) の差分整理
- memory map (= PC-9801 dos memory vs NEOGEO sound ROM 領域 + RAM 領域) の差分整理
- main CPU 通信 (= PC-9801 では DOS process 通信、 NEOGEO は 68000 から Z80 へ port 経由 command) の追加実装範囲
- `vendor/ngdevkit-examples/` の既存 NEOGEO Z80 sound driver 例を reference として読解

**期待成果**: 「NEOGEO 環境依存層の if neogeo 挿入候補 list」 (= PMD.ASM 内の行 + 既存 PC-9801 code + 必要な NEOGEO code)。

### 軸 3: OPNB chip 差分の特定

**目的**: OPNA → OPNB の chip register / 機能差分を整理し、 `if opnb` 挿入候補を特定。

**作業内容**:
- register address 差分 (= OPNA と OPNB は port 番号違うが register layout 似てる)
- ADPCM-A 6 ch 経路 (= OPNA の Rhythm 経路 = `if adpcm` + `if board2` で書かれている、 OPNB ADPCM-A は別系統リソース)
- ADPCM-B 1 ch (= OPNA / OPNB 共通だが、 OPNB は sample bank の memory layout が異なる)
- SSG 3 ch (= OPNA と OPNB はほぼ共通、 base clock 差異のみ)
- FM 4 ch / 6 ch (= YM2610 は 4 ch、 YM2610B は 6 ch、 ADR-0001 既決事項参照)
- ADR-0010 で整理した「YM2610 = YM2610B の ch1/ch4 物理 omit 派生 chip」 の事実は本路線でも継承
- 既存 memory `reference_opna_opnb_chip_comparison.md` (= もし存在すれば) や PMD V4.8s manual を reference

**期待成果**: 「OPNA → OPNB 差分表」 + 「if opnb 挿入候補 list」 (= PMD.ASM 内の行 + 既存 OPNA code + 必要な OPNB code)。

### 軸 4: mc compiler 改造範囲特定

**目的**: `vendor/PMDDotNET/PMDDotNETConsole/` (= C# 移植版 mc compiler) を OPNB 対応にする改造範囲を特定。

**作業内容**:
- mc compiler の OPNA 出力経路を読解 (= 例 `mc.cs` 内の voice 定義 → register layout 変換ロジック)
- OPNB 出力分岐の挿入候補箇所を特定 (= build flag or runtime flag で OPNB mode 化)
- .M format 内に OPNB 識別子 / metadata を追加するか、 driver 側で吸収するかの設計判断
- 同 .M format (= 同一 MD5) 保証のため、 OPNB 用 .M は別 file 出力か同 file format 内で flag 切替か

**期待成果**: 「mc compiler 改造箇所 list」 + 「.M format design 決定」 (= OPNA / OPNB 識別の方法)。

### 軸 5: 改造規模見積もり最終化

**目的**: 軸 1-4 の調査結果を踏まえ、 改造規模を最終確定し ADR-0016 (= 改造着手) 起票準備。

**作業内容**:
- 100-150 件 if 分岐の具体的内訳 (= 軸 2 の neogeo / 軸 3 の opnb の合計)
- 各 if 分岐の影響範囲 (= 数行 vs 数十行 vs 数百行)
- 作業順序の選択肢 (= 例「先に NEOGEO 環境移植 → 次に OPNB chip 移植」 vs 「先に OPNB chip 移植 → 次に NEOGEO 環境移植」)
- 段階的検証経路 (= 例「NEOGEO 環境 + OPNA mock で実機動作 → OPNB 切替」 が可能かの判定)
- mc compiler 改造のタイミング (= driver と並行 or 後)

**期待成果**: ADR-0016 (= 改造着手 sprint の作業計画) を書き起こせる程度の改造規模 + 着手順序 + 段階的検証方針の確定。

## 調査手法

- **grep + 読解**: PMD.ASM / 関連 ASM file / mc compiler C# source を grep + 行範囲読解
- **memory + ADR-0015 追記**: 調査結果を memory または ADR-0015 本体に段階的に蓄積
- **ngdevkit examples reference**: NEOGEO Z80 sound driver の既存実装例から memory map / IRQ / I/O 規定を借用
- **PMDPPZ.ASM 流儀踏襲**: 既存 PPZ8 拡張の流儀 (= 16 行 wrapper + 35 件の if 分岐) を改造手本として参照
- **commit / push 前に平易な日本語報告**: feedback_explain_in_plain_japanese_before_commit.md 規律遵守

## 期待成果物

調査完了時に以下が揃う:

1. **ADR-0015 本体に各軸の調査結果を追記** (= 行番号 + flag + 目的の対応表、 if 分岐挿入候補 list、 mc compiler 改造箇所 list)
2. **必要に応じて memory 化** (= 例「PMD.ASM 構造調査結果」 memory、 「NEOGEO 環境移植要点」 memory 等)
3. **ADR-0016 起票準備** (= 改造着手 sprint の作業計画、 着手順序、 段階的検証方針)

## 着手順序

```
1. 軸 1: PMD.ASM 構造調査 (= 最優先、 起点)
   ↓
2. 軸 2 + 軸 3 並行 (= NEOGEO 環境 + OPNB 差分、 独立した調査軸)
   ↓
3. 軸 4: mc compiler 改造範囲 (= 軸 3 OPNB 差分結果が前提)
   ↓
4. 軸 5: 改造規模見積もり最終化 (= 軸 1-4 集約)
   ↓
5. ADR-0016 起票
```

軸 1 の調査結果次第で軸 2/3/4 の作業量が変動する可能性あり、 段階ごとに user 壁打ち + 判断仰ぐ。

## 完了判定

ADR-0016 (= 改造着手) を書き起こせる程度に以下が確定した状態:

- PMD.ASM 内の neogeo / opnb 挿入候補箇所 (= 行番号レベル)
- mc compiler の OPNB 出力分岐挿入箇所
- 改造規模 (= if 分岐の具体的数 + 各分岐の影響行数)
- 着手順序 + 段階的検証方針

## 関連 memory

- `project_adr_0013_0014_path_switch.md` (= ADR-0013/0014 路線変更記録 + PMDPPZ 流儀発見)
- `project_pmddotnet_chextend_data_area.md` (= PMDPPZ + FM3Extend data area)
- `project_mame_headless_recording_mode.md` (= MAME 録音 mode、 検証経路で再利用)
- `project_pmd_voice_{tl,ar,dr,ml,alg,fbl}_verified.md` (= PMDDotNET 側 reference 検証結果、 本路線でも有効)
- `feedback_explain_in_plain_japanese_before_commit.md` (= 規律)
- `feedback_branch_strategy.md` (= 規律)

## 次 sprint 候補

1. **軸 1 PMD.ASM 構造調査 着手** (= 本 sprint 最初のステップ)
2. **段階的に軸 2-5 を進行** (= 各軸完了ごとに ADR-0015 追記 + user 報告)
3. **ADR-0015 完了後 ADR-0016 起票** (= 改造着手 sprint の作業計画)
