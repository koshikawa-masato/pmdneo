# ADR-0052: PMDNEO 軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry + dispatch trigger path

- 状態: **Draft** (= 2026-05-21 39th session 軸 B 実装 sprint 1 α、 ground truth = ADR-0045 Annex I-1 / §J-4-1、 ADR 起票 doc-only filing、 後続 β/γ/δ/ε で driver 実装 → verify → completion。 ADR-0045 §J-4-1 literal 後続実装 ADR。 **軸 B 実装 sprint chain の 実装 1 = δ-1 = v2 driver foundation**。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用。 §決定 3 は β kickoff plan 整理で発見した trigger path 想定誤り (= `cmd_jmptable` / cmd 0x06) を doc-correction PR で訂正済 = **cmd 0x07 + live `nmi_dispatch`**、 改訂履歴 + §決定 3 参照)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex I-1 で δ-1 設計を literal 化 + §J-4-1 で実装 sprint 1 bridging note 化、 本 ADR の母 ADR。 §I-1-b の `cmd_jmptable` / cmd 0x06 記述は legacy nullsound 経路想定であり本 ADR §決定 3 が override)
  - **ADR-0049** (= 軸 B 実装 sprint 5 mute semantics、 Accepted、 **本 ADR で完全不可触保護**、 sub-sprint 構成 / verify gate / doc-only filing 規律の precedent)
  - **ADR-0050** (= 軸 B 実装 sprint 6 fade-out semantics、 Accepted、 **本 ADR で完全不可触保護**。 NMI dispatch command 6 = `nmi_cmd_6_fade_start` を使用中、 cmd 0x06 は fade trigger 予約済)
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
  - `project_pmdneo_driver_two_paths_discovery.md` (= driver 二系統 = standalone_test.s 本線 / PMDNEO.s + nullsound 系 legacy、 §決定 3 trigger path 訂正の根拠)

## 背景 (= why now)

### 軸 B 実装 sprint 5/6/7 完了 base

39th session までに軸 B 実装 sprint 5 (= mute semantics、 ADR-0049 Accepted) / sprint 6 (= fade-out semantics、 ADR-0050 Accepted) / sprint 7 (= SSG tone-enable semantics、 ADR-0051 Accepted + V0 keyon literal trace gate follow-up 完了) が完了した。 これらは既存 driver (= Phase 1 PoC base、 NMI dispatch cmd 2 = `nmi_cmd_2_play_song` path) の semantics 拡張であり、 audition / regression の検証基盤 (= `verify-mute-semantics.sh` 7 gate / `verify-fadeout-semantics.sh` 16 gate / `verify-ssg-tone-enable.sh` 15 gate) を固めた。

軸 B 実装 sprint chain は ADR-0045 §J-4 の 6 候補 (= 実装 1-4 + mute + fade-out) + 後から追加の sprint 7 (= SSG tone-enable) で構成され、 38th session user 判断 priority 5→6→1→2→3→4 に従い sprint 5/6 完了、 sprint 7 追加完了。 残 = **実装 sprint 1-4 (= ADR-0045 Annex I の δ-1〜δ-4)**。

### δ-1 = v2 driver foundation (= δ-2/3/4 が依存)

ADR-0045 Annex I で軸 B Phase 2 fullscratch driver は 5 sub-axis に分解された (= δ-1 FM/SSG v2 entry + trigger path / δ-2 PartWork・SRAM placement / δ-3 F-2-B hook / δ-4 軸 C/G/rhythm 接続点 / δ-5 実装 sprint chain 計画)。 このうち **δ-1 = v2 driver の foundation** であり、 δ-2 (= v2 entry が使う PartWork placement) / δ-3 (= v2 FM dispatch を ch3 4-op へ拡張) / δ-4 (= v2 main loop へ軸 C/G/rhythm 接続点を配線) は全て δ-1 の v2 entry skeleton + v2 main loop に依存する。 ADR-0045 §I-5-b 順序提案も δ-1 → δ-2 → δ-3 → δ-4 sequential。 よって軸 B 本線の次着手 1 本 = δ-1 (= 39th session 4 sprint 比較 + Codex layer 2 review approve + user 判断 gate)。

### v2 entry / trigger path の不足

