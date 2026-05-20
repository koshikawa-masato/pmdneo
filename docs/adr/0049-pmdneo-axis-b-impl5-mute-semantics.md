# ADR-0049: PMDNEO 軸 B 実装 sprint 5 = mute semantics (= 任意 ch / 任意 part 即 mute + unmute、 PMD V4.8s mask 構造 ground truth + 案 1 = 既存 1-bit mask 拡張) 設計 (= sprint 5 α、 5 sub-sprint 構成、 doc-only filing)

- 状態: **Draft** (= 2026-05-20 38th session 軸 B 実装 sprint 5 α、 ADR-0045 §J-4-5 literal 後続実装 ADR、 Codex layer 2 計 5 round chain approve = 6 sprint 比較 round 1-3 + kickoff 計画 round 1-2)
- 起票日: 2026-05-20
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §Annex J-4-5 で実装 sprint 5 = mute semantics を literal 化、 本 ADR の母 ADR)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化 default 永続化、 §決定 7 dashboard 一元管理)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**、 軸 G を完成扱いしない)
  - ADR-0044 (= 軸 F MML compiler 拡張 完成扱い、 F-2-A 将来 sprint defer 維持、 本 ADR で MML mask command 経路は scope-out)
  - ADR-0043 (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触**、 production-ready 保護)
  - ADR-0023 / ADR-0024 / ADR-0025 (= sample_table_id selection arch、 ADPCM-A/B keyon 経路参照)
  - ADR-0026〜ADR-0031 (= K/R rhythm dispatch、 **本 ADR で完全不可触**)
- 関連 memory:
  - `project_pmdneo_37th_session_complete.md` (= 軸 B 設計 ADR 完了 = 実装 sprint 起票 ready、 mute 3 層分離 / fade-out 2 層分離 ground truth literal、 register trace primary gate)
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律、 軸 B 実装 sprint 起票 prompt 規律基盤)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化、 38th session 適用継続)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 mute semantics verify gate 基盤)
  - `feedback_audio_gate_solo_isolation.md` (= 聴感 gate で対象音源 solo 化、 mute semantics 安定化動機)

## 背景 (= why now)

### 軸 B 設計 ADR 完了 base + 実装 sprint 起票 phase

37th session で軸 B 設計 ADR (= ADR-0045) が Draft → Accepted 移行完了した (= 5 段 α/β/γ/δ/ε 全走 + 計 6 PR MERGED + Codex layer 2 13+ round 全 chain approve)。 ただし **設計 ADR Accepted = 設計 ADR 完了であり、 軸 B 実装完了ではない** (= memory `feedback_axis_design_adr_accepted_vs_implementation_completion.md` literal、 「軸 B 完成」 表現禁止)。 ADR-0045 §J-4 で実装 sprint 6 候補 (= 実装 1-4 + 実装 5 mute semantics + 実装 6 fade-out semantics) を bridging note として literal 化済。

### 38th session 6 sprint 比較 → priority 5→6→1→2→3→4 + sprint 5 案 1 GO

38th session で主軸が ADR-0045 §J-4 の実装 sprint 6 候補を 8 観点で比較し、 Codex layer 2 (= session `019e3425-3327-74e1-95bc-461cc5d0af66`) に 3 round chain で投入、 round 3 approve 取得。 user 判断:

- **priority 5 → 6 → 1 → 2 → 3 → 4** (= mute semantics 最優先、 fade-out semantics 次点)
- **sprint 5 mute = 案 1 GO** (= 既存 1-bit mask 拡張 + 即 mute path 追加 + next dispatch restore)
- sprint 6 fade-out = 案 1 GO (= 後続 sprint)
- sprint 3 F-2-B hook 3 案は後続 sprint 3 kickoff で user 選択

### audio gate 安定化動機 (= user 明示)

以前の audition で余計な FM 音が残り、 聴感判定が難しかった経験から、 user は mute / fade-out semantics を先に固めることを明示指示した。 mute semantics を driver behavior level で確立し register trace で検証可能にすることで、 以降の実装 sprint (= 1-4) の audio gate を安定化させる (= memory `feedback_audio_gate_solo_isolation.md` 聴感 gate solo 化規律の driver 側基盤)。

### 既存実装 base + 不足箇所

現 PMDNEO active driver (= `src/driver/standalone_test.s`) の mask 機構:

- `PART_OFF_MASK` (= L83 `.equ PART_OFF_MASK, 30`) = part workarea offset 30 の **1-bit boolean** (= 0=audible / 1=mask silent)
- `nmi_cmd_mask_part` (= L710-728) = NMI command 24-37 で part_idx (= cmd byte - 24) 算出 → `PART_OFF_MASK(ix) = 1` を set **のみ**
- `pmdneo_part_main_note_dispatch` (= L1990) = note dispatch 前に `PART_OFF_MASK(ix)` 参照 → 非 0 なら `ret` (= note keyon を抑止)

