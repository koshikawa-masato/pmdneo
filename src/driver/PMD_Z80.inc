;;;
;;; PMD_Z80.inc
;;; PMD V4.8s の Z80 化 base driver
;;;
;;; PMD.ASM (10864 行 x86 アセンブリ) を NEOGEO Z80 環境に移植する base
;;; module。 PMDPPZ.ASM が PMD.ASM を include する流儀を踏襲して、
;;; PMDNEO.s が flag を立てて本 file を include する。
;;;
;;; SubB-1: pmdneo_init (= SSG silent init) を実装
;;; SubB-2: TIMER-B 起動 + pmdneo_irq_count
;;; SubB-3: test_play_c4 (= 最初の音発生)
;;; SubB-4: psg_tune_data + fnumsetp + 1 octave スケール再生
;;;
;;; nullsound 公式 chip 駆動 calling convention:
;;;   ym2610_write_port_a / port_b: B = register、 C = data
;;;

        .area CODE


;;; ----- pmdneo_init: driver 起動時の SSG silent init + TIMER-B 起動 -----
;;;
;;; SubB-1: SSG mixer + volume init
;;; SubB-2: TIMER-B 起動
;;; SubB-4: scale 演奏 state も init

pmdneo_init::
        ;; SSG mixer (0x07) = 0x38 (tone 3 ch enable + noise all disable)
        ld      b, #REG_SSG_ENABLE
        ld      c, #0x38
        call    ym2610_write_port_a

        ;; SSG volume A = 0x00 (mute、 後で test_play_scale で 0x0F に上げる)
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x00
        call    ym2610_write_port_a

        ;; SSG volume B = 0x00
        ld      b, #REG_SSG_B_VOLUME
        ld      c, #0x00
        call    ym2610_write_port_a

        ;; SSG volume C = 0x00
        ld      b, #REG_SSG_C_VOLUME
        ld      c, #0x00
        call    ym2610_write_port_a

        ;; pmdneo_irq_count = 0
        ld      hl, #0
        ld      (pmdneo_irq_count), hl

        ;; SubB-4: scale state init
        xor     a
        ld      (scale_step), a

        ld      a, #SCALE_TICK_INITIAL
        ld      (scale_tick), a

        ;; TIMER-B counter (0x26) = 0xC0 (= 約 488 µs 周期、 ≈ 2050 Hz)
        ld      b, #REG_TIMER_B_COUNTER
        ld      c, #0xC0
        call    ym2610_write_port_a

        ;; TIMER-B enable + IRQ enable + reset (0x2A)
        ld      b, #REG_TIMER_FLAGS
        ld      c, #0x2A
        call    ym2610_write_port_a

        ;; SubB-4 修正: Z80 IRQ enable
        ;; nullsound default は IRQ disable で snd_mainloop polling (= 06-sound-adpcma
        ;; 等は IRQ 不要)。 PMDNEO は TIMER-B IRQ で per-tick 駆動するため、
        ;; user 側で明示的に ei が必要。
        ;; 経路: 0x0038 IRQ handler (entrypoint.s) → update_timer_state_tracker
        ;; → state_timer_tick_reached set。 PMDNEO の polling loop はこれを待つ。
        ei

        ret


;;; ----- pmd_z80_main: TIMER-B tick で呼ばれる main 処理 -----
;;;
;;; SubB-2: pmdneo_irq_count を 16-bit increment
;;; SubB-4: scale_tick を decrement、 0 になったら次 step へ進む

pmd_z80_main::
        ;; pmdneo_irq_count++ (= 動作証跡)
        ld      hl, (pmdneo_irq_count)
        inc     hl
        ld      (pmdneo_irq_count), hl

        ;; scale_tick decrement
        ld      a, (scale_tick)
        dec     a
        ld      (scale_tick), a
        or      a
        ret     nz                      ; tick 残ってる → return

        ;; tick 0 → 次 step に進む
        ld      a, (scale_step)
        cp      #8
        ret     nc                      ; 8 step 終わった → return (= 最後の音保持)

        ;; scale_notes[scale_step] を fnumsetp で発音
        ld      hl, #scale_notes
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      a, (hl)
        call    fnumsetp

        ;; scale_step++
        ld      a, (scale_step)
        inc     a
        ld      (scale_step), a

        ;; scale_tick reset
        ld      a, #SCALE_TICK_INITIAL
        ld      (scale_tick), a

        ret


;;; ----- fnumsetp: note byte → SSG ch A fine/coarse tune -----
;;;
;;; 入力: A = note byte (= OCT 4 bit 上位 + ONKAI 4 bit 下位)
;;; 動作:
;;;   1. ONKAI で psg_tune_data[ONKAI × 2] (= OCT 0 ベース 16-bit freq) を取得
;;;   2. OCT 回 right shift (= 1 octave あたり counter / 2)
;;;   3. SSG ch A fine tune (LSB) + coarse tune (MSB) に書込
;;; 破壊: A、 B、 C、 D、 E、 H、 L

