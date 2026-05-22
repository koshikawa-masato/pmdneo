# ADR-0057: PMDNEO 軸 B v2 driver production-ready roadmap ① = FM/SSG 実音

- 状態: **Draft** (= 2026-05-23 39th session 軸 B production-ready roadmap ①、 ground truth = ADR-0056 roadmap ① / ADR-0045、 α 起票 doc-only filing + β driver 実音化 完了、 後続 γ で verify script 体系化 → δ completion → Draft → Accepted。 ADR-0056 §決定 4 roadmap ① literal 後続実装 ADR。 **v2 FM/SSG dispatcher を trace-proof stub から実音 register write へ昇格する実装 ADR**。 production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0056** (= 軸 B v2 driver production-ready 化 選定 ADR、 Accepted、 §決定 4 roadmap ① = FM/SSG 実音。 本 ADR-0057 が roadmap ① の実装 ADR)
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted)
  - **ADR-0052** (= 軸 B 実装 sprint 1 δ-1 v2 entry、 Accepted。 §決定 5 δ で「v2 SSG dispatcher は reg 0x07 一切 touch しない」 と規定 = volume-only stub 期の契約。 **本 ADR-0057 §決定 4 がこれを実音化に伴い更新** = `pmdneo_ssg_tone_sync` 経由化)
  - **ADR-0051** (= 軸 B 実装 sprint 7 SSG tone-enable、 Accepted。 §決定 3/4 = `pmdneo_ssg_tone_sync` が reg 0x07 唯一の RMW owner / tone-enable trigger = keyon かつ実効 volume>0 / reg 0x07 直接 write 禁止。 **本 ADR-0057 の SSG 実音化はこの契約に完全準拠**)
  - **ADR-0053 / ADR-0054 / ADR-0055** (= 軸 B 実装 sprint 2/3/4 = SRAM placement / F-2-B / 軸 C/G/rhythm 接続点、 Accepted、 **本 ADR で完全不可触保護**。 `pmdneo_v2_fm3ext_dispatch` / `pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` は本 roadmap ① では不可触)
  - **ADR-0049 / ADR-0050** (= mute / fade-out、 Accepted、 **本 ADR で完全不可触保護**)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `feedback_long_running_verify_polling_hang_detection.md` (= 長時間 verify は polling monitor 併走 + hang 判定)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow、 0x0610 セクションは末尾 .org で overflow risk なし)
  - `feedback_parallelize_with_subagents_for_throughput.md` (= 本 ADR の現状 ground truth 調査は並列 sub-agent 3 体で実施)

## 背景 (= why now)

### production-ready 化 roadmap ① = FM/SSG 実音

ADR-0056 (= v2 driver production-ready 化 選定 ADR) Accepted で、 production-ready 化 roadmap が ① FM/SSG 実音 → ② song parse + v2 per-part dispatch loop + IRQ tick 連携 → ③ ADPCM-B/rhythm 実 dispatch → ④ 軸 G dynamic supply に固定された。 本 ADR-0057 = roadmap ① の実装 ADR。

### v2 FM/SSG dispatcher は trace-proof stub 段階

並列 sub-agent 3 体調査 (= ADR-0056 §決定 1 と同調査) で、 v2 dispatcher の現状が確認された = `pmdneo_v2_fm_dispatch` は FM keyon (reg 0x28) のみ / `pmdneo_v2_ssg_dispatch` は SSG volume (reg 0x08-0x0A) のみ。 = register 証跡を出すだけで「実音が鳴る」 状態ではない。 roadmap ① = この 2 dispatcher を実音 register write へ昇格する (= FM = voice/operator + fnum/block + keyon、 SSG = tone period + volume + reg 0x07 tone-enable)。

CLAUDE.md §設計書ファースト に従い、 本 ADR-0057 を doc-only filing として起票し、 後続 β/γ/δ で driver 実音化 → verify → completion を進める。

## 決定

### 決定 1: 軸 B roadmap ① sub-sprint 構成 = 4 段 α/β/γ/δ

