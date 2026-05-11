# ADR-0011: PMDNEO driver FM octave +1 shift 修正 (= block = MML octave - 1 で PMD V4.8s 規約整合)

- 状態: Accepted
- 起票日: 2026-05-11
- 起票者: 越川将人 (M.Koshikawa)
- 関連: ADR-0006 §A (= PMDNEO MML 文法、 PMDDotNET 互換)、 ADR-0009 §D (= octave +1 shift 観察)、 ADR-0010 (= A/D voice fix、 trace で数値固定)、 memory `project_pmd_voice_ml_verified.md` (= 「PMD o5 c = MIDI C4 = 261 Hz」 実機確証)

## 背景

ADR-0009 §D で観察された MML `o4 l1 e` の周波数差異 (= PMDDotNET pmdplay 165 Hz / PMDNEO MAME 330 Hz = +1 octave shift) を、 ADR-0010 sprint の ymfm trace 実測で数値固定済:

| MML | ch | trace fnum | trace block | 実周波数 (MAME) | 期待 (PMD V4.8s 規約) | 差異 |
|---|---|---|---|---|---|---|
| `o4 c` (= A part) | ch1 | 0x26A | 4 | **261.9 Hz** (= MIDI C4) | 131 Hz (= MIDI C3) | +1 octave |
| `o4 e` (= B part) | ch2 | 0x30B | 4 | **330.5 Hz** (= MIDI E4) | 165 Hz (= MIDI E3) | +1 octave |
| `o4 g` (= D part) | ch4 | 0x39E | 4 | **392.4 Hz** (= MIDI G4) | 196 Hz (= MIDI G3) | +1 octave |

一貫して +1 octave shift が観測される。

## driver source 解析

`src/driver/standalone_test.s:623-697` `fnumset_fm` 解析:

```asm
fnumset_fm:
        push    af
        push    bc
        and     #0x0F             ; a = note_byte & 0x0F = onkai (0-11)
        ld      l, a
        ld      h, #0
        add     hl, hl            ; hl = onkai × 2 (= 2 byte/entry)
        ld      bc, #fnum_data
        add     hl, bc            ; hl = fnum_data + onkai × 2
        ld      e, (hl)
        inc     hl
        ld      d, (hl)           ; de = fnum value (= 11-bit、 例 C=0x26A)

        pop     bc
        pop     af
        rrca
        rrca
        rrca
        rrca                      ; a = note_byte >> 4 = octave (high nibble)
        and     #0x07             ; a = octave & 0x07 (= 0-7)
        add     a, a
        add     a, a
        add     a, a              ; a = octave << 3 (= BLOCK 位置 bit 3-5)
        ld      l, a              ; l = block << 3
        ld      a, d
        and     #0x07             ; a = fnum upper 3 bit (bit 8-10)
        or      l                 ; a = (block << 3) | fnum_upper3
        ld      h, a              ; h = reg 0xA4 value
        ...
```

つまり driver は **MML の octave 値を そのまま YM2610 BLOCK として書込** している:

- MML `o4 c` → note_byte = 0x40 → octave = 4 → block = 4
- chip 計算 (= YM2610 datasheet 式): F = fnum × clock / (144 × 2^(21-block))
  - block=4, fnum=0x26A=618, clock=8MHz → F = 618 × 8e6 / (144 × 131072) = 261.9 Hz

これは **fnum_data table 自体は標準** (= `0x26A` は OPNA/OPNB 共通の「C note + block 4 → 261 Hz」 設計値) で、 問題は **octave → block 変換に -1 offset がない** こと。

## PMD V4.8s 規約との突合

PMD V4.8s 公式マニュアル + ML 検証 (= memory `project_pmd_voice_ml_verified.md` 実機確証):

- **PMD V4.8s 規約**: `o5 c = MIDI C4 = 261 Hz` (= 5 オクターブ目の C が国際標準 C4)
- PMDDotNET pmdplay の OPNA 経路もこの規約に従う (= 「o4 c = 131 Hz = C3」 を出力)
- つまり PMD 内部で MML octave → chip block 変換に **「octave - 1 = block」** の関係

PMDNEO driver は MML octave 値を そのまま block にしているため、 PMD V4.8s 規約から +1 octave shift。 fix は `block = octave - 1` への変換追加。

compile.py 側 (= `src/tools/pmd-mml/compile.py:312-314`) で:

```python
note_byte = (self.octave << 4) | onkai
if not 0x40 <= note_byte <= 0x7F:
    self.error(line_no, start, f"note byte 0x{note_byte:02X} outside octave 4-7 range")
```

compile.py は MML octave 4-7 を受領し note_byte 0x40-0x7F にエンコード。 driver 側で -1 offset すると block 範囲は 3-6 (= 0-7 の chip valid 範囲内、 OK)。

## 決定

### A. driver fnumset_fm に `dec a` 1 行追加 (= MML octave - 1 = chip block)

`src/driver/standalone_test.s:643` `and #0x07` の直後に `dec a` を挿入。 octave 抽出後 block 計算前に -1 offset。

実装後想定:

```asm
        rrca
        rrca
        rrca
        rrca
        and     #0x07             ; a = octave & 0x07
        dec     a                 ; ADR-0011: MML octave - 1 = chip block (= PMD V4.8s 規約「o5 c = MIDI C4」 整合)
        add     a, a
        add     a, a
        add     a, a              ; a = block << 3
        ...
```

