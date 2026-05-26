# ADR-0069: PMDNEO 軸 B v2 driver A-J candidate distinctness 拡張 ADR (= ADR-0065 β halt 解消の driver 拡張 sprint、 K bitmap pair distinct は ADR-0070 candidate future へ分割)

- 状態: **Draft** (= 2026-05-25 40th session、 起票 doc-only PR1、 base anchor `wip-pmddotnet-opnb-extension@b215e7c`)
- 関連 ADR: ADR-0058/0059 (= v2 driver base) + ADR-0067 (= 16 ch fixture 拡張 Accepted、 K+L-Q precedent) + ADR-0068 (= 16 ch integration verify Accepted、 §決定 1 driver ground truth literal) + ADR-0065 (= roadmap ⑥ audition Draft + α 完了 + retrospective approve + β halt、 §決定 9 + Annex β-3 ADR-0069 先行 dependency 順序固定)

## historical split note (= 2026-05-25 40th session、 ADR-0069 起票時点、 5 sub-agent 並列 investigation + user 採用 option A2)

既存 ADR-0065 + ADR-0068 では本 ADR 候補を「**ADR-0069 = A-J candidate distinctness + K bitmap pair distinct**」 と記録していた:

- ADR-0065 §決定 9 + Annex β-3 literal = 「ADR-0069 = driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct」
- ADR-0068 §決定 1 / §決定 9 + Annex β-5 / δ-3-3 / ε-4 literal = 「ADR-0069 候補 future = A-J + K」

ADR-0069 起票時点で **2 ADR に分割確定**:

- **ADR-0069 = A-J candidate distinctness のみ** (= 本 ADR)
- **ADR-0070 (= candidate future) = K bitmap pair distinct** (= ADR-0069 γ Accepted 後 user 明示 GO 必須)

分割根拠 (= 5 sub-agent finding 統合):

- A-J 拡張 = **guarded change additive** (= K+L-Q precedent 継承、 既存 routine 不変、 production sha256 維持可能、 実装難度非常に低い)
- K bitmap pair distinct = `pmdneo_rhythm_event_trigger` body 修正必須 (= ADR-0026 §決定 3/4 = L ch 固定占有 scaffold 再設計要求、 driver dispatch 思想変更、 既存 routine body 変更 risk、 sha256 確実に変わる)
- risk profile が異質 = scope creep 回避 + ADR-0065 β 再開条件 (= 「実 MML 聴いて aesthetic judgment」 前提成立) を A-J 完走で達成可能

ADR-0065 / ADR-0068 内 「ADR-0069 = A-J + K」 wording は本 ADR-0069 起票後 historical context (= 起票時点 plan literal record) として保存、 本 ADR-0069 + 後続 ADR-0070 が新 ground truth。

## 決定 1: ADR-0069 = A-J candidate distinctness 拡張専用 ADR (= ADR-0068 §決定 9 候補消化、 K は ADR-0070 future)

ADR-0069 scope = **A-J (= FM 6 + SSG 3 + ADPCM-B = 10 part) candidate distinctness 拡張専用**。 ADR-0067 fixture 拡張 pattern + K+L-Q `pmdneo_mn_direct_load_*` precedent 継承で driver source 拡張。 K bitmap pair distinct は scope-out (= ADR-0070 candidate future、 user 明示 GO 必須)。

ADR-0068 §決定 1 driver ground truth literal:
- 「(A) production default では candidate MML 関与なし」
- 「(C-2) PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ、 **A-J は全 build mode default 固定** (= driver line 1741-1804 `load_song_part_addr` 固定)」

ADR-0069 が解消する制約 = この「A-J default 固定」 を guarded change で「(C-2) PMDDOTNET_MML 経路で A-J も MML 由来 candidate dispatch 可能」 へ拡張。 (A) production default では既存 byte-identical 維持 (= sha256 `b15883fe...` 不変)。

## 決定 2: sub-sprint chain plan = 4 PR (= PR1 起票 doc-only + α/β/γ 3 sub-sprint)

| PR | scope | user 介入 | 完了判定 |
|---|---|---|---|
| **PR1 (= 起票 doc-only、 本 PR)** | ADR-0069 file 新規 (= historical split note 含む) + dashboard + memory + 12 決定 + Annex skeleton | optional | Draft 起票 + Codex plan/impl review approve |
| **PR2 = α impl** | driver A-J guarded change (= line 1741-1804) + 新規 routine `pmdneo_mn_direct_load_aj_part_addr` additive (= line 5810-5821 周辺) | optional | **α 完了 (= 本 PR2)** = A-J impl 完了 + build 計 4 件 + 3 段 verify gate ALL PASS literal record (= 7a production default sha256 `b15883fe...` MATCH + 7b PMDDOTNET=1 ym2610b/ym2610 build PASS + .lst predicate 4 件 confirm + 7c production rebuild two-way sha256 一致 MATCH = production sha256 byte-identical 維持確定、 Annex α fill 6 sub-section literal record、 Codex layer 2 plan review 7 round chain approve = round 1-6 revise + round 7 approve plan v7) |
| **PR3 = β verify** | A-J candidate distinctness verify script 新規 (= `verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh`) + 新規 fixture MML (= `aj-distinctness-fixture.mml`、 user Option A 採用) + chip target matrix build trace + distinct pattern 確認 + Annex β fill | optional | **β 完了 (= 本 PR3)** = A-J verify script 新規 + 新規 fixture MML (= aj-distinctness-fixture.mml、 A-J 10 part 全 active + per-part distinct note) + chip target matrix build trace verify ALL PASS literal record (= Annex β fill 6 sub-section literal record、 16 gate ALL PASS = gate-0 preflight + gate-1 7a sha256 + gate-2 .lst predicate 4 件 + gate-3a/3b/3c FM/SSG/ADPCM-B dynamic + gate-3d per-part distinctness + gate-4 ym2610 caller + gate-5a/5b/5c ym2610 + gate-6/7 v2-only baseline + gate-8 7c sha256 + gate-9/10 driver no-touch、 既存 routine body + 既存 verify script + 既存 build flag + vendor + ADR-0048 軸 G ε partial state + ADR-0026 §決定 3/4 + ADR-0041〜0068 本文 + Annex 完全不変 confirm、 Codex layer 2 plan review 7 round chain approve plan v7 + impl-review approve) |
| **PR4 = γ Draft → Accepted** | Annex 全統合 + 「A-J candidate distinctness 達成」 milestone wording 解禁 (= scope 限定 + 併記必須) + Draft → Accepted 移行 | optional | Accepted + ADR-0065 β 再開 trigger 発火 |

### PR3 verify chip target matrix literal

