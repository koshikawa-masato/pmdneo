# ADR-0052: PMDNEO 軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry + dispatch trigger path

- 状態: **Draft** (= 2026-05-21 39th session 軸 B 実装 sprint 1 α、 ground truth = ADR-0045 Annex I-1 / §J-4-1、 ADR 起票 doc-only filing、 後続 β/γ/δ/ε で driver 実装 → verify → completion。 ADR-0045 §J-4-1 literal 後続実装 ADR。 **軸 B 実装 sprint chain の 実装 1 = δ-1 = v2 driver foundation**。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex I-1 で δ-1 設計を literal 化 + §J-4-1 で実装 sprint 1 bridging note 化、 本 ADR の母 ADR)
  - **ADR-0049** (= 軸 B 実装 sprint 5 mute semantics、 Accepted、 **本 ADR で完全不可触保護**、 sub-sprint 構成 / verify gate / doc-only filing 規律の precedent)
  - **ADR-0050** (= 軸 B 実装 sprint 6 fade-out semantics、 Accepted、 **本 ADR で完全不可触保護**)
  - **ADR-0051** (= 軸 B 実装 sprint 7 SSG tone-enable semantics、 Accepted + V0 keyon literal trace gate follow-up 完了、 **本 ADR で完全不可触保護**)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**、 軸 G を完成扱いしない)
  - ADR-0043 (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触**、 production-ready 保護)
  - ADR-0044 (= 軸 F MML compiler 拡張、 Accepted、 F-2-A defer 維持。 F-2-B 譲渡軸 integration は δ-3 scope = 本 ADR scope-out)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 verify gate 基盤)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 並設 routine 配置規律基盤)

## 背景 (= why now)

### 軸 B 実装 sprint 5/6/7 完了 base

39th session までに軸 B 実装 sprint 5 (= mute semantics、 ADR-0049 Accepted) / sprint 6 (= fade-out semantics、 ADR-0050 Accepted) / sprint 7 (= SSG tone-enable semantics、 ADR-0051 Accepted + V0 keyon literal trace gate follow-up 完了) が完了した。 これらは既存 driver (= Phase 1 PoC base、 cmd 0x02 path) の semantics 拡張であり、 audition / regression の検証基盤 (= `verify-mute-semantics.sh` 7 gate / `verify-fadeout-semantics.sh` 16 gate / `verify-ssg-tone-enable.sh` 15 gate) を固めた。

軸 B 実装 sprint chain は ADR-0045 §J-4 の 6 候補 (= 実装 1-4 + mute + fade-out) + 後から追加の sprint 7 (= SSG tone-enable) で構成され、 38th session user 判断 priority 5→6→1→2→3→4 に従い sprint 5/6 完了、 sprint 7 追加完了。 残 = **実装 sprint 1-4 (= ADR-0045 Annex I の δ-1〜δ-4)**。

### δ-1 = v2 driver foundation (= δ-2/3/4 が依存)

ADR-0045 Annex I で軸 B Phase 2 fullscratch driver は 5 sub-axis に分解された (= δ-1 FM/SSG v2 entry + trigger path / δ-2 PartWork・SRAM placement / δ-3 F-2-B hook / δ-4 軸 C/G/rhythm 接続点 / δ-5 実装 sprint chain 計画)。 このうち **δ-1 = v2 driver の foundation** であり、 δ-2 (= v2 entry が使う PartWork placement) / δ-3 (= v2 FM dispatch を ch3 4-op へ拡張) / δ-4 (= v2 main loop へ軸 C/G/rhythm 接続点を配線) は全て δ-1 の v2 entry skeleton + v2 main loop に依存する。 ADR-0045 §I-5-b 順序提案も δ-1 → δ-2 → δ-3 → δ-4 sequential。 よって軸 B 本線の次着手 1 本 = δ-1 (= 39th session 4 sprint 比較 + Codex layer 2 review approve + user 判断 gate)。

### v2 entry / cmd 0x06 trigger path の不足

