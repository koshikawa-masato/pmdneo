        .equ    driver_state_init_flag,  0xF810
        .equ    driver_song_ready,       0xF811
        .equ    driver_adpcmb_done_flag, 0xF812
        .equ    scale_step,              0xF813
        .equ    scale_tick_lo,           0xF814
        .equ    scale_tick_hi,           0xF815
        .equ    pmdneo_irq_count,        0xF816
        .equ    driver_tempo_d,          0xF817   ; 1 byte BPM-encoded accumulator delta
        .equ    driver_subtick_acc,      0xF818   ; 1 byte 8-bit overflow accumulator
        .equ    driver_fade_state,         0xF819   ; 1 byte: 0=no fade, 1=in progress
        .equ    driver_fade_counter,       0xF81A   ; 1 byte: IRQ step counter
        .equ    driver_fade_master,        0xF81B   ; 1 byte: ADPCM-A master vol shadow
        .equ    driver_fade_speed,         0xF81C   ; 1 byte (default 16, range 0-255)
        .equ    driver_pending_arg_target, 0xF81D   ; 1 byte (0=normal, 1=fade_speed arg)
        .equ    driver_loop_cycle,         0xF81E   ; 1 byte: BD part LOOP cycle counter

        ;; Phase 3 4ch individual test: 1=ch2(B), 2=ch3(C), 4=ch5(E), 5=ch6(F)
        .equ    TEST_FM_CH_INDEX,        1
        ;; TEST_MODE_CHORD:
        ;; 0 = single ch scale
        ;; 1 = 4 ch unison scale
        ;; 2 = 4 ch chord sustain
        ;; 3 = chord progression scale (4 ch FM)
        ;; 4 = 8 ch chord progression (FM4 + SSG3 + ADPCM-B, BCEFGHIJ milestone)
        ;; 5 = 17-part MML byte-stream state machines (BCEFGHIJ active)
        .equ    TEST_MODE_CHORD,         5

