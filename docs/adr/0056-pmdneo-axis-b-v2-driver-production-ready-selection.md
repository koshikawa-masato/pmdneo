# ADR-0056: PMDNEO 軸 B v2 driver production-ready 化 選定 ADR

- 状態: **Accepted** (= 2026-05-23 39th session、 軸 B v2 driver production-ready 化の選定/設計 ADR。 単一 doc-only 起票 (= 1 PR、 sub-sprint chain なし)、 Codex layer 2 全文一括 review approve + user 4 問判断 (= 切替方式 / production-ready gate / roadmap 順序 / ADR 構成) 経由で Accepted。 ADR-0045 §I-5-b が future へ defer した production-ready 化を、 実装前に ground truth 整理 + 切替方式 + gate + roadmap として文書固定する。 ADR-0056 は **「すぐ切り替える ADR」 ではなく「何が揃ったら切り替えてよいかを定義する ADR」**。 軸 B production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用)
- 著作権者: 越川将人
- 関連 ADR:
  - **ADR-0045** (= 軸 B Phase 2 FM/SSG driver フルスクラッチ 設計 ADR、 Accepted、 §I-5-b が「v2 driver production-ready 化 + 既存 cmd path からの switch は future 判断 / user 判断」 と defer。 本 ADR-0056 がその defer を選定 ADR として受ける)
  - **ADR-0049〜0055** (= 軸 B 実装 sprint chain 7 sprint = mute / fade-out / SSG tone-enable + δ-1 v2 entry / δ-2 SRAM placement / δ-3 F-2-B / δ-4 軸 C/G/rhythm 接続点、 全 Accepted。 **本 ADR で完全不可触保護**。 v2 driver foundation はこの 7 sprint で出揃った)
  - ADR-0043 (= 軸 C ADPCM-B、 Accepted、 **本 ADR で完全不可触**)
  - ADR-0048 (= 軸 G ADPCM 動的 sample 供給、 **Draft + ε partial complete + ζ 未着手、 本 ADR で完全不可触**)
  - ADR-0026〜0031 (= rhythm、 Accepted、 **本 ADR で完全不可触**)
  - ADR-0041 (= Claude Code 併走運用、 §決定 4-2 Codex rescue 化、 §決定 7 dashboard 一元管理)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 39th session 完全自走 model)
  - `feedback_metric_pass_is_not_aesthetic_pass.md` (= metric pass ≠ aesthetic pass、 production-ready 最終 gate = 越川氏 audition の根拠)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `feedback_parallelize_with_subagents_for_throughput.md` (= 本 ADR の現状 ground truth 調査は並列 sub-agent 3 体で実施)

## 背景 (= why now)

### 軸 B 実装 sprint chain 7 sprint 完了 base

39th session までに軸 B 実装 sprint chain (= ADR-0049 mute / ADR-0050 fade-out / ADR-0051 SSG tone-enable / ADR-0052 δ-1 v2 entry / ADR-0053 δ-2 SRAM placement / ADR-0054 δ-3 F-2-B / ADR-0055 δ-4 軸 C/G/rhythm 接続点 = 7 sprint) が全 Accepted となった。 v2 driver の foundation (= cmd 0x07 entry / SRAM sub-region / FM・SSG・F-2-B dispatcher / 軸 C/G/rhythm 接続点 + mute・fade-out・SSG tone-enable semantics) が出揃った。

### 次フェーズ = production-ready 化 (= ADR-0045 §I-5-b の future 判断)

ADR-0045 §I-5-b は「v2 driver が production-ready になるまで Phase 1 PoC base は並走、 switch 時期は実装 sprint で確定」 + 「user 切替判断は production-ready 後」 と literal 規定し、 production-ready 判定 gate + switch 時期を future / user 判断へ defer した。 軸 B 実装 sprint chain 完了後の次フェーズ = この production-ready 化。 これは「proof 経路を作る」 段階から「本番経路へ昇格する」 段階への移行であり、 切替方式と rollback 条件を実装前に文書固定する必要がある (= 39th session user 明示)。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 に従い、 本 ADR-0056 を **選定/設計 ADR** として起票し、 production-ready 化の ground truth / 切替方式 / gate / roadmap を文書固定する。

## 決定

### 決定 1: 現状 ground truth 整理 (= 並列 sub-agent 3 体 調査結果)

production-ready 化の前提として、 現状の driver 経路を ground truth として整理する (= 39th session 並列 sub-agent 3 体で `src/driver/standalone_test.s` + ADR-0045/0052〜0055 を調査)。 詳細は Annex A。

