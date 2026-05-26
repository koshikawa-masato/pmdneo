# ADR-0065: PMDNEO roadmap ⑥ audition ADR (= 越川氏 audition gate、 aesthetic gate、 production-ready 経路 audition session approve)

- 状態: **Draft** (= 2026-05-25 40th session、 ADR-0068 Accepted + ε retrospective fix 完走後の roadmap ⑥ 起票、 ADR-0064 §決定 7 番号予約消化、 doc-only 起票 PR1 = ADR-0067 起票 pattern 継承、 Codex layer 2 plan review 1 round approve plan v1 = must-fix 0 + nice-to-have 1 件 (= PR5 wav repo 外 artifact 配置明記) + latent risk 1 件 (= ADR-0069 parallel 起票時 sha256 維持運用順序明記) 全反映、 越権操作なし confirmed、 集約 HEAD `037cd3e`、 sub-sprint chain α/β/γ/δ/ε 起票 5 段 plan literal、 δ で user 介入 mandatory、 agentId `afbed0b24a60caa41`)
- 起票日: 2026-05-25
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0056** (= production-ready 選定 ADR、 §決定 3-b 最終 gate audition approve literal = production-ready 4 gate のうち (d)、 line 79-83)
  - **ADR-0063** (= production-ready 4 gate status 確認、 §(d) 越川氏 audition gate 定義 + status partial 達成 + 確認方法 + 達成判定根拠、 line 113-122 + roadmap ⑥ 起票判断 material)
  - **ADR-0064** (= roadmap ⑤ 統合 verify plan ADR、 §決定 7 番号 chronology rationale = ADR-0065 roadmap ⑥ 番号予約)
  - **ADR-0067** (= ADR-0064 §決定 7 ADR-0067+ 実作業群 1 本目、 16 ch fixture 拡張完了、 残課題 enumeration ADR-0065 候補 scope literal、 line 677-683)
  - **ADR-0068** (= ADR-0064 §決定 7 ADR-0067+ 実作業群 2 本目、 §決定 1(d) audition gate scope-out + §決定 6 「(d) audition gate 未実装 = ADR-0065 候補 future」 併記必須 9 件の 1 つ + §決定 9 ADR-0065 候補 = roadmap ⑥ audition、 起票判断 user 明示 GO 必須)
  - **ADR-0058** (= roadmap ② song parse + IRQ tick、 production-ready 経路前提条件)
  - **ADR-0059** (= roadmap ③ ADPCM-B/rhythm 実 dispatch、 production-ready 経路前提条件)
  - **ADR-0043** (= 軸 C ADPCM-B audition approve、 partial 達成 evidence)
  - **ADR-0048** (= 軸 G dynamic supply 完成、 ζ-δ-2 audition、 partial 達成 evidence)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 + §決定 4-3 fallback regime + §決定 5 escalation `audit_gate` literal)
- 関連 memory:
  - `feedback_relative_preference_vs_absolute_acceptance.md` (= acceptance framework 3 軸独立 schema literal、 pairwise + individual + 全 reject)
  - `feedback_preference_learning_beats_metric_correlation.md` (= preference learning 規律、 metric ≠ preference)
  - `feedback_metric_pass_is_not_aesthetic_pass.md` (= metric pass ≠ aesthetic pass、 human aesthetic gate is authoritative)
  - `feedback_ai_engineering_gate_before_human_audition.md` (= AI engineering 検査 → human aesthetic audition 順序固定)
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 / 「production-ready 全体達成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal 強調)
  - `project_pmdneo_adr_0068_initiated.md` (= ADR-0068 Accepted + ε retrospective fix 完走 milestone + ADR-0065 候補 dependency)

## 背景 (= why now)

### ADR-0068 Accepted + ε retrospective fix 完走 milestone 達成 (= roadmap ⑤ 統合 verify 完了)

40th session (= 2026-05-25) で ADR-0068 ε PR #138 MERGED at `c118532` + ε retrospective fix PR #139 MERGED at `037cd3e` 完走。 ADR-0068 Accepted milestone 達成 = roadmap ⑤ 統合 verify 完了 (= 併記必須 9 件)。 ADR-0064 plan 実作業群 (= ADR-0067 + ADR-0068 chain) 完了。

ただし併記必須 9 件の 1 つ「(d) audition gate 未実装 = ADR-0065 候補 future」 が残る。 production-ready 4 gate (= ADR-0056 §決定 3) のうち (a)(b)(c) 3 gate = ADR-0068 ε で達成、 (d) audition gate = 未実装 = 本 ADR-0065 scope。

### user 明示 GO「ADR-0065 が自然な次」

40th session ADR-0068 retrospective fix 完走後の next 候補確認 (= AskUserQuestion option 1) で user 明示 GO「ADR-0065 起票判断進める = roadmap ⑥ audition、 production-ready 本線」 受領。 推奨順 = (1) ADR-0065 起票判断 + (2) ADR-0069 起票判断 (= parallel 可) + (3) ADR-0066 (= ADR-0065 Accepted 後 future)。

### (d) 越川氏 audition gate = production-ready 経路 audition session approve

ADR-0063 §(d) literal「production-ready 経路 (= v2 driver 経路 = cmd 0x05 + pmdneo_song_main → v2 dispatcher 全 ch 統合) で実 MML song を audio render + 越川氏 audition session + judgment」 = ADR-0065 scope の中核。 status = partial 達成 (= production-ready 経路 audition 未実施、 partial = ADR-0043 軸 C ADPCM-B audition + ADR-0048 ζ-δ-2 軸 G dynamic supply audition + ADR-0058/0059 部分達成)。

### CLAUDE.md §設計書ファースト遵守 + ADR-0041 §決定 4-2/4-3 Codex rescue 化 + fallback default 永続化

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 本 ADR-0065 を roadmap ⑥ audition ADR として起票。 Codex layer 2 plan review 1 round approve (= must-fix 0 + nice-to-have 1 + latent risk 1) 完了下、 全 finding ADR doc 本文に literal 反映。

