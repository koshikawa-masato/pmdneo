# SubF-1 — tempo / loop / fade 本実装

	位置付け: Phase 2 SubF 段階分割の 1 番目 (= SubB-7 から先送りされた item)
	書き手: Claude Code
	実装担当: Codex (= codex:codex-rescue agent 経由)
	状態: handoff 待ち

---

## 0. 役割分担

- Claude Code: 設計、 review
- Codex: 実装、 build pass まで
- user: judgment、 audio gate

---

## 1. 背景

### 1-1. Codex verifier (a0d84dc) 指摘

> 隠れた課題:
> - フェードは引数スキップのみ (= fade_set / snd_command_04 ともに即 ret)
> - 音長・テンポ変換が暫定実装 (= ×8 倍 scale 固定、 comt で TIMER-B 反映なし)
> - Step 5 (= 長尺 FM/SSG/ADPCM-B + tempo + loop + fade) 未実走

phase2_driver_plan.md §7-5 の Phase 2 完成基準達成のため、 これら 3 機能の
本実装が必要。

### 1-2. SubE-2 完了 (commit 91e5fca)

Part J ADPCM-B が song 経路に統合済。 Phase 2 機能 coverage は FM 4 ch +
SSG 3 ch + ADPCM-B 1 ch + K stub の 4 chip 経路全部 song 駆動可能。
残るは tempo / loop / fade。

### 1-3. SubF-1 = tempo + loop + fade 本実装

3 機能を 1 commit で実装。 minimum 動作 (= capability 確認 level) を満たす
だけで良い、 高度品質 (= 滑らかな fade curve 等) は SubE-3 / Phase 3 以降。

---

## 2. 実装内容

### 2-1. tempo: comt cmd で TIMER-B 周期反映

#### 現状

`comt` (= cmd 0xFC) で driver_tempo_d / driver_tempo_48 を set するだけ。
TIMER-B counter (= REG_TIMER_B_COUNTER = 0x26) には反映されない。 つまり
tempo cmd を踏んでも演奏速度は変わらない。

#### 修正

```asm
comt:
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d), a
        ld      (driver_tempo_48), a
        ;; SubF-1: TIMER-B counter (= 0x26) に書込で chip 周期反映
        ld      b, #REG_TIMER_B_COUNTER
        ld      c, a
        call    ym2610_write_port_a
        ret
```

PMD MML `t` 値 (= 通常 75-200 bpm) は **そのまま TIMER-B counter として
書込**(= 簡略 mapping)。 PMD V4.8s の精密な bpm → counter 計算は SubE-3 /
Phase 3 で。 SubF-1 では「tempo cmd で速度変化が聴感確認できる」 が達成
基準。

注意: TIMER-B counter は **8 bit**、 値 0 = 周期 256 cycles、 値 0xFF =
周期 1 cycle。 PMD t 値の解釈は「大 = 速い」、 chip counter は「大 = 速い」
で方向一致 (= 直接書込 OK)。

### 2-2. loop: comedloop / comexloop の RAM counter 実装

#### 現状

- `comstloop` (= 0xF9 [): arg 2 byte 消費 + PART_OFF_LOOP = current ADDR +
  LOOPCNT = 0 (= 既存実装あり、 触らない)
- `comedloop` (= 0xF8 ]): arg 4 byte 消費のみ (= line 1817-1826、
  loop 未実装、 hang up 回避)
- `comexloop` (= 0xF7 :): arg 2 byte 消費 + ret nz (= line 1828-1834、
  loop break 未実装)

#### PMD V4.8s loop spec (推定)

- comedloop ] arg = (loop_count: 1 byte, post_addr_LE: 2 byte)
  - LOOPCNT++ (= PART_OFF_LOOPCNT)
  - LOOPCNT < loop_count なら ADDR = PART_OFF_LOOP (= [ 位置に戻る)
  - 違うなら ADDR = post_addr (= ] の後に飛ぶ、 LOOPCNT は内部 reset)
- comexloop : arg = (loop_count: 1 byte, exit_addr_LE: 2 byte)
  - LOOPCNT + 1 == loop_count なら ADDR = exit_addr (= 最終 iteration で break)
  - 違うなら continue (= : の後に進む)

実 PMD V4.8s spec を確認する余裕があれば確認。 Codex は PMD.ASM
(`/Users/koshikawamasato/Projects/neo-sisters/vendor/pmd48s/source/pmd48s/PMD.ASM`)
の `lopstart` / `loopend` / `loopex` 等を grep で確認すること。

#### 修正

