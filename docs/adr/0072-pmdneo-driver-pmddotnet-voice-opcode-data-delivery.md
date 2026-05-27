# ADR-0072: PMDNEO driver-PMDDOTNET voice opcode data delivery repair (= voice_table lookup vs inline voice table mismatch)

- 状態: **Accepted** (= 2026-05-27 43rd session 完走、 sprint α/β/γ/ε 完了 = ADR-0071 ε Accepted (= PR #153 MERGED at `665b494`) + δ MAME runtime functional verify で発見した voice opcode data delivery mismatch の engineering repair 完了 = (1) `src/tools/pmd-mml/compile.py` 拡張 = `parse_fffile_directive()` + `merge_voices_with_priority()` + `format_voice_table_only()` + `scan_voice_references()` + `--voice-only` mode + (2) `scripts/build-poc.sh` PMDDOTNET_MML block 拡張 = compile.py --voice-only 並行呼出 + voice_table_pmddotnet.inc 生成 + song_data.inc 内 empty `voice_table:` block sed 削除 + voice_table_pmddotnet.inc append、 driver source **完全 no-touch** + production sha256 invariant **`457a237c...` byte-identical 維持確認** ((B1) baseline verify)、 ε Accepted 後解禁 wording = 「driver-PMDDOTNET voice opcode data delivery repair 完了」 (= 併記必須 6 件 = (i) audio 音量問題 (= -76 dBFS、 δ-5 engineering gate Layer 1 未達) は driver volume scaling or fixture voice design 由来 = ADR-0072 scope OUT (= 別 sprint / 別 ADR 範疇) + (ii) production-ready 全体達成ではない (= ADR-0066 候補 future) + (iii) (d) audition gate 達成ではない (= ADR-0065 ε scope) + (iv) 軸 B 完成ではない + (v) 軸 G 完成ではない + (vi) 16ch full candidate distinctness 完了ではない (= ADR-0070 候補 future))、 main agent autonomous で完走 (= ADR-0041 §決定 4-2 Codex Rescue 化 default + ADR-0041 §決定 4-3 retrospective Codex impl-review pattern、 計 Codex layer 2 review 9 round = plan review 7 round chain (= plan v1→v7 approve、 round 4 attempt 1 placeholder 機械復旧 retry + round 4 retry approve、 plan v5 build-side scope shift + #FFFile 対応 + plan v6/v7 wording fix 経由 round 7 approve) + γ retrospective impl-review 2 round chain (= round 1 revise MF-1 LR-2 mitigation 未実装 + fix-up commit `6503738` + round 2 retry approve))
- 起票日: 2026-05-27
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 user 明示「voice opcode @N PMDDOTNET 経路解釈 follow-up sprint が自然 + Claude Code 主担当」)
- 関連 ADR:
  - **ADR-0071** (= driver-PMDDOTNET integration repair、 rest 0x0F handler + tempo 3-byte = ε Accepted、 δ verify で voice opcode @N 未解釈 = ADR-0071 §決定 1 scope OUT (5) 該当 = 本 ADR-0072 が repair)
  - **ADR-0065** (= roadmap ⑥ audition、 sprint B follow-up integration verify で voice 関連 silent wav 発見、 §決定 13 4 層 engineering gate framework が detect)
  - **ADR-0069** (= A-J distinctness 拡張、 load layer 完成、 guarded change `.if PMDNEO_USE_PMDDOTNET` pattern precedent)
  - **ADR-0067** (= 16 ch fixture 拡張、 既存 verify script regression 維持対象)
  - **ADR-0068** (= 16 ch integration trace、 既存 verify script regression 維持対象)
  - **ADR-0051** (= SSG tone-enable owner contract、 既存 RMW owner 不可触対象)
  - **ADR-0058** (= roadmap ② v2 dispatcher、 `pmdneo_v2_*` 系 routine 不可触対象)
  - **ADR-0048** (= 軸 G dynamic supply、 ε partial state placement 不可触対象継承)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 + 並走 sub-agent + §決定 12 worktree isolation、 §決定 4-3 main agent fallback approve + retrospective Codex review)
  - **ADR-0026** (= K dispatch L ch 固定占有 不可触対象継承)
  - **ADR-0050** (= fadeout-semantics、 PMDNEO_NO_FADE harness flag precedent、 issue 3 scope-out 根拠)
- 関連 memory:
  - `feedback_codex_rescue_audition_material_review_prompt.md` (= 4 層 engineering gate framework executor、 本 ADR の verify gate base)
  - `feedback_main_agent_engineering_responsibility.md` (= repair = main agent autonomous + user judgment = 設計不可逆/scope 変更/aesthetic/本番切替のみ)
  - `feedback_pr_merge_branch_delete_atomic.md` (= branch 運用 4 条 + atomic 1 セット規律)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal)
  - `feedback_parallel_subagent_investigation_default.md` (= 5 並走 sub-agent default、 本 ADR で適用 5 回目)
  - `feedback_long_running_hang_auto_recovery_rule.md` (= build / verify hang threshold)
  - `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= worktree base ref mismatch、 agents 2/3/5 で 2 回目 trigger、 9 件 guard 機能実証)
  - `feedback_sdas_if_no_value_comparison.md` (= sdasz80 `.if X == 1` 値比較非対応、 binary toggle `.if X` 統一)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= main agent autonomous + Codex layer 2 review-only)

## 背景

ADR-0071 sprint γ impl (= 2 driver patch = rest 0x0F handler + tempo 3-byte handling inline embed) + ε Accepted 後、 main agent autonomous default task 2 = δ MAME runtime functional verify を実施。 結果:

- ✅ δ-4 既存 verify script regression = ALL PASS (= 47 gate transitively)
- ✅ δ-6 patch (2) tempo 3-byte runtime = PASS (= driver_tempo_d 0xF817 = 0x18 = (120*13)>>6)
- ✅ δ-7 patch (1) rest 0x0F handler runtime = PASS (= FM clean keyon-keyoff alternating cycle)
- ❌ **δ-5 engineering gate executor = FAIL** = wav RMS = -∞ dBFS (= silent)、 原因 = **voice opcode `@N` が PMDDOTNET 経路で未解釈** (= ADR-0071 §決定 1 scope OUT (5) literal 該当)
- ❌ δ-1/δ-2/δ-3 audio audible = BLOCKED on δ-5

本 ADR-0072 で voice opcode @N PMDDOTNET 経路解釈 issue を repair。

### 5 並走 sub-agent investigation 結果 (= sprint α 完走)

5 sub-agent 並列 investigation:

| agent | scope | 結果 |
|---|---|---|
| agent 1 (= `ac9672ac72446cea9`) | PMDDotNET compiler voice opcode emit + voice definition handling | ✅ SUCCESS via `git show` workaround (= preflight fail worktree base ref mismatch + main HEAD `git show` read-only access で迂回)、 confidence high |
| agent 2 (= `a29c987d12e4dcef2`) | .M/.MN binary voice data structure | ❌ preflight FAIL (= worktree HEAD `3ad1e23` outdated revert chain、 投資未実施)、 agent 1 でカバー範囲含む |
| agent 3 (= `a19e62a20efe8134e`) | driver `commandsp` voice opcode handler + register write | ❌ preflight FAIL (= 同上)、 agent 1 でカバー範囲含む |
| agent 4 (= `ada225a5606f3ddd1`) | PMD V4.8s vs PMDDotNET voice opcode encoding 比較 | ✅ SUCCESS via `git show` workaround、 confidence high |
| agent 5 (= `a4f3b05d7ad45fdb4`) | allowed-touch + sha256 maintenance framework | ❌ preflight FAIL (= 同上)、 main agent 直接 framework analysis でカバー |

### 真の root cause (= agent 1 + agent 4 finding 統合)

**voice opcode `@N` emit byte format は PMD V4.8s と PMDDotNET で完全 byte-identical** (= 2 byte `0xFF <voice_num>`)。 ADR-0071 tempo 3-byte 型 encoding mismatch は voice opcode には **存在しない**。

driver の `comat` (= `commandsp` から `0xFF` opcode dispatch) も既に存在 (= `src/driver/standalone_test.s:4419`)、 voice_num fetch + voice_table[N] lookup + `pmdneo_fm_voice_set` call の経路は ADR-0058 era で実装済。

**真の問題**: driver の `voice_table[N]` lookup が PMDNEO compile.py 経路 separate Z80 label table (= `voice_table: .dw voiceN_data`) を参照する設計だが、 PMDNEO_USE_PMDDOTNET=1 経路では:

1. compile.py が **走らない** (= MML compile = PMDDotNET 経由) → `voice_table` Z80 label table が populated されない / 空 / undefined
2. PMDDotNET は voice data を **`.M binary 内 inline voice table` 形式** で emit (= `[1 byte voice_num][25 byte voice_buf]...[0xFF 0x00 terminator]`、 slot-interleaved order slot_1/slot_3/slot_2/slot_4)
3. PMDNEO compile.py は voice data を **separate Z80 label** + **register-major order** で出力
4. driver `comat` は (3) の format を expect、 (2) の format を読まない

結果: `voice_table[N]` lookup が 空 or PMDNEO format expected の Z80 address を返す → `pmdneo_fm_voice_set` が garbage data を FM register に write → 初期 TL=0x1F (silence) のまま → audio silent。

## 決定

### 決定 1: ADR-0072 scope = PMDDOTNET 経路 voice data delivery 修理に限定

#### scope IN (= ADR-0072 で修理)

- **(1) PMDDOTNET_MML build 経路で driver の voice_table lookup を PMDDOTNET inline voice table へ redirect**
  - 候補経路: (a) driver-side guarded change (= ADR-0071 pattern) / (b) compile.py path / (c) build script path
  - 各候補の比較 + 推奨案確定は plan v1 (= Annex β-1) で literal
  - production sha256 invariant 維持 (= base anchor `457a237c...`、 guarded change `.if PMDNEO_USE_PMDDOTNET` 配下限定 + flag-off で byte-identical)

#### scope OUT (= 別軸 / 別 ADR future、 ADR-0072 では touch しない)

- **(2) SSG voice change (= `@N` for SSG part)** = PMDDotNET は SSG part で `0xF0 + 4 envelope byte` (= soft envelope inline) emit、 driver 側 handler 確認 + 必要に応じて別 ADR scope
- **(3) PCM voice change (= `@N,N,N,N` repeat 拡張記法)** = agent 4 caveat literal record、 PMDDotNET PCM part `0xCE` opcode 経路、 PMDNEO MML fixture で未使用なら不発、 別 ADR scope
- **(4) MAME runtime audio audible verify on user 別作業 fixture** (= fm/ssg-active-ladder.mml) = ADR-0072 ε Accepted 後 follow-up、 user 明示 GO 必須
- **(5) ADR-0065 ε audition session 実施判断** = user 介入 mandatory、 driver dispatch capability 確立後の audition material 再設計 + user audition session
- **(6) production-ready 全体達成 / 本番 cmd 切替判断** = ADR-0066 候補 future、 user 明示 GO 必須

### 決定 2: sub-sprint chain plan = α/β/γ/δ/ε 5 段 (= ADR-0067/0068/0069/0071 precedent)

| sub-sprint | scope | user 介入 | 完了判定 | 駆動 driver/runtime touch |
|---|---|---|---|---|
| **α** | root cause investigation = 5 並走 sub-agent + 真 root cause 確定 + Annex α literal record | optional (= main agent autonomous + Codex Rescue review-only) | **本 PR1 起票時完了** = Annex α 5 sub-section fill + ADR doc 起票 | なし (= 全 sub-agent read-only) |
| **β** | plan iteration = Annex β-1 plan v1 起草 + Codex Rescue plan review chain + plan v2/v3 iteration | optional | plan approve (= Codex approve or main agent fallback approve + retrospective Codex review = ADR-0041 §決定 4-3 precedent) | なし (= doc-only) |
| **γ** | repair implementation = approve plan に基づき driver / compile.py / build script 修正 (= guarded change `.if PMDNEO_USE_PMDDOTNET` pattern) | optional (= main agent autonomous + Codex Rescue review-only) | impl 完了 + 4 build matrix PASS + production sha256 byte-identical 維持 confirm + 既存 routine body 不変 confirm | **あり** (= scope IN (1) 関連 routine のみ) |
| **δ** | MAME runtime functional verify = δ-1〜δ-7 gate 実施 + audio render + trace + expected behavior 確認 | optional | δ verify findings literal record (= ADR-0071 ε 後 δ verify pattern) | なし (= MAME render only) |
| **ε** | Accepted 移行 doc-only = Draft → Accepted + Annex 全統合 + 「driver-PMDDOTNET voice opcode data delivery repair 完了」 milestone wording 解禁 (= 併記必須) + ADR-0065 audition material 再設計 trigger 解除 record | optional | Accepted milestone + ADR-0065 audition material 再開 trigger 発火 | なし (= doc-only) |

### 決定 3: production sha256 維持方針 (= user 明示 mandate)

production sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` **維持 mandate** (= dashboard active baseline marker section literal、 base anchor `wip-pmddotnet-opnb-extension@05f0e44` baseline)。

修理は **`.if PMDNEO_USE_PMDDOTNET ... .endif` guarded change pattern** (= ADR-0069 §決定 4 + ADR-0071 §決定 3 precedent) で実装し、 production default build (= `PMDNEO_USE_PMDDOTNET=0`) では **byte-identical 維持**。

guarded change で実装不可能 (= 修理 routine が両 build mode 共通で sha256 衝突不可避) と判明した場合は **user 明示 GO + 新 baseline 設定 へ pivot**、 main agent 自走では実施しない。

#### γ 実装時の検証

- 4 build matrix PASS (= ADR-0071 plan v4 B1-B4 同 pattern):
  - (B1) production baseline = `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` → sha256 == `457a237c...` byte-identical
  - (B2) post-patch flag-off = (B1) と byte-identical (= guarded change flag-off 完全無効化)
  - (B3) flag-on pre-patch with fixture = ADR-0071 patch + ADR-0069 guarded + import song data only
  - (B4) flag-on post-patch with fixture = (B3) と diff = ADR-0072 patch byte 量のみ
- production sha256 不一致時 = rollback condition #1 発火 (= ADR-0071 §決定 6 + ADR-0069 §決定 5 継承)

### 決定 4: allowed-touch literal (= 推奨候補 (a) driver-side fix base、 plan v1 で確定)

#### (i) repo diff allowed-touch (= ADR-0072 各 PR 対象 file)

- **driver-side fix 候補 (= 推奨 = ADR-0071 同 pattern)**:
  - `src/driver/standalone_test.s` = `comat` routine 周辺 (= line 4419 周辺) + 必要に応じて新規 helper routine additive (= guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下限定)
  - 新規 verify script (= `src/test-fixtures/adr-0072/`) = δ functional verify gate 実装
  - 新規 committed fixture (= `src/test-fixtures/adr-0072/*.mml`) = ADR-0071 precedent + ADR-0069 §決定 3-d「新規 fixture MML 例外的許可」 継承
  - `docs/adr/0072-*.md` + `docs/parallel-axes-dashboard.md` + 改訂履歴 + 平易要約
- **compile.py path 候補 (= 代替案)**:
  - `src/tools/pmd-mml/compile.py` = PMDDotNET .M binary inline voice table → voice_table format 変換 logic 追加
  - `scripts/build-poc.sh` = build wiring 拡張
- **build script path 候補 (= 代替案)**:
  - `scripts/m-to-z80-incbin.py` 等 = .M → song_data.inc auto-generation + voice_table inline 注入

#### (ii) 不可触対象 (= 完全不変)

- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0026 §決定 3/4 K dispatch L ch 固定占有
- ADR-0051 `pmdneo_ssg_tone_sync` (= reg 0x07 RMW 唯一 owner)
- ADR-0058 `pmdneo_v2_*` 系 routine body
- ADR-0067〜0071 既存 Annex 本文 (= immutable history)
- 既存 verify script (= ADR-0049〜0071 全 verify gate)
- 既存 fixture MML (= ADR-0067/0068/0069 PR で commit 済 + user 別作業 untracked fixture)
- vendor (= `vendor/pmd48s/` + `vendor/PMDDotNET/` + `vendor/ngdevkit-examples/`)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked + 退避 branch + 集約 branch 上 user 別作業

### 決定 5: verify gate literal

#### γ build verify (= production sha256 維持 + 4 build PASS)

- gate γ-1: 4 build matrix PASS (= 決定 3 § γ 実装時の検証 literal)
- gate γ-2: production sha256 byte-identical 維持 (= `457a237c...` ALL build mode (B1)/(B2) で)
- gate γ-3: `.lst` predicate (= ADR-0071 precedent 4 件 = 新規 inline label / guarded block assemble / 既存 routine body 不変 / 既存 symbol table 不変)
- gate γ-4: ADR-0051 owner contract untouched (= `pmdneo_ssg_tone_sync` 完全不変)
- gate γ-5: 既存 verify script ALL PASS (= ADR-0049〜0071 regression-free)

#### δ functional verify (= 実音成立確認、 voice load + audio audible)

- gate δ-1〜δ-3: fm-active-ladder / ssg-active-ladder / candidate 2 v3 staircase audible (= user 別作業 fixture も含む)
- gate δ-4: 既存 18+ verify script regression carry (= ADR-0071 δ-4 同 pattern)
- gate δ-5: `scripts/analyze-audition-wav.py` engineering gate 4 層 ALL PASS (= 特に Layer 1 WAV hygiene = wav RMS > -60 dBFS で **非 silent confirm**、 これが本 ADR-0072 の primary success metric)
- gate δ-6: MAME ymfm trace で FM reg 0x30-0x9F (= voice register area = AR/DR/SR/RR/SL/TL/KS/ML/DT/AMS) writes confirmed (= 25 byte voice data 各 FM channel に write 確認)
- gate δ-7: MAME z80-mem-trace で `voice_table` lookup 経路または PMDDOTNET inline voice table 読込 経路 trace confirmed (= 実装案に応じて trace target 確定 = plan v1 で literal)

### 決定 6: rollback condition (= ADR-0071 §決定 6 11 condition 継承 + ADR-0072 固有 condition)

ADR-0071 §決定 6 11 unique rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ) **完全継承**。

ADR-0072 固有 condition 追加候補 (= plan v1 で literal 確定):
- #12 voice load failure on PMDDOTNET path (= γ impl 後 MAME ymfm trace で voice register writes 0 件)
- #13 audio silent persistence after γ impl (= δ-5 engineering gate Layer 1 FAIL on `analyze-audition-wav.py`)

### 決定 7: 表記制約 + 解禁表現候補

