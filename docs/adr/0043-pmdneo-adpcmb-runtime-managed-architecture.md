# ADR-0043: PMDNEO ADPCM-B 1ch runtime-managed architecture 設計 (= 軸 C α、 4 sub-sprint 構成)

- 状態: **Draft** (= 2026-05-18、 軸 C α、 ADR-0041 併走運用下)
- 起票日: 2026-05-18
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由 sub-agent C による起票、 ADR-0041 §決定 4 規律遵守)
- 関連 ADR:
  - ADR-0016 (= 改造実装 sprint 作業計画、 step 4 = ADPCM-B 本実装 完了 milestone)
  - ADR-0019 (= ADPCM-A 6ch 設計、 step 5 α/β/γ/δ/ε 5 段 reference)
  - ADR-0021 (= `.PNE` asset pipeline、 path B / c1 採用、 ADPCM-B yaml 別系統管理 確立)
  - ADR-0022/0023/0024/0025 (= runtime-managed architecture 確立、 sample_table_id selection arch)
  - ADR-0041 (= Claude Code 併走運用、 主軸 + sub-agent + Codex 2 段壁打ち + fallback 規律)
- 関連 memory:
  - `project_pmdneo_adpcma_subsystem_boundary.md` (= ADPCM-A subsystem 境界、 ADPCM-B 軸との分離)
  - `project_pmddotnet_chextend_data_area.md` (= partWork ch 拡張、 J part PCM データ領域)
  - `project_pmdneo_step5_complete.md` (= ADPCM-A step 5 完了、 軸 C reference pattern)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
  - `feedback_subagent_codex_loop_with_escalation.md` (= sub-agent 規律)

## 背景

PMDNEO は YM2610(B) 2 系統 ADPCM (= ADPCM-A 6ch + ADPCM-B 1ch) を駆動する。 既に **ADPCM-A 軸**は ADR-0016 step 5-18 + ADR-0019 〜 ADR-0032 で完成済 (= L-Q part 6 ch dispatch + sample_table_id selection + K/R rhythm compatibility + 6 drum 種 expansion + simultaneous trigger semantics、 runtime-managed architecture 段階到達、 `project_pmdneo_adpcma_subsystem_boundary.md` literal)。

**ADPCM-B 軸**は ADR-0016 step 4 (= SubE 完成、 2026-05-12 5th session、 commit `8e3dc59`) で基礎実装が成立済:

- `adpcmb_keyon` / `adpcmb_keyoff` / `adpcmb_volset` / `adpcmb_panset` / `adpcmb_setfreq` 実装 (= `src/driver/ADPCMB_DRV.inc` 72 行 + `src/driver/standalone_test.s` L2603-3567 本線実装、 後者が ADR-0043 実装対象 ground truth)
- `ADPCMB_DRV.inc` (= 72 行) は core/legacy reference として参照する。 同 file L9-L12 の `.PPC` 利用コメントは「PMD V4.8s `.m2` の OPNA ADPCM RAM 経路を YM2610(B) 内蔵 ADPCM-B に対応付ける」 という後続構想 (= 候補 ADR-0048) を記述したもので、 ADR-0043 起票時点 (= 2026-05-18) 実装状態ではない。 J part runtime path の現役対象は `standalone_test.s` L2603-3567。
- delta-N chromatic table 24 byte (= 12 entries × 16-bit、 `adpcmb_deltan_chromatic` L3567-3579) + `adpcmb_note_to_deltan` octave shift routine
- J part body 由来 note 値 → delta-N 制御 + chip register 0x19/0x1A 書込 + audio 出力成立
- audio gate (= MAME 録音 wav sha256 で fixture 差分検出、 `b542cd92...` vs `5f194cd4...`)、 ymfm-trace primary gate
- sample data は **beat.wav 固定** (= `samples.inc` 由来 BEAT_START_LSB/MSB + BEAT_STOP_LSB/MSB、 L2698-2710)
- yaml `assets/pne/samples-map-adpcmb.yaml` で `.PPC` 不在 + beat.wav 単独 passthrough 経由で VROM 焼込済 (= ADR-0021 §c1 採用根拠)

しかし step 4 時点では:

