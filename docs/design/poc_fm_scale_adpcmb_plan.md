# 実装計画: standalone PoC で FM ドレミファソラシド + ADPCM-B beat 同時再生

**位置付け**: nullsound 非依存 standalone PoC (= commit `0e74ec8`、 chip ch 2 C4 持続音実証) の機能拡張。 設計書 `pmdneo_self_contained_driver.md` 11 章 8 step migration plan の中で、 step 1-7 の主要要素を 1 commit で凝縮実装する PoC phase 2。

**作成**: 2026-05-09 / **作成者**: 越川将人 + Claude Code (= 計画) / Codex (= 実装委譲予定)

## 1. Context

### 直前成果 (= commit `0e74ec8`)
- `src/driver/standalone_test.s` 1 file 完結、 nullsound include 0
- 0x0000 cold start + 0x0066 NMI handler (= 30 register write inline) + idempotent design
- chip ch 2 で C4 持続音、 改造 MAME ymfm-trace で 0x28=0xF1 keyon × 3 cycle 客観確証

### 次 step として何を実証するか
- **TIMER-B IRQ 駆動 (= 0x0038 IRQ handler)** が自作 driver で動作する
- **chip ch 2 で 8 note scale (= ドレミファソラシド)** を一定 tempo で順次再生
- **ADPCM-B beat 単発再生** が並行発火、 FM scale と干渉なし
- **cmd dispatch (= cmd 2 / cmd 5 別個機能)** が NMI handler 内で動作する
- nullsound 0 link を維持

これにより設計書 8 step migration plan の **step 2-5 (= chip helper + TIMER + cmd FIFO + SRAM map)** を 1 PoC で実証完了、 残り step (= driver 本体 fmmain 統合、 ADPCM-B helper 完成、 SubF-1 fixture) に進む基盤を確立。

## 2. 動作 spec (= 受け入れ基準)

起動後の sequence:
1. NEOGEO BIOS boot (= 数秒の chime)
2. main.c で `*REG_SOUND = 3` 発火 → Z80 cold reset (= driver state init)
3. main.c で `*REG_SOUND = 5` 発火 → Z80 NMI → ADPCM-B beat 1 回再生
4. main.c で `*REG_SOUND = 2` 発火 → Z80 NMI → FM scale 開始
5. **chip ch 2 で C4 → D4 → E4 → F4 → G4 → A4 → B4 → C5 を約 0.5 秒間隔で順次発音**(= 約 4 秒で完走)
6. scale 完走後 chip ch 2 keyoff、 silent 状態維持

聴感判定:
- ADPCM-B beat 1 回 (= 鋭い打撃音)
- ADPCM-B 直後から FM 8 note scale が一定 tempo で進行
- 最後の C5 で停止、 silent

## 3. 既存資産 (= 流用 / 参照)

### 流用 (= standalone_test.s に取り込む)
- standalone_test.s 自体 (= 0x0000 cold start + 0x0066 NMI handler 構造)
- chip ch 2 voice register 列 (= ALG/FB + DT/ML×4 + TL×4 + KS/AR×4 + AM/DR×4 + SR×4 + RR/SL×4 + SSG-EG×4)
- C4 fnum value (= 0x6A / 0x22 = lower / upper)

### 参照 (= 値を読み取って自作実装に書き写す、 nullsound include しない)
- `src/driver/PMD_Z80.inc`:
  - `scale_notes_fm` (= `0x40 0x42 0x44 0x45 0x47 0x49 0x4B 0x50`、 8 note table)
  - `fnum_data` (= 12 半音分の 16-bit base fnum、 OCT 0 起点)
  - `fnumset_fm` (= note byte → fnum/block 計算 logic)
  - `fm_voice_data_default` (= 25 byte voice、 既流用済の値)
- `src/driver/ADPCMB_DRV.inc`:
  - `adpcmb_keyon` の chip register write 列 (= port B 0x10-0x1F)
  - sample address / stop address / delta-N / volume の値
- `vendor/ngdevkit/nullsound/timer.s` (= TIMER-B init の reference、 ただし自作)

### 改造 MAME trace harness (= verification 用)
- `vendor/mame-fork/neogeo` binary
- `bash scripts/run-mame.sh --gamerom lastbld2 --trace` で起動 + trace 出力

## 4. 設計

### 4.1 Z80 SRAM layout (= 0xF800-0xFFFF)

