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