現 PMDNEO driver (= `standalone_test.s`) には Phase 2 fullscratch driver の v2 entry が存在しない (= cmd 0x06 / `snd_command_06_play_song_v2` / v2 main loop 未実装、 39th session grep で確認)。 既存は Phase 1 PoC base の cmd 0x02 path (= `play_song`) のみ。 ADR-0045 §I-1-b は v2 entry を「既存 cmd 0x02 path と完全並走する新規 cmd 0x06 経由 trigger path」 として設計済。 本 sprint 1 で γ proof spike (= `scripts/axis-b-v2-entry-spike.py`、 1 part → 1 register write proof) を FM 6ch + SSG 3ch dispatcher へ拡張し、 v2 entry + cmd 0x06 trigger path を driver に実装する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0052 を doc-only filing として起票し、 後続 sub-sprint β/γ/δ/ε で trigger path → FM dispatcher → SSG dispatcher → verify → completion を段階的に進める。

## 決定

### 決定 1: 軸 B sprint 1 sub-sprint 構成 = 5 段 α/β/γ/δ/ε

δ-1 実装を **5 段階 α/β/γ/δ/ε** に分割する (= ADR-0049/0050 sprint 5/6 precedent 踏襲)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0052 起票 (= doc-only) + δ-1 scope / verify gate / 規律 literal 化 | 本 ADR-0052 起票 + dashboard sync、 driver / spike / verify script touch なし、 doc-only | なし |
| **β** | cmd 0x06 trigger path 実装 = `IRQ.inc cmd_jmptable` 末尾 padding へ cmd 0x06 entry 1 行 additive + `snd_command_06_play_song_v2` 並設 routine + v2 entry skeleton 並設 routine | cmd 0x06 経由で v2 entry skeleton へ到達する register trace + 既存 cmd 0x02 path byte-identical | 最小限 (= cmd 0x06 entry additive + 並設 routine) |
| **γ** | FM 6ch v2 dispatcher 実装 | FM 6ch 各 ch fixture で register write 発生 + chip target flag 分岐 (YM2610 ch2/3/5/6 / YM2610B ch1-6) verify | 最小限 (= FM v2 dispatcher 並設) |
| **δ** | SSG 3ch v2 dispatcher 実装 | SSG 3ch 各 ch fixture で register write 発生 (= reg 0x00-0x0A) | 最小限 (= SSG v2 dispatcher 並設) |
| **ε** | verify script 体系化 + completion + ADR-0052 Draft → Accepted 判断 | 全 sub α/β/γ/δ verify gate PASS + verify script (= 想定 `verify-axis-b-v2-entry.sh`) + Accepted 移行判断 (= user 判断 gate) | verify script のみ (= driver touch なし) |

