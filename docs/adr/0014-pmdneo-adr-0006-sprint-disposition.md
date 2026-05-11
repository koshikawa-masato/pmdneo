# ADR-0014: ADR-0006 sprint 成果の扱い決定 (= 5 カテゴリ別判断、 branch 凍結 + 部分再利用 + 履歴保存)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0005 (= 音色検証 local DB)、 ADR-0006 (= compile.py 文法 + driver target chip)、 ADR-0009 (= driver PAN policy)、 ADR-0010 (= A/D voice init)、 ADR-0011 (= FM octave offset)、 ADR-0013 (= 同 .M 2 経路比較 路線への切替)

## 背景

ADR-0013 (= 2026-05-11 起票) で PMDNEO 検証経路を「同 .M 2 経路比較 路線」 に切替えることを決定し、 既存 ADR-0006 sprint 成果 (= PMDNEO 自前 compile.py + 自前 driver) を「再評価対象」 とした。 ADR-0013 D4 では具体的扱いを「(a) 全廃 (b) 凍結 (c) 並行運用 (d) 活用」 から個別判断と宣言、 本 ADR で確定する。

ADR-0006 sprint 成果は性質の異なる成果が混在しているため、 5 カテゴリ (A-E) に分けて個別に扱いを決定する。

### 対象 commit (= wip-pmdmml-voice-parser branch、 2026-05-11 時点)

| commit | カテゴリ | 内容 |
|---|---|---|
| `f06105a` | E | ADR-0005 起票 |
| `73e8a3e` | A | ADR-0005 実装 (= measure.py + migrate_existing + marker_jitter) |
| `dffdb25` | A | .gitignore (= vendor/PMDDotNET + /data/) |
| `c92cbb3` | E | ADR-0006 起票 (= AES+ YM2610B 想定 + 規約 7 論点) |
| `96fc0ad` | E | ADR-0005 W superseded 注記 |
| `4966b05` | B | compile.py ADR-0006 §A/B/C 準拠拡張 |
| `1c74a1b` | B | ADR-0006 update 1 (= FM3Extend XYZ) + compile.py X/Y/Z 対応 |
| `f3bb43e` | C | ADR-0006 §2 driver 実装 (= PART_COUNT 17→20、 K/X/Y/Z mute) |
| `0f84bf8` | A | ADR-0006 §3 measure.py marker 動的選定 |
| `5dde476` | D | ADR-0006 §4 build infra `--chip` option |
| `21bfa23` | C, E | ADR-0009 起票 + 実装 (= driver PAN ハードコード Center 化) |
| `356d572` | C, E | ADR-0010 起票 + 実装 (= A/D voice init) |
| `65de35d` | E | ADR-0010 訂正 (= YM2610/B 関係訂正) |
| `b95a70f` | C, E | ADR-0011 起票 + 実装 (= fnumset_fm dec a) |
| `3e53654` | A | ADR-0006 §5 段階 1 (= measure.py MAME 経路実装) |
| `f513f72` | A | ADR-0006 §5 段階 2 (= align_and_match marker align + DC 除去 + RMS 正規化) |
| `8641854` | E | ADR-0013 起票 |

## 決定 (= 5 カテゴリ A-E)

### カテゴリ A. 比較ツール (= 再利用)

**対象**:
- `src/tools/pmd-mml/reference/measure.py` (= ADR-0005 実装 + §3 marker 動的選定 + §5 段階 1/2 MAME 経路 + align_and_match DC 除去版)
- `src/tools/pmd-mml/reference/migrate_existing.py` (= ADR-0005 一括 migration)
- `scripts/run-mame.sh` 内 `--headless --wavwrite` 経路 (= ADR-0005 F1 (a) 解決)
- MAME headless 録音 mode (= SDL_VIDEODRIVER=dummy + -video none + -sound coreaudio、 memory `project_mame_headless_recording_mode.md`)
- `.gitignore` の `vendor/PMDDotNET` + `/data/` (= dffdb25)

**扱い**: **再利用**

**理由**: 改造 PMDDotNET 路線でも「.mml → .M → 2 経路再生 → 録音 + 解析」 の後半 (= .M 以降の録音 + 解析) は共通。 measure.py の対象を「PMDNEO 自前 driver via MAME」 から「改造 PMDDotNET driver via MAME」 に切替えれば、 align_and_match (= DC 除去 + RMS 正規化版) はそのまま機能する。 marker 注入経路 (= dynamic host 選定) も .M format 互換であれば共通。

**移行作業**:
- measure.py の `render_mame()` 内 `--gamerom lastbld2` を改造 PMDDotNET driver の ROM に変更 (= 別 sprint)
- inject_marker() の voice 定義 / part letter convention は改造 PMDDotNET driver 側仕様で見直し (= 別 sprint)
- それ以外 (= analyze_full / detect_marker_peak / align_and_match) はそのまま流用

