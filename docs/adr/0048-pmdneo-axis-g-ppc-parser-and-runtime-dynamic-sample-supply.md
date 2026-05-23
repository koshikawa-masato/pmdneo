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
- **scope-in** (= 35th session γ revise must-fix #3 反映、 案 C 部分 runtime parse 経路 literal 明確化):
  - `.PPC` **runtime directory lookup** (= directory entry index → START/STOP word decode、 ROM 内 embed directory binary を driver runtime で参照) ← 旧記述「`.PPC` format driver parse (= header / directory / sample entry 解析)」 は full binary parse と読めるため明確化
  - `.PPC` runtime sample selection (= mapping-B + selection key bit7、 sample addr 動的解決)
  - PMDPPZ 流儀 reference → YM2610(B) V-ROM 直結 mapping 設計 (= 案 C 経路: directory 部分のみ ROM embed + sample data は既存 vromtool 経路継続)
  - 既存 sample_table_id selection arch (= ADR-0023/0024/0025) との integration design
  - ADPCM-B 軸 (= ADR-0043) production-ready 保護 (= 既存 yaml passthrough 並走 + 既存 vromtool 経路保護)
  - 新規 generator script (= 仮称 `scripts/ppc-to-ngdevkit.py`、 vromtool 外側、 `.PPC` → directory binary embed + sample data 既存 vromtool 経路へ渡す)
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

### 決定 8: 軸 G γ V-ROM mapping 確定 = mapping-B (= offset 加算) + selection key δ defer + δ 経路 = 案 C (= 部分 runtime parse)

軸 G γ sub-sprint で V-ROM 直結 mapping を **mapping-B (= offset 加算)** に literal 確定する。 mapping-A (= identity) + mapping-C (= scaled × k) は reject。 selection key (= `.PPC` source vs yaml passthrough source 判定軸) は δ で literal 確定 (= γ では候補列挙のみ)。

**35th session vromtool finding 反映**: `vromtool` は ngdevkit 外部 tool (= brew install ngdevkit 配布 binary、 repo 内に source なし、 PMDNEO 側で **拡張不能**)。 旧 literal「vromtool.py 拡張で `.PPC` file 取り込み」 は **stale** = vromtool 自体は拡張不能、 .PPC 取り込み経路は **vromtool 外側で実装** する形に修正。 §決定 8 末尾「δ 経路 = 案 C (= 部分 runtime parse) 採用」 を新規追加 (= Codex layer 2 35th session 開始時 round 1 approve)、 mapping-B 式は維持 (= resolution timing が runtime directory lookup 側になる点を明記)。

#### mapping-B 採用 (= 確定式)

```
v_rom_word = ppc_word + v_rom_base_offset_word
reg 0x12 = v_rom_word & 0xFF       (= START LSB)
reg 0x13 = (v_rom_word >> 8) & 0xFF (= START MSB)
reg 0x14 = v_rom_stop_word & 0xFF       (= STOP LSB)
reg 0x15 = (v_rom_stop_word >> 8) & 0xFF (= STOP MSB)
where v_rom_stop_word = ppc_stop_word + v_rom_base_offset_word
```

- `ppc_word` = `.PPC` directory entry の START / STOP word (= LE 16-bit、 Annex A-3 literal)
- `v_rom_base_offset_word` = build-time literal symbol (= 仮称 `PPC_VROM_BASE_OFFSET_WORD`、 driver source + samples.inc literal、 値は δ で `scripts/ppc-to-ngdevkit.py` (= vromtool 外側 新規 generator) 生成時に確定)
- YM2610(B) ADPCM-B reg 0x12-0x15 = 16-bit register × 256 = byte addr (= V-ROM 上 byte addr、 256 byte aligned granularity、 ADR-0043 Annex A reference)

#### mapping-A reject 根拠

| reject 軸 | 根拠 |
|---|---|
| V-ROM base = 0 固定衝突 | 既存 yaml passthrough sample 領域 (= ADR-0043 `adpcmb_sample_beat` + γ-2 silence_b + γ-2 sample B) と addr 衝突、 共存困難 |
| 設計言語統一性 | ADR-0021 §c1 + ADR-0043 §決定 4 `samples.inc` build-time embed pattern が「sample 群を V-ROM 上 free area にまとめて配置」 を前提、 base = 0 固定は逸脱 |
| 拡張性 | 将来 `.PPC` 複数 file 取り込み時に base offset 切替で配置領域分離可能、 base = 0 固定では対応不能 |

#### mapping-C reject 根拠

| reject 軸 | 根拠 (= γ revise round 1 must-fix #1 反映済) |
|---|---|
| YM2610 register unit 確認済 + 直結経路 | (1) `src/driver/PMD_Z80.inc` L2186 literal `byte 0-1: start address LSB/MSB (= 256 byte unit)` (= PMDNEO driver source で 256 byte unit 確定) + (2) `src/driver/standalone_test.s` L2712-2734 (= ADR-0043 既存 `adpcmb_keyon_have_sample` routine、 reg 0x12/0x13/0x14/0x15 直接書込 + 16-bit value で 256 byte boundary literal) + (3) YM2610 datasheet ADPCM-B section (= 外部 reference、 register × 256 = byte addr) で literal 確認済 |
| OPNA 側は mapping-B 採用下で **unit 確定不要** | PMDDotNET `PCMDRV.cs` L673-684 (= 軸 G runtime selection 主軸 reference、 Annex A-6 literal) は voicenum × 4 byte offset → `pw.pcmWk[r.bx] + pw.pcmWk[r.bx+1]*0x100` (= LE 16-bit decode) → `pw.pcmstart` / `pw.pcmstop` set = directory entry word を **OPNA ADPCM-B register に直接書込まれる pcmstart/pcmstop word として decode**。 PMDDotNET 解釈で directory entry word の OPNA register 単位 conversion は **不在** (= 直結経路)。 mapping-B 採用下では PMDNEO YM2610 V-ROM 直結のため OPNA PCMRAM 概念非適用 = OPNA 側 granularity 確定そのものが不要、 mapping-C scale factor `k` ≠ 0 の必要性なし |
| PMDDotNET × 32 解釈訂正済 (= mapping-C 採用根拠の不在裏付け) | PCMLOAD.cs L630-634 の `r.bx += r.bx` × 5 (= × 32) は **PCM data transfer stride 計算** (= 0x400 byte block × 32 stride = 0x8000 byte 一括 store unit) であり、 directory entry word の byte unit 変換ではない (= Annex A-1 source attribution literal、 α revise round 1 must-fix #3 反映済)。 mapping-C 採用根拠として誤帰属しがちな × 32 は transfer stride に属する |
| 不要な複雑性 | scale factor 確定根拠が不在 (= mapping-C scale factor `k` の datasheet/source 裏付け不在) + mapping-B (= offset 加算) で sufficient (= V-ROM 配置領域分離 + 既存 yaml passthrough 並走可能)、 mapping-C 採用は不要な実装複雑性 |

#### `v_rom_base_offset_word` 配置設計 (= δ scope literal、 案 C 部分 runtime parse 経路、 γ では設計のみ)

- 値は **新規 generator script (= 仮称 `scripts/ppc-to-ngdevkit.py` 等、 vromtool 外側)** で生成、 既存 yaml passthrough sample 配置領域 size から計算
- 既存 yaml 領域は不可触 (= ADR-0043 production-ready 経路保護)、 `.PPC` sample 群は **後方** 配置
- **vromtool は外部 tool で拡張不能** (= 35th session finding) のため、 案 C 経路で実装:
  - **sample data**: `.PPC` から ADPCM-B raw byte stream を抽出 → wav 経由 or 直接 ngdevkit-tool に渡す既存経路で V-ROM 焼き込み (= 既存 vromtool 経路継続、 sample data 配置不変)
  - **directory binary**: `.PPC` directory (= 256 entries × 4 byte = 1024 byte) を **ROM 内別領域に embed** (= 仮称 `PPC_DIRECTORY_BASE` symbol、 新規 generator で directory binary 生成 + linker exposure)
  - **offset 計算**: `PPC_VROM_BASE_OFFSET_WORD` = vromtool 自動 layout 後の `.PPC` sample 配置 base addr (= 既存 yaml sample 配置領域後方、 generator が samples.inc 解析 or vromtool log 解析で算出)
- driver runtime で `PPC_VROM_BASE_OFFSET_WORD` symbol 参照 + `PPC_DIRECTORY_BASE` symbol 経由 directory entry index → START/STOP word decode (= δ で driver routine 実装)

#### selection key 候補列挙 (= δ で literal 確定、 γ では候補のみ)

`.PPC` source vs yaml passthrough source の判定 key は δ で literal 確定。 γ scope では候補列挙のみ:

| 候補 | 判定軸 | 利点 | 欠点 (= γ revise round 1 must-fix #2 反映済 = 表記矛盾解消) |
|---|---|---|---|
| 候補-1 | `sample_table_id` (= 0xFD32) 上位 1 bit (= bit7 set / clear で source 判別) | 既存 SRAM 領域共用、 ADR-0043 §決定 3 整合 | id range **0-127 (= bit7 clear) = 既存 yaml passthrough / ADR-0043 id 範囲 (= id 0x00 yaml beat + id 0x01 yaml silence_b 等)** / **128-255 (= bit7 set) = `.PPC` source 経路 (= 新規)**、 selection arch 上位 1 bit 拡張 |
| 候補-2 | 別 SRAM 1 byte 領域 (= 仮称 0xFD33 等) で source switch | source switch 明確、 既存 id 経路と独立 | SRAM 領域追加、 ADR-0043 §決定 3 整合確認 |
| 候補-3 | voicenum range (= 0-127 yaml / 128-255 `.PPC`) で implicit switch | 既存 selection key 不変、 voicenum 直結 | voicenum range 分割の固定 literal 化、 拡張性低 |
| 候補-4 | MML directive (= e.g. `#PPCFile` 等) で source switch | source switch を MML 側で明示 | MML compiler 拡張 (= 軸 F 完成扱い、 F-2-A defer と矛盾 risk) |

δ で literal 確定軸: ADR-0043 §決定 3 整合 + 既存 SRAM 領域経済性 + selection arch 拡張性 + MML compiler touch なし (= 軸 F defer 維持) の 4 軸で評価、 候補-1 (= sample_table_id 上位 1 bit、 bit7 set = `.PPC` source / bit7 clear = 既存 yaml passthrough) を **δ 第一候補** (= γ で literal 確定ではなく δ で確定軸として明示)。

#### ADR-0043 production-ready 経路保護 literal

mapping-B 確定下で既存 ADR-0043 routine 経路は完全不可触:

- `pmdneo_select_adpcmb_sample_pointer` (= routine 定義) = 不可触
- `adpcmb_sample_beat` literal table (= 4 byte BEAT_START_LSB/MSB + BEAT_STOP_LSB/MSB) = 不可触
- voice index → sample id lookup table (= 2 entry sample table) = 不可触
- `sample_table_id` (= 0xFD32) ADPCM-A / ADPCM-B 軸共用方針 = 維持 (= ADR-0043 §決定 3 literal)
- 軸 G `.PPC` 経路は **新規 routine 追加 only** (= δ で `pmdneo_select_adpcmb_ppc_pointer` 等新規追加、 既存 selector と並走、 selection key で分岐)
- byte-identical 維持 (= 既存 ADR-0043 fixture register write sequence 不変、 δ verify gate)

#### δ verify gate 推奨 (= γ revise round 1 nice-to-have #2 反映、 unit / offset 誤り早期検出)

δ runtime selection proof 段階で、 mapping-B 式の unit / offset 誤り早期検出のため次の literal assert fixture を verify gate に組込推奨:

- fixture 条件: `ppc_word != 0` かつ `PPC_VROM_BASE_OFFSET_WORD != 0` (= 両者 nonzero で identity と offset 加算の差を明確化)
- expected: reg 0x12-0x15 書込 value = `(ppc_start_word + PPC_VROM_BASE_OFFSET_WORD)` LSB/MSB / `(ppc_stop_word + PPC_VROM_BASE_OFFSET_WORD)` LSB/MSB を **literal value で assert** (= 0xFF mask + 8-bit shift 整合確認)
- ymfm-trace primary gate (= 既存 verify-j-part-fixture-driven.sh 経路拡張): 既存 ADR-0043 fixture (= ppc 経路に流れない = bit7 clear id) byte-identical 維持 + 新規 `.PPC` fixture (= bit7 set id) で reg 0x12-0x15 期待 literal 一致確認
- 両 fixture 並走で「mapping-B 採用 + selection key 候補-1 bit7 分岐 + ADR-0043 既存経路保護」 を 1 set の trace で完全確認

#### δ 実装経路 = 案 C (= 部分 runtime parse) 採用 (= 35th session 開始時 Codex layer 2 round 1 approve、 vromtool finding 反映)

vromtool 拡張不能 finding (= 35th session 開始時) を踏まえ、 δ 実装経路を **案 C (= 部分 runtime parse)** に literal 確定する。 案 A (= build-time emit) + 案 B (= 真の runtime parse、 full .PPC binary embed) は reject。

##### 案 C (= 部分 runtime parse) 採用 (= 確定)

- **sample data**: `.PPC` から ADPCM-B raw byte stream を抽出 → 既存 vromtool 経路 (= yaml + adpcm_b passthrough) で V-ROM 焼き込み (= 既存経路継続、 ADR-0043 §決定 4 yaml + adpcm_b 経路と同型、 vromtool 外側の新規 generator が .PPC → 個別 sample file or yaml entry に展開)
- **directory binary**: `.PPC` directory (= 256 entries × 4 byte = 1024 byte、 Annex A-3 layout literal) を **ROM 内別領域に embed** (= 仮称 `PPC_DIRECTORY_BASE` symbol、 新規 generator が directory binary 生成 + assembler `.incbin` or `.db` literal emit + linker exposure)
- **driver runtime**: `pmdneo_select_adpcmb_ppc_pointer` (= 新規 routine) で voicenum × 4 byte offset → `PPC_DIRECTORY_BASE` から START/STOP word decode (= mapping-B mapping_B 式 + `PPC_VROM_BASE_OFFSET_WORD` 加算) → reg 0x12-0x15 書込
- **selection key**: 候補-1 (= sample_table_id bit7 set/clear) で source 分岐 (= bit7 clear = 既存 ADR-0043 `pmdneo_select_adpcmb_sample_pointer` 経路 / bit7 set = 新規 `pmdneo_select_adpcmb_ppc_pointer` 経路)
- **新規 generator script**: 仮称 `scripts/ppc-to-ngdevkit.py` (= vromtool 外側、 `.PPC` 取り込み + directory binary 生成 + adpcm_b raw byte 展開 + yaml entry 生成 or 既存 yaml に追記)
- **mapping-B 式は維持** (= resolution timing が runtime directory lookup 側、 driver runtime で `ppc_word + base_offset_word` 計算)

##### 案 A (= build-time emit) reject 根拠

- 軸 G **runtime parse scope を捨てる** = ADR-0048 §軸 G scope-in literal (= `.PPC` runtime sample selection / directory 引き) 違反
- runtime selection (= bit7 分岐) のみ実装するが、 directory 動的解決は build-time に展開 = 軸 G の本来意義 (= runtime parse) 縮小
- **設計根本分岐 risk** = 軸 G scope-in literal 変更必要、 user escalate 候補

##### 案 B (= 真の runtime parse、 full .PPC binary embed) reject 根拠

- ROM 領域 layout 新設 + vromtool 完全 bypass + 別 generator + driver 完全 runtime parse 実装 = scope 最大
- 既存 vromtool 経路 (= ADR-0043 production-ready 経路) を破壊する設計判断 = **ADR-0043 production-ready 経路保護違反 risk**
- sample data 抽出も独自経路 (= vromtool 経由しない) = ngdevkit 標準 build pipeline 逸脱

##### ROM directory region 設計 (= 案 C、 δ で literal 確定)

- format: `.PPC` directory 1024 byte (= 256 entries × 4 byte) を `.incbin` 経由 ROM embed or `.db` literal emit
- alignment: 4 byte 境界 (= directory entry 単位)、 ngdevkit linker section に新規 region 追加 or 既存 PROM section の末尾 append
- symbol naming: `PPC_DIRECTORY_BASE` (= 仮称、 driver source / generator script literal)
- linker exposure: ngdevkit `vendor/ngdevkit-examples/00-template/Makefile` 経路で directory binary を Z80 source に include (= `scripts/ppc-to-ngdevkit.py` が `assets/samples.inc` 末尾 or 別 inc file に append、 driver source は `.include` で取り込み)
- δ で literal 確定 (= γ では設計概要のみ)

## sub-sprint chain 進捗 (= 起票時 literal、 後続 sub-sprint 完了で update)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= ADR-0048 PR #39 MERGED 9b52af3、 Annex A literal 化 + §決定 2 補正、 doc-only) | 80fd219 |
| β | **完了** (= PR #41 MERGED f79f5e5、 `scripts/ppc-parser-spike.py` 新規 + 6/6 test PASS、 doc + spike script) | bd9401a |
| γ | **完了** (= PR #43 MERGED 2923c3a、 §決定 8 V-ROM mapping mapping-B 確定 + Annex A-5 確定 update + integration design literal、 doc-only) | 12fcf69 |
| γ revision | **完了** (= PR #45 MERGED ee40987、 35th session vromtool finding 反映 + 案 C 採用 ADR fix、 Codex 3 round chain approve) | bfc2e5e |
| **δ** | **完了** (= PR #47 MERGED 5f91b3a、 案 C 部分 runtime parse 実装、 verify gate 7/7 PASS、 既存 ADR-0043 byte-identical 維持) | 6 commit chain (= 59e1acb + 216f520 + d53efc7 + 5e677ba + 5755934 + MAME 起動確認) |
| **ε** | **partial complete** (= 36th session、 PR #49 で round 2 fix 後 越川氏 audition で **PPC audible proof approve / integration 同居 reject**、 integration 同居は **ζ 候補へ defer**、 **ADR-0048 Draft 維持 = Accepted 化保留**) | PR #49 = cf64d60 + 1ed5fe4 + 本 doc commit |
| **ζ (= 候補予約)** | **未着手** (= integration 同居 fixture + TIMER-B IRQ rate 改修 or MML 拡張 scope、 別 sub-sprint or 別 ADR で起票候補、 着手時期 user 判断仰ぎ) | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

- **やりたいこと**: ADPCM-B 軸 (= 軸 C) は完成して production-ready になったが、 sample 供給経路は build 時に yaml で hand-written embed する形 (= ADR-0043 §決定 2 で `.PPC` driver parse は scope-out) のままで、 PMD V4.8s `.PPC` (= PMDB2 用 ADPCM RAM sample pack) を driver runtime で directory 引きする経路がまだない。 これを ADR-0043 §決定 2 literal 後続 ADR 経路で新規軸 G として立ち上げる。
- **前提**: 32nd session 末で軸 C 完了 (= ADR-0043 Accepted、 越川氏 audition approve)、 全 OPEN PR 0 件、 33rd session 起点で Codex layer 2 round 1 approve (= 候補 4 → 候補 3、 主軸推奨完全一致)、 user 明示永続 scope-out 9 項目 (= Surge XT / vendor wav / 軸 C 再オープン 等) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下。
- **やったこと**: ADR-0048 起票 = 7 §決定 (= sub-sprint 5 段 α/β/γ/δ/ε + `.PPC` ground truth PMDDotNET `PCMDRV.cs` + integration design ADPCM-B 保護 + doc-only filing + non-goal 列挙 + ADR-0041 経路継承 + dashboard 更新規律)、 軸 G 命名 + scope-in/scope-out literal + Codex layer 2 推奨 5 段構成踏襲、 ADR-0043 既存 routine 不可触 + yaml passthrough 並走方針、 doc-only commit で driver / runtime / vendor 完全不変。
- **結果**: doc-only ADR Draft 起票 (= 本 commit)、 driver / runtime / vendor 完全不変、 後続 sub-sprint α/β/γ/δ/ε 着手準備完了、 dashboard 軸 G 行 update + ADR-0048 Draft 起票済 literal 反映。
- **解釈**: ADR-0043 ADPCM-B native path 完成段階の自然な後続として、 PMD V4.8s `.PPC` driver runtime parse + sample bank 動的供給を軸 G で実現する。 ADPCM-A multi-table proof (= ADR-0025) pattern + ADPCM-B sample_table_id integration (= ADR-0043 γ) pattern を継承しつつ、 PMDPPZ 流儀 (= PMDDotNET `PCMDRV.cs` 1063 行) を ground truth source として byte-level parser spec を α で確定、 β で spike proof、 γ で integration design、 δ で runtime selection proof、 ε で audition gate と段階的に進める。 5 段化は format/parser/integration/runtime/audition 軸分離 (= Codex 推奨) + ADR-0043 4 段 ch 軸不要構成からの 1 段増。
- **次の step (= 起票時 = α 着手予定)**: sub-sprint α 着手 = `.PPC` format archaeology + fixture contract 確定 = PMDDotNET `PCMLOAD.cs` (= 1256 行、 byte-level format parser ground truth) + `PCMDRV.cs` (= 1063 行、 runtime selection reference) grep + byte-level parser spec literal + 最小 fixture (= 1-2 entry) imagined byte sequence ADR Annex 化 + Codex layer 2 review。 本 ADR-0048 起票 (= 軸 G α task の前段 = ADR doc 起票そのもの) と sub-sprint α (= format archaeology) は **別 step** である点に注意 (= ADR-0043 同形 pattern)。
- **α 完了後 次の step (= α 完了 commit reflect)**: sub-sprint β 着手 = parser / validator proof spike + minimum fixture **生成** (= α では imagined byte sequence only、 β で実 fixture spike emit + reject 条件 literal 検証)、 driver / runtime / vendor 完全不変、 Annex A-7 β validator 候補 reject 条件 table から β default 採用 4 件 + γ 確定 1 件選定。
- **β 完了後 次の step (= β 完了 commit reflect)**: sub-sprint γ 着手 = integration design + V-ROM mapping 確定 (= Annex A-5 候補 3 種から確定) + samples.inc / sample_table_id / yaml passthrough 接続方針確定 + ADR-0043 production-ready 経路保護 literal、 driver / runtime / vendor 完全不変 (= 設計のみ doc-only)。
- **γ 完了後 次の step (= γ 完了 commit reflect、 35th session 開始時 vromtool finding 反映済)**: sub-sprint δ 着手 = runtime selection proof = mapping-B 実装 (= driver source `standalone_test.s` 新規 routine 追加 only、 既存 ADR-0043 routine 不可触) + selection key 候補-1 第一候補 確定 (= sample_table_id bit7) + **案 C (= 部分 runtime parse) 経路**: 新規 generator script `scripts/ppc-to-ngdevkit.py` (= vromtool 外側、 `.PPC` → directory binary embed + sample data 既存 vromtool 経路へ渡す) + ROM 内 directory 別領域 embed (= `PPC_DIRECTORY_BASE` symbol) + driver runtime で directory 引き + 実 `.PPC` minimum fixture 1-2 entry 生成 + verify gate (= ymfm-trace primary gate + driver byte-identical + 既存 ADR-0043 fixture regression + 新規 .PPC fixture reg 0x12-0x15 literal assert)、 最小 driver touch、 ADR-0043 既存 routine 完全不可触、 既存 vromtool 経路保護。

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

### A-5: PMDNEO YM2610(B) V-ROM 直結 mapping (= γ で確定 = mapping-B、 α では候補列挙)

> **γ 確定**: mapping-B (= offset 加算) **採用確定** (= ADR-0048 §決定 8 literal)、 mapping-A / mapping-C **reject**。 詳細式 + reject 根拠 + selection key δ defer 規律は §決定 8 参照。 本 section は α 段階の候補列挙 literal を歴史保存。


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

> **γ 確定 result (= §決定 8 literal、 γ revise round 2 + 35th session vromtool finding 反映済)**: mapping-B 採用 = `v_rom_word = ppc_word + v_rom_base_offset_word` + `v_rom_base_offset_word` は build-time literal symbol `PPC_VROM_BASE_OFFSET_WORD` (= δ で `scripts/ppc-to-ngdevkit.py` (= vromtool 外側 新規 generator、 35th session 採用 案 C 経路) 生成時に値確定)。 mapping-A reject = V-ROM base = 0 固定で既存 yaml passthrough sample 衝突。 **mapping-C reject = (1) YM2610 register unit 256 byte aligned 確認済 (= `src/driver/PMD_Z80.inc` L2186 + `standalone_test.s` L2712-2734 + YM2610 datasheet) + (2) OPNA 側 unit 確定不要 (= mapping-B 採用下で V-ROM 直結のため OPNA PCMRAM 概念非適用、 PMDDotNET 解釈で directory entry word は OPNA register 直結 = PCMDRV.cs L673-684) + (3) PMDDotNET × 32 解釈訂正済 (= transfer stride、 directory parse ではない) + (4) 不要複雑性 (= mapping-B で sufficient)** = scale factor `k` ≠ 0 不要、 §決定 8 4-row reject table 参照。

**規律違反 risk 防止 (= Codex α review 指摘)**: mapping-B を γ 確定前に δ 実装へ持ち込まないこと (= γ V-ROM register unit 確定 / 既存 yaml passthrough sample との共存配置 確定後の δ 実装)。 γ 確定後 (= 本 §決定 8) は δ で driver routine 実装可。

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
| **YM2610 ADPCM-B reg unit 256 byte literal (= γ revise round 1 nice-to-have #1 反映 datasheet citation 内部 source)** | `src/driver/PMD_Z80.inc` | L2186 | コメント literal `byte 0-1: start address LSB/MSB (= 256 byte unit)` (= PMDNEO driver source 内 datasheet integration、 γ §決定 8 mapping-C reject 根拠 a 補強 source) |
| YM2610 ADPCM-B reg 直接書込 routine | `src/driver/standalone_test.s` | L2712-2734 (`adpcmb_keyon_have_sample`) | ADR-0043 既存 routine、 reg 0x12/0x13/0x14/0x15 直接書込 + 16-bit value で 256 byte boundary literal (= γ §決定 8 mapping-B 採用式の driver source 整合確認) |
| YM2610 ADPCM-B reg datasheet citation (= 外部 reference) | YM2610 Application Manual ADPCM-B section | external | reg 0x12/0x13 = Start Address / 256 (= 256 byte aligned)、 reg 0x14/0x15 = End Address / 256 (= 同上)、 §決定 8 mapping-C reject 根拠 a 外部裏付け |

### A-7: 最小 fixture 期待値 (= 1-2 entry imagined byte sequence、 β で実 fixture 生成、 α では imagined byte sequence only)

α 段階の literal expected byte sequence (= 概念上 minimum fixture、 ADR §決定 4 「α では imagined byte sequence only」 規律):

```
offset  byte sequence                                      意図
0x000   41 44 50 43 4D 20 ... (24 byte 任意)              "ADPCM " magic + 24 byte metadata
0x01E   00 05                                              Next START Address = 0x0500 (= 例、 spike round-trip self-test 整合)
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
| α | **完了** (= PR #39 MERGED 9b52af3、 Annex A literal + §決定 2 補正) | 80fd219 |
| β | **完了** (= 本 commit、 spike script + 6/6 PASS) | (= 本 commit hash) |
| γ | **次** (= integration design + V-ROM mapping 確定) | - |
| δ | 未着手 (= runtime selection proof driver touch 最小) | - |
| ε | 未着手 (= integration + audition gate) | - |

## sub-sprint β 完了 (= 33rd session、 主軸単独実装 + spike script self-verify)

### 実装 deliverable

`scripts/ppc-parser-spike.py` 新規 (= 約 240 行、 standard library only、 doc + spike script sprint):

1. **constant literal** (= ADR-0048 Annex A spec literal の Python 実体化)
   - `PPC_SIGNATURE_FULL = b"ADPCM DATA for  PMD ver.4.4-  "` (= A-2)
   - `PPC_MAGIC_PREFIX = b"ADPCM "` (= A-2 parser check)
   - `PPC_HEADER_SIZE = 30` / `PPC_NEXT_START_OFS = 0x1E` / `PPC_DIRECTORY_OFS = 0x20` / `PPC_DIRECTORY_ENTRIES = 256` / `PPC_DIRECTORY_ENTRY_SIZE = 4` / `PPC_PCM_DATA_OFS = 0x420` (= A-1 header layout)
   - `PPC_PVI_MAGIC = b"PVI2"` (= A-8 scope-out detect)
2. **`DirectoryEntry` dataclass** + `is_unused` / `is_valid_range` properties (= A-3 + A-7 reject 条件)
3. **`PpcImage` dataclass** (= signature / next_start / entries[256] / pcm_data)
4. **`emit_minimum_fixture()` emitter** (= A-7 imagined byte sequence の literal 実装、 任意 entries + pcm_data + next_start で valid `.PPC` byte sequence emit)
5. **`parse_ppc()` parser** + **`PpcRejectError`** exception (= A-4 malformed reject 4 種 + A-8 PVI2 scope-out detect)
6. **`validate_ppc()` validator** + **`ValidationReport` dataclass** (= A-7 β reject 条件 5 件 = invalid_range / stop_exceeds_next_start / skip_unused / warn_aliasing / next_start_scale_pending)
7. **6 self-test case** (= `CASES` list 全 PASS で `exit 0`):
   - `minimum_fixture_round_trip` (= emit → parse 完全一致)
   - `reject_too_short` (= size < 30 reject)
   - `reject_wrong_magic` (= 先頭 6 byte != "ADPCM " reject)
   - `reject_under_directory` (= size < 0x420 reject)
   - `reject_pvi2_scope_out` (= PVI2 magic + offset 10 == 2 reject)
   - `validator_invalid_range_and_aliasing` (= 全 5 件 validator 動作確認 = START > STOP / aliasing / STOP > next_start / unused / next_start scale pending)

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化)

- **layer 2 review chain** (= session 019e3b50-... 流用、 β sprint):
  - round 1 = β parser / validator proof spike + 6 test cases + ADR sub-sprint β 完了 section literal 化 review = (= 本 commit が round 1 反映、 review 完了後 approve / revise 取得予定)
- **主軸 fallback regime** (= sub-agent isolation 5 連続 fail 経験踏襲、 主軸単独実装 default)
- **Codex layer 1 不要** (= driver / runtime touch なし、 spike script + ADR doc 更新 only、 layer 2 review のみで sufficient)

### verify gate (= β は spike script self-verify + driver/runtime/vendor 不変)

- `python3 scripts/ppc-parser-spike.py` 実行 = `summary: 6/6 PASS` + exit code 0 (= 本 commit 前 主軸試行で確認済)
- spike script は standard library only (= struct / dataclasses / sys、 dependency なし)
- driver / runtime / vendor / fixture 完全不変 (= ADR file + spike script 新規 only、 stage = 2 file only + vendor wav 3 件 untracked retain 維持)
- ADR-0048 Annex A spec literal と spike script 定数 完全整合 (= PPC_HEADER_SIZE = 30 + 0x420 = 0x20 + 1024 等)

### scope-out 確認 (= ADR §決定 4 doc-only sprint 規律 + §決定 5 non-goal list + Annex A-8 別 format 全 完全遵守)

- driver source touch なし (= δ sub-sprint で起動)
- vendor source touch なし
- 実 `.PPC` fixture 生成は spike emitter で在 memory のみ (= file 出力なし、 `.PPC` file 新規追加なし)
- `.PVI` / `.P86` / `.PPS` / `.PPZ` parser 未実装 (= A-8 scope-out 維持、 spike も `.PPC` 専用)
- V-ROM mapping 実装なし (= γ で確定 + δ で driver routine 実装、 β は parser / validator のみ)
- 軸 C 再オープン / Surge XT / vendor wav cleanup / 軸 B / 軸 F MML compiler すべて非 touch

### sub-sprint chain 進捗 update (= sub-sprint chain 表 reflect)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= PR #39 MERGED 9b52af3、 Annex A literal + §決定 2 補正) | 80fd219 |
| β | **完了** (= 本 commit、 spike script + 6/6 PASS、 doc + spike script) | (= 本 commit hash) |
| γ | **完了** (= 本 commit、 §決定 8 V-ROM mapping mapping-B 確定 + Annex A-5 確定 update + integration design literal) | (= 本 commit hash) |
| δ | **次** (= runtime selection proof driver touch 最小、 mapping-B 実装 + selection key 候補-1 + **案 C 部分 runtime parse + ppc-to-ngdevkit.py 新規 generator (= vromtool 外側)**) | - |
| ε | 未着手 (= integration + audition gate) | - |

## sub-sprint γ 完了 (= 34th session、 主軸単独実装 + Codex layer 2 review 経由)

### 実装 deliverable (= doc-only)

`docs/adr/0048-pmdneo-axis-g-ppc-parser-and-runtime-dynamic-sample-supply.md` 更新:

1. **§決定 8 新規追加** = 軸 G γ V-ROM mapping 確定 = **mapping-B (= offset 加算) 採用** + mapping-A / mapping-C reject literal (= γ revise round 2 must-fix 2 件反映済、 §決定 8 4-row reject table と同期):
   - 確定式: `v_rom_word = ppc_word + v_rom_base_offset_word` + reg 0x12-0x15 書込経路
   - `v_rom_base_offset_word` = build-time literal symbol `PPC_VROM_BASE_OFFSET_WORD` (= δ で `scripts/ppc-to-ngdevkit.py` (= vromtool 外側 新規 generator、 35th session 採用 案 C 経路) 生成時に値確定)
   - mapping-A reject 根拠 3 件 (= V-ROM base = 0 固定衝突 + 設計言語逸脱 + 拡張性低)
   - **mapping-C reject 根拠 4 件 (= §決定 8 table 4-row)**: (1) YM2610 register unit 256 byte aligned 確認済 (= `src/driver/PMD_Z80.inc` L2186 + `standalone_test.s` L2712-2734 + YM2610 datasheet) + (2) OPNA 側 unit 確定不要 (= mapping-B 採用下で V-ROM 直結のため OPNA PCMRAM 概念非適用、 PMDDotNET 解釈で directory entry word は OPNA register 直結 = PCMDRV.cs L673-684) + (3) PMDDotNET × 32 解釈訂正済 (= transfer stride、 directory parse ではない) + (4) 不要複雑性 (= scale factor `k` 根拠不在 + mapping-B で sufficient)
   - selection key 候補 4 件列挙 (= δ で literal 確定、 第一候補 = 候補-1 sample_table_id 上位 1 bit、 bit7 set = `.PPC` source / bit7 clear = 既存 yaml passthrough)
   - ADR-0043 production-ready 経路保護 literal (= 既存 routine 不可触 + 新規 routine 並設 + byte-identical 維持)
   - δ verify gate 推奨 (= `ppc_word != 0` かつ `offset != 0` fixture で reg 0x12-0x15 literal value assert、 unit/offset 誤り早期検出)
2. **Annex A-5 update** = γ 確定 status reflect literal:
   - section heading 「γ で確定 = mapping-B、 α では候補列挙」
   - γ 確定 result literal block (= mapping-B 採用式 + mapping-A/C reject 1 行 summary + §決定 8 参照)
   - 規律違反 risk 防止 補強 (= γ 確定後 δ 実装可)
3. **sub-sprint chain 表 update** (= ADR 内 2 箇所): γ 完了 + δ 次 + δ 第一候補 selection key (= 候補-1) literal

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化)

- **layer 2 review chain** (= session 019e3b50-... 流用、 γ sprint):
  - round 1 = γ integration design + V-ROM mapping 確定 + selection key δ defer review = **revise** (= must-fix 2 件 = mapping-C reject 根拠 a 補強 + selection key 候補-1 表記矛盾解消、 nice-to-have 2 件 = YM2610 datasheet citation + δ verify gate literal assert)
  - round 2 = revise round 1 反映後 = **revise** (= 追加 must-fix 2 件 = Annex A-5 γ result block + γ 完了 deliverable summary を §決定 8 4-row reject table と同期反映、 stale テキスト解消、 nice-to-have 0 件)
  - round 3 = revise round 2 反映後 = **approve** (= 追加 must-fix 0 件 + 追加 nice-to-have 0 件 + 規律違反 risk 0 件、 γ 完了 commit GO + sub-sprint δ 着手 GO、 stale 全解消 + 「OPNA 側 unit 確定不要」 論理 3 箇所統一確認)
- **主軸 fallback regime** (= sub-agent isolation 5 連続 fail 経験踏襲、 主軸単独実装 default)
- **Codex layer 1 不要** (= doc-only sprint、 driver / runtime touch なし、 layer 2 review のみで sufficient)

### verify gate (= γ は doc-only、 doc consistency + spike spec consistency + source attribution consistency)

- ADR-0048 §決定 8 mapping-B 式 と Annex A-3 directory entry layout 整合 (= ppc_word LE 16-bit decode + offset 加算 + reg 256 byte aligned write 経路)
- ADR-0048 §決定 8 mapping-C reject 根拠 と Annex A-1 source attribution 整合 (= PMDDotNET × 32 解釈訂正済 literal、 α revise round 1 must-fix #3 反映 reflect)
- ADR-0048 §決定 8 selection key 候補-1 と ADR-0043 §決定 3 sample_table_id 共用方針整合 (= 0xFD32 上位 1 bit = `.PPC` source、 lower 7 bit = voicenum direct lookup、 既存 ADR-0043 id 0x00/0x01 範囲 (= lower 7 bit) と衝突なし)
- ADR-0048 §決定 8 ADR-0043 production-ready 保護 literal と §決定 3 + §決定 5 non-goal 整合 (= 軸 C 再オープン継続 skip user 明示永続 scope-out 維持、 既存 routine 不可触 + 新規 routine 並設方針)
- driver / runtime / vendor / 実 `.PPC` file / spike script `scripts/ppc-parser-spike.py` 完全不変 (= ADR file 更新 only、 stage = ADR file 単独 + vendor wav 3 件 untracked retain 維持)

### scope-out 確認 (= ADR §決定 4 doc-only sprint 規律 + §決定 5 non-goal list + Annex A-8 別 format 全 完全遵守)

- driver source touch なし (= δ sub-sprint で起動)
- vendor source touch なし
- 実 `.PPC` fixture file 追加なし (= δ で生成、 minimum valid fixture)
- 新規 generator script `scripts/ppc-to-ngdevkit.py` (= vromtool 外側、 案 C 経路) 実装なし (= δ scope)
- selection key literal 確定なし (= δ scope、 γ では候補 4 件列挙のみ + 第一候補 literal)
- `v_rom_base_offset_word` 値の literal 確定なし (= δ scope、 γ では symbol 配置設計のみ)
- `.PVI` / `.P86` / `.PPS` / `.PPZ` parser 未実装 (= A-8 scope-out 維持)
- 軸 C 再オープン / Surge XT / vendor wav cleanup / 軸 B / 軸 F MML compiler すべて非 touch

### sub-sprint chain 進捗 update (= sub-sprint chain 表 reflect)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= PR #39 MERGED 9b52af3、 Annex A literal + §決定 2 補正) | 80fd219 |
| β | **完了** (= PR #41 MERGED f79f5e5、 spike script + 6/6 PASS) | bd9401a |
| γ | **完了** (= PR #43 MERGED 2923c3a、 §決定 8 V-ROM mapping mapping-B 確定 + Annex A-5 update + integration design literal) | 12fcf69 |
| **γ revision (= 35th session vromtool finding 反映)** | **本 commit** (= ADR-0048 §決定 8 + §軸 G scope-in + §決定 8 末尾 案 C 経路 + 各 stale literal 修正) | (= 本 commit hash) |
| δ | **次** (= runtime selection proof driver touch 最小、 mapping-B 実装 + selection key 候補-1 第一候補 + **案 C 部分 runtime parse + ppc-to-ngdevkit.py 新規 generator (= vromtool 外側)**) | - |
| ε | 未着手 (= integration + audition gate) | - |

## sub-sprint γ revision (= 35th session 開始時、 vromtool finding 反映、 主軸単独実装 + Codex layer 2 round 1 approve)

### 実装 deliverable (= doc-only)

`docs/adr/0048-pmdneo-axis-g-ppc-parser-and-runtime-dynamic-sample-supply.md` 更新:

1. **§決定 8 heading update** = 「+ δ 経路 = 案 C (= 部分 runtime parse)」 追加、 「35th session vromtool finding 反映」 1 段落新規 (= vromtool 拡張不能 + 旧 literal stale + 案 C 採用 + mapping-B 式維持 literal)
2. **§決定 8 `v_rom_base_offset_word` 配置設計** update = 「vromtool.py 拡張」 → 「新規 generator script (= 仮称 `scripts/ppc-to-ngdevkit.py`、 vromtool 外側)」 literal、 案 C 経路 sample data / directory binary / offset 計算の 3 軸分離
3. **§決定 8 末尾 `δ 実装経路 = 案 C (= 部分 runtime parse) 採用` section 新規追加**:
   - 案 C 採用確定 literal (= sample data + directory binary + driver runtime + selection key + 新規 generator + mapping-B 式維持 の 6 軸)
   - 案 A (= build-time emit) reject 根拠 3 件 (= runtime parse scope drop + 設計根本分岐 risk)
   - 案 B (= 真の runtime parse、 full .PPC binary embed) reject 根拠 3 件 (= scope 最大 + vromtool bypass + ADR-0043 production-ready 破壊 risk)
   - ROM directory region 設計 5 軸 (= format / alignment / symbol naming / linker exposure / δ 確定)
4. **§軸 G scope-in literal 明確化** = 「`.PPC` format driver parse (= header / directory / sample entry 解析)」 → 「`.PPC` **runtime directory lookup** (= directory entry index → START/STOP word decode、 ROM 内 embed directory binary)」 literal 修正、 新規 generator script 1 行追加
5. **平易日本語要約 `γ 完了後 次の step`** update = 案 C 経路 + ppc-to-ngdevkit.py + ROM directory embed literal 反映

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化)

- **layer 2 review chain** (= session 019e3b50-... 流用、 35th session γ revision sprint):
  - round 1 = 35th session vromtool finding 反映 + δ scope 経路選定 3 案 = **approve** (= 案 C 採用、 設計根本分岐対象外、 must-fix 5 件、 nice-to-have 3 件、 規律違反 risk 3 件、 ADR 修正 PR → δ 実装 PR の順)
  - round 2 = round 1 must-fix 5 + nice-to-have 3 反映後 = **revise** (= 追加 must-fix 5 件 = stale `vromtool.py 拡張` literal 5 箇所残存 L222/L325/L413/L615/L626、 規律違反 risk 2 件 = stale 残存で δ 実装時誤違反 risk + factual drift risk)
  - round 3 = round 2 追加 must-fix 5 件 反映後 = **approve** (= 6 箇所 stale literal 修正 + literal quotation 3 箇所維持 OK 確認、 factual drift 解消、 案 C 経路 literal 統一、 追加 must-fix 0 件 + 追加 nice-to-have 0 件 + 規律違反 risk 0 件、 γ revision commit GO + dashboard sync PR + δ 実装 PR 着手 GO)
- **主軸 fallback regime** (= 主軸単独実装 default)
- **Codex layer 1 不要** (= doc-only sprint、 driver / runtime touch なし、 layer 2 review のみで sufficient)

### Codex layer 2 round 1 must-fix 反映 (= 5 件 全反映)

1. ADR-0043 / ADR-0048 の stale literal 修正: `vromtool.py 拡張` は不可として明記 → §決定 8 「35th session vromtool finding 反映」 1 段落 literal、 旧経路 reference を「stale」 + 「修正済」 と明示
2. ADR-0048 §決定 8 を案 C ルートへ更新: `.PPC directory binary` を別 ROM region に embed、 sample data は既存 vromtool route 継続 → §決定 8 末尾 `δ 実装経路 = 案 C` section 新規 literal
3. ADR-0048 §軸 G scope-in literal を明確化: full `.PPC` binary parse ではなく、 runtime directory lookup + runtime sample selection として扱う → §軸 G scope-in literal 明確化 (= 「runtime directory lookup」 明記)
4. mapping-B formula は維持し、 resolution timing が runtime directory lookup 側になる点を明記 → §決定 8 「35th session vromtool finding 反映」 末尾 + 案 C 採用 section に literal
5. δ 実装 PR 前に ADR fix PR を先行させる → 本 commit が ADR fix PR (= 35th session 候補 1)、 後続別 PR で δ 実装着手

### Codex layer 2 round 1 nice-to-have 反映 (= 3 件 全反映)

- 案 A (= build-time emit) を ADR rejected option として記録 → §決定 8 末尾 案 A reject 根拠 section
- 案 B (= 真の runtime parse) を ADR rejected option として記録 → §決定 8 末尾 案 B reject 根拠 section
- 新 ROM directory region の format / alignment / symbol naming / linker exposure 追記 → §決定 8 末尾 ROM directory region 設計 section 5 軸 literal

### verify gate (= γ revision は doc-only、 doc consistency 整合)

- ADR-0048 §決定 8 案 C 経路 と §軸 G scope-in literal 整合 (= 「runtime directory lookup」 明記、 full binary parse 削除)
- §決定 8 mapping-B 式は維持 (= resolution timing 明記、 式自体は不変)
- §決定 8 案 A / 案 B reject 根拠 + 案 C 採用根拠 の整合
- ADR-0043 production-ready 経路保護 literal 維持 (= 既存 routine 不可触 + 既存 vromtool 経路継続)
- driver / runtime / vendor / 実 .PPC file / spike script / vromtool 完全不変 (= ADR file 更新 only、 stage = ADR file 単独 + vendor wav 3 件 untracked retain 維持)

### scope-out 確認 (= ADR §決定 4 doc-only sprint 規律 + §決定 5 non-goal list 全完全遵守)

- driver source touch なし (= δ sub-sprint で起動)
- vendor source touch なし
- 実 `.PPC` fixture file 追加なし (= δ で生成)
- 新規 generator script (= ppc-to-ngdevkit.py) 実装なし (= δ scope、 γ revision では設計 literal のみ)
- ADR-0043 既存 routine 不可触
- 既存 vromtool 経路保護
- 軸 C 再オープン / Surge XT / vendor wav cleanup / 軸 B / 軸 F MML compiler すべて非 touch

## sub-sprint δ (= 案 C 部分 runtime parse 経路実装、 35th session 末、 主軸単独実装 + Codex layer 2 PR 境界 approve)

### 実装 deliverable (= driver touch sprint、 6 commit chain)

1. **step 1** (= 59e1acb): `scripts/ppc-to-ngdevkit.py` 新規 generator (= 約 355 行、 vromtool 外側 layer)
   - `.PPC` parse + size / magic / format verify (= ADR-0048 Annex A-1〜A-4 spec literal、 spike script logic 重複で self-contained)
   - `extract_directory_binary()` で 1024 byte directory binary を `ppc_directory.bin` 抽出
   - ADPCM-B raw byte stream (= file 0x420 以降) を 1 blob として `ppc_pcm_blob.adpcm_b` 抽出
   - `samples-map-adpcmb-ppc.yaml` に blob entry emit (= 既存 yaml と build hook で merge cp 前提)
   - `ppc_symbols.inc` で `PPC_VROM_BASE_OFFSET_WORD_LSB/MSB = PPC_PCM_BLOB_START_LSB/MSB` 同値定義 (= vromtool 配置後の symbol を assembler resolve)
   - `--emit-fixture` mode で minimum `.PPC` fixture 生成
   - `--self-test` で round-trip + size + nonzero + symbols literal 5 件 PASS (= nice-to-have #1 + #3 反映)

2. **step 2** (= 216f520): `src/test-fixtures/axis-g/minimum.PPC` 1312 byte 2 entry fixture commit
   - entry 0: START 0x0400, STOP 0x0480 (= `ppc_word != 0` で identity 誤実装 trace 用、 nice-to-have #1)
   - entry 1: START 0x0480, STOP 0x0500
   - PCM filler 256 byte (= deterministic、 audio gate 対象外)

3. **step 3** (= d53efc7): build hook + ROM section 接続
   - `scripts/build-poc.sh` L99-117 に generator invoke + yaml merge cp 追加
   - `.gitignore` に generator output 3 件 (= `samples-map-adpcmb-ppc.yaml` + `ppc_symbols.inc` + `ppc_pcm_blob.adpcm_b`) 追加 (= `*.bin` は既存 glob で `ppc_directory.bin` 自動 cover)
   - 既存 ADPCM-B passthrough 経路 (= beat / silence / silence_b) 完全不変、 PPC blob entry が末尾に追加されるのみ

4. **step 4** (= 5e677ba): driver 改修 6 箇所 (= `src/driver/standalone_test.s`、 89 行 net 増)
   - SRAM scratch 領域定義 4 件 (= 0xFD33-0xFD36、 ppc_scratch_start/stop_lsb/msb)
   - `.include "assets/ppc_symbols.inc"` (= samples.inc 直後)
   - SRAM layout コメント update (= 0xFD33-0xFD36 ppc scratch + 0xFD37-0xFFBF free)
   - `adpcmb_keyon` 改修 = bit7 分岐追加 (= `sample_table_id` lookup → bit7 set/clear で source 切替、 既存 routine への jr 経路完全不変)
   - 新規 routine `pmdneo_select_adpcmb_ppc_pointer` (= 約 45 行、 HL = `PPC_DIRECTORY_BASE` + entry_index * 4 → byte-level mapping-B add + adc 加算 + scratch 書込 → DE = scratch addr return)
   - `PPC_DIRECTORY_BASE: .incbin "assets/ppc_directory.bin"` 配置 (= song_data.inc 直後)

5. **step 5** (= 5755934): verify script (= `src/test-fixtures/axis-g/verify-delta-ppc-runtime-selection.sh`、 200 行) 7 gate ALL PASS
   - gate 1: build PASS (= `scripts/build-poc.sh`)
   - gate 2: `ppc_directory.bin` 1024 byte size assert (= nice-to-have #2 反映)
   - gate 3: generator self-test 5/5 PASS (= nice-to-have #3 反映)
   - gate 4: spike script 6/6 PASS (= β regression)
   - gate 5: mapping-B literal 期待値 + samples.inc 整合 + identity 区別 (= nice-to-have #1 反映)
     - `PPC_PCM_BLOB_START_WORD = 0x00AF` (= nonzero base offset 確認)
     - entry 0 期待 reg 0x12/0x13/0x14/0x15 = 0xAF/0x04/0x2F/0x05 (= `0x0400 + 0x00AF = 0x04AF` / `0x0480 + 0x00AF = 0x052F`)
     - entry 1 期待 reg 0x12/0x13/0x14/0x15 = 0x2F/0x05/0xAF/0x05 (= `0x0480 + 0x00AF = 0x052F` / `0x0500 + 0x00AF = 0x05AF`)
     - identity 区別 literal 確認 (= identity だと entry 0 で 0x00/0x04/0x80/0x04 になる)
   - gate 6: 既存 ADR-0043 regression PASS (= driver byte-identical 維持)
     - ADR-0016 step 4-3-δ baseline PASS
     - axis-c γ-2 multi-table PASS (= BEAT vs SILENCE_B literal differ + non-addr regs identical)
     - axis-c γ-3 axis independence PASS (= ADPCM-A M-Q ch 20 reg byte-identical + keyon count 41 identical)
   - gate 7: driver source 構造 grep 5 件 (= 新 routine + bit7 分岐 + mapping-B add/adc literal + `.incbin` + 既存 routine label 不可触 literal 保持)

6. **step 6**: MAME 起動確認 (= CLAUDE.md §動作確認義務遵守、 driver touch sprint 必須)
   - `bash scripts/run-mame.sh --headless --wavwrite` で `audio.wav` 1.5 MB 生成
   - Average speed 4020% (= 8 秒分 audio を 7 秒で生成完了)
   - WRONG CHECKSUMS warning のみ (= PMDNEO 専用 ROM の常時 expected warning、 機能影響なし)

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化)

- **Codex layer 2 PR 境界 review** (= session 019e3b50-... 流用、 35th session δ 実装 sprint):
  - round 1 = PR 境界 3 案 (= 案 A 1 PR まとめ / 案 B 3 PR 分割 / 案 C 2 PR 分割) 主軸推奨案 C → **approve** (= must-fix 0 件、 nice-to-have 3 件 = identity 誤実装 trace + size assert + generator self-test 含む、 規律違反 risk 0 件)
- **主軸 fallback regime** (= sub-agent isolation 5 連続 fail 経験踏襲、 主軸単独実装 default、 ADR-0048 §決定 6 「δ/ε driver touch 系は主軸単独実装 default」 適用)
- **Codex layer 1 不要** (= 主軸単独実装、 layer 2 PR 境界 approve のみで sufficient、 nice-to-have 3 件は本 PR 内で全反映)

### verify gate (= δ は driver touch sprint、 audio gate audition は ε 分離)

- driver source 改修 = 既存 ADR-0043 production-ready 経路完全不可触 + 新規 routine 並設 only
- byte-identical 維持確認 = step4 baseline + γ-2 + γ-3 全 PASS
- mapping-B literal 期待値計算 + samples.inc PPC_PCM_BLOB_START_LSB/MSB 整合確認
- nice-to-have 3 件 (= Codex layer 2 round 1) 全反映 = identity 誤実装 trace / size assert / generator self-test
- audio gate audition (= 越川氏 audition) は **ε scope に分離** (= Codex layer 2 approve、 δ では MAME 起動確認 + ymfm-trace gate なし driver source 構造 + literal 期待値計算で完了判定)

### scope-out 確認 (= ADR §決定 5 non-goal + Annex A-8 別 format + 35th session vromtool finding 完全遵守)

- vromtool 改造 = 禁止 (= 35th session finding、 ngdevkit 外部 tool)
- 既存 ADR-0043 routine (= pmdneo_select_adpcmb_sample_pointer / adpcmb_keyon_have_sample / adpcmb_sample_beat) 完全不可触
- `.PPC` full binary runtime parser = 禁止 (= 案 B reject 済)
- audio gate audition = ε scope
- unrelated refactor = 禁止
- vendor wav 3 件 untracked retain 維持

### sub-sprint chain 進捗 update (= sub-sprint chain 表 reflect)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= ADR-0048 PR #39 MERGED 9b52af3) | 80fd219 |
| β | **完了** (= PR #41 MERGED f79f5e5) | bd9401a |
| γ | **完了** (= PR #43 MERGED 2923c3a) | 12fcf69 |
| γ revision | **完了** (= PR #45 MERGED ee40987、 35th session vromtool finding 反映 + 案 C 採用) | bfc2e5e |
| **δ** | **完了** (= PR #47 MERGED 5f91b3a、 案 C 部分 runtime parse 実装、 verify gate 7/7 PASS) | 6 commit chain |
| ε | **次** (= integration + audition gate、 必要時 user audition、 ADR-0043 §決定 1 ε 完全充足) | - |

## sub-sprint ε (= 36th session、 reject 1 回目 + round 2 fix + partial approve / integration reject、 主軸単独実装 + Codex layer 2 review approve)

### ε 結果 = partial complete (= PPC audible proof approve / integration 同居 reject、 Accepted 化 defer)

35th session 末の越川氏 audition reject 1 回目から、 36th session で主軸 5 件切り分け + round 2 fix を実施。 再 audition で **PPC audible proof approve / integration 同居 reject** の partial 結果。 ADR-0048 Draft 維持 (= Accepted 化 defer)、 integration 同居は **ζ 候補へ defer**。

### 越川氏 audition 結果 literal 引用 (= Codex layer 2 nice-to-have #1 反映、 「なぜ partial か」 後から読む人が一発理解できるよう保存)

```
聴感結果:
- audition.wav 冒頭で、 ADPCM-B の kick/beat が 1 発鳴ったことは確認できました。
- その音は、 既存 yaml beat sample の先頭 slice を minimum.PPC に埋め、 PPC 経路から
  ADPCM-B 専用 ch で鳴らしたものだと理解しました。
- したがって「PPC 経路から ADPCM-B sample を可聴に鳴らす」 点は approve です。

ただし:
- 今回聴こえたのは冒頭の kick/beat 1 発のみでした。
- FM / ADPCM-A / 既存 yaml beat 経路との同居 audition にはなっていません。
- そのため、 ADR-0048 ε の integration gate としてはまだ approve できません。
- ADR-0048 Draft → Accepted には進めないでください。

判断:
- PPC audible proof: approve
- ε integration + audition gate: reject / incomplete

次に必要なこと:
- ε を完了させるなら、 PPC 単体発音ではなく、 production 相当の FM / ADPCM-A playback と
  同居する audition fixture を作ってください。
- もし同居 fixture が既存 driver 構造上大きくなるなら、 今回の PPC audible proof を
  PR #49 の成果として記録し、 integration 同居は別 PR または別 sub-sprint へ明示的に
  defer してください。
- その場合でも、 ADR-0048 Accepted 化は defer し、 Draft のまま維持してください。

要するに、 「PPC 経路から音は出た」 は OK。 ただし「既存再生と同居して軸 G 完成」 はまだ NG。
```

### reject 1 回目 + 主軸 5 件切り分け (= ε round 2 fix 経路 literal、 user 指示通り)

35th session 末越川氏 audition reject literal: 「両 wav とも `.PPC` 由来 ADPCM-B が鳴っていない」。 主軸が次の 5 件で切り分け:

| 切り分け | finding | 結果 |
|---|---|---|
| 1 | TEST_MODE_AXIS_G_INT=1 が preprocessed.s に literal 反映済 | PASS (= sed 経路は正常) |
| 2 | audition build で reg 0x10 = 0x80 keyon の発火件数 | **FAIL = 0 件** (= ADPCM-B keyon 未発火) |
| 3 | minimum.PPC entry word が blob 範囲内か | **FAIL** (= entry 0 START 0x0400 + blob_base 0x00AF = 0x04AF、 blob 範囲 0x00AF-0x00B0 を遥か超えて V-ROM uninitialized 領域 273 KB 後を指す) |
| 4 | minimum.PPC filler が ADPCM-B として可聴か | **FAIL** (= user 補足通り、 deterministic byte filler の decode 音は非可聴) |
| 5 | TIMER-B IRQ rate が想定通りか | **FAIL** (= z80-mem-trace で 0xF816 への write が 6 秒で 3 件のみ = IRQ 2 回しか発火、 IRQ counter 経路で 1 秒後 trigger 不能、 別 sprint 改修 scope) |

### round 2 fix 3 件 (= 36th session、 切り分け 2/3/4 を解消、 切り分け 5 は ζ defer)

1. **minimum.PPC を audible 化**:
   - entry word を blob 内に修正 (= entry 0 START=0x0000/STOP=0x0004 = blob 内 1024 byte 範囲、 entry 1 START=0x0002/STOP=0x0004)
   - PCM data filler を既存 V-ROM yaml beat sample raw byte 1024 byte slice に差替 (= BEAT_START_LSB=0x2a で byte 0x2A00 から抽出、 sha256 = de90e4c4994219831b97633626dfca55d27260af3dfb9cefccd0234358268244)
   - fixture size = 1312 byte → 2080 byte

2. **強制 keyon を IRQ → init 経路に移動**:
   - IRQ handler 内 test mode block を削除 (= 切り分け 5 で IRQ tick 不足 finding 反映、 counter 経路は不能)
   - init 経路 (= nmi_clear_driver_state 直後) に強制 ADPCM-B keyon code 12 step inline 追加
   - cold boot 直後 1 度 trigger (= 「同居 audition」 ではなく「PPC audible proof」)

3. **verify script expected reg を新 fixture 値に更新**:
   - PPC_ENTRY0_START_WORD/STOP_WORD = 0x0000/0x0004
   - mapping-B 期待 reg = 0xAF/0x00/0xB3/0x00 (= 新 entry word + blob_base 0x00AF)
   - identity 区別判定 = reg 0x12 == blob_base_lsb なら mapping-B PASS

### round 2 fix verify gate

- production build (= TEST_MODE_AXIS_G_INT=0) で δ verify gate **7/7 ALL PASS 維持**
- audition build (= TEST_MODE_AXIS_G_INT=1) trace literal:
  - reg 0x10 = 0x80 keyon trigger: write_idx 9 (= init 経路、 **1 件発火**)
  - reg 0x12 = 0xAF, reg 0x13 = 0x00, reg 0x14 = 0xB3, reg 0x15 = 0x00 (= mapping-B literal 期待値完全一致)
- wav sha256:
  - production: e48cf7731f0862ccd153c4aee2803f12946667eb1ef8417812137cccee082920
  - audition: 928093c094a7b2f6d1877d10a0dd836f791cd7177a3cd12374d181098f2c9b3a

### 採用判断 経路 (= ADR-0041 §決定 4-2 Codex rescue 化 + user 介入は最終確認)

- **Codex layer 2 ε round 1 approve** (= 35th session、 4 判断 + nice-to-have 4 件): 案 B PR 境界 + 案 a TEST_MODE_AXIS_G_INT + audition wav 非 commit + Accepted 移行条件案 c
- **越川氏 audition reject 1 回目** (= 35th session 末): 両 wav とも PPC 由来 ADPCM-B 不可聴
- **主軸 5 件切り分け** (= 36th session、 user 指示通り literal 確認): root cause 3 件特定
- **round 2 fix 3 件** (= 36th session、 切り分け 2/3/4 解消、 切り分け 5 は ζ defer)
- **越川氏 audition round 2 partial approve** (= PPC audible proof approve / integration 同居 reject)
- **Codex layer 2 ε partial 進め方 review approve** (= 36th session、 4 判断全 GO、 nice-to-have 1 件 = 越川氏 audition literal 引用保存、 規律違反 risk 3 件 = Accepted 化禁止 + 「完了」 記述禁止 + 同居未達事実隠蔽禁止)

### ε scope-out (= 36th session round 2 fix + partial complete 時点で literal 化、 ζ defer 範囲)

- **真の同居 audition** (= 同一 MAME 起動内で PPC + 既存 yaml + ADPCM-A 経路が時系列で並走、 越川氏 audition で 3 経路同居確認) = **ζ 候補 へ defer** (= 既存 driver の TIMER-B IRQ rate 改修必要、 ε scope 超え)
- ADR-0048 Draft → Accepted 移行 = **defer** (= ζ 完了 + 真の integration audition approve 後)
- 軸 G 完了宣言 = **defer** (= partial complete 状態維持、 「完了」 と記述しない、 Codex layer 2 規律違反 risk 反映)
- IRQ counter 経路 (= 1 秒後切替) = ζ scope (= 既存 driver TIMER-B 構造改修必要)
- MML 拡張 (= J part で MML 中 sample_table_id 切替) = 軸 F defer + ζ scope 候補

### sub-sprint chain 進捗 update (= sub-sprint chain 表 reflect)

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= PR #39 MERGED 9b52af3) | 80fd219 |
| β | **完了** (= PR #41 MERGED f79f5e5) | bd9401a |
| γ | **完了** (= PR #43 MERGED 2923c3a) | 12fcf69 |
| γ revision | **完了** (= PR #45 MERGED ee40987) | bfc2e5e |
| δ | **完了** (= PR #47 MERGED 5f91b3a) | 6 commit chain |
| **ε** | **partial complete** (= PR #49 round 2 fix + partial approve / integration reject、 Accepted 化 defer) | PR #49 = cf64d60 + 1ed5fe4 + 本 doc commit |
| **ζ (= 候補予約)** | **未着手** (= integration 同居 fixture、 着手時期 user 判断仰ぎ) | - |

## sub-sprint ζ 候補予約 (= 36th session、 ε partial complete + integration defer に伴う後続候補、 起票は未実施)

ε partial complete (= PPC audible proof approve / integration 同居 reject) を受けて、 ζ sub-sprint を **候補予約** literal 化。 起票 + 着手は user 明示 GO 後 (= 別 sprint 起票判断仰ぎ)。

### ζ scope (= 候補定義)

- 同一 MAME 起動内で **3 経路同居 audition** (= `.PPC` 経路 + 既存 yaml passthrough 経路 + ADPCM-A 経路) が時系列で並走 + 越川氏 audition で同居確認 approve 取得
- 既存 driver の **TIMER-B IRQ rate 構造改修** (= 36th session ε 切り分け 5 finding、 6 秒で IRQ 2 回しか発火しない問題、 ε scope 超え) を解消 or 別駆動経路で同居 fixture 構築
- 同居 fixture を実現する経路の候補:
  - **案 X = TIMER-B IRQ rate 改修** (= 既存 driver の TIMER-B 構造を見直し、 IRQ rate を 1 ms 想定通りに復旧)
  - **案 Y = MML 拡張で J part に PPC 経路 keyon 命令を追加** (= 軸 F defer 解除必要、 compile.py + driver 両方改修)
  - **案 Z = init 経路の強制 keyon を timing 調整可能 sequence に拡張** (= 既存 init 経路維持、 frame counter ではなく ADPCM-B 終了 flag 経由で「1 度目 yaml + 2 度目 PPC」 を inline 実装)

### ζ 起票時の判断軸

- 着手 timing = user 明示 GO 後 (= 別 sprint scope、 軸 B / 軸 D 等他軸との優先順位 user 判断)
- 着手範囲 = 案 X/Y/Z の比較 Codex layer 2 review + 主軸推奨 + user 判断
- ε との関係 = ζ 完了で「軸 G 完成」 = ADR-0048 Draft → Accepted 移行 trigger

### ζ 未着手中の運用

- ε partial complete 状態維持 (= ADR-0048 Draft + dashboard 軸 G「ε partial / ζ defer」 literal)
- 軸 G を「完了」 と記述しない (= Codex layer 2 規律違反 risk 反映)
- 同居未達事実を隠蔽しない (= Codex layer 2 規律違反 risk 反映)
- ζ 着手 trigger を user 明示 GO のみに限定 (= 別 sprint との衝突 risk 回避)

## sub-sprint ζ 着手準備: 3 案比較表 (= 36th session 末、 主軸単独実装 + Codex layer 2 3 round chain approve、 実装はまだ入らない)

ε partial complete を受けて、 ζ 着手判断のための 3 案比較表を作成。 ζ 着手 + 案選定は user 明示 GO 後 (= 別 sprint scope)。 本 section は ADR-0048 内に「ζ 着手判断材料」 を literal 化する doc-only sprint。

### 3 案の中身

#### 案 X: 既存 driver の TIMER-B IRQ rate 構造改修

TIMER-B init + IRQ handler を改修して IRQ rate を 1 ms 想定に復旧 (= 切り分け 5 finding 根本解決)。 IRQ counter 経路が functional になり、 1 秒後 sample_table_id 切替 + J part keyon が PPC 経路で鳴る。 既存 driver 全 part 駆動 timing 変更を伴う。

#### 案 Y: MML 拡張で J part に PPC 経路 keyon を追加

軸 F (= MML compiler 拡張) defer 解除 (= ADR-0044 改訂)。 compiler 経路 (= 改造 PMDDotNET compiler 触接含む可能性、 compile.py + driver の両方 or 片方) + driver 改修。 新 MML 命令 (= 例 `\@128` for PPC entry 0) 追加で MML で記述する song の中で yaml → PPC 切替可能。

#### 案 Z: init 経路の強制 keyon を拡張し、 yaml → PPC 順次発火

ε round 2 fix で実装した init 経路の強制 keyon を拡張。 ADPCM-B 終了 flag (= YM2610 status register polling、 上限 N 回 / 例 0xFFFF cycle 到達で sentinel 確定 = polling loop 暴走防止) で yaml → PPC 順次発火。 driver init 経路だけ拡張 = 既存 driver 全体への影響なし。 **audition fixture としての同居証明** (= 最終曲中 runtime selection そのものではない)。

### final revised 比較表 (= 11 評価軸、 Codex layer 2 round 3 approve)

| 評価軸 | 案 X (TIMER-B) | 案 Y (MML 拡張) | 案 Z (init 経路拡張) |
|---|---|---|---|
| 1. ADR-0048 現行 goal 一致度 | ◎ (= 既存 song 中 production 経路、 最終 runtime selection そのもの) | ◎ (= MML 中 production 経路、 最終 runtime selection そのもの) | △ (= 現行 goal 未達、 goal 再定義必要) |
| 2. ADR-0043 production-ready 経路への影響 | 中 (= IRQ rate 改修で全 part 駆動 timing 変更 = regression risk) | 低 (= compiler 経路改修主体、 driver 側 keyon は既存 routine 利用) | 最小 (= init 経路追加のみ、 TEST_MODE guard 下で既存 IRQ + song player に touch せず) |
| 3. driver 改修範囲 | 大 (= TIMER-B init + IRQ handler 全面改修、 既存 driver 構造変更) | 中 (= MML cmd 追加 = byte stream 新 opcode + handler、 sample_table_id write 1 箇所追加) | 小 (= init 経路の強制 keyon 拡張、 status polling 追加) |
| 4. compiler / 軸 F defer 解除の要否 | 不要 | 必要 (= ADR-0044 改訂 + 軸 F defer 解除、 compile.py + 改造 PMDDotNET 両方触接の可能性、 sprint scope 拡大) | 不要 |
| 5. audition fixture 十分性 | ◎ (= 既存 song 中で PPC 鳴る、 真の同居 audition) | ◎ (= MML 中で PPC 鳴る、 真の同居 audition) | ○ (= 順次発火 fixture OK、 同居は時系列分離) |
| 6a. Accepted 移行の根拠 (= 真の integration audition approve として十分か) | ◎ | ◎ (= 軸 F defer 解除整合性確認必要) | **要 user 判断** (= test mode proof で Accepted 化の十分性は user 判断 gate、 自動 trigger ではない) |
| 6b. ζ fixture proof としての十分性 | ◎ | ◎ | ○ (= test mode 同居 audition fixture proof として完結、 限定 scope の fixture proof は十分) |
| 7. regression risk | **高** (= TIMER-B 改修で全 part 駆動 timing 変更、 既存 ADR-0043 / 軸 C / step4 baseline 等全 fixture 影響可能性) | 中 (= MML cmd 追加で byte stream 互換性 risk、 既存 fixture の MML 解釈影響可能性) | **低** (= init 経路追加のみ、 production build (= TEST_MODE_AXIS_G_INT=0) で既存 fixture 完全不変 = byte-identical 維持) |
| 8. PR 境界 | 多 PR 分割必要 | 多 PR 分割必要 (= ADR-0044 改訂 + compiler 改修 + driver keyon 改修 + verify gate + audition + Accepted 判断) | 少 PR (= 1-2 PR で完結) |
| 9. verify gate | 大 (= 既存 fixture 全 regression + 新 TIMER-B IRQ rate verify + 同居 audition + audio gate) | 大 (= 既存 fixture regression + MML cmd 互換 verify + 同居 audition + audio gate) | 中 (= production build byte/trace 不変 + test mode で yaml→B 終了→PPC 順序 trace + **status polling timeout fail (= cycle 数上限 N 回 / 例 0xFFFF cycle 到達で sentinel 確定)** + 同居 audition fixture audio gate) |
| 10. user audition 必要箇所 | 1 箇所 (= 同居 audition) | 1 箇所 (= 同居 audition) | **2 箇所** (= 順次発火 audition + 「test mode proof で ADR-0048 sufficient か」 user 判断 gate) |
| 11. production runtime semantics 到達度 | ◎ (= 既存 song 中 production 経路で発火) | ◎ (= MML 中 production 経路で発火) | **×** (= test mode 専用、 production runtime semantics 到達度ゼロ) |

### 主軸推奨 (= 弱め表現、 user 仮判断と一致、 Codex round 3 approve)

**案 Z を ζ 第一候補** として推奨。

| 項目 | 推奨表現 |
|---|---|
| 採用理由 | 最小リスクで integration audition fixture を作るため、 ε scope 内拡張で完結する案 Z が第一候補 |
| 完了定義 | ζ 完了 = ADR-0048 §決定 1 sub-sprint chain は **test mode 同居 audition fixture proof まで完了**、 「軸 G 完成」 とは表現しない |
| Accepted 化 | ζ 完了で自動 Accepted ではなく、 **user が test mode proof を ADR-0048 sufficient と判断した場合のみ** Draft → Accepted 移行 |
| 後続予約 | production 経路同居 (= 真の integration audition) は **ADR-0049 候補 or ADR-0044 revision 候補** (= 軸 F defer 解除路線、 軸 G の後続軸として別 ADR で扱う) |

### ζ section literal 化規律 6 件 (= Codex layer 2 round 3 approve)

ζ 着手時に ADR-0048 ζ section に literal 化する規律:

1. **ζ scope = test mode 同居 audition fixture proof** (= 順次発火 + production 経路ではない)
2. **「軸 G 完成」 表現禁止** (= ε reject 1 回目越川氏 literal 「既存再生と同居して軸 G 完成はまだ NG」 遵守、 「sub-sprint chain test mode fixture proof 完了」 と表現)
3. **ADR-0048 Draft → Accepted 移行は user 判断 gate** (= ζ 完了で自動 trigger しない)
4. **案 Z verify gate**: production build byte/trace 不変 + 順序 trace + **status polling timeout fail (= 上限 N 回 / 例 0xFFFF cycle 到達で sentinel 確定、 polling loop 暴走防止 literal)**
5. **ADR-0048 末尾予約 literal**: production 経路同居は **ADR-0049 候補 or ADR-0044 revision 候補** (= 軸 F defer 解除路線、 軸 G の後続軸として別 ADR で扱う)
6. **§決定 5 non-goal 拡張**: production 経路での MML 中 PPC 経路 keyon を non-goal に literal 追加

### Codex layer 2 3 round chain 経過 literal (= 36th session ζ 着手準備)

- **round 1** = **revise** (= must-fix 4 件 = Accepted 自動 trigger 禁止 + 評価軸 6 分割 + 「軸 G 完成」 弱め + verify gate 不足、 nice-to-have 3 件 = 新評価軸 11 production runtime semantics 追加 + 案 Y compiler 経路広げ + ADR-0048 末尾予約 literal、 規律違反 risk 0 件)
- **round 2** = **revise** (= 追加 must-fix 1 件 = cycle 数上限 literal 欠落、 round 1 must-fix #4 partial 反映、 規律違反 risk 0 件)
- **round 3** = **approve** (= revised 比較表 + 弱め主軸推奨 + ζ literal 6 件 全 GO、 着手は user 明示 GO 後 / 別 sprint scope 維持)

### ζ 着手判断 (= user 判断仰ぎ、 主軸進行禁止)

- **ζ 着手 GO** = user 明示後、 主軸が案 Z 経路で ζ implementation sprint 開始 (= 新 PR + driver 拡張 + verify gate 拡張 + audition + Accepted 化判断)
- **session 閉じる** = ζ 着手は次 session or 他軸との優先順位 user 判断後
- **他軸へ戻る** = 軸 B (= Phase 2 FM/SSG driver) / 軸 D (= WebApp) / 軸 E (= IPL) 等の優先順位仰ぎ

本 sub-section (= ζ 着手準備) は **doc-only sprint** で、 driver / runtime / vendor / 既存 fixture / 既存 yaml 全完全不変。 ADR-0048 Draft 維持 + 軸 G ε partial complete 状態維持。

## sub-sprint ζ-α 起票 (= 2026-05-23 39th session、 ADR-0048 ζ-α 起票 doc-only filing、 ADR-0060 Accepted 後の continuation、 単一 doc-only PR = single-doc-pr-A、 Codex layer 2 round 2 approve 経由)

### ζ-α 起票の経緯 (= ADR-0060 Accepted 後の ADR-0048 ζ 着手判断)

ADR-0060 Accepted (= 2026-05-23 39th session、 PR #108、 軸 B production-ready roadmap ④ 軸 G dynamic supply 依存整理 doc-only design 完了) で次の literal 整理が確立した:

- **ADR-0058 δ-5 TIMER-B IRQ rate ~492 Hz literal 実測** = ADR-0048 ε partial 切り分け 5「6 秒で 2 回」 finding 完全 stale 化 (= ADR-0060 §決定 1)
- **v2 driver と軸 G ε partial state の依存関係 literal 整理** = ADR-0060 §決定 2 で case 1/2/3 候補 + ADR-0048 ζ scope literal
- **ADR-0048 ζ 着手向け前提整理** = ADR-0060 §決定 3 で案 X 不要 / 案 Y 継続 / 案 Z 第一候補 + 真 root cause 4 候補
- **ADR-0059 sup-sample-table-id-bit7-clear gate 関係性** = ADR-0060 §決定 4 で roadmap ④ 後の bit7=1 侵入可能性 literal、 実装は ADR-0048 ζ scope

これらの finding を反映し、 user 明示「次は ADR-0048 ζ の再評価 / 起票判断でよいです」 を受けて ADR-0048 ζ 起票判断を実施。 Codex layer 2 起票 plan review = round 1 revise + round 2 approve 経由で **ADR-0048 ζ-α (= 起票 doc-only filing) GO** 確定。

### ζ-α 起票 deliverable (= 本 sub-section)

| deliverable | 内容 |
|---|---|
| ADR-0048 本文 ζ-α section additive 追加 (= ADR-0058 ζ / ADR-0059 ζ pattern 同形式) | 本 sub-section が ζ-α 起票内容 = (1) ζ-α 経緯 (2) 5 sub-sprint 構成 (= ζ-α/β/γ/δ/ε) (3) 案 X/Y/Z/W 再評価 (4) 真 root cause 4 候補 (5) 不可触対象 (6) allowed-touch 例外 (7) verify+audition gate (8) 禁止表現リスト (9) Draft → Accepted 移行 trigger |
| ADR-0048 状態行 + 改訂履歴 update | 状態行 = Draft 維持 (= ζ-α は起票のみ、 ζ-ε で Accepted 移行)、 改訂履歴に ζ-α entry 追加 |
| dashboard 同期 (= ADR-0048 軸 G 行 + escalation 履歴 entry) | 軸 G 行 status column に ζ-α 完了 reflect、 escalation 履歴に ζ-α entry literal |

### ζ-α 5 sub-sprint 構成 (= ζ-α/β/γ/δ/ε、 PR 形式 = single-doc-pr-A (ζ-α のみ) + chain-pr-A (ζ-β/γ/δ/ε))

ADR-0048 ζ 全体は 5 sub-sprint で完成する。 PR 形式:

- **ζ-α** = **single-doc-pr-A** (= ADR-0056/0060 同形式、 単一 doc-only PR で起票 + Codex layer 2 review、 main agent 自律完走範囲)
- **ζ-β/γ/δ/ε** = **chain-pr-A** (= ADR-0058/0059 同形式、 sub-sprint chain で各 1 PR + Codex layer 2 review、 ζ-β 着手は user GO 必須、 ζ-β 以降 chain-pr-A 全体は user GO 待ち)

各 sub-sprint の scope + driver touch + user gate を literal 化:

| sub | 内容 | driver touch | user gate |
|---|---|---|---|
| **ζ-α** (= 本 sub-section) | 起票 doc-only filing (= ADR-0048 本文に ζ section additive 追加 + 案再評価 + 不可触対象 + allowed-touch 例外 + sub-sprint plan literal 化) | なし | なし (= main agent 自律完走、 Codex layer 2 plan review approve + ζ-α doc review 経由) |
| **ζ-β** | 実装 (= case 選定確定後の driver implementation、 v2 wrapper extension or 並設) | **allowed-touch 例外 適用** (= 下記 §allowed-touch 例外条件) | **user GO 必須** (= case 最終選定 + 着手判断) |
| **ζ-γ** | verify script 体系化 (= integration 同居 audition fixture + register trace + audio gate) | verify script 新規のみ (= driver touch なし) | なし (= ζ-β 完了後の continuation) |
| **ζ-δ** | 越川氏 audition gate (= ADR-0056 §決定 3 production-ready gate 4 系統最終 gate) | なし (= audition session) | **user 介入必須** (= 越川氏 audition + judgment) |
| **ζ-ε** | completion + ADR-0048 Draft → Accepted 移行 doc-only | なし | **user 判断 gate** (= audition approve 後の Accepted 移行 trigger) |

### 案 X/Y/Z/W 再評価 (= ADR-0058 δ-5 finding stale 化 + ADR-0060 §決定 1-4 反映)

ADR-0048 sub-sprint ζ 着手準備 (= 同 ADR 内 L953-1006) の 3 案 (= X/Y/Z) は ADR-0060 §決定 1-4 で再評価された。 本 ζ-α では再評価結果 literal + ADR-0060 §決定 2 case 1 由来の新案 W を追加:

| 案 | ADR-0048 ζ 着手準備当時評価 | 本 ζ-α 再評価 (= ADR-0060 §決定 1-4 反映) |
|---|---|---|
| **案 X** TIMER-B IRQ rate 構造改修 | 第二候補 (= 既存 driver 改修、 ε scope 超え) | **不要** (= ADR-0058 δ-5 ~492 Hz literal 実測で 1 ms 想定通り、 改修不要、 ADR-0060 §決定 1 stale 化確定) |
| **案 Y** MML 拡張で J part PPC keyon | 第三候補 (= 軸 F defer 解除必要、 ADR-0044 ζ scope 別軸) | **継続候補** (= MML 経路で song-driven PPC 切替、 軸 F defer 解除は user 判断別軸、 軸 F なしでも部分実装可能性) |
| **案 Z** init 経路順次発火 | **第一候補** (= 主軸推奨 + user 仮判断) | **継続候補 + ADR-0058 IRQ tick 駆動整合検討必要** (= ADR-0058 δ で IRQ tick 駆動 (~492 Hz) 確立済 = init 経路順次発火と並走 or 統合可能か再評価必要) |
| **新案 W** v2 driver KIND=2 経路 PPC 切替 | ADR-0048 当時不可 (= roadmap ②/③ 未完了) | **主軸推奨 candidate (= 確定ではない、 ζ-β 着手時 user 判断 gate)** (= ADR-0060 §決定 2 case 1 採用 = v2 wrapper 内 driver_pne_sample_table_id bit7 save/set/call/restore、 song-driven PPC 切替、 ADR-0058 IRQ tick 駆動と統合済、 ADR-0048 当時 roadmap ②/③/④ 未完了で不可能だった新候補) |

**最終選定 = ζ-β 着手時 user 判断 gate (= Codex review + user judgment AND 必須条件)**。 ζ-α では「主軸推奨 candidate (= 確定ではない)」 で止める。 案 W/Y/Z 並列候補、 case 最終選定は user GO 後。

### 真 root cause 候補 enumeration (= ADR-0048 ε partial integration 同居 reject 再評価、 ADR-0060 §決定 3 reference)

ADR-0048 ε partial の integration 同居 reject の真 root cause 候補 (= ADR-0058 δ-5 TIMER-B finding stale 化に伴う再評価):

1. **同居 fixture 設計不足** = ADR-0048 ε partial fixture は単発 keyon のみ = 3 経路同居 (= PPC + yaml beat + ADPCM-A) の時系列並走 fixture 未実装
2. **単発 keyon 設計** = init 経路 1 度 trigger だけでは同居 audition 不可、 周期 trigger or sequence 化必要
3. **トリガ timing 設計不足** = ADR-0058 δ IRQ tick 駆動 (= ~492 Hz 周期再生) を活用すれば解消可能性
4. **越川氏 audition 期待値 align 不足** = ε partial reject literal「FM / ADPCM-A / 既存 yaml beat 経路との同居 audition にはなっていません」 から integration audition target fixture の明確化必要

これらは **ζ-β 着手時 + ζ-γ verify gate 設計時 + ζ-δ audition 設計時の調査軸**。 ζ-α では候補列挙 literal のみ、 確定は後続 sub-sprint。

### 不可触対象 (= ζ-α 全 sub-sprint 共通、 ADR-0060 §決定 6 継承 + 補完)

次を **完全不可触** とする (= ζ-α は全 sub-sprint 通算、 ζ-β は allowed-touch 例外条件下で部分例外):

- **ADR-0049〜0060 routine body** (= mute / fade-out / SSG tone-enable / v2 entry / SRAM placement / F-2-B / 軸 C/G/rhythm 接続点 / song parse + dispatch + IRQ + tempo / ADPCM-B/rhythm 実 dispatch + roadmap ④ 依存整理)、 ζ-β allowed-touch 例外除く
- 既存 `adpcmb_keyon` body / `pmdneo_select_adpcmb_ppc_pointer` body / `pmdneo_select_adpcmb_sample_pointer` body
- 既存 `pmdneo_rhythm_event_trigger` body + `_rhythm_event_*_trigger` 全部
- 既存 cmd 0x05 path / `pmdneo_song_main` / `pmdneo_part_main` / `commandsp` / `part_workarea` (= 0xF820-)
- `irq_handler_body` 既存処理 + ADR-0050 fade tick + ADR-0058 song tick 既存処理
- ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` (= driver-embedded fixture)
- **vromtool.py / compile.py / PMDDotNETCompiler** = vendor 範囲、 ADR-0048 ζ では一切 touch なし
- vendor / vendor wav 3 件 + 未確認 untracked MML 3 件 (= user 明示永続 scope-out)
- **軸 G ε partial state** (= ppc_scratch 0xFD33-0xFD36 / audition_frame_counter 0xFD37-0xFD38) = ζ-β で **sentinel/contract 不変な state 拡張のみ許容** (= ADR-0048 §決定 8 案 C 維持 + ADR-0060 §決定 6 不可触原則継承、 既存 placement 不変 + 新規 field 追加のみ許容)
- ADR-0048 sub-sprint α/β/γ/γ revision/δ/ε partial の本文 literal (= 履歴改変 risk 回避、 本 ζ-α 起票は additive 追加のみ、 既存 sub-sprint section の本文 modify なし)

### allowed-touch 例外 (= ζ-β 着手時のみ、 3 条件 AND 必須)

ζ-β 実装時、 以下 **3 条件 AND** を満たす場合に限り **v2 wrapper extension** (= `pmdneo_v2_adpcmb_voice_note_song` 相当 routine の修正 or 並設 routine 追加) を allowed-touch 例外として扱う:

1. **ADR-0048 ζ-β sub-sprint 着手** (= ζ-α MERGED + ζ-β branch 作成後)
2. **user 明示 GO** (= case 最終選定 + 着手判断 user judgment)
3. **case 選定確定** (= Codex layer 2 review + user judgment AND、 案 W/Y/Z のいずれを採用するか確定)

allowed-touch 例外対象:

- **案 W 採用時**: `pmdneo_v2_adpcmb_voice_note_song` (= ADR-0059 §決定 4 routine) の **保持** (= modify ではなく、 内部に case 1 save/restore bit7 sequence を additive 追加可能、 既存 default voice 0 経路は保持) または並設 v2 wrapper (= `pmdneo_v2_adpcmb_voice_note_song_ppc` 等の新 routine) の追加
- **案 Z 採用時**: 既存 init 経路 (= ADR-0048 ε partial で確立した init 経路強制 keyon) を sequence 化拡張、 既存 `nmi_clear_driver_state` の body 不変 + 並設 routine 追加
- **案 Y 採用時**: 軸 F defer 解除なしで v2 driver-side で MML 経路 partial 実装の場合のみ、 v2 driver 範囲で wrapper 追加

ζ-α 時点では **case 最終選定は確定しない** (= ζ-β user GO + case 選定確定 AND 必須)。

### verify + audition gate target (= ζ-γ + ζ-δ scope)

#### ζ-γ verify script 体系化 (= integration 同居 audition fixture + register trace)

- integration 同居 fixture (= **3 経路同居 trigger** = PPC + yaml beat + ADPCM-A の時系列並走)
- register trace primary gate = PPC 経路 reg 0x10/0x12-0x15/0x19/0x1A/0x1B (= ADPCM-B chip) + yaml beat 経路 reg + ADPCM-A L ch reg 全観測
- baseline regression = ADR-0058/0059/0060 全 verify ALL PASS 維持 (= 既存 verify-axis-b-v2-song-playback.sh + verify-axis-b-v2-roadmap3-dispatch.sh)
- supplemental gate (= ζ-β case 選定に応じて確定)

#### ζ-δ 越川氏 audition gate (= ADR-0056 §決定 3 4 系統最終 gate)

- **越川氏 audition target = 「integration 同居 audition approve」** (= ADR-0048 ε partial reject literal「FM / ADPCM-A / 既存 yaml beat 経路との同居 audition にはなっていません」 を解消)
- audition session = user 介入必須 (= 越川氏 listening + judgment)
- audition approve = ADR-0048 ζ-ε Draft → Accepted 移行 trigger

### 禁止表現リスト (= 全 sub-sprint で literal 維持)

ADR-0048 ζ-α から ζ-ε までの全 sub-sprint で以下表現を **literal 禁止**:

- 「軸 B 完成」 (= v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過後)
- **「軸 G 完成」** (= ADR-0048 ζ-ε Accepted 移行までは「ζ-ε で軸 G dynamic supply 完成」 表現を慎重に使用、 audition approve 後のみ)
- **`axis-G dynamic supply complete` (英語版)** (= 同上)
- **「軸 G dynamic supply 完成」** (= 同上、 ζ-ε Accepted 移行後のみ)
- 「production-ready 全体達成」 (= ADR-0056 §決定 3 4 系統全通過 + 越川氏 audition approve 後の future)

ζ-ε Accepted 移行時の Accepted 表記制約 (= ADR-0058 ζ pattern 継承):

- ADR-0048 Accepted = 軸 G dynamic supply 完成 (= ζ-α/β/γ/δ/ε 全完走 + audition approve)
- ≠ production-ready 全体達成 (= ADR-0056 §決定 3 全 gate + 本番 cmd 切替 user 判断後の future)
- ≠ 「軸 B 完成」 (= v2 driver production-ready 化 + 本番 cmd 切替後の future)

### Draft → Accepted 移行 trigger (= ζ-ε)

ADR-0048 Draft → Accepted 移行は **ζ-ε で実施** (= ζ-α/β/γ/δ 完了 + 越川氏 audition approve + user 判断後)。 ζ-α では Draft 状態維持。

移行条件 (= ζ-ε 着手判定):

- ζ-α/β/γ/δ 全完走 (= 各 sub-sprint Codex layer 2 review approve + PR MERGED)
- ζ-δ 越川氏 audition approve (= integration 同居 audition approve、 ε partial reject literal 解消)
- user 明示 GO (= ζ-ε Draft → Accepted 移行判断)

ζ-ε 完了 = ADR-0048 Accepted = 軸 G dynamic supply 完成 (= ただし production-ready 全体達成 ≠ 「軸 B 完成」 ≠ 本番 cmd 切替、 これらは更に user 判断 gate)。

### ζ-α 起票 verify gate (= doc-only filing、 spec consistency check)

- ADR-0048 本文 ζ-α section additive 追加のみ (= 既存 sub-sprint section + 本文 literal 全不変、 履歴改変 risk 回避)
- driver / verify script / vendor / vromtool.py / compile.py / spike / fixture 完全不変
- m1 binary byte-identical 維持期待 (= ADR-0048 ζ-α は doc-only filing で通算 sha256 b15883fe... 維持)
- 軸 G ε partial state (= 0xFD32-0xFD38) + Draft 状態維持
- ADR-0049〜0060 routine body 完全不変
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain

### ζ-α Codex layer 2 review chain (= 全 approve、 起票 GO)

- **plan review round 1** = **revise** (= 3 must-fix + 2 nice-to-have、 ζ-β allowed-touch 例外明文化 + 不可触対象漏れ補完 + 案 W 確定度を下げる + 名称衝突回避 + 禁止表現英語版追加)
- **plan review round 2** = **approve** (= round 1 must-fix 3 + nice-to-have 2 全反映、 追加修正なし、 ζ-α 起票 GO + 主軸自律進行)
- **doc review** (= 後続 commit 後投入予定)

## sub-sprint ζ-β 実装 (= 2026-05-23 39th session、 軸 G dynamic supply v2 PPC 経路 案 W 実装、 chain-pr-A 1 本目、 user case 選定 final confirmation = 案 W 確定経由)

### ζ-β 着手条件 = ADR-0048 ζ-α §allowed-touch 例外 3 条件 AND 全充足

| 条件 | 充足判定 |
|---|---|
| (1) ζ-β sub-sprint 着手 (= ζ-α MERGED + ζ-β branch 作成後) | **充足** (= ζ-α PR #109 MERGED、 ζ-β branch `wip-adr-0048-zeta-beta-axis-g-v2-ppc-case-w` 作成) |
| (2) user 明示 GO | **充足** (= user「次は ζ-β 着手判断でよいです」 + AskUserQuestion 回答「案 W (推奨) を選んでください」) |
| (3) case 選定確定 | **充足** (= Codex layer 2 plan review 3 round chain approve + user AskUserQuestion confirmation = **案 W 確定**) |

### ζ-β deliverable (= driver active code 拡張 + build flag + ADR doc + dashboard)

- `standalone_test.s` 新規 build flag `TEST_MODE_AXIS_G_V2_PPC` (= default 0、 sdasz80 `.if FLAG` binary toggle 規律遵守)
- `standalone_test.s` SRAM scratch `.equ pmdneo_v2_ppc_bit7_scratch, 0xFD61` (= v2 wrapper transient scratch、 軸 G ε partial state 0xFD32-0xFD38 とは別領域、 残 free 0xFD62-0xFD78 = 23 byte)
- `standalone_test.s` KIND 定数 `.equ PMDNEO_V2_KIND_ADPCMB_PPC, 4` (= ADR-0059 KIND=0/1/2/3 + 4 additive)
- `standalone_test.s` SRAM layout comment update (= 0xFD61 scratch + 0xFD62-0xFD78 free 23 bytes)
- `standalone_test.s` `pmdneo_v2_part_dispatch_note` KIND=4 分岐 additive (= `.if TEST_MODE_AXIS_G_V2_PPC` 配下、 KIND=3 jr z 直後)
- `standalone_test.s` `pmdneo_v2_adpcmb_voice_note_song_ppc` 並設新設 (= `.if TEST_MODE_AXIS_G_V2_PPC` 配下、 既存 `pmdneo_v2_adpcmb_voice_note_song` 不変)
- `standalone_test.s` `pmdneo_v2_song_init` slot 9 init binary toggle (= `.if/.else/.endif` で KIND=2 / KIND=4 切替)
- `standalone_test.s` `pmdneo_v2_song_fixture_adpcmb_j_ppc` 新規 fixture (= `.db 0x00, 0x10, 0x01, 0x10, 0x00, 0x10, 0x80` = PPC entry 0 → 1 → 0 → loop)
- `scripts/build-poc.sh` + `vendor/ngdevkit-examples/00-template/build.mk` flag passing 追加

### ζ-β 実装核心 = bit7 save/restore + lower 7 bit = PPC entry index 経路

ζ-β wrapper `pmdneo_v2_adpcmb_voice_note_song_ppc` は `driver_pne_sample_table_id` (= 0xFD32) を以下 sequence で route 化:

1. 関数 entry 時の 0xFD32 全 byte を `pmdneo_v2_ppc_bit7_scratch` (= 0xFD61) に save
2. A = song-driven note byte の lower 7 bit を `and #0x7F` で抽出 = PPC directory entry index (= 0-127 範囲)
3. `or #0x80` で bit7=1 set = 軸 G 経路侵入 trigger
4. 修正値 (= bit7=1 + lower 7 bit = PPC entry index) を 0xFD32 に格納
5. shim base 設定 + voice index 0 (= PPC 経路では unused、 ADR-0059 §決定 3 互換 init)
6. A=note byte 復元 = adpcmb_keyon delta-N 計算用
7. `call adpcmb_keyon` (= ADR-0043 entry 本体不可触) で軸 G 経路 (= `pmdneo_select_adpcmb_ppc_pointer`、 ADR-0048 軸 G δ partial routine) 経由 reg 0x12-0x15 + 0x19/0x1A + 0x10 emit
8. 単一 epilogue (= `pmdneo_v2_adpcmb_voice_note_song_ppc_done`) で 0xFD32 restore + pop ix + ret

### ζ-β fixture build flag 完全分離 (= ADR-0059 sup-sample-table-id-bit7-clear gate 維持)

- **production build** (= 両 flag clear) = m1 binary byte-identical 維持 (= 通算 sha256 b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4)
- **ADR-0059 fixture build** (= `TEST_MODE_V2_SONG_FIXTURE=1` + `TEST_MODE_AXIS_G_V2_PPC=0` default) = roadmap ③ scope 維持、 `sup-sample-table-id-bit7-clear` gate 不変 (= bit7=1 write 0 件 literal)
- **ADR-0048 ζ-β fixture build** (= 両 flag 1) = 軸 G 経路 active、 新 gate `zeta-beta-bit7-save-restore-entry-select` 観測対象 (= ζ-γ verify script で実装)

### ADR-0049〜0060 routine body 不可触遵守

- 既存 `adpcmb_keyon` body / `pmdneo_select_adpcmb_ppc_pointer` body / `pmdneo_select_adpcmb_sample_pointer` body 完全不変
- 既存 `pmdneo_v2_adpcmb_voice_note_song` (= ADR-0059 KIND=2 routine) 完全不変、 並設 routine 追加のみ
- `pmdneo_v2_part_dispatch_note` KIND=4 分岐 additive (= ADR-0059 §決定 6 allowed-touch extension pattern 継承、 既存 KIND=0/1/2/3 分岐不変)
- `pmdneo_v2_song_init` slot 9 init binary toggle (= ADR-0048 ζ-α §allowed-touch 例外、 `.if/.else/.endif` で KIND=2 / KIND=4 切替、 既存 KIND=2 init は production + ADR-0059 fixture で維持)
- 軸 G ε partial state (= 0xFD32-0xFD38) は **save/restore で同一値復元** = 既存 placement 不変 + sentinel/contract 不変

### ζ-β 検証結果

- **production build** (= 両 flag clear): **PASS** + **m1 binary byte-identical 維持** (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で ζ-β commit 後も同一 binary)、 ζ-β 全 routine + KIND=4 分岐 + slot 9 init KIND=4 path + fixture 全 `.if TEST_MODE_AXIS_G_V2_PPC` 配下未 assemble (= .lst で routine label の address 割当なし、 byte 非出力 confirmed)
- **ζ-β fixture build** (= `PMDNEO_V2_SONG_FIXTURE=1` + `PMDNEO_AXIS_G_V2_PPC=1` + ym2610): **PASS** + ζ-β routine 全 assemble:
  - `pmdneo_v2_part_dispatch_note_adpcmb_ppc:` @ 0x0B63
  - `pmdneo_v2_adpcmb_voice_note_song_ppc:` @ 0x0BB6
  - `pmdneo_v2_song_fixture_adpcmb_j_ppc:` @ 0x0C27
- baseline regression = ADR-0049〜0060 routine body 完全不変 (= 通算 sha256 維持で trivially 維持)
- ζ-γ verify script (= 新 gate `zeta-beta-bit7-save-restore-entry-select`) = 後続 sub-sprint

### ζ-β Codex layer 2 review chain

- **plan review round 1** = **revise** (= 2 must-fix = ζ-β 専用 fixture selector + verify gate 明示 + 2 nice-to-have + 5 risk literal)
- **plan review round 2** = **revise** (= 1 must-fix = adpcmb_keyon PPC entry index は `driver_pne_sample_table_id` lower 7 bit 由来、 A=note byte ではない)
- **plan review round 3** = **approve** (= 全反映、 案 W skeleton + ζ-γ gate 全 source 整合、 must-fix なし + nice-to-have 1 件 (= `and #0x7F` → `or #0x80` 順序 static gate))
- **user case 選定 final confirmation** = 案 W 確定 (= AskUserQuestion 回答)
- **implementation review** (= 後続 commit 後投入予定)

## sub-sprint ζ-γ verify script 体系化 (= 2026-05-23 39th session、 ADR-0048 ζ-β 案 W 実装の verify proof、 chain-pr-A 2 本目、 user 明示 5 重点 gate + ζ-β literal gate 統合)

### ζ-γ 着手条件 (= chain-pr-A 2 本目)

- ζ-β implementation 完走 (= PR #118 MERGED、 chain-pr-A 1 本目、 Codex layer 2 implementation review round 1 revise 2 must-fix (= ADR-0048 ζ-α section 行書き換え修正 + fixture build .lst 再確認) → 反映 → main agent self-approve + merge)
- user 明示「次は ζ-γ でよいです」 + 5 重点 gate 提示
- ζ-γ scope = main agent 自律完走範囲 (= verify script + ADR-0048 ζ-γ section additive + dashboard)、 ζ-δ user audition は別 sub-sprint で user GO 待ち

### ζ-γ deliverable

- `src/test-fixtures/axis-g/verify-axis-g-zeta-beta-dispatch.sh` 新規 = primary 8 gate + supplemental 5 gate = **13 gate** + completion proof line 16 行
- ADR-0048 本文に ζ-γ section additive 追加 (= 既存 ζ-α/ζ-β section + ζ-γ row 当時 literal 不変、 audio gate scope 訂正注記 literal 内蔵)
- dashboard sync (= 予約簿 0048 軸 G 行 + 軸 G 行 status column + escalation 履歴 ζ-γ entry)

### ζ-γ 実装核心 = user 明示 5 重点 gate + ζ-β literal gate 5 proof 統合

#### primary 8 gate

| # | gate | user 明示 / ζ-β literal 由来 |
|---|---|---|
| 1 | bit7 save/set/restore sequence | user 明示 #1 + ζ-β proof (a)(b) |
| 2 | lower 7 bit = PPC entry index song-driven 変化 | user 明示 #2 + ζ-β proof (c) |
| 3 | PPC pointer register write 変化 | user 明示 #3 + ζ-β proof (d) |
| 4 | 全 exit driver_pne_sample_table_id restore | user 明示 #4 + ζ-β proof (e) |
| 5 | ADR-0049〜0060 baseline regression | user 明示 #5 (= verify-axis-b-v2-roadmap3-dispatch.sh transitive) |
| 6 | production byte-identical + build-mode 排他 | 追加 (= ADR-0058/0059 ε pattern) |
| 7 | ζ-β wrapper 経路 + 既存 routine 不可触 (= diff base pin `11655cb`) | 追加 (= round 2 must-fix B) |
| 8 | integration preview = 同一 trace co-existence | 追加 (= round 1 must-fix A、 ADR-0048 ζ-α §sub-sprint 構成 ζ-γ row literal「integration 同居 audition fixture」 の preview proof) |

#### supplemental 5 gate

- sup-IX-saved / sup-KIND-4-dispatch / sup-slot-9-init-binary-toggle / sup-fixture-loop / sup-fixture-byte-sequence

### audio gate scope 訂正注記 (= round 1 must-fix A 反映、 履歴改変 risk 回避)

ADR-0048 ζ-α §sub-sprint 構成 ζ-γ row literal は当時:

> ζ-γ | verify script 体系化 (= integration 同居 audition fixture + register trace + audio gate)

ζ-γ 実装段階で判明した scope clarification:

- **ζ-γ 実装範囲**: ζ-β routine register trace primary gate + **integration preview gate** (= 同一 trace run 内 PPC ADPCM-B reg + ADPCM-A reg co-observation = co-existence preview proof)
- **ζ-δ scope に移動**: 本格 integration 同居 audition fixture (= 3 経路同居 trigger) + audio gate (= wav artifact existence + 越川氏 audition)

ADR-0048 ζ-α §sub-sprint 構成 ζ-γ row 当時 literal は **不変**維持 (= ADR-0058 ε rename 注記 / ADR-0059 ε slot base address 訂正注記 と同 pattern)。

### ζ-γ 検証結果 (= 13 gate ALL PASS literal)

- ζ-β fixture build (= 両 flag 1 + ym2610): **PASS**
- production build (= 両 flag clear): **PASS** + **m1 binary byte-identical 維持** (= sha256 b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4)
- `verify-axis-g-zeta-beta-dispatch.sh` **13 gate ALL PASS** literal:
  - gate 1: 0xFD32 bit7=1 write 70 件 + bit7=0 restore 70 件
  - gate 2: lower 7 bit uniq 2 件 (= entry 0/1 切替)
  - gate 3: reg 0x12-0x15 uniq ≥ 2 per register
  - gate 4: 単一 epilogue 経由全 exit (= tick body 内 ret 直接出現なし)
  - gate 5: verify-axis-b-v2-roadmap3-dispatch.sh 12 gate ALL PASS
  - gate 6: m1 sha256 baseline 一致 + ζ-β routine 3 件 全 assemble なし
  - gate 7: and #0x7F → or #0x80 順序 + call adpcmb_keyon + ld ix #shim + 既存 body 4 labels diff `11655cb..HEAD` = 0 lines
  - gate 8: PPC ADPCM-B reg 284 件 + ADPCM-A reg 212 件 (= co-existence proof)
  - supplemental 5 gate 全 PASS
- completion proof line 16 行 literal 出力 + **ζ-δ audition 移行 ready: yes signal**

### ζ-γ Codex layer 2 review chain

- **plan review round 1** = **revise** (= 2 must-fix = integration 同居 + audio gate scope clarification + gate-7(d) diff base 明示 pin + 3 nice-to-have)
- **plan review round 2** = **revise** (= 3 minor must-fix = completion proof line 行数訂正 15→16 + production .lst path 明示 + ADR-0048 doc sync policy 明示)
- **plan review round 3** = **approve** (= 全反映確認、 must-fix なし + nice-to-have なし、 ζ-γ kickoff GO + main agent 自律完走)
- **implementation review** = round 1 revise 3 must-fix (= ζ-β section 行書き換え修正 + dashboard L15/L242 ζ-γ 反映 + L168 禁止語句 literal 参照形式化) → 反映 → main agent self-approve + merge (= PR #119)

## sub-sprint ζ-δ-1 integration 同居 audition fixture + wav 生成 + audition request (= 2026-05-23 39th session、 chain-pr-A 3 本目、 option A 採用 = user AskUserQuestion confirmation 経由)

### ζ-δ 着手判断 + user 介入分離

ζ-γ PR #119 MERGED + `ζ-δ audition 移行 ready: yes signal` 出力後、 user 明示「次は ζ-δ audition です。 ここは user 介入必須」 + audition target「PPC + yaml beat + ADPCM-A の同居 audition」 + 「ADR-0048 はまだ Draft であり、 ζ-ε までは Accepted 扱いにしないでください」。

ζ-δ は **2 stage 分離**:
- **ζ-δ-1** (= 本 sub-section) = main agent autonomous part
- **ζ-δ-2** = user 介入必須 part = 越川氏 audition session + judgment

### ζ-δ-1 case 選定 = option A (= user AskUserQuestion confirmation)

user 確定: ζ-β fixture pattern を拡張し、 entry 0 / entry 1 / yaml beat marker (= 0x7F) を交互 trigger する option A 採用。 driver active code 変更は ζ-δ allowed-touch 例外として ADR 明記、 既存 routine body 不可触 + ADR-0048 Draft 維持 + ζ-ε まで Accepted にしない規律維持。

### ζ-δ allowed-touch 例外 = 4 条件 AND

ADR-0048 ζ-α §allowed-touch 例外 3 条件 (= ζ-β 着手 + user GO + case 選定確定) を ζ-δ で拡張、 **(4) audition target = PPC + yaml beat + ADPCM-A 同居 audition (= ε partial reject literal 解消)** 追加。 4 条件 AND 全充足下で ζ-β wrapper + fixture の additive 拡張を allowed-touch 例外として扱う。 ζ-β wrapper body 構造は完全不変、 内部 branch additive (= yaml beat marker 0x7F 認識 path) のみ追加。

### ζ-δ-1 deliverable (= main agent autonomous part)

- `standalone_test.s` `pmdneo_v2_adpcmb_voice_note_song_ppc` wrapper 内部 branch additive (= yaml beat marker 0x7F 認識 + bit7=0 + lower 7 bit=0 = ADR-0043 経路 yaml beat trigger)
- `standalone_test.s` fixture pattern expand (= `0x00, 0x10, 0x01, 0x10, 0x7F, 0x10, 0x80` = entry 0 / entry 1 / yaml beat marker / loop)
- `verify-axis-g-zeta-beta-dispatch.sh` extend (= 既存 13 gate + ζ-δ 新 gate 2 件 + completion proof line 16 → 18 行)
- MAME headless audition wav artifact 生成 (= `/tmp/zeta-delta-audition.wav` 約 1.9 MB、 **wav 非 commit**)
- ADR-0048 本文 ζ-δ section additive (= 本 sub-section、 既存 ζ-α/ζ-β/ζ-γ section + ζ-δ row 当時 literal 完全不変)
- dashboard sync

### ζ-δ-1 検証結果 (= 15 gate ALL PASS + audition session ready signal)

- production build (= 両 flag clear): **PASS** + **m1 binary byte-identical 維持** (= 通算 sha256 b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4)
- ζ-β fixture build (= 両 flag 1 + ym2610): **PASS**
- `verify-axis-g-zeta-beta-dispatch.sh` **15 gate ALL PASS** literal:
  - 既存 primary 8 + supplemental 5 = 13 gate 維持
  - 新 gate `zeta-delta-yaml-beat-marker`: lower 7 bit uniq 2 + 0x7F fixture byte 静的存在 + wrapper `cp #0x7F` + `xor a` + `ld (driver_pne_sample_table_id),a` 3 命令 sequence 静的存在
  - 新 gate `zeta-delta-adpcma-coexistence`: ADPCM-A reg port B write ≥ 1 件 (= slot 10 rhythm 並走 proof)
- completion proof line 18 行 literal 出力 + **`ζ-δ-2 audition session ready: yes` signal**
- audition wav artifact = `/tmp/zeta-delta-audition.wav` 約 1.9 MB (= 10 秒 PCM、 **git commit 非対象**)

### audition request literal (= ζ-δ-2 user 介入必須 sub-sprint)

```
ζ-δ audition request (= ADR-0048 ε partial reject literal 解消 target):

wav artifact: /tmp/zeta-delta-audition.wav (= ζ-β fixture build + 両 flag 1 + ym2610 + MAME headless 10 秒)

聴感目標:
- audition.wav 冒頭から終盤まで、 PPC 経路の ADPCM-B sample (= ζ-β fixture pattern PPC entry 0/1 切替)
  + yaml beat marker (= 0x7F note byte → ADR-0043 経路 yaml beat sample trigger) が連続的に鳴ること
  (= ε partial「1 発のみ」 解消)
- 同時に既存 v2 song dispatch 経由で FM B (= slot 0) + SSG G (= slot 1) + ADPCM-A rhythm (= slot 10、
  BD/SD/BD bitmap pattern) も時系列で並走鳴動すること
- 全 4+ 経路 (= FM B + SSG G + PPC ADPCM-B + yaml beat ADPCM-B + ADPCM-A rhythm) が同居 audition として
  聴感確認できること (= ε partial reject literal「FM / ADPCM-A / 既存 yaml beat 経路との同居 audition には
  なっていません」 解消)
- ※ 0x7F note byte は delta-N 計算にも渡るため音程変化あり、 audition fixture marker 由来 = route proof
  が主目的、 聴感は marker note の delta-N と route 経由 sample 鳴動の組合せ

audition request:
- 上記 4+ 経路同居 audition の approve / reject / partial approve judgment を user (= 越川氏) にお願い
- approve = ADR-0048 ζ-ε Draft → Accepted 移行 trigger (= ただし production-ready 全体達成 ≠ 「軸 B 完成」
  ≠ 本番 cmd 切替、 これらは更に user 判断 gate)
- reject = ζ-δ-1 fixture / wrapper 改修 + 再 audition
- partial approve = part 経路のみ approve、 残部分 ζ-δ-1 改修 + 再 audition
```

### ADR-0048 Draft 状態維持 (= user 明示遵守)

user 明示「ADR-0048 はまだ Draft であり、 ζ-ε までは Accepted 扱いにしないでください」 を literal 遵守。 ADR-0048 状態行 = Draft 維持。 ζ-ε で audition approve 後 + user 判断 = Accepted 移行 trigger (= 軸 G dynamic supply 完成)、 production-ready 全体達成 / 「軸 B 完成」 / 本番 cmd 切替は更に user 判断 gate。

### ζ-δ-1 Codex layer 2 review chain (= plan)

- **plan review round 1** = **revise** (= 1 重大 must-fix = yaml beat 経路同居 driver 変更必要、 案 A だけでは PPC + ADPCM-A まで) → user AskUserQuestion confirmation で **option A 確定**
- **plan review round 2** = **revise** (= 3 must-fix = gate uniq 条件修正 + ADR additive 順序 + sup-fixture-byte-sequence 文言 update + 2 nice-to-have + 2 latent risk)
- **plan review round 3** = **approve** (= 全 8 件反映、 must-fix なし、 ζ-δ-1 着手 GO)
- **implementation review** (= 後続 commit 後投入予定)

### ζ-δ-2 待機 (= user 介入必須 sub-sprint)

main agent は ζ-δ-1 完了後、 越川氏 audition session result 報告を待つ。 audition approve → main agent が ADR-0048 ζ-δ section additive で audition result literal + ζ-ε への遷移 (= user GO 必須)。 audition reject → ζ-δ-1 改修 + 再 audition。 partial approve → 部分改修 + 再 audition。 ζ-ε Draft → Accepted 移行は audition approve 後 + user 判断 gate、 main agent autonomous で Accepted 化しない。

## sub-sprint ζ-δ-2 audition reject + audition fixture revise (= 2026-05-23 39th session、 chain-pr-A 4 本目、 user audition reject judgment 受領 + 改修方向 spec literal 5 件確定経由)

### ζ-δ-2 経緯 (= user audition reject judgment literal)

ζ-δ-1 完了後の ζ-δ-2 user audition session で、 越川氏は `/tmp/zeta-delta-audition.wav` に対し下記 judgment を literal で報告した:

- **ADR-0048 は Draft 維持** (= ζ-ε には進まず)
- **/tmp/zeta-delta-audition.wav は approve しない**
- **ζ-δ-1 fixture を再設計して再 audition** = audition fixture revise sub-sprint = **ζ-δ-2 起票**

改修方向 (= user 明示 spec literal 5 件):

- **FM B**: 持続音ではなく、 短いアタックの反復音にする
- **SSG G**: FM と同じく短く区切る
- **ADPCM-B**: PPC0 → PPC1 → yaml beat marker の順番が分かるようにする
- **ADPCM-A rhythm**: BD → SD → BD の識別を維持
- **全体**: 10 秒の中で「4+ 経路が同時に成立している」 と判断しやすい構成にする

改修方向の核心は **音楽的綺麗さ scope-out + 経路聞き分け target**。

### ζ-δ-2 切り分け 5 件 (= main agent ε partial 同形式、 register trace literal 由来)

main agent ζ-δ-1 audition wav register trace 解析:

| 切り分け | 観察値 | 期待値 | 結果 |
|---|---|---|---|
| 1. FM B keyon (= reg 0x28 = 0xF1) 件数 | 149 件 | 約 150 件 (= 50 loop × 3 note) | PASS = song-driven keyon 正常 trigger |
| 2. FM B fnum LSB (= reg 0xA1) uniq | 4 種 (= 0x39 / 0x6A / 0xB6 / 0xD5) | 3 種以上 | PASS = fnum 切替正常動作 |
| 3. FM B fnum/block MSB (= reg 0xA5) uniq | 2 種 (= 0x1A / 0x1B) | 1-3 種 | PASS = block + fnum upper 切替動作 |
| 4. FM voice 音色 = `fm_voice_data_default` envelope | DR=0x00 / SR=0x00 / SL=0x00 = sustain hold 持続音色 | percussive 期待 | **finding** = 持続音色 (= default 音色由来 root cause) |
| 5. wav 長さ = MAME `--wavwrite-seconds 10` cap | 10 秒で wav 強制終了 | 10 秒 audition target | **finding** = wav 末尾で audio 強制 cut off |

切り分け 1/2/3 = **FM B 経路は register level で song-driven 正常動作 confirmed** (= keyon 149 件 ≈ 150 件期待 + fnum 4 種切替)。
切り分け 4 = `fm_voice_data_default` の envelope 設定 (= DR=0x00 / SR=0x00 / SL=0x00) が「sustain hold 持続音色」 = 「ただの持続音」 の root cause。
切り分け 5 = 10 秒 wav cap で末尾 cut off = 「途中で切れる」 解釈、 audition target 10 秒以内なら問題なし。

### 改修内容 spec literal (= driver source additive、 4 軸)

| 軸 | 改修内容 | 実装 |
|---|---|---|
| **A. FM 新 voice 追加** | `fm_voice_data_audition` block 追加 (= percussive envelope: AR=31 / DR=15 / SR=15 / SL=15 / RR=15、 TL=0x10、 alg=7、 fb=0) + `pmdneo_v2_fm_voice_note_song` wrapper 内 binary toggle で audition fixture build 時のみ swap | `.if TEST_MODE_AXIS_G_AUDITION_REVISE` 配下で voice address swap、 `fm_voice_data_default` 完全不可触維持 |
| **B. fixture data length 改修** | slot 0 FM B + slot 1 SSG G = length 0x10 → 0x06 (= 約 24 ms = 短いアタック反復)、 slot 9 ADPCM-B PPC = length 0x10 → 0x30 (= 約 130 ms = sample 分離可聴)、 slot 10 ADPCM-A rhythm = length 0x10 → 0x14 (= 約 53 ms = BD/SD 識別維持) | `.if TEST_MODE_AXIS_G_AUDITION_REVISE` 配下で新 fixture block 並設、 既存 fixture 完全不可触維持 |
| **C. note byte 維持** | slot 9 ADPCM-B = 0x00 / 0x01 / 0x7F (= PPC entry 0 + entry 1 + yaml beat marker、 ζ-δ-1 と同) | PPC entry index range 安全保証 (= 0x00 / 0x01 既知 + 0x7F = ADR-0043 経路) |
| **D. build flag 追加** | `TEST_MODE_AXIS_G_AUDITION_REVISE` (= default 0)、 `TEST_MODE_AXIS_G_V2_PPC` の上位互換 (= ζ-δ-2 fixture build 時のみ ON、 ζ-δ-2 trigger flag) | `scripts/build-poc.sh` + `vendor/ngdevkit-examples/00-template/build.mk` |

### allowed-touch 例外 5 条件 AND (= ζ-α 4 条件 + audition reject judgment 1 条件 拡張)

ζ-α §allowed-touch 例外 4 条件 (= ζ-β 着手 + user GO + case 選定確定 + audition target = ζ-δ-1 で確立) に対し、 ζ-δ-2 は **「audition reject judgment 受領 + 改修方向 spec literal 5 件確定」** 1 条件 追加 = **5 条件 AND** で audition fixture revise sub-sprint 着手:

1. ζ-β 着手 (= 既)
2. user GO (= 既、 ζ-β 案 W 選定)
3. case 選定確定 (= 既、 案 W 確定)
4. audition target (= 既、 ζ-δ-1 で option A 確定)
5. **audition reject judgment + 改修方向 spec literal 5 件確定** (= 新、 ζ-δ-2 trigger)

allowed-touch scope literal (= ζ-δ-2):

- 既存 `fm_voice_data_default` 完全不可触
- 既存 fixture block (= `pmdneo_v2_song_fixture_fm_b` 等) 完全不可触
- 既存 wrapper routine body (= `pmdneo_v2_fm_voice_note_song` 等) 完全不可触
- 新規追加のみ = 新 voice block `fm_voice_data_audition` + 新 fixture block 並設 (= `pmdneo_v2_song_fixture_fm_b_audition` 等) + wrapper 内 binary toggle `.if` 配下 additive

### 軸 G 永続 scope-out (= ζ-δ-2 でも維持)

ADR-0048 ε partial 確立 + ζ-α/ζ-β/ζ-γ/ζ-δ-1 維持の 軸 G 永続 scope-out 9 項目 + ADR-0048 ζ-α §禁止表現リスト 5 件 (= 軸 G 完成系 3 件 + 軸 B 完成 + production-ready 全体達成) literal 維持。

### ζ-δ-2 完了判定 (= ζ-δ-1 同形式、 audition fixture revise 完了 = wav 生成 + user 提示 + ζ-δ-2 再 audition session ready)

- driver source 改修 PASS (= ADR additive + driver code additive + verify gate 拡張 + build flag 追加 + audition wav 生成)
- ζ-δ-2 audition wav (= `/tmp/zeta-delta-2-audition-revise.wav`) 生成完了 = user 再 audition session ready
- ADR-0048 Draft 維持 = ζ-ε 進まず literal 維持
- user 再 audition judgment 受領後の path:
  - **approve** → ADR-0048 ζ-ε 移行 (= user GO 必須、 main agent autonomous で Accepted 化しない)
  - **reject** → ζ-δ-3 audition fixture revise round 2 起票
  - **partial approve** → 部分改修 + 再 audition or ζ-ε 移行 (= user 判断)
