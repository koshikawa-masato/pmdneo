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
| α | FM 残 5 ch fixture data 追加 + slot 2-6 active init | FM A/C/D/E/F | `pmdneo_v2_song_fixture_fm_a` / `_c` / `_d` / `_e` / `_f` 新規 | slot 2 (FM A、 ch_idx 0) / slot 3 (FM C、 ch_idx 2) / slot 4 (FM D、 ch_idx 3) / slot 5 (FM E、 ch_idx 4) / slot 6 (FM F、 ch_idx 5) FLAGS=1 active | YM2610 (= production default) | trace tmp 前後 clean literal + .org overflow gate 必須 (= round 5 latent-risk 2 反映、 全 sub-sprint PR 必須) |
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

### 決定 12: chip target 制約 literal (= ADR-0006 §B 継承、 plan v5 追加 detail)

YM2610 target (= `PMDNEO_TARGET_CHIP_YM2610B == 0`、 production default) では **FM ch A/D/F は init せず stream 読捨** (= ADR-0006 §B literal、 公式 NEOGEO YM2610 想定)。 YM2610B target (= AES+ YM2610B 想定) では FM ch A/D/F も init + 発音可能。

ADR-0067 FM 残 5 ch fixture 追加 + slot init は **chip target に依存しない物理追加** (= 5 slot 全て active 化、 fixture data 5 件追加):

- **ym2610 target (= production default) trace では FM C/E のみ audible** (= 2 ch、 残 ch B 既存と合わせて FM audible = B/C/E = 3 ch)、 A/D/F は stream 読捨 = trace に keyon 出ない (= expected behavior、 ADR-0006 §B literal)
- **ym2610b target (= 別 build) trace では FM A/C/D/E/F 全 5 ch audible** (= 残 ch B 既存と合わせて FM 全 6 ch audible)、 δ で別 build verify

δ gate-3 chip 別代表 register 期待値出力 verify では **ym2610 target trace を primary** (= production default) + **ym2610b target trace を secondary** (= 別 build verify、 全 6 ch audible 確認) で取得。

= ADR-0067 fixture 拡張は ym2610 / ym2610b 両 target 対応、 trace 結果は chip target に依存する (= expected)。

## verify gate (= 実作業 ADR、 sub-sprint chain で実行)

### 全 sub-sprint 共通 gate
- production sha256 = `b15883fe...` 維持 mandatory (= 全 sub-sprint で gate-1 として常時 verify)
- ADR-0049〜0064 全 routine body + 本文 + Annex 完全不変 = 履歴改変 risk 回避

### sub-sprint α gate (= 起票 + sub-sprint α 着手 PR)
- ADR-0067 Draft 起票 file 新規 (= 本 ADR doc)
- driver source 内 FM 残 5 ch fixture data 追加 (= `pmdneo_v2_song_fixture_fm_a` / `_c` / `_d` / `_e` / `_f` 5 件) + `pmdneo_v2_song_init` slot 2-6 active init 追加 (= 5 slot)
- production default build (= TEST_MODE_V2_SONG_FIXTURE=0) sha256 維持 verify
- v2 only trace capture build (= TEST_MODE_V2_SONG_FIXTURE=1 + LEGACY_SKIP=1) build PASS
- .org section overflow なし verify (= .lst で section アドレス範囲確認)
- α 完走 = FM 残 5 ch fixture 追加 + slot 2-6 active init 追加 milestone

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

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0067 新規起票 Draft (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目、 driver fixture 拡張専用 ADR、 sub-sprint α/β/γ/δ/ε chain、 起票 + sub-sprint α 着手 PR、 Codex layer 2 plan review 5 round chain = round 1-4 revise + round 4 escalation user option Z 採用 + round 5 approve、 nice-to-have 2 + latent-risk 2 全 ADR 本文反映、 chip target 制約 ADR-0006 §B 継承 literal、 「roadmap ⑤ 統合 verify 完了」 wording 完全禁止、 「16 ch fixture 拡張完了」 = ε Accepted 後使用可解禁表現候補) | (= 本 commit) |
