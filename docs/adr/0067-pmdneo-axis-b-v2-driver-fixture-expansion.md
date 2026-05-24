# ADR-0067: PMDNEO 軸 B v2 driver fixture 拡張 ADR (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目、 16 ch trace-equivalence 前提作り、 既存 4 ch fixture cover を 16 ch carry 可能な driver state へ widen、 統合 verify は ADR-0068 候補 future)

- 状態: **Draft** (= 2026-05-24 39th session、 sub-sprint chain (= α/β/γ/δ/ε) 起票、 起票 + sub-sprint α 着手で 1 PR、 ADR-0058 / ADR-0059 同 pattern、 Codex layer 2 plan review 5 round chain (= round 1-4 revise + round 4 で escalation = user option Z 採用 + round 5 approve)、 must-fix なし + nice-to-have 2 件 + latent-risk 2 件全反映、 越権操作なし、 ADR-0064 §決定 3 sub-sprint plan の 16 ch literal trace-equivalence と既存 4 ch fixture cover 範囲の矛盾を解消する fixture 拡張専用 ADR + 統合 verify は ADR-0068 候補 future へ分離)
- 起票日: 2026-05-24
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0064** (= 母 ADR、 §決定 3 sub-sprint α/β/γ/δ/ε plan = 16 ch literal trace-equivalence + §決定 7 ADR-0067+ = ADR-0064 実作業 ADR 番号 chronology rationale、 本 ADR-0067 が ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目)
  - **ADR-0063** (= production-ready 4 gate status 確認、 §決定 1(b) 16 ch trace-equivalence ground truth)
  - **ADR-0058** (= roadmap ② song parse + per-part dispatch、 §決定 1 slot 0/1 active init pattern + §決定 3 slot 構造 + γ allowed-touch fixture 追加 pattern 由来)
  - **ADR-0059** (= roadmap ③ ADPCM-B/rhythm 実 dispatch、 γ slot 9 ADPCM-B 追加 + δ slot 10 rhythm 追加 allowed-touch pattern 由来 + δ rhythm K bitmap fixture 由来)
  - **ADR-0057** (= roadmap ① FM/SSG 実音、 `pmdneo_v2_fm_voice_note` per-ch register write 既存実装 + `pmdneo_v2_ssg_voice_note` per-ch register write 既存実装)
  - **ADR-0056** (= production-ready 選定 ADR、 §決定 3-a trace-equivalence literal、 §決定 4 roadmap ①〜④ 由来、 ADR-0067 = roadmap ⑤ 前提作り)
  - **ADR-0048** (= 軸 G dynamic supply 完成、 ζ-δ-2 `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP` 由来既存 flag 流用 = 新規 flag 追加なし)
  - **ADR-0006** (= AES+ YM2610B 想定 + FM3Extend 規約、 §B chip target literal = ym2610 target では FM A/D/F init せず stream 読捨)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化 + §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止、 「roadmap ⑤ 統合 verify 完了」 = ADR-0067 完全禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal 強調)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `feedback_org_section_overflow_silent_bug.md` (= .org section overflow silent bug、 §決定 3 注意点 literal)
  - `feedback_sdas_if_no_value_comparison.md` (= sdasz80 .if 値比較禁止規律)
  - `project_pmdneo_adr_0064_initiated.md` (= ADR-0064 plan ADR + ADR-0067+ 実作業 ADR 候補)

## 背景 (= why now)

### ADR-0064 plan の 16 ch literal trace-equivalence と既存 4 ch fixture cover の矛盾

ADR-0064 §決定 3 sub-sprint plan は **16 ch literal trace-equivalence** (= FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6 = 16 ch、 ADR-0063 §決定 1(b) ground truth) を要求する。 ただし 39th session の主軸 ground truth 確認結果 = driver source 内 v2 fixture cover 範囲は **4 ch のみ** (= FM ch B + SSG ch G + ADPCM-B J + rhythm K):

| 既存 fixture | 関連 ADR | cover ch |
|---|---|---|
| `pmdneo_v2_song_fixture_fm_b` | ADR-0058 γ | FM ch B (= 1 ch) |
| `pmdneo_v2_song_fixture_ssg_g` | ADR-0058 γ | SSG ch G (= 1 ch) |
| `pmdneo_v2_song_fixture_adpcmb_j` | ADR-0059 γ | ADPCM-B J (= 1 ch、 chip 上 1 ch) |
| `pmdneo_v2_song_fixture_rhythm_k` | ADR-0059 δ | rhythm K (= BD→SD→BD bitmap、 ADPCM-A 6 ch のうち 2 種類のみ active) |

= 全 16 ch trace-equivalence 達成には driver source 内 fixture 拡張が必要 (= 残 12 ch carry):

- FM 残 5 ch = A/C/D/E/F
- SSG 残 2 ch = H/I
- ADPCM-A 残 ch = K bitmap で BD/SD のみから 6 ch 全 active 化拡張 (= ADPCM-A 6 ch literal carry)

ただし driver source 変更 = ADR-0064 §決定 5「driver / verify / vendor / fixture / build flag **完全不変**」 と矛盾する (= ADR-0064 = plan ADR doc-only)。

### user option Z 採用 = ADR-0067 = fixture 拡張専用 + ADR-0068 = 統合 verify

39th session 主軸 escalation (= round 4 Codex finding「β 4ch 限定 = ADR-0064 §決定 3 (= 16 ch literal) と矛盾」) → user option Z 採用 literal:

1. ADR-0067 を「fixture 拡張専用」 に scope 変更
2. 目的 = 既存 4 ch fixture cover を 16 ch trace-equivalence 可能な状態へ広げる
3. driver source 変更は allowed-touch として明記
4. 統合 verify 完了宣言は ADR-0068 以降に送る
5. ADR-0067 では「roadmap ⑤ 統合 verify 完了」 と書かない
6. ADR-0064 番号 chronology rationale = ADR-0067+ = ADR-0064 実作業群 として整合

= ADR-0067 = ADR-0064 §決定 7 literal「ADR-0067+ = ADR-0064 実作業 ADR」 の **1 本目** (= driver fixture 拡張)、 ADR-0068 候補 = **2 本目** (= 16 ch 統合 verify)。

### ADR-0058 γ / ADR-0059 γ-δ allowed-touch pattern 継承

ADR-0058 γ で slot 0 (FM B) + slot 1 (SSG G) active init + fixture data 追加。 ADR-0059 γ で slot 9 (ADPCM-B J) active init + fixture data 追加。 ADR-0059 δ で slot 10 (rhythm K) active init + fixture data 追加。 これらは全て driver source 内 fixture additive 追加 + `pmdneo_v2_song_init` slot active init 追加で、 **既存 routine body / dispatcher body / IRQ handler / cmd path は完全不変**。 ADR-0067 は同じ allowed-touch pattern を chip 軸拡張 (= FM 残 5 ch + SSG 残 2 ch + ADPCM-A 残 ch) に適用する。

### CLAUDE.md §設計書ファースト遵守 + ADR-0041 §決定 4-2 Codex rescue 化遵守

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 本 ADR-0067 を **driver fixture 拡張 ADR** として起票する。 Codex layer 2 plan review 5 round chain (= round 1-4 revise + round 4 escalation user 判断 + round 5 approve) 完了下、 round 5 nice-to-have 2 件 + latent-risk 2 件全反映 (= user 明示)。

ADR-0041 §決定 4 規律 (= sub-agent ↔ Codex 2 段壁打ち + 3 重 zero-trust review) + ADR-0041 §決定 4-2 Codex rescue 化 default 永続化下で起票。 39th session ADR-0062 PR2 越権 merge 事例後の規律強化 = Codex layer 2 review-only + commit / branch / merge 禁止 + merge は main agent 経路のみ literal 遵守 (= 冒頭 6 件 literal 強調 prompt 経由)。

## 決定

### 決定 1: ADR-0067 = driver fixture 拡張専用 ADR (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目)

ADR-0067 scope = **既存 4 ch fixture cover を 16 ch trace-equivalence 可能な状態へ広げる driver fixture 拡張 ADR**。

- driver source 変更 = allowed-touch (= ADR-0058 γ / ADR-0059 γ-δ pattern 継承、 fixture data + slot init additive 追加のみ、 既存 routine body / dispatcher body / IRQ handler / cmd path 完全不変)
- ADR-0067 ε Accepted ≠ roadmap ⑤ 統合 verify 完了 (= ADR-0068 候補で future)
- **「roadmap ⑤ 統合 verify 完了」 wording = ADR-0067 内で完全禁止** (= §決定 6 表記制約 literal)
- ADR-0067 = ADR-0064 plan の **前提作り** = 16 ch trace-equivalence 可能な driver state へ widen する sprint

