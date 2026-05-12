# ADR-0016 step 4-3-δ — fixture-driven verify (= J part note → reg 0x19/0x1A + wav に意図的差分)

	位置付け: ADR-0016 step 4-3 sub-commit δ (= note differentiation を 2 件 fixture で実証)
	書き手: Claude Code
	状態: 4-3-δ PASS (= 「J part body が ADPCM-B pitch を制御している」 finally 証明)
	関連 commit: 4-3-α `32390cf` / 4-3-β `58833c0` / 4-3-γ `76e4c76`

---

## 0. 目的

4-3-γ で完成した note → delta-N table 経路が、 異なる J part body から異なる chip register
値を生成することを 2 件 fixture で実証する。 4-2 / 4-3 の累積課題:

> 「J part body の note 差分が ymfm-trace + wav に意図的反映」

を初めて成立させる。

## 1. 改修内容

### 1-1. 新規 fixture: `src/test-fixtures/step4/j-part-g.mml`

```
J  o4 l1 g
```

j-part-minimum.mml (= `o4 l1 c`) と FM voice 等のヘッダ部分は完全同一、 J part 行のみ
`c` → `g` (= chromatic +7 semitone) に差し替え。 同じ compile.py を経由して .mn を
生成。

### 1-2. 新規 verify script: `src/test-fixtures/step4/verify-j-part-fixture-driven.sh`

2 件 fixture で build + trace + wav 取得、 reg 0x19/0x1A の値と wav sha256 を自動 verify。
exit code 0 = PASS。 CI 化候補 (= 別 sprint)。

## 2. 期待 register 値 (= chromatic table 由来)

`adpcmb_deltan_chromatic` table (= 4-3-γ 実装) 由来の expected:

| fixture | note byte | low nibble | table[idx] | reg 0x19 LSB | reg 0x1A MSB |
|---|---|---|---|---|---|
| j-part-minimum.mml (= `o4 c`) | 0x40 | 0 | 0x6E96 | **0x96** | **0x6E** |
| j-part-g.mml (= `o4 g`) | 0x47 | 7 | 0xA5B1 | **0xB1** | **0xA5** |

high nibble はどちらも 4 (= 0x40-0x4F)、 octave shift 0 で table 値そのまま。

## 3. 観測結果

### 3-1. compile.py 出力 .mn

| fixture | J part .mn (hex dump) |
|---|---|
| j-part-minimum.mml | `40 80 80` (= note 0x40 + duration 0x80 + end 0x80) |
| j-part-g.mml | `47 80 80` (= note 0x47 + 同上) |

✅ compile.py が note 差分を正しく emit。

### 3-2. ADPCM-B writes 全 20 件 比較 (= ROM_Bc vs ROM_Bg)

| idx | reg | ROM_Bc (= o4 c) val | ROM_Bg (= o4 g) val | 差分 | 期待 |
|---|---|---|---|---|---|
| 103-110 (= init mute) | 0x10/0x1B/0x11-0x15 | 全件 0x01/0x00 等 | 全件 同一 | 一致 | 一致 (= init 共通) |
| 249 | 0x10 (= clear keyon) | 0x00 | 0x00 | 一致 | 一致 |
| 250 | 0x12 (= sample start LSB) | 0x2A | 0x2A | 一致 | 一致 (= beat fixed) |
| 251 | 0x13 (= sample start MSB) | 0x00 | 0x00 | 一致 | 一致 |
| 252 | 0x14 (= sample stop LSB) | 0xA8 | 0xA8 | 一致 | 一致 (= beat fixed) |
| 253 | 0x15 (= sample stop MSB) | 0x00 | 0x00 | 一致 | 一致 |
| **254** | **0x19 (= delta-N LSB)** | **0x96** | **0xB1** | **差分** | **table 由来 ✅** |
| **255** | **0x1A (= delta-N MSB)** | **0x6E** | **0xA5** | **差分** | **table 由来 ✅** |
| 256 | 0x1B (= vol) | 0xFF | 0xFF | 一致 | 一致 (= vol max fixed) |
| 257 | 0x11 (= pan) | 0xC0 | 0xC0 | 一致 | 一致 (= pan both fixed) |
| 258 | 0x10 (= keyon trigger) | 0x80 | 0x80 | 一致 | 一致 |
| 1624-1625 (= retrigger) | 0x10 | 0x01 / 0x00 | 同上 | 一致 | 一致 |

**18 件一致 + 2 件意図的差分**。 差分は reg 0x19/0x1A (= delta-N) のみ。 設計通り。

### 3-3. wav sha256

| ROM | sha256 |
|---|---|
| ROM_Bc (= o4 c) | `b542cd92426c04521350c3cb492082d5f14fa119ec5b7d542b1945720fb6bd4d` |
| ROM_Bg (= o4 g) | `5f194cd41dd27f8d9eb77fd0a98f06f6f49b423b67f327d19f451ea360544295` |

wav 異なる ✅。 chip register 値が実際に違うので、 これは **timing artifact ではない真の差分**。
beat.wav sample 自体は同じだが、 delta-N が 0x6E96 → 0xA5B1 (= 約 1.498 倍) で再生され、
playback rate が約 +7 semitone (= 完全 5 度) 高くなる。

### 3-4. verify script 自動実行

```
🎉 ADR-0016 step 4-3-δ fixture-driven verify PASS
   - reg 0x19/0x1A が J part note byte に応じた chromatic table 値
   - wav も意図的に差分 (= timing artifact ではない pitch 差)
```

