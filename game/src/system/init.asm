;------------------------------------------------------------------------------------------
; System initialization code
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Start of 68000 execution (See reset vector)
; ----------------
SysInit:
        jsr MemInit ; Must be called first (Clears all memory)

        jsr IOInit
        jsr VDPDMAQueueInit
        jsr VDPTaskQueueInit
        jsr VDPInit
        jsr VDPSpriteInit
        jsr OSInit

        ; Prepare cpu for processing once all sub systems have been initialized (ie proper handlers are setup)
        jsr M68KInit

        ; Start main program
        jmp Main


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