#### 決定 1-a: 「既存本番再生経路」 の ground truth 補正

39th session の調査前、 production-ready 化の切替元は「cmd 0x02 = 既存本番再生経路」 と認識されていたが、 driver source 調査で次が判明した (= ground truth 補正、 user preference ではなく事実訂正)。

- **cmd 0x02** (`nmi_cmd_2_play_song`) = **test fixture 経路**。 `TEST_MODE_CHORD` build flag で固定 note (= C4/E4/G4 等) を即 keyon するのみ。 MML song data parse なし。
- **実 MML 再生経路** = **cmd 0x05** (`nmi_cmd_5_init_mml_song`) + IRQ tick 駆動 `pmdneo_song_main` (= MML byte parser、 `TEST_MODE_CHORD == 5` build 限定)。
- = production-ready 化の「切替元 (= v2 が置き換える対象)」 は cmd 0x02 ではなく **cmd 0x05 + `pmdneo_song_main` MML parser 経路**。 本 ADR-0056 以降この補正 ground truth を用いる。

#### 決定 1-b: cmd 0x07 v2 path は trace-proof stub 段階

cmd 0x07 v2 path (`nmi_cmd_7_play_song_v2` → `pmdneo_v2_entry_skeleton` → FM/SSG/F-2-B/ADPCM-B/rhythm dispatcher) は **trace-proof stub 段階**。 各 dispatcher は register / SRAM marker の証跡を出すのみで、 実音再生・song data parse・周期再生 loop・IRQ tick 連携は全て未接続 (= one-shot)。 v2 は「単純な cmd 切替で本番化できる」 状態ではない。

#### 決定 1-c: production-ready gap = 7 実装要素 + 1 切替判断

v2 path が実音再生に足りない要素 (= ADR-0052〜0055 が「後続 future」 へ defer 済) = (1) FM fnum/block/TL/voice/pan (2) SSG tone period/fnum/noise/envelope (3) F-2-B 実音 individual mode (4) ADPCM-B 実 dispatch (= `adpcmb_keyon` call) (5) rhythm 実 dispatch (= `pmdneo_rhythm_event_trigger` call) (6) song data parse + v2 per-part dispatch loop (7) IRQ tick 駆動連携。 これに (8) production-ready switch 判断 を加えた 8 件が production-ready 化の全 gap。

### 決定 2: 切替方式 = 並走継続 + gate 全通過で切替 (= user 判断確定)

production-ready 化の切替方式を **既存実音経路と v2 経路の並走継続 + production-ready gate 全通過で切替** とする (= 39th session user 判断)。

- **既存実音経路** = cmd 0x05 + `pmdneo_song_main`。 **v2 proof 経路** = cmd 0x07 + `pmdneo_v2_entry_skeleton`。
- 当面は両経路を並走維持。 既存経路は byte-identical / trace-equivalent で保護。
- v2 は production-ready gate (= 決定 3) を全通過するまで本番切替しない。
- **rollback** = cmd 0x07 を使わないだけで成立 (= 既存経路不可触のため rollback 自明)。
- 機能単位の段階切替 (= FM から順次 v2 へ、 未実装部分は既存経路 fallback) は採らない (= v2 が現状 stub のため 2 経路の状態合成が過剰に複雑、 user 判断)。
- = ADR-0056 は **「すぐ切り替える ADR」 ではなく「何が揃ったら切り替えてよいかを定義する ADR」**。

### 決定 3: production-ready 判定 gate (= user 判断確定 + trace-equivalence 補足)

v2 driver の production-ready 判定 gate を次の 4 系統とする (= 39th session user 判断)。

| # | gate | 内容 |
|---|---|---|
| 1 | 実 MML 再生 | v2 path が実 MML song を parse + 周期再生できる (= one-shot stub ではなく song 進行) |
| 2 | 実音 register write trace | FM / SSG / ADPCM-B / rhythm の実音 register write が既存経路と **trace-equivalent** or 越川氏 audition approve |
| 3 | baseline regression | ADR-0049〜0055 の verify (= verify-mute/fadeout/ssg-tone-enable + verify-axis-b-v2-entry/sram-placement/f2b-integration/axis-connection) 全 PASS + 既存 cmd 0x05 経路 byte-identical |
| 4 | audition approve | 越川氏 audition approve (= 最終 gate、 必須) |

#### 決定 3-a: register trace は byte-identical ではなく trace-equivalence (= user 補足)