1. **sample 切替不能** = J part が beat.wav 固定 (= `BEAT_START_LSB/MSB` literal 参照、 L2700)、 別 sample に切り替える経路なし
2. **selection arch 不在** = ADPCM-A `sample_table_id` (= ADR-0023/0024/0025) のような id → sample 選択 routine が J part に存在しない
3. **`.PPC` asset pipeline 未着手** = PMD V4.8s `.PPC` format (= PMDB2 用 ADPCM RAM sample pack) の driver parse / runtime selection 経路未実装
4. **multi-table 不在** = ADPCM-A multi-table id=0x01 proof (= ADR-0025) のような sample 切替実証なし

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 ADPCM-A 軸の対称構造として ADPCM-B 1ch runtime-managed architecture 設計を本 ADR で確立する。 ADR-0019 が ADPCM-A step 5 α/β/γ/δ/ε 5 段で確立した pattern を、 **ch 軸不要 (= 1 ch 専用)** で 1 段減らした **4 段 α/β/γ/δ** 構成とする。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) 下で起票。

## 決定

### 決定 1: ADPCM-B 軸 sub-sprint 構成 = 4 段 α/β/γ/δ

ADPCM-B 軸を **4 段階 α/β/γ/δ** に分割する。 ADPCM-A 軸の 5 段 (= ADR-0019) から ch 軸 (= γ step) を **削除** (= ADPCM-B 1 ch 専用、 multi-ch dispatch 不要)。 各 sub = 1 commit + 1 push、 primary gate は ADPCM-B register trace / ymfm-trace、 wav sha256 は timing-sensitive reference。

| sub | 内容 | 完了判定 |
|---|---|---|
| **α** | sample selection arch 設計 + driver routine 新規追加 (= `pmdneo_select_adpcmb_sample_pointer` 中間 routine、 `adpcmb_keyon` 内に挿入) | ADPCM-A `pmdneo_select_sample_pointer` 対称構造で sample header pointer を返す routine が J part keyon 経路で動作、 trace で sample addr 引き経路確認 |
| **β** | multi-sample fixture 比較 (= J ch only で sample A / sample B fixture、 build-time `samples.inc` 拡張、 voice index table 化 + A register range check 配置 = pmdneo_select_adpcmb_sample_pointer 内で voice index → sample id lookup table 経由、 unknown range は adpcmb_select_sample_unknown_id sentinel 経路統合、 ADPCM-A 軸 sample_table 対称構造踏襲) | start/stop addr 差分 (= reg 0x12/0x13/0x14/0x15) を register trace で確認、 delta-N / vol / pan は固定で同一、 verify script 自動 PASS |
| **γ** | sample_table_id integration (= ADPCM-A multi-table proof pattern 踏襲、 J part が `sample_table_id` に応じて ADPCM-B sample 切替) | id=0x00 / id=0x01 fixture 比較で sample 切替 observable proof、 ADPCM-A 軸との独立性 (= ADPCM-A 側 register write 不変) trace 確認 |
| **δ** | 統合 (= ADPCM-B + ADPCM-A 同時演奏 fixture 1 つ以上 MAME 再生 + audio gate + ADR Accepted 移行) | 全 sub α/β/γ verify gate PASS + audio gate (= 越川氏 audition) 通過 |

> 注記: 本 ADR-0043 起票 (= 軸 C α task = ADR doc 起票そのもの) と sub-sprint α (= driver routine 新規追加) は **別 step**。 起票 (= 本 commit、 doc-only) を経て、 後続 sub-sprint α/β/γ/δ が順次着手される。

#### 共通規律 (= 全 sub-sprint 共通、 ADR-0019 §決定 6 踏襲)

- 各 sub = **1 commit + 1 push** (= `feedback_post_commit_push_report_format` + `feedback_push_per_commit` 適用)
- **primary gate = ADPCM-B register trace / ymfm-trace** (= reg 0x10-0x1B、 `feedback_refactor_gate_register_trace_not_wav` 適用)
- wav sha256 は **timing-sensitive reference** (= cycle 数増減で sample shift 許容)
- 各 commit 前に「平易な日本語で説明」 + user レビュー待ち (= `feedback_explain_in_plain_japanese_before_commit` 適用)
- driver / runtime layer touch commit = MAME 起動確認義務 (= CLAUDE.md §動作確認義務、 audio gate 必須)
- ADR-0041 §決定 4 規律 = sub-agent ↔ Codex 壁打ち + 3 重 zero-trust review、 ADR-0041 §決定 5 escalation 6 種準拠

### 決定 2: `.PPC` asset pipeline = 本軸 scope-out、 yaml passthrough 継続

ADPCM-B sample 供給経路は **本軸 (= ADR-0043) では `assets/pne/samples-map-adpcmb.yaml` hand-written passthrough を継続**、 `.PPC` format (= PMD V4.8s PMDB2 用 ADPCM RAM sample pack) の driver parse / runtime selection は **scope-out**、 別 ADR (= 候補 ADR-0048 等、 後続) で扱う。

**理由**:

- ADR-0019 §決定 3 (= ADPCM-A の場合) と同じ理屈で「build 時 embed」 が最小規模で proof 可能
- ADR-0021 §c1 採用根拠 (= `.PNE` = ADPCM-A 専用 format、 ADPCM-B は yaml 別系統管理) literal 継承
- `.PPC` driver parse 同時実装は scope 膨張 + 検証軸増加 + ADPCM-A 軸との対称 sample selection 設計を曖昧化
- 既存 `samples-map-adpcmb.yaml` + `vromtool.py` merge 経路 (= ADR-0021 §決定 5) は安定動作中
- `.PPC` の WebApp 経由 ADPCM-B 管理 UI / converter は Phase 4 領域 (= `samples-map-adpcmb.yaml` 末尾 comment literal)

**運用**:

- β / γ の multi-sample fixture も build-time `samples.inc` 拡張 (= ADPCM-A β 同様、 BEAT_START_LSB/MSB に加えて 2 つ目以降 sample symbol を embed)
- yaml に新規 sample 追加 → vromtool.py merge で VROM 焼込 → driver は固定 symbol で参照
- `.PPC` parser は本 ADR §scope-out、 接続点予約のみ後続 ADR で記述
- 後続軸 (= 候補 ADR-0048) で WebApp WAV → `.PPC` 変換 + driver runtime selection を扱う

### 決定 3: sample selection arch = ADPCM-A `sample_table_id` pattern 踏襲

ADPCM-B sample selection は **ADPCM-A `sample_table_id` (= ADR-0023/0024/0025) pattern を踏襲** する。 driver runtime SRAM 0xFD32 にある **既存 `sample_table_id` (= 1 byte)** を ADPCM-B 軸も共有参照、 sample 切替 routine `pmdneo_select_adpcmb_sample_pointer` を新規追加 (= ADPCM-A `pmdneo_select_sample_pointer` 対称構造)。

**理由**:

- 「同じ `.PNE` filename context で ADPCM-A / ADPCM-B sample table が連動切替する」 が semantic に自然 (= `sample_table_id` は ADPCM-B の asset format ではなく、 既存 resolver が持つ共通 selection id として利用する、 `.PPC` scope-out (= §決定 2) と独立した話)
- ADPCM-A 軸で確立した resolver / selector 構造 (= ADR-0023 D1 hand-written directory + T3 独立 routine、 ADR-0024 A2 中間 routine 経由 pointer 返却) を ADPCM-B 軸で再利用、 driver 内 selection arch 設計言語の統一
- ADR-0041 §決定 1 (= 軸間衝突回避) 観点でも、 `sample_table_id` SRAM 領域 0xFD32 は ADPCM-A / ADPCM-B 共用 (= 1 byte) で competing write が発生しない
- ADPCM-B 専用 selection id を別途設けると複雑化 + future user-facing sample switch UI も別 model になる、 統一が望ましい

**運用 (= α 実装内容)**:

1. `pmdneo_select_adpcmb_sample_pointer` 新規 routine (= `standalone_test.s` 内、 ADPCM-A `pmdneo_select_sample_pointer` の対称構造)
2. 入力: voice index (= J part `PART_OFF_INSTRUMENT` 経由) + 0xFD32 `sample_table_id` 参照
3. 出力: DE = sample header pointer (= start/stop LSB/MSB を含む 4 byte 連続 structure pointer) or 0x0000 sentinel (= silent)
4. `adpcmb_keyon` (= L2692) 内で `BEAT_START_LSB/MSB` literal 参照を **撤去**、 `pmdneo_select_adpcmb_sample_pointer` 呼出で動的解決 + DE pointer から 4 byte 読み出して reg 0x12/0x13/0x14/0x15 書込
5. id=0x00 only-accept (= ADPCM-A ADR-0024 §決定 3 と同等)、 id != 0x00 → DE = 0x0000 → keyon skip (= mismatch silent literal)
6. ADPCM-A `pmdneo_select_sample_pointer` (= routine 定義 L3067、 call site L2784) と独立 routine、 共有 routine 化は γ 完了後判断 (= 早すぎる抽象化回避、 「3 行重複は早すぎる抽象化より良い」 CLAUDE.md §スコープ外踏み込み禁止)

**ADPCM-A 軸との非対称箇所** (= ch 軸不要に起因):

- ADPCM-A: 6 ch 各 ch で sample 引き (= L-Q part 各々独立)
- ADPCM-B: 1 ch のみ (= J part 単独)、 ch index 引数不要
- ADPCM-B: keyon 経路で sample addr 4 byte (= start/stop LSB/MSB) を register write、 ADPCM-A は ch 単位 reg 0x10+ch/0x18+ch/0x20+ch/0x28+ch (= 6 set)

