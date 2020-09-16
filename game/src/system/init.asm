;------------------------------------------------------------------------------------------
; System initialization code
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Start of 68000 execution (See reset vector)
; ----------------
SysInit:
        ; Clear RAM
        bsr MemInit

        ; initialize VDP
        bsr VDPInit

        ; Start main program
        jmp Main