roadmap ① 実装を **4 段階 α/β/γ/δ** に分割する。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | ADR-0057 起票 (= doc-only) + roadmap ① scope / FM・SSG 実音化方式 / verify gate / 規律 literal 化 | 本 ADR-0057 起票 + dashboard sync、 driver / verify script touch なし、 doc-only | なし |
| **β** | driver 実音化 = `pmdneo_v2_fm_dispatch` / `pmdneo_v2_ssg_dispatch` を実音 register write へ拡張 + driver 出力変更で直接影響する既存 verify gate を同時更新 (= β commit を self-consistent に) | FM voice/fnum/keyon + SSG tone period/volume/reg 0x07 の実音 register write trace + 既存 verify gate (= 実音化で期待値が変わる gate) 更新 + ADR-0049〜0056 regression PASS | driver + 影響 verify gate |
| **γ** | FM/SSG 実音 proof verify script 体系化 (= 想定 `verify-axis-b-fm-ssg-real-sound.sh`) | FM/SSG 実音 register write proof gate + verify script | verify script のみ (= driver touch なし) |
| **δ** | completion + ADR-0057 Draft → Accepted 判断 | 全 sub α/β/γ verify gate PASS + Accepted 移行 (= Codex layer 2 approve 経由、 完全自走 model) | なし (= doc-only completion) |

