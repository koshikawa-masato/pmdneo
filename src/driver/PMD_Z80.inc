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

        ;; driver 共通 state を初期化
        ld      hl, #0
        ld      (driver_tempo_d), hl
        ld      (driver_tempo_48), hl
        ld      (driver_psg_noise), hl
        ld      (driver_tieflag), hl
        ld      (driver_song_ready), hl
        ld      (driver_song_base), hl
        ld      (driver_song_end), hl

        ;; SubB-4: scale state init
        xor     a
        ld      (scale_step), a

        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

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

        ;; driver_song_ready が立っている場合は PSG 解析ルートへ
        ld      a, (driver_song_ready)
        or      a
        jr      z, pmd_z80_main_scale

        call    pmdneo_song_main
        ret

pmd_z80_main_scale:

        ;; scale_tick decrement (16 bit)
        ld      hl, (scale_tick_lo)
        ld      a, h
        or      l
        jr      z, pmd_z80_main_scale_step
        dec     hl
        ld      (scale_tick_lo), hl
        ld      a, h
        or      l
        ret     nz                      ; tick 残ってる → return

        ;; tick 0 → 次 step に進む
pmd_z80_main_scale_step:
        ld      a, (scale_step)
        cp      #0xFF
        ret     z                       ; scale test stopped
        cp      #8
        jr      nc, pmd_z80_main_scale_stop

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
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        ret

pmd_z80_main_scale_stop:
        ;; 最後の音を約 1 秒鳴らした後に停止
        ld      b, #0
        call    pmdneo_psg_keyoff
        ld      b, #1
        call    pmdneo_psg_keyoff
        ld      b, #2
        call    pmdneo_psg_keyoff
        ld      a, #0xFF
        ld      (scale_step), a
        xor     a
        ld      (scale_tick_lo), a
        ld      (scale_tick_hi), a
        ret


;;; ----- fnumsetp: note byte → SSG ch A fine/coarse tune -----
;;;
;;; 入力: A = note byte (= OCT 4 bit 上位 + ONKAI 4 bit 下位)
;;; 動作:
;;;   1. ONKAI で psg_tune_data[ONKAI × 2] (= OCT 0 ベース 16-bit freq) を取得
;;;   2. OCT 回 right shift (= 1 octave あたり counter / 2)
;;;   3. SSG ch A fine tune (LSB) + coarse tune (MSB) に書込
;;; 破壊: A、 B、 C、 D、 E、 H、 L
;;;
;;; SubB-5 以降は B = channel index (0=A, 1=B, 2=C) で他 ch へ再利用する。

fnumsetp::
        ld      b, #0
        jp      fnumsetp_ch

fnumsetp_ch::
        push    af                      ; note byte 保存
        push    bc                      ; channel index 保存

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
        pop     bc                      ; channel index 復帰
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
        ;; ch ごとの register を引く
        push    bc                      ; channel index を保持
        push    de
        ld      hl, #psg_fine_regs
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)
        pop     de
        ld      c, e
        call    ym2610_write_port_a

        pop     bc                      ; channel index を戻す
        push    bc
        push    de
        ld      hl, #psg_coarse_regs
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)
        pop     de
        ld      c, d
        call    ym2610_write_port_a

        pop     bc                      ; channel index 保存を解除

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

        ;; scale_tick reset (次の note までの時間、 実測 0x0800 の約 1/40)
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        ret


;;; ----- test_play_psgmain: SubB-5/6 PSG main 単体検証開始 -----
;;;
;;; hardcoded MML byte 列を SSG1 workarea に設定し、 driver_song_ready を
;;; 立てて pmd_z80_main の PSG 解析ルートを駆動する。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L、 IX

test_play_psgmain::
        ;; SSG volume A = 0x0F (max)
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x0F
        call    ym2610_write_port_a

        ;; SSG1 (G part) に test_mml_data を設定
        ld      a, #PART_SSG1
        call    pmdneo_part_ix_from_part
        ld      hl, #test_mml_data
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        xor     a
        ld      PART_OFF_LOOP(ix), a
        ld      PART_OFF_LOOP+1(ix), a
        ld      PART_OFF_LEN(ix), a
        ld      a, #0x0F
        ld      PART_OFF_VOLUME(ix), a

        ;; 念のため未使用 PSG part は停止状態に固定
        ld      a, #PART_SSG2
        call    pmdneo_part_ix_from_part
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ld      a, #PART_SSG3
        call    pmdneo_part_ix_from_part
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

        ;; song mode に切替
        ld      a, #1
        ld      (driver_song_ready), a

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
;;; 実機/エミュレータ実測で 0x0800 が約 38 sec だったため、
;;; SubB-4 では 0x0800 / 40 ≒ 0x0033 を 1 note の duration にする。

