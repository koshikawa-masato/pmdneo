# FM/SSG 軸並走 ADR 起票 — Codex 壁打ち用 talking points

- 起票: 2026-05-18 26th session、 ADR-0035 Draft 起票後の派生整理
- 起票者: 越川将人 (M.Koshikawa)
- 用途: FM/SSG 軸を ADPCM-A 軸 (= Step 5-18 系) と同時並行で進める方針が user 判断で確定 (= 26th session、 memory `project_fm_ssg_adpcma_parallel_axis_decision`)。 本 file は user が Codex と壁打ちして並走 ADR を起票する際の入力資料。
- 状態: 壁打ち前 talking points、 ADR 番号未確定 (= ADR-0035 が Draft、 0036 取得可否は壁打ち後 user 判断)

## 1. 背景 (= Codex 共有用 minimal context)

PMDNEO は CLAUDE.md §開発フェーズで Phase 1-4 構造を持つが、 ADR-0013 (= 2026-05-11) で「フルスクラッチ Z80 driver 路線凍結 → PMDDotNET 改造路線」 に切替済。 ADR-0016 §決定 6 は「step 5 完了 = Phase 2 完了」 と定義したが、 実態として Step 5-18 で進行している軸は ADPCM-A / `.PNE` / K/R rhythm 軸であり、 FM/SSG 軸の Step 単位 native dispatch proof は未着手。

26th session で並行して IR 軸 (= ADR-0034 / ADR-0035) が進行中。 IR 軸は driver / runtime 不変、 docs + script + fixture 範囲。 ADR-0035 が完走すれば IR layer で FM ChipEvent → YM2610 register write 列が literal 化される。

user 判断 (= 26th session、 本 talking points 起票直前): **FM/SSG 軸を後回しにせず ADPCM-A 軸と同時並行で進める。 並走 ADR は Codex 壁打ちで決める。 並走可能性は source / branch / verify infra 触接面の独立性が前提**。

## 2. 既存制約 (= 議論不要、 前提として固定)

| 制約 | 出典 |
|---|---|
| 本線 driver = `src/driver/standalone_test.s` (= nullsound-free PoC) | ADR-0014 / memory `project_pmdneo_driver_two_paths_discovery` |
| legacy = `PMDNEO.s` 系 nullsound integration 未完成、 触らない | 同上 |
| branch 戦略 = `wip-` branch、 main 直接 push 禁止 | memory `feedback_branch_strategy` |
| 1 commit = 1 push、 まとめ push 禁止 | memory `feedback_push_per_commit` |
| driver / runtime layer touch commit は MAME 動作確認 + audio gate 義務 | CLAUDE.md §動作確認義務 |
| verify 2 系統分離 = A 系統 runtime/audio + B 系統 asset pipeline byte-identical | memory `project_pmdneo_verify_two_subsystems` |
| primary gate = ymfm register trace、 wav sha256 は secondary | memory `feedback_refactor_gate_register_trace_not_wav` |
| audio gate は対象 part solo 化必須 (= 同居 audio confusion 回避) | memory `feedback_audio_gate_solo_isolation` |
| Codex 実装の Claude Code 側 review 義務 (= 5 段 zero-trust verify) | CLAUDE.md §Codex 実装の Claude Code 側 review 義務 |
| AI協働用 ADR が判断 ground truth、 人間向け公開 docs は派生物 | CLAUDE.md §ドキュメント統治 + memory `feedback_doc_governance_two_systems` |
| 平易日本語報告 (= やりたいこと / 前提 / やったこと / 結果 / 解釈 / 次 の 6 構造) | memory `feedback_explain_in_plain_japanese_before_commit` |
| commit 後決め書式報告 (= branch / 改修 file+行 / GitHub URL) | memory `feedback_post_commit_push_report_format` |

## 3. 開く論点 (= Codex 壁打ちで判断する軸)

### 論点 1: source 触接面の独立性 verify

ADPCM-A 軸が `standalone_test.s` 本線で動作している。 FM/SSG 軸を同 file に追加すると触接面が共存する。 並走可能性の核心論点。

選択肢:

- **A. 同一 file 内独立 routine 分離**: ADR-0016 §決定 4 「段階的 file 境界」 path、 K/R rhythm trigger と同 pattern。 触接面は同 file だが routine 単位独立。 commit / merge 衝突 risk は同 file edit で発生し得る。
- **B. 独立 inc file 化**: `FM_DRV.inc` / `SSG_DRV.inc` 別 file 化、 register 触接面物理分離。 ただし `standalone_test.s` 本線への include 統合が必要、 既存 ADPCM-A 軸 commit chain との同居方針 ADR 化必要。
- **C. 別 branch 並行 + 完了時 merge**: 触接面物理分離、 ただし両軸 sprint 完了同期 / merge conflict / verify infra 二重実行 cost 等の運用 risk。 1 commit / 1 push 規律と branch 戦略の組合せ判断が必要。

