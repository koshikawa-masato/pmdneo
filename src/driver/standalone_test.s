        .equ    driver_state_init_flag,  0xF810
        .equ    driver_song_ready,       0xF811
        .equ    driver_adpcmb_done_flag, 0xF812
        .equ    scale_step,              0xF813
        .equ    scale_tick_lo,           0xF814
        .equ    scale_tick_hi,           0xF815
        .equ    pmdneo_irq_count,        0xF816

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

        ld      b, #0x27
        ld      c, #0x40
        call    ym2610_write_port_a
        ld      b, #0x26
        ld      c, #0xFC
        call    ym2610_write_port_a
        ld      b, #0x27
        ld      c, #0x6A
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
        ld      a, #1
        ld      (driver_song_ready), a

        ld      a, #0x40
        call    fnumset_fm_ch2
        call    fm_ch2_keyon
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
        ld      c, #0x6A
        call    ym2610_write_port_a

        ld      hl, (pmdneo_irq_count)
        inc     hl
        ld      (pmdneo_irq_count), hl

        ld      a, (driver_song_ready)
        or      a
        jr      z, irq_done

        ld      hl, (scale_tick_lo)
        ld      a, h
        or      l
        jr      z, irq_scale_step_next
        dec     hl
        ld      (scale_tick_lo), hl
        jr      irq_done

irq_scale_step_next:
        ld      a, (scale_step)
        inc     a
        ld      (scale_step), a
        cp      #8
        jr      nc, irq_scale_end

        ;; ★ note 切替時 必ず keyoff → 新 fnum → keyon (= envelope edge trigger)
        ;;   2026-05-09 user 「note 順序が出鱈目」 audio 解析で keyoff 中間欠落確認、
        ;;   chip envelope legato 状態で fnum 切替 glitch を user 聴感が拾っていた。
        call    fm_ch2_keyoff

        ld      a, (scale_step)
        ld      e, a
        ld      d, #0
        ld      hl, #scale_notes_fm
        add     hl, de
        ld      a, (hl)
        call    fnumset_fm_ch2
        call    fm_ch2_keyon

        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl
        jr      irq_done

irq_scale_end:
        ld      b, #0x28
        ld      c, #0x01
        call    ym2610_write_port_a
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
fnumset_fm_ch2:
        push    af
        push    de
        and     #0x0F
        ld      l, a
        ld      h, #0
        add     hl, hl
        ld      de, #fnum_data
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)

        pop     hl
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
        ld      b, #0xA5
        ld      c, h
        push    de
        call    ym2610_write_port_a
        pop     de

        ld      b, #0xA1
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

fm_ch2_keyoff:
        ld      b, #0x28
        ld      c, #0x01
        call    ym2610_write_port_a
        ret

fm_ch2_keyon:
        ld      b, #0x28
        ld      c, #0xF1
        call    ym2610_write_port_a
        ret

        .org 0x0300
init_chip_ch2_voice:
        ld      b, #0xB1
        ld      c, #0x07
        call    ym2610_write_port_a

        ld      b, #0x31
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x35
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x39
        ld      c, #0x01
        call    ym2610_write_port_a
        ld      b, #0x3D
        ld      c, #0x01
        call    ym2610_write_port_a

        ld      b, #0x41
        ld      c, #0x18
        call    ym2610_write_port_a
        ld      b, #0x45
        ld      c, #0x18
        call    ym2610_write_port_a
        ld      b, #0x49
        ld      c, #0x18
        call    ym2610_write_port_a
        ld      b, #0x4D
        ld      c, #0x18
        call    ym2610_write_port_a

        ld      b, #0x51
        ld      c, #0x1F
        call    ym2610_write_port_a
        ld      b, #0x55
        ld      c, #0x1F
        call    ym2610_write_port_a
        ld      b, #0x59
        ld      c, #0x1F
        call    ym2610_write_port_a
        ld      b, #0x5D
        ld      c, #0x1F
        call    ym2610_write_port_a

        ld      b, #0x61
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x65
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x69
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x6D
        ld      c, #0x00
        call    ym2610_write_port_a

        ld      b, #0x71
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x75
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x79
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x7D
        ld      c, #0x00
        call    ym2610_write_port_a

        ld      b, #0x81
        ld      c, #0x0F
        call    ym2610_write_port_a
        ld      b, #0x85
        ld      c, #0x0F
        call    ym2610_write_port_a
        ld      b, #0x89
        ld      c, #0x0F
        call    ym2610_write_port_a
        ld      b, #0x8D
        ld      c, #0x0F
        call    ym2610_write_port_a

        ld      b, #0x91
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x95
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x99
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #0x9D
        ld      c, #0x00
        call    ym2610_write_port_a

        ld      b, #0xB5
        ld      c, #0xC0
        call    ym2610_write_port_a
        ret

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
