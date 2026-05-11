# ADR-0013: PMDNEO 検証経路を 同 .M 2 経路比較 路線へ切替 (= PMDDotNET 改造 路線、 ADR-0005/0006 評価基準訂正)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0001 (= FM ch1/ch4 no use policy)、 ADR-0005 (= 音色検証 local DB)、 ADR-0006 (= compile.py 文法 + driver target chip)、 ADR-0009 (= driver PAN policy)、 ADR-0010 (= A/D voice init)、 ADR-0011 (= FM octave offset)

## 背景

PMDNEO の音色検証経路 (= driver 機能検証) は、 ADR-0005 で「PMDDotNET → pmdplay 経路の録音を『正』 とし、 PMDNEO 自前 driver via MAME 録音との合致率で判定」 と決めた。 この §H 表現は、 起票時の壁打ち上では「同 .M (= 同一 MD5 binary) を 2 経路で再生して driver の差のみを verdict 化する」 という越川意図を含んでいたが、 ADR 文面では明示されなかった。

その後 ADR-0006 起票で「PMDNEO compile.py が PMDDotNET MML 文法を読む」 + 「driver target chip 切替 (= ym2610 / ym2610b)」 が決まり、 実装は **PMDNEO 自前 compile.py + 自前 driver** 路線で進行した。 この路線は以下の構造を持つ:

```
.mml (= 同一 MML テキスト)
   │
   ├→ PMDDotNETConsole → .M → pmdplay (= お手本録音)
   │
   └→ PMDNEO compile.py → 独自 binary → PMDNEO 自前 driver via MAME (= 検証録音)
```

ADR-0006 §1-4 + ADR-0009/0010/0011 driver fix までは「2 経路で同 .mml を別 compiler に通す」 設計上問題ないかに見えたが、 ADR-0006 §5 段階 2 (= 2026-05-11、 commit f513f72) で 28 entry 一括 batch を実行したところ、 **全 28 entry FAIL + driver 側 rms / fft が voice parameter (TL/ML/alg/fbl) を全く反映していない** という結果が出た。

ここで深刻な問題が露呈した: 本路線では verdict FAIL の原因が **compile.py のバグなのか driver のバグなのか切り分けできない**。 出発点で 2 つの異なる compiler が異なる binary を生成しているため、 「driver は正しいが compile.py が voice 定義を正しく emit していない」 と「compile.py は正しいが driver の voice register 書込が壊れている」 の 2 つを区別できる手段がない。

越川本来の構想は次の通りだった:

```
.mml (= 同一 MML テキスト)
   │
   └→ 改造 PMDDotNETConsole (= OPNB 対応版) → .M (= 同一 MD5)
                                                    │
                                                    ├→ pmdplay (= OPNA 出力、 お手本録音)
                                                    │
                                                    └→ 改造 PMDDotNET driver in ROM via MAME (= OPNB 出力、 検証録音)
```

この路線では、 .M の MD5 一致を入口で確認することで「同一データ」 を保証し、 verdict 差は **driver の差のみ** に純化される。 不合致時は ADR-0005 §G「MATLAB 保険」 と §N「不合致時 plot 自動生成」 で原因を精査する。

ADR-0006 §5 段階 2 結果を契機に本来構想と現状実装のずれが明確化したため、 検証経路を本来構想に戻す方針を本 ADR で正式記録する。

## 決定

### D1. 検証経路を「同 .M 2 経路比較」 に切替

- **入力**: 同一 `.mml` テキスト
- **compile 経路**: **改造 PMDDotNETConsole** (= OPNB 対応版) **1 本** に統一
- **出力**: 同一 `.M` (= MD5 一致で出発点保証)
- **再生経路 A (= お手本)**: pmdplay (= OPNA 出力)
- **再生経路 B (= 検証)**: 改造 PMDDotNET driver in ROM via MAME (= OPNB 出力)
- **比較**: 経路 A 録音 vs 経路 B 録音、 L1/L3/L4 指標で verdict

### D2. PMDNEO の本体 driver 位置付け

PMDNEO の本体 driver は **PMDDotNET (= PMD V4.8s 系) を OPNB 対応に改造したもの** とする。 Phase 2 以降の driver 開発の出発点を「ゼロから新規 Z80 asm」 ではなく「既存 PMD V4.8s driver の OPNB 派生改造」 に変更する。

これに伴い、 ADR-0006 で立ち上げた「PMDNEO 自前 compile.py」 と「自前 driver (= standalone_test.s + 各種 fix)」 は **本路線上の中間成果 / 並行検討対象** として一旦凍結し、 別 ADR で位置付けを再定義する。

### D3. ADR-0005 §H 評価基準の訂正

ADR-0005 §H 現文面:

> 「PMDDotNET → pmdplay 経路の録音を『正』 とし、 PMDNEO 自前 driver via MAME 録音との合致率で判定」

を以下に訂正する:

> 「同一 .mml から **改造 PMDDotNETConsole** で生成した同一 .M を、 pmdplay (= OPNA 出力、 お手本) と MAME (= 改造 PMDDotNET driver via OPNB ROM、 検証) の 2 経路で再生録音し、 経路 A を『正』 として経路 B との合致率で判定。 入口で .M の MD5 一致を確認して『同一データ』 を保証」

### D4. ADR-0006 §A-H 路線の再評価

