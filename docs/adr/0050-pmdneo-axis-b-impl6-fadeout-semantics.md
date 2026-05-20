# ADR-0050: PMDNEO 軸 B 実装 sprint 6 = fade-out semantics (= 楽曲全体 fade-out、 現 active 段階 fade 経路の ADPCM-A 限定減衰を FM/SSG/ADPCM-B へ semantic 拡張、 案 1 = active 経路拡張 + 設計核心 3 論点 A/B/C 起票) 設計 (= sprint 6 α、 5 sub-sprint 構成、 doc-only filing)

- 状態: **Draft** (= 2026-05-20 38th session 軸 B 実装 sprint 6 α、 ground truth 全数調査 + ADR 起票 doc-only filing、 後続 β/γ/δ/ε で driver 実装 → verify → completion。 ADR-0045 §J-4-6 literal 後続実装 ADR。 **軸 B 実装 sprint chain 6 sprint 中 2 本目** = sprint 5 mute (= ADR-0049 Accepted) 完了、 本 sprint 6 = fade-out。 軸 B 全体は未完了、 「軸 B 完成」 表現不使用)
- 起票日: 2026-05-20
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §J-4-6 で実装 sprint 6 = fade-out semantics を literal 化、 本 ADR の母 ADR)
  - **ADR-0049** (= 軸 B 実装 sprint 5 mute semantics、 Accepted、 sub-sprint 構成 / verify gate / doc-only filing 規律の precedent、 本 ADR が形式を継承)
  - ADR-0041 (= Claude Code 併走運用、 §決定 3 軸別 wip- branch、 §決定 4-2 Codex rescue 化 default 永続化、 §決定 7 dashboard 一元管理)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**、 軸 G を完成扱いしない)
  - ADR-0044 (= 軸 F MML compiler 拡張 完成扱い、 F-2-A 将来 sprint defer 維持、 本 ADR で MML fade command 経路は scope-out)
  - ADR-0043 (= 軸 C ADPCM-B runtime-managed architecture、 Accepted、 **本 ADR で完全不可触**、 production-ready 保護)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_parallel_axis_orchestration.md` (= 併走運用 10 規律、 軸 B 実装 sprint 起票 prompt 規律基盤)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 default 永続化、 38th session 適用継続)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= Codex layer 2 review 依頼時 commit 権限なし明示)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace、 fade-out semantics verify gate 基盤)
  - `feedback_org_section_overflow_silent_bug.md` (= `.org` セクション overflow を sdasz80 が silent 配置、 38th session 軸 B sprint 5 β finding、 fade routine 配置規律基盤)

## 背景 (= why now)

### 軸 B 実装 sprint 5 完了 base + sprint 6 起票 phase

38th session で軸 B 実装 sprint 5 (= mute semantics、 ADR-0049) が Draft → Accepted 移行完了した (= 5 段 α/β/γ/δ/ε 全走 + 計 6 PR MERGED + Codex layer 2 全 chain approve)。 ADR-0049 Accepted = **軸 B 実装 sprint 5 完了であり、 軸 B 全体完了ではない** (= memory `feedback_axis_design_adr_accepted_vs_implementation_completion.md` literal、 「軸 B 完成」 表現禁止)。 軸 B 実装 sprint chain は 6 sprint 構成で、 sprint 5 (= mute) が 1 本目完了、 本 ADR-0050 = sprint 6 (= fade-out) が 2 本目。

### priority 5 → 6 (= 38th session user 判断)

ADR-0045 §J-4 の実装 sprint 6 候補を 38th session で主軸が比較し、 Codex layer 2 round 3 approve 取得。 user 判断 = **priority 5 → 6 → 1 → 2 → 3 → 4** (= mute semantics 最優先、 fade-out semantics 次点)。 sprint 5 mute 完了に伴い、 本 sprint 6 = fade-out semantics に着手する。

### 楽曲全体 fade-out 動機 (= user 追加要件)

user 追加要件 = 「楽曲全体 fade-out をちゃんと実装対象にする」。 現 PMDNEO の active 段階 fade 経路は **ADPCM-A の master volume のみ** を減衰させ、 FM/SSG/ADPCM-B は減衰しない (= Annex A literal)。 これは「楽曲全体が徐々に小さくなって消える」 という fade-out の本来の挙動を満たさない。 本 sprint 6 で active 段階 fade を FM 6ch + SSG 3ch + ADPCM-A + ADPCM-B の全 chip 減衰へ semantic 拡張し、 楽曲全体 fade-out を PMDNEO の正式な driver behavior として確立する。

### 既存 fade 経路 3 系統 + 不足箇所

現 PMDNEO driver には「fade」 を名乗る routine が 3 系統あり、 semantics が全て異なる (= ground truth 調査で確定、 Annex A/B/C literal)。

| 経路 | file:routine | semantics | 対象 chip | 現状 |
|---|---|---|---|---|
| active 段階 fade | `standalone_test.s` `nmi_cmd_6_fade_start` (L464) + `irq_fade_*` (L501-530) | NMI cmd 6 で fade 開始 → IRQ tick 毎に段階減衰 | **ADPCM-A のみ** | 実装済、 ADPCM-A 限定 |
| cmd 0x04 即 silence | `IRQ.inc` `snd_command_04_fade_out` (L84-111) | cmd 0x04 で**即時 silence** + song 停止 | SSG ABC + FM 6ch + ADPCM-B keyoff | 実装済、 段階 fade ではない |
| MML fade cmd | `PMD_Z80.inc` `fade_set` (L2080-2082、 bytecode 0xD2) | MML `F` コマンド | (なし) | **no-op stub** |

**不足箇所** (= ground truth 調査で確定):

1. **active 段階 fade が ADPCM-A 限定** = `irq_fade_*` は ADPCM-A の master volume register (= port B reg `0x01`) しか減衰させない。 FM operator TL / SSG channel volume は不変。 楽曲全体 fade-out 未達 (= Annex A literal)。
2. **MML fade コマンドが未実装** = PMD V4.8s 由来 MML `F` コマンド (= bytecode 0xD2) の handler `fade_set` は arg byte を読むだけの no-op stub (= Annex C literal)。
3. **本家 fade 流儀との差** = PMD V4.8s / PMDDotNET は `fadeout_volume` という減衰量を Timer-A 駆動で ramp し、 各 chip の volume 計算に乗算 factor として混ぜる (= Annex D literal)。 現 PMDNEO の ADPCM-A master volume 直接減衰はこの流儀を一部しか持たない。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 doc-only filing として本 ADR-0050 を起票する。 後続 sub-sprint β/γ/δ/ε で fade decay path 実装 → fade finish path 実装 → register trace verify gate → completion を段階的に進める。

## 決定

### 決定 1: 軸 B sprint 6 sub-sprint 構成 = 5 段 α/β/γ/δ/ε

fade-out semantics 実装を **5 段階 α/β/γ/δ/ε** に分割する (= ADR-0049 sprint 5 precedent 踏襲)。

| sub | 内容 | 完了判定 | driver touch |
|---|---|---|---|
| **α** | fade-out ground truth 全数調査 (= 3 経路 + PMD V4.8s/PMDDotNET fadeout source) + ADR-0050 起票 (= doc-only) + 設計核心論点 A/B/C 比較整理 | 3 fade 経路 literal + PMD V4.8s/PMDDotNET fadeout 構造 literal + 設計核心 3 論点 ADR 化 + verify gate 10 件 ADR 化 + 5 段 sub-sprint 化、 driver/runtime/compiler/vendor/vromtool.py touch なし、 doc-only | なし |
| **β** | fade decay path 実装 = active 段階 fade を FM/SSG/ADPCM-A/ADPCM-B 全 chip 段階減衰へ拡張 + driver-embedded fixture (= `TEST_MODE_FADE_FIXTURE`) | fade 開始 → IRQ tick 毎に chip 別段階減衰 register write 発生 + register trace primary gate 期待値一致 (= driver-embedded fixture で実測) + 決定 3 論点 A の採用案に従った fade 適用 | 最小限 (= active fade routine 拡張 + fade decay path 並設 + fixture) |
| **γ** | fade finish path 実装 = 減衰完了時 (= 全 chip volume 0 到達) に全 chip keyoff (= safe silence) | fade finish で 4 chip keyoff register write 発生 (= ADR-0049 §決定 5 の 4 chip keyoff routine 本体直接 call) + register trace primary gate 期待値一致 | 最小限 (= fade finish path 並設) |
| **δ** | verify script 体系化 + 10 gate 完全化 = β/γ の driver-embedded fixture を使った verify script 化 + 10 gate を再現可能な script に体系化 + build infra 切替 | verify script 追加 + 10 gate 全 PASS + build infra (= `TEST_MODE_FADE_FIXTURE` sed 切替) 化 | verify script のみ (= driver touch なし) |
| **ε** | completion + ADR-0050 Draft → Accepted 判断 | 全 sub α/β/γ/δ verify gate PASS + 規律遵守確認 + Accepted 移行判断 (= user 判断 gate 経由) | なし |

各 sub-sprint = 1 PR (= ADR-0049 §決定 1 precedent = sprint = PR 1 対 1 規律、 ADR-0041 §決定 4-2 継承)。 計 5 PR。 全 PR で軸 G / 軸 C / rhythm routine 完全不可触 + baseline byte-identical 維持。

#### 共通規律 (= 全 sub-sprint 共通)

- primary gate = register trace (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)
- 1 sub-sprint = 1 commit + 1 PR、 commit 前報告 + Codex layer 2 review (= ADR-0041 §決定 4-2 運用 3 手順)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触、 軸 G を完成扱いしない
- ADR-0043 軸 C + ADR-0026〜0031 rhythm routine 完全不可触 (= 並設 only or 本体直接 call only、 既存 routine modify なし)
- ADR-0044 Accepted + F-2-A defer 維持
- vendor wav 3 件 untracked retain (= commit 混入禁止)、 vromtool.py 不変
- 「軸 B 完成」 表現禁止 (= 「ADR-0050 α 完了 = fade-out semantics 設計起票」 表記、 軸 B 実装完了ではない)
- α は β に先行する (= ADR-0050 doc-only PR が MERGED されてから β 着手、 設計書ファースト遵守、 α を経ない β 先行禁止)

### 決定 2: fade-out semantics = 案 1 (= active 段階 fade 経路の拡張) 第一候補

ADR-0045 §J-4-6 §user 判断 gate =「既存 fade routine 流用 vs 新規 v2 fade routine 並設」。 38th session user hint =「既存 ADPCM-A 寄りの fade 経路 A を base に FM/SSG/ADPCM-B semantic 拡張」。 本 ADR は **案 1 = active 段階 fade 経路 (= `nmi_cmd_6_fade_start` + `irq_fade_*`) の拡張** を第一候補とする。

| 案 | 内容 | 評価 |
|---|---|---|
| **案 1 (= 第一候補)** | active 段階 fade 経路を base に、 ADPCM-A 限定減衰を FM/SSG/ADPCM-B へ semantic 拡張。 既存 `driver_fade_*` field 流用 + 新規 field は free region 配置 | 既存実装の流用で scope 最小、 38th session user hint と整合 |
| 案 2 | 既存 `irq_fade_*` を不可触保持し、 新規 v2 fade routine を `.org 0x0610` セクションに並設、 NMI cmd 6 を新 routine 配線 | 既存経路完全保護だが routine 二重化、 scope 拡大 |

案 1/案 2 の最終確定 + 決定 3 論点 A の fade 適用位置は **β 着手前に Codex layer 2 壁打ち → user 判断 gate** で確定する (= ADR-0041 §決定 4-2、 α 完了時)。

### 決定 3: 設計核心論点 A = fade 適用位置 (= **案 (b) 確定**、 39th session user 判断 gate)

現 IRQ handler 構造で、 active 段階 fade 処理 `irq_fade_*` (= standalone_test.s L501-530) は song dispatch `pmdneo_song_main` (= L542) **より前** に実行される (= Annex A literal)。

- **ADPCM-A** は master volume register (= port B reg `0x01`、 6ch 共通 total level) を持ち、 これは per-ch volume register (= reg `0x08`+ch、 `adpcma_volume_hook` 経由) と独立で note dispatch / volume hook が再 write しない。 IRQ で fade 値を master reg `0x01` へ直接 write しても上書きされない (= 現 active fade が ADPCM-A で機能する理由)。
- **ADPCM-B** は reg `0x1B` (= total level) が唯一の volume control で、 `adpcmb_volume_hook` が MML V/v コマンド時にこれを再 write する (= ADPCM-A のような独立 master を持たない)。 fade を reg `0x1B` へ直接 write すると fade 中の V コマンドが上書きする。
- **FM/SSG** は master volume register を持たず、 note dispatch / volume hook が per-note・per-V-cmd に FM operator TL register / SSG channel volume register を再 write する。 fade 値を直接 write しても dispatch / volume hook で上書きされる。

→ FM/SSG の fade 適用位置は次の 2 案。

| 案 | 内容 | trade-off |
|---|---|---|
| **案 (a)** | fade 値を song dispatch **後** (= `pmdneo_song_main` return 後) に write = 「last write wins」 | 既存 volume hook 不可触、 ただし post-dispatch FM TL write routine が必要で per-ch/per-op 処理量増 |
| **案 (b)** | fade attenuation factor を volume hook 内で volume 計算に **混ぜる** (= dispatch 時適用) | per-op TL 直接 ramp 不要、 ただし volume hook touch が必要 |

**ground truth** (= Annex D literal): PMD V4.8s / PMDDotNET は `fadeout_volume` (= 減衰量) を FM volume 計算 (= `fm_fade_calc` PMD.cs L6902-6914) / PSG volume 計算 (= `psg_fade_calc` PMD.cs L7106-7112) に **乗算 factor として混ぜる**。 = 本家流儀は案 (b)。 案 (a) は PMDNEO 独自の単純化経路。

#### 論点 A 確定 = 案 (b) (= 39th session user 判断 gate)

案 (a)/(b) を β 着手前に Codex layer 2 壁打ち (= 8 観点比較) にかけ、 Codex layer 2 approve (= 案 (b) 推奨)。 user 判断 gate = **案 (b) 確定**。

確定理由 (= user literal):

1. PMD V4.8s / PMDDotNET の fadeout 流儀に近い (= Annex D、 `fadeout_volume` を volume 計算に乗算 factor 混入)
2. FM/SSG の note dispatch と post-write が競合しない (= 案 (a) の同 tick 二重 write を回避)
3. ADR-0049 mute semantics の safe-state を壊しにくい (= mute は dispatch 側抑止で fade volume hook 混入と自然分離)
4. register trace gate が素直になる (= §決定 7 gate 2/3 採用案分岐の案 (b) 側と整合)
5. cmd 0x04 即時 silence を byte-identical 不可触にしやすい

chip 別 fade 経路 = **ADPCM-A** は独立 master volume register reg `0x01` を `pmdneo_v2_fade_level` 派生値で直接 ramp (= 案 (b) の volume hook 混入対象外、 独立 master を持つため)。 **ADPCM-B/FM/SSG** は volume hook (`adpcmb_volume_hook`/`fm_volume_hook`/`psg_volume_hook`) に fade factor を乗算混入する案 (b) 経路 (= ADPCM-B は独立 master を持たず reg `0x1B` が `adpcmb_volume_hook` 書込の唯一の volume control、 FM/SSG は master register 自体なし)。

#### β 実装境界 (= 案 (b) 確定 + Codex layer 2 壁打ち must-fix 2 反映)

β sub-sprint (= fade decay path 実装) の touch 範囲を次の 4 点に限定する。

| 対象 | 内容 |
|---|---|
| fade factor ramp | `pmdneo_v2_fade_*` attenuation factor field を IRQ tick 毎に単調 ramp (= §決定 4 論点 B、 free region 配置) |
| FM/SSG volume write path | FM operator TL / SSG channel volume の write path に fade factor を乗算混入 (= 案 (b)、 PMD 本家 `fm_fade_calc`/`psg_fade_calc` 流儀) |
| ADPCM-A master volume write | ADPCM-A master volume reg `0x01` (= 6ch 共通 total level) の段階減衰 write (= 現 active fade `irq_fade_*` 経路の拡張、 `pmdneo_v2_fade_level` 派生値) |
| ADPCM-B volume hook 経路 | ADPCM-B reg `0x1B` は `adpcmb_volume_hook` が唯一書く volume control。 fade は `adpcmb_volume_hook` への fade factor 注入 + fade step での hook 再適用で扱う (= 直接 master write ではない、 V コマンドとの競合回避、 案 (b) 統一) |
| `IRQ.inc` `snd_command_04_fade_out` | **byte-identical gate 対象として不可触** (= L84-111、 §決定 8 + verify gate 6) |

β は上記 4 点に touch を限定する。 cmd 0x04 即時 silence 経路の semantics 変更 / MML `fade_set` stub 現役化 / 軸 G・軸 C・rhythm routine touch は β でも行わない (= 決定 6 scope-out 維持)。

### 決定 4: 設計核心論点 B = SRAM field 配置

既存 `driver_fade_*` field は `standalone_test.s` L10-13 で 0xF819-0xF81C に配置される (= Annex F-2 literal)。

| field | addr | 意味 |
|---|---|---|
| `driver_fade_state` | 0xF819 | 1 byte: 0=no fade / 1=in progress |
| `driver_fade_counter` | 0xF81A | 1 byte: IRQ step counter |
| `driver_fade_master` | 0xF81B | 1 byte: ADPCM-A master vol shadow |
| `driver_fade_speed` | 0xF81C | 1 byte (default 16, range 0-255) |

driver_state region (= 0xF810-0xF81F、 16 byte) の空きは **0xF81D 1 byte のみ** (= 0xF81E `driver_loop_cycle` / 0xF81F `driver_song_id` 既存使用)。 part_workarea は 0xF820 開始 (= 0xF820-0xFD1F、 1280 byte)。

→ fade-out semantic 拡張で必要になる新規 field (= chip 別 fade shadow / FM・SSG fade attenuation factor 等、 採用案により点数変動) は **free region 0xFD39-0xFFBF** (= 647 byte、 Annex F-2 literal) に `pmdneo_v2_fade_*` prefix で配置する (= ADR-0045 §J-4-2 PartWork/driver_state 拡張 placement 規律 + `pmdneo_v2_*` prefix 命名規約と整合)。 実 allocation の確定は α 完了後の β 実装 sprint で行う。

WORKAREA.inc 同期方針 = active driver `standalone_test.s` 内 `.equ` 追加のみ。 legacy `WORKAREA.inc` (= PMD_Z80.inc 系 driver の workarea 定義) は **touch しない** (= memory `project_pmdneo_driver_two_paths_discovery.md` の driver 二系統分離維持、 active 本線 standalone_test.s のみ対象)。

### 決定 5: 設計核心論点 C = register preservation 契約

IRQ handler body (= `.org 0x0100` irq_handler_body) は AF/BC/DE/HL のみ push/pop する (= standalone_test.s L476-480、 Annex A literal)。 song dispatch `pmdneo_song_main` は IX を part workarea pointer として使用する。

→ fade routine を `.org 0x0610` セクション (= 制約のない最後の .org セクション、 決定 8 + Annex F-3) に配置し IRQ handler body から `call` する場合、 fade routine が IX/IY register を使うなら **IRQ handler body から call する前に push/pop を追加する** 必要がある。

ADR-0050 に fade routine の **「破壊 register 一覧」 を literal 記録** する (= β 実装 sprint で fade routine 確定時に Annex 追記)。 verify gate 5 (= register preservation) で IRQ 前後の register (= IX/IY 含む) 不変 or 明示 save/restore を確認する。

### 決定 6: scope-in / scope-out / non-goal

#### scope-in (= sprint 6 で扱う)

- **楽曲全体 fade-out** = active 段階 fade を ADPCM-A 限定減衰から FM 6ch + SSG 3ch + ADPCM-A + ADPCM-B の全 chip 段階減衰へ semantic 拡張
- fade 開始 (= NMI cmd 6) → IRQ tick 毎の段階減衰 → 完全 silence で全 chip keyoff
- chip 別 fade strategy (= ADPCM-A は独立 master volume register reg `0x01` 直接 ramp 経路、 ADPCM-B/FM/SSG は決定 3 論点 A 案 (b) の volume hook factor 混入経路)
- 案 1 = active 段階 fade 経路 (= `nmi_cmd_6_fade_start` + `irq_fade_*`) の拡張
- PMD V4.8s / PMDDotNET fadeout 構造 (= `fadeout_speed`/`fadeout_volume`/`fadeout_flag`/`fade_stop_flag`) の調査結果を本 ADR-0050 Annex D に literal 記録

#### scope-out (= 別 ADR / 別軸 / future sprint)

- **cmd 0x04 即時 silence 経路の semantics 変更** = `IRQ.inc` `snd_command_04_fade_out` は不可触保持 (= 決定 8、 verify gate 6 で byte-identical 確認)
- **MML `fade_set` stub の現役化** = PMD V4.8s 由来 MML `F` コマンド (= bytecode 0xD2) handler の実装は軸 F / 後続 sprint。 本 sprint 6 は NMI cmd 6 経路のみ扱う
- **fade-in** (= 段階増音、 PMD V4.8s `fadeout_speed` bit 7 経路) = 別 sprint。 本 sprint 6 は fade-out のみ
- **legacy PMD_Z80.inc / IRQ.inc 系 driver への fade 実装** = active driver `standalone_test.s` のみが対象
- **audio gate 主導の完了判定** = fade-out semantics は register trace primary gate で verify する (= 決定 7)。 audio gate は本 sprint 6 の完了判定には用いない

#### non-goal (= 軸 B sprint 6 として目指さない)

- 軸 G ADR-0048 / 軸 C ADR-0043 / rhythm ADR-0026〜0031 routine の modify (= 完全不可触、 並設 only or 本体直接 call only)
- mute semantics (= ADR-0049、 実装 sprint 5、 完了済)
- FM/SSG driver フルスクラッチ本体 (= 実装 sprint 1 = δ-1 以降)

### 決定 7: verify gate (= register trace primary gate、 10 gate)

fade-out semantics は **register trace primary gate** で verify する (= memory `feedback_refactor_gate_register_trace_not_wav.md`、 audio gate ではなく driver behavior verify)。 δ sub-sprint で次の **10 gate** を verify script (= `src/test-fixtures/axis-b/verify-fadeout-semantics.sh` 想定) に確立する。

| # | gate | 期待 |
|---|---|---|
| 1 | fade 開始 | NMI cmd 6 で `driver_fade_state=1` + master/counter init register/memory write |
| 2 | per-tick 段階減衰 (= 案 (b) 確定) | **ADPCM-A** = master volume register reg `0x01` が fade step 毎に減衰 write + 単調変化。 **ADPCM-B/FM/SSG** = volume hook (`adpcmb_volume_hook`/`fm_volume_hook`/`psg_volume_hook`) が `pmdneo_v2_fade_level` factor を乗算混入し、 fade step での hook 再適用で減衰 register write 発生 + `pmdneo_v2_fade_level` factor 単調変化 (= z80-mem-trace) |
| 3 | fade 値が dispatch raw 値に上書きされない (= 案 (b) 確定) | dispatch 時の volume hook (`adpcmb_volume_hook`/`fm_volume_hook`/`psg_volume_hook`) の volume register write 値が `pmdneo_v2_fade_level` factor 適用後値であり、 raw note volume ではない (= ymfm-trace。 案 (b) は volume hook 自体に factor を混入するため dispatch 経路と fade 経路が同一 source-of-truth、 上書き競合が原理的に発生しない) |
| 4 | 完全 silence | fade 減衰完了 (= 全 chip volume 0 到達) で全 chip keyoff register write 発生 |
| 5 | register preservation | fade routine call 前後で IRQ handler body の register (= IX/IY 含む) 不変 or 明示 save/restore |
| 6 | cmd 0x04 即時 silence 不変 | `IRQ.inc` `snd_command_04_fade_out` (= L84-111) が **byte-identical 必須**。 cmd 0x04 を変更する必要が生じた場合、 それ自体が must-fix escalate (= user 判断、 scope-out 違反 risk) |
| 7 | mute semantics regression | ADR-0049 `src/test-fixtures/axis-b/verify-mute-semantics.sh` 7 gate 全 PASS (= mute 経路への退行なし) |
| 8 | baseline regression | ADR-0049 Annex F-4 literal の既存 verify script 9 件 (= Annex F-4 literal 固定) 実行 + 全 PASS (= fade 未使用 path の baseline 保護) |
| 9 | `.org` overflow / section overlap | production build `.lst` で fade routine が `.org` 境界と overlap なし + fade fixture 機械語が production build に生成なし (= 38th session 軸 B sprint 5 β `.org` silent overlap finding 再発防止) |
| 10 | SRAM placement | 新規 `pmdneo_v2_fade_*` field が (a) 0xFD39-0xFFBF free region 内、 (b) part_workarea (0xF820-0xFD1F) / driver_state (0xF810-0xF81F) / 既存 field と非 overlap、 (c) `pmdneo_v2_*` prefix 命名規約遵守、 (d) legacy `WORKAREA.inc` drift なし (= touch されていない)。 build `.lst` + `.equ` 一覧 + git diff で確認 |

#### 案 (b) 確定に伴う trace 期待値 3 件 (= 39th session Codex layer 2 壁打ち nice-to-have 反映)

論点 A 案 (b) 確定により、 verify gate 2/3 (= 採用案分岐の案 (b) 側) で次の 3 点を register/memory trace で確認する。

1. **`pmdneo_v2_fade_*` factor の単調変化** = fade 進行中、 attenuation factor field が IRQ tick 毎に単調変化する (= z80-mem-trace、 増減方向は β 実装の factor encoding で確定)
2. **dispatch volume write が fade 後の値** = note dispatch 発生 tick の FM TL / SSG volume register write 値が raw note volume ではなく fade factor 適用後の値である (= ymfm-trace、 案 (b) の volume hook 混入が効いている証跡)
3. **mute 中 part へ fade 由来 volume write が出ない** = ADR-0049 mute 適用中の part に対し、 fade による volume register write が発生しない (= mute は dispatch 側抑止であり、 案 (b) の volume hook 混入は mute された part の dispatch 自体が起きないため fade volume write も出ない = mute と fade の自然分離の証跡)

audio gate は本 sprint 6 の完了判定には用いない (= 決定 6 scope-out)。 ただし δ or ε で「FM/SSG/ADPCM-A/B が同時に自然に減衰しているか」 の聴感確認を user が希望する場合のみ audio gate を 1 回 option 化できる。 その場合は期待音 8 軸詳細記述 (= 個数 / 時刻 / 経路 / sample / 期待音 / pass-fail 判定点 / aesthetic scope-out / 何が同じで何が違うべきか) を義務とする。 audio gate 要否は α 完了時に確定する。

### 決定 8: cmd 0x04 不可触 + MML fade_set scope-out

- `IRQ.inc` `snd_command_04_fade_out` (= cmd 0x04 即時 silence) は **byte-identical 必須** (= 決定 7 gate 6)。 byte-identical 比較基点 = β 着手直前の `src/driver/IRQ.inc` L84-111 (= β 実装 sprint で current 行範囲を再確認し literal 固定)。 cmd 0x04 を変更する必要が生じた場合、 それ自体が must-fix escalate (= user 判断)。
- `PMD_Z80.inc` `fade_set` (= bytecode 0xD2、 MML `F` コマンド handler) は no-op stub のまま不可触 (= 現役化は scope-out、 決定 6)。
- fade routine は `.org 0x0610` セクション (= `standalone_test.s` 最後の .org セクション、 制約なし) の **末尾追記** で配置する。 0x0610 セクションには既存 routine (= `init_adpcmb_beat` 等) が存在するため、 既存 routine の後ろへの追記とする (= 既存 routine 不可触、 ADR-0049 β `pmdneo_mask_immediate_keyoff` 配置 pattern 踏襲)。 `.org 0x0100` IRQ handler body セクション (= 256 byte 上限) への routine 配置は overflow risk があるため行わない (= memory `feedback_org_section_overflow_silent_bug.md`)。

### 決定 9: ADR-0045 §J-4-6 文言の override 明示

ADR-0045 §J-4-6 の fade-out 実装 sprint 候補記述で verify gate 期待は「(2) IRQ tick 毎の段階減衰 (= TL or volume register write)」 と literal 化されている。 本 ADR-0050 決定 3 論点 A の採用案 (= 特に案 (b) volume hook factor 方式) では、 FM/SSG の fade は「IRQ tick 毎の register write」 ではなく「volume hook 経由の factor 適用」 として実現される場合がある。 この場合、 本 ADR-0050 §決定 7 gate 2 (= 採用案分岐) が ADR-0045 §J-4-6 の当該文言を **override** する。 ADR-0045 §J-4-6 は実装 sprint 起票前の bridging note であり、 本 ADR-0050 が fade-out semantics の確定設計文書である。 文言の不明確を残さないため、 本 §決定 9 で override 関係を明示する。

### 決定 10: doc-only filing 規律 (= 本 ADR-0050 起票 commit = α sub-sprint)

α sub-sprint (= 本 ADR-0050 起票) は **doc-only**。 次を遵守する。

- 変更 file = 本 ADR-0050 (= 新規) + `docs/parallel-axes-dashboard.md` (= 軸 B 行 + ADR 番号予約簿 + escalation 履歴 update) のみ
- driver / runtime / compiler / vendor / vromtool.py / verify script / verify fixture data 完全不変
- vendor wav 3 件 untracked retain (= commit 混入なし)
- 軸 G ADR-0048 Draft + ε partial complete + ζ 未着手 完全不可触
- ADR-0044 Accepted + F-2-A defer 維持、 ADR-0043 軸 C 完全不可触

### 決定 11: ADR-0041 §決定 4-2 Codex rescue 化 default 永続化継承

本 sprint 6 全 sub-sprint で ADR-0041 §決定 4-2 Codex rescue 化を継承する。 主軸の user 確認質問 (= driver / 実装 / 配置 / 即時 GO 判定 / ADR 大型更新) は user 確認の前に Codex layer 2 投入を default 化、 approve なら主軸自律進行、 revise なら修正再 review、 escalate なら user 上げ。 user 介入は escalate or 最終確認 (= PR merge / Accepted 移行判断 / 決定 3 論点 A の案 a/b 確定) のみ。 Codex layer 2 review 依頼時は commit 権限なしを prompt 冒頭で literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`、 38th session Codex 越権 commit finding 再発防止)。

