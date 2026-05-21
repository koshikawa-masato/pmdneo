# ADR-0051: PMDNEO 軸 B 実装 sprint 7 = SSG tone-enable semantics (= SSG note dispatch 時の mixer reg `0x07` on-demand tone enable / symmetric disable、 Phase 12a-5b の always-on 撤去判断を維持、 mixer reg 3ch 共有のため shadow byte で状態管理、 doc-only filing) 設計 (= sprint 7 α、 3 sub-sprint 構成)

- 状態: **Draft** (= 2026-05-21 39th session 軸 B 実装 sprint 7 α、 root cause 調査 + ADR 起票 doc-only filing、 後続 β/γ で driver 実装 → verify → completion。 test-tone-ladder.mml 診断 (= PR #65) で surface した軸 B 実装 sprint。 **軸 B 実装 sprint chain は ADR-0045 §J-4 当初 6 候補 (= 実装 1-4 + mute + fade-out) に本 sprint 7 が追加された形**。 sprint 5 mute (= ADR-0049 Accepted) + sprint 6 fade-out (= ADR-0050 β 完了) は完了済、 実装 1-4 (= δ-1〜δ-4) は未着手。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用)
- 起票日: 2026-05-21
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 本 ADR の母 ADR。 §J-4 実装 sprint bridging note の 6 候補に本 sprint 7 は含まれない = tone-ladder 診断で追加 surface)
  - **ADR-0049** (= 軸 B 実装 sprint 5 mute semantics、 Accepted、 **本 ADR で完全保護**。 mute 仕様変更しない)
  - **ADR-0050** (= 軸 B 実装 sprint 6 fade-out semantics、 β 完了 / Draft。 **本 ADR で fade 経路不可触**。 sub-sprint 構成 / doc-only filing 規律の precedent、 本 ADR が形式を継承)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化 default 永続化、 §決定 7 dashboard 一元管理)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 新規 routine 配置規律)
- 関連 PR:
  - **PR #65** (= `wip-tone-ladder-audition-harness` MERGED、 `PMDNEO_NO_FADE` audition harness flag + `test-tone-ladder.mml` 聴覚診断 MML。 本 ADR の verify fixture 基盤)

## 背景 (= why now)

### test-tone-ladder.mml 診断で surface した SSG 無音 finding

