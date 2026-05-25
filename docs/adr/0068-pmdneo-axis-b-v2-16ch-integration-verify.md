# ADR-0068: PMDNEO 軸 B v2 driver 16 ch 統合 verify ADR (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目、 roadmap ⑤ 統合 verify 本体、 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較)

- 状態: **Draft** (= 2026-05-24 39th session、 ADR-0068 起票 doc-only PR1 + sub-sprint chain α/β/γ/δ/ε 起票、 起票 doc-only 1 PR (= ADR-0064 plan/実作業分離 pattern 整合)、 ADR-0067 同 chain pattern 継承、 Codex layer 2 plan review 4 round chain (= round 1-3 revise + round 4 approve)、 must-fix 計 7 件 (= build mode 分離 + allowed-touch 分類 + ε 解禁併記必須 + 「16 ch fixture 拡張完了」 併記 2 段化 + legacy MML candidate 修正 + path 修正 + ch coverage 表記修正) + nice-to-have 計 4 件 + latent-risk 計 3 件 全反映、 越権操作なし confirmed、 ADR-0064 §決定 3 sub-sprint plan literal 継承 + ADR-0067 fixture 拡張完了 milestone 前提)
- 起票日: 2026-05-24
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 ADR-0041 §決定 4-3 主軸 fallback default 規律)
- 関連 ADR:
  - **ADR-0067** (= 母 ADR、 「16 ch fixture 拡張完了」 milestone 達成 = Accepted、 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 1 本目、 16 ch trace-equivalence 前提作り完成、 本 ADR-0068 が 2 本目 = 統合 verify 本体)
  - **ADR-0064** (= plan ADR、 §決定 3 sub-sprint α/β/γ/δ/ε plan literal 継承元、 §決定 1 (a)(b)(c) 3 gate scope literal、 §決定 7 番号 chronology rationale literal)
  - **ADR-0063** (= 4 gate status partial、 §決定 1(b) 16 ch trace-equivalence ground truth)
  - **ADR-0056** (= production-ready 4 gate ground truth、 §決定 3-a trace-equivalence literal 継承)
  - **ADR-0058** (= roadmap ② v2 song parse、 ε `verify-axis-b-v2-song-playback.sh` 10 gate representative regression script)
  - **ADR-0059** (= roadmap ③ v2 ADPCM-B/rhythm dispatch、 ε `verify-axis-b-v2-roadmap3-dispatch.sh` 12 gate representative regression script)
  - **ADR-0057** (= roadmap ① v2 FM/SSG 実音、 `verify-axis-b-fm-ssg-real-sound.sh` 6 gate baseline)
  - **ADR-0048 ζ-ε** (= 軸 G dynamic supply 完成、 `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP` 既存 flag 流用継承)
  - **ADR-0006 §B** (= AES+ YM2610B 想定、 chip target 制約 = ym2610 FM A/D/F 非可聴 継承)
  - **ADR-0041** (= 併走運用、 Codex rescue 化規律 + 冒頭 6 件 literal 強調規律)
  - **ADR-0026 §決定 4** (= L ch (= ch 0) 暫定占有 scaffold、 ADPCM-A L ch 固定仕様由来、 ADR-0067 δ Annex δ literal 反映)
- 関連 memory:
  - `feedback_axis_design_adr_accepted_vs_implementation_completion.md` (= 設計 ADR Accepted ≠ 軸実装完了、 「軸 B 完成」 表現禁止)
  - `feedback_codex_layer2_implementation_review_delegation.md` (= Codex rescue 化 + 完全自走 model)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件 literal 強調)
  - `feedback_refactor_gate_register_trace_not_wav.md` (= register trace primary gate)
  - `project_pmdneo_adr_0067_initiated.md` (= ADR-0067 起票 + 完走 milestone 経緯)
  - `project_pmdneo_adr_0064_initiated.md` (= ADR-0064 plan ADR 起票 + §決定 3 sub-sprint plan literal)

## 背景 (= why now)

### ADR-0067 完走 = 「16 ch fixture 拡張完了」 milestone 達成 (= 併記必須)

