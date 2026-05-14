# ADR-0026 step 12 δ completion handoff: K/R rhythm compatibility proof sprint 完了統合

- 関連 ADR: [ADR-0026](../../adr/0026-pmdneo-step12-kr-rhythm-compatibility-proof.md) **Accepted** (= 2026-05-14 13th session δ 完了統合で移行)
- sub-sprint: δ (= 5 commit chain の 5 段目 = 最終、 完了統合 + Accepted 移行)
- commit: 本 commit
- 前段: γ commit `5465f08` (= commandsp 0xEB 分岐追加 + verify-step12-kr-differential.sh 新設 + K-R differential proof 確立)
- 次段: Step 13 候補 (= 本 ADR §次 sprint 候補参照、 user 13th session β/γ レビューで drum 種拡張 / `.PNE` rhythm bank migration / rhythm channel concept formalization 等を Step 13 候補として温存)

## Step 12 sprint の本質 (= Accepted 後の literal 固定、 user δ handoff 記載要件)

**Step 12 は K/R full compatibility ではなく K/R semantics dispatch proof stage**。 future contributor が「K/R compatibility 完成版」 と誤解せず、 「K/R semantics → PMDNEO native ADPCM-A trigger 接続の 1 段目」 として扱えるよう本 handoff で literal 明記する。

### 達成したこと (= Step 12 で literal 成立)

