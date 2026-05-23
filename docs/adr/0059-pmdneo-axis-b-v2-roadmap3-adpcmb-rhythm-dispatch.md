# ADR-0059: PMDNEO 軸 B v2 driver production-ready roadmap ③ = ADPCM-B/rhythm 実 dispatch

- 状態: **Draft** (= 2026-05-23 39th session 軸 B production-ready roadmap ③ α 起票 doc-only filing。 ADR-0056 §決定 4 roadmap ③ literal 後続実装 ADR。 ADR-0058 Accepted (= roadmap ② 完了) 後の次フェーズ = ADPCM-B / rhythm 実 dispatch (= 接続点 stub marker proof → 既存 routine 本体不可触 call へ昇格)。 6 sub-sprint α/β/γ/δ/ε/ζ 構成、 production-ready 全体達成宣言ではない、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0056** (= 軸 B v2 driver production-ready 化 選定 ADR、 Accepted、 §決定 4 roadmap ③ = ADPCM-B/rhythm 実 dispatch。 本 ADR-0059 が roadmap ③ の実装 ADR)
  - **ADR-0058** (= roadmap ② song parse + v2 per-part dispatch loop + IRQ tick 連携、 Accepted。 v2 PartWork compact slot (= 9 part、 12 byte/slot) + v2 song parse + dispatch wiring + IRQ tick 連携 + tempo accumulator を確立。 **本 ADR-0059 はこの dispatch wiring に KIND=2 (ADPCM-B) + KIND=3 (rhythm) を追加 + slot 数 9 → 11 拡張**)
  - **ADR-0057** (= roadmap ① FM/SSG 実音、 Accepted。 v2 FM/SSG dispatcher 実音化済、 本 ADR では完全不可触保護)
  - **ADR-0055** (= 軸 B 実装 sprint 4 = δ-4 v2 main loop 軸 C/G/rhythm 接続点定義、 Accepted。 §決定 2 stub marker proof = 既存 軸 C/rhythm routine は call しない / 実 dispatch は後続 future。 **本 ADR-0059 がこの「後続 future」 を受けて stub marker → 既存 routine 本体不可触 call へ昇格**、 ただし ADR-0055 stub marker write (= 0xFD3C ← 0x09 / 0xFD3D ← 0x0A) は regression 用に維持)
  - **ADR-0043** (= 軸 C ADPCM-B runtime-managed architecture、 Accepted。 `adpcmb_keyon` (= standalone_test.s L3875) + ADPCMB_DRV.inc 全部 + voice index table + sample pointer selector 全部 **完全不可触**)
  - **ADR-0048** (= 軸 G ADPCM 動的供給、 Draft + ε partial complete + ζ 未着手、 **完全不可触** = `driver_pne_sample_table_id` bit7=0 default 維持で軸 G 経路を侵入させない、 軸 G dynamic supply 依存整理は roadmap ④)
  - **ADR-0026〜0031** (= rhythm 実装、 Accepted。 `pmdneo_rhythm_event_trigger` (= L4616) + `_rhythm_event_*_trigger` (= b/s/c/h/t/i) + `rhythm_main` + KR_STUB.inc + `adpcma_sample_*` (= driver-embedded fixture) 全部 **完全不可触**)
  - **ADR-0049 / ADR-0050 / ADR-0051 / ADR-0052 / ADR-0053 / ADR-0054** (= mute / fade-out / SSG tone-enable / v2 entry / SRAM placement / F-2-B、 Accepted、 **本 ADR で routine body 完全不可触保護**)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 長時間 verify は polling monitor 併走 + hang 判定)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow silent bug guard)
  - `feedback_sdas_if_no_value_comparison.md` (= sdasz80 `.if` 値比較禁止、 binary toggle `.if FLAG` のみ許容)
  - `feedback_parallelize_with_subagents_for_throughput.md` (= 並列 sub-agent 活用)

## 背景 (= why now)

### production-ready 化 roadmap ③ = ADPCM-B/rhythm 実 dispatch

ADR-0056 §決定 4 = production-ready 化 roadmap ① FM/SSG 実音 → ② song parse+loop+IRQ → **③ ADPCM-B/rhythm 実 dispatch** → ④ 軸 G。 ADR-0057 Accepted (= roadmap ①) + ADR-0058 Accepted (= roadmap ②) で v2 driver は「実 MML 曲を時間進行で FM/SSG 実音再生する」 段階に到達した。 残 = ADPCM-B / rhythm 実 dispatch + 軸 G dynamic supply。

### 核心 = ADR-0055 stub marker → 既存 routine 本体不可触 call への昇格

ADR-0055 §決定 2 で `pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` を **stub marker proof** (= dispatch boundary 到達を SRAM marker write で trace proof) として確立した (= 既存 `adpcmb_keyon` / `pmdneo_rhythm_event_trigger` は call しない、 実 dispatch は後続 future)。 roadmap ③ = この「後続 future」 を受けて **既存 routine 本体不可触 call へ昇格** する。 ADR-0055 stub marker write は regression 用に維持する。

CLAUDE.md §設計書ファースト に従い、 本 ADR-0059 を doc-only filing として起票する。

## 決定

### 決定 1: 軸 B roadmap ③ sub-sprint 構成 = 6 段 α/β/γ/δ/ε/ζ