現 PMDNEO live driver (= `standalone_test.s`) には Phase 2 fullscratch driver の v2 entry が存在しない (= v2 song 再生 routine / v2 main loop 未実装、 39th session grep で確認)。 既存は Phase 1 PoC base の NMI dispatch cmd 2 path (= `nmi_cmd_2_play_song`) のみ。 ADR-0045 §I-1-b は v2 entry を「既存 cmd path と完全並走する新規 command 経由 trigger path」 として設計済。 本 sprint 1 で γ proof spike (= `scripts/axis-b-v2-entry-spike.py`、 1 part → 1 register write proof) を FM 6ch + SSG 3ch dispatcher へ拡張し、 v2 entry + trigger path を driver に実装する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0052 を doc-only filing として起票し、 後続 sub-sprint β/γ/δ/ε で trigger path → FM dispatcher → SSG dispatcher → verify → completion を段階的に進める。

## 決定

### 決定 1: 軸 B sprint 1 sub-sprint 構成 = 5 段 α/β/γ/δ/ε

δ-1 実装を **5 段階 α/β/γ/δ/ε** に分割する (= ADR-0049/0050 sprint 5/6 precedent 踏襲)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0052 起票 (= doc-only) + δ-1 scope / verify gate / 規律 literal 化 | 本 ADR-0052 起票 + dashboard sync、 driver / spike / verify script touch なし、 doc-only | なし |
| **β** | cmd 0x07 trigger path 実装 = live `nmi_dispatch` へ cmd 0x07 分岐 additive + `nmi_cmd_7_play_song_v2` 並設 routine + v2 entry skeleton 並設 routine | cmd 0x07 経由で v2 entry skeleton へ到達する register trace + 既存 NMI dispatch cmd path byte-identical | 最小限 (= cmd 0x07 分岐 additive + 並設 routine) |
| **γ** | FM 6ch v2 dispatcher 実装 | FM 6ch 各 ch fixture で register write 発生 + chip target flag 分岐 (YM2610 ch2/3/5/6 / YM2610B ch1-6) verify | 最小限 (= FM v2 dispatcher 並設) |
| **δ** | SSG 3ch v2 dispatcher 実装 | SSG 3ch 各 ch fixture で register write 発生 (= reg 0x00-0x0A) | 最小限 (= SSG v2 dispatcher 並設) |
| **ε** | verify script 体系化 + completion + ADR-0052 Draft → Accepted 判断 | 全 sub α/β/γ/δ verify gate PASS + verify script (= 想定 `verify-axis-b-v2-entry.sh`) + Accepted 移行判断 (= user 判断 gate) | verify script のみ (= driver touch なし) |

