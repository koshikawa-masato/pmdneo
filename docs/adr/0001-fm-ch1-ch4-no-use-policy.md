# ADR-0001: PMDNEO 楽曲は YM2610 無印 chip ch 1/4 を不使用とする (C 方針)

- 状態: Accepted
- 起票日: 2026-05-08
- 起票者: 越川将人 (M.Koshikawa)
- 関連: Phase 2 SubC-1 audio gate、 memory `reference_opna_opnb_chip_comparison.md`、 memory `project_pmd_invalid_channel_silence_invariant.md`

## 背景

PMDNEO は NEOGEO (YM2610/B) 用の PMD 系統 driver。 PMD V4.8s の OPNA 楽曲流儀
(= Part A-F = FM 6ch) を踏襲する設計だが、 NEOGEO に搭載される chip は **YM2610
無印が標準** で、 YM2610B (= FM 6ch 全部 output) は実機入手困難 (= リマーク詐欺
横行、 memory `reference_opna_opnb_chip_comparison.md`)。

### YM2610 無印の chip 仕様

YM2610 無印 chip は internal に FM 6ch 全部存在するが、 **chip ch 1 (= ch index 0)
と chip ch 4 (= ch index 3、 port B index 0) は output 配線がない**(= register
write は通るが音が出ない)。 残る 4 ch (= chip ch 2/3/5/6) のみ output される。

これは nullsound の channel 命名にも反映されている:

```
FM1_YM2610 = 1   ; nullsound FM1 → chip ch 2 (= 末尾 +1)
FM2_YM2610 = 2   ; nullsound FM2 → chip ch 3
FM3_YM2610 = 5   ; nullsound FM3 → chip ch 5 (= port B + 末尾 +1)
FM4_YM2610 = 6   ; nullsound FM4 → chip ch 6
```

### PMD driver の不変条件

PMD V4.8s 流儀の driver は **無効チャンネルへの register write で破綻せず無音**
という不変条件を持つ。 SubC-1 audio gate (2026-05-08) で chip ch 1 を駆動した
結果が無音 (= 音色 / fnum / keyon は正常書込されたが output されない) であった
事実は、 PMDNEO driver が PMD V4.8s 不変条件を継承していることを逆方向に実証
している (memory `project_pmd_invalid_channel_silence_invariant.md`)。

## 検討した選択肢

### (A) 全 part を chip ch 2/3/5/6 で運用

- letter convention を再 mapping (= Part A → chip ch 2、 Part B → ch 3、 …)
- nullsound 命名と整合
- ただし PMD V4.8s 楽曲を直接持ち込む際 letter 翻訳が必要
- 楽曲 4 ch 限定 (= Part E/F は表現不可)

### (B) YM2610B 想定で 6 ch 全部使う

- letter convention は PMD V4.8s と同一
- ただし YM2610B 実機は入手困難、 emulator 限定の動作になる
- ROM を YM2610 無印実機で再生すると Part A/D が無音

### (C) ハイブリッド: driver は 6ch 実装、 楽曲は Part B/C/E/F のみ使う自己規律

- driver は YM2610B 仕様で書く (= 6 ch 全部 dispatch + register write)
- 楽曲生成側 (= mc compiler / MML 作曲) で **Part A/D を使わない自己規律** を維持
- letter convention は PMD V4.8s と同一 (= Part A-F = FM 6ch)
- chip 物理仕様 (= ch 1/4 配線なし) + driver 不変条件 (= 無効ch 無音) の二重整合
- 楽曲は事実上 4 ch FM (= Part B/C/E/F) のみ運用

## 決定

**(C) 方針** を採用する。

具体規律:
- **driver**: YM2610B 仕様で 6 ch FM dispatch を実装する (= Part A-F 全部 cmdtbl /
  fmmain / 音色 set / fnumset / keyon / volset を持つ)。 chip ch 1/4 への
  register write は破綻しない (= PMD 不変条件を維持)。
- **楽曲 (`.m` / `.mn`)**: **Part A と Part D は使わない**。 mc compiler で空 part
  を出力するか、 part offset を 0 にして driver が rest 扱いする。 楽曲 MML で
  Part A/D に note を書いても driver は破綻せず無音になるが、 設計上の規律として
  楽曲側で使わない。
- **emulator / 実機**: YM2610 無印 (= NEOGEO 標準) で動作確認する。 YM2610B 実機
  でも互換動作するが、 開発の audio gate は YM2610 無印基準で行う。
- **mc compiler の警告**: Part A/D に note が書かれた場合、 compiler は **warning**
  を出す (= error にはしない、 driver 不変条件で破綻しないため)。

## 根拠

- chip 物理仕様: YM2610 無印 ch 1/4 は output 配線なし
- driver 不変条件: PMD V4.8s 流儀で無効 ch register write は破綻せず無音
- 二重整合: 物理仕様 + driver 不変条件の両方で「楽曲が間違って Part A/D を
  使っても破綻しない」 を保証
- letter convention 維持: PMD V4.8s 楽曲との互換性 (= driver で受けて静かに
  無視するだけで動く)
- 実機運用: YM2610B 実機入手困難なので無印基準で audio gate する

## 結果 / 影響

### 変更が必要な範囲

- **設計書**:
  - `phase2_driver_plan.md` §3 build flag 説明、 §7 audio gate Step 2 期待動作
  - `mn_binary_layout.md` §1 letter ch mapping に注記
  - `PMDNEO_DESIGN.md` §1 (位置付け) または §2 (Phase 計画) に方針反映
- **driver 実装**:
  - SubC-2/SubC-3 で FM 6 ch dispatch を実装、 ただし audio gate は chip ch
    2/3/5/6 (= Part B/C/E/F) で行う
  - `test_play_fm_c4` (SubC-1) 既に chip ch 2 で実装済 (= commit `23f1bd4`)
- **mc compiler / MML tooling**:
  - Part A/D に note 書込時の warning 機能 (= Phase 2 後段 or Phase 4 で実装)
  - 既存 PMD V4.8s 楽曲の取込時、 Part A/D は破棄 or rest 化する処理
- **楽曲 (Neo-Sisters)**:
  - Part B/C/E/F の 4 ch FM + Part G-I の SSG 3ch + Part J の ADPCM-B + Part L-Q
    の ADPCM-A 6ch、 計 14 ch で楽曲設計 (Part A/D の 2 ch を除く)

### 維持される性質

- PMD V4.8s 楽曲が PMDNEO driver に load しても破綻しない (= Part A/D が無音に
  なるだけで他 part は鳴る)
- letter convention は PMD V4.8s と同一
- driver は YM2610B 仕様で書くため、 将来 YM2610B 実機が入手できれば 6 ch 全部
  鳴る形に拡張可能 (= 楽曲側 self-規律を緩めるだけ)

## 参照

- memory `reference_opna_opnb_chip_comparison.md` — YM2610 無印 ch 1/4 仕様
- memory `project_pmd_invalid_channel_silence_invariant.md` — PMD 不変条件と
  chip 仕様の二重整合
- nullsound `nss-fm.s` L49-52 — `FM*_YM2610` 定義
- commit `23f1bd4` (2026-05-08) — SubC-1 audio gate pass で chip ch 2 発音実証
