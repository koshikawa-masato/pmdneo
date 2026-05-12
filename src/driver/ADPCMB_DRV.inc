;;;
;;; ADPCMB_DRV.ASM
;;; ADPCM-B 1ch driver
;;;
;;; YM2610/B 内蔵 ADPCM-B 機構 (port A 0x10-0x1B) を駆動。
;;; PMD V4.8s `.m2` の OPNA ADPCM RAM 経路を YM2610/B 内蔵 ADPCM-B に
;;; 対応付ける。
;;;
;;; sample data は `.PPC` format (PMDB2 用 ADPCM RAM sample pack) を
;;; 流用、 `.PNE` (ADPCM-A 用) と同じ NEOGEO V-ROM bank に並べて焼き
;;; 込む。 driver は sample 番号で V-ROM 内 sample header を引き、
;;; start/end addr + delta-N + volume を chip register に書込。
;;;
;;; 設計書 3 §4 (ADPCM-B 1ch dispatch の YM2610/B register mapping) 参照。
;;;
;;; SubA: 空 stub (silent ROM 用)。 Phase 2 SubE で本実装。

        .area CODE

;;; ----- adpcmb_keyon: 既存実装 (= 4-1 では維持) -----
;;;
;;; 既存 caller (= standalone_test.s adpcmb_keyon_hook、 PMD_Z80.inc
;;; adpcmb_main_note) が IX 未設定で呼ぶ前提のため、 ld ix, #adpcm_b_beat_struct
;;; 固定を維持。 引数化 (= IX = config struct を caller 側で設定) への refactor
;;; は 4-3 main loop integration で caller 側と一体で実施予定 (= 設計書 3 §4-4
;;; 直接 register 書込 流儀への移行も同タイミング)。
adpcmb_keyon::
        ld      ix, #adpcm_b_beat_struct
        call    snd_adpcm_b_play
        ret

;;; ----- adpcmb_keyoff: 既存実装 (= SubE-1 確立済) -----
;;;
;;; 動作: register 0x10 ← 0x01 (= reset bit、 = stop)
adpcmb_keyoff::
        ld      b, #REG_ADPCM_B_START_STOP
        ld      c, #0x01
        call    ym2610_write_port_a
        ret

;;; ----- adpcmb_volset: SubE-1 本実装 (4-1) -----
;;;
;;; 入力: A = volume (0-255、 直接 chip register に流す)
;;; 動作: register 0x1B (= REG_ADPCM_B_VOLUME) に A を書込
adpcmb_volset::
        ld      b, #REG_ADPCM_B_VOLUME
        ld      c, a
        call    ym2610_write_port_a
        ret

;;; ----- adpcmb_panset: SubE-1 本実装 (4-1) -----
;;;
;;; 入力: A = pan (bit 7=L, bit 6=R、 例 0xC0 = both、 0x80 = L only、 0x40 = R only)
;;; 動作: register 0x11 (= REG_ADPCM_B_PAN) に A を書込
adpcmb_panset::
        ld      b, #REG_ADPCM_B_PAN
        ld      c, a
        call    ym2610_write_port_a
        ret

;;; ----- adpcmb_setfreq: SubE-1 本実装 (4-1) -----
;;;
;;; 入力: HL = delta-N (LE 16-bit、 sample playback 周波数係数)
;;; 動作: register 0x19 (= LSB) + 0x1A (= MSB) に HL を書込
adpcmb_setfreq::
        ld      b, #REG_ADPCM_B_DELTA_N_LSB
        ld      c, l
        call    ym2610_write_port_a
        ld      b, #REG_ADPCM_B_DELTA_N_MSB
        ld      c, h
        call    ym2610_write_port_a
        ret
