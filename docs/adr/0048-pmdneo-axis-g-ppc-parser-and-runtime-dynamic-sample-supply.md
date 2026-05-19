# ADR-0048: PMDNEO 軸 G = ADPCM 動的 sample 供給 (= `.PPC` parser + driver runtime selection + asset converter 接続) 設計 (= 軸 G α、 5 sub-sprint 構成、 doc-only filing)

- 状態: **Draft** (= 2026-05-19 33rd session α、 ADR-0043 §決定 2 literal 後続 ADR、 軸 G 新規軸 起票、 Codex layer 2 round 1 approve = 主軸推奨完全一致)
- 起票日: 2026-05-19
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0043** (= 軸 C ADPCM-B 1ch runtime-managed architecture、 §決定 2 で `.PPC` driver parse は本軸 (= 軸 C) scope-out + 後続 ADR 候補 ADR-0048 で扱う literal、 本 ADR の母 ADR)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 default 永続化、 §決定 7 dashboard 一元管理、 §決定 8 ADR 番号予約、 §決定 9 memory write 集約)
  - ADR-0044 (= 軸 F MML compiler 拡張 完成扱い、 採用案 (ii) 軸 F 全体 scope-out + F-2-B 軸 B 譲渡、 軸 G integration design で MML compiler touch なし)
  - ADR-0023 (= step 9 `.PNE` filename → sample_table_id resolver、 D1 hand-written directory + T3 独立 routine、 軸 G integration design 参照)
  - ADR-0024 (= step 10 sample_table_id selection consumption、 A2 中間 routine 経由 pointer 返却、 軸 G integration design 参照)
  - ADR-0025 (= step 11 multi-table id=0x01 proof、 ADPCM-A multi-table arch、 軸 G integration design 参照)
  - ADR-0021 (= step 7 `.PNE` asset pipeline + `.MN` filename embed、 path B / c1 採用、 軸 G .PPC asset pipeline 対称構造参照)
  - ADR-0014 (= ADR-0006 sprint 成果 disposition、 改造 PMDDotNET 路線採用、 自前 compile.py 凍結)
  - ADR-0015 (= 改造 PMDDotNET 技術調査、 PMDPPZ 流儀 100-150 件 if 分岐 + wrapper、 PMDDotNET PCMDRV.cs 1063 行 ground truth)
- 関連 memory:
  - `project_pmdneo_33rd_session_initiated.md` (= 33rd session 起点、 軸 G 新規軸予約 + user 明示永続 scope-out 9 項目)
  - `project_pmdneo_adpcma_subsystem_boundary.md` (= ADPCM-A / ADPCM-B subsystem 境界、 軸 G 範囲明確化)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化、 33rd session 採用継続)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律、 軸 G 起票 prompt 規律基盤)
  - `feedback_subagent_isolation_worktree_base_ref_mismatch.md` (= sub-agent 5 連続 fail 経験、 軸 G も主軸 fallback default 想定)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 軸 G δ runtime selection proof verify gate)
  - `project_adr_0013_0014_path_switch.md` (= 改造 PMDDotNET 路線切替、 PMDPPZ 流儀発見、 軸 G `.PPC` parser ground truth source)

## 背景 (= why now)

### 軸 C 完了 base + ADR-0043 §決定 2 literal 後続 ADR 経路

