# ADR-0006: PMDNEO compile.py 文法 + driver target chip 切替 規約 (= AES+ YM2610B 想定 + ADR-0001 (C) 方針継承)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0001 (= FM ch1/ch4 no use policy)、 ADR-0005 (= 音色検証 local DB)、 memory `project_voice_db_design_agreed.md`、 memory `project_next_session_kickoff.md`、 memory `reference_opna_opnb_chip_comparison.md`

## 背景

ADR-0005 F1 前提条件として残っていた:

- **(b) PMDNEO compile.py が PMDDotNET MML format 非互換**: voice 定義 (= `@001 alg fbl` + 4 slot 行) や cmd alias 等の非対応
- **(c) marker A part が PMDNEO 側 TARGET_PARTS にない**: ADR-0005 W で marker 注入を A part 想定で設計したが、 PMDNEO compile.py の TARGET_PARTS から A が除外されている

両者を「PMDDotNET 拡張 sprint 待ち」 として保留していたが、 越川意向で AES+ (= 現代の同人 NEOGEO 互換 hardware) が **YM2610B 相当** で実装される将来想定 (= PMDNEO_DESIGN.md §1 ターゲット) を踏まえ、 ADR-0001 (C) 方針を継承しつつ「compile.py の MML 文法 + driver target chip 切替」 を本 ADR で規約化する。

ADR-0001 §「結果 / 影響 - 維持される性質」 既決事項:
> driver は YM2610B 仕様で書くため、 将来 YM2610B 実機が入手できれば 6 ch 全部鳴る形に拡張可能 (= 楽曲側 self-規律を緩めるだけ)

driver 層は元から 6ch dispatch を持つため、 「楽曲側 / compile.py 側の規律」 を build flag で切替えるだけで AES+ YM2610B 対応が完成する設計。

PMDPPZ 系 (= PMD ch 拡張版) の data area 仕様調査結果 (= 別 memory 起票予定):
- voice 定義 buffer = 8192 bytes 固定 (= 256 voice 上限) で ch 拡張時も不変
- 1 voice = 32 bytes (= PMDDotNET `mc.cs:3525`)
- part 表記文字 A-Q 範囲で letter convention 共通

これにより本 ADR の規約化に hardware / 既存 PMD source 由来の制約障害なし。

## 決定 (= A-H 8 論点)

### A. compile.py parser 文法範囲

PMDNEO compile.py の **MML parser は A-Q 全 17 part 表記を文法上受け入れる**:

| 文字 | 用途 | 文法 | driver 対応 |
|---|---|---|---|
| A | FM ch1 | 受ける | ym2610: mute、 ym2610b: 発音 |
| B | FM ch2 | 受ける | 全 mode で発音 |
| C | FM ch3 | 受ける | 全 mode で発音 |
| D | FM ch4 | 受ける | ym2610: mute、 ym2610b: 発音 |
| E | FM ch5 | 受ける | 全 mode で発音 |
| F | FM ch6 | 受ける | 全 mode で発音 |
| G/H/I | SSG ch1-3 | 受ける | 全 mode で発音 |
| J | ADPCM-B | 受ける | 全 mode で発音 (= 1ch) |
| K | Rhythm (= ADPCM-A drum) | 受ける | **driver 未実装** (= mute、 将来 sprint) |
| L-Q | ADPCM-A ch1-6 | 受ける | 全 mode で発音 |
| X/Y/Z | FM3Extend (= ch3 4-op individual mode の追加 voice) | 受ける | **driver 未実装** (= mute、 §H 参照) |

合計 **20 part** (= 17 + X/Y/Z)。 これにより AES+ YM2610B 対応 ROM 用 MML と公式 NEOGEO YM2610 用 MML を **同一 source で** 生成可能 (= build flag 切替のみで使い分け)。

PMD V4.8s 公式マニュアル §1-1-3 と §2-20「#FM3Extend」 規約を参照。

### B. driver target chip build flag

```
PMDNEO_TARGET_CHIP=ym2610   (default、 公式 NEOGEO YM2610 想定)
PMDNEO_TARGET_CHIP=ym2610b  (AES+ YM2610B 想定、 FM 6ch 全部発音)
```

build flow:
- `PMDNEO_TARGET_CHIP=ym2610` (default): A/D part は driver 側で mute (= register write はするが chip 物理仕様で output されない、 ADR-0001 既決)
- `PMDNEO_TARGET_CHIP=ym2610b`: A/D part も発音、 楽曲側 self-規律不要

実装経路:
- `scripts/build-poc.sh` / `scripts/run-mame.sh` に `--chip ym2610|ym2610b` option (= 既存 `PMDNEO_EXTRA_CFLAGS` 経由)
- `vendor/ngdevkit-examples/00-template/Makefile` で cpp define `-DPMDNEO_TARGET_CHIP_YM2610B=1` に変換
- driver `standalone_test.s` で `.if PMDNEO_TARGET_CHIP_YM2610B` 条件 assemble

