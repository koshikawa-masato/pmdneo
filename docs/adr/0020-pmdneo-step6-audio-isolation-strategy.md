# ADR-0020: PMDNEO step 6 standalone audio isolation 戦略 (= 6-a fixture / 6-b driver flag)

- 状態: **Accepted** (= 2026-05-13 7th session、 6-a 完了で Accepted 移行、 6-b は scope-out 留保のまま完了)
- 起票日: 2026-05-13
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0016 (= 改造実装 sprint 作業計画、 step 6 = 検証 infra 強化)、 ADR-0019 (= step 5 ADPCM-A 6ch 設計判断、 ε-c で FM 同居 audio finding を残置)

## 背景

step 5 ε-c 完了 (= 2026-05-12 6th session、 commit `62faf8f`) で ADPCM-A 6ch native path が成立した。 ただし step 5 最終再生で「ADPCM-A 6 音が確認できたが FM 音も混在していた」 という finding が残り、 ε-b integration verify script でも以下のように明示されている:

```
echo "   wav sha256 (= 参考、 FM 同居で primary gate にしない):"
```

step 6 では trace primary gate を維持しつつ、 **「対象音源 (= ADPCM-A L-Q) だけを聴ける状態」 を成立** させる。 これは driver 機能拡張ではなく **検証 feedback loop の品質改善** であり、 後続 sprint (= `.PNE` parser / K-R compat / nullsound integration / future FM-Towns mode) の verify 地ならしとして位置付ける。

CLAUDE.md §設計書ファースト「実装に入る前に必ず設計書で仕様を文書として固定」 + 「動いているものを壊さない」 + 「scope-out を守る」 + 「future mode を混ぜすぎない」 を遵守し、 step 6 着手前に audio isolation 戦略を ADR として独立起票する。

### FM 同居 audio finding の整理 (= 7th session 冒頭調査)

7th session 開始時の root cause 調査で以下が確認された:

1. `scripts/build-poc.sh` の default は `MML_INPUTS=test01.mml,test02.mml`
2. `test01.mml` / `test02.mml` は **B C E F (= FM ch 2/3/5/6) の chord 進行** を含む
3. `compile.py` が test01/test02 を `song_data.inc` の `song_table` (= A-Q + X/Y/Z 20 stream) に compile
4. `src/driver/standalone_test.s:1336-1488` の init コードが **`PMDNEO_USE_PMDDOTNET` の値に関わらず**、 song_table idx 1-5 (= B-F) の FM 部分を `load_song_part_addr` + `pmdneo5_init_part` で常に dispatch
5. ε-b integration verify で `PMDDOTNET_MML=l-q-rhythm-song.mml` `PMDNEO_USE_PMDDOTNET=1` を指定しても、 default `MML_INPUTS` の test01/test02 由来 BCEF FM 部分は併走再生される

つまり **L-Q 経路 (= `.MN` direct) と BCEF 経路 (= compile.py + song_table) が並列ライブで重なっている**。 これは step 5 で意図された設計 (= legacy 経路を壊さず併存) の結果であり、 driver bug ではない。 step 6 で「聴感上 L-Q を solo 化する」 ための追加 layer が必要。

#### 重要前提: FM coexist は bug ではなく retain + refactor 設計の自然な結果

step 5 最終段階で「FM が混ざる = regression ではないか」 と誤解しかけた経緯がある。 結論として **FM coexist は driver bug でも regression でもない**:

- ADR-0019 §決定 1 (= retain + refactor) により、 legacy compile.py + song_table 経路は **意図的に温存**
- ADR-0019 §決定 4 (= 段階的 file 境界) で `.MN` direct path は legacy 経路と並存させる方針
- 結果として「compile.py + song_table legacy path」 と「.MN direct L-Q path」 が **二系統並走で同時 dispatch** される
- これは bug ではなく retain + refactor 設計の自然な帰結

step 6 (= audio isolation sprint) は **bug fix ではなく検証明瞭化** が目的。 future contributor が FM coexist を regression と誤解しないよう、 本 ADR にこの整理を明示的に残す。

## 決定

### 決定 1: 段階導入 = α + β の 2 sub-sprint

step 6 を **6-a (= silent-bcef fixture) + 6-b (= PMDNEO_MUTE_FM driver flag、 条件付き留保)** の 2 sub-sprint 構造で進める。

**理由**:

- 6-a (= MML 差替) は driver 不変、 scope 最小、 「動いているものを壊さない」 原則と整合
- 6-a で聴感上の isolation が十分なら 6-b は不要 (= over-engineering 回避)
- 6-a で不十分 (= FM register write を完全に消したい等) なら 6-b で driver flag を追加
- 1 sub = 1 commit + 1 push 規律 (= `feedback_push_per_commit` / `feedback_post_commit_push_report_format`) に乗る
- ADR-0019 §決定 1 retain + refactor 規律踏襲 (= 動いている資産 = legacy compile.py 経路 / test01.mml / test02.mml を壊さない)

