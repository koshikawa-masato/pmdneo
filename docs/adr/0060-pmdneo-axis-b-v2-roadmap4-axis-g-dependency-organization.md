# ADR-0060: PMDNEO 軸 B v2 driver production-ready roadmap ④ = 軸 G dynamic supply 依存整理

- 状態: **Accepted** (= 2026-05-23 39th session、 軸 B production-ready roadmap ④ 軸 G dynamic supply 依存整理 = doc-only design ADR。 単一 doc-only 起票 (= 1 PR、 sub-sprint chain なし、 ADR-0056 同形式、 Codex layer 2 plan review approve + 案 B 推奨 採用)。 ADR-0056 §決定 4 roadmap ④ literal 後続実装 ADR。 ADR-0059 Accepted (= roadmap ③ 完了) 後の次フェーズ。 **ADR-0060 Accepted = roadmap ④「軸 G dynamic supply 依存整理」 完了** ≠ ADR-0048 ζ dynamic supply 本体実装完了 ≠ production-ready 全体達成。 「軸 B 完成」 表現禁止 継続、 軸 G ADR-0048 Draft + ε partial state 完全不可触維持)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0056** (= 軸 B v2 driver production-ready 化 選定 ADR、 Accepted、 §決定 4 roadmap ④ = 軸 G dynamic supply 依存整理。 本 ADR-0060 が roadmap ④ の design ADR)
  - **ADR-0048** (= 軸 G ADPCM 動的 sample 供給 = `.PPC` parser + driver runtime selection + asset converter 接続、 **Draft + α/β/γ/γ revision/δ 完了 + ε partial complete + ζ 未着手**。 ε partial = 越川氏 audition「PPC audible proof approve / integration 同居 reject」。 **本 ADR-0060 で完全不可触保護** = ADR-0048 本文 + ε partial state (= ppc_scratch 0xFD33-0xFD36 / audition_frame_counter 0xFD37-0xFD38) + Draft 状態 + ζ 未着手 state は不変)
  - **ADR-0058** (= roadmap ② song parse + per-part dispatch loop + IRQ tick 連携、 Accepted。 **δ-5 で TIMER-B IRQ rate ~492 Hz literal 実測** = ADR-0048 ε partial の TIMER-B「6 秒で 2 回」 finding 完全 stale 化、 本 ADR-0060 の核心 finding 1 件)
  - **ADR-0059** (= roadmap ③ ADPCM-B/rhythm 実 dispatch、 Accepted。 §決定 3 ADPCM-B IX shim (= 0xFD41-0xFD60) + §決定 8 sup-sample-table-id-bit7-clear gate (= `driver_pne_sample_table_id` bit7=0 default 維持で軸 G 経路を侵入させない)、 本 ADR-0060 で接続経路 design の base)
  - **ADR-0043** (= 軸 C ADPCM-B 1ch runtime-managed architecture、 Accepted、 本 ADR で完全不可触 = `adpcmb_keyon` body + `pmdneo_select_adpcmb_sample_pointer` + ADPCMB_DRV.inc 全部)
  - **ADR-0057** (= roadmap ① FM/SSG 実音、 Accepted、 本 ADR で不可触保護)
  - **ADR-0049〜0055** (= 軸 B 実装 sprint chain 7 sprint = mute / fade-out / SSG tone-enable + v2 entry / SRAM placement / F-2-B / 軸 C/G/rhythm 接続点、 全 Accepted、 本 ADR で routine body 不可触保護)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 「軸 B 完成」 表現禁止、 「軸 G dynamic supply 実装完了」 表現禁止、 ADR-0060 Accepted = roadmap ④ 依存整理完了のみ)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 39th session 完全自走 model + 後半 再拡張 = 判断も Codex 自律 / non-stop、 user 完走後確認)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 但し本 ADR は doc-only filing のため driver behavior verify 不要)
  - `feedback_metric_pass_is_not_aesthetic_pass.md` (= metric pass ≠ aesthetic pass、 production-ready 最終 gate = 越川氏 audition、 ADR-0048 ε partial の audition reject 経験継承)

## 背景 (= why now)

### roadmap ④ = 軸 G dynamic supply 依存整理 = ADPCM-B 実 dispatch 後の依存整理 phase

ADR-0056 §決定 4 = production-ready 化 roadmap ① FM/SSG 実音 → ② song parse + v2 per-part dispatch loop + IRQ tick 連携 → ③ ADPCM-B/rhythm 実 dispatch → **④ 軸 G dynamic supply 依存整理** = ADPCM-B 実 dispatch の土台ができてから ADR-0048 軸 G 依存を扱う。 ADR-0059 Accepted (= roadmap ③ 完了) で v2 driver が FM/SSG/ADPCM-B/rhythm 4 chip 系統で実 dispatch する段階に到達した。 残 = 軸 G dynamic supply 依存整理 + 越川氏 audition + production-ready 判定。

