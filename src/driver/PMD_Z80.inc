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

        .include "assets/samples.inc"


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
        ld      (mmlbuf), hl

        ;; SubB-4: scale state init
        xor     a
        ld      (scale_step), a

        ;; SubC-2: scale_mode = 0 (= SSG default)
        ld      (scale_mode), a

        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        ;; SubC-3: default FM voice for audible PMDNEO FM parts (B/C/E/F).
        ld      b, #1                   ; chip ch 2 = Part B
        call    pmdneo_fm_voice_set_default
        ld      b, #2                   ; chip ch 3 = Part C
        call    pmdneo_fm_voice_set_default
        ld      b, #4                   ; chip ch 5 = Part E
        call    pmdneo_fm_voice_set_default
        ld      b, #5                   ; chip ch 6 = Part F
        call    pmdneo_fm_voice_set_default

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

        ;; SubC-2: scale_mode で table 選択 (= note byte は OCT base が違う、
        ;; SSG OCT 1 ≈ C4 / FM OCT 4 = C4)
        push    af                      ; A = scale_step を保存
        ld      a, (scale_mode)
        or      a
        jr      nz, pmd_z80_main_scale_step_fm_table
        ld      hl, #scale_notes
        jr      pmd_z80_main_scale_step_table_done
pmd_z80_main_scale_step_fm_table:
        ld      hl, #scale_notes_fm
pmd_z80_main_scale_step_table_done:
        pop     af                      ; A = scale_step 復元
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      a, (hl)                 ; A = note byte

        ;; SubC-2: scale_mode で fnumset routine 切替
        push    af
        ld      a, (scale_mode)
        or      a
        jr      nz, pmd_z80_main_scale_step_fm
        pop     af
        call    fnumsetp
        jr      pmd_z80_main_scale_step_advance
pmd_z80_main_scale_step_fm:
        pop     af
        ld      b, #1                   ; chip ch 2 = ch index 1
        call    fnumset_fm

pmd_z80_main_scale_step_advance:
        ;; scale_step++
        ld      a, (scale_step)
        inc     a
        ld      (scale_step), a

        ;; scale_tick reset
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        ret

pmd_z80_main_scale_stop:
        ;; SubC-2: scale_mode で keyoff routine 切替
        ld      a, (scale_mode)
        or      a
        jr      nz, pmd_z80_main_scale_stop_fm

        ;; SSG keyoff (= 既存 SubB-4)
        ld      b, #0
        call    pmdneo_psg_keyoff
        ld      b, #1
        call    pmdneo_psg_keyoff
        ld      b, #2
        call    pmdneo_psg_keyoff
        jr      pmd_z80_main_scale_stop_done

pmd_z80_main_scale_stop_fm:
        ;; FM chip ch 2 keyoff
        ld      b, #1
        call    pmdneo_fm_keyoff

pmd_z80_main_scale_stop_done:
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


;;; ----- pmdneo_load_m: SubB-7 SAMPLE.M load -----
;;;
;;; sample_m_data に組み込んだ PMD V4.8s SAMPLE.M の header を読み、
;;; part 0-10 の body address を per-part workarea に設定する。
;;;
;;; .m part offset は mmlbuf (= sample_m_data + 1) からの相対 offset。
;;; pmdneo_psgmain は絶対 address を読むため、 load 時に絶対化する。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L、 IX

pmdneo_load_m::
        ;; m_start = 0x00 (OPNA mode flag) を想定
        ld      hl, #sample_m_data
        ld      a, (hl)
        or      a
        jr      nz, pmdneo_load_m_abort

        ;; mmlbuf = sample_m_data + 1 (= m_buf 先頭)
        inc     hl
        ld      (mmlbuf), hl

        ;; 念のため mixer を再設定
        ld      b, #REG_SSG_ENABLE
        ld      c, #0x38
        call    ym2610_write_port_a

        ;; m_buf の part offset table から part 0-10 を設定
        ld      de, (mmlbuf)            ; DE = 現在の offset table pointer
        ld      c, #0                   ; C = part number