### 決定 2: sub-sprint scope plan = chip 軸 5 段 (α/β/γ/δ/ε) + nice-to-have / latent-risk 全反映

| sub | scope | 関連 chip | 新規 fixture | slot init 追加 | chip target | 前後 clean / overflow gate |
|---|---|---|---|---|---|---|
| α | FM 残 5 ch fixture data 追加 + slot 2-6 init (= **chip target 別 active policy**、 ADR-0058 γ comment「slot 初期化で active ch_idx のみ選択 (= ym2610 silent skip 対象は init 段階で回避)」 + ADR-0006 §B 整合 = ym2610 で slot 3/5 (= FM C/E) のみ active 化、 ym2610b で slot 2-6 全 active 化) | FM A/C/D/E/F | `pmdneo_v2_song_fixture_fm_a` / `_c` / `_d` / `_e` / `_f` 新規 | slot 3 (FM C、 ch_idx 2) / slot 5 (FM E、 ch_idx 4) FLAGS=1 active (= 無条件、 ym2610 / ym2610b 両 audible) + slot 2 (FM A、 ch_idx 0) / slot 4 (FM D、 ch_idx 3) / slot 6 (FM F、 ch_idx 5) FLAGS=1 active (= `.if PMDNEO_TARGET_CHIP_YM2610B` 配下のみ、 ym2610b 限定) | YM2610 (= production default) + YM2610B (= 別 build) | trace tmp 前後 clean literal + .org overflow gate 必須 (= round 5 latent-risk 2 反映、 全 sub-sprint PR 必須) |
| β | SSG 残 2 ch fixture data 追加 + slot 7-8 active init | SSG H/I | `pmdneo_v2_song_fixture_ssg_h` / `_i` 新規 | slot 7 (SSG H、 ch_idx 1) / slot 8 (SSG I、 ch_idx 2) FLAGS=1 active | YM2610 | trace tmp 前後 clean + .org overflow gate 必須 |
| γ | rhythm K bitmap fixture 拡張 (= ADPCM-A 全 6 ch active 化、 既存 BD→SD bitmap を全 6 ch bitmap 拡張、 slot 10 fixture pointer switch 先 = `pmdneo_v2_song_fixture_rhythm_k_full`、 round 5 nice-to-have 1 反映 literal) | ADPCM-A 6 ch (= K bitmap、 BD/SD/CYM/HH/TOM/RIM) | `pmdneo_v2_song_fixture_rhythm_k_full` 新規 (= 既存 `_rhythm_k` 維持 + 拡張版 additive) | slot 10 KIND=3 維持 (= rhythm)、 ADDR を fixture pointer switch (= `_rhythm_k` → `_rhythm_k_full`) | YM2610 | trace tmp 前後 clean + .org overflow gate 必須 |
| δ | 全 16 ch fixture 駆動 trace gate verify (= 全 11 slot active 駆動の register write trace、 fixture 拡張完了の機能 verify、 trace-equivalence 比較は ADR-0068 候補 future) | 全 16 ch (= FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6) | なし (= 既存 + α/β/γ 拡張 fixture 統合 trace、 機能 verify のみ) | なし | YM2610 + YM2610B (= 別 build verify) | δ gate-3 chip 別代表 register 列挙 (= round 5 nice-to-have 2 反映 literal) |
| ε | Accepted 移行 doc-only + Annex 全 + 完走 milestone literal (= 「16 ch fixture 拡張完了」、 §決定 6 表記制約 literal) | - | なし | なし | - | - |

### 決定 3: driver source allowed-touch literal (= ADR-0058 γ / ADR-0059 γ-δ pattern 継承)

ADR-0067 = driver source allowed-touch 例外:

#### allowed-touch
- driver source 内 v2 fixture 追加 (= `pmdneo_v2_song_fixture_*` 新規 .db literal、 `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive)
- driver source 内 `pmdneo_v2_song_init` slot active init 追加 (= slot 2-8 FLAGS=1 set + KIND set + ch_idx set + ADDR set + LOOP set + LEN=0 + NOTE=0 + OCTAVE=0、 `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive、 既存 slot 9/10 init pattern 同形式)
- rhythm K bitmap fixture pointer switch (= slot 10 ADDR を `_rhythm_k` → `_rhythm_k_full` 切替、 γ で literal 化)

#### 完全不変 (= 既存 ADR-0058/0059 と同)
- 既存 routine body / dispatcher body (= `pmdneo_v2_song_dispatch` / `pmdneo_v2_part_dispatch_note` / `pmdneo_v2_fm_voice_note` / `pmdneo_v2_ssg_voice_note` / `pmdneo_v2_song_tick` 等)
- IRQ handler / cmd path
- 既存 fixture (= `_fm_b` / `_ssg_g` / `_adpcmb_j` / `_rhythm_k`)
- 既存 build flag

#### 注意点 (= round 5 latent-risk 2 反映 + 既存 ADR-0058/0059 経験 finding 継承)
- slot init 追加は `.if TEST_MODE_V2_SONG_FIXTURE` 配下のみ (= production build 完全不可触、 sha256 維持 mandatory)
- 新規 fixture data も `.if TEST_MODE_V2_SONG_FIXTURE` 配下のみ
- production build (= TEST_MODE_V2_SONG_FIXTURE=0) sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory (= 通算 ADR-0058〜0064)
- **.org section overflow 注意** (= memory `feedback_org_section_overflow_silent_bug.md` literal、 round 5 latent-risk 2 反映): FM / SSG fixture data 追加 + slot init 追加が想定より大きい場合に発生 risk、 α/β/γ 各 PR 必須 gate (= 決定 5 gate-4 literal、 .lst で section アドレス範囲確認)
- **sdasz80 .if 値比較禁止** (= memory `feedback_sdas_if_no_value_comparison.md` literal): 既存 `TEST_MODE_AXIS_G_*` flag pattern と同 (= binary toggle、 .if VAR / .else)

### 決定 4: build mode literal (= ADR-0058 γ / ADR-0059 γ 同 build mode 継承)

ADR-0067 fixture 拡張は既存 2 build mode で動作確認:

#### (A) production default build (= 全 fixture toggle = 0、 既存 cmd 0x05 + pmdneo_song_main legacy 経路駆動、 sha256 維持対象)

```
TEST_MODE_CHORD == 5
TEST_MODE_V2_SONG_FIXTURE == 0
TEST_MODE_V2_ENTRY_FIXTURE == 0
TEST_MODE_AXIS_G_V2_PPC == 0
TEST_MODE_AXIS_G_INT == 0
TEST_MODE_MUTE_FIXTURE == 0
TEST_MODE_FADE_FIXTURE == 0
TEST_MODE_AXIS_G_AUDITION_REVISE == 0
TEST_MODE_AXIS_G_AUDITION_MUTE_* == 0 (4 個 全 0)
TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP == 0
PMDNEO_TARGET_CHIP_YM2610B == 0
PMDNEO_USE_PMDDOTNET == 0
env 注入なし (= PMDNEO_M_RAW unset + PMDDOTNET_MML unset)
```
= sha256 = `b15883fe...` 維持 mandatory (= 通算)、 ADR-0067 全 sub-sprint で常時 verify。 ADR-0067 fixture / slot init 追加は全て `.if TEST_MODE_V2_SONG_FIXTURE` 配下のため production default では未 assemble = sha256 不変。

#### (B) v2 only trace capture build (= v2 fixture + legacy skip、 sub-sprint α/β/γ/δ trace gate verify 用)

```
TEST_MODE_V2_SONG_FIXTURE == 1 (= v2 song fixture build、 ADR-0058 γ 由来既存 flag)
TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP == 1 (= IRQ 内 legacy pmdneo_song_main skip、 ADR-0048 ζ-δ-2 由来既存 flag 流用 = 新規 flag 追加なし、 driver 不変、 round 5 nice-to-have 1 反映 = 流用理由 literal)
TEST_MODE_CHORD == 5
他 fixture toggle == 0
PMDNEO_TARGET_CHIP_YM2610B == 0 (= ym2610 target、 δ で 1 へ別 build verify)
PMDNEO_USE_PMDDOTNET == 0
env 注入なし
```
= sha256 別 (= 比較対象外)、 trace 中身のみ比較対象。