各 sub-sprint = 1 PR (= ADR-0049/0050 §決定 1 precedent = sprint = PR 1 対 1)。 計 5 PR。 全 PR で軸 G / 軸 C / rhythm / 既存 cmd 0x02 path / 既存 hook framework 完全不可触 + baseline byte-identical 維持。 詳細 sub-sprint 境界は β 着手時に再確認する。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 軸 G を完成扱いしない
- ADR-0043 軸 C + ADR-0026〜0031 rhythm routine 完全不可触 (= 並設 only)
- ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable Accepted 状態を regression なしで保護
- ADR-0044 Accepted + F-2-A defer 維持
- vendor wav 3 件 untracked retain (= commit 混入禁止)
- 「軸 B 完成」 表現禁止 (= 「ADR-0052 = 軸 B 実装 sprint 1 (= δ-1) 起票」 表記、 軸 B 実装完了ではない)
- α は β に先行する (= ADR-0052 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: δ-1 minimal scope = FM 6ch + SSG 3ch dispatcher のみ (= user 判断論点 1)

v2 main loop の scope は **FM 6ch + SSG 3ch sequential dispatcher のみ** に限定する (= 39th session user 判断 gate)。

- v2 main loop = part を sequential に dispatch し、 FM 6ch (= part B/C/E/F + A/D) と SSG 3ch (= part G/H/I) の register write を発生させる skeleton。 chip target flag に従い YM2610 では FM ch2/3/5/6 active + A/D (= ch1/4) silent、 YM2610B では FM ch1-6 active。
- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm の接続点 stub は δ-4 (= 実装 sprint 4) へ defer**。 本 sprint 1 の v2 main loop には接続点を含めない。
- δ-1 の v2 dispatcher が要する SRAM field は最小限とし、 0xFD39-0xFFBF free region に `pmdneo_v2_` prefix で β/γ/δ 実装時に最小配置する。 v2 PartWork / driver_state の正式な sub-region placement (= ADR-0045 §I-2-c の実 allocation) は δ-2 (= 実装 sprint 2) scope であり、 本 ADR では行わない。

### 決定 3: cmd trigger path = cmd 0x06 を `cmd_jmptable` 末尾へ additive 追加 (= user 判断論点 2)

v2 entry の trigger path は **新規 cmd 0x06 経由** とする (= ADR-0045 §I-1-b literal、 user 判断 gate)。

- `IRQ.inc cmd_jmptable` (= sound command dispatch table) の **末尾 padding 領域へ cmd 0x06 entry を 1 行 additive 追加** する。 既存 cmd 0x00-0x05 entry は完全不変 (= 配列末尾への並設追加扱い)。
- `snd_command_06_play_song_v2` routine 自体は `standalone_test.s` 内の新規並設 routine として配置 (= 既存 routine 不可触)。
- **別 dispatch table 分岐 (= cmd_jmptable とは別の dispatch 機構) を採る場合は ADR-0045 §I-1-b/§I-5-b literal 主軸からの設計逸脱として user 判断 gate 化**する。 本 ADR は cmd_jmptable 末尾 additive を確定方針とする。

### 決定 4: spike 方針 = 既存 `axis-b-v2-entry-spike.py` 拡張 (= user 判断論点 3)

v2 entry の register trace proof は既存 γ proof spike `scripts/axis-b-v2-entry-spike.py` (= 1 part → 1 register write proof) を **拡張** する (= FM 6ch + SSG 3ch fixture 追加、 既存 γ proof との trace 継続性を維持)。 別 spike file の新設は、 拡張で対応できない必要性が出た場合のみ β/γ/δ 着手時に user 判断 gate で判断する。

### 決定 5: routine 境界 = 並設 only + 既存 cmd 0x02 path byte-identical 保護 (= user 判断論点 4)

δ-1 で新規追加する driver routine を次の 3 種に限定し、 いずれも **並設 (= 既存 routine を改変せず新規追加)** とする。

| 新規並設 routine | 内容 |
|---|---|
| `snd_command_06_play_song_v2` | cmd 0x06 entry から到達する v2 song 再生開始 routine |
| v2 entry skeleton | v2 main loop の初期化 + part dispatch loop の骨格 |
| FM / SSG v2 dispatcher | FM 6ch / SSG 3ch の per-part register write dispatcher |

**保護対象 (= byte-identical / trace 等価)**: 既存 cmd 0x02 path (= `play_song`)、 既存 hook framework (= `fm_*_hook` / `psg_*_hook`)、 既存 ADR-extended routine (= `fnumset_fm` / `fnumset_ssg` 等)、 ADR-0049/0050/0051 で追加した mute / fade / SSG tone-enable routine。 これらは並設 routine から本体直接 call する場合を除き完全不変。

並設 routine は `.org` 制約のないセクション末尾に配置する (= memory `feedback_org_section_overflow_silent_bug.md` = `.org` セクション overflow silent bug 回避)。 詳細配置と `.lst` overflow verify は β/γ/δ 各実装時に行う。

### 決定 6: chip target flag gate = YM2610 / YM2610B 分岐 (= user 判断論点 5)

v2 dispatcher は chip target flag (= ADR-0006 §4 の `PMDNEO_CHIP` build-time flag) に従い 2 系統を分岐する。 verify gate は **ADR-0052 初回 (= γ FM dispatcher) から両系統を含める**。

| chip target | FM ch | A/D (= ch1/4) |
|---|---|---|
| YM2610 (= 無印、 default) | ch2/3/5/6 active | silent (= YM2610 は FM 4ch、 ADR-0010) |
| YM2610B | ch1-6 active | active (= YM2610B は FM 6ch) |

### 決定 7: verify gate (= register trace primary gate)

δ-1 は **register trace primary gate** で verify する (= memory `feedback_refactor_gate_register_trace_not_wav.md`)。 ε sub-sprint で次を verify script (= 想定 `src/test-fixtures/axis-b/verify-axis-b-v2-entry.sh`) に体系化する。

| # | gate | 期待 |
|---|---|---|
| 1 | cmd 0x06 trigger path | cmd 0x06 経由で `snd_command_06_play_song_v2` → v2 entry skeleton へ到達する register/PC trace |
| 2 | cmd 0x02 path byte-identical | 既存 cmd 0x02 path (= `play_song`) の register trace が base と byte-identical (= cmd 0x06 additive が既存経路を破壊しない) |
| 3 | FM 6ch v2 dispatch | FM 6ch 各 ch fixture で v2 dispatcher が FM register write を発生 |
| 4 | SSG 3ch v2 dispatch | SSG 3ch 各 ch fixture で v2 dispatcher が reg 0x00-0x0A register write を発生 |
| 5 | chip target flag 分岐 | YM2610 (= FM ch2/3/5/6 active + A/D silent) / YM2610B (= FM ch1-6 active) の分岐が register trace で観測可能 |
| 6 | `.org` overflow / section overlap | production build `.lst` で v2 並設 routine が `.org` 境界と overlap なし |
| 7 | baseline regression | ADR-0049/0050/0051 verify script (= mute 7 / fade-out 16 / SSG tone-enable 15 gate) + baseline 9 script 全 PASS |

verify gate の最終件数 / fixture 詳細は ε sub-sprint で確定する。 audio gate は本 sprint 1 の完了判定には用いない (= 決定 8 scope-out。 v2 path で実音が出る段階の audition 要否は ε で判断)。

### 決定 8: scope-in / scope-out / non-goal

#### scope-in (= sprint 1 で扱う)

- cmd 0x06 v2 entry trigger path (= `cmd_jmptable` 末尾 additive + `snd_command_06_play_song_v2` + v2 entry skeleton)
- FM 6ch + SSG 3ch sequential dispatcher (= v2 main loop の最小骨格)
- chip target flag (YM2610 / YM2610B) 分岐
- γ proof spike (`axis-b-v2-entry-spike.py`) の FM 6ch + SSG 3ch 拡張
- register trace primary gate の verify script 体系化

#### scope-out (= 別 ADR / 別 sprint / future)

- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm 接続点** = δ-4 (= 実装 sprint 4)
- **v2 PartWork / driver_state の正式 sub-region placement** (= ADR-0045 §I-2-c 実 allocation) = δ-2 (= 実装 sprint 2)
- **F-2-B (= ch3 4-op individual mode) integration** = δ-3 (= 実装 sprint 3)
- **v2 driver の production-ready 化 + 既存 cmd 0x02 path からの switch** = 全 δ 完了後の future 判断 (= ADR-0045 §I-5-b、 production-ready までは Phase 1 PoC base 並走)
- MML compiler 経路 / .mn 生成側の変更 = 軸 F scope
- audio gate 主導の完了判定 (= 決定 7、 register trace primary)

#### non-goal (= 軸 B sprint 1 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 / ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable routine の modify (= 完全不可触、 並設 only or 本体直接 call only)
- IRQ flow / TIMER-B 設定 / `pmd_main` / `pmdneo_play_loop` / 既存 cmd 0x00-0x05 entry の変更
- FM attack click (= ADR-0051 Annex C-5) / ADPCM-B literal value decay (= ADR-0050 Annex I-3) = 後続候補保持、 本 sprint で触らない

### 決定 9: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする (= ADR-0045 §I-1-b/§J-4-1/§J-4-7 literal 継承)。

- **IRQ flow / TIMER-B 設定 / `pmd_main` / `pmdneo_play_loop` / `state_timer_tick_reached` / `pmd_z80_main` / 既存 cmd 0x00-0x05 entry**
- 既存 hook framework (= `fm_*_hook` / `psg_*_hook` / `adpcmb_*_hook` 等)
- 既存 ADR-extended routine (= `fnumset_fm` / `fnumset_ssg` 等)
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable で追加した routine + SRAM field (= Accepted 状態保護、 regression なし)
- 軸 G ADR-0048 routine 全部 + 軸 G SRAM scratch (= 0xFD33-0xFD38、 Draft + ε partial complete + ζ 未着手 完全不可触)
- 軸 C ADR-0043 ADPCM-B routine 全部 + rhythm ADR-0026〜0031 routine 全部
- ADR-0044 Accepted + F-2-A defer 維持 (= vendor compiler 不可触)

### 決定 10: doc-only filing 規律 (= 本 ADR-0052 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0052 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0052 (= 新規) + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0052 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / ADR-0049/0050/0051 完全不可触

### 決定 11: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

本 sprint 1 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化を継承する。 主軸の user 確認質問 (= driver / 実装 / 配置 / 即時 GO 判定 / ADR 大型更新) は user 確認の前に Codex layer 2 投入を default 化、 approve なら主軸自律進行、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終確認 (= PR merge / Accepted 移行判断 / 決定 3 別 dispatch table 分岐の設計逸脱判断) のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0052 起票) | **完了** (= 39th session) | 本 PR | 次着手 sprint 比較 review approve (= δ-1) + ADR-0052 起票 plan review approve (= must-fix 0) + ADR-0052 起票 review (= 本 PR) |
| β (= cmd 0x06 trigger path 実装) | 未着手 | - | - |
| γ (= FM 6ch v2 dispatcher 実装) | 未着手 | - | - |
| δ (= SSG 3ch v2 dispatcher 実装) | 未着手 | - | - |
| ε (= verify script 体系化 + completion + Accepted 判断) | 未着手 | - | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: PMDNEO の Phase 2 フルスクラッチ音源ドライバ (= 新しく作り直す本命ドライバ) の「入口」 を作る。 具体的には、 新しい再生命令 (= cmd 0x06) を 1 つ足し、 そこから FM 6 チャンネルと SSG 3 チャンネルを順に処理する骨格 (= v2 main loop) を作る。