ADR-0041 §決定 4 規律 (= 主軸 ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化 + ADR-0041 §決定 4-3 主軸 fallback default 規律 (= 40th session ε で full cycle 完走実証済) 下で起票。 Codex layer 2 review-only + commit / branch / merge 禁止 + merge は main agent 経路のみ literal 遵守 (= 冒頭 6 件 literal 強調 prompt 経由)。

## 決定

### 決定 1: ADR-0065 = (d) 越川氏 audition gate ADR (= roadmap ⑥ audition)

ADR-0065 scope = **(d) 越川氏 audition gate = production-ready 経路 (= v2 driver 経路 = cmd 0x05 + pmdneo_song_main → v2 dispatcher 全 ch 統合) audio render + 越川氏 audition session + judgment**。

- ADR-0056 §決定 3-b literal「最終 gate = 越川氏 audition approve 必須」 整合
- ADR-0063 §(d) literal「production-ready 経路 audition session 未実施 = audition session 別 sprint 起票判断必要 = roadmap ⑥ 候補」 後続
- ADR-0068 §決定 6 「(d) audition gate 未実装 = ADR-0065 候補 future」 併記必須 9 件の 1 つ消化
- **ADR-0065 ε Accepted ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了** (= ADR-0066 候補 future、 各 user 判断軸 future)

### 決定 2: sub-sprint chain plan = α/β/γ/δ/ε 5 段 (= ADR-0067/0068 起票 pattern 継承)

| sub | scope | user 介入 | 完了判定 | 関連 ADR |
|---|---|---|---|---|
| α | audition session 準備 doc-only = production binary build 確認 + emulator (MAME) 環境確認 + audition record format 定義 (= 決定 11) | optional | **α 完了 (= 本 PR2)** + retrospective approve (= 本 retrospective record) = build 環境 + emulator + format 確定 literal record (= Annex α fill 6 sub-section、 ADR-0041 §決定 4-3 主軸 fallback approve plan v1 + retrospective Codex review 完走 = approve 判定) | ADR-0058 + ADR-0059 完成済確認 |
| β | audition material 選定 doc-only = ADR-0067 fixture vs PMDDotNET 既存 MML vs 新規 MML trade-off + 選定 literal | optional | **β PR3 halt (= 2026-05-25 40th session、 user option 3 採用)** = driver capability 制約発覚 (= ADR-0068 §決定 1 literal「A-J は全 build mode で default 固定、 C-2 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」)、 PMDDotNET MML の A/B/C/I etc は現 driver で audition audio に出ない、 「実 MML を聴いて aesthetic judgment」 前提不成立。 **ADR-0069 (= driver 拡張 = A-J candidate distinctness) 先行完走後 ADR-0065 β/δ 再開、 dependency = ADR-0069 → ADR-0065 β/δ 順序固定** (= 元の parallel 可 → 順序固定 dependency に変更、 §決定 9 update 反映) | ADR-0067 ε 既存 fixture + ADR-0068 16 ch integration trace 既存 + **ADR-0069 完走前提** |
| γ | acceptance gate criteria 定義 doc-only = pairwise + individual + 全 reject 3 軸 schema 整合 + 判定 framework literal (= 決定 4) | optional | criteria literal + 判定 framework 確定 | memory 3 件 regulation cite |
| δ | **audition session 実施** + record 取得 + finding literal + acceptance decision (= **user 介入 mandatory**、 越川氏 listening + judgment) | **mandatory (= aesthetic / ADR-0041 §決定 5 `audit_gate` escalation 該当)** | audition record + acceptance decision (= aesthetic accept / revise required / 全 reject) | ADR-0058 + ADR-0059 + ADR-0067 ε + ADR-0068 ε 完走前提 |
| ε | Draft → Accepted 移行 doc-only + Annex 全統合 + 「(d) audition gate 達成」 milestone wording 解禁 (= 併記必須 9 件継承) | optional | Annex 全統合 + 解禁 wording + Accepted milestone literal | ADR-0067 ε / ADR-0068 ε pattern 継承 |

### 決定 3: production-ready 経路 literal (= v2 driver 経路)

production-ready 経路 = **v2 driver 経路 = cmd 0x05 + pmdneo_song_main → v2 dispatcher 全 ch 統合** (= ADR-0058 + ADR-0059 完成済前提)。

- ADR-0058 = roadmap ② = song parse + IRQ tick 連携 + v2 per-part dispatch loop 完了
- ADR-0059 = roadmap ③ = ADPCM-B/rhythm 実 dispatch 完了
- ADR-0048 = 軸 G dynamic supply 完成 (= ζ-ε 完走、 ただし production-ready 全体達成 ≠)
- ADR-0067 = 16 ch fixture 拡張完了 (= 機能 verify only、 trace-equivalence は ADR-0068 で完了)
- ADR-0068 = 16 ch 統合 verify 完了 (= K+L-Q distinctness + A-J default integration trace + (a)(b)(c) 3 gate 統合 verify)

### 決定 4: acceptance framework literal (= memory 3 軸独立 schema 遵守)

acceptance framework = **3 軸独立 schema** (= memory `feedback_relative_preference_vs_absolute_acceptance.md` 由来):

| 軸 | 内容 | criteria |
|---|---|---|
| (1) aesthetic accept | user 明示 OK = production-ready 経路 audition session approve | 越川氏 listening + judgment + 明示 GO |
| (2) revise required | aesthetic finding + driver/MML fix 必要 | 別 ADR 起票 (= 軸 B / 軸 G / 軸 C / 軸 F 等の改修 sprint、 user 判断による起票) |
| (3) 全 reject | production-ready 経路 audition 不合格 → 別軸 redesign | ADR-0056 §決定 4 roadmap 再設計 sprint、 user 明示 GO 必須 |

memory 規律遵守:
- `feedback_metric_pass_is_not_aesthetic_pass.md`「metric pass ≠ aesthetic pass」 = engineering verify pass で aesthetic accept 宣言禁止
- `feedback_preference_learning_beats_metric_correlation.md`「preference learning beats metric correlation」 = pairwise comparison + reject label 別軸、 absolute score + Spearman correlation gate 採用不可
- `feedback_relative_preference_vs_absolute_acceptance.md`「pairwise preference ≠ asset acceptance」 = 3 軸独立 schema 必須、 global_reject_all gate 実装必須
- `feedback_ai_engineering_gate_before_human_audition.md`「AI engineering 検査 → human aesthetic audition 順序固定」 = ADR-0067/0068 = engineering verify、 ADR-0065 = human audition、 順序遵守

### 決定 5: allowed-touch literal (= 3 段分類、 ADR-0067/0068 pattern 継承)

#### (i) repo diff allowed-touch (= 各 PR 対象 file)

- doc (= ADR-0065 + dashboard + 起票 PR1 で実装の場合は他 doc)
- audition record file = **text record (= markdown + JSONL) のみ、 audio file (= wav) は repo 外 artifact 配置 = gitignore + 別 storage** (= nice-to-have 1 反映、 repo bloat 回避、 既存 PMDNEO repo pattern = vendor wav 等 untracked retain 整合)

#### (ii) runtime / driver allowed-touch = 完全不変

- driver source / α script / β script / γ script / verify script / vendor / fixture / build flag = ADR-0065 で変更しない
- 変更必要時 = 別 ADR 起票 (= 決定 4 (2) revise required 経路、 user 判断)

#### (iii) repo 外 = PR diff 対象外

- memory `project_pmdneo_adr_0065_initiated.md` + MEMORY.md index
- audition session の wav file (= production binary audio render output、 別 storage 配置、 path は ADR Annex でのみ reference)

### 決定 6: 表記制約 + 新規解禁表現候補 literal (= ADR-0067 / ADR-0068 pattern 継承)

#### ADR-0065 起票時点 (= 本 PR1)

| 表現 | ADR-0065 起票時点 |
|---|---|
| 「(d) audition gate 達成」 | **literal 禁止** (= ADR-0065 ε Accepted 後解禁、 δ acceptance accept 前提) |
| 「越川氏 audition approve」 | **literal 禁止** (= ADR-0065 δ acceptance accept 後解禁) |
| 「roadmap ⑥ audition 完了」 | **literal 禁止** (= ADR-0065 ε Accepted 後解禁) |
| 「production-ready 全体達成」 | **literal 禁止維持** (= ADR-0066 本番 cmd 切替後 future) |
| 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 | **literal 禁止維持** |
| 「16ch full candidate distinctness 完了」 | **literal 禁止維持** (= ADR-0069 候補 future) |

#### ADR-0065 ε Accepted 後 (= 解禁 + 併記必須、 δ acceptance accept 経路前提)

| 表現 | ε Accepted 後 (= δ accept) |
|---|---|
| 「(d) audition gate 達成」 | **解禁** + 併記必須 = 「production-ready 全体達成ではない (= ADR-0066 本番 cmd 切替後 future)」 + 「軸 B 完成ではない」 + 「軸 G 完成ではない」 + 「本番 cmd 切替完了ではない」 |
| 「越川氏 audition approve」 | **解禁** (= δ acceptance accept 経由) + 併記必須 = 同上 |
| 「roadmap ⑥ audition 完了」 | **解禁** + 併記必須 = 同上 |
| 「production-ready 全体達成」 | **禁止維持** (= ADR-0066 本番 cmd 切替後 future) |
| 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 | **禁止維持** |
| 「16ch full candidate distinctness 完了」 | **禁止維持** (= ADR-0069 候補 future) |

#### δ で acceptance decision = (2) revise required または (3) 全 reject の場合

- 「(d) audition gate 達成」 解禁不可 (= δ acceptance reject 経路、 別軸 redesign or 別 ADR 起票)
- ADR-0065 ε Accepted = δ 結果 literal record + 残課題 enumeration + 次 ADR (= 別軸 / ADR-0066 候補等) 起票判断 material
- 「ADR-0065 ε Accepted」 ≠ 「(d) audition gate 達成」 (= δ acceptance accept のみで両方達成、 acceptance reject 経路の場合 ε Accepted は record milestone のみ)

#### gate verify criteria (= ADR-0067 §決定 6 ε gate-3 pattern 継承)
- 禁止 wording は **肯定表現として使わない**
- ただし「production-ready 全体達成ではない」 / 「軸 B 完成ではない」 等の **否定併記は必須**
- 「未実装」 / 「未解禁」 / 「future」 / 「不可」 / 「≠」 reference context は OK

### 決定 7: 不可触対象 literal (= 決定 5 (ii) と整合、 明示再列挙)

#### 完全不変
- driver source (= `src/driver/standalone_test.s`)
- α script / β script / γ script / 既存 verify script (= ADR-0049〜0068 全)
- vendor
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_rhythm_k` + `_rhythm_k_full` 等)
- ADR-0067 slot init (= slot 0-10 init + chip target 別 active policy + pointer switch)
- 既存 build flag (= 新規 flag 追加なし)
- ADR-0041〜0068 本文 + Annex (= 完全 historical record 維持)
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触

### 決定 8: PR chain plan = 6 PR (= 本 PR1 = doc-only + PR2-PR6 sub-sprint α/β/γ/δ/ε)

| PR # | scope | content type | user 介入 |
|---|---|---|---|
| **PR1 (= 本 PR)** | ADR-0065 doc 起票 doc-only (= 12 決定 + Annex skeleton + dashboard + memory) | doc-only | optional |
| PR2 | sub-sprint α = audition session 準備 doc-only | doc-only | optional |
| PR3 | sub-sprint β = audition material 選定 doc-only (= **halt 解消後 再起票完了 = ADR-0069 Accepted (= PR #147 MERGED at `0cde9f6`) 後 41st session 2026-05-26、 candidate 4 件評価 + 採否判定 record 完了 + β revise (= 採否 revise + engineering gate 追加) sub-sprint 完走 = δ session 試行 invalid (= candidate 2 「低音持続」 + candidate 3 「無音 fadeout」 + 説明不足 で aesthetic judgment 不成立) を root cause evidence に candidate 2/3 不採用候補 revise + §決定 13 audio render engineering gate 7 items 追加、 詳細 Annex β-7 + β-8 fill 参照**) | doc-only | optional |
| PR4 | sub-sprint γ = acceptance gate criteria 定義 doc-only (= **γ PR4 起票完了 = 2026-05-26 41st session、 ADR-0069 Accepted + β PR3 再起票完了後の γ acceptance gate criteria 定義完走 = 3 軸独立 schema (= pairwise comparison + individual acceptance + 全 reject) 明記 + candidate 1/2/3 役割接続 + candidate 4 scope-out literal、 詳細 Annex γ fill 参照**) | doc-only | optional |
| PR5 | sub-sprint δ = **audition session 実施 + record + finding + acceptance decision** | doc + text record (= markdown + JSONL) + audio file (= wav、 **repo 外 artifact 配置 = gitignore + 別 storage**、 nice-to-have 反映) | **mandatory** |
| PR6 | sub-sprint ε = Draft → Accepted + Annex 全統合 + milestone wording 解禁 | doc-only | optional |

### 決定 9: ADR-0066/0069 候補 起票判断 dependency literal (= 2026-05-25 40th session β PR3 halt 経緯で更新)

- **ADR-0066 候補** = roadmap ⑦ 本番 cmd 切替判断 ADR (= ADR-0065 Accepted 後 future、 **順序固定 dependency**、 全 4 gate (= (a)(b)(c) ADR-0068 + (d) ADR-0065) 達成後 user 明示 GO 必須)
- **ADR-0069 候補** = driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct (= ADR-0068 残課題)
  - **2026-05-25 40th session 更新**: 元「ADR-0065 と independent、 parallel 起票可」 → 「**ADR-0065 β 再開のために先行完走必須 dependency = ADR-0069 → ADR-0065 β/δ 順序固定**」 (= β PR3 plan v2 round 2 review で driver capability 制約発覚、 ADR-0068 §決定 1 literal「A-J は全 build mode で default 固定」 = PMDDotNET MML audition 前提不成立、 user option 3 採用 = ADR-0069 先行起票 + ADR-0065 β/δ はその後)
  - 旧 sha256 維持運用順序 4 選択肢 (= parallel 起票時の選択肢) は obsolete = 順序固定 dependency に統一
- 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)

#### ADR-0069 parallel 起票時の sha256 維持運用順序 (= **OBSOLETE = 2026-05-25 40th session β PR3 halt で確定無効**、 historical record)

> **OBSOLETE NOTICE**: 以下の subsection は β PR3 halt (= driver capability 制約発覚 + user option 3 採用 = ADR-0069 → ADR-0065 β/δ 順序固定 dependency 確定) により **完全に無効**。 新 dependency = ADR-0069 先行完走後 ADR-0065 β/δ 再開 (= 順序固定、 並行進行不可、 4 選択肢 obsolete)。 historical context として記録のみ残す (= 起票時点 plan の literal record)。

ADR-0069 = driver 拡張 (= A-J candidate distinctness + K bitmap pair distinct) は driver source 変更が必須 = production sha256 衝突 risk。 ADR-0065 sub-sprint 進行中 (= δ audition session 実施前後) で ADR-0069 driver 拡張 commit を同時実施すると次 risk:

| risk | content |
|---|---|
| sha256 衝突 | ADR-0065 production binary (= 越川氏 audition 対象) と ADR-0069 driver 拡張後 binary の sha256 不一致 |
| audition 結果整合性 | ADR-0065 δ で audition した binary と ADR-0069 完走後 binary が異なる場合、 audition decision の意味曖昧化 |

旧運用順序選択肢 (= **OBSOLETE**、 β PR3 halt で無効化 = ADR-0069 → ADR-0065 β/δ 順序固定 dependency 確定):
1. ~~ADR-0065 ε Accepted 後に ADR-0069 起票~~ (= obsolete、 β halt で ADR-0069 先行確定)
2. ~~ADR-0069 完走後に ADR-0065 δ audition session 実施~~ (= obsolete、 順序固定 dependency 確定済)
3. ~~ADR-0065 δ 前に ADR-0069 完走~~ (= obsolete、 順序固定 dependency 確定済)
4. ~~ADR-0065 ε Accepted + ADR-0069 別 ADR-0065 拡張 entry~~ (= obsolete、 β halt で order 一本化)

= **新 dependency 確定 (= 2026-05-25 40th session β PR3 halt)**: ADR-0069 → ADR-0065 β/δ 順序固定、 並行進行不可、 4 選択肢全 obsolete。 ADR-0069 完走後 ADR-0065 β/δ 再開時に sha256 carry literal は再確定 (= ADR-0069 完走後 driver 拡張後 binary を audition baseline として新規確定 必要可能性)。

### 決定 10: production sha256 維持 mandatory (= 全 sub-sprint 共通 gate)

ADR-0065 全 sub-sprint 共通 gate:
- 通算 sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持必須
- ADR-0065 で driver / fixture / verify script / build flag 変更しない方針 = sha256 確定 carry (= ADR-0067/0068 後の状態)
- ADR-0065 δ audition session は production-ready 経路 build (= `b15883fe...` sha256 binary) で実施
- ADR-0069 parallel 起票時の sha256 衝突 risk は §決定 9 §sub-section literal

### 決定 11: audition record format literal

#### text record format (= repo 内 commit、 PR diff 対象)

- **markdown audition session report** (= session 概要 + audition material + 経緯 + finding + acceptance decision literal)
- **JSONL aesthetic finding format** (= 1 finding = 1 JSONL row、 timestamp + audition material id + aesthetic finding text + acceptance decision (= aesthetic accept / revise required / 全 reject) literal)

#### audio file (= repo 外 artifact 配置、 PR diff 対象外、 nice-to-have 1 反映)

- **wav (= production binary audio render output)** = MAME wavwrite or emulator audio output
- **repo 外 artifact 配置** (= gitignore + 別 storage、 例: `audition/2026-05-XX/session-N.wav` という path schema は ADR-0065 Annex で literal reference のみ、 repo に commit しない、 repo bloat 回避)
- 既存 PMDNEO repo pattern (= vendor wav 等 untracked retain) 整合

#### aesthetic finding format (= memory 規律遵守)

- memory `feedback_metric_pass_is_not_aesthetic_pass.md` 規律 = metric ≠ aesthetic、 metric pass で aesthetic accept 宣言禁止
- memory `feedback_preference_learning_beats_metric_correlation.md` 規律 = preference learning + reject label 別軸
- memory `feedback_relative_preference_vs_absolute_acceptance.md` 規律 = pairwise + individual + 全 reject 3 軸独立 schema
- memory `feedback_ai_engineering_gate_before_human_audition.md` 規律 = AI engineering 検査 → human aesthetic audition 順序固定 (= ADR-0067/0068 = engineering verify、 ADR-0065 = human audition)

### 決定 12: 番号 chronology rationale (= ADR-0064 §決定 7 整合)

- ADR-0064 plan → ADR-0065 (= roadmap ⑥ audition、 本 ADR) → ADR-0066 (= roadmap ⑦ 本番 cmd 切替、 future) → ADR-0067 fixture 拡張 (= 完了) → ADR-0068 統合 verify (= 完了) → ADR-0069 driver 拡張 (= ADR-0068 残課題、 parallel 起票可)
- audition (= ADR-0065) は ADR-0066 (= 本番 cmd 切替) 前 mandatory (= production-ready 経路 audition approve = (d) gate = 4 gate 全達成 + user 明示 GO で本番 cmd 切替判断)

### 決定 13: audio render engineering gate 7 items + δ 前提 gate pass 規律 (= 41st session β revise sprint 追加、 memory `feedback_ai_engineering_gate_before_human_audition.md` 規律遵守 = AI engineering 検査 → human aesthetic audition 順序固定 restore)

δ audition session 実施前に **audio render engineering gate (= 機械検査 with metric pass)** 全 7 items pass mandatory。 1 件でも fail なら δ 進行 halt + material revise trigger。 越川氏 human aesthetic audition phase は engineering gate pass 後にのみ実施可能。

#### gate items literal (= 7 件)

1. **wav duration** = render 後 wav file 実 duration ≥ 期待 duration (= candidate 別 minimum、 例 candidate 2 = ≥ 30 秒 / candidate 3 = ≥ 4 秒)
2. **RMS amplitude** = wav RMS > silence threshold (= silence-only wav reject)
3. **silence check** = wav 全 sample が 0 ではない (= 「無音 fadeout」 のみの場合 reject = candidate 3 実 render 不成立 evidence)
4. **FM keyon count** = MAME ymfm trace で FM keyon count ≥ 期待値 (= candidate MML が FM melody 含むなら ≥ 1)
5. **SSG tone write** = ymfm trace で SSG tone register write count ≥ 期待値 (= candidate MML が SSG melody/percussion 含むなら ≥ 1)
6. **ADPCM-A trigger count** = ymfm trace で ADPCM-A trigger count ≥ 期待値 (= candidate MML が rhythm / ADPCM-A 含むなら ≥ 1)
7. **expected audible content match** = 期待 audio 説明 (= material id + 期待音 文字列) と render trace 結果の **機械的整合確認** (= LR1 反映 = metric pass ≠ aesthetic pass 混同回避、 例 candidate 2 = 「polyphonic FM song + Intro + A/B/C section + 主旋律」 → FM keyon ≥ 期待 + SSG tone write ≥ 期待 + 持続時間 ≥ 期待 で機械的 pass、 越川氏 aesthetic judgment は別 phase)

#### gate pass mandate

- **all 7 gate items pass 後にのみ δ audition session 実施可**
- **1 件 fail で δ halt** + material revise trigger (= β 採否再評価 or candidate 別 MML 探索 or 新規 audition material 起票)
- engineering gate pass record = δ session 開始前 Annex δ 内 literal record
- memory `feedback_metric_pass_is_not_aesthetic_pass.md` 規律遵守 = engineering gate pass = 機械検査 pass、 越川氏 aesthetic judgment は **別 phase + 別 軸 (= 3 軸独立 schema γ-2 適用)**

#### gate items 拡張可能性 (= future)

7 items は 41st session β revise sprint 時点の literal、 将来 candidate 4 (= 新規 audition material MML) 起票時等で gate items 追加 (= envelope decay verify、 stereo balance、 別 chip target trace 等) は user 明示 GO で別 sub-sprint。

## verify gate (= PR1 = doc-only sprint、 spec consistency check)

PR1 doc-only sprint で次 verify gate:

- gate 1: ADR-0065 file 新規作成 + 12 決定 literal coverage
- gate 2: dashboard 0065 行 update (= 「未起票」 → 「Draft 起票」)
- gate 3: dashboard escalation 履歴 ADR-0065 entry 追加
- gate 4: 不可触対象 (= driver / verify / vendor / fixture / build flag / ADR-0041〜0068 本文 + Annex) 完全不変 confirm (= git diff -- src/ vendor/ scripts/ docs/adr/0041* etc = 空)
- gate 5: 禁止 wording 6 件 (= 「(d) audition gate 達成」 + 「越川氏 audition approve」 + 「roadmap ⑥ audition 完了」 + 「production-ready 全体達成」 + 「軸 B 完成」 + 「本番 cmd 切替完了」) literal 禁止 confirm (= 否定 / reference / ≠ context のみ)
- gate 6: production sha256 = `b15883fe...` 維持 confirm (= ADR-0065 で driver 不変、 doc-only sprint、 再 build なし)

## Codex layer 2 plan review chain (= 1 round chain、 全 review-only + 越権操作なし confirmed)

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| 1 | **approve** | must-fix 0 + nice-to-have 1 (= PR5 wav repo 配置明記) + latent risk 1 (= ADR-0069 parallel 起票時 sha256 維持運用順序明記) 全反映 | `afbed0b24a60caa41` |

= 1 round chain、 全 review-only 遵守 confirmed + 越権操作なし。 nice-to-have 1 件 = §決定 11 + §決定 5 (i)/(iii) で literal 反映 (= wav = repo 外 artifact、 text record = repo 内)。 latent risk 1 件 = §決定 9 で literal 反映 (= ADR-0069 parallel sha256 維持運用順序、 4 選択肢、 user 明示 GO 必須)。

冒頭 6 件 literal 強調遵守 (= memory `feedback_codex_layer2_review_no_commit_authority.md`):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations

## Annex skeleton (= ε で fill default、 α 漏れ補完 retrospective 起票時 prevention = ADR-0067 ε retrospective 学習反映)

### Annex A: ADR-0065 ground truth + 起票背景 (= ε で fill 完了)

#### A-1 = ADR-0056 §決定 3-b 最終 gate audition approve literal (= production-ready 4 gate (d))

placeholder (= ε で fill)。

#### A-2 = ADR-0063 §(d) 越川氏 audition gate 定義 + status + 確認方法 + 達成判定根拠 literal

placeholder (= ε で fill)。

#### A-3 = ADR-0067 残課題 enumeration ADR-0065 候補 scope literal

placeholder (= ε で fill)。

#### A-4 = ADR-0068 §決定 1(d) + §決定 6 「(d) audition gate 未実装 = ADR-0065 候補 future」 併記必須 9 件の 1 つ literal + §決定 9 ADR-0065 候補起票判断 literal

placeholder (= ε で fill)。

#### A-5 = user 明示 GO「ADR-0065 が自然な次」 (= 40th session ADR-0068 retrospective fix 完走後)

placeholder (= ε で fill)。

#### A-6 = production-ready 経路 partial 達成 evidence (= ADR-0043 + ADR-0048 + ADR-0058/0059 部分達成 literal)

placeholder (= ε で fill)。

### Annex B: production-ready 経路 構成図 + audio render method (= ε で fill 完了)

#### B-1 = v2 driver 経路 全体図 (= cmd 0x05 + pmdneo_song_main → v2 dispatcher 全 ch 統合 ascii)

placeholder (= ε で fill)。

#### B-2 = MAME wavwrite or emulator audio output method literal

placeholder (= ε で fill)。

#### B-3 = audition material build matrix (= production-ready build (= sha256 `b15883fe...`) + ADR-0067 fixture build + ADR-0068 integration trace build)

placeholder (= ε で fill)。

#### B-4 = audition session checklist literal (= 越川氏 listening 環境 + judgment 入力 format + record 取得手順)

placeholder (= ε で fill)。

### Annex α: sub-sprint α audition session 準備 doc-only (= α PR2 で fill 完了)

#### α-1: production binary build 確認方針

production-ready 経路 build = (A) production default build mode (= ADR-0068 §決定 3 (A) literal 整合)。

- build script: `scripts/build-poc.sh` (= 既存、 不変)
- build command literal: `bash scripts/build-poc.sh --chip ym2610` (= ym2610 production default、 ADR-0006 §B chip target literal 整合)
- sha256 確認 mandatory: `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` (= ADR-0065 §決定 10 整合)
- build artifact: production binary ROM file (= `build/poc/` 配下、 既存 build output 経路)
- ADR-0067 ε / ADR-0068 ε で確立した build pattern 継承

#### α-2: MAME / emulator 環境確認方針

- MAME version: 既存 PMDNEO repo 内で使用中の MAME version (= 具体 version literal は δ session 実施時に確定 = α では「最新使用 version + audition session 全体で同一 version 使用 mandatory」 方針確定)
- MAME command literal:
  - 既存 `scripts/run-mame.sh` reference (= 不変)
  - audio render flag literal: `-wavwrite <output.wav>` (= MAME standard wavwrite)
- ROM path + load 方法: MAME `-rompath <build artifact dir>` + ROM file load
- audio output method: MAME wavwrite (= memory `project_mame_headless_recording_mode.md` 確立 mode 整合)
  - SDL_VIDEODRIVER=dummy + -video none + -sound coreaudio + -samplerate 48000 (= headless 録音 mode literal)
- driver / chip target: ym2610 production default (= ADR-0006 §B literal)
- emulator 環境完全 reproducible: MAME version + flag + ROM 完全 literal record (= δ session 実施時の environment snapshot 取得 mandatory)

#### α-3: audio render の前提

- ADR-0058 = roadmap ② song parse + IRQ tick 完成済 (= production-ready 経路前提条件)
- ADR-0059 = roadmap ③ ADPCM-B/rhythm 実 dispatch 完成済 (= production-ready 経路前提条件)
- ADR-0067 = 16 ch fixture 拡張完了 (= 機能 verify only base、 16 ch carry 可能 driver state)
- ADR-0068 = 16 ch 統合 verify 完了 (= K+L-Q distinctness + A-J default integration trace + (a)(b)(c) 3 gate 統合 verify)
- audition material: **β PR3 で選定** (= α では「audition material を rendering する build 環境を確定」 のみ)
- audio output spec: sample rate 48 kHz / 16-bit / 2ch (= MAME wavwrite default、 memory `project_mame_headless_recording_mode.md` 整合)
- 1 audition material = 1 wav file (= MAME `-wavwrite <output.wav>` 経由)
- 録音時間: audition material の playback duration full 録音 (= MAME `-seconds_to_run <N>` 適切設定、 N 値は β material 選定後 決定)

#### α-4: audition record format (= ADR-0065 §決定 11 整合、 nice-to-have 反映)

##### text record file structure (= repo 内、 PR diff 対象)

- markdown audition session report: `audition/YYYY-MM-DD/session-N/report.md` path schema (= 例示、 実 path は δ session 実施時に確定)
- JSONL aesthetic finding: `audition/YYYY-MM-DD/session-N/findings.jsonl` path schema

##### markdown audition session report format literal

```markdown
# Audition Session N (YYYY-MM-DD)

## Session 概要
- audition material: <material-id-list>
- 越川氏 listening 環境: <emulator + MAME version + audio output 環境>
- 主軸 record 担当: Claude Code

## audition material

### <material-id>
- source: <ADR-0067 fixture / PMDDotNET 既存 MML / 新規 MML>
- wav: <audition/.../material.wav> (= repo 外 artifact)
- duration: <seconds>

## 経緯
- <user listening + judgment 経緯 literal>

## finding
- <aesthetic finding text> (= 越川氏 judgment + comment)

## acceptance decision
- decision: <aesthetic_accept | revise_required | all_reject>
- rationale: <decision の理由 literal>
- 次 action: <ADR-0065 ε 移行 / 別 ADR 起票判断 / 別軸 redesign>
```

##### JSONL aesthetic finding format literal

1 finding = 1 JSONL row schema:
```jsonl
{"timestamp": "YYYY-MM-DDTHH:MM:SSZ", "session_id": "<session-id>", "material_id": "<material-id>", "finding_text": "<越川氏 finding 自然言語>", "acceptance_decision": "aesthetic_accept|revise_required|all_reject", "rationale": "<decision rationale literal>"}
```

##### wav file storage (= repo 外 artifact 配置、 nice-to-have 1 反映)

- wav file path schema: `audition/YYYY-MM-DD/session-N/<material-id>.wav` (= 例示、 実 path は δ で決定)
- repo 外 artifact 配置: `.gitignore` で `audition/` directory excluded (= 本 α PR2 commit chain 内で `.gitignore` update)
- 別 storage: local file system or 別 archive (= PMDNEO repo に commit しない、 repo bloat 回避)
- 既存 PMDNEO repo pattern (= vendor wav 等 untracked retain) 整合

#### α-5: 越川氏 judgment 記録形式 (= ADR-0065 §決定 4 整合)

##### aesthetic finding text format

- 自然言語 (= 越川氏 judgment + comment + finding text)
- 文体: 主軸 record draft 起草時の literal verbatim (= 越川氏発言を主軸が record として書き起こす)
- 長さ: 制約なし (= 越川氏 finding の質に応じる)

##### acceptance decision enum (= ADR-0065 §決定 4 acceptance framework 3 軸独立 schema)

| enum value | 内容 |
|---|---|
| `aesthetic_accept` | user 明示 OK = production-ready 経路 audition session approve (= ADR-0065 §決定 4 (1)) |
| `revise_required` | aesthetic finding + driver/MML fix 必要 = 別 ADR 起票 (= ADR-0065 §決定 4 (2)) |
| `all_reject` | production-ready 経路 audition 不合格 → 別軸 redesign (= ADR-0065 §決定 4 (3)) |

##### judgment 入力 method (= 主軸起草 → user confirm process)

1. δ session 実施前:
   - 主軸が audition material build + render 実行 + wav 取得
   - 主軸が audition session report draft 起草 (= report.md + findings.jsonl skeleton)
2. δ session 実施中:
   - 越川氏 listening (= wav 再生 + emulator playback)
   - 越川氏 judgment + finding 口頭 or text 入力
   - 主軸が record draft に finding text + acceptance decision 入力
3. δ session 実施後:
   - 主軸 record draft 完成 → 越川氏 review approve
   - 越川氏修正指示 (= 必要なら record text 修正)
   - δ PR5 commit (= record file + JSONL + dashboard update)
- judgment 主体: 越川氏 (= user 本人)
- 記録主体: 主軸 Claude Code
- commit 主体: 主軸 (= 越川氏 review approve 後)

##### memory 規律遵守 (= ADR-0065 §決定 4 cite)

- `feedback_metric_pass_is_not_aesthetic_pass.md` = metric ≠ aesthetic、 metric pass で aesthetic accept 宣言禁止
- `feedback_preference_learning_beats_metric_correlation.md` = pairwise comparison + reject label 別軸
- `feedback_relative_preference_vs_absolute_acceptance.md` = pairwise + individual + 全 reject 3 軸独立 schema
- `feedback_ai_engineering_gate_before_human_audition.md` = AI engineering 検査 → human aesthetic audition 順序固定 (= ADR-0067/0068 engineering verify → ADR-0065 human audition)

#### α-6: 不可触対象 literal (= ADR-0065 §決定 7 整合)

##### 完全不変 (= α PR2 で touch しない)

- driver source (= `src/driver/standalone_test.s`)
- α script / β script / γ script / 既存 verify script (= ADR-0049〜0068 全)
- vendor
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_rhythm_k` + `_rhythm_k_full` 等)
- ADR-0067 slot init (= slot 0-10 init + chip target 別 active policy + pointer switch)
- 既存 build flag (= 新規 flag 追加なし)
- ADR-0041〜0068 本文 + Annex (= ADR-0068 既存 Annex α/β/γ/δ + Annex A/B/ε 完全不変)
- ADR-0065 §決定 1-12 本文 / §verify gate / §Codex layer 2 plan review chain / Annex skeleton (= A/B/β/γ/δ/ε placeholder) 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory (= α で再 build しない doc-only sprint、 ADR-0065 §決定 10 整合)

