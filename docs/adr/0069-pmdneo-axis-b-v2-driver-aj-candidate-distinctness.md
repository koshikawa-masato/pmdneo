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
| **PR2 = α impl** | driver A-J guarded change (= line 1741-1804) + 新規 routine `pmdneo_mn_direct_load_aj_part_addr` additive (= line 5810-5821 周辺) | optional | impl 完了 + production sha256 `b15883fe...` 維持 confirm |
| **PR3 = β verify** | A-J candidate distinctness verify script 新規 (= `verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh`) + chip target matrix build trace + distinct pattern 確認 + Annex β fill | optional | verify gate ALL PASS = ym2610b で A-J 10 part 全 candidate dispatch primary gate confirm + ym2610 で A/D skip expected behavior confirm + 「A-J candidate distinctness 達成」 wording 解禁条件達成 |
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

## 決定 5: rollback 条件 literal (= 12 condition table + 4 段 stop action + 3 段 responsibility + destructive git 禁止)

### stop action 4 段 定義 (= ADR-0041 §決定 4-3 line 227 literal「修正 commit = 軸 chain 連鎖 commit (= rollback ではない)」 整合)

- **(α) 連鎖 commit fix-up**: rollback ではない、 軸 chain の連鎖 commit (= retrospective Codex revise / Codex round 内 must-fix / build failure 修正 等の軽微 fix)
- **(β) sub-sprint halt**: 当該 sub-sprint PR halt + halt record commit doc-only + 後続 sub-sprint dependency 順序固定 (= ADR-0065 β PR3 halt precedent literal 同形)
- **(γ) ADR-0069 全体 halt + Draft 維持**: ADR-0069 全体 halt + 後続 ADR (= ADR-0065 β/δ / ADR-0066 / ADR-0070) dependency 順序固定 update
- **(δ) 新 ADR 化 (= scope 分割)**: ADR-0069 scope 分割 + 新 ADR-00NN 起票 + ADR-0069 scope 縮小 update (= ADR-0067 round 4 precedent)

### responsibility 3 段 定義 (= ADR-0041 §決定 5 介入手順整合)

- **(I) 主軸自律**: main agent autonomous (= sub-agent 評価 / 連鎖 commit / 規律解釈 / Codex orchestration)
- **(II) Codex layer 2**: main agent ↔ Codex 統合判断 + plan/impl review approve/revise loop
- **(III) user escalation**: ADR-0041 §決定 5 6 種 + 設計判断複数案 + scope 変更 + 全体 halt 判断

### 12 rollback condition table

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

### Annex α: A-J implementation literal record (= PR2 で fill)

placeholder。 PR2 で driver guarded change + 新規 routine additive 実装 literal record。

### Annex β: A-J verify literal record (= PR3 で fill)

placeholder。 PR3 で chip target matrix verify script 新規 + 6 gate ALL PASS literal record。

### Annex γ: Draft → Accepted + 「A-J candidate distinctness 達成」 milestone literal (= PR4 で fill)

placeholder。 PR4 で Draft → Accepted 移行 + wording 解禁 + ADR-0065 β 再開 trigger 発火 literal record。

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
| 2026-05-25 | 40th session | ADR-0069 起票 Draft = A-J candidate distinctness 拡張専用 ADR (= ADR-0065 β PR3 halt 解消 + K bitmap pair distinct は ADR-0070 future へ分割、 5 sub-agent 並列 investigation (= driver ground truth + sha256 policy + rollback + candidate distinctness 要件 + Codex prompt 整備) + user 4 設計判断確定 (= scope A2 / sha256 B1 / allowed-touch Agent A / rollback Agent C 採用) + Codex layer 2 plan review 3 round chain (= round 1 revise + round 2 revise + round 3 approve、 計 MF 5 + nh 3 + lr 2 全反映)、 base anchor `wip-pmddotnet-opnb-extension@b215e7c`、 集約 HEAD `b215e7c` 起点)。 ADR doc 修正範囲 = (1) ADR-0069 file 新規 (= 12 決定 + historical split note + Annex skeleton A/α/β/γ + 改訂履歴 + 平易要約、 約 300-400 行) + (2) dashboard 0069 行追加 (= 「未起票」 → 「Draft 起票」 + 12 決定 literal + 表記制約 + 不可触対象 + Codex layer 2 plan review 3 round chain approve literal) + (3) dashboard escalation 履歴 ADR-0069 PR1 entry 1 row 新規追加 (= ADR-0065 β halt record entry 直前 = 最新位置) + (4) memory 起票 (= 新 memory `project_pmdneo_adr_0069_initiated.md` + MEMORY.md index 1 行追加、 repo 外 PR 対象外、 主軸直接 Write/Edit)。 sub-sprint chain α/β/γ 3 段 plan literal (= α A-J impl + β A-J verify + γ Accepted) + PR chain plan 4 PR + production sha256 `b15883fe...` 維持 mandatory (= guarded change `.if PMDNEO_USE_PMDDOTNET == 1` 配下限定 byte-identical 保証) + 表記制約 (= 起票時点 禁止 6+ 件 + γ Accepted 後解禁候補 1 件 + 併記必須 4 件 + 禁止維持 5 件) + rollback condition 12 件 + stop action 4 段 + responsibility 3 段 + destructive git 禁止 + scope-out 拡張 (= `wip-dashboard-coverage` branch + `docs/dashboard/` untracked = user 別作業、 ADR-0069 完全 untouched)。 driver / verify script / vendor / fixture / build flag / ADR-0041〜0068 本文 + Annex / ADR-0048 軸 G ε partial state placement / `pmdneo_rhythm_event_trigger` body 完全不変 = doc-only sprint。 production sha256 = `b15883fe...` 維持期待 (= 再 build しない、 §決定 10 整合)。 commit chain = 単一 commit (= 本 commit、 ADR-0067 / ADR-0068 / ADR-0065 起票 PR1 同 pattern 継承)。 後続 = Codex layer 2 impl-review on PR1 + approve loop + main agent 経路 merge + local + remote branch 削除 atomic 1 セット規律 + memory update + user 完走報告、 sub-sprint α PR2 起票判断 = user 明示 GO 必須、 ADR-0066 / ADR-0070 候補 起票判断 = 各 user 明示 GO 必須 (= §決定 9 dependency literal、 ADR-0066 順序固定 + ADR-0070 ADR-0069 γ Accepted 後 future)。 | (= 本 PR1 commit chain 内 commit 1) |

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
