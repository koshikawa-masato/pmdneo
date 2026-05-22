# ADR-0053: PMDNEO 軸 B 実装 sprint 2 = δ-2 PartWork / driver_state SRAM placement

- 状態: **Draft** (= 2026-05-21 39th session 軸 B 実装 sprint 2 α、 ground truth = ADR-0045 Annex I-2 / §J-4-2、 ADR 起票 doc-only filing、 後続 β/γ で driver region 定数実装 → verify → completion。 ADR-0045 §J-4-2 literal 後続実装 ADR。 **軸 B 実装 sprint chain の 実装 2 = δ-2 = v2 SRAM sub-region foundation** (= δ-3 F-2-B / δ-4 軸 C/G/rhythm 接続点 が依存)。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex I-2 で δ-2 設計を literal 化 + §J-4-2 で実装 sprint 2 bridging note 化、 本 ADR の母 ADR)
  - **ADR-0052** (= 軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry、 Accepted、 §決定 2 で「v2 PartWork / driver_state の正式 sub-region placement は δ-2 scope」 と literal defer。 **本 ADR で完全不可触保護**、 v2 entry field + routine)
  - **ADR-0049** (= 軸 B 実装 sprint 5 mute semantics、 Accepted、 **本 ADR で完全不可触保護**)
  - **ADR-0050** (= 軸 B 実装 sprint 6 fade-out semantics、 Accepted、 **本 ADR で完全不可触保護**。 `pmdneo_v2_fade_level` (0xFD39) を使用中)
  - **ADR-0051** (= 軸 B 実装 sprint 7 SSG tone-enable semantics、 Accepted、 **本 ADR で完全不可触保護**。 `pmdneo_v2_ssg_mixer` (0xFD3A) を使用中)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**。 軸 G scratch 0xFD33-0xFD38 を使用中)
  - ADR-0043 (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触**)
  - ADR-0006 / ADR-0021 / ADR-0022 / ADR-0023 (= 既存 SRAM layout 0xF820-0xFD32 の owner ADR、 **完全不可触**)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化 + 39th session 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 SRAM 配置とは別軸だが配置 verify の基盤規律)

## 背景 (= why now)

### 軸 B 実装 sprint 1 (= δ-1) 完了 base