### 決定 2: silent-bcef fixture を first choice

6-a では `src/test-fixtures/step6/silent-bcef.mml` を新規追加、 B C E F (= FM ch 2/3/5/6) を empty part として記述する。 verify script で `MML_INPUTS=silent-bcef.mml` を指定し、 default test01.mml + test02.mml の代わりに silent-bcef.mml を `compile.py` 入力にする。

**理由**:

- driver source 完全不変 (= ADR-0019 §決定 1 retain + refactor 規律)
- compile.py / build-poc.sh / `MML_INPUTS` env var path は既に存在 (= `scripts/build-poc.sh:91`)、 新規 build infra 不要
- song_table dispatch は走るが empty stream を読捨 (= FM keyon は 0 件期待)
- trivial verify risk 低 (= fixture 内容と trace 結果が直接比較可能)
- 検証戦略は step 5 fixture-driven 規律踏襲

**fixture 構造案**:

```mml
#Title          step 6-a silent BCEF fixture (= audio isolation 用 default MML 代替)
#Composer       M.Koshikawa.
#Memo           B/C/E/F (= FM ch 2/3/5/6) を empty part 化、 ADPCM-A L-Q solo 試聴用
                song_table dispatch は走るが FM keyon 0 件期待。

; FM ch 2/3/5/6 = empty part (= note 命令なし、 stream 即終了)
B
C
E
F

; SSG / ADPCM-B / Rhythm / FM3Extend は既存 default 通り (= silent or noop)
G V0
H V0
I V0
J
```

完了条件 (= 6-a):

1. `src/test-fixtures/step6/silent-bcef.mml` 追加
2. verify script で `MML_INPUTS` 差替経路を確立
3. trace 上で FM keyon (= reg 0x28) が 0 件 (= 直前は test01.mml で複数件)
4. ADPCM-A L-Q reg write (= reg 0x00/0x08+ch/0x10-0x2D+ch) は ε-b verify 同等 PASS
5. MAME / wav で ADPCM-A L-Q 6 音を聴き取れる (= human listening reference)
6. handoff doc `docs/design/handoff/adr-0016-step6-a-silent-bcef.md` 作成

### 決定 3: PMDNEO_MUTE_FM driver flag は条件付き留保

6-b の driver flag (= `.equ PMDNEO_MUTE_FM, 1` で B-F init / playback skip) は **6-a 結果次第で必要性判断**。 6-a で聴感 isolation が十分なら 6-b は scope-out のまま温存、 不十分なら追加 sub-sprint として実装する。

**理由**:

- 6-a で「FM init は走るが note は鳴らない」 状態になる (= TL/ALG/PAN init はあるが keyon 不発)
- 完全 silence (= FM register write 自体 0 件) が必要かは 6-a 試聴で判断可能
- 先回り実装は over-engineering、 「scope-out を守る」 原則と矛盾
- 6-b 追加時の予想実装:
  - `standalone_test.s:1338-1375` (= FM B-F init) を `.if !PMDNEO_MUTE_FM` で囲む
  - `build-poc.sh` で env `PMDNEO_MUTE_FM` を sed pre-process で `.equ` 値に反映
  - verify script `PMDNEO_MUTE_FM=1` 指定経路で reg 0x40-0x4F (= TL) / reg 0xB0 (= alg/fbl) write が 0 件確認

### 決定 4: primary gate / audio gate の役割分離

step 6 でも primary gate = **register trace (= ymfm-trace / z80-mem-trace)** を維持し、 audio (= wav / MAME 再生) は **reference + human verification** として位置付ける。

**理由**:

- `feedback_refactor_gate_register_trace_not_wav` 規律踏襲 (= byte-identical trace 一致が primary、 wav は cycle 数増減で sample shift 許容)
- step 6 は「audio が聴き取りやすくなる」 ための作業だが、 客観的 PASS 判定は trace 上の数値 (= FM keyon 件数 / ADPCM-A reg write 件数) で行う
- human listening は最終確認 (= 「対象音源だけ聴ける」 体感) として実施するが、 数値 gate と独立軸
- step 5 ε-b 規律踏襲 (= wav sha256 = 参考、 primary gate は 6 段階 gate)

**運用**:

- 6-a verify script は trace primary gate を 2 件追加:
  - gate F: FM keyon (= reg 0x28、 全 channel bit 0-2 keyon 命令) が 0 件 (= test01/02 では `\d+` 件)
  - gate L-Q: ε-b 6 段階 gate 同等 PASS
