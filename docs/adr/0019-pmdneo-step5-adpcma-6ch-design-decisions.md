# ADR-0019: PMDNEO step 5 ADPCM-A 6ch 設計判断 (= 6 議題集約)

- 状態: Proposed
- 起票日: 2026-05-12
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 5 = ADPCM-A 6ch 本実装)、 ADR-0017 (= develop branch driver snapshot)、 ADR-0013/0014/0015 (= 改造 PMDDotNET 路線基盤)

## 背景

ADR-0016 step 4 完了 (= 2026-05-12 5th session、 commit `8e3dc59`) で ADPCM-B 本実装 + fixture-driven verify が成立した。 続く step 5 (= ADPCM-A 6ch 本実装) は ADR-0016 §決定 3 で骨格まで記録されているが、 実装着手前に次の論点を解決する必要がある:

- 既存 `src/driver/standalone_test.s` 内 Phase 9c 期遺産 `adpcma_*` 実装の処遇
- K part (= OPNA rhythm 互換) と L-Q part (= ADPCM-A 6ch 拡張) の境界
- sample addr 解決経路 (= build 時 embed vs `.PNE` parser)
- 実装 file 境界 (= `standalone_test.s` 内 vs `ADPCMA_DRV.inc` 復活)
- fixture-driven verify infra の拡張順序
- sub-sprint 分割と完了判定 precise 化

6th session (= 2026-05-12) でこれら 6 議題を壁打ち、 全件決定した。 本 ADR で正式に確定する。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 を遵守し、 step 5 着手前に 6 議題決定を ADR として独立起票する。

## 決定

### 決定 1: 既存 adpcma_* 実装の処遇 = retain + refactor

`src/driver/standalone_test.s` 内 Phase 9c 期遺産 `adpcma_*` 実装 (= `adpcma_init` / `adpcma_keyon_simple` / `adpcma_keyoff` / `adpcma_volume_hook` / `adpcma_keyon_hook` / `adpcma_keyoff_hook` / `adpcma_ch_bit_table` / `adpcma_pan_bits` / `adpcma_ch_sample_ptr_table` + 6 slot fixed sample bd/sd/hh/tom/rim/top) は **retain + refactor** で step 5 を進める。

**理由**:
- 動いている資産を捨てない (= 6th session までの規律踏襲、 V-1 / W-1 / W-3 trivial verify 補正の教訓)
- 既存 routine は YM2610 ADPCM-A register を正しく叩く hardware access layer として価値がある
- 廃棄して全面新規実装は trivial verify や未接続問題の再発リスク

**5 原則** (= step 5 内で遵守):

1. 既存 rhythm fixed mapping (= bd/sd/hh/tom/rim/top) は「legacy K/R compatibility path」 として隔離
2. 新規 L-Q dispatch / `.PNE` bank / sample allocation は step 5 本線として別実装
3. low-level ADPCM-A register write routine (= reg 0x10+ch 等) は共通化
4. sample ptr table は拡張可能な構造へ整理
5. K/R rhythm path と L-Q path は **上位 dispatch を分離、 下位 hardware routine を共有**

### 決定 2: K part rhythm 経路は scope-out

step 5 では **L-Q part (= ADPCM-A 6ch 拡張) のみ本線**、 K part (= OPNA rhythm 互換 part) は scope-out する。

**理由**:
- step 5 主目的 = `.MN` / L-Q part / ADPCM-A 6ch 拡張の成立
- K part は OPNA rhythm compatibility layer として重要だが、 L-Q 実装と同時進行は scope 膨張
- K/R command byte 互換 / mc compiler 側 K cmd / R 定義 / fixed sample mapping が絡む別軸

**運用**:
- 既存 K/R fixed mapping routine は **削除しない**
- ただし step 5 中は **必要以上に接続・修正しない** (= dispatch 現役化なし、 hook 接続は触らない)
- K/R は「legacy compat path retained but inactive / out of scope」 と code comment + 本 ADR で明記
- K/R 現役化は step 5 完了後の別 micro-sprint で起票候補

### 決定 3: sample addr 解決経路 = build 時 embed

step 5 では sample addr 解決を **build 時 embed (= `samples.inc` 拡張)** で進める。 `.PNE` parser は step 5 scope-out、 次 sprint へ分離。

**理由**:
- step 5 主目的 = L-Q part → ADPCM-A 6ch の fixture-driven verify
- `.PNE` full parse 同時実装は scope 膨張 + 検証軸増加
- build 時 embed なら step 4 と同じ作法 (= `samples.inc`) で sample addr 差分を機械的に検証可能
- 既存 `samples.inc` / `adpcma_ch_sample_ptr_table` 資産を活かせる

