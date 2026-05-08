        .area _HEADER (ABS)

        .org 0x0000
        di
        im      1
        ld      sp, #0xFFFF
        xor     a
        out     (0x08), a
idle_loop:
        jp      idle_loop

        .org 0x0010
        ret

        .org 0x0018
        ret

        .org 0x0020
        ret

        .org 0x0028
        ret

        .org 0x0030
        ret

        .org 0x0038
        ei
        reti

        .org 0x0066
        ;; NMI handler at 0x0066: idempotent chip init.
        ;; Note: NEOGEO SM1 BIOS writes 0x18 0xFE to (0xFFFE)/(0xFFFF) as workarea,
        ;; so we cannot use a RAM init flag at 0xFFFE. Re-running chip init on every
        ;; NMI is harmless (= idempotent register writes) and avoids the collision.
        push    af
        push    bc
        in      a, (0x00)

        ;; --- chip init: all 30 register writes, unconditionally ---
        ld      a, #0xB1
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x07
        out     (5), a

        ld      a, #0x31
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x01
        out     (5), a

        ld      a, #0x35
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x01
        out     (5), a

        ld      a, #0x39
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x01
        out     (5), a

        ld      a, #0x3D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x01
        out     (5), a

        ld      a, #0x41
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x18
        out     (5), a

        ld      a, #0x45
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x18
        out     (5), a

        ld      a, #0x49
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x18
        out     (5), a

        ld      a, #0x4D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x18
        out     (5), a

        ld      a, #0x51
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x1F
        out     (5), a

        ld      a, #0x55
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x1F
        out     (5), a

        ld      a, #0x59
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x1F
        out     (5), a

        ld      a, #0x5D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x1F
        out     (5), a

        ld      a, #0x61
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x65
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x69
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x6D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x71
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x75
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x79
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x7D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x81
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x0F
        out     (5), a

        ld      a, #0x85
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x0F
        out     (5), a

        ld      a, #0x89
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x0F
        out     (5), a

        ld      a, #0x8D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x0F
        out     (5), a

        ld      a, #0x91
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x95
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x99
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0x9D
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x00
        out     (5), a

        ld      a, #0xA1
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x6A
        out     (5), a

        ld      a, #0xA5
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0x22
        out     (5), a

        ld      a, #0xB5
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0xC0
        out     (5), a

        ld      a, #0x28
        out     (4), a
        nop
        nop
        nop
        nop
        nop
        nop
        ld      a, #0xF1
        out     (5), a

        ;; --- end chip init ---
        pop     bc
        pop     af
        retn

        ;; Dummy DATA area to satisfy linker (= -b DATA=0xf800)
        .area DATA