39th session までに軸 B 実装 sprint 1 = δ-1 FM/SSG v2 entry (= ADR-0052 Accepted、 PR #74-#79) が完了した。 v2 driver の entry trigger path (= cmd 0x07 + `nmi_dispatch`) + FM 6ch / SSG 3ch v2 dispatcher の foundation が driver に成立した。 軸 B 実装 sprint chain は ADR-0045 §J-4 の 6 候補 (= 実装 1-4 + mute + fade-out) + 後から追加の sprint 7 (= SSG tone-enable) で構成され、 sprint 5/6/7 完了 + sprint 1 (= δ-1) 完了。 残 = 実装 sprint 2-4 (= δ-2/δ-3/δ-4)。

### δ-2 = v2 SRAM sub-region foundation (= δ-3/δ-4 が依存)

ADR-0045 §I-5-b の実装 sprint 順序提案は δ-1 → δ-2 → δ-3 → δ-4 sequential。 δ-2 = v2 driver state の SRAM 配置 foundation であり、 δ-3 (= F-2-B integration が要する v2 state field) / δ-4 (= 軸 C/G/rhythm 接続点が要する v2 state field) は全て δ-2 で確定する SRAM sub-region map に依存する。 ADR-0052 §決定 2 も「v2 PartWork / driver_state の正式 sub-region placement (= ADR-0045 §I-2-c の実 allocation) は δ-2 scope」 と literal defer 済。 よって軸 B 本線の次着手 1 本 = δ-2 (= 39th session user GO + Codex layer 2 起票 plan review approve)。

### v2 SRAM sub-region map の不在 + 仮表と実 placement の不一致

ADR-0045 §I-2-c は 0xFD39-0xFFBF (= 647 byte free region) の sub-region を **仮表** (= PartWork 拡張 256 byte / driver_state 拡張 64 byte / reserved 327 byte) として記述し、 「仮、 実 allocation は実装 sprint で確定」 と明記した。 その後 sprint 6/7/1 が free region 先頭 0xFD39-0xFD3B に v2 state field を incremental 配置した (= `pmdneo_v2_fade_level` 0xFD39 / `pmdneo_v2_ssg_mixer` 0xFD3A / `pmdneo_v2_entry_marker` 0xFD3B)。 この 3 field は全て per-driver singleton (= driver_state class、 per-part PartWork ではない) であり、 §I-2-c 仮表が「0xFD39-0xFE38 = PartWork 拡張」 と earmark した範囲と分類不一致になっている。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0053 を doc-only filing として起票し、 §I-2-c 仮表を実 placement と整合させた **v2 SRAM sub-region 正式 map** を literal 化する。 後続 sub-sprint β/γ で driver の region 境界定数実装 → verify → completion を進める。

## 決定

### 決定 1: 軸 B sprint 2 sub-sprint 構成 = 3 段 α/β/γ

δ-2 実装を **3 段階 α/β/γ** に分割する (= Codex layer 2 起票 plan review 判定 = δ-2 の driver 改修は SRAM region 境界定数 + comment block 整備程度で小さく、 ADR-0052 の 5 段 = 機能段階分割は不要)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0053 起票 (= doc-only) + δ-2 scope / SRAM sub-region 正式 map / verify gate / 規律 literal 化 | 本 ADR-0053 起票 + dashboard sync、 driver / verify script touch なし、 doc-only | なし |
| **β** | driver に v2 SRAM region 境界定数 (= `.equ`) 追加 + SRAM layout comment block 整備 | region 境界 `.equ` 3 件 additive + comment block が正式 map 反映 + production build PASS + binary byte-identical (= unused `.equ` は byte 非emit) | 最小限 (= `.equ` additive + comment) |
| **γ** | verify script 体系化 + completion + ADR-0053 Draft → Accepted 判断 | verify gate 全 PASS + verify script + Accepted 移行 (= Codex layer 2 approve 経由、 完全自走 model) | verify script のみ (= driver touch なし) |

各 sub-sprint = 1 PR (= ADR-0052 §決定 1 precedent)。 計 = α/β/γ 各 1 PR = **3 PR**。 全 PR で軸 G / 軸 C / rhythm / 既存 SRAM layout (= 0xF820-0xFD38) / ADR-0049/0050/0051/0052 完全不可触。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = SRAM placement の非重複 + 命名規約の機械的 verify (= ADR 内整合性確認 + driver `.lst` / source 静的確認)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model)
- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 完全不可触
- ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable / ADR-0052 v2 entry の routine + SRAM field 完全不可触 (= 既配置 3 field の placement は不変)
- 既存 SRAM layout 0xF820-0xFD38 (= ADR-0006/0021/0022/0023/0048) 完全不可触 + byte-identical
- 「軸 B 完成」 表現禁止 (= 「ADR-0053 = 軸 B 実装 sprint 2 (= δ-2)」 表記、 軸 B 実装完了ではない)
- α は β に先行する (= ADR-0053 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: v2 SRAM sub-region 正式 map = 案 A (= driver_state region 先頭)

0xFD39-0xFFBF (= 647 byte free region) の v2 sub-region map を **案 A = driver_state 拡張 region を free region 先頭 (0xFD39 起点) に置き、 PartWork 拡張 region をその後に置く** で確定する。

| range | size | sub-region | 命名 anchor (= β で実装) |
|---|---|---|---|
| `0xFD39-0xFD78` | 64 byte | **軸 B v2 driver_state 拡張 region** (= per-driver singleton field) | `pmdneo_v2_driver_state_base` = 0xFD39 |
| `0xFD79-0xFE78` | 256 byte | **軸 B v2 PartWork 拡張 region** (= per-part work field、 必要時) | `pmdneo_v2_partwork_base` = 0xFD79 |
| `0xFE79-0xFFBF` | 327 byte | **reserved** (= 余裕、 後続軸 拡張用) | `pmdneo_v2_reserved_base` = 0xFE79 |
| **合計** | **647 byte** | (= 0xFD39-0xFFBF free region 全体) | |

非重複 + 合計上限 verify: 64 + 256 + 327 = 647 byte ✓ (= free region 完全充足)。 size 配分 (= 64 / 256 / 327) は ADR-0045 §I-2-c 仮表の配分を維持し、 region の順序のみ driver_state 先頭へ変更した。

**案 A 採用根拠**: §I-2-c 仮表は driver_state 拡張を free region 後方 (0xFE39-0xFE78) に置いたが、 sprint 6/7/1 が実際に配置した 3 field (= `pmdneo_v2_fade_level` 0xFD39 / `pmdneo_v2_ssg_mixer` 0xFD3A / `pmdneo_v2_entry_marker` 0xFD3B) は全て per-driver singleton = driver_state class であり、 free region 先頭 0xFD39 から置かれている。 案 A は driver_state region を 0xFD39 起点とすることで既配置 3 field を移動せず正式 region に収容する (= ADR-0050/0051/0052 の field placement 不可触を維持)。 ADR-0045 §I-2-c は当該表を「仮、 実 allocation は実装 sprint で確定」 と明記しており、 本 §決定 2 が実 placement と整合する正式 map を確定する (= 仮表の region 順序を override)。

### 決定 3: 既配置 v2 driver_state field 3 件の正式分類

free region 先頭に既配置の次 3 field を **軸 B v2 driver_state 拡張 region の正式 member** と分類する。 placement (= address) は完全不変 (= ADR-0050/0051/0052 不可触)。

| field | address | owner ADR | 分類 |
|---|---|---|---|
| `pmdneo_v2_fade_level` | 0xFD39 | ADR-0050 §決定 4 | driver_state singleton (= 楽曲全体 fade 減衰 factor) |
| `pmdneo_v2_ssg_mixer` | 0xFD3A | ADR-0051 §決定 4 | driver_state singleton (= SSG mixer reg 0x07 shadow) |
| `pmdneo_v2_entry_marker` | 0xFD3B | ADR-0052 §決定 2 | driver_state singleton (= v2 entry skeleton 到達 marker) |

= driver_state 拡張 region (0xFD39-0xFD78、 64 byte) は 3 byte 使用済 + **0xFD3C-0xFD78 = 61 byte free** (= 後続 δ-3/δ-4 が v2 driver_state singleton を置く home)。 PartWork 拡張 region (0xFD79-0xFE78、 256 byte) は全 256 byte free。

### 決定 4: 命名規約 = `pmdneo_v2_` prefix

軸 B v2 driver が新規追加する SRAM field / region anchor は全て **`pmdneo_v2_` prefix** で命名する (= ADR-0045 §I-2-c literal、 既存 sprint 6/7/1 の 3 field と統一)。 β で追加する region 境界定数も `pmdneo_v2_driver_state_base` / `pmdneo_v2_partwork_base` / `pmdneo_v2_reserved_base` と prefix 統一する。

### 決定 5: verify gate

δ-2 は **SRAM placement の機械的 verify** で検証する。 γ sub-sprint で次を verify script (= 想定 `src/test-fixtures/axis-b/verify-axis-b-sram-placement.sh`) に体系化する。

| # | gate | 期待 |
|---|---|---|
| 1 | sub-region 非重複 + 合計 647 byte | driver_state 64 + PartWork 256 + reserved 327 = 647、 各 region 境界が非重複 (= `.lst` / source 静的確認) |
| 2 | region 境界定数 一致 | `pmdneo_v2_driver_state_base` = 0xFD39 / `pmdneo_v2_partwork_base` = 0xFD79 / `pmdneo_v2_reserved_base` = 0xFE79 が本 ADR §決定 2 と一致 |
| 3 | 既配置 3 field placement 不変 | `pmdneo_v2_fade_level` = 0xFD39 / `pmdneo_v2_ssg_mixer` = 0xFD3A / `pmdneo_v2_entry_marker` = 0xFD3B が driver_state region 内 + placement 不変 |
| 4 | 既存 SRAM layout byte-identical | 0xF820-0xFD38 既存 layout (= part_workarea / PNE block / 軸 G scratch) が base と byte-identical (= δ-2 が既存 layout を破壊しない) |
| 5 | 命名規約 | β 追加 region 境界定数 + 既存 v2 field が `pmdneo_v2_` prefix 遵守 |
| 6 | baseline regression | ADR-0049/0050/0051/0052 verify script (= mute 7 / fade-out 16 / SSG tone-enable 15 / v2-entry 7 gate) 全 PASS |

verify gate の最終件数は γ sub-sprint で確定する。 audio gate は δ-2 の完了判定に用いない (= SRAM placement は register trace / audio と別軸の静的 verify)。

### 決定 6: scope-in / scope-out / non-goal

#### scope-in (= sprint 2 で扱う)

- 0xFD39-0xFFBF free region の v2 SRAM sub-region 正式 map literal 化 (= driver_state 64 / PartWork 256 / reserved 327)
- driver への region 境界定数 (= `pmdneo_v2_driver_state_base` 等 3 件) `.equ` additive + SRAM layout comment block 整備
- 既配置 3 field の driver_state singleton 正式分類
- SRAM placement の verify script 体系化

#### scope-out (= 別 ADR / 別 sprint / future)

- **v2 driver_state / PartWork field の実 追加** (= δ-3 F-2-B / δ-4 軸 C/G/rhythm 接続点が要する個別 field) = δ-3 / δ-4 scope。 本 sprint 2 は region (= home) の確定のみ、 個別 field 追加はしない
- **F-2-B (= ch3 4-op individual mode) integration** = δ-3 (= 実装 sprint 3)
- **軸 C ADPCM-B / 軸 G ADPCM 動的供給 / rhythm 接続点** = δ-4 (= 実装 sprint 4)
- **既存 part_workarea (= 0xF820-0xFD1F、 20 part × 64 byte) の per-part field 拡張** = WORKAREA.inc legacy 含め本 sprint 不可触。 v2 PartWork 拡張 region は別 region (= 0xFD79-0xFE78) であり既存 part_workarea を変更しない
- reserved region (= 0xFE79-0xFFBF) の用途確定 = 後続軸 future

#### non-goal (= 軸 B sprint 2 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 / ADR-0049 mute / ADR-0050 fade / ADR-0051 SSG tone-enable / ADR-0052 v2 entry の routine + SRAM field の modify
- 既存 SRAM layout 0xF820-0xFD38 (= ADR-0006/0021/0022/0023/0048) の変更
- WORKAREA.inc legacy (= PART_COUNT = 17 legacy 含む) の変更 / standalone_test.s PART_COUNT = 20 の変更
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐の変更

### 決定 7: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする。

- **既存 SRAM layout 0xF820-0xFD38** = part_workarea (0xF820-0xFD1F) / driver_pne_filename_buf (0xFD20-0xFD2F) / driver_pne_filename_adr_word (0xFD30-0xFD31) / driver_pne_sample_table_id (0xFD32) / 軸 G scratch (0xFD33-0xFD38) = ADR-0006/0021/0022/0023/0048 owner、 byte-identical
- **WORKAREA.inc** legacy 全部 + standalone_test.s `PART_COUNT` = 20
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable / ADR-0052 v2 entry で追加した routine + SRAM field (= 既配置 3 field の placement 不変)
- 軸 G ADR-0048 routine 全部 + 軸 G scratch 0xFD33-0xFD38
- 軸 C ADR-0043 ADPCM-B routine 全部 + rhythm ADR-0026〜0031 routine 全部
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐

### 決定 8: doc-only filing 規律 (= 本 ADR-0053 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0053 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0053 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0053 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / ADR-0049/0050/0051/0052 完全不可触

### 決定 9: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 sprint 2 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model を継承する。 主軸の報告 / kickoff plan / commit GO / Accepted 移行判断は Codex layer 2 へ投入し、 approve なら主軸が commit + push + PR + merge + dashboard update まで自律完走、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終完走報告のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: δ-2 ground truth (= ADR-0045 §I-2 / §J-4-2 reference)

本 ADR-0053 の δ-2 設計 ground truth は ADR-0045 に literal 化済であり、 本 ADR は再調査せず reference する。 ただし sub-region map の region 順序は本 ADR §決定 2 が実 placement と整合させ override する。

| ADR-0045 section | 内容 | 本 ADR との関係 |
|---|---|---|
| §Annex I-2-a | δ-2 = PartWork / SRAM placement integration の 8 評価軸 | reference (= scope / verify gate 軸)。 「user 判断が必要な箇所 = sub-region 配分比率」 は §決定 2 で案 A 確定 (= Codex layer 2 起票 plan review approve、 実 placement 整合で escalate 不要判定) |
| §Annex I-2-b | SRAM historical range (= 0xF820-0xFD38 既存 + 0xFD39-0xFFBF 647 byte free region) | reference (= 不可触対象 + free region 範囲) |
| §Annex I-2-c | 0xFD39-0xFFBF free region sub-region 仮表 (= PartWork 256 / driver_state 64 / reserved 327) | **§決定 2 が region 順序を override** = 仮表は PartWork 先頭、 本 ADR は driver_state 先頭 (= 実 placement 整合)。 size 配分 64/256/327 は維持 |
| §J-4-2 | 実装 sprint 2 bridging note = scope (= sub-region 実 allocation literal) / ground truth (= Annex I-2) / verify gate (= placement 重複なし + prefix 規約) / 不可触対象 | reference (= scope / verify gate / 不可触対象 literal 継承) |

## Annex B: v2 SRAM sub-region map literal (= §決定 2 確定値)

```
0xF820-0xFD1F  1280 byte  part_workarea (= 20 part × 64 byte、 既存、 不可触)
0xFD20-0xFD2F    16 byte  driver_pne_filename_buf (= ADR-0022、 既存、 不可触)
0xFD30-0xFD31     2 byte  driver_pne_filename_adr_word (= ADR-0022、 既存、 不可触)
0xFD32            1 byte  driver_pne_sample_table_id (= ADR-0023、 既存、 不可触)
0xFD33-0xFD38     6 byte  軸 G scratch (= ADR-0048、 既存、 不可触)
--- 0xFD39-0xFFBF = 647 byte free region (= 本 ADR §決定 2 で sub-region 化) ---
0xFD39-0xFD78    64 byte  軸 B v2 driver_state 拡張 region (pmdneo_v2_driver_state_base)
                            0xFD39      pmdneo_v2_fade_level   (= ADR-0050、 既配置)
                            0xFD3A      pmdneo_v2_ssg_mixer    (= ADR-0051、 既配置)
                            0xFD3B      pmdneo_v2_entry_marker (= ADR-0052、 既配置)
                            0xFD3C-0xFD78  61 byte free (= δ-3/δ-4 driver_state home)
0xFD79-0xFE78   256 byte  軸 B v2 PartWork 拡張 region (pmdneo_v2_partwork_base、 全 free)
0xFE79-0xFFBF   327 byte  reserved (pmdneo_v2_reserved_base、 後続軸 future)
```

非重複 verify: 0xFD39 + 64 = 0xFD79 / 0xFD79 + 256 = 0xFE79 / 0xFE79 + 327 = 0xFFC0 (= 0xFFBF + 1)。 連続 + 非重複 + free region 完全充足 ✓。

## Annex C: β 実装 completion record (= driver region 境界定数 + SRAM layout comment block)

### C-1: β deliverable

軸 B 実装 sprint 2 β = v2 SRAM region 境界定数 driver 実装 (= 39th session、 PR #81)。 §決定 2 案 A の sub-region map を driver `standalone_test.s` に literal 化する。

| deliverable | 内容 |
|---|---|
| region 境界定数 3 件 | `standalone_test.s` に `.equ pmdneo_v2_driver_state_base, 0xFD39` / `.equ pmdneo_v2_partwork_base, 0xFD79` / `.equ pmdneo_v2_reserved_base, 0xFE79` を additive 追加 (= §決定 2 案 A 確定値、 命名規約 `pmdneo_v2_` prefix)。 後続 δ-3/δ-4 が追加する v2 SRAM field は本 base 定数からの相対 offset で配置する |
| SRAM layout comment block 整備 | `standalone_test.s` の Z80 SRAM layout コメントを v2 sub-region 3 区画構造へ更新 (= driver_state 64 byte / PartWork 256 byte / reserved 327 byte、 既配置 3 field を driver_state region 先頭 3 byte + 0xFD3C-0xFD78 = 61 byte free を明示) |

### C-2: β 検証結果

- production build PASS。 region 境界定数 3 件が `.lst` で `pmdneo_v2_driver_state_base` = 0x00FD39 / `pmdneo_v2_partwork_base` = 0x00FD79 / `pmdneo_v2_reserved_base` = 0x00FE79 に解決 (= §決定 2 案 A + Annex B と一致)
- rom binary (`243-m1.m1`) が β 適用前と **byte-identical** (= 未参照 `.equ` は機械語 byte を emit しない、 β は driver の機械語 + 既存 routine + 既配置 SRAM field placement を一切変更しない)
- driver touch = `standalone_test.s` のみ (= `.equ` 3 件 additive + SRAM layout comment block、 既存 code 不変)
- 既存 SRAM layout 0xF820-0xFD38 + ADR-0049/0050/0051/0052 の SRAM field placement 完全不変
- Codex layer 2 = β 実装 review approve

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) が使うメモリ (= Z80 の SRAM) の置き場所を正式に決める。 0xFD39 から 0xFFBF までの 647 バイトの空き領域を 3 つの区画 (= driver_state 拡張 / PartWork 拡張 / 予約) に分け、 どの区画がどこから始まるかを文書と定数で固定する。

**前提**: 軸 B の実装は実装 1 (= v2 入口) が完了済。 実装 1 のときに fade / SSG mixer / 入口マーカーの 3 つの 1 バイト変数が空き領域の先頭 (0xFD39-0xFD3B) に置かれた。 これらは「ドライバ全体で 1 つ」 の変数なので driver_state 区画に分類すべきもの。 設計書 (ADR-0045) の仮の区画表は「先頭 = PartWork」 としていたが、 実際の置かれ方と食い違っているため、 ここで実態に合わせて正式な区画表を確定する。

**今回やること (= α)**: 設計書 (= 本 ADR-0053) を起票するだけ。 ドライバのコードはまだ書かない。 区画の範囲・順序・既存 3 変数の分類・検証方法を文書で固定する。

**区画の決め方**: driver_state 拡張区画を空き領域の先頭 (0xFD39 から 64 バイト) に置く。 こうすると既に置かれている 3 変数を 1 バイトも動かさずに正式区画へ収められる。 その後ろに PartWork 拡張区画 (256 バイト)、 さらに後ろに予約区画 (327 バイト)。 合計 64 + 256 + 327 = 647 バイトでぴったり。

**次**: 本 ADR-0053 を doc-only で commit / PR / merge した後、 β sub-sprint でドライバに区画の境界定数を追加し、 γ で検証スクリプトを整備して Draft → Accepted へ移行する。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0053 起票) | **進行中** (= 39th session、 本 PR) | (= 本 PR) | 起票 plan review approve (= 論点 1 案 A / 論点 2 3 段、 escalate なし、 規律 5 観点 PASS) + 起票 review |
| β (= driver region 境界定数 + comment block) | **完了** (= 39th session、 PR #81) | PR #81 | β 実装 review approve |
| γ (= verify script 体系化 + completion + Accepted 判断) | 未着手 | - | - |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-21 | Draft 起票 (= 39th session 軸 B 実装 sprint 2 α) | δ-2 PartWork / driver_state SRAM placement の実装 ADR を起票。 軸 B 本線の実装 sprint 2 として δ-2 を選定 (= ADR-0045 §I-5-b sequential 順序、 δ-1 完了の次)。 決定 1-9 + 3 段 sub-sprint α/β/γ + v2 SRAM sub-region 正式 map (= 案 A = driver_state 拡張 64 byte 0xFD39 先頭 / PartWork 拡張 256 byte / reserved 327 byte) + 既配置 3 field の driver_state singleton 正式分類 + verify gate 6 件 + 命名規約 `pmdneo_v2_` prefix。 doc-only filing (= ADR-0053 + dashboard のみ変更)。 ADR-0045 §J-4-2 literal 後続実装 ADR。 sub-region map は ADR-0045 §I-2-c 仮表の region 順序を実 placement (= sprint 6/7/1 が 0xFD39 に driver_state-class 3 field を配置) と整合させ override (= size 配分 64/256/327 は維持)。 Codex layer 2 起票 plan review = approve (= 論点 1 sub-region map 案 A approve / 論点 2 sub-sprint 3 段 α/β/γ / 規律 5 観点 PASS、 escalate なし)。 軸 B 実装 sprint chain は実装 2 = δ-2 が v2 SRAM foundation、 軸 B 全体は未完了 (= 「軸 B 完成」 表現不使用) |
| 2026-05-21 | β 実装完了 (= 39th session、 PR #81) | v2 SRAM region 境界定数 driver 実装。 `standalone_test.s` に region 境界定数 3 件 (= `pmdneo_v2_driver_state_base` 0xFD39 / `pmdneo_v2_partwork_base` 0xFD79 / `pmdneo_v2_reserved_base` 0xFE79、 §決定 2 案 A 確定値) を `.equ` additive 追加 + Z80 SRAM layout comment block を v2 sub-region 3 区画構造へ整備。 Annex C 追記 (= β completion record + deliverable + 検証結果) + sub-sprint chain β 完了 reflect。 検証 = production build PASS + region 境界定数 3 件が `.lst` で §決定 2 案 A と一致解決 + rom binary byte-identical (= 未参照 `.equ` は機械語 byte 非emit、 β は driver 機械語 + 既存 routine + 既配置 SRAM field placement 不変)。 driver touch = `standalone_test.s` のみ。 Codex layer 2 = β 実装 review approve。 既存 SRAM layout 0xF820-0xFD38 + ADR-0049/0050/0051/0052 + 軸 G ADR-0048 + 軸 C ADR-0043 完全不可触、 「軸 B 完成」 表現不使用 |