;;; ----- per-part workarea field offsets -----

        .equ    PART_OFF_ADDR,           0
        .equ    PART_OFF_LOOP,           2
        .equ    PART_OFF_LEN,            4
        .equ    PART_OFF_QDATA,          5
        .equ    PART_OFF_QDATB,          6
        .equ    PART_OFF_QDAT2,          7
        .equ    PART_OFF_QDAT3,          8
        .equ    PART_OFF_VOLUME,         9
        .equ    PART_OFF_SHIFT,          10
        .equ    PART_OFF_NOTE,           11
        .equ    PART_OFF_LOOPCNT,        12
        .equ    PART_OFF_LFOSWI,         13
        .equ    PART_OFF_PSGPAT,         14
        .equ    PART_OFF_TIEFLAG,        15
        .equ    PART_OFF_ENVF,           16
        .equ    PART_OFF_PAT,            17
        .equ    PART_OFF_PV2,            18
        .equ    PART_OFF_PR1,            19
        .equ    PART_OFF_PR2,            20
        .equ    PART_OFF_ENVVOL,         21
        .equ    PART_OFF_FLAGS,          22
        .equ    PART_OFF_GATE,           PART_OFF_QDATA
        .equ    PART_OFF_TRANSPOSE,      PART_OFF_SHIFT
        .equ    PART_OFF_OCTAVE,         23
        .equ    PART_OFF_CH_IDX,         24
        .equ    PART_OFF_CHIP_TYPE,      25   ;; 0=FM, 1=SSG, 2=PCM/ADPCM
        .equ    PART_OFF_VOLUME_SHIFT,   26   ;; signed v+/v- shift applied to V level
        .equ    PART_OFF_V_SCALE,        27   ;; signed v)/v( scale before v->V convert
        .equ    PART_OFF_LOOPSTACK_BASE, 32
        .equ    PART_OFF_LOOPDEPTH,      48
        .equ    PART_OFF_HOOK_KEYON,     49    ;; 2 bytes
        .equ    PART_OFF_HOOK_KEYOFF,    51    ;; 2 bytes
        .equ    PART_OFF_HOOK_FNUMSET,   53    ;; 2 bytes
        .equ    PART_OFF_HOOK_VOLUMESET, 55    ;; 2 bytes
        .equ    PART_WORKAREA_SIZE,      64

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
        ;; 17 x 64 = 1088 bytes occupies 0xF820-0xFC5F

        .include "assets/samples.inc"

;;; ----- Z80 SRAM layout (= 2 KB at 0xF800-0xFFFF) -----
;;;
;;;   0xF800 - 0xF80F   reserved future (16 bytes、cmd FIFO 検討中)
;;;   0xF810 - 0xF81F   driver_state (= 16 bytes 既存)
;;;   0xF820 - 0xFC5F   part_workarea (= 17 x 64 = 1088 bytes、Phase 5b)
;;;   0xFC60 - 0xFFBF   free / 後続 phase 用 (= 864 bytes 余裕)
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

        ld      a, #16
        ld      (driver_fade_speed), a

        ;; ★ 0x27 bit 6 (= multi-freq mode for ch 3) を立てると ch 3 通常 fnum
        ;;   (0xA2/0xA6) が無効化、 4 OP 個別 fnum (0xA8-0xAF) 必要に。 PMDNEO は
        ;;   通常 fnum 経路で chip ch 3 を駆動するため bit 6 クリア。
        ;;   2026-05-09 user 「B + ADPCM のみ」 audio 報告 + Codex 解析で発見。
        ld      b, #0x27
        ld      c, #0x00                ; multi-freq disable + TIMER 全 reset
        call    ym2610_write_port_a
        ld      b, #0x26
        ld      c, #0xF9                ; NB=249 -> TB=7*144=1008 us ~= 1 ms IRQ
        call    ym2610_write_port_a
        ld      b, #0x27
        ld      c, #0x2A                ; TIMER-B reset(b1) + IRQ enable(b3) + run(b5)、 multi-freq disable
        call    ym2610_write_port_a

nmi_dispatch:
        ;; modal flag check disabled for bug isolation
        in      a, (0x00)
        cp      #2
        jp      z, nmi_cmd_2_play_song
        cp      #5
        jp      z, nmi_cmd_5_adpcmb_beat
        cp      #6
        jp      z, nmi_cmd_6_fade_start
        cp      #7
        jp      z, nmi_cmd_7_set_fade_speed
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

        ;; PAN分離 (= 7ch識別用): ch2/3(B/C)=R, ch5/6(E/F)=L, SSG中央既定
        ;; PMD_TL最大化なしでも左右分離で聴感識別可能
        ld      b, #0xB5
        ld      c, #0x40        ; ch2 (B) = R
        call    ym2610_write_port_a
        ld      b, #0xB6
        ld      c, #0x40        ; ch3 (C) = R
        call    ym2610_write_port_a
        ld      b, #0xB5
        ld      c, #0x80        ; ch5 (E) = L (port B)
        call    ym2610_write_port_b
        ld      b, #0xB6
        ld      c, #0x80        ; ch6 (F) = L (port B)
        call    ym2610_write_port_b

        xor     a
        ld      (scale_step), a
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        .if TEST_MODE_CHORD == 4
        call    nmi_cmd_2_play_song_mode4
        .else
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
        .endif
        jp      nmi_done

nmi_cmd_5_adpcmb_beat:
        .if TEST_MODE_CHORD == 5
        call    nmi_cmd_5_init_mml_song
        jp      nmi_done
        .else
        ld      a, (driver_adpcmb_done_flag)
        or      a
        jp      nz, nmi_done
        call    init_adpcmb_beat
        ld      a, #1
        ld      (driver_adpcmb_done_flag), a
        jp      nmi_done
        .endif

nmi_cmd_6_fade_start:
        ld      a, #0x3F
        ld      (driver_fade_master), a
        xor     a
        ld      (driver_fade_counter), a
        ld      a, #1
        ld      (driver_fade_state), a
        jp      nmi_done

nmi_cmd_7_set_fade_speed:
        ld      a, #1
        ld      (driver_pending_arg_target), a
        jp      nmi_done

        .org 0x0100
irq_handler_body:
        di
        push    af
        push    bc
        push    de
        push    hl

        ld      b, #0x27
        ld      c, #0x2A                ; TIMER-B re-arm (multi-freq disable for ch 3 fnum)
        call    ym2610_write_port_a

        ld      a, (pmdneo_irq_count)
        inc     a
        ld      (pmdneo_irq_count), a

        ;; IRQ fade processing (= default speed 16, ~1 sec fade)
        ld      a, (driver_fade_state)
        or      a
        jp      z, irq_fade_done
        ld      a, (driver_fade_counter)
        inc     a
        ld      hl, #driver_fade_speed
        cp      (hl)
        jp      c, irq_fade_save_counter
        xor     a
        ld      (driver_fade_counter), a
        ld      a, (driver_fade_master)
        or      a
        jp      z, irq_fade_finish
        dec     a
        ld      (driver_fade_master), a
        ld      b, #0x01
        ld      c, a
        call    ym2610_write_port_b
        jp      irq_fade_done
irq_fade_save_counter:
        ld      (driver_fade_counter), a
        jp      irq_fade_done
irq_fade_finish:
        xor     a
        ld      (driver_fade_state), a
        ld      b, #0x00
        ld      c, #0xBF
        call    ym2610_write_port_b
irq_fade_done:

        ld      a, (driver_song_ready)
        or      a
        jp      z, irq_done

        .if TEST_MODE_CHORD == 5
        ld      a, (driver_subtick_acc)
        ld      hl, #driver_tempo_d
        add     a, (hl)
        ld      (driver_subtick_acc), a
        jp      nc, irq_done              ; no overflow -> skip song dispatch
        call    pmdneo_song_main
        jp      irq_done
        .endif

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
        .if TEST_MODE_CHORD == 4
        call    irq_scale_step_mode4
        .else
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
        .if TEST_MODE_CHORD == 4
        ld      b, #1
        call    fm_keyoff
        ld      b, #2
        call    fm_keyoff
        ld      b, #4
        call    fm_keyoff
        ld      b, #5
        call    fm_keyoff
        ld      b, #0
        call    ssg_keyoff
        ld      b, #1
        call    ssg_keyoff
        ld      b, #2
        call    ssg_keyoff
        .else
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

init_ssg_voice:
        ld      b, #0x07
        ld      c, #0x38
        call    ym2610_write_port_a
        ;; SSG volume = 0x0F (= max、中央SSGをFM L/Rの間に浮かせる)
        ld      b, #0x08
        ld      c, #0x0F
        call    ym2610_write_port_a
        ld      b, #0x09
        ld      c, #0x0F
        call    ym2610_write_port_a
        ld      b, #0x0A
        ld      c, #0x0F
        call    ym2610_write_port_a
        ret

;; fnumset_ssg: A = note byte (OCT<<4|ONKAI), B = SSG ch index (0..2)
fnumset_ssg:
        push    af
        push    bc
        and     #0x0F
        ld      l, a
        ld      h, #0
        add     hl, hl
        ld      bc, #psg_tune_data
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
        and     #0x0F
        or      a
        jr      z, fnumset_ssg_set
fnumset_ssg_shift:
        srl     d
        rr      e
        dec     a
        jr      nz, fnumset_ssg_shift

fnumset_ssg_set:
        ld      a, b
        add     a, a                    ; SSG tune register base = ch * 2
        ld      l, a
        ld      h, #0

        push    de
        push    hl
        ld      b, l                    ; fine tune register
        ld      c, e
        call    ym2610_write_port_a
        pop     hl
        pop     de

        ld      a, l
        inc     a                       ; coarse tune register
        ld      b, a
        ld      a, d
        and     #0x0F
        ld      c, a
        call    ym2610_write_port_a
        ret

;; ssg_keyoff: B = SSG ch index (0..2)
ssg_keyoff:
        push    bc
        ld      a, #0x08
        add     a, b
        ld      b, a
        ld      c, #0x00
        call    ym2610_write_port_a
        pop     bc
        ret

;; ssg_keyon: B = SSG ch index (0..2)
ssg_keyon:
        push    bc
        ld      a, #0x08
        add     a, b
        ld      b, a
        ld      c, #0x0F                ; SSG volume = 0x0F (= max、FMがPAN左右で分離済なので中央SSG浮かせる)
        call    ym2610_write_port_a
        pop     bc
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

psg_tune_data:
        .dw     0x0EE8                  ; C
        .dw     0x0E12                  ; C#
        .dw     0x0D48                  ; D
        .dw     0x0C89                  ; D#
        .dw     0x0BD5                  ; E
        .dw     0x0B2B                  ; F
        .dw     0x0A8A                  ; F#
        .dw     0x09F3                  ; G
        .dw     0x0964                  ; G#
        .dw     0x08DD                  ; A
        .dw     0x085E                  ; A#
        .dw     0x07E6                  ; B

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

scale_notes_g_chord:
        .db     0x40, 0x42, 0x44, 0x45, 0x47, 0x49, 0x4B, 0x50
scale_notes_h_chord:
        .db     0x44, 0x45, 0x47, 0x49, 0x4B, 0x50, 0x52, 0x54
scale_notes_i_chord:
        .db     0x47, 0x49, 0x4B, 0x50, 0x52, 0x54, 0x55, 0x57

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

        .org 0x0380
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

nmi_cmd_2_play_song_mode4:
        call    init_ssg_voice

        ld      a, #0x40                ; FM ch2 root C4
        ld      b, #1
        call    fnumset_fm
        ld      b, #1
        call    fm_keyon
        ld      a, #0x44                ; FM ch3 3rd E4
        ld      b, #2
        call    fnumset_fm
        ld      b, #2
        call    fm_keyon
        ld      a, #0x47                ; FM ch5 5th G4
        ld      b, #4
        call    fnumset_fm
        ld      b, #4
        call    fm_keyon
        ld      a, #0x50                ; FM ch6 octave C5
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon

        ld      a, #0x40                ; SSG G root C4
        ld      b, #0
        call    fnumset_ssg
        ld      b, #0
        call    ssg_keyon
        ld      a, #0x44                ; SSG H 3rd E4
        ld      b, #1
        call    fnumset_ssg
        ld      b, #1
        call    ssg_keyon
        ld      a, #0x47                ; SSG I 5th G4
        ld      b, #2
        call    fnumset_ssg
        ld      b, #2
        call    ssg_keyon

        ld      a, #1
        ld      (driver_song_ready), a
        ret

irq_scale_step_mode4:
        ld      b, #1
        call    fm_keyoff
        ld      b, #2
        call    fm_keyoff
        ld      b, #4
        call    fm_keyoff
        ld      b, #5
        call    fm_keyoff
        ld      b, #0
        call    ssg_keyoff
        ld      b, #1
        call    ssg_keyoff
        ld      b, #2
        call    ssg_keyoff

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
        push    de
        ld      b, #5
        call    fnumset_fm
        ld      b, #5
        call    fm_keyon
        pop     de

        ld      hl, #scale_notes_g_chord
        add     hl, de
        ld      a, (hl)
        push    de
        ld      b, #0
        call    fnumset_ssg
        ld      b, #0
        call    ssg_keyon
        pop     de
        ld      hl, #scale_notes_h_chord
        add     hl, de
        ld      a, (hl)
        push    de
        ld      b, #1
        call    fnumset_ssg
        ld      b, #1
        call    ssg_keyon
        pop     de
        ld      hl, #scale_notes_i_chord
        add     hl, de
        ld      a, (hl)
        ld      b, #2
        call    fnumset_ssg
        ld      b, #2
        call    ssg_keyon
        ret

fm_voice_data_default:
        .db     0x01, 0x01, 0x01, 0x01
        ;; FM TLは元の0x18で全mode統一 (= main HEAD audio gate pass値、
        ;; mode 4はPAN分離(L/R)でFM/SSG識別、TL最大化不要)
        .db     0x18, 0x18, 0x18, 0x18
        .db     0x1F, 0x1F, 0x1F, 0x1F
        .db     0x00, 0x00, 0x00, 0x00
        .db     0x00, 0x00, 0x00, 0x00
        .db     0x0F, 0x0F, 0x0F, 0x0F
        .db     0x07

        .org 0x0600
fm_keyon_values:
        .db     0xF0, 0xF1, 0xF2, 0xF4, 0xF5, 0xF6
fm_keyoff_values:
        .db     0x00, 0x01, 0x02, 0x04, 0x05, 0x06

        .org 0x0610
init_adpcmb_beat:
        ld      b, #0x10
        ld      c, #0x00
        call    ym2610_write_port_a

        ;; Phase 9R R-5c: ADPCM-B sample = beat.wav (= samples-map.yaml 経由)
        ;; samples.inc 経由で BEAT_START_LSB/MSB / BEAT_STOP_LSB/MSB 生成済
        ld      b, #0x12
        ld      c, #BEAT_START_LSB
        call    ym2610_write_port_a
        ld      b, #0x13
        ld      c, #BEAT_START_MSB
        call    ym2610_write_port_a
        ld      b, #0x14
        ld      c, #BEAT_STOP_LSB
        call    ym2610_write_port_a
        ld      b, #0x15
        ld      c, #BEAT_STOP_MSB
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

;;; ----- Phase 5b: MML byte-stream song initialization -----

nmi_cmd_5_init_mml_song:
        ;; --- silence all chips (FM / SSG / ADPCM-B) ---
        ;; FM keyoff all 6 channels (reg 0x28, ch 0/1/2/4/5/6)
        ld      b, #0x28
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x28
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x28
        ld      c, #0x02
        call    ym2610_write_port_a
        ld      b, #0x28
        ld      c, #0x04
        call    ym2610_write_port_a
        ld      b, #0x28
        ld      c, #0x05
        call    ym2610_write_port_a
        ld      b, #0x28
        ld      c, #0x06
        call    ym2610_write_port_a
        ;; FM TL max attenuation on both banks (regs 0x40-0x4F)
        ld      b, #0x40
        ld      e, #0x10
nmi_cmd_5_fm_tl_port_a_loop:
        ld      c, #0x7F
        call    ym2610_write_port_a
        inc     b
        dec     e
        jp      nz, nmi_cmd_5_fm_tl_port_a_loop
        ld      b, #0x40
        ld      e, #0x10
nmi_cmd_5_fm_tl_port_b_loop:
        ld      c, #0x7F
        call    ym2610_write_port_b
        inc     b
        dec     e
        jp      nz, nmi_cmd_5_fm_tl_port_b_loop
        ;; FM SSG-EG off on both banks (regs 0x90-0x9F)
        ld      b, #0x90
        ld      e, #0x10
nmi_cmd_5_fm_ssg_eg_port_a_loop:
        ld      c, #0x00
        call    ym2610_write_port_a
        inc     b
        dec     e
        jp      nz, nmi_cmd_5_fm_ssg_eg_port_a_loop
        ld      b, #0x90
        ld      e, #0x10
nmi_cmd_5_fm_ssg_eg_port_b_loop:
        ld      c, #0x00
        call    ym2610_write_port_b
        inc     b
        dec     e
        jp      nz, nmi_cmd_5_fm_ssg_eg_port_b_loop
        ;; SSG all tone+noise disable (reg 0x07 = 0x3F)
        ld      b, #0x07
        ld      c, #0x3F
        call    ym2610_write_port_a
        ;; SSG vol 0 all 3 channels
        ld      b, #0x08
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x09
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x0A
        ld      c, #0x00
        call    ym2610_write_port_a
        ;; SSG envelope shape/cycle off
        ld      b, #0x0B
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x0C
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x0D
        ld      c, #0x00
        call    ym2610_write_port_a
        ;; ADPCM-B reset/stop (reg 0x10 = 0x01 then 0x00)
        ld      b, #0x10
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x10
        ld      c, #0x00
        call    ym2610_write_port_a
        ;; ADPCM-B total level mute
        ld      b, #0x1B
        ld      c, #0x00
        call    ym2610_write_port_a
        ;; ADPCM-B L/R/start/end clear
        ld      b, #0x11
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x12
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x13
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x14
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x15
        ld      c, #0x00
        call    ym2610_write_port_a
        call    adpcma_init
        ld      b, #0x00
        ld      c, #0x00
        call    ym2610_write_port_b
        ld      a, #24                  ; t120 default: (120*13)>>6 = 24
        ld      (driver_tempo_d), a
        xor     a
        ld      (driver_subtick_acc), a
        ;; Phase 9R R-5a: FM 4 ch (= ch2/3/5/6) audible voice setup (= TL 0x18 + ALG 7)
        ;; mode 4 経由なら nmi_cmd_2_play_song で init_chip_ch2_voice 呼ばれるが、
        ;; mode 5 (= MML byte parser) では nmi_cmd_5 内で voice setup が skip されてた、
        ;; FM keyon 出るが TL = 0x7F mute で audible にならない真因 (= 2026-05-10)。
        call    init_chip_ch2_voice
        ;; Phase 9R R-5b: SSG 3 ch audible setup (= reg 0x07 = 0x38 tone enable + vol 0x0F)
        ;; mode 4 経由なら nmi_cmd_2_play_song_mode4 で init_ssg_voice 呼ばれるが、
        ;; mode 5 では SSG silence init (= reg 0x07 = 0x3F all disable + vol 0x00) のまま、
        ;; SSG 3 part init 復活 (= R-5b) 時の audible 化に必要。
        call    init_ssg_voice
        ;; Phase 9R R-5b 補足: FM PAN 分離 (= user 要望、 BC=Left, EF=Right)
        ;; ch2 (B) = port A reg 0xB5、 ch3 (C) = port A reg 0xB6
        ;; ch5 (E) = port B reg 0xB5、 ch6 (F) = port B reg 0xB6
        ;; PAN 値: 0x80 = Left only, 0x40 = Right only, 0xC0 = L+R 中央 (default)
        ld      b, #0xB5
        ld      c, #0x80                ; ch2 (B) = L
        call    ym2610_write_port_a
        ld      b, #0xB6
        ld      c, #0x80                ; ch3 (C) = L
        call    ym2610_write_port_a
        ld      b, #0xB5
        ld      c, #0x40                ; ch5 (E) = R
        call    ym2610_write_port_b
        ld      b, #0xB6
        ld      c, #0x40                ; ch6 (F) = R
        call    ym2610_write_port_b
        call    pmdneo5_clear_part_workarea

        ld      a, #PART_FM2
        ld      hl, #song_part_b
        ld      b, #1
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_FM3
        ld      hl, #song_part_c
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_FM5
        ld      hl, #song_part_e
        ld      b, #4
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_FM6
        ld      hl, #song_part_f
        ld      b, #5
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_SSG1
        ld      hl, #song_part_g
        ld      b, #0
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_SSG2
        ld      hl, #song_part_h
        ld      b, #1
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_SSG3
        ld      hl, #song_part_i
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #PART_PCM
        ld      hl, #song_part_j
        ld      b, #0
        ld      c, #0
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA1
        ld      hl, #song_part_l
        ld      b, #0
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA2
        ld      hl, #song_part_m
        ld      b, #1
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA3
        ld      hl, #song_part_n
        ld      b, #2
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA4
        ld      hl, #song_part_o
        ld      b, #3
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA5
        ld      hl, #song_part_p
        ld      b, #4
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #PART_ADPCMA6
        ld      hl, #song_part_q
        ld      b, #5
        ld      c, #0x00
        call    pmdneo5_init_part

        ld      a, #1
        ld      (driver_song_ready), a
        ret

pmdneo5_clear_part_workarea:
        ld      hl, #part_workarea
        ld      de, #part_workarea + 1
        ld      bc, #1087
        xor     a
        ld      (hl), a
        ldir
        ret

;;; A=part index, HL=stream table, B=channel index, C=default volume.
pmdneo5_init_part:
        push    hl
        push    bc
        call    pmdneo_part_ix_from_part
        pop     bc
        pop     hl
        ld      d, a

        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        xor     a
        ld      PART_OFF_LOOP(ix), a
        ld      PART_OFF_LOOP+1(ix), a
        ld      PART_OFF_LEN(ix), a
        ld      PART_OFF_GATE(ix), a
        ld      PART_OFF_TRANSPOSE(ix), a
        ld      PART_OFF_FLAGS(ix), a
        ld      a, #4
        ld      PART_OFF_OCTAVE(ix), a
        ld      PART_OFF_CH_IDX(ix), b
        ld      PART_OFF_VOLUME(ix), c
        xor     a
        ld      PART_OFF_VOLUME_SHIFT(ix), a
        ld      PART_OFF_V_SCALE(ix), a
        ld      a, d
        cp      #PART_SSG1
        jr      c, pmdneo5_init_part_chip_fm
        cp      #PART_PCM
        jr      c, pmdneo5_init_part_chip_ssg
        ld      a, #2
        jr      pmdneo5_init_part_chip_set
pmdneo5_init_part_chip_fm:
        xor     a
        jr      pmdneo5_init_part_chip_set
pmdneo5_init_part_chip_ssg:
        ld      a, #1
pmdneo5_init_part_chip_set:
        ld      PART_OFF_CHIP_TYPE(ix), a
        ld      a, d
        cp      #PART_SSG1
        jp      c, pmdneo5_init_part_hooks_fm
        cp      #PART_PCM
        jp      c, pmdneo5_init_part_hooks_psg
        cp      #PART_PCM
        jp      z, pmdneo5_init_part_hooks_pcm
        cp      #PART_ADPCMA1
        jp      c, pmdneo5_init_part_hooks_noop
        jp      pmdneo5_init_part_hooks_adpcma

pmdneo5_init_part_hooks_fm:
        ld      hl, #fm_keyon_hook
        ld      PART_OFF_HOOK_KEYON(ix), l
        ld      PART_OFF_HOOK_KEYON+1(ix), h
        ld      hl, #fm_keyoff_hook
        ld      PART_OFF_HOOK_KEYOFF(ix), l
        ld      PART_OFF_HOOK_KEYOFF+1(ix), h
        ld      hl, #fnumset_fm_hook
        ld      PART_OFF_HOOK_FNUMSET(ix), l
        ld      PART_OFF_HOOK_FNUMSET+1(ix), h
        ld      hl, #fm_volume_hook
        ld      PART_OFF_HOOK_VOLUMESET(ix), l
        ld      PART_OFF_HOOK_VOLUMESET+1(ix), h
        ret

pmdneo5_init_part_hooks_psg:
        ld      hl, #psg_keyon_hook
        ld      PART_OFF_HOOK_KEYON(ix), l
        ld      PART_OFF_HOOK_KEYON+1(ix), h
        ld      hl, #ssg_keyoff_hook
        ld      PART_OFF_HOOK_KEYOFF(ix), l
        ld      PART_OFF_HOOK_KEYOFF+1(ix), h
        ld      hl, #fnumsetp_ch_hook
        ld      PART_OFF_HOOK_FNUMSET(ix), l
        ld      PART_OFF_HOOK_FNUMSET+1(ix), h
        ld      hl, #psg_volume_hook
        ld      PART_OFF_HOOK_VOLUMESET(ix), l
        ld      PART_OFF_HOOK_VOLUMESET+1(ix), h
        ret

pmdneo5_init_part_hooks_pcm:
        ld      hl, #adpcmb_keyon_hook
        ld      PART_OFF_HOOK_KEYON(ix), l
        ld      PART_OFF_HOOK_KEYON+1(ix), h
        ld      hl, #adpcmb_keyoff_hook
        ld      PART_OFF_HOOK_KEYOFF(ix), l
        ld      PART_OFF_HOOK_KEYOFF+1(ix), h
        ld      hl, #noop_hook
        ld      PART_OFF_HOOK_FNUMSET(ix), l
        ld      PART_OFF_HOOK_FNUMSET+1(ix), h
        ld      PART_OFF_HOOK_VOLUMESET(ix), l
        ld      PART_OFF_HOOK_VOLUMESET+1(ix), h
        ret

pmdneo5_init_part_hooks_adpcma:
        ld      hl, #adpcma_keyon_hook
        ld      PART_OFF_HOOK_KEYON(ix), l
        ld      PART_OFF_HOOK_KEYON+1(ix), h
        ld      hl, #adpcma_keyoff_hook
        ld      PART_OFF_HOOK_KEYOFF(ix), l
        ld      PART_OFF_HOOK_KEYOFF+1(ix), h
        ld      hl, #noop_hook
        ld      PART_OFF_HOOK_FNUMSET(ix), l
        ld      PART_OFF_HOOK_FNUMSET+1(ix), h
        ld      PART_OFF_HOOK_VOLUMESET(ix), l
        ld      PART_OFF_HOOK_VOLUMESET+1(ix), h
        ret

pmdneo5_init_part_hooks_noop:
        ld      hl, #noop_hook
        ld      PART_OFF_HOOK_KEYON(ix), l
        ld      PART_OFF_HOOK_KEYON+1(ix), h
        ld      PART_OFF_HOOK_KEYOFF(ix), l
        ld      PART_OFF_HOOK_KEYOFF+1(ix), h
        ld      PART_OFF_HOOK_FNUMSET(ix), l
        ld      PART_OFF_HOOK_FNUMSET+1(ix), h
        ld      PART_OFF_HOOK_VOLUMESET(ix), l
        ld      PART_OFF_HOOK_VOLUMESET+1(ix), h
        ret

;;; ----- Phase 5b: song dispatcher and per-part state machines -----

pmdneo_song_main:
        ld      c, #0
pmdneo_song_main_loop:
        ld      a, c
        push    bc
        call    pmdneo_part_ix_from_part
        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        jp      z, pmdneo_song_main_skip
        pop     bc
        push    bc
        ld      a, c
        cp      #PART_RHYTHM
        jp      z, pmdneo_song_main_rhythm
        ld      b, PART_OFF_CH_IDX(ix)
        call    pmdneo_part_main
        jp      pmdneo_song_main_after

pmdneo_song_main_rhythm:
        call    rhythm_main
        jp      pmdneo_song_main_after

pmdneo_song_main_after:
        pop     bc
pmdneo_song_main_next:
        inc     c
        ld      a, c
        cp      #PART_COUNT
        jp      c, pmdneo_song_main_loop
        ret

pmdneo_song_main_skip:
        pop     bc
        jp      pmdneo_song_main_next

pmdneo_part_ix_from_part:
        ld      l, a
        ld      h, #0
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      e, l
        ld      d, h
        ld      hl, #part_workarea
        add     hl, de
        push    hl
        pop     ix
        ret

pmdneo_part_fetch_byte:
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      a, (hl)
        inc     hl
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ret

pmdneo_v_to_V_convert:
        push    bc
        push    de
        push    hl
        cp      #17
        jr      c, _pmdneo_v_to_V_index_ok
        ld      a, #16
_pmdneo_v_to_V_index_ok:
        ld      b, a
        ld      a, PART_OFF_CHIP_TYPE(ix)
        or      a
        jr      z, _pmdneo_v_to_V_fm
        cp      #1
        jr      z, _pmdneo_v_to_V_ssg
        ld      hl, #v_to_V_pcm
        jr      _pmdneo_v_to_V_table
_pmdneo_v_to_V_fm:
        ld      hl, #v_to_V_fm
        jr      _pmdneo_v_to_V_table
_pmdneo_v_to_V_ssg:
        ld      a, b
        jr      _pmdneo_v_to_V_done
_pmdneo_v_to_V_table:
        ld      e, b
        ld      d, #0
        add     hl, de
        ld      a, (hl)
_pmdneo_v_to_V_done:
        pop     hl
        pop     de
        pop     bc
        ret

pmdneo_scale_mml_length:
        or      a
        ret     nz
        inc     a
        ret

pmdneo_part_main:
        ld      a, PART_OFF_LEN(ix)
        or      a
        jp      z, pmdneo_part_main_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        ret     nz
        call    pmdneo_part_call_keyoff_hook
        ret

pmdneo_part_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, pmdneo_part_main_loop
        cp      #0x90
        jp      z, pmdneo_part_main_rest
        jp      c, pmdneo_part_main_note
        call    commandsp
        jp      pmdneo_part_main_parse

pmdneo_part_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ;; Phase 9b FULL: q gate effect with random range and min guarantee.
        ld      b, a
        ld      a, PART_OFF_QDATA(ix)
        or      a
        jr      z, pmdneo_part_main_note_no_gate
        ld      c, a
        ld      a, PART_OFF_QDATB(ix)
        or      a
        jr      z, pmdneo_part_main_note_have_gate
        cp      c
        jr      z, pmdneo_part_main_note_have_gate
        jr      c, pmdneo_part_main_note_have_gate
        sub     c
        dec     a
        ld      e, a
        ld      a, r
        and     #0x7F
        and     e
        add     a, c
        ld      c, a
pmdneo_part_main_note_have_gate:
        ld      a, PART_OFF_QDAT3(ix)
        or      a
        jr      z, pmdneo_part_main_note_no_min
        ld      e, a
        ld      a, c
        cp      b
        jr      nc, pmdneo_part_main_note_use_min
        ld      a, b
        sub     c
        cp      e
        jr      nc, pmdneo_part_main_note_set_len
pmdneo_part_main_note_use_min:
        ld      a, e
        jr      pmdneo_part_main_note_set_len
pmdneo_part_main_note_no_min:
        ld      a, c
        cp      b
        jr      nc, pmdneo_part_main_note_min_one
        ld      a, b
        sub     c
        jr      nz, pmdneo_part_main_note_set_len
pmdneo_part_main_note_min_one:
        ld      a, #1
pmdneo_part_main_note_set_len:
        ld      PART_OFF_LEN(ix), a
        jr      pmdneo_part_main_note_dispatch
pmdneo_part_main_note_no_gate:
        ld      PART_OFF_LEN(ix), b
pmdneo_part_main_note_dispatch:
        ld      a, PART_OFF_NOTE(ix)
        call    pmdneo_part_call_fnumset_hook
        ld      a, PART_OFF_NOTE(ix)
        call    pmdneo_part_call_keyon_hook
        ret

pmdneo_part_main_rest:
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ret

pmdneo_part_main_loop:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jp      z, pmdneo_part_main_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jp      pmdneo_part_main_parse

pmdneo_part_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

pmdneo_part_call_keyon_hook:
        ld      l, PART_OFF_HOOK_KEYON(ix)
        ld      h, PART_OFF_HOOK_KEYON+1(ix)
        jp      pmdneo_part_call_hl

pmdneo_part_call_keyoff_hook:
        ld      l, PART_OFF_HOOK_KEYOFF(ix)
        ld      h, PART_OFF_HOOK_KEYOFF+1(ix)
        jp      pmdneo_part_call_hl

pmdneo_part_call_fnumset_hook:
        ld      l, PART_OFF_HOOK_FNUMSET(ix)
        ld      h, PART_OFF_HOOK_FNUMSET+1(ix)
        jp      pmdneo_part_call_hl

pmdneo_part_call_volume_hook:
        ld      l, PART_OFF_HOOK_VOLUMESET(ix)
        ld      h, PART_OFF_HOOK_VOLUMESET+1(ix)
        jp      pmdneo_part_call_hl

pmdneo_part_call_hl:
        push    hl
        ret

comt:
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d), a
        ret