| chip target | (B) v2-only build trace | (C-2) PMDDOTNET_MML build trace | 期待 A-J part |
|---|---|---|---|
| **ym2610** | A/D = init skip expected (= 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` guard literal) + B/C/E/F + G/H/I + J = 8 part active | 同 chip skip behavior + MML 由来 candidate dispatch confirmed | A/D 以外 8 part candidate distinctness 確認 |
| **ym2610b (= primary gate)** | A/B/C/D/E/F + G/H/I + J = **10 part 全 active** | A-J 10 part 全 candidate dispatch primary gate | **A-J 10 part 全 candidate distinctness primary gate** |

PR3 verify gate ALL PASS 条件 = ym2610b primary + ym2610 secondary (= A/D skip expected behavior confirm) 両方達成。

## 決定 3: allowed-touch literal (= driver source + verify script 2 sub-section 分離)

### 3a: driver source allowed-touch

- file: `src/driver/standalone_test.s` (= **1 file のみ**)
- scope 1 (= guarded change): **line 1741-1804** = A-J 10 entry の `load_song_part_addr` 経路に `.if PMDNEO_USE_PMDDOTNET == 1 / .else / .endif` 3 段 guarded branch 追加 (= K+L-Q 既存 pattern 完全 symmetric、 既存 1 行 → 約 60 行)
- scope 2 (= additive): **line 5810-5821 周辺** = 新規 routine `pmdneo_mn_direct_load_aj_part_addr` 1 本追加 (= K `pmdneo_mn_direct_load_k_part_addr` index 化 10 倍展開、 約 15-20 行、 `.if PMDNEO_USE_PMDDOTNET == 1` 配下 additive)
- `.else` 分岐 = 既存 `ld a, #0..9 / call load_song_part_addr` byte-identical 保証 (= production default sha256 維持)

### 3b: verify / fixture allowed-touch (= PR3 β scope)

- file: `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh` (= 新規 verify script、 chip target matrix coverage 含み示唆)
- header literal: `# chip target matrix: ym2610b primary gate (= A-J 10 part 全 candidate dispatch) + ym2610 secondary (= A/D skip expected behavior confirm)`
- 既存 verify script (= ADR-0049〜0068 全 verify script) は完全不変

### 3d: 新規 fixture MML 例外的許可 (= β PR3 dynamic proof のため、 2026-05-26 40th session user Option A 採用 literal、 ADR-0041 §決定 5 `design_judgment_needed` escalation 経路で確定)

β PR3 plan v3 round 3 で「SAMPLE2-baseline.mml は A/B/C/I のみ active = A-J 10 part 全 candidate dispatch dynamic proof 不可」 finding 発覚 + 既存 vendor MML 累積で H/J 不在判明 = fixture limitation 問題。 main agent escalation = ADR-0041 §決定 5 `design_judgment_needed` 経路 + 4 option 提示 + user 採用 Option A = 新規 fixture MML 追加 + vendor 不可触維持。

- file: `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` (= 新規 fixture MML、 PMDDotNETConsole format CRLF、 A-J 10 part 全 active + per-part distinct note = c4/d4/e4/f4/g4/a4 for FM A-F + c4/d4/e4 for SSG G-I + c4 for ADPCM-B J)
- 用途: β PR3 dynamic proof (= chip target matrix verify、 FM A-F keyon + SSG G-I voice + ADPCM-B J keyon + per-part distinct register value proof)
- 範囲限定: β PR3 限定例外、 ADR-0070 候補 future 拡張時別途判断 (= K bitmap pair distinct scope-out 維持)
- vendor / driver routine / K path 完全不変 = Option A literal 整合

### 既存 routine body 完全不変 (= driver source 内)

- `load_song_part_addr` (= line 3390-3425)
- `pmdneo_mn_direct_load_k_part_addr` (= line 5812-5820)
- `pmdneo_mn_direct_load_lq_part_addr` (= line 5705-5781)
- `pmdneo5_init_part`
- `pmdneo_rhythm_event_trigger` (= line 5282-5344、 K dispatch 完全不可触)

### 明示的 scope-out

- `song_data.inc` (= vendor、 完全不変)
- K bitmap pair distinct (= ADR-0070 candidate future)
- `pmdneo_rhythm_event_trigger` body 修正 (= ADR-0070 候補)
- ADR-0026 §決定 3/4 再設計 (= K dispatch L ch 固定占有方式の変更、 ADR-0070 候補)
- production default sha256 変更
- 新 baseline 設定 (= ADR-0069 scope 外、 ADR-0070 で別途)
- **`wip-dashboard-coverage` branch (= user 別作業)** = 完全 untouched
- **`docs/dashboard/` untracked directory (= user 別作業 file)** = PR diff に含めない

## 決定 4: production sha256 維持 mandatory

- 通算 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory (= ADR-0058〜0068 carry)
- guarded change `.if PMDNEO_USE_PMDDOTNET == 1` 配下に限定 = production default (= flag off) sha256 byte-identical 保証
- 既存 K+L-Q precedent (= ADR-0067/0068 通算 sha256 維持実証済) 継承
- sha256 mismatch = rollback / revise trigger (= §決定 5 condition #1 literal)
- 新 baseline 設定は ADR-0069 scope 外 (= ADR-0070 K 拡張で必要なら別途 user 判断)

## 決定 5: rollback 条件 literal (= 11 unique rollback condition table (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で 12 row) + 4 段 stop action + 3 段 responsibility + destructive git 禁止、 β PR3 plan v7 round 6 wording 修正反映)

### stop action 4 段 定義 (= ADR-0041 §決定 4-3 line 227 literal「修正 commit = 軸 chain 連鎖 commit (= rollback ではない)」 整合)

- **(α) 連鎖 commit fix-up**: rollback ではない、 軸 chain の連鎖 commit (= retrospective Codex revise / Codex round 内 must-fix / build failure 修正 等の軽微 fix)
- **(β) sub-sprint halt**: 当該 sub-sprint PR halt + halt record commit doc-only + 後続 sub-sprint dependency 順序固定 (= ADR-0065 β PR3 halt precedent literal 同形)
- **(γ) ADR-0069 全体 halt + Draft 維持**: ADR-0069 全体 halt + 後続 ADR (= ADR-0065 β/δ / ADR-0066 / ADR-0070) dependency 順序固定 update
- **(δ) 新 ADR 化 (= scope 分割)**: ADR-0069 scope 分割 + 新 ADR-00NN 起票 + ADR-0069 scope 縮小 update (= ADR-0067 round 4 precedent)

### responsibility 3 段 定義 (= ADR-0041 §決定 5 介入手順整合)

- **(I) 主軸自律**: main agent autonomous (= sub-agent 評価 / 連鎖 commit / 規律解釈 / Codex orchestration)
- **(II) Codex layer 2**: main agent ↔ Codex 統合判断 + plan/impl review approve/revise loop
- **(III) user escalation**: ADR-0041 §決定 5 6 種 + 設計判断複数案 + scope 変更 + 全体 halt 判断

### 11 unique rollback condition table (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で 12 row、 β PR3 plan v7 round 6 wording 修正反映)

| # | condition | 検知 method | threshold | stop action | responsibility | 後続処理 |
|---|---|---|---|---|---|---|
| 1 | production sha256 mismatch | `bash scripts/build-poc.sh --chip ym2610` 後 m1.bin sha256 != `b15883fe...` | 1 byte 違い即発火 | (α) 1 retry → (β) sub-sprint halt | (I) → (III) `discipline_violation_risk` | git revert + sha256 再 confirm + ADR doc rollback record |
| 2 | build failure | sdasz80 / sdldz80 exit≠0 / error keyword | 1 retry 後再発 | (α) → (β) | (I) → (II) → (III) if Codex 3 round 超過 | 修正 commit (= ADR-0041 §決定 4-3 line 227 literal) |
| 3 | 既存 verify regression | ADR-0067/0068 verify script いずれか FAIL | 1 script でも FAIL 即発火 | (β) + revert | (I) → (III) | git revert + verify 全 re-run |
| 4 | .org section overflow | `.lst` でアドレス範囲超過 (= memory `feedback_org_section_overflow_silent_bug.md` literal) | 1 byte 超過即発火 | (α) 配置 section 変更 | (I) + (II) | 修正 commit + .lst 再 verify |
| 5 | driver diff 肥大化 / 既存 routine 破壊 | `git diff src/driver/standalone_test.s` で既存 `pmdneo_*` routine body line change 検出 | 既存 routine body 1 line change 即発火 | (β) → (γ) 検討 | (I) → (III) `discipline_violation_risk` | git revert + allowed-touch 再確認 |
| 6 | hidden state 破壊 | 軸 G ε partial state (= 0xFD32-0xFD38) / pmdneo_v2_song_state 等 touch 検出 | 1 line change 即発火 | (β) | (I) → (III) | git revert + 不可触 literal 再確認 |
| 7 | scope-out 違反 | ADR-0065 / ADR-0066 / ADR-0070 領域 touch 検出 + `wip-dashboard-coverage` / `docs/dashboard/` 混入 | 1 件検出即発火 | (β) or (δ) 新 ADR 化 | (I) → (III) | git revert + scope literal 再確認 |
| 8a | **MAME trace failure** (= 異常 exit) | MAME `-wavwrite` exit code ≠ 0 / TSV file size 0 / build path で発見 | 1 retry 後再発 | (α) → (β) | (I) → (III) `unexpected_finding` | kill + 1 retry + re-run |
| 8b | **MAME trace hang** (= CPU 時間停止) | 10 分 CPU 時間停止 (= memory `feedback_long_running_verify_polling_hang_detection.md` literal) / polling monitor で発見 | 10 分 hang | (α) kill + 1 retry → (β) | (I) → (III) `unexpected_finding` | process kill + retry |
| 9 | Codex layer 2 review 3 round 超過 unresolved | round 3 後も approve 出ず | round 3 + 同 must-fix 1 回繰り返し | (β) or (γ) | (II) → (III) `codex_unresolved` or `design_judgment_needed` | ADR-0065 β PR3 halt precedent 適用 |
| 10 | audition material 不成立 (= design 失敗) | trace で A-J part candidate dispatch 出ない | ε 段直前で確定 | (γ) ADR-0069 全体 halt + Draft 維持 | (III) `design_judgment_needed` | git revert 全 sub-sprint + ADR-0065 dependency update |
| 11 | Codex companion 一時障害 | `claude-opus-4-7[1m] is temporarily unavailable` error 2 回連続 | 2 回連続 | **rollback 起動せず**、 ADR-0041 §決定 4-3 fallback + retrospective Codex review 必須 | (I) fallback approve + (II) retrospective | 連鎖 commit fix-up (= rollback ではない) |

### 共通原則

- 軽微 fix-up (= condition #2 / #4 / #8a / #8b) = 連鎖 commit fix-up (= rollback ではない)
- sub-sprint 単位 halt (= condition #1 / #3 / #5 / #6 / #7 / #9) = ADR-0065 β PR3 halt precedent literal 同形
- ADR-0069 全体 halt (= condition #10) = Draft 維持 + 全 sub-sprint rollback record + 後続 ADR dependency update
- **destructive git 操作禁止** = `git reset --hard` / `git push --force` / `git checkout --` 等は user 明示なし禁止、 `git revert` のみ採用

## 決定 6: 表記制約

### 起票時点 禁止 wording

- 「A-J candidate distinctness 達成」 = γ Accepted 後解禁候補
- 「16ch full candidate distinctness 完了」 = **ADR-0069 では永久禁止** (= K 拡張 ADR-0070 完走条件)
- 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 = ADR-0065 δ scope future
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = 各 user 判断軸 future

### γ Accepted 後解禁候補 (= scope 限定 + 併記必須)

- 「**A-J candidate distinctness 達成**」 解禁
- 併記必須:
  - 「K bitmap pair distinct 未達成 = ADR-0070 candidate future」
  - 「16ch full candidate distinctness 完了 ではない」
  - 「ADR-0065 β/δ 再開 ready」
  - 「production-ready 全体達成 ではない」

### 禁止維持 (= γ Accepted 後も継続)

- 「16ch full candidate distinctness 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」

## 決定 7: 不可触対象 literal

### 完全不変

- ADR-0041〜0068 本文 + Annex
- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0058 / ADR-0059 軸 B v2 driver state
- vendor (= `song_data.inc` 含む)
- 既存 verify script (= ADR-0049〜0068 全 verify script)
- 既存 build flag (= ADR-0067 fixture flag 含む)
- ADR-0026 §決定 3/4 (= K dispatch L ch 固定占有方式)
- driver 内 既存 routine body (= §決定 3 enumeration 通り)
- `pmdneo_rhythm_event_trigger` body
- ADR-0065 § 決定 1 + 3-8 + 10-12 + §verify gate + Annex α (= final) + Annex β (= halt record final) + Annex skeleton 他 sub-section
- **`wip-dashboard-coverage` branch (= user 別作業)** = ADR-0069 完全 untouched + scope-out
- **`docs/dashboard/` untracked directory (= user 別作業 file)** = ADR-0069 PR diff に含めない + scope-out

### allowed-touch (= §決定 3 例外)

- driver source: `src/driver/standalone_test.s` line 1741-1804 + 5810-5821 周辺
- verify script: `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh` (= 新規、 PR3 β scope)

## 決定 8: PR chain plan = 4 PR (= PR1 起票 doc-only + PR2-PR4 sub-sprint α/β/γ)

ADR-0067/0068 5 段 chain pattern から K 拡張 scope-out で 4 段 chain (= ε 統合 sub-sprint を γ に統合)。 各 PR で `git status` + `git diff --name-only` で `wip-dashboard-coverage` + `docs/dashboard/` 混入なし確認必須。

## 決定 9: ADR-0066 / ADR-0070 候補 起票判断 dependency literal

- **ADR-0066 候補** = roadmap ⑦ 本番 cmd 切替判断 ADR (= ADR-0065 ε Accepted 後 future、 順序固定 dependency)
- **ADR-0070 候補** = K bitmap pair distinct ADR (= **ADR-0069 γ Accepted 後 future**、 user 明示 GO 必須、 ADR-0069 と独立 driver dispatch 設計変更系)
- 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)

## 決定 10: ADR-0065 β/δ 再開条件

- ADR-0069 γ Accepted = A-J candidate distinctness 達成 = 「実 MML を聴いて aesthetic judgment」 前提成立 → **ADR-0065 β PR3 再起票可能化**
- ADR-0065 β/δ 再開時 plan v3 新規 draft (= ADR-0069 完走後 driver state 反映、 PMDDotNET MML A-J part audition 可能化)
- K rhythm pattern aesthetic 評価は ADR-0070 完走待ち

### δ 根拠補足

- ADR-0069 直接 trigger は **ADR-0065 β PR3 halt** (= 40th session、 user option 3 採用、 β 再開条件成立)
- ADR-0065 δ (= audition session 実施) は β 完走後の連続 sub-sprint chain (= ADR-0065 §決定 2 α/β/γ/δ/ε literal) として natural 移行
- ADR-0069 γ Accepted で β 再開 → β/γ 完走後 δ audition session 実施 = scope 広がりではなく ADR-0065 既定 chain 通り運用

### K bitmap pair distinct 完了扱いしない併記

- **ADR-0065 δ audition session では K bitmap pair distinct は完了扱いしない** (= ADR-0070 完走待ち)
- acceptance framework 3 軸独立 schema 経由 partial accept 判定可能
- 「K rhythm pattern aesthetic 評価は ADR-0070 完走後別途、 ADR-0065 δ では A-J FM/SSG/ADPCM-B aesthetic 評価のみ」 wording literal

## 決定 11: production sha256 維持運用順序 (= 順序固定 dependency)

- ADR-0069 γ Accepted = production sha256 `b15883fe...` 維持 confirmed (= guarded change additive のみ)
- ADR-0065 β/δ 再開時 = 同 sha256 binary で audition session (= ADR-0065 §決定 10 + Annex α-1 と整合維持)
- ADR-0070 (= K 拡張) で sha256 変更必要時 = baseline migration policy は ADR-0070 内で別途 user 判断 (= ADR-0069 scope 外)

## 決定 12: Codex layer 2 plan review chain literal (= round 1 revise + round 2 revise + round 3 approve)

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | **revise** | `a49d5432e9efbcd20` | must-fix 3 (= 決定 9 ε→γ + 決定 3 file 限定 vs verify script + 決定 5 stop action/responsibility 定義) + nh 1 (= MAME failure/hang 分離) + lr 1 (= δ trigger 根拠補足) |
| 2 | **revise** | `a681a6f24b52b3186` | must-fix 2 (= PR3 verify chip target matrix literal + ADR-0069 PR1 historical split note) + nh 2 (= PR3 verify script 名 ym2610b coverage + 決定 10 K aesthetic 完了扱いしない) + lr 1 (= branch SHA anchor) |
| 3 | **approve** | `019e5f32-b2f3-7110-b80e-d4baf34d3a9d` (= Codex internal session) | must-fix 0 + nh 0 + lr 0 + 全 7 axis pass |

= 3 round chain で approve、 全 review-only 遵守 confirmed + 越権操作なし。 round 1+2 finding 全反映 (= MF 5 + nh 3 + lr 2 全反映)。

## Annex skeleton (= 各 PR で fill)

### Annex A: 起票時点 scope context (= PR1 で fill)

placeholder。 PR1 commit chain で起票時点 ground truth + 5 sub-agent 統合 + user 4 設計判断 literal record。

### Annex α: A-J implementation literal record (= 本 PR2 で fill)

#### α-1: α PR2 scope literal + 実装内容 summary

ADR-0069 α PR2 = A-J impl driver guarded change + 新規 routine additive 実装。 touch file = `src/driver/standalone_test.s` 1 file のみ、 既存 routine body 完全不変、 K bitmap pair distinct scope-out (= ADR-0070 future)、 production default sha256 `b15883fe...` 維持確定。

実装 2 箇所:
1. **caller guarded change** (= line 1741-1804 周辺): A-J 10 entry の `ld a, #N / call load_song_part_addr` を `.if PMDNEO_USE_PMDDOTNET == 1 / ld a, #N / call pmdneo_mn_direct_load_aj_part_addr / .else / ld a, #N / call load_song_part_addr / .endif` 3 段 wrap (= K/L-Q 既存 pattern 完全 symmetric)。 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` (= A/D init 部のみ囲む) 完全不変維持、 ネスト不要 = 並列配置。
2. **新規 routine additive** (= K routine `ret` 後 + `.endif` 前): `pmdneo_mn_direct_load_aj_part_addr` 1 本追加 (= K helper の index 化 10 倍展開、 input A = aj_idx 0..9、 output HL = part body file addr、 clobber AF/DE/HL、 16 byte / 87 T-cycle)。 sdasz80 syntax = `ld d, #0` + `ld hl, #pmddotnet_song + 1` (= K routine pattern 整合)。

#### α-2: driver impl literal record (= edit diff)

A-J 10 entry caller patch (= aj_idx mapping、 line range は **impl 後の実 line 範囲** literal record):

| aj_idx | part letter | impl 前 line range (= 旧) | impl 後 line range (= 実 = `.if/.else/.endif` 3 段 wrap 拡張後) | active 条件 |
|---|---|---|---|---|
| 0 | A | 1741-1748 | 1744-1756 (= load 部 1744-1750 + 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` 1751-1756) | 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` (= ym2610b のみ init 部 active) 不変 |
| 1 | B | 1749-1754 | 1757-1767 (= load 部 1757-1763 + init 部 1764-1767) | 全 chip active |
| 2 | C | 1755-1760 | 1768-1778 | 全 chip active |
| 3 | D | 1761-1768 | 1779-1791 (= load 部 + 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` 1786-1791) | 既存 `.if PMDNEO_TARGET_CHIP_YM2610B` 不変 |
| 4 | E | 1769-1774 | 1792-1802 | 全 chip active |
| 5 | F | 1775-1780 | 1803-1813 | 全 chip active |
| 6 | G | 1781-1786 | 1814-1824 | 全 chip active |
| 7 | H | 1787-1792 | 1825-1835 | 全 chip active |
| 8 | I | 1793-1798 | 1836-1846 | 全 chip active |
| 9 | J | 1799-1804 | 1847-1857 (= load 部 1847-1853 + init 部 1854-1857) | 全 chip active |

= A-J 10 entry 範囲 (= 実 line) = **1744-1857** (= 旧 1741-1804 範囲 64 行 → 1744-1857 範囲 **114 行** (= inclusive: 1857 - 1744 + 1) + 約 **+50 行** = guarded change 3 段 wrap で 10 entry × 約 +5 行追加)。 K entry (= 旧 line 1805〜) は実 line 1858〜 にシフト。

新規 routine 配置: K routine (= line 5865-5873 `pmdneo_mn_direct_load_k_part_addr::`) の `ret` 後 + `.endif` 前 (= 同 `.if PMDNEO_USE_PMDDOTNET == 1` block 内末尾)。 build .lst 上の address = K routine `0x15E2`、 新規 routine `0x15ED` (= K + 11 byte 後、 連続配置)。

#### α-3: sdasz80 syntax 補正履歴 (= sub-agent F finding 反映)

- `ld d, 0` (= sub-agent A 初期 draft) → `ld d, #0` (= sub-agent F 補正、 sdasz80 即値 `#` 前置 convention、 K routine line 5818 style 整合)
- `ld hl, #(pmddotnet_song + 1)` (= 括弧付き) → `ld hl, #pmddotnet_song + 1` (= sub-agent F 補正、 K routine line 5818/5820 実証済 syntax)

#### α-4: build + sha256 + .lst verify gate ALL PASS literal (= 4 build 3 段 gate 結果)

| gate | build command | sha256 | 結果 |
|---|---|---|---|
| 7a (= build 1/4) | `bash scripts/build-poc.sh --chip ym2610` (= production default) | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` | ✓ MATCH (= 通算 sha256 維持) |
| 7b (= build 2/4) | `PMDDOTNET_MML=<abs path>/SAMPLE2-baseline.mml PMDDOTNET_MODE=N PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip ym2610b` | `1dc136c89891f1ff74278beb252f967a00a6d8f9e24c46c49c4bea95f8f4735a` | ✓ PASS (= 別 sha256、 比較対象外、 record のみ) + .lst predicate 4 件 confirm |
| 7b (= build 3/4) | 同上 + `--chip ym2610` | `4df9b0dd6a0cc05cad81c9e2be4be7468910d1d08584abf33f52df93791e5cb6` | ✓ PASS (= 別 sha256、 比較対象外) |
| 7c (= build 4/4) | `bash scripts/build-poc.sh --chip ym2610` (= production rebuild) | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` | ✓ MATCH (= 7a 記録値一致 + literal 一致、 production sha256 byte-identical 維持確定) |

.lst predicate 4 件 confirm (= 7b ym2610b ground truth):
- (i) 新規 routine symbol `pmdneo_mn_direct_load_aj_part_addr::` が .lst に出現 (= address 0x15ED)
- (ii) A-J PMDDOTNET caller expansion assembled = `call pmdneo_mn_direct_load_aj_part_addr` 10 件 emit (= 10 entry × 1 call each)
- (iii) 新規 routine 配置 area = K routine 後 (= K = 0x15E2 + 新規 = 0x15ED、 同 `.if PMDNEO_USE_PMDDOTNET == 1` block 内、 連続配置)
- (iv) bounded `.org` sections 維持 (= section overflow なし、 memory `feedback_org_section_overflow_silent_bug.md` literal 整合)

#### α-5: 不可触対象 confirm

- 既存 routine body 完全不変 (= line range は **β PR3 retrospective 反映 = α PR2 で A-J caller guarded change +50 行 入った後の実 line range**、 旧 wording = α PR2 doc 当時の推定値): `load_song_part_addr` (= 旧 line 3390-3425 / 実 line 3443-3478) / `pmdneo_mn_direct_load_k_part_addr` (= line 5865-5873、 既存 doc と整合) / `pmdneo_mn_direct_load_lq_part_addr` (= 旧 line 5705-5781 / 実 line 5758-5834) / `pmdneo5_init_part` (= 旧 line 3428~ / 実 line 3481-3549) / `pmdneo_rhythm_event_trigger` (= 旧 line 5282-5344 / 実 line 5372-5397) = `git diff` で touch なし confirmed (= sub-agent J finding 4 反映、 β PR3 retrospective line range fix)
- vendor / song_data.inc / 既存 verify script / 既存 build flag / ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) / ADR-0026 §決定 3/4 / ADR-0041〜0068 本文 + Annex = 全 untouched
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked directory = α PR2 完全 untouched (= `git status` + `git diff --name-only` 混入確認 confirmed)
- 既存 chip target guard 位置完全不変: A/D entry の `.if PMDNEO_TARGET_CHIP_YM2610B` (= init 部のみ囲む) は α PR2 で touch なし、 B/C/E/F/G/H/I/J 8 entry の guard なし状態も完全不変

#### α-6: α PR2 Codex layer 2 plan review chain literal (= 7 round chain approve)

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | revise | `aed0a9bfd475c6cef` | must-fix 2 (= scope contradiction + .lst overflow check 必須化) + lr 1 |
| 2 | revise | `ab5a07bd0e6a75e9c` | must-fix 2 (= PMDDOTNET=1 build mandatory + artifact path 実 repo) + nh 1 + lr 2 |
| 3 | revise | `a212843716dff4e3c` | must-fix 1 (= input register A/D 誤読疑い、 wording 明確化) + nh 1 |
| 4 | revise | `a737127f4d8129584` | must-fix 1 (= file path 参照 wording 明確化) + nh 1 |
| 5 | revise | `a70a648e587c47455` | must-fix 1 (= PMDDOTNET=1 env var 詳細明示) + nh 1 + lr 1 (= 7c rebuild for sha256) |
| 6 | revise | `ab04d4d22c7deb2d9` | must-fix 2 (= PMDDOTNET_MODE 正確説明 + 7c rollback mapping 分離) |
| 7 | **approve plan v7** | TBD | must-fix 0 + nh 0 + lr 0 + 全 7 axis PASS |

= 7 round chain (= ADR-0067 5 round precedent +2 round)、 計 MF 9 件 + nh 5 件 + lr 5 件全反映。 全 review-only + 越権操作なし confirmed + 冒頭 7 件 literal 強調遵守。 round 3/4 = Codex 誤読 (= input register / file path)、 round 1/2/5/6 = valid technical correction (= scope / artifact path / env var / .lst predicate / sha256 mapping)、 設計対立なし。 3 sub-agent F/G/H 並走 investigation 統合 = 並走 sub-agent 投入 default 化規律 2 回目適用。

### Annex β: A-J verify literal record (= 本 PR3 で fill)

#### β-1: β PR3 scope literal + 実装内容 summary

ADR-0069 β PR3 = A-J candidate distinctness verify script 新規 + 新規 fixture MML 追加 (= user Option A 採用) + chip target matrix build trace verify。 driver source `src/driver/standalone_test.s` 完全 untouched (= α PR2 で確立した A-J caller guarded change + 新規 routine `pmdneo_mn_direct_load_aj_part_addr::` 継承使用)、 vendor 完全不変、 K bitmap pair distinct 完全 scope-out (= ADR-0070 future)。

β PR3 で追加された 2 file:
1. `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh` (= 新規 verify script、 約 250 行、 16 gate)
2. `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` (= 新規 fixture MML、 PMDDotNETConsole format CRLF、 A-J 10 part 全 active + per-part distinct note)

#### β-2: 新規 verify script literal record

file: `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh`

16 gate 構成:
- gate-0 = preflight scope-out enforcement (= forbidden path 検出 only = docs/dashboard/ + wip-dashboard-coverage、 LR1 反映)
- gate-1 = 7a production default ym2610 build + sha256 = `b15883fe...` MATCH
- gate-2 = 7b PMDDOTNET ym2610b primary build + .lst predicate 4 件 (= (i) aj routine symbol at 0x15ED + (ii) caller 10 件 + (iii) K_ADDR < AJ_ADDR + (iv) Area Table present)
- gate-3a = 7b primary MAME trace FM A-F keyon ≥ 1 each (= 動的 proof)
- gate-3b = 7b primary SSG G/H/I write ≥ 1 each (= ADR-0068 β `detect_ssg` pattern 流用)
- gate-3c = 7b primary ADPCM-B J write ≥ 1
- gate-3d = per-part distinctness assert (= FM fnum distinct ≥ 4 + SSG tone distinct ≥ 3 + ADPCM-B delta-N distinct ≥ 1)
- gate-4 = 7b PMDDOTNET ym2610 secondary build + caller count 10 共通 confirm
- gate-5a = ym2610 FM B/C/E/F keyon ≥ 1 + **A/D keyon = 0 expected** (= driver guard literal 整合)
- gate-5b/5c = ym2610 SSG G/H/I + ADPCM-B J 共通 active
- gate-6/7 = 7b-V2-ONLY ym2610b/ym2610 build PASS (= ADR-0067 δ baseline carry literal only、 existing script not re-executed)
- gate-8 = 7c production rebuild ym2610 sha256 = `b15883fe...` MATCH (= 7a 一致 + byte-identical 確定)
- gate-9 = existing routine no-touch (= git diff DIFF_BASE_PIN..HEAD 5 既存 routine label 行 change 0 件)
- gate-10 = driver source 完全 untouched (= `git diff src/driver/standalone_test.s` 0 byte)

#### β-3: 新規 fixture MML literal record (= per-part distinct note)

file: `src/test-fixtures/axis-b/aj-distinctness-fixture.mml`

format: PMDDotNETConsole CRLF。 voice 定義 2 件 (@001 alg=0 + @002 alg=7) + A-J 10 part 全 active + per-part distinct note。

| aj_idx | part letter | chip target | MML note |
|---|---|---|---|
| 0 | A | FM 1 | c4 (= MIDI C4) |
| 1 | B | FM 2 | d4 |
| 2 | C | FM 3 | e4 |
| 3 | D | FM 4 | f4 |
| 4 | E | FM 5 | g4 |
| 5 | F | FM 6 | a4 |
| 6 | G | SSG 1 | c4 |
| 7 | H | SSG 2 | d4 |
| 8 | I | SSG 3 | e4 |
| 9 | J | ADPCM-B | c4 |

= 各 part 別 note → 各 part 別 fnum/tone/delta-N value で per-part identity 確立。 K (= rhythm) は fixture に含めず scope-out 維持 (= ADR-0070 future)。

#### β-4: verify script ALL PASS literal record (= 実 execution 結果)

全 16 gate ALL PASS。 execution log summary:

| gate | result | literal value |
|---|---|---|
| gate-0 | OK | scope-out forbidden path 混入なし confirmed |
| gate-1 | OK | 7a sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` MATCH |
| gate-2 (i) | OK | aj routine symbol at 0x0015ED |
| gate-2 (ii) | OK | callers = 10 |
| gate-2 (iii) | OK | K=0x0015E2 < aj=0x0015ED |
| gate-2 (iv) | OK | Area Table present |
| gate-3a | OK | FM A-F keyon ≥ 1 each (= A=5 B=1 C=1 D=1 E=1 F=1) |
| gate-3b | OK | SSG G/H/I ≥ 1 each (= G=4 H=4 I=4) |
| gate-3c | OK | ADPCM-B J ≥ 1 (= count=12) |
| gate-3d | OK | FM fnum distinct=5 + SSG tone distinct=6 + ADPCM-B delta distinct=2 |
| gate-4 | OK | ym2610 callers = 10 (= chip target 共通) |
| gate-5a | OK | A/D skip (= A=0 D=0) + B/C/E/F ≥ 1 each (= B=1 C=1 E=1 F=1) |
| gate-5b | OK | ym2610 SSG G/H/I ≥ 1 each |
| gate-5c | OK | ym2610 ADPCM-B J ≥ 1 (= count=12) |
| gate-6 | OK | v2-only ym2610b build PASS (= ADR-0067 δ 11 slot baseline carry) |
| gate-7 | OK | v2-only ym2610 build PASS (= ADR-0067 δ 8 slot baseline carry) |
| gate-8 | OK | 7c sha256 MATCH (= 7a 一致 + byte-identical 確定) |
| gate-9 | OK | 5 既存 routine label 行 diff 0 件 |
| gate-10 | OK | driver source 完全 untouched (= 0 byte diff) |

= **A-J verify gate ALL PASS + chip target matrix verify 完了 + per-part identity proof confirmed** (= ym2610b 10 part + ym2610 8 part + A/D dynamic skip)。 production sha256 byte-identical 維持確定。

#### β-5: 不可触対象 confirm

- driver source `src/driver/standalone_test.s` = 0 byte touch (= `git diff` 0 行 confirmed、 gate-10 PASS)
- 既存 routine body 完全不変 (= gate-9 5 既存 routine label diff 0 件 confirmed)
- vendor / song_data.inc / 既存 verify script (= ADR-0049〜0068 全 15 script) / 既存 build flag = touch なし
- ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0068 本文 + Annex 完全不変
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked directory = β PR3 完全 untouched (= gate-0 forbidden path 検出 confirmed)

#### β-6: β PR3 Codex layer 2 plan review chain literal + Codex impl-review chain (= 後で fill)

plan review chain = 7 round chain (= ADR-0067 5 round precedent +2 round、 ADR-0069 α plan v7 と同 chain 長さ):

| round | judgment | agentId | finding 要点 |
|---|---|---|---|
| 1 | revise | `a3c6c550a0788c8d0` | MF 3 + nh 1 + lr 1 (= scope/allowed-touch/rollback inheritance) |
| 2 | revise | `ad98a158a896df14d` | MF 4 + nh 1 + lr 1 (= v2-only + A/D skip + PMDDOTNET_MML + gate-0 allowlist) |
| 3 | revise + escalate | `ac4757e26952d13d8` | MF 2 (= fixture limitation) → main agent escalation `design_judgment_needed` → user Option A 採用 (= 新規 fixture MML 追加) |
| 4 | revise | `a571adcf735d1d061` | MF 1 (= ADPCM-B delta-N reg 修正) + nh 1 + lr 1 |
| 5 | revise | `a01797246d12ae1e2` | MF 1 (= ym2610b/ym2610 distinctness 境界) + nh 2 + lr 1 |
| 6 | revise (retry) | `a3074589720f5bd7b` | MF 1 (= rollback 11 vs 12 wording) + lr 1 |
| 7 | **approve plan v7** | `acf90fc7a3874b0c5` | must-fix 0 + nh 0 + lr 1 (= stale wording scan 推奨) + 全 7 axis PASS |

= 計 MF 12 + nh 6 + lr 6 全反映、 round 3 user escalation `design_judgment_needed` 経路で Option A 採用、 round 6 = round 6 初回 agent (= `a5f7d4a85dad03156`) judgment 未 return = 機械復旧 rule 1 retry で round 6 retry confirmed approve。 設計対立なし。

impl-review chain (= 後で fill = main agent merge 後 dashboard maintenance entry に反映)。

### Annex γ: Draft → Accepted + 「A-J candidate distinctness 達成」 milestone literal (= PR4 で fill)

placeholder。 PR4 で Draft → Accepted 移行 + wording 解禁 + ADR-0065 β 再開 trigger 発火 literal record。

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
| 2026-05-25 | 40th session | ADR-0069 起票 Draft = A-J candidate distinctness 拡張専用 ADR (= ADR-0065 β PR3 halt 解消 + K bitmap pair distinct は ADR-0070 future へ分割、 5 sub-agent 並列 investigation (= driver ground truth + sha256 policy + rollback + candidate distinctness 要件 + Codex prompt 整備) + user 4 設計判断確定 (= scope A2 / sha256 B1 / allowed-touch Agent A / rollback Agent C 採用) + Codex layer 2 plan review 3 round chain (= round 1 revise + round 2 revise + round 3 approve、 計 MF 5 + nh 3 + lr 2 全反映)、 base anchor `wip-pmddotnet-opnb-extension@b215e7c`、 集約 HEAD `b215e7c` 起点)。 ADR doc 修正範囲 = (1) ADR-0069 file 新規 (= 12 決定 + historical split note + Annex skeleton A/α/β/γ + 改訂履歴 + 平易要約、 約 300-400 行) + (2) dashboard 0069 行追加 (= 「未起票」 → 「Draft 起票」 + 12 決定 literal + 表記制約 + 不可触対象 + Codex layer 2 plan review 3 round chain approve literal) + (3) dashboard escalation 履歴 ADR-0069 PR1 entry 1 row 新規追加 (= ADR-0065 β halt record entry 直前 = 最新位置) + (4) memory 起票 (= 新 memory `project_pmdneo_adr_0069_initiated.md` + MEMORY.md index 1 行追加、 repo 外 PR 対象外、 主軸直接 Write/Edit)。 sub-sprint chain α/β/γ 3 段 plan literal (= α A-J impl + β A-J verify + γ Accepted) + PR chain plan 4 PR + production sha256 `b15883fe...` 維持 mandatory (= guarded change `.if PMDNEO_USE_PMDDOTNET == 1` 配下限定 byte-identical 保証) + 表記制約 (= 起票時点 禁止 6+ 件 + γ Accepted 後解禁候補 1 件 + 併記必須 4 件 + 禁止維持 5 件) + rollback condition 12 件 + stop action 4 段 + responsibility 3 段 + destructive git 禁止 + scope-out 拡張 (= `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = user 別作業、 ADR-0069 完全 untouched)。 driver / verify script / vendor / fixture / build flag / ADR-0041〜0068 本文 + Annex / ADR-0048 軸 G ε partial state placement / `pmdneo_rhythm_event_trigger` body 完全不変 = doc-only sprint。 production sha256 = `b15883fe...` 維持期待 (= 再 build しない、 §決定 10 整合)。 commit chain = 単一 commit (= 本 commit、 ADR-0067 / ADR-0068 / ADR-0065 起票 PR1 同 pattern 継承)。 後続 = Codex layer 2 impl-review on PR1 + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 + memory update + user 完走報告、 sub-sprint α PR2 起票判断 = user 明示 GO 必須、 ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須 (= §決定 9 dependency literal、 ADR-0066 順序固定 + ADR-0070 ADR-0069 γ Accepted 後 future)。 | (= 本 PR1 commit chain 内 commit 1) |
| 2026-05-26 | 40th session | ADR-0069 sub-sprint α PR2 = A-J impl driver guarded change + 新規 routine additive sprint (= ADR-0065 β PR3 halt 解消の driver 拡張 impl、 ADR-0069 §決定 1-3 literal 実装、 K bitmap pair distinct は完全 scope-out = ADR-0070 future、 PR #144 MERGED at `22b8cad` + dashboard maintenance `92981a4` 後続、 base anchor `wip-pmddotnet-opnb-extension@92981a4`、 3 sub-agent F/G/H 並走 investigation 完走 = 並走 sub-agent 投入 default 化規律 2 回目適用 = Agent F K routine literal + Agent G L-Q complexity 不要 confirm + Agent H A-J entry literal、 Codex layer 2 plan review 7 round chain approve = round 1-6 revise + round 7 approve plan v7 (= 計 MF 9 + nh 5 + lr 5 全反映、 round 3/4 = Codex 誤読、 round 1/2/5/6 = valid technical correction、 設計対立なし、 ADR-0067 5 round precedent +2 round で α plan v7 approve))。 ADR doc 修正範囲 = (1) §決定 2 α row 完了判定 column update (= 「optional」 → 「α 完了 (= 本 PR2) = A-J impl 完了 + build 計 4 件 + 3 段 verify gate ALL PASS literal record」) + (2) Annex α fill 6 sub-section literal (= α-1 scope literal + 実装内容 + α-2 driver impl literal record edit diff + α-3 sdasz80 syntax 補正履歴 + α-4 build + sha256 + .lst verify gate ALL PASS literal + α-5 不可触対象 confirm + α-6 Codex plan review 7 round chain literal) + (3) 改訂履歴 α entry 追加 (= 本 entry) + (4) 平易要約 α PR2 context section 追加 (= α PR2 完走 update 6 構造)。 driver impl 修正範囲 = (5) `src/driver/standalone_test.s` line 1741-1804 周辺 = A-J 10 entry caller guarded change (= `.if PMDNEO_USE_PMDDOTNET == 1 / .else / .endif` 3 段 wrap、 K/L-Q precedent symmetric) + (6) 同 file line 5873 直後 = 新規 routine `pmdneo_mn_direct_load_aj_part_addr` additive (= 16 byte / 87 T-cycle、 K helper の index 化 10 倍展開、 input register A = aj_idx 0..9、 sdasz80 syntax 補正済 = `ld d, #0` + `ld hl, #pmddotnet_song + 1`)。 dashboard 修正範囲 = (7) 0069 行 status column update (= 「Draft 起票」 → 「Draft + α 完了」 + α 完了 entry literal) + (8) escalation 履歴 α PR2 entry 1 row 新規追加 (= ADR-0069 PR1 entry 直前 = 最新位置)。 memory 修正 = (9) `project_pmdneo_adr_0069_initiated.md` α 完走 entry 追加 (= 別途、 repo 外、 PR diff 対象外、 主軸直接 Write/Edit)。 build + sha256 + .lst verify gate (= 4 build 3 段) ALL PASS literal = 7a production default ym2610 build sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` MATCH + 7b PMDDOTNET=1 ym2610b primary build PASS (= sha256 `1dc136c8...` 別 sha256 比較対象外) + .lst predicate 4 件 confirm (= 新規 routine symbol present at 0x15ED + caller expansion 10 件 emit + 配置 area K routine 0x15E2 後連続 + bounded `.org` 維持) + 7b PMDDOTNET=1 ym2610 secondary build PASS (= sha256 `4df9b0dd...`) + 7c production default rebuild ym2610 sha256 = `b15883fe...` MATCH (= 7a 記録値一致 + literal 一致、 byte-identical 確定)。 既存 routine body 完全不変 confirm = `load_song_part_addr` (line 3390-3425) / `pmdneo_mn_direct_load_k_part_addr` (line 5865-5873) / `pmdneo_mn_direct_load_lq_part_addr` (line 5705-5781) / `pmdneo5_init_part` (line 3428~) / `pmdneo_rhythm_event_trigger` (line 5282-5344) = `git diff` touch なし。 不可触対象 = `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / vendor / song_data.inc / 既存 verify script / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0068 本文 + Annex 完全 untouched confirm (= `git diff --name-only` 混入確認 confirmed)。 commit chain = 単一 commit (= 本 commit、 ADR-0067 α / ADR-0048 軸 G ζ-α precedent 継承 = driver + ADR Annex α + dashboard 1 commit)。 後続 = Codex layer 2 impl-review on α PR2 (= 4 軸必須項目 literal = production default byte-identical / PMDDOTNET=1 caller expansion correctness / new routine placement・symbol・bounded .org / no K rhythm routine touch) + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] 4 回目適用 + memory + dashboard maintenance update + user 完走報告、 sub-sprint β PR3 起票判断 = user 明示 GO 必須 (= A-J verify script 新規 + chip target matrix build trace + Annex β fill)、 ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須。 | (= 本 α PR2 commit chain 内 commit 1) |
| 2026-05-26 | 40th session | ADR-0069 sub-sprint β PR3 = A-J candidate distinctness verify script 新規 + chip target matrix build trace verify sprint (= ADR-0069 §決定 2 β row literal + §決定 3 拡張 (= 3-d 新規 fixture MML 例外的許可 = user Option A 採用、 ADR-0041 §決定 5 `design_judgment_needed` escalation 経路)、 K bitmap pair distinct 完全 scope-out = ADR-0070 future、 PR #145 MERGED at `069cca7` + dashboard maintenance `cf8cf9f` + α retrospective sync `8609904` 後続、 base anchor `wip-pmddotnet-opnb-extension@9a10c15` 起点 + α impl-review 追加 update を含む集約 HEAD、 3 sub-agent I/J/K 並走 investigation 完走 = 並走 sub-agent 投入 default 化規律 3 回目適用 = Agent I 既存 verify script pattern 抽出 + Agent J chip target matrix shell command literal + Agent K β scope literal + Annex β draft、 Codex layer 2 plan review 7 round chain approve plan v7 (= round 1 revise MF 3 + nh 1 + lr 1 + round 2 revise MF 4 + nh 1 + lr 1 + round 3 revise + escalate MF 2 = fixture limitation → user Option A 採用 (= 新規 fixture MML 追加) + round 4 revise MF 1 = ADPCM-B delta-N reg 修正 + nh 1 + lr 1 + round 5 revise MF 1 = ym2610b/ym2610 distinctness 境界 + nh 2 + lr 1 + round 6 revise (retry) MF 1 = rollback 11 vs 12 wording + lr 1 + round 7 approve must-fix 0 + nh 0 + lr 1 + 全 7 axis PASS、 計 MF 12 + nh 6 + lr 6 全反映、 ADR-0067 5 round precedent +2 round = ADR-0069 α plan v7 同 chain 長さ、 round 6 初回 agent judgment 未 return = 機械復旧 rule 1 retry で round 6 retry confirmed approve、 設計対立なし))。 ADR doc 修正範囲 = (1) §決定 2 β row 完了判定 column update (= 「verify gate ALL PASS = ym2610b で A-J 10 part 全 candidate dispatch primary gate confirm」 → 「**β 完了 (= 本 PR3)** = A-J verify script 新規 + 新規 fixture MML + chip target matrix build trace verify ALL PASS literal record (= Annex β fill 6 sub-section literal record、 16 gate ALL PASS literal)」) + (2) §決定 3 拡張 = §決定 3-d 新規追加 (= 「β PR3 dynamic proof のため test fixture MML 追加例外的許可、 vendor / driver routine / K path 不変」、 ADR-0041 §決定 5 `design_judgment_needed` escalation 経路 + user Option A 採用 literal) + (3) §決定 5 section heading wording 修正 (= 「12 rollback condition table」 → 「**11 unique rollback condition table (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で 12 row)**」、 round 6 MF1 反映) + (4) Annex α-5 retrospective line range fix (= 旧 line 3390-3425 等 = 推定値 → 実 line 3443-3478 等、 sub-agent J finding 4 反映) + (5) Annex β fill 6 sub-section literal (= β-1 scope literal + β-2 新規 verify script literal record + β-3 新規 fixture MML literal record + β-4 verify script ALL PASS literal record + β-5 不可触対象 confirm + β-6 Codex plan review 7 round chain literal) + (6) 改訂履歴 β entry 追加 (= 本 entry) + (7) 平易要約 β PR3 context section 追加 (= β PR3 完走 update 6 構造)。 verify script 修正範囲 = (8) `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh` 新規 (= 約 250 行、 16 gate constellation = gate-0 preflight + gate-1 7a sha256 + gate-2 .lst predicate 4 件 + gate-3a/3b/3c FM/SSG/ADPCM-B dynamic + gate-3d per-part distinctness + gate-4 ym2610 caller + gate-5a/5b/5c ym2610 + gate-6/7 v2-only baseline + gate-8 7c sha256 + gate-9/10 driver no-touch、 ADR-0067 δ + ADR-0068 α/β/γ pattern 流用)。 新規 fixture MML 修正範囲 = (9) `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` 新規 (= PMDDotNETConsole format CRLF、 約 30 行、 A-J 10 part 全 active + per-part distinct note = c4/d4/e4/f4/g4/a4 for FM A-F + c4/d4/e4 for SSG G-I + c4 for ADPCM-B J、 voice 定義 2 件)。 dashboard 修正範囲 = (10) 0069 行 status column update (= 「Draft + α 完了」 → 「Draft + α/β 完了」 + β 完了 entry literal) + (11) escalation 履歴 β PR3 entry 1 row 新規追加 (= ADR-0069 α PR2 entry 直前 = 最新位置)。 memory 修正 = (12) `project_pmdneo_adr_0069_initiated.md` β 完走 entry 追加 (= 別途、 repo 外、 PR diff 対象外、 主軸直接 Write/Edit)。 verify gate ALL PASS literal = 16 gate (= gate-0 preflight + 1 7a sha256 MATCH + 2 .lst predicate 4 件 + 3a FM A-F keyon ≥ 1 each + 3b SSG G/H/I write ≥ 1 each + 3c ADPCM-B J ≥ 1 + 3d per-part distinctness = FM fnum distinct 5 + SSG tone distinct 6 + ADPCM-B delta distinct 2 + 4 ym2610 caller 10 共通 + 5a A/D skip 0 + B/C/E/F ≥ 1 each + 5b ym2610 SSG ≥ 1 each + 5c ym2610 ADPCM-B ≥ 1 + 6 v2-only ym2610b build PASS + 7 v2-only ym2610 build PASS + 8 7c sha256 byte-identical 確定 + 9 5 既存 routine label diff 0 + 10 driver source 完全 untouched)。 driver source `src/driver/standalone_test.s` = β PR3 完全 untouched confirm (= gate-9 + gate-10 PASS、 既存 routine body + 既存 verify script + 既存 build flag + vendor + ADR-0048 軸 G ε partial state + ADR-0026 §決定 3/4 + ADR-0041〜0068 本文 + Annex / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked 完全 untouched)。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` byte-identical 維持確定 (= gate-1 + gate-8 両 MATCH literal)。 commit chain = 単一 commit (= 本 commit、 ADR-0067 β / ADR-0068 β precedent 継承 = 新規 verify script + 新規 fixture MML + ADR Annex β + dashboard 1 commit)。 11 unique rollback condition 全 inheritance (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で 12 row、 round 6 MF1 反映 wording 統一) + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ) 維持。 後続 = Codex layer 2 impl-review on β PR3 (= 必須 review 軸 = fixture MML scope + 16 gate + stale wording + driver no-touch + vendor no-touch + sha256 維持) + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 [[feedback-pr-merge-branch-delete-atomic]] 5 回目適用 + memory + dashboard maintenance update + user 完走報告、 sub-sprint γ PR4 起票判断 = user 明示 GO 必須 (= Draft → Accepted + Annex γ fill + 「A-J candidate distinctness 達成」 wording 解禁 + ADR-0065 β/δ 再開 trigger 発火)、 ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須。 | (= 本 β PR3 commit chain 内 commit 1) |

## 平易要約

### ADR-0069 でやりたいこと

ADR-0065 β PR3 halt (= 40th session、 user option 3 採用) の根本問題を解消する driver 拡張 sprint。 現 driver では PMDDotNET MML の A/B/C/I etc (= FM/SSG melody) が audition audio に反映されないため、 越川氏 audition session で「実 MML を聴いて aesthetic judgment」 前提が成立しない。 ADR-0069 で A-J candidate distinctness を実現 = ADR-0065 β/δ 再開条件成立。 K bitmap pair distinct は別 risk profile (= ADR-0026 §決定 3/4 再設計要求) なので ADR-0070 future へ分割。

### ADR-0069 前提

- ADR-0065 = Draft + α 完了 + retrospective approve + β halt (= ADR-0069 先行 dependency 順序固定確定)
- ADR-0067 = Accepted (= 16 ch fixture 拡張完了)
- ADR-0068 = Accepted (= roadmap ⑤ 統合 verify 完了、 §決定 1 driver ground truth 確定)
- ADR-0068 §決定 1 driver ground truth = 「A-J 10 part は全 build mode default 固定」
- user 明示 4 設計判断確定 (= scope A2 / sha256 B1 / allowed-touch Agent A / rollback Agent C)
- 5 sub-agent 並列 investigation 完走
- Codex layer 2 plan review 3 round chain approve
- base anchor = `wip-pmddotnet-opnb-extension@b215e7c`

### ADR-0069 でやること

- ADR-0069 file 新規作成 (= 12 決定 + historical split note + Annex skeleton + 改訂履歴 + 平易要約)
- dashboard 0069 行追加 + escalation 履歴 entry 追加
- memory 起票 entry 新規 + MEMORY.md index 追加 (= repo 外、 PR diff 対象外)
- sub-sprint α/β/γ 3 段 plan literal 確定 (= α impl + β verify + γ Accepted)
- production sha256 維持 + driver guarded change additive 方針

### ADR-0069 起票後の結果

- ADR-0069 = Draft 起票完了
- dashboard 0069 行 = 「Draft 起票」
- sub-sprint chain plan literal record
- ADR-0066 / ADR-0070 候補 起票判断 dependency literal

### ADR-0069 γ Accepted 後の解釈 (= future)

- 「A-J candidate distinctness 達成」 wording 解禁 + 併記必須 4 件
- ADR-0065 β PR3 再起票可能化 (= β/δ 再開 trigger 発火)
- ADR-0070 (= K bitmap pair distinct) 起票判断 dependency 解除 (= user 明示 GO 必須)
- ADR-0069 γ Accepted ≠ 「16ch full candidate distinctness 完了」 (= K 拡張 ADR-0070 完走条件、 禁止維持)
- ADR-0069 γ Accepted ≠ 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 (= 各 user 判断軸 future)

### 次

- ADR-0069 PR1 commit chain (= 本 commit、 単一 commit)
- push + PR 起票
- Codex layer 2 impl-review on PR1 + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律
- memory update + user 完走報告
- 続行 = sub-sprint α PR2 起票判断 (= user 明示 GO 必須、 A-J impl)、 ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須

## α PR2 平易要約 (= A-J impl driver guarded change + 新規 routine additive sprint)

### α でやりたいこと

ADR-0069 §決定 1-3 literal の A-J candidate distinctness 拡張を driver source に実装。 ADR-0065 β PR3 halt の根本問題 (= PMDDotNET MML の A-J 10 part が現 driver で audition audio に出ない) を解消するための driver 拡張。 K bitmap pair distinct は完全 scope-out (= ADR-0070 future)。

### α 前提

- 集約 HEAD = `92981a4` (= ADR-0069 PR1 起票 dashboard maintenance commit 後)
- ADR-0069 = Draft 起票完了 (= PR #144 MERGED at `22b8cad`)
- α plan v7 = Codex layer 2 plan review 7 round chain approve (= round 1-6 revise + round 7 approve、 計 MF 9 + nh 5 + lr 5 全反映)
- 3 sub-agent F/G/H 並走 investigation 完走 = K routine template + L-Q complexity 不要 confirm + A-J entry literal extraction + 並走 sub-agent 投入 default 化規律 2 回目適用
- base anchor = `wip-pmddotnet-opnb-extension@92981a4`

### α でやったこと

driver impl (= `src/driver/standalone_test.s` 1 file のみ touch):
- A-J 10 entry caller guarded change (= line 1741-1804 周辺、 `.if PMDNEO_USE_PMDDOTNET == 1 / .else / .endif` 3 段 wrap、 K/L-Q 既存 pattern symmetric)
- 新規 routine `pmdneo_mn_direct_load_aj_part_addr` additive (= K routine `ret` 後 + `.endif` 前、 16 byte / 87 T-cycle、 input A = aj_idx 0..9)

ADR-0069 doc fill:
- §決定 2 α row 完了判定 column update
- Annex α fill 6 sub-section literal record

build + sha256 + .lst verify gate (= 4 build 3 段 ALL PASS):
- 7a production default ym2610: sha256 `b15883fe...` MATCH
- 7b PMDDOTNET=1 ym2610b primary: build PASS + .lst predicate 4 件 confirm
- 7b PMDDOTNET=1 ym2610 secondary: build PASS
- 7c production rebuild ym2610: sha256 `b15883fe...` MATCH (= 7a 一致 + literal 一致)

### α 完走後の結果

- ADR-0069 = Draft + α 完了
- A-J 10 entry guarded change + 新規 routine additive 実装完了
- production sha256 = `b15883fe...` 維持確定 (= byte-identical)
- 既存 routine body 完全不変 (= `load_song_part_addr` / K helper / L-Q helper / `pmdneo5_init_part` / `pmdneo_rhythm_event_trigger`)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = α PR2 完全 untouched confirmed

### α 完走後の解釈

- 「A-J candidate distinctness 達成」 wording = α PR2 時点では **依然禁止** (= γ Accepted 後解禁候補)
- 「16ch full candidate distinctness 完了」 wording = α PR2 時点も **永久禁止** (= K 拡張 ADR-0070 完走条件)
- 「roadmap ⑥ audition 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 / 「本番 cmd 切替完了」 = 禁止維持

### 次

- α PR2 commit + push + PR 起票
- Codex layer 2 impl-review on α PR2 + 4 軸必須項目 literal (= production default byte-identical / PMDDOTNET=1 caller expansion correctness / new routine placement / no K rhythm routine touch) + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律
- memory + dashboard maintenance update + 完走報告
- 続行 = sub-sprint β PR3 起票判断 (= user 明示 GO 必須、 A-J verify script 新規 + chip target matrix build trace)

## β PR3 平易要約 (= A-J candidate distinctness verify script 新規 + chip target matrix build trace verify sprint)

### β でやりたいこと

ADR-0069 §決定 2 β row literal の A-J candidate distinctness verify gate 整備。 α PR2 で driver 実装した A-J 10 entry guarded change が PMDDOTNET=1 / ym2610b primary + ym2610 secondary 両 chip target で正しく dynamic dispatch するかを build trace verify で確定。 driver は完全 untouched (= verify-only sprint)。

### β 前提

- 集約 HEAD = `9a10c15` (= ADR-0069 α PR2 dashboard maintenance + α retrospective sync 完了後)
- ADR-0069 = Draft + α 完了 (= PR #145 MERGED at `069cca7`)
- α PR2 driver impl = A-J 10 entry guarded change + 新規 routine additive 完了
- production sha256 = `b15883fe...` byte-identical 維持確定 (= α gate-1/8 確認済)
- β plan v7 = Codex layer 2 plan review 7 round chain approve (= round 1-6 revise + round 7 approve、 計 MF 12 + nh 6 + lr 6 全反映)
- 3 sub-agent I/J/K 並走 investigation 完走 = 並走 sub-agent 投入 default 化規律 3 回目適用
- round 3 で fixture limitation 発覚 (= 既存 PMDDotNET MML SAMPLE2-baseline は A/B/C/I のみ active で A-J 10 part 全 active dynamic proof 不可) → user escalation = `design_judgment_needed` 経路 = **Option A 採用** (= 新規 fixture MML 追加 = ADR-0069 §決定 3-d 例外的許可 literal)

### β でやったこと

verify script 新規 (= `src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh` 1 file、 約 250 行):
- 16 gate constellation (= preflight + sha256 + .lst predicate + dynamic FM/SSG/ADPCM-B + per-part distinctness + chip matrix + baseline + driver no-touch)
- ADR-0067 δ + ADR-0068 α/β/γ pattern 流用

新規 fixture MML (= `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` 1 file、 PMDDotNETConsole format CRLF):
- A-J 10 part 全 active + per-part distinct note (= FM A-F 各 distinct fnum / SSG G-I 各 distinct tone / ADPCM-B J distinct delta-N)
- voice 定義 2 件 (= @001 / @002)
- ADR-0069 §決定 3-d 例外的許可 literal (= user Option A 採用)

ADR-0069 doc update:
- §決定 2 β row 完了判定 column update
- §決定 3-d 新規追加 (= 新規 fixture MML 例外的許可、 user Option A literal)
- §決定 5 section heading wording fix (= 「12 rollback condition」 → 「11 unique rollback condition (= #1-#7 + #8a/#8b + #9-#11、 #8 分割で 12 row)」、 stale wording scan 反映)
- Annex α-5 retrospective line range fix (= 推定値 → 実 line range、 sub-agent J finding 4 反映)
- Annex β fill 6 sub-section literal record
- 改訂履歴 β entry 追加 (= 本)
- 平易要約 β PR3 context section 追加 (= 本 section)

verify gate ALL PASS literal (= 16 gate):
- gate-0 preflight scope-out forbidden path 検出: PASS
- gate-1 7a production default ym2610 sha256 = `b15883fe...` MATCH
- gate-2 7b PMDDOTNET=1 ym2610b .lst predicate 4 件 confirm: PASS
- gate-3a FM A-F keyon (A=5 B=1 C=1 D=1 E=1 F=1): PASS
- gate-3b SSG G/H/I (G=4 H=4 I=4): PASS
- gate-3c ADPCM-B J = 12: PASS
- gate-3d per-part distinctness = FM fnum 5 distinct + SSG tone 6 distinct + ADPCM-B delta-N 2 distinct: PASS
- gate-4 ym2610 caller 10 共通: PASS
- gate-5a A/D skip (A=0 D=0) + B/C/E/F ≥ 1 each: PASS
- gate-6/7 v2-only baseline build PASS
- gate-8 7c production rebuild sha256 = `b15883fe...` MATCH (= byte-identical 確定)
- gate-9/10 driver source 完全 untouched: PASS

### β 完走後の結果

- ADR-0069 = Draft + α/β 完了
- A-J 10 part 全 active dynamic dispatch ym2610b primary build trace で確定
- production sha256 = `b15883fe...` byte-identical 維持確定 (= gate-1/8 両 MATCH)
- driver source `src/driver/standalone_test.s` = β PR3 完全 untouched confirmed
- 既存 verify script + 既存 build flag + vendor + ADR-0048 軸 G ε partial state + ADR-0026 §決定 3/4 + ADR-0041〜0068 本文 + Annex / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked 完全 untouched

### β 完走後の解釈

- 「A-J candidate distinctness 達成」 wording = β PR3 時点では **依然禁止** (= γ Accepted 後解禁候補、 併記必須 4 件)
- 「16ch full candidate distinctness 完了」 wording = β PR3 時点も **永久禁止** (= K 拡張 ADR-0070 完走条件)
- 「roadmap ⑥ audition 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 / 「本番 cmd 切替完了」 = 禁止維持
- ADR-0065 β/δ 再開条件 = ADR-0069 **γ Accepted 完走後** (= β 完走だけでは不足、 γ Accepted trigger 必須)

### 次

- β PR3 commit + push + PR 起票
- Codex layer 2 impl-review on β PR3 + 必須 review 軸 6 件 literal (= fixture MML scope / 16 gate / stale wording / driver no-touch / vendor no-touch / sha256 維持) + approve loop
- main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 5 回目適用
- memory + dashboard maintenance update + 完走報告
- 続行 = sub-sprint γ PR4 起票判断 (= user 明示 GO 必須、 Draft → Accepted 移行 + Annex γ fill + 「A-J candidate distinctness 達成」 wording 解禁 + ADR-0065 β/δ 再開 trigger 発火)
