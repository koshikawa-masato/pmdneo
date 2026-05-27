# ADR-0074: PMDNEO PMDDOTNET_MML runtime selection path repair (= 指定 MML を MAME runtime で本当に起動できる経路の設計 plan)

## 平易日本語 3 軸 (= ADR 起票時 mandate 規律 = memory `feedback_adr_filing_plain_context_required.md` literal carry)

### 1. 何の問題を解くための ADR か

PMDDOTNET_MML で指定した MML が build artifact (= `vendor/ngdevkit-examples/00-template/pmddotnet_song.m`) には入っていても、 **MAME runtime では `song_table[0] = test01.mml` が再生されていた**。 これにより:

- ADR-0065 δ preflight (= 2026-05-27 staggered fixture preflight v2) で「指定 fixture 由来 WAV」 が証明できない infrastructure issue を検出 = user audition「G g」 = test01.mml の FM E (= g4 連続) audible だった可能性
- ADR-0072 ε「voice opcode dispatch + #FFFile support 完了」 + ADR-0073 ε「driver FM volume scaling semantics repair 完了」 の runtime audio verify (= γ runtime functional verify -29.59 dBFS 等) が **指定 fixture 由来かを証明できない state** = ADR-0058 §決定 1 mandate「A-J は全 build mode で default 固定、 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 と矛盾する infrastructure assumption で立てられていた可能性

### 2. 何を実装・検証するのか

PMDDOTNET_MML で指定した song を **runtime から明示的に選択・起動できる経路** を設計する:

- main.c (= M68K side) / song_data.inc (= driver-side song_table) / driver (= cmd handler) のどこで song 選択するかを比較
- 最小 touch で「指定 MML が鳴っている」 を **trace + WAV segment で機械的に証明** できる方式を決定
- ADR-0058 §決定 1 mandate との衝突を明示 + 整合 path 提案
- production sha256 (= `b15883fe...`) 維持戦略 (= guarded change pattern or preflight build mode 導入)
- 既存 ADR-0072/0073 ε wording への影響整理 (= **wording 訂正・撤回判断は user judgment scope = 自走しない**)

本 sprint α scope = **doc-only plan sprint**、 driver / build / vendor / fixture / 既存 verify 完全不変。 実装着手は β plan approve + user 明示 GO 経由限定。

### 3. 完了すると何が次に進められるのか

- ADR-0065 δ session preflight を **正しくやり直せる** (= staggered fixture が runtime で再生される機械的証明後、 part-by-part dispatch verify 可能)
- ADR-0072 / ADR-0073 ε の runtime verify が **本当に PMDDOTNET_MML 由来だったか再確認** できる (= wording 訂正・撤回判断は user 介入 mandatory)
- user audition / δ session / candidate 評価 / aesthetic approve には **進まない** (= 本 ADR-0074 完走後も user 介入 mandatory)

---