判断要素: ADPCM-A 軸 sprint がどこまで継続するか (= ADR-0033 sample provenance 進行中) + FM/SSG 軸 sprint 想定期間 + Claude Code セッション分業 (= 別 session が FM/SSG 軸を担当する場合の独立性).

### 論点 2: FM/SSG 軸 Step 1 の最小 proof scope

ADPCM-A 軸 Step 5 = native dispatch path に相当する FM 側の最小 proof は何か。

選択肢例:

- FM ch1 単音 KeyOn + Tone load + FMFrequency の register write trace 観測
- 6 ch 全部の dispatch path proof
- 単一 ch only proof
- part letter 選定 (= `M-Q` は ADPCM-A、 K/R は rhythm 占有、 残 `A-J` のどれを FM proof part にするか)
- IR 軸 ADR-0035 で chip → raw lowering 出力 = 期待 register trace fixture として再利用

判断要素: ADR-0035 完走後の IR spike 出力が driver Step の expected fixture source になる可能性 + Step 単位粒度の前例 (= Step 12-17 drum 種 1 軸 / Step pattern).

### 論点 3: PMDDotNET Z80 化遺産との関係

ADR-0017 で「develop branch に Phase 2 SubF-1.1 まで進行済」 が記録されているが、 本線 `standalone_test.s` には統合されていない疑い。

選択肢:

- **A. 遺産無視 + 本線で新規 FM/SSG 実装**: Step 5-18 pattern と整合。 ADR-0019 step 5 設計判断 1 「既存 adpcma_* 実装 = retain + refactor」 と異なり、 FM/SSG は本線新規実装。
- **B. 遺産を本線へ portion 移植**: 規模見積もり必要、 100-150 行〜の if 分岐 / wrapper 流儀 (= ADR-0014 PMDPPZ 流儀発見).
- **C. 遺産を別 file で活用 + 本線から call**: 二系統的 path、 W-3 driver 二系統発見と同 pattern を意図的継続、 統合 cost 後で発生。

判断要素: develop branch の現状確認 + standalone_test.s 本線への include 状況 + ADR-0017 §軸 5 改造規模見積もり re-evaluation の必要性.

### 論点 4: Step 単位粒度

ADPCM-A 軸の Step 12-17 = drum 種 1 軸 / Step pattern が確立済。 FM/SSG 軸でも同 pattern 適用候補。

Step 候補 enumeration:

- FM KeyOn / Tone load / Frequency / Volume / Pan / LFO / Detune / Algorithm / Feedback / Operator parameter
- FM3Mode (= 4 operator 個別 frequency 制御 chip mode)
- SSG (= channel 3 つ、 envelope、 noise、 tone)
- 軸間順序 (= FM 先 / SSG 先 / 同時)
- 1 Step 1 機能 / 大粒度 Step / どの軸を最初に置くか

判断要素: ADPCM-A 軸 Step 5-18 の literal 完成度 (= 18 step 14 ヶ月相当の進行ペース) + 並走 sprint で時間軸が伸びる場合の cost.

### 論点 5: 並走時の commit chain / branch 戦略

現在進行中の branch:

- IR 軸 = `wip-ir-raw-register-lowering` (= ADR-0035 Draft)
- ADPCM-A 軸 = `wip-rhythm-sample-provenance` 系 (= ADR-0033 進行中、 sub-sprint α 完了 milestone memory)

FM/SSG 軸の branch 選択肢:

- **A. 完全独立 branch**: 例 `wip-fm-ssg-step1-keyon`、 main 起点並行。 ADPCM-A / IR 軸と物理分離。 merge order 判断必要。
- **B. ADPCM-A 軸と stack**: 既存 `wip-rhythm-sample-provenance` 系を base、 FM/SSG 軸 commit を上に重ねる。 ADPCM-A 軸完了時に同時 merge 想定。
- **C. main 起点並行 wip- branch + ADPCM-A 軸完了時 rebase**: 並行進行中は独立、 最終 integration 時 rebase or merge。

ADR-0014 § branch 戦略の再評価が必要。

判断要素: 三軸並走 (= ADPCM-A + IR + FM/SSG) の branch 数 limit、 user 認知負荷、 review cost.

### 論点 6: 検証 infra の共存

ymfm register trace は両軸同時 capture 可能 (= chip 単位 trace、 軸関係なく出力)。 ただし:

- audio gate solo isolation 規律: FM 軸 verify 時に ADPCM-A 同居 audio を mute する fixture 必要 → `silent-jkpq` / `silent-lq` 等の muting fixture 設計が論点
- verify script 並列実行禁止規律: branch 並走時に CI / 手動 verify でどう守るか
- 期待 register trace fixture: IR 軸 ADR-0035 完走後の spike 出力を fixture 化する hook 設計

判断要素: silent-bcef fixture (= ADR-0020 step 6) の FM 側変形 / IR spike output と driver expected の自動比較 framework 必要性.

### 論点 7: IR 軸との接続点

ADR-0035 が完走すると IR Chip → Raw lowering 成立、 FM ChipEvent register 仕様が literal 化される。

選択肢:

- **A. IR 軸完了待ち + FM/SSG 軸着手**: ADR-0035 Accepted 後に FM/SSG 軸が IR spike 出力を fixture として活用
- **B. 並行進行 + 後で結合**: IR 軸 ADR-0035 と FM/SSG 軸 ADR を同時進行、 完了後に接続点 ADR 起票
- **C. 完全独立 + 接続なし**: FM/SSG 軸 driver は独自 fixture、 IR 軸とは別軸 verify (= 三軸独立)

判断要素: IR spike 出力が driver expected fixture として使える形式かの確認 + 結合 cost vs 独立 cost.

## 4. 閉じる論点 (= 既存判断に従う、 議論不要)

- branch 命名: `wip-<topic>` (= memory `feedback_branch_strategy`)
- commit pacing: 1 commit / 1 push / 平易日本語報告 + 決め書式報告
- verify primary gate: ymfm register trace + audio gate secondary
- doc governance: AI 協働用 ADR を ground truth、 人間向け公開 docs は派生、 既存 ADR / handoff 不可触
- Codex 実装時の Claude Code 側 review 義務: 5 段 zero-trust verify (= session log 読み + git diff + 設計書整合 + report + user 判断)

## 5. Annex — 接続 ADR table

| ADR | 関連性 |
|---|---|
| ADR-0013 | PMDDotNET 改造路線切替、 Phase 2 = フルスクラッチ廃止の根拠 |
| ADR-0014 | path A 採択 + branch 戦略、 並走 branch 設計の base |
| ADR-0015 | PMDDotNET 改造 技術調査 5 軸、 driver 規模見積もり source |
| ADR-0016 | 5 step sprint plan、 step 5 完了で Phase 2 完了定義 |
| ADR-0017 | develop driver snapshot、 Phase 2 SubF-1.1 進行済記録 |
| ADR-0019 | step 5 設計判断 6 議題、 retain + refactor pattern |
| ADR-0020 | step 6 audio isolation 戦略、 silent fixture pattern |
| ADR-0021-0033 | Step 7-18 + sample provenance、 driver 軸進行履歴 |
| ADR-0034 | IR design 6 軸 ratify、 IR layer の compiler / WebApp intermediate 位置づけ |
| ADR-0035 | IR Chip → Raw lowering Draft 起票中、 FM register 仕様 literal 化軸 |

## 6. Codex 壁打ち時の進め方提案

CLAUDE.md §開発の進め方 (= 壁打ち) に従い:

1. **論点 1 から順に 1 軸ずつ**: 各論点 user 回答 → Codex 整理 → ADR §決定 N に literal 化
2. **新 ADR 番号確定は壁打ち完了時**: 並走 ADR が 0036 になるか 0037 になるかは Draft 起票時に決める (= ADR-0035 Draft / Accepted の進行と相対依存)
3. **ADR 起票後 commit / push 段階で Claude Code 側へ復帰**: Codex session log 読み + git diff + review report の 5 段 zero-trust verify (= CLAUDE.md §Codex 実装の Claude Code 側 review 義務)
4. **本 file は壁打ち中に追記更新可能**: user / Codex で論点新規追加 / scope 変更 / 既存制約再評価 等を本 file へ反映、 ADR §決定への昇格は user 判断

## 7. 関連 memory

- `project_fm_ssg_adpcma_parallel_axis_decision` — 並走方針 user 判断 (= 26th session)
- `project_pmdneo_driver_two_paths_discovery` — standalone_test.s 本線 / PMDNEO.s legacy
- `project_adr_0013_0014_path_switch` — フルスクラッチ凍結 + 改造路線切替
- `project_pmdneo_verify_two_subsystems` — A 系統 runtime / B 系統 asset pipeline
- `project_adr_0016_step5_design_decision_1_retain_refactor` — retain + refactor pattern
- `feedback_branch_strategy` — wip- branch 規律
- `feedback_codex_implementation_review` (CLAUDE.md §Codex 実装の Claude Code 側 review 義務 と等価) — 5 段 zero-trust verify
- `feedback_doc_governance_two_systems` — AI 協働用 ADR vs 人間向け公開 docs 分離