各 sub-sprint = 1 PR。 計 = α/β/γ/δ 各 1 PR = **4 PR**。 全 PR で軸 C / 軸 G / rhythm / ADR-0049〜0056 完全不可触。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop)
- 長時間 verify / MAME / regression は background 実行 + polling monitor 併走 + hang 判定 + kill/retry (= memory `feedback_long_running_verify_polling_hang_detection.md`)
- 軸 C ADR-0043 / 軸 G ADR-0048 / rhythm ADR-0026〜0031 / ADR-0049〜0056 完全不可触
- 既存実音 routine 本体 (= `fnumset_fm` / `fnumset_ssg` / `fm_keyon` / `ssg_keyon` / `pmdneo_fm_voice_set` / `pmdneo_ssg_tone_sync`) は **本体改変せず call のみ**
- 「軸 B 完成」 表現禁止 (= ADR-0057 = roadmap ① の実装、 production-ready 達成宣言ではない)
- α は β に先行する (= ADR-0057 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: FM 実音化方式 = 既存 routine 本体 call

`pmdneo_v2_fm_dispatch` を、 FM ch loop の per ch で次の 3 既存 routine を本体直接 call する形へ拡張する (= trace-proof stub の keyon-only から実音化)。

| 順 | routine | 役割 |
|---|---|---|
| 1 | `pmdneo_fm_voice_set` (HL = `fm_voice_data_default`、 B = ch) | FM voice/operator 設定 (= reg 0x30-0x80 + algorithm/feedback 0xB0 + pan 0xB4) |
| 2 | `fnumset_fm` (A = 固定 note byte、 B = ch) | FM fnum/block 設定 (= reg 0xA4系 → 0xA0系) |
| 3 | `fm_keyon` (B = ch) | FM keyon (= reg 0x28) |

`pmdneo_fm_voice_set` と `fnumset_fm` は **BC 非保存** (= `fnumset_fm` は冒頭 `push bc`/`pop bc` を fnum_data table lookup 用に行うが、 その後 B を register addr 0xA4系/0xA0系 で上書きして ret するため、 戻り時 B は ch index ではない) のため、 これらの call では loop counter B を push/pop で退避する。 `fm_keyon` は末尾 `pop bc` で BC 保存。 chip target 分岐 (= YM2610 は A/D = ch index 0/3 を skip) は既存 `pmdneo_v2_fm_dispatch` の `.if PMDNEO_TARGET_CHIP_YM2610B` 構造を維持する。

### 決定 3: SSG 実音化方式 = 既存 routine 本体 call

`pmdneo_v2_ssg_dispatch` を、 SSG ch loop の per ch で次の 3 既存 routine を本体直接 call する形へ拡張する。

| 順 | routine | 役割 |
|---|---|---|
| 1 | `fnumset_ssg` (A = 固定 note byte、 B = ch) | SSG tone period 設定 (= reg 0x00-0x05) |
| 2 | `ssg_keyon` (B = ch) | SSG volume 設定 (= reg 0x08-0x0A) |
| 3 | `pmdneo_ssg_tone_sync` (B = ch、 A = 実効 volume) | SSG mixer reg 0x07 tone-enable (= ADR-0051 契約準拠) |

`fnumset_ssg` と `pmdneo_ssg_tone_sync` は **BC 非保存** (= `fnumset_ssg` は冒頭 `push bc`/`pop bc` を psg_tune_data table lookup 用に行うが、 その後 B を register addr で上書きして ret する。 `pmdneo_ssg_tone_sync` は AF/BC/DE/HL 破壊) のため、 これらの call では loop counter B を push/pop で退避する。 `ssg_keyon` は末尾 `pop bc` で BC 保存。

### 決定 4: reg 0x07 契約 evolution = ADR-0052 δ「touch しない」 → ADR-0051 `pmdneo_ssg_tone_sync` 経由

ADR-0052 §決定 5 δ は「v2 SSG dispatcher は reg 0x07 (= mixer tone-enable) を一切 touch しない」 と規定した。 これは **volume-only trace-proof stub 期の保護契約** (= 当時 v2 SSG dispatcher は volume のみ出す stub であり、 reg 0x07 owner `pmdneo_ssg_tone_sync` を保護するため touch しなかった)。

本 ADR-0057 §決定 3 の SSG 実音化に伴い、 v2 SSG dispatcher は tone period + volume を出した上で **reg 0x07 tone-enable が必要**になる。 ADR-0052 δ の「touch しない」 契約を、 実音化に伴い **「`pmdneo_ssg_tone_sync` 経由で reg 0x07 tone-enable を扱う」 へ更新**する。

- これは ADR-0051 §決定 3/4 への **契約準拠** = `pmdneo_ssg_tone_sync` は reg 0x07 の唯一の RMW owner、 tone-enable trigger = keyon かつ実効 volume>0。 v2 SSG dispatcher は `pmdneo_ssg_tone_sync` を call することで ADR-0051 契約に合流する (= 契約違反ではない)。
- **reg 0x07 への直接 write は引き続き禁止** (= ADR-0051 §決定 4 維持)。 v2 SSG dispatcher は `pmdneo_ssg_tone_sync` 経由のみ。
- ADR-0052 δ の当該記述は本 ADR-0057 §決定 4 が roadmap ① 段階で update する (= ADR-0052 本体は不可触、 契約 evolution を本 ADR で literal 記録)。

### 決定 5: 固定 note 使用 (= v2 song parse なし、 roadmap ②)

v2 path は実 MML song data parse を持たない (= roadmap ② scope)。 roadmap ① では v2 FM/SSG dispatcher は **固定 note** で実音を出す。 固定 note は既存 cmd 0x02 mode4 の固定 chord (= C4/E4/G4 = note byte 0x40/0x44/0x47) を流用する。 ch への具体 note 割当は β 実装時に確定する (= 例 = FM/SSG 各 ch に chord を割当、 詳細 β)。 = roadmap ① は「v2 dispatcher が実音 register write を出せること」 の確立であり、 実 MML 曲再生は roadmap ②。

### 決定 6: verify gate 更新方針 (= β/γ 分担)

v2 dispatcher の実音化で register 出力が変わるため、 既存 verify gate の literal 期待値が変わる。

- **β** = driver 実音化と同時に、 driver 出力変更で直接影響する既存 verify gate (= `verify-axis-b-v2-entry.sh` gate 3/4 等の literal 期待値) を更新する (= β commit を self-consistent に保つ。 driver だけ変えて verify を放置すると β 自身の regression が壊れる)。 ADR-0049〜0056 regression は維持 (= reg 0x07 を `pmdneo_ssg_tone_sync` 経由で扱えば `verify-ssg-tone-enable.sh` は保護される)。
- **γ** = FM/SSG 実音 proof の verify script (= 想定 `verify-axis-b-fm-ssg-real-sound.sh`) を新規体系化 = FM voice/fnum register write proof + SSG tone period/reg 0x07 register write proof を gate 化。

### 決定 7: verify gate (= register trace primary gate)

roadmap ① は **register trace primary gate** で verify する。 γ で次を verify script に体系化する (= 最終件数は γ で確定)。

| # | gate | 期待 |
|---|---|---|
| 1 | FM 実音 register write proof | v2 FM dispatcher が voice (reg 0x30-0x80/0xB0) + fnum/block (reg 0xA0系/0xA4系) + keyon (reg 0x28) を実音 write |
| 2 | SSG 実音 register write proof | v2 SSG dispatcher が tone period (reg 0x00-0x05) + volume (reg 0x08-0x0A) + reg 0x07 tone-enable を実音 write |
| 3 | reg 0x07 契約準拠 | reg 0x07 が `pmdneo_ssg_tone_sync` 経由のみで write される (= 直接 write なし、 ADR-0051 §決定 4 準拠) |
| 4 | chip target 分岐維持 | FM の YM2610 (A/D skip) / YM2610B (全 6ch) 分岐が実音化後も維持 |
| 5 | baseline regression | ADR-0049〜0056 verify (= mute / fade-out / SSG tone-enable / v2-entry / sram-placement / f2b-integration / axis-connection) 全 PASS |
| 6 | `.org` overflow / cmd 0x07 v2 path | v2 並設 routine が `.org` overflow なし + `pmdneo_v2_entry_marker` (0xFD3B) ← 0x07 維持 |

audition は production-ready gate (= ADR-0056 §決定 3) の最終段。 roadmap ① の完了判定は register trace primary。 短い audition fixture は γ で可能なら用意 (= v2 path で実音が出ることの聴感確認、 必須ではない)。

### 決定 8: scope-in / scope-out

#### scope-in (= roadmap ① で扱う)

- `pmdneo_v2_fm_dispatch` の実音化 (= voice + fnum/block + keyon)
- `pmdneo_v2_ssg_dispatch` の実音化 (= tone period + volume + reg 0x07 tone-enable)
- 固定 note による実音 register write
- 実音化で影響する verify gate 更新 + FM/SSG 実音 proof verify script 体系化

#### scope-out (= 後続 roadmap)

- **実 MML song data parse + v2 per-part dispatch loop + IRQ tick 連携** = roadmap ② (= ADR-0056 §決定 4)
- **ADPCM-B / rhythm 実 dispatch** (= `pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` の marker stub → 実 call) = roadmap ③
- **軸 G dynamic supply 依存整理** = roadmap ④
- **F-2-B 実音 individual mode** (= `pmdneo_v2_fm3ext_dispatch` の実音化) = ADR-0054 §決定 6 後続 future (= roadmap ① では fm3ext stub のまま不可触)
- **production-ready 判定 + cmd 切替** = roadmap ①〜④ 完了後 (= ADR-0056 §決定 3)

### 決定 9: 不可触対象 (= 全 sub-sprint 共通)

次を完全不可触とする。

- 既存実音 routine の **本体** (= `fnumset_fm` / `fnumset_ssg` / `fm_keyon` / `ssg_keyon` / `pmdneo_fm_voice_set` / `pmdneo_ssg_tone_sync` / `fm_voice_data_default` / `fnum_data` / `psg_tune_data`) = call / 参照のみ、 本体改変なし
- 既存 cmd 0x02 fixture path / cmd 0x05 + `pmdneo_song_main` MML parser 経路 / IRQ handler / TIMER-B / 既存 NMI dispatch cmd 分岐
- `pmdneo_v2_fm3ext_dispatch` (= F-2-B) / `pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch` (= roadmap ③) / `pmdneo_v2_entry_skeleton` の dispatcher call 構造
- ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable / ADR-0052〜0055 v2 driver foundation の routine + SRAM field (= reg 0x07 owner `pmdneo_ssg_tone_sync` は call のみ)
- 軸 C ADR-0043 / 軸 G ADR-0048 (= Draft + ε partial state) / rhythm ADR-0026〜0031 / vendor

### 決定 10: doc-only filing 規律 (= α) + Codex rescue 化 + non-stop model 継承

α sub-sprint (= 本 ADR-0057 起票) は **doc-only** = 変更 file = 本 ADR-0057 + `docs/parallel-axes-dashboard.md` のみ。 driver / verify script / vendor 完全不変。 vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain。

本 roadmap ① 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model + 後半 再拡張 (= 判断要件も Codex layer 2 自律判断、 mid-flight escalate で止まらず non-stop、 user は完走後確認) を継承する。 Codex layer 2 review 依頼時は commit 権限なしを literal 明示する。

## Annex A: FM/SSG 実音化 ground truth (= 並列 sub-agent 3 体調査)

### A-1: FM 実音 routine (= `src/driver/standalone_test.s`)

| routine | 入力 | 破壊 register | 役割 |
|---|---|---|---|
| `pmdneo_fm_voice_set` | HL = voice data 先頭、 B = ch | AF/DE/HL (= **BC 非保存**) | reg 0x30-0x80 (op) + 0xB0 (FB/ALG) + 0xB4 (pan) |
| `fnumset_fm` | A = note byte (OCT<<4\|ONKAI)、 B = ch | AF/BC/DE/HL (= **BC 非保存**、 table lookup 用の冒頭 push/pop bc 後に B を register addr で上書きして ret) | reg 0xA4系 → 0xA0系 (block+fnum、 latch 順序保証) |
| `fm_keyon` | B = ch | AF/DE/HL (= BC 保存) | reg 0x28 (slot mask + ch) |

固定値 = note byte 0x40=C4 / 0x44=E4 / 0x47=G4 (= cmd 0x02 mode4 chord)、 `fnum_data` table (12 entry)、 `fm_voice_data_default` (25 byte、 ALG7 = 4 op 全 carrier)。

### A-2: SSG 実音 routine + reg 0x07 契約

| routine | 入力 | 破壊 register | 役割 |
|---|---|---|---|
| `fnumset_ssg` | A = note byte、 B = ch | AF/BC/DE/HL (= **BC 非保存**、 table lookup 用の冒頭 push/pop bc 後に B を register addr で上書きして ret) | reg 0x00-0x05 (tone period) |
| `ssg_keyon` | B = ch | AF (= BC 保存) | reg 0x08-0x0A (volume、 0x0F 固定) |
| `pmdneo_ssg_tone_sync` | B = ch、 A = 実効 volume | AF/BC/DE/HL (= **BC 破壊**) | reg 0x07 tone-enable (= shadow `pmdneo_v2_ssg_mixer` 0xFD3A RMW) |

ADR-0051 §決定 3/4 = `pmdneo_ssg_tone_sync` は reg 0x07 唯一の RMW owner、 tone-enable trigger = keyon かつ実効 volume>0、 reg 0x07 直接 write 禁止。 固定値 = SSG note 0x40/0x44/0x47、 `psg_tune_data` table。

### A-3: v2 dispatcher 現状 + verify 影響

`pmdneo_v2_fm_dispatch` (= FM keyon のみ、 chip 分岐あり) / `pmdneo_v2_ssg_dispatch` (= SSG volume 0x0F のみ、 chip 分岐なし)。 0x0610 セクション = 最終 `.org` = overflow risk なし (= 後続 routine が押し下がるのみ)。 実音化で `verify-axis-b-v2-entry.sh` gate 3 (= FM keyon set) / gate 4 (= SSG reg 0x08-0x0A ← 0x0F 各 1) 等の literal 期待値が変わる = β で同時更新 (= §決定 6)。

## Annex B: v2 dispatcher 実音化 register map

```
v2 FM dispatcher (per ch、 既存 routine 本体 call):
  pmdneo_fm_voice_set  → reg 0x30-0x8E (op DT/ML/TL/AR/DR/SR/SL/RR) + 0xB0-0xB6 (FB/ALG) + 0xB4-0xB6 (pan)
  fnumset_fm           → reg 0xA4-0xA6 / 0xAC-0xAE (block+fnum upper) → 0xA0-0xA2 / 0xA8-0xAA (fnum lower latch)
  fm_keyon             → reg 0x28 (keyon)
v2 SSG dispatcher (per ch、 既存 routine 本体 call):
  fnumset_ssg          → reg 0x00-0x05 (tone period fine/coarse)
  ssg_keyon            → reg 0x08-0x0A (volume)
  pmdneo_ssg_tone_sync → reg 0x07 (mixer tone-enable、 shadow RMW)
```

固定 note (= §決定 5) で per ch に実音 register write。 具体 note 割当は β 実装時に確定。

## Annex C: β 実装 completion record (= v2 FM/SSG dispatcher 実音化)

### C-1: β deliverable

軸 B production-ready roadmap ① β = v2 FM/SSG dispatcher 実音化 (= 39th session、 PR #93)。 既存実音 routine 本体 call で trace-proof stub から実音 register write へ昇格。

| deliverable | 内容 |
|---|---|
| `pmdneo_v2_fm_dispatch` 実音化 | FM ch loop の per ch で `pmdneo_v2_fm_voice_note` を call。 chip 分岐 (= YM2610 A/D skip) 維持 |
| `pmdneo_v2_fm_voice_note` 新設 | per-ch FM 実音 = `pmdneo_fm_voice_set` (voice/operator) + `fnumset_fm` (fnum/block) + `fm_keyon` (keyon) 本体 call |
| `pmdneo_v2_ssg_dispatch` 実音化 | SSG ch loop の per ch で `pmdneo_v2_ssg_voice_note` を call |
| `pmdneo_v2_ssg_voice_note` 新設 | per-ch SSG 実音 = `fnumset_ssg` (tone period) + `ssg_keyon` (volume) + `pmdneo_ssg_tone_sync` (reg 0x07 tone-enable) 本体 call |
| `pmdneo_v2_fm_notes` / `pmdneo_v2_ssg_notes` | 固定 note table (= C4/E4/G4 chord = note byte 0x40/0x44/0x47) |

### C-2: 実装詳細

- BC 非保存対策 = `pmdneo_fm_voice_set` / `fnumset_fm` / `fnumset_ssg` / `pmdneo_ssg_tone_sync` の call で loop counter B を push/pop 退避 (= §決定 2/3、 起票 review must-fix で確定した BC 非保存 routine 群)。 `fm_keyon` / `ssg_keyon` は BC 保存
- reg 0x07 = `pmdneo_ssg_tone_sync` 経由のみ (= §決定 4 契約 evolution、 ADR-0051 §決定 3/4 準拠、 直接 write なし)
- chip 分岐 = `pmdneo_v2_fm_dispatch` の `.if PMDNEO_TARGET_CHIP_YM2610B` 維持 (= YM2610 A/D skip)

### C-3: β 検証結果 + finding

- production build PASS。 v2 実音 routine は 0x0610 セクション (= `pmdneo_v2_fm_dispatch` 0x09AB / `pmdneo_v2_fm_voice_note` 0x09C0 / `pmdneo_v2_ssg_dispatch` 0x09E0 / `pmdneo_v2_ssg_voice_note` 0x09EC)、 `.org` overflow なし
- V2 fixture build (両 chip) + MAME headless trace = FM voice/operator (reg 0x30-0x8E) + fnum/block (reg 0xA0系) + keyon (reg 0x28) / SSG tone period (reg 0x00-0x05) + volume (reg 0x08-0x0A) + reg 0x07 tone-enable の実音 register write を観測 (= trace-proof stub から実音化)
- baseline regression = `verify-axis-b-axis-connection.sh` 6 gate 全 PASS (= 内部で `verify-axis-b-f2b-integration.sh` / `verify-axis-b-sram-placement.sh` / `verify-axis-b-v2-entry.sh` + `verify-fadeout-semantics.sh` / `verify-mute-semantics.sh` / `verify-ssg-tone-enable.sh` + baseline 9 script を transitively = ADR-0049〜0056 全 PASS)
- **finding**: §決定 6 は実音化で既存 verify gate の literal 期待値が変わると想定し β で gate 更新を計画したが、 実測で **既存 verify gate の更新は不要**だった。 理由 = 実音化は additive (= 既存 FM keyon reg 0x28 + SSG volume reg 0x08-0x0A ← 0x0F は維持、 voice/fnum/tone period/reg 0x07 が新規追加)。 既存 gate は keyon / SSG 0x0F 等の特定 register/value を assert するため、 additive な実音化で literal 期待値は壊れない。 実音 register write 自体の proof gate は γ で新規体系化する
- Codex layer 2 = β 実装 review approve

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) の FM/SSG 音源処理を「証跡を出すだけのスタブ」 から「実際に音が鳴るレベル」 へ引き上げる。 FM は keyon だけでなく音色 (voice) と音程 (fnum) を、 SSG は音量だけでなく音程 (tone period) と tone enable を register に書く。

**前提**: ADR-0056 で production-ready 化の roadmap (= ① FM/SSG 実音 → ② 曲データ解釈 → ③ ADPCM-B/rhythm → ④ 軸 G) が固定済。 本 ADR-0057 = roadmap ① の実装。

**進捗 (= α/β 完了)**: α で設計書 (= 本 ADR-0057) を起票し、 FM/SSG の実音化方式・固定 note・検証方法・不可触対象を文書で固定した。 β でドライバ (= `standalone_test.s`) の v2 FM/SSG dispatcher を実音化した = FM は音色 (voice) と音程 (fnum) を、 SSG は音程 (tone period) と tone enable を register に書くようになった。 固定の和音 (= C4/E4/G4) を鳴らす。 既存検証 (= ADR-0049〜0056) は全て PASS のままで、 実音化は既存挙動に追加する形 (= additive) のため既存 gate は壊れなかった。

**実音化のやり方**: 既存の音源処理ルーチン (= `pmdneo_fm_voice_set` / `fnumset_fm` / `fm_keyon`、 `fnumset_ssg` / `ssg_keyon` / `pmdneo_ssg_tone_sync`) を v2 dispatcher から呼ぶ。 v2 はまだ曲データを解釈しないので (= roadmap ②)、 固定の音 (= C4/E4/G4 = 既存 fixture と同じ和音) を鳴らす。

**SSG の reg 0x07 について**: 旧スタブ期は「v2 SSG は reg 0x07 を触らない」 契約だったが、 実音化では tone enable が要る。 ADR-0051 が定めた `pmdneo_ssg_tone_sync` (= reg 0x07 の唯一の管理ルーチン) を経由して扱う = 契約違反ではなく契約への合流。

**次**: γ で FM/SSG 実音 proof の検証スクリプトを整備し、 δ で ADR-0057 を Draft → Accepted へ移行する。 実 MML 曲再生は roadmap ②、 production-ready 達成宣言はまだしない。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ADR-0057 起票) | **完了** (= 39th session、 PR #92) | PR #92 | 起票 plan review approve (= 全 3 論点 + 規律 + ADR 番号 approve、 escalate なし) + 起票 review revise (= must-fix 1 = fnumset_fm/ssg BC 非保存) → approve |
| β (= driver 実音化 + 影響 verify gate 更新) | **完了** (= 39th session、 PR #93) | PR #93 | β 実装 review approve |
| γ (= FM/SSG 実音 proof verify script 体系化) | 未着手 | - | - |
| δ (= completion + Draft → Accepted 判断) | 未着手 | - | - |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | β 実装完了 (= 39th session、 PR #93) | v2 FM/SSG dispatcher 実音化。 `standalone_test.s` の `pmdneo_v2_fm_dispatch` を per ch `pmdneo_v2_fm_voice_note` call (= `pmdneo_fm_voice_set` + `fnumset_fm` + `fm_keyon`) へ、 `pmdneo_v2_ssg_dispatch` を per ch `pmdneo_v2_ssg_voice_note` call (= `fnumset_ssg` + `ssg_keyon` + `pmdneo_ssg_tone_sync`) へ拡張 + 固定 note table `pmdneo_v2_fm_notes`/`pmdneo_v2_ssg_notes` (= C4/E4/G4) 新設。 BC 非保存 routine の call で loop counter B を push/pop 退避。 reg 0x07 は `pmdneo_ssg_tone_sync` 経由のみ (= §決定 4 契約 evolution、 ADR-0051 準拠)。 Annex C 追記 (= β completion + deliverable + finding) + sub-sprint chain β 完了 reflect + 状態行/平易要約 β 同期。 検証 = production build PASS (= v2 実音 routine 0x0610 セクション、 overflow なし) + V2 fixture trace 両 chip で FM voice/fnum/keyon + SSG tone period/volume/reg 0x07 の実音 register write 観測 + verify-axis-b-axis-connection.sh 6 gate baseline regression 全 PASS (= ADR-0049〜0056 transitively 全 PASS)。 finding = §決定 6 は実音化で既存 verify gate 更新が要ると想定したが、 実音化が additive (= 既存 keyon/SSG 0x0F は維持、 voice/fnum/tone period/reg 0x07 が新規追加) のため既存 gate の literal 期待値は壊れず gate 更新不要。 Codex layer 2 = β 実装 review approve。 軸 B production-ready roadmap ① β、 残 γ/δ、 「軸 B 完成」 表現不使用 |
| 2026-05-23 | Draft 起票 (= 39th session 軸 B production-ready roadmap ① α) | v2 driver production-ready roadmap ① = FM/SSG 実音 の実装 ADR を起票。 ADR-0056 §決定 4 roadmap ① の実装 ADR として、 v2 FM/SSG dispatcher を trace-proof stub から実音 register write へ昇格する設計を固定。 決定 1-10 + 4 段 sub-sprint α/β/γ/δ + FM 実音化方式 (= `pmdneo_fm_voice_set` + `fnumset_fm` + `fm_keyon` 本体 call) + SSG 実音化方式 (= `fnumset_ssg` + `ssg_keyon` + `pmdneo_ssg_tone_sync` 本体 call) + reg 0x07 契約 evolution (= ADR-0052 δ「touch しない」 → ADR-0051 `pmdneo_ssg_tone_sync` 経由、 契約準拠) + 固定 note 使用 (= song parse は roadmap ②) + verify gate 更新方針 (= β driver+影響 gate 同時 / γ 実音 proof script 体系化) + verify gate 6 件 + scope-out (= song parse/ADPCM-B/rhythm/軸 G/F-2-B 実音 は後続)。 doc-only filing (= ADR-0057 + dashboard のみ)。 並列 sub-agent 3 体調査の ground truth (= FM/SSG 実音 routine + reg 0x07 契約 + v2 dispatcher 現状 + verify 影響) を Annex A/B に literal 化。 Codex layer 2 起票 plan review approve (= 全 3 論点 = sub-sprint 段数/reg 0x07 契約 evolution/固定 note+fm3ext scope-out + 規律 6 観点 + ADR 番号 0057 approve、 escalate なし)。 起票 review must-fix 1 件 = `fnumset_fm`/`fnumset_ssg` の register 保存性。 並列 sub-agent は冒頭 `push bc`/`pop bc` のみ見て「BC 保存」 と誤判定したが、 Codex source verify + 主軸 driver source 直接確認で両 routine は table lookup 用 push/pop bc 後に B を register addr で上書きして ret する = **BC 非保存** と確定 → Annex A + §決定 2/3 を訂正 (= `pmdneo_fm_voice_set`/`fnumset_fm` 両方、 `fnumset_ssg`/`pmdneo_ssg_tone_sync` 両方 で loop counter B を push/pop 退避必須)。 ADR-0057 = roadmap ① 実装、 production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用 |
