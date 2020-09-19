;------------------------------------------------------------------------------------------
; System initialization code
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Start of 68000 execution (See reset vector)
; ----------------
SysInit:
        jsr MemInit ; Must be called first (Clears all memory)

        jsr IOInit
        jsr VDPInit

        ; Start main program
        jmp Main