##### α PR2 で touch する範囲

- ADR-0065 file: Annex α fill 6 sub-section + §決定 2 α row update + 改訂履歴 α entry + 平易要約 α context section
- dashboard: 0065 行 status column α 完了 entry update + escalation 履歴 α PR2 entry 追加
- `.gitignore`: `audition/` excluded entry 追加 (= 新規 entry、 nice-to-have 反映)

#### α PR2 Codex layer 2 plan review chain (= 主軸 fallback approve plan v1、 ADR-0041 §決定 4-3 適用、 Codex unavailable + retrospective Codex review 必須)

| round | judgment | 主体 | finding 要点 |
|---|---|---|---|
| 1 | (Codex unavailable) | Codex layer 2 起動失敗 | Codex companion 安全性分類器 (claude-opus-4-7) 一時障害 1 回目失敗 = `claude-opus-4-7[1m] is temporarily unavailable` error |
| 1 retry | (Codex unavailable) | Codex layer 2 起動失敗 | 同障害 2 回連続失敗 = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 該当 |
| fallback | **approve plan v1** | 主軸 Claude Code | 主軸独立 review (= 6 axis = A scope / B α-1 build / C α-2 emulator / D α-3 render + α-4 record format / E α-5 judgment / F α-6 不可触対象 + commit chain 全 OK = approve 判断)、 latent risk 1 件 (= MAME version literal specificity、 plan v1 内 abstract OK + δ で具体 version 確定 natural) は retrospective Codex review で再確認 |
| retrospective | **approve** (= 2026-05-25 40th session、 Codex companion 復旧後) | Codex layer 2 | agentId `ac5bbe0460b71e59d`、 6 axis 全 OK (= Axis 1 plan v1 / Axis 2 impl / Axis 3 fallback 適用根拠 / Axis 4 scope 違反なし / Axis 5 wording 制約遵守 / Axis 6 memory + dashboard consistency)、 must-fix 0 + nice-to-have 0 + latent risk 1 件 (= MAME version literal specificity = α では abstract OK + δ で具体 version 確定 natural、 Annex α-2「既存 PMDNEO repo 内で使用中の MAME version」 + 「δ session 実施時に確定」 + 「session 全体で同一 version 使用 mandatory」 literal で current must-fix ではない) 主軸 fallback judgment 事後 confirm = approve、 全 review-only + 越権操作なし confirmed |

= 主軸 fallback approve 1 件 + retrospective Codex review approve (= 主軸 fallback judgment 事後 confirm completed)。 ADR-0068 ε で確立した「主軸 fallback + retrospective Codex review」 pattern (= ADR-0041 §決定 4-3 full cycle 完走実証完了) 継承 = doc-only sprint + scope 明確 + retrospective review 必須が成立条件 = ADR-0065 α PR2 で 2 回目適用 full cycle 完走実証 (= ε PR6 同 pattern 安定化)。 user 明示 option B 採用 (= 40th session ADR-0065 α PR2 plan review 2 回連続 Codex unavailable 後 escalation 経路)、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed (= 主軸 fallback でも commit 権限分離維持)。

### Annex β: sub-sprint β audition material 選定 doc-only (= β PR3 halt 記録、 ADR-0069 完走後 再開)

#### β-1 = β PR3 halt 経緯 literal (= 2026-05-25 40th session、 user option 3 採用)

β PR3 = audition material 選定 doc-only sprint は **halt (= pending、 ADR-0069 完走後 再開)**。 halt 経緯:

1. β PR3 plan v1 draft = PMDDotNET 既存 MML (= SAMPLE2-baseline / step5-noACI / step8-Bvol) 3 件 採用 + ADR-0067 fixture + 新規 MML scope-out
2. Codex layer 2 plan review round 1 (= agentId `a7e63962cb989934c`) = **revise** = must-fix 6 件 (= MML 実内容不一致 + build mode 混同 + 越川氏 verify claim 誤 + 不可触衝突)
3. β PR3 plan v2 draft = round 1 must-fix 6 件全反映 + 2 件 selection (= baseline + step5-noACI、 step8-Bvol drop)
4. Codex layer 2 plan review round 2 (= agentId `a8681fb73a77eacfc`) = **revise** = must-fix 2 件 (= driver capability 制約 + ADR-0065 §決定 10 vs C-2 build 衝突) + lr 1 件
5. 主軸 escalate to user (= ADR-0041 §決定 5 `design_judgment_needed` escalation 該当) = 4 option 提示
6. user 採用 = **option 3 = ADR-0069 先行起票 + ADR-0065 β/δ はその後**

#### β-2 = driver capability 制約 literal (= ADR-0068 §決定 1 ground truth)

ADR-0068 §決定 1 line 102/105/109 literal:

| build mode | A-J (= FM 6 + SSG 3 + ADPCM-B) | K (= rhythm) | L-Q (= ADPCM-A 6) | candidate MML 関与 part |
|---|---|---|---|---|
| (A) production default | test01/test02 default | test01/test02 default | test01/test02 default | **なし** |
| (C-2) PMDDOTNET_MML | test01/test02 default **固定** | pmddotnet_song K | pmddotnet_song L-Q | **K + L-Q (= 7 part)** |

ADR-0068 line 109 literal: **「A-J 10 part の candidate dispatch は既存 build mode いずれでも不可」** = driver line 1741-1804 `load_song_part_addr` 固定。

= PMDDotNET MML の主旋律 (= A/B/C/I FM+SSG melody) は現 driver で audition audio に出ない、 audition material として「実 MML を聴いて aesthetic judgment」 前提が不成立。

#### β-3 = ADR-0069 dependency literal (= §決定 9 更新と整合)

ADR-0069 (= driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct):
- driver line 1741-1804 `load_song_part_addr` 拡張 (= A-J MML candidate dispatch 可能化)
- 完走後に MML A-J part の audio render が初めて可能化
- ADR-0065 β/δ 再開条件 = ADR-0069 ε Accepted (= driver 拡張完走)

= ADR-0065 β PR3 再開は ADR-0069 完走後、 順序固定 dependency。

#### β-4 = ADR-0065 β PR3 再開時の前提変更 (= ADR-0069 完走後 future、 placeholder)

ADR-0069 完走後の ADR-0065 β PR3 再開時:
- driver capability 制約解除 (= A-J MML candidate dispatch 可能)
- material 選定対象に PMDDotNET MML 全 part audition が含まれる
- ADR-0065 §決定 10 + Annex α-1 production sha256 `b15883fe...` 維持方針との関係は ADR-0069 完走後の sha256 と整合性確認 (= 再 build 後 sha256 を audition baseline として再確定 必要可能性)
- β PR3 plan v3 起票時に再 draft

#### β-5 = β PR3 halt 中の不可触対象 (= ADR-0065 §決定 7 literal 継承 + Annex α 維持)

- driver 完全不変
- α/β/γ script / 既存 verify script 完全不変
- vendor 完全不変
- ADR-0067 fixture 完全不変
- 既存 build flag 完全不変
- ADR-0041〜0068 本文 + Annex 完全不変 (= halt record commit でも触らない)
- ADR-0065 §決定 1 + 3-8 + 10-12 本文 完全不変 (= 本 halt record でも触らない)
- ADR-0065 §決定 2 = β row 完了判定 column のみ literal update (= halt record)
- ADR-0065 §決定 9 = ADR-0066/0069 dependency literal の ADR-0069 entry 更新 (= 元 parallel 可 → 順序固定 dependency)
- ADR-0065 §verify gate / §Codex layer 2 plan review chain / Annex α (= 本文 + retrospective row + summary 段落 already final) / Annex skeleton 他 sub-section (= γ/δ/ε placeholder + A/B 本文) 完全不変

#### β-6 = β PR3 halt record touch 範囲 + Codex layer 2 plan review chain literal (= round 2 revise + halt)

##### touch 範囲 (= 本 halt record commit)
- ADR-0065 file: §決定 2 β row update + §決定 9 ADR-0069 dependency update + Annex β fill (= 本 halt record literal) + 改訂履歴 halt entry + 平易要約 β halt context section
- dashboard: 0065 行 status column update + escalation 履歴 β PR3 plan review chain + halt entry 追加

##### Codex layer 2 plan review chain literal (= round 1 revise + round 2 revise + halt)

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | **revise** | `a7e63962cb989934c` | must-fix 6 (= SAMPLE2 MML 実内容誤 (baseline 16 ch全 part claim / step5-noACI ABCDFGH claim / step8-Bvol SSG B claim) + build mode 混同 + 越川氏 verify claim 誤 + 不可触衝突) + nh 2 (= material 1 表 + aesthetic range vs coverage range) + lr 2 (= aesthetic vs 16 ch coverage 混同 + C-2 sha relation 曖昧) |
| 2 | **revise + escalate** | `a8681fb73a77eacfc` | must-fix 2 (= driver capability 制約 = ADR-0068 §決定 1 A-J default 固定 literal + ADR-0065 §決定 10 vs C-2 build 衝突) + lr 1 (= halt 時の touch 範囲再調整必要)、 主軸 escalation `design_judgment_needed` 経路で user に option 4 件提示、 **user option 3 採用 = ADR-0069 先行起票 + ADR-0065 β/δ halt** |

= 主軸 escalation 経路 (= ADR-0041 §決定 5 `design_judgment_needed`) 利用、 全 Codex layer 2 round review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed。

##### β PR3 再開時 (= future、 ADR-0069 完走後)

ADR-0069 完走後 ADR-0065 β PR3 再開時 = β PR3 plan v3 新規 draft (= driver capability 拡張後の前提整合) + Codex plan review + impl + impl-review + merge + branch 削除 atomic 1 セット。

#### β-7 = β PR3 再起票 record (= ADR-0069 Accepted 後 41st session 2026-05-26)

##### β-7-1 = 再開条件成立 confirm + 同文脈併記 mandatory 4 件 boilerplate

ADR-0069 Accepted (= 2026-05-26 41st session、 PR #147 MERGED at `0cde9f6` + final maintenance commit `916b600`) = 軸 B v2 driver A-J candidate distinctness 拡張完成 = ADR-0065 β PR3 halt 解消条件成立 confirmed。 「実 MML を聴いて aesthetic judgment」 前提 = driver capability 制約 (= ADR-0068 §決定 1 「A-J default 固定」) 解除済、 PMDDOTNET_MML 経路で A-J part candidate dispatch 可能化。

**同文脈併記 mandatory 4 件 boilerplate** (= 「A-J candidate distinctness 達成」 wording 使用時必須):
1. 「K bitmap pair distinct 未達成 = ADR-0070 candidate future」
2. 「16ch full candidate distinctness 完了 ではない」 (= ADR-0070 完走条件)
3. 「ADR-0065 β/δ 再開 ready」
4. 「production-ready 全体達成 ではない」

= 本 sub-section + 後続 sub-section で wording 使用箇所全てで boilerplate 適用 (= ADR-0069 §決定 6 + γ-2 規律 literal 継承)。

##### β-7-2 = audition material 候補 4 件 evaluation literal (= 実 read verify confirmed)

| candidate | file path | 実 line count (= main agent verify) | part coverage | 演奏時間目安 | audition 適性 |
|---|---|---|---|---|---|
| 1 | `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` | 32 行 (= ADR-0069 β PR3 で追加) | A-J 10 part 全 active + per-part distinct note (= c4/d4/e4/f4/g4/a4 for FM A-F + c4/d4/e4 for SSG G-I + c4 for ADPCM-B J) + voice 定義 2 件 (= @001 alg 0 / @002 alg 7) | 約 0.5 秒 (= t120、 single note × 10 part、 loop/decay/fade 無し) | **test pattern (= acoustic verify gate 用)** = 「楽曲」 不成立 = 越川氏 aesthetic judgment 対象外 |
| 2 | `vendor/PMDDotNET/SAMPLE2.MML` | 84 行 (= PMDDotNET 公式 sample) | A/B/C/I 部分 active (= D/E/F/G/H/J 欠落) + rich FM voice @1/@2/@4/@5 + actual song form Intro/A/B/C | 約 45 秒 (= t75、 polyphonic structure) | **PMDDotNET 既存「曲」 audition material 最有力 (= 部分 audition)** = D/E/F/G/H/J 欠落明示 (= ADR-0069 完走で driver 拡張済だが MML に書かれた part のみ active = A/B/C/I 4 part のみ audition) = 越川氏 aesthetic judgment 対象 |
| 3 | `src/test-fixtures/step5/l-q-rhythm-song.mml` | 23 行 (= ADR-0016 step 5 ε-a で追加) | L-Q ADPCM-A 6 ch (= bd/sd/hh/tom/rim/top) + K bitmap rhythm | 約 4 秒 (= 1-bar loop) | **rhythm/ADPCM-A audition material (= 採用)** = ADR-0067 ε 16 ch fixture 拡張完了 流用、 越川氏 aesthetic judgment 対象 |
| 4 | 新規 audition material MML (= A-J + K rhythm + L-Q ADPCM-A 6 = 17 part full active demo、 30-60 秒想定) | (= 未作成、 候補概念) | A-J 10 + K rhythm + L-Q ADPCM-A 6 = 17 part 同時 active demo MML、 per-part 差別化可能 pattern | 30-60 秒想定 | **将来検討 (= β PR3 scope 選定対象外、 defer)** = ADR-0041 §決定 5 `design_judgment_needed` escalation 経路 + ADR-0069 §決定 3-d 新規 fixture MML 例外的許可 precedent 同 pattern、 user 明示 GO 必須 mandate、 別 sprint or 別 ADR scope 候補 |

##### β-7-3 = 採否判定 final list (= β PR3 再起票時点)

| candidate | 採否判定 | 用途 literal |
|---|---|---|
| 1 (= aj-distinctness-fixture.mml) | **補助採用** | A-J part distinctness 検証 acoustic verify gate 用 (= test pattern、 aesthetic judgment 対象外明示) |
| 2 (= SAMPLE2.MML) | **部分採用** | A/B/C/I 部分 audition material (= D/E/F/G/H/J 欠落明示)、 PMDDotNET 既存「曲」 として越川氏 aesthetic judgment 対象 |
| 3 (= l-q-rhythm-song.mml) | **採用** | rhythm/ADPCM-A audition material = K rhythm + L-Q ADPCM-A 6 ch 越川氏 aesthetic judgment 対象 |
| 4 (= 新規 17 part full active demo MML) | **将来検討 defer** | β PR3 scope 選定対象外、 必要性ありの場合別 sprint or 別 ADR scope、 user 明示 GO 必須 |

##### β-7-4 = 「実 MML を聴いて aesthetic judgment」 前提成立条件 + partial coverage 明示

candidate 2 + 3 採用で部分達成 = PMDDotNET 既存曲「SAMPLE2.MML」 (= A/B/C/I FM+SSG melody) + 「l-q-rhythm-song.mml」 (= K rhythm + L-Q ADPCM-A 6 ch) = 越川氏 aesthetic judgment 可能 sound system = 起動 14 part coverage (= A/B/C/I + K + L-Q = 4 + 1 + 6 = 11 part / 全 17 part = 65%)。

全 17 part 同時 active full coverage audition = candidate 4 future = β PR3 scope では future defer literal (= γ PR4 acceptance gate criteria 定義 + δ PR5 audition session 実施で必要性再評価可能)。

partial coverage 明示 = D/E/F/G/H/J (= FM 3 part + SSG 2 part + ADPCM-B = 6 part 不在) は β PR3 採用 material では audition 対象外。

##### β-7-5 = 不可触対象 confirm + Codex layer 2 plan review chain literal + impl-review placeholder

###### 不可触対象 confirm
- driver `src/driver/standalone_test.s` = 完全 untouched
- 既存 verify script (= ADR-0049〜0068 全 verify script + ADR-0069 β PR3 新規 `verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh`) = 完全 untouched
- 新規 fixture MML (= `src/test-fixtures/axis-b/aj-distinctness-fixture.mml`) = touch 不要、 candidate 1 として reference のみ
- 既存 fixture MML (= PMDDotNET `SAMPLE2.MML` + step5 `l-q-rhythm-song.mml`) = touch 不要、 candidate 2/3 として reference のみ
- vendor (= `song_data.inc` 含む)
- 既存 build flag
- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0026 §決定 3/4
- ADR-0041〜0064 / ADR-0066/0067/0068/0069 本文 + Annex
- **ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-6 本文 (= halt record literal、 immutable history) + Annex γ/δ/ε placeholder + 改訂履歴 既存 entry (= append only mandate、 既存 entry 書き換え禁止) + 平易要約 既存 context section 完全 untouched**
- production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= β PR3 doc-only sprint で build しない、 carry)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = scope-out (= 4 条 (4) 保持対象 3 type)
- 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = local 保持 (= 4 条 (4) 保持対象 3 type)

