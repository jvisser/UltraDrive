;------------------------------------------------------------------------------------------
; System initialization code
;------------------------------------------------------------------------------------------

;-------------------------------------------------
; Start of 68000 execution (See reset vector)
; ----------------
SysInit:
        jsr MemoryInit ; Must be called first (Clears all memory)

        jsr VDPInit
        jsr VDPDMAQueueInit
        jsr VDPTaskQueueInit
        jsr VDPSpriteInit
        jsr RasterEffectsInit
        jsr IOInit
        jsr OSInit

        ; Prepare cpu for processing once all sub systems have been initialized (ie proper handlers are setup)
        jsr Z80Init

        ; Allow all interrupts
        move #M68k_SR_SUPERVISOR, sr

        ; Start main program
        jmp Main


;-------------------------------------------------
; No operations handler
; ----------------
NoOperation:
    rts