**前提**: 軸 B の実装 sprint は 7 本中 3 本 (= mute / fade-out / SSG tone-enable) が完了済。 残りは実装 1-4。 そのうち実装 1 = δ-1 が「入口」 にあたり、 残り 3 本 (= placement / F-2-B / 接続点) は全てこの入口の上に乗るため、 最初に作る必要がある。

**今回やること**: 設計書 (= 本 ADR-0052) を起票するだけ。 ドライバのコードはまだ書かない。 入口の範囲・命令の足し方・既存ドライバを壊さない保護・検証方法を文書で固定する。

**範囲の限定**: 入口は「FM 6ch + SSG 3ch を順に処理する骨格」 だけに絞る。 ADPCM-B / 軸 G / リズムへの接続は後の実装 4 に回す。 既存の再生命令 cmd 0x02 の経路は 1 bit も変えず、 新しい cmd 0x06 を末尾に並べて足すだけにする。

**次**: 本 ADR-0052 を doc-only で commit / PR / merge した後、 β sub-sprint で cmd 0x06 の trigger path を実装する。

## Annex A: δ-1 ground truth (= ADR-0045 §I-1 / §J-4-1 reference)

本 ADR-0052 の δ-1 設計 ground truth は ADR-0045 に literal 化済であり、 本 ADR は再調査せず reference する。