- audio gate (= human listening) は handoff doc に手順を残す (= MAME 起動 / wav 再生 / 6 音 audible 確認)、 自動 PASS 判定はしない

### 決定 5: solo audio gate infrastructure は最小限

step 6 で扱う solo audio gate infrastructure は **「default fixture を silent-bcef にすればよい」 という最小限の仕組み** に留める。 future audio gate (= GUI 上の solo toggle / channel mute pad / per-chip mixer) は scope-out。

**理由**:

- 6th session 開始時の方針「動いているものを壊さない」 「future mode を混ぜすぎない」 と整合
- WebApp UI / preview 系の音源 solo 機構は Phase 3 完了後 Phase 4 領域
- 7 candidate (= ADR-0019 ε-c handoff future scope-out) のうち C (= audio isolation infra) は driver 検証品質向上の意味合いで採用、 GUI 統合は別 sprint

**運用**:

- 6-a で確立する silent-bcef fixture を `scripts/build-poc.sh` default 候補に **しない** (= test01.mml + test02.mml の chord 進行 demo は legacy として温存)
- verify script で MML_INPUTS 差替を明示する経路のみ追加
- WebApp UI mute toggle / per-chip mixer は Phase 4 で扱う

### 決定 6: handoff doc 構造

step 6 の handoff doc は 6-a / 6-b それぞれ独立、 step 6 完了統合は別 doc。

| 段階 | 文書 | 内容 |
|---|---|---|
| 6-a | `docs/design/handoff/adr-0016-step6-a-silent-bcef.md` | silent-bcef fixture 仕様 + verify 手順 + trace 結果 + human listening 結果 |
| 6-b (条件付き) | `docs/design/handoff/adr-0016-step6-b-mute-fm-flag.md` | PMDNEO_MUTE_FM 実装 (= 必要時のみ) |
| 完了 | `docs/design/handoff/adr-0016-step6-completion.md` | step 6 統合 sum-up + ADR-0020 Accepted 移行 |

## scope-in / scope-out 明示

### scope-in (= step 6 本 sprint 範囲)

- `src/test-fixtures/step6/silent-bcef.mml` 追加 (= 6-a)
- 6-a 用 verify script (= `MML_INPUTS=silent-bcef.mml` 差替 + FM keyon 0 件 gate + ADPCM-A L-Q gate)
- 6-a handoff doc
- step 6 完了統合 handoff doc
- ADR-0020 Proposed → Accepted 移行 (= 6-a 完了時)
- **条件付き**: PMDNEO_MUTE_FM driver flag (= 6-b、 6-a 結果次第)

### scope-out (= step 6 範囲外、 後続 sprint で扱う)

- `.PNE` parser driver 実装 (= ADR-0019 §決定 3 接続点予約、 別 sprint)
- K/R rhythm compatibility 現役接続 (= ADR-0019 §決定 2 micro-sprint 候補)
- PMDNEO.s + nullsound integration (= 大規模 sprint)
- PPZ compatibility mode
- FM-Towns-style rhythm mode
- WebApp UI 上の solo toggle / mute pad / per-chip mixer (= Phase 4)
- ADPCMA_DRV.inc routine refactor 移動 (= ADR-0019 §決定 4 ε 完了後判断、 別 refactor sprint)

## 完了判定

### 6-a 完了判定 (= ADR-0020 Accepted 移行条件)

1. `src/test-fixtures/step6/silent-bcef.mml` 追加 + commit + push
2. 6-a verify script で MML_INPUTS 差替経路成立
3. trace 上で FM keyon (= reg 0x28) 0 件
4. ADPCM-A L-Q reg write は ε-b verify 同等 PASS
5. MAME 起動 / wav 再生で ADPCM-A L-Q 6 音 audible 確認 (= human listening reference)
6. 6-a handoff doc 作成 + commit + push
7. step 6 完了統合 handoff doc 作成 + ADR-0020 Accepted 移行 + commit + push

### 6-b 着手判定 (= 6-a 完了後の条件付き判断)

- 6-a 試聴で「FM register init の余韻 (= TL/ALG 設定だけでも click や hiss 等) が無視できない」 場合のみ 6-b 着手
- 6-b 着手時は driver source 変更を伴うため、 CLAUDE.md §動作確認義務 (= MAME 再生確認) を遵守
- 6-b 完了判定は別途追記

### 完了判定達成状況 (= 2026-05-13 7th session、 step 6-a + 完了統合)