```asm
comedloop:
        call    pmdneo_part_fetch_byte    ; A = loop_count
        ld      b, a
        ld      a, PART_OFF_LOOPCNT(ix)
        inc     a
        ld      PART_OFF_LOOPCNT(ix), a
        cp      b
        jr      nc, comedloop_done        ; LOOPCNT >= count → loop end
        ;; LOOPCNT < count → ADDR = LOOP に戻す
        call    pmdneo_part_fetch_byte    ; post_addr LSB (skip)
        call    pmdneo_part_fetch_byte    ; post_addr MSB (skip)
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ret
comedloop_done:
        ;; LOOPCNT >= count → ADDR = post_addr
        call    pmdneo_part_fetch_byte
        ld      e, a                       ; post_addr LSB
        call    pmdneo_part_fetch_byte
        ld      d, a                       ; post_addr MSB
        ld      hl, (mmlbuf)
        add     hl, de                     ; 絶対 addr = mmlbuf + offset
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        xor     a
        ld      PART_OFF_LOOPCNT(ix), a    ; reset counter for next loop
        ret

comexloop:
        call    pmdneo_part_fetch_byte    ; A = loop_count
        ld      b, a
        ld      a, PART_OFF_LOOPCNT(ix)
        inc     a                          ; 次 iteration で LOOPCNT になる予定
        cp      b
        jr      nz, comexloop_skip
        ;; 次 iteration が最終 → exit_addr へ
        call    pmdneo_part_fetch_byte
        ld      e, a
        call    pmdneo_part_fetch_byte
        ld      d, a
        ld      hl, (mmlbuf)
        add     hl, de
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ret
comexloop_skip:
        call    pmdneo_part_fetch_byte    ; arg 2 byte 消費
        call    pmdneo_part_fetch_byte
        ret
```

**注意**: PMD V4.8s の post_addr / exit_addr は **mmlbuf base からの relative
offset** (= 既存 part offset table と同流儀) と仮定。 ROM ベース絶対 addr
ではない。 mc compiler が relative offset で出力する。 Codex 実装で
mmlbuf base + offset 計算経路を確認すること。

### 2-3. fade: snd_command_04_fade_out の minimum 実装

#### 現状

`snd_command_04_fade_out` (= IRQ.inc) は ret のみ。 `fade_set` (= cmd
0xD2 内 MML) は arg 1 byte 消費のみ。

#### minimum 実装: 全 ch immediate silent

PMD V4.8s 流儀の漸減 fade は SubE-3 / Phase 3 で。 SubF-1 では minimum:

```asm
;; IRQ.inc
snd_command_04_fade_out::
        ;; 全 SSG ch volume 0
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #REG_SSG_B_VOLUME
        call    ym2610_write_port_a
        ld      b, #REG_SSG_C_VOLUME
        call    ym2610_write_port_a

        ;; 全 FM ch keyoff (= 6 ch)
        ld      b, #0
        call    pmdneo_fm_keyoff
        ld      b, #1
        call    pmdneo_fm_keyoff
        ld      b, #2
        call    pmdneo_fm_keyoff
        ld      b, #3
        call    pmdneo_fm_keyoff
        ld      b, #4
        call    pmdneo_fm_keyoff
        ld      b, #5
        call    pmdneo_fm_keyoff

        ;; ADPCM-B stop
        call    adpcmb_keyoff

        ;; driver state を fade=1 にして song 駆動も停止
        ld      a, #1
        ld      (driver_fade_state), a

        ret
```

加えて pmd_z80_main で driver_fade_state == 1 なら song dispatch を skip
(= 全 part halt):

```asm
pmd_z80_main::
        ld      hl, (pmdneo_irq_count)
        inc     hl
        ld      (pmdneo_irq_count), hl

        ;; SubF-1: fade 中なら song dispatch を skip
        ld      a, (driver_fade_state)
        or      a
        ret     nz

        ld      a, (driver_song_ready)
        or      a
        jr      z, pmd_z80_main_scale
        call    pmdneo_song_main
        ret
        ;; ... 既存 scale 経路
```

WORKAREA.inc に `driver_fade_state` (= 1 byte) field を追加。 pmdneo_init
で 0 に初期化。

### 2-4. 試料 MML に loop / tempo を追加

`test_fm_song_part_b` 等を loop で覆う形に変更:

```asm
test_fm_song_part_b:
        ;; SubF-1: tempo 設定 + loop で 2 回繰返
        .db     0xFC, 0xC0              ; comt = 0xC0 (= 速め)
        .db     0xF9, 0x02, 0x00, 0x00  ; comstloop count=2, dummy 2 byte
        ;; loop body (= 既存 8 note × 0x20)
        .db     0x40, 0x20, 0x42, 0x20, 0x44, 0x20, 0x45, 0x20
        .db     0x47, 0x20, 0x49, 0x20, 0x4B, 0x20, 0x50, 0x20
        ;; comedloop arg = (count=2, post_addr_LE)
        .db     0xF8, 0x02
        .dw     test_fm_song_part_b_post - test_fm_song_data
test_fm_song_part_b_post:
        .db     0x80                    ; end
```

注意: comstloop の arg byte 数は PMD V4.8s spec で確認 (= 既存実装は 2 byte
消費している)。 comedloop は count + post_addr で 3 byte。

