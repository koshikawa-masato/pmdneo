;;;
;;; PMD_Z80.ASM
;;; PMD V4.8s の Z80 化 base driver
;;;
;;; PMD.ASM (10864 行 x86 アセンブリ) を NEOGEO Z80 環境に移植する base
;;; module。 PMDPPZ.ASM が PMD.ASM を include する流儀を踏襲して、
;;; PMDNEO.ASM が flag を立てて本 file を include する。
;;;
;;; 設計書 1 / 2 / 3 で確定した:
;;; - dispatch table (cmdtbl FM/PCM、 cmdtblp PSG、 cmdtblr Rhythm、 cmdtbla ADPCM-A)
;;; - per-part main loop (fmmain / psgmain / rhythmmain / adpcma_main)
;;; - opcode 0x00-0x7F (音程 + 音長)、 0x80 (part end)、 0x81-0xB0 (out_of_commands)、 0xB1-0xFF (dispatch)
;;; - K/R workarea OPNA 互換 layout、 解釈 routine は KR_STUB.INC の no-op stub
;;;
;;; SubA: 空 (silent ROM 用 stub)。 SubB-F で段階的に PMD.ASM の routine
;;; を翻訳して埋める。

        .area CODE

;;; ----- Phase 2 SubA placeholder -----

pmd_z80_main::
        ;; SubA: 空 (silent)
        ;; SubB: SSG 3ch dispatch (commandsp / cmdtblp / fnumset PSG / volset PSG)
        ;; SubC: FM 6ch dispatch (commands / cmdtbl / 音色 set / fnumset / volset)
        ;; SubD: K/R no-op stub の cmdtblr 連結 (dispatch jump table set up)
        ;; SubE: ADPCM-B 1ch dispatch (J part main loop、 ADPCMB_DRV.ASM 連携)
        ;; SubF: 統合 (tempo / fade / loop / mask、 長尺楽曲対応)
        ret
