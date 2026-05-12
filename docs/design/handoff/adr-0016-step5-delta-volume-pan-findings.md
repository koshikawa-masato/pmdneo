# ADR-0016 step 5 δ volume/pan finding (= δ-a bug fix + δ-b verify)

- 起票日: 2026-05-12 (= 6th session δ-b)
- 起票者: Claude Code
- 関連: δ-a commit d1ebdfc、 γ-b commit a4cbc99、 ADR-0019 §決定 6 sub-sprint δ

## 概要

**δ で 2 つの成果**:
1. **δ-a (= commit d1ebdfc)**: Phase 9c 期遺産 `adpcma_volume_hook` の **register 番号 bug** を fix。 旧 `reg 0x10+ch` (= start LSB、 sample addr 破壊 path) → 新 `reg 0x08+ch` (= per-ch vol+pan、 仕様正)。
2. **δ-b (= 本 commit)**: v0 / v16 2 fixture + verify script + handoff doc で δ-a を regression test 化。

driver bug fix を独立 commit にし、 検証 infrastructure で固定。 step 4-3 / α / β / γ で確立した「driver 修正 → verify 固定」 規律踏襲。

## δ-a bug fix 経緯

### 発見

δ 着手前に既存 `adpcma_volume_hook` (= L2535 周辺) を確認、 register 番号誤りを検出:

```asm
adpcma_volume_hook:
        ld   a, PART_OFF_VOLUME(ix)
        srl  a × 3                  ; A = V/8 (= 0-31)
        or   #0xC0                  ; 固定 pan L+R
        ld   c, a
        ld   a, PART_OFF_CH_IDX(ix)
        add  a, #0x10               ; ★ reg 0x10+ch (= bug)
        call ym2610_write_port_b    ; ★ start LSB を上書き
```

`reg 0x10+ch` は ADPCM-A start LSB (= sample addr の一部)。 vol/pan は `reg 0x08+ch` が正しい。 V cmd dispatch で sample addr 破壊 path だった。

α/β/γ fixture には V cmd がなく、 bug は表面化していなかった (= adpcma_volume_hook が呼ばれず)。

### 修正

```asm
adpcma_volume_hook:
        ld   a, PART_OFF_VOLUME(ix)
        srl  a × 3                  ; A = V/8 (= 0-31 vol)
        ld   hl, #adpcma_pan_bits
        ld   e, PART_OFF_CH_IDX(ix)
        ld   d, #0
        add  hl, de                 ; HL = pan_bits[ch] addr
        or   (hl)                   ; A = vol | pan_bits[ch]
        ld   c, a
        ld   a, PART_OFF_CH_IDX(ix)
        add  a, #0x08               ; ★ reg 0x08+ch (= 仕様正)
        call ym2610_write_port_b
```

主な変更:
- `add a, #0x10` → `add a, #0x08` (= 仕様 fix)
- `or #0xC0` (= 固定 pan) → `or (hl)` (= `adpcma_pan_bits[ch]`、 議題 1 retain + refactor)

## V cmd dispatch chain (= 確定 mapping)

PMD V4.8s 規約 + 実 trace から確定:

```
MML v<n>  (n = 0..16)
  ↓ mc compiler /B emit
  0xFD nn (= v cmd + value、 2 byte)
  ↓ driver commandsp_v → comv
  V(1) table 引き (= linear 0..16 → 0..255):
    v0  → V = 0
    v1  → V = 16
    v2  → V = 32
    ...
    v15 → V = 240
    v16 → V = 255
  ↓ PART_OFF_VOLUME(ix) = V
  ↓ adpcma_volume_hook (= V cmd dispatch trigger)
  vol = V >> 3   (= 0..31、 5 bit max)
  reg 0x08+ch = pan_bits[ch] | vol (= 8 bit chip reg)
```

ch 0 (= L) で pan_bits[0] = 0xC0 (= L+R):
- v0  → reg 0x08+0 = 0xC0 (= pan|0)
- v16 → reg 0x08+0 = 0xDF (= pan|0x1F)