本 ADR-0060 = roadmap ④ の design ADR。 **「依存整理」 = ADR-0048 dynamic supply 本体実装ではなく、 v2 driver と軸 G の依存関係 + 接続経路 + ADR-0048 既存 finding stale 化 update を整理する doc-only design 段階** (= ADR-0048 dynamic supply 本体実装は ADR-0048 ζ scope、 user 判断 gate)。

### 核心 finding = ADR-0048 ε partial の TIMER-B IRQ rate「6 秒で 2 回」 は ADR-0058 δ-5 で完全 stale 化

ADR-0048 ε partial (= 36th session、 PR #49) で 5 件切り分け実施。 切り分け 5 = TIMER-B IRQ rate「6 秒で 2 回 (= 0xF816 への write が 6 秒で 3 件のみ)」 finding が **ε scope 超え** と判定され、 ADR-0048 ζ 候補 案 X (= TIMER-B IRQ rate 改修) の前提となった。

**しかし ADR-0058 δ-5 (= 39th session、 PR #99) で「TIMER-B IRQ rate ~492 Hz literal 実測」 (= 5 秒間で 2461 件 / 1 秒あたり ~492 Hz = 1 ms 想定通り) を確定済**。 = ADR-0048 ε partial の TIMER-B finding は **完全に stale 化**。

これは roadmap ④ の核心 = ADR-0048 ζ 候補 案 X (= TIMER-B 改修) が **不要可能性** + 軸 G integration 同居 reject の真の root cause は別要因 (= 同居 fixture 設計 / 単発 keyon 設計 / トリガ timing 等) であり、 ADR-0048 ζ 着手時の前提整理が必要。

### 起票方式 = 単一 doc-only 起票 (= ADR-0056 同形式、 Codex layer 2 plan review approve 経由)

ADR-0060 は **doc-only design ADR** であり driver / runtime / verify script 実装を伴わない (= scope-in 全 4 件すべて doc-only)。 Codex layer 2 plan review で「案 B 単一 doc-only 起票」 を recommend (= sub-sprint chain 4 分割は過剰、 ADR-0056 と同形式の 1 PR で起票 + Accepted が適切)。 本 ADR-0060 は単一 doc-only 起票で完結。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0060 を doc-only filing として起票し、 軸 G dynamic supply 依存整理を文書固定する。

## 決定

### 決定 1: ADR-0048 ε partial TIMER-B finding stale 化 literal (= ADR-0058 δ-5 で覆された)

ADR-0048 ε partial (= 36th session、 切り分け 5) の「TIMER-B IRQ rate 6 秒で 2 回」 finding は **ADR-0058 δ-5 (= 39th session、 PR #99) で完全に stale 化**された。

| ADR-0048 ε partial 当時 finding (= 切り分け 5) | ADR-0058 δ-5 実測 (= roadmap ② 完了時) |
|---|---|
| TIMER-B IRQ rate = 6 秒で 2 回 (= 0xF816 write 3 件 / 6 秒) | TIMER-B IRQ rate = **~492 Hz** (= 0xF816 write 2461 件 / 5 秒 = 1 ms 想定通り) |
| → ε scope 超え + ζ 候補 案 X (= TIMER-B 改修) 前提 | → 古い finding 完全 stale 確定 (= ADR-0058 δ-5 supplemental gate sup-TIMER-B literal で再確認済) |

#### stale 化の意味

- **ADR-0048 ζ 候補 案 X (= TIMER-B IRQ rate 改修) は不要可能性** (= TIMER-B 自体は ~492 Hz で正常動作、 改修不要)
- ADR-0048 ε partial の integration 同居 reject の真の root cause は **別要因** (= 同居 fixture 設計 / 単発 keyon 設計 / トリガ timing 等) であり、 ADR-0048 ζ 着手時に再評価が必要
- ADR-0048 ε partial 当時の切り分け 2/3/4 (= keyon 0 件 / blob 範囲外 / filler 非可聴) は ADR-0048 ε round 2 fix 3 件で解消済、 切り分け 5 のみが stale 化対象

#### ADR-0048 本文不変 (= 履歴改変 risk 回避、 ADR-0058 ε / ADR-0059 ε pattern 同形式)

ADR-0048 本文は ε partial 当時の literal 記録として **完全不変**維持する。 stale 化は本 ADR-0060 §決定 1 内に literal 反映のみ (= ADR-0058 ε rename 注記 / ADR-0059 ε slot base address 訂正注記 と同 pattern)。 履歴改変 risk 回避 + ε partial 当時の判断経緯保存。

ADR-0048 ζ 着手時の前提整理は ADR-0048 ζ sub-sprint 内で行う (= 本 ADR-0060 は ζ 着手前の依存整理段階)。

### 決定 2: v2 driver と軸 G ε partial state の依存関係 literal 整理

ADR-0059 (= roadmap ③) で確立した v2 driver と軸 G の依存関係を literal 整理する (= 概念設計のみ、 具体 code skeleton なし = Codex layer 2 plan review 案 P 採用)。

#### v2 driver 経路 (= 現状、 ADR-0059 Accepted 時点)

```
pmdneo_v2_song_dispatch (= ADR-0058 γ)
  → pmdneo_v2_part_dispatch_note (KIND=2 ADPCM-B 分岐、 ADR-0059 γ)
    → pmdneo_v2_adpcmb_voice_note_song (= ADR-0059 §決定 4 並設)
      → push ix + ld ix, #pmdneo_v2_adpcmb_ix_shim (= 0xFD41-0xFD60、 案 Q)
      → ld PART_OFF_INSTRUMENT(ix), #0 (= default voice index 0、 ADR-0043 経路前提)
      → call adpcmb_keyon (= ADR-0043 entry 本体不可触 call、 L4020)
        → ld a, (driver_pne_sample_table_id) + bit 7,a
        → **bit7=0 (= 現状 ADR-0059 sup-sample-table-id-bit7-clear gate で維持)**
          → call pmdneo_select_adpcmb_sample_pointer (= ADR-0043 経路、 sample literal table)
        → bit7=1 (= roadmap ④ で侵入可能性、 実装は ADR-0048 ζ scope)
          → call pmdneo_select_adpcmb_ppc_pointer (= ADR-0048 軸 G δ partial)
      → pop ix
```

#### roadmap ④ で扱う依存整理 (= 概念設計のみ literal)

1. **bit7=1 経路侵入の design 経路**: v2 wrapper (= `pmdneo_v2_adpcmb_voice_note_song`) から軸 G 経路を呼ぶには `driver_pne_sample_table_id` (= 0xFD32) bit7=1 への切替が必要。 切替方法は以下の候補:
   - **case 1**: v2 wrapper 内で driver_pne_sample_table_id を save / set bit7 / call adpcmb_keyon / restore する save/restore pattern (= 既存 adpcmb_keyon body 完全不可触、 sample table id field を 1 命令 sequence で 一時 modify)
   - **case 2**: v2 専用 wrapper の dispatch_note KIND=4 (= ADPCM-B 軸 G 専用) を新設し、 直接 `pmdneo_select_adpcmb_ppc_pointer` を call (= ADR-0043 経路 bypass)
   - **case 3**: ADR-0048 ζ で MML 経路 (= 案 Y) で対応、 v2 から直接呼ばない

   **本 ADR-0060 では case 1/2/3 のいずれも実装しない** (= 依存整理 doc-only、 実装は ADR-0048 ζ scope)。 case 選定は ADR-0048 ζ 起票時の user 判断 gate。

2. **軸 G ε partial state との非衝突**: ADR-0059 §決定 3 ADPCM-B IX shim (= 0xFD41-0xFD60、 32 byte) と軸 G ε partial state (= ppc_scratch 0xFD33-0xFD36 + audition_frame_counter 0xFD37-0xFD38) は **非衝突** (= SRAM 領域分離済)。 v2 + 軸 G 同居時 SRAM 競合なし。

3. **ADR-0055 stub marker との関係**: `pmdneo_v2_adpcmb_dispatch` (= ADR-0055 stub、 0xFD3C marker) + `pmdneo_v2_rhythm_dispatch` (= 0xFD3D marker) は regression 用に維持。 v2 song dispatch 経路 (= ADR-0059 γ/δ の `pmdneo_v2_adpcmb_voice_note_song` / `pmdneo_v2_rhythm_voice_note_song`) と並存。 軸 G 経路侵入時も ADR-0055 stub marker は不変。

#### 不可触対象 (= roadmap ④ で完全不可触)

- **軸 G ε partial state** (= ppc_scratch 0xFD33-0xFD36 / audition_frame_counter 0xFD37-0xFD38) 完全不変
- **ADR-0048 本文 + Draft 状態 + ζ 未着手 state** 不変 (= 履歴改変 risk 回避)
- **既存 `adpcmb_keyon` body / `pmdneo_select_adpcmb_ppc_pointer` body / `pmdneo_select_adpcmb_sample_pointer` body** 完全不変
- **ADR-0059 §決定 8 sup-sample-table-id-bit7-clear gate** 規律維持 (= roadmap ④ doc-only filing 段階では bit7=0 default 継続、 bit7=1 経路侵入は ADR-0048 ζ で扱う)
- **v2 driver active code 変更なし** (= roadmap ④ は doc-only design、 production build PASS + m1 binary byte-identical 維持 = 通算 sha256 b15883fe...)

### 決定 3: ADR-0048 ζ 着手向け前提整理 = 案 X 不要 / 案 Y/Z 再評価

ADR-0048 ζ 候補 3 案 (= sub-sprint ζ 着手準備 literal、 ADR-0048 L953-1006) の再評価を doc-only literal で整理。 **実装判断は ADR-0048 ζ 起票時の user 判断 gate**、 本 ADR-0060 は前提整理のみ。

| 案 | ADR-0048 当時の主軸推奨評価 | 本 ADR-0060 §決定 3 再評価 |
|---|---|---|
| **案 X** TIMER-B IRQ rate 構造改修 | 評価 = 既存 driver 改修必要 + ε scope 超え | **不要可能性 (= TIMER-B ~492 Hz 実測で正常動作確定、 改修不要)**、 軸 G integration 同居 reject の真の root cause は別要因 |
| **案 Y** MML 拡張で J part に PPC 経路 keyon 命令を追加 | 評価 = 軸 F defer 解除必要、 compile.py + driver 両方改修 | **継続候補** (= MML 経路で song-driven PPC 切替を実現、 軸 F defer 解除は ADR-0044 ζ scope 別軸)、 ADR-0048 ζ 起票時に再評価 |
| **案 Z** init 経路の強制 keyon を timing 調整可能 sequence に拡張 | **主軸推奨 + user 仮判断 = 第一候補** (= 最小リスクで integration audition fixture を作る) | **第一候補維持 + roadmap ② IRQ tick 駆動 (= ADR-0058 δ) との整合性検討必要** (= ADR-0058 δ で IRQ tick 駆動 dispatch を確立済 = init 経路順次発火と並走可能か、 ADR-0048 ζ 起票時に再評価) |

#### 軸 G integration 同居 reject の真の root cause 再評価候補 (= ADR-0048 ζ 着手時の調査軸)

ADR-0048 ε partial の integration 同居 reject 真因は ADR-0058 δ-5 TIMER-B finding stale 化に伴い再評価が必要。 候補:

- **同居 fixture 設計** = ADR-0048 ε partial の同居 fixture は init 経路 1 度 trigger のみ = 真の同居 audition (= 3 経路同居の時系列並走) には不足
- **単発 keyon 設計** = init 経路 1 度 trigger では integration audition 不可、 周期 trigger or MML 経路 trigger が必要
- **トリガ timing 設計** = roadmap ② IRQ tick 駆動 (= ADR-0058 δ) と統合した PPC 経路順次発火が ADR-0048 ζ 案 Z で実現可能性
- **越川氏 audition 期待値再 align** = ε partial「PPC audible proof approve」 は achieved、 「integration 同居 reject」 は再 audition で別 fixture 評価必要

これらは **ADR-0048 ζ 起票時に user 判断 + Codex layer 2 review で再評価** する。 本 ADR-0060 は再評価軸の literal 化のみ。

### 決定 4: ADR-0059 sup-sample-table-id-bit7-clear gate との関係性 + roadmap ④ 後の bit7=1 侵入可能性

ADR-0059 §決定 8 supplemental 5 gate (= sup-sample-table-id-bit7-clear) = `driver_pne_sample_table_id` (= 0xFD32) bit7=1 write 件数 = 0 で「軸 G dynamic supply 経路 = bit7=1 を侵入させない」 を verify gate 化。 = ADR-0059 完了時点で v2 driver は **bit7=0 default 維持 + 軸 G 経路侵入なし**。

#### roadmap ④ 完了後の bit7=1 侵入可能性 (= 実装は ADR-0048 ζ scope)

本 ADR-0060 Accepted で **roadmap ④ 依存整理完了** = 「v2 driver から軸 G 経路を侵入させる経路の設計が literal 化された」 状態。 = ADR-0059 sup-sample-table-id-bit7-clear gate は **roadmap ④ 完了後も維持** (= 実装は ADR-0048 ζ で扱う、 本 ADR-0060 では侵入させない)。

ADR-0048 ζ 起票時 (= user 判断 gate) に case 1/2/3 (= §決定 2 内候補) のいずれを採用するか確定、 実装時に ADR-0059 sup-sample-table-id-bit7-clear gate を以下に変更:

- **bit7=1 write 件数 >= 1 件期待** (= 軸 G 経路侵入を許容、 case 1 採用時)
- もしくは **sup gate 自体を ADR-0048 ζ verify script へ移管** (= roadmap ④ までの bit7=0 default 維持規律を ADR-0048 ζ scope に引き渡し)

本 ADR-0060 では gate 変更も実装も行わない (= 依存整理 doc-only、 実装は ADR-0048 ζ)。

### 決定 5: scope-in / scope-out / non-goal

#### scope-in (= roadmap ④ で扱う、 全 doc-only filing)

- ADR-0048 ε partial TIMER-B finding stale 化 literal (= ADR-0058 δ-5 ~492 Hz 実測で覆された、 §決定 1)
- v2 driver と軸 G ε partial state の依存関係 literal 整理 (= 概念設計のみ、 案 P 採用、 §決定 2)
- ADR-0048 ζ 着手向け前提整理 (= 案 X 不要 / 案 Y/Z 再評価、 §決定 3)
- ADR-0059 sup-sample-table-id-bit7-clear gate との関係性 + roadmap ④ 後の bit7=1 侵入可能性 literal (= §決定 4)

#### scope-out (= 別 ADR / 別軸 / future)

- **ADR-0048 dynamic supply 本体実装** = ADR-0048 ζ scope (= user 判断 gate、 本 ADR-0060 では扱わない)
- **軸 G ε partial state (= 0xFD33-0xFD38) modify** = 完全不可触 (= ADR-0048 Draft + ε partial 状態維持)
- **ADR-0048 本文 modify** = 完全不可触 (= 履歴改変 risk 回避、 ADR-0058 ε / ADR-0059 ε pattern 同形式)
- **ADR-0048 Draft → Accepted 移行** = ADR-0048 ζ 完了 + 真の integration audition approve 後の future (= user 判断 gate)
- **v2 driver active code 変更** = roadmap ④ は doc-only design、 active code 実装は ADR-0048 ζ で扱う
- **越川氏 audition** = production-ready 判定 gate 最終段 (= ADR-0056 §決定 3、 roadmap ④ 完了後の future)
- **production-ready 判定 + cmd 切替** = roadmap ④ 完了後 (= ADR-0056 §決定 3 gate 全通過 + audition)
- **bit7=1 経路侵入実装** = ADR-0048 ζ scope (= case 1/2/3 のいずれを採用するかは ADR-0048 ζ 起票時 user 判断)

#### non-goal (= roadmap ④ として目指さない)

- ADR-0048 dynamic supply 本体実装の宣言
- 軸 G 完了宣言 (= ADR-0048 ζ 完了 + audition approve 後の future)
- **「production-ready 全体達成」 宣言** (= ADR-0056 §決定 3 全 gate 通過 + audition approve 後の future)
- **「軸 B 完成」 表現** (= v2 driver production-ready 化 + ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過後)
- ADR-0048 ζ 案選定 (= ADR-0048 ζ 起票時 user 判断 gate)

### 決定 6: 不可触対象 (= 全 doc-only filing 共通)

次を完全不可触とする。

- **ADR-0048 本文 + Draft 状態 + ε partial state + ζ 未着手 state**:
  - ADR-0048 本体 markdown (= 履歴改変 risk 回避、 stale 化は本 ADR-0060 §決定 1 内に literal 反映のみ)
  - `ppc_scratch_start/stop_lsb/msb` (= 0xFD33-0xFD36) + `audition_frame_counter_lsb/msb` (= 0xFD37-0xFD38) SRAM field
  - `pmdneo_select_adpcmb_ppc_pointer` body / 軸 G δ 接続 routine 全部
  - `driver_pne_sample_table_id` (= 0xFD32) の default 値 0x00 + bit7=0 維持規律
- **ADR-0049〜0059 routine body** (= mute / fade / SSG tone-enable / v2 entry / SRAM placement / F-2-B / 軸 C/G/rhythm 接続点 / song parse + dispatch + IRQ + tempo / ADPCM-B/rhythm 実 dispatch)
- 既存 `adpcmb_keyon` body / `pmdneo_select_adpcmb_sample_pointer` body / `pmdneo_rhythm_event_trigger` body / ADPCMB_DRV.inc / KR_STUB.inc / `adpcma_sample_*` / 既存 `part_workarea` (= 0xF820-)
- 既存 cmd 0x05 path / `pmdneo_song_main` / `pmdneo_part_main` / `irq_handler_body` 既存処理
- vendor / vromtool.py / compile.py / PMDDotNETCompiler
- vendor wav 3 件 + 未確認 untracked MML 3 件 (= user 明示永続 scope-out)

### 決定 7: 単一 doc-only 起票 (= 案 B 採用、 Codex layer 2 plan review approve)

ADR-0060 は **doc-only design ADR** であり実装を伴わないため、 **単一 doc-only PR で起票 + Accepted** (= 案 B 採用、 ADR-0056 同形式)。 sub-sprint chain (= α/β/γ/δ) は設けない。 Codex layer 2 review は plan + doc 全文一括。

#### doc-only filing 規律

- 変更 file = 本 ADR-0060 + `docs/parallel-axes-dashboard.md` (= ADR 番号予約簿 0060 + 軸 B 行 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data / spike 完全不変
- production build PASS + m1 binary byte-identical 維持期待 (= 通算 sha256 b15883fe... を ADR-0060 commit 後にも維持)
- vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm / ADR-0049〜0059 完全不可触

### 決定 8: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 ADR-0060 起票で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model + 後半 再拡張 (= 判断要件も Codex layer 2 自律判断、 mid-flight escalate で止まらず non-stop、 user は完走後確認) を継承する。 主軸の起票 + commit + push + PR + Codex doc review + merge + dashboard update は自律完走、 user 介入は escalate or 最終完走報告のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: ADR-0058 δ-5 TIMER-B IRQ rate 実測 literal 引用 (= 決定 1 ground truth source)

ADR-0058 δ-5 verify gate (= supplemental gate sup-TIMER-B) で TIMER-B IRQ rate を literal 実測:

```
roadmap2-gate-supplemental sup-TIMER-B (= ADR-0058 δ-5):
  pmdneo_irq_count (= 0xF816) write 件数 = 2461 件 / 5 秒 (= MAME headless trace、 wavwrite-seconds 5)
  → 1 秒あたり ~492 Hz (= 2461 / 5 = 492.2 Hz)
  → 1 ms 想定通り (= TIMER-B 想定 freq ~1000 Hz の半分 ≈ 492 Hz)
  → ADR-0048 ε partial 切り分け 5 finding (= 6 秒で 2 回) は完全 stale 確定
```

引用元: `docs/adr/0058-pmdneo-axis-b-v2-roadmap2-song-parse-loop-irq.md` Annex E-3 + L288 + ADR-0058 ε ε completion proof line `sup-TIMER-B: PASS`。

## Annex B: ADR-0048 ε partial 切り分け 5 当時 finding literal 引用 (= 決定 1 stale 元)

ADR-0048 ε partial L869 literal:

```
| 5 | TIMER-B IRQ rate が想定通りか | FAIL (= z80-mem-trace で 0xF816 への write が 6 秒で 3 件のみ
    = IRQ 2 回しか発火、 IRQ counter 経路で 1 秒後 trigger 不能、 別 sprint 改修 scope) |
```

引用元: `docs/adr/0048-pmdneo-axis-g-ppc-parser-and-runtime-dynamic-sample-supply.md` L869。

= 切り分け 5 当時 = 6 秒で 3 件 (= IRQ 2 回発火相当) → ADR-0058 δ-5 = 5 秒で 2461 件 (= IRQ ~2459 回発火) で **完全 stale 化** (= 計測精度 + 計測経路の違いではなく、 driver 実装段階の差異による発火 rate 復旧)。

## Annex C: v2 driver と軸 G の SRAM 領域分離図 (= 決定 2 non-conflict literal)

```
v2 driver_state 拡張 region (= 0xFD39-0xFD78、 64 byte、 ADR-0053 §決定 2):
  0xFD39  pmdneo_v2_fade_level             (= ADR-0050 β)
  0xFD3A  pmdneo_v2_ssg_mixer              (= ADR-0051 β shadow byte)
  0xFD3B  pmdneo_v2_entry_marker           (= ADR-0052 β v2 entry 到達 marker)
  0xFD3C  pmdneo_v2_adpcmb_marker          (= ADR-0055 stub marker)
  0xFD3D  pmdneo_v2_rhythm_marker          (= ADR-0055 stub marker)
  0xFD3E  pmdneo_v2_song_state             (= ADR-0058 δ active flag)
  0xFD3F  pmdneo_v2_tempo_acc              (= ADR-0058 δ tempo subtick accumulator)
  0xFD40  pmdneo_v2_tempo_d                (= ADR-0058 δ tempo delta)
  0xFD41-0xFD60  pmdneo_v2_adpcmb_ix_shim  (= ADR-0059 §決定 3、 32 byte、 案 Q ADPCM-B IX shim)
  0xFD61-0xFD78  (= free 24 byte、 後続軸 future)

軸 G ε partial state (= ADR-0048 §決定 8、 driver_state 拡張 region より前の領域):
  0xFD32  driver_pne_sample_table_id       (= ADR-0023 §決定 4、 軸 G bit7 経路選択)
  0xFD33-0xFD36  ppc_scratch_start/stop_lsb/msb  (= ADR-0048 §決定 8 案 C 軸 G δ、 runtime selection scratch)
  0xFD37-0xFD38  audition_frame_counter_lsb/msb  (= ADR-0048 §決定 8 案 C 軸 G ε integration test mode)
```

v2 driver_state region (= 0xFD39-0xFD78) と軸 G ε partial state (= 0xFD32-0xFD38) は **完全非衝突** (= SRAM 領域分離成立)。 = v2 + 軸 G 同居時 SRAM 競合なし。 ADR-0048 ζ 実装時に v2 wrapper から軸 G 経路を呼ぶ際も両 region は独立。

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: production-ready 化 roadmap の ④ 段階 = 軸 G (= ADPCM 動的供給 = `.PPC` directory 引きで sample を切替える経路) との依存関係を整理する。 v2 driver と軸 G が「どう接続できるか」 を設計書として固定する。 ただし、 軸 G の実装本体は別 ADR (= ADR-0048 ζ) で扱うため、 本 ADR-0060 では実装に踏み込まない。

**前提**: roadmap ① (= FM/SSG 実音) + roadmap ② (= 曲解釈 + 周期再生 + IRQ 連携) + roadmap ③ (= ADPCM-B/rhythm 実 dispatch) は全部完了 (= ADR-0057/0058/0059 Accepted)。 v2 driver は FM/SSG/ADPCM-B/rhythm 4 chip 系統を実 dispatch する段階。 軸 G ADR-0048 は ε partial complete (= PPC audible proof は approve / 同居 audition は reject) + ζ 未着手 (= 着手時期 user 判断)。

**今回の重要発見**: ADR-0048 ε partial で「TIMER-B 割り込みが 6 秒で 2 回しか発火しない」 という finding が ADR-0048 ζ 案 X (= TIMER-B 改修) の前提になっていた。 しかし ADR-0058 δ-5 で「TIMER-B 割り込みは ~492 Hz (= 5 秒で 2461 件) で 1 ms 想定通り」 と実測されたため、 **この古い finding は完全に stale (= 古い計測値)**。 = ADR-0048 ζ 案 X (= TIMER-B 改修) は **不要** な可能性、 軸 G 同居 audition reject の真の原因は別のところにある (= 同居 fixture 設計 / 単発 keyon / トリガ timing 等)。

**決めたこと**: ① ADR-0048 の TIMER-B finding stale 化を ADR-0060 内に literal で書く (= ADR-0048 本文は不変、 ADR-0058 ε / ADR-0059 ε と同じ「後続 ADR で訂正注記」 pattern)。 ② v2 driver から軸 G 経路を呼ぶ方法の設計を概念だけ書く (= 具体 code は書かない、 実装は ADR-0048 ζ で扱う)。 ③ ADR-0048 ζ 着手向けの前提整理 = 案 X 不要 / 案 Y/Z 再評価 を doc-only literal で。 ④ ADR-0059 の sup-sample-table-id-bit7-clear gate (= 軸 G 侵入させない) は roadmap ④ 完了後も維持、 実装時 (= ADR-0048 ζ) に変更する旨を literal 化。 ⑤ ADR-0060 自体は実装を伴わないので **単一 doc-only PR で起票 + Accepted** (= ADR-0056 と同形式、 sub-sprint chain なし、 Codex layer 2 plan review で「案 B 単一起票」 が推奨された)。

**触らないもの**: ADR-0048 本文 + Draft 状態 + ε partial state (= 0xFD32-0xFD38)、 ADR-0049〜0059 routine body 全部、 既存 `adpcmb_keyon` / `pmdneo_select_adpcmb_ppc_pointer` body、 既存 cmd 0x05 path / `pmdneo_song_main` / `irq_handler_body` 既存処理、 vendor。 ADR-0048 ζ 実装 / 軸 G dynamic supply 本体 / 越川氏 audition は完全 scope-out。

**重要 = production-ready 全体達成と書かない** (= ADR-0056 §決定 3 production-ready gate 4 系統 = 実 MML 再生 / 実音 register trace-equivalence / baseline regression / 越川氏 audition 必須、 のうち越川氏 audition は roadmap ④ で未実施、 ADR-0048 ζ も未着手 = production-ready 全体達成は ADR-0048 ζ 完了 + audition approve 後の future)。 **「軸 B 完成」 表現禁止 継続** (= v2 driver production-ready 化が残る = ADR-0045 §I-5-b future + ADR-0056 production-ready gate 全通過)。

**次**: ADR-0060 を doc-only で commit / PR / merge した後、 ADR-0048 ζ 起票 = user 判断 gate (= 案 X/Y/Z の選定 + 着手時期 + 軸 G integration 同居 reject の真の root cause 再調査) → ADR-0048 ζ 完了 + 越川氏 audition approve → production-ready 全体判定 (= ADR-0056 §決定 3 gate 全通過) → user 判断で v2 driver を本番経路へ切替。 これらは順次 user 判断 gate で進める。

## sub-sprint chain 進捗 (= 単一 doc-only 起票、 sub-sprint chain なし、 ADR-0056 同形式)

本 ADR-0060 は **単一 doc-only 起票** (= 案 B 採用、 Codex layer 2 plan review approve 経由)。 sub-sprint chain (= α/β/γ/δ/ε/ζ) は設けない。 計 = **1 PR** で起票 + Accepted。

| 段 | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| 起票 + Accepted | **完了** (= 39th session、 PR # 後続) | PR # 後続 | 起票 plan review approve (= 案 B 単一 PR + 案 P 概念のみ + 案 Y ADR-0048 後続注記 全 recommend、 must-fix なし + nice-to-have 2 件全反映) + doc review (= 後続 commit 後投入) |

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | 起票 + Accepted (= 39th session、 単一 doc-only PR、 案 B 採用) | 軸 B production-ready roadmap ④ = 軸 G dynamic supply 依存整理 の doc-only design ADR を起票。 ADR-0056 §決定 4 roadmap ④ literal 後続実装 ADR、 ADR-0059 Accepted (= roadmap ③ 完了) 後の次フェーズ。 決定 1-8 = ADR-0048 ε partial TIMER-B finding stale 化 (= ADR-0058 δ-5 ~492 Hz literal 実測で覆された、 ADR-0048 本文不変 + 本 ADR-0060 §決定 1 内に literal 反映 = ADR-0058 ε / ADR-0059 ε pattern 同形式) + v2 driver と軸 G ε partial state の依存関係 literal 整理 (= 概念設計のみ、 案 P 採用、 case 1/2/3 候補 literal、 実装は ADR-0048 ζ scope) + ADR-0048 ζ 着手向け前提整理 (= 案 X TIMER-B 不要 / 案 Y MML 拡張継続候補 / 案 Z init 経路順次発火 第一候補 + roadmap ② IRQ tick 駆動との整合検討) + ADR-0059 sup-sample-table-id-bit7-clear gate 関係性 + roadmap ④ 後の bit7=1 侵入可能性 literal + scope-in/out + non-goal + 不可触対象 (= 軸 G ε partial state + ADR-0048 本文 + ADR-0049〜0059 routine body + 既存 routine + vendor) + 単一 doc-only 起票 規律 (= 案 B 採用、 sub-sprint chain なし、 ADR-0056 同形式) + Codex rescue 化継承。 Annex A = ADR-0058 δ-5 TIMER-B ~492 Hz 実測 literal 引用 + Annex B = ADR-0048 ε partial 切り分け 5 当時 finding literal 引用 + Annex C = v2 driver と軸 G の SRAM 領域分離図 (= 非衝突 literal proof)。 Codex layer 2 起票 plan review = approve (= 全 8 観点 + 判断 point 3 件 (案 A vs B / 案 P vs Q / 案 X vs Y) = 案 B/P/Y 推奨採用、 must-fix なし + nice-to-have 2 件 (= 案 B 単一 PR 推奨 + ADR-0060 Accepted ≠ ADR-0048 ζ 完了 ≠ production-ready 全体達成 太字 literal 配置) 全反映、 risk literal Medium = ADR-0048 ε partial state 誤変更 / ADR-0048 Draft 誤 Accepted / 軸 G dynamic supply 実装踏み込み / production-ready 全体達成宣言 / 「軸 B 完成」 表現 = scope-out literal で抑止可能)。 doc-only filing (= ADR-0060 + dashboard のみ変更、 driver / runtime / compiler / vendor / vromtool.py / verify script / spike / fixture 完全不変)、 m1 binary byte-identical 期待 (= 通算 sha256 b15883fe... 維持)。 **ADR-0060 Accepted = roadmap ④「軸 G dynamic supply 依存整理」 完了** ≠ ADR-0048 ζ dynamic supply 本体実装完了 ≠ production-ready 全体達成。 「軸 B 完成」 表現禁止 継続 |