39th session で軸 B 実装 sprint 6 β (= ADR-0050、 fade-out fade decay path) 完了後、 聴覚診断用 MML `test-tone-ladder.mml` (= 1ch ずつ順次発音する staggered tone ladder) を作成した (= PR #65)。 当初 fade が混入し E/F/G/H/I が消えていたが、 `PMDNEO_NO_FADE` harness flag で fade-out audition と tone-ladder audition を分離 (= PR #65) し、 fade なしで全長再生した。

結果、 **FM B/C/E/F (= ド/レ/ミ/ファ) は可聴 (= 越川氏 audition 確認済)、 SSG G/H/I は無音** であることが判明した。 register trace 解析で、 G/H/I は note dispatch 自体は成立 (= tone period reg `0x00-0x05` + volume reg `0x08-0x0A` write 確認) しているが、 **SSG mixer reg `0x07` が `0x3F` (= SSG tone A/B/C 全 disable) のまま** であることが root cause と確定した。

### root cause = SSG tone-enable が playing 経路に未実装

driver source `src/driver/standalone_test.s` 実 source 調査で、 SSG mixer reg `0x07` を書く箇所は **init 1 箇所のみ** と確定した (= Annex A literal)。

- `nmi_cmd_5_init_mml_song` (= L1411-1414) が `reg 0x07 = 0x3F` (= SSG tone + noise 全 disable) を init で write。
- `ssg_keyon` / `ssg_keyoff` / `pmdneo_psg_keyon` / `psg_volume_hook` / `fnumsetp_ch` (= SSG note dispatch + V cmd 経路) は **いずれも reg `0x07` を書かない**。 tone period (= reg `0x00-0x05`) と volume (= reg `0x08-0x0A`) のみ write。
- → G/H/I は tone period + volume が出ても mixer で tone disable のまま = 無音。

`standalone_test.s` L1475-1480 の Phase 12a-5b cleanup comment は「旧 SSG audible setup (= reg `0x07`=`0x38` tone enable + vol `0x0F` max) は撤去。 V cmd / psg_volume_hook 経由で必要時に audible 化する設計」 と記すが、 **`psg_volume_hook` は volume reg しか書かず tone-enable は実装されていない** = 設計意図と実装の gap。 always-on tone-enable の撤去 (= user「SSG ミュートに」要望 2026-05-10、 init audible 残音対策) は実装されたが、 「on-demand で tone-enable する」 部分が未実装のまま残った。

### tone-ladder 診断が長く隠れていた gap を炙り出した

既存 MML fixture (= test01/test02 等) は G/H/I を `V0` (= volume 0) で mute しており、 SSG audible 経路が exercise されてこなかった。 `test-tone-ladder.mml` (= PR #65) が SSG を実際に発音させる初の fixture となり、 本 gap を surface した。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0051 を起票する。 後続 sub-sprint β/γ で driver 実装 → verify → completion を段階的に進める。 mixer reg `0x07` は 3 SSG tone ch を 1 byte で共有するため、 雑な実装は他 ch state / 残音に影響する。 enable/disable の状態管理設計を本 ADR で固定してから実装する。

## 決定

### 決定 1: 軸 B sprint 7 sub-sprint 構成 = 3 段 α/β/γ

SSG tone-enable semantics 実装を **3 段階 α/β/γ** に分割する (= ADR-0049/0050 の sub-sprint precedent を、 sprint 7 の focused scope に合わせ縮約)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | root cause 調査 + ADR-0051 起票 (= doc-only) + 方針 / state-management / verify gate 設計 | root cause literal + 方針 (= on-demand enable / symmetric disable) ADR 化 + mixer reg `0x07` shadow 設計 + verify gate ADR 化 + 3 段 sub-sprint 化、 driver/runtime/compiler/vendor/verify script touch なし、 doc-only | なし |
| **β** | SSG tone-enable on-demand 実装 = SSG note keyon 時 mixer reg `0x07` tone bit enable + keyoff / V0 / part end 時 disable + reg `0x07` shadow byte 導入 + driver-embedded fixture (= 既存 `test-tone-ladder.mml` 流用) | SSG note dispatch で reg `0x07` の該当 tone bit が enable → 完了/V0/part end で disable + register trace primary gate 期待値一致 + noise bit 不変 | 最小限 (= SSG keyon/keyoff/V cmd 経路への tone bit 操作追加 + shadow field + 新規 routine 並設) |
| **γ** | verify script 体系化 + 11 gate 完全化 + completion + ADR-0051 Draft → Accepted 判断 | verify script 追加 + 11 gate 全 PASS + ADR-0049 mute / baseline regression PASS + Accepted 移行判断 (= user 判断 gate 経由) | verify script のみ (= driver touch なし) |

各 sub-sprint = 1 PR。 計 3 PR。 全 PR で軸 G / ADR-0049 mute / ADR-0050 fade 経路 / ADPCM / rhythm 完全不可触 + baseline 保護。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)。 audio 可聴確認は越川氏 audition で別途。
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2)
- 軸 G ADR-0048 / ADR-0049 mute / ADR-0050 fade 経路 / ADPCM / rhythm 完全不可触
- 未確認 untracked MML 3 件 (= `fm-active-ladder.mml` / `ssg-active-ladder.mml` / `ssg-sustained-ladder.mml`) は作成者未確認のため本 ADR sprint で完全不可触 (= commit / 削除 / rename / 内容参照しない)。 正規診断 MML は `test-tone-ladder.mml` (= PR #65 MERGED)
- 「軸 B 完成」 表現禁止 (= 本 sprint 7 は軸 B 実装 sprint chain の一部、 軸 B 全体は未完了)
- α は β に先行する (= ADR-0051 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守)

### 決定 2: root cause (= 実 source 確定)

SSG G/H/I 無音の root cause を `src/driver/standalone_test.s` 実 source で確定する (= Annex A literal)。

1. **init で `reg 0x07 = 0x3F`** — `nmi_cmd_5_init_mml_song` (= L1411-1414) が SSG mixer reg `0x07` に `0x3F` (= tone A/B/C bit 0-2 + noise A/B/C bit 3-5、 全 disable) を write。
2. **playing 経路が reg `0x07` を書かない** — `ssg_keyon` (= L964) / `ssg_keyoff` (= L953) / `pmdneo_psg_keyon` (= L3114、 MML SSG keyon hook 経路) / `psg_volume_hook` (= L3031、 V cmd 経路) / `fnumsetp_ch` (= L2930、 tone period 経路) のいずれも reg `0x07` を touch しない。 tone period (= reg `0x00-0x05`) + volume (= reg `0x08-0x0A`) のみ write。
3. **設計意図と実装の gap** — L1475-1480 Phase 12a-5b cleanup comment は「V cmd / psg_volume_hook 経由で audible 化する設計」 と記すが、 tone-enable は psg_volume_hook にも他経路にも実装されていない。 always-on tone-enable (= reg `0x07`=`0x38`) の撤去のみ実装され、 on-demand tone-enable は未実装。
4. **結果** — G/H/I は tone period + volume write が出ても mixer reg `0x07` = `0x3F` で tone disable のまま = 無音。 register trace では「note dispatch 成立、 mixer tone disable」 が観測される。

### 決定 3: 方針 = on-demand enable / symmetric disable (= always-on へ戻さない)

SSG tone を **on-demand enable / symmetric disable** で実装する。

**tone-enable 条件 = keyon かつ実効 volume > 0** — tone bit を enable する条件は「note keyon」 単独ではなく **「keyon かつ実効 volume > 0」** とする。 enable / disable trigger は次のとおり。

- **tone-enable trigger** — (a) SSG note keyon 時、 該当 part の実効 volume (= V cmd 由来 SSG volume、 0-15 範囲) が **> 0 の場合のみ** 該当 ch の reg `0x07` tone bit を **enable** (= bit clear、 reg `0x07` は 0=enable / 1=disable)。 (b) note 発音中に V cmd で volume が `0 → 正値` へ上がった場合も該当 ch tone bit を enable。
- **tone-enable しないケース** — **実効 volume == 0 (= V0) の状態での note keyon では tone bit を enable しない** (= 無音 part の mixer tone を立てない)。 これにより ADR-0049 mute semantics (= mute 中 part) や V0 設定 part の mixer tone state を立てず、 mute / V0 と非干渉に保つ。
- **tone-disable trigger** — SSG keyoff / V0 (= volume が `正値 → 0` へ変化) / part end 時、 該当 SSG ch の tone bit を **disable** (= bit set)。
- **always-on (= reg `0x07`=`0x38`) へは戻さない** — Phase 12a-5b の always-on 撤去判断 (= init audible で V0 反映までの数十 IRQ tick の SSG 残音を解消、 user「SSG ミュートに」要望) を維持する。 「keyon かつ volume > 0」 で enable / keyoff・V0・part end で disable の **対称性** により、 「鳴っていないのに tone enable」 状態を作らず残音対策を壊さない。
- **noise bit (= reg `0x07` bit 3-5) は touch しない** — noise は本 sprint scope-out (= 決定 6)。 reg `0x07` noise bit は init `0x3F` の disable のまま維持。

### 決定 4: 設計核心 = mixer reg `0x07` の状態管理 (= shadow byte 必須)

mixer reg `0x07` は **1 byte で 3 SSG tone ch (= bit 0-2) + 3 noise ch (= bit 3-5) を共有** する。 1 ch の tone bit のみ変更するには read-modify-write が必要だが、 YM2610 mixer register は read-back できない。 雑に reg `0x07` 全体を write すると他 ch の tone state / noise state を破壊する。

→ driver SRAM に **reg `0x07` の shadow byte** を保持する。

| 項目 | 内容 |
|---|---|
| shadow field | reg `0x07` の現在値を保持する 1 byte。 `pmdneo_v2_*` prefix 命名 (= 候補 `pmdneo_v2_ssg_mixer`、 確定は β 実装)。 |
| 配置 | free region 0xFD3A 以降 (= ADR-0050 β が `pmdneo_v2_fade_level` で 0xFD39 を使用済、 次は 0xFD3A。 ADR-0050 §決定 4 SRAM placement 規律と整合) |
| init 値 / 初期同期タイミング | song init 時 (= `nmi_cmd_5_init_mml_song` の既存 reg `0x07` = `0x3F` write と同期) に shadow byte を `0x3F` (= 全 disable) へ初期化する。 shadow byte の初期値と実 reg `0x07` の初期値を song init 時点で必ず一致させる (= shadow と chip state の初期同期、 以降は read-modify-write で同期維持) |
| tone-enable 操作 | shadow の該当 ch tone bit (= bit `ch_idx`) を clear → reg `0x07` へ shadow write |
| tone-disable 操作 | shadow の該当 ch tone bit を set → reg `0x07` へ shadow write |
| noise bit | shadow bit 3-5 は init `0x3F` のまま不変 = noise 常時 disable 維持 |

shadow により、 任意の 1 SSG ch の tone bit 操作が他 ch tone / noise state を破壊しない。 WORKAREA.inc 同期方針 = active driver `standalone_test.s` 内 `.equ` 追加のみ (= legacy `WORKAREA.inc` touch しない、 ADR-0050 §決定 4 と同)。

### 決定 5: verify gate (= register trace primary gate、 11 gate)

SSG tone-enable semantics は **register trace primary gate** で verify する。 fixture = `test-tone-ladder.mml` + `PMDNEO_NO_FADE=1` build (= PR #65、 fade 混入なしで SSG 区間を観測)。 γ sub-sprint で次の **11 gate** を verify script (= `src/test-fixtures/axis-b/verify-ssg-tone-enable.sh` 想定) に確立する。

| # | gate | 期待 |
|---|---|---|
| 1 | SSG tone period write | G/H/I note dispatch で reg `0x00-0x05` (= tone period) write 発生 |
| 2 | SSG volume write | G/H/I note dispatch / V cmd で reg `0x08-0x0A` (= volume) write 発生 |
| 3 | mixer tone enable | G/H/I 発音区間 (= keyon かつ volume > 0) で reg `0x07` の該当 SSG ch tone bit (= bit 0/1/2) が `0` (= enable) になる |
| 4 | mixer tone disable 復帰 | note 終了 / V0 / part end で該当 ch tone bit が `1` (= disable) に戻る |
| 5 | V0 keyon non-enable | 実効 volume == 0 (= V0) の状態での SSG note keyon dispatch で、 reg `0x07` の該当 ch tone bit が **enable されない** (= `1` disable のまま、 無音 part の mixer tone を立てない、 §決定 3) |
| 6 | noise bit 不変 | reg `0x07` の noise bit (= bit 3-5) が全区間で `1` (= disable) のまま (= noise scope-out) |
| 7 | shadow 整合 | reg `0x07` write 値が shadow byte と一致 + 他 ch tone state を破壊しない (= 1 ch enable 時に他 ch bit 不変) |
| 8 | FM 回帰 (= register trace) | FM B/C/E/F の keyon + TL register trace が SSG tone-enable 実装の前後で正常維持 (= register trace primary gate。 越川氏 audition は完了判定に含めない = option、 本 §末尾) |
| 9 | ADR-0049 mute regression | `src/test-fixtures/axis-b/verify-mute-semantics.sh` 7 gate 全 PASS |
| 10 | baseline regression | ADR-0049 Annex F-4 literal の既存 verify script 9 件 実行 + 全 PASS |
| 11 | `.org` overflow / section overlap | production build `.lst` で新規 routine が `.org` 境界と overlap なし (= memory `feedback_org_section_overflow_silent_bug.md`) + 新規 SRAM field が free region 内 + 既存 field 非 overlap |

ADR-0050 fade 経路は本 sprint で touch しないため fade regression gate は設けない (= fade 経路不可触、 決定 6)。 audio gate は本 sprint 7 の完了判定には用いない (= register trace primary gate、 gate 1-11 は全て register/memory trace で判定可能)。 越川氏 audition (= SSG G/H/I が ソ/ラ/シ で可聴になるか) は完了判定には含めず、 β or γ で option として 1 回実施できる。

### 決定 6: scope-in / scope-out / non-goal

#### scope-in (= sprint 7 で扱う)

- SSG note keyon 時の mixer reg `0x07` tone bit on-demand enable
- SSG keyoff / V0 / part end 時の tone bit symmetric disable
- reg `0x07` shadow byte による 3ch 共有 register の状態管理
- `test-tone-ladder.mml` + `PMDNEO_NO_FADE=1` での register trace verify

#### scope-out (= 別 ADR / 別軸 / future sprint)

- **SSG noise** — reg `0x07` noise bit (= bit 3-5) は触らない。 noise 経路は別 sprint
- **SSG envelope 本格対応** — SSG software envelope / hardware envelope (= reg `0x0D` 等) は別 sprint
- **MML `fade_set` stub 現役化** — 別軸 / 後続 sprint
- **ADR-0050 fade 経路** — fade decay path は不可触 (= fade 経路への tone bit 干渉なし)
- **legacy driver への SSG tone-enable 実装** — active driver `standalone_test.s` のみ対象

#### non-goal (= 軸 B sprint 7 として目指さない)

- 軸 G ADR-0048 / ADR-0049 mute 仕様 / ADR-0050 fade 経路 / ADPCM / rhythm の modify (= 完全不可触)
- always-on SSG tone-enable (= reg `0x07`=`0x38`) への回帰 (= Phase 12a-5b 撤去判断を維持)

### 決定 7: doc-only filing 規律 (= 本 ADR-0051 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0051 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0051 (= 新規) + `docs/parallel-axes-dashboard.md` (= 軸 B 行 + ADR 番号予約簿 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data 完全不変
- 未確認 untracked MML 3 件 完全不可触 (= 決定 1 共通規律)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触
- ADR-0049 Accepted + ADR-0050 β 完了 不可触

### 決定 8: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

本 sprint 7 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化を継承する。 主軸の user 確認質問 (= driver / 実装 / 配置 / ADR 大型更新) は user 確認の前に Codex layer 2 投入を default 化。 user 介入は escalate or 最終確認 (= PR merge / Accepted 移行判断) のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= root cause 調査 + ADR 起票) | **完了** (= 39th session、 PR #66 MERGED) | PR #66 | ADR-0051 起票 review = revise (must-fix 1 V>0 ガード) → 修正 → approve |
| β (= SSG tone-enable on-demand 実装) | **完了** (= 39th session、 本 PR) | 本 PR | 実装 plan review = revise (must-fix 2) → 修正 → approve + completion review (= 後続) |
| γ (= verify script 体系化 + completion + Accepted 判断) | 未着手 | - | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: PMDNEO の SSG (= G/H/I パート) が、 MML で音符を書いても鳴らない問題を直す設計を文書として固定する。

**前提**: 聴覚診断用 MML `test-tone-ladder.mml` で SSG を鳴らそうとしたら無音だった。 調査の結果、 driver は SSG の音程と音量のレジスタは書いているが、 音を出すか止めるかを決める「ミキサーレジスタ `0x07`」 が `0x3F` (= 全 SSG tone 停止) のままになっていた。 過去に「常時 ON」 の設定があったが、 残音対策で撤去され、 その代わりの「必要な時だけ ON」 が実装されないまま残っていた。

**やったこと**: driver の実 source で SSG 関連 routine を全数調査し、 mixer reg `0x07` を書くのが init の 1 箇所だけ (= 全 disable) で、 音符を鳴らす経路がどこも reg `0x07` を触らないことを確定した。 これを ADR-0051 として起票し、 3 段の sub-sprint (= α/β/γ) と verify gate 11 件、 設計核心 (= reg `0x07` は 3ch 共有なので shadow byte で状態管理) を定義した。

**結果**: SSG tone-enable の設計が文書として固定された。 方針は「音符の keyon で該当 ch の tone を ON、 keyoff / 音量 0 / パート終了で OFF」 という対称的な on-demand 方式。 過去の「常時 ON 撤去」 判断は維持する。

**解釈**: これは設計の起票であり、 SSG tone-enable の実装は完了していない。 後続の β で driver を改修し、 γ で verify と完了判断する。

**次**: β sub-sprint (= driver 実装) 着手は本 ADR-0051 doc-only PR の MERGED 後。

## Annex A: SSG mixer reg `0x07` root cause source ground truth

`src/driver/standalone_test.s` (= 2026-05-21 時点) の SSG mixer 経路を全数調査した。

### A-1: init での reg `0x07` write (= L1411-1414)

```
;; SSG all tone+noise disable (reg 0x07 = 0x3F)
ld   b, #0x07
ld   c, #0x3F
call ym2610_write_port_a
```

`nmi_cmd_5_init_mml_song` 内。 reg `0x07` = `0x3F` = bit 0-2 (SSG tone A/B/C) + bit 3-5 (noise A/B/C) 全 set = 全 disable。 SSG mixer reg は 0=enable / 1=disable。

### A-2: Phase 12a-5b cleanup comment (= L1475-1480)

```
;; Phase 12a-5b cleanup: 旧 SSG audible setup (= reg 0x07=0x38 tone enable
;; + vol 0x0F max) は撤去。 driver init 段階では SSG mute 維持 (= reg 0x07=0x3F
;; all disable + vol 0x00、 init で既設定済) で、 V cmd / V+/V- 等で必要時に
;; psg_volume_hook 経由で audible 化する設計。 user 「SSG ミュートに」 要望
;; (= 2026-05-10) で test04 audio gate 反映、 init audible で V0 反映までの
;; 数十 IRQ tick で SSG 残音する真因を解消。
```

旧 always-on tone-enable (= reg `0x07`=`0x38` = bit 0-2 clear で tone A/B/C enable) を撤去。 撤去理由 = init audible だと V0 反映までの数十 IRQ tick で SSG が残音する (= user「SSG ミュートに」要望、 2026-05-10)。 comment は「V cmd / psg_volume_hook 経由で audible 化する設計」 と記すが、 tone-enable は実装されていない (= A-4)。

### A-3: SSG note dispatch / V cmd 経路 (= reg `0x07` を書かない)

| routine | 行 | reg write |
|---|---|---|
| `ssg_keyon` | L964 | reg `0x08`+ch (= volume `0x0F`) のみ |
| `ssg_keyoff` | L953 | reg `0x08`+ch (= volume `0x00`) のみ |
| `pmdneo_psg_keyon` | L3114 | `fnumsetp_ch` (= tone period) + reg `0x08-0x0A` (= volume) |
| `psg_volume_hook` | L3031 | reg `0x08-0x0A` (= volume、 V cmd 経路) |
| `fnumsetp_ch` | L2930 | reg `0x00-0x05` (= tone period) |

いずれも reg `0x07` (= mixer) を touch しない。

### A-4: A-1〜A-3 から確定する root cause

1. reg `0x07` を書くのは init (= A-1) の 1 箇所のみ、 値 `0x3F` (= 全 disable)。
2. SSG note dispatch / V cmd 経路 (= A-3) は tone period + volume を書くが reg `0x07` を書かない。
3. = G/H/I は note dispatch しても mixer で tone disable のまま → 無音。
4. Phase 12a-5b cleanup (= A-2) は always-on tone-enable を撤去したが、 comment が「設計」 とする on-demand tone-enable (= psg_volume_hook 経由) は実装されていない = 設計意図と実装の gap。

### A-5: register trace 証跡 (= PR #65 test-tone-ladder.mml + PMDNEO_NO_FADE=1)

`test-tone-ladder.mml` を `PMDNEO_NO_FADE=1` build + MAME headless trace した実測:

- SSG tone period reg `0x00-0x05` = G/H/I 各 ch に write 発生 (= note dispatch 成立)
- SSG volume reg `0x08-0x0A` = `0x0F`/`0x00` toggle 発生 (= volume 経路成立)
- SSG mixer reg `0x07` = `0x3F` が idx 96 で 1 回 write、 以降全区間で変化なし (= tone disable のまま)
- FM B/C/E/F = keyon + TL trace 正常、 fade なしで可聴 (= 越川氏 audition 確認済)

## Annex B: verify gate 詳細 + SRAM map literal

### B-1: verify script 想定

γ sub-sprint で `src/test-fixtures/axis-b/verify-ssg-tone-enable.sh` (想定) に 11 gate (= 決定 5) を体系化する。 ADR-0049 `verify-mute-semantics.sh` の verify script 構造を踏襲。 fixture = `test-tone-ladder.mml` + `PMDNEO_NO_FADE=1` build (= PR #65)。

### B-2: SRAM map (= shadow field 配置基点)

`src/driver/standalone_test.s` (= 2026-05-21 時点、 ADR-0050 β 反映後):

| 領域 | addr | 備考 |
|---|---|---|
| `pmdneo_v2_fade_level` | 0xFD39 | ADR-0050 β、 1 byte |
| **free region** | **0xFD3A-0xFFBF** | 646 byte。 本 sprint 7 の reg `0x07` shadow field を 0xFD3A に配置想定 |

新規 reg `0x07` shadow field は free region 0xFD3A へ配置 (= 決定 4)。 verify gate 10 はこの範囲を照合基点とする。

### B-3: 新規 routine 配置

β 実装の新規 routine (= tone-enable / tone-disable + shadow 操作) は `.org` 制約のない `0x0610` セクション末尾に配置する (= ADR-0050 β `pmdneo_v2_fade_*` 配置 pattern 踏襲、 memory `feedback_org_section_overflow_silent_bug.md`)。 `.org 0x0100` IRQ handler body 等の 256 byte 制約セクションへの routine 配置は行わない。

## Annex C: β 実装 completion record (= SSG tone-enable on-demand 実装)

### C-1: β deliverable

軸 B 実装 sprint 7 β = SSG tone-enable on-demand 実装 (= 39th session、 本 PR)。 §決定 3/4 の方針どおり driver `src/driver/standalone_test.s` に実装した。

| 実装項目 | 内容 |
|---|---|
| `pmdneo_v2_ssg_mixer` | 1 byte SRAM field @ 0xFD3A (= reg `0x07` shadow、 §決定 4)。 song init で `0x3F` 同期初期化 |
| `pmdneo_ssg_tone_sync` | 新規 helper (= 0x0610 セクション末尾)。 入力 B=ch_idx / A=実効 volume。 A>0 → 該当 tone bit enable、 A==0 → disable。 shadow read-modify-write + reg `0x07` write。 reg `0x07` の唯一の RMW owner |
| `pmdneo_ssg_tone_mask` | tone bit mask table `.db 0x01,0x02,0x04` |
| keyon hook | `pmdneo_psg_keyon` 冒頭で `pmdneo_ssg_tone_sync` (= raw V level、 fade scale 前)。 vol>0 enable / V0 keyon は enable しない。 `pmdneo_ssg_tone_sync` は AF/BC を破壊するため、 後続 `fnumsetp_ch` (= A=note byte 契約) の前に A=note を `PART_OFF_NOTE` から、 B=ch_idx を IX から再ロード (= Codex completion review must-fix 1 修正、 C-4 参照) |
| keyoff hook | `ssg_keyoff_hook` で `call ssg_keyoff` 後に tone bit disable |
| V cmd hook | `psg_volume_hook` で V0 時のみ disable。 V>0 は tone bit 不変 (= enable は keyon hook に集約、 rest 中 V コマンドでの premature enable 回避) |
| init 同期 | `nmi_cmd_5_init_mml_song` の既存 reg `0x07`=`0x3F` write に隣接して shadow も `0x3F` 初期化 |

Codex layer 2 review = 実装 plan review で revise (= must-fix 2 件 = keyon hook の BC/stack 整合 + V cmd hook の premature enable 回避) → 修正 → approve。 completion review で revise (= must-fix 1 = keyon hook が A=note byte を破壊し `fnumsetp_ch` に誤値が渡る、 C-4 の SSG pitch bug 真因 / must-fix 2 = `0xFB` 経路) → must-fix 1 修正 → 再 review。

**part-end / tie の扱い** (= completion review must-fix 2 の論点整理): bytecode `0xFB` は **tie marker** (= compile.py `&` → `0xFB`)、 part-end terminator ではない (= terminator は `0x80`)。 `pmdneo_part_main` が note 終了時に次 byte `0xFB` で keyoff を skip するのは **tie の正しい挙動** (= tied note は持続、 tone は継続 enable が正)。 非 tie の note は keyoff hook (`ssg_keyoff_hook`) で tone disable されるため、 通常 part の part-end では最終 note の keyoff で tone disable 済。 tie で終わる part (= tie-at-end、 malformed MML 想定) のみ tone enable が残るが、 `test-tone-ladder.mml` 含む通常 MML には該当せず、 別 follow-up に literal 残す (= β plan review でも同判定)。

### C-2: β verify 結果 (= register trace primary gate)

fixture = `test-tone-ladder.mml` + `PMDNEO_NO_FADE=1` build。 MAME headless register trace 実測:

- SSG tone period reg `0x00-0x05` = G/H/I 各 ch に write 発生 (= note dispatch 成立)。 must-fix 1 修正後、 tone period は G (LSB `0x9F`) > H (`0x8D`) > I (`0x7E`) = g4 < a4 < b4 の周波数 = ascending (= C-4 の pitch bug 修正確認)
- SSG mixer reg `0x07` = G 区間で `0x3E` (= ch A tone bit のみ enable)、 H 区間で `0x3D` (= ch B)、 I 区間で `0x3B` (= ch C)、 各 note 後 `0x3F` (= 全 disable) へ復帰。 reg `0x07` の distinct 値は `3B / 3D / 3E / 3F` のみ = 単一 tone bit 操作で他 ch tone / noise bit (= bit 3-5 常時 `1`) を破壊しない
- G/H/I の leading rest 中は reg `0x07` = `0x3F` 維持 = V15 (part 先頭) でも premature tone enable なし
- FM keyon F1/F2/F5/F6 全発火 = FM B/C/E/F 回帰なし
- `verify-mute-semantics.sh` 7 gate + baseline 9 script ALL PASS = ADR-0049 mute regression なし
- production build `.lst` で `pmdneo_ssg_tone_sync` は 0x0610 セクション配置、 `.org` overlap なし

### C-3: user audition 結果 (= literal 記録)

越川氏 audition (= `test-tone-ladder.mml` + `PMDNEO_NO_FADE=1`、 fade なし全長再生) の結果を literal 記録する。

**1 回目 audition (= must-fix 1 修正前)**:

> 「そ、ら、は低い音で鳴り、し、は普通通りになった気がします」

= SSG G/H/I は β tone-enable 実装により無音から可聴になった (= β の目的達成) が、 G (ソ) / H (ラ) の pitch が低かった。 この pitch 異常の真因は Codex completion review で β 自身の bug と判明 (= C-4)。

**2 回目 audition (= must-fix 1 修正後)**:

> 「(ソ ラ シ を含め) それ以外は正常になっています」 (= FM ド の attack click を除き正常)

= must-fix 1 修正で SSG G/H/I の pitch が正常化 (= ソ ラ シ が ascending)。 FM ド の attack click は別 finding (= C-5)。

### C-4: SSG pitch 異常の真因 = β 自身の bug (= must-fix 1、 β 内で修正済)

C-3 の 1 回目 audition で surface した SSG pitch 異常 (= ソ/ラ低い) の真因は、 当初「pre-existing bug」 と推定したが、 **Codex layer 2 completion review で β 自身の実装 bug と判明し、 β 内で修正した**。

- **真因**: keyon hook の `pmdneo_psg_keyon` で、 追加した `pmdneo_ssg_tone_sync` 呼出が A register を破壊。 後続 `call fnumsetp_ch` (= SSG tone period 計算、 A=note byte 契約) が note byte ではなく `pmdneo_ssg_tone_sync` の残値 (= mixer shadow 値 `0x3E`/`0x3D`/`0x3B`) を受け、 SSG tone period が壊れていた。 = β の register 破壊 bug。
- **症状の説明**: G keyon 時 A=`0x3E` (= octave 3 / onkai 14 = out-of-range) → 異常 period → 低音。 H keyon 時 A=`0x3D` → 同様。 I keyon 時 A=`0x3B` (= octave 3 / onkai 11 = B) → 偶然 valid な B note (octave 3) → 「普通」 に聴こえた。
- **修正**: `pmdneo_psg_keyon` で `call fnumsetp_ch` の前に `ld a, PART_OFF_NOTE(ix)` で A=note byte を再ロード (= C-1 keyon hook 行)。 修正後 trace で SSG tone period が ascending に正常化 (= C-2)、 2 回目 audition で ソ ラ シ 正常確認 (= C-3)。
- **教訓**: `fnumsetp_ch` は A=note byte 契約。 keyon hook に register 破壊 routine を差し込む際は契約 register (A/B) の再確立が必須。 `test-tone-ladder.mml` 診断 MML が β 自身の register 破壊 bug を audition で炙り出した。

### C-5: FM attack click finding (= β scope 外、 後続候補)

C-3 の 2 回目 audition で、 FM B の `ド` (= `c1 c1` の 2 note) の attack でクリック音が聴取された。 これは **β (= SSG tone-enable) scope 外の FM 領域の finding** であり、 別 finding として記録する (= β PR に含めない、 FM note dispatch / voice は β で不可触)。

- **症状**: FM B の `ド` の 1 回目・2 回目それぞれの note attack でクリック音。 FM C/E/F は同種の可能性あり。
- **想定原因 (= 断定しない、 両論併記)**:
  1. **voice 由来**: `@001` voice は modulator (slot 1-3) AR=31 (= 最速) + feedback fb=5 のため、 keyon 直後に FM 変調 (倍音) が瞬時に立ち上がり attack transient が出やすい。 voice の AR / feedback 調整で軽減しうる。
  2. **FM note dispatch 由来**: FM の keyoff → register write → keyon の順序、 keyon 中の TL/fnum 書換、 keyoff から次 keyon までの間隔等でもクリックは生じうる。 FM note dispatch trace review が必要。
- **扱い**: β scope 外。 後続候補 = 別 sprint で (a) voice 調整 fixture、 または (b) FM note-dispatch (keyoff→register write→keyon 順序) trace review。 起票するかは user 判断。 β は `fnumsetp_ch` / FM voice / FM keyon を不可触。

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-21 | Draft 起票 (= 39th session 軸 B 実装 sprint 7 α) | SSG tone-enable root cause 全数調査 (= Annex A) + 決定 1-8 + verify gate 11 件 + 設計核心 (= reg `0x07` shadow byte 状態管理) + 3 段 sub-sprint 構成、 doc-only filing (= ADR-0051 + dashboard のみ変更)。 test-tone-ladder.mml 診断 (= PR #65) で surface した軸 B 実装 sprint。 ADR-0045 §J-4 当初 6 候補に追加された sprint 7 |
| 2026-05-21 | β 実装完了 (= 39th session、 本 PR) | SSG tone-enable on-demand 実装 = `pmdneo_v2_ssg_mixer` shadow byte + `pmdneo_ssg_tone_sync` helper + keyon/keyoff/V cmd hook + init 同期。 Annex C 追記 (= C-1 deliverable / C-2 verify 結果 register trace 全 gate PASS + SSG tone period ascending / C-3 user audition 結果 literal 2 回 / C-4 SSG pitch 異常の真因 = β 自身の register 破壊 bug = must-fix 1、 β 内で修正済 / C-5 FM attack click finding = β scope 外・後続候補) + sub-sprint chain α/β 完了 reflect。 Codex layer 2 = plan review revise→approve + completion review revise (= must-fix 1 keyon hook A=note 破壊) → 修正 → 再 review。 driver `standalone_test.s` 実装、 `fnumsetp_ch` / FM voice / FM keyon 不可触、 ADR-0049 mute / ADR-0050 fade 経路 / 軸 G ADR-0048 不可触。 軸 B 実装 sprint chain 進行中 (= 「軸 B 完成」 表現不使用) |