- 状態: **Draft** (= 2026-05-27 43rd session 起票、 sprint α plan sprint scope = touch 範囲候補比較 + rollback + sha256 影響 + 既存 ADR wording 影響整理 + Codex Rescue plan review 投入準備 doc-only sprint。 user 明示 mandate「いきなり実装ではなく、 まず doc/plan sprint として起票、 ADR-0058 §決定 1 mandate と衝突する可能性があるので慎重 plan 化」 mandate 経路、 ADR-0073 ε Accepted (= PR #158 MERGED at `d33166f`) 完走後の audio quiet 問題 follow-up = ADR-0065 δ preflight v2 (= 2026-05-27 43rd session 末) で発覚した infrastructure issue (= preflight-staggered.mml が runtime で再生されず test01.mml audio measurement だった evidence) repair sprint)
- 起票日: 2026-05-27
- 起票者: 越川将人 (M.Koshikawa) (= 主軸 Claude Code 経由、 user 明示 mandate「PMDDOTNET_MML runtime selection path repair の ADR 起票 plan を作る + option A test01.mml 一時置換は採用しない (= production 経路の確認であり PMDDOTNET_MML 経路の証明にならない) + option B K/L-Q 限定は FM/SSG preflight に不足 + option C 相当 runtime selection path repair を plan 化 + doc-only plan / touch 範囲 / rollback / sha256 影響 / 既存 ADR wording 影響整理 + ADR-0058 §決定 1 mandate 衝突明示 + user audition / δ session に勝手に進まない + ADR-0072/0073 wording 訂正・撤回 user 判断なしに行わない」 mandate 経路)
- 関連 ADR:
  - **ADR-0058** (= roadmap ② v2 dispatcher、 §決定 1「A-J は全 build mode で default 固定、 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 literal、 本 ADR-0074 で **衝突明示 + 整合 path 提案 mandatory**)
  - **ADR-0072** (= driver-PMDDOTNET voice opcode data delivery repair、 ε Accepted、 「voice opcode dispatch + #FFFile support 完了」 wording = K + L-Q 経路 context 推定 = **本 ADR-0074 plan 後 wording 訂正候補 = user 判断軸**)
  - **ADR-0073** (= driver FM volume scaling semantics repair、 ε Accepted、 「FM volume scaling repair 完了」 wording = test01.mml 経路 audio measurement で +46.41 dB 改善確認 = **本 ADR-0074 plan 後 wording 訂正候補 = user 判断軸**)
  - **ADR-0065** (= roadmap ⑥ audition、 δ session preflight v2 で本 infrastructure issue 発覚)
  - **ADR-0069** (= A-J distinctness、 ADR-0058 §決定 1 context carry)
  - **ADR-0016** (= step 3c PMDDOTNET 経路、 `PMDNEO_USE_PMDDOTNET` flag `pmdneo_load_m` 入力 label 切替)
  - **ADR-0041** (= Claude Code 併走運用、 §決定 5 `design_judgment_needed` escalation = wording 訂正・撤回判断は user judgment scope)
- 関連 memory:
  - `feedback_adr_filing_plain_context_required.md` (= ADR 起票時平易 3 軸 mandate)
  - `feedback_adr_0065_delta_audition_pre_offer_required.md` (= δ session 5 軸提示 mandate、 本 ADR-0074 完走後も carry)
  - `feedback_metric_pass_is_not_aesthetic_pass.md` (= metric pass ≠ aesthetic approve)
  - `feedback_main_agent_engineering_responsibility.md` (= user judgment scope = 不可逆 / 設計判断、 wording 訂正は user 介入 mandatory)
  - `feedback_doc_governance_two_systems.md` (= immutable history mandate、 ADR-0072/0073 historical record literal 書換禁止)
  - `feedback_codex_layer2_review_no_commit_authority.md` (= review-only 6 件)
  - `feedback_pr_merge_branch_delete_atomic.md` (= atomic 1 セット規律、 17 回目適用予定)

## 背景 (= infrastructure issue detection 経緯)

### detection 経緯 (= 2026-05-27 43rd session 末 ADR-0065 δ preflight v2)

ADR-0073 ε Accepted (= PR #158 MERGED at `d33166f`) 完走後、 user 明示 GO で ADR-0065 δ session preflight 再開。 main agent 1 回目 preflight = 既存 candidate (= SAMPLE2.MML + l-q-rhythm-song.mml 等) 評価 → user mandate「既存 candidate 評価でない、 driver per-part dispatch 確認用 staggered fixture」 receive → preflight v2 = staggered fixture `src/test-fixtures/adr-0065/preflight-staggered.mml` 作成 → MAME runtime + wav + trace。

### user audition + main agent finding 不整合

| 軸 | main agent preflight v2 report | user 実 audition |
|---|---|---|
| FM B (= ch 2) c4 (= 0-4 秒) | -1.63 dBFS audible | inaudible |
| FM C (= ch 3) d4 (= 4-8 秒) | -1.51 dBFS audible | inaudible |
| FM E (= ch 5) e4 (= 8-12 秒) | -2.65 dBFS audible | g4 audible? |
| FM F (= ch 6) f4 (= 12-16 秒) | -28.85 dBFS weak | inaudible |
| SSG G g4 (= 16-20 秒) | -16.35 dBFS audible | g4 audible |
| SSG H a4 (= 20-24 秒) | -inf silent | inaudible |
| SSG I b4 (= 24-28 秒) | -inf silent | inaudible |

→ user 実 audition は **「G g4 のみ audible、 他は inaudible」**。 main agent report の「FM B/C audible」 は test01.mml の **FM B (= c4 連続) + C (= e4 連続)** audio で、 user が 30 秒 record 中聴いた「g 音」 は test01.mml の **FM E (= g4 連続)** audio だった可能性 (= SSG G ではなく FM E が「g 音」 source)。

### infrastructure 切り分け literal

1. **main.c L67** = `*REG_SOUND = 9 + PMDNEO_SONG;` = sound cmd 9 + N で `nmi_cmd_select_song` (= driver L937-940) → `driver_song_id = N` store
2. **main.c L89** = `*REG_SOUND = 5;` = sound cmd 5 で `nmi_cmd_5_init_mml_song` 起動 = song dispatch trigger
3. **driver L3486 `load_song_part_addr`** = `song_table[driver_song_id × 20 + part_idx × 2]` で part address load
4. **song_data.inc L43-54** = song_table = song0_part_a〜z (= test01) + song1_part_a〜z (= test02)、 **`pmddotnet_song` は song_table 未登録** = `cmd 9 + N` 経由起動不可
5. **driver L1902-1905** = `PMDDOTNET_MML mode では pmddotnet_song の K part offset (= file byte 21-22) から body addr を計算` + `pmdneo_mn_direct_load_k_part_addr` = **K + L-Q part のみ pmddotnet_song 経由 dispatch**
6. **ADR-0058 §決定 1 mandate** = 「A-J は全 build mode で default 固定、 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 literal

### evidence summary

PMDDOTNET_MML build mode で:
- **A-J (= FM 6 + SSG 3 + ADPCM-B = 10 part) = song_table[0] = test01.mml が play**
- **K + L-Q (= rhythm + ADPCM-A 6 ch) = pmddotnet_song の K + L-Q part offset 経由 override**

→ preflight-staggered.mml の FM B/C/E/F + SSG G/H/I 全 part は **runtime で test01.mml に上書き** = 「指定 fixture 由来 audio」 ではない。

## 決定 (= plan v1 draft、 Codex Rescue plan review iteration で確定)

### 決定 1: ADR-0074 scope = PMDDOTNET_MML runtime selection path repair に限定

#### scope IN (= 本 ADR-0074 で repair)

- (1) PMDDOTNET_MML 指定 fixture を MAME runtime から **明示的に選択・起動** できる経路の設計
- (2) 経路 candidate (= main.c / song_data.inc / driver) の比較 + 最小 touch path 確定
- (3) 「指定 MML が鳴っている」 を **trace + WAV segment で機械的に証明** できる方式の設計
- (4) ADR-0058 §決定 1 mandate との **衝突明示 + 整合 path** 提案
- (5) production sha256 (= `b15883fe...`) 維持戦略 (= guarded change or preflight build mode 導入)
- (6) 既存 ADR-0072/0073 ε wording への影響整理 (= **wording 訂正・撤回判断は user judgment scope = 自走しない**)

#### scope OUT (= 別 ADR future、 本 ADR-0074 では touch しない)

- (a) **実装着手** = sub-sprint γ で別 PR、 本 sprint α は plan only
- (b) **ADR-0072/0073 ε wording 訂正・撤回** = user judgment scope (= ADR-0041 §決定 5 escalation 軸)
- (c) **user audition / δ session / candidate 評価** = ADR-0065 ε δ session scope、 user 介入 mandatory
- (d) **aesthetic approve** = user judgment scope
- (e) **ADR-0058 §決定 1 mandate 自体の変更** = user judgment scope (= 設計不可逆判断)

### 決定 2: sub-sprint chain plan = α/β/γ/δ/ε 5 段 (= ADR-0073 precedent literal 継承)

| sub-sprint | scope | user 介入 | 完了判定 | driver/runtime touch |
|---|---|---|---|---|
| **α (= 本 sprint)** | plan v1 draft + 5 重点 mandate (= scope + touch 範囲候補 + rollback + sha256 + 既存 ADR wording 影響) + Codex Rescue plan review 投入 | optional (= main agent autonomous + Codex Rescue review-only) | 本 PR1 起票時完了 = ADR doc 起票 + Codex review 5 必須軸 approve | なし (= doc-only) |
| β | plan iteration = Codex Rescue plan review chain + touch 範囲確定 + rollback + sha256 維持戦略 + ADR-0058 §決定 1 整合 path | optional (= main agent autonomous + Codex Rescue review) | plan approve | なし (= doc-only) |
| **γ** | runtime selection path implementation = 確定 touch (= main.c + song_data.inc + driver いずれか or 複合) + 機械的証明 fixture 作成 + 4 build matrix verify | **user 明示 GO mandatory point** (= ADR-0058 §決定 1 衝突する可能性 = 設計判断軸、 ADR-0041 §決定 5 escalation 該当) → **2026-05-27 user 明示 GO 受領 + γ impl 完了 + NH-1 (B) 採用 round 1 revise 完了** = candidate 4 実装 + 正規 preflight path = B3 (= PMDDOTNET=0 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML)、 B4 (= PMDDOTNET=1 + SONG_SELECT=1) は補助確認扱い (= scope-out 相当) + γ-1〜γ-5 ALL PASS + B3 predicate (a)〜(d) ALL PASS + production sha256 `b15883fe...` byte-identical 維持 | impl 完了 + 正規 preflight path B3 build + B3 predicate (= song2_part_a〜z 20 == equate + song_table[40..59] .dw rows + song_table[0..19] preserved + load_song_part_addr call site active) ALL PASS + 「指定 fixture 由来 audio」 機械的証明 evidence は δ runtime functional verify で取得 | あり (= scope IN routine + build infra のみ、 guarded change or preflight build mode 配下) |
| δ | runtime functional verify = staggered fixture が runtime 再生される機械的証明 + trace + WAV segment 一致 confirm + ADR-0072/0073 reverify scope | optional | δ verify findings literal record | なし (= MAME render only) |
| **ε** | Accepted milestone + 「PMDDOTNET_MML runtime selection path repair 完了」 wording 解禁 (= 併記必須 mandatory) + ADR-0072/0073 ε wording 訂正・撤回判断は user judgment scope mandate carry | **user 明示 GO mandatory** | Accepted + wording 解禁 + 残課題 record | なし (= doc-only) |

### 決定 3: touch 範囲 candidate (= sprint β で確定、 sprint α では候補列挙)

#### candidate 1: song_table 拡張 + main.c PMDNEO_SONG=N で起動 (= 最 minimum)

- `vendor/ngdevkit-examples/00-template/song_data.inc` 改修 = `song_table` に `pmddotnet_song` 関連 entry (= 20 part 分の literal address、 ただし pmddotnet_song は part offset table 内蔵 binary blob = literal address direct 困難)
- 代替 = `pmddotnet_song_part_a/b/.../z` 20 個 literal label を pmddotnet_song.m 内 part offset から build-poc.sh で生成 + song_table に entry 追加
- main.c PMDNEO_SONG=2 (= 新規 song slot) で起動可能
- driver 内 logic 変更 minimum (= song_table 経由 既存経路 carry)
- ADR-0058 §決定 1 mandate との関係 = song_table[2] 経路は ADR-0058 §決定 1 「A-J test01 default」 mandate を **bypass** (= song_table[2] は新 slot)、 ただし mandate literal「PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 自体への影響不明 = 整理必要

#### candidate 2: driver cmd handler 改修 + PMDDOTNET 経路 song を別 cmd id 経由起動

- driver 内に新規 cmd handler 追加 (= 例 = cmd 0x40+N で pmddotnet_song 起動)
- main.c で対応 cmd 送信
- driver 内 routine 追加 = guarded change 必要 (= production binary 影響あり)
- 大きな改修 = ADR-0058 §決定 1 mandate と直接衝突 (= driver routine 自体に新 song 起動 path 追加 = mandate 変更該当)

#### candidate 3: build-poc.sh + song_data.inc 改修 + PMDDOTNET 経路 song を ngdevkit-examples 内に song として組み込む

- build-poc.sh PMDDOTNET_MML 経路で song_data.inc 内 song_table を **動的拡張** (= 既存 song0/1 + pmddotnet_song_part_a〜z を song 2 として append)
- main.c PMDNEO_SONG=2 で起動
- candidate 1 と類似だが build infra 側で song_table 拡張を全自動化
- driver / production binary への影響 = guarded change `.if PMDNEO_USE_PMDDOTNET` 配下で song_table 拡張 = production binary `b15883fe...` 維持 (= flag-off では song_table 拡張なし)
- ADR-0058 §決定 1 mandate との関係 = candidate 1 と同等 (= mandate bypass、 ただし mandate 自体は不変)

#### candidate 4: preflight 専用 build mode 導入 (= TEST_MODE_PMDDOTNET_SONG_SELECT flag 等)

- driver 内 + build infra 側に新 `TEST_MODE_PMDDOTNET_SONG_SELECT` flag 導入 (= 既存 TEST_MODE_AXIS_G_INT 等の precedent 同形)
- flag=0 (= production default) = 既存 logic 完全保存 (= sha256 byte-identical 維持)
- flag=1 (= preflight build) = pmddotnet_song を song_table 拡張 + main.c PMDNEO_SONG=N で起動可能
- ADR-0058 §決定 1 mandate との関係 = flag=0 では mandate 完全 carry、 flag=1 では preflight 専用 = mandate 例外条件として承認可能性

### 決定 4: production sha256 維持戦略 (= candidate 4 推奨 path)

production sha256 = `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` **維持 mandate** (= ADR-0073 ε で確定 active baseline、 dashboard production baseline section literal carry)。

candidate 4 (= preflight 専用 build mode) を採用すれば:
- flag=0 default = production binary 完全不変 (= sha256 byte-identical)
- flag=1 preflight build = song_table 拡張 + main.c PMDNEO_SONG=N path = preflight 専用
- 4 build matrix B1-B4 verify pattern (= ADR-0071/0072/0073 precedent literal 継承)

### 決定 5: ADR-0058 §決定 1 mandate との衝突明示 + 整合 path

#### ADR-0058 §決定 1 mandate literal

「A-J は全 build mode で default 固定、 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 literal。 これは PMDDOTNET_MML build 時の A-J part dispatch を test01.mml に固定する mandate。

#### 衝突分析

candidate 1/3/4 (= song_table 拡張経路) は **「PMDDOTNET 経路全 part を song_table[2] 等の新 slot に登録 + N=2 で起動」** で、 ADR-0058 §決定 1 mandate の literal text 自体は **不変** (= 既存 song_table[0]/[1] = test01/test02 の A-J test01 default carry)、 ただし「PMDDOTNET_MML 経路の song 起動 path」 自体は新 slot 経由で別 dispatch = mandate の **意図** との整合性は要 user 判断。

#### 整合 path 提案 (= candidate 4 推奨)

- **preflight 専用 build mode** = `TEST_MODE_PMDDOTNET_SONG_SELECT=1` 時のみ song_table 拡張 + 新 dispatch path active
- ADR-0058 §決定 1 mandate = production default (= flag=0) で完全 carry = mandate 不変
- preflight build (= flag=1) は **ADR-0058 §決定 1 mandate 例外条件** として **本 ADR-0074 内で literal 例外明示** (= 既存 mandate を撤回せず、 「preflight build mode 例外」 として共存)
- user judgment scope = (a) 整合 path 承認 / (b) ADR-0058 §決定 1 mandate 自体変更要望 / (c) preflight 経路自体不採用 (= 別 path 模索) = β plan review iteration で user 確認

### 決定 6: 既存 ADR-0072/0073 ε wording への影響整理 (= user judgment scope mandate carry)

#### ADR-0072 ε wording = 「voice opcode dispatch + #FFFile support 完了」

本 ADR-0074 で確定する事項:
- ADR-0072 ε で確立した「voice opcode dispatch」 経路は **K + L-Q part dispatch (= ADR-0058 §決定 1 mandate carry)** での voice opcode literal 想定だった可能性 ⇄ ADR-0072 fixture `test-voice-load.mml` は FM A-F 経路で voice opcode 書いた = **mismatch**
- ADR-0072 γ runtime verify で「reg 0x40=0x11 (= voice 001 OP1 TL=17)」 観測 = test01.mml に voice 001 ないため、 別経路 (= init phase default voice load?) で観測した可能性

→ wording 訂正候補 (= 「voice opcode dispatch FM 経路は infrastructure 未確立」 等の併記必須化) = **user judgment scope** = 本 ADR-0074 では wording 訂正・撤回 **判断しない** + ADR-0074 ε Accepted 後に user に再評価判断仰ぐ。

#### ADR-0073 ε wording = 「driver FM volume scaling repair 完了」

本 ADR-0074 で確定する事項:
- ADR-0073 γ runtime functional verify で「wav RMS = -29.59 dBFS (= +46.41 dB 改善)」 観測 = **test01.mml 経路 audio measurement** = driver patch (= fix A/B/C) 自体の effect 観測は real、 ただし「PMDDOTNET_MML 由来 audio」 ではない
- driver patch (= comv + fm_volume_hook + pmdneo5_init_part) 自体の logic change は test01.mml audio output に effect = real measurement

→ wording 訂正候補 (= 「test01.mml 経路 audio measurement、 PMDDOTNET_MML 経路 FM part audio verify は infrastructure 未確立」 等の併記必須化) = **user judgment scope** = 本 ADR-0074 では wording 訂正・撤回 **判断しない** + ADR-0074 ε Accepted 後に user に再評価判断仰ぐ。

#### immutable history mandate carry (= memory `feedback_doc_governance_two_systems.md`)

ADR-0072/0073 既存 §決定 + Annex + 改訂履歴 + 平易要約 = **書換禁止 mandate**。 wording 訂正は新規 §決定 (= ADR-0074 内 or 別 ADR) + supersede pointer 経由 indirect 訂正 (= ADR-0072 plan v3 Annex β-3-3 / ADR-0073 plan v3 Annex β-3-3 agent 1/agent 2 finding 誤記訂正 precedent 同形)。

### 決定 7: rollback condition (= ADR-0073 §決定 6 18 condition + ADR-0074 固有 condition)

ADR-0073 sprint ε §決定 6 18 condition + 共通原則 **完全継承**。 ADR-0074 固有追加 condition (= sprint β plan review iteration で literal 確定):

- **#19 ADR-0058 §決定 1 mandate との根本衝突 finding** = β plan review で「preflight 専用 build mode 経路でも ADR-0058 §決定 1 mandate 違反不可避」 finding → sub-sprint halt + user 明示 GO 必須 (= 設計判断軸)
- **#20 production sha256 mandate 違反 risk** = γ impl 段階で `b15883fe...` byte-identical 維持不可能 finding → 即 sub-sprint halt + revert
- **#21 ADR-0072/0073 ε wording 訂正・撤回 main agent 自走 risk** = δ runtime verify 結果で「ADR-0072/0073 ε wording が偽」 evidence が出ても、 wording 訂正・撤回は **user judgment scope** = 自走で訂正・撤回しない (= 違反すれば immediate halt + user escalation)

#### 共通原則 (= ADR-0069 §決定 5 + ADR-0071/0072/0073 完全継承)

destructive git 操作禁止 (= `git revert` のみ採用)、 軽微 fix-up (= 連鎖 commit) + sub-sprint 単位 halt + ADR 全体 halt 3 段使い分け。

### 決定 8: 表記制約 + 解禁表現候補

#### ADR-0074 起票時点 (= 本 sprint α、 PR1 doc-only)

- **使用可**:
  - 「ADR-0074 sprint α 起票 = plan sprint 完了」
  - 「PMDDOTNET_MML runtime selection path repair の plan 設計開始」
  - 「infrastructure issue (= test01.mml 混入) を機械的に切り分け確定」
- **禁止維持 (= 起票時点)**:
  - 「PMDDOTNET_MML runtime selection path repair 完了」 (= ADR-0074 ε Accepted 後解禁)
  - 「指定 fixture 由来 audio 機械的証明達成」 (= γ runtime verify ALL PASS 後解禁)
  - 「ADR-0072 ε wording 訂正完了」 / 「ADR-0073 ε wording 訂正完了」 (= user judgment scope、 自走で訂正しない)
  - 「(d) audition gate 達成 / roadmap ⑥ audition 完了 / production-ready 全体達成 / 軸 B 完成 / 軸 G 完成 / 本番 cmd 切替完了」 (= 各 user 明示 GO 必須)

#### ADR-0074 ε Accepted 後 (= 解禁候補)

- 「**PMDDOTNET_MML runtime selection path repair 完了**」 (= 併記必須 mandatory = (i) preflight 専用 build mode 経路、 production binary 不変 + (ii) ADR-0058 §決定 1 mandate carry + (iii) ADR-0072/0073 ε wording 訂正・撤回 user judgment scope (= 自走しない) + (iv) audition gate 達成ではない + (v) production-ready 全体達成ではない + (vi) 軸 B 完成ではない + (vii) 軸 G 完成ではない + (viii) 本番 cmd 切替完了ではない)
- 「ADR-0074 ε Accepted」

## verify gate (= 本 PR1 sprint α scope = doc-only、 spec consistency check)

- gate 1: ADR doc 整合性 (= 平易 3 軸先頭 + 8 決定 literal + Codex Rescue review 5 必須軸)
- gate 2: ADR-0058 §決定 1 mandate との衝突明示 + 整合 path 提案 literal
- gate 3: production sha256 維持戦略 (= candidate 4 preflight 専用 build mode 推奨 path literal)
- gate 4: 既存 ADR-0072/0073 ε wording 影響整理 (= user judgment scope mandate carry)
- gate 5: dashboard 0074 行 add (= status + scope + dependency literal)
- gate 6: 改訂履歴 起票 entry append (= append only mandate 厳守)
- gate 7: 平易要約 6 構造 (= memory `feedback_explanation_style.md` 整合)
- gate 8: branch 運用 4 条規律 (= PR 先 default `wip-pmddotnet-opnb-extension` + merge atomic + close 不要時削除 + 保持対象 3 type 不可触)

## Codex Rescue plan review 5 必須軸 (= user 明示 mandate literal carry)

1. **PMDDOTNET_MML 指定 fixture が runtime で本当に起動できる設計か** = candidate 4 preflight 専用 build mode 経路で song_table 拡張 + main.c PMDNEO_SONG=N path が機能する設計妥当性
2. **test01.mml 混入を機械的に排除できるか** = song_table[0] = test01 を bypass + 新 slot 経由 dispatch で混入排除可能か
3. **trace と WAV segment で「この WAV はこの fixture 由来」 と証明できるか** = 機械的証明 method literal (= time-staggered fixture + per-channel register write timeline + segment RMS 一致 confirm)
4. **ADR-0058 §決定 1 との衝突を明示しているか** = 衝突明示 + 整合 path 提案 (= preflight 例外条件) literal
5. **user audition / δ session に勝手に進んでいないか** = scope OUT 明示 + 禁止 mandate literal carry

## review-only mandate 6 件 (= 冒頭 literal 強調)

1. no commit
2. no file change
3. no branch
4. no merge
5. no GitHub write
6. return judgment + findings only

## Annex α: plan v1 draft = touch 範囲 candidate 比較 + 推奨 path

### α-1: candidate 1-4 比較 table

| candidate | infrastructure 変更 | production sha256 影響 | ADR-0058 §決定 1 影響 | preflight 経路 確立 | 推奨 |
|---|---|---|---|---|---|
| 1 = song_table 拡張 + main.c PMDNEO_SONG=N | song_data.inc 改修 (= ~20 line 追加) + main.c 改修 (= PMDNEO_SONG=2 デフォルト か別 path) + build-poc.sh 改修 (= part offset → literal address 生成) | 影響あり (= song_table 拡張で binary size 変化) | mandate bypass (= 新 slot 経由) | ○ | × (= sha256 mandate 違反) |
| 2 = driver cmd handler 改修 | driver routine 追加 + main.c cmd 改修 | 影響あり (= driver routine 追加) | mandate 直接衝突 (= driver 内 song 起動 path 追加) | ○ | × (= driver 改修 + mandate 衝突) |
| 3 = build-poc.sh + song_data.inc 動的拡張 | build infra 改修 + song_table 動的拡張 | 影響あり (= 同上) | mandate bypass | ○ | △ (= sha256 mandate 違反) |
| **4 = preflight 専用 build mode (= TEST_MODE_PMDDOTNET_SONG_SELECT flag)** | **driver `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` flag 追加 + build infra sed 置換 + song_data.inc 動的拡張 (= flag=1 時のみ) + main.c PMDNEO_SONG=2 (= flag=1 時のみ)** | **flag=0 default = 完全不変 (= sha256 byte-identical 維持)** | **flag=0 default = mandate 完全 carry**、 flag=1 preflight 専用 = mandate 例外条件 (= 整合 path 提案) | ○ | **○ (= 推奨)** |

### α-2: 推奨 path = candidate 4 = preflight 専用 build mode 導入

#### 設計 outline

1. driver source `src/driver/standalone_test.s` 内 `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` 新規 flag 追加 (= 既存 TEST_MODE_AXIS_G_INT / TEST_MODE_MUTE_FIXTURE 等の precedent 同形)
2. build.mk 内 sed 置換 logic 追加 (= ADR-0016 step 3c-2 precedent 同形 = `ifeq ($(TEST_MODE_PMDDOTNET_SONG_SELECT),1) → s/, 0/, 1/`)
3. build-poc.sh 内 PMDDOTNET_MML 経路で `TEST_MODE_PMDDOTNET_SONG_SELECT=1` set + song_data.inc に pmddotnet_song を song_table[2] として追加生成 (= part offset table 経由 literal address 列計算 + song_table append、 flag=0 default では従来通り)
4. main.c に `PMDNEO_SONG=2` 経路 (= ng_center_text 文字列追加程度)
5. preflight 用 fixture (= staggered MML) を PMDDOTNET_MML 経由 build + `PMDNEO_SONG=2` で起動 + MAME runtime 再生

#### sha256 維持戦略

- flag=0 default (= production build) = 完全不変 (= `b15883fe...` byte-identical 維持)
- flag=1 preflight build = m1 binary 別 sha256 (= 期待値 record + verify)
- 4 build matrix B1-B4 pattern (= ADR-0071/0072/0073 precedent literal 継承):
  - (B1) production baseline = `b15883fe...`
  - (B2) post-patch flag=0 = (B1) byte-identical
  - (B3) flag=1 preflight pre-impl = (B1) 同等 (= まだ flag=1 path 未実装)
  - (B4) flag=1 preflight post-impl = 別 sha256 (= flag=1 path active で binary 変化)

#### 機械的証明 method

- preflight fixture = time-staggered single-note MML (= ADR-0065 δ preflight v2 type、 各 part 4 秒/slot × 7 part = 28 秒 total)
- MAME runtime + wav + trace 取得
- trace per-channel register write timeline = 時間帯 ↔ part 対応 confirm
- WAV segment RMS = 時間帯別 audible/silent 一致 confirm
- 「この WAV はこの fixture 由来」 = trace + segment + fixture MML byte-level diff (= test01.mml と異なる literal content)

## Annex β: plan v2 = candidate 4 実装前提具体化 (= 2026-05-27 43rd session、 sprint β round 1 投入 target)

### β-0: user 明示 mandate (= sprint β scope 6 mandate point literal carry)

> 「candidate 4 を実装前提まで具体化してください。 特に曖昧にしてはいけない点は以下です。
> - TEST_MODE_PMDDOTNET_SONG_SELECT=0 では production binary が完全不変であること
> - TEST_MODE_PMDDOTNET_SONG_SELECT=1 の時だけ PMDDOTNET_MML 指定 song を runtime 起動すること
> - main.c / song_data.inc / driver / build script のどこを触るか
> - PMDNEO_SONG=2 などの選択値がどう渡るか
> - test01.mml 混入をどう機械的に排除するか
> - trace + WAV segment で『この WAV は指定 fixture 由来』 と証明する方法」

### β-1: TEST_MODE_PMDDOTNET_SONG_SELECT flag = build → driver propagation 経路 literal

#### flag 定義経路 (= driver source 内)

`src/driver/standalone_test.s` 内 (= 既存 TEST_MODE_AXIS_G_INT (= line 49) / TEST_MODE_MUTE_FIXTURE (= line 58) / TEST_MODE_V2_ENTRY_FIXTURE (= line 75) precedent 同形配置):

```
;; ADR-0074 sprint γ: PMDDOTNET_MML runtime selection path repair (= preflight 専用 build mode)
;;   0 = production default (= 既存 cmd 9 経路 song_table[0/1] = test01/test02 carry、 PMDDOTNET_MML
;;       build artifact は ROM 内に存在するが MAME runtime cmd 9 経路 では選択されない)
;;   1 = preflight build (= cmd 9 + N で N=2 path 追加、 song_table[40-59] = pmddotnet_song の
;;       part_a〜z literal address column 経由 dispatch、 既存 song_table[0]/[1] entries 完全不変)
;; production 時は必ず 0 維持 (= TEST_MODE_AXIS_G_INT と同 pattern)。 preflight build 時のみ
;; 手動 / build-poc.sh で 1 set + ADR-0074 sprint γ 実装範囲。 ADR-0058 §決定 1 mandate
;; (= A-J test01 default、 K + L-Q のみ PMDDOTNET) は flag=0 で完全 carry、 flag=1 は
;; preflight 例外条件として本 ADR-0074 内 literal 明示。
        .equ    TEST_MODE_PMDDOTNET_SONG_SELECT, 0
```

#### sed 置換経路 (= build.mk PMDNEO_SED_EXPRS pattern carry)

`vendor/ngdevkit-examples/00-template/build.mk` 内 (= ADR-0016 step 3c-2 + TEST_MODE_AXIS_G_INT precedent 同形):

```makefile
# ADR-0074 sprint γ: TEST_MODE_PMDDOTNET_SONG_SELECT flag (= preflight build mode、
# pmddotnet_song を song_table[2] 経由 runtime 起動可能化、 flag=0 production default で完全不変)
TEST_MODE_PMDDOTNET_SONG_SELECT?=0

# ... 既存 PMDNEO_SED_EXPRS 群 ...

ifeq ($(TEST_MODE_PMDDOTNET_SONG_SELECT),1)
PMDNEO_SED_EXPRS+=-e 's/TEST_MODE_PMDDOTNET_SONG_SELECT, 0/TEST_MODE_PMDDOTNET_SONG_SELECT, 1/'
endif
```

#### flag propagation 経路 summary

| layer | flag literal | propagation 経路 |
|---|---|---|
| **build-poc.sh** | `TEST_MODE_PMDDOTNET_SONG_SELECT=1` env var（**caller明示指定必須、 build-poc.sh側 auto-set しない**= ADR-0072経路 K+L-Q only override carry を壊さないため、 preflight用 invocationのみ明示set） | env → make var |
| **build.mk** | `TEST_MODE_PMDDOTNET_SONG_SELECT=1` make var | make var → sed expr |
| **build infra (= sed 置換)** | `s/TEST_MODE_PMDDOTNET_SONG_SELECT, 0/TEST_MODE_PMDDOTNET_SONG_SELECT, 1/` | sed expr → standalone_test.preprocessed.s |
| **driver (= sdasz80 assemble)** | `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 1` | preprocessed.s → assembled m1 binary |
| **driver runtime (= `.if TEST_MODE_PMDDOTNET_SONG_SELECT`)** | guarded block active (= flag=1 配下 logic 有効化) | sdasz80 conditional assembly |

### β-2: production binary 完全不変 mandate (= flag=0 default、 ADR-0073 ε baseline `b15883fe...` 維持)

#### 不変保証 mechanism

- driver `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` = production default
- driver 内 ADR-0074 関連 logic 全 `.if TEST_MODE_PMDDOTNET_SONG_SELECT ... .endif` 配下 = flag=0 で assemble 全 skip = production binary 完全不変
- song_data.inc 内 ADR-0074 関連 entry (= song_table[40-59] = pmddotnet_song_part_a〜z literal column) は build-poc.sh PMDDOTNET_MML 経路で **`TEST_MODE_PMDDOTNET_SONG_SELECT=1` 時のみ動的 append** = flag=0 では song_table[0..39] 既存 entries 完全不変
- main.c 内 PMDNEO_SONG=2 経路 = `.equ PMDNEO_SONG, 0` default carry = flag=0 で M68K side cmd 9+2 経路 unreachable
- production sha256 = `b15883fe...` byte-identical 維持 mandate (= 4 build matrix B1-B4 verify pattern)

#### sha256 維持 verify gate (= γ build verify literal)

| build | flag combination | 期待 sha256 |
|---|---|---|
| **(B1) production baseline** | `PMDNEO_USE_PMDDOTNET=0` + `TEST_MODE_PMDDOTNET_SONG_SELECT=0` + no PMDDOTNET_MML | == `b15883fe...` byte-identical |
| **(B2) post-patch flag-off** | 同上 + ADR-0074 patch 全適用 | == (B1) byte-identical (= `.if TEST_MODE_PMDDOTNET_SONG_SELECT` 配下 assemble skip) |
| **(B3) PMDDOTNET on + SONG_SELECT off pre-patch（round 2 NH-1反映）** | `PMDNEO_USE_PMDDOTNET=1` + `TEST_MODE_PMDDOTNET_SONG_SELECT=0` + PMDDOTNET_MML=staggered | ADR-0073 ε state baseline（PMDDOTNET on path の K+L-Q only override経路、 ADR-0058 §決定 1 mandate carry状態） |
| **(B4) PMDDOTNET on + SONG_SELECT on post-patch（round 2 NH-1反映）** | `PMDNEO_USE_PMDDOTNET=1` + `TEST_MODE_PMDDOTNET_SONG_SELECT=1` + PMDDOTNET_MML=staggered | (B3)と diff = ADR-0074 patch byte量 + song_table拡張 byte（約40 byte = 20 entries × 2 byte literal）+ preflight runtime起動経路activeでstaggered fixture rendering可能 |

### β-3: TEST_MODE_PMDDOTNET_SONG_SELECT=1 時の runtime 起動経路 literal

#### main.c 改修 (= PMDNEO_SONG=2 経路追加、 mandatory)

`vendor/ngdevkit-examples/00-template/main.c` 内:

```c
// 既存 line 67 周辺:
*REG_SOUND = 9 + PMDNEO_SONG;  // = PMDNEO_SONG=2 で cmd 11 = driver_song_id=2 store
// 既存 line 89 周辺:
*REG_SOUND = 5;                // = nmi_cmd_5_init_mml_song trigger
```

main.c に新規追加なし = **既存 `9 + PMDNEO_SONG` 経路で PMDNEO_SONG=2 = cmd 11** が driver `nmi_cmd_select_song` (= L937-940) `sub #9` → `driver_song_id = 2` store → 既存 cmd 5 init_mml_song trigger 経路で song_table[2 × 20 + part_idx × 2] lookup。

```c
// 表示文字列追加のみ (= cosmetic、 lr 1 件 carry 解消):
#elif PMDNEO_SONG == 2
  ng_center_text(8, 0, "PMDNEO ADR-0074");
  ng_center_text(10, 0, "SONG 2 = PMDDOTNET PREFLIGHT");
#endif
```

#### song_data.inc動的拡張（build-poc.sh PMDDOTNET_MML経路でflag=1時のみ、 round 2 MF-1反映）

**重要: round 2 revise MF-1反映**= 既存`song_table:`block配下 `song1_part_z`直後にinsert必須。 末尾append（`>> song_data.inc`）だと`song_table[40..59]`連続参照不可能（既存`pmddotnet_song:`label が`song_table:`block直後にあるため、 song2 entries を末尾追加すると`song_table:`配列の連続性破壊）。 修正実装:

```bash
if [[ -n "${PMDDOTNET_MML:-}" && "${TEST_MODE_PMDDOTNET_SONG_SELECT:-0}" == "1" ]]; then
    # ADR-0074 sprint γ: pmddotnet_song を song_table[2] 経由 runtime 起動可能化
    # round 2 MF-2 反映: caller明示指定必須（build-poc.sh側auto-setしない、 ADR-0072経路K+L-Q only carry確保）
    python3 "$PMDNEO_ROOT/scripts/pmddotnet-song-table-entries.py" \
        --input "$TEMPLATE_DIR/pmddotnet_song.m" \
        --output "$TEMPLATE_DIR/pmddotnet_song_table_entries.inc" \
        --label-prefix song2_part
    # round 2 MF-1 反映: song_table:配下に挿入（既存song1_part_z直後）。
    # 既存 sed 経路（ADR-0072 plan v7 `/^voice_table:$/,$d`）と同 pattern、 sed `/pattern/r file`で
    # `.dw song1_part_q, song1_part_x, song1_part_y, song1_part_z` 行直後に挿入。
    sed -i.bak '/        \.dw song1_part_q, song1_part_x, song1_part_y, song1_part_z$/r '"$TEMPLATE_DIR/pmddotnet_song_table_entries.inc" "$TEMPLATE_DIR/song_data.inc"
    rm -f "$TEMPLATE_DIR/song_data.inc.bak"
    # 既存song_table:配下に20件のsong2_part entriesが挿入され、 song_table[40..59]連続参照可能。
    # song0_part_a〜z (= 0..19) + song1_part_a〜z (= 20..39) + song2_part_a〜z (= 40..59) で60 entries連続配置。
    export PMDNEO_SONG=2  # = preflight専用song slot指定
fi
```

helper script`scripts/pmddotnet-song-table-entries.py`の生成出力（song_table:配下挿入想定）:

```
;; ADR-0074 sprint γ: PMDDOTNET_MML preflight song slot (= TEST_MODE_PMDDOTNET_SONG_SELECT=1)
        .dw song2_part_a, song2_part_b, song2_part_c, song2_part_d
        .dw song2_part_e, song2_part_f, song2_part_g, song2_part_h
        .dw song2_part_i, song2_part_j, song2_part_k, song2_part_l
        .dw song2_part_m, song2_part_n, song2_part_o, song2_part_p
        .dw song2_part_q, song2_part_x, song2_part_y, song2_part_z
;; song2_part_X label 定義（pmddotnet_song + 1 + part_X_offset、 .M binary part offset table parse 経由）
song2_part_a == pmddotnet_song + 1 + <part_a_offset_from_pmddotnet_song.m>
song2_part_b == pmddotnet_song + 1 + <part_b_offset_from_pmddotnet_song.m>
;; ... 以下20件、 各part_X_offsetは.M binary L6080-6084のpart offset table経由実値
```

**LR-1反映mandate**: helper script内`pmddotnet_song + 1 + part_X_offset`計算は実装時に`.M binary byte origin`をverifier で固定確認mandate。 verifier method = `xxd pmddotnet_song.m | head -2`で先頭28 byte header確認 + offset_table_base = pmddotnet_song + 1 + extended_data_adr計算 + song2_part_X label resolve結果の byte-identical verify（γ-3 .lst predicate追加候補）。

新規 helper script `scripts/pmddotnet-song-table-entries.py` (= sprint γ 実装範囲):

- input = `pmddotnet_song.m` binary (= part offset table 内蔵)
- output = `pmddotnet_song_table_entries.inc` (= 20 entries `song_table` 拡張用 `.dw` literal column = `song2_part_a, song2_part_b, ..., song2_part_z`)
- 各 song2_part_X label = `pmddotnet_song + 1 + part_X_offset` (= driver L6081 `pmdneo_mn_direct_load_k_part_addr` と同 part offset 解釈 logic、 ただし K + L-Q 限定ではなく A-Q 全 20 part)
- generated `.inc` 内 = `.equ` で各 song2_part_X label 定義 + song_table 末尾に 20 entries `.dw` 追加

#### driver 側 runtime dispatch (= 既存 logic carry mandatory、 改修なし)

- driver `nmi_cmd_select_song` (= L937-940) = cmd 9+N → driver_song_id = N store (= 既存 carry)
- driver `load_song_part_addr` (= L3486-3521) = song_table[driver_song_id × 20 + part_idx × 2] lookup (= 既存 carry)
- driver_song_id=2 経路 = song_table[40..59] = pmddotnet_song_part_a〜z 経由 dispatch (= song_data.inc 動的拡張で flag=1 時のみ song_table[40-59] entries 存在)
- **driver routine 自体は完全不変** = ADR-0073 ε で確立した driver patch (= fix A/B/C + fm_volume_hook_pmddotnet 等) も既存 dispatch 経路で carry
- song_table[0]/[1] = test01/test02 entries は flag=0/1 共通完全不変

### β-4: PMDNEO_SONG=2 等選択値の渡し方 literal

#### 渡し方 chain literal

```
[build invocation]
  caller（preflight用 invocation）が PMDDOTNET_MML + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2を全部明示set
  （round 2 MF-2反映: build-poc.sh側 auto-setしない、 caller明示指定一本化、 ADR-0072経路 K+L-Q only carry確保）
      ↓
  build-poc.sh が TEST_MODE_PMDDOTNET_SONG_SELECT=1検出時のみ song_data.inc動的拡張 + PMDNEO_SONG=2 export pass-through
      ↓
[Makefile / build.mk]
  PMDNEO_SONG=$(PMDNEO_SONG) を CFLAGS に -DPMDNEO_SONG=$(PMDNEO_SONG) で渡す (= 既存経路 carry)
      ↓
[main.c]
  #define PMDNEO_SONG 2 (= CFLAGS 経由)
      ↓
[M68K runtime]
  *REG_SOUND = 9 + PMDNEO_SONG;  // = cmd 11
      ↓
[driver Z80 runtime (= nmi_cmd_select_song)]
  driver_song_id = 11 - 9 = 2
      ↓
[driver Z80 runtime (= cmd 5 後 load_song_part_addr)]
  song_table[2*20 + part_idx*2] = pmddotnet_song_part_X address
      ↓
[song play]
  pmddotnet_song の各 part が dispatch される
```

#### build-poc.sh PMDNEO_SONG export literal

```bash
if [[ -n "${PMDDOTNET_MML:-}" && "${TEST_MODE_PMDDOTNET_SONG_SELECT:-0}" == "1" ]]; then
    # ... song_table 拡張 ...
    export PMDNEO_SONG=2  # = preflight 専用 song slot 指定
fi
# 既存 make poc target は PMDNEO_SONG env var を CFLAGS に伝搬済 (= ngdevkit-examples build.mk 既存経路)
```

### β-5: test01.mml 混入を機械的に排除する方法 literal

#### 排除 mechanism 3 段

1. **driver_song_id = 2 store** = `cmd 9 + 2` で driver_song_id = 2 = song_table[0] = test01 lookup 経路 unreachable (= driver `load_song_part_addr` で song_table[40..59] direct lookup、 [0..19] 触らない)
2. **song_table[0..19] entries 完全不変** = song_data.inc 内 song0_part_a〜z entries は flag=0/1 共通で **literal 不変 carry** = build artifact 内 test01 part data 存在するが runtime 不参照
3. **part dispatch trace 確認 (= γ verify gate)** = MAME ymfm-trace per-channel register write timeline で song2_part_X (= pmddotnet_song_part_X) 由来 register write のみ確認、 test01 由来 register write 不在 evidence (= 各 part の MML byte sequence diff = test01 c4/d4/e4/g4/c5 連続 vs preflight staggered single-note + rest pattern)

#### 排除 verify gate (= γ-3 .lst predicate 追加候補)

- predicate add 1: song_data.inc 内 song_table[0..19] = song0_part_a〜z literal entries byte-identical 維持 (= flag=0/1 共通)
- predicate add 2: song_data.inc 内 song_table[40..59] = song2_part_a〜z literal entries 存在 (= flag=1 時のみ assemble)
- predicate add 3: m1 binary 内 song0_part_X data (= test01 part body) literal byte 不変 (= 既存 carry)
- predicate add 4: m1 binary 内 song2_part_X data (= pmddotnet_song part body) literal byte = pmddotnet_song.m 内 part_X offset から計算した addr / data 完全一致

### β-6: trace + WAV segment で「この WAV は指定 fixture 由来」 と証明する方法 literal

#### 機械的証明 method 3 軸

##### 軸 1: time-staggered fixture 設計 + 期待 audible window per part

preflight fixture (= 例 = ADR-0065 preflight-staggered.mml type):
- t60 + l1 (= 全音符 = 4 拍/note = 4 秒/note in t60)
- 7 part (= B/C/E/F/G/H/I) × 4 秒/slot = 28 秒 total
- 各 part 1 個 audible (= note) + 6 個 rest (= 残 24 秒 silent in that part)
- 期待 audible window:
  - 0-4 秒: B (= FM ch 2) only
  - 4-8 秒: C (= FM ch 3) only
  - ...
  - 24-28 秒: I (= SSG 3) only

##### 軸 2: trace per-channel register write timeline 一致 confirm

MAME ymfm-trace + 各 part chip ch index 対応:
- B = FM port A ch 1 (= reg 0x41 etc) → 0-4 秒 window に register writes 集中
- C = FM port A ch 2 (= reg 0x42 etc) → 4-8 秒 window
- E = FM port B ch 1 (= reg 0x41 port B) → 8-12 秒
- F = FM port B ch 2 (= reg 0x42 port B) → 12-16 秒
- G = SSG ch 1 (= reg 0x00/0x01/0x08 SSG) → 16-20 秒
- H = SSG ch 2 (= reg 0x02/0x03/0x09) → 20-24 秒
- I = SSG ch 3 (= reg 0x04/0x05/0x0A) → 24-28 秒

trace 解析 = 各 time bucket (= 4 秒/bucket) の per-channel register write count + write event の timestamp = 期待 timeline 一致 confirm。

##### 軸 3: WAV segment RMS audible/silent 一致 confirm

WAV segment analysis (= `scripts/segment-analyze.py` type):
- 0-4 秒 segment RMS > -60 dBFS = B audible expected
- 4-8 秒 segment RMS > -60 dBFS = C audible expected
- ... etc
- 28 秒以降 = silent expected
- per part audible/silent pattern 一致 confirm

##### 軸 4: fixture byte-level uniqueness (= test01.mml 混入排除 evidence)

- preflight fixture MML byte sequence (= staggered single-note + rest) ≠ test01.mml byte sequence (= c4/d4/e4/g4/c5 連続)
- pmddotnet_song.m 内 part_X data binary literal = preflight fixture compile 結果と完全一致 (= byte-identical confirm)
- song_table[2*20 + X*2] dispatch 経路 = song2_part_X label resolve → pmddotnet_song + 1 + part_X_offset address → preflight fixture compile 結果 byte 一致 = mechanically 「この WAV は preflight fixture 由来」 evidence

### β-7: sprint γ 実装範囲 + allowed-touch literal (= sprint β plan で確定)

#### 修正 file 4 件 (= γ で touch、 全 guarded change `.if TEST_MODE_PMDDOTNET_SONG_SELECT` 配下限定)

| file | 修正範囲 | flag-off 影響 |
|---|---|---|
| **`src/driver/standalone_test.s`** | line 75 周辺 `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` 追加 (= 既存 TEST_MODE_* precedent 同形配置) | 完全不変 (= flag=0 で `.if ... .endif` 配下 assemble skip、 ただし本 ADR-0074 では driver 内 `.if TEST_MODE_PMDDOTNET_SONG_SELECT` 配下に新規 logic 追加なし = song_table dispatch は既存 logic carry) |
| **`vendor/ngdevkit-examples/00-template/build.mk`** | line 140 周辺 `TEST_MODE_PMDDOTNET_SONG_SELECT?=0` 追加 + line 160 周辺 sed 置換 expr 追加 | 完全不変 (= flag=0 で sed expr skip、 standalone_test.preprocessed.s byte-identical 維持) |
| **`vendor/ngdevkit-examples/00-template/main.c`** | line 92 周辺 `#elif PMDNEO_SONG == 2` 追加 (= cosmetic、 ng_center_text 文字列表示のみ) | 完全不変 (= PMDNEO_SONG=0 default で 該当 #elif block 不 compile) |
| **`scripts/build-poc.sh`** | PMDDOTNET_MML block 内に caller明示指定の `TEST_MODE_PMDDOTNET_SONG_SELECT=1` 検出時のみ song_data.inc動的拡張 + `PMDNEO_SONG=2 export` pass-through追加（round 2 MF-2反映: build-poc.sh側 auto-setしない、 caller明示指定一本化）| 完全不変（PMDDOTNET_MML未設定 or TEST_MODE_PMDDOTNET_SONG_SELECT未設定 で skip、 PMDDOTNET_MML単独 build = ADR-0072経路 K+L-Q only carry）|

#### 新規 file 2 件

| file | 内容 |
|---|---|
| **`scripts/pmddotnet-song-table-entries.py`** | pmddotnet_song.m binary part offset table parse + song2_part_a〜z label + song_table extension `.inc` 生成 |
| **`src/test-fixtures/adr-0074/`** (= 新規 directory) | preflight fixture (= staggered MML) + verify script (= 4 build matrix + segment analyze + trace timeline 一致 confirm) |

#### 不可触対象 (= 既存 ADR mandate carry)

- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不変
- ADR-0026 §決定 3/4 K dispatch L ch 固定占有 完全不変
- ADR-0051 `pmdneo_ssg_tone_sync` (= reg 0x07 RMW 唯一 owner) 完全不変
- ADR-0058 v2 PartWork (= 0xFD79-0xFE78) 完全不変
- ADR-0067〜0073 既存 Annex 本文 (= immutable history mandate)
- 既存 verify script (= ADR-0049〜0073 全)
- 既存 fixture MML (= test01.mml / test02.mml / vendor/pmd48s/ / vendor/PMDDotNET/ / 他既存 ADR fixtures)
- ADR-0072/0073 ε wording (= user judgment scope mandate carry、 訂正・撤回しない)
- `src/tools/pmd-mml/compile.py` (= production 経路、 本 ADR-0074 では完全不変)
- ADR-0073 で確立した driver patch (= fix A/B/C + fm_volume_hook_pmddotnet + fm_carrier_table + SRAM equ 7 件) = 完全不変

### β-8: sprint γ verify gate literal

#### γ build verify (= 4 build matrix B1-B4 + .lst predicate 拡張)

- gate γ-1: 4 build matrix B1-B4 ALL PASS (= β-2 § literal)
- gate γ-2: production sha256 `b15883fe...` byte-identical 維持 (= B1/B2 で)
- gate γ-3: .lst predicate 拡張 (= ADR-0073 6 件 carry + ADR-0074 固有 4 件 = 計 10 件):
  1-6: ADR-0073 既存 predicate carry (= fm_carrier_table + fm_volume_hook_pmddotnet + SRAM equ 7 件 + 既存 routine body byte-identical 等)
  7: TEST_MODE_PMDDOTNET_SONG_SELECT flag .equ assemble PASS
  8: song_table[0..19] = song0_part_a〜z entries flag=0/1 共通 byte-identical 維持
  9: song_table[40..59] = song2_part_a〜z entries flag=1 時のみ assemble + flag=0 時 unassembled
  10: 既存 symbol table 順序不変 (= driver routine 完全 unchanged confirmation)
- gate γ-4: ADR-0051 owner contract untouched
- gate γ-5: 既存 verify script ALL PASS (= ADR-0049〜0073 regression-free)

#### δ functional verify (= staggered fixture runtime 再生機械的証明)

- gate δ-1: TEST_MODE_PMDDOTNET_SONG_SELECT=1 build + PMDDOTNET_MML=preflight-staggered.mml + PMDNEO_SONG=2 で MAME runtime 起動
- gate δ-2: ymfm-trace per-channel register write timeline = time-staggered fixture 期待 timeline 一致 (= β-6 § 軸 2 literal)
- gate δ-3: WAV segment per-part RMS audible/silent pattern 一致 (= β-6 § 軸 3 literal)
- gate δ-4: pmddotnet_song.m 内 part_X data byte = preflight fixture compile 結果 byte-identical (= β-6 § 軸 4 literal)
- gate δ-5: test01.mml 混入排除 = trace 内 song0_part_X (= test01) 由来 register write 不在 confirm
- gate δ-6: 既存 ADR-0073 ε で確立した「FM B/C audible」 が test01.mml 経路だった可能性 reconfirm = TEST_MODE_PMDDOTNET_SONG_SELECT=0 baseline (= test01.mml 経路) と TEST_MODE_PMDDOTNET_SONG_SELECT=1 + preflight fixture (= 指定 fixture 経路) の wav diff で test01 由来 audio が完全消失することを機械的に確認 (= ADR-0072/0073 ε wording validity question への evidence collection、 ただし wording 訂正・撤回判断は user 介入 mandatory)
- gate δ-7: ADR-0073 fix A/B/C (= comv + fm_volume_hook + pmdneo5_init_part) が flag=1 経路でも regression-free (= TEST_MODE_PMDDOTNET_SONG_SELECT は ADR-0073 patch flag PMDNEO_USE_PMDDOTNET と独立、 両 flag-on で fix A/B/C logic 引き続き active)

### β-9: Codex Rescue plan review round 2 投入 mandate (= sprint β verify scope)

#### round 2 重点 review 軸 (= sprint α 5 必須軸 carry + β plan v2 詳細化 軸追加)

- AXIS-RT-1〜5 (= sprint α carry)
- **AXIS-BETA-6 (= 新軸)**: 6 mandate point 詳細化 confirm
  - point 1: production binary 完全不変 (= flag=0 default、 β-2 §)
  - point 2: flag=1 時のみ PMDDOTNET_MML 指定 song runtime 起動 (= β-3 §)
  - point 3: main.c / song_data.inc / driver / build script touch literal (= β-7 §)
  - point 4: PMDNEO_SONG=2 渡し方 (= β-4 § chain literal)
  - point 5: test01.mml 混入機械的排除 (= β-5 §)
  - point 6: trace + WAV segment 機械的証明 (= β-6 §)
- **AXIS-BETA-7 (= 新軸)**: sprint γ 実装範囲 + allowed-touch literal 明確性 (= β-7 §)
- **AXIS-BETA-8 (= 新軸)**: verify gate γ + δ literal (= β-8 §)

#### review-only mandate 6 件 literal carry

#### 期待 経験則
- plan v2 review = 5-8 分 threshold (= sprint α plan v1 1 round approve precedent 同形期待)
- 8 分超過 = 機械復旧 rule cancel + 1 retry

## Annex γ: sprint γ runtime selection path implementation 完了 (= 2026-05-27 user 明示 GO 経路 + NH-1 (B) 採用 round 1 revise 反映)

### γ-0: NH-1 (B) 採用 round 1 revise 結果 (= 2026-05-27 user 明示判断 carry literal)

sprint γ impl 初版 (= PR #161 round 1) で Codex Rescue impl-review が NH-1 を **escalate-to-user** 判定。 user 明示判断「NH-1 は (B) を採用。 正規 preflight path = B5 (= PMDNEO_USE_PMDDOTNET=0 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML=preflight)。 song_table[40..59] を runtime で実際に使う経路を正とする。 B4 は scope-out または補助確認扱いに落とす。 driver patch 追加 (= (A)) は範囲拡大、 plan v3 mechanism 追記のみ (= (C)) は目的未達」 受領下、 本 round 1 revise で:

- **正規 preflight path = 旧 B5 を本 ADR-0074 内で B3 に re-label** (= γ-2 § build matrix で B3 = 正規、 B4 = 補助 reorder)
- **B4 (= PMDDOTNET=1 + SONG_SELECT=1)** = 補助確認扱い (= scope-out 相当、 ADR-0074 candidate 4 mechanism の runtime exercise 経路ではない)
- **driver source 完全 untouched** (= 「driver routine 自体は完全不変」 mandate carry、 (A) driver patch 追加路線拒否を反映)
- **verify-runtime-selection.sh 判定意味明確化** (= LR-1 解消 = deferred PASS / warn-only 全廃、 B3 predicate (a)〜(d) hard FAIL exit 経路)
- **ADR doc + dashboard + verify 説明 全て B3 正規 path に整合**

### γ-1: 修正・新規 file literal (= plan v3 Annex β-7 § 6 mandate point literal 反映 + round 1 revise verify 強化)

#### 修正 file 4 件 (= 全 guarded change `.if TEST_MODE_PMDDOTNET_SONG_SELECT` 配下限定 or build infra 経路限定)

| file | 修正範囲 | flag-off 影響 |
|---|---|---|
| **`src/driver/standalone_test.s`** | line 121 直後 (= TEST_MODE_AXIS_G_AUDITION_LEGACY_SKIP 直後) `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` 新規追加 (= 既存 TEST_MODE_AXIS_G_INT precedent 同形配置)、 driver 内 .if 配下 logic 追加なし (= song_table dispatch は既存 logic carry、 driver routine 自体は完全不変) | 完全不変 (= flag=0 default で symbol declared only、 既存 routine assemble に影響なし) |
| **`vendor/ngdevkit-examples/00-template/build.mk`** | line 152 `TEST_MODE_PMDDOTNET_SONG_SELECT?=0` 追加 + line 214 直前 sed 置換 expr 追加 (= `s/TEST_MODE_PMDDOTNET_SONG_SELECT, 0/TEST_MODE_PMDDOTNET_SONG_SELECT, 1/`) | 完全不変 (= flag=0 で sed expr skip、 PMDNEO_SED_EXPRS 集合に追加なし → cp で pass-through 継続) |
| **`vendor/ngdevkit-examples/00-template/main.c`** | line 99-102 `#elif PMDNEO_SONG == 2` 追加 (= cosmetic、 ng_center_text "PMDNEO ADR-0074" + "SONG 2 = PMDDOTNET PREFLIGHT" 表示のみ) | 完全不変 (= PMDNEO_SONG=0 default で #elif block 不 compile) |
| **`scripts/build-poc.sh`** | PMDDOTNET_MML block 後ろに caller 明示指定の `TEST_MODE_PMDDOTNET_SONG_SELECT=1` 検出時のみ helper script 呼出 + sed insert 経路追加、 make poc invocation に `TEST_MODE_PMDDOTNET_SONG_SELECT` + `PMDNEO_SONG` pass-through 追加 (= caller 明示指定一本化、 build-poc.sh 側 auto-set しない) | 完全不変 (= PMDDOTNET_MML 未設定 or TEST_MODE_PMDDOTNET_SONG_SELECT 未設定 = ADR-0072 経路 K + L-Q only carry) |

#### 新規 file 2 件

| file | 内容 |
|---|---|
| **`scripts/pmddotnet-song-table-entries.py`** | PMDDotNET .M / .MN binary part offset table (= bytes 1..22 LE 16-bit × 11 entries A-K) parse + song_table[40..59] = song2_part_a〜z 20 entries `.dw` column + song2_part_X label `==` 絶対 equate 定義生成 + byte origin verifier comment (= LR-1 反映) |
| **`src/test-fixtures/adr-0074/preflight-staggered.mml`** | preflight fixture = ADR-0065 staggered single-note pattern 継承 (= 7 part B/C/E/F/G/H/I × 4 秒/slot = 28 秒 total)、 CRLF line ending (= PMDDotNET parser 想定) |
| **`src/test-fixtures/adr-0074/verify-runtime-selection.sh`** | γ build verify gate γ-1〜γ-5 (= 4 build matrix B1-B4 + .lst predicate 10 件 + ADR-0051 owner contract untouched + ADR-0073 verify regression-free) |

### γ-2: 4 build matrix verify result (= γ-1 build verify gate ALL PASS、 round 1 revise = B3 正規 / B4 補助 reorder)

| build | flag combination | sha256 (= verify-runtime-selection.sh empirical 結果) | 役割 |
|---|---|---|---|
| **(B1) production baseline** | `PMDNEO_USE_PMDDOTNET=0` + `TEST_MODE_PMDDOTNET_SONG_SELECT=0` + no PMDDOTNET_MML | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` = ACTIVE_BASELINE byte-identical ✓ | production baseline (= flag-off mandate carry) |
| **(B2) post-patch flag-off** | 同上 + ADR-0074 patch 全適用 | `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` = (B1) byte-identical ✓ | guarded change flag-off 完全無効化 confirm |
| **(B3) 正規 preflight path** | `PMDNEO_USE_PMDDOTNET=0` + `TEST_MODE_PMDDOTNET_SONG_SELECT=1` + `PMDNEO_SONG=2` + PMDDOTNET_MML=preflight-staggered.mml | `29e0fd1ca1ed148cd79b1252bc223ddf90b07648ab4ded100c56e8c876a891c4` = song_table[40..59] song2_part_a〜z entries 挿入 active + driver `load_song_part_addr` 経路 + driver_song_id=2 + song2_part_X → pmddotnet_song body bytes dispatch | **正規 preflight path = NH-1 (B) 採用後の ADR-0074 candidate 4 mechanism runtime exercise 経路** = δ runtime functional verify 適用 build |
| **(B4) 補助 build (= scope-out 相当)** | `PMDNEO_USE_PMDDOTNET=1` + `TEST_MODE_PMDDOTNET_SONG_SELECT=1` + `PMDNEO_SONG=2` + PMDDOTNET_MML=preflight-staggered.mml | `ff9a5013474f7b58685d5d57c484c956d4fc7010583a2ee3ef126ec67eb6ffbc` | 補助確認扱い (= driver `pmdneo_mn_direct_load_aj_part_addr` 経路 = .m header offset 直接 dispatch、 song_table[40..59] entries は build 内存在するが runtime 未参照、 ADR-0074 candidate 4 mechanism の runtime exercise 経路ではない) = plan v3 wording 整合性確認のための補助 record only |

#### B3 .lst predicate (a)〜(d) ALL PASS (= round 1 revise verify 強化、 LR-1 解消 = deferred PASS / warn-only 全廃)

- **predicate (a)**: `song2_part_a〜z` 20 個の `==` 絶対 equate 全 active assemble confirm (= helper script output 整合)
- **predicate (b)**: `song_table[40..59]` 内 `song2_part_X` `.dw` rows 5 件 (= 4 entries × 5 = 20 entries 連続) assemble confirm
- **predicate (c)**: `song_table[0..19]` = `song0_part_a〜z` 20 labels 完全保存 confirm (= ADR-0058 §決定 1 mandate carry = test01 default 不変)
- **predicate (d)**: driver `load_song_part_addr` call site assembled confirm (= PMDNEO_USE_PMDDOTNET=0 mode で song_table 経由 dispatch active、 NH-1 (B) 採用 mechanism の runtime exercise 経路成立 evidence)

#### .lst predicate 10 件 ALL PASS (= ADR-0073 6 件 carry + ADR-0074 固有 4 件)

| predicate | 確認内容 | 確認 build |
|---|---|---|
| 1-6 | ADR-0073 carry = 既存 routine body + symbol table 順序 byte-identical | B1/B2 (= γ-1/γ-2 で確認済) |
| 7 | TEST_MODE_PMDDOTNET_SONG_SELECT flag .equ in preprocessed source | B1/B2 |
| 8 | song_table[0..19] = song0_part_a〜z entries flag=0/1 共通完全保存 | B3 predicate (c) で実体化 (= LR-1 解消、 旧版 deferred PASS 廃止) |
| 9 | song_table[40..59] = song2_part_a〜z entries flag=0 時 unassembled | B1/B2 song_data.inc literal check + .lst `==` equate 行非存在 |
| 10 | 既存 symbol 9 件 ADR-0073 carry | B1/B2 .lst grep |

### γ-3: NH-1 design observation 解決 record (= main agent γ impl 中発見 → Codex Rescue impl-review escalate-to-user → user 明示判断 (B) 採用 round 1 revise)

#### NH-1 finding 経緯 (= 初版 γ impl PR #161 round 1)

γ impl 後の driver actual code 解析で、 plan v3 β-3 § (= 「driver `load_song_part_addr` (= L3486-3521) = song_table 経由 dispatch」) と driver 現状 logic (= ADR-0069 α で導入された `.if PMDNEO_USE_PMDDOTNET == 1` 配下 10 instance: `call pmdneo_mn_direct_load_aj_part_addr`) との **dispatch path 整合性 question** を発見:

#### finding literal

driver `src/driver/standalone_test.s` L1802-1889 で per-part init dispatch は次の guarded pattern:

```
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #N
        call    pmdneo_mn_direct_load_aj_part_addr   ; HL = pmddotnet_song + 1 + .m header offset[N]
.else
        ld      a, #N
        call    load_song_part_addr                   ; HL = song_table[song_id*20 + N*2]
.endif
```

→ PMDNEO_USE_PMDDOTNET=1 mode = `pmdneo_mn_direct_load_aj_part_addr` 経路で .m header offset 直接 dispatch (= song_table bypass)、 driver_song_id 不参照
→ PMDNEO_USE_PMDDOTNET=0 mode = `load_song_part_addr` 経路で song_table[song_id*20 + part*2] dispatch、 driver_song_id 参照

#### 帰結 (= candidate 4 plan v3 と現状 driver dispatch logic の交差)

| 設定組合せ | 機構 | runtime dispatch path |
|---|---|---|
| (B4 plan v3 設定) PMDDOTNET=1 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML | song_table[40..59] 動的挿入 + main.c PMDNEO_SONG=2 + ADR-0072/0073 patch 全 active | driver は **`pmdneo_mn_direct_load_aj_part_addr` 経路 = .m header offset 直接 dispatch** (= song_table[40..59] 未参照、 plan v3 β-3 § song_table dispatch logic は使われない)、 ただし pmddotnet_song .m bytes は preflight-staggered fixture 由来 = 結果として preflight fixture が dispatch される |
| (B5 = plan 未明記の補助 build、 main agent γ impl 中 empirical 確認) PMDDOTNET=0 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML | song_table[40..59] 動的挿入 + main.c PMDNEO_SONG=2 + ADR-0072/0073 patch **inactive** (= `.if PMDNEO_USE_PMDDOTNET` 配下のため flag-off で skip) | driver は **`load_song_part_addr` 経路 = song_table[40..59] dispatch** (= plan v3 β-3 § song_table dispatch logic が動作)、 song2_part_X label が pmddotnet_song + 1 + offset_X を指す → .m body bytes を dispatch、 ただし ADR-0072 voice opcode (= `0xFF N`) handling は inactive |

#### user judgment 軸該当部 (= 自走しない mandate carry、 初版 PR #161 round 1 で record + Codex Rescue impl-review escalate-to-user 由来)

- **(a) B4 mode で plan v3 mechanism が実質 unused = 設計上の意図と異なる runtime path** → 判断軸 = (i) plan v3 mechanism を取り下げて「PMDDOTNET=1 単独で fixture dispatch される事実」 を documentation する path / (ii) plan v3 mechanism を有効化するために driver patch (= `TEST_MODE_PMDDOTNET_SONG_SELECT=1` 時に PMDNEO_USE_PMDDOTNET path で song_table 経由 dispatch に切り替える gate 追加) / (iii) B5 path を新規 build matrix として正式採用 + ADR-0072/0073 patch を SONG_SELECT=1 でも active 化する driver patch 追加
- **(b) ADR-0072/0073 ε wording validity question 拡張** = γ impl finding は ADR-0072/0073 ε で確立した「driver patch effect 観測」 が test01.mml 経路 audio measurement だった可能性を強化 (= 既存 user judgment 軸 + 自走で wording 訂正・撤回しない mandate carry)
- **(c) preflight fixture 由来 audio の機械的証明 method 適用 build 選択** = δ runtime functional verify で B4 / B5 のどちらを採用するか = ADR-0058 §決定 1 mandate との関係も含む

#### user 明示判断 (= 2026-05-27 user mandate literal carry、 round 1 revise 反映)

> 「NH-1 は (B) を採用してください。 正規 preflight path = `PMDNEO_USE_PMDDOTNET=0` + `TEST_MODE_PMDDOTNET_SONG_SELECT=1` + `PMDNEO_SONG=2` + song_table[40..59] を runtime で実際に使う経路を正とする。 B4 は scope-out または補助確認扱いに落とす。 ADR doc、 dashboard、 verify 説明を B5 正規 path に合わせて修正する。 verify-runtime-selection.sh の deferred PASS や warn-only は、 次 sprint 送りにせず、 今回の revise で判定意味を明確にする。 (A) は driver 側の追加変更が増える、 (C) は不整合を記録するだけで目的を満たさない。」

#### round 1 revise で実施 (= 本 Annex γ § rewrite)

- (a) → **(B) 採用** = 正規 preflight path を B3 として再定義 (= 旧版 B3 を本 ADR-0074 内で B3 = 正規 preflight path に re-label)、 B4 = 補助確認扱い格下げ
- (b) → 自走しない mandate carry 維持 (= ADR-0072/0073 ε wording 訂正・撤回判断は ADR-0074 ε Accepted 後の user 介入 mandatory)
- (c) → δ runtime functional verify は B3 正規 preflight path で実施 (= NH-1 (B) 採用後の primary verify path、 別 sub-sprint δ 起票時に literal 反映)

#### 帰結 table (= round 1 revise 後)

| 設定組合せ | 機構 | runtime dispatch path | 役割 |
|---|---|---|---|
| **B3 = PMDDOTNET=0 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML** (= NH-1 (B) 採用後 **正規 preflight path**) | song_table[40..59] 動的挿入 + main.c PMDNEO_SONG=2 + ADR-0072/0073 patch **inactive** (= `.if PMDNEO_USE_PMDDOTNET` 配下のため flag-off で skip) | driver は **`load_song_part_addr` 経路 = song_table[40..59] dispatch** (= ADR-0074 candidate 4 mechanism の runtime exercise 経路)、 song2_part_X label が pmddotnet_song + 1 + offset_X を指す → .m body bytes を dispatch、 ただし ADR-0072 voice opcode (= `0xFF N`) handling は inactive | **正規 preflight path** = δ runtime functional verify 適用 build |
| B4 = PMDDOTNET=1 + SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML | song_table[40..59] entries は build 内存在するが runtime 未参照 + main.c PMDNEO_SONG=2 = cmd 11 store + ADR-0072/0073 patch 全 active | driver は **`pmdneo_mn_direct_load_aj_part_addr` 経路 = .m header offset 直接 dispatch** (= song_table[40..59] 未参照、 plan v3 β-3 § song_table dispatch logic は使われない)、 ただし pmddotnet_song .m bytes は preflight-staggered fixture 由来 = 結果として preflight fixture が dispatch される | **補助確認扱い (= scope-out 相当)** = ADR-0074 candidate 4 mechanism の runtime exercise 経路ではない、 plan v3 wording 整合性確認のための補助 record only |

### γ-4: 不可触対象 confirm (= 既存 ADR mandate carry)

- ADR-0048 軸 G ε partial state placement (= 0xFD32-0xFD38) 完全不変
- ADR-0026 §決定 3/4 K dispatch L ch 固定占有 完全不変
- ADR-0051 `pmdneo_ssg_tone_sync` (= reg 0x07 RMW 唯一 owner) 完全不変
- ADR-0058 v2 PartWork (= 0xFD79-0xFE78) 完全不変
- ADR-0067〜0073 既存 Annex 本文 (= immutable history mandate)
- 既存 verify script (= ADR-0049〜0073 全)
- 既存 fixture MML (= test01.mml / test02.mml / vendor/pmd48s/ / vendor/PMDDotNET/ / 他既存 ADR fixtures)
- ADR-0072/0073 ε wording (= user judgment scope mandate carry、 訂正・撤回しない)
- `src/tools/pmd-mml/compile.py` (= production 経路、 本 ADR-0074 では完全不変)
- ADR-0073 で確立した driver patch (= fix A/B/C + fm_volume_hook_pmddotnet + fm_carrier_table + SRAM equ 7 件) = 完全不変

### γ-5: Codex Rescue impl-review chain (= round 1 escalate-to-user → round 1 revise → round 2 approve target)

- **round 1** (= initial impl PR #161 commit `9ec1684`、 agentId `codex-20260527-182147-JST`、 elapsed 3m 10s) = 9 軸 PASS + must-fix 0 件 + **NH-1 = escalate-to-user 判定** (= AXIS-NH-1 = B4 で song_table[40..59] dispatch 未使用問題、 3 択 (A)/(B)/(C) user 判断必須)、 LR-1 軽微 (= verify-runtime-selection.sh deferred PASS / warn-only exit 0 統一望ましい)、 越権操作なし
- **round 1 revise** (= 2026-05-27 user 明示判断「NH-1 (B) 採用、 PR #161 を revise」 受領経路) = 本 Annex γ § rewrite + verify-runtime-selection.sh B-matrix reorder + LR-1 解消 + ADR doc + B3 predicate (a)〜(d) hard FAIL exit 経路化、 driver source 完全 untouched (= (A) 拒否反映、 「driver routine 自体は完全不変」 mandate carry)
- **round 2** = round 1 revise commit + 同 AXIS carry confirm + NH-1 (B) 採用反映 confirm + LR-1 解消 confirm、 approve target (= sprint γ impl review 経験則 20 分 threshold 内)

## Annex δ / ε: placeholder (= 後続 sub-sprint fill 予定)

## 改訂履歴

- 2026-05-27: ADR-0074 sprint γ PR3 round 1 revise fix-up (= NH-1 (B) 採用反映、 user 明示判断 carry literal)。 初版 PR #161 commit `9ec1684` の Codex Rescue impl-review (= agentId `codex-20260527-182147-JST`、 elapsed 3m 10s) で 9 軸 PASS + must-fix 0 件 + AXIS-NH-1 = escalate-to-user 判定 + LR-1 軽微 verify exit code 統一望ましい finding 受領後、 user 明示判断「NH-1 は (B) 採用 = 正規 preflight path = PMDNEO_USE_PMDDOTNET=0 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + song_table[40..59] を runtime で実際に使う経路を正とする + B4 は scope-out または補助確認扱い + ADR doc / dashboard / verify 説明全て B5 正規 path に合わせて修正 + verify-runtime-selection.sh deferred PASS / warn-only は今回の revise で判定意味明確化 = 次 sprint 送りにしない + (A) は driver 側追加変更が増える / (C) は不整合を記録するだけで目的未達」 受領 + 禁止 mandate carry「PR #161 を現状のまま merge しない + ADR-0072/0073 wording 訂正に進まない + ADR-0065 δ session に進まない + user audition に進まない」。 本 round 1 revise で実施: (1) Annex γ §γ-0 round 1 revise 結果 section 新規追加 (= NH-1 (B) 採用 record + 旧 B5 → 本 ADR-0074 内 B3 = 正規 preflight path に re-label + B4 = 補助確認扱い格下げ + driver source 完全 untouched 明示 + verify-runtime-selection.sh 判定意味明確化 + ADR doc + dashboard + verify 説明 全て B3 正規 path 整合) + (2) Annex γ §γ-2 build matrix reorder (= B1 production baseline / B2 post-patch flag-off / **B3 = 正規 preflight path (= NH-1 (B) 採用後 ADR-0074 candidate 4 mechanism runtime exercise 経路 = δ runtime functional verify 適用 build、 PMDNEO_USE_PMDDOTNET=0 + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2 + PMDDOTNET_MML、 sha256 `29e0fd1ca1ed148cd79b1252bc223ddf90b07648ab4ded100c56e8c876a891c4`、 driver `load_song_part_addr` 経路 + song_table[40..59] dispatch active + driver_song_id=2 + song2_part_X → pmddotnet_song body bytes dispatch、 ADR-0072/0073 patch inactive 状態下)** / B4 = 補助確認扱い (= scope-out 相当、 plan v3 wording 整合性確認のための補助 record only)) + B3 predicate (a)〜(d) ALL PASS 4 件 record (= song2_part_a〜z 20 == equate assemble + song_table[40..59] song2_part_X .dw rows assemble + song_table[0..19] = song0_part_a〜z 20 labels 完全保存 + driver `load_song_part_addr` call site assembled = song_table 経由 dispatch active evidence) + (3) Annex γ §γ-3 user 明示判断 record section 追加 (= user mandate literal carry + round 1 revise で実施した (a)/(b)/(c) 反映内容明記 + 帰結 table を round 1 revise 後 state に rewrite) + (4) Annex γ §γ-5 Codex Rescue chain update (= round 1 = NH-1 escalate-to-user 判定 record + round 1 revise = ADR doc rewrite + verify 強化 + driver untouched mandate carry + round 2 = approve target literal) + (5) verify-runtime-selection.sh 全面 rewrite (= B-matrix reorder = B1/B2 carry + B3 = 正規 preflight path active build + 4 predicate (a)/(b)/(c)/(d) hard FAIL exit 経路化 + B4 = 補助 build 格下げ wording、 LR-1 解消 = deferred PASS / warn-only exit 0 全廃) + (6) §決定 2 γ row update (= NH-1 (B) 採用 round 1 revise 完了 wording 反映、 正規 preflight path = B3 明示)。 driver `src/driver/standalone_test.s` 完全 untouched carry (= (A) driver patch 追加路線拒否反映、 「driver routine 自体は完全不変」 mandate strict carry)、 production sha256 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` byte-identical 維持 (= B1/B2 = ACTIVE_BASELINE 一致 confirm)、 retained branch 3 type (= user 別作業 / scope-out / 退避) 完全 untouched 維持。 後続 = round 1 revise commit + push + Codex Rescue impl-review round 2 投入 + 同 AXIS carry confirm + NH-1 (B) 採用反映 confirm + LR-1 解消 confirm + approve loop + main agent 経路 merge + atomic 1 セット規律 19 回目適用予定 (= PR #142+...+#160+本 γ PR3 round 1 revise)。
- 2026-05-27: ADR-0074 sprint γ PR3 起票 (= Annex γ literal fill = candidate 4 runtime selection path implementation 完了 + 4 build matrix B1-B4 ALL PASS + .lst predicate 10 件 ALL PASS + γ-1〜γ-5 ALL PASS + production sha256 `b15883fe59804a201e13d0c05f083c1c3dd31fbfb1efd193b34d550d18f561e4` byte-identical 維持 + NH-1 design observation 発見)、 起票者: 越川将人 (= 主軸 Claude Code 経由)、 user 明示 GO mandate「ADR-0074 sprintγ GO。 実装とverifyを進めてください。 δ sessionやwording訂正には進まないでください」 受領 + 事前提示 4 軸再提示 (= `feedback_adr_0074_gamma_pre_offer_required.md` mandate 経路) 経由、 base anchor `wip-pmddotnet-opnb-extension@b50e2c2`。 修正 file 4 件 (= driver `.equ TEST_MODE_PMDDOTNET_SONG_SELECT, 0` + build.mk make var + sed expr + main.c `#elif PMDNEO_SONG == 2` cosmetic + build-poc.sh caller 明示指定 detection + helper script invocation + sed insert + make poc invocation pass-through) + 新規 file 2 件 (= `scripts/pmddotnet-song-table-entries.py` = PMDDotNET .M binary header parse + song_table[40..59] entries + 20 song2_part_X `==` 絶対 equate 定義生成 + byte origin verifier comment (= LR-1 反映) + `src/test-fixtures/adr-0074/` directory = preflight-staggered.mml (= ADR-0065 pattern 継承 CRLF) + verify-runtime-selection.sh (= γ build verify gate γ-1〜γ-5 + 4 build matrix B1-B4 + .lst predicate 10 件)) + 不可触対象全継承 (= ADR-0048 軸 G ε partial state + ADR-0026 §決定 3/4 + ADR-0051 owner contract + ADR-0058 v2 PartWork + ADR-0067〜0073 既存 Annex 本文 + 既存 verify script + 既存 fixture MML + ADR-0072/0073 ε wording user judgment scope mandate carry + compile.py production 経路 + ADR-0073 driver patch fix A/B/C 全 完全不変) = guarded change `.if TEST_MODE_PMDDOTNET_SONG_SELECT` 配下限定 (= flag=0 default で symbol declared only、 driver 内 .if 配下 logic 追加なし)。 γ build verify result = (B1) `b15883fe...` ACTIVE_BASELINE byte-identical + (B2) `b15883fe...` (B1) byte-identical (= guarded change flag-off 完全無効化 confirm) + (B3) `99e5644d...` ADR-0073 ε state baseline + (B4) `ff9a5013...` song2 entries assembled + main.c PMDNEO_SONG=2 経路、 .lst predicate 10 件 ALL PASS (= ADR-0073 carry 1-6 + ADR-0074 固有 7-10 = TEST_MODE_PMDDOTNET_SONG_SELECT flag in preprocessed + song_table[0..19] flag=0/1 共通 byte-identical + song_table[40..59] flag-off 時 unassembled + 既存 symbol 9 件 carry)、 NH-1 design observation literal record (= γ-3 § literal = driver L1802-1889 `.if PMDNEO_USE_PMDDOTNET == 1 ... pmdneo_mn_direct_load_aj_part_addr ... .else ... load_song_part_addr ...` per-part guarded pattern により plan v3 β-3 § 「song_table 経由 dispatch」 logic は PMDNEO_USE_PMDDOTNET=0 mode 限定 active = B4 build (= PMDDOTNET=1) では plan v3 mechanism 未使用 + B5 補助 build (= PMDDOTNET=0 + SONG_SELECT=1) 試行で plan v3 mechanism 動作確認 = ADR-0072/0073 patch inactive 状態下) = user judgment 軸該当 3 件 ((a) plan v3 mechanism 取り下げ vs driver patch 追加 vs B5 build matrix 正式採用、 (b) ADR-0072/0073 ε wording validity question 拡張、 (c) δ runtime functional verify 適用 build 選択) は **main agent 自走しない carry** = 後続 user 明示 GO mandatory。 後続 = Codex Rescue impl-review 投入 + AXIS-FIX 新軸 + NH-1 design observation 評価 (= main agent autonomous default = 機械復旧 rule 経路) + approve loop + main agent 経路 merge + atomic 1 セット規律 19 回目適用予定 (= PR #142+...+#160+本 γ PR3) + ADR-0072/0073 ε wording 訂正・撤回判断 + sprint δ runtime functional verify 起票判断 = 各 user 明示 GO 必須 (= 自走しない mandate carry)。
- 2026-05-27: ADR-0074 sprint β PR2 round 3 Codex Rescue plan review（agentId `af47ff1d23a69c063`、 約2m 20s）**revise** + must-fix 1（new）+ nh 0 + lr 0 + 越権操作なし confirmed = per-axis verdict round 3 = AXIS-FIX-1 PASS（MF-1 song_table挿入位置反映確認 = sed insert literal mandatory化）+ AXIS-FIX-2 **FAIL**（MF-2 caller明示指定一本化、 β-1 line 349 fix済だが β-4 line 458 + β-7 line 559 に旧 auto-set記述残存）+ AXIS-FIX-3 PASS（NH-1 B3/B4 wording区別反映）+ AXIS-FIX-4 PASS（LR-1 byte origin verifier mandate反映）、 must-fix 1件 = β-4 / β-7 残存 auto-set記述を caller明示指定一本化に統一修正、 main agent autonomous で軽微 fix-up commit = β-4 line 458 「build-poc.sh が PMDDOTNET_MML detect + flag=1 set」 → 「caller（preflight用 invocation）が PMDDOTNET_MML + TEST_MODE_PMDDOTNET_SONG_SELECT=1 + PMDNEO_SONG=2全部明示set + build-poc.sh側 auto-setしない literal carry」修正 + β-7 line 559 build-poc.sh row 「PMDDOTNET_MML block内 TEST_MODE_PMDDOTNET_SONG_SELECT=1設定」 → 「caller明示指定の TEST_MODE_PMDDOTNET_SONG_SELECT=1検出時のみ song_data.inc動的拡張 + PMDNEO_SONG=2 pass-through、 PMDDOTNET_MML単独 build = ADR-0072経路 K+L-Q only carry literal carry」修正、 round 4投入予定（同 AXIS-FIX carry confirm）。
- 2026-05-27: ADR-0074 sprint β PR2 round 2 Codex Rescue plan review (= agentId `ae8532559e5cda879`、 elapsed約3m 34s) **revise** + must-fix 2 + nh 1 + lr 1 + 越権操作なし confirmed = per-axis verdict round 2 = AXIS-RT-1/RT-2/AXIS-BETA-6 FAIL（song_table[40..59]連続性未保証 + build-poc.sh auto-set vs caller明示指定衝突）+ AXIS-RT-3/RT-4/RT-5/AXIS-BETA-7/AXIS-BETA-8 PASS、 must-fix 2件 = MF-1 song_table挿入位置literal化（既存song_table:配下 song1_part_z直後にinsert mandatory、 末尾append不可）+ MF-2 build-poc.sh auto-set vs caller明示指定一本化（caller明示指定採用= ADR-0072経路 K+L-Q only carry確保）、 nh 1件 = NH-1 B3/B4 wording区別（PMDDOTNET on + SONG_SELECT off/on 明示）、 lr 1件 = LR-1 helper script byte origin verifier mandate γ-3 .lst predicate追加候補、 main agent autonomous で軽微 fix-up commit（memory `feedback_main_agent_engineering_responsibility.md` literal「doc wording = Claude Code自分で直す」整合）= β-1 flag propagation表 + β-3 song_data.inc動的拡張 sed insert literal修正 + β-2 4 build matrix B3/B4 wording区別 + β-3 LR-1反映 helper script byte origin verifier mandate、 round 3投入予定（同 AXIS carry confirm + MF-1/MF-2/NH-1/LR-1反映確認）。
- 2026-05-27: ADR-0074 sprint β PR2 起票 (= Annex β plan v2 literal fill = candidate 4 実装前提具体化 doc-only sprint)、 起票者: 越川将人 (= 主軸 Claude Code 経由)、 user 明示 GO mandate「candidate 4 を実装前提まで具体化、 6 mandate point 曖昧禁止 = (1) TEST_MODE_PMDDOTNET_SONG_SELECT=0 で production binary 完全不変 + (2) flag=1 時のみ PMDDOTNET_MML 指定 song runtime 起動 + (3) main.c / song_data.inc / driver / build script どこを touch するか literal + (4) PMDNEO_SONG=2 等選択値の渡し方 + (5) test01.mml 混入機械的排除 + (6) trace + WAV segment で『この WAV は指定 fixture 由来』 証明方法 + δ session / candidate 評価に戻らない (= infrastructure repair scope carry)」 mandate 経路、 base anchor `wip-pmddotnet-opnb-extension@8c17821`。 Annex β fill 9 sub-section literal = β-0 user mandate carry + β-1 flag build → driver propagation 経路 (= driver `.equ` 配置 + build.mk sed expr 追加 = 既存 TEST_MODE_AXIS_G_INT precedent 同形) + β-2 production binary 完全不変 mandate (= flag=0 default + 4 build matrix B1-B4 verify pattern) + β-3 flag=1 時 runtime 起動経路 (= main.c PMDNEO_SONG=2 + driver_song_id=2 + song_table[2*20+part*2] dispatch、 driver routine 自体は完全不変、 既存 logic carry) + β-4 PMDNEO_SONG=2 渡し方 chain literal (= build-poc.sh env → build.mk make var → CFLAGS -DPMDNEO_SONG=2 → main.c → cmd 11 → driver_song_id=2) + β-5 test01.mml 混入機械的排除 3 段 (= driver_song_id=2 で song_table[0] unreachable + song_table[0..19] entries 完全不変 + part dispatch trace evidence) + β-6 trace + WAV segment 機械的証明 4 軸 (= time-staggered fixture 期待 audible window + per-channel register write timeline + segment RMS pattern + fixture byte-level uniqueness) + β-7 sprint γ 実装範囲 + allowed-touch literal (= 修正 file 4 件 = driver flag + build.mk + main.c + build-poc.sh + 新規 file 2 件 = pmddotnet-song-table-entries.py + src/test-fixtures/adr-0074/、 不可触対象 ADR-0048〜0073 全継承) + β-8 verify gate γ + δ literal (= 4 build matrix + .lst predicate 10 件 + δ-1〜δ-7 + δ-6 で ADR-0072/0073 ε wording validity question evidence collection (= ただし訂正・撤回判断は user 介入 mandatory)) + β-9 Codex Rescue plan review round 2 投入 mandate (= 5 必須軸 carry + AXIS-BETA-6/7/8 新軸)、 後続 = Codex Rescue plan review round 2 投入 + approve loop + main agent 経路 merge + atomic 1 セット規律 18 回目適用予定 (= PR #142+...+#159+本 β PR2)。
- 2026-05-27: ADR-0074 起票 (= sprint α plan sprint 完了 + Annex α plan v1 draft literal + Codex Rescue plan review 5 必須軸投入準備) = Draft、 起票者: 越川将人 (= 主軸 Claude Code 経由)、 PR1 doc-only sprint = ADR-0065 δ preflight v2 (= 2026-05-27 43rd session 末) で発覚した infrastructure issue (= PMDDOTNET_MML build artifact は ROM 内に存在するが MAME runtime では song_table[0] = test01.mml が再生されていた = ADR-0058 §決定 1 mandate「A-J test01 default、 K + L-Q のみ PMDDOTNET」 carry confirmed) repair plan、 base anchor `wip-pmddotnet-opnb-extension@99f2d6f`、 user 明示 mandate「option A test01.mml 一時置換は採用しない (= production 経路の確認であり PMDDOTNET_MML 経路の証明にならない) + option B K/L-Q 限定は FM/SSG preflight に不足 + option C 相当 runtime selection path repair を plan 化 + doc-only plan / touch 範囲 / rollback / sha256 影響 / 既存 ADR wording 影響整理 + ADR-0058 §決定 1 mandate 衝突明示 + user audition / δ session 進めない + ADR-0072/0073 wording 訂正・撤回 user 判断なしに行わない」 mandate 経路。 touch 範囲候補 4 件比較 (= candidate 1 song_table 拡張 / candidate 2 driver cmd handler 改修 / candidate 3 build-poc.sh + song_data.inc 動的拡張 / candidate 4 preflight 専用 build mode `TEST_MODE_PMDDOTNET_SONG_SELECT` flag) + 推奨 path = candidate 4 (= flag=0 default で production binary 完全不変 + flag=1 で song_table 拡張 + main.c PMDNEO_SONG=2 起動 + ADR-0058 §決定 1 mandate 例外条件 = 整合 path、 既存 TEST_MODE_AXIS_G_INT / TEST_MODE_MUTE_FIXTURE precedent 同形)、 sub-sprint chain α/β/γ/δ/ε 5 段 plan (= ADR-0073 precedent literal 継承)、 rollback condition = ADR-0073 §決定 6 18 condition 継承 + ADR-0074 固有 #19 ADR-0058 §決定 1 mandate 根本衝突 finding + #20 production sha256 mandate 違反 risk + #21 ADR-0072/0073 ε wording 訂正・撤回 main agent 自走 risk literal、 Codex Rescue plan review 5 必須軸 (= user 明示 mandate literal carry) = (1) PMDDOTNET_MML 指定 fixture runtime 起動設計妥当性 + (2) test01.mml 混入機械的排除 + (3) WAV + trace で「この WAV はこの fixture 由来」 機械的証明 + (4) ADR-0058 §決定 1 衝突明示 + (5) user audition / δ session に勝手に進んでいないか、 review-only mandate 6 件 literal、 後続 = sprint β = Codex Rescue plan review chain + plan iteration + touch 範囲確定、 sprint γ = 実装 user 明示 GO 必須、 ADR-0072/0073 ε wording 訂正・撤回 = ADR-0074 ε Accepted 後 user 判断仰ぐ (= 本 ADR-0074 では訂正・撤回しない mandate carry)。

## 平易要約

### sprint α PR1 context section (= 2026-05-27 43rd session、 ADR-0074 起票 plan sprint)

#### やりたいこと

PMDDOTNET_MML で指定した MML を、 MAME runtime で本当に起動できる経路を作る plan を立てる。 今は build artifact に MML が入っていても、 runtime では test01.mml が再生されていた。 これを解かないと、 ADR-0065 δ preflight も ADR-0072/0073 の runtime verify も「指定 fixture 由来」 と証明できない。 本 sprint α は plan のみ、 実装はしない。

#### 前提

- ADR-0073 ε Accepted 完走済 (= PR #158 MERGED at `d33166f`) = 「PMDNEO driver FM volume scaling semantics repair 完了」 wording 解禁、 ただし test01.mml 経路 audio measurement だった可能性 = user judgment scope
- ADR-0058 §決定 1 mandate「A-J は全 build mode で default 固定、 PMDDOTNET_MML 経路でも MML 関与は K + L-Q のみ」 literal carry
- production sha256 `b15883fe...` 維持 mandate carry
- ADR-0065 δ preflight / δ session / candidate 評価 / user audition は本 ADR-0074 完走後の user 判断軸

#### やったこと

1. infrastructure issue (= test01.mml 混入) を機械的に切り分け確定
2. touch 範囲 candidate 4 件比較 (= 1 song_table 拡張 / 2 driver cmd 改修 / 3 build infra 動的拡張 / 4 preflight 専用 build mode)
3. 推奨 path = candidate 4 = `TEST_MODE_PMDDOTNET_SONG_SELECT` flag 導入 (= 既存 TEST_MODE_AXIS_G_INT precedent 同形)
4. sub-sprint chain α/β/γ/δ/ε 5 段 plan (= ADR-0073 precedent 継承)
5. rollback condition (= 18 condition + #19/#20/#21 ADR-0074 固有)
6. ADR-0058 §決定 1 mandate 衝突明示 + 整合 path 提案 (= preflight 例外条件)
7. 既存 ADR-0072/0073 ε wording 影響整理 (= user judgment scope mandate carry)
8. Codex Rescue plan review 5 必須軸 (= user 明示 mandate literal carry)
9. ADR doc 起票 (= 平易 3 軸先頭 + 8 決定 + Annex α plan v1 + 改訂履歴 + 平易要約)
10. dashboard 0074 行 add

#### 結果

ADR-0074 sprint α plan sprint 起票 Draft 完了 = touch 範囲候補比較 + 推奨 path (= candidate 4) + rollback + sha256 維持戦略 + ADR-0058 §決定 1 衝突明示 + 既存 ADR wording 影響整理 + Codex Rescue 5 必須軸 literal 固定。

#### 解釈

- ADR-0073 ε Accepted 後、 ADR-0065 δ preflight 再開試行で **infrastructure issue (= PMDDOTNET_MML runtime selection path 不在)** が発覚
- 解決 path = candidate 4 (= preflight 専用 build mode flag) で **production binary 不変 + flag=1 preflight build で PMDDOTNET 経路 runtime 起動可能** = ADR-0058 §決定 1 mandate carry + 例外条件として整合
- ADR-0072/0073 ε wording 訂正・撤回判断は **user judgment scope** = 本 ADR-0074 では訂正・撤回しない、 ADR-0074 ε Accepted 後に user に再評価判断仰ぐ

#### 次

- 本 PR1 = doc-only 起票 → Codex Rescue plan review 5 必須軸投入 → approve loop → main agent 経路 merge (= atomic 1 セット規律 17 回目適用予定 = PR #142+...+#158+本 ε PR)
- sprint β = plan iteration + Codex Rescue plan review chain + touch 範囲確定 (= candidate 4 詳細化 or 他案検討)
- **sprint γ 着手 = user 明示 GO mandatory** (= ADR-0058 §決定 1 mandate 衝突 risk + sha256 維持戦略確定 + 設計判断軸 = ADR-0041 §決定 5 escalation)
- sprint δ = runtime functional verify = staggered fixture が runtime 再生される機械的証明
- sprint ε = Accepted milestone + 「PMDDOTNET_MML runtime selection path repair 完了」 wording 解禁 (= 併記必須 mandatory) + ADR-0072/0073 ε wording 訂正・撤回 = user 判断軸

#### 重要 insight (= 本 sprint α 確立)

1. ADR-0058 §決定 1 mandate は production binary level で **正しく機能している** (= A-J test01 default literal carry)、 ただし PMDDOTNET_MML 経路 runtime selection path 自体は infrastructure 上 **未整備**
2. ADR-0072/0073 ε で確立した「PMDDotNET 経路 audio verify」 は **test01.mml 経路 audio measurement** だった可能性 = user judgment scope = ADR-0074 ε Accepted 後再評価
3. preflight 専用 build mode (= candidate 4) は **production binary 不変 + ADR-0058 §決定 1 mandate carry + 例外条件として整合** の 3 軸両立 path = 推奨
4. user audition / δ session / aesthetic approve は本 ADR-0074 完走後の user 判断軸 = 自走しない mandate carry