pmdneo_load_m_loop:
        push    bc
        push    de

        ld      a, c
        call    pmdneo_part_ix_from_part

        ;; offset = *(DE) little endian、 table pointer を 2 byte 進める
        pop     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        push    hl                      ; next offset table pointer

        ;; PART_OFF_ADDR = mmlbuf + offset
        ld      hl, (mmlbuf)
        add     hl, de
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h

        ;; loop なし、 即 parse、 初期 volume max
        xor     a
        ld      PART_OFF_LOOP(ix), a
        ld      PART_OFF_LOOP+1(ix), a
        ld      PART_OFF_LEN(ix), a
        ld      a, #0x0F
        ld      PART_OFF_VOLUME(ix), a

        pop     de                      ; 次の offset table pointer
        pop     bc
        inc     c
        ld      a, c
        cp      #11
        jr      nz, pmdneo_load_m_loop

        ;; song mode に切替
        ld      a, #1
        ld      (driver_song_ready), a
        ret

pmdneo_load_m_abort:
        xor     a
        ld      (driver_song_ready), a
        ret


;;; ----- test_play_fm_song: SubC-3 4 ch FM MML song load -----
;;;
;;; test_fm_song_data の OPNA 互換 part offset table を読み、 part 0-10 の
;;; body address を per-part workarea に設定する。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L、 IX

test_play_fm_song::
        ld      hl, #test_fm_song_data
        ld      (mmlbuf), hl

        ld      de, (mmlbuf)            ; DE = offset table pointer
        ld      c, #0                   ; C = part number

test_play_fm_song_loop:
        push    bc
        push    de

        ld      a, c
        call    pmdneo_part_ix_from_part

        ;; offset = *(DE) little endian、 table pointer を 2 byte 進める
        pop     hl
        ld      e, (hl)
        inc     hl
        ld      d, (hl)
        inc     hl
        push    hl                      ; next offset table pointer

        ;; PART_OFF_ADDR = mmlbuf + offset
        ld      hl, (mmlbuf)
        add     hl, de
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h

        ;; loop なし、 即 parse、 初期 volume max
        xor     a
        ld      PART_OFF_LOOP(ix), a
        ld      PART_OFF_LOOP+1(ix), a
        ld      PART_OFF_LEN(ix), a
        ld      a, #0x0F
        ld      PART_OFF_VOLUME(ix), a

        pop     de                      ; 次の offset table pointer
        pop     bc
        inc     c
        ld      a, c
        cp      #11
        jr      nz, test_play_fm_song_loop

        ;; song mode に切替
        ld      a, #1
        ld      (driver_song_ready), a
        ret


;;; ----- test_play_fm_c4: SubC-1 FM chip ch 2 hardcoded C4 -----
;;;
;;; YM2610 無印 chip では chip ch 1/4 が internal に存在するが output 配線
;;; なし (= 既知仕様、 memory reference_opna_opnb_chip_comparison.md)。
;;; PMDNEO 楽曲は (C) 方針 (= Part A/D 不使用の自己規律) で chip ch 2/3/5/6
;;; のみ運用する。 SubC-1 では chip ch 2 (= ch index 1、 port A、 末尾 +1)
;;; に 25 byte 音色を設定し、 C4 (= OCT 4 + ONKAI 0) を keyon して保持する。
;;; nullsound 命名 FM1_YM2610 = 1 と一致 (= 末尾 +1)。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L、 IX