## sub-sprint chain 進捗

| sub | 状態 | PR | Codex layer 2 review |
|---|---|---|---|
| α (= ground truth 調査 + ADR 起票) | **完了** (= 38th session、 PR #63 MERGED 2ab113f) + 論点 A 案 (b) 確定 (= 39th session user 判断 gate) | PR #63 | kickoff 計画 round 1-3 chain (= round 1 revise must-fix 4 + round 2 revise must-fix 2 → round 3 approve) + ADR-0050 起票 review approve (= must-fix 0) + 論点 A 8 観点壁打ち approve (= 案 (b) 推奨) |
| β (= fade decay path 実装 + driver-embedded fixture) | **進行中** (= 39th session、 案 (b) 確定 base) | 本 PR | β kickoff plan review (= 後続) |
| γ (= fade finish path 実装) | 未着手 | - | - |
| δ (= verify script 体系化 + 10 gate 完全化) | 未着手 | - | - |
| ε (= completion + Accepted 判断) | 未着手 | - | - |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: PMDNEO の音楽 driver に「楽曲全体が徐々に小さくなって消える」 fade-out 機能を、 正式な driver behavior として追加する設計を文書として固定する。

**前提**: 現状の PMDNEO の段階 fade は ADPCM-A (= 打楽器系) の音量しか下げず、 FM / SSG (= メロディ系) は下がらない。 また「fade」 を名乗る routine が 3 つあり、 NMI cmd 6 の段階 fade / cmd 0x04 の即時消音 / MML の no-op stub と全て意味が違う。 この差を整理して埋める。

**やったこと**: 現 PMDNEO の active 段階 fade 経路 (= `standalone_test.s`)、 cmd 0x04 即時 silence 経路 (= `IRQ.inc`)、 MML fade stub (= `PMD_Z80.inc`) を実 source で全数調査した。 PMD V4.8s 公式 source (= PMD.ASM) と PMDDotNET 移植版 (= PMD.cs) の fadeout 構造 (= `fadeout_speed`/`fadeout_volume`/`fadeout_flag`) を調査した。 これらを ADR-0050 として起票し、 5 段の sub-sprint (= α/β/γ/δ/ε) と verify gate 10 件、 設計核心 3 論点 (= A fade 適用位置 / B SRAM field 配置 / C register 保存契約) を定義した。

**結果**: fade-out semantics の設計が文書として固定された。 案 1 (= 現 active 段階 fade 経路を base に ADPCM-A 限定減衰を FM/SSG/ADPCM-B へ拡張) を第一候補とし、 cmd 0x04 即時 silence と MML fade stub 現役化は scope-out とした。

**解釈**: これは設計の起票であり、 fade-out の実装は完了していない。 後続の β/γ/δ で driver を改修し、 ε で完了判断する。 特に設計核心論点 A (= FM/SSG の fade をどこで適用するか) は β 着手前に Codex 壁打ち + user 判断で確定する。

**次**: β sub-sprint (= fade decay path 実装) 着手は ADR-0050 doc-only PR の MERGED + 論点 A の案確定後。

## Annex A: 現 PMDNEO active fade 経路 ground truth

現 PMDNEO active driver `src/driver/standalone_test.s` の段階 fade 機構を全数調査した。 行番号は 2026-05-20 時点。

### A-1: fade field 定義 (= L10-13)

```
.equ driver_fade_state,   0xF819  ; 1 byte: 0=no fade, 1=in progress
.equ driver_fade_counter, 0xF81A  ; 1 byte: IRQ step counter
.equ driver_fade_master,  0xF81B  ; 1 byte: ADPCM-A master vol shadow
.equ driver_fade_speed,   0xF81C  ; 1 byte (default 16, range 0-255)
```

**`driver_fade_master` の実際の意味** = `.equ` コメント literal「ADPCM-A master vol shadow」。 = ADPCM-A の master volume (= port B reg `0x01`) の shadow copy であり、 **楽曲全体の master volume ではない**。 「楽曲全体 fade master」 と誤読しないこと。

### A-2: fade speed init (= L286-287)

```
ld a, #16
ld (driver_fade_speed), a
```

fade speed 既定値 = 16 (= IRQ 16 tick 毎に 1 段減衰、 約 1 秒で fade 完了)。

### A-3: fade 開始 = `nmi_cmd_6_fade_start` (= L464-471)

NMI command 6 で fade 開始。

```
nmi_cmd_6_fade_start:
        ld   a, #0x3F
        ld   (driver_fade_master), a   ; master = 0x3F (= ADPCM-A 最大音量)
        xor  a
        ld   (driver_fade_counter), a  ; counter = 0
        ld   a, #1
        ld   (driver_fade_state), a    ; state = 1 (= in progress)
        jp   nmi_done
```

### A-4: IRQ tick fade 処理 = `irq_fade_*` (= L501-530、 `.org 0x0100` IRQ handler body 内)

IRQ handler body (= `.org 0x0100` irq_handler_body、 L475) は di + AF/BC/DE/HL push (= L476-480) で開始する。 fade 処理 `irq_fade_*` は song dispatch `pmdneo_song_main` (= L542) **より前** に実行される。

```
        ld   a, (driver_fade_state)
        or   a
        jp   z, irq_fade_done          ; fade 中でなければ skip
        ld   a, (driver_fade_counter)
        inc  a
        ld   hl, #driver_fade_speed
        cp   (hl)
        jp   c, irq_fade_save_counter  ; counter < speed なら counter 保存して done
        xor  a
        ld   (driver_fade_counter), a  ; counter reset
        ld   a, (driver_fade_master)
        or   a
        jp   z, irq_fade_finish        ; master == 0 なら finish
        dec  a
        ld   (driver_fade_master), a   ; master--
        ld   b, #0x01
        ld   c, a
        call ym2610_write_port_b       ; port B reg 0x01 (= ADPCM-A TL) <- master
        jp   irq_fade_done
irq_fade_save_counter:
        ld   (driver_fade_counter), a
        jp   irq_fade_done
irq_fade_finish:
        xor  a
        ld   (driver_fade_state), a    ; state = 0 (= fade 完了)
        ld   b, #0x00
        ld   c, #0xBF
        call ym2610_write_port_b       ; port B reg 0x00 <- 0xBF (= ADPCM-A 全 6ch dump)
irq_fade_done:
```

### A-5: A-1〜A-4 から確定する active fade 経路の特性

1. **対象 chip = ADPCM-A のみ** = `irq_fade_*` が write するのは port B reg `0x01` (= ADPCM-A total level) と reg `0x00` ← `0xBF` (= ADPCM-A dump bit 7 + 全 6ch bit `0x3F`) のみ。 FM operator TL / SSG channel volume / ADPCM-B level register への write は一切ない。
2. **減衰モデル** = `driver_fade_master` を 0x3F から 0 へ、 IRQ `driver_fade_speed` (= 16) tick 毎に 1 ずつ decrement し ADPCM-A TL register に直接 write。 master 0 到達で ADPCM-A 全 6ch keyoff。
3. **fade と song dispatch の順序** = `irq_fade_*` は IRQ handler body 内で `pmdneo_song_main` 呼出 (= L542) より前。 ADPCM-A master volume は note dispatch が再 write しないため、 IRQ 前半の fade write が上書きされない。 = ADPCM-A で fade が機能する構造的理由。
4. **IRQ handler body の register 保存** = di + AF/BC/DE/HL の push/pop のみ (= L476-480)。 IX/IY は保存しない。
5. **`driver_fade_state` の役割** = standalone_test.s 内では fade 進行 flag (= `irq_fade_*` の進行判定) のみ。 standalone_test.s の song dispatch gate は `driver_song_ready` (= L532) で行われ、 `driver_fade_state` では gate しない (= legacy `pmd_z80_main` の `driver_fade_state` 経由 song 停止とは別、 Annex C-2 参照)。

## Annex B: cmd 0x04 即時 silence 経路 ground truth

`src/driver/IRQ.inc` `snd_command_04_fade_out` (= L84-111) を調査した。

```
snd_command_04_fade_out::
        ;; SubF-1 minimum fade: immediately silence supported chips and stop song.
        ld   b, #REG_SSG_A_VOLUME
        ld   c, #0x00
        call ym2610_write_port_a       ; SSG A volume <- 0
        ld   b, #REG_SSG_B_VOLUME
        call ym2610_write_port_a       ; SSG B volume <- 0
        ld   b, #REG_SSG_C_VOLUME
        call ym2610_write_port_a       ; SSG C volume <- 0
        ld   b, #0
        call pmdneo_fm_keyoff          ; FM ch 0
        ... (ch 1-5)
        call adpcmb_keyoff             ; ADPCM-B keyoff
        ld   a, #1
        ld   (driver_fade_state), a
        ret
```

### B-1: cmd 0x04 経路の特性

1. **即時 silence** = SSG A/B/C volume を 0 に即時 set + FM ch 0-5 を即時 keyoff + ADPCM-B を即時 keyoff。 段階減衰 (= per-tick fade) ではない。
2. **段階 fade との別 layer** = cmd 0x04 は「今鳴っている音を即座に全部止める」。 active 段階 fade (= Annex A) は「時間経過で徐々に小さくする」。 両者は別 semantics layer であり、 混同しない。
3. **dispatch 機構の違い** = cmd 0x04 は標準 nullsound `cmd_jmptable` の 0x04 entry (= IRQ.inc L45) 経由。 active 段階 fade の NMI cmd 6 (= standalone_test.s の NMI dispatch L309-310) とは別の dispatch 機構。
4. **本 sprint 6 での扱い** = scope-out (= 決定 6)。 verify gate 6 で byte-identical を必須確認 (= 決定 7/8)。

## Annex C: PMD_Z80.inc legacy MML fade_set ground truth

`src/driver/PMD_Z80.inc` の MML fade コマンド経路を調査した。

### C-1: `fade_set` = no-op stub (= L2080-2082)

```
fade_set:
        call pmdneo_part_fetch_byte
        ret
```

MML bytecode dispatch table (= L1642 / L1728) で `0xD2` に `fade_set` が配線される。 `fade_set` は MML data 中の fade コマンド arg byte を 1 個読む (= `pmdneo_part_fetch_byte`) だけで何もしない **no-op stub**。 PMD V4.8s 由来 MML `F` コマンドは PMDNEO で未実装。

### C-2: `driver_fade_state` の legacy 側参照

`PMD_Z80.inc` の `pmd_z80_main` (= L125-128) は `driver_fade_state` を参照し、 非 0 なら song dispatch を即 return で停止する。

```
;; SubF-1: fade command stops song dispatch immediately.
ld   a, (driver_fade_state)
or   a
ret  nz
```

= legacy `pmd_z80_main` 経路では `driver_fade_state` が song 停止 gate を兼ねる。 ただし本 sprint 6 の対象 active driver `standalone_test.s` の song dispatch は `pmdneo_song_main` (= 別 routine) であり、 `driver_fade_state` で song を停止しない (= Annex A-5-5)。 legacy `pmd_z80_main` 経路は scope-out (= 決定 6 = active driver standalone_test.s のみ対象)。

## Annex D: PMD V4.8s / PMDDotNET fadeout source ground truth

PMD V4.8s 公式 source `vendor/pmd48s/source/pmd48s/PMD.ASM` (= Shift-JIS、 M.Kajihara 作) と PMDDotNET 移植版 `vendor/PMDDotNET/PMDDotNETDriver/PMD.cs` + `PW.cs` の fadeout 機構を全数調査した。 PMD.ASM 行番号は iconv UTF-8 変換後。

### D-1: fadeout 3 + 1 field 構造 (= PW.cs L220/L221/L249/L268)

| field | PW.cs | 意味 |
|---|---|---|
| `fadeout_speed` | L220 | Fadeout 速度 (= Timer-A tick 毎の減衰量 increment、 bit 7 set = fade-in) |
| `fadeout_volume` | L221 | Fadeout 音量 (= 現在の減衰量、 0=無減衰 / 255=完全減衰) |
| `fade_stop_flag` | L249 | Fadeout 後 MSTOP するかどうかの flag |
| `fadeout_flag` | L268 | 内部から fout を呼び出した時 1 |

### D-2: `fadeout()` routine = Timer-A 駆動の減衰量 ramp (= PMD.cs L8481-8506 / PMD.ASM L5967-5994)

```
private void fadeout()  // FROM Timer-A
{
    if (pw.pause_flag == 1) goto fade_exit;   // pause 中は fade しない
    r.al = pw.fadeout_speed;
    if (r.al == 0) goto fade_exit;            // speed 0 = fade 未進行
    if ((r.al & 0x80) != 0) goto fade_in;     // bit 7 = fade-in 分岐
    r.carry = (r.al + pw.fadeout_volume > 0xff);
    r.al += pw.fadeout_volume;
    if (r.carry) goto fadeout_end;
    pw.fadeout_volume = r.al;                 // fadeout_volume += fadeout_speed
    return;
fadeout_end:
    pw.fadeout_volume = 255;                  // 完全減衰
    pw.fadeout_speed = 0;
    if (pw.fade_stop_flag != 1) goto fade_exit;
    pw.music_flag |= 2;                       // fade_stop_flag 立っていれば楽曲停止
}
```

= `fadeout_volume` を Timer-A tick 毎に `fadeout_speed` ずつ加算し、 0 → 255 へ ramp。 255 到達で `fadeout_speed=0` + `fade_stop_flag` が立っていれば `music_flag |= 2` で楽曲停止。

### D-3: FM fade 適用 = `fm_fade_calc()` (= PMD.cs L6902-6914 / PMD.ASM L4756-4763)

```
private void fm_fade_calc()
{
    r.al = pw.fadeout_volume;
    if (r.al >= 2)
    {
        r.al >>= 1;                  // 50% 下げれば充分
        r.al = (byte)-r.al;          // 負化 = (256 - fadeout_volume/2)
        r.ax = (ushort)(r.al * r.cl);// volume cl に乗算
        r.cl = r.ah;                 // 上位 byte = cl * (256-al) / 256
    }
    fmvs();                          // carrier に volume 設定
}
```

= FM の fade は `fadeout_volume` を半分にして負化し、 FM volume `cl` に **乗算 factor として混ぜる**。 FM operator TL を直接 ramp するのではなく、 volume 計算経路に減衰係数を挿入する方式。

### D-4: SSG/PSG fade 適用 = `psg_fade_calc` (= PMD.cs L7106-7112 / PMD.ASM L4921-4927)

```
psg_fade_calc:
    r.al = pw.fadeout_volume;
    if (r.al == 0) goto psg_env_calc;
    r.al = (byte)-r.al;              // 負化 = (256 - fadeout_volume)
    r.ax = (ushort)(r.al * r.dl);    // volume dl に乗算
    r.dl = r.ah;                     // 上位 byte = dl * (256-al) / 256
```

= SSG の fade も `fadeout_volume` を負化し、 SSG volume `dl` に **乗算 factor として混ぜる**。

### D-5: PMD V4.8s / PMDDotNET fadeout から導出される ground truth

1. PMD 本家 fade は `fadeout_volume` (= 減衰量 0-255) を Timer-A 駆動で ramp し、 各 chip の **volume 計算経路に乗算 factor として混ぜる** 方式。 chip ごとに master volume register を直接 ramp するのではない。
2. = 本 ADR-0050 §決定 3 論点 A の **案 (b) (= volume hook factor 方式) が PMD 本家流儀**。 案 (a) (= post-dispatch 直接 write) は PMDNEO 独自の単純化経路。
3. PMD 本家 fade は `fade_stop_flag` で「fade 完了時に楽曲を停止するか」 を制御する。 本 sprint 6 で同等の停止制御を持つかは β/γ 実装時に判断 (= 現 PMDNEO active fade は `irq_fade_finish` で ADPCM-A 全 ch dump のみ、 楽曲停止は別 = Annex A-5)。
4. PMD 本家には fade-in (= `fadeout_speed` bit 7) もあるが、 本 sprint 6 では fade-out のみ扱う (= 決定 6 scope-out)。

## Annex E: fade-out ground truth から導出される sprint 6 設計 finding

1. 現 PMDNEO active 段階 fade は ADPCM-A 限定 = 楽曲全体 fade-out には FM/SSG/ADPCM-B への減衰拡張が必須 (= 決定 6 scope-in)。
2. ADPCM-A は独立 master volume register reg `0x01` (= per-ch reg 0x08+ch と独立) を持つため減衰が単純 (= register 1 本を ramp)。 ADPCM-B は reg `0x1B` が唯一の volume control で `adpcmb_volume_hook` 書込のため独立 master を持たず、 FM/SSG は master register 自体がない。 ADPCM-B/FM/SSG は fade 適用位置が設計論点になる (= 決定 3 論点 A、 案 (b) volume hook factor 混入で確定)。
3. PMD 本家流儀は volume 計算経路への factor 混入 (= 案 (b))。 ただし PMDNEO は driver フルスクラッチであり、 既存 volume hook 構造との整合で案 (a) が単純な場合もある。 β 着手前に Codex 壁打ち + user 判断で確定する。
4. cmd 0x04 即時 silence は段階 fade とは別 layer。 sprint 6 は cmd 0x04 を不可触保持し、 verify gate で byte-identical 確認 (= 決定 7/8)。
5. fade routine の配置は `.org 0x0610` セクション末尾追記。 `.org 0x0100` IRQ handler body は 256 byte 上限で overflow risk (= 38th session β finding、 memory `feedback_org_section_overflow_silent_bug.md`)。

## Annex F: verify gate 詳細 + SRAM map / baseline script 行番号 literal

### F-1: verify script 想定

δ sub-sprint で `src/test-fixtures/axis-b/verify-fadeout-semantics.sh` (想定) に 10 gate (= 決定 7) を体系化する。 ADR-0049 `verify-mute-semantics.sh` の verify script 構造 + build infra 切替 (= `TEST_MODE_FADE_FIXTURE` sed 切替) pattern を踏襲する。

### F-2: SRAM map 行番号 literal 固定 (= verify gate 10 照合基点)

`src/driver/standalone_test.s` (= 2026-05-20 時点):

| 領域 | addr 範囲 | source 行 |
|---|---|---|
| driver_state | 0xF810-0xF81F (= 16 byte) | L1-15 `.equ` 群 (= `driver_fade_*` は L10-13 = 0xF819-0xF81C) |
| part_workarea | 0xF820-0xFD1F (= 20 x 64 = 1280 byte) | L130-131 `.equ part_workarea, 0xF820` + comment |
| .PNE 観測 block | 0xFD20-0xFD38 | (= ADR-0022/0023 由来、 SRAM map comment L177-184) |
| **free region** | **0xFD39-0xFFBF** (= 647 byte) | SRAM map comment L184「0xFD39 - 0xFFBF free / 後続 phase 用 (= 647 bytes 余裕)」 |

新規 `pmdneo_v2_fade_*` field は free region 0xFD39-0xFFBF へ配置 (= 決定 4)。 verify gate 10 はこの範囲を照合基点とする。

### F-3: fade routine 配置先 = `.org 0x0610` セクション

`standalone_test.s` の `.org` 一覧 = 0x0000 / 0x0038 / 0x0066 / 0x0100 / 0x0200 / 0x0220 / 0x0380 / 0x0600 / 0x0610。 `.org 0x0610` は最後の .org セクションで後続 .org 制約がなく、 routine 末尾追記に余裕がある (= ADR-0049 β で `pmdneo_mask_immediate_keyoff` を 0x0610 セクション末尾に配置した pattern と同)。 fade routine はこのセクション末尾に追記する (= 決定 8)。

### F-4: baseline regression script 一覧 (= verify gate 8、 ADR-0049 Annex F-4 literal 転記)

verify gate 8 (= baseline regression) は ADR-0049 Annex F-4 で literal 固定された既存 verify script 9 件を実行し全 PASS を確認する。 `src/test-fixtures/` 配下:

1. `step5/verify-l-q-tutti-gamma.sh`
2. `step5/verify-l-part-alpha-trace-gate.sh`
3. `step5/verify-l-part-beta-sample-lookup.sh`
4. `step5/verify-l-part-delta-volume-pan.sh`
5. `step5/verify-l-q-rhythm-song-integration.sh`
6. `step6/verify-silent-bcef-audio-isolation.sh`
7. `step11/verify-step11-multi-table.sh`
8. `step12/verify-step12-kr-differential.sh`
9. `step12/verify-step12-k-rhythm-trigger.sh`

ADR-0049 Annex F-4 の gate 6 flaky 対応 (= bounded retry 最大 3 attempt、 MAME trace timing flaky 許容) を本 sprint 6 verify gate 8 でも踏襲する。

### F-5: verify gate 数の sprint 5 との差

ADR-0049 (= sprint 5 mute) は 7 gate。 本 ADR-0050 (= sprint 6 fade-out) は 10 gate。 差分 = fade 適用位置論点 (= gate 2/3 の採用案分岐) + register preservation (= gate 5) + SRAM placement (= gate 10) の追加。 起票時 (= α) は 10 gate 定義。 δ 実装で gate 文言の精緻化が生じた場合は ADR-0050 Annex に literal 追記する (= ADR-0049 §決定 7 の δ 拡張 pattern 踏襲)。

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-20 | Draft 起票 (= 38th session 軸 B 実装 sprint 6 α) | fade-out ground truth 全数調査 (= Annex A/B/C/D) + 決定 1-11 + verify gate 10 件 + 設計核心 3 論点 A/B/C + sub-sprint 5 段構成、 doc-only filing (= ADR-0050 + dashboard のみ変更)、 kickoff 計画 Codex layer 2 round 1-3 chain approve 経由 + user GO 取得 |
| 2026-05-20 | 論点 A 案 (b) 確定 (= 39th session、 β sub-sprint base) | §決定 3 = 設計核心論点 A を案 (b) 確定 (= volume 計算混入方式、 Codex layer 2 8 観点壁打ち approve + user 判断 gate) + β 実装境界 4 点限定 + §決定 7 に案 (b) 確定 trace 期待値 3 件追記 + sub-sprint chain 進捗 α 完了/β 進行中 reflect、 β sub-sprint PR で driver 実装と同梱 |
