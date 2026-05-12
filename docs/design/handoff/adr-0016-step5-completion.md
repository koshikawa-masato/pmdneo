# ADR-0016 step 5 completion — L-Q ADPCM-A 6 ch native path 完成

- 起票日: 2026-05-12 (= 6th session ε-c)
- 起票者: 越川将人 (M.Koshikawa) + Claude Code
- 関連: ADR-0016 (= 改造実装 sprint 作業計画)、 ADR-0019 (= step 5 設計判断 6 議題集約)

## 概要

ADR-0016 step 5 (= ADPCM-A 6 ch 本実装、 sub-sprint α/β/γ/δ/ε) を **完了**。 PMDNEO の **L-Q ADPCM-A 6 ch native path** が、 実装・trace・fixture・regression 全部揃った状態で成立。

ADR-0019 §完了判定「step 5 α/β/γ/δ/ε 全 sub 完了 + ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生確認」 を達成、 ADR-0016 全体も完了 (= step 1-5 全件)。

本 doc で step 5 全体 sum-up + future scope-out + 次 sprint 候補を整理。

## sub-sprint sum-up

### α: `.MN direct load` (= 4 commit)

| sub | commit | 内容 |
|---|---|---|
| α-1 | `3e01f48` | `.MN` layout ground truth + ROM embed byte-identical |
| α-2 | `ae6b419` | `.MN direct path` + L part dispatch (= 6 trace gate 手動確認) |
| α-3 | `e97210c` | verify script + handoff doc (= regression test 化) |
| α-3-fu | `335dec1` | audio gate finding 追記 (= FM 同居 audio confusion) |

成果:
- mc compiler `/B` 出力 `.MN` の byte layout 確定 (= Codex zero-trust verify)
- `pointer 解決規則 = pmddotnet_song + 1 + pointer_value` 固定
- L part body → ADPCM-A keyon chain 成立
- 6 段階 trace gate を verify script 自動化
- audio gate solo 化規律確立 (= memory `feedback_audio_gate_solo_isolation`)

### β: sample lookup (= 4 commit)

| sub | commit | 内容 |
|---|---|---|
| β-1 | `b3b1683` | sample A/B fixture + `.MN` diff fixture-driven |
| β-2a | `0029034` | PART_OFF_INSTRUMENT field + 0xFF cmd CHIP_TYPE=2 path |
| β-2b | `93bfc3d` | adpcma_keyon_simple voice index 引き refactor + reg 差分検出 |
| β-3 | `3fd418c` | verify script + handoff doc |

成果:
- MML `@<n>` → mc compiler emit `0xFF nn` 確定
- `@<n>` → comat_pcm → PART_OFF_INSTRUMENT → adpcma_keyon_simple → sample table lookup chain 成立
- 既存 `adpcma_ch_sample_ptr_table` (= K/R rhythm fixed mapping) を **voice index 引き** として再解釈 (= 議題 1 retain + refactor)
- sample A (= bd) / sample B (= sd) で reg 0x10/0x20 LSB 差分検出
- 範囲外 voice (= >= 6) keyon skip (= 誤 sample 鳴動防止)

### γ: L-Q 6 ch dispatch (= 2 commit)

| sub | commit | 内容 |
|---|---|---|
| γ-a | `cc51116` | routine 一般化 + M-Q dispatch 追加 |
| γ-b | `a4cbc99` | tutti fixture + 6 ch verify (= 4 観点全達成) |

成果:
- `pmdneo_mn_direct_load_l_part_addr` (= L 専用) を `pmdneo_mn_direct_load_lq_part_addr` (= L-Q 汎用) に一般化
- L-Q 全 6 part init を `.if PMDNEO_USE_PMDDOTNET == 1` 分岐に展開
- user 4 観点 全達成:
  - simultaneous keyon (= reg 0x00 で 6 ch 全 bit)
  - ch overlap (= 6 ch sample addr 全 unique)
  - register isolation (= 5 reg group × 6 ch)
  - workarea independence (= 6 ch PART_OFF_INSTRUMENT 独立)