#### ADR-0072 起票時点 (= 本 sprint α)

- **使用可**:
  - 「driver-PMDDOTNET integration repair (= rest 0x0F handler + tempo 3-byte) impl 完了」 (= ADR-0071 ε Accepted 後継承)
  - 「ADR-0071 patch (1)/(2) MAME runtime 動作確認」 (= ADR-0071 δ verify 後継承)
  - 「ADR-0072 sprint α 完走 = 真の root cause = voice_table lookup vs inline voice table mismatch 確定」
- **禁止維持 (= 起票時点)**:
  - 「driver-PMDDOTNET voice opcode data delivery repair 完了」 (= ADR-0072 ε Accepted 後解禁)
  - 「δ MAME runtime functional verify 完了」 (= ADR-0072 δ verify ALL PASS 後解禁)
  - 「(d) audition gate 達成 / roadmap ⑥ audition 完了 / production-ready 全体達成 / 軸 B 完成 / 軸 G 完成 / 本番 cmd 切替完了」 (= 各 user 明示 GO 必須)
  - 「16ch full candidate distinctness 完了」 (= ADR-0070 候補 future)

#### ADR-0072 ε Accepted 後 (= 解禁候補)

- 「**driver-PMDDOTNET voice opcode data delivery repair 完了**」 (= 併記必須 = (i) δ MAME runtime functional verify 結果 + (ii) production-ready 全体達成ではない + (iii) (d) audition gate 達成ではない + (iv) 軸 B 完成ではない + (v) 軸 G 完成ではない + (vi) 16ch full candidate distinctness 完了ではない)
- 「ADR-0072 ε Accepted」

### 決定 8: 番号 chronology + ADR 関連順序

ADR-0072 = ADR-0071 ε Accepted 後の natural follow-up sprint。 ADR-0070 候補 (= K bitmap pair distinct) は ADR-0072 と独立 (= user 明示 GO 必須)。 ADR-0065 ε audition session は ADR-0072 ε Accepted + user 介入 mandatory で再開判断。

## verify gate (= 本 PR1 sprint α scope = doc-only、 spec consistency check)

- gate 1: ADR doc 整合性 (= 8 決定 literal + Annex α 5 sub-section + Annex β-1 plan v1 + 平易要約 6 構造)
- gate 2: 5 並走 sub-agent investigation finding literal record (= preflight fail 3 agent + success 2 agent literal)
- gate 3: dashboard 0072 行 add (= status + scope + allowed-touch + verify gate + dependency literal)
- gate 4: 改訂履歴 起票 entry append (= append only mandate 厳守)
- gate 5: production sha256 = `457a237c...` 維持 confirm (= 本 sprint α doc-only で build しない、 carry)
- gate 6: branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` + (2) merge atomic + (3) close 不要時削除 + (4) 保持対象 3 type 不可触
- gate 7: 5 並走 sub-agent default 規律遵守 confirm (= memory `feedback_parallel_subagent_investigation_default.md`、 同一 message 内多 Agent tool call + nesting 禁止)
- gate 8: worktree base ref mismatch escalation 規律遵守 confirm (= 3 agent preflight fail を escalation `merge_conflict` で literal record、 越権操作なし confirmed)

## Codex layer 2 plan review chain

sprint α 完走後の sprint β = Codex Rescue plan review chain (= ADR-0071 5 round precedent + ADR-0069 7 round precedent から類推):
- round 1: plan v1 投入 + scope / allowed-touch / sha256 / verify plan / repair candidate (a)/(b)/(c) 選定 重点 review
- round chain: revise → plan v2/v3 iteration → approve (= Codex approve or main agent fallback approve + retrospective Codex review)

## Annex α: root cause investigation 5 sub-agent finding synthesis (= sprint α scope literal fill)

### α-1: agent 1 finding = PMDDotNET compiler voice opcode emit (= confidence high、 via `git show` workaround)

#### preflight fail + 復旧経路
- worktree HEAD `3ad1e23` (= revert chain) ≠ 期待 `05f0e44`、 期待 file 不在
- 復旧 = `git show wip-adr-0072-voice-opcode-pmddotnet:<path>` read-only access で迂回 (= 越権操作なし、 worktree 内 write なし)

#### 確定 finding 5 軸

##### 軸 1 = `@N` voice change opcode emit format
- `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:7933-8030` `neirochg()` routine
- byte construction at line 7957 (`work.dx = 0xff00 + (byte)work.bx`) → `parset()` (line 7427-7449)
- **emit byte pattern = `[0xFF][voice_num]` = 2 byte**

##### 軸 2 = voice definition emit format
- `mc.cs:3744-3854` `nns()` parse + voice_buf store
- `mc.cs:1774-1880` `vdat_set()` / `nd_s_loop()` voice table emit to .M binary
- binary layout = .M binary inline voice table = `[1 byte voice_num][25 byte voice_buf data]` × N + `[0xFF 0x00]` terminator (= **supersede note**: 元 agent 1 report writing convention 由来表記、 Codex round 1+2 + main agent direct mc.cs:1872-1876 read で訂正 = literal byte sequence in file = `[0x00, 0xFF]` low/high 順 = `(byte)0xff00 = 0x00` 先 + `(byte)(0xff00 >> 8) = 0xFF` 後、 plan v3 Annex β-3-3 + plan v4 が訂正版 ground truth)
- voice table pointer at .M offset `2 * (max_part + 1)` (= immediately after part pointer table、 line 1781-1789)
- per-voice in-memory order = slot1 → slot3 → slot2 → slot4 (= hardware slot interleaved)

##### 軸 3 = voice register write logic
- mc.cs = **compiler-side register write なし**、 voice_buf に store するのみ
- driver-side runtime dispatch mandatory (= `comat` handler 経路)
- dispatch model = compiler embed voice table data + emit `0xFF N` opcode + runtime driver reads opcode + lookup voice table + write registers

##### 軸 4 = PMDDotNET vs PMDNEO compile.py emit 差分

| aspect | PMDDotNET (`mc.cs`) | PMDNEO (`src/tools/pmd-mml/compile.py`) |
|---|---|---|
| `@N` opcode bytes | `0xFF N` (2 byte) | `0xFF N` (2 byte) |
| voice number base | 0-based | 1-based input → 0-based stored (= `@001` → N=0) |
| voice param storage | **slot interleaved** (slot1/3/2/4) per voice 25 byte | **register-major** (= 6 reg × 4 slot) per voice 25 byte |
| voice table format | **inline in .M binary** `[voice_num][25 byte]...[0xFF 0x00]` (= 表記 supersede = 訂正版 `[0x00, 0xFF]`、 Annex β-3-3 ground truth carry) | **separate Z80 source labels** `voice_table: .dw voiceN_data` |
| SSG `@N` | expand to `0xF0 + 4 envelope byte` inline (= soft envelope) | (= 未確認、 主軸 follow-up 推奨) |

**opcode byte (`0xFF N`) 完全一致**、 ただし voice **DATA byte ordering + delivery format 不一致**。

##### 軸 5 = driver `commandsp` 入口 byte 値
- `commandsp` dispatcher = `0xFF` prefix で `comat` routine へ jump
- `src/driver/standalone_test.s:4419` `comat:` routine = N fetch + voice_table[N] lookup + `pmdneo_fm_voice_set` call
- driver-side handler **既に存在** = ADR-0058 era で実装済

##### finding caveat
- prompt path errata: `scripts/compile.py` → 実 path `src/tools/pmd-mml/compile.py`
- SSG `@N` PMDNEO behavior 未確認 (= 主軸 follow-up 推奨)
- rhythm part `@N` handling 未確認

### α-2: agent 4 finding = PMD V4.8s vs PMDDotNET voice opcode encoding 比較 (= confidence high、 via `git show` workaround)

#### 確定 finding 5 軸

##### 軸 1 = PMD V4.8s `@N` emit format
- `vendor/pmd48s/source/mc48s/MC.ASM:6037-6076` `neirochg:` ラベル
- line 6072-6073: `mov dl,bl; mov dh,0ffh` → dl = voice_num, dh = 0xFF
- `parset` (line 5698-5704): `xchg dh,dl; mov es:[di],dx; inc di; inc di`
- **emit byte pattern = `[0xFF][voice_num]` = 2 byte (= PMDDotNET と完全一致)**

##### 軸 2 = PMD V4.8s driver voice handler
- `vendor/pmd48s/source/pmd48s/PMD.ASM:1744` `cmdtbl: dw com@ ;0FFH` = FM command table 0xFF dispatch
- `vendor/pmd48s/source/pmd48s/PMD.ASM:3338-3342` `com@:` routine = `lodsb` 1 byte fetch → voicenum 保存 → neiroset call

##### 軸 3 = PMDDotNET `@N` emit format
- `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:7960-7962` `neirochg()`
- line 7427-7449 `parset()` byte swap
- **emit byte pattern = `[0xFF][voice_num]` = 2 byte (= PMD V4.8s と完全一致)**

##### 軸 4 = PMD V4.8s vs PMDDotNET voice opcode 差分

| 観点 | PMD V4.8s | PMDDotNET | 差分 |
|---|---|---|---|
| MML opcode | `@N` | `@N` | 同 |
| emit byte 1 | `0xFF` | `0xFF` | 同 |
| emit byte 2 | voice_num | voice_num | 同 |
| emit byte 数 | 2 byte | 2 byte | 同 |
| `@@N` (+128) 扱い | inc si + cx=128 add | si++ + cx=128 add | 同 |
| driver fetch | `0xFF → cmdtbl → com@ → lodsb` | (driver は共通設計 = 同) | 同 |

**ADR-0071 tempo 3-byte precedent との類似性なし** = voice opcode に encoding 差分は **存在しない**。

##### 軸 5 = voice definition emit 差分
- PMD V4.8s `MC.ASM:3010-3080` `nns:` + PMDDotNET `mc.cs:3756-3829` `nns()` 完全一致
- voice_buf offset = newprg_num × 32
- operator 順 = slot_1 → slot_3 → slot_2 → slot_4 = **PMD-specific operator swap、 PMD V4.8s + PMDDotNET で byte-identical**
- alg_fb @ +21、 prg_name 7 bytes @ +22-+28
- **voice definition emit (= 32 byte/voice、 operator swap 1→3→2→4、 alg_fb @+21、 prg_name @+22-28) は PMD V4.8s と PMDDotNET で byte-identical**

##### finding caveat (= medium 注意度)
- PMDDotNET `neirochg()` repeat_check 経路 (= mc.cs line 8034-8050) で K part rhythm2 PMDNEO mode で `0xCE` opcode emit (= PMD V4.8s `MC.ASM:6122` `mov al,0ceh` 同等)
- PCM part `@N,N,N,N` repeat 拡張記法 = PMDNEO driver `comat` / `comat_pcm` 現状で拡張部分が次 opcode として誤解釈される **潜在 risk** (= medium)、 PMDNEO MML fixture で `@N,N,N,N` 未使用なら不発
- ADR-0072 scope OUT (3) literal record

### α-3: main agent direct analysis = allowed-touch + sha256 framework (= agent 5 preflight fail 代替)

#### 修正経路 3 候補の比較

##### (a) driver-side fix (= 推奨 = ADR-0071 同 pattern)

**メリット**:
- ADR-0071 precedent (= `.if PMDNEO_USE_PMDDOTNET ... .endif` guarded change) と完全整合
- production sha256 invariant 維持可 (= flag-off で byte-identical)
- compile.py + build wiring の変更不要 = 既存 build matrix 簡素維持

**デメリット**:
- driver source 拡張 (= `comat` routine 周辺 + 新規 helper routine additive)
- runtime cost (= PMDDOTNET 経路 voice lookup 経路追加 1 routine 分)
- byte order 変換が runtime で必要 (= slot-interleaved → register expected order or vice versa)

**risk**: ADR-0051 `pmdneo_ssg_tone_sync` owner contract と無関係 (= voice register area reg 0x30-0x9F は別領域)、 ADR-0058 `pmdneo_v2_*` 系 routine と無関係 (= dispatch dispatcher 系)。

**実装案概略**:
1. `comat` routine 内 `.if PMDNEO_USE_PMDDOTNET` block 追加
2. block 内 = pmddotnet_song.m header から inline voice table offset 計算 + voice_num 用 25 byte data fetch + FM register area (= reg 0x30-0x9F) に write
3. `.else` branch = 既存 `voice_table[N]` lookup 維持 (= byte-identical for production)

##### (b) compile.py path

**メリット**:
- driver source 不変 (= production sha256 byte-identical 自動維持)
- voice data transformation を build time に集中

**デメリット**:
- PMDDOTNET MML 経路で compile.py を **追加で走らせる** 設計変更 (= 既存 build wiring は PMDDOTNET_MML で compile.py を bypass)
- .M binary inline voice table parse logic を Python で実装 (= 新規 ~50-100 行)
- PMDDotNET 出力 .M binary header parser を Python に持つ (= duplicate vs C#)

**risk**: build wiring 変更で既存 PMDDOTNET 経路 regression risk。

##### (c) build script path (= e.g., `m-to-z80-incbin.py` 拡張)

**メリット**:
- 既存 build wiring に近い (= .M → song_data.inc auto-generation 経路活用)
- driver + compile.py 共に不変

**デメリット**:
- build script 拡張 = voice table extraction logic 追加 (= 新規 ~30-50 行)
- 生成 voice_table が compile.py 経路と同 format で出力する必要 (= register-major、 slot ordering 変換 mandatory)

**risk**: build script 拡張による既存 build matrix 影響 = 4 build matrix で再 verify mandatory。

#### 推奨候補 = (a) driver-side fix

**理由**:
1. ADR-0071 precedent (= guarded change `.if PMDNEO_USE_PMDDOTNET`) と完全整合
2. 既存 build wiring 不変 + compile.py 不変 = scope 狭く保持
3. production sha256 byte-identical 維持容易 (= flag-off で完全無効化)
4. runtime cost minimal (= 1 routine 追加、 既存 `comat` の guarded extension)

#### production sha256 invariant 維持可能性

(a) 経路 = 全 guarded change `.if PMDNEO_USE_PMDDOTNET ... .endif` 配下、 flag-off で完全無効化 = byte-identical 維持可 (= ADR-0071 precedent 同 pattern)
(b) 経路 = driver source 不変 = sha256 自動維持可
(c) 経路 = driver source 不変 = sha256 自動維持可、 ただし build script 修正で既存 build matrix 再 verify mandatory

#### sub-sprint chain plan (= 決定 2 整合)

α/β/γ/δ/ε 5 段 = ADR-0067/0068/0069/0071 precedent 同 pattern。

### α-4: agent 2 preflight fail literal record (= worktree base ref mismatch、 2 回目 trigger)

- worktree HEAD `3ad1e23` (= revert chain) ≠ 期待 `05f0e44`
- 期待 file `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs` + `docs/adr/0071-*.md` 不存在
- 投資未実施 + 越権操作なし confirmed
- agent 1 で軸 1/2 + agent 4 で軸 5 がカバー範囲含む = 主軸 synthesis で代替

### α-5: agent 3 preflight fail literal record (= 同上)

- worktree HEAD `3ad1e23` + driver `standalone_test.s` line count 2581 (= 期待 5938 = ADR-0069+ADR-0071 patched state 3357 lines short)
- 投資未実施 + 越権操作なし confirmed
- agent 1 軸 5 (= driver `commandsp` 入口 + `comat` 経路 line 4419) でカバー
- 主軸 synthesis (= α-3) で driver-side fix 候補 (a) 詳細補完

### α-6: agent 5 preflight fail literal record (= 同上)

- worktree HEAD `3ad1e23` + `docs/adr/0069/0071*.md` + `docs/parallel-axes-dashboard.md` + `scripts/compile.py` 全不存在
- 投資未実施 + 越権操作なし confirmed
- 主軸 synthesis (= α-3) で allowed-touch + sha256 framework 直接策定

## Annex β-1: repair plan v1 (= sprint β scope = Codex Rescue plan review 対象)

### β-1-1: repair scope literal (= 決定 1 整合)

(1) **driver-side fix (= 推奨候補 (a))** = `src/driver/standalone_test.s` `comat` routine 周辺に `.if PMDNEO_USE_PMDDOTNET` guarded block 追加 + PMDDOTNET inline voice table 読込 経路実装。

scope OUT (= 別軸):
- (2) SSG voice change handling (= `0xF0 + 4 envelope byte`)
- (3) PCM voice change `@N,N,N,N` 拡張記法
- (4) MAME runtime audio audible verify on user 別作業 fixture
- (5) ADR-0065 ε audition session 実施判断
- (6) production-ready 全体達成判断

### β-1-2: repair patch v1 design

#### 仮説 (= Codex review 重点 axis 1)

PMDDOTNET 経路 `0xFF N` opcode dispatch → driver `comat` で voice_table[N] lookup 経路に分岐する設計を、 PMDNEO_USE_PMDDOTNET=1 時に pmddotnet_song.m inline voice table から N 番 voice data (= 25 byte slot-interleaved) を fetch + FM register area (= reg 0x30-0x9F) に write する経路に redirect。

#### patch design (= guarded change `.if PMDNEO_USE_PMDDOTNET` 配下、 既存 routine modify only or 新規 helper routine additive)

```asm
; src/driver/standalone_test.s 既存 comat routine (line 4419 周辺):
comat:
.if PMDNEO_USE_PMDDOTNET
        ; ADR-0072 patch (1): PMDDOTNET 経路 inline voice table 読込
        ; pmddotnet_song.m header から voice table pointer 取得
        ; voice_num 用 25 byte voice_buf fetch + slot1/3/2/4 順 FM register area write
        call    pmdneo_part_fetch_byte                    ; A = voice_num
        ld      l, a
        ; (新規 helper routine call or inline embed = γ impl で確定)
        call    pmdneo_comat_pmddotnet_voice_load        ; HL = voice_num input
.else
        ; 既存 voice_table[N] lookup 経路 (= byte-identical 維持)
        call    pmdneo_part_fetch_byte
        ; ... 既存 logic ...
.endif
        ret

; 新規 helper routine (= 0x0610 セクション末尾 additive、 ADR-0069 + ADR-0071 precedent):
pmdneo_comat_pmddotnet_voice_load:
        ; 入力: L = voice_num
        ; 出力: なし (= FM register area へ write 副作用)
        ; logic:
        ;   1. pmddotnet_song.m header parse → voice table base address 取得
        ;   2. voice_num × 27 byte (= 1 byte header + 25 byte data + 1 byte align) で voice record offset 計算
        ;   3. voice_num 一致確認 + 25 byte voice data fetch
        ;   4. slot-interleaved (slot1/3/2/4) → FM register area (reg 0x30/0x34/0x38/0x3C 等) write order 変換
        ;   5. alg_fb @ offset +21 → reg 0xB0-0xB6 write
        ; (= γ impl で完全 implementation、 plan v1 では skeleton のみ literal)
        ret