###### Codex layer 2 plan review chain literal (= 41st session 2026-05-26)

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | **approve** | `a1eeb29251ac69e48` | must-fix 0 + 全 8 軸 PASS (= AXIS-1 scope coverage / AXIS-2 allowed-touch + immutable / AXIS-3 audition material candidate evaluation / AXIS-4 aesthetic judgment prerequisite / AXIS-5 wording constraint compliance / AXIS-6 rollback condition untouched carry / AXIS-7 branch rule 4-mandate compliance / AXIS-8 atomic 1-set 7th application + memory excluded)、 nh 2 (= NH1 = 4 件 mandatory co-mentions 固定 boilerplate (= β-7-1 反映済) + NH2 = dashboard row status 具体化 (= 後述 dashboard 修正で反映)) + lr 3 (= LR1 = candidate file line count 実 read verify (= β-7-2 反映済 = 32/84/23 行 confirmed) + LR2 = 改訂履歴 append only mandate (= 既存 halt entry 直後 append、 既存書き換えなし) + LR3 = dashboard row status concrete wording (= 後述 dashboard 修正で final wording))、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed |

= 計 MF 0 + nh 2 + lr 3 全反映、 ADR-0065 起票 PR1 1 round approve precedent + ADR-0067/0068 ε precedent 同 doc-only sprint 1 round approve パターン継承。

###### impl-review chain (= 41st session 2026-05-26、 main agent merge 後 final fill)

| round | judgment | agentId / task id | finding 要点 |
|---|---|---|---|
| 1 (first attempt) | **cancelled** (= 経験則超過機械復旧) | task id `task-mpmg1y1q-sa0yzd` | elapsed 15m 26s anomalous (= doc-only impl-review 経験則 5-8 分超過、 user 明示新規律「Codex rescue 時必ず経過時間を見積もる + 経験則 超えたらリトライ」 経路) → main agent autonomous cancel + 1 retry |
| 1 (retry) | revise | task id `task-mpmgpkme-cplq3z` | AXIS-1〜AXIS-8 全 PASS + must-fix 1 件 (= 改訂履歴 chronological 逆順 = β PR3 再起票 entry が β halt entry の前に挿入、 LR2 append only mandate strictness 違反) → fix-up commit `2ceec1d` で chronological swap 反映 (= sed `624{h;d;}; 625{p;g;}` 経由 2 line swap、 content literal touch なし) |
| 2 | **approve** | task id `task-mpmgw6bz-49exvp` | must-fix 0 + 全 8 軸 + MF1-CONFIRM PASS = AXIS-1 PR diff 1 file swap / AXIS-2 untouched 範囲 / AXIS-3 swap content 保持 / AXIS-4 build/driver 非接触 / AXIS-5 diff = halt 前 delete + halt 後 add / AXIS-6 line 624 halt + line 625 β PR3 再起票 chronological 正常化 / AXIS-7 single hunk swap / AXIS-8 read-only commands、 nh 0 + lr 0、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 elapsed 約 1m 48s = doc-only fix-up swap 経験則 5 分 threshold 内 |

= 計 MF 1 + nh 0 + lr 0 全反映、 round 1 first attempt 経験則超過 cancel + retry pattern 実証完了 (= 41st session user 明示新規律「経過時間見積もり + 経験則超過 retry」 literal 適用 1 回目)、 Monitor grep pattern bug fix (= 「rescue.*running.*running」 → 「\| rescue \| running \|」 で phase 部分問わず) + memory `feedback_codex_rescue_always_monitor.md` 41st session 経過時間見積もり + 経験則 retry 強化 section 反映済、 ADR-0067/0068 ε + ADR-0069 γ PR4 precedent 同 doc-only sprint パターン継承 + 機械復旧 rule literal 適用 2 回目実証完了 (= ADR-0069 γ PR4 impl-review round 2 first attempt cancel + retry approve = 1 回目、 本 ADR-0065 β PR3 round 1 first attempt cancel + retry approve = 2 回目)。

= **PR #148 MERGED at `cd715ae`**、 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] **7 回目適用完走** (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148)、 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = local 保持 (= 4 条 (4) 保持対象 3 type 不可触遵守)。

#### β-8 = β revise + engineering gate sub-sprint (= 41st session 2026-05-26、 δ session 試行 invalid 後の β 採否 revise + §決定 13 engineering gate 7 items 追加 sub-sprint)

##### β-8-1 = δ session 試行 invalid + user 観測 root cause evidence (= 41st session 2026-05-26)

main agent autonomous で candidate 2 (= SAMPLE2.MML) + candidate 3 (= l-q-rhythm-song.mml) audio render 実施 (= `PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=...` build + MAME `-wavwrite` headless mode、 各 wav 960048 byte ≈ 5 秒)、 user (= 越川氏) audition session 試行 = **invalid / judgment not possible 結果**。

user 観測 literal:
- **candidate 2 (= SAMPLE2.MML)**: 「ものすごい低音の音が一定時間持続」 (= 期待 = polyphonic FM song = Intro + A/B/C section + 主旋律)
- **candidate 3 (= l-q-rhythm-song.mml)**: 「音が鳴らないまま fadeout」 (= 期待 = drum loop = bd/sd/hh/tom/rim/top)
- **そもそも何のテストか説明がなく、 判断不能** (= material intent 説明不足 + 期待音 説明不足 + render 方法 説明不足)

= aesthetic accept / reject の前段 = audition material と説明が成立していない = 3 軸 judgment 未入力で良い。

##### β-8-2 = root cause analysis (= main agent β PR3 採否誤り + engineering gate 不足 + 規律違反、 越川氏 judgment 瑕疵なし)

###### 越川氏 judgment は瑕疵なし

越川氏の aesthetic 観測 + 「説明不足で判断不能」 finding は **正当**。 audition material 採否 invalid root cause は main agent の β PR3 採否判定誤り。

###### root cause = β PR3 採否判定誤り + engineering gate 不足

- main agent β PR3 採否判定段階で **doc-only sprint** として MML 内容 + part coverage 評価のみで採否判定
- **実 audio render での aesthetic 評価対象成立を verify していなかった**
- engineering gate (= 機械検査 with metric pass) を踏まずに human audition phase へ進めようとした

###### memory `feedback_ai_engineering_gate_before_human_audition.md` 規律違反

memory 規律 = 「AI engineering 検査 → human aesthetic audition 順序固定」、 「engineering pass ≠ aesthetic accept」、 「acceptance は downstream upstream ではない」 = ADR-0067/0068 (= engineering verify) → ADR-0065 (= human audition) order。

main agent β PR3 採否判定 = engineering verify を skipping して human audition phase へ進めた = **順序固定違反**。

= 本 β revise sprint で engineering gate 確立 = **AI engineering 検査 → human aesthetic audition 順序固定 restore confirmed** literal。

##### β-8-3 = audition material 採否 revise (= 41st session β revise)

| candidate | β PR3 採否 (= 旧) | β revise 採否 (= 41st session 新) | 根拠 |
|---|---|---|---|
| 1 = aj-distinctness-fixture.mml | 補助採用 = acoustic verify gate | **補助採用維持** = acoustic verify gate (= 3 軸対象外、 越川氏 aesthetic judgment 対象外明示) | β-8-1 user 観測対象外、 ADR-0069 verify gate 用途維持 |
| 2 = SAMPLE2.MML | 部分採用 = A/B/C/I 部分 audition | **不採用候補 revise** (= 「現状の render では aesthetic judgment 不成立」) | user 観測 「ものすごい低音持続」 = 期待 polyphonic FM song と乖離、 engineering gate 7 items 全 fail 予想 |
| 3 = l-q-rhythm-song.mml | 採用 = K rhythm + L-Q ADPCM-A | **不採用候補 revise** (= 「現状の render では aesthetic judgment 不成立」) | user 観測 「無音 fadeout」 = 期待 drum loop と乖離、 engineering gate 7 items 全 fail 予想 (= silence check fail 確実) |
| 4 = 新規 17 part full active demo MML | 将来検討 defer (= γ scope-out) | **将来検討 defer 維持** (= γ scope-out、 user 明示 GO 必須) | β revise sprint scope-out、 別 sprint 起票判断 (= 別 sub-sprint or 別 ADR scope) |

= candidate 2/3 = **「現状の render では aesthetic judgment 不成立」 不採用候補 revise**、 candidate 1 = 補助採用維持、 candidate 4 = 将来検討 defer 維持。

##### β-8-4 = engineering gate 7 items 定義 (= §決定 13 と整合、 詳細 §決定 13 参照)

§決定 13 で literal 定義済 7 items:
1. wav duration ≥ 期待 duration
2. RMS amplitude > silence threshold
3. silence check (= 全 sample 非ゼロ)
4. FM keyon count ≥ 期待値
5. SSG tone write ≥ 期待値
6. ADPCM-A trigger count ≥ 期待値
7. expected audible content match (= 機械的整合確認、 LR1 反映 = metric pass ≠ aesthetic pass 混同回避)

= all 7 gate items pass mandate、 1 件 fail で δ halt + material revise trigger。

##### β-8-5 = audio render 前 expected audio 説明 format (= material id + 期待音 文字列 + render 後 engineering gate 結果 + gate pass/fail 判定)

###### format literal

```markdown
## audition material: <material-id>
- source: <MML file path>
- 期待音 (= expected audible content): <自然言語、 melody + harmony + rhythm 等の構造説明>
- 期待 duration: <seconds>
- 期待 FM keyon count: <≥ N>
- 期待 SSG tone write: <≥ N>
- 期待 ADPCM-A trigger count: <≥ N>

## render 後 engineering gate 結果

| gate item | 期待値 | 実測値 | pass/fail |
|---|---|---|---|
| 1. wav duration | <≥ N秒> | <実 N秒> | <PASS/FAIL> |
| 2. RMS amplitude | <> silence threshold> | <実 RMS> | <PASS/FAIL> |
| 3. silence check | <非ゼロ> | <ゼロ/非ゼロ> | <PASS/FAIL> |
| 4. FM keyon count | <≥ N> | <実 N> | <PASS/FAIL> |
| 5. SSG tone write | <≥ N> | <実 N> | <PASS/FAIL> |
| 6. ADPCM-A trigger count | <≥ N> | <実 N> | <PASS/FAIL> |
| 7. expected audible content match | <期待音 文字列 vs trace 機械的整合> | <整合/不整合> | <PASS/FAIL> |

= **all 7 PASS 判定** (= δ 進行可) or **1 件以上 FAIL 判定** (= δ halt + material revise trigger)
```

= δ session 実施前に material id 別 audio render result が engineering gate 7 items 機械検査結果 literal で record + Annex δ literal carry。

##### β-8-6 = gate pass 後 δ audition session 進行規律 + 順序固定 restore literal + 不可触対象 confirm + Codex chain

###### gate pass 後 δ 進行規律

- **all 7 gate items pass 後** = δ session 開始前提条件成立 → δ PR5 起票判断 (= user 介入 mandatory)
- **1 件 fail** = δ halt + material revise trigger → β revise sprint 再起票 (= β-8 revise) or 別 material 探索 sub-sprint or 別 ADR scope

###### 順序固定 restore literal (= LR2 反映)

**memory `feedback_ai_engineering_gate_before_human_audition.md` 規律 = AI engineering 検査 → human aesthetic audition 順序固定**、 本 β revise sprint で engineering gate 確立 → 順序固定 restore confirmed。 ADR-0067/0068 (= engineering verify) → ADR-0065 audition phase (= engineering gate pass 後 human audition) order 整合。

###### 不可触対象 confirm

- driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag = 完全 untouched
- ADR-0048 軸 G ε partial state / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex = 完全 untouched
- **ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-7 本文 + Annex γ (= γ-1〜γ-5 final) + Annex δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section 完全 untouched** (= LR2 append only mandate 厳守)
- production sha256 = `b15883fe...` 維持期待 (= β revise doc-only sprint で build しない、 carry)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = scope-out
- 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = local 保持
- audition/2026-05-26/session-1/ (= δ 試行 wav 2 件) = repo 外 artifact、 `.gitignore` audition/ excluded、 PR diff target excluded、 β-8-1 で literal reference

###### Codex layer 2 plan review chain literal (= 41st session 2026-05-26)

| round | judgment | agentId / task id | finding 要点 |
|---|---|---|---|
| 1 | revise | agentId `a7fed7dcb9dedb574`、 task id `task-mpmijdqp-gjluh8` | must-fix 2 (= MF1 §決定 5 rollback condition untouched carry 明記不足 + MF2 branch operation 4-rule plan 内明示不足) + nh 1 (= dashboard 0065 row status update placeholder column + 予定文言 具体化) + lr 2 (= LR1 dashboard row update 文言未確定 + LR2 ordering-fix restore literal ADR 本文 literal 反映) → plan v2 全反映 |
| 2 | **approve** | agentId `adad46f3950ddec5e`、 task id `task-mpmio7ct-5dyjpm` | must-fix 0 + 全 9 軸 PASS (= AXIS-1 scope coverage / AXIS-2 allowed-touch + 不可触 / AXIS-3 β PR3 採否 revise validity / AXIS-4 engineering gate definition validity / AXIS-5 δ prerequisite engineering gate pass rule / AXIS-6 memory rule compliance + LR2 ordering-fix restore literal 反映 / AXIS-7 wording constraint compliance / AXIS-8 rollback condition untouched + branch 4-rule (= round 1 FAIL → round 2 PASS) / AXIS-9 atomic set rule 9th application)、 nh 0 + lr 2 (= LR1 expected audible content match metric pass ≠ aesthetic pass 混同回避 + LR2 §決定 2 β row 実文面 semantic update)、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed |

= 計 MF 2 + nh 1 + lr 4 全反映、 doc-only plan review 経験則 8 分 threshold 内 (= round 1 約 1m 30s + round 2 約 3m)、 41st session 経験則 retry default 規律遵守 (= retry 不要)、 ADR-0065 起票 PR1 + γ PR4 + 本 β revise plan v2 round 2 approve precedent 同 doc-only sprint パターン継承。

###### impl-review chain placeholder (= main agent merge 後 final fill)

placeholder。 PR 起票 + impl-review approve loop + main agent merge 後に fill (= doc-only impl-review 経験則 2-5 分目安、 threshold 8 分、 Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default)。

### Annex γ: sub-sprint γ acceptance gate criteria 定義 doc-only (= γ PR4 fill 完了 = 41st session 2026-05-26)

#### γ-1: γ PR4 scope literal

