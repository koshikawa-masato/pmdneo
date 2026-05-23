# ADR-0058: PMDNEO 軸 B v2 driver production-ready roadmap ② = song parse + per-part dispatch loop + IRQ 連携

- 状態: **Accepted** (= 2026-05-23 39th session 軸 B production-ready roadmap ② 設計+実装 完了、 ground truth = ADR-0056 roadmap ② / ADR-0057、 α 起票 + β v2 PartWork compact layout + γ v2 song parse+dispatch wiring + δ v2 IRQ tick 連携+tempo accumulator + ε verify script 体系化 + ζ Draft→Accepted 移行 = 全 6 sub-sprint α/β/γ/δ/ε/ζ 完走。 ADR-0058 Accepted = roadmap ②「実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携」 完了 (= design + 実装 + verify 完走)。 **production-ready 全体達成ではない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition 未実施 + roadmap ③ ADPCM-B/rhythm + roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ②〜④ 完走後の future)。 「軸 B 完成」 表現不使用 (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過))
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0056** (= production-ready 化 選定 ADR、 Accepted、 §決定 4 roadmap ② = song parse + v2 per-part dispatch loop + IRQ tick 連携。 本 ADR-0058 が roadmap ② の実装 ADR)
  - **ADR-0057** (= roadmap ① FM/SSG 実音、 Accepted。 v2 FM/SSG dispatcher = `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch` を実音化。 **本 ADR-0058 はこの v2 dispatcher を song parse の出力で駆動する** = 固定 note table `pmdneo_v2_fm_notes` 等を song-driven note へ置換)
  - **ADR-0053** (= 軸 B 実装 sprint 2 SRAM placement、 Accepted。 §決定 2 で v2 PartWork 拡張 region 0xFD79-0xFE78 (256 byte) を確保。 **本 ADR-0058 §決定 3 がこの region に v2 専用 compact PartWork slot を配置**)
  - **ADR-0052 / ADR-0054 / ADR-0055** (= v2 entry / F-2-B / 軸 C/G/rhythm 接続点、 Accepted、 **本 ADR で不可触保護**)
  - **ADR-0049 / ADR-0050 / ADR-0051** (= mute / fade-out / SSG tone-enable、 Accepted、 **本 ADR で不可触保護**。 ADR-0050 = `irq_handler_body` への `pmdneo_v2_fade_tick` 1 行 additive 追加の前例)
  - **ADR-0045** (= 軸 B Phase 2 設計 ADR、 Accepted)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 長時間 verify は polling monitor 併走 + hang 判定)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow)
  - `feedback_parallelize_with_subagents_for_throughput.md` (= 本 ADR の現状 ground truth 調査は並列 sub-agent 3 体で実施)

## 背景 (= why now)

### production-ready 化 roadmap ② = song parse + loop + IRQ

ADR-0057 (= roadmap ① FM/SSG 実音) Accepted で、 v2 FM/SSG dispatcher (`pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch`) が固定 note (= C4/E4/G4) で実音 register write する段階に到達した。 ただし v2 path は依然 one-shot (= `pmdneo_v2_entry_skeleton` が dispatcher を 1 回 call → ret、 song data parse なし / 周期再生なし / IRQ 未連携)。

ADR-0056 §決定 4 の production-ready 化 roadmap = ① FM/SSG 実音 → **② song parse + v2 per-part dispatch loop + IRQ tick 連携** → ③ ADPCM-B/rhythm 実 dispatch → ④ 軸 G。 本 ADR-0058 = roadmap ② = v2 driver を「実 MML 曲を時間進行で鳴らす」 driver へ昇格する。

### 核心 = song parse の出力を v2 dispatcher へ feed する

並列 sub-agent 3 体調査 (= Annex A) で次が判明した = 既存 MML parser `pmdneo_song_main` を v2 が単純流用すると、 song の per-part dispatch は既存 hook (`fm_keyon_hook` 等 = 旧 dispatch) を通り、 **roadmap ① で実音化した v2 dispatcher が bypass される**。 = roadmap ② は「song parse の結果を v2 dispatcher へ feed する」 wiring が必須。

CLAUDE.md §設計書ファースト に従い、 本 ADR-0058 を doc-only filing として起票する。

## 決定

### 決定 1: 軸 B roadmap ② sub-sprint 構成 = 6 段 α/β/γ/δ/ε/ζ

roadmap ② 実装を **6 段階 α/β/γ/δ/ε/ζ** に分割する (= Codex layer 2 起票 plan review 判定)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0058 起票 (= doc-only) + roadmap ② scope / parse 方式 / v2 PartWork / IRQ 連携 / verify gate / 規律 literal 化 | 本 ADR-0058 起票 + dashboard sync、 doc-only | なし |
| **β** | v2 PartWork compact layout 確定 + driver field 追加 (= v2 PartWork region 0xFD79-0xFE78 に v2 専用 compact slot を配置) | v2 PartWork slot layout の `.equ` 定数 + production build PASS + baseline regression PASS | 最小限 (= SRAM layout + `.equ`) |
| **γ** | v2 song parse + per-part dispatch wiring (= 既存 MML byte 解釈基盤を用い、 v2 per-part dispatch を v2 dispatcher へ向ける) | v2 path が song data を per-part に parse + v2 dispatcher を song-driven note で駆動 + trace proof | driver (= v2 parse + dispatch wiring) |
| **δ** | IRQ tick 連携 + tempo (= `irq_handler_body` から v2 song dispatch を call する v2 hook 1 行 additive + tempo accumulator) | v2 song dispatch が IRQ tick 駆動 + tempo 分周 + 周期再生 trace proof | driver (= IRQ hook 1 行 + tempo) |
| **ε** | verify script 体系化 (= 想定 `verify-axis-b-v2-song-playback.sh`) | verify gate 全 PASS + verify script | verify script のみ |
| **ζ** | completion + ADR-0058 Draft → Accepted 判断 | 全 sub α〜ε verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由) | なし (= doc-only completion) |

