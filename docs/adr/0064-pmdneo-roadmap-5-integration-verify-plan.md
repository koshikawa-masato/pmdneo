# ADR-0064: PMDNEO roadmap ⑤ 統合 verify sprint plan = ADR-0056 §決定 3 (a)(b)(c) gate 統合 verify plan ADR (= ADR-0063 §決定 3 roadmap ⑤ literal 後続、 doc-only filing、 実作業は別 ADR)

- 状態: **Accepted** (= 2026-05-24 39th session、 単一 doc-only PR で起票 + Accepted = ADR-0056 / ADR-0060 / ADR-0061 / ADR-0063 同形式、 Codex layer 2 plan review 1 round approve = must-fix なし + nice-to-have 1 件反映 + latent-risk 1 件反映 + 越権操作なし、 ADR-0063 §決定 3 roadmap ⑤ literal 後続 user 明示 GO「次 sprint は roadmap ⑤ 統合 verify = ADR-0064」 + 「Codex layer 2 review-only 3 件 literal 強化」 経由)
- 起票日: 2026-05-24
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0063** (= 母 ADR、 §決定 3 roadmap ⑤ 統合 verify sprint = ADR-0064 候補 literal 後続)
  - **ADR-0061** (= 残課題 3 系統 plan、 §決定 7 後続 sprint chain 独立性 + plan ADR vs 実作業 ADR 分離 pattern 由来)
  - **ADR-0056** (= production-ready 選定 ADR、 §決定 3 4 gate ground truth + §決定 3-a trace-equivalence 定義、 §決定 4 roadmap ①〜④ 由来)
  - ADR-0062 (= §決定 3 (1) stash 退避分整理 sprint 完了)
  - ADR-0045 (= 軸 B 設計、 §I-5-b future = (3) 本番 cmd 切替 user 判断軸)
  - ADR-0048 (= 軸 G dynamic supply 完成、 (d) gate 部分達成 source)
  - ADR-0057 (= roadmap ① FM/SSG 実音 Accepted、 (a)(b) gate 部分達成 source)
  - ADR-0058 (= roadmap ② song parse + IRQ 連携 Accepted、 (a) gate 部分達成 source)
  - ADR-0059 (= roadmap ③ ADPCM-B/rhythm 実 dispatch Accepted、 (a)(b) gate 部分達成 source)
  - ADR-0060 (= roadmap ④ 軸 G dynamic supply 依存整理 Accepted)
  - ADR-0049〜0055 (= 軸 B 実装 sprint chain Accepted、 (b)(c) gate 部分達成 source)
- 関連 memory:
  - `project_pmdneo_adr_0063_initiated.md` (= ADR-0063 §決定 3 roadmap ⑤ 後続)
  - `project_pmdneo_adr_0061_initiated.md` (= ADR-0061 §決定 7 plan ADR vs 実作業 ADR 分離 pattern)
  - `project_pmdneo_39th_session_zeta_epsilon_complete.md` (= 軸 G dynamic supply 完成 + 残課題)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= 39th session ADR-0062 PR2 越権 merge 事例後の規律強化 + 3 件 literal 冒頭強調)
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 plan ADR は実装 ADR ではない)

## 背景 (= why now)

### ADR-0063 §決定 3 roadmap ⑤ literal 後続

