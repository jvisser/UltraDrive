;------------------------------------------------------------------------------------------
; OS Macros
;------------------------------------------------------------------------------------------

    If (~def(__SYSTEM_OS_INC))
__SYSTEM_OS_INC Equ 1

    Include './common/include/debug.inc'

    Include './system/include/memory.inc'

;-------------------------------------------------
; OS Context structure
; ----------------
    DEFINE_STRUCT OSContext
        STRUCT_MEMBER.w frameReady
        STRUCT_MEMBER.l framesProcessed
        STRUCT_MEMBER.l framesSkipped
        STRUCT_MEMBER.l frameProcessedCallback
        STRUCT_MEMBER.w lockCount
    DEFINE_STRUCT_END


;-------------------------------------------------
; Aliases
; ----------------
VBlankInterruptHandler  Equ OSPrepareNextFrame              ; Patch address for 68k vector table
OSInit                  Equ osContextInit


;-------------------------------------------------
; Get the lower word of the frame counter
; ----------------
OS_GET_FRAME_COUNTER_W Macro target
        move.w  (osContext + OSContext_framesProcessed + SIZE_WORD), \target
    Endm


;-------------------------------------------------
; Get the the frame counter
; ----------------
OS_GET_FRAME_COUNTER_L Macro target
        move.l  (osContext + OSContext_framesProcessed), \target
    Endm


;-------------------------------------------------
; Lock OS when accessing shared resources between main program and OS
; ----------------
OS_LOCK Macro
        tst.w   (osContext + OSContext_lockCount)
        bne.s   .alreadyLocked\@
            M68K_DISABLE_INT
    .alreadyLocked\@:
        addq    #1, (osContext + OSContext_lockCount)
    Endm


;-------------------------------------------------
; Unlock OS when accessing shared resources between main program and OS
; ----------------
OS_UNLOCK Macro
        tst.w   (osContext + OSContext_lockCount)
        beq.s   .alreadyUnlocked\@
            subq    #1, (osContext + OSContext_lockCount)
            bne.s   .alreadyUnlocked\@
                M68K_ENABLE_INT
    .alreadyUnlocked\@:
    Endm


;-------------------------------------------------
; Kill switch
; ----------------
OS_KILL Macro reason
        DEBUG_MSG \reason
        trap #0
        Endm

    EndIf
