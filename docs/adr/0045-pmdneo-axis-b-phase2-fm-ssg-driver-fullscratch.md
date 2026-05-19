# ADR-0045: PMDNEO 軸 B = Phase 2 FM/SSG driver フルスクラッチ + F-2-B 譲渡軸統合 設計 (= 軸 B 起票、 5 sub-sprint 構成、 doc-only filing)

- 状態: **Draft** (= 2026-05-19 37th session、 ADR-0044 §F-2-B 譲渡軸 literal 後続 ADR、 軸 B 新規軸 起票、 Codex layer 2 候補整理 round 1 approve = 主軸推奨 4 候補比較 + 候補 α 採用一致、 本 ADR 起票実 commit pre-review は別 round)
- 起票日: 2026-05-19
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 範囲明示 (= ADR-0044 との境界、 Codex nice-to-have 1 件反映):
  - 本 ADR は **軸 F (= ADR-0044) §F-2-B 譲渡軸 (= driver ch3 4-op FM3 拡張) を含む** が、 **F-2-A defer 解除ではない**
  - F-2-A (= 改造 PMDDotNET compiler X/Y/Z 強制) は ADR-0044 §決定 5 で将来 sprint defer 確定、 本 ADR で扱わない
  - ADR-0044 Accepted 状態は破壊しない (= 軸 F 完成扱い継続)
- 関連 ADR:
  - **ADR-0044** (= 軸 F MML compiler 拡張 Accepted、 §決定 5 採用案 (ii) 軸 F 全体 scope-out + F-2-A defer + F-2-B 軸 B 譲渡 literal、 本 ADR の母 ADR + 譲渡元)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 default 永続化、 §決定 7 dashboard 一元管理、 §決定 8 ADR 番号予約、 §決定 9 memory write 集約)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給 Draft、 ε partial complete + ζ 未着手、 本 ADR は軸 G state 不可触)
  - ADR-0043 (= 軸 C ADPCM-B 1ch runtime-managed architecture Accepted、 driver runtime production-ready 経路保護対象)
  - ADR-0006 (= compile.py 文法 + driver chip target 規約 起点 ADR、 AES+ YM2610B 想定 + FM3Extend XYZ 固定運用、 §H で「X/Y/Z 駆動 (= FM3Extend) は別 ADR (= 想定 ADR-0008) で起票」 と defer literal、 ADR-0008 = 本 ADR-0045 で消費置換)
  - ADR-0014 (= ADR-0006 sprint 成果 disposition、 改造 PMDDotNET 路線採用 + 自前 compile.py / driver 凍結)
  - ADR-0015 (= 改造 PMDDotNET 技術調査、 PMDPPZ 流儀 100-150 件 if 分岐 + wrapper、 PMDDotNETDriver source ground truth)
  - ADR-0016 (= 改造着手 sprint plan、 step 1 commit chain で /B option + opnb_flg + .MN 切替 + L-Q part 6 ch 後方拡張領域 完全実装、 9 commit 達成)
