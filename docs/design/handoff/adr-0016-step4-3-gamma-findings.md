# ADR-0016 step 4-3-γ — adpcmb_keyon refactor (= note → delta-N table) + 純 refactor gate PASS

	位置付け: ADR-0016 step 4-3 sub-commit γ (= note 値 → delta-N 変換経路確立、 表 + helper 関数)
	書き手: Claude Code
	状態: 4-3-γ PASS (= ymfm-trace byte-identical + code path switch 確認)、 4-3-δ で 2nd fixture 経由 differentiation
	関連 commit: 4-3-α `32390cf` / 4-3-β `58833c0`

---

## 0. 目的

`adpcmb_keyon` (= standalone_test.s) を refactor し、 J part body 由来 note 値 (= A レジスタ)
を delta-N に変換して reg 0x19 (LSB) / reg 0x1A (MSB) に書込む経路を確立する。 sample
addr (= reg 0x12-0x15) / vol (= reg 0x1B) / pan (= reg 0x11) は beat.wav 固定値を維持。

設計判断 (= 案 A 採択): note byte 0x40 (= PMD MML o4 c) → delta-N 0x6E96 (= beat.wav
natural rate 維持)。 4-3-β baseline の register write 内容が pre/post-γ で完全一致するよう
chromatic table[0] を 0x6E96 に設定。 differentiation は 4-3-δ で 2nd fixture (= 例 o4 g)
経由で実証する。

## 1. 改修内容

### 1-1. standalone_test.s `adpcmb_keyon` (旧 L2576-2578) → inline 実装

```asm
;; 旧 (= 4-3-β 時点):
adpcmb_keyon:
        call    init_adpcmb_beat        ; reg 0x10/0x12-0x15/0x19/0x1A/0x1B/0x11/0x10 全部固定
        ret

;; 新 (= 4-3-γ):
adpcmb_keyon:
        push    af                       ; save note (= A reg)
        ;; reg 0x10 = 0x00 (clear keyon)
        ;; reg 0x12-0x15 = beat.wav sample addr (= fixed、 init_adpcmb_beat と同順)
        ;; ↓ ここが本 step の本旨 (= MML 由来 delta-N)
        pop     af                       ; restore note
        call    adpcmb_note_to_deltan    ; A=note → DE=delta-N
        ld      b, #0x19
        ld      c, e
        call    ym2610_write_port_a       ; reg 0x19 = delta-N LSB
        ld      b, #0x1A
        ld      c, d
        call    ym2610_write_port_a       ; reg 0x1A = delta-N MSB
        ;; reg 0x1B = 0xFF (vol max、 fixed)
        ;; reg 0x11 = 0xC0 (pan both、 fixed)
        ;; reg 0x10 = 0x80 (keyon trigger)
        ret
```

旧 `init_adpcmb_beat` 呼出は撤去。 同 routine は cmd 0x05 非 MML mode 経路 (= L327、
TEST_MODE_CHORD != 5) で legacy 利用、 当面残置 (= 削除しない)。

### 1-2. 新規 `adpcmb_note_to_deltan` 関数

```asm
;; A = note byte (= 0x40-0x7B、 PMD 形式: high nibble = octave nibble、 low nibble = chromatic idx)
;; → DE = delta-N (= 16-bit)
;; clobbers: A、 DE
adpcmb_note_to_deltan:
        push    af / push bc / push hl
        ;; (1) chromatic table[low_nibble] → DE
        ;; (2) octave shift (= high_nibble - 4) で DE を <<= or >>= 1 ループ
        pop hl / pop bc / pop af
        ret
```

### 1-3. 新規 `adpcmb_deltan_chromatic` table

12 entry × 16-bit = 24 byte。 base C (= idx 0) = 0x6E96 (= 4-3-β baseline 維持)。 ratio
per semitone = 2^(n/12)。

