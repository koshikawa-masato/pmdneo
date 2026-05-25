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
| β | audition material 選定 doc-only = ADR-0067 fixture vs PMDDotNET 既存 MML vs 新規 MML trade-off + 選定 literal | optional | material 選定 literal + 採用根拠 record | ADR-0067 ε 既存 fixture + ADR-0068 16 ch integration trace 既存 |
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
| PR3 | sub-sprint β = audition material 選定 doc-only | doc-only | optional |
| PR4 | sub-sprint γ = acceptance gate criteria 定義 doc-only | doc-only | optional |
| PR5 | sub-sprint δ = **audition session 実施 + record + finding + acceptance decision** | doc + text record (= markdown + JSONL) + audio file (= wav、 **repo 外 artifact 配置 = gitignore + 別 storage**、 nice-to-have 反映) | **mandatory** |
| PR6 | sub-sprint ε = Draft → Accepted + Annex 全統合 + milestone wording 解禁 | doc-only | optional |

### 決定 9: ADR-0066/0069 候補 起票判断 dependency literal

- **ADR-0066 候補** = roadmap ⑦ 本番 cmd 切替判断 ADR (= ADR-0065 Accepted 後 future、 **順序固定 dependency**、 全 4 gate (= (a)(b)(c) ADR-0068 + (d) ADR-0065) 達成後 user 明示 GO 必須)
- **ADR-0069 候補** = driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct (= ADR-0068 残課題、 ADR-0065 と independent、 **parallel 起票可**)
- 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)

#### ADR-0069 parallel 起票時の sha256 維持運用順序 (= latent risk 1 反映、 Codex finding literal)

ADR-0069 = driver 拡張 (= A-J candidate distinctness + K bitmap pair distinct) は driver source 変更が必須 = production sha256 衝突 risk。 ADR-0065 sub-sprint 進行中 (= δ audition session 実施前後) で ADR-0069 driver 拡張 commit を同時実施すると次 risk:

| risk | content |
|---|---|
| sha256 衝突 | ADR-0065 production binary (= 越川氏 audition 対象) と ADR-0069 driver 拡張後 binary の sha256 不一致 |
| audition 結果整合性 | ADR-0065 δ で audition した binary と ADR-0069 完走後 binary が異なる場合、 audition decision の意味曖昧化 |

運用順序選択肢 (= **user 明示 GO 必須**、 main agent autonomous で進めない):
1. ADR-0065 ε Accepted 後に ADR-0069 起票 (= sha256 carry literal 固定)
2. ADR-0069 完走後に ADR-0065 δ audition session 実施 (= 拡張後 binary で audition)
3. ADR-0065 δ 前に ADR-0069 完走 (= 同 2 と同じ、 user 明示 GO 順序)
4. ADR-0065 ε Accepted + ADR-0069 別 ADR-0065 拡張 entry (= 拡張後 binary で再 audition session 必要、 別 sprint)

= user 明示 GO 必須 (= ADR-0066/0069 候補 起票判断と同)、 ADR-0065 と ADR-0069 の並行進行は user 判断軸。

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

### Annex β: sub-sprint β audition material 選定 doc-only (= β PR3 で fill)

placeholder。

### Annex γ: sub-sprint γ acceptance gate criteria 定義 doc-only (= γ PR4 で fill)

placeholder。

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
