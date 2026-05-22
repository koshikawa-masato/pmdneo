# ADR-0058: PMDNEO 軸 B v2 driver production-ready roadmap ② = song parse + per-part dispatch loop + IRQ 連携

- 状態: **Draft** (= 2026-05-23 39th session 軸 B production-ready roadmap ②、 ground truth = ADR-0056 roadmap ② / ADR-0057、 α 起票 doc-only filing + β v2 PartWork compact layout 完了、 後続 γ/δ/ε/ζ で song parse+dispatch wiring → IRQ+tempo → verify → completion。 ADR-0056 §決定 4 roadmap ② literal 後続実装 ADR。 **v2 driver を one-shot 固定 note 再生から「実 MML 曲を時間進行で鳴らす」 driver へ昇格する実装 ADR**。 production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用)
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

**進捗 (= α/β 完了)**: α で設計書 (= 本 ADR-0058) を起票し、 曲解釈の方式・パート状態の置き場所・IRQ 連携の方法・検証方法を文書で固定した。 β でドライバ (= `standalone_test.s`) に v2 専用のパート状態置き場 (= v2 PartWork compact slot = 12 byte/part × 9) のレイアウト定数を追加した。 β は定数のみで Z80 ドライバ binary は byte-identical (= 不変)。

**核心**: 既存ドライバの MML 曲解釈ロジックは信頼して基盤に使うが (= 案 b)、 各パートの「音を鳴らす出口」 は roadmap ① で作った v2 dispatcher へ向ける。 既存ドライバをそのまま流用すると roadmap ① の v2 dispatcher が使われずに無駄になるため。

**次**: γ で曲解釈 + dispatch 配線 (= v2 song parse を v2 dispatcher へ feed)、 δ で IRQ 連携 + tempo、 ε で検証スクリプト、 ζ で Draft → Accepted へ移行する。 ADPCM-B/rhythm は roadmap ③、 production-ready 達成宣言はまだしない。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0058 起票) | **進行中** (= 39th session、 本 PR) | (= 本 PR) | 起票 plan review approve (= 案 b + 6 段 + 全 4 論点 + 規律 approve、 escalate なし) + 起票 review |
| β (= v2 PartWork compact layout) | **完了** (= 39th session、 PR #97) | PR #97 | β 実装 review approve |
| γ (= v2 song parse + dispatch wiring) | 未着手 | - | - |
| δ (= IRQ 連携 + tempo) | 未着手 | - | - |
| ε (= verify script 体系化) | 未着手 | - | - |
| ζ (= completion + Draft → Accepted 判断) | 未着手 | - | - |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | β 実装完了 (= 39th session、 PR #97) | v2 PartWork compact layout 確定。 `standalone_test.s` に v2 専用 compact slot `.equ` layout (= `PMDNEO_V2_PARTWORK_SLOT_SIZE` 12 + `PMDNEO_V2_PART_COUNT` 9 + slot field offset 8 件 ADDR/LEN/NOTE/CH_IDX/KIND/OCTAVE/LOOP/FLAGS) を追加 + SRAM layout comment 更新。 ADR-0053 §決定 2 の v2 PartWork region 0xFD79-0xFE78 に slot N = base + N×12 で配置 (= 12×9 = 108 byte ≤ 256)。 Annex C 追記 + sub-sprint chain β 完了 reflect + 状態行/平易要約 β 同期。 検証 = production build PASS + m1 binary byte-identical (= β は unused symbol の `.equ` のみ = byte 非出力 = Z80 driver binary 不変、 ADR-0053 β と同 pattern、 baseline regression は同一 binary で trivially 維持)。 既存 part_workarea + ADR-0049〜0057 + 軸 C/G/rhythm 完全不可触。 Codex layer 2 = β 実装 review approve。 軸 B roadmap ② β、 残 γ/δ/ε/ζ、 「軸 B 完成」 表現不使用 |
| 2026-05-23 | Draft 起票 (= 39th session 軸 B production-ready roadmap ② α) | v2 driver production-ready roadmap ② = song parse + per-part dispatch loop + IRQ tick 連携 の実装 ADR を起票。 ADR-0056 §決定 4 roadmap ② の実装 ADR として、 v2 driver を one-shot 固定 note 再生から「実 MML 曲を時間進行で鳴らす」 driver へ昇格する設計を固定。 決定 1-9 + 6 段 sub-sprint α/β/γ/δ/ε/ζ + parse 方式 = 案 (b) 既存 MML byte 解釈基盤 + v2 dispatch wiring (= 案 a 完全専用 parser / 案 c 既存 pmdneo_song_main 単純流用 = roadmap ① bypass は不採用) + v2 PartWork compact layout (= ADR-0053 v2 PartWork region 0xFD79-0xFE78) + IRQ 連携 (= irq_handler_body へ v2 hook 1 行 additive + build-mode 排他) + v2 dispatcher 固定 note → song-driven note 置換 + verify gate 6 件 + scope-out (= ADPCM-B/rhythm は roadmap ③、 軸 G は roadmap ④)。 doc-only filing (= ADR-0058 + dashboard のみ)。 並列 sub-agent 3 体調査の ground truth (= 既存 MML parser / IRQ 機構 / v2 path 現状) を Annex A/B に literal 化。 核心の気づき = 既存 pmdneo_song_main 単純流用は roadmap ① の v2 dispatcher を bypass するため、 roadmap ② は song parse 出力を v2 dispatcher へ feed する wiring 必須。 Codex layer 2 起票 plan review approve (= 案 b parse 方式 + 6 段 sub-sprint + 全 4 論点 (parse 方式/v2 PartWork/IRQ 連携/scope 分割) + 規律 + ADR 番号 0058 approve、 escalate なし)。 ADR-0058 = roadmap ② 実装、 production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用 |