**不足箇所** (= ground truth 調査で確定):

1. **即 keyoff が存在しない** = mask set 時に既発音中の ch を keyoff しない。 現状は「次の note dispatch を抑止する」 だけで、 mask 設定時点で鳴っている音は自然減衰まで残る
2. **unmask 経路が存在しない** = `nmi_cmd_mask_part` は `PART_OFF_MASK = 1` を set するのみ。 mask を 0 に戻す (= unmute) 経路がない
3. **chip 別 safe-state 処理が存在しない** = FM/SSG/ADPCM-A/ADPCM-B 各 chip の safe-state register 処理がない

PMD V4.8s / PMDDotNET は mask-on 時に `silence_fmpart` (= FM TL 最大減衰 + RR 最速 + keyoff) / `psgmsk` (= SSG mixer off) を呼び **即 silence** する (= Annex A literal)。 現 PMDNEO の next-keyon suppress only は user 要件「任意 ch / 任意 part の即 mute」 を満たさない。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0049 を起票、 後続 sub-sprint β/γ/δ/ε で即 mute path 実装 → unmute path 実装 → register trace verify gate → completion を段階的に進める。

## 決定

### 決定 1: 軸 B sprint 5 sub-sprint 構成 = 5 段 α/β/γ/δ/ε

mute semantics 実装を **5 段階 α/β/γ/δ/ε** に分割する。 α = ground truth 調査 + ADR 起票 (= doc-only)、 β = 即 mute path 実装、 γ = unmute path 実装、 δ = register trace verify gate 確立、 ε = completion + Accepted 判断。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | PMD V4.8s / PMDDotNET mask 構造 ground truth 全数調査 + 現 PMDNEO mask 経路調査 + ADPCM-A keyoff direct-call 設計判断 + ADR-0049 起票 | PMD mask 構造 (= partmask/slotmask/neiromask/silence_fmpart) literal + 現 PMDNEO mask 経路 literal + 4 chip keyoff literal + 5 段 sub-sprint + verify gate ADR 化、 driver/runtime/compiler/vendor/vromtool.py touch なし、 doc-only | なし |
| **β** | 即 mute path 実装 = `nmi_cmd_mask_part` 拡張で mask set 時に該 part 発音中 ch を chip 別に即 keyoff + chip-neutral safe-state | mask set 時 chip 別 keyoff register write 発生 + register trace primary gate 期待値一致 + 既存 next-keyon suppress 経路 byte-identical 維持 | 最小限 (= `nmi_cmd_mask_part` 拡張 + 即 mute path 並設、 既存 keyoff routine は本体直接 call) |
| **γ** | unmute path 実装 = `nmi_cmd_mask_part` に unmask 経路追加 (= NMI command byte で mask on/off 区別) + `PART_OFF_MASK` clear → next dispatch restore | unmask command で `PART_OFF_MASK = 0` + unmute 後の next note dispatch から register write 復活 (= mid-note 即 re-sound なし) + register trace primary gate 期待値一致 | 最小限 (= `nmi_cmd_mask_part` unmask 経路追加) |
| **δ** | register trace verify gate 確立 = mute fixture + verify script + 6 gate (= 即 keyoff / safe-state / next dispatch restore / 既存 suppress 経路 byte-identical / 非対象 part 無影響 / baseline byte-identical regression) | mute fixture register trace 期待値一致 + 6 gate 全 PASS + verify script 追加 | verify script のみ (= driver touch なし) |
| **ε** | completion + ADR-0049 Draft → Accepted 判断 | 全 sub α/β/γ/δ verify gate PASS + 規律遵守確認 + Accepted 移行判断 (= user 判断 gate 経由) | なし |

各 sub-sprint = 1 PR (= ADR-0041 §決定 4-2 sprint = PR 1 対 1 規律)。 計 5 PR。 全 PR で軸 G / 軸 C / rhythm routine 完全不可触 + baseline byte-identical 維持。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 運用 3 手順)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 軸 G を完成扱いしない
- ADR-0043 軸 C + ADR-0026〜0031 rhythm routine 完全不可触 (= 並設 only or 本体直接 call only、 既存 routine modify なし)
- ADR-0044 Accepted + F-2-A defer 維持
- vendor wav 3 件 untracked retain (= commit 混入禁止)、 vromtool.py 不変
- 「軸 B 完成」 表現禁止 (= 「ADR-0049 α 完了 = mute semantics 設計起票」 表記、 軸 B 実装完了ではない)

### 決定 2: mute semantics = 案 1 (= 既存 1-bit mask 拡張 + 即 mute path + unmute next dispatch restore)

38th session 6 sprint 比較で user GO 取得した **案 1** を採用する。