**運用**:
- step 5 実装では `samples.inc` に L-Q 用 sample を build 時 embed
- driver は L-Q index / part index → sample addr table で start/stop を解決
- `.PNE` parser は今回 scope-out
- 設計書 / 本 ADR に「`.PNE` parser は将来この sample addr table を生成・上書きする」 と明記 (= 接続点の予約)
- `#PNEFile` は compiler 側で既に受け取れるが (= ADR-0016 step 1 commit `45eebaf` で実装済)、 step 5 では driver parse 未実装

### 決定 4: 実装 file 境界 = 段階的

step 5 では L-Q dispatch / ADPCM-A 6ch driver code を **まず `src/driver/standalone_test.s` 内で実装**、 sub-sprint 末で `ADPCMA_DRV.inc` への refactor 移動を判断する。

**理由**:
- 最優先 = 「本当に build top に入り、 trace が目的 routine に到達する」 こと
- `standalone_test.s` 内実装なら trivial verify risk が最小 (= V-1 / W-1 / W-3 経験より)
- step 4 と同じ作法で小さく検証しながら進められる
- 最初から `ADPCMA_DRV.inc` に分離すると「include 済みと思い込む」 trivial verify を再発する risk

**運用**:
- まず `standalone_test.s` 内で L-Q dispatch / ADPCM-A 6ch / sample table を実装
- fixture-driven verify を成立させる
- step 5 完了間際に、 安定した routine だけ `ADPCMA_DRV.inc` へ refactor 移動するか判断
- 最終的に `ADPCMA_DRV.inc` へ移せるよう、 routine 境界は意識して書く (= 上位 dispatch / 下位 register 書込 / sample table 引き / hook の 4 層を明確化)
- refactor 移動は fixture-driven verify 完了後
- 移動時は register writes / ymfm-trace **primary gate** で確認

### 決定 5: fixture-driven verify infra = sample 切替差分を先

step 5 の fixture-driven verify は **sample 切替差分を先に確立** する。 1 ch (= L) で sample A / sample B fixture を 2 件作成、 ADPCM-A register trace primary gate。 ch 軸 verify は sample lookup 成立後に段階拡張。

**理由**:
- ADPCM-A 中核 = note → pitch ではなく sample addr table 経由で正しい sample を ch に割り当てる
- L ch だけで sample A / sample B 差分検証 = sample addr 解決経路を最小構成で確認可能
- 6 ch dispatch と sample switching を同時に見ると失敗時の原因候補が増加
- step 4-3-δ 同様、 最初は「1 軸だけ変える」 fixture-driven verify が安全
- 決定 3 (= build-time sample table) と整合

**運用**:
1. `src/test-fixtures/step5/l-part-sample-a.mml` 作成 (= L part minimum + sample A)
2. `src/test-fixtures/step5/l-part-sample-b.mml` 作成 (= L part minimum + sample B)
3. ymfm-trace で reg 0x10/0x18/0x20/0x28 (= start/stop LSB/MSB) の **start/stop addr 差分** 確認
4. key bit (= reg 0x00 bit) / volume (= reg 0x08+ch / reg 0x01) / pan (= reg 0x08+ch bit 6-7) は **同一であること** 確認
5. wav sha256 は参考扱い、 **primary gate = ADPCM-A register trace** (= `feedback_refactor_gate_register_trace_not_wav` 適用)
6. sample 切替差分が成立した後に L → M → ... → Q の ch 軸 verify へ段階拡張
7. `src/test-fixtures/step5/verify-l-part-sample-fixture-driven.sh` (= step 4-3-δ verify script 直系拡張、 自動 PASS 化)

### 決定 6: sub-sprint 分割 = 5 段階 α/β/γ/δ/ε

step 5 を **5 段階 α/β/γ/δ/ε** に分割する。 各 sub = 1 commit + 1 push、 primary gate は ADPCM-A register trace / ymfm-trace、 wav sha256 は timing-sensitive reference。

| sub | 内容 | 完了判定 |
|---|---|---|
| **α** | L part body → L ch ADPCM-A dispatch 接続 (= 1 sample fixed、 hook 接続 + cmd 経路成立) | trace で L part hook 到達 + ADPCM-A register write (= reg 0x10/0x18/0x20/0x28 + 0x00 key bit) を確認 |
| **β** | sample table lookup (= L ch only で sample A / sample B fixture 比較、 `samples.inc` 拡張) | start/stop addr 差分 (= reg 0x10/0x18/0x20/0x28) を register trace で確認、 key/vol/pan 同一、 verify script 自動 PASS |
| **γ** | ch 軸拡張 (= L → M → ... → Q、 6 ch 独立 dispatch) | key bit (= reg 0x00) + ch 別 register write を verify、 各 ch verify script 自動 PASS |
| **δ** | volume / pan hook 完成 (= V cmd 等 → reg 0x08+ch、 5 bit vol + bit 6-7 pan) | V cmd 経由 reg 0x08+ch 動作 fixture verify PASS |
| **ε** | step 5 完了判定統合 (= ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生 + audio gate) | ADR-0016 §決定 6 達成、 audio gate 通過 |