#### 注意 (= ADR-0067 では legacy trace capture build は使わない)
- legacy trace capture build (= ADR-0064 plan v4 (C) 由来 = `PMDNEO_M_RAW` / `PMDDOTNET_MML` env 注入 cmd 0x05 経路駆動) = ADR-0067 scope-out (= ADR-0068 候補 = 統合 verify ADR で初使用)
- ADR-0067 = driver fixture 拡張の機能 verify のみ、 legacy 比較は scope-out

### 決定 5: trace gate verify literal (= δ scope、 機能 verify only、 trace-equivalence は ADR-0068 future)

ADR-0067 δ = 全 16 ch fixture 駆動の register write trace 取得 + fixture 拡張完了の機能 verify (= trace の中身に期待値が出ているか確認、 trace-equivalence 比較ではない)。

#### 機能 verify gate (= δ 確定項目)

| gate # | 名称 | 内容 |
|---|---|---|
| gate-1 | production sha256 維持 verify | production default build (= 決定 4 (A)) で sha256 = `b15883fe...` 維持 verify (= 全 sub-sprint で常時) |
| gate-2 | v2 fixture build PASS + 全 11 slot active driven | v2 only trace capture build (= 決定 4 (B)) build PASS + 全 11 slot active 駆動の register write trace capture |
| gate-3 | 全 16 ch chip 別代表 register literal 期待値出力 | 全 16 ch (= FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6) trace に chip 別代表 register の literal 期待値出力確認、 round 5 nice-to-have 2 反映 literal: <br>**FM 代表 register** (= per-ch keyon 0x28 (op 4 bit + ch index lower 3 bit) + fnum LSB 0xA0/0xA4 系 + block+fnum MSB 0xA4/0xAC 系 + TL 0x40-0x4F 系 (= operator 別)) <br>**SSG 代表 register** (= tone period 0x00-0x05 (3 ch × 2 byte) + mixer 0x07 (= bit 0-5 で tone/noise enable per-ch) + volume 0x08/0x09/0x0A (= per-ch)) <br>**ADPCM-B 代表 register** (= keyon 0x10 (= bit 7 set) + start LSB/MSB 0x12/0x13 + stop LSB/MSB 0x14/0x15 + delta-N LSB/MSB 0x19/0x1A + volume 0x1B + pan 0x11) <br>**ADPCM-A 代表 register** (= per-ch keyon 0x00 (= bit set per ch) + per-ch start LSB/MSB 0x10-0x15 系 + per-ch stop LSB/MSB 0x18-0x1D 系 + per-ch volume 0x08-0x0D + master volume 0x01) |
| gate-4 | .org section overflow なし verify | 全 fixture / slot init 追加後の .lst で section アドレス範囲確認、 round 5 latent-risk 2 反映 literal = **α/β/γ 各 PR 必須 gate** |
| gate-5 | 既存 verify script ALL PASS 維持 regression | ADR-0049〜0059 既存 verify script ALL PASS 維持 (= 拡張影響なし regression check) |
| gate-6 | IRQ tick 処理量増加 trace window 適合 verify | round 5 latent-risk 1 反映: slot 2-8 active 化で 11-slot dispatch loop 全体処理量増加 → trace capture 秒数 + 期待 write 件数を δ verify script で literal 化 |

#### trace-equivalence は ADR-0068 候補で future
- ADR-0067 δ = 機能 verify のみ (= 「fixture 駆動可能」 「trace に期待値出力」 確認)
- 統合 trace-equivalence (= cmd 0x05 経路 vs v2 経路 比較) = ADR-0068 候補 = future
- **「(a)(b)(c) 3 gate 統合 verify 完了」 / 「roadmap ⑤ 統合 verify 完了」 = ADR-0067 完全禁止** (= §決定 6 literal)

### 決定 6: 表記制約継承 + ADR-0067 新規解禁表現候補 literal 化 + 「roadmap ⑤ 統合 verify 完了」 完全禁止

ADR-0048 ζ-ε + ADR-0061 §決定 6 + ADR-0062 §決定 7 + ADR-0063 §決定 6 + ADR-0064 §決定 6 継承:

| 表現 | ADR-0067 起票時点 | ADR-0067 ε Accepted 後 | 解禁条件 |
|---|---|---|---|
| 「軸 G dynamic supply 完成」 (日英両版) | 使用可 | 継承 | ADR-0048 ζ-ε Accepted 後使用可 (= 継承) |
| 「軸 G 完成」 | literal 禁止維持 | literal 禁止維持 | 軸 G 全体完成は別 axis 完了後 future |
| 「軸 B 完成」 | literal 禁止維持 | literal 禁止維持 | v2 driver production-ready 化 + 本番 cmd 切替後 future |
| 「production-ready 全体達成」 | literal 禁止維持 | literal 禁止維持 | 全 4 gate 達成 + 越川氏 audition + 本番 cmd 切替後 future |
| 「本番 cmd 切替完了」 | literal 禁止維持 | literal 禁止維持 | ADR-0066 完了後のみ |
| **「roadmap ⑤ 統合 verify 完了」** | **literal 禁止 (= ADR-0067 完全禁止)** | **literal 禁止維持** | **ADR-0068 候補 (= 統合 verify ADR) Accepted 後使用可、 ADR-0067 では使用しない** |
| **「(a)(b)(c) 3 gate 統合 verify 完了」** | **literal 禁止 (= ADR-0067 完全禁止)** | **literal 禁止維持** | **ADR-0068 候補 (= 統合 verify ADR) Accepted 後使用可、 ADR-0067 では使用しない** |
| **「16 ch fixture 拡張完了」 (= 新規解禁表現候補)** | **literal 禁止 (= ADR-0067 ε Accepted 前)** | **使用可、 ただし併記必須** | **ADR-0067 ε Accepted 後使用可、 併記必須 = 「roadmap ⑤ 統合 verify 未実装 (= ADR-0068 候補 future)」 + 「production-ready 全体達成ではない」** |

### 決定 7: 不可触対象 literal (= 修正、 fixture / slot init 追加 = allowed-touch)

#### 完全不変
- driver source 内 既存 routine body / dispatcher body / IRQ handler / cmd path
- 既存 fixture (= `_fm_b` / `_ssg_g` / `_adpcmb_j` / `_rhythm_k`) modification = 完全不可、 ADR-0067 で参照のみ (= γ で `_rhythm_k_full` 並設追加、 既存 `_rhythm_k` は不変)
- 既存 verify script (= ADR-0049〜0059 既存 script) modification = 完全不可
- 既存 build flag (= 新規 flag 追加不可)
- vendor
- ADR-0048〜0064 本文 / Annex

#### allowed-touch (= ADR-0067 §決定 3 例外、 ADR-0058/0059 pattern 継承)
- driver source 内 v2 fixture 追加 (= `.if TEST_MODE_V2_SONG_FIXTURE` 配下、 additive)
- `pmdneo_v2_song_init` slot 2-8 active init 追加 + slot 10 fixture pointer switch (= `.if TEST_MODE_V2_SONG_FIXTURE` 配下、 additive)

### 決定 8: 「roadmap ⑤ 統合 verify 完了」 wording 完全禁止 (= 表記制約継承)

ADR-0067 内で「roadmap ⑤ 統合 verify 完了」 を一切書かない。 ADR-0067 ε Accepted = 「16 ch fixture 拡張完了」 milestone のみ。 統合 verify 完了は ADR-0068 候補で future。

### 決定 9: ADR-0068 候補 起票判断 (= ADR-0067 完走後の future)

- ADR-0067 ε Accepted 後、 ADR-0068 候補 (= 16 ch 統合 verify 実作業 ADR) を起票判断 (= user 明示 GO 必須)
- ADR-0068 = ADR-0067 plan v1-v4 base (= sub-sprint α/β/γ/δ/ε pattern、 3 build mode、 trace-equivalence、 等) で起票
- ADR-0067 = ADR-0068 の前提作り

### 決定 10: PR chain plan (= 5 PR、 ADR-0058 / ADR-0059 pattern 継承)

| sub | PR 内容 | doc / 実装 |
|---|---|---|
| 起票 + α | ADR-0067 Draft 起票 + sub-sprint α 着手 + FM 残 5 ch (= A/C/D/E/F) fixture 追加 + slot 2-6 init + Annex α | doc + 実装 |
| β | sub-sprint β + SSG 残 2 ch (= H/I) fixture 追加 + slot 7-8 init + Annex β | 実装 + doc |
| γ | sub-sprint γ + rhythm K bitmap full 拡張 (= ADPCM-A 全 6 ch active 化、 slot 10 fixture pointer switch `_rhythm_k_full`) + Annex γ | 実装 + doc |
| δ | sub-sprint δ + 全 16 ch trace gate verify (= 6 gate literal) + Annex δ | 実装 + doc |
| ε | sub-sprint ε + Draft → Accepted 移行 + Annex ε + 完走 milestone literal (= 「16 ch fixture 拡張完了」) | doc-only |