### C. compile.py warning 機構

`PMDNEO_TARGET_CHIP=ym2610` mode で **A/D part に note** を書いた MML を compile すると compile.py は **warning** を出す (= error にしない、 driver 不変条件で破綻しないため)。

ADR-0001「mc compiler の警告」 規律を PMDNEO compile.py に継承。

`PMDNEO_TARGET_CHIP=ym2610b` mode では warning なし (= A/D 使用は意図通り)。

### D. voice 定義 buffer

PMDDotNET 同等の **256 voice 上限** を継承:
- 1 voice = 32 bytes (= 4 slot × 6 bytes + alg/fb 1 byte + name 7 bytes、 PMDDotNET `mc.cs:3525`)
- voice buffer = 8192 bytes 固定 (= PMDDotNET `voice_seg.cs:10`)
- PMDPPZ 系 (= ch 拡張版) でも buffer 拡張なしで成立 (= 調査結果)

PMDNEO 側 voice 定義 emit (= Phase 12a-5d で実装) は本規約に既に整合。

### E. voice 番号 99 = marker 用予約

voice 番号 99 (= `@099`) は **marker tone 用に運用予約**。 文法上は単なる voice 番号だが:
- PMDNEO MML 作曲規律: `@099` は marker 用に予約、 通常楽曲では使わない
- measure.py: marker 注入時に `@099` を動的定義 + 注入

PMDDotNET 自体に voice 99 の予約規約はないが (= 調査結果)、 PMDNEO 検証 sprint における運用判断として本 ADR で予約。

### F. marker 注入 host part = 動的選定 (= ADR-0005 W 破棄)

ADR-0005 W の **「marker は A part で注入」 規約を本 ADR で破棄**。 代わりに:

- measure.py が入力 MML を parse して **使われていない part を検出**
- 検出 part のうち 1 つを marker host に動的選定
- marker MML 行を生成 (= `<host_part> @099 r1 c1 r1` 等)、 既存 MML に注入

選定 priority (= 高 → 低):
1. **SSG 空 part** (= G/H/I): FM voice/SSG voice の音色性質差は大きいが、 marker 用 click tone は SSG でも可
2. **FM 空 part** (= ym2610b mode で A/D も候補、 ym2610 mode で B/C/E/F のうち空)
3. **やむを得ず ADPCM 系** (= L-Q、 ADPCM 用 voice 設計が要、 fallback)

検証対象 part が voice-test で B のみ使う場合、 G が marker host に選定される。 marker tone は SSG cuctom voice (= @099 の SSG 用音色定義) で出す。

### G. K (Rhythm) part の駆動

- **文法上**: compile.py は K part の note / cmd を byte stream に emit (= ADR-0001 letter convention 維持)
- **driver 側**: 当面 mute (= K cmd を見つけたら skip)
- K 用 ADPCM-A drum cmd 仕様は別 ADR (= ADR-0007 想定) で起票予定
- 将来 K 駆動 sprint 着手時、 本 ADR に「K 規約」 section 追記 or ADR-0007 で別途規定

### H. FM3Extend (= XYZ 固定運用)

PMD V4.8s 公式マニュアル §2-20:
```
#FM3Extend パート記号１[パート記号２[パート記号３]]
[記号] LMNOPQSTUVWXYZabcdefghijklmnopqrstuvwxyz のうちのいずれか
       FM音源3 のパートを、 指定したパート記号で拡張します。 最大３ｃｈ分。
[例] #FM3Extend XYZ
[結果] パート X, Y, Z を新規に拡張し、 FM音源3 パートとします。
```

PMD では `#FM3Extend` directive で動的 letter reassign が可能だが、 PMDNEO は **XYZ 固定** で運用:

- **PMDNEO MML 規約**: FM3Extend を使う MML は **必ず X/Y/Z** を指定 (= `#FM3Extend XYZ` か、 `#FM3Extend` 自体を省略して X/Y/Z を直接 part letter として使う)
- **理由**: PMDNEO 既存 ADPCM-A part (= L-Q) との letter 衝突回避、 文法解析を簡潔に保つ
- **PMDDotNET MML 由来 で `#FM3Extend ABC` 等の非標準 letter を使う MML**: compile.py は warning emit + XYZ にも mapping せず無視 (= 当面)

| 文字 | 用途 | driver 対応 |
|---|---|---|
| X | FM ch3 拡張 voice 1 (= op2 個別 fnum/vol) | driver 未実装、 mute |
| Y | FM ch3 拡張 voice 2 (= op3 個別) | driver 未実装、 mute |
| Z | FM ch3 拡張 voice 3 (= op4 個別) | driver 未実装、 mute |

