;;;
;;; WORKAREA.INC
;;; per-part workarea offset 定数 + workarea 領域定義
;;;
;;; 設計書 2 §6-3 (part 番号 → workarea offset 対応表) /
;;; 設計書 3 §1 (driver source 構造) 参照。
;;;
;;; SubA: part 番号定数 + workarea 領域 (BSS) を定義。 各 part の
;;; workarea size は暫定値、 Phase 2 SubB-C で実体化する。
;;;

;;; ----- part 番号定数 (0-16) -----

PART_FM1     = 0    ; A
PART_FM2     = 1    ; B
PART_FM3     = 2    ; C
PART_FM4     = 3    ; D (YM2610 では mute、 YM2610B で生)
PART_FM5     = 4    ; E
PART_FM6     = 5    ; F
PART_SSG1    = 6    ; G
PART_SSG2    = 7    ; H
PART_SSG3    = 8    ; I
PART_PCM     = 9    ; J、 ADPCM-B
PART_RHYTHM  = 10   ; K=R、 OPNA 内蔵 rhythm = no-op stub (PMDNEO で無音)
PART_ADPCMA1 = 11   ; L
PART_ADPCMA2 = 12   ; M
PART_ADPCMA3 = 13   ; N
PART_ADPCMA4 = 14   ; O
PART_ADPCMA5 = 15   ; P
PART_ADPCMA6 = 16   ; Q

PART_COUNT   = 17

;;; ----- per-part workarea size (= N、 暫定) -----
;;;
;;; Phase 2 SubB-C で各 part 共通 field (address / leng / qdata /
;;; volume / fnum / 等) を確定して実体化する。 PMD V4.8s の qq struc
;;; (PPZDRV.ASM L8155-) を Z80 移植する形で固める。
;;;
;;; SubA 暫定値: 64 byte (= driver build 通る最小値)

PART_WORKAREA_SIZE = 64

;;; ----- workarea 領域 (BSS) -----

        .area BSS

;;; per-part workarea 領域: PART_COUNT × PART_WORKAREA_SIZE = 17 × 64 = 1088 byte
;;; NEOGEO Z80 RAM (約 2 KB) のうち約半分を workarea で確保
part_workarea::
        .ds PART_WORKAREA_SIZE * PART_COUNT

;;; global driver state (= tempo / fade / mask 系の共通領域)
;;; SubA 暫定 16 byte、 Phase 2 SubB-F で field 確定

driver_state::
        .ds 16

;;; SubB-2: TIMER-B IRQ count (= 周期発火の動作証跡)
;;; nullsound の TIMER-B IRQ で update_timer_state_tracker が呼ばれた後、
;;; PMDNEO の polling loop が state_timer_tick_reached を読み取って
;;; pmd_z80_main を call。 pmd_z80_main で本 counter を 16-bit increment。

pmdneo_irq_count::
        .ds 2
