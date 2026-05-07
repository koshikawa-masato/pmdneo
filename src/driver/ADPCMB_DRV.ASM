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

;;; ----- adpcmb_keyon: SubE で実装 -----
;;;
;;; 入力: A = sample 番号、 BC = delta-N、 D = pan/volume
;;; 動作: V-ROM 内 sample header 引き → 0x12-0x15 に start/end addr 書込
;;;       → 0x19/0x1A に delta-N 書込 → 0x1B に volume 書込 → 0x11 に pan
;;;       → 0x10 に start bit (0x80) 書込
adpcmb_keyon::
        ret

;;; ----- adpcmb_keyoff: SubE で実装 -----
;;;
;;; 動作: register 0x10 ← 0x01 (= reset bit、 = stop)
adpcmb_keyoff::
        ret

;;; ----- adpcmb_volset / adpcmb_panset / adpcmb_setfreq: SubE で実装 -----

adpcmb_volset::
        ret

adpcmb_panset::
        ret

adpcmb_setfreq::
        ret