| ADR-0045 section | 内容 |
|---|---|
| §Annex I-1 | δ-1 = FM/SSG v2 entry integration + v2 dispatch trigger path の 8 評価軸 + I-1-b trigger path 設計 (= cmd 0x06 additive) + I-1-c SSG fixture 対応表 |
| §Annex I-1-b | IRQ flow 不可触範囲 + `cmd_jmptable` 末尾 cmd 0x06 entry 1 行 additive 許容 + 新規 cmd 経由 (= 既存 hook framework / cmd 0x02 path 完全並走) |
| §Annex I-5-b | 実装 sprint chain 計画 = δ-1 → δ-2 → δ-3 → δ-4 順序提案 + trigger path 追加規律 + verify gate strategy |
| §J-4-1 | 実装 sprint 1 bridging note = scope (cmd 0x06 additive + 並設 routine) / ground truth (Annex I-1) / verify gate (register trace + cmd 0x02 byte-identical) / 不可触対象 |
| §J-4-7 | 実装 sprint 起票時の共通規律 (= Codex rescue 化 / 軸 G・軸 C・rhythm 不可触 / baseline byte-identical / register trace primary gate / 「軸 B 完成」 表現不使用) |

## Annex B: cmd 0x06 v2 entry trigger path 設計

ADR-0045 §I-1-b に基づく cmd 0x06 trigger path の literal 設計。

