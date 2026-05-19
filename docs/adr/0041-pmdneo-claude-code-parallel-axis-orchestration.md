# ADR-0041: Claude Code 併走運用 = 主軸 orchestrator + sub-agent worker + Codex 自律壁打ち + 主軸介入 (= 30th session 末 user 判断、 軸並走による開発加速、 IR 軸 stacked PR 反省踏襲)

- 状態: **Draft** (= 2026-05-18 30th session 末起票、 設計先行 ADR、 memory + CLAUDE.md + dashboard は本 ADR scope-out で別 sprint commit chain、 Accepted 移行は軸 0 chain 完走 + 軸 A 試行成功 + user 最終確認時、 driver / runtime / 既存 schema / 既存 spike / 既存 fixture 完全不変 doc-only ADR)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa)
- 関連 ADR:
  - ADR-0036 (= FM/SSG 並走方針、 26th session 起票、 wip-ir-trunk に隔離、 軸並走の前例)
  - ADR-0033 (= rhythm sample provenance、 β sub-sprint 軸 A 着手予定)
  - ADR-0040 (= 30th session 末で IR 軸 chain 完走、 stacked PR 8 段の反省源)
- 関連 memory:
  - `feedback_codex_review_autonomous_no_user_judgment` (= sub-agent 継承する Codex 壁打ち規律 元出典)
  - `feedback_codex_implementation_review.md` (= 3 重 zero-trust review = session log 読込 → git diff 確認 → 規律 check の literal 規律、 sub-agent ↔ Codex loop に必須継承)
  - `feedback_branch_strategy.md` (= main / develop / wip- branch 運用規律、 軸別 wip- branch 命名根拠、 ただし PMDNEO 実運用では `wip-pmddotnet-opnb-extension` が事実上の集約点、 §決定 3 で例外明示)
  - `feedback_explanation_style.md` (= 30th session 末確立の説明 style 10 規律、 sub-agent return format に継承)
  - `feedback_explain_in_plain_japanese_before_commit` (= commit 前 6 構造、 sub-agent return にも適用)
  - `feedback_doc_governance_two_systems.md` (= AI 協働用 ADR と人間向け公開 docs の 2 系統分離、 sub-agent prompt template に literal 必須記述)

## 背景

