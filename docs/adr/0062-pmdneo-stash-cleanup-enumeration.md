# ADR-0062: PMDNEO stash 退避分整理 実作業 ADR = stash list 5 件 enumeration + 各 stash 4 種選択肢 + user 採否 gate (= ADR-0061 §決定 3 (1) literal 後続、 PR1 = doc-only + stash 操作なし、 PR2 = 採否反映 + Accepted 移行)

- 状態: **Draft** (= 2026-05-24 39th session、 PR1 起票時、 ADR-0061 §決定 3 (1) literal 後続 実作業 ADR、 stash 5 件 enumeration + user 採否 gate 未了、 PR2 で採否反映 + Accepted 移行、 Codex layer 2 plan review 2 round chain approve)
- 起票日: 2026-05-24
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0061** (= 母 ADR、 §決定 3 (1) literal「stash 5 件 + 4 種選択肢 enumeration、 実作業 ADR で user 採否」 後続)
  - ADR-0048 (= ζ-δ-2 sprint で stash@{0}/@{1} 由来)
  - ADR-0045 (= 軸 B 設計 ADR、 軸 B 実装 sprint chain ADR-0049〜0055 で stash@{2}/@{3}/@{4} 代替済)
- 関連 memory:
  - `project_pmdneo_adr_0061_initiated.md` (= ADR-0061 起票 + 3 系統 sprint 構成、 §決定 3 (1) 後続 実作業 ADR)
  - `project_pmdneo_39th_session_zeta_epsilon_complete.md` (= 39th session ζ-ε 完走 + 軸 G dynamic supply 完成、 stash 退避分 5 件 user 判断軸 literal)

## 背景 (= why now)

### ADR-0061 §決定 3 (1) literal 後続