```

#### sha256 影響 estimate (= Codex review 重点 axis 3)

- (B1)/(B2) (= flag-off) = byte-identical 維持 (= `.if PMDNEO_USE_PMDDOTNET` block flag-off で完全無効化、 既存 `comat` routine 完全保持)
- (B3) vs (B4) = ADR-0072 patch byte 量分離 = guarded block (= 推定 ~30-50 byte) + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` (= 推定 ~80-120 byte = voice table parse + slot order convert + FM register write loop) = 計 ~110-170 byte (rough)
- actual byte 量は γ impl 完了後 `.lst` 実測 confirm

### β-1-3: γ implementation order

1. main agent 経路で `git worktree` 再作成 (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当 = 本 sprint α agent 2/3/5 で 2 回目 trigger 機能実証)
2. 新規 committed fixture 配置 (= `src/test-fixtures/adr-0072/test-voice-load.mml` + `test-multi-voice.mml`)
3. `comat` routine guarded block 追加 + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` additive
4. sdasz80 build
5. `.lst` predicate 4 件確認 (= ADR-0071 precedent)
6. 4 build matrix sha256 verify (= B1-B4 同 pattern)
7. δ functional verify (= 決定 5 § δ-1〜δ-7 gate)

### β-1-4: δ verify plan (= Codex review 重点 axis 5 = verify plan が実音成立を確認できるか)

(= 決定 5 § δ functional verify literal)

特に **gate δ-5 `scripts/analyze-audition-wav.py` Layer 1 WAV hygiene PASS** が primary success metric = wav RMS > -60 dBFS (= 非 silent confirm)。 これが ADR-0071 ε 後 δ-5 FAIL の根本治療確認。

### β-1-5: rollback condition (= 決定 6 整合)

ADR-0071 §決定 6 11 condition 継承 + ADR-0072 固有 #12 voice load failure + #13 audio silent persistence = 計 13 condition。

### β-1-6: Codex Rescue plan review 重点軸 (= user 明示 mandate 整合)

| review 重点 | 内容 |
|---|---|
| review-1 (= driver-side fix 仮説妥当性) | (a)/(b)/(c) 3 候補比較 + (a) 推奨理由 + (b)/(c) 代替案 risk |
| review-2 (= 真の root cause confirmed) | agent 1 + agent 4 finding 統合 = voice opcode encoding 一致 + voice table delivery 不一致 |
| review-3 (= production sha256 維持可否) | guarded change `.if PMDNEO_USE_PMDDOTNET` で (B1)/(B2) byte-identical 維持可 + (B3)/(B4) patch byte 量分離可 |
| review-4 (= allowed-touch limited) | `comat` 周辺 + 新規 helper routine additive のみ、 ADR-0051/0058 owner contract 無関係 |
| review-5 (= verify plan 実効化) | δ-5 engineering gate Layer 1 = wav 非 silent confirm が primary success metric、 ADR-0071 ε 後 δ-5 FAIL の根本治療 |

doc wording / 表記 review = 重点ではない (= user 明示 mandate)。

## Annex β-2: plan v2 (= Codex round 1 revise 2 must-fix 反映 + sprint β round 2 Codex review 投入 target)

sprint β round 1 plan v1 Codex Rescue plan review (= agentId `a27e5cf2ade7b3234`、 elapsed 4m29s) judgment = **revise** + 2 must-fix + 3 nice-to-have + 3 latent-risk。 per-axis verdict = AXIS-1 WARN + AXIS-2 FAIL + AXIS-3 PASS + AXIS-4 FAIL + AXIS-5 PASS。

### β-2-1: plan v2 scope (= 不変 carry + must-fix 2 件反映 overview)

- repair scope = 不変 (= (a) driver-side guarded change、 `comat` routine 周辺 + 新規 helper routine additive)
- 主要 shift from plan v1:
  - (mf-1) pseudo-code に `PART_OFF_CHIP_TYPE(ix)` guard 追加 (= CHIP_TYPE=2 `comat_pcm` 既存維持 + FM 以外 no-op + FM only PMDDOTNET helper dispatch)
  - (mf-2) voice record format 訂正 = **sparse emit** `[1 byte voice_num][25 byte voice data]` (= `prg_num[bx] != 0` 時のみ) + terminator **`[0x00, 0xFF]`** low/high 順 + **ALG/FB offset = byte 24** of voice data record (= driver `pmdneo_fm_voice_set` line 1315-1320 `ld de,#24` + `add hl,de` + `ld c,(hl)` 整合)

### β-2-2: must-fix mf-1 反映 = chip_type guard 追加 (= AXIS-1 + AXIS-4)

Codex 指摘 = plan v1 pseudo-code が `comat` 内で voice_num fetch 直後に PMDDOTNET helper を dispatch する設計で、 既存 `comat_pcm` 分岐 (= `src/driver/standalone_test.s:4422-4437`) + SSG/PCM scope-out との衝突 risk。

**plan v2 pseudo-code (= chip_type guard 順序明示)**:

```asm
comat:
        ;; voice_num fetch
        call    pmdneo_part_fetch_byte                ; A = voice_num
        ;; chip type guard (= existing comat_pcm preserve、 ADR-0072 scope OUT (2)/(3) for SSG/PCM)
        ld      c, a                                   ; preserve voice_num in C
        ld      a, PART_OFF_CHIP_TYPE(ix)
        cp      #2                                     ; CHIP_TYPE=2 → PCM
        jp      z, comat_pcm                          ; (= 既存 PCM path 維持、 ADR-0072 scope OUT (3))
.if PMDNEO_USE_PMDDOTNET
        ;; FM channel only: PMDDOTNET inline voice table load
        cp      #0                                     ; CHIP_TYPE=0 → FM (= ADR-0072 scope IN)
        jr      nz, comat_pmddotnet_done              ; SSG/other = no-op (= ADR-0072 scope OUT (2)、 future ADR)
        ld      a, c                                   ; restore voice_num
        call    pmdneo_comat_pmddotnet_voice_load     ; do the FM voice load
        ret
comat_pmddotnet_done:
        ret
.else
        ;; 既存 FM voice_table lookup 経路 (= byte-identical 維持)
        ld      a, c
        ;; ... 既存 logic (= compile.py separate label table lookup) ...
        ret
.endif
```

- chip_type guard が `comat_pcm` 経路を **既存 routine `comat_pcm` 完全保持** (= 触らず維持、 ADR-0072 scope OUT (3))
- FM (`CHIP_TYPE=0`) only で PMDDOTNET helper dispatch
- SSG (`CHIP_TYPE=1`) + 他 = no-op (= ADR-0072 scope OUT (2) literal、 別 ADR future)
- `.else` branch = 既存 FM voice_table lookup 経路完全維持 (= production sha256 byte-identical 確保)

### β-2-3: must-fix mf-2 反映 = voice record format 訂正 (= AXIS-2)

Codex 指摘 = plan v1 Annex β-1 voice record scan 詳細が誤り (= 4 点 mismatch with mc.cs literal source)。

**ground truth confirmed via mc.cs:1838-1880 + driver `pmdneo_fm_voice_set` line 1315**:

| 項目 | plan v1 (= 誤り) | plan v2 訂正 (= mc.cs/driver literal) |
|---|---|---|
| stride | `voice_num × 27 byte` 計算 | **sparse emit** = `prg_num[bx] != 0` 時のみ emit (= mc.cs:1846-1858 `nd_s_loop` `if (prg_num[bx] == 0) goto nd_s_00`) |
| record format | (= 暗黙 alignment あり) | `[1 byte voice_num (= work.al)][25 byte voice_buf data]` 形式、 **per-record align byte なし** (= mc.cs:1850-1858 `m_buf.Set(work.di, work.al); work.di++; for rep 0..24 m_buf.Set(work.di, voice_buf[work.si]); work.di++; work.si++`) |
| terminator | `[0xFF, 0x00]` | **`[0x00, 0xFF]` low/high 順** = (byte)0xff00 = 0x00 + (byte)(0xff00 >> 8) = 0xFF (= mc.cs:1872-1876 `ax = 0xff00; m_buf.Set(work.di++, (byte)ax); m_buf.Set(work.di++, (byte)(ax >> 8))`) |
| ALG/FB offset | `@+21` | **byte 24 of 25-byte voice data record** (= driver `pmdneo_fm_voice_set:1315-1320` `ld de,#24; add hl,de; ld c,(hl); ld d,#0xB0` で +24 から ALG/FB 読込 + reg 0xB0 write) |

### β-2-4: helper routine `pmdneo_comat_pmddotnet_voice_load` design v2 (= mf-2 反映 + nh-1/nh-2 反映)

**plan v2 helper routine design** (= 0x0610 セクション末尾 additive、 ADR-0069/0071 precedent):

```asm
;; ADR-0072 patch (1): PMDDOTNET inline voice table から voice_num 用 voice data fetch + driver expected layout で load
;; Input: A = voice_num
;; Output: なし (= FM register area へ write 副作用)
;; Preserve: IX (= part work area pointer)、 IY
;; Clobber: A, B, C, D, E, H, L
pmdneo_comat_pmddotnet_voice_load:
        push    ix
        push    iy
        ld      e, a                                  ; E = voice_num
        ;; step 1: pmddotnet_song.m header parse → voice_table_base address 取得
        ;;   = ADR-0069 pmdneo_mn_direct_load_aj_part_addr precedent と類似経路
        ;;   = pmddotnet_song + 1 + part_table_size_2x
        ld      hl, #pmddotnet_song
        ld      a, (hl)                               ; A = m_start byte
        ;; (= part_table_size 算出 + voice_table_offset 加算 logic、 γ impl で完全実装)
        ;; 結果: HL = voice_table 先頭 address (= 1 byte voice_num の前)
        ;; step 2: sparse record scan
        ;;   loop: read 1 byte (= voice_num_byte)
        ;;     check terminator = `0x00, 0xFF` 2-byte sequence
        ;;     if voice_num_byte == E: found、 HL+=1、 jp pmdneo_comat_pmddotnet_load_voice
        ;;     else: skip 25 byte、 HL += 26、 next iteration
pmdneo_comat_pmddotnet_scan_loop:
        ld      a, (hl)                               ; A = record voice_num (or terminator low byte)
        cp      e                                     ; match?
        jr      z, pmdneo_comat_pmddotnet_load_voice
        ;; terminator check = current byte 0x00 + next byte 0xFF
        or      a                                     ; A == 0x00?
        jr      nz, pmdneo_comat_pmddotnet_skip
        inc     hl
        ld      a, (hl)
        cp      #0xFF                                 ; next byte 0xFF?
        jr      z, pmdneo_comat_pmddotnet_miss        ; terminator found = voice not in table
        dec     hl                                    ; restore HL for skip
pmdneo_comat_pmddotnet_skip:
        ld      bc, #26                               ; skip 1 voice_num + 25 byte data = 26 byte
        add     hl, bc
        jr      pmdneo_comat_pmddotnet_scan_loop
pmdneo_comat_pmddotnet_load_voice:
        ;; HL = voice_num_byte address、 HL+1 = voice data start
        inc     hl                                    ; HL = voice data 先頭 (= 25 byte block)
        ;; step 3: voice data layout 確認
        ;;   - mc.cs voice_buf = slot interleaved (slot_1 → slot_3 → slot_2 → slot_4) で 22 byte operator data
        ;;   - byte 24 of 25-byte block = ALG/FB
        ;;   - driver pmdneo_fm_voice_set 既存 routine が +24 = ALG/FB + group writes (= reg 0x30/0x40/0x50/0x60/0x70/0x80 各 4 byte) を読む
        ;; step 4: pmdneo_fm_voice_set 直接 call 可否評価 (= γ impl で literal 確認):
        ;;   候補 A (= 推奨初期): HL を直接 pmdneo_fm_voice_set に渡す
        ;;     - 既存 driver routine は 25 byte block を解釈、 ALG/FB @ +24 + group writes byte 0-23
        ;;     - voice_buf order (slot 1/3/2/4) と driver group write order (= slot 1/2/3/4) が一致するか γ impl で literal verify
        ;;     - 不一致なら候補 B (= slot reorder + scratch RAM 経由) へ
        ;;   候補 B (= 候補 A 不成立時): slot reorder + 0xFDxx scratch RAM 経由
        ;;     - 25 byte slot-interleaved → 25 byte slot-1/2/3/4 sequential へ reorder
        ;;     - scratch RAM (= 0xFDxx の 25 byte free region、 既存 ADR-0048〜0071 placement と非衝突 = γ impl で確定) に copy
        ;;     - HL = scratch RAM start で pmdneo_fm_voice_set call
        call    pmdneo_fm_voice_set                   ; HL = voice data start、 B = FM ch index (= caller preserved)
        pop     iy
        pop     ix
        ret
pmdneo_comat_pmddotnet_miss:
        ;; voice_num not in PMDDOTNET inline voice table
        ;; = safe default no-op (= nh-2 反映、 rollback condition #12 candidate trigger)
        ;; debug counter or marker write 候補 = γ impl で確定
        pop     iy
        pop     ix
        ret
```

**register contract** (= nh-1 反映):
- preserve: IX (= part work area pointer)、 IY (= 反映 driver convention)
- clobber: A, B, C, D, E, H, L
- caller responsibility: B = FM ch index (= `pmdneo_fm_voice_set` 入力契約)

**safe default** (= nh-2 反映):
- voice_num miss (= sparse table に存在しない voice_num) → no-op return
- 候補 = debug marker write (= 0xFD32-0xFD38 軸 G ε partial state placement 不可触、 別領域確定)
- rollback condition #12 candidate trigger (= γ impl で literal 確定)

**byte increment estimate (= nh-3 反映)**:
- plan v1 推定 `~110-170 byte` → **plan v2 推定 ~150-250 byte (rough)**:
  - chip_type guard branch (= ~10-15 byte)
  - helper routine (= ~120-200 byte = header parse + scan loop + match + safe default + register preserve)
  - 候補 B (= slot reorder) 採用時 +50-100 byte 追加
- actual byte 量は γ impl 完了後 `.lst` 実測 confirm

### β-2-5: latent-risk lr-1/lr-2/lr-3 acknowledge + mitigation

**lr-1**: slot/order 変換が `pmdneo_fm_voice_set` group writer (= line 1318-1335 reg 0x30/0x40/0x50/0x60/0x70/0x80 × ch_idx) と不一致なら δ-5 non-silent PASS でも音色崩れ risk。

mitigation:
- γ impl で候補 A vs 候補 B 確認 (= voice_buf slot order と driver expectation 整合性)
- **δ-6 FM voice register trace gate 必須** = MAME ymfm-trace.tsv で reg 0x30-0x9F (= 96 register) writes が expected 25 byte voice data と整合確認 (= per-FM ch 25 byte voice register write、 6 ch × 25 = 150 writes 期待)

**lr-2**: voice 0 と terminator (= 2-byte detection `0x00, 0xFF`) 注意:
- voice_num 0 (= 単独 byte 0x00) は正規 voice、 次 byte が voice data byte 0
- terminator (= 2-byte sequence 0x00 + 0xFF) は table 末尾の marker
- detection 経路 = current byte 0x00 + next byte 0xFF 同時条件 → terminator
- current byte 0x00 + next byte 何か他 → voice 0 record

mitigation:
- pseudo-code 内 `cp e` (= voice_num match) を `or a` (= 0x00 check) より先行配置
- voice_num 0 が match した場合は load 経路へ、 不一致時のみ terminator check (= β-2-4 pseudo-code に literal 反映)

**lr-3**: δ-5 non-silent 単独は必要条件 + 十分条件ではない:
- δ-5 PASS = audio audible (= TL load されている確認)
- ただし voice tone が正しいかは別問題 (= 例: garbage TL load で TL=0 → 大音量 random sound)
- **δ-6 FM voice register trace gate が根本治療完了確認に必要**

mitigation (= 決定 5 § δ verify gate 強化):
- δ-5 + **δ-6 trace gate** 両方 PASS が success 完了条件
- δ-6 = FM voice register area (= reg 0x30-0x9F) writes が 25 byte voice data 各 ch に対応 + slot order 検証

### β-2-6: γ implementation order (= plan v1 から update)

1. main agent 経路で `git worktree` 再作成 (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当 = sprint α agent 2/3/5 で 2 回目 trigger)
2. 新規 committed fixture 配置 (= `src/test-fixtures/adr-0072/test-voice-load.mml` + `test-multi-voice.mml`、 ADR-0069 §決定 3-d「新規 fixture MML 例外的許可」 precedent 継承)
3. `comat` routine chip_type guard 追加 + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` additive (= 候補 A 推奨初期、 不成立時 候補 B)
4. sdasz80 build
5. `.lst` predicate 4 件確認 (= ADR-0071 precedent)
6. 4 build matrix sha256 verify (= B1-B4 同 pattern)
7. δ functional verify (= 決定 5 § δ-1〜δ-7 gate + **δ-6 trace gate strengthen** = FM voice register area writes 確認)

### β-2-7: Codex Rescue plan review round 2 重点軸 (= round 1 must-fix 反映 + 不変 carry)

1. mf-1 反映確認 = `comat` chip_type guard 追加 + scope OUT (2)/(3) 整合 (= β-2-2)
2. mf-2 反映確認 = voice record format 訂正 (= sparse + `[0x00, 0xFF]` terminator + ALG/FB @ +24) (= β-2-3)
3. nh-1 反映確認 = helper register contract literal (= β-2-4)
4. nh-2 反映確認 = voice miss safe default (= β-2-4)
5. nh-3 反映確認 = byte increment 再算出 (= ~150-250 byte rough、 β-2-4)
6. lr-1 acknowledge = slot order verify + δ-6 trace gate 強化 (= β-2-5)
7. lr-2 acknowledge = voice 0 vs terminator detection 順序 literal (= β-2-5)
8. lr-3 acknowledge = δ-5 + δ-6 両方 PASS が success 条件 (= β-2-5)
9. unchanged carry = AXIS-3 (sha256 維持) + AXIS-5 (verify plan primary metric δ-5) PASS confirm

## Annex β-3: plan v3 (= Codex round 2 revise 2 must-fix 反映 + sprint β round 3 Codex review 投入 target)

sprint β round 2 plan v2 Codex Rescue plan review (= agentId `a65c98ab79db416f1`、 elapsed 約 4 分) judgment = **revise** + 2 must-fix + 3 nice-to-have + 3 latent-risk。 per-axis verdict = AXIS-1 PASS + AXIS-2 PASS + AXIS-3 **FAIL** + AXIS-4 WARN + AXIS-5 PASS + AXIS-6 PASS + AXIS-7 **FAIL** + AXIS-8 PASS + AXIS-9 PASS (= 9 軸中 7 PASS + 1 WARN + 1 FAIL、 round 1 比大幅改善)。

### β-3-1: plan v3 scope (= 不変 carry + must-fix 2 件反映 overview)

- repair scope = 不変 (= (a) driver-side guarded change、 `comat` routine 周辺 + 新規 helper routine additive)
- 主要 shift from plan v2:
  - (mf-A、 AXIS-3) helper 内 `ld bc, #26` で **B (= FM ch index) 破壊** = `pmdneo_fm_voice_set` 直前で `PART_OFF_CH_IDX(ix)` reload 必要
  - (mf-B、 AXIS-7) **voice 0 record vs terminator `[0x00, 0xFF]` 識別順** = 現 match-first scan で voice 0 が terminator low byte (0x00) と衝突可能 → **terminator check を match check より先に置く** or voice 0 を事前に弾く