comv:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_V_SCALE(ix)
        add     a, b
        jp      p, _pmdneo_comv_scale_pos
        xor     a
_pmdneo_comv_scale_pos:
        cp      #17
        jr      c, _pmdneo_comv_scale_ok
        ld      a, #16
_pmdneo_comv_scale_ok:
        call    pmdneo_v_to_V_convert
        ld      b, a
        ld      a, PART_OFF_VOLUME_SHIFT(ix)
        or      a
        jp      p, _pmdneo_comv_shift_pos
        neg
        ld      c, a
        ld      a, b
        sub     c
        jr      nc, _pmdneo_comv_shift_ok
        xor     a
        jr      _pmdneo_comv_shift_ok
_pmdneo_comv_shift_pos:
        add     a, b
        jr      nc, _pmdneo_comv_shift_ok
        ld      a, #0xFF
_pmdneo_comv_shift_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comV:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comvshift_up:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_VOLUME_SHIFT(ix), a
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        add     a, b
        jr      nc, _pmdneo_vsu_ok
        ld      a, #0xFF
_pmdneo_vsu_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comvshift_down:
        call    pmdneo_part_fetch_byte
        neg
        ld      PART_OFF_VOLUME_SHIFT(ix), a
        neg
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        sub     b
        jr      nc, _pmdneo_vsd_ok
        xor     a