ADR-0067 sub-sprint chain α/β/γ/δ/ε 全 完走 (= PR #128/#129/#130/#131/#132 全 merge、 7ac4ab7 集約 branch HEAD) で 16 ch fixture 拡張 + 機能 verify only 完了。 ただし併記必須 = 「roadmap ⑤ 統合 verify 未実装 (= ADR-0068 候補 future)」 + 「production-ready 全体達成ではない」 (= ADR-0067 §決定 6 literal)。

### roadmap ⑤ 統合 verify の本体 = ADR-0068 scope

ADR-0064 §決定 1 literal (= (a)(b)(c) 3 gate 統合 verify scope):
- (a) 実 MML 再生 統合 verify = v2 driver 経路 + cmd 0x05 経路 並走 trace capture
- (b) 全 16 ch trace-equivalence verify = FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6 同時 register write 比較
- (c) baseline regression gate = 全 verify script 統合 ALL PASS

ADR-0067 = fixture 拡張 + 機能 verify only (= driver state widen + trace 取得)、 ADR-0068 = 統合 verify (= cmd 0x05 経路 vs v2 経路 trace-equivalence 比較 + 全 verify ALL PASS + 統合 report)。 これが **roadmap ⑤ 統合 verify 本体**。

### (d) 越川氏 audition gate = ADR-0065 候補 scope-out

(d) audition は ADR-0064 §決定 1(d) literal = roadmap ⑥ ADR-0065 候補 = 別 ADR、 user 明示 GO 必須 future。

### ADR-0064 §決定 7 番号 chronology rationale 整合

ADR-0064 §決定 7 literal「ADR-0067+ = ADR-0064 実作業 ADR」 整合維持:
- **ADR-0067** = driver fixture 拡張 ADR (= 16 ch trace-equivalence 前提作り完成、 1 本目)
- **ADR-0068 (= 本 ADR)** = 16 ch 統合 verify ADR (= roadmap ⑤ 統合 verify 本体、 **2 本目**)
- ADR-0064 plan 実作業群 = ADR-0067 + ADR-0068 = 2 ADR chain (= ADR-0068 完走で plan 実作業群完了)

### user 明示 GO「次は ADR-0068 候補が自然」

ADR-0067 ε Accepted (= PR #132 merge) 完了報告後、 user 明示「次は ADR-0068 候補が自然です。 目的は 16ch 統合 verify、 つまり cmd 0x05 経路と v2 経路の trace-equivalence 比較です。 これが roadmap ⑤ 統合 verify 本体になります」 = ADR-0064 §決定 9 起票判断条件「user 明示 GO 必須」 整合。

### PR1 (= 本 PR) doc-only 起票 + PR2 α 実装段階分離 (= user 明示 option 1 採用)

user 明示 GO option 1 = ADR-0068 doc-only 起票 1 PR + α 実装 1 PR 段階分離:
1. PR1 (= 本 PR) = ADR-0068 doc 起票 doc-only (= 12 決定 + Annex skeleton + dashboard + memory) + driver / verify / vendor / fixture 完全不変
2. PR2 = α 実装 = 新規 verify script + 16 ch candidate 探索 + 20 trace capture (= K=3 candidate + α-task 1 = 10 env × 2 trace 種) + literal report

user 判断軸 (= literal 引用):
- doc-only 起票 PR で ADR-0068 の scope を先に固定できる
- α 実装 PR の revise risk を doc 起票から切り離せる
- 16 ch candidate が見つからない場合でも、 起票 ADR 全体を巻き戻さずに済む
- Codex review が小さくなり、 越権・長時間化・混線のリスクが下がる
- ADR-0064 の plan / 実作業分離 pattern と整合する

## 決定

### 決定 1: scope = ADR-0056 §決定 3 (a)(b)(c) 3 gate 統合 verify (= ADR-0064 §決定 1 literal 継承)

ADR-0056 §決定 3 4 gate のうち **(a)(b)(c) 3 gate** を統合 verify 対象。 (d) 越川氏 audition は ADR-0065 候補 (= roadmap ⑥) scope-out。

#### (a) 実 MML 再生 gate 統合 verify
- scope: v2 driver 経路 (= TEST_MODE_V2_SONG_FIXTURE=1 + TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP=1 = driver .equ name、 verify script からは env var `PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1` で渡す = build-poc.sh sed 置換、 (B) build mode) + cmd 0x05 経路 (= PMDNEO_M_RAW or PMDDOTNET_MML legacy build、 (C-1)/(C-2) build mode) 並走 trace capture
- 目的: 各 ch 個別 verify 完了済 (= roadmap ①〜③ Accepted) を 1 件の MML song に対して統合実行 + 統合 trace 取得
- 完了判定: 全 ch + 全機能の trace 統合取得 + literal report

##### α union coverage の境界明記 (= β trace-equivalence 完了条件 代替ではない、 40th session plan v6-revised diff 1)

α union coverage = ADR-0064 §決定 1(b) literal「16 ch 同時 register write trace」 とは別軸、 β trace-equivalence 完了条件 (= 単一 MML 内 16 ch 同時 trace の v2/cmd 0x05 経路比較) 代替ではない。 α union coverage = β trace-equivalence 比較 input material 提供 + ADR-0064 16ch 方針維持手段。 完了条件は β で確定。 α 結果が 12/16 ch carry 場合の不足 ch (= FM E/F + SSG G/H) は β で minimal MML 例外許可で carry (= 下記 hybrid 原則 sub-section literal)。

##### driver source dispatch ground truth (= plan v7 = 40th session self-test 完走後 driver 調査確定、 plan v6-revised hybrid 原則 unused 化)

40th session self-test で発見 (= plan v6-revised の「各 candidate を再生」 前提 wrong):

driver `nmi_cmd_5_init_mml_song` (= `src/driver/standalone_test.s:1569-1888`) literal:

| MML part | dispatch source | PMDNEO_USE_PMDDOTNET 切替 |
|---|---|---|
| A-F (= FM 6 ch、 PART_FM1-6) | `load_song_part_addr` (= song_table[index] 経由 = test01/test02 default) | **なし** (= 常時 song_table) |
| G-I (= SSG 3 ch、 PART_SSG1-3) | `load_song_part_addr` (= 同上) | **なし** |
| J (= ADPCM-B、 PART_PCM) | `load_song_part_addr` (= 同上) | **なし** |
| K (= rhythm、 PART_RHYTHM) | `pmdneo_mn_direct_load_k_part_addr` ↔ `load_song_part_addr` | **あり** (= line 1808-1813) |
| L-Q (= ADPCM-A 6 ch、 PART_ADPCMA1-6) | `pmdneo_mn_direct_load_lq_part_addr` ↔ `load_song_part_addr` | **あり** (= line 1823-1888) |

全 build mode 統合 carrier 差分 table (= 40th session driver source 調査結果):

| build mode | A-J (= FM 6 + SSG 3 + ADPCM-B) | K (= rhythm) | L-Q (= ADPCM-A 6) | candidate MML 関与 part |
|---|---|---|---|---|
| (A) production default | test01/test02 default | test01/test02 default | test01/test02 default | **なし** |
| (B) v2-only fixture | test01/test02 default + v2 fixture mixed | 同上 + v2 `_rhythm_k_full` | 同上 + v2 fixture | **なし** (= fixture data 内蔵) |
| (C-1) PMDNEO_M_RAW | test01/test02 default 固定 | pmddotnet_song K | pmddotnet_song L-Q | **K + L-Q (= 7 part)** |
| (C-2) PMDDOTNET_MML | test01/test02 default 固定 | pmddotnet_song K | pmddotnet_song L-Q | **K + L-Q (= 7 part)** |

### 結果 = 既存 build mode で candidate distinctness 達成は K + L-Q (= 7 part) のみ可能

- **A-J 10 part の candidate dispatch は既存 build mode いずれでも不可** (= driver line 1741-1804 `load_song_part_addr` 固定)
- **K + L-Q 7 part は (C-1)/(C-2) で PMDNEO_USE_PMDDOTNET=1 切替で MML 由来可能**
- A-J candidate distinctness を実現するには **driver source 拡張必要** (= **ADR-0069 候補** = §決定 9 literal)

### plan v6-revised の hybrid 原則 sub-section = unused 化

plan v6-revised の「不足 4 ch (= FM E/F + SSG G/H) は β で minimal MML 例外許可」 = **driver ground truth で根本不要**:

- FM E/F + SSG G/H は **default test01/test02 駆動で常時 carry** (= 40th session self-test trace 確認、 env # 5-10 で各 8 writes / 2 writes pattern 整合)
- minimal MML 追加は **不要**
- hybrid 原則 sub-section = **unused** (= plan v7 で撤回、 ただし plan 経緯記録のため literal 残置)
- 新「真の不足軸」 = A-J candidate distinctness (= driver 拡張 sprint = ADR-0069 候補 future)

### 40th session self-test actual trace literal (= 10 env × 2 trace = 20 file capture 結果)

trace coverage = 16/16 ch carry actual (= default + fixture 由来):

| chip 軸 | actual carry (= 全 env で carry) | 由来 |
|---|---|---|
| FM (6 ch = A-F) | A B C D E F | (B) v2 fixture + (C-1)/(C-2) test01/test02 default |
| SSG (3 ch = G-I) | G H I | 同上 |
| ADPCM-B (1 ch = J) | J | 同上 |
| ADPCM-A (6 ch = L-Q) | L M N O P Q | (B) v2 `_rhythm_k_full` + (C-2) pmddotnet_song L-Q |
| 合計 | 16 / 16 | 既存 default + ADR-0067 fixture 拡張完了 baseline |

candidate distinctness (= K + L-Q 7 part のみ可能、 A-J = default 同一):

| env | candidate MML | L-Q trace (= distinct) | A-J trace (= default 同一) |
|---|---|---|---|
| 03 rhythm-only ym2610 | l-q-rhythm-song.mml | L=9 M=9 N=17 O=5 P=3 Q=2 (= MML 由来 distinct) | A=0 B=8 C=8 D=0 E=8 F=8 G=2 H=2 I=2 J=2 (= default 同一) |
| 04 rhythm-only ym2610b | 同上 | 同上 | A=8 D=8 F=8 + 他同上 (= ym2610b chip target 差) |
| 05 SAMPLE2-baseline | (L-Q 全 empty、 `ABCI L` 行の L は loop start mark = ADPCM-A part body 不在) | L=1 M=1 N=1 O=1 P=1 Q=1 (= 全 init keyon 1 件のみ、 MML 由来 distinct なし) | 同上 default 8/2 pattern |
| 07 test-aes-ad | (L-Q empty) | L=1 M=1 N=1 O=1 P=1 Q=1 (= 全 init keyon のみ) | 同上 |
| 09 j-part-g | (L-Q empty) | 同上 | 同上 |

### K=3 candidate enumeration plan v6-revised → v7 update

plan v6-revised candidate selection (= SAMPLE2-baseline / test-aes-ad / j-part-g) は **A-J part 由来 distinctness 想定** で wrong:

- SAMPLE2-baseline (= FM A/B/C + SSG I、 `ABCI L` 行の L は PMD MML loop start mark = ADPCM-A L part body 不在、 Codex impl-review round 1 must-fix 2 反映で訂正) → A-J 部分は default driven、 L-Q 全 distinct なし
- test-aes-ad (= FM A/B/D) → 全 default driven、 L-Q distinct なし
- j-part-g (= ADPCM-B J) → 全 default driven、 L-Q distinct なし

plan v7 candidate selection = **K + L-Q part 持ち MML** に再選定:

- α-task 1 = `src/test-fixtures/step5/l-q-rhythm-song.mml` (= L-Q 6 part each driven、 K なし) = L-Q distinctness primary
- α-task 2-1 = `src/test-fixtures/step5/l-q-tutti.mml` (= L-Q 6 part 同時 keyon、 K なし) = L-Q distinctness alternative
- α-task 2-2 = `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= L-Q 6 part、 K なし) = L-Q distinctness step5b proof
- K distinctness candidate = future (= K part 単独 MML 探索 + 追加可能性は β scope)

= K=3 candidate plan v7 update = L-Q distinct primary (= 既存 src/test-fixtures/ L-Q part 持ち 3 candidate)、 K distinctness は **β scope future**。

#### (b) 実音 register trace-equivalence gate 統合 verify
- scope: FM 6 + SSG 3 + ADPCM-B 1 + ADPCM-A 6 = 16 ch 同時 register write trace を v2 driver / 既存 driver 両経路で capture + trace-equivalence 確認
- trace-equivalence 定義 (= 決定 4 literal、 ADR-0056 §決定 3-a 継承): 完全 byte-identical ではなく、 意図した v2 差分許容、 意図しない差分不可、 byte-identical は acceptable pass case の 1 つ
- 完了判定: 全 ch trace-equivalence 確認 + 意図しない差分なし literal 確認

#### (c) baseline regression gate 統合 verify
- scope: 全 verify script suite を 1 batch で production binary 1 件に対して通す + ALL PASS 確認
- 完了判定: 全 verify script ALL PASS literal 確認 + completion proof 統合 report

#### (d) 越川氏 audition gate = ADR-0065 候補 scope-out
- engineering pass (= (a)(b)(c)) ≠ aesthetic pass (= (d))、 ADR-0065 候補で別 sprint。

### 決定 2: sub-sprint chain α/β/γ/δ/ε 5 段 (= ADR-0064 §決定 3 plan literal 継承)

| sub | scope | 関連 gate | 完了判定 |
|---|---|---|---|
| α | (a) 実 MML 再生 統合 verify = **K+L-Q candidate distinctness capture + A-J default integration trace** (= plan v7 = 40th session driver ground truth based、 distinctness 判定 assertion は β scope future)。 candidate = `src/test-fixtures/step5/l-q-rhythm-song.mml` + `src/test-fixtures/step5/l-q-tutti.mml` + `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= K=3 L-Q distinct candidate)、 K distinctness は β scope future。 10 env × ymfm/z80-mem 2 trace 種 capture = 20 trace file + literal report | (a) | K+L-Q distinctness capture (= 各 candidate L-Q trace 個別記録) + A-J default integration trace record (= default 同一 8/2 pattern literal) + 16/16 ch carry actual literal record |
| β | (b) trace-equivalence 判定基準確定 + 比較実行 = 意図した v2 差分 / 意図しない差分 enumeration literal + α 取得 trace 20+ 件を input として **K+L-Q candidate distinctness comparison** + A-J default carry baseline 比較 + K distinct candidate (= K part 単独 MML) 探索 / 追加判断 | (b) | K+L-Q distinctness 範囲で trace-equivalence 確認 + A-J default carry baseline 確認 + 意図しない差分なし literal 確認 |
| γ | (c) 全 verify script 統合 ALL PASS = production binary 1 件に対して全 verify を 1 batch 実行 + 統合 report | (c) | 全 verify script ALL PASS literal 確認 + completion proof 統合 report (= 「16ch integration trace 完了」 + 「K+L-Q candidate distinctness 完了」 + 「A-J default carry 確認」 三分割 wording 必須、 「16ch full candidate distinctness 完了」 wording 禁止 = A-J distinctness は ADR-0069 候補 future) |
| δ | 統合 report 作成 + 残課題 enumeration (= ADR-0065/0066 起票判断 material) | - | 統合 report literal + 残課題 literal |
| ε | Draft → Accepted 移行 + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal (= 併記必須) | - | Accepted 移行完了 milestone |

= 5 sub-sprint pattern (= ADR-0067 chain 同 pattern 継承)。 各 sub-sprint = 1 PR (= 計 5 PR、 ε までで ADR-0068 完走)。 本 PR1 = ADR-0068 doc-only 起票、 sub-sprint α-ε は PR2-PR6 (= 別 task chain で起票)。

### 決定 3: build mode literal (= 4 mode、 (C-1)/(C-2) は ADR-0068 で初使用)

ADR-0068 で使用する build mode (= ADR-0067 §決定 4 (A)/(B) 継承 + (C-1)/(C-2) 新規 literal):

#### (A) production default build (= 既存、 sha256 維持対象)
- 全 fixture toggle = 0 (= ADR-0067 §決定 4 (A) literal 継承)
- sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory
- (c) baseline regression gate で representative binary として使用

#### (B) v2 only trace capture build (= ADR-0067 流用)
- TEST_MODE_V2_SONG_FIXTURE=1 + TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP=1 (= ADR-0067 §決定 4 (B) literal 継承)
- v2 driver 経路で trace capture
- α env # 1-2 で使用

#### (C-1) PMDNEO_M_RAW 経路 (= ADR-0068 で初使用)
- raw .M binary 直接取り込み (= compile.py 経由なし、 `m-to-z80-incbin.py` 経由 .incbin 経路)
- env = `PMDNEO_M_RAW=<.M binary path> PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip <ym2610|ym2610b>` (= driver 側 `PMDNEO_USE_PMDDOTNET=1` を同時 export 必須、 ADR-0068 Codex impl-review round 1 must-fix 1 反映)
- `PMDDOTNET_MML` と **排他** (= `PMDNEO_M_RAW` 優先、 `scripts/build-poc.sh:156` literal)
- driver 側 `PMDNEO_USE_PMDDOTNET=1` (= driver line 34-40 literal、 build infra `sed` 置換) = 同経路で `pmddotnet_song` `.incbin` 経路へ切替、 上記 env で同時 export 必須
- β/γ で必要時使用 (= 既存 .M binary 直接 trace 比較用)

#### (C-2) PMDDOTNET_MML 経路 (= ADR-0068 で初使用)
- 改造 PMDDotNET dotnet で MML compile → `.M` binary → `pmddotnet_song.m` + `song_data.inc` 追記
- env = `PMDDOTNET_MML=<MML path> PMDDOTNET_MODE=<N|B> PMDDOTNET_DLL=<dll path> PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip <ym2610|ym2610b>`
- `PMDDOTNET_MODE` (= N/B、 default N) = ADPCM-A 経路使用切替 (= B = ADPCM-A 経路、 N = ADPCM-A 経路なし)
- `PMDDotNETConsole.dll` (= `vendor/PMDDotNET/PMDDotNETConsole/bin/Release/net6.0/PMDDotNETConsole.dll`) 必要
- α env # 3-6 で主軸使用

### 決定 4: trace-equivalence 定義 literal (= ADR-0056 §決定 3-a / ADR-0064 §決定 1(b) literal 継承)

trace-equivalence 判定 criteria:
- **完全 byte-identical** ではなく、 **意図した v2 差分** (= dispatch 順序 / 並設 routine 由来 write 順序差) を許容しつつ、 **実音として等価な register state へ収束**
- **意図しない差分** (= 音が変わる write の欠落 / 誤値) は不可
- byte-identical は acceptable pass case の 1 つに過ぎず、 v2 実装方式差を許容する trace-equivalence が gate 判定基準
- literal 判定基準 (= 「意図した v2 差分 / 意図しない差分」 の具体的 register / 順序 enumeration) は β sub-sprint で確定 (= α は capture + report only)

### 決定 5: allowed-touch literal (= 3 段分類、 ADR-0064 §決定 9 line 171-173 pattern 継承)

#### (i) repo diff allowed-touch (= 各 PR 対象 file)

**PR1 (= 本 PR、 doc-only 起票) scope**:
- ADR-0068 新規 file (= `docs/adr/0068-pmdneo-axis-b-v2-16ch-integration-verify.md`)
- dashboard 0068 行追加 + escalation 履歴 entry 1 row + 0067 entry 完全不変
- (driver / verify script / vendor 完全不変)

**PR2-PR6 (= 後続 α-ε 実装、 別 task chain) scope**:
- 新規統合 verify script 追加 (= sub-sprint 毎 1+ script、 詳細は各 PR 起票時 plan で確定)
- ADR-0068 § Annex N section 新規追加 + § 改訂履歴 entry + 状態行は ε で Draft → Accepted
- env prefix 統一表記 (= `PMDDOTNET_MML` / `PMDDOTNET_MODE` / `PMDDOTNET_DLL` + `PMDNEO_M_RAW` + `PMDNEO_USE_PMDDOTNET` 全 build mode 共通、 各 PR 内 verify script + dashboard scope-in literal 整合、 plan v6-revised diff 4)

#### (ii) runtime / driver allowed-touch = 完全不変

- driver source (= `src/driver/standalone_test.s`)
- ADR-0067 fixture (= 全 16 ch fixture data + slot 2-10 init + pointer switch、 `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_rhythm_k` + `_rhythm_k_full` 全て不変)
- 既存 verify script (= ADR-0049〜0067 全、 含む `verify-axis-b-v2-song-playback.sh` + `verify-axis-b-v2-roadmap3-dispatch.sh` + `verify-axis-b-v2-fixture-expansion-delta.sh`)
- 既存 build flag (= 新規 flag 追加なし、 既存 flag combination のみ使用)
- vendor
- ADR-0048〜0067 本文 + Annex
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触

#### (iii) repo 外 = PR diff 対象外

- 主軸 memory dir (= `~/.claude/projects/.../memory/`) = `project_pmdneo_adr_0068_initiated.md` 新規 + MEMORY.md index 1 行追加 = PR diff に現れない、 commit 対象外

### 決定 6: 表記制約継承 + 新規解禁表現候補 literal (= ADR-0067 §決定 6 pattern 継承)

| 表現 | ADR-0068 起票時点 | ADR-0068 ε Accepted 後 | 解禁条件 / 併記必須 |
|---|---|---|---|
| 「16 ch fixture 拡張完了」 | 使用可 (= 継承) + 併記必須 = ADR-0067 §決定 6 由来 = 「roadmap ⑤ 統合 verify 未実装 (= ADR-0068 候補 future)」 + 「production-ready 全体達成ではない」 | 使用可 + **併記必須 update** = 「roadmap ⑤ 統合 verify 完了、 ただし production-ready 全体達成ではない」 + 「(d) audition 未実装 (= ADR-0065 候補 future)」 + 「本番 cmd 切替未実施 (= ADR-0066 候補 future)」 | ADR-0068 ε Accepted で「未実装」 → 「完了」 反転、 同時に「(d) audition 未実装」 / 「本番 cmd 切替未実施」 を併記必須化 |
| 「全 16 ch trace 取得」 / 「機能 verify 完了」 | 使用可 (= 継承) | 使用可 (= 継承) | ADR-0067 δ 由来 |
| 「軸 G dynamic supply 完成」 (日英両版) | 使用可 (= 継承) | 使用可 (= 継承) | ADR-0048 ζ-ε 由来 |
| **「roadmap ⑤ 統合 verify 完了」 (= 新規解禁表現候補)** | **literal 禁止 (= ADR-0068 ε Accepted 前)** | **使用可、 ただし併記必須** | **ADR-0068 ε Accepted 後使用可 + 併記必須 = 「(d) audition 未実装 (= ADR-0065 候補 future)」 + 「production-ready 全体達成ではない」 + 「軸 B 完成ではない」 + 「本番 cmd 切替完了ではない」** |
| **「(a)(b)(c) 3 gate 統合 verify 完了」 (= 新規解禁表現候補)** | literal 禁止 | 使用可、 併記必須 | 同上 |
| **「trace-equivalence 完了」 (= 新規解禁表現候補)** | literal 禁止 | 使用可、 併記必須 (= K+L-Q distinctness 範囲限定併記必須、 plan v7) | 同上 + 「A-J distinctness は ADR-0069 候補 future」 併記必須 |
| **「K+L-Q candidate distinctness 完了」 (= plan v7 新規解禁表現)** | literal 禁止 | 使用可、 併記必須 | ADR-0068 ε Accepted 後使用可 + 併記必須 = 「A-J default carry 確認」 + 「16ch full candidate distinctness 未達成 (= ADR-0069 候補 future)」 |
| **「A-J default carry 確認」 (= plan v7 新規解禁表現)** | literal 禁止 | 使用可 | ε Accepted 後使用可 (= 単独使用 OK、 ただし「16ch full candidate distinctness」 と混同しない) |
| **「16ch integration trace 完了」 (= plan v7 新規解禁表現)** | literal 禁止 | 使用可、 併記必須 | ε Accepted 後使用可 + 併記必須 = 「K+L-Q distinctness 達成」 + 「A-J default carry 確認」 + 「16ch full candidate distinctness 未達成」 |
| **「16ch full candidate distinctness 完了」 (= plan v7 新規禁止表現、 ADR-0069 候補 future)** | **literal 禁止** | **literal 禁止維持** | **ADR-0069 候補 (= driver 拡張 sprint) 完走後 future**、 ADR-0068 ε Accepted では達成不可 (= driver source 修正必須) |
| 「production-ready 全体達成」 | literal 禁止維持 | literal 禁止維持 | ADR-0056 §決定 3 4 系統全通過 + 越川氏 audition approve + 本番 cmd 切替後 future |
| 「軸 B 完成」 | literal 禁止維持 | literal 禁止維持 | v2 driver production-ready 化 + 本番 cmd 切替後 future |
| 「軸 G 完成」 | literal 禁止維持 | literal 禁止維持 | 軸 G 全体完成は別 axis 完了後 future |
| 「本番 cmd 切替完了」 | literal 禁止維持 | literal 禁止維持 | ADR-0066 候補完了後のみ |

#### gate verify criteria (= ADR-0067 §決定 6 ε gate-3 pattern 継承)
- 禁止 wording は **肯定表現として使わない**
- ただし「production-ready 全体達成ではない」 / 「軸 B 完成ではない」 / 「16 ch fixture 拡張完了 ≠ roadmap ⑤ 統合 verify 完了」 等の **否定併記は必須**
- 「未実装」 / 「未解禁」 / 「future」 / 「不可」 / 「≠」 reference context は OK

### 決定 7: 不可触対象 literal (= 決定 5 (ii) と整合、 明示再列挙)

#### 完全不変
- driver source (= `src/driver/standalone_test.s`)
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_adpcmb_j_ppc` + `_rhythm_k` + `_rhythm_k_full` + `_rhythm_k_audition` + audition fixture 全)
- ADR-0067 slot init (= slot 0-10 init + chip target 別 active policy + pointer switch)
- 既存 verify script (= ADR-0049〜0067 全)
- 既存 build flag (= 新規 flag 追加なし)
- vendor
- ADR-0048〜0067 本文 + Annex
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触

### 決定 8: PR chain plan = 5 PR (= sub-sprint α/β/γ/δ/ε 各 1 PR + 本 PR1 = 計 6 PR、 ADR-0067 chain 同 pattern)

| PR # | scope | content type |
|---|---|---|
| **PR1 (= 本 PR)** | ADR-0068 doc 起票 doc-only (= 12 決定 + Annex skeleton + dashboard + memory) | doc-only |
| PR2 | sub-sprint α = (a) 実 MML 再生 統合 verify = 新規 verify script + α-task 1 L-Q distinctness primary (= l-q-rhythm-song) + α-task 2 L-Q distinctness alternative + step5b proof + A-J default integration baseline (= plan v7、 SAMPLE2-baseline / l-q-tutti / l-q-rhythm-song-step5b) + 20 trace capture (= 10 env × 2 trace 種) + literal report + Annex α、 actual 結果 = 16/16 carry actual + L-Q candidate 3 種類 distinct pattern + A-J default integration trace 確認 | 実装 + doc |
| PR3 | sub-sprint β = (b) trace-equivalence 判定基準確定 + 比較実行 + Annex β | 実装 + doc |
| PR4 | sub-sprint γ = (c) 全 verify script 統合 ALL PASS + Annex γ | 実装 + doc |
| PR5 | sub-sprint δ = 統合 report + 残課題 enumeration + Annex δ | doc 主体 |
| PR6 | sub-sprint ε = Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal (= 併記必須) | doc-only |

### 決定 9: ADR-0065/0066/0069 候補 起票判断 = future、 user 明示 GO 必須

- **ADR-0065 候補** = roadmap ⑥ audition ADR (= 越川氏 audition gate、 aesthetic gate)
- **ADR-0066 候補** = roadmap ⑦ 本番 cmd 切替判断 ADR (= cmd 0x05 + pmdneo_song_main 経路 → v2 driver 経路 switch、 production-ready 全通過後 future)
- **ADR-0069 候補** (= plan v7 新規追加) = driver 拡張 sprint = nmi_cmd_5_init_mml_song line 1741-1804 `load_song_part_addr` 経路を `.if PMDNEO_USE_PMDDOTNET == 1` 分岐で `pmdneo_mn_direct_load_a_part_addr` 等の A-J 各 part 拡張 + ADR-0067 fixture 拡張 pattern 同手法 additive 修正 (= 既存 routine 不変)、 完走で A-J candidate distinctness 達成 + ADR-0068 「16ch full candidate distinctness 完了」 wording 解禁、 ADR-0068 ε Accepted 後 future user GO 必須
- 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)

### 決定 10: production sha256 維持 mandatory (= 全 sub-sprint 共通 gate)

ADR-0068 全 sub-sprint 共通 gate:
- 通算 sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持必須
- (A) production default build (= TEST_MODE_V2_SONG_FIXTURE=0 等 全 toggle off) で sha256 literal 一致 confirm
- (B)/(C-1)/(C-2) build mode は別 sha256 (= 比較対象外)

### 決定 11: chip target 別 trace (= ADR-0067 §決定 12 継承)

- **ym2610 primary trace** (= production default、 FM 3 ch B/C/E + SSG 3 ch + ADPCM-B + ADPCM-A 6 ch = 8 active slot)
- **ym2610b secondary trace** (= 別 build、 + FM A/D/F = 11 active slot)
- ADR-0067 §決定 12 chip target 別 active policy literal 整合維持

### 決定 12: 番号 chronology rationale literal (= ADR-0064 §決定 7 継承)

ADR-0064 §決定 7 literal「ADR-0067+ = ADR-0064 実作業 ADR」 整合維持:
- **ADR-0067** = driver fixture 拡張 ADR (= 16 ch trace-equivalence 前提作り完成、 ADR-0064 plan 実作業 1 本目) = **完了**
- **ADR-0068 (= 本 ADR)** = 16 ch 統合 verify ADR (= roadmap ⑤ 統合 verify 本体、 ADR-0064 plan 実作業 **2 本目**) = 起票
- ADR-0064 plan 実作業群 = ADR-0067 + ADR-0068 = 2 ADR chain (= ADR-0068 完走で plan 実作業群完了)
- 番号 chronology = ADR-0064 plan → ADR-0065 (= roadmap ⑥ audition、 future) → ADR-0066 (= roadmap ⑦ 本番 cmd 切替、 future) → ADR-0067 fixture 拡張 (= 完了) → ADR-0068 統合 verify (= 起票)

## verify gate (= PR1 = doc-only sprint、 spec consistency check)

PR1 (= 本 PR) verify gate (= doc-only、 build 不要):
- ADR-0068 新規 file 起票 + ADR-0067 ε Accepted 後続
- driver / verify script / vendor / fixture / build flag 完全不変
- (a)(b)(c) gate 統合 verify scope literal + (d) audition scope-out literal 完了
- sub-sprint α/β/γ/δ/ε 5 段 plan literal 完了 (= ADR-0064 §決定 3 plan literal 継承 + α-task 1/2 切り分け literal)
- build mode (A)/(B)/(C-1)/(C-2) 4 mode literal (= scripts/build-poc.sh + driver source ground truth literal 整合)
- trace-equivalence 定義 literal (= ADR-0056 §決定 3-a 継承、 α/β scope 切り分け = α capture only / β 判定基準確定)
- allowed-touch 3 段分類 literal (= (i) repo diff + (ii) runtime/driver 完全不変 + (iii) repo 外 memory)
- 表記制約 + 新規解禁表現候補 literal (= 「16 ch fixture 拡張完了」 起票時点 / ε Accepted 後 2 段化 + 「roadmap ⑤ 統合 verify 完了」 等 ε Accepted 後解禁 + 併記必須)
- 番号 chronology rationale literal (= ADR-0064 §決定 7 整合)
- 通算 sha256 = `b15883fe...` 維持期待 (= doc-only build 走らない、 doc / dashboard / memory のみ change)
- ADR-0048〜0067 本文 + Annex + 既存 escalation 履歴 entry 完全不変

後続 sub-sprint α-ε verify gate = 各 PR2-PR6 で確定。

## Codex layer 2 plan review chain (= 4 round chain、 全 review-only + 越権操作なし confirmed)

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| 1 | revise | must-fix 3 = build mode (C) env literal 不足 + allowed-touch literal 分類不足 + ε 解禁時併記必須 literal 未確定、 nh 2 + lr 1 | `a799c7ba9d307e5bf` |
| 2 | revise | must-fix 2 (= 新規発見) = 「16 ch fixture 拡張完了」 併記必須 起票時点 / ε Accepted 後 2 段化 + legacy MML 第一 candidate SAMPLE2-step8-Bvol.mml contradicted (= 41 行 / B part のみ)、 nh 1 + lr 1 | `a9edf6991d326d06a` |
| 3 | revise | must-fix 2 = candidate path 誤り (= `src/test-fixtures/step5/songs/` 実在しない、 正 = `src/test-fixtures/step5/l-q-rhythm-song.mml`) + `l-q-rhythm-song.mml` = L-Q ADPCM-A 6 ch のみで全 16 ch 不整合、 nh 1 + lr 1 | `aca7e3685f7014fdf` |
| 4 | **approve** | must-fix 0 + nh 1 (= α-task 2 candidate ch coverage 表残し推奨) + lr 1 (= 全 16 ch candidate 不在時 revise/escalate 条件明記) | `ab1422ba6381c0322` |

= 4 round chain、 全 review-only 遵守 confirmed + 越権操作なし。 must-fix 計 7 件 + nh 計 4 件 + lr 計 3 件 全 ADR 本文反映。

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

## Annex skeleton (= ε で fill default、 α 漏れ補完 retrospective 起票時 prevention = ADR-0067 ε retrospective 反映)

### Annex A: ADR-0068 ground truth + 起票背景 (= ε で fill)

(= ADR-0067 完走経緯 + roadmap ⑤ 統合 verify 本体 + (a)(b)(c) 3 gate scope + ADR-0064 §決定 3 plan literal 継承 + user 明示 GO option 1 (PR1/PR2 分離) literal を ε で fill)

### Annex B: 16 ch 統合 verify 構成図 + build mode matrix (= ε で fill)

(= 16 ch 統合 verify 全体図 + build mode (A)/(B)/(C-1)/(C-2) matrix + chip target 別 trace + PMDDOTNET_MODE matrix + trace TSV format literal を ε で fill)

### Annex α: α 実装 completion record (= plan v7 = K+L-Q distinctness capture + A-J default integration trace、 distinctness 判定 assertion は β scope future)

#### α-1 = scope literal (= plan v7 = K+L-Q distinctness capture + A-J default integration trace)

ADR-0068 §決定 2 α row plan v7 literal:
- α-task 1 = L-Q distinctness primary = `src/test-fixtures/step5/l-q-rhythm-song.mml` (= L-Q 6 part each driven)
- α-task 2 = L-Q distinctness alternative + step5b proof + A-J default integration baseline:
  - `src/test-fixtures/step5/l-q-tutti.mml` (= L-Q 6 part 同時 keyon)
  - `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= L-Q 6 part driven step5b proof)
  - `vendor/PMDDotNET/SAMPLE2-baseline.mml` (= A-J default integration baseline)
- K distinctness candidate = β scope future (= K part 単独 MML 探索 + 追加判断)

α scope = capture + report only (= ADR-0068 §決定 1(a) α union 境界明記 literal、 trace-equivalence 判定は β scope)。

#### α-2 = 配置 (= 新規 verify script + ADR doc plan v7 + 既存 candidate MML / 既存 driver / 既存 build flag 完全不変)

- **新規 verify script**: `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-alpha.sh` (= 466 行、 ADR-0067 δ pattern 継承、 Codex impl-review round 1 nh 1 + round 3 must-fix 3 反映で行数更新)
- **ADR-0068 doc**: plan v7 update (= §決定 1(a) + §決定 2 + §決定 6 + §決定 9 + Annex α fill + 改訂履歴 plan v7 entry)
- **build mode env literal** (= 10 env):
  - env # 1-2 = (B) v2-only = `PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 bash scripts/build-poc.sh --chip <ym2610|ym2610b>`
  - env # 3-10 = (C-2) PMDDOTNET_MML = `PMDDOTNET_MML=<path> PMDDOTNET_MODE=B PMDDOTNET_DLL=<dll path> PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip <ym2610|ym2610b>`
- **driver / 既存 verify / vendor / 既存 fixture / 既存 build flag 完全不変** (= ADR-0068 §決定 5 (ii) literal)
- **トレース出力**: `/tmp/pmdneo-adr-0068-alpha/env-<NN>-<label>-{ymfm,zmem}.tsv` 計 20 file (= 10 env × 2 trace 種)

#### α-3 = K+L-Q distinctness capture 結果 (= L-Q candidate 3 種類 distinct trace pattern capture + report 完了)

ADPCM-A port B reg 0x100 (= keyon mask) bit 別 detection literal:

| env | MML | L (bit 0) | M (bit 1) | N (bit 2) | O (bit 3) | P (bit 4) | Q (bit 5) | pattern |
|---|---|---|---|---|---|---|---|---|
| 03-rhythmonly-ym2610 | l-q-rhythm-song | 9 | 9 | 17 | 5 | 3 | 2 | A (= MML note 数差分) |
| 04-rhythmonly-ym2610b | 同上 | 9 | 9 | 17 | 5 | 3 | 2 | A (= chip target 同等) |
| 05-lqtutti-ym2610 | l-q-tutti | 2 | 2 | 2 | 2 | 2 | 2 | B (= 6 ch 同時 keyon) |
| 06-lqtutti-ym2610b | 同上 | 2 | 2 | 2 | 2 | 2 | 2 | B |
| 07-lqstep5b-ym2610 | l-q-rhythm-song-step5b | 9 | 9 | 17 | 5 | 3 | 2 | A (= MML body 同一) |
| 08-lqstep5b-ym2610b | 同上 | 9 | 9 | 17 | 5 | 3 | 2 | A |
| 09-sample2-baseline-ym2610 | SAMPLE2-baseline | 1 | 1 | 1 | 1 | 1 | 1 | C (= L-Q 全 empty、 `ABCI L` 行の L は loop start mark = ADPCM-A part body 不在、 全 6 ch init keyon 1 件のみ、 Codex impl-review round 1 must-fix 2 反映で訂正) |
| 10-sample2-baseline-ym2610b | 同上 | 1 | 1 | 1 | 1 | 1 | 1 | C |

= **3 種類 distinct pattern (A/B/C) capture + report 完了** (= α scope = capture + report only literal 整合、 distinctness 判定 assertion は β scope = trace-equivalence 判定基準確定 + 比較実行 future、 Codex impl-review round 1 lr 1 反映で「distinctness 過信表現」 wording を「distinct pattern capture + report」 に明確化):
- pattern A = note 数差分由来 distinctness (= l-q-rhythm-song / l-q-rhythm-song-step5b 同 MML body)
- pattern B = 6 ch 同時 keyon distinctness (= l-q-tutti = 各 ch 1 note の同時 trigger)
- pattern C = baseline + init keyon (= SAMPLE2-baseline = L-Q 全 empty、 `ABCI L` 行の L は PMD MML loop start mark = ADPCM-A part body 不在、 全 6 ch init keyon 1 件のみ、 Codex impl-review round 1 must-fix 2 反映で訂正)

K (= rhythm K bitmap) distinctness は本 α では 候補 MML 全て K part なし、 β scope future。

#### α-4 = A-J default integration trace record (= default driven trace literal 同一 pattern)

全 (C-2) env (= env # 3-10) で A-J 部分 trace は **同一 default pattern**:

| ch | env # 3-10 共通 writes (= ym2610 active のみ) | 由来 |
|---|---|---|
| A (FM A) | 0 (= ym2610 では init guard、 ym2610b で 61) | ADR-0006 §B 整合 |
| B (FM B) | 8 | test01/test02 default driven |
| C (FM C) | 8 | 同上 |
| D (FM D) | 0 (= ym2610 では init guard、 ym2610b で 61) | ADR-0006 §B 整合 |
| E (FM E) | 8 | test01/test02 default driven |
| F (FM F) | 8 (= ym2610b で 8 + ym2610 で 8、 ADR-0006 §B 整合) | 同上 |
| G/H/I (SSG) | 各 2 | 同上 |
| J (ADPCM-B) | 2 | 同上 |

= **A-J default integration trace 確認** (= A-J carry は default driven、 candidate MML 関与なし)。

#### α-5 = 16/16 ch carry actual literal record (= plan v7 整合 三分割 wording)

| chip 軸 | actual carry (= 全 env で carry) | 由来 |
|---|---|---|
| FM (6 ch = A-F) | A B C D E F | (B) v2 fixture + (C-2) test01/test02 default |
| SSG (3 ch = G-I) | G H I | 同上 |
| ADPCM-B (1 ch = J) | J | 同上 |
| ADPCM-A (6 ch = L-Q) | L M N O P Q | (B) v2 `_rhythm_k_full` + (C-2) pmddotnet_song L-Q candidate distinct |
| **合計** | **16 / 16** | 既存 default + ADR-0067 fixture 拡張完了 baseline + plan v7 K+L-Q candidate distinct |

= **16ch integration trace 完了 (= 三分割 wording 整合)**:
- 「16ch integration trace 完了」 ✓
- 「K+L-Q candidate distinctness 完了」 ✓ (= L-Q 3 種類 distinct pattern 確認、 K は β future)
- 「A-J default carry 確認」 ✓ (= default driven trace 同一 pattern 確認)
- 「16ch full candidate distinctness 完了」 = literal 禁止維持 (= A-J distinctness は ADR-0069 候補 future)

#### α-6 = 状態維持 + Codex review + commit chain literal

**状態維持 confirm** (= ADR-0068 §決定 7 不可触対象 literal):
- driver source `src/driver/standalone_test.s` 完全不変
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_rhythm_k_full` 等) 完全不変
- 既存 verify script (= ADR-0049〜0067 全) 完全不変
- 既存 build flag 完全不変 (= 新規 flag 追加なし)
- vendor 完全不変
- ADR-0048〜0067 本文 + Annex 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- **production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待 (= 文書記録のみ、 (A) production default build 実 verify は γ scope future = Codex impl-review round 1 lr 2 反映)** (= α PR2 では (B)/(C-2) build mode のみ使用、 production build artifacts 不変期待、 (A) build mode 実 sha256 確認 + 一致 verify は γ baseline regression gate で実行 予定)

**Codex layer 2 plan review chain (= plan v6-revised + plan v7 経緯)**:

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| plan v6-revised round 1 | revise | must-fix 2 + nh 2 + lr 2 (= line 60/97/204/347 整合 + β/γ で残 4 ch trace-equivalence carry 方法 + nh + lr) | `a493861afdfd58d95` |
| plan v6-revised round 2 attempt | hang 22m 55s cancel | log mtime 20m 停止 + phase=verifying 固定 (= 機械復旧 default rule 該当、 cancel 後 retry) | `task-mpjuqshs-fyavhn` |
| plan v6-revised round 2 retry | revise | must-fix 3 (= 「diff 未反映 = 計画書 review か実反映 review かの解釈ズレ」、 main agent 自律「計画書 review、 ADR 反映は PR2 commit で実施」) | `a18ab6af2bce91b3b` |
| plan v7 (= 本 α) | (impl-review 別途) | self-test 完走 + driver source ground truth 4 件 finding 確定 + user 明示 option 4 採用 = K+L-Q distinctness 再定義 | (= 本 commit 後 impl-review 別途 round 起票) |

= plan review chain = 全 review-only + 越権操作なし confirmed。 plan v7 impl-review は本 commit chain 後 別途 round。

**commit chain literal (= α PR2)**:

| # | commit | 内容 |
|---|---|---|
| 1 | `66f8b6f` | ADR doc plan v6-revised 7 件 diff 反映 |
| 2 | `0613e5a` | verify script 新規 +403 lines |
| 3 | `38444a4` | 全角 「、」 4 件 → 半角 fix |
| 4 | `b2767aa` | printf '----+' + CRLF on-the-fly 変換 helper fix |
| 5 | `c36301f` | detect_adpcma reg 100 (= 3 桁 hex) + assertion softening |
| 6 | `ab542bf` | plan v6-revised → plan v7 = K+L-Q distinctness 再定義 |
| 7 | `5072116` | summary stale wording fix (= plan v7 整合) |
| 8 | `e6f9cbc` | Annex α fill 6 sub-section |
| 9 | `518b7ef` | dashboard 0068 行 status column + escalation 履歴 40th session α PR2 entry |
| 10 | `2b81da6` | Codex impl-review round 1 finding 反映 (= must-fix 3 + nh 1 + lr 2 = SAMPLE2-baseline 解釈訂正 + stale wording cleanup + commit chain 表 update + 行数 update + PASS wording 明示 + production sha256 wording 明示) |
| 11 | `adedc66` | Codex impl-review round 2 finding 反映 (= must-fix 4 + nh 1 = verify script header / report ラベル plan v6 残存 cleanup + dashboard 0068 行 wording 併記 + ADR doc 「K+L-Q distinctness proof」 5 箇所一括置換 + PR1 平易要約欄 wording 併記) |
| 12 | `2f3b3d1` | Codex impl-review round 3 finding 反映 (= must-fix 3 + nh/lr 0 = 「distinctness proof」 残存 3 箇所 → 「distinctness capture」 置換 + commit chain table 10 件 → 12 件 update + 行数 459 → 466 訂正) |
| 13 | `e2c57fe` | Codex impl-review round 4 finding 反映 (= must-fix 1 + lr 1 advisory = ADR doc line 76 §決定 1(a) (a) gate scope literal 変数名 `AXIS_G_AUDITION_LEGACY_SKIP=1` → `TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP=1` 統一 + verify script env var transform 関係明示) |
| 14 | (= 本 commit) | Codex impl-review round 5 finding 反映 (= must-fix 1 + nh/lr 0 = Annex α commit chain table 12 件 → 14 件 update = round 3 commit hash 確定 + round 4 e2c57fe + round 5 本 commit 追加) |

**機械復旧 default rule (= [[long-running-hang-auto-recovery-rule]]) 適用実証**:
- Codex round 2 hang 22m 55s cancel + retry 1 回成功 (= revise judgment 取得)
- verify script bug 4 件 cancel + 修正 retry chain (= 全角 / printf / CRLF / detect_adpcma)
- user 介入 = 設計判断 (= hybrid → option 2 → option 4) のみ
- main agent 自律 = bug fix 6 commit + plan v7 doc update + Annex α fill + dashboard / memory update + Codex impl-review

### Annex β: β 実装 completion record (= β PR3 で fill = trace-equivalence 判定基準確定 + 比較実行)

(= β PR3 で 6 sub-section literal fill)

### Annex γ: γ 実装 completion record (= γ PR4 で fill = 全 verify script 統合 ALL PASS)

(= γ PR4 で 6 sub-section literal fill)

### Annex δ: δ 統合 report + 残課題 enumeration (= δ PR5 で fill)

(= δ PR5 で literal fill = 統合 report + 残課題 enumeration ADR-0065/0066 起票判断 material)

### Annex ε: ε 完走 milestone (= ε PR6 で fill = Draft → Accepted + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須)

(= ε PR6 で literal fill = 「roadmap ⑤ 統合 verify 完了」 + 併記必須 「(d) audition 未実装」 + 「production-ready 全体達成ではない」 + 「軸 B 完成ではない」 + 「本番 cmd 切替未実施」 literal)

## 平易な日本語による要約 (= `feedback_explain_in_plain_japanese_before_commit` 適用)

### やりたいこと

ADR-0067 完走 = 「16 ch fixture 拡張完了」 milestone 直後の roadmap ⑤ 統合 verify 本体 = ADR-0068 起票 doc-only PR1。 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較を sub-sprint α/β/γ/δ/ε 5 段 plan で構成 + 実作業は PR2-PR6 で別 task chain 起票。 本 PR1 = 12 決定 + Annex skeleton + dashboard + memory のみ doc-only (= driver / verify / vendor / fixture 完全不変)。

### 前提

- ADR-0067 Accepted (= PR #132、 「16 ch fixture 拡張完了」 milestone 達成、 16 ch fixture 駆動 trace 機能 verify 完了)
- ADR-0064 §決定 3 sub-sprint plan literal 継承 (= α (a) / β (b) / γ (c) / δ report / ε Accepted)
- ADR-0064 §決定 1 (a)(b)(c) 3 gate scope + (d) audition は ADR-0065 候補 scope-out
- ADR-0056 §決定 3-a trace-equivalence 定義 literal 継承
- user 明示 GO「次は ADR-0068 候補が自然」 + option 1 (= PR1/PR2 段階分離)
- Codex layer 2 plan review 4 round chain (= round 1-3 revise + round 4 approve、 must-fix 計 7 件 + nh 計 4 件 + lr 計 3 件 全反映、 越権操作なし)

### やったこと

- ADR-0068 Draft 起票 (= 12 決定 + Annex skeleton + 平易要約 + 改訂履歴、 doc-only)
- ADR-0064 §決定 3 sub-sprint plan literal 継承 + α-task 1/2 切り分け literal (= 起票時 = rhythm-only proof + 全 16 ch candidate 探索、 plan v7 = L-Q distinctness primary + L-Q distinctness alternative + step5b proof + A-J default integration baseline = 40th session 訂正)
- build mode (A)/(B)/(C-1)/(C-2) 4 mode literal (= scripts/build-poc.sh + driver source ground truth literal 整合)
- trace-equivalence 定義 literal (= ADR-0056 §決定 3-a 継承、 α/β scope 切り分け)
- allowed-touch 3 段分類 literal (= (i) repo diff + (ii) runtime/driver 完全不変 + (iii) repo 外 memory)
- 表記制約 + 新規解禁表現候補 literal (= 「16 ch fixture 拡張完了」 起票時点 / ε Accepted 後 2 段化 + 「roadmap ⑤ 統合 verify 完了」 等 ε Accepted 後解禁 + 併記必須)
- 番号 chronology rationale literal (= ADR-0064 §決定 7 整合)
- Annex skeleton (= A/B/α/β/γ/δ/ε placeholder、 α 漏れ補完 retrospective 起票時 prevention = ADR-0067 ε retrospective 学習反映)
- dashboard 0068 行追加 + escalation 履歴 entry 1 row
- memory entry 新規起票

### 結果

- ADR-0068 Draft 起票 (= 本 PR1 完走時)
- ADR-0064 plan 実作業 2 本目 = ADR-0068 起票 ready
- 通算 sha256 `b15883fe...` 維持期待 (= doc-only build 走らない、 doc / dashboard / memory のみ change)
- ADR-0048〜0067 本文 + Annex 完全不変
- 「16 ch fixture 拡張完了」 wording 継承 + ADR-0068 ε Accepted 後の併記必須 update plan literal
- 「roadmap ⑤ 統合 verify 完了」 等 = ADR-0068 起票時点では literal 禁止維持

### 解釈

ADR-0068 Draft 起票 ≠ 「roadmap ⑤ 統合 verify 完了」 (= ε Accepted 後解禁 + 併記必須) ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。 ADR-0068 = roadmap ⑤ 統合 verify 本体 plan literal、 実作業は PR2-PR6 で sub-sprint α/β/γ/δ/ε 段階実施。 PR1 doc-only = ADR-0064 plan/実作業分離 pattern 整合 (= user 明示 option 1)。

### 次

PR1 merge 後 (= 既完了)、 sub-sprint α 実装 PR2 を別 task chain で完走 (= plan v7 = K+L-Q distinctness capture + A-J default integration trace、 16/16 carry actual + L-Q candidate 3 種類 distinct pattern + 三分割 wording 整合、 distinctness 判定 assertion は β scope future)。 α 完走後 β/γ/δ/ε 各 PR を continue。 ADR-0068 ε Accepted 後、 ADR-0065 候補 (= roadmap ⑥ audition) + ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替判断) + ADR-0069 候補 (= plan v7 新規追加、 driver 拡張 sprint = A-J candidate distinctness 実現) 起票判断 (= 各 user 明示 GO 必須)。

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0068 新規起票 Draft (= doc-only PR1、 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目、 16 ch 統合 verify ADR、 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較、 sub-sprint α/β/γ/δ/ε chain literal、 build mode (A)/(B)/(C-1)/(C-2) 4 mode literal、 trace-equivalence 定義 literal、 allowed-touch 3 段分類 literal、 表記制約 + 新規解禁表現候補 literal、 Annex skeleton 起票時起草 (= α 漏れ補完 retrospective 起票時 prevention)、 Codex layer 2 plan review 4 round chain = round 1-3 revise + round 4 approve、 must-fix 計 7 件 + nh 計 4 件 + lr 計 3 件 全反映、 越権操作なし confirmed、 user 明示 GO option 1 PR1/PR2 段階分離 採用) | (= 起票 commit 後続) |
| 2026-05-24 | 40th session | ADR-0068 α scope 再定義 plan v5 → v6-revised revise (= ADR-0067 Accepted「16 ch fixture 拡張完了」 milestone 前提、 task #50 candidate 探索結果 union 12/16 ch carry + 不足 4 ch = FM E/F + SSG G/H 判明、 user 明示 40th session option 2 採用 = hybrid 方針 = existing resource activation 原則維持 + 不足 ch 限定 minimal MML 例外許可 + 16ch 方針縮小なし + β で minimal MML 4 件追加 carry、 §決定 1(a) α union 境界明記 + hybrid 原則 sub-section 追記 (= K=3 candidate 12/16 coverage 表 literal + β minimal MML 候補 enumeration) + §決定 2 α/β/γ row 再定義 + §決定 5 PR2-PR6 PMDNEO_* prefix 統一 + line 60/97/204/347 20 trace 化整合、 Codex layer 2 plan review 5 round chain = round 1 revise must-fix 2 + nh 2 + lr 2 (= a493861afdfd58d95) + round 2 attempt hang 22m 55s cancel (= task-mpjuqshs-fyavhn) + round 2 retry --fresh = revise must-fix 3 (= diff 未反映 = 計画書 review か実反映 review かの解釈ズレ、 main agent 自律判断「計画書 review、 ADR 反映は PR2 commit で実施」、 a18ab6af2bce91b3b)、 越権操作なし confirmed、 機械復旧 default rule 適用 (= [[long-running-hang-auto-recovery-rule]] 初実証)) | (= 本 PR2 commit chain 内) |
| 2026-05-25 | 40th session | ADR-0068 α scope 再定義 plan v6-revised → v7 (= self-test 完走 + driver source ground truth 4 件 finding 確定後 user 明示 option 4 採用 = driver line 1741-1888 で A-J 10 part 常に test01/test02 default 駆動 / K+L-Q 7 part のみ PMDNEO_USE_PMDDOTNET 切替で pmddotnet_song 由来、 全 (A)/(B)/(C-1)/(C-2) build mode で A-J candidate dispatch 不可、 plan v6-revised hybrid 原則 sub-section = unused 化 (= 不足 4 ch FM E/F + SSG G/H は default driven で常時 carry、 minimal MML 不要)、 §決定 1(a) driver source dispatch ground truth + 全 build mode carrier 差分 table + 40th session self-test actual trace literal + K=3 candidate plan v7 update literal 追記、 §決定 2 α/β/γ row plan v7 = K+L-Q distinctness capture + A-J default integration trace / 三分割 wording 必須、 §決定 6 表記制約 plan v7 = 「K+L-Q candidate distinctness 完了」 + 「A-J default carry 確認」 + 「16ch integration trace 完了」 = ε Accepted 後解禁 + 併記必須、 「16ch full candidate distinctness 完了」 = literal 禁止維持 (= ADR-0069 候補 future)、 §決定 9 ADR-0069 候補 = driver 拡張 sprint literal 追加。 verify script bug fix 4 件 (= 全角 「、」 4 件 + printf 「-」 escape + CRLF on-the-fly 変換 helper + detect_adpcma reg 100 = 3 桁 hex 修正) + assertion softening (= α scope = capture + report only literal 整合)。 機械復旧 default rule (= [[long-running-hang-auto-recovery-rule]]) 適用 = Codex round 2 hang 22m 55s cancel + retry / verify script bug 4 件 cancel + retry chain、 user 介入 = 設計判断 (= hybrid → option 2 → option 4) のみ。 plan v7 scope 縮小 (= 16/16 carry → K+L-Q distinctness focus) ただし 16ch 方針自体は維持 (= ADR-0069 候補で完成、 ADR-0068 scope の 16ch integration trace は actual 達成) | (= 本 PR2 commit chain 内、 commit 66f8b6f / 0613e5a / 38444a4 / b2767aa / c36301f 経由) |