fnumsetp::
        push    af                      ; note byte 保存

        ;; ONKAI を取り出して psg_tune_data の index に
        and     #0x0F
        ld      l, a
        ld      h, #0
        add     hl, hl                  ; HL = ONKAI × 2
        ld      bc, #psg_tune_data
        add     hl, bc                  ; HL = &psg_tune_data[ONKAI × 2]

        ;; DE = (HL) (= 16-bit freq base、 LE)
        ld      e, (hl)
        inc     hl
        ld      d, (hl)

        ;; OCT を取り出し (note byte の上位 4 bit)
        pop     af
        rrca
        rrca
        rrca
        rrca
        and     #0x0F                   ; A = OCT (0-15)

        ;; DE を A 回 right shift (= 1 octave あたり 2 倍 freq)
        or      a
        jr      z, fnumsetp_set         ; OCT 0 → shift しない
fnumsetp_shift:
        srl     d
        rr      e
        dec     a
        jr      nz, fnumsetp_shift

fnumsetp_set:
        ;; SSG ch A fine tune (0x00) = E (LSB)
        ld      b, #REG_SSG_A_FINE_TUNE
        ld      c, e
        call    ym2610_write_port_a

        ;; SSG ch A coarse tune (0x01) = D (MSB)
        ld      b, #REG_SSG_A_COARSE_TUNE
        ld      c, d
        call    ym2610_write_port_a

        ret


;;; ----- test_play_scale: SubB-4 1 octave スケール演奏開始 -----
;;;
;;; pmd_z80_main 内で TIMER-B tick 毎に scale_tick を decrement、
;;; 0 になったら scale_notes[scale_step] を発音、 scale_step++、
;;; tick reset。 8 step (= ドレミファソラシド) で end (= 最後の音保持)。
;;;
;;; SubB-4 では SSG ch A のみ。 mixer (0x38) + volume A (0x0F) を最初に
;;; set してから最初の note を発音 (= scale_step = 0 から開始)。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L

test_play_scale::
        ;; SSG volume A = 0x0F (max)
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x0F
        call    ym2610_write_port_a

        ;; 最初の note (scale_notes[0]) を発音
        ld      a, (scale_notes)
        call    fnumsetp

        ;; scale_step = 1 (次は scale_notes[1])
        ld      a, #1
        ld      (scale_step), a

        ;; scale_tick reset (次の note までの時間)
        ld      a, #SCALE_TICK_INITIAL
        ld      (scale_tick), a

        ret


;;; ----- psg_tune_data: 12 半音 × 2 byte (LE)、 OCT 0 ベース counter 値 -----
;;;
;;; PMD V4.8s 公式 psg_tune_data (= analysis_m_data_structure.md §5-1-1)。
;;; YM2610 SSG counter = freq_clock / (16 × n)、 n = 12-bit value。
;;; OCT 0 = 約 130 Hz (= C3)、 OCT 1 = freq × 2 = C4、 OCT 2 = C5、 ...

        .area CODE

psg_tune_data::
        .dw     0x0EE8                  ; ONKAI 0  = C   (C3 ≈ 131 Hz)
        .dw     0x0E12                  ; ONKAI 1  = C# (D♭)
        .dw     0x0D48                  ; ONKAI 2  = D
        .dw     0x0C89                  ; ONKAI 3  = D# (E♭)
        .dw     0x0BD5                  ; ONKAI 4  = E
        .dw     0x0B2B                  ; ONKAI 5  = F
        .dw     0x0A8A                  ; ONKAI 6  = F# (G♭)
        .dw     0x09F3                  ; ONKAI 7  = G
        .dw     0x0964                  ; ONKAI 8  = G# (A♭)
        .dw     0x08DD                  ; ONKAI 9  = A
        .dw     0x085E                  ; ONKAI 10 = A# (B♭)
        .dw     0x07E6                  ; ONKAI 11 = B


;;; ----- scale_notes: 1 octave スケール (= ドレミファソラシド) -----
;;;
;;; OCT 1 (= C4 帯域、 約 261 Hz 起点) で 8 個の note。
;;; note byte format: 上位 4 bit OCT + 下位 4 bit ONKAI。
;;; 0x10 = OCT 1 + ONKAI 0 (C4 = ド)
;;; 0x12 = OCT 1 + ONKAI 2 (D4 = レ)
;;; 0x14 = OCT 1 + ONKAI 4 (E4 = ミ)
;;; 0x15 = OCT 1 + ONKAI 5 (F4 = ファ)
;;; 0x17 = OCT 1 + ONKAI 7 (G4 = ソ)
;;; 0x19 = OCT 1 + ONKAI 9 (A4 = ラ)
;;; 0x1B = OCT 1 + ONKAI 11 (B4 = シ)
;;; 0x20 = OCT 2 + ONKAI 0 (C5 = 1 octave 上のド)

scale_notes::
        .db     0x10, 0x12, 0x14, 0x15, 0x17, 0x19, 0x1B, 0x20


;;; ----- SCALE_TICK_INITIAL: 各 note の duration (= TIMER-B tick 数) -----
;;;
;;; TIMER-B 周期 ≈ 488 µs。 256 tick ≈ 125 ms。
;;; SubB-4 では 0xFF (= 255 tick ≈ 125 ms) を 1 note の duration にする。
;;; 8 note × 125 ms = 1 sec のスケール。

SCALE_TICK_INITIAL = 0xFF
