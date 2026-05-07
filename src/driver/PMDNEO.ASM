;;;
;;; PMDNEO build top
;;;
;;; PMDNEO driver の build entry point。 flag を立てて各 module を include
;;; する流儀 (= PMD V4.8s の PMDPPZ.ASM 流儀踏襲、 設計書 3 §2-1 参照)。
;;;
;;; 設計書 1: docs/design/mn_binary_layout.md
;;; 設計書 2: docs/design/ppz_to_adpcma_mapping.md
;;; 設計書 3: docs/design/phase2_driver_plan.md
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright (C) 2026 越川将人 (M.Koshikawa.)

        ;; build flag
        neogeo  = 1     ; YM2610/B chip 対応 (常に 1)
        adpcmb  = 1     ; ADPCM-B 1ch 対応 (Phase 2 から有効)
        adpcma  = 0     ; ADPCM-A 6ch 対応 (Phase 2 SubA では 0、 Phase 3 で 1)
        ym2610b = 1     ; FM 6ch 想定 (YM2610 では A/D ch 自動 mute)

        .include "WORKAREA.INC"
        .include "REGMAP.INC"
        .include "IRQ.INC"
        .include "KR_STUB.INC"
        .include "PMD_Z80.ASM"

        .if adpcmb
        .include "ADPCMB_DRV.ASM"
        .endif

        .if adpcma
        .include "ADPCMA_DRV.ASM"
        .endif
