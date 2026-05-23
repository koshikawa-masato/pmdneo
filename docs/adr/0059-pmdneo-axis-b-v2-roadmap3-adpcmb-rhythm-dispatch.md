# ADR-0059: PMDNEO 軸 B v2 driver production-ready roadmap ③ = ADPCM-B/rhythm 実 dispatch

- 状態: **Accepted** (= 2026-05-23 39th session 軸 B production-ready roadmap ③ 設計+実装 完了、 ground truth = ADR-0056 roadmap ③ / ADR-0058、 α 起票 + β v2 PartWork 11 + KIND + ADPCM-B IX shim .equ + γ ADPCM-B 実 dispatch + δ rhythm 実 dispatch + ε verify script 体系化 + 12 gate ALL PASS + ζ Draft→Accepted 移行 = 全 6 sub-sprint α/β/γ/δ/ε/ζ 完走。 ADR-0059 Accepted = roadmap ③「ADPCM-B/rhythm 実 dispatch」 完了 (= design + 実装 + verify 完走)。 **production-ready 全体達成ではない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ③ で未実施、 roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ④ 完走後の future)。 「軸 B 完成」 表現不使用 (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過))
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

- **案 P 不採用** (= 既存 `part_workarea` slot 9 data touch 後 IX を slot 9 に向ける): ADR-0058 §決定 8「既存 part_workarea (0xF820-) 完全不可触」 に違反。
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
| 7 | roadmap3-gate-7 (Q shim 経路 + 既存 body call 静的確認) | v2 ADPCM-B wrapper 内: (a) `ld a, PMDNEO_V2_PART_OFF_NOTE(iy)` (= dispatcher 渡し経路) 静的存在 (b) `ld ix, #pmdneo_v2_adpcmb_ix_shim` 静的存在 (c) `part_workarea` 系シンボル write (= `ld (part_workarea` / `ld 0xF8` 等) 不在 (= 静的 grep) (d) `call adpcmb_keyon` 静的存在 (e) `push ix` / `pop ix` pair (= IX 退避) |

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

- 変更 file = 本 ADR-0059 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0059 + escalation 履歴 α entry update、 軸 B 行 + 軸別進捗 details は ζ で一括 update = ADR-0058 ζ 同 pattern) のみ
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

## Annex C: β 実装 completion record (= v2 PartWork 11 拡張 + KIND + ADPCM-B IX shim .equ)

### C-1: β deliverable

軸 B production-ready roadmap ③ β = v2 PartWork 11 拡張 + KIND=2/3 .equ + ADPCM-B IX shim 0xFD41-0xFD60 .equ (= 39th session、 PR #103)。

| deliverable | 内容 |
|---|---|
| `standalone_test.s` `PMDNEO_V2_PART_COUNT` 9 → **11** | FM 6ch + SSG 3ch + ADPCM-B 1 part + rhythm 1 part = 11 part (= slot 9 J / slot 10 K)。 11 × 12 = 132 byte ≤ 256 byte (= v2 PartWork region 0xFD79-0xFE78、 ADR-0053 §決定 2 確保)、 残 124 byte は後続軸 future (= 20 part 想定で 240 byte ≤ 256 byte OK)。 既存 slot 0-8 layout 不変 |
| `standalone_test.s` 新 KIND .equ 2 件 | `PMDNEO_V2_KIND_ADPCMB` = 2 (= J part、 γ で実 dispatch) / `PMDNEO_V2_KIND_RHYTHM` = 3 (= K part、 δ で実 dispatch)。 既存 KIND=0 FM / KIND=1 SSG は ADR-0058 γ で magic 直接埋込み (= `pmdneo_v2_part_dispatch_note` の `or a / jr z` = KIND=0 判定)、 β では新規 KIND=2/3 のみ .equ 明示化 (= ADR-0059 §決定 2 literal)、 .equ 化 refactor は後続 sprint 候補 |
| `standalone_test.s` 新 ADPCM-B IX shim .equ | `pmdneo_v2_adpcmb_ix_shim` = 0xFD41 (= 32 byte shim base、 ADR-0059 §決定 3 案 Q 確定)。 既存 driver_state 拡張 region (= 0xFD39-0xFD78、 64 byte、 ADR-0053 §決定 2) 内に配置、 既配置 field (= 0xFD39-0xFD40 8 byte = fade_level/ssg_mixer/entry_marker/adpcmb_marker/rhythm_marker/song_state/tempo_acc/tempo_d) と非衝突、 残 free = 0xFD61-0xFD78 (= 24 byte、 後続軸 future) |
| SRAM layout comment | shim 配置 comment block 11 行 追加 (= ADPCM-B IX shim 経路 literal、 案 Q 採用理由)、 v2 PartWork compact slot layout comment update (= 12 byte × 11 = 132 byte ≤ 256 byte) |
| `standalone_test.s` `PMDNEO_V2_PART_OFF_NOTE` comment update | KIND=3 rhythm では bitmap として解釈 (= ADR-0059 §決定 5 案 A) literal 追記 |
| `standalone_test.s` `PMDNEO_V2_PART_OFF_KIND` comment update | KIND=0/1/2/3 = FM/SSG/ADPCM-B/rhythm literal 追記 |

### C-2: 実装詳細

- β は `.equ` 定数 4 件 (= shim base 1 + KIND 2 + PART_COUNT 値変更 1) のみ + comment block (= 11 行 shim 解説 + 既存 comment update)。 **active code 変更なし** (= γ/δ で active code 追加予定)
- `PMDNEO_V2_PART_COUNT` 9 → 11 は `.if TEST_MODE_V2_SONG_FIXTURE` 配下の `pmdneo_v2_song_init` clear loop (= `(PMDNEO_V2_PART_COUNT - 2)` = 7 → 9 計算) + `pmdneo_v2_song_dispatch` loop (= `#PMDNEO_V2_PART_COUNT` = 9 → 11 immediate) で参照される。 production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) では `.if` 配下全 routine 未 assemble = `PMDNEO_V2_PART_COUNT` 未参照 (= unused symbol) = sdasz80 が byte 非出力 = m1 binary byte-identical 維持 (= ADR-0053 β / ADR-0058 β と同 pattern)
- ADPCM-B IX shim 配置 (= 0xFD41) は既配置 field 8 byte (= 0xFD39-0xFD40) との非衝突確認済、 driver_state 拡張 region 64 byte 内に 32 byte 取得し残 24 byte free を後続軸 future へ温存
- 既存 `part_workarea` (= 0xF820-) は完全不可触 (= ADR-0058 §決定 8 + ADR-0059 §決定 3 案 Q 確定遵守)
- 既存 KIND=0/1 magic 直接埋込み (= ADR-0058 γ literal) は不変、 後続 refactor sprint で `.equ` 化候補 (= ADR-0059 §決定 2 literal)

### C-3: β 検証結果