```
0xF800 - 0xF80F  cmd FIFO (= 16 byte ringbuffer、 head/tail 1 byte ずつ + 14 byte buffer)
                 ※ standalone PoC phase 2 では cmd FIFO は使わず NMI 内で即 dispatch、
                   将来 phase で使う領域として確保
0xF810 - 0xF81F  driver state (= 16 byte):
                   driver_state_init_flag      .ds 1   (= 0xF810、 NMI 初回 marker)
                   driver_song_ready           .ds 1   (= 0xF811、 cmd 2 で 1 set)
                   driver_adpcmb_done_flag     .ds 1   (= 0xF812、 cmd 5 idempotent)
                   scale_step                  .ds 1   (= 0xF813、 0..8)
                   scale_tick_lo               .ds 1   (= 0xF814、 IRQ count down lower)
                   scale_tick_hi               .ds 1   (= 0xF815、 上位)
                   pmdneo_irq_count            .ds 2   (= 0xF816-0xF817、 TIMER-B IRQ 累積)
                   reserved                    .ds 8   (= 0xF818-0xF81F)
0xF820 - 0xFFBF  scratch (= 1440 byte 余裕、 後続 phase で part_workarea 等)
0xFFC0 - 0xFFFF  Z80 stack (= 64 byte、 ld sp, #0xFFFF 起点)
                 ※ 0xFFFE/0xFFFF は SM1 BIOS 作業領域、 driver state 配置禁止
                   (= memory `project_neogeo_sm1_bios_workarea_collision.md`)
```

driver state は ABS 配置 (= `.equ` で絶対 address 定義) で linker 不確定要素を排除。

### 4.2 NMI handler (= 0x0066)

```asm
.org 0x0066
    push af
    push bc
    push hl
    in   a, (0x00)         ; PORT_FROM_68K = cmd byte

    ;; cmd dispatch (= simple compare、 FIFO 不使用)
    cp   #2
    jp   z, nmi_cmd_2_play_song
    cp   #5
    jp   z, nmi_cmd_5_adpcmb_beat
    ;; cmd 3 (= reset) は無視 (= 副作用なしで脱出)
    ;; その他 cmd も無視

nmi_done:
    pop  hl
    pop  bc
    pop  af
    retn

nmi_cmd_2_play_song:
    ;; idempotent: 毎 cmd 2 で実行されても OK
    ;; chip ch 2 voice setup (= 30 register write inline、 既存)
    call init_chip_ch2_voice    ; voice + PAN + 初期 fnum (C4) 設定
    ;; scale_step = 0、 scale_tick = SCALE_TICK_INITIAL、 driver_song_ready = 1
    xor  a
    ld   (scale_step), a
    ld   hl, #SCALE_TICK_INITIAL
    ld   (scale_tick_lo), hl
    ld   a, #1
    ld   (driver_song_ready), a
    ;; 初回 note (= scale_notes_fm[0] = 0x40 = C4) で keyon
    ld   a, #0x40
    call fnumset_fm_ch2
    ld   a, #0xF1
    out  (4), a              ; 0x28 = ch 2 keyon
    ;; ... port A 0x28 への out (= 既存 ld a,#0x28; out (4),a; nop x6; ld a,#0xF1; out (5),a)
    jp   nmi_done

nmi_cmd_5_adpcmb_beat:
    ;; idempotent guard
    ld   a, (driver_adpcmb_done_flag)
    or   a
    jp   nz, nmi_done
    ld   a, #1
    ld   (driver_adpcmb_done_flag), a
    ;; ADPCM-B chip register write (= port B 0x10-0x1F、 inline)
    call init_adpcmb_beat
    jp   nmi_done
```

注: `cp #3` 別途 handle 不要 (= cmd 3 が来ても dispatch なし、 副作用なし)。

### 4.3 TIMER-B IRQ handler (= 0x0038)

