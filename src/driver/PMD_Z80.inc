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

        ret


;;; ----- pmd_z80_main: TIMER-B IRQ から呼ばれる main 処理 -----
;;;
;;; SubB-1: 即 ret (silent ROM、 TIMER-B IRQ は SubB-2 で実装)
;;; SubB-2 以降: tempo / fade 更新、 per-part main loop dispatcher

pmd_z80_main::
        ret
