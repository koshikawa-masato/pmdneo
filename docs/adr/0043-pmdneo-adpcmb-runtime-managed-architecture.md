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
| β | **完了** (= PR #28 MERGED) | dfc9774 |
| γ-1 | **完了** (= PR #30 MERGED) | 766fca4 |
| γ-2 | **完了** (= PR #31 MERGED) | 40d0a00 |
| **γ-3** | **完了** (= 本 commit、 ADPCM-A 軸独立性 trace、 verify only sub-sprint、 全 8 gate PASS、 driver source touch なし) | (= 本 commit hash) |
| γ (= 全体) | **complete** (= γ-1 + γ-2 + γ-3 全 sub-sprint 完了、 別 commit で宣言、 ADR-0043 Draft → Accepted 移行は δ 完了後待ち) | (= γ complete 宣言 commit hash) |
| δ | 未着手 | - (= statement audio gate、 越川氏 audition、 永久 user scope) |

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

## sub-sprint γ-1 完了 (= 32nd session、 主軸 + Codex layer 2 rescue 化 default + 主軸単独実装)

### 実装 deliverable

1. **`assets/pne/silence.wav` 新規追加** (= project-owned deterministic test sample)
   - format: 16-bit 8 kHz mono 0.1s 全 zero PCM (= 1644 bytes、 WAV header 44 + 16-bit × 800 samples)
   - sha256 `c726d333dd159a31423f3480dbb1c5c4a9dfcd30efe1f7e12ade390dc92e8908`
   - 生成: python3 wave module + struct.pack で deterministic 生成 (= 再現可能)
   - 配置: `assets/pne/silence.wav` (= project-owned、 vendor 不可触規律遵守)
   - 用途: voice 1 = sample B selection 経路 register trace 実証 (= aesthetic 対象外、 audition は selection proof のみ可)

2. **`assets/pne/samples-map-adpcmb.yaml` 拡張** (= ADR-0043 §決定 4 yaml + vromtool encode 経路採用)
   - 既存 beat entry 維持 + silence entry 末尾追加
   - vromtool 経由 `SILENCE_START_LSB/MSB/STOP_LSB/MSB` 自動生成 (= samples.inc に emit)
   - vromtool 自動 layout: beat 0x002a..0x00a8 直後 silence 0x00a9..0x00aa 配置 = 衝突自動回避

3. **`src/driver/standalone_test.s` 改修** (= placeholder → silence rename + literal addr 撤去)
   - L2820 周辺 `adpcmb_sample_b_placeholder: .db 0x00, 0x10, 0x00, 0x20` 削除
   - → `adpcmb_sample_silence: .db SILENCE_START_LSB, SILENCE_START_MSB, SILENCE_STOP_LSB, SILENCE_STOP_MSB` 置換
   - `adpcmb_select_sample_b:` 内 caller rename = `ld de, #adpcmb_sample_silence`
   - β literal addr 撤去 + generated symbol 参照経路統一 (= adpcmb_sample_beat と同形式)

4. **`src/test-fixtures/axis-c/gamma-1-silence-selection.mml` 新規追加** (= voice 1 fixture)
   - `J @1 o4 l1 c` = voice 1 (= PART_OFF_INSTRUMENT=1 → voice 1 → sample id 1 → silence)
   - FM voice template は step4 fixture 同形式 (= J part 単独 verify、 FM/SSG 干渉なし)

5. **`src/test-fixtures/axis-c/verify-gamma-1-silence-selection.sh` 新規追加** (= γ-1 専用 differential gate)
   - samples.inc に SILENCE_* 4 件 grep emit assert (= must-fix #3)
   - silence addr と beat addr differ assert (= 2 / 4 byte 差分実証)
   - run-mame --headless --wavwrite --trace 経由 ymfm-trace.tsv 取得
   - reg 0x12-0x15 = ADPCM-B start/stop addr LSB/MSB を last match で抽出 (= adpcmb_keyon 経路 write、 init 0x00 拾い回避)
   - SILENCE_* literal 値と一致 assert (= bash 3.2 互換 tr lowercase 経路)

### Codex layer 2 経由 採用判断 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化 適用、 user 介入なし non-stop 進行)

- **layer 2 round 1**: 「軸 C γ sprint 境界 a/b/c 案 + actual sample B 素材選定」 review → **escalate** (= aesthetic 永久 user scope) + 推奨「project-owned deterministic test sample」 (= user 介入回避経路提示)
- **layer 2 round 2**: 「deterministic test sample 経路 X/Y/Z 案 + 主軸推奨 X silence」 re-review → **revise** (= must-fix 3 件) + 案 X 採用根拠 approve (= user escalate 不要、 案 Y vendor reject 確定、 案 Z encoder scope 膨張 reject)
- **layer 2 round 3**: 「must-fix 3 件解消 plan v2」 review → **revise** (= must-fix 3 件 = voice 1 fixture + verify gate 分離 + samples.inc emit assert) + 全 must-fix 解消経路提示
- **user 介入回避経路**: user 明示指示「Codex に判断を全て委ねる + non-stop GO」 下、 主軸が plan v2 must-fix 反映で固定 + 直接実装着手 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化 適用、 layer 2 revise→主軸修正→実装 path)

### verify gate (= driver touch、 ADR-0041 §動作確認義務遵守、 32nd session 主軸試行 全 PASS)

- **scripts/build-poc.sh 成功** (= sdasz80 + sdldz80 + vromtool 全 PASS、 samples.inc 生成成功)
- **samples.inc emit 確認**: SILENCE_START_LSB=0xa9 / MSB=0x00 / STOP_LSB=0xaa / MSB=0x00 (= beat 0x002a-0x00a8 直後 0x00a9-0x00aa 配置、 vromtool 自動衝突回避)
- **γ-1 専用 differential gate** = `src/test-fixtures/axis-c/verify-gamma-1-silence-selection.sh` 全 PASS:
  - samples.inc に SILENCE_* 4 件 emit OK
  - silence (0xa9/0x00/0xaa/0x00) vs beat (0x2a/0x00/0xa8/0x00) differ OK (= 2 / 4 byte)
  - run-mame trace reg 0x12=0xa9 / 0x13=0x00 / 0x14=0xaa / 0x15=0x00 全 SILENCE_* 一致 OK
- **step4 voice 0 byte-identical regression** = `src/test-fixtures/step4/verify-j-part-fixture-driven.sh` 全 PASS:
  - fixture o4 c wav sha256 `527587f8464705edfccabe822950b10d790c0d0f16b0a74bd7f0c6fc60272adc` (= 既知値完全一致)
  - fixture o4 g wav sha256 `08dbeab49251c4f36e322273f95132d0bbc27a31270da58f0532df45171bad5a` (= 既知値完全一致)
  - reg 0x19/0x1A 期待値完全一致 (= voice 0 = beat 経路 byte-identical 維持)
- **既存 ADPCM-A native path regression なし** (= touch なし、 機械的保証)
- **CLAUDE.md §動作確認義務 + ADR-0043 §決定 6 規律 完全遵守** (= commit 前 verify gate 両 gate 全項目 PASS)

### must-fix 3 件解消 literal 経路 (= Codex layer 2 round 3 revise must-fix 完全反映)

| # | must-fix 内容 | 解消経路 |
|---|---|---|
| 1 | voice 1 fixture 明記 (= 既存 step4 は voice 指定なし default voice 0 = beat、 sample B 経路未検証) | `gamma-1-silence-selection.mml` `J @1 o4 l1 c` 新規追加 = voice 1 = sample id 1 = adpcmb_sample_silence 経路 register trace 実証 |
| 2 | verify gate 分離 (= 既存 step4 byte-identical regression と γ-1 differential gate を分離) | `src/test-fixtures/axis-c/verify-gamma-1-silence-selection.sh` 新規 = step4 と独立、 ADR-0043 §決定 6 「`<sub>-<purpose>.mml` + verify script 自動 PASS 化」 遵守 |
| 3 | samples.inc emit assert (= SILENCE_* 4 件 generated symbol 破損検出) | verify script step「samples.inc に SILENCE_* generated symbol emit assert」 = grep + awk で SILENCE_START_LSB/MSB/STOP_LSB/MSB 4 件存在確認 + 値抽出 |

### 共通規律遵守確認 (= ADR-0043 §決定 1 共通規律 + ADR-0041 §決定 4 規律)

- **各 sub = 1 commit + 1 push** (= γ-1 単独 commit + push) ✅
- **primary gate = ADPCM-B register trace / ymfm-trace** (= reg 0x12-0x15 SILENCE_* 一致 last match) ✅
- **wav sha256 = timing-sensitive reference** (= step4 voice 0 sha256 既知値一致は byte-identical 確認、 γ-1 voice 1 wav 自体は silence で primary 判定にしない) ✅
- **各 commit 前に「平易な日本語で説明」 + user レビュー待ち** (= 本 ADR § 平易日本語要約 + commit message に literal、 ただし user 「non-stop GO」 指示下で都度確認は省略) ✅
- **driver / runtime layer touch commit = MAME 起動確認義務** (= scripts/run-mame.sh 経由 trace 取得 + reg 値確認、 audio audition は γ-1 silence sample のため δ 統合 audio gate に集約) ✅
- **ADR-0041 §決定 4 規律 = 3 重 zero-trust review** (= layer 1 sub-agent 経由なし、 主軸単独実装 + 主軸自己 verify + Codex layer 2 計 3 round 全段階確認、 ADR-0041 §決定 4-3 fallback 経路) ✅

### scope-out 維持 (= ADR-0043 §決定 5 + ADR-0041 §forbidden write set)

- γ-2 sample_table_id integration (= 0xFD32 lookup + ADPCM-A 連動 切替 proof、 別 sub-sprint)
- δ integration + audio gate (= 越川氏 final audition、 永久 user scope)
- `.PPC` format driver parse (= 別 ADR ADR-0048 候補)
- driver 他軸領域 (= ADPCM-A / FM/SSG / IR runtime) touch なし
- aesthetic / audio audition refinement (= 越川氏判断、 永久 user scope、 silence sample は audition 対象外 = engineering test sample)
- vendor 配下 touch なし (= silence.wav は project-owned `assets/pne/` 配置)
- 未追跡 vendor wav 3 件 (= lefthook/lightbulbbreaking/woosh、 軸 A scope、 触らない)
- main 直接 push / wip-pmddotnet-opnb-extension 直接 commit (= ADR-0041 §決定 3、 wip-axis-c-gamma-1-actual-silence branch 経由)
- MEMORY.md / CLAUDE.md / 他軸専用 file touch なし
- 本拠地 absolute path edit (= preflight guard #7-#9 規律踏襲)

## sub-sprint γ-2 完了 (= 32nd session、 主軸 + Codex layer 2 rescue 化 default + hybrid 経路採用 + unexpected finding 反映)

### 実装 deliverable

1. **`assets/pne/silence_b.wav` 新規追加** (= project-owned 3rd deterministic test sample)
   - format: 16-bit 8 kHz mono 0.2s 全 zero PCM (= 3244 bytes、 silence 0.1s と異なる長さ = vromtool 自動別 addr 配置確保)
   - sha256 `4e9cc5bbce2136140462d11c5fec6e6c1ed10602c2bca874dbb58e7b9be21092`
   - 配置: `assets/pne/silence_b.wav` (= project-owned、 vendor 不可触規律遵守)

2. **`assets/pne/samples-map-adpcmb.yaml` 拡張** (= ADR-0043 §決定 4 「3rd sample entry + adpcmb_sample_ptr_table_b 新設」 literal 整合)
   - 既存 beat + silence entry 維持 + silence_b entry 末尾追加 (= 3rd entry)
   - vromtool 経由 `SILENCE_B_START_LSB/MSB/STOP_LSB/MSB` 自動生成 (= samples.inc 0xab/0x00/0xae/0x00、 silence 0xa9-0xaa 直後配置)

3. **`src/driver/standalone_test.s` 改修** (= 0xFD32 lookup + table-of-tables dispatch、 ADR-0043 §決定 3 + §決定 4 整合)
   - L2773-2830 周辺 pmdneo_select_adpcmb_sample_pointer 全面改修:
     - 冒頭で `ld a, (driver_pne_sample_table_id)` + `cp #0x00/#0x01` dispatch
     - id=0x00 → adpcmb_select_table_a (= 既存 voice → sample id table A → beat/silence)
     - id=0x01 → adpcmb_select_table_b (= 新設 voice → sample id table B → silence_b)
     - id>=0x02 → adpcmb_select_sample_unknown_id (= 既存 sentinel 経路統合)
   - 新規 routine: `adpcmb_select_sample_silence_b` (= DE = adpcmb_sample_silence_b)
   - 新規 table: `pmdneo_adpcmb_voice_to_sample_id_table_b` (= 2 entry、 voice 0/1 → sample id 2 = silence_b)
   - 新規 literal table: `adpcmb_sample_silence_b` (= 4 byte `SILENCE_B_START_LSB/MSB/STOP_LSB/MSB`)
   - 新規 symbol: `pmdneo_adpcmb_voice_table_size_b .equ 2`
   - B register 使用 = voice index 退避経路 (= sample_table_id lookup で A clobber 対策)

4. **`src/test-fixtures/axis-c/verify-gamma-2-multi-table.sh` 新規追加** (= γ-2 専用 differential gate、 hybrid 経路、 6 gate)
   - **hybrid 経路** (= Codex layer 2 revise must-fix 反映):
     - J body: `MML_INPUTS="$TMPDIR/j-body.mml,test02.mml"` env (= 自前 compile.py 経路、 step4 既動作 pattern 流用)
     - carrier: `PMDDOTNET_MML=<step5/step11 fixture>` + `PMDDOTNET_MODE=B` + `PMDNEO_USE_PMDDOTNET=1` env (= 改造 PMDDotNET 経路、 #PNEFile filename embed → resolver → 0xFD32 設定)
   - **既存 fixture 流用** (= 新規 fixture 不要、 build pipeline 既動作経路 維持):
     - J body: `src/test-fixtures/step4/j-part-minimum.mml` (= 既存 J only fixture)
     - zero carrier: `src/test-fixtures/step5/l-q-rhythm-song.mml` (= 既存 #PNEFile step5.PNE)
     - one carrier: `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= 既存 #PNEFile step5b.PNE)
   - 6 gate: build PASS (gate 1/3) + 0xFD32 0x00/0x01 resolver assert (gate 2/4) + reg 0x12-0x15 BEAT vs SILENCE_B differ literal (gate 5) + delta-N/vol/pan/keyon identical (gate 6)

### unexpected finding 反映 (= ADR-0041 §決定 5 escalation type = unexpected_finding)

**finding**: 改造 PMDDotNET /B mode で L-Q ADPCM-A + J ADPCM-B 同時含む MML を compile すると、 .MN binary に J part body が emit されない (= L-Q part 5 つ + part offset table + filename + Title/Memo Shift-JIS encoded comment のみ)。 PMDDotNET log は「Part J Length : 96」 と表示するが、 .MN binary に J body bytecode emit なし。

**Codex layer 2 round 3 escalate review 結果**:
- 案 X (= γ-2 fixture J only 縮退、 ADPCM-A 独立性 trace γ-3 defer) は不採用 = `compile.py` は #PNEFile を resolver に流さない (= src/tools/pmd-mml/compile.py L525 # 以降コメント落とし)
- 案 Y (= compile.py + driver hard-code sample_table_id) は must-fix #3 違反 risk
- 案 Z (= PMDDotNET J emit bug 修正) は ADR-0044 §軸 F 全体 scope-out 確定済 (= F-2-A defer + F-2-B 軸 B 譲渡) と矛盾
- **採用案 = hybrid 経路** = J body compile.py + carrier PMDDotNET .MN 同時 build (= build-poc.sh L107 compile.py + L163 PMDDotNET .MN carrier 経路、 両経路同 driver build 内共存)、 ADPCM-A 独立性 trace は γ-3 deferral 明示

**γ-3 起票方針** (= ADR-0043 §sub-sprint chain 拡張): J + L-Q 同時 fixture でADPCM-A regs byte-identical (= 軸間独立性 副作用なし) trace 実装、 PMDDotNET /B mode J emit 修正は scope-out 維持 (= 別 ADR 候補 or 軸 F 内 sub-軸 として将来 sprint)、 γ 全体 complete 宣言は γ-3 完了後とする (= ADR-0041 §決定 5 段階的完了 pattern)。

### Codex layer 2 経由 採用判断 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化 適用、 user 介入なし non-stop 進行)

- **layer 2 round 1**: 「γ-2 sprint 境界 a/b/c 案 + 主軸推奨 案 c」 review → **revise** (= 案 c reject、 修正案 a 採用 + must-fix 5 件)
- **layer 2 round 2**: 「γ-2 unexpected finding (= PMDDotNET J emit 不在) escalate + 解決方針 X/Y/Z」 review → **revise** (= 案 X 不採用、 hybrid 経路採用 + must-fix 4 件 = compile.py 単独 #PNEFile 不流通 / hybrid 必須 / J-only PMDDotNET 第一案 reject / 0xFD32 carrier gate 追加)
- **主軸 hybrid 経路実装**: gamma-2 fixture 2 件削除 (= 不要) + verify script hybrid 経路改修 (= MML_INPUTS j-body + PMDDOTNET_MML carrier) + 既存 step4/step5/step11 fixture 流用 + 全 6 gate 全 PASS

### verify gate (= driver touch、 ADR-0041 §動作確認義務遵守、 32nd session 主軸試行 全 PASS)

- **scripts/build-poc.sh 成功** (= sdasz80 + sdldz80 + vromtool 全 PASS、 hybrid 経路 (= MML_INPUTS + PMDDOTNET_MML) 同時駆動)
- **samples.inc emit 確認**: SILENCE_B_START_LSB=0xab / MSB=0x00 / STOP_LSB=0xae / MSB=0x00 (= silence 0xa9-0xaa 直後配置、 vromtool 自動衝突回避)
- **γ-2 専用 differential gate** = `src/test-fixtures/axis-c/verify-gamma-2-multi-table.sh` 全 6 gate PASS:
  - 0xFD32 = 0x00 (step5.PNE) / 0x01 (step5b.PNE) 完全 idempotent (= 6 件各 unique value)
  - reg 0x12-0x15 zero/one differ literal: zero (0x2a/0x00/0xa8/0x00) vs one (0xab/0x00/0xae/0x00) 完全一致
  - delta-N/vol/pan/keyon identical: 0x10=0x00 / 0x11=0xc0 / 0x19=0x96 / 0x1A=0x6e / 0x1B=0xff 全 5 reg identical (= sample addr のみ differ proof)
- **step4 voice 0 byte-identical regression** = `src/test-fixtures/step4/verify-j-part-fixture-driven.sh` 全 PASS:
  - fixture o4 c reg 0x19=0x96 / 0x1A=0x6E 期待値完全一致
  - fixture o4 g reg 0x19=0xB1 / 0x1A=0xA5 期待値完全一致
  - wav sha256 異なる (= note 差分 OK、 silence_b 投入で samples.inc layout shift 反映)
- **γ-1 voice 1 differential gate regression** = `src/test-fixtures/axis-c/verify-gamma-1-silence-selection.sh` 全 PASS:
  - samples.inc SILENCE_START_LSB=0xa9 emit 維持
  - reg 0x12-0x15 全 SILENCE_* literal 値完全一致 (= silence_b 投入で silence 値変化なし、 vromtool 安定 layout 確認)
- **既存 ADPCM-A native path regression なし** (= driver pmdneo_select_sample_pointer touch なし、 機械的保証)
- **CLAUDE.md §動作確認義務 + ADR-0043 §決定 6 規律 完全遵守** (= commit 前 verify gate 全 PASS)

### must-fix 5 件解消 literal 経路 (= Codex layer 2 round 1 revise + round 2 escalate→revise must-fix 完全反映)

| # | must-fix 内容 | 解消経路 |
|---|---|---|
| 1 | 案 c は γ-2 complete 宣言不可 (= ADPCM-A 独立性 trace defer 時 partial 扱い必要) | γ-2 partial 完了宣言 + γ-3 起票 (= ADR-0043 §sub-sprint chain γ-3 追加、 ADPCM-A 独立性 trace 別 sub-sprint 化、 γ complete 宣言は γ-3 完了後) |
| 2 | 案 c の「id=0x01 → silence reuse」 ADR §決定 4 不整合 | 採用 = 3rd sample entry silence_b 新規 + adpcmb_sample_ptr_table_b 新設 + table B namespace (= sample id 2) 分離 (= ADR §決定 4 literal 完全整合) |
| 3 | sample_table_id 設定は driver hard-code / sed を第一案にしない | 採用 = #PNEFile resolver 経路 (= step5.PNE / step5b.PNE) literal 流用、 driver hard-code / sed 経路使用なし |
| 4 | verify gate は reg 0x12-0x15 だけでは不足 | 採用 = 6 gate 構成 = 0xFD32 = 0x00/0x01 (gate 2/4) + reg 0x12-0x15 differ literal (gate 5) + delta-N/vol/pan/keyon identical (gate 6) |
| 5 | ground truth path 誤記 (= src/sound/standalone_test.s 不存在) | 解消 = 全 doc/PR description で `src/driver/standalone_test.s` (= 正) literal 明記 (= 本 ADR + PR description) |

### unexpected finding round 2 must-fix 4 件解消 literal 経路

| # | must-fix 内容 | 解消経路 |
|---|---|---|
| 1 | 案 X (= compile.py 単独 + #PNEFile resolver) は成立しない (= L525 # 以降コメント落とし) | hybrid 経路採用 = J body compile.py + carrier PMDDotNET .MN 同時 build |
| 2 | hybrid 経路 (= J body compile.py + carrier PMDDotNET .MN) 採用必須 | verify script L91 `MML_INPUTS="$TMPDIR/j-body.mml,test02.mml" PMDDOTNET_MML="$ZERO_CARRIER_MML" PMDDOTNET_MODE=B PMDNEO_USE_PMDDOTNET=1` 経路 literal 実装 |
| 3 | PMDDotNET J-only 代替は第一案にしない (= driver J part は compile.py song_table 経路) | J body は j-part-minimum.mml 流用 = compile.py 経路、 carrier は L-Q only step5/step11 fixture 流用 = PMDDotNET 経路 |
| 4 | verify gate に 0xFD32 carrier gate 追加 (= step5.PNE → 0x00、 step5b.PNE → 0x01、 ADPCM-B reg differ、 ADPCM-A keyon carrier rest のみ) | 6 gate 構成 = gate 2/4 0xFD32 assert + gate 5 reg differ + gate 6 ADPCM-B non-addr identical |

### 共通規律遵守確認 (= ADR-0043 §決定 1 共通規律 + ADR-0041 §決定 4 規律)

- **各 sub = 1 commit + 1 push** (= γ-2 単独 commit + push) ✅
- **primary gate = ADPCM-B register trace / ymfm-trace** (= reg 0x12-0x15 BEAT/SILENCE_B literal differ + non-addr identical) ✅
- **wav sha256 = timing-sensitive reference** (= 越川氏 audition は δ scope、 silence sample は audition 対象外 engineering test sample) ✅
- **各 commit 前に「平易な日本語で説明」 + user レビュー待ち** (= 本 ADR § 平易日本語要約 + commit message に literal、 user 「non-stop GO」 指示下で都度確認は省略) ✅
- **driver / runtime layer touch commit = MAME 起動確認義務** (= scripts/run-mame.sh 経由 trace 取得 + reg 値確認、 audio audition は γ-2 silence sample のため δ 統合 audio gate に集約) ✅
- **ADR-0041 §決定 4 規律 = 3 重 zero-trust review** (= layer 1 sub-agent 起動なし、 主軸単独実装 + 主軸自己 verify + Codex layer 2 計 2 round revise→hybrid 経路採用、 ADR-0041 §決定 4-3 fallback 経路) ✅

### scope-out 維持 (= ADR-0043 §決定 5 + ADR-0041 §forbidden write set + γ-3 deferral 追加)

- **γ-3 ADPCM-A 独立性 trace** (= J + L-Q 同時 fixture、 unexpected finding 反映で deferral、 別 sub-sprint 別 PR、 PMDDotNET /B mode J emit 修正は scope-out 維持)
- δ statement audio gate (= 越川氏 final audition、 永久 user scope)
- `.PPC` format driver parse (= 別 ADR ADR-0048 候補)
- 改造 PMDDotNET /B mode J emit 不在 bug 修正 (= 軸 F 範疇、 ADR-0044 §軸 F 全体 scope-out 確定済と矛盾なし、 別 ADR 候補 or 将来 sprint defer)
- driver 他軸領域 (= ADPCM-A / FM/SSG / IR runtime) touch なし
- aesthetic / audio audition refinement (= 永久 user scope、 silence_b sample は engineering test sample で audition 対象外)
- vendor 配下 touch なし (= silence_b.wav は project-owned `assets/pne/` 配置)
- 未追跡 vendor wav 3 件 (= lefthook/lightbulbbreaking/woosh、 軸 A scope、 触らない)
- main 直接 push / wip-pmddotnet-opnb-extension 直接 commit (= ADR-0041 §決定 3、 wip-axis-c-gamma-2-multi-table branch 経由)
- MEMORY.md / CLAUDE.md / 他軸専用 file touch なし
- 本拠地 absolute path edit (= preflight guard #7-#9 規律踏襲)
- γ-2 fixture 2 件新規作成 (= unused、 hybrid 経路で既存 fixture 流用、 commit 含めず) = `src/test-fixtures/axis-c/gamma-2-multi-table-id-zero.mml` + `-one.mml` 作成 → 削除済、 hybrid 経路採用で不要化

## sub-sprint γ-3 完了 (= 32nd session、 主軸 + Codex layer 2 round 1 approve + verify only sub-sprint)

### 実装 deliverable

1. **`src/test-fixtures/axis-c/verify-gamma-3-axis-independence.sh` 新規追加** (= 8 gate、 γ-2 hybrid 経路完全踏襲 + ADPCM-A 観測 2 gate 拡張)
   - **gate 1-6**: γ-2 verify gate 完全踏襲 (= hybrid build + 0xFD32 resolver + ADPCM-B sample 切替 + ADPCM-B non-addr identical)
   - **gate 7**: ADPCM-A M-Q ch (= ch 1-5) addr regs byte-identical (= 20 reg = port B reg 0x11-0x15 / 0x19-0x1D / 0x21-0x25 / 0x29-0x2D、 step11 verify-step11-multi-table.sh gate 6 pattern 完全踏襲)
   - **gate 8**: ADPCM-A keyon count identical (= port B reg 0x00 = ADPCM-A keyon control、 step11 gate 7 pattern 完全踏襲、 silent ではない literal proof)
   - L ch (= ch 0 = reg 0x10/0x18/0x20/0x28) は gate 7 対象外 (= step5/step5b 切替で ADPCM-A 軸 sample_table_id 切替が L ch differ = ADR-0025 既実証で意図的、 γ-3 は「ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ」 proof scope に純化)
   - bash 3.2 互換 (= γ-1 verify 同 pattern、 tr lowercase + last match awk)

### driver source touch なし (= verify only sub-sprint)

γ-3 は γ-2 完了状態 driver で十分 (= Codex layer 2 approve item 6 literal)。 `src/driver/standalone_test.s` + `pmdneo_select_adpcmb_sample_pointer` + table A/B + 0xFD32 lookup は γ-2 で完成、 γ-3 では「同 driver の ADPCM-B 軸切替が ADPCM-A 軸 (= M-Q ch) に副作用なし」 を verify trace で proof するのみ。

### Codex layer 2 経由 採用判断 (= ADR-0041 §決定 4-2 Codex rescue 化 default 永続化 適用、 user 介入なし non-stop 進行)

- **layer 2 round 1**: 「γ-3 sprint 境界 案 A/B/C + 主軸推奨 案 A + 8 gate 構成 + driver touch なし」 review → **approve** (全 8 項目 OK 判定、 ただし gate 7 表記修正 = M-Q ch 1-5 のみ byte-identical = L ch 含む 6 ch 全部ではない)
- gate 7 表記 main 改善反映 = verify script comment + ADR doc + dashboard literal で「M-Q ch (= ch 1-5、 20 reg) byte-identical」 + 「L ch は step5/step5b 切替で differ 既実証 = gate 7 対象外」 を明示

### verify gate (= driver touch なし、 verify only sub-sprint、 32nd session 主軸試行 全 PASS)

- **scripts/build-poc.sh 成功** (= hybrid 経路 (= MML_INPUTS + PMDDOTNET_MML) 同時駆動成功、 γ-2 と同 pattern)
- **γ-3 専用 differential gate** = `src/test-fixtures/axis-c/verify-gamma-3-axis-independence.sh` 全 8 gate PASS:
  - gate 1-6 = γ-2 6 gate 完全踏襲全 PASS (= 0xFD32 0x00/0x01 + reg 0x12-0x15 BEAT/SILENCE_B literal differ + delta-N/vol/pan/keyon identical)
  - gate 7 = ADPCM-A M-Q ch addr regs identical (= 20 reg × ch 1-5 で 0 件 differ、 ADPCM-B 軸 → ADPCM-A 非対象 ch 副作用ゼロ proof)
  - gate 8 = ADPCM-A keyon count identical 41 (= 同回数鳴る、 silent ではない literal proof)

### ADR-0043 §決定 1 γ 完全充足 literal 整理

ADR-0043 §決定 1 γ literal:
> γ | sample_table_id integration (= ADPCM-A multi-table proof pattern 踏襲、 J part が sample_table_id に応じて ADPCM-B sample 切替) | id=0x00 / id=0x01 fixture 比較で sample 切替 observable proof、 ADPCM-A 軸との独立性 (= ADPCM-A 側 register write 不変) trace 確認

| γ literal 要素 | γ-1 充足 | γ-2 充足 | γ-3 充足 |
|---|---|---|---|
| sample_table_id integration | partial (= actual silence sample 投入) | **完全充足** (= 0xFD32 lookup + table B 新設) | - |
| ADPCM-A multi-table proof pattern 踏襲 | - | **完全充足** (= ADR-0023/0024/0025 pattern 流用) | - |
| J part が sample_table_id に応じて ADPCM-B sample 切替 | - | **完全充足** (= step5.PNE → beat / step5b.PNE → silence_b literal proof) | - |
| id=0x00 / id=0x01 fixture 比較で sample 切替 observable proof | - | **完全充足** (= γ-2 gate 5 BEAT vs SILENCE_B literal differ) | - |
| **ADPCM-A 軸との独立性 (= ADPCM-A 側 register write 不変) trace 確認** | - | defer | **完全充足** (= γ-3 gate 7 M-Q ch 20 reg byte-identical + gate 8 keyon count identical) |

γ 全体 = γ-1 + γ-2 + γ-3 で literal 完全充足、 段階的完了 pattern (= ADR-0041 §決定 5) 機能完全実証。

### must-fix 解消 literal 経路 (= Codex layer 2 round 1 approve、 修正のみ 1 件)

| # | 内容 | 解消経路 |
|---|---|---|
| 1 | gate 7 表記 scope 誤記 (= 「全 6 ch / 24 reg」 ではない、 M-Q ch 1-5 / 20 reg が正) | verify script gate 7 comment + ADR doc literal 修正 (= M-Q ch のみ、 L ch は ADR-0025 既実証で意図的 differ scope-out) |

### 共通規律遵守確認 (= ADR-0043 §決定 1 共通規律 + ADR-0041 §決定 4 規律)

- **各 sub = 1 commit + 1 push** (= γ-3 verify + γ complete 宣言 = 同 PR 2 commit、 Codex layer 2 approve item 7 literal) ✅
- **primary gate = ADPCM-B register trace / ymfm-trace** (= γ-3 では ADPCM-A M-Q ch + keyon count 追加観測) ✅
- **wav sha256 = timing-sensitive reference** (= δ scope) ✅
- **各 commit 前に「平易な日本語で説明」 + user レビュー待ち** (= user 「γ-3 まで Codex 委譲で non-stop 進めて」 指示下で都度確認は省略) ✅
- **driver / runtime layer touch commit = MAME 起動確認義務** (= γ-3 は driver touch なし verify only、 MAME 起動 + reg 観測 + trace assert) ✅
- **ADR-0041 §決定 4 規律 = 3 重 zero-trust review** (= 主軸単独実装 + 主軸自己 verify + Codex layer 2 round 1 approve) ✅

### scope-out 維持 (= ADR-0043 §決定 5 + ADR-0041 §forbidden write set)

- δ statement audio gate (= 越川氏 final audition、 永久 user scope、 γ 全体 complete 宣言後の別 sub-sprint)
- `.PPC` format driver parse (= 別 ADR ADR-0048 候補)
- 改造 PMDDotNET /B mode J emit 不在 bug 修正 (= ADR-0044 §軸 F 全体 scope-out 確定済、 将来 sprint)
- driver 他軸領域 (= ADPCM-A / FM/SSG / IR runtime) touch なし
- driver source touch なし (= γ-3 verify only sub-sprint)
- aesthetic / audio audition refinement (= 永久 user scope)
- vendor 配下 touch なし
- 未追跡 vendor wav 3 件 (= lefthook/lightbulbbreaking/woosh、 軸 A scope、 触らない)
- main 直接 push / wip-pmddotnet-opnb-extension 直接 commit (= ADR-0041 §決定 3、 wip-axis-c-gamma-3-axis-independence branch 経由)
- MEMORY.md / CLAUDE.md / 他軸専用 file touch なし
- ADR-0043 Draft → Accepted 移行 (= Codex layer 2 approve item 7 literal「δ 完了時が安全」、 γ-3 では「γ complete / δ 着手可能」 まで)

## γ 全体 complete 宣言 (= γ-1 + γ-2 + γ-3 全 sub-sprint 完了、 32nd session 末)

ADR-0043 §sub-sprint chain γ 全体 = γ-1 (= actual silence sample) + γ-2 (= sample_table_id integration + table B) + γ-3 (= ADPCM-A 軸独立性 trace) 全 sub-sprint 完了で、 ADR-0043 §決定 1 γ literal 完全充足。

| sub-sprint | 完了 commit | PR | verify gate |
|---|---|---|---|
| γ-1 | 766fca4 | #30 MERGED beee2b14 | 2 gate (= γ-1 differential + step4 regression) |
| γ-2 | 40d0a00 | #31 MERGED 7bd724bc | 8 gate (= γ-2 6 gate + step4 regression + γ-1 regression) |
| γ-3 | (= 本 PR γ-3 verify commit hash) | (= 本 PR) | 8 gate (= γ-3 gate 1-8) |
| γ complete 宣言 | (= 本 PR γ complete 別 commit hash) | (= 本 PR、 別 commit) | n/a (= 宣言のみ) |

**次の step**: δ statement audio gate (= 越川氏 audition、 永久 user scope) → δ 完了後 ADR-0043 Draft → Accepted 移行 (= Codex layer 2 round 1 approve item 7 literal「δ 完了時が安全」)。