- production build (= `TEST_MODE_V2_SONG_FIXTURE=0` default) **PASS** (= `bash scripts/build-poc.sh` 完走、 sdasz80 / sdldz80 / sdobjcopy / vromtool 全 step PASS)
- **m1 binary byte-identical** literal proof = `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で β 前 (= 27aad02 = α merge 直後) と β 後 (= 本 commit) が一致確認 (= `cmp -s` PASS、 git stash + build + sha256 比較 2 段 proof)
- binary 不変のため ADR-0049〜0058 baseline regression は trivially 維持 (= 同一 binary、 ADR-0053 β / ADR-0058 β と同 pattern、 verify script 別途実行不要)
- driver edit = `standalone_test.s` 1 file 35 行 + (= shim .equ block 11 行 + KIND .equ block 5 行 + PART_COUNT update 1 行 + comment update 数行)
- 既存 part_workarea / 既存 adpcmb_keyon body / 既存 pmdneo_rhythm_event_trigger body / ADR-0049〜0058 routine body / 軸 G ADR-0048 Draft + ε partial state / vendor / vromtool.py / compile.py 完全不可触
- 「軸 B 完成」 表現不使用、 「production-ready 全体達成」 表現禁止 継続

## Annex D: γ 実装 completion record (= ADPCM-B 実 dispatch wrapper + KIND=2 分岐 + slot 9 fixture)

### D-1: γ deliverable

軸 B production-ready roadmap ③ γ = ADPCM-B 実 dispatch 並設 + KIND=2 分岐 additive + slot 9 fixture init (= 39th session、 PR # 後続)。

| deliverable | 内容 |
|---|---|
| `pmdneo_v2_adpcmb_voice_note_song` 並設新設 (= `.if TEST_MODE_V2_SONG_FIXTURE` 配下) | A = song-driven note を保持、 push ix → ld ix #pmdneo_v2_adpcmb_ix_shim → shim PART_OFF_INSTRUMENT(ix) = 0 (= default voice index) → pop af で A 復元 → call adpcmb_keyon → pop ix → ret。 ADR-0059 §決定 4 案 b' 並設 + 案 Q shim 経路。 既存 `adpcmb_keyon` (= L3875) は本体不可触 call。 既存 `part_workarea` (= 0xF820-) は touch なし (= ADR-0058 §決定 8 維持) |
| `pmdneo_v2_part_dispatch_note` KIND=2 分岐 additive (= allowed-touch extension) | 既存 KIND=0 (= FM) / KIND=1 (= SSG) magic 直接埋込み path を保持しつつ、 cp #1 / cp #PMDNEO_V2_KIND_ADPCMB の 2 分岐を additive 追加。 KIND=2 ADPCM-B で `pmdneo_v2_adpcmb_voice_note_song` jp。 KIND=3 rhythm は δ で追加 (= 現状 silent ret)、 KIND>=4 silent ignore (= ADR-0059 §決定 6) |
| `pmdneo_v2_song_init` slot 9 = J part active init (= allowed-touch extension) | clear loop (= slot 2..PART_COUNT-1 FLAGS=0、 既存不変) の後ろに slot 9 active init を additive。 slot 9 base = 0xFDD1 (= partwork_base + 9*12)、 ADDR = `pmdneo_v2_song_fixture_adpcmb_j`、 KIND = `PMDNEO_V2_KIND_ADPCMB` (= 2)、 CH_IDX = 0 (= ADPCM-B chip 上 1 ch のみ)、 LOOP = fixture base、 FLAGS = 1 (= active、 ADR-0059 §決定 7) |
| `pmdneo_v2_song_fixture_adpcmb_j` 新設 (= `.if` 配下) | J part 用 fixture MML。 `.db 0x42, 0x20, 0x45, 0x20, 0x48, 0x20, 0x80`。 note byte 0x42/0x45/0x48 (= FM/SSG fixture と同 pattern、 既存 adpcmb_keyon の chromatic table 引きで delta-N に変換、 reg 0x19/0x1A に literal write)、 length 0x20 (= 32 tick、 FM/SSG fixture 0x10 より長)、 末尾 0x80 loop |

### D-2: 実装詳細

- **案 b' 並設採用** (= ADR-0058 γ FM/SSG wrapper と同 pattern): 既存 `adpcmb_keyon` body は完全不変、 新規 並設 routine `pmdneo_v2_adpcmb_voice_note_song` を `.if TEST_MODE_V2_SONG_FIXTURE` 配下で新設、 既存 caller (= `adpcmb_keyon_hook` L3773、 cmd 0x05 path 経由) は不変
- **案 Q shim 経路採用** (= ADR-0059 §決定 3): IX = `pmdneo_v2_adpcmb_ix_shim` (= 0xFD41-0xFD60、 32 byte) に向けて adpcmb_keyon を call。 shim `PART_OFF_INSTRUMENT(ix)` (= offset 31) に default voice 0 を write、 shim 他 field は touch しない (= adpcmb_keyon が read しないため)。 既存 `part_workarea` (= 0xF820-) 完全不可触
- **IX 退避** (= IRQ 経路 contract 継承): push ix / pop ix pair で v2 song_tick の IX/IY 退避 contract と同 pattern (= ADR-0058 δ 継承)
- **driver_pne_sample_table_id bit7=0 維持** (= ADR-0059 §決定 8 sup-sample-table-id-bit7-clear): shim 経由 path は default voice index 0 = ADR-0043 sample pointer literal table 引き = bit7=0 path、 軸 G dynamic supply 経路 (= bit7=1) は侵入させない
- **dispatch_note KIND 分岐拡張**: 既存 magic 0 jr z / jp ssg path を `cp #1 / cp #PMDNEO_V2_KIND_ADPCMB` の 2 分岐 additive へ拡張、 既存 KIND=0/1 dispatch 結果不変 (= 同 voice_note_song へ jp)、 新規 KIND=2 で ADPCM-B 並設 wrapper へ jp、 KIND=3+ は silent ret (= δ で KIND=3 追加予定)
- **slot 9 active init**: clear loop の後ろに additive、 init 順序 = ADDR/LEN/NOTE/CH_IDX/KIND/OCTAVE/LOOP/FLAGS の既存 slot 0/1 同 pattern。 BC = #pmdneo_v2_song_fixture_adpcmb_j で ADDR/LOOP 共に fixture base 設定
- **全 routine + fixture を `.if TEST_MODE_V2_SONG_FIXTURE` 配下に閉じ**: γ 新規 4 件 (= adpcmb wrapper + dispatch_note 拡張部分 + slot 9 init + fixture) 全て既存 `.if` 配下 = `=0` build (= production) で未 assemble = byte-identical 維持

### D-3: γ 検証結果