26-30 session で IR 軸 (= ADR-0034〜0040) を 1 軸 stacked PR chain で進めた結果、 OPEN PR 8 段 + wip- branch 11 個まで膨張 (= 30th session 末で案 2 採用、 wip-ir-trunk に集約済、 PR #6-#13 全 CLOSED)。 user 側で「思いのほか多くの PR」 と認識され、 「遅れを取り戻したい」 「Claude Code を正式に併走させたい」 と要望。

PMDNEO Phase 2-4 残作業として 6 軸 (= 軸 A〜F) が並行候補に存在:

| 軸 | 内容 | 軸間 dependency |
|---|---|---|
| A | ADR-0033 β sample provenance 再開 | 完全独立 |
| B | Phase 2 FM/SSG driver フルスクラッチ | 軸 F に依存 |
| C | ADPCM-B 軸 | 完全独立 |
| D | WebApp 最小骨格 | 軸 C/F に依存 |
| E | IPL / プレイヤー V1 | driver 完成後 |
| F | MML compiler 拡張 | 完全独立 |

初期並走候補 = A + C + F (= 完全独立 3 軸)。

CLAUDE.md §記憶は AI に、 判断は自分が握る (= 30th session で確立した「説明 style 10 規律」 + Codex 自律壁打ち運用 = 主軸 orchestrator が判断を引き受けつつ sub-agent worker に並列実装委譲) を仕組み化する。

## 決定

### 決定 1: 主軸 (= Claude Code 親 session) + sub-agent (= worker) 2 階層構造

- **主軸** = user 対話を担当する Claude Code session (= 1 つ、 一元化)
- **sub-agent** = 主軸が起動する Agent tool 経由の worker (= 軸ごとに 1 つ、 並行起動可能)
- **sub-agent ネスト禁止** (= sub-agent から sub-agent 起動なし、 worker 階層は 1 段のみ)

主軸の責務:
- user 対話 + 進捗報告 + 判断仰ぎ
- dashboard 管理
- ADR 番号予約 + branch 命名
- 各 sub-agent への task prompt 設計
- sub-agent 結果の review + 統合判断
- Codex review との連携 (= 軸別 session 管理)
- memory 更新 (= 主軸 1 つで write 集約、 race condition なし)
- commit / push 最終 verify (= sub-agent commit 結果の diff 確認 + 規律遵守 check)

sub-agent の責務:
- 指定軸の task 実行 (= ADR 起票 / spike 実装 / fixture 追加 等)
- **commit 直前に Codex 自律壁打ち** (= 軸別 Codex session で review、 §決定 4)
- 進捗報告 (= 平易日本語 6 構造 + 200 単語以内)
- 完了時 deliverable 提示 (= file path / commit hash / verify 結果)
- 問題発生時 escalate (= §決定 5)

### 決定 2: worktree isolation 必須 (= Agent tool `isolation: "worktree"` flag)

各 sub-agent 起動時に **`isolation: "worktree"` flag** を必須指定する。 効果:

- 自動的に別 worktree directory が作成される
- sub-agent が独立 directory で作業 + commit
- file system 上で完全分離 = race condition なし
- 完了後の cleanup は Agent tool が自動処理

worktree 手動管理 (= `git worktree add` / `git worktree remove`) は不要。 ただし sub-agent return 時に worktree path + branch 情報を確認できる。

### 決定 3: 軸別 wip- branch (= 1 軸 1 branch 集約、 stacked 禁止)

各軸が独立 branch で作業:

- `wip-axis-a-sample-provenance` (= 軸 A、 ADR-0033 β)
- `wip-axis-c-adpcmb` (= 軸 C)
- `wip-axis-f-mml-extension` (= 軸 F)
- `wip-orchestration-setup` (= 軸 0、 本 ADR + memory + dashboard 確立用)

命名規律: `wip-axis-<軸>-<topic>`。 軸内の sub-sprint (= α/β/γ/δ) は **同 branch 内で commit chain**、 中間 wip- branch を作らない (= 30th session stacked PR 反省踏襲)。

軸完了時に **1 軸 1 PR で本拠地 (= `wip-pmddotnet-opnb-extension`) に merge**。 stacked PR は禁止。

**branch 集約点の例外説明** (= must-fix 1 反映): memory `feedback_branch_strategy.md` 規律では「develop が wip- branch の集約点」 だが、 PMDNEO 実運用では `wip-pmddotnet-opnb-extension` が事実上の集約点として機能している (= PR #3/#4/#5 merged 履歴 + 26-30 session IR 軸 stacked PR の base + 30 案 2 集約後の本拠地)。 本 ADR では現運用に従い「軸完了 PR の merge 先 = `wip-pmddotnet-opnb-extension`」 を **例外的に literal 規律化**する。 memory `feedback_branch_strategy.md` 規律と現運用のズレは別軸 (= `develop` 系統への将来統合 / branch 戦略 ADR 別途起票) で扱う scope-out 項目。

### 決定 4: sub-agent 常時 Codex 壁打ち + 軸別 Codex session + 3 重 zero-trust review (= must-fix 2 反映)

各 sub-agent は memory `feedback_codex_review_autonomous_no_user_judgment` 規律 + memory `feedback_codex_implementation_review.md` 3 重 zero-trust review 規律を継承し、 軸内で **自律的に Codex review を取得 + approve loop を回す**。

| sub-agent 動作 | 処理 |
|---|---|
| commit 直前 | `codex:codex-rescue` agent 経由で軸別 Codex session に review 依頼 |
| Codex approve | sub-agent が **3 重 zero-trust 自己 verify** 実施: (1) Codex return の reasoning trace を sub-agent 自身が読む、 (2) `git diff` で実 file 変更を sub-agent が確認、 (3) 規律 check (= 設計書/CLAUDE.md/触らない file/audio gate 規律遵守)。 全 PASS なら commit + push、 次 task へ進む (= 自律進行) |
| Codex revise (= must-fix 列) | sub-agent が修正 + 再 review (= 同 turn で loop) |
| Codex revise 3 round 超過 | escalate (= §決定 5) |
| Codex reject (= 設計根本問題) | escalate |
| 3 重 zero-trust 自己 verify 失敗 (= Codex approve でも sub-agent 自身が規律違反検知) | escalate (= `discipline_violation_risk` または `codex_unresolved`) |

3 重 zero-trust review は Codex 自律壁打ち運用と **対称軸** = Codex が approve しても sub-agent 側で独立 verify (= ground truth の独立確認、 zero-trust orchestration 規律踏襲)。 「Codex approve したから OK」 と機械的に進めず、 sub-agent も grounding source を独立 verify する。

### 決定 4-2: 主軸 ↔ Codex return 評価壁打ち (= 2 段壁打ち構造、 30th session 末 user 判断「終了判定も Codex 自律化」 反映)

§決定 4 (= sub-agent ↔ 軸別 Codex session) を **layer 1**、 主軸 ↔ Codex 統合判断 session を **layer 2** として 2 段壁打ち構造を確立する。

| layer | 壁打ち | 役割 | 起動主 |
|---|---|---|---|
| 1 | sub-agent ↔ 軸別 Codex session | sub-agent commit 直前の review (= §決定 4) | sub-agent 自律 |
| 2 (= 新規) | 主軸 ↔ 統合判断 Codex session | sub-agent return 受領後の評価 + 次 action 提案 | 主軸 |

#### layer 2 起動条件 (= 主軸単独判断 vs Codex 評価依頼)

| 条件 | 主軸単独 | Codex 評価依頼 |
|---|---|---|
| 単一 sub-agent return + 形式 check のみ | ✓ | (任意) |
| 複数 sub-agent return 統合 | × | **必須** |
| 軸間衝突検知 (= ADR 番号 / branch / file 領域 / 規律解釈衝突) | × | **必須** |
| ground truth 矛盾検知 | × | **必須** |
| 次 action 設計判断複数案 | × | **必須** (= + escalate user 上げ判断含む) |
| simple approve (= 規律遵守 + finding 明確) | ✓ | (任意) |

#### Codex 評価依頼 prompt template (= layer 2)

```
## sub-agent return 評価依頼

各 sub-agent の return 内容を literal 貼付。 評価軸:

1. format 規律遵守 (= ADR-0041 §決定 6 return format / 平易日本語 6 構造 / 200-300 単語以内)
2. ground truth 整合性 (= ADR / memory 規律 / source path 正確)
3. 軸間衝突検知 (= ADR 番号 / branch / file 領域 / 規律解釈)
4. 次 action 提案 (= approve / re-task / escalate / 主軸介入)
5. 主軸が見落とした可能性 point (= 規律違反 / 設計トレードオフ / aesthetic gate)

## return format (= Codex 出力)
- 全体評価: approve / revise / escalate
- 各 sub-agent return 評価
- 軸間衝突: 列挙 + 解消案
- 次 action 提案: 主軸が取るべき行動
```

#### Codex task queue 制約

Codex 内部 runtime は **同時 1 task 制限**。 layer 1 (= sub-agent 内 Codex 起動) と layer 2 (= 主軸 Codex 起動) が衝突する可能性。 解決策:

- layer 2 起動時、 layer 1 sub-agent が並行中 = sub-agent 完了待ち or 強制解放
- 軸別 Codex session ID は **context 分離のみ** で、 physical runtime は共有
- **複数 review を 1 task にまとめる** (= layer 2 evaluation + ADR review を 1 prompt で) で queue 効率化推奨

#### layer 2 採用効果

| 軸 | 効果 |
|---|---|
| 主軸 context 軽量化 | sub-agent return 評価を Codex に委譲、 主軸は判断結果受領のみ |
| 客観性 | 主軸単独判断より ground truth 整合 + 軸間衝突検知が機械的 |
| 軸間衝突検知 | 例 ADR 番号衝突 / 規律解釈衝突 / file 領域衝突を Codex が systematic check |
| user 上げ判断 | Codex が「user 判断必要」 と提案 → 主軸が escalate `design_judgment_needed` 経由 user 上げ |

#### 起動条件 拡張 (= 「Codex rescue 化」 規律、 31st session 末 user 「同じ事をやってる」 + 「その意思指示を Codex に委譲」 経路、 memory `feedback_codex_layer2_implementation_review_delegation.md` literal)

主軸の **user 確認質問 自体**を Codex layer 2 経由化 default 化する規律。 user 負担削減 + 主軸自律進行加速 + 機械的 review 可能項目を user から外す。

| 主軸 action | Codex layer 2 review 起動 | user 介入 |
|---|---|---|
| driver / runtime 改修方針提示 | **必須** | escalate or 最終確認のみ |
| 実装方針提示 (= source / spike / fixture 新規 or 重要 update) | **必須** | 同上 |
| 配置判定 / 即時実装 GO 判定 | **必須** | 同上 |
| ADR 大型更新 (= §決定 追加 / 削除) | **必須** | 同上 |
| user 確認質問「a/b/c のどれ?」 type | **必須** (= 主軸が user に直接聞く前に Codex に委譲) | 同上 |
| commit message 案 / PR description 案 | 任意 | - |
| simple status report (= 進捗報告) | 不要 | - |

##### 例外 (= user 直接判断必須、 escalate 経由)

- **aesthetic / audio audition 関連** (= 越川氏 final 判断 scope、 永久 user)
- **一般 user 判断 scope** (= 設計トレードオフ、 越川氏 directive / preference / mission 軸)
- **規律違反 risk 重大** (= driver source touch + 越境 / vendor 不可触 違反 / main 直接 commit / 機密情報露出 等)

##### 31st session 機能実証

Codex layer 2 session 019e3b50-8f23-7803-af9e-903d6587f891 で **計 6+ round 全 approve** = 軸 A/F 採用案決定 + 5 step 計画 review + 配置 + GO + 規律確立 + verify gate 経路 + 軸 C sub-sprint α layer 1 reflect + 本規律実装方針 review (= 自己参照例)。 Codex 1 task 同時制限 + 4 連続 hang + cancel 経由解放経験も literal 記録 (= memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` + dashboard escalation 履歴)。

##### default 永続化 + 毎回 user 確認禁止 (= 31st session 末 user 「毎回聞かないで。 常に Code resque 化で作業終わるまで継続」 literal 反映)

user 明示指示 = 「Codex rescue 化」 を主軸 default 動作とし、 起動条件 table 該当 action の度に user に「Codex rescue 化を使いますか？」 と確認する経路を **永続停止**。 主軸は本 §決定 4-2 起動条件 table に基づき **自律的に Codex layer 2 起動 + approve 受け commit + push + PR + merge** を進める。 user 介入経路は §例外 + escalate の 6 種 (= ADR-0041 §決定 4-1 末尾) のみ。

具体的禁止 pattern:
- 「Codex rescue 化を使いますか?」 を起動条件 table 該当 action 毎に問う
- 「user 判断 a/b/c?」 を起動条件 table 該当 action 毎に問う
- 「即時 GO で良いか?」 を Codex layer 2 approve 後に問う (= approve 自体が GO sentinel)
- 主軸が次 action 候補を user に列挙して選ばせる (= Codex layer 2 に投入して判断委譲)

具体的継続 pattern:
- 主軸 → Codex layer 2 投入 → approve → 主軸自律進行 (= commit + push + PR + merge + 次 step) を **作業終わるまで継続**
- user 介入は §例外 + escalate 6 種に該当する場合のみ self-judgment で停止 + user 報告
- session 終了は (1) 全 OPEN PR 0 件 + 全進行可能 sprint 完走、 (2) escalate 発生、 (3) user 明示停止指示、 のいずれかで判定

### 決定 4-3: Codex unavailable 時の主軸単独 fallback + retrospective review 必須 (= 30th session 末 layer 2 試行第 1 例で Codex runtime hang に直面、 fallback regime 確立)

§決定 4 + §決定 4-2 で確立した 2 段 Codex 壁打ち構造は、 Codex 内部 runtime の 1 task 同時制限と hang 可能性により unavailable 状態に陥る場合がある。 fallback 規律を確立:

#### fallback 起動条件

| 条件 | 動作 |
|---|---|
| Codex runtime unavailable (= hang / 起動失敗 / 解放されない) | 主軸単独で評価 + 次 action 実行 |
| sub-agent ↔ Codex (= layer 1) が hang | sub-agent が escalate `codex_unresolved` で主軸介入 |
| 主軸 ↔ Codex (= layer 2) が hang | 主軸が単独評価 fallback、 次 action 進行 |

#### fallback 主軸単独評価の規律

- ground truth integrity (= ADR / memory / source path) を主軸が確認
- 軸間衝突検知 (= ADR 番号 / branch / file 領域 / 規律解釈) を主軸が単独でも実施
- 設計判断複数案は escalate `design_judgment_needed` 経由で user 上げ (= Codex unavailable 時も user 判断は escalate 経由)
- 評価結果を dashboard escalation 履歴に literal 記録

#### retrospective review 必須

Codex runtime 復帰後、 fallback で進行した commit / sprint を **事後 review** で確認:

| 段階 | 動作 |
|---|---|
| Codex 復帰検知 | dashboard escalation 履歴の fallback 件を列挙 |
| retrospective Codex review 依頼 | fallback で進行した commit hash + sub-agent return の literal を 1 task で投入 |
| Codex 評価 | approve = fallback 妥当 / revise = 修正 commit 追加 / reject = revert 検討 |
| 修正 commit | 軸 chain の連鎖 commit として処理 (= rollback ではない) |

#### dashboard escalation 履歴の fallback 記録 format

```markdown
## escalation 履歴

| 日時 | 軸 | escalation 種別 | fallback / Codex 経由 | 解決方針 | retrospective review 状態 |
|---|---|---|---|---|---|
| 2026-05-18 | 軸 0 α | layer 2 hang | fallback (= 主軸単独評価) | 軸 0 α commit 進行 | pending (= Codex 復帰待ち) |
```

#### 30th session 末 軸 0 α での fallback 適用 (= 実 case 記録)

本 ADR §決定 4-2 試行第 1 例 (= sub-agent A/C/F return 評価 + ADR-0041 再 review 統合 task) を Codex に投入したが、 直前 background 起動 (= 通知 hang) と foreground 再起動 (= response 取得済) の後、 Codex 内部 runtime task queue が解放されず 2 度の新規投入拒否。

fallback として主軸単独評価:
- sub-agent A approve (= ground truth 整合)
- sub-agent C approve (= ADR 番号 0042 → 0043 訂正必要、 主軸 prompt ミス起因)
- sub-agent F approve (= ADR 番号 0042 → 0044 訂正必要、 同上)
- ADR-0041 must-fix 3 + nice-to-have 4 + §決定 4-2 + §決定 7 反映 approve

軸 0 α commit を fallback regime で進行、 retrospective review は Codex 復帰後実施予定。

軸別 Codex session ID は dashboard に literal 記録 (= §決定 7):

| 軸 | Codex session ID |
|---|---|
| A | (新規取得、 軸 A 試行直前) |
| C | (新規取得、 軸 C 起動直前) |
| F | (新規取得、 軸 F 起動直前) |

session ID は sub-agent 起動時に prompt に明示渡し (= sub-agent が context ゼロから start するため)。

### 決定 5: escalation 6 種 + 主軸介入手順

sub-agent が自律解決できない問題を検知したら **即座に主軸に escalate**:

| escalation 種別 | 内容 | 例 |
|---|---|---|
| `codex_unresolved` | Codex review 3 round 超過で解消せず | 設計判断の根本対立 / Codex が同じ must-fix を繰り返す |
| `discipline_violation_risk` | 規律違反検知 (= 触らない file / scope 外踏み込み リスク) | driver / vendor / main / 設計書ファースト違反 / 早すぎる抽象化 |
| `design_judgment_needed` | 設計判断が複数案あり user 判断 scope | ADR 解釈に複数候補 / トレードオフ含む変更 |
| `audit_gate` | user audition 必須 (= aesthetic / audio gate) | aesthetic accept gate / driver runtime MAME 試聴 |
| `unexpected_finding` | memory 規律外 / ground truth と矛盾 | datasheet 仕様矛盾 / 既存 source と不整合 |
| `merge_conflict` | worktree / branch / 軸間 dependency 状態異常 | rebase 衝突 / 軸間 file 重複 / branch 状態異常 |

主軸 (= 私) の介入手順:

1. sub-agent return 受領 (= status = `escalate`)
2. 状況把握 (= worktree 状態確認 + commit log + sub-agent message + 関連 memory / ADR re-read)
3. 解決方針決定:
   - (a) 規律解釈で sub-agent に再 task (= prompt 修正 + 再起動)
   - (b) user に判断仰ぎ (= 設計判断 scope / audition 必須)
   - (c) 主軸が直接介入実装 (= 規律違反 緊急対応 / 軸間 dependency 解消 / 短時間で済む修正)
4. sub-agent 再起動 (= 新規 instance、 解決方針を prompt に追加) or 主軸による解決
5. dashboard 更新 (= escalation 経緯 + 解決方針 + 完了時刻 literal 記録)

### 決定 6: sub-agent prompt 設計 = context literal 化 必須 (= doc-governance + write set + verify command 明示、 must-fix 3 + nice-to-have 1-2 反映)

sub-agent は **新規 instance で context ゼロから start** するため、 prompt に必要情報を全 literal 化する:

```
## 軸の概要
<何を達成するか、 1-2 文>

## 必須読み込み context (= 着手前に読む、 ground truth 順)
- /Users/koshikawamasato/Projects/pmdneo/CLAUDE.md (= 規律全般)
- /Users/koshikawamasato/.claude/projects/.../memory/MEMORY.md (= 関連 memory list)
- /Users/koshikawamasato/Projects/pmdneo/docs/adr/<軸の主 ADR>.md
- <その他軸固有 docs path>

## doc-governance 規律 (= memory `feedback_doc_governance_two_systems.md` literal 継承、 必須遵守)
- **AI 協働用 ADR** (= `docs/adr/00xx-*.md` 系 + `docs/design/handoff/` 配下) を **ground truth として扱う**
- **人間向け公開 docs** (= `docs/guide/` 等の派生 doc、 README.md 一部) は **派生物であり判断根拠にしない**
- 既存 ADR / handoff の削除・短縮・人間向け文体書き換えは user 明示依頼なしには行わない
- 公開 docs と AI 協働用 ADR の混同を回避

## 制約 (= allowed / forbidden 明示)
### allowed write set (= 軸内で write してよい file)
- `docs/adr/<予約 ADR 番号>-*.md` (= 軸専用 ADR)
- `scripts/<軸関連 spike>.py` (= 軸専用 spike script)
- `docs/design/<軸関連 directory>/*` (= 軸専用 fixture / schema)
- `README.md` の §<軸関連 section> 拡張 (= 軸専用 section に限定)

### forbidden write set (= 触ってはいけない file)
- driver / runtime source (= `src/sound/` 配下、 Z80 アセンブラ、 別途指示なしに touch 禁止)
- vendor 配下 (= `vendor/PMDDotNET/` 等、 完全不可触)
- main branch (= 直接 push 禁止、 main protection 適用済)
- `wip-pmddotnet-opnb-extension` 直接 commit (= 必ず wip-axis-* 経由)
- 他軸専用 file (= 軸別 dashboard 予約済の他軸領域)
- `wip-ir-trunk` (= IR 軸保管、 別途 touch 禁止)
- `MEMORY.md` / `CLAUDE.md` 直接 edit (= 主軸経由のみ、 sub-agent から提案 return)

## 規律遵守 (= 必須遵守)
- 説明 style 10 規律 (= memory `feedback_explanation_style.md`)
- 設計書ファースト (= 実装前に ADR で仕様 fix)
- Codex 自律壁打ち + 3 重 zero-trust review (= §決定 4)
- ADR 番号: <主軸予約済 番号 literal>
- branch: <wip-axis-<軸>-<topic> literal>

## 着手 task
1. step 1
2. step 2
...

## verify command + 期待 gate (= 機械検査経路)
- 例: `python3 scripts/<spike>.py <fixture> --output /tmp/test.json` → exit 0
- 例: `diff <expected> <actual>` → 0 lines (= byte-identical)
- 例: `gh pr view <PR>` → status APPROVED
- 全 verify command を sub-agent 内で実行 + 結果を return 内に literal 含める

## Codex 自律壁打ち + 3 重 zero-trust 規律 (= memory `feedback_codex_review_autonomous_no_user_judgment` + `feedback_codex_implementation_review.md` 継承)
- 軸別 Codex session ID: <literal>
- 各 commit 直前に codex:codex-rescue 経由 review 依頼必須
- Codex approve 後の sub-agent 側 **3 重 zero-trust 自己 verify**:
  1. Codex return の reasoning trace を sub-agent が確認
  2. `git diff` で実 file 変更を sub-agent が確認 (= Codex finding と実 code の整合)
  3. 規律 check (= 設計書/CLAUDE.md/forbidden write set/audio gate 規律遵守)
- 全 PASS なら commit + push、 1 つでも fail なら escalate
- Codex revise → 自律修正 + 再 review、 3 round 超過 → escalate

## 主軸介入要請 (= escalate) 条件 (= 6 種)
<§決定 5 を literal>

## return format

### approve case
- status: approve
- branch + commit hash + Codex review round
- 主要 deliverable (= file path 列 + 概要)
- **git status output literal** (= 変更 file 一覧、 untracked 含む)
- **verify command 出力 literal** (= 全 gate の exit code + 主要 output)
- 平易日本語 6 構造 (= やりたいこと / 前提 / やったこと / 結果 / 解釈 / 次) 200 単語以内

### escalate case
- status: escalate
- 問題種別 + 状況 + 提案 + user 判断要否
- **git status output literal** + **直近 commit log** + **関連 Codex finding literal**
- 平易日本語 6 構造 + 問題詳細 300 単語以内

### partial case
- status: partial
- 完了済 step + 残 step + 中断理由
- **git status output literal**

## 設計判断 (= トレードオフ含む変更) の扱い
- 設計トレードオフを含む変更は **必ず複数案を escalate `design_judgment_needed` 経由で主軸 / user に提示**
- sub-agent 内で勝手に 1 案決定しない (= CLAUDE.md §中核原則「記憶は AI に、 判断は自分が握る」 規律踏襲)
```

### 決定 7: dashboard 一元管理 (= docs/parallel-axes-dashboard.md)

各軸の状態を本拠地に置く dashboard で一元管理:

```markdown
# PMDNEO 併走軸 dashboard

## 軸予約表

| 軸 | branch | ADR 番号 | Codex session ID | 状態 | 直近 commit | 次の user 関与 |
|---|---|---|---|---|---|---|
| 0 (= orchestration) | wip-orchestration-setup | 0041 | - (= 規律確立は主軸直接) | 着手中 | - | PR review |
| A (= sample provenance β) | wip-axis-a-sample-provenance | 0042 | (未取得) | 未着手 | - | audition gate |
| C (= ADPCM-B) | wip-axis-c-adpcmb | 0043 | (未取得) | 未着手 | - | audition gate |
| F (= MML 拡張) | wip-axis-f-mml-extension | 0044 | (未取得) | 未着手 | - | machine verify |

## 軸別進捗 details
(= 各軸の sprint chain α/β/γ/δ 進捗、 Codex round 履歴、 escalation 履歴)

## ADR 番号予約簿
- 0041: 軸 0 = 本 ADR
- 0042: 軸 A 候補 (= ADR-0033 β 設計 ADR or sub-sprint 起票 ADR)
- 0043: 軸 C
- 0044: 軸 F

## escalation 履歴
(= 主軸介入 log)
```

dashboard は主軸が更新 (= sub-agent return 受領時 + 軸状態変化時)。 sub-agent は dashboard を **read のみ** (= context として参照、 write は主軸)。

dashboard 内に **Codex session ID 一覧** を持つ (= §決定 4 + §決定 4-2 で軸別 layer 1 と統合判断 layer 2 を分離):

```markdown
## Codex session ID 一覧

| 用途 | session ID | 起動主 | 起動条件 |
|---|---|---|---|
| 軸 A sub-agent ↔ Codex (= layer 1) | (= 軸 A 試行直前取得) | sub-agent 内自律 | commit 直前 |
| 軸 C sub-agent ↔ Codex (= layer 1) | (= 軸 C 起動直前取得) | sub-agent 内自律 | commit 直前 |
| 軸 F sub-agent ↔ Codex (= layer 1) | (= 軸 F 起動直前取得) | sub-agent 内自律 | commit 直前 |
| **統合判断 (= layer 2 主軸 ↔ Codex)** | **session 019e3425-3327-74e1-95bc-461cc5d0af66** | 主軸 起動 | 軸間衝突 / 統合評価 / next action 提案時 |
| 軸 0 規律確立 review (= 例外) | session 019e3425 流用 | 主軸 起動 | 軸 0 = 規律確立 = 統合判断系性質 |
```

### 決定 8: ADR 番号予約 = dashboard literal 管理

ADR 番号衝突防止のため、 軸開始時に主軸が dashboard に予約番号を literal 記録。 sub-agent prompt に予約番号を渡し、 sub-agent はその番号で起票。

| 軸 | 予約 ADR 番号 |
|---|---|
| 0 | 0041 (= 本 ADR) |
| A | 0042 |
| C | 0043 |
| F | 0044 |
| B / D / E (= 後続) | 0045+ |

予約変更は主軸判断 (= 軸の起票延期 / 中止時に解放)。

### 決定 9: memory write 集約 (= 主軸 1 つ、 sub-agent は finding 報告のみ)

memory file (= `/Users/.../memory/` 配下) は **主軸が単独で write**:

- read: 全 sub-agent 自由 (= 規律自動継承)
- write: 主軸のみ (= race condition 完全回避)
- sub-agent からの新規 memory 提案: return 内で「memory 追加候補」 として報告 → 主軸が判断 + 作成

新規 memory file 命名規律: `feedback_axis_<軸>_<topic>.md` (= 軸固有 finding は軸 prefix 付き) or `feedback_<general topic>.md` (= 全軸共通 finding)。

### 決定 10: scope-out 列 (= nice-to-have 3 反映、 doc governance + zero-trust gap 追記)

- main への merge (= 当面 wip-pmddotnet-opnb-extension が集約先、 main 保護維持)
- 本拠地への直接 commit (= memory `feedback_branch_strategy.md` 規律遵守、 全 commit は wip- branch 経由)
- sub-agent ネスト (= 1 階層のみ、 sub-agent から sub-agent 起動禁止)
- memory write の sub-agent 並行化 (= 主軸 1 つで集約、 race condition 防止)
- wip-ir-trunk への commit (= IR 軸は隔離保管、 当面 touch なし、 .NEO コンテナ軸着手時に取り出し)
- vendor 不可触
- driver / runtime / schema / spike / fixture touch (= 本 ADR は doc-only、 §決定 6 forbidden write set で明示)
- automated CI 化 (= 別軸)
- aesthetic / audio audition の sub-agent 内自律実行 (= 必ず escalate `audit_gate` で主軸経由 user)
- **既存 ADR / handoff のリファクタ・短縮・人間向け文体書き換え** (= user 明示依頼なし、 memory `feedback_doc_governance_two_systems.md` 規律踏襲)
- **人間向け公開 docs を ground truth として扱う** (= 同上、 AI 協働用 ADR が ground truth、 派生物を判断根拠にしない)
- **3 重 zero-trust review のスキップ** (= sub-agent が Codex approve で機械的に進めること禁止、 §決定 4 で必須化)
- `develop` 系統への統合 / branch 戦略 再設計 (= 別軸 ADR で扱う、 本 ADR は現運用 `wip-pmddotnet-opnb-extension` 集約点の例外規律化のみ)

## 後続 sprint 想定 (= 軸 0 α/β/γ/δ chain)

| commit | 内容 |
|---|---|
| α (= 本 commit) | ADR-0041 起票 (= 設計先行 ADR、 doc-only) |
| β | memory file 群追加 (= `feedback_parallel_axis_orchestration.md` + `feedback_subagent_codex_loop_with_escalation.md`) + CLAUDE.md 冒頭 §Claude Code 併走運用 追加 + MEMORY.md 冒頭固定 entry 追加 |
| γ | dashboard 作成 (= `docs/parallel-axes-dashboard.md`) |
| δ | PR 作成 + 本拠地 merge + 軸 A 試行準備 (= Codex session ID 取得 + sub-agent prompt draft) |

軸 0 完走後、 軸 A (= ADR-0033 β) を sub-agent で先行試行 → 動作確認 → 軸 C + F 並走起動。

本 ADR Accepted 移行は β/γ/δ commit chain 完走 + 軸 A 試行成功 + user 最終確認時。

## verify 計画

### A. ADR 整合性
- ADR-0034 §決定 1-6 IR 軸 + ADR-0036 FM/SSG 並走方針 + ADR-0040 IR 軸 chain 反省 と矛盾なし
- CLAUDE.md §中核原則 + §「記憶は AI に、 判断は自分が握る」 + §「設計書ファースト」 + §「動作確認義務」 と整合
- memory `feedback_branch_strategy.md` + `feedback_codex_review_autonomous_no_user_judgment` + `feedback_explanation_style.md` + `feedback_doc_governance_two_systems.md` 規律を継承

### B. 既存 chain 不変
- wip-pmddotnet-opnb-extension (= 開発本拠地) HEAD 不変
- wip-ir-trunk (= IR 軸保管) touch なし
- main 保護維持 (= 5 項目 enable)
- PR #6-#13 CLOSED 状態維持

### C. 後続 sprint verify gate (= β/γ/δ で実施、 本 ADR では計画明示のみ)

- β: memory + CLAUDE.md + MEMORY.md の自己一貫性 (= ADR ↔ memory ↔ CLAUDE.md 規律 literal 一致)
- γ: dashboard 構造の Codex review approve + 軸予約表 / ADR 予約簿 / escalation 履歴の 3 sub-section 完備
- δ: PR description literal 化 + 本拠地 merge 後 軸 A 試行可能状態 (= sub-agent prompt + Codex session 取得手順 整備)

## Annex

### A-1. 30th session 末 user 判断 経緯

| user 発言 | 判断 |
|---|---|
| 「Claude Code を正式に併走させたい」 | 並走仕組みの literal 化要望 |
| 「sub-agent 使って主軸はあなたができませんかね」 | 主軸 私 + sub-agent worker 階層 採用 |
| 「sub-agent は常に Codex と壁打ち、 問題発生時は主軸介入」 | §決定 4 + §決定 5 確立 |
| 「1 OK / 2 a / 3 それぞれ新規 / 4 お任せ」 | §決定 1-10 全体採用 + 軸 0 = ADR 起票 + memory + dashboard 全部 完全 doc 化 |

### A-2. IR 軸 stacked PR 反省 (= 30th session 案 2 集約) との関係

26-30 session で IR 軸を 1 軸内で 8 PR stacked にした結果、 PR 一覧の見通し低下 + merge 順序の複雑化 + user 認識 (= 「思いのほか多くの PR」) を招いた。

本 ADR の §決定 3 「1 軸 1 branch 集約、 stacked 禁止」 規律は、 この反省を踏襲。 軸内の sub-sprint (= α/β/γ/δ) は同 branch 内 commit chain で進める。

ただし軸内 commit chain は維持 (= 26-30 session で確立した「ADR 起票 → schema → spike → fixture」 pattern を軸内で踏襲)。 各 commit は Codex 自律壁打ち approve を経る。

### A-3. 26-30 session Codex 自律壁打ち運用 との関係

memory `feedback_codex_review_autonomous_no_user_judgment` で確立した「approve → auto commit、 revise → 修正再 review、 reject 相当のみ user 上げ」 規律を sub-agent に継承。

ただし軸別 Codex session を別途取得する (= 26-30 session の単一 session `019e3425` を継続使用しない、 軸間の review context 分離)。

主軸 (= 私) は Codex review に介入しない (= sub-agent と Codex の 1 対 1)。 escalation 時のみ主軸が状況把握 + 解決方針決定 (= 必要なら主軸が直接 Codex review 依頼するケースもあるが、 sub-agent 復旧後は再び sub-agent ↔ Codex に戻る)。

### A-4. 軸 0 / A / C / F の sub-agent 起動 例 (= 本 ADR β/γ/δ で sub-agent 起動なし、 軸 A 試行 時に literal 化)

軸 0 = 主軸が直接実装 (= 規律確立を sub-agent に委譲すると循環依存)。 軸 A 試行 が sub-agent 起動の最初の例。

軸 A 試行 prompt 概要 (= 本 ADR Annex で記録、 δ commit で literal 化予定、 nice-to-have 4 反映で user audition escalation point 明示):
- 軸の概要 = ADR-0033 §π15.14 reject 後の β sub-sprint 再開
- 必須読み込み = ADR-0033 + memory `feedback_ai_engineering_gate_before_human_audition` + 退避 artifact list
- 制約 (= allowed write set / forbidden write set 別々に明示)
  - allowed: `docs/adr/0042-*.md` / 軸専用 spike script / 軸専用 fixture / README §軸 A section
  - forbidden: driver / vendor / main / 本拠地直接 commit / 他軸領域 / wip-ir-trunk / MEMORY.md / CLAUDE.md
- ADR 番号 = 0042
- branch = wip-axis-a-sample-provenance
- Codex session ID = (δ 時点で取得)
- 着手 task = (a) mixer 構造 or .fxp gain 設計案 (= **複数案あり、 1 案決定前に必ず escalate `design_judgment_needed`**)、 (b) 退避 4 artifact 評価、 (c) β sub-sprint 設計 ADR 起票
- **user audition escalation point (= aesthetic gate)**:
  - artifact 再生成完了 → user audition gate (= **必ず escalate `audit_gate` で主軸経由 user に依頼**、 sub-agent 内で audition 判定しない)
  - audition reject → reject 経緯 + retry 軸を escalate で主軸に共有
  - audition approve → 次 sub-sprint へ進む

### A-5. 後続 sprint 想定 (= 軸 0 完走後)

| sprint | 内容 |
|---|---|
| 軸 0 β | memory + CLAUDE.md 拡張 commit |
| 軸 0 γ | dashboard 作成 commit |
| 軸 0 δ | PR 作成 + 本拠地 merge + 軸 A 試行準備 (= Codex session 取得 + prompt draft) |
| 軸 A 試行 | sub-agent 1 つ起動 + ADR-0042 起票 + Codex 壁打ち動作確認 |
| 軸 C / F 並走起動 | 軸 A 安定後、 3 軸並走 fully 起動 |
| 規律 refine | 並走で発見された課題を memory + ADR-0041 §決定 に追記 |