- **既存 `PART_OFF_MASK` 1-bit boolean を維持** = part workarea offset 30、 0=audible / 1=mask silent
- **即 mute path を追加** = mask set 時に該 part の発音中 ch を chip 別に即 keyoff (= 決定 5 の 4 chip keyoff literal 経路) + chip-neutral safe-state
- **unmask 経路を追加** = `nmi_cmd_mask_part` に NMI command byte で mask on/off を区別する分岐を追加、 unmask 時 `PART_OFF_MASK = 0` → next note dispatch から復帰 (= next dispatch restore、 mid-note 中の即 re-sound は対象外)
- **案 2 (= PMD V4.8s 3-mask 完全互換 upgrade) は reject** = 決定 3 で scope-out literal 化

### 決定 3: PMD V4.8s 3-mask 完全互換は scope-out (= user 条件「いきなり広げない」)

PMD V4.8s / PMDDotNET の mask 機構は `partmask` (= 8-bit bit field) + `slotmask` (= FM SLOT MASK 0xf0) + `neiromask` (= FM Neiro MASK 0xff) の 3 mask 構造 (= Annex A literal)。 本 sprint 5 では **この 3-mask 完全互換へは広げない**。

- 採用: `partmask` 相当の 1-bit `PART_OFF_MASK` 拡張のみ (= 案 1)
- scope-out: `slotmask` (= operator slot 単位 mask) + `neiromask` (= 音色再設定 mask) の PMDNEO 実装
- 理由: slot mask / neiro mask は operator 単位の細粒度制御で、 軸 B Phase 2 driver フルスクラッチ (= FM/SSG driver 全面再設計) で operator 構造を再設計する局面で再評価する方が自然。 sprint 5 は user 要件「任意 ch / 任意 part の mute」 を満たす最小実装に純化する
- PMD 互換調査結果は本 ADR-0049 Annex A に literal 記録する (= user 条件「ADR に残した上で案 1 の狭い実装」)

### 決定 4: 即 mute と next-keyon suppress は別 layer (= 混同しない)

本 sprint 5 では次の 2 つを **別 layer の別概念** として扱い、 ADR / 実装 / verify gate で混同しない (= user 条件 4)。

| layer | 概念 | 現 PMDNEO 状態 | sprint 5 |
|---|---|---|---|
| **next-keyon suppress** | mask 中は次の note keyon を抑止する (= `pmdneo_part_main_note_dispatch` L1990 が `PART_OFF_MASK` 非 0 で `ret`) | 実装済 | **不可触保持** (= byte-identical 維持)、 verify gate 4 で確認 |
| **即 mute (= 即 keyoff)** | mask set 時点で発音中の ch を即 keyoff する | 未実装 | **新規追加** (= β で実装、 決定 5 の 4 chip keyoff literal 経路) |

即 mute は「今鳴っている音を止める」、 next-keyon suppress は「次の音を出さない」。 user 要件「任意 ch / 任意 part の mute」 は両方を含意する。 sprint 5 は即 mute を新規追加し、 next-keyon suppress は既存実装を不可触保持する。

### 決定 5: 4 chip keyoff = 既存 routine 本体直接 call (= ADPCM-A は `adpcma_keyoff` 本体、 hook 配線しない)

即 mute path (= β 実装) の chip 別 keyoff は、 既存実装済 routine を **本体直接 call** する。 4 chip の keyoff register write は実 source verified literal (= Annex C)。

| chip | call 先 routine | register write literal |
|---|---|---|
| FM | `fm_keyoff` (= L973) | reg `0x28` ← `fm_keyoff_values[ch]` (= ch index、 slot bit 全 0 = keyoff) |
| SSG | `ssg_keyoff` (= L904) | reg `0x08+ch` (= 0x08/0x09/0x0A) ← `0x00` (= volume 0) |
| ADPCM-A | `adpcma_keyoff` 本体 (= L3163) | reg `0x00` ← `0x80 \| adpcma_ch_bit_table[ch]` (= dump bit 7 + ch bit) |
| ADPCM-B | `adpcmb_keyoff` (= L2876) | reg `0x10` ← `0x01` → reg `0x10` ← `0x00` (= 2 write 連続) |

**ADPCM-A keyoff direct-call 設計判断** (= Annex C literal): driver には `adpcma_keyoff` (= L3163、 実装本体) と `adpcma_keyoff_hook` (= L2764、 `ret` のみの noop stub) の 2 routine が同名 prefix で共存する。 即 mute path は **`adpcma_keyoff` 本体を直接 call** する (= hook を配線しない)。 理由: `adpcma_keyoff_hook` は ADR-0016 step 系の hook framework 上の未配線 stub であり、 hook 配線は別軸の作業。 sprint 5 は scope 最小化のため本体直接 call で済ませる (= hook framework 改修まで広げない)。