test_play_fm_c4::
        ;; ALG/FB = ALG 7, FB 0
        ld      hl, #fm_voice_data_default
        ld      de, #24
        add     hl, de
        ld      b, #0xB1
        ld      c, (hl)
        call    ym2610_write_port_a

        ld      hl, #fm_voice_data_default

        ;; DT/ML × 4 (OP1, OP3, OP2, OP4)
        ld      d, #0x31
        call    pmdneo_fm_write_voice_group

        ;; TL × 4 (ALG 7 なので全 op carrier)
        ld      d, #0x41
        call    pmdneo_fm_write_voice_group

        ;; KS/AR × 4
        ld      d, #0x51
        call    pmdneo_fm_write_voice_group

        ;; AM/DR × 4
        ld      d, #0x61
        call    pmdneo_fm_write_voice_group

        ;; SR × 4
        ld      d, #0x71
        call    pmdneo_fm_write_voice_group

        ;; RR/SL × 4
        ld      d, #0x81
        call    pmdneo_fm_write_voice_group

        ;; SSG-EG は未使用なので明示的に 0
        call    pmdneo_fm_clear_ssg_eg

        ;; C4: OCT 4 + ONKAI 0
        ld      a, #0x40
        ld      b, #1                   ; chip ch 2 = ch index 1
        call    fnumset_fm

        ;; L/R pan on, AMS/PMS off
        ld      b, #0xB5
        ld      c, #0xC0
        call    ym2610_write_port_a

        ;; chip ch 2 (= nullsound FM1, ch index 1) all operators keyon
        ld      b, #REG_FM_KEY_ON_OFF_OPS
        ld      c, #0xF1
        call    ym2610_write_port_a

        ret


;;; ----- test_play_fm_scale_b: SubC-2 chip ch 2 で FM スケール -----
;;;
;;; SubC-1 の test_play_fm_c4 と同じ音色 + PAN + ALG/FB 設定後、 scale_mode
;;; を 1 にして SubB-4 の scale 駆動経路 (= pmd_z80_main_scale_step) に乗せる。
;;; scale_notes_fm (= OCT 4 ベースの 8 note) を順に発音、 keyon は 1 回だけで
;;; envelope 維持のまま fnum 変更で legato。 終端で keyoff。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C、 D、 E、 H、 L、 IX