```asm
.org 0x0038
    push af
    push hl

    ;; pmdneo_irq_count++
    ld   hl, (pmdneo_irq_count)
    inc  hl
    ld   (pmdneo_irq_count), hl

    ;; driver_song_ready = 1 でなければ何もしない
    ld   a, (driver_song_ready)
    or   a
    jr   z, irq_done

    ;; scale_tick decrement (16 bit)
    ld   hl, (scale_tick_lo)
    ld   a, h
    or   l
    jr   z, irq_scale_step    ; tick 0 → 次 step
    dec  hl
    ld   (scale_tick_lo), hl
    jr   irq_done

irq_scale_step:
    ;; scale_step++
    ld   a, (scale_step)
    inc  a
    ld   (scale_step), a
    cp   #8
    jr   nc, irq_scale_end    ; 8 で終了

    ;; chip ch 2 keyoff → 次 note keyon
    ld   a, #0x01
    out  (4), a               ; 0x28 ch 2 keyoff register address
    nop x 6
    ld   a, #0x01
    out  (5), a               ; ch 2 keyoff value (= slot mask 0)
    
    ;; scale_notes_fm[scale_step] を fnumset + keyon
    ld   a, (scale_step)
    ld   hl, #scale_notes_fm
    add  hl, a
    ld   a, (hl)
    call fnumset_fm_ch2
    ;; keyon (= 0x28 = 0xF1)
    ...

    ;; scale_tick reset
    ld   hl, #SCALE_TICK_INITIAL
    ld   (scale_tick_lo), hl
    jr   irq_done

irq_scale_end:
    ;; chip ch 2 全 op keyoff
    ld   a, #0x01
    out  (4), a
    nop x 6
    ld   a, #0x01
    out  (5), a
    xor  a
    ld   (driver_song_ready), a

irq_done:
    pop  hl
    pop  af
    ei
    reti
```

`SCALE_TICK_INITIAL` = 約 500 (= 約 0.5 秒、 TIMER-B 1ms × 500)。 user 聴感で調整 (= 体感 tempo 適切な値)。

### 4.4 TIMER-B init

NMI cmd 2 dispatch 内 or cold start で TIMER-B 起動:
- 0x27 |= 0x40 (= multi-freq mode)
- 0x26 = 0xFC (= TIMER-B counter、 NEOGEO M1 4 MHz で約 1ms IRQ)
- 0x27 |= 0x02 (= TIMER-B start)
- ei (= IRQ enable、 IM 1 既定)

cold start で init は user 聴感 影響なし、 idempotent で毎 NMI で OK。 ただし重複 init 副作用 (= TIMER-B counter reset) を避けるため driver_state_init_flag で 1 回だけ init するのが筋。

### 4.5 chip helper (= ym2610_write_port_a/b)

`.area _HEADER (ABS)` 内 `.org 0x0200` (= NMI handler の後の安全 ROM area) に subroutine 配置:
```asm
.org 0x0200
ym2610_write_port_a:
    ld   a, b
    out  (4), a
    nop x 6
    ld   a, c
    out  (5), a
    ret

ym2610_write_port_b:
    ld   a, b
    out  (6), a
    nop x 6
    ld   a, c
    out  (7), a
    ret
```

`.area _HEADER` 内 ABS 配置 = linker 配置不確定要素なし、 standalone_test.s で経験した「`.area CODE` が SRAM に流れる」 trap 回避。

### 4.6 fnumset_fm_ch2 (= chip ch 2 専用、 自作)

PMD_Z80.inc の `fnumset_fm` を読んで chip ch 2 (= ch index 1、 port A、 register suffix +1) hardcoded 版を inline で書く。 値は `fnum_data` table を inline `.db` で取り込み:

```asm
.org 0x0220
fnumset_fm_ch2:
    ;; A = note byte (= OCT << 4 | ONKAI)
    push af
    push de
    and  #0x0F                ; ONKAI 0..11
    ld   hl, #fnum_data
    ld   e, a
    ld   d, #0
    add  hl, de               ; HL = fnum_data + ONKAI*2
    add  hl, de
    ld   e, (hl)
    inc  hl
    ld   d, (hl)              ; DE = base fnum
    pop  af
    pop  af                   ; restore A = note byte (caller's responsibility)
    rrca
    rrca
    rrca
    rrca                      ; A = OCT
    and  #0x07
    add  a, a
    add  a, a
    add  a, a                 ; A = block << 3
    ld   l, a
    ld   a, d
    and  #0x07
    or   l                    ; A = block + fnum upper
    ld   h, a
    ;; 0xA1 (lower) → 0xA5 (upper) の順 (= spec 通り、 MAME 両順 OK 確認済)
    ld   b, #0xA1
    ld   c, e
    call ym2610_write_port_a
    ld   b, #0xA5
    ld   c, h
    call ym2610_write_port_a
    ret

fnum_data:
    .dw  0x026A   ; ONKAI 0  = C
    .dw  0x028F   ; ONKAI 1  = C#
    .dw  0x02B6   ; ONKAI 2  = D
    .dw  0x02DF   ; ONKAI 3  = D#
    .dw  0x030B   ; ONKAI 4  = E
    .dw  0x0339   ; ONKAI 5  = F
    .dw  0x036A   ; ONKAI 6  = F#
    .dw  0x039E   ; ONKAI 7  = G
    .dw  0x03D5   ; ONKAI 8  = G#
    .dw  0x0410   ; ONKAI 9  = A
    .dw  0x044E   ; ONKAI 10 = A#
    .dw  0x048F   ; ONKAI 11 = B

scale_notes_fm:
    .db  0x40, 0x42, 0x44, 0x45, 0x47, 0x49, 0x4B, 0x50
```

