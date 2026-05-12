;;;
;;; IRQ.INC
;;; TIMER-B IRQ handler + sound command 受付
;;;
;;; 設計書 3 §5 (TIMER-B IRQ NEOGEO 環境置換) 参照。
;;;
;;; SubA: silent ROM のため IRQ handler は最小 stub (= TIMER-B 来ても
;;; 何もせず ret)、 sound command 受付は no-op。 Phase 2 SubB-F で
;;; 各部を埋める。
;;;

        .area CODE

;;; ----- pmd_main: TIMER-B IRQ handler の主処理 -----
;;;
;;; SubA: 即 ret (silent ROM、 何も鳴らさない)
;;; SubB-F: per-part main loop (FM/SSG/ADPCM-B 順次実装)、
;;;         tempo / fade / mask の global flag 更新、 chip 駆動

pmd_main::
        ret


;;; ----- sound command jump table (= ngdevkit nullsound 流儀) -----
;;;
;;; 設計書 3 §5-3 で確定した nullsound 系統 sound command framework。
;;; M68K 側から REG_SOUND port write 経由で sound command を発行、
;;; Z80 IRQ handler が cmd_jmptable で振り分け。
;;;
;;; SubA: stub のみ (受付するが何もしない、 silent ROM)

;;; cmd_jmptable: nullsound 公式の slot 0x00, 0x01, 0x03 は nullsound NMI
;;; handler が直接参照する予約 cmd。 user は 0x02 と 0x04 以降を独自 cmd
;;; として使用可能。
;;;
;;; nullsound NMI handler 経路:
;;;   *REG_SOUND = 1 → snd_command_01_prepare_for_rom_switch (NMI 内直接 jp、 nullsound.lib 提供)
;;;   *REG_SOUND = 3 → snd_command_03_reset_driver (NMI 内直接 jp、 user 実装必須)
;;;   *REG_SOUND = 2/4-N → fifo に push、 snd_mainloop polling で cmd_jmptable[N] dispatch
cmd_jmptable::
        jp      snd_command_unused                       ; 0x00 no-op
        jp      snd_command_01_prepare_for_rom_switch    ; 0x01 ngdevkit reserved (nullsound.lib)
        jp      snd_command_02_play_song                 ; 0x02 PMDNEO 楽曲再生開始
        jp      snd_command_03_reset_driver              ; 0x03 ngdevkit reserved (user 実装)
        jp      snd_command_04_fade_out                  ; 0x04 fade out (将来)
        jp      snd_command_05_play_adpcmb_test          ; 0x05 ADPCM-B beat 単発再生
        ;; 残り 122 entry を未使用 cmd で padding (nullsound 慣習、 helpers.inc macro)
        init_unused_cmd_jmptable


;;; snd_command_03_reset_driver は nullsound.lib に default 実装あり
;;; (= chip silence + driver state reset)。 PMDNEO 側で再定義しない。
;;; main.c で cmd 3 を最初に発行することで Z80 driver が ready になる。


;;; ----- snd_command_02_play_song: ADR-0016 step 4-2.5 で pmdneo_load_m 経路に refactor -----
;;;
;;; cmd 3 (= nullsound default reset) で chip silence + Z80 init 後、 cmd 2 で:
;;; 1. pmdneo_init (= SSG mixer + TIMER-B 起動 + driver state init)
;;; 2. pmdneo_load_m (= sample_m_data or pmddotnet_song の m_buf header を読み
;;;    part 0-10 の body address を per-part workarea に設定、 設計書 §6-1)
;;;    PMDNEO_USE_PMDDOTNET build flag で sample_m_data / pmddotnet_song 切替
;;; 3. polling loop: TIMER-B tick 毎に pmd_z80_main を call、 TIMER-B IRQ count
;;;    を継続確認
;;;
;;; ret しない (= snd_mainloop に戻らない)、 後続 cmd 受付不可。
;;;
;;; 注意: 旧 test_play_fm_song / test_fm_song_data (= SubC-3 hardcoded 4 ch FM)
;;; は PMD_Z80.inc に legacy として残置、 本経路では使用しない。

snd_command_02_play_song::
        call    pmdneo_init
        call    pmdneo_load_m
pmdneo_play_loop::
        ld      a, (state_timer_tick_reached)
        or      a
        jp      z, pmdneo_play_loop
        xor     a
        ld      (state_timer_tick_reached), a
        call    pmd_z80_main
        jp      pmdneo_play_loop


snd_command_04_fade_out::
        ;; SubF-1 minimum fade: immediately silence supported chips and stop song.
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x00
        call    ym2610_write_port_a
        ld      b, #REG_SSG_B_VOLUME
        call    ym2610_write_port_a
        ld      b, #REG_SSG_C_VOLUME
        call    ym2610_write_port_a

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

        call    adpcmb_keyoff

        ld      a, #1
        ld      (driver_fade_state), a
        ret


;;; ----- snd_command_05_play_adpcmb_test: SubE-1 ADPCM-B 単発再生 -----
;;;
;;; cmd 2 (FM song) と並列発火。即 ret するため polling loop に入らず、
;;; FM song 駆動を妨げない。

snd_command_05_play_adpcmb_test::
        call    test_play_adpcmb_beat
        ret
