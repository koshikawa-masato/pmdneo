# ADR-0055: PMDNEO 軸 B 実装 sprint 4 = δ-4 v2 main loop 軸 C/G/rhythm 接続点定義

- 状態: **Draft** (= 2026-05-22 39th session 軸 B 実装 sprint 4 α、 ground truth = ADR-0045 Annex I-4 / §J-4-4、 ADR 起票 doc-only filing、 後続 β/γ/δ で接続点 stub driver 実装 → verify → completion。 ADR-0045 §J-4-4 literal 後続実装 ADR。 **軸 B 実装 sprint chain の 実装 4 = δ-4 = v2 main loop の軸 C/G/rhythm dispatch boundary 定義**。 軸 B 実装 sprint chain の最終 sprint だが ADR-0055 Accepted = sprint 4 完了であり「軸 B 完成」 ではない、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex I-4 で δ-4 設計を literal 化 + §J-4-4 で実装 sprint 4 bridging note 化、 本 ADR の母 ADR)
  - **ADR-0052 / ADR-0053 / ADR-0054** (= 軸 B 実装 sprint 1/2/3 = δ-1 v2 entry / δ-2 SRAM placement / δ-3 F-2-B、 Accepted。 **本 ADR で完全不可触保護** = v2 entry routine + SRAM region + F-2-B dispatch、 並設 only / 本体直接 call only)
  - **ADR-0049 / ADR-0050 / ADR-0051** (= 軸 B 実装 sprint 5/6/7 mute / fade-out / SSG tone-enable、 Accepted、 **本 ADR で完全不可触保護**)
  - **ADR-0043** (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触** = `adpcmb_keyon` 等の ADPCM-B routine + ADPCMB_DRV.inc 全部)
  - **ADR-0048** (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触** = `pmdneo_select_adpcmb_ppc_pointer` + ε partial state ppc_scratch 0xFD33-0xFD36 + audition_frame_counter 0xFD37-0xFD38。 軸 G Draft 状態 + ε partial state 不変)
  - **ADR-0026〜0031** (= rhythm 実装、 Accepted、 **本 ADR で完全不可触** = `pmdneo_rhythm_event_trigger` 等の rhythm routine + KR_STUB.inc 全部)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化 + 39th session 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 並設 routine 配置規律基盤)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 長時間 verify は background + polling monitor + hang 判定 + kill/retry 必須)

## 背景 (= why now)

### 軸 B 実装 sprint 1/2/3 (= δ-1/δ-2/δ-3) 完了 base

39th session までに軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry (= ADR-0052 Accepted) / sprint 2 = δ-2 PartWork/SRAM placement (= ADR-0053 Accepted) / sprint 3 = δ-3 F-2-B ch3 4-op integration (= ADR-0054 Accepted) が完了した。 v2 driver は cmd 0x07 entry trigger path + FM 6ch / SSG 3ch / F-2-B v2 dispatcher + v2 SRAM sub-region foundation を持つ。 軸 B 実装 sprint chain (= 実装 1-4 + mute + fade-out + SSG tone-enable) の残 = 実装 4 = δ-4 のみ。

### δ-4 = v2 main loop の軸 C/G/rhythm dispatch boundary 定義

ADR-0045 §I-5-b の実装 sprint 順序提案は δ-1 → δ-2 → δ-3 → δ-4 sequential で、 δ-4 が最後。 δ-4 = v2 main loop から軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm dispatch への **接続点 (= dispatch boundary)** を定義する sprint。 現 v2 driver の main loop (= `pmdneo_v2_entry_skeleton`) は FM/SSG/F-2-B dispatcher を call するのみで、 軸 C/G/rhythm への接続点を持たない。

δ-4 は他軸を直接動かす sprint ではなく、 **接続点・stub・dispatch boundary を定義する** sprint として scope を絞る (= 39th session user 明示方針)。 軸 C/G/rhythm の既存 routine は完全不可触、 実 dispatch (= ADPCM-B / rhythm playback) は後続 future。 CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0055 を doc-only filing として起票する。

## 決定

### 決定 1: 軸 B sprint 4 sub-sprint 構成 = 4 段 α/β/γ/δ