gate 2 の register trace 等価は **「完全 byte-identical」 ではなく、 意図した v2 差分を許容する trace-equivalence** として定義する (= 39th session user 補足)。 v2 は実装方式が既存経路と変わるため、 完全一致を要求すると production-ready gate が過剰に硬くなる。 trace-equivalence = 「意図した v2 差分 (= 例 = dispatch 順序 / 並設 routine 由来の write 順序差) を許容しつつ、 実音として等価な register state へ収束する」 こと。 意図しない差分 (= 音が変わる write の欠落 / 誤値) は不可。 trace-equivalence の literal 判定基準は後続 roadmap ADR の各 verify gate で確定する。

#### 決定 3-b: 最終 gate = 越川氏 audition approve 必須

gate 4 = 越川氏 audition approve を **production-ready 判定の最終 gate として必須** とする。 metric / register trace の機械的 pass は production-ready の必要条件だが十分条件ではない (= memory `feedback_metric_pass_is_not_aesthetic_pass.md`)。 v2 driver が本番再生経路へ昇格してよいかの最終判断は越川氏の audition。

### 決定 4: production-ready 化 roadmap (= 実装順序、 user 判断確定)

production-ready 化の実音再生要素実装 roadmap を次の順序とする (= 39th session user 判断)。 各段階は **別 ADR / 別 sprint** で起票し、 本 ADR-0056 は順序と gate のみ固定する (= 実装は ADR-0056 後続の各 roadmap ADR に分割)。

| 段 | 内容 | 主な gap 要素 |
|---|---|---|
| **roadmap ①** | FM/SSG 実音 = FM fnum/block/TL/voice/pan + SSG tone period の実音 register write 化 | 決定 1-c (1)(2)(3) |
| **roadmap ②** | song data parse + v2 per-part dispatch loop + IRQ tick 連携 = 実 MML song を時間進行で再生 | 決定 1-c (6)(7) |
| **roadmap ③** | ADPCM-B / rhythm 実 dispatch = marker stub から `adpcmb_keyon` / `pmdneo_rhythm_event_trigger` 実 call へ | 決定 1-c (4)(5) |
| **roadmap ④** | 軸 G dynamic supply 依存整理 = ADPCM-B 実 dispatch の土台ができてから ADR-0048 軸 G 依存を扱う | 軸 G ADR-0048 後続依存 |

roadmap 順序の根拠 = 依存順序。 ① 基本音源 register write を実音レベル化 → ② 実 MML song を時間進行で鳴らす → ③ marker stub から実 routine call → ④ ADPCM-B 実 dispatch の土台後に軸 G。 v2 が現状 one-shot proof のため、 ADPCM-B/rhythm/軸 G より先に FM/SSG 実音 + song loop を固める。 production-ready 判定 (= 決定 3 gate 全通過) は roadmap ①〜④ 完了後。

### 決定 5: ADR-0056 = 単一 doc-only 起票 (= user 判断確定)

ADR-0056 は **選定/設計 ADR** であり実装を伴わないため、 **単一 doc-only PR で起票** する (= 39th session user 判断)。 sub-sprint chain (= α/β/γ/δ/ε) は設けない。 Codex layer 2 review は全文一括。 production-ready 化の実装は ADR-0056 後続の各 roadmap ADR (= 決定 4 の roadmap ①〜④) に分割する。

### 決定 6: 不可触対象

次を完全不可触とする。

- **既存 cmd 0x02 fixture path** (`nmi_cmd_2_play_song`) + **cmd 0x05 + `pmdneo_song_main` 実 MML parser 経路** = 既存経路 byte-identical 保護 (= rollback 基盤、 切替前は壊さない)
- IRQ handler (`irq_handler_body`) / TIMER-B 設定 / 既存 NMI dispatch cmd 分岐
- ADR-0049〜0055 で追加した routine + SRAM field (= v2 driver foundation)
- 軸 C ADR-0043 ADPCM-B routine / 軸 G ADR-0048 routine + Draft 状態 + ε partial state / rhythm ADR-0026〜0031 routine
- vendor PMDDotNETCompiler 全部 (= F-2-A defer)
- ADR-0056 起票 = doc-only filing。 driver / runtime / compiler / vendor / verify script / fixture / spike 完全不変。 変更 file = 本 ADR-0056 + `docs/parallel-axes-dashboard.md` のみ。 vendor wav 3 件 + 未確認 untracked MML 3 件 untracked retain

### 決定 7: ADR-0041 §決定 4-2 Codex rescue 化 + 39th session 完全自走 model 継承