- 関連 memory:
  - `project_adr_0013_0014_path_switch.md` (= 改造 PMDDotNET 路線切替、 PMDPPZ 流儀発見、 軸 B driver layer 基盤)
  - `project_pmdneo_develop_driver_snapshot.md` (= develop branch PMDNEO driver 現状 snapshot、 Phase 2 SubF-1.1 まで進行 finding)
  - `project_pmdneo_driver_two_paths_discovery.md` (= driver 二系統発見、 standalone_test.s 本線 / PMDNEO.s 系 legacy)
  - `project_pmdneo_phase_transition_verification_driven.md` (= 「検証可能な進め方を固定しながら機能を増やす」 phase 転換、 軸 B 実装規律基盤)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 軸 B 実装 verify gate 基盤)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化、 軸 B 起票継続適用)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律、 軸 B 起票 prompt 規律基盤)
  - `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= sub-agent 5 連続 fail 経験、 軸 B 実装も主軸 fallback default 想定)

## 背景 (= why now)

### 軸 G ζ 保留 + 37th session 他軸候補整理経由

37th session 起点 (= 2026-05-19、 PR #50 MERGED bfde5a5 後) で user 判断: **軸 G ζ 未着手のまま保留 + 他軸へ移る**。 軸 G は ε partial complete + ζ 比較表 literal 化済 (= 案 X/Y/Z) で Codex layer 2 3 round chain approve 取得済だが、 case Z = test mode fixture proof に留まり production runtime semantics に届かないため、 user 判断で軸 G state は **ε partial complete + ADR-0048 Draft 維持** で固定 (= 軸 G を「完成」 と表現することの禁止 + Accepted 化禁止 + integration 同居 reject finding literal 保護)。

37th session 主軸が他軸 4 候補 (= α 軸 B 起票 / β 軸 D 起票 / γ 軸 F-2-A defer解除 / δ 軸 C δ tempo refinement) を 7 評価軸で比較し、 **候補 α 軸 B 起票 (= ADR-0045 doc-only)** を主軸推奨として Codex layer 2 round 1 approve 取得 (= must-fix 0 件 + nice-to-have 1 件 = F-2-B 譲渡含むが F-2-A defer解除ではない冒頭明示 + 規律違反 risk 0 件)。

### 採用根拠 6 件 (= 主軸推奨 + Codex layer 2 因果整合確認)

1. **V1 release への critical path**: Phase 2 FM/SSG driver フルスクラッチ replace は docs/design/PMDNEO_DESIGN.md §2 Phase 2 必須軸
2. **軸 G に依存しない**: ADPCM 動的供給 (= 軸 G) とは driver layer 独立、 軸 G ζ 保留と無関係に着手可能
3. **doc-only 起票で risk 最小**: 実装は別 sub-sprint chain、 起票時点は scope 定義のみ + driver / runtime / compiler / vendor 完全不変
4. **F-2-A defer 解除より価値高**: F-2-A は F-2-B (= 軸 B) 完成必要 = 軸 B 着手前提
5. **軸 D より base 完成度高**: WebApp は backend 軸 (= 軸 G 含む) 安定必要 = 軸 G ε partial 状態で先走り risk
6. **軸 C δ tempo より固有性高**: tempo refinement は aesthetic で根本 layer 未調査、 軸 B 起票より先に進める価値低

### ADR-0044 §F-2-B 譲渡軸の literal 継承

ADR-0044 §決定 5 (= 採用案 (ii) 軸 F 全体 scope-out) で literal: 「**F-2-B**: PMDNEO driver ch3 4-op FM3 拡張モード実装 → 軸 B (= Phase 2 FM/SSG driver フルスクラッチ、 ADR-0008 候補) の範囲、 軸 B 着手時に統合」。

ADR-0006 §H で literal: 「X/Y/Z 駆動 (= FM3Extend) は別 ADR (= 想定 ADR-0008) で起票」。 historical 予約番号 ADR-0008 は未起票のまま 30 ADR 経過し、 ADR-0041 §決定 8 ADR 番号予約簿で軸 B = ADR-0045 候補に切替 (= 番号空き番号 0045 採用、 ADR-0008 は番号予約 release)。 本 ADR-0045 で driver ch3 4-op + Phase 2 全体 FM/SSG フルスクラッチを統合的に扱う。

### Phase 2 driver フルスクラッチ scope の literal

CLAUDE.md §開発フェーズ + docs/design/PMDNEO_DESIGN.md §2 で literal:
- **Phase 1**: PoC = 既存 PMDDotNET driver Z80 binary 流用、 NEOGEO ROM ビルド + MAME 再生確認
- **Phase 2**: フルスクラッチ driver の FM/SSG 部分 (= YM2610B 仕様、 既存 driver 置換)
- **Phase 3**: ADPCM-A 6ch + .PNE + WebApp 最小骨格
- **Phase 4**: ADPCM-B + WebApp 完成 + IPL + プレイヤー V1 + リリース統合

軸 B = **Phase 2 fullscratch driver** の boundary。 PMDDotNET driver Z80 binary 流用 (= Phase 1 PoC base) を新規 driver で置換する。

### 既存 driver path 現状 (= memory `project_pmdneo_driver_two_paths_discovery.md` literal)

PMDNEO repo 内 driver 配置は **二系統**:
- **本線**: `standalone_test.s` 3700+ 行 = nullsound-free PoC、 ADR-0016 step 1-18 + ADR-0021/0022/0023/0024/0025/0026/0027/0028/0029/0030/0031/0032 (= K/R rhythm + drum kind expansion + simultaneous trigger) + ADR-0043 ADPCM-B + ADR-0048 軸 G δ runtime selection 部分実装の累積 implementation host
- **legacy**: `src/driver/PMDNEO.s` 系 = nullsound integration 試行、 未到達、 接続点なし

軸 B は **本線 `standalone_test.s` 上で進める** が、 Phase 2 フルスクラッチ scope (= FM 6ch / SSG 3ch driver 全面 rewrite) は既存 ADR-0016+ implementation の上に重ねる経路。 既存 ADR-0023 〜 ADR-0048 routine は **不可触保護** (= ADR-0043 production-ready 経路 + ADR-0048 δ 案 C 経路) で、 軸 B 拡張は **追加 routine + dispatch table 差替** で実装する想定 (= 詳細は β/γ/δ 段で確定)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0045 を起票、 後続 sub-sprint α-ε で archaeology → 最小設計 → proof spike → integration → completion を段階的に進める。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。

## 決定

### 決定 1: 軸 B sub-sprint 構成 = 5 段 α/β/γ/δ/ε (= ADR-0048 5 段構成踏襲 + 軸 B 実態整合)

軸 B を **5 段階 α/β/γ/δ/ε** に分割する。 ADR-0048 軸 G 5 段構成 (= format/parser/integration/runtime/audition 軸分離) を踏襲しつつ、 軸 B 実態 (= driver フルスクラッチ + F-2-B ch3 4-op + 既存 ADR-0023+ baseline 保護) に合わせて具体名を調整。

| sub | 名称 | 内容 | 完了判定 | driver touch |
|---|---|---|---|---|
| **α** | driver archaeology + Phase 2 scope 確定 | 既存 PMDDotNETDriver (= `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` + `PMD.cs` + `PCMDRV.cs` + `PCMLOAD.cs` + `PPZDRV.cs` + `EFCDRV.cs` + `OPNATimer.cs` ground truth、 FM/SSG dispatch routine は driver.cs/PMD.cs 内に統合配置 = 別 file 派生なし) reference + `src/driver/standalone_test.s` 本線 FM/SSG 部分 inventory + Phase 2 fullscratch boundary literal 化 (= 何を replace、 何を保護) + F-2-B ch3 4-op 既存 PMDPPZ 流儀 reference + ADR Annex 化 | 主要 routine pattern reference + 既存 driver inventory (= FM 6ch dispatch / SSG 3ch dispatch 現状) + boundary literal + driver source touch なし、 doc-only | なし (= **完了 = 37th session α sub-sprint、 Annex D + Annex E 追加**) |
| **β** | 最小設計 + interface 固定 | α inventory base で fullscratch driver interface 設計 (= FM/SSG dispatch routine 境界 + register write sequence + chip target flag 接続 + 既存 ADR-0023+ routine 不可触保護方針 + F-2-B ch3 4-op integration 経路) + ADR §決定 追加 | interface 設計 ADR 追加 + 既存 routine 不可触 literal 確認 + F-2-B 統合点 literal、 driver source touch なし | 設計のみ (= **完了 = 37th session β sub-sprint、 Annex G 追加 = G-1 12 候補分類 + G-2 最小設計 9 領域 + G-3 γ/δ/ε 橋渡し**) |
| **γ** | proof / spike (= 最小 routine 1 つ proof) | β interface design を **Python spike script** (= standard library only、 `scripts/*-spike.py`) で proof + 期待 register write sequence literal + 既存 driver behavior と byte-identical 比較 (= register trace primary gate、 spike script が emit する期待値 vs 既存 driver の実 trace) | Python spike script 実装 + register trace 期待値一致 + 既存 ADR-0023+ baseline byte-identical 維持 + **driver source touch なし** (= spike は Python のみ、 driver source は α-δ 全段で完全不変) | なし (= spike script のみ、 **完了 = 37th session γ sub-sprint、 target (c) v2 entry skeleton + 1 register write、 Annex H 追加**) |
| **δ** | integration (= 既存 driver と並走 + sub-axis 分解計画) | γ proof base で FM 6ch / SSG 3ch / ADPCM-A 6ch / ADPCM-B 1ch sub-axis 分解 + F-2-B ch3 4-op integration + 軸 C/G との接続点 literal + 実装 sprint chain 計画 (= verify gate strategy + audio gate strategy) | sub-axis 分解 ADR + 軸 C ADR-0043 不可触確認 + 軸 G ADR-0048 不可触確認 + F-2-B integration 経路確定 + 実装 sprint chain 計画 literal | 設計のみ |
| **ε** | completion + Accepted 判断 | α/β/γ/δ verify gate 全 PASS 確認 + ADR Draft → Accepted 判断 (= user 判断 gate) + dashboard 軸 B 完了 reflect + 実装 sprint への bridging note | 全 sub verify PASS + user audition 不要 (= doc-only sprint で audio behavior 変化なし) + ADR Accepted 移行 user 判断 gate 経由 | なし |

#### 共通規律 (= 全 sub-sprint 共通)

1. **doc-only filing sprint**: driver / runtime / compiler / vendor 完全不変 (= 既存 implementation touch 禁止)
2. **既存 ADR baseline 保護**: ADR-0016 step 1-18 + ADR-0021〜0032 + ADR-0043 + ADR-0048 implementation routine は **不可触** (= 軸 B 実装は別 routine 並設 only、 既存 routine 改変は別 sprint 起票が必要)
3. **既存 PMDDotNET driver Z80 binary 流用 (= Phase 1 PoC base) は当面保持**: Phase 2 fullscratch driver が production-ready になるまで Phase 1 PoC base は並走、 switch 時期は実装 sprint で確定
4. **vendor wav 3 件 retain** (= 33rd session 起点 §user 明示永続 scope-out 節遵守、 untracked 維持、 commit 混入禁止)
5. **register trace primary gate** (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 wav sha256 は cycle-sensitive で secondary)
6. **audio gate 期待音 8 軸詳細記述義務** (= 個数 / 時刻 / 経路 / sample / 期待音 / pass-fail 判定点 / aesthetic scope-out、 ε 段で audio gate 発動時のみ適用、 起票 sprint では audio gate 不要)

### 決定 2: 軸 F (= ADR-0044) との関係 = F-2-B 譲渡継承 + F-2-A defer 維持 + ADR-0044 Accepted 不可触

| 項目 | 状態 | 根拠 |
|---|---|---|
| **F-2-B** (= driver ch3 4-op FM3 拡張) | **本 ADR で扱う** (= 軸 B sub-axis 分解 δ 段で integration) | ADR-0044 §決定 5 譲渡 literal |
| **F-2-A** (= 改造 PMDDotNET compiler X/Y/Z 強制) | **defer 維持** (= 本 ADR で扱わない) | ADR-0044 §決定 5 将来 sprint defer + Codex nice-to-have 1 件反映 |
| **ADR-0044 Accepted 状態** | **不可触** (= 軸 F 完成扱い継続、 本 ADR で ADR-0044 改変なし) | ADR-0044 = 軸 F 状態整理 ADR として消費完了 |

F-2-B 譲渡で軸境界が「軸 F = MML compiler 拡張 完成扱い」 / 「軸 B = Phase 2 driver フルスクラッチ + F-2-B ch3 4-op」 と明確化。 軸 F と軸 B の重複 scope は **0** (= compiler / driver layer 完全分離)。

### 決定 3: 軸 G (= ADR-0048) との関係 = Draft 維持 + ζ 未着手 + 軸 G を完成扱いしない + state 不可触

| 項目 | 状態 | 根拠 |
|---|---|---|
| **ADR-0048 Draft 状態** | **維持** (= 本 ADR で ADR-0048 改変なし) | user 明示 37th session 維持規律 + Codex layer 2 approve |
| **軸 G ε partial complete state** | **維持** (= integration 同居 reject finding literal 保護) | ADR-0048 §決定 + dashboard literal |
| **軸 G ζ 未着手** | **維持** (= 案 X/Y/Z 比較表 literal + 案 Z 主軸推奨) | ADR-0048 ζ 着手準備 section literal |
| 軸 G state 表現 | 軸 G を「完成」 と表現することの禁止 (= 軸 G state は常に「ε partial complete + ζ 未着手」 と表記) | user 明示 37th session 維持規律 |
| **軸 G driver runtime 接続点** | **不可触** (= 軸 B 実装で軸 G `pmdneo_select_adpcmb_ppc_pointer` 等の routine 触らない) | ADR-0048 production-ready 経路保護 + ADR-0043 routine 保護経路継承 |

軸 G ADPCM 動的 sample 供給は driver runtime layer で軸 B Phase 2 driver と接続する可能性があるが、 本 ADR 起票 sprint では **接続設計 scope-out** (= 軸 B δ 段で integration 接続点 literal 化、 実装は軸 B 実装 sprint で行う、 軸 G ADR-0048 は不可触)。

### 決定 4: doc-only filing 規律 (= 全 sub-sprint α/β/γ/δ/ε 共通)

本 ADR 起票 sprint は **doc-only** で、 次を **完全不変** に保つ:

1. **driver source** (= `src/driver/standalone_test.s` + `src/driver/PMDNEO.s` + `src/driver/*.inc` 全 driver source file)
2. **runtime layer** (= driver 内 routine、 SRAM layout 0xFD20-0xFD32 等)
3. **compiler** (= `vendor/PMDDotNET/` 全 file、 `compile.py` 凍結 assets、 mc.cs / mml_seg.cs / m_seg.cs 等)
4. **vendor** (= `vendor/ngdevkit-examples/` + `vendor/PMDDotNET/` + `vendor/pmd48s/` 全 file、 ただし軸 G で vendor wav 3 件 untracked retain 規律継承)
5. **vromtool.py** (= ngdevkit 外部 tool、 ADR-0048 §決定 8 35th session vromtool finding 経路保護継承)
6. **verify script** (= scripts/verify-*.sh、 ADR-0023+ 既存 verify gate 保護)
7. **fixture data** (= src/test-fixtures/、 既存 MML / wav / yaml 全 retain)

write 対象 (= 軸 B 起票 sprint scope-in):
- 本 ADR file (= `docs/adr/0045-pmdneo-axis-b-phase2-fm-ssg-driver-fullscratch.md`)
- `docs/parallel-axes-dashboard.md` (= 軸 B 行 + ADR 番号予約簿 + escalation 履歴 update)

### 決定 5: scope-in / scope-out / non-goal

#### scope-in (= 軸 B 起票 sprint で扱う)

1. Phase 2 FM/SSG driver フルスクラッチ scope 定義 (= boundary literal、 何を replace + 何を保護)
2. F-2-B (= driver ch3 4-op FM3 拡張) integration 設計 (= 軸 F ADR-0044 譲渡経路継承)
3. 既存 PMDDotNETDriver source (= `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` + `PMD.cs` 等、 FM/SSG dispatch routine は main file 内統合配置) ground truth reference
4. 既存 standalone_test.s 本線 FM/SSG 部分 inventory
5. ADR-0016 step 1-18 + ADR-0023〜0032 + ADR-0043 + ADR-0048 routine 不可触保護方針
6. 軸 C ADR-0043 production-ready 経路保護
7. 軸 G ADR-0048 ε partial complete state 不可触保護
8. sub-axis 分解 (= FM 6ch / SSG 3ch / 軸 C ADPCM-B (= ADR-0043) 接続点 / 軸 G ADPCM 動的 sample 供給 (= ADR-0048) 接続点)
9. 実装 sprint chain 計画 (= verify gate + audio gate strategy + 既存 baseline 保護)
10. dashboard 軸 B 行 update + ADR 番号予約簿 update (= 0045 軸 B 確定使用)

#### scope-out (= 別 ADR / 別軸 / future sprint)

1. **driver / runtime / compiler / vendor 実 source 改変** (= 本 ADR 起票 sprint は doc-only、 実装は軸 B 実装 sprint で別起票)
2. **F-2-A defer 解除** (= ADR-0044 §決定 5 維持、 将来 sprint で別 ADR 起票時に再着手判断)
3. **ADR-0044 Accepted 状態改変** (= 軸 F 完成扱い継続)
4. **ADR-0048 Draft 状態改変** (= 軸 G ε partial complete + ζ 未着手 維持)
5. **軸 G ADR-0048 ζ 案 X/Y/Z 着手** (= user 明示 GO 後、 別 sprint scope)
6. **軸 G ADR-0048 Accepted 化** (= user 判断 gate、 本 ADR では trigger しない)
7. **軸 C δ tempo refinement** (= aesthetic future sprint、 user 明示 GO 待ち、 user 明示永続 scope-out 表)
8. **軸 D WebApp 起票** (= ADR-0046 候補、 backend 軸 安定後)
9. **軸 E IPL/プレイヤー V1 起票** (= ADR-0047 候補、 driver 完成後 = 軸 B 完成必要)
10. **vendor wav 3 件 commit** (= untracked retain 維持、 user 明示永続 skip)
11. **Surge XT / .fxp render / actual render** (= user 明示永続 skip)
12. **軸 A β-3 / β-4** (= user 明示永続 skip / 永久 user scope)
13. **PMD88 互換** (= CLAUDE.md §プロジェクト要旨で明示放棄、 V3.9 Z80 流用は試行で偽完了連発の教訓)

#### non-goal (= 軸 B として目指さない)

1. **既存 ADR-0023+ implementation の改変** (= 不可触保護、 軸 B は別 routine 並設 only)
2. **PMDDotNET driver Z80 binary 流用 (= Phase 1 PoC base) の即時廃止** (= Phase 2 fullscratch production-ready まで並走)
3. **OPNA (YM2608) 専用 driver 化** (= docs/design/PMDNEO_DESIGN.md §チップ仕様で driver YM2610B 仕様で書く + OPNA / YM2610 / YM2610B 全環境動作可能、 OPNA 専用化 = scope-out)
4. **ADPCM 部分の driver 改変** (= 軸 C ADR-0043 + 軸 G ADR-0048 既存 routine 保護、 ADPCM-A/B 拡張は軸 C/G 内で扱う)

### 決定 6: verify gate / review gate (= doc-only sprint 整合性確認中心)

doc-only sprint なので実装 verify (= build OK + register trace + audio gate) ではなく **整合性確認** を中心とする。 ε 段で全 sub verify gate 集約。

#### α 段 verify gate
- driver archaeology 内容が PMDDotNETDriver source (= vendor/PMDDotNET/PMDDotNETDriver/*.cs) と integer 整合か (= file 名 + 行数 + routine name reference 確認)
- standalone_test.s 本線 inventory が現 source (= 行数 + routine reference) と integer 整合か
- Phase 2 boundary literal が CLAUDE.md §開発フェーズ + docs/design/PMDNEO_DESIGN.md §2 と integer 整合か

#### β 段 verify gate
- interface 設計が α inventory に整合か (= 引用 routine name + 改変経路 literal)
- F-2-B ch3 4-op integration 経路が ADR-0044 §決定 5 譲渡 literal と整合か
- 既存 ADR-0023+ routine 不可触方針が ADR-0016/0021〜0032/0043/0048 と integer 整合か

#### γ 段 verify gate
- spike が最小 routine 1 つ proof scope に収まっているか (= scope creep 防止)
- register trace 期待値が既存 driver behavior と byte-identical 比較可能か (= 既存 ADR-0023+ verify gate 流儀踏襲)
- **driver source touch なし**確認 (= spike は Python script のみ、 driver source / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変、 doc-only filing 規律遵守継続)

#### δ 段 verify gate
- sub-axis 分解が軸 C / 軸 G との重複なく integer 整合か
- F-2-B integration 経路 literal が β 設計と γ proof に integer 整合か
- 実装 sprint chain 計画 (= verify gate strategy + audio gate strategy) が ADR-0043 / ADR-0048 既存 strategy と integer 整合か

#### ε 段 verify gate (= 整合性確認集約)
- α/β/γ/δ verify gate 全 PASS 確認
- ADR-0044 Accepted 状態 不可触確認
- ADR-0048 Draft 状態 + 軸 G ε partial complete state 不可触確認
- dashboard 軸 B 行 + ADR 番号予約簿 sync 整合確認
- vendor wav 3 件 untracked retain 確認 (= commit 混入なし)
- driver / runtime / compiler / vendor 完全不変確認 (= git diff で確認)
- user audition 不要確認 (= doc-only sprint で audio behavior 変化なし、 audition gate 発動なし)
- ADR Draft → Accepted 移行は **user 判断 gate** (= 自動 trigger しない、 ε で user 判断仰ぎ)

#### review gate (= 全 sub-sprint 共通)
- ADR-0041 §決定 4-2 Codex layer 2 review (= must-fix / nice-to-have / 規律違反 risk + approve/revise/escalate 判定) を全 sub-sprint commit 前に投入
- approve 後のみ commit、 revise は修正 + 再投入で chain
- escalate 6 種 (= ADR-0041 §決定 5) 該当時は dashboard escalation 履歴 literal 記録

### 決定 7: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

軸 B 起票 sprint + 後続 実装 sprint で ADR-0041 §決定 4-2 (= Codex rescue 化 default 永続化、 user 確認質問の Codex layer 2 経由化、 user 介入は escalate or 最終確認のみ) を継承適用する。

- 主軸単独実装 default (= sub-agent isolation 5 連続 fail 経験を踏まえた fallback 既 pattern、 ADR-0041 §決定 4-3)
- Codex layer 2 (= session `019e3425-3327-74e1-95bc-461cc5d0af66` 流用) を全 sub-sprint commit 前に投入
- user 介入は escalate (= aesthetic / audio / 設計トレードオフ / 規律違反 risk 重大) or 最終確認 (= PR merge 判断 / ADR Accepted 移行) のみ
- 「完走まで user 介入なし」 (= 37th session user literal「常に Codex rescue でやりとりをして判断し、 完走まで user までに質問をしない」) を継承

## 後続 sub-sprint chain 想定 (= 採用案確定後)

| 段 | 種別 | scope | PR 想定 |
|---|---|---|---|
| 起票 (= 本 ADR) | doc-only | ADR-0045 Draft + dashboard sync | 1 PR (= 本 sprint) |
| α (= driver archaeology) | doc-only | ADR Annex A 追加 (= PMDDotNETDriver source ref + standalone_test.s inventory + Phase 2 boundary literal) | 1 PR |
| β (= interface 固定) | doc-only | ADR §決定 追加 (= interface 設計 + F-2-B 統合点 + 既存 routine 不可触方針) | 1 PR |
| γ (= proof spike) | spike only | spike script 新規 + ADR §決定 追加 (= proof 結果 + register trace 期待値) | 1 PR |
| δ (= integration design) | doc-only | ADR §決定 追加 (= sub-axis 分解 + F-2-B integration + 実装 sprint chain 計画) | 1 PR |
| ε (= completion) | doc-only | ADR Draft → Accepted 移行 (= user 判断 gate) + dashboard 軸 B 完了 reflect | 1 PR |

軸 B 起票 sprint chain 完了後、 **軸 B 実装 sprint** (= driver source touch sprint) は別 ADR or 同 ADR 内 sub-sprint で起票判断 (= ε 完了時 user 判断 gate)。

## Annex A: 軸 B context literal (= dashboard L21 + ADR-0044 §決定 5 + ADR-0006 §H + docs/design/PMDNEO_DESIGN.md §2 統合)

### A-1: 軸 B 命名 + 軸予約

- 軸名: **軸 B (= Phase 2 FM/SSG driver フルスクラッチ)**
- 予約 ADR 番号: **0045** (= ADR-0041 §決定 8 ADR 番号予約簿、 本 ADR で確定使用)
- 旧予約番号: ADR-0008 (= ADR-0006 §H literal、 30 ADR 経過で未起票、 ADR-0045 に置換)
- branch 命名規約: `wip-axis-b-*` (= ADR-0041 §決定 3 軸別 wip- branch 集約 1 軸 1 PR)

### A-2: Phase 2 scope literal (= CLAUDE.md + docs/design/PMDNEO_DESIGN.md §2)

- Phase 1: 既存 PMDDotNET driver Z80 binary 流用 (= NEOGEO ROM ビルド + MAME 再生確認)
- **Phase 2 (= 軸 B scope)**: フルスクラッチ driver の FM/SSG 部分 (= YM2610B 仕様、 既存 driver 置換)
- Phase 3: ADPCM-A 6ch + .PNE + WebApp 最小骨格 (= 軸 C + 軸 D 等)
- Phase 4: ADPCM-B + WebApp 完成 + IPL + プレイヤー V1 + リリース統合 (= 軸 C + 軸 D + 軸 E)

### A-3: 既存 driver 配置 (= memory `project_pmdneo_driver_two_paths_discovery.md` literal)

- **本線**: `src/driver/standalone_test.s` (= 約 154KB / 3700+ 行) = nullsound-free PoC、 ADR-0016 step 1-18 + ADR-0021〜0032 + ADR-0043 + ADR-0048 累積 implementation host
- **legacy**: `PMDNEO.s` 系 = nullsound integration 試行、 未完成、 接続点なし

### A-4: 既存 ADR-0023+ implementation routine (= 不可触保護対象)

軸 B 拡張で **不可触** とすべき既存 routine + ADR pair (= 詳細 routine name は α 段で literal 化):

- ADR-0016: step 1-18 完成 implementation (= /B option / opnb_flg / .MN 切替 / L-Q part 6 ch 後方拡張)
- ADR-0021〜0024: `.PNE` asset pipeline + `.MN` filename embed + filename → sample_table_id resolver + sample_table_id selection consumption
- ADR-0025: multi-table id=0x01 proof
- ADR-0026〜0032: K/R rhythm + drum kind expansion (b/s/h/c/t/i) + simultaneous trigger
- ADR-0043: ADPCM-B 1ch runtime-managed architecture (= 軸 C 完了、 production-ready 経路保護)
- ADR-0048: 軸 G ADPCM 動的 sample 供給 (= ε partial complete + ζ 未着手、 driver runtime selection 部分実装)

### A-5: F-2-B (= ADR-0044 §決定 5 譲渡軸) literal

- 元 sub-軸: F-2-B (= ADR-0044 §F-2-B)
- 内容: PMDNEO driver ch3 4-op FM3 拡張モード実装 (= per-op fnum / volume / keyon、 ADR-0006 §H 規約)
- 譲渡経路: ADR-0044 §決定 5 (= 採用案 (ii)) で「軸 B (= Phase 2 FM/SSG driver フルスクラッチ、 ADR-0008 候補) の範囲」 と literal、 ADR-0008 = 本 ADR-0045 に置換
- 軸 B 内 sub-axis: δ 段で integration 設計、 実装は軸 B 実装 sprint
- **F-2-A defer 解除しない** (= ADR-0044 §決定 5 維持、 本 ADR 範囲外)

### A-6: FM/SSG レジスタ互換 (= docs/design/PMDNEO_DESIGN.md §チップ仕様 literal)

- YM2608(OPNA) と YM2610(OPNB)/YM2610B は FM/SSG レジスタ完全互換
- 同 driver code が OPNA / YM2610 / YM2610B 全環境で動作可能
- driver は **YM2610B 仕様で書く** (= FM 6ch dispatch)
- OPNA 用 driver の dispatch をそのまま OPNB に移植可能 (= Phase 2 fullscratch driver で踏襲)

### A-7: 軸 F (= ADR-0044) との関係 literal

- 軸 F = MML compiler 拡張、 **Accepted (= 完成扱い)**、 ADR-0044 不可触
- 軸 B は driver layer (= driver source)、 軸 F は compiler layer (= mc.cs / mml_seg.cs / m_seg.cs)、 重複 scope 0
- F-2-B 譲渡で軸境界明確化、 軸 B 内 sub-axis として integration
- F-2-A defer 維持 (= 本 ADR で扱わない、 将来 sprint で別 ADR 起票時に再着手判断)

### A-8: 軸 G (= ADR-0048) との関係 literal

- 軸 G = ADPCM 動的 sample 供給、 **Draft (= ε partial complete + ζ 未着手)**、 ADR-0048 不可触
- 軸 G ε partial = PPC audible proof approve / integration 同居 reject、 ζ defer literal 保護対象
- 軸 B は driver layer (= FM/SSG)、 軸 G も driver layer (= ADPCM 動的 sample 供給 runtime selection) で重複可能性あるが、 **接続点設計は軸 B δ 段 + 実装 sprint scope** (= 本 ADR 起票 sprint では scope-out)
- 軸 G ζ Accepted 化 trigger なし (= 本 ADR で軸 G state 改変なし)

## Annex B: 既存 PMDDotNETDriver source ground truth reference (= 詳細は α 段で literal 化)

α 段で reference する vendor source の高レベル inventory (= 詳細 行数 + routine name + 改変経路は α 段 ADR Annex で literal 化、 行数は α 段で `wc -l` 等で確定):

| file | 役割 |
|---|---|
| `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` | PMDDotNETDriver entry / dispatch、 FM/SSG / ADPCM 統合 driver layer |
| `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` | PMD core 駆動 (= work area / part dispatch / interrupt 等)、 FM/SSG dispatch routine 統合配置 |
| `vendor/PMDDotNET/PMDDotNETDriver/OPNATimer.cs` | OPNA timer (= TIMER-A / TIMER-B) 駆動 |
| `vendor/PMDDotNET/PMDDotNETDriver/EFCDRV.cs` | effect driver (= 軸 B 範囲外、 reference として参照) |
| `vendor/PMDDotNET/PMDDotNETDriver/PPZDRV.cs` | PPZ8 chip 駆動 driver (= 軸 B 範囲外、 PMDPPZ 流儀 reference として参照) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV.cs` | ADPCM-B driver (= 軸 G ADR-0048 ground truth、 軸 B 範囲外、 接続点 reference) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV86.cs` | PC-86 PCM driver (= 軸 B 範囲外、 reference) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMLOAD.cs` | `.PPC` parser (= 軸 G ADR-0048 ground truth、 軸 B 範囲外) |

軸 B α 段 で **FM/SSG 軸 specific** な routine + register write sequence + envelope state machine を `driver.cs` + `PMD.cs` 内で特定 + literal 化する (= FM/SSG dispatch は別 file 派生ではなく main file 内統合配置)。

## Annex C: doc-only filing 規律 (= 全 sub-sprint 共通、 ADR-0048 §決定 4 踏襲)

軸 B 起票 sprint + 全 sub-sprint α-ε で次を遵守:

1. driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変
2. write 対象 = ADR file (= `docs/adr/0045-*.md`) + dashboard (= `docs/parallel-axes-dashboard.md`) + sub-sprint γ 段で spike script (= scripts/*-spike.py 等、 standard library only 想定) のみ
3. vendor wav 3 件 untracked retain (= user 明示永続 skip)
4. commit 前に Codex layer 2 review (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承)
5. ADR-0044 Accepted 状態 + ADR-0048 Draft 状態 + 軸 G ε partial complete state 完全不可触
6. ADR Draft → Accepted 移行は ε 段で user 判断 gate (= 自動 trigger しない)

## Annex D: 軸 B α 完了 = driver archaeology findings (= 37th session α sub-sprint deliverable、 doc-only investigation)

α sub-sprint 投入 (= 37th session、 user 明示 GO 経由) で実 source 調査を主軸単独で実施 (= driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変、 read-only investigation)。

### D-1: src/driver/ inventory (= 9 file 6777 行 = `wc -l` `.s` + `.inc` 集計、 `README.md` 等 docs 除外)

| file | 行数 | 役割 |
|---|---|---|
| `src/driver/standalone_test.s` | 4055 | **本線 host** = ADR-0016 step 1-18 後段 + ADR-0021〜0032 + ADR-0043 + ADR-0048 累積 implementation、 hook framework + ADR-extended routine 配置 (= 詳細 D-3-b/c) |
| `src/driver/PMD_Z80.inc` | 2213 | **PMD V4.8s 由来 legacy core** = `pmdneo_init` / `pmdneo_load_m` / `pmdneo_song_main` / `fmmain` / `pmdneo_psgmain` / `adpcmb_main` / `rhythm_main` 配置 (= 詳細 D-3-a)、 ADR-0017 §決定 1 「nullsound-free driver 本線として再評価」 + 軸 B α 調査時点で標準 PMDNEO 経路の参照対象として有効 (= 「接続点なし legacy」 と memory `project_pmdneo_driver_two_paths_discovery.md` に記述があるが、 IRQ.inc::71-81 から `pmdneo_init` / `pmdneo_load_m` 呼出経路あり = ADR 起票時の調査 finding、 詳細は D-6/D-11) |
| `src/driver/WORKAREA.inc` | 137 | per-part workarea SRAM layout 定数 = `PART_COUNT = 17` (= legacy 値)、 standalone_test.s が `PART_COUNT = 20` で上書き (= ADR-0006 §A 20 part 規約、 詳細 D-4) |
| `src/driver/IRQ.inc` | 121 | TIMER-B IRQ handler + sound command jump table (= cmd 0x00-0x05) |
| `src/driver/ADPCMB_DRV.inc` | 72 | ADPCM-B init (= ADR-0043 から呼び出される adpcmb_init 等) |
| `src/driver/PMDNEO.s` | 60 | legacy entry point (= minimal、 軸 B 範囲外) |
| `src/driver/KR_STUB.inc` | 52 | K/R rhythm legacy stub (= ADR-0026+ dispatch source) |
| `src/driver/ADPCMA_DRV.inc` | 48 | ADPCM-A legacy / stub |
| `src/driver/REGMAP.inc` | 19 | YM2610/B chip register 定数 (= nullsound `ports.inc` + `ym2610.inc` include) |

注: 集計対象 = `*.s` + `*.inc` のみ、 `README.md` 等の docs 除外。

### D-2: vendor PMDDotNETDriver/ inventory (= 14 file 20130 行 = `wc -l` `.cs` 集計、 `.csproj` 除外、 ground truth reference、 軸 B 範囲外で touch なし)

| file | 行数 | 役割 |
|---|---|---|
| `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` | 10748 | **MAIN driver core** (= PMD 駆動主体、 `mmain()` / `fmmain()` / `psgmain()` / `play_init()` / `data_init()` / `opn_init()` 統合配置) |
| `vendor/PMDDotNET/PMDDotNETDriver/PW.cs` | 2167 | PartWork struct (= per-part workarea struct、 Z80 移植元) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV86.cs` | 1903 | PC-86 PCM driver (= 軸 B 範囲外) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMLOAD.cs` | 1256 | `.PPC` loader (= 軸 G ADR-0048 ground truth、 軸 B 範囲外) |
| `vendor/PMDDotNET/PMDDotNETDriver/PPZDRV.cs` | 1135 | PPZ8 chip 駆動 driver (= 軸 B 範囲外、 PMDPPZ 流儀 reference) |
| `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV.cs` | 1063 | ADPCM-B driver (= 軸 G ADR-0048 ground truth、 軸 B 範囲外) |
| `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` | 601 | PMDDotNETDriver entry / dispatch / Rendering() |
| `vendor/PMDDotNET/PMDDotNETDriver/PPZ8em.cs` | 535 | PPZ8 emulator (= 軸 B 範囲外) |
| `vendor/PMDDotNET/PMDDotNETDriver/EFCDRV.cs` | 329 | effect driver (= 軸 B 範囲外) |
| `vendor/PMDDotNET/PMDDotNETDriver/x86Register.cs` | 148 | x86 register 模倣 (= Z80 移植 reference) |
| `vendor/PMDDotNET/PMDDotNETDriver/Pc98.cs` | 106 | PC-98 platform |
| `vendor/PMDDotNET/PMDDotNETDriver/OPNATimer.cs` | 86 | OPNA timer (= TIMER-A / TIMER-B) 駆動 |
| `vendor/PMDDotNET/PMDDotNETDriver/PPZChannelWork.cs` | 30 | PPZ8 channel work |
| `vendor/PMDDotNET/PMDDotNETDriver/PMDDotNETOption.cs` | 23 | option 構造 |

**重要 finding**: `PMD.cs` 10748 行が PMDDotNET driver core で、 ADR-0045 起票時の Annex B 推定値「約 8000 行」 は actual = **10748 行** に訂正必要 (= α 段で確定、 Annex B 行数は α 段で確定するとの注記済)。 FM/SSG dispatch routine は `PMD.cs` 内 `fmmain()` (L1216) / `psgmain()` (L1645) として配置 = 別 file 派生なし、 Annex B literal 確認。

### D-3: driver routine map (= file 別 + 責務 grouping、 3 階層 = PMD_Z80.inc legacy core / standalone_test.s 本線 hook framework / standalone_test.s ADR-extended routine)

#### D-3-a: PMD_Z80.inc PMD V4.8s 由来 legacy core routine (= top-level `::` labels、 軸 B α verify で 31 件 label 確認)

| routine | 行 | 責務 | ADR mapping |
|---|---|---|---|
| `pmdneo_init::` | 29 | driver init (= SSG mixer + TIMER-B 起動 + driver state init) | ADR-0016 step 1 |
| `fnumsetp::` | 253 | PSG fnum entry | PMD V4.8s 流儀 |
| `fnumsetp_ch::` | 257 | PSG fnum per-ch | PMD V4.8s 流儀 |
| `pmdneo_load_m::` | 414 | .M / .MN binary header parse + per-part body address set | ADR-0016 step 4 |
| `pmdneo_song_main::` | 1133 | legacy song main entry | PMD V4.8s 由来 (= standalone 側に同名 routine L1810 あり、 詳細 D-3-b) |
| `pmdneo_part_ix_from_part::` | 1163 | part 番号 → workarea index | PMD V4.8s 流儀 |
| `pmdneo_part_fetch_byte::` | 1183 | MML byte parser | PMD V4.8s 流儀 |
| `pmdneo_psg_keyon::` | 1195 | PSG keyon | PMD V4.8s 流儀 |
| `pmdneo_psg_keyoff::` | 1212 | PSG keyoff | PMD V4.8s 流儀 |
| `pmdneo_fm_keyon::` | 1228 | FM keyon | PMD V4.8s 流儀 |
| `pmdneo_fm_keyoff::` | 1246 | FM keyoff | PMD V4.8s 流儀 |
| `fmmain::` | 1266 | FM main per-part dispatch | PMD V4.8s 由来 |
| `pmdneo_psgmain::` | 1335 | SSG main per-part dispatch | PMD V4.8s 由来 |
| `adpcmb_main::` | 1402 | ADPCM-B main per-part dispatch | PMD V4.8s 由来 |
| `rhythm_main::` | 1466 | K/R rhythm dispatch | PMD V4.8s 由来 |
| `pmd_z80_main` | 119 | TIMER-B IRQ tick → song dispatch entry (= IRQ.inc 経由呼出、 D-6) | ADR-0016 step 4-2 |

その他: `pmdneo_scale_mml_length::` L1529 / `commandsp::` L1558 / `commandsr::` L1574 (= MML command tables) / `test_play_*` (= 古い test routine 群) / `test_fm_song_data::` L1043 / `adpcm_b_beat_struct::` L2192 / `test_play_adpcmb_beat::` L2210。

#### D-3-b: standalone_test.s 本線 hook framework (= 軸 B replacement target literal 軸)

standalone_test.s には PMD V4.8s 由来 routine と同名の `pmdneo_song_main:` L1810 (= 本線 entry) があり、 hook framework 経由で FM/SSG/ADPCM dispatch を行う。 hook の install + dispatcher + 実装 hook 配置:

| routine | 行 | 責務 |
|---|---|---|
| `pmdneo_song_main:` | 1810 | 本線 song main loop entry (= standalone 側、 PMD_Z80.inc L1133 とは別 routine) |
| `pmdneo_song_main_loop:` | 1812 | per-tick main loop body |
| `pmdneo_song_main_rhythm:` | 1828 | rhythm dispatch |
| `pmdneo_part_ix_from_part:` | 1845 | standalone 側 part 番号 → workarea |
| `pmdneo_part_fetch_byte:` | 1862 | standalone 側 MML byte parse |
| `pmdneo_part_main:` | 1910 | per-part main dispatch (= 本線、 hook 呼出経路) |
| `pmdneo5_init_part_hooks_fm:` | 1736 | hook install: FM hooks setup |
| `pmdneo5_init_part_hooks_psg:` | (= L1729 jp dest) | hook install: PSG hooks setup |
| `pmdneo5_init_part_hooks_pcm:` | (= L1731 jp dest) | hook install: ADPCM-B hooks setup |
| `pmdneo5_init_part_hooks_adpcma:` | (= L1734 jp dest) | hook install: ADPCM-A hooks setup |
| `pmdneo5_init_part_hooks_noop:` | (= L1725/L1733 jp dest) | hook install: K/R/X/Y/Z = noop (= 当面 mute literal) |
| `pmdneo_part_call_keyon_hook:` | 2087 | hook dispatcher: keyon |
| `pmdneo_part_call_keyoff_hook:` | 2092 | hook dispatcher: keyoff |
| `pmdneo_part_call_fnumset_hook:` | 2097 | hook dispatcher: fnumset |
| `pmdneo_part_call_volume_hook:` | 2102 | hook dispatcher: volume |
| `fm_keyon_hook:` | 2595 | FM keyon hook impl |
| `fm_keyoff_hook:` | 2602 | FM keyoff hook impl |
| `fnumset_fm_hook:` | 2607 | FM fnum hook impl |
| `fm_volume_hook:` | 2616 | FM volume hook impl |
| `psg_keyon_hook:` | 2674 | PSG keyon hook impl |
| `ssg_keyoff_hook:` | 2679 | SSG keyoff hook impl |
| `fnumsetp_ch_hook:` | 2684 | PSG fnum hook impl |
| `psg_volume_hook:` | 2692 | PSG volume hook impl |
| `adpcmb_keyon_hook:` | 2710 | ADPCM-B keyon hook impl |
| `adpcmb_keyoff_hook:` | 2715 | ADPCM-B keyoff hook impl |
| `adpcmb_volume_hook:` | 2721 | ADPCM-B volume hook impl |
| `adpcma_volume_hook:` | 2741 | ADPCM-A volume hook impl |
| `adpcma_keyon_hook:` | 2758 | ADPCM-A keyon hook impl |
| `adpcma_keyoff_hook:` | 2764 | ADPCM-A keyoff hook impl |
| `noop_hook:` | 2767 | noop hook (= K/R/X/Y/Z 配線先) |

軸 B fullscratch driver は **standalone hook framework に並設 routine 追加** or **新規 hook 配線** で実装 (= 既存 hook impl は不可触保護)。

#### D-3-c: standalone_test.s ADR-extended routine (= ADR-0021〜0048 累積 implementation、 不可触保護対象)

| routine | 行 | 責務 | ADR mapping |
|---|---|---|---|
| `fnumset_fm:` | 758 | FM fnum register write 実装 (= hook 経由呼出) | ADR-0016 step 後段 |
| `fnumset_fm_porta:` | 816 | FM portamento variant | ADR-0016 step 後段 |
| `init_ssg_voice:` | 835 | SSG voice init | ADR-0016 step 後段 |
| `fnumset_ssg:` | 852 | SSG fnum register write 実装 | ADR-0016 step 後段 |
| `ssg_keyoff:` | 904 | SSG keyoff 実装 | ADR-0016 step 後段 |
| `ssg_keyon:` | 915 | SSG keyon 実装 | ADR-0016 step 後段 |
| `fm_keyoff:` | 973 | FM keyoff 実装 | ADR-0016 step 後段 |
| `fm_keyon:` | 987 | FM keyon 実装 | ADR-0016 step 後段 |
| `pmdneo_fm_write_reg_ch:` | 1001 | FM ch-specific register write | ADR-0016 step 後段 |
| `pmdneo_fm_write_voice_group_ch:` | 1029 | FM voice group write | ADR-0016 step 後段 |
| `pmdneo_fm_clear_ssg_eg_ch:` | 1044 | SSG-EG clear | ADR-0016 step 後段 |
| `pmdneo_fm_voice_set_default:` | 1059 | FM voice default | ADR-0016 step 後段 |
| `pmdneo_fm_voice_set:` | 1063 | FM voice set | ADR-0016 step 後段 |
| `adpcmb_keyon:` | 2794 | ADPCM-B keyon entry (= hook 経由呼出) | ADR-0043 |
| `adpcmb_keyon_have_sample:` | 2829 | ADPCM-B keyon body (= sample addr 確定後) | ADR-0043 |
| `adpcmb_keyoff:` | 2876 | ADPCM-B keyoff 実装 | ADR-0043 |
| `pmdneo_select_adpcmb_ppc_pointer:` | 2901 | 軸 G PPC runtime selection | ADR-0048 δ |
| `pmdneo_select_adpcmb_sample_pointer:` | 2949 | ADPCM-B sample pointer 選択 | ADR-0043 |
| `adpcma_init:` | 3054 | ADPCM-A init | ADR-0016 step 5 |
| `adpcma_keyon_simple:` | 3079 | ADPCM-A keyon | ADR-0016 step 5 |
| `adpcma_keyoff:` | 3164 | ADPCM-A keyoff | ADR-0016 step 5 |
| `pne_sample_directory:` | 3227 | .PNE directory | ADR-0023 |
| `pmdneo_resolve_sample_table_id:` | 3283 | sample_table_id resolver | ADR-0023 |
| `pmdneo_select_sample_pointer:` | 3378 | sample pointer 選択 | ADR-0024/0025 |
| `rhythm_main:` (= standalone 側 新規 entry) | 3450 | K/R rhythm dispatch 本線 (= PMD_Z80.inc L1466 とは別 entry、 ADR-0026+ 整備) | ADR-0026〜0031 |
| `pmdneo_rhythm_event_trigger::` | 3535 | rhythm event trigger 統合 | ADR-0026〜0031 |
| `_rhythm_event_*_trigger:` (= b/s/c/h/t/i) | 3562-3760 | drum 種別 trigger | ADR-0026〜0031 |
| `pmdneo_mn_direct_load_lq_part_addr::` | 3921 | .MN L-Q part addr direct load | ADR-0021/0022 |
| `pmdneo_mn_direct_load_k_part_addr::` | 4028 | .MN K part addr direct load | ADR-0021/0022 |

軸 B α verify で **これら ADR-extended routine 全件 = 不可触保護対象**。 fullscratch driver は別 routine 並設 / 別 hook 配線で実装。

### D-4: WORKAREA SRAM layout (= 0xF820-0xFFBF address map + ADR mapping、 PART_COUNT 2 段 finding)

**finding**: `PART_COUNT` の値は 2 段存在 = standalone_test.s L119 `PART_COUNT = 20` (= ADR-0006 §A 20 part 規約、 本線、 1280 byte 0xF820-0xFD1F) と WORKAREA.inc L32 `PART_COUNT = 17` (= legacy 値、 1088 byte = 17 × 64)。 standalone_test.s が本線の 20 part 規約を実装し、 WORKAREA.inc の 17 は legacy。 軸 B 内で WORKAREA.inc 修正 = 不可触保護 (= ADR-0006 §A 規律維持で standalone 20 part 採用継続)。

| addr range | size | field | ADR mapping |
|---|---|---|---|
| `0xF820-0xFD1F` | 1280 byte | `part_workarea` (= 20 part × 64 byte、 standalone PART_COUNT = 20 採用) | ADR-0006 §A |
| `0xFD20-0xFD2F` | 16 byte | `driver_pne_filename_buf` | ADR-0022 §決定 4 |
| `0xFD30-0xFD31` | 2 byte | `driver_pne_filename_adr_word` | ADR-0022 §決定 4 |
| `0xFD32` | 1 byte | `driver_pne_sample_table_id` | ADR-0023 §決定 4 |
| `0xFD33-0xFD36` | 4 byte | `ppc_scratch_start/stop_lsb/msb` | ADR-0048 §決定 8 軸 G δ |
| `0xFD37-0xFD38` | 2 byte | `audition_frame_counter_lsb/msb` | ADR-0048 §決定 8 軸 G ε (test mode) |
| `0xFD39-0xFFBF` | 647 byte | free / 後続 phase 用 | - (= 軸 B 拡張 placement 候補) |

per-part workarea field offset (= WORKAREA.inc):

| offset | field | 用途 |
|---|---|---|
| 0 | `PART_OFF_ADDR` (2 byte) | current stream pointer |
| 2 | `PART_OFF_LOOP` (2 byte) | loop start pointer |
| 4 | `PART_OFF_LEN` (1 byte) | length counter |
| 5-8 | `PART_OFF_QDATA/B/2/3` | q gate time |
| 9 | `PART_OFF_VOLUME` | volume |
| 10 | `PART_OFF_SHIFT` | transposition |
| 11 | `PART_OFF_NOTE` | last note |
| 12 | `PART_OFF_LOOPCNT` | loop counter |
| 13 | `PART_OFF_LFOSWI` | LFO switch flag |
| 14 | `PART_OFF_PSGPAT` | PSG tone/noise/mix |
| 15 | `PART_OFF_TIEFLAG` | tie flag |
| 16-21 | `PART_OFF_ENVF/PAT/PV2/PR1/PR2/ENVVOL` | PSG envelope state |
| 22 | `PART_OFF_FLAGS` | future use |
| 28-29 | `PART_OFF_LOOPSTART/_HI` | L global loop marker |
| 32-48 | `PART_OFF_LOOPSTACK_BASE/LOOPDEPTH` | loop stack |

### D-5: driver_state global variables (= 0xF80x、 tempo/fade/song/loop/scale)

| field | 用途 | ADR mapping |
|---|---|---|
| `driver_tempo_d` / `driver_tempo_d_push` | BPM-encoded accumulator delta | ADR-0006 §A |
| `driver_tempo_48` / `driver_tempo_48_push` | 48-tick tempo | ADR-0006 §A |
| `driver_psg_noise` | PSG noise global | ADR-0006 §A |
| `driver_tieflag` | tie flag global | ADR-0006 §A |
| `driver_song_ready` / `driver_song_base` / `driver_song_end` | song state | ADR-0016 step 4 |
| `driver_fade_state/counter/master/speed` | fade state | SubF-1 |
| `driver_loop_cycle` | BD part LOOP cycle counter | ADR-0026+ |
| `driver_subtick_acc` | sub-tick accumulator | SubF-1.1 |
| `pmdneo_irq_count` | TIMER-B IRQ counter (16-bit) | SubB-2 |
| `scale_step/scale_tick_lo/hi/scale_mode` | scale 演奏 state (= legacy test routine) | SubB-4/SubC-2 |

### D-6: IRQ flow (= TIMER-B → nullsound NMI → polling loop → pmd_z80_main)

```
YM2610 TIMER-B 周期発火
  ↓
nullsound NMI handler
  ↓
update_timer_state_tracker (= nullsound provided)
  ↓
state_timer_tick_reached = 1 set
  ↓
pmdneo_play_loop (= IRQ.inc::74)
  - state_timer_tick_reached を poll
  - 1 検出時に xor a (= clear) + pmd_z80_main call
  ↓
pmd_z80_main (= PMD_Z80.inc:119 配置、 PMD V4.8s 由来 entry、 standalone_test.s 側に同名でなく
                 standalone_test.s 本線 song 駆動は同 file 内の pmdneo_song_main: L1810 経路)
  - pmdneo_irq_count increment
  - per-part main loop (= PMD_Z80.inc 側 fmmain L1266 / pmdneo_psgmain L1335 / adpcmb_main L1402 / rhythm_main L1466、
                          standalone 側 hook framework は pmdneo_part_call_*_hook L2087+ 経由で fm_*_hook L2595+ / psg_*_hook L2674+ / adpcmb_*_hook L2710+ / adpcma_*_hook L2741+ を dispatch)
  - chip register write
  - tempo / fade / mask 等 global state update
```

軸 G ε 切り分け 5 finding (= TIMER-B IRQ rate 6 秒で 2 回発火) は本 IRQ flow の TIMER-B 設定 + nullsound integration 部分 = 軸 G ζ 案 X TIMER-B 改修候補 scope (= 軸 B sprint 範囲外、 軸 G ζ defer 維持)。

### D-7: snd_command jump table (= IRQ.inc::40-48)

| cmd | 用途 | 実装 |
|---|---|---|
| 0x00 | unused | `snd_command_unused` no-op |
| 0x01 | ngdevkit reserved (= ROM switch) | `snd_command_01_prepare_for_rom_switch` (nullsound.lib) |
| 0x02 | PMDNEO 楽曲再生開始 | `pmdneo_init` + `pmdneo_load_m` + `pmdneo_play_loop` (= ADR-0016 step 4-2.5) |
| 0x03 | ngdevkit reserved (= reset_driver) | nullsound.lib default 実装 |
| 0x04 | fade out (= SubF-1 minimum) | SSG ABC + FM 6ch keyoff + ADPCM-B keyoff |
| 0x05 | ADPCM-B beat 単発再生 (= test) | `test_play_adpcmb_beat` |

軸 B 拡張で新規 cmd 追加可能 (= 0x06+ 領域)、 既存 entry 不可触保護。

### D-8: ADR routine mapping (= 既存 ADR-0016〜0048 routine 不可触保護対象 literal)

| ADR | 主要 routine | 行 | 役割 |
|---|---|---|---|
| ADR-0016 step 1-18 | standalone_test.s 全体 + IRQ.inc + WORKAREA.inc + PMD_Z80.inc legacy | 0-4055 | nullsound-free PoC 累積 implementation |
| ADR-0021/0022 | `pmdneo_mn_direct_load_lq_part_addr` / `pmdneo_mn_direct_load_k_part_addr` + `driver_pne_filename_buf` | 3921, 4028 | .PNE asset pipeline + .MN filename embed |
| ADR-0023 | `driver_pne_sample_table_id` + `pmdneo_resolve_sample_table_id` | 3283 | filename → sample_table_id resolver |
| ADR-0024/0025 | `pmdneo_select_sample_pointer` + table A/B | 3378 | sample_table_id selection consumption + multi-table proof |
| ADR-0026-0031 | `pmdneo_rhythm_event_trigger` + `_rhythm_event_*_trigger` (b/s/h/c/t/i) | 3535-3760 | K/R rhythm dispatch + drum kind expansion |
| ADR-0032 | rhythm simultaneous trigger semantics | (= rhythm_main 関連) | simultaneous trigger proof |
| ADR-0043 | `adpcmb_keyon:` L2794 (= entry) + `adpcmb_keyon_have_sample:` L2829 (= body) + `pmdneo_select_adpcmb_sample_pointer` L2949 + voice index table | 2794, 2829, 2949 | ADPCM-B 1ch runtime-managed architecture |
| ADR-0048 δ | `pmdneo_select_adpcmb_ppc_pointer` + `ppc_scratch_*` | 2901 | 軸 G ADPCM 動的 sample 供給 runtime selection (= 部分実装) |

**軸 B 不可触保護対象**: 上記全 routine + workarea field 既存 layout + driver_state global field 既存 + IRQ flow 既存 + snd_command 0x00-0x05 既存。

### D-9: FM/SSG existing routines (= 軸 B replacement target + file 別 配置 literal)

軸 B Phase 2 fullscratch driver で **replacement 対象** となる FM/SSG dispatch routine (= file 別 + D-3 inventory ref):

#### PMD_Z80.inc legacy core (= D-3-a inventory)
- **FM main dispatch**: `fmmain::` L1266
- **SSG main dispatch**: `pmdneo_psgmain::` L1335
- **FM keyon/keyoff**: `pmdneo_fm_keyon::` L1228 / `pmdneo_fm_keyoff::` L1246
- **SSG keyon/keyoff**: `pmdneo_psg_keyon::` L1195 / `pmdneo_psg_keyoff::` L1212
- **PSG fnum entry**: `fnumsetp::` L253 / `fnumsetp_ch::` L257

#### standalone_test.s 本線 hook framework (= D-3-b inventory)
- **hook dispatcher**: `pmdneo_part_call_keyon_hook:` L2087 / `pmdneo_part_call_keyoff_hook:` L2092 / `pmdneo_part_call_fnumset_hook:` L2097 / `pmdneo_part_call_volume_hook:` L2102
- **FM hook impl**: `fm_keyon_hook:` L2595 / `fm_keyoff_hook:` L2602 / `fnumset_fm_hook:` L2607 / `fm_volume_hook:` L2616
- **SSG hook impl**: `psg_keyon_hook:` L2674 / `ssg_keyoff_hook:` L2679 / `fnumsetp_ch_hook:` L2684 / `psg_volume_hook:` L2692

#### standalone_test.s ADR-extended FM/SSG routine (= D-3-c inventory、 hook から call される実装本体)
- **FM dispatch impl**: `fnumset_fm:` L758 + `fnumset_fm_porta:` L816 + `fm_keyon:` L987 + `fm_keyoff:` L973 + `pmdneo_fm_voice_set:` L1063 + `pmdneo_fm_write_reg_ch:` L1001 + `pmdneo_fm_voice_set_default:` L1059
- **SSG dispatch impl**: `fnumset_ssg:` L852 + `fnumset_ssg_shift:` L874 + `fnumset_ssg_set:` L880 + `ssg_keyon:` L915 + `ssg_keyoff:` L904 + `init_ssg_voice:` L835

**part workarea + driver_state**: 既存 field は 不可触保護、 軸 B 拡張は 0xFD39-0xFFBF free 領域に placement。 PART_COUNT は standalone 20 を継承 (= D-4)。

軸 B 実装 sprint で **別 routine 並設 + 新規 hook 配線** (= 既存 routine + 既存 hook impl を残しつつ新規追加) で fullscratch driver 構築。 既存 routine + 既存 hook の改変 (= refactor / 削除 / 名前変更) は別 sprint 起票が必要。

### D-10: F-2-B 譲渡軸 current state (= ch3 4-op individual mode、 X/Y/Z parts)

| part | constant | 現状 | ADR-0006 §H 規約 |
|---|---|---|---|
| C (= ch3) | `PART_FM3 = 2` | active (= 通常 4-op operator-shared mode) | 通常 FM dispatch 経由 |
| X (= ch3 op1) | `PART_FM3EXT_X = 17` | **hooks=noop = 当面 mute** | F-2-B integration 範囲 |
| Y (= ch3 op2) | `PART_FM3EXT_Y = 18` | **hooks=noop = 当面 mute** | F-2-B integration 範囲 |
| Z (= ch3 op3) | `PART_FM3EXT_Z = 19` | **hooks=noop = 当面 mute** | F-2-B integration 範囲 |

standalone_test.s L1459 + L1706 literal: 「K (Rhythm) と X/Y/Z (FM3Extend) は常時 init、 hooks=noop で stream 読捨 (= 当面 mute)」 (= ADR-0006 §H literal preserved)。

軸 B β/γ/δ で X/Y/Z integration 設計、 軸 B 実装 sprint で per-op fnum / volume / keyon 実装、 PMD V4.8s PMDPPZ 流儀 (= 100-150 件 if 分岐 + wrapper) reference。

### D-11: MML compiler boundary (= .M / .MN binary format)

```
.mml source
  ↓ PMDDotNETConsole + PMDDotNETCompiler (= vendor、 軸 F Accepted、 軸 B 範囲外)
.M binary (= compiler 出力)
  ↓ pmdneo_load_m:: (= PMD_Z80.inc L414、 ADR-0016 step 4-2)
m_buf header parse + per-part body addr set
  ↓ pmdneo_mn_direct_load_lq_part_addr:: (= standalone_test.s L3921、 ADR-0021/0022)
.PNE filename + part body addr 受領
  ↓
driver runtime (= IRQ.inc::71-81 snd_command_02 + pmd_z80_main PMD_Z80.inc:119 経由 + standalone hook framework dispatch)
  ↓
YM2610 chip register write
```

軸 B replacement scope = **driver runtime 層 (= pmdneo_load_m から chip register write までの間、 PMD_Z80.inc + standalone_test.s 両 file の現役 routine)** で、 compiler 層 (= .M binary 出力契約) には touch しない (= 軸 F Accepted 不可触遵守)。 .M binary format は軸 B 内 不可触契約。

### D-12: 軸 F F-2-A defer 維持確認

F-2-A (= 改造 PMDDotNET compiler の X/Y/Z FM3Extend 文法強制 = `mc.cs` `FM3Extend_set` 改造 10-30 行) は ADR-0044 §決定 5 で「将来 sprint defer」 確定。 軸 B 範囲外 (= compiler 層 touch なし)。

軸 B 内では:
- driver 側 X/Y/Z dispatch (= F-2-B 譲渡軸) は β/γ/δ で integration 設計、 実装 sprint で実装
- compiler 側 X/Y/Z 強制 (= F-2-A) は touch なし

`vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` + `mml_seg.cs` + `m_seg.cs` への変更 = 軸 B 起票 sprint 禁止 + 軸 B 全 sub-sprint α-ε 禁止。

### D-13: 軸 G ADR-0048 driver runtime routine 不可触保護対象

ADR-0048 ε partial complete state で driver runtime に存在する軸 G 関連 routine (= 軸 B 内 不可触保護):

| routine | 行 | 役割 |
|---|---|---|
| `pmdneo_select_adpcmb_ppc_pointer` | 2901 | 軸 G ADR-0048 δ runtime selection proof (= 案 C 部分 runtime parse) |
| `ppc_scratch_start_lsb/msb` / `ppc_scratch_stop_lsb/msb` | 0xFD33-0xFD36 | 軸 G ADR-0048 §決定 8 δ runtime selection scratch |
| `audition_frame_counter_lsb/msb` | 0xFD37-0xFD38 | 軸 G ADR-0048 §決定 8 ε integration test mode (= TEST_MODE_AXIS_G_INT toggle) |

軸 B 内で driver runtime 軸 G 関連 routine + workarea field touch なし (= ADR-0048 Draft state + ε partial complete 維持)。

## Annex E: β interface 候補列挙 (= α 出口 = β 入口、 12 候補)

α driver archaeology findings (= Annex D) base で、 β 「最小設計 + interface 固定」 で 議論すべき interface 候補を 12 件列挙。 β で各候補の boundary / contract / 拡張点を ADR §決定 として固定する。

| # | interface 候補 | 現状 | β 設計対象 | 不可触保護 |
|---|---|---|---|---|
| 1 | FM dispatch routine boundary | PMD_Z80.inc `fmmain::` L1266 (legacy core) + standalone hook framework (`pmdneo_part_call_*_hook` L2087+ → `fm_*_hook` L2595+) + standalone ADR-extended (`fnumset_fm:` L758 等) | fullscratch FM dispatch entry + register write sequence + envelope state (= 並設 routine 追加 / 新規 hook 配線) | 既存 PMD_Z80.inc core + 既存 standalone hook + 既存 ADR-extended (= 並設 only) |
| 2 | SSG dispatch routine boundary | PMD_Z80.inc `pmdneo_psgmain::` L1335 (legacy core) + standalone hook (`psg_*_hook` L2674+) + standalone ADR-extended (`fnumset_ssg:` L852 等) | fullscratch SSG dispatch entry + register write sequence (= 並設 routine 追加 / 新規 hook 配線) | 既存 PMD_Z80.inc core + 既存 standalone hook + 既存 ADR-extended (= 並設 only) |
| 3 | part workarea field layout (= PartWork struct) | standalone `PART_COUNT = 20` × 64 byte = 1280 byte (= ADR-0006 §A 本線、 0xF820-0xFD1F)、 WORKAREA.inc `PART_COUNT = 17` (= legacy 値、 不可触保護) | 拡張 field placement (= 0xFD39-0xFFBF 647 byte free 領域) | 既存 field (= ADR-0021〜0048 で使用中) + standalone 20 part 規約 |
| 4 | IRQ handler interface | `pmd_main` @ IRQ.inc::20 (= 即 ret stub) + pmdneo_play_loop polling | TIMER-B IRQ rate + sub-tick accumulator 統合方針 (= 軸 G ε 切り分け 5 finding 接続点 = ただし ζ defer 維持) | 既存 IRQ flow |
| 5 | chip target flag (= `PMDNEO_TARGET_CHIP`) | ADR-0016 step 1 で 9 commit chain literal 実装済 (= F-3 完了) | build flag による FM 4ch/6ch 切替 (= YM2610 / YM2610B 対応) 維持 | 既存実装全体 |
| 6 | F-2-B integration interface | X/Y/Z = PART_FM3EXT_X/Y/Z = hooks=noop (= mute) | ch3 4-op individual mode register write + per-op fnum/volume/keyon | PART_FM3 既存 dispatch との接続点 |
| 7 | 軸 C ADPCM-B 接続点 | `adpcmb_keyon:` L2794 (= entry) + `adpcmb_keyon_have_sample:` L2829 (= body) + `pmdneo_select_adpcmb_sample_pointer` @ L2949 (= ADR-0043) | FM/SSG main loop からの adpcmb dispatch 呼び出し点 | ADR-0043 routine 全体 |
| 8 | 軸 G ADPCM 動的 sample 供給 接続点 | `pmdneo_select_adpcmb_ppc_pointer` @ L2901 (= ADR-0048 δ partial) | sample_table_id-based selection 経由の sample pointer 取得 | ADR-0048 routine 全体 + ε partial state |
| 9 | rhythm dispatch 接続点 | `pmdneo_rhythm_event_trigger` @ L3535 + `_rhythm_event_*_trigger` (= ADR-0026-0031) | main loop からの rhythm dispatch 呼び出し点 | ADR-0026-0031 routine 全体 |
| 10 | MML compiler 境界 (.M / .MN binary format) | `pmdneo_load_m` @ L414 + `pmdneo_mn_direct_load_*` @ L3921, 4028 (= ADR-0016, 0021, 0022) | MML binary format 仕様 (= compiler 出力契約) 維持 | 軸 F Accepted 不可触 + .M binary format 不可触 |
| 11 | driver_state global field | tempo_d / fade_state / song_ready 等 (= D-5 inventory) | 拡張 field placement (= 0xFD39-0xFFBF free 領域) | 既存 field 全体 |
| 12 | sound command jump table | cmd 0x00-0x05 (= IRQ.inc::40-48) | 軸 B 実装で新規 cmd 追加経路 (= 0x06+ 領域) | 既存 entry 全体 |

### β 設計の重要原則 (= α findings から導出)

1. **並設 only 経路の徹底**: 全 interface 候補で既存 routine の改変 (= refactor / 削除 / 名前変更) 禁止、 新規 routine 並設で proof
2. **PartWork 拡張は free 領域に限定**: 0xFD39-0xFFBF (= 647 byte) を軸 B 拡張 placement 候補とし、 既存 0xF820-0xFD38 layout は不可触
3. **chip register write 順序の byte-identical 維持**: 既存 ADR-0023+ verify gate 流儀踏襲 (= register trace primary gate、 wav sha256 secondary)
4. **軸 G ε partial state 不可触**: 軸 B 実装でも軸 G 関連 routine + workarea field + IRQ rate constant は touch なし (= 軸 G ζ defer 維持)
5. **軸 F Accepted 不可触**: compiler 層 (= vendor PMDDotNET 全 file + .M binary format 契約) touch なし
6. **F-2-A defer 維持**: compiler 側 X/Y/Z 強制 (= mc.cs FM3Extend_set) は β/γ/δ 全段 で touch なし

### β 完了時の deliverable 想定 (= α 出口 = β 入口の link)

β sub-sprint 完了で次の deliverable が ADR-0045 に追加される想定 (= 本 ADR β 段で literal 化):

- Annex F: 12 interface 候補の **boundary + contract + 拡張点** 確定 (= β §決定 として追加)
- §決定 8 新規: fullscratch driver interface design (= FM / SSG / part workarea / IRQ / chip target / F-2-B integration の boundary literal)
- 既存 ADR-0023+ routine 不可触保護方針 literal (= 並設 only 経路 + free 領域 placement の規律確認)

## Annex F: α 段 scope-out 確認 (= 追加 scope-out なし、 α 段で発見した追加保護対象)

α driver archaeology で追加発見した既存資産で、 軸 B 内 不可触保護とすべき項目:

1. **`src/driver/PMD_Z80.inc` 2213 行 legacy nullsound integration** = ADR-0017 §決定 1 で「nullsound-free driver 本線として再評価」 後の legacy file、 標準経路 standalone_test.s と接続点なし、 軸 B では touch なし (= 既 §決定 5 scope-out + non-goal 範囲内、 新規 scope-out 追加なし)
2. **`src/driver/PMDNEO.s` 60 行 legacy entry point** = 同上、 軸 B では touch なし
3. **`vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` 10748 行** = 軸 B Annex B 推定値 8000 行を **actual 10748 行に訂正** (= α 段 finding)、 軸 B 範囲外 reference

scope-in / scope-out / non-goal への追加修正 = なし (= 既 §決定 5 + 共通規律 2 で網羅済)。

## Annex G: 軸 B β 完了 = 最小設計 + interface 固定 (= 37th session β sub-sprint deliverable、 doc-only design sprint)

β sub-sprint 投入 (= 37th session、 user 明示 GO 経由) で α driver archaeology findings (= Annex D 13 sub-section) + α β interface 候補 12 件 (= Annex E) を base に、 fullscratch driver の **最小設計 + interface 固定** を主軸単独で確定 (= driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変、 doc-only design sprint)。

### G-1: 12 interface 候補分類 (= β固定 7 件 + γ defer 1 件 + δ defer 4 件 + 軸 B scope 外 0 件)

α Annex E 12 候補を β 段で 4 bucket に分類。 各候補の boundary は本 §G-2 で literal 化、 後続 γ proof / δ integration / ε Accepted への defer を §G-3 で literal 化。

| # | interface 候補 | bucket | 根拠 |
|---|---|---|---|
| 1 | FM dispatch routine boundary | **β 固定** | 並設 routine entry + register write order を β で確定、 詳細 register write sequence は γ で proof |
| 2 | SSG dispatch routine boundary | **β 固定** | 並設 routine entry + register write order を β で確定、 詳細は γ で proof |
| 3 | PartWork / PART_COUNT 方針 | **β 固定** | standalone PART_COUNT = 20 採用維持 + 拡張 placement 領域 (= 0xFD39-0xFFBF) 確定 |
| 4 | IRQ handler interface | **γ proof まで defer** | β fix: 既存 IRQ flow 維持 (= TIMER-B → nullsound NMI → polling loop → pmd_z80_main)、 γ で minimum register write proof + IRQ rate 確定 |
| 5 | chip target flag (= `PMDNEO_TARGET_CHIP`) | **β 固定** | ADR-0016 step 1 F-3 完了済 = 既存実装維持確認のみ、 軸 B v2 dispatch も同 flag 経由 |
| 6 | F-2-B integration interface | **δ integration まで defer** | β fix: PART_FM3EXT_X/Y/Z 既存 hooks=noop 維持 (= ADR-0006 §H literal preserved)、 δ で sub-axis 分解 + per-op fnum/volume/keyon literal |
| 7 | 軸 C ADPCM-B 接続点 | **δ integration まで defer** | β fix: ADR-0043 routine 不可触保護、 δ で v2 main loop からの呼出経路 literal |
| 8 | 軸 G ADPCM 動的 sample 供給 接続点 | **δ integration まで defer** | β fix: ADR-0048 routine 不可触保護 + ε partial state 維持、 δ で v2 main loop からの呼出経路 literal |
| 9 | rhythm dispatch 接続点 | **δ integration まで defer** | β fix: ADR-0026〜0031 routine 不可触保護、 δ で v2 main loop からの呼出経路 literal |
| 10 | MML compiler 境界 (= .M / .MN binary format) | **β 固定** | 軸 F ADR-0044 Accepted 不可触契約 = 入力契約として β 段で確認、 軸 B 全 sub-sprint で touch なし |
| 11 | driver_state global field | **β 固定** | 既存 field 不可触保護 + 拡張 placement 領域 (= 0xFD39-0xFFBF) 確定、 新規 field 命名規約 |
| 12 | sound command jump table | **β 固定** | 既存 0x00-0x05 不可触 + 新規 0x06+ 領域確認、 cmd 上限 128 entry |

**軸 B scope 外 = 0 件** (= 12 候補は全て軸 B 内で boundary または接続点 literal 化、 F-2-A は ADR-0044 §決定 5 defer 維持 = 軸 B 起票時から scope 外で本 ADR で扱わない、 12 候補に含まれない)。

### G-2: β 最小設計境界 9 領域 (= user 指示 9 領域 + 候補 # link、 各 boundary を ADR §決定 literal 化)

#### G-2-1: FM dispatch boundary (= 候補 #1、 bucket: β 固定)

- **Entry routine 命名**: 新規 `pmdneo_v2_fm_main` (= 仮称、 並設 only、 既存 PMD_Z80.inc `fmmain::` L1266 と並走、 不可触保護)
- **Per-ch loop**: ch1-ch6 sequential dispatch (= chip target flag 経由で YM2610 ch2/3/5/6 active or YM2610B ch1-6 active)
- **Register write order**: PMD V4.8s OPNA 流儀踏襲 (= envelope (TL/AR/DR/SR/RR/SL) → fnum/block → keyon)、 ground truth = `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` `fmmain()` L1216 + standalone_test.s ADR-extended `fnumset_fm:` L758 / `fm_keyon:` L987 / `pmdneo_fm_voice_set:` L1063
- **envelope state**: per-part workarea 既存 field 再利用 (= PART_OFF_NOTE L11 / PART_OFF_VOLUME L9 / 等)、 新規 field 必要時 0xFD39+ 拡張領域 (= G-2-3 参照)
- **既存 hook framework との関係**: 並走維持 (= standalone `fm_*_hook` L2595-L2616 不可触保護)、 v2 dispatch は別 hook 配線 or 別 cmd 経由
- **詳細 register write sequence の確定**: γ proof で literal 化 (= 最小 routine 1 つ proof、 G-3 参照)

#### G-2-2: SSG dispatch boundary (= 候補 #2、 bucket: β 固定)

- **Entry routine 命名**: 新規 `pmdneo_v2_ssg_main` (= 仮称、 並設 only、 既存 PMD_Z80.inc `pmdneo_psgmain::` L1335 と並走、 不可触保護)
- **Per-ch loop**: ch1-ch3 sequential dispatch
- **Register write order**: PMD V4.8s SSG 流儀踏襲 (= envelope → fnum → mixer (tone/noise/mix) → volume → keyon)、 ground truth = `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` `psgmain()` L1645 + standalone_test.s ADR-extended `fnumset_ssg:` L852 / `ssg_keyon:` L915 / `init_ssg_voice:` L835
- **envelope state**: per-part workarea 既存 PSG 5 field (= PART_OFF_ENVF L16 / PAT L17 / PV2 L18 / PR1 L19 / PR2 L20 / ENVVOL L21) 再利用
- **既存 hook framework との関係**: 並走維持 (= standalone `psg_*_hook` L2674-L2692 不可触保護)、 v2 dispatch は別 hook 配線 or 別 cmd 経由
- **詳細 register write sequence の確定**: γ proof で literal 化

#### G-2-3: PartWork / PART_COUNT 方針 (= 候補 #3、 bucket: β 固定)

- **PART_COUNT 採用**: **standalone_test.s L119 `PART_COUNT = 20`** (= ADR-0006 §A 本線、 1280 byte 0xF820-0xFD1F)
- **WORKAREA.inc L32 `PART_COUNT = 17`** (= legacy 値、 軸 B 全 sub-sprint で 不可触保護、 修正禁止)
- **既存 PartWork field layout 不可触保護**: Annex D-4 既存 22 field (= PART_OFF_ADDR/LOOP/LEN/QDATA/QDATB/QDAT2/QDAT3/VOLUME/SHIFT/NOTE/LOOPCNT/LFOSWI/PSGPAT/TIEFLAG/ENVF/PAT/PV2/PR1/PR2/ENVVOL/FLAGS/LOOPSTART/LOOPSTACK_BASE/LOOPDEPTH) 全 不可触保護 (= ADR-0021〜0048 で使用中)
- **拡張 field placement**: 0xFD39-0xFFBF (= 647 byte free 領域) を v2 driver 新規 state 用 placement candidate に確定
- **新規 field 命名規約**: `pmdneo_v2_*` prefix (= 既存 `driver_*` / `part_workarea` と区別)
- **PART_OFF 拡張**: per-part workarea size = PART_WORKAREA_SIZE = 64 byte 固定、 拡張時は別領域 placement (= per-part workarea 拡張は別 ADR 起票で再検討)

#### G-2-4: IRQ handler interface (= 候補 #4、 bucket: γ proof まで defer)

- **β 段 fix**: 既存 IRQ flow 完全維持 (= TIMER-B → nullsound NMI handler → `update_timer_state_tracker` → `state_timer_tick_reached = 1` set → `pmdneo_play_loop` IRQ.inc::74 polling → `pmd_z80_main` PMD_Z80.inc:119 call → per-part main loop dispatch)
- **β 段 不可触保護**: IRQ.inc 全体 (= `pmd_main::` L20 / `cmd_jmptable::` L40 / `snd_command_*` L41-L48 / `pmdneo_play_loop::` L74)、 TIMER-B init constant
- **γ proof で確定**: TIMER-B rate (= 軸 G ε 切り分け 5 finding「6 秒で 2 回」 は軸 G ζ scope、 軸 B 内 touch なし) + minimum register write 経路 proof (= 1 routine の register write が IRQ tick 1 回で完了するか) + v2 dispatch entry の IRQ flow integration 経路
- **軸 G ε ζ defer との関係**: TIMER-B rate 構造改修 = 軸 G ζ scope (= 案 X TIMER-B 改修候補) で行う、 軸 B 内では既存 IRQ rate 維持 + 既存 polling loop の上に v2 dispatch を載せる

#### G-2-5: driver_state global field (= 候補 #11、 bucket: β 固定)

- **既存 field 不可触保護**: Annex D-5 既存 9 group (= `driver_tempo_d/push` / `driver_tempo_48/push` / `driver_psg_noise` / `driver_tieflag` / `driver_song_ready/base/end` / `driver_fade_state/counter/master/speed` / `driver_loop_cycle` / `driver_subtick_acc` / `pmdneo_irq_count` / `scale_step/tick_lo/hi/mode`) 全 不可触保護
- **拡張 field placement**: 0xFD39-0xFFBF 領域 (= G-2-3 と同領域、 PartWork 拡張と共用)
- **新規 field 命名規約**: `pmdneo_v2_*` prefix
- **placement 競合回避**: 0xFD39-0xFFBF 647 byte 領域は PartWork 拡張 (= G-2-3) と driver_state 拡張 (= G-2-5) 共用、 詳細 placement は γ/δ 段で確定 (= sub-region 切り分け literal 化)

#### G-2-6: sound command jump table (= 候補 #12、 bucket: β 固定)

- **既存 entry 不可触保護**: IRQ.inc::40-48 (= cmd 0x00 unused / 0x01 ROM switch / 0x02 play_song / 0x03 reset_driver / 0x04 fade_out / 0x05 play_adpcmb_test) 全 不可触保護
- **新規 cmd placement**: 0x06+ 領域 (= 0x06-0x7F range)
- **cmd 上限**: 128 entry (= `init_unused_cmd_jmptable` macro 慣習、 IRQ.inc::48 padding 経路継承)
- **命名規約候補**: `snd_command_06_play_song_v2` 等 (= 詳細命名は γ proof 段で確定)
- **既存 0x02 play_song 並走**: 軸 B v2 driver が production-ready になるまで Phase 1 PoC base (= 0x02 経路) 並走、 switch 時期は実装 sprint で確定

#### G-2-7: MML compiler 境界 (= 候補 #10、 bucket: β 固定)

- **軸 F ADR-0044 Accepted 完全不可触**: `vendor/PMDDotNET/PMDDotNETCompiler/*.cs` 全 file (= `mc.cs` / `mml_seg.cs` / `m_seg.cs` 等) 軸 B 全 sub-sprint で touch なし
- **入力契約 = .M / .MN binary format**: compiler 出力 binary を driver 入力契約として固定 (= 軸 B 内 binary format 改変なし)
- **受領 entry**: `pmdneo_load_m::` (= PMD_Z80.inc L414、 ADR-0016 step 4-2) + `pmdneo_mn_direct_load_lq_part_addr::` (= standalone_test.s L3921、 ADR-0021/0022) + `pmdneo_mn_direct_load_k_part_addr::` (= standalone_test.s L4028)
- **F-2-A defer 維持**: compiler 側 X/Y/Z 強制 (= `mc.cs` `FM3Extend_set` 改造) は軸 B 全 sub-sprint で touch なし、 ADR-0044 §決定 5 defer 維持

#### G-2-8: F-2-B integration interface (= 候補 #6、 bucket: δ integration まで defer)

- **β 段 fix**: PART_FM3EXT_X = 17 / PART_FM3EXT_Y = 18 / PART_FM3EXT_Z = 19 (= standalone_test.s L116-118) 既存 `hooks=noop` 維持 (= ADR-0006 §H literal preserved「X/Y/Z 駆動 (= FM3Extend) は別 ADR で起票」、 軸 B 範囲を継承)
- **β 段 不可触保護**: standalone L1459 「K (Rhythm) と X/Y/Z (FM3Extend) は常時 init、 hooks=noop で stream 読捨」 literal + L1706 「ADR-0006 §H: X/Y/Z (= FM3Extend) は chip_type=FM 扱い、 hooks=noop」 literal + L1723-L1734 hook install pmdneo5_init_part_hooks_noop 経由配線
- **δ literal 予定**: ch3 4-op individual mode register write + per-op fnum/volume/keyon (= ground truth = PMD V4.8s PMDPPZ 流儀 100-150 件 if 分岐 + wrapper reference)、 PART_FM3 (= ch3) と PART_FM3EXT_X/Y/Z の chip ch3 共有経路
- **F-2-A との完全分離**: 本 F-2-B (= driver 側) は軸 B 内、 F-2-A (= compiler 側) は ADR-0044 §決定 5 defer 維持 (= G-2-7 で確認)

#### G-2-9: 軸 C / 軸 G / rhythm dispatch 接続点 (= 候補 #7/#8/#9、 bucket: δ integration まで defer)

##### G-2-9a: 軸 C ADPCM-B 接続点 (= 候補 #7)

- **β 段 fix**: ADR-0043 routine 完全不可触 (= `adpcmb_keyon:` L2794 entry / `adpcmb_keyon_have_sample:` L2829 body / `adpcmb_keyoff:` L2876 / `pmdneo_select_adpcmb_sample_pointer:` L2949 / voice index table)
- **δ literal 予定**: v2 FM/SSG main loop からの adpcmb dispatch 呼出経路 (= adpcmb_keyon L2794 entry 呼出 + sample_table_id base のため pmdneo_select_adpcmb_sample_pointer 経由)
- **既存 hook framework との関係**: 既存 `adpcmb_*_hook` L2710-L2721 並走維持

##### G-2-9b: 軸 G ADPCM 動的 sample 供給 接続点 (= 候補 #8)

- **β 段 fix**: ADR-0048 routine 完全不可触 (= `pmdneo_select_adpcmb_ppc_pointer:` L2901 + `ppc_scratch_start_lsb/msb` L0xFD33-L0xFD34 + `ppc_scratch_stop_lsb/msb` L0xFD35-L0xFD36 + `audition_frame_counter_lsb/msb` L0xFD37-L0xFD38) + ε partial complete state 完全不可触
- **δ literal 予定**: v2 FM/SSG main loop からの pmdneo_select_adpcmb_ppc_pointer 呼出経路 (= sample_table_id base selection)
- **ADR-0048 Draft 維持**: 軸 B δ で接続点 literal 化しても ADR-0048 改変なし (= Accepted 化禁止、 ζ 未着手維持)
- **軸 G ζ defer との関係**: TIMER-B IRQ rate 改修候補 (= 案 X) は軸 G ζ scope (= 軸 B 内 touch なし、 G-2-4 と整合)

##### G-2-9c: rhythm dispatch 接続点 (= 候補 #9)

- **β 段 fix**: ADR-0026〜0031 routine 完全不可触 (= `pmdneo_rhythm_event_trigger::` L3535 + `_rhythm_event_*_trigger:` L3562-L3760 (= b/s/c/h/t/i 6 drum 種))
- **δ literal 予定**: v2 FM/SSG main loop からの rhythm dispatch 呼出経路 (= pmdneo_rhythm_event_trigger 呼出)
- **既存 hook framework との関係**: K/R part は `pmdneo5_init_part_hooks_noop` 経由 (= standalone L1725 jp dest) + 既存 rhythm dispatch は別経路 = 既存実装維持

### G-3: γ / δ / ε 橋渡し成果物 (= β 出口 = γ/δ/ε 入口、 各段 deliverable literal)

β 完了時点で各後続段への bridging deliverable を literal 化、 後続段着手時に迷わない設計を確立。

#### G-3-1: γ で proof すべきこと (= 候補 #1/#2/#4 詳細確定)

| deliverable | 内容 |
|---|---|
| spike target | 最小 routine 1 つ proof = 例 (a) FM ch1 keyon only / (b) SSG ch1 keyon only / (c) 軸 B v2 entry routine `pmdneo_v2_fm_main` (or `pmdneo_v2_ssg_main`) の skeleton + 1 register write、 候補は γ 着手時 user 判断 + Codex layer 2 review |
| spike 実装 | `scripts/*-spike.py` (= Python standard library only、 仮称 `axis-b-fm-dispatch-spike.py` 等) + 期待 register write sequence emit |
| primary gate | register trace primary gate (= 期待値 vs 既存 driver 実 trace byte-identical 比較、 既存 ADR-0023+ 流儀踏襲) |
| IRQ handler interface 確定 | TIMER-B rate (= 軸 B 内既存維持) + minimum register write が IRQ tick 1 回で完了するか proof + v2 dispatch entry の IRQ flow integration 経路 literal |
| driver source touch | **なし** (= spike は Python のみ、 driver / runtime / compiler / vendor 完全不変、 doc-only filing 規律維持) |
| ADR-0045 反映 | γ section + Annex H (= 新規想定) に proof 結果 literal、 IRQ handler interface 確定 literal |

#### G-3-2: δ で integration すべきこと (= 候補 #6/#7/#8/#9 整合 + sub-axis 分解)

| deliverable | 内容 |
|---|---|
| FM 6ch 全 dispatch integration | ch1-ch6 sequential dispatch literal + chip target flag (= YM2610 ch2/3/5/6 / YM2610B ch1-6) 経由 |
| SSG 3ch 全 dispatch integration | ch1-ch3 sequential dispatch literal |
| F-2-B integration (= 候補 #6) | ch3 4-op individual mode register write + per-op fnum/volume/keyon literal + PART_FM3 と PART_FM3EXT_X/Y/Z の chip ch3 共有経路 literal |
| 軸 C ADPCM-B 接続点 literal (= 候補 #7) | v2 main loop からの adpcmb_keyon L2794 entry 呼出経路 literal + ADR-0043 routine 完全不可触確認 |
| 軸 G ADPCM 接続点 literal (= 候補 #8) | v2 main loop からの pmdneo_select_adpcmb_ppc_pointer L2901 呼出経路 literal + ADR-0048 Draft state + ε partial complete state 完全不可触確認 |
| rhythm dispatch 接続点 literal (= 候補 #9) | v2 main loop からの pmdneo_rhythm_event_trigger L3535 呼出経路 literal + ADR-0026〜0031 routine 完全不可触確認 |
| sub-axis 分解 | FM 6ch / SSG 3ch / F-2-B ch3 4-op / 軸 C 接続 / 軸 G 接続 / rhythm 接続 の sub-axis 分解 + 実装 sprint chain 計画 (= 各 sub-axis 完了判定 + 順序 + verify gate strategy + audio gate strategy) |
| 既存 baseline 保護 | ADR-0023+ baseline byte-identical 維持戦略 literal + 実装 sprint で並設 routine + 新規 hook 配線 only 規律 |
| ADR-0045 反映 | δ section + Annex I (= 新規想定) に integration design literal、 実装 sprint chain 計画 literal |

#### G-3-3: ε で Accepted 判断に必要なこと (= 軸 B 起票 sprint 完了 + 実装 sprint 接続)

| deliverable | 内容 |
|---|---|
| α/β/γ/δ verify gate 全 PASS 確認 | 各 sub-sprint deliverable 整合性確認 (= ADR-0045 Annex D + E + F + G + H + I 完備確認) |
| 既存 ADR-0023+ baseline 不可触確認 | ADR-0016 step 1-18 + ADR-0021〜0032 + ADR-0043 + ADR-0048 routine 改変なし確認 (= git diff stat) |
| 軸 G ε partial complete state 不可触確認 | ADR-0048 Draft 維持 + ζ 未着手 + ε partial complete state 文言維持確認 |
| 軸 F ADR-0044 Accepted 不可触確認 | ADR-0044 改変なし + 軸 F 完成扱い継続確認 |
| F-2-A defer 維持確認 | `vendor/PMDDotNET/PMDDotNETCompiler/*.cs` touch なし確認、 F-2-A 解除なし |
| ADR-0045 Draft → Accepted 移行 | **user 判断 gate** (= 自動 trigger なし、 ε で user 判断仰ぎ) |
| dashboard 軸 B 完了 reflect | 軸予約表 軸 B 行 + 軸別進捗 details + ADR 番号予約簿 0045 + escalation 履歴 |
| 実装 sprint への bridging note | 軸 B 起票 sprint chain 完了後の 軸 B 実装 sprint (= driver source touch sprint) 起票判断 literal (= ε で user 判断 gate、 新規 ADR or 同 ADR 内 sub-sprint) |

### G-4: β 段 規律遵守確認 (= 37th session 維持規律 6 件 + 禁止 9 項目)

β 段で次の規律全遵守:

1. ✅ 軸 G 保留 (= ε partial complete state + ADR-0048 Draft + ζ 未着手 維持、 G-2-9b で literal)
2. ✅ ADR-0048 Draft 維持 (= Accepted 化禁止、 G-2-9b で確認)
3. ✅ ζ 未着手 (= 軸 G ζ scope は 軸 B 内 touch なし、 G-2-4 + G-2-9b で確認)
4. ✅ 軸 G を完成扱いしない (= 本 Annex G 全文で literal「ε partial complete」 「ζ 未着手」 表記維持、 「軸 G 完成」 表現 0 件)
5. ✅ vendor wav 3 件 retain (= untracked 維持、 commit 混入なし)
6. ✅ audio gate 期待音 8 軸詳細記述義務 (= β は doc-only design で audio gate 発動なし、 γ proof 段以降の規律として ADR-0045 §共通規律 6 で literal 化済)
7. ✅ driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変 (= β は doc-only design sprint、 git diff stat で確認)
8. ✅ F-2-A defer 維持 (= G-2-7 + G-2-8 で literal)
9. ✅ ADR-0044 Accepted 不可触 (= G-2-7 で literal)

## Annex H: 軸 B γ 完了 = proof spike target (c) v2 entry skeleton + 1 register write (= 37th session γ sub-sprint deliverable、 Python spike script + register trace primary gate)

γ sub-sprint 投入 (= 37th session、 user 明示 GO 経由) で β Annex G-3-1 spike target 3 候補から **target (c) v2 entry skeleton + 1 register write** を採用 (= Codex layer 2 round 1 approve + 主軸推奨 4 件 + 評価軸 8 件全 PASS)。 Python spike script による proof + register trace primary gate verify を主軸単独で完走 (= driver / runtime / compiler / vendor / vromtool.py / verify fixture data 完全不変、 Python spike script のみ追加)。

### H-1: β retrospective review 結果 record (= Codex 復帰後 retrospective)

β sub-sprint (= PR #53 MERGED ba822cd) は ADR-0041 §決定 6 fallback 主軸単独 approve だったため、 γ 着手前に Codex layer 2 復帰後 retrospective review を実施。

| 項目 | 結果 |
|---|---|
| 主軸 fallback approve 妥当性 | **confirm** (= 追加 must-fix なし、 規律違反 risk なし) |
| G-1 12 候補分類整合性 | **PASS** (= Annex E と integer 整合) |
| G-2 最小設計境界 9 領域 literal 整合性 | **PASS** (= 全網羅 + 「並設 only」 + 「既存不可触保護」 全領域 literal) |
| G-3 γ/δ/ε 橋渡し成果物 | **PASS** (= 後続 sub-sprint で迷わない粒度) |
| 規律遵守 | **PASS** (= 軸 G state 不可触 + ADR-0048 Draft + ζ 未着手 + vendor wav retain + F-2-A defer 維持) |
| nice-to-have 反映時期 judgement | **γ 段で反映** (= 0xFD39-0xFFBF 共用 placement 上限見積もり note を Annex H-7 に記録、 実 allocation 分割は δ integration 側で扱う) |

β fallback approve は妥当、 PR #53 MERGED ba822cd は再 verify 確認済。

### H-2: γ target 選定 review 結果 record

Codex layer 2 round 1 approve = **target (c) v2 entry skeleton + 1 register write 採用**。

#### 主軸推奨理由 4 件 (= Codex 因果整合確認)

1. FM/SSG 本実装前に v2 entry boundary + trace gate を最小で検証 (= β G-2-1/G-2-2 で確定した並設 entry の boundary contract proof)
2. production semantics 不変 (= driver source touch なし、 既存 FM/SSG dispatch に影響しない)
3. driver / runtime 本体改修なし、 Python script のみで収まりやすい (= entry skeleton + 1 register write を Python で table emit 形式で proof 可能)
4. 後続 δ integration の入口として最も汎用的 (= v2 entry interface を δ で FM 6ch / SSG 3ch / F-2-B / 軸 C/G/rhythm 接続 拡張する際の base)

#### 評価軸 8 件比較 (= 主軸推奨確認、 Codex round 1 全 PASS)

| 評価軸 | (a) FM ch1 keyon | (b) SSG ch1 keyon | (c) v2 entry + 1 reg write |
|---|---|---|---|
| 1. β interface 整合 | △ | △ | **◎** |
| 2. production build 影響 | ○ | ○ | **◎** |
| 3. driver / runtime 不可触維持 | ○ | ○ | **○** |
| 4. register trace primary gate 有効性 | △ | △ | **○** |
| 5. δ integration への橋渡し | △ | △ | **◎** |
| 6. regression risk | ○ | ○ | **○** |
| 7. PR 境界 | ○ | ○ | **○** |
| 8. verify gate | ○ | ○ | **○** |

### H-3: spike script 配置 + scope (= Python standard library only)

- **file**: `scripts/axis-b-v2-entry-spike.py` 新規 (= 約 270 行、 standard library only)
- **import 範囲**: `argparse` / `json` / `sys` / `dataclasses` / `typing` のみ (= 標準 module)
- **driver source touch**: なし (= Python spike のみ、 driver / runtime / compiler / vendor / vromtool.py / verify fixture data 完全不変)
- **実行方法**:
  - `python3 scripts/axis-b-v2-entry-spike.py` (= default、 self-test 実行 + 結果 print)
  - `python3 scripts/axis-b-v2-entry-spike.py --json` (= JSON output)

### H-4: v2 entry routine skeleton boundary contract (= Python proof)

#### 入力 / 出力 / 副作用 contract

| 観点 | 内容 |
|---|---|
| 入力 | `PartCtx(part: int, op: int, tl: int)` (= per-part workarea 抽象表現、 part = PART_FM1-6 = 0-5、 op = operator index 0-3、 tl = 7-bit TL field) |
| 出力 | `list[RegisterWrite]` (= 期待 register trace、 本 spike では len == 1) |
| 副作用 | なし (= pure function、 driver source touch なし) |

#### routing rule (= chip port A/B 分岐 contract)

- ch < 3 (= PART_FM1/2/3 = A/B/C) → port A (= 0x04 addr / 0x05 data)
- ch >= 3 (= PART_FM4/5/6 = D/E/F、 YM2610B のみ active) → port B (= 0x06 addr / 0x07 data)

#### register address computation (= TL register addr literal)

- `reg_addr = FM_TL_BASE (= 0x40) + (op * 4) + (part % 3)`
- 例: PART_FM1 (= ch1) op1 → `0x40 + 0 + 0 = 0x40`
- 例: PART_FM3 (= ch3) op2 → `0x40 + 4 + 2 = 0x46`
- 例: PART_FM4 (= ch4) op1 → `0x40 + 0 + 0 = 0x40` (= port B 側で同 layout offset)

### H-5: register trace primary gate spec (= γ verify primary gate)

#### 期待 register trace fixture 3 件 (= spike self-test 内 EXPECTED_TRACE_*)

| fixture | 入力 | 期待 trace |
|---|---|---|
| `EXPECTED_TRACE_CH1_OP1_TL` | `PartCtx(part=0, op=0, tl=0x14)` | `[RegisterWrite(port_addr=0x04, port_data=0x05, reg_addr=0x40, reg_value=0x14)]` |
| `EXPECTED_TRACE_CH4_OP1_TL` | `PartCtx(part=3, op=0, tl=0x20)` | `[RegisterWrite(port_addr=0x06, port_data=0x07, reg_addr=0x40, reg_value=0x20)]` |
| `EXPECTED_TRACE_CH3_OP2_TL` | `PartCtx(part=2, op=1, tl=0x30)` | `[RegisterWrite(port_addr=0x04, port_data=0x05, reg_addr=0x46, reg_value=0x30)]` |

#### invariant 1 件 (= register write count = 1)

- `EXPECTED_REGISTER_WRITE_COUNT = 1` (= target (c) は「1 register write」 と β G-3-1 で確定)
- 全 fixture で `len(trace) == 1` を assert

### H-6: spike self-test 結果 (= ALL PASS = 4/4)

`python3 scripts/axis-b-v2-entry-spike.py` 実行結果:

```
=== 軸 B sub-sprint γ proof spike (= target (c) v2 entry skeleton + 1 register write) ===

ADR-0045 Annex G G-3-1 target (c) per 37th session γ.
Python standard library only. driver source touch なし。

[PASS] ch1_op1_tl_14
[PASS] ch4_op1_tl_20
[PASS] ch3_op2_tl_30
[PASS] register_write_count_invariant

=== γ proof spike: ALL PASS ===
```

### H-7: γ → δ 橋渡し literal (= G-3-2 拡張点 + β nice-to-have 反映)

γ proof spike で確立した v2 entry interface boundary を δ integration で拡張する際の拡張点 literal:

| 拡張点 | δ で literal 化される内容 |
|---|---|
| FM 6ch 全 dispatch | `pmdneo_v2_fm_main_skeleton` を 1 part → 6 part (= ch1-6) sequential dispatch に拡張、 chip target flag 経由で YM2610 ch2/3/5/6 active or YM2610B ch1-6 active 分岐 |
| SSG 3ch dispatch | 別 skeleton `pmdneo_v2_ssg_main_skeleton` (= 仮称) を追加、 SSG register layout (= 0x00-0x0F の SSG-A/B/C tone/noise/mix/volume/envelope) に対応 |
| F-2-B ch3 4-op individual mode | PART_FM3 + PART_FM3EXT_X/Y/Z で chip ch3 共有経路 + per-op fnum/volume/keyon literal |
| 軸 C ADPCM-B 接続点 | v2 main loop から `adpcmb_keyon:` L2794 呼出経路 literal (= ADR-0043 routine 完全不可触) |
| 軸 G ADPCM 接続点 | v2 main loop から `pmdneo_select_adpcmb_ppc_pointer:` L2901 呼出経路 literal (= ADR-0048 Draft state + ε partial complete state 完全不可触) |
| rhythm dispatch 接続点 | v2 main loop から `pmdneo_rhythm_event_trigger::` L3535 呼出経路 literal (= ADR-0026〜0031 routine 完全不可触) |
| sub-axis 分解 + 実装 sprint chain 計画 | verify gate strategy + audio gate strategy + 既存 ADR-0023+ baseline byte-identical 維持戦略 literal |

#### β nice-to-have 反映 = 0xFD39-0xFFBF 共用 placement 上限見積もり note (= H-7 record)

β Annex G-2-3 + G-2-5 で 0xFD39-0xFFBF (= 647 byte free 領域) を **PartWork 拡張 + driver_state 拡張 共用** と定めたが、 γ 段 spike では実 PartWork field 追加していない (= entry skeleton + 1 register write のみ proof)。 δ integration 段で 6ch / 3ch 拡張 + F-2-B + 軸 C/G/rhythm 接続点 literal 時に **placement 上限見積もり** を確定する:

- 仮定: per-part workarea 拡張 = PART_FM3EXT_X/Y/Z (= 3 part × 64 byte = 192 byte) + F-2-B 個別 state (= 推定 32-64 byte) → 約 256 byte 上限見積もり
- driver_state 拡張 = v2 main loop state (= 推定 16-32 byte) + sub-tick refinement (= 推定 8 byte) → 約 64 byte 上限見積もり
- 合計上限 = 約 320 byte (= 647 byte 内、 余裕 327 byte)

実 placement 分割 (= sub-region 切り分け literal) は δ integration 段で確定 (= β nice-to-have を γ Annex H で記録、 実 allocation は δ で確定の 2 段経路)。

### H-8: γ 段 規律遵守確認 9 件 全 PASS

γ 段で次の規律全遵守:

1. ✅ driver / runtime / compiler / vendor / vromtool.py / verify fixture data 完全不変 (= git diff stat で確認、 Python spike + ADR + dashboard のみ追加)
2. ✅ 軸 G ADR-0048 Draft 維持 (= Annex H 全文で literal、 Accepted 化禁止)
3. ✅ 軸 G ζ 未着手 (= γ proof spike 範囲外、 軸 G ζ scope は軸 B 内 touch なし)
4. ✅ 軸 G を完成扱いしない (= 「軸 G 完成」 literal 0 件)
5. ✅ vendor wav 3 件 retain (= untracked 維持、 commit 混入なし)
6. ✅ ADR-0044 Accepted 不可触 (= F-2-A defer 維持、 compiler 層 touch なし)
7. ✅ F-2-A defer 解除なし (= γ proof spike は driver layer entry skeleton で compiler layer 完全不変)
8. ✅ Python standard library only (= argparse / json / sys / dataclasses / typing のみ、 外部依存なし)
9. ✅ register trace primary gate verify (= 3 fixture + 1 invariant、 self-test ALL PASS)

---

## 改訂履歴

| 日付 | 状態 | 内容 |
|---|---|---|
| 2026-05-19 | Draft 起票 | 37th session 主軸推奨 + Codex layer 2 round 1 approve 経由起票、 軸 G ζ 保留 + 他軸候補整理 + 候補 α 軸 B 採用、 ADR-0044 §F-2-B 譲渡継承 + F-2-A defer 維持 + ADR-0048 Draft state 不可触、 5 段 α/β/γ/δ/ε 構成、 doc-only filing |
| 2026-05-19 | Draft α 完了 (= 37th session α sub-sprint) | driver archaeology + Phase 2 scope 確定 = Annex D (= driver archaeology findings 13 sub-section、 src/driver/ 9 file 6777 行 + vendor 14 file 20130 行 inventory + standalone_test.s routine map + WORKAREA SRAM layout + driver_state global field + IRQ flow + snd_command jump table + ADR-0016〜0048 routine 不可触保護対象 + FM/SSG replacement target literal + F-2-B X/Y/Z current state + MML compiler boundary + F-2-A defer 維持 + 軸 G ADR-0048 routine 不可触保護) + Annex E (= β interface 候補 12 件 + β 設計 6 原則 + β 完了 deliverable 想定) + Annex F (= α 段 scope-out 確認、 追加 scope-out なし)、 Annex B 行数訂正 (= PMD.cs 推定 8000 → actual 10748 行)、 doc-only investigation で driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変、 vendor wav 3 件 untracked retain 維持 |
| 2026-05-19 | Draft β 完了 (= 37th session β sub-sprint) | 最小設計 + interface 固定 = Annex G (= G-1 12 interface 候補分類 = β 固定 7 件 + γ defer 1 件 + δ defer 4 件 + 軸 B scope 外 0 件 / G-2 β 最小設計境界 9 領域 = FM dispatch / SSG dispatch / PartWork PART_COUNT / IRQ handler / driver_state / sound command jump table / MML compiler / F-2-B integration / 軸 C 軸 G rhythm 接続点 / G-3 γ/δ/ε 橋渡し成果物 = γ proof / δ integration / ε Accepted 判断 / G-4 β 段 規律遵守確認 9 件 全 PASS)、 doc-only design sprint で driver / runtime / compiler / vendor / vromtool.py / verify script / fixture data 完全不変、 vendor wav 3 件 untracked retain 維持、 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 不可触維持、 ADR-0044 Accepted + F-2-A defer 不可触維持 |
| 2026-05-20 | Draft γ 完了 (= 37th session γ sub-sprint) | proof spike target (c) v2 entry skeleton + 1 register write = Annex H (= H-1 β retrospective review confirm = ADR-0041 §決定 6 fallback approve 妥当 / H-2 γ target 選定 = Codex layer 2 approve + 主軸推奨理由 4 件 + 評価軸 8 件全 PASS / H-3 spike script `scripts/axis-b-v2-entry-spike.py` 約 270 行 Python standard library only / H-4 v2 entry routine skeleton boundary contract = 入力 PartCtx + 出力 list[RegisterWrite] + pure function / H-5 register trace primary gate spec = 3 fixture (CH1_OP1_TL/CH4_OP1_TL/CH3_OP2_TL) + 1 invariant (register_write_count = 1) / H-6 spike self-test ALL PASS = 4/4 / H-7 γ → δ 橋渡し literal + β nice-to-have 反映 = 0xFD39-0xFFBF 共用 placement 上限見積もり 約 320 byte / 647 byte / H-8 γ 段 規律遵守確認 9 件 全 PASS)、 Python spike script 追加 + ADR-0045 + dashboard のみ変更で driver / runtime / compiler / vendor / vromtool.py / verify fixture data 完全不変、 vendor wav 3 件 untracked retain 維持、 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 ADR-0044 Accepted + F-2-A defer 完全不可触 |
