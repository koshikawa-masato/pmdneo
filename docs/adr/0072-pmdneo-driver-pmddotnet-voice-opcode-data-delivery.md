# ADR-0072: PMDNEO driver-PMDDOTNET voice opcode data delivery repair (= voice_table lookup vs inline voice table mismatch)

- 状態: **Draft** (= 2026-05-27 43rd session 起票、 ADR-0071 ε Accepted (= PR #153 MERGED at `665b494`) + δ MAME runtime functional verify (= 4 gate PASS + δ-5 FAIL on scope-out = voice opcode @N PMDDOTNET 経路未解釈) で発見した voice opcode data delivery mismatch の engineering repair sprint、 5 並走 sub-agent investigation 起動 (= 2 agent success via `git show` workaround + 3 agent preflight FAIL on worktree base ref mismatch = memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` 9 件 guard re-trigger)、 sub-sprint chain α/β/γ/δ/ε 5 段 plan literal、 main agent autonomous default + user 判断 scope = sha256 維持崩れ / allowed-touch 拡張 / scope 変更時のみ)
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
- binary layout = .M binary inline voice table = `[1 byte voice_num][25 byte voice_buf data]` × N + `[0xFF 0x00]` terminator
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
| voice table format | **inline in .M binary** `[voice_num][25 byte]...[0xFF 0x00]` | **separate Z80 source labels** `voice_table: .dw voiceN_data` |
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

## Annex β-2/β-3/β-4: δ verify result / ε Accepted milestone (= sprint β/γ/δ/ε で fill)

placeholder。

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
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