各 sub-sprint = 1 PR (= ADR-0049/0050 §決定 1 precedent = sprint = PR 1 対 1)。 ただし α は ADR-0052 起票 PR (= #74) + 本 cmd 0x07 doc-correction PR の **2 PR** となる (= doc-correction は β kickoff plan 整理 finding 由来の起票後前提訂正、 §決定 3 + 改訂履歴 参照)。 計 = α 2 PR + β/γ/δ/ε 各 1 PR = **6 PR**。 全 PR で軸 G / 軸 C / rhythm / 既存 NMI dispatch cmd path / 既存 hook framework 完全不可触 + baseline byte-identical 維持。 詳細 sub-sprint 境界は β 着手時に再確認する。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 軸 G を完成扱いしない
- ADR-0043 軸 C + ADR-0026〜0031 rhythm routine 完全不可触 (= 並設 only)
- ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable Accepted 状態を regression なしで保護 (= NMI dispatch cmd 6 = `nmi_cmd_6_fade_start` を含む既存 cmd 分岐は不可触)
- ADR-0044 Accepted + F-2-A defer 維持
- vendor wav 3 件 untracked retain (= commit 混入禁止)
- 「軸 B 完成」 表現禁止 (= 「ADR-0052 = 軸 B 実装 sprint 1 (= δ-1) 起票」 表記、 軸 B 実装完了ではない)
- α は β に先行する (= ADR-0052 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: δ-1 minimal scope = FM 6ch + SSG 3ch dispatcher のみ (= user 判断論点 1)

v2 main loop の scope は **FM 6ch + SSG 3ch sequential dispatcher のみ** に限定する (= 39th session user 判断 gate)。

- v2 main loop = part を sequential に dispatch し、 FM 6ch (= part B/C/E/F + A/D) と SSG 3ch (= part G/H/I) の register write を発生させる skeleton。 chip target flag に従い YM2610 では FM ch2/3/5/6 active + A/D (= ch1/4) silent、 YM2610B では FM ch1-6 active。
- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm の接続点 stub は δ-4 (= 実装 sprint 4) へ defer**。 本 sprint 1 の v2 main loop には接続点を含めない。
- δ-1 の v2 dispatcher が要する SRAM field は最小限とし、 0xFD39-0xFFBF free region に `pmdneo_v2_` prefix で β/γ/δ 実装時に最小配置する。 v2 PartWork / driver_state の正式な sub-region placement (= ADR-0045 §I-2-c の実 allocation) は δ-2 (= 実装 sprint 2) scope であり、 本 ADR では行わない。

### 決定 3: cmd trigger path = cmd 0x07 を live `nmi_dispatch` へ additive (= user 判断論点 2、 cmd_jmptable 想定の訂正)

v2 entry の trigger path は **live driver (`standalone_test.s`) の `nmi_dispatch` の空き NMI dispatch command 番号 cmd 0x07** とする。

#### 決定 3-a: `cmd_jmptable` / cmd 0x06 想定の訂正 (= ADR-0045 §I-1-b override、 39th session β kickoff plan 整理 finding)

ADR-0045 §I-1-b は v2 entry trigger path を「`IRQ.inc cmd_jmptable` 末尾へ cmd 0x06 entry additive」 と設計し、 本 ADR-0052 起票時 (= α、 PR #74) の §決定 3 もこれを継承していた。 β kickoff plan 整理で次の ground truth 不一致を発見した (= 39th session、 user escalate)。

- live driver = `standalone_test.s`。 その NMI handler (`.org 0x0066`) 内の `nmi_dispatch` が `in a,(0x00)` で NMI dispatch command byte を読み分岐する (= `standalone_test.s` L330 付近)。
- `standalone_test.s` は `IRQ.inc` を `.include` しない (= 39th session grep 確認、 include は `samples.inc` / `ppc_symbols.inc` / `song_data.inc` のみ)。 = **`IRQ.inc cmd_jmptable` は live build に不在**。 `IRQ.inc` + `PMDNEO.s` 系の nullsound integration 経路は legacy / 未完成 (= memory `project_pmdneo_driver_two_paths_discovery.md`)。
- live `nmi_dispatch` で **NMI dispatch command 6 (= cmd 0x06) は `nmi_cmd_6_fade_start` (= ADR-0050 fade-out 楽曲全体 fade trigger) が使用中**。

= ADR-0045 §I-1-b の「`cmd_jmptable` + cmd 0x06」 は legacy nullsound 経路を live と誤認した記述であり、 cmd 0x06 を v2 entry に使うと fade と衝突する。 本 §決定 3 で **live driver ground truth = `cmd 0x07` + `nmi_dispatch`** が ADR-0045 §I-1-b を override する (= ADR-0050 §決定 9 が ADR-0045 §J-4-6 文言を override した先例と同形式)。

#### 決定 3-b: cmd 0x07 trigger path 確定方針

- live `nmi_dispatch` (`standalone_test.s` NMI handler `.org 0x0066`) に **NMI dispatch command 0x07 の分岐 (= `cp #7` + `jp z, nmi_cmd_7_play_song_v2`) を additive 追加** する。 既存の cmd 分岐 (= cmd 2 play_song / cmd 5 adpcmb_beat / cmd 6 fade / cmd 9-23 select_song / cmd 24-40 mask / cmd 41-57 unmask) は完全不変。 cmd 0x07 は現状 `cp #9` / `jp c, nmi_done` で `nmi_done` (= no-op) へ落ちる空き番号。
- v2 song 再生開始 routine は `nmi_cmd_7_play_song_v2` (= 仮称) として `standalone_test.s` 内の新規並設 routine とする。 fade の `nmi_cmd_6_fade_start` と番号・名前を明確に分離 (= cmd 6 fade / cmd 7 v2 entry)。
- `IRQ.inc cmd_jmptable` は live build に不在のため **本 ADR-0052 の実装対象にしない**。 nullsound integration 経路の v2 対応は本 sprint 1 scope-out。
- NMI dispatch cmd 0x06 (= fade) / `nmi_cmd_6_fade_start` は完全不可触。 `nmi_dispatch` とは別の dispatch 機構を新設する案を採る場合は ADR-0045 §I-1-b/§I-5-b literal 主軸からの設計逸脱として user 判断 gate 化する。 本 ADR は live `nmi_dispatch` への cmd 0x07 分岐 additive を確定方針とする。

#### 決定 3-c: NMI dispatch command と `cmd_jmptable` の層の違い (= naming 整理)

| 層 | 実体 | live build か | cmd 0x06 / 0x07 |
|---|---|---|---|
| **NMI dispatch command** (= live) | `standalone_test.s` NMI handler (`.org 0x0066`) の `nmi_dispatch`、 `in a,(0x00)` で command byte 読取 | **live (= 本線)** | cmd 0x06 = `nmi_cmd_6_fade_start` (fade、 使用中) / cmd 0x07 = `nmi_cmd_7_play_song_v2` (= 本 ADR で additive、 空き) |
| `cmd_jmptable` (= legacy) | `IRQ.inc` の nullsound sound command table | **live build に不在** (= `standalone_test.s` 非 include) | 本 ADR の実装対象外 |

ADR-0052 β 以降で「cmd 0x07」 と記す場合は **live NMI dispatch command 0x07** を指す。 nullsound `cmd_jmptable` の slot 番号とは別層であり混同しない。

### 決定 4: spike 方針 = 既存 `axis-b-v2-entry-spike.py` 拡張 (= user 判断論点 3)

v2 entry の register trace proof は既存 γ proof spike `scripts/axis-b-v2-entry-spike.py` (= 1 part → 1 register write proof) を **拡張** する (= FM 6ch + SSG 3ch fixture 追加、 既存 γ proof との trace 継続性を維持)。 別 spike file の新設は、 拡張で対応できない必要性が出た場合のみ β/γ/δ 着手時に user 判断 gate で判断する。

### 決定 5: routine 境界 = 並設 only + 既存 NMI dispatch cmd path byte-identical 保護 (= user 判断論点 4)

δ-1 で新規追加する driver routine を次の 3 種に限定し、 いずれも **並設 (= 既存 routine を改変せず新規追加)** とする。

| 新規並設 routine | 内容 |
|---|---|
| `nmi_cmd_7_play_song_v2` | NMI dispatch command 0x07 分岐から到達する v2 song 再生開始 routine |
| v2 entry skeleton | v2 main loop の初期化 + part dispatch loop の骨格 |
| FM / SSG v2 dispatcher | FM 6ch / SSG 3ch の per-part register write dispatcher |

`nmi_dispatch` 自体への変更は **cmd 0x07 分岐 (= `cp #7` + `jp z, nmi_cmd_7_play_song_v2`) の additive 追加のみ** に限定する。 既存 cmd 分岐 (= cmd 2/5/6/9-23/24-57) は完全不変。

**保護対象 (= byte-identical / trace 等価)**: 既存 NMI dispatch cmd path 全部 (= cmd 2 `nmi_cmd_2_play_song` / cmd 5 `nmi_cmd_5_adpcmb_beat` / **cmd 6 `nmi_cmd_6_fade_start`** / cmd 9-23 `nmi_cmd_select_song` / cmd 24-57 mask/unmask)、 既存 hook framework (= `fm_*_hook` / `psg_*_hook`)、 既存 ADR-extended routine (= `fnumset_fm` / `fnumset_ssg` 等)、 ADR-0049/0050/0051 で追加した mute / fade / SSG tone-enable routine。 これらは並設 routine から本体直接 call する場合を除き完全不変。

並設 routine は `.org` 制約のないセクション末尾に配置する (= memory `feedback_org_section_overflow_silent_bug.md` = `.org` セクション overflow silent bug 回避)。 `nmi_dispatch` への cmd 0x07 分岐 additive は `.org 0x0066` NMI セクション内であり、 同セクションの `.lst` overflow を β で必ず verify する。 詳細配置と `.lst` overflow verify は β/γ/δ 各実装時に行う。

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
| 1 | cmd 0x07 trigger path | NMI dispatch command 0x07 経由で `nmi_cmd_7_play_song_v2` → v2 entry skeleton へ到達する register/PC trace |
| 2 | 既存 cmd path byte-identical | 既存 NMI dispatch cmd path (= cmd 2 play_song / cmd 5 adpcmb / **cmd 6 fade** / select_song / mask/unmask) の register trace が base と byte-identical (= cmd 0x07 分岐 additive が既存経路を破壊しない) |
| 3 | FM 6ch v2 dispatch | FM 6ch 各 ch fixture で v2 dispatcher が FM register write を発生 |
| 4 | SSG 3ch v2 dispatch | SSG 3ch 各 ch fixture で v2 dispatcher が reg 0x00-0x0A register write を発生 |
| 5 | chip target flag 分岐 | YM2610 (= FM ch2/3/5/6 active + A/D silent) / YM2610B (= FM ch1-6 active) の分岐が register trace で観測可能 |
| 6 | `.org` overflow / section overlap | production build `.lst` で `nmi_dispatch` の cmd 0x07 分岐 additive 後も `.org 0x0066` セクションが overflow せず + v2 並設 routine が `.org` 境界と overlap なし |
| 7 | baseline regression | ADR-0049/0050/0051 verify script (= mute 7 / fade-out 16 / SSG tone-enable 15 gate) + baseline 9 script 全 PASS |

verify gate の最終件数 / fixture 詳細は ε sub-sprint で確定する。 audio gate は本 sprint 1 の完了判定には用いない (= 決定 8 scope-out。 v2 path で実音が出る段階の audition 要否は ε で判断)。

### 決定 8: scope-in / scope-out / non-goal

#### scope-in (= sprint 1 で扱う)

- cmd 0x07 v2 entry trigger path (= live `nmi_dispatch` への cmd 0x07 分岐 additive + `nmi_cmd_7_play_song_v2` + v2 entry skeleton)
- FM 6ch + SSG 3ch sequential dispatcher (= v2 main loop の最小骨格)
- chip target flag (YM2610 / YM2610B) 分岐
- γ proof spike (`axis-b-v2-entry-spike.py`) の FM 6ch + SSG 3ch 拡張
- register trace primary gate の verify script 体系化

#### scope-out (= 別 ADR / 別 sprint / future)

- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm 接続点** = δ-4 (= 実装 sprint 4)
- **v2 PartWork / driver_state の正式 sub-region placement** (= ADR-0045 §I-2-c 実 allocation) = δ-2 (= 実装 sprint 2)
- **F-2-B (= ch3 4-op individual mode) integration** = δ-3 (= 実装 sprint 3)
- **`IRQ.inc cmd_jmptable` (= nullsound 経路) の v2 対応** = legacy path であり live build 不在、 本 sprint 1 では扱わない
- **v2 driver の production-ready 化 + 既存 cmd 2 path からの switch** = 全 δ 完了後の future 判断 (= ADR-0045 §I-5-b、 production-ready までは Phase 1 PoC base 並走)
- MML compiler 経路 / .mn 生成側の変更 = 軸 F scope
- audio gate 主導の完了判定 (= 決定 7、 register trace primary)

#### non-goal (= 軸 B sprint 1 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 / ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable routine の modify (= 完全不可触、 並設 only or 本体直接 call only)
- IRQ flow / TIMER-B 設定 / `pmd_main` / `pmdneo_play_loop` / 既存 NMI dispatch cmd 分岐 (= cmd 2/5/6/9-23/24-57) の変更
- FM attack click (= ADR-0051 Annex C-5) / ADPCM-B literal value decay (= ADR-0050 Annex I-3) = 後続候補保持、 本 sprint で触らない

### 決定 9: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする (= ADR-0045 §I-1-b/§J-4-1/§J-4-7 literal 継承)。

- **IRQ flow / TIMER-B 設定 / `pmd_main` / `pmdneo_play_loop` / `state_timer_tick_reached` / `pmd_z80_main`**
- **既存 NMI dispatch cmd 分岐** (= `nmi_dispatch` の cmd 2 `nmi_cmd_2_play_song` / cmd 5 `nmi_cmd_5_adpcmb_beat` / cmd 6 `nmi_cmd_6_fade_start` / cmd 9-23 `nmi_cmd_select_song` / cmd 24-40 mask / cmd 41-57 unmask)。 `nmi_dispatch` への変更は cmd 0x07 分岐 additive のみ
- 既存 hook framework (= `fm_*_hook` / `psg_*_hook` / `adpcmb_*_hook` 等)
- 既存 ADR-extended routine (= `fnumset_fm` / `fnumset_ssg` 等)
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable で追加した routine + SRAM field (= Accepted 状態保護、 regression なし)
- 軸 G ADR-0048 routine 全部 + 軸 G SRAM scratch (= 0xFD33-0xFD38、 Draft + ε partial complete + ζ 未着手 完全不可触)
- 軸 C ADR-0043 ADPCM-B routine 全部 + rhythm ADR-0026〜0031 routine 全部
- ADR-0044 Accepted + F-2-A defer 維持 (= vendor compiler 不可触)

### 決定 10: doc-only filing 規律 (= 本 ADR-0052 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0052 起票 + 本 doc-correction) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0052 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0052 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / ADR-0049/0050/0051 完全不可触

### 決定 11: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

本 sprint 1 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化を継承する。 主軸の user 確認質問 (= driver / 実装 / 配置 / 即時 GO 判定 / ADR 大型更新) は user 確認の前に Codex layer 2 投入を default 化、 approve なら主軸自律進行、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終確認 (= PR merge / Accepted 移行判断 / 決定 3 別 dispatch 機構新設の設計逸脱判断) のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0052 起票 + cmd 0x07 doc-correction) | **完了** (= 39th session) | 起票 PR #74 + doc-correction PR | 次着手 sprint 比較 review approve (= δ-1) + ADR-0052 起票 plan review approve (= must-fix 0) + ADR-0052 起票 review approve + cmd 0x07 doc-correction review |
| β (= cmd 0x07 trigger path 実装) | 未着手 | - | - |
| γ (= FM 6ch v2 dispatcher 実装) | 未着手 | - | - |
| δ (= SSG 3ch v2 dispatcher 実装) | 未着手 | - | - |
| ε (= verify script 体系化 + completion + Accepted 判断) | 未着手 | - | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: PMDNEO の Phase 2 フルスクラッチ音源ドライバ (= 新しく作り直す本命ドライバ) の「入口」 を作る。 具体的には、 新しい再生命令 (= NMI dispatch command 7) を 1 つ足し、 そこから FM 6 チャンネルと SSG 3 チャンネルを順に処理する骨格 (= v2 main loop) を作る。

**前提**: 軸 B の実装 sprint は 7 本中 3 本 (= mute / fade-out / SSG tone-enable) が完了済。 残りは実装 1-4。 そのうち実装 1 = δ-1 が「入口」 にあたり、 残り 3 本 (= placement / F-2-B / 接続点) は全てこの入口の上に乗るため、 最初に作る必要がある。

**今回やること**: 設計書 (= 本 ADR-0052) を起票するだけ。 ドライバのコードはまだ書かない。 入口の範囲・命令の足し方・既存ドライバを壊さない保護・検証方法を文書で固定する。

**命令番号の訂正**: 起票時 (α 第 1 版) は新命令を「cmd 0x06」 として設計したが、 cmd 0x06 は既に fade-out (楽曲全体の消音) で使われていた。 また「cmd_jmptable」 という別の命令表は今の実機ドライバでは使われていない (= 旧 nullsound 経路)。 そこで命令番号を **cmd 0x07** に直し、 今の実機ドライバの命令分岐 (`nmi_dispatch`) に足す、 と本 doc-correction で訂正した。

**範囲の限定**: 入口は「FM 6ch + SSG 3ch を順に処理する骨格」 だけに絞る。 ADPCM-B / 軸 G / リズムへの接続は後の実装 4 に回す。 既存の命令分岐は 1 bit も変えず、 新しい cmd 0x07 を 1 分岐だけ足す。

**次**: 本 doc-correction を含む ADR-0052 を doc-only で commit / PR / merge した後、 β sub-sprint で cmd 0x07 の trigger path を実装する。

## Annex A: δ-1 ground truth (= ADR-0045 §I-1 / §J-4-1 reference)

本 ADR-0052 の δ-1 設計 ground truth は ADR-0045 に literal 化済であり、 本 ADR は再調査せず reference する。 ただし trigger path の command 番号 / dispatch 機構は本 ADR §決定 3 が override する (= 下表注記参照)。

| ADR-0045 section | 内容 | 本 ADR との関係 |
|---|---|---|
| §Annex I-1 | δ-1 = FM/SSG v2 entry integration + v2 dispatch trigger path の 8 評価軸 + I-1-c SSG fixture 対応表 | reference (= scope / verify gate 軸) |
| §Annex I-1-b | trigger path 設計。 「`cmd_jmptable` 末尾 cmd 0x06 entry additive」 と記述 | **§決定 3 が override** = `cmd_jmptable` は legacy nullsound 経路想定であり live build 不在、 cmd 0x06 は fade 使用中。 live ground truth = cmd 0x07 + `nmi_dispatch` |
| §Annex I-5-b | 実装 sprint chain 計画 = δ-1 → δ-2 → δ-3 → δ-4 順序提案 + trigger path 追加規律 + verify gate strategy | reference (= 順序 / verify gate strategy)。 trigger path の command 番号は §決定 3 override |
| §J-4-1 | 実装 sprint 1 bridging note = scope (cmd 0x06 additive + 並設 routine) / ground truth (Annex I-1) / verify gate / 不可触対象 | scope / verify gate / 不可触対象は reference。 command 番号 (cmd 0x06) は §決定 3 override = cmd 0x07 |
| §J-4-7 | 実装 sprint 起票時の共通規律 (= Codex rescue 化 / 軸 G・軸 C・rhythm 不可触 / baseline byte-identical / register trace primary gate / 「軸 B 完成」 表現不使用) | reference (= 共通規律 literal 継承) |

## Annex B: cmd 0x07 v2 entry trigger path 設計

ADR-0045 §I-1-b を §決定 3 で override した live driver ground truth に基づく cmd 0x07 trigger path の literal 設計。

| 観点 | 内容 |
|---|---|
| trigger 経路 | NMI dispatch command 0x07 → live `nmi_dispatch` (`standalone_test.s` NMI handler `.org 0x0066`) の cmd 0x07 分岐 (= additive) → `nmi_cmd_7_play_song_v2` 並設 routine → v2 entry skeleton → v2 main loop (= FM 6ch + SSG 3ch dispatcher) |
| `nmi_dispatch` 追加方式 | `nmi_dispatch` 内に cmd 0x07 分岐 (= `cp #7` + `jp z, nmi_cmd_7_play_song_v2`) を additive 追加。 既存 cmd 分岐 (= cmd 2/5/6/9-23/24-57) の判定順序・jump target は完全不変。 cmd 0x07 は現状 `cp #9` / `jp c, nmi_done` で no-op へ落ちる空き番号 |
| cmd 0x06 (= fade) との関係 | NMI dispatch command 6 = `nmi_cmd_6_fade_start` (= ADR-0050 楽曲全体 fade-out trigger) は完全不可触。 cmd 0x06 と cmd 0x07 は同じ `nmi_dispatch` の別 command 番号であり、 fade と v2 entry は別 routine |
| 既存 cmd 2 path との関係 | 完全並走。 cmd 2 (= `nmi_cmd_2_play_song` = Phase 1 PoC base) は production-ready までそのまま並走し、 v2 driver は cmd 0x07 経由でのみ起動。 switch 時期は全 δ 完了後の future 判断 |
| 並設 routine 配置 | `standalone_test.s` 内の `.org` 制約のないセクション末尾 (= ADR-0049/0050/0051 並設 routine 配置 pattern 踏襲)。 配置と `.lst` overflow verify は β/γ/δ で実施 |
| `cmd_jmptable` (= legacy) | `IRQ.inc cmd_jmptable` は nullsound integration 経路で live `standalone_test.s` build に不在 (= 非 `.include`)。 本 ADR の実装対象外 |
| verify | cmd 0x07 経由で v2 entry skeleton へ到達する register/PC trace (= gate 1) + 既存 NMI dispatch cmd path register trace の base byte-identical (= gate 2) |

## Annex C: verify gate 詳細 + regression risk

### C-1: regression risk = 中 (= driver touch 前提)

ADR-0045 §I-1 の「regression risk = 低」 は **δ 設計段 (= doc-only / spike 前提) の評価値** である。 本 ADR-0052 = 実装 sprint は driver (= `standalone_test.s`) を touch するため、 **regression risk = 中** に読み替える (= Codex layer 2 比較 review 指摘)。 中と評価する根拠 = (1) `nmi_dispatch` への cmd 0x07 分岐 additive が既存 cmd 分岐 (= cmd 2/5/6/9-23/24-57) を破壊しないこと、 (2) cmd 0x07 分岐 additive 後も `.org 0x0066` NMI セクションが overflow しないこと + 並設 routine の `.org` 配置が既存セクションと overlap しないこと (= `feedback_org_section_overflow_silent_bug.md` class)、 (3) 既存 NMI dispatch cmd path の byte-identical 維持、 の 3 点が verify gate で機械的に担保される必要がある。

### C-2: baseline 保護

ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable は Accepted 済であり、 本 sprint 1 はこれらに regression を出さない。 verify gate 7 (= baseline regression) で `verify-mute-semantics.sh` 7 gate + `verify-fadeout-semantics.sh` 16 gate + `verify-ssg-tone-enable.sh` 15 gate + baseline 9 script の全 PASS を確認する。 fade (= cmd 0x06 `nmi_cmd_6_fade_start`) は cmd 0x07 分岐の additive 追加で経路が変わらないことを verify gate 2 (= 既存 cmd path byte-identical) で機械的に担保する。

### C-3: 後続 sub-sprint の user 判断 gate 候補

| sub | user 判断 gate 候補 |
|---|---|
| β | 並設 routine の `.org` セクション配置先 / `nmi_dispatch` 内 cmd 0x07 分岐の挿入位置 (= 既存判定順序を崩さない位置) |
| γ | FM v2 dispatcher の register write 順序 / chip target flag 分岐の実装方式 |
| δ | SSG v2 dispatcher の reg 0x00-0x0A write 順序 / `pmdneo_v2_` SRAM field 最小配置 |
| ε | verify gate 最終件数 / audio gate 要否 (= v2 path 実音段階) / Draft → Accepted 移行判断 |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-21 | Draft 起票 (= 39th session 軸 B 実装 sprint 1 α) | δ-1 FM/SSG v2 entry + dispatch trigger path の実装 ADR を起票。 軸 B 本線復帰の次着手 1 本として δ-1 を選定 (= 39th session 実装 sprint 1-4 比較 + Codex layer 2 review approve + user 判断 gate)。 決定 1-11 + 5 段 sub-sprint α/β/γ/δ/ε + verify gate 7 件 + δ-1 minimal scope (= FM 6ch + SSG 3ch dispatcher のみ、 接続点は δ-4 defer) + 既存 cmd path byte-identical 保護 + chip target flag 分岐。 doc-only filing (= ADR-0052 + dashboard のみ変更)。 ADR-0045 §J-4-1 literal 後続実装 ADR。 軸 B 実装 sprint chain は実装 1 = δ-1 が v2 driver foundation、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
| 2026-05-21 | cmd 0x07 doc-correction (= 39th session、 β kickoff plan 整理 finding、 user escalate → 確定) | β kickoff plan 整理で trigger path 想定誤りを発見。 ADR-0045 §I-1-b + ADR-0052 起票第 1 版 §決定 3 の「`IRQ.inc cmd_jmptable` へ cmd 0x06 additive」 は (1) `cmd_jmptable` が live `standalone_test.s` build に不在 (= legacy nullsound 経路)、 (2) NMI dispatch command 6 = `nmi_cmd_6_fade_start` が ADR-0050 fade で使用中、 の 2 点で live driver ground truth と不一致。 §決定 3 を **cmd 0x07 + live `nmi_dispatch`** へ訂正 (= 決定 3-a override 明示 + 3-b 確定方針 + 3-c 層の違い整理)。 trigger routine 名 = `nmi_cmd_7_play_song_v2`。 ADR 全体 (= 決定 1/5/7/8/9 + Annex A/B/C + 平易要約 + 状態行) を cmd 0x07 + `nmi_dispatch` 前提へ整合。 doc-only (= ADR-0052 + dashboard、 driver 不変)。 Codex layer 2 doc-correction review 経由。 β 実装は本 doc-correction PR merge 後に着手 |