### カテゴリ B. compile.py 拡張 (= 凍結)

**対象**:
- `src/tools/pmd-mml/compile.py` の ADR-0006 §A/B/C/H 拡張 (= commit 4966b05、 1c74a1b)
  - TARGET_PARTS A-Q + X/Y/Z 全 20 part
  - PMDNEO_TARGET_CHIP env + WARN_PARTS_NOTE 機構
  - read_mml_source() の utf-8 → cp932 fallback
  - parse_voice_definitions() の comment 行許容
  - X/Y/Z FM3Extend warning

**扱い**: **凍結**

**理由**: 改造 PMDDotNET 路線では mc compiler (= PMDDotNETConsole) 1 本化で .mml → .M を担うため、 compile.py は本路線で **不要**。 ただし将来「並行運用 / 比較検証」 が必要になった場合 (= 例えば改造 PMDDotNET の出力を自前 compile.py と突き合わせて妥当性 verify) の用途で wip-pmdmml-voice-parser branch に残す。 develop / main merge はしない。

**移行作業**: なし (= 凍結のみ)

### カテゴリ C. 自前 driver (= 凍結)

**対象**:
- `src/driver/standalone_test.s` (= ADR-0006 §2 driver 実装 + ADR-0009/0010/0011 fix)
  - PART_COUNT 17→20、 K/X/Y/Z mute (= ADR-0006 §2)
  - PAN ハードコード Center 化 (= ADR-0009)
  - init_chip_ch2_voice の A/D voice setup (= ADR-0010)
  - fnumset_fm の dec a (= ADR-0011)
- driver 関連 song init 14→20 stream 拡張

**扱い**: **凍結**

**理由**: 改造 PMDDotNET driver が PMDNEO の本体 driver になる (= ADR-0013 D2)。 自前 driver は本路線で置換対象。 ただし将来「改造 PMDDotNET driver と機能比較」 や「特定機能を改造 PMDDotNET driver に移植」 する際の reference として wip- branch に残す。

ADR-0006 §5 段階 2 で露呈した「voice param 全部未反映」 問題 (= 28 entry 全 FAIL の真因) は、 本路線では **追求しない** (= 自前 driver の bug 修正に時間を使わず、 改造 PMDDotNET driver に集中)。

**移行作業**: なし (= 凍結のみ)

### カテゴリ D. build infra (= 部分再利用)

**対象**:
- `scripts/build-poc.sh` (= MML_INPUTS env、 ROM build chain)
- `scripts/run-mame.sh` の `--chip` option (= ADR-0006 §4、 commit 5dde476)
- `vendor/ngdevkit-examples/00-template/Makefile` の cpp define 経路 (= -DPMDNEO_TARGET_CHIP_YM2610B=1)
- 改造 MAME (= vendor/mame-fork/neogeo) の headless 録音経路
- ngdevkit 経路 (= NEOGEO ROM build chain)

**扱い**: **部分再利用**

**理由**: 改造 PMDDotNET driver も NEOGEO ROM に組み込んで MAME 上で再生する以上、 ROM build chain (= ngdevkit / MAME / `run-mame.sh --headless`) は共通利用。 `--chip` option も AES+ YM2610B 想定継承で必要。 ただし build 内容 (= driver source、 voice / song data 配置) は改造 PMDDotNET driver 用に書換える必要あり (= 別 sprint)。

**移行作業**:
- `scripts/build-poc.sh` の driver source 参照を「standalone_test.s」 から「改造 PMDDotNET driver」 に切替 (= 別 sprint)
- voice / song data の配置を .M format 互換に変更 (= 別 sprint)
- MAME 起動 + 録音経路はそのまま流用

### カテゴリ E. ADR 文書 (= 履歴保存 + superseded 注記)

**対象**: ADR-0005、 ADR-0006、 ADR-0009、 ADR-0010、 ADR-0011

**扱い**: **履歴保存 + superseded 注記**

**理由**: ADR は意思決定の歴史記録として価値があり、 削除すべきでない。 ただし ADR-0013 で路線変更があったため、 各 ADR の冒頭に「ADR-0013 で路線変更、 ADR-0014 で扱い確定」 の superseded 注記を追加する。

**移行作業** (= 別 commit で実施):
- ADR-0005 冒頭: 「ADR-0013 D3 で §H 評価基準訂正、 比較ツール (= measure.py / migrate_existing.py) は ADR-0014 カテゴリ A で再利用」
- ADR-0006 冒頭: 「ADR-0013 D4 で本路線は再評価対象化、 ADR-0014 で compile.py / 自前 driver / build infra を カテゴリ B/C/D 別判断」
- ADR-0009 冒頭: 「ADR-0014 カテゴリ C で凍結扱い」
- ADR-0010 冒頭: 「ADR-0014 カテゴリ C で凍結扱い」
- ADR-0011 冒頭: 「ADR-0014 カテゴリ C で凍結扱い」

