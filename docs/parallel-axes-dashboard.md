# PMDNEO 併走軸 dashboard

ADR-0041 §決定 7 で確立した一元管理 dashboard。 主軸 (= Claude Code 親 session) が write、 sub-agent は **read のみ** (= context 参照、 write は主軸経由)。 各軸の状態 / Codex session ID / ADR 番号予約 / escalation 履歴を literal 管理。

**doc-governance**: AI 協働用 dashboard (= memory `feedback_doc_governance_two_systems.md` 規律遵守、 ground truth として扱う)、 人間向け公開 docs ではない。 修正は主軸が行い、 sub-agent prompt は本 dashboard を context として read。

## 軸予約表

| 軸 | branch | 予約 ADR 番号 | 状態 | 直近 commit | 直近 Codex review | 次の user 関与 |
|---|---|---|---|---|---|---|
| **0 (= orchestration setup)** | `wip-orchestration-setup` (= MERGED) + `wip-orchestration-retrospective-fix` (= 本修正 commit) | 0041 | **完了** (= α/β/γ/δ + retrospective fix) | 82b9378 (= γ dashboard) + PR #14 MERGED 8d36113 + 本 retrospective fix commit | round 1 revise → must-fix 反映 → round 2-4 fallback approve → **round 5 Codex retrospective revise (= dashboard lifecycle 更新漏れ 1 件) → 本 commit で fix** | (= 完了、 軸 A/C/F sub-agent 並走起動済) |
| **A (= sample provenance β)** | `wip-axis-a-sample-provenance` (= α + β-1 commit、 PR #17 MERGED + PR #20 OPEN) | 0042 | **β-1 完了** (= 63d3b09、 §決定 2 採用案 A mixer 構造 6 levers literal + 案 B reject 経緯 + Codex layer 2 引用 + β-2 戦略 = individual sweep + clipping gate) | 63d3b09 (= β-1 commit 90 行 diff = 48 ins + 42 del) | layer 1 session 019e3b57-... β-1 round 1 revise → approve + layer 2 session 019e3b50 採用案 A approve | β-2 spike `audible-level-sweep-spike.py` 新規作成予定 (= 主軸 or sub-agent guard 付き) |
| **C (= ADPCM-B 軸)** | `wip-axis-c-adpcmb` (= sub-agent C 経由作成 + push 済) | 0043 | **α 完了** (= approve、 設計判断単一明確、 β sub-sprint 起動可) | a3a162d (= ADR-0043 起票 254 行) | session 019e3b56-...、 round 1 revise → round 2 revise → round 3 approve | β sub-sprint で audition gate + machine verify |
| **F (= MML compiler 拡張)** | `wip-axis-f-mml-extension` (= sub-agent F 経由作成 + push 済) | 0044 | **α 完了** + **採用案 (ii) 軸 F 全体 scope-out** (= Codex 判断 session 019e3b50 147s、 主軸推奨と一致)、 ADR-0044 Accepted 移行予定 (= F-2-A 将来 defer + F-2-B 軸 B 譲渡)、 F-3 は ADR-0016 step 1 で完了済 | 5317de1 (= ADR-0044 起票 382 行) | layer 1 session 019e3b57-f438-... round 3 approve + **layer 2 session 019e3b50 案 ii 採用 approve** | (= 軸 F 完成扱い、 F-2-A は将来 sprint defer) |

## 後続軸 候補 (= ADR 0045+ 予約候補)

| 軸 | 内容 | 予約 ADR | 開始予定 |
|---|---|---|---|
| B (= Phase 2 FM/SSG driver フルスクラッチ) | scope 最大、 軸 F MML 文法拡張に依存 | 0045 候補 | 軸 F 進行後 |
| D (= WebApp 最小骨格) | 別 stack 軸、 backend で軸 C/F に依存 | 0046 候補 | 軸 C/F 安定後 |
| E (= IPL / プレイヤー V1) | 単独 binary、 driver 完成後 | 0047 候補 | リリース直前 |

## Codex session ID 一覧

| 用途 | session ID | 起動主 | 起動条件 |
|---|---|---|---|
| **統合判断 (= layer 2 主軸 ↔ Codex)** | `019e3425-3327-74e1-95bc-461cc5d0af66` | 主軸 起動 | 複数 sub-agent return 統合 / 軸間衝突 / ground truth 矛盾 / 設計判断複数案 |
| 軸 0 規律確立 review (= 例外、 layer 2 流用) | `019e3425` 流用 | 主軸 起動 | 軸 0 = 規律確立 = 統合判断系性質 |
| 軸 A sub-agent ↔ Codex (= layer 1) | `019e3b57-08c0-7e42-a78f-7091f4fe382a` (= 取得済、 round 2 approve) | sub-agent 内自律 | commit 直前 review |
| 軸 C sub-agent ↔ Codex (= layer 1) | `019e3b56-2f9c-7941-9704-2bb689d98e64` (= 取得済、 round 3 approve) | sub-agent 内自律 | commit 直前 review |
| 軸 F sub-agent ↔ Codex (= layer 1) | `019e3b57-f438-7800-aa07-7e4f65971486` (= 取得済、 round 3 approve) | sub-agent 内自律 | commit 直前 review |

## ADR 番号予約簿

| 番号 | 軸 | 状態 | 備考 |
|---|---|---|---|
| 0041 | 軸 0 (= orchestration setup) | **起票済** (= b205716) | Claude Code 併走運用 ADR (= 主軸 + sub-agent + Codex 2 段壁打ち + fallback 規律) |
| 0042 | 軸 A (= sample provenance β) | 予約 | ADR-0033 β sub-sprint 設計 ADR (= mixer 構造 or .fxp gain) |
| 0043 | 軸 C (= ADPCM-B 軸) | 予約 | ADPCM-B 新規軸 設計 ADR (= Step 4 の上に立つ runtime-managed architecture) |
| 0044 | 軸 F (= MML compiler 拡張) | 予約 | MML 拡張 sub-軸 設計 ADR (= F-1 voice buffer / F-2 X/Y/Z 文法 / F-3 chip target flag) |
| 0045+ | B / D / E 候補 | 予約候補 | 後続軸用 |

## escalation 履歴

| 日時 | 軸 | escalation 種別 | fallback / Codex 経由 | 解決方針 | retrospective review 状態 |
|---|---|---|---|---|---|
| 2026-05-18 | 軸 0 α | layer 2 hang (= Codex runtime `task-mpb6938b-z2y3pw` 解放されず、 background + foreground 2 度試行後 hang) | fallback (= 主軸単独評価 approve) | ADR-0041 b205716 commit + push 進行 (= must-fix 3 + nice-to-have 4 + §決定 4-2/4-3 反映済) | **reviewed: approve** (= Codex retrospective、 fallback 妥当性 OK + ground truth 整合 OK) |
| 2026-05-18 | 軸 0 β | layer 2 hang (= 同 task 解放されず、 3 回連続 hang) | fallback (= 主軸単独評価 approve) | memory + CLAUDE.md + MEMORY.md literal 化進行 (= 全 user 個人 file、 commit なし sprint) | **reviewed: approve** (= Codex retrospective、 doc-governance 遵守 OK + user 4 要望反映 OK) |
| 2026-05-18 | 軸 0 γ | layer 2 hang (= 4 回連続 hang、 同 task 解放されず) | fallback (= 主軸単独評価 approve) | dashboard 作成 commit + push 進行 (= ADR-0041 §決定 7 仕様 + sub-agent context 調査結果 literal 反映) | **reviewed: revise** (= dashboard lifecycle 更新漏れ 1 件 = 軸 0 状態 / sprint γ / δ / retrospective 状態 「pending」 「着手中」 「未着手」 のまま、 PR #14 merged 後の現状反映なし → 本 retrospective fix commit で 4 箇所更新) |
| 2026-05-18 | 軸 0 retrospective fix | (= Codex retrospective review 復帰、 layer 2 175 秒で正常 response) | Codex 経由 (= revise 反映済 = 本 commit) | dashboard lifecycle 更新 (= 軸 0 完了状態 + sprint γ/δ 完了 + retrospective approve/revise/approve literal) | reviewed: approve (= 本 commit が retrospective revise を解消) |
| 2026-05-18 | 軸 A α | design_judgment_needed (= sub-agent A return、 2 案 mixer 構造 vs .fxp gain、 user 判断 scope) | Codex 経由 (= layer 1 session 019e3b57-... round 2 approve、 1 案決定禁止規律遵守) | 主軸経由 user 上げ pending = 越川氏に 2 案 + 8 軸 trade-off 提示 + 判断仰ぎ | n/a (= user 判断後に進行) |
| 2026-05-18 | 軸 C α | approve (= sub-agent C return、 設計判断単一明確) | Codex 経由 (= layer 1 session 019e3b56-... round 3 approve) | β sub-sprint 起動可 (= 主軸経由 user GO 待ち or 即時 sub-agent 起動) | n/a (= approve、 retrospective 不要) |
| 2026-05-18 | 主軸 cwd 干渉 | worktree isolation 副作用 (= sub-agent isolation worktree 起動で本 worktree cwd が agent-ad71e73589d7ac9a7/ に切り替わり、 ADR-0042 file が本 worktree に重複展開) | 主軸単独復旧 (= cd 本 worktree + 重複 file rm + branch 状態確認) | 復旧完了、 軸 A/C/F 影響なし | unexpected_finding として memory に追加候補 |
| 2026-05-18 | 軸 F α | design_judgment_needed (= sub-agent F return、 3 案 F-2-A 着手 / 軸 F 全体 scope-out / F-2-A+F-2-B 統合、 主軸推奨 案 ii 全体 scope-out) | Codex 経由 (= layer 1 session 019e3b57-f438-... round 3 approve、 1 案決定禁止規律遵守) | 主軸経由 user 上げ pending = 越川氏に 3 案 + F-3 完了済 finding + 主軸推奨理由 6 件提示 + 判断仰ぎ、 重要 finding = F-3 chip target flag は ADR-0016 step 1 で 9 commit chain literal 実装済 (= sub-agent F が vendor grep で発見、 軸 F 状態認識更新) | n/a (= user 判断後に進行) |
| 2026-05-19 | 軸 A/F 採用案決定 | Codex layer 2 統合判断 (= user 「Codex 確認後 GO」 委譲、 task-mpb6938b cancel + queue 解放後 147s で正常 response、 軸 A=A mixer 構造 + 軸 F=ii scope-out 採用) | Codex 経由 (= layer 2 session 019e3b50-8f23-...) | 軸 A β-1 sub-agent 起動準備 (= 案 A literal + individual sweep + clipping gate) + 軸 F ADR-0044 Accepted 移行 (= F-2-A defer + F-2-B 軸 B 譲渡) | n/a (= 採用案確定、 進行中) |
| 2026-05-19 | 5 step 計画 review | revise → 修正 (= must-fix 3 件 = mergeability gate + Accepted commit 先 + 並列 NG) → approve (= 70s) | Codex 経由 (= layer 2 session 019e3b50-...) | 修正版 7 sub-step 計画で即時 GO | n/a (= approve、 進行中) |
| 2026-05-19 | 軸 A β-1 isolation finding | **unexpected_finding + merge_conflict + discipline_violation_risk** = sub-agent ab197eb5b34dac35e の isolation worktree が prompt 期待 branch (= wip-axis-a-sample-provenance HEAD 07b4979) ではなく `worktree-agent-...` 自動 branch (= base HEAD 3ad1e23) で切られ、 ADR-0042 file 不存在 → sub-agent が絶対 path で本拠地 file Edit 越境 → 138 行 diff 漏れ (= commit せず) | fallback 主軸単独 (= ADR-0041 §決定 4-3) = 本拠地 diff revert + wip-axis-a- rebase 確認 + patch apply + Codex layer 1 代理 review session 019e3b57-... round 1 revise (= must-fix 2 = vendor untracked + diff stat 実測値) → approve + commit 63d3b09 + push + PR #20 作成 | reviewed: approve + memory 追加 = `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= preflight 9 件 guard、 全 sub-agent 起動 prompt で必須) |
| 2026-05-19 | 軸 A β-1 完了 | n/a | Codex layer 1 + layer 2 両 approve (= 採用案 A + β-1 update + 主軸 fallback で復旧) | PR #20 OPEN merge 待ち、 後続 β-2 spike 新規作成 | n/a |

## 軸別進捗 details

### 軸 0 (= orchestration setup)

| sprint | 状態 | commit | 内容 |
|---|---|---|---|
| α | 完了 | b205716 | ADR-0041 起票 (= §決定 1-10 + §決定 4-2 + §決定 4-3 + §決定 7 拡張、 511 行) |
| β | 完了 (= commit なし) | - | memory 2 + CLAUDE.md + MEMORY.md literal 化 (= 全 user 個人 file、 .gitignore 除外) |
| γ | 完了 | 82b9378 | dashboard `docs/parallel-axes-dashboard.md` 新規作成 (= 約 130 行) |
| δ | **完了** | PR #14 MERGED (= 8d36113) | PR #14 作成 + 本拠地 merge 完了 |
| retrospective fix | **完了** (= 本 commit) | 本 commit hash | Codex retrospective review revise 反映 = dashboard lifecycle 6 箇所更新 (= 軸 0 状態 + γ/δ sprint + retrospective 3 行 + retrospective fix 行追加) |

### 軸 A (= sample provenance β)

| sprint | 状態 | commit | 内容 |
|---|---|---|---|
| context 調査 | 完了 (= sub-agent A) | - | ADR-0033 §π15.14 reject 原因 (= peak -25 dBFS) + 退避 4 artifact `/private/tmp/pmdneo-plan-a-rejected/` 確認 |
| α | 完了 (= PR #17 MERGED) | b6dbc0d | ADR-0042 起票 349 行 (= 2 案併記、 Codex round 2 approve) |
| **β-1** | **完了** (= 63d3b09 + PR #20 OPEN) | 63d3b09 | §決定 2 採用案 A mixer 構造 6 levers literal + 案 B reject 経緯 + Codex layer 2 引用 + β-2 戦略 literal (= individual sweep + clipping_count == 0 hard gate)、 90 行 diff = 48 ins + 42 del、 主軸 fallback 経由 (= sub-agent isolation finding 発生) |
| β-2/β-3/β-4/γ/δ | 未着手 | - | β-2 軸 A 専用 spike scripts/audible-level-sweep-spike.py 新規作成 (= individual sweep + clipping gate) → β-3 layer 1 PASS candidate → β-4 escalate audit_gate → γ BD authoring chain integration → δ Accepted + 1 PR 本拠地 merge |

### 軸 C (= ADPCM-B 軸)

| sprint | 状態 | commit | 内容 |
|---|---|---|---|
| context 調査 | 完了 (= sub-agent C) | - | ADPCM-B Step 4 既実装 (= keyon/keyoff/volume/chromatic table 24 byte) + driver structure (= standalone_test.s 3736 行) + PMDPPZ 流儀 (= PCMDRV.cs 1063 行) |
| α | **完了** (= sub-agent C return、 approve、 escalate なし) | a3a162d | ADR-0043 起票 254 行 (= ADPCM-B 1ch runtime-managed architecture、 sub-sprint α/β/γ/δ 4 段、 sample selection arch = ADPCM-A `sample_table_id` 共用 + `pmdneo_select_adpcmb_sample_pointer` 新規 routine、 .PPC driver parse = ADR-0048 候補別 ADR defer、 build-time samples.inc 拡張で multi-sample、 Codex round 3 approve) |
| β/γ/δ | β sub-sprint 起動可 | - | J part sample 切替 fixture → runtime sample selection arch → integration |

### 軸 F (= MML compiler 拡張)

| sprint | 状態 | commit | 内容 |
|---|---|---|---|
| context 調査 | 完了 (= sub-agent F) | - | 現役 PMDDotNETConsole (= .mml→.M 1 本化) + sub-軸 F-1/F-2/F-3 候補 + 自前 compile.py 凍結 (= ADR-0014 §B) |
| α | **完了** (= sub-agent F return、 escalate `design_judgment_needed` pending user 判断) | 5317de1 | ADR-0044 起票 382 行 (= 軸 F 3 案併記 = (i) F-2-A 着手 / (ii) 全体 scope-out / (iii) F-2-A+F-2-B 統合、 重要 finding = F-3 は ADR-0016 step 1 で 9 commit chain literal 実装済 sub-agent F vendor grep 発見、 F-1 は scope-out 推奨 256 voice 実用十分、 F-2 は compiler 側 F-2-A + driver 側 F-2-B = ADR-0008 候補軸 B 範囲に分離可能、 主軸推奨 案 ii 全体 scope-out 6 根拠、 Codex round 3 approve) |
| β/γ/δ | user 判断後 | - | 案 (i) 採用なら F-2-A compiler 側 X/Y/Z 強制 / 案 (ii) なら ADR-0044 = 軸 F 状態整理 ADR として軸 F 完成扱い / 案 (iii) なら F-2-A+F-2-B 統合 sub-sprint (= 軸 F + 軸 B 兼用、 user 明示許可必要) |

## 主軸介入手順 (= ADR-0041 §決定 5 + §決定 4-3 fallback)

1. sub-agent return 受領 (= status = approve / escalate / partial)
2. status = **approve** = 最終 verify (= diff + 規律遵守 check + escalation 履歴更新不要) → memory + dashboard 更新
3. status = **escalate** = 状況把握 + 解決方針決定 (= 規律解釈 / user 判断仰ぎ / 主軸直接介入) → sub-agent 再 task or 主軸介入 → dashboard escalation 履歴 literal 記録
4. **Codex runtime hang** = fallback 主軸単独評価 + escalation 履歴 literal 記録 + retrospective review pending
5. dashboard 更新 (= 直近 commit / Codex review / escalation 履歴 / 軸別進捗)

## sub-agent prompt template 必須読み込み (= dashboard read 規律)

各 sub-agent 起動時に dashboard を **必読 context** として指定:

- 軸予約表 = ADR 番号 + branch 名の literal (= 主軸予約値を確認、 sub-agent 内で別番号を選ばない)
- Codex session ID 一覧 = layer 1 軸別 session ID 取得 / 統合判断 session 流用判断
- ADR 番号予約簿 = 起票時の番号競合回避
- escalation 履歴 = 過去 fallback 経緯 + retrospective review 状態

## 関連 ADR + memory

- **ADR-0041** (= 母 ADR、 §決定 7 で本 dashboard 構造仕様)
- memory `feedback_parallel_axis_orchestration.md` (= 規律 10 件、 dashboard 運用基盤)
- memory `feedback_subagent_codex_loop_with_escalation.md` (= sub-agent ↔ Codex 詳細、 escalation 6 種 + return format)
- memory `feedback_explanation_style.md` (= dashboard 内表 + 平易日本語 6 構造規律)
- memory `feedback_doc_governance_two_systems.md` (= AI 協働用 dashboard、 人間向け公開 docs として扱わない)
- memory `feedback_codex_review_autonomous_no_user_judgment` (= layer 1 Codex 壁打ち継承元)
- memory `feedback_codex_implementation_review.md` (= 3 重 zero-trust review 規律源)