_pmdneo_vsd_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comvscale_up:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_V_SCALE(ix), a
        ret

comvscale_down:
        call    pmdneo_part_fetch_byte
        neg
        ld      PART_OFF_V_SCALE(ix), a
        ret

comvolup:
        call    pmdneo_part_fetch_byte
        ld      l, a
        ld      a, PART_OFF_CHIP_TYPE(ix)
        cp      #2
        jr      z, _pmdneo_vup_pcm
        ld      a, l
        sla     a
        sla     a
        jr      _pmdneo_vup_apply
_pmdneo_vup_pcm:
        ld      a, l
        sla     a
        sla     a
        sla     a
        sla     a
_pmdneo_vup_apply:
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        add     a, b
        jr      nc, _pmdneo_vup_ok
        ld      a, #0xFF
_pmdneo_vup_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comvoldown:
        call    pmdneo_part_fetch_byte
        ld      l, a
        ld      a, PART_OFF_CHIP_TYPE(ix)
        cp      #2
        jr      z, _pmdneo_vdn_pcm
        ld      a, l
        sla     a
        sla     a
        jr      _pmdneo_vdn_apply
_pmdneo_vdn_pcm:
        ld      a, l
        sla     a
        sla     a
        sla     a
        sla     a
_pmdneo_vdn_apply:
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        sub     b
        jr      nc, _pmdneo_vdn_ok
        xor     a
