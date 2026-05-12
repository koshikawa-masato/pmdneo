# ADR-0016 step 4-3-β — adpcmb_keyon_hook 引数化 + cycle timing artifact finding

	位置付け: ADR-0016 step 4-3 sub-commit β (= note 値引渡し経路確立 + refactor 系 gate 規律確立)
	書き手: Claude Code
	状態: 4-3-β PASS (= functional 不変)、 wav timing artifact finding を規律化
	関連 commit: 4-3-α `32390cf` (= cmd 0x05 revert)

---

## 0. 目的

`adpcmb_keyon_hook` (= standalone_test.s L2509-2512) の引数経路を確立する。 旧 `ld b, #0`
hardcoded から `ld a, PART_OFF_NOTE(ix)` に置換し、 MML body 由来の note 値を
`adpcmb_keyon` に渡せるようにする。 ただし `adpcmb_keyon` 本体 (L2571-2573) はまだ A
値を ignore したまま (= 4-3-γ で本格 refactor)、 4-3-β は引渡し経路の確立 + register
write 内容不変が gate。

## 1. 改修内容

`src/driver/standalone_test.s` L2509-2512 改修:

```asm
;; 旧 (4-3-α 時点):
adpcmb_keyon_hook:
        ld      b, #0           ; 2 byte / 7 T-states
        call    adpcmb_keyon
        ret

;; 新 (4-3-β):
adpcmb_keyon_hook:
        ld      a, PART_OFF_NOTE(ix)  ; 3 byte / 19 T-states (= +1 byte / +12 T-states)
        call    adpcmb_keyon
        ret
```

ハンクション意味:
- 旧: B レジスタを 0 で初期化 (= sample 番号引数想定だが ignore されていた)
- 新: A レジスタに J part body 由来 note 値 (= PMDNEO C4=0x40 系) を load

`adpcmb_keyon` (L2571-2573) 本体は不変 (= まだ A 値 ignore、 4-3-γ で delta-N 変換に
refactor 予定)。 commit-comment で経路意図を明示。

## 2. 検証 setup

### 2-1. ROM_A (= test01.mml default、 Part J empty 0x80)

build + run-mame headless + trace + wav 録音、 結果を `/tmp/pmdneo-Abeta/` に保存:

- wav sha256: `3c1f776f76dd66647bcad04c6914822490850a4342d5dc4928a63d69a0f985d6`
- = 4-3-α (= `/tmp/pmdneo-A/audio.wav`) と完全一致 ✅
- (= J body empty で adpcmb_keyon_hook 未到達、 instruction 改変箇所通らない、 cycle timing 不変)

### 2-2. ROM_B (= j-part-minimum.mml + test02.mml、 J=`o4 l1 c`)

- wav sha256: `3777cb572cd931a8f5d4924cccfd853fe83712035053e8a5a932d3a0e7c2fa2a`
- = 4-3-α 時点 (`eabb80d4...`) と **異なる** ⚠️
- 原因 = adpcmb_keyon_hook 内 instruction の cycle 数増加 (+12 T-states ≈ 3 μsec) による
  chip write timing shift

## 3. 観測結果 (= ROM_B pre/post-β 比較)

### 3-1. ymfm-trace.tsv 比較

| metric | pre-β | post-β | 結果 |
|---|---|---|---|
| 全 lines | 2202 | 2202 | byte-identical ✅ |
| `diff` | empty (= 0 bytes 差分) | byte-identical ✅ |

### 3-2. ADPCM-B (port A, reg 0x10-0x1B) writes 比較

| idx | reg | pre-β val | post-β val | 一致 |
|---|---|---|---|---|
| 103 | 0x10 | 0x01 | 0x01 | ✅ |
| 104 | 0x10 | 0x00 | 0x00 | ✅ |
| 105 | 0x1B | 0x00 | 0x00 | ✅ |
| 106 | 0x11 | 0x00 | 0x00 | ✅ |
| 107-110 | 0x12-0x15 | 0x00 ×4 | 0x00 ×4 | ✅ |
| 249 | 0x10 | 0x00 | 0x00 | ✅ |
| 250 | 0x12 | 0x2A | 0x2A | ✅ |
| 251 | 0x13 | 0x00 | 0x00 | ✅ |
| 252 | 0x14 | 0xA8 | 0xA8 | ✅ |
| 253 | 0x15 | 0x00 | 0x00 | ✅ |
| 254 | 0x19 | 0x96 | 0x96 | ✅ |
| 255 | 0x1A | 0x6E | 0x6E | ✅ |
| 256 | 0x1B | 0xFF | 0xFF | ✅ |
| 257 | 0x11 | 0xC0 | 0xC0 | ✅ |
| 258 | 0x10 | 0x80 | 0x80 | ✅ keyon |
| 1624 | 0x10 | 0x01 | 0x01 | ✅ |
| 1625 | 0x10 | 0x00 | 0x00 | ✅ |