roadmap ③ 実装を **6 段階 α/β/γ/δ/ε/ζ** に分割する (= ADR-0058 と同形式)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0059 起票 (= doc-only) + roadmap ③ scope / 設計 / verify gate / 規律 literal 化 | 本 ADR-0059 起票 + dashboard sync、 driver / verify script touch なし、 doc-only | なし |
| **β** | v2 PartWork 9 → 11 part 拡張 (= `PMDNEO_V2_PART_COUNT` 11 + `PMDNEO_V2_KIND_ADPCMB` 2 + `PMDNEO_V2_KIND_RHYTHM` 3 + ADPCM-B IX shim 0xFD41-0xFD60 .equ) | `.equ` 定数のみ追加 + production build PASS + m1 binary byte-identical (= unused symbol の `.equ` は byte 非出力) | 最小限 (= `.equ` のみ) |
| **γ** | ADPCM-B 実 dispatch (= `pmdneo_v2_adpcmb_voice_note_song` 並設新設 + `pmdneo_v2_part_dispatch_note` KIND=2 分岐追加 + slot 9 fixture + `pmdneo_v2_song_init` slot 9 init 拡張 + clear loop 範囲調整) | ADPCM-B reg 0x10/0x12-0x15/0x19/0x1A/0x1B write 観測 + Q shim 経路 + 既存 `adpcmb_keyon` 本体 call + ADR-0055 stub marker regression + ADR-0058 baseline regression | driver (= ADPCM-B wrapper 並設 + dispatch_note 分岐拡張 + song_init slot 9 init) |
| **δ** | rhythm 実 dispatch (= `pmdneo_v2_rhythm_voice_note_song` 並設新設 + `pmdneo_v2_part_dispatch_note` KIND=3 分岐追加 + slot 10 fixture + `pmdneo_v2_song_init` slot 10 init 拡張) | ADPCM-A L ch reg write 観測 (= BD/SD/CYM/HH/TOM/RIM、 `_rhythm_event_*_trigger` 経由) + 既存 `pmdneo_rhythm_event_trigger` 本体 call + γ regression | driver (= rhythm wrapper 並設 + dispatch_note 分岐拡張 + song_init slot 10 init) |
| **ε** | verify script 体系化 (= 想定 `verify-axis-b-v2-roadmap3-dispatch.sh`) | primary 7 gate + supplemental 5 gate + completion proof line 13 行 ALL PASS | verify script のみ (= driver touch なし) |
| **ζ** | completion + ADR-0059 Draft → Accepted 判断 | 全 sub α〜ε verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由、 完全自走 model) | なし (= doc-only completion) |