### 決定 6: scope-in / scope-out / non-goal

#### scope-in (= sprint 5 で扱う)

- 任意 ch / 任意 part の **即 mute** (= mask set 時に該 part 発音中 ch を chip 別に即 keyoff)
- 任意 ch / 任意 part の **unmute** (= mask 解除 + next dispatch restore)
- chip-neutral safe-state (= FM/SSG/ADPCM-A/ADPCM-B 各 chip の safe-state register を chip 別に handle)
- 案 1 = 既存 `PART_OFF_MASK` 1-bit boolean 拡張 (= 即 mute path 追加、 unmask 経路追加)
- PMD V4.8s / PMDDotNET mask 構造 (= partmask/slotmask/neiromask/silence_fmpart) の調査結果を本 ADR-0049 Annex A に literal 記録

#### scope-out (= 別 ADR / 別軸 / future sprint)

- PMD V4.8s 3-mask 完全互換 (= `slotmask` + `neiromask` の PMDNEO 実装) = 決定 3 literal、 軸 B Phase 2 driver フルスクラッチ時に再評価
- MML mask command 経路 (= MML bytecode 0xC0 → `fm/ssg/rhythm_mml_part_mask` handler、 PMD V4.8s 由来) = 本 sprint 5 は NMI command 経路 (= `nmi_cmd_mask_part`) のみ、 MML cmd 経路は軸 F / 後続 sprint
- slot mask / neiro mask の MML cmd (= PMD_Z80.inc `ssg_mml_part_mask` stub L2096 の現役化) = legacy reference のみ
- FM3Extend X/Y/Z part の個別 mute = F-2-B 譲渡軸 (= 実装 sprint 3 = δ-3、 ADR-0044 §F-2-B)
- mid-note 中の即 re-sound (= unmute 時) = next dispatch restore のみ、 mid-note re-sound は対象外
- audio gate (= 越川氏 audition) = mute semantics は register trace primary gate で verify、 audio gate は本 sprint 5 では要さない (= user 明示「audio gate ではなく driver behavior verify」)

#### non-goal (= 軸 B sprint 5 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 routine の modify (= 完全不可触、 並設 only or 本体直接 call only)
- fade-out semantics (= 実装 sprint 6、 別 ADR)
- FM/SSG driver フルスクラッチ本体 (= 実装 sprint 1 = δ-1 以降)

### 決定 7: verify gate (= register trace primary gate、 audio gate 不要)

mute semantics は **register trace primary gate** で verify する (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)。 δ sub-sprint で次の 6 gate を確立する。

| # | gate | 期待 |
|---|---|---|
| 1 | mask set 時 該 ch 即 keyoff (= chip 別) | FM = reg 0x28 ← fm_keyoff_values[ch] / SSG = reg 0x08+ch ← 0x00 / ADPCM-A = reg 0x00 ← 0x80\|adpcma_ch_bit_table[ch] / ADPCM-B = reg 0x10 ← 0x01 → 0x00 |
| 2 | mask set 中 chip-neutral safe-state | 各 chip の safe-state register への write or 抑制 (= FM TL / SSG volume / ADPCM-A vol reg / ADPCM-B level 等を chip 別 handle、 詳細は β 実装で確定) |
| 3 | mask 解除時 next dispatch restore | unmute 後の最初の note dispatch から register write 復活 (= mid-note 即 re-sound なし) |
| 4 | 既存 next-keyon suppress 経路 byte-identical | 既存 `PART_OFF_MASK` dispatch 抑止経路 (= L1990 `pmdneo_part_main_note_dispatch`) の register trace 不変 |
| 5 | 非対象 part 無影響 | mask 設定 ch 以外の part の (a) register write 完全不変 + (b) `PART_OFF_MASK` bit も不変 |
| 6 | baseline byte-identical regression | step5/step6/step11/step12 fixture 全 regression (= mute 未使用 path の baseline 保護) |

audio gate は本 sprint 5 では要さない。 mute semantics は driver behavior であり、 register trace で keyoff / safe-state / restore / 非対象不変が確認できれば verify は完結する。

### 決定 8: doc-only filing 規律 (= 本 ADR-0049 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0049 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0049 (= 新規) + `docs/parallel-axes-dashboard.md` (= 軸 B 行 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data 完全不変
- vendor wav 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触
- ADR-0044 Accepted + F-2-A defer 維持、 ADR-0043 軸 C 完全不可触

### 決定 9: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

