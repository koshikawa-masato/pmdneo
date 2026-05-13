# ADR-0016 / ADR-0020 step 6 完了統合 handoff (= audio isolation infra 確立)

- 状態: **完了** (= 2026-05-13 7th session)
- 関連 ADR: ADR-0020 (= Accepted、 step 6 audio isolation 戦略)、 ADR-0016 (= Accepted、 改造実装 sprint 作業計画、 step 6 は ε-c 完了後の検証 infra 強化拡張 sprint)
- 関連 commit: `46d1228` (= ADR-0020 起票) / `6983234` (= step 6-a 実装) / 本 commit (= step 6 完了統合)

## 目的

step 5 ε-c (= 2026-05-12 6th session) で残った FM 同居 audio finding を解消し、 「trace gate (= 機械検証) だけでなく human listening gate (= 聴感検証) でも ADPCM-A native path を clean に確認できる」 状態を成立させる。 driver 機能拡張ではなく **検証 feedback loop の品質改善** sprint として位置付け。

## step 6 全体 sum-up

### 構成

step 6 = ADR-0020 で起票した audio isolation micro-sprint。 sub-sprint 構造:

| sub | 内容 | 結果 | commit |
|---|---|---|---|
| 起票 | ADR-0020 起票 (= silent-bcef fixture first choice + PMDNEO_MUTE_FM 条件付き留保) | ✅ Proposed → Accepted | `46d1228` |
| 6-a | silent-bcef fixture + 7 段階 verify script + handoff doc | ✅ trace gate 7/7 + audio gate user 試聴 OK | `6983234` |
| 完了統合 | step 6 完了統合 doc + ADR-0020 Accepted 移行 + ADR-0016 関連 ADR 追記 | ✅ 本 commit | (= 本 commit) |
| 6-b | PMDNEO_MUTE_FM driver flag | ⏸ 不要判定で scope-out 留保 (= 6-a で十分) | — |

### 完了判定達成状況 (= ADR-0020 §6-a 完了判定 7 項目)

| # | 項目 | 達成 |
|---|---|---|
| 1 | `src/test-fixtures/step6/silent-bcef.mml` 追加 | ✅ (= 6983234) |
| 2 | 6-a verify script で MML_INPUTS 差替経路成立 | ✅ (= 6983234) |
| 3 | trace 上で FM keyon (= reg 0x28) 0 件 | ✅ (= 6983234 verify run) |
| 4 | ADPCM-A L-Q reg write は ε-b verify 同等 PASS | ✅ (= gate 2-6 全 PASS、 39 keyon 件数 ε-b 完全一致) |
| 5 | MAME / wav で ADPCM-A L-Q 6 音 audible 確認 | ✅ (= user 試聴で「FM の音だけ消えて ADPCM-A シーケンスだけ」 確認) |
| 6 | 6-a handoff doc 作成 | ✅ (= `adr-0016-step6-a-silent-bcef.md`) |
| 7 | step 6 完了統合 handoff doc + ADR-0020 Accepted 移行 | ✅ (= 本 commit) |

→ 7/7 達成、 ADR-0020 Accepted 移行完了。

## 達成事項 (= step 6 全体)

### 1. driver 不変 audio isolation 成立

`src/driver/standalone_test.s` を始め driver source / build infra に変更を一切加えず、 `MML_INPUTS=silent-bcef.mml` env 差替のみで FM 同居 audio を完全解消。 ADR-0019 §決定 1 「retain + refactor」 規律と完全整合。

### 2. 7 段階 trace gate + human listening gate の両 gate 通過

- trace gate: ε-b 6 段階 (= workarea / sample addr / vol-pan / keyon / register isolation) + 新規 gate F (= FM keyon 0 件) で計 7 段階
- audio gate: user 実機試聴 (= afplay /tmp/pmdneo-trace/audio.wav) で「FM の音だけ消えて ADPCM-A シーケンスだけ」 を耳で確認
- 両 gate を別軸並走させる規律を verify script 内に明示 (= wav sha256 は reference、 primary gate は trace)

### 3. PMDNEO 二層構造の安定 (= legacy / native)

step 6 で「legacy layer」 と「native layer」 の二層が共存しつつ独立試聴可能になった:

**legacy layer**:
- 入口: `compile.py` + `MML_INPUTS` (= test01.mml / test02.mml / silent-bcef.mml 等)
- 中継: `song_data.inc` `song_table` (= A-Q + X/Y/Z)
- driver: `standalone_test.s` `load_song_part_addr` + `pmdneo5_init_part`
- chip: FM ch 1-6 / SSG / ADPCM-B / Rhythm

**native layer**:
- 入口: `.MN` binary (= `PMDDOTNET_MML` 経路 or `PMDNEO_M_RAW` 経路)
- 中継: `pmddotnet_song` `.incbin` + `extended_data_adr` table
- driver: `standalone_test.s` `pmdneo_mn_direct_load_lq_part_addr`
- chip: ADPCM-A 6 ch (= L-Q)

**isolation 機構**:
- silent-bcef.mml = legacy layer を完全 silent 化 (= FM keyon 0 件)
- `PMDDOTNET_MML` 経路 = native layer の楽曲 (= l-q-rhythm-song.mml 等)
- 並走 build で「native layer だけ聴ける」 状態を成立

### 4. FM coexist 規律の固定 (= 「bug ではなく retain + refactor の自然な結果」)

step 5 終盤で「FM が鳴る = regression?」 と疑いかけた経緯を踏まえ、 ADR-0020 §背景 で **FM coexist は driver bug でも regression でもない** と明文化:

- ADR-0019 §決定 1 (= retain + refactor) により、 legacy compile.py + song_table 経路は意図的に温存
- ADR-0019 §決定 4 (= 段階的 file 境界) で `.MN` direct path は legacy 経路と並存
- 結果として「compile.py + song_table legacy path」 と「.MN direct L-Q path」 が二系統並走で同時 dispatch される

future contributor が同じ誤解をしないよう ADR-0020 に整理を残置。

### 5. build-time fixture isolation 規律の確立

audio isolation 戦略として **build-time fixture isolation を runtime driver mute より優先** する規律を ADR-0020 + memory `feedback_audio_gate_solo_isolation.md` に固定。 優先順序:

1. build-time fixture isolation (= MML / asset 差替) — driver / build infra 不変、 risk 最小 ← **本 step 6-a で採用**
2. build-time config flag (= compile.py 等の上位 build tool option)
3. driver build flag (= .equ + .if、 sed pre-process) ← **6-b は scope-out 留保**
4. runtime mute hack — 最も risk 高、 通常 scope-out

### 6. verify infrastructure の進化

step 5 まで verify script は parser / lookup / register 中心だった。 step 6 で **human listening support** を verify script 内に組み込み (= 末尾に MAME / wav 試聴手順を表示)。 audio gate を機械検証と独立軸として明示的に運用する規律が verify infra に組み込まれた。

## driver / build infra final state (= step 6 完了時点)

### driver

step 5 ε-c から変更なし。 全機能 retain。

- `src/driver/standalone_test.s` (= 本線 driver、 3014 行、 step 5 ε-b から不変)
- `src/driver/ADPCMA_DRV.inc` / `ADPCMB_DRV.inc` / `KR_STUB.inc` 等 (= 全 retain)

### build infra

step 5 ε-c から変更なし。 既存 `MML_INPUTS` env var 経路 (= `scripts/build-poc.sh:91`) を利用。

- `scripts/build-poc.sh` (= 不変、 既存経路を利用)
- `src/tools/pmd-mml/compile.py` (= 不変)

### fixture

step 6 で新規追加:

- `src/test-fixtures/step6/silent-bcef.mml` (= 25 行、 6-a fixture)
- `src/test-fixtures/step6/verify-silent-bcef-audio-isolation.sh` (= 約 220 行、 7 段階 verify script)

### handoff doc

step 6 で新規追加:

- `docs/design/handoff/adr-0016-step6-a-silent-bcef.md` (= 6-a sum-up)
- `docs/design/handoff/adr-0016-step6-completion.md` (= 本 doc、 step 6 完了統合)

### ADR

- `docs/adr/0020-pmdneo-step6-audio-isolation-strategy.md` (= 新規起票 + Accepted 移行、 約 230 行)
- `docs/adr/0016-pmdneo-implementation-sprint-plan.md` (= 関連 ADR に ADR-0020 追記 + 次 sprint 候補 update)

## Phase 進捗

step 5 ε-c から変更なし (= step 6 は機能拡張ではなく検証 infra 強化):