### 決定 11: 番号 chronology rationale literal (= ADR-0064 §決定 7 継承 + ADR-0067/0068 整合)

ADR-0064 §決定 7 literal「ADR-0067+ = ADR-0064 実作業 ADR」 整合維持:
- **ADR-0067** = driver fixture 拡張 ADR (= 16 ch trace-equivalence 前提作り、 ADR-0064 plan 実作業 1 本目)
- **ADR-0068 候補** = 16 ch 統合 verify ADR (= roadmap ⑤ 完了、 ADR-0064 plan 実作業 2 本目)
- ADR-0064 plan 実作業群 = ADR-0067 + ADR-0068 = 2 ADR chain
- 番号 chronology = ADR-0064 plan → ADR-0065 (= roadmap ⑥ audition、 future) → ADR-0066 (= roadmap ⑦ 本番 cmd 切替、 future) → ADR-0067 fixture 拡張 (= ADR-0064 1 本目) → ADR-0068 統合 verify (= ADR-0064 2 本目)、 ADR-0064 §決定 7 整合維持

### 決定 12: chip target 別 active policy literal (= ADR-0006 §B + ADR-0058 γ comment 継承、 Codex round 6 must-fix 1 反映)

YM2610 target (= `PMDNEO_TARGET_CHIP_YM2610B == 0`、 production default) では **FM ch A/D/F は init せず stream 読捨** (= ADR-0006 §B literal、 公式 NEOGEO YM2610 想定)。 YM2610B target (= AES+ YM2610B 想定) では FM ch A/D/F も init + 発音可能。

ADR-0058 γ comment literal「slot 初期化で active ch_idx のみ選択 (= ym2610 silent skip 対象は init 段階で回避)」 遵守 = `pmdneo_v2_fm_voice_note_song` 側に chip target skip がないため、 **slot init 段階で chip target 別 active policy** を適用する (= Codex round 6 must-fix 1 反映)。

#### slot init chip target 別 active policy

- **slot 3 (= FM ch C、 ch_idx 2)** / **slot 5 (= FM ch E、 ch_idx 4)** = **無条件 active init** (= ym2610 / ym2610b 両 audible、 既存 dispatch 整合)
- **slot 2 (= FM ch A、 ch_idx 0)** / **slot 4 (= FM ch D、 ch_idx 3)** / **slot 6 (= FM ch F、 ch_idx 5)** = `**.if PMDNEO_TARGET_CHIP_YM2610B`** 配下のみ active init (= ym2610b build で active、 ym2610 build (= production default) では clear loop で FLAGS=0 default 維持 = 不活性)

#### trace 結果 (= chip target に依存)

- **ym2610 target (= production default) v2 fixture build trace** = FM C/E の 2 slot のみ active 駆動 = 残 ch B 既存と合わせて FM audible = B/C/E = 3 ch literal keyon trace 出力 (= ADR-0006 §B「ym2610 で A/D/F は init せず stream 読捨」 整合、 slot 2/4/6 は FLAGS=0 で dispatch 段階 skip)
- **ym2610b target (= 別 build) v2 fixture build trace** = FM A/C/D/E/F の 5 slot 全 active 駆動 = 残 ch B 既存と合わせて FM 全 6 ch audible literal keyon trace 出力 (= δ gate-3 別 build verify)

#### fixture data (= chip target 非依存)

`pmdneo_v2_song_fixture_fm_a` / `_c` / `_d` / `_e` / `_f` 全 5 件 = **chip target 非依存** (= driver source 内 `.if TEST_MODE_V2_SONG_FIXTURE` 配下並設、 ym2610 build でも assemble される、 ただし ym2610 では slot 2/4/6 は active 化されないため `_fm_a` / `_d` / `_f` は dispatch されない = unused literal)。

δ gate-3 chip 別代表 register 期待値出力 verify では **ym2610 target trace を primary** (= production default、 FM C/E + 既存 B = 3 ch keyon expected) + **ym2610b target trace を secondary** (= 別 build verify、 FM A/B/C/D/E/F = 全 6 ch keyon expected) で取得。

= ADR-0067 fixture 拡張は ym2610 / ym2610b 両 target 対応、 trace 結果は chip target に依存する (= expected)。 chip 別 active policy literal 固定 (= Codex round 6 latent-risk 1 mitigation)。

## verify gate (= 実作業 ADR、 sub-sprint chain で実行)

### 全 sub-sprint 共通 gate
- production sha256 = `b15883fe...` 維持 mandatory (= 全 sub-sprint で gate-1 として常時 verify)
- ADR-0049〜0064 全 routine body + 本文 + Annex 完全不変 = 履歴改変 risk 回避

### sub-sprint α gate (= 起票 + sub-sprint α 着手 PR)
- ADR-0067 Draft 起票 file 新規 (= 本 ADR doc)
- driver source 内 FM 残 5 ch fixture data 追加 (= `pmdneo_v2_song_fixture_fm_a` / `_c` / `_d` / `_e` / `_f` 5 件) + `pmdneo_v2_song_init` slot 2-6 init 追加 (= **chip target 別 active policy** = slot 3/5 無条件 active + slot 2/4/6 `.if PMDNEO_TARGET_CHIP_YM2610B` 配下、 §決定 12 literal)
- production default build (= TEST_MODE_V2_SONG_FIXTURE=0) sha256 維持 verify
- v2 only trace capture build (= TEST_MODE_V2_SONG_FIXTURE=1 + LEGACY_SKIP=1) build PASS
- .org section overflow なし verify (= .lst で section アドレス範囲確認)
- gate-5 partial PASS 注記 = 既存 `verify-axis-b-v2-song-playback.sh` 10 gate ALL PASS 維持 (= ADR-0049〜0057 baseline regression なし、 ADR-0058 ε ALL PASS 維持)、 **既存 verify script 維持確認のみ、 新規 slot 2/3/4/5/6 (= ym2610 で slot 3/5、 ym2610b で 5 slot) の trace 確認は sub-sprint δ scope** (= Codex round 6 nice-to-have 2 反映 literal)
- α 完走 = FM 残 5 ch fixture 追加 + slot 2-6 init (= chip target 別 active policy) 追加 milestone

### sub-sprint β gate
- driver source 内 SSG 残 2 ch fixture data 追加 + slot 7-8 active init 追加
- (= α 同 gate set 適用、 SSG H/I のみ scope)

### sub-sprint γ gate
- driver source 内 rhythm K bitmap full 拡張 fixture 追加 (= `pmdneo_v2_song_fixture_rhythm_k_full` 新規、 既存 `_rhythm_k` 維持) + slot 10 fixture pointer switch
- (= α 同 gate set 適用、 rhythm K full bitmap のみ scope)

### sub-sprint δ gate (= 機能 verify only、 trace-equivalence は ADR-0068 future)
- gate-1: production sha256 維持
- gate-2: v2 fixture build PASS + 全 11 slot active 駆動
- gate-3: 全 16 ch chip 別代表 register literal 期待値出力 (= 決定 5 literal)
- gate-4: .org section overflow なし
- gate-5: 既存 verify script ALL PASS 維持
- gate-6: IRQ tick 処理量増加 trace window 適合

### sub-sprint ε gate (= Accepted 移行 doc-only)
- ADR-0067 Draft → Accepted 移行
- Annex 全 + 完走 milestone literal (= 「16 ch fixture 拡張完了」)
- 「roadmap ⑤ 統合 verify 完了」 / 「(a)(b)(c) 3 gate 統合 verify 完了」 wording 排除 (= ADR-0067 完全禁止維持)

## Codex layer 2 plan review chain (= 5 round chain、 全 review-only + 越権なし confirmed)

