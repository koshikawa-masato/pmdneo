# ADR-0071: PMDNEO driver-PMDDOTNET integration repair (= rest 0x0F handling + SSG mixer enable)

- 状態: **Draft** (= 2026-05-27 43rd session 起票、 ADR-0065 sprint B follow-up integration verify (= 2026-05-26) で発見した driver-PMDDOTNET integration 2 bug の engineering repair sprint、 4 並走 sub-agent investigation 完了 = Annex α literal record、 sub-sprint chain α/β/γ/δ/ε 5 段 plan literal、 main agent autonomous default + user 判断 scope = sha256 維持崩れ / allowed-touch 拡張 / scope 変更時のみ)
- 起票日: 2026-05-27
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 user 明示「Claude Code 主担当で進めてください」)
- 関連 ADR:
  - **ADR-0065** (= roadmap ⑥ audition、 sprint B follow-up integration verify で本 bug 発見、 §決定 13 4 層 engineering gate framework が本 bug を検出した実証)
  - **ADR-0069** (= A-J distinctness 拡張、 load layer 完成、 dispatch layer 未完成発覚 = 本 ADR が補完)
  - **ADR-0068** (= 16 ch integration trace、 既存 verify script regression 維持対象)
  - **ADR-0067** (= 16 ch fixture 拡張、 既存 verify script regression 維持対象)
  - **ADR-0058** (= roadmap ② v2 dispatcher、 `pmdneo_v2_part_parse` で 0x90 rest 正常 handle = option A repair precedent)
  - **ADR-0048** (= 軸 G dynamic supply、 partial state placement 不可触対象継承)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 + 並走 sub-agent + §決定 12 worktree isolation)
  - **ADR-0026** (= §決定 3/4 K dispatch L ch 固定占有 不可触対象継承)
  - **ADR-0050** (= fadeout-semantics、 PMDNEO_NO_FADE harness flag precedent、 issue 3 scope-out 根拠)
- 関連 memory:
  - `feedback_codex_rescue_audition_material_review_prompt.md` (= 4 層 engineering gate framework executor、 本 ADR の verify gate base)
  - `feedback_main_agent_engineering_responsibility.md` (= repair = main agent autonomous + user judgment = 設計不可逆/scope 変更/aesthetic/本番切替のみ)
  - `feedback_pr_merge_branch_delete_atomic.md` (= branch 運用 4 条 + atomic 1 セット規律)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal)
  - `feedback_parallel_subagent_investigation_default.md` (= 4 並走 sub-agent default + ADR-0071 起票 phase で適用済)
  - `feedback_long_running_hang_auto_recovery_rule.md` (= build / verify hang threshold)
  - `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= worktree base ref mismatch flag、 agent 1/2/4 で発生確認)

## 背景

### sprint B follow-up integration verify で発見した 4 finding

2026-05-26 42nd session ADR-0065 sprint B 完走後 (= PR #152 MERGED at `70230d1`)、 sprint B follow-up integration verify (= `scripts/analyze-audition-wav.py` 4 層 engineering gate を user 提供 candidate 2 v2 staircase wav + candidate 3 wav に適用) で driver-PMDDOTNET integration の不具合発覚:

- candidate 2 v3 staircase render (= PMDNEO_USE_PMDDOTNET=1 + 8 part B/C/E/F/G/H/I/J) → **bar 0 (= B/J) のみ audible、 bar 1-7 (= C/E/F/G/H/I) 完全 silent**
- 既存 `src/tools/pmd-mml/fm-active-ladder.mml` (= FM 4 ch B/C/E/F staircase) render → **B/C audible、 E/F 完全 silent**
- 既存 `src/tools/pmd-mml/ssg-active-ladder.mml` (= SSG 3 ch G/H/I staircase) render → **G/H audible-like (= 実は FM bleed)、 I 完全 silent**
- 全 render 末尾 14.4-16.8 sec に **RMS -14.15 dBFS / peak 5.4 Hz / low_freq 0.9993 の sub-bass artifact** 共通発生

### user 観測 41st session δ session 試行 invalid 経路 と 整合性確認

ADR-0065 Annex β-8-2 literal user 観測 evidence:
- candidate 2 SAMPLE2.MML 「ものすごい低音持続」
- candidate 3 l-q-rhythm-song.mml 「無音 fadeout」

= 本 ADR-0071 sub-agent investigation 4 finding と整合確認:
- 「ものすごい低音持続」 = FM bleed harmonic + SSG mute + tail artifact 合算結果
- 「無音 fadeout」 = SSG mixer mute + driver 末尾 fade trigger artifact

### sprint A engineering gate framework が本 bug を検出した実証

ADR-0065 §決定 13 engineering gate 4 層 framework (= sprint A 永久 design 化、 sprint B `scripts/analyze-audition-wav.py` 実装完了) が本 bug を **「user audition 前段で process failure として確実に reject」** することを sprint B follow-up integration verify で実証。

= sprint A + sprint B framework の **設計通り動作** = 41st session δ session 試行 invalid (= 「render 不成立 material を user audition に出した」 process failure) の再発を engineering gate が未然防止した実証。

### 4 並走 sub-agent investigation 起動 + root cause 確定

user 明示 mandate「driver 修理を伴うなら別 ADR / 別 sub-sprint として切る方が安全」 を受け、 ADR-0071 起票 + 4 並走 sub-agent investigation (= memory `feedback_parallel_subagent_investigation_default.md` 適用) 実施:

- agent 1 (= `a1d35d89aa90b5f76`) = issue 1 = 3rd+ part dispatch silent root cause → **rest opcode 0x0F handler missing 確定 (= confidence high)**
- agent 2 (= `a6a68b892193cded5`) = issue 2 = pitch/frequency 異常 root cause → **3 仮説確定 (= FFT artifact 80% + SSG mixer mute 85% + voice 経路 95%)**
- agent 3 (= `a96c0520e9be2b697`) = issue 3 = 末尾 sub-bass artifact 切分け → **harness flag PMDNEO_NO_FADE=1 渡し忘れ確定 (= confidence ≥95%)**
- agent 4 (= `a34df6cbc138382da`) = regression + sha256 + allowed-touch 方針 → **5 軸 framework 確定 (= sha256 維持 / touch range / regression / sub-sprint chain / rollback)**

= 4 finding cross-synthesis で driver 真の bug = **2 件のみ** (= rest 0x0F handler + SSG mixer enable)、 残り 2 件 (= FFT artifact + harness flag) は driver 修理 scope 外 確定。

## 決定

### 決定 1: ADR-0071 scope = driver source 2 bug 修理に限定 (= user 明示 scope narrowing)

#### scope IN (= ADR-0071 で修理)

- **(1) `pmdneo_part_main_parse` (= `src/driver/standalone_test.s` line 3725-3733 周辺) に PMDDotNET rest opcode `0x0F` low-nibble handler 追加**
  - 既存 `cp #0x90` (= compile.py 形式 rest) はそのまま維持、 PMDDotNET emit 形式 (= `0x0F` byte + length byte) を新規 handler 経路で受ける
  - 既存 `pmdneo_part_main_rest` (= line 3806-3810) の length 解釈 logic を reuse、 keyon path 実行せず PART_OFF_LEN だけ set
  - = ADR-0058 §決定 1-2 v2 dispatcher (= `pmdneo_v2_part_parse`) が 0x90 rest を正しく handle する precedent 同 pattern を **legacy parser に同種 handler 追加**

- **(2) `pmdneo_psg_keyon` (= `src/driver/standalone_test.s` line 2407 周辺) に SSG mixer enable bit clear 追加**
  - YM2610 SSG mixer reg 0x07 (= bit 0/1/2 = ch1/2/3 tone enable、 inverted: 1=disable / 0=enable) は `nmi_cmd_5_init_mml_song` (= line 1170-1173) で 0x3F (= all disable) initialize、 keyon path で一度も touch されない = G/H/I 全 silent
  - 修理 = `pmdneo_psg_keyon` に read-modify-write 追加 = reg 0x07 read → ch_idx 対応 bit clear (= `& ~(1 << ch_idx)`) → reg 0x07 write
  - chip register write 経路は ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) と無関係 (= SSG mixer 別 register area)

#### scope OUT (= 別軸 / 別 ADR future、 ADR-0071 では touch しない)