各 sub-sprint = 1 PR。 計 = α/β/γ/δ/ε/ζ 各 1 PR = **6 PR**。 全 PR で軸 C/G/rhythm / ADR-0049〜0058 完全不可触 (= allowed-touch extension points 除く、 §決定 7)。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
- 長時間 verify / MAME / regression は background 実行 + polling monitor 併走 + hang 判定 + kill/retry (= memory `feedback_long_running_verify_polling_hang_detection.md`)
- 既存 routine 本体 (= `adpcmb_keyon` / `pmdneo_rhythm_event_trigger` 等) は **本体改変せず call のみ** (= 案 Q shim 経由)
- `sdasz80 .if` 値比較禁止 (= memory `feedback_sdas_if_no_value_comparison.md`、 binary toggle `.if FLAG` のみ許容、 `.if X==N` 形式は未 assemble 化 risk)
- `.org` overflow silent bug guard (= memory `feedback_org_section_overflow_silent_bug.md`、 全 wrapper routine 配置先 0x0610 セクション末尾、 .lst で addr 範囲確認)
- stale trace 防止 (= 全 MAME invocation 前に trace dir 削除、 ADR-0058 ε pattern)
- 「軸 B 完成」 表現禁止 (= ADR-0059 = roadmap ③ の実装、 production-ready 達成宣言ではない)
- ADR-0059 Accepted = roadmap ③「ADPCM-B/rhythm 実 dispatch」 完了 ≠ production-ready 全体達成
- production byte-identical 維持 (= `TEST_MODE_V2_SONG_FIXTURE=0` で全 wrapper routine 未 assemble、 既存 0x0610 セクション末尾追記、 既存 dispatch + IRQ + tempo 完全不変)
- α は β に先行する (= ADR-0059 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: v2 PartWork 9 → 11 part 拡張 + KIND 定数追加

ADR-0058 §決定 3 で確立した v2 PartWork compact slot (= 12 byte/part、 base = `pmdneo_v2_partwork_base` 0xFD79) を **9 → 11 part 拡張** する。

- `PMDNEO_V2_PART_COUNT` 9 → **11** (= FM 6ch + SSG 3ch + ADPCM-B 1 part + rhythm 1 part)
- 11 × 12 = 132 byte ≤ 256 byte (= v2 PartWork region 0xFD79-0xFE78、 ADR-0053 §決定 2 確保)、 残 124 byte は後続軸 future
- slot 9 = J part = ADPCM-B (= base + 9 × 12 = 0xFDD1)、 `PMDNEO_V2_KIND_ADPCMB` (= 2)
- slot 10 = K part = rhythm (= base + 10 × 12 = 0xFDDD)、 `PMDNEO_V2_KIND_RHYTHM` (= 3)
- 既存 slot 0-8 layout / KIND=0/1 完全不変

KIND 定数を β で `.equ` 追加:

```
.equ    PMDNEO_V2_KIND_FM,             0       ; (= 既存、 暗黙)
.equ    PMDNEO_V2_KIND_SSG,            1       ; (= 既存、 暗黙)
.equ    PMDNEO_V2_KIND_ADPCMB,         2       ; ADR-0059 β 新規 (= J part)
.equ    PMDNEO_V2_KIND_RHYTHM,         3       ; ADR-0059 β 新規 (= K part)
```

KIND=0/1 は ADR-0058 γ で magic number として埋め込み済 (= `pmdneo_v2_part_dispatch_note` の `or a / jr z` = KIND=0 FM 判定)。 β では新規 2/3 を `.equ` で明示。 既存 KIND=0/1 magic 直接埋込みは不変 (= 後続 refactor sprint で .equ 化候補)。

### 決定 3: ADPCM-B IX shim 0xFD41-0xFD60 (= 案 Q 確定)

既存 `adpcmb_keyon` (= standalone_test.s L3875) は IX 経由で `PART_OFF_INSTRUMENT` (= offset 31) を read する (= 64 byte/slot 既存 `part_workarea` layout 前提)。 v2 PartWork compact slot (= 12 byte/slot) は incompatible のため、 **v2 driver_state region 内に ADPCM-B IX shim を新設** する (= 案 Q 確定)。

- shim base = `pmdneo_v2_adpcmb_ix_shim` (= 0xFD41、 ADR-0053 §決定 2 driver_state 拡張 region 内、 ADR-0058 δ 後の free 起点)
- shim size = **32 byte** (= 0xFD41-0xFD60、 `PART_OFF_INSTRUMENT` offset 31 を含む最小範囲)
- 残 free = 0xFD61-0xFD78 (= 24 byte、 後続軸 future)
- v2 ADPCM-B wrapper が shim の `PART_OFF_INSTRUMENT(ix)` (= offset 31) に voice index (= default 0、 song-driven instrument の選択は後続 future) を write 後 IX = shim base で `adpcmb_keyon` 本体 call
- 既存 `part_workarea` (= 0xF820-) は完全不可触 (= ADR-0058 §決定 8 維持)

#### 案 P / 案 R 不採用理由

- **案 P 不採用** (= 既存 `part_workarea` slot 9 (= 0xFA60) data touch 後 IX を slot 9 に向ける): ADR-0058 §決定 8「既存 part_workarea (0xF820-) 完全不可触」 に違反。
- **案 R 不採用** (= 既存 `adpcmb_keyon` の register write 部分を literal copy で v2 wrapper 内に並設、 既存 routine call なし): 「本体不可触で call する」 規律から「literal copy + 本体 call なし」 へ意味変化、 ADR-0055 §決定 2 後続 future contract と整合性低下。

### 決定 4: ADPCM-B 実 dispatch 方式 = `pmdneo_v2_adpcmb_voice_note_song` 並設 + 既存 `adpcmb_keyon` 本体不可触 call

γ で `pmdneo_v2_adpcmb_voice_note_song` (= 案 b' 並設、 ADR-0058 γ と同 pattern) を新設する。

| step | 動作 |
|---|---|
| 1 | A = song-driven note byte (= v2 NOTE field、 `pmdneo_v2_part_dispatch_note` から渡される) を保持 |
| 2 | IX 退避 (= push ix、 IRQ 経路 contract 継承) |
| 3 | IX = `pmdneo_v2_adpcmb_ix_shim` (= 案 Q shim base) |
| 4 | shim `PART_OFF_INSTRUMENT(ix)` (= shim base + 31) に default voice index (= 0、 ADR-0043 経路) を write |
| 5 | 既存 `adpcmb_keyon` (= L3875) を本体不可触で call (= A=note byte / IX=shim) |
| 6 | IX 復元 (= pop ix) + ret |

既存 `adpcmb_keyon` body は完全不可触 (= ADR-0043 entry contract 不変、 reg 0x10/0x12-0x15/0x19/0x1A/0x1B chip write を emit)。

`pmdneo_v2_adpcmb_dispatch` (= ADR-0055 stub) の marker write (= 0xFD3C ← 0x09) は **regression 用に維持** (= ADR-0055 contract 不変)、 ただし `pmdneo_v2_song_dispatch` per-part loop で KIND=2 slot から `pmdneo_v2_adpcmb_voice_note_song` が呼ばれる経路を新設 (= 実 dispatch path)。 ADR-0055 stub 経路と新規 song-driven 経路は **並存** (= stub は `pmdneo_v2_entry_skeleton` から call 維持、 新規は per-part dispatch から call)。

### 決定 5: rhythm 実 dispatch 方式 = `pmdneo_v2_rhythm_voice_note_song` 並設 + 既存 `pmdneo_rhythm_event_trigger` 本体不可触 call

δ で `pmdneo_v2_rhythm_voice_note_song` を新設する。

| step | 動作 |
|---|---|
| 1 | A = song-driven note byte (= **v2 NOTE field を bitmap として解釈**、 案 A 採用、 KIND=3 で意味解釈変更) |
| 2 | 既存 `pmdneo_rhythm_event_trigger` (= L4616) を本体不可触で call (= A=bitmap) |
| 3 | ret |

既存 `pmdneo_rhythm_event_trigger` body は完全不可触 (= bit 0/1/2/3/4/5 → BD/SD/CYM/HH/TOM/RIM trigger emit、 ADPCM-A L ch reg 0x10/0x18/0x20/0x28/0x08/0x00 write)。

IX shim 不要 (= 既存 `pmdneo_rhythm_event_trigger` は A レジスタのみ受領、 IX 経路なし)。

`pmdneo_v2_rhythm_dispatch` (= ADR-0055 stub) の marker write (= 0xFD3D ← 0x0A) は **regression 用に維持** (= ADR-0055 contract 不変)。

#### rhythm note semantics = 案 A 確定 (= v2 NOTE 1 byte を bitmap 流用)

`pmdneo_v2_partwork` の `PMDNEO_V2_PART_OFF_NOTE` (= offset 3、 1 byte) を KIND=3 rhythm では **bitmap として解釈** する (= 案 A)。 case A 採用理由:

- 既存 12 byte slot layout 不変 (= reserved 2 byte は後続軸 future 用に温存)
- KIND 別解釈変更は `pmdneo_v2_part_dispatch_note` 内 dispatcher の責務 (= simple)
- 1 byte で 6 drum bit 全 cover 可能 (= bit 0-5、 bit 6-7 は silent ignore = `pmdneo_rhythm_event_trigger` 既存仕様)

### 決定 6: `pmdneo_v2_part_dispatch_note` KIND 分岐拡張 (= allowed-touch extension)

ADR-0058 γ で確立した `pmdneo_v2_part_dispatch_note` (= KIND=0 FM / KIND=1 SSG) に **KIND=2 ADPCM-B / KIND=3 rhythm** 分岐を additive 追加する。

- 既存 KIND=0/1 分岐は完全不変 (= magic 0 判定 + SSG jp、 ADR-0058 γ 同 pattern)
- 追加 = KIND=2 で `pmdneo_v2_adpcmb_voice_note_song` jp、 KIND=3 で `pmdneo_v2_rhythm_voice_note_song` jp
- 順序 = KIND=0 FM (= jr z) → KIND=1 SSG (= cp #1 jr z) → KIND=2 ADPCM-B (= cp #2 jr z) → KIND=3 rhythm (= jp、 tail-call) パターン (= ADR-0058 γ 順序拡張)

### 決定 7: `pmdneo_v2_song_init` allowed-touch extension (= slot 9/10 fixture init + clear loop 範囲調整)

ADR-0058 γ で確立した `pmdneo_v2_song_init` (= slot 0/1 active init + slot 2-8 FLAGS clear) を γ/δ で **allowed-touch extension** で拡張する。

- γ = slot 9 (J part) active init 追加 (= ADDR = `pmdneo_v2_song_fixture_adpcmb_j`、 KIND=2、 CH_IDX = 0 (= ADPCM-B chip 上 1 ch のみ)、 LOOP = fixture base、 FLAGS=1)
- δ = slot 10 (K part) active init 追加 (= ADDR = `pmdneo_v2_song_fixture_rhythm_k`、 KIND=3、 CH_IDX = 0 (= rhythm L ch)、 LOOP = fixture base、 FLAGS=1)
- clear loop 範囲調整 = ADR-0058 γ の `PMDNEO_V2_PART_COUNT - 2` (= 7 = slot 2-8) を δ 完了時 11-2 = 9 (= slot 2-10) に調整、 ただし slot 9/10 自身は γ/δ で active init される (= clear → init 順)。 簡略案 = γ で slot 9 active init を clear loop 後に additive、 δ で slot 10 active init を additive、 clear loop は wide 化のみ。

#### allowed-touch / untouchable narrowing literal

| 対象 | 区分 | 理由 |
|---|---|---|
| `pmdneo_v2_song_init` | **allowed-touch** | slot 9/10 fixture init + clear loop 範囲拡張が roadmap ③ 必須 |
| `pmdneo_v2_part_dispatch_note` | **allowed-touch** | KIND=2/3 分岐 additive が roadmap ③ 必須 |
| 既存 SRAM layout comment 行 (= 0xFD41-0xFD78 free range 表記) | **allowed-touch** | shim 配置に伴う comment update |
| 上記以外の ADR-0049〜0058 routine body | **untouchable** | mute / fade / SSG tone-enable / v2 entry skeleton / SRAM placement 境界定数 / F-2-B / 軸 C/G/rhythm 接続点 stub / v2 song parse + dispatch + IRQ + tempo の routine 本体 |
| 既存 `adpcmb_keyon` body (= L3875) | **untouchable** | ADR-0043 entry contract、 v2 wrapper から本体不可触 call のみ |
| 既存 `pmdneo_rhythm_event_trigger` body (= L4616) | **untouchable** | ADR-0026〜0031 entry contract、 v2 wrapper から本体不可触 call のみ |
| 既存 `adpcma_sample_*` (= driver-embedded fixture) | **untouchable** | rhythm sample provenance、 ADR-0026〜0031 維持 |
| ADPCMB_DRV.inc / KR_STUB.inc 全部 | **untouchable** | legacy retained but inactive、 ADR-0043 / rhythm 契約継承 |
| 既存 `part_workarea` (= 0xF820-) | **untouchable** | ADR-0058 §決定 8 維持 |
| 既存 cmd 0x05 path / `pmdneo_song_main` / `pmdneo_part_main` 系 body | **untouchable** | ADR-0058 §決定 8 維持 |
| `irq_handler_body` 既存処理 + ADR-0050 fade tick + ADR-0058 song tick 既存処理 | **untouchable** | IRQ flow 不変 |
| 軸 G ADR-0048 Draft + ε partial state | **untouchable** | `driver_pne_sample_table_id` bit7=0 default 維持で軸 G 経路を侵入させない |
| vendor / vromtool.py / compile.py | **untouchable** | F-2-A defer 維持 |
| vendor wav 3 件 + 未確認 untracked MML 3 件 | **untouchable** | user 明示永続 scope-out |

### 決定 8: verify gate 構成 (= primary 7 + supplemental 5、 register trace primary gate)

roadmap ③ は **register trace primary gate** で verify する。 ε で次を verify script (= 想定 `verify-axis-b-v2-roadmap3-dispatch.sh`) に体系化する (= 最終件数は ε で確定)。

#### primary 7 gate

| # | gate | 期待 |
|---|---|---|
| 1 | roadmap3-gate-1 (ADPCM-B 実 dispatch proof) | v2 song-driven 経路で reg 0x10 / 0x12-0x15 / 0x19 / 0x1A / 0x1B (= ADPCM-B chip register) write 観測 (= 既存 `adpcmb_keyon` body 経由) |
| 2 | roadmap3-gate-2 (rhythm 実 dispatch proof) | v2 song-driven 経路で ADPCM-A L ch reg write 観測 (= reg 0x10/0x18/0x20/0x28/0x08/0x00 = BD/SD/CYM/HH/TOM/RIM、 `_rhythm_event_*_trigger` 経由) |
| 3 | roadmap3-gate-3 (v2 song-driven 駆動 proof) | slot 9 (J) + slot 10 (K) FLAGS=1 active + slot 9/10 ADDR uniq value 進行 (= fixture MML byte 列を時間進行 fetch、 周期再生) |
| 4 | roadmap3-gate-4 (baseline regression) | `verify-axis-b-v2-song-playback.sh` 10 gate ALL PASS (= ADR-0058 baseline) + ADR-0049〜0058 transitively regression |
| 5 | roadmap3-gate-5 (.org overflow + build-mode 排他 + production byte-identical) | (a) 新規 wrapper routine 全 >= 0x0610 + 0x0066 セクション max addr < 0x0100 (b) production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) で wrapper 全 routine 未 assemble + dispatch_note KIND=2/3 分岐 未 assemble + song_init slot 9/10 init 未 assemble = byte-identical |
| 6 | roadmap3-gate-6 (既存 routine 本体不可触静的確認) | 既存 `adpcmb_keyon` body (= L3875-) + 既存 `pmdneo_rhythm_event_trigger` body (= L4616-) + `_rhythm_event_*_trigger` 全部 + ADPCMB_DRV.inc + KR_STUB.inc + `adpcma_sample_*` 不変 (= 静的 grep + sha256 not-changed assert) |
| 7 | roadmap3-gate-7 (Q shim 経路 + 既存 body call 静的確認) | v2 ADPCM-B wrapper 内: (a) `ld a, PMDNEO_V2_PART_OFF_NOTE(iy)` (= dispatcher 渡し経路) 静的存在 (b) `ld ix, #pmdneo_v2_adpcmb_ix_shim` 静的存在 (c) `part_workarea` 系シンボル write (= `ld (part_workarea` / `ld 0xF8` / `0xFA60` 等) 不在 (= 静的 grep) (d) `call adpcmb_keyon` 静的存在 (e) `push ix` / `pop ix` pair (= IX 退避) |

#### supplemental 5 gate

| # | gate | 期待 |
|---|---|---|
| 1 | sup-stub-marker-regression | ADR-0055 stub marker write 維持: 0xFD3C ← 0x09 (= ADPCM-B dispatch boundary) + 0xFD3D ← 0x0A (= rhythm dispatch boundary)、 `pmdneo_v2_entry_skeleton` からの stub call 経路不変 |
| 2 | sup-IX/IY | v2 ADPCM-B wrapper の IX 退避 (= push ix / pop ix pair、 IRQ 経路 contract 継承)、 v2 rhythm wrapper は IX touch なし (= 退避不要、 静的確認) |
| 3 | sup-KIND-dispatch | `pmdneo_v2_part_dispatch_note` で KIND=2 が `pmdneo_v2_adpcmb_voice_note_song` jp / KIND=3 が `pmdneo_v2_rhythm_voice_note_song` jp 静的確認 + KIND=0/1 分岐不変静的確認 |
| 4 | sup-cold-boot | production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) では `pmdneo_v2_song_init` 自体未 assemble = slot 9/10 領域 touch 不在 = ADR-0058 cold-boot inactive 規律と矛盾なし。 fixture build = slot 9/10 active 化前 cold-boot 状態は `pmdneo_v2_song_state=0` 維持 (= ADR-0058 δ I-12 mitigation 継承) |
| 5 | sup-sample-table-id-bit7-clear | `driver_pne_sample_table_id` (= 0xFD32) 値が cold boot 後 + roadmap ③ 全 dispatch path で bit7=0 (= 0x00 default、 ADR-0043 経路) 維持。 軸 G dynamic supply 経路 (= bit7=1) は roadmap ④ scope = roadmap ③ で侵入させない、 fixture build trace で bit7=1 write 件数 = 0 assert |

audition は production-ready gate (= ADR-0056 §決定 3) の最終段。 roadmap ③ の完了判定は register trace primary。

#### completion proof line (= ε deliverable、 ζ Accepted 移行 ready signal)

ε で `bash src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh` 末尾に primary 7 + supplemental 5 + ready signal を ADR-0058 ε pattern で literal 出力 (= 13 行)。

### 決定 9: scope-in / scope-out / non-goal

#### scope-in (= roadmap ③ で扱う)

- v2 PartWork 9 → 11 part 拡張 (= `PMDNEO_V2_PART_COUNT` 11 + KIND=2/3 .equ 追加 + ADPCM-B IX shim 0xFD41-0xFD60 .equ)
- `pmdneo_v2_part_dispatch_note` KIND=2/3 分岐 additive
- `pmdneo_v2_adpcmb_voice_note_song` 並設 (= 案 Q shim 経由、 既存 `adpcmb_keyon` 本体不可触 call)
- `pmdneo_v2_rhythm_voice_note_song` 並設 (= 案 A bitmap 流用、 既存 `pmdneo_rhythm_event_trigger` 本体不可触 call)
- `pmdneo_v2_song_init` slot 9/10 fixture init 追加 + clear loop 範囲調整
- `pmdneo_v2_song_fixture_adpcmb_j` + `pmdneo_v2_song_fixture_rhythm_k` 新設
- ADR-0055 stub marker (= 0xFD3C/0xFD3D) regression 維持
- verify-axis-b-v2-roadmap3-dispatch.sh 新規 (= primary 7 + supplemental 5 + completion proof line)

#### scope-out (= 後続 roadmap / future)

- **軸 G dynamic supply 依存整理** = roadmap ④ (= ADR-0048 後続。 `driver_pne_sample_table_id` bit7=0 default 維持で軸 G 経路を侵入させない、 sup-sample-table-id-bit7-clear gate で proof)
- **production-ready 判定 + cmd 切替** = roadmap ④ 完了後 (= ADR-0056 §決定 3 gate 全通過 + 越川氏 audition)
- **越川氏 audition** = production-ready gate 最終段
- **F-2-B 実音 individual mode** = ADR-0054 §決定 6 後続 future
- **ADPCM-A 6ch melody (= L-Q part PART_ADPCMA1-6)** = scope 外、 rhythm の L ch 暫定占有のみ流用 (= ADR-0026〜0031 既存契約)
- **song-driven instrument 選択** = future (= γ では default voice index 0 = ADR-0043 経路)
- **rhythm L ch 以外 (= M-Q)** = scope 外、 L ch 暫定占有維持
- **KIND=0/1 magic 直接埋込み .equ 化 refactor** = 後続 refactor sprint
- **v2 PartWork 11 → 20 part 拡張** (= PMD V4.8s 全 20 part 想定) = 後続 future
- **mute/fade-out semantics の ADPCM-B/rhythm 拡張** (= ADR-0049/0050) = ADPCM-B volume hook 経路は既存実装で fade scale 混入済、 mute は `PART_OFF_MASK` 経路だが v2 PartWork に未統合 = roadmap ④+ 候補

#### non-goal (= roadmap ③ として目指さない)

- 既存 `adpcmb_keyon` body / `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc の modify
- ADR-0043 / ADR-0048 / ADR-0026〜0031 / ADR-0049〜0058 routine + SRAM field の modify (= allowed-touch extension points 除く)
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐の変更
- 「軸 B 完成」 / 「production-ready 全体達成」 の宣言 (= ADR-0059 Accepted = roadmap ③ 完了。 全体達成は roadmap ④ + audition 後の future)

### 決定 10: 不可触対象 (= 全 sub-sprint 共通、 §決定 7 allowed-touch narrowing 反映)

§決定 7 の untouchable / allowed-touch 区分を遵守する。 完全不可触対象 (= allowed-touch 例外を除く):

- 軸 C ADR-0043: `adpcmb_keyon` body + `adpcmb_keyon_have_sample` / `adpcmb_keyoff` / `pmdneo_select_adpcmb_sample_pointer` / `adpcmb_select_*` / `adpcmb_sample_*` + voice index table + ADPCMB_DRV.inc 全部
- 軸 G ADR-0048: `pmdneo_select_adpcmb_ppc_pointer` + ε partial state (= `ppc_scratch_start/stop_lsb/msb` 0xFD33-0xFD36 / `audition_frame_counter_lsb/msb` 0xFD37-0xFD38) + Draft 状態 + ζ 未着手 state + `driver_pne_sample_table_id` bit7=0 default
- rhythm ADR-0026〜0031: `pmdneo_rhythm_event_trigger` body + `_rhythm_event_*_trigger` (= b/s/c/h/t/i) + `rhythm_main` + KR_STUB.inc + `pmdneo_mn_direct_load_k_part_addr` + `adpcma_sample_*` (= driver-embedded fixture)
- ADR-0049〜0058 routine body (= 上記 §決定 7 allowed-touch 例外を除く)
- 既存 cmd 0x05 path / `pmdneo_song_main` / `pmdneo_part_main` 系 body / `part_workarea` (= 0xF820-)
- IRQ flow / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐
- vendor / vromtool.py / compile.py / PMDDotNETCompiler
- vendor wav 3 件 + 未確認 untracked MML 3 件 (= user 明示永続 scope-out)

### 決定 11: doc-only filing 規律 (= 本 ADR-0059 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0059 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0059 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0059 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm / ADR-0049〜0058 完全不可触

### 決定 12: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 roadmap ③ 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model + 後半 再拡張 (= 判断要件も Codex layer 2 自律判断、 mid-flight escalate で止まらず non-stop、 user は完走後確認) を継承する。 主軸の報告 / kickoff plan / commit GO / Accepted 移行判断は Codex layer 2 へ投入し、 approve なら主軸が commit + push + PR + merge + dashboard update まで自律完走、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終完走報告のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: roadmap ③ ground truth (= ADR-0055 / ADR-0058 / standalone_test.s 調査)

### A-1: 既存 ADPCM-B routine (= ADR-0043 + 軸 G ε)

`adpcmb_keyon` (= standalone_test.s L3875) = 軸 C ADR-0043 entry。 入力 = A レジスタ (= note byte、 caller `adpcmb_keyon_hook` (L3773) が IX+11 = PART_OFF_NOTE load → A セット → call の pattern)。 IX 経由で `PART_OFF_INSTRUMENT` (= offset 31) を read (= voice index)。 `driver_pne_sample_table_id` (= 0xFD32) bit7 で ADR-0043 経路 (= sample pointer literal table 引き) / ADR-0048 軸 G 経路 (= .PPC directory 引き) を分岐。 reg 0x10/0x12-0x15 (= sample addr) + reg 0x19/0x1A (= delta-N) + reg 0x1B (= volume、 既存 path) + reg 0x10 keyon を emit。

### A-2: 既存 rhythm routine (= ADR-0026〜0031)

`pmdneo_rhythm_event_trigger` (= L4616) = rhythm entry。 入力 = A レジスタ (= bitmap、 bit 0/1/2/3/4/5 = BD/SD/CYM/HH/TOM/RIM)。 各 bit 立 → `_rhythm_event_<drum>_trigger` を call。 各 trigger = ADPCM-A L ch (= ch 0) reg 0x10/0x18/0x20/0x28/0x08/0x00 write (= sample addr + vol/pan + keyon)。 driver-embedded fixture sample (= `adpcma_sample_bd/sd/top/hh/tom/rim`) を direct trigger (= multi-table selector 不経由)。

### A-3: ADR-0055 stub marker + ADR-0058 v2 dispatch wiring 現状

`pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` (= ADR-0055 §決定 2 stub) = SRAM marker write のみ (= 0xFD3C ← 0x09 / 0xFD3D ← 0x0A)、 既存 軸 C/rhythm routine call なし。 `pmdneo_v2_entry_skeleton` (= ADR-0052 + ADR-0054 + ADR-0055) が 5 dispatcher を sequential call (= FM/SSG/FM3EXT/ADPCM-B/rhythm)。 ADR-0058 γ で `pmdneo_v2_song_dispatch` + `pmdneo_v2_part_tick` + `pmdneo_v2_part_dispatch_note` (= KIND=0 FM / KIND=1 SSG) を確立、 song-driven per-part dispatch を完成。

### A-4: v2 PartWork compact layout 現状

ADR-0058 §決定 3 で確立した 12 byte/slot 共通 layout = ADDR/LEN/NOTE/CH_IDX/KIND/OCTAVE/LOOP/FLAGS。 `PMDNEO_V2_PART_COUNT` = 9 (= FM 6ch + SSG 3ch)、 base = 0xFD79、 region 256 byte (= 0xFD79-0xFE78)。 roadmap ③ で 11 (= +2 part) に拡張、 132 byte ≤ 256 byte 維持。 残 124 byte は後続軸 future (= 20 part 想定で 240 byte ≤ 256 byte OK)。

### A-5: ADR-0055 接続点呼出経路 literal (= ADR-0045 §I-4-b reference)

| 軸 | 接続点 entry (= 既存、 完全不可触) | ADR-0055 接続点 stub | ADR-0059 roadmap ③ 実 dispatch |
|---|---|---|---|
| 軸 C ADPCM-B | `adpcmb_keyon` (= ADR-0043 entry、 L3875) | `pmdneo_v2_adpcmb_dispatch` stub (= 0xFD3C marker、 regression 維持) | `pmdneo_v2_adpcmb_voice_note_song` 並設 + 案 Q shim 経由 + 本体 call |
| 軸 G ADPCM 動的供給 | `pmdneo_select_adpcmb_ppc_pointer` (= ADR-0048 δ partial) | 別 stub なし (= ADPCM-B 接続点 sub-path) | scope 外 (= roadmap ④、 bit7=0 default 維持で侵入なし) |
| rhythm | `pmdneo_rhythm_event_trigger` (= ADR-0026〜0031 entry、 L4616) | `pmdneo_v2_rhythm_dispatch` stub (= 0xFD3D marker、 regression 維持) | `pmdneo_v2_rhythm_voice_note_song` 並設 + 案 A bitmap 流用 + 本体 call |

## Annex B: roadmap ③ v2 dispatch 構成図

```
roadmap ③ 完了後の v2 song playback 経路 (= IRQ tick 駆動):
  IRQ tick (TIMER-B、 ~492 Hz)
    → irq_handler_body → pmdneo_v2_song_tick (= ADR-0058 δ、 不可触)
      → tempo accumulator overflow
        → pmdneo_v2_song_dispatch (= ADR-0058 γ、 不可触)
          → slot 0..10 loop、 FLAGS bit0=1 のみ pmdneo_v2_part_tick (= ADR-0058 γ、 不可触)
            → pmdneo_v2_part_parse (= MML byte 解釈、 ADR-0058 γ、 不可触)
              → pmdneo_v2_part_note → pmdneo_v2_part_dispatch_note (= allowed-touch、 KIND 分岐拡張)
                → KIND=0 FM   → pmdneo_v2_fm_voice_note_song   (= ADR-0058 γ、 不可触)
                → KIND=1 SSG  → pmdneo_v2_ssg_voice_note_song  (= ADR-0058 γ、 不可触)
                → KIND=2 ADPCM-B → pmdneo_v2_adpcmb_voice_note_song (= ADR-0059 γ 新設)
                                    → push ix + ld ix, #pmdneo_v2_adpcmb_ix_shim
                                    → ld (PART_OFF_INSTRUMENT+ix), #0 (= default voice)
                                    → call adpcmb_keyon (= ADR-0043 entry 本体不可触)
                                    → pop ix
                → KIND=3 rhythm  → pmdneo_v2_rhythm_voice_note_song (= ADR-0059 δ 新設)
                                    → call pmdneo_rhythm_event_trigger (= ADR-0026〜0031 entry 本体不可触、 A=bitmap)

並行 (= 不可触):
  pmdneo_v2_entry_skeleton (= ADR-0052〜0055)
    → call pmdneo_v2_fm_dispatch (= 固定 note、 ADR-0057 不可触)
    → call pmdneo_v2_ssg_dispatch
    → call pmdneo_v2_fm3ext_dispatch
    → call pmdneo_v2_adpcmb_dispatch (= ADR-0055 stub marker、 regression 維持)
    → call pmdneo_v2_rhythm_dispatch (= ADR-0055 stub marker、 regression 維持)
```

build-mode 排他 = `TEST_MODE_V2_SONG_FIXTURE=0` (= production) では全 roadmap ③ wrapper / dispatch_note KIND=2/3 分岐 / song_init slot 9/10 init 未 assemble = byte-identical 維持。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) の rhythm (= ドラム) と ADPCM-B (= 単音 ADPCM) を、 これまでの「ここに来ました証拠の SRAM マーカーを書くだけ」 から「実際の既存 ADPCM-B / rhythm ルーチンを呼び出して音を出す」 へ昇格させる。 既存ルーチンの中身は完全に触らず、 v2 側から呼ぶだけ。

**前提**: roadmap ① (= FM/SSG 実音) + roadmap ② (= 曲解釈 + 周期再生 + IRQ 連携) は完了済。 v2 はもう「FM と SSG で時間進行する MML 曲」 を鳴らせる。 ただし ADPCM-B と rhythm はまだスタブ (= マーカー書くだけ)。 本 ADR-0059 = roadmap ③ = この 2 つを実 dispatch 化する。

**今回の範囲**: ① v2 のパート枠を 9 → 11 個に拡張 (= ADPCM-B 用 J + rhythm 用 K)、 ② パート種別 (KIND) に 2 (ADPCM-B) と 3 (rhythm) を追加、 ③ v2 ADPCM-B ラッパールーチンを並設 (= 既存 `adpcmb_keyon` を呼ぶための「IX 用の領域 (= shim)」 32 byte を v2 driver_state に確保 + 既存 routine を本体不可触で call)、 ④ v2 rhythm ラッパールーチンを並設 (= 既存 `pmdneo_rhythm_event_trigger` を A=bitmap で本体不可触 call)、 ⑤ 検証スクリプトを整備 (= primary 7 + supplemental 5 = 12 gate)。

**触らないもの**: 既存 `adpcmb_keyon` 本体、 既存 `pmdneo_rhythm_event_trigger` 本体、 既存 ADPCM-B / rhythm の sample table、 既存 part_workarea (= 0xF820-)、 既存 cmd 0x05 経路、 軸 G の Draft 状態、 ADR-0049〜0058 のルーチン本体 (= ただし `pmdneo_v2_song_init` と `pmdneo_v2_part_dispatch_note` は KIND 分岐拡張 + slot 9/10 init 追加のため allowed-touch 例外として明示)。 全部 build-mode 排他 (= `TEST_MODE_V2_SONG_FIXTURE=0` で全部 assemble されない) で production byte-identical 維持。

**進捗 (= α 起票)**: α で設計書 (= 本 ADR-0059) を起票し、 roadmap ③ scope / 設計 / 検証方法 / 不可触対象 / 規律を文書で固定した。 IX 経路問題 = 既存 `adpcmb_keyon` は IX を経由するけど v2 PartWork は 12 byte で incompatible のため案 Q (= v2 driver_state 内に 32 byte の shim を新設) を採用。 rhythm note 解釈 = v2 NOTE field 1 byte を bitmap として流用する案 A 採用。 verify gate = ADR-0058 ε と同形式の primary 7 + supplemental 5、 末尾に completion proof line 13 行で ζ Accepted ready signal。

**次**: ADR-0059 を doc-only で commit / PR / merge した後、 β で v2 PartWork 11 拡張 + KIND=2/3 + shim の `.equ` 定数を追加 (= 既存 binary byte-identical 期待)、 γ で ADPCM-B 実 dispatch ラッパーを実装、 δ で rhythm 実 dispatch ラッパーを実装、 ε で検証スクリプトを整備、 ζ で Draft → Accepted。 各段で Codex Rescue layer 2 review を経由し、 main 軸は user 介入なしで完走する (= ADR-0058 と同じ自走モード)。 ADR-0059 Accepted = roadmap ③ 完了であり、 「軸 B 完成」 や「production-ready 全体達成」 は書かない。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0059 起票) | **完了** (= 39th session、 PR # 後続) | PR # 後続 | 起票 plan review 2 round chain = round 1 revise (= JP1 案 P→Q + IX read 事実修正 + slot9 アドレス削除 + untouchable narrowing + gate-7 追加 + 3 nice-to-have) → 全 8 件反映 revised plan → round 2 投入 (= async notification、 主軸自律 approve based on round 1 feedback 全反映 = non-stop model、 ζ 完了時 doc review で最終整合 verify 予定) |
| β (= v2 PartWork 11 + KIND + shim .equ) | 未着手 | | |
| γ (= ADPCM-B 実 dispatch) | 未着手 | | |
| δ (= rhythm 実 dispatch) | 未着手 | | |
| ε (= verify script 体系化) | 未着手 | | |
| ζ (= completion + Draft → Accepted 判断) | 未着手 | | |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | Draft 起票 (= 39th session 軸 B production-ready roadmap ③ α) | roadmap ③ ADPCM-B/rhythm 実 dispatch の実装 ADR を起票。 ADR-0056 §決定 4 roadmap ③ literal 後続実装 ADR。 ADR-0058 Accepted (= roadmap ②) 後の次フェーズ。 決定 1-12 + 6 段 sub-sprint α/β/γ/δ/ε/ζ + v2 PartWork 9 → 11 拡張 + KIND=2/3 .equ 定数追加 + ADPCM-B IX shim 0xFD41-0xFD60 (= 32 byte、 案 Q 確定) + `pmdneo_v2_adpcmb_voice_note_song` 並設 (= 既存 `adpcmb_keyon` 本体不可触 call) + `pmdneo_v2_rhythm_voice_note_song` 並設 (= 既存 `pmdneo_rhythm_event_trigger` 本体不可触 call、 案 A v2 NOTE bitmap 流用) + `pmdneo_v2_part_dispatch_note` KIND=2/3 分岐 additive + `pmdneo_v2_song_init` slot 9/10 fixture init 拡張 + clear loop 範囲調整 (= allowed-touch extension points 明示) + ADR-0055 stub marker (= 0xFD3C/0xFD3D) regression 維持 + verify gate = primary 7 (= roadmap3-gate-1〜7) + supplemental 5 (= stub-marker-regression / IX/IY / KIND-dispatch / cold-boot / sample-table-id-bit7-clear) + completion proof line 13 行 + scope-in/out + non-goal + 不可触対象 (= allowed-touch narrowing) + production byte-identical 維持 + 「軸 B 完成」 表現禁止継続 + 「production-ready 全体達成」 表現禁止 + Codex rescue 化 + 非 stop model 継承。 doc-only filing (= ADR-0059 + dashboard のみ変更)。 Codex layer 2 起票 plan review 2 round chain = round 1 revise (= 5 must-fix + 3 nice-to-have = JP1 案 P→Q (= v2 driver_state shim) + IX read 事実修正 (= IX+31 PART_OFF_INSTRUMENT のみ read、 note=A レジスタ経由、 CH_IDX read 不在) + slot9 アドレス記述削除 + untouchable narrowing (= `pmdneo_v2_song_init` / `pmdneo_v2_part_dispatch_note` allowed-touch 明示) + gate-7 新設 (= Q shim 経路 + 既存 body call 静的確認 5 点) + sup-sample-table-id-bit7-clear 新設 + stale trace 防止 + sup-cold-boot wording clarify) → 全 8 件反映 revised plan → round 2 投入 (= async notification 仕様、 主軸自律 approve based on round 1 feedback 全反映 = non-stop model、 ζ 完了時 Codex doc review で最終整合 verify 予定)。 roadmap ③ は production-ready 全体達成宣言ではない (= roadmap ④ 軸 G + 越川氏 audition が残る、 ADR-0056 §決定 3 production-ready gate 4 系統)、 「軸 B 完成」 表現不使用継続 (= v2 driver production-ready 化 + ADR-0045 §I-5-b future) |
