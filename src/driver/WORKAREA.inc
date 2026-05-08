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

;;; ----- per-part field offset -----
;;;
;;; PMD V4.8s の qq struc から、 Phase 2 SubB で PSG 解析に必要な最小
;;; 部分を先に固定する。 FM / ADPCM-B 側は後続 sub-phase で拡張する。

PART_OFF_ADDR     = 0    ; 2 byte current stream pointer
PART_OFF_LOOP     = 2    ; 2 byte loop start pointer
PART_OFF_LEN      = 4    ; 1 byte length counter
PART_OFF_QDATA    = 5    ; 1 byte q
PART_OFF_QDATB    = 6    ; 1 byte Q
PART_OFF_QDAT2    = 7    ; 1 byte q2
PART_OFF_QDAT3    = 8    ; 1 byte q3
PART_OFF_VOLUME   = 9    ; 1 byte volume
PART_OFF_SHIFT    = 10   ; 1 byte transposition
PART_OFF_NOTE     = 11   ; 1 byte last note
PART_OFF_LOOPCNT  = 12   ; 1 byte loop counter
PART_OFF_LFOSWI   = 13   ; 1 byte LFO switch flag
PART_OFF_PSGPAT   = 14   ; 1 byte PSG tone/noise/mix
PART_OFF_TIEFLAG  = 15   ; 1 byte tie flag
PART_OFF_ENVF     = 16   ; 1 byte PSG envelope mode
PART_OFF_PAT      = 17   ; 1 byte PSG envelope pat
PART_OFF_PV2      = 18   ; 1 byte PSG envelope pv2
PART_OFF_PR1      = 19   ; 1 byte PSG envelope pr1
PART_OFF_PR2      = 20   ; 1 byte PSG envelope pr2
PART_OFF_ENVVOL   = 21   ; 1 byte PSG envelope volume
PART_OFF_FLAGS    = 22   ; 1 byte future use

;;; ----- workarea 領域 (BSS) -----

        .area BSS

;;; SubB-7: SAMPLE.M load 用 mmlbuf (= m_buf 開始位置の絶対 address)
mmlbuf::
        .ds 2

;;; per-part workarea 領域: PART_COUNT × PART_WORKAREA_SIZE = 17 × 64 = 1088 byte
;;; NEOGEO Z80 RAM (約 2 KB) のうち約半分を workarea で確保
part_workarea::
        .ds PART_WORKAREA_SIZE * PART_COUNT

;;; global driver state (= tempo / fade / mask 系の共通領域)
;;; SubA 暫定 16 byte、 Phase 2 SubB-F で field 確定

driver_state::
driver_tempo_d::
        .ds 1
driver_tempo_d_push::
        .ds 1
driver_tempo_48::
        .ds 1
driver_tempo_48_push::
        .ds 1
driver_psg_noise::
        .ds 1
driver_tieflag::
        .ds 1
driver_song_ready::
        .ds 1
driver_song_base::
        .ds 2
driver_song_end::
        .ds 2
driver_fade_state::
        .ds 1
        .ds 4

;;; SubB-2: TIMER-B IRQ count (= 周期発火の動作証跡)
;;; nullsound の TIMER-B IRQ で update_timer_state_tracker が呼ばれた後、
;;; PMDNEO の polling loop が state_timer_tick_reached を読み取って
;;; pmd_z80_main を call。 pmd_z80_main で本 counter を 16-bit increment。

pmdneo_irq_count::
        .ds 2

;;; SubB-4: scale 演奏 state (= G part でドレミファソラシド)
;;; scale_step: 0-7 が現在の scale step、 8 で end
;;; scale_tick_hi/lo: TIMER-B tick の残り、 0 になったら次 step へ
;;;             (= note duration を tick 単位で表現)

scale_step::
        .ds 1

scale_tick_lo::
        .ds 1

scale_tick_hi::
        .ds 1

;;; SubC-2: scale 駆動 mode (0 = SSG ch A 既存、 1 = FM chip ch 2)
scale_mode::
        .ds 1