`dec a` の flag 影響:
- a=4 (= octave 4) → a=3, zero=0, carry=0
- a=1 (= octave 1) → a=0, zero=1, carry=0
- 後続 `add a, a` で flag 上書きされるため `dec a` の flag は無影響

octave 範囲:
- compile.py で octave 4-7 限定 → block 3-6 (= chip valid 0-7 内)
- 仮に octave=0 が driver に来ても block=255 (= 0 - 1) に wrap、 ただし `add a, a x3` で「255 << 3」 で overflow、 後段の or で乱れる。 ただし compile.py の制約があるため実体ケースで発生しない。 防衛的に対応するなら `or a; jr z, ...` で octave=0 を別経路化だが、 本 sprint では「バグ修正に余計なリファクタを混ぜない」 規律で touched せず。

### B. SSG 側 (= fnumset_ssg) は本 sprint scope 外

`fnumset_ssg` (line 716-765) は SSG 用で fnum × octave shift 経路 (= fnum を octave 回数分 srl/rr で右シフト) で FM とは完全に異なる logic。 SSG での octave shift 状況は本 sprint trace 実測対象外で、 別途検証必要。 本 ADR では FM のみ fix し、 SSG は別 sprint 扱い。

### C. fnum_data table は touched せず

fnum_data table (line 789-801) は OPNA/OPNB 共通の標準値 (= 「C=0x26A、 block=4 で 261 Hz」 設計値) で、 PMDDotNET 経路でも同値を使用する想定。 table を書換えるアプローチは:

- fnum_data の値を 2 倍 (= 0x26A → 0x4D4) で「block=4 + 倍 fnum で C3=131 Hz」 にする → fnum 11-bit overflow リスク (0xFFF=4095 max、 高音域で範囲超え)
- 各 octave 用 fnum table を 4 種準備 (= block 3/4/5/6 用) → メモリ + 計算量増

これらに比べ「driver fnumset_fm で -1 offset」 が最小変更で機能等価。 fnum_data table は不変。

### D. 動作確認方針 (= 「動作確認義務」 規律遵守)

driver / runtime 層 commit のため、 build + MAME 録音 + 解析で fix の効果検証:

1. `bash scripts/run-mame.sh --build --headless --wavwrite --chip ym2610b --gamerom lastbld2` で test-aes-ad.mml 録音
2. python3 wave 解析で:
   - ch2 (B) の `o4 e` が **165 Hz (= MIDI E3)** に修正されることを確認 (= 旧 330 Hz から半周波数)
   - A/D は MAME 上 audio output されない (= ADR-0010 §C の chip mismatch 制約継続)
3. ymfm trace で:
   - ch2 (B) の fnum upper 3 bit + block 部分が `block=3, fnum upper=...` に変化 (= 旧 block=4 から -1)
   - fnum lower 8 bit (= reg 0xA1) は不変 (= fnum_data 自体は不変)

### E. 他 part / 他 cmd への影響範囲

`fnumset_fm` は fm_keyon_hook + fnumset_fm_hook の両方から呼ばれる。 MML `c`-`b` note cmd 全部が影響受ける。 一括 -1 octave shift で driver 全体が PMD V4.8s 規約整合。

他 cmd への副作用:
- voice (`@`) cmd: fnum 経路と独立、 影響なし
- volume (`V`/`v`) cmd: TL 経路、 影響なし
- length / gate cmd: tempo + counter 経路、 影響なし

fnum 計算経路のみ touched で他 cmd の挙動変化なし。

## 影響

- MML `o4 c` → MIDI C3 = 131 Hz 発音 (= PMD V4.8s 規約整合)
- voice-test 28 entry / test01.mml の周波数 baseline は **全 part で -1 octave** ずれる (= 既存 reference は +1 octave shift 状態で取得済、 ADR-0006 §5 検証 sprint で baseline 再取得時に同時補正)
- AES+ 実機 (= YM2610B) でも本 fix で PMD V4.8s 規約通りの音高
- SSG 側 octave 挙動は不変 (= 別 sprint で検証 + fix)

## 残論点 / 後続 sprint

- **SSG 側 octave shift 検証** (= 別 sprint): fnumset_ssg の srl/rr 回数が PMD V4.8s 規約整合か実測 verify
- **ADR-0006 §5 検証**: 28 entry baseline 再取得 (= 本 ADR + ADR-0009 + ADR-0010 で値変動)
- **AES+ 実機検証** (= 別 sprint): A/D 含む 6 ch 全 PMD 規約通り発音確認
- **MAME chip mismatch 解消** (= 別 sprint): MAME 改造で YM2610B emulation 可能化

## 改訂履歴

- **2026-05-11 起票**: 初版 (= 決定 A-E、 -1 offset 実装方針)

## 参照

- ADR-0009 §D: octave +1 shift 観察 (= 本 sprint の発端、 数値は ADR-0010 trace で固定)
- ADR-0010: A/D voice fix sprint で trace 経由 octave shift 確証 (= o4 c → 262 Hz、 o4 e → 330 Hz、 o4 g → 392 Hz)
- memory `project_pmd_voice_ml_verified.md`: 「PMD o5 c = MIDI C4 = 261 Hz」 実機確証
- memory `project_pmd_voice_alg_verified.md` 他 6 step: PMDDotNET pmdplay OPNA 経路の周波数 reference
- YM2610 / YM2610B datasheet: reg 0xA4 (BLOCK_FNUM_2) bit 3-5 = BLOCK (= octave 相当 0-7)、 fnum 11-bit
- PMDDotNET (https://github.com/kuma4649/PMDDotNET): octave → block 変換の参考実装 (= 別途突合可)
