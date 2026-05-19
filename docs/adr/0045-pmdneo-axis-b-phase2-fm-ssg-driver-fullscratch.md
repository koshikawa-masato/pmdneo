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
| **α** | driver archaeology + Phase 2 scope 確定 | 既存 PMDDotNETDriver (= `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` + `PMD.cs` + `PCMDRV.cs` + `PCMLOAD.cs` + `PPZDRV.cs` + `EFCDRV.cs` + `OPNATimer.cs` ground truth、 FM/SSG dispatch routine は driver.cs/PMD.cs 内に統合配置 = 別 file 派生なし) reference + `src/driver/standalone_test.s` 本線 FM/SSG 部分 inventory + Phase 2 fullscratch boundary literal 化 (= 何を replace、 何を保護) + F-2-B ch3 4-op 既存 PMDPPZ 流儀 reference + ADR Annex 化 | 主要 routine pattern reference + 既存 driver inventory (= FM 6ch dispatch / SSG 3ch dispatch 現状) + boundary literal + driver source touch なし、 doc-only | なし |
| **β** | 最小設計 + interface 固定 | α inventory base で fullscratch driver interface 設計 (= FM/SSG dispatch routine 境界 + register write sequence + chip target flag 接続 + 既存 ADR-0023+ routine 不可触保護方針 + F-2-B ch3 4-op integration 経路) + ADR §決定 追加 | interface 設計 ADR 追加 + 既存 routine 不可触 literal 確認 + F-2-B 統合点 literal、 driver source touch なし | 設計のみ |
| **γ** | proof / spike (= 最小 routine 1 つ proof) | β interface design を **Python spike script** (= standard library only、 `scripts/*-spike.py`) で proof + 期待 register write sequence literal + 既存 driver behavior と byte-identical 比較 (= register trace primary gate、 spike script が emit する期待値 vs 既存 driver の実 trace) | Python spike script 実装 + register trace 期待値一致 + 既存 ADR-0023+ baseline byte-identical 維持 + **driver source touch なし** (= spike は Python のみ、 driver source は α-δ 全段で完全不変) | なし (= spike script のみ) |
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

---

## 改訂履歴

| 日付 | 状態 | 内容 |
|---|---|---|
| 2026-05-19 | Draft 起票 | 37th session 主軸推奨 + Codex layer 2 round 1 approve 経由起票、 軸 G ζ 保留 + 他軸候補整理 + 候補 α 軸 B 採用、 ADR-0044 §F-2-B 譲渡継承 + F-2-A defer 維持 + ADR-0048 Draft state 不可触、 5 段 α/β/γ/δ/ε 構成、 doc-only filing |
