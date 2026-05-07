;;;
;;; PMDNEO build top
;;;
;;; PMDNEO driver の build entry point。 sdasz80 (ngdevkit 慣習) で
;;; compile される .s file。 nullsound framework と integrate して
;;; ngdevkit-examples の sound driver build 経路に乗る。
;;;
;;; 設計書 1: docs/design/mn_binary_layout.md
;;; 設計書 2: docs/design/ppz_to_adpcma_mapping.md
;;; 設計書 3: docs/design/phase2_driver_plan.md
;;;
;;; SubA: silent ROM stub。 nullsound integration + 各 module skeleton を
;;; include。 SubB-F で各 routine を段階的に埋める。
;;;
;;; SPDX-License-Identifier: GPL-3.0-or-later
;;; Copyright (C) 2026 越川将人 (M.Koshikawa.)

        ;;; nullsound 公式 include
        .include "helpers.inc"

        ;;; build flag
        neogeo  = 1     ; YM2610/B chip 対応 (常に 1)
        adpcmb  = 1     ; ADPCM-B 1ch 対応 (Phase 2 から有効)
        adpcma  = 0     ; ADPCM-A 6ch 対応 (Phase 2 SubA では 0、 Phase 3 で 1)
        ym2610b = 1     ; FM 6ch 想定 (YM2610 では A/D ch 自動 mute)

        ;;; ----- 各 module include (設計書 3 §1-2 依存関係図) -----

        .include "WORKAREA.inc"
        .include "REGMAP.inc"
        .include "IRQ.inc"
        .include "KR_STUB.inc"
        .include "PMD_Z80.inc"

        .if adpcmb
        .include "ADPCMB_DRV.inc"
        .endif

        .if adpcma
        .include "ADPCMA_DRV.inc"
        .endif