| 観点 | 内容 |
|---|---|
| trigger 経路 | sound command cmd 0x06 → `IRQ.inc cmd_jmptable` の cmd 0x06 entry (= 末尾 additive) → `snd_command_06_play_song_v2` 並設 routine → v2 entry skeleton → v2 main loop (= FM 6ch + SSG 3ch dispatcher) |
| `cmd_jmptable` 追加方式 | 末尾 padding 領域へ cmd 0x06 entry を 1 行 additive 追加 (= 既存 cmd 0x00-0x05 entry 改変なし)。 cmd 0x00-0x05 の jump target は完全不変 |
| 既存 cmd 0x02 path との関係 | 完全並走。 cmd 0x02 (= `play_song` = Phase 1 PoC base) は production-ready までそのまま並走し、 v2 driver は cmd 0x06 経由でのみ起動。 switch 時期は全 δ 完了後の future 判断 |
| 並設 routine 配置 | `standalone_test.s` 内の `.org` 制約のないセクション末尾 (= ADR-0049/0050/0051 並設 routine 配置 pattern 踏襲)。 配置と `.lst` overflow verify は β/γ/δ で実施 |
| verify | cmd 0x06 経由で v2 entry skeleton へ到達する register/PC trace (= gate 1) + 既存 cmd 0x02 path register trace の base byte-identical (= gate 2) |

## Annex C: verify gate 詳細 + regression risk

### C-1: regression risk = 中 (= driver touch 前提)

ADR-0045 §I-1 の「regression risk = 低」 は **δ 設計段 (= doc-only / spike 前提) の評価値** である。 本 ADR-0052 = 実装 sprint は driver (= `standalone_test.s` / `IRQ.inc`) を touch するため、 **regression risk = 中** に読み替える (= Codex layer 2 比較 review 指摘)。 中と評価する根拠 = (1) `cmd_jmptable` への additive 追加が既存 cmd 0x00-0x05 entry を破壊しないこと、 (2) 並設 routine の `.org` 配置が既存セクションと overlap しないこと (= `feedback_org_section_overflow_silent_bug.md` class)、 (3) 既存 cmd 0x02 path の byte-identical 維持、 の 3 点が verify gate で機械的に担保される必要がある。

### C-2: baseline 保護

ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable は Accepted 済であり、 本 sprint 1 はこれらに regression を出さない。 verify gate 7 (= baseline regression) で `verify-mute-semantics.sh` 7 gate + `verify-fadeout-semantics.sh` 16 gate + `verify-ssg-tone-enable.sh` 15 gate + baseline 9 script の全 PASS を確認する。

### C-3: 後続 sub-sprint の user 判断 gate 候補

| sub | user 判断 gate 候補 |
|---|---|
| β | 並設 routine の `.org` セクション配置先 / cmd 0x06 entry の `cmd_jmptable` 末尾 padding 位置 |
| γ | FM v2 dispatcher の register write 順序 / chip target flag 分岐の実装方式 |
| δ | SSG v2 dispatcher の reg 0x00-0x0A write 順序 / `pmdneo_v2_` SRAM field 最小配置 |
| ε | verify gate 最終件数 / audio gate 要否 (= v2 path 実音段階) / Draft → Accepted 移行判断 |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-21 | Draft 起票 (= 39th session 軸 B 実装 sprint 1 α) | δ-1 FM/SSG v2 entry + dispatch trigger path の実装 ADR を起票。 軸 B 本線復帰の次着手 1 本として δ-1 を選定 (= 39th session 実装 sprint 1-4 比較 + Codex layer 2 review approve + user 判断 gate)。 決定 1-11 + 5 段 sub-sprint α/β/γ/δ/ε + verify gate 7 件 + δ-1 minimal scope (= FM 6ch + SSG 3ch dispatcher のみ、 接続点は δ-4 defer) + cmd 0x06 cmd_jmptable 末尾 additive + 既存 cmd 0x02 path byte-identical 保護 + chip target flag 分岐。 doc-only filing (= ADR-0052 + dashboard のみ変更)。 ADR-0045 §J-4-1 literal 後続実装 ADR。 軸 B 実装 sprint chain は実装 1 = δ-1 が v2 driver foundation、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
