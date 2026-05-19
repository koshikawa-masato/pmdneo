# ADR-0044: 軸 F = PMDNEO MML compiler 拡張 sub-軸 設計 (= 改造 PMDDotNET 路線 + F-1/F-2/F-3 候補比較 + 採用案 (ii) 軸 F 全体 scope-out)

- 状態: **Accepted** (= 2026-05-19 31st session、 user 「Codex 確認後 GO」 委譲 → Codex layer 2 統合判断 session 019e3b50-8f23-... 147s response で **採用案 (ii) 軸 F 全体 scope-out 確定** = F-3 完了済認識 + F-1/F-2-A 将来 sprint defer + F-2-B 軸 B ADR-0008 候補譲渡、 ADR-0044 は軸 F 状態整理 ADR として消費、 軸 F 実質完成扱い、 ADR-0041 §決定 4-2 layer 2 統合判断機能実証 + Codex 5 step 計画 review approve 70s、 後段 F-2-A 実装は将来 sprint で別 ADR 起票時に再着手判断、 doc-only 移行 commit)
- Accepted 移行日: 2026-05-19
- 元 状態: ~~Draft~~ (= 2026-05-18 30th session 末 起票、 設計判断複数案 + user escalate 想定)

## 採用案決定 = 案 (ii) 軸 F 全体 scope-out (= 2026-05-19、 Codex layer 2 判断)

user 「Codex に確認を取ってその内容で GO」 委譲経路で Codex layer 2 統合判断 session `019e3b50-8f23-7803-af9e-903d6587f891` 147s response で確定。

### 採用根拠 (= Codex layer 2 + 主軸推奨一致)

1. **F-3 完了済**: chip target flag は ADR-0016 step 1 で Accepted 移行済 + 9 commit chain literal 実装済 (= sub-agent F vendor grep で発見)、 軸 F の中核 sub-軸 は既達成
2. **F-1 実需未発生**: voice buffer 256 voice 実用十分 (= memory `project_pmddotnet_chextend_data_area.md` 整合)、 拡張要求なし
3. **F-2-A 単独実装は観測価値低**: compiler 側 X/Y/Z 強制のみだと driver F-2-B 完成までユーザ視点観測差分なし
4. **F-2-B は軸 B 範囲**: ADR-0008 候補 (= driver ch3 4-op 実装) は Phase 2 FM/SSG driver フルスクラッチ軸 (= 軸 B) へ譲渡、 軸 F に取り込むと軸境界曖昧化 + ADR-0041 §決定 6 forbidden write set (= driver source) 違反 risk
5. **並走集中効率化**: active を軸 A + 軸 C に絞り、 主軸 context + Codex queue 軽減 (= ADR-0041 §決定 4-2 layer 2 統合判断趣旨と整合)
6. **ADR-0044 = 軸 F 状態整理 ADR として消費**: 番号 0044 を本 ADR で確定使用、 軸 F 整理目的達成

### 将来 sprint defer 軸

- **F-2-A**: 改造 PMDDotNET compiler の X/Y/Z FM3Extend 文法強制 (= mc.cs FM3Extend_set 改造 10-30 行、 XYZ 判定を partcheck より前に置く方針) → 将来 sprint で別 ADR (= ADR-0045+ 候補) 起票時に再着手判断
- **F-1**: voice buffer 拡張 (= 256 voice 超) → 実需発生時に再検討

### 軸 B 譲渡軸

- **F-2-B**: PMDNEO driver ch3 4-op FM3 拡張モード実装 → 軸 B (= Phase 2 FM/SSG driver フルスクラッチ、 ADR-0008 候補) の範囲、 軸 B 着手時に統合

## 後続 sprint 想定 (= 採用案 ii 確定後)

- 軸 F α 完了 (= 本 ADR 起票 + 採用案確定) で軸 F **完成扱い**
- 軸 F β/γ/δ は未着手のまま将来 defer
- 後段で F-2-A 再着手時は別 ADR (= ADR-0045+ 候補) 起票
- F-2-B は軸 B 内で扱う

---

## 元 Draft 内容 (= 2026-05-18 31st session 軸 F sub-agent F 起票時の literal、 採用案決定後も歴史保存)

- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0041 (= Claude Code 併走運用、 軸 0 母 ADR、 §決定 8 で本 ADR 番号 0044 予約 + §決定 6 sub-agent prompt 規律)
  - ADR-0006 (= compile.py 文法 + driver target chip 規約、 起点 ADR、 AES+ YM2610B 想定 + A-Q + X/Y/Z 全 20 part + FM3Extend XYZ 固定運用)
  - ADR-0013 (= 同 .M 2 経路比較 路線への切替、 自前 compile.py / driver 凍結 + 改造 PMDDotNET 路線採用)
  - ADR-0014 (= ADR-0006 sprint 成果のカテゴリ別判断、 カテゴリ B = 自前 compile.py 凍結 + カテゴリ E = ADR 文書履歴保存)
  - ADR-0015 (= 改造 PMDDotNET 技術調査、 軸 4 = mc compiler 改造範囲特定 + step 4-A〜4-E literal 化、 改造規模 185-360 行)
  - ADR-0016 (= 改造着手 sprint plan、 step 1 commit chain で /B option + opnb_flg + .MN 切替 + #PNEFile + opnb_check phase + L-Q part 6 ch 後方拡張領域 完全実装、 9 commit 達成)
- 関連 memory:
  - `project_compile_py_pmddotnet_compat_main.md` (= 自前 compile.py PMDDotNET 互換状況、 凍結資産)
  - `project_adr_0006_aes_plus_policy.md` (= AES+ YM2610B 想定 + FM3Extend 規約、 A-Q + X/Y/Z 全 20 part の起点 ADR)
  - `project_adr_0013_0014_path_switch.md` (= 路線切替経緯、 PMDPPZ 流儀発見)
  - `project_pmddotnet_compile_option_C_required.md` (= /C option 必須規律)
  - `project_pmddotnet_chextend_data_area.md` (= PMDPPZ + FM3Extend data area)
  - `feedback_explanation_style.md` (= 30th session 末確立 説明 style 10 規律)
  - `feedback_parallel_axis_orchestration.md` (= 並走運用基盤)
  - `feedback_subagent_codex_loop_with_escalation.md` (= sub-agent ↔ Codex loop + escalation)

## 背景

PMDNEO 開発の Phase 2-4 残作業として軸 F = MML compiler 拡張 (= ADR-0041 §決定 8 で番号 0044 予約) が並走候補となった。 ADR-0041 軸 0 chain (= α/β/γ/δ) と並走で sub-agent F context 調査が完了し (= dashboard `parallel-axes-dashboard.md` § 軸 F context 調査結果)、 着手判断の literal 化が必要となった。

### 軸 F の起点 ADR (= ADR-0006)

ADR-0006 §A で「PMDNEO compile.py の MML parser は A-Q 全 17 part 表記を文法上受け入れる」 + X/Y/Z FM3Extend 追加 = 全 20 part 規約を定めた。 driver target chip は §B で `PMDNEO_TARGET_CHIP=ym2610|ym2610b` build flag で切替。 §H で「X/Y/Z 固定運用」 = PMDDotNET の `#FM3Extend ABCDEF...` 任意 letter 指定を **PMDNEO は X/Y/Z 固定に簡略化** と決定。

ADR-0006 sprint 成果は ADR-0013/0014 で次の通り処理:
- 自前 compile.py 拡張 (= §A/B/C/H、 commit 4966b05 + 1c74a1b) → **カテゴリ B 凍結** (= `wip-pmdmml-voice-parser` branch 保管、 develop merge せず)
- 自前 driver `standalone_test.s` の §2 driver 実装 → **カテゴリ C 凍結** (= ただし ADR-0017 §決定 1 で「機能凍結はせず、 nullsound-free driver 本線として再評価」 と更新)
- ADR 文書 (= ADR-0006/0009/0010/0011) → **カテゴリ E 履歴保存 + superseded 注記**

つまり ADR-0006 の MML 文法拡張規約は「規律としては有効」 だが、 「実装経路は改造 PMDDotNET 路線に switch (= 自前 compile.py は凍結)」 という状況。

### 現役 MML compiler = PMDDotNETConsole

ADR-0013/0014/0015 で確立した改造 PMDDotNET 路線では `vendor/PMDDotNET/PMDDotNETConsole/` (= .NET CLI) + `vendor/PMDDotNET/PMDDotNETCompiler/` (= C# library 全 14 file 約 12000 行) が現役 main。 自前 compile.py は凍結 (= ADR-0014 §B)。

ADR-0015 §軸 4 step 4-E で mc compiler 改造箇所 = 185-360 行 規模、 改修対象 = `mml_seg.cs` + `mc.cs` + `m_seg.cs` 3 file と特定。 ADR-0016 sprint で step 1 commit chain 着手予定。

### ADR-0016 step 1 で既に実装済の改造内容 (= 重要発見、 sub-agent F context 調査では未捕捉だった精緻化)

sub-agent F context 調査 (= dashboard 軸 F context 調査結果) を受け、 主軸 (= 私) が `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` + `mml_seg.cs` + `m_seg.cs` を直接 grep + 読解した結果、 **ADR-0016 step 1 commit chain で次の改造が既に完了済**であることが判明:

| commit | 内容 |
|---|---|
| 25bde49 | vendor/PMDDotNET を git tracked に切替 (= ADR-0016 sprint 前提整備、 **implementation chain から除外** = chip target flag 機能 commit ではなく vendor track 化のみ) |
| 4b2e6b1 | step 1 commit 1 = `mml_seg.cs` + `m_seg.cs` に opnb 関連 field 追加 (= `opnb_flg` + `pne_filename` + `extended_data_adr` + `pne_filename_adr` 等) + usage `/B` 行追加 |
| d034eff | step 1 commit 2 = `/B` CLI option 認識 + `m_start` bit 2 + `.MN` 拡張子切替 |
| 2719544 | step 1 commit 3 = `partcheck` で L-Q part (= ADPCM-A 6 ch) 受付 + `/N` mode 時 警告 + skip |
| 01e347a | step 1 commit 4a = `adpcma_used` 判定 logic + 最優先制約 (= `.M` byte 単位互換) 達成 |
| 1a7e59e | step 1 commit 4b = Pass1 で `/B` mode 時の L-Q part 検出 + `adpcma_used = true` 発火経路 |
| 45eebaf | step 1 commit 4c = `#PNEFile` macro 認識経路 (= filename 格納のみ) |
| 0675b71 | step 1 commit 4c-fixup = `pnefile_set` で CR (0x0D) trim 追加 |
| 0b12f0a | step 1 commit 4e = cloop iteration + L-Q body + 後方拡張領域 + header 拡張 (= `adpcma_used` gate) |
| d653d62 | step 7 δ-fix = mc compiler `/B` path で `#PNEFile` surrounding quotes を strip (= 局所修正) |

合計 **F-3 implementation chain = 9 commit** (= 4b2e6b1 + d034eff + 2719544 + 01e347a + 1a7e59e + 45eebaf + 0675b71 + 0b12f0a + d653d62、 25bde49 は前提整備で除外)。 mc.cs 限定 git log (= 9 件) と F-3 full implementation chain (= 9 件、 mml_seg.cs/m_seg.cs field 追加 commit 4b2e6b1 含む) の区別は本表の commit 列で literal 化済。

### sub-軸 F 3 候補 (= sub-agent F context 調査結果 + 主軸補正)

sub-agent F context 調査で identified された 3 候補を主軸 (= 私) が現状実装 grep 結果と突き合わせて再評価:

#### F-1: voice buffer 拡張

**起点 ADR-0006 §D** で「PMDDotNET 同等の 256 voice 上限を継承」 「1 voice = 32 bytes」 「voice buffer = 8192 bytes 固定」 と決定。 PMDPPZ 系 (= ch 拡張版) でも buffer 拡張なしで成立 (= 調査結果)、 つまり **256 voice 上限は実用上十分**。

現状 = `voice_seg.cs:10` = `public byte[] voice_buf = new byte[8192];` 固定。

**評価**: 実需が見えない。 PMD V4.8s 公式マニュアル + PMDDotNET 既存運用で 256 voice 上限 (= 各楽曲 1 つ) は実用十分。 PMDNEO で 256 voice 上限を超える実需は現時点で **未発生**。 「将来要件のための抽象化」 = CLAUDE.md §中核原則「3 行の重複は早すぎる抽象化より良い」 違反候補。

**推奨**: scope-out (= 実需発生時に別 ADR で起票)。

#### F-2: X/Y/Z FM3Extend 文法移植 + driver 実装

**起点 ADR-0006 §H + §H table** で driver 未実装 (= mute) 確定、 「X/Y/Z 駆動 (= FM3Extend) は別 ADR (= 想定 ADR-0008) で起票」 と defer。 ADR-0008 は未起票。

現状 compiler 側 (= mc.cs):
- `FM3Extend_set` (= mc.cs:3174) は **既に実装済** (= PMDDotNET 既存機能)
- 任意 letter 指定可能 (= `fm3_partchr1/2/3` field、 mml_seg.cs:264-266)
- 既存 `partcheck` (= mc.cs:3492 想定) は A-K (= 既存 OPNA part) + L-Q (= `/B` mode 時 ADPCM-A 6 ch) + R (= Rhythm part) を「使用中」 判定して invalid letter 扱い (= `FM3Extend_set` 内 partcheck で reject 済)
- したがって PMDDotNET 既存 `partcheck` で通る letter は **A-K / L-Q / R 以外の自由 letter (= 例 `STUVWXYZ` 等)**、 つまり「現行 PMDDotNET で通るが PMDNEO XYZ 固定では拒否したい letter」 の代表例 = `STU` (= `#FM3Extend STU`)
- ADR-0006 §H 「X/Y/Z 固定運用」 規約は **PMDDotNET 側 compile に対しては未強制** (= 任意 letter 受付のまま、 ただし A-K/L-Q は partcheck で reject 済)

driver 側 (= ADR-0016 step 5+):
- ch3 4-op individual mode の register 制御 (= 0x27 register bit 6/7) + per-op fnum / volume / keyon 仕様
- 既に IR 軸 (= ADR-0034〜0040) で FM3Mode raw lowering 設計 + RawRegisterMaskWrite event 仕様 + spike + fixture が大幅進行 (= 26-30 session、 wip-ir-trunk に保管)
- driver 実装はまだ着手なし (= IR は intermediate format、 driver runtime 実 RMW 実行は別軸)

**評価**: compiler 側 = 軽量改造 (= X/Y/Z 固定運用 強制 + warning emit、 推定 10-30 行)。 driver 側 = ADR-0008 起票 + 大規模実装 (= ch3 4-op mode + per-op control、 推定 100-200 行)。 driver 軸は軸 B (= Phase 2 FM/SSG driver) に dependency (= 軸 F は完全独立軸前提、 driver 着手は軸 B sub-軸 として分離が妥当)。

**推奨**: compiler 側 X/Y/Z 規約強制 = 軸 F sub-sprint 候補。 driver 側 ch3 4-op 実装 = 軸 F 範囲外 (= 軸 B 候補 別 ADR)。

#### F-3: chip target flag (= /B + opnb_flg + .MN 切替)

**起点 ADR-0006 §B + §C** で「`PMDNEO_TARGET_CHIP=ym2610|ym2610b` build flag」 + 「warning 機構」 を規定。 ただし当時は **自前 compile.py 想定** = ADR-0014 §B カテゴリ B 凍結。

現役 PMDDotNETConsole では ADR-0015 軸 4 step 4-C で「CLI option `/B` + `mml_seg.opnb_flg`」 + 「同 MML 前半 bit-by-bit 一致保証」 を確定 → **ADR-0016 step 1 commit chain で完全実装済**:

| 改造範囲 | 状態 |
|---|---|
| `/B` CLI option 認識 (= `ReadOption()`) | **実装済** (= commit d034eff) |
| `m_start` bit 2 + `.MN` 拡張子切替 | **実装済** (= commit d034eff) |
| `partcheck` で L-Q 受付 + `/N` 時 警告 + skip | **実装済** (= commit 2719544) |
| `adpcma_used` 判定 logic + `.M` byte 互換 | **実装済** (= commit 01e347a) |
| Pass1 L-Q 検出 + `adpcma_used` 発火 | **実装済** (= commit 1a7e59e) |
| `#PNEFile` macro 認識 + filename 格納 | **実装済** (= commit 45eebaf + 0675b71 + d653d62) |
| `opnb_check` phase + L-Q body + 後方拡張領域出力 | **実装済** (= commit 0b12f0a) |

**評価**: F-3 は ADR-0016 step 1 で完全実装済 = **軸 F sub-sprint 候補から除外**。

## 決定

### 決定 1: F-1 (voice buffer 拡張) = scope-out

- 起点 ADR-0006 §D で 256 voice 上限は実用十分と確定済 (= PMDPPZ 系も拡張なし)
- 実需が未発生 = 「3 行の重複は早すぎる抽象化より良い」 (= CLAUDE.md §中核原則) 違反候補
- 将来実需発生時に別 ADR で起票 (= scope-out 列に追加)

### 決定 2: F-3 (chip target flag /B + opnb_flg + .MN 切替) = 完了済

- ADR-0016 step 1 commit chain (= 9 commit) で完全実装済
- 主軸 grep 結果で literal 確認 (= 上表)
- 軸 F sub-sprint 候補から除外

### 決定 3: F-2 (X/Y/Z FM3Extend 文法強制) = 軸 F sub-sprint **候補だが採否未定**

F-2 は 2 軸に分離可能:

#### F-2-A: compiler 側 X/Y/Z 固定運用 強制

- 現状 = PMDDotNET `FM3Extend_set` (= mc.cs:3174) は任意 letter 受付
- ADR-0006 §H で「PMDNEO は X/Y/Z 固定」 規約 + 「非標準 letter は compile.py が warning emit + XYZ にも mapping せず無視」 と決定 (= ただし当時は自前 compile.py 想定、 凍結)
- 改造 PMDDotNET 路線では本規約を `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` 内 `FM3Extend_set` 上で強制必要
- 改造規模 = 推定 10-30 行 (= `opnb_flg == 1` 時に non-X/Y/Z letter を warning + skip、 XYZ 判定を partcheck より前に置く実装方針必須 = `partcheck()` 内で L-Q 受付経路を持つため XYZ 以外の letter を partcheck に渡す前に reject、 `partcheck()` 副作用 (= `adpcma_used` set) を回避)
- driver 側 dependency なし (= compiler の意味論のみ)

#### F-2-B: driver 側 ch3 4-op individual mode 実装 (= ADR-0008 候補)

- 起点 ADR-0006 §H で defer (= ADR-0008 想定)
- driver runtime 実装 = ch3 4-op individual mode (= 0x27 register bit 6/7 + per-op fnum + per-op vol + per-op keyon)
- IR 軸 (= ADR-0034〜0040) FM3Mode raw lowering + RawRegisterMaskWrite event 仕様 で intermediate format 設計済、 driver runtime 実装は別軸
- 推定 100-200 行
- **軸 F (= MML compiler 拡張) 範囲外** = 軸 B (= Phase 2 FM/SSG driver) の sub-軸候補 別 ADR で扱う

### 決定 4: 軸 F sub-sprint 採否 = **設計判断複数案、 user 判断要請** (= escalate `design_judgment_needed`)

F-1 = scope-out / F-3 = 完了済 / F-2-A = 候補 / F-2-B = 範囲外 と整理した結果、 **軸 F sub-sprint として残るのは F-2-A のみ** (= compiler 側 X/Y/Z 固定運用 強制)。

ただし F-2-A の採否は次のトレードオフを含む設計判断:

#### 案 (i): F-2-A 軸 F sub-sprint α 着手 (= compiler 側 X/Y/Z 強制)

- pros:
  - ADR-0006 §H 規約の literal 実装完成 (= 規律と実装の整合性)
  - PMDDotNET 流儀の任意 letter 指定 (= `#FM3Extend STU` 等、 既存 `partcheck` を通る letter) を PMDNEO 流儀の X/Y/Z 固定に縮退、 文法解析を簡潔に保つ
  - 改造規模 軽量 (= 10-30 行)、 1 commit で完結
- cons:
  - 実装後に driver 側 F-2-B が起票されない限り「文法は受け付けるが driver は mute」 状態継続 = ユーザ視点では F-2-B 完成まで観測差分なし
  - PMDDotNET 既存運用 (= 任意 letter) との互換性低下
  - 単独で audio gate 観測対象なし (= machine verify のみ、 byte-identical 経路で reject 0 件確認程度)

#### 案 (ii): 軸 F 全体 scope-out (= 軸 F sub-sprint なし、 ADR-0044 で「F-3 完了 + F-1/F-2-A defer」 確定)

- pros:
  - 軸 F context 調査で identified された残作業がない (= F-3 完成済、 F-1/F-2-A 実需なし)
  - 並走候補から軸 F を外して軸 A (= ADR-0033 β sample provenance) + 軸 C (= ADPCM-B) 2 軸並走に集中 = 主軸 context + Codex queue 軽減
  - F-2-A 単独実装は driver 側 F-2-B (= 軸 B 候補) と組み合わせないと観測価値が低い (= cons 1 と同じ)
- cons:
  - ADR-0006 §H 規約の literal 強制は将来 sprint に defer (= 規律と実装の整合性は遅延)
  - ADR-0041 §決定 8 で予約した ADR 番号 0044 が「F-3 完了 + 残候補 defer」 確定 ADR として消費 (= 0044 ADR 番号は軸 F 専用)

#### 案 (iii): F-2-A + F-2-B (= driver 側 ch3 4-op) を同 軸 F sub-sprint に統合

- pros:
  - F-2-A 単独の観測価値の低さを F-2-B 完成で解消、 audio gate 観測対象が成立
  - ADR-0008 候補と統合 = ADR-0044 が軸 F + ADR-0008 兼用、 ADR 番号節約
- cons:
  - 軸 F (= MML compiler 拡張) と軸 B (= driver Phase 2) の境界を曖昧化 = ADR-0041 §決定 3 「1 軸 1 branch 集約」 規律違反候補
  - driver 触接面決定 (= ADR-0041 §決定 6 forbidden write set で「driver / runtime source」 = 軸 F sub-agent 触接禁止) と矛盾
  - 改造規模 = 推定 110-230 行、 1 軸内 sub-sprint chain 長期化
  - 軸 B sub-軸として別 ADR (= 0045+ 予約候補) で扱うほうが規律整合

### 決定 5: 採用案 = **case (ii) 軸 F 全体 scope-out 推奨、 ただし user 判断**

主軸 (= 私) 推奨は **案 (ii) 軸 F 全体 scope-out**。 理由:

1. F-3 (= chip target flag /B + opnb_flg + .MN 切替) は ADR-0016 step 1 で完了済 = **軸 F は実質的に既に完成**
2. F-1 (= voice buffer 拡張) は実需未発生 = scope-out
3. F-2-A 単独実装は driver 側 F-2-B 完成までユーザ視点観測差分なし = 着手の即時価値が低い
4. F-2-B (= driver 側) は軸 B (= Phase 2 FM/SSG driver) sub-軸として別 ADR (= 0045+ 候補) で扱うのが規律整合
5. 並走候補から軸 F を外して軸 A + 軸 C 2 軸並走に集中 = ADR-0041 並走運用の context + Codex queue 軽減
6. ADR-0044 = 「軸 F 状態整理 ADR」 (= F-3 完了済 literal 化 + F-1/F-2-A defer 確定 + F-2-B 軸 B 譲渡) として ADR 番号 0044 を消費

ただし本決定は user 判断 scope (= 設計トレードオフを含む変更、 ADR-0041 §決定 5 = escalate `design_judgment_needed`)。 user の判断結果次第で:
- 案 (i) 採用 → F-2-A 軸 F sub-sprint α 起票 + β commit chain 実装
- 案 (ii) 採用 → 本 ADR-0044 で軸 F 状態整理 + Accepted 移行 + 軸 F 並走候補から除外
- 案 (iii) 採用 → F-2-A + F-2-B 統合 sub-sprint 起票 (= 改造範囲 110-230 行、 driver 触接面決定が前提)

## scope-out

- driver / runtime source touch (= ADR-0041 §決定 6 forbidden write set、 本 ADR doc-only)
- vendor 配下 touch (= 同上、 本 ADR は調査結果 literal 化のみ vendor 不可触)
- F-1 voice buffer 拡張 (= 決定 1、 256 voice 上限 実用十分、 実需発生時に別 ADR)
- F-2-B driver 側 ch3 4-op individual mode 実装 (= 決定 3、 軸 B sub-軸 候補 別 ADR、 0045+ 予約)
- IR 軸 (= ADR-0034〜0040) FM3Mode raw lowering / RawRegisterMaskWrite spike / fixture (= wip-ir-trunk 保管、 軸 F touch なし)
- main / wip-pmddotnet-opnb-extension 直接 commit (= 全 commit は wip-axis-f-mml-extension 経由)
- MEMORY.md / CLAUDE.md 直接 edit (= ADR-0041 §決定 9 memory write 集約、 主軸経由のみ)
- 既存 ADR / handoff の リファクタ・短縮・人間向け文体書き換え (= memory `feedback_doc_governance_two_systems.md` 規律踏襲)
- 人間向け公開 docs を ground truth 扱い (= 同上)
- 3 重 zero-trust review の スキップ (= ADR-0041 §決定 4)
- automated CI 化 (= 別軸)
- aesthetic / audio audition (= 軸 F は machine verify 軸、 audition gate 起動なし)

## 後続 sprint 想定 (= user 判断後)

### 案 (i) 採用時の sub-sprint chain

| commit | 内容 |
|---|---|
| α (= 本 commit、 本 ADR Draft) | ADR-0044 起票 + user escalate |
| β (= user 案 (i) 採用後) | mc.cs `FM3Extend_set` 改造 (= `opnb_flg == 1` 時に non-X/Y/Z letter を warning + skip、 推定 10-30 行) + 既存 `.M` byte-identical 維持 verify |
| γ | fixture 追加 (= `vendor/PMDDotNET` 配下を変えず、 軸 F 専用 fixture を `docs/design/<軸 F>/` 配下、 `#FM3Extend XYZ` positive + `#FM3Extend STU` negative 各 1 件 = STU は既存 `partcheck` を通る letter、 PMDNEO XYZ 固定で reject 対象の代表例) |
| δ | PR 作成 + 本拠地 `wip-pmddotnet-opnb-extension` merge |

### 案 (ii) 採用時の sub-sprint chain

| commit | 内容 |
|---|---|
| α (= 本 commit、 本 ADR Draft) | ADR-0044 起票 + user escalate |
| β (= user 案 (ii) 採用後) | ADR-0044 Accepted 移行 + dashboard 軸 F 「scope-out (= F-3 完了 + F-1/F-2-A defer)」 literal 化 |
| γ | PR 作成 + 本拠地 merge |

### 案 (iii) 採用時の sub-sprint chain

| commit | 内容 |
|---|---|
| α (= 本 commit、 本 ADR Draft) | ADR-0044 起票 + user escalate |
| β (= user 案 (iii) 採用後) | F-2-A compiler 改造 (= 案 (i) β 同等) |
| γ | F-2-B driver 側 ch3 4-op individual mode 実装 (= ADR-0008 候補と統合、 driver 触接面 = `src/driver/` 配下 wip-axis-f-mml-extension 内で扱う、 ただし ADR-0041 §決定 6 forbidden write set 例外として user 明示許可後) |
| δ | fixture 追加 + audio gate user audition + PR 作成 + 本拠地 merge |

軸 F Accepted 移行は user 案決定後 + 該当 sub-sprint chain 完走 + audio gate (= 案 (i) は machine verify のみ、 案 (iii) は driver 動作確認) + user 最終確認時。

## verify 計画

### A. ADR 整合性

- ADR-0006 §A/D/H 規約 (= 全 20 part + 256 voice 上限 + X/Y/Z 固定運用) と矛盾なし
- ADR-0013/0014 路線切替 (= 自前 compile.py 凍結 + 改造 PMDDotNET 路線) と整合
- ADR-0015 §軸 4 mc compiler 改造範囲特定 + ADR-0016 step 1 実装済 commit chain と literal 整合 (= 主軸 grep 結果で verify)
- ADR-0041 §決定 1-10 + §決定 4-3 fallback regime + §決定 6 sub-agent prompt 規律 と整合
- CLAUDE.md §中核原則 (= 記憶は AI に + 設計書ファースト + scope-out 規律) と整合
- memory `feedback_doc_governance_two_systems.md` 規律 (= AI 協働用 ADR を ground truth、 人間向け公開 docs を派生物) 継承

### B. 既存 chain 不変

- wip-pmddotnet-opnb-extension HEAD 不変 (= 本 ADR は wip-axis-f-mml-extension 内 commit、 本拠地は merge 待ち)
- wip-ir-trunk (= IR 軸保管) touch なし
- main 保護維持
- PR #3/#4/#5/#14/#15 merged + PR #6-#13 CLOSED + main 保護維持 完全不変
- vendor 配下 (= `vendor/PMDDotNET/`) 不可触 (= 本 ADR は調査結果 literal 化のみ)

### C. 後続 sprint verify gate (= 案 (i)/(iii) 採用時、 本 ADR では計画明示のみ)

- 案 (i) β: mc.cs 改造後の既存 MML compile byte-identical verify (= ADR-0006 §H 規約強制が既存出力に影響しないこと確認、 `#FM3Extend XYZ` MML は warning なし、 `#FM3Extend STU` MML は warning + skip = STU は既存 `partcheck` を通る letter、 PMDNEO XYZ 固定で reject 対象の代表例)
- 案 (i) γ: positive/negative fixture 各 1 件 verify (= positive .M output 既存と byte-identical、 negative warning + skip 出力確認、 また `partcheck` 副作用 = `adpcma_used` set がないことを Pass1/Pass2 dispatch 経路で確認)
- 案 (iii) γ: driver 側 ch3 4-op register write trace (= MAME headless + ymfm-trace、 RawRegisterMaskWrite event 仕様準拠 verify)
- 案 (iii) δ: audio gate user audition (= MAME 試聴、 ch3 4-op individual mode の audible 動作確認、 ADR-0041 §決定 5 audit_gate escalation)

## Annex

### A-1. 30th session 末 user 並走判断 + 軸 F 軸予約経緯

| user 発言 / 判断 | 結果 |
|---|---|
| 「Claude Code を正式に併走させたい」 | ADR-0041 起票 + 軸 0/A/C/F 4 軸予約 |
| dashboard 軸 F context 調査 sub-agent 起動 | sub-agent F return = 「現役 PMDDotNETConsole + sub-軸 F-1/F-2/F-3 候補 + 自前 compile.py 凍結 (= ADR-0014 §B)」 |
| 本 ADR-0044 起票 task | 主軸 grep 補正で「F-3 = ADR-0016 step 1 で完了済」 発見 → 案 (i)/(ii)/(iii) escalate 想定で起票 |

### A-2. sub-agent F context 調査 literal 引用 (= dashboard 軸 F context 調査結果)

dashboard 軸別進捗 details § 軸 F (= MML compiler 拡張) context 調査結果:

> 現役 PMDDotNETConsole (= .mml→.M 1 本化) + sub-軸 F-1/F-2/F-3 候補 + 自前 compile.py 凍結 (= ADR-0014 §B)

主軸補正:
- F-3 (= chip target flag /B + opnb_flg + .MN 切替) は **ADR-0016 step 1 commit chain (= 9 commit、 d653d62 で δ-fix 完了) で完全実装済**
- F-1 (= voice buffer 拡張) は ADR-0006 §D で 256 voice 上限実用十分、 PMDPPZ 系も拡張なし、 実需未発生
- F-2 (= X/Y/Z FM3Extend 文法移植) は compiler 側 (= F-2-A) と driver 側 (= F-2-B) に分離可能、 driver 側は軸 B 候補

### A-3. ADR-0016 step 1 commit chain literal (= 主軸 grep 結果)

`git log --oneline -- vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` 結果 (= 古→新):

```
25bde49 chore(vendor): vendor/PMDDotNET を git tracked に切替 — ADR-0016 sprint 前提整備
d034eff feat(mc): step 1 commit 2 — /B option 認識 + m_start bit 2 + .MN 拡張子切替
2719544 feat(mc): step 1 commit 3 — partcheck で L-Q 受付 + /N 時 警告 skip
01e347a feat(mc): step 1 commit 4a — ADPCM-A 使用判定 logic + 最優先制約 (.M 維持) 達成
1a7e59e feat(mc): step 1 commit 4b — Pass1 で /B 時の L-Q 検出 + adpcma_used 発火経路完成
45eebaf feat(mc): step 1 commit 4c — #PNEFile macro 認識経路追加 (filename 格納のみ、 byte layout 影響なし)
0675b71 fix(mc): step 1 commit 4c-fixup — pnefile_set で CR (0x0D) trim 追加
0b12f0a feat(mc): step 1 commit 4e — cloop iteration + L-Q body + 後方拡張領域 + header 拡張 一括 (adpcma_used gate)
d653d62 fix(compiler): step 7 δ-fix — mc compiler /B path で #PNEFile surrounding quotes を strip (= 局所修正)
```

### A-4. 軸 F 完了済確認 literal grep (= 主軸 zero-trust verify、 ADR-0041 §決定 4 3 重 zero-trust review 規律踏襲)

mml_seg.cs:
- `public int opnb_flg = 0;//b PMDNEO YM2610/B mode (CLI /B option)` (= L229)
- `public bool warned_LQ = false;//b L-Q part /N mode 警告抑制 flag` (= L230)
- `public bool adpcma_used = false;//b ADPCM-A 使用判定 (= /B mode で L-Q 受付 or #PNEFile 指定時 true)` (= L231)
- `public string pne_filename = null;//b PMDNEO .PNE file 指定 (#PNEFile)` (= L339)
- `public int opnb_lq_init = 0;` 等 L-Q iteration state (= L341-346)
- `public bool[] opnb_part_used = new bool[6];//b L-Q part の MML 使用判定 (Pass1 で立てる)` (= L346)

m_seg.cs:
- `public int extended_data_adr = 0;//w PMDNEO 後方拡張領域先頭アドレス` (= L13)
- `public int pne_filename_adr = 0;//w PMDNEO .PNE file 名アドレス` (= L14)

mc.cs (= 主要箇所):
- `enmPass2JumpTable.opnb_check` enum 値 + dispatch (= L441-505)
- `mml_seg.opnb_flg = 1;` set 経路 (= L2391、 `/B` CLI option 認識)
- `private enmPass2JumpTable opnb_check()` body (= L1486、 L-Q iteration + 後方拡張領域出力)
- `FM3Extend_set` (= L3174、 PMDDotNET 既存機能、 任意 letter 受付)

### A-5. 改造 PMDDotNET 路線 触接面決定 (= ADR-0041 §決定 6 forbidden write set との関係)

ADR-0041 §決定 6 forbidden write set で「vendor 配下 (= `vendor/PMDDotNET/` 等、 完全不可触)」 と規定。 ただし ADR-0013/0014/0015/0016 路線で `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` 等は **既に改造実装中** (= ADR-0016 step 1 commit chain で 9 commit)。 これは矛盾ではなく:

- ADR-0041 規律 = sub-agent F が **触接禁止** (= sub-agent 経由 ADR-0044 起票 段階の vendor 不可触)
- ADR-0016 路線 = 主軸 (= 私) が user 明示許可後に主軸介入で改造実行 (= ADR-0041 §決定 5 (c) 主軸が直接介入実装)

つまり vendor 改造は **主軸経由のみ** で sub-agent 経由ではない。 本 ADR-0044 後続 sprint chain も:
- 案 (i) β 採用時 → 主軸介入で mc.cs 改造 (= sub-agent F に委譲しない)
- 案 (iii) γ 採用時 → 主軸介入で driver 改造 (= `src/driver/` 配下、 vendor ではない)

sub-agent F は **doc-only ADR 起票 (= 本 ADR-0044 α) のみ** が範囲 = vendor / driver / runtime source 触接禁止。 後続 β 以降は主軸介入。

### A-6. escalate 理由 = `design_judgment_needed` (= ADR-0041 §決定 5)

本 ADR § 決定 4 で複数案 (i)/(ii)/(iii) を literal 化、 主軸推奨 = 案 (ii) 全体 scope-out。 ただしトレードオフ含む設計判断 = user 判断 scope。 ADR-0041 §決定 5 escalation 6 種のうち `design_judgment_needed` 該当 = user に判断仰ぐ。

escalate 内容:
- 状況: F-1 = scope-out 推奨 / F-3 = 完了済 / F-2-A = 候補 / F-2-B = 範囲外。 軸 F sub-sprint として残るのは F-2-A のみ、 採否未定
- 提案: 案 (i)/(ii)/(iii) 3 案、 主軸推奨 = 案 (ii) 全体 scope-out (= 6 根拠列挙)
- user 判断必要: yes

### A-7. 後続軸候補 (= ADR 0045+ 予約候補) との関係

dashboard § 後続軸 候補:

- 軸 B (= Phase 2 FM/SSG driver フルスクラッチ、 scope 最大、 軸 F MML 文法拡張に依存) → ADR 0045 候補
- 軸 D (= WebApp 最小骨格、 backend で軸 C/F に依存) → ADR 0046 候補
- 軸 E (= IPL / プレイヤー V1) → ADR 0047 候補

F-2-B (= driver 側 ch3 4-op individual mode) は **軸 B sub-軸** に該当 = ADR 0045 候補 (= 軸 B 母 ADR) または 0045+ 別番号 (= 軸 B sub-軸 ADR) で扱う。 本 ADR-0044 は **軸 F (= MML compiler 拡張) 専用** = F-2-B は軸 F 範囲外確定。

軸 F が案 (ii) で全体 scope-out なら、 軸 F は dashboard 後続軸候補に降格 (= ADR 0048+ 「軸 F 文法拡張 復活軸 候補」 として実需発生時に再起票)、 軸 B 起動が前進候補。

## 改訂履歴

- **2026-05-18 起票** (= 軸 F sub-agent 経由、 wip-axis-f-mml-extension branch、 ADR-0041 §決定 8 番号 0044 予約 + §決定 6 sub-agent prompt 規律): 初版 (= 決定 1-5 + escalate `design_judgment_needed` 想定 + Annex A-1 〜 A-7)

## 参照

- ADR-0006 §A/B/C/D/H (= MML 文法 + driver chip target + voice buffer + FM3Extend XYZ 規約、 起点 ADR)
- ADR-0013 D2/D4 (= 改造 PMDDotNET 路線採用 + 自前 compile.py 凍結)
- ADR-0014 §B/§C/§E (= ADR-0006 sprint 成果カテゴリ別判断、 カテゴリ B/C 凍結 + E 履歴保存)
- ADR-0015 軸 4 step 4-A 〜 4-E (= mc compiler 改造範囲特定、 改造規模 185-360 行)
- ADR-0016 step 1 commit chain (= 9 commit、 /B option + opnb_flg + .MN + #PNEFile + opnb_check phase + L-Q 後方拡張領域 完全実装、 主軸 grep 結果 A-3 literal)
- ADR-0041 §決定 1-10 + §決定 4-3 fallback regime + §決定 6 sub-agent prompt 規律 (= 軸 0 母 ADR、 並走運用基盤)
- dashboard `docs/parallel-axes-dashboard.md` (= 軸予約表 + 軸 F context 調査結果 + ADR 番号予約簿)
- memory `feedback_doc_governance_two_systems.md` (= AI 協働用 ADR ground truth + 人間向け公開 docs 派生)
- memory `feedback_parallel_axis_orchestration.md` (= 並走運用基盤)
- memory `feedback_subagent_codex_loop_with_escalation.md` (= sub-agent ↔ Codex loop + escalation 6 種)
- memory `feedback_codex_review_autonomous_no_user_judgment` (= Codex 自律壁打ち継承元)
- memory `feedback_codex_implementation_review.md` (= 3 重 zero-trust review 規律源)