ADR-0061 Accepted (= 2026-05-24 39th session、 PR #123 MERGED at `c552b79`) で残課題 3 系統 plan 整理確定。 §決定 3 (1) literal:

> (1) stash list 5 件 + 各 stash 毎 4 種選択肢 (= apply / drop / branch 化 / 保留継続) 列挙、 ADR-0061 plan ADR で選択肢 enumeration のみ + **実作業 ADR で user 採否**

本 ADR-0062 がその「実作業 ADR」。

### user 明示 option 2 = 2 PR 分割

ADR-0061 完走報告後の user judgment literal:

> option 2 を推奨します。 stash 操作は reversible に見えても、 実際には drop / apply / branch 化が混ざると状態変化が大きくなります。 ADR-0061 で「実作業 ADR で user 採否」 と決めた以上、 まず ADR-0062 起票 + stash 5 件の内容 enumeration + user 採否 gate 記録 を 1 PR に閉じる方が安全です。
> 推奨フロー: PR1 = ADR-0062 起票 + stash 5 件 enumeration + user 採否 gate 記録 (= ここでは stash 操作をしない) → user 採否判断 → PR2 = user 判断に基づいて stash 操作実施 + 結果を ADR-0062 に記録 + Accepted 化。

= PR1 = doc-only + stash 操作なし、 PR2 = 採否反映 + Accepted 移行 の 2 PR 分割確定。

### ADR-0062 起票時点の現在状態

**ADR-0062 起票時点 (= 2026-05-24 39th session ADR-0061 完走直後) の現在状態 = ADR-0048 Accepted (= 軸 G dynamic supply 完成、 ζ-ε で Draft → Accepted 移行完了)** + ADR-0049〜0061 全 Accepted + 軸 G ε partial state placement (= 0xFD32-0xFD38) は ADR-0048 Accepted 後の保持状態。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0062 PR1 を起票、 stash 5 件 enumeration + user 採否 gate 記録 + stash 操作なし。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。

## 決定

### 決定 1: stash 5 件 enumeration (= 番号 + branch 名 + 件名 + stat 併記、 primary key = branch 名 + 件名)

| 番号 | base branch | 件名 | 変更 file 概要 |
|---|---|---|---|
| **stash@{0}** | `wip-adr-0048-zeta-delta-2-axis-g-audition-fixture-revise` | `uncommitted: fm voice round 2 + silent enforcement + verify update (= scope-out by user direction)` | `src/driver/standalone_test.s` +89 行 / `verify-axis-g-zeta-delta-2-audition-revise-dispatch.sh` +42 行 (= 計 2 file 95 ins + 36 del) |
| **stash@{1}** | `wip-adr-0048-zeta-delta-2-axis-g-audition-fixture-revise` | `scope-out: .gitignore AGENTS.md add` | `.gitignore` +3 行 (= 計 1 file 3 ins) |
| **stash@{2}** | `develop` | `Phase 8d (= NMI query版、 drum 全停止 bug 再発)` | `src/driver/standalone_test.s` +127 行 / `vendor/ngdevkit-examples/00-template/main.c` +103 行 (= 計 2 file 188 ins + 42 del) |
| **stash@{3}** | `develop` | `Phase 8c-2 (= LOOP stack visualize、 全 part 無音 bug)` | `src/driver/standalone_test.s` +144 行 / `vendor/ngdevkit-examples/00-template/main.c` +97 行 (= 計 2 file 191 ins + 50 del) |
| **stash@{4}** | `main` | `SubF-1.2 spike WIP (pre-rollback to SubF-1.1)` | `scripts/audio-gate.sh` +16 / `scripts/build-poc.sh` +8 / `src/driver/IRQ.inc` +45 / `src/driver/PMD_Z80.inc` +159 / `src/driver/WORKAREA.inc` +8 / `vendor/ngdevkit-examples/00-template/main.c` +57 / `00-template/rom.mk` +44 (= 計 7 file 245 ins + 92 del) |

注: stash@{n} 番号は将来 stash 追加・削除でずれる可能性あり = **primary key = base branch + 件名** で固定識別。

### 決定 2: 各 stash 採用候補 (= main agent recommendation、 user 採否前の暫定候補)

main agent recommendation = main agent 解釈による暫定候補。 ADR-0062 PR1 時点では **user 採否未確定** (= PR2 で user judgment 反映)。

| stash | main agent recommendation | 根拠 |
|---|---|---|
| stash@{0} | **drop 推奨候補 (= user 採否前)** | user 「scope-out by user direction」 明示 + ADR-0048 ζ-δ-2 sprint で `TEST_MODE_AXIS_G_AUDITION_REVISE` flag 経由 voice (= `fm_voice_data_audition` percussive envelope) + `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP` flag 経由 dispatch gate (= candidate C 採用) で同等以上に正式実装済 = 重複あり |
| stash@{1} | **drop 推奨候補 (= user 採否前)** | user 「scope-out」 明示 + `.gitignore` AGENTS.md は untracked 維持で安全 (= user 明示永続 scope-out) + .gitignore 更新は将来 user 判断 sprint で再起票可 = 重複なし、 ただし不要 |
| stash@{2} | **drop 推奨候補 (= user 採否前)** | `develop` branch 由来 Phase 8d (= 38th session 以前)、 drum 全停止 bug 再発状態 + 軸 B 実装 sprint chain (= ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable / ADR-0052〜0055 v2 driver foundation / ADR-0057〜0059 roadmap ①〜③) で driver 大幅改修済 = bug 状態で保存意味薄い |
| stash@{3} | **drop 推奨候補 (= user 採否前)** | `develop` branch 由来 Phase 8c-2 (= 38th session 以前)、 全 part 無音 bug 状態 + 軸 B 実装 sprint chain で代替済 = bug 状態で保存意味薄い |
| stash@{4} | **drop 推奨候補 (= user 採否前)** | `main` branch 由来 SubF-1.2 spike WIP (= 軸 B/IPL 系 大規模 spike)、 SubF-1.1 へ rollback 済 + 軸 B 実装 sprint chain で v2 driver foundation 確立 + IPL 系は ADR-0047 軸 E 候補 (= future) で別軸 = 大規模 + 古い + 代替済 |

**全 5 件「drop 推奨候補 (= user 採否前)」** = ただし最終判断 user、 ADR-0062 PR1 時点では確定ではない。

wording 規律 (= ADR-0062 全体で固定):
- **使用可** = 「drop 推奨候補 (= user 採否前)」 / 「main agent recommendation = drop 候補」
- **禁止** = 「drop 予定」 / 「drop 決定済」 / 「全 5 件 drop」 / 「drop 確定」

### 決定 3: 重複判定 (= 各 stash と既 commit / 既 ADR / 既 sprint chain との関係)

| stash | 重複あり / なし | 関連 commit / ADR / sprint |
|---|---|---|
| stash@{0} | **重複あり** | ADR-0048 ζ-δ-2 sprint = PR #121 (= `a7588d7` 等)、 fm voice round 2 + silent enforcement 機能は `TEST_MODE_AXIS_G_AUDITION_REVISE` + `TEST_MODE_AXIS_G_AUDITION_MUTE_*` + `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP` flag で正式実装済 |
| stash@{1} | **重複なし、 ただし不要** | AGENTS.md は user 明示永続 scope-out untracked retain、 .gitignore 更新不要 |
| stash@{2} | **重複なし、 bug 状態** | Phase 8d は 38th session 以前 (= 軸 B 起票前)、 現 driver は ADR-0049〜0055 + ADR-0057〜0059 で v2 driver foundation + production-ready roadmap ①〜③ 完成済、 Phase 8 系遺産は obsolete |
| stash@{3} | **重複なし、 bug 状態** | stash@{2} 同様、 Phase 8c-2 も 38th session 以前の遺産 |
| stash@{4} | **重複なし、 rollback 済** | SubF-1.2 spike WIP、 SubF-1.1 へ rollback 済、 大規模 driver 改修 + IPL/script 系は別軸 (= ADR-0047 軸 E 候補) で別途設計 |

### 決定 4: 4 種選択肢 literal (= 各 stash 毎 user 採否)

各 stash について user は **4 種選択肢** から自由選択:

| 選択肢 | 操作 | 結果 |
|---|---|---|
| **apply** | `git stash apply stash@{n}` + 別 branch / PR 化 | stash 内容を作業 tree に展開 + 新 commit/PR 化 + stash drop (= apply 後の手順、 別 PR で実施) |
| **drop** | `git stash drop stash@{n}` | stash 完全破棄 (= 復元不可、 ただし `git fsck --unreachable` で 30 日以内は復元可能性あり) |
| **branch 化** | `git stash branch <name> stash@{n}` | 新 branch 作成 + stash 内容 apply + stash drop (= 内容保存方法、 PR 化前に branch 検査可能) |
| **保留継続** | (= 操作なし) | stash 完全不変、 将来 sprint で再判断 |

main agent recommendation は判断材料、 user は 4 種から自由選択。

### 決定 5: PR1 = doc-only + stash 操作なし (= stash 5 件本体完全不変)

PR1 で main agent が実施する操作:
- ADR-0062 file 新規作成
- dashboard 2 箇所 update (= ADR 番号予約簿 0062 行 + escalation 履歴 ADR-0062 PR1 entry)
- memory entry 起票 + MEMORY.md index 1 行追加 (= repo 外 user 個人 file)
- commit + push + PR1 作成

PR1 で main agent が **実施しない** 操作 (= PR2 scope):
- `git stash apply` / `git stash drop` / `git stash branch` 一切実施しない
- stash 5 件本体完全不変 (= `git stash list` 結果 5 件保持)
- driver source / verify script / vendor / fixture / build flag 一切変更しない

### 決定 6: 不可触対象 literal 明示列挙

**driver source** = `src/driver/standalone_test.s` 等 全完全不変

**verify script** = `src/test-fixtures/axis-g/verify-axis-g-*.sh` / `src/test-fixtures/axis-b/verify-axis-b-*.sh` / `verify-mute-semantics.sh` / `verify-fadeout-semantics.sh` / `verify-ssg-tone-enable.sh` 等 全完全不変

**vendor/** = vendor wav 3 件 (= `lefthook.wav` / `lightbulbbreaking.wav` / `woosh.wav`) + 未確認 untracked MML 3 件 untracked retain、 vendor 本体完全不変

**fixture** = `pmdneo_v2_song_fixture_*` (= ADR-0048 ζ-β/δ 由来 fixture 含む) 等 全完全不変

**build flag** = `TEST_MODE_AXIS_G_V2_PPC` / `TEST_MODE_AXIS_G_AUDITION_REVISE` / `TEST_MODE_AXIS_G_AUDITION_MUTE_*` / `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP` / `TEST_MODE_V2_SONG_FIXTURE` 等 既存 flag 完全不変

**ADR-0048 Accepted + Annex 全** = §sub-sprint ζ-α/β/γ/δ-1/δ-2/ε 完了 section literal 不変、 履歴改変 risk 回避

**ADR-0049〜0061 全 routine body + 本文** = 全 Accepted ADR 本文不変

**既存 routine + cmd 0x05 path + `pmdneo_song_main` + irq_handler_body** = driver active code 完全不変

**stash 5 件 本体** = `git stash list` の 5 件 (= stash@{0}〜stash@{4}) 完全不変、 PR1 では `git stash apply` / `drop` / `branch` 一切実施しない

### 決定 7: 表記制約 5 件 literal 再掲 (= ADR-0061 §決定 6 継承 + ADR-0062 で明示列挙)

| 表現 | ADR-0062 時点 | 解禁条件 |
|---|---|---|
| 「軸 G dynamic supply 完成」 (日本語版) | **使用可** | ADR-0048 ζ-ε Accepted 後の表現として使用可 |
| `axis-G dynamic supply complete` (英語版) | **使用可** | 同上 (= 日英両版同時解禁) |
| 「軸 G 完成」 | **literal 禁止維持** | dynamic supply 単独実装より広い範囲、 軸 G 全体完成は別 axis (= 軸 D / E 等) 完了後の future |
| 「軸 B 完成」 | **literal 禁止維持** | v2 driver production-ready 化 + `cmd 0x05 + pmdneo_song_main` → v2 driver 経路 switch は ADR-0045 §I-5-b の future |
| 「production-ready 全体達成」 | **literal 禁止維持** | ADR-0056 §決定 3 4 系統全通過 + 越川氏 audition approve + 本番 cmd 切替後の future |
| 「本番 cmd 切替完了」 | **§禁止表現リスト枠ではなく別 track で user 判断する表現** | ADR-0061 §決定 3 (3) sprint で production-ready gate 全通過 + cmd switch + user 明示 GO 後にのみ使用可、 **ADR-0062 時点では不可** |

### 決定 8: user 採否 gate (= PR1 merge 後)

PR1 merge 後の経路:
1. main agent が AskUserQuestion 経路で各 stash 採否確認投入 (= 4 種選択肢 × 5 stash = 計 5 件確認)
2. user 採否判断 literal を受領
3. main agent が PR2 plan を Codex layer 2 plan review に投入
4. approve なら PR2 = user 採否反映 + stash 操作実施 + ADR-0062 result 記録 + Accepted 移行

### 決定 9: production build byte-identical 維持 + 根拠 literal

ADR-0062 PR1 = **doc-only sprint** で driver / verify / vendor / fixture / build flag **完全不変** = production build sha256 = ζ-ε 同 sha256 維持 (= 通算 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 不変)。

**sha256 維持の根拠** = driver / verify / vendor / fixture / build flag 不変 (= doc-only sprint で driver build artifacts 変化なし)。

**実際の変更範囲** (= ADR-0061 §決定 9 同形式):
- **(a) repo 内** = `docs/adr/0062-pmdneo-stash-cleanup-enumeration.md` 新規 + `docs/parallel-axes-dashboard.md` 限定 update (= ADR 番号予約簿 0062 行 + escalation 履歴 ADR-0062 PR1 entry 1 件)
- **(b) repo 外** = Claude Code Agent SDK auto memory dir (= `/Users/koshikawamasato/.claude/projects/-Users-koshikawamasato-Projects-pmdneo/memory/`) で memory file 新規 + MEMORY.md index 1 行追加 = PR diff には現れない

sha256 再計算は doc-only sprint で driver build 走らないため不可、 **diff 範囲 verify + flag 不変 verify を primary gate** とする。

### 決定 10: 変更範囲 limited verify

**ADR-0049〜0061 本文 + dashboard 既存 0049-0061 行 + 既存 escalation 履歴 entry 完全不変** = 履歴改変 risk 回避。

repo 内 PR1 diff = **2 file 限定差分** (= `docs/adr/0062-*.md` 新規 1 件 + `docs/parallel-axes-dashboard.md` 限定 update 1 件)。 repo 外 memory file = PR diff には現れない、 commit 対象外。

## verify gate (= doc-only sprint、 spec consistency check)

- ADR-0062 新規 file 起票 + ADR-0061 §決定 3 (1) literal 後続
- driver / verify script / vendor / fixture / build flag 完全不変
- stash 5 件本体完全不変 (= `git stash list` 結果保持)
- m1 binary byte-identical 維持期待 (= 通算 sha256 `b15883fe...` 不変)
- ADR-0048 Accepted + Annex 全 + ADR-0049〜0061 routine body + 本文 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain
- repo 内 diff = 2 file 限定
- repo 外 memory file = PR diff に現れない、 commit 対象外

## Codex layer 2 plan review chain (= 2 round chain、 全 must-fix 反映)

| round | judgment | must-fix / nice-to-have / latent-risk | agentId |
|---|---|---|---|
| round 1 | revise | 2 must-fix (= 決定 6 不可触対象 literal 列挙 + 決定 7 表記制約 5 件 literal 再掲) + 2 nice-to-have (= dashboard wording 限定 + 決定 2 main agent recommendation 分離) + 2 latent-risk (= stash 番号ずれ branch 併記 + drop 推奨候補 wording) | `aae560db5cfc46e48` |
| round 2 | **approve** | 0 件 (= 全 6 件反映確認、 must-fix なし + nice-to-have なし + latent-risk なし) | `a6239ef0c7b683160` |

= main agent autonomous で起票 + commit + PR1 + implementation review + merge 進行。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

### やりたいこと

ADR-0061 §決定 3 (1) literal 後続 = stash 退避分整理 実作業 ADR を PR1 = doc-only で起票。 stash 5 件 enumeration + 各 stash 4 種選択肢 (= apply / drop / branch 化 / 保留継続) literal + user 採否 gate 記録、 stash 操作なし、 PR2 で採否反映 + Accepted 移行。

### 前提

- ADR-0061 Accepted (= 2026-05-24 PR #123 MERGED at `c552b79`)
- user 明示 option 2 GO = 2 PR 分割、 PR1 = doc-only + stash 操作なし + PR2 = 採否反映 + Accepted
- Codex layer 2 plan review 2 round chain approve (= round 1 revise 6 件反映 → round 2 approve)

### やったこと

- ADR-0062 PR1 起票 doc-only sprint (= 単一 doc-only PR)
- stash 5 件 enumeration (= 番号 + branch 名 + 件名 + stat 併記、 primary key = branch 名 + 件名)
- 各 stash 採用候補 (= main agent recommendation = drop 推奨候補 5 件、 user 採否前) + 重複判定 + 4 種選択肢 literal
- 表記制約 5 件 + 不可触対象 literal 明示列挙
- dashboard 2 箇所 update + memory entry 起票

### 結果

- ADR-0062 Draft (= PR1、 PR2 で Accepted 移行)
- stash 5 件本体完全不変 (= PR1 では stash 操作なし)
- production build PASS + m1 binary byte-identical 維持 (= 通算 sha256 `b15883fe...`)
- ADR-0049〜0061 本文 + 既存 dashboard 0049-0061 行 完全不変

### 解釈

ADR-0062 PR1 = doc-only enumeration + user 採否 gate 記録 sprint (= ADR-0061 §決定 3 (1) literal 後続 実作業 ADR)。 PR1 では stash 操作なし、 user 採否は PR1 merge 後 AskUserQuestion 経路で確認、 PR2 で採否反映 + Accepted 移行。

### 次

PR1 commit + push + Codex layer 2 implementation review + PR1 merge → user AskUserQuestion 採否確認 → PR2 plan → Codex review → PR2 = 採否反映 + 操作実施 + Accepted 移行 → user 完走報告。

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0062 PR1 新規起票 Draft (= ADR-0061 §決定 3 (1) literal 後続、 stash 5 件 enumeration + user 採否 gate 記録 doc-only、 Codex layer 2 plan review 2 round chain approve、 main agent autonomous) | (= 本 commit) |
