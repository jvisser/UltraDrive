;------------------------------------------------------------------------------------------
; Startup code
;------------------------------------------------------------------------------------------

    Include './system/include/m68k.inc'

;-------------------------------------------------
; Start of 68000 execution (See reset vector)
; ----------------
Boot:
        jsr MemoryInit

        ; Run initializers
        lea     __ctors, a0
    .ctorsLoop:
        move.l  (a0)+, d0
        beq.s   .ctorsDone
            movea.l d0, a1
            PUSHL   a0
                jsr     (a1)
            POPL    a0
            bra.s .ctorsLoop
    .ctorsDone:

        ; Accept all interrupts
        move #M68k_SR_SUPERVISOR, sr

        ; Start main program
        jmp Main
