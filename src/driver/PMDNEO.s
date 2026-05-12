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

        ;;; ADR-0006 §B / ADR-0016 step 3c-2: build flag (sed pre-process で値切替)
        ;;; PMDNEO_TARGET_CHIP_YM2610B: 0=ym2610 / 1=ym2610b
        ;;; PMDNEO_USE_PMDDOTNET: 0=sample_m_data / 1=pmddotnet_song
        .equ    PMDNEO_TARGET_CHIP_YM2610B, 0
        .equ    PMDNEO_USE_PMDDOTNET, 0

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

        ;;; SubB-7: PMD V4.8s 公式 SAMPLE.M の組み込み data
        .include "sample_m.s"

        ;;; ADR-0016 step V-1: pmddotnet_song label を build-poc.sh が生成する
        ;;; 専用 .inc (= pmddotnet_song.inc) 経由で取り込む。 song_data.inc は
        ;;; standalone_test.s 専用 (= song_table / voice_table 等の label) で、
        ;;; PMDNEO.s build top では include しない (= 不要 + relocation error 原因)。
        ;;; PMDNEO_USE_PMDDOTNET = 1 のみ pmddotnet_song.inc を取り込み (= 0 では
        ;;; 不要、 pmddotnet_song.inc 不在で build 通過させる)。
.if PMDNEO_USE_PMDDOTNET
        .include "pmddotnet_song.inc"
.endif