## branch 戦略

### wip-pmdmml-voice-parser (= 既存)

- **そのまま残す** (= 凍結扱い、 履歴保存)
- 本 branch に新規 commit は **しない** (= 凍結対象 commit に追加変更を加えない)
- develop / main への merge は **しない**
- ADR-0014 + 各 ADR への superseded 注記追加 commit は **本 branch で行う** (= 路線変更記録は本 branch の最終 commit 群)

### wip-pmddotnet-opnb-extension (= 新規予定)

- **新規作成** (= develop 起点で切る)
- 改造 PMDDotNET 路線の sprint はこの branch で進める
- 命名は ADR-0013 D2 の「PMDDotNET 改造 = PMDNEO 本体 driver 化」 を反映

### develop / main

- 不変 (= 路線変更に伴う即時 merge はしない)
- 改造 PMDDotNET 路線の sprint が安定したら user 判断で develop merge

## 影響

### 即時影響

- ADR-0006 §5 段階 2 で露呈した「自前 driver の voice param 未反映」 問題は **本 ADR で追求対象外** と確定 (= 凍結扱い、 改造 PMDDotNET driver に集中)
- 28 entry batch で取得した `data/` 配下 blob (= 56 wav + 56 mat + runs.jsonl 29 entry) は本路線では意味を失う、 ただし `data/` は `.gitignore` で除外されているため repo には残らない (= 物理 dir は user 判断で削除可能)
- voice-test 28 entry MML reference (= `src/tools/pmd-mml/reference/pmddotnet/voice-test/`) は本路線でも再利用 (= 出発点共通)、 そのまま流用

### 次 sprint への影響

- PMDDotNET 改造 技術調査 sprint (= 想定 ADR-0015) で改造規模見積もり
- 改造 PMDDotNET driver 着手 sprint で本体実装開始
- 比較ツール (= カテゴリ A) は改造 PMDDotNET driver 完成後に対象切替で再利用

## 関連 memory

- `project_voice_db_design_agreed.md` (= ADR-0005 設計合意、 §H 訂正対象)
- `project_adr_0006_aes_plus_policy.md` (= ADR-0006 本体、 凍結対象 = カテゴリ B)
- `project_adr_0006_3_marker_dynamic_host.md` (= §3 marker 動的選定、 再利用対象 = カテゴリ A の一部)
- `project_adr_0009_pan_policy.md` (= ADR-0009 PAN、 凍結対象 = カテゴリ C)
- `project_adr_0010_ad_voice_init_and_mame_chip_mismatch.md` (= ADR-0010 A/D voice、 凍結対象 = カテゴリ C)
- `project_adr_0011_octave_block_offset.md` (= ADR-0011 octave、 凍結対象 = カテゴリ C)
- `project_mame_headless_recording_mode.md` (= MAME 録音 mode、 再利用 = カテゴリ A)
- `project_compile_py_pmddotnet_compat_main.md` (= compile.py 互換性、 凍結 = カテゴリ B)
- `project_build_mk_sed_preprocess_pitfall.md` (= BSD sed 罠、 build infra knowledge = カテゴリ D 参考)
- `project_pmd_voice_{tl,ar,dr,ml,alg,fbl}_verified.md` (= 6 件、 PMDDotNET 側 reference 検証結果、 改造 PMDDotNET 路線でもそのまま使える)
- `feedback_branch_strategy.md` (= branch 規律、 本 ADR の branch 戦略に整合)

## PMDPPZ 流儀の発見と改造規模見込み (= 2026-05-11 壁打ち追記)

本 ADR commit 直前の壁打ち (= 越川「私のイメージは PMDPPZ と同じくらいで PMDNEO」) を受けて `vendor/pmd48s/source/pmd48s/` を調査した結果、 PMD V4.8s 公式 driver の構造が明らかになった。 これにより ADR-0013 D2 の「改造 PMDDotNET 路線」 が具体的にどの程度の改造規模かが見積もれる。

### PMD V4.8s 公式 driver の構造