δ-4 実装を **4 段階 α/β/γ/δ** に分割する。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0055 起票 (= doc-only) + δ-4 scope / 接続点形式 / verify gate / 規律 literal 化 | 本 ADR-0055 起票 + dashboard sync、 driver / verify script touch なし、 doc-only | なし |
| **β** | 接続点 stub driver 実装 = v2 main loop に軸 C ADPCM-B / rhythm の接続点 stub 並設 routine 追加 (= marker proof) | 接続点 stub 並設 + production build PASS + ADPCM-B / rhythm 接続点 marker write trace 観測 + 既存 v2 FM/SSG/F-2-B dispatch + cmd 0x07 path 不変 | 最小限 (= 接続点 stub 並設) |
| **γ** | verify script 体系化 (= 想定 `verify-axis-b-axis-connection.sh`) | verify gate 全 PASS + verify script | verify script のみ (= driver touch なし) |
| **δ** | completion + ADR-0055 Draft → Accepted 判断 | 全 sub α/β/γ verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由、 完全自走 model) | なし (= doc-only completion) |

各 sub-sprint = 1 PR。 計 = α/β/γ/δ 各 1 PR = **4 PR**。 全 PR で軸 C / 軸 G / rhythm / ADR-0049〜0054 完全不可触。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model)
- 長時間 verify / MAME / regression は background 実行 + polling monitor 併走 + hang 判定 + kill/retry (= memory `feedback_long_running_verify_polling_hang_detection.md`)
- 軸 C ADR-0043 / 軸 G ADR-0048 / rhythm ADR-0026〜0031 完全不可触
- ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable / ADR-0052 v2 entry / ADR-0053 v2 SRAM region / ADR-0054 F-2-B の routine + SRAM field 完全不可触
- 「軸 B 完成」 表現禁止 (= 「ADR-0055 = 軸 B 実装 sprint 4 (= δ-4)」 表記。 軸 B 実装 sprint chain の最終 sprint だが ADR-0055 Accepted = sprint 4 完了であって「軸 B 完成」 ではない)
- α は β に先行する (= ADR-0055 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: 接続点の形 = stub marker proof (= §I-4-a user 判断 gate 確定)

ADR-0045 §I-4-a は接続点呼出 timing (= 直接呼出 vs hook 並走) を user 判断 gate と明記した。 39th session で **接続点 = stub marker proof** を確定した (= user 明示方針「接続点・stub 定義 sprint」、 Codex layer 2 起票 plan review approve)。

- v2 main loop に **接続点 stub 並設 routine** を追加する = `pmdneo_v2_adpcmb_dispatch` (= 軸 C ADPCM-B 接続点) + `pmdneo_v2_rhythm_dispatch` (= rhythm 接続点)。
- 各 stub は v2 main loop が ADPCM-B / rhythm dispatch boundary に到達したことを **SRAM marker write で trace proof** する。
- 既存 軸 C `adpcmb_keyon` (= ADR-0043 entry) / rhythm `pmdneo_rhythm_event_trigger` (= ADR-0026〜0031 entry) は本 sprint 4 では **call しない** (= 実音 ADPCM-B / rhythm playback は後続 future)。 = δ-4 は dispatch boundary を「定義」 する sprint であり、 実 dispatch は後続。
- **scope 外 (= 後続 future)**: 軸 C ADPCM-B 実 dispatch (= `adpcmb_keyon` call) / ADPCM-B literal value decay / 軸 G dynamic supply 本体 / rhythm 実 dispatch (= `pmdneo_rhythm_event_trigger` call) / 実音 rhythm 動作 / PART_PCM・PART_RHYTHM の v2 per-part dispatch loop full 実装。

### 決定 3: 軸 G 接続点 = ADPCM-B 接続点の sub-path、 別 stub なし

ADR-0045 §I-4-b で軸 G ADPCM 動的供給は「`adpcmb_keyon` 内 sample_table_id selection 時の sub-path」 (= `pmdneo_select_adpcmb_ppc_pointer`) であり、 独立 dispatch point ではない。 本 ADR-0055 では **軸 G 接続点を literal 記録のみ** とし (= Annex B literal reference)、 別 stub routine は新設しない。

- 軸 G ADR-0048 の **Draft 状態 + ε partial complete state + ζ 未着手 + ε partial state (= ppc_scratch 0xFD33-0xFD36 / audition_frame_counter 0xFD37-0xFD38)** は完全不変。
- 軸 G dynamic supply 本体 / 軸 G ζ は本 sprint 4 完全 scope 外 (= 後続 future)。

### 決定 4: marker SRAM 配置 = v2 driver_state 拡張 region

接続点到達 marker は ADR-0053 §決定 2 の v2 driver_state 拡張 region (= 0xFD39-0xFD78、 既配置 3 field + 0xFD3C-0xFD78 free 61 byte) に `pmdneo_v2_` prefix で β 配置する。 既配置 field (= `pmdneo_v2_fade_level` 0xFD39 / `pmdneo_v2_ssg_mixer` 0xFD3A / `pmdneo_v2_entry_marker` 0xFD3B) の placement は不変。 具体 address は β で確定。

### 決定 5: 接続点呼出 timing = v2 entry skeleton の fm3ext_dispatch 直後 additive

接続点 stub dispatch は `pmdneo_v2_entry_skeleton` の `call pmdneo_v2_fm3ext_dispatch` (= ADR-0054 δ-3) 直後に additive 追加する (= ADR-0052 γ/δ + ADR-0054 F-2-B と同じ additive pattern)。 既存 FM/SSG/F-2-B dispatch の順序は不変。

### 決定 6: verify gate (= register trace primary gate)

δ-4 は **register trace primary gate** で verify する。 γ sub-sprint で次を verify script (= 想定 `src/test-fixtures/axis-b/verify-axis-b-axis-connection.sh`) に体系化する。

| # | gate | 期待 |
|---|---|---|
| 1 | cmd 0x07 v2 path 到達維持 | `pmdneo_v2_entry_marker` (0xFD3B) ← 0x07 (= ADR-0052 v2 entry path が接続点追加後も維持) |
| 2 | ADPCM-B 接続点 marker proof | v2 main loop で ADPCM-B 接続点 stub の marker が write される (= dispatch boundary 到達) |
| 3 | rhythm 接続点 marker proof | v2 main loop で rhythm 接続点 stub の marker が write される (= dispatch boundary 到達) |
| 4 | 既存 v2 dispatch regression | 既存 FM 6ch keyon (reg 0x28) + SSG 3ch dispatch (reg 0x08-0x0A) + F-2-B (reg 0x27 bit 7 / ch3 op1-4 TL) が接続点追加後も維持 |
| 5 | baseline regression | ADR-0052 `verify-axis-b-v2-entry.sh` + ADR-0053 `verify-axis-b-sram-placement.sh` + ADR-0054 `verify-axis-b-f2b-integration.sh` (= mute/fade/SSG tone-enable + baseline を transitively) 全 PASS |
| 6 | 軸 C/G/rhythm 不可触 + `.org` overflow | 軸 C `adpcmb_keyon` / 軸 G `pmdneo_select_adpcmb_ppc_pointer` / rhythm `pmdneo_rhythm_event_trigger` 既存 routine 不変 (= call なし、 ADPCMB_DRV.inc / KR_STUB.inc 不変) + production build `.lst` で v2 並設 routine が `.org` 境界 overlap なし |

verify gate の最終件数は γ sub-sprint で確定する。 audio gate は δ-4 の完了判定に用いない (= 接続点 stub marker proof、 実音 dispatch は後続 future)。

### 決定 7: scope-in / scope-out / non-goal

#### scope-in (= sprint 4 で扱う)

- v2 main loop への軸 C ADPCM-B 接続点 stub (= `pmdneo_v2_adpcmb_dispatch`) + rhythm 接続点 stub (= `pmdneo_v2_rhythm_dispatch`) 並設追加
- 各接続点 stub の dispatch boundary 到達 marker proof
- 軸 G 接続点の literal 記録 (= ADPCM-B 接続点の sub-path)
- register trace primary gate の verify script 体系化

#### scope-out (= 別 ADR / 別 sprint / future)

- **軸 C ADPCM-B 実 dispatch** (= `adpcmb_keyon` call) / **ADPCM-B literal value decay** = 後続 future
- **軸 G ADPCM dynamic supply 本体** / **軸 G ζ** = ADR-0048 後続 (= Draft 状態不変)
- **rhythm 実 dispatch** (= `pmdneo_rhythm_event_trigger` call) / **実音 rhythm 動作** = 後続 future
- **PART_PCM・PART_RHYTHM の v2 per-part dispatch loop full 実装** = 後続 future
- **v2 driver の production-ready 化 + 既存 cmd 2 path からの switch** = 全 δ 完了後の future 判断 (= ADR-0045 §I-5-b)

#### non-goal (= 軸 B sprint 4 として目指さない)

- 軸 C ADR-0043 / 軸 G ADR-0048 / rhythm ADR-0026〜0031 / ADR-0049〜0054 の routine + SRAM field の modify
- 軸 G ADR-0048 の Draft 状態 + ε partial state の変更
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐の変更
- 「軸 B 完成」 の宣言 (= ADR-0055 Accepted = 軸 B 実装 sprint 4 完了。 軸 B 実装 sprint chain 全 sprint 完了でも「軸 B 完成」 表現は使用しない)

### 決定 8: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする。

- **軸 C ADR-0043**: `adpcmb_keyon` / `adpcmb_keyon_have_sample` / `adpcmb_keyoff` / `pmdneo_select_adpcmb_sample_pointer` / `adpcmb_select_*` / `adpcmb_sample_*` + voice index table + ADPCMB_DRV.inc 全部
- **軸 G ADR-0048**: `pmdneo_select_adpcmb_ppc_pointer` + ε partial state (= `ppc_scratch_start/stop_lsb/msb` 0xFD33-0xFD36 / `audition_frame_counter_lsb/msb` 0xFD37-0xFD38) + Draft 状態 + ζ 未着手 state
- **rhythm ADR-0026〜0031**: `pmdneo_rhythm_event_trigger` / `_rhythm_event_*_trigger` (= b/s/c/h/t/i) / `rhythm_main` + KR_STUB.inc + `pmdneo_mn_direct_load_k_part_addr`
- ADR-0052 v2 entry routine / ADR-0053 v2 SRAM region 境界定数 + 既配置 field / ADR-0054 F-2-B routine
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable の routine + SRAM field
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐

### 決定 9: doc-only filing 規律 (= 本 ADR-0055 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0055 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0055 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0055 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm / ADR-0049〜0054 完全不可触

### 決定 10: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 sprint 4 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model を継承する。 主軸の報告 / kickoff plan / commit GO / Accepted 移行判断は Codex layer 2 へ投入し、 approve なら主軸が commit + push + PR + merge + dashboard update まで自律完走、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終完走報告のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: δ-4 ground truth (= ADR-0045 §I-4 / §J-4-4 reference)

本 ADR-0055 の δ-4 設計 ground truth は ADR-0045 に literal 化済であり、 本 ADR は再調査せず reference する。 接続点の形 (= stub marker proof vs 直接呼出) は本 ADR §決定 2 が user 判断で確定する。

| ADR-0045 section | 内容 | 本 ADR との関係 |
|---|---|---|
| §Annex I-4-a | δ-4 = 軸 C/軸 G/rhythm 接続点保護 の 8 評価軸 | reference (= 目的 / 不可触対象 / verify gate 軸)。 「user 判断 = 接続点呼出 timing / 直接呼出 vs hook 並走」 は §決定 2 で stub marker proof 確定 |
| §Annex I-4-b | 軸 C/軸 G/rhythm 接続点呼出経路 literal | reference (= Annex B 接続点呼出経路 の ground truth) |
| §J-4-4 | 実装 sprint 4 bridging note = scope / ground truth / verify gate / 不可触対象 | reference (= scope / verify gate / 不可触対象 literal 継承) |

## Annex B: 軸 C/G/rhythm 接続点呼出経路 literal (= ADR-0045 §I-4-b reference)

δ-4 で v2 main loop に定義する接続点の呼出経路 (= ADR-0045 §I-4-b literal)。 本 sprint 4 では各接続点を **stub (= marker proof)** として実装し、 既存 entry routine は call しない (= §決定 2)。

| 軸 | 接続点 entry (= 既存、 完全不可触) | δ-4 接続点 stub | 後続 future |
|---|---|---|---|
| 軸 C ADPCM-B | `adpcmb_keyon` (= ADR-0043 entry) | `pmdneo_v2_adpcmb_dispatch` 並設 stub = ADPCM-B dispatch boundary 到達 marker | stub から `adpcmb_keyon` 実 call (= 実音 ADPCM-B dispatch) |
| 軸 G ADPCM 動的供給 | `pmdneo_select_adpcmb_ppc_pointer` (= ADR-0048 δ partial) | 別 stub なし = ADPCM-B 接続点の sub-path として literal 記録のみ (= §決定 3) | ADR-0048 後続 (= dynamic supply 本体 / ζ) |
| rhythm | `pmdneo_rhythm_event_trigger` (= ADR-0026〜0031 entry) | `pmdneo_v2_rhythm_dispatch` 並設 stub = rhythm dispatch boundary 到達 marker | stub から `pmdneo_rhythm_event_trigger` 実 call (= 実音 rhythm dispatch) |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) の main loop に、 ADPCM-B (= 軸 C) / 動的サンプル供給 (= 軸 G) / リズム (= rhythm) へ「渡す場所」 (= 接続点 = dispatch boundary) を作る。 = 「ここから ADPCM-B に渡す」「ここからリズムに渡す」 という境界を v2 main loop に定義する。