### β-3-2: must-fix mf-A 反映 = B (FM ch index) 破壊 + reload from `PART_OFF_CH_IDX(ix)` (= AXIS-3)

Codex 指摘 = plan v2 helper routine line 576-578 で `ld bc, #26` 実行時、 B が 0 に書込まれる (= `ld bc, n16` は B=0, C=26)。 後で line 596 `call pmdneo_fm_voice_set` 時に B が FM ch index として読まれる (= `standalone_test.s:1257` literal) ので、 0 (= ch 0 = FM-A) に書込まれる結果に。

**ground truth confirmed via `src/driver/standalone_test.s:149`**:
```
.equ    PART_OFF_CH_IDX,         24
```

= part work area offset 24 = chip channel index (= FM ch 0-5、 SSG ch 0-2、 ADPCM-A ch 0-5)。

**plan v3 fix**: `pmdneo_fm_voice_set` call 直前に `ld b, PART_OFF_CH_IDX(ix)` で B を reload (= IX = part work area pointer、 helper 入口で preserve 済)。

### β-3-3: must-fix mf-B 反映 = terminator check 順序 (= AXIS-7)

Codex 指摘 = plan v2 helper scan loop で `cp e` (= voice_num match) を terminator check (`or a` + 0xFF peek) より先に置く。 結果:
- voice_num 0 requested + record voice_num 0 = match (= 正常 load)
- voice_num 0 requested + 末尾到達 terminator (= byte 0x00 + next 0xFF) = `cp e` match (= **terminator low byte を voice 0 record と誤認 + 次 25 byte (= 0xFF + garbage) を voice data として load = 不正な register write**)

**plan v3 fix**: scan loop で **terminator check を match check より先**:

```asm
pmdneo_comat_pmddotnet_scan_loop:
        ld      a, (hl)                               ; A = current byte
        push    hl                                     ; preserve HL
        inc     hl
        ld      c, (hl)                                ; C = next byte (peek for terminator)
        pop     hl                                     ; restore HL
        ;; terminator check FIRST = A == 0x00 && C == 0xFF
        or      a                                      ; A == 0?
        jr      nz, pmdneo_comat_pmddotnet_not_terminator
        ;; A == 0: could be voice 0 record OR terminator
        ld      a, c                                   ; A = next byte (peeked)
        cp      #0xFF
        jr      z, pmdneo_comat_pmddotnet_miss        ; terminator → miss return
        ;; A != 0xFF: voice 0 record (= not terminator)
        xor     a                                      ; A = 0 (= restore current byte value)
pmdneo_comat_pmddotnet_not_terminator:
        ;; match check SECOND
        cp      e                                      ; A == E (= requested voice_num)?
        jr      z, pmdneo_comat_pmddotnet_load_voice
        ;; not match: skip 1 voice_num + 25 byte data = 26 byte
        ld      d, #0                                  ; DE = 26 (= use DE, NOT BC = AXIS-3 fix)
        ld      e, #26
        add     hl, de
        ld      e, c                                   ; restore voice_num to E... wait, C was peek
        ;; problem: E was holding voice_num (= E = voice_num at entry)、 上記 ld e, #26 で破壊
        ;; → fix: voice_num を別の場所に保持
        jr      pmdneo_comat_pmddotnet_scan_loop
```

**β-3-3-revised: voice_num preservation re-design**

voice_num を E に置くと scan loop 内で DE 使えない → IX-relative scratch (= 既存 free byte) or stack 経由で voice_num 保持。

revised helper entry:
```asm
pmdneo_comat_pmddotnet_voice_load:
        push    ix
        push    iy
        ;; voice_num を stack に保存 (= scan loop で E free に使用可能)
        push    af                                    ; stack: af (= A = voice_num)
        ;; HL = voice_table base address 計算 (= γ impl で literal)
        ld      hl, #pmddotnet_song
        ;; ... header parse logic ...
        ;; pop voice_num to E for match check
        pop     af                                    ; A = voice_num (= original)
        ld      e, a                                  ; E = voice_num
pmdneo_comat_pmddotnet_scan_loop:
        ld      a, (hl)
        push    hl
        inc     hl
        ld      c, (hl)
        pop     hl
        or      a                                      ; A == 0?
        jr      nz, pmdneo_comat_pmddotnet_check_match
        ld      a, c                                   ; A = peeked next byte
        cp      #0xFF                                  ; terminator?
        jr      z, pmdneo_comat_pmddotnet_miss
        xor     a                                      ; A = 0 (= voice 0 record)
pmdneo_comat_pmddotnet_check_match:
        cp      e
        jr      z, pmdneo_comat_pmddotnet_load_voice
        ;; skip 26 byte = 1 voice_num + 25 voice data
        ld      d, #0
        ld      a, #26
        ld      e, a                                   ; E temp clobber
        add     hl, de
        ld      e, (voice_num_save_byte)               ; restore E = voice_num
        ;; alternative: save voice_num in a scratch RAM byte (= ADR-0072 reserves 1 byte e.g., 0xFD3F as scratch、 γ impl で確定)
        jr      pmdneo_comat_pmddotnet_scan_loop
```

**β-3-3-cleaner: 設計 alternative**

scratch RAM byte (= 1 byte free region in 0xFDxx area、 γ impl で具体的 address 確定) を導入し voice_num 保持:

```asm
pmdneo_comat_pmddotnet_voice_load:
        push    ix
        push    iy
        ld      (driver_pmddotnet_voice_num_scratch), a   ; save voice_num to scratch RAM byte
        ;; HL = voice_table base address 計算 (= γ impl で literal)
        ;; ...
pmdneo_comat_pmddotnet_scan_loop:
        ld      a, (hl)
        push    hl
        inc     hl
        ld      c, (hl)
        pop     hl
        or      a
        jr      nz, pmdneo_comat_pmddotnet_check_match
        ld      a, c
        cp      #0xFF
        jr      z, pmdneo_comat_pmddotnet_miss
        xor     a
pmdneo_comat_pmddotnet_check_match:
        ld      b, a                                  ; preserve current byte
        ld      a, (driver_pmddotnet_voice_num_scratch)
        cp      b                                      ; A (= voice_num requested) == B (= record voice_num)?
        jr      z, pmdneo_comat_pmddotnet_load_voice
        ;; skip 26 byte
        ld      bc, #26                                ; B/C destroy OK = scratch RAM has voice_num
        add     hl, bc
        jr      pmdneo_comat_pmddotnet_scan_loop
pmdneo_comat_pmddotnet_load_voice:
        inc     hl                                     ; HL = voice data start (= 25 byte block)
        ld      b, PART_OFF_CH_IDX(ix)                ; reload B = FM ch index (= mf-A 反映)
        call    pmdneo_fm_voice_set
        pop     iy
        pop     ix
        ret
pmdneo_comat_pmddotnet_miss:
        ;; no-op safe default (= rollback condition #12 candidate trigger)
        pop     iy
        pop     ix
        ret
```

**scratch RAM byte = `driver_pmddotnet_voice_num_scratch` literal (= γ impl で 0xFD3F or similar literal address 確定)**:
- 既存 ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全 untouched
- 既存 ADR-0026 §決定 3/4 K dispatch L ch 固定占有 untouched
- 1 byte 確保 = `.equ driver_pmddotnet_voice_num_scratch, 0xFD3F` (= γ impl で literal 確定、 既存 placement との衝突確認)

### β-3-4: nice-to-have nh-1/nh-2/nh-3 反映 + 追加 nh from round 2