- production build (= `TEST_MODE_V2_SONG_FIXTURE=0` default): **PASS** + **m1 binary byte-identical** 維持 (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で α/β/γ 通算で同一 binary、 全 γ routine + dispatch_note KIND=2/3 分岐 + slot 9 init + fixture 全て `.if` 配下未 assemble proof)
- binary 不変のため ADR-0049〜0058 baseline regression は trivially 維持 (= 同一 binary)
- fixture build (= `TEST_MODE_V2_SONG_FIXTURE=1`) trace gate proof は ε で verify-axis-b-v2-roadmap3-dispatch.sh 体系化時に実施 (= ADR-0058 γ では γ 単体で verify-axis-b-v2-song-parse.sh 6 gate 同梱、 ADR-0059 §決定 1 sub-sprint 構成 = γ は driver 実装のみ + ε で verify 体系化 へ役割分離)
- driver edit = `standalone_test.s` 1 file 60 行 + (= adpcmb wrapper 24 行 + dispatch_note 拡張 12 行 + slot 9 init 24 行 + fixture 4 行 + comment)
- 既存 `adpcmb_keyon` body (= L3875) / `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 既存 part_workarea / cmd 0x05 path / irq_handler_body / ADR-0049〜0058 routine body (= allowed-touch 例外除く) / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触

## Annex E: δ 実装 completion record (= rhythm 実 dispatch wrapper + KIND=3 分岐 + slot 10 fixture)

### E-1: δ deliverable

軸 B production-ready roadmap ③ δ = rhythm 実 dispatch 並設 + KIND=3 分岐 additive + slot 10 fixture init (= 39th session、 PR # 後続)。

| deliverable | 内容 |
|---|---|
| `pmdneo_v2_rhythm_voice_note_song` 並設新設 (= `.if TEST_MODE_V2_SONG_FIXTURE` 配下) | A = song-driven bitmap (= v2 NOTE field 流用、 ADR-0059 §決定 5 案 A) を受領、 既存 `pmdneo_rhythm_event_trigger` (= L4616) を本体不可触 call、 ret。 IX 経由 read なし = shim 不要。 既存 routine は bit 0-5 を check し BD/SD/CYM/HH/TOM/RIM trigger emit (= ADPCM-A L ch reg 0x10/0x18/0x20/0x28/0x08/0x00 write、 ADR-0026〜0031 contract) |
| `pmdneo_v2_part_dispatch_note` KIND=3 分岐 additive (= allowed-touch extension) | γ で追加した KIND=2 分岐の後ろに KIND=3 分岐を additive。 cp #PMDNEO_V2_KIND_RHYTHM / jr z dispatch_note_rhythm / KIND>=4 silent ret。 既存 KIND=0/1/2 dispatch 結果不変 |
| `pmdneo_v2_song_init` slot 10 = K part active init (= allowed-touch extension) | slot 9 active init (= γ で追加) の後ろに additive。 slot 10 base = 0xFDDD (= partwork_base + 10*12)、 ADDR = `pmdneo_v2_song_fixture_rhythm_k`、 KIND = `PMDNEO_V2_KIND_RHYTHM` (= 3)、 CH_IDX = 0 (= rhythm L ch 暫定占有)、 LOOP = fixture base、 FLAGS = 1 |
| `pmdneo_v2_song_fixture_rhythm_k` 新設 | K part 用 fixture MML。 `.db 0x01, 0x10, 0x02, 0x10, 0x01, 0x10, 0x80`。 note byte = bitmap: 0x01 (= BD) → 0x02 (= SD) → 0x01 (= BD) → loop。 length 0x10、 末尾 0x80 = loop |

### E-2: 実装詳細

- **案 b' 並設採用** (= ADR-0058 γ FM/SSG + ADR-0059 γ ADPCM-B wrapper 同 pattern): 既存 routine body 完全不変、 並設 routine `pmdneo_v2_rhythm_voice_note_song` を `.if` 配下で新設
- **案 A bitmap 流用採用** (= ADR-0059 §決定 5): v2 NOTE field 1 byte を bitmap として解釈、 既存 slot layout 不変、 KIND 別解釈変更は dispatcher 責務
- **IX 退避不要** (= ADPCM-B wrapper との非対称): 既存 `pmdneo_rhythm_event_trigger` は A レジスタのみ受領、 IX 経路 read なし → wrapper で IX touch 不要
- **bitmap fixture pattern**: 0x01 (= BD) / 0x02 (= SD) で 2 種 drum 交互、 ADPCM-A L ch reg write の sample addr 切替を trace 観測可能 (= ε roadmap3-gate-2)
- **既存 `pmdneo_rhythm_event_trigger` 本体不可触 call**: ADR-0026〜0031 entry contract 不変、 ADPCM-A L ch reg sequence + sample addr 切替を emit、 driver-embedded `adpcma_sample_bd/sd` direct trigger
- **全 routine + fixture を `.if TEST_MODE_V2_SONG_FIXTURE` 配下に閉じ**: δ 新規 4 件全て `.if` 配下 = `=0` build で未 assemble = byte-identical 維持

### E-3: δ 検証結果

- production build (= `TEST_MODE_V2_SONG_FIXTURE=0` default): **PASS** + **m1 binary byte-identical** 維持 (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で α/β/γ/δ 通算同一 binary)
- binary 不変のため ADR-0049〜0058 baseline regression は trivially 維持 (= 同一 binary)
- fixture build trace gate proof は ε で verify-axis-b-v2-roadmap3-dispatch.sh 体系化時に実施
- driver edit = `standalone_test.s` 1 file 49 行 + (= rhythm wrapper 11 行 + dispatch_note 拡張 5 行 + slot 10 init 24 行 + fixture 9 行)
- 既存 `pmdneo_rhythm_event_trigger` body / `_rhythm_event_*_trigger` 全部 / `adpcma_sample_*` / KR_STUB.inc / 既存 `adpcmb_keyon` body / ADPCMB_DRV.inc / 既存 part_workarea / cmd 0x05 path / irq_handler_body / ADR-0049〜0058 routine body (= allowed-touch 例外除く) / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触

## Annex F: ε 実装 completion record (= verify script 体系化 + completion proof + slot base address 訂正注記)

### F-1: ε deliverable

軸 B production-ready roadmap ③ ε = verify script 体系化 (= 39th session、 PR # 後続)。

| deliverable | 内容 |
|---|---|
| `verify-axis-b-v2-roadmap3-dispatch.sh` 新規 (= 約 280 行) | ADR-0059 §決定 8 primary 7 gate (= `roadmap3-gate-1` ADPCM-B 実 dispatch / `roadmap3-gate-2` rhythm 実 dispatch / `roadmap3-gate-3` v2 song-driven 駆動 / `roadmap3-gate-4` baseline regression / `roadmap3-gate-5` .org + build-mode 排他 / `roadmap3-gate-6` 既存 routine 本体不可触 / `roadmap3-gate-7` Q shim 経路 + 既存 body call) + supplemental 5 gate (= `sup-stub-marker-regression` / `sup-IX/IY` / `sup-KIND-dispatch` / `sup-cold-boot` / `sup-sample-table-id-bit7-clear`) = **計 12 gate** に統合 + 末尾 completion proof line 13 行 literal (= ζ Annex 引用可能形式) |
| Annex F 追記 = ε completion + slot base address 訂正注記 | Annex D γ (= slot 9 base) / Annex E δ (= slot 10 base) 本文不変、 ε で発見した誤算を本 Annex F に訂正注記として記録 (= ADR-0058 ε rename 注記 pattern 同形式、 履歴改変 risk 回避) |

### F-2: 実装詳細

- **gate 整理**: §決定 8 primary 7 gate 命名 `roadmap3-gate-1〜7` で literal 統一 + supplemental 5 gate (= `sup-*` prefix) を末尾配置
- **stale trace 防止** (= ADR-0058 ε pattern 継承): 全 MAME invocation 前に `rm -rf $TRACE_DIR`
- **port B 3 桁 hex** (= 既存 step15/16/17 rhythm verify pattern 継承): ymfm-trace port B reg は `1XX` prefix (= ADPCM-A reg 0x10 = `"110"` / reg 0x18 = `"118"` / reg 0x00 = `"100"`)
- **sup-stub-marker-regression 静的 .lst 化** (= fixture build cmd 0x05 経路で `pmdneo_v2_entry_skeleton` 非経路のため runtime marker write 観測なし): 静的 .lst で stub routine 内 `ld (pmdneo_v2_adpcmb_marker),a` / `ld (pmdneo_v2_rhythm_marker),a` 存在を確認、 source level proof で ADR-0055 contract 維持
- **gate-6 git diff scan**: awk で diff scan (= pipefail + set -e で grep no-match 時の script exit 回避)、 既存 body 全 10 labels + ADPCMB_DRV.inc / KR_STUB.inc 不変 (= 27aad02..HEAD diff 0 lines)
- **completion proof line literal**: `FAIL=0` 通過時のみ 13 行 literal 出力 = NG なら gate failure で `ng` line + 末尾未達 = false PASS 不可
- **driver touch なし** (= ADR-0059 §決定 1 ε row literal 遵守 + §決定 10 不可触対象維持)

### F-3: slot base address 訂正注記 (= Annex D/E 履歴不変、 driver code は正しい)

ε で `verify-axis-b-v2-roadmap3-dispatch.sh` の trace 抽出時に発見した誤算を訂正注記として記録 (= ADR-0058 ε rename 注記 pattern と同形式、 Annex D γ / Annex E δ 本文の literal は当時の記録として維持、 履歴改変 risk 回避)。

| 対象 | Annex D/E literal (= 誤算) | 正算 | 根拠 |
|---|---|---|---|
| slot 9 base | 0xFDD1 | **0xFDE5** | `pmdneo_v2_partwork_base + 9*12 = 0xFD79 + 0x6C = 0xFDE5` (= 0xFD79 + 108 decimal) |
| slot 10 base | 0xFDDD | **0xFDF1** | `pmdneo_v2_partwork_base + 10*12 = 0xFD79 + 0x78 = 0xFDF1` |
| slot 9 FLAGS | (Annex D/E 内 literal なし) | **0xFDEE** | 0xFDE5 + OFF_FLAGS 9 = 0xFDEE |
| slot 10 FLAGS | (Annex D/E 内 literal なし) | **0xFDFA** | 0xFDF1 + OFF_FLAGS 9 = 0xFDFA |

**driver code は計算式 `(pmdneo_v2_partwork_base + 9*12)` / `(pmdneo_v2_partwork_base + 10*12)` を sdasz80 が assemble 時に計算するため正しい address (= 0xFDE5 / 0xFDF1) に init 命令を emit する**。 誤算は ADR-0059 Annex D/E doc の literal 表記のみ (= 計算式 vs literal の不整合)、 runtime 動作は正しい (= ε verify gate 1/3 で slot 9 ADDR lo @ 0xFDE5 uniq 8 件 + slot 10 ADDR lo @ 0xFDF1 uniq 8 件 = 0xFDE5/0xFDF1 が実 write address で確認済)。

ε 以降は本 Annex F の正算を ground truth とする。

### F-4: ε 検証結果 (= 12 gate ALL PASS literal + completion proof line)

- ε fixture build (= `PMDNEO_V2_SONG_FIXTURE=1` + ym2610): **PASS**
- production build (= `TEST_MODE_V2_SONG_FIXTURE=0`): **PASS**
- `verify-axis-b-v2-roadmap3-dispatch.sh` 12 gate **ALL PASS** literal:
  - roadmap3-gate-1 (ADPCM-B 実 dispatch): slot 9 ADDR lo (= 0xFDE5) uniq 8 件 + ADPCM-B reg write port A 188 件 (= 既存 adpcmb_keyon body 経由)
  - roadmap3-gate-2 (rhythm 実 dispatch): ADPCM-A L ch reg write port B (= reg 0x110/0x118/0x100、 = ADPCM-A reg 0x10/0x18/0x00) 218 件 + reg 0x110 sample START_LSB uniq value 2 件 (= BD/SD sample addr 切替 proof)
  - roadmap3-gate-3 (v2 song-driven 駆動): slot 9/10 ADDR lo uniq 各 8 件 + 両 slot FLAGS=01 active + fixture 進行 proof
  - roadmap3-gate-4 (baseline regression): verify-axis-b-v2-song-playback.sh 10 gate ALL PASS (= ADR-0049〜0058 transitively)
  - roadmap3-gate-5 (.org + build-mode 排他): 新 4 routine/fixture 全 >= 0x0610 + 0x0066 max 0xFD < 0x0100 + production build で 新 4 全 assemble なし
  - roadmap3-gate-6 (既存 routine 本体不可触): 既存 body 10 labels + ADPCMB_DRV.inc + KR_STUB.inc 全 不変
  - roadmap3-gate-7 (Q shim 経路 + body call): dispatch_note 内 ld a, PART_OFF_NOTE(iy) 4 箇所 + ld ix #pmdneo_v2_adpcmb_ix_shim + part_workarea write 不在 + call adpcmb_keyon + call pmdneo_rhythm_event_trigger + push ix / pop ix pair
  - sup-stub-marker-regression: 静的 .lst で adpcmb_dispatch + rhythm_dispatch stub 内 marker write 命令存在 (= ADR-0055 source 維持)
  - sup-IX/IY: ADPCM-B wrapper 内 push ix / pop ix pair
  - sup-KIND-dispatch: 4 KIND 分岐 (= 0/1/2/3) 全 jp 静的存在
  - sup-cold-boot: production build で `pmdneo_v2_song_init` 未 assemble
  - sup-sample-table-id-bit7-clear: 0xFD32 bit7=1 write 件数 = 0
- **completion proof line literal 出力** (= ε deliverable、 ζ Annex 引用可能形式):

```
=== roadmap ③ completion proof (ADR-0059 §決定 8 全 PASS = ζ Accepted 移行 ready) ===
§決定 8 gate 1 (ADPCM-B 実 dispatch):       PASS
§決定 8 gate 2 (rhythm 実 dispatch):        PASS
§決定 8 gate 3 (v2 song-driven 駆動):       PASS
§決定 8 gate 4 (baseline regression):        PASS
§決定 8 gate 5 (.org + build-mode 排他):    PASS
§決定 8 gate 6 (既存 routine 本体不可触):   PASS
§決定 8 gate 7 (Q shim 経路 + body call):   PASS
supplemental gate stub-marker-regression:   PASS
supplemental gate IX/IY:                    PASS
supplemental gate KIND-dispatch:            PASS
supplemental gate cold-boot:                PASS
supplemental gate sample-table-id-bit7-clear: PASS
ζ Accepted 移行 ready: yes (ADR-0059 §決定 1 ε 完了)
```

## Annex G: ζ 完了確認 + Draft → Accepted 移行 record

### G-1: α〜ε 全 sub-sprint 完走 summary

| sub | PR | 完了内容 |
|---|---|---|
| α | PR #102 | 起票 doc-only filing (= 決定 1-12 + 6 段 α/β/γ/δ/ε/ζ + v2 PartWork 9 → 11 + KIND=2/3 + ADPCM-B IX shim 0xFD41-0xFD60 (= 案 Q) + 並設 wrapper 2 件 (案 b') + KIND 分岐 + slot 9/10 fixture init (= allowed-touch extension) + ADR-0055 stub marker (= 0xFD3C/0xFD3D) regression 維持 + verify gate primary 7 + supplemental 5 + scope-in/out + non-goal、 Codex layer 2 起票 plan review 2 round + doc review 2 round) |
| β | PR #103 | v2 PartWork 11 拡張 + KIND .equ + ADPCM-B IX shim .equ (= standalone_test.s 1 file 35 行 +、 PMDNEO_V2_PART_COUNT 9→11 + PMDNEO_V2_KIND_ADPCMB=2 + PMDNEO_V2_KIND_RHYTHM=3 + pmdneo_v2_adpcmb_ix_shim=0xFD41 + SRAM layout comment 11 行、 active code 変更なし)。 production build PASS + m1 binary byte-identical (= sha256 b15883fe...)、 Codex layer 2 β 実装 review 2 round approve |
| γ | PR #104 | ADPCM-B 実 dispatch 並設 + KIND=2 分岐 + slot 9 fixture init (= standalone_test.s 1 file 60 行 +、 全 `.if TEST_MODE_V2_SONG_FIXTURE` 配下、 pmdneo_v2_adpcmb_voice_note_song 並設 + 既存 adpcmb_keyon 本体不可触 call + Q shim 経路 + dispatch_note KIND=2 分岐 + slot 9 active init + fixture_adpcmb_j)。 production build PASS + m1 binary byte-identical 維持、 Codex layer 2 γ 実装 review async + 主軸自律 approve |
| δ | PR #105 | rhythm 実 dispatch 並設 + KIND=3 分岐 + slot 10 fixture init (= standalone_test.s 1 file 49 行 +、 全 `.if` 配下、 pmdneo_v2_rhythm_voice_note_song 並設 + 既存 pmdneo_rhythm_event_trigger 本体不可触 call + 案 A v2 NOTE bitmap 流用 + dispatch_note KIND=3 分岐 + slot 10 active init + fixture_rhythm_k BD/SD bitmap)。 production build PASS + m1 binary byte-identical 維持 |
| ε | PR #106 | verify script 体系化 + 12 gate ALL PASS + slot base address 訂正注記 (= verify-axis-b-v2-roadmap3-dispatch.sh 約 280 行 + ADR-0059 Annex F)。 primary 7 + supplemental 5 = 12 gate ALL PASS literal + completion proof line 13 行 literal 出力。 slot 9 base = 0xFDD1 → 0xFDE5、 slot 10 base = 0xFDDD → 0xFDF1 訂正注記 (= Annex D/E 本文不変、 履歴改変 risk 回避)、 Codex layer 2 ε 実装 review approve + nice-to-have 3 件反映 |

### G-2: ε completion proof line literal 引用 (= roadmap ③ 全 gate ALL PASS literal、 Annex F-4 から literal copy)

ε で `bash src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh` 実行時の末尾出力:

```
=== roadmap ③ completion proof (ADR-0059 §決定 8 全 PASS = ζ Accepted 移行 ready) ===
§決定 8 gate 1 (ADPCM-B 実 dispatch):       PASS
§決定 8 gate 2 (rhythm 実 dispatch):        PASS
§決定 8 gate 3 (v2 song-driven 駆動):       PASS
§決定 8 gate 4 (baseline regression):        PASS
§決定 8 gate 5 (.org + build-mode 排他):    PASS
§決定 8 gate 6 (既存 routine 本体不可触):   PASS
§決定 8 gate 7 (Q shim 経路 + body call):   PASS
supplemental gate stub-marker-regression:   PASS
supplemental gate IX/IY:                    PASS
supplemental gate KIND-dispatch:            PASS
supplemental gate cold-boot:                PASS
supplemental gate sample-table-id-bit7-clear: PASS
ζ Accepted 移行 ready: yes (ADR-0059 §決定 1 ε 完了)
```

= ε commit chain で literal 出力済 + Annex F-4 に literal 記録済 = **ζ Accepted 移行 ready signal**。

### G-3: Draft → Accepted 移行根拠

- ADR-0059 §決定 1 ζ row literal 完了判定 = 「全 sub α〜ε verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由)」 を満たす
- ε で `verify-axis-b-v2-roadmap3-dispatch.sh` 12 gate + completion proof line ALL PASS literal 出力済 (= G-2)
- 「ζ Accepted 移行 ready: yes (ADR-0059 §決定 1 ε 完了)」 literal signal が ε commit chain で出力 + Annex F-4 に literal 記録済
- Codex layer 2 chain = α plan review 2 round + α doc review 2 round + β 実装 review 2 round approve + γ 実装 review async + 主軸自律 approve + δ 実装 review async + 主軸自律 approve + ε 実装 review approve + nice-to-have 3 件反映
- 全 sub-sprint 規律遵守 = 既存 `adpcmb_keyon` body / 既存 `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 既存 `part_workarea` / cmd 0x05 path / `irq_handler_body` / ADR-0049〜0058 routine body (= allowed-touch 例外除く) / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触 + production byte-identical 維持 (= m1 sha256 b15883fe... 通算同一)

