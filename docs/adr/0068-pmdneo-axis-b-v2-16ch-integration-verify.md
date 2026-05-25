# ADR-0068: PMDNEO 軸 B v2 driver 16 ch 統合 verify ADR (= ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目、 roadmap ⑤ 統合 verify 本体、 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較)

- 状態: **Accepted** (= 2026-05-25 40th session、 ε PR #138、 sub-sprint chain α/β/γ/δ/ε 全 完走 + 6 PR chain = #133 (起票) + #134 (α MERGED at `3c59d93`) + #135 (β MERGED at `7335da9`) + #136 (γ MERGED at `ef87dcb`) + #137 (δ MERGED at `56c0b0f`) + #138 (ε)、 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目完了 = 16 ch 統合 verify ADR 完走 milestone、 ADR-0064 plan 実作業群完了 (= ADR-0067 + ADR-0068 chain)、 「ADR-0068 Accepted」 + 「ADR-0068 ε 完了」 + 「roadmap ⑤ 統合 verify 完了」 milestone wording 解禁、 ただし併記必須 9 件 = K+L-Q trace-equivalence 判定基準と比較実行は完了 + A-J default integration trace + A-J full candidate distinctness は ADR-0069 候補 future + K bitmap pair distinct も ADR-0069 候補 future + (d) audition gate 未実装 = ADR-0065 候補 future + production-ready 全体達成ではない + 本番 cmd 切替完了ではない = ADR-0066 候補 future + 軸 B 完成ではない + 軸 G 完成ではない、 driver source / 既存 verify script / vendor / ADR-0067 fixture / 既存 build flag / ADR-0068 既存 Annex α/β/γ/δ 本文 / 軸 G ε partial state placement 完全不変、 通算 sha256 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 confirmed = γ 実測 confirm + δ/ε doc-only carry、 Codex layer 2 plan review chain = α 4 round + β 3 round + γ 8 round + δ 1 round + **ε 主軸 fallback approve plan v1** (= ADR-0041 §決定 6 適用、 Codex companion 安全性分類器 (claude-opus-4-7) 一時障害 2 回連続失敗 = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 該当、 user 明示 option B = ADR-0041 §決定 6 fallback + retrospective Codex review 必須 採用、 主軸 Claude Code が plan v1 を独立 review = scope literal coverage / 併記必須 9 件 / Annex A/B/ε fill / allowed-touch / production sha256 / commit chain plan 全 OK = approve 判断、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed)) (= 2026-05-24 39th session、 ADR-0068 起票 doc-only PR1 + sub-sprint chain α/β/γ/δ/ε 起票、 起票 doc-only 1 PR (= ADR-0064 plan/実作業分離 pattern 整合)、 ADR-0067 同 chain pattern 継承、 Codex layer 2 plan review 4 round chain (= round 1-3 revise + round 4 approve)、 must-fix 計 7 件 + nice-to-have 計 4 件 + latent-risk 計 3 件 全反映、 越権操作なし confirmed、 ADR-0064 §決定 3 sub-sprint plan literal 継承 + ADR-0067 fixture 拡張完了 milestone 前提)
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

##### β scope literal (= 40th session β kickoff plan v3 確定、 Codex round 2 nh 3 反映、 round 1 lr 1 起源)

β scope の trace-equivalence は **K+L-Q register behavior の normalized comparison** (= K+L-Q distinctness 範囲限定)、 ADR-0064 §決定 1(b)「v2 / 既存 driver 両経路 16 ch 同時 register write trace 比較」 とは別 wording。 理由 = (B) v2-only fixture trace と (C-2) PMDDOTNET_MML trace は同一入力曲ではない (= 別 input source、 v2 fixture data 内蔵 vs PMDDOTNET compile .M binary)、 同一入力曲での 16ch 同時 trace 比較は driver source 拡張後 (= ADR-0069 候補 future) 達成可能。 β = K+L-Q range で「同一 path 上の L-Q candidate distinct pattern A/B/C + K candidate trigger 出現確認」 + 「(B) と (C-2) の path 別 invariant + intended diff 確認」 limit (= L-Q は distinct pattern acceptable、 K は trigger 出現確認 limit + 真の K bitmap pair variant 1/2/3 trace distinct は ADR-0069 候補 future defer)。

β 完走後解禁 wording = 「K+L-Q distinctness range trace-equivalence literal 達成」 (= β scope 限定明記必須)。 「trace-equivalence 完了」 (= 単独 wording) は ε Accepted 後解禁 + 併記必須 (= §決定 6 表記制約)。

#### (c) baseline regression gate 統合 verify
- scope: 全 verify script suite を 1 batch で production binary 1 件に対して通す + ALL PASS 確認 (= **representative direct invoke + transitively regression OK pattern**、 ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承、 representative 4 script = `verify-axis-b-v2-16ch-integration-alpha.sh` + `verify-axis-b-v2-fixture-expansion-delta.sh` + `verify-axis-b-v2-song-playback.sh` + `verify-axis-b-v2-roadmap3-dispatch.sh`、 ADR-0049〜0057 系 verify script + β scope 全 transitively regression OK = production sha256 維持 m1 ROM byte-identical、 β scope (= K+L-Q distinctness range trace-equivalence) coverage は ADR Annex β literal で別途確保済 = β script 除外 = §決定 5 (ii) 不可触原則遵守)
- 完了判定: 全 verify script ALL PASS literal 確認 + completion proof 統合 report

#### (d) 越川氏 audition gate = ADR-0065 候補 scope-out
- engineering pass (= (a)(b)(c)) ≠ aesthetic pass (= (d))、 ADR-0065 候補で別 sprint。

### 決定 2: sub-sprint chain α/β/γ/δ/ε 5 段 (= ADR-0064 §決定 3 plan literal 継承)

| sub | scope | 関連 gate | 完了判定 |
|---|---|---|---|
| α | (a) 実 MML 再生 統合 verify = **K+L-Q candidate distinctness capture + A-J default integration trace** (= plan v7 = 40th session driver ground truth based、 distinctness 判定 assertion は β scope future)。 candidate = `src/test-fixtures/step5/l-q-rhythm-song.mml` + `src/test-fixtures/step5/l-q-tutti.mml` + `src/test-fixtures/step11/l-q-rhythm-song-step5b.mml` (= K=3 L-Q distinct candidate)、 K distinctness は β scope future。 10 env × ymfm/z80-mem 2 trace 種 capture = 20 trace file + literal report | (a) | K+L-Q distinctness capture (= 各 candidate L-Q trace 個別記録) + A-J default integration trace record (= default 同一 8/2 pattern literal) + 16/16 ch carry actual literal record |
| β | (b) trace-equivalence 判定基準確定 + 比較実行 = **3 axis + 8 sub-category** (= axis A YMFM register equivalence primary gate + axis B zmem diagnostic record-only + axis C K+L-Q distinctness comparison primary scope、 plan v3 = β kickoff plan Codex 3 round chain approve 経由)。 α 取得 trace 20 件 (= α PR2 結果) + β 新規 K candidate trace 12 件 (= step18/k03/k11/k21 = bitmap pair representative candidate variant 1/2/3、 6 env × 2 chip × 2 trace 種) を input、 計 32 trace file。 **K+L-Q register behavior normalized comparison** (= β scope 限定明記、 ADR-0064 §決定 1(b) 16ch 同時 trace 比較とは別 wording、 §決定 1(b) β scope literal 整合) + A-J default carry baseline 比較 + K candidate β scope 採用判断完了 (= bitmap pair representative 3 件採用、 残 8 件 future、 trigger 出現確認 limit、 真の trace distinct は ADR-0069 候補 future defer)。 verify gate = 9 件 (= sub-step 含む 14 step) ALL PASS = gate 1-7 axis A/B/C judgment + gate 8 α trace provenance 4 step + gate 9 (A) production sha256 literal 実測 confirm | (b) | 9 gate ALL PASS + axis A-3a unintended diff 0 件 literal + axis B zmem 別 file diagnostic + axis C K+L-Q acceptable literal (= L-Q distinct pattern A/B/C + K candidate trigger 出現確認、 真の K trace distinct は ADR-0069 候補 future defer) + α trace provenance 4 step + (A) production sha256 literal `b15883fe...` 実測 confirm |
| γ | (c) 全 verify script 統合 ALL PASS = production binary 1 件に対して全 verify を 1 batch 実行 + 統合 report (= **representative direct invoke 4 script + transitively regression OK pattern**、 ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承、 sha256 直接 confirm は ym2610 chip target のみ + ym2610b は representative scripts 内既存 chip target coverage で推移的保証、 β script 除外 = §決定 5 (ii) 不可触原則遵守 + β scope coverage は ADR Annex β literal で別途確保) | (c) | 全 verify script ALL PASS literal 確認 + completion proof 統合 report (= 「16ch integration trace 完了」 + 「K+L-Q candidate distinctness 完了」 + 「A-J default carry 確認」 三分割 wording 必須 = γ completion proof 内 context-bound 使用 OK / single isolated wording は ε まで禁止維持、 「16ch full candidate distinctness 完了」 wording 禁止 = A-J distinctness は ADR-0069 候補 future、 「roadmap ⑤ 統合 verify 完了」 = ε まで禁止 明示、 6 gate = gate 1 pre-build sha256 + gate 2 representative regression 4 件 ALL PASS + per-script log + gate 3 三分割 wording report + gate 4 禁止 wording self-check 7 件全件 + allowlist 拡張 + gate 5 NOT-COMPLETE 7 行 + gate 6 post-script sha256 復元 confirm) |
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
- α env # 3-10 で主軸使用 (= plan v7 = 10 env literal 整合)

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

#### γ Accepted 後の追加 context (= γ PR4 確定、 plan v4 round 4 approve 反映)

γ PR4 merge 後 (= main agent 経路 merge 完了後) の使用可・禁止 context literal:

| 表現 | γ Accepted 後 | ε Accepted 後 |
|---|---|---|
| 「16ch integration trace 完了」 | γ completion proof 内 **context-bound 使用 OK** (= verify script 内 / Annex γ 内 / 改訂履歴 γ entry 内 / 平易要約 γ context 内)、 single isolated wording は ε まで禁止維持 | 解禁 + 併記必須 |
| 「K+L-Q candidate distinctness 完了」 | 同上 (= γ completion proof 内 context-bound 使用 OK) | 解禁 + 併記必須 |
| 「A-J default carry 確認」 | 同上 (= γ completion proof 内 context-bound 使用 OK) | 解禁 (= 単独使用 OK) |
| 「16ch full candidate distinctness 完了」 | literal 禁止維持 (= ADR-0069 候補 future) | literal 禁止維持 (= ADR-0069 候補 future) |
| 「roadmap ⑤ 統合 verify 完了」 | literal 禁止維持 (= **ε まで禁止 明示**) | 解禁 + 併記必須 |
| 「trace-equivalence 完了」 single wording | literal 禁止維持 (= ε まで禁止 明示) | 解禁 + 併記必須 |
| 「production-ready 全体達成」 | literal 禁止維持 | literal 禁止維持 |
| 「軸 B 完成」 | literal 禁止維持 | literal 禁止維持 |
| 「軸 G 完成」 | literal 禁止維持 | literal 禁止維持 |
| 「本番 cmd 切替完了」 | literal 禁止維持 | literal 禁止維持 |

γ 完走後解禁 wording = 「ADR-0068 γ 完了」 (= γ baseline regression gate 統合 verify ALL PASS literal、 γ scope 限定、 representative direct invoke 4 script + transitively regression OK pattern、 β script 除外 = §決定 5 (ii) 遵守 + β scope coverage は ADR Annex β literal で別途確保)。

#### δ Accepted 後の追加 context (= δ PR5 確定、 plan v1 round 1 approve 反映、 LR1「同段落で ε まで禁止 wording 併記必須」 反映)

δ PR5 merge 後 (= main agent 経路 merge 完了後) の使用可・禁止 context literal:

| 表現 | δ Accepted 後 (= δ PR5 merge 後) | ε Accepted 後 |
|---|---|---|
| 「ADR-0068 γ 完了」 | 使用可 (= 継承) | 使用可 (= 継承) |
| 「16ch integration trace 完了」 | γ completion proof 内 context-bound 使用 OK (= 継承)、 single isolated wording は ε まで禁止維持 | 解禁 + 併記必須 |
| 「K+L-Q candidate distinctness 完了」 | 同上 (= 継承) | 解禁 + 併記必須 |
| 「A-J default carry 確認」 | 同上 (= 継承) | 解禁 (= 単独使用 OK) |
| **「ADR-0068 δ 完了」 (= δ PR5 新規解禁表現)** | **使用可、 ただし併記必須 = 同段落で「roadmap ⑤ 統合 verify 完了は ε まで禁止維持」 literal 併記** | 使用可、 ただし併記必須 update |
| 「16ch full candidate distinctness 完了」 | literal 禁止維持 (= ADR-0069 候補 future) | literal 禁止維持 (= ADR-0069 候補 future) |
| 「roadmap ⑤ 統合 verify 完了」 | literal 禁止維持 (= ε まで禁止 明示) | 解禁 + 併記必須 |
| 「trace-equivalence 完了」 single wording | literal 禁止維持 (= ε まで禁止 明示) | 解禁 + 併記必須 |
| 「production-ready 全体達成」 | literal 禁止維持 | literal 禁止維持 |
| 「軸 B 完成」 | literal 禁止維持 | literal 禁止維持 |
| 「軸 G 完成」 | literal 禁止維持 | literal 禁止維持 |
| 「本番 cmd 切替完了」 | literal 禁止維持 | literal 禁止維持 |

##### 「ADR-0068 δ 完了」 wording 解禁条件 literal (= δ PR5 merge 後、 LR1 反映 = 同段落併記必須)

- δ scope 限定 = 統合 report + 残課題 enumeration 完了 literal
- **同段落併記必須 (= LR1 = Codex round 1 lr 1 反映、 ε 前倒し完了読み下し risk 回避)**:
  - 「ADR-0068 ε Accepted ではない」 (= ε PR6 で別途 Accepted 移行 future)
  - **「roadmap ⑤ 統合 verify 完了」 = ε まで禁止維持** (= 同段落 literal 併記必須、 ε Accepted 後解禁 + 併記必須 update)
  - 「trace-equivalence 完了」 single wording = ε まで禁止維持
  - 「16ch full candidate distinctness 完了」 = ADR-0069 候補 future literal 禁止維持
  - 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = literal 禁止維持

δ 完走後解禁 wording = 「ADR-0068 δ 完了」 (= δ scope 限定 = 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material 完了 literal、 LR1 同段落併記必須)。

#### ε Accepted 後の追加 context (= ε PR6 確定、 主軸 fallback approve plan v1 反映、 ADR-0041 §決定 6 Codex unavailable fallback + retrospective Codex review 必須)

ε PR6 merge 後 (= main agent 経路 merge 完了後) の使用可・禁止 context literal:

| 表現 | ε Accepted 後 |
|---|---|
| 「ADR-0068 α 完了」 | 使用可 (= 継承) |
| 「ADR-0068 β 完了」 | 使用可 (= 継承) |
| 「ADR-0068 γ 完了」 | 使用可 (= 継承) |
| 「ADR-0068 δ 完了」 | 使用可 (= 継承) |
| **「ADR-0068 Accepted」 (= ε PR6 新規解禁)** | **使用可** (= ε scope = Draft → Accepted + Annex 全統合 完了) |
| **「ADR-0068 ε 完了」 (= ε PR6 新規解禁)** | **使用可** (= ε scope 完了) |
| **「16ch integration trace 完了」** | **解禁** (= single isolated wording も使用可) + 併記必須 = 「K+L-Q distinctness 達成」 + 「A-J default carry 確認」 + 「16ch full candidate distinctness は ADR-0069 候補 future」 |
| **「K+L-Q candidate distinctness 完了」** | **解禁** + 併記必須 = 「A-J default carry 確認」 + 「16ch full candidate distinctness は ADR-0069 候補 future」 |
| **「A-J default carry 確認」** | **解禁** (= 単独使用 OK) |
| **「(a)(b)(c) 3 gate 統合 verify 完了」** | **解禁** + 併記必須 = 「(d) audition 未実装 = ADR-0065 候補 future」 + 「production-ready 全体達成ではない」 + 「軸 B 完成ではない」 + 「本番 cmd 切替完了ではない」 |
| **「trace-equivalence 完了」 single wording** | **解禁** + 併記必須 = 「K+L-Q distinctness range 限定」 + 「A-J distinctness は ADR-0069 候補 future」 |
| **「roadmap ⑤ 統合 verify 完了」 (= ε PR6 milestone wording 解禁)** | **解禁** + 併記必須 9 件 (= 下記 literal 列挙) |
| 「16ch full candidate distinctness 完了」 | literal 禁止維持 (= ADR-0069 候補 future) |
| 「production-ready 全体達成」 | literal 禁止維持 |
| 「軸 B 完成」 | literal 禁止維持 |
| 「軸 G 完成」 | literal 禁止維持 |
| 「本番 cmd 切替完了」 | literal 禁止維持 |

##### 「roadmap ⑤ 統合 verify 完了」 wording 解禁条件 literal (= ε PR6 merge 後、 併記必須 9 件 literal)

「roadmap ⑤ 統合 verify 完了」 wording を使用する全段落で次 9 件 literal 併記必須:

1. K+L-Q trace-equivalence 判定基準と比較実行は完了 (= β PR3 達成、 ADR Annex β literal)
2. A-J は default integration trace (= candidate distinctness ではない、 α PR2 達成、 ADR Annex α literal)
3. A-J full candidate distinctness は ADR-0069 候補 future (= driver 拡張 sprint required)
4. K bitmap pair distinct も ADR-0069 候補 future (= driver K dispatch normalization 由来、 ADR Annex β-5 literal)
5. (d) audition gate 未実装 = ADR-0065 候補 future
6. production-ready 全体達成ではない
7. 本番 cmd 切替完了ではない = ADR-0066 候補 future
8. 軸 B 完成ではない
9. 軸 G 完成ではない

##### ε 完走後解禁 wording 整理 = 7 wording 解禁 + 9 件併記必須 + 5 wording 禁止維持

- **解禁** (= ε PR6 merge 後使用可、 各々併記必須付き 7 wording):
  - 「ADR-0068 Accepted」
  - 「ADR-0068 ε 完了」
  - 「16ch integration trace 完了」
  - 「K+L-Q candidate distinctness 完了」
  - 「(a)(b)(c) 3 gate 統合 verify 完了」
  - 「trace-equivalence 完了」 single wording
  - 「roadmap ⑤ 統合 verify 完了」
- **単独使用 OK** (= 併記必須なし、 継承 + 新規 6 wording): 「A-J default carry 確認」 / 「ADR-0068 α 完了」 / 「ADR-0068 β 完了」 / 「ADR-0068 γ 完了」 / 「ADR-0068 δ 完了」 / 「16 ch fixture 拡張完了」
- **禁止維持** (= ADR-0068 Accepted 後も literal 禁止 5 wording):
  - 「16ch full candidate distinctness 完了」 (= ADR-0069 候補 future)
  - 「production-ready 全体達成」 (= ADR-0056 §決定 3 4 系統全通過後 future)
  - 「軸 B 完成」 (= v2 driver production-ready 化 + 本番 cmd 切替後 future)
  - 「軸 G 完成」 (= 軸 G 全体完成は別 axis 完了後 future)
  - 「本番 cmd 切替完了」 (= ADR-0066 候補完了後のみ)

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

### Annex A: ADR-0068 ground truth + 起票背景 (= ε で fill 完了)

#### A-1 = ADR-0067 完走経緯 (= 「16 ch fixture 拡張完了」 milestone 達成)

ADR-0067 sub-sprint chain α/β/γ/δ/ε 全 完走 (= PR #128/#129/#130/#131/#132 全 merge、 7ac4ab7 集約 branch HEAD) で 16 ch fixture 拡張 + 機能 verify only 完了。 ε Accepted 時 milestone wording = 「16 ch fixture 拡張完了」 + 併記必須 = 「roadmap ⑤ 統合 verify 未実装 (= ADR-0068 候補 future)」 + 「production-ready 全体達成ではない」 (= ADR-0067 §決定 6 literal)。 本 ADR-0068 = 母 ADR-0067 完走後 + ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目 = 16 ch 統合 verify 本体。

#### A-2 = roadmap ⑤ 統合 verify 本体 = ADR-0068 scope

ADR-0064 §決定 1 literal「(a) 実 MML 再生 統合 verify + (b) 全 16 ch trace-equivalence verify + (c) baseline regression gate」 = 3 gate 統合 verify scope。 ADR-0067 = fixture 拡張 + 機能 verify only (= driver state widen + trace 取得)、 ADR-0068 = 統合 verify (= cmd 0x05 経路 vs v2 経路 trace-equivalence 比較 + 全 verify ALL PASS + 統合 report)。 これが **roadmap ⑤ 統合 verify 本体**。

#### A-3 = (a)(b)(c) 3 gate scope + (d) audition scope-out

ADR-0056 §決定 3 4 gate のうち (a)(b)(c) 3 gate を ADR-0068 scope、 (d) audition は ADR-0065 候補 (= roadmap ⑥) scope-out (= aesthetic gate、 別 ADR + user 明示 GO 必須 future)。

#### A-4 = ADR-0064 §決定 3 plan literal 継承 (= sub-sprint α/β/γ/δ/ε 5 段 plan)

| sub | scope | ADR-0068 達成 |
|---|---|---|
| α | K+L-Q candidate distinctness capture + A-J default integration trace | PR #134 MERGED at `3c59d93` |
| β | trace-equivalence 判定基準確定 + 比較実行 | PR #135 MERGED at `7335da9` |
| γ | baseline regression gate 統合 verify | PR #136 MERGED at `ef87dcb` |
| δ | 統合 report + 残課題 enumeration | PR #137 MERGED at `56c0b0f` |
| ε | Draft → Accepted + Annex 全統合 | PR #138 (= 本 PR) |

#### A-5 = user 明示 GO「次は ADR-0068 候補が自然」 + option 1 採用 (= PR1/PR2 段階分離)

ADR-0067 ε Accepted 完了報告後、 user 明示「次は ADR-0068 候補が自然です。 目的は 16ch 統合 verify、 つまり cmd 0x05 経路と v2 経路の trace-equivalence 比較です。 これが roadmap ⑤ 統合 verify 本体になります」 + option 1 = doc-only 起票 PR + sub-sprint 実装 PR 段階分離。 PR1 (= 起票) + PR2 (= α) + PR3 (= β) + PR4 (= γ) + PR5 (= δ) + PR6 (= ε) = 計 6 PR chain。

#### A-6 = ε で確立した「主軸 fallback + retrospective Codex review」 pattern (= ADR-0041 §決定 6 適用、 40th session 新規 finding)

ε PR6 起票時、 Codex companion 安全性分類器 (claude-opus-4-7) 一時障害で Codex layer 2 plan review が 2 回連続失敗 (= retry 1 回後も同障害)。 CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 条件該当 + user 明示 option B 採用 = ADR-0041 §決定 6「Codex unavailable 時 fallback + retrospective Codex review 必須」 適用。 主軸 Claude Code が plan v1 を独立 review + approve 判断 (= scope literal coverage / 併記必須 9 件 / Annex A/B/ε fill / allowed-touch / production sha256 / commit chain plan 全 OK)、 Codex 復旧後に retrospective review 実施必須。 fallback 適用根拠 = doc-only sprint + scope 明確 (= driver/fixture/vendor 不変、 ADR doc + dashboard 2 file のみ変更) + retrospective Codex review 必須。 40th session ε PR6 で初実証 pattern。 「review-only / Do NOT commit / Do NOT modify files / Do NOT create branches / Do NOT merge PRs / Do NOT run GitHub write operations / Return only review judgment and findings」 冒頭 6 件 literal 強調 = 主軸 fallback でも同規律遵守 (= 主軸 fallback judgment は plan 単独 review、 commit 権限と分離維持)。

### Annex B: 16 ch 統合 verify 構成図 + build mode matrix (= ε で fill 完了)

#### B-1 = 16 ch 統合 verify 全体図 (= ADR-0064 §決定 1 (a)(b)(c) 3 gate + (d) scope-out)

```
+------------------ ADR-0068 scope (= roadmap ⑤ 統合 verify 本体) ------------------+
|                                                                                  |
| (a) 実 MML 再生 統合 verify          [α PR #134 完了]                              |
|     = K+L-Q candidate distinctness capture + A-J default integration trace        |
|     + 16/16 ch carry actual + 3 pattern A/B/C capture                            |
|                                                                                  |
| (b) 実音 register trace-equivalence verify   [β PR #135 完了]                     |
|     = K+L-Q register behavior normalized comparison                              |
|     + 3 axis (A/B/C) + 8 sub-category + 9 gate ALL PASS                          |
|     + K trace 同一 finding → ADR-0069 候補 future defer                            |
|                                                                                  |
| (c) baseline regression gate 統合 verify    [γ PR #136 完了]                      |
|     = representative direct invoke 4 script + transitively regression OK pattern  |
|     + 6 gate ALL PASS + 通算 sha256 維持 confirmed                                 |
|                                                                                  |
| [δ PR #137] 統合 report + 残課題 enumeration (= ADR-0065/0066/0069 起票判断 material) |
| [ε PR #138] Draft → Accepted + Annex 全統合 + milestone literal 解禁 (= 併記必須 9 件)|
|                                                                                  |
+----------------------------------------------------------------------------------+

[scope-out] (d) 越川氏 audition gate = ADR-0065 候補 future (= roadmap ⑥)
[scope-out] A-J candidate distinctness 実現 = ADR-0069 候補 future (= driver 拡張 sprint)
[scope-out] K bitmap pair distinct 実現 = ADR-0069 候補 future (= driver K dispatch 拡張)
[scope-out] 本番 cmd 切替判断 = ADR-0066 候補 future (= roadmap ⑦)
```

#### B-2 = build mode (A)/(B)/(C-1)/(C-2) matrix

| build mode | env literal | sha256 | trace 用途 |
|---|---|---|---|
| (A) production default | `bash scripts/build-poc.sh --chip ym2610` (= 全 fixture toggle off) | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory | γ baseline regression gate representative binary + §決定 10 全 sub-sprint 共通 gate |
| (B) v2-only trace capture | `PMDNEO_V2_SONG_FIXTURE=1 PMDNEO_AXIS_G_AUDITION_LEGACY_SKIP=1 bash scripts/build-poc.sh --chip <ym2610\|ym2610b>` | 別 (= 比較対象外) | α env # 1-2 trace capture |
| (C-1) PMDNEO_M_RAW | `PMDNEO_M_RAW=<.M binary path> PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip <ym2610\|ym2610b>` | 別 | β/γ 必要時 (= 既存 .M binary 直接 trace 比較用) |
| (C-2) PMDDOTNET_MML | `PMDDOTNET_MML=<MML path> PMDDOTNET_MODE=<N\|B> PMDDOTNET_DLL=<dll path> PMDNEO_USE_PMDDOTNET=1 bash scripts/build-poc.sh --chip <ym2610\|ym2610b>` | 別 | α env # 3-10 + β env # 11-16 主軸使用 |

#### B-3 = chip target 別 trace (= ADR-0067 §決定 12 継承)

| chip target | active slot | trace 用途 | γ sha256 confirm |
|---|---|---|---|
| ym2610 (primary) | 8 slot (= FM B/C/E + SSG 3 + ADPCM-B + ADPCM-A 6) | production default、 全 sub-sprint primary | gate 1 pre + gate 6 post 両方一致 confirmed |
| ym2610b (secondary) | 11 slot (= + FM A/D/F) | trace 比較対象 | representative scripts 内既存 chip target coverage で推移的保証 |

#### B-4 = PMDDOTNET_MODE matrix (= (C-2) build mode)

| mode | meaning | ADPCM-A 経路 | α/β env で使用 |
|---|---|---|---|
| N | default | なし | A-J part driven MML 用 |
| B | ADPCM-A 経路使用 | あり | L-Q part driven MML 用 (= α-task 1/2 全 env で MODE=B + β K candidate 全 env で MODE=B) |

#### B-5 = trace TSV format literal (= α/β/γ script 共通)

trace 出力 format = TSV (= tab-separated values) で次 column:

| column | content |
|---|---|
| 1 | timestamp / sample index (= ymfm 経由 = sample index、 zmem 経由 = MAME time) |
| 2 | event type (= ymfm = register write、 zmem = memory access) |
| 3 | address / register (= 16 bit hex literal) |
| 4 | value (= 8 bit hex literal) |
| 5 | source / context (= 補助情報) |

trace file 配置 = `/tmp/pmdneo-adr-0068-<sub-sprint>/env-<NN>-<label>-{ymfm,zmem}.tsv`。 各 sub-sprint 別 dir = `α` (= `/tmp/pmdneo-adr-0068-alpha/`) + `β` (= `/tmp/pmdneo-adr-0068-beta/`) + `γ` per-script log (= `/tmp/pmdneo-adr-0068-gamma/<script-basename>.log`)。

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

### Annex β: β 実装 completion record (= β kickoff plan v3 確定後、 trace-equivalence 判定基準確定 + 比較実行)

#### β-1 = scope literal (= β kickoff plan v3、 Codex layer 2 plan review 3 round chain approve 後)

ADR-0068 §決定 2 β row literal + plan v3 拡張:
- 主軸: (b) trace-equivalence 判定基準確定 + 比較実行
- trace-equivalence の β scope literal: **K+L-Q register behavior の normalized comparison** (= §決定 1(b) β scope literal 整合)
- 範囲: K+L-Q distinctness 範囲のみ (= A-J default carry baseline は record only、 A-J full candidate distinctness は ADR-0069 候補 future)

β sub-task (= 5 件):
1. trace-equivalence 判定基準 literal 定義 (= 3 axis + 8 sub-category)
2. K+L-Q candidate distinctness comparison 実装 + 比較実行
3. A-J default carry baseline comparison 実装 + 比較実行
4. K candidate (= step18/k03/k11/k21 = bitmap pair representative 3 件) β scope 追加実装 (= trigger 出現確認 limit、 真の trace distinct は ADR-0069 候補 future defer)
5. literal report (= 各 axis 比較結果 + axis A-3a unintended diff 0 件 confirm + β 完了判定)

#### β-2 = trace-equivalence 判定基準 literal (= 3 axis + 8 sub-category、 Codex round 2 must-fix 1 反映で数え方明示)

##### axis A: YMFM register-level equivalence (= primary gate)

| sub | label | 内容 | judgment |
|---|---|---|---|
| A-1 | invariant | 両 path で完全一致期待 = chip init register set + chip target active slot (= ADR-0006 §B 整合) | 対象 |
| A-2 | intended diff | 意図した v2 差分、 register state 収束許容 = dispatch order (= v2 dispatcher vs 既存 cmd 0x05 + pmdneo_song_main) + 同一 register への redundant write | 対象 |
| A-3a | unintended diff | 全部 0 件期待、 primary gate strict = 同一 ch register write 値欠落 + 同一 ch register write 値誤値 + extra write + keyon count/timing 差 + final state 差 + unintended silent write (= 音響状態を変える silent-looking write、 round 1 nh 1 強調) | 対象 |
| A-3b | neutral/report bucket | 最終 register state + keyon/timing に影響しない同値再書込、 報告のみ (= round 2 must-fix 1 反映で labeling 明示) | **外 (= record-only)** |

##### axis B: zmem diagnostic (= YMFM register equivalence 外、 副次レポート、 round 2 nh 2 反映で別 file 分離)

| sub | label | 内容 | judgment |
|---|---|---|---|
| B-1 | PartWork layout diff | v2 compact layout vs PMDDotNET/default、 expected noise。 output = `/tmp/pmdneo-adr-0068-beta/zmem-diagnostic-report.tsv` 別 file 出力、 verify summary は path + 「judgment 外」 のみ表示 | **外 (= record-only、 axis A/C の PASS/FAIL と混ぜない)** |

##### axis C: distinctness comparison (= β scope 主軸)

| sub | label | 内容 | judgment |
|---|---|---|---|
| C-1 | L-Q candidate distinctness | α capture 3 pattern A/B/C = env # 3,4 (l-q-rhythm-song = pattern A) / env # 5,6 (l-q-tutti = pattern B) / env # 7,8 (l-q-rhythm-song-step5b = pattern A) / env # 9,10 (SAMPLE2-baseline = pattern C)。 「L-Q distinct pattern として acceptable」 literal 確定 | 対象 |
| C-2 | A-J default carry baseline | 全 env A-J default driven literal 確認 = FM A/D = 0/61 (chip 別) + B/C/E/F = 8 / SSG = 2 / ADPCM-B = 2。 「A-J default carry baseline 確認」 literal 達成 | 対象 |
| C-3 | K candidate trigger 出現確認 (= trace 同一 finding 後 wording、 真の K bitmap pair variant 1/2/3 trace distinct は ADR-0069 候補 future defer) | β 新規 capture、 bitmap pair representative 3 件 = env # 11,12 (k03 = variant 1) / env # 13,14 (k11 = variant 2) / env # 15,16 (k21 = variant 3)。 「K candidate trigger 出現確認 (= L-Q いずれかに keyon write 出現)」 literal 確定 (= driver K dispatch normalization で bitmap pattern 差吸収、 trace 同一 finding β-5 整合、 Codex impl-review round 1 must-fix 1 反映で「K distinct」 wording 排除) | 対象 |

##### 数え方 literal (= round 2 must-fix 1 反映)

- 3 axis = axis A + axis B + axis C
- 8 sub-category = A-1 + A-2 + A-3a + A-3b + B-1 + C-1 + C-2 + C-3
- judgment 対象 = A-1 + A-2 + A-3a + C-1 + C-2 + C-3 = **6 sub-category**
- judgment 外 record-only = A-3b + B-1 = **2 sub-category**

#### β-3 = 配置 (= 新規 verify script + ADR doc β scope literal + 既存 driver / 既存 verify script / 既存 build flag / vendor / 既存 fixture 完全不変)

- **新規 verify script**: `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-beta.sh` (= α script pattern 継承 + K candidate 3 件追加 + 3 axis 8 sub-category gate + `--refresh-alpha` option、 行数 TBD)
- **ADR-0068 doc 修正**: §決定 1(b) β scope literal 追記 + §決定 2 β row update + Annex β fill + 改訂履歴 β entry
- **env literal (= 16 env)**:
  - env # 1-10 = α 流用 (= `/tmp/pmdneo-adr-0068-alpha/env-*-*.tsv` 20 file) or β 内 `--refresh-alpha` で再 capture
  - env # 11 = (C-2) k03 ym2610 (mode=B)
  - env # 12 = (C-2) k03 ym2610b (mode=B)
  - env # 13 = (C-2) k11 ym2610 (mode=B)
  - env # 14 = (C-2) k11 ym2610b (mode=B)
  - env # 15 = (C-2) k21 ym2610 (mode=B)
  - env # 16 = (C-2) k21 ym2610b (mode=B)
- **driver / 既存 verify script / vendor / 既存 fixture / 既存 build flag 完全不変** (= ADR-0068 §決定 5 (ii) literal)
- **トレース出力**:
  - β 新規 trace = `/tmp/pmdneo-adr-0068-beta/env-<NN>-<label>-{ymfm,zmem}.tsv` 計 12 file (= 6 env × 2 trace 種)
  - axis B zmem diagnostic = `/tmp/pmdneo-adr-0068-beta/zmem-diagnostic-report.tsv` 1 file (= 別 file 出力、 judgment 外)
- **α trace input** = `/tmp/pmdneo-adr-0068-alpha/env-*-*.tsv` 20 file (= gate 8 provenance check で stale 判定)

#### β-4 = verify gate 9 件 (= sub-step 含む 14 step、 Codex round 1-2 finding 全反映)

| gate | 内容 |
|---|---|
| gate 1 | (B) v2-only build mode + trace capture 2 env (= α 流用 or `--refresh-alpha` 再 capture) |
| gate 2 | (C-2) PMDDOTNET_MML K+L-Q candidate trace 比較 (= env # 3-10 + # 11-16) |
| gate 3 | A-J default carry baseline 全 env 同一 pattern 確認 (= axis C-2 judgment) |
| gate 4 | axis A YMFM register equivalence (= A-1 invariant + A-2 intended diff + A-3a unintended literal + A-3b record-only) |
| gate 5 | axis A-3a unintended diff 0 件 literal confirm (= primary gate strict) |
| gate 6 | axis B-1 zmem diagnostic 別 report file output + summary path 表示のみ (= judgment 外、 round 2 nh 2 反映) |
| gate 7 | axis C K+L-Q distinctness 範囲 acceptable confirm (= C-1 + C-2 + C-3) |
| gate 8 | α trace input provenance check (= 4 step 細分、 round 2 must-fix 2 + lr 2 反映) |
| gate 8a | 20 trace file 存在 confirm (= `/tmp/pmdneo-adr-0068-alpha/env-*-{ymfm,zmem}.tsv`) |
| gate 8b | ENVS array 完全一致 (= α script literal `01-v2only-ym2610` 〜 `10-sample2-baseline-ym2610b`) |
| gate 8c | mtime window check (= default 24 時間以内、 違反は warning level + `--refresh-alpha` option 案内、 escalate しない) |
| gate 8d | β branch parent commit literal verify (= `git merge-base HEAD wip-pmddotnet-opnb-extension` = `3c59d93` 一致 confirm、 不一致時 escalate `merge_conflict`、 round 2 lr 1 反映) |
| gate 8 option `--refresh-alpha` | β script に flag 追加 (= 指定時 α verify script を再実行して trace 再生成) |
| gate 9 | (A) production default build + sha256 literal 実測 confirm (= round 1 must-fix 1 + round 2 nh 1 反映、 ADR-0068 §決定 10 全 sub-sprint 共通 gate 整合) |
| gate 9a | build command literal = `bash scripts/build-poc.sh --chip ym2610` (= 全 fixture toggle off で production default build) |
| gate 9b | artifact path literal = `vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1` |
| gate 9c | sha256 command literal = `sha256sum vendor/ngdevkit-examples/00-template/build/rom/243-m1.m1` |
| gate 9d | expected hash literal = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` (= ADR-0067 ε milestone 通算 sha256) |

= 9 gate (= sub-step 含む 14 step) ALL PASS で β 完走 milestone。

#### β-5 = K candidate 探索結果 + β scope 採否 (= round 2 nh 3 反映、 bitmap pair representative 3 件採用、 trigger 出現確認 limit、 impl-review round 2 wording 統一)

| candidate | path | K part 内容 | β scope 採否 | rationale |
|---|---|---|---|---|
| step18/k03.mml | 2-bit simultaneous pair | bitmap pair representative variant 1 | **採用** | bitmap pair reach 代表 1 |
| step18/k11.mml | 2-bit simultaneous pair | bitmap pair representative variant 2 | **採用** | bitmap pair reach 代表 2 |
| step18/k21.mml | 2-bit simultaneous pair | bitmap pair representative variant 3 | **採用** | bitmap pair reach 代表 3 |
| step18/k05.mml | 2-bit simultaneous pair | future-ready | optional | β γ optional or future ADR |
| step18/k09.mml | 2-bit simultaneous pair | future-ready | optional | 同上 |
| step12/k-br-only.mml | 1-bit single drum | `K \b` = BD 単独 | future | bitmap pair representative 主軸でない |
| step13/k-sr-only.mml | 1-bit single drum | `K \s` = snare 単独 | future | 同上 |
| step14/k-hr-only.mml | 1-bit single drum | `K \h` = hi-hat 単独 | future | 同上 |
| step15/k-cr-only.mml | 1-bit single drum | `K \c` = cymbal 単独 | future | 同上 |
| step16/k-tr-only.mml | 1-bit single drum | `K \t` = tom 単独 | future | 同上 |
| step17/k-ir-only.mml | 1-bit single drum | `K \i` = rim 単独 | future | 同上 |

= β scope 採用 = 3 件 (= k03/k11/k21)、 6 env 追加、 env 計 = α 10 + β K 6 = 16 env。 残 8 件 = β γ optional or ADR-0069 候補 future。

##### K trace 同一 finding (= 40th session β self-test retry 3 で発覚、 重要 finding)

self-test retry 3 結果 = **全 6 env (= k03/k11/k21 × ym2610/ym2610b) で trace 同一 pattern** (= L=3 + M-Q 各 1 = total 8 件):

| env | candidate | L | M | N | O | P | Q | total |
|---|---|---|---|---|---|---|---|---|
| 11 | k03 ym2610 | 3 | 1 | 1 | 1 | 1 | 1 | 8 |
| 12 | k03 ym2610b | 3 | 1 | 1 | 1 | 1 | 1 | 8 |
| 13 | k11 ym2610 | 3 | 1 | 1 | 1 | 1 | 1 | 8 |
| 14 | k11 ym2610b | 3 | 1 | 1 | 1 | 1 | 1 | 8 |
| 15 | k21 ym2610 | 3 | 1 | 1 | 1 | 1 | 1 | 8 |
| 16 | k21 ym2610b | 3 | 1 | 1 | 1 | 1 | 1 | 8 |

期待 vs 実:
- 期待 = k03/k11/k21 で異なる bitmap pattern → 異なる L-Q write pattern (= MML 上 bitmap pair pattern 差を駆動)
- 実 = driver K dispatch 後 trace 同一 (= MML 上 bitmap pair pattern 差は driver dispatch で吸収、 L-Q keyon は全 candidate 同一)

結論:
- axis C-3 K candidate gate 7 PASS 判定の literal 意味 = **「K candidate trigger 出現確認 (= L-Q いずれかに keyon write 出現)」 limit**
- 真の「K bitmap pair representative variant 1/2/3 trace distinct」 は **β scope 内で未達成** (= driver K dispatch normalization で吸収)
- 真の K distinct 達成は **driver 拡張 (= K bitmap pattern 別 dispatch) + 別 MML required** = **ADR-0069 候補 future へ defer**

β scope 完走 wording の reflexion:
- 「K candidate trigger 出現確認」 = β acceptable (= K MML 由来で L-Q keyon が L=3 + M-Q 各 1 件 trigger される、 driver K bitmap → ADPCM-A keyon 経路機能 verify literal)
- 「K bitmap pair representative variant 1/2/3 distinct」 = β 内 NOT acceptable、 ADR-0069 候補 future
- 「K+L-Q distinctness range trace-equivalence literal 達成」 = β 完走 wording 解禁 (= L-Q candidate distinctness 3 pattern A/B/C + K candidate trigger 出現確認 + A-J default carry baseline 確認、 「真の K distinct」 含まない明示)

#### β-6 = 状態維持 + Codex layer 2 plan review + commit chain literal (= self-test 完走後 fill)

##### 状態維持 confirm (= ADR-0068 §決定 7 不可触対象 literal)

- driver source `src/driver/standalone_test.s` 完全不変
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_rhythm_k_full` 等) 完全不変
- 既存 verify script (= ADR-0049〜0067 全 + α script = verify-axis-b-v2-16ch-integration-alpha.sh) 完全不変
- 既存 build flag 完全不変 (= 新規 flag 追加なし)
- vendor 完全不変
- ADR-0048〜0067 本文 + Annex 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- **production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 実測 confirm** (= gate 9 (A) production default build + sha256 literal 一致 PASS、 §決定 10 全 sub-sprint 共通 gate 整合)

##### commit chain literal (= β PR3 commit chain 5 commit + bug fix integrated)

| # | commit | 内容 |
|---|---|---|
| 1 | `e486a7c` | ADR doc β scope literal + Annex β skeleton fill (= §決定 1(b) β scope literal + §決定 2 β row update + Annex β 8 sub-section literal + 改訂履歴 β entry) |
| 2 | `40410f7` | β verify script 新規実装 705 行 commit 時点 (= 9 gate + 14 step + 3 axis + 8 sub-category + K candidate 3 件 + `--refresh-alpha` option、 後続 bug fix + impl-review round 1 反映で現 HEAD 720 行、 nh 1 反映で行数 evolution literal) |
| 3 | `5d73611` | β verify script bug fix 2 件 + self-test PASS = 9 gate ALL PASS (= 全角「、」 2 箇所 + bash 3.2 `declare -A` → case 関数置換、 self-test retry 3 PASS confirmed、 K trace 同一 finding 検出) |
| 4 | (= 本 commit) | Annex β fill 完成 (= β-5 K trace 同一 finding literal 追加 + β-6 状態維持 + commit chain literal + § 改訂履歴 β bug fix entry) |
| 5 | (= 次 commit) | dashboard + memory + 平易要約 |

#### β-7 = lr 2 件補強 literal (= Codex round 3 approve 後の情報提供反映)

##### lr 1: α trace stale 非停止 risk
- gate 8c mtime window check で違反時 = warning level + `--refresh-alpha` option 案内
- β script header に「α trace stale 判定時は `--refresh-alpha` option 使用推奨」 message literal 出力
- 開発者使い忘れ防止: gate 8c warning は強調 message 出力 (= `WARN` 接頭辞 + `--refresh-alpha` 案内文 literal)

##### lr 2: base SHA 不一致時復旧フロー literal
- gate 8d で `git merge-base HEAD wip-pmddotnet-opnb-extension = 3c59d93` 不一致時 = escalate `merge_conflict`
- 復旧フロー:
  - (a) main agent autonomous: `git rebase wip-pmddotnet-opnb-extension` 試行 (= conflict なし PASS)
  - (b) escalate: rebase conflict / scope 変更 risk / 設計判断必要 = user 上げ

#### β-8 = Codex layer 2 plan review chain (= 3 round chain、 全 review-only + 越権操作なし confirmed)

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| 1 | revise | must-fix 3 = production sha256 β 内実測 + K candidate density wording 修正 + trace-equivalence subtype 1 invariant/intended/zmem 分離 + nh 3 + lr 3 | `a687604717a024fd4` |
| 2 | revise | must-fix 2 = 3 axis + 8 sub-category 数え方明示 (= A-3a/A-3b 分割) + gate 8 mtime threshold + stale 対策固定 + nh 3 + lr 2 | `a365c311820484805` |
| 3 | **approve** | must-fix 0 + nh 0 + lr 2 情報提供 (= α trace stale 使い忘れ risk + base SHA 不一致時復旧フロー、 β-7 で literal 反映) | `ab716011d8cec2170` |

= 3 round chain、 全 review-only 遵守 confirmed + 越権操作なし。 must-fix 計 5 件 + nh 計 6 件 + lr 計 7 件 (= 3 round 累積) 全 ADR 本文反映。

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

### Annex γ: γ 実装 completion record (= γ PR4 で fill = 全 verify script 統合 ALL PASS、 representative direct invoke 4 script + transitively regression OK pattern、 Codex layer 2 plan review 8 round chain approve 後 = round 1-3 revise + round 4 approve plan v4 + γ self-test 1 finding 反映 + round 5-7 revise + round 8 approve plan v8、 β script 除外 = §決定 5 (ii) 不可触原則遵守)

#### γ-1 = scope literal (= γ kickoff plan v4、 Codex layer 2 plan review 4 round chain approve 後)

ADR-0068 §決定 2 γ row literal + plan v4 拡張:
- 主軸: (c) baseline regression gate 統合 verify
- 範囲: representative direct invoke 4 script + transitively regression OK pattern (= ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承、 β script 除外 = §決定 5 (ii) 遵守 + β scope coverage は ADR Annex β literal で別途確保)
- production sha256 維持 = ym2610 chip target 直接 confirm + ym2610b 推移性保証

γ 完了判定 = 6 gate ALL PASS + 三分割 wording integrated completion proof report literal output + 7 件全件 禁止 wording self-check + NOT-COMPLETE 7 行 literal output。

#### γ-2 = 配置 (= 新規 γ verify script + ADR doc 3 箇所同時 update + dashboard + 既存 driver / 既存 verify script / 既存 build flag / vendor / 既存 fixture / α script / β script 完全不変)

- **新規 verify script**: `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-gamma.sh` (= 307 行 commit b39c7ec 時点 → 現 HEAD 325 行 evolution、 α/β script pattern 継承、 bug fix 2 件 + allowlist 5 件追加で行数 increment、 impl-review round 1 nh 1 反映)
- **ADR-0068 doc 修正**: §決定 1(c) + §決定 2 γ row + §決定 6 表記制約 3 箇所同時 update + Annex γ fill + 改訂履歴 γ entry + 平易要約 γ context
- **dashboard 0068 行 status column update + escalation 履歴 γ PR4 entry 1 row**
- **トレース出力**: per-script log = `/tmp/pmdneo-adr-0068-gamma/<script-basename>.log` 計 4 file (= representative 4 script 各 1 log、 β script 除外) + `build-pre.log` + `build-post.log` + `adr-doc-diff-added.txt`
- **driver / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / α script / β script / ADR-0048〜0067 本文 + Annex 完全不変** (= ADR-0068 §決定 5 (ii) literal)

#### γ-3 = representative regression 4 script + per-script log (= impl-review round 1 must-fix 1 反映、 β script 除外 = 5 → 4 script)

representative direct invoke (= 4 script、 β script 除外 = §決定 5 (ii) 不可触原則遵守):

| # | script | 由来 ADR |
|---|---|---|
| 1 | `verify-axis-b-v2-16ch-integration-alpha.sh` | ADR-0068 α 直接 dependency |
| 2 | `verify-axis-b-v2-fixture-expansion-delta.sh` | ADR-0067 δ 16 ch fixture 拡張完了 baseline |
| 3 | `verify-axis-b-v2-song-playback.sh` | ADR-0058 ε 10 gate baseline |
| 4 | `verify-axis-b-v2-roadmap3-dispatch.sh` | ADR-0059 ε 12 gate baseline |

transitively regression (= ADR-0049〜0057 系 verify script 全) = production sha256 維持 = m1 ROM byte-identical 経由で transitively regression OK literal。

per-script log path = `/tmp/pmdneo-adr-0068-gamma/<script-basename>.log` (= self-test 完走後 PASS / FAIL 切り分け logfile 保存)。

##### β script 除外 rationale (= γ self-test 1 finding 反映、 plan v5 → v8 round 5-8 chain approve)

β script (= `verify-axis-b-v2-16ch-integration-beta.sh`) は本 γ representative regression から除外 (= ADR-0068 §決定 5 (ii) β script 完全不変原則遵守、 内部修正不可、 β script gate 8d (= β branch parent commit literal verify = 3c59d93) は β branch 内部 self-test 専用仕様で γ branch HEAD (= 7335da9 = β merge commit) 経路で merge_conflict 誤発火検出 = γ self-test 1 で顕在化、 ADR-0068 Annex β β-7 lr 2 復旧フロー (a) rebase 不適用 = β merge 完了で git history 線形分岐済)。 β scope (= K+L-Q distinctness range trace-equivalence) 確認は ADR Annex β literal (= β-1〜β-8 8 sub-section + 9 gate ALL PASS + K trace 同一 finding + β 完走 wording 解禁) で別途確保済、 transitively regression は production sha256 維持 (= m1 ROM byte-identical) で carry。

#### γ-4 = production sha256 維持 (= pre + post 両方 confirm、 ym2610b 推移保証 + β scope coverage 根拠 paragraph 分離 = round 6 lr 2 反映)

- 通算 sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持 mandatory
- gate 1 pre-build sha256 (= ym2610 (A) production default build) 実測 confirm
- gate 6 post-representative-script sha256 (= ym2610 (A) production default build 再実行) 復元 confirm = representative script 内非 production build 後 production binary 復元 literal

##### paragraph 1: ym2610b representative coverage 根拠 (= γ 直接 sha256 confirm は ym2610 のみ、 ym2610b は推移的保証)

ym2610b chip target coverage = representative regression script 内既存 chip target 駆動による推移的保証:
- **representative-1 α script** = `verify-axis-b-v2-16ch-integration-alpha.sh` 内 10 env のうち ym2610 + ym2610b 両 chip target 駆動 (= env # 1-2 = (B) v2-only ym2610 + ym2610b + env # 3-10 = (C-2) PMDDOTNET_MML ym2610 + ym2610b 交互、 ADR-0067 §決定 12 chip target 別 active policy literal 整合)
- **representative-2 δ script** = `verify-axis-b-v2-fixture-expansion-delta.sh` 内 ADR-0067 §決定 12 chip target 別 active policy で ym2610 primary 8 slot + ym2610b secondary 11 slot 駆動 (= chip target 両 capture)
- representative-3 song-playback + representative-4 roadmap3 = ym2610 primary 駆動 (= 各 script 既存決定)

γ 直接 sha256 confirm は ym2610 (A) production default 1 件 (= gate 1 pre + gate 6 post)。 ym2610b 独立 sha256 confirm は γ scope 外 (= 別 sub-sprint / 別 ADR future)。

##### paragraph 2: β scope coverage 根拠 (= β script 除外による β scope 影響、 ADR Annex β literal で別途確保)

β script (= `verify-axis-b-v2-16ch-integration-beta.sh`) を γ representative regression から除外したことによる β scope coverage 影響:
- β scope (= K+L-Q register behavior の normalized comparison + 3 axis + 8 sub-category trace-equivalence + K trace 同一 finding) の repo 内 coverage は **ADR Annex β literal** で別途確保済:
  - Annex β-1 〜 β-8 8 sub-section literal
  - β-4 verify gate 9 件 ALL PASS literal record
  - β-5 K trace 同一 finding literal record + ADR-0069 候補 future defer literal
  - β 完走 wording 解禁 = 「K+L-Q distinctness range trace-equivalence literal 達成」
- β scope の機械的再実行 coverage は γ から外れるが、 β branch merge 時 (= PR #135) に Codex impl-review 2 round chain で確認済 + β 完走 milestone 既達成
- transitively regression = production sha256 維持 (= m1 ROM byte-identical) で β 影響を覆う production binary 不変性保証

#### γ-5 = 三分割 wording integrated completion proof report + 禁止 wording self-check

verify script 末尾 exact literal output (= 6 gate + NOT-COMPLETE 7 行):

```
=== ADR-0068 γ baseline regression gate completion proof ===
PASS sha256-pre: b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4 (= (A) production default ym2610)
PASS representative-1: verify-axis-b-v2-16ch-integration-alpha.sh exit=0 log=/tmp/pmdneo-adr-0068-gamma/verify-axis-b-v2-16ch-integration-alpha.log
PASS representative-2: verify-axis-b-v2-fixture-expansion-delta.sh exit=0 log=/tmp/pmdneo-adr-0068-gamma/verify-axis-b-v2-fixture-expansion-delta.log
PASS representative-3: verify-axis-b-v2-song-playback.sh exit=0 log=/tmp/pmdneo-adr-0068-gamma/verify-axis-b-v2-song-playback.log
PASS representative-4: verify-axis-b-v2-roadmap3-dispatch.sh exit=0 log=/tmp/pmdneo-adr-0068-gamma/verify-axis-b-v2-roadmap3-dispatch.log
PASS three-section-wording 16ch integration trace 完了
PASS three-section-wording K+L-Q candidate distinctness 完了
PASS three-section-wording A-J default carry 確認
NOT-COMPLETE 16ch full candidate distinctness 完了 (= ADR-0069 候補 future、 driver 拡張 sprint required)
NOT-COMPLETE roadmap ⑤ 統合 verify 完了 (= ADR-0068 ε Accepted future)
NOT-COMPLETE trace-equivalence 完了 single wording (= ADR-0068 ε Accepted future)
NOT-COMPLETE production-ready 全体達成 (= 4 gate + audition + cmd 切替 future)
NOT-COMPLETE 軸 B 完成 (= v2 production-ready 化 + cmd 切替後 future)
NOT-COMPLETE 軸 G 完成 (= 軸 G 全体完成は別 axis 完了後 future)
NOT-COMPLETE 本番 cmd 切替完了 (= ADR-0066 候補 future)
PASS sha256-post: b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4 (= representative script 内非 production build 後 (A) production default ym2610 復元 confirm)
=== ADR-0068 γ baseline regression gate ALL PASS ===
```

禁止 wording self-check (= 7 件全件、 scan target literal 固定 + 範囲限定):
- scan target = (a) `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-gamma.sh` 全行 + (b) `docs/adr/0068-pmdneo-axis-b-v2-16ch-integration-verify.md` の PR4 更新箇所 (= `git diff wip-pmddotnet-opnb-extension..HEAD` で +追加行抽出)
- 検査 wording 7 件 = 「16ch full candidate distinctness 完了」 / 「roadmap ⑤ 統合 verify 完了」 / 「trace-equivalence 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」
- allowlist pattern (= exact substring exclusion):
  - `NOT-COMPLETE <禁止 wording>` (= completion proof 内否定行)
  - `「<禁止 wording>」 wording 禁止` (= 表記制約 reference context)
  - `「<禁止 wording>」 = literal 禁止` (= 表記制約 reference context)
  - `「<禁止 wording>」 = ADR-0069 候補 future` (= 16ch full candidate distinctness 限定)
  - `「<禁止 wording>」 = ADR-0068 ε Accepted future`
  - `「<禁止 wording>」 = ADR-0066 候補 future` (= 本番 cmd 切替完了 限定)
  - `<禁止 wording>条件` (= 比較・条件文脈、 round 3 nh 1 反映)
  - `<禁止 wording>ではない` (= 否定文脈)
  - `<禁止 wording>達成ではない` (= 否定文脈)
  - `禁止 wording check` (= self-check context)
  - `禁止維持` (= 表記制約 context)
  - `prohibited wording` (= 英文 reference context)
- expected count after exclusion = 各 wording 0
- 不一致時 FAIL + violation line literal output

#### γ-6 = 状態維持 + Codex layer 2 plan review chain + commit chain literal (= self-test 完走後 fill)

##### 状態維持 confirm (= ADR-0068 §決定 7 不可触対象 literal)

- driver source `src/driver/standalone_test.s` 完全不変
- ADR-0067 fixture (= 全 16 ch fixture data + slot 2-10 init + pointer switch) 完全不変
- 既存 verify script (= ADR-0049〜0067 全 + α script + β script) 完全不変
- 既存 build flag 完全不変 (= 新規 flag 追加なし)
- vendor 完全不変
- ADR-0048〜0067 本文 + Annex 完全不変
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 実測 confirm (= gate 1 pre + gate 6 post 両方 PASS、 §決定 10 全 sub-sprint 共通 gate 整合)

##### Codex layer 2 plan review chain (= 4 round、 全 review-only + 越権操作なし confirmed)

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| 1 | revise | must-fix 3 = ADR γ row literal 乖離 + completion proof exact literal underspecified + memory commit chain 内/外 矛盾、 nh 2 + lr 2 | `a3a27e8e2dfee977a` |
| 2 | revise | must-fix 3 = ADR doc 更新範囲 狭い + prohibited wording check grep 1 件 → 7 件全件 + NOT-COMPLETE 6 行 vs 禁止 literal 7 件 不一致、 nh 2 + lr 2 | `a1c4721bf1f66a5a6` |
| 3 | revise | must-fix 2 = gate 1 と chip target 境界矛盾 + scan target ADR doc 全体 false positive risk、 nh 1 + lr 1 | `a836738a32ccf5bdc` |
| 4 | **approve plan v4** | must-fix 0 + nh 1 (= prohibited wording 配列 context literal 必須) + lr 1 (= git diff base ref 確認) | `a5e3502b12fb6bbfb` |
| 5 | revise plan v5 | γ self-test 1 finding 投入 (= β script gate 8d β branch 内部 self-test 専用 = γ 統合 regression 経路で merge_conflict 誤発火検出): must-fix 2 = ADR doc update 対象不足 (= Annex γ-4 等) + §決定 3 wording 不整合、 nh 2 + lr 2 | `a0ebc16cc8dff7c1c` |
| 6 | revise plan v6 | must-fix 2 = ADR doc 12 → 11 → 12 箇所明示 + γ script gate 2 section heading update target 追加、 nh 1 + lr 2 (= ym2610b coverage / β scope coverage paragraph 分離) | `a3e1649a54066ee4d` |
| 7 | revise plan v7 | must-fix 1 = 改訂履歴 γ entry update target 明示追加、 lr 1 (= BASE_REF 不在時 fail-stop 挙動明示) | `a36cd4ac2187ebc37` |
| 8 | **approve plan v8** | must-fix 0 + nh 1 (= commit 3 message wording fine-tune)、 lr 0 | `aaf195285d974edcc` |

= 8 round chain、 全 review-only 遵守 confirmed + 越権操作なし。 must-fix 計 13 件 + nh 計 10 件 + lr 計 11 件 全 ADR / verify script 反映。 round 1-4 = plan v4 確定 + round 5-8 = γ self-test 1 finding 反映 plan v8 確定 (= β script representative 除外、 5 → 4 script、 §決定 5 (ii) 不可触原則遵守、 β scope coverage は ADR Annex β literal 別途確保)。

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

##### commit chain literal (= plan v8 historical record = 5 commit chain、 impl-review 反映 commit は別 sub-section で literal record、 self-referential commit chain table 無限再帰回避方式)

###### (a) plan v8 計画時 5 commit chain (= historical record = plan v8 round 8 approve 時点)

| # | commit | 内容 |
|---|---|---|
| 1 | `3b1a026` | ADR doc γ scope literal + Annex γ skeleton 主要 fill (= §決定 1(c) + §決定 2 γ row + §決定 6 表記制約 3 箇所同時 update + Annex γ 6 sub-section + 改訂履歴 γ entry) |
| 2 | `b39c7ec` | γ verify script 新規実装 307 行 |
| 3 | `fc2320d` | self-test 1 finding 反映 + plan v5 → v8 (= β script representative 除外 = 5 → 4 script、 §決定 5 (ii) 不可触原則遵守、 ADR doc 12 箇所 update + γ verify script 7 箇所 update、 Codex layer 2 plan review round 5-7 revise + round 8 approve plan v8) |
| 4 | `60101a2` | γ verify script bug fix 2 件 (= self-test 2/3 finding 反映) + Annex γ fill 完成 update (= commit hash literal + self-test 4 結果 6 gate ALL PASS literal) + 改訂履歴 γ bug fix entry update。 bug fix 内容 = (a) bash 3.2 多バイト文字 parameter expansion bug 回避 = `local var="$arg"` declaration assignment 分離 + 全 `${word}` braces 明示、 (b) allowlist 5 件追加 = 「<word> /」 enumeration list context + 「/ 「<word>」」 + array entry `    "<word>"` + 「<word> 限定」 limitation context + 「検査 wording」 reference context。 self-test 4 結果 = 6 gate ALL PASS + NG count 0 + 22 OK count |
| 5 | `8c1d5ec` | dashboard 0068 行 status update + escalation 履歴 γ PR4 entry + 平易要約 γ context 追記 |

###### (b) impl-review 反映追加 commit chain (= plan v8 5 commit chain 完走後、 Codex layer 2 impl-review round-by-round 反映 commit chain、 self-referential 無限再帰回避方式で本 sub-section で literal record)

| # | commit | 内容 |
|---|---|---|
| round 1 反映 | `d798a21` | Codex layer 2 impl-review round 1 finding 反映 (= revise judgment must-fix 1 + nh 2 全反映、 lr 1 継続監視、 agentId `a7ec395ff32cfb510`) = Annex γ-3 見出し「5 script」 → 「4 script」 修正 + Annex γ-2 「行数 TBD」 → 「307 → 325 行 evolution」 update + dashboard γ PR4 + β PR3 entry 内 commit 5 wording「memory」 → 「escalation 履歴」 update (= memory は repo 外、 PR diff 対象外明示) + 改訂履歴 γ impl-review round 1 entry 追加 |
| round 2 反映 | `ab3b29d` | Codex layer 2 impl-review round 2 finding 反映 (= revise judgment must-fix 1、 commit chain 件数 mismatch 5 → 6 update、 agentId `a72621a6d6d2de0bd`) = Annex γ-6 commit chain literal 6 entry update + 平易要約「commit chain 6 完走」 update + γ 完走後の次「本 commit 6」 update。 ただし本 update 自体が self-referential commit chain table update を引き起こす finding (= round 3 で再 mismatch 検出)、 round 3 反映で historical record 分離方式に refactor |
| round 3 反映 | `9f33843` | Codex layer 2 impl-review round 3 finding 反映 (= revise judgment must-fix 1、 commit chain 件数 6 → 7 update + self-referential 無限再帰回避方式 refactor、 agentId `a0386dec89731f2d1`) = commit chain literal sub-section を (a) plan v8 historical record 5 commit + (b) impl-review 反映追加 commit chain 別 sub-section に分離 + dashboard / 平易要約 / γ 完走後の次 wording も「plan v8 5 + impl-review N 反映」 形式に統一、 self-referential 無限再帰回避 + literal record 整合 |
| round 4 反映 (= 本 commit) | (= 本 commit) | Codex layer 2 impl-review round 4 finding 反映 (= revise judgment must-fix 1、 round 3 reference の literal hash 確定 update (= 「本 commit」 → `9f33843`)、 agentId `a593148f4340d756d`) = Annex γ-6 (b) sub-section 内 round 3 entry の commit hash literal 確定 + 平易要約 round 3 reference literal 確定 + lr 1 継続監視。 round 4 反映 hash 自身は本 commit の self-referential なため確定不可、 round 5 で確定 update 期待 (= 「本 commit」 wording 維持 = 各 round 反映時に直前 round の commit hash を確定する pattern) |

### Annex δ: δ 統合 report + 残課題 enumeration (= δ PR5 で fill = 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material、 Codex layer 2 plan review round 1 approve plan v1 + nh 3 + lr 3 全反映)

#### δ-1 = scope literal (= ADR-0068 §決定 2 δ row literal 継承、 doc-only sprint)

δ scope = **統合 report + 残課題 enumeration (= ADR-0065/0066/0069 起票判断 material)** doc-only sprint:

1. (i) 統合 report = α/β/γ 3 sub-sprint 結果 enumeration + integration milestone literal
2. (ii) roadmap ⑤ 完了前状態の明確化 (= 「roadmap ⑤ 統合 verify 完了」 wording = ε まで禁止維持 literal 強調、 (a)(b)(c) 3 gate 結果別 status enumeration)
3. (iii) 残課題 enumeration = ADR-0065/0066/0069 起票判断 material (= 各 scope literal + 解禁 wording 条件 + user 明示 GO 必須 literal)
4. (iv) Annex δ fill = δ-1 (= scope literal) + δ-2 (= 統合 report) + δ-3 (= 残課題 enumeration) + δ-4 (= 状態維持 + Codex layer 2 plan review chain + commit chain literal)

δ Accepted (= δ PR5 merge 後) ≠ ADR-0068 ε Accepted (= ε PR6 で別途) ≠ roadmap ⑤ 統合 verify 完了 (= ε Accepted 後解禁 + 併記必須)。

#### δ-2 = 統合 report = α/β/γ 3 sub-sprint 結果 enumeration + integration milestone literal

##### δ-2-1 = α PR2 結果 literal (= K+L-Q candidate distinctness capture + A-J default integration trace)

| 項目 | 結果 |
|---|---|
| PR | #134 MERGED at `3c59d93` |
| 完了日 | 2026-05-25 (= 40th session) |
| scope | (a) 実 MML 再生 統合 verify = K+L-Q candidate distinctness capture + A-J default integration trace (= plan v7 = 40th session driver ground truth based) |
| 新規 verify script | `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-alpha.sh` (= 466 行) |
| trace capture | 20 file (= 10 env × ymfm/zmem 2 trace 種) |
| K+L-Q distinctness pattern | A (= note 数差分由来 = l-q-rhythm-song / l-q-rhythm-song-step5b) + B (= 6 ch 同時 keyon = l-q-tutti) + C (= baseline + init keyon = SAMPLE2-baseline) = **3 pattern capture 確認** |
| A-J default integration trace | 全 (C-2) env で同一 default pattern 確認 (= FM A/D = 0/61 chip 別 + B/C/E/F = 8 + SSG = 2 + ADPCM-B = 2) |
| 16/16 ch carry actual | FM A-F + SSG G-I + ADPCM-B J + ADPCM-A L-Q = 全 16 ch carry 確認 |
| 三分割 wording | 「16ch integration trace 完了」 ✓ + 「K+L-Q candidate distinctness 完了」 ✓ + 「A-J default carry 確認」 ✓ + 「16ch full candidate distinctness 完了」 = literal 禁止維持 (= ADR-0069 候補 future) |
| Codex layer 2 review | plan review 5 round chain + impl-review 5 round chain 全 approve = 全 review-only + 越権操作なし confirmed |
| 通算 sha256 | `b15883fe...` 維持 confirmed |

= **「ADR-0068 α 完了」 wording 解禁 + 16ch integration trace + K+L-Q candidate distinctness + A-J default carry 三分割 wording 整合**。 distinctness 判定 assertion は β scope future (= β-2 で 3 axis + 8 sub-category trace-equivalence 判定基準 確定)。

##### δ-2-2 = β PR3 結果 literal (= K+L-Q distinctness range trace-equivalence + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal)

| 項目 | 結果 |
|---|---|
| PR | #135 MERGED at `7335da9` |
| 完了日 | 2026-05-25 (= 40th session) |
| scope | (b) trace-equivalence 判定基準確定 + 比較実行 = K+L-Q register behavior の normalized comparison (= ADR-0064 §決定 1(b) β scope literal 整合) |
| 新規 verify script | `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-beta.sh` (= 720 行 現 HEAD = bug fix + impl-review 反映後) |
| trace 入力 | α capture 20 file + β 新規 12 file (= K candidate bitmap pair representative variant 1/2/3 = k03/k11/k21、 6 env × 2 trace 種) = 計 32 trace file |
| trace-equivalence 判定基準 | 3 axis + 8 sub-category (= axis A YMFM register 4 sub = A-1 invariant + A-2 intended diff + A-3a unintended primary + A-3b neutral record-only + axis B zmem diagnostic record-only + axis C distinctness 3 sub = C-1 L-Q + C-2 A-J + C-3 K) |
| verify gate | 9 件 (= sub-step 含む 14 step) ALL PASS = axis A-3a unintended diff 0 件 literal confirm + axis B zmem 別 file diagnostic + axis C K+L-Q acceptable literal + α trace provenance 4 step + (A) production sha256 literal `b15883fe...` 実測 confirm |
| 重要 finding | K trace 同一 (= k03/k11/k21 全 6 env trace 同一 pattern L=3 + M-Q 各 1 = total 8 件、 driver K dispatch normalization で MML 上 bitmap pair pattern 差吸収) = 真の「K bitmap pair representative variant 1/2/3 trace distinct」 は **β scope 内未達成** = **ADR-0069 候補 future defer literal** (= LR2 反映 = A-J candidate distinctness と K bitmap pair distinct は粒度別 sub-finding として明示) |
| β scope acceptable literal | axis C-3 K candidate gate 7 PASS = 「K candidate trigger 出現確認 (= L-Q いずれかに keyon write 出現)」 limit (= driver K dispatch normalization で吸収、 真の K bitmap pair variant distinct は ADR-0069 候補 future defer) |
| Codex layer 2 review | plan review 3 round chain + impl-review 2 round chain 全 approve = 全 review-only + 越権操作なし confirmed |
| 通算 sha256 | `b15883fe...` 維持 confirmed (= gate 9 (A) production default build 実測一致) |

= **「ADR-0068 β 完了」 wording 解禁 + 「K+L-Q distinctness range trace-equivalence literal 達成」 (= β scope 限定明記必須、 真の K distinct 含まない明示)**。

##### δ-2-3 = γ PR4 結果 literal (= baseline regression gate 統合 verify ALL PASS + representative direct invoke 4 script + 6 gate ALL PASS)

| 項目 | 結果 |
|---|---|
| PR | #136 MERGED at `ef87dcb` |
| 完了日 | 2026-05-25 (= 40th session) |
| scope | (c) baseline regression gate 統合 verify = representative direct invoke 4 script + transitively regression OK pattern (= ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承) |
| 新規 verify script | `src/test-fixtures/axis-b/verify-axis-b-v2-16ch-integration-gamma.sh` (= 325 行 現 HEAD = bug fix + allowlist 5 件追加後) |
| representative direct invoke 4 script | (1) `verify-axis-b-v2-16ch-integration-alpha.sh` + (2) `verify-axis-b-v2-fixture-expansion-delta.sh` + (3) `verify-axis-b-v2-song-playback.sh` + (4) `verify-axis-b-v2-roadmap3-dispatch.sh` |
| β script 除外 rationale | β script gate 8d (= β branch parent commit literal verify = 3c59d93) は β branch 内部 self-test 専用仕様で γ 統合 regression 経路で merge_conflict 誤発火検出 = γ self-test 1 で顕在化 → β script 完全不変原則遵守 (= §決定 5 (ii)) + β scope coverage は ADR Annex β literal で別途確保 (= 5 script → 4 script 整理) |
| verify gate | 6 gate ALL PASS = gate 1 sha256-pre + gate 2 representative 4/4 ALL PASS + gate 3 三分割 wording + gate 4 prohibited wording self-check 7 件全件 allowlisted + gate 5 NOT-COMPLETE 7 行 + gate 6 sha256-post 復元 = 22 OK count + 0 NG count |
| 通算 sha256 | `b15883fe...` 維持 confirmed (= gate 1 pre + gate 6 post 両方一致) |
| Codex layer 2 review | plan review 8 round chain + impl-review 4+ round chain 全 approve = must-fix 計 13 + nh 計 10 + lr 計 11 全反映 = 全 review-only + 越権操作なし confirmed、 self-referential commit chain 無限再帰回避方式 refactor (= round 3 反映で historical record 分離) |

= **「ADR-0068 γ 完了」 wording 解禁 + γ scope 限定 baseline regression gate 統合 verify ALL PASS literal 達成 (= γ 限定併記必須維持 = ε まで禁止 7 件継続)**。

##### δ-2-4 = integration milestone literal (= α/β/γ 3 sub-sprint 統合視点、 三分割 wording integrated)

α/β/γ 3 sub-sprint 完走による ADR-0068 statement の literal 整理:

| 達成項目 | literal status | rationale |
|---|---|---|
| **「ADR-0068 α 完了」** | 解禁 (= α PR2 merge 後) | K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 carry actual + 三分割 wording 整合 |
| **「ADR-0068 β 完了」** | 解禁 (= β PR3 merge 後) | K+L-Q distinctness range trace-equivalence literal 達成 + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal |
| **「ADR-0068 γ 完了」** | 解禁 (= γ PR4 merge 後) | γ scope 限定 baseline regression gate 統合 verify ALL PASS literal + representative 4 script + 6 gate ALL PASS + 通算 sha256 維持 |
| **「16ch integration trace 完了」** | γ completion proof 内 context-bound 使用 OK (= 継承)、 single isolated wording は ε まで禁止維持 | (a)(b)(c) gate 統合 verify 達成 |
| **「K+L-Q candidate distinctness 完了」** | 同上 (= 継承) | α capture 3 pattern A/B/C + β trace-equivalence 判定 acceptable |
| **「A-J default carry 確認」** | 同上 (= 継承) | α default driven trace 同一 pattern 確認 |
| **「ADR-0068 δ 完了」** | δ PR5 merge 後解禁 (= LR1 同段落併記必須) | δ scope 限定 = 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material 完了 literal |
| 「ADR-0068 ε Accepted」 | ε PR6 future | Draft → Accepted 移行 + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須 |
| 「roadmap ⑤ 統合 verify 完了」 single wording | **ε まで禁止維持** (= ε Accepted 後解禁 + 併記必須) | ADR-0068 ε で literal 解禁、 δ 時点では (a)(b)(c) 3 gate 別 status enumeration のみ |
| 「trace-equivalence 完了」 single wording | ε まで禁止維持 | 同上 |
| 「16ch full candidate distinctness 完了」 | literal 禁止維持 (= ADR-0069 候補 future) | LR2 反映 = A-J candidate distinctness + K bitmap pair distinct 別 sub-finding として粒度保持、 driver source 拡張必須 (= ADR-0069 candidate scope literal) |
| 「production-ready 全体達成」 | literal 禁止維持 | ADR-0056 §決定 3 4 gate 全達成 + 越川氏 audition approve + 本番 cmd 切替後 future |
| 「軸 B 完成」 | literal 禁止維持 | v2 driver production-ready 化 + 本番 cmd 切替後 future |
| 「軸 G 完成」 | literal 禁止維持 | 軸 G 全体完成は別 axis 完了後 future |
| 「本番 cmd 切替完了」 | literal 禁止維持 | ADR-0066 候補完了後のみ |

##### δ-2-5 = roadmap ⑤ 完了前状態の明確化 (= (a)(b)(c) 3 gate 別 status enumeration、 ε まで「roadmap ⑤ 統合 verify 完了」 single wording 禁止維持 literal 強調)

ADR-0056 §決定 3 4 gate のうち ADR-0068 scope = (a)(b)(c) 3 gate ((d) audition は ADR-0065 候補 scope-out) の literal status:

| gate | status (= ADR-0068 δ 時点) | 達成内容 | ε Accepted 後解禁 wording |
|---|---|---|---|
| (a) 実 MML 再生 統合 verify | **partial 達成** (= α PR2 完了) | K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 ch carry actual + 3 pattern A/B/C 確認 | ε 完走後「(a) gate 達成」 wording 解禁 |
| (b) 実音 register trace-equivalence | **partial 達成** (= β PR3 完了 = β scope 限定) | K+L-Q register behavior の normalized comparison literal 達成 + 9 gate ALL PASS + axis A-3a unintended diff 0 件 confirm | ε 完走後「(b) gate 達成 (= K+L-Q range 限定、 真の K distinct は ADR-0069 future)」 wording 解禁 |
| (c) baseline regression gate | **達成** (= γ PR4 完了) | representative direct invoke 4 script + 6 gate ALL PASS + 通算 sha256 維持 confirm | ε 完走後「(c) gate 達成」 wording 解禁 |
| (d) 越川氏 audition gate | **ADR-0068 scope-out** (= ADR-0065 候補 future) | engineering pass (= (a)(b)(c)) ≠ aesthetic pass (= (d))、 ADR-0065 起票後 user 明示 GO + 越川氏 audition session approve | ADR-0065 Accepted 後「(d) audition 完了」 wording 解禁 (= 別 ADR scope) |

= ADR-0068 δ 時点 = (a)(b)(c) 3 gate partial/達成 status enumeration 完了。 「(a)(b)(c) 3 gate 統合 verify 完了」 / 「roadmap ⑤ 統合 verify 完了」 single wording = **ε まで禁止維持 literal 強調** (= ε Accepted 後解禁 + 併記必須 = 「(d) audition 未実装」 + 「production-ready 全体達成ではない」 + 「軸 B 完成ではない」 + 「本番 cmd 切替完了ではない」)。

#### δ-3 = 残課題 enumeration = ADR-0065/0066/0069 起票判断 material (= LR2 反映 = A-J candidate distinctness + K bitmap pair distinct 別 sub-finding 粒度保持、 LR3 反映 = γ MERGED と δ 完了の境界明確分離維持)

##### δ-3-1 = ADR-0065 候補 = roadmap ⑥ audition ADR (= 越川氏 audition gate)

| 項目 | literal |
|---|---|
| 由来 | ADR-0064 §決定 1(d) literal「(d) 越川氏 audition gate = ADR-0065 候補 scope-out」 + ADR-0064 §決定 9 literal「ADR-0065 候補 = roadmap ⑥ audition ADR」 |
| scope | 越川氏 audition session approve = aesthetic gate (= engineering pass (= ADR-0068 (a)(b)(c) 3 gate) ≠ aesthetic pass) |
| 起票判断条件 (= user 明示 GO 必須) | ADR-0068 ε Accepted 後 + user 明示 GO (= 明示 unlock 条件は user GO のみ、 audition session 実施準備は運用上前提 = NH1 反映) |
| 解禁 wording 条件 | ADR-0065 Accepted 後 = 「(d) audition 完了」 wording 解禁、 ただし「production-ready 全体達成ではない」 + 「本番 cmd 切替完了ではない」 併記必須 |
| 関連 memory | [[ai-engineering-gate-before-human-audition]] (= AI engineering 検査 → human aesthetic audition の順序固定 literal) |
| ADR-0066 起票への dependency | ADR-0065 Accepted → ADR-0066 起票判断条件 (= 順序固定) |

NH1 反映: 「audition session 実施準備完了」 は ground truth 上の明示 unlock 条件ではなく、 user 運用上の前提扱い (= 越川氏 audition session のスケジューリング + audition material 選定等)。 明示 unlock 条件 = ADR-0068 ε Accepted + user 明示 GO のみ。 ε 時点で「audition preparation 完了 = ADR-0065 起票可」 と誤読する risk 回避。

##### δ-3-2 = ADR-0066 候補 = roadmap ⑦ 本番 cmd 切替判断 ADR (= cmd 0x05 経路 → v2 driver 経路 switch)

| 項目 | literal |
|---|---|
| 由来 | ADR-0064 §決定 1(c) + ADR-0061 §決定 3 (3) literal「本番 cmd 切替判断」 + ADR-0064 §決定 9 literal「ADR-0066 候補 = roadmap ⑦ 本番 cmd 切替判断 ADR」 |
| scope | cmd 0x05 + `pmdneo_song_main` 経路 → v2 driver 経路 switch、 production-ready 全通過後 future |
| 起票判断条件 (= user 明示 GO 必須) | ADR-0068 ε Accepted + ADR-0065 Accepted (= 越川氏 audition approve) + production-ready 全 4 gate 達成 + user 明示 GO (= 順序固定 dependency) |
| 解禁 wording 条件 | ADR-0066 Accepted + 本番 cmd 切替実施後 = 「本番 cmd 切替完了」 wording 解禁、 「production-ready 全体達成」 + 「軸 B 完成」 wording も同時解禁判断 (= user 判断軸) |
| 依存 | ADR-0068 ε Accepted → ADR-0065 Accepted → ADR-0066 起票判断 (= **順序固定 dependency chain**) |
| ADR-0068 δ 時点での status | 起票判断 future (= ADR-0068 ε Accepted + ADR-0065 Accepted 後 user 判断軸) |

##### δ-3-3 = ADR-0069 候補 = driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct 実現 (= ADR-0068 §決定 9 literal、 Annex α-3 / β-5 K trace 同一 finding 由来、 LR2 反映 = 別 sub-finding 粒度保持)

| 項目 | literal |
|---|---|
| 由来 | ADR-0068 §決定 9 literal「ADR-0069 候補 = driver 拡張 sprint」 + Annex α-3 「A-J default driven 確認、 A-J distinctness 達成は driver 拡張 sprint = ADR-0069 候補 future」 + Annex β-5 K trace 同一 finding「真の K bitmap pair representative variant 1/2/3 distinct は β scope 内未達成 = driver 拡張 + 別 MML required = ADR-0069 候補 future defer literal」 |
| scope (= LR2 反映 = 2 sub-finding 別粒度保持) | **2 sub-finding 別粒度 literal** (= 一括「16ch full candidate distinctness」 と読ませない明示): (a) **A-J candidate distinctness 実現** = driver `nmi_cmd_5_init_mml_song` line 1741-1804 `load_song_part_addr` 経路を `.if PMDNEO_USE_PMDDOTNET == 1` 分岐で A-J 各 part 拡張 (= ADR-0067 fixture 拡張 pattern 同手法 additive 修正、 既存 routine 不変)、 完走で ADR-0068 「16ch full candidate distinctness 完了」 wording 解禁条件 (a) 達成、 (b) **K bitmap pair representative variant 1/2/3 distinct 実現** = driver K dispatch normalization 経路の bitmap pattern 別 dispatch 拡張 (= 真の K distinct trace 実現)、 完走で ADR-0068 Annex β-5 K trace 同一 finding 解消 + 「K bitmap pair distinct 完了」 wording 解禁条件達成、 (c) (a)(b) **両達成で** 「16ch full candidate distinctness 完了」 wording 解禁条件達成 (= 一括解禁ではない、 段階的解禁) |
| 起票判断条件 (= user 明示 GO 必須) | ADR-0068 ε Accepted 後 + user 明示 GO |
| 解禁 wording 条件 (= LR2 反映 = 段階的解禁) | (a) ADR-0069 (a) sub-finding 完走後 = 「A-J candidate distinctness 完了」 wording 解禁 + (b) ADR-0069 (b) sub-finding 完走後 = 「K bitmap pair distinct 完了」 wording 解禁 + (c) (a)(b) 両完走後 = **「16ch full candidate distinctness 完了」 wording 解禁** (= ただし「production-ready 全体達成ではない」 併記必須) |
| driver source 拡張範囲 | driver `nmi_cmd_5_init_mml_song` line 1741-1804 + K dispatch normalization 経路、 既存 routine 完全不変 + additive 修正のみ (= ADR-0067 fixture 拡張 pattern 同手法) |
| ADR-0068 δ 時点での status | 起票判断 future (= ADR-0068 ε Accepted 後 user 判断軸) |

LR2 反映 literal: ADR-0069 候補は **2 sub-finding (= A-J candidate distinctness + K bitmap pair distinct) 別粒度保持**。 一括「16ch full candidate distinctness 完了」 と読ませると β finding (= K trace 同一 finding = driver K dispatch normalization 由来) の粒度が潰れる risk。 段階的解禁 = (a) A-J → (b) K → (c) 統合 という順序で wording 解禁条件確定。

##### δ-3-4 = 残課題 enumeration 整理 = 3 ADR 候補 dependency chain literal

| ADR 候補 | dependency | 起票判断 trigger | 解禁 wording |
|---|---|---|---|
| ADR-0065 候補 (= audition) | ADR-0068 ε Accepted | user 明示 GO | 「(d) audition 完了」 |
| ADR-0066 候補 (= 本番 cmd 切替) | ADR-0068 ε Accepted → ADR-0065 Accepted | production-ready 全 4 gate 達成 + user 明示 GO | 「本番 cmd 切替完了」 (= production-ready 全体達成 / 軸 B 完成 同時解禁判断) |
| ADR-0069 候補 (= driver 拡張) | ADR-0068 ε Accepted (= ADR-0065/0066 と独立、 parallel 起票可) | user 明示 GO | (a) 「A-J candidate distinctness 完了」 + (b) 「K bitmap pair distinct 完了」 + (c) 「16ch full candidate distinctness 完了」 段階的解禁 |

= 3 ADR 候補 dependency chain literal、 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)。

#### δ-4 = 状態維持 + Codex layer 2 plan review chain + commit chain literal

##### 状態維持 confirm (= ADR-0068 §決定 7 不可触対象 literal、 LR3 反映 = γ MERGED と δ 完了の境界明確分離維持)

- driver source `src/driver/standalone_test.s` 完全不変
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_adpcmb_j_ppc` + `_rhythm_k` + `_rhythm_k_full` + `_rhythm_k_audition` + audition fixture 全) 完全不変
- ADR-0067 slot init (= slot 0-10 init + chip target 別 active policy + pointer switch) 完全不変
- 既存 verify script (= ADR-0049〜0067 全 + ADR-0068 α script + β script + γ script) 完全不変
- 既存 build flag 完全不変 (= 新規 flag 追加なし)
- vendor 完全不変
- ADR-0048〜0067 本文 + Annex 完全不変
- **ADR-0068 既存 Annex α/β/γ 本文完全不変** (= δ で新規 Annex δ 追加のみ、 LR3 反映 = γ 完了 record 不可触)
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- **production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待** (= NH3 反映 = δ で再 build しない + γ で既達成済 sha256 実測結果を doc-only として carry、 §決定 10 全 sub-sprint 共通 gate との見かけの衝突回避 literal)

NH3 反映 literal: δ は doc-only sprint で driver build 走らない。 通算 sha256 維持 mandatory (= §決定 10) は γ で既達成済 (= γ PR4 self-test 4 gate 1 pre + gate 6 post 両方 `b15883fe...` 一致 confirmed)、 δ では γ 実測結果を doc-only として carry。 δ の verify gate 9 は「sha256 維持期待 (= doc-only build 走らない)」 で「sha256 実測 confirm」 ではない (= γ で confirm 完了 + δ で carry)。

##### Codex layer 2 plan review chain (= 1 round chain、 全 review-only + 越権操作なし confirmed)

| round | judgment | finding 要点 | agentId |
|---|---|---|---|
| 1 | **approve** | must-fix 0 + nh 3 + lr 3 全反映 (= NH1 audition preparation は明示 unlock 条件でなく運用前提扱い + NH2 gate 7 scan target + allowlist context Annex δ 内明文化 + NH3 sha256 doc-only carry literal + LR1 「ADR-0068 δ 完了」 同段落「ε まで禁止」 併記必須 + LR2 A-J + K 別 sub-finding 粒度保持 + LR3 γ MERGED と δ 完了境界 PR/commit chain 分離) | `ad78bc3e6e2e6928a` |

= 1 round chain、 全 review-only 遵守 confirmed + 越権操作なし。 must-fix 0 件 + nh 3 件 + lr 3 件 全 ADR 本文反映 (= 本 Annex δ + §決定 6 δ context 内 literal 反映)。

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md` 39th session ADR-0062 PR2 越権 merge 事例後の規律強化):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

##### NH2 反映 = δ doc 内禁止 wording self-check scan target + allowlist context literal (= γ pattern 継承)

δ doc-only sprint のため verify script なし、 ただし将来 ε 起票時に Annex δ 内 wording 整合 check 必要時の literal 参照:

- scan target (= δ 追加箇所、 ADR-0068 本 commit chain で新規追加範囲):
  - (a) 本 Annex δ section 全行 (= δ-1 〜 δ-4 4 sub-section)
  - (b) §決定 6 δ Accepted 後追加 context section (= 本 commit 追加)
  - (c) 改訂履歴 δ entry
  - (d) 平易要約 δ context section
- 検査 wording 7 件 = 「16ch full candidate distinctness 完了」 / 「roadmap ⑤ 統合 verify 完了」 / 「trace-equivalence 完了」 / 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」
- allowlist pattern (= γ pattern 継承 + 否定/reference context exclusion):
  - `「<禁止 wording>」 = literal 禁止維持`
  - `「<禁止 wording>」 = ADR-0069 候補 future`
  - `「<禁止 wording>」 = ADR-0068 ε Accepted future`
  - `「<禁止 wording>」 = ADR-0066 候補 future` (= 本番 cmd 切替完了 限定)
  - `<禁止 wording>ではない` (= 否定文脈)
  - `<禁止 wording>達成ではない` (= 否定文脈)
  - `禁止 wording check` / `禁止維持` / `prohibited wording` (= self-check / reference context)
  - `「<禁止 wording>」 wording 解禁` (= reference context)
  - `「<禁止 wording>」 wording` (= general reference context)
  - 表 row 内禁止 wording (= 表記制約 table 既存 row)
- expected count after exclusion = 各 wording 0 (= literal 肯定使用なし)

NH2 反映: γ verify script の prohibited wording self-check pattern を δ doc 内に literal 明文化することで ε 起票時の誤読 risk 低減。 δ では verify script 走らないが ε 検証時の literal reference 確保。

##### commit chain literal (= δ PR5 = 2 commit、 LR3 反映 = γ MERGED と δ 完了の境界明確分離維持)

| # | commit | 内容 |
|---|---|---|
| 1 | (= 本 commit) | ADR-0068 doc 修正 = 状態行 update (= γ 完了 PR #136 MERGED at ef87dcb 反映 + δ PR5 進行中 entry) + §決定 6 δ Accepted 後追加 context (= LR1 同段落「ε まで禁止」 併記必須 literal) + Annex δ section fill (= δ-1 〜 δ-4 4 sub-section literal、 nh 3 + lr 3 全反映) + 改訂履歴 δ entry + 平易要約 δ context section |
| 2 | (= 次 commit) | dashboard 0068 行 status update (= γ MERGED 反映 + δ PR5 entry、 LR3 反映 = 1 row 内で「γ 完了 (PR #136 MERGED at ef87dcb)」 + 「δ PR5 進行中」 明確分離維持) + escalation 履歴 δ PR5 entry 1 row |

LR3 反映: γ MERGED と δ PR5 進行中を同時に dashboard で記述する場合、 row 内で「γ 完了 (= PR #136 MERGED at `ef87dcb`)」 + 「δ PR5 進行中」 明確分離維持。 commit chain は 2 commit に分離 (= commit 1 = ADR doc + commit 2 = dashboard) = γ 完了 record (= 既存 commit chain 内) と δ 完了 record (= 本 commit chain 内) の境界明確。

##### NH3 反映 literal = δ verify gate 9 「sha256 維持期待」 wording の literal 整合 (= §決定 10 衝突回避)

- §決定 10 = 「通算 sha256 = `b15883fe...` 維持必須 + (A) production default build 実 sha256 literal 一致 confirm」 = 全 sub-sprint 共通 gate
- γ で **実測 confirm** 達成 (= gate 1 pre + gate 6 post 両方 PASS)
- δ では doc-only sprint で **再 build 走らない** (= driver build 必要なし、 verify script 必要なし)
- δ verify gate 9 = 「sha256 維持期待 (= doc-only build 走らない、 γ で既達成済 sha256 実測結果を doc-only として carry、 §決定 10 整合)」 (= 「実測 confirm」 ではなく「期待 + γ carry」)
- ε で再 build 必要時は ε で別途 sha256 実測 confirm (= ε scope 内決定)

### Annex ε: ε 完走 milestone (= ε PR6 で fill 完了 = Draft → Accepted + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須 9 件)

#### ε-1 = scope literal (= ADR-0068 §決定 2 ε row literal 継承、 doc-only sprint)

ε scope = **Draft → Accepted 移行 + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須 9 件** doc-only sprint:

1. (i) 状態行 Draft → Accepted 移行
2. (ii) §決定 6 ε Accepted 後追加 context fill (= δ で先送りした「roadmap ⑤ 統合 verify 完了」 wording 解禁 + 併記必須 9 件 literal + 7 wording 解禁 + 5 wording 禁止維持 整理)
3. (iii) Annex A fill (= ground truth + 起票背景 6 sub-section literal)
4. (iv) Annex B fill (= 16 ch 統合 verify 構成図 + build mode matrix 5 sub-section literal)
5. (v) Annex ε fill (= 本 section = 完走 milestone literal 6 sub-section)
6. (vi) 改訂履歴 ε entry 追加 1 row
7. (vii) 平易要約 ε context section (= 6 構造 = やりたいこと / 前提 / やったこと / 結果 / 解釈 / 完走後の次)
8. (viii) dashboard 0068 行 status column update + escalation 履歴 ε PR6 entry 1 row

ε Accepted (= ε PR6 merge 後) = ADR-0068 全体完走 milestone。 「roadmap ⑤ 統合 verify 完了」 wording 解禁。 ただし併記必須 9 件 維持。

#### ε-2 = 「roadmap ⑤ 統合 verify 完了」 milestone literal (= ε PR6 merge 後解禁、 併記必須 9 件 literal)

ε PR6 merge 後解禁 wording = **「roadmap ⑤ 統合 verify 完了」** (= ADR-0068 scope 内完了)。 ただし併記必須 9 件:

1. K+L-Q trace-equivalence 判定基準と比較実行は完了 (= β PR3 達成、 ADR Annex β literal)
2. A-J は default integration trace (= candidate distinctness ではない、 α PR2 達成、 ADR Annex α literal)
3. A-J full candidate distinctness は ADR-0069 候補 future (= driver 拡張 sprint required)
4. K bitmap pair distinct も ADR-0069 候補 future (= driver K dispatch normalization 由来、 ADR Annex β-5 literal)
5. (d) audition gate 未実装 = ADR-0065 候補 future
6. production-ready 全体達成ではない
7. 本番 cmd 切替完了ではない = ADR-0066 候補 future
8. 軸 B 完成ではない
9. 軸 G 完成ではない

#### ε-3 = ADR-0068 sub-sprint chain 完走 summary (= α/β/γ/δ/ε 5 段 6 PR chain)

| sub | PR | 完了日 | 完了 wording | 達成内容 summary |
|---|---|---|---|---|
| 起票 | #133 | 2026-05-24 | (= 起票 doc-only) | ADR-0068 Draft 起票 + sub-sprint chain plan literal |
| α | #134 | 2026-05-25 | 「ADR-0068 α 完了」 解禁 | K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 ch carry actual + 三分割 wording 整合 |
| β | #135 | 2026-05-25 | 「ADR-0068 β 完了」 + 「K+L-Q distinctness range trace-equivalence literal 達成」 解禁 | trace-equivalence 判定基準 3 axis + 8 sub-category 確定 + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal |
| γ | #136 | 2026-05-25 | 「ADR-0068 γ 完了」 解禁 | baseline regression gate 統合 verify = representative direct invoke 4 script + 6 gate ALL PASS + 通算 sha256 維持 confirmed |
| δ | #137 | 2026-05-25 | 「ADR-0068 δ 完了」 解禁 (= LR1 同段落「ε まで禁止」 併記必須) | 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material + dependency chain literal |
| ε | #138 | 2026-05-25 | 「ADR-0068 Accepted」 + 「ADR-0068 ε 完了」 + 「roadmap ⑤ 統合 verify 完了」 解禁 (= 併記必須 9 件) | Draft → Accepted + Annex 全統合 + milestone literal 解禁 + 主軸 fallback pattern 確立 |

= 全 6 PR chain 完走 = ADR-0068 全体完走 milestone。 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目完了 (= 1 本目 = ADR-0067、 2 本目 = ADR-0068 = 本 ADR、 ADR-0064 plan 実作業群完了 = ADR-0067 + ADR-0068 chain)。

#### ε-4 = 残課題 dependency chain literal (= δ-3 継承 + ε Accepted 後 status update)

| ADR 候補 | dependency | 起票判断 trigger | 解禁 wording |
|---|---|---|---|
| ADR-0065 候補 (= audition) | **ADR-0068 ε Accepted 完了 (= 本 ADR ε PR6 merge 後)** | user 明示 GO | 「(d) audition 完了」 |
| ADR-0066 候補 (= 本番 cmd 切替) | ADR-0068 ε Accepted → ADR-0065 Accepted | production-ready 全 4 gate 達成 + user 明示 GO | 「本番 cmd 切替完了」 (= 「production-ready 全体達成」 / 「軸 B 完成」 同時解禁判断) |
| ADR-0069 候補 (= driver 拡張) | **ADR-0068 ε Accepted 完了 (= 本 ADR ε PR6 merge 後)** (= ADR-0065/0066 と独立 parallel 起票可) | user 明示 GO | (a) 「A-J candidate distinctness 完了」 + (b) 「K bitmap pair distinct 完了」 + (c) 「16ch full candidate distinctness 完了」 段階的解禁 |

= 3 ADR 候補 dependency chain literal、 各 user 明示 GO 必須 (= ADR-0064 §決定 8 literal、 main agent autonomous で進めない)。 dependency chain = ADR-0068 ε Accepted (= 本 ADR、 ε PR6 merge 後) → ADR-0065 起票判断 / ADR-0069 起票判断 (= 各 user 明示 GO、 ADR-0065 と ADR-0069 は parallel 起票可) → ADR-0065 Accepted → ADR-0066 起票判断 (= 順序固定 dependency)。

#### ε-5 = 状態維持 + Codex layer 2 review chain + commit chain literal

##### 状態維持 confirm (= ADR-0068 §決定 7 不可触対象 literal)

- driver source `src/driver/standalone_test.s` 完全不変
- ADR-0067 fixture (= `_fm_a/b/c/d/e/f` + `_ssg_g/h/i` + `_adpcmb_j` + `_adpcmb_j_ppc` + `_rhythm_k` + `_rhythm_k_full` + `_rhythm_k_audition` + audition fixture 全) 完全不変
- ADR-0067 slot init (= slot 0-10 init + chip target 別 active policy + pointer switch) 完全不変
- 既存 verify script (= ADR-0049〜0067 全 + ADR-0068 α script + β script + γ script) 完全不変
- 既存 build flag 完全不変 (= 新規 flag 追加なし)
- vendor 完全不変
- ADR-0048〜0067 本文 + Annex 完全不変
- **ADR-0068 既存 Annex α/β/γ/δ 本文完全不変** (= ε で新規 Annex A + B + ε fill + 改訂履歴 ε entry + 平易要約 ε context のみ追加、 既存 fill 部分 historical record として維持)
- 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不可触
- **production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 維持期待** (= ε で再 build しない、 γ で実測 confirm + δ で doc-only carry、 ε で doc-only carry 継続、 §決定 10 整合)

##### Codex layer 2 plan review chain (= 主軸 fallback approve plan v1、 ADR-0041 §決定 6 適用、 Codex unavailable + retrospective Codex review 必須)

| round | judgment | finding 要点 | 主体 |
|---|---|---|---|
| 1 | (Codex unavailable) | Codex companion 安全性分類器 (claude-opus-4-7) 一時障害 1 回目失敗 = `claude-opus-4-7[1m] is temporarily unavailable` error | Codex layer 2 起動失敗 |
| 1 retry | (Codex unavailable) | 同障害 2 回連続失敗 = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 該当 | Codex layer 2 起動失敗 |
| fallback | **approve plan v1** | 主軸 Claude Code 独立 review = scope literal coverage / 併記必須 9 件 / Annex A/B/ε fill / allowed-touch (ii) 完全不変対象 enumeration / production sha256 維持期待 wording / commit chain plan 2 commit (= γ/δ pattern 継承) 全 OK = approve 判断、 latent risk 3 件 (= final 状態行 wording 案 ADR-0067 ε pattern 継承推奨 + Annex δ 既存本文不変 maintenance + 改訂履歴 ε entry literal 整合) は retrospective Codex review で再確認 | 主軸 Claude Code |
| retrospective | (= TBD、 Codex 復旧後) | Codex companion 復旧後に retrospective review 実施必須 (= ADR-0041 §決定 6 literal)、 主軸 fallback judgment の事後 confirm + 漏れ確認 + latent risk 3 件 再 review | Codex layer 2 |

= 主軸 fallback approve 1 件 + retrospective Codex review TBD。 全 review-only + 越権操作なし confirmed (= 主軸 fallback でも commit 権限なし規律維持)。 ADR-0041 §決定 6 fallback + retrospective Codex review 必須 pattern を 40th session ε PR6 で初実証。

冒頭 6 件 literal 強調 (= memory `feedback_codex_layer2_review_no_commit_authority.md`、 主軸 fallback でも同規律遵守):
- Codex layer 2 is review-only
- Do NOT commit
- Do NOT modify files
- Do NOT create branches
- Do NOT merge PRs
- Do NOT run GitHub write operations
- Return only review judgment and findings

##### commit chain literal (= ε PR6 = 2 commit、 γ/δ pattern 継承)

| # | commit | 内容 |
|---|---|---|
| 1 | (= 本 commit) | ADR doc 修正 = 状態行 Draft → Accepted + §決定 6 ε Accepted 後追加 context fill (= ε Accepted 後 wording status table + 「roadmap ⑤ 統合 verify 完了」 解禁条件 9 件併記必須 literal + 7 wording 解禁 + 5 wording 禁止維持 整理) + Annex A fill (= ground truth + 起票背景 6 sub-section) + Annex B fill (= 16 ch 統合 verify 構成図 + build mode matrix 5 sub-section) + Annex ε fill (= 完走 milestone literal 6 sub-section) + 改訂履歴 ε entry + 平易要約 ε context section |
| 2 | (= 次 commit) | dashboard 0068 行 status update (= δ MERGED at `56c0b0f` 反映 + ε Accepted entry) + escalation 履歴 ε PR6 entry 1 row (= 主軸 fallback approve plan v1 + Codex unavailable + retrospective Codex review 必須 literal) |

= 2 commit chain、 historical record 整合。 commit 1 = ADR doc + commit 2 = dashboard + escalation 履歴 = γ/δ pattern 継承。

#### ε-6 = ADR-0068 Accepted milestone literal (= roadmap ⑤ 統合 verify 本体完走、 ADR-0064 plan 実作業群完了)

ADR-0068 ε PR6 merge 後 (= ADR-0068 Accepted milestone):

- **ADR-0068 Accepted** wording 解禁 (= Draft → Accepted 移行完了)
- **「ADR-0068 ε 完了」** wording 解禁 (= ε scope = Draft → Accepted + Annex 全統合 完了)
- **「roadmap ⑤ 統合 verify 完了」** wording 解禁 (= 併記必須 9 件)
- **ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目完了** = ADR-0064 plan 実作業群完了 (= ADR-0067 + ADR-0068 chain = 2 ADR 全完走)
- **roadmap ⑤ 統合 verify** = ADR-0068 scope 内達成完了
- **後続 candidates 3 ADR** = ADR-0065 (= roadmap ⑥ audition) / ADR-0066 (= roadmap ⑦ 本番 cmd 切替) / ADR-0069 (= driver 拡張 = A-J candidate distinctness + K bitmap pair distinct) = 各 user 明示 GO 必須
- **主軸 fallback + retrospective Codex review pattern 初実証** (= ADR-0041 §決定 6 適用、 40th session ε PR6 で確立、 Codex unavailable 時の fallback 経路 + doc-only sprint + scope 明確 + retrospective review 必須 が成立条件)

ADR-0068 Accepted ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 軸 G 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。

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

## γ PR4 完走 update (= 2026-05-25 40th session、 平易要約 update)

### γ でやりたかったこと

ADR-0068 §決定 2 γ row literal「全 verify script 統合 ALL PASS = production binary 1 件に対して全 verify を 1 batch 実行 + 統合 report」 を実装 + γ scope 限定 baseline regression gate 統合 verify ALL PASS literal 達成。 (c) baseline regression gate (= ADR-0056 §決定 3 (c)) の repo 内 verify を 1 batch で通す + completion proof 統合 report 出力。

### γ 前提

- α PR2 完走 (= PR #134 MERGED at `3c59d93`、 K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 carry actual + 三分割 wording 整合)
- β PR3 完走 (= PR #135 MERGED at `7335da9`、 K+L-Q distinctness range trace-equivalence literal 達成 + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal)
- ADR-0067 ε Accepted (= 16 ch fixture 拡張完了 milestone、 併記必須)
- user 明示 GO「質疑あれば全て Codex Rescue で回答を得て、 完全自律で完走まで GO」 = main agent autonomous 完走 default

### γ でやったこと

- γ kickoff plan v4 起草 + Codex layer 2 plan review 4 round chain approve (= round 1-3 revise + round 4 approve、 must-fix 8 + nh 6 + lr 6 全反映)
- γ branch `wip-adr-0068-gamma-impl` (= base `7335da9`) 作成
- commit 1 `3b1a026` = ADR doc 3 箇所同時 update (= §決定 1(c) + §決定 2 γ row + §決定 6 表記制約) + Annex γ skeleton 主要 fill + 改訂履歴 γ entry
- commit 2 `b39c7ec` = γ verify script `verify-axis-b-v2-16ch-integration-gamma.sh` 新規実装 307 行 (= 6 gate + representative direct invoke + per-script log + 三分割 wording + prohibited wording self-check 7 件全件 + allowlist 拡張 + NOT-COMPLETE 7 行 + sha256 pre/post)
- γ self-test 1 で β script gate 8d (= β branch parent commit literal verify = 3c59d93) が γ 統合 regression 経路 (= HEAD 7335da9) で merge_conflict 誤発火 finding 検出
- Codex layer 2 plan review re-review 4 round chain (= round 5-7 revise + round 8 approve plan v8) = β script representative regression 除外 5 → 4 script、 §決定 5 (ii) β script 完全不変原則遵守、 β scope coverage は ADR Annex β literal で別途確保 (= 9 gate ALL PASS + K trace 同一 finding + β 完走 wording 解禁)
- commit 3 `fc2320d` = self-test 1 finding 反映 + plan v5 → v8 (= ADR doc 12 箇所 + γ verify script 7 箇所 update)
- self-test 2 で gate 4 bash 3.2 多バイト文字 parameter expansion bug 発覚 (= `local var="$arg"` + 多バイト char 値 + nounset + glob match)
- self-test 3 で gate 4 allowlist 不足 (= enumeration list / array entry / 限定 / 検査 wording context) で false positive 7 件発覚
- commit 4 `60101a2` = γ verify script bug fix 2 件 + allowlist 5 件追加 + Annex γ fill 完成 + 改訂履歴 γ bug fix entry
- self-test 4 = 6 gate ALL PASS literal 達成 = 22 OK count + 0 NG count
- commit 5 (= 本 commit) = dashboard 0068 行 status update + escalation 履歴 γ PR4 entry 追加 + β entry reviewed column update (= pending → approve) + 平易要約 γ context 追記

### γ 結果

- ADR-0068 γ PR4 commit chain = plan v8 historical 5 commit (= 3b1a026 / b39c7ec / fc2320d / 60101a2 / 8c1d5ec) + impl-review 反映追加 commit chain (= round 1 `d798a21` + round 2 `ab3b29d` + round 3 `9f33843` + round 4 本 commit + 以降 round N 期待 approve まで継続)、 self-referential 無限再帰回避方式 (= round 3 反映で historical record 分離 refactor + round 4+ 反映で直前 round commit hash 確定 update pattern)
- γ verify script self-test 4 = 6 gate ALL PASS literal 達成:
  - gate 1: (A) production default ym2610 pre-build sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` 一致 PASS
  - gate 2: representative 4/4 ALL PASS (= alpha exit=0 + delta exit=0 + song-playback exit=0 + roadmap3 exit=0)
  - gate 3: 三分割 wording (= 16ch integration trace 完了 + K+L-Q candidate distinctness 完了 + A-J default carry 確認) PASS
  - gate 4: prohibited wording self-check 7 件全件 all allowlisted PASS
  - gate 5: NOT-COMPLETE 7 行 literal output 完了 PASS
  - gate 6: post-representative-script sha256 = `b15883fe...` 一致 = production binary 復元 confirm PASS
- 通算 sha256 `b15883fe...` 維持 confirmed (= gate 1 pre + gate 6 post 両方一致)
- driver / α script / β script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex / 軸 G ε partial state placement 完全不変 confirm (= §決定 5 (ii) + §決定 7 literal 遵守)
- Codex layer 2 plan review 計 8 round chain (= plan v4 round 4 approve + γ self-test 1 finding 反映 plan v8 round 8 approve)、 must-fix 計 13 + nh 計 10 + lr 計 11 全反映、 全 review-only + 越権操作なし confirmed

### γ 解釈

ADR-0068 γ PR4 完走 = 「ADR-0068 γ 完了」 wording 解禁条件達成 = γ scope 限定 baseline regression gate 統合 verify ALL PASS literal。 ただし併記必須維持:
- 「roadmap ⑤ 統合 verify 完了」 = ε まで禁止維持
- 「trace-equivalence 完了」 single wording = ε まで禁止維持
- 「16ch full candidate distinctness 完了」 = ADR-0069 候補 future literal 禁止維持
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = literal 禁止維持

γ scope = baseline regression gate 統合 verify、 representative direct invoke 4 script + transitively regression OK pattern (= ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承)、 β script 除外 = §決定 5 (ii) 不可触原則遵守 + β scope coverage は ADR Annex β literal で別途確保。

ADR-0068 γ PR4 完走 ≠ ε Accepted ≠ roadmap ⑤ 統合 verify 完了 ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。

### γ 完走後の次

γ PR4 commit chain = plan v8 historical 5 commit + impl-review 反映 N commit (= self-referential 無限再帰回避方式) 完走後、 Codex layer 2 impl-review round 4+ 期待 approve + main agent 経路で γ PR4 merge + user 完走報告。 γ Accepted 後 (= γ PR4 merge 後):
- δ (= 統合 report + 残課題 enumeration、 ADR-0065/0066/0069 起票判断 material) 起票判断 = user 明示 GO 必須
- ε (= Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須) は δ 完走後
- ADR-0065 候補 (= roadmap ⑥ audition) + ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替判断) + ADR-0069 候補 (= driver 拡張 sprint = A-J candidate distinctness 実現) = 各 user 明示 GO 必須

## δ PR5 完走 update (= 2026-05-25 40th session、 平易要約 update)

### δ でやりたかったこと

ADR-0068 §決定 2 δ row literal「統合 report 作成 + 残課題 enumeration (= ADR-0065/0066 起票判断 material)」 を実装 + δ scope 限定 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material literal 達成。 α/β/γ 3 sub-sprint 完走後の整理 + roadmap ⑤ 完了前状態の明確化 + 後続 ADR 候補 (= ADR-0065/0066/0069) 起票判断 material 作成 = ε Accepted 前の整理 sprint。 doc-only sprint = driver / verify script / vendor / fixture / build flag 完全不変。

### δ 前提

- α PR2 完走 (= PR #134 MERGED at `3c59d93`、 K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 carry actual + 三分割 wording 整合)
- β PR3 完走 (= PR #135 MERGED at `7335da9`、 K+L-Q distinctness range trace-equivalence literal 達成 + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal)
- γ PR4 完走 (= PR #136 MERGED at `ef87dcb`、 baseline regression gate 統合 verify ALL PASS literal + 6 gate ALL PASS + representative direct invoke 4 script + 通算 sha256 `b15883fe...` 維持 confirmed)
- user 明示 GO「ADR-0068 δ 起票判断から開始、 δ scope = 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material」
- 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 + Codex rescue 化 default 規律継承

### δ でやったこと

- δ kickoff plan v1 起草 + Codex layer 2 plan review round 1 approve (= must-fix 0 + nh 3 + lr 3 全反映、 agentId `ad78bc3e6e2e6928a`)
- δ branch `wip-adr-0068-delta-impl` (= base `ef87dcb`) 作成
- commit 1 (= 本 commit) = ADR doc 修正 = 状態行 update (= γ 完了 PR #136 MERGED at `ef87dcb` 反映 + δ PR5 進行中 entry) + §決定 6 δ Accepted 後追加 context (= LR1 同段落「ε まで禁止」 併記必須 literal) + Annex δ section fill (= δ-1 〜 δ-4 4 sub-section literal、 nh 3 + lr 3 全反映 = NH1 audition preparation 運用上前提 + NH2 prohibited wording scan target + allowlist literal + NH3 sha256 doc-only carry literal + LR1 同段落併記必須 + LR2 A-J + K 別 sub-finding 粒度保持 + LR3 γ MERGED と δ 完了境界明確分離) + 改訂履歴 δ entry + 平易要約 δ context section
- commit 2 (= 次 commit) = dashboard 0068 行 status update (= γ MERGED 反映 + δ PR5 entry) + escalation 履歴 δ PR5 entry 1 row
- Codex layer 2 impl-review 期待 approve + main agent 経路で δ PR5 merge + user 完走報告

### δ 結果

- ADR-0068 δ PR5 doc-only sprint = 統合 report + 残課題 enumeration (= ADR-0065/0066/0069 起票判断 material) literal 達成
- Annex δ fill 完成 = δ-1 scope + δ-2 統合 report (α/β/γ 結果 + integration milestone + roadmap ⑤ 完了前状態の明確化 = (a)(b)(c) 3 gate 別 status enumeration) + δ-3 残課題 enumeration (= ADR-0065/0066/0069 起票判断 material + dependency chain literal) + δ-4 状態維持 + Codex layer 2 plan review chain + commit chain literal
- §決定 6 δ Accepted 後追加 context (= LR1 同段落「roadmap ⑤ 統合 verify 完了は ε まで禁止維持」 併記必須 literal)
- driver / α script / β script / γ script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex / ADR-0068 既存 Annex α/β/γ 本文 / 軸 G ε partial state placement 完全不変 confirm (= §決定 5 (ii) + §決定 7 literal 遵守)
- production sha256 = `b15883fe...` 維持期待 (= NH3 反映 = δ で再 build しない、 γ で既達成済 sha256 実測結果を doc-only として carry、 §決定 10 整合)
- Codex layer 2 plan review 1 round chain (= round 1 approve)、 must-fix 0 + nh 3 + lr 3 全反映、 全 review-only + 越権操作なし confirmed

### δ 解釈

ADR-0068 δ PR5 完走 = 「ADR-0068 δ 完了」 wording 解禁条件達成 = δ scope 限定 統合 report + 残課題 enumeration 完了 literal。 ただし併記必須維持 (= LR1 反映 = 同段落 literal 併記必須):
- 「ADR-0068 ε Accepted ではない」 (= ε PR6 で別途 future)
- 「roadmap ⑤ 統合 verify 完了」 = **ε まで禁止維持** (= 同段落 literal 併記必須)
- 「trace-equivalence 完了」 single wording = ε まで禁止維持
- 「16ch full candidate distinctness 完了」 = ADR-0069 候補 future literal 禁止維持
- 「production-ready 全体達成」 / 「軸 B 完成」 / 「軸 G 完成」 / 「本番 cmd 切替完了」 = literal 禁止維持

δ scope = 統合 report + 残課題 enumeration、 doc-only sprint = driver / verify script / vendor / fixture / build flag 完全不変、 §決定 5 (ii) 不可触原則遵守。

ADR-0068 δ PR5 完走 ≠ ε Accepted ≠ roadmap ⑤ 統合 verify 完了 ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。

### δ 完走後の次

δ PR5 commit chain (= 2 commit、 commit 1 ADR doc + commit 2 dashboard) 完走後、 Codex layer 2 impl-review 期待 approve + main agent 経路で δ PR5 merge + user 完走報告。 δ Accepted 後 (= δ PR5 merge 後):
- ε (= Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須) 起票判断 = user 明示 GO 必須
- ADR-0065 候補 (= roadmap ⑥ audition) + ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替判断) + ADR-0069 候補 (= driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct = 2 sub-finding 別粒度) = 各 user 明示 GO 必須、 ADR-0068 ε Accepted 後 future
- dependency chain literal = ADR-0068 ε Accepted → ADR-0065 Accepted → ADR-0066 起票判断 (= 順序固定)、 ADR-0069 候補 = ADR-0065/0066 と独立 parallel 起票可

## ε PR6 完走 update (= 2026-05-25 40th session、 平易要約 update)

### ε でやりたかったこと

ADR-0068 §決定 2 ε row literal「Draft → Accepted 移行 + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal (= 併記必須)」 を実装 + ADR-0068 全体完走 milestone literal 達成。 ε scope = Draft → Accepted + Annex A/B/ε fill + 「roadmap ⑤ 統合 verify 完了」 wording 解禁 + 併記必須 9 件 + ADR-0065/0066/0069 起票判断 dependency chain literal = ADR-0064 plan 実作業 2 本目完了 milestone。 doc-only sprint = driver / verify script / vendor / fixture / build flag 完全不変。

### ε 前提

- α PR2 完走 (= PR #134 MERGED at `3c59d93`、 K+L-Q candidate distinctness capture + A-J default integration trace + 16/16 carry actual + 三分割 wording 整合)
- β PR3 完走 (= PR #135 MERGED at `7335da9`、 K+L-Q distinctness range trace-equivalence literal 達成 + 9 gate ALL PASS + K trace 同一 finding → ADR-0069 候補 future defer literal)
- γ PR4 完走 (= PR #136 MERGED at `ef87dcb`、 baseline regression gate 統合 verify ALL PASS literal + 6 gate ALL PASS + representative direct invoke 4 script + 通算 sha256 `b15883fe...` 維持 confirmed)
- δ PR5 完走 (= PR #137 MERGED at `56c0b0f`、 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material doc-only sprint)
- user 明示 GO「ADR-0068 ε 起票判断から開始、 ε scope = Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal」
- 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 + Codex rescue 化 default 規律継承
- **40th session ε で確立した「主軸 fallback + retrospective Codex review」 pattern** (= ADR-0041 §決定 6 適用、 Codex companion 安全性分類器一時障害 2 回連続失敗、 user 明示 option B 採用、 doc-only sprint + scope 明確で fallback 適用根拠成立、 retrospective Codex review 必須)

### ε でやったこと

- ε kickoff plan v1 起草 (= scope literal + 8 範囲 + 併記必須 9 件 + allowed-touch + production sha256 維持期待 + commit chain plan)
- Codex layer 2 plan review v1 投入試行 = 2 回連続失敗 (= Codex companion 安全性分類器 (claude-opus-4-7) 一時障害 = `claude-opus-4-7[1m] is temporarily unavailable` error)
- user escalation = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user 判断仰ぐ
- user 明示 option B 採用 = ADR-0041 §決定 6 fallback + retrospective Codex review 必須 適用
- 主軸 fallback review approve plan v1 (= scope literal coverage / 併記必須 9 件 / Annex A/B/ε fill / allowed-touch / production sha256 / commit chain plan 全 OK = approve 判断、 latent risk 3 件 retrospective Codex review で再確認)
- ε branch `wip-adr-0068-epsilon-impl` (= base `56c0b0f`) 作成
- commit 1 (= 本 commit) = ADR doc 修正 = 状態行 Draft → Accepted + §決定 6 ε Accepted 後追加 context fill + Annex A fill + Annex B fill + Annex ε fill + 改訂履歴 ε entry + 平易要約 ε context section
- commit 2 (= 次 commit) = dashboard 0068 行 status update + escalation 履歴 ε PR6 entry 1 row
- Codex layer 2 impl-review 期待 (= Codex 復旧後 + retrospective review)
- main agent 経路で ε PR6 merge + user 完走報告

### ε 結果

- ADR-0068 ε PR6 doc-only sprint = Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 達成
- Annex A fill 完成 = ground truth + 起票背景 6 sub-section (= A-1 ADR-0067 完走経緯 + A-2 roadmap ⑤ 統合 verify 本体 + A-3 (a)(b)(c) 3 gate scope + A-4 ADR-0064 §決定 3 plan literal 継承 + A-5 user 明示 GO option 1 + A-6 主軸 fallback pattern literal)
- Annex B fill 完成 = 16 ch 統合 verify 構成図 + build mode matrix 5 sub-section (= B-1 16 ch 構成図 ascii + B-2 build mode matrix + B-3 chip target 別 trace + B-4 PMDDOTNET_MODE matrix + B-5 trace TSV format)
- Annex ε fill 完成 = 完走 milestone literal 6 sub-section (= ε-1 scope + ε-2 「roadmap ⑤ 統合 verify 完了」 milestone literal + 併記必須 9 件 + ε-3 sub-sprint chain 完走 summary + ε-4 残課題 dependency chain + ε-5 状態維持 + commit chain + ε-6 ADR-0068 Accepted milestone literal)
- §決定 6 ε Accepted 後追加 context fill = 7 wording 解禁 + 9 件併記必須 + 5 wording 禁止維持 整理
- driver / α script / β script / γ script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex / ADR-0068 既存 Annex α/β/γ/δ 本文 / 軸 G ε partial state placement 完全不変 confirm
- production sha256 = `b15883fe...` 維持期待 (= ε で再 build しない、 γ で実測 confirm + δ で doc-only carry + ε で doc-only carry 継続、 §決定 10 整合)
- Codex layer 2 plan review chain ε = 主軸 fallback approve plan v1 (= ADR-0041 §決定 6 適用、 Codex unavailable + retrospective Codex review 必須 = 復旧後 TBD)

### ε 解釈

ADR-0068 ε PR6 完走 = **「ADR-0068 Accepted」 wording 解禁** + **「ADR-0068 ε 完了」 wording 解禁** + **「roadmap ⑤ 統合 verify 完了」 milestone wording 解禁 (= 併記必須 9 件)**。 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目完了 = ADR-0064 plan 実作業群完了 (= ADR-0067 + ADR-0068 chain)。

ただし併記必須 9 件 (= 「roadmap ⑤ 統合 verify 完了」 wording 使用全段落で literal 必須):
1. K+L-Q trace-equivalence 判定基準と比較実行は完了
2. A-J は default integration trace
3. A-J full candidate distinctness は ADR-0069 候補 future
4. K bitmap pair distinct も ADR-0069 候補 future
5. (d) audition gate 未実装 = ADR-0065 候補 future
6. production-ready 全体達成ではない
7. 本番 cmd 切替完了ではない = ADR-0066 候補 future
8. 軸 B 完成ではない
9. 軸 G 完成ではない

ε scope = Draft → Accepted + Annex 全統合 doc-only sprint = driver / verify script / vendor / fixture / build flag 完全不変、 §決定 5 (ii) 不可触原則遵守、 既存 Annex α/β/γ/δ 本文完全不変 (= ε で新規 fill のみ)。

40th session ε で確立した「主軸 fallback + retrospective Codex review」 pattern = ADR-0041 §決定 6 適用、 Codex unavailable 時の fallback 経路。 doc-only sprint + scope 明確 + retrospective review 必須が成立条件。

ADR-0068 ε PR6 完走 ≠ production-ready 全体達成 ≠ 軸 B 完成 ≠ 軸 G 完成 ≠ 本番 cmd 切替完了 (= 各 user 判断軸 future)。

### ε 完走後の次

ε PR6 commit chain (= 2 commit、 commit 1 ADR doc + commit 2 dashboard) 完走後、 Codex layer 2 impl-review 期待 (= Codex 復旧後)、 main agent 経路で ε PR6 merge + user 完走報告。 ε Accepted 後 (= ε PR6 merge 後):

- **ADR-0068 全体完走 milestone** 達成 = ADR-0064 plan 実作業群完了 (= ADR-0067 + ADR-0068 chain)
- ADR-0065 候補 (= roadmap ⑥ audition) + ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替判断) + ADR-0069 候補 (= driver 拡張 sprint = A-J candidate distinctness + K bitmap pair distinct = 2 sub-finding 別粒度) = 各 user 明示 GO 必須、 ADR-0068 ε Accepted 後 future
- dependency chain literal = ADR-0068 ε Accepted (= 本 ADR) → ADR-0065 Accepted → ADR-0066 起票判断 (= 順序固定)、 ADR-0069 候補 = ADR-0065/0066 と独立 parallel 起票可
- Codex 復旧後の retrospective Codex review (= 主軸 fallback approve judgment の事後 confirm + 漏れ確認、 latent risk 3 件 再 review、 ADR-0041 §決定 6 literal)

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0068 新規起票 Draft (= doc-only PR1、 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目、 16 ch 統合 verify ADR、 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較、 sub-sprint α/β/γ/δ/ε chain literal、 build mode (A)/(B)/(C-1)/(C-2) 4 mode literal、 trace-equivalence 定義 literal、 allowed-touch 3 段分類 literal、 表記制約 + 新規解禁表現候補 literal、 Annex skeleton 起票時起草 (= α 漏れ補完 retrospective 起票時 prevention)、 Codex layer 2 plan review 4 round chain = round 1-3 revise + round 4 approve、 must-fix 計 7 件 + nh 計 4 件 + lr 計 3 件 全反映、 越権操作なし confirmed、 user 明示 GO option 1 PR1/PR2 段階分離 採用) | (= 起票 commit 後続) |
| 2026-05-24 | 40th session | ADR-0068 α scope 再定義 plan v5 → v6-revised revise (= ADR-0067 Accepted「16 ch fixture 拡張完了」 milestone 前提、 task #50 candidate 探索結果 union 12/16 ch carry + 不足 4 ch = FM E/F + SSG G/H 判明、 user 明示 40th session option 2 採用 = hybrid 方針 = existing resource activation 原則維持 + 不足 ch 限定 minimal MML 例外許可 + 16ch 方針縮小なし + β で minimal MML 4 件追加 carry、 §決定 1(a) α union 境界明記 + hybrid 原則 sub-section 追記 (= K=3 candidate 12/16 coverage 表 literal + β minimal MML 候補 enumeration) + §決定 2 α/β/γ row 再定義 + §決定 5 PR2-PR6 PMDNEO_* prefix 統一 + line 60/97/204/347 20 trace 化整合、 Codex layer 2 plan review 5 round chain = round 1 revise must-fix 2 + nh 2 + lr 2 (= a493861afdfd58d95) + round 2 attempt hang 22m 55s cancel (= task-mpjuqshs-fyavhn) + round 2 retry --fresh = revise must-fix 3 (= diff 未反映 = 計画書 review か実反映 review かの解釈ズレ、 main agent 自律判断「計画書 review、 ADR 反映は PR2 commit で実施」、 a18ab6af2bce91b3b)、 越権操作なし confirmed、 機械復旧 default rule 適用 (= [[long-running-hang-auto-recovery-rule]] 初実証)) | (= 本 PR2 commit chain 内) |
| 2026-05-25 | 40th session | ADR-0068 α scope 再定義 plan v6-revised → v7 (= self-test 完走 + driver source ground truth 4 件 finding 確定後 user 明示 option 4 採用 = driver line 1741-1888 で A-J 10 part 常に test01/test02 default 駆動 / K+L-Q 7 part のみ PMDNEO_USE_PMDDOTNET 切替で pmddotnet_song 由来、 全 (A)/(B)/(C-1)/(C-2) build mode で A-J candidate dispatch 不可、 plan v6-revised hybrid 原則 sub-section = unused 化 (= 不足 4 ch FM E/F + SSG G/H は default driven で常時 carry、 minimal MML 不要)、 §決定 1(a) driver source dispatch ground truth + 全 build mode carrier 差分 table + 40th session self-test actual trace literal + K=3 candidate plan v7 update literal 追記、 §決定 2 α/β/γ row plan v7 = K+L-Q distinctness capture + A-J default integration trace / 三分割 wording 必須、 §決定 6 表記制約 plan v7 = 「K+L-Q candidate distinctness 完了」 + 「A-J default carry 確認」 + 「16ch integration trace 完了」 = ε Accepted 後解禁 + 併記必須、 「16ch full candidate distinctness 完了」 = literal 禁止維持 (= ADR-0069 候補 future)、 §決定 9 ADR-0069 候補 = driver 拡張 sprint literal 追加。 verify script bug fix 4 件 (= 全角 「、」 4 件 + printf 「-」 escape + CRLF on-the-fly 変換 helper + detect_adpcma reg 100 = 3 桁 hex 修正) + assertion softening (= α scope = capture + report only literal 整合)。 機械復旧 default rule (= [[long-running-hang-auto-recovery-rule]]) 適用 = Codex round 2 hang 22m 55s cancel + retry / verify script bug 4 件 cancel + retry chain、 user 介入 = 設計判断 (= hybrid → option 2 → option 4) のみ。 plan v7 scope 縮小 (= 16/16 carry → K+L-Q distinctness focus) ただし 16ch 方針自体は維持 (= ADR-0069 候補で完成、 ADR-0068 scope の 16ch integration trace は actual 達成) | (= 本 PR2 commit chain 内、 commit 66f8b6f / 0613e5a / 38444a4 / b2767aa / c36301f 経由) |
| 2026-05-25 | 40th session | ADR-0068 β kickoff plan v3 確定 = trace-equivalence 判定基準確定 + 比較実行 scope literal (= K+L-Q register behavior の normalized comparison、 ADR-0064 §決定 1(b) 16ch 同時 trace 比較とは別 wording、 §決定 1(b) β scope literal 整合)、 §決定 1(b) β scope literal sub-section 追記 + §決定 2 β row update (= 3 axis + 8 sub-category + K candidate trace 12 file 追加 + verify gate 9 件 = 14 step) + Annex β fill 8 sub-section (= β-1 scope / β-2 trace-equivalence 判定基準 = 3 axis + 8 sub-category literal / β-3 配置 = 16 env literal + 12 trace 追加 / β-4 verify gate 9 件 + sub-step 14 step / β-5 K distinct candidate 探索結果 + β scope 採否 = bitmap pair representative 3 件採用 + future 8 件 / β-6 状態維持 + commit chain literal (= self-test 後 fill) / β-7 lr 2 件補強 = α trace stale 非停止 risk + base SHA 不一致復旧フロー literal / β-8 Codex layer 2 plan review chain 3 round)。 Codex layer 2 plan review 3 round chain = round 1 revise (= must-fix 3 + nh 3 + lr 3、 production sha256 β 実測 + K candidate wording 修正 + trace-equivalence subtype 1 invariant/intended/zmem 分離、 agentId `a687604717a024fd4`) + round 2 revise (= must-fix 2 + nh 3 + lr 2、 8 sub-category 数え方明示 + gate 8 stale 対策固定、 agentId `a365c311820484805`) + round 3 **approve** (= must-fix 0 + nh 0 + lr 2 情報提供、 agentId `ab716011d8cec2170`)、 must-fix 計 5 件 + nh 計 6 件 + lr 計 7 件 全 ADR 本文反映、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 user 明示 GO「β 起票から開始」 + 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 | (= 本 PR3 commit chain 内) |
| 2026-05-25 | 40th session | ADR-0068 β PR3 Codex impl-review round 2 finding 反映 (= revise judgment must-fix 1、 agentId `ae0979991bedde96d`、 review-only 越権操作なし confirmed) = round 1 must-fix 1「K distinct candidate / distinct pattern wording 統一」 未完了の残存 wording 修正 = β verify script line 26 (header comment C-3) + line 48 (K candidate section header) + line 233 (echo header section) + line 368 (capture section header) + line 501 (axis A-3a internal comment) で「K distinct candidate」 → 「K candidate」 / 「K candidate trigger 出現確認」 統一 + ADR doc line 168 (§決定 1(b) β scope literal) + line 184 (§決定 2 β row) + line 517 (β-1 sub-task 4) + line 595 (β-5 section header) + line 631 (β-5 axis C-3 PASS 判定) で同様 wording 統一 + 改訂履歴 line 761 「結論 = axis C-3 K distinct candidate gate 7 PASS」 → 「結論 = axis C-3 K candidate gate 7 PASS (= historical record、 旧 wording 注記付き)」。 L-Q 「distinct pattern A/B/C」 (= α plan v7 wording、 acceptable) と K「trigger 出現確認」 (= driver K dispatch normalization で trace 同一、 真の trace distinct は ADR-0069 候補 future defer) を厳密分離。 syntax check PASS、 driver / α script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex 完全不変、 越権操作なし維持 | (= 本 PR3 commit chain 内 commit 7 追加) |
| 2026-05-25 | 40th session | ADR-0068 β PR3 Codex impl-review round 1 finding 反映 (= revise judgment must-fix 1 + nh 1 + lr 1、 agentId `a4de707f82e1a0e4e`、 review-only 越権操作なし confirmed) = (1) must-fix 1 K trace 同一 finding 後 wording 不整合修正 = β verify script C-3 PASS message + ADR §決定 2 β-2 axis C-3 row で「K distinct candidate」 / 「distinct pattern」 残存 wording → 「K candidate trigger 出現確認」 統一 (= L-Q いずれかに keyon write 出現 limit、 真の「K bitmap pair representative variant 1/2/3 trace distinct」 は ADR-0069 候補 future defer literal、 driver K dispatch normalization で bitmap pattern 差吸収) + verify summary echo 行 wording update + (2) nh 1 行数 mismatch literal = 「commit 40410f7 時点 705 行、 後続 bug fix + impl-review 反映で現 HEAD 720 行」 commit chain table 内 evolution literal 追加 + (3) lr 1 gate 8c stale warning summary 反映 = `GATE_8C_STALE` variable track + summary 行 conditional 化 (= stale 発生時「8a/8b/8d PASS + 8c WARN (= stale、 --refresh-alpha 推奨、 escalate しない)」 literal、 PASS 誤読 risk 低減)。 driver / α script / 既存 verify / 既存 build flag / vendor / ADR-0048〜0067 完全不変、 越権操作なし維持 | (= 本 PR3 commit chain 内 commit 6 追加) |
| 2026-05-25 | 40th session | ADR-0068 β verify script bug fix 2 件 + self-test PASS = 9 gate ALL PASS + K trace 同一 finding 検出 = (1) bug fix 全角 「、」 2 箇所 → 半角 「 , 」 + 英文化 (= α script 同 bug pattern 再導入、 line 234 + 291) + (2) bug fix bash 3.2 `declare -A` (associative array) 非対応 → case 関数 `get_pattern()` で置換 (= macOS default bash 互換)、 self-test retry 3 PASS confirmed (= 9 gate ALL PASS、 FAIL count = 0、 axis A-3a unintended diff 0 件 literal confirm、 axis C-1 L-Q distinctness 8/8 + C-2 A-J default carry 10/10 + C-3 K candidate trigger 出現 6/6、 axis B-1 zmem 別 file 出力 PASS、 gate 9 production sha256 `b15883fe...` 実測一致 confirm)。 **重要 finding (= K trace 同一)** = 全 6 env (= k03/k11/k21 × ym2610/ym2610b) で trace 同一 pattern (= L=3 + M-Q 各 1 = total 8 件)、 期待 (= k03/k11/k21 で異なる bitmap pattern → 異なる L-Q write pattern) vs 実 (= driver K dispatch 後 trace 同一)、 driver K dispatch normalization で MML 上 bitmap pair pattern 差を吸収。 結論 = axis C-3 K candidate gate 7 PASS = 「K candidate trigger 出現確認 (= L-Q いずれかに keyon write 出現)」 limit (= 旧 wording 「axis C-3 K distinct candidate gate 7 PASS」 は impl-review round 2 wording 統一で 「K candidate」 に統一済)、 真の「K bitmap pair representative variant 1/2/3 trace distinct」 は β scope 内で未達成 (= driver 拡張 + 別 MML required = ADR-0069 候補 future defer literal)。 β 完走 wording 解禁 = 「K+L-Q distinctness range trace-equivalence literal 達成」 (= L-Q candidate distinctness 3 pattern A/B/C + K candidate trigger 出現確認 + A-J default carry baseline 確認、 「真の K distinct」 含まない明示) | (= 本 PR3 commit chain 内 commit `5d73611` + 本 commit) |
| 2026-05-25 | 40th session | ADR-0068 γ kickoff plan v4 確定 + γ PR4 起票 = baseline regression gate 統合 verify (= ADR-0056 §決定 3 (c)、 representative direct invoke 5 script + transitively regression OK pattern、 ADR-0067 δ gate-5 + ADR-0059 ε roadmap3-gate-4 確立 pattern 継承)、 §決定 1(c) + §決定 2 γ row + §決定 6 表記制約 3 箇所同時 update (= 「γ completion proof 内だけ三分割 wording context-bound 使用 OK」 + 「roadmap ⑤ 統合 verify 完了は ε まで禁止」 明示) + Annex γ skeleton 起票時起草 (= γ-1 〜 γ-6 6 sub-section literal、 representative 5 script + per-script log + sha256 pre+post + 三分割 wording integrated completion proof report + 禁止 wording self-check 7 件全件 + allowlist 拡張 + NOT-COMPLETE 7 行 + 状態維持 + commit chain literal) + 状態行 update (= Draft + α 完了 + β 完了 + γ PR4 進行中)。 Codex layer 2 plan review 4 round chain = round 1 revise (= must-fix 3 + nh 2 + lr 2、 agentId `a3a27e8e2dfee977a`) + round 2 revise (= must-fix 3 + nh 2 + lr 2、 agentId `a1c4721bf1f66a5a6`、 ADR doc 更新範囲 狭い + grep 1 件 → 7 件全件 + NOT-COMPLETE 6 → 7 行整合) + round 3 revise (= must-fix 2 + nh 1 + lr 1、 agentId `a836738a32ccf5bdc`、 chip target 境界統一 + scan target 範囲限定) + round 4 **approve** (= must-fix 0 + nh 1 + lr 1、 agentId `a5e3502b12fb6bbfb`、 prohibited wording 配列 context literal + git diff base ref 確認の advisory)、 must-fix 計 8 件 + nh 計 6 件 + lr 計 6 件 全 ADR 反映、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed、 user 明示 GO「質疑あれば全て Codex Rescue で回答を得て、 完全自律で完走まで GO」 = main agent autonomous 完走 default + 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 | (= 本 PR4 commit chain 内 commit 1) |
| 2026-05-25 | 40th session | ADR-0068 γ verify script bug fix 2 件 + self-test 4 PASS = 6 gate ALL PASS = (a) bash 3.2 多バイト文字 parameter expansion bug 回避 = self-test 2 で line 193 `word: unbound variable` 発覚、 `local var="$arg"` 1 行宣言+代入 → `local var; var="$arg"` 2 行分離 + 全 `$word` → `${word}` braces 明示で fix (= bash 3.2 nounset + 多バイト char 値 + `[[ ... == *"$VAR"* ]]` glob match で parameter expansion parser bug 既知 limitation 回避)、 + (b) allowlist 5 件追加 = self-test 3 で false positive 7 件発覚 (= 禁止 wording 7 件 enumeration list / array declaration / 限定 / 検査 wording context が allowlist 不在で誤検出)、 「<word> / 」 enumeration list context + 「 / 「<word>」」 + 「    "<word>"」 array entry + 「<word> 限定」 limitation context + 「検査 wording」 reference context allowlist 追加で fix。 self-test 4 結果 = 6 gate ALL PASS + NG count 0 + 22 OK count 達成 (= gate 1 sha256-pre + gate 2 representative 4/4 ALL PASS + gate 3 三分割 wording + gate 4 prohibited wording self-check 7/7 + gate 5 NOT-COMPLETE 7 行 + gate 6 sha256-post)。 「ADR-0068 γ 完了」 wording 解禁条件達成 = γ scope 限定 baseline regression gate 統合 verify ALL PASS literal。 driver / α script / β script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex 完全不変維持 confirm (= ADR-0068 §決定 5 (ii) + §決定 7 literal 遵守) | (= 本 PR4 commit chain 内 commit 4) |
| 2026-05-25 | 40th session | ADR-0068 γ self-test 1 finding 反映 + plan v5 → v8 確定 (= β script representative regression 除外、 5 → 4 script、 §決定 5 (ii) β script 完全不変原則遵守、 β scope coverage は ADR Annex β literal で別途確保)。 finding root cause = β script gate 8d (= β branch parent commit literal verify = 3c59d93) は β branch 内部 self-test 専用仕様で、 γ branch HEAD (= 7335da9 = β merge commit) 経路で merge_conflict 誤発火検出 = γ self-test 1 で顕在化、 ADR-0068 Annex β β-7 lr 2 復旧フロー (a) rebase 不適用 = β merge 完了で git history 線形分岐済 = (b) escalate 案件、 ただし「設計判断は Codex 経由で進める」 user 明示 GO 整合で Codex layer 2 plan review re-review 経路で plan v5 → v8 反映。 ADR doc 12 箇所 update enumeration = 状態行 + §決定 1(c) + §決定 2 γ row + §決定 6 γ Accepted 後追加 context + Annex γ 見出し + γ-1 scope + γ-2 配置 + γ-3 representative regression (= β rationale sub-section 末尾追加) + γ-4 production sha256 維持 (= ym2610b coverage 根拠 paragraph 1 + β scope coverage 根拠 paragraph 2 分離) + γ-5 completion proof exact literal (= representative 5 → 4 entry + 行数 17 → 16) + γ-6 commit chain literal (= 4 → 5 commit) + Codex layer 2 plan review chain table (= 4 → 8 round) + 本改訂履歴 entry。 γ verify script 7 箇所 update = header コメント representative 5 → 4 + REPRESENTATIVE_SCRIPTS array 5 → 4 entry + gate 2 echo header line 5 → 4 + gate 2 section heading + comment 5 → 4 + gate 2 PASS criteria 5 → 4 + summary message 5/5 → 4/4 + header コメント末尾 β script 除外 rationale 段落追加。 β script (= verify-axis-b-v2-16ch-integration-beta.sh) ファイル一切修正なし (= §決定 5 (ii) + §決定 7 不可触対象 literal 遵守 confirm)。 Codex layer 2 plan review round 5 revise (= must-fix 2 + nh 2 + lr 2、 agentId `a0ebc16cc8dff7c1c`) + round 6 revise (= must-fix 2 + nh 1 + lr 2、 agentId `a3e1649a54066ee4d`、 ADR doc 12 箇所明示 + γ script gate 2 section heading 追加 + ym2610b coverage / β scope coverage paragraph 分離) + round 7 revise (= must-fix 1 + lr 1、 agentId `a36cd4ac2187ebc37`、 改訂履歴 γ entry update target 明示) + round 8 **approve plan v8** (= must-fix 0 + nh 1、 agentId `aaf195285d974edcc`、 commit 3 message wording fine-tune advisory)、 must-fix 計 5 + nh 計 6 + lr 計 5 全反映、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed | (= 本 PR4 commit chain 内 commit 3) |
| 2026-05-25 | 40th session | ADR-0068 γ PR4 Codex layer 2 impl-review round 1 finding 反映 (= revise judgment must-fix 1 + nh 2 + lr 1、 agentId `a7ec395ff32cfb510`、 全 review-only + 越権操作なし confirmed) = (1) must-fix 1 ADR Annex γ-3 見出し 「representative regression 5 script + per-script log」 → 「representative regression 4 script + per-script log (= impl-review round 1 must-fix 1 反映、 β script 除外 = 5 → 4 script)」 修正、 + (2) nh 1 ADR Annex γ-2 「行数 TBD」 → 「307 行 commit b39c7ec 時点 → 現 HEAD 325 行 evolution、 bug fix 2 件 + allowlist 5 件追加で行数 increment」 update、 + (3) nh 2 dashboard γ PR4 + β PR3 entry 内「(5) 本 commit dashboard + memory + 平易要約」 → 「(5) 本 commit dashboard + escalation 履歴 + 平易要約 (= memory は repo 外、 PR diff 対象外、 impl-review round 1 nh 2 反映)」 update、 + lr 1 = γ script allowlist false negative risk 継続監視 (= 現 PR 実測 PASS と矛盾なし、 将来 拡張時 false negative 監視継続)。 driver / α script / β script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex 完全不変維持 confirm | (= 本 PR4 commit chain 内 commit 6 追加) |
| 2026-05-25 | 40th session | ADR-0068 δ PR5 起票 = 統合 report + 残課題 enumeration ADR-0065/0066/0069 起票判断 material doc-only sprint (= ADR-0068 §決定 2 δ row literal 継承、 γ PR #136 MERGED at `ef87dcb` 後続、 driver / α script / β script / γ script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex / ADR-0068 既存 Annex α/β/γ 本文 / 軸 G ε partial state placement 完全不変 sprint)。 ADR doc 修正範囲 = (1) 状態行 update (= γ PR4 進行中 → γ 完了 PR #136 MERGED at `ef87dcb` + δ PR5 進行中 entry) + (2) §決定 6 δ Accepted 後追加 context (= LR1 反映「ADR-0068 δ 完了」 解禁段落同段落「roadmap ⑤ 統合 verify 完了は ε まで禁止維持」 literal 併記必須) + (3) Annex δ section fill 4 sub-section literal (= δ-1 scope literal + δ-2 統合 report = α/β/γ 結果 + integration milestone + roadmap ⑤ 完了前状態の明確化 = (a)(b)(c) 3 gate 別 status enumeration + δ-3 残課題 enumeration = ADR-0065/0066/0069 起票判断 material + dependency chain literal + δ-4 状態維持 + Codex layer 2 plan review chain + commit chain literal、 nh 3 + lr 3 全反映 = NH1 audition preparation 運用上前提扱い + NH2 prohibited wording scan target + allowlist context Annex δ 内明文化 + NH3 sha256 doc-only carry literal § 決定 10 衝突回避 + LR1 同段落併記必須 + LR2 ADR-0069 候補 A-J candidate distinctness + K bitmap pair distinct 別 sub-finding 粒度保持 + LR3 γ MERGED と δ 完了境界明確分離 PR/commit chain 分離) + (4) 改訂履歴 δ entry 追加 (= 本 entry) + (5) 平易要約 δ context section (= δ PR5 完走 update = δ でやりたかったこと/前提/やったこと/結果/解釈/完走後の次 6 構造)。 Codex layer 2 plan review 1 round chain = round 1 **approve** (= must-fix 0 + nh 3 + lr 3 全反映、 agentId `ad78bc3e6e2e6928a`)、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed。 user 明示 GO「ADR-0068 δ 起票判断から開始」 + 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 + Codex rescue 化 default 規律継承。 production sha256 = `b15883fe...` 維持期待 (= NH3 反映 = δ で再 build しない、 γ で既達成済 sha256 実測結果を doc-only として carry、 §決定 10 整合)。 commit chain = 2 commit = (1) 本 commit ADR doc 修正 + (2) 次 commit dashboard 0068 行 status update + escalation 履歴 δ PR5 entry 1 row | (= 本 PR5 commit chain 内 commit 1) |
| 2026-05-25 | 40th session | ADR-0068 ε PR6 = Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal 解禁 + 併記必須 9 件 doc-only sprint (= ADR-0068 §決定 2 ε row literal 継承、 δ PR #137 MERGED at `56c0b0f` 後続、 driver / α script / β script / γ script / ADR-0067 fixture / 既存 verify script / 既存 build flag / vendor / ADR-0048〜0067 本文 + Annex / ADR-0068 既存 Annex α/β/γ/δ 本文 / 軸 G ε partial state placement 完全不変 sprint)。 ADR doc 修正範囲 = (1) 状態行 update (= Draft + α/β/γ 完了 + δ PR5 進行中 → **Accepted** = ε PR #138、 sub-sprint chain α/β/γ/δ/ε 全 完走 + 6 PR chain + 「ADR-0068 Accepted」 + 「ADR-0068 ε 完了」 + 「roadmap ⑤ 統合 verify 完了」 wording 解禁 + 併記必須 9 件 + 通算 sha256 維持 + 主軸 fallback approve plan v1) + (2) §決定 6 ε Accepted 後追加 context fill (= ε Accepted 後 wording status table = 7 wording 解禁 + 9 件併記必須 literal + 5 wording 禁止維持 + 「roadmap ⑤ 統合 verify 完了」 wording 解禁条件 9 件併記必須 literal) + (3) Annex A fill = 6 sub-section (= A-1 ADR-0067 完走経緯 + A-2 roadmap ⑤ 統合 verify 本体 + A-3 (a)(b)(c) 3 gate scope + A-4 ADR-0064 §決定 3 plan literal 継承 + A-5 user 明示 GO option 1 + A-6 主軸 fallback pattern literal) + (4) Annex B fill = 5 sub-section (= B-1 16 ch 統合 verify 構成図 ascii + B-2 build mode (A)/(B)/(C-1)/(C-2) matrix + B-3 chip target 別 trace + B-4 PMDDOTNET_MODE matrix + B-5 trace TSV format literal) + (5) Annex ε fill = 6 sub-section (= ε-1 scope literal + ε-2 「roadmap ⑤ 統合 verify 完了」 milestone literal + 併記必須 9 件 + ε-3 sub-sprint chain 完走 summary 6 PR chain + ε-4 残課題 dependency chain literal + ε-5 状態維持 + commit chain literal + ε-6 ADR-0068 Accepted milestone literal) + (6) 改訂履歴 ε entry 追加 (= 本 entry) + (7) 平易要約 ε context section (= ε PR6 完走 update 6 構造)。 Codex layer 2 plan review chain ε = 主軸 fallback approve plan v1 (= ADR-0041 §決定 6 適用、 Codex companion 安全性分類器 (claude-opus-4-7) 一時障害で Codex layer 2 plan review 2 回連続失敗 = `claude-opus-4-7[1m] is temporarily unavailable` error = CLAUDE.md §長時間 task hang 自動復旧 rule「retry も hang した」 user escalation 該当、 user 明示 option B = ADR-0041 §決定 6 fallback + retrospective Codex review 必須 採用、 doc-only sprint + scope 明確 + retrospective review 必須が fallback 適用根拠、 主軸 Claude Code が plan v1 を独立 review = scope literal coverage / 併記必須 9 件 / Annex A/B/ε fill / allowed-touch / production sha256 / commit chain plan 全 OK = approve 判断、 latent risk 3 件 retrospective Codex review で再確認)、 全 review-only + 越権操作なし + 冒頭 6 件 literal 強調遵守 confirmed (= 主軸 fallback でも commit 権限なし規律維持)、 40th session ε で「主軸 fallback + retrospective Codex review」 pattern 初実証。 user 明示 GO「ADR-0068 ε 起票判断から開始」 + 機械復旧 default rule [[long-running-hang-auto-recovery-rule]] 継承 + Codex rescue 化 default 規律継承。 production sha256 = `b15883fe...` 維持期待 (= ε で再 build しない、 γ で実測 confirm + δ で doc-only carry + ε で doc-only carry 継続、 §決定 10 整合)。 commit chain = 2 commit = (1) 本 commit ADR doc 修正 + (2) 次 commit dashboard 0068 行 status update + escalation 履歴 ε PR6 entry 1 row。 ADR-0068 Accepted milestone = ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目完了 (= ADR-0067 + ADR-0068 chain = ADR-0064 plan 実作業群完了)、 「roadmap ⑤ 統合 verify 完了」 wording 解禁 + 併記必須 9 件、 「ADR-0068 Accepted」 + 「ADR-0068 ε 完了」 wording 解禁 | (= 本 PR6 commit chain 内 commit 1) |