#### 共通規律 (= 全 sub-sprint 共通)

- 各 sub = **1 commit + 1 push** (= `feedback_post_commit_push_report_format` + `feedback_push_per_commit` 適用)
- **primary gate = ADPCM-A register trace / ymfm-trace** (= `feedback_refactor_gate_register_trace_not_wav` 適用)
- wav sha256 は **timing-sensitive reference** (= cycle 数増減で sample shift 許容)
- `.PNE` parser は scope-out (= 決定 3)、 build-time sample table で進める
- 各 commit 前に「平易な日本語で説明」 + user レビュー待ち (= `feedback_explain_in_plain_japanese_before_commit` 適用)
- driver / runtime layer touch commit = MAME 起動確認義務 (= CLAUDE.md §動作確認義務)

## scope-in / scope-out 明示

### scope-in (= step 5 本 sprint 範囲)

- L-Q part dispatch (= mc compiler `/B` 出力 `.MN` の L-Q body → driver ADPCM-A 6ch 経路)
- ADPCM-A 6ch register write (= reg 0x00/0x01/0x08-0x0D/0x10-0x15/0x18-0x1D/0x20-0x25/0x28-0x2D)
- sample addr table の build 時 embed (= `samples.inc` 拡張)
- 6 ch 独立 keyon / keyoff
- V cmd → reg 0x08+ch (= 5 bit vol + bit 6-7 pan)
- fixture-driven verify infra 拡張 (= sample 切替差分 → ch 軸拡張)
- ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生確認

### scope-out (= step 5 範囲外、 後続 sprint で扱う)

- `.PNE` format parser driver 実装 (= 接続点予約のみ、 設計書記述)
- K part (= OPNA rhythm 互換) 現役接続 (= 別 micro-sprint)
- `ADPCMA_DRV.inc` への routine refactor 移動 (= ε 完了後判断)
- WebApp WAV → `.PNE` 変換 UI
- ADPCM-A 内蔵 LFO / volume envelope (= chip 仕様外、 不要)

## 完了判定

- 本 ADR (= ADR-0019) 起票 + commit + push (= `wip-pmddotnet-opnb-extension` branch)
- step 5 α/β/γ/δ/ε 全 sub 完了 (= 各 sub 完了判定通過)
- ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生確認 (= ε 完了)

step 5 ε 完了時に本 ADR-0019 + ADR-0016 step 5 + ADR-0016 全体を Proposed → Accepted へ移行する (= ADR-0016 §完了判定 §決定 6)。

## 関連 memory

- `project_adr_0016_step5_design_decision_1_retain_refactor.md` (= 議題 1)
- `project_adr_0016_step5_design_decision_2_k_part_scope_out.md` (= 議題 2)
- `project_adr_0016_step5_design_decision_3_sample_addr_build_embed.md` (= 議題 3)
- `project_adr_0016_step5_design_decision_4_file_boundary_staged.md` (= 議題 4)
- `project_adr_0016_step5_design_decision_5_verify_sample_first.md` (= 議題 5)
- `project_adr_0016_step5_design_decision_6_sub_sprint_5_phase.md` (= 議題 6)
- `project_pmdneo_driver_two_paths_discovery.md` (= W-3 後 `standalone_test.s` 本線)
- `feedback_post_commit_push_report_format.md` / `feedback_push_per_commit.md` / `feedback_refactor_gate_register_trace_not_wav.md` / `feedback_explain_in_plain_japanese_before_commit.md`

## 関連 doc

- ADR-0016 §決定 3 step 5 (= 本 ADR が詳細展開)
- 設計書 §1-8-3 `.PNE` 仕様 (= 決定 3 接続点)
- 設計書 §2-4 Phase 3 (= PPZ → ADPCM-A 6ch 置換)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §「記憶は AI に、 判断は自分が握る」

## 次 sprint 候補

1. **step 5 α 着手** (= L part body → L ch ADPCM-A dispatch 接続、 1 commit + 1 push、 cmd dispatch + hook 接続 + trace gate 確立)
2. α 完了 → β 着手 (= sample table lookup、 `samples.inc` 拡張 + L sample A/B fixture)
3. β 完了 → γ 着手 (= ch 軸拡張、 L → L+M → L-Q 6 ch)
4. γ 完了 → δ 着手 (= vol/pan hook 完成)
5. δ 完了 → ε 着手 (= 楽曲 MAME 再生 + audio gate + ADR-0016/0019 Accepted 移行)