**前提**: 軸 B の実装は実装 1 (= v2 入口) / 実装 2 (= メモリ配置) / 実装 3 (= F-2-B) が完了済。 実装 4 = δ-4 が最後の sprint。 ただし δ-4 完了でも「軸 B 完成」 とは言わない (= sprint 4 完了として扱う)。

**今回の範囲 (= 接続点定義のみ)**: δ-4 は他軸を直接動かす sprint ではない。 v2 main loop に「接続点 (= スタブ)」 だけを追加する。 スタブは「v2 main loop がこの境界に到達した」 ことを SRAM のマーカー書き込みで証明する。 既存の ADPCM-B / リズムのルーチンは **呼び出さない** (= 実音の ADPCM-B / リズム再生は後続)。 軸 G は ADPCM-B 接続点の中の枝分かれなので別スタブは作らず、 文書に経路を記録するだけ。

**触らないもの**: 軸 C / 軸 G / リズムの既存ルーチン全部、 軸 G の Draft 状態、 ADR-0049〜0054。 全て不可触。

**今回やること (= α)**: 設計書 (= 本 ADR-0055) を起票するだけ。 ドライバのコードはまだ書かない。 接続点の形・配置・検証方法・不可触対象を文書で固定する。

**次**: 本 ADR-0055 を doc-only で commit / PR / merge した後、 β でドライバの v2 main loop に接続点スタブを追加し、 γ で検証スクリプトを整備、 δ で Draft → Accepted へ移行する。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0055 起票) | **進行中** (= 39th session、 本 PR) | (= 本 PR) | 起票 plan review approve (= 全決定/論点 2 件/規律/scope-out approve、 must-fix・escalate なし) + 起票 review |
| β (= 接続点 stub driver 実装) | 未着手 | - | - |
| γ (= verify script 体系化) | 未着手 | - | - |
| δ (= completion + Draft → Accepted 判断) | 未着手 | - | - |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-22 | Draft 起票 (= 39th session 軸 B 実装 sprint 4 α) | δ-4 v2 main loop 軸 C/G/rhythm 接続点定義の実装 ADR を起票。 軸 B 本線の実装 sprint 4 = 最終 sprint として δ-4 を選定 (= ADR-0045 §I-5-b sequential 順序、 δ-3 完了の次)。 決定 1-10 + 4 段 sub-sprint α/β/γ/δ + 接続点 = stub marker proof (= §I-4-a user 判断 gate 確定、 既存 軸 C/rhythm routine は call せず dispatch boundary を marker で proof、 実 dispatch は後続 future) + 軸 G 接続点 = ADPCM-B 接続点 sub-path として literal 記録のみ (別 stub なし、 ADR-0048 Draft + ε partial state 不変) + marker SRAM = ADR-0053 v2 driver_state region + 接続点呼出 timing = fm3ext_dispatch 直後 additive + verify gate 6 件。 doc-only filing (= ADR-0055 + dashboard のみ変更)。 ADR-0045 §J-4-4 literal 後続実装 ADR。 Codex layer 2 起票 plan review = approve (= 全決定/論点 2 件/規律 6 観点/scope-out approve、 must-fix・escalate なし)。 軸 B 実装 sprint chain の実装 4 = δ-4 が最終 sprint、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