| round | judgment | must-fix / nice-to-have / latent-risk | agentId |
|---|---|---|---|
| round 1 | revise | must-fix 3 (= 新規 fixture scope-in vs driver 不変矛盾 + build mode literal 不足 + 同一 MML song 比較条件未定義) + nh 2 + lr 2 | (= 主軸 main agent 別 thread) |
| round 2 | revise | must-fix 2 (= legacy 混入分離未定義 + α 完了条件弱い) + nh 2 + lr 2 | `a79144083e3153f11` |
| round 3 | revise | must-fix 3 (= β 16 ch feasibility 未確定 + 3 build mode 別名化 + ADPCM-B register 例不正確) + nh 2 + lr 2 | `ac33b8910c197d19e` |
| round 4 | revise (= **escalation 発生**) | must-fix 3 (= β 4 ch 限定 = ADR-0064 §決定 3 (= 16 ch literal) と矛盾、 ADR-0067 = partial / scope 修正必要) → **user 判断 = option Z 採用** = ADR-0067 を fixture 拡張専用 + ADR-0068 = 統合 verify | `a251f89fcc9351c33` |
| round 5 | **approve** | must-fix なし + nice-to-have 2 件 (= slot 10 fixture pointer switch 先 `_rhythm_k_full` 明示 + δ gate-3 chip 別代表 register 列挙) + latent-risk 2 件 (= IRQ tick 処理量増加 risk + .org overflow gate α/β/γ 全 PR 必須) + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed | `a08bc8d848baf3966` |

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

= Codex round 1-5 全 review-only 遵守 confirmed = 越権操作なし + round 5 approve + nice-to-have / latent-risk 全反映で plan v5 確定 + ADR-0067 起票 GO。 user 最終判断 = nice-to-have 2 件 + latent-risk 2 件全 ADR 本文反映 (= 主軸 single edit、 plan v5 → ADR-0067 doc literal 反映済)。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

### やりたいこと

ADR-0064 plan の 16 ch literal trace-equivalence と既存 4 ch fixture cover の矛盾を解消するため、 driver fixture 拡張専用 ADR ADR-0067 を起票 + sub-sprint α 着手 (= FM 残 5 ch fixture + slot init 追加)。 統合 verify は ADR-0068 候補で future。

### 前提