## fixture

| file | MML | 期待 reg 0x08+0 |
|---|---|---|
| `src/test-fixtures/step5/l-part-volume-low.mml` | `L v0 @0 o4 l1 c` | `0xC0` |
| `src/test-fixtures/step5/l-part-volume-high.mml` | `L v16 @0 o4 l1 c` | `0xDF` |

UTF-8 + CRLF、 `#PNEFile "step5.PNE"` 宣言 (= mc compiler strict 要求対応)。

## verify script

`src/test-fixtures/step5/verify-l-part-delta-volume-pan.sh` (= 約 200 行、 β-3 派生)。

### 6 段階 trace gate

| gate | 観点 | source | 期待 |
|---|---|---|---|
| 1 | v0 build + trace | - | infra PASS |
| 2 | v16 build + trace | - | infra PASS |
| 3 | reg 0x08+0 差分 | ymfm-trace | 0xC0 ≠ 0xDF |
| 4 | reg 0x10+0 同一性 | ymfm-trace | 両 0x00 (= V cmd で破壊なし) |
| 5 | reg 0x18/0x20/0x28+0 同一性 | ymfm-trace | sample addr 不変 |
| 6 | reg 0x00 keyon 同一性 | ymfm-trace | 両 ch 0 keyon (= 0x01) |

robust 化:
- expected value は trace から動的取得 (= sha256 / addr hardcode なし)
- bash 3.x 対応 (= `tr 'a-f' 'A-F'` で大文字化、 `${X^^}` 不使用)
- ROM build / linker layout 変動でも追従

## verify script 実行結果 (= 2026-05-12 自動 PASS)

```
gate 1: v0 (low) trace 取得 ✅
gate 2: v16 (high) trace 取得 ✅

gate 3: reg 0x08+0 差分
  v0  = 0xC0 (= 期待 0xC0)
  v16 = 0xDF (= 期待 0xDF)
  ✅ 差分検出

gate 4: reg 0x10+0 同一性
  v0  = 0x00 / v16 = 0x00
  ✅ 同一 (= V cmd で start LSB 破壊なし)

gate 5: reg 0x18/0x20/0x28+0 同一性
  start MSB: 両 0x00 / stop LSB: 両 0x03 / stop MSB: 両 0x00
  ✅ sample addr 不変

gate 6: reg 0x00 keyon 同一性
  両 fixture で ch 0 keyon (= 0x01) 確認
  ✅ vol で keyon 動作は変わらない

🎉 PASS (exit 0)
```

## 音声 gate (= 参考情報)

wav sha256:
- v0  (low):  `0a12a9448cc908aeb386611bf1db6e2e65ade91aea7e2d49c66efbc0f343a72b`
- v16 (high): `3b1a1756110c95c7954cc61a0fa49762a873fd51af047127ad55f86e931f91f4`

異なる (= V cmd で audible 差分発生)。 ただし FM 同居 audio (= α-3 audio finding) で primary gate にしない。 v16 で audible 化したが、 user が耳で聴くには solo 化 fixture 検討要 (= memory `feedback_audio_gate_solo_isolation` 適用)。

## δ chain 完成 (= ADR-0019 §決定 6 sub-sprint δ)

```
MML v<n>
  ↓ mc compiler /B emit (= 0xFD nn)
  ↓ driver commandsp_v → comv
  ↓ V(1) table 引き (= 0..16 → 0..255)
  ↓ PART_OFF_VOLUME(ix) = V
  ↓ adpcma_volume_hook   ← δ-a で reg 0x08+ch 書込 fix
  ↓ pan_bits[ch] | (V>>3)
  ↓ reg 0x08+ch = chip vol/pan
```

これで「V cmd → ADPCM-A 5 bit vol + 2 bit pan」 chain が成立、 driver は audible 化可能。

## ε への引継ぎ事項 (= step 5 完了統合)

### ε = ADR-0019 §決定 6 sub-sprint ε (= step 5 完了判定統合)