| 項目 | 内容 |
|---|---|
| **K part 0xEB rhykey path** | PMD V4.8s K part 内 `\b` → PMDDotNET emit `0xEB 0x01 0x80` → driver `rhythm_main_rhykey` → `pmdneo_rhythm_event_trigger` → ADPCM-A L ch BD trigger |
| **R command 0xEB rhykey path** | melody part (= L part 採用) 内 `\b` inline → PMDDotNET emit `0xEB 0x01` inline → driver `commandsp_rhykey` → 同 `pmdneo_rhythm_event_trigger` → 同 ADPCM-A L ch BD trigger |
| **K と R の dispatch path 1 本化** | K part / melody part の 2 source path が runtime layer で同 routine entry (= `pmdneo_rhythm_event_trigger` @ 0x1126) に collapse、 同 BD register write sequence が K build / R build で byte-identical |
| **driver-embedded BD trigger** | 既存 `adpcma_sample_bd` (= proof 用 driver fixture、 ADR-0019 §決定 3 build-time embed) を再利用、 register write 6 件 = reg 0x10 0x00 / 0x18 0x00 / 0x20 0x03 / 0x28 0x00 / 0x08 0xDF / 0x00 0x01 |
| **observability marker** | 独立 routine label `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable (= ADR-0026 §決定 8 整合、 memory marker byte なし、 SRAM layout 増設なし) |
| **既存 layering 不変保証** | PMDDotNET / `.MN` format / 既存 L-Q ADPCM-A melody architecture / multi-table proof / silent-bcef audio isolation 全て不変、 16/16 script regression PASS |

### 達成していないこと (= scope-out 維持、 future scope)

**user δ handoff 記載要件 5 項目を literal 明記**:

| 項目 | scope-out 維持理由 |
|---|---|
| **Step 12 は b-only proof** (= BD bit 0 のみ accept) | s/c/h/t/r 残り 5 drum 種 (= SD / CYM / HH / TOM / RIM) は future sub-sprint、 dispatch path は不変で drum 種 → sample pointer mapping を 1 軸拡張のみ |
| **L ch allocation は scaffold** | ADR-0026 §決定 4 整合、 K/R active 時の L ch 占有は proof 用暫定 allocation、 PMDNEO 恒久仕様ではない。 L-Q melody architecture は恒久的に縮小しない |
| **driver-embedded BD sample は proof 用** | ADR-0026 §決定 3 整合、 `adpcma_sample_bd` 再利用は最終 ownership ではない。 future sprint で `.PNE` rhythm bank へ migration path を維持 |
| **full 6 drum K/R compatibility は未実装** | Step 12 は dispatch path 1 本化の literal 証明が目的。 各 drum 種別の sample 切替 / volume / pan / 複数 drum 同時打ち / pattern loop / velocity は future sprint |
| **`.PNE` rhythm bank integration は future** | ADR-0026 §決定 3 / scope-out 整合、 `sample_table_id` id=0x02 rhythm bank / generated rhythm sample directory / driver-embedded fixture からの migration は future sprint で必要なら別途検討 |

加えて維持される他 scope-out 項目 (= ADR-0026 §scope-out 26 項目から抜粋):

| 項目 | scope-out 維持理由 |
|---|---|
| OPNA rhythm sound source register fake API (= 0x10-0x18) | PMDNEO は YM2610(B) で物理的に rhythm source 不在、 emulation は方針外 (= ADR-0026 §決定 2 / β 軸採用根拠) |
| 動的 channel allocation / rhythm channel 新概念 / 6ch drum sub-allocation | 最終 channel allocation は future sprint で channel allocation 軸の sprint 起票時に検討 |
| PMDDotNET 改造 / `.MN` format new bytecode 追加 | ADR-0026 §決定 7 整合、 Step 7-11 layering 維持原則継続 |
| OPNA native rhythm timing fidelity | dispatch proof であり完全 timing compatibility ではない (= ADR-0026 §scope-out 追加項目、 user γ レビューで literal 確認) |
| K と R 共通 dispatch 以外の K/R 制御 cmd 現役化 (= rhyvs / rmsvs / rpnset / rmsvs_sft / rhyvs_sft / pdrswitch 6 件) | PMDNEO.s legacy 系 KR_STUB.inc の no-op stub 思想を継続維持 (= ADR-0026 Annex A-6)、 standalone_test.s 本線でも他 cmd は silent fallback (= 1 byte 消費継続) |
| selected pointer runtime state cache (= A2/A3) | ADR-0024 §決定 6 / ADR-0025 §決定 1 維持 |
| 3 table 以上の multi-table / generated directory (D3) / runtime `.PNE` parser / multi-`.PNE` switching / bank switching | ADR-0025 §scope-out 継続維持 |

## sub-sprint chain 完了結果

### 5 commit chain (= ADR + α/β/γ/δ)

| sub | commit | 一文要約 |
|---|---|---|
| ADR | `29e3174` | ADR-0026 起票 Draft、 13th session 冒頭壁打ち 7 軸確定 + §決定 11 件 + sub-sprint 分割 + scope-out 26 項目明示 + 「本質再確認」 callout + layering 図 literal 固定 |
| α | `749b867` | ADR-0026 Annex A 追記 (= K/R bytecode + legacy K/R routine 調査結果 9 sub-section literal 反映)、 driver 完全不変純調査 commit、 既存 14 regression PASS、 fail-safe 2 件 evaluate → β 進行可 判定 |
| β | `309c011` | pmdneo_rhythm_event_trigger 新設 + rhythm_main K part body parser + pmdneo_mn_direct_load_k_part_addr + K fixture 新規 + verify-step12-k-rhythm-trigger.sh 5 段 gate PASS、 全 14 regression PASS |
| γ | `5465f08` | commandsp 0xEB 分岐追加 + R fixture (L part `\b` only) 新規 + verify-step12-kr-differential.sh 7 段 gate PASS (= K-R BD register write byte-identical literal 証明)、 全 14 + step12 β 計 15 script regression PASS |
| δ | 本 commit | 完了統合 + ADR-0026 Accepted 移行 + 全 16 script regression PASS + audible 試聴 + handoff doc 起票 + memory + MEMORY.md update |

### 「動いているものを壊さない」 規律遵守 (= ADR-0021-0025 で確立、 Step 12 で継続)

各 sub-sprint で driver source 改修を最小化し、 trivial verify (= 既存 path で false PASS) を段階分離で防いだ。

- ADR Draft: driver / `.MN` format / PMDDotNET 完全不変 (= 純文書化 commit)
- α: driver / `.MN` format / PMDDotNET 完全不変 (= 純調査 commit、 ADR §Annex A 追記のみ)
- β: driver standalone_test.s に 173 行追加 (= K part init conditional + rhythm_main 拡張 + pmdneo_rhythm_event_trigger + pmdneo_mn_direct_load_k_part_addr 新規)、 既存 routine 完全不変、 PMDDotNET / `.MN` format 完全不変
- γ: driver standalone_test.s に 14 行追加 (= commandsp に 0xEB 分岐 + commandsp_rhykey label)、 既存 routine 完全不変、 PMDDotNET / `.MN` format 完全不変
- δ: driver source 完全不変 (= regression + Accepted 移行 + handoff + memory のみ)

各段階の primary gate が trivial verify を弾く設計 (= memory `feedback_trivial_verify_detection_and_correction_commit` 整合):
- ADR Draft gate: doc only、 既存 14 script regression PASS 維持
- α gate: driver 不変 literal 確認 + 既存 14 script regression PASS
- β gate: build PASS + pmdneo_rhythm_event_trigger symbol 存在 + K fixture run PC trace marker hit + ADPCM-A L ch register write literal (= 5 reg + keyon mask) + 既存 14 script PASS
- γ gate: K-R routine addr identical + K-R BD register write sequence byte-identical (= 6 件) + K-R keyon count identical + 既存 14 + step12 β PASS
- δ gate: 全 16 script regression PASS + user 試聴 OK

## 全 16 script regression 結果 (= δ で serial 実行、 [[feedback_verify_script_serial_execution]] 整合)

| step | script | 結果 |
|---|---|---|
| 5 | verify-l-part-alpha-trace-gate.sh | PASS |
| 5 | verify-l-part-beta-sample-lookup.sh | PASS |
| 5 | verify-l-part-delta-volume-pan.sh | PASS |
| 5 | verify-l-q-tutti-gamma.sh | PASS |
| 5 | verify-l-q-rhythm-song-integration.sh | PASS |
| 6 | verify-silent-bcef-audio-isolation.sh | PASS |
| 7 | verify-step7-b1-roundtrip.sh | PASS |
| 7 | verify-step7-b3-byte-identical.sh | PASS |
| 7 | verify-step7-delta-mn-filename-embed.sh | PASS |
| 7 | verify-step7-delta-fix-quote-strip.sh | PASS |
| 8 | verify-step8-filename-observation.sh | PASS |
| 9 | verify-step9-resolver.sh | PASS |
| 10 | verify-step10-mismatch-silent.sh | PASS |
| 11 | verify-step11-multi-table.sh | PASS |
| 12 (β) | verify-step12-k-rhythm-trigger.sh | PASS (= 5 gate、 K rhythm BD trigger literal proof) |
| 12 (γ) | verify-step12-kr-differential.sh | PASS (= 7 gate、 K-R differential proof + byte-identical BD register write) |

→ **全 16 script / 約 75 gate PASS**。 k-br-only.wav / r-melody-br-only.wav は user 試聴用に `/tmp/pmdneo-step12/` に保存。

## user 試聴用 wav (= audio gate 結果)

| wav | 出所 | 内容 |
|---|---|---|
| `/tmp/pmdneo-step12/k-br-only.wav` | step 12 β/γ verify | K fixture (= K part `\b`) audible、 BD 音色 1 発鳴る (= rhythm_main_rhykey 経路) |
| `/tmp/pmdneo-step12/r-melody-br-only.wav` | step 12 γ verify | R fixture (= L part `\b` inline) audible、 K fixture と完全同 BD 音色 1 発鳴る (= commandsp_rhykey 経路、 audio domain でも K と区別不能) |

両 wav を聴き比べることで dispatch path 1 本化の audible 証跡を得る。 trace 層では既に byte-identical の literal 証拠があるが、 audio 層でも user 試聴で「同じ音」 が確認された (= 13th session δ user 確認済)。

### user δ audio gate finding (= 2026-05-14 13th session)

- **K fixture / R fixture の BD trigger は完全に同じ** (= user 聴感判定、 dispatch path collapse の audio 証跡成立)
- **FM 1-4 ch の同居音は scope-out 留保** (= 既存 compile.py default test01.mml / test02.mml の FM chord 進行が両 fixture に並走、 K/R fixture 内では明示的に mute していない)
- FM 同居 mute は silent-bcef pattern (= ADR-0020 step 6-a) と integration すれば実現可能だが、 Step 12 は **dispatch path 証明が主目的**で audio isolation は副次。 FM 同居許容で proof 成立を判断
- future audio gate sprint で必要なら fixture 統合検討 (= scope-out 維持)

## 13th session 全体まとめ

### 13th session 流れ

1. **冒頭壁打ち**: Step 12 = K/R rhythm compatibility proof sprint 採用 (= memory `project_pmdneo_step12_direction_kr_compat`)、 7 軸 user 主導確定 (= compatibility 軸 β / sample source s4 / channel allocation c5 / drum 種 b only / K と R 共通 dispatch / normalize layer driver parser / observability marker routine PC hit)
2. **ADR commit** (= `29e3174`): ADR-0026 Draft 起票、 §決定 11 件 + sub-sprint 分割 + scope-out 26 項目 + layering 図 literal 固定
3. **α commit** (= `749b867`): K/R bytecode + legacy K/R routine 調査、 ADR §Annex A 9 sub-section 追記、 driver 完全不変純調査
4. **β commit** (= `309c011`): driver 173 行追加で K rhythm trigger 成立、 verify-step12-k-rhythm-trigger.sh 5 gate PASS
5. **γ commit** (= `5465f08`): driver 14 行追加で R command も同 hook、 verify-step12-kr-differential.sh 7 gate PASS、 K-R byte-identical literal 証明
6. **δ commit** (= 本 commit): 完了統合 + Accepted 移行 + 全 16 script regression + 2 wav 保存

### Step 8 → Step 9 → Step 10 → Step 11 → Step 12 contract chain

| Step | sub-system 軸 | runtime state | playback effect |
|---|---|---|---|
| 8 | runtime `.PNE` filename observation | SRAM 0xFD20-0xFD32 filename buffer | 不影響 (= filename を読めるだけ) |
| 9 | identity resolution (= filename → sample_table_id) | 0xFD32 = id byte | 不影響 (= ADR-0023 §決定 11 literal、 ADR-0024 §決定 7 で解除) |
| 10 | identity → selection consumption | 0xFD32 = 0x00 (= accept) / 他 (= silent) | match = table A 引き / 他 = sentinel silent |
| 11 | multi-table differentiation | 0xFD32 = 0x00 (= table A) / 0x01 (= table B) / 他 (= silent) | 0x00 = L ch BD / 0x01 = L ch SD / 他 = silent |
| 12 | **K/R rhythm semantics → ADPCM-A dispatch** (= 別 sub-system 軸、 sample_table_id とは独立) | (= sample_table_id 状態と独立、 K/R 経路は selector を経由しない) | K part `\b` / melody part `\b` inline → 同 `pmdneo_rhythm_event_trigger` → ADPCM-A L ch BD |

Step 12 は **新 sub-system 軸 (= K/R rhythm)** の最初の literal proof。 Step 8-11 の ADPCM-A melody / multi-table sample selection 軸とは独立し、 source layer (= MML K part syntax + R command syntax) → normalize → runtime rhythm event → 共通 hook → ADPCM-A native trigger という 1 本化 layering を確立した。

### 13th session 学び (= 後続 sprint 向け教訓)

- **user 用語と PMD V4.8s manual 用語の差異整理は α 調査で必須** (= memory `project_pmdneo_step12_direction_kr_compat`、 「drum 識別文字 b」 = `\b` 1 文字、 manual の `\br` は `\b` + `r` rest の組合せ、 PMDDotNET grammar で確認必須)
- **β 着手前に PMDDotNET emit 状況 + driver legacy routine 状況を literal 反映する α 純調査 commit が有効** (= 後続実装 commit が「PMDDotNET 不変 / .MN format 不変 / 本線で新規実装」 の方針に迷わない)
- **二系統 driver (= PMDNEO.s legacy / standalone_test.s 本線) の選択指針** = legacy 系の K/R 配線 (= cmdtblr + KR_STUB.inc) は existence proof として参考、 本線では新規実装 (= 候補 (i) 採用、 ADR-0026 Annex A-5)
- **PMDDotNET emit `\b` → 0xEB rhykey + bitmap byte** で K と melody part 両方で同 opcode、 driver layer で dispatch path 1 本化が自然
- **R fixture の part 選択** = L part (= ADPCM-A、 standalone_test.s 本線で .MN direct path 既接続) を melody part の代表として採用、 commandsp 経路で 0xEB → 共通 hook
- **FM 同居の許容判断** = audio isolation は副次、 dispatch path 証明が主目的 (= user δ レビュー finding)、 future sprint で必要なら silent-bcef pattern 統合

## 次 sprint 候補 (= Step 13 候補)

user 13th session γ レビューで temporally 整理した候補 (= 本 ADR §scope-out のうち未消化 + future sprint で扱う):

1. **drum 種拡張** (= s/c/h/t/r の追加、 dispatch path は 1 本のまま drum 種 → sample pointer mapping を 1 軸拡張)
2. **`.PNE` rhythm bank migration** (= driver-embedded fixture → `.PNE` 経由 `sample_table_id` id=0x02 rhythm bank、 generated rhythm sample directory)
3. **rhythm channel concept formalization** (= K part / R command の channel allocation 最終仕様、 (c2) rhythm channel 新概念 / (c3) 6ch drum sub-allocation / (c4) 動的切替 のいずれか採用)
4. **複数 drum 同時打ち** (= BD + SD 同時打ち等、 PMDDotNET bitmap OR 結合 emit の driver 側対応)
5. **OPNA native rhythm timing fidelity** (= timing / mixing / overlap fidelity 復元、 完全 PMD audio 互換)
6. **K/R 制御 cmd 現役化** (= rhyvs / rmsvs / rpnset 等、 6 件 cmd の no-op → ADPCM-A volume 系制御へ rewire)
7. **selected pointer cache** (= A2 / A3、 動的化局面で再検討)
8. **mismatch silent flag micro-sprint** (= ADR-0025 §scope-out 継続)
9. **D3 generated directory migration**
10. **runtime `.PNE` parser / multi-`.PNE` switching / bank switching**
11. **PMDNEO.s + nullsound integration** (= 大規模 sprint)
12. **WebApp Phase 4 領域 (= WAV import / 新規 sample 追加 UI)**

Step 12 完了で「K/R semantics → PMDNEO native ADPCM-A dispatch」 path が成立、 Phase 3 driver (= ADPCM-A 6ch) の機能カバレッジは melody + multi-table + rhythm dispatch まで完成。 future sprint は (1) drum 種拡張 / (2) rhythm channel formalization / (3) `.PNE` rhythm bank / (4) dynamic asset 軸 / (5) WebApp 軸 のいずれかへの展開。

## 関連 memory

- `project_pmdneo_step11_complete.md` (= Step 11 完了、 multi-table id=0x01 proof + 「proof-of-selection stage」 表現)
- `project_pmdneo_step12_direction_kr_compat.md` (= 13th session 冒頭、 K/R rhythm compatibility proof sprint 採用判断 + 7 軸方針)
- `project_pmdneo_adpcma_subsystem_boundary.md` (= PMDNEO は ADPCM-A subsystem 専用、 `.PPC` / `.P86` / ADPCM-B は別 subsystem、 Step 12 scope 境界の前提)
- `project_adr_0016_step5_design_decision_2_k_part_scope_out.md` (= Step 5 で K/R を「legacy retained but inactive」 と判断、 Step 12 で「retained and reconnected under PMDNEO native mapping」 に格上げ)
- `project_pmdneo_step10_complete.md` (= Step 10 完了、 identity → selection consumption)
- `project_pmdneo_step11_a2_deferred.md` (= A2 selected pointer cache scope-out、 Step 12 でも維持)
- `project_pmdneo_step9_complete.md` (= step 9 完了、 0xFD32 identity resolver)
- `project_pmdneo_step8_complete.md` (= step 8 完了、 runtime filename observation)
- `project_pmdneo_step7_complete.md` (= step 7 完了、 `.PNE` asset pipeline)
- `project_pmdneo_step6_complete.md` (= step 6 完了、 audio isolation)
- `project_pmdneo_step5_complete.md` (= step 5 完了、 ADPCM-A 6ch native path)
- `project_pmdneo_step_role_split_semantics_source_listening.md` (= Step 5/6/7 役割分離、 Step 12 は K/R semantics 軸の独立 sub-system 第 1 段)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `project_pmdneo_driver_two_paths_discovery.md` (= PMDNEO.s legacy / standalone_test.s 本線、 Step 12 β で本線採用)
- `feedback_trivial_verify_detection_and_correction_commit.md` (= dead code → call insertion → behavior change 段階分離規律、 β は 1 commit で完結 + literal 分離せず handoff 明記)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 PC trace + ymfm-trace 二段 gate を採用)
- `feedback_pmddotnet_mml_authoring_rules.md` (= MML 新規作成時 CRLF 必須、 β fixture 作成時に literal 確認)
- `feedback_push_per_commit.md` / `feedback_post_commit_push_report_format.md` / `feedback_explain_in_plain_japanese_before_commit.md`
- `feedback_verify_script_serial_execution.md` (= δ で全 16 script serial 実行)
- `feedback_audio_gate_solo_isolation.md` (= solo 化 + scope 外 audio 排除規律、 Step 12 では FM 同居許容判断で副次 scope に留保)
- `feedback_codex_implementation_review.md` (= Codex 実装の Claude Code 側 review 義務、 Step 12 では Codex 経由実装なし)
