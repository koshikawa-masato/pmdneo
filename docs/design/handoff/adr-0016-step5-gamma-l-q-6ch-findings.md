# ADR-0016 step 5 γ L-Q 6 ch independence finding

- 起票日: 2026-05-12 (= 6th session γ-b)
- 起票者: Claude Code
- 関連: γ-a commit cc51116、 β-3 commit 3fd418c、 ADR-0019 §決定 6 sub-sprint γ、 議題 5

## 概要

**γ-b は検証 infrastructure commit** (= driver 実装変更なし、 γ-a の driver 改修を fixture-driven verify で固定)。 γ で確立した「L-Q 6 ch 独立 ADPCM-A track」 を tutti fixture (= 6 ch 同時 keyon) + verify script で regression test 化。

`@<n>` → comat_pcm → PART_OFF_INSTRUMENT → adpcma_keyon_simple → sample table lookup chain (= β-2 確立) が **6 ch 並列に独立動作** することを trace で証明。

## γ chain 完成 (= γ-b で固定する対象)

```
L body @0 → PART_ADPCMA1 (ch 0) → reg 0x10/0x18/0x20/0x28/0x08+0 → keyon bit 0x01
M body @1 → PART_ADPCMA2 (ch 1) → reg 0x10/0x18/0x20/0x28/0x08+1 → keyon bit 0x02
N body @2 → PART_ADPCMA3 (ch 2) → reg 0x10/0x18/0x20/0x28/0x08+2 → keyon bit 0x04
O body @3 → PART_ADPCMA4 (ch 3) → reg 0x10/0x18/0x20/0x28/0x08+3 → keyon bit 0x08
P body @4 → PART_ADPCMA5 (ch 4) → reg 0x10/0x18/0x20/0x28/0x08+4 → keyon bit 0x10
Q body @5 → PART_ADPCMA6 (ch 5) → reg 0x10/0x18/0x20/0x28/0x08+5 → keyon bit 0x20
```

すべてが **independent + simultaneous** に動作。

## fixture

`src/test-fixtures/step5/l-q-tutti.mml`:

```
#Title  ADR-0016 step 5 gamma-b L-Q tutti (= 6 ch simultaneous keyon)
#PNEFile "step5.PNE"

L @0 o4 l1 c    ; ch 0 = bd
M @1 o4 l1 c    ; ch 1 = sd
N @2 o4 l1 c    ; ch 2 = hh
O @3 o4 l1 c    ; ch 3 = tom
P @4 o4 l1 c    ; ch 4 = rim
Q @5 o4 l1 c    ; ch 5 = top
```

各 ch が異なる voice (= bd/sd/hh/tom/rim/top) を引いて同時 keyon。

## verify script

`src/test-fixtures/step5/verify-l-q-tutti-gamma.sh` (= 約 250 行)。

### 6 段階 trace gate (= user 4 観点をカバー)

| gate | 観点 | source | 確認内容 |
|---|---|---|---|
| 1 | build | - | tutti fixture build + MAME trace |
| 2 | workarea independence | z80-mem-trace | 6 ch PART_OFF_INSTRUMENT 独立書込 |
| 3 | ch overlap | ymfm-trace | 6 ch sample addr 全 ch 異なる |
| 4 | register isolation | ymfm-trace | reg 0x10/0x18/0x20/0x28/0x08+ch 全 ch 個別書込 |
| 5 | simultaneous keyon | ymfm-trace | reg 0x00 で 6 ch 全 bit (= 0x01-0x20) 順次 keyon |
| 6 | MSB 同一性 | ymfm-trace | reg 0x18/0x28 全 ch 0x00 (= sample addr < 1024 byte) |

## verify script 実行結果 (= 2026-05-12 自動 PASS 確認)

### gate 2: workarea independence

各 ch PART_OFF_INSTRUMENT 書込:

| ch | workarea addr | voice idx |
|---|---|---|
| L | 0xFAFF | 0x00 (= bd) |
| M | 0xFB3F | 0x01 (= sd) |
| N | 0xFB7F | 0x02 (= hh) |
| O | 0xFBBF | 0x03 (= tom) |
| P | 0xFBFF | 0x04 (= rim) |
| Q | 0xFC3F | 0x05 (= top) |

(= PART_WORKAREA_SIZE=64、 part_workarea=0xF820 から計算)

### gate 3: ch overlap (= 6 ch sample addr 全 ch 異なる)

reg 0x10+ch (= ymfm 110-115、 start LSB):

| ch | reg | value | sample |
|---|---|---|---|
| L | 110 | 0x00 | bd |
| M | 111 | 0x04 | sd |
| N | 112 | 0x07 | hh |
| O | 113 | 0x0C | tom |
| P | 114 | 0x0A | rim |
| Q | 115 | 0x12 | top |

全 6 ch で **異なる sample addr** = ch overlap 成立。

### gate 4: register isolation

5 reg group (= start LSB / start MSB / stop LSB / stop MSB / vol/pan) × 6 ch = 30 reg に全部 write。 ch ごと **個別 reg** (= 0x10+ch、 0x18+ch、 ...) で **register isolation** 成立。

