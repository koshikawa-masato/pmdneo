# ADR-0054: PMDNEO 軸 B 実装 sprint 3 = δ-3 F-2-B ch3 4-op individual mode integration

- 状態: **Draft** (= 2026-05-22 39th session 軸 B 実装 sprint 3、 ground truth = ADR-0045 Annex I-3 / §J-4-3、 α 起票 doc-only filing + β F-2-B minimal driver integration + γ verify script 体系化 完了、 後続 δ で completion → Draft → Accepted。 ADR-0045 §J-4-3 literal 後続実装 ADR。 **軸 B 実装 sprint chain の 実装 3 = δ-3 = F-2-B ch3 4-op individual mode の入口 + register write proof**。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex I-3 で δ-3 設計を literal 化 + §J-4-3 で実装 sprint 3 bridging note 化、 本 ADR の母 ADR)
  - **ADR-0052** (= 軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry、 Accepted、 v2 entry = cmd 0x07 + `nmi_dispatch` + `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch` / `pmdneo_v2_entry_skeleton`。 **本 ADR で完全不可触保護** = 並設 only / 本体直接 call only)
  - **ADR-0053** (= 軸 B 実装 sprint 2 = δ-2 PartWork/SRAM placement、 Accepted、 v2 SRAM sub-region map = `pmdneo_v2_driver_state_base` 0xFD39 等。 **本 ADR で完全不可触保護**。 F-2-B が v2 SRAM field を要する場合は本 region map に従う)
  - **ADR-0049 / ADR-0050 / ADR-0051** (= 軸 B 実装 sprint 5/6/7 mute / fade-out / SSG tone-enable、 Accepted、 **本 ADR で完全不可触保護**)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**)
  - ADR-0043 (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触**)
  - ADR-0044 (= 軸 F MML compiler 拡張、 Accepted、 **F-2-A defer 維持 + vendor PMDDotNETCompiler 完全不可触**。 F-2-B は ADR-0044 で軸 B へ譲渡された軸)
  - ADR-0006 (= §H FM3 拡張想定、 **本 ADR で完全不可触**)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化 + 39th session 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 並設 routine 配置規律基盤)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 長時間 verify は background + polling monitor + hang 判定 + kill/retry 必須)

## 背景 (= why now)

### 軸 B 実装 sprint 1/2 (= δ-1/δ-2) 完了 base

39th session までに軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry (= ADR-0052 Accepted) + sprint 2 = δ-2 PartWork/SRAM placement (= ADR-0053 Accepted) が完了した。 v2 driver は cmd 0x07 経由 entry trigger path + FM 6ch / SSG 3ch v2 dispatcher + v2 SRAM sub-region foundation を持つ。 軸 B 実装 sprint chain の残 = 実装 3-4 = δ-3 (= F-2-B integration) / δ-4 (= 軸 C/G/rhythm 接続点)。

### δ-3 = F-2-B ch3 4-op individual mode の入口

ADR-0045 §I-5-b の実装 sprint 順序提案は δ-1 → δ-2 → δ-3 → δ-4 sequential。 δ-3 = F-2-B 譲渡軸 (= ADR-0044 で軸 F から軸 B へ譲渡された FM ch3 4-op individual mode) の integration。 F-2-B = YM2610 の reg 0x27 bit 7 (= CH3 individual mode = ch3 を 4 operator 個別制御) を enable し、 ch3 op1-4 を per-operator に register write する機能。 v2 driver の FM dispatcher (= ADR-0052 γ `pmdneo_v2_fm_dispatch`) は現在 ch3 を他 FM ch と同じ keyon dispatch するのみで、 individual mode の入口を持たない。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0054 を doc-only filing として起票し、 δ-3 の scope (= 簡易実装 trace-proof / legacy hook 不可触) を固定する。

## 決定

### 決定 1: 軸 B sprint 3 sub-sprint 構成 = 4 段 α/β/γ/δ