- ADR-0064 Accepted (= PR #127、 roadmap ⑤ plan ADR) + §決定 3 16 ch literal trace-equivalence ground truth + §決定 7 ADR-0067+ = ADR-0064 実作業 ADR
- 既存 fixture cover = 4 ch のみ (= FM B + SSG G + ADPCM-B J + rhythm K)、 全 16 ch carry には driver fixture 拡張必要
- ADR-0058 γ / ADR-0059 γ-δ allowed-touch pattern (= fixture + slot init additive、 既存 routine 不変) 継承
- ADR-0006 §B chip 制約 (= ym2610 target で FM A/D/F 非可聴) 継承
- user 明示 GO option Z = ADR-0067 fixture 拡張専用 + ADR-0068 統合 verify
- Codex layer 2 plan review 5 round chain (= round 1-4 revise + round 4 escalation user 判断 + round 5 approve) 完了 + nice-to-have 2 件 + latent-risk 2 件全反映

### やったこと

- ADR-0067 Draft 起票 (= 5 sub-sprint chain α/β/γ/δ/ε pattern、 ADR-0058 / ADR-0059 同形式)
- driver fixture 拡張専用 ADR scope literal (= 既存 4 ch fixture cover → 16 ch trace-equivalence 可能 driver state へ widen)
- sub-sprint α/β/γ/δ/ε plan literal (= chip 軸 5 段、 FM 残 5 ch / SSG 残 2 ch / rhythm K full / 機能 verify / Accepted)
- driver source allowed-touch literal (= fixture + slot init additive のみ、 既存 routine 不変、 ADR-0058 γ / ADR-0059 γ-δ pattern 継承)
- 2 build mode literal (= production default + v2 only trace capture、 legacy trace capture build = ADR-0068 候補で初使用)
- trace gate verify literal (= δ 6 gate、 機能 verify only、 trace-equivalence は ADR-0068 future)
- 表記制約継承 + 新規解禁表現候補 (= 「16 ch fixture 拡張完了」 = ε Accepted 後使用可、 併記必須)
- 「roadmap ⑤ 統合 verify 完了」 / 「(a)(b)(c) 3 gate 統合 verify 完了」 wording = ADR-0067 完全禁止
- 番号 chronology rationale literal (= ADR-0067 fixture 拡張 + ADR-0068 統合 verify = ADR-0064 実作業群 2 ADR chain)
- chip target 制約 literal (= ADR-0006 §B 継承、 ym2610 target で FM A/D/F 非可聴 = trace に keyon 出ない expected)
- Codex layer 2 plan review 5 round chain literal + 全 review-only + 越権なし confirmed
- nice-to-have 2 件 (= slot 10 pointer switch 明示 + δ gate-3 chip 別代表 register 列挙) + latent-risk 2 件 (= IRQ tick 処理量 + .org overflow gate 全 PR 必須) 全 ADR 本文反映 (= user 明示)

### 結果

- ADR-0067 Draft 起票 + sub-sprint α 着手 ready (= driver fixture 実装 + verify は本 PR 内続く)
- ADR-0064 plan の 16 ch literal と既存 4 ch fixture cover の矛盾を解消する scope literal 確定
- sub-sprint α/β/γ/δ/ε 5 段 plan literal 確定
- production build byte-identical 維持期待 (= 通算 sha256 `b15883fe...`)
- ADR-0049〜0064 本文 + dashboard 既存 0049-0064 行 完全不変
- 「roadmap ⑤ 統合 verify 完了」 wording 完全禁止 + 「16 ch fixture 拡張完了」 ε Accepted 後使用可

### 解釈

ADR-0067 Draft 起票 ≠ roadmap ⑤ 統合 verify 完了 ≠ production-ready 全体達成 ≠ 軸 G 完成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。 ADR-0067 = driver fixture 拡張専用 ADR で 16 ch trace-equivalence 前提作り (= 統合 verify は ADR-0068 候補 future)。 ADR-0058 γ / ADR-0059 γ-δ allowed-touch pattern 継承 = fixture data + slot init additive のみ、 既存 routine body 完全不変。 ADR-0006 §B chip 制約整合 = ym2610 target で FM A/D/F 非可聴 expected。

### 次

PR 作成 (= 起票 + sub-sprint α 着手 PR = doc + 実装) + Codex layer 2 implementation review + **main agent 経路で PR merge** (= Codex 越権 merge 禁止規律遵守) + user 完走報告。 sub-sprint α 完走後、 β/γ/δ/ε 各 PR を continue。 ADR-0067 ε Accepted 後、 ADR-0068 候補 (= 16 ch 統合 verify ADR) 起票判断 (= user 明示 GO 必須)。

## Annex β: β 実装 completion record (= SSG 残 2 ch fixture + slot 7-8 active init)

### 実装内容 (= driver source `src/driver/standalone_test.s` `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive)

- slot 7 (= SSG ch H、 ch_idx 1、 KIND=1) active init = ym2610b α block end と既存 slot 9 init の間に additive (= 無条件 active = ADR-0006 §B 制約対象外、 ym2610 / ym2610b 両 audible)
- slot 8 (= SSG ch I、 ch_idx 2、 KIND=1) active init = slot 7 init 直後 additive (= 無条件 active 同)
- `pmdneo_v2_song_fixture_ssg_h` 新規 .db literal (= `0x42, 0x10, 0x45, 0x10, 0x48, 0x10, 0x80`、 既存 `_ssg_g` 同 pattern) = 既存 `_ssg_g` .db 直後 additive
- `pmdneo_v2_song_fixture_ssg_i` 新規 .db literal (= 同上) = `_ssg_h` 直後 additive

### 配置 base address (= LATENT-RISK 1 mitigation literal、 Codex round 1 反映)

- slot 7 base = `pmdneo_v2_partwork_base + 7*12` = **0xFDCD** (= 主軸計算 verified、 0xFD79 + 0x54)
- slot 8 base = `pmdneo_v2_partwork_base + 8*12` = **0xFDD9** (= 主軸計算 verified、 0xFD79 + 0x60)
- 既存 slot 10 comment line 2792「0xFDDD」 は stale literal (= 0xFD79 + 0x64、 実 expression emit 値 = 0xFDF1 = 0xFD79 + 0x78、 ADR-0059 δ 時点の comment typo、 既存 routine body 不変ルールで β scope-out、 slot 7/8 では計算結果 literal 正確値使用)

### verify gate 結果 (= ADR-0067 § verify gate sub-sprint β gate literal、 α 同 gate set 適用)

- production default build (= `TEST_MODE_V2_SONG_FIXTURE=0`) sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 verified (= 通算 ADR-0058〜0064〜0067 α 継承、 β 改変後も literal 一致 confirmed)
- v2 only trace capture build (= `TEST_MODE_V2_SONG_FIXTURE=1` + `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP=1`) build PASS verified (= `verify-axis-b-v2-song-playback.sh` 内 ε fixture build step pass)
- .org section overflow なし verified (= `verify-axis-b-v2-song-playback.sh` roadmap2-gate-6 (a) literal pass = 15 routine 全 >= 0x0610 + 0x0066 セクション max addr < 0x0100、 β PR 必須 gate = ADR-0067 §決定 5 round 5 latent-risk 2 反映)
- 既存 `verify-axis-b-v2-song-playback.sh` 10 gate (= roadmap2-gate-1〜6 + sup-IX/IY + sup-TIMER-B + sup-γ-pattern + sup-cold-boot) ALL PASS 維持 verified (= LATENT-RISK 2 mitigation literal = 既存 script label checks は `_fm_b` / `_ssg_g` のみ、 SSG H/I active 化の trace 確認は δ scope、 β は維持確認のみ)

### Codex layer 2 review chain

- plan review chain:
  - round 1 **revise** (= must-fix 1 = Annex β 追加要求 + nice-to-have 0 + latent-risk 2 = slot 10 stale comment 警戒 + verify script label scope、 agentId `a3120f8d13f068af1`、 job `task-mpjd6dlm-5b546s`、 elapsed 2m 1s)
  - round 2 **approve** (= must-fix 0 + nice-to-have 0 + latent-risk 1 = α 漏れ追跡 ε 引き継ぎ文言、 plan v2 = Annex β literal 追加 + LATENT-RISK 1/2 明示 mitigation 反映、 agentId `a7a70830496954f89`、 job `task-mpjdnj85-qijit0`、 elapsed 2m、 越権操作なし confirmed)
- implementation review chain: (= 後続、 PR 作成後投入)

### α 漏れ補完 (= ε retrospective 候補、 ADR-0058/0059 Annex pattern 整合、 Codex round 2 LATENT-RISK 1 反映 ε 引き継ぎ文言強化)

- α PR (= bfd4009 + 159c05f + merge 378850b) では ADR-0067 §決定 10 line 215 plan literal「+ Annex α」 が doc に section 追加されなかった漏れ (= ADR-0067 本文に `## Annex` section 全て不在 = Annex A ground truth / Annex B 構成図 / Annex α 全て漏れ、 β PR で初の `## Annex β` section 追加)
- β PR では Annex β 単独追加 = α 漏れの retrospective 補完は ε で行う default candidate (= ε で Annex A/B/α/β/γ/δ/ε 全 section 統合追加、 ADR-0058 Annex G ζ Accepted 移行時に retrospective 補完 pattern 候補継承)
- **ε 担当者引き継ぎ literal**: ε sub-sprint 担当者 (= 主軸 Claude Code or 後続 session) は本 § Annex β「α 漏れ補完」 sub-section を **ε retrospective 補完 default candidate** として参照し、 ε PR で次の Annex section を統合追加する (= ADR-0067 完走時の Annex 構造): (1) Annex A = ADR-0067 ground truth (= 既存 4 ch fixture cover + 16 ch 要求の矛盾) / (2) Annex B = 構成図 (= 16 ch fixture chip target 別 active policy 図) / (3) Annex α = α 完了 record (= FM 残 5 ch + slot 2-6 + chip target 別 active policy) / (4) Annex β = 本 section (= 既存維持) / (5) Annex γ = γ PR で追加 (= rhythm K full bitmap) / (6) Annex δ = δ PR で追加 (= 機能 verify only 6 gate) / (7) Annex ε = ε 完了確認 + Draft → Accepted。 ε 担当者は本引き継ぎ literal を ε PR review chain literal で reference + ADR-0058 Annex G / ADR-0059 Annex G retrospective 補完 pattern を継承する。

### 状態維持

- ADR-0067 Draft 維持 (= ε まで Draft、 § 決定 1〜12 本文不変)
- 「16 ch fixture 拡張完了」 wording = β 完走では未解禁、 ε Accepted 後使用可 + 併記必須 (= ADR-0067 §決定 6 表記制約 literal)
- 「roadmap ⑤ 統合 verify 完了」 / 「(a)(b)(c) 3 gate 統合 verify 完了」 wording = ADR-0067 完全禁止維持

## Annex γ: γ 実装 completion record (= rhythm K bitmap full 拡張 + slot 10 fixture pointer switch)

### 実装内容 (= driver source `src/driver/standalone_test.s` `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive)

- `pmdneo_v2_song_fixture_rhythm_k_full` 新規 .db literal (= 既存 `pmdneo_v2_song_fixture_rhythm_k` 直後 additive、 ADPCM-A 全 6 ch 順次 trigger 6 段 bitmap = BD/SD/CYM/HH/TOM/RIM)
- slot 10 ADDR pointer 1 行 edit = `_rhythm_k` → `_rhythm_k_full` (= AUDITION_REVISE=0 default 経路のみ、 AUDITION_REVISE=1 audition 経路は `_rhythm_k_audition` で完全保護)
- 既存 `_rhythm_k` (= ADR-0059 δ literal、 BD→SD→BD 3 段 bitmap) **完全不変** (= ADR-0067 §決定 7 allowed-touch literal「既存 fixture 維持 + 拡張版 additive」 整合)

### 配置 + bitmap convention literal

- bitmap convention 継承 (= ADR-0059 §決定 5 案 A literal): `bit 0 = BD` / `bit 1 = SD` / `bit 2 = CYM` / `bit 3 = HH` / `bit 4 = TOM` / `bit 5 = RIM`、 末尾 `0x80` = loop marker (= bit 7 set)
- 新規 `_rhythm_k_full` byte sequence (= 13 byte): `0x01, 0x10, 0x02, 0x10, 0x04, 0x10, 0x08, 0x10, 0x10, 0x10, 0x20, 0x10, 0x80` (= 6 段 × 2 byte + 1 byte loop)
- 主軸 judgment = **案 A per-bit 順次 trigger** (= 既存 `_rhythm_k` BD→SD→BD per-bit pattern 継承、 simultaneous 0x3F より安全 = simultaneous combo は既存 routine scope-out 確認)
- parser alternation 安全性 confirmed (= Codex layer 2 plan review γ round 1 approve、 note byte `< 0x80` = note handling 経路、 length は別 fetch、 note byte `0x10` TOM bitmap と length byte `0x10` 16 tick は alternation 位置で区別)

### verify gate 結果 (= ADR-0067 § verify gate sub-sprint γ gate literal、 α 同 gate set 適用)

- production default build (= `TEST_MODE_V2_SONG_FIXTURE=0`) sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 verified (= 通算 ADR-0058〜0064〜0067 α/β 継承、 γ 改変後も literal 一致 confirmed)
- v2 only trace capture build (= `TEST_MODE_V2_SONG_FIXTURE=1` + `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP=1`) build PASS verified (= `verify-axis-b-v2-song-playback.sh` 内 ε fixture build step pass)
- .org section overflow なし verified (= `verify-axis-b-v2-song-playback.sh` roadmap2-gate-6 (a) literal pass、 γ PR 必須 gate = ADR-0067 §決定 5 round 5 latent-risk 2 反映)
- 既存 `verify-axis-b-v2-song-playback.sh` 10 gate ALL PASS 維持 verified (= **新規 rhythm K full trace 確認は δ scope、 γ は維持確認のみ** = Codex γ plan review LATENT-RISK 1 反映 literal、 既存 script label checks は `_fm_b` / `_ssg_g` のみで K full は未 cover、 全 16 ch trace 取得 + 期待値 literal 確認は δ で行う)

### Codex layer 2 review chain

- plan review chain: round 1 **approve** (= must-fix 0 + nice-to-have 1 = β 後 line ref stale (= 非 blocker、 label-based placement で問題なし、 current line refs slot 10 toggle = `src/driver/standalone_test.s:2848-2853` + 既存 `_rhythm_k` = `:3295`) + latent-risk 1 = γ wording「all 6 ADPCM-A trace verified」 禁止 + 「新規 rhythm K full trace 確認は δ scope」 wording 維持、 bitmap parser 安全性 confirmed + 案 A judgment confirmed、 越権操作なし confirmed)
- implementation review chain: (= 後続、 PR 作成後投入)

### α 漏れ補完継承 (= Annex β「α 漏れ補完」 sub-section 継承、 ε retrospective 候補 default 維持)

- α PR (= bfd4009 + 159c05f + merge 378850b) で §決定 10 line 215 plan literal「+ Annex α」 が doc に追加されなかった漏れ = Annex β 内「α 漏れ補完」 sub-section 記録継承 (= ε で Annex A/B/α/β/γ/δ/ε 全 section 統合追加 default candidate)
- γ では α 漏れに対する新規 issue なし、 β literal「ε 担当者引き継ぎ literal 強化」 継承維持

### 状態維持

- ADR-0067 **Draft 維持** (= ε まで Draft、 § 決定 1〜12 本文不変)
- 「16 ch fixture 拡張完了」 wording = γ 完走では未解禁、 ε Accepted 後使用可 + 併記必須 (= ADR-0067 §決定 6 表記制約 literal)
- 「roadmap ⑤ 統合 verify 完了」 / 「(a)(b)(c) 3 gate 統合 verify 完了」 wording = ADR-0067 完全禁止維持
- 「all 6 ADPCM-A trace verified」 / 「全 6 ch ADPCM-A 実音 verified」 等 trace 完了表現 = γ 完走では使用不可 (= δ scope = Codex γ plan review LATENT-RISK 1 反映)

## Annex δ: δ 実装 completion record (= 全 16 ch fixture 駆動 trace gate verify、 機能 verify only、 6 gate 全 PASS)

### 実装内容 (= 新規 verify script、 driver source 完全不変)

- 新規 verify script: `src/test-fixtures/axis-b/verify-axis-b-v2-fixture-expansion-delta.sh` (= ADR-0067 §決定 7 allowed-touch literal「driver source 完全不変、 新規 verify script のみ」 遵守)
- 既存 verify script (= `verify-axis-b-v2-song-playback.sh` 等 ADR-0049〜0059 全) 完全不変
- driver source (= `src/driver/standalone_test.s` slot init / fixture data / 既存 routine) 完全不変

### 6 gate literal (= ADR-0067 §決定 5 literal)

| gate # | scope | 実行値 |
|---|---|---|
| gate-1 | production sha256 維持 | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` literal 一致 (= 通算 ADR-0058〜0064〜0067 α/β/γ 継承、 δ 改変なし = 新規 verify script のみ追加) |
| gate-2 | v2 fixture build PASS + active slot driven (= chip target 別) | ym2610 = 8 slot (= FM B/C/E + SSG G/H/I + ADPCM-B J + rhythm K) + ym2610b = 11 slot (= + FM A/D/F = chip target 別 active policy ADR-0067 §決定 12 整合) |
| gate-3 | 全 16 ch chip 別代表 register literal 期待値出力 | FM (= ym2610 B/C/E + ym2610b A/D/F port A reg 0x28 keyon value F1/F2/F5 + F0/F4/F6) + SSG (= G/H/I tone period port A reg 0x00-0x05 + mixer 0x07 + volume 0x08-0x0A) + ADPCM-B (= port A reg 0x10 keyon bit 7 + 0x11 pan + 0x12/0x13 start + 0x14/0x15 stop + 0x19/0x1A delta-N + 0x1B volume) + ADPCM-A (= L ch 固定 6 drum trigger = port B reg 0x100 keyon mask 0x01 x 66 件 + 0x108 vol 0xDF x 66 件 + 0x110 START_LSB uniq 6/66 件 + 0x118 START_MSB 0x00 x 66/66 件 + 0x120 STOP_LSB uniq 6/66 件 + 0x128 STOP_MSB 0x00 x 66/66 件) 全 PASS |
| gate-4 | .org section overflow なし | 0x0066 セクション max addr `0x0000FD` < 0x0100 (= overflow なし、 K full bitmap 拡張後も維持) |
| gate-5 | representative 2 script regression | `verify-axis-b-v2-song-playback.sh` (= ADR-0058 ε 体系化 10 gate + transitively `verify-axis-b-fm-ssg-real-sound.sh` = ADR-0049〜0057 transitively cover) + `verify-axis-b-v2-roadmap3-dispatch.sh` (= ADR-0059 ε) 両 ALL PASS |
| gate-6 | IRQ tick 処理量 trace window 適合 | actual IRQ count = **2270 件** (= threshold >= 2000 PASS、 γ baseline 2261 件から +9 件 = β/γ active 追加で dispatch loop 微増、 -12% 余白十分) |

### 重要仕様明示 (= ADR-0067 §決定 5 literal vs 実 driver 整合)

#### ADPCM-A L ch 固定 + sample addr 差分仕様 (= Codex plan review round 1/2 must-fix 反映)

ADR-0067 §決定 5 gate-3 ADPCM-A literal「per-ch keyon 0x00 (= bit set per ch) + per-ch start LSB/MSB 0x10-0x15 系 + per-ch stop LSB/MSB 0x18-0x1D 系 + per-ch volume 0x08-0x0D + master volume 0x01」 は **ADR 起票時の理論的 register map**。 実 driver `pmdneo_rhythm_event_trigger` (= `src/driver/standalone_test.s:5295-5345`) = **L ch (= ch 0) 固定** + 各 drum sample addr 差分仕様 (= ADR-0026 §決定 4「L ch (= ch 0) 暫定占有 scaffold」 由来)。 各 drum BD/SD/CYM/HH/TOM/RIM は同 6 件 register write を ym2610_write_port_b 経由で発行:

- port B reg 0x10 (= START_LSB) = drum 別 sample addr 差分 (= 6 drum で unique value 6 件)
- port B reg 0x18 (= START_MSB) = **全 drum 0x00 固定** (= sample 16-bit space 内、 既存 step12/13/17 verify literal 整合)
- port B reg 0x20 (= STOP_LSB) = drum 別差分 (= unique 6 件)
- port B reg 0x28 (= STOP_MSB) = 全 drum 0x00 固定
- port B reg 0x08 = vol/pan 0xDF 固定 (= 0xC0 pan | 0x1F vol)
- port B reg 0x00 = keyon mask 0x01 (= L ch bit 0、 全 drum 共通)

ADR 修正は scope-out (= ADR-0067 §決定 1〜12 本文不変規律遵守)、 本 Annex δ で literal 化。

#### FM keyon 全 ch port A reg 0x28 一本仕様 (= Codex plan review round 1 must-fix 2 反映)

FM keyon = 全 ch port A reg 0x28 一本 (= `fm_keyon_values` F0/F1/F2/F4/F5/F6、 `src/driver/standalone_test.s:1238/1523`)。 port B 経由は fnum/TL 等 ch >= 3 のみ (= `src/driver/standalone_test.s:1045/4397`、 ym2610b 限定)。

#### gate-5 scope literal limit (= Codex plan review round 1 must-fix 3 反映)

ADR-0067 §決定 5 gate-5 literal「ADR-0049〜0059 既存 verify script ALL PASS 維持」 を **v2 driver 関連 representative 2 script** で direct cover、 他 ADR-0049〜0057 系 verify script (= mute / fade / tone-enable / sram-placement / axis-connection / v2-entry 等) は production sha256 維持 (= gate-1) によって m1 ROM byte-identical = ADR-0049〜0057 全 routine byte-identical proof = transitively regression OK。

### trace TSV format literal

- ymfm-trace.tsv: `# write_idx\tport\treg\tvalue`
- port A = chip register 0x00-0xFF (= FM 1-3 ch + SSG + ADPCM-B)
- port B = chip register 0x100-0x1FF (= ADPCM-A + FM 4-6 ch ym2610b 限定 = 3 桁 hex 表記)
- ADR-0067 §決定 5 gate-3 ADPCM-A literal「0x00/0x10/0x18 系」 は driver source level の reg literal、 trace TSV では port B 3 桁 hex (= 0x100/0x110/0x118 系) で記録

### Codex layer 2 review chain

- plan review chain: round 1 **revise** (= must-fix 3 = ADPCM-A per-ch expected 不整合 + FM port B keyon 誤り + gate-5 範囲狭い + nh 1 + lr 0、 agentId `a17acc836d9dadd6f`、 elapsed 4m 31s) → round 2 **revise** (= must-fix 1 = ADPCM-A MSB unique >= 6 false FAIL 修正、 既存 step12/13/17 verify literal 整合、 agentId `a34c78814c619f335`、 elapsed 2m 0s) → round 3 **approve** (= must-fix 0 + nh 0 + lr 0、 既存 step verify literal 完全整合 confirmed、 agentId `a1189768f6a4522fb`、 elapsed 1m 14s)
- implementation review chain: (= 後続、 PR 作成後投入)

### α 漏れ補完継承 (= Annex β「α 漏れ補完」 sub-section 継承、 ε retrospective 候補 default 維持)

- δ では α 漏れに対する新規 issue なし、 β/γ literal「ε 担当者引き継ぎ literal 強化」 継承維持

### 状態維持

- ADR-0067 **Draft 維持** (= ε まで Draft、 § 決定 1〜12 本文不変)
- 「16 ch fixture 拡張完了」 wording = **δ 完走では未解禁** (= ε Accepted 後使用可 + 併記必須)
- 「trace-equivalence 完了」 wording = **使用不可** (= ADR-0068 候補 future、 δ は機能 verify only)
- 「roadmap ⑤ 統合 verify 完了」 / 「(a)(b)(c) 3 gate 統合 verify 完了」 = ADR-0067 完全禁止維持
- 「production-ready 全体達成」 / 「軸 B 完成」 = literal 禁止維持
- **δ 新規解禁表現**: 「全 16 ch trace 取得」 / 「機能 verify 完了」 = δ scope literal で使用可 (= 主軸 judgment + Codex round 3 approve confirmed)

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0067 新規起票 Draft (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目、 driver fixture 拡張専用 ADR、 sub-sprint α/β/γ/δ/ε chain、 起票 + sub-sprint α 着手 PR、 Codex layer 2 plan review 5 round chain = round 1-4 revise + round 4 escalation user option Z 採用 + round 5 approve、 nice-to-have 2 + latent-risk 2 全 ADR 本文反映、 chip target 制約 ADR-0006 §B 継承 literal、 「roadmap ⑤ 統合 verify 完了」 wording 完全禁止、 「16 ch fixture 拡張完了」 = ε Accepted 後使用可解禁表現候補) | (= 初版 commit `bfd4009`) |
| 2026-05-24 | 39th session | Codex layer 2 implementation review round 6 revise 反映 (= must-fix 2 (= slot 2/4/6 chip target 別 active policy + dashboard 0065/0066 placeholder 行追加) + nice-to-have 2 (= ADR comment chip 制約整合 + α gate-5 partial PASS 注記) 全反映、 §決定 2 sub-sprint α scope row 更新 + §決定 12 chip target 別 active policy literal 全面書き換え + § verify gate sub-sprint α gate-5 注記追加、 driver source slot 3/5 = 無条件 active + slot 2/4/6 = `.if PMDNEO_TARGET_CHIP_YM2610B` 配下 active 化 修正、 ADR-0058 γ comment「slot 初期化で active ch_idx のみ選択 (= ym2610 silent skip 対象は init 段階で回避)」 遵守、 production sha256 = `b15883fe...` 維持 confirmed、 ym2610 v2 fixture build sha256 = `33dfce3e...` (= chip target fix 反映後の新値、 ym2610 では slot 2/4/6 init 未 assemble)、 latent-risk 1 (= chip 別 active policy literal 固定) + latent-risk 2 (= dashboard 番号順 = 既存運用整合) mitigation 反映) | (= round 6 反映 commit、 後続) |
| 2026-05-24 | 39th session | ADR-0067 sub-sprint β = SSG 残 2 ch (= H/I) fixture 追加 + slot 7-8 active init 追加 完走 milestone (= driver `src/driver/standalone_test.s` `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive、 SSG H/I 無条件 active = ADR-0006 §B 制約対象外 ym2610 / ym2610b 両 audible、 既存 `_ssg_g` / `_fm_b` / `_adpcmb_j` / `_rhythm_k` / α 追加 `_fm_a/c/d/e/f` 完全不変、 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 verified、 v2 fixture build PASS、 .org section overflow なし verified、 既存 `verify-axis-b-v2-song-playback.sh` 10 gate ALL PASS 維持 verified、 § Annex β section 新規追加 (= ADR-0058/0059 Annex C pattern 継承)、 α 漏れ補完は ε retrospective 候補 default + ε 担当者引き継ぎ literal 強化 (= Codex round 2 LATENT-RISK 1 反映)、 Codex layer 2 plan review 2 round chain (= round 1 revise must-fix 1 = Annex β 追加要求 + latent-risk 2 + round 2 approve must-fix 0 + latent-risk 1 = α 漏れ追跡 ε 引き継ぎ) 全反映 + 越権操作なし confirmed、 ADR-0067 Draft 維持) | (= β commit `a71f32a` + dashboard fix `2190388`、 PR #129 MERGED at `be453e3`) |
| 2026-05-24 | 39th session | ADR-0067 sub-sprint γ = rhythm K bitmap full 拡張 (= ADPCM-A 全 6 ch active 化、 案 A per-bit 順次 trigger 6 段 bitmap = BD/SD/CYM/HH/TOM/RIM) + slot 10 fixture pointer switch (= `_rhythm_k` → `_rhythm_k_full`、 AUDITION_REVISE=0 default 経路のみ、 AUDITION_REVISE=1 audition 経路完全保護) 完走 milestone (= driver `src/driver/standalone_test.s` `.if TEST_MODE_V2_SONG_FIXTURE` 配下 additive + 1 行 edit、 既存 `_rhythm_k` 完全不変、 既存 `_fm_b` / `_ssg_g` / `_adpcmb_j` / α 追加 `_fm_a/c/d/e/f` / β 追加 `_ssg_h/_ssg_i` 完全不変、 production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 verified、 v2 fixture build PASS、 .org section overflow なし verified、 既存 `verify-axis-b-v2-song-playback.sh` 10 gate ALL PASS 維持 verified、 § Annex γ section 新規追加 (= β Annex pattern 継承、 6 sub-section = 実装内容 + 配置 + bitmap convention + verify gate + Codex review chain + α 漏れ補完継承 + 状態維持)、 Codex layer 2 plan review 1 round approve (= must-fix 0 + nh 1 = β 後 line ref stale 非 blocker + lr 1 = wording「新規 rhythm K full trace 確認は δ scope」 維持、 bitmap parser 安全性 confirmed + 案 A judgment confirmed) + 越権操作なし confirmed、 ADR-0067 Draft 維持) | (= γ commit `aeae373`、 PR #130 MERGED at `b9a5411`) |
| 2026-05-24 | 39th session | ADR-0067 sub-sprint δ = 全 16 ch fixture 駆動 trace gate verify (= 機能 verify only、 trace-equivalence は ADR-0068 future) + 新規 verify script `verify-axis-b-v2-fixture-expansion-delta.sh` 実装 (= 6 gate literal = sha256 + active slot driven + 全 16 ch chip 別代表 register + .org overflow + representative 2 script regression + IRQ tick 処理量) 完走 milestone (= driver source 完全不変 = ADR-0067 §決定 7 allowed-touch literal「driver source 完全不変、 新規 verify script のみ」 遵守、 既存 ADR-0049〜0059 verify script 全て不変、 6 gate 全 PASS verified = production sha256 `b15883fe...` 維持 + ym2610 active 8 slot + ym2610b active 11 slot + 全 16 ch chip 別 register literal (= FM port A 0x28 keyon F0-F6 + SSG port A 0x00-0x05 tone + 0x07 mixer + 0x08-0x0A volume + ADPCM-B port A 0x10-0x1B + ADPCM-A port B 0x100/0x108/0x110/0x118/0x120/0x128 L ch 固定 + sample addr 差分 + MSB 0x00 固定) + .org max 0x0000FD < 0x0100 + representative 2 script ALL PASS + IRQ count 2270 (>= 2000) + ADR-0067 §決定 5 ADPCM-A literal vs 実 driver L ch 固定仕様の差分を Annex δ literal 化 (= ADR-0026 §決定 4 L ch 暫定占有 scaffold 由来、 ADR 修正 scope-out) + FM keyon 全 ch port A reg 0x28 一本仕様 literal 化 + gate-5 scope literal limit (= v2 driver 関連 representative 2 script direct cover + 他 script は production sha256 維持で transitively regression OK)、 § Annex δ section 新規追加 (= 7 sub-section = 実装内容 + 6 gate literal + 重要仕様明示 + trace TSV format literal + Codex review chain + α 漏れ補完継承 + 状態維持)、 Codex layer 2 plan review 3 round chain (= round 1 revise must-fix 3 ADPCM-A 不整合 + FM port 誤り + gate-5 範囲狭い + 1 nh + 0 lr + round 2 revise must-fix 1 MSB unique false FAIL + round 3 approve must-fix 0 + nh 0 + lr 0) 全反映 + 越権操作なし confirmed、 ADR-0067 Draft 維持) | (= δ commit hash 後続、 PR # 後続) |
