# ADR-0016: PMDNEO 改造実装 sprint 作業計画

- 状態: Proposed
- 起票日: 2026-05-12
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0013 (= 同 .M 2 経路比較 路線への切替)、 ADR-0014 (= ADR-0006 sprint 成果のカテゴリ別判断 + PMDPPZ 流儀発見)、 ADR-0015 (= PMDDotNET 改造 技術調査 sprint、 全 5 軸完了 Accepted)、 ADR-0017 (= develop driver snapshot + ADR-0015 前提整理 + path A 採択)

## 背景

ADR-0015 §軸 5 完了 (= 2026-05-12、 commit `c3f8798`) で改造実装 sprint の前提が全て確定した:

- 路線: ADR-0017 §決定 4 path A 採択 (= 改造 PMDDotNET 路線、 develop driver 継続発展)
- 着手順序: (B) mc compiler 先 + driver 後 (= 判断 5-1)
- 段階的検証: 5 step (= 判断 5-2、 step 1-2 mc compiler sprint + step 3-5 driver sprint)
- 改造規模: 約 335-660 行 + 既存 `PMD_Z80.inc` 追加分
- 改修対象: (driver) `ADPCMA_DRV.inc` + `ADPCMB_DRV.inc` + `PMD_Z80.inc` 追加 / (mc compiler) `mml_seg.cs` + `mc.cs` + `m_seg.cs`
- 不要対象: (driver) `standalone_test.s` (= ADR-0014 凍結) / (mc compiler) `voice_seg.cs` (= 判断 3、 OPNA 完全互換)

本 ADR は上記引継項目を base に、 改造実装 sprint の具体的作業計画 + 完了判定基準 + 依存関係を確定する。

## 決定

### 決定 1: sprint 構成

改造実装 sprint は **mc compiler sprint (= step 1-2) + driver sprint (= step 3-5) の 2 段構成**。 各 step は順次進行 (= 並行不可)、 前 step の完了判定通過後に次 step 着手。

### 決定 2: mc compiler sprint (= step 1-2) 作業計画

#### step 1: mc compiler 改造

- **作業対象**: `vendor/PMDDotNET/PMDDotNETCompiler/` 内 3 file
  - `mml_seg.cs` (= 30-50 行): 新規 `opnb_flg` flag + `pne_filename` field + usage message 更新 (= `/B` 追加)
  - `mc.cs` (= 150-250 行): 新規 CLI option `/B` 認識 (= `ReadOption()`、 507 行) + m_start bit 2 追加 (= 816 行) + partcheck で L-Q 受付 + `/N` 時 L-Q 警告 + 新規 `#PNEFile` handler + Part L-Q MML body 出力経路 + 後方拡張領域出力 + 出力拡張子 `.MN` 切替 (= 591/593 行)
  - `m_seg.cs` (= 5-10 行): 新規 `extended_data_adr` field + `pne_filename_adr` field
- **作業内容**: ADR-0015 §軸 4 完了 §step 4-E 改造箇所 list に従って実装
- **完了判定**: 既存 `/N` 出力 (= 全 voice-test 28 entry MML 等) が改造後も byte 単位で温存されること

##### step 1 完了 (= 2026-05-12 4th session)

step 1 は以下 commit で完了 (= `wip-pmddotnet-opnb-extension` branch、 全件 push 済):

| commit | 内容 |
|---|---|
| `25bde49` | commit 0 — vendor/PMDDotNET initial import + .gitignore 更新 |
| `4b2e6b1` | commit 1 — mml_seg.cs + m_seg.cs field 追加 |
| `d034eff` | commit 2 — /B option 認識 + m_start bit 2 + .MN 切替 (暫定) |
| `2719544` | commit 3 — partcheck で L-Q 受付 + /N 時 警告 skip |
| `01e347a` | commit 4a — ADPCM-A 使用判定 logic + 最優先制約 (.M 維持) 達成 |
| `1a7e59e` | commit 4b — Pass1 で /B 時の L-Q 検出 + adpcma_used 発火経路 |
| `45eebaf` | commit 4c — #PNEFile macro 認識経路 (filename 格納のみ) |
| `0675b71` | commit 4c-fixup — pnefile_set で CR (0x0D) trim 追加 |
| `0b12f0a` | commit 4e — cloop iteration + L-Q body + 後方拡張領域 + header 拡張 一括 |
| `2dabd22` | 設計書 §4-2-1 注記追加 — .mn header 28 byte 固定化 + shift 量整理 |