- **本体**: `PMD.ASM` 10864 行 (= 単一 file、 条件 assemble の塊)
- **wrapper file 群** (= 各 chip / 環境用、 15-17 行のみ):
  - `PMDB2.ASM` (15 行): `board2 equ 1` + `adpcm equ 1` + include PMD.ASM → OPNA + 内蔵 ADPCM-B 用
  - `PMDPPZ.ASM` (16 行): `board2 equ 1` + `adpcm equ 1` + `ppz equ 1` + include PMD.ASM → 上記 + PPZ8 用
  - `PMD86.ASM` (15 行): `board2 equ 1` + `pcm equ 1` + include PMD.ASM → サウンドボード 86 (= 86PCM) 用
  - `PMDVA.ASM` / `PMDVA1.ASM` / `PMDPPZE.ASM` 等の同様 wrapper

つまり PMD V4.8s 公式は **「PMD.ASM 1 本体 + flag による条件 assemble + 15-17 行の wrapper file」** 設計。

### PMD.ASM 内の条件 assemble 規模 (= 集計)

PMD.ASM 内の `if` / `ifdef` / `ifndef` directive 計 **203 件**。 内訳:

| flag | 出現数 | 用途 |
|---|---|---|
| `board2` | 90 | サウンドボード 2 (= OPNA) |
| `ppz` | 35 | **PPZ8 拡張** (= PMDPPZ 流儀の実体) |
| `va` | 22 | VA1 |
| `pcm` | 11 | 86PCM |
| `board2*adpcm` 等の組合せ | 計 45 | |

「PMDPPZ レベル」 の実体 = `ppz` 関連 35 件 + 関連組合せ十数件 = **約 50 件の `if` 分岐 + 16 行 wrapper file** で 1 つの新音源拡張 (= PPZ8) が完成している。

### PMDNEO の改造規模見込み

PMDPPZ 流儀に乗った場合の推定:

| 改造軸 | flag 候補 | 推定 `if` 分岐数 | 中身 |
|---|---|---|---|
| 環境移植 | `neogeo` | 30-50 件 | memory map / IRQ / I/O port / main CPU (= 68000) との command 通信路 / Z80 sound subsystem 規定 |
| chip 移植 | `opnb` | 50-100 件 | OPNB register address、 ADPCM-A 6 ch 経路追加、 ADPCM-B sample bank の OPNB 形式対応 |
| wrapper file | - | - | `PMDNEO.ASM` (= 15-20 行、 `neogeo equ 1` + `opnb equ 1` + include PMD.ASM) |

**合計推定**: PMD.ASM 内に約 **100-150 件の `if` 分岐**を散らばせる + wrapper file 1 つ = **数百〜千行規模の修正**。 元の 10864 行のうち修正対象は **約 5-10%**。

### この発見が ADR-0014 に与える意味

- **カテゴリ C (= 自前 driver 凍結)** の判断は妥当性が増した: 「PMD.ASM に flag 追加」 で済む経路があるなら、 standalone_test.s 全面書き直しを続ける意味は本路線では無い
- **カテゴリ A (= 比較ツール再利用)** の判断も妥当: PMDNEO.ASM が出力する .M format は PMDDotNET 既存 .M と互換 (= 同一 MD5 が成立)、 measure.py の align_and_match はそのまま使える
- **カテゴリ E (= ADR 履歴保存)** で残す ADR-0006 / 0009 / 0010 / 0011 は「PMD V4.8s の条件 assemble 構造を読まずに自前 driver 路線に進んだ戦略誤判断」 の記録として historical value を持つ
- **次 sprint (= ADR-0015 想定の技術調査)** の中身は具体化: 「PMD.ASM に neogeo + opnb flag 用条件 assemble を追加する設計」 「NEOGEO 環境依存層 (= 30-50 件) と OPNB chip 層 (= 50-100 件) の具体的箇所特定」

### 自前 driver で実装した機能の取扱 (= 再質問への答え)

ADR-0006 sprint で `standalone_test.s` に実装した機能 (= PART_COUNT 17→20、 K/X/Y/Z mute、 PAN Center 化、 A/D voice init、 octave offset) は本路線では **「やり直し」 ではなく「PMD V4.8s 公式 driver に元から正しく実装されている」** ため、 PMD.ASM 流用で自動的に解決される見込み。 自前 driver の bug (= ADR-0006 §5 段階 2 で露呈した voice param 未反映) は本路線で追求しない。

## 次 sprint 候補

1. **本 ADR-0014 commit + push** (= wip-pmdmml-voice-parser branch)
2. **各 ADR への superseded 注記追加 commit** (= 同 branch、 別 commit)
3. **次 session kickoff 書 update** (= `project_next_session_kickoff.md` を改造 PMDDotNET 路線 + PMDPPZ 流儀発見を反映して書換え)
4. **PMDDotNET 改造 技術調査 sprint** (= 想定 ADR-0015、 新 branch `wip-pmddotnet-opnb-extension` で開始、 PMD.ASM の neogeo + opnb flag 追加箇所特定 + NEOGEO 環境依存層調査)