ADR-0063 Accepted (= 2026-05-24 39th session、 PR #126 MERGED at `ba8d654`) で 4 gate status 確認 + roadmap ⑤/⑥/⑦ 起票判断 literal 確定。 §決定 3 literal:

> | **roadmap ⑤ 統合 verify sprint** | (a)(b)(c) gate 統合 verify = 全 sprint chain ALL PASS + 全 ch trace-equivalence + 全機能統合 verify | (a)(b)(c) | **ADR-0064 候補** |

本 ADR-0064 がその「roadmap ⑤ 統合 verify sprint」 = (a)(b)(c) gate 統合 verify plan ADR。

### ADR-0061 §決定 7 plan ADR vs 実作業 ADR 分離 pattern 継承

ADR-0061 plan ADR (= 3 系統 plan 整理) → ADR-0062 実作業 ADR (= stash 退避分整理 実 git stash drop 実行) の plan / 実作業分離 pattern を継承。 ADR-0064 = roadmap ⑤ plan ADR (= doc-only)、 実作業は別 ADR (= ADR-0067+ 候補) で別 sprint。 plan ADR で sub-sprint 構成 + scope literal 確定 → 実作業 ADR で実 verify 実行。

### ADR-0064 起票時点の現在状態

**ADR-0064 起票時点 (= 2026-05-24 39th session、 ADR-0063 PR #126 MERGED 直後) の現在状態**:

- ADR-0048 Accepted (= 軸 G dynamic supply 完成)
- ADR-0049〜0063 全 Accepted (= 軸 B 実装 sprint chain + production-ready 選定 ADR + roadmap ①〜④ + ζ-ε 完走 + plan 整理 + stash 退避分整理 + production-ready 全体判定 status 確認 全完了)
- 軸 G ε partial state placement (= 0xFD32-0xFD38) ADR-0048 Accepted 後の保持状態
- stash 5 件全 drop (= `git stash list` empty 維持)
- ADR-0056 §決定 3 4 gate 全「partial 達成」 status enumeration 完了

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0064 を起票。 統合 verify sub-sprint 構成 plan + scope literal + 番号 rationale literal 確定。 **plan ADR、 実作業は別 ADR (= ADR-0067+ 候補)**。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。 39th session ADR-0062 PR2 越権 merge 事例後の規律強化 = Codex layer 2 review only + commit / branch / merge 禁止 + merge は main agent 経路のみ literal 遵守 (= 冒頭 3 件 literal 強調 prompt 経由)。

## 決定

### 決定 1: roadmap ⑤ 統合 verify sprint scope = ADR-0056 §決定 3 (a)(b)(c) gate 統合 verify

ADR-0056 §決定 3 4 gate のうち **(a)(b)(c) 3 gate** を統合 verify 対象とする。 (d) audition は roadmap ⑥ ADR-0065 候補で別 sprint (= ADR-0063 §決定 3 literal 整合)。

#### (a) 実 MML 再生 gate 統合 verify

- **scope**: v2 driver 経路 (= `cmd 0x07 + pmdneo_v2_*` dispatcher 経由) で実 MML song を register write level で再現 + 既存 cmd 0x05 + `pmdneo_song_main` 経路と並走 + register trace 全 ch + 全機能統合 capture
- **目的**: 各 ch 個別 verify 完了済 (= roadmap ①〜③ Accepted) を 1 件の実 MML song に対して統合実行 + 統合 trace 取得
- **既存個別 verify ground truth**: ADR-0057 (= FM/SSG 実音) + ADR-0058 (= song parse + IRQ 連携) + ADR-0059 (= ADPCM-B/rhythm 実 dispatch) 各 sprint chain Accepted

#### (b) 実音 register trace-equivalence gate 統合 verify

- **scope**: FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6 = **16 ch 同時 register write trace** を v2 driver / 既存 driver 両経路で capture + **trace-equivalence 確認 (= ADR-0056 §決定 3-a literal)**
- **trace-equivalence 定義 (= ADR-0056 §決定 3-a literal 継承)**: 「完全 byte-identical」 ではなく、 **意図した v2 差分 (= 例 = dispatch 順序 / 並設 routine 由来の write 順序差) を許容しつつ、 実音として等価な register state へ収束する」 こと。 意図しない差分 (= 音が変わる write の欠落 / 誤値) は不可。 **byte-identical は acceptable pass case の 1 つに過ぎず、 v2 実装方式差を許容する trace-equivalence が gate 判定基準**。 trace-equivalence の literal 判定基準は実作業 ADR (= ADR-0067+ 候補) の各 verify gate で確定する。
- **既存個別 trace ground truth**: ADR-0049〜0055 各 verify (= mute / fade-out / SSG tone-enable / v2 driver foundation) + ADR-0057〜0059 各 verify (= FM/SSG 実音 / song parse / ADPCM-B/rhythm 実 dispatch) + ADR-0048 ζ-γ/δ 軸 G verify

#### (c) baseline regression gate 統合 verify

- **scope**: 全 verify script suite (= 以下 enumeration) を 1 batch で production binary 1 件に対して通す + ALL PASS 確認
- **既存 verify script 一覧** (= 主な + ADR-0048〜0059 chain 由来):
  - `verify-mute-semantics.sh` 7 gate (= ADR-0049、 mute)
  - `verify-fadeout-semantics.sh` 16 gate (= ADR-0050、 fade-out)
  - `verify-ssg-tone-enable.sh` 15 gate (= ADR-0051、 SSG tone-enable)
  - `verify-axis-b-v2-*` (= ADR-0052〜0055、 v2 driver foundation)
  - `verify-axis-b-fm-ssg-real-sound.sh` 6 gate (= ADR-0057 γ、 roadmap ①)
  - `verify-axis-b-v2-song-playback.sh` 10 gate (= ADR-0058 ε、 roadmap ②)
  - `verify-axis-b-v2-roadmap3-dispatch.sh` 12 gate (= ADR-0059 ε、 roadmap ③ primary 7 + supplemental 5)
  - `verify-axis-g-*.sh` 15 gate (= ADR-0048 ζ-γ/δ-1、 軸 G dynamic supply)
- **既存個別 ALL PASS ground truth**: 各 sprint chain ε で completion proof line literal 出力 + Codex implementation review approve 経由 + ADR Accepted (= ADR-0048〜0059 全 Accepted)

#### (d) 越川氏 audition gate = scope-out

(d) audition は **roadmap ⑥ ADR-0065 候補で別 sprint** = 本 ADR-0064 では scope-out。 (a)(b)(c) gate 完全達成 = engineering pass 完了 + (d) audition = aesthetic pass = 別軸 (= memory `feedback_metric_pass_is_not_aesthetic_pass.md` literal + ADR-0056 §決定 3-b 越川氏 audition 必須 literal 継承)。

### 決定 2: ADR-0064 = plan ADR + 実作業は別 ADR (= ADR-0067+ 候補)

ADR-0061 → ADR-0062 plan / 実作業分離 pattern を継承:

- **ADR-0064 = plan ADR** = doc-only sprint、 sub-sprint 構成 plan + scope literal + 完了判定 plan のみ
- **実作業 ADR (= ADR-0067+ 候補)** = 実 verify 実行 + sub-sprint chain α/β/γ/δ/ε + trace capture + ALL PASS 確認、 driver / verify script の追加 / 修正の余地あり

= **ADR-0064 Accepted ≠ roadmap ⑤ 統合 verify 完了** (= plan 整理完了 milestone のみ、 実作業は別 ADR Accepted で完了)。

### 決定 3: 統合 verify sub-sprint 構成 plan (= 実作業 ADR で確定、 plan ADR では提案 literal のみ)

候補 sub-sprint 構成 plan:

| sub-sprint | scope plan | 関連 gate | 完了判定 plan |
|---|---|---|---|
| α | (a) 実 MML 再生 統合 verify = v2 driver 経路 + cmd 0x05 経路 並走 trace capture | (a) | 全 ch + 全機能の trace 統合取得 + literal report |
| β | (b) 全 16 ch trace-equivalence verify = FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6 同時 register write 比較 | (b) | 全 ch trace-equivalence 確認 + 意図しない差分なし literal 確認 |
| γ | (c) 全 verify script 統合 ALL PASS = production binary 1 件に対して全 verify を 1 batch 実行 | (c) | 全 verify script ALL PASS literal 確認 + completion proof 統合 report |
| δ | 統合 report 作成 + 残課題 enumeration | - | 統合 report literal + 残課題 (= 次 sprint 起票判断 material) literal |
| ε | Accepted 移行 doc-only | - | Accepted 移行完了 milestone |

= 5 sub-sprint pattern (= ADR-0048 ζ chain 同 pattern、 ADR-0045 軸 B sprint chain α/β/γ/δ/ε pattern 継承)。 ただし sub-sprint の合分 / 追加 / 削除 / 順序変更は実作業 ADR 起票時に最終確定 = 本 ADR-0064 plan は **提案 literal のみ**、 実作業 ADR で前提変更可能。

### 決定 4: doc-only sprint 維持

ADR-0064 起票 doc-only sprint = driver / verify script / vendor / fixture / build flag **完全不変**。 ADR-0064 は plan ADR で実装 ADR ではない (= ADR-0056 / ADR-0060 / ADR-0061 / ADR-0063 同形式)。 後続実作業 ADR (= ADR-0067+ 候補) で実 verify 実行 + 実 trace capture + 必要に応じて verify script 追加 / 修正。

### 決定 5: 不可触対象 literal 明示列挙

- **driver source** = `src/driver/standalone_test.s` 等 全完全不変
- **verify script** = `src/test-fixtures/axis-b/verify-axis-b-*.sh` / `src/test-fixtures/axis-g/verify-axis-g-*.sh` / `verify-mute-semantics.sh` / `verify-fadeout-semantics.sh` / `verify-ssg-tone-enable.sh` 等 全完全不変
- **vendor/** = vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain、 vendor 本体完全不変
- **fixture** = `pmdneo_v2_song_fixture_*` 等 全完全不変
- **build flag** = `TEST_MODE_AXIS_G_V2_PPC` / `TEST_MODE_AXIS_G_AUDITION_*` / `TEST_MODE_V2_SONG_FIXTURE` 等 既存 flag 完全不変
- **ADR-0048 Accepted + Annex 全** = ζ-ε で Accepted 移行完了
- **ADR-0049〜0063 全 routine body + 本文** = 全 Accepted ADR 本文不変
- **既存 routine + cmd 0x05 path + `pmdneo_song_main` + irq_handler_body** = driver active code 完全不変

### 決定 6: 表記制約 5 件 literal 継承 + 「本番 cmd 切替完了」 別 track + ADR-0064 時点不可

ADR-0048 ζ-ε + ADR-0061 §決定 6 + ADR-0062 §決定 7 + ADR-0063 §決定 6 同 literal 継承:

| 表現 | ADR-0064 時点 | 解禁条件 |
|---|---|---|
| 「軸 G dynamic supply 完成」 (日本語版) | **使用可** | ADR-0048 ζ-ε Accepted 後使用可 (= 継承) |
| `axis-G dynamic supply complete` (英語版) | **使用可** | 同上 (= 日英両版同時解禁、 継承) |
| 「軸 G 完成」 | **literal 禁止維持** | dynamic supply 単独実装より広い範囲、 軸 G 全体完成は別 axis 完了後 future |
| 「軸 B 完成」 | **literal 禁止維持** | v2 driver production-ready 化 + `cmd 0x05 + pmdneo_song_main` → v2 driver 経路 switch は ADR-0045 §I-5-b future |
| 「production-ready 全体達成」 | **literal 禁止維持** | ADR-0056 §決定 3 4 系統全通過 + 越川氏 audition approve + 本番 cmd 切替後 future、 **ADR-0064 Accepted ≠ production-ready 全体達成 (= plan ADR Accepted = sub-sprint 構成 plan 確定 milestone のみ)** |
| 「本番 cmd 切替完了」 | **§禁止表現リスト枠ではなく別 track で user 判断する表現** | ADR-0061 §決定 3 (3) sprint 完了後のみ使用可、 **ADR-0064 時点では不可** |

### 決定 7: 後続 sprint chain 独立性 + 番号 chronology rationale (= Codex layer 2 latent-risk 反映)

ADR-0064 plan ADR の後続:

- **実作業 ADR (= ADR-0067+ 候補)** = sub-sprint α/β/γ/δ/ε 実装 ADR、 別 PR / 別 sprint chain (= ADR-0061 → ADR-0062 plan / 実作業分離 pattern と整合)
- **roadmap ⑥ audition ADR-0065 候補** = (d) gate、 別 ADR、 ADR-0064 と並走可能 (= aesthetic 軸独立)
- **roadmap ⑦ 本番 cmd 切替判断 ADR-0066 候補** = 4 gate 全達成後 future (= (3) sprint、 ADR-0061 §決定 3 (3) literal 後続)

#### 番号 chronology rationale (= 後続 ADR 番号予約順序の根拠)

ADR 番号予約順序 = **ADR-0064 plan ADR → ADR-0065 audition ADR (= roadmap ⑥) → ADR-0066 本番 cmd 切替 ADR (= roadmap ⑦) → ADR-0067+ 実作業 ADR (= ADR-0064 実作業 sub-sprint chain)**。

これは **plan ADR と実作業 ADR の分離 pattern (= ADR-0061 → ADR-0062 由来)** + **roadmap ⑤/⑥/⑦ 番号予約 = 整理上 ADR-0064/0065/0066 連番** + **実作業 ADR は roadmap 番号予約後の連続番号 (= ADR-0067+)** という整理に由来。 番号の chronological gap (= ADR-0064 plan vs ADR-0067+ 実作業の間に ADR-0065/0066 が roadmap ⑥/⑦ として割り込む) は **plan / 実作業分離 pattern の literal 結果** であり、 後の混乱回避のため本 ADR-0064 §決定 7 で literal 明示する。

実作業 ADR が ADR-0065/0066 番号を予約しないのは:

1. **ADR-0064 が plan ADR である** = 実作業 ADR は別番号 (= ADR-0067+) が plan / 実作業分離 pattern と整合
2. **roadmap ⑥/⑦ 番号予約は ADR-0063 §決定 3 literal で既定** = ADR-0065 = roadmap ⑥ / ADR-0066 = roadmap ⑦ で番号予約済
3. **ADR-0067+ 実作業 ADR の起票順序** = user 明示 GO 後に確定 (= 実作業 ADR の sub-sprint 単位起票 or 一括起票は実作業 ADR plan で決定)

### 決定 8: (d) audition sprint = scope-out + 本番 cmd 切替判断 sprint = scope-out

- **(d) audition gate** = roadmap ⑥ ADR-0065 候補 = 本 ADR-0064 では着手しない、 user 明示 GO 後の別 ADR
- **(3) 本番 cmd 切替判断 sprint** = roadmap ⑦ ADR-0066 候補 = (2) 完了 + (d) gate 全達成後 future、 user 明示 GO 必須 (= ADR-0045 §I-5-b future literal、 main agent autonomous で進めない)

### 決定 9: production build byte-identical 維持 + 根拠 literal

ADR-0064 = **doc-only sprint** で driver / verify / vendor / fixture / build flag **完全不変** = production build sha256 = ADR-0063 同 sha256 維持 (= 通算 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 不変)。

**sha256 維持の根拠** = driver / verify / vendor / fixture / build flag 不変 (= doc-only sprint で driver build artifacts 変化なし)。

**実際の変更範囲**:
- **(a) repo 内** = `docs/adr/0064-pmdneo-roadmap-5-integration-verify-plan.md` 新規 + `docs/parallel-axes-dashboard.md` 限定 update (= ADR 番号予約簿 0064 行 1 件追加 + escalation 履歴 ADR-0064 entry 1 件追加)
- **(b) repo 外** = Claude Code Agent SDK auto memory dir で memory file 新規 + MEMORY.md index 1 行追加 = PR diff には現れない、 commit 対象外

sha256 再計算は doc-only sprint で driver build 走らないため不可、 **diff 範囲 verify + flag 不変 verify を primary gate** とする。

### 決定 10: 変更範囲 limited verify

**ADR-0049〜0063 本文 + dashboard 既存 0049-0063 行 + 既存 escalation 履歴 entry 完全不変** = 履歴改変 risk 回避。 repo 内 PR diff = **2 file 限定差分** (= ADR-0064 新規 + dashboard 限定 update)。 repo 外 memory file = PR diff には現れない、 commit 対象外。

## verify gate (= doc-only sprint、 spec consistency check)

- ADR-0064 新規 file 起票 + ADR-0063 §決定 3 roadmap ⑤ literal 後続
- driver / verify script / vendor / fixture / build flag 完全不変
- (a)(b)(c) gate 統合 verify scope literal + (d) audition scope-out literal 完了
- sub-sprint α/β/γ/δ/ε 5 段 plan literal 完了 (= 実作業 ADR で確定、 plan ADR では提案のみ)
- ADR-0056 §決定 3-a trace-equivalence literal 継承 (= Codex layer 2 nice-to-have 反映)
- 番号 chronology rationale literal 完了 (= Codex layer 2 latent-risk 反映、 §決定 7 で literal)
- m1 binary byte-identical 維持期待 (= 通算 sha256 `b15883fe...` 不変)
- ADR-0048 Accepted + Annex 全 + ADR-0049〜0063 routine body + 本文 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain
- 「達成宣言」 wording 排除確認 (= 「plan 整理」 「sub-sprint 構成 plan」 wording 厳格遵守)
- repo 内 diff = 2 file 限定
- repo 外 memory file = PR diff に現れない、 commit 対象外

## Codex layer 2 plan review chain (= 1 round chain、 approve)

| round | judgment | must-fix / nice-to-have / latent-risk | agentId |
|---|---|---|---|
| round 1 | **approve** | must-fix 0 件 + nice-to-have 1 件 (= 決定 1(b) wording で「literal-equivalent」 を ADR-0056 §決定 3-a trace-equivalence と明示) + latent-risk 1 件 (= 番号 chronology rationale を ADR 本文に literal 明示)、 越権操作なし + 冒頭 3 件 literal 強調遵守 confirmed | `a0cfca4f4e46e08d8` |

冒頭 3 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 は review のみ
- commit / branch / PR merge / file 変更 / GitHub write は禁止
- merge は main agent 経路のみ

= Codex round 1 で 3 件 literal 遵守 confirmed = approve + nice-to-have / latent-risk 各 1 件 return + 越権操作なし。 main agent (= 主軸 Claude Code) で nice-to-have 1 件 (= §決定 1(b) wording) + latent-risk 1 件 (= §決定 7 番号 chronology rationale) を反映済。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

### やりたいこと

ADR-0063 §決定 3 literal 後続 = roadmap ⑤ 統合 verify sprint plan を doc-only で起票。 ADR-0056 §決定 3 4 gate のうち (a)(b)(c) 3 gate を統合 verify 対象として scope + sub-sprint 構成 plan + 番号予約整理を literal 確定。 **plan ADR、 実作業は別 ADR (= ADR-0067+ 候補)**。

### 前提

- ADR-0063 Accepted (= PR #126、 4 gate status 確認 sprint 完了) + §決定 3 roadmap ⑤ literal 後続
- ADR-0061 → ADR-0062 plan / 実作業分離 pattern 継承
- ADR-0056 §決定 3 4 gate ground truth + §決定 3-a trace-equivalence 定義
- user 明示 GO「次 sprint は roadmap ⑤ 統合 verify = ADR-0064」 + 「Codex layer 2 review-only 3 件 literal 強化」 経路
- Codex layer 2 plan review 1 round approve (= must-fix なし + nice-to-have 1 反映 + latent-risk 1 反映 + 越権操作なし)

### やったこと

- ADR-0064 起票 doc-only sprint (= ADR-0056 / ADR-0060 / ADR-0061 / ADR-0063 同形式、 単一 doc-only PR)
- roadmap ⑤ 統合 verify sprint scope = (a)(b)(c) gate 統合 verify literal (= (d) audition は roadmap ⑥ scope-out)
- ADR-0064 = plan ADR + 実作業は別 ADR (= ADR-0067+ 候補) literal
- 統合 verify sub-sprint α/β/γ/δ/ε 5 段 plan literal (= 実作業 ADR で確定、 plan ADR では提案のみ)
- doc-only sprint 維持 + 不可触対象 literal + 表記制約 5 件継承 + 「本番 cmd 切替完了」 別 track + ADR-0064 時点不可
- (d) audition + (3) 本番 cmd 切替判断 = scope-out (= roadmap ⑥/⑦ future)
- 番号 chronology rationale literal (= ADR-0065/0066 = roadmap ⑥/⑦ 予約 + ADR-0067+ = ADR-0064 実作業、 plan / 実作業分離 pattern 由来、 Codex layer 2 latent-risk 反映)
- (b) gate wording に ADR-0056 §決定 3-a trace-equivalence 明示 (= byte-identical は acceptable pass case の 1 つ、 意図した v2 diff 許容、 Codex layer 2 nice-to-have 反映)
- production build byte-identical 維持 + 変更範囲 limited verify (= repo 内 2 file 限定 + repo 外 memory 非 commit)
- dashboard 2 箇所 update + memory entry 起票

### 結果

- ADR-0064 Accepted = roadmap ⑤ 統合 verify sprint plan 整理完了 milestone
- (a)(b)(c) gate 統合 verify scope literal + (d) scope-out literal 確定
- sub-sprint α/β/γ/δ/ε 5 段 plan literal 確定 (= 実作業 ADR で前提変更可能)
- 番号予約整理 literal (= ADR-0064 plan / ADR-0065 roadmap ⑥ / ADR-0066 roadmap ⑦ / ADR-0067+ 実作業)
- production build byte-identical 維持 (= 通算 sha256 `b15883fe...`)
- ADR-0049〜0063 本文 + dashboard 既存 0049-0063 行 完全不変
- 「達成宣言」 wording 排除 + 「plan 整理」 「sub-sprint 構成 plan」 wording 厳格遵守

### 解釈

ADR-0064 Accepted ≠ roadmap ⑤ 統合 verify 完了 ≠ production-ready 全体達成 ≠ 軸 G 完成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。 ADR-0064 = plan ADR で sub-sprint 構成 plan + scope literal + 番号予約整理を確定するだけ、 実作業は別 ADR (= ADR-0067+ 候補) で進める。 (b) gate trace-equivalence は ADR-0056 §決定 3-a literal 継承 = byte-identical は acceptable pass case の 1 つ、 意図した v2 diff 許容。

### 次

PR 作成 + Codex layer 2 implementation review + **main agent 経路で PR merge** (= Codex 越権 merge 禁止規律遵守) + user 完走報告。 user 明示 GO 後 ADR-0067+ 実作業 ADR 起票判断 (= 別 ADR / 別 sprint) or roadmap ⑥ audition ADR-0065 候補 並走起票判断。

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0064 新規起票 + 即時 Accepted (= ADR-0063 §決定 3 roadmap ⑤ literal 後続、 (a)(b)(c) gate 統合 verify plan + sub-sprint α/β/γ/δ/ε plan + 番号予約整理 literal、 Codex layer 2 plan review 1 round approve + nice-to-have / latent-risk 各 1 件反映、 main agent autonomous) | (= 本 commit) |
