        .equ    driver_state_init_flag,  0xF810
        .equ    driver_song_ready,       0xF811
        .equ    driver_adpcmb_done_flag, 0xF812
        .equ    scale_step,              0xF813
        .equ    scale_tick_lo,           0xF814
        .equ    scale_tick_hi,           0xF815
        .equ    pmdneo_irq_count,        0xF816

        ;; Phase 3 4ch individual test: 1=ch2(B), 2=ch3(C), 4=ch5(E), 5=ch6(F)
        .equ    TEST_FM_CH_INDEX,        1
        ;; Phase 3 final test:
        ;;   0 = single ch (= TEST_FM_CH_INDEX 経由 scale 進行)
        ;;   1 = 4 ch unison scale (= 4 ch 同 fnum で C-D-E-F-G-A-B-C、 ymfm 特異で ch 3/5/6 silent)
        ;;   2 = 4 ch chord 持続 (= C-E-G-C 別 fnum で 4 ch 同時 keyon、 持続音、 SubC-3 既往実績類)
        ;;   3 = 4 ch chord progression scale (= I-ii-iii-IV-V-vi-vii-I, ch2 root/ch3 3rd/ch5 5th/ch6 octave)
        .equ    TEST_MODE_CHORD,         3

;;; ----- per-part workarea field offsets -----

        .equ    PART_OFF_ADDR,           0
        .equ    PART_OFF_LOOP,           2
        .equ    PART_OFF_LEN,            4
        .equ    PART_OFF_QDATA,          5
        .equ    PART_OFF_QDATB,          6
        .equ    PART_OFF_VOLUME,         7
        .equ    PART_OFF_SHIFT,          8
        .equ    PART_OFF_NOTE,           9
        .equ    PART_OFF_LOOPCNT,        10
        .equ    PART_OFF_LFOSWI,         11
        .equ    PART_OFF_TIEFLAG,        12
        .equ    PART_OFF_FNUM,           13
        .equ    PART_OFF_PAN,            15
        .equ    PART_OFF_DETUNE,         16
        .equ    PART_OFF_VOICE,          17
        .equ    PART_OFF_FLAGS,          18
        ;; reserved 19-23 (5 bytes padding)
        .equ    PART_WORKAREA_SIZE,      24

;;; ----- part number constants -----

        .equ    PART_FM1,                0    ;; A
        .equ    PART_FM2,                1    ;; B (= chip ch 2 = audible)
        .equ    PART_FM3,                2    ;; C
        .equ    PART_FM4,                3    ;; D (chip ch 4 = mute on YM2610)
        .equ    PART_FM5,                4    ;; E
        .equ    PART_FM6,                5    ;; F
        .equ    PART_SSG1,               6    ;; G
        .equ    PART_SSG2,               7    ;; H
        .equ    PART_SSG3,               8    ;; I
        .equ    PART_PCM,                9    ;; J (= ADPCM-B)
        .equ    PART_RHYTHM,             10   ;; K (= no-op stub on PMDNEO)
        .equ    PART_ADPCMA1,            11   ;; L
        .equ    PART_ADPCMA2,            12   ;; M
        .equ    PART_ADPCMA3,            13   ;; N
        .equ    PART_ADPCMA4,            14   ;; O
        .equ    PART_ADPCMA5,            15   ;; P
        .equ    PART_ADPCMA6,            16   ;; Q
        .equ    PART_COUNT,              17

        .equ    part_workarea,           0xF820
        ;; 17 x 24 = 408 bytes occupies 0xF820-0xF9C7