### 4.7 ADPCM-B beat (= cmd 5)

ADPCMB_DRV.inc + samples-map.yaml を読んで beat sample の start/stop address を特定、 以下の register write を inline で:

```asm
init_adpcmb_beat:
    ;; ADPCM-B port B 0x10-0x1F の register write
    ;; 0x10: control (= 0x00 = playback)
    ;; 0x11: L+R output (= 0xC0)
    ;; 0x12-0x13: start address LSB/MSB (= sample 起点 / 256)
    ;; 0x14-0x15: stop address LSB/MSB
    ;; 0x19-0x1A: delta-N (= playback frequency)
    ;; 0x1B: volume (= 0xFF)
    ;; 0x10: trigger (= 0x80 = keyon)
    ;; 値は ADPCMB_DRV.inc から読取り
    ...
    ret
```

Codex に ADPCMB_DRV.inc の adpcmb_keyon を読ませて等価 inline 版を実装委譲。

### 4.8 cold start (= 0x0000)

```asm
.org 0x0000
    di
    im   1
    ld   sp, #0xFFFF
    xor  a
    out  (0x08), a            ; PORT_ENABLE_NMI
    ;; driver state RAM clear
    ld   hl, #0xF810
    ld   bc, #0x0010          ; 16 byte
    xor  a
clear_loop:
    ld   (hl), a
    inc  hl
    dec  bc
    ld   a, b
    or   c
    jr   nz, clear_loop
    ;; TIMER-B init
    ld   b, #0x27
    ld   c, #0x40
    call ym2610_write_port_a
    ld   b, #0x26
    ld   c, #0xFC
    call ym2610_write_port_a
    ld   b, #0x27
    ld   c, #0x42             ; multi-freq + TIMER-B start
    call ym2610_write_port_a
    ei
idle_loop:
    jp   idle_loop
```

ただし `call` は ABS 0x0000 area 内で使えるか要確認 (= sdas-z80 syntax で `call` は relocatable target も OK のはず)。 もし問題ある場合は inline `out` で展開。

### 4.9 既存 standalone_test.s からの拡張差分
- 0x0000 cold start: driver state RAM clear + TIMER-B init 追加
- 0x0038 IRQ handler: scale 進行 logic 追加 (= 既存は ei + reti のみ)
- 0x0066 NMI handler: cmd dispatch 追加 (= 既存は無条件 chip init)
- 0x0200+: ym2610_write_port_a/b subroutine 追加
- 0x0220+: fnumset_fm_ch2 + fnum_data + scale_notes_fm 追加
- ADPCM-B beat 関連 inline 追加
- driver state symbol (= `.equ` で 0xF810 起点)

## 5. 実装 step (= Codex に渡す段階)

各 step で build pass + xxd 確認:

| step | 内容 | 検証 |
|---|---|---|
| 1 | driver state symbol 定義 + 0x0000 RAM clear + TIMER-B init | xxd 0x0000 で di + im 1 + ld sp + RAM clear loop + chip register write |
| 2 | 0x0038 IRQ handler 拡張 (= scale_tick decrement + scale_step++) | xxd 0x0038、 改造 MAME trace で pmdneo_irq_count 増加 |
| 3 | ym2610_write_port_a/b subroutine + fnumset_fm_ch2 + fnum_data + scale_notes_fm | xxd 0x0200 / 0x0220 |
| 4 | 0x0066 NMI handler に cmd dispatch (= cmd 2 + cmd 5) | xxd 0x0066、 cmd 別 jp |
| 5 | cmd 2 NMI で voice setup + scale_step init + driver_song_ready=1 | trace で chip ch 2 voice + 0xA1/0xA5 + 0x28=0xF1 |
| 6 | cmd 5 NMI で ADPCM-B beat inline (= port B 0x10-0x1F) | trace で port B 0x10-0x1B write |
| 7 | scale 進行で 8 keyon + 7 keyoff + final keyoff | trace で 0x28=0xF1 ×8 + 0x28=0x01 ×8、 fnum 8 種類 |
| 8 | build + 改造 MAME trace + user 聴感確認 | ymfm-trace 全数解析 |

