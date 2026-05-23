# ADR-0061: PMDNEO ADR-0048 ζ-ε 完走後 残課題 3 系統 plan 整理 (= 軸 G dynamic supply 完成 milestone 後の (1) stash 退避分整理 / (2) production-ready 全体判定 / (3) 本番 cmd 切替判断 独立 sprint 構成、 doc-only filing)

- 状態: **Accepted** (= 2026-05-24 39th session、 単一 doc-only PR で起票 + Accepted = ADR-0056 / ADR-0060 同形式、 Codex layer 2 plan review 4 round chain approve = must-fix 全反映、 user 明示 option 3 GO + 推奨順「stash 退避分整理 → production-ready gate status 確認 → 本番 cmd 切替判断」 確定経由)
- 起票日: 2026-05-24
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0048** (= 軸 G dynamic supply 完成 milestone、 ζ-ε で Draft → Accepted 移行完了、 本 ADR の母 ADR)
  - **ADR-0056** (= production-ready 選定 ADR、 §決定 3 4 系統 gate (= 実 MML 再生 / 実音 register trace-equivalence / baseline regression / 越川氏 audition)、 §決定 1-a 実 MML 再生経路 ground truth literal = `cmd 0x05 + pmdneo_song_main`)
  - **ADR-0060** (= roadmap ④ 軸 G dynamic supply 依存整理、 doc-only design ADR、 ADR-0061 同形式)
  - **ADR-0045** (= 軸 B 設計 ADR、 §I-5-b future = 本番 cmd 切替 user 判断軸)
- 関連 memory:
  - `project_pmdneo_39th_session_zeta_epsilon_complete.md` (= 39th session ζ-ε 完走 milestone、 軸 G dynamic supply 完成 + 残課題 enumeration)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化規律、 本 ADR plan review 4 round chain で機能実証継続)
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 ADR-0061 = plan 整理 ADR + 実装 ADR ではない)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 5-10 分 hang 判定規律、 本 ADR plan review 全 round 5-10 分以内 return 達成)

## 背景 (= why now)

### ADR-0048 ζ-ε 完走 + 軸 G dynamic supply 完成 milestone