δ-3 実装を **4 段階 α/β/γ/δ** に分割する。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0054 起票 (= doc-only) + δ-3 scope / F-2-B 経路 / verify gate / 規律 literal 化 | 本 ADR-0054 起票 + dashboard sync、 driver / verify script touch なし、 doc-only | なし |
| **β** | minimal driver integration = v2 FM dispatcher に F-2-B 最小並設 proof path 追加 (= reg 0x27 bit 7 set + ch3 op1-4 individual register write) | F-2-B proof path 並設 + production build PASS + reg 0x27 bit 7 / ch3 op1-4 register write trace 観測 + 既存 FM 6ch keyon / SSG 3ch dispatch / cmd 0x07 path 不変 | 最小限 (= F-2-B 並設 proof path) |
| **γ** | verify script 体系化 (= 想定 `verify-axis-b-f2b-integration.sh`) | verify gate 全 PASS + verify script | verify script のみ (= driver touch なし) |
| **δ** | completion + ADR-0054 Draft → Accepted 判断 | 全 sub α/β/γ verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由、 完全自走 model) | なし (= doc-only completion) |

各 sub-sprint = 1 PR。 計 = α/β/γ/δ 各 1 PR = **4 PR**。 全 PR で軸 G / 軸 C / rhythm / ADR-0049/0050/0051/0052/0053 / vendor PMDDotNETCompiler 完全不可触。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model)
- 長時間 verify / MAME / regression は background 実行 + polling monitor 併走 + hang 判定 + kill/retry (= memory `feedback_long_running_verify_polling_hang_detection.md`)
- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 完全不可触
- ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable / ADR-0052 v2 entry / ADR-0053 v2 SRAM region 完全不可触
- vendor PMDDotNETCompiler 全部 完全不可触 (= F-2-A defer 維持)
- 「軸 B 完成」 表現禁止 (= 「ADR-0054 = 軸 B 実装 sprint 3 (= δ-3)」 表記、 軸 B 実装完了ではない)
- α は β に先行する (= ADR-0054 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: F-2-B integration 経路 = 簡易実装 (= trace-proof 中心) (= §I-3-a user 判断 gate 確定)

ADR-0045 §I-3-a は F-2-B integration 経路を 3 案 (= PMDPPZ 流儀 / 簡易実装 / PMD V4.8s 流儀) の user 判断 gate と明記した。 39th session で **簡易実装 (= trace-proof 中心)** を確定した (= user 判断、 Codex layer 2 起票 plan review escalate → user 確定)。

- δ-3 の目的 = ADR-0045 §I-3/§J-4-3 の F-2-B register trace proof を通すこと。 = 「ch3 individual mode の入口」 と「register write proof」 を確立する sprint。
- v2 FM dispatcher (= `pmdneo_v2_fm_dispatch`) 側に **最小の並設 proof path** を置き、 reg 0x27 bit 7 (= CH3 individual mode enable) set + ch3 op1-4 individual register write の register trace proof を出す。
- **scope 外 (= 後続 future)**: 実音 individual mode 完全動作 / PMDPPZ 流儀 full 実装 (= 100-150 件 if 分岐 + wrapper) / fnum per-op 完全制御 / PMDDotNet compiler 側 F-2-B (= F-2-A defer) / 既存 hook framework の本格接続。

### 決定 3: PART_FM3EXT_X/Y/Z legacy hooks=noop は不可触維持 (= §J-4-3 scope 一部 defer、 user 判断 gate 確定)

ADR-0045 §J-4-3 は δ-3 scope に「PART_FM3EXT_X/Y/Z hooks=noop 解除」 を列挙したが、 これは full F-2-B (= PMDPPZ 流儀) 想定の記述。 39th session で **本 sprint 3 では legacy PART_FM3EXT_X/Y/Z hooks=noop を解除せず不可触維持** を確定した (= user 判断、 Codex layer 2 escalate → user 確定)。

- 既存 `PART_FM3EXT_X/Y/Z` constant (= `standalone_test.s` L142-144) + legacy noop hook wiring (= L1459/L1706 hooks=noop literal + L1723-L1734 `pmdneo5_init_part_hooks_noop` 経由配線) は **完全不可触**。
- F-2-B は v2 FM dispatcher 側の最小並設 proof path で扱い、 legacy 経路を一切 touch しない。
- §J-4-3 の「hooks=noop 解除」 (= legacy X/Y/Z 拡張 part 経路の活性化) は **full F-2-B 後続 future** へ defer する (= 本 §決定 3 で literal 記録)。

### 決定 4: reg 0x27 bit 7 write 方式 = 既存 reg 0x27 非破壊

F-2-B の reg 0x27 bit 7 (= CH3 individual mode enable) write は、 既存 reg 0x27 write path を破壊しない方式とする。

- reg 0x27 は既存 init で write 済 (= `standalone_test.s` L347-357 付近、 bit 6 = multi-freq mode 等)。 reg 0x27 は read-back 不可。
- F-2-B の bit 7 set は **既存 reg 0x27 値を破壊しない方式** (= shadow byte RMW or 既存値 base への OR 等) を β で確定する。 既存 reg 0x27 write path (= L347-357) は不可触。
- v2 SRAM field を要する場合 (= reg 0x27 shadow 等) は ADR-0053 §決定 2 の v2 driver_state 拡張 region (= 0xFD3C-0xFD78 free) に `pmdneo_v2_` prefix で β 配置する。

### 決定 5: verify gate (= register trace primary gate)

δ-3 は **register trace primary gate** で verify する。 γ sub-sprint で次を verify script (= 想定 `src/test-fixtures/axis-b/verify-axis-b-f2b-integration.sh`) に体系化する。

| # | gate | 期待 |
|---|---|---|
| 1 | cmd 0x07 v2 path 到達維持 | `pmdneo_v2_entry_marker` (0xFD3B) ← 0x07 (= ADR-0052 v2 entry path が F-2-B 追加後も維持) |
| 2 | reg 0x27 bit 7 set | F-2-B proof path で reg 0x27 が bit 7 = 1 で write される (= CH3 individual mode enable) |
| 3 | ch3 op1-4 individual register write | ch3 op1-4 の individual register (= TL 0x42/0x46/0x4A/0x4E 等) write が register trace で観測可能 |
| 4 | 既存 FM/SSG v2 dispatch regression | 既存 FM 6ch keyon (reg 0x28) + SSG 3ch dispatch (reg 0x08-0x0A) が F-2-B 追加後も維持 |
| 5 | baseline regression | ADR-0052 `verify-axis-b-v2-entry.sh` 7 gate + ADR-0053 `verify-axis-b-sram-placement.sh` 6 gate (= mute/fade/SSG tone-enable + baseline を transitively) 全 PASS |
| 6 | `.org` overflow / SRAM boundary 不変 | production build `.lst` で v2 並設 routine が `.org` 境界 overlap なし + ADR-0053 v2 SRAM region 境界定数不変 |

verify gate の最終件数は γ sub-sprint で確定する。 audio gate は δ-3 の完了判定に用いない (= 簡易実装 trace-proof、 実音 individual mode 完全動作は後続 future)。

### 決定 6: scope-in / scope-out / non-goal

#### scope-in (= sprint 3 で扱う)

- v2 FM dispatcher への F-2-B 最小並設 proof path (= reg 0x27 bit 7 set + ch3 op1-4 individual register write)
- reg 0x27 bit 7 = CH3 individual mode enable の trace proof
- ch3 op1-4 individual register write の trace proof
- register trace primary gate の verify script 体系化

#### scope-out (= 別 ADR / 別 sprint / future)

- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm 接続点** = δ-4 (= 実装 sprint 4)
- **PART_FM3EXT_X/Y/Z legacy hooks=noop 解除** (= §J-4-3 の一部) = full F-2-B 後続 future (= §決定 3)
- **PMDPPZ 流儀 full 実装** (= 100-150 件 if 分岐 + wrapper) = full F-2-B 後続 future
- **実音 individual mode 完全動作 / fnum per-op 完全制御** = full F-2-B 後続 future
- **PMDDotNet compiler 側 F-2-B** = F-2-A defer (= ADR-0044、 vendor PMDDotNETCompiler 不可触)
- **既存 hook framework の本格接続** = 後続 future

#### non-goal (= 軸 B sprint 3 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 / ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable / ADR-0052 v2 entry / ADR-0053 v2 SRAM region の routine + SRAM field の modify
- 既存 reg 0x27 write path (= `standalone_test.s` L347-357) の変更
- `PART_FM3EXT_X/Y/Z` constant + legacy noop hook wiring の変更
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐の変更
- vendor PMDDotNETCompiler の変更 (= F-2-A defer)

### 決定 7: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする。

- ADR-0052 v2 entry routine (= cmd 0x07 path / `nmi_cmd_7_play_song_v2` / `pmdneo_v2_entry_skeleton` / `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch`)。 F-2-B は並設 proof path or `pmdneo_v2_fm_dispatch` への最小 additive で扱い、 既存 v2 dispatcher の FM 6ch keyon / SSG 3ch dispatch loop は破壊しない
- ADR-0053 v2 SRAM region 境界定数 + 既配置 v2 driver_state field
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable の routine + SRAM field
- `PART_FM3EXT_X/Y/Z` constant (= `standalone_test.s` L142-144) + legacy noop hook wiring (= L1459/L1706 + L1723-L1734)
- 既存 reg 0x27 write path (= L347-357)
- 軸 G ADR-0048 routine + 軸 G scratch 0xFD33-0xFD38
- 軸 C ADR-0043 ADPCM-B routine 全部 + rhythm ADR-0026〜0031 routine 全部
- vendor PMDDotNETCompiler 全部 (= F-2-A defer)
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐 / ADR-0006 §H literal

### 決定 8: doc-only filing 規律 (= 本 ADR-0054 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0054 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0054 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0054 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / ADR-0049/0050/0051/0052/0053 完全不可触

### 決定 9: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 sprint 3 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model を継承する。 主軸の報告 / kickoff plan / commit GO / Accepted 移行判断は Codex layer 2 へ投入し、 approve なら主軸が commit + push + PR + merge + dashboard update まで自律完走、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終完走報告のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: δ-3 ground truth (= ADR-0045 §I-3 / §J-4-3 reference)

本 ADR-0054 の δ-3 設計 ground truth は ADR-0045 に literal 化済であり、 本 ADR は再調査せず reference する。 ただし integration 経路と hooks=noop 解除の scope は本 ADR §決定 2/3 が user 判断で確定する。

| ADR-0045 section | 内容 | 本 ADR との関係 |
|---|---|---|
| §Annex I-3-a | δ-3 = F-2-B hook integration の 8 評価軸 | reference (= 目的 / verify gate 軸)。 「user 判断が必要な箇所 = F-2-B integration 経路 3 案」 は §決定 2 で簡易実装確定 |
| §Annex I-3-b | F-2-B 4-op individual mode register fixture (= reg 0x27 bit 7 / ch3 op1-4 TL/AR/fnum) | reference (= Annex B register map の ground truth) |
| §J-4-3 | 実装 sprint 3 bridging note = scope / ground truth / verify gate / 不可触対象 / user 判断 gate | reference。 ただし「PART_FM3EXT_X/Y/Z hooks=noop 解除」 は §決定 3 で full F-2-B 後続 future へ defer |

## Annex B: F-2-B ch3 4-op individual mode register map (= ADR-0045 §I-3-b reference)

簡易実装 trace-proof で扱う F-2-B 関連 register (= YM2610 datasheet 整合、 ADR-0045 §I-3-b literal)。

| register addr | 役割 |
|---|---|
| `0x27` | Mode and Timer Control register。 **bit 7 = CH3 mode (1 = individual mode = F-2-B 4-op enable)**。 bit 6 = CSM、 既存 driver は bit 6 等を使用中 (= 非破壊 write、 §決定 4) |
| `0x42 / 0x46 / 0x4A / 0x4E` | ch3 op1-4 TL (= per-op total level、 individual mode で per-op 制御) |
| `0x52 / 0x56 / 0x5A / 0x5E` | ch3 op1-4 AR (= per-op attack rate) |
| `0xA0-0xA2 / 0xA8-0xAA` | ch3 fnum/block (= individual mode で per-op fnum、 簡易実装 trace-proof では proof 対象範囲を β で確定) |

β の F-2-B 並設 proof path は reg 0x27 bit 7 set + ch3 op1-4 individual register write (= 上記 TL/AR 等) を register trace で観測可能にする。 per-op fnum 完全制御 / 実音 individual mode は後続 future (= §決定 6 scope-out)。

## Annex C: β 実装 completion record (= F-2-B minimal driver integration)

### C-1: β deliverable

軸 B 実装 sprint 3 β = F-2-B minimal driver integration (= 39th session、 PR #84)。 §決定 2 簡易実装 (= trace-proof 中心)。

| deliverable | 内容 |
|---|---|
| `pmdneo_v2_fm3ext_dispatch` 並設 routine | F-2-B ch3 4-op individual mode dispatcher (= 0x0610 セクション 新設)。 (1) reg 0x27 bit 7 を非破壊 set (= 0xAA = init 値 0x2A `|` 0x80) (2) ch3 op1-4 individual TL register (= 0x42/0x46/0x4A/0x4E) を per-op 異値 0x20/0x21/0x22/0x23 で write。 既存 `ym2610_write_port_a` を本体直接 call |
| `pmdneo_v2_entry_skeleton` 拡張 | δ の `call pmdneo_v2_ssg_dispatch` 直後に `call pmdneo_v2_fm3ext_dispatch` を追加 |

### C-2: 簡易実装 trace-proof + 不可触

β = §決定 2 簡易実装 = reg 0x27 bit 7 + ch3 op1-4 individual register write の trace proof のみ。 reg 0x27 = 0xAA は init 値 0x2A (= L357-359、 TIMER-B reset/IRQ enable/run) への bit 7 OR で **既存 TIMER bit 非破壊** (= §決定 4)。 ch3 op1-4 TL を per-op 異値 (= 0x20-0x23) で write し individual addressing を観測可能化。 既存 reg 0x27 write path (= L347-359) / `PART_FM3EXT_X/Y/Z` legacy hooks=noop / 既存 v2 FM 6ch dispatcher + SSG 3ch dispatcher 完全不可触 (= 並設 only、 `ym2610_write_port_a` 本体 call only)。 実音 individual mode 完全動作 / fnum per-op 完全制御 / PMDPPZ 流儀 full 実装は scope-out (= 後続 future、 §決定 6)。

### C-3: β 検証結果

- production build PASS。 `pmdneo_v2_fm3ext_dispatch` = 0x09C6 (= 0x0610 セクション >= 0x0610、 overflow なし)、 `.org 0x0066` セクション max addr 0x00F9 (= 0x0100 未満、 overlap なし、 β は 0x0066 セクション不変)
- V2 fixture build (= `TEST_MODE_V2_ENTRY_FIXTURE=1` + `MML_INPUTS=ssg-v0-keyon.mml`) + MAME headless trace、 両 chip:
  - **reg 0x27 ← 0xAA** (= bit 7 set = CH3 individual mode enable) 各 1 write (= ym2610 idx 245 / ym2610b)
  - **ch3 op1-4 individual TL** = reg 0x42/0x46/0x4A/0x4E ← 0x20/0x21/0x22/0x23 各 4 write (= per-op 異値、 individual addressing proof)
  - 既存 FM 6ch keyon (reg 0x28) 維持 = ym2610 4 (= B/C/E/F、 A/D skip) / ym2610b 6 (= 全 6ch)、 SSG 3ch dispatch (reg 0x08-0x0A ← 0x0F) 維持 = 両 chip 各 3
  - `pmdneo_v2_entry_marker` (0xFD3B) ← 0x07 維持 (= cmd 0x07 v2 path 到達)
- baseline regression: `verify-axis-b-v2-entry.sh` 7 gate 全 PASS (= 内部で `verify-fadeout-semantics.sh` 16 = `verify-mute-semantics.sh` 7 + baseline 9 script + `verify-ssg-tone-enable.sh` 15 gate を transitively)
- Codex layer 2 = β 実装 review approve

## Annex D: γ 実装 completion record (= F-2-B integration verify script 体系化)

### D-1: γ deliverable

軸 B 実装 sprint 3 γ = F-2-B integration verify script 体系化 (= 39th session、 PR #85)。 driver touch なし (= verify script + ADR + dashboard のみ、 §決定 1 γ 行 literal)。

| deliverable | 内容 |
|---|---|
| `src/test-fixtures/axis-b/verify-axis-b-f2b-integration.sh` | §決定 5 の verify gate 6 件を体系化した新規 verify script。 production build (= 静的 gate 1 静的部 / gate 6) + V2 fixture build ym2610/ym2610b + MAME headless trace (= gate 1 marker / gate 2/3/4) + `verify-axis-b-sram-placement.sh` (= gate 5 baseline) |
| ADR-0054 γ 反映 | Annex D + sub-sprint chain γ 行 + 改訂履歴 |

### D-2: verify-axis-b-f2b-integration.sh = 6 gate 構成

| gate | 種別 | 検証 |
|---|---|---|
| gate 1 | static + 動的 marker | `pmdneo_v2_entry_skeleton` が `pmdneo_v2_fm3ext_dispatch` を call (= production `.lst` 静的) + V2 fixture build z80-mem-trace で `pmdneo_v2_entry_marker` (0xFD3B) ← 0x07 (= cmd 0x07 v2 path 到達維持) |
| gate 2 | trace | V2 fixture trace で reg 0x27 ← 0xAA (= bit 7 = CH3 individual mode enable) 両 chip 各 1 write |
| gate 3 | trace | V2 fixture trace で ch3 op1-4 individual register = reg 0x42/0x46/0x4A/0x4E ← 0x20/0x21/0x22/0x23 (= per-op 異値) 両 chip 各 1 write |
| gate 4 | trace | 既存 FM 6ch keyon (reg 0x28、 ym2610 4 / ym2610b 6) + SSG 3ch dispatch (reg 0x08-0x0A ← 0x0F、 各 3) が F-2-B 追加後も維持 |
| gate 5 | baseline | `verify-axis-b-sram-placement.sh` 6 gate (= 内部で `verify-axis-b-v2-entry.sh` 7 gate + `verify-fadeout-semantics.sh` 16 + `verify-mute-semantics.sh` 7 + baseline 9 script + `verify-ssg-tone-enable.sh` 15 gate を transitively = ADR-0052/0053 + mute/fade/SSG tone-enable regression) 全 PASS |
| gate 6 | static | v2 並設 routine 5 件 (= `nmi_cmd_7_play_song_v2` / `pmdneo_v2_entry_skeleton` / `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch` / `pmdneo_v2_fm3ext_dispatch`) が 0x0610 セクション + 0x0066 セクション max addr (= 0x00F9) < 0x0100 |

### D-3: γ 検証結果

- `verify-axis-b-f2b-integration.sh` 6 gate 全 PASS (= 39th session 実行確認、 EXIT 0)
  - gate 1 = skeleton → fm3ext_dispatch call + marker 0xFD3B ← 0x07
  - gate 2 = reg 0x27 ← 0xAA 両 chip 各 1
  - gate 3 = ch3 op1-4 TL reg 0x42/0x46/0x4A/0x4E ← 0x20/0x21/0x22/0x23 両 chip 各 1
  - gate 4 = FM keyon ym2610 4 / ym2610b 6 + SSG dispatch 各 3
  - gate 5 = `verify-axis-b-sram-placement.sh` 6 gate 全 PASS
  - gate 6 = v2 並設 routine 5 件 >= 0x0610 + 0x0066 セクション max addr 0x00F9 < 0x0100
- driver touch なし (= verify-axis-b-f2b-integration.sh 新規 + ADR-0054 + dashboard のみ)
- Codex layer 2 = γ 実装 review approve

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) に「FM の 3 番チャンネルを 4 つのオペレータ個別に制御するモード」 (= F-2-B、 ch3 4-op individual mode) の入口を作る。 YM2610 のレジスタ 0x27 の bit 7 を立てると ch3 が individual mode になり、 ch3 の 4 オペレータを個別にレジスタ設定できる。

**前提**: 軸 B の実装は実装 1 (= v2 入口) と実装 2 (= v2 メモリ配置) が完了済。 実装 3 = δ-3 が F-2-B にあたる。 F-2-B は元々軸 F (= MML コンパイラ拡張) の一部だったが、 ドライバ側機能のため軸 B へ譲渡された。

**今回の範囲 (= 簡易実装)**: full な F-2-B (= 100-150 件の分岐を持つ PMDPPZ 流儀) ではなく、 「ch3 individual mode の入口」 と「レジスタ書き込みの証跡 (= register write proof)」 を確立する段階に絞る。 v2 の FM dispatcher の隣に最小の proof 用 path を置き、 reg 0x27 bit 7 + ch3 op1-4 の個別レジスタ書き込みが trace で観測できることを gate にする。 実音の完全動作・既存 hook の本格接続・コンパイラ側は後回し。

**触らないもの**: 既存の PART_FM3EXT_X/Y/Z 定数と noop hook の配線、 既存の reg 0x27 書き込み、 軸 C/G/リズム、 PMDDotNet コンパイラ。 全て不可触。

**進捗 (= α/β/γ 完了)**: α で設計書 (= 本 ADR-0054) を起票し、 範囲・F-2-B の経路・検証方法・不可触対象を文書で固定した。 β でドライバ (= `standalone_test.s`) に F-2-B の最小 proof path (= `pmdneo_v2_fm3ext_dispatch`) を追加し、 reg 0x27 bit 7 (= ch3 individual mode enable) + ch3 op1-4 の個別レジスタ書き込みの trace proof を出した。 γ で検証スクリプト (= `verify-axis-b-f2b-integration.sh`、 6 項目) を整備し、 全 6 項目 PASS を確認した。

**次**: δ で ADR-0054 を Draft → Accepted へ移行する (= 全 sub-sprint α/β/γ/δ 完走 + 検証 6 項目 PASS を根拠)。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0054 起票) | **完了** (= 39th session、 PR #83) | PR #83 | 起票 plan review = escalate (= 論点 2 件 = F-2-B 経路 / hooks=noop scope、 user 判断 → 簡易実装 / defer 確定) + 起票 review approve |
| β (= minimal driver integration) | **完了** (= 39th session、 PR #84) | PR #84 | β 実装 review approve |
| γ (= verify script 体系化) | **完了** (= 39th session、 PR #85) | PR #85 | γ 実装 review approve |
| δ (= completion + Draft → Accepted 判断) | 未着手 | - | - |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-22 | γ 実装完了 (= 39th session、 PR #85) | F-2-B integration verify script 体系化。 §決定 5 の verify gate 6 件を `src/test-fixtures/axis-b/verify-axis-b-f2b-integration.sh` に体系化 (= production build 静的 gate 1 静的部/6 + V2 fixture build ym2610/ym2610b MAME trace gate 1 marker/2/3/4 + verify-axis-b-sram-placement.sh baseline gate 5)。 Annex D 追記 (= γ completion + 6 gate 構成 + 検証結果) + sub-sprint chain γ 完了 reflect。 検証 = verify-axis-b-f2b-integration.sh 6 gate 全 PASS (EXIT 0)。 driver touch なし (= verify script 新規 + ADR-0054 + dashboard のみ)。 Codex layer 2 = γ 実装 review approve。 軸 B 実装 sprint 3 = δ-3、 残 δ (= completion + Draft → Accepted)、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
| 2026-05-22 | β 実装完了 (= 39th session、 PR #84) | F-2-B minimal driver integration。 `standalone_test.s` に `pmdneo_v2_fm3ext_dispatch` 並設 routine 新設 (= 0x0610 セクション、 reg 0x27 bit 7 非破壊 set = 0xAA + ch3 op1-4 individual TL register 0x42/0x46/0x4A/0x4E ← per-op 異値 0x20-0x23、 既存 `ym2610_write_port_a` 本体直接 call) + `pmdneo_v2_entry_skeleton` を `call pmdneo_v2_fm3ext_dispatch` 拡張。 Annex C 追記 (= β completion + deliverable + 簡易実装 trace-proof + 検証結果) + sub-sprint chain β 完了 reflect。 検証 = production build PASS (= fm3ext routine 0x09C6、 overflow なし) + V2 fixture trace 両 chip で reg 0x27 ← 0xAA + ch3 op1-4 TL ← 0x20-0x23 + FM 6ch keyon (ym2610 4 / ym2610b 6) + SSG 3ch dispatch 維持 + marker 0xFD3B 維持 + verify-axis-b-v2-entry.sh 7 gate baseline regression 全 PASS。 §決定 2 簡易実装 = trace-proof 中心、 既存 reg 0x27 write path / PART_FM3EXT legacy hooks=noop / 既存 v2 FM/SSG dispatcher 完全不可触。 Codex layer 2 = β 実装 review approve。 軸 B 実装 sprint 3 = δ-3、 残 γ/δ、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
| 2026-05-22 | Draft 起票 (= 39th session 軸 B 実装 sprint 3 α) | δ-3 F-2-B ch3 4-op individual mode integration の実装 ADR を起票。 軸 B 本線の実装 sprint 3 として δ-3 を選定 (= ADR-0045 §I-5-b sequential 順序、 δ-2 完了の次)。 決定 1-9 + 4 段 sub-sprint α/β/γ/δ + F-2-B 経路 = 簡易実装 (= trace-proof 中心、 §I-3-a user 判断 gate 確定) + PART_FM3EXT_X/Y/Z legacy hooks=noop 不可触維持 (= §J-4-3 の hooks=noop 解除 は full F-2-B 後続 future へ defer、 §I-3-a/§J-4-3 user 判断 gate 確定) + reg 0x27 bit 7 非破壊 write + verify gate 6 件。 doc-only filing (= ADR-0054 + dashboard のみ変更)。 ADR-0045 §J-4-3 literal 後続実装 ADR。 Codex layer 2 起票 plan review = escalate (= 論点 1 F-2-B 経路 / 論点 2 hooks=noop scope、 規律 check pass、 ADR 番号 0054 予約妥当) → user 判断 = 簡易実装 / hooks=noop 解除 defer で確定。 軸 B 実装 sprint chain は実装 3 = δ-3 が F-2-B 入口、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