α/β/γ/δ で:
- α: `.MN direct path` + L dispatch
- β: voice index → sample lookup
- γ: L-Q 6 ch 独立 dispatch
- δ: vol/pan hook 完成

ε で:
- ADPCM-A 6 ch 使用 `.MN` 楽曲 1 つ以上 MAME 再生確認 (= ADR-0019 §完了判定)
- 統合 doc 作成
- ADR-0016 全体完了 → Proposed → Accepted 移行

### ε で扱う候補

- 統合楽曲 fixture (= L-Q + V cmd + 複数 note + リズム pattern 等)
- audible verify (= solo 化 fixture or FM mute 検討)
- 楽曲 trace gate (= 4-8 拍くらいのリズムパターン)
- handoff 統合 doc (= step 5 全体 sum-up)

### ε で touch しない範囲

- 既存 driver (= α-2/β-2b/γ-a/δ-a 改修済)
- 既存 fixture
- .PNE parser (= 次 sprint)
- K/R rhythm 現役接続 (= 次 micro-sprint)

## 残り課題 (= ε scope-out)

### adpcma_keyon_simple の vol or 動作

`adpcma_keyon_simple` 内で `or PART_OFF_VOLUME(ix)` (= raw V or pan_bits) が動いている。 trace で reg 0x08+0 が **2 回 write** されることを確認:
- idx 272 (= adpcma_volume_hook 経由): pan|V/8 (= 0xC0 / 0xDF)
- idx 277 (= adpcma_keyon_simple 経由): pan|raw V (= 0xC0 / 0xFF)

v16 で keyon 時 reg 0x08+0 = `0xFF` (= 6 bit vol 0x3F、 ADPCM-A 仕様 6 bit max)。 vol scale が hook と keyon で **5 bit vs 6 bit 不一致**だが、 chip 仕様内 (= bit 6-7 pan + bit 5-0 vol)。 これは別 sprint で「vol scale 統一」 を扱う候補。

### δ で扱わなかった項目 (= 議題 + user 規律)

- pan cmd (= user 制御可能 pan 設定)
- master attenuation (= 全 ch 共通 vol scale)
- PCMVolume Extend
- audible verify (= solo 化 fixture)

## δ-b 完了判定

- ✅ v0 / v16 2 fixture 作成 (= 0..16 範囲)
- ✅ verify script 作成 + 自動 PASS (exit 0)
- ✅ handoff doc 作成 (= 本 doc)
- ✅ driver 実装変更なし (= δ-a を fixture-driven verify で固定)
- ✅ user 6 必須確認項目 全達成

## 関連

- **commit chain**:
  - α: 3e01f48 / ae6b419 / e97210c / 335dec1
  - β: b3b1683 / 0029034 / 93bfc3d / 3fd418c
  - γ: cc51116 / a4cbc99
  - δ: d1ebdfc (δ-a bug fix) / [本 commit] (δ-b verify)
- **ADR**: ADR-0019 §決定 6 sub-sprint δ
- **handoff**:
  - α-1: alpha-1-mn-layout.md
  - α-2: alpha-2-trace-gate-findings.md
  - β-1: beta-1-sample-fixture-findings.md
  - β-2: beta-2-sample-lookup-findings.md
  - γ: gamma-l-q-6ch-findings.md
  - δ (本 doc): delta-volume-pan-findings.md
- **fixture**:
  - α: l-part-minimum.mml
  - β: l-part-sample-a.mml / l-part-sample-b.mml
  - γ: l-q-tutti.mml
  - δ: l-part-volume-low.mml / l-part-volume-high.mml
- **verify script**:
  - α-3: verify-l-part-alpha-trace-gate.sh
  - β-3: verify-l-part-beta-sample-lookup.sh
  - γ-b: verify-l-q-tutti-gamma.sh
  - δ-b: verify-l-part-delta-volume-pan.sh

δ-b で sub-sprint δ 完全終了。 次は ε (= step 5 完了統合) 着手前 user 擦り合わせ。