本 sprint 5 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化を継承する。 主軸の user 確認質問 (= driver / 実装 / 配置 / 即時 GO 判定 / ADR 大型更新) は user 確認の前に Codex layer 2 (= session `019e3425-3327-74e1-95bc-461cc5d0af66`) 投入を default 化、 approve なら主軸自律進行、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終確認 (= PR merge / Accepted 移行判断) のみ。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ground truth 調査 + ADR 起票) | **完了** (= 38th session、 PR #57 MERGED 4515de5) | PR #57 | 6 sprint 比較 round 1-3 + kickoff 計画 round 1-2 + ADR-0049 起票 round 1-2 = 計 7 round chain approve |
| β (= 即 mute path 実装) | 未着手 | - | - |
| γ (= unmute path 実装) | 未着手 | - | - |
| δ (= register trace verify gate) | 未着手 | - | - |
| ε (= completion + Accepted 判断) | 未着手 | - | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: PMDNEO の音楽 driver に「指定したパートの音を即座に止める / 再開する」 機能を追加する設計を文書として固定する。

**前提**: 現状の PMDNEO は「次の音符を鳴らさない」 機能 (= next-keyon suppress) しかなく、 mask を掛けた瞬間に鳴っている音は止まらない。 PMD V4.8s / PMDDotNET の本家 driver は mask を掛けた瞬間に音を即座に消す (= silence_fmpart 等)。 この差を埋める。

**やったこと**: PMD V4.8s 公式 source (= PMD.ASM) と PMDDotNET 移植版 (= PMD.cs) の mask 構造 (= partmask / slotmask / neiromask) を調査し、 現 PMDNEO の mask 経路 (= PART_OFF_MASK / nmi_cmd_mask_part) と比較した。 4 chip (= FM/SSG/ADPCM-A/ADPCM-B) の keyoff register write を実 source で確認した。 これらを ADR-0049 として起票し、 5 段の sub-sprint (= α/β/γ/δ/ε) と verify gate を定義した。

**結果**: mute semantics の設計が文書として固定された。 案 1 (= 既存の 1-bit mask を拡張 + 即 mute 経路追加 + unmute 経路追加) を採用し、 PMD 本家の 3-mask 完全互換へは広げない方針を literal 化した。

**解釈**: これは設計の起票であり、 mute の実装は完了していない。 後続の β/γ/δ で driver を改修し、 ε で完了判断する。

**次**: β sub-sprint (= 即 mute path 実装) 着手。

## Annex A: PMD V4.8s / PMDDotNET mask 構造 ground truth

PMD V4.8s 公式 source `vendor/pmd48s/source/pmd48s/PMD.ASM` (= Shift-JIS、 M.Kajihara 作) と PMDDotNET 移植版 `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` (= PMD.ASM の C# 移植、 構造完全同一) の mask 機構を全数調査した。 行番号は PMD.ASM = iconv UTF-8 変換後、 PMD.cs = そのまま。

### A-1: 3 mask 構造 概観

PMD V4.8s の part mask 機構は 3 つの mask field で構成される。

| mask field | 用途 | init 値 | 粒度 |
|---|---|---|---|
| `partmask` | part 全体の mask 状態 (= 8-bit bit field、 複数 mask 要因を bit で持つ) | 0 | part 単位 |
| `slotmask` | FM operator slot mask (= 上位 4 bit = slot 4/3/2/1) | 0xf0 (= 全 slot) | operator slot 単位 |
| `neiromask` | FM 音色再設定 mask (= どの slot/register を TL 再設定するか) | 0xff | operator/register 単位 |

全体判定軸: 「`partmask != 0` なら part の音を出さない、 `partmask == 0` なら復活させる」 (= PMD.ASM L1057/L1281/L1528/L1617/L2264 `cmp partmask[di],0` literal)。

### A-2: partmask bit field 構成

`partmask` は 8-bit bit field で、 複数の mask 要因をそれぞれの bit で持つ。

| bit | 値 | 意味 | source literal |
|---|---|---|---|
| bit 0 | 0x01 | SSG マスク中 | PMD.ASM L1509 `test partmask[di],1 ;bit0(SSGマスク中？)をcheck` |
| bit 1 | 0x02 | 効果音中 (= FM/SSG 効果音) | PMD.ASM L1276 `test partmask[di],2 ;bit1(FM効果音中？)をcheck` / L1511 `bit1(SSG効果音中？)` |
| bit 2 | 0x04 | Mask(bit2) (= NEC YM2608 PCM part mask) | PMD.ASM L471 `or partmask[bx],4 ;Mask(bit2)` / PMD.cs L431 |
| bit 4 | 0x10 | Mask(bit4) | PMD.ASM L463 `or partmask[bx],10h ;Mask(bit4)` / PMD.cs L421 |
| bit 5 | 0x20 | s0 時 FM マスク (= slotmask 全 0 = 全 slot off) | PMD.ASM L570 `or partmask[di],20h ;s0の時FMマスク` / PMD.cs L545 |
| bit 6 | 0x40 | MML mask command 由来 (= bytecode 0xC0 → `fm/ssg/rhythm_mml_part_mask` handler) | PMD.ASM L2363 `or partmask[di],40h` (= fm_mml_part_mask) / PMD.cs L3210 |

`partmask` の保存/復元は `mov dh,partmask[bx]` / `mov partmask[bx],dh ;partmaskのみ保存` (= PMD.ASM L638/L646、 PMD.cs L630/L641)。 効果音終了時は `and partmask[di],0fdh ;bit1をclear` で bit 1 を落とし、 `partmask == 0` なら復活 (= PMD.ASM L1280-1281/L1525-1528)。

### A-3: slotmask / neiromask 構成

- `slotmask` (= FM SLOT MASK) = init 0xf0 (= PMD.ASM L561/L566、 PMD.cs L535/L541)。 上位 4 bit が FM operator slot 4/3/2/1 に対応 (= `slotmask 43210000` = PMD.cs L3088 comment)。 OPN ch 3/4/5 は neiro/slotmask を 0 のまま保持する場合がある (= PMD.ASM L565 `OPN 3,4,5 はneiro/slotmaskは0のまま`)
- `neiromask` (= FM Neiro MASK) = init 0xff (= PMD.ASM L562/L567、 PMD.cs L536/L542)。 音色再設定時にどの slot/register を書くかの mask。 `neiromask == 0` なら音色再設定 skip (= PMD.cs L3299/L4697 `if (neiromask == 0)`)
- s0 (= slot 0 指定) 時は `partmask |= 0x20` で FM マスク (= PMD.ASM L570)

本 sprint 5 では slotmask / neiromask は **scope-out** (= 決定 3)。 operator slot 単位の細粒度制御であり、 軸 B Phase 2 driver フルスクラッチ時に再評価する。

### A-4: silence_fmpart (= FM part 即 silence、 PMD.cs L7634-7669)

mask-on 時に FM part を完璧に消す routine。

```
private void silence_fmpart()
{
    r.al = pw.partWk[r.di].neiromask;     // neiromask を見る
    if (r.al == 0) goto sfm_exit;          // neiromask == 0 なら何もしない
    ...                                    // neiromask の各 bit に対し:
    r.dl = 127;//; TL = 127 / RR=15        //   TL=127 (= 最小音量) / RR=15 (= 最速 release)
    ...                                    //   opnset() で reg 0x40+ (TL/RR) に書く
    kof1();//; KEY OFF                     // kof1() で keyoff
}
```

= FM part を「TL を 127 (= 最小音量) まで減衰 + RR を 15 (= 最速 release) + keyoff」 で完璧に消す。 `kof1` (= PMD.cs L7317-) は reg `0x28` に `partb-1` (= ch) で keyoff。

### A-5: psgmsk (= SSG part mask data 生成、 PMD.cs L7280-7298)

SSG part mask 時の mixer mask data を生成する routine。 part 番号から SSG mixer (= reg 0x07) の tone/noise bit を算出し、 `get07` で reg 0x07 に書く (= 該 SSG ch を mixer level で off)。

### A-6: MML mask command (= fm/ssg/rhythm_mml_part_mask、 PMD.cs L3193-3289)

PMD V4.8s の MML mask command (= MML bytecode 0xC0 → `fm/ssg/rhythm_mml_part_mask` handler) による part mask/解除。 partmask bit 6 (= 0x40) を使う。 = この MML 経路は driver 外部 API command `PART_MASK AH=1Eh` (= PMD.ASM L102、 PC-98 側から AH register に 1Eh を入れて呼ぶ external command interface) とは **別ルート**。 AH=1Eh は外部 command interface、 MML mask は MML データ中の bytecode 0xC0 経路で、 両者を混同しない。

| routine | mask-on (= arg != 0) | mask-off (= arg == 0) |
|---|---|---|
| `fm_mml_part_mask` (L3193) | `partmask \|= 0x40` → partmask が 0x40 のみ (= 他要因 0) なら `silence_fmpart()` (= 即 silence) | `partmask &= 0xbf` (= bit 6 clear) → partmask == 0 なら `neiro_reset()` (= 音色再設定で復活) |
| `ssg_mml_part_mask` (L3234) | `partmask \|= 0x40` → partmask が 0x40 のみなら `psgmsk()+opnset44()` (= PSG keyoff) | `partmask &= 0xbf` → partmask == 0 なら復活 |
| `rhythm_mml_part_mask` (L3274) | `partmask \|= 0x40` (= flag のみ、 silence 処理なし) | `partmask &= 0xbf` (= flag のみ) |

**finding**: rhythm part は mask flag を立てるのみで即 silence 処理を持たない (= rhythm 音は短い one-shot で自然減衰するため)。 FM/SSG は即 silence を持つ。 本 sprint 5 は NMI command 経路のみ扱い、 MML mask command 経路は scope-out (= 決定 6) だが、 MML command 流儀の「mask-on で即 silence、 mask-off で復活」 の構造は即 mute path / unmute path の設計参照とする。

### A-7: PMD V4.8s ground truth から導出される sprint 5 設計 finding

1. PMD V4.8s/PMDDotNET は mask-on 時に `silence_fmpart` (= FM) / `psgmsk` (= SSG) で **即 silence** する。 現 PMDNEO の next-keyon suppress only はこの即 silence を欠く
2. PMD V4.8s の即 silence は「TL 最大減衰 + RR 最速 + keyoff」 (= FM) / 「mixer off」 (= SSG) の chip 別処理。 PMDNEO の即 mute path も chip 別 safe-state を持つべき (= 決定 7 gate 2)
3. PMD V4.8s は `partmask != 0` を全体判定軸とする bit field 方式。 PMDNEO 案 1 は 1-bit boolean で簡略化 (= 決定 2/3)。 PMD 互換の bit field 方式は scope-out だが、 「mask != 0 で音を出さない」 の判定軸は共通
4. mask-off (= unmute) は PMD V4.8s では `neiro_reset()` で音色再設定して part 復活。 PMDNEO 案 1 は next dispatch restore (= mid-note 即 re-sound なし) で簡略化

## Annex B: 現 PMDNEO mask 経路 ground truth

現 PMDNEO active driver `src/driver/standalone_test.s` の mask 機構を全数調査した。

### B-1: PART_OFF_MASK (= part workarea offset 30)

```
L83:  .equ    PART_OFF_MASK,    30   ;; per-part mask flag (0=audible, 1=mask silent)
```

part workarea (= `part_workarea`、 1 part = 64 byte) の offset 30 に配置された **1-bit boolean** flag。 PMD V4.8s の `partmask` (= 8-bit bit field) を 1-bit に簡略化したもの。

### B-2: nmi_cmd_mask_part (= NMI command 24-37 = mask set、 L710-728)

```
nmi_cmd_mask_part:
        sub     #24                    ; A = cmd byte (24..37) -> part_idx (0..13)
        ld      l, a
        ld      h, #0
        add     hl, hl  (×6)           ; HL = part_idx * 64
        ld      de, #part_workarea
        add     hl, de                 ; HL = &part_workarea[part_idx]
        push    hl
        pop     ix
        ld      a, #1
        ld      PART_OFF_MASK(ix), a   ; PART_OFF_MASK = 1 を set のみ
        jp      nmi_done
```

NMI command byte 24-37 (= 14 part 分) を受け、 part_idx を算出し `PART_OFF_MASK(ix) = 1` を set **のみ**。 即 keyoff 処理なし。 unmask (= PART_OFF_MASK = 0) 経路なし。 NMI command byte は mask on のみで mask off との区別を持たない。

### B-3: pmdneo_part_main_note_dispatch (= next-keyon suppress、 L1990)

```
pmdneo_part_main_note_dispatch:
        ld      a, PART_OFF_MASK(ix)
        or      a
        ret     nz                     ; PART_OFF_MASK != 0 なら note keyon を抑止
        ...                            ; (= 通常の note keyon 処理)
```

note dispatch 前に `PART_OFF_MASK(ix)` を参照し、 非 0 なら `ret` で note keyon を抑止する。 = **next-keyon suppress** (= mask 中は次の note を鳴らさない)。 既発音中の ch を keyoff する処理は持たない。

### B-4: PMD_Z80.inc ssg_mml_part_mask (= stub、 L2096)

```
ssg_mml_part_mask:
        call    pmdneo_part_fetch_byte
        ret
```

PMD_Z80.inc (= PMD V4.8s 由来 legacy core) の `ssg_mml_part_mask` は MML cmd byte を 1 つ fetch して `ret` するのみの **stub** (= 未実装)。 SSG mask MML command は PMD_Z80.inc 内では未配線。 本 sprint 5 では legacy reference のみ (= scope-out)。

### B-5: 現 PMDNEO mask 経路の不足箇所 (= 決定 1 §背景 literal)

| # | 不足箇所 | sprint 5 対応 |
|---|---|---|
| 1 | 即 keyoff が存在しない (= mask set 時に発音中 ch を keyoff しない) | β で即 mute path 追加 |
| 2 | unmask 経路が存在しない (= PART_OFF_MASK = 0 に戻す経路なし) | γ で unmask 経路追加 |
| 3 | chip 別 safe-state 処理が存在しない | β で chip-neutral safe-state 追加 |

## Annex C: ADPCM-A keyoff direct-call 設計判断 + 4 chip keyoff literal

### C-1: 4 chip keyoff routine 実 source verified literal

即 mute path (= β 実装) で本体直接 call する 4 chip keyoff routine を実 source で verify した。

| chip | routine | source 行 | register write literal |
|---|---|---|---|
| FM | `fm_keyoff` | L973-984 + `fm_keyoff_values` L1255-1256 | reg `0x28` ← `fm_keyoff_values[ch]` (= `0x00/0x01/0x02/0x04/0x05/0x06`、 slot bit 全 0) |
| SSG | `ssg_keyoff` | L904-912 | reg `0x08+ch` (= 0x08/0x09/0x0A) ← `0x00` (= volume 0) |
| ADPCM-A | `adpcma_keyoff` (= 本体) | L3163-3174 + `adpcma_ch_bit_table` L3176-3177 | reg `0x00` ← `0x80 \| adpcma_ch_bit_table[ch]` (= dump bit 7 + ch bit、 ch_bit_table = `0x01/0x02/0x04/0x08/0x10/0x20`) |
| ADPCM-B | `adpcmb_keyoff` | L2876-2883 | reg `0x10` ← `0x01` (= reset) → reg `0x10` ← `0x00` (= clear、 2 write 連続) |

### C-2: ADPCM-A keyoff = `adpcma_keyoff` 本体 vs `adpcma_keyoff_hook` noop stub

driver には ADPCM-A keyoff 関連 routine が 2 つ同名 prefix で共存する。

| routine | source 行 | 実装 |
|---|---|---|
| `adpcma_keyoff` (= 実装本体) | L3163-3174 | reg `0x00` ← `0x80 \| ch_bit` (= 上記 C-1 literal、 実装済) |
| `adpcma_keyoff_hook` | L2764-2765 | `ret` のみ (= noop stub、 ADR-0016 step 系 hook framework 上で未配線) |

**設計判断**: sprint 5 即 mute path の ADPCM-A keyoff は **`adpcma_keyoff` 本体を直接 call** する (= 決定 5)。

- 採用根拠 1: `adpcma_keyoff` 本体は ADPCM-A keyoff register write を実装済 (= C-1 verify)。 即 mute path から直接 call すれば追加実装不要
- 採用根拠 2: `adpcma_keyoff_hook` は ADR-0016 step 系の hook framework 上の noop stub。 hook を配線する作業は hook framework 改修であり、 sprint 5 mute semantics の scope 外
- reject 案: hook を配線して hook 経由で call する案は、 hook framework (= ADR-0016 step 系) への touch を伴い scope 拡大 + regression surface 増。 sprint 5 は scope 最小化のため reject

### C-3: β 実装時の caller 注意点 (= β sub-sprint へ申し送り)

- `fm_keyoff` / `ssg_keyoff` / `adpcma_keyoff` は引数 `B = ch index` を取る。 即 mute path は part_idx → ch index の対応付けが必要 (= β 実装で part workarea の ch 情報を参照)
- `adpcmb_keyoff` は引数なし (= ADPCM-B 1ch 固定)
- 各 keyoff routine は register bank (= port A / port B) が異なる (= FM/SSG = port A、 ADPCM-A/B = port B)。 既存 routine 本体が `ym2610_write_port_a` / `ym2610_write_port_b` を内部で呼ぶため、 caller は意識不要
- 該 part が FM / SSG / ADPCM-A / ADPCM-B のどの chip に属するかの判定は β 実装で part 種別情報を参照 (= part_idx → chip 種別の対応付け、 β 設計事項)

## 改訂履歴

| 日付 | 状態 | 内容 |
|---|---|---|
| 2026-05-20 | Draft 起票 (= 38th session 軸 B 実装 sprint 5 α) | ADR-0045 §J-4-5 literal 後続実装 ADR、 mute semantics = 案 1 (= 既存 1-bit mask 拡張 + 即 mute path + unmute next dispatch restore)、 5 段 α/β/γ/δ/ε 構成、 決定 1-9 (= sub-sprint 構成 / 案 1 採用 / 3-mask 互換 scope-out / 即 mute と next-keyon suppress 別 layer / 4 chip keyoff 本体直接 call / scope / verify gate 6 件 / doc-only filing / Codex rescue 化継承)、 Annex A (= PMD V4.8s/PMDDotNET mask 構造 = partmask/slotmask/neiromask/silence_fmpart/psgmsk/MML mask command) + Annex B (= 現 PMDNEO mask 経路 = PART_OFF_MASK/nmi_cmd_mask_part/next-keyon suppress/不足箇所) + Annex C (= ADPCM-A keyoff direct-call 設計判断 + 4 chip keyoff literal)、 doc-only filing で driver/runtime/compiler/vendor/vromtool.py/verify script/verify fixture data 完全不変、 vendor wav 3 件 untracked retain、 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 ADR-0044 Accepted + F-2-A defer 維持、 ADR-0043 軸 C 完全不可触、 Codex layer 2 計 5 round chain approve (= 6 sprint 比較 round 1-3 + kickoff 計画 round 1-2) |