| idx | semitone | hex | ratio (= 2^(n/12)) |
|---|---|---|---|
| 0 | C  | 0x6E96 | 1.000000 |
| 1 | C# | 0x7529 | 1.059463 |
| 2 | D  | 0x7C21 | 1.122462 |
| 3 | D# | 0x8382 | 1.189207 |
| 4 | E  | 0x8B54 | 1.259921 |
| 5 | F  | 0x939D | 1.334840 |
| 6 | F# | 0x9C64 | 1.414214 |
| 7 | G  | 0xA5B1 | 1.498307 |
| 8 | G# | 0xAF8B | 1.587401 |
| 9 | A  | 0xB9FC | 1.681793 |
| 10 | A# | 0xC50B | 1.781797 |
| 11 | B  | 0xD0C2 | 1.887749 |

### 1-4. octave shift logic

note byte の高 nibble (= bit 4-7) で base octave 4 からのずれを決定:

- high nibble 4 (= o4) → shift 0 (= base)
- high nibble 5 (= o5) → DE <<= 1 (= ×2)
- high nibble 6 (= o6) → DE <<= 2 (= ×4)
- high nibble 7 (= o7) → DE <<= 3 (= ×8)

(有効入力 0x40-0x7B では shift は 0 ~ +3。 negative shift 経路 (= 0x00-0x3F の defensive)
は実装しているが本 fixture では到達しない。)

## 2. 検証 setup

### 2-1. ROM_A (= test01.mml default、 Part J empty)

- build: `bash scripts/build-poc.sh`
- run: `bash scripts/run-mame.sh --headless --wavwrite --wavwrite-seconds 4 --trace`
- 保存: `/tmp/pmdneo-Agamma/`
- wav sha256: `3c1f776f76dd66647bcad04c6914822490850a4342d5dc4928a63d69a0f985d6`
- = 4-3-α (`/tmp/pmdneo-A/`) と完全一致 ✅ (= hook 未到達、 cycle 不変)

### 2-2. ROM_B (= j-part-minimum.mml + test02.mml、 Part J=`o4 l1 c`)

- build: `MML_INPUTS="/tmp/j-part-minimum.mml,test02.mml" bash scripts/build-poc.sh`
- run: 同上
- 保存: `/tmp/pmdneo-Bgamma/`
- wav sha256: `b542cd92426c04521350c3cb492082d5f14fa119ec5b7d542b1945720fb6bd4d`
- = pre-γ (`3777cb57...`) と異なる ⚠️ (= cycle timing artifact、 primary gate 外)

## 3. 観測結果

### 3-1. primary gate (= ymfm-trace byte-identical)

| metric | pre-γ | post-γ | 結果 |
|---|---|---|---|
| 全 ymfm-trace lines | 2202 | 2202 | byte-identical ✅ |
| `diff` 出力 | empty (= 0 byte 差分) | byte-identical ✅ |

### 3-2. secondary gate (= ADPCM-B writes 全件一致)

20 件 ADPCM-B writes が pre/post-γ で idx + reg + val 完全一致 ✅。

主要 writes (= 全 20 件):
- idx 103-110: init mute (= reset / vol / pan / sample addr clear)、 8 件
- idx 249-258: keyon 経路 (= clear / addr / delta-N / vol / pan / start)、 10 件
- idx 1624-1625: retrigger (= reset)、 2 件

reg 0x19/0x1A (= delta-N) は idx 254/255 で:
- pre-γ: 0x96 / 0x6E (= init_adpcmb_beat 固定値)
- post-γ: 0x96 / 0x6E (= adpcmb_note_to_deltan(0x40) = 0x6E96 ← chromatic[0] × shift 0)
- **値同一、 経路は新 routine 経由** ✅

### 3-3. code path switch (= z80-mem-trace PC range 比較)

| PC range | pre-γ writes | post-γ writes | 解釈 |
|---|---|---|---|
| `init_adpcmb_beat` (0x0610-0x0656) | 20 | **0** | 旧固定経路撤去 ✅ |
| `adpcmb_keyon` body (0x0F2E-0x0F77) | 10 | 24 | inline 化で writes 増 ✅ |
| `adpcmb_note_to_deltan` (0x1063-0x10FF) | 0 | **6** | 新 helper 到達 ✅ |