**全 20 件で idx + reg + val が完全一致**。 functional 不変。

### 3-3. wav byte-level diff

```
$ cmp -l /tmp/pmdneo-B/audio.wav /tmp/pmdneo-Bbeta/audio.wav | head -5
 18069 377   0
 18070 377   0
 ...
```

offset 18069 (= WAV header 44 byte 控除後 sample idx 約 9012、 約 188 msec 付近) から
微小差分。 全くの静寂 → 騒音ではなく、 sample 値が微妙に違う (= phase shift)。 これは
adpcmb_keyon_hook が初めて呼ばれた直後の chip write timing shift が、 ymfm の
cycle-accurate sampling と相互作用した結果。

## 4. 設計判断 4-3-β-1 (= refactor 系 commit の gate 規律確立)

### 規律

driver / chip register write 経路の refactor 系 commit では:

- **primary gate**: `ymfm-trace.tsv` byte-identical (= 全 chip writes 同一)
- **secondary gate**: 関連 register 帯 writes 全件一致
- **参考のみ**: wav sha256 (= 不変期待は cycle 増減で容易に false negative)

### Why

- Z80 instruction の cycle 数変化 (= T-states 増減) で ymfm cycle-accurate emulation の
  chip write tick が μsec オーダーずれる
- 同じ register writes が同じ順序で出ていれば functional に完全等価 (= driver semantic 不変)
- wav は sample 値レベルで敏感に変動、 「不変」 を gate にすると refactor で常に false negative

### How to apply

- refactor 系 commit (= 「register 不変」 を宣言する commit) は最初に ymfm-trace を取り、
  pre/post で `diff` byte-identical を確認
- ADPCM-B / FM / SSG 等 関連帯の writes も別途 idx + reg + val 全件確認
- commit message + handoff doc に「ymfm-trace byte-identical」 「writes 全件一致」 「wav 差は
  timing artifact」 を必ず書く

memory `feedback_refactor_gate_register_trace_not_wav.md` 参照。

### 例外

data-only (= .db / .dw / 定数のみ) 改修や main.c のみ改修 (= driver asm 不変) では
cycle 数も不変なので wav sha256 一致を gate にしてよい。

## 5. 4-3-β gate 評価

| gate | 結果 |
|---|---|
| ymfm-trace 2202 lines byte-identical | ✅ PASS |
| ADPCM-B 20 件 writes 全件一致 | ✅ PASS |
| ROM_A wav sha256 維持 | ✅ PASS (= hook 未到達ケース) |
| note 値引渡し経路確立 (= A レジスタで PART_OFF_NOTE) | ✅ PASS |
| ROM_B wav sha256 (= 参考のみ、 gate にしない) | ⚠️ timing artifact (= functional 不変、 規律外) |

functional regression 不在、 4-3-β は **PASS**。

## 6. 4-3-γ / δ への引継

### 4-3-γ で予定

`adpcmb_keyon` (L2571-2573) refactor:
- A レジスタの note 値を delta-N に変換 (= PMD V4.8s 公式 source の adpcmb_setfreq 流儀)
- reg 0x19 (delta-N LSB) + reg 0x1A (delta-N MSB) を直接書込み
- sample addr (reg 0x12-0x15) / vol (reg 0x1B) / pan (reg 0x11) は beat fixed 維持 (= 4-3-ε 候補)
- init_adpcmb_beat 呼出は keep か refactor 判断

note → delta-N 変換は別 table / 計算式が必要。 PMD V4.8s 公式 source の対応 routine
を流用候補。

### 4-3-δ で予定

2 件の J part fixture (= note 値違いの minimum + variant) で:
- ymfm-trace の reg 0x19/0x1A が note 差分を反映
- wav sha256 が異なる (= 4-3-γ で意図的 register 差分発生)
- fixture-driven verify として gate 評価

## 7. 関連

- ADR-0016 §決定 3 step 4-3
- `docs/design/handoff/adr-0016-step4-3-alpha-findings.md` (= 4-3-α、 cmd 0x05 revert)
- memory `feedback_refactor_gate_register_trace_not_wav.md` (= 本 step で確立した gate 規律)
- memory `feedback_post_commit_push_report_format.md` (= commit 後報告書式)
- standalone_test.s L2509-2512 (= adpcmb_keyon_hook 本体)
- WORKAREA.inc L58 (= PART_OFF_NOTE = 11)
