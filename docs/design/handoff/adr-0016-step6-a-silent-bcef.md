# ADR-0016 / ADR-0020 step 6-a handoff: silent BCEF fixture (= audio isolation)

- 状態: **完了** (= 2026-05-13 7th session)
- 関連 ADR: ADR-0020 §決定 2 (= silent-bcef fixture first choice)、 ADR-0016 (= 改造実装 sprint 作業計画、 step 6 = 検証 infra 強化)
- 関連 commit: (= 本 doc + fixture + verify script を含む 6-a 1 commit、 SHA は commit 直前に付記予定)

## 目的

step 5 ε-c で残った FM 同居 audio finding (= L-Q ADPCM-A 6 ch + BCEF FM 並走) を解消する。 ADR-0020 §決定 2 に基づき、 driver source 不変のまま `MML_INPUTS` 差替経路で BCEF FM stream を empty 化、 L-Q ADPCM-A だけが鳴る試聴環境を成立させる。

## 追加 file

| file | 目的 | 行数 |
|---|---|---|
| `src/test-fixtures/step6/silent-bcef.mml` | A-J empty fixture (= BCEF chord を消す default MML 代替) | 25 行 |
| `src/test-fixtures/step6/verify-silent-bcef-audio-isolation.sh` | 7 段階 trace gate verify script (= ε-b 6 gate + gate F) | 約 220 行 |

driver source 変更なし。 build infra (= `scripts/build-poc.sh`) も変更なし (= 既存 `MML_INPUTS` env var 経路を使うのみ)。

## fixture 設計

`silent-bcef.mml`:

- FM ch 1-6 (= A-F) を `;silent` コメント付き empty part 化 (= test02.mml `J ;empty` 流儀踏襲)
- SSG ch 1-3 (= G/H/I) を `V0` で明示的 silent
- ADPCM-B (= J) を `;empty` で empty
- K (Rhythm) / L-Q / X/Y/Z は記載なし → `compile.py` default `[0x80]` (= EOM のみ)

`compile.py` の挙動確認:

- `parts[part] = compiler.compile_part(line[1:], line_no)` で empty body は `[0x80]` (= EOM marker) のみ生成
- `parts.get(part, [0x80])` で未記載 part も `[0x80]` 既定
- 結果: song_table 全 part stream が即終了 (= keyon 命令 0 件期待)

## verify script 設計

`verify-silent-bcef-audio-isolation.sh` は ε-b script を template に gate F を追加した 7 段階構成:

| gate | 内容 | 期待 |
|---|---|---|
| 1 | silent-bcef + l-q-rhythm-song build + trace | wav 生成 + Z80/ymfm trace 取得 |
| **F** | FM keyon (= reg 0x28 高 nibble = F) | **0 件** (= silent BCEF 主目的) |
| 2 | 6 ch ADPCM-A workarea voice idx 独立 | voice 0-5 各 ch 独立 |
| 3 | 6 ch ADPCM-A sample addr 全 unique | bd/sd/hh/tom/rim/top 6 種 |
| 4 | 6 ch ADPCM-A vol/pan (= reg 0x08+ch) | 各 ch v cmd 由来 |
| 5 | 6 ch ADPCM-A simultaneous + rhythm keyon | 8/8/16/4/2/1 = 39 件 |
| 6 | 5 reg group × 6 ch register isolation | 全 30 reg write |

gate F は本 6-a で新規追加。 gate 2-6 は ε-b と完全同等 (= rhythm song 動作不変を保証)。

primary gate = ymfm-trace / z80-mem-trace。 wav sha256 は human listening reference。

## 検証結果 (= 2026-05-13 7th session)

### trace gate 結果

全 7 gate PASS:

```
gate 1: ✅ build + trace 取得 (wav: 2611716cc0ab824e...)
gate F: ✅ FM keyon (= reg 0x28 高 nibble = F) = 0 件
gate 2: ✅ 6 ch workarea voice idx 0-5 独立
gate 3: ✅ 6 ch sample addr 0x00/04/07/0C/0A/12 全 unique
gate 4: ✅ 6 ch vol/pan reg 0x08+ch 0xDF/5F/98/50/D8/9F
gate 5: ✅ 6 ch simultaneous keyon 8/8/16/4/2/1 = 39 件
gate 6: ✅ 5 reg group × 6 ch isolation
```