driver 実装 (= ch3 4-op individual mode の register 制御 + per-op fnum / volume / keyon) は ADR-0006 範囲外、 別 sprint (= ADR-0008 想定) で起票予定。 当面 compile.py は X/Y/Z を文法受け入れ + warning + driver byte stream は emit するが driver 側で skip。

`scripts/run-mame.sh` の `--mask` option では既に X/Y/Z (= bit 11/12/13) 対応済 (= 将来 driver 実装時に有効化)。

## 実装 plan

1. **compile.py 拡張**:
   - `TARGET_PARTS` = `("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "X", "Y", "Z")` に拡張 (= 20 part)
   - `PART_LABELS` table に A/D/K/X/Y/Z を追加
   - `PMDNEO_TARGET_CHIP_YM2610B` cpp define / build env 連携 (= warning 抑止用)
   - A/D に note 書込時の warning emit (= default mode のみ)
   - K/X/Y/Z に note 書込時の warning emit (= 全 mode で driver 未実装)

2. **driver (standalone_test.s) 拡張**:
   - `part_workarea` を 14 → 17 (= +A/D/K) または 20 (= +A/D/K/X/Y/Z) に拡張
   - A/D part dispatch を確認 (= ADR-0001 既決で 6ch dispatch あるはず)
   - K/X/Y/Z part dispatch は mute path (= cmd 見ても skip)
   - `.if PMDNEO_TARGET_CHIP_YM2610B` 条件で A/D output 有効化 (= 詳細実装は driver sprint で)
   - X/Y/Z driver 実装 (= ch3 4-op individual mode) は別 sprint (= ADR-0008 想定)

3. **measure.py 拡張**:
   - marker host part 動的選定 algorithm 実装 (= F section の priority)
   - voice 99 注入: voice_seg に `@099` の voice 定義を動的追加 + 既存 MML に行注入

4. **build infrastructure**:
   - `scripts/build-poc.sh` / `scripts/run-mame.sh` に `--chip ym2610|ym2610b` option 追加
   - `vendor/ngdevkit-examples/00-template/Makefile` に `PMDNEO_TARGET_CHIP_YM2610B` 連携

5. **検証**:
   - voice-test 28 entry を新 compile.py で完走 (= existing reference を新 build で再現)
   - AES+ YM2610B mode test MML (= A/D に note を書いた MML) を build + MAME 再生 + 録音 (= ADR-0005 measure.py 経路)

## 残論点 / 後続 sprint

- **K (Rhythm) 駆動**: 別 ADR (= 想定 ADR-0007) で起票
- **X/Y/Z 駆動 (= FM3Extend)**: 別 ADR (= 想定 ADR-0008) で起票、 ch3 4-op individual mode の register 制御 / per-op fnum / volume / keyon 設計
- **#FM3Extend directive 動的 letter 対応**: 本 ADR で XYZ 固定運用に簡略化、 動的 letter reassign は将来必要時に検討
- **ADR-0001 update 要否**: 本 ADR で「ADR-0001 を継承 + 拡張」 と位置付け、 ADR-0001 自体は immutable に近い扱い (= update せず)
- **ADR-0005 W 修正**: ADR-0005 W の「A part 固定」 を本 ADR F で破棄、 ADR-0005 file 自体への注記追加は別 commit (= 「ADR-0006 で superseded」 と W section 末尾に追記)
- **vendor/PMDDotNET source 改修**: 本 ADR で**不要**と判断 (= PMDNEO compile.py 側完結、 PMDDotNET は reference oracle として参照のみ、 source 改修は当面なし)

## 改訂履歴

- **2026-05-11 起票**: 初版 (= 決定 A-G 7 論点)
- **2026-05-11 update 1**: §H FM3Extend (= XYZ 固定) 追加 (= 起票直後の重要欠落補完、 越川指摘)。 §A table に X/Y/Z 行追加、 §「実装 plan」 の TARGET_PARTS / part_workarea 拡張規模を update

## 参照

- ADR-0001 (C) 方針: 「楽曲側 A/D 不使用」 規律 を default mode で継承
- ADR-0005 W: 「A part marker 注入」 規約を本 ADR F で破棄 + 動的選定に変更
- ADR-0005 全般: F1 前提条件 (b)(c) を本 ADR で解決
- PMD V4.8s 公式マニュアル §1-1-3 / §2-20: part 記号と音源対応 / #FM3Extend 規約
- PMDDotNET `mc.cs:3525, 1350, 1384, 7982, 8587`: voice 定義 / part letter convention / X part FM3Extend 処理 根拠
- PMDDotNET `voice_seg.cs:10`: voice buffer 8192 bytes 上限
- memory `project_voice_db_design_agreed.md`: ADR-0005 設計合意、 本 ADR で部分 update
- memory `project_next_session_kickoff.md`: F1 前提 (b)(c) blocker を本 ADR で解決