### G-4: Accepted 表記制約 (= ADR-0058 ζ pattern 継承)

ADR-0058 ζ の user 明示制約 3 件を ADR-0059 ζ でも継承:

1. **ADR-0059 Accepted = roadmap ③「ADPCM-B/rhythm 実 dispatch」 完了** (= design + 実装 + verify 完走)
2. **「production-ready 全体達成」 と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ③ で未実施、 roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ④ 完走後の future)
3. **「軸 B 完成」 表現禁止 継続** (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過)

### G-5: ζ deliverable

| deliverable | 内容 |
|---|---|
| 状態行 prefix `**Draft**` → `**Accepted**` | + ε 完了確認 + roadmap ③ design+実装+verify 完了 literal + production-ready 全体達成ではない literal + 「軸 B 完成」 表現不使用 literal |
| Annex G 新規 | 本 record (= G-1 α〜ε summary + G-2 completion proof line literal 引用 + G-3 Accepted 移行根拠 + G-4 表記制約 literal + G-5 deliverable + G-6 scope-out) |
| sub-sprint chain ζ 行 = 未着手 → 完了 | PR # 後続 + Codex layer 2 ζ doc review (= 後続 commit 後投入) |
| 改訂履歴 ζ 行追加 | Draft → Accepted 移行 + Accepted = roadmap ③ design+実装 完了 literal + production-ready 全体達成と書かない literal + 「軸 B 完成」 表現禁止 継続 literal |
| 平易要約 ζ 完了 reflect | 「ε 完了 + ADR-0059 Draft → Accepted = roadmap ③ 完了」 + 「production-ready 全体達成は roadmap ④ + 越川氏 audition 後の future」 literal |
| dashboard 軸 B 行 status column update | `0059 Draft (= roadmap ③)` → `0059 Accepted (= roadmap ③ = ADPCM-B/rhythm 実 dispatch 完了)` |
| dashboard 進行履歴 ζ 行追加 | ζ Draft → Accepted 移行 + 表記制約 literal |
| dashboard 予約簿 0059 update | ε 完了 + 残 ζ → ζ 完了 + ADR-0059 Accepted + production-ready 全体達成ではない literal |