### δ: volume/pan hook (= 2 commit、 重要 bug fix 含む)

| sub | commit | 内容 |
|---|---|---|
| δ-a | `d1ebdfc` | adpcma_volume_hook **bug fix** (= reg 0x10+ch → 0x08+ch) |
| δ-b | `9b3e4f8` | v0/v16 verify + handoff doc |

成果:
- **Phase 9c 期遺産 register 番号 bug を 5 sprint 越しで発見+ 修正**:
  - 旧: `reg 0x10+ch` (= start LSB、 sample addr 破壊 path)
  - 新: `reg 0x08+ch` (= per-ch vol+pan、 仕様正)
- `adpcma_pan_bits[ch]` 流用 (= 議題 1 retain、 新規 table 追加なし)
- v cmd 0..16 → V(1) table → /8 → 5 bit vol → reg 0x08+ch mapping 確定
- δ-b で 2 fixture (= v0/v16) 差分検出 + reg 0x10 不破壊 verify

### ε: 統合 + 完了 (= 3 commit、 本 commit 含む)

| sub | commit | 内容 |
|---|---|---|
| ε-a | `f2383e0` | L-Q rhythm song 統合 fixture |
| ε-b | `19ad60c` | integration verify script (= 6 段階 gate) |
| ε-c (= 本 commit) | (本 commit) | step 5 全体 handoff + ADR-0016/0019 Accepted 移行 |

成果:
- 「単発 fixture」 から「楽曲 fixture」 への移行
- α/β/γ/δ chain 全部を 1 fixture / 1 verify script で **統合動作確認**
- 総 keyon 39 件 (= 8+8+16+4+2+1 件) = MML リズムパターンが driver で正確に dispatch
- step 5 全体完了 + ADR-0016 / ADR-0019 status Proposed → Accepted

## 議題 1-6 達成状況 (= ADR-0019 §決定 1-6)

| 議題 | 内容 | 達成 |
|---|---|---|
| 1 | retain + refactor (= 既存 adpcma_* 実装) | ✅ pan_bits / sample_ptr_table 流用、 hook 経路再利用 |
| 2 | K part scope-out (= L-Q のみ本線) | ✅ K rhythm 別経路 (= rhythm_main 空 stub) 維持、 副作用なし |
| 3 | sample addr build 時 embed (= .PNE parser 次 sprint) | ✅ samples.inc 構造不変、 voice → sample mapping 既存 table 再利用 |
| 4 | 段階的 file 境界 (= standalone_test.s 内で進め) | ✅ 全 sub-sprint standalone_test.s 内、 ADPCMA_DRV.inc 移動は次 sprint |
| 5 | fixture-driven verify (= sample 切替差分先) | ✅ α→β→γ→δ→ε で順次拡張、 各 sub-sprint で fixture + verify |
| 6 | sub-sprint α/β/γ/δ/ε 5 段階 | ✅ 全 sub 完了 (= 計 14 commit) |

## ADR-0016 全体完了 (= step 1-5)