### 決定 4: build-time sample table = `samples.inc` 拡張

β / γ 用 multi-sample は **build-time embed (= `samples.inc` 拡張)** で進める。 既存 `BEAT_START_LSB/MSB/BEAT_STOP_LSB/MSB` symbol に加えて 2 つ目 sample symbol (= 仮称 `SAMPLEB1_START_LSB/MSB/SAMPLEB1_STOP_LSB/MSB`) を embed、 driver は sample id → symbol pointer table 引きで sample addr 解決。

**理由**:

- ADR-0019 §決定 3 + ADR-0025 §決定 (= multi-table id=0x01 proof) と同じ理屈
- yaml `assets/pne/samples-map-adpcmb.yaml` 拡張 → vromtool.py merge → `samples.inc` に新規 symbol 自動 emit (= 既存 build pipeline 利用)
- driver は固定 symbol pointer table (= 仮称 `adpcmb_sample_ptr_table`) で id → start/stop addr 解決
- ADPCM-A `adpcma_sample_ptr_table_b` (= ADR-0025) と対称構造、 「runtime-managed architecture」 段階到達の意味付け統一

**運用**:

- β: yaml に 2 つ目 sample entry 追加 + driver `adpcmb_sample_ptr_table_a` (= id=0x00 用) に 2 entry (= beat + sample B1) 追加、 voice index で sample 切替
- γ: yaml に 3 つ目 sample entry 追加 + `adpcmb_sample_ptr_table_b` (= id=0x01 用) 新設、 `sample_table_id` で table 切替
- δ: yaml + sample table 固定、 ADPCM-A 軸との同時演奏 fixture で audio gate

### 決定 5: scope-in / scope-out 明示

#### scope-in (= 本 ADR-0043 軸 C 範囲)

- ADPCM-B 1 ch sample selection arch 設計 + driver routine 新規追加 (= `pmdneo_select_adpcmb_sample_pointer`)
- build-time multi-sample table 拡張 (= `samples.inc` + yaml 連動)
- `sample_table_id` (= 0xFD32) を ADPCM-A 軸と共用、 ADPCM-B 軸でも参照
- α/β/γ/δ 4 sub-sprint chain + 各 sub 完了判定通過
- ADPCM-A 軸 + ADPCM-B 軸 同時演奏 fixture 1 つ以上 MAME 再生 + audio gate

#### scope-out (= 本 ADR-0043 軸 C 範囲外、 後続 sprint で扱う)

- `.PPC` format (= PMD V4.8s PMDB2 用 ADPCM RAM sample pack) driver parse (= 別 ADR 候補 ADR-0048)
- WebApp WAV → `.PPC` 変換 UI (= Phase 4 領域)
- ADPCM-B sample table id=0x02 以上 multi-bank 拡張 (= 本 ADR は id=0x00 / 0x01 まで proof、 これを超える本格 multi-bank 拡張は scope-out)
- ADPCM-B 用 vol envelope / LFO (= chip 仕様外、 不要)
- ADPCM-A `pmdneo_select_sample_pointer` と ADPCM-B `pmdneo_select_adpcmb_sample_pointer` の共有 routine 化 (= γ 完了後判断、 早すぎる抽象化回避)
- 他軸 (= 軸 A sample provenance / 軸 F MML compiler 拡張) touch
- vendor 配下 touch (= 完全不可触、 ADR-0041 §forbidden write set)
- main 直接 push / `wip-pmddotnet-opnb-extension` 直接 commit (= ADR-0041 §決定 3、 `wip-axis-c-adpcmb` branch 集約)

### 決定 6: verify 計画 = primary gate ADPCM-B register trace + audio gate

各 sub-sprint の verify は **ADR-0019 §決定 5 + `feedback_refactor_gate_register_trace_not_wav` 完全踏襲**。

- **primary gate = ADPCM-B register trace / ymfm-trace** (= reg 0x10-0x1B、 特に 0x12/0x13/0x14/0x15 = start/stop addr LSB/MSB)
- wav sha256 = **timing-sensitive reference** (= cycle 数増減で sample shift 許容、 primary 判定にしない)
- 各 fixture 単位で `src/test-fixtures/axis-c/<sub>-<purpose>.mml` + `src/test-fixtures/axis-c/verify-<sub>-<purpose>.sh` 自動 PASS 化
- audio gate (= MAME 起動 + 越川氏 audition) = δ 完了時 + driver / runtime touch commit ごと (= CLAUDE.md §動作確認義務)
- ADR-0025 (= ADPCM-A multi-table id=0x01 proof) の verify pattern (= 3 観点同時 + literal value assert) を γ 段で踏襲