39th session 2026-05-24 で **ADR-0048 ζ-ε (= chain-pr-A 5 本目、 PR #122 MERGED at `4ff0f7f`)** が完走し、 ADR-0048 Draft → Accepted 移行 = **軸 G dynamic supply 完成 milestone** 達成。 ζ chain 6 sub-sprint (= ζ-α 起票 PR #109 / ζ-β 案 W 実装 PR #118 / ζ-γ verify script 体系化 PR #119 / ζ-δ-1 integration audition fixture PR #120 / ζ-δ-2 audition fixture revise + 越川氏 audition approve PR #121 / ζ-ε Draft → Accepted 移行 doc-only PR #122) 全完走、 越川氏 ζ-δ-2 audition approve `「userジャッジ、 5wavともOKでした」` 受領 + user 明示 ζ-ε GO「完走後判断、 Codex Rescue 自律」 経由。

### ADR-0061 起票時点の現在状態

**ADR-0061 起票時点 (= 2026-05-24 39th session ζ-ε 完走直後) の現在状態 = ADR-0048 Accepted (= 軸 G dynamic supply 完成、 ζ-ε で Draft → Accepted 移行完了)** + ADR-0049〜0060 全 Accepted + 軸 G ε partial state placement (= 0xFD32-0xFD38) は ADR-0048 Accepted 後の保持状態。

### 残課題 3 系統 整理必要

ADR-0048 ζ-ε 完了 section literal で enumeration された残課題 (= production-ready 全体達成 ≠ ζ-ε / 本番 cmd 切替 user 判断軸 / stash 退避分 5 件 user 判断軸 / 軸 B sprint chain 残り / 軸 G 別 sprint 候補 / scope-out 9 項目維持) のうち、 **(a) production-ready 全体判定** / **(b) 本番 cmd 切替** / **(c) stash 退避分 5 件** の 3 系統が integration 軸として残る。 各系統は性質が異なるため独立 sprint 化 + 着手順固定が必要。

### user 明示 option 3 GO + 推奨順確定

ζ-ε 完走報告後の user judgment literal:

> option 3 を推奨します。 ADR-0048 Accepted 直後で、 残課題が性質の違う 3 系統に分かれているためです。 いきなり stash 処理や production-ready 判定に入るより、 まず 1 PR の doc-only plan で依存関係と着手順を固定した方が安全です。
> 推奨順は stash 退避分整理 → production-ready gate status 確認 → 本番 cmd 切替判断 です。
> Issue 更新は方針が確定して plan PR が作られた時点で #110 に更新するのが適切。

= ADR-0061 起票 doc-only sprint GO + 推奨順「stash → production-ready → cmd 切替」 確定 + Issue 更新 timing = ADR-0061 PR merge 後 user 別途実施。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0061 を起票、 3 系統独立 sprint 構成 + 推奨順 + 依存関係 + scope-out literal を確定する。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。

## 決定

### 決定 1: 3 系統独立 sprint 構成

軸 G dynamic supply 完成 (= ADR-0048 Accepted) 後の残課題を **3 系統独立 sprint** として構成:

| sprint | 内容 | 関連 ADR | 性質 |
|---|---|---|---|
| **(1) stash 退避分整理 sprint** | stash list 5 件 (= FM voice round 2 + audition silent enforcement + verify update + .gitignore AGENTS.md add + main/develop 系遺産) 内容確認 + 重複判定 + 各 stash 毎 user 採否判断 | (= 別 ADR 候補) | user 判断軸 = 各 stash 毎独立 |
| **(2) production-ready 全体判定 sprint** | ADR-0056 §決定 3 4 gate status 確認 = (a) 実 MML 再生 / (b) 実音 register trace-equivalence / (c) baseline regression / (d) 越川氏 audition、 4 gate status (= 達成済 / 未達 / 未着手) enumeration + 未達 gate roadmap ⑤+ 起票判断 | ADR-0056 §決定 3 / roadmap ⑤+ 別 ADR 候補 | 確認軸 = status 確認 + 起票判断 |
| **(3) 本番 cmd 切替判断 sprint** | production-ready 全通過後の future、 `cmd 0x05 + pmdneo_song_main` 実 MML 再生経路 (= Phase 1 PoC base + 既存 production 経路) → v2 driver 経路 switch user 判断軸 | ADR-0045 §I-5-b future / ADR-0056 §決定 1-a literal 整合 | 判断軸 = user 明示 GO 必須 |

### 決定 2: 推奨着手順

user 明示 literal の推奨順を反映:

```
(1) stash 退避分整理  →  (2) production-ready 全体判定  →  (3) 本番 cmd 切替判断
```

| 関係 | 詳細 |
|---|---|
| (1) と (2) | **並走可** (= 性質独立、 (1) は user 判断軸 + (2) は確認軸) |
| (2) → (3) | **依存** (= (3) は (2) 完了後の future、 production-ready gate 全通過が前提) |
| (1) → (3) | **間接依存** (= (1) は (3) に直接影響しないが、 (1)(2)(3) の整理順として (1) 先行) |

### 決定 3: 各 sprint scope literal

#### (1) stash 退避分整理 sprint scope

- stash list 5 件 enumeration (= `git stash list` literal):
  - `stash@{0}` = `wip-adr-0048-zeta-delta-2-axis-g-audition-fixture-revise: uncommitted: fm voice round 2 + silent enforcement + verify update (= scope-out by user direction)`
  - `stash@{1}` = `wip-adr-0048-zeta-delta-2-axis-g-audition-fixture-revise: scope-out: .gitignore AGENTS.md add`
  - `stash@{2}` = `develop: Phase 8d (= NMI query版、 drum 全停止 bug 再発)`
  - `stash@{3}` = `develop: Phase 8c-2 (= LOOP stack visualize、 全 part 無音 bug)`
  - `stash@{4}` = `main: SubF-1.2 spike WIP (pre-rollback to SubF-1.1)`
- 各 stash 毎 4 種選択肢 user 判断軸 (= 実作業 ADR で実施):
  - **apply** (= 採用 = `git stash apply` + 別 branch / PR 化)
  - **drop** (= 破棄 = `git stash drop`)
  - **branch 化** (= `git stash branch <name>` で別 branch 保存後 stash drop)
  - **保留継続** (= 触らず保持)
- ADR-0061 plan ADR では **選択肢 enumeration のみ** = 各 stash 内容詳細 / 重複判定 / user 採否は実作業 ADR で実施

#### (2) production-ready 全体判定 sprint scope

- ADR-0056 §決定 3 4 gate status 確認 (= sprint target):
  - **(a) 実 MML 再生 gate** = `cmd 0x05 + pmdneo_song_main` 実 MML 再生経路の v2 driver 経路 trace-equivalence
  - **(b) 実音 register trace-equivalence gate** = FM/SSG/ADPCM-B/ADPCM-A 全 ch の v2 driver register write vs 既存 driver register write の literal equivalence
  - **(c) baseline regression gate** = 既存 verify script suite (= verify-axis-b-v2-*.sh / verify-axis-g-*.sh / verify-mute-semantics.sh / verify-fadeout-semantics.sh / verify-ssg-tone-enable.sh 等) 全 ALL PASS 維持
  - **(d) 越川氏 audition gate** = production-ready 経路 audition session approve
- 4 gate status enumeration (= 達成済 / 未達 / 未着手) literal report
- **ADR-0056 4 gates と roadmap ⑤+ は確認対象であり達成宣言ではない** (= sprint target = 4 gate status 確認、 未達 gate を roadmap ⑤+ として起票判断、 達成宣言 = production-ready 全体達成 literal は別 sprint の future)
- 未達 gate ごとに roadmap ⑤+ 起票判断 = 別 ADR / 別 sprint chain として進める

#### (3) 本番 cmd 切替判断 sprint scope

- **production-ready gate 全通過後の future** = (2) sprint 完了 + 4 gate 全達成 + ADR-0056 production-ready 全体達成 literal 解禁後
- 切替元 = **`cmd 0x05 + pmdneo_song_main` 実 MML 再生経路** (= Phase 1 PoC base + 既存 production 経路、 ADR-0056 §決定 1-a literal、 dashboard 軸 B 行 ground truth 補正 literal「実 MML 経路は cmd 0x02 ではなく cmd 0x05+pmdneo_song_main」 と整合)
- 切替先 = **v2 driver 経路** (= ADR-0052〜0055 v2 driver foundation + ADR-0057〜0059 roadmap ①〜③ 実装完了 path)
- 判断主体 = user 明示 GO 必須 (= ADR-0045 §I-5-b future literal、 main agent autonomous で進めない)
- ADR-0061 時点では着手しない (= (2) sprint 完了が前提、 doc-only plan ADR 範囲外)

### 決定 4: doc-only sprint 維持

ADR-0061 起票 doc-only sprint = driver / verify script / vendor / fixture / build flag **完全不変**。 ADR-0061 は plan 整理 ADR で実装 ADR ではない (= ADR-0056 / ADR-0060 同形式)。 後続 sprint (= (1)/(2)/(3)) は各別 ADR / 別 PR で進める。

### 決定 5: 不可触対象 literal

- **ADR-0048 Accepted + Annex 全** (= ζ-ε で Draft → Accepted 移行完了、 §sub-sprint ζ-α/β/γ/δ-1/δ-2/ε 完了 section literal 不変、 履歴改変 risk 回避)
- **ADR-0049〜0060 全 routine body + 本文** (= 全 Accepted、 sub-sprint section 本文不変)
- **既存 routine + cmd 0x05 path + `pmdneo_song_main` + irq_handler_body** (= driver active code 完全不変)
- **vendor/** (= vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain、 user 明示永続 scope-out)
- **stash 退避分 5 件 本体** (= ADR-0061 は内容確認 plan であり stash apply / drop / branch 化ではない、 user 判断 sprint で別途処理)

### 決定 6: 表記制約 5 件 + ground truth 整合補強

ADR-0048 ζ-ε §禁止表現リスト 5 件のうち 2 件解禁 (= ζ-ε Accepted 移行後) を継承 + 「本番 cmd 切替完了」 別 track 制約 literal 化:

| 表現 | ADR-0061 時点 | 解禁条件 |
|---|---|---|
| 「軸 G dynamic supply 完成」 (日本語版) | **使用可** | ζ-ε Accepted 後の表現として ADR-0048 Accepted の範囲で使用可 |
| `axis-G dynamic supply complete` (英語版) | **使用可** | 同上 (= 日英両版同時解禁) |
| 「軸 G 完成」 | **literal 禁止維持** | 「軸 G 完成」 = dynamic supply 単独実装より広い範囲 (= asset converter Phase 4 / WebApp UI 等)、 ζ-ε Accepted ≠ 軸 G 全体完成 |
| 「軸 B 完成」 | **literal 禁止維持** | v2 driver の production-ready 化 + 既存 cmd 0x05 + `pmdneo_song_main` 実 MML 再生経路 → v2 driver 経路 switch は ADR-0045 §I-5-b の future 判断、 軸 B は production-ready 化が残る |
| 「production-ready 全体達成」 | **literal 禁止維持** | ADR-0056 §決定 3 4 系統全通過 + 越川氏 audition approve + 本番 cmd 切替後の future、 (2) sprint で 4 gate status 確認は達成宣言ではない |
| **「本番 cmd 切替完了」** | **§禁止表現リスト枠ではなく別 track で user 判断する表現** | **(3) sprint で production-ready gate 全通過 + `cmd 0x05 + pmdneo_song_main` 実 MML 再生経路 → v2 driver 経路 switch + user 明示 GO 後にのみ使える表現、 ADR-0061 時点では不可** |

### 決定 7: 後続 sprint chain 独立性

ADR-0061 は **plan 整理 ADR** (= ADR-0056 / ADR-0060 同形式) で実装 ADR ではない。 後続 sprint chain は本 ADR と独立:

- **(1) stash 退避分整理** = 実作業 ADR (= 別 ADR 番号予約 + 別 PR) で進める、 ADR-0061 は選択肢 enumeration のみ
- **(2) production-ready 全体判定** = ADR-0056 §決定 3 4 gate status 確認 sprint = 別 ADR / 別 PR で起票
- **(3) 本番 cmd 切替判断** = (2) 完了後の future、 user 明示 GO 後の別 ADR / 別 PR

### 決定 8: Issue 更新 timing

user 明示 literal:

> Issue 更新は方針が確定して plan PR が作られた時点で #110 に更新するのが適切。

= ADR-0061 PR merge 後 user が #110 Issue update (= main agent 提案のみ、 update は user 別途実施)。

### 決定 9: production build byte-identical 維持 + 根拠 literal

ADR-0061 = doc-only sprint で driver / verify / vendor / fixture / build flag **完全不変** = production build sha256 = ζ-ε 同 sha256 維持 (= 通算 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 不変)。

**sha256 維持の根拠** = driver / verify / vendor / fixture / build flag 不変 (= doc-only sprint で driver build artifacts 変化なし)。

**実際の変更範囲**:

- **(a) repo 内** = `docs/adr/0061-pmdneo-zeta-epsilon-followup-3-axes-plan.md` 新規 + `docs/parallel-axes-dashboard.md` 限定 update (= ADR 番号予約簿 0061 行 1 件追加 + escalation 履歴 ADR-0061 entry 1 件追加)
- **(b) repo 外** = Claude Code Agent SDK auto memory dir (= `/Users/koshikawamasato/.claude/projects/-Users-koshikawamasato-Projects-pmdneo/memory/`) で memory file 新規 + MEMORY.md index 1 行追加 = **PR diff には現れない**、 commit 対象外

sha256 再計算は doc-only sprint で driver build 走らないため不可、 **diff 範囲 verify + flag 不変 verify を primary gate** とする。

### 決定 10: 変更範囲 limited verify

**ADR-0049〜0060 本文 + dashboard 既存 0049-0060 行 + 既存 escalation 履歴 entry 完全不変** = 履歴改変 risk 回避。

repo 内 PR diff = **2 file 限定差分** (= `docs/adr/0061-*.md` 新規 1 件 + `docs/parallel-axes-dashboard.md` 限定 update 1 件)。 repo 外 memory file (= 新規 + MEMORY.md index 1 行) = user 個人 file、 PR diff には現れない。

## verify gate (= doc-only sprint、 spec consistency check)

- ADR-0061 新規 file 起票 + ADR-0056 / ADR-0060 同形式 (= 単一 doc-only PR 起票 + Accepted)
- driver / verify script / vendor / fixture / build flag 完全不変
- m1 binary byte-identical 維持期待 (= 通算 sha256 `b15883fe...` 不変)
- ADR-0048 Accepted + Annex 全 + ADR-0049〜0060 routine body + 本文 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain
- repo 内 diff = 2 file 限定 (= `docs/adr/0061-*.md` 新規 + `docs/parallel-axes-dashboard.md` 限定 update)
- repo 外 memory file = PR diff に現れない、 commit 対象外

## Codex layer 2 plan review chain (= 4 round chain、 全 must-fix 反映)

| round | judgment | must-fix / nice-to-have / latent-risk | agentId |
|---|---|---|---|
| round 1 | revise | 1 must-fix (= 決定 6 「本番 cmd 切替完了」 別 track 明確化) + 3 nice-to-have (= 決定 3 track (2) 確認対象明示 + track (1) stash 4 選択肢列挙 + dashboard scope) + 3 latent-risk (= 0061 未予約 confirm + sha256 維持根拠 + ADR-0049-0060 本文不変 verify) | `a5152e7bf8fe0c62b` |
| round 2 | revise | 1 must-fix (= 決定 9 sha256 維持根拠 wording 矛盾 = repo 内/外分離不足) + 2 nice-to-have (= 決定 10 粒度揃え + memory path literal) + 1 latent-risk (= 0061 起票時点の現在状態 ADR-0048 Accepted 明示) | `a31a6b439d8f6f98f` |
| round 3 | revise | 1 must-fix (= 決定 3 (3) ground truth literal 訂正 = cmd 2 path → cmd 0x05 + pmdneo_song_main 実 MML 再生経路) + 0 nice-to-have + 0 latent-risk | `afe323d32b1ef2b2e` |
| round 4 | **approve** | 0 件 (= must-fix なし + nice-to-have なし + latent-risk なし) | `ab52c5ebbd96877bc` |

= 全 must-fix 反映済、 main agent autonomous で起票 + commit + PR + implementation review + merge 進行。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

### やりたいこと

ADR-0048 ζ-ε 完走 (= 軸 G dynamic supply 完成 milestone) 後の残課題 3 系統 (= stash 退避分 + production-ready 全体判定 + 本番 cmd 切替判断) を独立 sprint 構成 + 推奨着手順固定 + 依存関係明記して plan 整理 ADR として起票。

### 前提

- ADR-0048 ζ-ε Accepted 完了 (= 2026-05-24 PR #122 MERGED at `4ff0f7f`)
- 軸 G dynamic supply 完成 milestone (= 越川氏 audition approve + user 明示 ζ-ε GO 経由)
- user 明示 option 3 GO + 推奨順「stash → production-ready → cmd 切替」 + Issue 更新 timing 確定

### やったこと

- ADR-0061 起票 doc-only sprint (= 単一 doc-only PR、 ADR-0056 / ADR-0060 同形式)
- 3 系統独立 sprint 構成 + 推奨着手順 + 依存関係 literal 確定
- 各 sprint scope literal (= stash 4 選択肢 enumeration + ADR-0056 4 gate status 確認 + cmd 切替 user 判断軸)
- 表記制約 5 件 + 「本番 cmd 切替完了」 別 track 制約 literal
- doc-only sprint 維持 + 不可触対象 literal
- ground truth 整合補強 (= cmd 0x05 + `pmdneo_song_main` 実 MML 再生経路 ADR-0056 §決定 1-a literal)
- Codex layer 2 plan review 4 round chain approve (= 全 must-fix 反映)

### 結果

- 3 系統独立 sprint plan + 推奨順 + 依存関係 確定
- 後続 sprint chain は各別 ADR / 別 PR で進める方針 literal
- production build byte-identical 維持 (= 通算 sha256 `b15883fe...` 不変、 doc-only)
- ADR-0049〜0060 本文 + 既存 dashboard 0049-0060 行 完全不変

### 解釈

ADR-0061 = plan 整理 ADR (= 実装 ADR ではない、 ADR-0056 / ADR-0060 同形式)。 後続 sprint (= (1)/(2)/(3)) は各別 ADR / 別 PR で進める。 ADR-0061 Accepted ≠ production-ready 全体達成 ≠ 軸 G 完成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。

### 次

ADR-0061 PR merge 後:

1. user #110 Issue update (= user 別途実施)
2. 推奨順 (1) stash 退避分整理 sprint 起票判断 (= user 明示 GO 待ち)

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0061 新規起票 + 即時 Accepted (= 単一 doc-only PR、 Codex layer 2 plan review 4 round chain approve、 main agent autonomous) | (= 本 commit) |