### G-6: ζ で扱わない (= scope-out)

- driver / verify script / vendor / build flag / SRAM / .equ 一切 touch なし
- Annex A〜F 本文不変 (= 履歴改変 risk 回避、 ADR-0058 ζ 同 pattern)
- production-ready 全体達成宣言 (= roadmap ④ + audition 残)
- roadmap ④ 軸 G dynamic supply 着手
- 越川氏 audition 着手

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) の rhythm (= ドラム) と ADPCM-B (= 単音 ADPCM) を、 これまでの「ここに来ました証拠の SRAM マーカーを書くだけ」 から「実際の既存 ADPCM-B / rhythm ルーチンを呼び出して音を出す」 へ昇格させる。 既存ルーチンの中身は完全に触らず、 v2 側から呼ぶだけ。

**前提**: roadmap ① (= FM/SSG 実音) + roadmap ② (= 曲解釈 + 周期再生 + IRQ 連携) は完了済。 v2 はもう「FM と SSG で時間進行する MML 曲」 を鳴らせる。 ただし ADPCM-B と rhythm はまだスタブ (= マーカー書くだけ)。 本 ADR-0059 = roadmap ③ = この 2 つを実 dispatch 化する。

**今回の範囲**: ① v2 のパート枠を 9 → 11 個に拡張 (= ADPCM-B 用 J + rhythm 用 K)、 ② パート種別 (KIND) に 2 (ADPCM-B) と 3 (rhythm) を追加、 ③ v2 ADPCM-B ラッパールーチンを並設 (= 既存 `adpcmb_keyon` を呼ぶための「IX 用の領域 (= shim)」 32 byte を v2 driver_state に確保 + 既存 routine を本体不可触で call)、 ④ v2 rhythm ラッパールーチンを並設 (= 既存 `pmdneo_rhythm_event_trigger` を A=bitmap で本体不可触 call)、 ⑤ 検証スクリプトを整備 (= primary 7 + supplemental 5 = 12 gate)。

**触らないもの**: 既存 `adpcmb_keyon` 本体、 既存 `pmdneo_rhythm_event_trigger` 本体、 既存 ADPCM-B / rhythm の sample table、 既存 part_workarea (= 0xF820-)、 既存 cmd 0x05 経路、 軸 G の Draft 状態、 ADR-0049〜0058 のルーチン本体 (= ただし `pmdneo_v2_song_init` と `pmdneo_v2_part_dispatch_note` は KIND 分岐拡張 + slot 9/10 init 追加のため allowed-touch 例外として明示)。 全部 build-mode 排他 (= `TEST_MODE_V2_SONG_FIXTURE=0` で全部 assemble されない) で production byte-identical 維持。