**β / γ 観測項目** (= ADPCM-A pattern 対称):

| 観測 reg | 期待 (sample 切替時) | 期待 (id 切替時) |
|---|---|---|
| reg 0x12/0x13 (= start LSB/MSB) | sample 間 differ | id 間 differ |
| reg 0x14/0x15 (= stop LSB/MSB) | sample 間 differ | id 間 differ |
| reg 0x19/0x1A (= delta-N) | 固定 (= 同一 note) | 固定 |
| reg 0x1B (= volume) | 固定 | 固定 |
| reg 0x11 (= pan) | 固定 | 固定 |
| reg 0x10 (= keyon trigger) | bit pattern 同一 (= 0x00 clear → 0x80 trigger の順序) | bit pattern + 順序 同一 |

### 決定 7: branch / ADR 番号 / Codex session

ADR-0041 §決定 7 dashboard literal 整合:

- **ADR 番号: 0043** (= 軸 C 予約、 dashboard L40 確認済)
- **branch: `wip-axis-c-adpcmb`** (= 本拠地 `wip-pmddotnet-opnb-extension` HEAD `8d36113` から派生、 ADR-0041 §決定 3 worktree isolation)
- **Codex layer 1 session**: sub-agent 内自律取得 (= 各 commit 直前 review)
- **Codex layer 2 統合判断 session**: `019e3425-3327-74e1-95bc-461cc5d0af66` 流用 (= 軸間衝突 / 設計判断複数案発生時に主軸経由 escalate)
- **PR**: δ 完了時に `wip-axis-c-adpcmb` → `wip-pmddotnet-opnb-extension` 1 PR (= ADR-0041 §決定 3 stacked 禁止)

### 決定 8: 後続軸候補 / 関連別 ADR

ADR-0043 完了後 (= δ 後) の後続軸候補 (= ADR 番号 0045+ 候補):

- **`.PPC` format driver parse** (= 候補 ADR-0048): PMD V4.8s `.PPC` format runtime parse + multi-sample 切替 UI 経路
- **ADPCM-A / ADPCM-B sample selection routine 共有化** (= γ 完了後 refactor 判断、 早すぎる抽象化回避規律下)
- **WebApp ADPCM-B sample management UI** (= Phase 4 軸 D 候補、 yaml 自動生成)
- **delta-N envelope / LFO** (= 不要、 chip 仕様外、 scope-out 維持)

## scope-in / scope-out 明示 (= §決定 5 literal 再掲、 grep 用)

§決定 5 を参照。

## 完了判定

- 本 ADR (= ADR-0043) 起票 + commit + push (= `wip-axis-c-adpcmb` branch、 ADR-0041 §決定 3 規律)
- 軸 C α/β/γ/δ 全 sub 完了 (= 各 sub 完了判定通過、 §決定 1 table literal)
- ADPCM-A + ADPCM-B 同時演奏 `.MN` 楽曲 1 つ以上 MAME 再生確認 + audio gate (= δ 完了)

δ 完了時に本 ADR-0043 を Draft → Accepted へ移行する。

## Annex A: ADPCM-A native path との対称構造 reference

ADPCM-A 軸 (= ADR-0016 step 5-18 + ADR-0019 〜 ADR-0032) と ADPCM-B 軸の対称構造:

| 項目 | ADPCM-A 軸 (= step 5-18 完了) | ADPCM-B 軸 (= 本 ADR) |
|---|---|---|
| ch 数 | 6 ch (= L-Q part) | 1 ch (= J part) |
| sub-sprint 段数 | 5 段 α/β/γ/δ/ε (= ADR-0019) | 4 段 α/β/γ/δ (= ch 軸 step なし) |
| selection routine | `pmdneo_select_sample_pointer` (= routine 定義 L3067、 `adpcma_keyon_simple` からの call site L2784) | `pmdneo_select_adpcmb_sample_pointer` (= sub-sprint α で新規) |
| selection id | `sample_table_id` (= 0xFD32) | `sample_table_id` (= 0xFD32、 共用) |
| keyon entry | `adpcma_keyon_simple` (= L2768) | `adpcmb_keyon` (= L2692) |
| sample addr register | reg 0x10+ch/0x18+ch/0x20+ch/0x28+ch | reg 0x12/0x13/0x14/0x15 |
| keyon trigger register | reg 0x00 (= bit per ch) | reg 0x10 (= bit 0x80 single) |
| volume register | reg 0x08+ch (= 5 bit vol + bit 6-7 pan) | reg 0x1B (= 8 bit) |
| pan register | reg 0x08+ch bit 6-7 (= 内包) | reg 0x11 (= 独立 byte) |
| pitch control | none (= sample fixed rate playback) | reg 0x19/0x1A (= delta-N 16-bit、 chromatic table 経由) |
| sample asset format | `.PNE` (= ADPCM-A 専用、 ADR-0021) | yaml passthrough (= 本 ADR §決定 2) + 候補 `.PPC` (= 後続 ADR) |
| multi-table proof | ADR-0025 (= id=0x01) | 本 ADR γ |
| rhythm K/R compat | ADR-0026/0027/0028/0029/0030/0031 (= 6 drum 種) | scope-out (= ADPCM-B = melodic / pitched chromatic、 rhythm 用途なし) |

