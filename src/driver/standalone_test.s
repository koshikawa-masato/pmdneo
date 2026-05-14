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
        .equ    driver_loop_cycle,         0xF81E   ; 1 byte: BD part LOOP cycle counter
        .equ    driver_song_id,            0xF81F   ; 1 byte: driver_state +0x0F, cold-cleared to song 0

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

        ;; ADR-0006 §B: PMDNEO target chip build flag
        ;;   0 = ym2610 (default、 公式 NEOGEO YM2610 想定、 A/D は init せず stream 読捨)
        ;;   1 = ym2610b (AES+ YM2610B 想定、 FM 6ch 全部発音、 A/D も init)
        ;; build infra (= ADR-0006 §「実装 plan」 §4) から override する経路は option C 別 sprint
        .equ    PMDNEO_TARGET_CHIP_YM2610B, 0

        ;; ADR-0016 step 3c: pmdneo_load_m の入力 label 切替 flag
        ;;   0 = sample_m_data (default、 sample_m.s 経路 = bin2db.py で .s 化 + .include)
        ;;   1 = pmddotnet_song (.incbin 経路 = build-poc.sh PMDNEO_M_RAW or PMDDOTNET_MML)
        ;; 同一 SAMPLE.M binary を 2 経路で取り込んだ際の driver load 整合 verify 用。
        ;; build infra (= build.mk PMDNEO_PREPROCESS_CMD) で sed 置換、 build-poc.sh
        ;; の env PMDNEO_USE_PMDDOTNET=1 で 1 に切替わる。
        .equ    PMDNEO_USE_PMDDOTNET, 0

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
        .equ    PART_OFF_LOOPSTART,      28   ;; L global loop marker address lo-byte
        .equ    PART_OFF_LOOPSTART_HI,   29   ;; L global loop marker address hi-byte
        .equ    PART_OFF_MASK,           30   ;; per-part mask flag (0=audible, 1=mask silent)
        ;; ADR-0016 step 5 β-2a: ADPCM-A voice index (= L body 0xFF nn の nn)
        ;; comat (CHIP_TYPE=2 path) で書込、 β-2b で adpcma_keyon_simple が読む
        .equ    PART_OFF_INSTRUMENT,     31   ;; 1 byte ADPCM-A voice idx (L-Q part only)
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
        ;; ADR-0006 §H: FM3Extend (= ch3 4-op individual mode 追加 voice)
        ;; driver 未実装、 hooks=noop で stream 読捨 (= ADR-0008 想定で本格実装)
        .equ    PART_FM3EXT_X,           17   ;; X
        .equ    PART_FM3EXT_Y,           18   ;; Y
        .equ    PART_FM3EXT_Z,           19   ;; Z
        .equ    PART_COUNT,              20

        .equ    part_workarea,           0xF820
        ;; 20 x 64 = 1280 bytes occupies 0xF820-0xFD1F (= ADR-0006 §A 20 part)

        ;; ADR-0022 step 8 + ADR-0023 step 9: PNE runtime block (= 0xFD20-0xFD32, 19 byte)
        ;;   driver_pne_filename_buf       0xFD20-0xFD2F  16 byte  NUL-terminated ASCII (= ADR-0022 §決定 4)
        ;;   driver_pne_filename_adr_word  0xFD30-0xFD31   2 byte  LE u16 m_buf-relative (= ADR-0022 §決定 4)
        ;;   driver_pne_sample_table_id    0xFD32          1 byte  resolver 出力 (= ADR-0023 §決定 4)
        ;;     0x00-0xFE = valid id、 0xFF = mismatch sentinel
        ;;     ADR-0023 step 9 α scope = data placement only、 まだ書込みされない (= resolver routine は β、 call は γ)
        ;;     ADR-0023 §決定 11: Step 9 内で playback decision に使用しない
        .equ    driver_pne_filename_buf,       0xFD20
        .equ    driver_pne_filename_adr_word,  0xFD30
        .equ    driver_pne_sample_table_id,    0xFD32

        ;; ADR-0025 step 11 α: PNE_SAMPLE_DIRECTORY_ENTRY_COUNT
        ;;   directory entry 数 + selector accepted id range の上限を兼ねる EQU 定数
        ;;   (= ADR-0025 §決定 4 / axis 3-b α' + ADR-0025 §決定 5 / axis 4-e、 1 定数で同期)
        ;;   α scope: declare のみ (= 既存 resolver は terminator driven、 selector は id=0x00 only-accept のまま)
        ;;   β scope: selector が `cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT` で id 上限判定に使用、 範囲外は sentinel silent
        ;;   entry 数を増減する将来 sprint では本 EQU の 1 行修正で driver 全体に伝播 (= magic number 排除)
        .equ    PNE_SAMPLE_DIRECTORY_ENTRY_COUNT, 2

        .include "assets/samples.inc"

;;; ----- Z80 SRAM layout (= 2 KB at 0xF800-0xFFFF) -----
;;;
;;;   0xF800 - 0xF80F   reserved future (16 bytes、cmd FIFO 検討中)
;;;   0xF810 - 0xF81F   driver_state (= 16 bytes 既存)
;;;   0xF820 - 0xFD1F   part_workarea (= 20 x 64 = 1280 bytes、ADR-0006 §A)
;;;   0xFD20 - 0xFD2F   driver_pne_filename_buf (= 16 bytes、ADR-0022 §決定 4)
;;;   0xFD30 - 0xFD31   driver_pne_filename_adr_word (= 2 bytes、ADR-0022 §決定 4)
;;;   0xFD32            driver_pne_sample_table_id (= 1 byte、ADR-0023 §決定 4、 α scope = placement only)
;;;   0xFD33 - 0xFFBF   free / 後続 phase 用 (= 653 bytes 余裕)
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
        in      a, (0x00)
        cp      #2
        jp      z, nmi_cmd_2_play_song
        cp      #5
        jp      z, nmi_cmd_5_adpcmb_beat
        cp      #6
        jp      z, nmi_cmd_6_fade_start
        cp      #9
        jp      c, nmi_done
        cp      #24
        jp      c, nmi_cmd_select_song
        cp      #38
        jp      c, nmi_cmd_mask_part
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

nmi_cmd_select_song:
        sub     #9
        ld      (driver_song_id), a
        jp      nmi_done

nmi_cmd_mask_part:
        ;; A = cmd byte (24..37) -> part_idx = A - 24 (0..13)
        sub     #24
        ld      l, a
        ld      h, #0
        ;; HL = part_idx * 64
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      de, #part_workarea
        add     hl, de
        push    hl
        pop     ix
        ld      a, #1
        ld      PART_OFF_MASK(ix), a
        jp      nmi_done

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
        dec     a                       ; ADR-0011: MML octave - 1 = chip block (= PMD V4.8s 規約「o5 c = MIDI C4」 整合)
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
        jp      pmdneo_fm_voice_set

pmdneo_fm_voice_set:
        push    hl
        ld      de, #24
        add     hl, de
        ld      d, #0xB0
        ld      c, (hl)
        call    pmdneo_fm_write_reg_ch

        pop     hl
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

;; ADR-0010: ADR-0001 期「FM ch1/ch4 不使用」 命名遺物。 ADR-0006 §B「ym2610b mode で 6 FM ch 全部発音」
;; 規律に追従、 ym2610b conditional で ch index 0 (A) / 3 (D) voice setup 追加。
;; 命名 refactor (= init_fm_audible_voices 等) は別 sprint。
init_chip_ch2_voice:
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #0                   ; chip ch 1 (A) [ym2610b 限定]
        call    pmdneo_fm_voice_set_default
.endif
        ld      b, #1                   ; chip ch 2 (B)
        call    pmdneo_fm_voice_set_default
        ld      b, #2                   ; chip ch 3 (C)
        call    pmdneo_fm_voice_set_default
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #3                   ; chip ch 4 (D) [ym2610b 限定]
        call    pmdneo_fm_voice_set_default
.endif
        ld      b, #4                   ; chip ch 5 (E)
        call    pmdneo_fm_voice_set_default
        ld      b, #5                   ; chip ch 6 (F)
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
        ;; Phase 12a-5b cleanup: 旧 SSG audible setup (= reg 0x07=0x38 tone enable
        ;; + vol 0x0F max) は撤去。 driver init 段階では SSG mute 維持 (= reg 0x07=0x3F
        ;; all disable + vol 0x00、 init で既設定済) で、 V cmd / V+/V- 等で必要時に
        ;; psg_volume_hook 経由で audible 化する設計。 user 「SSG ミュートに」 要望
        ;; (= 2026-05-10) で test04 audio gate 反映、 init audible で V0 反映までの
        ;; 数十 IRQ tick で SSG 残音する真因を解消。
        ;; ADR-0006 §B + Phase 9R R-5b 撤廃: 全 FM ch を Center (= 0xC0 = L+R 両側 enable) で初期化
        ;; ch1 (A) = port A reg 0xB4 [.if PMDNEO_TARGET_CHIP_YM2610B = ym2610b 限定]
        ;; ch2 (B) = port A reg 0xB5
        ;; ch3 (C) = port A reg 0xB6
        ;; ch4 (D) = port B reg 0xB4 [.if PMDNEO_TARGET_CHIP_YM2610B = ym2610b 限定]
        ;; ch5 (E) = port B reg 0xB5
        ;; ch6 (F) = port B reg 0xB6
        ;; PAN 値: bit 7 = L Output Enable、 bit 6 = R Output Enable
        ;;   0xC0 = L+R 両側 = Center、 0x80 = L only、 0x40 = R only、 0x00 = mute
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #0xB4
        ld      c, #0xC0                ; ch1 (A) = Center
        call    ym2610_write_port_a
.endif
        ld      b, #0xB5
        ld      c, #0xC0                ; ch2 (B) = Center
        call    ym2610_write_port_a
        ld      b, #0xB6
        ld      c, #0xC0                ; ch3 (C) = Center
        call    ym2610_write_port_a
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      b, #0xB4
        ld      c, #0xC0                ; ch4 (D) = Center
        call    ym2610_write_port_b
.endif
        ld      b, #0xB5
        ld      c, #0xC0                ; ch5 (E) = Center
        call    ym2610_write_port_b
        ld      b, #0xB6
        ld      c, #0xC0                ; ch6 (F) = Center
        call    ym2610_write_port_b
        call    pmdneo5_clear_part_workarea

        ;; ADR-0006 §A/§B: song_table は 20 stream 順 (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,X,Y,Z)
        ;; A/D は PMDNEO_TARGET_CHIP_YM2610B 時のみ init、 default (= ym2610) では stream 読捨
        ;; K (Rhythm) と X/Y/Z (FM3Extend) は常時 init、 hooks=noop で stream 読捨 (= 当面 mute)
        ld      a, #0
        call    load_song_part_addr
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      a, #PART_FM1
        ld      b, #0
        ld      c, #0x0F
        call    pmdneo5_init_part
.endif
        ld      a, #1
        call    load_song_part_addr
        ld      a, #PART_FM2
        ld      b, #1
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #2
        call    load_song_part_addr
        ld      a, #PART_FM3
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #3
        call    load_song_part_addr
.if PMDNEO_TARGET_CHIP_YM2610B
        ld      a, #PART_FM4
        ld      b, #3
        ld      c, #0x0F
        call    pmdneo5_init_part
.endif
        ld      a, #4
        call    load_song_part_addr
        ld      a, #PART_FM5
        ld      b, #4
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #5
        call    load_song_part_addr
        ld      a, #PART_FM6
        ld      b, #5
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #6
        call    load_song_part_addr
        ld      a, #PART_SSG1
        ld      b, #0
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #7
        call    load_song_part_addr
        ld      a, #PART_SSG2
        ld      b, #1
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #8
        call    load_song_part_addr
        ld      a, #PART_SSG3
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #9
        call    load_song_part_addr
        ld      a, #PART_PCM
        ld      b, #0
        ld      c, #0
        call    pmdneo5_init_part
        ;; ADR-0026 step 12 β: K part (= PART_RHYTHM) addr load 経路
        ;; PMDDOTNET_MML mode では pmddotnet_song の K part offset (= file byte 21-22 = m_buf[20..21]) から body addr を計算
        ;; legacy compile.py mode では既存 load_song_part_addr 経路 (= song_table[song_id*20 + 10*2])
.if PMDNEO_USE_PMDDOTNET == 1
        call    pmdneo_mn_direct_load_k_part_addr   ; HL = K body addr (= pmddotnet_song + 1 + K_offset)
.else
        ld      a, #10
        call    load_song_part_addr
.endif
        ld      a, #PART_RHYTHM
        ld      b, #0
        ld      c, #0
        call    pmdneo5_init_part
        ;; ADR-0016 step 5 γ-a: L-Q part = ADPCM-A ch 0-5 (= PART_ADPCMA1-6)
        ;; PMDNEO_USE_PMDDOTNET == 1 時のみ .MN direct path (= L-Q 汎用 routine)、
        ;; 0 時は legacy compile.py 経路 (= load_song_part_addr) を維持。
        ;; α-2 (L only) → γ-a (L-Q 全 6 part) 拡張。
        ;; .MN layout ground truth: docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #0                  ; lq idx 0 = L
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #11
        call    load_song_part_addr     ; HL = L body addr (= legacy compile.py 経路)
.endif
        ld      a, #PART_ADPCMA1
        ld      b, #0
        ld      c, #0x00
        call    pmdneo5_init_part
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #1                  ; lq idx 1 = M
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #12
        call    load_song_part_addr
.endif
        ld      a, #PART_ADPCMA2
        ld      b, #1
        ld      c, #0x00
        call    pmdneo5_init_part
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #2                  ; lq idx 2 = N
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #13
        call    load_song_part_addr
.endif
        ld      a, #PART_ADPCMA3
        ld      b, #2
        ld      c, #0x00
        call    pmdneo5_init_part
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #3                  ; lq idx 3 = O
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #14
        call    load_song_part_addr
.endif
        ld      a, #PART_ADPCMA4
        ld      b, #3
        ld      c, #0x00
        call    pmdneo5_init_part
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #4                  ; lq idx 4 = P
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #15
        call    load_song_part_addr
.endif
        ld      a, #PART_ADPCMA5
        ld      b, #4
        ld      c, #0x00
        call    pmdneo5_init_part
.if PMDNEO_USE_PMDDOTNET == 1
        ld      a, #5                  ; lq idx 5 = Q
        call    pmdneo_mn_direct_load_lq_part_addr
.else
        ld      a, #16
        call    load_song_part_addr
.endif
        ld      a, #PART_ADPCMA6
        ld      b, #5
        ld      c, #0x00
        call    pmdneo5_init_part
        ld      a, #17
        call    load_song_part_addr
        ld      a, #PART_FM3EXT_X
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #18
        call    load_song_part_addr
        ld      a, #PART_FM3EXT_Y
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part
        ld      a, #19
        call    load_song_part_addr
        ld      a, #PART_FM3EXT_Z
        ld      b, #2
        ld      c, #0x0F
        call    pmdneo5_init_part

        ld      a, #1
        ld      (driver_song_ready), a
        ret

pmdneo5_clear_part_workarea:
        ld      hl, #part_workarea
        ld      de, #part_workarea + 1
        ld      bc, #1279
        xor     a
        ld      (hl), a
        ldir
        ret

;;; A=part table index (0=b, 1=c, 2=e, 3=f, 4=g, 5=h, 6=i, 7=j,
;;;                     8=l, 9=m, 10=n, 11=o, 12=p, 13=q)
;;; Return HL=song data address selected by driver_song_id. AF preserved.
load_song_part_addr:
        push    af
        ld      c, a
        ld      hl, #driver_song_id
        ld      a, (hl)
        ld      h, #0
        ld      l, a
        add     hl, hl
        add     hl, hl
        ld      d, h
        ld      e, l
        add     hl, hl
        add     hl, hl
        add     hl, hl
        ld      b, h
        ld      a, l
        sub     e
        ld      l, a
        ld      a, b
        sbc     a, d
        ld      h, a
        ld      a, c
        add     a, a
        add     a, l
        ld      l, a
        adc     a, h
        sub     l
        ld      h, a
        ld      de, #song_table
        add     hl, de
        ld      a, (hl)
        inc     hl
        ld      h, (hl)
        ld      l, a
        pop     af
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
        ;; ADR-0006 §H: X/Y/Z (= FM3Extend) は chip_type=FM 扱い、 hooks=noop (= 当面 mute)
        cp      #PART_FM3EXT_X
        jr      nc, pmdneo5_init_part_chip_fm
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
        ;; ADR-0006 §H: X/Y/Z は driver 未実装、 hooks=noop で stream 読捨
        cp      #PART_FM3EXT_X
        jp      nc, pmdneo5_init_part_hooks_noop
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
        ld      hl, #adpcmb_volume_hook
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
        ld      hl, #adpcma_volume_hook
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
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      a, (hl)
        cp      #0xFB
        ret     z
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
        call    pmdneo_part_apply_shift
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
        ld      a, PART_OFF_MASK(ix)
        or      a
        ret     nz
        ld      a, PART_OFF_TIEFLAG(ix)
        or      a
        jr      z, pmdneo_part_main_note_keyon
        xor     a
        ld      PART_OFF_TIEFLAG(ix), a
        ret
pmdneo_part_main_note_keyon:
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
        ld      a, PART_OFF_LOOPSTART(ix)
        or      PART_OFF_LOOPSTART_HI(ix)
        jp      z, pmdneo_part_main_loop_legacy
        ld      a, PART_OFF_LOOPSTART(ix)
        ld      PART_OFF_ADDR(ix), a
        ld      a, PART_OFF_LOOPSTART_HI(ix)
        ld      PART_OFF_ADDR+1(ix), a
        jp      pmdneo_part_main_parse
pmdneo_part_main_loop_legacy:
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

pmdneo_part_apply_shift:
        ld      b, a
        ld      a, PART_OFF_SHIFT(ix)
        or      a
        jr      z, pmdneo_part_apply_shift_none
        jp      p, pmdneo_part_apply_shift_positive
        neg
        ld      c, a
        ld      a, b
pmdneo_part_apply_shift_negative_loop:
        cp      #0x40
        jr      z, pmdneo_part_apply_shift_min
        dec     a
        ld      b, a
        and     #0x0F
        cp      #0x0F
        ld      a, b
        jr      nz, pmdneo_part_apply_shift_negative_next
        sub     #4
pmdneo_part_apply_shift_negative_next:
        dec     c
        jr      nz, pmdneo_part_apply_shift_negative_loop
        ret
pmdneo_part_apply_shift_min:
        ld      a, #0x40
        ret
pmdneo_part_apply_shift_positive:
        ld      c, a
        ld      a, b
pmdneo_part_apply_shift_positive_loop:
        cp      #0x7B
        jr      nc, pmdneo_part_apply_shift_max
        inc     a
        ld      b, a
        and     #0x0F
        cp      #0x0C
        ld      a, b
        jr      nz, pmdneo_part_apply_shift_positive_next
        add     a, #4
pmdneo_part_apply_shift_positive_next:
        dec     c
        jr      nz, pmdneo_part_apply_shift_positive_loop
        ret
pmdneo_part_apply_shift_max:
        ld      a, #0x7B
        ret
pmdneo_part_apply_shift_none:
        ld      a, b
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
        cp      #0xF7
        jp      z, commandsp_exloop
        cp      #0xFA
        jp      z, comd
        cp      #0xD5
        jp      z, comdd
        cp      #0xF6
        jp      z, comlopset
        cp      #0xFB
        jp      z, comtie
        cp      #0xFF
        jp      z, commandsp_at
        ;; ADR-0026 step 12 γ: melody part 内 0xEB rhykey (= R command = inline rhythm trigger)
        ;; PMDDotNET emit (= mc.cs L9748): \b → 0xEB 0x01 (= rhykey opcode + BD bitmap)
        ;; β で K part 経由 pmdneo_rhythm_event_trigger に dispatch、 γ で melody part 経由も同 hook へ統合
        ;; ADR-0026 §決定 6 (= K と R 共通 dispatch path)、 §決定 8 (= 同 routine addr PC marker)
        cp      #0xEB
        jp      z, commandsp_rhykey
        call    pmdneo_part_fetch_byte
        ret
commandsp_rhykey:
        ;; ADR-0026 step 12 γ: 0xEB rhykey bitmap fetch + 共通 hook tail call
        ;; bitmap byte は K part rhythm_main_rhykey と同 format (= bit 0 = BD、 bit 1-5 silent ignore)
        ;; tail call (= jp) で stack frame 不要、 ret は pmdneo_rhythm_event_trigger 経由で caller (= pmdneo_part_main_parse) に戻る
        call    pmdneo_part_fetch_byte           ; A = bitmap byte
        jp      pmdneo_rhythm_event_trigger
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
commandsp_exloop:
        jp      comexloop
commandsp_at:
        jp      comat

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

comd:
        ;; D <signed_byte> -- set PART_OFF_SHIFT = arg
        call    pmdneo_part_fetch_byte
        ld      PART_OFF_SHIFT(ix), a
        ret

comdd:
        ;; DD <signed_byte> -- add arg to PART_OFF_SHIFT
        call    pmdneo_part_fetch_byte
        ld      b, a
        ld      a, PART_OFF_SHIFT(ix)
        add     a, b
        ld      PART_OFF_SHIFT(ix), a
        ret

comlopset:
        ;; L -- store current fetch address into PART_OFF_LOOPSTART
        ld      a, PART_OFF_ADDR(ix)
        ld      PART_OFF_LOOPSTART(ix), a
        ld      a, PART_OFF_ADDR+1(ix)
        ld      PART_OFF_LOOPSTART_HI(ix), a
        ret

comtie:
        ;; & -- set PART_OFF_TIEFLAG = 1
        ld      a, #1
        ld      PART_OFF_TIEFLAG(ix), a
        ret

comexloop:
        ;; PMDMML ':' loop escape (opcode 0xF7, arg = expected cycle count N)
        call    pmdneo_part_fetch_byte    ; A = N (the loop count of matching ']N')
        ld      c, a                      ; C = N
        ld      a, PART_OFF_LOOPDEPTH(ix)
        or      a
        ret     z                         ; depth 0: unmatched ':', ignore
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
        inc     hl                        ; HL -> stack[depth-1].count field
        ld      a, (hl)
        inc     a                         ; A = current_count + 1 (next cycle number)
        cp      c
        ret     c                         ; current_count+1 < N: not last cycle, skip ':'
        jr      nz, comexloop_continue    ; > N: unexpected, ignore safely
        ;; current_count+1 == N: last cycle - scan forward to matching ']'
comexloop_skip_to_end:
        ld      l, PART_OFF_ADDR(ix)
        ld      h, PART_OFF_ADDR+1(ix)
        ld      b, #0                     ; B = nest level
comexloop_scan_loop:
        ld      a, (hl)
        inc     hl
        cp      #0xF9                     ; '[' opcode
        jr      z, comexloop_nest_inc
        cp      #0xF8                     ; ']' opcode
        jr      z, comexloop_check_end
        jp      comexloop_scan_loop
comexloop_nest_inc:
        inc     b
        jp      comexloop_scan_loop
comexloop_check_end:
        ld      a, b
        or      a
        jr      z, comexloop_found_end
        dec     b
        inc     hl                        ; skip ']' arg byte (count)
        jp      comexloop_scan_loop
comexloop_found_end:
        inc     hl                        ; skip ']' arg byte (count)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        ld      a, PART_OFF_LOOPDEPTH(ix)
        dec     a
        ld      PART_OFF_LOOPDEPTH(ix), a
        ret
comexloop_continue:
        ret

;; ADR-0016 step 5 β-2a: 0xFF (@<n>) cmd dispatch 拡張
;; 既存 comat は FM 限定 (= CHIP_TYPE=0 で voice_table 引き)、 PCM/SSG は破棄。
;; β-2a で CHIP_TYPE=2 (= PCM/ADPCM-A) path を追加、 voice index を
;; PART_OFF_INSTRUMENT(ix) に保存。 β-2b で adpcma_keyon_simple が
;; この field を読み、 voice index → sample table lookup を実装。
;; M-Q part は β scope-out (= γ で扱う)、 ただし comat 自体は L-Q 共通 path。
comat:
        call    pmdneo_part_fetch_byte    ; A = voice index (0-based)
        ld      c, a
        ld      a, PART_OFF_CHIP_TYPE(ix)
        cp      #2                        ; CHIP_TYPE 2 = PCM/ADPCM-A
        jp      z, comat_pcm
        or      a
        jp      nz, comat_done            ; SSG 等は何もしない (= 既存挙動維持)
        ld      l, c                      ; FM voice setup (= 既存 path、 CHIP_TYPE=0)
        ld      h, #0
        add     hl, hl                    ; HL = index * 2
        ld      de, #voice_table
        add     hl, de
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        ex      de, hl                    ; HL = voiceN_data address
        ld      b, PART_OFF_CH_IDX(ix)
        call    pmdneo_fm_voice_set
comat_done:
        ret

;; β-2a: L-Q part 用 voice index 保存 (= ADPCM-A sample table lookup 準備)
;; C = voice index (= pmdneo_part_fetch_byte で取得済)
;; PART_OFF_INSTRUMENT(ix) = C
comat_pcm:
        ld      PART_OFF_INSTRUMENT(ix), c
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

;; ADR-0016 step 4-3-β: J part body 由来 note 値を A レジスタで adpcmb_keyon に
;; 引渡す経路を確立 (= 旧 B=0 hardcoded を A=PART_OFF_NOTE に置換)。 adpcmb_keyon
;; 本体は 4-3-γ で A 値を delta-N 変換 + reg 0x19/0x1A 書込みに refactor 予定。
;; 4-3-β 単体では adpcmb_keyon は A 値 ignore のまま (= audio 不変期待、 wav
;; sha256 維持: ROM_A 3c1f776f... / ROM_B eabb80d4...)。
adpcmb_keyon_hook:
        ld      a, PART_OFF_NOTE(ix)
        call    adpcmb_keyon
        ret

adpcmb_keyoff_hook:
        call    adpcmb_keyoff
        ret

;; Phase 9c fix#3: adpcmb_volume_hook 実装
;; PART_OFF_VOLUME (= V cmd 0-255) → reg 0x1B (= ADPCM-B total level、 8 bit 直接)
adpcmb_volume_hook:
        ld      a, PART_OFF_VOLUME(ix)
        ld      c, a
        ld      b, #0x1B
        call    ym2610_write_port_a
        ret

;; ADR-0016 step 5 δ-a: adpcma_volume_hook bug fix
;; 旧 (= Phase 9c 期遺産 bug): reg 0x10 + ch (= ADPCM-A start LSB) に書込
;;   → V cmd dispatch で sample addr を破壊する仕様誤り
;; 新 (= δ-a fix): reg 0x08 + ch (= ADPCM-A per-ch vol + pan、 仕様正)
;;
;; vol mapping: PART_OFF_VOLUME (= v cmd 0-255) → /8 で 0-31 (= 5 bit、 ADPCM-A
;; chip reg は 6 bit 0-63 だが、 PMD V4.8s 規約 V/8 で 5 bit 化、 max 0x1F)
;;
;; pan mapping: adpcma_pan_bits[ch] (= K/R rhythm 用 fixed pan) を流用、
;; 議題 1 retain + refactor 遵守 (= 既存 table 再利用、 新規 table 追加なし)
;;
;; α/β/γ で sample lookup chain が成立済、 δ-a で V cmd 経由 vol/pan も
;; chip reg level で audible 化可能になる。
adpcma_volume_hook:
        ld      a, PART_OFF_VOLUME(ix)
        srl     a
        srl     a
        srl     a                       ; A = V/8 (= 0-31 範囲 5 bit vol)
        ld      hl, #adpcma_pan_bits
        ld      e, PART_OFF_CH_IDX(ix)
        ld      d, #0
        add     hl, de                  ; HL = adpcma_pan_bits[ch] addr
        or      (hl)                    ; A = vol | pan_bits[ch]
        ld      c, a
        ld      a, PART_OFF_CH_IDX(ix)
        add     a, #0x08                ; ★ reg 0x08 + ch (= per-ch vol + pan、 fix)
        ld      b, a
        call    ym2610_write_port_b
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

;; ADR-0016 step 4-3-γ: J part body 由来 A レジスタ note 値を delta-N に変換し
;; reg 0x19 (LSB) + reg 0x1A (MSB) を MML 由来値で書込。 sample addr (= reg
;; 0x12-0x15) / vol (= reg 0x1B) / pan (= reg 0x11) は beat.wav 固定値を維持。
;; 4-3-β baseline (= o4 c → 0x6E96) 互換: high nibble 4 + low nibble 0 で
;; chromatic table[0] = 0x6E96 を維持、 ymfm-trace byte-identical 期待。
;; differentiation は 4-3-δ で 2nd fixture (= e.g. o4 g) 経由で実証。
;; 旧 init_adpcmb_beat 呼出は撤去、 同 routine は cmd 0x05 非 MML mode 経路
;; (= L327 / TEST_MODE_CHORD != 5) で legacy 利用、 当面残置。
adpcmb_keyon:
        push    af                      ; save note byte (= A reg)
        ;; reg 0x10 = 0x00 (= clear keyon、 init_adpcmb_beat 旧経路と同順)
        ld      b, #0x10
        ld      c, #0x00
        call    ym2610_write_port_a
        ;; reg 0x12-0x15 = beat.wav sample addr (= fixed、 samples.inc 由来)
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
        ;; reg 0x19/0x1A = MML 由来 delta-N (= 4-3-γ の本旨)
        pop     af                      ; restore note byte
        call    adpcmb_note_to_deltan   ; A=note → DE=delta-N (clobbers A,DE)
        ld      b, #0x19
        ld      c, e
        call    ym2610_write_port_a
        ld      b, #0x1A
        ld      c, d
        call    ym2610_write_port_a
        ;; reg 0x1B = 0xFF (= vol max、 fixed)
        ld      b, #0x1B
        ld      c, #0xFF
        call    ym2610_write_port_a
        ;; reg 0x11 = 0xC0 (= pan both、 fixed)
        ld      b, #0x11
        ld      c, #0xC0
        call    ym2610_write_port_a
        ;; reg 0x10 = 0x80 (= keyon trigger)
        ld      b, #0x10
        ld      c, #0x80
        call    ym2610_write_port_a
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
;;;
;;; ADR-0016 step 5 β-2b refactor:
;;;   ch index (= A) は reg base 計算用 (0x10+ch / 0x18+ch / 0x20+ch / 0x28+ch /
;;;   0x08+ch / (1<<ch)) として preserve、 sample addr 引きは voice index
;;;   (= PART_OFF_INSTRUMENT(ix)) で行う。
;;;
;;; voice index → sample mapping (= 既存 adpcma_ch_sample_ptr_table を再解釈):
;;;   @0 → bd / @1 → sd / @2 → hh / @3 → tom / @4 → rim / @5 → top
;;;
;;; 範囲外 voice (= >= 6): keyon skip (= ret) で誤 sample 鳴動防止。
;;;
;;; K/R compat (= 議題 2 scope-out): K part = PART_RHYTHM (= part 10) は
;;; pmdneo_song_main の L1654 分岐で rhythm_main (= 空 stub) に流れ、
;;; adpcma_keyon_simple には到達しない。 voice index 引きへの refactor で
;;; K/R 経路への副作用なし (= 元々非アクティブ、 議題 2 retained but inactive)。
adpcma_keyon_simple:
        and     #0x07                   ; A = ch index (0-7 mask)
        ld      b, a                    ; B = ch index (= reg base 計算用、 preserve)
        ;; ADR-0016 step 5 β-2b 由来 + ADR-0024 step 10 β refactor:
        ;; voice index range check (= 4-A 採用、 routine 内では二重 check しない)
        ld      a, PART_OFF_INSTRUMENT(ix)
        cp      #6                      ; voice >= 6 は範囲外
        ret     nc                      ; → keyon skip (= 誤 sample 鳴動より安全)
        ;; --- ADR-0024 step 10 β: 中間 routine 経由で sample header pointer 取得 ---
        ;; A = voice index (= L2745-2747 で setup + range check 済)
        ;; B = ch index (= preserve、 pmdneo_select_sample_pointer は BC preserve)
        ;; 出力 DE = sample header pointer (= id == 0x00 + voice valid) or 0x0000 sentinel
        ;;        既存 inc de path (= L2757 以降) はそのまま接続可 (= 3-B DE 返却整合)
        ;; ADR-0024 §決定 3 (= 2-C): id != 0x00 → DE = 0x0000 → keyon skip (= mismatch silent)
        ;; ADR-0024 §決定 7: ADR-0023 §決定 11 contract 解除、 本 call で initial effective
        ;;        (= step 10 で sample_table_id が initial に playback selection に効く)
        call    pmdneo_select_sample_pointer
        ld      a, d
        or      e
        ret     z                       ; DE == 0x0000 → mismatch / unknown id keyon skip

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

;;; ----------------------------------------------------------------
;;; ADR-0025 step 11 α: adpcma_ch_sample_ptr_table_b (= table B、 multi-table id=0x01 proof)
;;;
;;; ADR-0025 §決定 2 整合 (= axis 1 / i 採用): L ch のみ別 sample 差替 + M-Q = table A と同 symbol
;;;   L = adpcma_sample_sd (= SD 相当、 sample swap 対象、 既存 VROM 内 sample 再利用 = axis 1-b / α)
;;;   M-Q = table A と完全同 symbol (= 物理 pointer 一致、 register trace で identical 期待値)
;;;
;;; α scope: dead code 状態 (= selector 未拡張、 keyon path 未影響)
;;;          step5b.PNE run で resolver は entry 1 match → 0xFD32 = 0x01 立つが、 selector は id=0x00 only-accept のため
;;;          本 table は参照されず sentinel silent (= playback 不影響、 ADR-0025 §決定 8 α gate 整合)
;;; β scope: selector が id=0x01 で本 table を引く explicit if/jr 拡張を入れる (= ADR-0025 §決定 5)
;;;
;;; trivial verify 防止: M-Q を同 symbol で書くことで、 β 完了後 step5.PNE vs step5b.PNE の
;;;                       register trace 比較で「L 違う / M-Q identical」 を literal 観測可能 (= 副作用なし証明)
adpcma_ch_sample_ptr_table_b:
        .dw     adpcma_sample_sd, adpcma_sample_sd, adpcma_sample_hh
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

;;; ----------------------------------------------------------------
;;; ADR-0023 step 9 α: PNE filename directory (= hand-written D1 placeholder)
;;;
;;; ADR-0023 §決定 3 / §決定 5 整合: 17 byte/entry, fixed length
;;;   filename:         16 byte, fixed length, NUL-padded ASCII
;;;   sample_table_id:   1 byte (= 0x00-0xFE valid id、 0xFF terminator marker)
;;;
;;; α scope: data placement only. resolver routine は β、 call insertion は γ。
;;; ADR-0023 §決定 11: driver_pne_sample_table_id は Step 9 内で playback decision に使用しない。
;;; ADR-0023 §決定 3: D1 = proof 用 placeholder、 最終 directory ownership ではない (= future D3 generated)
pne_sample_directory:
        ;; entry 0: filename = "step5.PNE" (= 9 char + 7 NUL pad = 16 byte)
        ;;          sample_table_id = 0x00
        ;;
        ;; γ 改訂 (= ADR-0023 §決定 5): α 時点では "PMDNEO01.PNE" としたが、 これは
        ;; asset pipeline canonical asset 名で、 driver runtime filename buffer
        ;; (= 0xFD20-0xFD2F) に実 copy される文字列ではない。 step 8 で確立した
        ;; runtime fixture (= l-q-rhythm-song.mml + PMDDOTNET_MODE=B) では
        ;; "step5.PNE" が流れるため、 runtime resolver の match fixture もそれに合わせる。
        .db     0x73, 0x74, 0x65, 0x70, 0x35, 0x2E, 0x50, 0x4E   ; "step5.PN"
        .db     0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; "E\0\0\0\0\0\0\0"
        .db     0x00                                              ; sample_table_id = 0x00

        ;; ADR-0025 step 11 α: entry 1 (= multi-table id=0x01 proof 用 fixture)
        ;;   filename = "step5b.PNE" (= 10 char + 6 NUL pad = 16 byte)
        ;;   sample_table_id = 0x01
        ;;
        ;; ADR-0025 §決定 3 / axis 2 整合: step5b.PNE = table B selection fixture
        ;;   (= runtime proof 用 命名、 asset canonical name ではない、 PMDNEO01.PNE とは役割が異なる)
        ;;
        ;; α scope: directory placement のみ。 resolver は terminator driven のため自然に entry 1 を見るようになる。
        ;;          selector は id=0x00 only-accept のため、 step5b.PNE run でも sentinel silent (= playback 不影響)。
        ;;          memory inspection で 0xFD32 = 0x01 は observable (= 「resolver は entry 1 を正しく見ている」 literal 証跡)。
        ;; β scope: selector 拡張で id=0x01 → table B 引き → L ch addr regs differ で audible 差分が出る。
        .db     0x73, 0x74, 0x65, 0x70, 0x35, 0x62, 0x2E, 0x50   ; "step5b.P"
        .db     0x4E, 0x45, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00   ; "NE\0\0\0\0\0\0"
        .db     0x01                                              ; sample_table_id = 0x01

        ;; terminator entry (= sample_table_id == 0xFF、 filename don't care = NUL)
        .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        .db     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        .db     0xFF                                              ; sample_table_id = 0xFF (terminator)

;;; ----------------------------------------------------------------
;;; ADR-0023 step 9 β: pmdneo_resolve_sample_table_id
;;;
;;; ADR-0023 §決定 6 整合: 独立 init routine、 .MN load chain 末尾 call (= γ scope)
;;; β scope: routine 単体実装、 call insertion は γ scope (= まだ呼ばれない)
;;; ADR-0023 §決定 11: 出力 (= 0xFD32) は Step 9 内で playback decision に使用しない
;;;
;;; 入力:
;;;   driver_pne_filename_buf (= 0xFD20-0xFD2F): NUL-padded ASCII filename (= Step 8 で書込済)
;;;   pne_sample_directory: hand-written directory (= 17 byte/entry, 0xFF terminator)
;;;
;;; 出力:
;;;   driver_pne_sample_table_id (= 0xFD32): 0x00-0xFE = valid id、 0xFF = mismatch sentinel
;;;
;;; 動作:
;;;   1. HL = pne_sample_directory (= entry head)
;;;   2. loop:
;;;        terminator check (= entry+16 が 0xFF か peek) → 0xFF なら mismatch branch
;;;        16 byte memcmp (entry filename vs driver_pne_filename_buf)
;;;        match → A = entry+16 (= sample_table_id) を 0xFD32 に store + ret
;;;        mismatch → HL += 17 (= next entry) + loop
;;;
;;; clobber: A, B, DE, HL (= caller 保存規約は既存 driver routine 群と同じ無し)
pmdneo_resolve_sample_table_id:
        ld      hl, #pne_sample_directory
resolve_loop:
        ;; HL = current entry head
        ;; --- terminator check (= entry+16 が 0xFF か peek) ---
        push    hl                              ; save entry head
        ld      de, #16
        add     hl, de
        ld      a, (hl)                         ; A = entry の sample_table_id byte
        pop     hl                              ; restore entry head
        cp      #0xFF
        jr      z, resolve_mismatch             ; terminator hit → mismatch

        ;; --- 16 byte memcmp (entry filename vs driver_pne_filename_buf) ---
        push    hl                              ; save entry head (for resolve_next)
        ld      de, #driver_pne_filename_buf
        ld      b, #16
resolve_cmp_loop:
        ld      a, (de)
        cp      (hl)
        jr      nz, resolve_next                ; byte mismatch → next entry
        inc     hl
        inc     de
        djnz    resolve_cmp_loop

        ;; match: HL = entry head + 16 = sample_table_id field
        ld      a, (hl)                         ; A = sample_table_id
        ld      (driver_pne_sample_table_id), a
        pop     hl                              ; discard saved entry head
        ret

resolve_next:
        pop     hl                              ; restore entry head
        ld      de, #17
        add     hl, de                          ; HL = next entry head
        jr      resolve_loop

resolve_mismatch:
        ld      a, #0xFF
        ld      (driver_pne_sample_table_id), a
        ret

;;; ----------------------------------------------------------------
;;; ADR-0024 step 10 α: pmdneo_select_sample_pointer (= 中間 routine 経由 pointer 返却)
;;; ADR-0025 step 11 β: id=0x01 branch 追加 + EQU 上限判定追加 (= multi-table id=0x01 proof、 explicit if/jr dispatch)
;;;
;;; ADR-0024 §決定 1/4 整合: 中間 routine 経由 pointer 返却 (= A2 採用)
;;; α scope (= Step 10): routine 単体実装 + adpcma_keyon_simple から call insertion。
;;;
;;; ADR-0024 §決定 2 (= 1-A 採用): id=0x00 canonical table は既存
;;;          adpcma_ch_sample_ptr_table を再利用。
;;; ADR-0024 §決定 3 (= 2-C 採用): id=0x00 only-accept、 それ以外 (= 0xFF
;;;          + 全 unknown) は 0x0000 sentinel で silent。
;;;
;;; ADR-0025 step 11 β 拡張:
;;;   ADR-0025 §決定 5 (= axis 4 採用): explicit if/jr で id=0x00/0x01 dispatch、
;;;          id 上限判定は cp PNE_SAMPLE_DIRECTORY_ENTRY_COUNT で実施、 範囲外は既存
;;;          sentinel path 流用 (= Step 10 silent 挙動完全保存)。
;;;   ADR-0024 §決定 3 (= id=0x00 only-accept) は本 β で {id=0x00, id=0x01} accept に拡張。
;;;          0xFF (= mismatch) と id >= PNE_SAMPLE_DIRECTORY_ENTRY_COUNT は依然 sentinel。
;;;   ADR-0025 §決定 2 (= axis 1 / i 採用): id=0x01 で adpcma_ch_sample_ptr_table_b 引き、
;;;          L ch のみ別 sample (= adpcma_sample_sd) / M-Q = table A 同 symbol。
;;;
;;; ADR-0024 §決定 4 整合: ABI = 入力 A + 0xFD32 read、 出力 DE = pointer
;;;          or 0x0000、 clobber A/HL、 preserve BC/IX/IY。 β でも ABI 完全不変。
;;; ADR-0024 §決定 5 整合: voice >= 6 range check は呼出側責務、 routine
;;;          内で実施しない (= 二重 check を持たせない)。
;;; ADR-0024 §決定 7: ADR-0023 §決定 11「playback decision に使用しない」
;;;          contract は step 10 β commit (= 9f454f5) で解除済。 本 routine の β 拡張で
;;;          複数 table から選ぶ selection key として initial に effective になる。
;;;
;;; 入力:
;;;   A: voice index (= 0..5、 6 以上の range check は呼出側で実施済前提)
;;;   driver_pne_sample_table_id (= 0xFD32): 0x00-0xFE valid id、 0xFF mismatch
;;;
;;; 出力:
;;;   DE: id=0x00 + voice valid 時 → adpcma_ch_sample_ptr_table[voice]
;;;       id=0x01 + voice valid 時 → adpcma_ch_sample_ptr_table_b[voice] (= β 新規)
;;;       それ以外 (= id >= EQU 含む) → 0x0000 sentinel (= caller で keyon skip)
;;;
;;; clobber:
;;;   A, HL (= 必要最小限、 β でも不変)
;;;
;;; preserve:
;;;   BC, IX, IY (= caller adpcma_keyon_simple の ch index B 等を温存)
;;;
;;; 動作:
;;;   1. L = voice index (= 入力 A を退避、 後段の HL = voice*2 計算用)
;;;   2. A = driver_pne_sample_table_id (= 0xFD32 read)
;;;   3. A >= PNE_SAMPLE_DIRECTORY_ENTRY_COUNT → select_unknown_id (= 上限超え silent、 β 新規)
;;;   4. id 値 dispatch (= explicit if/jr、 β 新規):
;;;        A == 0x00 → select_table_a (= adpcma_ch_sample_ptr_table 引き)
;;;        A == 0x01 → select_table_b (= adpcma_ch_sample_ptr_table_b 引き、 β 新規)
;;;        その他 (= 通常 unreachable with EQU=2) → select_unknown_id
;;;   5. select_table_a / select_table_b: H = 0、 HL = voice*2、 table base + HL = entry addr、 DE = (HL,HL+1)
pmdneo_select_sample_pointer:
        ld      l, a                            ; L = voice index (= 後段 HL=voice*2 用に退避)
        ld      a, (driver_pne_sample_table_id) ; A = 0xFD32 (= sample_table_id)
        ;; β: id 範囲 check (= axis 4-e EQU 上限判定、 範囲外は sentinel silent)
        cp      #PNE_SAMPLE_DIRECTORY_ENTRY_COUNT
        jr      nc, select_unknown_id           ; id >= EQU → silent (= 上限超え)
        ;; β: id 値 dispatch (= axis 4-a explicit if/jr、 EQU=2 では A は 0 or 1)
        or      a
        jr      z, select_table_a               ; id == 0x00 → table A
        cp      #1
        jr      z, select_table_b               ; id == 0x01 → table B
        ;; future: cp #2 / jr z, select_table_c ... の形で N table 拡張可能
        ;; ここに来るのは EQU >= 3 + 中間 id 未実装の不整合時のみ (= 通常 unreachable)
        jr      select_unknown_id

select_table_a:
        ;; id == 0x00 path: voice index で adpcma_ch_sample_ptr_table 引き (= 既存 Step 10 path)
        ld      h, #0
        add     hl, hl                          ; HL = voice * 2
        ld      de, #adpcma_ch_sample_ptr_table
        add     hl, de                          ; HL = sample ptr table entry addr
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                         ; DE = sample header pointer (= table A)
        ret

select_table_b:
        ;; ADR-0025 step 11 β: id == 0x01 path (= multi-table proof)
        ;; voice index で adpcma_ch_sample_ptr_table_b 引き
        ld      h, #0
        add     hl, hl                          ; HL = voice * 2
        ld      de, #adpcma_ch_sample_ptr_table_b
        add     hl, de                          ; HL = sample ptr table_b entry addr
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                         ; DE = sample header pointer (= table B、 L ch SD)
        ret

select_unknown_id:
        ;; id != accepted (= mismatch 0xFF + id >= EQU + 未実装 id): 0x0000 sentinel 返却
        ;; caller (= adpcma_keyon_simple) は DE == 0x0000 で keyon skip (= silent)
        ld      de, #0x0000
        ret

;;; ----------------------------------------------------------------
;;; ADR-0026 step 12 β: rhythm_main K part body parser + pmdneo_rhythm_event_trigger 共通 hook
;;;
;;; ADR-0026 §決定 1 整合: 「K part 0xEB path から hook に接続」
;;; ADR-0026 §決定 5 (= drum 種 b only proof、 BD bit 0 のみ accept、 bit 1-5 silent ignore)
;;; ADR-0026 §決定 6 (= K と R の dispatch = 共通 rhythm event hook、 R command は γ scope)
;;; ADR-0026 §決定 7 (= normalize 担当 layer = driver `.MN` direct parser)
;;; ADR-0026 §決定 8 (= rhythm event observability marker = 独立 routine label PC hit)
;;;
;;; PC trace marker: `pmdneo_rhythm_event_trigger` の entry addr が PC trace で literal observable
;;;
;;; β scope (= 本 commit):
;;;   - rhythm_main を empty stub から K part body parser に拡張
;;;   - 0xEB rhykey 検出 → bitmap fetch → pmdneo_rhythm_event_trigger 呼出
;;;   - 0x00-0x7F note byte = silent fallback (= K part body 内 R# 番号、 Step 12 では未対応)
;;;   - 0x80 / 0x81-0xB0 = part end (= PART_OFF_ADDR clear)
;;;   - 他 0xB1-0xFF command = silent fallback (= 1 byte 消費して継続)
;;;   - pmdneo_rhythm_event_trigger: A = bitmap、 bit 0 立 → ADPCM-A L ch BD trigger (= adpcma_sample_bd)
;;;   - 既存 adpcma_keyon_simple 経路 (= pmdneo_select_sample_pointer 経由 multi-table) は使わない
;;;     (= rhythm trigger は sample_table_id 状態と独立、 ADR-0026 §決定 3 driver-embedded fixture proof 整合)
;;;
;;; γ scope (= 次 commit):
;;;   - commandsp に 0xEB 分岐追加 (= melody part 内 \b inline → 同 hook 呼出)
;;;
;;; future drum 種拡張 scope (= 残り 5 drum sub-sprint):
;;;   - bit 1 (= SD), bit 2 (= CYM), bit 3 (= HH), bit 4 (= TOM), bit 5 (= RIM)
;;;   - dispatch path は不変、 drum 種 → sample pointer mapping を 1 軸拡張

rhythm_main:
        ;; tick wait check (= PART_OFF_LEN > 0 ならば decrement して終了)
        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, rhythm_main_parse
        dec     a
        ld      PART_OFF_LEN(ix), a
        ret

rhythm_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, rhythm_main_part_end          ; 0x80 = part end / loop マーカー
        jr      c, rhythm_main_note              ; 0x00-0x7F = note byte (= R# index、 silent fallback)
        cp      #0xB1
        jr      c, rhythm_main_part_end          ; 0x81-0xB0 = out_of_commands

        ;; 0xB1-0xFF = control command
        cp      #0xEB
        jr      z, rhythm_main_rhykey

        ;; 他 control command = silent fallback (= 1 byte 消費して継続、 driver 「未対応 cmd スルー」 思想)
        ;; ADR-0026 Annex A-6 整合: 6 個の他 K/R handler (= rhyvs / rmsvs 等) は no-op stub 思想を継続
        call    pmdneo_part_fetch_byte
        jr      rhythm_main_parse

rhythm_main_rhykey:
        ;; 0xEB rhykey: bitmap byte fetch + 共通 hook 呼出
        call    pmdneo_part_fetch_byte           ; A = bitmap byte
        call    pmdneo_rhythm_event_trigger
        jr      rhythm_main_parse

rhythm_main_note:
        ;; K part body 内 note byte (= PMD V4.8s 仕様 = R# index referencing radtbl)
        ;; Step 12 b-only proof scope-out: R# pattern body 2 段構造は未対応
        ;; silent fallback: length byte 消費 + PART_OFF_LEN 設定 (= 次 tick 待ち)
        call    pmdneo_part_fetch_byte           ; length byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ret

rhythm_main_part_end:
        ;; 0x80 / 0x81-0xB0 hit = part end、 PART_OFF_ADDR clear で次 tick skip
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a
        ret

;;; pmdneo_rhythm_event_trigger:
;;;   input: A = rhythm bitmap byte
;;;          bit 0 = BD trigger (= Step 12 b-only proof、 ADR-0026 §決定 5)
;;;          bit 1 = SD trigger (= Step 13 b+s proof、 ADR-0027 §決定 2、 14th session β)
;;;          bit 2-5 = future drum (= CYM \c / HH \h / TOM \t / RIM \i、 silent ignore)
;;;          bit 6-7 = scope-out (= PMDDotNET note byte 識別 flag 等、 silent ignore)
;;;   output: なし (= side effect = ADPCM-A L ch BD/SD trigger if bit 0/1 set)
;;;   clobber: A, B, C, HL (= conservative、 caller 側で必要なら push/pop)
;;;
;;; ADR-0026 §決定 8 / ADR-0027 §決定 9 整合: 本 routine の entry addr が PC trace で literal observable な marker、 drum 種拡張 (= Step 13 bit 1 SD 追加) でも entry addr 不変保持
;;; ADR-0026 §決定 3 / ADR-0027 §決定 3 整合: 既存 adpcma_sample_bd + adpcma_sample_sd (= driver-embedded fixture) を直接 trigger、 multi-table selector (= pmdneo_select_sample_pointer) は経由しない
;;; ADR-0026 §決定 4 整合: L ch (= ch 0) 暫定占有 scaffold
;;; ADR-0026 §決定 6 / ADR-0027 §決定 8 整合: K / R 共通 dispatch + drum 種拡張で dispatch path を増やさない
;;; ADR-0027 §決定 7 整合: BD fixture 完全不変保証 (= bit 0 only fixture では既存 register write sequence と byte-identical)
;;; ADR-0027 §決定 11 整合: BD+SD 同時打ち (= bitmap = 0x03) は Step 13 fixture では生成しない、 driver 側は arrive 時に BD trigger + SD trigger 連続 register write で対応 (= harmful なし、 Step 14 候補 scope-in 時の二次改修不要)
;;;
;;; register sequence (= L ch ch 0 固定、 BD / SD で sample addr のみ違う):
;;;   reg 0x10 = adpcma_sample_<bd|sd>[0] (= START_LSB)
;;;   reg 0x18 = adpcma_sample_<bd|sd>[1] (= START_MSB)
;;;   reg 0x20 = adpcma_sample_<bd|sd>[2] (= STOP_LSB)
;;;   reg 0x28 = adpcma_sample_<bd|sd>[3] (= STOP_MSB)
;;;   reg 0x08 = vol/pan (= 0xC0 pan L|R | 0x1F vol = 0xDF、 固定値 proof 用)
;;;   reg 0x00 = keyon mask 0x01 (= L ch bit 0)
;;;
;;; route table (= bit pattern → 動作):
;;;   bitmap = 0x00          → silent (= chip touch なし)
;;;   bitmap = 0x01 (BD)     → _rhythm_event_bd_trigger 6 件 reg write (= L ch BD)
;;;   bitmap = 0x02 (SD)     → _rhythm_event_sd_trigger 6 件 reg write (= L ch SD)
;;;   bitmap = 0x03 (BD+SD)  → BD 6 件 + SD 6 件 連続 reg write (= ADR-0027 §決定 11 scope-out 動作、 fixture では emit せず)
;;;   bitmap & 0x3C (CYM/HH/TOM/RIM) → silent ignore (= future drum 種拡張で _rhythm_event_{cym|hh|tom|rim}_trigger 追加)
pmdneo_rhythm_event_trigger::
        push    af                               ; A 保持 (= bit 0/1 両方 check 用)
        bit     0, a
        call    nz, _rhythm_event_bd_trigger     ; bit 0 立 → BD trigger
        pop     af
        bit     1, a
        ret     z                                ; bit 1 不立 → ret (= silent ignore for bit 2-5)
        ;; --- bit 1 立 = SD trigger (= Step 13 新規) ---
        jr      _rhythm_event_sd_trigger

_rhythm_event_bd_trigger:
        ;; ADR-0026 §決定 5 Step 12 既存 BD path (= 6 件 reg write 完全不変、 sample addr = adpcma_sample_bd)
        ld      hl, #adpcma_sample_bd            ; HL = BD sample 4-byte struct

        ;; reg 0x10 = start LSB
        ld      b, #0x10
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x18 = start MSB
        ld      b, #0x18
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x20 = stop LSB
        ld      b, #0x20
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x28 = stop MSB
        ld      b, #0x28
        ld      c, (hl)
        call    ym2610_write_port_b

        ;; reg 0x08 = volume/pan (= L ch、 0xC0 pan + 0x1F max vol = 0xDF 固定値 proof 用)
        ld      b, #0x08
        ld      c, #0xDF
        call    ym2610_write_port_b

        ;; reg 0x00 = keyon (= L ch mask 0x01)
        ld      b, #0x00
        ld      c, #0x01
        call    ym2610_write_port_b
        ret

_rhythm_event_sd_trigger:
        ;; ADR-0027 §決定 2/3 Step 13 新規 SD path (= 6 件 reg write、 sample addr = adpcma_sample_sd)
        ld      hl, #adpcma_sample_sd            ; HL = SD sample 4-byte struct

        ;; reg 0x10 = start LSB
        ld      b, #0x10
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x18 = start MSB
        ld      b, #0x18
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x20 = stop LSB
        ld      b, #0x20
        ld      c, (hl)
        call    ym2610_write_port_b
        inc     hl

        ;; reg 0x28 = stop MSB
        ld      b, #0x28
        ld      c, (hl)
        call    ym2610_write_port_b

        ;; reg 0x08 = volume/pan (= L ch、 0xC0 pan + 0x1F max vol = 0xDF 固定値 proof 用)
        ld      b, #0x08
        ld      c, #0xDF
        call    ym2610_write_port_b

        ;; reg 0x00 = keyon (= L ch mask 0x01)
        ld      b, #0x00
        ld      c, #0x01
        call    ym2610_write_port_b
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

;; ADR-0016 step 4-3-γ: J part note byte → ADPCM-B delta-N 変換
;; A レジスタ入力 = PMD 形式 note byte (= 0x40-0x7B):
;;   high nibble (= bit 4-7) ... octave nibble (= MML octave、 4 が base = o4)
;;   low nibble (= bit 0-3) ... chromatic semitone idx (= 0-11、 12-15 は clamp)
;; DE レジスタ出力 = delta-N (= reg 0x19/0x1A の 16-bit 値)
;; clobbers: A, DE (= AF/BC/HL は preserve)
;;
;; 設計: base octave = high nibble 4 (= MML o4)、 chromatic table[0] = 0x6E96
;; (= beat.wav natural rate ≈ 24 kHz、 4-3-α/β baseline 互換)。 octave shift
;; = high nibble - 4 で左 (= positive、 ×2 per octave) または右 (= negative)。
;; 有効入力 range (= 0x40-0x7B) では shift は 0-3 (= 左のみ)、 右 shift 経路は
;; 不正入力の defensive 経路。
adpcmb_note_to_deltan:
        push    af
        push    bc
        push    hl
        ld      b, a                    ; B = full note byte (= preserve)
        and     #0x0F                   ; A = low nibble = chromatic idx
        cp      #12
        jr      c, adpcmb_n2d_low_ok
        ld      a, #11                  ; clamp 12-15 to 11
adpcmb_n2d_low_ok:
        add     a, a                    ; ×2 for 16-bit table index
        ld      l, a
        ld      h, #0
        ld      de, #adpcmb_deltan_chromatic
        add     hl, de
        ld      e, (hl)                 ; DE = chromatic[idx] = base delta-N
        inc     hl
        ld      d, (hl)
        ;; --- octave shift ---
        ld      a, b
        rrca
        rrca
        rrca
        rrca
        and     #0x07                   ; A = high nibble (= 0-7)
        sub     #4                      ; A = octave delta (= -4 ~ +3)
        jr      z, adpcmb_n2d_done      ; no shift needed
        jr      c, adpcmb_n2d_shift_right
adpcmb_n2d_shift_left_loop:
        sla     e
        rl      d                       ; DE <<= 1 (= ×2、 octave up)
        dec     a
        jr      nz, adpcmb_n2d_shift_left_loop
        jr      adpcmb_n2d_done
adpcmb_n2d_shift_right:
        neg                             ; A = abs(shift count)
adpcmb_n2d_shift_right_loop:
        srl     d
        rr      e                       ; DE >>= 1 (= ÷2、 octave down)
        dec     a
        jr      nz, adpcmb_n2d_shift_right_loop
adpcmb_n2d_done:
        pop     hl
        pop     bc
        pop     af
        ret

;; chromatic delta-N table (= 12 entries × 16-bit = 24 byte)
;; base C (= idx 0) = 0x6E96 (= beat.wav natural rate、 PMD MML o4 c 互換)
;; ratio per semitone = 2^(n/12)、 round half-to-even
adpcmb_deltan_chromatic:
        .dw     0x6E96                  ; C  (= idx 0、 ratio 1.000000)
        .dw     0x7529                  ; C# (= idx 1、 ratio 1.059463)
        .dw     0x7C21                  ; D  (= idx 2、 ratio 1.122462)
        .dw     0x8382                  ; D# (= idx 3、 ratio 1.189207)
        .dw     0x8B54                  ; E  (= idx 4、 ratio 1.259921)
        .dw     0x939D                  ; F  (= idx 5、 ratio 1.334840)
        .dw     0x9C64                  ; F# (= idx 6、 ratio 1.414214)
        .dw     0xA5B1                  ; G  (= idx 7、 ratio 1.498307)
        .dw     0xAF8B                  ; G# (= idx 8、 ratio 1.587401)
        .dw     0xB9FC                  ; A  (= idx 9、 ratio 1.681793)
        .dw     0xC50B                  ; A# (= idx 10、 ratio 1.781797)
        .dw     0xD0C2                  ; B  (= idx 11、 ratio 1.887749)

;;; ADR-0016 step 5 γ-a: .MN direct parser (= L-Q 汎用、 α-2 L 専用版を一般化)
;;;
;;; 入力: A = L-Q index (0=L, 1=M, 2=N, 3=O, 4=P, 5=Q)
;;; 出力: HL = part body file 内 addr (= pmddotnet_song + 1 + part_offset)
;;; 破壊: AF, BC, DE, HL
;;;
;;; .MN layout (= ground truth、 docs/design/handoff/adr-0016-step5-alpha-1-mn-layout.md):
;;;   pmddotnet_song[0]      = m_start (= bit 2 = 1 で PMDNEO .MN mode)
;;;   pmddotnet_song[1..28]  = header 28 byte (= m_buf[0..27])
;;;   pmddotnet_song[27..28] = m_buf[26..27] = extended_data_adr (LE 16-bit)
;;;   offset_table_base = pmddotnet_song + 1 + extended_data_adr
;;;   offset_table[lq_idx] = base + lq_idx * 2 (= LE 16-bit、 m_buf-relative)
;;;
;;; pointer 解決規則 (= Codex zero-trust verify 確定、 α-1):
;;;   全 pointer 値は m_buf-relative
;;;   file address = pmddotnet_song + 1 + pointer_value
;;;
;;; γ-a 一般化方針 (= α-2 L 専用 routine の自然な拡張):
;;;   - offset_table_base から lq_idx × 2 byte 進めて entry を引く
;;;   - 既存 L 専用 logic は A=0 で完全に同等動作 (= regression なし期待)
;;;   - K/R compat fallback は load_song_part_addr へ tail call (= 既存維持)
;;;   - lq_idx は A レジスタで preserve (= push af / pop af で再利用)
;;;
;;; γ scope (= 議題 6 sub-sprint γ):
;;;   - L-Q 全 6 part の .MN direct path dispatch を一般化
;;;   - β chain (= @<n> → sample lookup) は ch 軸でも継承される (= 議題 5 後段)
;;;   - sample lookup 自体は β-2b で完成済、 γ で touch しない
;;;   - vol/pan hook は δ で扱う
.if PMDNEO_USE_PMDDOTNET == 1
pmdneo_mn_direct_load_lq_part_addr::
        push    af                      ; A = lq idx preserve (0-5)
        ;; ★ trace gate 1: .MN header parse 到達
        ld      hl, #pmddotnet_song
        ld      a, (hl)                 ; A = m_start
        and     #0x04                   ; bit 2 = 1 で PMDNEO .MN mode
        jr      z, pmdneo_mn_direct_lq_not_mn  ; bit 2 = 0 なら legacy fallback

        ;; ★ trace gate 2: extended_data_adr read (= m_buf[26..27])
        ld      hl, #pmddotnet_song + 27
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = extended_data_adr (LE、 m_buf-relative)

        ;; offset_table_base = pmddotnet_song + 1 + extended_data_adr
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = offset_table file addr

        ;; ★ ADR-0022 step 8 α: pne_filename_adr observation
        ;; pne_filename_adr field file addr = offset_table_base + 12 (= m_buf 相対 +12..13)
        ;; α scope: word を 0xFD30-0xFD31 に保存するのみ (= string copy は β、 §決定 7)
        push    hl                      ; preserve offset_table base
        ld      bc, #12
        add     hl, bc                  ; HL = pne_filename_adr field file addr
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = pne_filename_adr (LE u16、 m_buf-relative)
        ld      (driver_pne_filename_adr_word), de  ; store to 0xFD30-0xFD31
        pop     hl                      ; restore offset_table base

        ;; ★ ADR-0022 step 8 β: filename string copy (= 0xFD20-0xFD2F buffer)
        ;; filename string file addr = pmddotnet_song + 1 + pne_filename_adr
        ;; β scope: NUL-terminated ASCII を最大 15 byte copy + byte15 強制 NUL (= §決定 5 overflow 規約)
        ;; β-A: 通常 contract (= DOS 8.3 / NUL-terminated) を通すのみ、 16+ byte fixture verify は γ / future
        push    hl                      ; preserve offset_table base
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = filename string file addr
        ld      de, #driver_pne_filename_buf  ; DE = 0xFD20 (buffer 先頭)
        ld      b, #15                  ; max non-NUL byte 数 (= byte15 は overflow 時 NUL 用に予約)
pmdneo_mn_pne_fn_copy_loop:
        ld      a, (hl)
        ld      (de), a                 ; copy 1 byte (= NUL も含めて write)
        or      a
        jr      z, pmdneo_mn_pne_fn_copy_done  ; A = NUL → 早期終了 (= 通常 path)
        inc     hl
        inc     de
        djnz    pmdneo_mn_pne_fn_copy_loop
        ;; overflow path: 15 byte 全 copy で NUL 未検出 (= source filename ≥ 16 byte)
        ;; byte15 (= 0xFD2F) を強制 NUL、 driver halt せず継続 (= §決定 5)
        xor     a
        ld      (de), a                 ; (DE) = 0xFD2F = 0x00 強制
pmdneo_mn_pne_fn_copy_done:
        ;; ★ ADR-0023 step 9 γ: filename copy 完了後 → sample_table_id resolve
        ;; resolver は driver_pne_filename_buf を読み、 0xFD32 に id を保存
        ;; HL/DE/BC は resolver 内で clobber されるが、 直後の pop hl で
        ;; offset_table base を復元するため caller への影響なし
        ;; ADR-0023 §決定 6 timing: filename copy 完了後の独立 routine call
        ;; ADR-0023 §決定 11: 0xFD32 は本 routine 完了後 playback decision に使用しない
        call    pmdneo_resolve_sample_table_id
        pop     hl                      ; restore offset_table base

        ;; offset_table[lq_idx] = base + lq_idx * 2 (= γ-a 一般化点)
        pop     af                      ; A = lq idx restore
        add     a, a                    ; A = lq_idx * 2
        ld      e, a
        ld      d, #0
        add     hl, de                  ; HL = offset_table[lq_idx] addr

        ;; ★ trace gate 3: part offset read (= offset_table entry)
        ld      e, (hl)
        inc     hl
        ld      d, (hl)                 ; DE = part body offset (m_buf-relative)

        ;; ★ trace gate 4: part_body_addr = pmddotnet_song + 1 + part_offset
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = part body file addr
        ret

pmdneo_mn_direct_lq_not_mn:
        ;; m_start bit 2 = 0 → legacy fallback (= compile.py 経路)
        ;; lq_idx 0=L → table idx 11 (= song_table A=0, ..., L=11, ..., Q=16)
        pop     af                      ; A = lq idx restore (0-5)
        add     a, #11                  ; A = song_table idx (11-16)
        jp      load_song_part_addr     ; tail call、 HL は load_song_part_addr 設定

;;; ADR-0026 step 12 β: K part body addr load (= PMDDOTNET_MML 経路)
;;;
;;; 入力: なし
;;; 出力: HL = K part body file 内 addr (= pmddotnet_song + 1 + K_offset)
;;; 破壊: AF, DE, HL
;;;
;;; .M / .MN file layout (= analysis_m_data_structure.md §2-3 整合):
;;;   pmddotnet_song[0]      = m_start
;;;   pmddotnet_song[1..2]   = m_buf[0..1]   = part A offset (LE 16-bit)
;;;   pmddotnet_song[3..4]   = m_buf[2..3]   = part B offset
;;;   ...
;;;   pmddotnet_song[21..22] = m_buf[20..21] = **part 10 (K = R body) offset** (LE 16-bit)
;;;   pmddotnet_song[23..24] = m_buf[22..23] = rhythm address table offset
;;;
;;; pointer 解決規則 (= L-Q routine と同じ規約):
;;;   K_offset 値は m_buf-relative
;;;   K body file addr = pmddotnet_song + 1 + K_offset
;;;
;;; bit 2 m_start check は不要 (= K offset は標準 m_buf header の固定位置、 .M / .MN 共通)
;;; L-Q routine は bit 2 check を持つが、 これは ADPCM-A 拡張領域 (= extended_data_adr) 経由
;;; K 用 sample table id resolver は呼ばない (= ADR-0026 §決定 3 driver-embedded fixture proof、
;;;                                            sample_table_id 状態と独立)
pmdneo_mn_direct_load_k_part_addr::
        ;; K part offset position: pmddotnet_song + 21 (= m_buf[20..21])
        ld      hl, #pmddotnet_song + 21
        ld      e, (hl)                 ; E = K offset LO
        inc     hl
        ld      d, (hl)                 ; D = K offset HI (LE)
        ld      hl, #pmddotnet_song + 1
        add     hl, de                  ; HL = K body file addr (= pmddotnet_song + 1 + K_offset)
        ret
.endif

;; Phase 12a-2: song data は compile.py 経由 song_data.inc で取込済 (= driver
;; の `.include "song_data.inc"` で一意 source)、 hardcoded song_part_? は廃止。
;; Codex Phase 12a-2 削除漏れ fix (= Phase 12a-3 audio gate で発覚、 line 2346-
;; 2394 残存していた hardcoded を本 fix で除去、 song_data.inc が単一 source)。

        .include "song_data.inc"

        ;; Dummy DATA area to satisfy linker (= -b DATA=0xf800)
        .area DATA
