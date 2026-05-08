;;;
;;; KR_STUB.INC
;;; K/R 内蔵 rhythm no-op stub
;;;
;;; PMD ファミリ「未対応 cmd スルー」 思想 (= 設計書 2 §0-2 / 設計書 3
;;; §3 参照) の literal 実装。 各 handler は引数 byte を PMDNEO の
;;; PART_OFF_ADDR(IX) から消費するだけで chip 書込なし、 ret で帰る。
;;;
;;; YM2610/B には OPNA 内蔵 rhythm 機構が存在しないため、 cmdtblr の
;;; rhythm 関連 cmd は全て本 stub に dispatch される。
;;;
;;; 引数 byte 数は analysis_m_data_structure.md §4-7-8 で確定済。
;;;
;;; SubA: 7 個 handler 完成。 cmdtblr の jump table から参照される。

        .area CODE

;;; rhykey (引数 1 byte): rhythm trigger bitmap
rhykey::
        call    pmdneo_part_fetch_byte
        ret

;;; rhyvs (引数 1 byte): rhythm volume (per ch)
rhyvs::
        call    pmdneo_part_fetch_byte
        ret

;;; rhyvs_sft (引数 2 byte): rhythm vol shift (per ch + 値)
rhyvs_sft::
        call    pmdneo_part_fetch_byte
        call    pmdneo_part_fetch_byte
        ret

;;; rpnset (引数 1 byte): rhythm pattern set (pan + ch)
rpnset::
        call    pmdneo_part_fetch_byte
        ret

;;; rmsvs (引数 1 byte): \V rhythm master vol set
rmsvs::
        call    pmdneo_part_fetch_byte
        ret

;;; rmsvs_sft (引数 1 byte): rhythm master vol shift
rmsvs_sft::
        call    pmdneo_part_fetch_byte
        ret

;;; pdrswitch (引数 1 byte): PDR switch (PPSDRV mode、 PMDNEO では完全 no-op)
pdrswitch::
        call    pmdneo_part_fetch_byte
        ret