_pmdneo_vdn_ok:
        ld      PART_OFF_VOLUME(ix), a
        call    pmdneo_part_call_volume_hook
        ret

comstloop:
        ld      a, PART_OFF_LOOPDEPTH(ix)
        cp      #4
        jp      nc, comstloop_done
        push    af
        add     a, a
        add     a, a
        add     a, #PART_OFF_LOOPSTACK_BASE
        ld      e, a
        ld      d, #0
        push    ix
        pop     hl
        add     hl, de
        ld      a, PART_OFF_ADDR(ix)
        ld      (hl), a
        inc     hl
        ld      a, PART_OFF_ADDR+1(ix)
        ld      (hl), a
        inc     hl
        xor     a
        ld      (hl), a
        pop     af
        inc     a
        ld      PART_OFF_LOOPDEPTH(ix), a
comstloop_done:
        ret

comedloop:
        push    bc
        call    pmdneo_part_fetch_byte
        or      a
        jp      z, comedloop_force_reloop
        ld      c, a
        ld      a, PART_OFF_LOOPDEPTH(ix)
        or      a
        jp      z, comedloop_done
        dec     a
        add     a, a
        add     a, a
        add     a, #PART_OFF_LOOPSTACK_BASE
        ld      e, a
        ld      d, #0
        push    ix
        pop     hl
        add     hl, de
        inc     hl
        inc     hl
        ld      a, (hl)
        inc     a
        ld      (hl), a
        cp      c
        jp      c, comedloop_repeat
        ld      a, PART_OFF_LOOPDEPTH(ix)
        dec     a
        ld      PART_OFF_LOOPDEPTH(ix), a
        jp      comedloop_done
