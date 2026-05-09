        .equ    driver_state_init_flag,  0xF810
        .equ    driver_song_ready,       0xF811
        .equ    driver_adpcmb_done_flag, 0xF812
        .equ    scale_step,              0xF813
        .equ    scale_tick_lo,           0xF814
        .equ    scale_tick_hi,           0xF815
        .equ    pmdneo_irq_count,        0xF816
        .equ    driver_tempo_d,          0xF817   ; 1 byte BPM-encoded accumulator delta
        .equ    driver_subtick_acc,      0xF818   ; 1 byte 8-bit overflow accumulator

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
        .equ    PART_OFF_LOOPSTACK_BASE, 32
        .equ    PART_OFF_LOOPDEPTH,      48
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
        call    pmdneo5_clear_part_workarea

        ld      a, #PART_FM2
        ld      hl, #song_part_b
        ld      b, #1
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_FM3
        ld      hl, #song_part_c
        ld      b, #2
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_FM5
        ld      hl, #song_part_e
        ld      b, #4
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_FM6
        ld      hl, #song_part_f
        ld      b, #5
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_SSG1
        ld      hl, #song_part_g
        ld      b, #0
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_SSG2
        ld      hl, #song_part_h
        ld      b, #1
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_SSG3
        ld      hl, #song_part_i
        ld      b, #2
        ld      c, #0x0F
;;      call    pmdneo5_init_part
        ld      a, #PART_PCM
        ld      hl, #song_part_j
        ld      b, #0
        ld      c, #0
;;      call    pmdneo5_init_part
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
        cp      #PART_SSG1
        jp      c, pmdneo_song_main_fm
        cp      #PART_PCM
        jp      c, pmdneo_song_main_psg
        cp      #PART_PCM
        jp      z, pmdneo_song_main_pcm
        cp      #PART_RHYTHM
        jp      z, pmdneo_song_main_rhythm
        jp      pmdneo_song_main_adpcma

pmdneo_song_main_fm:
        ld      b, c
        call    fmmain
        jp      pmdneo_song_main_after

pmdneo_song_main_psg:
        ld      a, c
        sub     #PART_SSG1
        ld      b, a
        call    pmdneo_psgmain
        jp      pmdneo_song_main_after

pmdneo_song_main_pcm:
        ld      b, #0
        call    adpcmb_main
        jp      pmdneo_song_main_after

pmdneo_song_main_rhythm:
        call    rhythm_main
        jp      pmdneo_song_main_after

pmdneo_song_main_adpcma:
        call    adpcma_main

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

pmdneo_scale_mml_length:
        or      a
        ret     nz
        inc     a
        ret

comt:
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d), a
        ret

comv:
        call    pmdneo_part_fetch_byte
        and     #0x1F
        ld      PART_OFF_VOLUME(ix), a
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
comedloop_done:
        pop     bc
        ret

commandsp:
        cp      #0xFC
        jp      z, commandsp_t
        cp      #0xFD
        jp      z, commandsp_v
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
commandsp_stloop:
        jp      comstloop
commandsp_edloop:
        jp      comedloop

fnumsetp_ch:
        jp      fnumset_ssg

fmmain:
        ld      a, PART_OFF_LEN(ix)
        or      a
        jp      z, fmmain_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        jp      nz, fmmain_done
        call    fm_keyoff

fmmain_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, fmmain_loop
        jp      c, fmmain_note
        call    commandsp
        jp      fmmain_parse

fmmain_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ld      a, PART_OFF_NOTE(ix)
        push    bc
        call    fnumset_fm
        pop     bc
        call    fm_keyon
        ret

fmmain_loop:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jp      z, fmmain_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jp      fmmain_parse

fmmain_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

fmmain_done:
        ret

pmdneo_psgmain:
        ld      a, PART_OFF_LEN(ix)
        or      a
        jp      z, pmdneo_psgmain_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        jp      nz, pmdneo_psgmain_done
        call    ssg_keyoff

pmdneo_psgmain_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, pmdneo_psgmain_loop
        jp      c, pmdneo_psgmain_note
        call    commandsp
        jp      pmdneo_psgmain_parse

pmdneo_psgmain_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ld      a, PART_OFF_NOTE(ix)
        call    pmdneo_psg_keyon
        ret

pmdneo_psgmain_loop:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jp      z, pmdneo_psgmain_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jp      pmdneo_psgmain_parse

pmdneo_psgmain_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