## Annex B: PMDDotNET `PCMDRV.cs` 流儀 reference

PMDDotNET (= GPL-3.0、 `vendor/PMDDotNET/PMDDotNETDriver/PCMDRV.cs` 1063 行) は **PC-98 OPNA ADPCM RAM 経路** (= 64KB ADPCM RAM、 sample bank 概念) を駆動。 PMDNEO は **YM2610(B) 内蔵 ADPCM-B** (= V-ROM 直結、 RAM 概念なし、 ROM addr 直接 register write) を駆動するため経路が異なる。

PMDDotNET PMDPPZ 流儀の主要 routine pattern (= 100-150 件 if 分岐 + wrapper、 `project_adr_0013_0014_path_switch.md` literal):

- `pcmmain` (= 演奏 main)
- `pcm_addr_set` (= sample addr 解決、 PMD `.PPC` directory 引き)
- `pcm_volset` / `pcm_panset` / `pcm_freq_set`
- `keyon` / `keyoff`

PMDNEO ADPCM-B 軸 (= 本 ADR) は **PMDPPZ 流儀の sample addr 解決経路 (= directory 引き)** を **本軸 scope-out** とし、 build-time `samples.inc` embed + symbol pointer table 経路で proof する (= §決定 2 + §決定 4)。 `.PPC` directory runtime parse は後続 ADR 候補 (= ADR-0048 候補) で扱う。

## Annex C: 軸間衝突確認 (= ADR-0041 §決定 1)

ADR-0041 §決定 1 (= 軸間衝突回避) に従い、 本軸 C と他軸 (= 軸 A / 軸 F / 軸 0) との触接面確認:

- **軸 A (= sample provenance β、 ADR-0042 予約)**: ADPCM-A 軸の sample provenance 改修、 ADPCM-B sample (= 本軸 C beat.wav / sample B1) と独立、 衝突なし
- **軸 F (= MML compiler 拡張、 ADR-0044 予約)**: MML 文法拡張 (= F-1 voice buffer / F-2 X/Y/Z / F-3 chip target flag)、 J part body 解釈は変更しない想定 (= 軸 F-2 X/Y/Z 拡張で J part 影響あれば軸 F prompt 内に明示)、 本軸 C で MML compiler touch なし
- **軸 0 (= orchestration setup、 ADR-0041)**: 規律確立 ADR、 driver / source touch なし、 衝突なし
- **driver SRAM 領域**: 0xFD32 `sample_table_id` 共用 (= ADPCM-A / ADPCM-B 同じ id で連動切替、 §決定 3)、 0xFD20-0xFD31 filename string 領域共用、 J part workarea (= partWork PART_PCM = 9) は ADPCM-A workarea (= partWork PART_ADPCMA1-6) と独立
- **共有 source file**: `src/driver/standalone_test.s` (= L2692 `adpcmb_keyon` + L2768 `adpcma_keyon_simple` 同 file、 commit 衝突 risk あり) → ADR-0041 §決定 3 「軸別 wip- branch 集約 1 軸 1 PR」 + sub-agent 内自律 commit で本拠地直接 commit 禁止 (= 主軸 merge orchestration 経由)

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

