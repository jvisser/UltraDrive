;------------------------------------------------------------------------------------------
; Mega Drive system details
;------------------------------------------------------------------------------------------

    Include './system/include/tmss.inc'

;-------------------------------------------------
; Unlock system by TradeMark Security System (TMSS) protocol
; ----------------
; Uses: d0
TMSSUnlock:
        move.b  MEM_REG_VERSION, d0
        andi.b  #REG_VERSION_TMSS_MASK, d0
        beq.s   .noTMSS
        move.l  #'SEGA', MEM_TMSS

    .noTMSS:
        rts