γ PR4 = sub-sprint chain α/β/γ/δ/ε 5 段の γ 段 = doc-only sprint = δ audition session 実施前の **acceptance gate criteria 定義** 完走。 ADR-0069 Accepted (= PR #147 MERGED at `0cde9f6`) で「実 MML を聴いて aesthetic judgment」 前提成立 + ADR-0065 β PR3 再起票完了 (= PR #148 MERGED at `cd715ae`) で audition material 採否判定 final 完了。 次 δ PR5 (= user 介入 mandatory) の audition session 実施前提として、 越川氏 audition input をどの schema で受領 + どう判定するかを literal 文書化。

scope = (i) **3 軸独立 schema 明記** (= pairwise comparison + individual acceptance + 全 reject、 memory 4 規律遵守) + (ii) **candidate 1/2/3 役割を judgment 基準に接続** + (iii) **δ session 実施時の 3 軸入力 method** literal + (iv) **candidate 4 (= 17 part full active demo MML) γ scope-out 明示** + (v) **不可触対象 confirm + Codex layer 2 plan review chain literal + impl-review chain placeholder**。 driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state + ADR-0026 §決定 3/4 + ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / ADR-0065 既存 §決定 1 + 3-12 + Annex A/B/α 本文 + Annex β-1〜β-7 (= immutable history) + Annex δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section = 完全不変。 PR diff target = ADR-0065 doc + dashboard 2 file 限定。 memory + MEMORY.md = main agent direct Write/Edit (= 別途、 repo 外、 PR diff target excluded、 merge 後実施)。 production sha256 = `b15883fe...` 維持期待 (= γ doc-only sprint で build しない、 carry)。

#### γ-2: 3 軸独立 schema 明記 (= memory 4 規律遵守 literal)

memory 規律遵守 base: `feedback_relative_preference_vs_absolute_acceptance.md` (= pairwise + individual + 全 reject 3 軸独立 schema literal) + `feedback_preference_learning_beats_metric_correlation.md` (= preference learning > metric correlation) + `feedback_metric_pass_is_not_aesthetic_pass.md` (= metric pass ≠ aesthetic pass、 human aesthetic gate is authoritative) + `feedback_ai_engineering_gate_before_human_audition.md` (= AI engineering 検査 → human aesthetic audition 順序固定)。

##### axis 1: pairwise comparison (= 候補間相対比較)

- input enum = `A_better_than_B` / `B_better_than_A` / `tie` の 3 値
- 対象 = 採用 candidate 間の組合せ (= candidate 2 vs candidate 3 が primary pairwise)
- 用途 = 候補間 ranking (= preference learning)
- limit = pairwise は ranking のみ提供、 「個別 candidate が production-ready acceptable か」 を表現しない (= individual acceptance axis と分離 mandatory)
- 範例 = 「candidate 2 (= SAMPLE2.MML A/B/C/I FM+SSG melody) is better than candidate 3 (= l-q-rhythm-song.mml K rhythm + L-Q ADPCM-A 6 ch)」 の入力可、 ただし両者個別の accept 可否は別軸で別判定

##### axis 2: individual acceptance (= 個別採用判定)

- input enum = `aesthetic_accept` / `revise_required` / `reject` の 3 値
- 対象 = 各採用 candidate 単独 (= candidate 2 個別 + candidate 3 個別)
- 用途 = 各 candidate が production-ready acceptable か / revise mandatory か / reject mandatory か
- limit = pairwise の結果と独立、 「pairwise better でも individual reject 可能」 (= ranking is not acceptance)
- 範例 = candidate 2 = `aesthetic_accept` + candidate 3 = `revise_required` (= 各 candidate 独立判定)

##### axis 3: global reject all (= 全 candidate reject)

- input = `global_reject_all` (= 全採用 candidate reject + 全体 redo 必要 trigger)
- 用途 = 全 candidate が aesthetic 不成立 = audition material 全面再選定 trigger (= candidate 4 future or 別 sprint or 別 ADR)
- limit = individual `reject` ≠ `global_reject_all` (= individual reject は 1 candidate のみ reject、 global は全 candidate reject + audition material 全体 redo)
- 範例 = δ session で 「candidate 2 + candidate 3 + candidate 4 future も含めて aesthetic 不成立」 = global_reject_all trigger = ADR-0065 §決定 5 rollback condition 該当可能性 + 別 audition material 起票 sprint trigger

##### 3 軸独立 mandatory (= memory `feedback_relative_preference_vs_absolute_acceptance.md` literal)

- 3 軸は **必ず別 field で記録** (= 同 field で混在禁止)
- 「全 reject」 でも pairwise 入力可能 (= ranking 入力は acceptance とは独立)
- preference model は accepted asset selector ではない
- script に `global_reject_all` gate 実装必須

#### γ-3: candidate 1/2/3 役割を judgment 基準に接続 literal

| candidate | source | 採否 (= β PR3 final) | 3 軸 schema 接続 | aesthetic judgment 対象 |
|---|---|---|---|---|
| 1 | `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` (32 行) | **補助採用** = acoustic verify gate | **3 軸対象外** (= test pattern、 越川氏 aesthetic judgment 対象外、 audio render は acoustic verify gate 用途のみ) | NO |
| 2 | `vendor/PMDDotNET/SAMPLE2.MML` (84 行) | **部分採用** = A/B/C/I 部分 audition | **3 軸全対象** = pairwise vs candidate 3 + individual aesthetic_accept/revise_required/reject + 全 reject (= global_reject_all 該当時 contribute) | YES |
| 3 | `src/test-fixtures/step5/l-q-rhythm-song.mml` (23 行) | **採用** = K rhythm + L-Q ADPCM-A 6 ch audition | **3 軸全対象** = pairwise vs candidate 2 + individual aesthetic_accept/revise_required/reject + 全 reject (= global_reject_all 該当時 contribute) | YES |
| 4 | 新規 audition material MML (= 17 part full active demo) | **将来検討 defer** (= β PR3 final = γ scope-out 維持) | **γ scope-out** = future / full coverage 補強候補、 δ session 全 reject (= global_reject_all) trigger 該当時 future trigger record | NO (= γ scope) |

#### γ-4: δ session 実施時の 3 軸入力 method literal

##### step 1: audio render (= production-ready 経路)

- chip target = ym2610 production default
- build path = `scripts/build-poc.sh` + production default flag (= PMDNEO_USE_PMDDOTNET=1 + PMDDOTNET_MML=... 経路、 ADR-0065 既存 §決定 1 production-ready 経路 literal 整合)
- emulator = MAME `-wavwrite` 経由 audio render (= ADR-0065 既存 Annex α-2 emulator 環境設定 literal 整合)
- output = wav file (= 48 kHz / 16-bit / 2ch、 ADR-0065 既存 Annex α-3 audio render spec 整合、 repo 外 artifact 配置)
- candidate 2 + candidate 3 各 1 wav (= candidate 1 = acoustic verify gate 用は別 verify gate phase で render)

##### step 2: 越川氏 audition session

- audition material = candidate 2 + candidate 3 の wav (= 各 1 wav)
- audition 環境 = MAME or AES+ で実音確認
- session 形式 = 越川氏 (= user 本人) が 各 wav を聴き、 3 軸 schema 各軸入力を確定

##### step 3: 3 軸入力 (= 越川氏 → main agent 起草 → user confirm process)

- **pairwise comparison input** = `A_better_than_B` / `B_better_than_A` / `tie` (= candidate 2 vs candidate 3)
- **individual acceptance input (× 2)** = candidate 2 単独 `aesthetic_accept` / `revise_required` / `reject` + candidate 3 単独 `aesthetic_accept` / `revise_required` / `reject`
- **global reject all input** = `false` (= 非該当、 candidate 2 + 3 のいずれかが aesthetic_accept か revise_required) or `true` (= candidate 2 + 3 + candidate 4 future も含め全 reject、 audition material 全面再選定 trigger)
- input 入力 method = ADR-0041 §決定 4-3 主軸 fallback + user confirm pattern 継承 (= main agent が draft input → user confirm の 3 段階 process)

##### step 4: 結果 record (= Annex δ literal)

- text record = markdown report (= judgment table + 越川氏 aesthetic finding text + revision request literal)
- structured record = JSONL aesthetic finding schema (= ADR-0065 既存 §決定 11 audition record format 整合、 `feedback_relative_preference_vs_absolute_acceptance.md` 3 軸独立 schema 整合)
- audio artifact = wav repo 外 (= `.gitignore` audition/ excluded 整合、 ADR-0065 既存 §決定 11 + Annex α-4 整合)

#### γ-5: candidate 4 (= 新規 17 part full active demo MML) γ scope-out 明示 + 不可触対象 + Codex chain

##### candidate 4 γ scope-out literal

- **γ scope-out 明示** = β PR3 final (= candidate 4 = 将来検討 defer) 継承、 γ scope では選定対象外 + judgment 基準対象外
- **future trigger condition** = δ session 結果が `global_reject_all = true` (= candidate 2 + 3 両 reject) で audition material 全面再選定必要時 + ADR-0041 §決定 5 `design_judgment_needed` escalation 経路 + ADR-0069 §決定 3-d 新規 fixture MML 例外的許可 precedent 同 pattern
- **起票判断** = user 明示 GO 必須 (= main agent autonomous で進めない、 別 sprint or 別 ADR scope)

##### 不可触対象 confirm
- driver `src/driver/standalone_test.s` = 完全 untouched
- 既存 verify script (= ADR-0049〜0068 全 verify script + ADR-0069 β PR3 新規 `verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh`) = 完全 untouched
- 新規 fixture MML (= `aj-distinctness-fixture.mml`) = touch 不要、 candidate 1 reference のみ
- 既存 fixture MML (= PMDDotNET SAMPLE2.MML + step5 l-q-rhythm-song.mml) = touch 不要、 candidate 2/3 reference のみ
- vendor (= `song_data.inc` 含む)
- 既存 build flag
- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0026 §決定 3/4
- ADR-0041〜0064 / ADR-0066-0069 本文 + Annex
- **ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-7 本文 (= halt + 再起票 record literal、 immutable history) + Annex δ/ε placeholder + 改訂履歴 既存 entry (= LR2 append only mandate 厳守 = 新 entry は既存 entry の後ろに append) + 平易要約 既存 context section 完全 untouched**
- production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= γ doc-only sprint で build しない、 carry)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = scope-out (= 4 条 (4) 保持対象 3 type)
- 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = local 保持 (= 4 条 (4) 保持対象 3 type)

##### Codex layer 2 plan review chain literal (= 41st session 2026-05-26)

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | **approve** | `a9bb0fe9ee79343bc` (= task id `task-mpmhcnfz-8f6wk3`) | must-fix 0 + 全 8 軸 PASS (= AXIS-1 scope coverage / AXIS-2 allowed-touch + 不可触 / AXIS-3 3 軸独立 schema validity / AXIS-4 candidate 1/2/3 role connection / AXIS-5 notation constraints / AXIS-6 §決定 5 rollback untouched carry / AXIS-7 branch 4-clause compliance / AXIS-8 atomic 1-set 8th application)、 nh 1 + lr 2 全反映 = NH1 = dashboard placeholder wording を γ criteria-definition status 限定明記 + LR1 = dashboard final wording γ criteria-definition status のみ収まる executor 確認 + LR2 = memory direct Write/Edit after merge γ PR4 PR diff 混入 prevention、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 elapsed 約 1m 55s = doc-only plan review 経験則 8 分 threshold 内、 ADR-0065 起票 PR1 + 本 γ PR4 = 1 round approve precedent 同 doc-only sprint パターン継承 |

= 計 MF 0 + nh 1 + lr 2 全反映、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 doc-only plan review 経験則 base retry pattern 確立 (= ADR-0065 β PR3 round 1 first attempt cancel + retry approve precedent 同 pattern、 本 γ PR4 plan review = 1 attempt approve 即了)。

##### impl-review chain (= 41st session 2026-05-26、 main agent merge 後 final fill)

| round | judgment | agentId / task id | finding 要点 |
|---|---|---|---|
| 1 | **approve** | agentId `ad67d8afae738d231`、 task id `task-mpmhnnxn-ongjex` | must-fix 0 + 全 8 軸 PASS = AXIS-1 PR diff 2 file 限定 / AXIS-2 allowed-touch + 不可触 / AXIS-3 3 軸独立 schema validity / AXIS-4 candidate 1/2/3 role connection / AXIS-5 表記制約準拠 / AXIS-6 §決定 5 rollback untouched carry / AXIS-7 branch 運用 4 条 / AXIS-8 atomic 8 回目 + memory excluded、 nh 0 + lr 0、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 elapsed 約 2m 14s = doc-only impl-review 経験則 8 分 threshold 内 |

= 計 MF 0 + nh 0 + lr 0、 doc-only impl-review 経験則 base 1 attempt approve 即了 = ADR-0065 起票 PR1 + 本 γ PR4 = 1 round approve precedent 同 doc-only sprint パターン継承、 41st session 経験則 retry default 規律遵守 confirmed。

= **PR #149 MERGED at `e4ec4c7`**、 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] **8 回目適用完走** (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148 + #149)、 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = local 保持 (= 4 条 (4) 保持対象 3 type 不可触遵守)。

### Annex δ: sub-sprint δ audition session 実施 + record + finding + acceptance decision (= δ PR5 で fill)

placeholder (= user 介入 mandatory section、 audition session 実施結果 literal record)。

### Annex ε: sub-sprint ε Draft → Accepted 移行 + Annex 全統合 + milestone wording 解禁 (= ε PR6 で fill)