| # | 項目 | 達成 | 関連 commit |
|---|---|---|---|
| 1 | silent-bcef.mml 追加 | ✅ | `6983234` |
| 2 | 6-a verify script で MML_INPUTS 差替経路成立 | ✅ | `6983234` |
| 3 | trace 上で FM keyon (= reg 0x28) 0 件 | ✅ | `6983234` (= verify run 結果) |
| 4 | ADPCM-A L-Q reg write は ε-b verify 同等 PASS | ✅ | `6983234` (= gate 2-6 全 PASS) |
| 5 | MAME / wav で ADPCM-A L-Q 6 音 audible 確認 | ✅ | `6983234` (= user 試聴で「FM の音だけ消えて ADPCM-A シーケンスだけになった」 確認) |
| 6 | 6-a handoff doc 作成 | ✅ | `6983234` (= `docs/design/handoff/adr-0016-step6-a-silent-bcef.md`) |
| 7 | step 6 完了統合 handoff doc + ADR-0020 Accepted 移行 | ✅ | 本 commit (= `docs/design/handoff/adr-0016-step6-completion.md` + 本 ADR Accepted 移行) |

→ 6-a 完了判定 7/7 達成、 ADR-0020 Accepted 移行完了。

### isolation と legacy 削除の区別 (= future contributor 向け整理)

silent-bcef fixture で FM coexist audio を **isolation** したが、 **legacy compile.py path 自体は retain** されている。 「**isolation achieved ≠ legacy removed**」 を明示:

- ✅ **retain (= 削除していない)**: `compile.py` / `song_table` / BCEF FM dispatch path / `load_song_part_addr` / `pmdneo5_init_part` 経由 FM init / `song_data.inc` への compile.py 出力経路
- ✅ **isolation (= 本 step 6 で達成)**: silent-bcef fixture (= `MML_INPUTS` 差替) で BCEF stream を `[0x80]` (= EOM) のみに圧縮、 song_table dispatch は走るが note 命令 0 件
- 結果: 「FM keyon 0 件 + ADPCM-A solo audible」 を成立させつつ、 legacy path は将来 (= test01.mml / test02.mml 等の chord 進行 demo / FM 系 voice 検証 / 他 step) でも変わらず利用可能

future contributor が「step 6 で FM path / compile.py 経路を削除した」 と誤解しないよう明示。 ADR-0019 §決定 1 (= retain + refactor) 規律と完全整合。

### 6-b 判断結果 (= scope-out 留保のまま完了)

6-a audio gate で「FM の音だけ消えて ADPCM-A シーケンスだけ」 が達成され、 FM register init 余韻 (= TL/ALG 設定だけでも click や hiss) は感じられず。 **PMDNEO_MUTE_FM driver flag は不要**、 6-b は scope-out 留保のまま step 6 完了。

将来 6-b 着手判断条件:
- driver source 変更を伴う FM 完全 silence (= TL/ALG/PAN init 自体 skip) が必要になった場合
- 別 sprint で起票

### sub-sprint commit chain (= step 6 全 3 commit)

| sub | commit | 内容 |
|---|---|---|
| 起票 | `46d1228` | docs(adr): step 6 着手前に ADR-0020 起票 (= audio isolation 戦略) |
| 6-a | `6983234` | test(infra): step 6-a — silent BCEF fixture + audio isolation verify |
| 完了 | 本 commit | docs(adr): step 6 完了統合 + ADR-0020 Accepted 移行 |

## 関連 memory

- `project_pmdneo_step5_complete.md` (= step 5 完了状態、 ε-c FM 同居 finding)
- `project_adr_0016_step5_design_decision_1_retain_refactor.md` (= retain + refactor 規律)
- `project_pmdneo_phase_transition_verification_driven.md` (= 検証可能な進め方を固定しながら機能を増やす)
- `feedback_audio_gate_solo_isolation.md` (= 聴感 gate で対象音源を solo 化、 scope 外 audio で confusion を避ける)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)
- `feedback_post_commit_push_report_format.md` / `feedback_push_per_commit.md` / `feedback_explain_in_plain_japanese_before_commit.md`

## 関連 doc

- ADR-0016 §決定 6 (= 全 step 完了後の検証 infra 強化)
- ADR-0019 (= step 5 完了 + FM 同居 finding 残置)
- `docs/design/handoff/adr-0016-step5-completion.md` (= future scope-out 7 候補のうち #4 = solo 化 audio gate)
- CLAUDE.md §設計書ファースト / §動作確認義務 / §スコープ外への踏み込み禁止

## 次 sprint 候補

1. **6-a 着手** (= silent-bcef.mml 追加 + verify script + trace gate 確立、 1 commit + 1 push)
2. 6-a 完了 → handoff doc + human listening reference 確認
3. 6-b 必要性判断 (= 6-a 試聴結果次第、 必要なら 6-b 着手、 不要なら step 6 完了統合へ進む)
4. step 6 完了統合 handoff doc + ADR-0020 Accepted 移行
5. **step 7 候補** (= ADR-0019 ε-c handoff future scope-out のうち未消化): `.PNE` parser / K-R compat micro-sprint / nullsound integration 再検討 等
