;;;
;;; IRQ.INC
;;; TIMER-B IRQ handler + sound command 受付
;;;
;;; 設計書 3 §5 (TIMER-B IRQ NEOGEO 環境置換) 参照。
;;;
;;; SubA: silent ROM のため IRQ handler は最小 stub (= TIMER-B 来ても
;;; 何もせず ret)、 sound command 受付は no-op。 Phase 2 SubB-F で
;;; 各部を埋める。
;;;

        .area CODE

;;; ----- pmd_main: TIMER-B IRQ handler の主処理 -----
;;;
;;; SubA: 即 ret (silent ROM、 何も鳴らさない)
;;; SubB-F: per-part main loop (FM/SSG/ADPCM-B 順次実装)、
;;;         tempo / fade / mask の global flag 更新、 chip 駆動

pmd_main::
        ret


;;; ----- sound command jump table (= ngdevkit nullsound 流儀) -----
;;;
;;; 設計書 3 §5-3 で確定した nullsound 系統 sound command framework。
;;; M68K 側から REG_SOUND port write 経由で sound command を発行、
;;; Z80 IRQ handler が cmd_jmptable で振り分け。
;;;
;;; SubA: stub のみ (受付するが何もしない、 silent ROM)

;;; cmd_jmptable: nullsound 公式の slot 0x00, 0x01 は nullsound.lib に
;;; 既に定義済 (snd_command_unused / snd_command_01_prepare_for_rom_switch)、
;;; 本 file では call のみ。 PMDNEO 独自 cmd は 0x02 以降に追加。
cmd_jmptable::
        jp      snd_command_unused                       ; 0x00 no-op
        jp      snd_command_01_prepare_for_rom_switch    ; 0x01 ngdevkit reserved (nullsound.lib)
        jp      snd_command_02_play_song                 ; 0x02 楽曲再生開始
        jp      snd_command_03_stop_song                 ; 0x03 楽曲再生停止
        jp      snd_command_04_fade_out                  ; 0x04 fade out
        ;; 残り 123 entry を未使用 cmd で padding (nullsound 慣習、 helpers.inc macro)
        init_unused_cmd_jmptable


;;; PMDNEO 独自 sound command (= 0x02 以降、 nullsound と被らない)

snd_command_02_play_song::
        ;; SubB-F で楽曲再生開始 routine を実装
        ret

snd_command_03_stop_song::
        ;; SubB-F で楽曲停止 + chip silence routine を実装
        ret

snd_command_04_fade_out::
        ;; SubF で fade out 実装
        ret