SCALE_TICK_INITIAL = 0x0033


;;; ----- test_mml_data: PSG main 検証用 hardcoded MML -----
;;;
;;; note byte, length byte の列。 0x80 で part end。

test_mml_data:
        .db     0x10, 0x33              ; C4 (ド)
        .db     0x12, 0x33              ; D4 (レ)
        .db     0x14, 0x33              ; E4 (ミ)
        .db     0x15, 0x33              ; F4 (ファ)
        .db     0x17, 0x33              ; G4 (ソ)
        .db     0x19, 0x33              ; A4 (ラ)
        .db     0x1B, 0x33              ; B4 (シ)
        .db     0x20, 0x33              ; C5 (1 octave 上のド)
        .db     0x80                    ; part end


;;; ----- PSG / part helper -----

pmdneo_song_main::
        ld      a, #PART_SSG1
        call    pmdneo_psgmain
        ld      a, #PART_SSG2
        call    pmdneo_psgmain
        ld      a, #PART_SSG3
        call    pmdneo_psgmain
        ret


;;; pmdneo_part_ix_from_part:
;;;   input : A = part index
;;;   output: IX = part_workarea + A * PART_WORKAREA_SIZE

pmdneo_part_ix_from_part::
        ld      l, a
        ld      h, #0
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl                      ; *64
        ld      de, #part_workarea
        add     hl, de
        push    hl
        pop     ix
        ret


;;; pmdneo_part_fetch_byte:
;;;   IX = current part workarea
;;;   返値 A = *addr、 addr を 1 byte 進める

pmdneo_part_fetch_byte::
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      a, (hl)
        inc     hl
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ret


;;; pmdneo_psg_keyon / keyoff

pmdneo_psg_keyon::
        ;; A = note byte, B = channel index
        call    fnumsetp_ch

        ld      hl, #psg_volume_regs
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)
        ld      c, PART_OFF_VOLUME(ix)
        ld      a, c
        and     #0x0F
        ld      c, a
        call    ym2610_write_port_a
        ret

pmdneo_psg_keyoff::
        push    bc
        ld      hl, #psg_volume_regs
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, (hl)
        ld      c, #0x00
        call    ym2610_write_port_a
        pop     bc
        ret


;;; ----- pmdneo_psgmain: PSG part 1 step -----
;;;
;;; いまは SubB-5/6 の骨格。 driver_song_ready が立った後に
;;; .m stream を part_workarea に流し込む前提で動かす。
;;; 未初期化 part は addr=0 で即 return。

pmdneo_psgmain::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af
        sub     #PART_SSG1
        ld      b, a                        ; channel index (0-2)

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, pmdneo_psgmain_parse

        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, pmdneo_psgmain_done

        ;; length == 0 になったら keyoff して次 token へ進む
        call    pmdneo_psg_keyoff

pmdneo_psgmain_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, pmdneo_psgmain_end
        jr      c, pmdneo_psgmain_note
        cp      #0xB1
        jr      c, pmdneo_psgmain_clear

        call    commandsp
        jr      pmdneo_psgmain_parse

pmdneo_psgmain_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_LEN(ix), a

        ld      a, PART_OFF_NOTE(ix)
        call    pmdneo_psg_keyon
        ret

pmdneo_psgmain_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, pmdneo_psgmain_clear

        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      pmdneo_psgmain_parse

pmdneo_psgmain_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

pmdneo_psgmain_done:
        ret


;;; ----- commandsp / cmdtblp -----

commandsp::
        cp      #0xB1
        ret     c

        cpl
        add     a, a
        ld      l, a
        ld      h, #0
        ld      de, #cmdtblp
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        push    de
        ret


;;; PSG 用 dispatch table
;;;
;;; 0xFF から 0xB1 までの 79 entry。 未実装 entry は jumpN で
;;; arg byte を消費して無害化する。

