;;;
;;; ADPCMA_DRV.ASM
;;; ADPCM-A 6ch driver (Phase 3 で完成)
;;;
;;; YM2610/B 内蔵 ADPCM-A 機構 (port B 0x00-0x2D) を駆動。
;;; PMDPPZ の PPZ8 module (PPZDRV.ASM 865 行 + PMDDotNET PPZDRV.cs 1135
;;; 行) を read-only 参照テンプレートとして ADPCM-A 6ch 用に書き換える。
;;;
;;; sample data は `.PNE` format (PMDNEO 専用 ADPCM-A 18.5kHz 4bit mono
;;; sample pack)、 NEOGEO V-ROM 経由で chip が直接読出。
;;;
;;; 設計書 2 §3-§7 (PPZ → ADPCM-A 翻訳 mapping) 参照。
;;;
;;; Phase 2 SubA では adpcma=0 のため include されない (= 本 file は
;;; Phase 3 着手まで空 stub)。

        .area CODE

;;; ----- adpcma_init: Phase 3 で実装 -----
;;;
;;; 動作: 0x00 ← 0xBF (全 ch dump)、 0x01 ← 0x3F (max master vol)
adpcma_init::
        ret

;;; ----- adpcma_keyon: Phase 3 で実装 -----
;;;
;;; 入力: A = ch (0-5)、 DE = sample table entry pointer
;;; 動作: 0x10+ch / 0x18+ch / 0x20+ch / 0x28+ch に start/end addr 書込、
;;;       0x00 に (1 << ch) で keyon
adpcma_keyon::
        ret

;;; ----- adpcma_keyoff: Phase 3 で実装 -----
;;;
;;; 動作: 0x00 ← 0x80 | (1 << ch) で dump (= keyoff 相当)
adpcma_keyoff::
        ret

;;; ----- adpcma_volset / adpcma_panset / adpcma_main: Phase 3 で実装 -----

adpcma_volset::
        ret

adpcma_panset::
        ret

adpcma_main::
        ret