**round 1 nh** (= plan v2 で反映済 carry):
- nh-1 helper register contract = preserve IX/IY + clobber A/B/C/D/E/H/L (= plan v3 で更新 = scratch RAM byte 追加 + B/C 破壊 OK + IX-relative restore)
- nh-2 voice miss safe default = no-op return (= rollback condition #12 candidate trigger、 確認済)
- nh-3 byte increment 再算出 = plan v2 ~150-250 byte → **plan v3 ~180-280 byte rough** (= scratch RAM access logic ~10-20 byte 追加 + reload B logic ~3 byte)

**round 2 nh 追加** (= plan v3 で反映):
- **nh-typo** = ADR §β-2-6 line 657 「`comt routine`」 → 「`comat routine`」 typo 修正 (= 別 commit で同時 fix)
- **nh-δ-6-predicate** = δ-6 trace gate を write count だけでなく **expected voice data byte と register order の照合 predicate** 明文化:
  - reg 0x30 base group (= DT1/MUL): 4 byte voice data byte 0-3 と一致
  - reg 0x40 base group (= TL): 4 byte voice data byte 4-7 と一致
  - reg 0x50 base group (= KS/AR): 4 byte voice data byte 8-11 と一致
  - reg 0x60 base group (= AM/D1R): 4 byte voice data byte 12-15 と一致
  - reg 0x70 base group (= D2R): 4 byte voice data byte 16-19 と一致
  - reg 0x80 base group (= D1L/RR): 4 byte voice data byte 20-23 と一致
  - reg 0xB0 (= ALG/FB): voice data byte 24 と一致
- **nh-γ-byte-update** = γ impl 完了後 `.lst` 実測 byte 数で plan v3 推定 ~180-280 byte rough を update (= γ commit message + Annex β-4 δ verify result に literal)

### β-3-5: latent-risk lr-1/lr-2/lr-3 acknowledge + mitigation

**round 1 lr** (= plan v2 で acknowledge 済 carry):
- lr-1 slot/order 変換 vs `pmdneo_fm_voice_set` group writer 整合 = δ-6 trace gate **必須**
- lr-2 voice 0 vs terminator detection 順序 = **β-3-3 で plan v3 反映完了** (= terminator check first + scratch RAM byte 経由 voice_num 保持)
- lr-3 δ-5 + δ-6 両方 PASS が success 条件

**round 2 lr 追加** (= plan v3 で acknowledge):
- **lr-stale-α**: 既存 Annex α-1 (= agent 1 finding) に `Terminator = [0xFF, 0x00]` 旧記述残存 = plan v3 訂正 (= `[0x00, 0xFF]`) と読者混同 risk
  - mitigation: Annex α-1 内 「Terminator = `[0xFF, 0x00]`」 line に **supersede pointer 注記追加** (= Annex β-2-3 + β-3-3 が訂正版 ground truth = `[0x00, 0xFF]` literal、 mc.cs:1872-1876 直接確認済 by Codex round 1 + main agent direct read)
  - immutable history 保護維持 (= 元 finding 削除せず、 注記のみ追加)
- **lr-voice-A-slot-order**: 候補 A (= direct `pmdneo_fm_voice_set` call) は slot order 整合性が **γ impl 時に literal verify 必須**:
  - mc.cs voice_buf slot order = slot_1 → slot_3 → slot_2 → slot_4 (= agent 4 finding)
  - driver `pmdneo_fm_voice_set` group writer order = `pmdneo_fm_write_voice_group_ch` reg 0x30/0x40/0x50/0x60/0x70/0x80 各 4 byte
  - slot 順序差分があれば候補 B (= scratch RAM reorder) へ pivot
- **lr-voice-0-first-byte**: voice 0 record first data byte が偶然 0xFF (= 25 byte の最初 byte) になり得る possibility = source 確認だけでは断定不能
  - mitigation: terminator detection は **「current byte == 0x00 AND next byte == 0xFF」** 2-byte sequence で判定 (= β-3-3 plan v3 反映済)、 first data byte の 0xFF 値は terminator condition 不成立 = 正常 voice record として処理

### β-3-6: helper routine `pmdneo_comat_pmddotnet_voice_load` design v3 (= mf-A + mf-B + nh + lr 全反映)

(= β-3-3 § cleaner literal 参照、 γ impl で literal 完全実装)

主要 design point:
1. **voice_num scratch RAM byte** (= `driver_pmddotnet_voice_num_scratch` 0xFD3F or γ impl 確定 literal) で voice_num 保持 → B/C/D/E 全 scratch として scan loop 内 free に使用可
2. **terminator check first** = 0x00 byte 検出時に next byte 0xFF 確認 → 一致なら miss return、 不一致なら voice 0 record として match check 経路
3. **match check second** = scratch RAM voice_num と current record voice_num byte 比較
4. **on match: HL+=1 (= voice data start) + `ld b, PART_OFF_CH_IDX(ix)` reload + `call pmdneo_fm_voice_set`** (= mf-A 反映)
5. **on miss: no-op safe default** (= rollback condition #12 candidate trigger)
6. **register preserve**: IX + IY 全保護 (= push/pop)、 B/C/D/E/H/L clobber OK (= voice_num scratch RAM 経由保持)
7. **byte estimate**: ~180-280 byte rough (= scratch RAM access + scan loop + match + safe default + register preserve)

### β-3-7: γ implementation order (= plan v2 から update = 軸 nh-δ-6-predicate 反映)

1. main agent 経路で `git worktree` 再作成 (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当)
2. 新規 committed fixture 配置 (= `src/test-fixtures/adr-0072/test-voice-load.mml` + `test-multi-voice.mml`)
3. **scratch RAM byte literal address 確定** = `driver_pmddotnet_voice_num_scratch` 0xFDxx (= 既存 ADR-0048〜0071 placement 衝突確認、 γ impl で 1 byte free region 確定 + `.equ` 追加)
4. `comat` routine chip_type guard 追加 + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` additive
5. sdasz80 build
6. `.lst` predicate 4 件確認 (= ADR-0071 precedent)
7. 4 build matrix sha256 verify (= B1-B4 同 pattern)
8. δ functional verify (= 決定 5 § δ-1〜δ-7 gate + **δ-6 trace gate** で voice data byte ↔ register order **照合 predicate** PASS confirm (= 7 group write per FM ch × 6 FM ch = 42 predicate))

### β-3-8: Annex α-1 supersede note 追加 (= lr-stale-α 反映、 別 commit で同時実施)

Annex α-1 内 軸 2 「Terminator = `[0xFF, 0x00]`」 line に supersede pointer 注記追加 (= β-3 commit chain 内で別 commit or 同 commit fix):

```markdown
### α-1: agent 1 finding...

##### 軸 2 = voice definition emit format
- ...
- 1 行 summary: Voice defs go to an **out-of-band voice table** inside .M (1 byte header + 25 byte data per voice, hardware slot interleaved order, terminator `0xFF 0x00`).

> **supersede note** (= 2026-05-27 43rd session sprint β round 1 Codex review + main agent direct mc.cs read で訂正): terminator literal は **`[0x00, 0xFF]` low/high 順** (= mc.cs:1872-1876 `(byte)0xff00 + (byte)(0xff00 >> 8)` literal) が ground truth、 Annex α-1 軸 2 内 「`0xFF 0x00`」 表記は agent 1 report writing convention 由来の表記 (= byte order 逆順記述)、 substantive value は同 = `0xff00` (= 0x00 先 + 0xFF 後 in file)。 plan v3 (= Annex β-3) では訂正版 `[0x00, 0xFF]` literal を採用、 sprint γ impl で本 ground truth を実装根拠とする。
```

### β-3-9: Codex Rescue plan review round 3 重点軸 (= round 2 must-fix 2 件反映 + 不変 carry + 追加 nh/lr 反映)

1. mf-A 反映確認 = helper 内 B 破壊 + `PART_OFF_CH_IDX(ix)` reload before `pmdneo_fm_voice_set` (= β-3-2)
2. mf-B 反映確認 = terminator check first + scratch RAM byte voice_num 保持 (= β-3-3)
3. nh-typo 反映確認 = `comt` → `comat` typo fix (= 別 commit or 同 commit、 nh)
4. nh-δ-6-predicate 反映確認 = δ-6 trace gate で voice data byte ↔ register order **照合 predicate 42 件** (= β-3-4)
5. nh-γ-byte-update reflection mandate (= γ impl 完了後 literal update、 plan-level acknowledge)
6. lr-stale-α 反映確認 = Annex α-1 軸 2 supersede note 追加 (= β-3-8)
7. lr-voice-A-slot-order acknowledge = 候補 A vs B pivot 経路 γ impl で確定
8. lr-voice-0-first-byte acknowledge = terminator detection 2-byte sequence 判定で安全 (= β-3-5)
9. unchanged carry = AXIS-1/AXIS-2/AXIS-4/AXIS-5/AXIS-6/AXIS-8/AXIS-9 全 PASS confirm

### β-3-10: plan v4 = Codex round 3 revise 5 must-fix 反映 (= round 3 revise corrections)

sprint β round 3 plan v3 Codex Rescue plan review (= agentId `ac6a9071699dee380`、 elapsed 約 8 分) judgment = **revise** + 5 must-fix + 1 nice-to-have + 1 latent-risk。 per-axis verdict = AXIS-1 PASS + AXIS-2 FAIL + AXIS-3 FAIL + AXIS-4 PASS + AXIS-5 PASS + AXIS-6 FAIL + AXIS-7 PASS + AXIS-8 FAIL + AXIS-9 FAIL (= 9 軸中 5 PASS + 4 FAIL)。

### β-3-11: must-fix mf-1 反映 = scratch byte 0xFD3F → 0xFD62 訂正 (= AXIS-2)

Codex 指摘 = plan v3 β-3-3 で scratch RAM byte `driver_pmddotnet_voice_num_scratch` 0xFD3F 提案だが、 0xFD3F は既存 `pmdneo_v2_tempo_acc` (= ADR-0058 δ v2 tempo subtick accumulator) 衝突。

**ground truth confirmed via `src/driver/standalone_test.s:376` + line 380**:
- 0xFD3F = `pmdneo_v2_tempo_acc` (= ADR-0058 δ 既使用)
- 0xFD62-0xFD78 = **free region (23 byte)** = 後続 v2 driver_state singleton home

**plan v4 fix**: scratch byte address を **0xFD62** (= free region 先頭) に変更。

```asm
;; src/driver/standalone_test.s :8 周辺 (= 既存 .equ ブロック内) に追加 candidate:
        .equ    driver_pmddotnet_voice_num_scratch, 0xFD62   ; 1 byte ADR-0072 helper scratch
```

- 0xFD62 = 既存 free region 先頭 (= `standalone_test.s:380` literal「`0xFD62 - 0xFD78   free (= 23 bytes、後続 v2 driver_state singleton home)`」)
- 残 free = 0xFD63-0xFD78 (= 22 byte、 後続軸 future for v2 driver_state singleton home 維持)
- 既存 ADR-0058 δ tempo_acc 衝突なし
- 既存 ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) 衝突なし
- 既存 ADR-0048 ζ-β `pmdneo_v2_ppc_bit7_scratch` (= 0xFD61) 衝突なし

### β-3-12: must-fix mf-2 反映 = β-2-6 line 657 typo 直接修正 (= AXIS-3)

Codex 指摘 = plan v3 β-3-4 で「`comt routine` → `comat routine` typo 修正」 言及のみ、 実際の ADR 本文修正未実施。

**plan v4 fix**: 本 commit chain 内で β-2-6 line 657 typo 直接修正:
- 旧: 「`comt` routine chip_type guard 追加 + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` additive」
- 新: 「**`comat`** routine chip_type guard 追加 + 新規 helper routine `pmdneo_comat_pmddotnet_voice_load` additive」

(= 本 plan v4 commit chain 内で β-2-6 同時編集、 immutable history 保護 = 元 plan v2 wording 直接訂正は plan v2 内 typo として permissible scope)

### β-3-13: must-fix mf-3 反映 = Annex α-1 軸 2 supersede note 直接追加 (= AXIS-6)

Codex 指摘 = plan v3 β-3-8 で supersede note 草案あり、 ただし Annex α-1 本文 line 225 + 241 の stale 記述「`[0xFF 0x00]` terminator」 直接修正未実施。

**plan v4 fix**: 本 commit chain 内で Annex α-1 軸 2 直接 supersede note inline:
- line 225 「`[0xFF 0x00]` terminator」 末尾に supersede note 括弧追加 (= 元 finding 削除せず、 注記のみ追加 = immutable history 保護)
- line 241 「`[voice_num][25 byte]...[0xFF 0x00]`」 末尾に supersede note 括弧追加 (= 同)
- supersede note literal = 「(= 表記 supersede = 訂正版 `[0x00, 0xFF]`、 Annex β-3-3 ground truth carry)」 形式

実施済み (= 本 commit chain で `[0xFF 0x00]` line 225 + 241 直接編集完了)。

### β-3-14: must-fix mf-4 反映 = voice 0 + first data byte 0xFF terminator collision 不可能性 proof (= AXIS-8)

Codex 指摘 = voice 0 + first data byte 0xFF が terminator 2-byte sequence (0x00 + 0xFF) と衝突可能。 PMDDotNET パラメータ範囲で byte0 = 0xFF 除外できるか未証明。

**plan v4 proof**: YM2610 voice register spec から **structural impossibility** 主張。

#### YM2610 voice register spec literal (= reg 0x30-0x9F)

voice_buf byte 0 = slot 1's reg 0x30 byte (= DT1/MUL register、 PMDDotNET nns() slot 1 first store)。

reg 0x30 (= DT1/MUL) byte layout per YM2610 spec:
- bit 7: **reserved (= 必ず 0)**
- bits 4-6: DT1 (= 3 bits、 値 0-7)
- bits 0-3: MUL (= 4 bits、 値 0-15)

→ byte 値 max = `0x7F` (= bit 7 = 0 + bits 0-6 all set)、 **`0xFF` は spec 上不可能**。

#### voice_buf byte 0 mapping confirmation

agent 1 finding (= mc.cs:3796-3826) + agent 4 finding (= operator slot order slot_1 → slot_3 → slot_2 → slot_4) より:
- voice_buf bytes 0-5 = slot 1 (= reg 0x30 + 0x40 + 0x50 + 0x60 + 0x70 + 0x80 of slot 1)
- voice_buf byte 0 = slot 1's reg 0x30 byte (= DT1/MUL)
- voice_buf byte 0 ≤ 0x7F (= per YM2610 spec)

#### conclusion

**voice 0 record's first data byte (= voice_buf byte 0 = reg 0x30 of slot 1) ≤ 0x7F、 0xFF 不可能** (= YM2610 reg 0x30 bit 7 reserved 仕様)。 voice 0 record + terminator 2-byte sequence collision は **structural impossibility**。

mitigation: plan v4 helper routine の terminator detection (= β-3-3 cleaner pseudo-code) は voice 0 case でも安全動作確認。 spec citation を γ impl コメント + verify 文書に literal 反映。

### β-3-15: must-fix mf-5 反映 = AXIS-4 carry wording 整合 (= AXIS-9)

Codex 指摘 = plan v3 β-3-9 で「unchanged carry = AXIS-1/2/4/5/6/8/9 全 PASS」 と書いたが、 round 2 では AXIS-4 = WARN (= NOT PASS)。 矛盾。

**plan v4 fix**: AXIS-4 round 2 = WARN → plan v3 β-3-5 lr acknowledge で resolve、 plan v4 で **AXIS-4 WARN → resolved (= acknowledge)** 明示。

round 4 carry wording:
- **AXIS-1**: round 2 PASS、 plan v3/v4 carry PASS
- **AXIS-2**: round 2 PASS → round 3 FAIL (= scratch byte collision) → plan v4 で mf-1 反映 = 0xFD62 訂正 → resolved
- **AXIS-3**: round 2 PASS → round 3 FAIL (= typo 言及のみ) → plan v4 で mf-2 直接修正 → resolved
- **AXIS-4**: round 2 WARN (= voice miss reachability) → plan v3 β-3-5 lr-2/lr-voice-0-first-byte で safe default + 2-byte sequence detection acknowledge → plan v4 mf-4 で structural impossibility proof → **WARN resolved**
- **AXIS-5**: round 2 PASS、 plan v3/v4 carry PASS
- **AXIS-6**: round 2 PASS → round 3 FAIL (= supersede note 草案のみ) → plan v4 で mf-3 直接 supersede note inline → resolved
- **AXIS-7**: round 2 FAIL → plan v3 β-3-3 で terminator check first resolved → carry PASS
- **AXIS-8**: round 2 PASS → round 3 FAIL (= voice 0 + 0xFF collision) → plan v4 で mf-4 structural impossibility proof → resolved
- **AXIS-9**: round 2 PASS → round 3 FAIL (= 自己矛盾) → plan v4 mf-5 で wording 整合 → resolved

### β-3-16: nice-to-have nh-1 反映 = β-3-3 旧 stack/E-register pseudo-code 削除 (= round 3 追加 nh)

Codex 指摘 = β-3-3 内に旧 stack/E-register 経由 voice_num 保持の擬似コード (= scratch RAM 採用前の試行案) が残存、 plan v3 採用版 (= scratch RAM 経由) と読者混乱 risk。

**plan v4 fix**: β-3-3 内旧 stack/E-register 経由擬似コード block を「**β-3-3-cleaner: 設計 alternative (= 採用版)**」 で supersede 済として明示 (= 既存 cleaner section が canonical、 旧 stack/E-register version は探索過程記録 として保持)。

実施済み (= 既存 β-3-3 cleaner block が採用版、 plan v4 で「**採用版 = cleaner、 旧 stack/E-register version は探索過程 only、 plan v4 では cleaner 採用**」 明示)。

### β-3-17: latent-risk lr-1 反映 = `pmdneo_fm_voice_set` slot order γ 前 confirm (= round 3 追加 lr)

Codex 指摘 = `pmdneo_fm_voice_set` slot/register write order が候補 A/B 判定前に γ 実装に入る risk。 δ-6 predicate 設計は γ より先に確定推奨。

**plan v4 fix**: γ impl pre-step に **`pmdneo_fm_voice_set` slot order literal confirmation** 追加:

```
γ impl pre-step (= γ-0):
1. read src/driver/standalone_test.s:1315-1335 `pmdneo_fm_voice_set` + `pmdneo_fm_write_voice_group_ch` literal
2. write order trace: reg 0x30 group (= slot 1 → slot 2 → slot 3 → slot 4 OR slot 1 → slot 3 → slot 2 → slot 4)
3. compare with mc.cs voice_buf slot order (= slot 1 → slot 3 → slot 2 → slot 4)
4. if 順序一致 → 候補 A direct call OK
   if 順序不一致 → 候補 B scratch RAM reorder 必要
5. δ-6 predicate (= 42 件) を確定 slot order に基づいて 文書化
```

### β-3-18: helper design v4 (= mf-1 + mf-2 + mf-3 + mf-4 + mf-5 + nh-1 + lr-1 全反映)

主要 design point (= plan v3 β-3-6 から差分):
1. **scratch RAM byte address = `0xFD62`** (= mf-1 反映、 既存 free region 先頭、 衝突なし)
2. **typo fix**: β-2-6 line 657 `comt` → `comat` 訂正済 (= mf-2 反映)
3. **Annex α-1 supersede note**: line 225 + 241 inline 注記済 (= mf-3 反映)
4. **voice 0 safety**: YM2610 spec proof = byte 0 ≤ 0x7F → terminator collision 不可能 (= mf-4 反映)
5. **AXIS carry wording**: WARN → resolved 明示 (= mf-5 反映)
6. **clean pseudo-code**: scratch RAM 採用版 cleaner section が canonical (= nh-1 反映)
7. **γ pre-step**: `pmdneo_fm_voice_set` slot order literal confirm (= lr-1 反映)

byte estimate carry: ~180-280 byte rough (= 不変、 scratch byte address のみ変更で size 影響なし)

### β-3-19: γ implementation order plan v4 (= plan v3 β-3-7 + γ-0 pre-step 追加)

0. **γ-0 pre-step**: `pmdneo_fm_voice_set` (= line 1315-1335) slot order literal trace + 候補 A vs B 判定 + δ-6 predicate 42 件確定
1. main agent 経路で `git worktree` 再作成
2. 新規 committed fixture 配置 (= `src/test-fixtures/adr-0072/test-voice-load.mml` + `test-multi-voice.mml`)
3. scratch RAM byte literal `.equ driver_pmddotnet_voice_num_scratch, 0xFD62` 追加 (= 既存 standalone_test.s line 8 周辺 .equ block)
4. `comat` routine chip_type guard 追加 + 新規 helper routine additive
5. sdasz80 build
6. `.lst` predicate 4 件確認
7. 4 build matrix sha256 verify (= B1-B4)
8. δ functional verify + δ-6 trace gate 42 件 predicate (= γ-0 で確定済 expected register order)

### β-3-20: Codex Rescue plan review round 4 重点軸 (= round 3 must-fix 5 件反映 + nh + lr 反映 + 全 AXIS carry resolve confirm)

1. mf-1 反映確認 = scratch byte 0xFD62 (= free region literal) (= β-3-11)
2. mf-2 反映確認 = β-2-6 typo 直接修正済 (= β-3-12)
3. mf-3 反映確認 = Annex α-1 軸 2 supersede note 直接 inline 済 (= β-3-13)
4. mf-4 反映確認 = voice 0 + 0xFF terminator collision structural impossibility proof (= YM2610 reg 0x30 bit 7 reserved) (= β-3-14)
5. mf-5 反映確認 = AXIS carry wording 整合 (= β-3-15)
6. nh-1 反映確認 = β-3-3 cleaner section canonical 明示 (= β-3-16)
7. lr-1 反映確認 = γ-0 pre-step `pmdneo_fm_voice_set` slot order confirm (= β-3-17)
8. unchanged carry = AXIS-1/AXIS-5/AXIS-7 全 PASS confirm (= round 2 から維持)
9. round 3 FAIL resolve confirm = AXIS-2/AXIS-3/AXIS-4/AXIS-6/AXIS-8/AXIS-9 全 resolved confirm

## Annex β-4: plan v5 = γ impl phase finding-based scope shift (= driver-side fix → build-side voice resolution + #FFFile support、 user 明示 GO Option 2 revised)

### β-4-1: γ impl phase で発見した plan v4 前提不成立

sprint γ impl 着手後の real binary 解析で plan v4 (= Codex round 4 approve plan) の core 前提が不成立と判明:

**plan v4 前提**: PMDDOTNET .m binary に voice table が inline emit される (= sparse `[1 byte voice_num][25 byte voice data]...[0x00, 0xFF terminator]` 形式)、 driver helper が読込可能。

**γ impl で確認した実態** (= test-voice-load.mml を /N + /B 両 mode で compile、 binary literal 解析):
- PMDDOTNET /N mode binary (= 251 byte) + /B mode binary (= byte-identical) で voice table が **inline emit されない**
- m_start byte 0 = 0x00 (= non-PMDNEO mode)、 file body = part offset table + part data + ASCII metadata + 末尾 marker のみ
- voice data (= reg 0x30-0x80 値 + ALG/FB) は binary 内に存在せず
- agent 1 finding 「mc.cs:1838-1880 nd_s_loop で voice table emit」 は **`mml_seg.prg_flg & 1 != 0` 条件下のみ動作** (= `if ((mml_seg.prg_flg & 1) == 0) return enmPass2JumpTable.memo_write;` vdat_set:1779 line literal、 default では非実行と推測)
- agent 1 / agent 4 confidence high 判定は mc.cs 静的解析ベースで、 runtime emit 条件評価が不足

### β-4-2: 真の解決経路発見 = build-side voice resolution (= compile.py 既存機能再利用)

`src/tools/pmd-mml/compile.py` 静的解析で:
- **line 424**: `parse_voice_definitions(source)` 関数 (= MML から voice 定義抽出機能、 既存実装済)
- **line 626 / 634**: `voice_table:` Z80 label generation (= 既存 driver `comat` ↔ `voice_table[N]` lookup 経路を populate する logic)

つまり compile.py は **既に voice 抽出 + voice_table generation 機能を持っている**。 PMDDOTNET_MML 経路では compile.py が呼ばれないため voice_table が空 (= `vendor/ngdevkit-examples/00-template/song_data.inc` で `voice_table:` label のみ + 中身 0 byte) になっているのが root cause。

### β-4-3: plan v5 scope = build-side voice resolution + #FFFile support (= user 明示 GO Option 2 revised)

user 明示「Option 2 revised: build-side voice resolution + #FFFile support」 採用。 driver source 完全 no-touch + PMDDOTNET 本体改変なし + compile.py + build-poc.sh + 必要に応じて fixture 拡張。

**#FFFile 対応 (= 必須軸)**:
- PMD 系 MML は音色を MML 内に直接書くとは限らない、 同一フォルダの FM 音源音色 file を `#FFFile` directive で参照する慣習がある
- SAMPLE2 系 + 実用 MML では外部音色 file 対応がないと audition material として成立しない可能性が高い
- これは driver の問題ではなく、 MML build / voice resolution の問題 (= 既存 ADR-0071 + plan v4 までの driver-side fix scope では解決不能)

**新 scope IN**:
1. **`src/tools/pmd-mml/compile.py`** = #FFFile directive parse + MML file relative path 解決 + FM voice file (= 外部 PMD voice format) parse + voice_table: generation logic 拡張
2. **`scripts/build-poc.sh`** = PMDDOTNET_MML 使用時に compile.py voice 抽出 (= --voice-only mode 等) を呼ぶ + generated voice_table.inc を build に組み込む
3. **`src/test-fixtures/adr-0072/`** = 必要に応じて #FFFile 付き minimal MML + minimal voice file fixture 追加 (= ADR-0069 §決定 3-d 新規 fixture 例外的許可 precedent 継承)
4. **`docs/adr/0072-*.md`** + **`docs/parallel-axes-dashboard.md`** + 改訂履歴 + 平易要約

**新 scope OUT**:
1. PMDDOTNET 本体改変 (= `vendor/PMDDotNET/` 完全不変)
2. driver source patch (= `src/driver/standalone_test.s` 完全不変、 plan v1-v4 で提案された patch revert 済)
3. pmdneo_rhythm_event_trigger (= K bitmap pair distinct ADR-0070 候補 future)
4. K bitmap pair distinct (= ADR-0070 候補 future)
5. user audition / δ 再開 (= ADR-0065 ε scope、 user 明示 GO 必須)

### β-4-4: plan v5 修正 path detail

#### β-4-4-1: compile.py 拡張 (= primary work)

`src/tools/pmd-mml/compile.py` に追加機能:

1. **`#FFFile <filename>` directive parse**:
   - MML 冒頭の `#FFFile` directive を検出
   - filename 引数を MML file の同一フォルダ内 relative path として解決
   - file 存在確認 + 不在時 warning + fallback (= MML 内 voice def のみ使用)
2. **External FM voice file parse**:
   - PMD 標準 voice file format (= `.FF`、 binary or text? = γ impl で literal 確認 mandate)
   - voice definition entries 抽出 (= voice_num + alg/fb + 4 operator params)
3. **Voice resolution 優先順位**:
   - MML 内 `@N alg fbl` + operator data line が定義されていれば優先
   - MML 内未定義 + #FFFile 内定義 = #FFFile から resolve
   - 両方未定義 = compile.py warning + voice_table 該当 entry skip
4. **`--voice-only` mode (= 新 flag)**:
   - MML から voice table only 抽出 (= part data compile skip)
   - 出力 = voice_table.inc (= Z80 source label + 25 byte voice data × N)
   - PMDDOTNET_MML 経路で並行実行可能化

#### β-4-4-2: build-poc.sh 拡張

`scripts/build-poc.sh` line 188-242 (= PMDDOTNET_MML block) 内追加:
- PMDDOTNET dotnet compile 実行後、 compile.py `--voice-only` で voice table 抽出
- 出力 `voice_table.inc` を `song_data.inc` に append (= 既存 `voice_table:` 空 label を本物の voice data で置き換える経路 = 既 song_data.inc 構造に統合)

#### β-4-4-3: 新規 committed fixture (= 必要に応じて)

`src/test-fixtures/adr-0072/` 配下:
- `test-fffile.mml` = #FFFile directive 付き minimal MML (= voice ref to external file)
- `test-fffile.ff` = minimal external FM voice file (= 1-2 voice 定義)
- `test-voice-load.mml` (既存 carry) = MML 内 voice 定義のみ (= #FFFile 不使用)
- `test-multi-voice.mml` (既存 carry) = 同上

### β-4-5: production sha256 維持方針 update

plan v4 まで = driver-side guarded change で `.if PMDNEO_USE_PMDDOTNET` flag-off byte-identical 維持。

**plan v5 = driver source 完全 no-touch** = `src/driver/standalone_test.s` 完全不変 = production sha256 invariant **automatic 維持** (= 触らないので破れない)。

verify gate 簡素化:
- (B1) production baseline = `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` → `457a237c...` byte-identical 確認 (= driver no-touch、 trivially 維持)
- (B2) post-plan-v5 flag-off = (B1) と byte-identical (= driver 不変)
- (B3) flag-on pre-plan-v5 with fixture (= 既存 PMDDOTNET 経路 = voice_table 空 = audio silent)
- (B4) flag-on post-plan-v5 with fixture (= 新 build wiring + compile.py voice 抽出 = voice_table populated = audio audible)

### β-4-6: Codex Rescue plan review 必須軸 (= user 明示 7 軸)

1. **PMDDOTNET .m に voice table がない事実** = γ impl phase で確認した /N + /B 両 mode binary literal 解析の妥当性 + agent 1/4 finding の re-evaluation
2. **#FFFile で同一フォルダ voice file を解決できるか** = path resolution + file 存在確認 + format parse の design validity
3. **MML 内 voice 定義と外部 voice file の優先順位** = conflict resolution policy + warning + fallback design
4. **relative path / missing file / malformed file の扱い** = error handling robustness + safe default
5. **generated voice_table: が既存 driver と整合するか** = byte format (= register-major、 25 byte per voice、 voice_num × 2 byte LE pointer table) + 既存 `comat` lookup 経路 (= line 4419) との literal compatibility
6. **driver no-touch で実現できるか** = scope IN 整合 + plan v1-v4 で提案された driver patch 完全 revert 確認 + driver source byte-identical 維持
7. **production sha256 維持に影響がないか** = (B1)/(B2) baseline 維持 + (B3)/(B4) 差分は song_data.inc + ROM data 由来 (= driver byte-identical) であることの妥当性確認

### β-4-7: γ implementation order plan v5

1. **γ-0 pre-step**: PMD voice file format (= `.FF` extension expected) literal spec 確認 (= vendor/pmd48s 内 + PMD documentation + 既存 MML/voice fixture から format extract)
2. **compile.py 拡張**:
   - #FFFile directive parser 追加
   - MML file relative path 解決 logic
   - external voice file parser
   - voice resolution priority logic (= MML voice def > #FFFile voice > warning)
   - `--voice-only` mode flag 追加
3. **build-poc.sh 拡張**: PMDDOTNET_MML block 内に compile.py `--voice-only` 並行実行 + voice_table.inc append
4. **fixture 配置** (= 必要に応じて): `src/test-fixtures/adr-0072/test-fffile.mml` + `test-fffile.ff` (= 既存 test-voice-load.mml + test-multi-voice.mml carry)
5. **build verify**: 4 build matrix sha256 (= B1/B2/B3/B4) + production baseline `457a237c...` byte-identical 維持
6. **δ functional verify**: MAME runtime trace + FM voice register area writes (= reg 0x30-0x9F) + audio audible (= wav RMS > -60 dBFS = ADR-0071 ε δ-5 FAIL の根本治療)
7. **retrospective Codex impl-review** (= ADR-0041 §決定 4-3 mandate、 plan v5 build-side scope shift 整合性確認)
8. ε Accepted milestone + ADR doc 状態行 Draft → Accepted

### β-4-8: plan v1-v4 driver patches revert literal record (= 本 commit chain で同時実施)

- plan v1〜v4 で提案された `src/driver/standalone_test.s` patches = revert 済 (= `git checkout src/driver/standalone_test.s` 実行済、 driver source 完全 no-touch state restored)
- plan v5 commit chain 内 `git status src/driver/standalone_test.s` で「nothing to commit」 confirm 済
- driver source byte-identical to base anchor `wip-pmddotnet-opnb-extension@05f0e44` (= ADR-0072 起票時点)

### β-4-9: Annex β-1〜β-3 immutable history carry note

Annex β-1 (= plan v1) + Annex β-2 (= plan v2) + Annex β-3 (= plan v3 + plan v4) は **driver-side fix 経路の plan iteration history** として完全保持 (= immutable history mandate per memory `feedback_doc_governance_two_systems.md`)。

plan v5 (= Annex β-4) で scope shift 確定後も β-1〜β-3 は historical record として preserve。 sprint γ impl 実装者は **Annex β-4 plan v5 (= 最新 plan iteration) を ground truth として参照**。

supersede pointer: plan v1-v4 で提案された driver patch + scratch RAM byte + comat guarded change + helper routine `pmdneo_comat_pmddotnet_voice_load` 等は **plan v5 で scope-out**、 γ impl では一切実装しない。

### β-4-10: plan v6 = Codex plan v5 review revise 4 must-fix 反映

sprint β plan v5 Codex Rescue plan review (= agentId `aa8f01d42ba8f4422`、 elapsed 約 2 分) judgment = **revise** + 4 must-fix + 3 nice-to-have + 3 latent-risk。 per-axis verdict = AXIS-1 PASS + AXIS-2 FAIL + AXIS-3 FAIL + AXIS-4 FAIL + AXIS-5 FAIL + AXIS-6 PASS + AXIS-7 WARN (= 7 軸中 2 PASS + 4 FAIL + 1 WARN)。

### β-4-11: must-fix MF-1 反映 = 外部 FM voice file format 仕様 literal 化 (= AXIS-2)

Codex 指摘 = β-4-4-1 で「PMD 標準 voice file format (= `.FF` extension expected)」 と書いたが、 binary or text、 encoding、 record layout、 voice_num base、 既存 25-byte register-major PMDNEO format への変換仕様が未確定。

**plan v6 fix = .FF format literal spec (= γ-0 pre-step で確定必須)**:

#### β-4-11-1: 入力 #FFFile format (= γ-0 pre-step で literal 確認 mandatory)

- **拡張子**: `.FF` (= PMD V4.8s + PMDDotNET 互換 voice file)
- **encoding**: **binary** (= text encoded voice file は PMD 慣習で `.FFV` 等別拡張、 PMD V4.8s + PMDDotNET 標準 .FF は binary)
- **layout** (= γ-0 で `vendor/pmd48s/` + PMDDotNET source + 既存 .FF サンプルから literal 確認):
  - 候補仮説: voice_num 連番 0/1/2/... の voice data records、 各 record 25 byte (= PMD voice_buf format slot 1/3/2/4 interleaved)
  - 候補仮説: 各 record 32 byte (= internal voice_buf size、 25 byte voice + 7 byte name)
  - 候補仮説: file header + N records + footer (= e.g., voice count byte + records)
- **voice_num base**: γ-0 pre-step で確認 (= 0-based か 1-based か)
- **既存 register-major PMDNEO format との関係**:
  - compile.py 既存 generation (= line 488-494): register-major (= 6 reg × 4 slot) per voice 25 byte
  - PMD .FF format との byte ordering 変換は γ-0 で literal 確認後決定 (= slot reorder 不要 or slot reorder logic 追加)

#### β-4-11-2: γ-0 pre-step = .FF format literal 確認 mandatory (= 実装着手前)

1. `vendor/pmd48s/` 内 .FF sample または PMD V4.8s 標準 voice file 探索
2. `vendor/PMDDotNET/` 内 .FF I/O 関連 source (= `compiler.cs:154` + `Program.cs:190` outFFFileBuf logic = LR-3 参考)
3. 既存 `src/test-fixtures/axis-b/` 等で .FF 使用例検索
4. 仕様確定 + plan v7 (= Annex β-4 拡張 β-4-N) で literal record

### β-4-12: must-fix MF-2 反映 = MML 内 voice + #FFFile 同一番号 conflict resolution policy (= AXIS-3)

Codex 指摘 = β-4-4-1 point 3 で「MML > #FFFile 優先順位」 のみ定義、 同一 voice_num が両方に定義された場合の warning 動作未規定 (= 「両方未定義」 warning のみ規定済)。

**plan v6 fix = conflict resolution policy literal**:

```
voice_num N の resolution priority (= compile.py 内 logic):
1. MML 内 @N voice 定義 (= `@001 alg fbl` + 4 operator row) 検出
   → MML voice def を採用、 同時 #FFFile 内に同 N があれば **warning** (= 「voice N defined in both MML and #FFFile, using MML」 標準 stderr 出力)
2. MML 内未定義 + #FFFile 内 N 定義あり
   → #FFFile from voice を採用 (= fallback path)
3. MML + #FFFile 両方未定義 (= 既存 plan v5 base、 plan v7 で β-4-16 LR-2 と整合 update)
   → warning emit + **max referenced N まで safe/empty entry を emit** (= LR-2 voice_table generation range 整合、 overread 防止 mandate)、 driver 経路で comat lookup 時 empty entry hit = safe default (= entry内 voice data は 0x00 で埋め、 keyon path で害なし)
```

警告 wording 統一:
- `[compile.py warning] voice {N} defined in both MML and #FFFile '{ff_path}', using MML version`
- `[compile.py warning] voice {N} not defined in MML or #FFFile, voice_table[{N}] emitted as empty/safe entry (= max N range carry)`

### β-4-13: must-fix MF-3 反映 = voice_table.inc 組込ルール literal 化 (= AXIS-5)

Codex 指摘 = β-4-4-2 で「generated voice_table.inc を build に組み込む」 だが、 既存 `song_data.inc:55` に `voice_table:` empty label がある。 「append」 だと label 重複 / 配置ずれ risk。

**plan v6 fix = 組込ルール exact policy (= 採用 Option B)**:

#### Option A (= 不採用): generated voice_table.inc を song_data.inc に append
- 既存 empty `voice_table:` + 新 `voice_table:` label = **duplicate label** = sdasz80 error
- 不採用

#### Option B (= **採用**): build-poc.sh で song_data.inc 内 `voice_table:` block を sed 等で削除 + 新 voice_table.inc を append
- 既存 song_data.inc (= compile.py 経路 default 生成) の `voice_table:` empty label + 末尾までの voice block (= 0 byte) を削除
- compile.py --voice-only generated voice_table.inc を末尾に append
- 結果: 単一 `voice_table:` label + populated entries
- backward-compat: compile.py 経路 (= PMDDOTNET_MML 未使用 production default) では song_data.inc が compile.py 経路の通常 generation を使う (= 不変)

実装 sketch (= build-poc.sh 追加 logic、 PMDDOTNET_MML block 内):
```bash
if [[ -n "${PMDDOTNET_MML:-}" ]]; then
    # ... 既存 PMDDOTNET .M compile + pmddotnet_song.m generation ...
    # ADR-0072 plan v6: compile.py --voice-only で voice_table.inc 生成
    python3 "$PMDNEO_ROOT/src/tools/pmd-mml/compile.py" --voice-only \
        --mml "$PMDDOTNET_MML" \
        --output-voice-table "$TEMPLATE_DIR/voice_table_pmddotnet.inc"
    # song_data.inc の既存 empty voice_table: block を削除 + voice_table_pmddotnet.inc を append
    sed -i.bak '/^voice_table:$/,$d' "$TEMPLATE_DIR/song_data.inc"
    cat "$TEMPLATE_DIR/voice_table_pmddotnet.inc" >> "$TEMPLATE_DIR/song_data.inc"
fi
```

(= literal は γ impl で確定、 macOS BSD sed と GNU sed 両対応必要 = `-i.bak` portable invocation)

#### Option C (= 不採用): song_data.inc 全体再生成
- compile.py 経路の song_table + song_part_? generation を bypass する設計変更必要
- scope creep risk + backward-compat 影響 → 不採用

### β-4-14: must-fix MF-4 反映 = malformed 外部 voice file safe-default policy (= AXIS-4)

Codex 指摘 = missing file fallback は明記済だが、 malformed (= broken format、 truncated、 invalid byte) file の動作未定。

**plan v6 fix = malformed file handling literal**:

```
malformed #FFFile detection + safe default:
1. file size check (= expected size = voice_count × 25 byte + header overhead)
   不正サイズ → warning + 全 #FFFile ignore + MML inline voice のみ使用
2. parse error (= I/O exception、 byte 解釈失敗)
   → warning + 全 #FFFile ignore + MML inline voice のみ使用
3. partial parse success (= 一部 voice 抽出可能、 一部失敗)
   → warning per voice + 成功分のみ使用 + 失敗分は MF-2 priority 3 (= skip + warning)
4. 全 case で **build failure させない** (= warning level、 exit code 0 維持)
   = MML inline voice def + 既存 driver fallback で動作確保
```

警告 wording:
- `[compile.py warning] #FFFile '{ff_path}' malformed (reason: {reason}), ignoring entire file, using MML inline voices only`
- `[compile.py warning] #FFFile '{ff_path}' voice {N} parse failed (reason: {reason}), skipped`

### β-4-15: nice-to-have NH-1/NH-2/NH-3 反映

#### NH-1: conflict fixture 追加
`src/test-fixtures/adr-0072/test-conflict.mml` + `test-conflict.ff` (= MML 内 @001 定義 + #FFFile 内 @001 定義 = priority warning 動作確認)。 γ impl で配置。

#### NH-2: missing/malformed fixture 追加
- `src/test-fixtures/adr-0072/test-missing-ff.mml` (= #FFFile 'nonexistent.ff' = missing file fallback 動作確認)
- `src/test-fixtures/adr-0072/test-malformed.ff` (= truncated/corrupt binary = malformed safe default 動作確認)

#### NH-3: 旧 driver-side plan コメント update
- `src/test-fixtures/adr-0072/test-voice-load.mml` + `test-multi-voice.mml` (= 既存 fixture) のコメントで「ADR-0072 patch (1) = comat routine chip_type guard + PMDDOTNET inline voice table load verify」 等 plan v1-v4 era 記述を plan v5/v6 (= build-side voice resolution) に update (= γ impl で同時実施)

### β-4-16: latent-risk LR-1/LR-2/LR-3 acknowledge + mitigation

#### LR-1: compile.py `#` strip 順序
Codex 指摘 = `compile.py:430` + `:525` で `#` をコメント strip している箇所より前に `#FFFile` 検出を走らせないと FFFile が無視される。

**plan v6 mitigation**: `#FFFile` directive parser は MML preprocessing の **最初の pass** で実行、 `#` strip より前。 具体 implementation:
- compile.py に新 function `parse_ff_file_directive(source)` 追加
- `parse_mml(source)` 関数の **冒頭** (= line ~501 直前) で呼出
- `#FFFile <filename>` line を検出 → filename + relative path 解決 → external voice file parse → voice dict に merge
- その後 既存 `parse_voice_definitions` + 通常 MML parse 続行 (= 既存 `#` strip path は preserved)

#### LR-2: max voice_num overread
Codex 指摘 = compile.py:614 voice_table generation で「定義済み最大 voice_num までしか emit しない」、 それを超える `@N` 参照が MML にあると driver の `comat` が `voice_table` 末尾を overread。

**plan v6 mitigation** (= plan v7 で β-4-12 priority 3 wording と整合確定):
- compile.py で MML 内全 `@N` 参照を pre-scan + max referenced N を計算
- voice_table generation で **max referenced N まで** emit (= MF-2 priority 3 「両方未定義」 entry も skip ではなく **empty/safe entry (= 25 byte 0x00 + ALG/FB 0x00) で埋める** = `voice_table` entry index 整合保持 + driver `comat` lookup 範囲外 fault risk 完全回避)
- 既存 driver `comat` は `voice_table[N]` lookup を期待、 範囲内 empty entry hit = safe default (= keyon path で害なし、 ただし audio silent 該当 ch のみ、 全 audio 経路は他 voice で正常)

#### LR-3: PMDDOTNET 自身も .FF 出力生成
Codex 指摘 = `compiler.cs:154` + `Program.cs:190` で PMDDOTNET 自身が `outFFFileBuf` 経由で `.FF` 出力を生成する。 入力 `#FFFile` と PMDDOTNET 出力 .FF の混同 risk。

**plan v6 mitigation**: plan v6 wording で **明示区別** mandatory:
- **入力 `#FFFile`**: MML 冒頭 directive で参照される **外部 voice file**、 ユーザが用意する PMD voice file (= 同一フォルダ内 binary `.FF`)
- **出力 PMDDOTNET .FF** (= `outFFFileBuf`): PMDDOTNET compiler 内部で生成される副産物、 **本 ADR-0072 scope-out** (= 触らない、 PMDDOTNET 本体改変は scope OUT (1))
- 命名衝突回避: compile.py 内変数名 = `external_ff_path` (= 入力)、 `outFFFileBuf` (= PMDDOTNET 内、 触らない) として区別

### β-4-17: plan v6 = γ impl order updated

1. **γ-0 pre-step**: .FF format literal spec 確認 (= β-4-11-2 vendor + sample + PMDDOTNET source 経路) + plan v7 起票 (= 必要に応じて、 β-4-N で literal record)
2. **compile.py 拡張** (= plan v5 β-4-4-1 carry + plan v6 反映):
   - `parse_ff_file_directive(source)` 新規 function (= LR-1 反映、 `#` strip 前 first pass)
   - MML file relative path 解決
   - external voice file (= .FF binary) parser
   - voice resolution priority (= MF-2 = MML > #FFFile + conflict warning)
   - malformed file handling (= MF-4 safe default + warning)
   - max referenced voice_num pre-scan + voice_table generation range fix (= LR-2 反映)
   - `--voice-only` mode flag
3. **build-poc.sh 拡張**:
   - PMDDOTNET_MML 使用時に compile.py `--voice-only` 並行呼出
   - song_data.inc の `voice_table:` block を sed 削除 + generated voice_table.inc を append (= MF-3 Option B 採用)
   - sed portable invocation (= macOS BSD + GNU sed 両対応)
4. **新規 committed fixture 配置** (= NH-1/NH-2 反映):
   - 既存 `test-voice-load.mml` + `test-multi-voice.mml` (= NH-3 コメント update)
   - `test-conflict.mml` + `test-conflict.ff` (= NH-1 priority warning verify)
   - `test-missing-ff.mml` (= NH-2 missing file fallback)
   - `test-malformed.ff` (= NH-2 malformed safe default)
5. **build verify**: 4 build matrix sha256 (= B1/B2/B3/B4) + production baseline `457a237c...` byte-identical 維持
6. **δ functional verify** (= plan v5 β-4-7 step 6 carry): MAME runtime trace + FM voice register area writes + audio audible
7. **retrospective Codex impl-review**
8. ε Accepted

### β-4-18: Codex Rescue plan review round 6 重点軸 (= plan v6 = 4 must-fix 反映 + 3 nh + 3 lr 反映 + 不変 carry)

1. MF-1 反映確認 = .FF format γ-0 pre-step literal 確認 mandate (= β-4-11)
2. MF-2 反映確認 = MML+#FFFile conflict resolution policy literal (= β-4-12)
3. MF-3 反映確認 = voice_table.inc 組込 Option B 採用 + sed 削除 + append exact rule (= β-4-13)
4. MF-4 反映確認 = malformed file safe default policy literal (= β-4-14)
5. NH-1/NH-2/NH-3 反映確認 = fixture 拡張 + コメント update (= β-4-15)
6. LR-1 acknowledge = #FFFile directive parser を `#` strip 前 first pass (= β-4-16 LR-1)
7. LR-2 acknowledge = max voice_num pre-scan + voice_table range fix (= β-4-16 LR-2)
8. LR-3 acknowledge = 入力 #FFFile vs PMDDOTNET 出力 .FF 命名区別 (= β-4-16 LR-3)
9. AXIS-1/AXIS-6 unchanged carry PASS confirm + AXIS-7 WARN → MF-3 resolve で resolved 期待 confirm

## Annex β-5: γ impl + retrospective Codex review approve + ε Accepted milestone (= 2026-05-27 43rd session)

### β-5-1: γ impl 完走 + retrospective Codex impl-review approve

ADR-0072 sprint γ impl chain (= commits `731cffd` → `dfec8e9` → `6503738`):

| commit | 内容 |
|---|---|
| `731cffd` | compile.py + build-poc.sh 拡張 (= γ initial impl) |
| `dfec8e9` | 新規 committed fixture 配置 (= test-voice-load.mml + test-multi-voice.mml) |
| `6503738` | MF-1 fix-up = LR-2 mitigation (= scan_voice_references + max_ref_voice 経由 voice_table range expansion + 未定義参照 warning) |

retrospective Codex impl-review chain:
- round 1 (= agentId `a63b92450f0fee259`、 elapsed 約 8 分) **revise** + 1 must-fix MF-1 (= AXIS-5 LR-2 mitigation 未実装 = driver overread risk on referenced-but-undefined @N) + 2 nh + 3 lr + 7 軸中 5 PASS + 1 CONDITIONAL + 1 FAIL
- round 2 attempt 1 (= agentId `a032bdb95d2c2b0af`、 elapsed 約 2m38s) placeholder response 機械復旧 retry
- round 2 retry (= agentId `af43c4d0c9000fcc1`、 elapsed 約 1 分) **approve** = AXIS-1〜3/5/6/7 全 PASS + AXIS-4 CONDITIONAL (= partial-success malformed handling carry) + must-fix 0 + nh 1 件 (= scan_voice_references で `;` コメント行 skip = trailing comment 内 @N 誤検出回避、 nh carry) + lr 1 件 (= 同源)

### β-5-2: γ impl 達成成果

| 項目 | 結果 |
|---|---|
| voice opcode @N dispatch | ✅ driver `comat` 経路 runtime 動作確認 |
| voice_table[N] lookup with 1-based offset fix | ✅ MML @001 → voice_table[1] → voice0_data (= dummy index 0 + voice data 1+) |
| FM register area voice data load | ✅ MAME ymfm-trace で reg 0x30=0x01 (= slot 0 ML) + reg 0x40=0x11 (= slot 0 TL=17、 voice 001 exact) + reg 0x44=0x19 (= slot 1 TL=25) confirmed |
| **driver source no-touch** | ✅ `src/driver/standalone_test.s` 完全不変 (= 全 plan v1-v4 提案 driver patches revert 済) |
| **production sha256 invariant** | ✅ (B1) m1.m1 sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` = base anchor byte-identical 維持 |
| #FFFile parsing | ✅ vendor/pmd48s/SSGEG.FF 4 voices extract 成功、 register-major format compile.py format 一致 |
| audio non-silent | ✅ rms=5 (-76.3 dBFS)、 peak=53 (-55.8 dBFS) = ADR-0071 ε δ-5 silent failure の **substantive 根本治療達成** |
| LR-2 driver overread prevention | ✅ scan_voice_references + max_ref_voice 経由 voice_table range expansion + 未定義参照 warning literal |
| build matrix backward-compat | ✅ (B1) PMDDOTNET_MML 未使用 = compile.py + build-poc.sh 拡張は inactive、 既存 production build path 完全不変 |

### β-5-3: 「driver-PMDDOTNET voice opcode data delivery repair 完了」 milestone wording 解禁

ε Accepted 後、 以下 wording 使用可:
- 「**driver-PMDDOTNET voice opcode data delivery repair 完了**」
- 「**ADR-0072 ε Accepted**」
- 「**build-side voice resolution + #FFFile support 完了**」
- 「**PMDDotNET MML voice opcode @N runtime dispatch 動作確認**」

ただし以下併記必須 6 件 mandatory:
1. audio 音量問題 (= -76 dBFS、 δ-5 engineering gate Layer 1 未達) は **ADR-0072 scope OUT** = driver volume scaling or fixture voice design 由来、 別 sprint / 別 ADR 範疇
2. production-ready 全体達成ではない (= ADR-0066 候補 future、 user 明示 GO 必須)
3. (d) audition gate 達成ではない (= ADR-0065 ε scope、 user 介入 mandatory)
4. 軸 B 完成ではない
5. 軸 G 完成ではない
6. 16ch full candidate distinctness 完了ではない (= ADR-0070 候補 future)

### β-5-4: 後続 task (= ADR-0072 ε Accepted 後)

main agent autonomous default:
1. **#FFFile partial-success malformed handling enhancement** (= AXIS-4 CONDITIONAL carry、 nh-1 candidate、 個別 voice record 部分採用、 別 follow-up task)
2. **scan_voice_references コメント行 skip 改善** (= round 2 nh、 `;` 始まり line skip、 trailing comment 内 @N 誤検出回避)

user 明示 GO 必須 (= scope 変更 / 不可逆 / aesthetic / 本番切替):
3. **audio 音量問題 follow-up sprint** (= driver volume scaling or fixture voice design tuning、 ADR-0072 scope OUT)
4. **δ-5 engineering gate Layer 1 PASS verify** (= 音量問題 fix 後の re-verify)
5. **ADR-0065 ε audition session 実施判断** (= ADR-0072 ε Accepted で voice opcode dispatch + 1-based offset + voice data delivery 経路確立、 user 介入 mandatory)
6. **ADR-0066 本番 cmd 切替判断** + **ADR-0070 候補 起票判断** + **ADR-0073+ 候補 起票判断**

### β-5-5: scope-out 維持 (= ADR-0072 ε Accepted 後 carry)

1. PMDDOTNET 本体改変 (= `vendor/PMDDotNET/` 完全不変、 carry)
2. driver source patch (= `src/driver/standalone_test.s` 完全不変、 plan v1-v4 提案 patch 全 revert 済)
3. pmdneo_rhythm_event_trigger (= K bitmap pair distinct ADR-0070 候補 future)
4. K bitmap pair distinct (= ADR-0070 候補 future)
5. user audition / δ 再開 (= ADR-0065 ε scope、 user 明示 GO 必須)
6. audio 音量問題 (= driver volume scaling、 別 sprint / 別 ADR)

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
| 2026-05-27 | 43rd session | ADR-0072 ε Accepted = γ impl 完走 + retrospective Codex impl-review approve = ADR-0072 完走 milestone (= 2026-05-27 43rd session、 driver-PMDDOTNET voice opcode data delivery repair sprint = build-side voice resolution + #FFFile support 完了、 sub-sprint α/β/γ + ε 完了、 retrospective Codex impl-review round 2 retry (= agentId `af43c4d0c9000fcc1`、 elapsed 約 1 分) **approve** AXIS-1〜3/5/6/7 全 PASS + AXIS-4 CONDITIONAL carry + must-fix 0、 main agent autonomous で完走 = ADR-0041 §決定 4-2 Codex Rescue 化 default + §決定 4-3 retrospective Codex impl-review pattern、 計 Codex layer 2 review 9 round = plan review 7 round chain (= plan v1→v7 approve、 round 4 attempt 1 placeholder 機械復旧 retry + plan v5 build-side scope shift user 明示 GO Option 2 revised + #FFFile 対応 + plan v6/v7 wording fix 経由 round 7 retry approve) + γ retrospective impl-review 2 round chain (= round 1 revise MF-1 LR-2 mitigation 未実装 + fix-up commit `6503738` + round 2 retry approve))。 ε Accepted 後解禁 wording (= 6 件併記必須) = 「driver-PMDDOTNET voice opcode data delivery repair 完了」 + 「ADR-0072 ε Accepted」 + 「build-side voice resolution + #FFFile support 完了」 + 「PMDDotNET MML voice opcode @N runtime dispatch 動作確認」、 併記必須 = (i) audio 音量問題 ADR-0072 scope OUT + (ii) production-ready 全体達成ではない + (iii) (d) audition gate 達成ではない + (iv) 軸 B 完成ではない + (v) 軸 G 完成ではない + (vi) 16ch full candidate distinctness 完了ではない。 ADR doc 修正範囲 = (1) 状態行 Draft → **Accepted** + ε Accepted 後解禁 wording + 併記必須 6 件 literal + (2) Annex β-5 fill = γ impl + retrospective Codex review approve 詳細 + γ impl 達成成果 table + wording 解禁 literal + 後続 task + scope-out 維持 + (3) 改訂履歴 ε Accepted entry append (= 本 entry、 append only mandate 厳守) + (4) dashboard 0072 行 status update = 別 commit で同時実施 (= fix-up separate commit pattern carry)。 driver / 既存 verify script / 既存 fixture MML / vendor (= 特に PMDDOTNET 完全不変 carry) / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 Annex α-1〜α-6 + β-1 + β-2 + β-3 + β-4 (= plan v1-v7 + γ impl iteration history、 immutable history carry) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 production sha256 = `457a237cd696e09bc99f707d13bc8851c75faf7225eee5e0d4c7111980ca9092` 維持 confirmed (= driver no-touch + (B1) build matrix byte-identical 確認済)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 ε precedent 同 pattern)。 branch 運用 4 条規律 carry = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 = PR #142+#143+#144+#145+#146+#147+#148+#149+#151+#152+#153+#154 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = **PR #154 merge + atomic 1 セット 12 回目適用** + dashboard maintenance + memory `project_pmdneo_adr_0072_initiated.md` 新規 + MEMORY.md index entry update + 完走報告、 後続 task scope = main agent autonomous (= #FFFile partial-success enhancement + scan_voice_references comment skip 改善) + user 明示 GO 必須 (= audio 音量問題 follow-up + δ-5 Layer 1 PASS verify + ADR-0065 ε + ADR-0066 + ADR-0070 + ADR-0073+ 候補 起票判断)。 | (= 本 ε Accepted commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 plan v6 Codex review revise + plan v7 wording 整合 fix = plan v6 (= `a789d0e`) 後の Codex Rescue plan review round 6 (= agentId `a50a50bb995be8935`、 elapsed 約 1 分) **revise** + 1 must-fix (= AXIS-2 + AXIS-7 β-4-12 priority 3 「skip」 vs β-4-16 LR-2 「empty entry」 wording 矛盾解消) + 0 nh + 0 lr + per-axis (= 9 軸中 6 PASS + 3 WARN = AXIS-2 + AXIS-7 + AXIS-9、 WARN は本 must-fix 解決連動)。 main agent autonomous で plan v7 wording 整合 fix (= driver no-touch carry、 design literal 整合のみ = sha256/allowed-touch/scope 変更なし)。 ADR doc 修正範囲 = (1) β-4-12 priority 3 wording update = 「voice_table[N] entry skipped」 → 「max referenced N まで safe/empty entry を emit、 driver `comat` lookup empty entry hit = safe default (= 25 byte 0x00 + ALG/FB 0x00 + 該当 ch audio silent のみ、 全 audio 経路は他 voice で正常)」 (= LR-2 と整合) + 警告 wording update + (2) β-4-16 LR-2 mitigation wording update = plan v7 整合明示 + safe default 詳細 + (3) 改訂履歴 plan v7 wording fix entry append (= 本 entry) + (4) dashboard 0072 行 status update = 別 commit。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0041〜0071 本文 + Annex / 既存 scripts (= compile.py + build-poc.sh plan v6/v7 scope IN 例外) / 既存 Annex α/β-1〜β-4-9 (= immutable history carry) = 全 untouched。 production sha256 = `457a237c...` 維持期待 (= driver no-touch carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 3 fix-up precedent 同 pattern)。 branch 運用 4 条規律 carry。 後続 = Codex layer 2 plan review round 7 on plan v7 wording 整合 = 1 重点軸 (= AXIS-2/AXIS-7 矛盾解消確認) + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + γ sub-sprint impl 着手。 | (= 本 plan v7 wording fix commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 plan v5 Codex review revise + plan v6 起草 = plan v5 build-side scope shift commit chain (= `b3b594a` + `4f75f14`) 後の Codex Rescue plan review (= agentId `aa8f01d42ba8f4422`、 elapsed 約 2 分) **revise** + 4 must-fix + 3 nice-to-have + 3 latent-risk + per-axis verdict (= AXIS-1 PASS + AXIS-2 FAIL + AXIS-3 FAIL + AXIS-4 FAIL + AXIS-5 FAIL + AXIS-6 PASS + AXIS-7 WARN = 7 軸中 2 PASS + 4 FAIL + 1 WARN)。 main agent autonomous (= user mandate 適用、 全 mf scope 内 design spec literal 化 + driver no-touch 維持 = 全自律進行可能) で plan v6 起草。 ADR doc 修正範囲 = (1) Annex β-4 拡張 = β-4-10〜β-4-18 plan v6 = 9 sub-section (= β-4-10 plan v6 scope + must-fix overview + β-4-11 MF-1 .FF format spec γ-0 pre-step mandatory + literal 候補仮説 3 件 + β-4-12 MF-2 MML+#FFFile conflict resolution priority literal (= MML 優先 + warning 詳細 wording) + β-4-13 MF-3 voice_table.inc 組込ルール Option A/B/C 比較 + Option B 採用 sed 削除 + append exact rule + build-poc.sh sketch + β-4-14 MF-4 malformed file safe default 4 件 case + warning wording literal + build failure させない mandate + β-4-15 NH-1/NH-2/NH-3 fixture 拡張 + コメント update + β-4-16 LR-1/LR-2/LR-3 acknowledge + mitigation literal (= #FFFile parser `#` strip 前 first pass + max voice_num pre-scan + 入出力 .FF 区別) + β-4-17 γ impl order plan v6 = 8 step (= γ-0 pre-step .FF format 確認 + compile.py 拡張 + build-poc.sh 拡張 + fixture + verify) + β-4-18 round 6 重点軸 9 件) + (2) 改訂履歴 plan v6 entry append (= 本 entry、 append only mandate 厳守) + (3) dashboard 0072 行 status update = 別 commit。 driver / 既存 verify script / 既存 fixture MML / vendor (= 特に PMDDOTNET 完全不変 carry) / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 scripts (= compile.py + build-poc.sh plan v6 scope IN 例外、 既存機能 backward-compat 維持 mandatory) / 既存 Annex α-1〜α-6 + β-1 + β-2 + β-3 + β-4 β-4-1〜β-4-9 (= plan v5 immutable history carry) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 production sha256 = `457a237c...` 維持期待 (= driver no-touch carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 1/2/3 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 6 on Annex β-4 plan v6 (= 9 重点軸 = MF-1/2/3/4 反映 + NH-1/2/3 反映 + LR-1/2/3 acknowledge + AXIS unchanged carry + WARN resolve confirm) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= compile.py + build-poc.sh 拡張、 driver no-touch carry)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default。 | (= 本 plan v6 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 γ impl phase finding-based scope shift = plan v5 = build-side voice resolution + #FFFile support (= user 明示 GO Option 2 revised、 driver no-touch 確定) = sprint γ impl 着手後 real binary 解析で plan v4 前提「voice table が pmddotnet_song.m 内 inline emit」 が **不成立確定** (= PMDDOTNET /N + /B 両 mode で voice table inline emit されない、 251 byte binary literal verify、 agent 1/4 finding `mml_seg.prg_flg & 1 != 0` runtime 条件評価不足 retrospective)、 真の解決経路 = `src/tools/pmd-mml/compile.py:424` 既存 `parse_voice_definitions(source)` + line 626/634 `voice_table:` Z80 label generation 機能再利用 + build-poc.sh 拡張で PMDDOTNET_MML 経路でも voice 抽出並行実行、 user 明示「Option 2 revised: build-side voice resolution + #FFFile support、 driver source 原則 no-touch」 受領 + scope shift 確定。 plan v1-v4 driver patches 完全 revert 済 (= `git checkout src/driver/standalone_test.s` 実行、 driver source byte-identical to base anchor `wip-pmddotnet-opnb-extension@05f0e44` 維持 confirmed)、 plan v5 起草 = build-side scope。 ADR doc 修正範囲 = (1) Annex β-4 新規追加 = plan v5 build-side voice resolution + #FFFile support 9 sub-section (= scope shift 経緯 + 解決経路 + scope IN/OUT + modification path detail + sha256 維持 update + review 7 軸 + γ impl order 8 step + revert literal + immutable history carry) + (2) 改訂履歴 plan v5 entry append (= 本 entry、 append only mandate 厳守) + (3) dashboard 0072 行 status update = 別 commit で同時実施。 user 明示 #FFFile 対応必須要件 = PMD 系 MML は音色を MML 内に直接書くとは限らない + 同一フォルダの FM 音源音色 file を `#FFFile` directive で参照する慣習がある + SAMPLE2 系 + 実用 MML では外部音色 file 対応がないと audition material として成立しない可能性が高い + これは driver の問題ではなく MML build / voice resolution の問題 (= 既存 ADR-0071 + plan v4 までの driver-side fix scope では解決不能)。 plan v5 scope IN literal (= user 明示 allowed-touch) = (1) `src/tools/pmd-mml/compile.py` #FFFile parse + MML file relative path 解決 + FM voice file parse + voice_table: generation 拡張 + --voice-only mode flag + (2) `scripts/build-poc.sh` PMDDOTNET_MML 使用時に compile.py voice 抽出並行呼出 + generated voice table.inc を build に組み込む + (3) `src/test-fixtures/adr-0072/` 必要に応じて #FFFile 付き minimal MML + minimal voice file fixture (= ADR-0069 §決定 3-d precedent 継承) + (4) `docs/adr/0072-*.md` + `docs/parallel-axes-dashboard.md` + 改訂履歴 + 平易要約。 plan v5 scope OUT literal (= user 明示) = (1) PMDDOTNET 本体改変 (= `vendor/PMDDotNET/` 完全不変) + (2) driver source patch (= `src/driver/standalone_test.s` 完全不変、 plan v1-v4 提案 patch 全 revert 済) + (3) pmdneo_rhythm_event_trigger (= K bitmap pair distinct ADR-0070 候補 future) + (4) K bitmap pair distinct (= ADR-0070 候補 future) + (5) user audition / δ 再開 (= ADR-0065 ε scope、 user 明示 GO 必須)。 Codex Rescue plan review 必須軸 (= user 明示 7 軸 literal) = (1) PMDDOTNET .m に voice table がない事実 + (2) #FFFile で同一フォルダ voice file を解決できるか + (3) MML 内 voice 定義と外部 voice file の優先順位 + (4) relative path / missing file / malformed file の扱い + (5) generated voice_table: が既存 driver と整合するか + (6) driver no-touch で実現できるか + (7) production sha256 維持に影響がないか。 production sha256 維持方針 update = plan v4 まで driver-side guarded change で flag-off byte-identical / plan v5 = driver source 完全 no-touch で automatic 維持 (= 触らないので破れない) + (B1)/(B2)/(B3) baseline 全 byte-identical 維持 + (B4) flag-on post-plan-v5 with fixture diff = song_data.inc + ROM data 由来 (= driver byte-identical)。 driver / 既存 verify script / 既存 fixture MML / vendor (= 特に PMDDOTNET 完全不変、 plan v5 scope OUT (1)) / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 scripts (= compile.py + build-poc.sh は本 ADR-0072 plan v5 scope IN なので例外的 modify、 ただし既存機能完全 backward-compatible 維持 mandatory) / 既存 Annex α-1〜α-6 + β-1 + β-2 + β-3 (= immutable history carry) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 3 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review on Annex β-4 plan v5 (= 7 重点軸 = user 明示 literal carry) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= compile.py 拡張 + build-poc.sh 拡張 mandate、 worktree 再作成 不要 = main agent 経路、 driver no-touch)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default。 | (= 本 plan v5 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 sprint β round 3 Codex review revise + plan v4 起草 = sprint β round 2 + plan v3 後の sprint β round 3 plan v3 Codex review (= agentId `ac6a9071699dee380`、 elapsed 約 8 分) **revise** + 5 must-fix + 1 nice-to-have + 1 latent-risk + per-axis verdict (= AXIS-1 PASS + AXIS-2 FAIL + AXIS-3 FAIL + AXIS-4 PASS + AXIS-5 PASS + AXIS-6 FAIL + AXIS-7 PASS + AXIS-8 FAIL + AXIS-9 FAIL = 9 軸中 5 PASS + 4 FAIL)。 main agent autonomous (= user mandate 適用、 全 mf scope 内 technical detail 訂正 = 全自律進行可能) で plan v4 起草 + 直接 fix 適用 (= mf-2 typo + mf-3 supersede note inline)。 ADR doc 修正範囲 = (1) Annex β-3 拡張 = β-3-10〜β-3-20 plan v4 = 11 sub-section (= β-3-10 plan v4 scope overview + β-3-11 mf-1 scratch byte 0xFD3F → 0xFD62 訂正 (= free region 0xFD62-0xFD78 from `standalone_test.s:380` literal) + β-3-12 mf-2 β-2-6 line 657 typo `comt` → `comat` 直接修正 + β-3-13 mf-3 Annex α-1 軸 2 line 225/241 supersede note inline 追加 (= immutable history 保護 + 注記のみ追加) + β-3-14 mf-4 voice 0 + first data byte 0xFF terminator collision **structural impossibility proof** (= YM2610 reg 0x30 bit 7 reserved → voice_buf byte 0 ≤ 0x7F → 0xFF spec 上不可能) + β-3-15 mf-5 AXIS-4 WARN → resolved 明示 + AXIS carry wording 整合 (= round 2 WARN ↔ plan v3 acknowledge ↔ plan v4 mf-4 proof resolve full chain literal) + β-3-16 nh-1 β-3-3 cleaner section canonical 明示 + β-3-17 lr-1 γ-0 pre-step `pmdneo_fm_voice_set` slot order literal confirm + β-3-18 helper design v4 (= 主要 design point 7 件) + β-3-19 γ impl order plan v4 = 9 step (= γ-0 pre-step 追加 + scratch byte literal 追加 step 追加) + β-3-20 round 4 重点軸 9 件) + (2) β-2-6 line 657 typo `comt` → `comat` 直接修正 (= 本 commit chain 内同時実施) + (3) Annex α-1 軸 2 line 225 + 241 supersede note inline 直接追加 (= 本 commit chain 内同時実施、 immutable history 保護 = 元 finding 削除せず、 注記のみ追加) + (4) 改訂履歴 sprint β round 3 + plan v4 entry append (= 本 entry、 append only mandate 厳守) + (5) dashboard 0072 行 status update placeholder (= 別 commit で同時実施)。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 scripts / 既存 Annex α-1〜α-6 + β-1 + β-2 + β-3-1〜β-3-9 (= immutable history、 ただし α-1 軸 2 line 225/241 supersede note inline と β-2-6 line 657 typo fix のみ追加可) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 production sha256 = `457a237c...` 維持期待 (= sprint β round 3 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 3 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 4 on Annex β-3 plan v4 (= 9 重点軸 = mf-1〜mf-5 反映確認 + nh-1 反映 + lr-1 反映 + unchanged AXIS carry + round 3 FAIL resolve confirm) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 + 新規 fixture + γ-0 pre-step + scratch RAM byte address 0xFD62 mandate)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default。 | (= 本 plan v4 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 sprint β round 2 Codex review revise + plan v3 起草 = sprint β round 1 + plan v2 後の sprint β round 2 plan v2 Codex review (= agentId `a65c98ab79db416f1`、 elapsed 約 4 分) **revise** + 2 must-fix + 3 nice-to-have + 3 latent-risk + per-axis verdict (= AXIS-1 PASS + AXIS-2 PASS + AXIS-3 FAIL + AXIS-4 WARN + AXIS-5 PASS + AXIS-6 PASS + AXIS-7 FAIL + AXIS-8 PASS + AXIS-9 PASS = 9 軸中 7 PASS + 1 WARN + 1 FAIL、 round 1 比大幅改善)。 main agent autonomous (= user mandate 適用、 mf-A/mf-B 全 technical detail 訂正 + scope 内 = 全自律進行可能) で plan v3 起草。 ADR doc 修正範囲 = (1) Annex β-3 新規追加 = plan v3 = 9 sub-section (= β-3-1 scope + must-fix overview + β-3-2 mf-A B preservation + reload from `PART_OFF_CH_IDX(ix)` offset 24 literal + β-3-3 mf-B terminator check first + voice_num scratch RAM byte 経由保持 design + β-3-4 nh-1/nh-2/nh-3 反映 + 追加 nh-typo + nh-δ-6-predicate (= 42 件 voice data byte ↔ register order 照合) + nh-γ-byte-update + β-3-5 lr-1/lr-2/lr-3 acknowledge + 追加 lr-stale-α + lr-voice-A-slot-order + lr-voice-0-first-byte + β-3-6 helper design v3 literal + scratch RAM byte `driver_pmddotnet_voice_num_scratch` 0xFDxx γ impl で literal 確定 + β-3-7 γ impl order plan v3 = 8 step + scratch RAM byte literal address 確定 step 追加 + β-3-8 Annex α-1 軸 2 supersede note 追加 (= terminator 表記訂正、 immutable history 保護維持 + 注記のみ追加) + β-3-9 Codex round 3 重点軸 9 件) + (2) 改訂履歴 sprint β round 2 + plan v3 entry append (= 本 entry、 append only mandate 厳守) + (3) dashboard 0072 行 status update placeholder (= 別 commit で同時実施)。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 scripts / 既存 Annex α-1〜α-6 + β-1 + β-2 (= immutable history、 ただし α-1 軸 2 supersede note のみ追加可) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 production sha256 = `457a237c...` 維持期待 (= sprint β round 2 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 1/2 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 3 on Annex β-3 plan v3 (= 9 重点軸 = mf-A/mf-B 反映確認 + nh-typo/nh-δ-6-predicate/nh-γ-byte-update + lr-stale-α/lr-voice-A-slot-order/lr-voice-0-first-byte + AXIS unchanged carry) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 + 新規 fixture + scratch RAM byte literal address 確定 mandate)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default。 | (= 本 plan v3 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 sprint β round 1 Codex review revise + plan v2 起草 = sprint α 完走 + 起票 Draft 後の sprint β round 1 plan v1 Codex review (= agentId `a27e5cf2ade7b3234`、 elapsed 4m29s) **revise** + 2 must-fix + 3 nice-to-have + 3 latent-risk + per-axis verdict (= AXIS-1 WARN + AXIS-2 FAIL + AXIS-3 PASS + AXIS-4 FAIL + AXIS-5 PASS)。 main agent autonomous (= user mandate「sha256 維持崩れ / allowed-touch 拡張 / 別 ADR scope 変更時のみ user 判断」 適用、 mf-1/mf-2 全 technical detail 訂正 + scope 内 = 全自律進行可能) で plan v2 起草。 ADR doc 修正範囲 = (1) Annex β-2 新規追加 = plan v2 = 7 sub-section (= β-2-1 scope 不変 carry + must-fix overview + β-2-2 mf-1 chip_type guard 追加 = `comat` 内 `PART_OFF_CHIP_TYPE(ix)` check + CHIP_TYPE=2 → `comat_pcm` 既存維持 + FM=0 only PMDDOTNET helper dispatch + SSG/other no-op (= scope OUT (2) literal) + β-2-3 mf-2 voice record format 訂正 = ground truth from mc.cs:1838-1880 `nd_s_loop` literal = sparse emit `[1 byte voice_num][25 byte voice data]` (= `prg_num[bx] != 0` 時のみ) + terminator `[0x00, 0xFF]` low/high 順 (= mc.cs:1872-1876 (byte)0xff00 + (byte)(0xff00 >> 8) literal) + ALG/FB offset = byte 24 of voice record (= driver `pmdneo_fm_voice_set` line 1315-1320 `ld de,#24` + `add hl,de` + `ld c,(hl)` literal 整合、 NOT +21 = plan v1 誤り) + β-2-4 helper routine `pmdneo_comat_pmddotnet_voice_load` design v2 literal (= scan loop + match + safe default + register contract preserve IX/IY + clobber A/B/C/D/E/H/L + 候補 A 直接 `pmdneo_fm_voice_set` call + 候補 B slot reorder scratch RAM 経由 = γ impl で確定) + β-2-5 lr-1/lr-2/lr-3 acknowledge + mitigation = slot order verify + voice 0 vs terminator detection 順序 + δ-5 + δ-6 両方 PASS が success 条件 + β-2-6 γ impl order plan v2 = 7 step (= worktree 再作成 + 新規 fixture 配置 + chip_type guard + helper routine + sdasz80 build + .lst predicate + 4 build matrix B1-B4 + δ functional + **δ-6 trace gate 強化**) + β-2-7 Codex round 2 重点軸 9 件 (= mf-1/mf-2 反映 + nh-1/nh-2/nh-3 反映 + lr-1/lr-2/lr-3 acknowledge + AXIS-3/AXIS-5 unchanged carry confirm)) + (2) 改訂履歴 sprint β round 1 + plan v2 entry append (= 本 entry、 append only mandate 厳守 = 既存 起票 entry の後ろに append、 chronological order 正常維持) + (3) dashboard 0072 行 status update placeholder (= 別 commit で同時実施、 fix-up separate commit pattern carry)。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0071 本文 + Annex / 既存 scripts / 既存 Annex α-1〜α-6 + β-1 (= immutable history) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch / 集約 branch 上 user 別作業 = 全完全 untouched。 production sha256 = `457a237c...` 維持期待 (= sprint β round 1 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0071 sprint β round 1 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #154 base) + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 2 on Annex β-2 plan v2 (= 9 重点軸 = mf-1/mf-2 反映確認 + nh-1/nh-2/nh-3 反映 + lr-1/lr-2/lr-3 acknowledge + AXIS-3/AXIS-5 unchanged carry) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 12 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 + 新規 fixture 配置 mandate)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default、 user 判断 = sha256 維持崩れ / allowed-touch 拡張 (= 既 ADR pattern 外への拡張) / 別 ADR scope 変更時のみ。 | (= 本 plan v2 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0072 起票 Draft = PMDNEO driver-PMDDOTNET voice opcode data delivery repair sprint (= sprint α scope = root cause investigation 完走 + 5 並走 sub-agent investigation (= 2 agent success via `git show` workaround + 3 agent preflight FAIL on worktree base ref mismatch 9 件 guard re-trigger 2 回目) + Annex α 6 sub-section literal record (= α-1 agent 1 finding + α-2 agent 4 finding + α-3 main agent direct analysis on allowed-touch/sha256 framework + α-4/α-5/α-6 preflight fail literal record) + Annex β-1 plan v1 起草 + sub-sprint chain α/β/γ/δ/ε 5 段 plan literal、 ADR-0071 ε Accepted 後 δ verify で発見した voice opcode @N PMDDOTNET 経路未解釈 (= ADR-0071 §決定 1 scope OUT (5) literal 該当) の engineering repair sprint、 user 明示「voice opcode @N PMDDOTNET 経路解釈 follow-up sprint が自然 + Claude Code 主担当 + まず root cause 調査 + allowed-touch/sha256 方針を先に明記 + Codex Rescue plan review 必須 + user audition / δ 再開には進まない」 mandate 経路、 真の root cause = voice opcode emit 形式は PMD V4.8s + PMDDotNET で byte-identical (= `0xFF N` 2-byte) + driver `comat` handler 既存 (= line 4419)、 真の問題 = driver の voice_table lookup が compile.py 経路 separate label table を expect、 PMDDOTNET 経路 inline voice table (= pmddotnet_song.m 内 slot-interleaved 25 byte format) を読まない設計、 推奨修理経路 = (a) driver-side guarded change (= ADR-0071 precedent 同 pattern)、 production sha256 = `457a237c...` 維持期待 (= 本 sprint α doc-only で build しない、 carry))。 ADR doc 修正範囲 = (1) ADR-0072 file 新規 (= 8 決定 + verify gate + Annex α 6 sub-section + Annex β-1 plan v1 + Annex β-2/3/4 placeholder + 改訂履歴 + 平易要約) + (2) dashboard 0072 行 add + (3) dashboard escalation 履歴 ADR-0072 entry 追加 + (4) memory + MEMORY.md = merge 後 main agent direct。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0041〜0071 本文 + Annex / 既存 scripts 完全不変。 commit chain = 単一 commit (= 本 commit、 ADR-0071 起票 precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` + (2) merge atomic 12 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review on Annex β-1 plan v1 (= user 明示 5 重点軸 = driver-side fix 仮説 + 真 root cause confirmed + sha256 維持可否 + allowed-touch limited + verify plan 実効化) + approve loop + main agent 経路 merge + atomic 1 セット 12 回目適用予定 + memory + dashboard maintenance + γ sub-sprint impl 着手判断 (= main agent autonomous default)。 | (= 本起票 commit chain 内 commit 1) |

## 平易要約

### ADR-0072 でやりたいこと

ADR-0071 ε Accepted 後の δ MAME runtime functional verify (= 2026-05-27 43rd session main agent autonomous default task 2) で発見した、 PMDDOTNET_MML 経路で `@N` voice change opcode が dispatch されても voice data が FM register に load されない issue (= audio silent) を repair する。 5 並走 sub-agent investigation で真の root cause = voice opcode emit 形式は問題なし (= byte-identical to PMD V4.8s) + driver handler 既存 (= `comat` line 4419) + **voice DATA delivery 形式が PMDNEO compile.py 経路 separate label table を expect する設計と PMDDOTNET 経路 inline voice table 形式の不整合** と確定。

### ADR-0072 前提

- ADR-0071 ε Accepted (= PR #153 MERGED at `665b494`) + δ verify findings (= 4 gate PASS + δ-5 FAIL on scope OUT)
- 5 並走 sub-agent investigation (= 2 success via `git show` workaround + 3 preflight FAIL 機械的 escalation)
- user 明示「voice opcode @N PMDDOTNET 経路解釈 follow-up sprint が自然 + Claude Code 主担当」 mandate

### ADR-0072 でやること

- sprint α (= 本 PR1) = 5 並走 sub-agent investigation + Annex α 6 sub-section literal record + Annex β-1 plan v1 起草 + 起票 Draft
- sprint β = Codex Rescue plan review chain (= revise → plan v2/v3 iteration → approve)
- sprint γ = (a) driver-side fix 経路 = `comat` routine guarded change + 新規 helper routine additive
- sprint δ = MAME runtime functional verify (= δ-5 engineering gate executor Layer 1 wav 非 silent confirm が primary success metric)
- sprint ε = Draft → Accepted + Annex 全統合 + 「driver-PMDDOTNET voice opcode data delivery repair 完了」 milestone wording 解禁 (= 併記必須)

### ADR-0072 起票後の結果

- driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0041〜0071 本文 + Annex / 既存 scripts 完全不変
- production sha256 = `457a237c...` 維持 (= 本 sprint α doc-only carry)
- 5 並走 sub-agent default 規律 + worktree base ref mismatch 9 件 guard 規律 2 回目機能実証

### ADR-0072 ε Accepted 後の解釈 (= future)

- 「driver-PMDDOTNET voice opcode data delivery repair 完了」 wording 解禁 (= 併記必須 6 件)
- ADR-0065 ε audition session 再開 trigger 発火 (= ただし user 介入 mandatory + audition material 再設計必要)
- voice load mismatch root cause 解消 = MAME runtime で実音 audible 経路確立 (= δ-1〜δ-3 + δ-5 ALL PASS expected after γ impl)

### Annex β supersede pointer (= ADR-0071 precedent 継承)

本 ADR-0072 sprint α 起票時点 (= plan v1 era) は driver-side fix 候補 (a) を推奨案として記載。 sprint β Codex Rescue plan review で plan v2/v3 iteration の可能性あり、 最新 plan iteration が ground truth。 sprint γ impl 実装者は最新 Annex β を参照 (= ADR-0071 §決定 1 supersede pointer precedent 同 pattern)。