ADR-0006 で立ち上げた compile.py 拡張 (§A-H)、 driver target chip 切替 (§B)、 PART_COUNT 17→20 拡張、 marker 動的選定 (§F)、 build infra (§4) 等は、 本路線 (= 改造 PMDDotNET 路線) では **直接の本体実装ではなくなる**。

これらの ADR-0006 sprint 成果の扱いは別 ADR (= 想定 ADR-0014) で個別に判断する。 候補:
- (a) 全廃 (= revert、 wip- branch から develop merge せず)
- (b) 凍結 (= wip- branch に残し、 将来再評価)
- (c) 並行運用 (= 改造 PMDDotNET と並行で「PMDNEO 自前 driver」 path も維持)
- (d) 改造 PMDDotNET の中間検証ツールとして活用

本 ADR では「(a)-(d) の決定保留」 とのみ宣言し、 個別判断は ADR-0014 で行う。

### D5. ADR-0009/0010/0011 driver fix の扱い

これらは ADR-0006 路線の派生 driver fix (= PAN、 A/D voice init、 octave offset)。 D4 の扱い決定と同様に ADR-0014 で再評価する。 当面 wip-pmdmml-voice-parser branch に残す。

## 影響

### 検証精度の向上

比較指標 (= L1/L3/L4) が「driver の差のみ」 を測る純粋指標になる。 verdict FAIL 時の原因切り分けが「driver のどの機能が壊れているか」 に絞られ、 ADR-0005 §G/§N の MATLAB plot 精査が初めて有意義に機能する。

### compile 経路の 1 本化

`.mml` → `.M` の経路が改造 PMDDotNETConsole 1 本に統一される。 MD5 比較で「同一データ出発」 を機械的に保証可能 (= 過去 R2 sprint 偽完了パターンの根本予防)。

### 改造規模の見込み (= 未確定、 次 sprint で技術調査)

改造範囲の候補:
- **mc compiler (= PMDDotNET の .cs source)**: 既存 OPNA 出力経路から OPNB 出力経路を分岐、 build flag で切替
- **driver (= Z80 asm)**: 既存 PMD V4.8s driver (= vendor/pmd48s) の OPNB register 出力対応
- **.M format**: OPNB 用識別子 / ヘッダ追加 (= 互換性維持優先)
- **ROM 化経路**: 改造 driver + .M データを NEOGEO ROM に組み込み、 MAME 起動 + headless 録音まで chain 統合

技術調査は別 sprint (= 次 session 候補) で実施。

### 既存 ADR-0006 sprint commit 群の扱い

ADR-0006 §1-5 + ADR-0009/0010/0011 の 28 commit (= wip-pmdmml-voice-parser branch) は本路線では本体実装ではなくなる。 個別判断は ADR-0014 で実施 (= 全廃 / 凍結 / 並行 / 活用)。

### 既存 voice-test 28 entry reference の扱い

`src/tools/pmd-mml/reference/pmddotnet/voice-test/` の 28 entry MML + REFERENCE.md は、 本路線でも **そのまま使える** (= .mml は出発点として共通、 改造 PMDDotNETConsole で .M 生成 → 2 経路再生 が可能)。 ただし `data/` 配下の既存 blob (= ADR-0006 路線で取得した wav + mat 28 組) と runs.jsonl は本路線では **意味を失う** (= 出発点が異なる別経路の数値)。 これらの取扱は ADR-0014 と共に判断。

## 関連 memory

- `project_voice_db_design_agreed.md` (= ADR-0005 設計合意、 §H 表現の意図と現実のずれ)
- `project_adr_0006_aes_plus_policy.md` (= ADR-0006 本体、 PMDNEO 自前 compile.py 路線、 再評価対象)
- `project_adr_0006_3_marker_dynamic_host.md` (= §3 marker 動的選定、 再評価対象)
- `project_adr_0009_pan_policy.md` (= ADR-0009 PAN、 再評価対象)
- `project_adr_0010_ad_voice_init_and_mame_chip_mismatch.md` (= ADR-0010 A/D voice、 再評価対象)
- `project_adr_0011_octave_block_offset.md` (= ADR-0011 octave、 再評価対象)
- `project_mame_headless_recording_mode.md` (= MAME 録音 mode、 本路線でもそのまま使える)
- `project_compile_py_pmddotnet_compat_main.md` (= compile.py 互換性、 再評価対象)
- `project_pmd_voice_{tl,ar,dr,ml,alg,fbl}_verified.md` (= 6 件、 PMDDotNET 側 reference 検証結果、 本路線でもそのまま使える)
- `feedback_explain_in_plain_japanese_before_commit.md` (= 規律、 本 ADR 起票で平易な日本語報告を実践)

## 次 sprint 候補

1. **ADR-0014 起票**: ADR-0006 sprint 成果 (= compile.py + 自前 driver + ADR-0009/0010/0011) の位置付け再定義 (= 全廃 / 凍結 / 並行 / 活用)
2. **PMDDotNET 改造 技術調査 sprint**: mc compiler / driver / .M format / ROM 化 経路の改造規模見積もり、 既存 source 調査
3. **PMDDotNET 改造 着手 sprint**: 技術調査結果を元に最小経路から実装着手 (= まず OPNB 出力 driver、 MAME ROM 化、 .M 直接再生確認、 順次拡張)