pmdneo_psgmain_done:
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

adpcmb_main:
        ld      a, PART_OFF_LEN(ix)
        or      a
        jp      z, adpcmb_main_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        jp      nz, adpcmb_main_done
        call    adpcmb_keyoff

adpcmb_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, adpcmb_main_loop
        jp      c, adpcmb_main_note
        call    commandsp
        jp      adpcmb_main_parse

adpcmb_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        call    adpcmb_keyon
        ret

adpcmb_main_loop:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jp      z, adpcmb_main_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jp      adpcmb_main_parse

adpcmb_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

adpcmb_main_done:
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

adpcma_main:
        ld      a, PART_OFF_LEN(ix)
        or      a
        jp      z, adpcma_main_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        jp      nz, adpcma_main_done

adpcma_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jp      z, adpcma_main_loop
        cp      #0x90
        jp      z, adpcma_main_rest
        jp      c, adpcma_main_note
        call    commandsp
        jp      adpcma_main_parse

adpcma_main_rest:
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ret

adpcma_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ld      a, PART_OFF_CH_IDX(ix)
        call    adpcma_keyon_simple
        ret

adpcma_main_loop:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jp      z, adpcma_main_clear
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jp      adpcma_main_parse

adpcma_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

adpcma_main_done:
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

song_part_b:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x40, 0x20, 0x42, 0x20, 0x44, 0x20, 0x45, 0x20
        .db     0x47, 0x20, 0x49, 0x20, 0x4B, 0x20, 0x50, 0x20
        .db     0x80
song_part_c:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x44, 0x20, 0x45, 0x20, 0x47, 0x20, 0x49, 0x20
        .db     0x4B, 0x20, 0x50, 0x20, 0x52, 0x20, 0x54, 0x20
        .db     0x80
song_part_e:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x47, 0x20, 0x49, 0x20, 0x4B, 0x20, 0x50, 0x20
        .db     0x52, 0x20, 0x54, 0x20, 0x55, 0x20, 0x57, 0x20
        .db     0x80
song_part_f:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x50, 0x20, 0x52, 0x20, 0x54, 0x20, 0x55, 0x20
        .db     0x57, 0x20, 0x59, 0x20, 0x5B, 0x20, 0x60, 0x20
        .db     0x80
song_part_g:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x40, 0x20, 0x42, 0x20, 0x44, 0x20, 0x45, 0x20
        .db     0x47, 0x20, 0x49, 0x20, 0x4B, 0x20, 0x50, 0x20
        .db     0x80
song_part_h:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x44, 0x20, 0x45, 0x20, 0x47, 0x20, 0x49, 0x20
        .db     0x4B, 0x20, 0x50, 0x20, 0x52, 0x20, 0x54, 0x20
        .db     0x80
song_part_i:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x47, 0x20, 0x49, 0x20, 0x4B, 0x20, 0x50, 0x20
        .db     0x52, 0x20, 0x54, 0x20, 0x55, 0x20, 0x57, 0x20
        .db     0x80
song_part_j:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0x40, 0x20, 0x40, 0x20, 0x40, 0x20, 0x40, 0x20
        .db     0x40, 0x20, 0x40, 0x20, 0x40, 0x20, 0x40, 0x20
        .db     0x80

song_part_l:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x1F                 ; v31 (BD max)
song_part_l_loop:
        .db     0xF9
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0xF8, 4
        .db     0x80
song_part_m:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x1C                 ; v28 (SD)
song_part_m_loop:
        .db     0xF9
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0xF8, 4
        .db     0x80
song_part_n:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x0E                 ; v14 (HH)
song_part_n_loop:
        .db     0xF9
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0xF8, 4
        .db     0x80
song_part_o:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x18                 ; v24 (TOM)
song_part_o_loop:
        .db     0xF9
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0x40, 0x18
        .db     0xF8, 4
        .db     0x80
song_part_p:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x16                 ; v22 (RIM)
song_part_p_loop:
        .db     0xF9
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0xF8, 4
        .db     0x80
song_part_q:
        .db     0xFC, 0x18                 ; t120 (tempo_d=24)
        .db     0xFD, 0x1A                 ; v26 (TOP)
song_part_q_loop:
        .db     0xF9
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x40, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0x90, 0x18
        .db     0xF8, 4
        .db     0x80

        ;; Dummy DATA area to satisfy linker (= -b DATA=0xf800)
        .area DATA