- **やりたいこと**: ADPCM-A 6 ch 軸が runtime-managed architecture (= sample 切替 / multi-table / id 連動) で完成したのに、 ADPCM-B 1 ch 軸は基礎実装 (= keyon/keyoff/note→pitch) のみで sample 切替経路がない、 これを対称構造で補う設計を確立する。
- **前提**: ADR-0016 step 4 で ADPCM-B 基礎実装完了済 (= adpcmb_keyon/keyoff/volset/panset/setfreq + chromatic table 24 byte + beat.wav 固定)、 ADR-0019 〜 ADR-0032 で ADPCM-A 軸 runtime-managed architecture 完成済、 ADR-0041 で Claude Code 併走運用規律確立。
- **やったこと**: ADR-0043 起票 = sub-sprint 4 段構成 (= α 設計 routine 新規 / β multi-sample fixture / γ id=0x01 切替 proof / δ 統合 audio gate)、 ADPCM-A 軸対称構造で sample selection arch 設計、 `.PPC` driver parse は本軸 scope-out + 後続 ADR 候補、 build-time `samples.inc` 拡張で multi-sample 実装、 `sample_table_id` (= 0xFD32) ADPCM-A 軸と共用。
- **結果**: doc-only ADR Draft 起票、 driver / runtime / vendor 完全不変、 後続 sub-sprint α/β/γ/δ 着手準備完了、 dashboard 更新は主軸経由 (= ADR-0041 §決定 9)。
- **解釈**: ADPCM-A native path 段階到達 pattern を ADPCM-B 軸に literal 適用、 「ch 軸不要」 を活かして 5 段 → 4 段に削減 + 早すぎる抽象化 (= ADPCM-A/B 共有 routine 化) は γ 完了後判断で防止。
- **次の step**: sub-sprint α 着手 = ADPCM-B selection routine `pmdneo_select_adpcmb_sample_pointer` 新規追加 + driver runtime に J part keyon 経路接続 (= `standalone_test.s` L2692 `adpcmb_keyon` 改修)、 別 sub-agent return で sub-agent C 後続 task として起動候補。 本 ADR-0043 起票 (= 軸 C α task) と sub-sprint α (= driver routine 新規追加) は別 step である点に注意。

---

## sub-sprint α 完了 (= 31st session、 主軸 fallback regime + Codex layer 1/2 経由)

### 実装 deliverable

`standalone_test.s` 改修 (= L2692 `adpcmb_keyon` + adpcmb_keyoff 直後 新規追加):

1. **`pmdneo_select_adpcmb_sample_pointer` 新規追加** (= ADPCM-A `pmdneo_select_sample_pointer` 対称構造):
   - 入力: A = voice index (= α 未使用、 β voice index table 化 拡張接続点)
   - 出力: DE = sample literal table pointer (= 4 byte: START_LSB/MSB + STOP_LSB/MSB)
   - DE = 0x0000 sentinel = unknown id (= caller silent reject)
   - `driver_pne_sample_table_id` (= 0xFD32) lookup = id=0 → beat / id!=0 → 0x0000

2. **`adpcmb_sample_beat` literal table 新規追加** (= 4 byte: BEAT_START_LSB/MSB + BEAT_STOP_LSB/MSB)

3. **`adpcmb_keyon` 改修**: reg 0x12-0x15 直接書き込み 4 ブロック → selector call + DE pointer 経由 4 byte read + register write。 byte-identical (= register 順序維持) 保証。

### 採用判断 経路 (= ADR-0041 §決定 4-2 layer 2 統合判断機能実証)

- **layer 2 採用** (= session 019e3b50-... 175s response、 配置 a + 即時実装 GO approve)
- **主軸 fallback regime 適用** (= sub-agent isolation worktree base ref 不一致再発、 軸 A β-1 と同 pattern)
- **Codex layer 1 代理 review** (= session 019e3b56-... 軸 C 既取得 流用)

### verify gate (= driver touch、 ADR-0041 §動作確認義務遵守、 31st session 主軸試行 全 PASS)

- **scripts/build-poc.sh 成功** (= sdasz80 + sdldz80 通過、 driver 改修 syntax + symbol resolution OK)
- **scripts/run-mame.sh + register trace = src/test-fixtures/step4/verify-j-part-fixture-driven.sh 全 PASS**:
  - fixture o4 c (= j-part-minimum.mml): wav sha256 `527587f8464705edfccabe822950b10d790c0d0f16b0a74bd7f0c6fc60272adc`、 reg 0x19=0x96 + 0x1A=0x6E (= 期待値一致) ✅
  - fixture o4 g (= j-part-g.mml): wav sha256 `08dbeab49251c4f36e322273f95132d0bbc27a31270da58f0532df45171bad5a`、 reg 0x19=0xB1 + 0x1A=0xA5 (= 期待値一致) ✅
  - **note 差分が wav に反映** (= pitch 差 OK、 timing artifact ではない)
- **既存 ADPCM-A native path regression なし** (= touch なし、 機械的保証)
- **既存 ADPCM-B Step 4 keyon/keyoff 動作維持** (= verify-j-part-fixture-driven 全 PASS で実証、 selector 経路化後も register byte-identical)
- **byte-identical 保証** (= register 順序 + 値 + delta-N 完全維持、 既存 fixture sha256 + 期待 register 値 完全一致)
- **CLAUDE.md §動作確認義務 + ADR-0043 §決定 6 規律 完全遵守** (= commit 前 verify gate 主軸試行 全項目 PASS)