**完了判定の達成状況**:
- ✅ /N output byte 単位温存 (= voice-test 28 entry sha256 完全一致、 改造前 baseline と byte 一致)
- ✅ ADR-0013 D1 路線基盤 (= /B + ADPCM-A 未使用 = /N と byte 完全一致) を 4a/4b 時点で確立
- ✅ ADPCM-A 使用経路 (= `.MN` 出力、 後方拡張領域、 L-Q body、 #PNEFile 連動) 完成形を 4e で達成
- ✅ 設計書 §4-2 / §4-3 完全整合 (= header 28 byte 固定化、 m_buf[26..27] = extended_data_adr 常成立)
- ✅ /N と /B 両 baseline byte-identical で driver 不可侵を保証

**step 1 範囲外 (= 別 sprint で対応予定)**:
- `lc.cs` (= 長さ計算) を L-Q 拡張する作業 (= 「Part L Length : N」 log 補完、 driver 動作には影響なし)
- step 2 (= /N vs /B 前半 bit-by-bit 一致) の verify script 化 (= 28 entry の永続検証 infra 構築)

#### step 2: 同 MML 前半 bit-by-bit 一致 verify

- **作業対象**: 既存 voice-test 28 entry MML (= ADPCM-A 不使用、 main branch 固定資産) を `/N` `/B` 両 compile
- **作業内容**:
  - 28 entry を `/N` で compile → 既存 .M output
  - 28 entry を `/B` で compile → 新 .M output (= m_start bit 2 = 0、 前半同一想定)
  - byte 単位比較 script で前 26 byte header + part body + prgdat 一致を機械的に検証
  - verify 結果記録
- **完了判定**: 全 28 entry で `/N` と `/B` の前半 byte 単位完全一致 (= ADR-0013 D1 路線基盤の establish)

### 決定 3: driver sprint (= step 3-5) 作業計画

#### step 3: driver 既存 .M 再生 verify

- **作業対象**: `src/driver/PMDNEO.s` (= 現状 `sample_m.s` 組み込み経路) + `src/driver/PMD_Z80.inc` (= 動的 load 経路へ拡張)
- **作業内容**: mc compiler `/B` 出力 .M (= bit 2 = 0、 step 2 で生成) を ROM 焼込 → driver で再生
- **完了判定**: 既存 `sample_m.s` 経路と動的 load 経路で同一波形 (= MAME 録音 + RMS 一致 verify)

#### step 4: SubE 完成 (= ADPCM-B 本実装)

- **作業対象**: `src/driver/ADPCMB_DRV.inc` (= 50-100 行追加)
- **作業内容**: `adpcmb_volset` + `adpcmb_panset` + `adpcmb_setfreq` 実装 + ADPCM-B main loop integration
- **完了判定**: ADPCM-B 楽曲再生 + audio gate (= MAME 録音 + RMS / spectrum 検証) 通過

#### step 5: Phase 3 (= ADPCM-A 6ch 本実装)

- **作業対象**: `src/driver/ADPCMA_DRV.inc` (= 100-200 行) + `src/driver/PMDNEO.s` の `adpcma = 0` → `adpcma = 1` 切替
- **作業内容**: `adpcma_init` + `adpcma_keyon` + `adpcma_keyoff` + `adpcma_volset` + `adpcma_panset` + `adpcma_main` 実装
- **完了判定**: mc compiler `/B` + ADPCM-A 使用 MML → `.MN` 出力 (= m_start bit 2 = 1) → driver で再生 + audio gate 通過

#### step 3-5 補正注記 (= 2026-05-12 W-3、 driver 設計再評価後)

ADR-0016 step 3 sprint (= V-1 / W-1 / 4-2 / W-3 経路) で driver 設計の trivial verify を 3 重に検出、 build top と本線 driver の見直しが必要となった:

- **trivial verify 1 (= V-1 で検出、 6813d70 補正)**: 改修対象の `IRQ.inc` / `PMD_Z80.inc` / `ADPCMB_DRV.inc` が build top = `standalone_test.s` の時に **build に取り込まれていなかった**。 V-1 で build top を `PMDNEO.s` に切替えて補正。
- **trivial verify 2 (= W-1 で検出、 8fc326a 補正)**: `main.c` が `*REG_SOUND = 5` (= cmd 0x05 = `test_play_adpcmb_beat` 固定 beat、 nmi_cmd_5_adpcmb_beat) を発行していたため、 driver の cmd 0x02 = `snd_command_02_play_song` 経路に **1 度も到達していなかった**。 W-1 で cmd 0x02 発行に変更して補正。
- **trivial verify 3 (= W-3 で検出、 464cff1 補正)**: `PMDNEO.s` + `IRQ.inc` + `PMD_Z80.inc` の polling loop は `state_timer_tick_reached` を **nullsound 提供と仮定** したが、 nullsound.lib では未定義 (= Ref のみ)。 加えて `cmd_jmptable` で `nullsound module が cmd_jmptable を参照` する依存があり、 `PMDNEO.s` build top で nullsound integration が未完成と判明。 一方 `standalone_test.s` は nullsound-free PoC として独自 entrypoint + TIMER-B IRQ + NMI command dispatch + per-tick driver loop が成立していた。 W-3 で build top を `standalone_test.s` に戻して補正。

**W-3 後の更新方針**:

- step 3-5 の **作業対象 driver = `src/driver/standalone_test.s` 本線** (= ADR-0014 §C 注記更新、 ADR-0017 §決定 2 注記更新)
- step 3 完了判定「既存 `sample_m.s` 経路と動的 load 経路で同一波形」 は再評価必要 (= `standalone_test.s` 内に動的 load 経路を新規実装するか、 別経路を検討)
- step 4 / step 5 の作業対象 driver も `standalone_test.s` 内で進める (= `ADPCMB_DRV.inc` の routine は legacy retain、 `standalone_test.s` から call できる場合は再利用、 もしくは `standalone_test.s` 内に新規実装)
- `PMDNEO.s` + `IRQ.inc` + `PMD_Z80.inc` + 関連 .inc は **legacy retain** (= 機能凍結はしない、 ただし本 sprint の作業対象外)、 将来 nullsound integration sprint で完成させる予定

step 3 〜 step 5 完了判定 / 作業対象の詳細 redefine は別 sprint で対応 (= ADR-0019 等の起票候補)。

### 決定 4: 各 step 間の依存関係

```
step 1 (mc compiler 改造)
   ↓ (= 既存 /N 出力 byte 単位温存)
step 2 (前半 bit-by-bit 一致 verify)
   ↓ (= ADR-0013 D1 路線基盤 establish)
step 3 (driver 既存 .M 再生 verify)
   ↓ (= 動的 load 経路 establish)
step 4 (ADPCM-B 本実装、 SubE 完成)
   ↓ (= ADPCM-B 楽曲再生 verify)
step 5 (ADPCM-A 6ch 本実装、 Phase 3)
   ↓
[改造実装 sprint 完了]
```

並行不可。 前 step の完了判定通過後に次 step 着手。

### 決定 5: branch 戦略 + commit pacing

- **branch**: `wip-pmddotnet-opnb-extension` で全 5 step 進行 (= ADR-0014 §branch 戦略遵守、 develop merge は ADR-0016 完了時に user 判断)
- **commit pacing**: step 単位で commit + push + audio gate (= driver / runtime layer touch commit は MAME 起動確認義務、 CLAUDE.md §動作確認義務 遵守)
- 各 step 完了で memory `project_next_session_kickoff.md` 更新

### 決定 6: 完了判定 (= ADR-0016 全体)

step 5 完了 + ADPCM-A 6ch 使用 `.MN` 楽曲 1 つ以上が MAME で再生確認できれば、 改造実装 sprint 完了。

これにより:
- **Phase 2 完了** (= フルスクラッチ driver の FM/SSG + ADPCM-B、 CLAUDE.md §開発フェーズ Phase 2)
- **Phase 3 の driver / mc compiler 部分完了** (= ADPCM-A 6ch driver + .MN 出力対応 mc compiler)

残作業 (= .PNE 統合 / WebApp / IPL / リリース統合) は ADR-0016 範囲外、 別 sprint で進行。

## 完了判定

- 本 ADR (= ADR-0016) 起票 + commit + push (= `wip-pmddotnet-opnb-extension`)
- step 1-5 全件 完了 (= 各 step の完了判定通過)
- ADPCM-A 6ch 使用 `.MN` 楽曲 1 つ以上が MAME で再生確認

step 1-5 完了時は本 ADR-0016 の状態を Proposed → Accepted に移行する。

## 関連 memory

- `project_next_session_kickoff.md` (= 次 session 着手指示、 ADR-0016 起票後は本 ADR を base に進行)
- `project_pmdneo_develop_driver_snapshot.md` (= develop branch 9 file 詳細 snapshot)
- `project_adr_0013_0014_path_switch.md` (= 路線変更記録)
- `feedback_explain_in_plain_japanese_before_commit.md` (= commit 前 平易日本語報告規律)
- `feedback_branch_strategy.md` (= branch 規律)
- `project_mame_headless_recording_mode.md` (= MAME 録音 mode、 各 step audio gate で再利用)

## 次 sprint 候補

1. **step 1 着手** (= mc compiler 改造、 mml_seg.cs + mc.cs + m_seg.cs)
2. step 1 完了 → step 2 着手 (= 同 MML 前半 bit-by-bit 一致 verify)
3. step 2 完了 → driver sprint (= step 3-5) 着手

各 step の細部 (= 例「mc.cs 内の partcheck 改修 行範囲」 等) は step 着手時 sprint で具体化する。 ADR-0016 では作業計画の骨格までを記録する。