本 ADR-0056 起票 + 後続 roadmap ADR で ADR-0041 §決定 4-2 Codex rescue 化 + memory `feedback_codex_layer2_implementation_review_delegation.md` の 39th session 完全自走 model を継承する。 主軸の報告 / kickoff plan / commit GO / Accepted 移行判断は Codex layer 2 へ投入し、 approve なら主軸が自律完走、 escalate なら user 上げ。 production-ready 判定 gate (= 決定 3) の最終 audition は越川氏 (= user) 必須。 Codex layer 2 review 依頼時は commit 権限なしを literal 明示する (= memory `feedback_codex_layer2_review_no_commit_authority.md`)。

## Annex A: 現状 ground truth 詳細 (= 並列 sub-agent 3 体 調査)

### A-1: driver 3 経路の現状

| 経路 | entry | 実体 |
|---|---|---|
| cmd 0x02 | `nmi_cmd_2_play_song` | test fixture。 `TEST_MODE_CHORD` build flag で固定 note を即 keyon。 MML parse なし |
| cmd 0x05 + `pmdneo_song_main` | `nmi_cmd_5_init_mml_song` → IRQ tick 駆動 `pmdneo_song_main` | 実 MML byte parser 経路 (= `TEST_MODE_CHORD == 5` build 限定)。 song init → IRQ tick で MML parse + 周期再生。 = production-ready 化の切替元 |
| cmd 0x07 v2 | `nmi_cmd_7_play_song_v2` → `pmdneo_v2_entry_skeleton` | trace-proof stub。 5 dispatcher を 1 回 sequential call する one-shot。 実音再生・song parse・周期 loop・IRQ 連携なし |

### A-2: v2 dispatcher の現状 (= trace-proof stub)

| v2 dispatcher | 現状の write | 未実装 (= production-ready gap) |
|---|---|---|
| `pmdneo_v2_fm_dispatch` | FM keyon (reg 0x28) のみ | fnum/block (0xA0/0xA4) / TL (0x40系) / voice / pan |
| `pmdneo_v2_ssg_dispatch` | SSG volume (reg 0x08+ch) のみ | tone period (0x00-0x05) / fnum / noise / envelope |
| `pmdneo_v2_fm3ext_dispatch` | reg 0x27 bit 7 + ch3 op1-4 TL (trace proof dummy 値) | 実音 individual mode / fnum per-op 完全制御 |
| `pmdneo_v2_adpcmb_dispatch` | SRAM marker (0xFD3C) のみ | `adpcmb_keyon` 実 call (= 実 ADPCM-B dispatch) |
| `pmdneo_v2_rhythm_dispatch` | SRAM marker (0xFD3D) のみ | `pmdneo_rhythm_event_trigger` 実 call (= 実 rhythm dispatch) |
| (v2 main loop 全体) | one-shot (entry skeleton が dispatcher を 1 回 call) | song data parse / v2 per-part dispatch loop / IRQ tick 駆動連携 |

### A-3: ADR-0045 §I-5-b の defer literal

ADR-0045 §I-5-b は production-ready 判定 gate + switch 時期を **未定義 = future / user 判断へ defer**。 verify strategy は primary = register trace byte-identical (= 既存 path 不変) + baseline 保護 (= ADR-0023+ byte-identical) を規定。 本 ADR-0056 がこの defer を選定 ADR として受け、 決定 2/3/4 で切替方式・gate・roadmap を確定する (= 決定 3-a で「byte-identical」 を trace-equivalence へ緩和、 v2 実装方式差を許容)。

## Annex B: production-ready roadmap 後続 ADR 想定

決定 4 の roadmap ①〜④ は各々別 ADR / 別 sprint で起票する。 本 ADR-0056 は順序 + gate のみ固定し、 各 roadmap ADR の sub-sprint 構成 / verify gate 詳細はそれぞれの起票時に確定する。