cmdtblp:
        .dw     jump1                       ; 0xFF @
        .dw     comq                        ; 0xFE q
        .dw     comv                        ; 0xFD v
        .dw     comt                        ; 0xFC t
        .dw     comtie                      ; 0xFB &
        .dw     comd                        ; 0xFA D
        .dw     comstloop                   ; 0xF9 [
        .dw     comedloop                   ; 0xF8 ]
        .dw     comexloop                   ; 0xF7 :
        .dw     comlopset                   ; 0xF6 L
        .dw     comshift                    ; 0xF5 _
        .dw     comvolupp                   ; 0xF4 )
        .dw     comvoldownp                 ; 0xF3 (
        .dw     lfoset                      ; 0xF2 M
        .dw     lfoswitch                   ; 0xF1 *
        .dw     psgenvset                   ; 0xF0 E
        .dw     comy                        ; 0xEF y
        .dw     psgnoise                    ; 0xEE w
        .dw     psgsel                      ; 0xED P
        .dw     jump1                       ; 0xEC p (PSG pan なし)
        .dw     rhykey                      ; 0xEB
        .dw     rhyvs                       ; 0xEA
        .dw     rpnset                      ; 0xE9
        .dw     rmsvs                       ; 0xE8
        .dw     comshift2                   ; 0xE7
        .dw     rmsvs_sft                   ; 0xE6
        .dw     rhyvs_sft                   ; 0xE5
        .dw     jump1                       ; 0xE4 hardware LFO delay なし
        .dw     comvolupp2                  ; 0xE3
        .dw     comvoldownp2                ; 0xE2
        .dw     jump1                       ; 0xE1 hardware LFO なし
        .dw     jump1                       ; 0xE0 hardware LFO なし
        .dw     syousetu_lng_set            ; 0xDF
        .dw     vol_one_up_psg              ; 0xDE
        .dw     vol_one_down                ; 0xDD
        .dw     status_write                ; 0xDC
        .dw     status_add                  ; 0xDB
        .dw     portap                      ; 0xDA
        .dw     jump1                       ; 0xD9
        .dw     jump1                       ; 0xD8
        .dw     jump1                       ; 0xD7
        .dw     mdepth_set                  ; 0xD6
        .dw     comdd                       ; 0xD5
        .dw     ssg_efct_set                ; 0xD4
        .dw     fm_efct_set                 ; 0xD3
        .dw     fade_set                    ; 0xD2
        .dw     jump1                       ; 0xD1
        .dw     psgnoise_move               ; 0xD0
        .dw     jump1                       ; 0xCF
        .dw     jump6                       ; 0xCE
        .dw     extend_psgenvset            ; 0xCD
        .dw     detune_extend               ; 0xCC
        .dw     lfowave_set                 ; 0xCB
        .dw     lfo_extend                  ; 0xCA
        .dw     envelope_extend             ; 0xC9
        .dw     jump3                       ; 0xC8
        .dw     jump3                       ; 0xC7
        .dw     jump6                       ; 0xC6
        .dw     jump1                       ; 0xC5
        .dw     comq2                       ; 0xC4
        .dw     jump2                       ; 0xC3
        .dw     lfoset_delay                ; 0xC2
        .dw     jump0                       ; 0xC1
        .dw     ssg_mml_part_mask           ; 0xC0
        .dw     _lfoset                     ; 0xBF
        .dw     _lfoswitch                  ; 0xBE
        .dw     _mdepth_set                 ; 0xBD
        .dw     _lfowave_set                ; 0xBC
        .dw     _lfo_extend                 ; 0xBB
        .dw     jump1                       ; 0xBA
        .dw     _lfoset_delay               ; 0xB9
        .dw     jump2                       ; 0xB8
        .dw     mdepth_count                ; 0xB7
        .dw     jump1                       ; 0xB6
        .dw     jump2                       ; 0xB5
        .dw     jump16                      ; 0xB4
        .dw     comq3                       ; 0xB3
        .dw     comshift_master             ; 0xB2
        .dw     comq4                       ; 0xB1


;;; ----- jumpN -----

jump16:
        ld      de, #10
        add     hl, de
        ret

jump6:
        inc     hl
jump5:
        inc     hl
jump4:
        inc     hl
jump3:
        inc     hl
jump2:
        inc     hl
jump1:
        inc     hl
jump0:
        ret


;;; ----- PSG command handlers -----

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

comv:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_VOLUME(ix), a
        ret

comt:
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d), a
        ld      (driver_tempo_48), a
        ret

comtie:
        ld      a, #1
        ld      PART_OFF_TIEFLAG(ix), a
        ld      (driver_tieflag), a
        ret

comd:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_SHIFT(ix), a
        ret

comdd:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_SHIFT(ix)
        add     a, b
        ld      PART_OFF_SHIFT(ix), a
        ret

comstloop:
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      PART_OFF_LOOP(ix), l
        ld      PART_OFF_LOOP+1(ix), h
        xor     a
        ld      PART_OFF_LOOPCNT(ix), a
        ret

comedloop:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_LOOPCNT(ix), a
        call    pmdneo_part_fetch_byte
        ld      a, PART_OFF_LOOPCNT(ix)
        or      a
        jr      z, comedloop_back
        dec     a
        ld      PART_OFF_LOOPCNT(ix), a
        jr      nz, comedloop_back
        ret
comedloop_back:
        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ret

comexloop:
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ld      a, PART_OFF_LOOPCNT(ix)
        or      a
        ret     nz
        ret