各 sub-sprint = 1 PR。 計 = α/β/γ/δ/ε/ζ 各 1 PR = **6 PR**。 全 PR で軸 C/G/rhythm / ADR-0049〜0057 完全不可触。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
- 長時間 verify / MAME / regression は background 実行 + polling monitor 併走 + hang 判定 + kill/retry (= memory `feedback_long_running_verify_polling_hang_detection.md`)
- 既存 MML parser `pmdneo_song_main` / `pmdneo_part_main` 系の **本体は改変せず参照のみ** (= 案 (b)、 §決定 2)
- 既存 cmd 0x05 経路 / `irq_handler_body` body (= δ の v2 hook 1 行 additive 追加除く) / ADR-0049〜0057 / 軸 C/G/rhythm 完全不可触
- 「軸 B 完成」 表現禁止 (= ADR-0058 = roadmap ② の実装、 production-ready 達成宣言ではない)
- α は β に先行する (= ADR-0058 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: v2 song parse 方式 = 案 (b) 既存 MML byte 解釈基盤 + v2 dispatch wiring (= Codex 判定)

v2 song parse の方式を **案 (b)** とする (= Codex layer 2 起票 plan review 判定)。

- **案 (b) 採用**: 既存 `pmdneo_part_main` 系の MML byte 解釈ロジック (= note/休符/command opcode の解釈、 tick counter) は信頼する (= compile.py の `.mn` song data 形式と契約済、 全 chip カバー)。 v2 は **per-part dispatch の出口を v2 dispatcher (`pmdneo_v2_fm_dispatch` 系) へ向ける wiring** + v2 PartWork で part 進行 state を持つ。
- **案 (a) 不採用** (= v2 完全専用 parser 新規) = MML byte 解釈の全再実装 = 実装量大 + bug risk 大。
- **案 (c) 不採用** (= 既存 `pmdneo_song_main` 単純流用) = song の per-part dispatch が既存 hook (旧 dispatch) を通り **roadmap ① の v2 dispatcher が bypass される** (= roadmap ① 無意味化、 不可)。
- 既存 `pmdneo_song_main` / `pmdneo_part_main` 系の **本体は改変しない** (= 案 (b) は MML byte 解釈ロジックの「基盤を用いる」 が、 既存 routine 本体は参照のみ。 v2 専用 parse/dispatch routine を並設し、 必要なら MML opcode 定数等を共有)。 詳細 (= 完全並設 か 部分共有か) は γ で確定。

### 決定 3: v2 PartWork compact layout (= ADR-0053 v2 PartWork region)

v2 の part 進行 state (= MML addr / tick counter / note / loop / octave / ch_idx 等) を、 ADR-0053 §決定 2 で確保した **v2 PartWork 拡張 region (0xFD79-0xFE78、 256 byte)** に配置する。 既存 `part_workarea` の 64 byte/part slot を流用すると 256 byte ÷ 64 = 4 part 分のみで FM 6ch + SSG 3ch = 9 part に不足するため、 **v2 専用 compact slot** (= 12 byte 程度 × ~20 part) を新設する。 slot field の詳細 layout (= 各 field の offset / byte 数) は β で確定する。 既存 `part_workarea` (0xF820-) は不可触。

### 決定 4: IRQ tick 連携 + tempo (= ADR-0050 前例 pattern)

v2 song dispatch を `irq_handler_body` から call する。

- `irq_handler_body` body に **v2 song dispatch routine を call する 1 行を additive 追加** (= ADR-0050 β の `pmdneo_v2_fade_tick` 追加と同 pattern)。 既存 `irq_handler_body` の他の処理は不可触。
- v2 song dispatch routine は IRQ から call されるため **内部で IX/IY を push/pop** する (= IRQ handler は IX/IY を push しない契約)。
- **build-mode 排他**: 既存 cmd 0x05 song dispatch は `.if TEST_MODE_CHORD==5` build 限定。 v2 song dispatch も `.if` flag (= ADR-0052 系の `TEST_MODE_V2_ENTRY_FIXTURE` 等) で build-mode 排他とし、 同一 build で cmd 0x05 song と v2 song が両方 IRQ 駆動して衝突しないようにする。
- **tempo**: v2 song dispatch も tempo accumulator (= subtick 加算 + overflow で 1 song step) を持つ。 v2 専用の tempo state を v2 driver_state region に置くか既存 `driver_tempo_d` を参照するかは δ で確定。
- **TIMER-B tick rate**: driver に「TIMER-B IRQ が 6 秒で 2 回しか発火しない」 旨の古い finding コメントがあるが、 ADR-0050 fade-out verify が `pmdneo_v2_fade_level` の 64-step 単調減少 (= 66 IRQ tick) を観測済のため IRQ tick は実用上発火している (= 古い finding は stale の可能性高)。 δ/ε で TIMER-B tick rate を register trace で実測し gate 化する。

### 決定 5: v2 dispatcher 固定 note → song-driven note 置換

roadmap ① の v2 dispatcher は固定 note table (`pmdneo_v2_fm_notes` / `pmdneo_v2_ssg_notes` = C4/E4/G4) を参照する。 roadmap ② で v2 dispatcher を **per-part 進行 state 由来の song-driven note** で駆動するよう wiring する (= γ)。 固定 note table は roadmap ② 完了後は song-driven path に置換される (= 固定 note は roadmap ① の中間段階)。

### 決定 6: verify gate (= register trace primary gate)

roadmap ② は **register trace primary gate** で verify する。 ε で次を verify script (= 想定 `verify-axis-b-v2-song-playback.sh`) に体系化する (= 最終件数は ε で確定)。

| # | gate | 期待 |
|---|---|---|
| 1 | v2 song parse proof | v2 path が song data を per-part に parse する (= MML byte fetch + 解釈) |
| 2 | v2 dispatch wiring proof | v2 per-part dispatch が v2 dispatcher (`pmdneo_v2_fm_dispatch` 系) を song-driven note で駆動する (= 既存 hook bypass ではない) |
| 3 | IRQ tick 駆動 proof | v2 song dispatch が IRQ tick 駆動で周期再生する (= one-shot ではない、 複数 tick で song 進行) |
| 4 | tempo proof | tempo accumulator が song step を時間進行させる |
| 5 | baseline regression | ADR-0049〜0057 verify 全 PASS + 既存 cmd 0x05 経路 byte-identical |
| 6 | `.org` overflow / build-mode 排他 | v2 並設 routine `.org` overflow なし + build-mode 排他成立 |

audition は production-ready gate (= ADR-0056 §決定 3) の最終段。 roadmap ② の完了判定は register trace primary。

### 決定 7: scope-in / scope-out

#### scope-in (= roadmap ② で扱う)

- v2 専用 compact PartWork layout (= part 進行 state)
- v2 song parse + per-part dispatch loop (= 既存 MML byte 解釈基盤 + v2 dispatch wiring、 案 b)
- IRQ tick 連携 + tempo (= 周期再生)
- v2 dispatcher の固定 note → song-driven note 置換
- verify script 体系化

#### scope-out (= 後続 roadmap)

- **ADPCM-B / rhythm 実 dispatch** (= `pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` の marker stub → 実 call) = roadmap ③
- **軸 G dynamic supply 依存整理** = roadmap ④
- **F-2-B 実音 individual mode** = ADR-0054 §決定 6 後続 future (= roadmap ② では fm3ext stub 不可触)
- **production-ready 判定 + cmd 切替** = roadmap ②〜④ 完了後 (= ADR-0056 §決定 3)

### 決定 8: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする。

- 既存 MML parser `pmdneo_song_main` / `pmdneo_part_main` / `pmdneo_part_main_parse` / `commandsp` 系 の **本体** (= 案 b は参照のみ、 改変なし)
- 既存 `part_workarea` (0xF820-) / 既存 cmd 0x02 fixture path / cmd 0x05 + `pmdneo_song_main` MML parser 経路
- `irq_handler_body` body (= δ の v2 song dispatch call 1 行 additive 追加を除く) / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐
- ADR-0049〜0057 で追加した routine + SRAM field (= v2 driver foundation + roadmap ①)
- 軸 C ADR-0043 / 軸 G ADR-0048 (= Draft + ε partial state) / rhythm ADR-0026〜0031 / vendor

### 決定 9: doc-only filing 規律 (= α) + Codex rescue 化 + non-stop model 継承

α sub-sprint (= 本 ADR-0058 起票) は **doc-only** = 変更 file = 本 ADR-0058 + `docs/parallel-axes-dashboard.md` のみ。 driver / verify script / vendor 完全不変。 vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain。

本 roadmap ② 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model + 後半 再拡張 (= 判断要件も Codex layer 2 自律判断、 mid-flight escalate で止まらず non-stop、 user は完走後確認) を継承する。 Codex layer 2 review 依頼時は commit 権限なしを literal 明示する。

## Annex A: roadmap ② ground truth (= 並列 sub-agent 3 体調査)

### A-1: 既存 MML parser (= `src/driver/standalone_test.s`)

`pmdneo_song_main` (L2509) = per-tick で全 20 part loop → part 毎 `pmdneo_part_main` (L2609) call。 `pmdneo_part_main` = MML byte parser (= `PART_OFF_LEN` tick counter、 `pmdneo_part_fetch_byte` で MML byte fetch、 note/休符/command 分岐)。 part 進行 state は `part_workarea` (0xF820、 64 byte/part、 20 part)。 chip 別 hook (`fm_keyon_hook` 等) を `pmdneo5_init_part` が bind。 song data = compile.py 生成 `.mn` binary を `song_data.inc` で incbin。 IRQ から `pmdneo_song_main` call は `.if TEST_MODE_CHORD==5` build 限定。

### A-2: IRQ 機構

`irq_handler_body` (L542、 `.org 0x0100`) = TIMER-B ~1ms tick。 `pmdneo_v2_fade_tick` を IRQ から call する前例あり (= ADR-0050 β で IRQ handler に 1 行追加)。 IRQ handler は IX/IY を push しない (= 呼ぶ routine 側で push/pop 契約)。 tempo = `driver_subtick_acc` + `driver_tempo_d` overflow で dispatch。 TIMER-B 古い finding (= 6 秒で 2 回) は ADR-0050 fade verify の 66 IRQ tick 観測で stale の可能性高。

### A-3: v2 path 現状 + v2 PartWork region

v2 path = `nmi_cmd_7_play_song_v2` → `pmdneo_v2_entry_skeleton` = one-shot (= 5 dispatcher 1 回 call → ret、 IRQ 未連携)。 roadmap ① で `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch` 実音化済、 fm3ext/adpcmb/rhythm は stub。 v2 PartWork 拡張 region = ADR-0053 §決定 2 = 0xFD79-0xFE78 (256 byte、 全 free)。 64 byte/part slot 流用では 4 part 分のみ = 不足 → v2 専用 compact slot 必要。

## Annex B: roadmap ② v2 song playback 構成図

```
roadmap ② 完了後の v2 song playback 経路:
  IRQ tick (TIMER-B)
    → irq_handler_body (= v2 song dispatch call 1 行 additive、 δ)
      → v2 song dispatch (= tempo accumulator、 δ)
        → v2 per-part dispatch loop (= 全 v2 part 巡回、 γ)
          → v2 MML byte parse (= 既存 MML byte 解釈基盤、 案 b、 γ)
            → v2 part 進行 state 更新 (= v2 PartWork compact slot、 β)
            → v2 dispatcher 駆動 (= pmdneo_v2_fm_dispatch 系を song-driven note で、 γ/決定 5)
              → 実音 register write (= roadmap ① の v2 FM/SSG 実音)
```

build-mode 排他 = 既存 cmd 0x05 song (`TEST_MODE_CHORD==5`) と v2 song を `.if` flag で排他 build。

## Annex C: β 実装 completion record (= v2 PartWork compact layout)

### C-1: β deliverable

軸 B production-ready roadmap ② β = v2 PartWork compact slot layout 確定 (= 39th session、 PR #97)。

| deliverable | 内容 |
|---|---|
| `standalone_test.s` の v2 PartWork compact slot `.equ` layout | `PMDNEO_V2_PARTWORK_SLOT_SIZE` (= 12) + `PMDNEO_V2_PART_COUNT` (= 9 = FM 6ch + SSG 3ch) + slot field offset 8 件 (`PMDNEO_V2_PART_OFF_ADDR`/`LEN`/`NOTE`/`CH_IDX`/`KIND`/`OCTAVE`/`LOOP`/`FLAGS`)。 ADR-0053 §決定 2 の v2 PartWork region 0xFD79-0xFE78 に v2 専用 compact slot を配置 (= slot N = `pmdneo_v2_partwork_base` + N × 12) |
| SRAM layout comment | v2 PartWork region 行を compact slot layout 付きへ更新 |

### C-2: 実装詳細

- v2 専用 12 byte compact slot = 既存 `part_workarea` の 64 byte/part slot を流用しない (= 256 byte で 4 part 分のみ = FM 6ch+SSG 3ch に不足)。 12 byte × 9 part = 108 byte ≤ 256 byte region。 roadmap ③ で ADPCM-B/rhythm part 追加時は `PMDNEO_V2_PART_COUNT` 拡張 (= 256/12 = 21 part まで収容可)
- slot field = ADDR (2 byte MML pointer) / LEN (1 byte tick counter) / NOTE (1 byte) / CH_IDX (1 byte) / KIND (1 byte FM/SSG) / OCTAVE (1 byte) / LOOP (2 byte loop pointer) / FLAGS (1 byte)、 offset 10-11 reserved
- β は `.equ` 定数のみ (= active code なし)。 γ が本 slot を read/write、 δ が IRQ 駆動で per-part loop

### C-3: β 検証結果

- production build PASS
- **m1 binary byte-identical** (= sha256 一致確認、 β は unused symbol の `.equ` のみ = sdasz80 は byte 非出力 = Z80 driver binary 不変、 ADR-0053 β と同 pattern)
- binary 不変のため ADR-0049〜0057 baseline regression は trivially 維持 (= 同一 binary)
- Codex layer 2 = β 実装 review approve

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) を「固定の和音を 1 回鳴らすだけ」 から「実際の MML 曲を時間進行で鳴らす」 ドライバへ引き上げる。 曲データを読んで、 各パートを時間で進め、 IRQ (= 一定間隔の割り込み) で周期再生する。

**前提**: roadmap ① (= ADR-0057) で v2 の FM/SSG 音源処理は実音を出せるようになった。 ただし v2 はまだ「曲データを読まない・時間進行しない・割り込み連携なし」 の one-shot。 本 ADR-0058 = roadmap ② = この 3 つを実装する。

**進捗 (= α/β/γ/δ 完了)**: α で設計書 (= 本 ADR-0058) を起票し、 曲解釈の方式・パート状態の置き場所・IRQ 連携の方法・検証方法を文書で固定した。 β でドライバ (= `standalone_test.s`) に v2 専用のパート状態置き場 (= v2 PartWork compact slot = 12 byte/part × 9) のレイアウト定数を追加した。 γ で v2 専用の曲解釈ルーチンを `.if TEST_MODE_V2_SONG_FIXTURE` 配下に並設 (= 案 b' + 案 E'-b)、 v2 PartWork compact slot 経由で song-driven note を v2 FM/SSG dispatcher へ feed する配線を実装した。 δ で **IRQ tick 連携 + tempo accumulator** を実装 = `irq_handler_body` から `pmdneo_v2_song_tick` を `.if` 配下で 1 行 additive call (= ADR-0050 β `pmdneo_v2_fade_tick` 前例 pattern)、 v2 専用 tempo state (= `pmdneo_v2_song_state` 0xFD3E / `_tempo_acc` 0xFD3F / `_tempo_d` 0xFD40) を v2 driver_state region に配置、 cold init で `pmdneo_v2_song_state=0` clear (= I-12 mitigation = cold boot false active 防止)、 `pmdneo_v2_song_entry` 責務変更 (= dispatch 直接 call 撤去 → init + tempo init + active flag set、 dispatch は IRQ 駆動へ委ね)、 `pmdneo_v2_song_tick` は IX/IY 退避 + state check + tempo overflow gate + 単一 epilogue で全 exit pop pair 順序保証。 既存 `pmdneo_v2_entry_skeleton` + roadmap ① v2 dispatcher + cmd 0x05 経路 + `part_workarea` + `irq_handler_body` 既存処理 + `driver_subtick_acc/_tempo_d` 完全不可触。 `TEST_MODE_V2_SONG_FIXTURE=0` で **production byte-identical** (= δ-7 literal proof = 新 15 routine 全 assemble なし + IRQ call 未 assemble + cold init clear 未 assemble)。 δ verify gate 10 件 (= δ-1 IRQ tick 駆動 / δ-2 tempo / δ-3 周期再生 / δ-4 IX/IY 保存 / δ-5 TIMER-B IRQ rate 実測 / δ-6 baseline regression / δ-7 production byte-identical / δ-8 γ pattern 移行 / δ-9 .org overflow / δ-10 cold boot inactive + cmd 0x05/0x07 callsite 静的確認) を `verify-axis-b-v2-song-parse.sh` (= γ 6 gate から 10 gate へ完全 rewrite) に体系化し ALL PASS。 δ-5 で TIMER-B IRQ rate = 2461 件 / 5 秒 = **~492 IRQ/秒** literal 実測 (= 古い「6 秒で 2 回」 finding 完全 stale 確定)、 δ-2 で IRQ 2461 件 > slot 0 LEN write 1219 件 = overflow gate 動作 proof (= tempo_d=0x80 で半数 IRQ で dispatch)、 δ-3 で slot 0 ADDR uniq 9 値 = 複数 byte 進行 proof。

**核心**: 既存ドライバの MML 曲解釈ロジックは信頼して基盤に使うが (= 案 b)、 各パートの「音を鳴らす出口」 は roadmap ① で作った v2 dispatcher へ向ける。 δ で IRQ tick + tempo accumulator により one-shot から周期再生へ昇格 (= roadmap ② の中核機能達成)。

**ε 完了**: `verify-axis-b-v2-song-parse.sh` を `verify-axis-b-v2-song-playback.sh` に rename、 §決定 6 primary 6 gate + supplemental 4 gate = 計 10 gate に統合 + 末尾 completion proof line 11 行 (= §決定 6 全 PASS + ζ Accepted 移行 ready signal) 追加。 driver touch なし。 Annex D (γ) / Annex E (δ) 本文不変。 verify ALL PASS + completion proof line literal 出力確認。

**ζ 完了 (= Draft → Accepted 移行)**: ADR-0058 を Draft → Accepted へ移行。 Accepted = 「roadmap ②「実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携」 完了」 (= design + 実装 + verify 完走、 = 6 sub-sprint α/β/γ/δ/ε/ζ 全完走 + ε で `verify-axis-b-v2-song-playback.sh` 10 gate + completion proof line ALL PASS literal 出力)。 doc-only filing (= 主軸直接 edit、 Annex A〜F 本文不変)。 **重要 = production-ready 全体達成と書かない**: ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ② で未実施、 roadmap ③ ADPCM-B/rhythm + roadmap ④ 軸 G 未着手、 = production-ready 全体達成は roadmap ②〜④ 完走後の future。 「軸 B 完成」 表現禁止 継続。

**次**: ADR-0058 Accepted 後の候補 = roadmap ③ ADPCM-B/rhythm 実 dispatch 着手 / roadmap ④ 軸 G dynamic supply 着手 / production-ready gate 4 系統判定 (= 越川氏 audition 含む) は roadmap ②〜④ 完走後の future。 別軸 (= 軸 G ζ defer 等) 着手判断は user。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0058 起票) | **完了** (= 39th session、 PR #96) | PR #96 | 起票 plan review approve (= 案 b + 6 段 + 全 4 論点 + 規律 approve、 escalate なし) + 起票 review approve |
| β (= v2 PartWork compact layout) | **完了** (= 39th session、 PR #97) | PR #97 | β 実装 review approve |
| γ (= v2 song parse + dispatch wiring) | **完了** (= 39th session、 PR #98) | PR #98 | γ kickoff plan review revise (= 案 b' + 案 E'-b 推奨 + γ-2/γ-3/γ-6 修正 + I-6〜I-9 追加 反映) + γ 実装 review 4 round (= round 1 = 不可触/規律/verify gate revise → 案 b' + E'-b + γ-2 literal value gate + dashboard 予約簿 sync + γ-2 noref fallback risk → ref inline 必須生成 + ref failure 二重カウント除去) → round 4 approve |
| δ (= IRQ 連携 + tempo) | **完了** (= 39th session、 PR #99) | PR #99 | δ kickoff plan review 4 round (= round 1 revise SRAM 0xFD3D 衝突 + tick 全 exit single epilogue + entry song_init 必須維持 + verify F-a + risk I-10〜I-13 + sub-agent prompt isolation worktree 限定 → round 2 revise cold init 全経路 → round 3 revise δ-10 cmd 0x05 callsite 整合 → round 4 approve) + δ 実装 review 2 round (= round 1 revise δ-3 init-only false PASS → strengthen ADDR lo uniq + LEN uniq → round 2 approve) |
| ε (= verify script 体系化) | **完了** (= 39th session、 PR #100) | PR #100 | ε kickoff plan review 2 round (= round 1 revise D' completion proof line literal 改訂 + Annex D/E 履歴不変 + Annex F rename 注記 → round 2 approve) + ε 実装 review 2 round (= round 1 revise stale trace false PASS risk → 3 MAME invocation 全前 `rm -rf $TRACE_DIR` 追加 → round 2 approve) |
| ζ (= completion + Draft → Accepted 判断) | **完了** (= 39th session、 PR #101) | PR #101 | ζ kickoff plan review 1 round approve (= doc-only scope + Annex G 構造 + 表記制約 literal + 主軸直接 edit 妥当性 全 ok) + ζ doc review 1 round approve (= 実装 vs plan + 不可触対象 + 規律 + user 明示制約 3 件 literal 反映 + doc 整合 + latent risk 全 ok) |

## Annex D: γ 実装 completion record (= v2 song parse + per-part dispatch wiring)

### D-1: γ deliverable

軸 B production-ready roadmap ② γ = v2 song parse + per-part dispatch wiring 並設 (= 39th session、 PR #98)。

| deliverable | 内容 |
|---|---|
| `standalone_test.s` 新 routine 群 14 件 (= `.if TEST_MODE_V2_SONG_FIXTURE` 配下) | `pmdneo_v2_song_init` (= v2 PartWork slot 0/1 初期化、 slot 0 = FM ch B / slot 1 = SSG ch G、 slot 2-8 = FLAGS clear) + `pmdneo_v2_song_dispatch` (= 9 slot loop、 FLAGS bit0=1 のみ tick) + `pmdneo_v2_part_tick` (= LEN dec or parse) + `pmdneo_v2_part_parse` (= MML byte 解釈、 <0x80 note / 0x80 loop / 0x90 rest / >=0x91 slot deactivate) + `pmdneo_v2_part_note` (= NOTE 保存 + length fetch + LEN set + dispatch) + `pmdneo_v2_part_rest` (= length fetch + LEN set) + `pmdneo_v2_part_loop` (= LOOP pointer ADDR set or FLAGS clear、 LOOP=base 規律 = I-9 mitigation) + `pmdneo_v2_part_fetch_byte` (= slot ADDR から 1 byte fetch + ADDR++) + `pmdneo_v2_part_dispatch_note` (= KIND 分岐 = FM ならば `_fm_voice_note_song` / SSG ならば `_ssg_voice_note_song` jp) + `pmdneo_v2_fm_voice_note_song` / `pmdneo_v2_ssg_voice_note_song` (= 案 b' 並設、 A=note / B=ch_idx で実音 register write、 既存 `pmdneo_v2_fm_voice_note` / `_ssg_voice_note` 完全不可触) + `pmdneo_v2_song_entry` (= 案 E'-b 独立 entry、 init + dispatch 1 回) + fixture 2 件 `pmdneo_v2_song_fixture_fm_b` / `_ssg_g` (= MML byte 列 `0x42, 0x10, 0x45, 0x10, 0x48, 0x10, 0x80` = roadmap ① 固定 table 0x40/0x44/0x47 と異なる song-driven proof 用 note) |
| `nmi_cmd_7_play_song_v2` cmd 0x07 path 変更 (= 案 E'-b) | `.if TEST_MODE_V2_SONG_FIXTURE / call pmdneo_v2_song_entry / .else / call pmdneo_v2_entry_skeleton / .endif` で build-mode 排他 entry 切替。 `=0` build では `.else` block のみ assemble = β 直後 byte と等価 (= γ-6 で literal 確認) |
| `nmi_cmd_5_init_mml_song` 末尾 fixture call (= γ verify trace 起動経路) | `.if TEST_MODE_V2_SONG_FIXTURE / call pmdneo_v2_song_entry / .endif` を既存 `TEST_MODE_V2_ENTRY_FIXTURE` / `TEST_MODE_FADE_FIXTURE` block の隣に additive 追加。 production build 完全不変 |
| `TEST_MODE_V2_SONG_FIXTURE` build flag 経路 | `.equ TEST_MODE_V2_SONG_FIXTURE, 0` (= driver) + `scripts/build-poc.sh` make 行に `PMDNEO_V2_SONG_FIXTURE` 環境変数 pass 追加 + `vendor/ngdevkit-examples/00-template/build.mk` に `?=0` + sed expression block 追加 |
| 新 verify script `src/test-fixtures/axis-b/verify-axis-b-v2-song-parse.sh` (= 186 行) | γ verify gate 6 件 (= γ-1〜γ-6) 体系化、 既存 `verify-axis-b-fm-ssg-real-sound.sh` pattern 踏襲、 ALL PASS |

### D-2: 実装詳細

- **dispatcher refactor 案 b' 採用** (= Codex layer 2 kickoff plan review revise)。 既存 `pmdneo_v2_fm_voice_note` / `pmdneo_v2_ssg_voice_note` (= roadmap ① 由来) signature 完全不変。 新並設 routine `_fm_voice_note_song` / `_ssg_voice_note_song` が A=song-driven note / B=ch_idx 受け取りで voice/fnum/keyon を emit。 roadmap ① path 完全 byte-identical。 ADR-0058 §決定 8 「ADR-0049〜0057 で追加 routine 不可触」 遵守。
- **cmd 0x07 wiring 案 E'-b 採用** (= Codex layer 2 kickoff plan review revise)。 既存 `pmdneo_v2_entry_skeleton` 完全不変、 `nmi_cmd_7_play_song_v2` routine 内で `.if/.else/.endif` build-mode 排他。 `=0` build では `.else` block の `call pmdneo_v2_entry_skeleton` (= β 直後と等価 byte) のみ assemble。 ADR-0058 §決定 4 build-mode 排他 + §決定 8 entry skeleton 不可触 遵守。
- **fixture note 0x42/0x45/0x48 採用** (= Codex layer 2 review revise = γ-2 proof 強化)。 roadmap ① 固定 table 0x40/0x44/0x47 と全 byte 異なる song-driven note を fixture に置き、 γ-2 dispatch wiring proof で trace 観測時に区別可能化。
- **LOOP=fixture base 初期値 init で literal 設定** (= Codex layer 2 review revise = I-9 mitigation)。 `pmdneo_v2_song_init` で slot 0/1 の LOOP field = fixture base address を literal 書込み。 fixture 末尾 `0x80` loop event 到達時 ADDR を fixture base へ巻戻し可能。
- **全 γ routine + fixture を `.if TEST_MODE_V2_SONG_FIXTURE` 配下に閉じる** (= Codex layer 2 review revise = I-6 mitigation = γ-6 production byte-identical 担保)。 `=0` build で 14 routine 全 assemble されず、 .lst に label 行が現れない (= γ-6 で literal assert)。
- IY-relative addressing で slot field アクセス (= `PMDNEO_V2_PART_OFF_*(iy)`)。 既存 PMD style と同形式。

### D-3: γ 検証結果

- production build (= `TEST_MODE_V2_SONG_FIXTURE=0`): **PASS** + **m1 ROM byte-identical** (= sub-agent worktree 内 `cmp` で base ref e009bfd と literal 一致確認 = γ-6 最強 proof)
- γ fixture build (= `PMDNEO_V2_SONG_FIXTURE=1` + `--chip ym2610`): **PASS** + 新 14 routine 全 assemble + addr 0x0A3B〜0x0B58
- `verify-axis-b-v2-song-parse.sh` 6 gate **ALL PASS**:
  - γ-1 (= song parse proof): slot 0 ADDR (= 0xFD79/0xFD7A) write 6 件 + slot 1 ADDR (= 0xFD85/0xFD86) write 6 件
  - γ-2 (= dispatch wiring proof): song-driven FM ch B keyon (reg 0x28 ← 0xF1) 9 件 + SSG ch G volume (reg 0x08 ← 0x0F) 1 件 (= roadmap ① 固定 table と異なる song fixture 由来 dispatch)
  - γ-3 (= LEN set proof): slot 0 LEN (= 0xFD7B) nonzero 1 件 + slot 1 LEN (= 0xFD87) nonzero 1 件 (= dispatch 経路通過)
  - γ-4 (= baseline regression): `verify-axis-b-fm-ssg-real-sound.sh` 6 gate 全 PASS (= ADR-0049〜0057 transitively regression)
  - γ-5 (= .org overflow なし): 新 14 routine 全 >= 0x0610 + 0x0066 セクション max addr 0x0000F9 < 0x0100
  - γ-6 (= production byte-identical): 新 14 routine 全 assemble なし + `nmi_cmd_7_play_song_v2` body byte = CD (call) + C3 (jp) (= `.else` block のみ assemble = β 直後と等価)
- Codex layer 2 = γ kickoff plan review revise (= 案 b' + E'-b 推奨 + γ-2/γ-3/γ-6 修正 + I-6〜I-9 追加 反映) + γ 実装 review approve (= 後続 commit 後)

## Annex E: δ 実装 completion record (= v2 IRQ tick 連携 + tempo accumulator)

### E-1: δ deliverable

軸 B production-ready roadmap ② δ = v2 IRQ tick 連携 + tempo accumulator (= 39th session、 PR #99)。

| deliverable | 内容 |
|---|---|
| `standalone_test.s` 新 SRAM `.equ` 3 件 (= v2 driver_state region 0xFD3E-0xFD40) | `pmdneo_v2_song_state` 1 byte @ 0xFD3E (= active flag、 bit0) + `pmdneo_v2_tempo_acc` 1 byte @ 0xFD3F (= v2 専用 tempo subtick accumulator) + `pmdneo_v2_tempo_d` 1 byte @ 0xFD40 (= v2 専用 tempo delta = subtick add per IRQ)。 既存 `driver_subtick_acc/_tempo_d` (= cmd 0x05 path 専用) と衝突回避。 既配置 `pmdneo_v2_rhythm_marker` (= 0xFD3D = ADR-0055) と非衝突 (= round 1 revise I-10 fix)。 SRAM layout comment 3 行追加 + free byte range 表記更新 (= 0xFD41-0xFD78 = 56 byte) |
| `standalone_test.s` cold init で `pmdneo_v2_song_state=0` clear (= D'' = I-12 mitigation) | `nmi_clear_driver_state` loop 後 + `.if TEST_MODE_V2_SONG_FIXTURE / xor a / ld (pmdneo_v2_song_state),a / .endif` を additive 追加。 cold boot 全経路 (= NMI cold init `driver_state_init_flag` ガード経由 idempotent) で `pmdneo_v2_song_state=0` を担保 (= IRQ tick が cmd 0x07 entry 前に random で false active 踏まない)。 `.if` 配下で production byte-identical 維持 |
| `standalone_test.s` IRQ body 1 行 additive (= E) | `irq_handler_body` 内 `call pmdneo_v2_fade_tick` の **直後** に `.if TEST_MODE_V2_SONG_FIXTURE / call pmdneo_v2_song_tick / .endif` を additive 追加。 ADR-0050 β `pmdneo_v2_fade_tick` 前例 pattern と同位置形式。 `=0` build skip = byte-identical 担保 |
| `standalone_test.s` 新 routine `pmdneo_v2_song_tick` (= C' = 全 exit 単一 epilogue + IX/IY pop pair 順序) | IRQ tick から call、 IX/IY 退避 → state inactive 即 ret (epilogue 経由) → tempo accumulator add + overflow なし skip ret (epilogue 経由) → overflow ならば `pmdneo_v2_song_dispatch` call → epilogue (pop iy / pop ix / ret)。 全 exit path が `pmdneo_v2_song_tick_done` 単一 epilogue を通過 (= δ-4 静的 proof) |
| `standalone_test.s` `pmdneo_v2_song_entry` 責務変更 (= D' literal) | γ 既存 `pmdneo_v2_song_entry` = `call pmdneo_v2_song_init` + `call pmdneo_v2_song_dispatch` + ret を以下に変更: `call pmdneo_v2_song_init` 必須維持 (= I-11 mitigation) + `xor a / ld (pmdneo_v2_tempo_acc), a` (= tempo acc 0 reset) + `ld a, #0x80 / ld (pmdneo_v2_tempo_d), a` (= tempo delta 0x80) + `ld a, #1 / ld (pmdneo_v2_song_state), a` (= active flag 最後 set)。 dispatch 直接 call 撤去 = dispatch は IRQ 駆動委ね |
| `verify-axis-b-v2-song-parse.sh` δ 10 gate 完全 rewrite (= 案 F-a) | γ 6 gate (= γ-1〜γ-6) を δ 10 gate (= δ-1〜δ-10) に完全 rewrite。 +234/-124 行。 ref trace inline 生成必須 (= γ 同 pattern)、 `set -euo pipefail` + `FAIL=0 ok/ng` 構造維持 |

### E-2: 実装詳細

- **SRAM 衝突回避** (= round 1 revise I-10 = `0xFD3D` rhythm_marker 既配置): plan 初稿 `pmdneo_v2_song_state @ 0xFD3D` を `0xFD3E` へ移動。 既配置 4 byte (= 0xFD39 fade_level / 0xFD3A ssg_mixer / 0xFD3B entry_marker / 0xFD3C adpcmb_marker / 0xFD3D rhythm_marker) と非衝突。
- **tick 単一 epilogue 設計** (= round 1 revise = 判定 3): plan 初稿の「state check 前 push、 各 exit path 直接 ret」 構造を、 全 exit が `pmdneo_v2_song_tick_done` ラベルを必ず通過する単一 epilogue 設計に変更。 IX/IY pop pair 順序保証 (= push ix → push iy → ... → pop iy → pop ix → ret)。
- **entry song_init 必須維持** (= round 1 revise I-11 = 判定 4): plan 初稿で曖昧だった「dispatch 撤去」 表現を「`call pmdneo_v2_song_init` は最初の命令として literal 必須維持 + dispatch だけ撤去」 へ明確化。 verify δ-8 で静的 .lst で `call pmdneo_v2_song_init` 残存 assert。
- **cold init 経路必須化** (= round 2 revise I-12 + 判定 5): `nmi_clear_driver_state` 既存 loop が `driver_song_ready` (= 0xF811) + 0x0F bytes (= 15 byte) clear のみで `0xFD3E` 対象外を発見、 `.if TEST_MODE_V2_SONG_FIXTURE / xor a / ld (pmdneo_v2_song_state),a / .endif` を loop 後に additive 追加。 cmd 0x05 / cmd 0x07 / direct entry 全 cold boot 経路で `driver_state_init_flag` ガード経由 idempotent 1 回 init で `pmdneo_v2_song_state=0` 担保。
- **δ-10 単一観点 collapse** (= round 3 revise): plan 初稿の 3 観点 (cmd 0x07 / cmd 0x05 0 維持 / direct cmd 0x07) を、 cmd 0x05 fixture build でも `nmi_cmd_5_init_mml_song` 末尾 `call pmdneo_v2_song_entry` (= γ 追加) 経由で active 1 set される source 矛盾を反映し、 「`TEST_MODE_V2_SONG_FIXTURE=1` build で cold init 0 → entry 1 sequence proof」 単一観点 + 「cmd 0x05/cmd 0x07 両 callsite 静的確認」 (= round 4 追記) に collapse。
- **sub-agent worktree prompt** (= round 1 revise 判定 8): `git reset --hard` は worktree root が `.claude/worktrees/` 配下確認後のみ許可 (= `case "$WORKTREE_ROOT" in ... esac`)。 `git fetch /Users/koshikawamasato/Projects/pmdneo` は fetch source only、 cwd/edit 禁止と例外範囲分離。

### E-3: δ 検証結果

- production build (= `TEST_MODE_V2_SONG_FIXTURE=0`): **PASS** + δ-7 = 新 15 routine 全 assemble なし + IRQ body call pmdneo_v2_song_tick 未 assemble + cold init song_state clear 未 assemble (= production byte-identical 完全担保)
- δ fixture build (= `PMDNEO_V2_SONG_FIXTURE=1`): **PASS** + 新 15 routine 全 assemble (= 0x0A3B〜0x0B7B、 0x0610 セクション余裕内)
- `verify-axis-b-v2-song-parse.sh` 10 gate **ALL PASS**:
  - δ-1 (= IRQ tick 駆動 proof): IRQ body call assembled + `pmdneo_v2_tempo_acc` write 2438 件 (>= 2 期待)
  - δ-2 (= tempo proof): IRQ tick 2461 件 > slot 0 LEN write 1219 件 = overflow gate 動作 proof (= 全 IRQ で dispatch しない、 tempo_d=0x80 で半数 IRQ で overflow = expected)
  - δ-3 (= 周期再生 proof): slot 0 ADDR (= 0xFD79/0xFD7A) write uniq value 9 件 (= 複数 byte 進行 proof、 γ 1 note → δ 周期再生に昇格)
  - δ-4 (= IX/IY 保存 proof): `push ix` + `push iy` (tick body) + `pop iy` + `pop ix` (tick_done) + 全 exit 単一 epilogue 経由 (= tick body 内 ret 直接出現なし)
  - δ-5 (= TIMER-B IRQ rate 実測): `pmdneo_irq_count` (= 0xF816) write 2461 件 / 5 秒 = **~492 IRQ/秒** literal 実測 (= ADR-0050 fade verify 66 tick literal 同等以上、 古い「6 秒で 2 回」 finding 完全 stale 確定)
  - δ-6 (= baseline regression): `verify-axis-b-fm-ssg-real-sound.sh` 6 gate ALL PASS = ADR-0049〜0057 transitively regression
  - δ-7 (= production byte-identical): 上記の通り
  - δ-8 (= γ pattern 移行): `pmdneo_v2_song_entry` body 内 `call pmdneo_v2_song_init` 存在 + `call pmdneo_v2_song_dispatch` **未存在** (= dispatch 直接 call 撤去) + `ld (pmdneo_v2_song_state),a` 存在 (= active flag set)
  - δ-9 (= .org overflow なし): 新 15 routine 全 >= 0x0610 + 0x0066 セクション max addr 0x0000FD < 0x0100
  - δ-10 (= cold boot inactive + cmd callsite): (a) `pmdneo_v2_song_state` write 2 件 + first value = 0x00 + has-1 = 1 (= cold init 0 → entry 1 sequence literal)、 (b) cmd 0x05 callsite + cmd 0x07 callsite ともに `call pmdneo_v2_song_entry` 静的存在
- Codex layer 2 = δ kickoff plan review 4 round chain (= 案 b'+E'-b γ pattern 同様の revise/approve loop) → 実装 commit 後 review (= 後続)

## Annex F: ε 実装 completion record (= verify script 体系化 + completion proof line + rename 注記)

### F-1: ε deliverable

軸 B production-ready roadmap ② ε = verify script 体系化 (= 39th session、 PR #100)。

| deliverable | 内容 |
|---|---|
| `verify-axis-b-v2-song-playback.sh` 新規 336 行 | §決定 6 primary 6 gate (= `roadmap2-gate-1` v2 song parse / `roadmap2-gate-2` v2 dispatch wiring / `roadmap2-gate-3` IRQ tick 駆動 / `roadmap2-gate-4` tempo / `roadmap2-gate-5` baseline regression / `roadmap2-gate-6` .org + build-mode 排他) + supplemental 4 gate (= `sup-IX/IY` δ-4 / `sup-TIMER-B` δ-5 / `sup-γ-pattern` δ-8 / `sup-cold-boot` δ-10) = **計 10 gate** に統合 + 末尾 completion proof line 11 行 (= §決定 6 全 PASS + supplemental 全 PASS + ζ Accepted 移行 ready signal、 ζ Annex F (= 本 Annex) へ literal 引用可能形式) |
| `verify-axis-b-v2-song-parse.sh` 削除 | γ/δ 期 verify script (= 旧 6/10 gate) を rename + 削除。 `git rm` で履歴削除 |

### F-2: 命名 + rename 注記 (= revise round 2 Annex D/E 履歴改変 risk 回避)

- ADR-0058 §決定 1 ε literal 推奨命名 `verify-axis-b-v2-song-playback.sh` への rename (= 旧 `verify-axis-b-v2-song-parse.sh` from γ/δ)
- **Annex D (= γ completion record) / Annex E (= δ completion record) 本文の verify script path 表記は γ/δ 当時の literal 記録として維持 (= 履歴改変 risk 回避、 Codex layer 2 ε kickoff plan review round 1 revise 反映)**
- ε 以降は本 Annex F の rename 注記 + 新 path (`verify-axis-b-v2-song-playback.sh`) を ground truth とする
- dashboard は現 state ground truth role = 新 path に更新

### F-3: ε 実装詳細

- **rename 案 (B-a) 採用** (= Codex layer 2 kickoff plan review approve): 旧 file 削除 + 新 file 作成で冗長性回避。 影響範囲調査 = `rg "verify-axis-b-v2-song-parse|verify-axis-b-v2-song-playback"` で他 verify script invoke なし confirmed (= round 1 + sub-agent 内 literal 再確認)。
- **gate 整理**: §決定 6 想定 6 gate 命名 `roadmap2-gate-1〜6` で literal 統一 + δ 10 gate のうち §決定 6 6 gate に含まれない 4 件 (= IX/IY epilogue / TIMER-B IRQ rate / γ pattern 移行 / cold boot inactive) を `sup-*` prefix supplemental gate として末尾配置 = 退行検出力保持。
- **completion proof line** (= revise round 1 反映 = ζ Annex 引用形式): FAIL=0 通過時のみ literal 11 行出力 = NG なら gate failure で `ng` line + 末尾未達 = false PASS 不可。
- **`roadmap2-gate-2` literal value proof**: γ で確立した ref trace inline 生成 pattern を継承 = `PMDNEO_V2_ENTRY_FIXTURE=1 MML_INPUTS=ssg-v0-keyon.mml bash scripts/build-poc.sh --chip ym2610` + MAME run → `/tmp/v2-song-playback-roadmap1-ref-ymfm.tsv` cp → γ build trace との FM ch B fnum write value set 比較 (= literal value proof、 clean CI false PASS 排除)。 ε で ref trace 生成後 ε fixture build (= `PMDNEO_V2_SONG_FIXTURE=1`) を rebuild + MAME 再 trace で gate-3〜6 用 trace を復元。
- **driver touch なし** (= §決定 1 ε row literal 遵守 + §決定 8 不可触対象維持)。 ADR-0049〜0057 routine + 既存 `pmdneo_v2_*` routine + cmd 0x05 path + `irq_handler_body` + `part_workarea` + 軸 C/G/rhythm + vendor 完全不可触。

### F-4: ε 検証結果 (= 10 gate ALL PASS literal + completion proof line)

- ε fixture build (= `PMDNEO_V2_SONG_FIXTURE=1` + ym2610): **PASS**
- production build (= `TEST_MODE_V2_SONG_FIXTURE=0`): **PASS**
- `verify-axis-b-v2-song-playback.sh` 10 gate **ALL PASS** literal:
  - roadmap2-gate-1 (v2 song parse): slot 0 ADDR lo uniq 8 件 + slot 0 LEN uniq 17 件 (= init-only false PASS 排除)
  - roadmap2-gate-2 (v2 dispatch wiring): song-driven FM ch B keyon 80 件 + SSG ch G volume 72 件 + FM ch B fnum write value set が roadmap ① ref と異 (= literal value proof、 δ 9 件から **大幅増 = 周期再生成果**)
  - roadmap2-gate-3 (IRQ tick 駆動): IRQ body 内 call assembled + tempo_acc write 2438 件
  - roadmap2-gate-4 (tempo): IRQ tick 2461 > slot 0 LEN write 1219 (= overflow gate 動作)
  - roadmap2-gate-5 (baseline regression): verify-axis-b-fm-ssg-real-sound.sh 6 gate ALL PASS (= ADR-0049〜0057 transitively)
  - roadmap2-gate-6 (.org + build-mode 排他): (a) 15 routine 全 >= 0x0610 + 0x0066 max 0xFD < 0x0100 + (b) production build で 15 routine 全 assemble なし + IRQ call 未 assemble + cold init clear 未 assemble
  - sup-IX/IY: push ix/iy + 単一 epilogue 経由全 exit
  - sup-TIMER-B: pmdneo_irq_count write 2461 件 / 5 秒 = **~492 Hz literal 実測** (= 古い「6 秒 2 回」 finding 完全 stale 確定)
  - sup-γ-pattern: song_entry body 内 call song_init 存在 + call song_dispatch 撤去 + ld (song_state),a 存在
  - sup-cold-boot: song_state write 2 件 + first=00 + has-1=1 + cmd 0x05/0x07 callsite 静的存在
- **completion proof line literal 出力** (= ε deliverable、 ζ Annex 引用可能形式):

```
=== roadmap ② completion proof (ADR-0058 §決定 6 全 PASS = ζ Accepted 移行 ready) ===
§決定 6 gate 1 (v2 song parse):          PASS
§決定 6 gate 2 (v2 dispatch wiring):     PASS
§決定 6 gate 3 (IRQ tick 駆動):          PASS
§決定 6 gate 4 (tempo):                  PASS
§決定 6 gate 5 (baseline regression):    PASS
§決定 6 gate 6 (.org + build-mode 排他): PASS
supplemental gate IX/IY:                 PASS
supplemental gate TIMER-B:               PASS
supplemental gate γ-pattern:             PASS
supplemental gate cold-boot:             PASS
ζ Accepted 移行 ready: yes (ADR-0058 §決定 1 ε 完了)
```

Codex layer 2 = ε kickoff plan review 2 round chain (= round 1 revise completion proof line literal 改訂 + Annex D/E 履歴不変 + Annex F rename 注記 → round 2 approve) → ε 実装 review (= 後続 commit 後)

## Annex G: ζ 完了確認 + Draft → Accepted 移行 record

### G-1: α〜ε 全 sub-sprint 完走 summary

| sub | PR | 完了内容 |
|---|---|---|
| α | PR #96 | 起票 doc-only filing (= 決定 1-9 + 6 段 α/β/γ/δ/ε/ζ + parse 方式 案 b + v2 PartWork compact layout + IRQ 連携 + verify gate 6 件 + scope-in/out) |
| β | PR #97 | v2 PartWork compact slot layout (= `PMDNEO_V2_PARTWORK_SLOT_SIZE` 12 + `PMDNEO_V2_PART_COUNT` 9 + slot field offset 8 件 ADDR/LEN/NOTE/CH_IDX/KIND/OCTAVE/LOOP/FLAGS) + m1 binary byte-identical |
| γ | PR #98 | v2 song parse + per-part dispatch wiring 並設 (= 案 b' 並設 _song_ suffix routine + 案 E'-b 独立 entry + 全 14 routine `.if TEST_MODE_V2_SONG_FIXTURE` 配下 + verify-axis-b-v2-song-parse.sh 6 gate ALL PASS + m1 ROM byte-identical) |
| δ | PR #99 | v2 IRQ tick 連携 + tempo accumulator (= ADR-0050 β `pmdneo_v2_fade_tick` 前例 pattern 1 行 additive + v2 専用 tempo state 0xFD3E-0xFD40 + cold init `pmdneo_v2_song_state=0` clear (= I-12 mitigation) + tick 単一 epilogue + entry 責務変更 dispatch 撤去 + verify 10 gate ALL PASS + **TIMER-B IRQ rate ~492 Hz literal 実測** = 古い「6 秒 2 回」 finding 完全 stale 確定 + production byte-identical) |
| ε | PR #100 | verify script 体系化 (= verify-axis-b-v2-song-parse.sh → verify-axis-b-v2-song-playback.sh rename + §決定 6 命名統一 primary 6 gate `roadmap2-gate-1〜6` + supplemental 4 gate `sup-*` = 10 gate ALL PASS + 末尾 completion proof line 11 行 literal 出力 + ζ Accepted 移行 ready signal + driver touch なし + Annex D/E 履歴不変 + Annex F rename 注記) |

### G-2: ε completion proof line literal 引用 (= roadmap ② 全 gate ALL PASS literal、 Annex F-4 から literal copy)

ε で `bash src/test-fixtures/axis-b/verify-axis-b-v2-song-playback.sh` 実行時の末尾出力:

```
=== roadmap ② completion proof (ADR-0058 §決定 6 全 PASS = ζ Accepted 移行 ready) ===
§決定 6 gate 1 (v2 song parse):          PASS
§決定 6 gate 2 (v2 dispatch wiring):     PASS
§決定 6 gate 3 (IRQ tick 駆動):          PASS
§決定 6 gate 4 (tempo):                  PASS
§決定 6 gate 5 (baseline regression):    PASS
§決定 6 gate 6 (.org + build-mode 排他): PASS
supplemental gate IX/IY:                 PASS
supplemental gate TIMER-B:               PASS
supplemental gate γ-pattern:             PASS
supplemental gate cold-boot:             PASS
ζ Accepted 移行 ready: yes (ADR-0058 §決定 1 ε 完了)
```

= ε commit chain で literal 出力済 + Annex F-4 に literal 記録済 = **ζ Accepted 移行 ready signal**。

### G-3: Draft → Accepted 移行根拠

- ADR-0058 §決定 1 ζ row literal 完了判定 = 「全 sub α〜ε verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由)」 を満たす
- ε で `verify-axis-b-v2-song-playback.sh` 10 gate + completion proof line ALL PASS literal 出力済 (= G-2)
- 「ζ Accepted 移行 ready: yes (ADR-0058 §決定 1 ε 完了)」 literal signal が ε commit chain で出力 + Annex F-4 に literal 記録済
- Codex layer 2 chain = α plan review approve + β 実装 review approve + γ kickoff 1 round + 実装 4 round all approve + δ kickoff 4 round + 実装 2 round all approve + ε kickoff 2 round + 実装 2 round all approve + ζ kickoff 1 round approve
- 全 sub-sprint 規律遵守 = 既存 `pmdneo_song_main` / `pmdneo_part_main` / `commandsp` / `part_workarea` / `irq_handler_body` 既存処理 / `driver_subtick_acc`/`_tempo_d` / ADR-0049〜0057 routine + 既存 `pmdneo_v2_entry_skeleton` / `pmdneo_v2_fm/ssg_voice_note` / 軸 C/G/rhythm / vendor 完全不可触 + production byte-identical 維持

### G-4: Accepted 表記制約 (= user 明示 PR #100 merge GO message literal 反映)

user 明示 (= PR #100 merge GO 承認 message literal):

> ζ は doc-only completion でよいです。 ここでは ADR-0058 Accepted = roadmap ②「実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携」 完了 として扱い、 **production-ready 全体達成とは書かないのが重要**です。

→ ζ の Accepted 表記は以下 3 件を literal 維持:

1. **ADR-0058 Accepted = roadmap ②「実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携」 完了** (= design + 実装 + verify 完走)
2. **「production-ready 全体達成」 と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ② で未実施、 roadmap ③ ADPCM-B/rhythm + roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ②〜④ 完走後の future)
3. **「軸 B 完成」 表現禁止 継続** (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過)

### G-5: ζ deliverable

| deliverable | 内容 |
|---|---|
| 状態行 prefix `**Draft**` → `**Accepted**` | + ε 完了確認 + roadmap ② design+実装+verify 完了 literal + production-ready 全体達成ではない literal + 「軸 B 完成」 表現不使用 literal |
| Annex G 新規 | 本 record (= G-1 α〜ε summary + G-2 completion proof line literal 引用 + G-3 Accepted 移行根拠 + G-4 表記制約 literal + G-5 deliverable) |
| sub-sprint chain ζ 行 = 未着手 → 完了 | PR # 後続 (= ζ doc-only PR、 push 後確定) + Codex layer 2 ζ kickoff plan review 1 round approve + ζ doc review 後続 |
| 改訂履歴 ζ 行追加 | Draft → Accepted 移行 + Accepted = roadmap ② design+実装 完了 literal + production-ready 全体達成と書かない literal + 「軸 B 完成」 表現禁止 継続 literal |
| 平易要約 ζ 完了 reflect | 「ε 完了 + ADR-0058 Draft → Accepted = roadmap ② 完了」 + 「production-ready 全体達成は roadmap ②〜④ + 越川氏 audition 後の future」 literal |
| dashboard 軸 B 行 status column update | `0058 Draft (= roadmap ②)` → `0058 Accepted (= roadmap ② = 実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携 完了)` |
| dashboard 進行履歴 ζ 行追加 | ζ Draft → Accepted 移行 + 表記制約 literal |
| dashboard 予約簿 L66 update | ε 完了 + 残 ζ → ζ 完了 + ADR-0058 Accepted + production-ready 全体達成ではない literal |

### G-6: ζ で扱わない (= scope-out)

- driver / verify script / vendor / build flag / SRAM / .equ 一切 touch なし
- Annex A〜F 本文不変 (= 履歴改変 risk 回避、 ε 同 pattern)
- production-ready 全体達成宣言 (= roadmap ③/④ + audition 残)
- roadmap ③ ADPCM-B/rhythm 着手
- roadmap ④ 軸 G dynamic supply 着手
- 越川氏 audition 着手

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | ζ Draft → Accepted 移行 (= 39th session、 PR #101) | ADR-0058 を Draft → Accepted へ移行 = ADR-0058 Accepted = roadmap ②「実 MML song parse + v2 per-part dispatch loop + IRQ tick 連携」 完了 (= design + 実装 + verify 完走、 = 6 sub-sprint α/β/γ/δ/ε/ζ 全完走 + ε で verify-axis-b-v2-song-playback.sh 10 gate + completion proof line ALL PASS literal 出力 + 「ζ Accepted 移行 ready: yes」 signal)。 doc-only filing (= 主軸直接 edit、 Annex A〜F 本文不変 = 履歴改変 risk 回避)。 Annex G 新規追加 (= G-1 α〜ε 全 sub-sprint 完走 summary + G-2 ε completion proof line literal 引用 11 行 + G-3 Draft → Accepted 移行根拠 = §決定 1 ζ row + ε ALL PASS + Codex chain 全 approve + 規律遵守 literal + G-4 Accepted 表記制約 = user 明示 PR #100 merge GO message literal 反映 = 3 件 (ADR-0058 Accepted = roadmap ② 完了 + production-ready 全体達成と書かない + 「軸 B 完成」 表現禁止 継続) + G-5 deliverable + G-6 scope-out) + sub-sprint chain ζ 行 完了 reflect + 状態行 Draft → Accepted + 平易要約 ζ 完了 reflect + dashboard 軸 B 行 status column update + 進行履歴 ζ 行 + 予約簿 L66 update。 **重要 = production-ready 全体達成と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ② で未実施、 roadmap ③ ADPCM-B/rhythm + roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ②〜④ 完走後の future)。 **「軸 B 完成」 表現禁止 継続** (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過)。 既存 driver / verify script / vendor / build flag / SRAM 一切 touch なし。 既存 cmd 0x05 path / `pmdneo_song_main` / `pmdneo_v2_*` routine + ADR-0049〜0057 + 軸 C/G/rhythm 完全不可触 (= 全 sub-sprint chain 通算)。 Codex layer 2 = ζ kickoff plan review 1 round approve (= doc-only scope + Annex G 構造 + 表記制約 literal + 主軸直接 edit 妥当性 全 ok、 escalate なし) + ζ doc review (= 後続 commit 後投入) |
| 2026-05-23 | ε 実装完了 (= 39th session、 PR #100) | verify script 体系化。 `verify-axis-b-v2-song-parse.sh` (= γ 6 gate → δ 10 gate) を `verify-axis-b-v2-song-playback.sh` に rename (= §決定 1 ε literal 推奨命名)。 §決定 6 primary 6 gate (= `roadmap2-gate-1〜6` 命名統一 = v2 song parse / v2 dispatch wiring / IRQ tick 駆動 / tempo / baseline regression / .org + build-mode 排他) + supplemental 4 gate (= `sup-IX/IY` δ-4 / `sup-TIMER-B` δ-5 / `sup-γ-pattern` δ-8 / `sup-cold-boot` δ-10) = 計 10 gate に統合 + 末尾 completion proof line 11 行 (= §決定 6 全 PASS + supplemental 全 PASS + ζ Accepted 移行 ready signal) 追加。 driver touch なし (= §決定 1 ε row literal 遵守、 ADR-0049〜0057 routine + 既存 `pmdneo_v2_*` routine + cmd 0x05 path + `irq_handler_body` + `part_workarea` + 軸 C/G/rhythm + vendor 完全不可触)。 Annex D (γ) / Annex E (δ) 本文不変 (= 当時 literal 記録維持、 履歴改変 risk 回避)、 ε 以降は本 Annex F + 新 script を ground truth とする。 検証 = ε fixture build PASS + production build PASS + 10 gate ALL PASS literal (= roadmap2-gate-1 ADDR lo uniq 8 + LEN uniq 17 / roadmap2-gate-2 FM keyon 80 + SSG volume 72 (= δ 9 件から **大幅増 = 周期再生成果**) + literal value proof / roadmap2-gate-3 tempo_acc write 2438 / roadmap2-gate-4 IRQ 2461 > LEN write 1219 / roadmap2-gate-5 baseline / roadmap2-gate-6 .org + 排他 / sup-IX/IY epilogue / sup-TIMER-B **~492 Hz literal 実測** 古い stale 確定 / sup-γ-pattern entry / sup-cold-boot 0→1 sequence + cmd callsite) + completion proof line 11 行 literal 出力 (= ζ Annex 引用可能形式)。 Annex F 追記 + sub-sprint chain ε 完了 reflect + 状態行/平易要約 ε 同期 + 改訂履歴 ε 行。 Codex layer 2 = ε kickoff plan review 2 round chain (= round 1 revise = D' completion proof line literal 改訂 + Annex D/E 履歴不変 + Annex F rename 注記 → round 2 approve) → ε 実装 review (= 後続 commit chain で投入)。 軸 B roadmap ② ε、 残 ζ (= Draft → Accepted 移行)、 「軸 B 完成」 表現不使用 (= v2 driver production-ready 化 + roadmap ②〜④ + 越川氏 audition が残る) |
| 2026-05-23 | δ 実装完了 (= 39th session、 PR #99) | v2 IRQ tick 連携 + tempo accumulator 実装。 `standalone_test.s` に v2 SRAM `.equ` 3 件 (= `pmdneo_v2_song_state` 0xFD3E / `_tempo_acc` 0xFD3F / `_tempo_d` 0xFD40) + SRAM layout comment 3 行追加 + free byte range 表記更新 (= 0xFD41-0xFD78 = 56 byte) + cold init `.if TEST_MODE_V2_SONG_FIXTURE / xor a / ld (pmdneo_v2_song_state),a / .endif` を `nmi_clear_driver_state` loop 後に additive 追加 (= I-12 mitigation = cold boot false active 防止、 全経路 cover) + `irq_handler_body` 内 `call pmdneo_v2_fade_tick` 直後に `.if / call pmdneo_v2_song_tick / .endif` 1 行 additive 追加 (= ADR-0050 β 前例 pattern) + 新 routine `pmdneo_v2_song_tick` を `.if` 配下に追加 (= IX/IY 退避 + state check + tempo accumulator overflow gate + 単一 epilogue で全 exit pop pair 順序保証) + `pmdneo_v2_song_entry` 責務変更 (= γ の dispatch 直接 call 撤去 → init + tempo init + active flag 最後 set、 dispatch は IRQ 駆動委ね、 `call pmdneo_v2_song_init` 必須維持 = I-11 mitigation)。 `verify-axis-b-v2-song-parse.sh` を γ 6 gate から δ 10 gate (= δ-1〜δ-10) に完全 rewrite (+234/-124 行、 案 F-a)。 検証 = production build PASS + production byte-identical (= 新 15 routine 全 assemble なし) + δ fixture build PASS + δ 10 gate ALL PASS (= δ-1 IRQ tick 駆動 + δ-2 tempo overflow gate + δ-3 周期再生 ADDR uniq 9 値 + δ-4 IX/IY 単一 epilogue + δ-5 TIMER-B IRQ rate **~492 Hz literal 実測** = 古い「6 秒で 2 回」 finding 完全 stale 確定 + δ-6 baseline regression + δ-7 production byte-identical + δ-8 γ pattern 移行 + δ-9 .org overflow なし + δ-10 cold boot inactive + cmd 0x05/cmd 0x07 両 callsite 静的確認)。 Annex E 追記 + sub-sprint chain δ 完了 reflect + 状態行/平易要約 δ 同期。 既存 `pmdneo_song_main` / `pmdneo_part_main` / `commandsp` / `part_workarea` / `irq_handler_body` 既存処理 / `driver_subtick_acc/_tempo_d` / ADR-0049〜0057 routine + 既存 `pmdneo_v2_entry_skeleton` + 軸 C/G/rhythm 完全不可触。 Codex layer 2 = δ kickoff plan review 4 round chain (= round 1 revise SRAM 0xFD3D 衝突 + tick 単一 epilogue + entry song_init 必須維持 + verify F-a + risk I-10〜I-13 + sub-agent prompt 強化 → round 2 revise cold init 全経路 → round 3 revise δ-10 cmd 0x05 callsite 整合 → round 4 approve) → δ 実装 review (= 後続 commit 後)。 軸 B roadmap ② δ、 残 ε/ζ、 「軸 B 完成」 表現不使用 (= v2 driver の production-ready 化 + roadmap ②〜④ + 越川氏 audition が残る) |
| 2026-05-23 | γ 実装完了 (= 39th session、 PR #98) | v2 song parse + per-part dispatch wiring 並設。 `standalone_test.s` に `.if TEST_MODE_V2_SONG_FIXTURE` 配下で新 14 routine (= `pmdneo_v2_song_init` / `_dispatch` / `_part_tick` / `_part_parse` / `_part_note` / `_part_rest` / `_part_loop` / `_part_fetch_byte` / `_part_dispatch_note` + 案 b' 並設 `_fm_voice_note_song` / `_ssg_voice_note_song` + 案 E'-b 独立 entry `_song_entry` + fixture 2 件 `_song_fixture_fm_b` / `_ssg_g`) を 0x0610 セクション末尾に追加 + `.equ TEST_MODE_V2_SONG_FIXTURE, 0` 追加 + `nmi_cmd_7_play_song_v2` cmd 0x07 path を `.if/.else/.endif` で build-mode 排他化 (= 案 E'-b) + `nmi_cmd_5_init_mml_song` 末尾に fixture call 追加 (= γ verify trace 起動経路)。 `scripts/build-poc.sh` + `vendor/ngdevkit-examples/00-template/build.mk` に `PMDNEO_V2_SONG_FIXTURE` flag pass 経路追加 (= 既存 `TEST_MODE_V2_ENTRY_FIXTURE` と同 pattern)。 新規 `src/test-fixtures/axis-b/verify-axis-b-v2-song-parse.sh` (= 186 行) で γ verify gate 6 件 (= γ-1〜γ-6) 体系化。 dispatcher refactor 案 b' (= 既存 `_fm/ssg_voice_note` 完全不変、 song 用 routine 並設) + cmd 0x07 wiring 案 E'-b (= 既存 entry skeleton 完全不変、 build-mode で song_entry / entry_skeleton 排他選択) で ADR-0058 §決定 8 (= ADR-0049〜0057 routine + entry skeleton 不可触) 遵守。 fixture note 0x42/0x45/0x48 (= roadmap ① 固定 table 0x40/0x44/0x47 と全 byte 異) で γ-2 song-driven proof 強化。 LOOP=fixture base 初期値 init literal 設定 (= I-9 mitigation)。 全 γ routine を `.if TEST_MODE_V2_SONG_FIXTURE` 配下に閉じ `=0` build で 14 routine 全 assemble なし (= I-6 mitigation = γ-6 production byte-identical)。 検証 = production build PASS + **m1 ROM byte-identical** (= sub-agent worktree 内 `cmp` で base ref e009bfd と literal 一致 = γ-6 最強 proof) + γ fixture build PASS + verify-axis-b-v2-song-parse.sh 6 gate ALL PASS (= γ-1 slot 0/1 ADDR write 各 6 件 + γ-2 song-driven FM ch B keyon 9 / SSG ch G volume 1 + γ-3 LEN set 各 1 件 + γ-4 verify-axis-b-fm-ssg-real-sound.sh 6 gate 全 PASS transitively ADR-0049〜0057 regression + γ-5 .org overflow なし + γ-6 production byte-identical 全 PASS)。 Annex D 追記 + sub-sprint chain γ 完了 reflect + 状態行/平易要約 γ 同期。 既存 `pmdneo_song_main` / `pmdneo_part_main` / `commandsp` / `part_workarea` / `irq_handler_body` body / ADR-0049〜0057 で追加 routine + 既存 `pmdneo_v2_entry_skeleton` + 軸 C/G/rhythm 完全不可触。 Codex layer 2 = γ kickoff plan review revise (= 案 b' + E'-b 推奨 + γ-2/γ-3/γ-6 + I-6〜I-9 反映) → 実装 + γ verify ALL PASS 後 layer 2 実装 review (= 後続 commit chain で投入)。 軸 B roadmap ② γ、 残 δ/ε/ζ、 「軸 B 完成」 表現不使用 |
| 2026-05-23 | β 実装完了 (= 39th session、 PR #97) | v2 PartWork compact layout 確定。 `standalone_test.s` に v2 専用 compact slot `.equ` layout (= `PMDNEO_V2_PARTWORK_SLOT_SIZE` 12 + `PMDNEO_V2_PART_COUNT` 9 + slot field offset 8 件 ADDR/LEN/NOTE/CH_IDX/KIND/OCTAVE/LOOP/FLAGS) を追加 + SRAM layout comment 更新。 ADR-0053 §決定 2 の v2 PartWork region 0xFD79-0xFE78 に slot N = base + N×12 で配置 (= 12×9 = 108 byte ≤ 256)。 Annex C 追記 + sub-sprint chain β 完了 reflect + 状態行/平易要約 β 同期。 検証 = production build PASS + m1 binary byte-identical (= β は unused symbol の `.equ` のみ = byte 非出力 = Z80 driver binary 不変、 ADR-0053 β と同 pattern、 baseline regression は同一 binary で trivially 維持)。 既存 part_workarea + ADR-0049〜0057 + 軸 C/G/rhythm 完全不可触。 Codex layer 2 = β 実装 review approve。 軸 B roadmap ② β、 残 γ/δ/ε/ζ、 「軸 B 完成」 表現不使用 |
| 2026-05-23 | Draft 起票 (= 39th session 軸 B production-ready roadmap ② α) | v2 driver production-ready roadmap ② = song parse + per-part dispatch loop + IRQ tick 連携 の実装 ADR を起票。 ADR-0056 §決定 4 roadmap ② の実装 ADR として、 v2 driver を one-shot 固定 note 再生から「実 MML 曲を時間進行で鳴らす」 driver へ昇格する設計を固定。 決定 1-9 + 6 段 sub-sprint α/β/γ/δ/ε/ζ + parse 方式 = 案 (b) 既存 MML byte 解釈基盤 + v2 dispatch wiring (= 案 a 完全専用 parser / 案 c 既存 pmdneo_song_main 単純流用 = roadmap ① bypass は不採用) + v2 PartWork compact layout (= ADR-0053 v2 PartWork region 0xFD79-0xFE78) + IRQ 連携 (= irq_handler_body へ v2 hook 1 行 additive + build-mode 排他) + v2 dispatcher 固定 note → song-driven note 置換 + verify gate 6 件 + scope-out (= ADPCM-B/rhythm は roadmap ③、 軸 G は roadmap ④)。 doc-only filing (= ADR-0058 + dashboard のみ)。 並列 sub-agent 3 体調査の ground truth (= 既存 MML parser / IRQ 機構 / v2 path 現状) を Annex A/B に literal 化。 核心の気づき = 既存 pmdneo_song_main 単純流用は roadmap ① の v2 dispatcher を bypass するため、 roadmap ② は song parse 出力を v2 dispatcher へ feed する wiring 必須。 Codex layer 2 起票 plan review approve (= 案 b parse 方式 + 6 段 sub-sprint + 全 4 論点 (parse 方式/v2 PartWork/IRQ 連携/scope 分割) + 規律 + ADR 番号 0058 approve、 escalate なし)。 ADR-0058 = roadmap ② 実装、 production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用 |