| step | status | 内容 |
|---|---|---|
| step 1 | ✅ 完了 (= 4th session) | mc compiler 改造 (= /B + L-Q + .MN + #PNEFile) |
| step 2 | ✅ scope-out 内吸収 | /N vs /B byte-identical verify (= step 3 で吸収) |
| step 3 | ✅ 完了 (= step 4/5 で吸収) | driver 既存 .M 再生 verify |
| step 4 | ✅ 完了 (= 5th session、 4-3-δ で fixture-driven) | ADPCM-B 本実装 (= SubE) |
| step 5 | ✅ 完了 (= 6th session、 本 doc) | ADPCM-A 6 ch 本実装 |

ADR-0016 §完了判定:
- step 1-5 全件完了 ✅
- ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生確認 ✅ (= ε-a/ε-b で確認)

→ **ADR-0016 全体完了**

## Phase 進捗 (= CLAUDE.md §開発フェーズ)

- **Phase 1 完了**: PoC (= ROM ビルド + MAME 再生確認、 step 3 で達成)
- **Phase 2 完了**: ベースライン driver の FM/SSG/ADPCM-B 部分 (= step 3/4 で達成)
- **Phase 3 driver 部分完了**: ADPCM-A 6 ch driver + `.MN` 出力対応 mc compiler (= **step 5 で達成**)

Phase 3 残作業 (= 別 sprint):
- `.PNE` parser driver 実装
- WebApp WAV → `.PNE` 変換 UI
- WebApp 最小骨格 (= MML エディタ + ビルド + プレビュー)

## driver / build infra final state

### driver (= src/driver/standalone_test.s)

step 5 改修により以下が成立:
- `pmdneo_mn_direct_load_lq_part_addr` (= L-Q 汎用 .MN parser)
- L-Q part init `.if PMDNEO_USE_PMDDOTNET == 1` 分岐 (= 6 part × dispatch)
- `comat_pcm` (= L-Q part 0xFF cmd path、 voice idx 保存)
- `PART_OFF_INSTRUMENT` field (= offset 31、 voice idx 保管)
- `adpcma_keyon_simple` voice index 引き refactor
- `adpcma_volume_hook` bug fix (= reg 0x10 → 0x08)

### build infra (= scripts/build-poc.sh)

不変。 `PMDDOTNET_MML` + `PMDDOTNET_MODE=B` + `PMDNEO_USE_PMDDOTNET=1` で L-Q ADPCM-A 楽曲 build 可能。

### fixture + verify (= src/test-fixtures/step5/)

7 fixture + 5 verify script:

| ファイル | 用途 |
|---|---|
| `l-part-minimum.mml` | α-1 baseline (= L only) |
| `l-part-sample-a.mml` | β-1 sample A (= @0) |
| `l-part-sample-b.mml` | β-1 sample B (= @1) |
| `l-q-tutti.mml` | γ-b 6 ch tutti |
| `l-part-volume-low.mml` | δ-b v0 |
| `l-part-volume-high.mml` | δ-b v16 |
| `l-q-rhythm-song.mml` | ε-a 統合楽曲 |
| `verify-l-part-alpha-trace-gate.sh` | α-3 verify |
| `verify-l-part-beta-sample-lookup.sh` | β-3 verify |
| `verify-l-q-tutti-gamma.sh` | γ-b verify |
| `verify-l-part-delta-volume-pan.sh` | δ-b verify |
| `verify-l-q-rhythm-song-integration.sh` | ε-b 統合 verify |

## future scope-out / next sprint 候補

step 5 で **意図的に touch しなかった範囲** (= 別 sprint 起票候補):

### 1. K/R rhythm compatibility (= micro-sprint 候補)

- 議題 2 で scope-out 確定 (= L-Q 成立後の別 micro-sprint)
- 既存 `adpcma_keyon_hook` / fixed sample mapping 残存、 接続なし
- 起票判断: step 5 完了後 user 判断

### 2. `.PNE` parser driver 実装 (= 次 sprint 候補)

- 議題 3 で scope-out (= build 時 embed のみ、 .PNE は次 sprint)
- 既存 `pne_filename_adr` (= mc compiler 出力) を driver で読む経路追加
- WAV → `.PNE` 変換 UI (= WebApp 連携)

### 3. ADPCMA_DRV.inc への routine 移動 (= refactor sprint 候補)

- 議題 4 段階的 file 境界、 ε 完了後 refactor 判断
- 現状 standalone_test.s 内に L-Q 関連 routine 集約
- routine 境界は意識して書かれている (= 上位 dispatch / 下位 register 書込 / sample table 引き / hook の 4 層)
- 移動時は ymfm-trace primary gate (= refactor 規律)

### 4. solo 化 audio gate (= optional micro-sprint)

- α-3 audio finding で「FM 同居 dominant」 問題判明
- 「対象音源 solo 化」 規律確立 (= memory `feedback_audio_gate_solo_isolation`)
- audible 化作業時に「test01/test02 empty MML 差替」 or 「FM mute cmd」 検討

### 5. PMDNEO.s nullsound integration (= 大規模 sprint 候補)

- ADR-0014 §C 凍結 (= standalone_test.s 本線、 W-3 確定)
- 将来的に nullsound 経路完成で `PMDNEO.s` build top 復活可能性
- step 5 完了の現状では `standalone_test.s` 本線で十分

### 6. ADPCM-A vol/pan 拡張 (= 別設計 sprint)

- 現状 `adpcma_pan_bits` (= K/R rhythm 用 fixed pan、 ch ごと別) を流用
- 「user 制御可能 pan cmd」 追加は別 sprint
- master attenuation / PCMVolume Extend / PPZ-like scaling も別 sprint

### 7. 残った微細課題

- `adpcma_keyon_simple` 内 `or PART_OFF_VOLUME(ix)` (= raw V or pan_bits) で keyon 時 6 bit vol、 hook 経由は /8 で 5 bit vol → **vol scale 不整合** (= chip 仕様内、 audible 影響軽微)。 別 sprint で「vol scale 統一」 候補

## ADR-0016 / ADR-0019 status 移行

本 commit で:
- ADR-0016 状態: Proposed → **Accepted**
- ADR-0019 状態: Proposed → **Accepted**

これに伴い ADR-0016 §決定 3 step 5 末尾に完了注記追加 + ADR-0019 §状態 + §完了判定 更新。

## memory 更新

- 新規: `project_pmdneo_step5_complete.md` (= step 5 完了 + ADR-0016 全体完了の象徴)
- 更新: `MEMORY.md` index

## 6th session sum-up

PMDNEO 6th session 中に達成:
- step 5 設計判断 6 議題 (= ADR-0019 起票)
- step 5 sub-sprint α/β/γ/δ/ε 全 14 commit
- 既存 Phase 9c 期 bug 5 件発見+ 修正 (= adpcma_volume_hook reg 番号、 hex dump 読み違い、 etc.)
- driver / build infra / fixture / verify / handoff doc 統合
- ADR-0016 全体完了 + Phase 3 driver 部分完了

開発フェーズ転換 (= memory `pmdneo-phase-transition-verification-driven-2026-05-12`):
- 「とりあえず動かす」 → 「検証可能な進め方を固定しながら機能を増やす」
- regression test 規律確立 (= 各 sub-sprint で verify script + handoff doc)

## 関連

- **commit chain (= 全 14 commit)**:
  - α: 3e01f48 / ae6b419 / e97210c / 335dec1
  - β: b3b1683 / 0029034 / 93bfc3d / 3fd418c
  - γ: cc51116 / a4cbc99
  - δ: d1ebdfc / 9b3e4f8
  - ε: f2383e0 / 19ad60c / [本 commit]
- **ADR**: ADR-0016 (= Accepted)、 ADR-0019 (= Accepted)
- **handoff** (= step 5 全 doc):
  - alpha-1-mn-layout.md
  - alpha-2-trace-gate-findings.md
  - beta-1-sample-fixture-findings.md
  - beta-2-sample-lookup-findings.md
  - gamma-l-q-6ch-findings.md
  - delta-volume-pan-findings.md
  - **step5-completion.md** (= 本 doc)
- **memory**:
  - 議題 1-6: project_adr_0016_step5_design_decision_*.md
  - α-1 ground truth: project_adr_0016_step5_alpha_prep_mn_direct_path.md
  - audio gate 規律: feedback_audio_gate_solo_isolation.md
  - phase 転換: project_pmdneo_phase_transition_verification_driven.md
  - 新規 step 5 完了: project_pmdneo_step5_complete.md

step 5 完了 → ADR-0016 全体完了 → Phase 3 driver 部分完了 → 次 sprint は別 ADR 起票候補。