comlopset:
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      PART_OFF_LOOP(ix), l
        ld      PART_OFF_LOOP+1(ix), h
        ret

comshift:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_SHIFT(ix), a
        ret

comshift2:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_SHIFT(ix)
        add     a, b
        ld      PART_OFF_SHIFT(ix), a
        ret

comvolupp:
        ld      a, PART_OFF_VOLUME(ix)
        inc     a
        cp      #16
        jr      c, comvolupp_set
        ld      a, #15
comvolupp_set:
        ld      PART_OFF_VOLUME(ix), a
        ret

comvolupp2:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        add     a, b
        cp      #16
        jr      c, comvolupp2_set
        ld      a, #15
comvolupp2_set:
        ld      PART_OFF_VOLUME(ix), a
        ret

comvoldownp:
        ld      a, PART_OFF_VOLUME(ix)
        or      a
        ret     z
        dec     a
        ld      PART_OFF_VOLUME(ix), a
        ret

comvoldownp2:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_VOLUME(ix)
        sub     b
        jr      nc, comvoldownp2_set
        xor     a
comvoldownp2_set:
        ld      PART_OFF_VOLUME(ix), a
        ret

lfoset:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_LFOSWI(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_FLAGS(ix), a
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_d_push), a
        call    pmdneo_part_fetch_byte
        ld      (driver_tempo_48_push), a
        ret

lfoset_delay:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_FLAGS(ix), a
        ret

lfoswitch:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_LFOSWI(ix), a
        ret

psgenvset:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PAT(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PV2(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PR1(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PR2(ix), a
        ret

extend_psgenvset:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PAT(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PV2(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PR1(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PR2(ix), a
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_ENVVOL(ix), a
        ret

psgnoise:
        call    pmdneo_part_fetch_byte
        ld      (driver_psg_noise), a
        ret

psgnoise_move:
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, (driver_psg_noise)
        add     a, b
        ld      (driver_psg_noise), a
        ret

psgsel:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_PSGPAT(ix), a
        ret

;;; --- PSG 以外の PSG table entry で触る no-op 群 ---

comy:
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ret

comvolup:
        jp      comvolupp

comvoldown:
        jp      comvoldownp

comvolup2:
        jp      comvolupp2

comvoldown2:
        jp      comvoldownp2

comshift_master:
        call    pmdneo_part_fetch_byte
        ret

status_write:
        call    pmdneo_part_fetch_byte
        ret

status_add:
        call    pmdneo_part_fetch_byte
        ret

porta:
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ret

portap:
        call    pmdneo_part_fetch_byte
        ret

mdepth_set:
        call    pmdneo_part_fetch_byte
        ret

fade_set:
        call    pmdneo_part_fetch_byte
        ret

ssg_efct_set:
        call    pmdneo_part_fetch_byte
        ret

fm_efct_set:
        call    pmdneo_part_fetch_byte
        ret

syousetu_lng_set:
        call    pmdneo_part_fetch_byte
        ret

ssg_mml_part_mask:
        call    pmdneo_part_fetch_byte
        ret

vol_one_up_psg:
        ld      a, PART_OFF_VOLUME(ix)
        inc     a
        cp      #16
        jr      c, vol_one_up_psg_set
        ld      a, #15
vol_one_up_psg_set:
        ld      PART_OFF_VOLUME(ix), a
        ret

vol_one_down:
        ld      a, PART_OFF_VOLUME(ix)
        or      a
        ret     z
        dec     a
        ld      PART_OFF_VOLUME(ix), a
        ret

lfowave_set:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_FLAGS(ix), a
        ret

lfo_extend:
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_FLAGS(ix), a
        ret

_lfoset:
        jp      lfoset

_lfoswitch:
        jp      lfoswitch

_mdepth_set:
        jp      mdepth_set

_lfowave_set:
        jp      lfowave_set

_lfo_extend:
        jp      lfo_extend

_lfoset_delay:
        jp      lfoset_delay

mdepth_count:
        ret

detune_extend:
        call    pmdneo_part_fetch_byte
        ret

envelope_extend:
        call    pmdneo_part_fetch_byte
        ret

;;; ----- PSG register table -----

psg_fine_regs:
        .db     REG_SSG_A_FINE_TUNE
        .db     REG_SSG_B_FINE_TUNE
        .db     REG_SSG_C_FINE_TUNE

psg_coarse_regs:
        .db     REG_SSG_A_COARSE_TUNE
        .db     REG_SSG_B_COARSE_TUNE
        .db     REG_SSG_C_COARSE_TUNE

psg_volume_regs:
        .db     REG_SSG_A_VOLUME
        .db     REG_SSG_B_VOLUME
        .db     REG_SSG_C_VOLUME