comedloop_repeat:
        dec     hl
        dec     hl
        ld      a, (hl)
        ld      PART_OFF_ADDR(ix), a
        inc     hl
        ld      a, (hl)
        ld      PART_OFF_ADDR+1(ix), a
        jp      comedloop_done
comedloop_force_reloop:
        push    af
        push    ix
        pop     hl
        ld      a, h
        cp      #0xFA
        jp      nz, comedloop_force_reloop_skip
        ld      a, l
        cp      #0xE0
        jp      nz, comedloop_force_reloop_skip
        ld      a, (driver_loop_cycle)
        inc     a
        ld      (driver_loop_cycle), a
        out     (0x0C), a
comedloop_force_reloop_skip:
        pop     af
        ld      a, PART_OFF_LOOPDEPTH(ix)
        or      a
        jp      z, comedloop_done
        dec     a
        sla     a
        sla     a
        add     a, #PART_OFF_LOOPSTACK_BASE
        ld      e, a
        ld      d, #0
        push    ix
        pop     hl
        add     hl, de
        ld      a, (hl)
        ld      PART_OFF_ADDR(ix), a
        inc     hl
        ld      a, (hl)
        ld      PART_OFF_ADDR+1(ix), a
        jp      comedloop_done
comedloop_done:
        pop     bc
        ret