注: vol/pan (= reg 0x08+ch) は ch ごと **意図的に異なる** (= `adpcma_pan_bits` 固定値 `0xC0 0x40 0x80 0x40 0xC0 0x80`)。 これは β-3 の「ch 0 のみで sample 変えて pan 同一」 とは別の話で、 6 ch で pan が異なるのは既存 K/R rhythm 用 pan mapping。 議題 1 retain + refactor 遵守。

### gate 5: simultaneous keyon

reg 0x00 (= 100) keyon writes:

| idx | value | ch |
|---|---|---|
| 277 | 0x01 | L (ch 0) |
| 283 | 0x02 | M (ch 1) |
| 289 | 0x04 | N (ch 2) |
| 295 | 0x08 | O (ch 3) |
| 301 | 0x10 | P (ch 4) |
| 307 | 0x20 | Q (ch 5) |

6 ch 全部 keyon。 各 ch が **個別 bit** で keyon (= 同 tick 内で sequential write、 chip 内では並列再生)。

### gate 6: MSB 同一性

reg 0x18-0x1D (start MSB) + reg 0x28-0x2D (stop MSB) 全 12 reg で `0x00`。 sample addr が < 1024 byte 範囲で MSB 全 0 (= 正常な期待値)。

## γ-b 完了判定

- ✅ tutti fixture 作成 (= 6 ch 同時 keyon)
- ✅ verify script 作成 + 自動 PASS (exit 0)
- ✅ handoff doc 作成 (= 本 doc)
- ✅ driver 実装変更なし (= γ-a 改修を fixture-driven verify で固定)
- ✅ user 4 観点 (= simultaneous keyon / ch overlap / register isolation / workarea independence) 全達成
- ✅ wav は参考扱い (= primary は register trace)

## γ 全体完了 (= ADR-0019 §決定 6 sub-sprint γ)

| sub | commit | 内容 |
|---|---|---|
| γ-a | `cc51116` | routine 一般化 + M-Q dispatch 追加 (= driver) |
| γ-b (= 本 commit) | (本 commit) | tutti fixture + verify script + handoff doc |

## δ への引継ぎ事項

### δ = volume / pan hook 完成 (= ADR-0019 §決定 6 sub-sprint δ)

γ で 6 ch 独立 dispatch は成立。 δ では vol/pan hook を完成させて audible 化:

1. **PART_OFF_VOLUME hook**:
   - 既存 `adpcma_volume_hook` は V cmd (= 0-255) → reg 0x10+ch (= ADPCM-A vol) を **per-ch vol bit (= bit 5-0)** に書き込む path
   - 現状: V cmd が L-Q part body にないので vol = 0 (= silent)
   - δ で: V cmd 経由で audible 化、 fixture で V255 など追加

2. **PAN hook**:
   - 既存 `adpcma_pan_bits` (= ch ごと固定 `0xC0/0x40/0x80/0x40/0xC0/0x80`) を retain
   - L-Q 本線で pan を user 制御可能にするには別 cmd (= 設計判断要)
   - δ scope-out 可 (= 既存 fixed pan で十分なら)

3. **audible 化 fixture**:
   - L @0 V255 o4 l1 c のような fixture (= V cmd 加)
   - 期待: reg 0x08+ch で bit 5-0 が non-zero (= audible)

### δ で verify 観点

- vol cmd dispatch trace (= V cmd → adpcma_volume_hook → reg 0x10+ch write)
- audible verify (= wav RMS が non-zero、 ただし FM 同居問題は α-3 audio finding 経験で solo 化検討)

### γ で touch しない範囲 (= δ で扱う or scope-out)

- vol/pan hook 改修
- audible verify
- .PNE parser
- K/R rhythm 現役接続

## 関連

- **commit chain**: 
  - α: 3e01f48 / ae6b419 / e97210c / 335dec1
  - β: b3b1683 / 0029034 / 93bfc3d / 3fd418c
  - γ: cc51116 (γ-a) / [本 commit] (γ-b)
- **ADR**: ADR-0019 §決定 6 sub-sprint γ
- **handoff**:
  - `docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md` (= α-1 ground truth)
  - `docs/design/handoff/adr-0016-step5-alpha-2-trace-gate-findings.md` (= α-3 + audio finding)
  - `docs/design/handoff/adr-0016-step5-beta-1-sample-fixture-findings.md` (= β-1)
  - `docs/design/handoff/adr-0016-step5-beta-2-sample-lookup-findings.md` (= β-3)
- **fixture**:
  - `src/test-fixtures/step5/l-part-minimum.mml` (= α 用)
  - `src/test-fixtures/step5/l-part-sample-a.mml` (= β 用 @0)
  - `src/test-fixtures/step5/l-part-sample-b.mml` (= β 用 @1)
  - `src/test-fixtures/step5/l-q-tutti.mml` (= γ 用 6 ch 同時)
- **verify script**:
  - α-3: verify-l-part-alpha-trace-gate.sh
  - β-3: verify-l-part-beta-sample-lookup.sh
  - γ-b: verify-l-q-tutti-gamma.sh

γ-b で sub-sprint γ 完全終了。 次は δ (= vol/pan hook 完成、 audible 化) 着手前 user 擦り合わせ。