wav sha256 (= reference): `2611716cc0ab824e20a46cecab5d1b72ab9cf166ef45240253f50713ce98ba4f`

### audio gate 結果 (= human listening reference)

user 実機試聴 (= `afplay /tmp/pmdneo-trace/audio.wav`) で:

- ✅ ADPCM-A L-Q 6 音 (= bd/sd/hh/tom/rim/top) のみ audible
- ✅ FM chord 進行 (= test01/02 由来 C major chord) 消失
- ✅ 「FM の音だけ消えて ADPCM-A のシーケンスだけになった」 を user 確認

human listening は trace gate と独立軸の audio gate として位置付け (= ADR-0020 §決定 4)。

### 補助 finding

- `FM keyoff = 0 件` も検出 (= 参考)
- 解釈: `standalone_test.s:1177` の silence_all_chips 経路も silent-bcef では実行されない (= ROM 起動 → driver init → ADPCM-A 即動作)
- 本 6-a の主目的 (= FM keyon 0 件) は別軸。 silence_all_chips 経路追跡は別 sprint
- ε-b 39 keyon 件数完全一致 (= 8/8/16/4/2/1 = 39) — silent BCEF が L-Q dispatch を阻害していない証拠

## 6-b 着手判断

**6-b PMDNEO_MUTE_FM driver flag は不要 (= scope-out のまま)**。

理由:
- 6-a audio gate で「FM の音だけ消えた」 = silent fixture で十分
- FM register init 余韻 (= TL/ALG 設定だけでも click や hiss 等) は感じられず
- ADR-0020 §決定 3 (= 6-a 結果次第で 6-b 判断) に従い、 6-b は scope-out 留保

将来 6-b 着手判断条件:
- driver source 変更を伴う FM 完全 silence (= TL/ALG/PAN init 自体 skip) が必要になった場合
- 別 sprint で起票

## 完了判定達成状況 (= ADR-0020 §6-a 完了判定)

| # | 項目 | 達成 |
|---|---|---|
| 1 | `src/test-fixtures/step6/silent-bcef.mml` 追加 + commit + push | ✅ (= 本 commit 予定) |
| 2 | 6-a verify script で MML_INPUTS 差替経路成立 | ✅ |
| 3 | trace 上で FM keyon (= reg 0x28) 0 件 | ✅ |
| 4 | ADPCM-A L-Q reg write は ε-b verify 同等 PASS | ✅ |
| 5 | MAME / wav で ADPCM-A L-Q 6 音 audible 確認 | ✅ |
| 6 | 6-a handoff doc 作成 + commit + push | ✅ (= 本 doc + 同 commit 予定) |
| 7 | step 6 完了統合 handoff doc + ADR-0020 Accepted 移行 | ⏳ (= 次 commit) |

→ 6-a 完了判定 6/7 項目達成 (= 残 1 は次 commit で完了)。

## 関連 memory

- `project_pmdneo_step5_complete.md` (= step 5 ε-c FM 同居 finding 残置)
- `feedback_audio_gate_solo_isolation.md` (= 聴感 gate で対象音源を solo 化)
- `feedback_refactor_gate_register_trace_not_wav.md` (= primary gate = register trace)

## 次

1. **6-a 1 commit + 1 push** (= 本 doc + silent-bcef.mml + verify script、 driver 不変なので動作確認義務対象外)
2. **step 6 完了統合 handoff doc** 作成 (= `docs/design/handoff/adr-0016-step6-completion.md`)
3. **ADR-0020 Proposed → Accepted 移行** + ADR-0016 step 6 章末追記
4. step 6 完了統合 1 commit + 1 push
5. **step 7 候補** (= ADR-0019 ε-c handoff future scope-out のうち未消化): `.PNE` parser / K-R compat / nullsound integration 再検討 等
