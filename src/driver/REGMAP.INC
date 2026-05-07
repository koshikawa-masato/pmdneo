;;;
;;; REGMAP.INC
;;; YM2610/B chip register 定数定義
;;;
;;; 設計書 2 §5-1 (ADPCM-A register layout) / 設計書 3 §4-2 (ADPCM-B
;;; register layout) で確定した register address を sdasz80 定数として
;;; 定義する。
;;;
;;; SubA: 全 register 定数を初期定義。 Phase 2 SubB-E + Phase 3 で
;;; 各 module から参照される。
;;;

;;; ----- NEOGEO Z80 → YM2610 chip 通信 port -----

YM2610_PORT_A_REG  = 0x04   ; port A register address write
YM2610_PORT_A_DATA = 0x05   ; port A register data write
YM2610_PORT_B_REG  = 0x06   ; port B register address write
YM2610_PORT_B_DATA = 0x07   ; port B register data write

YM2610_STATUS_PORT = 0x04   ; status read (port A の入力 read)

;;; ----- TIMER register (port A) -----

YM2610_REG_TIMER_A_LOW  = 0x24   ; TIMER-A 低 8bit
YM2610_REG_TIMER_A_HIGH = 0x25   ; TIMER-A 高 2bit
YM2610_REG_TIMER_B      = 0x26   ; TIMER-B (8bit)
YM2610_REG_TIMER_CTRL   = 0x27   ; TIMER 制御 (load/enable/reset)

;;; ----- ADPCM-B register (port A、 設計書 3 §4-2) -----

ADPCMB_REG_CONTROL   = 0x10   ; bit 7 Start、 bit 6 Repeat、 bit 4 Reset
ADPCMB_REG_LR_PAN    = 0x11   ; bit 7-6 LR pan
ADPCMB_REG_START_L   = 0x12   ; start address LSB (256 byte unit)
ADPCMB_REG_START_H   = 0x13   ; start address MSB
ADPCMB_REG_END_L     = 0x14   ; end address LSB
ADPCMB_REG_END_H     = 0x15   ; end address MSB
ADPCMB_REG_DELTA_L   = 0x19   ; Delta-N LSB (再生周波数係数)
ADPCMB_REG_DELTA_H   = 0x1A   ; Delta-N MSB
ADPCMB_REG_VOLUME    = 0x1B   ; Volume (0-255)

;;; ----- ADPCM-A register (port B、 設計書 2 §5-1) -----

ADPCMA_REG_KEYON_DUMP = 0x00   ; bit 7 Dump、 bit 5-0 ch flag
ADPCMA_REG_MASTER_VOL = 0x01   ; bit 5-0 全 ch 共通 master volume (0-63)

ADPCMA_REG_VOL_BASE   = 0x08   ; ch 0-5 の per-ch volume + LR pan: +ch
ADPCMA_REG_START_L_BASE = 0x10   ; ch 0-5 の start LSB: +ch
ADPCMA_REG_START_H_BASE = 0x18   ; ch 0-5 の start MSB: +ch
ADPCMA_REG_END_L_BASE   = 0x20   ; ch 0-5 の end LSB: +ch
ADPCMA_REG_END_H_BASE   = 0x28   ; ch 0-5 の end MSB: +ch

;;; ----- FM register (port A、 設計書 3 §1-3 / SubC で詳細実装) -----
;;; ----- SSG register (port A、 SubB で詳細実装) -----

;;; (FM/SSG register 帯は Phase 2 SubB-C で具体実装時に展開する)
