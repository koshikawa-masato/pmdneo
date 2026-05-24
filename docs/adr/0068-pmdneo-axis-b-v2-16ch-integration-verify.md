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
2. PR2 = α 実装 = 新規 verify script + 16 ch candidate 探索 + 12 trace capture + literal report

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
- scope: v2 driver 経路 (= TEST_MODE_V2_SONG_FIXTURE=1 + AXIS_G_AUDITION_LEGACY_SKIP=1、 (B) build mode) + cmd 0x05 経路 (= PMDNEO_M_RAW or PMDDOTNET_MML legacy build、 (C-1)/(C-2) build mode) 並走 trace capture
- 目的: 各 ch 個別 verify 完了済 (= roadmap ①〜③ Accepted) を 1 件の MML song に対して統合実行 + 統合 trace 取得
- 完了判定: 全 ch + 全機能の trace 統合取得 + literal report

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
| α | (a) 実 MML 再生 統合 verify = α-task 1 rhythm-only proof (= `src/test-fixtures/step5/l-q-rhythm-song.mml`) + α-task 2 全 16 ch candidate 探索 (= `vendor/PMDDotNET/SAMPLE2-baseline.mml` 等から確認) + 12 trace capture (= 6 env × ymfm/z80-mem 2 trace 種) + literal report | (a) | 全 ch + 全機能の trace 統合取得 + literal report、 α-task 1 + α-task 2 両完了 |
| β | (b) 全 16 ch trace-equivalence 判定基準確定 + 比較実行 = 意図した v2 差分 / 意図しない差分 enumeration literal + α 取得 trace 4-6 件を input として comparison | (b) | 全 ch trace-equivalence 確認 + 意図しない差分なし literal 確認 |
| γ | (c) 全 verify script 統合 ALL PASS = production binary 1 件に対して全 verify を 1 batch 実行 + 統合 report | (c) | 全 verify script ALL PASS literal 確認 + completion proof 統合 report |
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
| **「trace-equivalence 完了」 (= 新規解禁表現候補)** | literal 禁止 | 使用可、 併記必須 | 同上 |
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
| PR2 | sub-sprint α = (a) 実 MML 再生 統合 verify = 新規 verify script + α-task 1 rhythm-only proof + α-task 2 全 16 ch candidate 探索 + 12 trace capture + literal report + Annex α | 実装 + doc |
| PR3 | sub-sprint β = (b) trace-equivalence 判定基準確定 + 比較実行 + Annex β | 実装 + doc |
| PR4 | sub-sprint γ = (c) 全 verify script 統合 ALL PASS + Annex γ | 実装 + doc |
| PR5 | sub-sprint δ = 統合 report + 残課題 enumeration + Annex δ | doc 主体 |
| PR6 | sub-sprint ε = Draft → Accepted + Annex 全統合 + 「roadmap ⑤ 統合 verify 完了」 milestone literal (= 併記必須) | doc-only |

### 決定 9: ADR-0065/0066 候補 起票判断 = future、 user 明示 GO 必須

- **ADR-0065 候補** = roadmap ⑥ audition ADR (= 越川氏 audition gate、 aesthetic gate)
- **ADR-0066 候補** = roadmap ⑦ 本番 cmd 切替判断 ADR (= cmd 0x05 + pmdneo_song_main 経路 → v2 driver 経路 switch、 production-ready 全通過後 future)
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

### Annex α: α 実装 completion record (= α PR2 で fill = α-task 1 rhythm-only proof + α-task 2 全 16 ch candidate 探索)

(= α PR2 で 6 sub-section literal fill = 実装内容 + 配置 + α-task 1 結果 + α-task 2 結果 + Codex review chain + 状態維持)

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
- ADR-0064 §決定 3 sub-sprint plan literal 継承 + α-task 1/2 切り分け literal (= rhythm-only proof + 全 16 ch candidate 探索)
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

PR1 (= 本 PR) merge 後、 sub-sprint α 実装 PR2 を別 task chain で起票 (= ADR-0068 §決定 2 α scope literal = α-task 1 rhythm-only proof + α-task 2 全 16 ch candidate 探索 + 12 trace capture + literal report)。 α 完走後 β/γ/δ/ε 各 PR を continue。 ADR-0068 ε Accepted 後、 ADR-0065 候補 (= roadmap ⑥ audition) + ADR-0066 候補 (= roadmap ⑦ 本番 cmd 切替判断) 起票判断 (= 各 user 明示 GO 必須)。

## 改訂履歴

| 日付 | session | 変更 | commit |
|---|---|---|---|
| 2026-05-24 | 39th session | ADR-0068 新規起票 Draft (= doc-only PR1、 ADR-0064 §決定 7 ADR-0067+ 実作業群 の 2 本目、 16 ch 統合 verify ADR、 cmd 0x05 経路 vs v2 経路 trace-equivalence 比較、 sub-sprint α/β/γ/δ/ε chain literal、 build mode (A)/(B)/(C-1)/(C-2) 4 mode literal、 trace-equivalence 定義 literal、 allowed-touch 3 段分類 literal、 表記制約 + 新規解禁表現候補 literal、 Annex skeleton 起票時起草 (= α 漏れ補完 retrospective 起票時 prevention)、 Codex layer 2 plan review 4 round chain = round 1-3 revise + round 4 approve、 must-fix 計 7 件 + nh 計 4 件 + lr 計 3 件 全反映、 越権操作なし confirmed、 user 明示 GO option 1 PR1/PR2 段階分離 採用) | (= 起票 commit 後続) |