**進捗 (= α 起票)**: α で設計書 (= 本 ADR-0059) を起票し、 roadmap ③ scope / 設計 / 検証方法 / 不可触対象 / 規律を文書で固定した。 IX 経路問題 = 既存 `adpcmb_keyon` は IX を経由するけど v2 PartWork は 12 byte で incompatible のため案 Q (= v2 driver_state 内に 32 byte の shim を新設) を採用。 rhythm note 解釈 = v2 NOTE field 1 byte を bitmap として流用する案 A 採用。 verify gate = ADR-0058 ε と同形式の primary 7 + supplemental 5、 末尾に completion proof line 13 行で ζ Accepted ready signal。

**進捗 (= α/β 完了)**: α (= PR #102) で設計書 (= 本 ADR-0059) を起票し、 roadmap ③ scope / 設計 / 検証方法 / 不可触対象 / 規律を文書で固定した (= Codex layer 2 doc review 2 round chain approve)。 β (= PR #103) で driver `standalone_test.s` に `.equ` 4 件 (= `PMDNEO_V2_PART_COUNT` 9 → 11 + `PMDNEO_V2_KIND_ADPCMB` 2 + `PMDNEO_V2_KIND_RHYTHM` 3 + `pmdneo_v2_adpcmb_ix_shim` 0xFD41) + SRAM layout comment 11 行を追加。 production build PASS + **m1 binary byte-identical** (= sha256 b15883fe... 一致、 β 前後で同一 binary、 unused `.equ` は sdasz80 byte 非出力)。 既存 part_workarea / 既存 adpcmb_keyon body / 既存 pmdneo_rhythm_event_trigger body / ADR-0049〜0058 routine body / 軸 G Draft + ε partial state / vendor 完全不可触。

**γ/δ 完了**: γ で driver `standalone_test.s` に ADPCM-B ラッパー (= `pmdneo_v2_adpcmb_voice_note_song` 並設、 既存 `adpcmb_keyon` 本体不可触 call、 案 Q shim 経由) + KIND=2 分岐 + slot 9 fixture init を追加。 δ で rhythm ラッパー (= `pmdneo_v2_rhythm_voice_note_song` 並設、 既存 `pmdneo_rhythm_event_trigger` 本体不可触 call、 案 A v2 NOTE bitmap 流用) + KIND=3 分岐 + slot 10 fixture init を追加。 production build PASS + m1 binary byte-identical 維持 (= sha256 b15883fe... α/β/γ/δ 通算同一)。

**ε 完了**: `verify-axis-b-v2-roadmap3-dispatch.sh` を新設 = §決定 8 primary 7 gate + supplemental 5 gate = 計 12 gate に統合 + 末尾 completion proof line 13 行 literal 出力 (= ζ Accepted 移行 ready signal)。 全 12 gate ALL PASS literal 確認。 slot 9/10 base address の Annex D/E 誤算 (= 0xFDD1/0xFDDD) を訂正注記 (= 正算 0xFDE5/0xFDF1、 driver code は計算式で正しく emit、 Annex F-3 literal)。

**ζ 完了 (= Draft → Accepted 移行)**: ADR-0059 を Draft → Accepted へ移行。 Accepted = 「roadmap ③「ADPCM-B/rhythm 実 dispatch」 完了」 (= design + 実装 + verify 完走、 = 6 sub-sprint α/β/γ/δ/ε/ζ 全完走 + ε 12 gate + completion proof line ALL PASS literal 出力)。 doc-only filing (= 主軸直接 edit、 Annex A〜F 本文不変)。 **重要 = production-ready 全体達成と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ③ で未実施、 roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ④ 完走後の future)。 「軸 B 完成」 表現禁止 継続。