## 6. 検証 (= 動作 OK 判定)

### 改造 MAME trace で確認すべき event
- ymfm-trace.tsv:
  - chip ch 2 voice setup (= 0x31, 0x35, ..., 0x9D 30 register、 cmd 2 NMI 時 1 回 or 毎回 idempotent)
  - **0xA1 (= fnum lower) と 0xA5 (= fnum upper)** が 8 種類の値で書込 (= scale 8 note 進行)
  - **0x28 = 0xF1** が **8 回**(= 各 note keyon)
  - **0x28 = 0x01** が **少なくとも 7 回**(= note 切替時 keyoff)
  - port B 0x10 (= ADPCM-B trigger) が 1 回 (= cmd 5 beat)
  - port B 0x12-0x15 (= ADPCM-B start/stop address) write
- z80-mem-trace.tsv:
  - 0xF816/0xF817 (= pmdneo_irq_count) が連続 increment
  - 0xF813 (= scale_step) が 0 → 1 → ... → 8 で進行
  - 0xF814/0xF815 (= scale_tick) が SCALE_TICK_INITIAL → 0 → reset 反復

### user 聴感
- ADPCM-B beat 1 回 (= 鋭い打撃音)
- chip ch 2 で ドレミファソラシド 8 note scale が約 0.5 秒間隔で進行
- 最後の C5 後に silent

## 7. Codex 委譲 prompt 要件

- **目的**: 上記 4-5 章の設計を `src/driver/standalone_test.s` 拡張で実装
- **既存 base**: standalone_test.s (= commit `0e74ec8`)
- **流用**:
  - chip ch 2 voice register 列 (= 既存 30 register write inline、 cmd 2 NMI 内に再配置)
  - PMD_Z80.inc の `scale_notes_fm` / `fnum_data` 値を inline `.db / .dw` で書き写す
  - ADPCMB_DRV.inc の `adpcmb_keyon` chip register write 列を inline 化
- **追加実装**:
  - driver state symbol (= `.equ` 起点 0xF810)
  - 0x0000 RAM clear + TIMER-B init
  - 0x0038 IRQ handler 拡張 (= scale 進行)
  - 0x0066 NMI handler に cmd dispatch
  - 0x0200+ chip helper subroutine
  - 0x0220+ fnumset_fm_ch2 + fnum_data + scale_notes_fm
- **build verification**: `make poc` pass + xxd で各 area 配置確認
- **trace verification**: 改造 MAME で ymfm-trace 検証
- **scope 厳守**: 上記 step 1-8 のみ、 LFO / ADPCM-A / cmd FIFO ringbuffer は範囲外

## 8. Critical files

- 拡張対象: `/Users/koshikawamasato/Projects/pmdneo/src/driver/standalone_test.s`
- 参照 (= 値読取): 
  - `/Users/koshikawamasato/Projects/pmdneo/src/driver/PMD_Z80.inc`
  - `/Users/koshikawamasato/Projects/pmdneo/src/driver/ADPCMB_DRV.inc`
  - `/Users/koshikawamasato/Projects/pmdneo/src/driver/REGMAP.inc`
  - `/Users/koshikawamasato/Projects/pmdneo/vendor/ngdevkit-examples/00-template/assets/samples-map.yaml`
- 不変: `vendor/ngdevkit-examples/00-template/build.mk` (= make poc target、 修正不要)
- 不変: `vendor/ngdevkit-examples/00-template/main.c` (= cmd 3/5/2 発火を維持)

## 9. Out of scope

- LFO / vibrato / portamento (= Phase 2 SubG)
- ADPCM-A 6 ch driver (= Phase 3)
- cmd FIFO ringbuffer (= 設計書 5.2 の本格実装、 本 PoC では NMI 内即 dispatch で代用)
- 音色 (= voice) の動的変更 (= 1 voice 固定)
- audio gate workflow 再構築 (= 自作 driver 完成後の Phase)
- main.c の cmd 発火変更 (= 既存維持)

## 10. 完了後の次 step (= 別 plan)

- 設計書 8 step migration の残り (= ADPCM-A、 SubF-1 fixture、 fmmain 統合)
- audio gate workflow を自作 driver 用に再設計
- ADR-0003 supersede / amendment 判断 (= user 判断保留事項)
- stash@{0} 処分 (= user 判断保留事項)