- **(3) `scripts/analyze-audio.py` FFT / fundamental 検出改善** = agent 2 仮説 1 (= FFT argmax artifact、 driver は正しく 261.97 Hz 出力中)、 別 task で `scripts/analyze-audio.py` の `compute_top_freq_peaks` を argmax bin → fundamental peak detection (= autocorrelation / cepstrum 等) に semantic 修正。 driver source touch 不要、 sha256 不変。
- **(4) `PMDNEO_NO_FADE=1` harness flag 運用 doc** = agent 3 確定 (= ADR-0050 §決定 1-8 + PR #65 既存 precedent)、 別軸で sprint A engineering gate framework に「audition material render 時は PMDNEO_NO_FADE=1 必須」 doc append 候補。 driver source touch 不要。
- **(5) MML voice opcode / `@N` 対応** = agent 2 仮説 3 (= compile.py `@` skip + driver `commandsp` 0xFF unhandled)。 ただし PMDDOTNET 経路では PMDDotNET compiler が voice opcode を正しく emit するため本件 issue 1/2B と独立、 別 ADR / 別 sprint scope。
- **(6) K bitmap pair distinct** = ADR-0070 候補 (= ADR-0069 γ Accepted 後 future、 user 明示 GO 必須)、 本 ADR と独立。

### 決定 2: sub-sprint chain plan = α/β/γ/δ/ε 5 段 (= ADR-0067/0068/0069 precedent)

| sub | scope | user 介入 | 完了判定 | driver touch |
|---|---|---|---|---|
| **α** | root cause investigation 完走 + Annex α 4 sub-section literal record (= 本 doc + 4 sub-agent return synthesis) | optional | ADR-0071 Draft 起票 + Annex α fill + Codex layer 2 plan review approve (= **本 PR1 scope**) | なし (= doc-only) |
| **β** | repair plan v1 + Codex Rescue plan review approve (= driver root cause 仮説 + repair plan 重点 review、 doc wording 不要 mandate) | optional | plan v1 Codex approve | なし (= doc-only) |
| **γ** | repair implementation = driver source 2 routine 修正 (= guarded change `.if PMDNEO_USE_PMDDOTNET == 1` pattern) | optional (= main agent autonomous + Codex Rescue review-only) | impl 完了 + 4 build matrix PASS + production sha256 byte-identical 維持 confirm + 既存 routine body 不変 confirm | **あり** (= `pmdneo_part_main_parse` + `pmdneo_psg_keyon` 周辺のみ) |
| **δ** | repair verify = FM/SSG active ladder render → 3rd+ part audible + SSG mixer enabled + 既存 18+ verify script regression 全 PASS | optional | 全 verify gate ALL PASS literal record + Annex δ fill | なし (= verify only、 driver untouched) |
| **ε** | Accepted 移行 doc-only = Draft → Accepted + Annex 全統合 + 「driver-PMDDOTNET integration repair 完了」 milestone wording 解禁 (= 併記必須) + ADR-0065 audition material 再設計 trigger 解除 record | optional | Accepted milestone + ADR-0065 audition material 再開 trigger 発火 | なし (= doc-only) |

### 決定 3: production sha256 維持方針 (= user 明示 mandate)

production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` **維持 mandate**。

両 driver 修理は **`.if PMDNEO_USE_PMDDOTNET == 1 ... .endif` guarded change pattern** (= ADR-0069 §決定 4 precedent) で実装し、 production default build (= `PMDNEO_USE_PMDDOTNET=0`) では **byte-identical 維持**。

guarded change で実装不可能 (= 修理 routine が両 build mode 共通で sha256 衝突不可避) と判明した場合は **user 明示 GO + 新 baseline 設定 (= agent 4 軸 1 option (A)) へ pivot**、 main agent 自走では実施しない。

#### γ 実装時の検証

- 4 build matrix PASS:
  - (A) production default build = `PMDNEO_USE_PMDDOTNET=0` + `PMDNEO_TARGET_CHIP_YM2610B=0` → sha256 == `b15883fe...` byte-identical confirm
  - (A2) production AES+ build = `PMDNEO_USE_PMDDOTNET=0` + `PMDNEO_TARGET_CHIP_YM2610B=1` → 既存 sha256 維持 confirm (= ADR-0069 §決定 4 整合)
  - (C-1) PMDDOTNET ym2610 build = `PMDNEO_USE_PMDDOTNET=1` + `PMDNEO_TARGET_CHIP_YM2610B=0` → 修理機能動作 (= 新 sha256、 但し production と独立)
  - (C-2) PMDDOTNET ym2610b build = `PMDNEO_USE_PMDDOTNET=1` + `PMDNEO_TARGET_CHIP_YM2610B=1` → 同上
- production sha256 不一致時 = rollback condition #1 発火 (= ADR-0069 §決定 5 継承)

### 決定 4: allowed-touch literal

#### (i) repo diff allowed-touch (= ADR-0071 各 PR 対象 file)

| file | range | 修理対象 |
|---|---|---|
| `src/driver/standalone_test.s` | line 3725-3733 周辺 (= `pmdneo_part_main_parse`) | issue 1 = rest 0x0F handler 追加 |
| `src/driver/standalone_test.s` | line 2407 周辺 (= `pmdneo_psg_keyon`) | issue 2B = SSG mixer enable bit clear 追加 |
| `docs/adr/0071-pmdneo-driver-pmddotnet-integration-repair.md` | 本 file | sprint α/β/γ/δ/ε 各 fill |
| `src/test-fixtures/adr-0071/` | 新規 directory | δ verify script 新規 (= 4 script proposal、 詳細 Annex β) |
| `docs/parallel-axes-dashboard.md` | 0071 行 add + escalation 履歴 entry | dashboard update |

#### (ii) 不可触対象 (= 完全不変)

- `src/driver/standalone_test.s` 他 routine body 全 (= 修理対象 2 routine 以外、 sha256 production carry mandate)
- `src/driver/IRQ.inc` / `PMD_Z80.inc` / `REGMAP.inc` / `ADPCMA_DRV.inc` / `ADPCMB_DRV.inc` / `KR_STUB.inc` / `WORKAREA.inc` (= 修理に不要)
- vendor (= `vendor/pmd48s/` + `vendor/ngdevkit-examples/` + `vendor/PMDDotNET/`)
- 既存 fixture MML (= `src/test-fixtures/axis-b/aj-distinctness-fixture.mml` + `src/test-fixtures/step5/` 系等 + `src/tools/pmd-mml/` 系)
- 既存 verify script (= ADR-0049〜0070 全)
- 既存 build flag (= 新規 flag 追加なし、 既存 flag 意味変更なし)
- ADR-0041〜0070 本文 + Annex
- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38)
- ADR-0026 §決定 3/4
- `scripts/analyze-audio.py` / `scripts/analyze-audition-wav.py` / `scripts/test_analyze_audition_wav.py` (= sprint A/B 成果物、 利用のみ)
- `wip-dashboard-coverage` branch + `docs/dashboard/` untracked
- 退避 branch `wip-dashboard-progress-heatmap-from-a8b8cc5`
- 集約 branch 上 user 別作業 untracked

### 決定 5: verify gate literal

#### γ build verify (= production sha256 維持 + 4 build PASS)

- gate γ-1: 4 build matrix PASS (= 決定 3 § γ 実装時の検証 literal)
- gate γ-2: production sha256 byte-identical 維持 (= `b15883fe...` ALL build mode (A)/(A2) で)
- gate γ-3: `.lst` predicate (= 修理 routine size + section overflow check、 memory `feedback_org_section_overflow_silent_bug.md` 整合)
- gate γ-4: 既存 routine body 完全不変 (= `git diff` で修理 2 routine 以外 0 line 変更 confirm)

#### δ functional verify (= 実音成立確認、 user 明示「実音成立を確認」 mandate)

- gate δ-1: **fm-active-ladder.mml render → bar 0-3 全 (B/C/E/F) audible** (= RMS > silence threshold、 期待 keyon timing で chip register write 確認)
- gate δ-2: **ssg-active-ladder.mml render → bar 0-2 全 (G/H/I) audible** (= SSG mixer reg 0x07 active bit literal record、 各 ch tone period register write 確認)
- gate δ-3: candidate 2 v3 staircase render (= 8 part B/C/E/F/G/H/I/J) → 全 part audible
- gate δ-4: 既存 18+ verify script (= ADR-0049〜0070) 全 PASS 維持 (= 特に ADR-0067/0068 16ch integration + ADR-0069 aj-distinctness gate-3a/3b/3c/3d)
- gate δ-5: `scripts/analyze-audition-wav.py` 4 層 ALL PASS on FM + SSG ladder render (= LOW_FREQ_DOMINANCE_THRESHOLD 0.7 は本 ADR で touch しない、 別軸 LR1 calibration future)
- gate δ-6: tail artifact は `PMDNEO_NO_FADE=1` harness flag で抑制した render で verify (= driver 修理 scope と分離、 issue 3 別軸対応)

### 決定 6: rollback condition (= ADR-0069 §決定 5 11 condition 継承 + ADR-0071 固有 2 件)

ADR-0069 §決定 5 11 unique rollback condition + 4 段 stop action + 3 段 responsibility + destructive git 禁止 (= `git revert` のみ) **完全継承**。

ADR-0071 固有追加:

- **#12 = 既存 verify regression** = ADR-0049〜0070 18+ verify script のいずれか FAIL → 即 sub-sprint halt + revert + scope 検討
- **#13 = engineering gate FAIL on FM/SSG ladder** = δ verify gate δ-1/δ-2/δ-3 のいずれか FAIL (= 3rd+ part silent or SSG silent 残存) → 1 retry → 再 FAIL なら sub-sprint halt + 設計再評価 + Codex Rescue review 再起動

### 決定 7: 表記制約 + 解禁表現候補

#### ADR-0071 起票時点 (= 本 sprint α)

| 表現 | 起票時点 |
|---|---|
| 「driver-PMDDOTNET integration repair 完了」 | **literal 禁止** (= ADR-0071 ε Accepted 後解禁、 併記必須 = 「本 ADR sub-sprint 範囲完走」 + 「ADR-0065 audition material 再設計 trigger 解除 ready」 + 「production-ready 全体達成ではない」 + 「軸 B 完成ではない」) |
| 「(d) audition gate 達成」 / 「越川氏 audition approve」 / 「roadmap ⑥ audition 完了」 | **literal 禁止維持** (= ADR-0065 ε 後解禁候補、 ADR-0071 とは独立) |
| 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 | **literal 禁止維持** (= 永久) |
| 「16ch full candidate distinctness 完了」 | **literal 禁止維持** (= ADR-0070 完走条件) |
| 「A-J candidate distinctness 達成」 | 既存 ADR-0069 γ Accepted で解禁済、 ただし本 ADR で「A-J **MML driven** distinctness」 wording を追加するかは ε 判断 (= ADR-0069 = load layer distinctness、 ADR-0071 = MML driven dispatch correctness 軸別) |

#### ADR-0071 ε Accepted 後 (= 解禁候補)

| 表現 | ε Accepted 後 |
|---|---|
| 「driver-PMDDOTNET integration repair 完了」 | **解禁** + 併記必須 4 件 (= 上記) |
| 「PMDDOTNET MML driven A-J active part audible 達成」 | **解禁候補** (= δ verify gate δ-1/δ-2/δ-3 ALL PASS 経路前提、 ε で判断) |
| 「production-ready 全体達成」 / 「軸 B 完成」 / 「本番 cmd 切替完了」 | **禁止維持** |
| 「ADR-0065 audition material 再設計 trigger 解除」 | **解禁** (= ε で発火 record、 user 明示 GO で δ session 起票判断 ready) |

### 決定 8: 番号 chronology rationale + ADR 関連順序

- ADR-0065 (= roadmap ⑥ audition、 sprint A/B 完走、 sprint B follow-up integration verify で本件発見)
- ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替、 ADR-0065 ε Accepted 後 future)
- ADR-0067/0068 (= 16ch fixture + integration verify、 完了)
- ADR-0069 (= A-J distinctness load layer、 完了、 dispatch layer 不足発覚 = 本 ADR で補完)
- ADR-0070 候補 (= K bitmap pair distinct、 ADR-0069 γ Accepted 後 future)
- **ADR-0071 (= driver-PMDDOTNET integration repair、 本 ADR)**
- ADR-0072+ 候補 (= analyze-audio.py FFT 改善 + voice opcode 対応等、 別軸 future)

dependency 順序固定:
- **ADR-0071 ε Accepted → ADR-0065 audition material 再設計 trigger 解除 → user 明示 GO で δ session 起票判断**
- ADR-0070/0066 = ADR-0071 と独立、 user 明示 GO で各起票

## verify gate (= 本 PR1 sprint α scope = doc-only、 spec consistency check)

- gate 1: ADR-0071 file 新規作成 + 8 決定 literal coverage
- gate 2: Annex α 4 sub-section literal fill (= 4 sub-agent finding synthesis)
- gate 3: Annex β-1 plan v1 literal fill (= repair plan + sha256 維持 + allowed-touch + verify + risks)
- gate 4: dashboard 0071 行 add (= 「Draft 起票」 + 12 決定 概要)
- gate 5: dashboard escalation 履歴 ADR-0071 entry
- gate 6: 不可触対象 完全不変 confirm (= `git diff` で driver source / vendor / 既存 ADR / 既存 verify / 既存 scripts 0 line)
- gate 7: 禁止 wording 4 件 (= 「driver-PMDDOTNET integration repair 完了」 + 「(d) audition gate 達成」 + 「production-ready 全体達成」 + 「16ch full candidate distinctness 完了」) literal 禁止 confirm
- gate 8: production sha256 = `b15883fe...` 維持 confirm (= ADR-0071 sprint α は doc-only、 build しない、 carry)
- gate 9: branch 運用 4 条規律 confirm (= PR 先 `wip-pmddotnet-opnb-extension` + atomic 1 セット規律 11 回目適用予定 + 保持対象 3 type 不可触)

## Codex layer 2 plan review chain

(= sprint α + β で fill、 詳細 Annex β-1 Codex review chain section)

## Annex α: root cause investigation 4 sub-agent finding synthesis (= sprint α scope literal fill)

### α-1: agent 1 finding = issue 1 = **PMDDotNET rest opcode 0x0F handler missing** (= confidence high)

#### 確定 root cause

PMDDotNET compiler は MML rest を **byte `0x0F` + length byte** で coalesce emit (= `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:6144-6149` `otor()` + 同 file `:6385-6391` `otoset_x()` + `:6422-6428` `bp8b` literal)。 PMDDotNET driver `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs:6311-6319` `fnumset()` で `r.al & 0xf == 0xf` → `fnrest()` (= fnum=0 + onkai=-1 = keyon せず無音 hold) で rest 判定。

PMDNEO driver `src/driver/standalone_test.s:3725-3733` `pmdneo_part_main_parse` は **`cp #0x90` のみ rest check**:

```asm
pmdneo_part_main_parse:
        call    pmdneo_part_fetch_byte         ; A = MML byte
        cp      #0x80
        jp      z, pmdneo_part_main_loop        ; 0x80 = end of music
        cp      #0x90
        jp      z, pmdneo_part_main_rest        ; 0x90 = rest (compile.py 形式のみ)
        jp      c, pmdneo_part_main_note        ; A < 0x90 → note path  ← BUG !!
        call    commandsp
        jp      pmdneo_part_main_parse
```

= PMDDotNET emit の `0x0F` byte は `cp #0x90` で z=0、 c=1 (= 0x0F < 0x90) → `jp c, pmdneo_part_main_note` 分岐 → **note path で keyon path 実行**。

#### byte literal verification (= agent 1 が `xxd` で実 confirm)

- G part body (= no rest): `fc 64 fe 08 30 18 30 18 30 18 30 18 80` (= tempo + q + 4 note + end)
- H part body (= `r4×4 d×4`): `fc 64 fe 08 **0f 60** 32 18 32 18 32 18 32 18 80` (= **REST `0x0F` len `0x60`** + 4 note + end)
- I part body (= `r4×8 e×4`): `fc 64 fe 08 **0f c0** 34 18 34 18 34 18 34 18 80` (= REST `0x0F` len `0xC0`)

#### garbage dispatch 詳細

A=0x0F 入力で `pmdneo_part_main_note` → fnumset_fm / fnumset_ssg 経由:
- `and #0x0F` → ONKAI=15 → `fnum_data[15]` = **table 12 entry 境界 overflow read** (= 隣接 `psg_tune_data` の途中 byte を fnum として誤読)
- octave path: A=0x0F → `rrca×4` → 0xF0 → `and #0x07` → 0x00 → `dec a` → 0xFF (= byte underflow) → register address 計算狂い (= 0x9C / 0x98 = SSG-EG 領域 = BLOCK/FNUM register address ではない)
- chip BLOCK/FNUM register (= 0xA0-0xA6) は default value (= chip reset 後 0) のまま update されない → fnum=0 → **chip 無発振 = silent**
- その後 `fm_keyon` で reg 0x28 に keyon mask 書込 (= 0xF0+ch、 全 op enable) — keyon は実行されるが fnum=0 のため音は出ない

#### 「3rd+ part」 は coincidence

真因は **「rest-token-first part」**:
- B part (= no rest)、 G part (= no rest) audible
- C/E/F/H/I part (= rest 先頭) silent

ladder MML 構造で part 順序と先頭 rest 数が比例 = 順序 pattern として観測されたが、 順序は無関係。

#### ADR-0058 v2 precedent

`pmdneo_v2_part_parse` (= `src/driver/standalone_test.s:2971-3027`) は 0x90 rest を正しく handle = legacy parse 経路に同種 handler 追加が **option A repair pattern の precedent**。

#### why undetected (= 過去 verify gate を passing した理由)

`src/test-fixtures/axis-b/aj-distinctness-fixture.mml` (= ADR-0069 verify base) は **各 part 単音 1 note のみ + rest 完全不在**、 全 verify gate (= gate-3a/3b/3c/3d 等) は **rest path を一切 exercise していない**。 ladder fixture が初の rest-containing test。

### α-2: agent 2 finding = issue 2 = **pitch 異常 = 3 仮説に分解** (= confidence high)

#### 仮説 1 = FFT 計測 artifact (= driver は正しく 261.97 Hz 出力中、 confidence 80%)

PMDNEO `fnum_data` table (= `src/driver/standalone_test.s:756-768`) = PMD V4.8s 公式 (= `vendor/pmd48s/source/pmd48s/PMD.ASM:15851-15862`) と **完全 byte-identical** (= C=0x026A, C#=0x028F, ..., B=0x048F)。

`fnumset_fm` (= `src/driver/standalone_test.s:589-664`) で o4 c (= note byte 0x40) → BLOCK=4, FNUM=0x26A 抽出 → reg 0xA5 (BLOCK_FNUM_2 ch2) ← 0x22, reg 0xA1 (FNUM_LOW ch2) ← 0x6A 書込 (= PMD V4.8s `fnumset` line 4266-4291 と同等)。

ymfm phase step formula (= `vendor/mame-fork/3rdparty/ymfm/src/ymfm_opn.cpp:362-394`) = `phase_step = (fnum << 1 << block) >> 2`、 NEOGEO master_clock = 8 MHz、 sample_rate = master_clock / 144。

計算: F = (8e6 / 144) × (618 × 2 × 16 / 4) / 2^20 = 55555 × 4944 / 1048576 = **261.97 Hz ≈ C4 (= 期待 fundamental)**。

= **driver は正しく C4 = 262 Hz を出力中**、 観測 3326 Hz は `scripts/analyze-audio.py:86-110` の **argmax-based FFT peak detection の artifact** (= 強い transient keyon edge × 4 で wide-band noise、 12-13 harmonic bin が fundamental より勝つ)。

#### 仮説 2 = SSG mixer 未 enable (= G/H/I 全 silent、 confidence 85%)

`nmi_cmd_5_init_mml_song` (= `src/driver/standalone_test.s:1170-1173`) で SSG mixer reg 0x07 = 0x3F (= all tone disable + all noise disable)。 `pmdneo_psg_keyon` (= line 2407) / `psg_keyon_hook` (= line 2330-2333) / `psg_volume_hook` (= line 2348-2359) で **reg 0x07 を一度も touch しない** = SSG MML 経路で mixer は永遠 0x3F = 全 mute 維持。

= SSG **G/H/I 全 silent** が真の挙動。 観測 G part 2659 Hz は **FM ch B/C audio (= L PAN ch 2 + R PAN ch 3 各 262 Hz fundamental + harmonic) からの spectrum bleed** (= 262 × 10.15 = 2659 ≈ 10 harmonic)。 観測 H part 104 Hz は noise + DC offset + ADPCM init residue。

#### 仮説 3 = MML `@N` voice 参照 silent drop (= compile.py 経路、 PMDDOTNET 経路では独立、 confidence 95%)

`src/tools/pmd-mml/compile.py:119-121` で `@` 含む unknown character は warning + skip = byte emission なし。 driver `commandsp` は 0xFF unhandled = 1 byte consume + drop。

ただし **PMDDOTNET 経路 (= 本 ADR scope) では PMDDotNET compiler が voice opcode を正しく emit**、 driver 側の voice 解釈問題は別軸。 本 ADR-0071 では仮説 3 を scope-out (= 決定 1 § scope OUT (5))。

### α-3: agent 3 finding = issue 3 = **harness flag `PMDNEO_NO_FADE=1` 渡し忘れ** (= confidence ≥95%、 driver 修理不要)

#### 確定 root cause

`vendor/ngdevkit-examples/00-template/main.c:114` で `wait_vblanks = 960` = **16.0 sec**、 同 `:152` で `*REG_SOUND = 6` 送出。 wav 解析でアーティファクト発生時刻 = ピタリ 16.0 sec (= 14.0-15.5s で -84 dBFS / -inf 無音 → 16.0-16.5s で突如 RMS -9.08 dBFS + 巨大 DC offset 0.21684)。

両 wav (= fm-active-ladder + ssg-active-ladder) の post-16s 区間が **byte-identical 数値完全一致** (= MML 内容無関係 = driver/MAME 共通 fixed source)。 既存 build artifact (= `main.o`) に `"FADE OUT..."` 文字列残存 = **PMDNEO_NO_FADE 未定義 build の動かぬ証拠**。

#### 既存解決済 precedent

ADR-0050 §決定 1-8 + PR #65 (= `docs/parallel-axes-dashboard.md:157` literal) で **`PMDNEO_NO_FADE=1` harness flag** 既追加 (= main.c + Makefile + build-poc.sh wiring)。 `src/test-fixtures/axis-b/verify-ssg-tone-enable.sh:35-36` literal `fixture: PMDNEO_NO_FADE=1 + test-tone-ladder.mml` 既存 precedent。

#### 推奨 fix = driver 修理 scope 外、 別軸 process discipline

- wav 再 render = `PMDNEO_NO_FADE=1 PMDNEO_USE_PMDDOTNET=1 bash scripts/run-mame.sh --build --headless --wavwrite --wavwrite-seconds 18` (= flag 渡すだけ、 driver / source 完全不変)
- ADR-0071 では本 issue 3 を **scope OUT** (= 決定 1 § scope OUT (4)) として明示
- sprint A engineering gate framework に「audition material render 時は `PMDNEO_NO_FADE=1` 必須」 doc append 候補は別軸 (= `feedback_codex_rescue_audition_material_review_prompt.md` の render hygiene check item 拡張)

### α-5: agent 5 finding = **真の SSG silent + pitch 異常 root cause = PMDDotNET 3-byte tempo encoding と driver 1-byte `comt` handler 不整合** (= sprint β Codex round 1 revise で agent 2 仮説 2 反証 → focused 再投資 = confidence high)

#### agent 2 仮説 2 reject 経緯 (= worktree base ref mismatch 由来)

sprint β Codex layer 2 plan review round 1 (= `ad2dc66cae5b63599`) で agent 2 仮説 2 (= 「`pmdneo_psg_keyon` で reg 0x07 touch なし」) が source level evidence で **誤り** と判明:

- 現 base anchor `36330a6` driver source の `pmdneo_psg_keyon` (= line 4590-4621) は冒頭で `pmdneo_ssg_tone_sync` を call
- `pmdneo_ssg_tone_sync` (= line 2318-2348) は **reg 0x07 RMW 唯一 owner** (= ADR-0051 §決定 3/4 契約)
- shadow = `pmdneo_v2_ssg_mixer @ 0xFD3A`
- = reg 0x07 への write は **既に実行されている**、 agent 2 「touch なし」 仮説は反証済

#### agent 2 が outdated source を見ていた真因

agent 5 escalation `merge_conflict` (= memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` 9 件 guard #2/#3 trigger):
- agent 1/2/4 worktree HEAD = `3ad1e23` (= 2026-05-11、 ADR-0051 β 実装前)
- base anchor `36330a6` (= 2026-05-26、 sprint B 完走 final maintenance) の **ancestor**
- agent 2 worktree HEAD の `src/driver/standalone_test.s` (= 2581 lines、 outdated) を base anchor (= 5938 lines、 ADR-0051 β 実装済) と誤同視
- ADR-0051 β `pmdneo_ssg_tone_sync` / `pmdneo_v2_ssg_mixer` 等 30+ symbol が outdated source に不在 → 「touch なし」 と誤判定

agent 5 は `git show 36330a6:<path>` 経由で base anchor source 直接 read → 真の root cause 発見。

#### 真の root cause = PMDDotNET 3-byte tempo encoding mismatch

**evidence (= source line literal)**:

- **PMDDotNET compiler** (= `vendor/PMDDotNET/PMDDotNETCompiler/mc.cs:7474-7479` `tempoa()`):
  ```csharp
  m_seg.m_buf.Set(work.di++, new MmlDatum(0xfc));  // t marker
  m_seg.m_buf.Set(work.di++, new MmlDatum(0xff));  // sub-cmd marker
  m_seg.m_buf.Set(work.di++, new MmlDatum((byte)work.bx));  // raw BPM
  ```
  + `mc.cs:81` `tempo_old_flag = 0` default → **3-byte emit**

- **driver `comt`** (= `src/driver/standalone_test.s:3911-3914`):
  ```asm
  comt:
      call    pmdneo_part_fetch_byte
      ld      (driver_tempo_d), a
      ret
  ```
  = **1-byte fetch のみ** (= 旧 PMD V4.8s 2-byte format `0xFC <BPM>` 同等)

- **ssg-active-ladder.mml PMDDotNET-compiled .M binary G part body** (= `xxd vendor/ngdevkit-examples/00-template/pmddotnet_song.m`):
  ```
  fc ff 64 fe 08 30 18 30 18 30 18 30 18 80
  ```
  = `0xFC 0xFF 0x64` (= 3-byte tempo cmd、 `0x64 = 100 = MML t100`) + `0xFE 0x08` (= quantize `q8`) + 4 × note + len + end

#### 誤解釈 path (= G part の例)

1. driver fetch `0xFC` → `commandsp` → `comt` → fetch **次 1 byte = 0xFF** → `driver_tempo_d = 0xFF` (= 異常高速 dispatch) → return
2. driver fetch **次 byte = 0x64** → `< 0x80` + `< 0x90` → `pmdneo_part_main_note` 経路 → **note byte = 0x64 (= OCT=6 ONKAI=4 = E6) として keyon**
3. driver fetch 次 byte = `0xFE` → length byte = 254 tick (= 異常長 keyon)
4. = **SSG G は MML 意図 (= C4 quarter × 4) ではなく E6 を 254 tick で誤 keyon**

#### 観測との整合性 verify

- user 観測 G peak 2659 Hz ≈ **E6 fundamental 1318.51 Hz × 2 = 2637 Hz** (= 2nd harmonic、 誤差 0.8%)
- tempo = `0xFF` (= raw) で IRQ tick ごとに `subtick_acc += 0xFF` overflow → 異常高速 → 短 burst → user perception 「silent」
- FM B part も同 tempo 誤解釈で同経路、 peak 3326 Hz は同 E6 系 harmonic との bleed 重畳
- = G silent (= rest 不在なのに silent) + FM B/C audible-but-wrong-pitch + SSG G/H/I 全 silent の **全観測が説明可能**

#### 修理 scope shift impact (= plan v1 → v2)

- agent 2 仮説 2 ベースの SSG mixer enable patch = **不要** (= 既存 ADR-0051 β で reg 0x07 RMW 完全動作中、 patch 追加すると owner contract 違反 + 重複)
- 真の修理 = `comt` tempo 3-byte handling 追加 (= 新規 helper routine pattern、 ADR-0051 precedent 踏襲)
- rest 0x0F handler 修理 (= agent 1 finding) も **依然必要** (= tempo 修理後も `0x0F` rest byte は別 issue として残る)
- = **真 scope = (1) rest 0x0F handler (= agent 1) + (2) tempo 3-byte handling (= agent 5)、 SSG mixer scope OUT**

#### worktree base ref mismatch escalation literal

sprint γ impl 着手時に main agent 経路で `git worktree` 再作成必要 (= base anchor `36330a6` 直系から spawn)。 既存 4 sub-agent worktree (= agent 1/2/4/5) は read-only investigation のみで影響なし、 γ patch 投入時のみ問題化。

= memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` 9 件 guard 中 #2/#3 trigger 該当、 plan v2 で preflight rule 強化候補。

### α-4: agent 4 finding = repair framework (= sha256 + allowed-touch + sub-sprint chain + rollback、 confidence 中-高)

#### 軸 1 = sha256 維持方針

- ADR-0069 guarded change precedent (= `.if PMDNEO_USE_PMDDOTNET == 1 / .else / .endif`) は **issue 1/2B 両件で適用可能性高**
- 修理 routine = `pmdneo_part_main_parse` + `pmdneo_psg_keyon` 両方とも PMDDOTNET=1 経路でのみ実行されるため、 production default (= PMDDOTNET=0) は **byte-identical 維持の見込み**
- 検証: γ build で 4 build matrix sha256 confirm
- guarded change 不可能と判明時 = user 明示 GO + 新 baseline 設定 (= agent 4 軸 1 option (A) へ pivot、 main agent 自走では実施しない)

#### 軸 2 = allowed-touch 範囲

- 主 touch: `src/driver/standalone_test.s` line 3725-3733 + line 2407 周辺 (= 修理対象 2 routine)
- optional touch (= 必要に応じて、 修理 routine 内のみ): なし
- 不可触: vendor / 既存 fixture MML / 既存 build flag / 既存 verify script / ADR-0041〜0070 / 既存 routine body 全
- 詳細 = 決定 4 § allowed-touch literal

#### 軸 3 = regression verify approach

- 既存 18+ verify script (= ADR-0049〜0070) 全 PASS 維持 mandate
- 特に ADR-0069 production sha256 gate-1/8 = byte-identical 維持 confirm
- 新規 verify script proposal:
  - `src/test-fixtures/adr-0071/verify-dispatch-correctness.sh` (= issue 1 修理検証 = fm-active-ladder.mml render → B/C/E/F 全 keyon ≥ 1 + per-part keyon count)
  - `src/test-fixtures/adr-0071/verify-ssg-mixer-enabled.sh` (= issue 2B 修理検証 = ssg-active-ladder.mml render → G/H/I 全 audible + reg 0x07 active bit literal)
  - `src/test-fixtures/adr-0071/verify-engineering-gate.sh` (= 統合 = FM + SSG ladder render → `scripts/analyze-audition-wav.py` Layer 1 ALL PASS + 末尾 PMDNEO_NO_FADE=1 で artifact 除外)

#### 軸 4 = sub-sprint chain proposal

α/β/γ/δ/ε 5 段 plan (= ADR-0067/0068/0069 precedent)、 詳細 = 決定 2 § sub-sprint chain

#### 軸 5 = rollback strategy

ADR-0069 §決定 5 11 unique condition 継承 + ADR-0071 固有 2 件 (= #12 既存 verify regression + #13 engineering gate FAIL on ladder)、 詳細 = 決定 6 § rollback condition

#### 重要 finding = worktree base ref mismatch

agent 1/2/4 で **worktree HEAD = `3ad1e23` (= `wip-voice-verification-db` 系統、 期待 base `36330a6` 直系ではない)** 検出。 ただし read-only mandate + `git show 36330a6:<path>` 経由で expected base ground truth 直接 read = investigation 妥当性影響なし。

**γ impl 着手時に main agent 経路で `git worktree` 再作成必要** (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当)。 次回 sub-agent 起動時 preflight rule 強化候補 (= memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` 9 件 + agent 4 提案の preflight 追加)。

## Annex β-1: repair plan v1 (= sprint β scope = Codex Rescue plan review 対象)

### β-1-1: repair scope literal (= 決定 1 整合)

scope IN (= ADR-0071 で修理):
- (1) `pmdneo_part_main_parse` rest 0x0F handler 追加
- (2) `pmdneo_psg_keyon` SSG mixer enable bit clear 追加

scope OUT (= 別軸):
- `scripts/analyze-audio.py` FFT artifact 改善
- `PMDNEO_NO_FADE=1` harness flag doc append
- voice opcode / `@N` 対応
- K bitmap pair distinct (= ADR-0070)
- tail artifact は driver 修理 scope に混ぜない (= user 明示 mandate)

### β-1-2: repair patch v1 = `pmdneo_part_main_parse` rest 0x0F handler

#### 仮説 (= Codex review 重点 axis 1)

PMDDotNET rest opcode `0x0F` (= low-nibble) が driver parser に handler 不在 → note path 誤分岐 → garbage keyon + fnum=0 → silent。

#### patch design (= guarded change `.if PMDNEO_USE_PMDDOTNET == 1` 配下)

```asm
; src/driver/standalone_test.s line 3725-3733 周辺
pmdneo_part_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, pmdneo_part_main_loop      ; end
        cp      #0x90
        jp      z, pmdneo_part_main_rest      ; compile.py 形式 rest (= 既存維持)
.if PMDNEO_USE_PMDDOTNET == 1
        ;; PMDDotNET 形式 rest = low-nibble 0xF (= compile.py 形式と衝突しない note byte range 0x00-0x8F の subset)
        jp      nc, pmdneo_part_main_command  ; >= 0x91 = commandsp 経路へ
        push    af
        and     #0x0F
        cp      #0x0F
        jr      z, pmdneo_part_main_parse_rest_dotnet
        pop     af
        jp      pmdneo_part_main_note
pmdneo_part_main_parse_rest_dotnet:
        pop     af
        jp      pmdneo_part_main_rest         ; 既存 length 解釈 logic reuse
pmdneo_part_main_command:
        call    commandsp
        jp      pmdneo_part_main_parse
.else
        ;; production default (= compile.py 形式のみ、 既存挙動維持)
        jp      c, pmdneo_part_main_note
        call    commandsp
        jp      pmdneo_part_main_parse
.endif
```

#### sha256 影響 estimate (= Codex review 重点 axis 3)

- production build (= PMDNEO_USE_PMDDOTNET=0) = `.else` branch のみ assemble = **既存 code byte-identical** = sha256 維持
- PMDDOTNET build (= PMDNEO_USE_PMDDOTNET=1) = 新 code path embedded、 新 sha256 (= 別 baseline)
- 検証 mandatory = γ で 4 build matrix sha256 確認

### β-1-3: repair patch v2 = `pmdneo_psg_keyon` SSG mixer enable bit clear

#### 仮説 (= Codex review 重点 axis 2)

`nmi_cmd_5_init_mml_song` で SSG mixer reg 0x07 = 0x3F (= all disable)、 `pmdneo_psg_keyon` で reg 0x07 を touch しない = G/H/I 永遠 silent。

#### patch design (= guarded change `.if PMDNEO_USE_PMDDOTNET == 1` 配下)

```asm
; src/driver/standalone_test.s line 2407 周辺
pmdneo_psg_keyon:
        ;; A = ch_idx (= 0/1/2 for ch1/2/3)
.if PMDNEO_USE_PMDDOTNET == 1
        ;; SSG mixer enable bit clear (= ch_idx 対応 tone enable bit、 inverted: 0 = enable)
        push    af
        push    bc
        ld      b, a                    ; B = ch_idx
        ;; read current reg 0x07 value (= driver shadow register or chip read-back)
        call    pmdneo_ssg_mixer_read_shadow  ; A = current 0x07 value (= shadow var、 new routine)
        ;; clear bit (1 << ch_idx) for tone enable
        ld      c, #1
        ld      a, b
        or      a
        jr      z, pmdneo_psg_keyon_bit_set
pmdneo_psg_keyon_bit_loop:
        sla     c
        dec     a
        jr      nz, pmdneo_psg_keyon_bit_loop
pmdneo_psg_keyon_bit_set:
        ;; C = 1 << ch_idx
        ld      a, c
        cpl                              ; A = ~(1 << ch_idx)
        ld      b, a
        call    pmdneo_ssg_mixer_read_shadow ; A = current
        and     b                        ; A = current & ~(1 << ch_idx)
        ld      b, a
        ld      c, #0x07
        call    ssg_write                ; reg 0x07 = new mixer value
        call    pmdneo_ssg_mixer_write_shadow ; update shadow
        pop     bc
        pop     af
.endif
        ;; 既存 keyon logic 継続
        ; ... (= 既存 keyon path 不変)
```

note: `pmdneo_ssg_mixer_read_shadow` / `_write_shadow` = 新規 routine (= mixer reg 0x07 の current value を driver memory に shadow 保持、 chip register direct read 不可のため)。 これらは PMDDOTNET=1 配下のみ assemble + 既存 driver state 領域 (= ADR-0048 0xFD32-0xFD38 不可触) と衝突しない新規 memory location (= 例: 0xFD40 等、 .lst overflow check で確認)。

#### sha256 影響 estimate

- production build = `.else` branch なし = **既存 code byte-identical** = sha256 維持
- PMDDOTNET build = 新 routine embedded、 新 sha256
- 検証 mandatory = γ で 4 build matrix sha256 確認

### β-1-4: γ implementation order + verification

1. Patch (1) `pmdneo_part_main_parse` rest 0x0F handler 実装 + sdasz80 build + .lst predicate 確認 (= section overflow なし、 routine size 増加 < 100 byte target)
2. Patch (2) `pmdneo_psg_keyon` SSG mixer enable bit clear 実装 + sdasz80 build + .lst predicate 確認
3. 4 build matrix sha256 verify:
   - (A) production ym2610 → `b15883fe...` byte-identical
   - (A2) production ym2610b → 既存 sha256 維持
   - (C-1) PMDDOTNET ym2610 → 新 sha256 (= literal record)
   - (C-2) PMDDOTNET ym2610b → 新 sha256 (= literal record)
4. δ functional verify (= 決定 5 § gate δ-1〜δ-6)

### β-1-5: δ verify plan (= Codex review 重点 axis 5 = verify plan が実音成立を確認できるか)

#### gate δ-1 = FM ladder dispatch correctness

```bash
PMDNEO_NO_FADE=1 PMDNEO_USE_PMDDOTNET=1 \
    PMDDOTNET_MML="$(pwd)/src/tools/pmd-mml/fm-active-ladder.mml" \
    bash scripts/build-poc.sh
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 12
# 期待 = bar 0 (B) + bar 1 (C) + bar 2 (E) + bar 3 (F) 全 audible
python3 -c "
import wave, numpy as np
with wave.open('/tmp/pmdneo-trace/audio.wav','rb') as wf:
    sr=wf.getframerate(); raw=wf.readframes(wf.getnframes())
s=np.frombuffer(raw,dtype=np.int16).astype(float).reshape(-1,2).mean(axis=1)/32768
for i, name in enumerate(['B(C4)','C(D4)','E(E4)','F(F4)']):
    w=s[int(i*2.4*sr):int((i+1)*2.4*sr)]
    rms_db=20*np.log10(np.sqrt(np.mean(w**2))) if np.sqrt(np.mean(w**2))>0 else -999
    assert rms_db > -50, f'{name} silent at {rms_db:.1f} dBFS'
    print(f'{name}: {rms_db:.1f} dBFS PASS')
"
```

#### gate δ-2 = SSG ladder mixer enabled

```bash
PMDNEO_NO_FADE=1 PMDNEO_USE_PMDDOTNET=1 \
    PMDDOTNET_MML="$(pwd)/src/tools/pmd-mml/ssg-active-ladder.mml" \
    bash scripts/build-poc.sh
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 12
# 期待 = bar 0 (G) + bar 1 (H) + bar 2 (I) 全 audible + reg 0x07 active bit
# similar python verify + ymfm trace で reg 0x07 write 確認
```

#### gate δ-3 = candidate 2 v3 staircase 8 part

```bash
PMDNEO_NO_FADE=1 PMDNEO_USE_PMDDOTNET=1 \
    PMDDOTNET_MML=/tmp/pmdneo-audition/candidate-2-v3-staircase.MML \
    bash scripts/build-poc.sh
bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 18
# 期待 = bar 0-7 全 part audible
```

#### gate δ-4 = 既存 18+ verify script regression

```bash
bash src/test-fixtures/axis-b/verify-axis-b-v2-aj-candidate-distinctness-multi-chip.sh
# 期待 = 全 16 gate PASS 維持 (= 特に gate-1/8 production sha256 byte-identical)
bash src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-{alpha,beta,gamma}.sh
# 期待 = 全 PASS 維持
# 他 ADR-0048〜0070 verify script 全 PASS 維持
```

#### gate δ-5 = engineering gate executor on ladder

```bash
python3 scripts/analyze-audition-wav.py \
    --wav /tmp/pmdneo-trace/audio.wav \
    --trace /tmp/pmdneo-audition/empty-trace.txt \
    --expected <expected JSON> \
    --output-json analysis.json --output-report report.md
# 期待 = verdict pass + Layer 1 PASS (= silence + clipping + duration、 ただし LOW_FREQ_DOMINANCE は別軸)
```

### β-1-6: rollback condition (= 決定 6 整合)

- ADR-0069 §決定 5 11 condition + ADR-0071 固有 #12/#13 (= 決定 6 literal)
- destructive git 禁止 (= `git revert` のみ)
- guarded change で production sha256 維持崩れた場合 = main agent halt + user 明示 GO 確認 (= 新 baseline 設定 option (A) へ pivot)

### β-1-7: Codex Rescue plan review 重点軸 (= user 明示 mandate)

doc wording ではなく以下を Codex review 重点:

| 軸 | 内容 |
|---|---|
| **review-1 = rest handler 仮説妥当性** | agent 1 finding 「PMDDotNET emit 0x0F + length」 + driver parser missing handler 仮説が source level evidence で正しいか |
| **review-2 = SSG mixer enable 仮説妥当性** | agent 2 仮説 2 「nmi_cmd_5_init で 0x3F、 keyon path で touch なし」 仮説が source level evidence で正しいか |
| **review-3 = guarded change で production sha256 維持できるか** | `.if PMDNEO_USE_PMDDOTNET == 1` pattern で両 patch を実装した場合、 production default build (= PMDDOTNET=0) で byte-identical 維持できるか static analysis |
| **review-4 = allowed-touch が広がっていないか** | 修理 routine 周辺以外に touch が漏れていないか、 他 routine body 不変 mandate 整合 |
| **review-5 = verify plan が実音成立を確認できるか** | gate δ-1〜δ-6 で「3rd+ part silent でない」 + 「SSG G/H/I 鳴る」 + 「既存 regression 維持」 を網羅できるか |

doc wording / 表記 / 解禁 wording 等の review は **重点ではない** (= user 明示 scope narrow)。

## Annex β: sprint β-η = 後続 fill (= γ/δ/ε で順次)

### Annex β-2: plan v2 (= Codex round 1 revise 5 must-fix + agent 5 finding 反映、 sprint β round 2 Codex review 投入 target)

#### β-2-1: plan v2 scope (= 決定 1 scope shift 反映)

**真の repair scope (= 2 件)**:

- **(1) `pmdneo_part_main_parse` rest 0x0F handler 追加** (= agent 1 finding、 plan v1 から carry)
- **(2) `comt` tempo 3-byte handling 追加** (= agent 5 finding、 plan v1 SSG mixer enable patch を **置換**)

**scope OUT 変更**:

- **SSG mixer enable patch = OUT** (= agent 2 仮説 2 反証確定、 既存 ADR-0051 β `pmdneo_ssg_tone_sync` で reg 0x07 RMW owner contract 完全動作中、 重複 patch は owner contract 違反 risk)
- 他 4 件 (= analyze-audio.py FFT 改善 + PMDNEO_NO_FADE harness flag doc + voice opcode + K bitmap pair distinct) = plan v1 と同 scope OUT

#### β-2-2: must-fix #1 (= review-2 root cause 再調査) 反映

agent 5 focused 再投資 (= `abb6ecbd1a9c97112`) で **真の SSG silent root cause = PMDDotNET 3-byte tempo encoding mismatch** 確定 (= Annex α-5 literal)。 SSG silent + FM pitch 異常 + G rest 不在 silent の **全観測が tempo encoding 不整合 1 件で説明可能**。

agent 2 仮説 2 反証は worktree base ref mismatch (= outdated source、 ADR-0051 β 未実装版) 由来 = sub-agent 起動 preflight rule 強化候補。

#### β-2-3: must-fix #2 (= SSG patch containment 修正) 反映

SSG mixer enable patch (= plan v1 β-1-3) は **完全削除**。 既存 ADR-0051 β 設計:
- `pmdneo_psg_keyon` (= line 4590-4621) → `pmdneo_ssg_tone_sync` (= line 2318-2348) call
- `pmdneo_ssg_tone_sync` = reg 0x07 RMW 唯一 owner
- shadow = `pmdneo_v2_ssg_mixer @ 0xFD3A`

= 新規 routine + 新規 memory + 直接 reg 0x07 write は **全不要**。 ADR-0051 owner contract 維持。

#### β-2-4: must-fix #3 (= guarded syntax binary toggle) 反映

`.if PMDNEO_USE_PMDDOTNET == 1 ... .endif` → `.if PMDNEO_USE_PMDDOTNET ... .endif` (= **binary toggle**、 memory `feedback_sdas_if_no_value_comparison.md` literal 整合)。 sdasz80 は `.if X == N` 値比較非対応 = `.if X` 相当評価。

#### β-2-5: must-fix #4 (= allowed-touch literal 一致) 反映

plan v2 修理対象:

| file | range | 修理対象 |
|---|---|---|
| `src/driver/standalone_test.s` | line 3725-3733 周辺 (= `pmdneo_part_main_parse`) + 新規 helper routine `pmdneo_part_main_parse_rest_dotnet` (= 0x0610 セクション末尾 or 別 free region) | (1) rest 0x0F handler |
| `src/driver/standalone_test.s` | line 3911-3914 (= `comt`) + 新規 helper routine `pmdneo_comt_pmddotnet` (= 0x0610 セクション末尾) | (2) tempo 3-byte handling |
| `docs/adr/0071-pmdneo-driver-pmddotnet-integration-repair.md` | 全 sprint section fill | doc |
| `src/test-fixtures/adr-0071/` | 新規 verify script 3 件 | δ verify |
| `docs/parallel-axes-dashboard.md` | 0071 行 + escalation entry | dashboard |

= **`pmdneo_psg_keyon` touch 削除** (= plan v1 で含めていた)、 `comt` 周辺へ shift。 routine 数 = 2 (= 同)、 allowed-touch range は plan v1 と同程度 = **拡張ではない、 routine 入れ替え**。

#### β-2-6: must-fix #5 (= verify plan δ-5 実効化) 反映

plan v1 δ-5 = empty trace + 未定義 expected JSON で Layer 2/3 skip = ALL PASS にならず実 gate に到達せず → 実 gate 化:

| gate | revised verify approach |
|---|---|
| δ-1 (= FM ladder dispatch) | fm-active-ladder render + per-bar RMS + **MAME register trace で B/C/E/F keyon (= reg 0x28 = 0xF1/0xF2/0xF5/0xF6) literal record + reg 0xA1/0xA2/0xA5/0xA6 FNUM 期待値 (= C4 = 0x26A、 D4 = 0x28F、 E4 = 0x2AA、 F4 = 0x2D1) ±許容 0** |
| δ-2 (= SSG ladder mixer enabled) | ssg-active-ladder render + per-bar RMS + **trace で reg 0x07 期待値 (= G 鳴る時 0x3E、 H 鳴る時 0x3D、 I 鳴る時 0x3B) literal record + reg 0x00/0x02/0x04 tone period 期待値 (= C4 → 0x0EE、 D4 → 0x0D5、 E4 → 0x0BE)** |
| δ-3 (= candidate 2 v3 8 part) | per-part keyon literal record + 8 part 全 dispatch confirm |
| δ-4 (= 既存 regression) | ADR-0049〜0070 全 verify script PASS 維持 (= 特に ADR-0069 production sha256 gate-1/8) |
| δ-5 (= engineering gate 4 層) | **expected event JSON 固定 (= per-part keyon timing + chip target + register addr + value) + trace file 実 capture (= MAME ymfm-trace 経由) + baseline wav 指定** → Layer 2 (= trace event match + energy correspondence) + Layer 3 (= baseline comparison) で SKIP 不発 ALL PASS 到達 |
| δ-6 (= tail artifact 分離) | `PMDNEO_NO_FADE=1` 渡した render で verify (= scope OUT 維持) |
| **δ-7 (= 新規)** | **tempo encoding 解釈 verify** = `driver_tempo_d` shadow 値が修理後 expected (= `(BPM*13)>>6` = t100 → 0x14) と一致 confirm + tempo 0xFF garbage state 不発確認 |

#### β-2-7: repair patch v2 design (= guarded change binary toggle)

##### patch (1) = `pmdneo_part_main_parse` rest 0x0F handler

```asm
; src/driver/standalone_test.s line 3725-3733 周辺
pmdneo_part_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, pmdneo_part_main_loop      ; end
        cp      #0x90
        jp      z, pmdneo_part_main_rest      ; compile.py 形式 rest (= 既存維持)
.if PMDNEO_USE_PMDDOTNET
        jp      nc, pmdneo_part_main_command  ; >= 0x91 = commandsp 経路
        push    af
        and     #0x0F
        cp      #0x0F
        jr      z, pmdneo_part_main_parse_rest_dotnet
        pop     af
        jp      pmdneo_part_main_note
pmdneo_part_main_parse_rest_dotnet:
        pop     af
        jp      pmdneo_part_main_rest         ; 既存 length 解釈 logic reuse
pmdneo_part_main_command:
        call    commandsp
        jp      pmdneo_part_main_parse
.else
        jp      c, pmdneo_part_main_note      ; production default (= 既存挙動維持)
        call    commandsp
        jp      pmdneo_part_main_parse
.endif
```

##### patch (2) = `comt` tempo 3-byte handling (= Approach C 推奨 = helper routine 追加 pattern)

```asm
; src/driver/standalone_test.s line 3911-3914 (= 既存 comt)
comt:
.if PMDNEO_USE_PMDDOTNET
        call    pmdneo_comt_pmddotnet         ; 新規 helper、 0x0610 セクション末尾配置
.else
        call    pmdneo_part_fetch_byte        ; legacy: 1 byte tempo (= 既存挙動維持)
        ld      (driver_tempo_d), a
.endif
        ret

; 新規 helper routine (= 0x0610 セクション末尾配置、 ADR-0051 pmdneo_ssg_tone_sync pattern 踏襲)
pmdneo_comt_pmddotnet:
        ;; PMDDotNET 新 tempo encoding: 0xFC 0xFF <BPM raw>
        ;; comt 入口で 0xFC 既 fetch、 残 2 byte (= 0xFF marker + raw BPM) を処理
        call    pmdneo_part_fetch_byte        ; A = 0xFF (= magic marker、 discard)
        call    pmdneo_part_fetch_byte        ; A = raw BPM (= 例 0x64 = MML t100)
        ;; PMD V4.8s driver_tempo_d encoding = (BPM*13)>>6
        ;; raw BPM → driver_tempo_d 変換: A *= 13、 >> 6 (= shift right 6)
        ld      l, a
        ld      h, #0
        ld      d, h
        ld      e, l                          ; DE = BPM
        add     hl, hl                        ; HL = BPM * 2
        add     hl, hl                        ; HL = BPM * 4
        add     hl, hl                        ; HL = BPM * 8
        add     hl, de                        ; HL = BPM * 9
        add     hl, de                        ; HL = BPM * 10
        add     hl, de                        ; HL = BPM * 11
        add     hl, de                        ; HL = BPM * 12
        add     hl, de                        ; HL = BPM * 13
        ;; HL >> 6 = HL / 64
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        srl     h
        rr      l
        ;; L = (BPM * 13) >> 6 (= driver_tempo_d encoding 値)
        ld      a, l
        ld      (driver_tempo_d), a
        ret
```

note: shift right 6 回は `(BPM*13) <= 100*13 = 1300 < 8192 = 2^13` のため 16-bit 範囲内 + L only sufficient (= H は 0 想定)。 .lst で確認 (= overflow check)。

##### sha256 影響 (= review-3 重点)

両 patch とも:
- production default build (= `.if PMDNEO_USE_PMDDOTNET` の `.else` branch only) → **byte-identical 維持 target**
- PMDDOTNET build (= `.if` branch active + 新規 helper routine embedded) → 新 sha256 (= literal record 必要)
- 既存 `comt` body (= 1-byte fetch + ld + ret) は `.else` 配下に保持 = byte-identical literal carry
- 既存 `pmdneo_part_main_parse` (= cp 0x80/0x90 + jp c) は `.else` 配下に保持 = byte-identical literal carry

= ADR-0069 §決定 4 guarded change pattern 完全踏襲。

#### β-2-8: γ implementation order (= plan v1 から update)

1. **worktree 再作成** (= main agent 経路、 base anchor `36330a6` 直系から spawn、 worktree base ref mismatch escalation 反映)
2. patch (1) `pmdneo_part_main_parse` rest 0x0F handler 実装
3. patch (2) `comt` tempo 3-byte handling 実装 + helper routine 配置
4. sdasz80 build + .lst predicate (= section overflow + routine size 確認、 helper routine size < 50 byte target)
5. 4 build matrix sha256 verify:
   - (A) production ym2610 → `b15883fe...` byte-identical
   - (A2) production ym2610b → 既存 sha256 維持
   - (C-1) PMDDOTNET ym2610 → 新 sha256 literal record
   - (C-2) PMDDOTNET ym2610b → 新 sha256 literal record
6. δ functional verify (= β-2-6 各 gate)

#### β-2-9: Codex Rescue plan review round 2 重点軸 (= user 明示 5 軸 carry + agent 5 finding 反映)

| 軸 | round 2 期待 |
|---|---|
| review-1 (= rest handler 仮説妥当性) | round 1 PASS carry (= agent 1 finding 確定済) |
| review-2 (= 真の SSG silent root cause = tempo 3-byte encoding 仮説妥当性) | **新軸** = agent 5 finding (= compiler `mc.cs:7474-7479` + driver `comt` line 3911-3914 + binary `fc ff 64` literal evidence) が source level で正しいか + tempo formula `(BPM*13)>>6` 換算 logic が正しいか |
| review-3 (= guarded change binary toggle で production sha256 維持可否) | `.if PMDNEO_USE_PMDDOTNET` (= binary toggle) で両 patch 実装、 production default で byte-identical 維持確認 + helper routine 配置 section が production carry-safe か |
| review-4 (= allowed-touch limited) | `pmdneo_part_main_parse` + `comt` + 2 helper routine 周辺のみ touch、 他 routine body 完全不変、 SSG mixer 関連 touch 削除 (= ADR-0051 owner contract 維持) |
| review-5 (= verify plan 実効化) | δ-1〜δ-7 で real trace + 固定 expected register values (= reg 0xA1/0xA5 FNUM + 0x07 SSG mixer + 0x00/0x02/0x04 SSG period + driver_tempo_d shadow) で実音成立を **register level verify** |

doc wording / 表記 review = 重点ではない (= user 明示 mandate)。

### Annex β-3: plan v3 (= Codex round 2 revise 4 must-fix 反映 + sprint β round 3 Codex review 投入 target)

sprint β round 2 plan v2 Codex Rescue plan review (= agentId `af51f5e688ebc5242`、 elapsed 4m23s) judgment = **revise** + 4 must-fix + 3 nice-to-have + 3 latent-risk。 per-axis verdict = AXIS-1 (rest handler) PASS + AXIS-2 (tempo encoding) PARTIAL (mf1) + AXIS-3 (sha256 維持) FAIL (mf2) + AXIS-4 (allowed-touch) PARTIAL (mf3 + mf4) + AXIS-5 (verify plan) PASS。

#### β-3-1: plan v3 scope (= 不変 carry + must-fix 4 件反映 overview)

- repair scope = 不変 (= rest 0x0F handler + comt tempo 3-byte handling、 SSG mixer enable scope OUT 維持)
- 主要 shift from plan v2:
  - (mf1) Annex α-5 観測 peak 2659 Hz claim を「ADR 記録 + 算術整合」 格下げ + Python 1 行算式 snapshot embed
  - (mf2) γ implementation order 「4 build matrix sha256」 を `scripts/build-poc.sh:188-242` 基準 4 種に詳細化
  - (mf3) patch (2) を **inline embed** (= 新規 helper routine `pmdneo_comt_pmddotnet` 廃止)、 allowed-touch を「既存 routine modify only」 に統一
  - (mf4) dashboard 0071 行 active row を plan v3 wording に統一

#### β-3-2: must-fix mf1 反映 = AXIS-2 観測 peak 2659 Hz claim 格下げ + 算術 snapshot

Codex 指摘 = 観測 peak 2659 Hz が repo 内にソース根拠なし (= ADR text self-referential)。 解消方法 = E6 2nd harmonic 算式 Python snippet を embed + claim を「ADR 記録 + 算術整合」 格下げ。

```python
# E6 = MIDI note 88, A4 = MIDI note 69 = 440 Hz
e6_fundamental = 440 * (2 ** ((88 - 69) / 12))   # 1318.51 Hz
e6_2nd_harmonic = e6_fundamental * 2              # 2637.02 Hz
# observed peak 2659 Hz vs expected 2637.02 Hz → 21.98 Hz delta (= 0.83% error)
```

- claim grade shift: 「observed peak 2659 Hz = E6 2nd harmonic 2637 Hz 一致」 → 「ADR-0065 sprint B follow-up integration verify 経路 (= `analyze-audition-wav.py` output、 audition material storage = repo 外 artifact) で記録された観測 peak 2659 Hz は **算術整合** = E6 2nd harmonic 計算値 2637 Hz と 0.83% 誤差で一致」
- reproducer = 上記 Python 1 行 (= 独立再現可能)
- latent-risk lr3 acknowledge: 観測 source artifact (= `analyze-audition-wav.py` output JSON + `vendor/ngdevkit-examples/00-template/pmddotnet_song.m`) は commit 管理外 = AXIS-2 証拠 reproducibility 一部欠落、 mitigation = Python reproducer + ADR-0065 sprint B framework が再生成可能

#### β-3-3: must-fix mf2 反映 = AXIS-3 build matrix 4 種 `scripts/build-poc.sh:188-242` 基準詳細化

Codex 指摘 = 「4 build matrix」 が chip-target (ym2610/ym2610b) 基準として誤読される設計、 実 build switch = `PMDNEO_USE_PMDDOTNET` flag + `PMDDOTNET_MML` env による独立制御。 `scripts/build-poc.sh:188-242` 基準で 4 種を再定義。

| 種別 | 環境変数組 | 期待 sha256 結果 | scope |
|---|---|---|---|
| (A1) production baseline | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` | 既存 production `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` byte-identical 維持 (= ADR-0069 §決定 4 整合) | 修理経路無関係、 既存 byte 列完全保持 |
| (A2) chip variant | `PMDNEO_CHIP=ym2610` + `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` | 既存 ym2610 sha256 byte-identical 維持 | chip target alternative、 修理経路無関係 |
| (A3) PMDDotNET import flag-off | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=0` + `PMDDOTNET_MML=<staircase.MML>` | (A1) と byte-identical (= guarded change `.if PMDNEO_USE_PMDDOTNET` block は flag=0 で assemble されない) | PMDDotNET 経路で .M import するが driver 修理は無効 = byte-identical |
| (A4) PMDDotNET import flag-on (= 修理経路 build) | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=1` + `PMDDOTNET_MML=<staircase.MML>` | (A1) と diff = patch (1) + patch (2) 合計 byte 量 (= 期待 ~50-60 byte 増分) + `.lst` で diff 確認 | 修理経路 build、 δ functional verify 対象 |

- (A1)(A2)(A3) で `b15883fe...` 維持 = production sha256 invariant 守られる証拠
- (A4) のみ diff = guarded change が正しく `.if PMDNEO_USE_PMDDOTNET` block を assemble している証拠
- diff byte 量予測 = patch (1) ~15-20 byte (= `push af / and 0x0F / cp 0x0F / jr z / pop af / jp` block) + patch (2) ~35-40 byte (= comt inline embed = `(BPM*13)>>6` 換算 logic = `add hl`×5 + `srl h / rr l`×6 + load/store)
- 検証 command 例:
  ```sh
  # (A1)
  PMDNEO_CHIP=ym2610b PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
  sha256sum vendor/ngdevkit-examples/00-template/poc.neo
  # (A2)
  PMDNEO_CHIP=ym2610 PMDNEO_USE_PMDDOTNET=0 scripts/build-poc.sh
  sha256sum vendor/ngdevkit-examples/00-template/poc.neo
  # (A3)
  PMDNEO_CHIP=ym2610b PMDNEO_USE_PMDDOTNET=0 PMDDOTNET_MML=src/tools/pmd-mml/ssg-active-ladder.mml scripts/build-poc.sh
  sha256sum vendor/ngdevkit-examples/00-template/poc.neo
  # (A4)
  PMDNEO_CHIP=ym2610b PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/tools/pmd-mml/ssg-active-ladder.mml scripts/build-poc.sh
  sha256sum vendor/ngdevkit-examples/00-template/poc.neo
  ```

#### β-3-4: must-fix mf3 反映 = patch (2) inline embed + 新規 helper routine 廃止

Codex 指摘 = plan v2 patch (2) は新規 helper routine `pmdneo_comt_pmddotnet` (= 0x0610 セクション末尾) を提案、 patch (1) は inline label のみ (= 既存 routine modify only) = 不整合。 allowed-touch を「既存 routine modify only」 に統一するため、 patch (2) も inline embed に変更。

##### patch (2) v3 design (= inline embed、 helper routine 廃止)

```asm
; src/driver/standalone_test.s 既存 comt routine (line 3911-3914 周辺):
; comt:
;         call    pmdneo_part_fetch_byte
;         ld      (driver_tempo_d), a
;         ret

; patch (2) v3: comt routine 内に PMDDOTNET 3-byte tempo handling を inline embed
comt:
.if PMDNEO_USE_PMDDOTNET
        ; PMDDotNET 3-byte tempo encoding: 0xFC 0xFF <BPM raw>
        ; 上位 byte 0xFF = format marker (= discard)、 次 byte = raw BPM
        ; driver は (BPM*13)>>6 換算で driver_tempo_d に格納
        call    pmdneo_part_fetch_byte     ; A = 0xFF marker, discard
        call    pmdneo_part_fetch_byte     ; A = raw BPM
        ld      l, a                       ; HL = BPM
        ld      h, #0
        ld      d, h                       ; DE = BPM
        ld      e, l
        add     hl, hl                     ; HL = BPM * 2
        add     hl, hl                     ; HL = BPM * 4
        add     hl, hl                     ; HL = BPM * 8
        add     hl, de                     ; HL = BPM * 9
        add     hl, de                     ; HL = BPM * 10
        add     hl, de                     ; HL = BPM * 11
        add     hl, de                     ; HL = BPM * 12
        add     hl, de                     ; HL = BPM * 13
        srl     h                          ; HL >>= 1
        rr      l
        srl     h                          ; HL >>= 2
        rr      l
        srl     h                          ; HL >>= 3
        rr      l
        srl     h                          ; HL >>= 4
        rr      l
        srl     h                          ; HL >>= 5
        rr      l
        srl     h                          ; HL >>= 6
        rr      l
        ld      a, l                       ; A = (BPM*13)>>6
        ld      (driver_tempo_d), a
.else
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d), a
.endif
        ret
```

- 新規 routine label なし (= `pmdneo_comt_pmddotnet` 削除)
- 既存 `comt` routine 内部のみ modify
- 0x0610 セクション末尾配置 question moot (= nh3 = N/A、 inline embed で配置位置論点消滅)
- patch byte estimate = ~35-40 byte (= guarded block within comt)
- ADR-0051 owner contract = `pmdneo_ssg_tone_sync` (= reg 0x07 RMW) 影響なし
- allowed-touch literal update = `src/driver/standalone_test.s` のみ + (a) line 3725-3733 周辺 `pmdneo_part_main_parse` 既存 routine modify (= rest 0x0F handler inline label) + (b) line 3911-3914 周辺 `comt` 既存 routine modify (= tempo 3-byte handling inline embed) + 新規 routine 追加なし

#### β-3-5: must-fix mf4 反映 + nice-to-have 3 件反映

##### mf4 = dashboard 0071 行 active row plan v3 wording 統一 (= 本 plan v3 commit chain で同時実施)

dashboard `docs/parallel-axes-dashboard.md:66` の active row を以下に update (= 本 commit で同時実施):
- 「sprint β round 1 plan review revise + agent 5 真の root cause finding + plan v2 起草」 → 「sprint β round 2 plan review revise (= 4 must-fix) + plan v3 起草 (= patch (2) inline embed + 4 build matrix 詳細化 + 観測 peak claim 格下げ + Python reproducer embed)」
- escalation 履歴 0071 entry plan review chain column update = round 1 revise → round 1 revise + agent 5 + plan v2 → round 2 revise + plan v3 + round 3 投入予定

##### nh1 反映 = δ-7 算術 example `t120 → (120*13)>>6 = 0x18` 明示

既存 β-2-6 「δ-7」 gate description = `t100 → driver_tempo_d = 0x14` のみ。 plan v3 で追加:
- t100 → (100*13)>>6 = 1300>>6 = 20 = **0x14**
- t120 → (120*13)>>6 = 1560>>6 = 24 = **0x18**
- t60 → (60*13)>>6 = 780>>6 = 12 = **0x0C**

##### nh2 反映 = `driver_tempo_d` z80-mem probe アドレス 0xF817 明示

既存 `standalone_test.s:8` literal で `driver_tempo_d = 0xF817` (= driver tempo shadow byte)。 plan v3 で δ-7 gate description に明示:
- gate δ-7 = MAME z80-mem probe アドレス `0xF817` で expected `driver_tempo_d` value 一致

##### nh3 acknowledge = N/A (= patch (2) inline embed で配置位置論点消滅)

Codex nh3 = 「0x0610 セクション末尾配置位置を song_data.inc include 行手前明記」 → patch (2) inline embed で `pmdneo_comt_pmddotnet` helper routine 廃止のため、 配置位置 question 自体が moot。 plan v3 で明示的 acknowledge。

#### β-3-6: latent-risk 3 件 acknowledge

##### lr1 = patch (2) inline embed 後の comt 内 PMDDOTNET block が 0xFF marker 検証なく読み捨てる desync risk

mitigation:
- sprint γ test fixture (= `ssg-active-ladder.mml` 等) は PMDDotNET compiler 正規出力なので 0xFF marker は必ず先頭 (= malformed tempo は出ない)
- production-ready は ADR-0066 (= 本番 cmd 切替) 候補 future、 ADR-0071 sprint γ では skip
- 将来 strict mode 候補 (= 0xFF marker 検証 + mismatch 時 fallback) は別 ADR scope

##### lr2 = 既存 source 内 `.if PMDNEO_USE_PMDDOTNET == 1` pattern 残存 (= 既存 ADR-0069 patch 由来) = 将来読者混乱

mitigation:
- ADR-0071 sprint γ 修正範囲では `.if PMDNEO_USE_PMDDOTNET` (binary toggle) 統一
- 既存 source の `== 1` pattern cleanup は別 sprint scope (= 越境せず)
- memory `feedback_sdas_if_no_value_comparison.md` に historical note carry

##### lr3 = `vendor/ngdevkit-examples/00-template/pmddotnet_song.m` commit 管理外 = AXIS-2 証拠の一部再現性なし

mitigation:
- β-3-2 で Python 1 行 reproducer embed (= 独立再現可能)
- `pmddotnet_song.m` 再生成 = `PMDDOTNET_MML=src/tools/pmd-mml/ssg-active-ladder.mml scripts/build-poc.sh` (= ADR-0016 step 3b 経路)
- audition material storage の repo 外 artifact 規律は ADR-0065 §決定 13 (= sprint B follow-up integration verify framework) 整合

#### β-3-7: γ implementation order (= plan v2 から update = 4 build matrix 詳細化 + worktree 再作成 mandate carry)

1. **main agent 経路で `git worktree` 再作成** (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当、 agent 2 仮説 2 反証経路の正規化)
2. `comt` routine inline embed patch + `pmdneo_part_main_parse` rest 0x0F handler patch (= 2 patch 同時 apply)
3. sdasz80 build (= `make standalone_test.rel`)
4. `.lst` predicate 4 件確認:
   - patch (1) `pmdneo_part_main_parse_rest_dotnet` inline label assemble 確認
   - patch (2) comt 内 `.if PMDNEO_USE_PMDDOTNET` block 内 instructions assemble 確認
   - 既存 routine body 完全不変 (= patch 外の byte 列 byte-identical)
   - 既存 symbol table 不変 (= 新規 symbol 増加なし、 既存 symbol 完全保持)
5. 4 build matrix sha256 verify (= β-3-3 表 (A1)(A2)(A3)(A4))
6. δ functional verify (= β-2-6 各 gate + δ-7 tempo encoding verify nh1/nh2 反映)

#### β-3-8: Codex Rescue plan review round 3 重点軸 (= round 2 must-fix 4 件反映 + 不変 carry)

1. mf1 反映確認 = AXIS-2 観測 peak claim 格下げ + Python 算式 snapshot embed (= β-3-2)
2. mf2 反映確認 = AXIS-3 build matrix 4 種 `scripts/build-poc.sh:188-242` 基準詳細化 (= β-3-3)
3. mf3 反映確認 = AXIS-4 patch (2) inline embed + 新規 helper routine 廃止 (= β-3-4)
4. mf4 反映確認 = AXIS-4 dashboard active row plan v3 wording 統一 (= β-3-5 mf4)
5. unchanged carry = AXIS-1 (rest handler) PASS + AXIS-5 (verify plan) PASS confirm

#### β-3-9: plan v4 = Codex round 3 revise 3 must-fix 反映 (= round 3 revise corrections)

sprint β round 3 plan v3 Codex Rescue plan review (= agentId `afcf2868b5ce094ff`、 elapsed 7m) judgment = **revise** + 3 must-fix + 2 nice-to-have + 1 latent-risk。 per-axis verdict = mf1 PASS + mf2 FAIL + mf3 PASS + mf4 PARTIAL + AXIS-1/AXIS-5 PASS。

##### β-3-9-1: mf-r3-1 反映 = AXIS-3 build matrix 4 種定義誤り訂正 (= **β-3-3 supersede**)

Codex 指摘 = plan v3 β-3-3 の matrix 4 種定義誤り、 理由 2 件:
1. `PMDDOTNET_MML` を渡すと `scripts/build-poc.sh:188-223` が generated `song_data.inc` → `pmddotnet_song` data を ROM に追記する (= `standalone_test.s:5927` literal `song_data.inc` 無条件 include)。 (A3) を「A1 byte-identical」 と書けない (= song data payload diff)
2. `PMDNEO_USE_PMDDOTNET=1` は ADR-0069 guarded blocks (= line 1741-1804 + 5810-5821 周辺) も assemble する。 (A4) vs (A1) diff = patch (1) + (2) 合計 ~50-60 byte と書けない (= ADR-0069 guarded code 差分も含む)

**plan v4 build matrix 再定義** (= 同一 fixture / 同一 flag-on で pre-patch vs post-patch 比較に変更):

| 種別 | 環境変数組 + source state | 期待結果 | scope |
|---|---|---|---|
| (B1) production baseline | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` + base anchor source (= sprint γ patch 未適用) | 既存 production `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` byte-identical 維持 | **production sha256 invariant 主証** = 修理経路無関係で既存 byte 列完全保持 |
| (B2) production baseline post-patch | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=0` + no `PMDDOTNET_MML` + post-patch source (= sprint γ patch 適用後) | (B1) と byte-identical (= guarded change `.if PMDNEO_USE_PMDDOTNET` block が flag=0 で assemble されない証拠) | **production sha256 invariant post-patch 維持確認** |
| (B3) flag-on pre-patch with fixture | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=1` + `PMDDOTNET_MML=<committed fixture>` + base anchor source | (B1) と diff = ADR-0069 guarded blocks 差分 + import song data 差分のみ (= ADR-0071 patch 不在) | **pre-patch flag-on baseline** = 修理前 dispatch failure 状態 |
| (B4) flag-on post-patch with fixture | `PMDNEO_CHIP=ym2610b` + `PMDNEO_USE_PMDDOTNET=1` + `PMDDOTNET_MML=<committed fixture>` + post-patch source | (B3) と diff = ADR-0071 patch (1) + (2) byte 量のみ (= ~50-60 byte 増分予測) + song data + ADR-0069 guarded 同一 | **修理経路 build** = (B3) vs (B4) diff が patch byte 量と一致確認 + δ functional verify 対象 |

**主証ペア = (B1) ↔ (B2)** で production sha256 invariant 維持 (= flag-off で byte-identical)、 **patch 増分 = (B3) ↔ (B4)** で ADR-0071 patch byte 量分離 verify (= 同一 fixture/flag 条件で source diff のみ)。

- (B1) で `b15883fe...` byte-identical = production sha256 invariant 主証
- (B2) で post-patch flag-off byte-identical = guarded change が flag-off で完全無効化される証拠
- (B3) で pre-patch flag-on = ADR-0069 guarded + import song data 含む baseline (= 修理前状態の binary)
- (B4) で post-patch flag-on = (B3) + ADR-0071 patch byte 量のみ diff
- (B3) vs (B4) `.lst` diff predicate 確認 = ADR-0071 patch (1) inline label + patch (2) inline embed のみ insert

##### β-3-9-2: mf-r3-2 反映 = dashboard 0071 row 全列 plan v4 統一 (= 本 plan v4 commit chain で同時実施)

Codex 指摘 = dashboard `docs/parallel-axes-dashboard.md:66` の status column は plan v3 wording 反映済 (= 直近 commit `a7f1810`)、 ただし **scope column + allowed-touch column + 後続 plan review 文言** に `pmdneo_psg_keyon` / SSG mixer enable scope IN / plan v1 系 wording 残存。

本 plan v4 commit chain で同時修正範囲:
- scope IN literal = `(1) pmdneo_part_main_parse rest 0x0F handler 追加 + (2) pmdneo_psg_keyon SSG mixer enable bit clear 追加` → `(1) pmdneo_part_main_parse rest 0x0F handler 追加 (= line 3725-3733 周辺 inline label) + (2) comt routine tempo 3-byte handling inline embed 追加 (= line 3911-3914、 既存 routine modify only)`
- allowed-touch literal = `src/driver/standalone_test.s 修理 routine 周辺 + 新規 verify script 3 件 + dashboard` → `src/driver/standalone_test.s pmdneo_part_main_parse + comt 既存 routine modify only (= 新規 routine label 追加なし) + 新規 verify script + 新規 committed fixture (= src/test-fixtures/adr-0071/) + dashboard`

##### β-3-9-3: mf-r3-3 反映 = matrix fixture 再現性 = 新規 committed fixture 配置

Codex 指摘 = `src/tools/pmd-mml/ssg-active-ladder.mml` は `git status` 上 untracked (= user 別作業)、 worktree 再作成後不在の可能性 = matrix verify 再現性なし。

**plan v4 fixture procurement plan**:
- ADR-0071 γ impl 着手時、 新規 committed fixture を `src/test-fixtures/adr-0071/` directory 配下に配置 (= ADR-0069 `src/test-fixtures/axis-b-v2/aj-distinctness-fixture.mml` precedent 同 pattern)
- fixture 候補 = (a) `test-tempo-encoding.mml` (= PMDDotNET t100/t120/t60 tempo opcode 3-byte emit 確認用 = patch (2) verify) + (b) `test-rest-handler.mml` (= PMDDotNET rest 0x0F opcode emit 確認用 = patch (1) verify)
- 既存 user 別作業 `src/tools/pmd-mml/ssg-active-ladder.mml` + `fm-active-ladder.mml` は **完全 untouched 維持** (= 保持対象 3 type 不可触 confirmed)
- 新規 fixture は ADR-0069 §決定 3-d 「新規 fixture MML 例外的許可」 precedent 継承 = ADR-0071 §決定 4 allowed-touch literal に追加 (= dashboard 0071 row scope column 反映 = β-3-9-2 mf-r3-2)
- allowed-touch 拡張 = user 判断 required 該当? = no、 ADR-0069 precedent (= 既 user 承認済 pattern) + sprint γ impl scope 内 fixture 追加は新規 ADR scope 変更ではない、 user mandate「allowed-touch を広げる」 = ADR 外への拡張を想定 (= 別 sprint / 別 routine touch) と解釈

##### β-3-9-4: nice-to-have nh-r3-1/nh-r3-2 反映

- **nh-r3-1** = patch (2) byte estimate を「rough」 と明記 + 概算根拠:
  - patch (1) ~15-20 byte (rough) = `push af` (1) + `and #0x0F` (2) + `cp #0x0F` (2) + `jr z, label` (2) + `pop af` (1) + `jp label` (3) ≈ 11-15 byte (= label resolution に依存 ± 数 byte)
  - patch (2) ~35-40 byte (rough) = `call pmdneo_part_fetch_byte` ×2 (= 6 byte) + `ld l,a / ld h,#0 / ld d,h / ld e,l` (= 5 byte) + `add hl,hl` ×3 (= 3 byte) + `add hl,de` ×5 (= 5 byte) + `srl h / rr l` ×6 (= 18 byte) + `ld a,l / ld (driver_tempo_d),a` (= 4 byte) ≈ 41 byte (= 詳細実装で ± 数 byte)
  - 合計 estimate = ~50-60 byte (rough)、 actual は γ impl 完了後 `.lst` 実測で confirm

- **nh-r3-2** = matrix command 例に stale artifact clear step + `PMDDOTNET_MODE=N` 追加:
  ```sh
  # ADR-0069 gate-8 timestamp 汚染回避 + 確実な clean build:
  rm -rf vendor/ngdevkit-examples/00-template/{pmddotnet_song.m,song_data.inc.bak,*.lst}
  # PMDDOTNET_MODE=N 明示 (= default だが explicit 化で再現性向上):
  PMDDOTNET_MODE=N PMDNEO_CHIP=ym2610b PMDNEO_USE_PMDDOTNET=1 PMDDOTNET_MML=src/test-fixtures/adr-0071/test-tempo-encoding.mml scripts/build-poc.sh
  sha256sum vendor/ngdevkit-examples/00-template/poc.neo
  ```

##### β-3-9-5: latent-risk lr-r3-1 acknowledge + mitigation

- **lr-r3-1** = generated `song_data.inc` + `pmddotnet_song.m` が ignored/generated state のまま matrix に混ざると、 sha256 判定が driver patch 差分ではなく data payload 差分を検出
- mitigation:
  - β-3-9-1 plan v4 matrix で (B1)/(B2) = no `PMDDOTNET_MML` で fixture data 完全除外 → production sha256 invariant 主証は data payload 影響なし
  - (B3)/(B4) = 同一 `PMDDOTNET_MML` + 同一 fixture で data payload 同一 → diff は driver source patch byte のみ
  - command 例で `rm -rf` clear step 明示 (= nh-r3-2)
  - γ impl 完了時 `.lst` predicate 4 件確認 step (= β-3-7 step 4) で patch (1)/(2) byte assemble + 既存 routine body 不変 + 既存 symbol table 不変 を verify

#### β-3-10: γ implementation order (= plan v3 β-3-7 supersede = plan v4)

1. **main agent 経路で `git worktree` 再作成** (= ADR-0041 §決定 12 isolation worktree base ref 不一致 該当)
2. **新規 committed fixture 配置** = `src/test-fixtures/adr-0071/test-tempo-encoding.mml` + `test-rest-handler.mml` (= β-3-9-3 mf-r3-3 反映)
3. `comt` routine inline embed patch + `pmdneo_part_main_parse` rest 0x0F handler patch (= 2 patch 同時 apply)
4. sdasz80 build (= `make standalone_test.rel`)
5. `.lst` predicate 4 件確認 (= β-3-7 carry)
6. 4 build matrix sha256 verify (= **β-3-9-1 plan v4 matrix (B1)/(B2)/(B3)/(B4)**、 stale artifact clear + `PMDDOTNET_MODE=N` 明示 = β-3-9-4 nh-r3-2 反映)
7. δ functional verify (= β-2-6 + δ-7 nh1/nh2 反映)

#### β-3-11: Codex Rescue plan review round 4 重点軸 (= round 3 must-fix 3 件反映 + 不変 carry)

1. mf-r3-1 反映確認 = AXIS-3 build matrix 4 種 plan v4 再定義 (= β-3-9-1 (B1)/(B2)/(B3)/(B4) 同一 fixture/flag pre/post-patch 比較 semantics)
2. mf-r3-2 反映確認 = dashboard 0071 row 全列 plan v4 wording 統一 (= scope column + allowed-touch column + 後続 plan review 文言、 本 plan v4 commit chain で同時実施)
3. mf-r3-3 反映確認 = 新規 committed fixture `src/test-fixtures/adr-0071/` 配置計画 (= γ impl 着手時 main agent 配置、 ADR-0069 §決定 3-d precedent 継承)
4. nice-to-have nh-r3-1/nh-r3-2 反映 (= β-3-9-4 patch byte estimate rough 化 + matrix command stale clear step + PMDDOTNET_MODE=N 明示)
5. latent-risk lr-r3-1 acknowledge + mitigation (= β-3-9-5 plan v4 matrix で fixture data 除外 + payload 同一 + .lst predicate verify)
6. unchanged carry = mf1 PASS + mf3 PASS + AXIS-1 PASS + AXIS-5 PASS confirm

### Annex β-4: δ verify result (= sprint δ で fill)

placeholder。

### Annex β-5: ε Accepted milestone (= sprint ε で fill)

placeholder。

## 改訂履歴

| 日付 | session | 内容 | commit |
|---|---|---|---|
| 2026-05-27 | 43rd session | ADR-0071 sprint β round 3 Codex review revise + plan v4 起草 = sprint β round 2 + plan v3 後の round 3 plan v3 Codex review (= agentId `afcf2868b5ce094ff`、 elapsed 7m) **revise** + 3 must-fix + 2 nice-to-have + 1 latent-risk + per-axis verdict (= mf1 PASS + mf2 FAIL + mf3 PASS + mf4 PARTIAL + AXIS-1/AXIS-5 PASS)。 main agent autonomous (= user mandate「sha256 維持崩れ / allowed-touch 拡張 / 別 ADR scope 変更時のみ user 判断」 適用、 mf-r3-1〜3 全 scope 内 = sha256 invariant 主証 refine + dashboard 全列 wording 統一 + 新規 committed fixture 配置は ADR-0069 §決定 3-d precedent 継承 = allowed-touch 拡張ではなく既 ADR pattern 内、 全自律進行可能) で plan v4 起草。 ADR doc 修正範囲 = (1) Annex β-3 拡張 = β-3-9 plan v4 = Codex round 3 revise 3 must-fix 反映 5 sub-section = β-3-9-1 (mf-r3-1 build matrix 再定義 = B1/B2/B3/B4 同一 fixture/flag pre/post-patch 比較 = (B1) production baseline `b15883fe...` byte-identical 主証 + (B2) post-patch flag-off byte-identical = guarded change flag-off 完全無効化 confirm + (B3) flag-on pre-patch fixture (= ADR-0069 guarded + import song data baseline) + (B4) flag-on post-patch fixture (= (B3) と patch byte diff のみ)、 主証ペア = (B1)↔(B2) production sha256 invariant + 患部分離 = (B3)↔(B4) patch byte 量分離) + β-3-9-2 (mf-r3-2 dashboard scope/allowed-touch column plan v4 wording 統一 = scope IN literal「pmdneo_psg_keyon SSG mixer enable」 → 「comt routine tempo 3-byte handling inline embed」 + allowed-touch literal「修理 routine 周辺 + 新規 verify script 3 件」 → 「pmdneo_part_main_parse + comt 既存 routine modify only + 新規 verify script + 新規 committed fixture」) + β-3-9-3 (mf-r3-3 新規 committed fixture procurement plan = `src/test-fixtures/adr-0071/test-tempo-encoding.mml` + `test-rest-handler.mml`、 既存 user 別作業 `src/tools/pmd-mml/*-active-ladder.mml` 完全 untouched 維持、 ADR-0069 §決定 3-d「新規 fixture MML 例外的許可」 precedent 継承) + β-3-9-4 (nh-r3-1 patch byte estimate「rough」 明記 + 概算根拠 patch (1) ~15 byte + patch (2) ~41 byte = 合計 ~50-60 byte rough + actual は γ impl 完了後 .lst 実測 confirm + nh-r3-2 matrix command stale artifact clear step + PMDDOTNET_MODE=N 明示) + β-3-9-5 (lr-r3-1 generated song_data.inc/pmddotnet_song.m が matrix に混ざる sha256 判定誤検出 risk acknowledge + mitigation = plan v4 matrix で fixture data 除外 + payload 同一 + .lst predicate verify) + β-3-10 γ impl order plan v4 = 7 step (= worktree 再作成 + 新規 fixture 配置 + 2 patch + sdasz80 build + .lst predicate + 4 build matrix B1-B4 + δ functional) + β-3-11 Codex round 4 重点軸 6 件 (= mf-r3-1/2/3 反映確認 + nh-r3 反映 + lr-r3 acknowledge + AXIS-1/5/mf1/mf3 unchanged carry confirm) + (2) 改訂履歴 sprint β round 3 + plan v4 entry append (= 本 entry、 append only mandate 厳守) + (3) dashboard 0071 行 status update + scope column + allowed-touch column 全列 plan v4 wording 統一 (= mf-r3-2 反映、 本 plan v4 commit chain で同時実施) + (4) escalation 履歴 ADR-0071 entry plan review chain column update = round 1 + agent 5 + plan v2 + round 2 + plan v3 + round 3 revise + plan v4 + round 4 投入予定 placeholder。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0070 本文 + Annex / 既存 scripts / 既存 Annex α-1〜α-4 + β-1 + β-2 (= immutable history) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= sprint β round 3 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0065 sprint A AXIS-5 fix-up precedent + ADR-0071 sprint β round 1/2 fix-up precedent 同 pattern carry)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #153 base) + (2) merge atomic 11 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 4 on Annex β-3 plan v4 (= 6 重点軸 carry) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 11 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 + 新規 fixture 配置 mandate)、 sub-sprint γ/δ/ε 起票判断 = main agent autonomous default、 user 判断 = sha256 維持崩れ / allowed-touch 拡張 (= 既 ADR pattern 外への拡張) / 別 ADR scope 変更時のみ。 | (= 本 plan v4 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0071 sprint β round 2 Codex review revise + plan v3 起草 = sprint β round 1 + agent 5 + plan v2 後の sprint β round 2 plan v2 Codex review (= agentId `af51f5e688ebc5242`、 elapsed 4m23s) **revise** + 4 must-fix + 3 nice-to-have + 3 latent-risk + per-axis verdict (= AXIS-1 PASS + AXIS-2 PARTIAL mf1 + AXIS-3 FAIL mf2 + AXIS-4 PARTIAL mf3+mf4 + AXIS-5 PASS)。 main agent autonomous (= user mandate「sha256 維持崩れ / allowed-touch 拡張 / 別 ADR scope 変更時のみ user 判断」 適用、 mf1〜mf4 全 scope 内 + sha256 invariant 維持 + allowed-touch 縮小 = 全自律進行可能) で plan v3 起草。 ADR doc 修正範囲 = (1) Annex β-3 新規追加 = plan v3 (= 8 sub-section = β-3-1 scope + β-3-2 mf1 反映 = 観測 peak 2659 Hz claim 格下げ + Python 算式 snapshot embed (= E6 2nd harmonic 2637.02 Hz vs 観測 2659 Hz = 0.83% 誤差) + β-3-3 mf2 反映 = 4 build matrix 4 種 `scripts/build-poc.sh:188-242` 基準詳細化 (= (A1) production baseline + (A2) chip variant + (A3) PMDDotNET import flag-off + (A4) PMDDotNET import flag-on = 修理経路 build) + 検証 command 例 + β-3-4 mf3 反映 = patch (2) inline embed (= 新規 helper routine `pmdneo_comt_pmddotnet` 廃止、 既存 comt routine 内 `.if PMDNEO_USE_PMDDOTNET` block で `(BPM*13)>>6` 換算 logic 全 embed) + allowed-touch literal update (= 既存 routine modify only、 新規 routine 追加なし) + β-3-5 mf4 反映 + nh1/nh2/nh3 反映 (= δ-7 算術 example t100/t120/t60 明示 + driver_tempo_d 0xF817 z80-mem probe + nh3 N/A acknowledge) + β-3-6 lr1/lr2/lr3 acknowledge + mitigation 明示 + β-3-7 γ implementation order update (= 4 build matrix 詳細化 + worktree 再作成 mandate carry) + β-3-8 Codex round 3 重点軸 5 件) + (2) Annex β-3 placeholder rename → Annex β-4 (= δ verify result placeholder carry) + Annex β-4 placeholder rename → Annex β-5 (= ε Accepted milestone placeholder carry) + (3) 改訂履歴 sprint β round 2 + plan v3 entry append (= 本 entry、 append only mandate 厳守 = 既存 β round 1 + plan v2 entry の後ろに append、 chronological order 正常維持) + (4) dashboard 0071 行 status update = 「sprint β round 1 revise + agent 5 + plan v2 起草」 → 「sprint β round 2 revise (= 4 must-fix) + plan v3 起草」 + (5) escalation 履歴 ADR-0071 entry plan review chain column update = round 1 revise + agent 5 + plan v2 → round 2 revise + plan v3 + round 3 投入予定 placeholder。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0070 本文 + Annex / 既存 scripts (= analyze-audio.py / analyze-audition-wav.py / test_analyze_audition_wav.py) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= sprint β round 2 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0065 sprint A AXIS-5 fix-up precedent 同 pattern carry)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #153 base) + (2) merge atomic 11 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 3 on Annex β-3 plan v3 (= 5 重点軸 = mf1/mf2/mf3/mf4 反映確認 + AXIS-1/AXIS-5 unchanged carry) + Monitor 30s polling 死活管理 default + 機械復旧 rule literal 適用 default + 経験則 retry default + approve loop + main agent 経路 merge + atomic 1 セット 11 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 mandate)、 sub-sprint β/γ/δ/ε 起票判断 = main agent autonomous default、 user 判断 = sha256 維持崩れ / allowed-touch 拡張 / 別 ADR scope 変更時のみ。 | (= 本 plan v3 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0071 sprint β round 1 Codex review revise + agent 5 focused 再投資 + plan v2 起草 = sprint α 完走後の sprint β round 1 plan v1 Codex review (= agentId `ad2dc66cae5b63599`、 elapsed 258 秒) **revise** + 5 must-fix (= must-fix 1 = review-2 SSG mixer 仮説 root cause 再調査 / must-fix 2 = SSG patch containment 修正 (= 既存 ADR-0051 owner contract 維持) / must-fix 3 = guarded syntax `.if X == 1` → `.if X` binary toggle (= sdasz80 値比較非対応 memory `feedback_sdas_if_no_value_comparison.md` 整合) / must-fix 4 = allowed-touch 記述実修正範囲一致 / must-fix 5 = verify plan δ-5 実効化 = real trace + 固定 expected events) + review-1 PASS (= rest 0x0F handler 仮説 carry) + review-2/3/4/5 FAIL。 main agent autonomous で agent 5 focused 再投資 起動 (= agentId `abb6ecbd1a9c97112`、 elapsed 1044 秒、 confidence high) で **真の SSG silent root cause = PMDDotNET 3-byte tempo encoding と driver 1-byte `comt` handler 不整合** 確定 (= PMDDotNET `mc.cs:7474-7479` `tempoa()` で `0xFC 0xFF <BPM raw>` 3-byte emit + driver `comt` (= `standalone_test.s:3911-3914`) 1-byte fetch のみ = 旧 PMD V4.8s 2-byte format 想定、 ssg-active-ladder.mml G part body byte 列 `fc ff 64 fe 08 30 18 30 18 30 18 30 18 80` literal verify、 driver は `comt` で fetch `0xFF` → `driver_tempo_d = 0xFF` 異常高速、 次 byte `0x64` を note byte E6 (OCT=6 ONKAI=4) として誤 keyon、 G silent ではなく E6 短 burst → user perception silent + observed peak 2659 Hz は E6 fundamental 1319 Hz × 2 = 2nd harmonic 2637 Hz 一致 0.8% 誤差) + agent 2 仮説 2 反証真因 = worktree HEAD `3ad1e23` (= 2026-05-11、 ADR-0051 β 実装前) base anchor `36330a6` (= 2026-05-26) の ancestor、 outdated source (= 2581 lines、 30+ symbol 不在) を base anchor source (= 5938 lines) と誤同視 = memory `feedback_subagent_isolation_worktree_base_ref_mismatch.md` 9 件 guard #2/#3 trigger 該当 (= sprint γ impl 着手時 main agent 経路 worktree 再作成 mandate)。 ADR doc 修正範囲 = (1) Annex α-5 新規追加 = agent 5 finding literal (= compiler source line + driver source line + binary byte literal + 誤解釈 path + 観測整合 + worktree base ref mismatch escalation literal) + (2) Annex β-2 新規追加 = plan v2 (= scope shift (= SSG mixer enable scope OUT、 tempo 3-byte handling scope IN) + must-fix 1-5 全反映 + repair patch v2 design literal = patch (1) `pmdneo_part_main_parse` rest 0x0F handler `.if PMDNEO_USE_PMDDOTNET` binary toggle + patch (2) `comt` tempo 3-byte handling helper routine `pmdneo_comt_pmddotnet` 新規追加 (= 0x0610 セクション末尾、 ADR-0051 `pmdneo_ssg_tone_sync` pattern 踏襲、 `(BPM*13)>>6` 換算 logic embedded) + γ impl order (= worktree 再作成 + 2 patch + sdasz80 build + .lst predicate + 4 build matrix sha256 + δ functional) + δ-1〜δ-7 verify gate revised (= real trace + 固定 expected register values = reg 0xA1/0xA5 FNUM + 0x07 SSG mixer + 0x00/0x02/0x04 SSG period + driver_tempo_d shadow)) + (3) 改訂履歴 sprint β round 1 + agent 5 + plan v2 entry append (= 本 entry、 append only mandate 厳守) + (4) dashboard 0071 行 status update (= 「Draft 起票」 → 「Draft + α 完走 + sprint β round 1 plan review revise + agent 5 真の root cause finding + plan v2 起草」) + (5) escalation 履歴 ADR-0071 entry 更新 (= plan review chain placeholder → round 1 revise + agent 5 + plan v2 literal、 round 2 投入予定 placeholder)。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0048 軸 G ε partial state placement / ADR-0026 §決定 3/4 / ADR-0041〜0070 本文 + Annex / 既存 scripts (= analyze-audio.py / analyze-audition-wav.py / test_analyze_audition_wav.py) / `wip-dashboard-coverage` branch + `docs/dashboard/` untracked / 退避 branch 完全 untouched。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= sprint β round 1 doc-only iteration で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0065 sprint A AXIS-5 fix-up precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` (= PR #153 base) + (2) merge atomic 11 回目適用予定 + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review round 2 on Annex β-2 plan v2 (= user 明示 5 重点軸 = (1) rest handler 仮説 carry + (2) **真 SSG silent root cause = tempo 3-byte encoding 仮説妥当性 新軸** + (3) guarded change binary toggle で production sha256 維持可否 + (4) allowed-touch 限定 (= SSG mixer touch 削除、 comt touch 追加) + (5) verify plan 実効化 = real trace + 固定 expected register values) + approve loop + main agent 経路 merge + atomic 1 セット 11 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手 (= worktree 再作成 mandate)、 sub-sprint β/γ/δ/ε 起票判断 = main agent autonomous default、 user 判断 = sha256 維持崩れ / allowed-touch 拡張 / 別 ADR scope 変更時のみ。 | (= 本 plan v2 commit chain 内 commit 1) |
| 2026-05-27 | 43rd session | ADR-0071 起票 Draft = PMDNEO driver-PMDDOTNET integration repair sprint (= sprint α scope = root cause investigation 完走 + Annex α 4 sub-agent finding literal record + Annex β-1 plan v1 起草 + sub-sprint chain α/β/γ/δ/ε 5 段 plan literal、 ADR-0065 sprint B follow-up integration verify で発見した driver 真の bug 2 件 (= rest 0x0F handler missing + SSG mixer enable missing) の engineering repair、 user 明示「Claude Code 主担当 + main agent autonomous」 mandate 経路、 4 並走 sub-agent investigation 完了 (= agent 1 `a1d35d89aa90b5f76` / agent 2 `a6a68b892193cded5` / agent 3 `a96c0520e9be2b697` / agent 4 `a34df6cbc138382da` confidence 全 high)、 issue 3 (= harness flag) + issue 2A (= FFT artifact) は driver 修理 scope 外確定、 user 明示 scope narrowing 完了)。 ADR doc 修正範囲 = (1) ADR-0071 file 新規 (= 8 決定 + verify gate + Annex α 4 sub-section + Annex β-1 plan v1 + Annex β-2/3/4 placeholder + 改訂履歴 + 平易要約) + (2) dashboard 0071 行 add (= 「Draft 起票」 + 8 決定 概要) + (3) dashboard escalation 履歴 ADR-0071 entry 1 row 追加 + (4) memory + MEMORY.md = merge 後 main agent direct (= 別途、 repo 外、 PR diff target 完全 excluded)。 driver / 既存 verify script / 既存 fixture MML / vendor / 既存 build flag / ADR-0041〜0070 本文 + Annex / scripts/analyze-audio.py + scripts/analyze-audition-wav.py 完全不変。 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= sprint α doc-only sprint で build しない、 carry)。 commit chain = 単一 commit (= 本 commit、 ADR-0067/0068 ε precedent 同 pattern)。 branch 運用 4 条規律 = (1) PR 先 default `wip-pmddotnet-opnb-extension` confirmed + (2) merge atomic 11 回目適用予定 (= PR #142+...+#152 + 本 ADR-0071 起票 PR) + (3) close 不要時削除 想定なし + (4) 保持対象 3 type 不可触 confirmed。 後続 = Codex layer 2 plan review on Annex β-1 plan v1 (= user 明示 5 重点軸 = rest handler 仮説 + SSG mixer 仮説 + sha256 guarded change + allowed-touch + verify plan 実音成立) + approve loop + main agent 経路 merge + atomic 1 セット 11 回目 + memory + dashboard maintenance + γ sub-sprint impl 着手判断 (= main agent autonomous default)。 | (= 本起票 commit chain 内 commit 1) |

## 平易要約

### ADR-0071 でやりたいこと

ADR-0065 sprint B follow-up で発見した、 PMDDOTNET_MML 経路で実音 audition material が成立しない driver 側 root cause 2 件 (= (1) PMDDotNET rest opcode `0x0F` を driver parser が解釈できず garbage keyon を発火、 (2) SSG mixer enable bit が一度も clear されず G/H/I 全 silent) を engineering repair sprint として修理する。 audition material 設計層の問題ではなく driver 側の再生成立性の問題。

### ADR-0071 前提

- ADR-0065 sprint B 完走 (= PR #152 MERGED at `70230d1`) + sprint B follow-up integration verify で 4 finding 判明
- 4 並走 sub-agent investigation 完走 (= agent 1/2/3/4 全 confidence high)、 driver 真の bug = 2 件、 残り 2 件 (= harness flag + FFT artifact) は driver 修理 scope 外
- user 明示「Claude Code 主担当 + main agent autonomous」 + 「scope narrow」 + 「doc wording ではなく root cause + plan 重点 Codex review」 mandate
- ADR-0069 guarded change pattern (= `.if PMDNEO_USE_PMDDOTNET == 1`) で production sha256 維持の見込み

### ADR-0071 でやること

- (sprint α = 本 PR1) ADR-0071 doc 起票 + Annex α 4 sub-agent finding 記録 + Annex β-1 plan v1 起草
- (sprint β) Codex Rescue plan review approve loop (= user 明示 5 重点軸)
- (sprint γ) driver source 2 routine 修理 (= guarded change)
- (sprint δ) FM/SSG ladder で実音成立 verify + 既存 18+ regression
- (sprint ε) Draft → Accepted + ADR-0065 audition material 再設計 trigger 解除

### ADR-0071 起票後の結果

- ADR-0071 = Draft 起票完了 (= sprint α 完走)
- 4 sub-agent finding literal record = sprint A engineering gate framework が user audition 前段で本 bug を検出した実証
- repair plan v1 = guarded change 経路 + scope narrow + verify plan 実音成立確認
- ADR-0065 audition material 再設計 trigger = ADR-0071 ε Accepted 後解除予定

### ADR-0071 ε Accepted 後の解釈 (= future)

- 「driver-PMDDOTNET integration repair 完了」 wording 解禁 + 併記必須 4 件
- ADR-0065 audition material 再設計 sprint 着手 ready (= user 明示 GO で起票判断)
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「本番 cmd 切替完了」 = 永久禁止維持

### 次

- ADR-0071 PR1 commit + push + PR 起票
- Codex layer 2 plan review on Annex β-1 plan v1 + 5 重点軸 + approve loop
- main agent 経路 merge + branch 削除 atomic 1 セット 11 回目
- memory + dashboard maintenance
- γ sub-sprint impl 着手判断 (= main agent autonomous default、 user 判断 = sha256 維持崩れ / allowed-touch 拡張 / scope 変更時のみ)