**次**: ADR-0059 Accepted 後の候補 = roadmap ④ 軸 G dynamic supply 着手 / production-ready gate 4 系統判定 (= 越川氏 audition 含む) は roadmap ④ 完走後の future。 別軸 (= 軸 G ζ defer 等) 着手判断は user。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0059 起票) | **完了** (= 39th session、 PR #102) | PR #102 | 起票 plan review 2 round chain = round 1 revise (= JP1 案 P→Q + IX read 事実修正 + slot9 アドレス削除 + untouchable narrowing + gate-7 追加 + 3 nice-to-have) → 全 8 件反映 revised plan → round 2 投入 (= async notification、 主軸自律 approve based on round 1 feedback 全反映 = non-stop model)、 起票 doc review 2 round chain = round 1 revise 3 must-fix (= 0xFA60 stale literal 削除 L101 + gate-7 grep 例 L194 + §決定 11 dashboard 変更内容整合 L262) + 1 nice-to-have (= PR # 後続 → PR #102) 全反映 → round 2 **approve** (= must-fix 4 件全件 pass evidence + 新規 risk なし + doc-only 規律 PASS + β 自律進行 GO) |
| β (= v2 PartWork 11 + KIND + shim .equ) | **完了** (= 39th session、 PR #103) | PR #103 | β 実装 review 2 round chain = round 1 revise 2 must-fix (= L320 SRAM layout shim range comment + Annex C との range 表記整合) + 2 nice-to-have (= clear loop comment update + PR # 後続 → PR #103) 全反映 → round 2 投入予定 (= must-fix 反映後) |
| γ (= ADPCM-B 実 dispatch) | **完了** (= 39th session、 PR # 後続) | PR # 後続 | γ 実装 review (= 後続 commit 後投入) |
| δ (= rhythm 実 dispatch) | **完了** (= 39th session、 PR # 後続) | PR # 後続 | δ 実装 review (= 後続 commit 後投入) |
| ε (= verify script 体系化) | **完了** (= 39th session、 PR # 後続) | PR # 後続 | ε 実装 review (= 後続 commit 後投入) |
| ζ (= completion + Draft → Accepted 判断) | **完了** (= 39th session、 PR # 後続) | PR # 後続 | ζ kickoff plan 主軸自律 (= ADR-0058 ζ pattern 同形式、 doc-only completion + Annex G + 状態行 Draft → Accepted + dashboard 同期 + 主軸直接 edit) → Codex layer 2 ζ doc review (= 後続 commit 後投入) |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | ζ Draft → Accepted 移行 (= 39th session、 PR # 後続) | ADR-0059 を Draft → Accepted へ移行 = ADR-0059 Accepted = roadmap ③「ADPCM-B/rhythm 実 dispatch」 完了 (= design + 実装 + verify 完走、 = 6 sub-sprint α/β/γ/δ/ε/ζ 全完走 + ε で verify-axis-b-v2-roadmap3-dispatch.sh 12 gate + completion proof line ALL PASS literal 出力 + 「ζ Accepted 移行 ready: yes」 signal)。 doc-only filing (= 主軸直接 edit、 Annex A〜F 本文不変 = 履歴改変 risk 回避、 ADR-0058 ζ pattern 同形式)。 Annex G 新規追加 (= G-1 α〜ε 全 sub-sprint 完走 summary + G-2 ε completion proof line literal 引用 13 行 + G-3 Draft → Accepted 移行根拠 = §決定 1 ζ row + ε ALL PASS + Codex chain + 規律遵守 literal + G-4 Accepted 表記制約 = ADR-0058 ζ 継承 = 3 件 (ADR-0059 Accepted = roadmap ③ 完了 + production-ready 全体達成と書かない + 「軸 B 完成」 表現禁止 継続) + G-5 deliverable + G-6 scope-out) + sub-sprint chain ζ 行 完了 reflect + 状態行 Draft → Accepted + 平易要約 ζ 完了 reflect + dashboard 軸 B 行 status column update + 進行履歴 ζ 行 + 予約簿 0059 update。 **重要 = production-ready 全体達成と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統のうち越川氏 audition は roadmap ③ で未実施、 roadmap ④ 軸 G 未着手 = production-ready 全体達成は roadmap ④ 完走後の future)。 **「軸 B 完成」 表現禁止 継続** (= 軸 B は v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過)。 既存 driver / verify script / vendor / build flag / SRAM 一切 touch なし。 既存 `adpcmb_keyon` body / 既存 `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 既存 part_workarea / cmd 0x05 path / `pmdneo_v2_*` routine + ADR-0049〜0058 + 軸 G ADR-0048 Draft + ε partial state + vendor 完全不可触 (= 全 sub-sprint chain 通算)。 Codex layer 2 = ζ kickoff plan 主軸自律 + ζ doc review (= 後続 commit 後投入) |
| 2026-05-23 | ε 実装完了 (= 39th session、 PR # 後続) | verify script 体系化 + completion proof + slot base address 訂正注記。 `src/test-fixtures/axis-b/verify-axis-b-v2-roadmap3-dispatch.sh` 新規 (= 約 280 行) で ADR-0059 §決定 8 primary 7 gate (= roadmap3-gate-1〜7) + supplemental 5 gate (= sup-*) = **計 12 gate** 統合 + 末尾 completion proof line 13 行 literal 出力 (= ζ Accepted 移行 ready signal)。 ADR-0059 Annex F 追記 (= ε completion + 実装詳細 + slot base address 訂正注記 + 検証結果 + completion proof line literal)。 **slot base address 訂正注記** = Annex D γ literal `slot 9 base = 0xFDD1` / Annex E δ literal `slot 10 base = 0xFDDD` は誤算 (= 0xFD79 + 9*12 / 10*12 計算誤り)、 正は **slot 9 base = 0xFDE5 / slot 10 base = 0xFDF1**。 driver code は計算式 `(pmdneo_v2_partwork_base + 9*12)` / `(pmdneo_v2_partwork_base + 10*12)` を sdasz80 が assemble 時に計算するため正しい address に init 命令を emit する (= runtime 動作は正しい、 誤算は doc literal 表記のみ)。 ε verify gate-1/3 で slot 9 ADDR lo @ 0xFDE5 uniq 8 件 + slot 10 ADDR lo @ 0xFDF1 uniq 8 件 = 0xFDE5/0xFDF1 が実 write address で確認済。 Annex D/E 本文は履歴改変 risk 回避のため不変、 ε 以降は Annex F 正算を ground truth とする (= ADR-0058 ε rename 注記 pattern 同形式)。 sub-sprint chain ε 完了 reflect + 改訂履歴 ε entry。 検証 = ε fixture build PASS + production build PASS + 12 gate ALL PASS literal (= roadmap3-gate-1 slot 9 ADDR uniq 8 + ADPCM-B reg write 188 件 / roadmap3-gate-2 ADPCM-A L ch reg write port B 218 件 + sample START_LSB uniq 2 件 BD/SD 切替 / roadmap3-gate-3 slot 9/10 FLAGS=01 active + ADDR 進行 / roadmap3-gate-4 verify-axis-b-v2-song-playback.sh 10 gate / roadmap3-gate-5 .org overflow なし + production assemble なし / roadmap3-gate-6 既存 body 10 labels + ADPCMB_DRV.inc + KR_STUB.inc 不変 / roadmap3-gate-7 dispatch_note 経路 + Q shim 経路 + 既存 body call 5 点 / sup-stub-marker static .lst proof / sup-IX/IY / sup-KIND-dispatch 4 KIND 分岐 / sup-cold-boot production 未 assemble / sup-sample-table-id-bit7-clear 0 件) + completion proof line 13 行 literal 出力 (= ζ Annex 引用可能形式)。 driver / SRAM / .equ / build flag / vendor 一切 touch なし (= ε row literal、 ADR-0059 §決定 1 遵守)、 既存 cmd 0x05 path + ADR-0049〜0058 routine body (= allowed-touch 例外除く) + 軸 C/G/rhythm + vendor 完全不可触、 Annex D (γ) / Annex E (δ) 本文不変 (= 履歴改変 risk 回避)、 「軸 B 完成」 表現不使用継続。 Codex layer 2 = ε 実装 review (= 後続 commit 後投入)。 軸 B roadmap ③ ε、 残 ζ (= Draft → Accepted 移行)、 「軸 B 完成」 表現不使用 (= roadmap ④ + 越川氏 audition 残る) |
| 2026-05-23 | δ 実装完了 (= 39th session、 PR # 後続) | rhythm 実 dispatch wrapper 並設 + KIND=3 分岐 additive + slot 10 fixture init。 `standalone_test.s` 1 file edit (= 49 行 +、 全て `.if TEST_MODE_V2_SONG_FIXTURE` 配下): (1) `pmdneo_v2_rhythm_voice_note_song` 並設新設 (= 案 b' + A=bitmap、 既存 `pmdneo_rhythm_event_trigger` body L4616 不可触 call、 IX 退避不要) (2) `pmdneo_v2_part_dispatch_note` KIND=3 分岐 additive (= allowed-touch extension、 cp #PMDNEO_V2_KIND_RHYTHM jr z 追加、 既存 KIND=0/1/2 path 不変、 KIND>=4 silent ret) (3) `pmdneo_v2_song_init` slot 10 = K part active init 追加 (= allowed-touch extension、 slot 9 init 後 additive、 ADDR/LOOP = fixture base / KIND=3 / CH_IDX=0 rhythm L ch 暫定占有 / FLAGS=1) (4) `pmdneo_v2_song_fixture_rhythm_k` 新設 (= `.db 0x01, 0x10, 0x02, 0x10, 0x01, 0x10, 0x80`、 bitmap fixture = BD → SD → BD → loop、 length 0x10、 末尾 0x80 loop、 ADR-0059 §決定 5 案 A v2 NOTE bitmap 流用)。 Annex E 追記 (= δ completion + deliverable + 実装詳細 + 検証結果) + sub-sprint chain δ 完了 reflect + 改訂履歴 δ entry。 検証 = production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) PASS + **m1 binary byte-identical** 維持 (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で α/β/γ/δ 通算同一 binary、 全 δ routine + dispatch_note KIND=3 分岐 + slot 10 init + fixture 全て `.if` 配下未 assemble proof)。 既存 `pmdneo_rhythm_event_trigger` body / `_rhythm_event_*_trigger` 全部 / `adpcma_sample_*` / KR_STUB.inc / 既存 `adpcmb_keyon` body / ADPCMB_DRV.inc / 既存 part_workarea / cmd 0x05 path / irq_handler_body / ADR-0049〜0058 routine body (= allowed-touch 例外除く) / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触。 fixture build trace gate proof は ε で verify-axis-b-v2-roadmap3-dispatch.sh 体系化時に実施 (= ADR-0059 §決定 1 sub-sprint 役割分離)。 Codex layer 2 = δ 実装 review (= 後続 commit 後投入)。 軸 B roadmap ③ δ、 残 ε/ζ、 「軸 B 完成」 表現不使用 (= v2 driver production-ready 化 + roadmap ④ + 越川氏 audition 残る) |
| 2026-05-23 | γ 実装完了 (= 39th session、 PR # 後続) | ADPCM-B 実 dispatch wrapper 並設 + KIND=2 分岐 additive + slot 9 fixture init。 `standalone_test.s` 1 file edit (= 60 行 +、 全て `.if TEST_MODE_V2_SONG_FIXTURE` 配下): (1) `pmdneo_v2_adpcmb_voice_note_song` 並設新設 (= 案 b' + 案 Q shim 経路、 push ix → ld ix #pmdneo_v2_adpcmb_ix_shim → shim PART_OFF_INSTRUMENT(ix)=0 → call adpcmb_keyon → pop ix、 既存 `adpcmb_keyon` body L3875 不可触 call) (2) `pmdneo_v2_part_dispatch_note` KIND=2 分岐 additive (= allowed-touch extension、 cp #1 / cp #PMDNEO_V2_KIND_ADPCMB の 2 分岐追加、 既存 KIND=0/1 path 不変、 KIND=3+ silent ret) (3) `pmdneo_v2_song_init` slot 9 = J part active init 追加 (= allowed-touch extension、 clear loop の後ろに additive、 ADDR/LOOP = fixture base / KIND=2 / FLAGS=1) (4) `pmdneo_v2_song_fixture_adpcmb_j` 新設 (= `.db 0x42, 0x20, 0x45, 0x20, 0x48, 0x20, 0x80`、 note byte は既存 adpcmb_keyon chromatic table 引きで delta-N 変換、 length 0x20、 末尾 0x80 loop)。 Annex D 追記 (= γ completion + deliverable + 実装詳細 + 検証結果) + sub-sprint chain γ 完了 reflect + 改訂履歴 γ entry。 検証 = production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) PASS + **m1 binary byte-identical** 維持 (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で α/β/γ 通算同一 binary、 全 γ routine + dispatch_note 拡張 + slot 9 init + fixture 全て `.if` 配下未 assemble proof)。 既存 `adpcmb_keyon` body / `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 既存 part_workarea / cmd 0x05 path / irq_handler_body / ADR-0049〜0058 routine body (= allowed-touch 例外除く) / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触。 fixture build trace gate proof は ε で verify-axis-b-v2-roadmap3-dispatch.sh 体系化時に実施 (= γ 単体 verify script 不同梱 = ADR-0059 §決定 1 sub-sprint 役割分離)。 Codex layer 2 = γ 実装 review (= 後続 commit 後投入)。 軸 B roadmap ③ γ、 残 δ/ε/ζ、 「軸 B 完成」 表現不使用 (= v2 driver production-ready 化 + roadmap ③/④ + 越川氏 audition 残る) |
| 2026-05-23 | β 実装完了 (= 39th session、 PR #103) | v2 PartWork 11 拡張 + KIND=2/3 .equ + ADPCM-B IX shim 0xFD41-0xFD60 .equ。 `standalone_test.s` 1 file edit (= 35 行 +): (1) `PMDNEO_V2_PART_COUNT` 9 → **11** (= FM 6ch + SSG 3ch + ADPCM-B 1 + rhythm 1 = 132 byte ≤ 256 byte region、 ADR-0059 §決定 2) (2) `PMDNEO_V2_KIND_ADPCMB` = 2 / `PMDNEO_V2_KIND_RHYTHM` = 3 .equ 新規 (= 既存 KIND=0/1 magic 直接埋込み不変、 後続 refactor 候補、 ADR-0059 §決定 2 literal) (3) `pmdneo_v2_adpcmb_ix_shim` = 0xFD41 .equ 新規 (= 32 byte shim、 ADR-0059 §決定 3 案 Q 確定、 既存 part_workarea 不可触遵守、 残 free 0xFD61-0xFD78 24 byte) (4) `PART_OFF_NOTE` / `PART_OFF_KIND` comment update (= KIND=3 rhythm bitmap 解釈 + KIND=0/1/2/3 enumeration literal、 ADR-0059 §決定 5 案 A / §決定 2) (5) SRAM layout shim 配置 comment 11 行追加 (= ADPCM-B IX shim 経路 literal、 案 Q 採用理由 / 配置 / size / 不可触対象) (6) v2 PartWork compact slot layout comment update (= 12 byte × 11 = 132 byte ≤ 256 byte、 残 124 byte 後続軸 future)。 Annex C 追記 (= β completion + deliverable + 実装詳細 + 検証結果) + sub-sprint chain β 完了 reflect + 平易要約 β 完了 reflect。 検証 = production build (= `TEST_MODE_V2_SONG_FIXTURE=0`) PASS + **m1 binary byte-identical** (= `sha256(243-m1.m1) = b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` で β 前後 (= 27aad02 vs 本 commit) 一致確認、 `cmp -s` PASS、 git stash + build + sha256 比較 2 段 proof、 unused `.equ` symbol は sdasz80 が byte 非出力 = ADR-0053 β / ADR-0058 β と同 pattern)。 binary 不変のため ADR-0049〜0058 baseline regression は trivially 維持 (= 同一 binary)。 既存 `pmdneo_song_main` / `pmdneo_part_main` / `commandsp` / `part_workarea` / `irq_handler_body` 既存処理 / ADR-0049〜0058 routine body (= allowed-touch 例外除く) + 既存 `adpcmb_keyon` body / 既存 `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 軸 G ADR-0048 Draft + ε partial state / vendor 完全不可触。 active code 変更なし (= γ/δ で active code 追加予定 = wrapper 並設 + KIND 分岐 + slot 9/10 init)。 Codex layer 2 = β 実装 review (= 後続 commit 後投入)。 軸 B roadmap ③ β、 残 γ/δ/ε/ζ、 「軸 B 完成」 表現不使用 (= v2 driver production-ready 化 + roadmap ③/④ + 越川氏 audition 残る) |
| 2026-05-23 | Draft 起票 (= 39th session 軸 B production-ready roadmap ③ α) | roadmap ③ ADPCM-B/rhythm 実 dispatch の実装 ADR を起票。 ADR-0056 §決定 4 roadmap ③ literal 後続実装 ADR。 ADR-0058 Accepted (= roadmap ②) 後の次フェーズ。 決定 1-12 + 6 段 sub-sprint α/β/γ/δ/ε/ζ + v2 PartWork 9 → 11 拡張 + KIND=2/3 .equ 定数追加 + ADPCM-B IX shim 0xFD41-0xFD60 (= 32 byte、 案 Q 確定) + `pmdneo_v2_adpcmb_voice_note_song` 並設 (= 既存 `adpcmb_keyon` 本体不可触 call) + `pmdneo_v2_rhythm_voice_note_song` 並設 (= 既存 `pmdneo_rhythm_event_trigger` 本体不可触 call、 案 A v2 NOTE bitmap 流用) + `pmdneo_v2_part_dispatch_note` KIND=2/3 分岐 additive + `pmdneo_v2_song_init` slot 9/10 fixture init 拡張 + clear loop 範囲調整 (= allowed-touch extension points 明示) + ADR-0055 stub marker (= 0xFD3C/0xFD3D) regression 維持 + verify gate = primary 7 (= roadmap3-gate-1〜7) + supplemental 5 (= stub-marker-regression / IX/IY / KIND-dispatch / cold-boot / sample-table-id-bit7-clear) + completion proof line 13 行 + scope-in/out + non-goal + 不可触対象 (= allowed-touch narrowing) + production byte-identical 維持 + 「軸 B 完成」 表現禁止継続 + 「production-ready 全体達成」 表現禁止 + Codex rescue 化 + 非 stop model 継承。 doc-only filing (= ADR-0059 + dashboard のみ変更)。 Codex layer 2 起票 plan review 2 round chain = round 1 revise (= 5 must-fix + 3 nice-to-have = JP1 案 P→Q (= v2 driver_state shim) + IX read 事実修正 (= IX+31 PART_OFF_INSTRUMENT のみ read、 note=A レジスタ経由、 CH_IDX read 不在) + slot9 アドレス記述削除 + untouchable narrowing (= `pmdneo_v2_song_init` / `pmdneo_v2_part_dispatch_note` allowed-touch 明示) + gate-7 新設 (= Q shim 経路 + 既存 body call 静的確認 5 点) + sup-sample-table-id-bit7-clear 新設 + stale trace 防止 + sup-cold-boot wording clarify) → 全 8 件反映 revised plan → round 2 投入 (= async notification 仕様、 主軸自律 approve based on round 1 feedback 全反映 = non-stop model、 ζ 完了時 Codex doc review で最終整合 verify 予定)。 roadmap ③ は production-ready 全体達成宣言ではない (= roadmap ④ 軸 G + 越川氏 audition が残る、 ADR-0056 §決定 3 production-ready gate 4 系統)、 「軸 B 完成」 表現不使用継続 (= v2 driver production-ready 化 + ADR-0045 §I-5-b future) |