commandsp:
        cp      #0xFC
        jp      z, commandsp_t
        cp      #0xFD
        jp      z, commandsp_v
        cp      #0xCC
        jp      z, commandsp_V
        cp      #0xFE
        jp      z, commandsp_q
        cp      #0xC4
        jp      z, commandsp_q2
        cp      #0xB3
        jp      z, commandsp_q3
        cp      #0xB1
        jp      z, commandsp_q4
        cp      #0xDE
        jp      z, commandsp_vshift_up
        cp      #0xDD
        jp      z, commandsp_vshift_down
        cp      #0xDB
        jp      z, commandsp_vscale_up
        cp      #0xDA
        jp      z, commandsp_vscale_down
        cp      #0xF4
        jp      z, commandsp_volup
        cp      #0xF3
        jp      z, commandsp_voldown
        cp      #0xF9
        jp      z, commandsp_stloop
        cp      #0xF8
        jp      z, commandsp_edloop
        call    pmdneo_part_fetch_byte
        ret
commandsp_t:
        jp      comt
commandsp_v:
        jp      comv
commandsp_V:
        jp      comV
commandsp_q:
        jp      comq
commandsp_q2:
        jp      comq2
commandsp_q3:
        jp      comq3
commandsp_q4:
        jp      comq4
commandsp_vshift_up:
        jp      comvshift_up
commandsp_vshift_down:
        jp      comvshift_down
commandsp_vscale_up:
        jp      comvscale_up
commandsp_vscale_down:
        jp      comvscale_down
commandsp_volup:
        jp      comvolup
commandsp_voldown:
        jp      comvoldown
commandsp_stloop:
        jp      comstloop
commandsp_edloop:
        jp      comedloop

;; Phase 9a: comq (= PMD MML "q" gate cmd、 0xFE)
;; A = QDATA value (= note 長 vs key off timing 制御、 0-15 で gate 段階)
;; PMD_Z80.inc line 1782 から移植。 PART_OFF_QDATA / QDAT3 は既に SRAM 確保済
;; (= per-part offset 5 / 8、 dispatch 共通化 refactor 前から).
;; Phase 9a 範囲: QDATA 値設定のみ実装。 actual gate 効果 (= note dispatch で
;; PART_OFF_LEN を QDATA で減算) は Phase 9b で pmdneo_part_main_note に実装.
comq:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_QDATA(ix), a
        xor     a
        ld      PART_OFF_QDAT3(ix), a
        ret

comq2:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_QDATB(ix), a
        ret

comq3:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_QDAT2(ix), a
        ret

comq4:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_QDAT3(ix), a
        ret

fnumsetp_ch:
        jp      fnumset_ssg

fm_keyon_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    fnumset_fm
        ld      b, PART_OFF_CH_IDX(ix)
        call    fm_keyon
        ret

fm_keyoff_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    fm_keyoff
        ret

fnumset_fm_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    fnumset_fm
        ret

;; Phase 9c (post-Codex): fm_volume_hook 実 TL 書換実装
;; PART_OFF_VOLUME (= V cmd 0-255) → TL 値 (= 0x7F = mute / 0x00 = max)
;; 4 op (= reg 0x40, 0x44, 0x48, 0x4C + ch index) 同期書込
;; ALG 7 全 op carrier 想定、 全 op 同 TL で audible 設定
fm_volume_hook:
        ld      a, PART_OFF_VOLUME(ix)
        srl     a                       ; A = V/2 (0-127)
        ld      l, a
        ld      a, #0x7F
        sub     l                       ; A = 0x7F - V/2 = TL (V=0 → TL 0x7F mute)
        ld      c, a                    ; C = TL value
        ld      a, PART_OFF_CH_IDX(ix)
        cp      #3
        jr      nc, fm_volume_hook_portb
        ;; port A (= ch index 0-2)
        add     a, #0x40
        ld      b, a                    ; B = reg 0x40 + ch
        push    bc
        call    ym2610_write_port_a
        pop     bc
        push    bc
        ld      a, b
        add     a, #4
        ld      b, a                    ; reg 0x44 + ch
        call    ym2610_write_port_a
        pop     bc
        push    bc
        ld      a, b
        add     a, #8
        ld      b, a                    ; reg 0x48 + ch
        call    ym2610_write_port_a
        pop     bc
        ld      a, b
        add     a, #12
        ld      b, a                    ; reg 0x4C + ch
        call    ym2610_write_port_a
        ret
fm_volume_hook_portb:
        sub     #3                      ; ch index 0-2 for port B
        add     a, #0x40
        ld      b, a
        push    bc
        call    ym2610_write_port_b
        pop     bc
        push    bc
        ld      a, b
        add     a, #4
        ld      b, a
        call    ym2610_write_port_b
        pop     bc
        push    bc
        ld      a, b
        add     a, #8
        ld      b, a
        call    ym2610_write_port_b
        pop     bc
        ld      a, b
        add     a, #12
        ld      b, a
        call    ym2610_write_port_b
        ret

psg_keyon_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    pmdneo_psg_keyon
        ret

ssg_keyoff_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    ssg_keyoff
        ret

fnumsetp_ch_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        call    fnumsetp_ch
        ret

;; Phase 9c fix: psg_volume_hook 実装 (= SSG vol reg 直接書込)
;; PART_OFF_VOLUME 値 (= 0-15、 V cmd 受領後 v→V 変換 経由) を SSG vol reg に反映
;; reg 0x08-0x0A (= ch1/2/3 vol、 bit 0-3 vol、 bit 4 envelope select)
psg_volume_hook:
        ld      hl, #psg_volume_regs
        ld      a, PART_OFF_CH_IDX(ix)
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)                 ; B = reg 0x08+ch
        ld      a, PART_OFF_VOLUME(ix)
        and     #0x0F                   ; vol 0-15
        ld      c, a
        call    ym2610_write_port_a
        ret

adpcmb_keyon_hook:
        ld      b, #0
        call    adpcmb_keyon
        ret

adpcmb_keyoff_hook:
        call    adpcmb_keyoff
        ret

adpcma_keyon_hook:
        ld      b, PART_OFF_CH_IDX(ix)
        ld      a, b
        call    adpcma_keyon_simple
        ret

adpcma_keyoff_hook:
        ret

noop_hook:
        ret

pmdneo_psg_keyon:
        push    bc
        call    fnumsetp_ch
        pop     bc
        ld      hl, #psg_volume_regs
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)
        ld      a, PART_OFF_VOLUME(ix)
        and     #0x0F
        ld      c, a
        call    ym2610_write_port_a
        ret

adpcmb_keyon:
        call    init_adpcmb_beat
        ret

adpcmb_keyoff:
        ld      b, #0x10
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x10
        ld      c, #0x00
        call    ym2610_write_port_a
        ret

