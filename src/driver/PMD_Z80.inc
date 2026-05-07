;;;
;;; PMD_Z80.inc
;;; PMD V4.8s の Z80 化 base driver
;;;
;;; PMD.ASM (10864 行 x86 アセンブリ) を NEOGEO Z80 環境に移植する base
;;; module。 PMDPPZ.ASM が PMD.ASM を include する流儀を踏襲して、
;;; PMDNEO.s が flag を立てて本 file を include する。
;;;
;;; SubB-1: driver init routine (pmdneo_init = SSG silent init) を実装。
;;; chip 駆動 wrapper は nullsound.lib 提供の `ym2610_write_port_a` /
;;; `ym2610_write_port_b` を使用 (= 重複定義しない)。
;;;
;;; nullsound 公式の chip 駆動 calling convention:
;;;   ym2610_write_port_a / port_b
;;;     入力: B = register address、 C = data byte
;;;     破壊: A、 (port 出力)
;;;
;;; SubB-2 以降で TIMER-B IRQ + per-part main loop を順次実装。
;;;

        .area CODE


;;; ----- pmdneo_init: driver 起動時の SSG silent init -----
;;;
;;; SubB-1: SSG mixer (0x07) を tone 3 ch enable + noise all disable に
;;; 設定、 volume A/B/C を mute (0x00) に設定。 これで chip が「3 ch 全部
;;; tone 出力 mode、 ただし volume 0 で無音」 状態になる。
;;;
;;; 入力: なし
;;; 破壊: A、 B、 C

pmdneo_init::
        ;; SSG mixer (0x07) = 0x38
        ;;   bit 0-2: tone enable (low active、 0=enable) → 0,0,0 = 全 enable
        ;;   bit 3-5: noise enable (low active) → 1,1,1 = 全 disable
        ;;   bit 6-7: I/O 用、 NEOGEO では未使用
        ld      b, #REG_SSG_ENABLE
        ld      c, #0x38
        call    ym2610_write_port_a

        ;; SSG volume A = 0x00 (mute)
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

        ;; SubB-2: TIMER-B 起動
        ;; pmdneo_irq_count を 0 に初期化
        ld      hl, #0
        ld      (pmdneo_irq_count), hl

        ;; TIMER-B counter (0x26) = 0xC0
        ;; → tick 周期 = (256 - 0xC0) × 16 × 8 / (8 MHz / 2) = 64 × 128 / 4M = 約 488 µs
        ;; → 約 2050 Hz (= TIMER-B 単位、 BPM 換算は SubB-5 で精緻化)
        ;; SubB-2 では「TIMER-B が周期発火」 することのみ確認、 値は仮置き
        ld      b, #REG_TIMER_B_COUNTER
        ld      c, #0xC0
        call    ym2610_write_port_a

        ;; TIMER-B enable + IRQ enable + reset (REG_TIMER_FLAGS = 0x27)
        ;;   bit 1: TIMER-B reset (write 1 で reset)
        ;;   bit 3: TIMER-B enable
        ;;   bit 5: TIMER-B IRQ enable
        ;; = 0b00101010 = 0x2A
        ld      b, #REG_TIMER_FLAGS
        ld      c, #0x2A
        call    ym2610_write_port_a

        ret


;;; ----- pmd_z80_main: TIMER-B tick で呼ばれる main 処理 -----
;;;
;;; SubB-2: pmdneo_irq_count を 16-bit increment (= 動作証跡)。
;;; SubB-3 以降で per-part main loop dispatcher を実装。

pmd_z80_main::
        ld      hl, (pmdneo_irq_count)
        inc     hl
        ld      (pmdneo_irq_count), hl
        ret


;;; ----- test_play_c4: SubB-3 最初の音発生 (hardcoded C4 in SSG ch A) -----
;;;
;;; PMD V4.8s psg_tune_data (= analysis_m_data_structure.md §5-1-1) で
;;; ONKAI 0 (= C) の SSG 周波数値 = 0x0EE8。
;;; YM2610 master clock 8 MHz、 SSG counter = clock / (16 × n) で発音。
;;; n = 0x0EE8 = 3816 → freq = 8e6 / (16 × 3816) ≈ 131 Hz (= C3 or C4 周辺)
;;;
;;; SSG fine tune (0x00) = 周波数 LSB
;;; SSG coarse tune (0x01) = 周波数 MSB (上位 4 bit、 12-bit counter)
;;; SSG volume A (0x08) = 0x08 (= 中音量、 max は 0x0F)
;;;
;;; SubB-3 動作: 起動時に 1 回だけ呼び、 chip register に値を書く。
;;; mixer (0x07) は pmdneo_init で 0x38 (= tone 3 ch enable) に設定済。
;;; volume を 0 から 0x08 に変えるため、 連続音が出る。

test_play_c4::
        ;; SSG ch A fine tune (0x00) = 0xE8 (LSB of 0x0EE8)
        ld      b, #REG_SSG_A_FINE_TUNE
        ld      c, #0xE8
        call    ym2610_write_port_a

        ;; SSG ch A coarse tune (0x01) = 0x0E (MSB of 0x0EE8)
        ld      b, #REG_SSG_A_COARSE_TUNE
        ld      c, #0x0E
        call    ym2610_write_port_a

        ;; SSG volume A (0x08) = 0x0F (max)
        ;; (SubB-3 試行: 中音量 0x08 で無音だったため max に変更、
        ;;  「volume 値が低すぎて聴感不能」 仮説を排除)
        ld      b, #REG_SSG_A_VOLUME
        ld      c, #0x0F
        call    ym2610_write_port_a

        ret