placeholder。

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
| 2026-05-25 | 40th session | ADR-0065 起票 Draft = roadmap ⑥ audition ADR (= 越川氏 audition gate、 aesthetic gate、 production-ready 経路 audition session approve = ADR-0056 §決定 3-b literal、 ADR-0063 §(d) literal、 ADR-0064 §決定 7 番号予約消化、 ADR-0067 残課題 + ADR-0068 §決定 9 ADR-0065 候補後続、 集約 HEAD `037cd3e`、 doc-only 起票 PR1 = ADR-0067/0068 起票 pattern 継承、 Codex layer 2 plan review 1 round approve = must-fix 0 + nice-to-have 1 件 (= PR5 wav repo 外 artifact 配置 = §決定 11 + §決定 5 (i)/(iii) 反映) + latent risk 1 件 (= ADR-0069 parallel 起票時 sha256 維持運用順序 4 選択肢 + user 明示 GO 必須 = §決定 9 反映) 全反映、 agentId `afbed0b24a60caa41`、 越権操作なし confirmed)。 ADR doc 修正範囲 = (1) ADR-0065 file 新規 (= 12 決定 + Annex skeleton A/B/α/β/γ/δ/ε + 改訂履歴 + 平易要約) + (2) dashboard 0065 行 update (= 「未起票」 → 「Draft 起票」 + 12 決定 literal + 表記制約 + 不可触対象 + Codex layer 2 plan review 1 round approve literal) + (3) dashboard escalation 履歴 ADR-0065 entry 1 row 追加 + (4) memory 起票 (= 新 memory `project_pmdneo_adr_0065_initiated.md` + MEMORY.md index 1 行追加、 repo 外 PR 対象外)。 sub-sprint chain α/β/γ/δ/ε 5 段 plan literal (= α audition session 準備 + β material 選定 + γ acceptance gate criteria + δ audition session 実施 (= user 介入 mandatory) + ε Accepted 移行) + PR chain plan 6 PR + production sha256 維持 mandatory (= `b15883fe...` 通算維持、 driver 不変) + 表記制約 (= 起票時点 禁止 6 件 + ε Accepted 後解禁候補 3 件 + 禁止維持 5 件) + acceptance framework 3 軸 (= pairwise + individual + 全 reject) memory 規律遵守 + audition record format (= text markdown + JSONL + wav repo 外 artifact) + 番号 chronology rationale (= ADR-0064 §決定 7 整合)。 driver / α script / β script / γ script / 既存 verify script / vendor / ADR-0067 fixture / 既存 build flag / ADR-0041〜0068 本文 + Annex 完全不変、 production sha256 = `b15883fe...` 維持期待 (= ADR-0065 で再 build しない、 §決定 10 整合)、 commit chain = 単一 commit (= 本 commit) | (= 本 PR1 commit chain 内 commit 1) |
| 2026-05-25 | 40th session | ADR-0065 sub-sprint α PR2 = audition session 準備 doc-only sprint (= ADR-0065 §決定 2 α row literal 継承 = production binary build 確認 + emulator (MAME) 環境確認 + audition record format 定義 (= 決定 11)、 PR #140 MERGED at `c3ed5e0` 後続、 集約 HEAD `c3ed5e0`、 Codex layer 2 plan review 主軸 fallback approve plan v1 = ADR-0041 §決定 4-3 適用 (= Codex companion 安全性分類器 (claude-opus-4-7) 一時障害 2 回連続失敗 = `claude-opus-4-7[1m] is temporarily unavailable` error = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 該当、 user 明示 option B = ADR-0041 §決定 4-3 fallback + retrospective Codex review 必須 採用、 doc-only sprint + scope 明確 + retrospective review 必須が fallback 適用根拠、 主軸 Claude Code が plan v1 を独立 review = 6 axis (= A scope literal coverage + B α-1 production binary build + C α-2 MAME / emulator + D α-3 audio render + α-4 record format + E α-5 judgment 記録形式 + F α-6 不可触対象 + commit chain) 全 OK = approve 判断、 must-fix 0 + nice-to-have 0 + latent risk 1 件 = MAME version literal specificity (= α では abstract OK + δ で具体 version 確定 natural) は retrospective Codex review で再確認)、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed (= 主軸 fallback でも commit 権限分離維持)、 40th session ε で確立した「主軸 fallback + retrospective Codex review」 pattern (= ADR-0041 §決定 4-3 full cycle 完走実証完了) 継承)。 ADR doc 修正範囲 = (1) §決定 2 α row update (= 「α 完了 (= 本 PR2) = build 環境 + emulator + format 確定 literal record (= Annex α fill 6 sub-section、 ADR-0041 §決定 4-3 主軸 fallback approve plan v1 + retrospective Codex review 必須)」) + (2) Annex α fill = 6 sub-section literal (= α-1 production binary build 確認方針 = (A) production default + sha256 確認 mandatory + build script `scripts/build-poc.sh` reference + α-2 MAME / emulator 環境確認方針 = MAME version + command `scripts/run-mame.sh` + audio render flag `-wavwrite` + headless 録音 mode `project_mame_headless_recording_mode.md` 整合 + chip target ym2610 production default + α-3 audio render の前提 = ADR-0058/0059/0067/0068 base + 48 kHz/16-bit/2ch spec + α-4 audition record format = markdown report path schema + JSONL aesthetic finding schema literal + wav repo 外 artifact 配置 (= `.gitignore` audition/ excluded 反映) + α-5 越川氏 judgment 記録形式 = aesthetic finding text + acceptance decision enum (= aesthetic_accept / revise_required / all_reject) + judgment 入力 method (= 主軸起草 → user confirm process 3 段階) + memory 4 件 regulation cite + α-6 不可触対象 literal + α PR2 touch 範囲 + α PR2 Codex layer 2 plan review chain literal (= 4 round = round 1 unavailable + round 1 retry unavailable + fallback 主軸 approve + retrospective TBD)) + (3) 改訂履歴 α entry 追加 (= 本 entry) + (4) 平易要約 α context section 追加 (= α PR2 完走 update 6 構造)。 dashboard 修正範囲 = (5) 0065 行 status column update (= 「Draft 起票」 → 「Draft + α 完了」 + α 完了 entry literal) + (6) escalation 履歴 α PR2 entry 1 row 新規追加 (= ADR-0065 PR1 entry 直前 = 最新位置)。 `.gitignore` 修正 = (7) `audition/` directory excluded entry 1 行追加 (= 新規、 nice-to-have 反映 = repo 外 artifact 配置 path 安全化)。 memory 修正 = (8) `project_pmdneo_adr_0065_initiated.md` α 完走 entry 追加 (= repo 外、 PR diff 対象外、 主軸直接 Write/Edit)。 driver / α script / β script / γ script / 既存 verify script / vendor / ADR-0067 fixture / 既存 build flag / ADR-0041〜0068 本文 + Annex / ADR-0068 既存 Annex α/β/γ/δ + Annex A/B/ε / ADR-0065 §決定 1-12 本文 / §verify gate / §Codex layer 2 plan review chain / Annex skeleton 他 sub-section 完全不変 = doc-only sprint。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= α で再 build しない、 §決定 10 整合)。 commit chain = 単一 commit (= 本 commit、 ADR-0065 PR1 同 pattern 継承)。 後続 = retrospective Codex review (= Codex 復旧後) + main agent 経路 merge + user 完走報告、 sub-sprint β PR3 起票判断 = user 明示 GO 必須、 ADR-0066/0069 候補 起票判断 = 各 user 明示 GO 必須 | (= 本 PR2 commit chain 内 commit 1) |
| 2026-05-25 | 40th session | ADR-0065 sub-sprint α PR2 retrospective Codex review 完走 = approve 判定 (= 本 retrospective record、 PR #141 MERGED at `aef02b0` 後続、 集約 HEAD `aef02b0`、 Codex companion 復旧後 retrospective Codex layer 2 review 投入 = ADR-0041 §決定 4-3 retrospective review 必須 適用、 agentId `ac5bbe0460b71e59d`、 6 axis 全 OK (= Axis 1 plan v1 / Axis 2 impl / Axis 3 fallback 適用根拠 / Axis 4 scope 違反なし / Axis 5 wording 制約遵守 / Axis 6 memory + dashboard consistency)、 must-fix 0 + nice-to-have 0 + latent risk 1 件 = MAME version literal specificity (= α では abstract OK + δ で具体 version 確定 natural、 Annex α-2「既存 PMDNEO repo 内で使用中の MAME version」 + 「δ session 実施時に確定」 + 「session 全体で同一 version 使用 mandatory」 literal で current must-fix ではない)、 主軸 fallback judgment 事後 confirm = approve、 全 review-only + 越権操作なし confirmed、 40th session ε PR6 で full cycle 完走実証済 pattern 2 回目適用 = 主軸 fallback + retrospective Codex review pattern 安定化実証完了、 ADR-0065 α PR2 commit chain 単一 commit + retrospective record commit chain 単一 commit = doc-only carry)。 ADR doc 修正範囲 = (1) #### α PR2 Codex layer 2 plan review chain table の retrospective row update (= 「TBD」 → 「**approve**」 + agentId + 6 axis + must-fix 0 + nh 0 + lr 1 件 literal) + (2) 同 table 直後 summary 段落 update (= 「retrospective Codex review TBD」 → 「retrospective Codex review approve」 + pattern 2 回目適用 安定化実証 literal) + (3) §決定 2 α row update (= 「α 完了 (= 本 PR2) + retrospective approve (= 本 retrospective record) = build 環境 + emulator + format 確定 literal record + retrospective Codex review 完走 = approve 判定」) + (4) 改訂履歴 retrospective record entry 追加 (= 本 entry)。 dashboard 修正範囲 = (5) 0065 行 status column update (= 「Draft + α 完了」 → 「Draft + α 完了 + retrospective approve」 + retrospective approve entry literal) + (6) escalation 履歴 α PR2 entry reviewed column update (= 「pending」 → 「approve」 + retrospective Codex review judgment 詳細 literal) + (7) escalation 履歴 retrospective record entry 1 row 新規追加 (= ADR-0065 α PR2 entry 直前 = 最新位置)。 memory 修正 = (8) `project_pmdneo_adr_0065_initiated.md` retrospective approve entry 追加 (= 別途、 repo 外、 PR diff 対象外、 主軸直接 Write/Edit)。 driver / α script / β script / γ script / 既存 verify script / vendor / ADR-0067 fixture / 既存 build flag / ADR-0041〜0068 本文 + Annex / ADR-0068 既存 Annex α/β/γ/δ + Annex A/B/ε / ADR-0065 §決定 1-12 本文 / §verify gate / Annex skeleton 他 sub-section (= Annex α 6 sub-section 本文不変、 §Codex layer 2 plan review chain table 内 retrospective row のみ update + 直後 summary 段落 update + §決定 2 α row 完了判定列 update) 完全不変 = doc-only sprint。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= retrospective record で再 build しない、 §決定 10 整合)。 commit chain = 単一 commit (= 本 commit、 ADR-0068 ε retrospective fix 同 pattern 継承 = retrospective fix 0 件 + retrospective approve record のみ)。 後続 = Codex layer 2 impl-review on retrospective record + approve loop + main agent 経路 merge + user 完走報告、 sub-sprint β PR3 起票判断 = user 明示 GO 必須、 ADR-0066/0069 候補 起票判断 = 各 user 明示 GO 必須 | (= 本 retrospective record commit chain 内 commit 1) |
| 2026-05-25 | 40th session | ADR-0065 sub-sprint β PR3 halt record (= 本 commit、 user option 3 採用 = ADR-0069 先行起票 + ADR-0065 β/δ はその後 dependency 順序固定、 PR #142 MERGED at `f40ae8c` + dashboard maintenance `702da44` 後続、 集約 HEAD `702da44`、 β PR3 plan v2 round 2 Codex layer 2 plan review revise 後 main agent escalation = ADR-0041 §決定 5 `design_judgment_needed` 経路 = 4 option 提示 + user 採用 option 3 = ADR-0069 先行起票 + β/δ halt。 halt 経緯 = β PR3 plan v1 round 1 revise (= must-fix 6 件 = SAMPLE2 MML 実内容誤 + build mode 混同 + 越川氏 verify claim 誤 + 不可触衝突、 agentId `a7e63962cb989934c`) + plan v2 round 2 revise + escalate (= must-fix 2 件 = driver capability 制約 = ADR-0068 §決定 1 「A-J は全 build mode で default 固定、 C-2 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 literal + ADR-0065 §決定 10 vs C-2 build 衝突、 agentId `a8681fb73a77eacfc`) + 主軸 escalation で「PMDDotNET MML の A/B/C/I etc は現 driver で audition audio に出ない、 実 MML を聴いて aesthetic judgment 前提不成立」 finding 提示 = user 4 option 中 option 3 採用 (= ADR-0069 先行起票 + ADR-0065 β/δ はその後 dependency 順序固定))。 ADR doc 修正範囲 = (1) §決定 2 β row 完了判定 column update (= 「halt (= pending、 ADR-0069 完走後 再開、 user option 3 採用)」 + driver capability 制約 literal + ADR-0069 dependency 順序固定 literal) + (2) §決定 9 ADR-0069 dependency literal update (= 元「ADR-0065 と independent、 parallel 起票可」 → 「ADR-0065 β 再開のために先行完走必須 dependency = ADR-0069 → ADR-0065 β/δ 順序固定」、 旧 sha256 維持運用順序 4 選択肢 obsolete record) + (3) Annex β fill = 6 sub-section literal (= β-1 halt 経緯 + β-2 driver capability 制約 ADR-0068 §決定 1 literal + β-3 ADR-0069 dependency + β-4 β PR3 再開時前提変更 placeholder + β-5 halt 中不可触対象 + β-6 touch 範囲 + Codex layer 2 plan review chain literal) + (4) 改訂履歴 halt entry 追加 (= 本 entry、 chronological order = retrospective record entry の直後最新位置) + (5) 平易要約 β halt context section 追加 (= β halt 6 構造)。 dashboard 修正範囲 = (6) 0065 行 status column update (= 「Draft + α 完了 + retrospective approve」 → 「Draft + α 完了 + retrospective approve + β halt (= ADR-0069 先行 dependency)」 + halt entry literal) + (7) escalation 履歴 β PR3 halt entry 1 row 新規追加 (= ADR-0065 retrospective record entry 直前 = 最新位置)。 memory 修正 = (8) `project_pmdneo_adr_0065_initiated.md` β halt entry 追加 (= 別途、 repo 外、 PR diff 対象外、 主軸直接 Write/Edit)。 driver / α script / β script / γ script / 既存 verify script / vendor / ADR-0067 fixture / 既存 build flag / ADR-0041〜0068 本文 + Annex / ADR-0068 既存 Annex α/β/γ/δ + Annex A/B/ε / ADR-0065 §決定 1 + 3-8 + 10-12 本文 / §verify gate / §Codex layer 2 plan review chain / Annex α (= 本文 + retrospective row + summary 段落 already final) / Annex skeleton 他 sub-section (= γ/δ/ε placeholder + A/B 本文) 完全不変 = doc-only sprint。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= β halt record で再 build しない、 §決定 10 整合)。 commit chain = 単一 commit (= 本 commit、 retrospective record 同 pattern 継承)。 後続 = Codex layer 2 impl-review on halt record + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 + memory update + ADR-0069 起票判断へ移行 (= allowed-touch + production sha256 維持方針 + rollback 条件 明確化 先行)、 ADR-0065 β/δ 再開 = ADR-0069 完走後 future、 ADR-0066 起票判断 = ADR-0065 ε Accepted 後 future (= 順序固定維持)。 | (= 本 halt record commit chain 内 commit 1) |
| 2026-05-26 | 41st session | ADR-0065 sub-sprint β PR3 再起票 record (= halt 解消後 再開、 ADR-0069 Accepted (= 2026-05-26 41st session、 PR #147 MERGED at `0cde9f6` + final maintenance `916b600`) 後の β/δ 再開 trigger 発火 confirmed、 base anchor `wip-pmddotnet-opnb-extension@916b600`、 user 明示 GO「ADR-0065 β PR3 再起票が自然な次。 scope = audition material 選定 doc-only。 K bitmap pair distinct は ADR-0070 future として β scope に混ぜない。 必要なら新規 audition material MML 候補」 受領 + 主軸並走 3 sub-agent investigation 完了 (= Agent A = aj-distinctness-fixture audition 適性 / Agent B = PMDDotNET 既存 MML 候補 / Agent C = rhythm/ADPCM-A material + 新規 material 必要性) + Codex layer 2 plan review 1 round chain approve plan v1 (= agentId `a1eeb29251ac69e48`、 must-fix 0 + 全 8 軸 PASS = AXIS-1 scope coverage / AXIS-2 allowed-touch + immutable / AXIS-3 audition material candidate evaluation / AXIS-4 aesthetic judgment prerequisite / AXIS-5 wording constraint compliance / AXIS-6 rollback condition untouched carry / AXIS-7 branch rule 4-mandate compliance / AXIS-8 atomic 1-set 7th application + memory excluded、 nh 2 + lr 3 全反映 = NH1 = 4 件 mandatory co-mentions 固定 boilerplate (= β-7-1 反映) + NH2 = dashboard row status 具体化 (= dashboard 修正で反映) + LR1 = candidate file line count 実 read verify (= β-7-2 反映 = 32/84/23 行 confirmed) + LR2 = 改訂履歴 append only mandate (= 本 entry literal record) + LR3 = dashboard row status concrete wording (= dashboard 修正で final wording))、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed)。 ADR doc 修正範囲 = (1) §決定 2 β row 完了判定 column update (= 「halt (= pending、 ADR-0069 完走後 再開、 user option 3 採用)」 → 「halt 解消後 再起票完了 = ADR-0069 Accepted 後 41st session、 candidate 4 件評価 + 採否判定 record 完了、 詳細 Annex β-7 fill 参照」) + (2) Annex β に新規 sub-section β-7 fill (= β-7-1 再開条件成立 confirm + 同文脈併記 mandatory 4 件 boilerplate literal = NH1 反映 + β-7-2 audition material 候補 4 件 evaluation literal = 実 read verify line count 32/84/23 + part coverage + 演奏時間 + audition 適性 literal + β-7-3 採否判定 final list = candidate 1 補助採用 (= acoustic verify gate) + candidate 2 部分採用 (= A/B/C/I 部分 audition、 D/E/F/G/H/J 欠落明示) + candidate 3 採用 (= rhythm/ADPCM-A audition) + candidate 4 将来検討 defer (= user 明示 GO 必須 mandate) + β-7-4 「実 MML を聴いて aesthetic judgment」 前提成立条件 = candidate 2+3 部分達成 = 11 part coverage (= 65%)、 全 17 part full coverage = candidate 4 future + β-7-5 不可触対象 confirm + Codex layer 2 plan review chain literal + impl-review chain placeholder) + (3) 改訂履歴 β PR3 再起票 entry 追加 (= 本 entry、 append only mandate = LR2 反映 = 既存 entry 書き換えなし) + (4) 平易要約 β PR3 再起票 context section 追加 (= 6 構造 = やりたいこと / 前提 / やったこと / 結果 / 解釈 / 次)。 dashboard 修正範囲 = (5) 0065 行 status update 「Draft + α 完了 + retrospective approve + β halt (= ADR-0069 先行 dependency)」 → 「**Draft + α 完了 + retrospective approve + β PR3 再起票 in flight** (= γ PR4 起票時点 placeholder、 merge 後 final update timing 厳格化 = ADR-0069 γ PR4 precedent 同 pattern)」 (= NH2/LR3 反映 = placeholder 用途明示) + (6) escalation 履歴 β PR3 再起票 entry 1 row 新規追加 (= 既存 ADR-0069 γ PR4 entry 直前 = 最新位置、 plan chain literal record + impl-review chain placeholder)。 memory 修正 = (7) `project_pmdneo_adr_0065_initiated.md` 末尾 β PR3 再起票 update section 追加 + MEMORY.md index entry update (= 「Draft + α/β 完了 = audition material 選定 + 採否判定 record」 state 反映、 別途、 repo 外、 PR diff target 完全 excluded、 main agent direct Write/Edit、 merge 後実施)。 driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML (= PMDDotNET SAMPLE2.MML + step5 l-q-rhythm-song.mml = touch なし reference のみ) / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / **ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-6 本文 (= halt record literal、 immutable history) + Annex γ/δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section 完全 untouched** (= LR2 append only mandate 遵守 confirmed)、 `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= β PR3 doc-only sprint で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0067/0068 ε precedent 同 doc-only sprint 1 commit pattern 継承)。 ADR-0065 既存 §決定 5 rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ) = 完全 untouched carry。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` confirmed + (2) merge atomic 7 回目適用予定 (= PR #142 + #143 + #144 + #145 + #146 + #147 + 本 β PR3 再起票) + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed (= `wip-dashboard-coverage` + 退避 branch + 集約 branch 上 user 別作業 全完全 untouched)。 後続 = Codex layer 2 impl-review on β PR3 再起票 + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] **7 回目適用** + memory + dashboard maintenance final update + user 完走報告、 sub-sprint γ PR4 起票判断 = user 明示 GO 必須 (= acceptance gate criteria 定義 doc-only)、 sub-sprint δ PR5 起票判断 = user 介入 mandatory (= audition session 実施)、 sub-sprint ε PR6 起票判断 = user 明示 GO 必須 (= Draft → Accepted + Annex 全統合 + milestone wording 解禁)、 ADR-0066/0070 候補 起票判断 = 各 user 明示 GO 必須 (= ADR-0066 = ADR-0065 ε Accepted 後 future 順序固定 + ADR-0070 = ADR-0069 γ Accepted 後 dependency 解除済 但し独立 user GO 必須)。 | (= 本 β PR3 再起票 commit chain 内 commit 1) |
| 2026-05-26 | 41st session | ADR-0065 sub-sprint γ PR4 = acceptance gate criteria 定義 doc-only sprint (= β PR3 再起票完了 (= PR #148 MERGED at `cd715ae` + final maintenance `ec7f1ba`) 後の γ sub-sprint = δ audition session 実施前の acceptance gate criteria literal 文書化、 base anchor `wip-pmddotnet-opnb-extension@ec7f1ba`、 user 明示 GO「ADR-0065 γ PR4 起票が自然な次。 doc-only sprint = acceptance gate criteria 定義 = pairwise comparison / individual acceptance / 全 reject の 3 軸独立 schema 明記 + candidate 1/2/3 役割を判定基準に接続 + candidate 4 は γ scope に混ぜず future として扱う」 受領 + Codex layer 2 plan review 1 round chain approve plan v1 (= agentId `a9bb0fe9ee79343bc`、 task id `task-mpmhcnfz-8f6wk3`、 must-fix 0 + 全 8 軸 PASS = AXIS-1 scope coverage / AXIS-2 allowed-touch + 不可触 / AXIS-3 3 軸独立 schema validity / AXIS-4 candidate 1/2/3 role connection / AXIS-5 notation constraints / AXIS-6 §決定 5 rollback untouched carry / AXIS-7 branch 4-clause compliance / AXIS-8 atomic 1-set 8th application + memory excluded、 nh 1 + lr 2 全反映 = NH1 = dashboard placeholder wording を γ criteria-definition status 限定明記 + LR1 = dashboard final wording γ criteria-definition status のみ収まる executor 確認 + LR2 = memory direct Write/Edit after merge γ PR4 PR diff 混入 prevention、 越境操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 elapsed 約 1m 55s = doc-only plan review 経験則 8 分 threshold 内、 41st session user 明示新規律「Codex rescue 時必ず経過時間を見積もる + 経験則超えたらリトライ」 経路継承))。 ADR doc 修正範囲 = (1) §決定 2 γ row 完了判定 column update (= 「optional」 → 「γ PR4 起票完了 = acceptance gate criteria 定義 doc-only sprint 完走 + 3 軸独立 schema 明記 + candidate 1/2/3 役割接続、 詳細 Annex γ fill 参照」) + (2) Annex γ fill 5 sub-section literal = γ-1 scope literal + γ-2 3 軸独立 schema literal (= memory `feedback_relative_preference_vs_absolute_acceptance.md` + `feedback_preference_learning_beats_metric_correlation.md` + `feedback_metric_pass_is_not_aesthetic_pass.md` + `feedback_ai_engineering_gate_before_human_audition.md` 4 規律整合 = axis 1 pairwise comparison A_better_than_B/B_better_than_A/tie + axis 2 individual acceptance aesthetic_accept/revise_required/reject + axis 3 global reject all + 3 軸独立 mandatory) + γ-3 candidate 1/2/3 役割接続 literal table (= candidate 1 補助採用 acoustic verify gate 3 軸対象外 + candidate 2 部分採用 SAMPLE2.MML A/B/C/I 3 軸全対象 + candidate 3 採用 l-q-rhythm-song.mml K rhythm + L-Q ADPCM-A 3 軸全対象 + candidate 4 γ scope-out 17 part full active demo future) + γ-4 δ session 実施時の 3 軸入力 method literal (= step 1 audio render production-ready 経路 + step 2 越川氏 audition session + step 3 3 軸入力 越川氏 → main agent 起草 → user confirm process + step 4 結果 record Annex δ literal) + γ-5 candidate 4 γ scope-out 明示 (= future trigger condition global_reject_all 該当時、 user 明示 GO 必須) + 不可触対象 confirm + Codex layer 2 plan review chain literal + impl-review chain placeholder + (3) 改訂履歴 γ PR4 entry append (= 本 entry、 LR2 append only mandate 厳守 = 既存 β PR3 再起票 entry の後ろに append、 chronological order 正常維持) + (4) 平易要約 γ PR4 context section 追加 (= 6 構造 = やりたいこと / 前提 / やったこと / 結果 / 解釈 / 次)。 dashboard 修正範囲 = (5) 0065 行 status update placeholder (= merge 前 = 「Draft + α 完了 + retrospective approve + β PR3 再起票完了 + γ PR4 起票 in flight (= γ criteria-definition status only、 audition session 未実施、 δ acceptance + ε Accepted 後まで audition gate 達成等の wording 禁止維持)」 placeholder + merge 後 = 「Draft + α/β/γ 完了 = PR #NNN MERGED at `<hash>`」 final update timing 厳格化、 NH1/LR1 反映 = γ criteria-definition status 限定 wording) + (6) escalation 履歴 γ PR4 entry 1 row 新規追加 (= 既存 β PR3 再起票 entry 直前 = 最新位置、 plan chain literal record + impl-review chain placeholder)。 memory 修正 = (7) `project_pmdneo_adr_0065_initiated.md` 末尾 γ PR4 update section 追加 + MEMORY.md index entry update (= 「Draft + α/β/γ 完了」 state 反映、 LR2 反映 = 別途、 repo 外、 PR diff target 完全 excluded、 main agent direct Write/Edit、 merge 後実施)。 driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-7 本文 (= halt + 再起票 record literal、 immutable history) + Annex δ/ε placeholder + 改訂履歴 既存 entry (= LR2 append only mandate 厳守 confirmed) + 平易要約 既存 context section (= α/β halt + 再起票 context、 untouched) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= γ doc-only sprint で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0067/0068 ε precedent + ADR-0069 γ + ADR-0065 β PR3 再起票 precedent 同 doc-only sprint 1 commit pattern 継承)。 ADR-0065 既存 §決定 5 rollback condition (= 11 unique rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 = `git revert` のみ) = 完全 untouched carry。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` confirmed (= 本 PR base) + (2) merge atomic 8 回目適用予定 (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148 + 本 γ PR4) + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 impl-review on γ PR4 + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default (= 41st session user 明示新規律「経過時間見積もり + 経験則超えたらリトライ」 経路継承) + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] **8 回目適用** + memory + dashboard maintenance final update + user 完走報告、 sub-sprint δ PR5 起票判断 = user 介入 mandatory (= audition session 実施)、 sub-sprint ε PR6 起票判断 = user 明示 GO 必須 (= Draft → Accepted + Annex 全統合 + milestone wording 解禁)、 ADR-0066/0070 候補 起票判断 = 各 user 明示 GO 必須。 | (= 本 γ PR4 commit chain 内 commit 1) |
| 2026-05-26 | 41st session | ADR-0065 sub-sprint β revise + engineering gate sub-sprint (= δ session 試行 invalid 後の β PR3 採否 revise + §決定 13 audio render engineering gate 7 items 追加、 user 観測 root cause evidence record = candidate 2 「ものすごい低音持続」 + candidate 3 「無音 fadeout」 + 「説明不足で判断不能」、 main agent β PR3 採否誤り + engineering gate 不足 + memory `feedback_ai_engineering_gate_before_human_audition.md` 規律違反 = 順序固定違反 root cause、 越川氏 judgment 瑕疵なし明記、 base anchor `wip-pmddotnet-opnb-extension@c901213`、 user 明示 GO「option A = ADR-0065 内 β revise + engineering gate sub-sprint 追加。 δ PR5 起票なし。 Codex layer 2 plan review 必須 = engineering process 修正 sprint」 受領、 Codex layer 2 plan review 2 round chain approve plan v2 = round 1 (= agentId `a7fed7dcb9dedb574`、 task id `task-mpmijdqp-gjluh8`) revise MF 2 + nh 1 + lr 2 (= MF1 §決定 5 rollback condition untouched carry 明記不足 + MF2 branch operation 4-rule plan 内明示不足 + NH1 dashboard placeholder 文言具体化 + LR1 dashboard wording 確定 + LR2 ordering-fix restore literal ADR 本文反映) → plan v2 全反映 + round 2 (= agentId `adad46f3950ddec5e`、 task id `task-mpmio7ct-5dyjpm`) **approve** must-fix 0 + 全 9 軸 PASS、 elapsed 約 3m doc-only plan review 経験則 8 分 threshold 内)。 ADR doc 修正範囲 = (1) §決定 2 β row 完了判定 column update (= 末尾「+ β revise (= 採否 revise + engineering gate 追加) sub-sprint 完走 = δ session 試行 invalid を root cause evidence に candidate 2/3 不採用候補 revise + §決定 13 engineering gate 7 items 追加」 追記) + (2) **§決定 13 新規追加 = audio render engineering gate 7 items + δ 前提 gate pass 規律** literal (= 7 items = wav duration + RMS amplitude + silence check + FM keyon count + SSG tone write + ADPCM-A trigger count + expected audible content match + all 7 pass mandate + 1 件 fail で δ halt + material revise trigger + 順序固定 restore literal) + (3) Annex β-8 fill 6 sub-section literal = β-8-1 user 観測 root cause evidence + β-8-2 root cause analysis (= main agent β PR3 採否誤り + engineering gate 不足 + memory 規律違反 + 越川氏 judgment 瑕疵なし) + β-8-3 audition material 採否 revise table (= candidate 1 補助採用維持 + candidate 2/3 不採用候補 revise + candidate 4 将来検討 defer 維持) + β-8-4 engineering gate 7 items 定義 (= §決定 13 整合) + β-8-5 audio render 前 expected audio 説明 format literal + β-8-6 gate pass 後 δ 進行規律 + 順序固定 restore literal + 不可触対象 + Codex chain + (4) 改訂履歴 β revise entry append (= 本 entry、 LR2 append only mandate 厳守 = 既存 γ PR4 entry の後ろに append、 chronological order 正常維持) + (5) 平易要約 β revise context section 追加 (= 6 構造)。 dashboard 修正範囲 = (6) 0065 行 status update placeholder = 「Draft + α 完了 + retrospective approve + β PR3 再起票完了 + γ PR4 完了」 → 「**+ β revise in flight** (= engineering gate sub-sprint、 δ session invalid 後の β 採否 revise + engineering gate 7 items 追加、 audition session 未実施、 δ acceptance + ε Accepted 後まで audition gate 達成等の wording 禁止維持、 merge 後「+ β revise 完了 = PR #NNN MERGED at `<hash>`」 final update timing 厳格化)」 (= NH1/LR1 反映 = engineering gate sub-sprint status 限定 wording) + (7) escalation 履歴 β revise entry 1 row 新規追加 (= 既存 γ PR4 entry 直前 = 最新位置、 plan chain literal record + impl-review chain placeholder)。 memory 修正 = (8) `project_pmdneo_adr_0065_initiated.md` 末尾 β revise update section + MEMORY.md index entry update (= 「Draft + α 完了 + retrospective approve + β PR3 再起票完了 + γ PR4 完了 + β revise 完了」 state 反映、 LR2 反映 = 別途、 repo 外、 PR diff target 完全 excluded、 main agent direct Write/Edit、 merge 後実施)。 driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / **ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-7 本文 + Annex γ (= γ-1〜γ-5 final) + Annex δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section 完全 untouched** (= LR2 append only mandate 厳守 confirmed)、 `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` / audition/2026-05-26/session-1/ (= δ 試行 wav 2 件、 repo 外 artifact、 PR diff target excluded、 β-8-1 で literal reference) 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= β revise doc-only sprint で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0067/0068 ε + ADR-0069 γ + ADR-0065 β PR3 再起票 + γ PR4 precedent 同 doc-only sprint 1 commit pattern 継承)。 ADR-0065 既存 §決定 5 rollback condition = 完全 untouched carry literal (= 11 unique rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 = `git revert` のみ、 §決定 5 行 0 byte change confirm mandatory)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` confirmed (= 本 PR base) + (2) merge atomic 9 回目適用予定 (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148 + #149 + 本 β revise) + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 impl-review on β revise + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] **9 回目適用** + memory + dashboard maintenance final update + user 完走報告、 sub-sprint = β revise 完走後 audition material 再選定 sprint or candidate 別 MML 探索 sub-sprint (= engineering gate 7 items pass mandate)、 sub-sprint δ PR5 起票判断 = engineering gate pass 後 + user 介入 mandatory (= audition session 実施)、 sub-sprint ε PR6 起票判断 = user 明示 GO 必須、 ADR-0066/0070 候補 起票判断 = 各 user 明示 GO 必須。 | (= 本 β revise commit chain 内 commit 1) |

## 平易要約

### ADR-0065 でやりたいこと

(d) 越川氏 audition gate = production-ready 経路 audition session approve を別 ADR sprint として起票する。 ADR-0068 ε で「(d) audition gate 未実装 = ADR-0065 候補 future」 と書いた残課題を消化する。 越川氏 (= user 本人) が production-ready 経路 (= v2 driver) の audio render を実聴して aesthetic accept / revise required / 全 reject を判定する人間 audition gate。

### ADR-0065 前提

- ADR-0058 + ADR-0059 完成済 (= production-ready 経路 = v2 driver 経路 動作前提)
- ADR-0067 ε Accepted (= 16 ch fixture 拡張完了)
- ADR-0068 ε Accepted + retrospective fix 完走 (= roadmap ⑤ 統合 verify 完了)
- ADR-0064 §決定 7 番号予約 = ADR-0065 = roadmap ⑥ audition
- production sha256 = `b15883fe...` 維持 (= ADR-0065 で driver 不変)
- user 明示 GO「ADR-0065 が自然な次」 受領 (= 40th session ADR-0068 retrospective fix 完走後)

### ADR-0065 でやること

- ADR-0065 file 新規作成 (= 12 決定 + Annex skeleton A/B/α/β/γ/δ/ε + 改訂履歴 + 平易要約)
- dashboard 0065 行 update + escalation 履歴 entry 追加
- memory 起票 entry 新規 + MEMORY.md index 追加 (= repo 外、 PR diff 対象外)
- sub-sprint α/β/γ/δ/ε 5 段 plan literal 確定 (= δ で user 介入 mandatory)
- production sha256 維持 + driver 不変方針

### ADR-0065 起票後の結果

- ADR-0065 = Draft 起票完了
- dashboard 0065 行 = 「Draft 起票」
- sub-sprint chain plan literal record
- ADR-0066/0069 候補 起票判断 dependency literal (= ADR-0066 順序固定 + ADR-0069 parallel 可 + sha256 維持運用順序 4 選択肢)

### ADR-0065 ε Accepted 後の解釈 (= future、 δ acceptance accept 経路前提)

- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 wording 解禁 + 併記必須 (= production-ready 全体達成ではない 等 4 件)
- ε Accepted ≠ production-ready 全体達成 (= ADR-0066 本番 cmd 切替後 future)
- δ acceptance reject 経路では「(d) audition gate 達成」 解禁不可、 別軸 redesign or 別 ADR 起票判断

### 次

- ADR-0065 PR1 commit chain (= 本 commit、 単一 commit)
- push + PR 起票
- Codex layer 2 impl-review on PR1 + approve loop
- main agent 経路 merge
- 続行 = sub-sprint α PR2 起票判断 (= user 明示 GO 必須、 ADR-0065 ε まで完走後 ADR-0066 起票判断 + ADR-0069 parallel 起票判断 user 明示 GO)

## α PR2 平易要約 (= audition session 準備 doc-only sprint)

### α でやりたいこと

ADR-0065 §決定 2 α row literal「audition session 準備 doc-only = production binary build 確認 + emulator (MAME) 環境確認 + audition record format 定義」 を実装する。 越川氏 audition session を実施するための前準備として「どう build するか」 「どう emulator で audio render するか」 「どう record するか」 を ADR-0065 Annex α に literal 確定する。 driver / verify / vendor は touch しない doc-only sprint。

### α 前提

- ADR-0065 = Draft 起票完了 (= PR #140 MERGED at `c3ed5e0`)
- ADR-0058 + ADR-0059 = production-ready 経路 (= v2 driver 経路) 完成済
- ADR-0067 = 16 ch fixture 拡張完了 + ADR-0068 = 16 ch 統合 verify 完了 (= engineering verify base)
- 既存 build script (= `scripts/build-poc.sh`) + 既存 MAME script (= `scripts/run-mame.sh`) 不変前提
- memory `project_mame_headless_recording_mode.md` MAME headless 録音 mode 既確立 base
- production sha256 = `b15883fe...` 維持 mandatory (= ADR-0065 §決定 10 整合)
- user 明示 α scope 6 項目受領 (= 40th session ADR-0065 PR1 完走後 AskUserQuestion option 1)
- Codex companion 安全性分類器一時障害 2 回連続失敗 = ADR-0041 §決定 4-3 fallback regime 適用 (= ADR-0068 ε で実証済 pattern)

### α でやったこと

- ADR-0065 plan v1 起草 (= 6 sub-section α-1 build / α-2 emulator / α-3 audio render 前提 / α-4 record format / α-5 judgment 記録形式 / α-6 不可触対象)
- Codex layer 2 plan review 投入試行 = Codex companion 一時障害で 2 回連続失敗 = user escalation 該当
- user 明示 option B 採用 = ADR-0041 §決定 4-3 fallback + retrospective Codex review 必須 適用
- 主軸 fallback review approve plan v1 (= 6 axis 全 OK = scope literal coverage / α-1 build / α-2 emulator / α-3+α-4 render+format / α-5 judgment / α-6 不可触対象+commit chain、 must-fix 0 + nice-to-have 0 + latent risk 1 = MAME version literal specificity (= α では abstract OK + δ で具体 version 確定 natural))
- α branch `wip-adr-0065-alpha-impl` (= base `c3ed5e0`) 作成
- commit 1 (= 本 commit) = ADR-0065 修正 = §決定 2 α row update + Annex α fill 6 sub-section + 改訂履歴 α entry + 平易要約 α context section + dashboard 0065 行 status column update + dashboard escalation 履歴 α PR2 entry 1 row 追加 + `.gitignore` `audition/` excluded entry 追加 (= nice-to-have 反映)
- memory `project_pmdneo_adr_0065_initiated.md` α 完走 entry 追加 (= 別途、 repo 外、 PR diff 対象外、 主軸直接 Write/Edit)

### α 結果

- ADR-0065 = Draft + α 完了 milestone (= main agent 経路 merge 後確定)
- Annex α fill = 6 sub-section literal record (= build + emulator + audio render 前提 + audition record format + judgment 記録形式 + 不可触対象)
- `.gitignore` `audition/` directory excluded (= wav repo 外 artifact 配置 path 安全化)
- production sha256 = `b15883fe...` 維持期待 (= α で再 build しない、 §決定 10 整合)
- driver / verify / vendor / fixture / build flag / 既存 Annex 完全不変 confirm

### α 解釈

- α PR2 = audition session 準備 doc-only = β material 選定 + γ acceptance gate criteria 確定の前段階
- α 完了 = audition session を実施するための環境 + format が確定した状態
- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 wording は依然 literal 禁止維持 (= ε Accepted 後解禁候補 = δ acceptance accept 前提)
- ADR-0065 ε Accepted (= 全 sub-sprint 完走後 = future) も literal future
- ADR-0041 §決定 4-3 fallback regime 2 回目適用 (= ε PR6 で full cycle 完走実証 + 本 α PR2 で 2 回目実証、 pattern 安定化)

### α 完走後の次

- α PR2 commit + push + PR 起票
- retrospective Codex review (= Codex 復旧後、 主軸 fallback judgment 事後 confirm + latent risk 1 件再 review)
- main agent 経路 merge
- 続行 = sub-sprint β PR3 起票判断 (= user 明示 GO 必須、 audition material 選定 doc-only = ADR-0067 fixture vs PMDDotNET 既存 MML vs 新規 MML trade-off)、 ADR-0066/0069 候補 起票判断 = 各 user 明示 GO 必須

## β PR3 halt 平易要約 (= 2026-05-25 40th session、 user option 3 採用 = ADR-0069 先行起票 + ADR-0065 β/δ はその後)

### β PR3 でやりたかったこと

audition material 選定 doc-only sprint = 3 候補 source (= ADR-0067 fixture / PMDDotNET 既存 MML / 新規 MML) の trade-off + 採用 material literal record。

### β PR3 で発覚した driver capability 制約

Codex plan review 2 round で発覚 = ADR-0068 §決定 1 の driver ground truth literal:
- (A) production default では candidate MML 関与なし (= 全 part driver 内蔵 default)
- (C-2) PMDDOTNET_MML 経路でも MML 関与は K + L-Q (= 7 part) のみ、 A-J (= FM 6 + SSG 3 + ADPCM-B) は全 build mode で default 固定 (= driver line 1741-1804 `load_song_part_addr` 固定)

= PMDDotNET MML の主旋律 (= A/B/C/I FM+SSG melody) は現 driver で audition audio に出ない、 「実 MML を聴いて aesthetic judgment」 前提が不成立。

### user 採用 option (= 4 option 提示後 option 3)

option 3 = **ADR-0069 (= driver 拡張 = A-J candidate distinctness) 先行起票 + ADR-0065 β/δ はその後 dependency 順序固定**。

理由: 現 driver では PMDDotNET MML の A-J が audition 音に反映されず、 ADR-0065 β の material 選定をこのまま進めても「実 MML を聴いて aesthetic judgment」 前提が成立しない。 ADR-0065 側を緩めるより、 ADR-0069 で A-J candidate distinctness / MML 全 part audition 可能化を先に解く方が roadmap ⑥ audition の意味が保てる (= user message literal)。

### β PR3 halt record でやったこと

- ADR-0065 §決定 2 β row 完了判定 column update (= 「halt (= pending、 ADR-0069 完走後 再開、 user option 3 採用)」)
- ADR-0065 §決定 9 ADR-0069 dependency update (= 元「parallel 起票可」 → 「ADR-0069 → ADR-0065 β/δ 順序固定」)
- ADR-0065 Annex β fill (= placeholder → 6 sub-section halt record literal)
- ADR-0065 改訂履歴 halt entry 追加
- ADR-0065 平易要約 β halt context section (= 本 section) 追加
- dashboard 0065 行 status column update + escalation 履歴 halt entry 追加
- driver / verify / vendor / fixture / build flag / ADR-0041〜0068 本文 + Annex 完全不変 = doc-only sprint

### β PR3 halt 後の次

- halt record commit + push + PR 起票
- Codex layer 2 impl-review on halt record + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律
- memory update + 完走報告
- **ADR-0069 起票判断へ移行** (= allowed-touch + production sha256 維持方針 + rollback 条件 明確化 先行、 user 明示確認 mandatory)
- ADR-0065 β/δ 再開 = ADR-0069 完走後 future (= 本 halt から再開時 plan v3 新規 draft + Codex plan review chain)

### β PR3 再起票 (= 41st session 2026-05-26、 halt 解消後 再開) でやりたいこと

ADR-0069 Accepted (= 2026-05-26 41st session、 PR #147 MERGED at `0cde9f6`) = 軸 B v2 driver A-J candidate distinctness 拡張完成で β/δ 再開条件成立。 audition material 選定 doc-only sprint で candidate 4 件評価 + 採否判定 record + 「実 MML を聴いて aesthetic judgment」 前提成立条件確立。 K bitmap pair distinct は ADR-0070 future として β scope に混ぜない。

### β PR3 再起票 前提

- ADR-0069 Accepted (= driver capability 制約 解除済、 「A-J candidate distinctness 達成」 wording 解禁 (= 解禁時 同文脈併記 mandatory 4 件 = 「K bitmap pair distinct 未達成 = ADR-0070 candidate future」 + 「16ch full candidate distinctness 完了 ではない」 + 「ADR-0065 β/δ 再開 ready」 + 「production-ready 全体達成 ではない」))
- user 明示 GO「ADR-0065 β PR3 再起票が自然な次。 scope = audition material 選定 doc-only。 K bitmap pair distinct は ADR-0070 future として β scope に混ぜない。 必要なら新規 audition material MML 候補」 受領
- branch 運用 4 条規律 literal 明示固定 (= AGENTS.md + Codex memory + main agent memory 全同期記録)
- 主軸並走 3 sub-agent investigation 完了 (= Agent A = aj-distinctness-fixture audition 適性 / Agent B = PMDDotNET 既存 MML 候補 / Agent C = rhythm/ADPCM-A material + 新規 material 必要性)
- Codex layer 2 plan review 1 round chain approve plan v1 (= agentId `a1eeb29251ac69e48`、 must-fix 0 + 全 8 軸 PASS + nh 2 + lr 3 全反映)

### β PR3 再起票 でやったこと

- ADR-0065 doc 修正 = §決定 2 β row update (= halt → 再起票完了) + Annex β-7 fill 5 sub-section (= β-7-1 再開条件成立 + 4 件 mandatory co-mentions boilerplate + β-7-2 candidate 4 件 evaluation (= 実 read verify line count 32/84/23 行) + β-7-3 採否判定 final list + β-7-4 partial coverage 明示 + β-7-5 不可触対象 + Codex plan review chain literal + impl-review placeholder) + 改訂履歴 β PR3 再起票 entry append + 平易要約 β PR3 再起票 context section 追加 (= 本 section)
- dashboard 修正 = 0065 行 status update + escalation 履歴 β PR3 再起票 entry 1 row 新規追加
- memory update = `project_pmdneo_adr_0065_initiated.md` 末尾 β PR3 再起票 update section + MEMORY.md index entry update (= 別途、 repo 外、 PR diff target 完全 excluded、 main agent direct Write/Edit、 merge 後実施)
- 不可触対象 完全 untouched confirm = driver / 既存 verify script / 新規 fixture MML (= ADR-0069 `aj-distinctness-fixture.mml`) / 既存 fixture MML (= PMDDotNET SAMPLE2.MML + step5 l-q-rhythm-song.mml) / vendor / 既存 build flag / ADR-0048 軸 G ε partial state / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α 本文 + Annex β-1〜β-6 本文 + Annex γ/δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = 全完全 untouched

### β PR3 再起票 結果

- ADR-0065 = **Draft + α 完了 + retrospective approve + β PR3 再起票完了**
- audition material 採否判定 final = candidate 1 補助採用 + candidate 2 部分採用 + candidate 3 採用 + candidate 4 将来検討 defer
- 「実 MML を聴いて aesthetic judgment」 前提 = candidate 2+3 で部分達成 = 11 part coverage (= 65%)、 candidate 4 future = full coverage 17 part
- production sha256 = `b15883fe...` 維持期待 (= β PR3 doc-only sprint で build しない、 carry)
- atomic 1 セット規律 7 回目適用予定 (= merge 後)

### β PR3 再起票 解釈

- ADR-0069 γ Accepted で「A-J candidate distinctness 達成」 wording 解禁条件成立 = PMDDotNET MML の A-J part audition 可能化が driver layer で確立
- ただし MML 内 part coverage は MML 内容に依存 = SAMPLE2.MML は A/B/C/I のみ active = 残 D/E/F/G/H/J 6 part は β PR3 採用 material では audition 対象外
- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 wording = β PR3 時点では **依然禁止** (= ADR-0065 δ acceptance + ε Accepted 後解禁候補)
- 「16ch full candidate distinctness 完了」 wording = β PR3 時点も **永久禁止** (= ADR-0070 完走条件、 K 拡張要件)
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = 永久禁止維持

### β PR3 再起票 後の次

- β PR3 再起票 commit + push + PR 起票
- Codex layer 2 impl-review on β PR3 再起票 + approve loop + Monitor 30s polling 死活管理 + 機械復旧 rule literal 適用 default
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 **7 回目適用** (= PR #142 + #143 + #144 + #145 + #146 + #147 + 本 β PR3 再起票)
- memory + dashboard maintenance final update + user 完走報告
- 続行候補 = sub-sprint γ PR4 起票判断 = user 明示 GO 必須 (= acceptance gate criteria 定義 doc-only) / sub-sprint δ PR5 起票判断 = user 介入 mandatory (= audition session 実施) / sub-sprint ε PR6 起票判断 = user 明示 GO 必須 (= Draft → Accepted + Annex 全統合 + milestone wording 解禁)、 ADR-0066/0070 候補 起票判断 = 各 user 明示 GO 必須

### γ PR4 (= 41st session 2026-05-26、 acceptance gate criteria 定義 doc-only sprint) でやりたいこと

ADR-0065 sub-sprint chain α/β/γ/δ/ε 5 段 の γ 段 = doc-only sprint = δ audition session 実施前の越川氏 audition judgment を受領 + 判定する schema を literal 文書化。 pairwise comparison + individual acceptance + 全 reject の 3 軸独立 schema 明記 + β PR3 で決まった candidate 1/2/3 の役割を schema 接続 + candidate 4 は γ scope-out (= future、 別 sprint or 別 ADR scope) として扱う。 driver / verify / fixture / vendor 完全不変。

### γ PR4 前提

- ADR-0069 Accepted (= PR #147 MERGED at `0cde9f6`) で driver capability 拡張完了
- ADR-0065 β PR3 再起票完了 (= PR #148 MERGED at `cd715ae`) で audition material 採否判定 final 完了 (= candidate 1 補助採用 / candidate 2 部分採用 / candidate 3 採用 / candidate 4 将来検討 defer)
- user 明示 GO「ADR-0065 γ PR4 起票が自然な次。 doc-only sprint = acceptance gate criteria 定義 = 3 軸独立 schema 明記 + candidate 1/2/3 役割を判定基準に接続 + candidate 4 は γ scope に混ぜず future として扱う」 受領
- branch 運用 4 条規律 literal 明示固定済
- 41st session 確立規律 = passive 待機禁止 + polling 死活管理 + 経験則 retry default

### γ PR4 でやったこと

- ADR-0065 doc 修正 = §決定 2 γ row 完了判定 column update + Annex γ fill 5 sub-section (= γ-1 scope + γ-2 3 軸独立 schema literal = memory 4 規律遵守 base + γ-3 candidate 1/2/3 役割接続 literal table + γ-4 δ session 実施時の 3 軸入力 method literal + γ-5 candidate 4 γ scope-out 明示 + 不可触対象 + Codex chain) + 改訂履歴 γ PR4 entry append (= LR2 append only mandate 厳守) + 平易要約 γ PR4 context section 追加 (= 本 section)
- dashboard 修正 = 0065 行 status placeholder update (= 「+ γ PR4 起票 in flight (= γ criteria-definition status only)」 placeholder = merge 後 final update) + escalation 履歴 γ PR4 entry 1 row 新規追加 (= plan chain literal record + impl-review chain placeholder)
- memory update = `project_pmdneo_adr_0065_initiated.md` 末尾 γ PR4 update section + MEMORY.md index entry update (= 別途、 repo 外、 PR diff target 完全 excluded、 main agent direct Write/Edit、 merge 後実施)
- 不可触対象 完全 untouched confirm = driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α + Annex β-1〜β-7 本文 (= immutable history) + Annex δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` = 全完全 untouched

### γ 完走後の結果

- ADR-0065 = **Draft + α 完了 + retrospective approve + β PR3 再起票完了 + γ PR4 完了**
- acceptance gate criteria 定義 final = 3 軸独立 schema (= pairwise comparison + individual acceptance + 全 reject) + candidate 1/2/3 役割接続 + candidate 4 γ scope-out
- δ session 実施前提 = audio render method + 越川氏 audition session method + 3 軸入力 method literal 確立
- production sha256 = `b15883fe...` 維持期待 (= γ doc-only sprint で build しない、 carry)
- atomic 1 セット規律 8 回目適用予定 (= merge 後)

### γ 完走後の解釈

- γ PR4 完了で δ session 実施前提が literal 確立 = audition input schema + judgment 基準 + record format 全て決まった状態
- 次 δ PR5 (= user 介入 mandatory) で越川氏 audition session 実施 + 3 軸入力 + Annex δ literal record
- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 wording = γ PR4 時点では **依然禁止** (= δ acceptance + ε Accepted 後解禁候補)
- 「16ch full candidate distinctness 完了」 wording = γ PR4 時点も **永久禁止** (= ADR-0070 完走条件、 K 拡張要件)
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = 永久禁止維持

### γ PR4 後の次

- γ PR4 commit + push + PR 起票
- Codex layer 2 impl-review on γ PR4 + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 **8 回目適用** (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148 + 本 γ PR4)
- memory + dashboard maintenance final update + user 完走報告
- 続行候補 = sub-sprint δ PR5 起票判断 = user 介入 mandatory (= audition session 実施)、 sub-sprint ε PR6 起票判断 = user 明示 GO 必須 (= Draft → Accepted + Annex 全統合 + milestone wording 解禁)、 ADR-0066/0070 候補 起票判断 = 各 user 明示 GO 必須

### β revise + engineering gate sub-sprint (= 41st session 2026-05-26、 δ session 試行 invalid 後の β 採否 revise + engineering gate 7 items 追加) でやりたいこと

main agent β PR3 採否判定誤り + engineering gate 不足 + memory `feedback_ai_engineering_gate_before_human_audition.md` 規律違反 root cause を解消する sub-sprint。 candidate 2/3 不採用候補 revise + §決定 13 engineering gate 7 items 追加 + Annex β-8 fill 6 sub-section + 順序固定 restore literal。 越川氏 judgment 瑕疵なし明記。

### β revise + engineering gate sub-sprint 前提

- δ session 試行 (= main agent audio render + user 越川氏 観測) = invalid / judgment not possible
- user 観測 = candidate 2 「ものすごい低音持続」 + candidate 3 「無音 fadeout」 + 「何のテストか説明不足で判断不能」
- user 明示 GO 「option A = ADR-0065 内 β revise + engineering gate sub-sprint 追加。 δ PR5 起票なし。 Codex layer 2 plan review 必須 = engineering process 修正 sprint」 受領
- Codex layer 2 plan review 2 round chain approve plan v2 (= round 1 revise MF 2 + nh 1 + lr 2 → plan v2 全反映 → round 2 approve)

### β revise + engineering gate sub-sprint でやったこと

- ADR-0065 doc 修正 = §決定 2 β row update (= 末尾「+ β revise (= 採否 revise + engineering gate 追加) sub-sprint 完走」 追記) + 新 §決定 13 追加 (= audio render engineering gate 7 items + δ 前提 gate pass 規律) + Annex β-8 fill 6 sub-section (= β-8-1 root cause evidence + β-8-2 root cause analysis + β-8-3 採否 revise table + β-8-4 engineering gate 7 items + β-8-5 expected audio 説明 format + β-8-6 順序固定 restore + 不可触 + Codex chain) + 改訂履歴 β revise entry append (= LR2 append only mandate 厳守) + 平易要約 β revise context section 追加 (= 本 section)
- dashboard 修正 = 0065 行 status placeholder update + escalation 履歴 β revise entry 1 row 追加
- memory update = `project_pmdneo_adr_0065_initiated.md` 末尾 β revise update section + MEMORY.md index entry update (= 別途、 repo 外、 PR diff target excluded、 main agent direct Write/Edit、 merge 後実施)
- 不可触対象 完全 untouched confirm = driver / 既存 verify script / 新規 fixture MML / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state / ADR-0026 §決定 3/4 / ADR-0041〜0064 / ADR-0066-0069 本文 + Annex / ADR-0065 既存 §決定 1 + 3-12 本文 + Annex A/B/α + Annex β-1〜β-7 本文 + Annex γ + Annex δ/ε placeholder + 改訂履歴 既存 entry + 平易要約 既存 context section / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5` / audition/2026-05-26/session-1/ (= δ 試行 wav 2 件 repo 外 artifact) = 全完全 untouched

### β revise 完走後の結果

- ADR-0065 = **Draft + α 完了 + retrospective approve + β PR3 再起票完了 + γ PR4 完了 + β revise 完了**
- audition material 採否 final = candidate 1 補助採用維持 + candidate 2/3 不採用候補 revise + candidate 4 将来検討 defer 維持
- engineering gate 7 items 定義 final = wav duration + RMS + silence + FM keyon + SSG tone + ADPCM-A trigger + expected audible content (= §決定 13)
- δ 進行 prerequisite = all 7 gate items pass mandate、 1 件 fail で δ halt + material revise trigger
- memory `feedback_ai_engineering_gate_before_human_audition.md` 規律違反 root cause + 本 β revise で engineering gate 確立 → AI engineering 検査 → human aesthetic audition 順序固定 restore confirmed
- 越川氏 judgment 瑕疵なし明記
- production sha256 = `b15883fe...` 維持期待 (= β revise doc-only sprint で build しない、 carry)
- atomic 1 セット規律 9 回目適用予定 (= merge 後)

### β revise 完走後の解釈

- audition material 採否 revise = candidate 2/3 = 「現状の render では aesthetic judgment 不成立」 不採用候補 → β 再々起票 sprint or candidate 別 MML 探索 or 新規 audition material 起票 = Claude Code 主担当 (= engineering 範囲、 user 介入は最終 aesthetic judgment のみ)
- engineering gate 7 items pass mandate = δ 進行 prerequisite = Claude Code 自律 engineering 検査 + pass 後にのみ δ 進行
- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 wording = β revise 時点では **依然禁止** (= δ acceptance + ε Accepted 後解禁候補)
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = 永久禁止維持
- 「16ch full candidate distinctness 完了」 = 永久禁止 (= ADR-0070 future)

### β revise 完走後の次

- β revise sub-sprint commit + push + PR 起票
- Codex layer 2 impl-review on β revise + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 **9 回目適用** (= PR #142 + #143 + #144 + #145 + #146 + #147 + #148 + #149 + 本 β revise)
- memory + dashboard maintenance final update + user 完走報告
- 続行 = **Claude Code 自律 = audition material 再選定 sub-sprint (= candidate 2/3 替わる新 candidate or 既存 candidate の render method 修正 or 新規 audition material MML 起票) + engineering gate 7 items 機械検査 implementation (= verify script 新規 or 既存 verify script 拡張) + render 機械検査 pass 確認**、 その後 = δ PR5 起票 (= user 介入 mandatory = 「この音 accept できるか」 aesthetic judgment のみ)