- Phase 1 完了 (= PoC)
- Phase 2 完了 (= baseline driver FM/SSG/ADPCM-B)
- Phase 3 driver 部分完了 (= ADPCM-A 6 ch driver + `.MN` 出力対応 mc compiler + audio isolation infra)

Phase 3 残作業 (= 別 sprint):

- `.PNE` parser driver (= 次 sprint 最有力候補)
- WebApp WAV → `.PNE` 変換 UI
- WebApp 最小骨格

## 7th session sum-up

7th session の特徴:

1. **設計書ファースト規律の維持** — ADR-0020 を着手前に起票、 sprint 内容を文書として固定
2. **「動いているものを壊さない」 原則の徹底** — driver 不変 audio isolation、 6-b conditional reserve
3. **trace gate + audio gate 別軸並走** — wav sha256 を reference、 primary gate は register trace
4. **future contributor 防衛** — FM coexist が bug ではないことを ADR に固定、 build-time fixture 優先規律を memory 化

step 5 で確立した「検証可能な進め方を固定しながら機能を増やす」 phase transition (= memory `pmdneo-phase-transition-verification-driven-2026-05-12`) が step 6 で更に深化:

- step 5: 機能 (= ADPCM-A 6 ch native path) + 検証 infra (= fixture-driven verify) を同時に立てる
- step 6: 検証 infra (= audio isolation) を独立 sprint として整備、 機能は不変

→ 「検証 infra 自体を sprint として扱う」 段階に到達。

## 次 sprint 候補 (= 未消化 6 候補)

ADR-0019 ε-c handoff future scope-out 7 候補のうち、 step 6 で #4 (= solo 化 audio gate) を消化。 残 6 候補:

| # | 候補 | 規模 | 優先度 |
|---|---|---|---|
| A | `.PNE` parser driver 実装 | 大 | **最有力** (= Phase 3 driver 部分完了の残作業、 build-time embed → runtime resolution) |
| B | K/R rhythm compatibility 現役接続 | 小 (micro-sprint) | 中 (= ADR-0019 §決定 2 で起票候補と記載) |
| C | ADPCMA_DRV.inc routine refactor 移動 | 中 | 中 (= ε 完了後判断と ADR-0019 §決定 4 で書かれている) |
| D | PMDNEO.s + nullsound integration | 大 | 低 (= driver 二系統発見以降の積み残し) |
| E | ADPCM-A vol/pan 拡張 | 中 | 低 |
| F | vol scale 統一 (= adpcma_keyon_simple raw or 整理) | 小 | 低 |

### 推奨: 次 sprint = `.PNE` parser driver 実装 (= A)

理由:
- Phase 3 driver 部分完了 → Phase 3 残作業の中核
- step 5 §決定 3 で「接続点予約」 として `samples.inc` 拡張が将来 `.PNE` parser に置換される設計を明示
- step 6 で確立した二層構造 (= legacy / native) と整合
- audio isolation infra (= step 6) が PNE sample 切替 verify に再利用可能

着手前に独立 ADR (= 仮 ADR-0021) を起票して設計判断を固定する流れを推奨。 ADR-0019 / ADR-0020 と同じ作法。

## 関連 memory

- `project_pmdneo_step5_complete.md` (= step 5 ε-c 完了状態、 step 6 の起点)
- `project_pmdneo_step6_complete.md` (= 本 step 6 完了 memory)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定する規律、 step 6 で深化)
- `feedback_audio_gate_solo_isolation.md` (= audio gate 規律、 step 6-a で build-time fixture 優先規律を追記)
- `project_pmdneo_driver_two_paths_discovery.md` (= driver 二系統発見、 step 6 の legacy / native 二層構造の起源)

## 関連 doc

- ADR-0020 (= step 6 audio isolation 戦略、 Accepted)
- ADR-0016 (= 改造実装 sprint 作業計画、 step 6 は ε-c 完了後の拡張 sprint)
- ADR-0019 (= step 5 設計判断 6 議題、 step 6 の FM coexist 起源)
- `docs/design/handoff/adr-0016-step6-a-silent-bcef.md` (= 6-a sum-up)
- `docs/design/handoff/adr-0016-step5-completion.md` (= step 5 完了状態 + future scope-out 7 候補の起点)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止