test_play_fm_scale_b::
        ;; ALG/FB
        ld      hl, #fm_voice_data_default
        ld      de, #24
        add     hl, de
        ld      b, #0xB1
        ld      c, (hl)
        call    ym2610_write_port_a

        ld      hl, #fm_voice_data_default

        ld      d, #0x31
        call    pmdneo_fm_write_voice_group

        ld      d, #0x41
        call    pmdneo_fm_write_voice_group

        ld      d, #0x51
        call    pmdneo_fm_write_voice_group

        ld      d, #0x61
        call    pmdneo_fm_write_voice_group

        ld      d, #0x71
        call    pmdneo_fm_write_voice_group

        ld      d, #0x81
        call    pmdneo_fm_write_voice_group

        call    pmdneo_fm_clear_ssg_eg

        ;; 最初の note (= scale_notes_fm[0] = C4) を fnumset
        ld      a, (#scale_notes_fm)
        ld      b, #1                   ; chip ch 2 = ch index 1
        call    fnumset_fm

        ;; PAN L/R on
        ld      b, #0xB5
        ld      c, #0xC0
        call    ym2610_write_port_a

        ;; keyon (= chip ch 2 全 op、 envelope 開始)
        ld      b, #REG_FM_KEY_ON_OFF_OPS
        ld      c, #0xF1
        call    ym2610_write_port_a

        ;; SubC-2 scale 駆動 state init: mode = 1 (FM)、 step = 1 (= 既に [0] 発音済)、
        ;; tick = SCALE_TICK_INITIAL
        ld      a, #1
        ld      (scale_mode), a
        ld      (scale_step), a
        ld      hl, #SCALE_TICK_INITIAL
        ld      (scale_tick_lo), hl

        ret


;;; pmdneo_fm_write_voice_group:
;;;   input : HL = voice data pointer, D = first register in group
;;;   output: HL += 4

pmdneo_fm_write_voice_group:
        ld      e, #4
pmdneo_fm_write_voice_group_loop:
        ld      b, d
        ld      c, (hl)
        push    de
        push    hl
        call    ym2610_write_port_a
        pop     hl
        pop     de
        inc     hl
        ld      a, d
        add     a, #4
        ld      d, a
        dec     e
        jr      nz, pmdneo_fm_write_voice_group_loop
        ret


pmdneo_fm_clear_ssg_eg:
        ld      d, #0x91
        ld      e, #4
pmdneo_fm_clear_ssg_eg_loop:
        ld      b, d
        ld      c, #0x00
        push    de
        call    ym2610_write_port_a
        pop     de
        ld      a, d
        add     a, #4
        ld      d, a
        dec     e
        jr      nz, pmdneo_fm_clear_ssg_eg_loop
        ret


;;; pmdneo_fm_write_reg_ch:
;;;   input : B = FM ch index (0..5), D = base register, C = data
;;;   output: write to port A for ch 0..2, port B for ch 3..5

pmdneo_fm_write_reg_ch:
        push    bc
        push    de

        ld      a, b
        cp      #3
        jr      c, pmdneo_fm_write_reg_ch_porta

        sub     #3                      ; port B register suffix 0..2
        ld      e, a
        ld      a, d
        add     a, e
        ld      b, a
        call    ym2610_write_port_b
        jr      pmdneo_fm_write_reg_ch_done

pmdneo_fm_write_reg_ch_porta:
        ld      e, a                    ; port A register suffix 0..2
        ld      a, d
        add     a, e
        ld      b, a
        call    ym2610_write_port_a

pmdneo_fm_write_reg_ch_done:
        pop     de
        pop     bc
        ret


;;; pmdneo_fm_write_voice_group_ch:
;;;   input : B = FM ch index, HL = voice data pointer, D = first base register
;;;   output: HL += 4

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


;;; pmdneo_fm_voice_set_default:
;;;   input : B = FM ch index (0..5)

pmdneo_fm_voice_set_default:
        ;; ALG/FB
        ld      hl, #fm_voice_data_default
        ld      de, #24
        add     hl, de
        ld      d, #0xB0
        ld      c, (hl)
        call    pmdneo_fm_write_reg_ch

        ld      hl, #fm_voice_data_default

        ;; DT/ML × 4 (OP1, OP3, OP2, OP4)
        ld      d, #0x30
        call    pmdneo_fm_write_voice_group_ch

        ;; TL × 4 (ALG 7 なので全 op carrier)
        ld      d, #0x40
        call    pmdneo_fm_write_voice_group_ch

        ;; KS/AR × 4
        ld      d, #0x50
        call    pmdneo_fm_write_voice_group_ch

        ;; AM/DR × 4
        ld      d, #0x60
        call    pmdneo_fm_write_voice_group_ch

        ;; SR × 4
        ld      d, #0x70
        call    pmdneo_fm_write_voice_group_ch

        ;; RR/SL × 4
        ld      d, #0x80
        call    pmdneo_fm_write_voice_group_ch

        ;; SSG-EG は未使用なので明示的に 0
        call    pmdneo_fm_clear_ssg_eg_ch

        ;; L/R pan on, AMS/PMS off
        ld      d, #0xB4
        ld      c, #0xC0
        call    pmdneo_fm_write_reg_ch

        ret


;;; ----- fnumset_fm: note byte → FM block/fnum per ch -----
;;;
;;; 入力: A = note byte (= OCT 4 bit 上位 + ONKAI 4 bit 下位)
;;;       B = FM ch index (0..5)
;;; 動作:
;;;   1. ONKAI で fnum_data[ONKAI × 2] (= OCT 0 base fnum) を取得
;;;   2. OCT を block として 0xA4+ch bit 5-3 へ設定
;;;   3. 0xA4+ch (= block + fnum upper) → 0xA0+ch (= fnum lower) の順で書込
;;;      ch 0..2 は port A、 ch 3..5 は port B
;;; 破壊: A、 B、 C、 D、 E、 H、 L

fnumset_fm::
        push    af                      ; note byte 保存
        push    bc                      ; ch index 保存

        ;; ONKAI を取り出して fnum_data の index に
        and     #0x0F
        ld      l, a
        ld      h, #0
        add     hl, hl                  ; HL = ONKAI × 2
        ld      bc, #fnum_data
        add     hl, bc

        ;; DE = fnum (little endian)
        ld      e, (hl)
        inc     hl
        ld      d, (hl)

        ;; OCT を block に変換
        pop     bc
        pop     af
        rrca
        rrca
        rrca
        rrca
        and     #0x07
        add     a, a
        add     a, a
        add     a, a                    ; A = block << 3
        ld      l, a

        ld      a, d
        and     #0x07                   ; fnum upper 3 bit
        or      l
        ld      h, a                    ; H = block + fnum upper

        ld      a, b
        cp      #3
        jr      c, fnumset_fm_porta

        sub     #3                      ; port B register suffix 0..2
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
        ld      l, a                    ; port A register suffix 0..2
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


;;; ----- fnum_data: FM 用 12 半音 × 2 byte (LE)、 OCT 0 base fnum -----

fnum_data::
        .dw     0x026A                  ; ONKAI 0  = C
        .dw     0x028F                  ; ONKAI 1  = C#
        .dw     0x02B6                  ; ONKAI 2  = D
        .dw     0x02DF                  ; ONKAI 3  = D#
        .dw     0x030B                  ; ONKAI 4  = E
        .dw     0x0339                  ; ONKAI 5  = F
        .dw     0x036A                  ; ONKAI 6  = F#
        .dw     0x039E                  ; ONKAI 7  = G
        .dw     0x03D5                  ; ONKAI 8  = G#
        .dw     0x0410                  ; ONKAI 9  = A
        .dw     0x044E                  ; ONKAI 10 = A#
        .dw     0x048F                  ; ONKAI 11 = B


;;; ----- fm_voice_data_default: PMD prgdat 25 byte voice -----
;;;
;;; byte order is register slot order: OP1, OP3, OP2, OP4.

fm_voice_data_default::
        ;; DT/ML × 4
        .db     0x01, 0x01, 0x01, 0x01
        ;; TL × 4
        .db     0x18, 0x18, 0x18, 0x18
        ;; KS/AR × 4
        .db     0x1F, 0x1F, 0x1F, 0x1F
        ;; AM/DR × 4
        .db     0x00, 0x00, 0x00, 0x00
        ;; SR × 4
        .db     0x00, 0x00, 0x00, 0x00
        ;; RR/SL × 4
        .db     0x0F, 0x0F, 0x0F, 0x0F
        ;; ALG/FB
        .db     0x07


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

;;; SubC-2: FM 用 scale_notes (= OCT 4 ベース、 C4 = 0x40)
;;; SSG OCT 1 (= 0x10) ≈ FM OCT 4 (= 0x40) ≒ 261 Hz
scale_notes_fm::
        .db     0x40, 0x42, 0x44, 0x45, 0x47, 0x49, 0x4B, 0x50


;;; ----- SCALE_TICK_INITIAL: 各 note の duration (= TIMER-B tick 数) -----
;;;
;;; 実機/エミュレータ実測で 0x0800 が約 38 sec だったため、
;;; SubB-4 では 0x0800 / 40 ≒ 0x0033 を 1 note の duration にする。

SCALE_TICK_INITIAL = 0x0033

;;; SubB-7 暫定: SAMPLE.M の raw length を 2^3 = 8 倍して鳴らす。
PMDNEO_MML_LEN_SHIFT = 3


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


;;; ----- test_fm_song_data: SubC-3 4 ch FM sample song -----
;;;
;;; OPNA m_buf 互換の 11 part offset table。 Part A/D は ADR-0001 (C)
;;; 方針に従い即 end、 B/C/E/F のみ note sequence を持つ。

test_fm_song_data::
        .dw     test_fm_song_part_a - test_fm_song_data
        .dw     test_fm_song_part_b - test_fm_song_data
        .dw     test_fm_song_part_c - test_fm_song_data
        .dw     test_fm_song_part_d - test_fm_song_data
        .dw     test_fm_song_part_e - test_fm_song_data
        .dw     test_fm_song_part_f - test_fm_song_data
        .dw     test_fm_song_empty - test_fm_song_data      ; G (SSG)
        .dw     test_fm_song_empty - test_fm_song_data      ; H
        .dw     test_fm_song_empty - test_fm_song_data      ; I
        .dw     test_fm_song_part_j - test_fm_song_data     ; J (ADPCM-B)
        .dw     test_fm_song_part_k - test_fm_song_data     ; K (Rhythm)
        .dw     test_fm_song_empty - test_fm_song_data      ; rhythm addr
        .dw     test_fm_song_empty - test_fm_song_data      ; prgdat_adr

test_fm_song_part_a:
        .db     0x80                    ; Part A empty (chip ch 1)

test_fm_song_part_b:
        ;; 全 part 8 note × 0x20 tick で揃え (= 同時開始 / 同時終了)
        .db     0x40, 0x20              ; C4
        .db     0x42, 0x20              ; D4
        .db     0x44, 0x20              ; E4
        .db     0x45, 0x20              ; F4
        .db     0x47, 0x20              ; G4
        .db     0x49, 0x20              ; A4
        .db     0x4B, 0x20              ; B4
        .db     0x50, 0x20              ; C5
        .db     0x80

test_fm_song_part_c:
        .db     0x47, 0x20              ; G4
        .db     0x4B, 0x20              ; B4
        .db     0x52, 0x20              ; D5
        .db     0x57, 0x20              ; G5
        .db     0x55, 0x20              ; F5
        .db     0x52, 0x20              ; D5
        .db     0x4B, 0x20              ; B4
        .db     0x47, 0x20              ; G4
        .db     0x80

test_fm_song_part_d:
        .db     0x80                    ; Part D empty (chip ch 4)

test_fm_song_part_e:
        .db     0x30, 0x20              ; C3
        .db     0x37, 0x20              ; G3
        .db     0x39, 0x20              ; A3
        .db     0x35, 0x20              ; F3
        .db     0x30, 0x20              ; C3
        .db     0x37, 0x20              ; G3
        .db     0x39, 0x20              ; A3
        .db     0x30, 0x20              ; C3
        .db     0x80

test_fm_song_part_f:
        .db     0x44, 0x20              ; E4
        .db     0x47, 0x20              ; G4
        .db     0x49, 0x20              ; A4
        .db     0x4B, 0x20              ; B4
        .db     0x50, 0x20              ; C5
        .db     0x4B, 0x20              ; B4
        .db     0x47, 0x20              ; G4
        .db     0x44, 0x20              ; E4
        .db     0x80

test_fm_song_part_j:
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x40, 0x40
        .db     0x80

test_fm_song_part_k:
        .db     0xEB, 0x01              ; rhykey arg=0x01
        .db     0xEA, 0x10              ; rhyvs arg=0x10
        .db     0xE9, 0x80              ; rpnset arg=0x80
        .db     0xE8, 0x10              ; rmsvs arg=0x10
        .db     0xE6, 0x01              ; rmsvs_sft arg=0x01
        .db     0xE5, 0x10, 0x01        ; rhyvs_sft arg=0x10, 0x01
        .db     0xF1, 0x00              ; pdrswitch arg=0x00
        .db     0x80

test_fm_song_empty:
        .db     0x80


;;; ----- PSG / part helper -----

pmdneo_song_main::
        ld      a, #PART_FM1
        call    fmmain
        ld      a, #PART_FM2
        call    fmmain
        ld      a, #PART_FM3
        call    fmmain
        ld      a, #PART_FM4
        call    fmmain
        ld      a, #PART_FM5
        call    fmmain
        ld      a, #PART_FM6
        call    fmmain
        ld      a, #PART_SSG1
        call    pmdneo_psgmain
        ld      a, #PART_SSG2
        call    pmdneo_psgmain
        ld      a, #PART_SSG3
        call    pmdneo_psgmain
        ld      a, #PART_PCM
        call    adpcmb_main
        ld      a, #PART_RHYTHM
        call    rhythm_main
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


;;; pmdneo_fm_keyon / keyoff

pmdneo_fm_keyon::
        ;; A = note byte, B = FM ch index
        push    bc
        call    fnumset_fm
        pop     bc

        push    bc
        ld      hl, #fm_keyon_values
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, #REG_FM_KEY_ON_OFF_OPS
        ld      c, (hl)
        call    ym2610_write_port_a
        pop     bc
        ret

pmdneo_fm_keyoff::
        ;; B = FM ch index
        push    bc
        ld      hl, #fm_keyoff_values
        ld      a, b
        ld      e, a
        ld      d, #0
        add     hl, de
        ld      b, #REG_FM_KEY_ON_OFF_OPS
        ld      c, (hl)
        call    ym2610_write_port_a
        pop     bc
        ret


;;; ----- fmmain: FM part 1 step -----
;;;
;;; pmdneo_psgmain と同じ MML state machine を使い、 note 経路のみ
;;; FM keyon/keyoff + fnumset_fm に差し替える。

fmmain::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af
        sub     #PART_FM1
        ld      b, a                        ; FM ch index (0-5)

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, fmmain_parse

        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, fmmain_done

        ;; length == 0 になったら keyoff して次 token へ進む
        call    pmdneo_fm_keyoff

fmmain_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, fmmain_end
        jr      c, fmmain_note
        cp      #0xB1
        jr      c, fmmain_clear

        call    commandsp
        jr      fmmain_parse

fmmain_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a

        ld      a, PART_OFF_NOTE(ix)
        call    pmdneo_fm_keyon
        ret

fmmain_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, fmmain_clear

        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      fmmain_parse

fmmain_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

fmmain_done:
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
        call    pmdneo_scale_mml_length
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


;;; ----- adpcmb_main: Part J ADPCM-B part 1 step -----
;;;
;;; Part J note byte triggers the hardcoded beat sample. length 0 stops ADPCM-B.

adpcmb_main::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, adpcmb_main_parse

        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, adpcmb_main_done

        call    adpcmb_keyoff

adpcmb_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, adpcmb_main_end
        jr      c, adpcmb_main_note
        cp      #0xB1
        jr      c, adpcmb_main_clear

        call    commandsp
        jr      adpcmb_main_parse

adpcmb_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a

        call    adpcmb_keyon
        ret

adpcmb_main_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, adpcmb_main_clear

        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      adpcmb_main_parse

adpcmb_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

adpcmb_main_done:
        ret


;;; ----- rhythm_main: K/R part 1 step -----
;;;
;;; K/R 内蔵 rhythm は YM2610/B に存在しないため、 MML stream と length
;;; state だけ進める。 chip register write は行わない。

rhythm_main::
        push    af
        call    pmdneo_part_ix_from_part
        pop     af

        ld      a, PART_OFF_ADDR(ix)
        or      PART_OFF_ADDR+1(ix)
        ret     z

        ld      a, PART_OFF_LEN(ix)
        or      a
        jr      z, rhythm_main_parse

        dec     a
        ld      PART_OFF_LEN(ix), a
        jr      nz, rhythm_main_done

rhythm_main_parse:
        call    pmdneo_part_fetch_byte
        cp      #0x80
        jr      z, rhythm_main_end
        jr      c, rhythm_main_note
        cp      #0xB1
        jr      c, rhythm_main_clear

        call    commandsr
        jr      rhythm_main_parse

rhythm_main_note:
        ld      PART_OFF_NOTE(ix), a
        call    pmdneo_part_fetch_byte
        call    pmdneo_scale_mml_length
        ld      PART_OFF_LEN(ix), a
        ret

rhythm_main_end:
        ld      a, PART_OFF_LOOP(ix)
        or      PART_OFF_LOOP+1(ix)
        jr      z, rhythm_main_clear

        ld      l, PART_OFF_LOOP(ix)
        ld      h, PART_OFF_LOOP+1(ix)
        ld      PART_OFF_ADDR(ix), l
        ld      PART_OFF_ADDR+1(ix), h
        jr      rhythm_main_parse

rhythm_main_clear:
        xor     a
        ld      PART_OFF_ADDR(ix), a
        ld      PART_OFF_ADDR+1(ix), a

rhythm_main_done:
        ret


;;; pmdneo_scale_mml_length:
;;;   input : A = raw MML length byte
;;;   output: A = PSG main 用 tick length
;;;
;;; SubB-7 暫定: PMD V4.8s の本来の tempo / length 換算は未実装。
;;; SAMPLE.M は length 1 の note が多く、そのままだと聴感確認不能なため、
;;; raw length を 8 倍して audio gate 用の速度に落とす。

pmdneo_scale_mml_length::
        push    bc
        or      a
        jr      nz, pmdneo_scale_mml_length_start
        inc     a                       ; 0 length は最低 1 tick にする
        jr      pmdneo_scale_mml_length_done

pmdneo_scale_mml_length_start:
        ld      c, #PMDNEO_MML_LEN_SHIFT
pmdneo_scale_mml_length_loop:
        add     a, a
        jr      c, pmdneo_scale_mml_length_saturate
        dec     c
        jr      nz, pmdneo_scale_mml_length_loop
        jr      pmdneo_scale_mml_length_done

pmdneo_scale_mml_length_saturate:
        ld      a, #0xFF

pmdneo_scale_mml_length_done:
        pop     bc
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

commandsr::
        cp      #0xB1
        ret     c

        cpl
        add     a, a
        ld      l, a
        ld      h, #0
        ld      de, #cmdtblr
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


;;; K/R 用 dispatch table
;;;
;;; cmdtblp と同じ 79 entry。 K/R specific cmd だけ no-op stub に差替える。

cmdtblr:
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
        .dw     pdrswitch                   ; 0xF1 *
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
        ;; SubB-7 では ROM 上の SAMPLE.M を直接読むため、 PMD 本家のように
        ;; loop counter byte を MML buffer 内へ自己書き換えできない。
        ;; audio gate Step 1 では loop を展開せず、 4 byte 引数だけ消費して
        ;; 次の opcode へ進めることで hang up を避ける。
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
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

;;; ----- FM keyon/keyoff value table -----

fm_keyon_values:
        .db     0xF0, 0xF1, 0xF2, 0xF4, 0xF5, 0xF6

fm_keyoff_values:
        .db     0x00, 0x01, 0x02, 0x04, 0x05, 0x06


;;; ----- adpcm_b_beat_struct: ngdevkit snd_adpcm_b_play 用 8 byte 構造体 -----
;;;
;;; layout:
;;;   byte 0-1: start address LSB/MSB (= 256 byte unit)
;;;   byte 2-3: stop address LSB/MSB
;;;   byte 4-5: delta-N (= playback frequency coefficient, LE)
;;;   byte 6: L/R output (0xC0 = both)
;;;   byte 7: volume (0x00-0xFF)

adpcm_b_beat_struct::
        .db     BEAT_START_LSB
        .db     BEAT_START_MSB
        .db     BEAT_STOP_LSB
        .db     BEAT_STOP_MSB
        ;; SubE-1: delta-N = 24000 * 65536 / 55555 = 0x6E96 (= sample native 24 kHz、
        ;; o5a 基準確認用、 ngdevkit 15 の 0xcb6b は 44.1 kHz で 1.84x 速かったため)
        .dw     0x6E96
        .db     0xC0
        .db     0xFF


;;; ----- test_play_adpcmb_beat: SubE-1 ADPCM-B 単発再生 -----
;;;
;;; 入力: なし
;;; 動作: nullsound snd_adpcm_b_play (IX = config struct) で beat sample 再生
;;; 破壊: A, IX

test_play_adpcmb_beat::
        ld      ix, #adpcm_b_beat_struct
        call    snd_adpcm_b_play
        ret