`init_adpcmb_beat` 経路の writes が完全消失、 新規 `adpcmb_note_to_deltan` 経路が active
化。 同 register 値を**新 code path で生成**していることが PC range で実証。

## 4. gate 評価

| gate | 結果 |
|---|---|
| primary: ymfm-trace 2202 lines byte-identical | ✅ PASS |
| secondary: ADPCM-B 20 件 writes 全件一致 | ✅ PASS |
| ROM_A wav sha256 維持 | ✅ PASS (= hook 未到達、 instruction 改変経路通らない) |
| code path switch (= init_adpcmb_beat → adpcmb_note_to_deltan) | ✅ PASS |
| ROM_B wav sha256 (= 参考のみ、 primary gate 外) | ⚠️ 変化 (= cycle timing artifact) |

note-derived delta-N 経路確立、 同 fixture で chip register 内容も維持、 4-3-δ で
differentiation 実証準備。

## 5. 4-3-δ で予定する verify

新 fixture `j-part-g.mml` (= `J o4 l1 g`) を追加 (= note byte 0x47 期待):
- low nibble 7 → chromatic[7] = 0xA5B1
- high nibble 4 → shift 0
- result: DE = 0xA5B1 → reg 0x19 = 0xB1、 reg 0x1A = 0xA5
- pre/post 比較: o4 c (= reg 0x19/0x1A = 0x96/0x6E) と o4 g (= 0xB1/0xA5) で異なる ✅
- wav も異なる (= chip register が実際に違う、 timing artifact ではない musical pitch 差)

## 6. 含意 + 次 step 引継

### 含意

- 4-3-γ で note 値 → delta-N 経路完成 (= 新 helper + 新 table)
- 既存 fixture (= j-part-minimum.mml o4 c) では register 内容は **完全互換**、 functional
  regression 不在
- code path は `init_adpcmb_beat` 固定 → `adpcmb_note_to_deltan` 動的計算 へ切替
- 4-3-δ で 2nd fixture (= o4 g) 経由で table の他 entry が正しく機能することを実証

### 設計判断 4-3-γ-1: 案 A (= note 0x40 → 0x6E96 維持) 採択経緯

(user 2026-05-12 4-3-γ 着手時)
- 案 A: 既存 beat.wav natural rate (= 0x6E96) を o4 c の natural pitch として維持
- 案 B: round 数 0x4000 を base に (= 即時 register 差分を gate にできる)
- 案 C: 音楽的に PMD MML "o5 = MIDI C4" 整合 (= o4 c = -3 octave、 大幅 pitch 変化)

→ 案 A 採択。 理由: 4-3-γ を「純 refactor」 として位置付け、 既存音を保ちつつ内部経路だけを
note-driven に切替。 differentiation は 4-3-δ で別 fixture で行う方が安全。

### 4-3-δ への引継

- 新 fixture `j-part-g.mml` を `src/test-fixtures/step4/` に作成
- compile.py で .mn 出力 → ROM build
- ROM_B(g) で reg 0x19/0x1A = 0xB1/0xA5 (= chromatic[7] = 0xA5B1) を確認
- ROM_B(c) と ROM_B(g) で wav sha256 + ymfm-trace + register writes が differ
- これが「J part MML が ADPCM-B pitch に反映される」 finally 段階

## 7. 関連

- ADR-0016 §決定 3 step 4
- `docs/design/handoff/adr-0016-step4-2-findings.md` (= 4-2 fixture-driven 未達 finding)
- `docs/design/handoff/adr-0016-step4-3-alpha-findings.md` (= 4-3-α cmd revert)
- `docs/design/handoff/adr-0016-step4-3-beta-findings.md` (= 4-3-β note 引渡し + gate 規律確立)
- memory `feedback_refactor_gate_register_trace_not_wav.md` (= 4-3-β 確立 gate 規律、 本 step で 2 回目適用)
- memory `feedback_post_commit_push_report_format.md` (= commit 後報告書式)
- standalone_test.s `adpcmb_keyon` (= L2585 周辺) / `adpcmb_note_to_deltan` (= L2784 周辺) / `adpcmb_deltan_chromatic` (= L2823 周辺)