exit code 0、 expected vs observed 全件一致。

## 4. gate 評価

| user 指示 4-3-δ gate | 結果 |
|---|---|
| 別 note fixture 追加 | ✅ PASS (= j-part-g.mml) |
| reg 0x19/0x1A 差分 | ✅ PASS (= 0x96/0x6E vs 0xB1/0xA5、 chromatic[0] vs chromatic[7] 完全一致) |
| wav 差分 (= timing artifact ではない) | ✅ PASS (= b542cd92 vs 5f194cd4、 chip output 由来) |
| fixture-driven verify 完成 | ✅ PASS (= verify-j-part-fixture-driven.sh 自動 PASS) |

## 5. 含意 + 4-3 sprint 完了

### 含意

- ADR-0016 step 4-3 の本旨 (= 「fixture-driven ADPCM-B」 経路成立) が **完全達成**
- J part body の MML 表記が driver の chip register 操作に **真に反映** されている
- α (= dispatch correction) + β (= note 引渡し) + γ (= note → delta-N) + δ (= verify) の積み上げで:
  - cmd 0x05 → init_mml_song → song_main → part_main → keyon_hook → keyon → reg 0x19/0x1A の chain が **note-driven** で動作
  - 同 chain で sample addr / vol / pan は固定維持 (= 設計通り、 1 sample fixed)
- 設計判断 (= 案 A) も帰結としての design 整合性が確認できた:
  - o4 c (= note 0x40) → beat.wav natural rate (= 0x6E96)
  - chromatic 上昇で delta-N も正しく上昇
  - octave shift logic は本 fixture では shift 0 のみ通った、 octave 違い fixture (= o5 c 等)
    は 4-3-ε 候補

### 4-3 sprint 完了判定

| sub-commit | 状態 |
|---|---|
| α (= main.c cmd 0x05 revert) | ✅ 完了 (`32390cf`) |
| β (= adpcmb_keyon_hook 引数化) | ✅ 完了 (`58833c0`) |
| γ (= adpcmb_keyon refactor + table 追加) | ✅ 完了 (`76e4c76`) |
| δ (= fixture-driven verify) | ✅ 完了 (本 commit) |
| ε (= sample table 設計 / 不要判断) | 4-3 完了判断後に user 判断 |

ε は ADR-0016 §決定 3 step 4-3 完了判定の **scope outside** とする選択肢あり。 4-3-δ
完了で「J part body → ADPCM-B pitch 制御」 という本旨は達成済。 sample table (= 複数 sample
切替) は ADPCM-A 6ch sprint (= 4-3-ε 候補から push) でも自然に扱える。

### 4-3 完了の意義 (= ADR-0016 step 4 全体への含意)

- step 4 (= SubE / ADPCM-B 本実装) の **driver 側 fixture-driven verify が成立**
- 4-1 (= ADPCMB_DRV.inc 実装) + 4-2 (= register write 観測 gate) + 4-3 (= fixture-driven)
  の累積で SubE の核心経路が driver 内で動く
- ADR-0013 D1 路線基盤 (= 同 .M 2 経路比較) との接続は 4-3-ε もしくは step 5 で再評価

## 6. 4-3-ε 候補 (= user 判断)

選択肢:

### option α: 4-3-ε で sample table 設計
- 複数 sample (= e.g. drum + melodic) を切替える設計を追加
- ADPCM-B 1 ch では sample 切替は keyon 直前の sample addr write で実現可能
- ただし当面 1 sample fixed で大半の MML が成立、 設計負債のみ増える risk

### option β: 4-3-ε を skip、 step 5 (= ADPCM-A 6ch) へ進む (Recommended)
- 4-3-δ 完了で「J part body → ADPCM-B pitch」 本旨は達成済
- sample table 設計は ADPCM-A 6ch (= sample 切替が本旨) で自然に扱える
- step 5 着手で ADR-0016 §完了判定 (= ADPCM-A 6ch 使用 .MN 楽曲 MAME 再生) に近づく

### option γ: 4-3 完了宣言 + 別 sprint で octave verification
- octave shift logic (= adpcmb_note_to_deltan 内 shift loop) は本 fixture では未通過
- o5 c (= note byte 0x50) fixture で shift 1 (= ×2) を実証する別 micro-sprint

## 7. 関連

- ADR-0016 §決定 3 step 4 (= SubE / ADPCM-B 本実装)
- `docs/design/handoff/adr-0016-step4-3-alpha-findings.md` (= α、 cmd revert)
- `docs/design/handoff/adr-0016-step4-3-beta-findings.md` (= β、 note 引渡し)
- `docs/design/handoff/adr-0016-step4-3-gamma-findings.md` (= γ、 note → delta-N)
- standalone_test.s `adpcmb_keyon` / `adpcmb_note_to_deltan` / `adpcmb_deltan_chromatic`
- memory `feedback_refactor_gate_register_trace_not_wav.md` (= 4-3-β/γ で適用)
- memory `feedback_post_commit_push_report_format.md` (= commit 後報告書式)
- fixture: `src/test-fixtures/step4/j-part-minimum.mml` (= o4 c)
- fixture: `src/test-fixtures/step4/j-part-g.mml` (= o4 g、 本 commit 新規)
- verify script: `src/test-fixtures/step4/verify-j-part-fixture-driven.sh` (= 本 commit 新規)
