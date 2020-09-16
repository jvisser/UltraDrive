;------------------------------------------------------------------------------------------
; Debug log
;------------------------------------------------------------------------------------------

    If strcmp('\debug', 'gens')

;-------------------------------------------------
; Write debug message to console (GensKMod implementation)
; ----------------
; Parameters: 
; - message: String to write to console
DEBUG_MSG Macro message
            movem.l d0/a0-a1, -(sp)
            lea     .debugMessage\@, a0
            bsr     GensKModDebugAlert
            movem.l (sp)+, d0/a0-a1

            ; Store string data in DEBUG section
            SECTION_START S_DEBUG
        .debugMessage\@:
            dc.b    \message, $00
            SECTION_END
    Endm


;-------------------------------------------------
; Write null terminated string to GensKMod emulator message log (using virtual VDP register $1e)
; ----------------
; Parameters: 
; - a0: Address of null terminated string
; Uses: d0/a0-a1
GensKModDebugAlert:
        move.w  #0x9e00, d0
        move.b  (a0)+, d0
        beq.s   .done
        lea     $c00004, a1

    .writeLoop:
        move.w  d0, (a1)
        move.b  (a0)+, d0
        bne.s   .writeLoop
        move.w  d0, (a1)

    .done:
        rts

    Else

; NOOP
DEBUG_MSG Macro
    Endm

    EndIf