### scope-out (= 7 必須条件 #7 厳守)

- β multi-sample fixture 拡張 (= 別 sub-sprint)
- γ runtime parser (= 別 sub-sprint)
- driver 他軸領域 (= ADPCM-A / FM/SSG 等) touch なし
- aesthetic / audio audition (= 越川氏判断 scope)

### sub-sprint chain 進捗 update

| sub-sprint | 状態 | commit |
|---|---|---|
| α | **完了** (= PR #22 MERGED) | 588a11c |
| β | **完了** (= 本 commit、 主軸 fallback regime + sub-agent 5 連続 isolation fail) | (= 本 commit hash) |
| γ | 未着手 | - |
| δ | 未着手 | - |

## sub-sprint β 完了 (= 31st session 末、 主軸 fallback regime + Codex layer 1/2 経由)

**実装内容** (= `src/driver/standalone_test.s` L2773-2828 周辺):

1. **voice index → sample id lookup table 新規追加**
   - `pmdneo_adpcmb_voice_to_sample_id_table` = 2 entry (= voice 0 → sample id 0、 voice 1 → sample id 1)
   - `pmdneo_adpcmb_voice_table_size .equ 2` literal

2. **selector `pmdneo_select_adpcmb_sample_pointer` 拡張**
   - 入力 A = voice index で range check (= `cp #pmdneo_adpcmb_voice_table_size` + `jr nc, adpcmb_select_sample_unknown_id`)
   - range PASS なら HL = table base + DE = A 経由で 1 byte sample id read
   - sample id dispatch (= `cp #0` + `cp #1` explicit if/jr 流儀、 ADPCM-A native path 同 pattern)
   - sample id 0 → `adpcmb_select_sample_a` → DE = `adpcmb_sample_beat`
   - sample id 1 → `adpcmb_select_sample_b` → DE = `adpcmb_sample_b_placeholder`
   - unknown → `adpcmb_select_sample_unknown_id` → DE = 0x0000 sentinel (= caller silent reject)

3. **sample B placeholder 新規追加**
   - `adpcmb_sample_b_placeholder:` `.db 0x00, 0x10, 0x00, 0x20` (= start=0x1000、 stop=0x2000 16 KB offset stub)
   - 後段 γ で samples.inc 生成経路 vromtool.py 拡張時に actual sample data 化
   - 本 β は selection 経路通過のみ register trace 実証 (= actual wav 再生は γ scope)

**caller 不変** (= adpcmb_keyon @ L2692 sub-sprint α 時点で既に A = PART_OFF_INSTRUMENT(ix) 渡し成立、 β 拡張で selector 内部のみ改修)

**verify gate**:
- `scripts/build-poc.sh` = sdasz80 + sdldz80 + vromtool.py 全 PASS
- `src/test-fixtures/step4/verify-j-part-fixture-driven.sh` = voice 0 (= sample A = beat) 経路 byte-identical 維持 (= o4 c + o4 g 両 fixture register match + wav sha256 既知値完全一致)

**主軸 fallback 経緯** (= ADR-0041 §決定 4-3 literal):
- sub-agent ID `a8a3165b9f70c1a21` で軸 C β isolation worktree 起動 (= 期待 wip-axis-c-adpcmb HEAD e1e8c83)
- preflight guard 5/6 即 fail (= worktree branch `worktree-agent-a8a3165b9f70c1a21` + HEAD `3ad1e232` で起動)
- **sub-agent isolation worktree base ref 不一致 5 連続実証** (= 軸 A β-1 + 軸 C 実装 α + 軸 A β-2 + 軸 C β = 4 → 5 回連続)
- guard 9 件機能完全継続実証 (= 越境ゼロ + driver / ADR touch 一切なし)
- 主軸 fallback (= ADR-0041 §決定 4-3 + Codex layer 2 既 approve pattern 踏襲) で wip-axis-c-beta-multi-sample 新 branch + driver/ADR Edit + build + verify + commit + PR + merge

**scope-out 維持**:
- γ: actual sample B wav data + samples.inc 生成経路 vromtool.py 拡張
- γ: runtime sample selection arch (= sample_table_id 経由 ADPCM-A 連動 dynamic lookup)
- γ: .PPC parser
- δ: integration + audio gate
- driver 他軸領域 (= ADPCM-A / FM/SSG)
- aesthetic / audio audition (= 越川氏判断 scope)
- vendor / main / wip-ir-trunk / MEMORY.md / CLAUDE.md / dashboard / 他軸専用 file
- 本拠地 absolute path edit (= preflight guard #7-#9 規律踏襲)