adpcma_init:
        ld      b, #0x00
        ld      c, #0xBF
        call    ym2610_write_port_b
        ld      b, #0x01
        ld      c, #0x3F
        call    ym2610_write_port_b
        ret

;;; adpcma_keyon_simple: A = ADPCM-A channel index (0..5).
adpcma_keyon_simple:
        and     #0x07
        ld      b, a
        ld      l, a
        ld      h, #0
        add     hl, hl
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)

        ld      a, #0x10
        add     a, b
        push    bc
        ld      b, a
        ld      a, (de)
        ld      c, a
        call    ym2610_write_port_b
        pop     bc
        inc     de

        ld      a, #0x18
        add     a, b
        push    bc
        ld      b, a
        ld      a, (de)
        ld      c, a
        call    ym2610_write_port_b
        pop     bc
        inc     de

        ld      a, #0x20
        add     a, b
        push    bc
        ld      b, a
        ld      a, (de)
        ld      c, a
        call    ym2610_write_port_b
        pop     bc
        inc     de

        ld      a, #0x28
        add     a, b
        push    bc
        ld      b, a
        ld      a, (de)
        ld      c, a
        call    ym2610_write_port_b
        pop     bc

        ;; Write vol register 0x08+ch: PAN_BITS | PART_OFF_VOLUME
        push    bc
        ld      hl, #adpcma_pan_bits
        ld      e, b
        ld      d, #0
        add     hl, de
        ld      a, (hl)
        or      PART_OFF_VOLUME(ix)
        ld      c, a
        ld      a, b
        add     a, #0x08
        ld      b, a
        call    ym2610_write_port_b
        pop     bc

        ld      l, b
        ld      h, #0
        ld      de, #adpcma_ch_bit_table
        add     hl, de
        ld      b, #0x00
        ld      c, (hl)
        call    ym2610_write_port_b
        ret

;;; adpcma_keyoff: B = ADPCM-A channel index (0..5).
adpcma_keyoff:
        ld      l, b
        ld      h, #0
        ld      de, #adpcma_ch_bit_table
        add     hl, de
        ld      a, (hl)
        or      #0x80
        ld      b, #0x00
        ld      c, a
        call    ym2610_write_port_b
        ret

adpcma_ch_bit_table:
        .db     0x01, 0x02, 0x04, 0x08, 0x10, 0x20

adpcma_pan_bits:
        .db     0xC0, 0x40, 0x80, 0x40, 0xC0, 0x80

adpcma_ch_sample_ptr_table:
        .dw     adpcma_sample_bd, adpcma_sample_sd, adpcma_sample_hh
        .dw     adpcma_sample_tom, adpcma_sample_rim, adpcma_sample_top

adpcma_sample_bd:
        .db     BD_START_LSB, BD_START_MSB, BD_STOP_LSB, BD_STOP_MSB
adpcma_sample_sd:
        .db     SD_START_LSB, SD_START_MSB, SD_STOP_LSB, SD_STOP_MSB
adpcma_sample_hh:
        .db     HH_START_LSB, HH_START_MSB, HH_STOP_LSB, HH_STOP_MSB
adpcma_sample_rim:
        .db     RIM_START_LSB, RIM_START_MSB, RIM_STOP_LSB, RIM_STOP_MSB
adpcma_sample_tom:
        .db     TOM_START_LSB, TOM_START_MSB, TOM_STOP_LSB, TOM_STOP_MSB
adpcma_sample_top:
        .db     TOP_START_LSB, TOP_START_MSB, TOP_STOP_LSB, TOP_STOP_MSB

rhythm_main:
        ret

psg_fine_regs:
        .db     0x00, 0x02, 0x04
psg_coarse_regs:
        .db     0x01, 0x03, 0x05
psg_volume_regs:
        .db     0x08, 0x09, 0x0A

v_to_V_fm:
        .db     85, 87, 90, 93, 95, 98, 101, 103, 106, 109, 111, 114, 117, 119, 122, 125, 127

v_to_V_pcm:
        .db     0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 255

;; Phase 9b chord-mode: BCEF が C major chord (= C/E/G/C5)、 q6 固定 staccato、
;; 8 note 全部同一音 (= 和音 sustain で gate 効果が見やすい)。 GHIJ/L-Q は silent
;; (= MML 即 end で dispatch skip、 chip も無音)。
song_part_b:
        .db     0xFC, 0x1C                 ; t140 (tempo_d=28)
        .db     0xFE, 0x06                 ; q6 (= gate 6 tick 減算、 staccato)
        .db     0xCC, 0x00                 ; ★ Phase 9c: V0 (= 大文字 V cmd、 silent 試験)
        .db     0x40, 0x20, 0x40, 0x20, 0x40, 0x20, 0x40, 0x20  ; B = C4 (= 0x40) × 8
        .db     0x40, 0x20, 0x40, 0x20, 0x40, 0x20, 0x40, 0x20
        .db     0x80
song_part_c:
        .db     0xFC, 0x1C                 ; t140 (tempo_d=28)
        .db     0xFE, 0x06                 ; q6
        .db     0x44, 0x20, 0x44, 0x20, 0x44, 0x20, 0x44, 0x20  ; C = E4 (= 0x44) × 8
        .db     0x44, 0x20, 0x44, 0x20, 0x44, 0x20, 0x44, 0x20
        .db     0x80
song_part_e:
        .db     0xFC, 0x1C                 ; t140 (tempo_d=28)
        .db     0xFE, 0x06                 ; q6
        .db     0x47, 0x20, 0x47, 0x20, 0x47, 0x20, 0x47, 0x20  ; E = G4 (= 0x47) × 8
        .db     0x47, 0x20, 0x47, 0x20, 0x47, 0x20, 0x47, 0x20
        .db     0x80
song_part_f:
        .db     0xFC, 0x1C                 ; t140 (tempo_d=28)
        .db     0xFE, 0x06                 ; q6
        .db     0x50, 0x20, 0x50, 0x20, 0x50, 0x20, 0x50, 0x20  ; F = C5 (= 0x50) × 8
        .db     0x50, 0x20, 0x50, 0x20, 0x50, 0x20, 0x50, 0x20
        .db     0x80
song_part_g:
        .db     0xCC, 0x00                 ; ★ Phase 9c fix: V0 で SSG ch1 silent
        .db     0x80
song_part_h:
        .db     0xCC, 0x00                 ; ★ V0 SSG ch2
        .db     0x80
song_part_i:
        .db     0xCC, 0x00                 ; ★ V0 SSG ch3
        .db     0x80
song_part_j:
        .db     0x80

song_part_l:
        .db     0x80                       ; Phase 9b chord-mode: silent (= 既存 nest LOOP off)
song_part_m:
        .db     0x80                       ; silent
song_part_n:
        .db     0x80
song_part_o:
        .db     0x80
song_part_p:
        .db     0x80
song_part_q:
        .db     0x80

        ;; Dummy DATA area to satisfy linker (= -b DATA=0xf800)
        .area DATA