| roadmap | 想定 ADR | scope | production-ready gate との関係 |
|---|---|---|---|
| ① FM/SSG 実音 | 後続 ADR (= 番号未予約) | v2 FM dispatcher に fnum/block/TL/voice/pan、 v2 SSG dispatcher に tone period 等の実音 register write を実装 | gate 2 (= FM/SSG 実音 register write trace-equivalent) の前提 |
| ② song parse + loop | 後続 ADR | v2 path に song data parse + v2 per-part dispatch loop + IRQ tick 駆動連携を実装 | gate 1 (= 実 MML parse + 周期再生) の前提 |
| ③ ADPCM-B/rhythm 実 dispatch | 後続 ADR | 接続点 stub (`pmdneo_v2_adpcmb_dispatch` / `pmdneo_v2_rhythm_dispatch`) を marker write から `adpcmb_keyon` / `pmdneo_rhythm_event_trigger` 実 call へ | gate 2 (= ADPCM-B/rhythm 実音) の前提 |
| ④ 軸 G dynamic supply 依存整理 | 後続 ADR (= ADR-0048 後続依存) | ADPCM-B 実 dispatch の土台後に軸 G ADPCM 動的供給依存を整理。 ADR-0048 Draft / ζ 状態に依存 | gate 2 (= 軸 G 経由 ADPCM-B) の前提 |
| (production-ready 判定) | 後続 ADR | roadmap ①〜④ 完了後、 決定 3 gate 4 系統全通過の確認 + 越川氏 audition + cmd 切替判断 | 決定 3 gate 全通過 = production-ready 達成 |

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

**やりたいこと**: 新ドライバ (= v2) を「本番の再生に使えるドライバ」 へ昇格させる準備として、 「何が揃ったら本番に切り替えてよいか」 を設計書で先に固定する。 ADR-0056 は切り替えそのものではなく、 切り替えの条件・順序・やり方を決める ADR。

**前提**: 軸 B の実装 sprint は 7 本 (= mute / fade-out / SSG tone-enable / v2 入口 / SRAM 配置 / F-2-B / 軸 C・G・rhythm 接続点) 全て完了済。 ただし新ドライバ (= cmd 0x07 経路) はまだ「証跡を出すだけのスタブ」 で、 実際の曲は鳴らせない。

**今回の調査でわかったこと**: ① 既存の本番再生は cmd 0x02 ではなく cmd 0x05 + `pmdneo_song_main` (= MML を解釈する経路)。 ② v2 経路は実音再生・曲データ解釈・周期再生・IRQ 連携が全て未実装。 = v2 を本番化するには大きな実装がまだ残っている。

**決めたこと**: ① 切替方式 = 既存経路と v2 経路を当面並走させ、 v2 が判定 gate を全部通るまで切り替えない (= rollback は cmd 0x07 を使わないだけ)。 ② 判定 gate = 実 MML 再生 + 実音 register write が既存経路と等価 (= 完全一致ではなく意図した差分を許す trace-equivalence) + 既存 verify 全 PASS + 越川氏の試聴 OK。 ③ 実装順序 = FM/SSG 実音 → 曲解釈 + 周期再生 → ADPCM-B/rhythm 実再生 → 軸 G。 ④ ADR-0056 自体は実装を伴わないので 1 本の doc-only PR で起票する。

**次**: ADR-0056 を doc-only で commit / PR / merge した後、 roadmap ① (= FM/SSG 実音) から後続 ADR を順次起票する。 v2 が「本番化できた」 と宣言するのは roadmap ①〜④ + 判定 gate 全通過 + 越川氏 audition の後。 それまでは「軸 B 完成」 とは言わない。

## 改訂履歴

| 日付 | 改訂 | 内容 |
|---|---|---|
| 2026-05-23 | 起票 + Accepted (= 39th session、 単一 doc-only) | 軸 B v2 driver production-ready 化の選定/設計 ADR を起票。 軸 B 実装 sprint chain 7 sprint (= ADR-0049〜0055) 全 Accepted 後の次フェーズとして、 ADR-0045 §I-5-b が future へ defer した production-ready 化を選定 ADR で受ける。 決定 1-7 = 現状 ground truth 整理 (= 並列 sub-agent 3 体調査 = cmd 0x02 fixture / cmd 0x05+pmdneo_song_main 実 MML 経路 / cmd 0x07 v2 trace-proof stub / gap 8 件、 cmd 0x02→0x05 ground truth 補正含む) + 切替方式 (= 並走継続 + gate 全通過で切替) + production-ready gate 4 系統 (= 実 MML 再生 / 実音 register trace-equivalence / baseline regression / 越川氏 audition 必須) + roadmap 順序 (= FM/SSG 実音 → song parse+loop → ADPCM-B/rhythm 実 dispatch → 軸 G) + ADR-0056 単一 doc-only 構成 + 不可触対象 + Codex rescue 化継承。 user 4 問判断 (= 切替方式 / gate / roadmap / ADR 構成) + Codex layer 2 全文一括 review approve 経由で Accepted。 doc-only filing (= ADR-0056 + dashboard のみ変更)。 ADR-0056 は選定 ADR であり production-ready 達成宣言ではない、 「軸 B 完成」 表現不使用。 実装は後続 roadmap ADR ①〜④ に分割 |
