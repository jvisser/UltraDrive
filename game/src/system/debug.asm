;------------------------------------------------------------------------------------------
; Debug log
;------------------------------------------------------------------------------------------

    If strcmp('\debug', 'gens')

;-------------------------------------------------
; Write debug message to console (GensKMod implementation)
; ----------------
; Input:
; - message: String to write to console
DEBUG_MSG Macro message
            PUSH_CONTEXT

            lea     .debugMessage\@, a0
            jsr     GensKModDebugAlert

            POP_CONTEXT

            ; Store string data in DEBUG section
            SECTION_START S_DEBUG
        .debugMessage\@:
            dc.b    \message, $00
            SECTION_END
    Endm


;-------------------------------------------------
; Start a timer (NB: modifies ccr)
; ----------------
DEBUG_START_TIMER Macros
        move.w #VDP_CMD_RS_DBG_TIMER | $80, MEM_VDP_CTRL


;-------------------------------------------------
; Stop a timer (NB: modifies ccr)
; ----------------
DEBUG_STOP_TIMER Macros
        move.w #VDP_CMD_RS_DBG_TIMER | $40, MEM_VDP_CTRL


;-------------------------------------------------
; Software break point
; ----------------
DEBUG_BREAK Macro
        PUSH_CONTEXT

        move.w #VDP_CMD_RS_DBG_BP, MEM_VDP_CTRL

        POP_CONTEXT
    Endm


;-------------------------------------------------
; Write null terminated string to message log using GensKMod protocol.
; ----------------
; Input:
; - a0: Address of null terminated string
; Uses: d0/a0-a1
GensKModDebugAlert:
        move.w  #VDP_CMD_RS_DBG_LOG, d0
        move.b  (a0)+, d0
        beq.s   .done
        lea     MEM_VDP_CTRL, a1

    .writeLoop:
        move.w  d0, (a1)
        move.b  (a0)+, d0
        bne.s   .writeLoop
        move.w  d0, (a1)

    .done:
        rts


    Else

; NOOP Default

DEBUG_MSG Macro
    Endm

DEBUG_START_TIMER Macro
    Endm

DEBUG_STOP_TIMER Macro
    Endm

DEBUG_BREAK Macro
    Endm

    EndIf
