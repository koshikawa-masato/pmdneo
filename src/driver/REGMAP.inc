;;;
;;; REGMAP.inc
;;; YM2610/B chip register 定数定義
;;;
;;; nullsound 公式の ports.inc + ym2610.inc を流用 (= ngdevkit 慣習に沿う)。
;;; PMDNEO 独自 alias は本 file 内で追加定義。
;;;
;;; 設計書 2 §5-1 (ADPCM-A register layout) / 設計書 3 §4-2 (ADPCM-B
;;; register layout) で確定した register address は nullsound の REG_*
;;; 定数と同一値。
;;;

        ;;; nullsound 公式の Z80 port + chip register 定数
        .include "ports.inc"
        .include "ym2610.inc"

;;; ----- PMDNEO 独自 alias (互換性のため) -----

        .equ    YM2610_STATUS_PORT, PORT_YM2610_STATUS