;;; ----- Z80 SRAM layout (= 2 KB at 0xF800-0xFFFF) -----
;;;
;;;   0xF800 - 0xF80F   reserved future (16 bytes、cmd FIFO 検討中)
;;;   0xF810 - 0xF81F   driver_state (= 16 bytes 既存)
;;;   0xF820 - 0xF9C7   part_workarea (= 17 x 24 = 408 bytes、Phase 1 新規)
;;;   0xF9C8 - 0xFFBF   free / 後続 phase 用 (= 1528 bytes 余裕)
;;;   0xFFC0 - 0xFFFF   Z80 stack (= 64 bytes 既存、ld sp, #0xFFFF 起点)
;;;
;;;   ※ 0xFFFE/0xFFFF は SM1 BIOS 作業領域、driver state 配置禁止。

        .equ    SCALE_TICK_INITIAL,      0x01F4

        .area _HEADER (ABS)

        .org 0x0000
        di
        im      1
        ld      sp, #0xFFFF
        xor     a
        out     (0x08), a
idle_loop:
        jp      idle_loop

        .org 0x0038
        jp      irq_handler_body

        .org 0x0066
        ;; NMI handler at 0x0066: idempotent command dispatch.
        push    af
        push    bc
        push    de
        push    hl

        ld      a, (driver_state_init_flag)
        or      a
        jr      nz, nmi_dispatch

        ld      a, #1
        ld      (driver_state_init_flag), a
        xor     a
        ld      hl, #driver_song_ready
        ld      b, #0x0F
nmi_clear_driver_state:
        ld      (hl), a
        inc     hl
        djnz    nmi_clear_driver_state

        ;; ★ 0x27 bit 6 (= multi-freq mode for ch 3) を立てると ch 3 通常 fnum
        ;;   (0xA2/0xA6) が無効化、 4 OP 個別 fnum (0xA8-0xAF) 必要に。 PMDNEO は
        ;;   通常 fnum 経路で chip ch 3 を駆動するため bit 6 クリア。
        ;;   2026-05-09 user 「B + ADPCM のみ」 audio 報告 + Codex 解析で発見。
        ld      b, #0x27
        ld      c, #0x00                ; multi-freq disable + TIMER 全 reset
        call    ym2610_write_port_a
        ld      b, #0x26
        ld      c, #0xFC                ; TIMER-B counter
        call    ym2610_write_port_a
        ld      b, #0x27
        ld      c, #0x2A                ; TIMER-B reset(b1) + IRQ enable(b3) + run(b5)、 multi-freq disable
        call    ym2610_write_port_a

nmi_dispatch:
        in      a, (0x00)
        cp      #2
        jp      z, nmi_cmd_2_play_song
        cp      #5
        jp      z, nmi_cmd_5_adpcmb_beat
        jp      nmi_done

nmi_done:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        retn

nmi_cmd_2_play_song:
        call    init_chip_ch2_voice

        xor     a
        ld      (scale_step), a
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        .if TEST_MODE_CHORD == 3
        ;; Phase 3 final test mode 3: 4 ch chord progression scale.
        ld      a, #1
        ld      (driver_song_ready), a
        ld      a, #0x40                ; ch2 root C4
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        ld      a, #0x44                ; ch3 3rd E4
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        ld      a, #0x47                ; ch5 5th G4
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        ld      a, #0x50                ; ch6 octave C5
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        .else
        .if TEST_MODE_CHORD == 2
        ;; ★ Phase 3 final test mode 2: 4 和音 chord 持続 (= per-ch 別 fnum、 SubC-3 既往実績類)
        ;;   chip ch 2 = C4 (0x40)、 ch 3 = E4 (0x44)、 ch 5 = G4 (0x47)、 ch 6 = C5 (0x50)
        ;;   driver_song_ready = 0 で IRQ scale 進行 抑止、 持続音
        xor     a
        ld      (driver_song_ready), a
        ld      a, #0x40                ; C4
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        ld      a, #0x44                ; E4
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        ld      a, #0x47                ; G4
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        ld      a, #0x50                ; C5
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        .else
        .if TEST_MODE_CHORD == 1
        ;; ★ Phase 3 final test mode 1: 4 和音 unison scale (= 4 ch 同 fnum、 ymfm 特異で ch 3/5/6 silent)
        ld      a, #1
        ld      (driver_song_ready), a
        ld      a, #0x40
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        ld      a, #0x40
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        ld      a, #0x40
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        ld      a, #0x40
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        .else
        ;; 単音 mode (= TEST_FM_CH_INDEX で 1 ch 選択 + scale 進行)
        ld      a, #1
        ld      (driver_song_ready), a
        ld      a, #0x40                ; C4 note byte
        ld      b, #TEST_FM_CH_INDEX
        call    fnumset_fm
        ld      b, #TEST_FM_CH_INDEX
        call    fm_keyon
        .endif
        .endif
        .endif
        jp      nmi_done

nmi_cmd_5_adpcmb_beat:
        ld      a, (driver_adpcmb_done_flag)
        or      a
        jp      nz, nmi_done
        call    init_adpcmb_beat
        ld      a, #1
        ld      (driver_adpcmb_done_flag), a
        jp      nmi_done

        .org 0x0100
irq_handler_body:
        push    af
        push    bc
        push    de
        push    hl

        ld      b, #0x27
        ld      c, #0x2A                ; TIMER-B re-arm (multi-freq disable for ch 3 fnum)
        call    ym2610_write_port_a

        ld      hl, (pmdneo_irq_count)
        inc     hl
        ld      (pmdneo_irq_count), hl

        ld      a, (driver_song_ready)
        or      a
        jp      z, irq_done

        ld      hl, (scale_tick_lo)
        ld      a, h
        or      l
        jr      z, irq_scale_step_next
        dec     hl
        ld      (scale_tick_lo), hl
        jp      irq_done

irq_scale_step_next:
        ld      a, (scale_step)
        inc     a
        ld      (scale_step), a
        cp      #8
        jp      nc, irq_scale_end

        ;; ★ note 切替時 必ず keyoff → 新 fnum → keyon (= envelope edge trigger)
        ;;   2026-05-09 user 「note 順序が出鱈目」 audio 解析で keyoff 中間欠落確認。
        .if TEST_MODE_CHORD == 3
        ;; 4 ch chord progression: keyoff all -> per-ch fnumset -> per-ch keyon
        ld      b, #1
        call    fm_keyoff
        ld      b, #2
        call    fm_keyoff
        ld      b, #4
        call    fm_keyoff
        ld      b, #5
        call    fm_keyoff
        ld      a, (scale_step)
        ld      e, a
        ld      d, #0
        ld      hl, #scale_notes_ch2_chord
        add     hl, de
        ld      a, (hl)
        push    de
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        pop     de
        ld      hl, #scale_notes_ch3_chord
        add     hl, de
        ld      a, (hl)
        push    de
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        pop     de
        ld      hl, #scale_notes_ch5_chord
        add     hl, de
        ld      a, (hl)
        push    de
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        pop     de
        ld      hl, #scale_notes_ch6_chord
        add     hl, de
        ld      a, (hl)
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        .else
        .if TEST_MODE_CHORD
        ;; 4 ch unison: 全 ch keyoff → 全 ch fnumset → 全 ch keyon
        ld      b, #1
        call    fm_keyoff
        ld      b, #2
        call    fm_keyoff
        ld      b, #4
        call    fm_keyoff
        ld      b, #5
        call    fm_keyoff
        ld      a, (scale_step)
        ld      e, a
        ld      d, #0
        ld      hl, #scale_notes_fm
        add     hl, de
        ld      a, (hl)                 ; A = note byte
        push    af
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        pop     af
        push    af
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        pop     af
        push    af
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        pop     af
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        .else
        ld      b, #TEST_FM_CH_INDEX
        call    fm_keyoff
        ld      a, (scale_step)
        ld      e, a
        ld      d, #0
        ld      hl, #scale_notes_fm
        add     hl, de
        ld      a, (hl)
        ld      b, #TEST_FM_CH_INDEX
        call    fnumset_fm
        ld      b, #TEST_FM_CH_INDEX
        call    fm_keyon
        .endif
        .endif

        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl
        jr      irq_done

irq_scale_end:
        ;; ★ scale end bug fix (= 2026-05-09 Codex 検証で発見):
        ;;   TEST_MODE_CHORD = 1 で 4 ch unison scale 進行時、 scale 完走後に
        ;;   1 ch (= TEST_FM_CH_INDEX) のみ keyoff、 残り 3 ch が keyon 維持で
        ;;   C5 sustain 残留 (= user 「最後のドが少し延長」 真因)。 4 ch 全部
        ;;   keyoff 必要。
        .if TEST_MODE_CHORD
        ld      b, #1
        call    fm_keyoff
        ld      b, #2
        call    fm_keyoff
        ld      b, #4
        call    fm_keyoff
        ld      b, #5
        call    fm_keyoff
        .else
        ld      b, #TEST_FM_CH_INDEX
        call    fm_keyoff
        .endif
        xor     a
        ld      (driver_song_ready), a

irq_done:
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        reti

        .org 0x0200
ym2610_write_port_a:
        ld      a, b
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, c
        out     (5), a
        ret

ym2610_write_port_b:
        ld      a, b
        out     (6), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, c
        out     (7), a
        ret

        .org 0x0220
fnumset_fm:
        push    af
        push    bc
        and     #0x0F
        ld      l, a
        ld      h, #0
        add     hl, hl
        ld      bc, #fnum_data
        add     hl, bc
        ld      e, (hl)
        inc     hl
        ld      d, (hl)

        pop     bc
        pop     af
        rrca
        rrca
        rrca
        rrca
        and     #0x07
        add     a, a
        add     a, a
        add     a, a
        ld      l, a
        ld      a, d
        and     #0x07
        or      l
        ld      h, a

        ;; ★ 順序: 0xA5 (BLOCK_FNUM_2 / upper) を先 → 0xA1 (FNUM_LOW / lower) で latch 確定。
        ;;   neo-sisters Issue #8 fix (= commit 035f185) と同じ流儀、 「BLOCK_FNUM_2 を先に書き、
        ;;   FNUM_LOW で latch 確定」 が OPNB working order。 spec lower→upper 想定だが MAME ymfm
        ;;   実装 で逆順 latch (= upper 書込時に旧 lower、 lower 書込時に新 lower で正規 latch)、
        ;;   2026-05-09 user 「出鱈目音階 + 7 音」 audio 解析で確証。
        ld      a, b
        cp      #3
        jr      c, fnumset_fm_porta

        sub     #3
        ld      l, a
        ld      a, #0xA4
        add     a, l
        ld      b, a
        ld      c, h
        push    de
        push    hl
        call    ym2610_write_port_b
        pop     hl
        pop     de

        ld      a, #0xA0
        add     a, l
        ld      b, a
        ld      c, e
        call    ym2610_write_port_b
        ret

fnumset_fm_porta:
        ld      l, a
        ld      a, #0xA4
        add     a, l
        ld      b, a
        ld      c, h
        push    de
        push    hl
        call    ym2610_write_port_a
        pop     hl
        pop     de

        ld      a, #0xA0
        add     a, l
        ld      b, a
        ld      c, e
        call    ym2610_write_port_a
        ret

fnum_data:
        .dw     0x026A
        .dw     0x028F
        .dw     0x02B6
        .dw     0x02DF
        .dw     0x030B
        .dw     0x0339
        .dw     0x036A
        .dw     0x039E
        .dw     0x03D5
        .dw     0x0410
        .dw     0x044E
        .dw     0x048F

scale_notes_fm:
        .db     0x40, 0x42, 0x44, 0x45, 0x47, 0x49, 0x4B, 0x50

scale_notes_ch2_chord:
        .db     0x40, 0x42, 0x44, 0x45, 0x47, 0x49, 0x4B, 0x50
scale_notes_ch3_chord:
        .db     0x44, 0x45, 0x47, 0x49, 0x4B, 0x50, 0x52, 0x54
scale_notes_ch5_chord:
        .db     0x47, 0x49, 0x4B, 0x50, 0x52, 0x54, 0x55, 0x57
scale_notes_ch6_chord:
        .db     0x50, 0x52, 0x54, 0x55, 0x57, 0x59, 0x5B, 0x60

;; fm_keyoff: B = ch index (0..5)
fm_keyoff:
        push    bc
        ld      hl, #fm_keyoff_values
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, #0x28
        ld      c, (hl)
        call    ym2610_write_port_a
        pop     bc
        ret

;; fm_keyon: B = ch index (0..5)
fm_keyon:
        push    bc
        ld      hl, #fm_keyon_values
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, #0x28
        ld      c, (hl)
        call    ym2610_write_port_a
        pop     bc
        ret

        .org 0x0300
pmdneo_fm_write_reg_ch:
        push    bc
        push    de

        ld      a, b
        cp      #3
        jr      c, pmdneo_fm_write_reg_ch_port_a

        sub     #3
        ld      e, a
        ld      a, d
        add     a, e
        ld      b, a
        call    ym2610_write_port_b
        jr      pmdneo_fm_write_reg_ch_done

pmdneo_fm_write_reg_ch_port_a:
        ld      e, a
        ld      a, d
        add     a, e
        ld      b, a
        call    ym2610_write_port_a

pmdneo_fm_write_reg_ch_done:
        pop     de
        pop     bc
        ret

pmdneo_fm_write_voice_group_ch:
        ld      e, #4
pmdneo_fm_write_voice_group_ch_loop:
        ld      c, (hl)
        push    hl
        call    pmdneo_fm_write_reg_ch
        pop     hl
        inc     hl
        ld      a, d
        add     a, #4
        ld      d, a
        dec     e
        jr      nz, pmdneo_fm_write_voice_group_ch_loop
        ret

pmdneo_fm_clear_ssg_eg_ch:
        ld      d, #0x90
        ld      e, #4
pmdneo_fm_clear_ssg_eg_ch_loop:
        ld      c, #0x00
        push    hl
        call    pmdneo_fm_write_reg_ch
        pop     hl
        ld      a, d
        add     a, #4
        ld      d, a
        dec     e
        jr      nz, pmdneo_fm_clear_ssg_eg_ch_loop
        ret

pmdneo_fm_voice_set_default:
        ld      hl, #fm_voice_data_default
        ld      de, #24
        add     hl, de
        ld      d, #0xB0
        ld      c, (hl)
        call    pmdneo_fm_write_reg_ch

        ld      hl, #fm_voice_data_default
        ld      d, #0x30
        call    pmdneo_fm_write_voice_group_ch
        ld      d, #0x40
        call    pmdneo_fm_write_voice_group_ch
        ld      d, #0x50
        call    pmdneo_fm_write_voice_group_ch
        ld      d, #0x60
        call    pmdneo_fm_write_voice_group_ch
        ld      d, #0x70
        call    pmdneo_fm_write_voice_group_ch
        ld      d, #0x80
        call    pmdneo_fm_write_voice_group_ch

        call    pmdneo_fm_clear_ssg_eg_ch

        ld      d, #0xB4
        ld      c, #0xC0
        call    pmdneo_fm_write_reg_ch
        ret

init_chip_ch2_voice:
        ld      b, #1                   ; chip ch 2
        call    pmdneo_fm_voice_set_default
        ld      b, #2                   ; chip ch 3
        call    pmdneo_fm_voice_set_default
        ld      b, #4                   ; chip ch 5
        call    pmdneo_fm_voice_set_default
        ld      b, #5                   ; chip ch 6
        call    pmdneo_fm_voice_set_default
        ret

fm_voice_data_default:
        .db     0x01, 0x01, 0x01, 0x01
        .db     0x18, 0x18, 0x18, 0x18
        .db     0x1F, 0x1F, 0x1F, 0x1F
        .db     0x00, 0x00, 0x00, 0x00
        .db     0x00, 0x00, 0x00, 0x00
        .db     0x0F, 0x0F, 0x0F, 0x0F
        .db     0x07

        .org 0x03B0
fm_keyon_values:
        .db     0xF0, 0xF1, 0xF2, 0xF4, 0xF5, 0xF6
fm_keyoff_values:
        .db     0x00, 0x01, 0x02, 0x04, 0x05, 0x06

        .org 0x0400
init_adpcmb_beat:
        ld      b, #0x10
        ld      c, #0x00
        call    ym2610_write_port_a

        ld      b, #0x12
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x13
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x14
        ld      c, #0x7E
        call    ym2610_write_port_a
        ld      b, #0x15
        ld      c, #0x00
        call    ym2610_write_port_a

        ld      b, #0x19
        ld      c, #0x96
        call    ym2610_write_port_a
        ld      b, #0x1A
        ld      c, #0x6E
        call    ym2610_write_port_a
        ld      b, #0x1B
        ld      c, #0xFF
        call    ym2610_write_port_a
        ld      b, #0x11
        ld      c, #0xC0
        call    ym2610_write_port_a

        ld      b, #0x10
        ld      c, #0x80
        call    ym2610_write_port_a
        ret

        ;; Dummy DATA area to satisfy linker (= -b DATA=0xf800)
        .area DATA