PMDNEO は YM2610(B) 2 系統 ADPCM (= ADPCM-A 6ch + ADPCM-B 1ch) を駆動する。 32nd session 末 (= 2026-05-19) で **軸 C (= ADPCM-B 1ch runtime-managed architecture)** が ADR-0043 Accepted + 越川氏 audition approve で完了し、 ADPCM-B 軸 sample 切替 + multi-table proof + 軸独立性 trace + statement audio gate 全段階達成済 (= PR #18/#22/#28/#30-#35、 commit chain 2d3181f)。

ADR-0043 §決定 2 で literal 規定: **`.PPC` (= PMD V4.8s PMDB2 用 ADPCM RAM sample pack) の driver parse / runtime selection は本軸 (= 軸 C) scope-out、 別 ADR (= 候補 ADR-0048 等、 後続) で扱う**。 本 ADR-0048 はこの literal 後続 ADR として 33rd session で起票する。

### 33rd session 候補 3 採用経路 (= Codex layer 2 round 1 approve)

33rd session 開始時 user 明示指示:
- Surge XT / .fxp render / actual render / 軸 A β-3 = 永続 skip
- vendor wav 3 件 retain
- ADR-0041 §決定 4-2 Codex rescue 化 default 永続化適用

主軸が 4 候補 (= 候補 1 δ tempo refinement / 候補 2 軸 B 起票 / 候補 3 ADR-0048 起票 / 候補 4 dashboard/memory 整理) を Codex layer 2 (= session 019e3b50-... 流用) に投入し、 **候補 4 → 候補 3 順 approve** 取得:
- 候補 1 (δ tempo refinement) = defer (= 軸 C 再オープン risk + user 明示「軸 C 継続 skip」 矛盾 risk)
- 候補 2 (軸 B) = defer (= ADR-0044 §F-2-B 前提整備未了、 scope 最大)
- 候補 3 (ADR-0048) = ADR-0043 §決定 2/§決定 8 自然後続、 5 段 α/β/γ/δ/ε 推奨 (= ADR-0043 4 段 ch 軸不要構成からの 1 段増 = format/parser/runtime/audition 軸分離)
- 候補 4 (dashboard/memory 整理) = ADR-0041 §決定 7/9 + user 明示 Surge XT 永続 skip / vendor wav retain literal 化が急務

候補 4 は PR #36 MERGED で 33rd session 起点 literal 化完了 (= 軸 G 命名 + ADR-0048 番号予約 + §user 明示永続 scope-out 9 項目)。 本 ADR-0048 起票は候補 3 = 33rd session 主 sprint。

### 既存実装 base + 不足箇所

ADPCM-B 軸 (= 軸 C) 32nd session 末完了時点で:

- **sample 切替経路成立済**: `pmdneo_select_adpcmb_sample_pointer` (= ADR-0043 α、 routine 定義済) + voice index → sample id lookup table (= β、 2 entry) + `sample_table_id` (= γ-2、 0xFD32 lookup、 hybrid 経路 .MN bytecode 由来) + ADPCM-A 軸独立性 (= γ-3 verify)
- **build-time embed 経路**: `samples-map-adpcmb.yaml` hand-written passthrough + `vromtool.py` merge + `samples.inc` symbol emit (= ADR-0021 §c1 採用根拠継承)
- **未着手領域 (= ADR-0043 §決定 2 literal scope-out)**:
  1. `.PPC` format driver parse (= header / directory / sample range 解析)
  2. `.PPC` runtime sample selection (= directory 引きで sample addr 動的解決)
  3. asset converter 経路 (= WAV → `.PPC` 変換、 yaml hand-written passthrough との切替)
  4. PMDPPZ 流儀 ADPCM RAM sample bank 概念 → YM2610(B) V-ROM 直結 mapping

ADR-0043 §決定 2 literal 「`.PPC` の WebApp 経由 ADPCM-B 管理 UI / converter は Phase 4 領域」 + Annex B literal 「PMDDotNET PMDPPZ 流儀の主要 routine pattern (= 100-150 件 if 分岐 + wrapper、 `pcmmain` / `pcm_addr_set` / `pcm_volset` / `pcm_panset` / `pcm_freq_set` / `keyon` / `keyoff`)」 を ground truth source として、 PMDNEO 軸 G で `.PPC` driver parse + runtime selection を新規実装する設計を本 ADR で確立する。

### 軸 G 命名 + scope 定義

- **軸名**: 軸 G (= ADPCM 動的 sample 供給)
- **scope-in**:
  - `.PPC` format driver parse (= header / directory / sample entry 解析)
  - `.PPC` runtime sample selection (= directory 引き、 sample addr 動的解決)
  - PMDPPZ 流儀 reference → YM2610(B) V-ROM 直結 mapping 設計
  - 既存 sample_table_id selection arch (= ADR-0023/0024/0025) との integration design
  - ADPCM-B 軸 (= ADR-0043) production-ready 保護 (= 既存 yaml passthrough 並走)
  - asset converter (= WAV → `.PPC`) 接続点予約 (= 別軸 D Phase 4 WebApp 委譲予約)
- **scope-out (= 別 ADR / 別軸 / future sprint)**:
  - WebApp UI (= Phase 4 軸 D 範囲、 ADR-0046 候補)
  - Surge XT (= user 明示永続 skip)
  - vendor wav cleanup (= user 明示 retain、 33rd session 起点 §user 明示永続 scope-out 節)
  - tempo refinement (= 軸 C 完了済、 軸 C δ aesthetic finding は別 sprint で新規 ADR 起票時に user 明示 GO 待ち)
  - 軸 B FM3 4-op (= ADR-0044 §F-2-B 譲渡軸、 ADR-0045 候補)
  - ADR-0043 軸 C 実装 modify (= ADR-0043 Accepted 不可触、 軸 G で driver runtime 接続時は ADR-0043 routine 追加経路で、 既存 routine touch なし)

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0048 を起票、 後続 sub-sprint α-ε で format archaeology → parser proof → integration design → runtime selection proof → integration + audition gate を段階的に進める。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。

## 決定

### 決定 1: 軸 G sub-sprint 構成 = 5 段 α/β/γ/δ/ε (= Codex layer 2 推奨)

軸 G を **5 段階 α/β/γ/δ/ε** に分割する。 ADR-0043 軸 C 4 段 (= ch 軸不要 1 ch 専用構成) から **format/parser/integration/runtime/audition 軸分離 1 段増** = format archaeology を独立 sub-sprint 化、 parser proof を driver touch なし doc-only 化、 integration design を ADR-0043 ADPCM-B production-ready 保護観点で独立 sub-sprint 化、 runtime selection proof を driver touch primary gate primary 化、 ε で integration + audition gate を統合。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | `.PPC` format archaeology + fixture contract = PMD V4.8s / PMDDotNET `PCMDRV.cs` 1063 行 reference + byte-level parser spec literal + 最小 fixture 期待値 (= directory entry + sample range) ADR Annex 化 | 主要 routine pattern (= 100-150 件 if 分岐 + wrapper) reference + byte-level parser spec + 最小 fixture (= 1-2 entry) 期待値 literal、 driver source touch なし、 vendor touch なし、 doc-only | なし |
| **β** | parser / validator proof (= header / directory / sample range parse + malformed reject) = α spec を Python / spike 等で proof + 期待 entry decode + malformed input reject、 ADR-0043 既存 yaml passthrough 経路と独立 (= 並走) | spike 実装 + 正常 fixture decode 期待値一致 + malformed fixture reject + driver source touch なし | なし (= spike script のみ) |
| **γ** | integration design = `samples.inc` / `sample_table_id` (= 0xFD32) / yaml passthrough との接続方針確定 + ADR-0043 ADPCM-B production-ready 保護経路 literal、 driver runtime parse 接続点予約 (= δ で touch、 γ では設計のみ) | 接続設計 ADR §決定 追加 (= sample selection routine 拡張点 / sample_table_id 共用 / yaml passthrough fallback / `.PPC` parse 優先順) + ADR-0043 既存 routine 不可触 literal 確認、 driver source touch なし | 設計のみ |
| **δ** | runtime selection proof = `.PPC` directory runtime parse + sample addr 動的解決 + register write 経路 = driver source touch 最小限 (= 既存 `pmdneo_select_adpcmb_sample_pointer` 拡張 or 別 routine 並設)、 primary gate = register trace、 wav sha256 = timing-sensitive reference | α-γ pass 後のみ許可、 `.PPC` fixture 1-2 entry で sample addr 動的解決 observable proof + register trace primary gate 期待値一致 + ADR-0043 既存経路 byte-identical 維持 + MAME 起動確認 (= audio gate) | 最小限 driver touch (= 既存 routine 不可触、 新規 routine 追加 only) |
| **ε** | integration + audition gate = `.PPC` 経路 + yaml passthrough 経路 + ADPCM-A 軸 統合 fixture 1 つ以上 MAME 再生 + 越川氏 audition (= audio behavior 変化時のみ user audition = ADR-0041 §決定 4-2 例外) | 全 sub α/β/γ/δ verify gate PASS + 統合 fixture register trace + audio gate (= 越川氏 audition、 必要時のみ) | 必要時のみ |

#### 共通規律 (= 全 sub-sprint 共通、 ADR-0043 §決定 1 共通規律踏襲)

- 各 sub = **1 commit + 1 push** (= `feedback_post_commit_push_report_format` + `feedback_push_per_commit` 適用)
- **primary gate = ADPCM-B register trace / ymfm-trace** (= reg 0x10-0x1B、 `feedback_refactor_gate_register_trace_not_wav` 適用)
- wav sha256 は **timing-sensitive reference** (= cycle 数増減で sample shift 許容)
- 各 commit 前に「平易な日本語で説明」 + user レビュー待ち (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下では Codex layer 2 経由 approve → 主軸自律 commit、 user 介入は escalate or 最終確認のみ)
- driver / runtime layer touch commit = MAME 起動確認義務 (= CLAUDE.md §動作確認義務、 audio gate 必須、 δ/ε のみ)
- ADR-0041 §決定 4 規律 = sub-agent ↔ Codex 壁打ち + 3 重 zero-trust review、 ADR-0041 §決定 5 escalation 6 種準拠、 §決定 4-3 sub-agent isolation 5 連続 fail 経験下で主軸 fallback default

### 決定 2: `.PPC` format ground truth = PMDDotNET `PCMLOAD.cs` (= format parser) + `PCMDRV.cs` (= 演奏 runtime) reference

`.PPC` (= PMD V4.8s PMDB2 用 ADPCM RAM sample pack) の ground truth source は **PMDDotNET `vendor/PMDDotNET/PMDDotNETDriver/` 配下の 2 file** (= GPL-3.0):

| file | 行数 | 役割 | 軸 G 用途 |
|---|---|---|---|
| `PCMLOAD.cs` | 1256 行 (= α 実測) | `.PPC` / `.P86` / `.PVI` / `.PPS` file format parser + load logic | **byte-level format spec ground truth** (= α format archaeology、 β parser proof) |
| `PCMDRV.cs` | 1063 行 (= α 実測) | ADPCM 演奏 runtime (= `pcmmain` / `pcm_addr_set` / `pcm_volset` / `pcm_panset` / `pcm_freq_set` / `keyon` / `keyoff`、 100-150 件 if 分岐 + wrapper) | runtime selection 経路 reference (= γ integration design、 δ runtime selection proof)、 runtime directory index 引き経路 (= L673-684) は **軸 G runtime selection の主軸 reference** |

**α finding (= 起票 commit 時の reference 補正)**: ADR-0048 起票 commit 段階では PCMDRV.cs のみ reference していたが、 sub-sprint α format archaeology で **`.PPC` format parse / load logic は PCMLOAD.cs に存在** (= L260-647) が判明、 本 §決定 2 を α 完了 commit で補正。 両 file の役割分離 literal:

| 役割軸 | file | 範囲 | 軸 G 用途 |
|---|---|---|---|
| **`.PPC` file format parse + load** (= file→runtime work area transfer) | `PCMLOAD.cs` | L260-647 (= `pcm_all_load` / `all_load` / `ppc_load_main` / `write_pcm_main`) | α byte-level spec literal + β parser proof spike |
| **runtime directory index selection** (= voicenum → pcmstart/pcmstop word decode) | `PCMDRV.cs` | L673-684 (= voicenum × 4 byte offset → `pw.pcmWk[r.bx]` LE decode → `pw.pcmstart` / `pw.pcmstop` set) | γ integration design + δ runtime selection proof 主軸 reference |
| ADPCM 演奏 main (= 演奏 loop / keyon / keyoff / volume / pan / freq) | `PCMDRV.cs` | L36-78 + 100-150 件 if 分岐 + wrapper | γ / δ / ε reference |

ADR-0043 Annex B では PMDPPZ 流儀 主要 routine pattern として PCMDRV.cs を reference したが、 **format parse/load は PCMLOAD.cs、 runtime directory index selection (= voicenum → pcmstart/pcmstop) は PCMDRV.cs L673-684** という役割分離が α 段階で判明。 両 file を ground truth とする。

PMDDotNET は **PC-98 OPNA ADPCM RAM 経路** (= 32K-256KB ADPCM RAM、 sample bank 概念) を駆動。 PMDNEO は **YM2610(B) 内蔵 ADPCM-B** (= V-ROM 直結、 RAM 概念なし、 ROM addr 直接 register write) を駆動するため経路が異なる。 軸 G では PMDDotNET `.PPC` directory 引き仕様を **byte-level parser spec として継承** + YM2610(B) V-ROM 直結への **mapping 設計** を α/γ で literal 化、 PMDPPZ 流儀の register write 経路は PMDNEO 既存経路 (= ADR-0043 routine) と異なるため γ integration design で接続方針確定。

**理由**:
- ADR-0014 §改造 PMDDotNET 路線採用 + ADR-0015 §軸 4 改造 PMDDotNET 技術調査 で literal 化済の改造路線継承
- PMDPPZ 流儀発見 (= `project_adr_0013_0014_path_switch.md` literal) を `.PPC` format 仕様 ground truth として活用
- ADR-0043 Annex B reference 既存、 `.PPC` driver parse 経路は本軸 (= 軸 G) で初実装、 別 ADR で扱う literal 経路を踏襲

### 決定 3: integration design = ADPCM-B 軸 production-ready 保護 + yaml passthrough 並走

軸 G `.PPC` parser + runtime selection は **ADR-0043 ADPCM-B production-ready 経路 (= yaml hand-written passthrough + `samples.inc` build-time embed + `sample_table_id` selection arch) を保護** + **`.PPC` 経路を並走** で進める。 既存 ADR-0043 routine (= `pmdneo_select_adpcmb_sample_pointer` + `adpcmb_sample_beat` literal table + voice index lookup table) は **不可触**、 軸 G では:

- 新規 routine 追加 (= `.PPC` directory parse / runtime sample addr 解決) で既存経路と並走
- `sample_table_id` (= 0xFD32) は ADPCM-A / ADPCM-B 軸共用 (= ADR-0043 §決定 3) + 軸 G `.PPC` 経路でも共用、 selection arch 統一
- yaml hand-written passthrough fallback 維持 (= `.PPC` 不在 / parse fail / id mismatch 時の fallback)
- `.PPC` 経路 priority は γ integration design で確定 (= 候補: priority `.PPC` > yaml / priority yaml > `.PPC` / id range で切替)

**理由**:
- ADR-0043 越川氏 audition approve 済 + 越川氏「1〜4 の内容に問題無いと思われる」 literal、 production-ready 経路を破壊しない保護義務
- Codex layer 2 must-fix #4 = 「候補 1 後続で進める場合は ADR-0043 edit 不可 (新規独立 sprint + 新規 ADR として起票)」 + 軸 G も同 spirit で ADR-0043 routine 不可触
- ADR-0023/0024/0025 sample_table_id selection arch 確立済を再利用、 設計言語統一
- 早すぎる抽象化回避 (= CLAUDE.md §スコープ外踏み込み禁止「3 行重複は早すぎる抽象化より良い」)、 共有 routine 化は ε 完了後判断

### 決定 4: doc-only filing 規律 (= 本 ADR-0048 起票 commit + α 完了 commit 共通) + commit 汚染防止

本 ADR-0048 起票 + α 完了 commit (= ADR doc 起票 + Annex A literal 化) は **doc-only commit 厳守**:

- parser 実装禁止 (= β sub-sprint で起動、 spike script 経路)
- driver source touch 禁止 (= δ sub-sprint で起動、 最小限のみ)
- vendor source touch 禁止 (= 軸 G 全 sub-sprint 通して vendor 不可触)
- `.PPC` fixture 新規追加禁止 (= **α では imagined byte sequence only** (= Annex A-7 literal)、 β で実 fixture spike 生成)
- 自前 compile.py / 軸 F MML compiler touch 禁止 (= ADR-0044 §F-2-A defer + 軸 F 完成扱い literal 経路)

#### commit 汚染防止 (= 軸 G α revise round 2 Codex layer 2 must-fix #1 反映 literal)

軸 G 全 sub-sprint 通して、 user 明示永続 retain の vendor wav 3 件 (= `vendor/ngdevkit-examples/06-sound-adpcma/assets/{lefthook,lightbulbbreaking,woosh}.wav`、 33rd session 起点 dashboard §user 明示永続 scope-out 節 literal) は untracked 状態を維持。 commit 時の汚染防止 規律:

- **`git add` は target file path 明示** (= `git add -A` / `git add .` / `git add vendor/` 禁止、 vendor wav 3 件の誤 stage 防止)
- **commit message 末尾の Stage hint literal**: 「stage = `<ADR file path>` only」 を commit message に literal 化 (= post-commit `git show --stat` で確認可能)
- **commit 直前 `git status --short` 確認**: stage に target file 1 つ only + vendor wav 3 件 untracked 維持を主軸 verify
- **規律違反 risk**: vendor wav 3 件が tracked 化すると ADR-0033 sample provenance 軸 (= 軸 A 関連) + user 明示 retain 経路と衝突、 軸 G commit から完全分離維持義務

**理由**:
- Codex layer 2 must-fix #3 = 「ADR-0048 filing commit は doc-only 厳守 (parser 実装 / driver touch / vendor touch は filing 段階で禁止)」
- ADR-0043 軸 C α task (= ADR-0043 起票) と sub-sprint α (= driver routine 新規追加) が別 step の literal 経路踏襲
- doc-only filing で設計を確立 → 後続 sub-sprint で段階実装、 早すぎる実装を防止

### 決定 5: non-goal list (= literal 列挙)

軸 G で **明示的に扱わない** 項目 (= 別 ADR / 別軸 / future sprint / user 明示永続 scope-out):

| non-goal 項目 | 理由 / 譲渡先 |
|---|---|
| WebApp UI (= MML エディタ / プレビュー / ビルド) | Phase 4 軸 D 範囲 (= ADR-0046 候補)、 軸 G 完成後の WAV → `.PPC` converter 経路接続点予約のみ |
| Surge XT install / .fxp render / actual render | user 明示永続 skip (= 33rd session 起点 §user 明示永続 scope-out 節 literal) |
| 軸 A β-3 (= actual render) / β-4 (= audit_gate aesthetic) | user 明示永続 skip / 永久 user scope (= 同上) |
| vendor wav 3 件 (= lefthook / lightbulbbreaking / woosh.wav) 削除 / provenance 判断 | user 明示 retain (= 同上)、 軸 G で触らず保留 |
| 軸 C 再オープン (= ADR-0043 routine modify) | user 明示永続 skip (= 同上)、 軸 G は ADR-0043 routine 不可触 |
| 軸 C δ tempo refinement (= ADR-0043 §δ「テンポが速い」 aesthetic finding) | defer (= 軸 C 完了に伴い別 sprint 新規 ADR 起票時に user 明示 GO 待ち)、 軸 G で扱わない |
| 軸 B FM3 4-op (= driver ch3 4-op FM3 拡張) | ADR-0044 §F-2-B 譲渡軸、 ADR-0045 候補、 軸 G で扱わない |
| 軸 F MML compiler 拡張 (= F-1 voice buffer / F-2-A X/Y/Z 強制) | ADR-0044 完成扱い (= 採用案 ii)、 F-2-A 将来 sprint defer、 軸 G で扱わない |
| ADPCM-A (= L-Q 6 ch) 経路 modify | 軸 G は ADPCM-B 軸延長、 ADPCM-A は ADR-0019-0032 完了済、 不可触 |
| `.PNE` (= ADPCM-A 専用 format) parser modify | ADR-0021 完了済 + ADR-0022/0023 完了済、 軸 G は `.PPC` (= ADPCM-B 用) 専用、 `.PNE` 触らず |

### 決定 6: sub-agent / Codex layer / 主軸 fallback 規律 (= ADR-0041 経路継承)

軸 G 全 sub-sprint で:

- **sub-agent 起動**: ADR-0041 §決定 2 worktree isolation 必須 + `feedback_subagent_isolation_worktree_base_ref_mismatch.md` guard 9 件遵守、 但し 31st-32nd session で 5 連続 isolation fail 経験 + ADR-0041 §決定 4-3 主軸 fallback default 既 pattern を踏襲 → **主軸 fallback default、 sub-agent 起動は α/β doc-only 系で試行的、 δ/ε driver touch 系は主軸単独実装 default**
- **Codex layer 1** (= sub-agent ↔ 軸別 Codex session): commit 直前 review 必須、 session ID は本 ADR 起票後 dashboard `## Codex session ID 一覧` に追加
- **Codex layer 2** (= 主軸 ↔ 統合判断 session `019e3b50-...` 流用): 起動条件 = 複数案 / 軸間衝突 / 設計判断複数案 / user 確認質問の代行 (= ADR-0041 §決定 4-2 拡張 Codex rescue 化 default 永続化)
- **escalation 6 種** (= ADR-0041 §決定 5): `codex_unresolved` / `discipline_violation_risk` / `design_judgment_needed` / `audit_gate` / `unexpected_finding` / `merge_conflict`
- **user 介入** (= ADR-0041 §決定 4-2 例外): escalate or 最終確認 (= PR merge 判断 / audition 判断) のみ、 aesthetic / audio audition 関連 / 設計トレードオフ / 規律違反 risk 重大時のみ

### 決定 7: dashboard 更新 + 進捗管理 (= ADR-0041 §決定 7 規律)

各 sub-sprint 完了で dashboard `docs/parallel-axes-dashboard.md` § 軸別進捗 details § 軸 G 表 + § escalation 履歴 を主軸 write で update (= sub-agent read のみ)、 ADR-0048 §sub-sprint 完了 section に literal 反映、 1 sub = 1 commit + 1 PR + 1 merge + 1 dashboard update。

## sub-sprint chain 進捗 (= 起票時 literal、 後続 sub-sprint 完了で update)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= 本 commit、 Annex A literal 化 + §決定 2 補正、 doc-only) | (= 本 commit hash) |
| β | **次** (= parser / validator proof spike + minimum fixture 生成) | - |
| γ | 未着手 (= integration design 接続設計、 V-ROM mapping 候補 3 種から確定) | - |
| δ | 未着手 (= runtime selection proof driver touch 最小、 既存 routine 不可触) | - |
| ε | 未着手 (= integration + audition gate、 必要時 user audition) | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

- **やりたいこと**: ADPCM-B 軸 (= 軸 C) は完成して production-ready になったが、 sample 供給経路は build 時に yaml で hand-written embed する形 (= ADR-0043 §決定 2 で `.PPC` driver parse は scope-out) のままで、 PMD V4.8s `.PPC` (= PMDB2 用 ADPCM RAM sample pack) を driver runtime で directory 引きする経路がまだない。 これを ADR-0043 §決定 2 literal 後続 ADR 経路で新規軸 G として立ち上げる。
- **前提**: 32nd session 末で軸 C 完了 (= ADR-0043 Accepted、 越川氏 audition approve)、 全 OPEN PR 0 件、 33rd session 起点で Codex layer 2 round 1 approve (= 候補 4 → 候補 3、 主軸推奨完全一致)、 user 明示永続 scope-out 9 項目 (= Surge XT / vendor wav / 軸 C 再オープン 等) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下。
- **やったこと**: ADR-0048 起票 = 7 §決定 (= sub-sprint 5 段 α/β/γ/δ/ε + `.PPC` ground truth PMDDotNET `PCMDRV.cs` + integration design ADPCM-B 保護 + doc-only filing + non-goal 列挙 + ADR-0041 経路継承 + dashboard 更新規律)、 軸 G 命名 + scope-in/scope-out literal + Codex layer 2 推奨 5 段構成踏襲、 ADR-0043 既存 routine 不可触 + yaml passthrough 並走方針、 doc-only commit で driver / runtime / vendor 完全不変。
- **結果**: doc-only ADR Draft 起票 (= 本 commit)、 driver / runtime / vendor 完全不変、 後続 sub-sprint α/β/γ/δ/ε 着手準備完了、 dashboard 軸 G 行 update + ADR-0048 Draft 起票済 literal 反映。
- **解釈**: ADR-0043 ADPCM-B native path 完成段階の自然な後続として、 PMD V4.8s `.PPC` driver runtime parse + sample bank 動的供給を軸 G で実現する。 ADPCM-A multi-table proof (= ADR-0025) pattern + ADPCM-B sample_table_id integration (= ADR-0043 γ) pattern を継承しつつ、 PMDPPZ 流儀 (= PMDDotNET `PCMDRV.cs` 1063 行) を ground truth source として byte-level parser spec を α で確定、 β で spike proof、 γ で integration design、 δ で runtime selection proof、 ε で audition gate と段階的に進める。 5 段化は format/parser/integration/runtime/audition 軸分離 (= Codex 推奨) + ADR-0043 4 段 ch 軸不要構成からの 1 段増。
- **次の step (= 起票時 = α 着手予定)**: sub-sprint α 着手 = `.PPC` format archaeology + fixture contract 確定 = PMDDotNET `PCMLOAD.cs` (= 1256 行、 byte-level format parser ground truth) + `PCMDRV.cs` (= 1063 行、 runtime selection reference) grep + byte-level parser spec literal + 最小 fixture (= 1-2 entry) imagined byte sequence ADR Annex 化 + Codex layer 2 review。 本 ADR-0048 起票 (= 軸 G α task の前段 = ADR doc 起票そのもの) と sub-sprint α (= format archaeology) は **別 step** である点に注意 (= ADR-0043 同形 pattern)。
- **α 完了後 次の step (= α 完了 commit reflect)**: sub-sprint β 着手 = parser / validator proof spike + minimum fixture **生成** (= α では imagined byte sequence only、 β で実 fixture spike emit + reject 条件 literal 検証)、 driver / runtime / vendor 完全不変、 Annex A-7 β validator 候補 reject 条件 table から β default 採用 4 件 + γ 確定 1 件選定。

## Annex A: `.PPC` format archaeology (= sub-sprint α 完了 literal、 PMDDotNET PCMLOAD.cs reference)

### A-1: `.PPC` file header layout (= byte-level、 PCMLOAD.cs L287-298 spec literal 引用 + parser code 確認済)

```
offset  size      description                                           PMDDotNET source
0x000   30        signature = "ADPCM DATA for  PMD ver.4.4-  " (= ASCII) L290 spec + L512-515 parser
0x01E   2         Next START Address (= 16-bit LE word、 PCMRAM 上の Next START addr) L291 spec + L584 parser
0x020   1024      directory = 256 entries × 4 byte                       L292 spec + L555-566 copy to pcmWk
0x420   N         PCM data 本体 (= ADPCM 4-bit packed)                  L590 base offset

(file 末尾)
```

**source attribution**: directory layout 自体は L287-292 spec コメント + L555-566 で `pcmData[i + 32]` を `pw.pcmWk[]` に copy する transfer logic で確認 (= file 内 offset 0x20 = 32 から 4 * 256 + 128 byte = directory 1024 byte + filename 128 byte を runtime work area に展開)。 directory index 引き runtime は **PCMDRV.cs L673-684** (= 後述 A-6)、 PCMLOAD.cs L630-634 の `r.bx += r.bx` × 5 (= × 32) は **PCM data transfer stride 計算** (= 0x400 byte block × 32 stride = 0x8000 byte 一括 store unit) であり directory entry word の byte unit 変換ではない。

**合計 header 固定 byte 数 = 30 + 2 + 1024 = 1056 byte = 0x420** (= PCM data start offset)

PMDDotNET parser L521 literal:
```
if (pcmData.Length < 4 * 256 + 2 + 30) // = 0x420
    reject as malformed
```

### A-2: signature spec (= 30 byte ASCII、 parser check prefix 6 byte)

- file 内 byte sequence: `"ADPCM DATA for  PMD ver.4.4-  "` (= 30 byte、 末尾 2 byte space)
- PMDDotNET parser check (= PCMLOAD.cs L512-515): `pcmData[0..5] == "ADPCM "` (= 先頭 6 byte のみ verify、 ver suffix は parser ignore)
- 軸 G parser spec: 先頭 6 byte `"ADPCM "` (= 0x41 0x44 0x50 0x43 0x4D 0x20) を magic として accept、 残 24 byte は metadata reserved (= ignore)

### A-3: directory entry layout (= 4 byte × 256 entries = 1024 byte)

```
entry index = 0-255 (= voice index、 driver runtime で 1 byte index lookup)

per entry (= 4 byte):
  +0x00  2  START Address word (= LE、 PCMRAM 上 addr)
  +0x02  2  STOP Address word (= LE、 PCMRAM 上 addr)
```

- entry 全 256 個固定、 file 内 0x20-0x41F range
- 未使用 entry の値は file 作者依存 (= 0x0000 sentinel or 不定値)
- entry index は MML voice command (= e.g. `@n`) の n に直接対応 (= 0-255 range で PMD V4.8s 仕様整合)

### A-4: malformed reject pattern (= PMDDotNET parser literal、 軸 G 継承)

| reject pattern | PMDDotNET source line | 軸 G 採否 |
|---|---|---|
| `pcmData.Length < 30` | L497 | **採用** (= header signature 未満 = malformed) |
| `pcmData.Length < 0x420` (= 4*256+2+30) | L521 | **採用** (= directory + signature 未満 = malformed) |
| 先頭 6 byte != `"ADPCM "` | L512-515 | **採用** (= magic mismatch = malformed) |
| 先頭 4 byte == `"PVI2"` + offset 10 == 2 | L503-510 | **scope-out** (= `.PVI` 別 format 別 path、 軸 G `.PPC` 専用) |

### A-5: PMDNEO YM2610(B) V-ROM 直結 mapping (= γ integration design で確定、 α では候補列挙)

YM2610(B) ADPCM-B register layout (= ADR-0043 Annex A reference):
- reg 0x12 = START addr LSB / 0x13 = START addr MSB
- reg 0x14 = STOP addr LSB / 0x15 = STOP addr MSB
- 16-bit register value × 256 = byte addr (= V-ROM 上 byte addr、 256 byte aligned granularity)

`.PPC` directory entry word は PMDDotNET の PCMRAM (= PC-98 OPNA ADPCM RAM、 PMDB2 用) 上の addr であり、 OPNA PCMRAM の addr unit (= word) と YM2610(B) ADPCM-B register の addr unit (= 256 byte aligned word) の対応は **γ integration design で確定** する。 PMDNEO V-ROM 直結 mapping 候補 3 種 (= α 段階候補列挙):

| 候補 | 計算 | 利点 | 欠点 |
|---|---|---|---|
| **mapping-A (= identity)** | `v_rom_word = ppc_word` (= directory word をそのまま reg 書込) | parser 最小、 既存 sample base = 0 fixture で simulation 可 | V-ROM 上 sample 配置位置を 0x0 base 固定、 既存 yaml passthrough sample との共存困難 |
| **mapping-B (= offset 加算)** | `v_rom_word = ppc_word + v_rom_base_offset_word` (= build-time literal base offset) | 既存 sample 領域と共存可、 base offset で配置位置調整 | base offset の literal 化が必要、 driver / runtime symbol で参照 |
| **mapping-C (= scaled、 granularity 変換)** | `v_rom_byte = (ppc_word << k) + v_rom_base_byte_offset` (= OPNA PCMRAM word 単位 → YM2610 byte addr 単位 への scale shift `k`、 `k` の値は γ で OPNA / YM2610 datasheet 対照確認 + fixture 比較で確定) | PMDDotNET 解釈完全踏襲、 granularity 統一 | scale factor `k` の選定根拠が必要、 fixture 設計で対照確認 |

**γ の第一候補 (= α 推奨、 γ で literal 確定)**: **mapping-B (= offset 加算)** = 既存 `samples.inc` build-time embed pattern (= ADR-0021 §c1 + ADR-0043 §決定 4 踏襲) との整合が良く、 軸 G `.PPC` sample 群を V-ROM 上の free area にまとめて配置 + base offset で reg 書込が clean。 mapping-A は識別容易性で β fixture proof 段階の選択肢、 mapping-C は OPNA 互換性検証用 (= γ で OPNA PCMRAM word と YM2610 V-ROM register unit の対応を datasheet + fixture で確定後、 scale factor `k` 確定すれば採用可)。 γ で literal 確定 + δ で driver routine 実装。

**規律違反 risk 防止 (= Codex α review 指摘)**: mapping-B を γ 確定前に δ 実装へ持ち込まないこと (= γ V-ROM register unit 確定 / 既存 yaml passthrough sample との共存配置 確定後の δ 実装)。

### A-6: PMDDotNET source reference (= literal line numbers、 軸 G grep 結果)

| reference 軸 | file | line range | 内容 |
|---|---|---|---|
| `.PPC` format spec literal | `vendor/PMDDotNET/PMDDotNETDriver/PCMLOAD.cs` | L287-298 | header layout コメント (= ASCII art) |
| `.PPC` magic check | 同 | L512-515 | `pcmData[0..5] == "ADPCM "` literal |
| `.PPC` malformed reject (size) | 同 | L497, L521 | size < 30 / < 0x420 reject |
| `.PPC` directory + filename copy to pcmWk | 同 | L555-566 (`write_pcm_main`) | `pcmData[i + 32]` を `pw.pcmWk[]` に copy (= 4 * 256 + 128 byte = directory 1024 byte + filename 128 byte runtime work area 展開) |
| `.PPC` directory parse + RAM write | 同 | L527-647 (`ppc_load_main`) | 256 entry directory + PCM data 本体 transfer |
| `.PPC` PCM transfer stride × 32 | 同 | L630-634 | `r.bx += r.bx` × 5 (= × 32) = 0x400 byte block × 32 stride = 0x8000 byte 一括 store unit (= directory entry word の byte unit 変換ではない) |
| `.PPC` file Open + signature path | 同 | L455-528 (`all_load`) | `.PPC` / `.PVI` / `.P86` 拡張子 fallback chain |
| ADPCM 演奏 main | `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV.cs` | L36-57 (`pcmmain`) | PCM 演奏 main、 軸 G runtime selection γ reference |
| `pcmmain_c_1` keyoff + length tick | 同 | L59-78 | PMDPPZ 流儀 100-150 件 if 分岐 + wrapper の起点 |
| **`.PPC` directory 引き runtime (= 軸 G runtime selection 主軸 reference)** | 同 | L673-684 | voicenum (= `@n`) → `r.ax += r.ax` × 2 (= × 4 byte offset) → `pw.pcmWk[r.bx] + pw.pcmWk[r.bx+1]*0x100` (= START word LE decode) → `pw.pcmstart` / `pw.pcmstop` set (= directory index = voicenum × 4 byte の START word LE + STOP word LE decode、 軸 G runtime selection の central pattern) |
| driver.cs `.PPC` 拡張子 list | `vendor/PMDDotNET/PMDDotNETDriver/driver.cs` | L462 | `string[] ppcExtTbl = new string[] { ".PPC", ".P86", ".PVI" }` literal |
| driver.cs `.PPC` header check | 同 | L427 | `addtionalPMDDotNETOption.PPCHeader = CheckPPC(...)` 経路 |
| PW.cs `ppcFile` field | `vendor/PMDDotNET/PMDDotNETDriver/PW.cs` | L37 | `public string ppcFile = ""` runtime state |

### A-7: 最小 fixture 期待値 (= 1-2 entry imagined byte sequence、 β で実 fixture 生成、 α では imagined byte sequence only)

α 段階の literal expected byte sequence (= 概念上 minimum fixture、 ADR §決定 4 「α では imagined byte sequence only」 規律):

```
offset  byte sequence                                      意図
0x000   41 44 50 43 4D 20 ... (24 byte 任意)              "ADPCM " magic + 24 byte metadata
0x01E   00 04                                              Next START Address = 0x0400 (= 例)
0x020   00 04 80 04                                        entry 0 = START 0x0400 / STOP 0x0480
0x024   80 04 00 05                                        entry 1 = START 0x0480 / STOP 0x0500
0x028-0x41F: 254 × 4 byte = 0xFFFF (= sentinel) or 0x0000 未使用 entry
0x420-0x...: PCM data (= 0x80 byte per entry × 2 entry = 0x100 byte ADPCM data、 任意波形)
```

### β validator 候補 reject 条件 (= γ で literal 確定、 α では候補列挙)

β parser / validator proof spike で実装する reject 条件候補 (= A-4 size / magic に加えて semantic レベル check):

| 候補 reject pattern | check 内容 | 採否判断 |
|---|---|---|
| `entry.START > entry.STOP` (= START が STOP より大きい entry) | directory 各 entry で START word ≤ STOP word | **β default 採用** (= ADPCM-B keyon 動作不定 sample reject) |
| `entry.STOP > Next START Address` (= 末尾 sample の STOP 超過) | directory 各 entry で STOP ≤ Next START word | β default 採用 (= sample 範囲外 reject) |
| `Next START Address > file length-based end` (= file 末尾超過) | `Next START word × scale + 0x420 > pcmData.Length` (= scale は γ で確定) | γ 確定後 β で literal | 
| 未使用 entry (= START == 0 && STOP == 0) | reject せず skip (= voice index lookup で silent fallback) | β default skip (= reject ではない) |
| directory entry の重複 (= 複数 voicenum (= entry index) が同一 START/STOP range を指す) | informational warn のみ (= aliasing として valid、 reject せず) | β warn (= reject せず) |

### β 実 fixture 生成方針 (= α では生成なし、 β scope)

β sub-sprint で実 fixture を **生成** する:
- 既存 `vendor/PMDDotNET/` 配下 `.PPC` sample 探索 (= `find` で結果空 (= α 確認済、 PMDDotNET 自体は .PPC bundle なし、 PMDB2 同梱 sample に依存))
- PMD V4.8s source (= `vendor/pmd48s/`) 配下の sample reference 検索 (= β で探索)
- spike script で **byte-level emit** (= byte-level layout を spike Python で literal emit、 doc spec から逆算した minimum valid `.PPC` 1-2 entry) を β でのみ実装
- spike emit + magic / directory / data 各 byte literal 期待値 assert + 候補 reject 条件 (= 上記 table) literal 検証

### A-8: 軸 G scope-out (= ADR-0048 §決定 5 non-goal 補強、 別 format / 別軸)

| format / 軸 | 状態 | 理由 |
|---|---|---|
| `.PVI` (= PVI2 magic) | scope-out (= 別 path) | PCMLOAD.cs L503-510 で別 path 分岐、 軸 G `.PPC` 専用 |
| `.P86` (= PMD86 用 sample pack) | scope-out (= 別 path) | PCMLOAD.cs L432-437 で別 path 分岐、 86B/P86DRV 経路 |
| `.PPS` (= PMD PPS、 SSG/PPSDRV 用) | scope-out (= 別 path) | PCMLOAD.cs L343-415 別 routine、 SSG 軸範囲 |
| `.PPZ` (= PMDPPZE 用、 EMS bank) | scope-out (= 別 path) | PMDPPZE 経路、 軸 G で扱わず |
| .PPC 内 PVI 混在 (= 先頭 PVI2 magic 検出時) | scope-out (= 別 format 別 ADR 候補) | A-4 reject pattern table literal |

## Annex B: ADR-0043 軸 C との関係 + 軸間衝突確認 (= ADR-0041 §決定 1)

ADR-0041 §決定 1 (= 軸間衝突回避) に従い、 本軸 G と他軸の触接面確認:

| 軸 | 触接面 | 衝突 risk | 対処 |
|---|---|---|---|
| 軸 A (= sample provenance β) | sample provenance 領域、 軸 A は ADPCM-A BD 系 sample、 軸 G は ADPCM-B `.PPC` sample bank | 衝突なし (= 独立 asset 系統) | n/a |
| 軸 C (= ADPCM-B、 ADR-0043 完了) | ADPCM-B driver routine + sample_table_id (= 0xFD32) | **既存 routine 不可触 + selection id 共用** | §決定 3 production-ready 保護 + 新規 routine 並設 |
| 軸 F (= MML compiler 拡張、 ADR-0044 完成扱い) | MML compiler / driver / partWork | 衝突なし (= 軸 G は driver runtime parse のみ、 MML compiler touch なし) | n/a |
| 軸 0 (= orchestration setup、 ADR-0041) | 規律確立 ADR、 driver / source touch なし | 衝突なし | n/a |
| 軸 B 候補 (= Phase 2 FM/SSG driver フルスクラッチ、 ADR-0045 候補) | driver source、 軸 B 着手時 driver source 大規模改修想定 | 軸 G δ の driver touch との時系列調整必要 | 軸 B 着手は軸 G 進行後 (= dashboard §後続軸候補表 literal)、 並走時は ADR-0041 §決定 3 軸別 wip- branch 集約 + 主軸 merge orchestration |
| 軸 D 候補 (= WebApp 最小骨格、 ADR-0046 候補) | backend で軸 G `.PPC` converter 経路接続 | 軸 G ε 完了後の接続点予約のみ | n/a (= 軸 G 完成後の議題) |
| **driver SRAM 領域** | 0xFD32 `sample_table_id` 共用 (= ADPCM-A / ADPCM-B / 軸 G 同じ id で連動切替) | 競合 write なし (= 1 byte 共用)、 §決定 3 で literal | n/a |
| **共有 source file** | `src/driver/standalone_test.s` (= L2692 `adpcmb_keyon` + 軸 G で新規 routine 追加箇所、 commit 衝突 risk あり) | 軸 G δ で新規 routine 追加 only (= 既存 ADR-0043 routine 不可触) | ADR-0041 §決定 3 軸別 wip- branch 集約 + 主軸 merge orchestration、 sub-agent 内自律 commit で本拠地直接 commit 禁止 |

## Annex C: doc-only filing 規律 (= 決定 4 補足、 後続 sub-sprint との分離 literal)

本 ADR-0048 起票 commit (= 33rd session 候補 3 主 sprint = 主軸 fallback 経路) は:

- file 変更 = `docs/adr/0048-pmdneo-axis-g-ppc-parser-and-runtime-dynamic-sample-supply.md` 新規 only (= 本 file)
- driver source / runtime / vendor / spike script / fixture 完全不変
- dashboard `docs/parallel-axes-dashboard.md` 軸 G 行 update は別 commit (= 本 commit に含めない、 候補 4 PR #36 で起票準備済 + 起票後の状態 update は ADR-0048 起票 commit 同時 or 後続 commit で行う、 本 ADR 起票 commit は ADR file のみ)

## sub-sprint α 完了 (= 33rd session、 主軸単独実装 + Codex layer 2 review 経由)

### 実装 deliverable (= doc-only、 Codex layer 2 revise round 1 反映済)

`docs/adr/0048-pmdneo-axis-g-ppc-parser-and-runtime-dynamic-sample-supply.md` 更新:

1. **Annex A literal 化** (= placeholder 7 件 → A-1〜A-8 全 8 section literal、 Codex revise must-fix 反映済):
   - A-1: `.PPC` file header layout byte-level (= 0x000 signature 30 byte + 0x01E Next START 2 byte + 0x020 directory 1024 byte + 0x420 PCM data、 合計 header 1056 byte = 0x420) + directory source attribution (= L287-292 spec + L555-566 copy to pcmWk、 L630-634 は transfer stride ×32 (= directory parse ではない))
   - A-2: signature spec (= 30 byte ASCII "ADPCM DATA for  PMD ver.4.4-  "、 parser check prefix 6 byte "ADPCM ")
   - A-3: directory entry layout (= 4 byte × 256 entries、 START word LE + STOP word LE)
   - A-4: malformed reject pattern 4 種 (= size < 30 / size < 0x420 / magic mismatch / PVI2 別 path)
   - A-5: PMDNEO YM2610(B) V-ROM 直結 mapping 候補 3 種 (= identity / offset 加算 / scaled `× k` scale shift で γ 確定、 γ の第一候補 = mapping-B offset 加算、 規律違反 risk 防止 = mapping-B を γ 確定前に δ 実装へ持ち込まない)
   - A-6: PMDDotNET source reference literal 12 件 (= PCMLOAD.cs L287-298 spec + L497/L512-515/L521/L555-566 directory copy/L527-647 parse/L630-634 transfer stride ×32 + PCMDRV.cs L36-57 pcmmain + L59-78 + **L673-684 directory 引き runtime (= 軸 G runtime selection 主軸 reference)** + driver.cs L462/L427 + PW.cs L37 ppcFile field)
   - A-7: 最小 fixture imagined byte sequence (= 0x000-0x420 layout + 1-2 entry example、 α では imagined byte sequence only、 β で実 fixture 生成 spike emit) + β validator 候補 reject 条件 table 5 件 (= START ≤ STOP / STOP ≤ Next START / Next START scale check / 未使用 entry skip / 重複 entry warn)
   - A-8: 軸 G scope-out 別 format 5 種 (= .PVI / .P86 / .PPS / .PPZ / .PPC 内 PVI 混在)
2. **§決定 2 補正** (= PCMDRV.cs only → PCMLOAD.cs + PCMDRV.cs 両方 reference):
   - PCMLOAD.cs (= 1256 行、 α 実測) を **byte-level format spec ground truth** として追加
   - PCMDRV.cs (= 1063 行、 α 実測) は **runtime selection 経路 reference + L673-684 directory 引き runtime 主軸 reference** として位置付け
   - α finding として「ADR-0048 起票 commit 段階では PCMDRV.cs のみ reference していたが、 format parser は PCMLOAD.cs (= L260-647) と判明」 literal 化
3. **§決定 4 補正** (= 「α では imagined byte sequence only、 β で実 fixture 生成」 規律 A-7 と整合 literal)
4. **sub-sprint chain 表 update**: α 完了 + β「次」 (= parser / validator proof spike + minimum fixture 生成)

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化)

- **layer 2 review chain** (= session 019e3b50-... 流用):
  - round 1 = α format archaeology + Annex A literal 化 = **revise** (= must-fix 5 件 + nice-to-have 3 件 + 規律違反 risk 2 件)
  - round 2 = revise round 1 反映後 = **revise** (= must-fix 5 件 全 FOUND + 追加 must-fix 3 件 = vendor wav commit 汚染防止 literal + self-approve 表現修正 + PCMLOAD/PCMDRV 役割衝突解消 + 追加 nice-to-have 1 件)
  - round 3 = revise round 2 反映後 = **approve** (= 追加 must-fix 3 件 + 追加 nice-to-have 1 件 全反映確認、 追加 must-fix / nice-to-have / 規律違反 risk なし、 α 完了 commit GO + sub-sprint β 着手 GO)
- **主軸 fallback regime** (= sub-agent isolation 5 連続 fail 経験踏襲、 主軸単独実装 default)
- **Codex layer 1 不要** (= doc-only sprint、 driver / runtime touch なし、 layer 2 review のみで sufficient)

### verify gate (= α は doc-only、 spec consistency check)

- Annex A spec literal と PCMLOAD.cs L287-298 spec コメント整合 (= byte offset / size / signature 完全一致確認)
- Annex A parser code reference (= L497 / L512-515 / L521 / L527-647 / L630-634) と PCMLOAD.cs 実 code 整合 (= grep + Read 確認済)
- §決定 5 non-goal list 10 項目と Annex A-8 軸 G scope-out 別 format 5 種 互換性 (= 重複なし、 補強関係)
- driver / runtime / vendor / spike / fixture 完全不変 (= ADR file 更新 only、 doc-only sprint 規律遵守)

### scope-out 確認 (= ADR §決定 4 doc-only filing 規律 + §決定 5 non-goal list + Annex A-8 別 format 全 完全遵守)

- parser 実装なし (= β sub-sprint で起動)
- driver source touch なし (= δ sub-sprint で起動、 最小限のみ)
- vendor source touch なし (= 軸 G 全 sub-sprint 通して vendor 不可触)
- `.PPC` fixture 新規追加なし (= β で生成、 α では imagined byte sequence のみ)
- 軸 C 再オープン / Surge XT / vendor wav cleanup / 軸 B / 軸 F MML compiler すべて非 touch

### sub-sprint chain 進捗 update (= sub-sprint chain 表 reflect)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= 本 commit、 Annex A literal + §決定 2 補正) | (= 本 commit hash) |
| β | **次** (= parser / validator proof spike + minimum fixture 生成) | - |
| γ | 未着手 (= integration design + V-ROM mapping 確定) | - |
| δ | 未着手 (= runtime selection proof driver touch 最小) | - |
| ε | 未着手 (= integration + audition gate) | - |