実装は Codex に PMD.ASM 確認させて適切な arg byte 数を決定。

---

## 3. 前提

### 3-1. 既存実装

- `comt` (= L1781): driver_tempo_d set あり、 TIMER-B 反映なし (= 修正対象)
- `comstloop` (= L1806): arg 2 byte 消費 + LOOP/LOOPCNT init (= 触らない)
- `comedloop` (= L1817): arg 4 byte 消費のみ (= 修正対象)
- `comexloop` (= L1828): arg 2 byte + ret nz (= 修正対象)
- `fade_set` (= L2004): arg 1 byte 消費のみ (= 触らない、 cmd 0xD2 だけで
  fade trigger ではない)
- `snd_command_04_fade_out` (= IRQ.inc L80): ret のみ (= 修正対象)
- `pmd_z80_main` (= L106): scale 経路 / song 経路の二択 (= fade skip 経路追加)

### 3-2. PMD V4.8s 公式 spec

PMD.ASM (`vendor/pmd48s/source/pmd48s/PMD.ASM`) で以下 routine を grep して
arg byte 数 + 動作を確認:
- `lopstart`: comstloop 本実装
- `loopend`: comedloop 本実装
- `loopex`: comexloop 本実装

### 3-3. 規約

- sdasz80 syntax
- 既存 SubA-SubE-2 routine を破壊しない
- 越境禁止: ADPCMB_DRV.inc / Makefile / rom.mk / main.c / KR_STUB.inc は
  touch しない
- WORKAREA.inc: driver_fade_state (= 1 byte) 追加 OK
- IRQ.inc: snd_command_04_fade_out 修正 OK

### 3-4. mmlbuf 経路

post_addr / exit_addr は mmlbuf base からの relative offset。 既存
test_play_fm_song で mmlbuf に test_fm_song_data 先頭 address が格納される。
loop 内で相対 → 絶対 addr 計算は `ld hl, (mmlbuf); add hl, de` で。

---

## 4. 完了基準

### 4-1. build pass

`bash scripts/build-poc.sh` exit 0。

### 4-2. audio gate

期待動作:
- **tempo**: comt cmd で song の演奏速度が変わる (= 試料 MML に comt
  embed)
- **loop**: 試料 MML が loop で繰返再生 (= 例 Part B が 2 回繰返)
- **fade**: cmd 4 発行で song が即停止 (= 全 ch silent、 main.c で cmd 4
  発火追加 はせず、 capability 確認は driver source review で)

合格基準:
- gngeo 起動から song 終了まで、 tempo / loop が聴感で確認できる
- hang up / 異音 なし
- 既存 SubE-2 機能 (= ADPCM-B song 統合) は動作維持

### 4-3. user 報告

- build 結果
- Codex は **commit せず diff のまま終了**
- Claude Code review → user 聴感確認 → commit + push

---

## 5. 注意点

### 5-1. fade 動作の cmd trigger

snd_command_04_fade_out は cmd 4 で trigger。 main.c では現在 cmd 4 発火
していないので、 audio gate での確認方法:
- (a) main.c に cmd 4 発火を一時追加 → 削除する
- (b) driver source review で「fade 経路が正しく定義されている」 ことを確認

判断: (b) source review で済ませる。 main.c は touch しない。

### 5-2. loop 試料設計

loop count = 2 で簡単に確認。 Part B のみ loop、 Part C/E/F は loop なし
で対比。 Part B が 2 回繰返、 他 part が 1 回で全 part 同時終了するように
note 数 / length 調整。

### 5-3. tempo 値

PMD MML `t` 値の標準: 通常 100-150 bpm。 試料では 0xC0 (= 192) で「速め」
設定、 default の 0xC0 (= pmdneo_init で TIMER-B 周期 0xC0) と同じ。 つまり
試料での comt 0xC0 は実質 default 維持、 tempo 変化は確認できない。

修正: 試料 comt を 0x80 (= 128、 default より遅い) に。 pmdneo_init の
default 0xC0 → comt で 0x80 = 周期延長 = 演奏遅くなる。

### 5-4. audio gate 義務

driver/runtime 層 touch なので commit 前 user 聴感確認必須。

---

## 6. 参照

- `src/driver/PMD_Z80.inc` (= comt / comedloop / comexloop / pmd_z80_main /
  test_fm_song_part_b 修正対象)
- `src/driver/IRQ.inc` (= snd_command_04_fade_out 修正対象)
- `src/driver/WORKAREA.inc` (= driver_fade_state field 追加)
- `vendor/pmd48s/source/pmd48s/PMD.ASM` (= PMD V4.8s 公式 spec、 lopstart
  / loopend / loopex / comt routine grep)
- `docs/design/phase2_driver_plan.md` §7-5 (= Phase 2 完成基準)

---

[本書は handoff 待ち。 Auto Mode 継続中、 Claude Code が codex:codex-rescue
agent を Agent tool で起動]
